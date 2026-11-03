extends Node
# A shared queue survives title, map and battle changes. Workers own their local
# RenderingDevice, compilation, GPU waits, readback, mipmaps and disk I/O.
# Scene nodes and texture uploads stay on the main thread, behind loading.

const CACHE_MAX := 24
const CACHE_DIR := "user://world_bakes/v3"
static var _cache := {}
static var _textures := {}
var _jobs := {}
var _queue: Array = []
var _active := ""
var _thread: Thread

static func service(tree: SceneTree) -> Node:
	var node := tree.root.get_node_or_null("WorldBakes")
	if node == null:
		node = load("res://world/world_bake.gd").new()
		node.name = "WorldBakes"
		tree.root.add_child(node)
	return node

static func cache_key(key: String, code: String, params: Dictionary, size: Vector2i) -> String:
	var ordered := {}
	var keys := params.keys()
	keys.sort()
	for name in keys: ordered[name] = params[name]
	return var_to_str([key, code, ordered, size]).sha256_text()

static func cached(key: String) -> Image:
	# Disk hits also use the worker, never PNG decode on the caller's thread.
	return _cache.get(key)

static func texture(img: Image) -> Texture2D:
	var id := img.get_instance_id()
	if not _textures.has(id): _textures[id] = ImageTexture.create_from_image(img)
	return _textures[id]

static func remember(key: String, img: Image) -> void:
	if _cache.has(key): return
	if _cache.size() >= CACHE_MAX:
		var oldest: String = _cache.keys()[0]
		_textures.erase(_cache[oldest].get_instance_id())
		_cache.erase(oldest)
	_cache[key] = img

static func clear_static() -> void:
	_textures.clear()
	_cache.clear()

func bake(key: String, code: String, params: Dictionary, size: Vector2i, strips: int) -> Image:
	var owner := service(get_tree())
	key = cache_key(key, code, params, size)
	if _cache.has(key): return _cache[key]
	if not owner._jobs.has(key):
		owner._jobs[key] = {"code": code, "params": params.duplicate(true), "size": size,
			"done": false, "image": null, "started": Time.get_ticks_msec(),
			"compute": DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "gl_compatibility"}
		owner._queue.append(key)
	var job: Dictionary = owner._jobs[key]
	while not job.done: await get_tree().process_frame
	return job.image

func _process(_dt: float) -> void:
	if _thread != null:
		if _thread.is_alive(): return
		var result: Dictionary = _thread.wait_to_finish()
		_thread = null
		var job: Dictionary = _jobs[_active]
		if result.image == null and not job.compute and DisplayServer.get_name() != "headless" and not job.get("raster_done", false):
			job.raster_done = true
			var img: Image = await _canvas(job.code, job.params, job.size)
			_thread = Thread.new()
			_thread.start(_finish_image.bind(_active, img))
			return
		job.image = result.image
		job.done = true
		if result.image != null:
			remember(_active, result.image)
			print("[world] %s %s %dx%d in %d ms (worker)" % [result.source, _active, job.size.x, job.size.y, Time.get_ticks_msec() - job.started])
		elif result.get("error", "") != "":
			push_error("World bake: " + result.error)
		_jobs.erase(_active)
		_active = ""
	if _active != "" or _queue.is_empty(): return
	_active = _queue.pop_front()
	_thread = Thread.new()
	var err := _thread.start(_work.bind(_active, _jobs[_active]))
	if err != OK:
		_jobs[_active].done = true
		_jobs.erase(_active)
		_active = ""
		_thread = null
		push_error("Could not start world bake worker: %s" % err)

func _exit_tree() -> void:
	# Deleting a world does not cancel its shared job. Only shutdown joins it.
	if _thread != null: _thread.wait_to_finish()
	for job in _jobs.values(): job.done = true
	_jobs.clear()
	_queue.clear()
	clear_static()

static func _work(key: String, job: Dictionary) -> Dictionary:
	var folder := OS.get_environment("VS_WORLD_CACHE") if OS.has_environment("VS_WORLD_CACHE") else CACHE_DIR
	var path := folder.path_join(key + ".png")
	var img: Image = null
	if FileAccess.file_exists(path): img = Image.load_from_file(path)
	var source := "loaded"
	var error := ""
	if img == null or img.is_empty() or img.get_size() != job.size:
		img = null
		if job.compute:
			var result := _compute(job.code, job.params, job.size)
			img = result.image
			error = result.get("error", "")
			source = "baked"
			if img != null and DirAccess.make_dir_recursive_absolute(folder) == OK:
				var tmp := path + ".tmp"
				if img.save_png(tmp) == OK: DirAccess.rename_absolute(tmp, path)
	if img != null and not img.has_mipmaps(): img.generate_mipmaps()
	return {"image": img, "source": source, "error": error}

static func _finish_image(key: String, img: Image) -> Dictionary:
	if img != null:
		var folder := OS.get_environment("VS_WORLD_CACHE") if OS.has_environment("VS_WORLD_CACHE") else CACHE_DIR
		if DirAccess.make_dir_recursive_absolute(folder) == OK:
			var path := folder.path_join(key + ".png")
			if img.save_png(path + ".tmp") == OK: DirAccess.rename_absolute(path + ".tmp", path)
		img.generate_mipmaps()
	return {"image": img, "source": "baked"}

# The two bake shaders use the GLSL subset of Godot's shader language. Reuse
# their equations, with a storage buffer for uniforms and an image output.
static func _compute_source(code: String, params: Dictionary, size: Vector2i) -> Dictionary:
	code = code.replace("shader_type canvas_item;", "").replace("render_mode unshaded, blend_disabled;", "")
	var rx := RegEx.new()
	rx.compile("(?m)^uniform (float|int|vec2|vec3|vec4) (\\w+)(?:\\[(\\d+)\\])?[^;]*;")
	var values := PackedFloat32Array()
	var defines := ""
	var arrays := {}
	var uniforms := params.duplicate(true)
	uniforms.merge({"full_size": Vector2(size), "strip_y0": 0.0, "strip_h": float(size.y)}, true)
	for match_ in rx.search_all(code):
		var type := match_.get_string(1)
		var name := match_.get_string(2)
		var count := maxi(1, int(match_.get_string(3)))
		var offset := values.size() / 4
		if not uniforms.has(name): return {"error": "Missing bake uniform " + name}
		var value = uniforms[name]
		if match_.get_string(3) != "":
			arrays[name] = offset
		else:
			var expr := "bake_data.values[%d]" % offset
			match type:
				"float": expr += ".x"
				"int": expr = "int(" + expr + ".x)"
				"vec2": expr += ".xy"
				"vec3": expr += ".xyz"
			defines += "#define %s (%s)\n" % [name, expr]
		for i in count:
			var v = value[i] if match_.get_string(3) != "" else value
			match type:
				"float", "int": values.append_array([float(v), 0.0, 0.0, 0.0])
				"vec2": values.append_array([v.x, v.y, 0.0, 0.0])
				"vec3": values.append_array([v.x, v.y, v.z, 0.0])
				"vec4": values.append_array([v.x, v.y, v.z, v.w])
	code = rx.sub(code, "", true)
	for name in arrays:
		rx.compile(name + "\\[([^\\]]+)\\]")
		code = rx.sub(code, "bake_data.values[%d + ($1)]" % arrays[name], true)
	code = code.replace("void fragment()", "void bake_pixel()")
	var header := "#version 450\nlayout(local_size_x=8, local_size_y=8, local_size_z=1) in;\n"
	header += "layout(set=0,binding=0,rgba8) uniform writeonly image2D output_image;\n"
	header += "layout(set=0,binding=1,std430) readonly buffer BakeData { vec4 values[]; } bake_data;\n"
	header += "layout(push_constant,std430) uniform Tile { int y; } tile;\nvec2 UV; vec4 COLOR;\n"
	var entry := "\nvoid main() { ivec2 p=ivec2(gl_GlobalInvocationID.xy)+ivec2(0,tile.y); if(any(greaterThanEqual(p,ivec2(full_size)))) return; UV=(vec2(p)+0.5)/full_size; bake_pixel(); imageStore(output_image,p,COLOR); }\n"
	return {"code": header + defines + code + entry, "data": values.to_byte_array()}

static func _compute(code: String, params: Dictionary, size: Vector2i) -> Dictionary:
	var source := _compute_source(code, params, size)
	if source.has("error"): return {"image": null, "error": source.error}
	var rd := RenderingServer.create_local_rendering_device()
	if rd == null: return {"image": null, "error": "Local RenderingDevice is unavailable"}
	var shader_source := RDShaderSource.new()
	shader_source.source_compute = source.code
	var spirv := rd.shader_compile_spirv_from_source(shader_source)
	var error := spirv.get_stage_compile_error(RenderingDevice.SHADER_STAGE_COMPUTE)
	if error != "":
		rd.free()
		return {"image": null, "error": error}
	var shader := rd.shader_create_from_spirv(spirv)
	var pipeline := rd.compute_pipeline_create(shader)
	var format := RDTextureFormat.new()
	format.width = size.x
	format.height = size.y
	format.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	var output := rd.texture_create(format, RDTextureView.new())
	var buffer := rd.storage_buffer_create(source.data.size(), source.data)
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 0
	image_uniform.add_id(output)
	var data_uniform := RDUniform.new()
	data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	data_uniform.binding = 1
	data_uniform.add_id(buffer)
	var uniforms := rd.uniform_set_create([image_uniform, data_uniform], shader, 0)
	# Small dispatches avoid the Windows GPU watchdog on slower graphics cards.
	for y in range(0, size.y, 32):
		var list := rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(list, pipeline)
		rd.compute_list_bind_uniform_set(list, uniforms, 0)
		var push := PackedInt32Array([y]).to_byte_array()
		rd.compute_list_set_push_constant(list, push, push.size())
		rd.compute_list_dispatch(list, ceili(size.x / 8.0), ceili(mini(32, size.y - y) / 8.0), 1)
		rd.compute_list_end()
		rd.submit()
		rd.sync()
	var bytes := rd.texture_get_data(output, 0)
	for rid in [uniforms, buffer, output, pipeline, shader]: rd.free_rid(rid)
	rd.free()
	if bytes.size() != size.x * size.y * 4: return {"image": null, "error": "Incomplete bake readback"}
	return {"image": Image.create_from_data(size.x, size.y, false, Image.FORMAT_RGBA8, bytes)}


# Compatibility has no compute device. Keep its original raster bake under the
# loading cover; mipmaps and PNG work still go through the worker.
func _canvas(code: String, params: Dictionary, size: Vector2i) -> Image:
	var strips := maxi(2, ceili(size.y / 32.0))
	var sh := Shader.new()
	sh.code = code
	var mat := ShaderMaterial.new()
	mat.shader = sh
	for k in params:
		mat.set_shader_parameter(k, params[k])
	var sh_h := int(ceil(float(size.y) / strips))
	var vp := SubViewport.new()
	vp.size = Vector2i(size.x, sh_h)
	vp.disable_3d = true
	vp.transparent_bg = true   # keeps the shader's alpha (the sky stores starlight transmittance there)
	vp.use_hdr_2d = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var rect := ColorRect.new()
	rect.size = Vector2(vp.size)
	rect.material = mat
	vp.add_child(rect)
	add_child(vp)
	mat.set_shader_parameter("full_size", Vector2(size))
	mat.set_shader_parameter("strip_h", float(sh_h))
	var full := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	for i in strips:
		mat.set_shader_parameter("strip_y0", float(i * sh_h))
		var img: Image = null
		for attempt in 3:
			vp.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			# r6: one more frame before reading back (a strip read straight after its draw came back with a dark block
			# missing from the gas on the PC)
			await RenderingServer.frame_post_draw
			img = vp.get_texture().get_image()
			if img == null or img.is_empty():
				vp.queue_free()
				return null
			if not _blank(img):
				break
		img.convert(Image.FORMAT_RGBA8)
		var h := mini(sh_h, size.y - i * sh_h)
		full.blit_rect(img, Rect2i(0, 0, size.x, h), Vector2i(0, i * sh_h))
	vp.queue_free()
	return full

static func _blank(img: Image) -> bool:
	for k in 16:
		var c := img.get_pixel(int((k * 7919) % img.get_width()), int((k * 104729) % img.get_height()))
		if c.r + c.g + c.b + c.a > 0.0: return false
	return true
