extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1279: on Ryan's PC a capital's arrival logged "Jolt Physics job system exceeded the maximum number of jobs" and
# the physics step stalled. The cause: Jolt runs its step jobs on the shared worker lanes and holds each job in a fixed
# table until a lane has run it, so while any body moves, a second or more of long work on every high-priority lane
# (shader and pipeline compiles, a death cut's side-by-side lanes) fills the table. Every live ship's hull collider
# moves with its ship, so Jolt stepped all battle long. The checks, on box stand-ins, no ship files:
#   1. a death cut's side-by-side lanes leave two lanes free beyond what low-priority work can hold;
#   2. with moving hull colliders and no loose debris the battle's physics space sleeps (Jolt makes no jobs);
#   3. while it sleeps, every worker lane held by long high-priority work for 2 s raises no "exceeded" warning;
#   4. debris wakes the space at once; once every plate has settled (issue 1237, DEBRIS_REST_S) the space sleeps again;
#      a moving wreck section keeps it awake and still knocks a resting plate awake;
#   5. with JOLT_JOBS_CONTROL=1 only, a control (printed, not checked: it depends on the machine's lane count): the same
#      starve with the space awake, the old behaviour. Off by default: on Ryan's PC tools/pc/run_timeout.ps1 stops any
#      Godot that logs the warning, so the standing check never provokes it.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0
var _log := JobLog.new()
var _movers: Array = []


class JobLog extends Logger:
	var _lock := Mutex.new()
	var exceeded := 0

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool,
			_error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if (code + rationale).contains("job system exceeded"):
			_lock.lock()
			exceeded += 1
			_lock.unlock()

	func _log_message(message: String, _error: bool) -> void:
		if message.contains("job system exceeded"):
			_lock.lock()
			exceeded += 1
			_lock.unlock()

	func read() -> int:
		_lock.lock()
		var n := exceeded
		_lock.unlock()
		return n


func _init() -> void:
	GUARD.arm(self, "jolt_jobs_check", 120.0)
	OS.add_logger(_log)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)
	print(("  ok   " if ok else "  FAIL ") + why)


func _space_awake(fx) -> bool:
	return bool(fx._phys_awake)


# Run the game's frames for `sec` seconds of real time: the fx clock, the hull colliders moving with their ships.
func _run_for(fx, sec: float) -> void:
	var end := Time.get_ticks_msec() + int(sec * 1000.0)
	while Time.get_ticks_msec() < end:
		fx.step(1.0 / 60.0)
		for b in _movers:
			(b as Node3D).position.z += 0.02
		await physics_frame


# Every worker lane busy with high-priority work for `sec` seconds, as a shader compile storm or an old death cut did.
func _starve(fx, sec: float) -> int:
	var lanes := OS.get_processor_count()
	var ms := int(sec * 1000.0)
	var gid := WorkerThreadPool.add_group_task(func(_i: int) -> void:
		var e := Time.get_ticks_msec() + ms
		while Time.get_ticks_msec() < e: pass, lanes, lanes, true, "jolt_jobs_check starve")
	var before := _log.read()
	var t0 := Time.get_ticks_msec()
	await _run_for(fx, sec + 0.5)
	WorkerThreadPool.wait_for_group_task_completion(gid)
	print("  starve %.1f s on %d lanes: frames ran %.1f s, job table warnings %d" % [sec, lanes, (Time.get_ticks_msec() - t0) / 1000.0, _log.read() - before])
	return _log.read() - before


func _run() -> void:
	# 1. lane budget
	var threads := int(ProjectSettings.get_setting("threading/worker_pool/max_threads", -1))
	if threads <= 0: threads = OS.get_processor_count()
	var low := clampi(int(threads * float(ProjectSettings.get_setting("threading/worker_pool/low_priority_thread_ratio", 0.3))), 1, maxi(threads - 1, 1))
	var lanes: int = DEATH.cut_lanes(64)
	print("JOLT_JOBS lanes: threads %d, low-priority cap %d, cut lanes %d" % [threads, low, lanes])
	check(lanes >= 1, "a cut always has a lane")
	check(threads < 4 or lanes + low + 2 <= threads, "a cut leaves two lanes free beyond the low-priority cap")
	check(DEATH.cut_lanes(3) <= 3, "a cut never asks for more lanes than it has work")

	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": null, "shake": 0.0})
	check(bool(fx.dstate.get("physics_on", false)), "physics is on at high quality")
	# 2. hull colliders as DEATH.add_collider makes them, moving with their ships
	for i in 6:
		var body := AnimatableBody3D.new()
		body.sync_to_physics = false
		body.collision_layer = DEATH.HULL_LAYER
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		cs.shape = BoxShape3D.new()
		body.add_child(cs)
		world.add_child(body)
		body.position = Vector3(i * 4.0, 0, 0)
		_movers.append(body)
	await _run_for(fx, 0.6)
	check(not _space_awake(fx), "moving hull colliders alone leave the physics space asleep")
	# 3. starve every lane with the space asleep
	var asleep_hits := await _starve(fx, 2.0)
	check(asleep_hits == 0, "no job table warning while the space sleeps and every lane is held for 2 s")
	# 4. debris wakes it; stopped debris lets it sleep again
	DEATH.spawn_debris(fx, Vector3(0, 0, 10), Vector3.ZERO, 4, 0.5)
	check(_space_awake(fx), "debris wakes the physics space at once")
	await _run_for(fx, 0.6)
	check(_space_awake(fx), "drifting debris keeps the space awake")
	# with issue 1237's settle (merged first), every plate is stopped and asleep by DEATH.DEBRIS_REST_S, and the space with it
	await _run_for(fx, DEATH.DEBRIS_REST_S + 1.0)
	var slept := true
	for b in fx.dstate["debris"]:
		slept = slept and (b as RigidBody3D).sleeping
	check(slept, "every plate is asleep by DEBRIS_REST_S")
	check(not _space_awake(fx), "the space sleeps again once nothing loose is awake")
	# a moving wreck section (a loose rigid body under phys_root) keeps the space awake and still knocks a resting plate awake
	var plate := fx.dstate["debris"][0] as RigidBody3D
	var section := RigidBody3D.new()
	section.gravity_scale = 0.0
	section.collision_layer = DEATH.DEBRIS_LAYER
	section.collision_mask = DEATH.HULL_LAYER | DEATH.DEBRIS_LAYER
	var scs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 3, 3)
	scs.shape = box
	section.add_child(scs)
	fx.wake_physics()
	fx.phys_root.add_child(section)
	section.global_position = plate.global_position + Vector3(-6, 0, 0)
	section.linear_velocity = Vector3(8, 0, 0)
	var knocked := false
	var end := Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < end:
		await _run_for(fx, 0.05)
		knocked = knocked or not plate.sleeping
	check(_space_awake(fx), "a moving wreck section keeps the space awake")
	check(knocked, "a moving wreck section still knocks a resting plate awake")
	section.queue_free()
	# 5. control: the same starve with the space awake (the old behaviour), printed only
	if OS.get_environment("JOLT_JOBS_CONTROL") == "1":
		fx.wake_physics()
		DEATH.spawn_debris(fx, Vector3(0, 0, 10), Vector3.ZERO, 4, 0.5)
		var awake_hits := await _starve(fx, 2.0)
		print("JOLT_JOBS control (space awake, every lane held 2 s): warnings %d (1 shows the starve reaches Jolt here)" % awake_hits)
	world.queue_free()
	await process_frame
	print("JOLT_JOBS %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
