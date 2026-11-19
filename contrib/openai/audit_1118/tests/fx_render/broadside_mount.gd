extends SceneTree

const HULL := preload("res://fx/fx_hull.gd")

func _initialize() -> void:
	_run.call_deferred()

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
	hull._read_points(ship)
	var wrong := 0
	for flank in [-1, 1]:
		var target := Vector3(0, 0, flank * 40)
		for muzzle: Dictionary in hull.guns(0, "battery", target, 4):
			if muzzle.get("src") != "hp" or (muzzle["f"] as Vector3).dot(target.normalized()) <= 0.0:
				wrong += 1
	print("%s broadside mounts: %d of 8 shots did not use an authored muzzle facing the target (expected 0)" % ["PASS" if wrong == 0 else "FAIL", wrong])
	ship.free()
	quit(0 if wrong == 0 else 1)
