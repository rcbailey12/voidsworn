extends SceneTree
# Regression check. Set VS_WORLD_CACHE to a scratch directory before running:
# godot --headless --path godot --script res://main/test_loading.gd
# Omit --headless to also check compute pixels against the raster shader.

const Baker := preload("res://world/world_bake.gd")
const World := preload("res://world/world.gd")
const CODE := """
shader_type canvas_item;
render_mode unshaded, blend_disabled;
uniform vec2 full_size = vec2(65.0, 35.0);
uniform float strip_y0 = 0.0;
uniform float strip_h = 35.0;
uniform float value = 0.25;
void fragment() {
    vec2 p = vec2(UV.x * full_size.x, strip_y0 + UV.y * strip_h);
    COLOR = vec4(value, p / full_size, 0.625);
}
"""
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		printerr("FAIL: " + message)

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	var folder := OS.get_environment("VS_WORLD_CACHE")
	if folder == "":
		printerr("Set VS_WORLD_CACHE to a scratch directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	RenderingServer.global_shader_parameter_add("scene_t", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	OS.set_environment("VS_WORLD_PREVIEW", "1")
	var baker := Baker.service(self)
	var size := Vector2i(65, 35)
	var params := {"value": 0.25}
	var key := Baker.cache_key("test", CODE, params, size)
	check(key != Baker.cache_key("test", CODE, {"value": 0.5}, size), "uniform invalidates cache")
	check(key != Baker.cache_key("test", CODE + "\n", params, size), "source invalidates cache")
	check(key != Baker.cache_key("test", CODE, params, Vector2i(66, 35)), "size invalidates cache")
	check(Baker.cache_key("order", CODE, {"a": 1, "b": 2}, size) == Baker.cache_key("order", CODE, {"b": 2, "a": 1}, size), "uniform order is stable")
	var expected := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	expected.fill(Color(0.25, 0.5, 0.75, 0.625))
	check(expected.save_png(folder.path_join(key + ".png")) == OK, "write disk fixture")
	check(Baker.cached(key) == null, "disk lookup is deferred to worker")
	# Free one consumer mid-load. Its shared job must survive for a second one.
	var consumer := Baker.new()
	root.add_child(consumer)
	consumer.bake("test", CODE, params, size, 2)
	check(baker._jobs.size() == 1, "one in-flight job")
	consumer.queue_free()
	var image: Image = await baker.bake("test", CODE, params, size, 2)
	check(image != null and image.has_mipmaps(), "worker loads and mipmaps disk hit")
	check(baker._jobs.is_empty(), "joined job is released")
	check(image == await baker.bake("test", CODE, params, size, 2), "memory image is shared")
	check(Baker.texture(image) == Baker.texture(image), "GPU texture is shared")
	var run := {"map": {"fac": "hegemony", "biome": {"rock": "stone", "planet": 0}}}
	var sector := World.sector_setting(run)
	for seed in [1, 9001]:
		var world := World.new()
		root.add_child(world)
		world.build({"terrain": {}, "units": [], "map": {"deadstar": {"q": 0, "r": 0}} if seed == 9001 else {}},
			{"hex_world": func(q, r): return Vector3(q * 10, 0, r * 10), "fac": "corsair", "seed": seed, "sector_setting": sector})
		for field in ["seed", "feature", "c1", "c2", "planet"]:
			check(world.setting[field] == sector[field], "sector " + field + " survives rival, seed and dead-star changes")
		world.queue_free()
	if DisplayServer.get_name() != "headless":
		await compare_pixels(baker, "pixels", CODE, params, size)
		var sky_params := {"seed": 3.7, "c1": sector.c1, "c2": sector.c2, "c3": sector.c3, "neb": sector.neb, "cover": sector.cover,
			"dust": sector.dust, "band": sector.band, "band_n": sector.band_n, "feature": sector.feature, "steps": 48,
			"lamp": PackedVector4Array(World.SKY.lamps(sector)), "gal": PackedVector4Array(World.SKY.galaxies(sector))}
		await compare_pixels(baker, "sky", World.SKY.bake_code(), sky_params, size)
		for pass_id in 2:
			await compare_pixels(baker, "planet%d" % pass_id, World.PL.bake_code(),
				{"seed": 7.1, "kind": 2, "ca": Vector3(0.3, 0.36, 0.2), "cb": Vector3(0.02, 0.06, 0.14), "cc": Vector3(0.62, 0.55, 0.42), "pass_id": pass_id}, size)
	for i in Baker.CACHE_MAX + 1:
		Baker.remember("bound%d" % i, Image.create_empty(4, 4, false, Image.FORMAT_RGBA8))
	check(Baker._cache.size() == Baker.CACHE_MAX, "memory cache is bounded")
	for i in 2: await process_frame
	Baker.clear_static()
	print("LOADING_TEST failures=%d" % failed)
	quit(0 if failed == 0 else 1)

func compare_pixels(baker: Node, label: String, code: String, params: Dictionary, size: Vector2i) -> void:
	var computed: Image = await baker.bake("compare_" + label, code, params, size, 2)
	var raster: Image = await baker._canvas(code, params, size)
	check(computed != null and raster != null, label + " returns both images")
	if computed == null or raster == null: return
	var error := 0.0
	var total := 0.0
	for y in size.y:
		for x in size.x:
			var delta := computed.get_pixel(x, y) - raster.get_pixel(x, y)
			error = maxf(error, maxf(maxf(absf(delta.r), absf(delta.g)), maxf(absf(delta.b), absf(delta.a))))
			total += absf(delta.r) + absf(delta.g) + absf(delta.b) + absf(delta.a)
	# The sky hashes pixel coordinates for ray jitter. Raster interpolation and
	# compute rounding can change that jitter by a few levels in an 8-bit image.
	var tolerance := (8.0 if label == "sky" else 2.0) / 255.0
	var mean := total / (size.x * size.y * 4)
	check(error <= tolerance and mean <= 1.0 / 255.0, label + " preserves pixels and alpha, including last tile")
	print("BAKE %s pixel error: max=%f mean=%f" % [label, error, mean])
