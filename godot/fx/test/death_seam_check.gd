extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 600 (RULEBOOK 5.17, R226; RULEBOOK 6.5, R186 "blown apart, never sliced"): kill A16 (C19_51) and count two things.
# Both must be zero:
#   machines split: a gun, turret, casemate, launcher, engine, thruster, claw or sensor mast whose triangles land on more
#     than one piece (each machine's box comes from the export, voidsworn_destruct.machines; a turret's turning mesh
#     counts with the machine round its pivot);
#   insides outside: an inside triangle (deck, bulkhead, room, liner) on a main piece with a corner outside that piece's
#     own hull plating (and the bite and chips torn from it), so no slab sticks out past the broken hull. A corner is inside
#     when rays up and down, or to port and starboard, meet the plating, or the plating is within TOL_FRAC of it; an inside
#     corner already outside the whole ship's plating before the break (by more than 0.003 of the length) is a build sheet
#     matter: it is skipped, and its triangles are counted apart.
# It also prints the cut's worker time and the main-thread time to build the pieces (R118), and (issue 616) the kill
# frame's time in fx.death and each later frame's share of the power-down it hands on; the power-down must finish within
# 30 frames with every hull surface given its material. The times are printed, not checked: CI machines vary.
# The ship: the GLB path after "--", else the installed res://assets/ships/C19_51/C19_51.glb, else the unpainted export
# kept as a fixture (fx/test/fixtures/C19_51_unbaked.glb.gz: tools/recipe/export7.py unbaked=1 on the A16 build, gzipped;
# regenerate it when A16's sheet changes, by the steps in tools/recipe/sheet_fixture_hash.py). Staleness guard (opus_check_608
# note 3, issue 532): the fixture's record C19_51_unbaked.sheet.txt holds the sha256 of the files that make A16's geometry and
# their list; when the check runs on the fixture it hashes the same files and fails when they differ.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
const FIXTURE_RECORD := "res://fx/test/fixtures/C19_51_unbaked.sheet.txt"
const INSTALLED := "res://assets/ships/C19_51/C19_51.glb"
const TOL_FRAC := 0.012   # of the length: one split step of the cut (fx_death.gd REFINE_EPS); a torn inside edge beside its plating
var failures := 0


func _init() -> void:
	GUARD.arm(self, "death_seam_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)


# The hull plating (the <code>_hull surface) of one main piece and of the fragments; of all the pieces for pi = -1.
func _skin_faces(pieces: Array, pi: int, n_main: int) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for pj in pieces.size():
		if pi >= 0 and pj != pi and pj < n_main: continue
		for sd in pieces[pj]["surfs"]:
			if not bool(sd.get("skin", false)): continue
			var v: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
			for i in sd["arrays"][Mesh.ARRAY_INDEX]: faces.append(v[i])
	return faces


# A point is inside a skin when rays both up and down, or both to port and starboard, meet it, or when the skin is within
# tol of it along an axis (a torn inside edge beside the torn plating); the point may also move by tol along any axis first
# (a torn inside edge may stand a tooth proud of the torn plating). tol 0 is the plain test.
func _enclosed(tm: TriangleMesh, c: Vector3, tol: float) -> bool:
	if tol > 0.0:
		for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
			var hit: Dictionary = tm.intersect_ray(c, d)
			if not hit.is_empty() and (hit["position"] as Vector3).distance_to(c) <= tol: return true
	for off in [Vector3.ZERO, Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
		var q: Vector3 = c + off * tol
		if not tm.intersect_ray(q, Vector3.UP).is_empty() and not tm.intersect_ray(q, Vector3.DOWN).is_empty(): return true
		if not tm.intersect_ray(q, Vector3.FORWARD).is_empty() and not tm.intersect_ray(q, Vector3.BACK).is_empty(): return true
	return false


# The fixture was exported from the A16 sheet as it stood: hash the files its record lists (repository paths, line endings
# as LF) and compare with the recorded sha256 (tools/recipe/sheet_fixture_hash.py writes both).
func _fixture_fresh() -> void:
	var rec := FileAccess.get_file_as_string(FIXTURE_RECORD).split("\n", false)
	check(rec.size() > 1 and rec[0].begins_with("sha256 "), "the fixture record %s is missing or unreadable" % FIXTURE_RECORD)
	if rec.size() < 2: return
	var repo := ProjectSettings.globalize_path("res://").path_join("..")
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	for i in range(1, rec.size()):
		var f := repo.path_join(rec[i].strip_edges())
		check(FileAccess.file_exists(f), "the fixture record names a file that is not there: " + rec[i])
		ctx.update(FileAccess.get_file_as_string(f).replace("\r\n", "\n").to_utf8_buffer())
	var got := ctx.finish().hex_encode()
	var want := rec[0].substr(7).strip_edges()
	print("DEATH_SEAM fixture record ", "fresh" if got == want else "STALE")
	check(got == want, "the C19_51 fixture is stale: A16's sheet files changed since it was exported (regenerate it by the steps in tools/recipe/sheet_fixture_hash.py)")


func _load_ship() -> Node3D:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else (INSTALLED if FileAccess.file_exists(INSTALLED) else FIXTURE)
	if path == FIXTURE: _fixture_fresh()
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"): bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if bytes.is_empty() or doc.append_from_buffer(bytes, path.get_base_dir(), state) != OK: return null
	print("DEATH_SEAM ship ", path)
	return doc.generate_scene(state)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ship := _load_ship()
	check(ship != null, "A16 loads")
	if ship == null:
		quit(1)
		return
	# the class length the export wrote (length_world), as the game draws it
	var length := 26.0
	for nd in [ship] + ship.find_children("*", "Node3D", true, false):
		var ex = nd.get_meta("extras", {})
		if ex is Dictionary and ex.has("length_world"): length = float(ex["length_world"])
	world.add_child(ship)
	var box := AABB()
	var first := true
	for mi in ship.find_children("*", "MeshInstance3D", true, false):
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	ship.scale = Vector3.ONE * (length / maxf(box.size.x, 0.0001))
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s = fx.ship("a16")
	check(s.hull.authored, "A16's seams reach the hull reader")
	check(not s.hull.machines.is_empty(), "A16's export names its machines (voidsworn_destruct.machines)")
	# the staggered cut finishes before the death, as in a battle; then the kill and the break
	var t_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_wait < 120000:
		fx.step(1.0 / 60.0)
		await process_frame
		var j: Dictionary = s.get_meta("cut_job", {})
		if j.get("built", false): break
	var job: Dictionary = s.get_meta("cut_job", {})
	check(job.get("built", false), "the cut finished and its pieces were built")
	var prof: Dictionary = fx.prof_take()
	# Issue 616 (R118): the kill frame's main-thread time in fx.death (wall clock round the call, so a profile key booked
	# twice cannot skew it), then each following frame's share of the death's spread work (prof "power_down").
	var t_kill := Time.get_ticks_usec()
	fx.death("a16", "big")
	var kill_ms := float(Time.get_ticks_usec() - t_kill) / 1000.0
	var spread: Array = []
	var done_at := 0 if not s.has_meta("death_power_queue") else -1
	var prof2: Dictionary = fx.prof_take()
	for i in 240:
		fx.step(1.0 / 60.0)
		var pf: Dictionary = fx.prof_take()
		for k in pf: prof2[k] = int(prof2.get(k, 0)) + int(pf[k])
		if i < 12: spread.append(float(pf.get("power_down", 0)) / 1000.0)
		if done_at < 0 and not s.has_meta("death_power_queue"): done_at = i + 1
		await process_frame
	# every hull surface was handed its power-down material (the live ones dark, the authored insides a dark copy)
	var n_surf := 0
	var n_set := 0
	for mm in s.meshes:
		var mi := mm as MeshInstance3D
		if not is_instance_valid(mi) or mi.mesh == null: continue
		for si in mi.mesh.get_surface_count():
			n_surf += 1
			if mi.get_surface_override_material(si) != null: n_set += 1
	print("DEATH_SEAM kill_frame death_ms=%.1f power_down_frames_after=%d power_down_ms_per_frame=%s surfaces=%d powered=%d" % [kill_ms, done_at, str(spread.map(func(x: float) -> String: return "%.1f" % x)), n_surf, n_set])
	check(done_at >= 0 and done_at <= 30, "the power-down finished within 30 frames of the kill (took %d)" % done_at)
	check(n_set == n_surf, "every hull surface has its power-down material: %d of %d" % [n_set, n_surf])
	check(s.has_meta("death_hidden"), "A16 broke up")
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	var plan: Dictionary = job.get("plan", {})
	var n_main: int = int(plan.get("n_main", pieces.size()))
	var L: float = s.hull.L
	# 1. machines split across pieces
	var boxes: Array = []
	for m in s.hull.machines: boxes.append((m["box"] as AABB).grow(L * 0.001))
	var sets: Array = []
	for m in boxes: sets.append({})
	var tur_sets := {}
	for pi in pieces.size():
		for sd in pieces[pi]["surfs"]:
			# the plating and the insides may tear (RULEBOOK 5.17); machines are on the parts surfaces and turret nodes
			if bool(sd.get("interior", false)) or bool(sd.get("skin", false)): continue
			var tk := int(sd.get("tur", -1))
			if tk >= 0:
				tur_sets[tk] = tur_sets.get(tk, {})
				tur_sets[tk][pi] = true
				continue
			var v: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
			for t in range(0, idx.size() - 2, 3):
				var a := v[idx[t]]
				var b := v[idx[t + 1]]
				var c := v[idx[t + 2]]
				var cen := (a + b + c) / 3.0
				var best := -1
				var bd := INF
				for k in boxes.size():
					var bb: AABB = boxes[k]
					if not (bb.has_point(a) and bb.has_point(b) and bb.has_point(c)): continue
					var d := (cen - bb.get_center()).abs() / (bb.size * 0.5).max(Vector3.ONE * 1e-6)
					var dn := maxf(d.x, maxf(d.y, d.z))
					if dn < bd:
						bd = dn
						best = k
				if best >= 0: sets[best][pi] = true
	for tk in tur_sets:
		var pivot: Vector3 = (s.hull.turrets[tk]["xf"] as Transform3D).origin
		var home := -1
		for k in boxes.size():
			if (boxes[k] as AABB).has_point(pivot): home = k
		if home >= 0: sets[home].merge(tur_sets[tk])
		elif tur_sets[tk].size() > 1: sets.append(tur_sets[tk])
	var split := 0
	var names: Array = []
	for k in sets.size():
		if sets[k].size() > 1:
			split += 1
			names.append(s.hull.machines[k]["name"] if k < s.hull.machines.size() else "turret")
	# 2. inside triangles outside their own piece's hull. A piece's hull is its own outer skin plus the bite and chips torn
	# off the breaks (thrown debris: a deck under the hole a chip left is open to view, not sticking out past the break).
	# Insides already outside the whole ship before it breaks are a build sheet matter, counted apart, not a death fault.
	var tol := L * TOL_FRAC
	var whole := TriangleMesh.new()
	whole.create_from_faces(_skin_faces(pieces, -1, n_main))
	var inside_total := 0
	var outside := 0
	var outside_whole := 0
	var frag_inside := 0
	for pi in pieces.size():
		var pc: Dictionary = pieces[pi]
		if pi >= n_main:
			for sd in pc["surfs"]:
				if bool(sd.get("interior", false)): frag_inside += (sd["arrays"][Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			continue
		var faces := _skin_faces(pieces, pi, n_main)
		var tm := TriangleMesh.new()
		if faces.size() >= 3: tm.create_from_faces(faces)
		for sd in pc["surfs"]:
			if not bool(sd.get("interior", false)): continue
			var v: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
			for t in range(0, idx.size() - 2, 3):
				inside_total += 1
				# every corner: a slab that goes whole to the piece its middle lies in sticks out by its far corners
				var bad := false
				var sheet := false
				for q in [v[idx[t]], v[idx[t + 1]], v[idx[t + 2]]]:
					if not _enclosed(whole, q, L * 0.003):
						sheet = true
					elif faces.size() < 3 or not _enclosed(tm, q, tol):
						bad = true
				if bad: outside += 1
				if sheet: outside_whole += 1
	var cut_ms := float(job.get("cut_usec", -1)) / 1000.0
	print("DEATH_SEAM machines=%d machines_split=%d %s" % [sets.size(), split, str(names)])
	print("DEATH_SEAM inside_triangles=%d inside_outside_hull=%d fragment_inside_triangles=%d pieces=%d main=%d (outside the whole ship before the break, a sheet matter: %d)" % [inside_total, outside, frag_inside, pieces.size(), n_main, outside_whole])
	print("DEATH_SEAM cut_worker_ms=%.1f main_thread_ms piece_build=%.1f (most in one frame %.1f; headless also builds the geometry here, a game window builds it on the worker) death=%.1f break_up=%.1f" % [cut_ms,
		float(prof.get("piece_meshes", 0)) / 1000.0, float(job.get("build_max_usec", 0)) / 1000.0, float(prof2.get("death", 0)) / 1000.0, float(prof2.get("break_up", 0)) / 1000.0])
	check(split == 0, "machines split across pieces: %d %s" % [split, str(names)])
	check(outside == 0, "inside triangles outside their own piece's hull: %d" % outside)
	check(inside_total > 0, "the pieces carry inside triangles")
	fx.remove_ship("a16")
	world.queue_free()
	print("DEATH_SEAM failures=%d" % failures)
	quit(1 if failures else 0)
