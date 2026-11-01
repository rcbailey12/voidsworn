extends Node
# F4 GPU baker: draws a canvas_item shader into a big image, a strip per frame (no single frame long enough to upset the
# graphics driver), and hands back the image. The shader reads full_size, strip_y0 and strip_h and maps its UV to the
# whole picture itself (world_sky.gd BAKE, world_planet.gd BAKE).
#
# A finished picture is kept for the session under its key (a setting's sky or planet), so the battles of one sector bake
# once. Headless runs (tests, parity) have no renderer: bake() returns null at once and the world falls back.

static var _cache := {}       # key -> Image
const CACHE_MAX := 6


static func cached(key: String) -> Image:
	return _cache.get(key, null)


func bake(key: String, code: String, params: Dictionary, size: Vector2i, strips: int) -> Image:
	if _cache.has(key):
		return _cache[key]
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return null
	var t0 := Time.get_ticks_msec()
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
	if _cache.size() >= CACHE_MAX:
		_cache.erase(_cache.keys()[0])
	_cache[key] = full
	print("[world] baked %s %dx%d in %d ms" % [key, size.x, size.y, Time.get_ticks_msec() - t0])
	return full


# a strip the GPU has not drawn yet (its pipeline still compiling) comes back cleared: all zero
static func _blank(img: Image) -> bool:
	for k in 16:
		var c := img.get_pixel(int((k * 7919) % img.get_width()), int((k * 104729) % img.get_height()))
		if c.r + c.g + c.b + c.a > 0.0:
			return false
	return true
