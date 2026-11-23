extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1518 (Artoo on PR 1445): the game starts reading the battle's sky and sound clips on worker threads when it
# starts. Nothing may wait for one of those reads inside a frame, where a close is not seen, whichever way a battle is
# entered. This checks, through the real parts:
#   1. sound: a battle sound made while its clips are still being read takes no time for them (they join later, a frame
#      at a time), and once read they are all there;
#   2. sky: a battle entered the real way (Main's quick battle) while its sky is still being read (held as reading)
#      waits for it a frame at a time before its board; a window close during that wait is seen at once and stops the
#      build, which never goes on, even once the read is done;
#   3. the campaign's way in (Main.play_api) while the effects script is still being read (held as reading) builds no
#      battle until it is read; a window close during that wait ends it and play_api returns without a battle.
const Main := preload("res://main/main.gd")
const BattleScript := preload("res://scenes/battle/battle.gd")
const Sfx := preload("res://audio/sfx.gd")
const SV := preload("res://render/ship_view.gd")

class TestMain extends Main:
	var closed_at := -1

	func quit_clean(code := 0, route := "menu") -> void:
		# the real quit ends the process; this keeps what it does to a loading battle (stop its build) and the flag
		if closed_at < 0:
			closed_at = Time.get_ticks_msec()
		quitting = true
		if battle != null and is_instance_valid(battle) and battle.has_method("stop_build"):
			battle.stop_build()

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
	# 1. sound made while its clips are being read
	Sfx.prefetch()
	var pending_at_start := Sfx._pending.size()
	var s = Sfx.new()
	var t0 := Time.get_ticks_usec()
	root.add_child(s)
	var ready_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var late_at_start: int = s._late.size()
	print("  sound: %d reads asked, %d still running when the sound was made, made in %.1f ms" % [pending_at_start, late_at_start, ready_ms])
	check(pending_at_start == 0 or late_at_start > 0, "some clip reads were still running when the sound was made (the case under test)")
	var tw := Time.get_ticks_msec()
	while not s._late.is_empty() and Time.get_ticks_msec() - tw < 20000:
		await process_frame
	check(s._late.is_empty(), "the late clips joined their sets")
	var takes := 0
	for k in s.clips:
		takes += (s.clips[k] as Array).size()
	check(takes > 0, "the clip sets hold their takes (%d)" % takes)
	s.queue_free()
	await process_frame
	# 2. the sky, held as still being read, through Main's quick battle
	var sky := "res://fx/atlases/death/capital/cool_color.png"
	for c in ["res://fx/atlases/death/capital/cool_color.png"]:
		if ResourceLoader.exists(c):
			sky = c
			break
	check(ResourceLoader.exists(sky), "a stand-in sky texture exists (%s)" % sky)
	SV._manifest = {"sky": sky}
	BattleScript.hold_sky = true
	BattleScript.prefetch_sky()
	check(not BattleScript.sky_ready(), "the sky read counts as running")
	var main := TestMain.new()
	main.args["no-tips"] = true
	main.args["no-showcase"] = true
	main.args["battle"] = true
	root.add_child(main)
	await process_frame
	main.quick_battle()   # the real entry point
	var b = main.battle
	for i in 5:
		await process_frame
	check(b != null and is_instance_valid(b) and str(b.load_phase) == "start" and b.begin_us.is_empty(), "the battle waits for its sky before its board (phase %s)" % (str(b.load_phase) if b != null else "-"))
	var t_close := Time.get_ticks_msec()
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(main.closed_at >= 0 and main.closed_at - t_close < 100, "the window close ran at once during the wait")
	BattleScript.hold_sky = false
	for i in 5:
		await process_frame
	check(is_instance_valid(b) and b.begin_us.is_empty() and (b.V as Dictionary).is_empty(), "the stopped build never went on, even once the sky was read")
	BattleScript.drop_sky_pending()
	SV._manifest = null
	# 3. the campaign's way in, with the effects script held as being read
	main.quitting = false
	main.closed_at = -1
	main.battle = null
	check(ResourceLoader.load_threaded_request(Main.FX_SCRIPT) == OK, "the effects script read was asked for")
	main._fx_reading = true
	main.hold_fx_read = true
	var got := [null]
	var go := func() -> void: got[0] = await main.play_api(null)
	go.call()
	for i in 5:
		await process_frame
	check(got[0] == null and main.battle == null, "play_api builds no battle while the effects script is being read")
	var t_c2 := Time.get_ticks_msec()
	main._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await process_frame
	await process_frame
	check(main.closed_at >= 0 and main.closed_at - t_c2 < 100, "the window close ran at once during that wait")
	check(got[0] is Dictionary and str(got[0].get("result", "")) == "quit" and main.battle == null, "play_api ended without a battle")
	main.hold_fx_read = false
	if main._fx_reading:
		ResourceLoader.load_threaded_get(Main.FX_SCRIPT)
		main._fx_reading = false
	main.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: prefetch_wait_check")
		quit(0)
	else:
		printerr("FAIL: prefetch_wait_check (%d)" % failures)
		quit(1)
