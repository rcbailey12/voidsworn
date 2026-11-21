extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1435 (Astra council W3). SYNTHETIC: this sends the close notification in a headless run; it is not the
# acceptance for the real title bar X and Alt-F4 on Windows (the PC proof, pc/1435 close timing). The window close button and Alt-F4 ended the process straight from SceneTree, past
# main.quit_clean (which frees the scenes, drains the fx jobs and clears the statics before the rendering server goes).
# This runs the real Main (title screen, headless) with an instrumented quit_clean and a stand-in battle holding an fx
# with a cut that is still running, then sends the system close the way the window does (the close notification and
# the root window's close_requested, which SceneTree listens to). It checks:
#   1. Main turned automatic quit off, so the close does not end the process on its own;
#   2. the close runs quit_clean once, by the "window" route, and a second close does not run it again;
#   3. leaving the battle did not wait for the cut, and by the time the process ends every retired job has drained.
const Main := preload("res://main/main.gd")
const FX := preload("res://fx/fx.gd")

class TestMain extends Main:
	var calls := 0
	var routes: Array = []

	func quit_clean(code := 0, route := "menu") -> void:
		if not quitting:
			calls += 1
			routes.append(route)
		super(code, route)

var failures := 0
var done := [false]


func _init() -> void:
	GUARD.arm(self, "quit_route_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)
	else:
		print("  ok: ", why)


func _run() -> void:
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/godot_checks/xdg/"):
		printerr("FAIL: refusing to write settings outside the game check sandbox")
		quit(1)
		return
	var main := TestMain.new()
	main.args["no-tips"] = true
	main.args["no-showcase"] = true
	root.add_child(main)
	for i in 3:
		await process_frame
	check(not auto_accept_quit, "Main turned automatic quit off (the close request is Main's to handle)")
	# a stand-in battle: an fx with a cut still running on a worker (held by a gate a helper thread opens later)
	var battle := Node3D.new()
	main.add_child(battle)
	main.battle = battle
	var fx = FX.new()
	battle.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	var gate := Semaphore.new()
	fx.submit_death_cut(func() -> void:
		gate.wait()
		done[0] = true)
	root.tree_exiting.connect(_at_exit.bind(main))
	var poster := Thread.new()
	poster.start(func() -> void:
		OS.delay_msec(400)
		gate.post())
	var t0 := Time.get_ticks_usec()
	root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	root.close_requested.emit()
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	check(main.calls == 1 and main.quit_route == "window", "the window close runs quit_clean by the window route (%d calls, %s)" % [main.calls, main.quit_route])
	root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(main.calls == 1, "a second close does not start a second quit")
	await process_frame
	check(main.quitting, "still running one frame after the close: quit_clean owns the exit")
	check(FX.retired_count() == 1 and not done[0], "the battle left without waiting for its cut (retired %d, close handled in %.1f ms)" % [FX.retired_count(), ms])
	poster.wait_to_finish()


func _at_exit(main) -> void:
	check(done[0] and FX.retired_count() == 0, "every retired job drained before the process ended")
	check(main.routes == ["window"], "quit_clean ran once (%s)" % str(main.routes))
	print("QUIT_ROUTE failures=%d" % failures)
	quit(1 if failures else 0)
