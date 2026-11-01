extends SceneTree
# F3 round 2 probe (Ryan, Nov 1 16:12: "a ship can explode and it's just empty inside so it's clearly a shell. same with
# the holes in ships"): close stills of a hull's breaches and of its break-up, so the inside of a hole and of a wreck
# piece can be judged, plus the kill from the default battle camera.
#
# For each ship in PROBE_SHIPS (faction:class, comma list): the ship at battle size taken to damage stage 4, then
#   hole_<sec>_front, hole_<sec>_side   close on two section breaches (as fx_breach_probe)
#   hole_zoom                           the whole damaged ship from the kill zoom distance (about 1.6 ship lengths)
#   kill_battle                         the break-up from the battle camera (170 units, the rig's home angle)
#   kill_close_a, _b, _c                the break-up from close, 0.15 s, 1.2 s and 3.5 s after it
#   kill_inside                         0.8 s after, close on the biggest piece's cut face
# Files: <PROBE_OUT>/<faction>_<class>_<shot>.jpg. Env: PROBE_OUT, PROBE_SHIPS, PROBE_W, PROBE_H (default 960x540),
# PROBE_BOX=1 (box ships instead of res://gen hulls, for a quick check without the game's assets).
#
# Run: godot --path godot --fixed-fps 60 --script res://fx/test/fx_inside_probe.gd

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")

var vp: SubViewport
var world: Node3D
var cam: Camera3D
var rig: Camera3D
var fx
var out := "/tmp"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	var W := int(_env("PROBE_W", "960"))
	var H := int(_env("PROBE_H", "540"))
	out = _env("PROBE_OUT", "/tmp/f3_inside")
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	cam = Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	rig = CAMRIG.new()
	world.add_child(rig)
	rig.input_enabled = false
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "unit": 1.0})
	print("[inside] renderer=%s adapter=%s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	var box := _env("PROBE_BOX", "") == "1"
	var warmed := false
	for spec in _env("PROBE_SHIPS", "hegemony:Super-dreadnought,voidsworn:Frigate,corsair:Battle-barge").split(","):
		var fac: String = spec.split(":")[0]
		var cls: String = spec.split(":")[1]
		var tag := ("%s_%s" % [fac, cls]).to_lower().replace("-", "")
		var big := cls != "Frigate"
		var sv: Node3D = _box(fac) if box else _ship(fac, cls, big)
		if not warmed:
			await fx.warmup(cam)
			warmed = true
		var s = fx.ship("C")
		fx.sync_ship("C", {"hp": 12.0, "maxHp": 100.0, "sh": [0, 0, 0, 0],
			"sec": {"prow": {"hp": 3.6, "max": 30.0}, "mid": {"hp": 4.8, "max": 40.0}, "eng": {"hp": 3.6, "max": 30.0}}})
		var frames := 0
		while frames < 3000 and (s._dmg_task >= 0 or frames < 150 or (s._hole_nodes.is_empty() and frames < 900)):
			await _step()
			frames += 1
		var L: float = s.hull.L
		print("[inside] %s L=%.2f holes=%d rebuild frames=%d" % [tag, L, s._hole_nodes.size(), frames])
		# the breaches, close
		var n_sh := 0
		for i in 3:
			if n_sh >= 2:
				break
			for kind in ["a", "b"]:
				var k2 := "%s%d" % [kind, i]
				if not s._anchors.has(k2) or n_sh >= 2:
					continue
				var A: Dictionary = s._anchors[k2]
				var p: Vector3 = A["p"]
				var n: Vector3 = A["n"]
				var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
				var R := L * 0.06
				await _shot(sv.to_global(p + n * R * 5.0 + t1 * R * 1.2), sv.to_global(p), "%s_hole_%s_front" % [tag, k2])
				await _shot(sv.to_global(p + n * R * 2.6 + t1 * R * 4.0 + Vector3(0, R, 0)), sv.to_global(p), "%s_hole_%s_side" % [tag, k2])
				n_sh += 1
		var cw: Vector3 = sv.to_global(s.hull.c)
		var zoom := cw + (Vector3(-0.35, 0.6, 0.75).normalized() * L * 1.6)
		await _shot(zoom, cw, "%s_hole_zoom" % tag)
		# the kill
		var tb: float = fx.death("C", "big")
		var Tb: float = fx.now + tb - 0.6
		await _until(Tb + 0.15)
		await _battle(cw, "%s_kill_battle" % tag)
		await _shot(zoom, cw, "%s_kill_close_a" % tag)
		await _until(Tb + 0.8)
		var piece := _biggest_piece()
		if piece != null:
			var pc: Vector3 = piece.global_position
			await _shot(pc + (cw - pc).normalized() * -0.1 + Vector3(0.3, 0.45, 0.85).normalized() * L * 0.8, pc, "%s_kill_inside" % tag)
		await _until(Tb + 1.2)
		await _shot(zoom, cw, "%s_kill_close_b" % tag)
		await _until(Tb + 3.5)
		await _shot(zoom, cw, "%s_kill_close_c" % tag)
		fx.clear_wreck("C")
		fx.remove_ship("C")
		sv.queue_free()
		for i in 240:
			await _step()
	print("[inside] done")
	quit(0)


func _ship(fac: String, cls: String, big: bool) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_C"
	world.add_child(sv)
	var size: float = 1.25 if big else 0.55
	sv.setup({"id": "C", "fac": fac, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": size}, Vector3.ZERO, true)
	var info := {"faction": fac, "cls": cls, "size": size, "squadron": false, "flagship": big, "code": sv.code}
	if not sv.a4:
		info["meshes"] = sv.meshes
	fx.add_ship("C", sv, info)
	sv.fx_engines = true
	fx.set_engine("C", 0.35)
	return sv


# a closed box hull (the smoke test's stand-in), for a check without res://gen
func _box(fac: String) -> Node3D:
	var r := Node3D.new()
	r.name = "ship_C"
	var model := Node3D.new()
	model.scale = Vector3(1, 1, -1)
	r.add_child(model)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24.0, 4.3, 7.2)
	bm.subdivide_width = 24
	bm.subdivide_height = 6
	bm.subdivide_depth = 8
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.45, 0.46, 0.5)
	am.surface_set_material(0, m)
	model.add_child(mi)
	world.add_child(r)
	fx.add_ship("C", r, {"faction": fac, "cls": "Cruiser", "size": 1.0, "meshes": [mi]})
	return r


func _biggest_piece() -> Node3D:
	var best: Node3D = null
	var bn := -1.0
	for w in fx.dstate.get("wrecks", []):
		for nd in w["nodes"]:
			if is_instance_valid(nd):
				var aabb := 0.0
				for c in (nd as Node).get_children():
					if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
						aabb = maxf(aabb, (c as MeshInstance3D).mesh.get_aabb().get_longest_axis_size())
				if aabb > bn:
					bn = aabb
					best = nd
	return best


func _step() -> void:
	fx.step(1.0 / 60.0)
	await RenderingServer.frame_post_draw


func _until(t: float) -> void:
	while fx.now + 1e-4 < t:
		await _step()


func _shot(from: Vector3, at: Vector3, name: String) -> void:
	cam.current = true
	fx.camera = cam
	cam.look_at_from_position(from, at, Vector3.UP if absf((at - from).normalized().y) < 0.95 else Vector3.RIGHT)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_jpg("%s/%s.jpg" % [out, name], 0.9)
	print("[inside] wrote ", name)


func _battle(at: Vector3, name: String) -> void:
	rig.a = -PI / 2.0
	rig.b = 0.98
	rig.r = 170.0
	rig.t = at
	rig.snap()
	rig.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_jpg("%s/%s.jpg" % [out, name], 0.9)
	print("[inside] wrote ", name)
	cam.current = true
