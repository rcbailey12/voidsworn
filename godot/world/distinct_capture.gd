extends "res://world/nebula_capture.gd"
# Issue 368 run 4: both kinds on the same generated board, lighting and clock.
# Presentation moves the real cruiser only. No terrain or rule state is authored.


func _capture_routes() -> void:
	await _build("base", 4207)
	if PG.stop_if_any(): return
	volleys_on = false
	b.hud.visible = false
	b.set_process(false)
	b.gfx.manual = true
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
	for kind in ["neb", "storm"]:
		_capture_center = centers[kind]
		subject.position = _capture_center
		for radius in [170, 60]:
			for lit in [false, true]:
				living.clock = 0.08
				if nearest != null: nearest.start = 0.0 if lit else -10.0
				living._process(0.0)
				var stem := "%s_c%d_%s" % [kind, radius, "flash" if lit else "calm"]
				await _shot(stem + ".png")
				if args.has("four-k") and not lit:
					get_window().size = Vector2i(3840, 2160)
					await _shot(stem + "_4k.png")
					await _shot(stem + "_4k_clear.png")
					get_window().size = RES
		if args.has("motion"):
			for frame in 48:
				living.clock = float(frame) / 12.0
				if nearest != null: nearest.start = 0.8
				living._process(0.0)
				await _shot("%s_c170_motion_%03d.png" % [kind, frame])
	_capture_center = (centers.neb + centers.storm) * 0.5
	subject.position = _capture_center
	living.clock = 0.08
	if nearest != null: nearest.start = 0.0
	living._process(0.0)
	await _shot("board_c170_flash.png")
	var board_labels := {}
	for kind in centers:
		var screen: Vector2 = b.cam.unproject_position(centers[kind])
		board_labels[kind] = [screen.x, screen.y]
	var file := FileAccess.open(out.path_join("distinct_metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed": 4207, "terrain_sha256": str(b.api.R.B.terrain).sha256_text(),
		"centers": centers, "board_labels": board_labels, "tier": str(args.get("terrain-tier", "max")), "patches": patch_rows,
		"same_board_and_lighting": true, "motion_fps": 12,
		"world_sha256": FileAccess.get_sha256("res://world/world_living.gd"),
		"ion_sha256": FileAccess.get_sha256("res://world/ion_storm.gd")}, "  ") + "\n")
	file.close()
	b.queue_free()
	b = null
