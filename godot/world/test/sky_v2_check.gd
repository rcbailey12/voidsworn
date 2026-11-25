extends SceneTree
## Issues 1766 and 1502. Read the live star catalogue, setting palettes and sky cache without a renderer.

const BAKER := preload("res://world/world_bake.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const SKY := preload("res://world/world_sky.gd")
const WORLD := preload("res://world/world.gd")
const FLOOK := preload("res://fx/faction_look.gd")
const VISIBLE_PEAK := 0.003 # linear at the centre of a faint star, before gas or dust occlusion

var _failures := 0


func _init() -> void:
	GUARD.arm(self, "sky_v2_check")
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _palette(c: Vector3, label: String) -> void:
	var col := Color(c.x, c.y, c.z)
	var hue := col.h * 360.0
	_check(c.is_finite() and minf(c.x, minf(c.y, c.z)) >= 0.0, label + " has finite, nonnegative channels")
	_check(not (col.s > 0.18 and hue >= 240.0 and hue <= 335.0), "%s is purple (hue %.1f)" % [label, hue])
	_check(not (col.s > 0.26 and hue >= 43.0 and hue <= 92.0), "%s is mustard (hue %.1f)" % [label, hue])


func _settings() -> Array[Dictionary]:
	var factions := FLOOK.table()
	_check(factions.size() == 6, "all six faction palettes were loaded")
	for id in factions:
		var colors: Array = factions[id].get("nebula", [])
		_check(colors.size() == 3, id + " has a complete sky palette")
		for i in colors.size(): _palette(colors[i], "%s.nebula[%d]" % [id, i])
	var defaults := RegEx.create_from_string("uniform vec3 (c[123]) = vec3\\(([^)]+)\\);")
	var matches := defaults.search_all(SKY.BAKE_BODY)
	_check(matches.size() == 3, "all three bake fallback colours were found")
	for match_ in matches:
		var rgb := match_.get_string(2).split_floats(",")
		_palette(Vector3(rgb[0], rgb[1], rgb[2]), "bake default " + match_.get_string(1))
	var live: Array[Dictionary] = []
	for region in SKY.REGION:
		_palette(SKY.REGION[region]["tint"], region + " tint")
		var inputs: Dictionary = SKY.REGION_OF.get(region, SKY.REGION_OF["deep"])
		var biome := {"rock": inputs["rock"][0], "planet": inputs["planet"][0]}
		for id in factions:
			var label := "%s/%s" % [region, id]
			var s := SKY.setting(biome, id, "open", region == "deadstar", 1766)
			_check(s["region"] == region, label + " selects the intended region")
			live.append(s)
			for field in ["c1", "c2", "c3", "haze"]: _palette(s[field], label + "/" + field)
			for rival in factions:
				if id == rival: continue
				var mood := SKY.stop_mood(s, {"fac": rival, "sector_fac": id}, "open")
				for field in ["c1", "c2", "c3", "haze", "mood_tint"]:
					_palette(mood[field], label + "/rival " + rival + "/" + field)
	return live


func _catalogue() -> Dictionary:
	var atlas := SKY.star_catalog_image()
	var n := SKY.STAR_GRID
	_check(atlas.get_size() == Vector2i(3 * n, 2 * n) and not atlas.has_mipmaps(), "six unfiltered star catalogue faces")
	# Read the live shader's brightness curve, not a copy of the old thresholds or a count from tuning constants.
	var expression := Expression.new()
	var curve := SKY.SKY.get_slice("float lum = ", 1).get_slice(";", 0)
	if expression.parse(curve, ["m"]) != OK:
		_check(false, "could not read the live star brightness curve")
		return {"directions": PackedVector3Array(), "peaks": PackedFloat32Array()}
	var peaks := PackedFloat32Array()
	var directions := PackedVector3Array()
	var lut := PackedFloat32Array()
	for i in 256: lut.append(float(expression.execute([i / 255.0])))
	_check(lut[0] == 0.0 and lut[128] < lut[255] * 0.06, "steep star magnitude curve has no flat brightness floor")
	var band_stars := 0
	var off_stars := 0
	for face in 6:
		var offset := Vector2i(face % 3, face / 3) * n
		for y in n:
			for x in n:
				var star := atlas.get_pixelv(offset + Vector2i(x, y))
				if star.b == 0.0: continue
				var p := (Vector2(x, y) + Vector2(star.r, star.g)) * (2.0 / n) - Vector2.ONE
				var ray := SKY.star_direction(face, p)
				directions.append(ray)
				peaks.append(lut[roundi(star.b * 255.0)])
				if absf(ray.y) < 0.15: band_stars += 1
				if absf(ray.y) > 0.85: off_stars += 1
	_check(band_stars > off_stars * 1.75, "equal solid angle strips have more stars in the galactic band than off it")
	return {"directions": directions, "peaks": peaks}


func _views(settings: Array[Dictionary]) -> void:
	var data := _catalogue()
	var half_v := tan(deg_to_rad(45.0) * 0.5)
	var half_h := half_v * 16.0 / 9.0
	var counts: Array[int] = []
	for s in settings:
		var star_frame := SKY.star_frame(s)
		for pitch in [34.0, 14.4]: # default and low battle camera
			for orbit in [-0.3, 0.0, 0.3]:
				var camera := Basis(Vector3.UP, float(orbit) - float(s["yaw"])) * Basis(Vector3.RIGHT, -deg_to_rad(pitch))
				var from_stars := (star_frame * camera).transposed()
				var count := 0
				var heroes := 0
				var sky_gain := float(s["stars"]) * (0.4 if s["deadstar"] else 1.0)
				for i in data.directions.size():
					var peak: float = data.peaks[i] * sky_gain
					if peak < VISIBLE_PEAK: continue
					var ray: Vector3 = from_stars * data.directions[i]
					if ray.z >= 0.0 or absf(ray.x) > -ray.z * half_h or absf(ray.y) > -ray.z * half_v: continue
					count += 1
					if peak > 0.5: heroes += 1
				_check(heroes < 45, "hero pinpoints are rare in %s" % s["region"])
				counts.append(count)
	counts.sort()
	var median := counts[counts.size() / 2]
	print("SKY V2: %d projected 45-degree views, %d median pre-dust pinpoints (range %d to %d)" % [
		counts.size(), median, counts.front(), counts.back()])
	_check(median >= 340 and median <= 460, "typical 45-degree view has about 400 viable star centres")
	_check(counts.front() >= 225 and counts.back() <= 560, "neither empty nor snow-filled 45-degree views")


func _material(s: Dictionary) -> void:
	var saved := OS.get_environment("VS_STAR_FLOOR")
	OS.unset_environment("VS_STAR_FLOOR")
	var world := WORLD.new()
	root.add_child(world)
	world.setting = s
	world._baker = BAKER.service(self)
	var env := Environment.new()
	world._make_sky(env)
	var mat := env.sky.sky_material as ShaderMaterial
	_check(SKY.SKY.contains("uniform float star_floor = 0.0;"), "shader defaults to opaque dust")
	_check(SKY.SKY.contains("T = t.a *") and SKY.SKY.contains("* star_k * through"),
		"the live shader gates stars with the baked transmittance")
	_check(mat.get_shader_parameter("star_floor") == 0.0, "the live battle material defaults to opaque dust")
	_check(mat.get_shader_parameter("star_catalog") == SKY.star_catalog(), "the live battle uses the counted catalogue")
	OS.set_environment("VS_STAR_FLOOR", "0.19")
	SKY.set_star_uniforms(mat, s)
	_check(is_equal_approx(float(mat.get_shader_parameter("star_floor")), 0.19), "VS_STAR_FLOOR still overrides the default")
	if saved == "": OS.unset_environment("VS_STAR_FLOOR")
	else: OS.set_environment("VS_STAR_FLOOR", saved)
	await world.wait_ready()
	world.free()


func _half_cache(s: Dictionary) -> void:
	var size := Vector2i(16, 8)
	var folder := OS.get_temp_dir().path_join("sky-v2-check-%d" % OS.get_process_id())
	var params := SKY.bake_params(s, 32)
	var source := BAKER._compute_source(SKY.bake_code(), params, size, true)
	_check(SKY.BAKE_SIZE == Vector2i(2048, 1024), "live half-float sky is 2048x1024")
	_check(str(source.get("code", "")).contains("binding=0,rgba16f"), "sky compute writes half-float pixels")
	_check(SKY.SKY.contains("neb_tex : filter_linear, repeat_enable"), "longitude wraps with linear, mipless sampling")
	var key := BAKER.cache_key("sky-v2-check", SKY.bake_code(), params, size)
	var image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBAH)
	image.fill(Color(0.0004, 0.0006, 0.0007, 0.0))
	image.set_pixel(15, 7, Color(0.008, 0.007, 0.005, 0.4375))
	_check(BAKER._save(key, image, {}, {}, folder), "write a half-float sky through the live cache")
	var round_trip := BAKER._work(key, {"size": size, "folder": folder, "compute": false, "sky": true, "sky_half": true})
	var loaded: Image = round_trip.image
	_check(loaded != null and loaded.get_format() == Image.FORMAT_RGBAH and not loaded.has_mipmaps(), "cache returns half-floats without mips")
	if loaded != null:
		_check(loaded.get_data() == image.get_data(), "dark colours and transmittance survive the disk cache bit for bit")
	var cap := BAKER.prune(folder, 0, {}, "")
	_check(cap.after == 0 and cap.removed.has(key + BAKER.SKY_HALF_EXT), "half-float sky counts against the existing disk cap")
	DirAccess.remove_absolute(folder.path_join(BAKER.USED_INDEX))
	DirAccess.remove_absolute(folder)


func _run() -> void:
	var settings := _settings()
	if not settings.is_empty():
		_views(settings)
		await _material(settings.front())
		_half_cache(settings.front())
	if _failures == 0: print("PASS: sky star budget, opaque dust, palettes and half-float cache")
	quit(1 if _failures else 0)
