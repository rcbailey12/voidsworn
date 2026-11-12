extends SceneTree
# Issue 557: the written GLB drives the same reader used by damage and death.
const HULL = preload("res://fx/fx_hull.gd")
const DEATH = preload("res://fx/fx_death.gd")
const BREACH = preload("res://fx/fx_breach.gd")
const FX = preload("res://fx/fx.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ship: Node3D
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "--legacy-cache":
		var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json"))
		var count := 0
		for code in manifest.get("ships", {}):
			var old_ship: Node3D = load(manifest.ships[code].res).instantiate()
			world.add_child(old_ship)
			var h := HULL.new()
			h._authored(old_ship)
			check(not h.authored and h.seams.is_empty(), "legacy asset must keep #167: " + code)
			var meshes: Array = old_ship.find_children("*", "MeshInstance3D", true, false)
			var native := PackedVector3Array()
			for mi in meshes: native.append_array((old_ship.global_transform.affine_inverse() * mi.global_transform) * mi.mesh.get_faces())
			check(native == HULL.faces_of(old_ship, meshes), "legacy outside BVH triangles unchanged: " + code)
			old_ship.free()
			count += 1
		check(count >= 33, "legacy PC cache coverage must not silently skip missing assets")
		world.queue_free()
		print("LEGACY_CACHE ships=%d failures=%d" % [count, failures])
		quit(1 if failures else 0)
		return
	if not args.is_empty():
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		check(doc.append_from_file(args[0], state) == OK, "written GLB loads")
		ship = doc.generate_scene(state)
	else:
		ship = Node3D.new()
		var mi := MeshInstance3D.new()
		var mesh := ArrayMesh.new()
		var box := BoxMesh.new()
		box.size = Vector3(30, 6, 10)
		box.subdivide_width = 39; box.subdivide_depth = 13; box.subdivide_height = 9
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
		var deck := BoxMesh.new()
		deck.size = Vector3(28, 0.3, 8)
		deck.subdivide_width = 39
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, deck.get_mesh_arrays())
		var interior := StandardMaterial3D.new()
		interior.resource_name = "fixture_inside_0"
		mesh.surface_set_material(1, interior)
		mi.mesh = mesh
		ship.add_child(mi)
		ship.set_meta("voidsworn_destruct", {"version": 1, "interior_materials": ["fixture_inside_0"],
			"seams": [{"p": [-7, 0, 0], "n": [1, 0, 0]}, {"p": [5, 0, 0], "n": [1, 0, 0]},
				{"p": [0, 0, 0], "n": [0, 1, 0], "span": [-7, 5]}]})
	world.add_child(ship)
	ship.scale = Vector3.ONE * (1.7 if args.is_empty() else 40.0)
	ship.position = Vector3(2, 3, 4)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	fx.add_ship("authored", ship, {"faction": "corsair", "cls": "Cruiser", "size": 0.8})
	var s = fx.ship("authored")
	check(s.hull.authored, "GLB extras reached hull reader")
	check(s.hull.seams.size() == 3, "both transverse seams and bounded longitudinal seam survived")
	var rng := RandomNumberGenerator.new()
	rng.seed = 190
	var plan: Dictionary = DEATH.fracture_plan(fx, s, rng)
	check(plan.n_main == 4, "piece count follows authored structure, not the legacy cruiser count")
	check(plan.n_frag > 0 and not plan.bite.is_empty(), "authored seams retain missing bite and fragments")
	var point: Vector3 = plan.breaks[0].at
	# issue 592 (R225: a check reads the ship's own numbers): move the first seam by 0.14 of the length, or by half the gap to
	# the next seam when they are closer (A16's castle seams are 0.08 apart), so it stays the first seam
	var shift: float = s.hull.L * 0.14
	if plan.breaks.size() > 1:
		shift = minf(shift, 0.5 * (float(plan.breaks[1].at.x) - point.x))
	var before: int = DEATH._plan_main(plan, point + Vector3.RIGHT * shift * 0.36)
	var seam0: Vector3 = s.hull.seams[0].at
	var path0 = s.hull.seams[0].get("path")
	s.hull.seams[0].at += Vector3.RIGHT * shift
	if path0 != null:
		# issue 600: a seam with a plan path moves with its path (the cut follows the path)
		var moved_path := PackedVector2Array()
		for q in (path0 as PackedVector2Array): moved_path.append(q + Vector2(shift, 0.0))
		s.hull.seams[0].path = moved_path
	rng.seed = 190
	var moved: Dictionary = DEATH.fracture_plan(fx, s, rng)
	check(absf(moved.breaks[0].at.x - point.x - shift) < 0.0001, "moving authored seam moves fracture anchor")
	check(DEATH._plan_main(moved, point + Vector3.RIGHT * shift * 0.36) != before, "moving seam changes actual piece ownership")
	s.hull.seams[0].at = seam0
	if path0 != null: s.hull.seams[0].path = path0
	var moving_mesh: MeshInstance3D = s.meshes[0]
	var analysis_pose: Transform3D = ship.global_transform.affine_inverse() * moving_mesh.global_transform
	moving_mesh.position.y += 0.4
	DEATH.precompute(fx, s)
	if s.has_meta("cut_task"):
		while not WorkerThreadPool.is_task_completed(s.get_meta("cut_task")): await process_frame
		DEATH._prebuild(fx, s)
	var job: Dictionary = s.get_meta("cut_job")
	check(job.surfs[0].xf.is_equal_approx(analysis_pose), "authored seams stay aligned when ShipView bobs the mesh")
	var interior_triangles := 0
	var original_area := 0.0
	var piece_area := 0.0
	for sd in job.surfs:
		if sd.interior: original_area += _area(sd.arrays[Mesh.ARRAY_VERTEX], sd.arrays[Mesh.ARRAY_INDEX], sd.xf)
	for pc in job.out:
		check(pc.authored, "authored cut bypasses full fallback caps")
		for sd in pc.surfs:
			if sd.interior:
				interior_triangles += sd.arrays[Mesh.ARRAY_INDEX].size() / 3
				piece_area += _area(sd.arrays[Mesh.ARRAY_VERTEX], sd.arrays[Mesh.ARRAY_INDEX], Transform3D.IDENTITY)
				check(HULL.interior_material(sd.mat), "cut retains authored material")
	check(interior_triangles > 0, "cut contains real interior triangles")
	# issue 600: the insides tear with the hull (split along the tear, the strip it runs through blown away), so the pieces
	# keep almost all of the authored inside area rather than every original triangle
	check(piece_area >= original_area * 0.9 and piece_area <= original_area * 1.0001,
		"the wreck pieces keep the authored insides (%.1f percent of their area)" % (100.0 * piece_area / maxf(original_area, 1e-9)))
	var outline := PackedVector3Array([Vector3(0, -2, -3), Vector3(0, 2, -3), Vector3(0, 2, 3), Vector3(0, -2, 3)])
	var cap := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()}
	DEATH._cap_outline(cap, outline, AABB(Vector3(-5, -2, -3), Vector3(5, 4, 6)), 0.000001,
		{"authored": true, "cap_loops": 0, "cap_fallbacks": 0})
	var largest := 0.0
	for i in range(0, cap.v.size(), 3): largest = maxf(largest, (cap.v[i + 1] - cap.v[i]).cross(cap.v[i + 2] - cap.v[i]).length() * 0.5)
	check(largest < 1.0, "authored rooms have narrow torn rims, no solid fallback face blocking them")
	var originals: Array = BREACH.gather(s)
	check(originals.any(func(sd): return sd.interior), "breach reader recognises authored rooms")
	var wound = BREACH.hole(null, s.hull.c + Vector3.UP * s.hull.H * 0.5, Vector3.UP, s.hull.L * 0.08, 0.8, 0.1, 73.0)
	var damage := BREACH.compute({"surfs": originals, "ents": [wound], "q": 0.001, "hull": s.hull, "mesh_on_worker": false})
	for i in originals.size():
		if originals[i].interior: check(damage.surfs[i] == null, "wound preserves authored decks and machinery")
	# No extras is the old #167 path, including the same sealed backing.
	var legacy := HULL.new()
	ship.remove_meta("voidsworn_destruct")
	legacy.analyse(ship, s.meshes, 33)
	if args.is_empty(): check(not legacy.authored and legacy.seams.is_empty(), "legacy hull stays on fallback")
	fx.remove_ship("authored")
	world.queue_free()
	print("AUTHORED_INTERIORS failures=%d interior_triangles=%d" % [failures, interior_triangles])
	quit(1 if failures else 0)


static func _area(v: PackedVector3Array, idx: PackedInt32Array, xf: Transform3D) -> float:
	var a := 0.0
	for t in range(0, idx.size() - 2, 3):
		a += (xf * v[idx[t + 1]] - xf * v[idx[t]]).cross(xf * v[idx[t + 2]] - xf * v[idx[t]]).length() * 0.5
	return a
