extends SceneTree

const FX := preload("res://fx/fx.gd")
const SHIPS := 20
const FRAMES := 720
const STEP := 1.0 / 120.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(65, 100, 105)
	camera.look_at(Vector3(25, 0, 10))
	camera.current = true

	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max"})
	var box := BoxMesh.new()
	box.size = Vector3(12, 2.5, 4)
	var hull := ArrayMesh.new()
	hull.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	var bodies: Array[Node3D] = []
	var ships: Array = []
	for i in SHIPS:
		var body := Node3D.new()
		world.add_child(body)
		body.position = Vector3(-20 + (i % 5) * 9, 0, floori(i / 5.0) * 16)
		bodies.append(body)
		var mesh := MeshInstance3D.new()
		mesh.mesh = hull
		body.add_child(mesh)
		fx.add_ship(str(i), body, {"faction": "corsair", "shielded": false, "meshes": [mesh]})
		var ship = fx.ship(str(i))
		ship._eng_cur = 1.5
		ships.append(ship)

	var frames_us: Array[int] = []
	var submissions: Array[int] = []
	for frame in FRAMES + 360:
		fx.now += STEP
		RenderingServer.global_shader_parameter_set(&"scene_t", fx.now)
		var began := Time.get_ticks_usec()
		for i in SHIPS:
			bodies[i].position.x += 8.0 * STEP
			ships[i]._update_trails(fx, true)
		var elapsed := Time.get_ticks_usec() - began
		if frame >= 360:
			var submitted := 0
			for ship in ships:
				for trail in ship._trails:
					if trail.mi.visible and is_equal_approx(float(trail.get("mesh_time", fx.now)), fx.now):
						submitted += 1
			frames_us.append(elapsed)
			submissions.append(submitted)
		await process_frame
		await RenderingServer.frame_post_draw

	var args := OS.get_cmdline_user_args()
	var out := FileAccess.open(args[0], FileAccess.WRITE) if args.size() == 1 else null
	if out == null or submissions.max() <= 0:
		push_error("Trail probe needs an output path and a visible exhaust trail.")
		quit(1)
		return
	out.store_line(JSON.stringify({"adapter": RenderingServer.get_video_adapter_name(),
		"fx_ship_sha256": FileAccess.get_sha256("res://fx/fx_ship.gd"),
		"probe_sha256": FileAccess.get_sha256(get_script().resource_path),
		"ships": SHIPS, "step": STEP, "motion_units_per_second": 8,
		"cpu_us": frames_us, "mesh_submissions": submissions}))
	out.close()
	world.queue_free()
	await process_frame
	FX.clear_static()
	quit()
