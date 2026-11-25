extends SceneTree
# Issues 1877 and 2142: the built Acid Thorn vanishes when it hits the hull, and a miss flies past without a jump.

const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")

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
	GUARD.arm(self, "acid_thorn_check")
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
	var miss_first := bool(list[0]["miss"])
	var hit: Dictionary = list[1] if miss_first else list[0]
	var miss: Dictionary = list[0] if miss_first else list[1]
	if bool(hit["miss"]) or not bool(miss["miss"]):
		fails.append("expected one hit and one miss")
	if (hit["node"] as Node3D).get_node_or_null("kit_body") == null:
		fails.append("the thorn has no built body (fx/munition_bodies/chorus_bolt.glb)")
	var hn := hit["node"] as Node3D
	fx.now = float(hit["t1"]) - 0.01
	fx.step(0.0)
	if not hn.is_visible_in_tree():
		fails.append("the hull-hit thorn is not shown on approach")
	fx.now = float(hit["t1"])
	fx.step(0.0)
	if hn.is_visible_in_tree() or not hn.is_queued_for_deletion() or _thorns().has(hit):
		fails.append("the intact thorn stayed at the hull after contact")
	# the missed thorn flew on past its aim point
	# no jump where the flight ends and the pass-through begins (Artoo on PR 1904): one frame either side of t1
	var mn := miss["node"] as Node3D
	while fx.now + 1.0 / 60.0 < float(miss["t1"]):
		fx.step(1.0 / 60.0)
	var before := mn.global_position
	fx.step(1.0 / 60.0)
	fx.step(1.0 / 60.0)
	var step_len := mn.global_position.distance_to(before)
	var expect: float = float(miss["spd"]) * 2.0 / 60.0
	if step_len > expect * 1.6:
		fails.append("the missed thorn jumped %.2f across its aim point (two frames of flight are %.2f)" % [step_len, expect])
	while fx.now < float(miss["t1"]) + 0.2:
		fx.step(1.0 / 60.0)
	if not mn.visible:
		fails.append("the missed thorn vanished at its aim point")
	else:
		var past: float = (mn.global_position - (miss["b"] as Vector3)).dot(miss["dir"])
		if past <= 0.0:
			fails.append("the missed thorn did not fly on past (%.2f)" % past)
	_end()


func _end() -> void:
	if fails.is_empty():
		print("ACID_THORN_CHECK PASS")
		quit(0)
	else:
		for f in fails:
			print("ACID_THORN_CHECK FAIL ", f)
		quit(1)
