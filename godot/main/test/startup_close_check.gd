extends SceneTree

# Issue 1518. Synthetic draw and close events drive Main's windowed launch without a GPU or a native window.
const GUARD := preload("res://tools/ci/check_guard.gd")
const Main := preload("res://main/main.gd")


class TestMain extends Main:
	var prefetches := 0
	var quick_battles := 0

	func _wait_for_first_draw() -> bool:
		return true

	func _prefetch_launch() -> void:
		prefetches += 1
		super()

	func quick_battle() -> void:
		quick_battles += 1


var failures := 0


func _init() -> void:
	GUARD.arm(self, "startup_close_check", 30.0)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if ok:
		print("  ok: ", why)
	else:
		failures += 1
		push_error(why)


func _no_launch_work(main: TestMain, expected_sound_prefetches: int) -> bool:
	return (main.prefetches == 0 and main.quick_battles == 0 and main.title == null and main.ui_sound == null
			and not main._host_reading and not main._scene_reading and not main._fx_reading
			and Main.Sfx._prefetch_calls == expected_sound_prefetches)


func _run() -> void:
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/godot_checks/xdg/"):
		printerr("FAIL: refusing to use settings outside the game check sandbox")
		quit(1)
		return
	RenderingServer.render_loop_enabled = false   # only the test emits the first draw
	var main := TestMain.new()
	main.args["battle"] = true
	main.hold_fx_read = true
	root.add_child(main)
	check(not auto_accept_quit and main._launch_battle_pending, "the close route is armed while the quick battle waits to launch")
	for i in 3:
		await process_frame
	check(_no_launch_work(main, 0), "process frames alone do not start the launch before its first draw")
	RenderingServer.frame_post_draw.emit()
	check(_no_launch_work(main, 0), "the draw callback itself does not start the launch")
	for i in 3:
		await process_frame
	check(main.prefetches == 1 and main._host_reading and main._scene_reading and main._fx_reading,
			"the campaign host, battle scene and effects reads start once after the first draw")
	check(Main.Sfx._prefetch_calls == 1, "battle sound prefetch starts once after the first draw")
	check(main.quick_battles == 0 and main._launch_battle_pending, "the quick battle waits across frames for the held effects read")
	main.hold_fx_read = false
	while main._launch_battle_pending:
		await process_frame
	check(main.quick_battles == 1 and not main._fx_reading and not main._scene_reading,
			"the quick battle starts once after the background reads finish")
	# Drain completed resources before the second Main, so residual requests cannot mask a new one.
	if main._host_reading:
		while main._host_still_reading():
			await process_frame
		ResourceLoader.load_threaded_get(Main.HOST_SCRIPT)
	while not Main.Sfx.prefetch_ready():
		await process_frame
	Main.Sfx.drop_pending()
	main.queue_free()
	await process_frame

	var closing := TestMain.new()
	closing.args["battle"] = true
	root.add_child(closing)
	check(_no_launch_work(closing, 1), "no launch work is running when the window is closed before the first draw")
	root.tree_exiting.connect(_at_exit.bind(closing))
	root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	root.close_requested.emit()
	check(closing.quitting and closing.quit_route == "window", "the close before first draw immediately enters the real quit route")
	RenderingServer.frame_post_draw.emit()


func _at_exit(main: TestMain) -> void:
	check(_no_launch_work(main, 1), "a late first draw did not start prefetch or build a screen after close")
	print("STARTUP_CLOSE failures=%d" % failures)
	quit(1 if failures else 0)
