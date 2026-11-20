extends SceneTree
# Issue 1272: one campaign sector's fight stops side by side through the game's own path (main.gd stop_of and
# world.gd sector_setting into battle args, world.gd build applying world_sky.gd stop_mood). Capture only.
# godot --path godot --resolution 1280x720 --script res://world/stop_sky_shots.gd -- --out DIR --stop-kind plain|rival|boss|salvage
# VS_SHEET_HIDE_SHIPS=1 hides ship views (cloud copies have no built hulls).
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")
const WORLD := preload("res://world/world.gd")
const MAIN := preload("res://main/main.gd")
var out := "user://stop_sky"
var stop := "plain"

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	for i in argv.size() - 1:
		if argv[i] == "--out": out = argv[i + 1]
		if argv[i] == "--stop-kind": stop = argv[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	BL.set_look("cine", false)
	# One frontier sector held by the Hegemony; the same sector for every stop.
	var run := {"sector": 2, "map": {"fac": "hegemony", "region": "frontier", "biome": {"rock": "stone", "planet": 4},
		"cols": [[{"type": "battle"}], [{"type": "elite"}, {"type": "event"}], [{"type": "boss"}]]}}
	var fac := "corsair" if stop == "rival" else "hegemony"
	var enemies := ["c_raider", "c_raider", "c_raider"] if stop == "rival" else ["h_picket", "h_dominion", "h_picket"]
	var sc := {"seed": 1272, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": enemies, "fac": fac, "obj": "rout", "shape": "open", "map": "graveyard" if stop == "salvage" else "storm",
		"dep": "line", "kind": "boss" if stop == "boss" else "battle", "node": 7}
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = "high"
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return
	api.new_battle_scenario(sc, 1272)
	api.R.B["biome"] = run["map"]["biome"]
	api.R.B["cfg"]["node"] = 7
	b.args["sector_setting"] = WORLD.sector_setting(run)
	b.args["stop"] = MAIN.stop_of(api, run)
	root.add_child(b)
	b.tips_off = true
	b.battle_cfg = sc
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > 600000:
			quit(1)
			return
		await process_frame
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.screen_shift = 0.0
	if OS.get_environment("VS_SHEET_HIDE_SHIPS") == "1":
		for v in b.views.values(): v.visible = false
	for shot in [[420.0, b.world._center], [170.0, b.world._center]]:
		b.cam.r = shot[0]
		b.cam.t = shot[1]
		b.cam.snap()
		for i in 40: await process_frame
		await RenderingServer.frame_post_draw
		var name := "stop_%s_c%d.png" % [stop, int(shot[0])]
		preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), out.path_join(name))
		print("stop sky: ", name, " mood=", b.world.setting.get("mood", "?"), " frame=", b.world.setting.get("frame_scale", "?"), " planet=", b.world.setting.get("planet_i", "?"))
	quit(0)
