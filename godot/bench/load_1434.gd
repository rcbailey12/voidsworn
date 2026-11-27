extends SceneTree
# Issue 1434 PC proof: the battle's ships are built a few per frame under the loading cover, and the title backdrop
# builds behind a menu that keeps answering, without touching the sound volume.
# Cases, in this order, in one windowed process on the real renderer and the real hulls:
#   s25        the 24-unit scenario, first so its hull files load cold
#   title      main.gd's title with its backdrop at sound volume 0.25: worst frame while it builds, and the shared sfx bus
#              read every frame from before the backdrop starts until it is freed (must not move)
#   leave      a second cold title, New run clicked while its backdrop builds
#   b1, b2, b3 three default sector 1 fights (start_default, seeds 101, 202, 303), the shape of Battles 1 to 3
#   s25r       the 24-ship battle again in the same process, every shader and pipeline it uses already made (reported
#              only, issue 1434 LOAD19: if its 5 s hull-prep draw comes back, first-use compiling is not the cause)
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
const BAKER = preload("res://world/world_bake.gd")
const HULL = preload("res://fx/fx_hull.gd")
const SKEEP = preload("res://render/shader_keep.gd")


func _stage_name(w: int) -> String:
	return ["idle", "disk check", "compute", "png save", "prune", "mips"][w] if w >= 0 and w < 6 else str(w)
const LIMIT_MS := 500
var out_dir := ""
var lines: Array = []
var pass_all := true
var finished: Array = []   # each case adds its name as its last step, so a case cut short by a script error fails the run
var cases := PackedStringArray(["s25", "title", "leave", "b1", "b2", "b3", "b2r", "s25r"])
# Board, Nov 21 (LOAD10): graded on a warm profile (the player's second launch onward: Godot's shader and pipeline caches
# and the world bakes already on disk), with the cold first launch reported alongside on the same items. --pass names
# which this run is; the runner (load1434_runs.ps1) starts the bench twice on one profile, cold then warm.
var pass_name := "one"
# The cold condition (Board): the first launch must still show the loading cover while shaders compile, never a blank
# or stalled window. Every frame from the cover to play must have the cover up, and no frame may reach 5 s (Windows
# marks a window that has not answered for 5 s as not responding).
const STALL_MS := 5000
var cover_ok_all := true
var cover_notes: Array = []


# issue 1434 (Board on LOAD13): each frame's wall time split into the renderer's draw (frame_pre_draw to frame_post_draw)
# and everything before it on the main thread (scripts, physics, waits), plus the effects work it named (fx.prof)
var _pre_us := 0
var _draw_us := 0


# the node whose hull-prep step a frame row names: read at frame_pre_draw, the step the draw that follows belongs to
# (Artoo on PR 1445: a label read after the frame could already name the next step)
var _watch: Node = null
var _draw_step := ""


var _draw_ins := {}   # hull-prep installs before the draws of this row
# issue 1434 (LOAD20: 83 pipelines in one hull-prep draw, no install named): the meshes added to the tree before the
# draws of this row, by name without its digits and its parent's, and the texture and buffer memory at each row
var _nodes_now := {}
var _draw_nodes := {}
var _mem_last := -1.0
var _digits := RegEx.create_from_string("[0-9@]+")


func _on_node_added(n: Node) -> void:
	if n is GeometryInstance3D:
		var p := n.get_parent()
		var g := p.get_parent() if p != null else null
		# LOAD23 (cold s25: 7 meshes under an unnamed node in the cuts frame, 83 pipelines): the grandparent and the script
		# line that added the mesh (a debug build's stack), so the row names who adds it
		var key := "%s<%s<%s" % [_digits.sub(str(n.name), "", true), _digits.sub(str(p.name), "", true) if p != null else "-", _digits.sub(str(g.name), "", true) if g != null else "-"]
		for fr in get_stack():
			var src := str(fr.get("source", ""))
			if src != "" and not src.ends_with("load_1434.gd"):
				key += " @%s:%d" % [src.get_file(), int(fr.get("line", 0))]
				break
		_nodes_now[key] = int(_nodes_now.get(key, 0)) + 1


func _nodes_take() -> String:
	var keys := _draw_nodes.keys()
	if keys.is_empty():
		return "-"
	var total := 0
	for k in keys: total += int(_draw_nodes[k])
	keys.sort_custom(func(x, y): return int(_draw_nodes[x]) > int(_draw_nodes[y]))
	var out := PackedStringArray()
	for k in keys.slice(0, 5): out.append("%s x%d" % [str(k), int(_draw_nodes[k])])
	_draw_nodes = {}
	return "%d: %s" % [total, ", ".join(out)]


func _mem_take() -> String:
	var m := (Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) + Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)) / 1048576.0
	var d := m - _mem_last if _mem_last >= 0.0 else 0.0
	_mem_last = m
	return "%+.0f MB" % d
var _draw_made: Array = []   # new shaders before the draws of this row
var _draw_pipes := {}   # pipelines inside the draws of this row, by source
var _pipe_at_pre := {}


func _on_pre_draw() -> void:
	_pre_us = Time.get_ticks_usec()
	_pipe_at_pre = _pipe_counts()
	if _watch != null and is_instance_valid(_watch):
		var fx = _watch.get("gfx")
		if fx != null and is_instance_valid(fx) and str(fx.get("prep_step")) != "" and fx.get("prep_step") != null:
			var st := str(fx.get("prep_step"))
			if not _draw_step.contains(st):
				_draw_step = st if _draw_step == "" else _draw_step + " + " + st
		# Artoo on PR 1445 (LOAD18): the installs and new shaders made before this draw, taken here so a later
		# coroutine step cannot add to them before the row is written
		if fx != null and is_instance_valid(fx) and fx.has_method("installs_take"):
			var d: Dictionary = fx.installs_take()
			for k in d: _draw_ins[k] = int(_draw_ins.get(k, 0)) + int(d[k])
	_draw_made.append_array(SKEEP.made)
	SKEEP.made.clear()
	for k in _nodes_now: _draw_nodes[k] = int(_draw_nodes.get(k, 0)) + int(_nodes_now[k])
	_nodes_now = {}


func _on_post_draw() -> void:
	if _pre_us > 0:
		_draw_us += Time.get_ticks_usec() - _pre_us
		# the pipelines counted from this draw's start to its end, by source
		var now := _pipe_counts()
		for k in now: _draw_pipes[k] = int(_draw_pipes.get(k, 0)) + int(now[k]) - int(_pipe_at_pre.get(k, now[k]))
	_pre_us = 0


func _take_draw() -> float:
	var d := _draw_us / 1000.0
	_draw_us = 0
	return d


# the three biggest named effects costs since the last frame, "prep:shield 210 ms, ..." ("-" when none)
func _fx_work(node) -> String:
	if node == null or not is_instance_valid(node):
		return "-"
	var fx = node.get("gfx")
	if fx == null or not is_instance_valid(fx) or not fx.has_method("prof_take"):
		return "-"
	var step := _draw_step
	_draw_step = ""
	var p: Dictionary = fx.prof_take()
	var keys := p.keys()
	keys.sort_custom(func(x, y): return int(p[x]) > int(p[y]))
	var out := PackedStringArray()
	for k in keys.slice(0, 3):
		if int(p[k]) >= 1000:
			out.append("%s %d ms" % [str(k), int(p[k]) / 1000])
	var said := ", ".join(out) if not out.is_empty() else "-"
	# issue 1434 (LOAD17): what hull prep installed before this row's draws (taken at frame_pre_draw)
	var ins := PackedStringArray()
	for k in _draw_ins: ins.append("%s %d" % [str(k), int(_draw_ins[k])])
	_draw_ins = {}
	return said + (" (hull prep step at the draw: %s)" % step if step != "" else "") + (", installed before the draw: " + ", ".join(ins) if not ins.is_empty() else "") + _reads_note(node)


# issue 1434 (LOAD30d): the battle's hull reads that finished since the last row (", hull reads finished 3 of 8")
var _reads_seen := {}


func _reads_note(node) -> String:
	if node == null or not is_instance_valid(node) or not node.has_method("hull_reads_done"):
		return ""
	var id: int = node.get_instance_id()
	var done: int = node.hull_reads_done()
	var was: int = int(_reads_seen.get(id, 0))
	_reads_seen[id] = done
	var total: int = (node.get("_preload") as Dictionary).size() if node.get("_preload") is Dictionary else 0
	return ", hull reads finished %d of %d" % [done - was, total] if done > was else ""


# Performance.TIME_PROCESS read after a frame's await is the step before it (the battle's coroutine runs ahead of the
# bench in the same signal), so each row takes the process time read on the row after it
static func _shift_process(fs: Array) -> void:
	for i in fs.size():
		fs[i][6] = fs[i + 1][6] if i + 1 < fs.size() else -1.0


func _init() -> void:
	HULL.late_stacks = true
	SKEEP.watch = true
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)
	node_added.connect(_on_node_added)
	var a := OS.get_cmdline_user_args()
	var i := a.find("--out")
	if i >= 0 and i + 1 < a.size():
		out_dir = a[i + 1]
	var pn := a.find("--pass")
	if pn >= 0 and pn + 1 < a.size():
		pass_name = a[pn + 1]
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


# issue 1434 (Astra on LOAD17, issue 1573: is the 83-pipeline draw blocking pipeline creation?): the count by source since
# the last call, "draw 80, surface 3" ("-" when none). Godot counts a pipeline built at draw time under "draw"; "surface"
# and "mesh" ones are made ahead of the draw, "specialization" ones in the background
const PIPE_SOURCES := ["CANVAS", "MESH", "SURFACE", "DRAW", "SPECIALIZATION"]


func _pipe_counts() -> Dictionary:
	var d := {}
	for src in PIPE_SOURCES:
		var m: String = "PIPELINE_COMPILATIONS_" + src
		if ClassDB.class_has_integer_constant("Performance", m):
			d[src] = int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return d


# the pipelines counted inside this row's draws by source, "draw 80, surface 3" ("-" when none). A count, not a time:
# how long creation took needs a trace (Artoo on PR 1445)
func _pipes_by() -> String:
	var out := PackedStringArray()
	for src in PIPE_SOURCES:
		if int(_draw_pipes.get(src, 0)) > 0: out.append("%s %d" % [src.to_lower(), int(_draw_pipes[src])])
	_draw_pipes = {}
	return ", ".join(out) if not out.is_empty() else "-"


# the new shaders made before this row's draws (taken at frame_pre_draw)
func _made_take() -> String:
	var n := _draw_made.size()
	if n == 0:
		return "-"
	var said := ", ".join(PackedStringArray(_draw_made.slice(0, 6))) + (" and %d more" % (n - 6) if n > 6 else "")
	_draw_made = []
	return "%d: %s" % [n, said]


# one line per recorded frame: where its wall-clock time went
func _split(fs: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for f in fs:
		out.append("%d ms %s (began at %d ms): draw %.0f ms, before the draw %.0f ms (process step %.0f ms), render cpu %.0f ms, gpu %.0f ms, %d pipelines compiled, %d world bakes pending" % [
			f[0], f[1], f[7], f[9], maxf(0.0, float(f[0]) - float(f[9])), f[6], f[2], f[3], f[4], f[5]] + (" (inside the draw by source: %s)" % f[11]) + (", bake worker %s" % f[8]) + (", effects work %s" % f[10]) + (", new shaders %s" % f[12]) + (", meshes added %s, texture and buffer memory %s" % [f[13], f[14]]))
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
	_watch = b
	_draw_step = ""
	var ready_ms := (Time.get_ticks_usec() - t0) / 1000
	var worst := 0
	# [ms, phase before -> phase after, render cpu ms, gpu ms, pipelines compiled, world bakes pending] per frame under
	# the cover (LOAD5: the long "world" frames were not script time the bench could name; this splits them)
	var frames: Array = []
	_take_draw()
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var pipes0 := _pipes()
	_pipes_by()
	SKEEP.made.clear()
	_draw_made = []
	_draw_ins = {}
	_nodes_now = {}
	_draw_nodes = {}
	_mem_take()
	var gaps := 0
	var stalls := 0
	while (b.warming or b.load_stats.is_empty()) and Time.get_ticks_msec() - w0 < 240000:
		var ph0: String = b.load_phase
		var ws0: int = BAKER.work_stage
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		if b.warming:
			var cv = b.hud.load_cover if b.hud != null else null
			if cv == null or not is_instance_valid(cv) or not (cv as CanvasItem).is_visible_in_tree():
				gaps += 1
		if (now - last) / 1000 >= STALL_MS:
			stalls += 1
		var pipes := _pipes()
		var bakes: int = int(b.world.pending_bakes) if b.world != null and is_instance_valid(b.world) else -1
		frames.append([(now - last) / 1000, ph0 if ph0 == b.load_phase else "%s->%s" % [ph0, b.load_phase],
			RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(vp_rid), pipes - pipes0, bakes,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, last / 1000, _stage_name(ws0) + " -> " + _stage_name(BAKER.work_stage),
			_take_draw(), _fx_work(b), _pipes_by(), _made_take(), _nodes_take(), _mem_take()])
		pipes0 = pipes
		last = now
	_shift_process(frames)
	if OS.has_environment("VS_LOAD_ALL_ROWS"):   # a cloud trial: every row from the hull prep on, in order
		var from := -1
		for i in frames.size():
			if from < 0 and str(frames[i][1]).contains("prepare_hulls"): from = i
		if from >= 0:
			for r in _split(frames.slice(from)): print("[load1434] %s row: %s" % [tag, r])
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
	_cover_note(tag, gaps, stalls, worst / 1000)
	_say("[load1434] %s worst cover frames split: %s" % [tag, "; ".join(split)])
	if not st.is_empty():
		_say("[load1434] %s worst ship %s setup stages (us) %s; worst effects registration %s parts (us) %s; worst hull geometry %d ms (%s)" % [tag, st.get("worst_code", ""),
			str(st.get("worst_stages", {})), st.get("worst_fx_code", ""), str(st.get("worst_fx_parts", {})),
			int(st.get("worst_geo", 0)) / 1000, str(st.get("worst_geo_code", "-"))])
		_say("[load1434] %s start to board parts (us) %s" % [tag, str(b.begin_us)])
	b.queue_free()
	for i in 30:
		await process_frame
	finished.append(tag)


func _cover_note(tag: String, gaps: int, stalls: int, worst_ms: int) -> void:
	var ok := gaps == 0 and stalls == 0
	cover_ok_all = cover_ok_all and ok
	cover_notes.append("%s %s" % [tag, "ok" if ok else "FAIL"])
	_say("[load1434] %s cover check %s: %d frames without the cover before play, %d frames of %d s or more (worst %d ms)" % [
		tag, "PASS" if ok else "FAIL", gaps, stalls, STALL_MS / 1000, worst_ms])


func _title() -> void:
	var m = MainScript.new()
	var tw := Time.get_ticks_msec()
	root.add_child(m)
	# issue 1518 (Artoo on PR 1445, 6784b6b1): the title waits a frame at a time for the launch's campaign host read, so
	# the time from the new Main to its first painted menu is its own line, and no menu in 20 s fails the title plainly
	while (m.title == null or not is_instance_valid(m.title)) and Time.get_ticks_msec() - tw < 20000:
		await process_frame
	if m.title == null or not is_instance_valid(m.title):
		pass_all = false
		_say("[load1434] title FAIL (no menu painted 20 s after the new Main)")
		m.queue_free()
		for i in 10:
			await process_frame
		finished.append("title")
		return
	await RenderingServer.frame_post_draw
	_say("[load1434] title launch to first painted menu: %d ms (first button: %s)" % [Time.get_ticks_msec() - tw, str(m.title.get("first_label"))])
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
	_pipes_by()
	SKEEP.made.clear()
	_draw_made = []
	_draw_ins = {}
	_nodes_now = {}
	_draw_nodes = {}
	_mem_take()
	_take_draw()
	var last := Time.get_ticks_usec()
	var w0 := Time.get_ticks_msec()
	var click_ms := -1        # -1: never clicked while building; -2: clicked, drawer never opened
	var click_t := -1
	var begin_seen := {}
	var link: Button = _find_button(m.title, "Settings")
	while (m.showcase == null or not is_instance_valid(m.showcase) or not m.showcase.showcase_ready) and Time.get_ticks_msec() - w0 < 240000:
		if click_t < 0 and link != null and m.showcase != null and is_instance_valid(m.showcase) and m.showcase.api != null and m.showcase.load_stats.is_empty():
			# the backdrop has its fleet and is building ships now: click the menu like a player
			click_t = Time.get_ticks_msec()
			_click(link.get_global_rect().get_center())
		var sc0 = m.showcase
		_watch = sc0
		var ph0: String = sc0.load_phase if sc0 != null and is_instance_valid(sc0) else "none"
		var ws0: int = BAKER.work_stage
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		var sc1 = m.showcase
		if sc1 != null and is_instance_valid(sc1) and not (sc1.begin_us as Dictionary).is_empty():
			begin_seen = (sc1.begin_us as Dictionary).duplicate()   # LOAD29: the backdrop may be gone by the report
		var ph1: String = sc1.load_phase if sc1 != null and is_instance_valid(sc1) else "none"
		var pipes := _pipes()
		var bakes: int = int(sc1.world.pending_bakes) if sc1 != null and is_instance_valid(sc1) and sc1.world != null and is_instance_valid(sc1.world) else -1
		frames.append([(now - last) / 1000, ph0 if ph0 == ph1 else "%s->%s" % [ph0, ph1],
			RenderingServer.viewport_get_measured_render_time_cpu(vp_rid) + RenderingServer.get_frame_setup_time_cpu(),
			RenderingServer.viewport_get_measured_render_time_gpu(vp_rid), pipes - pipes0, bakes,
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, last / 1000, _stage_name(ws0) + " -> " + _stage_name(BAKER.work_stage),
			_take_draw(), _fx_work(sc1), _pipes_by(), _made_take(), _nodes_take(), _mem_take()])
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
	var stalls := 0
	for f in frames:
		if int(f[0]) >= STALL_MS: stalls += 1
	_cover_note("title", 0, stalls, worst / 1000)   # the title has no cover: its menu stays drawn, so only stalls count
	_shift_process(frames)
	frames.sort_custom(func(x, y): return x[0] > y[0])
	_say("[load1434] title worst frames split: %s" % "; ".join(_split(frames.slice(0, 5))))
	_say("[load1434] title: backdrop %s; longest build stretch %d ms; worst frame while it built %d ms; backdrop ready after %d ms; sfx bus %s before, %s" % [
		"%d ships" % st["ships"] if not st.is_empty() else "never built", int(st.get("worst_stretch", 0)) / 1000,
		worst / 1000, Time.get_ticks_msec() - w0, before, "never moved" if moved.is_empty() else "moved to %s" % [moved.slice(0, 3)]])
	_say("[load1434] title start to board parts (us) %s" % str(begin_seen))
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
	var keep_cover := cover_ok_all
	await _battle("b2r", {"seed": 202})
	cover_ok_all = keep_cover
	_say("[load1434] b2r is reported only (bakes again, shaders warm): its FAIL or PASS above does not count toward RESULT")
	pass_all = keep
	cover_notes[-1] = "b2r reported only"
	# the folder stays: bakes still running would write into it; it lives in this run's own throwaway Godot profile


# the bakes made during loads write their PNGs once nothing loads: wait for them, so the next (warm) launch on this
# profile finds them on disk; run before b2r too, so its folder switch cannot meet a pending normal write
func _drain(label: String) -> void:
	var svc = root.get_node_or_null("WorldBakes")
	var sw0 := Time.get_ticks_msec()
	var sworst := 0
	var slast := Time.get_ticks_usec()
	while svc != null and bool(svc.busy_status()["busy"]) and Time.get_ticks_msec() - sw0 < 180000:
		await process_frame
		var now := Time.get_ticks_usec()
		sworst = maxi(sworst, now - slast)
		slast = now
	# Artoo on PR 1445: count the writes that saved, not an empty queue
	var st: Dictionary = svc.busy_status() if svc != null else {}
	_say("[load1434] world bake writes %s: %s in %d ms, worst frame meanwhile %d ms (reported only)" % [
		label, "no bake service" if svc == null else "%d written, %d failed, %d still queued%s" % [svc.written, svc.write_failed, int(st["unsaved"]),
			", one still being written" if bool(st["saving"]) else ""], Time.get_ticks_msec() - sw0, sworst / 1000])


# issue 1434 (LOAD19: the warm profile still paid 5 s for 83 pipelines): the shader codes this launch made through
# render/shader_keep.gd, against the ones the last launch on this profile made. A code new on the warm launch changes
# from launch to launch, so its shader and pipelines never come from the disk caches.
const CODES_FILE := "user://load1434_codes_seen.txt"


func _codes_since_last_launch() -> void:
	var before := {}
	if FileAccess.file_exists(CODES_FILE):
		for line in FileAccess.get_file_as_string(CODES_FILE).split("\n", false):
			before[line.get_slice(" ", 0)] = true
	var fresh := PackedStringArray()
	var out := PackedStringArray()
	for h in SKEEP.seen:
		out.append("%s %s" % [h, SKEEP.seen[h]])
		if not before.is_empty() and not before.has(h):
			fresh.append("%s %s" % [SKEEP.seen[h], h])
	var f := FileAccess.open(CODES_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(out) + "\n")
		f.close()
	if before.is_empty():
		_say("[load1434] shader codes: %d made this launch; no earlier launch on this profile to compare (reported only)" % SKEEP.seen.size())
	else:
		_say("[load1434] shader codes: %d made this launch, %d not made by the last launch on this profile%s (reported only)" % [
			SKEEP.seen.size(), fresh.size(), (": " + ", ".join(fresh.slice(0, 20))) if not fresh.is_empty() else ""])


# the disk caches this launch starts with (issue 1434 LOAD19: does the warm launch find the pipeline cache)
func _caches_at_start() -> String:
	var out := PackedStringArray()
	for sub in ["vulkan", "shader_cache"]:
		var n := 0
		var bytes := 0
		var stack: Array = [OS.get_user_data_dir().path_join(sub)]
		while not stack.is_empty():
			var d: String = stack.pop_back()
			var da := DirAccess.open(d)
			if da == null:
				continue
			for f in da.get_files():
				n += 1
				var fa := FileAccess.open(d.path_join(f), FileAccess.READ)
				if fa != null:
					bytes += fa.get_length()
					fa.close()
			for sd in da.get_directories():
				stack.append(d.path_join(sd))
		out.append("%s %d files %.1f MB" % [sub, n, bytes / 1048576.0])
	out.append("pipeline cache setting %s" % str(ProjectSettings.get_setting("rendering/rendering_device/pipeline_cache/enable", "unset")))
	return ", ".join(out)


func _run() -> void:
	_say("[load1434] display %s, window %s, renderer %s" % [DisplayServer.get_name(), str(root.get_visible_rect().size), RenderingServer.get_current_rendering_method()])
	_say("[load1434] caches at start: " + _caches_at_start())
	if "s25" in cases: await _battle("s25", {"scenario": "s25"})
	if "title" in cases: await _title()
	if "leave" in cases: await _leave()
	if "b1" in cases: await _battle("b1", {"seed": 101})
	if "b2" in cases: await _battle("b2", {"seed": 202})
	if "b3" in cases: await _battle("b3", {"seed": 303})
	if "b2r" in cases:
		await _drain("before b2r")
		await _b2_again()
	if "s25r" in cases:
		var keep := pass_all
		var keep_cover := cover_ok_all
		await _battle("s25r", {"scenario": "s25"})
		cover_ok_all = keep_cover
		pass_all = keep
		cover_notes[-1] = "s25r reported only"
		_say("[load1434] s25r is reported only (the 24-ship battle again, every shader and pipeline already made this launch): its FAIL or PASS above does not count toward RESULT")
	_codes_since_last_launch()
	for c in cases:
		if not c in finished:
			pass_all = false
			_say("[load1434] %s FAIL: the case stopped before its end (see the script error above)" % c)
	await _drain("after the loads")
	_say("[load1434] COVER %s on the %s profile (the loading cover up on every frame to play and no frame of %d s or more: %s)" % [
		"PASS" if cover_ok_all else "FAIL", pass_name, STALL_MS / 1000, ", ".join(cover_notes)])
	_say("[load1434] RESULT %s on the %s profile (limit %d ms for each graded item: slice, ready, cover frame, title click, title frame, bus; leave exit limit 100 ms; graded on the warm profile, the cold one reported with its COVER line, Board Nov 21)" % ["PASS" if pass_all else "FAIL", pass_name, LIMIT_MS])
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var f := FileAccess.open(out_dir.path_join("load_result.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines) + "\n")
			f.close()
	quit(0 if pass_all else 1)
