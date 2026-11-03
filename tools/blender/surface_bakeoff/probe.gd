extends SceneTree
# Issue 75 isolated GPU comparison. Runtime scene, no imported project assets.
# Today's packed scenes are copies of build/godot/gen/ships, not a recreation.

var cfg: Dictionary
var world: Node3D
var cam: Camera3D
var holder: Node3D
var report: Array = []
var out: String
var facets: Dictionary
var compressed := {}


func compress_map(tex: Texture2D, normal: bool) -> Texture2D:
	if tex == null:
		return null
	var key := str(tex.get_rid())
	if compressed.has(key):
		return compressed[key]
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	if normal:
		assert(img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL) == OK)
	else:
		assert(img.compress(Image.COMPRESS_BPTC, Image.COMPRESS_SOURCE_GENERIC) == OK)
	var result := ImageTexture.create_from_image(img)
	compressed[key] = result
	return result


func _initialize() -> void:
	call_deferred("run")


func fail(message: String) -> void:
	push_error(message)
	quit(1)


func nodes(n: Node) -> Array:
	var found: Array = []
	if n is MeshInstance3D:
		found.append(n)
	for child in n.get_children():
		found.append_array(nodes(child))
	return found


func setup_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var shader := Shader.new()
	shader.code = "shader_type sky; uniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable; void sky(){ COLOR = min(texture(pano,SKY_COORDS).rgb * 0.8, vec3(0.6)); }"
	var sm := ShaderMaterial.new()
	sm.shader = shader
	sm.set_shader_parameter("pano", load("res://gen/sky.res"))
	sky.sky_material = sm
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# These are the shipped G4 max settings, recorded with source hashes by run.py.
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.tonemap_agx_white = 12.0
	env.tonemap_agx_contrast = 1.25
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_hdr_scale = 2.0
	env.glow_intensity = 0.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for lv in 7:
		env.set_glow_level(lv, [0.0, 0.6, 1.0, 0.6, 0.25, 0.0, 0.0][lv])
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	for light_cfg in [[Vector3(-0.45, -0.70, -0.55), Color(1.0, 0.96, 0.90), 2.0],
			[Vector3(0.6, -0.2, 0.75), Color(0.55, 0.65, 0.85), 0.5]]:
		var light := DirectionalLight3D.new()
		light.transform = Transform3D(Basis.looking_at(light_cfg[0].normalized(), Vector3.UP), Vector3.ZERO)
		light.light_color = light_cfg[1]
		light.light_energy = light_cfg[2]
		if light_cfg[2] > 1.0:
			light.shadow_enabled = true
			light.shadow_normal_bias = 2.0
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.directional_shadow_max_distance = 600.0
		world.add_child(light)
	root.msaa_3d = Viewport.MSAA_4X
	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	cam = Camera3D.new()
	cam.near = 0.2
	cam.far = 5000.0
	world.add_child(cam)
	cam.current = true
	holder = Node3D.new()
	world.add_child(holder)


func model(code: String, route: String) -> Node3D:
	var ship: Node3D
	if route == "today":
		var packed = load("res://gen/ships/%s.scn" % code)
		assert(packed is PackedScene, "Missing today's packed ship")
		ship = packed.instantiate()
	else:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var path := str(cfg["work"]).path_join(code).path_join(route).path_join("route%s.glb" % route)
		assert(doc.append_from_file(path, state) == OK, "Prototype glTF load failed")
		ship = doc.generate_scene(state)
	# Both ordinary skins AND heavy outer rings are visible on an intact ship.
	# They are disjoint patches, as pack.py and fx/API.md specify.
	for mi in nodes(ship):
		for i in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if src is BaseMaterial3D:
				var mat: BaseMaterial3D = src.duplicate()
				# Match build_assets.gd: mipmaps and BC7/BC5 on prototypes too.
				if route != "today":
					for prop in ["albedo_texture", "normal_texture", "orm_texture", "roughness_texture", "metallic_texture", "emission_texture", "ao_texture"]:
						if mat.get(prop) != null:
							mat.set(prop, compress_map(mat.get(prop), prop == "normal_texture"))
				var fac: String = cfg["ships"][code]["faction"]
				var fix: Array = facets[fac]["hull_fix"]
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				mat.rim_enabled = true
				mat.rim = float(fix[0])
				mat.rim_tint = float(fix[1])
				mat.albedo_color *= Color(float(fix[2]), float(fix[2]), float(fix[2]), 1)
				mi.set_surface_override_material(i, mat)
	return ship


func fit(ship: Node3D, length: float) -> Dictionary:
	holder.add_child(ship)
	var box := AABB()
	var first := true
	var triangle_count := 0
	for mi in nodes(ship):
		if not mi.is_visible_in_tree():
			continue
		var xf: Transform3D = ship.global_transform.affine_inverse() * mi.global_transform
		var bb: AABB = xf * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
		for i in mi.mesh.get_surface_count():
			var arr: Array = mi.mesh.surface_get_arrays(i)
			triangle_count += arr[Mesh.ARRAY_INDEX].size() / 3 if arr[Mesh.ARRAY_INDEX] != null else arr[Mesh.ARRAY_VERTEX].size() / 3
	var scale_k := length / maxf(box.size.x, 0.001)
	ship.scale = Vector3.ONE * scale_k
	ship.position = -box.get_center() * scale_k
	return {"triangles": triangle_count, "raw_bounds": [box.size.x, box.size.y, box.size.z], "world_length": length}


func view(kind: String, length: float) -> void:
	cam.fov = 45.0
	var dir := Vector3(0.0, cos(0.98), sin(0.98))
	var distance := 170.0
	var target := Vector3.ZERO
	if kind == "close":
		# Preserve the home camera's direction. Only the zoom changes.
		distance = length * (1.75 if length > 44.0 else 1.20)
	elif kind in ["top", "side", "below"]:
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = length * 1.16
		distance = length * 3.0
		dir = {"top": Vector3.UP, "side": Vector3.BACK, "below": Vector3.DOWN}[kind]
	else:
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	if kind == "close":
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	var up := Vector3.FORWARD if kind == "top" else (Vector3.BACK if kind == "below" else Vector3.UP)
	cam.look_at_from_position(target + dir * distance, target, up)


func settle(count := 40) -> void:
	for i in count:
		await process_frame


func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	assert(img.get_width() == 1920 and img.get_height() == 1080, "Unexpected capture size")
	assert(img.save_png(out.path_join(name + ".png")) == OK)
	print("[surface75] shot ", name)


func median(a: Array) -> float:
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


func bench(label: String) -> Dictionary:
	await settle(100)
	var gpu_ms: Array = []
	var cpu_ms: Array = []
	var frames: Array = []
	var last := Time.get_ticks_usec()
	for i in 360:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		await process_frame
	var sorted := frames.duplicate()
	sorted.sort()
	var row := {"label": label, "frames": frames.size(), "warmup": 100,
		"gpu_median_ms": median(gpu_ms), "render_cpu_median_ms": median(cpu_ms),
		"frame_median_ms": median(frames), "frame_p99_ms": sorted[int(sorted.size() * 0.99)],
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	assert(float(row["gpu_median_ms"]) > 0.0, "GPU timing unavailable")
	print("[surface75] timing ", JSON.stringify(row))
	return row


func run() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() != 1:
		fail("Usage: -- config.json")
		return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	out = cfg["shots"]
	facets = cfg["factions"]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920, 1080)
	setup_world()
	view("battle", 41.6)
	var blank := await bench("empty")
	for code in cfg["ships"]:
		var length: float = cfg["ships"][code]["length"]
		var routes := ["today", "B", "A"] if code == "C19_51" else ["today", "B"]
		for route in routes:
			var ship := model(code, route)
			var stats := fit(ship, length)
			for kind in ["battle", "close", "top", "side", "below"]:
				view(kind, length)
				await settle()
				await snap("%s_%s_%s" % [code, route, kind])
			view("battle", length)
			var single := await bench("%s_%s_1" % [code, route])
			# 20 non-overlapping copies. Use one fleet camera for every route
			# of this hull and leave all 20 ships inside its frustum.
			# Duplicate shares GPU meshes and maps as a real fleet would.
			var spacing := length * 1.15
			var fleet_r := maxf(170.0, length * 8.0)
			cam.look_at_from_position(Vector3(0, cos(0.98), sin(0.98)) * fleet_r, Vector3.ZERO, Vector3.UP)
			ship.position += Vector3(-2 * spacing, 0, -1.5 * spacing)
			for i in range(1, 20):
				var copy := ship.duplicate()
				copy.position += Vector3((i % 5) * spacing, 0, (i / 5) * spacing)
				holder.add_child(copy)
			var fleet := await bench("%s_%s_20" % [code, route])
			report.append({"code": code, "route": route, "geometry": stats, "single": single, "fleet": fleet})
			for child in holder.get_children():
				child.free()
			await settle(5)
	var result := {"adapter": RenderingServer.get_video_adapter_name(), "godot": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(), "resolution": [1920, 1080],
		"vsync": "disabled", "blank": blank, "rows": report,
		"fleet_layout": "5 by 4 copies; spacing 1.15 ship lengths; camera distance max(170, 8 ship lengths)",
		"textures": "mipmaps; BC7 colour/ORM/emission; BC5 normal"}
	var f := FileAccess.open(str(cfg["work"]).path_join("gpu.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  ") + "\n")
	f.close()
	print("[surface75] GPU PASS")
	quit(0)
