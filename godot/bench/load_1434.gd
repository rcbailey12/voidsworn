extends SceneTree
# Issue 1434 PC proof: the battle's ships are built a few per frame under the loading cover, and the title backdrop
# builds behind a menu that keeps answering, without touching the sound volume.
# Cases, in this order, in one windowed process on the real renderer and the real hulls:
#   s25        the 24-unit scenario, first so its hull files load cold
#   title      main.gd's title with its backdrop at sound volume 0.25: worst frame while it builds, and the shared sfx bus
#              read every frame from before the backdrop starts until it is freed (must not move)
#   b1, b2, b3 three default sector 1 fights (start_default, seeds 101, 202, 303), the shape of Battles 1 to 3
# Per battle: the longest main-thread stretch of the ship build (battle.gd load_stats: one ship's setup or its effects
# registration at most), the worst single ship's setup and registration, and the worst frame from the cover to play
# (that one includes the existing shader warm-up and is reported, not graded).
# PASS when every case's longest build stretch is under 500 ms and the title's bus never moved.
# Run: godot --path godot [--fullscreen] --script res://bench/load_1434.gd -- --out <folder>
const BattleScene = preload("res://scenes/battle/battle.tscn")
const MainScript = preload("res://main/main.gd")
const LIMIT_MS := 500
var out_dir := ""
var lines: Array = []
var pass_all := true


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--out")
	if i >= 0 and i + 1 < a.size():
		out_dir = a[i + 1]
	_run.call_deferred()


func _say(s: String) -> void:
	print(s)
	lines.append(s)


func _bus() -> String:
	var i := AudioServer.get_bus_index("sfx")
	return "%.2f dB%s" % [AudioServer.get_bus_volume_db(i), " muted" if AudioServer.is_bus_mute(i) else ""] if i >= 0 else "none"


func _battle(tag: String, args: Dictionary) -> void:
	var b = BattleScene.instantiate()
	for k in args:
		b.args[k] = args[k]
	b.args["quality"] = "max"
	b.bot = true   # no opening beat or story voice; the bot's first turn starts only after the load
	b.tips_off = true
	var t0 := Time.get_ticks_usec()
	root.add_child(b)
	var ready_ms := (Time.get_ticks_usec() - t0) / 1000
	var worst := 0
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	while (b.warming or b.load_stats.is_empty()) and Time.get_ticks_msec() - w0 < 240000:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
	var st: Dictionary = b.load_stats
	if st.is_empty():
		pass_all = false
		_say("[load1434] %s FAIL: no sliced build recorded (warming %s after %d ms)" % [tag, b.warming, Time.get_ticks_msec() - w0])
	else:
		var ok: bool = int(st["worst_stretch"]) / 1000 < LIMIT_MS
		pass_all = pass_all and ok
		_say("[load1434] %s %s: %d ships in %d ms over %d frames; longest build stretch %d ms; worst ship setup %d ms (%s), worst effects registration %d ms; waiting on hull files %d ms; scene ready %d ms; worst frame cover to play %d ms; to play %d ms" % [
			tag, "PASS" if ok else "FAIL", st["ships"], st["ms"], st["frames"], int(st["worst_stretch"]) / 1000,
			int(st["worst_setup"]) / 1000, st["worst_code"], int(st["worst_fx"]) / 1000, int(st["wait"]) / 1000, ready_ms,
			worst / 1000, Time.get_ticks_msec() - w0])
	b.queue_free()
	for i in 30:
		await process_frame


func _title() -> void:
	var m = MainScript.new()
	root.add_child(m)
	for i in 5:
		await process_frame
	m.settings["sound"] = true
	m.settings["volume"] = 0.25
	m._settings_to_ui_sound()
	await process_frame
	var before := _bus()
	var moved: Array = []
	var worst := 0
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	while (m.showcase == null or not is_instance_valid(m.showcase) or not m.showcase.showcase_ready) and Time.get_ticks_msec() - w0 < 120000:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		if _bus() != before: moved.append(_bus())
	var sc = m.showcase
	var st: Dictionary = sc.load_stats if sc != null and is_instance_valid(sc) else {}
	for i in 60:
		await process_frame
		if _bus() != before: moved.append(_bus())
	m._clear()   # leaving the title: stop_build, then free
	for i in 30:
		await process_frame
		if _bus() != before: moved.append(_bus())
	var ok: bool = not st.is_empty() and int(st["worst_stretch"]) / 1000 < LIMIT_MS and moved.is_empty()
	pass_all = pass_all and ok
	_say("[load1434] title %s: backdrop %s; longest build stretch %d ms; worst frame while it built %d ms (the menu's click latency); backdrop ready after %d ms; sfx bus %s before, %s" % [
		"PASS" if ok else "FAIL", "%d ships" % st["ships"] if not st.is_empty() else "never built", int(st.get("worst_stretch", 0)) / 1000,
		worst / 1000, Time.get_ticks_msec() - w0, before, "never moved" if moved.is_empty() else "moved to %s" % [moved.slice(0, 3)]])
	m.queue_free()
	for i in 10:
		await process_frame


func _run() -> void:
	_say("[load1434] display %s, window %s, renderer %s" % [DisplayServer.get_name(), str(root.get_visible_rect().size), RenderingServer.get_current_rendering_method()])
	await _battle("s25", {"scenario": "s25"})
	await _title()
	await _battle("b1", {"seed": 101})
	await _battle("b2", {"seed": 202})
	await _battle("b3", {"seed": 303})
	_say("[load1434] RESULT %s (limit %d ms per build stretch: one ship's setup or its effects registration)" % ["PASS" if pass_all else "FAIL", LIMIT_MS])
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var f := FileAccess.open(out_dir.path_join("load_result.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines) + "\n")
			f.close()
	quit(0 if pass_all else 1)
