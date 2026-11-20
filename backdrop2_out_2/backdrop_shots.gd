extends SceneTree
# Capture for the backdrop fixes (issues 1263, 1264, 1267, 1269; Opus helper, Nov 20 2026). Capture only, no game change.
# The PC bat (OPUS_BACKDROP_RUN1.bat) copies this file into the checkout under test as res://backdrop_shots.gd and runs
# it once per set, on main (before) and on each fix branch (after). Every picture is 1280x720, quality high, cine look,
# HUD off, and its file name is its code name: BD<issue>_<set>_<view>.png.
#   --set storm   issue 1269 (and 1263's nebula): the STORM982 kind of view, an ion storm beside a nebula. c170 between
#                 them and c26 on the storm. For each view, 16 frames 0.25 s apart; the brightest is kept (a bolt in it)
#                 and all 16 go in a frames folder.
#   --set dense   issue 1263: the PERF1070 RUN3 fixture (contrib/codex/perf_1118 DENSE: seed 4103, storm map with a
#                 nebula condition), c170 at the first storm hex, a 0.98, b as the battle camera.
#   --set planet  issue 1264: a ringed gas giant (biome planet 0), the camera at r 900 panned to the board's near edge
#                 and turned toward the planet, at two tilts.
#   --set rocks   issue 1264: a belt map; the camera low (b 1.30) at r 26 and r 100, its target swept across the
#                 nearest rocks in 10 steps, every step saved (a rock passing the near plane must fade, never slice).
#   --set edges   issue 1267: the storm-beside-nebula battle at c170 and c26 in cine and in Z (tactical), two skies
#                 (--region nebula and world).
# godot --path godot --rendering-method forward_plus --windowed --resolution 1280x720 --script res://backdrop_shots.gd
#       -- --out DIR --set storm|dense|planet|rocks|edges [--region nebula] [--tag before|after]
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")
const BIOME := {
	"frontier": {"rock": "stone", "planet": 4}, "nebula": {"rock": "ice", "planet": 2},
	"world": {"rock": "stone", "planet": 3}, "boneyard": {"rock": "carbon", "planet": 5},
	"deep": {"rock": "carbon", "planet": 6},
}
var out := "user://backdrop_shots"
var set_name := "storm"
var region := "nebula"
var tag := "after"
var started := 0
var b = null
var info := {}


func _init() -> void:
	started = Time.get_ticks_msec()
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _process(_delta: float) -> bool:
	if Time.get_ticks_msec() - started > 1200000:
		printerr("backdrop shots: capture timeout")
		quit(1)
	return false


func _arg(argv: PackedStringArray, name: String, fallback: String) -> String:
	for i in argv.size() - 1:
		if argv[i] == name: return argv[i + 1]
	return fallback


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	out = _arg(argv, "--out", out)
	set_name = _arg(argv, "--set", set_name)
	region = _arg(argv, "--region", region)
	tag = _arg(argv, "--tag", tag)
	DirAccess.make_dir_recursive_absolute(out)
	BL.set_look("cine", false)
	BL.tactical = false
	info = {"set": set_name, "region": region, "tag": tag, "commit": OS.get_environment("BD_COMMIT")}
	var ok := false
	match set_name:
		"storm": ok = await _storm_set("1269", false)
		"edges": ok = await _storm_set("1267", true)
		"dense": ok = await _dense_set()
		"densediag": ok = await _dense_diag()
		"planet": ok = await _planet_set()
		"rocks": ok = await _rocks_set()
	var f := FileAccess.open(out.path_join("BD_%s_%s_%s.json" % [set_name, region, tag]), FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("backdrop shots: ", "done" if ok else "FAILED", " ", set_name)
	quit(0 if ok else 1)


func _start(api, sc: Dictionary) -> bool:
	b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = OS.get_environment("BD_QUALITY") if OS.get_environment("BD_QUALITY") != "" else "high"
	root.add_child(b)
	b.tips_off = true
	b.battle_cfg = sc
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > 600000:
			printerr("backdrop shots: battle warm-up timed out")
			return false
		await process_frame
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.cam.screen_shift = 0.0
	b.set_process_unhandled_input(false)
	b.set_process_input(false)
	return true


func _api():
	var api = API.new()
	var error: String = api.load_rules()
	if error != "":
		printerr("backdrop shots: ", error)
		return null
	return api


func _view(r: float, t: Vector3, a := -PI / 2.0, tilt := 0.98) -> void:
	b.cam.a = a
	b.cam.b = tilt
	b.cam.r = r
	b.cam.t = t
	b.cam.snap()
	for i in 40: await process_frame
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name))
	print("backdrop shots: ", name)


# Brightest of n frames, step seconds apart (a storm bolt is lit in it); every frame kept in a subfolder.
func _brightest(name: String, n := 16, step := 0.25) -> void:
	var sub := out.path_join(name.get_basename() + "_frames")
	DirAccess.make_dir_recursive_absolute(sub)
	var best: Image = null
	var best_sum := -1.0
	for k in n:
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < int(step * 1000.0): await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.save_png(sub.path_join("%02d.png" % k))
		var small := img.duplicate() as Image
		small.resize(160, 90, Image.INTERPOLATE_BILINEAR)
		var s := 0.0
		for y in 90:
			for x in 160:
				var c := small.get_pixel(x, y)
				s += maxf(0.0, c.get_luminance() - 0.35)
		if s > best_sum:
			best_sum = s
			best = img
	best.save_png(out.path_join(name))
	print("backdrop shots: ", name, " (brightest of ", n, ")")


# The first seed from 1268 whose storm map puts a 5+ hex nebula within 4 hexes of the storm (as sky_sheet_shots.gd).
func _storm_set(issue: String, edges: bool) -> bool:
	var api = _api()
	if api == null: return false
	var sc := {"seed": 1268, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": ["h_picket", "h_dominion", "h_picket"], "fac": "hegemony", "obj": "rout",
		"shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	var best := [null, null]
	var bd := 1e9
	var neb := []
	for sd in range(1268, 1468):
		sc["seed"] = sd
		api.new_battle_scenario(sc, sd)
		neb = []
		var storm := []
		for key in api.R.B["terrain"]:
			var kind: String = api.R.B["terrain"][key]
			var qr := str(key).split(",")
			var h := {"q": int(qr[0]), "r": int(qr[1])}
			if kind == "neb": neb.append(h)
			elif kind == "storm": storm.append(h)
		best = [null, null]
		bd = 1e9
		for nh in neb:
			for s in storm:
				var d: float = api.R.hdist(nh, s)
				if d < bd and d >= 2:
					bd = d
					best = [nh, s]
		if neb.size() >= 5 and bd <= 4: break
	info["seed"] = sc["seed"]
	info["pair_distance"] = bd
	api.R.B["biome"] = BIOME.get(region, BIOME["nebula"]).duplicate()
	if not await _start(api, sc): return false
	var pn: Vector3 = b.board.hex_world(int(best[0]["q"]), int(best[0]["r"])) if best[0] != null else Vector3.ZERO
	var ps: Vector3 = b.board.hex_world(int(best[1]["q"]), int(best[1]["r"])) if best[1] != null else pn
	var mid := (pn + ps) * 0.5
	mid.y = 0.0
	if not edges:
		await _view(170.0, mid)
		await _brightest("BD%s_storm_%s_c170_%s.png" % [issue, region, tag])
		await _view(26.0, ps)
		await _brightest("BD%s_storm_%s_c26_%s.png" % [issue, region, tag])
		return true
	for look in ["cine", "z"]:
		BL.tactical = look == "z"
		b.board.apply_look(false)
		await _view(170.0, mid)
		await _save("BD%s_edges_%s_%s_c170_%s.png" % [issue, region, look, tag])
		await _view(26.0, ps.lerp(pn, 0.25))
		await _save("BD%s_edges_%s_%s_c26_%s.png" % [issue, region, look, tag])
	BL.tactical = false
	return true


func _dense_set() -> bool:
	var api = _api()
	if api == null: return false
	var sc := {"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"fac": "ithar", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(sc, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}
	if not await _start(api, sc): return false
	var pts: Dictionary = b.world._terr_pts
	info["storm_hexes"] = (pts.get("storm", []) as Array).size()
	info["nebula_hexes"] = (pts.get("neb", []) as Array).size()
	await _view(170.0, pts.storm[0])
	await _save("BD1263_dense_c170_%s.png" % tag)
	# the whole storm from higher up, so every side of the cloud shows
	var c := Vector3.ZERO
	for p in pts.storm: c += p
	c /= float(pts.storm.size())
	c.y = 0.0
	await _view(320.0, c)
	await _save("BD1263_dense_c320_%s.png" % tag)
	if (pts.get("neb", []) as Array).size() > 0:
		await _view(170.0, pts.neb[0])
		await _save("BD1263_dense_nebula_c170_%s.png" % tag)
	return true


# Run 2 (issue 1263): which layer draws the straight edge? The dense c170 view with one layer hidden at a time.
func _layer_nodes(kind: String) -> Array:
	var out_nodes: Array = []
	match kind:
		"board": out_nodes = [b.board]
		"cards":
			for n in b.world.find_children("*", "MeshInstance3D", true, false):
				if String(n.name) == "Storm" or String(n.name) == "Nebula": out_nodes.append(n)
		"fog": out_nodes = b.world.find_children("*", "FogVolume", true, false)
		"ships": out_nodes = b.views.values()
	return out_nodes


func _dense_diag() -> bool:
	var api = _api()
	if api == null: return false
	var sc := {"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"fac": "ithar", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(sc, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}
	if not await _start(api, sc): return false
	var pts: Dictionary = b.world._terr_pts
	var bounds: Vector2 = b.cam.bounds
	info["bounds"] = str(bounds)
	info["storm0"] = str(pts.storm[0])
	var zmax := -1e9
	for p in pts.storm + pts.get("neb", []): zmax = maxf(zmax, (p as Vector3).z)
	info["gas_zmax"] = zmax
	for kind in ["none", "board", "cards", "fog"]:
		var hidden := _layer_nodes(kind) if kind != "none" else []
		for n in hidden: n.visible = false
		await _view(170.0, pts.storm[0])
		await _save("BD1263_diag_hide_%s_c170_%s.png" % [kind, tag])
		for n in hidden: n.visible = true
	# side view: the camera low, looking along the board's near edge, so a cut shows as a wall
	await _view(170.0, pts.storm[0], 0.0, 1.30)
	await _save("BD1263_diag_side_c170_%s.png" % tag)
	return true


func _planet_set() -> bool:
	var api = _api()
	if api == null: return false
	var sc := {"seed": 1264, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": ["h_picket", "h_dominion", "h_picket"], "fac": "hegemony", "obj": "rout",
		"shape": "open", "map": "station", "dep": "line", "kind": "battle"}
	# not a planet map: there the board has its own planet and the backdrop draws moons only
	api.new_battle_scenario(sc, 1264)
	api.R.B["biome"] = {"rock": "stone", "planet": 0}
	if not await _start(api, sc): return false
	var pd: Vector3 = b.world._planet_dir
	info["planet_dir"] = str(pd)
	info["planet_r"] = b.world._planet_R
	if pd == Vector3.ZERO:
		printerr("backdrop shots: this map has no backdrop planet")
		return false
	var flat := Vector2(pd.x, pd.z).normalized()
	var bounds: Vector2 = b.cam.bounds
	# pan to the board's edge away from the planet (the farthest the camera gets from it), and face the planet
	var t := Vector3(-flat.x * bounds.x, 0.0, -flat.y * bounds.y)
	var a := atan2(flat.y, -flat.x)
	for tilt in [1.36, 1.15]:
		await _view(900.0, t, a, tilt)
		await _save("BD1264_planet_r900_b%d_%s.png" % [roundi(tilt * 100.0), tag])
		info["far_b%d" % roundi(tilt * 100.0)] = b.cam.far
	await _view(900.0, Vector3.ZERO, -PI / 2.0, 0.98)
	await _save("BD1264_planet_r900_home_%s.png" % tag)
	return true


func _rocks_set() -> bool:
	var api = _api()
	if api == null: return false
	var sc := {"seed": 1264, "sector": 2, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": ["h_picket", "h_dominion", "h_picket"], "fac": "hegemony", "obj": "rout",
		"shape": "open", "map": "belt", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(sc, 1264)
	api.R.B["biome"] = BIOME["frontier"].duplicate()
	if not await _start(api, sc): return false
	# the debris or asteroid hex nearest the board centre; sweep the camera target across it
	var target := Vector3.ZERO
	var nearest := 1e9
	for key in api.R.B["terrain"]:
		var kind := str(api.R.B["terrain"][key])
		if kind in ["debris", "asteroid", "rock", "comet"]:
			var qr := str(key).split(",")
			var p: Vector3 = b.board.hex_world(int(qr[0]), int(qr[1]))
			if p.length() < nearest:
				nearest = p.length()
				target = p
	info["rock_hex"] = str(target)
	for r in [26.0, 100.0]:
		for k in 10:
			var along: float = lerpf(-1.2, 1.2, float(k) / 9.0) * r * 0.5
			await _view(r, target + Vector3(0.0, 0.0, along), -PI / 2.0, 1.30)
			await _save("BD1264_rocks_r%d_%02d_%s.png" % [int(r), k, tag])
	return true
