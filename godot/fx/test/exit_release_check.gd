extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1435 (Astra council item 5): leaving a battle waited on the caller for the death cut, shield and damage jobs
# (fx.release() 5.7 to 6.5 s with one A16 cut out). Now the fx leaving the tree retires its running jobs instead:
#   1. a cut that cannot finish yet (held by a gate): the fx leaves the tree in under 200 ms, the job is retired, not
#      lost, and the retired job is reaped on a later frame once it ends;
#   2. a released fx takes no new cuts (precompute does nothing on it);
#   3. quit drains: FX.clear_static (static_caches clear_all, main.quit_clean) waits for every retired job;
#   4. a real A16 blast cut submitted just before the scene change: the caller's time is printed and checked, and the
#      cut is reaped later (the same set-up as cold_kill_check.gd and Astra's measurement).
# The ship: the installed res://assets/ships/C19_51/C19_51.glb, else the unpainted fixture.
const FX := preload("res://fx/fx.gd")
const ROOT := preload("res://tools/ci/world_root.gd")
const DEATH := preload("res://fx/fx_death.gd")
const FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"
const INSTALLED := "res://assets/ships/C19_51/C19_51.glb"
const CALLER_LIMIT_MS := 200.0
var failures := 0


func _init() -> void:
	GUARD.arm(self, "exit_release_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)
	else:
		print("  ok: ", why)


func _load_ship(world: Node3D) -> Node3D:
	var path: String = INSTALLED if FileAccess.file_exists(INSTALLED) else FIXTURE
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"): bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if bytes.is_empty() or doc.append_from_buffer(bytes, path.get_base_dir(), state) != OK: return null
	return ROOT.hold(world, doc.generate_scene(state))


func _fx(world: Node3D) -> Node:
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	return fx


# The scene change as the game does it: the battle node holding the fx leaves the tree and is freed (fx _exit_tree runs
# release(false)); returns the caller's time in ms for both. This is the fx part of leaving only, not the title rebuild
# after a quick battle (main.gd quick_battle); the PC proof times the real window close on Windows.
func _leave(world: Node3D, fx: Node) -> float:
	var battle: Node = fx.get_parent()
	var t0 := Time.get_ticks_usec()
	world.remove_child(battle)
	battle.free()
	return float(Time.get_ticks_usec() - t0) / 1000.0


# Each round's stand-in battle: the ship and the fx live under it, as in the game, and leave with it.
var _cur: Node3D


func _round(world: Node3D) -> Node3D:
	_cur = Node3D.new()
	world.add_child(_cur)
	return _cur


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ship := _load_ship(_round(world))
	check(ship != null, "A16 loads")
	if ship == null:
		quit(1)
		return
	# 1. a held cut is retired, not waited for, and reaped once it ends
	var fx = _fx(_cur)
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	var s = fx.ship("a16")
	var gate := Semaphore.new()
	var done := [false]
	var tid: int = fx.submit_death_cut(func() -> void:
		gate.wait()
		done[0] = true)
	s.set_meta("cut_task", tid)
	var ms := _leave(world, fx)
	print("EXIT_RELEASE held cut: caller_ms=%.2f retired=%d" % [ms, FX.retired_count()])
	check(ms < CALLER_LIMIT_MS, "leaving with a held cut returns in %.1f ms (under %d)" % [ms, int(CALLER_LIMIT_MS)])
	# the ship's own load jobs (its shield skin) may be retired beside the held cut
	var retired_at_leave := FX.retired_count()
	check(retired_at_leave >= 1, "the held cut is retired, not dropped (%d retired)" % retired_at_leave)
	for i in 5:
		await process_frame
	check(FX.retired_count() >= 1 and not done[0], "a running job stays retired until it ends")
	gate.post()
	var frames := 0
	while FX.retired_count() > 0 and frames < 60 * 30:
		await process_frame
		frames += 1
	check(FX.retired_count() == 0 and done[0], "the ended job is reaped on a later frame (%d frames)" % frames)
	# 2. a released fx takes no new cuts
	ship = _load_ship(_round(world))
	fx = _fx(_cur)
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	s = fx.ship("a16")
	fx.release()
	DEATH.precompute(fx, s, "blast", true)
	check(not s.has_meta("cut_task"), "a released fx starts no new cut")
	fx.queue_free()
	_cur.queue_free()
	await process_frame
	# 3. quit drains the retired jobs
	ship = _load_ship(_round(world))
	fx = _fx(_cur)
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	gate = Semaphore.new()
	done = [false]
	tid = fx.submit_death_cut(func() -> void:
		gate.wait()
		done[0] = true)
	_leave(world, fx)
	check(FX.retired_count() >= 1, "a second held cut is retired")
	var poster := Thread.new()
	poster.start(func() -> void:
		OS.delay_msec(300)
		gate.post())
	var t_drain := Time.get_ticks_usec()
	FX.clear_static()
	var drain_ms := float(Time.get_ticks_usec() - t_drain) / 1000.0
	poster.wait_to_finish()
	check(FX.retired_count() == 0 and done[0], "clear_static waits for the retired job before it returns (%.0f ms)" % drain_ms)
	await process_frame
	# 4. a real A16 blast cut out at the scene change
	ship = _load_ship(_round(world))
	fx = _fx(_cur)
	fx.defer_initial_cuts = true
	fx.add_ship("a16", ship, {"faction": "corsair", "cls": "Battle-barge", "size": 1.22})
	s = fx.ship("a16")
	DEATH.precompute(fx, s, "blast", true)
	var real_tid: int = s.get_meta("cut_task", -1)
	check(real_tid >= 0, "the A16 blast cut is out")
	var pending := real_tid >= 0 and not WorkerThreadPool.is_task_completed(real_tid)
	check(pending, "the A16 cut is still running when the battle leaves (the case being timed)")
	ms = _leave(world, fx)
	print("EXIT_RELEASE a16 cut: pending_at_leave=%s caller_ms=%.2f retired=%d" % [str(pending), ms, FX.retired_count()])
	check(ms < CALLER_LIMIT_MS, "leaving with the A16 cut out returns in %.1f ms (under %d)" % [ms, int(CALLER_LIMIT_MS)])
	var t_reap := Time.get_ticks_usec()
	frames = 0
	while FX.retired_count() > 0 and frames < 60 * 30:
		await process_frame
		frames += 1
	print("EXIT_RELEASE a16 cut reaped after %d frames, %.0f ms" % [frames, float(Time.get_ticks_usec() - t_reap) / 1000.0])
	check(FX.retired_count() == 0, "the A16 cut is reaped on later frames")
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("EXIT_RELEASE failures=%d" % failures)
	quit(1 if failures else 0)
