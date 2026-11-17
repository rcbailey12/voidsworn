extends "res://world/nebula_capture.gd"
# Refs #368, run 6. Fixed-clock presentation of the real generated board.
# Only the first burst due time is set; production updates build every strike.
var _bolt_screen_rows: Array = []


func _capture_routes() -> void:
	await _build("base", 4207)
	if PG.stop_if_any(): return
	volleys_on = false
	b.hud.visible = false
	b.set_process(false)
	b.gfx.manual = true
	# Let real warmup flashes leave the rolling safety window before the fixed burst.
	for frame in 240: b.gfx.step(1.0 / 120.0)
	b.gfx.flash_area_logging = true
	if args.has("reduced"): b.set_fx_opts(true, 0.0)
	b.cam.set_process(false)
	b.world.set_process(false)
	var living = b.world._living
	living.set_process(false)
	var subject = null
	for view in _views():
		view.set_process(false)
		view.visible = false
		if str(view.u.cls) == "Cruiser" and subject == null: subject = view
	if subject == null:
		push_error("Issue 368: real cruiser missing")
		get_tree().quit(1)
		return
	subject.visible = true
	var centers := {}
	for kind in ["neb", "storm"]:
		var patches: Array = living._patches(b.world._terr_pts[kind])
		patches.sort_custom(func(a, z): return a.size() > z.size())
		var center := Vector3.ZERO
		for point in patches[0]: center += point
		centers[kind] = center / float(patches[0].size())
	var nearest = null
	for bolt in living.bolts:
		bolt.next = 1000.0
		bolt.start = -10.0
		if nearest == null or bolt.pos.distance_to(centers.storm) < nearest.pos.distance_to(centers.storm): nearest = bolt
	if "_storm_bursts" in living:
		var closest = null
		for burst in living._storm_bursts:
			burst.next = 1000.0
			if closest == null or burst.center.distance_to(centers.storm) < closest.center.distance_to(centers.storm): closest = burst
		if closest != null: closest.next = 0.6
	elif nearest != null:
		nearest.next = 0.6
	living.clock = 0.0
	living._process(0.0)
	var samples := [0.58, 0.69, 0.77, 0.86, 0.96, 1.10]
	var snapshots: Array = []
	for index in samples.size():
		var target: float = samples[index]
		# Book flash area from the standard battle camera before each sample.
		b.cam.t = centers.storm
		b.cam.r = 170.0
		b.cam.snap()
		while living.clock < target - 0.00001:
			var dt := minf(1.0 / 120.0, target - living.clock)
			b.gfx.step(dt)
			living._process(dt)
		_capture_center = centers.storm
		subject.position = _capture_center
		await _shot("storm_c170_strike_%02d.png" % index)
		await _shot("storm_c60_strike_%02d.png" % index)
		var row := {"time": living.clock, "bolts": []}
		for bolt in living.bolts:
			row.bolts.append({"pos": [bolt.pos.x, bolt.pos.y, bolt.pos.z], "age": living.clock - float(bolt.start),
				"radiance": bolt.mi.get_instance_shader_parameter("flash"),
				"branch_radiance": bolt.mi.get_instance_shader_parameter("branch_flash"),
				"forks": bolt.get("fork_paths", []).size(), "soft": bolt.get("soft", false), "light": bolt.light.light_energy if bolt.light != null else 0.0})
		snapshots.append(row)
		if index == 3:
			for kind in ["neb", "storm"]:
				_capture_center = centers[kind]
				subject.position = _capture_center
				for radius in [170, 60]:
					await _shot("%s_c%d_peak.png" % [kind, radius])
					if args.has("four-k"):
						get_window().size = Vector2i(3840, 2160)
						await _shot("%s_c%d_peak_4k.png" % [kind, radius])
						await _shot("%s_c%d_peak_4k_clear.png" % [kind, radius])
						get_window().size = RES
	var file := FileAccess.open(out.path_join("lightning_metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 4207, "terrain_sha256": str(b.api.R.B.terrain).sha256_text(),
		"centers": centers, "tier": str(args.get("terrain-tier", "max")), "samples": snapshots,
		"world_sha256": FileAccess.get_sha256("res://world/world_living.gd"),
		"ion_sha256": FileAccess.get_sha256("res://world/ion_storm.gd"), "patches": patch_rows,
		"screen_rows": _bolt_screen_rows,
		"burst_sizes": living._storm_bursts.map(func(burst): return burst.bolts.size()),
		"glow_enabled": b.env.glow_enabled, "glow_intensity": b.env.glow_intensity,
		"reduced": b.reduce_flashing, "flash_requests": b.gfx.flash_area_log}, "  ") + "\n")
	file.close()
	b.queue_free()
	b = null


func _shot(name: String) -> void:
	await super._shot(name)
	if not name.begins_with("storm_") or name.ends_with("_clear.png"): return
	var row := {"file": name, "bolts": []}
	for bolt in b.world._living.bolts:
		var points: Array = []
		for path in [bolt.get("path", [])] + bolt.get("fork_paths", []):
			for point in path:
				var screen: Vector2 = b.cam.unproject_position(point)
				points.append([screen.x, screen.y])
		row.bolts.append({"points": points, "radiance": bolt.mi.get_instance_shader_parameter("flash")})
	_bolt_screen_rows.append(row)
