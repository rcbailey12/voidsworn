extends "res://main/player_path.gd"
# Issue 1439 (Astra items 3 and 6): first-launch cost and graphics memory per stage, measured before any fix.
# Main adds this node for --perf-1439 <folder> (main.gd _ready). It samples every frame: frame time, the five pipeline
# compile counters, video, texture and buffer memory (the three scene_gate.gd monitors) and objects, labelled by stage
# (boot, title, map, loadN, battleN_open for the first 10 s of play, battleN after). Measurement only.
# Two modes:
#   --player-path-seed 10   drives title, map and Battles 1 to 3 with the player path recorder's moves (no recording
#                           checks: any window size, any build). A route that stops early is logged, not a failure.
#   no seed                 the quick battle the other arguments ask for (e.g. --scenario s25, which plays itself),
#                           sampled until it returns to the title.
# Writes <folder>/frames.jsonl (one row per frame), events.jsonl (the recorder's events), summary.json at the end.
# Windows' own dedicated and shared GPU memory is sampled outside the game (contrib/opus/perf_1120_firstlaunch).

const OPEN_S := 10.0
const COMPILES := ["CANVAS", "MESH", "SURFACE", "DRAW", "SPECIALIZATION"]

var out_dir := ""
var frames_file: FileAccess
var quick := false
var stage := "boot"
var stage_rows := {}        # stage -> summary row
var stage_order: Array = []
var last_us := 0
var title_drawn_ms := -1.0
var playable := {}          # battle number -> engine ms when the cover lifted
var play_start_ms := -1.0
var quick_seen_battle := false
var route_note := ""
var finished := false
var n_frames := 0


func start(game: Node) -> void:
	main = game
	headless = DisplayServer.get_name() == "headless"
	out_dir = str(main.args.get("perf-1439", ""))
	if out_dir == "" or out_dir == "true":
		printerr("[perf-1439] FAIL --perf-1439 needs an output folder")
		main.quit_clean(1)
		return
	DirAccess.make_dir_recursive_absolute(out_dir)
	frames_file = FileAccess.open(out_dir.path_join("frames.jsonl"), FileAccess.WRITE)
	report_file = FileAccess.open(out_dir.path_join("events.jsonl"), FileAccess.WRITE)
	if frames_file == null or report_file == null:
		printerr("[perf-1439] FAIL could not write to ", out_dir)
		main.quit_clean(1)
		return
	last_us = Time.get_ticks_usec()
	RenderingServer.frame_post_draw.connect(_drawn)
	var seed := int(main.args.get("player-path-seed", 0))
	quick = seed == 0
	_event("run", {"mode": "quick" if quick else "route", "seed": seed, "pid": OS.get_process_id(), "settings": main.settings,
		"window": DisplayServer.window_get_size(), "viewport": get_viewport().get_visible_rect().size,
		"adapter": RenderingServer.get_video_adapter_name(), "driver": RenderingServer.get_video_adapter_api_version(),
		"method": str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
		"user_data_dir": ProjectSettings.globalize_path("user://"), "engine_ms_at_start": Time.get_ticks_msec(),
		"launch_unix_ms": str(main.args.get("launch-ms", ""))})
	if quick:
		main.quick_battle()
		return
	if not Routes.has(seed):
		_fail("unknown seed, expected 10 or 121")
		return
	route = Routes[seed]
	main.show_title()
	await _pause(1.5)
	if not _press(main.title, "New run"):
		_fail("New run button is unavailable")
		return
	# a cold first launch can take seconds to open the campaign; the recorder's 1 s pause assumes a warm one
	var wait_ms := Time.get_ticks_msec()
	while not is_instance_valid(main.campaign) and Time.get_ticks_msec() - wait_ms < 60000:
		await get_tree().process_frame
	await _pause(1.0)
	var steps := 0
	while steps < 70 and not finished:
		steps += 1
		var host = main.campaign
		if not is_instance_valid(host):
			_fail("the campaign returned to title")
			return
		if is_instance_valid(battle):
			await _play_battle()
			if finished or battle_number == 3 or main.is_queued_for_deletion():
				return
		elif not host.in_battle:
			if not await _campaign_step(host):
				return
		await _pause(0.4)
	_fail("campaign stopped making progress")


func _stage_now() -> String:
	var b = main.battle
	if b != null and is_instance_valid(b):
		var n: int = maxi(battle_number, 1)
		if int(b.pipe_base) < 0:
			return "load%d" % n
		if not playable.has(n):
			playable[n] = Time.get_ticks_msec()
			_event("playable", {"engine_ms": playable[n]})
		quick_seen_battle = true
		return ("battle%d_open" % n) if Time.get_ticks_msec() - float(playable[n]) < OPEN_S * 1000.0 else ("battle%d" % n)
	if main.campaign != null and is_instance_valid(main.campaign):
		return "map"
	if main.title != null and is_instance_valid(main.title):
		return "title"
	return "boot"


func _drawn() -> void:
	if finished:
		return
	if title_drawn_ms < 0.0 and main != null and main.title != null and is_instance_valid(main.title):
		title_drawn_ms = Time.get_ticks_msec()
		_event("title_drawn", {"engine_ms": title_drawn_ms, "unix_ms": _unix_ms()})


# The recorder counts frames at a fixed 30 fps; this run keeps the game's own frame rate, so its limits count real time.
func _frame() -> int:
	return int(Time.get_ticks_msec() * FPS / 1000)


func _unix_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _process(_dt: float) -> void:
	if frames_file == null or finished:
		return
	var now := Time.get_ticks_usec()
	var dt_ms := (now - last_us) / 1000.0
	last_us = now
	stage = _stage_now()
	var row := {"ms": now / 1000.0, "unix_ms": _unix_ms(), "stage": stage, "dt": snappedf(dt_ms, 0.01),
		"vram_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		"texture_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"buffer_mb": snappedf(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, 0.1),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT))}
	for m in COMPILES:
		row["pc_" + m.to_lower()] = int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", "PIPELINE_COMPILATIONS_" + m)))
	frames_file.store_line(JSON.stringify(row))
	n_frames += 1
	_add(row)
	if n_frames % 120 == 0:
		frames_file.flush()
		_write_summary("running")
	if quick and quick_seen_battle and stage == "title":
		_finish("quick battle returned to the title")


func _add(row: Dictionary) -> void:
	var s: String = row.stage
	if not stage_rows.has(s):
		stage_order.append(s)
		var first := {"first_unix_ms": row.unix_ms, "first_ms": row.ms, "frames": 0, "worst_dt": 0.0, "over_100ms": 0}
		for m in COMPILES:
			first["pc_" + m.to_lower() + "_start"] = row["pc_" + m.to_lower()]
		for k in ["vram_mb", "texture_mb", "buffer_mb", "objects"]:
			first[k + "_peak"] = 0.0
		stage_rows[s] = first
	var r: Dictionary = stage_rows[s]
	r.frames += 1
	r.last_unix_ms = row.unix_ms
	r.last_ms = row.ms
	if r.frames > 1:   # the first frame of a stage carries the switch into it
		r.worst_dt = maxf(r.worst_dt, row.dt)
		if row.dt > 100.0:
			r.over_100ms += 1
	for m in COMPILES:
		r["pc_" + m.to_lower() + "_end"] = row["pc_" + m.to_lower()]
	for k in ["vram_mb", "texture_mb", "buffer_mb", "objects"]:
		r[k + "_peak"] = maxf(r[k + "_peak"], float(row[k]))


func _finish(note: String) -> void:
	if finished:
		return
	finished = true
	_write_summary(note)
	if frames_file != null:
		frames_file.close()
	if report_file != null and report_file.is_open():
		_event("finish", {"note": note})
		report_file.close()
	print("[perf-1439] done: ", note)
	main.quit_clean(0)


# Rewritten every 120 frames and on exit, so a run the recorder ends itself (Battle 3 won) still leaves a summary.
func _exit_tree() -> void:
	if not finished and out_dir != "":
		_write_summary("exited")
		if frames_file != null:
			frames_file.close()


func _write_summary(note: String) -> void:
	var stages: Array = []
	for s in stage_order:
		var r: Dictionary = stage_rows[s].duplicate()
		r["stage"] = s
		var compiles := 0
		for m in COMPILES:
			r["pc_" + m.to_lower()] = int(r["pc_" + m.to_lower() + "_end"]) - int(r["pc_" + m.to_lower() + "_start"])
			compiles += int(r["pc_" + m.to_lower()])
		r["compiles"] = compiles
		stages.append(r)
	var summary := {"note": note, "pid": OS.get_process_id(), "route_note": route_note, "frames": n_frames, "battles": battle_number,
		"title_drawn_engine_ms": title_drawn_ms, "playable_engine_ms": playable,
		"launch_unix_ms": str(main.args.get("launch-ms", "")), "stages": stages, "settings": main.settings,
		"viewport": get_viewport().get_visible_rect().size, "adapter": RenderingServer.get_video_adapter_name()}
	var f := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(summary, " "))
		f.close()


# The recorder's checks are for recordings; here a route that stops early still leaves its stages measured.
func _fail(reason: String) -> void:
	route_note = reason
	printerr("[perf-1439] route stopped: ", reason)
	_finish("route stopped: " + reason)


func _event(kind: String, values := {}) -> void:
	if report_file == null or not report_file.is_open():
		return
	super._event(kind, values)
