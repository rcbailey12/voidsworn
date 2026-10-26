extends SceneTree
# Probe: fire rockets and a torpedo between two box ships and print the projectiles' positions over time.

const FX := preload("res://fx/fx.gd")


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _box(name: String, pos: Vector3) -> Node3D:
	var r := Node3D.new()
	r.name = name
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(26, 5, 7)
	mi.mesh = bm
	r.add_child(mi)
	r.position = pos
	return r


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 44.0
	cam.look_at_from_position(Vector3(10, 22, 70), Vector3(10, 4, 30))
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var a := _box("A", Vector3(46, 0, 30))
	var b := _box("B", Vector3(-46, 0, 30))
	world.add_child(a)
	world.add_child(b)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	fx.add_ship("A", a, {"faction": OS.get_environment("PFAC") if OS.get_environment("PFAC") != "" else "corsair", "size": 1.3})
	fx.add_ship("B", b, {"faction": "voidsworn", "size": 1.3})
	var r: Dictionary = fx.volley("A", "torp", "B", {"weapon_id": "torp", "shots": [true, true], "hits": [{"shield": 5, "hull": 0}, {"shield": 5, "hull": 0}], "pd": 1})
	print("volley ", r)
	for i in 150:
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		if i == int(OS.get_environment("PROBE_I") if OS.get_environment("PROBE_I") != "" else "60") and OS.get_environment("PROBE_OUT") != "":
			vp.get_texture().get_image().save_png(OS.get_environment("PROBE_OUT"))
		if i % 15 == 0:
			var list: Array = fx.dstate.get("proj", [])
			var s := "t=%.2f n=%d" % [fx.now, list.size()]
			for p in list:
				s += " [%s t0=%.2f t1=%.2f pos=%s mesh=%s]" % [p["lk"], p["t0"], p["t1"], str(p.get("pos", "-")), str(p["mesh"] != null and is_instance_valid(p["mesh"]))]
			print(s)
	quit()
