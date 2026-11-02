extends SceneTree
# Forward+ GPU/CPU frame probe: 20 box ships, mixed staged kills, pooled aftermath.
const FX := preload("res://fx/fx.gd")
var out := ""

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out = OS.get_environment("PROBE_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -30, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 100, 135), Vector3.ZERO)
	cam.current = true
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0})
	for i in 20:
		var ship := Node3D.new()
		world.add_child(ship)
		ship.position = Vector3((i % 5 - 2) * 26, 0, (i / 5 - 1.5) * 24)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(18, 4, 6)
		bm.subdivide_width = 24
		bm.subdivide_height = 6
		bm.subdivide_depth = 8
		mi.mesh = bm
		ship.add_child(mi)
		fx.add_ship(str(i), ship, {"faction": "corsair", "cls": "Cruiser" if i % 2 == 0 else "Frigate", "size": 0.8 if i % 2 == 0 else 0.55, "meshes": [mi]})
	await fx.warmup(cam)
	# Prebuild all cuts before measuring the first death.
	for frame in 540:
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw
	var frame_ms: Array = []
	var fx_ms: Array = []
	fx.prof_take()
	var previous := Time.get_ticks_usec()
	for frame in 660:
		if frame < 400 and frame % 20 == 0: fx.death(str(frame / 20), "blast")
		var start := Time.get_ticks_usec()
		fx.step(1.0 / 60.0)
		fx_ms.append((Time.get_ticks_usec() - start) / 1000.0)
		await RenderingServer.frame_post_draw
		var stamp := Time.get_ticks_usec()
		var ms := (stamp - previous) / 1000.0
		frame_ms.append(ms)
		var prof: Dictionary = fx.prof_take()
		if ms > 20.0: print("FLEET_HITCH frame=%d ms=%.2f process_ms=%.2f physics_ms=%.2f fx=%s" % [frame, ms, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, str(prof)])
		if frame in [180, 380, 580]: vp.get_texture().get_image().save_png(out.path_join("fleet_%d.png" % frame))
		previous = Time.get_ticks_usec()  # image readback/file I/O are outside the frame measurement
	frame_ms.sort()
	fx_ms.sort()
	var sum_ms := 0.0
	for ms in frame_ms: sum_ms += ms
	var p99: float = frame_ms[int(frame_ms.size() * 0.99)]
	var worst_sum := 0.0
	var worst_n := maxi(1, ceili(frame_ms.size() * 0.01))
	for i in range(frame_ms.size() - worst_n, frame_ms.size()): worst_sum += frame_ms[i]
	var low_fps := 1000.0 / maxf(worst_sum / worst_n, 0.001)
	var line := "DESTRUCTION_FLEET ships=20 renderer=%s adapter=%s frames=%d avg_ms=%.3f p99_ms=%.3f one_percent_low_fps=%.1f max_ms=%.3f fx_p99_ms=%.3f particles=%d wrecks=%d" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), frame_ms.size(), sum_ms / frame_ms.size(), p99, low_fps, frame_ms.back(), fx_ms[int(fx_ms.size() * 0.99)], fx.particles_emitted(), fx.dstate["wrecks"].size()]
	print(line)
	FileAccess.open(out.path_join("fleet.txt"), FileAccess.WRITE).store_line(line)
	fx.release()
	quit(0)
