extends SceneTree
# Issue 1268: the same storm-map battle (ion storm beside a nebula) at camera 170 and a camera 26 crop, for Ryan's
# nebula colour sheet. Colour options come in through VS_NEBULA_LIT / VS_NEBULA_GLOW / VS_NEBULA_SHADOW
# (world_living.gd, capture only); with none set it draws today's look. No game default changes.
# godot --path godot --resolution 1280x720 --script res://world/sky_sheet_shots.gd -- --out DIR --region nebula --tag violet
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const PG := preload("res://render/placeholder_guard.gd")
const BL := preload("res://world/board_look.gd")
const BIOME := {
	"frontier": {"rock": "stone", "planet": 4}, "nebula": {"rock": "ice", "planet": 2},
	"world": {"rock": "stone", "planet": 3}, "boneyard": {"rock": "carbon", "planet": 5},
	"deep": {"rock": "carbon", "planet": 6},
}
var out := "user://sky_sheet"
var region := "nebula"
var tag := "today"
# Issue 1270 preview: share of the region's sky tint laid on the key light and ambient (0 = today). Capture only.
var light_share := 0.0
# Issue 1272 preview: a stop mood laid on the sector's sky (plain, rival, boss, salvage). Capture only.
var mood := "plain"
var mood_strength := 1.0
const SKY := preload("res://world/world_sky.gd")
var started := 0

func _init() -> void:
	started = Time.get_ticks_msec()
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 900000:
		printerr("sky sheet: capture timeout")
		quit(1)
	return false

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	for i in argv.size() - 1:
		if argv[i] == "--out": out = argv[i + 1]
		if argv[i] == "--region": region = argv[i + 1]
		if argv[i] == "--tag": tag = argv[i + 1]
		if argv[i] == "--light": light_share = float(argv[i + 1])
		if argv[i] == "--mood": mood = argv[i + 1]
		if argv[i] == "--mood-strength": mood_strength = float(argv[i + 1])
	DirAccess.make_dir_recursive_absolute(out)
	BL.set_look("cine", false)
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = "high"
	root.add_child(b)
	b.tips_off = true
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return
	var sc := {"seed": 1268, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": ["h_picket", "h_dominion", "h_picket"], "fac": "hegemony", "obj": "rout",
		"shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	# The first seed from 1268 whose generated storm map puts a real nebula (5+ hexes) within 4 hexes of the storm.
	var neb := []
	var storm := []
	var best := [null, null]
	var bd := 1e9
	for sd in range(1268, 1468):
		sc["seed"] = sd
		api.new_battle_scenario(sc, sd)
		neb = []
		storm = []
		for key in api.R.B["terrain"]:
			var kind: String = api.R.B["terrain"][key]
			var qr := str(key).split(",")
			var h := {"q": int(qr[0]), "r": int(qr[1])}
			if kind == "neb": neb.append(h)
			elif kind == "storm": storm.append(h)
		best = [null, null]
		bd = 1e9
		for n in neb:
			for s in storm:
				var d: float = api.R.hdist(n, s)
				if d < bd and d >= 2:
					bd = d
					best = [n, s]
		if neb.size() >= 5 and bd <= 4: break
	api.R.B["biome"] = BIOME.get(region, BIOME["nebula"]).duplicate()
	# Ships stand on free hexes near the pair, as in a mid-battle frame.
	var occupied := {}
	var anchor: Dictionary = best[0] if best[0] != null else {"q": 12, "r": 8}
	for i in api.R.B["units"].size():
		var unit: Dictionary = api.R.B["units"][i]
		var h := {}
		var nearest := 1e9
		for cell in api.R.boardHexes():
			var key: String = api.R.hkey(cell["q"], cell["r"])
			var t: String = api.R.B["terrain"].get(key, "")
			if occupied.has(key) or api.R.BLOCKING.has(t) or t == "storm" or t == "neb": continue
			var distance: float = api.R.hdist(cell, anchor) + (0.0 if unit["side"] == "player" else 2.5)
			if distance < nearest and distance >= 1.0:
				h = cell
				nearest = distance
		unit["q"] = h["q"]
		unit["r"] = h["r"]
		occupied[api.R.hkey(h["q"], h["r"])] = true
	if mood != "plain":
		var biome: Dictionary = api.R.B["biome"]
		var st: Dictionary = SKY.setting(biome, "hegemony", "open", false, 0)
		var k := mood_strength
		if mood == "rival":
			# a rival faction's stop: some of its own nebula colours (Ashfall Hullbreakers here) in the sky
			var rv: Array = preload("res://fx/faction_look.gd").of("corsair")["nebula"]
			st["c1"] = (st["c1"] as Vector3).lerp(rv[1] * Vector3(1.3, 1.3, 1.3), 0.45 * k)
			st["c3"] = (st["c3"] as Vector3).lerp(rv[2], 0.4 * k)
		elif mood == "boss":
			# a boss stop: brighter, harder sky (the planet is brought closer after the build)
			st["neb"] = float(st["neb"]) * (1.0 + 0.6 * k)
			st["cover"] = minf(1.0, float(st["cover"]) * (1.0 + 0.25 * k))
			st["c3"] = (st["c3"] as Vector3) * (1.0 + 0.3 * k)
		elif mood == "salvage":
			# a salvage stop: a dusty wreck field, less glow, more dust lanes
			st["dust"] = float(st["dust"]) * (1.0 + 0.9 * k)
			st["neb"] = float(st["neb"]) * (1.0 - 0.3 * k)
			st["band"] = float(st["band"]) * (1.0 - 0.35 * k)
		st["seed"] = int(st["seed"]) + {"rival": 1, "boss": 2, "salvage": 3}.get(mood, 0) * 0
		b.args["sector_setting"] = st
	b.battle_cfg = sc
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > 600000:
			printerr("sky sheet: battle warm-up timed out")
			quit(1)
			return
		await process_frame
	b.hud.visible = false
	# The cloud copy has no built hulls (gen/ lives on the PC), so ships are hidden rather than drawn as blocks.
	if OS.get_environment("VS_SHEET_HIDE_SHIPS") == "1":
		for v in b.views.values(): v.visible = false
	if mood == "boss":
		# bring the backdrop planet (and its rings) nearer: about 1.5 times its size in the sky
		var pp: Vector3 = b.world._planet_pos
		if pp != Vector3.ZERO:
			for n in b.world.find_children("*", "Node3D", true, false):
				if (n as Node3D).position.distance_to(pp) < 1.0:
					(n as Node3D).scale *= 1.0 + 0.5 * mood_strength
	if light_share > 0.0:
		# Value-matched region tint, so the light changes hue, not brightness. The rim light (R227) is left alone.
		var t: Vector3 = SKY.REGION[region]["tint"]
		if "--light-from-sky" in OS.get_cmdline_user_args():
			# the sky colour actually on screen (the sector faction's gas times the region), not the region table alone
			t = (b.world.setting["c1"] as Vector3) * 0.7 + (b.world.setting["c3"] as Vector3) * 0.3
		t = t / maxf(t.x, maxf(t.y, t.z))
		var tc := Color(t.x, t.y, t.z)
		b.key_light.light_color = b.key_light.light_color.lerp(tc, light_share)
		b.env.ambient_light_color = b.env.ambient_light_color.lerp(tc, light_share)
		b.fill_light.light_color = b.fill_light.light_color.lerp(tc, light_share * 0.5)
	b.cam.input_enabled = false
	b.cam.screen_shift = 0.0
	var pn: Vector3 = b.board.hex_world(int(best[0]["q"]), int(best[0]["r"])) if best[0] != null else Vector3.ZERO
	var ps: Vector3 = b.board.hex_world(int(best[1]["q"]), int(best[1]["r"])) if best[1] != null else pn
	var focus := (pn + ps) * 0.5
	focus.y = 0.0
	var ship_focus := Vector3.ZERO
	for v in b.views.values(): ship_focus += v.position
	ship_focus /= maxf(1.0, float(b.views.size()))
	var shots := [[170.0, focus.lerp(ship_focus, 0.3)], [26.0, pn.lerp(ps, 0.35)]]
	if "--ship-close" in argv:
		# issue 1270: the close view is on a player hull (light on the hull), not on the gas
		for v in b.views.values():
			if str(v.u.get("side", "")) == "player":
				shots = [[170.0, ship_focus], [26.0, v.position]]
				break
	if OS.get_environment("VS_SHEET_OVERVIEW") == "1": shots.append([420.0, b.world._center])
	for shot in shots:
		b.cam.r = shot[0]
		b.cam.t = shot[1]
		b.cam.snap()
		for i in 40: await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var name := "%s_%s_c%d.png" % [region, tag, int(shot[0])]
		preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(name))
		print("sky sheet: ", name)
	var info := {"region": b.world.setting.get("region", "?") if "setting" in b.world else "?", "neb_hexes": neb.size(),
		"storm_hexes": storm.size(), "pair_distance": bd, "seed": sc["seed"], "tag": tag,
		"lit": OS.get_environment("VS_NEBULA_LIT"), "glow": OS.get_environment("VS_NEBULA_GLOW")}
	var f := FileAccess.open(out.path_join("%s_%s.json" % [region, tag]), FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	quit(0)
