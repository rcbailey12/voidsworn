extends SceneTree
# Issue 1877 (Artoo on PR 1904): the Acid Thorn (fx/fx_acid_thorn.gd) rides the ship it is stuck in and goes when that ship
# dies; a missed thorn flies on past. Headless: two box ships, one Chorus volley (one hit, one miss), then the target is
# moved and turned while the thorn is stuck, then killed. Exit 0 and ACID_THORN_CHECK PASS, or exit 1 with the reason
# (run: godot --headless --path godot --script res://fx/test/acid_thorn_check.gd).

const FX := preload("res://fx/fx.gd")

var fx
var fails: Array = []


func _box(name: String, pos: Vector3, L: float) -> Node3D:
	var root := Node3D.new()
	root.name = name
	var model := Node3D.new()
	model.scale = Vector3(1, 1, -1)
	root.add_child(model)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(L, L * 0.18, L * 0.3)
	mi.mesh = bm
	model.add_child(mi)
	root.position = pos
	return root


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _thorns() -> Array:
	return fx.dstate.get("thorn_proj", [])


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 80, 120)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max"})
	var att := _box("chorus_0", Vector3(0, 0, -9), 14.0)
	var tgt := _box("hegemony_0", Vector3(0, 0, 9), 14.0)
	world.add_child(att)
	world.add_child(tgt)
	fx.add_ship("chorus_0", att, {"faction": "chorus", "cls": "Destroyer", "size": 1.0})
	fx.add_ship("hegemony_0", tgt, {"faction": "hegemony", "cls": "Destroyer", "size": 1.0})
	for i in 30:
		fx.step(1.0 / 60.0)
	fx.volley("chorus_0", "bio", "hegemony_0", {"weapon_id": "tendril", "shots": [true, false],
		"hits": [{"shield": 0, "hull": 11, "section": "mid", "crit": false}], "quad": 0, "pd": 0})
	var list := _thorns()
	if list.size() != 2:
		fails.append("expected 2 thorns, got %d" % list.size())
		_end()
		return
	var hit: Dictionary = list[0] if bool(list[0]["stuck"]) else list[1]
	var miss: Dictionary = list[1] if bool(list[0]["stuck"]) else list[0]
	if not bool(miss["miss"]):
		fails.append("no missed thorn")
	if (hit["node"] as Node3D).get_node_or_null("kit_body") == null:
		fails.append("the thorn has no built body (fx/munition_bodies/chorus_bolt.glb)")
	# run to just after the hit lands, then keep the thorn's pose in the target's frame
	while fx.now < float(hit["t1"]) + 0.1:
		fx.step(1.0 / 60.0)
	var hn := hit["node"] as Node3D
	if not hn.visible:
		fails.append("the stuck thorn is not shown")
	var rel0: Transform3D = tgt.global_transform.affine_inverse() * hn.global_transform
	# the missed thorn flew on past its aim point
	var mn := miss["node"] as Node3D
	if fx.now < float(miss["end"]) and mn.visible:
		var past: float = (mn.global_position - (miss["b"] as Vector3)).dot(miss["dir"])
		if past <= 0.0:
			fails.append("the missed thorn did not fly on past (%.2f)" % past)
	# move and turn the target while the thorn is stuck: the thorn keeps its place on the hull
	tgt.position += Vector3(6, 0, 3)
	tgt.rotate_y(0.6)
	for i in 20:
		fx.step(1.0 / 60.0)
	var rel1: Transform3D = tgt.global_transform.affine_inverse() * hn.global_transform
	var drift := rel1.origin.distance_to(rel0.origin)
	if drift > 0.15:
		fails.append("the stuck thorn left the moving hull by %.2f" % drift)
	# the target dies: the stuck thorn goes with it
	fx.death("hegemony_0", "blast")
	for i in 3:
		fx.step(1.0 / 60.0)
	if is_instance_valid(hn) and hn.visible:
		fails.append("the stuck thorn stayed after its ship died")
	print("ACID_THORN_CHECK drift=%.3f" % drift)
	_end()


func _end() -> void:
	if fails.is_empty():
		print("ACID_THORN_CHECK PASS")
		quit(0)
	else:
		for f in fails:
			print("ACID_THORN_CHECK FAIL ", f)
		quit(1)
