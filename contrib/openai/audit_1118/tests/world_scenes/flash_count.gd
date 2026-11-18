extends SceneTree

const Gate := preload("res://bench/scene_gate.gd")


func _initialize() -> void:
	# Four distinct rise-and-fall pairs, 0.2 seconds apart. Each bright patch
	# covers the full frame and stays bright for six frames at 60 Hz.
	var rows: Array = []
	for i in 72:
		var high := i >= 12 and i < 60 and i % 12 < 6
		rows.append({"t": float(i) / 60.0, "mean": 0.7 if high else 0.1, "block": 0.7 if high else 0.1})
	var gate := Gate.new()
	var counts: Dictionary = gate._flash_stats(rows)
	gate.free()
	var found := int(counts["mean_max"])
	if found != 4:
		printerr("FAIL: four full-screen flashes in one second counted as %d" % found)
	quit(0 if found == 4 else 1)
