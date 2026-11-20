extends SceneTree
# Issue 1272: first battle load at a stop after the sector's plain sky is already baked (as the sector map does), so the
# number is the extra cost a mood stop adds. Loads a plain stop first (primes the bake cache), frees it, then times the
# target stop: ms from begin_with to the end of warm-up, and the worst frame in the first 180 frames after it.
# godot --path godot --resolution 1280x720 --script res://world/stop_sky_timing.gd -- --stop-kind plain|boss|salvage|rival
# Run each kind in its own process with an empty profile (APPDATA) so the disk bake cache starts empty every time.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")
const WORLD := preload("res://world/world.gd")
const MAIN := preload("res://main/main.gd")
const RUN := {"sector": 2, "map": {"fac": "hegemony", "region": "frontier", "biome": {"rock": "stone", "planet": 4},
	"cols": [[{"type": "battle"}], [{"type": "elite"}, {"type": "event"}], [{"type": "boss"}]]}}

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _load(kind: String) -> Array:
	var fac := "corsair" if kind == "rival" else "hegemony"
	var enemies := ["c_raider", "c_raider", "c_raider"] if kind == "rival" else ["h_picket", "h_dominion", "h_picket"]
	var sc := {"seed": 1272, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": enemies, "fac": fac, "obj": "rout", "shape": "open", "map": "graveyard" if kind == "salvage" else "storm",
		"dep": "line", "kind": "boss" if kind == "boss" else "battle", "node": 7 if kind != "prime" else 3}
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = str(OS.get_environment("VS_TIMING_QUALITY")) if OS.get_environment("VS_TIMING_QUALITY") != "" else "high"
	var api = API.new()
	api.load_rules()
	api.new_battle_scenario(sc, 1272)
	api.R.B["biome"] = RUN["map"]["biome"]
	api.R.B["cfg"]["node"] = sc["node"]
	b.args["sector_setting"] = WORLD.sector_setting(RUN)
	b.args["stop"] = MAIN.stop_of(api, RUN)
	root.add_child(b)
	b.tips_off = true
	b.battle_cfg = sc
	var t0 := Time.get_ticks_usec()
	b.begin_with(api)
	while b.warming or b.busy:
		await process_frame
	var load_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var worst := 0.0
	var last := Time.get_ticks_usec()
	for i in 180:
		await process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - last) / 1000.0)
		last = now
	return [b, load_ms, worst]


func _run() -> void:
	root.size = Vector2i(1280, 720)
	BL.set_look("cine", false)
	var kind := "plain"
	var argv := OS.get_cmdline_user_args()
	for i in argv.size() - 1:
		if argv[i] == "--stop-kind": kind = argv[i + 1]
	var prime: Array = await _load("prime")
	print("STOP_TIMING prime plain load_ms %.0f worst_frame_ms %.1f" % [prime[1], prime[2]])
	prime[0].queue_free()
	for i in 10: await process_frame
	var r: Array = await _load(kind)
	print("STOP_TIMING %s load_ms %.0f worst_frame_ms %.1f mood %s" % [kind, r[1], r[2], r[0].world.setting.get("mood", "?")])
	quit(0)
