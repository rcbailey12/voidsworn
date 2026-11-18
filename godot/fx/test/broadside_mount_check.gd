extends SceneTree
# godot --headless --path godot --script res://fx/test/broadside_mount_check.gd
# Issue 1117 finding 5: every authored muzzle a volley chooses bears on the target, in all three candidate tiers.

const GUARD := preload("res://tools/ci/check_guard.gd")
const HULL := preload("res://fx/fx_hull.gd")
var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "broadside_mount_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)


func _facing(muzzles: Array, toward: Vector3) -> int:
	var wrong := 0
	for muzzle: Dictionary in muzzles:
		if muzzle.get("src") != "hp" or (muzzle["f"] as Vector3).dot(toward.normalized()) <= 0.0:
			wrong += 1
	return wrong


func _run() -> void:
	var ship := Node3D.new()
	root.add_child(ship)
	for flank in [-1, 1]:
		var socket := Node3D.new()
		socket.name = "hp_w0_battery_P_0" if flank < 0 else "hp_w0_battery_S_1"
		ship.add_child(socket)
		socket.position = Vector3(0, 0, flank * 2)
		socket.rotation.y = 0.0 if flank < 0 else PI
	var hull := HULL.new()
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4, 1, 3)
	body.mesh = mesh
	ship.add_child(body)
	hull.analyse(ship, [body], 0)
	var shots := 0
	var wrong := 0
	for flank in [-1, 1]:
		var target := Vector3(0, 0, flank * 40)
		var muzzles: Array = hull.guns(0, "battery", target, 4)
		shots += muzzles.size()
		wrong += _facing(muzzles, target)
	_check(shots == 8, "two broadsides ask for eight shots")
	_check(wrong == 0, "%d of 8 shots did not use an authored muzzle facing the target (expected 0)" % wrong)
	# the right slot no longer holds the weapon: the by-weapon tier must also bear
	var other_slot: Array = hull.guns(9, "battery", Vector3(0, 0, -40), 4)
	_check(_facing(other_slot, Vector3(0, 0, -40)) == 0, "the by-weapon tier picks only muzzles that bear")
	# the right slot holds another weapon: the slot-only tier must also bear
	var other_weapon: Array = hull.guns(0, "lance", Vector3(0, 0, 40), 4)
	_check(_facing(other_weapon, Vector3(0, 0, 40)) == 0, "the slot-only tier picks only muzzles that bear")
	# no authored muzzle bears: the fallback shoots from the side the target is on, never backward
	var ahead := Vector3(40, 0, 0)
	var fallback: Array = hull.guns(0, "battery", ahead, 4)
	var backward := 0
	for muzzle: Dictionary in fallback:
		if (muzzle["f"] as Vector3).dot(ahead.normalized()) <= 0.0:
			backward += 1
	_check(fallback.size() == 4 and backward == 0, "a shot with no usable socket keeps a muzzle facing the target")
	ship.free()
	print("PASS broadside muzzles face the target" if failures == 0 else "FAIL broadside mounts: %d" % failures)
	quit(0 if failures == 0 else 1)
