extends SceneTree
# Issue 1482 (independent game audit Nov 21, F-04 and F-12): leaving a battle while its own timers are still running
# logs nothing. Arms the Command (its 3.05 s second-tap timer), starts a kill hold, retreats, frees the battle the way
# main.gd does (queue_free), then waits past every timer and counts engine errors that name a freed object or a null tree.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")

class _Errs extends Logger:
	var _lock := Mutex.new()
	var lines: Array = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			_error_type: int, _bt: Array[ScriptBacktrace]) -> void:
		_lock.lock()
		lines.append("%s %s (%s:%d %s)" % [code, rationale, file, line, function])
		_lock.unlock()
	func _log_message(_message: String, _error: bool) -> void:
		pass
	func read() -> Array:
		_lock.lock()
		var r := lines.duplicate()
		_lock.unlock()
		return r

var failures := 0
var errs := _Errs.new()


func _init() -> void:
	GUARD.arm(self, "exit_timers_1482_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
	else:
		print("ok    ", message)


func _run() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		_done()
		return
	api.new_battle_scenario("s1", 1482)
	var b = load("res://scenes/battle/battle.gd").new()
	b.cine = "off"
	b.follow = false
	root.add_child(b)
	await b._begin(api)
	for i in 5:
		await process_frame
	OS.add_logger(errs)
	var before: int = errs.read().size()
	# the end card closed inside its focus beat while the battle stays (a Continue pressed at once): the beat fires on a freed button
	b.hud.show_end("Victory", "Test", true)
	b.hud.hide_end()
	await create_timer(1.0).timeout
	var card: Array = errs.read().slice(before).filter(func(l): return "freed" in str(l))
	_check(card.is_empty(), "an end card closed inside its focus beat logs nothing (%d: %s)" % [card.size(), str(card.slice(0, 2))])
	b._on_action("command", null)   # first tap: arms the Command and starts its 3.05 s timer
	b._kill_hold()                   # a kill cut-in hold (1.6 s at the battle's pace)
	b._schedule_impact(str(api.R.alive("enemy")[0]["id"]), {"shield": 0, "hull": 1, "quad": 0, "crit": false}, 0.5, 10.0, Color.WHITE, "battery")
	b._at_fx(0.5, func() -> void: pass)
	b.hud.show_end("Withdrawal", "Test", false)   # the end card's 0.75 s focus beat, then the battle goes before it fires
	await process_frame
	_check(b.cmd_armed_t > 0.0 and b.kill_hold_until > 0.0, "the Command timer and the kill hold are running when the battle goes")
	b.ended = true   # the retreat: the battle is over and main.gd frees it
	b.queue_free()
	await create_timer(4.0).timeout
	var got: Array = errs.read().slice(before)
	var bad: Array = got.filter(func(l): return "freed" in str(l) or "data.tree" in str(l) or "null instance" in str(l))
	_check(bad.is_empty(), "no freed-object or null-tree errors after leaving with timers running (%d: %s)" % [bad.size(), str(bad.slice(0, 3))])
	_done()


func _done() -> void:
	OS.remove_logger(errs)
	print("exit_timers_1482_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
