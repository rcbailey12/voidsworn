extends SceneTree
# Probe: one real ship (G2 ShipView), walk its damage ladder and a shield hit, print what fx built.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _count(n: Node, out: Dictionary) -> void:
	var k := n.get_class()
	out[k] = int(out.get(k, 0)) + 1
	for c in n.get_children():
		_count(c, out)


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(480, 270)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.4, 0.4)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.7, -0.55))
	var sv: Node3D = SV.new()
	world.add_child(sv)
	var pf := OS.get_environment("PROBE_FAC") if OS.get_environment("PROBE_FAC") != "" else "corsair"
	var pc := OS.get_environment("PROBE_CLS") if OS.get_environment("PROBE_CLS") != "" else "Battle-barge"
	sv.setup({"id": "C", "fac": pf, "cls": pc, "facing": 0}, Vector3(10, 0, 5))
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max"})
	fx.add_ship("C", sv, {"faction": pf, "cls": pc, "size": 1.3, "meshes": sv.meshes})
	var s = fx.ship("C")
	print("hull L=%.2f W=%.2f H=%.2f tris=%d samples=%d nozzles=%d box=%s" % [s.hull.L, s.hull.W, s.hull.H, s.hull.tri_count, s.hull.sp.size(), s.hull.nozzles.size(), s.hull.box])
	for st in 5:
		var hp: float = [1.0, 0.7, 0.5, 0.3, 0.12][st]
		fx.sync_ship("C", {"hp": 100.0 * hp, "maxHp": 100.0, "burning": st >= 3, "sh": [5, 5, 5, 5],
			"sec": {"prow": {"hp": 30.0 * hp, "max": 30.0}, "mid": {"hp": 40.0 * hp, "max": 40.0}, "eng": {"hp": 30.0 * hp, "max": 30.0}}})
		for i in 10:
			fx.step(1.0 / 60.0)
		var c := {}
		_count(s._dmg_root, c)
		print("stage %d -> %s nodes %s" % [st, str(s.stage), c])
	s.shield_hit(fx, Vector3(0, 0, 8), fx.now, 1.0, 14.0, 0.6)
	print("shield hits param: ", s._shield_mat.get_shader_parameter("hits"))
	fx.step(0.1)
	print("shield visible: ", s._shield_mi.visible, " until ", s._shield_until, " now ", fx.now)
	cam.look_at_from_position(Vector3(14, 8, 34), Vector3(10, 0, 5))
	if OS.get_environment("PROBE_MODE") == "break":
		fx.shield_break("C", 1)
		fx.step(0.15)
	if OS.get_environment("PROBE_MODE") == "plain":
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0, 1, 0, 0.3)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		s._shield_mi.material_override = m
	print("shield node: vis=%s inside=%s scale=%s pos=%s global=%s" % [s._shield_mi.visible, s._shield_mi.is_inside_tree(), s._shield_mi.scale, s._shield_mi.position, s._shield_mi.global_position])
	for i in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png(OS.get_environment("PROBE_OUT"))
	quit()
