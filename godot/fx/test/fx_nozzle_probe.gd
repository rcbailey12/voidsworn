extends SceneTree
# Engines on A4's kit ships (r13): every built ship in gen/manifest.json "ships" goes through G2's ShipView and fx; prints
# where the engines came from (the kit's hp_eng_* hard points, or the stern-face guess) and writes a rear three-quarter
# still of each with the engines at a burn, so the plumes and trails can be checked against the real bells.
# run: godot --path godot --resolution 1280x720 --script res://fx/test/fx_nozzle_probe.gd   (PROBE_OUT, PROBE_MAX)

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	var out := _env("PROBE_OUT", "/tmp")
	var mx := int(_env("PROBE_MAX", "12"))
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.85, 1.0)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	w.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, -60, 0)
	key.light_energy = 2.0
	w.add_child(key)
	var cam := Camera3D.new()
	w.add_child(cam)
	var fx = FX.new()
	w.add_child(fx)
	fx.manual = true
	fx.setup({"camera": null, "quality": "max", "starboard_z": 1})
	var man: Dictionary = SV.manifest()
	var codes: Array = (man.get("ships", {}) as Dictionary).keys()
	codes.sort()
	print("NOZZLE ships in manifest: %d" % codes.size())
	var n := 0
	for code in codes:
		if n >= mx:
			break
		n += 1
		var sv: Node3D = SV.new()
		sv.name = "S%d" % n
		w.add_child(sv)
		sv.setup({"id": sv.name, "code": code, "fac": "voidsworn", "cls": "Cruiser", "facing": 0, "hp": 100, "maxHp": 100}, Vector3.ZERO, true)
		var hp := sv.find_children("hp_eng*", "Node3D", true, false).size()
		fx.add_ship(sv.name, sv, {"faction": "voidsworn", "cls": "Cruiser", "size": 1.0, "meshes": sv.meshes, "shielded": false})
		var s = fx.ships[sv.name]
		fx.set_engine(sv.name, 1.6)
		var ps: Array = []
		for nz in s.hull.nozzles:
			ps.append("(%.2f %.2f %.2f r%.2f)" % [nz["p"].x, nz["p"].y, nz["p"].z, nz["r"]])
		print("NOZZLE %s L=%.1f hp_eng=%d from=%s n=%d %s" % [code, float(s.hull.L), hp, "kit" if s.hull.nozzles_from_kit else "stern guess", s.hull.nozzles.size(), " ".join(ps)])
		for i in 40:
			fx.step(1.0 / 30.0)
			await process_frame
		var L: float = s.hull.L
		var c: Vector3 = sv.to_global(s.hull.c)
		cam.fov = 40.0
		cam.look_at_from_position(c + sv.global_transform.basis * (Vector3(-1.1, 0.45, 0.75).normalized() * L * 1.25), c)
		for i in 3:
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("%s/nozzle_%s.png" % [out, code])
		fx.remove_ship(sv.name)
		sv.queue_free()
		await process_frame
	quit()
