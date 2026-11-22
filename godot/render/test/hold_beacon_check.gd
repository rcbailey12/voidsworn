extends SceneTree
# Issue 1536 (Ryan, Nov 22 2026: "Yes" to showing the Relay in Hold battles): in a Hold battle the board stands the Navy relay
# beacon O3_11 under the hold hex. GitHub has no built ship files, so the check points the props' manifest at a stub box
# scene (fixtures/beacon) and checks, on a small board:
#   a Hold battle (two hold hexes, one well off the camera's axis): exactly one relay_beacon node, its middle within 1 px
#     of the hold hex's centre through the real battle camera at its opening view, no longer than BEACON_LEN and inside its hex,
#     its top under the board plane (a ship holding the hex floats over it), its lens (+x) turned toward +z and tipped up;
#   a battle with another objective: no beacon;
#   a Hold battle on a build without O3_11: no beacon and no error (the gold hex alone, as before);
#   a stale manifest row naming a missing file: no beacon, and no load is tried (PR 1561 review);
#   the threaded prefetch the battle starts (A4P.prefetch_beacon) is collected by the board build, none left pending.

const GUARD := preload("res://tools/ci/check_guard.gd")
const BOARD := preload("res://render/board.gd")
const A4P := preload("res://assets/ships/a4_props.gd")
const STUB := "res://render/test/fixtures/beacon/beacon_stub.tscn"

class StubRules extends RefCounted:
	var v := {}
	func view() -> Dictionary:
		return v

var failures := 0


func _init() -> void:
	GUARD.arm(self, "hold_beacon_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


const RIG := preload("res://render/camera_rig.gd")
const UNITS := [{"id": "p1", "side": "player", "q": 0, "r": 3}, {"id": "p2", "side": "player", "q": 1, "r": 2},
	{"id": "e1", "side": "enemy", "q": 0, "r": -3}, {"id": "e2", "side": "enemy", "q": -1, "r": -2}]


func _board(obj) -> Node3D:
	var hexes := []
	for q in range(-3, 4):
		for r in range(-3, 4):
			if absi(q + r) <= 3:
				hexes.append({"q": q, "r": r})
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": {}, "obj": obj, "units": UNITS}
	var board: Node3D = BOARD.new()
	root.add_child(board)
	board.build(rules)
	return board


func _beacons(board: Node3D) -> Array:
	return board.find_children("relay_beacon", "", true, false)


func _box(n: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	return box


# The real battle camera (render/camera_rig.gd) at its opening view, as battle.gd sets it: the beacon's middle and the
# hold hex's centre must land within 1 pixel of each other on a 1600 x 900 screen (Ryan's "Lift it onto the hex", Nov 22).
func _beacon_checks(board: Node3D, hx: Vector2i) -> void:
	var found := _beacons(board)
	_check(found.size() == 1, "a Hold battle at %s draws %d relay beacons, want 1" % [str(hx), found.size()])
	if found.size() != 1:
		return
	var box := _box(found[0] as Node3D)
	var hex: Vector3 = board.hex_world(float(hx.x), float(hx.y))
	var vp := SubViewport.new()
	vp.size = Vector2i(1600, 900)
	root.add_child(vp)
	var cam: Camera3D = RIG.new()
	vp.add_child(cam)
	cam.current = true
	var hv: Dictionary = board.home_view(UNITS)
	cam.home = hv["target"]
	cam.reset_view()
	cam.home_r = hv["r"]
	cam.r = cam.home_r
	cam.snap()
	var px := cam.unproject_position(box.get_center()).distance_to(cam.unproject_position(hex))
	_check(px < 1.0, "from the opening camera the beacon's middle is %.1f px off the hold hex %s" % [px, str(hx)])
	_check(not cam.is_position_behind(hex), "the opening camera does not see the hold hex %s" % str(hx))
	vp.free()
	var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	_check(longest <= BOARD.BEACON_LEN + 0.05 and longest > 0.5 * BOARD.BEACON_LEN, "the beacon's longest side is %.2f, want up to %.2f" % [longest, BOARD.BEACON_LEN])
	_check(box.end.y < 0.0, "the beacon's top is at %.2f, want under the board plane" % box.end.y)
	_check(maxf(box.size.x, box.size.z) < 2.0 * BOARD.HS, "the beacon (%.2f) is wider than its hex" % maxf(box.size.x, box.size.z))
	var lens: Vector3 = (found[0] as Node3D).global_transform.basis * Vector3.RIGHT
	_check(lens.z > 0.5 and lens.y > 0.3, "the lens points %s, want toward +z and tipped up" % str(lens.normalized()))


func _run() -> void:
	A4P._man = {"ships": {"O3_11": {"res": STUB}}}
	var hold := {"type": "hold", "hex": {"q": 1, "r": -1}, "score": 0, "escore": 0}
	A4P.prefetch_beacon()
	_check(A4P._pending.has(STUB), "the beacon prefetch did not start a threaded load")
	var board := _board(hold)
	_check(A4P._pending.is_empty(), "the board build left the beacon prefetch uncollected")
	_beacon_checks(board, Vector2i(1, -1))
	board.free()
	# Artoo on PR 1561: a hold hex well off the camera's axis (far left, on the enemy side) must read centred too
	var far := {"type": "hold", "hex": {"q": -3, "r": 0}, "score": 0, "escore": 0}
	board = _board(far)
	_beacon_checks(board, Vector2i(-3, 0))
	board.free()
	board = _board({"type": "rout"})
	_check(_beacons(board).is_empty(), "a Rout battle draws a relay beacon")
	board.free()
	A4P._man = {"ships": {}}
	board = _board(hold)
	_check(_beacons(board).is_empty(), "a build without O3_11 draws a relay beacon")
	board.free()
	A4P._man = {"ships": {"O3_11": {"res": "res://render/test/fixtures/beacon/missing_beacon.scn"}}}
	_check(A4P._res("O3_11") == "", "a stale manifest row still names a file to load")
	A4P.prefetch_beacon()
	_check(A4P._pending.is_empty(), "a stale manifest row started a threaded load")
	board = _board(hold)
	_check(_beacons(board).is_empty(), "a stale manifest row draws a relay beacon")
	board.free()
	A4P._man = null
	print("hold_beacon_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
