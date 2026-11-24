extends SceneTree
# Issue 1360 STB job helper (PC job opus1360storm, not in the repo): runs bench/scene_gate.tscn --still as is (storm map,
# fixed effect clock, 470 steps) and, once its battle is built, holds the battle camera on the first ion storm patch at
# radius STB_R (170, 60 or 26) every frame. STB_RF=1 turns on the game's Reduced Flashing (battle.set_fx_opts, the path
# main.gd uses for the setting). VS_STORM_BOLTS=ribbon (before) or unset (after, baked) is read by world_living itself.
# Prints [stb] lines: the storm patch it aims at, the radius, and Reduced Flashing.
var sg: Node = null
var said := false
var r := 170.0
var rf := false


func _initialize() -> void:
	r = float(OS.get_environment("STB_R")) if OS.get_environment("STB_R") != "" else 170.0
	rf = OS.get_environment("STB_RF") == "1"
	print("[stb] radius %.0f, reduced flashing %s, bolts %s" % [r, str(rf), OS.get_environment("VS_STORM_BOLTS") if OS.get_environment("VS_STORM_BOLTS") != "" else "baked (default)"])
	sg = load("res://bench/scene_gate.tscn").instantiate()
	root.add_child(sg)


func _find_living(n: Node) -> Node:
	if "_storm_bursts" in n and not (n.get("_storm_bursts") as Array).is_empty():
		return n
	for c in n.get_children():
		var f := _find_living(c)
		if f != null:
			return f
	return null


func _process(_delta: float) -> bool:
	if sg == null or not is_instance_valid(sg):
		return false
	var b = sg.get("b")
	if b == null or not is_instance_valid(b) or b.get("cam") == null or b.get("gfx") == null:
		return false
	if rf and not bool(b.get("reduce_flashing")):
		b.set_fx_opts(true, 0.0)
		print("[stb] reduced flashing on")
	var living := _find_living(b)
	if living == null:
		return false
	var c: Vector3 = (living.get("_storm_bursts") as Array)[0]["center"]
	b.cam.t = Vector3(c.x, 0.0, c.z)
	b.cam.r = r
	b.cam.snap()
	if not said:
		said = true
		print("[stb] aiming at storm patch %s of %d, r %.0f" % [str(c), (living.get("_storm_bursts") as Array).size(), r])
	return false
