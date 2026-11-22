extends SceneTree
# Issue 1536 (Ryan, Nov 22 2026: "Yes" to showing the Relay in Hold battles): in a Hold battle the board stands the Navy relay
# beacon O3_11 under the hold hex. GitHub has no built ship files, so the check points the props' manifest at a stub box
# scene (fixtures/beacon) and checks, on a small board:
#   a Hold battle: exactly one relay_beacon node, centred under the hold hex, no longer than BEACON_LEN and inside its hex,
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


func _board(obj) -> Node3D:
	var hexes := []
	for q in range(-3, 4):
		for r in range(-3, 4):
			if absi(q + r) <= 3:
				hexes.append({"q": q, "r": r})
	var rules := StubRules.new()
	rules.v = {"hexes": hexes, "terrain": {}, "obj": obj}
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


func _run() -> void:
	A4P._man = {"ships": {"O3_11": {"res": STUB}}}
	var hold := {"type": "hold", "hex": {"q": 1, "r": -1}, "score": 0, "escore": 0}
	A4P.prefetch_beacon()
	_check(A4P._pending.has(STUB), "the beacon prefetch did not start a threaded load")
	var board := _board(hold)
	_check(A4P._pending.is_empty(), "the board build left the beacon prefetch uncollected")
	var found := _beacons(board)
	_check(found.size() == 1, "a Hold battle draws %d relay beacons, want 1" % found.size())
	if found.size() == 1:
		var box := _box(found[0] as Node3D)
		var hex: Vector3 = board.hex_world(1.0, -1.0)
		var c := box.get_center()
		_check(Vector2(c.x - hex.x, c.z - hex.z).length() < 0.05, "the beacon's centre is %.2f off the hold hex" % Vector2(c.x - hex.x, c.z - hex.z).length())
		var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
		_check(longest <= BOARD.BEACON_LEN + 0.05 and longest > 0.5 * BOARD.BEACON_LEN, "the beacon's longest side is %.2f, want up to %.2f" % [longest, BOARD.BEACON_LEN])
		_check(box.end.y < 0.0, "the beacon's top is at %.2f, want under the board plane" % box.end.y)
		_check(maxf(box.size.x, box.size.z) < 2.0 * BOARD.HS, "the beacon (%.2f) is wider than its hex" % maxf(box.size.x, box.size.z))
		var lens: Vector3 = (found[0] as Node3D).global_transform.basis * Vector3.RIGHT
		_check(lens.z > 0.5 and lens.y > 0.3, "the lens points %s, want toward +z and tipped up" % str(lens.normalized()))
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
