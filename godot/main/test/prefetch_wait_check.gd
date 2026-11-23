extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1518 (Artoo on PR 1445): the game starts reading the battle's sky and sound clips on worker threads when it
# starts, and a battle collects them. A battle built while a read is still running would wait for it inside one frame,
# where a close is not seen. This checks:
#   1. the readiness tests never wait: sky_ready() and Sfx.prefetch_ready() each return within 5 ms on every frame of a
#      real prefetch, and once they say ready the collectors take under 50 ms;
#   2. with a read held pending (a stand-in readiness test that stays false), Main's test battle waits a frame at a time,
#      a close during that wait is seen on the next frame, and no battle is built afterwards.
const Main := preload("res://main/main.gd")
const BattleScript := preload("res://scenes/battle/battle.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestMain extends Main:
	var held := true
	var closed_at := -1
	var battles := 0

	func _prefetch_ready(with_sound: bool) -> bool:
		return not held and super(with_sound)

	func quit_clean(code := 0, route := "menu") -> void:
		if closed_at < 0:
			closed_at = Time.get_ticks_msec()
		quitting = true   # the real quit ends the process; the check only needs the flag it sets first

	func quick_battle() -> void:
		battles += 1

var failures := 0


func _init() -> void:
	GUARD.arm(self, "prefetch_wait_check")
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
	# 1. a real prefetch: the readiness tests are status reads only
	BattleScript.prefetch_sky()
	Sfx.prefetch()
	var worst := 0
	var frames := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		var t := Time.get_ticks_usec()
		var ready := BattleScript.sky_ready() and Sfx.prefetch_ready()
		worst = maxi(worst, Time.get_ticks_usec() - t)
		if ready:
			break
		frames += 1
		await process_frame
	check(worst < 5000, "the readiness tests never wait (worst %.2f ms over %d frames)" % [worst / 1000.0, frames])
	check(BattleScript.sky_ready() and Sfx.prefetch_ready(), "the prefetch finished")
	var sky := str(BattleScript.ShipView.manifest().get("sky", ""))
	var tc := Time.get_ticks_usec()
	if sky != "" and ResourceLoader.exists(sky):
		check(BattleScript._sky_texture(sky) != null, "the sky is collected")
	BattleScript.Sfx.drop_pending()
	check(Time.get_ticks_usec() - tc < 50000, "collecting after ready takes %.1f ms" % ((Time.get_ticks_usec() - tc) / 1000.0))
	BattleScript.drop_sky_pending()
	# 2. a read held pending: the test battle waits, a close in the wait is seen at once, no battle follows
	var main := TestMain.new()
	main.args["no-tips"] = true
	main.args["no-showcase"] = true
	root.add_child(main)
	for i in 3:
		await process_frame
	var waited := [false, false]
	var go := func() -> void:
		waited[1] = await main.prefetch_wait(true)
		waited[0] = true
	go.call()
	for i in 5:
		await process_frame
	check(not waited[0], "with a read pending the battle waits")
	var t_close := Time.get_ticks_msec()
	main.quit_clean(0, "window")
	await process_frame
	await process_frame
	check(waited[0] and not waited[1], "a close during the wait ends it within two frames, and the caller builds nothing")
	check(main.closed_at >= 0 and main.closed_at - t_close < 100, "the close ran at once")
	check(main.battles == 0, "no battle was built")
	# and released, a wait returns ready at once
	main.quitting = false
	main.held = false
	var t_r := Time.get_ticks_msec()
	var ok: bool = await main.prefetch_wait(true)
	check(ok and Time.get_ticks_msec() - t_r < 100, "with nothing pending the wait returns at once")
	main.quitting = true
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: prefetch_wait_check")
		quit(0)
	else:
		printerr("FAIL: prefetch_wait_check (%d)" % failures)
		quit(1)
