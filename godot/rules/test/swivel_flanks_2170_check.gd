extends SceneTree

const Rules = preload("res://rules/rules.gd")


func _init() -> void:
	var rules := Rules.new()
	var failures := 0
	for facing in 6:
		var ship := {"q": 0, "r": 0, "facing": facing, "fx": {"chaser": 1}}
		for q in range(-8, 9):
			for r in range(-8, 9):
				if q == 0 and r == 0:
					continue
				var target := {"q": q, "r": r}
				var a := rules.relAng(ship, target)
				for arc: String in ["P", "S"]:
					var side := a if arc == "S" else -a
					var expected := side >= -0.5 and side <= 150.5
					if rules.chaserArc(ship, {"arc": arc, "k": "fixed"}, target) != expected:
						failures += 1
	if failures > 0:
		printerr("FAIL: Swivel Arc Mounts must widen toward the bow without adding the aft band (%d bearings)" % failures)
	else:
		print("PASS: mirrored Swivel Arc Mounts bearings on all six headings")
	quit(1 if failures else 0)
