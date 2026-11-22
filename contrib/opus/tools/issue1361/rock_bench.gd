extends SceneTree
# Cloud direction shots for issue 1361 (compatibility renderer, not the game's Forward+): one rock group per kind.
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var which: String = a[0]
	var out: String = a[1]
	var WR = load("res://world/_before_rocks_tmp.gd" if which == "before" else "res://world/world_rocks.gd")
	RenderingServer.global_shader_parameter_set(&"cam_near", 0.05)
	var root := Node3D.new()
	get_root().add_child(root)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.008, 0.01, 0.016)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.32, 0.36, 0.46)
	e.ambient_light_energy = 0.3
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.glow_enabled = true
	env.environment = e
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.82)
	sun.light_energy = 2.4
	sun.shadow_enabled = OS.get_environment("SHOT_SHADOW") == "1"
	sun.transform = Transform3D(Basis.looking_at(Vector3(-0.6, -0.55, -0.45).normalized(), Vector3.UP), Vector3.ZERO)
	root.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.65, 0.9)
	fill.light_energy = 0.4
	fill.transform = Transform3D(Basis.looking_at(Vector3(0.7, -0.2, 0.5).normalized(), Vector3.UP), Vector3.ZERO)
	root.add_child(fill)
	var kinds := ["stone", "iron", "carbon", "ice", "crystal"]
	var batch = WR.Batch.new()
	var r := RandomNumberGenerator.new()
	for i in kinds.size():
		var kind: String = kinds[i]
		r.seed = 1361 + i
		var c := Vector3((i - 2) * 19.0, 0, 0)
		var m: ShaderMaterial = WR.material(OS.get_environment("SHOT_MAT") if OS.get_environment("SHOT_MAT") != "" else kind, {"haze_max": 0.0})
		m.set_shader_parameter("lift", 1.2)
		m.set_shader_parameter("amb", 0.65)
		m.set_shader_parameter("tumble_k", 0.0)
		var names: Array = WR.names_for(kind)
		for j in 5:
			var big := j == 0
			var s := 6.8 if big else r.randf_range(1.6, 2.6)
			var off := Vector3.ZERO if big else Vector3(r.randf_range(-6, 6), r.randf_range(-3, 4), r.randf_range(3, 7))
			var b := Basis(Quaternion(r.randfn(), r.randfn(), r.randfn(), r.randfn()).normalized())
			batch.add(names[(j * 3 + i) % names.size()], m, true, Transform3D(b.scaled(Vector3.ONE * s), c + off), Vector3.UP, 0.0, r.randf())
		if kind == "crystal":
			var cm: ShaderMaterial = WR.crystal_material({"haze_max": 0.0})
			cm.set_shader_parameter("tumble_k", 0.0)
			var cn: Array = WR.lib().get("crystals", [])
			for j in 2:
				var cb := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3(1, 0, 0), r.randf_range(-0.4, 0.4))
				batch.add(cn[j % cn.size()], cm, true, Transform3D(cb.scaled(Vector3.ONE * 4.5), c + Vector3(r.randf_range(-3, 3), 2.4 + j, r.randf_range(-1, 3))), Vector3.UP, 0.0, r.randf())
	batch.build(root, func(nm): return WR.mesh(nm))
	var cam := Camera3D.new()
	cam.fov = 45.0
	root.add_child(cam)
	var shots := {"wide": [Vector3(0, 0.557, 0.83) * 100.0, Vector3.ZERO]}
	for i in kinds.size():
		shots[kinds[i]] = [Vector3((i - 2) * 19.0, 0, 0) + Vector3(0, 0.45, 0.89) * float(OS.get_environment("SHOT_D") if OS.get_environment("SHOT_D") != "" else "26"), Vector3((i - 2) * 19.0, 0, 0)]
	for key in shots:
		cam.look_at_from_position(shots[key][0], shots[key][1], Vector3.UP)
		for f in 8:
			await process_frame
		get_root().get_texture().get_image().save_png(out + "/" + which + "_" + key + ".png")
	quit()
