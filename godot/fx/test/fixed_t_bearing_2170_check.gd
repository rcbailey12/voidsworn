extends SceneTree

const Hull = preload("res://fx/fx_hull.gd")


func _init() -> void:
	var hull := Hull.new()
	var mount := {"p": Vector3.RIGHT, "n": Vector3.RIGHT, "f": Vector3.RIGHT,
		"arc": "T", "slot": 0, "weapon": "test"}
	hull.points["gun"] = [mount]
	hull.mounts["top"] = []
	var ahead: Dictionary = hull.guns(0, "test", Vector3.RIGHT * 10, 1)[0]
	var astern: Dictionary = hull.guns(0, "test", Vector3.LEFT * 10, 1)[0]
	if ahead.get("src") != "hp" or astern.get("src") == "hp":
		printerr("FAIL: fixed arc-T muzzle must bear on the target like a fixed flank muzzle")
		quit(1)
	else:
		print("PASS: fixed arc-T muzzle selected ahead and rejected astern")
		quit(0)
