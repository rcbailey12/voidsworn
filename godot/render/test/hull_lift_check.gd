extends SceneTree
# Issue 811: fit an off-centre fixture through real ShipView.setup for every hull code, then exercise the lifted
# ship through a move, idle bob and revival. Effects must read the lifted mesh, while rules positions stay on the hex.
const GUARD := preload("res://tools/ci/check_guard.gd")
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const CAM := preload("res://render/camera_rig.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
const FX := preload("res://fx/fx.gd")
const STUB := preload("res://scenes/battle/fx_stub.gd")
var fails := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "hull_lift_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		push_error("HULL LIFT FAIL: " + message)


func fixture() -> String:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(9.54, 6.1, 2.0)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	mi.position = Vector3(2, 3, -4)
	n.add_child(mi)
	mi.owner = n
	for point in [["hp_core", Vector3(2, 3, -4)], ["hp_w0_nlance_F_0", Vector3(6.77, 3, -4)],
			["hp_eng_0", Vector3(-2.77, 3, -4)]]:
		var hp := Node3D.new()
		hp.name = point[0]
		hp.position = point[1]
		n.add_child(hp)
		hp.owner = n
	var packed := PackedScene.new()
	check(packed.pack(n) == OK, "fixture packs")
	var path := "user://hull_lift_fixture.tscn"
	check(ResourceSaver.save(packed, path) == OK, "fixture saves")
	n.free()
	return path


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var path := fixture()
	var man := {"ships": {}}
	for code in HT.AI_HULLS.values():
		man.ships[code] = {"res": path}
	SV._manifest = man
	var lifted = null
	for key in HT.AI_HULLS:
		var bits: PackedStringArray = key.split("|")
		var code: String = HT.AI_HULLS[key]
		var sv := SV.new()
		world.add_child(sv)
		var origin := Vector3(17, 0, -23)
		sv.setup({"id": code, "fac": bits[0], "cls": bits[1], "code": code, "facing": 2}, origin)
		sv.set_process(false)
		sv.set_marker(true)
		var expected: float = float(HT.HULL_LIFT.get(code, 0.0)) if code == "D20_23" else 0.0
		check(sv.hull_lift == expected, code + " only E14 gets height")
		check(sv.position == origin, code + " rules root stays on its hex")
		var mi: MeshInstance3D = sv.meshes[0]
		var bb: AABB = (sv.global_transform.affine_inverse() * mi.global_transform) * mi.get_aabb()
		check(bb.get_center().is_equal_approx(Vector3.UP * expected), code + " fit centres before lifting")
		check(is_equal_approx(bb.size.x, sv.L), code + " class length is unchanged")
		check(is_equal_approx(sv.ring.position.y, expected - 0.3), code + " selection ring follows")
		check(is_equal_approx(sv.marker.position.y, expected - 0.25), code + " marker follows")
		for e in sv.engines:
			check(is_equal_approx(e.position.y, expected), code + " fallback engine follows")
		check(sv.visual_position().is_equal_approx(origin + Vector3.UP * expected), code + " visual centre follows")
		if code == "D20_23":
			lifted = sv
			check(expected > 0.0, "E14 lift is positive")
			check(bb.position.y - 0.25 >= 0.0, "E14-sized fixture clears the board at the lowest idle bob")
		else:
			sv.free()
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	# Eclipse normally has no shield. Exercise the shielded/captured case on the same raised geometry.
	fx.add_ship("E14", lifted, {"faction": "hegemony", "cls": "Destroyer", "meshes": lifted.meshes})
	var s = fx.ship("E14")
	check(s.to_world(s.hull.core).is_equal_approx(lifted.global_position + Vector3.UP * lifted.hull_lift), "core and weapon aim follow the lifted mesh")
	check(is_equal_approx(s.hull.shield_centre().y, lifted.hull_lift), "shield centre follows")
	check(is_equal_approx(s.hull.points.gun[0].p.y, lifted.hull_lift), "authored muzzle follows")
	check(is_equal_approx(s.hull.nozzles[0].p.y, lifted.hull_lift), "authored engine follows")
	s.shield_hit(fx, Vector3.RIGHT, fx.now, 0.8, 3.0)
	fx.step(0.0)  # make the hit shield visible before moving the hull
	lifted.hull.position.y += 0.2
	var shield_at: Vector3 = lifted.to_local(s._shield_mi.global_position)
	check(is_equal_approx(shield_at.y, lifted.hull_lift + 0.2), "shield follows the lifted hull's bob before the next FX step")
	var stub := STUB.new()
	world.add_child(stub)
	stub.shield(lifted, lifted.L, 0, Color.GREEN)
	check(is_equal_approx(stub.items[0].node.position.y, lifted.hull_lift), "fallback shield follows")
	var cam := CAM.new()
	world.add_child(cam)
	cam.set_process(false)
	var battle := BATTLE.new()
	battle.views = {"E14": lifted}
	check(battle._pos("E14").is_equal_approx(lifted.visual_position()), "battle targets the visual centre")
	cam.focus(battle._pos("E14"))
	check(cam.t.is_equal_approx(lifted.visual_position()), "focus keeps ship height")
	cam.glide(battle._pos("E14"))
	check(cam.t.is_equal_approx(lifted.visual_position()), "activation glide keeps ship height")
	battle.free()
	fx.remove_ship("E14")
	var end: Vector3 = lifted.position + Vector3(12, 0, 0)
	lifted.play_path([{"s": 0.0, "pos": lifted.position}, {"s": 12.0, "pos": end}],
		[{"s": 0.0, "yaw": lifted.cur_yaw}], [], 12.0, 1.0)
	lifted._process(2.0)
	check(lifted.position.is_equal_approx(end), "move ends on the rules hex at zero altitude")
	check(absf(lifted.hull.position.y - lifted.hull_base.y) <= 0.251, "idle bob preserves the fitted lift")
	lifted.die(true)
	lifted.revive()
	lifted._process(0.0)
	check(is_equal_approx(lifted.visual_position().y, lifted.hull_lift), "revival preserves visual height")
	check(absf(lifted.hull.position.y - lifted.hull_base.y) <= 0.251, "revival keeps fitted hull height")
	world.free()
	FX.clear_static()
	SV.clear_static()
	print("HULL LIFT %s: %d checks, %d failures" % ["PASS" if fails == 0 else "FAIL", checks, fails])
	quit(1 if fails else 0)
