extends SceneTree
# Issue 238, HD6: battle log soak. Plays one long 20-ship battle with both sides on the game's AI, then reports the
# underlying rules log length and the HUD RichTextLabel's line count, and saves a capture with the full log open.
# Report only: it reads the log, it does not change it.
#
#   godot --path godot --resolution 1920x1080 --script <this file> -- --out DIR [--seed N] [--quality high]
#
# The battle is the scene gate's representative 20-ship fight (10 Sunward hulls against two hulls from each other
# faction) on a storm map, played by the bot at accelerated time. The log panel is opened before the capture so the
# whole log is on screen. Prints one LOG_SOAK line and writes soak.json beside the PNG.

const BattleScene := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")

const FLEET := ["ascendant", "cathedral", "penitent", "reliquary", "harrow", "harrow", "warden", "warden", "warden", "warden"]
const ENEMIES := ["c_boss", "c_raider", "h_interdictor", "h_picket", "b_spitter", "b_drone", "i_blade", "i_wisp", "d_harvester", "d_jackal"]
const LIMIT_S := 240.0

var out := "user://battle_log_soak"
var seed := 4238
var quality := "high"
var b
var done := false
var result := ""
var started := 0


func _init() -> void:
	started = Time.get_ticks_msec()
	_run.call_deferred()


func _process(_delta: float) -> bool:
	if not done and (Time.get_ticks_msec() - started) / 1000.0 > LIMIT_S + 10.0:
		push_error("battle log soak: the battle did not end in %d s" % int(LIMIT_S))
		quit(1)
	return false


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k := a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				if k == "out": out = a[i + 1]
				elif k == "seed": seed = int(a[i + 1])
				elif k == "quality": quality = a[i + 1]
				i += 1
		i += 1
	DirAccess.make_dir_recursive_absolute(out)

	var api = API.new()
	var e: String = api.load_rules()
	if e != "":
		push_error("battle log soak: rules: " + e)
		quit(1)
		return
	var sc := {"seed": seed, "sector": 3, "admiral": "vex", "fleet": FLEET.duplicate(), "enemies": ENEMIES.duplicate(),
		"fac": "corsair", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(sc, seed)
	api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}

	b = BattleScene.instantiate()
	b.external = true
	b.bot = true
	b.args["quality"] = quality
	b.args["no-tips"] = true
	root.add_child(b)
	b.battle_cfg = sc
	Engine.time_scale = 30.0
	Engine.max_fps = 0
	b.begin_with(api)
	var w0 := Time.get_ticks_msec()
	while (b.warming or b.busy) and Time.get_ticks_msec() - w0 < 120000:
		await process_frame
	if b.warming or b.busy:
		push_error("battle log soak: warm-up did not finish")
		quit(1)
		return
	# The scene's finished signal fires once the rules report a result. Keep the scene alive afterwards.
	b.finished.connect(func(r): result = str(r.get("result", "")); done = true)
	var rounds := 0
	while not done and (Time.get_ticks_msec() - started) / 1000.0 < LIMIT_S:
		await process_frame
		if b.V is Dictionary:
			rounds = maxi(rounds, int(b.V.get("round", 0)))
	Engine.time_scale = 1.0
	if not done:
		push_error("battle log soak: the battle did not end in %d s" % int(LIMIT_S))
		quit(1)
		return

	# Open the full log (L) before measuring and for the capture, then let the layout settle. A hidden RichTextLabel has
	# no width, so its display-line count is meaningless until the panel is open.
	if b.hud != null and not b.hud.log_open:
		b.hud.toggle_log()
	for k in 20:
		await process_frame

	# Read the two logs after the fight: the rules' own event array and the HUD's RichTextLabel.
	var rules_log: Array = api.R.B.get("log", []) if api.R.B.get("log") is Array else []
	var parsed: String = b.hud.log_text.get_parsed_text()
	var entries := parsed.split("\n", false).size()
	var display_lines: int = b.hud.log_text.get_line_count()
	var chars: int = b.hud.log_text.get_total_character_count()

	await RenderingServer.frame_post_draw
	var png := out.path_join("hd6_battle_log_soak.png")
	var img := root.get_texture().get_image()
	if img != null:
		img.save_png(png)
	var report := {
		"seed": seed, "quality": quality, "result": result, "rounds": rounds,
		"rules_log_entries": rules_log.size(), "hud_log_entries": entries,
		"hud_display_lines": display_lines, "hud_characters": chars,
		"hud_entry_cap_located": true, "js_cap": 200,
		"capture": png, "seconds": (Time.get_ticks_msec() - started) / 1000.0,
	}
	var f := FileAccess.open(out.path_join("soak.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	f.close()
	print("LOG_SOAK result=%s rounds=%d rules_entries=%d hud_entries=%d display_lines=%d chars=%d capture=%s" % [result, rounds, rules_log.size(), entries, display_lines, chars, png])
	done = true
	quit(0)
