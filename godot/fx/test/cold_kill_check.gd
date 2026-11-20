extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1232: the first capital kill of a session froze the game and could lose its pieces. Two checks on A16 (C19_51):
#   1. the cut side by side (each surface and each seal on its own worker) gives exactly the pieces of the one-thread cut;
#   2. a cold kill: A16 arrives after the battle has started and dies 6 frames later, before its cut is ready, with the
#      frames paced at 60 a second as the game runs. It must still break into pieces (the hull holds its tell until the
#      cut is done; it used to pop with no pieces at 2.67 s), and the kill frame's own time is printed;
#   3. a stuck cut holds the death (and so the kill camera and the turn) no longer than DEATH.cold_cut_wall of real time.
# The ship: the GLB path after "--", else the installed res://assets/ships/C19_51/C19_51.glb, else the unpainted fixture
# (the same fixture death_seam_check.gd uses and keeps fresh). Times are printed, not checked: CI machines vary.
const FX := preload("res://fx/fx.gd")
const ROOT := preload("res://fx/test/world_root.gd")
const DEATH := preload("res://fx/fx_death.gd")
const FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
const INSTALLED := "res://assets/ships/C19_51/C19_51.glb"
var failures := 0


func _init() -> void:
	GUARD.arm(self, "cold_kill_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)


func _load_ship(world: Node3D) -> Node3D:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if not args.is_empty() else (INSTALLED if FileAccess.file_exists(INSTALLED) else FIXTURE)
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"): bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if bytes.is_empty() or doc.append_from_buffer(bytes, path.get_base_dir(), state) != OK: return null
	var ship: Node3D = doc.generate_scene(state)
	# Issues 1309 and 1355: rooted the way the game roots it (fx/test/world_root.gd), at world size
	var holder := ROOT.hold(world, ship)
	print("COLD_KILL ship ", path)
	return holder


func _fx(world: Node3D) -> Node:
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	return fx


func _signature(pieces: Array) -> String:
	var out: Array = []
	for pc in pieces:
		var surfs: Array = []
		for sd in pc["surfs"]:
			surfs.append([hash(sd["arrays"][Mesh.ARRAY_VERTEX]), hash(sd["arrays"][Mesh.ARRAY_INDEX]), hash(sd["arrays"][Mesh.ARRAY_NORMAL])])
		out.append([surfs, hash(pc["pts"]), int(pc["n"]), hash(str(pc.get("caps", null))), hash(str(pc.get("cap_fallbacks", 0)))])
	return str(hash(str(out)))


# One frame as the game runs it: 1/60 of a second of effect time, and at least 1/60 of a second of real time.
func _frame(fx) -> float:
	var t0 := Time.get_ticks_usec()
	fx.step(1.0 / 60.0)
	await process_frame
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	if ms < 16.6: OS.delay_usec(int((16.6 - ms) * 1000.0))
	return ms


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	# 1. the side by side cut equals the one-thread cut
	var ship := _load_ship(world)
	check(ship != null, "A16 loads")
	if ship == null:
		quit(1)
		return
	var fx = _fx(world)
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s = fx.ship("a16")
	check(ROOT.at_game_size(s, ROOT.held_length(s.root)), ROOT.size_note(s, ROOT.held_length(s.root)))
	check(s.hull.authored, "A16's seams reach the hull reader")
	DEATH.precompute(fx, s, "blast", true)
	var job: Dictionary = s.get_meta("cut_job")
	var sig := {}
	var ms := {}
	for serial in [true, false]:
		DEATH.cut_serial = serial
		var copy := job.duplicate()
		var t0 := Time.get_ticks_usec()
		var pieces: Array = DEATH._cut(copy)
		ms[serial] = float(Time.get_ticks_usec() - t0) / 1000.0
		sig[serial] = _signature(pieces)
		check(pieces.size() >= 4, "the cut made its pieces (%d)" % pieces.size())
	DEATH.cut_serial = false
	print("COLD_KILL cut one_thread_ms=%.1f side_by_side_ms=%.1f same_pieces=%s" % [ms[true], ms[false], str(sig[true] == sig[false])])
	check(sig[true] == sig[false], "the side by side cut gives the same pieces as the one-thread cut")
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	fx.remove_ship("a16")
	fx.queue_free()
	ship.queue_free()
	await process_frame
	# 2. the cold kill: arrives after the battle started (defer_initial_cuts off), dies 6 frames later
	ship = _load_ship(world)
	fx = _fx(world)
	fx.defer_initial_cuts = false
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	s = fx.ship("a16")
	for i in 6:
		await _frame(fx)
	var ready_at_kill: bool = s.has_meta("cut_job") and not s.has_meta("cut_task")
	var t_kill := Time.get_ticks_usec()
	var t_fx: float = fx.now
	fx.death("a16", "big")
	var kill_ms := float(Time.get_ticks_usec() - t_kill) / 1000.0
	var worst := 0.0
	var frames := 0
	while not s.has_meta("death_hidden") and frames < 60 * 15:
		worst = maxf(worst, await _frame(fx))
		frames += 1
	var hidden_after: float = fx.now - t_fx
	for i in 30:
		worst = maxf(worst, await _frame(fx))
	var pieces := 0
	for wr in fx.dstate.get("wrecks", []):
		if wr.get("id", "") != "a16": continue
		for nd in wr.get("nodes", []):
			if is_instance_valid(nd): pieces += 1
	var outcome := "unresolved" if not s.has_meta("death_hidden") else ("fractured" if pieces > 0 else "fallback (no pieces)")
	print("COLD_KILL kill cut_ready_at_kill=%s kill_frame_ms=%.1f worst_later_frame_ms=%.1f hidden_after=%.2fs held_past_split=%s outcome=%s pieces=%d" % [
		str(ready_at_kill), kill_ms, worst, hidden_after, str(s.has_meta("death_cut_wait")), outcome, pieces])
	check(outcome == "fractured", "the cold kill broke into pieces (%s)" % outcome)
	fx.release()
	ship.visible = false
	# 3. a stuck cut (a worker that never ends): the hull holds no longer than DEATH.cold_cut_wall of real time, then pops,
	#    so the kill camera and the turn, which wait for the core flash, are never held longer than that
	ship = _load_ship(world)
	fx = _fx(world)
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	s = fx.ship("a16")
	DEATH.precompute(fx, s, "blast", true)
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	var gate := Semaphore.new()
	var tid: int = fx.submit_death_cut(func() -> void: gate.wait())
	s.set_meta("cut_task", tid)
	var t_stuck := Time.get_ticks_usec()
	fx.death("a16", "big")
	while s.death_core_pending and Time.get_ticks_usec() - t_stuck < int((DEATH.cold_cut_wall + 3.0) * 1e6):
		await _frame(fx)
	var held := float(Time.get_ticks_usec() - t_stuck) / 1e6
	gate.post()
	print("COLD_KILL stuck_cut held=%.2fs cap=%.1fs core_pending=%s hidden=%s" % [held, DEATH.cold_cut_wall, str(s.death_core_pending), str(s.has_meta("death_hidden"))])
	check(not s.death_core_pending and s.has_meta("death_hidden"), "a stuck cut still ends the death")
	check(held <= DEATH.cold_cut_wall + 0.25, "a stuck cut holds the battle %.2f s, no longer than the %.1f s cap" % [held, DEATH.cold_cut_wall])
	fx.release()
	world.queue_free()
	print("COLD_KILL failures=%d" % failures)
	quit(1 if failures else 0)
