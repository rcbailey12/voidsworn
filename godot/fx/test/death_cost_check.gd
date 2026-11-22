extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1395 (Neon F9): where a capital kill spends main-thread time. One big kill of A16 (C19_51, the fixture when the
# installed glb is missing), its cut ready as in a battle, quality high, anchored to its hex so the wreck draws together.
# Prints, in milliseconds of this machine's CPU:
#   DEATH_COST frames: the kill frame and the worst frames after it (fx.step plus the engine frame), with the effect time
#   DEATH_COST reach: _measure_reach (the leash's one-piece-a-frame face read) per piece: worst, total, vertex counts
#   DEATH_COST tell: _tell's tear material copy per hull mesh (duplicate, frame uniform, overlay), all meshes together
#   DEATH_COST flush: fragment Pool.flush with a full pool and fresh rows (the one data texture upload)
#   DEATH_COST particles: tear_particles' two GPU emitters made and added (only off headless; headless skips them)
# Times are printed, not checked (CI machines vary; the PC capture, GPU solo, R293, is the verdict). Checked: every main
# wreck piece carries the reach its cut's worker measured (so the draw-in reads no faces on the main thread), and that
# number matches the old face read within 0.1 percent (so the wreck settles exactly where it did). Run:
#   godot --headless --path godot --script res://fx/test/death_cost_check.gd [-- path/to/ship.glb]
const FX := preload("res://fx/fx.gd")
const ROOT := preload("res://tools/ci/world_root.gd")
const DEATH := preload("res://fx/fx_death.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
const INSTALLED := "res://assets/ships/C19_51/C19_51.glb"


func _init() -> void:
	GUARD.arm(self, "death_cost_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _load_ship(world: Node3D) -> Node3D:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else (INSTALLED if FileAccess.file_exists(INSTALLED) else FIXTURE)
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"): bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if bytes.is_empty() or doc.append_from_buffer(bytes, path.get_base_dir(), state) != OK: return null
	var ship: Node3D = doc.generate_scene(state)
	print("DEATH_COST ship ", path)
	return ROOT.hold(world, ship)


var failures := 0


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _ms(t0: int) -> float:
	return float(Time.get_ticks_usec() - t0) / 1000.0


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 60, 80)
	cam.look_at(Vector3.ZERO)
	var ship := _load_ship(world)
	if ship == null:
		print("DEATH_COST no ship")
		quit(1)
		return
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s = fx.ship("a16")
	DEATH.precompute(fx, s, "big", true)
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	fx.anchor_wreck("a16", ship.global_position, 14.0)
	for i in 10:
		fx.step(1.0 / 60.0)
		await process_frame
	# the kill, then 12 s of effect time at 60 a second
	var t0 := Time.get_ticks_usec()
	var t_fx: float = fx.now
	fx.death("a16", "big")
	var kill_ms := _ms(t0)
	var frames: Array = []
	for i in 60 * 12:
		var f0 := Time.get_ticks_usec()
		fx.step(1.0 / 60.0)
		var step_ms := _ms(f0)
		await process_frame
		frames.append([_ms(f0), step_ms, fx.now - t_fx])
	frames.sort_custom(func(a, b): return a[0] > b[0])
	var worst: Array = []
	for f in frames.slice(0, 6):
		worst.append("%.1f (step %.1f) at %.2fs" % [f[0], f[1], f[2]])
	print("DEATH_COST frames kill_call_ms=%.1f worst=%s" % [kill_ms, ", ".join(worst)])
	# _measure_reach, piece by piece, as the leash reads it (one piece a frame): the old face read against the worker's
	# number (reach_pre, issue 1395), which must agree with it
	var reach_worst := 0.0
	var reach_total := 0.0
	var pre_worst := 0.0
	var verts_worst := 0
	var pieces := 0
	var with_pre := 0
	var worst_gap := 0.0
	for w in fx.dstate.get("wrecks", []):
		for nd in w["nodes"]:
			if not is_instance_valid(nd): continue
			pieces += 1
			var pre = nd.get_meta("reach_pre", null)
			nd.remove_meta("leash_rad")
			nd.remove_meta("reach_pre")
			var r0 := Time.get_ticks_usec()
			DEATH._measure_reach(nd)
			var ms := _ms(r0)
			reach_worst = maxf(reach_worst, ms)
			reach_total += ms
			var faces: float = nd.get_meta("leash_rad")
			if pre != null:
				with_pre += 1
				nd.remove_meta("leash_rad")
				nd.set_meta("reach_pre", pre)
				var p0 := Time.get_ticks_usec()
				DEATH._measure_reach(nd)
				pre_worst = maxf(pre_worst, _ms(p0))
				worst_gap = maxf(worst_gap, absf(float(pre) - faces) / maxf(faces, 1e-4))
			for ch in nd.get_children():
				if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
					verts_worst = maxi(verts_worst, (ch as MeshInstance3D).mesh.get_faces().size())
					break
	print("DEATH_COST reach pieces=%d face_read worst_ms=%.2f total_ms=%.2f biggest_piece_face_points=%d | worker number on %d pieces, worst_ms=%.3f, worst gap to the face read %.4f%%" % [
		pieces, reach_worst, reach_total, verts_worst, with_pre, pre_worst, worst_gap * 100.0])
	check(pieces >= 2, "the kill left its wreck pieces (%d)" % pieces)
	check(with_pre == pieces, "every main piece has its worker-measured reach (%d of %d)" % [with_pre, pieces])
	check(worst_gap <= 0.001, "the worker reach matches the face read (worst gap %.4f%%)" % (worst_gap * 100.0))
	# _tell's material copies, on a fresh copy of the ship's meshes
	var ship2 := _load_ship(world)
	fx.add_ship("b16", ship2, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s2 = fx.ship("b16")
	var base: ShaderMaterial = fx.dstate["tear_mat"] if fx.dstate.has("tear_mat") else ShaderMaterial.new()
	var t1 := Time.get_ticks_usec()
	for mm in s2.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = base.duplicate()
			local.set_shader_parameter("frame", s2.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local
	print("DEATH_COST tell meshes=%d copies_ms=%.2f" % [s2.meshes.size(), _ms(t1)])
	# the fragment pool's flush: full pool, all rows fresh
	var pool = fx.pools.get("plate")
	if pool != null:
		var row := PackedFloat32Array()
		row.resize(20)
		row[7] = fx.now
		row[11] = 30.0
		for i in pool.cap:
			pool.emit(row.duplicate(), {})
		var t2 := Time.get_ticks_usec()
		pool.flush(fx.now)
		print("DEATH_COST flush rows=%d upload_ms=%.2f" % [pool.cap, _ms(t2)])
	if DisplayServer.get_name() != "headless":
		var t3 := Time.get_ticks_usec()
		for i in 4:
			DEATH.tear_particles(fx, Vector3.ZERO, Vector3.UP, 30.0, Vector3.ZERO, false, s2)
		print("DEATH_COST particles emitters=8 make_ms=%.2f (first call includes material setup)" % _ms(t3))
	else:
		print("DEATH_COST particles skipped (headless makes none)")
	fx.release()
	world.queue_free()
	print("DEATH_COST failures=%d" % failures)
	# the PC before/after job runs this file on the old code too, where the reach lines fail by design: times only there
	quit(0 if OS.get_environment("VS_1395_BASELINE") == "1" else (1 if failures else 0))
