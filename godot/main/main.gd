extends Node
# The game's root: title, settings, the campaign (G3, godot/campaign/) and the battles in between, as one game.
# README.md in this folder is the hand-off contract with the campaign: start_battle(run, cfg) returns the result.
#
# Command line (after --):
#   --battle [battle args]   go straight into a quick battle (scenes/battle/battle.gd takes the same args)
#   --bot-runs N             headless test: N full runs (campaign runs when the campaign is in, otherwise sector 1
#                            battles) with both sides on AI; prints one JSON line per run and a summary, and writes
#                            --report <file> (JSON). --fast K speeds the clock K times (default 40).

# issue 1518 (LOAD29 warm: a close 5 s after launch was seen only after 7.7 s, before the game's first frame): the
# battle scene and the campaign host are not preloaded with this script, since compiling them held the window unanswered
# at the start; the battle scene is read on a worker after launch (_battle_packed) and the host is loaded when needed
const BATTLE_SCENE := "res://scenes/battle/battle.tscn"
const BATTLE_SCRIPT := "res://scenes/battle/battle.gd"
const HOST_SCRIPT := "res://main/campaign_host.gd"
const Sfx := preload("res://audio/sfx.gd")   # light: its sound prefetch at launch
const Title := preload("res://main/title.gd")
const OrdersKit := preload("res://ui/theme/orders_kit.gd")
const CAMPAIGN_SCRIPT := "res://campaign/campaign.gd"
const SETTINGS_PATH := "user://settings.json"
const WORLD_BAKE := preload("res://world/world_bake.gd")   # issue 1434: bakes handed back, for the close frame log
const StaticCaches := preload("res://render/static_caches.gd")

signal battle_done(result: Dictionary)

var args := {}
var settings := {"volume": 0.8, "sound": true, "reduce_flashing": false, "shake": 1.0, "speed": 1.0, "tips": true, "fullscreen": true, "quality": "max", "ai": "standard", "follow": true, "music": true, "music_volume": 0.7, "cine": "key", "brisk_camera": false, "movement": "cinematic", "taa": false, "ui_scale": 1.0, "reduce_motion": false, "nebula_wake_on": true, "render_scale": 1.0, "fps_cap": 0.0, "vsync": true}
var title: CanvasLayer
var battle: Node
var campaign: Node
var bot_mode := false
var player_path: Node


# every quit goes through here: free what statics hold first, then quit (see ShipView.clear_static).
# Issue 1435 (W3): the window close button and Alt-F4 come here too (auto accept is off, see _notification), and it runs
# once however many ask: no new showcase or load work starts, the scenes are freed, the fx jobs drain once
# (static_caches clear_all, fx.gd clear_static) and the statics are cleared before the process ends.
var quitting := false
var quit_route := ""   # what started the quit ("menu" or "window"), for logs and the quit route check
var _launch_battle_pending := false


# issue 1434 (LOAD13 cold title_load_5s: the window hid 5.2 s after the close): the last frames before a close, each
# with what was loading, so a close that waited on one long frame names it. A few numbers a frame, kept for 8 frames.
var _frame_t := 0
var _frames: Array = []
# issue 1434 (LOAD17 cold title_load_5s: one 5.35 s frame, cause not split): the renderer's draw time since the last
# _process (frame_pre_draw to frame_post_draw), and the world bakes handed back meanwhile, kept with each frame
var _draw_pre := 0
var _draw_acc := 0


func _on_frame_pre_draw() -> void:
	_draw_pre = Time.get_ticks_usec()


func _on_frame_post_draw() -> void:
	if _draw_pre > 0:
		_draw_acc += Time.get_ticks_usec() - _draw_pre
	_draw_pre = 0


func _frame_parts() -> String:
	var parts := "draw %d ms" % (_draw_acc / 1000)
	_draw_acc = 0
	var back: String = WORLD_BAKE.take_handed_back()
	return parts + (", bake handed back " + back if back != "" else "")


func _process(_dt: float) -> void:
	var now := Time.get_ticks_usec()
	if _frame_t > 0:
		var parts := _frame_parts()
		var what := ""
		if battle != null and is_instance_valid(battle) and battle.get("warming") == true:
			what += "battle " + str(battle.get("load_phase"))
		elif showcase != null and is_instance_valid(showcase) and showcase.get("showcase_ready") == false:
			what += "backdrop " + str(showcase.get("load_phase"))
			var w = showcase.get("world")
			if w != null and is_instance_valid(w) and str(w.get("load_step")) != "":
				what += ", world " + str(w.get("load_step"))
		_frames.append("%d ms (%s; %s)" % [(now - _frame_t) / 1000, what if what != "" else "-", parts])
		if _frames.size() > 8:
			_frames.pop_front()
	_frame_t = now


func quit_clean(code := 0, route := "menu") -> void:
	if quitting:
		return
	quitting = true
	quit_route = route
	var t0 := Time.get_ticks_msec()
	# Hide first, then prevent a last resize/minimize draw from submitting more pipelines.
	if route == "window" and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		RenderingServer.render_loop_enabled = false
	print("[main] quit (%s) at %d ms" % [route, t0])
	if _frame_t > 0:
		_frames.append("%d ms so far (this frame; %s)" % [(Time.get_ticks_usec() - _frame_t) / 1000, _frame_parts()])
	print("[main] frames before the close, oldest first: %s" % ", ".join(_frames))
	# issue 1518 (Artoo on PR 1445): what was loading when the close came, so a close timed "during a load" is proven
	var loading := PackedStringArray()
	if battle != null and is_instance_valid(battle) and battle.get("warming") == true:
		loading.append("battle %s" % str(battle.get("load_phase")))
	elif _launch_battle_pending:
		loading.append("battle launch prefetch")
	if showcase != null and is_instance_valid(showcase) and showcase.get("showcase_ready") == false:
		loading.append("backdrop %s" % str(showcase.get("load_phase")))
	var svc := get_tree().root.get_node_or_null("WorldBakes")
	# a world bake still to run belongs to a load; the deferred PNG write ("#save") runs once loads are over, so it is not
	if svc != null and ((str(svc.get("_active")) != "" and str(svc.get("_active")) != "#save") or not (svc.get("_queue") as Array).is_empty()):
		loading.append("world bake %s" % str(svc.get("_active")).left(12))
	print("[main] loading at the close: %s" % (", ".join(loading) if not loading.is_empty() else "nothing"))
	WORLD_BAKE.begin_shutdown(get_tree())
	for n in [battle, showcase]:
		if n != null and is_instance_valid(n):
			if n.has_method("stop_build"):
				n.stop_build()   # issue 1518: a load under way stops at its next step and starts no more work
			if "quitting" in n:
				n.quitting = true   # issue 521: an awaiting command must not draw on the freed HUD
			n.queue_free()
	if campaign != null and is_instance_valid(campaign):
		campaign.queue_free()
	if is_instance_valid(_retired):
		_retired.queue_free()   # the close may beat the first title draw
		_retired = null
	if music != null and is_instance_valid(music) and music.has_method("release"):
		music.release()
	if ResourceLoader.has_cached(BATTLE_SCRIPT):
		load(BATTLE_SCRIPT).drop_sky_pending()   # a battle script never read has no sky read to drop
	if _scene_reading and ResourceLoader.load_threaded_get_status(BATTLE_SCENE) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		ResourceLoader.load_threaded_get(BATTLE_SCENE)
		_scene_reading = false
	if _fx_reading and ResourceLoader.load_threaded_get_status(FX_SCRIPT) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		ResourceLoader.load_threaded_get(FX_SCRIPT)
		_fx_reading = false
	if _host_reading and ResourceLoader.load_threaded_get_status(HOST_SCRIPT) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_host_script = ResourceLoader.load_threaded_get(HOST_SCRIPT)
		_host_reading = false
	Sfx.drop_pending()
	var t_queued := Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame
	var t1 := Time.get_ticks_msec()
	# issue 1204: every script with a GPU-holding static is on one list (render/static_caches.gd)
	StaticCaches.trace = true
	StaticCaches.clear_all()
	var t2 := Time.get_ticks_msec()
	print("[main] quit stages: scenes freed + 2 frames %d ms, statics and fx drain %d ms, engine exit from %d ms" % [t1 - t0, t2 - t1, t2])
	print("[main] quit split: stop and queue %d ms, dispose scenes %d ms, engine handoff wall ms %d" % [
		t_queued - t0, t1 - t_queued, int(Time.get_unix_time_from_system() * 1000.0)])
	get_tree().quit(code)


# Issue 1435 (W3): the system close (title bar X, Alt-F4) used to end the process straight from SceneTree, past
# quit_clean, so the statics were released after the rendering server (the crash class static_caches.gd describes).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_clean(0, "window")


# bot runs: count every engine and script error per run (Godot 4.5+ Logger), since a script error never reaches the run's
# own result
class ErrCount extends Logger:
	var n := 0
	var first: Array = []
	var mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		mutex.lock()
		n += 1
		if first.size() < 5:
			first.append("%s (%s:%d) %s" % [rationale if rationale != "" else code, file.get_file(), line, function])
		mutex.unlock()

	func _log_message(message: String, error: bool) -> void:
		pass

	func take() -> Array:
		mutex.lock()
		var out := [n, first.duplicate()]
		n = 0
		first.clear()
		mutex.unlock()
		return out


var errlog: ErrCount
var music: Node              # godot/music/music_player.gd (the music helper's player), one for the whole game
var ui_sound: Node           # issue 1217: the front-end sound (godot/audio/sfx.gd with the ui_* cues only), OrdersKit.sound


func _ready() -> void:
	name = "Main"
	get_tree().set_auto_accept_quit(false)   # issue 1435: the window close runs quit_clean (see _notification)
	RenderingServer.frame_pre_draw.connect(_on_frame_pre_draw)   # issue 1434: the close's frame log splits the draw
	RenderingServer.frame_post_draw.connect(_on_frame_post_draw)
	_args()
	if DisplayServer.get_name() != "headless":
		print("[main] ready at %d ms after the engine started" % Time.get_ticks_msec())   # issue 1518 (LOAD29): the launch's own share
		# issue 1518: the sound clips and the battle scene start loading on worker threads now, so the frame that builds the
		# first battle only collects them
		# the campaign host first: the title waits on it alone (Fable on 98926849)
		if not ResourceLoader.has_cached(HOST_SCRIPT) and ResourceLoader.load_threaded_request(HOST_SCRIPT) == OK:
			_host_reading = true   # read on a worker; a load() of it meanwhile waits only for what is not read yet
		Sfx.prefetch()
		if ResourceLoader.load_threaded_request(BATTLE_SCENE) == OK:
			_scene_reading = true   # the sky read starts once the battle script is read (battle_parts_ready)
		if ResourceLoader.load_threaded_request(FX_SCRIPT) == OK:
			_fx_reading = true
	if args.has("player-path"):
		var recorder = load("res://main/player_path.gd")
		var profile_error: String = recorder.prepare_profile()
		if profile_error != "":
			printerr("[player-path] FAIL ", profile_error)
			get_tree().quit(1)
			return
		player_path = recorder.new()
		add_child(player_path)
	elif args.has("perf-1439"):
		# issue 1439: first-launch and per-stage memory measurement (bench/perf_1439.gd); drives like the recorder
		player_path = load("res://bench/perf_1439.gd").new()
		add_child(player_path)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(load("res://ui/battle/brand.gd").TITLE)  # brand.gd: the one place to rename the game
	bot_mode = player_path == null and args.has("bot-runs")
	# a fresh profile starts on Standard enemy AI (onboarding fix 1, campaign3d.js:3); bot runs ignore the player's
	# settings file and play Veteran, as sim3d does, unless --ai says otherwise
	if bot_mode:
		settings["ai"] = str(args.get("ai", "veteran"))
	else:
		_load_settings()
	_apply_settings()
	if ResourceLoader.exists("res://music/music_player.gd") and not args.has("bot-runs"):
		music = load("res://music/music_player.gd").new()
		music.name = "Music"
		add_child(music)
		music.set_volume(float(settings.get("music_volume", 0.7)))
		music.set_on(bool(settings.get("music", true)))
	if not args.has("bot-runs") and ResourceLoader.exists("res://audio/sfx.gd"):
		ui_sound = load("res://audio/sfx.gd").new()
		ui_sound.only = "ui_"
		ui_sound.name = "UiSound"
		add_child(ui_sound)
		OrdersKit.sound = ui_sound
		_settings_to_ui_sound()
	if args.has("quit-after"):
		# a hard stop for test jobs, on every screen (real time, whatever the clock speed)
		var lim := float(args["quit-after"])
		get_tree().create_timer(lim, true, false, true).timeout.connect(func() -> void:
			print("[main] quit-after %d s reached, quitting" % int(lim))
			quit_clean(3))
	if player_path != null:
		player_path.start.call_deferred(self)
	elif args.has("check-export"):
		_check_export.call_deferred()
	elif bot_mode:
		_bot_runs.call_deferred()
	elif args.has("battle") or args.has("scenario") or args.has("shots") or args.has("bot") or args.has("seed"):
		# straight into a battle (test jobs, screenshot jobs): the battle reads the same arguments
		if DisplayServer.get_name() != "headless":
			_quick_battle_after_first_frame()
		else:
			quick_battle()
	else:
		show_title()


# --check-export (run on the exported build): no test trees in the package, and the real parts of the game are in it
# (not the fallbacks), and every ship file the game loads (main/export_ship_check.gd, issue 1438). Prints [export-check] OK
# or FAIL with the reasons; exit code 0 or 1.
func _check_export() -> void:
	var bad: Array = []
	for d in ["res://rules/test", "res://campaign/test", "res://fx/test", "res://music/test", "res://story/test", "res://portraits/test", "res://audio/build"]:
		if DirAccess.dir_exists_absolute(d):
			bad.append("test folder shipped: " + d)
	for f in ["res://campaign/campaign.gd", "res://ui/campaign/campaign_ui.gd", "res://fx/fx.gd", "res://world/world.gd", "res://story/story.gd",
			"res://music/music_player.gd", "res://rules/battle_api.gd", "res://scenes/battle/battle.tscn"]:
		if not ResourceLoader.exists(f):
			bad.append("missing: " + f)
	for f in ["res://rules/data/tables.json"]:
		if not FileAccess.file_exists(f):
			bad.append("missing: " + f)
	if not DirAccess.dir_exists_absolute("res://gen"):
		bad.append("missing: res://gen (the built assets)")
	else:
		# issue 1438: every manifest row loads with its maps, the wing selector's models load, no source ship GLB shipped
		var ships: Dictionary = load("res://main/export_ship_check.gd").check()
		bad.append_array(ships["fails"])
		for line in ships["notes"]:
			print("[export-check] ", line)
	if not FileAccess.file_exists("res://music/music.json"):
		bad.append("note: no music content yet (res://music/music.json)")
	var fails := bad.filter(func(x): return not str(x).begins_with("note:"))
	print("[export-check] %s %s" % ["OK" if fails.is_empty() else "FAIL", JSON.stringify(bad)])
	quit_clean(0 if fails.is_empty() else 1)


func _args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k := a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				args[k] = a[i + 1]
				i += 1
			else:
				args[k] = true
		i += 1


# ---------------------------------------------------------------- settings

func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var o = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if o is Dictionary:
			for k in o:
				settings[k] = o[k]
	# Issue 1079: the nebula wake went on by default (Ryan, Nov 20) under a new key, so the "nebula_wake": false that the
	# off-by-default build saved with every settings file never keeps it off.
	settings.erase("nebula_wake")


func save_settings() -> void:
	# written whole to a temp file, then renamed over the old one, so a crash mid-write never leaves half a file
	var tmp := SETTINGS_PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings, "  "))
		f.close()
		DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(SETTINGS_PATH))
	_apply_settings()


func _capture_window(spec: String) -> void:
	var wh := spec.split("x")
	if wh.size() != 2:
		return
	var want := Vector2i(int(wh[0]), int(wh[1]))
	for i in 3:  # the start-up maximise can land a frame or two later; apply it until it holds
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(want)
		await get_tree().process_frame
	print("[main] capture window ", DisplayServer.window_get_size(), " viewport ", get_viewport().get_visible_rect().size)


func _apply_settings() -> void:
	# the player's UI scale (R2, ui_spec.md 4.4): the Settings entry writes settings["ui_scale"], a missing key reads as 1.0
	load("res://ui/ui_scale.gd").set_player(settings.get("ui_scale", 1.0))
	# screenshot and capture jobs keep the window the command line asked for (--resolution), so every frame is one size
	var capture: bool = args.has("shots") or args.has("breach-shots") or args.has("move-frames") or args.has("title-shot") or args.has("career-shot")
	var player_path_window := args.has("player-path") and DisplayServer.get_name() != "headless"
	if player_path_window:
		# Only the recording window's size differs from the fresh profile's settings.
		_capture_window.call_deferred("1920x1080")
	elif capture and args.has("window") and DisplayServer.get_name() != "headless":
		# --window WxH: an exact window for capture jobs (the project starts maximised, and Godot's --windowed does not undo that)
		_capture_window.call_deferred(str(args["window"]))
	if not bot_mode and not capture and not player_path_window and DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_MAXIMIZED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	if player_launch():
		_apply_display()
	if battle != null and is_instance_valid(battle):
		_settings_to_battle(battle)
	if music != null:
		music.set_volume(float(settings.get("music_volume", 0.7)))
		music.set_on(bool(settings.get("music", true)))
	_settings_to_ui_sound()


# Issue 1437 (item 8): Render scale, Frame cap and V-Sync, in Display. The defaults are today's game (full scale, no cap,
# V-Sync on as project.godot sets it); any new default is Ryan's pick after a rendered comparison. Bot, capture and
# player-path runs never read them, so timing jobs stay uncapped and recordings stay on the player defaults.
func _apply_display() -> void:
	var rs := clampf(float(settings.get("render_scale", 1.0)), 0.5, 1.0)
	# the battle draws in the game's own viewport; the sector map draws in its own full-screen one (map3d.gd), which
	# reads the same value when it is built. Small portraits and podiums stay at full scale.
	Engine.set_meta("render_scale", rs)
	apply_render_scale(get_viewport(), rs)
	for vp in get_tree().get_nodes_in_group("player_3d_viewport"):
		apply_render_scale(vp, rs)
	Engine.max_fps = maxi(0, int(settings.get("fps_cap", 0)))
	var vs := DisplayServer.VSYNC_ENABLED if bool(settings.get("vsync", true)) else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vs:
		DisplayServer.window_set_vsync_mode(vs)


# issue 1559 item 23: a volume slider being dragged sets only the volumes, every step; the file is written (and the rest of
# _apply_settings run: window mode, UI scale) once, when the drag ends
func apply_volumes() -> void:
	if music != null:
		music.set_volume(float(settings.get("music_volume", 0.7)))
	if battle != null and is_instance_valid(battle) and battle.sfx != null:
		battle.sfx.set_volume(float(settings["volume"]))
	_settings_to_ui_sound()


static func apply_render_scale(vp: Viewport, rs: float) -> void:
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR if rs >= 1.0 else Viewport.SCALING_3D_MODE_FSR
	vp.scaling_3d_scale = rs


# Issue 1437 (review on PR 1607): the player's Render scale, Frame cap and V-Sync apply only to a plain launch, the way
# the player starts the game. Any command-line job flag (bot runs, a quick battle, a scenario, every capture or timing
# flag, a player path recording) keeps the engine defaults, so measurements never pick up the player's display settings.
func player_launch() -> bool:
	return args.is_empty() and player_path == null and not bot_mode and DisplayServer.get_name() != "headless"


func _settings_to_ui_sound() -> void:
	if ui_sound != null and is_instance_valid(ui_sound):
		ui_sound.set_on(bool(settings.get("sound", true)))
		ui_sound.set_volume(float(settings.get("volume", 0.8)))


func _settings_to_battle(b: Node) -> void:
	b.music = music
	if not b.option_changed.is_connected(_on_battle_option):
		b.option_changed.connect(_on_battle_option)
	if b.sfx != null:
		b.sfx.set_on(bool(settings["sound"]))
		b.sfx.set_volume(float(settings["volume"]))
	b.user_speed = float(settings["speed"])
	if not args.has("movement"):
		b.movement = str(settings.get("movement", "cinematic"))
	b.ai_level = str(settings["ai"])
	b.follow = bool(settings.get("follow", true))
	b.cine = str(settings.get("cine", "key"))
	b.brisk_camera = bool(settings.get("brisk_camera", false))
	b._sync_teaching_switch()
	b.set_fx_opts(bool(settings["reduce_flashing"]), float(settings["shake"]))
	b.reduce_motion = bool(settings.get("reduce_motion", false))   # issue 521: no key in old settings reads off
	if b.hud != null:
		b.hud.set_log_preferences(bool(settings.get("battle_log_enabled", true)), bool(settings.get("battle_log_collapsed", false)))


func _on_battle_option(key: String, value) -> void:
	settings[key] = value
	save_settings()


# ---------------------------------------------------------------- screens

func show_title(music_after_draw := false) -> void:
	# issue 1518 (Artoo on PR 1445, cc4a63ce): the title asks the campaign host whether a run is saved (Continue or New
	# run), so while the launch's worker still reads the host the title waits for it a frame at a time, the window
	# drawing and answering a close meanwhile, instead of compiling the host inside the first frame
	if _host_reading and _host_still_reading():
		_title_wait += 1
		var wait := _title_wait
		while not quitting and wait == _title_wait and _host_still_reading():
			await get_tree().process_frame
		if quitting or wait != _title_wait:
			return   # closed, or another screen was asked for meanwhile
	if _host_reading:
		_host_reading = false
		if ResourceLoader.load_threaded_get_status(HOST_SCRIPT) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_host_script = ResourceLoader.load_threaded_get(HOST_SCRIPT)   # read by now: no wait; held, so load() finds it cached
	_clear()
	# C32: set the title's AA before its first draw. The deferred backdrop must not rebuild live render buffers.
	var vp := get_viewport()
	if vp.msaa_3d != Viewport.MSAA_DISABLED:
		vp.msaa_3d = Viewport.MSAA_DISABLED
	if vp.use_taa:
		vp.use_taa = false
	if music != null:
		if music_after_draw and DisplayServer.window_can_draw():
			_title_music_after_draw()   # issue 1519: the music starts after the title's first frame, not inside it
		else:
			music.play_title()
	title = Title.new()
	title.main = self
	add_child(title)
	if not _title_painted_said and DisplayServer.window_can_draw():
		_title_painted_said = true
		_say_title_painted(title)
	# the decorative battle behind the menu, built once the title has painted, then faded in over the sky picture
	if _showcase_wanted():
		get_tree().create_timer(0.5).timeout.connect(_start_showcase)
	if args.has("career-shot"):
		_career_shot.call_deferred(str(args["career-shot"]))


func _title_music_after_draw() -> void:
	await RenderingServer.frame_post_draw
	if music != null and is_instance_valid(music) and not quitting and title != null and is_instance_valid(title):
		music.play_title()   # still on the title (a click that left it at once has started its own music)


# --career-shot <png>: open the Career screen from the title as its button does, save a shot, quit (screenshot jobs)
func _career_shot(path: String) -> void:
	await get_tree().create_timer(1.0).timeout
	if not ResourceLoader.exists("res://story/story.gd") or title == null:
		print("[career] no story layer in this build")
		quit_clean(1)
		return
	load("res://story/story.gd").open_standalone(title)
	await get_tree().create_timer(2.5).timeout
	await RenderingServer.frame_post_draw
	preload("res://tools/picture_provenance.gd").save_png(get_viewport().get_texture().get_image(), path, preload("res://tools/picture_provenance.gd").capture_stage())
	print("[career] shot saved ", path)
	quit_clean(0)


var showcase: Node = null


# Issue 1217 phase 2: the title's battle cycles the enemy through every faction that has built ships (your side is the
# Sunward line, so all six show over a few visits), starting at a random one each launch. Built ships are listed in
# res://gen/manifest.json on the PC; a build without it falls back to the repo's ship list.
static var _showcase_i := -1

static func showcase_factions() -> Array:
	var out: Array = []
	for path in ["res://gen/manifest.json", "res://assets/ships/manifest.json"]:
		if not FileAccess.file_exists(path):
			continue
		var m = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (m is Dictionary) or not (m.get("ships") is Dictionary):
			continue
		for id in m["ships"]:
			var e = m["ships"][id]
			var f := str(e.get("faction", "")) if e is Dictionary else ""
			if f != "" and f != "voidsworn" and not out.has(f):
				out.append(f)
		if not out.is_empty():
			break
	out.sort()
	return out if not out.is_empty() else ["hegemony", "corsair"]


static func next_showcase_fac() -> String:
	var facs := showcase_factions()
	if _showcase_i < 0:
		_showcase_i = randi() % facs.size()
	else:
		_showcase_i = (_showcase_i + 1) % facs.size()
	return str(facs[_showcase_i])


func _start_showcase() -> void:
	if quitting or title == null or not is_instance_valid(title) or showcase != null or not _showcase_wanted():
		return
	if _fx_reading or _scene_reading:
		var t_wait: Node = title
		if not await battle_parts_ready():
			return
		if title != t_wait or showcase != null or title == null or not is_instance_valid(title) or not _showcase_wanted():
			return   # the title was left, a backdrop started, or Low was selected meanwhile
	# issue 1519: a battle just left is still being freed in slices behind this title: the backdrop's build waits for
	# that to end, so the two never share a frame and the 3D is back on (off while the old battle is parked)
	if retire_pending():
		var t_slices: Node = title
		while not quitting and retire_pending():
			await get_tree().process_frame
		if quitting or title != t_slices or showcase != null or title == null or not is_instance_valid(title) or not _showcase_wanted():
			return
	showcase = _battle_packed().instantiate()
	showcase.showcase = true
	showcase.title_backdrop = true   # issue 1434: capped at High, silent, no combat warm-up
	showcase.args["quality"] = "high"
	showcase.args["fac"] = next_showcase_fac()
	showcase.args["map"] = ["open", "planet", "station", "storm"][randi() % 4]  # open fields: the dense belts hide the ships at this height
	add_child(showcase)
	move_child(showcase, 0)
	# issue 1434: the backdrop builds a few ships per frame behind the live menu; this wait belongs to this title and this
	# backdrop only (leaving the menu calls stop_build in _clear, and a later title starts its own)
	var sc: Node = showcase
	var t0: Node = title
	while is_instance_valid(sc) and not sc.showcase_ready:
		await get_tree().process_frame
	if not is_instance_valid(sc) or sc != showcase or t0 != title:
		return
	if title != null and is_instance_valid(title) and title.has_method("reveal_showcase"):
		title.reveal_showcase()
	if args.has("title-shot"):
		# --title-shot <png>: the title with its showcase faded in (screenshot jobs), then quit; --title-open settings opens
		# the Settings panel first
		await get_tree().create_timer(4.0).timeout
		if str(args.get("title-open", "")) == "settings" and title != null and is_instance_valid(title):
			title._settings()
			await get_tree().create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		preload("res://tools/picture_provenance.gd").save_png(get_viewport().get_texture().get_image(), str(args["title-shot"]), preload("res://tools/picture_provenance.gd").capture_stage())
		print("[title] shot saved ", args["title-shot"])
		quit_clean(0)


# Graphics changed on the title: Low has no 3D backdrop, High and Max both use the same High backdrop.
var _showcase_gen := 0   # bumped by each rebuild request, so only the newest pending one starts a battle


func restart_showcase() -> void:
	if is_instance_valid(showcase) and _showcase_wanted():
		return   # switching between High and Max never changes the backdrop or rebuilds it
	_showcase_gen += 1
	if showcase != null and is_instance_valid(showcase):
		if showcase.has_method("stop_build"):
			showcase.stop_build()   # Fable on PR 1445: the backdrop's viewport settings go back before its free
		showcase.queue_free()
	showcase = null
	if title != null and is_instance_valid(title) and title.has_method("cover_showcase"):
		title.cover_showcase()
	if _showcase_wanted():
		_arm_rebuild(_showcase_gen)


func _arm_rebuild(gen: int) -> void:
	get_tree().create_timer(0.3).timeout.connect(_rebuild_due.bind(gen))


# a quicker press (say on to Low) since this was asked for wins: only the newest request, still wanted, builds
func _rebuild_due(gen: int) -> void:
	if gen == _showcase_gen and _showcase_wanted():
		_start_showcase()


# the title's battle backdrop: not in bot or headless runs, never on Low (Low has none), not with --no-showcase
func _showcase_wanted() -> bool:
	return not bot_mode and DisplayServer.get_name() != "headless" and str(settings.get("quality", "max")) != "low" and not args.has("no-showcase")


func _host_still_reading() -> bool:
	return hold_host_read or ResourceLoader.load_threaded_get_status(HOST_SCRIPT) == ResourceLoader.THREAD_LOAD_IN_PROGRESS


func _clear() -> void:
	_title_wait += 1   # a title still waiting on the host read is not shown over the new screen
	if title != null and is_instance_valid(title):
		title.queue_free()
	title = null
	if showcase != null and is_instance_valid(showcase):
		if showcase.has_method("stop_build"):
			showcase.stop_build()   # issue 1434: no more backdrop build work, and the menu's viewport settings back
		showcase.queue_free()
	showcase = null


func has_campaign() -> bool:
	return ResourceLoader.exists(CAMPAIGN_SCRIPT)


func new_run(opts := {}) -> void:
	if not has_campaign():
		title.toast("The campaign is not in this build yet. Try a quick battle.")
		return
	_clear()
	# campaign_host.gd runs G3's campaign (rules and screens as data) with real battles; README.md is the contract
	campaign = load(HOST_SCRIPT).new()
	add_child(campaign)
	campaign.run_over.connect(func(_summary) -> void:
		campaign.queue_free()
		campaign = null
		show_title(), CONNECT_ONE_SHOT)
	if player_path != null:
		opts = opts.duplicate()
		opts["player_path_seed"] = int(args["player-path-seed"])
	campaign.start(self, opts)


static func campaign_has_save() -> bool:
	return load(HOST_SCRIPT).has_save()


# issue 1518 (LOAD22 warm: a close during the start hid after 2.7 s, before the game's first frame): the window draws
# and answers its messages once before the battle is built, so a close that comes during that build is seen at once
func _quick_battle_after_first_frame() -> void:
	_launch_battle_pending = true
	await RenderingServer.frame_post_draw
	var ready := await battle_parts_ready()
	_launch_battle_pending = false
	if ready:
		quick_battle()


# issue 1518 (cloud trace: a battle's first setup spent 0.4 s compiling the effects script, inside one frame): the game
# starts reading res://fx/fx.gd on a worker when it starts, and every way into a battle (the test battle, the title's
# backdrop, play_api for the campaign) waits here, a frame at a time, until it is read, so no battle's setup compiles it
# in a frame. A close meanwhile ends the wait (false: the caller builds nothing). No time limit: the read ends.
const FX_SCRIPT := "res://fx/fx.gd"
var _fx_reading := false
var _fx_script: Resource = null   # held, so the battles' load() finds it cached
var hold_fx_read := false         # prefetch_wait_check only: the read counts as still running


func battle_parts_ready() -> bool:
	while not quitting and ((_fx_reading and (hold_fx_read or ResourceLoader.load_threaded_get_status(FX_SCRIPT) == ResourceLoader.THREAD_LOAD_IN_PROGRESS))
			or (_scene_reading and ResourceLoader.load_threaded_get_status(BATTLE_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS)):
		await get_tree().process_frame
	if quitting:
		return false
	if _fx_reading:
		_fx_reading = false
		_fx_script = ResourceLoader.load_threaded_get(FX_SCRIPT)   # read by now: no wait
	if _scene_reading:
		_battle_packed()   # read by now: no wait
		if DisplayServer.get_name() != "headless":
			load(BATTLE_SCRIPT).prefetch_sky()   # issue 1518: the battle's sky starts reading on a worker now
	return true


# issue 1518: the battle scene, from the launch's worker read when it ran (it waits only for what is not read yet)
var _scene_reading := false
var _host_reading := false
var _host_script: Resource = null   # held, as _fx_script, so the title's load() of it never compiles it again
var hold_host_read := false   # prefetch_wait_check only: the host read counts as still running
var _title_painted_said := false


# issue 1518 (Artoo on PR 1445, 6784b6b1): the launch to the first painted title menu, on a line of its own, once per run
func _say_title_painted(t: Node) -> void:
	await RenderingServer.frame_post_draw
	if is_instance_valid(t) and t == title:
		print("[main] title menu painted at %d ms after the engine started (first button: %s)" % [Time.get_ticks_msec(), str(t.get("first_label"))])


var _title_wait := 0   # bumped by each show_title that waits on the host read, and by _clear, so only the newest goes on
var _battle_scene: PackedScene = null


func _battle_packed() -> PackedScene:
	if _battle_scene == null:
		if _scene_reading:
			_scene_reading = false
			_battle_scene = ResourceLoader.load_threaded_get(BATTLE_SCENE)
		if _battle_scene == null:
			_battle_scene = load(BATTLE_SCENE)
	return _battle_scene


# the title's Quick battle (Fable on PR 1445, 98926849): waits a frame at a time for the battle scene's launch read, so
# a click while it is still read never holds the window; the title must still be the screen when it ends
func quick_battle_from_title() -> void:
	var t0: Node = title
	if not await battle_parts_ready():
		return
	if title != t0 or title == null or not is_instance_valid(title) or battle != null:
		return
	quick_battle()


func quick_battle() -> void:
	_clear()
	var b = _battle_packed().instantiate()
	b.external = true
	b.args["quality"] = str(settings["quality"])
	# Issue 1079: on by default (Ryan, Nov 20). A capture that needs the old look passes --nebula_wake false (Artoo, PR 1330).
	var wake := bool(settings.get("nebula_wake_on", true))
	if args.has("nebula_wake"):
		wake = str(args["nebula_wake"]) == "true"
	b.args["nebula_wake"] = str(wake)
	b.args["taa"] = bool(settings.get("taa", false))
	add_child(b)
	_settings_to_battle(b)
	battle = b
	b.start_default()
	b.finished.connect(func(r: Dictionary) -> void:
		# The screenshot sequence saves its last frame and quits itself. A finish signal here means it was interrupted.
		if args.has("shots"):
			push_error("Battle screenshot run ended before capture completed: %s" % r.get("result", "unknown"))
			quit_clean(1)
			return
		if args.has("bot") and OS.has_feature("movie"):
			quit_clean(1 if r.get("result") == "softlock" else 0)
			return
		var t_leave := Time.get_ticks_usec()
		var parts := {}
		battle = null
		_retire_battle(b, parts)
		var t_q := Time.get_ticks_usec()
		show_title(true)
		parts["title_build"] = Time.get_ticks_usec() - t_q
		_time_title_return(t_leave, parts), CONNECT_ONE_SHOT)
	# --title-after S (issue 1435 PC proof): leave the quick battle for the title after S seconds, as the menu's "to title"
	if args.has("title-after"):
		# counted from the game's start (LOAD25: a slow start began the battle late, so "5 s" came after the close)
		var after := maxf(0.05, float(args["title-after"]) - Time.get_ticks_msec() / 1000.0)
		get_tree().create_timer(after, true, false, true).timeout.connect(func() -> void:
			if is_instance_valid(b) and battle == b:
				print("[main] leaving the battle for the title at %d ms" % Time.get_ticks_msec())
				b._on_action("to_title", null))


# LOAD36: removing the battle from the tree took 440 ms before the first title frame, even without freeing it.
# Park rendering and input, paint the title, then free it after the second painted title frame, in slices (issue 1519,
# _free_in_slices). Only quick battle takes this route. The campaign still owns its battle hand-off.
func _retire_battle(b: Node, parts: Dictionary) -> void:
	if b == null or not is_instance_valid(b):
		return
	var t := Time.get_ticks_usec()
	_retire_t0 = t
	if b.has_method("stop_build"):
		b.stop_build()
	if "quitting" in b:
		b.quitting = true   # issue 521: nothing awaiting in it draws again
	if not DisplayServer.window_can_draw():
		if b.get_parent() != null:
			b.get_parent().remove_child(b)
		parts["battle_out"] = Time.get_ticks_usec() - t
		b.queue_free()
		return
	var vp := get_viewport()
	var restore_3d := _take_parked(vp.disable_3d)
	vp.disable_3d = true   # simply hiding Battle still drew its sky and world
	b.process_mode = Node.PROCESS_MODE_DISABLED
	if "hud" in b and is_instance_valid(b.hud):
		b.hud.hide()
	parts["battle_park"] = Time.get_ticks_usec() - t
	_retired = b
	_free_after_title_draws(b, parts, vp, restore_3d)


# issue 1519: an older battle still parked (its title was left before it drew) is freed whole now, and the 3D setting
# it saved is the one to give back; returns that setting
func _take_parked(now_3d: bool) -> bool:
	var restore := now_3d
	if retire_pending():
		restore = _retire_3d
		_retired.free()
	_retired = null
	_retire_3d = restore
	return restore


func _free_after_title_draws(b: Node, parts: Dictionary, vp: Viewport, restore_3d: bool) -> void:
	var draws := 0
	while draws < 2:
		await RenderingServer.frame_post_draw
		if quitting or not is_instance_valid(b) or _retired != b:
			return   # quit_clean owns the parked battle now
		if is_instance_valid(title) and title.is_inside_tree() and not title.is_queued_for_deletion():
			draws += 1
		else:
			# The player left the title after its first draw. Do not keep the next screen's 3D off.
			if draws > 0:
				break
	if not await _free_in_slices(b, parts):
		return   # quit_clean owns the rest of the parked battle now
	_retired = null
	vp.disable_3d = restore_3d


var _retired: Node = null   # parked battle waiting for the title paints, its slices or a close
var _retire_t0 := 0         # when the battle was parked (the leave), for the slices' [main] line
var _retire_3d := false     # the viewport's disable_3d before the park, given back when the parked battle is gone


# Issue 1519: LOAD36's 440 ms detach and the free after it, split across frames behind the painted title. The parked
# battle stays in the tree, switched off (its awaits stop at their next step: battle.gd _left, and _parked in fx.gd,
# board.gd and world.gd), and is freed children first, about RETIRE_BUDGET_US of work a frame, the battle node itself
# last (its _exit_tree still drains its worker tasks). One node's free cannot be split, so a slice ends as soon as it
# has spent the budget. Leaving the title meanwhile frees the rest at once (the next screen needs its 3D back); a close
# hands the rest to quit_clean (returns false then). retire_stats keeps the last battle's numbers.
const RETIRE_BUDGET_US := 6000
var retire_stats := {}


func _free_in_slices(b: Node, parts: Dictionary) -> bool:
	var t_walk := Time.get_ticks_usec()
	var order: Array = [b]   # parents before their children, so taking from the back frees children first
	var i := 0
	while i < order.size():
		order.append_array((order[i] as Node).get_children())   # internal children go with their owner
		i += 1
	parts["battle_walk"] = Time.get_ticks_usec() - t_walk
	var st := {"nodes": order.size(), "freed": 0, "slices": 0, "free_us": 0, "worst_us": 0, "battle_us": 0, "flushed": false}
	retire_stats = st
	while true:
		if quitting or _retired != b or not is_instance_valid(b):
			return false
		var flush := not _title_up()   # the title was left: the next screen needs the 3D back now
		st["flushed"] = st["flushed"] or flush
		var t0 := Time.get_ticks_usec()
		while not order.is_empty():
			var n = order.pop_back()
			# a node moved out of the battle since the walk is no longer the battle's to free
			if is_instance_valid(n) and (n == b or b.is_ancestor_of(n)):
				var tn := Time.get_ticks_usec()
				(n as Node).free()
				st["freed"] += 1
				if n == b:
					st["battle_us"] = Time.get_ticks_usec() - tn
			if not flush and Time.get_ticks_usec() - t0 >= RETIRE_BUDGET_US:
				break
		var spent := Time.get_ticks_usec() - t0
		st["slices"] += 1
		st["free_us"] += spent
		st["worst_us"] = maxi(int(st["worst_us"]), spent)
		if order.is_empty():
			break
		await get_tree().process_frame
	parts["battle_free"] = st["free_us"]
	parts["battle_slice_worst"] = st["worst_us"]
	print("[main] battle to title: old battle freed in %d slices, %d nodes, freeing %.1f ms in all, longest slice %.1f ms (battle node %.1f ms)%s, done %.1f ms after the leave" % [
		st["slices"], st["freed"], st["free_us"] / 1000.0, st["worst_us"] / 1000.0, st["battle_us"] / 1000.0,
		", the rest at once: the title was left" if st["flushed"] else "", (Time.get_ticks_usec() - _retire_t0) / 1000.0])
	return true


func _title_up() -> bool:
	return title != null and is_instance_valid(title) and title.is_inside_tree() and not title.is_queued_for_deletion()


func retire_pending() -> bool:
	return _retired != null and is_instance_valid(_retired)


# Issue 1435: how long leaving a battle holds the player: the leave frame itself (the battle is freed at its end, which
# retires any running cut) and the first title frame after it.
func _time_title_return(t_leave: int, parts := {}) -> void:
	# issue 1519: where the time goes, frame by frame: the end of each frame's draw and the start of the next process step
	var marks: Array = []
	# a draw counts as a title frame only with the title in the tree (Fable on PR 1445: show_title may wait on the host read)
	var on_draw := func() -> void: marks.append(["draw" if title != null and is_instance_valid(title) and title.is_inside_tree() else "draw_no_title", Time.get_ticks_usec() - t_leave])
	RenderingServer.frame_post_draw.connect(on_draw)
	RenderingServer.frame_pre_draw.connect(func() -> void: marks.append(["pre", Time.get_ticks_usec() - t_leave]), CONNECT_ONE_SHOT)
	await get_tree().process_frame
	var t_free := Time.get_ticks_usec()
	marks.append(["step", t_free - t_leave])
	await get_tree().process_frame
	var t_title := Time.get_ticks_usec()
	marks.append(["step", t_title - t_leave])
	# then the rest of the first second, so a cost moved behind the title still shows (worst frame below)
	while Time.get_ticks_usec() - t_leave < 1000000 and not quitting:
		await get_tree().process_frame
		marks.append(["step", Time.get_ticks_usec() - t_leave])
	RenderingServer.frame_post_draw.disconnect(on_draw)
	# issue 1519: the first title frame is the first frame drawn after the leave with the title in the tree (from the leave
	# on, unless the title waited on the host read); before, this line gave the second process step, which also held the
	# battle's free. The worst frame counts every draw.
	var first_draw := -1
	var worst := 0
	var prev := 0
	for m in marks:
		if m[0] == "draw" or m[0] == "draw_no_title":
			if first_draw < 0 and m[0] == "draw":
				first_draw = int(m[1])
			worst = maxi(worst, int(m[1]) - prev)
			prev = int(m[1])
	print("[main] battle to title: leave frame %.1f ms, first title frame %.1f ms after the leave" % [
		float(t_free - t_leave) / 1000.0, float(first_draw if first_draw >= 0 else (t_title - t_leave if not DisplayServer.window_can_draw() else 9999000)) / 1000.0])   # 9999: no draw with the title in its first second
	var bits: Array = []
	for k in parts:
		bits.append("%s %.1f" % [k, float(parts[k]) / 1000.0])
	bits.append("battle exit_tree %.1f" % (float(load("res://scenes/battle/battle.gd").last_exit_us) / 1000.0))
	for m in marks.slice(0, 10):
		bits.append("%s@%.1f" % [m[0], float(m[1]) / 1000.0])
	print("[main] battle to title parts (ms): %s" % ", ".join(bits))
	print("[main] battle to title: worst frame in the first second %.1f ms" % (float(worst) / 1000.0))


# The campaign hands a battle over and gets the result back (README.md). run = the campaign run dictionary, cfg = the
# battle config (rules/API.md new_battle). Hides the campaign's screens while the battle plays.
func start_battle(run: Dictionary, cfg: Dictionary, opts := {}) -> Dictionary:
	var hidden: Array = []
	if campaign != null:
		for c in campaign.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				(c as CanvasItem).visible = false
				hidden.append(c)
			elif c is CanvasLayer and (c as CanvasLayer).visible:
				(c as CanvasLayer).visible = false
				hidden.append(c)
	var b = _battle_packed().instantiate()
	b.external = true
	b.bot = bot_mode or bool(opts.get("bot", false))
	b.in_campaign = campaign != null
	if run.get("map") is Dictionary:
		b.args["sector_setting"] = load("res://world/world.gd").sector_setting(run)
	b.can_retreat = campaign != null and str(cfg.get("kind", "")) != "boss"
	b.args["quality"] = str(settings["quality"])
	b.args["nebula_wake"] = str(bool(settings.get("nebula_wake_on", true)))   # issue 1079: on by default (Ryan, Nov 20)
	b.args["taa"] = bool(settings.get("taa", false))
	add_child(b)
	_settings_to_battle(b)
	battle = b
	b.start_battle(run, cfg)
	var r: Dictionary = await b.finished
	r["api"] = b.api
	battle = null
	b.queue_free()
	for c in hidden:
		if is_instance_valid(c):
			c.visible = true
	return r


# A battle already set up by the campaign host (its rules API, built in battle_setup).
func play_api(a, opts := {}) -> Dictionary:
	if not await battle_parts_ready():
		return {"result": "closing"}   # the game is closing before the battle began: not a result (campaign_host.gd)
	var b = _battle_packed().instantiate()
	b.external = true
	b.bot = bot_mode or bool(opts.get("bot", false))
	b.can_retreat = bool(opts.get("can_retreat", false))
	b.in_campaign = true
	if opts.get("on_round") is Callable:
		b.round_save_cb = opts["on_round"]   # issue 1451: the campaign saves each round start
	if campaign != null and campaign.C.RUN != null:
		b.args["sector_setting"] = load("res://world/world.gd").sector_setting(campaign.C.RUN)
		b.args["stop"] = stop_of(a, campaign.C.RUN)   # issue 1272: rival, boss and wreck-field stops change the sky
		# Issue 1271 (replaces R78 Q18's "fifth run only"): from the fifth run on, the final boss gets dawn.
		# Keep this visual flag out of the rules and saves.
		b.args["finale"] = finale_for_runs(int(campaign.C.META.get("stats", {}).get("runs", 0)))
	b.args["quality"] = str(settings["quality"])
	b.args["nebula_wake"] = str(bool(settings.get("nebula_wake_on", true)))   # issue 1079: on by default (Ryan, Nov 20)
	b.args["taa"] = bool(settings.get("taa", false))
	add_child(b)
	_settings_to_battle(b)
	battle = b
	if player_path != null:
		player_path.watch_battle(b, a, campaign)
	b.begin_with(a)
	var r: Dictionary = await b.finished
	battle = null
	b.queue_free()
	return r


# ---------------------------------------------------------------- bot runs (headless test of whole runs)

func _bot_runs() -> void:
	var n := int(args.get("bot-runs", 10))
	Engine.time_scale = float(args.get("fast", 40.0))
	Engine.max_fps = 0
	var report := {"runs": [], "errors": 0, "softlocks": 0, "started": Time.get_datetime_string_from_system()}
	errlog = ErrCount.new()
	OS.add_logger(errlog)
	var seed0 := int(args.get("seed", 1000))
	# hang guard: a run that takes longer than --run-timeout real seconds (default 600) is reported with where it
	# stood, then the process stops (a stuck rules thread cannot be recovered in place; tmo.bat is the last resort)
	var guard := Timer.new()
	guard.wait_time = 5.0
	add_child(guard)
	guard.timeout.connect(_hang_check.bind(report))
	guard.start()
	for i in n:
		var t0 := Time.get_ticks_msec()
		hang_t0 = t0
		hang_seed = seed0 + i
		var rec = {}
		if has_campaign():
			rec = await _bot_campaign(seed0 + i)
		else:
			rec = await _bot_battle(seed0 + i)
		if not (rec is Dictionary):
			rec = {}
		var ec: Array = errlog.take()
		if int(ec[0]) > 0:
			var el: Array = rec.get("errors", []).duplicate()
			el.append("%d engine or script errors, first: %s" % [int(ec[0]), " | ".join(ec[1])])
			rec["errors"] = el
		if not rec.has("result"):
			rec["result"] = "crashed"
			rec["errors"] = ["the run stopped without a result (script error, see the log)"]
		rec["run"] = i + 1
		rec["seed"] = seed0 + i
		rec["real_s"] = (Time.get_ticks_msec() - t0) / 1000.0
		report["runs"].append(rec)
		report["errors"] += (rec.get("errors", []) as Array).size()
		if str(rec.get("result", "")) == "softlock":
			report["softlocks"] += 1
		print("[botrun] ", JSON.stringify(rec))
	var wins := 0
	var total_s := 0.0
	for r in report["runs"]:
		if str(r.get("result", "")) == "win":
			wins += 1
		total_s += float(r["real_s"])
	report["summary"] = "%d runs, %d wins, %d errors, %d softlocks, %.1f s real time (average %.1f s)" % [n, wins, report["errors"], report["softlocks"], total_s, total_s / maxf(1, n)]
	print("[botrun] SUMMARY ", report["summary"])
	if args.has("report"):
		var f := FileAccess.open(str(args["report"]), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(report, "  "))
	OS.remove_logger(errlog)
	quit_clean(0 if report["errors"] == 0 and report["softlocks"] == 0 else 1)


var hang_t0 := 0
var hang_seed := 0

func _hang_check(report: Dictionary) -> void:
	var lim := float(args.get("run-timeout", 600))
	if (Time.get_ticks_msec() - hang_t0) / 1000.0 < lim:
		return
	var where := {"seed": hang_seed, "real_s": (Time.get_ticks_msec() - hang_t0) / 1000.0}
	if campaign != null and campaign.get("C") != null:
		var C = campaign.C
		where["page"] = str(C.page.get("kind", "?"))
		where["modal"] = str(C.modal_d.get("kind", "?")) if C.modal_d != null else "none"
		where["battles"] = campaign.get("battles")
		where["in_battle"] = campaign.get("in_battle")
	var b = battle if is_instance_valid(battle) else get_node_or_null("Battle")
	if b != null and b.get("api") != null:
		where["battle"] = {"phase": str(b.api.get("phase")), "round": b.get("V").get("round") if b.get("V") is Dictionary else "?", "busy": b.get("busy"),
			"thinking": b.get("thinking"), "warming": b.get("warming"), "ended": b.get("ended"), "idle_s": Time.get_ticks_msec() / 1000.0 - float(b.get("last_progress"))}
	print("[botrun] HANG ", JSON.stringify(where))
	report["errors"] += 1
	print("[botrun] SUMMARY %d runs finished before a hang at seed %d" % [(report["runs"] as Array).size(), hang_seed])
	if args.has("report"):
		report["hang"] = where
		var f := FileAccess.open(str(args["report"]), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(report, "  "))
			f.close()
	get_tree().quit(2)


func _bot_battle(seed: int) -> Dictionary:
	var b = _battle_packed().instantiate()
	b.external = true
	b.bot = true
	add_child(b)
	b.sfx.set_on(false)
	b.args["seed"] = seed
	battle = b
	b.start_default()
	var r: Dictionary = await b.finished
	var out := {"mode": "battle", "result": r.get("result"), "rounds": r.get("rounds"), "errors": r.get("errors", []), "game_s": r.get("secs"), "pipeline_compiles": r.get("pipeline_compiles", -1), "pace": r.get("pace", {})}
	battle = null
	b.queue_free()
	await get_tree().process_frame
	return out


func _bot_campaign(seed: int) -> Dictionary:
	campaign = load(HOST_SCRIPT).new()
	add_child(campaign)
	campaign.start(self, {"bot": true, "seed": seed, "policy": str(args.get("bot-policy", "smart"))})
	var summary = await campaign.run_over
	campaign.queue_free()
	campaign = null
	await get_tree().process_frame
	var out := {"mode": "campaign"}
	if summary is Dictionary:
		for k in summary:
			out[k] = summary[k]
	if not out.has("errors"):
		out["errors"] = []
	return out


# Issue 1271: META stats runs counts the run in progress (campaign.gd newRun adds one at the start, Back from the
# flagship page takes it away), so 5 is the fifth run, as under R78 Q18. Dawn now plays on every run from there.
static func finale_for_runs(runs: int) -> bool:
	return runs >= 5


# Issue 1272: what the backdrop needs to know about this fight stop (visual only; never the rules or saves).
static func stop_of(a, run: Dictionary) -> Dictionary:
	var cfg = a.R.B.get("cfg") if a != null and a.R.B is Dictionary else null
	if not cfg is Dictionary: return {}
	var map: Dictionary = run["map"] if run.get("map") is Dictionary else {}
	return {"kind": str(cfg.get("kind", "")), "fac": str(cfg.get("fac", "")), "sector_fac": str(map.get("fac", "")),
		"node": _id_text(cfg.get("node", "")) + "|" + _id_text(run.get("sector", ""))}


# a saved run reads numbers back as floats: 3 and 3.0 must give the same stop
static func _id_text(v) -> String:
	if v is float and v == floorf(v): return str(int(v))
	return str(v)
