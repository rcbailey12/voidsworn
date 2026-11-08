extends Node
# F4 capture harness (feel pass, backdrops and asteroids): the real battle scene on a fixed set of settings, one per
# region of the campaign (REGION_BIOME) plus the dead star, each from the default battle camera, zoomed out, and low
# (the camera tipped toward the horizon, where the planet and the sky show most). The HUD is hidden so the world reads.
#
#   godot --path godot --resolution 1920x1080 res://world/world_shots.tscn -- --out DIR [--only a,b] [--quality max]
#         [--bench S]   also orbit the camera for S seconds per case and write DIR/bench.json (frame times)
#         [--novsync]   measure without the screen's frame cap
#         [--looks today,holo,living,cine,tac]   the board look trial (world/board_look.gd): each look in turn on the same
#                       battle, from the default camera, zoomed out and close over the ship that is up, with a move hex
#                       hovered (tac: look C with the tactical grid up); names <case>_<look>_1_default.jpg, _2_zoomed_out.jpg
#                       and _3_close.jpg
#         [--terrain]   with --looks, also a close shot over the nearest nebula, ion storm and debris hex (_4_neb.jpg,
#                       _4_storm.jpg, _4_debris.jpg)
#
# Every case is a fixed scenario dictionary (the same fields as rules/test/scenarios.json) with its seed, and the biome
# the campaign would give that region (biome is visual only, R63), written into the rules' battle before the scene builds.

const BattleScene := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")

# name, enemy faction, map, shape, biome {rock, planet, station}, seed
const CASES := [
	["frontier_belt", "corsair", "belt", "open", {"rock": "stone", "planet": 0, "station": "rig"}, 4101],
	["frontier_station", "hegemony", "station", "open", {"rock": "iron", "planet": 4, "station": "rig"}, 4102],
	["nebula_storm", "ithar", "storm", "open", {"rock": "ice", "planet": 7, "station": "ring"}, 4103],
	["nebula_crystal_belt", "chorus", "belt", "open", {"rock": "crystal", "planet": 2, "station": "spire"}, 4104],
	["world_planet", "hegemony", "planet", "open", {"rock": "stone", "planet": 3, "station": "ring"}, 4105],
	["world_belt_ice", "voidsworn", "belt", "open", {"rock": "ice", "planet": 1, "station": "ring"}, 4106],
	["boneyard_graveyard", "deathless", "graveyard", "dense", {"rock": "carbon", "planet": 5, "station": "spire"}, 4107],
	["deep_storm", "deathless", "storm", "open", {"rock": "carbon", "planet": 6, "station": "spire"}, 4108],
	["open_iron", "corsair", "open", "open", {"rock": "iron", "planet": 0, "station": "rig"}, 4109],
	["deadstar", "ithar", "storm", "deadstar", {"rock": "ice", "planet": 7, "station": "ring"}, 4110],
	# the brief's frame-rate bar: 20 ships (ten a side) on a belt map, the heaviest rock count; its bench is the 1% low
	["bench20_belt", "hegemony", "belt", "open", {"rock": "stone", "planet": 0, "station": "rig"}, 4120,
		{"sector": 3, "fleet": ["penitent", "penitent", "harrow", "harrow", "harrow", "warden", "warden", "warden", "warden", "warden"],
		"enemies": ["h_boss", "h_interdictor", "h_interdictor", "h_interdictor", "h_picket", "h_picket", "h_picket", "h_picket", "h_picket", "h_picket"]}],
]

var args := {}
var out := ""
var bench: Dictionary = {}


func _ready() -> void:
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
	out = str(args.get("out", "user://world_shots"))
	# --novsync: the project syncs to the screen (60 fps on Ryan's monitor), which hides how much room is left; the bench
	# can turn it off to measure the real frame times
	if args.has("novsync"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	var only: PackedStringArray = str(args.get("only", "")).split(",", false)
	for c in CASES:
		if not only.is_empty():
			var hit := false
			for o in only:
				if String(c[0]).contains(o):
					hit = true
			if not hit:
				continue
		await _case(c)
	if args.has("bench"):
		var f := FileAccess.open(out.path_join("bench.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(bench, "  "))
		print("[world_shots] bench ", JSON.stringify(bench))
	print("[world_shots] done")
	get_tree().quit(0)


func _case(c: Array) -> void:
	var name: String = c[0]
	var b = BattleScene.instantiate()
	b.external = true
	b.args["quality"] = str(args.get("quality", "max"))
	b.args["no-tips"] = true
	add_child(b)
	b.tips_off = true
	var sc := {"seed": int(c[5]), "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"], "fac": c[1],
		"obj": "rout", "shape": c[3], "map": c[2], "dep": "line", "kind": "battle"}
	# Issue 232 riders: a warm faction sky for the E17/NB5 weight sheet without editing the case table.
	if args.has("fac"):
		sc["fac"] = str(args["fac"])
	if c.size() > 6:
		for k in c[6]:
			sc[k] = c[6][k]
	var api = API.new()
	var e: String = api.load_rules()
	if e != "":
		push_error(e)
	api.new_battle_scenario(sc, int(c[5]))
	api.R.B["biome"] = (c[4] as Dictionary).duplicate()
	b.battle_cfg = sc
	var t0 := Time.get_ticks_usec()
	b.begin_with(api)
	var t_build := (Time.get_ticks_usec() - t0) / 1000.0
	# let the warm-up, the world's own bakes and the ships settle
	var w0 := Time.get_ticks_msec()
	while (b.warming or b.busy) and Time.get_ticks_msec() - w0 < 20000:
		await get_tree().process_frame
	for k in 90:
		await get_tree().process_frame
	if b.hud != null:
		b.hud.visible = false
	var notes := ""
	if b.world != null:
		notes = "; ".join(b.world.notes)
	print("[world_shots] %s: scene build %.0f ms; %s" % [name, t_build, notes])
	var cam = b.cam
	var home := {"a": cam.a, "b": cam.b, "r": cam.r, "t": cam.t}
	if args.has("looks"):
		await _looks(b, name, home)
		b.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
		return
	await _snap(name + "_1_default")
	cam.r = 640.0
	cam.t = Vector3.ZERO
	cam.snap()
	await _settle()
	await _snap(name + "_2_zoomed_out")
	cam.b = 1.32
	cam.r = 260.0
	cam.t = home["t"]
	cam.snap()
	await _settle()
	await _snap(name + "_3_low")
	# a close look at one of the board's rock hexes (shapes and the rock kind's material, under the battle's light)
	var rk := ""
	var best := 1e9
	for k in b.V.get("terrain", {}):
		if str(b.V["terrain"][k]) == "rock":
			var qr: PackedStringArray = str(k).split(",")
			var pw: Vector3 = b.board.hex_world(int(qr[0]), int(qr[1]))
			if pw.length() < best:
				best = pw.length()
				rk = k
	if rk != "":
		var qr2: PackedStringArray = rk.split(",")
		cam.t = b.board.hex_world(int(qr2[0]), int(qr2[1]))
		cam.b = 1.05
		cam.r = 62.0
		cam.a = home["a"] + 0.5
		cam.snap()
		await _settle()
		await _snap(name + "_4_rocks_close")
	if args.has("bench"):
		cam.a = home["a"]
		cam.b = home["b"]
		cam.r = home["r"]
		cam.t = home["t"]
		cam.snap()
		await _settle()
		var secs := float(args["bench"]) if str(args["bench"]) != "true" else 10.0
		var ms: Array = []
		var t_start := Time.get_ticks_usec()
		var last := t_start
		while (Time.get_ticks_usec() - t_start) / 1e6 < secs:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			ms.append((now - last) / 1000.0)
			last = now
			# a slow orbit and a zoom breath, so every layer of the world passes through the view
			var u := (now - t_start) / 1e6 / secs
			cam.a = home["a"] + sin(u * TAU) * 0.9
			cam.r = home["r"] * (1.0 + 1.2 * (0.5 - 0.5 * cos(u * TAU)))
		ms.sort()
		var avg := 0.0
		for m in ms:
			avg += m
		avg /= maxf(1.0, ms.size())
		var n1: int = maxi(1, int(ms.size() * 0.01))
		var low := 0.0
		for k in n1:
			low += ms[ms.size() - 1 - k]
		low /= n1
		bench[name] = {"avg_ms": snappedf(avg, 0.01), "low1_ms": snappedf(low, 0.01), "worst_ms": snappedf(ms[ms.size() - 1], 0.01), "frames": ms.size(), "build_ms": snappedf(t_build, 0.1)}
	b.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


# the board look trial: every look on the same battle, a move hex two or three out hovered so the planned-move state shows
func _looks(b, name: String, home: Dictionary) -> void:
	var cam = b.cam
	var hk := ""
	var u: Dictionary = b._sel_unit() if b.has_method("_sel_unit") else {}
	if not u.is_empty():
		var ks: Array = b.reach_map.keys()
		ks.sort()
		var best := -1
		for k in ks:
			var qr: PackedStringArray = str(k).split(",")
			var d: int = b.board._hdist(int(qr[0]), int(qr[1]), int(u["q"]), int(u["r"]))
			if d <= 3 and d > best:
				best = d
				hk = k
	print("[world_shots] %s: selected %s, hover %s, %d move hexes" % [name, str(u.get("id", "?")), hk, b.reach_map.size()])
	for l in str(args["looks"]).split(",", false):
		var look := "cine" if l == "tac" else l
		BL.set_look(look, false)
		BL.tactical = l == "tac"
		b.board.apply_look(false)
		if hk != "":
			var qr2: PackedStringArray = hk.split(",")
			b.hover = Vector2i(int(qr2[0]), int(qr2[1]))
			b.board.set_hover(int(qr2[0]), int(qr2[1]))
			b._overlay()
		cam.a = home["a"]
		cam.b = home["b"]
		cam.r = home["r"]
		cam.t = home["t"]
		cam.snap()
		await _settle()
		await _snap("%s_%s_1_default" % [name, l])
		cam.r = 640.0
		cam.t = Vector3.ZERO
		cam.snap()
		await _settle()
		await _snap("%s_%s_2_zoomed_out" % [name, l])
		# close over the ship that is up (where the grid, the footprint and the terrain meet)
		if not u.is_empty():
			cam.t = b.board.hex_world(int(u["q"]), int(u["r"]))
			cam.r = 120.0
			cam.b = home["b"]
			cam.snap()
			await _settle()
			await _snap("%s_%s_3_close" % [name, l])
		# board look step 2 (--terrain): close over the nearest hex of each kind of natural terrain the map has, from the
		# battle camera's angle (the gas, the lightning, the wrecks)
		if args.has("terrain"):
			for kind in ["neb", "storm", "debris"]:
				var tk := ""
				var tb := 1e9
				for k in b.V.get("terrain", {}):
					if str(b.V["terrain"][k]) == kind:
						var qr3: PackedStringArray = str(k).split(",")
						var pw: Vector3 = b.board.hex_world(int(qr3[0]), int(qr3[1]))
						if pw.length() < tb:
							tb = pw.length()
							tk = k
				if tk != "":
					var qr4: PackedStringArray = tk.split(",")
					cam.t = b.board.hex_world(int(qr4[0]), int(qr4[1]))
					cam.r = 95.0
					cam.b = home["b"]
					cam.a = home["a"]
					cam.snap()
					await _settle()
					await _snap("%s_%s_4_%s" % [name, l, kind])
		if args.has("bench"):
			cam.a = home["a"]
			cam.b = home["b"]
			cam.r = home["r"]
			cam.t = home["t"]
			cam.snap()
			await _settle()
			bench["%s_%s" % [name, l]] = await _orbit(cam, home, float(args["bench"]) if str(args["bench"]) != "true" else 8.0)
	if b.world != null:
		print("[world_shots] %s: %s" % [name, "; ".join(b.world.notes)])
	BL.set_look("today", false)


# a slow orbit and a zoom breath for S seconds: frame times (average, 1% low, worst)
func _orbit(cam, home: Dictionary, secs: float) -> Dictionary:
	var ms: Array = []
	var t_start := Time.get_ticks_usec()
	var last := t_start
	while (Time.get_ticks_usec() - t_start) / 1e6 < secs:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ms.append((now - last) / 1000.0)
		last = now
		var u := (now - t_start) / 1e6 / secs
		cam.a = home["a"] + sin(u * TAU) * 0.9
		cam.r = home["r"] * (1.0 + 1.2 * (0.5 - 0.5 * cos(u * TAU)))
	ms.sort()
	var avg := 0.0
	for m in ms:
		avg += m
	avg /= maxf(1.0, ms.size())
	var n1: int = maxi(1, int(ms.size() * 0.01))
	var low := 0.0
	for k in n1:
		low += ms[ms.size() - 1 - k]
	low /= n1
	return {"avg_ms": snappedf(avg, 0.01), "low1_ms": snappedf(low, 0.01), "worst_ms": snappedf(ms[ms.size() - 1], 0.01), "frames": ms.size()}


func _settle() -> void:
	for k in 45:
		await get_tree().process_frame


func _snap(n: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("[world_shots] (headless) ", n)
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := out.path_join(n + ".jpg")
	img.save_jpg(p, 0.92)
	print("[world_shots] ", p)
