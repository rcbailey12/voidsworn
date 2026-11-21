extends Node
# The game's root: title, settings, the campaign (G3, godot/campaign/) and the battles in between, as one game.
# README.md in this folder is the hand-off contract with the campaign: start_battle(run, cfg) returns the result.
#
# Command line (after --):
#   --battle [battle args]   go straight into a quick battle (scenes/battle/battle.gd takes the same args)
#   --bot-runs N             headless test: N full runs (campaign runs when the campaign is in, otherwise sector 1
#                            battles) with both sides on AI; prints one JSON line per run and a summary, and writes
#                            --report <file> (JSON). --fast K speeds the clock K times (default 40).

const BattleScene := preload("res://scenes/battle/battle.tscn")
const Title := preload("res://main/title.gd")
const Host := preload("res://main/campaign_host.gd")
const OrdersKit := preload("res://ui/theme/orders_kit.gd")
const CAMPAIGN_SCRIPT := "res://campaign/campaign.gd"
const SETTINGS_PATH := "user://settings.json"

signal battle_done(result: Dictionary)

var args := {}
var settings := {"volume": 0.8, "sound": true, "reduce_flashing": false, "shake": 1.0, "speed": 1.0, "tips": true, "fullscreen": true, "quality": "max", "ai": "standard", "follow": true, "music": true, "music_volume": 0.7, "cine": "key", "movement": "cinematic", "taa": false, "ui_scale": 1.0, "reduce_motion": false, "nebula_wake_on": true}
var title: CanvasLayer
var battle: Node
var campaign: Node
var bot_mode := false
var player_path: Node


# every quit goes through here: free what statics hold first, then quit (see ShipView.clear_static)
func quit_clean(code := 0) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if campaign != null and is_instance_valid(campaign):
		campaign.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# issue 1204: every script with a GPU-holding static is on one list (render/static_caches.gd)
	load("res://render/static_caches.gd").clear_all()
	get_tree().quit(code)


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
	_args()
	if args.has("player-path"):
		var recorder = load("res://main/player_path.gd")
		var profile_error: String = recorder.prepare_profile()
		if profile_error != "":
			printerr("[player-path] FAIL ", profile_error)
			get_tree().quit(1)
			return
		player_path = recorder.new()
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
		quick_battle()
	else:
		show_title()


# --check-export (run on the exported build): no test trees in the package, and the real parts of the game are in it
# (not the fallbacks). Prints [export-check] OK or FAIL with the reasons; exit code 0 or 1.
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
	if battle != null and is_instance_valid(battle):
		_settings_to_battle(battle)
	if music != null:
		music.set_volume(float(settings.get("music_volume", 0.7)))
		music.set_on(bool(settings.get("music", true)))
	_settings_to_ui_sound()


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
	b._sync_teaching_switch()
	b.set_fx_opts(bool(settings["reduce_flashing"]), float(settings["shake"]))
	b.reduce_motion = bool(settings.get("reduce_motion", false))   # issue 521: no key in old settings reads off
	if b.hud != null:
		b.hud.set_log_preferences(bool(settings.get("battle_log_enabled", true)), bool(settings.get("battle_log_collapsed", false)))


func _on_battle_option(key: String, value) -> void:
	settings[key] = value
	save_settings()


# ---------------------------------------------------------------- screens

func show_title() -> void:
	_clear()
	if music != null:
		music.play_title()
	title = Title.new()
	title.main = self
	add_child(title)
	# the decorative battle behind the menu, built once the title has painted, then faded in over the sky picture
	if not bot_mode and DisplayServer.get_name() != "headless" and str(settings.get("quality", "max")) != "low" and not args.has("no-showcase"):
		get_tree().create_timer(0.5).timeout.connect(_start_showcase)
	if args.has("career-shot"):
		_career_shot.call_deferred(str(args["career-shot"]))


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
	preload("res://tools/picture_provenance.gd").save_png(get_viewport().get_texture().get_image(), path)
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
	if title == null or not is_instance_valid(title) or showcase != null:
		return
	showcase = BattleScene.instantiate()
	showcase.showcase = true
	showcase.title_backdrop = true   # issue 1434: capped at High, silent, no combat warm-up
	showcase.args["quality"] = str(settings["quality"])
	showcase.args["taa"] = bool(settings.get("taa", false))
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
		preload("res://tools/picture_provenance.gd").save_png(get_viewport().get_texture().get_image(), str(args["title-shot"]))
		print("[title] shot saved ", args["title-shot"])
		quit_clean(0)


func _clear() -> void:
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
	campaign = Host.new()
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
	return Host.has_save()


func quick_battle() -> void:
	_clear()
	var b = BattleScene.instantiate()
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
	b.finished.connect(func(_r) -> void:
		b.queue_free()
		battle = null
		show_title(), CONNECT_ONE_SHOT)


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
	var b = BattleScene.instantiate()
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
	var b = BattleScene.instantiate()
	b.external = true
	b.bot = bot_mode or bool(opts.get("bot", false))
	b.can_retreat = bool(opts.get("can_retreat", false))
	b.in_campaign = true
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
	var b = BattleScene.instantiate()
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
	campaign = Host.new()
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
