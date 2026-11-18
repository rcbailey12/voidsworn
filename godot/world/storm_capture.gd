extends "res://world/nebula_capture.gd"
# Issue 368 run 3. Reuse the fixed-pose native-pixel captures without editing
# the accepted nebula harness. The timing adapter remains nebula_bench.gd.


func _scale_captures(center: Vector3, living) -> void:
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
			for frame in 30: await get_tree().process_frame
			await _shot("scale_storm_fog_%s_c%d.png" % [cls.to_lower().replace(" ", "_"), int(radius)])
		rows.append({"class": cls, "tpl": unit.tpl, "code": view.code, "length": view.L})
		view.queue_free()
		await get_tree().process_frame
	var file := FileAccess.open(out.path_join("scale_metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"ships": rows, "terrain": "storm", "center": [center.x, center.y, center.z]}, "  ") + "\n")
	file.close()
	await _transport_capture(center)
	await _electrical_proof(center, living)


func _electrical_proof(center: Vector3, living) -> void:
	var subject = null
	for view in _views():
		view.visible = false
		if str(view.u.cls) == "Cruiser" and subject == null: subject = view
	if subject == null: return
	subject.visible = true
	subject.position = center
	var nearest = null
	for bolt in living.bolts:
		bolt.mi.visible = false
		bolt.next = 1000.0
		bolt.start = -10.0
		if bolt.light == null: continue
		if nearest == null or bolt.pos.distance_to(center) < nearest.pos.distance_to(center): nearest = bolt
	get_window().size = Vector2i(3840, 2160)
	for radius in [170, 60]:
		for lit in [false, true]:
			if nearest != null: nearest.start = living.clock - 0.025 if lit else -10.0
			living._process(0.0)
			await _shot("storm_fog_c%d_charge_%s.png" % [radius, "on" if lit else "off"])
		await _hull_mask(subject, "storm_fog_c%d_charge_mask.png" % radius)
	var scattering = null
	for bolt in living.bolts:
		bolt.start = -10.0
		if bolt.light == null or bolt.light.light_volumetric_fog_energy <= 0.0: continue
		if scattering == null or bolt.pos.distance_to(center) < scattering.pos.distance_to(center): scattering = bolt
	if scattering != null:
		scattering.start = living.clock - 0.025
		living._process(0.0)
		var energy: float = scattering.light.light_volumetric_fog_energy
		# Same direct hull light and shader charge in both frames. Only the
		# renderer's actual volumetric light injection changes.
		for lit in [false, true]:
			scattering.light.light_volumetric_fog_energy = energy if lit else 0.0
			await _shot("storm_fog_c60_scattering_%s.png" % ["on" if lit else "off"])
		scattering.light.light_volumetric_fog_energy = energy
	get_window().size = RES
	# Fixed 30 fps playback through the real flash envelope and light update.
	for frame in 36:
		living.clock = float(frame) / 30.0
		for bolt in living.bolts: bolt.start = -10.0
		if nearest != null:
			nearest.start = 0.20
			nearest.mi.visible = true
		living._process(0.0)
		await _shot("storm_fog_c170_motion_%03d.png" % frame)
	var light_file := FileAccess.open(out.path_join("light_metadata.json"), FileAccess.WRITE)
	light_file.store_string(JSON.stringify({"center": [center.x, center.y, center.z],
		"nearest_light_distance": nearest.pos.distance_to(center) if nearest != null else null,
		"light_range": nearest.light.omni_range if nearest != null else null,
		"tier": str(args.get("terrain-tier", "max")), "motion_fps": 30,
		"ribbons_hidden_in_charge_pairs": true}, "  ") + "\n")
	light_file.close()
