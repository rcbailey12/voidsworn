extends RefCounted
# A headless check never waits (issue 632, sweep 545 row 10). A GDScript runtime error (a SCRIPT ERROR, such as index 0
# on an empty Array) stops the function it happens in, so a check whose quit() sits at the end of that function never
# reaches it and Godot runs on forever: issue 618's PC job sat on authored_interiors_check.gd that way. Every
# godot/**/test/*_check.gd calls arm() first thing in _init. From then on:
#   - any SCRIPT ERROR, in the check or in game code it drives, prints one FAIL line and quits with exit code 1 on the
#     next frame;
#   - a check still running after its time limit (seconds, real time, not slowed by Engine.time_scale) prints one FAIL
#     line and quits with exit code 1.
# Plain errors and warnings (push_error, ERR_FAIL lines from the engine) are not SCRIPT ERRORs: a check that counts its
# own failures with push_error keeps doing so and quits with its own code. The CI runner (godot/tools/ci/run_checks.sh)
# still fails a check on any SCRIPT ERROR line in its log and still has its own time limit; this guard makes the check
# end by itself, on GitHub and on Ryan's PC alike.

const DEFAULT_LIMIT := 240.0

class _ScriptErrors extends Logger:
	var _lock := Mutex.new()
	var count := 0
	var first := ""

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_SCRIPT:
			return
		_lock.lock()
		count += 1
		if first == "":
			first = "%s at %s:%d" % [rationale if rationale != "" else code, file, line]
		_lock.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func read() -> Array:
		_lock.lock()
		var r := [count, first]
		_lock.unlock()
		return r


class _Watch extends RefCounted:
	var tree: SceneTree
	var check_name := ""
	var limit_ms := 0
	var start_ms := 0
	var errs: _ScriptErrors
	var done := false

	func tick() -> void:
		if done:
			return
		var r: Array = errs.read()
		if int(r[0]) > 0:
			done = true
			print("FAIL: %s hit %d SCRIPT ERROR(s); first: %s. Quitting with exit code 1 instead of waiting (check_guard.gd)."
				% [check_name, int(r[0]), str(r[1])])
			tree.quit(1)
		elif Time.get_ticks_msec() - start_ms > limit_ms:
			done = true
			print("FAIL: %s still running after %d s, its time limit. Quitting with exit code 1 instead of waiting (check_guard.gd)."
				% [check_name, limit_ms / 1000])
			tree.quit(1)


static var _keep: Array = []


# Call first thing in a check's _init: CheckGuard.arm(self, "name_check"). limit is the real-time limit in seconds.
static func arm(tree: SceneTree, check_name: String, limit: float = DEFAULT_LIMIT) -> void:
	var errs := _ScriptErrors.new()
	OS.add_logger(errs)
	var w := _Watch.new()
	w.tree = tree
	w.check_name = check_name
	w.limit_ms = int(limit * 1000.0)
	w.start_ms = Time.get_ticks_msec()
	w.errs = errs
	_keep.append(w)
	tree.process_frame.connect(w.tick)
