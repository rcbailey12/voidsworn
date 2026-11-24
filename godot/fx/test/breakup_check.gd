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
	# Fable on 33561155: a late snap whose glued piece is the middle one (snaps toward the lone piece) keeps clear too
	await _breakup("high", "late", [-2.0, 3.0], -3.0, " (middle glued)")
	# WRECK5d: in a tight hex (a long hull) the end pieces' parting is shortened; they still never run together
	await _breakup("high", "three", [-4.0, 4.0], INF, " (tight hex)", 4.0)
	await _breakup("high", "late", [-4.0, 4.0], INF, " (tight hex)", 4.0)
	# Artoo on db791b40: a hull drifting out of its hex as it dies, its end piece already near the edge (ships in a
	# real fight move about a hex a turn, a few units a second)
	_hex_fit()
	await _breakup("high", "three", [-4.0, 4.0], INF, " (hex edge, drifting out)", 6.0, Vector3(3.0, 0.0, 0.6))
	await _breakup("high", "late", [-4.0, 4.0], INF, " (hex edge, drifting out)", 6.0, Vector3(3.0, 0.0, 0.6))
	await _warmed_late_hit()
	await _middle_glued()
	await _kinked_seam()
	await _one_crack_hulls()
	await _real_layouts()
	_pick()
	print("BREAKUP failures=%d" % failures)
	quit(1 if failures else 0)


func _ship(fx, world: Node3D, id: String, joints: Array, machines := []) -> Variant:
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
	for x in joints: seams.append(x if x is Dictionary else {"p": [x, 0.0, 0.0], "n": [1.0, 0.0, 0.0]})
	holder.set_meta("voidsworn_destruct", {"version": 1, "seams": seams, "interior_materials": [], "machines": machines})
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


# Artoo on 951623ce: the shared move into the hex fits whenever the rest spots can fit, even near a tangent (24 halving
# steps toward the farthest spot stopped at 1.016 of the reach here), and centres a wreck too long to fit
func _hex_fit() -> void:
	var cases := [
		[[Vector2(-0.99, 0.29), Vector2(0.0, 0.29), Vector2(0.99, 0.29)], 1.0, true],
		[[Vector2(0.2, 1.1), Vector2(0.9, 0.6), Vector2(-0.3, 0.4)], 1.0, true],
		[[Vector2(1.4, 0.0), Vector2(0.4, 0.3), Vector2(-0.5, -0.1)], 1.0, true],
		[[Vector2(-1.3, 0.1), Vector2(0.0, 0.5), Vector2(1.3, 0.1)], 1.0, false],
	]
	for c in cases:
		var spots: Array = c[0]
		var reach: float = c[1]
		var d: Vector2 = DEATH._hex_fit(spots, reach)
		var far: float = DEATH._farthest(spots, d)
		if c[2]:
			check(far <= reach + 0.001, "hex fit: spots that can fit end within reach (farthest %.4f of %.2f, moved %.3f)" % [far, reach, d.length()])
		else:
			var circ: Vector3 = DEATH._enclosing_circle(spots)
			check(absf(far - circ.z) < 0.001, "hex fit: a wreck too long to fit ends centred (farthest %.3f, circle %.3f)" % [far, circ.z])


func _breakup(quality: String, kind: String, joints := [-4.0, 4.0], hit_x := INF, tag_extra := "", hex_r := 0.0, vel := Vector3.ZERO) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world, quality)
	var s = _ship(fx, world, "k", joints)
	s.set_meta("breakup_force", kind)
	if hit_x != INF: s.set_meta("last_hit", [Vector3(hit_x, 1.5, 0.0), Vector3.DOWN, 0.0])
	var job: Dictionary = await _wait_cut(fx, s)
	var tag := "%s %s%s" % [quality, kind, tag_extra]
	check(int((job.get("plan", {}) as Dictionary).get("n_main", 0)) == 3, "%s: three main pieces cut" % tag)
	if hex_r > 0.0: fx.anchor_wreck("k", Vector3.ZERO, hex_r)
	if vel != Vector3.ZERO:
		# the dying hull's own speed (death_velocity reads the root's _vel)
		var gs := GDScript.new()
		gs.source_code = "extends Node3D\nvar _vel := Vector3.ZERO\n"
		gs.reload()
		s.root.set_script(gs)
		s.root.set("_vel", vel)
	fx.death("k", "blast")
	# Fable on 33561155: the tear draws its second line (open_b) only when that joint parts at the death
	var open_b := Vector2(-1.0, 1.0)
	for mm in s.meshes:
		if is_instance_valid(mm) and (mm as MeshInstance3D).material_overlay is ShaderMaterial:
			var ob = ((mm as MeshInstance3D).material_overlay as ShaderMaterial).get_shader_parameter("open_b")
			if ob is Vector2: open_b = ob
			break
	var two_lines: bool = open_b.x >= 0.0
	check(two_lines == (kind == "three") and s.has_meta("death_line_b") == (kind == "three"), "%s: the tear draws a second line only when both joints part (second line %s)" % [tag, two_lines])
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
	if hex_r > 0.0:
		# Artoo on db791b40: every middle rests within the reach of the hex it is anchored to, drift included
		# (a hull longer than the reach across can never fit: it ends centred, no farther out than its own ends)
		var bound: float = DEATH.BREAKUP_HEX_REACH if 2.0 * hex_r * DEATH.BREAKUP_HEX_REACH >= 20.0 else 10.0 / hex_r + 0.1
		var hex_far := 0.0
		for nd in nodes: hex_far = maxf(hex_far, Vector2((nd as Node3D).global_position.x, (nd as Node3D).global_position.z).length() / hex_r)
		check(hex_far <= bound + 0.02, "%s: every middle rests within %.2f rest radii of its hex (%.2f)" % [tag, bound, hex_far])
	world.queue_free()
	await process_frame


# Artoo on PR 1737: the live path reuses a cut warmed before the killing hit. Cut after a hit at -6 (first crack -4), then
# killed by a hit at +7: the +4 joint cracks first instead, and the -4 joint (the bite's) is the one that holds.
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
	# Fable on 33561155: a moved crack never rolls two (the bite is on the joint that holds), and a tidal kill parts
	# all three at once; over many hit spots near +7
	var rolled := {}
	var tidal_ok := true
	for k in 40:
		s.set_meta("last_hit", [Vector3(6.0 + 0.1 * k, 0.25 * (k % 7), 0.25 * (k % 5)), Vector3.DOWN, fx.now])
		s.remove_meta("death_crack")
		rolled[DEATH._pick_breakup(fx, s, "blast", job)] = true
		s.remove_meta("death_crack")
		tidal_ok = tidal_ok and DEATH._pick_breakup(fx, s, "tidal", job) == "three"
	s.remove_meta("death_crack")
	check(not rolled.has("two") and rolled.size() >= 1, "warmed: a moved crack breaks late or in three, never in two (%s)" % str(rolled.keys()))
	check(tidal_ok, "a tidal kill always breaks in three")
	s.set_meta("last_hit", [Vector3(7.0, 1.5, 0.0), Vector3.DOWN, fx.now])
	s.set_meta("breakup_force", "two")
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
	# the Board on e26dab6c: the late hit moves the first crack instead of forcing three, so two and late stay common
	var crack: int = int(s.get_meta("death_crack", -1))
	var crack_x: float = (plan["breaks"][crack]["at"] as Vector3).x if crack >= 0 and not plan.is_empty() else INF
	var held: int = int(s.get_meta("death_glued_break", -1))
	var held_x: float = (plan["breaks"][held]["at"] as Vector3).x if held >= 0 and not plan.is_empty() else INF
	check(absf(crack_x - 4.0) < 0.3, "warmed: killed by a hit at +7, the first crack moves to the +4 joint (%.2f)" % crack_x)
	check(str(s.get_meta("death_breakup", "")) == "two" and glued and n == 3 and absf(held_x + 4.0) < 0.3, "warmed: and a two breakup still happens, held at the -4 joint (%s, glued %s, %d pieces, held at %.2f)" % [str(s.get_meta("death_breakup", "")), glued, n, held_x])
	world.queue_free()
	await process_frame


# Artoo on fbceb98a: a joint that kinks round a machine is measured at the hit's own z, not at the centre line. Joint A
# is straight at -1; joint B runs at +4 for most of the beam, then kinks to +0.5 on the +z side. A side hit at x 1.2,
# z 2.0 is nearest B there (0.7) but nearest A at the centre line (2.2 against 2.8).
func _kinked_seam() -> void:
	var kink := {"p": [4.0, 0.0, 0.0], "n": [1.0, 0.0, 0.0], "path": [[4.0, -2.5], [4.0, 0.5], [0.5, 1.0], [0.5, 2.5]]}
	var side_hit := Vector3(1.2, 1.5, 2.0)
	for warmed in [false, true]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = _fx(world, "low")
		var s = _ship(fx, world, "k", [-1.0, kink])
		s.set_meta("last_hit", [Vector3(-3.0, 1.5, 0.0) if warmed else side_hit, Vector3.DOWN, 0.0])
		var job: Dictionary = await _wait_cut(fx, s)
		var plan: Dictionary = job.get("plan", {})
		if plan.is_empty() or (plan["breaks"] as Array).size() != 2:
			check(false, "kinked: the cut keeps both joints (%d)" % (0 if plan.is_empty() else (plan["breaks"] as Array).size()))
		elif not warmed:
			var bx: float = (plan["breaks"][int(plan["bite_break"])]["at"] as Vector3).x
			check(bx > 2.0, "kinked: a side hit by the kink cracks the kinked joint first (bite at %.2f)" % bx)
		else:
			s.set_meta("last_hit", [side_hit, Vector3.DOWN, fx.now])
			s.set_meta("breakup_force", "two")
			fx.death("k", "blast")
			var c: int = int(s.get_meta("death_crack", -1))
			var cx: float = (plan["breaks"][c]["at"] as Vector3).x if c >= 0 else INF
			check(cx > 2.0 and cx < 6.0, "kinked: a later side hit by the kink moves the first crack to the kinked joint (%.2f)" % cx)
		world.queue_free()
		await process_frame


# Audit on 8a2edbce: with joints at -2 and +3 and the first crack at -2, the glued piece is the middle one. Its torn face
# on the open crack heats with the rest, the snap's sparks come from the joint that held (+3), and the chips on that
# joint stay in place instead of flying.
func _middle_glued() -> void:
	for kind in ["two", "late"]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = _fx(world, "high")
		var s = _ship(fx, world, "m", [-2.0, 3.0])
		s.set_meta("last_hit", [Vector3(-3.0, 1.5, 0.0), Vector3.DOWN, 0.0])
		s.set_meta("breakup_force", kind)
		await _wait_cut(fx, s)
		fx.death("m", "blast")
		var w: Dictionary = {}
		var child: Node3D = null
		var snap_x := INF
		var held_chips := 0
		var held_peak := 0
		for i in 3 * 60:
			fx.step(1.0 / 60.0)
			await process_frame
			for ww in fx.dstate.get("wrecks", []):
				if ww["id"] == "m": w = ww
			if w.is_empty(): continue
			for nd in w["nodes"]:
				if is_instance_valid(nd) and nd.has_meta("glued"):
					child = nd
					snap_x = (nd.get_meta("piece_cen", Vector3.ZERO) as Vector3).x + (nd.get_meta("snap_site", Vector3.ZERO) as Vector3).x
			held_chips = 0
			for nd in w["nodes"]:
				if not is_instance_valid(nd): continue
				for c in nd.get_children():
					if c is Node3D and c.has_meta("chip_break"): held_chips += 1
			held_peak = maxi(held_peak, held_chips)
		var tag := "middle glued %s" % kind
		var mid_ok: bool = child != null and int(child.get_meta("piece_i", -1)) == 1
		check(mid_ok, "%s: the middle piece is the one glued" % tag)
		check(absf(snap_x - 3.0) < 0.6, "%s: its snap site is the joint that held, +3 (%.2f)" % [tag, snap_x])
		var warm := 0
		for m in w.get("mats", []):
			if (w["heat_births"] as Dictionary).has(m): warm += 1
		check(warm == (w.get("mats", []) as Array).size(), "%s: every torn face has heated (%d of %d)" % [tag, warm, (w.get("mats", []) as Array).size()])
		if kind == "two":
			check(held_chips > 0, "%s: the chips on the joint that held stay in place (%d)" % [tag, held_chips])
		else:
			# Neon's audit (PR 1902, item 12): they stay while the joint holds, then let go with the snap
			var loose := 0
			for nd in w.get("frags", []):
				if is_instance_valid(nd) and (nd as Node).has_meta("chip_break") and not (nd as Node).has_meta("glued") and (nd as Node).get_parent() == fx.phys_root: loose += 1
			check(held_peak > 0 and held_chips == 0 and loose >= held_peak, "%s: the chips on the joint stay until the snap, then let go with it (held %d, still held %d, loose %d)" % [tag, held_peak, held_chips, loose])
		world.queue_free()
		await process_frame


# Audit B1: a small hull and a Chorus hull with two authored joints still break once (their own pop and rupture)
func _one_crack_hulls() -> void:
	for spec in [["Frigate", "corsair"], ["Destroyer", "hegemony"], ["Cruiser", "chorus"]]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = _fx(world, "low")
		var holder := Node3D.new()
		world.add_child(holder)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(20, 3, 5)
		mi.mesh = box
		holder.add_child(mi)
		holder.set_meta("voidsworn_destruct", {"version": 1, "seams": [{"p": [-4.0, 0.0, 0.0], "n": [1.0, 0.0, 0.0]}, {"p": [4.0, 0.0, 0.0], "n": [1.0, 0.0, 0.0]}], "interior_materials": [], "machines": []})
		fx.add_ship("o", holder, {"faction": spec[1], "cls": spec[0], "size": 1.0})
		var r := RandomNumberGenerator.new()
		r.seed = 5
		var plan: Dictionary = DEATH.fracture_plan(fx, fx.ship("o"), r)
		check(int(plan.get("n_main", 0)) == 2, "%s %s: one crack, two pieces (%d)" % [spec[1], spec[0], int(plan.get("n_main", 0))])
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


# WRECK5c (Nov 24): on the real hulls most deaths kept two pieces, because their joints sit near an end or there are
# none (SEAMS1 read them on the PC). The joint layouts of H4_11, V16_37 and H9_23 (no joints) on the 20-long box, as
# fractions of the length, each hit at the stern, amidships and the bow: three pieces every time, none under 0.15 L,
# the first crack the chosen joint nearest the hit; on V16_37 a machine across 0.28 to 0.36 keeps the added joint off it.
func _real_layouts() -> void:
	var cases := [["H4_11", [0.132, 0.292, 0.535, 0.824], []], ["V16_37", [0.081, 0.703], []],
		["V16_37 machine", [0.081, 0.703], [{"name": "m", "kind": "gun", "lo": [-4.4, -1.0, -1.0], "hi": [-2.8, 1.0, 1.0]}]],
		["H9_23", [], []]]
	for c in cases:
		for hf in [0.2, 0.5, 0.8]:
			var world := Node3D.new()
			root.add_child(world)
			var fx = _fx(world, "low")
			var joints: Array = (c[1] as Array).map(func(f): return -10.0 + 20.0 * float(f))
			var s = _ship(fx, world, "r", joints, c[2])
			var hx: float = -10.0 + 20.0 * float(hf)
			s.set_meta("last_hit", [Vector3(hx, 1.5, 0.0), Vector3.DOWN, 0.0])
			var job: Dictionary = await _wait_cut(fx, s)
			var plan: Dictionary = job.get("plan", {})
			var tag := "%s hit at %.1f" % [c[0], hf]
			if plan.is_empty():
				check(false, "%s: a cut" % tag)
			else:
				var brs: Array = plan["breaks"]
				var xs: Array = brs.map(func(b): return float((b["at"] as Vector3).x))
				var sizes: Array = plan["sizes"]
				var smallest: float = (sizes as Array).reduce(func(a, b): return minf(a, b), 1.0)
				var first: float = xs[int(plan["bite_break"])] if not xs.is_empty() else INF
				var other: float = xs[1 - int(plan["bite_break"])] if xs.size() == 2 else INF
				var off_machine := true
				for m in c[2]:
					for x in xs:
						if x > float(m["lo"][0]) - 0.2 and x < float(m["hi"][0]) + 0.2: off_machine = false
				check(int(plan["n_main"]) == 3 and bool(plan.get("breakup", false)) and smallest >= 0.15 - 1e-3 and absf(first - hx) <= absf(other - hx) + 1e-3 and off_machine,
					"%s: three pieces, none under 0.15 L, first crack the nearer joint, off any machine (joints %s, smallest %.2f)" % [tag, str(xs.map(func(x): return snappedf((x + 10.0) / 20.0, 0.01))), smallest])
			world.queue_free()
			await process_frame
