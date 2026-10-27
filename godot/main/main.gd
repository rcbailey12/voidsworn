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
const CAMPAIGN_SCRIPT := "res://campaign/campaign.gd"
const SETTINGS_PATH := "user://settings.json"

signal battle_done(result: Dictionary)

var args := {}
var settings := {"volume": 0.8, "sound": true, "reduce_flashing": false, "shake": 1.0, "speed": 1.0, "tips": true, "fullscreen": true, "quality": "max", "ai": "standard", "follow": true, "music": true, "music_volume": 0.7, "cine": "key", "movement": "cinematic", "taa": false}
var title: CanvasLayer
var battle: Node
var campaign: Node
var bot_mode := false


# every quit goes through here: free what statics hold first, then quit (see ShipView.clear_static)
func quit_clean(code := 0) -> void:
	if battle != null and is_instance_valid(battle):
		battle.queue_free()
	if campaign != null and is_instance_valid(campaign):
		campaign.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	load("res://render/ship_view.gd").clear_static()
	load("res://scenes/battle/fx_stub.gd").clear_static()
	# other streams' statics (G4 fx and world, G3 screens): a clear_static() there is called too when it exists
	for sp in ["res://fx/fx.gd", "res://world/world.gd", "res://render/look.gd", "res://ui/campaign/campaign_ui.gd", "res://portraits/portraits.gd"]:
		if ResourceLoader.exists(sp):
			var sc = load(sp)
			if sc != null and sc.has_method("clear_static"):
				sc.clear_static()
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


func _ready() -> void:
	name = "Main"
	_args()
	bot_mode = args.has("bot-runs")
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
	if args.has("quit-after"):
		# a hard stop for test jobs, on every screen (real time, whatever the clock speed)
		var lim := float(args["quit-after"])
		get_tree().create_timer(lim, true, false, true).timeout.connect(func() -> void:
			print("[main] quit-after %d s reached, quitting" % int(lim))
			quit_clean(3))
	if args.has("check-export"):
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
	# screenshot and capture jobs keep the window the command line asked for (--resolution), so every frame is one size
	var capture: bool = args.has("shots") or args.has("breach-shots") or args.has("move-frames") or args.has("title-shot")
	if capture and args.has("window") and DisplayServer.get_name() != "headless":
		# --window WxH: an exact window for capture jobs (the project starts maximised, and Godot's --windowed does not undo that)
		_capture_window.call_deferred(str(args["window"]))
	if not bot_mode and not capture and DisplayServer.get_name() != "headless":
		var want := DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_MAXIMIZED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	if battle != null and is_instance_valid(battle):
		_settings_to_battle(battle)
	if music != null:
		music.set_volume(float(settings.get("music_volume", 0.7)))
		music.set_on(bool(settings.get("music", true)))


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
	b.tips_off = not bool(settings["tips"])
	b.set_fx_opts(bool(settings["reduce_flashing"]), float(settings["shake"]))


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


var showcase: Node = null


func _start_showcase() -> void:
	if title == null or not is_instance_valid(title) or showcase != null:
		return
	showcase = BattleScene.instantiate()
	showcase.showcase = true
	showcase.args["quality"] = str(settings["quality"])
	showcase.args["taa"] = bool(settings.get("taa", false))
	showcase.args["fac"] = ["hegemony", "corsair"][randi() % 2]
	add_child(showcase)
	move_child(showcase, 0)
	while is_instance_valid(showcase) and not showcase.showcase_ready:
		await get_tree().process_frame
	if is_instance_valid(showcase) and title != null and is_instance_valid(title) and title.has_method("reveal_showcase"):
		title.reveal_showcase()
	if args.has("title-shot"):
		# --title-shot <png>: the title with its showcase faded in (screenshot jobs), then quit
		await get_tree().create_timer(4.0).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(str(args["title-shot"]))
		print("[title] shot saved ", args["title-shot"])
		quit_clean(0)


func _clear() -> void:
	if title != null and is_instance_valid(title):
		title.queue_free()
	title = null
	if showcase != null and is_instance_valid(showcase):
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
	campaign.start(self, opts)


static func campaign_has_save() -> bool:
	return Host.has_save()


func quick_battle() -> void:
	_clear()
	var b = BattleScene.instantiate()
	b.external = true
	b.args["quality"] = str(settings["quality"])
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
	b.can_retreat = campaign != null and str(cfg.get("kind", "")) != "boss"
	b.args["quality"] = str(settings["quality"])
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
	b.args["quality"] = str(settings["quality"])
	b.args["taa"] = bool(settings.get("taa", false))
	add_child(b)
	_settings_to_battle(b)
	battle = b
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
