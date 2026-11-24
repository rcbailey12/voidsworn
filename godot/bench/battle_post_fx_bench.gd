extends "res://bench/scene_gate.gd"
# Issue 1779. Matched 1080p scenes with fixed FX steps for pictures and per-viewport GPU timestamps for timing.
const Look := preload("res://render/look.gd")
const WorldSky := preload("res://world/world_sky.gd")
const Rocks := preload("res://world/world_rocks.gd")
const Podium := preload("res://ui/campaign/flagship_podium.gd")
const Stamp := preload("res://tools/picture_provenance.gd")
const FLAGS := ["LUT", "DOF", "SSR", "LENSING", "SHOCKWAVE", "DECALS"]
const REFLECTIVE := {"ithar": "i_blade", "deathless": "d_harvester", "chorus": "b_spitter"}
const SEED := 4207
const STEP := 1.0 / 60.0
const CELL := Vector2i(640, 360)
var _region := "world"
var _station := false
var _capital := ""


func _run() -> void:
	if args.has("dry"):
		_region = "deadstar"
		var good := await _prepare_case()
		good = good and b.world.well_radius() > 0.0 and b.cam.r == 170.0
		print("[post_fx] fixture dry run ", "PASS" if good else "FAIL")
		await _finish_bench(good)
		return
	if RenderingServer.get_current_rendering_method() != "forward_plus" or DisplayServer.get_name() == "headless":
		_fail("the picture and timing runs require Forward+ with a display")
		return
	build_wait_usec = 180_000_000
	var ok := await _timings() if args.has("timing") else await _comparison_sheets()
	await _finish_bench(ok)


func _finish_bench(ok: bool) -> void:
	if b != null:
		await _drop_battle()
	preload("res://render/static_caches.gd").clear_all()
	get_tree().quit(0 if ok else 1)


func _configure_battle(api) -> void:
	var state: Dictionary = api.R.B
	var map: Dictionary = state["map"]
	var region: Dictionary = WorldSky.REGION_OF.get(_region, WorldSky.REGION_OF["frontier"])
	state["biome"] = {"rock": region["rock"][0], "planet": region["planet"][0]}
	if _region == "deadstar":
		# This render fixture needs a well regardless of which map that seed rolls.
		var home: Dictionary = api._hexes[api._hexes.size() / 2]
		map["deadstar"] = {"q": home["q"], "r": home["r"]}
	else:
		map.erase("deadstar")


func _prepare_case() -> bool:
	args["map"] = "station" if _station else "storm"
	args["camera"] = "turn"
	rng.seed = SEED
	if not await _build("post_fx", SEED) or (not args.has("dry") and PG.stop_if_any()):
		return false
	b.reduce_motion = false
	b.reduce_flashing = false
	b.skip = false
	b.speed = 1.0
	b.cine = "key"
	var fx = b.gfx
	fx.manual = true
	fx.rng.seed = SEED
	_capital = _id_of("ascendant")
	if _capital.is_empty():
		return _fail("the battle fixture lost its Ascendant")
	var focus: Vector3 = b.world.well_position()
	if _region != "deadstar":
		focus = b._pos(_capital)
	_frame(focus, 170.0, 0.98)
	return true


func _id_of(tpl: String) -> String:
	for unit in b.V["units"]:
		if unit["tpl"] == tpl:
			return str(unit["id"])
	return ""


func _frame(center: Vector3, radius: float, tilt: float) -> void:
	b.cam.t = center
	b.cam.r = radius
	b.cam.a = -PI / 2.0
	b.cam.b = tilt
	b.cam.snap()


func _flags(active: Array) -> void:
	for flag in FLAGS:
		OS.set_environment("VS_BATTLE_" + flag, "1" if active.has(flag) else "0")


func _advance(frame: int, fire := true) -> void:
	_settle(b.gfx)
	if fire and frame % 21 == 0:
		_volley()
	b.gfx.step(STEP)
	await get_tree().process_frame
	await _post()


func _drop_battle() -> void:
	b.queue_free()
	b = null
	for frame in 4:
		await get_tree().process_frame


func _grab() -> Image:
	await _post()
	return get_viewport().get_texture().get_image()


func _pair(name: String, before: Image, after: Image) -> bool:
	if before == null or after == null or before.is_empty() or after.is_empty():
		return _fail("empty comparison " + name)
	var sheet := Image.create_empty(CELL.x * 2, CELL.y, false, Image.FORMAT_RGBA8)
	for i in 2:
		var panel := before if i == 0 else after
		panel.convert(Image.FORMAT_RGBA8)
		panel.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(panel, Rect2i(Vector2i.ZERO, CELL), Vector2i(i * CELL.x, 0))
	if preload("res://tools/picture_provenance.gd").save_png(sheet,
		out.path_join("1779_" + name + ".png"), Stamp.capture_stage(), true) != OK:
		return _fail("could not save " + name)
	return true


func _comparison_sheets() -> bool:
	for region in WorldSky.REGION:
		_region = region
		_flags([])
		if not await _prepare_case():
			return false
		for frame in 45:
			await _advance(frame)
		var swatch := ColorRect.new()
		swatch.position = Vector2(8, 8)
		swatch.size = Vector2(16, 16)
		swatch.color = Color("#a7c4e8")
		var layer := CanvasLayer.new()
		layer.layer = 100
		add_child(layer)
		layer.add_child(swatch)
		var before := await _grab()
		_flags(["LUT"])
		Look.battle_grade(b.env, _region)
		if not b.env.adjustment_enabled or str(b.env.adjustment_color_correction.resource_path) != Look.BATTLE_LUTS[_region]:
			return _fail("the battle did not select the " + _region + " grade")
		var after := await _grab()
		layer.queue_free()
		if before.get_pixel(16, 16) != after.get_pixel(16, 16):
			return _fail("the CanvasLayer swatch changed with the battle LUT")
		if not _pair("c170_" + region, before, after):
			return false
		await _drop_battle()
	var baseline := await _action_stills(false)
	var treatment := await _action_stills(true)
	if baseline.is_empty() or baseline.keys() != treatment.keys():
		return false
	for name in baseline:
		if not _pair(name, baseline[name], treatment[name]):
			return false
	return true


func _action_stills(active: bool) -> Dictionary:
	var rows := {}
	_region = "deadstar"
	_station = false
	_flags(["LENSING", "SHOCKWAVE", "DOF", "SSR"] if active else [])
	if not await _prepare_case():
		return {}
	b.env.ssr_enabled = false
	rows["dead_star_lens"] = await _grab()
	if active and not b._battle_lens.enabled:
		_fail("the Dead Star lens is outside the capture")
		return {}
	b._lens_well = false
	Look.battle_ssr(b.env, "max", b.V["units"])
	for faction in REFLECTIVE:
		var target := _id_of(REFLECTIVE[faction])
		if target.is_empty():
			_fail("the fixture lost its " + faction + " target")
			return {}
		_frame(b._pos(target), 60.0, 1.02)
		var volley: Dictionary = b.gfx.volley(_capital, "lance", target, {"weapon_id": "lance",
			"shots": [true], "hits": [{"shield": 0, "hull": 9, "section": "mid", "crit": false}]})
		if volley.get("impacts", []).is_empty():
			_fail("no live weapon impact for " + faction)
			return {}
		var until: float = b.gfx.now + float(volley["impacts"][0]) + 0.08
		while b.gfx.now < until:
			await _advance(0, false)
		rows["ssr_" + faction] = await _grab()
	b.env.ssr_enabled = false
	var core := await _show_capital_death()
	if core < 0.0:
		_fail("the capital death never reached its staged core")
		return {}
	if active and not b._battle_lens.enabled:
		_fail("the capital shockwave is outside the capture")
		return {}
	rows["capital_death"] = await _grab()
	await _drop_battle()

	_region = "world"
	_station = true
	_flags(["DECALS"] if active else [])
	var tumble := Rocks.rock_tumble_k
	Rocks.rock_tumble_k = 0.0 # Keep the same seeded surface facing the camera in both stills.
	var terrain_ready := await _prepare_case()
	Rocks.rock_tumble_k = tumble
	if not terrain_ready:
		return {}
	var station: Node3D
	for node in b.board.props.get_children():
		if node.has_meta("station_T2"):
			station = node
			break
	var rocks: Array = b.V["terrain"].keys().filter(func(key): return b.V["terrain"][key] == "rock")
	if station == null or rocks.is_empty():
		_fail("the fixture requires installed station_T2 and at least one asteroid")
		return {}
	if active and (station.find_children("*", "Decal", true, false).is_empty() or
		b.world.find_children("*", "Decal", true, false).is_empty()):
		_fail("the opt-in fixture installed no terrain scorch decals")
		return {}
	_frame(station.global_position, 64.0, 0.75)
	rows["station_T2"] = await _grab()
	var qr: PackedStringArray = str(rocks[0]).split(",")
	_frame(b.board.hex_world(int(qr[0]), int(qr[1])), 30.0, 0.62)
	rows["asteroid"] = await _grab()
	var rules = b.api.R
	_flags(["DOF"] if active else [])
	var podium := Podium.new()
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(podium)
	podium.position = Vector2(340, 20)
	podium.size = Vector2(1240, 1040)
	podium.setup(rules, {"tpl": "ascendant", "uid": "1779"}, Color("#ff8a3a"), true)
	await _drop_battle()
	if not podium.installed:
		_fail("the flagship podium requires the installed Ascendant hull")
		return {}
	rows["flagship_podium"] = await _grab()
	layer.queue_free()
	await get_tree().process_frame
	return rows


func _show_capital_death() -> float:
	_frame(b._pos(_capital), 170.0, 1.02)
	b._play_death({"unit": _capital, "cause": "big"})
	var limit: float = b.gfx.now + 8.0
	while b.gfx.now < limit:
		var core := _capital_core()
		if core >= 0.0 and b.gfx.now >= core + 0.15:
			return core
		await _advance(0, false)
	return -1.0


func _capital_core() -> float:
	var ship = b.gfx.ship(_capital)
	return -1.0 if ship == null or ship.death_core_pending else b.gfx.death_core_at(_capital)


func _timings() -> bool:
	_region = "deadstar"
	var samples := {}
	for mode in ["baseline_a", "ssr", "well", "shock", "baseline_b"]:
		_flags({"ssr": ["SSR"], "well": ["LENSING"], "shock": ["SHOCKWAVE"]}.get(mode, []))
		if not await _prepare_case():
			return false
		if mode == "ssr" and not b.env.ssr_enabled:
			return _fail("half-resolution SSR did not activate")
		b.cine = "off"
		var capital_pos: Vector3 = b._pos(_capital)
		var well_pos: Vector3 = b.world.well_position()
		_frame(capital_pos.lerp(well_pos, 0.5), 170.0, 0.98)
		var gpu: Array[float] = []
		var core_gpu: Array[float] = []
		var lens_frames := 0
		var rid := get_viewport().get_viewport_rid()
		for frame in 660:
			if frame == 300:
				b._play_death({"unit": _capital, "cause": "big"})
				side_ids["player"].erase(_capital)
			await _advance(frame)
			var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(rid)
			if frame >= 180 and gpu_ms > 0.0:
				gpu.append(gpu_ms)
				if b._battle_lens != null and b._battle_lens.enabled:
					lens_frames += 1
				var core := _capital_core()
				if core >= 0.0 and b.gfx.now >= core and b.gfx.now < core + b.SHOCKWAVE_S:
					core_gpu.append(gpu_ms)
		if gpu.size() < 400 or core_gpu.is_empty():
			return _fail("missing GPU timestamps or capital core samples in " + mode)
		if mode in ["well", "shock"] and lens_frames == 0:
			return _fail("the compositor stayed idle for " + mode)
		samples[mode] = {"all": _percentiles(gpu), "core": _percentiles(core_gpu), "lens_frames": lens_frames}
		print("[post_fx] ", mode, " ", samples[mode])
		await _drop_battle()
	for mode in ["ssr", "well", "shock"]:
		var window := "core" if mode == "shock" else "all"
		var baseline: float = (samples["baseline_a"][window]["p50_ms"] + samples["baseline_b"][window]["p50_ms"]) * 0.5
		samples[mode]["delta_p50_ms"] = samples[mode][window]["p50_ms"] - baseline
	var file := FileAccess.open(out.path_join("1779_timing.json"), FileAccess.WRITE)
	if file == null:
		return _fail("could not save the timing report")
	file.store_string(JSON.stringify({"gpu": RenderingServer.get_video_adapter_name(), "seed": SEED,
		"viewport": [RES.x, RES.y], "camera": 170, "ssr_half_size": true, "modes": samples}, "\t") + "\n")
	file.close()
	return true


static func _percentiles(values: Array[float]) -> Dictionary:
	values.sort()
	return {"frames": values.size(), "p50_ms": values[values.size() / 2], "p95_ms": values[int(values.size() * 0.95)]}


func _fail(message: String) -> bool:
	push_error("[post_fx] " + message)
	return false
