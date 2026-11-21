extends SceneTree
# Issue 1434 PC proof: the battle's ships are built a few per frame under the loading cover, and the title backdrop
# builds behind a menu that keeps answering, without touching the sound volume.
# Cases, in this order, in one windowed process on the real renderer and the real hulls:
#   s25        the 24-unit scenario, first so its hull files load cold
#   title      main.gd's title with its backdrop at sound volume 0.25: worst frame while it builds, and the shared sfx bus
#              read every frame from before the backdrop starts until it is freed (must not move)
#   leave      a second cold title, New run clicked while its backdrop builds
#   b1, b2, b3 three default sector 1 fights (start_default, seeds 101, 202, 303), the shape of Battles 1 to 3
#   b2r        Battle 2 again, its world bakes run again with every shader warm (reported only, see _b2_again)
# Per battle: the longest main-thread stretch of the ship build (battle.gd load_stats: one ship's setup or its effects
# registration at most), the worst single ship's setup and registration, and the worst frame from the cover to play,
# with the load phase of the five worst frames and the time spent in each phase.
# Graded separately (Artoo on PR 1445), every one must hold for PASS:
#   slice   the longest ship build stretch under 500 ms
#   ready   the battle reached play (warming cleared) / the backdrop reached showcase_ready before its time limit
#   cover   the worst frame from the cover to play under 500 ms (it includes the existing shader warm-up)
#   frame   the title's longest wall-clock frame from the backdrop's start to showcase_ready under 500 ms
#   click   the title's Settings link, clicked by a real mouse press and release while the backdrop is still building,
#           opens its drawer within 500 ms
#   bus     the title's shared sfx bus never moved (sound on at 0.25 here; the muted case and 0.25 both run in CI in
#           main/test/showcase_quiet_check.gd)
#   leave   New run clicked (real mouse) while the title backdrop has a load or kit instance pending: that backdrop's exit
#           under 100 ms on the main thread, and the campaign painted; no try caught pending is INCONCLUSIVE, not PASS
# Run: godot --path godot [--fullscreen] --script res://bench/load_1434.gd -- --out <folder>
const BattleScene = preload("res://scenes/battle/battle.tscn")
const MainScript = preload("res://main/main.gd")
const LIMIT_MS := 500
var out_dir := ""
var lines: Array = []
var pass_all := true
var finished: Array = []   # each case adds its name as its last step, so a case cut short by a script error fails the run
var cases := PackedStringArray(["s25", "title", "leave", "b1", "b2", "b3", "b2r"])


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


# pipelines compiled so far (Godot 4.7 Forward+ monitors; 0 where the renderer has none)
func _pipes() -> int:
	var n := 0
	for m in ["PIPELINE_COMPILATIONS_CANVAS", "PIPELINE_COMPILATIONS_MESH", "PIPELINE_COMPILATIONS_SURFACE", "PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if ClassDB.class_has_integer_constant("Performance", m):
			n += int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return n


# one line per recorded frame: where its wall-clock time went
func _split(fs: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for f in fs:
		out.append("%d ms %s (began at %d ms): render cpu %.0f ms, gpu %.0f ms, rest %.0f ms of which the process step %.0f ms, %d pipelines compiled, %d world bakes pending" % [
			f[0], f[1], f[7], f[2], f[3], maxf(0.0, float(f[0]) - float(f[2])), f[6], f[4], f[5]])
	return out


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
	# [ms, phase before -> phase after, render cpu ms, gpu ms, pipelines compiled, world bakes pending] per frame under
	# the cover (LOAD5: the long "world" frames were not script time the bench could name; this splits them)
	var frames: Array = []
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var pipes0 := _pipes()
	while (b.warming or b.load_stats.is_empty()) and Time.get_ticks_msec() - w0 < 240000:
		var ph0: String = b.load_phase
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		var pipes := _pipes()
		var bakes: int = int(b.world.pending_bakes) if b.world != null and is_instance_valid(b.world) else -1
		frames.append([(now - last) / 1000, ph0 if ph0 == b.load_phase else "%s->%s" % [ph0, b.load_phase],
			RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(vp_rid), pipes - pipes0, bakes,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, last / 1000])
		pipes0 = pipes
		last = now
	frames.sort_custom(func(x, y): return x[0] > y[0])
	var top := PackedStringArray()
	for f in frames.slice(0, 5):
		top.append("%d ms %s" % [f[0], f[1]])
	var split := _split(frames.slice(0, 5))
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
	_say("[load1434] %s worst cover frames split: %s" % [tag, "; ".join(split)])
	if not st.is_empty():
		_say("[load1434] %s worst ship %s setup stages (us) %s; worst effects registration %s parts (us) %s; worst hull geometry %d ms (%s)" % [tag, st.get("worst_code", ""),
			str(st.get("worst_stages", {})), st.get("worst_fx_code", ""), str(st.get("worst_fx_parts", {})),
			int(st.get("worst_geo", 0)) / 1000, str(st.get("worst_geo_code", "-"))])
	b.queue_free()
	for i in 30:
		await process_frame
	finished.append(tag)


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
	var frames: Array = []   # as _battle: [ms, phase, render cpu ms, gpu ms, pipelines compiled, world bakes pending]
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var pipes0 := _pipes()
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
		var sc0 = m.showcase
		var ph0: String = sc0.load_phase if sc0 != null and is_instance_valid(sc0) else "none"
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		var sc1 = m.showcase
		var ph1: String = sc1.load_phase if sc1 != null and is_instance_valid(sc1) else "none"
		var pipes := _pipes()
		var bakes: int = int(sc1.world.pending_bakes) if sc1 != null and is_instance_valid(sc1) and sc1.world != null and is_instance_valid(sc1.world) else -1
		frames.append([(now - last) / 1000, ph0 if ph0 == ph1 else "%s->%s" % [ph0, ph1],
			RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(vp_rid), pipes - pipes0, bakes,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, last / 1000])
		pipes0 = pipes
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
	# Artoo on PR 1445: a quick click does not prove the menu never froze (LOAD5: click 16 ms, one frame 7.9 s), so the
	# longest wall-clock frame from the backdrop's start to showcase_ready is graded too, with its renderer split
	var frame_ok: bool = worst / 1000 < LIMIT_MS
	var ok: bool = slice_ok and ready and click_ok and frame_ok and moved.is_empty()
	pass_all = pass_all and ok
	_say("[load1434] title %s (slice %s, ready %s, click %s, frame %s, bus %s)" % ["PASS" if ok else "FAIL", "PASS" if slice_ok else "FAIL",
		"PASS" if ready else "FAIL (timed out)", ("PASS (%d ms)" % click_ms) if click_ok else ("FAIL (%s)" % ("no click while building" if click_ms == -1 else "drawer never opened" if click_ms == -2 else "%d ms" % click_ms)),
		("PASS (%d ms)" % (worst / 1000)) if frame_ok else ("FAIL (%d ms)" % (worst / 1000)), "PASS" if moved.is_empty() else "FAIL"])
	frames.sort_custom(func(x, y): return x[0] > y[0])
	_say("[load1434] title worst frames split: %s" % "; ".join(_split(frames.slice(0, 5))))
	_say("[load1434] title: backdrop %s; longest build stretch %d ms; worst frame while it built %d ms; backdrop ready after %d ms; sfx bus %s before, %s" % [
		"%d ships" % st["ships"] if not st.is_empty() else "never built", int(st.get("worst_stretch", 0)) / 1000,
		worst / 1000, Time.get_ticks_msec() - w0, before, "never moved" if moved.is_empty() else "moved to %s" % [moved.slice(0, 3)]])
	m.queue_free()
	for i in 10:
		await process_frame
	finished.append("title")


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


# leave: a fresh title, then its New run button clicked by a real mouse press and release while the backdrop is still
# building, with a hull load or a kit hull instance still running (Artoo on PR 1445). Up to LEAVE_TRIES titles are tried
# until one is caught with that work pending. Graded on that attempt only: the exit record must be that same backdrop
# (its instance id), it must have left work pending, and its _exit_tree on the main thread must be under 100 ms. If no
# attempt catches work pending, the case is INCONCLUSIVE and the run does not pass. Reported for the same attempt: click
# to the first painted frame with the campaign in the tree, and the worst frame over the next 2 s.
const LEAVE_TRIES := 4


func _pending(sc) -> bool:
	return not sc._inst_tasks.is_empty() or sc._preload.values().has(null)


func _leave() -> void:
	var BS = load("res://scenes/battle/battle.gd")
	var SVs = load("res://render/ship_view.gd")
	var graded := false
	for attempt in range(1, LEAVE_TRIES + 1):
		var m = MainScript.new()
		root.add_child(m)
		var w0 := Time.get_ticks_msec()
		var caught := false
		var sc = null
		while Time.get_ticks_msec() - w0 < 120000:
			await process_frame
			sc = m.showcase
			if sc == null or not is_instance_valid(sc) or sc.api == null:
				continue
			if not sc.load_stats.is_empty() or sc.showcase_ready:
				break
			if _pending(sc):
				caught = true
				break
		if not caught or sc == null or not is_instance_valid(sc):
			_say("[load1434] leave try %d: the backdrop finished before any work could be caught pending; trying a fresh title" % attempt)
			m.queue_free()
			for i in 10:
				await process_frame
			continue
		var sc_id: int = sc.get_instance_id()
		var what := "a kit instance" if not sc._inst_tasks.is_empty() else "a hull load"   # read now: the backdrop is freed after the click
		var btn := _find_button(m, "New run")
		var how := "New run button"
		if btn == null:
			btn = _find_button(m, "Continue run")
			how = "Continue run button"
		var t0 := Time.get_ticks_usec()
		if btn != null:
			_click(btn.get_global_rect().get_center())
		else:
			how = "main.new_run (no button found)"
			m.new_run()
		# the first painted frame with the campaign in the tree
		var first_ms := -1
		var f0 := Time.get_ticks_usec()
		while Time.get_ticks_usec() - f0 < 20000000:
			await RenderingServer.frame_post_draw
			if m.campaign != null and is_instance_valid(m.campaign) and m.campaign.is_inside_tree():
				first_ms = (Time.get_ticks_usec() - t0) / 1000
				break
		var worst := 0
		var last := Time.get_ticks_usec()
		var e0 := last
		while Time.get_ticks_usec() - e0 < 2000000:
			await process_frame
			var now := Time.get_ticks_usec()
			worst = maxi(worst, now - last)
			last = now
		var same: bool = int(BS.last_exit_id) == sc_id
		var mid: bool = same and bool(BS.last_exit_mid_build)
		var exit_ms: int = int(BS.last_exit_us) / 1000
		var shown := "the backdrop's own exit %s" % ("%d ms on the main thread (limit 100)" % exit_ms if same else "never recorded (the last exit was another battle)")
		_say("[load1434] leave try %d: %s clicked with %s pending; %s; it left work %s; click to first campaign frame %s; worst frame over the next 2 s %d ms; work handed on %d" % [
			attempt, how, what, shown,
			"pending (handed on)" if mid else "finished (not a valid test)",
			("%d ms" % first_ms) if first_ms >= 0 else "never (20 s)", worst / 1000, SVs.retired_build_count()])
		if m.campaign != null and is_instance_valid(m.campaign):
			m.campaign.queue_free()
		m.queue_free()
		for i in 30:
			await process_frame
		if mid:
			var ok: bool = exit_ms < 100 and first_ms >= 0
			pass_all = pass_all and ok
			_say("[load1434] leave %s (try %d: exit %d ms, click to first campaign frame %s)" % ["PASS" if ok else "FAIL", attempt, exit_ms,
				("%d ms" % first_ms) if first_ms >= 0 else "never"])
			graded = true
			break
	if not graded:
		pass_all = false
		_say("[load1434] leave INCONCLUSIVE: no try in %d caught the backdrop with a load or kit instance pending, so the hand-off is unproven" % LEAVE_TRIES)
	finished.append("leave")


# b2r (reported, not graded): Battle 2 again in the same process, with its world bakes forced to run again (a fresh
# bake folder and an empty memory cache) while every shader and pipeline it uses is already warm. LOAD6 showed 5 to 10 s
# main-thread frames with bakes pending; if they come back here the bakes cause them, if not the first-use shader work does.
func _b2_again() -> void:
	var Baker = load("res://world/world_bake.gd")
	var fresh := OS.get_user_data_dir().path_join("load1434_b2r_bakes_%d" % OS.get_process_id())
	OS.set_environment("VS_WORLD_CACHE", fresh)
	Baker._cache.clear()
	Baker._textures.clear()
	var keep := pass_all
	await _battle("b2r", {"seed": 202})
	_say("[load1434] b2r is reported only (bakes again, shaders warm): its FAIL or PASS above does not count toward RESULT")
	pass_all = keep
	# the folder stays: bakes still running would write into it; it lives in this run's own throwaway Godot profile


func _run() -> void:
	_say("[load1434] display %s, window %s, renderer %s" % [DisplayServer.get_name(), str(root.get_visible_rect().size), RenderingServer.get_current_rendering_method()])
	if "s25" in cases: await _battle("s25", {"scenario": "s25"})
	if "title" in cases: await _title()
	if "leave" in cases: await _leave()
	if "b1" in cases: await _battle("b1", {"seed": 101})
	if "b2" in cases: await _battle("b2", {"seed": 202})
	if "b3" in cases: await _battle("b3", {"seed": 303})
	if "b2r" in cases: await _b2_again()
	for c in cases:
		if not c in finished:
			pass_all = false
			_say("[load1434] %s FAIL: the case stopped before its end (see the script error above)" % c)
	_say("[load1434] RESULT %s (limit %d ms for each graded item: slice, ready, cover frame, title click, title frame, bus; leave exit limit 100 ms)" % ["PASS" if pass_all else "FAIL", LIMIT_MS])
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var f := FileAccess.open(out_dir.path_join("load_result.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines) + "\n")
			f.close()
	quit(0 if pass_all else 1)
