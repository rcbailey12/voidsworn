extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1385 (Neon's death review, PR 1383): four things the A16 checks could not see, on box hulls that carry an authored
# break contract (voidsworn_destruct seams, as a recipe export does):
#   F2, F3: an authored small hull (its pop) and an authored Chorus hull (its rupture) never throw the bite and the chips,
#     so the fracture plan carves none: every triangle of the hull stays on a main piece (before: a hole in the wreck).
#     A big metal hull keeps its bite (the control).
#   F5: a lance kill on an authored hull breaks on the authored joint nearest the beam (not the joint nearest the core),
#     the pieces keep the joints' sizes (before: the lance's 0.3 to 0.7 split, under the seam's own break) and the tear
#     there has the lance's fine teeth.
#   F4: a strained wreck piece that leaves Jolt after WRECK_PHYS_S keeps its story damping on the effect clock (before: it
#     drifted and turned forever).
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "death_authored_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _run() -> void:
	await _no_lost_triangles("Frigate", "deathless", false)
	await _no_lost_triangles("Cruiser", "chorus", false)
	await _no_lost_triangles("Cruiser", "corsair", true)
	_tapered_section_kit()
	await _lance_joint()
	await _leave_physics_damp()
	print("DEATH_AUTHORED failures=%d" % failures)
	quit(1 if failures else 0)


# A 20-long box with authored crosswise joints at the given x (ship frame), as an export carries them.
func _ship(fx, world: Node3D, id: String, cls: String, fac: String, joints: Array) -> Variant:
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 3, 5)
	box.subdivide_width = 39
	box.subdivide_height = 3
	box.subdivide_depth = 7
	mi.mesh = box
	holder.add_child(mi)
	var seams: Array = []
	for x in joints: seams.append({"p": [x, 0.0, 0.0], "n": [1.0, 0.0, 0.0]})
	holder.set_meta("voidsworn_destruct", {"version": 1, "seams": seams, "interior_materials": [], "machines": []})
	fx.add_ship(id, holder, {"faction": fac, "cls": cls, "size": 1.0})
	return fx.ship(id)


func _fx(world: Node3D):
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	return fx


func _wait_cut(fx, s) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	return s.get_meta("cut_job", {})


func _tris(pc: Dictionary) -> int:
	var n := 0
	for sd in pc["surfs"]:
		n += (sd["arrays"][Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return n


func _no_lost_triangles(cls: String, fac: String, throws: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world)
	var s = _ship(fx, world, "a", cls, fac, [1.5])
	var tag := "%s %s" % [fac, cls]
	check(s.hull.authored, "%s: the box carries an authored joint" % tag)
	DEATH.precompute(fx, s, "blast")
	var job: Dictionary = await _wait_cut(fx, s)
	check(job.get("built", false), "%s: the cut finished" % tag)
	var plan: Dictionary = job.get("plan", {})
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	# Artoo on PR 1388: an empty plan would make every piece "main" and pass the count below, so the plan must be the
	# authored one, broken on the joint, and each half must hold its own side of the hull
	# issue 1236 round 4 (WRECK5c): a big metal hull breaks on two joints, adding a plain one where its authored joints
	# cannot leave three pieces of 0.15 L; a hull that never throws keeps its one authored break
	var want_breaks := 2 if throws else 1
	check(bool(plan.get("authored", false)) and (plan.get("breaks", []) as Array).size() == want_breaks, "%s: the cut used the authored plan with %d break(s)" % [tag, want_breaks])
	var brs: Array = plan.get("breaks", [])
	var xs: Array = brs.map(func(b): return float((b["at"] as Vector3).x))
	check(xs.any(func(x): return absf(x - 1.5) < 0.05), "%s: a break sits on the authored joint at x 1.5 (%s)" % [tag, str(xs)])
	var n_main: int = int(plan.get("n_main", -1))
	check(n_main == want_breaks + 1 and pieces.size() >= n_main, "%s: %d main pieces (n_main %d, pieces %d)" % [tag, want_breaks + 1, n_main, pieces.size()])
	xs.sort()
	for i in mini(maxi(n_main, 0), pieces.size()):
		var lo := INF
		var hi := -INF
		for sd in pieces[i]["surfs"]:
			for v in (sd["arrays"][Mesh.ARRAY_VERTEX] as PackedVector3Array):
				lo = minf(lo, v.x)
				hi = maxf(hi, v.x)
		var a: float = xs[i - 1] if i > 0 and i - 1 < xs.size() else -INF
		var b: float = xs[i] if i < xs.size() else INF
		# an added joint is turned up to 12 degrees across the 5-wide beam and torn, so it reaches a little further
		var ta: float = 1.0 if absf(a - 1.5) < 0.05 else 1.5
		var tb: float = 1.0 if absf(b - 1.5) < 0.05 else 1.5
		var ok: bool = _tris(pieces[i]) > 0 and hi <= b + tb and lo >= a - ta
		check(ok, "%s: main piece %d holds its own stretch of the hull (x %.2f to %.2f)" % [tag, i, lo, hi])
		var roles := _cap_roles(pieces[i])
		check(roles.has(DEATH.CAP_WALL.r), "%s: piece %d has a recessed backing despite being authored" % [tag, i])
		if fac != "chorus":
			check(roles.has(DEATH.CAP_DECK.r) and roles.has(DEATH.CAP_RIB.r),
				"%s: piece %d carries decks and ribs in the break" % [tag, i])
	if n_main < 0: n_main = pieces.size()
	var on_main := 0
	var on_frags := 0
	for i in pieces.size():
		if i < n_main: on_main += _tris(pieces[i])
		else: on_frags += _tris(pieces[i])
	print("DEATH_AUTHORED %s death_big=%s pieces=%d n_main=%d tris_main=%d tris_frags=%d" % [tag, s.death_big, pieces.size(), n_main, on_main, on_frags])
	if throws:
		check(on_frags > 0 and not (plan["bite"] as Dictionary).is_empty(), "%s: a big metal hull still carves its bite and chips (%d triangles)" % [tag, on_frags])
	else:
		check(on_main > 0 and on_frags == 0, "%s: no triangles on fragments it never throws (%d lost)" % [tag, on_frags])
	world.queue_free()
	await process_frame


func _cap_roles(piece: Dictionary) -> Dictionary:
	var colors := {}
	if not piece.has("cap"): return colors
	for c: Color in piece["cap"][Mesh.ARRAY_COLOR]:
		colors[c.r] = true
	return colors


# A sharply tapering closed end with its other end torn off. The original skin, not a hull-wide bounding box,
# decides how deep the bulkhead and the deck and rib profiles can sit.
func _tapered_section_kit() -> void:
	var v := PackedVector3Array([Vector3(0, -2, -3), Vector3(0, 2, -3), Vector3(0, 2, 3), Vector3(0, -2, 3),
		Vector3(1.5, -0.2, -0.3), Vector3(1.5, 0.2, -0.3), Vector3(1.5, 0.2, 0.3), Vector3(1.5, -0.2, 0.3)])
	var ids := PackedInt32Array([4, 5, 6, 4, 6, 7])
	for i in 4:
		var j := (i + 1) % 4
		ids.append_array(PackedInt32Array([i, j, j + 4, i, j + 4, i + 4]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_INDEX] = ids
	var surf := {"arrays": arr, "skin": true}
	for kind in [DEATH.CAP_METAL, DEATH.CAP_GLASS, DEATH.CAP_FLESH]:
		var pc := {"surfs": [surf], "authored": true, "ragged": true, "cap_kind": kind}
		DEATH._seal_piece(pc)
		var roles := _cap_roles(pc)
		var tag := ["metal", "glass", "flesh"][kind] as String
		check(roles.has(DEATH.CAP_WALL.r), tag + ": a tapered tear has a backing")
		var metal: bool = kind == DEATH.CAP_METAL
		check(roles.has(DEATH.CAP_DECK.r) == metal and roles.has(DEATH.CAP_RIB.r) == metal,
			tag + ": only metal gets the deck and frame profiles")
		if not pc.has("cap"): continue
		var verts: PackedVector3Array = pc["cap"][Mesh.ARRAY_VERTEX]
		var cols: PackedColorArray = pc["cap"][Mesh.ARRAY_COLOR]
		var leaks := 0
		var gradients := 0
		var glowing_structures := 0
		for i in verts.size():
			var p := verts[i]
			if cols[i].r >= DEATH.CAP_RIB.r:
				var taper := lerpf(1.0, 0.1, p.x / 1.5)
				if p.x <= 0.0 or p.x >= 1.5 or absf(p.y) > 2.0 * taper or absf(p.z) > 3.0 * taper: leaks += 1
				if cols[i].g > 0.78: glowing_structures += 1
			if i % 3 == 0 and cols[i].g == DEATH.CAP_LIP.g and cols[i + 2].g == DEATH.CAP_LIP_INSET.g:
				gradients += 1
		check(leaks == 0, "%s: no interior vertices protrude through tapered skin (%d outside)" % [tag, leaks])
		check((gradients > 0) == (kind != DEATH.CAP_FLESH) and glowing_structures == 0, tag + ": light is graded across the lip only")

	var old_opening := {"surfs": [surf], "authored": true, "ragged": true,
		"plan": {"L": 1.5, "breaks": [], "bite": {}}}
	DEATH._seal_piece(old_opening)
	var old_lip: PackedColorArray = old_opening["cap"][Mesh.ARRAY_COLOR]
	check(not old_lip.is_empty() and old_lip.count(DEATH.CAP_LIP_INSET) == old_lip.size(),
		"an existing kit opening is neither filled nor heated")


func _lance_joint() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world)
	check(fx.death_story, "the strained death is on by default")
	# joints at -5 and +6; the core sits near the middle, so the core's joint is -5 and the beam's joint (hit at +7) is +6
	var s = _ship(fx, world, "l", "Cruiser", "corsair", [-5.0, 6.0])
	s.hull.core = Vector3(-2.0, 0.0, 0.0)
	s.set_meta("lance_line", [Vector3(7.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0)])
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var plan: Dictionary = DEATH.fracture_plan(fx, s, r)
	var brs: Array = plan["breaks"]
	var sizes: Array = plan["sizes"]
	var x0: float = s.hull.box.position.x
	var L: float = s.hull.L
	var bx: float = (brs[0]["at"] as Vector3).x if not brs.is_empty() else INF
	print("DEATH_AUTHORED lance breaks=%d break_x=%.2f sizes=%s" % [brs.size(), bx, str(sizes)])
	check(brs.size() == 1 and absf(bx - 6.0) < 0.3, "lance: the strained hull breaks on the joint nearest the beam, +6 (at %.2f)" % bx)
	check(sizes.size() == 2 and absf(x0 + float(sizes[0]) * L - bx) < 0.3, "lance: the pieces end at that joint (first piece to %.2f)" % (x0 + float(sizes[0]) * L))
	var amp := INF
	if not brs.is_empty() and not (brs[0]["waves"] as Array).is_empty(): amp = float(brs[0]["waves"][0][2])
	check(amp <= L * 0.005, "lance: the tear on that joint has the lance's fine teeth (%.3f of the length)" % (amp / L))
	world.queue_free()
	await process_frame


func _leave_physics_damp() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = _fx(world)
	var rb := RigidBody3D.new()
	world.add_child(rb)
	rb.linear_damp = 0.0
	rb.angular_damp = 0.0
	rb.set_meta("story_damp", DEATH.STORY_DAMP)
	rb.linear_velocity = Vector3(2.0, 0.0, 0.0)
	rb.angular_velocity = Vector3(0.0, 1.0, 0.0)
	var wreck := {"fires": []}
	DEATH._wreck_leave_physics(fx, wreck, rb)
	var e: Dictionary = wreck["fires"][0] if not (wreck["fires"] as Array).is_empty() else {}
	check(float(e.get("damp", 0.0)) == DEATH.STORY_DAMP and float(e.get("adamp", 0.0)) == DEATH.STORY_DAMP * 0.5,
		"a strained piece leaving Jolt keeps its story damping (damp %s, adamp %s)" % [str(e.get("damp")), str(e.get("adamp"))])
	world.queue_free()
	await process_frame
