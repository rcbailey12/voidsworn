extends "res://bench/perf_1118.gd"


func _review(_variant: String) -> void:
	var fx = b.gfx
	var ship = fx.ship(side_ids.player[0])
	fx.manual = true
	fx.rng.seed = 2070
	b.set_process(false)
	b.hud.visible = false
	for view in _views():
		view.set_process(false)
		if view.squad_kind.is_empty():
			view.hull.position = view.hull_base
			view.hull.rotation = Vector3.ZERO
	var living = b.world._living
	living.set_process(false)
	for spin in living._hull_spin:
		(spin[0] as Node3D).rotate(spin[1], -float(spin[2]) * living.clock)
	living.clock = 0.08
	for burst in living._storm_bursts:
		burst.next = 1000.0
	for bolt in living.bolts:
		bolt.start = -10.0
	b.cam.screen_shift = 0.0
	if fixture == "dense":
		b.cam.t = b.world._terr_pts.storm[0]
		var nearest = living.bolts[0]
		for bolt in living.bolts:
			if bolt.pos.distance_to(b.cam.t) < nearest.pos.distance_to(b.cam.t):
				nearest = bolt
		nearest.start = living.clock - 0.025
		living._process(0.0)
		for radius in [170, 26]:
			await _capture("storm_%s_%d" % [quality, radius], radius)
		return
	living._process(0.0)
	b.cam.t = ship.root.global_position
	b.cam.a = -PI / 2.0
	b.cam.b = 0.8
	b.cam.r = 26.0
	b.cam.snap()
	# Drop expired warm-up effects, then tick a fixed motion path and one shield
	# hit. Both cameras see the same shield and trail ages.
	fx.step(8.0)
	fx.now = 600.0
	fx.step(0.0)
	ship._eng_cur = 0.3
	ship._moving = 0.0
	var origin: Vector3 = ship.root.position
	for i in 12:
		ship.root.position = origin + Vector3(-0.17, 0.0, 0.08) * (i + 1)
		fx.step(1.0 / 60.0)
		await get_tree().process_frame
	await _capture("battle_170", 170)
	await _capture("battle_26", 26)
	_event("shield_hit", 0)
	for i in 12:
		fx.step(1.0 / 60.0)
		await get_tree().process_frame
	await _capture("shield_hit", 26)
	# Let the first split reach the viewport. The frame after the wreck's
	# submission would already have moved its pieces.
	_event("death", 0)
	for i in 390:
		fx.step(1.0 / 60.0)
		if not fx.dstate.wrecks.is_empty():
			await _capture("first_wreck", 26, 1)
			return
		await get_tree().process_frame
	push_error("Proof capture did not reach the first wreck")
	failures += 1


func _capture(name: String, radius: float, settle := 8) -> void:
	b.cam.r = radius
	b.cam.snap()
	for i in settle:
		await get_tree().process_frame
		await _post()
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty() or image.save_png(out.path_join(name + ".png")) != OK:
		push_error("Proof capture failed: " + name)
		failures += 1
