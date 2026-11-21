extends SceneTree
# Issue 1434 PC proof: the battle's ships are built a few per frame under the loading cover, and the title backdrop
# builds behind a menu that keeps answering, without touching the sound volume.
# Cases, in this order, in one windowed process on the real renderer and the real hulls:
#   s25        the 24-unit scenario, first so its hull files load cold
#   title      main.gd's title with its backdrop at sound volume 0.25: worst frame while it builds, and the shared sfx bus
#              read every frame from before the backdrop starts until it is freed (must not move)
#   leave      a second cold title, New run clicked while its backdrop builds
#   b1, b2, b3 three default sector 1 fights (start_default, seeds 101, 202, 303), the shape of Battles 1 to 3
# Per battle: the longest main-thread stretch of the ship build (battle.gd load_stats: one ship's setup or its effects
# registration at most), the worst single ship's setup and registration, and the worst frame from the cover to play,
# with the load phase of the five worst frames and the time spent in each phase.
# Graded separately (Artoo on PR 1445), every one must hold for PASS:
#   slice   the longest ship build stretch under 500 ms
#   ready   the battle reached play (warming cleared) / the backdrop reached showcase_ready before its time limit
#   cover   the worst frame from the cover to play under 500 ms (it includes the existing shader warm-up)
#   click   the title's Settings link, clicked by a real mouse press and release while the backdrop is still building,
#           opens its drawer within 500 ms
#   bus     the title's shared sfx bus never moved
#   leave   New run clicked while the title backdrop builds: the backdrop's exit under 100 ms on the main thread (_leave)
# Run: godot --path godot [--fullscreen] --script res://bench/load_1434.gd -- --out <folder>
const BattleScene = preload("res://scenes/battle/battle.tscn")
const MainScript = preload("res://main/main.gd")
const LIMIT_MS := 500
var out_dir := ""
var lines: Array = []
var pass_all := true
var cases := PackedStringArray(["s25", "title", "leave", "b1", "b2", "b3"])


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--out")
	if i >= 0 and i + 1 < a.size():
		out_dir = a[i + 1]
	var c := a.find("--cases")   # a subset for a quick trial, e.g. --cases leave,b1 (the PC job runs them all)
	if c >= 0 and c + 1 < a.size():
		cases = a[c + 1].split(",")
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
	var frames: Array = []   # [ms, phase before -> phase after] for every frame under the cover
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	while (b.warming or b.load_stats.is_empty()) and Time.get_ticks_msec() - w0 < 240000:
		var ph0: String = b.load_phase
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		frames.append([(now - last) / 1000, ph0 if ph0 == b.load_phase else "%s->%s" % [ph0, b.load_phase]])
		last = now
	frames.sort_custom(func(x, y): return x[0] > y[0])
	var top := PackedStringArray()
	for f in frames.slice(0, 5):
		top.append("%d ms %s" % [f[0], f[1]])
	var per := {}
	for f in frames:
		per[f[1]] = int(per.get(f[1], 0)) + int(f[0])
	var st: Dictionary = b.load_stats
	var ready: bool = not b.warming
	if st.is_empty():
		pass_all = false
		_say("[load1434] %s FAIL: no sliced build recorded (warming %s after %d ms)" % [tag, b.warming, Time.get_ticks_msec() - w0])
	else:
		var slice_ok: bool = int(st["worst_stretch"]) / 1000 < LIMIT_MS
		var cover_ok: bool = worst / 1000 < LIMIT_MS
		var ok: bool = slice_ok and ready and cover_ok
		pass_all = pass_all and ok
		_say("[load1434] %s %s (slice %s, ready %s, cover %s)" % [tag, "PASS" if ok else "FAIL", "PASS" if slice_ok else "FAIL",
			"PASS" if ready else "FAIL (timed out still warming)", "PASS" if cover_ok else "FAIL"])
		_say("[load1434] %s: %d ships in %d ms over %d frames; longest build stretch %d ms; worst ship setup %d ms (%s), worst effects registration %d ms; waiting on hull files %d ms; scene ready %d ms; worst frame cover to play %d ms; to play %d ms" % [
			tag, st["ships"], st["ms"], st["frames"], int(st["worst_stretch"]) / 1000,
			int(st["worst_setup"]) / 1000, st["worst_code"], int(st["worst_fx"]) / 1000, int(st["wait"]) / 1000, ready_ms,
			worst / 1000, Time.get_ticks_msec() - w0])
	_say("[load1434] %s cover frames: worst %s; time by phase %s" % [tag, ", ".join(top), str(per)])
	if not st.is_empty():
		_say("[load1434] %s worst ship %s setup stages (us) %s; worst effects registration %s parts (us) %s" % [tag, st.get("worst_code", ""),
			str(st.get("worst_stages", {})), st.get("worst_fx_code", ""), str(st.get("worst_fx_parts", {}))])
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
	var click_ms := -1        # -1: never clicked while building; -2: clicked, drawer never opened
	var click_t := -1
	var link: Button = _find_button(m.title, "Settings")
	while (m.showcase == null or not is_instance_valid(m.showcase) or not m.showcase.showcase_ready) and Time.get_ticks_msec() - w0 < 240000:
		if click_t < 0 and link != null and m.showcase != null and is_instance_valid(m.showcase) and m.showcase.api != null and m.showcase.load_stats.is_empty():
			# the backdrop has its fleet and is building ships now: click the menu like a player
			click_t = Time.get_ticks_msec()
			_click(link.get_global_rect().get_center())
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		if _bus() != before: moved.append(_bus())
		if click_t >= 0 and click_ms == -1 and m.title.settings_panel != null:
			click_ms = Time.get_ticks_msec() - click_t
	if click_t >= 0 and click_ms == -1:
		click_ms = -2
	var sc = m.showcase
	var ready: bool = sc != null and is_instance_valid(sc) and sc.showcase_ready
	var st: Dictionary = sc.load_stats if sc != null and is_instance_valid(sc) else {}
	for i in 60:
		await process_frame
		if _bus() != before: moved.append(_bus())
	if m.title != null and m.title.settings_panel != null:
		m.title._close_settings()
	m._clear()   # leaving the title: stop_build, then free
	for i in 30:
		await process_frame
		if _bus() != before: moved.append(_bus())
	var slice_ok: bool = not st.is_empty() and int(st["worst_stretch"]) / 1000 < LIMIT_MS
	var click_ok: bool = click_ms >= 0 and click_ms < LIMIT_MS
	var ok: bool = slice_ok and ready and click_ok and moved.is_empty()
	pass_all = pass_all and ok
	_say("[load1434] title %s (slice %s, ready %s, click %s, bus %s)" % ["PASS" if ok else "FAIL", "PASS" if slice_ok else "FAIL",
		"PASS" if ready else "FAIL (timed out)", ("PASS (%d ms)" % click_ms) if click_ok else ("FAIL (%s)" % ("no click while building" if click_ms == -1 else "drawer never opened" if click_ms == -2 else "%d ms" % click_ms)),
		"PASS" if moved.is_empty() else "FAIL"])
	_say("[load1434] title: backdrop %s; longest build stretch %d ms; worst frame while it built %d ms; backdrop ready after %d ms; sfx bus %s before, %s" % [
		"%d ships" % st["ships"] if not st.is_empty() else "never built", int(st.get("worst_stretch", 0)) / 1000,
		worst / 1000, Time.get_ticks_msec() - w0, before, "never moved" if moved.is_empty() else "moved to %s" % [moved.slice(0, 3)]])
	m.queue_free()
	for i in 10:
		await process_frame


func _find_button(n: Node, text: String) -> Button:
	if n == null:
		return null
	if n is Button and (n as Button).text.strip_edges().to_lower() == text.to_lower() and (n as Button).is_visible_in_tree():
		return n
	for c in n.get_children():
		var r := _find_button(c, text)
		if r != null:
			return r
	return null


func _click(at: Vector2) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = at
	mv.global_position = at
	root.push_input(mv)
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		root.push_input(e)


# leave: a cold title, then New run (main.new_run, what the button calls) while the backdrop is still building, ideally
# with a kit hull instance in flight on a worker (Artoo on PR 1445). Graded: the backdrop battle's own _exit_tree on the
# main thread under 100 ms (it hands running work on instead of waiting). Reported: the whole transition through the next
# painted frame, which includes the campaign's own start.
func _leave() -> void:
	var m = MainScript.new()
	root.add_child(m)
	var w0 := Time.get_ticks_msec()
	var in_flight := false
	while Time.get_ticks_msec() - w0 < 240000:
		await process_frame
		var sc = m.showcase
		if sc == null or not is_instance_valid(sc) or sc.api == null:
			continue
		if not sc.load_stats.is_empty() or sc.showcase_ready:
			break
		if not sc._inst_tasks.is_empty():
			in_flight = true
			break
	var building: bool = m.showcase != null and is_instance_valid(m.showcase) and m.showcase.load_stats.is_empty()
	var t0 := Time.get_ticks_usec()
	m.new_run()
	await RenderingServer.frame_post_draw
	var total_ms := (Time.get_ticks_usec() - t0) / 1000
	for i in 3:
		await process_frame
	var BS = load("res://scenes/battle/battle.gd")
	var exit_ms: int = int(BS.last_exit_us) / 1000
	var ok: bool = building and exit_ms < 100
	pass_all = pass_all and ok
	_say("[load1434] leave %s: New run clicked %s (a kit instance on a worker %s); backdrop exit %d ms on the main thread (limit 100); title to next painted frame %d ms (includes the campaign's own start); work handed on %d" % [
		"PASS" if ok else "FAIL", "while the backdrop was building" if building else "after the backdrop finished (not a valid test)",
		"in flight" if in_flight else "not caught in flight", exit_ms, total_ms, load("res://render/ship_view.gd").retired_build_count()])
	m.queue_free()
	for i in 30:
		await process_frame


func _run() -> void:
	_say("[load1434] display %s, window %s, renderer %s" % [DisplayServer.get_name(), str(root.get_visible_rect().size), RenderingServer.get_current_rendering_method()])
	if "s25" in cases: await _battle("s25", {"scenario": "s25"})
	if "title" in cases: await _title()
	if "leave" in cases: await _leave()
	if "b1" in cases: await _battle("b1", {"seed": 101})
	if "b2" in cases: await _battle("b2", {"seed": 202})
	if "b3" in cases: await _battle("b3", {"seed": 303})
	_say("[load1434] RESULT %s (limit %d ms for each graded item: slice, ready, cover frame, title click, bus)" % ["PASS" if pass_all else "FAIL", LIMIT_MS])
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var f := FileAccess.open(out_dir.path_join("load_result.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines) + "\n")
			f.close()
	quit(0 if pass_all else 1)
