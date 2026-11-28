extends SceneTree
# godot --headless --path godot --script res://fx/test/broadside_mount_check.gd
# Issue 1117 finding 5: every authored muzzle a volley chooses bears on the target, in all three candidate tiers.

const GUARD := preload("res://tools/ci/check_guard.gd")
const HULL := preload("res://fx/fx_hull.gd")
const FX := preload("res://fx/fx.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "broadside_mount_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _facing(muzzles: Array, toward: Vector3) -> int:
	var wrong := 0
	for muzzle: Dictionary in muzzles:
		if muzzle.get("src") != "hp" or (muzzle["f"] as Vector3).dot(toward) <= 0.0 \
				or (muzzle["p"] as Vector3).dot(toward) <= 0.0:
			wrong += 1
	return wrong


func _run() -> void:
	var ship := Node3D.new()
	root.add_child(ship)
	var core := Node3D.new()
	core.name = "hp_core"
	ship.add_child(core)
	for flank in [-1, 1]:
		var socket := Node3D.new()
		socket.name = "hp_w0_battery_P_0" if flank < 0 else "hp_w0_battery_S_1"
		ship.add_child(socket)
		socket.position = Vector3(0, 0, flank * 2)
		socket.rotation.y = 0.0 if flank < 0 else PI
	var other := Node3D.new()
	other.name = "hp_w1_battery_P_0"
	other.position = Vector3(-1, 0, -2)
	ship.add_child(other)
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
		for muzzle: Dictionary in muzzles:
			_check(is_zero_approx((muzzle.get("p", Vector3.INF) as Vector3).x), "the usable exact slot wins over another slot")
	_check(shots == 8, "two broadsides ask for eight shots")
	_check(wrong == 0, "%d of 8 shots did not use an authored muzzle facing the target (expected 0)" % wrong)
	print("Broadside repro: %d of %d shots from the wrong flank or without a facing authored muzzle" % [wrong, shots])
	# the right slot no longer holds the weapon: the by-weapon tier must also bear
	var other_slot: Array = hull.guns(9, "battery", Vector3(0, 0, -40), 4)
	_check(other_slot.size() == 4 and _facing(other_slot, Vector3(0, 0, -40)) == 0, "the by-weapon tier picks only muzzles that bear")
	# the right slot holds another weapon: the slot-only tier must also bear
	var other_weapon: Array = hull.guns(0, "lance", Vector3(0, 0, 40), 4)
	_check(other_weapon.size() == 4 and _facing(other_weapon, Vector3(0, 0, 40)) == 0, "the slot-only tier picks only muzzles that bear")
	# no authored muzzle bears: the fallback shoots from the side the target is on, never backward
	var ahead := Vector3(40, 0, 0)
	var fallback: Array = hull.guns(0, "battery", ahead, 4)
	_check(fallback.size() == 4, "the no-socket fallback keeps four muzzles")
	for muzzle: Dictionary in fallback:
		_check(muzzle.get("src") == "ray" and (muzzle["p"] as Vector3).x > 0.0,
			"a shot with no usable socket starts on plating toward the target")
	var bare := HULL.new()
	bare.analyse(ship, [], 0)
	_check(bare.guns(0, "battery", ahead, 2) == [{}, {}] and bare.skipped() == 2,
		"without a usable socket or plating, both effects are skipped and counted")
	_check_turret(ship, body)
	ship.free()
	print("PASS broadside muzzles face the target and jammed volleys still have a shot" if failures == 0 else "FAIL broadside mounts: %d" % failures)
	quit(0 if failures == 0 else 1)


func _check_turret(ship: Node3D, body: MeshInstance3D) -> void:
	var turret := Node3D.new()
	turret.name = "turret_0"
	turret.position = Vector3(1.5, 1, 0)
	turret.set_meta("extras", {"arc_lo": 80.0, "arc_hi": 100.0})
	ship.add_child(turret)
	var socket := Node3D.new()
	socket.name = "hp_w2_lance_T_0"
	socket.position = Vector3(0, 0, -1)
	turret.add_child(socket)
	var hull := HULL.new()
	hull.analyse(ship, [body], 0)
	var in_arc := Vector3(1.5, 1, -4)
	var out_of_arc := Vector3(0, 1, -4)
	for request in [[2, "lance"], [-1, "lance"], [2, "other"]]:
		var inside: Dictionary = hull.guns(request[0], request[1], in_arc, 1)[0]
		var outside: Dictionary = hull.guns(request[0], request[1], out_of_arc, 1)[0]
		_check(inside.get("tur") == 0 and not inside.get("clamped", true),
			"tier %s uses the turret when the target is in reach from its pivot" % str(request))
		_check(outside.get("src") == "ray", "tier %s falls back when the target is outside the turret's reach" % str(request))
	hull.jam_turret(0, 0.0, 12.0, 0.0)
	var fallback := hull.guns(2, "lance", in_arc, 2)
	_check(fallback.size() == 2, "an all-jammed tier keeps the shot count")
	for muzzle: Dictionary in fallback:
		_check(muzzle.get("src") == "ray" and not muzzle.has("tur") and (muzzle["p"] as Vector3).z < 0.0,
			"an all-jammed tier sends the shot from the target-facing hull, not the frozen turret")
	_check(hull.gun_turrets(2, "lance", in_arc, 2).is_empty(), "an all-jammed tier does not pre-train")
	hull.mounts["stb"] = []
	var plate: Dictionary = hull.guns(2, "lance", in_arc, 1)[0]
	_check(plate.get("src") == "ray" and is_equal_approx((plate["p"] as Vector3).z, -1.5),
		"without a station hit, the jammed volley casts directly to the hull plating")
	var bare := HULL.new()
	bare.analyse(ship, [], 0)
	bare.jam_turret(0, 0.0, 12.0, 0.0)
	var centre: Dictionary = bare.guns(2, "lance", in_arc, 1)[0]
	_check(centre.get("src") == "centre" and centre.get("p") == bare.core and not centre.has("tur"),
		"without triangles, a known frozen battery falls back to the hull core")
	_check_jammed_volley(ship, body, socket)


func _check_jammed_volley(ship: Node3D, body: MeshInstance3D, socket: Node3D) -> void:
	socket.name = "hp_w2_battery_T_0"
	var fx := FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var target := Node3D.new()
	root.add_child(target)
	target.position = Vector3(1.5, 1.0, -12.0)
	var target_body := MeshInstance3D.new()
	target_body.mesh = body.mesh
	target.add_child(target_body)
	fx.add_ship("gun", ship, {"meshes": [body], "shielded": false, "cut_on_arrival": false})
	fx.add_ship("target", target, {"meshes": [target_body], "shielded": false, "cut_on_arrival": false})
	var h = fx.ship("gun").hull
	var opts := {"slot": 2, "weapon_id": "battery", "shots": [true], "hits": [{"hull": 1, "shield": 0, "section": "mid"}]}
	var normal := fx.volley("gun", "battery", "target", opts)
	_check(normal.get("muzzles", []).size() == 1 and int(normal["muzzles"][0]["tur"]) == 0,
		"the live battery would normally fire from this turret")
	h.jam_turret(0, 0.0, 12.0, fx.now)
	var result := fx.volley("gun", "battery", "target", opts)
	_check(result["fires"].size() == 1 and result["impacts"].size() == 1,
		"the jammed battery's legal hit still has one visible shot and impact")
	_check(result.get("muzzles", []).size() == 1 and int(result["muzzles"][0]["tur"]) == -1,
		"the fallback shot never fires or recoils from the jammed turret")
	fx.remove_ship("gun")
	fx.remove_ship("target")
	fx.free()
	target.free()
