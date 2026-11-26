extends SceneTree
# Issue 1582 (Fable on PR 1874, item 4): the faction jet code after the headless return in ShipView._puff never runs on
# GitHub, so this gpu-lane smoke runs it in a window: one view per faction, a burst of jets each, stepped until they fade.
# It fails on a script error (check_guard), on a faction that throws nothing, on Hullbreaker grit missing, or on a jet
# left behind. Needs a window (any renderer); not a look check.

const GUARD := preload("res://tools/ci/check_guard.gd")
const SV := preload("res://render/ship_view.gd")
const TP := preload("res://fx/thrust_profile.gd")
var fails := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "thrust_puff_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		push_error("THRUST_PUFF FAIL: " + message)


func _fixture() -> String:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(9.5, 2.0, 3.0)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	n.add_child(mi)
	mi.owner = n
	var hp := Node3D.new()
	hp.name = "hp_core"
	n.add_child(hp)
	hp.owner = n
	var packed := PackedScene.new()
	packed.pack(n)
	var path := "user://thrust_puff_fixture.tscn"
	ResourceSaver.save(packed, path)
	n.free()
	return path


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("THRUST_PUFF SKIP: needs a window (gpu lane)")
		quit(0)
		return
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(30, 120, 140)
	cam.look_at(Vector3(30, 0, 0))
	cam.current = true
	SV._manifest = {"ships": {"H9_23": {"res": _fixture()}}}
	var fx = preload("res://fx/fx.gd").new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam})
	fx.defer_initial_cuts = true
	var views := {}
	var x := 0.0
	for f in TP.TABLE:
		var sv := SV.new()
		world.add_child(sv)
		sv.setup({"id": "jet_" + f, "fac": f, "cls": "Cruiser", "code": "H9_23", "facing": 0}, Vector3(x, 0, 0))
		sv.set_process(false)
		sv.set_marker(f != "corsair")
		sv.set_band(3.0)   # a drop-line too, so the shared line shader compiles in a real renderer
		x += 30.0
		fx.add_ship("jet_" + f, sv, {"faction": f})
		views[f] = sv
	for calm in [false, true]:
		for f in views:
			var sv = views[f]
			sv.calm = calm
			var before: int = fx.pools["stk"].emitted
			for i in 4:
				sv._puff(Vector3(-4, 0, 0), Vector3(-1, 0, 0.2 * i), 1.0)
			var sparks: int = fx.pools["stk"].emitted - before
			check(sv.puffs.size() >= 4, "%s throws its jets (calm %s): %d" % [f, str(calm), sv.puffs.size()])
			var want_sparks: bool = int(TP.of(f)["sparks"]) > 0 and not calm
			check((sparks > 0) == want_sparks, "%s grit %s (calm %s): %d sparks" % [f, "thrown" if want_sparks else "not thrown", str(calm), sparks])
			var styles := {}
			for pf in sv.puffs:
				styles[str(pf.get("style", "gas"))] = true
			check(styles.has(str(TP.of(f)["style"])), "%s draws its own style (%s)" % [f, str(styles.keys())])
		for k in 240:
			for f in views:
				views[f]._puffs_step(1.0 / 60.0)
			fx.step(1.0 / 60.0)
			if k % 30 == 0:
				await process_frame
		for f in views:
			check(views[f].drop != null and views[f].drop.visible, "%s draws its drop-line" % f)
			check(views[f].puffs.is_empty(), "%s's jets all fade and free (calm %s): %d left" % [f, str(calm), views[f].puffs.size()])
	world.queue_free()
	await process_frame
	SV.clear_static()
	print("THRUST_PUFF %s: %d checks, %d failures" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	quit(1 if fails > 0 else 0)
