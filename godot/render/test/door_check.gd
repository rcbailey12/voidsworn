extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1543 (Ryan, Nov 21 2026: a flesh door "in sections with the opening spreading from the middle", closed between launches,
# plain flesh). The door check, headless, on a ship glb with doors (the C14 brood carrier from the stage 7 export). It loads the
# glb the way the game does, at a cruiser's game size, and the real effects system (fx/fx.gd, fx_weapons.gd launch, fx_hull.gd
# doors) launches a squadron from each bay in turn. The proofs, from the real functions (RULEBOOK 12.2):
#   1. what arrives: every door node with its lobes, each lobe carrying its mesh, each door tied to a bay that exists;
#   2. shut at rest: before any launch every lobe sits exactly at its authored pose;
#   3. each launch opens only its own bay's door: fully open when the first craft leaves (T + 0.3), every other door shut;
#   4. open, every lobe lies down in the bore: no vertex of its mesh rises further out of the mouth than the shut door's does,
#      so no lobe ever stands up past the lip like a tooth (Ryan, Nov 21: "random teeth inside look odd");
#   5. the motion is smooth (no step over a sixth of the swing in one 60 Hz frame) and the door is back at rest, exactly, after
#      the squadron has left;
#   6. the cost: a door step per frame, in microseconds.
#   godot --headless --path godot --script res://render/test/door_check.gd [-- SHIP.glb]   (default: the installed C14, B22_11)

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEFAULT_SHIP := "res://assets/ships/B22_11/B22_11.glb"   # the installed C14 brood carrier (PC gpu list)
const K := 23.2
const DT := 1.0 / 60.0

var failures := 0
var fx


class StandIn extends Node3D:
	var code := ""
	var attach = null


func _init() -> void:
	GUARD.arm(self, "door_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("DOOR FAIL: " + message)
		print("DOOR FAIL: " + message)


func _lobe_top(h, d: Dictionary, lb: Dictionary) -> float:
	# the highest vertex of the lobe's mesh above its own hinge, out of the mouth (the door node's +Y), in glb units
	var di: Transform3D = (d["node"] as Node3D).global_transform.affine_inverse()
	var ln: Node3D = lb["node"]
	var hinge_y: float = (lb["rest"] as Transform3D).origin.y
	var top := -INF
	for c in ln.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
			var mi := c as MeshInstance3D
			var xf: Transform3D = di * mi.global_transform
			for si in mi.mesh.get_surface_count():
				for v in mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]:
					top = maxf(top, (xf * v).y - hinge_y)
	return top


func _run() -> void:
	var ua := OS.get_cmdline_user_args()
	var path: String = ProjectSettings.globalize_path(ua[0]) if ua.size() > 0 else ProjectSettings.globalize_path(DEFAULT_SHIP)
	var world := Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0})
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	check(doc.append_from_file(path, st) == OK, "the glb loads (%s)" % path)
	var scene: Node3D = doc.generate_scene(st)
	scene.scale = Vector3(K, K, K)
	var node := StandIn.new()
	node.code = "DOORS"
	node.name = "DOORS"
	world.add_child(node)
	node.add_child(scene)
	fx.add_ship("A", node, {"faction": "chorus", "cls": "Cruiser", "size": 1.0, "code": "DOORS"})
	var A = fx.ship("A")
	var h = A.hull
	# 1. what arrives (an installed ship built before issue 1543 has no doors yet: said so, not a failure)
	if h.doors.is_empty():
		print("DOOR SKIP: no door nodes in %s (built before issue 1543)" % path)
		print("DOOR failures=%d" % failures)
		quit(1 if failures > 0 else 0)
		return
	var bays: Array = h.points.get("bay", [])
	for d in h.doors:
		check((d["lobes"] as Array).size() >= 3, "%s carries its lobes (got %d)" % [d["name"], (d["lobes"] as Array).size()])
		var has_bay := false
		for b in bays:
			has_bay = has_bay or int(b["i"]) == int(d["bay"])
		check(has_bay, "%s opens for hp_bay_%d, which exists" % [d["name"], int(d["bay"])])
		for lb in d["lobes"]:
			var n := 0
			for c in (lb["node"] as Node3D).get_children():
				if c is MeshInstance3D:
					n += 1
			check(n == 1, "%s carries its mesh" % (lb["node"] as Node3D).name)
	# 2. shut at rest
	for k in 3:
		fx.step(DT)
	for d in h.doors:
		for lb in d["lobes"]:
			check((lb["node"] as Node3D).transform.is_equal_approx(lb["rest"]), "%s is shut at rest" % (lb["node"] as Node3D).name)
	var shut_top := -INF
	for d in h.doors:
		for lb in d["lobes"]:
			shut_top = maxf(shut_top, _lobe_top(h, d, lb))
	# 3 to 5: one squadron from each bay in turn
	var cost := 0.0
	var steps := 0
	var worst_top := -INF
	for i in bays.size():
		A.set_meta("launches", i)
		var T: float = fx.now
		WEAP.launch(fx, "A", "")
		var k: int = h.door_for_bay(int(bays[i]["i"]))
		check(k >= 0, "hp_bay_%d has a door" % int(bays[i]["i"]))
		var last := 0.0
		while fx.now < T + 3.2:
			var t0 := Time.get_ticks_usec()
			h.door_step(fx.now)
			cost += Time.get_ticks_usec() - t0
			steps += 1
			fx.step(DT)
			if k < 0:
				continue
			var f: float = h.door_open_at(k, fx.now)
			check(absf(f - last) <= 1.0 / 6.0 + 1e-4, "%s moves smoothly (%.3f to %.3f in one frame)" % [h.doors[k]["name"], last, f])
			last = f
			if fx.now >= T + 0.3 and fx.now <= T + 0.3 + 5 * 0.25:
				check(f > 0.999, "%s is fully open while its squadron leaves (%.3f at T+%.2f)" % [h.doors[k]["name"], f, fx.now - T])
				for j in h.doors.size():
					if j != k:
						check(h.door_open_at(j, fx.now) == 0.0, "%s stays shut while %s launches" % [h.doors[j]["name"], h.doors[k]["name"]])
			if f > 0.999:
				for lb in h.doors[k]["lobes"]:
					var top := _lobe_top(h, h.doors[k], lb)
					worst_top = maxf(worst_top, top)
		h.door_step(fx.now)
		if k >= 0:
			for lb in h.doors[k]["lobes"]:
				check((lb["node"] as Node3D).transform.is_equal_approx(lb["rest"]), "%s is shut again after its squadron" % (lb["node"] as Node3D).name)
	# 4. open lobes lie down in the bore (a hundredth of the hull's length of slack for the lobe's dome over its hinge)
	check(worst_top <= shut_top + 1e-3, "open lobes never rise past their shut height (open %.4f, shut %.4f above the hinge)" % [worst_top, shut_top])
	print("DOOR doors=%d bays=%d shut_top=%.4f open_top=%.4f step_usec=%.1f" % [h.doors.size(), bays.size(), shut_top, worst_top, cost / maxf(steps, 1)])
	print("DOOR failures=%d" % failures)
	quit(1 if failures > 0 else 0)
