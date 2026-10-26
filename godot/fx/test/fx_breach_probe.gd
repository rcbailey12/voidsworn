extends SceneTree
# Probe: one real ship (G2 ShipView) taken to a damage stage, then close-ups of each section's hole from straight on and
# from the side, plus an overview. PROBE_FAC, PROBE_CLS, PROBE_STAGE (2 to 4), PROBE_OUT (a folder), PROBE_AGE (seconds
# after the hole opens).

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(_env("PROBE_W", "640")), int(_env("PROBE_H", "360")))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 40.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.36, 0.4)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	key.shadow_enabled = true
	key.light_energy = 2.2
	world.add_child(key)
	key.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.7, -0.55))
	var sv: Node3D = SV.new()
	world.add_child(sv)
	var pf := _env("PROBE_FAC", "corsair")
	var pc := _env("PROBE_CLS", "Battle-barge")
	sv.setup({"id": "C", "fac": pf, "cls": pc, "facing": 0}, Vector3.ZERO)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max"})
	fx.add_ship("C", sv, {"faction": pf, "cls": pc, "size": 1.3, "meshes": sv.meshes})
	var s = fx.ship("C")
	var st := int(_env("PROBE_STAGE", "4"))
	var hp: float = [1.0, 0.7, 0.5, 0.3, 0.12][st]
	var t_start := Time.get_ticks_msec()
	fx.sync_ship("C", {"hp": 100.0 * hp, "maxHp": 100.0, "sh": [5, 5, 5, 5],
		"sec": {"prow": {"hp": 30.0 * hp, "max": 30.0}, "mid": {"hp": 40.0 * hp, "max": 40.0}, "eng": {"hp": 30.0 * hp, "max": 30.0}}})
	var age := float(_env("PROBE_AGE", "2.5"))
	var frames := 0
	while frames < 2000 and (s._dmg_task >= 0 or fx.now < age):
		fx.step(1.0 / 60.0)
		frames += 1
		await process_frame
	print("BREACH_PROBE hull L=%.2f tris=%d rebuild+apply %d ms (wall), %d frames" % [s.hull.L, s.hull.tri_count, Time.get_ticks_msec() - t_start, frames])
	print("BREACH_PROBE worker compute %s ms" % str(s._dmg_job.get("out", {}).get("ms", -1)))
	var tris := 0
	for m in s.meshes:
		var mi := m as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var a: Array = mi.mesh.surface_get_arrays(si)
			tris += (a[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if a[Mesh.ARRAY_INDEX] != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	print("BREACH_PROBE hull tris now %d (was %d); interior nodes %d" % [tris, s.hull.tri_count, s._hole_nodes.size()])
	for n in s._hole_nodes:
		if n is MeshInstance3D:
			print("  inside: %d tris" % [(n as MeshInstance3D).mesh.get_faces().size() / 3])
	var out := _env("PROBE_OUT", "/tmp")
	var shots: Array = []
	var L: float = s.hull.L
	shots.append(["overview", sv.to_global(s.hull.c + Vector3(-0.15 * L, 0.55 * L, 0.75 * L)), sv.to_global(s.hull.c)])
	for i in 3:
		for kind in ["a", "b"]:
			var key2 := "%s%d" % [kind, i]
			if not s._anchors.has(key2):
				continue
			var A: Dictionary = s._anchors[key2]
			var p: Vector3 = A["p"]
			var n: Vector3 = A["n"]
			var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
			var R := L * 0.06
			shots.append(["%s_front" % key2, sv.to_global(p + n * R * 5.0 + t1 * R * 1.2), sv.to_global(p)])
			shots.append(["%s_side" % key2, sv.to_global(p + n * R * 2.6 + t1 * R * 4.0 + Vector3(0, R, 0)), sv.to_global(p)])
	var only := _env("PROBE_ONLY", "")
	for sh in shots:
		if only != "" and not (sh[0] as String).contains(only):
			continue
		cam.look_at_from_position(sh[1], sh[2])
		for i in 3:
			fx.step(1.0 / 60.0)
			await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png("%s/%s.png" % [out, sh[0]])
		print("wrote ", sh[0])
	quit()
