extends "res://bench/scene_gate.gd"
# Issue 368: reuse the gate's effects, warmup, timing, render stats and placeholder guard.
# Run the scene in this folder, not --script. This harness never saves a player profile.
const LIVING := preload("res://world/world_living.gd")
var map_case := "storm"
var route := "today"
var patch_rows := {}
var measured_camera := {}
var measured_tier := ""
var measured_seed := 0

func _run() -> void:
	map_case = str(args.get("map-case", "storm"))
	route = OS.get_environment("VS_NEBULA_ROUTE")
	if route == "": route = "fog"
	if not route in ["today", "fog"] or not map_case in ["nebula", "storm"]:
		push_error("Issue 368: route must be today/fog and map-case nebula/storm")
		get_tree().quit(2)
		return
	if args.has("dry-run"):
		await _dry_run()
		return
	if DisplayServer.get_name() == "headless":
		push_error("Issue 368: headless timing is not GPU evidence; use --dry-run only")
		get_tree().quit(2)
		return
	var go := str(args.get("go-file", ""))
	if go == "" or not FileAccess.file_exists(go) or not FileAccess.get_file_as_string(go).get_slice("\n", 0).begins_with("GPU cleared"):
		push_error("Issue 368: Board GPU go file required before drawing")
		get_tree().quit(2)
		return
	if args.has("captures"):
		await _capture_routes()
		PG.finish(0)
		return
	await super._run()


func _save() -> void:
	report["terrain_case"] = map_case
	report["route"] = route
	report["adapter_sha256"] = FileAccess.get_sha256("res://world/nebula_bench.gd")
	report["map"] = "graveyard with nebula condition" if map_case == "nebula" else str(args.get("map", "storm"))
	super._save()


func _nebula_terrain(api) -> void:
	# Use the game's nebula condition generator, never a hand-painted terrain dictionary.
	var terrain: Dictionary = api.R.genTerrain("graveyard", "open", {"cond": {"terr": "neb"}})
	api.R.B["terrain"] = terrain
	api.R.B["map"] = api.R.TERRAIN_META.duplicate(true)


func _patch_metadata(api) -> Dictionary:
	var points := {"neb": [], "storm": []}
	for key in api.R.B["terrain"]:
		var kind: String = api.R.B["terrain"][key]
		if not points.has(kind): continue
		var qr := str(key).split(",")
		var p: Dictionary = api.R.hexXZ({"q": int(qr[0]), "r": int(qr[1])})
		points[kind].append(Vector3(p.x, 0, p.z))
	var living := LIVING.new()
	var result := {}
	for kind in points:
		var patches: Array = living._patches(points[kind])
		var sizes: Array = []
		for patch in patches: sizes.append(patch.size())
		result[kind] = {"hexes": points[kind].size(), "patches": sizes}
	living.free()
	return result


func _dry_run() -> void:
	var api = API.new()
	var error: String = api.load_rules()
	if error != "":
		push_error(error)
		get_tree().quit(1)
		return
	var config := {"seed": 4207, "sector": 3, "admiral": "vex", "fleet": FLEET.duplicate(),
		"enemies": ENEMIES.duplicate(), "fac": "corsair", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(config, 4207)
	if map_case == "nebula": _nebula_terrain(api)
	var patches := _patch_metadata(api)
	var volume = load("res://world/nebula_noise.res")
	var bytes := 0
	for image in volume.slices:
		bytes += image.get_data().size()
	var expected := 128 * 128 * 128
	var active: Dictionary = patches["neb" if map_case == "nebula" else "storm"]
	if bytes != expected or active.patches.size() < 2:
		push_error("Issue 368: invalid baked noise or map is not multi-patch: %s" % patches)
		get_tree().quit(1)
		return
	var data := {"kind": "CPU preparation only", "map_case": map_case, "route": route, "seed": 4207,
		"patches": patches, "noise_bytes": bytes, "noise_sha256": FileAccess.get_sha256("res://world/nebula_noise.res"),
		"frame_median": null, "gpu_median": null}
	data["geometry"] = _geometry_check(api)
	if data.geometry.is_empty():
		get_tree().quit(1)
		return
	var file := FileAccess.open(out.path_join("dry_run.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ") + "\n")
	print("NEBULA_BENCH CPU only ", JSON.stringify(data))
	get_tree().quit(0)


func _geometry_check(api) -> Array:
	var points: Array = []
	var kind := "neb" if map_case == "nebula" else "storm"
	for key in api.R.B.terrain:
		if api.R.B.terrain[key] != kind: continue
		var qr := str(key).split(",")
		var p: Dictionary = api.R.hexXZ({"q": int(qr[0]), "r": int(qr[1])})
		points.append(Vector3(p.x, 0, p.z))
	var rows: Array = []
	for candidate in ["today", "fog"]:
		for tier in ["max", "high", "low"]:
			var world = load("res://world/world.gd").new()
			world.quality = tier
			world._fac = "corsair"
			var gas := LIVING.new()
			gas.W = world
			gas.gas_route = candidate
			gas.rng.seed = 368
			var patches: Array = gas._patches(points)
			for patch in patches: gas._gas(patch, kind == "storm")
			var fogs := 0
			var cards := 0
			for child in gas.get_children():
				if child is FogVolume:
					fogs += 1
					if not is_equal_approx(child.size.y, 38.5):
						push_error("Issue 368: fog height is not 38.5")
						return []
				if child is MultiMeshInstance3D: cards += child.multimesh.instance_count
			var mk: Array = gas._mask([points[0]])
			var box: Vector4 = mk[1]
			var image: Image = mk[2]
			var beyond: Vector3 = points[0] + Vector3(11, 0, 0)
			var pixel := Vector2i(int((beyond.x - box.x) * box.z * image.get_width()), int((beyond.z - box.y) * box.w * image.get_height()))
			var outside_alpha := image.get_pixelv(pixel).g
			var first := image.get_width()
			var last := -1
			var center_row := int((points[0].z - box.y) * box.w * image.get_height())
			for x in image.get_width():
				if image.get_pixel(x, center_row).g > 0.001:
					first = mini(first, x)
					last = maxi(last, x)
			var soft_span := float(last - first + 1) / (box.z * image.get_width())
			var expected_fogs: int = patches.size() if candidate == "fog" and tier == "max" else 0
			if fogs != expected_fogs or (candidate != "today" and (outside_alpha <= 0.0 or soft_span < 74.4)):
				push_error("Issue 368: fog tier or soft edge failed")
				return []
			rows.append({"route": candidate, "tier": tier, "fog_volumes": fogs, "cards": cards,
				"one_hex_soft_span": soft_span,
				"edge_at_x11": outside_alpha, "fog_height": 38.5 if fogs > 0 else null})
			gas.free()
			world.free()
	return rows


func _configure_battle(api) -> void:
	b.args["quality"] = str(args.get("terrain-tier", "max"))
	if map_case == "nebula":
		_nebula_terrain(api)


func _build(mode: String, seed: int) -> bool:
	if not await super._build(mode, seed) or PG.stop_if_any(): return false
	# The gate's engagement camera may be farther away than 250. Never time invisible fog.
	if route == "fog": b.env.volumetric_fog_length = maxf(250.0, b.cam.r + 200.0)
	patch_rows = _patch_metadata(b.api)
	measured_camera = {"r": b.cam.r, "near": b.cam.near, "t": [b.cam.t.x, b.cam.t.y, b.cam.t.z]}
	measured_tier = str(b.world.quality) if b.world != null else str(args.get("terrain-tier", "max"))
	measured_seed = int(b.battle_cfg.get("seed", seed))
	return true


func _mode(mode: String, session: int) -> Dictionary:
	var row: Dictionary = await super._mode(mode, session)
	if row.is_empty(): return row
	row["terrain_case"] = map_case
	row["terrain_tier"] = measured_tier
	row["seed"] = measured_seed
	row["route"] = route
	row["patches"] = patch_rows.duplicate(true)
	row["gate_ms"] = 12.5
	row["camera"] = measured_camera.duplicate(true)
	if mode == "base": row["gate_pass"] = float(row.get("frame_median", INF)) <= 12.5
	if mode == "res_2160": row["gate_pass"] = float(row.get("gpu_median", INF)) <= 12.5
	return row


func _capture_routes() -> void:
	if not await _build("base", 4207) or PG.stop_if_any(): return
	volleys_on = false
	b.hud.visible = false
	b.set_process(false)
	b.gfx.manual = true
	b.cam.screen_shift = 0.0
	var kind := "neb" if map_case == "nebula" else "storm"
	var living = b.world._living
	# Fixed presentation clock for a fair still comparison. Timing runs keep live motion.
	b.world.set_process(false)
	living.set_process(false)
	living.clock = 0.08
	for i in living.bolts.size():
		living.bolts[i]["next"] = 1000.0
		living.bolts[i]["start"] = 0.0 if i == 0 else -10.0
	living._process(0.0)
	var patches: Array = living._patches(b.world._terr_pts[kind])
	patches.sort_custom(func(a, z): return a.size() > z.size())
	var center := Vector3.ZERO
	for p in patches[0]: center += p
	center /= float(patches[0].size())
	var classes := {}
	for unit in b.V.units:
		var cls := str(unit.cls)
		if classes.has(cls) or not b.views.has(unit.id): continue
		var view = b.views[unit.id]
		view.set_process(false)
		# Presentation positions only; the battle's generated state is untouched.
		view.position = center + Vector3((classes.size() - 3) * 19.0, 0, 0)
		classes[cls] = str(unit.id)
	for view in _views():
		view.set_process(false)
		if not classes.values().has(str(view.u.id)): view.visible = false
	# Keep one real cruiser at the same point for all three camera distances.
	var subject = b.views[classes.get("Cruiser", classes.values()[0])]
	for view in _views(): view.visible = view == subject
	subject.position = center
	for radius in [170.0, 60.0, 26.0, -170.0]:
		b.cam.t = center
		b.cam.r = absf(radius)
		b.cam.b = 0.05 if radius < 0 else 0.98
		b.cam.snap()
		if route == "fog": b.env.volumetric_fog_length = maxf(250.0, absf(radius) + 200.0)
		for frame in 120: await get_tree().process_frame
		var label := "top" if radius < 0 else "c%d" % int(radius)
		await _shot("%s_%s_%s.png" % [map_case, route, label])
		if radius == 60.0 and map_case == "storm" and route == "fog":
			# Hold the same gas and hide the ribbons in both frames: only actual light injection differs.
			for bolt in living.bolts:
				bolt.mi.visible = false
				bolt.start = -10.0
			living._process(0.0)
			await _shot("storm_fog_c60_light_off.png")
			var nearest = null
			for bolt in living.bolts:
				if bolt.light == null or bolt.light.light_volumetric_fog_energy <= 0.0: continue
				if nearest == null or bolt.pos.distance_to(center) < nearest.pos.distance_to(center): nearest = bolt
			if nearest != null: nearest.start = living.clock - 0.025
			living._process(0.0)
			await _shot("storm_fog_c60_light_on.png")
			for i in living.bolts.size():
				living.bolts[i].mi.visible = true
				living.bolts[i].start = 0.0 if i == 0 else -10.0
			living._process(0.0)
		if args.has("four-k") and radius > 0:
			get_window().size = Vector2i(3840, 2160)
			for frame in 60: await get_tree().process_frame
			await _shot("%s_%s_%s_4k.png" % [map_case, route, label])
			# An identical gas-free frame exposes any lost hull contrast at native pixels.
			living.visible = false
			for frame in 60: await get_tree().process_frame
			await _shot("%s_%s_%s_4k_clear.png" % [map_case, route, label])
			living.visible = true
			get_window().size = RES
	if args.has("scale-captures"):
		await _scale_captures(center, living)
	var file := FileAccess.open(out.path_join("capture_metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"route": route, "map": map_case, "patches": patch_rows, "classes": classes,
		"presentation_positions_only": true, "gpu_measurements": false}, "  ") + "\n")
	b.queue_free()
	b = null


func _scale_captures(center: Vector3, living) -> void:
	# Unit dictionaries come from a real scenario, including the game's automatic wings.
	# Only their presentation positions change. The gate timing fleet is never expanded.
	var api = API.new()
	if api.load_rules() != "":
		get_tree().quit(1)
		return
	var fleet: Array = []
	var seen := {}
	for tpl in api.R.HULLS:
		var cls := str(api.R.HULLS[tpl].get("cls", ""))
		if cls == "" or seen.has(cls) or cls == "Squadron": continue
		seen[cls] = true
		fleet.append(tpl)
	api.new_battle_scenario({"seed": 4207, "sector": 3, "admiral": "vex", "fleet": fleet,
		"enemies": ["c_raider"], "fac": "corsair", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}, 4207)
	for view in _views(): view.visible = false
	var rows: Array = []
	seen.clear()
	for unit in api.view().units:
		# As in the gate's mixed-faction fleet, retain each template's own hull family.
		if api.R.HULLS.has(unit.tpl) and api.R.HULLS[unit.tpl].get("fac") != null:
			unit["fac"] = str(api.R.HULLS[unit.tpl].fac)
		var cls := str(unit.cls)
		if cls == "Squadron": cls += "_" + str(unit.get("sqKind", unit.get("tpl", "wing")))
		if seen.has(cls): continue
		seen[cls] = true
		var view := SV.new()
		b.add_child(view)
		view.setup(unit, center)
		view.set_process(false)
		if PG.stop_if_any(): return
		for radius in [170.0, 60.0]:
			b.cam.t = center
			b.cam.r = radius
			b.cam.b = 0.98
			b.cam.snap()
			if route == "fog": b.env.volumetric_fog_length = radius + 200.0
			for frame in 30: await get_tree().process_frame
			await _shot("scale_%s_%s_%s_c%d.png" % [map_case, route, cls.to_lower().replace(" ", "_"), int(radius)])
		rows.append({"class": cls, "tpl": unit.tpl, "code": view.code, "length": view.L})
		view.queue_free()
		await get_tree().process_frame
	var file := FileAccess.open(out.path_join("scale_metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"ships": rows, "terrain": map_case, "center": [center.x, center.y, center.z]}, "  ") + "\n")
	file.close()
