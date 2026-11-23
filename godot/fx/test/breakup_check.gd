extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1236 round 4 (Ryan, Nov 23: "have the hulks break up a bit more into 3 pieces and spread them across the hex", "every
# ship is breaking at the same spot", "we want variety"). On a 20-long box cruiser with authored joints at -4 and +4:
#   the cut keeps both joints (three main pieces), and the first crack is the joint nearest the last hit, not the core;
#   each breakup (two, three, late) at quality low (effect clock) and high (Jolt) keeps three pieces at real size:
#     two: one piece rides glued on its neighbour for good; three: all part at once; late: glued, then let go about a
#     second after the split;
#   the pieces never run into each other: no more than OVERLAP_MAX of a piece's outline lies inside another's (seen from
#     above), from a second and a half after the last joint let go to the end, glued pairs aside;
#   they spread: at rest the pieces have turned apart by at least SPREAD_YAW, and lie no farther than FAR_MAX lengths out;
#   the pick is the same for the same ship, cause and hit, and different ships and hits give all three.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const OVERLAP_MAX := 0.02
const SPREAD_YAW := 0.3
const FAR_MAX := 0.6
var failures := 0


func _init() -> void:
	GUARD.arm(self, "breakup_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _run() -> void:
	await _crack_near_hit()
	for q in ["low", "high"]:
		for kind in ["two", "three", "late"]:
			await _breakup(q, kind)
	await _warmed_late_hit()
	_pick()
	print("BREAKUP failures=%d" % failures)
	quit(1 if failures else 0)


func _ship(fx, world: Node3D, id: String, joints: Array) -> Variant:
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 3, 5)
	box.subdivide_width = 39
	box.subdivide_height = 3
	box.subdivide_depth = 7
	mi.mesh = box
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	holder.add_child(mi)
	var seams: Array = []
	for x in joints: seams.append({"p": [x, 0.0, 0.0], "n": [1.0, 0.0, 0.0]})
	holder.set_meta("voidsworn_destruct", {"version": 1, "seams": seams, "interior_materials": [], "machines": []})
	fx.add_ship(id, holder, {"faction": "corsair", "cls": "Cruiser", "size": 1.0})
	return fx.ship(id)


func _fx(world: Node3D, quality: String):
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 60, 1)
	cam.look_at(Vector3.ZERO)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": quality, "camera": cam, "shake": 0.0})
	return fx


func _wait_cut(fx, s) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	return s.get_meta("cut_job", {})


func _crack_near_hit() -> void:
	for hit_x in [-6.0, 7.0]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = _fx(world, "low")
		var s = _ship(fx, world, "h", [-4.0, 4.0])
		s.hull.core = Vector3(-4.0, 0.0, 0.0)   # the core sits on the -4 joint: a hit at +7 must still crack at +4
		s.set_meta("last_hit", [Vector3(hit_x, 1.5, 0.0), Vector3.DOWN, 0.0])
		var r := RandomNumberGenerator.new()
		r.seed = 5
		var plan: Dictionary = DEATH.fracture_plan(fx, s, r)
		var brs: Array = plan["breaks"]
		var first: float = (brs[int(plan["bite_break"])]["at"] as Vector3).x if not brs.is_empty() else INF
		var want := -4.0 if hit_x < 0.0 else 4.0
		check(int(plan["n_main"]) == 3 and brs.size() == 2, "hit at %+.0f: the cut keeps both joints (%d pieces)" % [hit_x, int(plan["n_main"])])
		check(absf(first - want) < 0.3, "hit at %+.0f: the first crack is the joint nearest the hit, %+.0f (at %.2f)" % [hit_x, want, first])
		world.queue_free()
		await process_frame


# the piece's outline seen from above: its mesh's points on the board plane, as a convex hull
func _outline(nd: Node3D) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for c in nd.get_children():
		if c is MeshInstance3D:
			var am: Mesh = (c as MeshInstance3D).mesh
			for si in am.get_surface_count():
				var vs: PackedVector3Array = am.surface_get_arrays(si)[Mesh.ARRAY_VERTEX]
				for k in range(0, vs.size(), 3):
					var g: Vector3 = (c as MeshInstance3D).global_transform * vs[k]
					pts.append(Vector2(g.x, g.z))
	return Geometry2D.convex_hull(pts)


func _inside_share(a: PackedVector2Array, b: PackedVector2Array) -> float:
	if a.size() < 3 or b.size() < 3: return 0.0
	# shrink b a little toward its middle: torn teeth that only touch are not an overlap
	var mid := Vector2.ZERO
	for p in b: mid += p
	mid /= b.size()
	var bs := PackedVector2Array()
	for p in b: bs.append(mid + (p - mid) * 0.97)
	var n := 0
	for p in a:
		if Geometry2D.is_point_in_polygon(p, bs): n += 1
	return float(n) / float(a.size())


func _yaw(nd: Node3D) -> float:
	var x := nd.global_basis.x
	return atan2(-x.z, x.x)


func _breakup(quality: String, kind: String) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world, quality)
	var s = _ship(fx, world, "k", [-4.0, 4.0])
	s.set_meta("breakup_force", kind)
	var job: Dictionary = await _wait_cut(fx, s)
	var tag := "%s %s" % [quality, kind]
	check(int((job.get("plan", {}) as Dictionary).get("n_main", 0)) == 3, "%s: three main pieces cut" % tag)
	fx.death("k", "blast")
	var split := -1.0
	var worst := 0.0
	var worst_at := ""
	var glued_at_end := 0
	var glued_seen := false
	var free_at := -1.0
	var yaw0 := {}
	var t := 0.0
	var w: Dictionary = {}
	for i in 12 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		t += 1.0 / 60.0
		w = {}
		for ww in fx.dstate.get("wrecks", []):
			if ww["id"] == "k": w = ww
		if w.is_empty(): continue
		if split < 0.0:
			split = t
			for nd in w["nodes"]: yaw0[nd.get_instance_id()] = _yaw(nd)
		var nodes: Array = (w["nodes"] as Array).filter(func(n): return is_instance_valid(n))
		var glued := nodes.filter(func(n): return (n as Node).has_meta("glued"))
		if not glued.is_empty(): glued_seen = true
		elif glued_seen and free_at < 0.0: free_at = t - split
		# from a second and a half after the last joint let go (pieces just parted still touch along their torn teeth)
		if t - split >= (1.5 if kind != "late" else DEATH.BREAKUP_SNAP_S + 1.5) and i % 6 == 0:
			var outs := {}
			for nd in nodes: outs[nd] = _outline(nd)
			for a in nodes:
				for b in nodes:
					if a == b: continue
					if (a as Node).has_meta("glued") and (a as Node).get_parent() == b: continue
					if (b as Node).has_meta("glued") and (b as Node).get_parent() == a: continue
					var sh := _inside_share(outs[a], outs[b])
					if sh > worst:
						worst = sh
						worst_at = "%s in %s at +%.2f s" % [str(a.name).get_slice("_", 3), str(b.name).get_slice("_", 3), t - split]
	var nodes: Array = (w.get("nodes", []) as Array).filter(func(n): return is_instance_valid(n))
	for nd in nodes:
		if (nd as Node).has_meta("glued"): glued_at_end += 1
	var scale_ok := true
	var far := 0.0
	var turn_lo := INF
	var turn_hi := -INF
	for nd in nodes:
		for c in nd.get_children():
			if c is MeshInstance3D and not (c as MeshInstance3D).transform.basis.get_scale().is_equal_approx(Vector3.ONE): scale_ok = false
		far = maxf(far, Vector2((nd as Node3D).global_position.x, (nd as Node3D).global_position.z).length() / 20.0)
		var dy: float = wrapf(_yaw(nd) - float(yaw0.get(nd.get_instance_id(), _yaw(nd))), -PI, PI)
		turn_lo = minf(turn_lo, dy)
		turn_hi = maxf(turn_hi, dy)
	print("BREAKUP %s: pieces %d, glued at end %d, let go at %.2f s, worst overlap %.3f (%s), turned %.2f to %.2f rad, farthest %.2f L" % [tag, nodes.size(), glued_at_end, free_at, worst, worst_at, turn_lo, turn_hi, far])
	check(nodes.size() == 3 and scale_ok, "%s: three pieces kept at real size (%d)" % [tag, nodes.size()])
	match kind:
		"two": check(glued_at_end == 1, "%s: one piece rides glued on its neighbour for good" % tag)
		"three": check(not glued_seen, "%s: all three part at once, none glued" % tag)
		"late": check(glued_at_end == 0 and absf(free_at - DEATH.BREAKUP_SNAP_S) < 0.2, "%s: glued, then let go about a second after the split (%.2f s)" % [tag, free_at])
	check(worst <= OVERLAP_MAX, "%s: no piece runs into another (worst %.1f%% of an outline inside another)" % [tag, worst * 100.0])
	check(turn_hi - turn_lo >= SPREAD_YAW, "%s: the pieces turn apart, some diagonal (%.2f rad)" % [tag, turn_hi - turn_lo])
	check(far <= FAR_MAX, "%s: and stay close (farthest middle %.2f lengths out)" % [tag, far])
	world.queue_free()
	await process_frame


# Artoo on PR 1737: the live path reuses a cut warmed before the killing hit. Cut after a hit at -6 (first crack -4), then
# killed by a hit at +7: the +4 joint must part at the death as well, so the hull breaks in three with nothing glued.
func _warmed_late_hit() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world, "low")
	var s = _ship(fx, world, "w", [-4.0, 4.0])
	s.set_meta("last_hit", [Vector3(-6.0, 1.5, 0.0), Vector3.DOWN, 0.0])
	var job: Dictionary = await _wait_cut(fx, s)
	var plan: Dictionary = job.get("plan", {})
	var first: float = (plan["breaks"][int(plan["bite_break"])]["at"] as Vector3).x if not plan.is_empty() else INF
	check(absf(first + 4.0) < 0.3, "warmed: the cut made after a hit at -6 cracks first at -4 (%.2f)" % first)
	s.set_meta("last_hit", [Vector3(7.0, 1.5, 0.0), Vector3.DOWN, fx.now])
	fx.death("w", "blast")
	var glued := false
	var n := 0
	for i in 4 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		for ww in fx.dstate.get("wrecks", []):
			if ww["id"] != "w": continue
			n = (ww["nodes"] as Array).size()
			for nd in ww["nodes"]:
				if is_instance_valid(nd) and (nd as Node).has_meta("glued"): glued = true
	check(str(s.get_meta("death_breakup", "")) == "three" and not glued and n == 3, "warmed: killed by a hit at +7, the +4 joint parts at the death too (%s, glued %s, %d pieces)" % [str(s.get_meta("death_breakup", "")), glued, n])
	world.queue_free()
	await process_frame


func _pick() -> void:
	var seen := {}
	var same := true
	for i in 40:
		var last := [Vector3(float(i % 9) - 4.0, 1.0, float(i % 3)), Vector3.DOWN, 0.0]
		var a: String = DEATH._pick_breakup_for("e%d" % i, "cruiser", last, "blast")
		var b: String = DEATH._pick_breakup_for("e%d" % i, "cruiser", last.duplicate(), "blast")
		same = same and a == b
		seen[a] = true
	check(same, "the pick is the same for the same ship, cause and hit (a replay breaks the same way)")
	check(seen.has("two") and seen.has("three") and seen.has("late"), "different ships and hits give all three breakups (%s)" % str(seen.keys()))
