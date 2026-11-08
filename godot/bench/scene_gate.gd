extends Node
# Issue 207: the scene gate benchmark (R111). One representative battle on the RTX 5080, measured the round 4 way
# (1920x1080, MSAA 4x, vsync off, warm-up then measured frames, GPU and frame medians), plus isolation runs that take one
# cost out at a time so the binder can be named and the headroom shown. Triangles are never capped: every hull loads at
# the most detail the build has (A4 kit ships, then the max-detail "hi" hulls, then the game hulls), mesh LOD off.
#
# The scene: the real battle scene (scenes/battle/battle.tscn) on a storm map (nebula and ion storm hexes) with the
# world's planet, sky, rocks and clouds, the board in Ryan's look C (cine), the HUD up, from the battle camera's angle
# pulled back to frame both fleets (--camera engagement, the default) or at the turn-start view (--camera turn).
# 20 ships in the 8/6/4/2 reporting mix (#207, R111 point 2): 8 frigates, 6 destroyers, 4 cruiser tier (cruiser,
# carrier, battleship), 2 capitals (the Sunward Crusade dreadnought and the Hullbreaker Pyre-Barge, the round 4 anchor).
# Your side is ten Sunward Crusade hulls; the enemy side is two hulls from each of the other five factions, so every
# faction's hull, paint and shader is on screen (distinct hulls and materials, not 20 copies of one mesh).
# Effects on: a seeded running battle of faction weapon volleys (about 3 a second, a third on shields), as in the effects
# gallery's fleet bench but between the battle's own ships.
#
#   godot --path godot --rendering-method forward_plus --resolution 1920x1080 res://bench/scene_gate.tscn -- --out DIR
#         [--sessions 3] [--warmup 120] [--frames 720] [--modes base,shadows_off,...] [--camera engagement|turn]
#
# Writes DIR/scene_gate.json (every mode, every session, plus the scene's per-ship and per-class counts) and
# DIR/scene_base.png (the base scene as measured). Modes, each on a freshly built battle:
#   base         everything on
#   shadows_off  no shadow maps (the key light's 4 split directional shadow, and any other light)
#   msaa_2x      MSAA 2x instead of 4x
#   msaa_off     no MSAA
#   fx_off       effects off: no G4 effects system (no volleys, no ship effects) (battle --nofx)
#   post_off     SSAO, SSIL, glow, volumetric fog and SSR off
#   hud_off      the HUD hidden
#   world_off    the world hidden (planet, rocks, nebula and storm clouds, dust); the sky stays
#   ships_off    every ship hidden (their effects still fire)
#   half_res     the 3D scene drawn at half width and height (a quarter of the pixels), HUD at full size
#   fleet_x2     a visual copy of every hull hovering above it (40 hulls), effects as base
#   deaths       base plus three ship deaths during the measured frames
#   floor        nothing but the board and the sky (no ships, world, HUD or effects)
# --trace (issue 220): in the base and deaths modes, also write DIR/trace_<mode>_s<session>.json, one row per measured
# frame: frame, process, physics, render CPU and GPU ms, the effects system's own main-thread sections (fx.prof, ms),
# new pipeline compiles by kind, volleys fired and objects created that frame; and add a per-section summary of the
# frames over 16.7 ms to the mode's row in scene_gate.json.
# --still (issue 220): no measuring. The base scene on a fixed effect clock (fx.manual, 1/60 s a step, a volley every 21
# steps from the session-1 seed, three deaths at steps 260, 320 and 380), with every worker job (hull rebuilds, death
# cuts) waited for before each step, so the same code draws the same moments; writes still_<step>_wide.png (the gate
# view) and still_<step>_close.png (the third death's ship, close) at steps 200, 300, 400 and 470. For before and
# after sheets of a change that must not show.
# Not in the default list (run with --modes): the 3D scene drawn at more pixels than the 1080p window, so the cost at
# Ryan's real screens shows whatever monitor the window sits on (the HUD stays at 1080p):
#   res_1440     3D at 2560x1440 (scaling_3d_scale 1.333)
#   res_2160     3D at 3840x2160 (scaling_3d_scale 2.0)

const BattleScene := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")
const SV := preload("res://render/ship_view.gd")

const RES := Vector2i(1920, 1080)
const MODES := ["base", "shadows_off", "msaa_2x", "msaa_off", "fx_off", "post_off", "hud_off", "world_off", "ships_off",
	"half_res", "fleet_x2", "deaths", "floor"]
# 8/6/4/2: your side then the enemy side (two per faction); the enemy list starts with the Pyre-Barge, so the world's
# sky and planet are the Hullbreakers' (battle.gd _enemy_fac_of takes the first enemy)
const FLEET := ["ascendant", "cathedral", "penitent", "reliquary", "harrow", "harrow", "warden", "warden", "warden", "warden"]
const ENEMIES := ["c_boss", "c_raider", "h_interdictor", "h_picket", "b_spitter", "b_drone", "i_blade", "i_wisp",
	"d_harvester", "d_jackal"]
const TIER := {"Frigate": "small (frigate)", "Destroyer": "frigate tier (destroyer)", "Cruiser": "cruiser tier",
	"Carrier": "cruiser tier", "Battleship": "cruiser tier", "Dreadnought": "capital", "Battle-barge": "capital",
	"Super-dreadnought": "capital", "Bio-titan": "capital", "Ark": "capital", "Tomb-ark": "capital", "Squadron": "strike craft"}
# each faction's own weapon looks (fx/gallery/gallery.gd reel): [kind, weapon_id]
const LOOKS := {
	"voidsworn": [["battery", "hbattery"], ["battery", "turret"], ["lance", "lance"], ["torp", "torp"]],
	"hegemony": [["battery", "hturbo"], ["lance", "ion"], ["battery", "autocannon"], ["flak", "flak"]],
	"corsair": [["battery", "scatter"], ["torp", "torp"], ["flak", "flak"]],
	"chorus": [["bio", "bioplasma"], ["bio", "tendril"], ["flak", "spores"]],
	"ithar": [["battery", "shard"], ["lance", "pulsar"], ["torp", "startorp"]],
	"deathless": [["gauss", "gauss"], ["lance", "doom"], ["flak", "gsentry"]],
}
const VOLLEY_EVERY := 0.35

var args := {}
var out := ""
var b = null
var report := {}
var rng := RandomNumberGenerator.new()
var volley_t := 0.0
var volleys_on := false
var side_ids := {"player": [], "enemy": []}
var fac_of := {}
var shadow_scan := 0
var kill_shadows := false
var build_ms := 0.0
var vol_looks: Array = []   # --trace: the volleys fired this frame (faction:kind:weapon)


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
	out = str(args.get("out", "user://scene_gate"))
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	OS.low_processor_usage_mode = false
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = RES
	AudioServer.set_bus_mute(0, true)   # a benchmark, not a battle to listen to (and Ryan's PC may be in a quiet room)
	BL.set_look("cine", false)          # Ryan's pick (Nov 1), whatever user://board_look.cfg says; not saved
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_run.call_deferred()


func _process(delta: float) -> void:
	if b == null or not is_instance_valid(b):
		return
	if kill_shadows:
		shadow_scan += 1
		if shadow_scan % 30 == 1:
			_shadows_off(b)
	if not volleys_on or b.gfx == null:
		return
	volley_t += delta
	while volley_t >= VOLLEY_EVERY:
		volley_t -= VOLLEY_EVERY
		_volley()


func _volley() -> void:
	var fx = b.gfx
	var from_p := rng.randf() < 0.5
	var att_list: Array = side_ids["player" if from_p else "enemy"]
	var tgt_list: Array = side_ids["enemy" if from_p else "player"]
	if att_list.is_empty() or tgt_list.is_empty():
		return
	var att: String = att_list[rng.randi() % att_list.size()]
	var tgt: String = tgt_list[rng.randi() % tgt_list.size()]
	var looks: Array = LOOKS.get(fac_of.get(att, "hegemony"), LOOKS["hegemony"])
	var lk: Array = looks[rng.randi() % looks.size()]
	var shield := rng.randf() < 0.35
	var n := 1 + rng.randi() % 3
	var shots := []
	var hits := []
	for k in n:
		shots.append(true)
		hits.append({"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": ["prow", "mid", "eng"][rng.randi() % 3], "crit": false})
	if fx.ships.has(att) and fx.ships.has(tgt) and not fx.ships[att].dead and not fx.ships[tgt].dead:
		vol_looks.append("%s:%s:%s%s" % [fac_of.get(att, "?"), lk[0], lk[1], ":shield" if shield else ""])
		fx.volley(att, str(lk[0]), tgt, {"weapon_id": str(lk[1]), "shots": shots, "hits": hits})


func _run() -> void:
	if args.has("still"):
		await _still_run()
		get_tree().quit(0)
		return
	# Issue 232: the E6/E24 worst-case salvo flash test (per-frame screen luminance, WCAG 2.3.1 counting).
	if args.has("flash"):
		await _flash_run()
		get_tree().quit(0)
		return
	var sessions := int(args.get("sessions", 3))
	var modes: Array = MODES.duplicate()
	if args.has("modes"):
		modes = Array(str(args["modes"]).split(",", false))
	report = {"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"api_version": RenderingServer.get_video_adapter_api_version(), "godot": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(), "driver": OS.get_video_adapter_driver_info(),
		"resolution_asked": [RES.x, RES.y], "vsync": "disabled", "warmup_frames": int(args.get("warmup", 120)),
		"measured_frames": int(args.get("frames", 720)), "sessions": sessions, "volley_every_s": VOLLEY_EVERY,
		"fleet": FLEET, "enemies": ENEMIES, "map": "storm", "shape": "open", "look": "cine",
		"camera": str(args.get("camera", "engagement")),
		"probe_sha256": FileAccess.get_sha256("res://bench/scene_gate.gd"), "modes": {}, "order": []}
	for s in sessions:
		# alternate the order each session (round 5's paired method), so slow drift (heat, background work) spreads evenly
		var order: Array = modes.duplicate()
		if s % 2 == 1:
			order.reverse()
		for m in order:
			var row: Dictionary = await _mode(str(m), s)
			row["session"] = s + 1
			if not report["modes"].has(m):
				report["modes"][m] = []
			report["modes"][m].append(row)
			report["order"].append("%d:%s" % [s + 1, m])
			_save()
	_save()
	print("[scene_gate] DONE")
	get_tree().quit(0)


func _settle(fx) -> void:
	for id in fx.ships:
		var sh = fx.ships[id]
		if int(sh._dmg_task) >= 0:
			while not WorkerThreadPool.is_task_completed(int(sh._dmg_task)):
				OS.delay_usec(500)
		if sh.has_meta("cut_task"):
			while not WorkerThreadPool.is_task_completed(int(sh.get_meta("cut_task"))):
				OS.delay_usec(500)


func _still_run() -> void:
	rng.seed = 2070
	await _build("still", 4207)
	_apply("base")
	var fx = b.gfx
	if fx == null:
		return
	fx.manual = true
	var deaths: Array = []
	for want in ["Frigate", "Destroyer", "Cruiser"]:
		for u in b.V.get("units", []):
			if str(u.get("cls", "")) == want and not deaths.has(str(u["id"])):
				deaths.append(str(u["id"]))
				break
	var keep := {"t": b.cam.t, "r": b.cam.r}
	var close_t := Vector3.INF
	for id in b.views:
		var sv = b.views[id]
		if deaths.size() > 2 and str(id) == str(deaths[2]) and sv != null and is_instance_valid(sv):
			close_t = Vector3(sv.global_position.x, 0, sv.global_position.z)
	var shots := [200, 300, 400, 470]
	for st in 471:
		_settle(fx)
		if st % 21 == 0:
			_volley()
		for d in deaths.size():
			if st == 260 + 60 * d and fx.ships.has(deaths[d]):
				fx.death(deaths[d], "big" if d == 2 else "blast")
				side_ids["player"].erase(deaths[d])
				side_ids["enemy"].erase(deaths[d])
		fx.step(1.0 / 60.0)
		await get_tree().process_frame
		if st in shots:
			await _shot("still_%03d_wide.png" % st)
			if close_t != Vector3.INF:
				b.cam.t = close_t
				b.cam.r = 70.0
				b.cam.snap()
				await get_tree().process_frame
				await _shot("still_%03d_close.png" % st)
				b.cam.t = keep["t"]
				b.cam.r = keep["r"]
				b.cam.snap()
				await get_tree().process_frame
	print("[scene_gate] STILLS DONE")


# Issue 232 E12/E13: every ship at stage 3 or 4 with a full load of weapon marks, so the raised caps bind. The fx.cap_k
# multiplier comes from --capk (1, 2, 4), so the same scene reports each cap step on equal terms.
func _apply_damage_stress() -> void:
	var fx = b.gfx
	if fx == null:
		return
	# The battle's own per-frame sync reads the unit hp back into the damage stages, so the stress sets the units' hp
	# low as well: otherwise the staged damage is reset to 0 on the first measured frame.
	for u in b.V.get("units", []):
		if bool(u.get("dead", false)):
			continue
		var mx := maxf(float(u.get("maxHp", 1.0)), 1.0)
		u["hp"] = mx * 0.05
		if u.get("sec") is Dictionary:
			for nm in u["sec"]:
				var sd = u["sec"][nm]
				if sd is Dictionary:
					sd["hp"] = maxf(float(sd.get("max", 1.0)), 1.0) * 0.05
		u["burning"] = true
	var looks := ["lance", "plasma", "macro", "gauss", "torp", "flak", "spine", "ion"]
	for id in fx.ships:
		var s = fx.ships[id]
		if s.dead or s.squadron:
			continue
		s.set_stages(fx, [4, 4, 4])
		s._set_burning(fx, true)
		var marks := int(24 * float(args.get("capk", 1.0)))
		for j in marks:
			var sec := j % 3
			var h: Dictionary = s.hull.random_sample(sec, 2.0)
			s.add_mark(fx, looks[j % looks.size()], 2 + (j % 2), h["p"], h["n"], -(h["n"] as Vector3).normalized())
	_settle(fx)


# Issue 232: the worst-case mixed salvo the A5 synthesis specifies: every weapon kind plus heavy gauss, a heavy torpedo
# volley, a flak screen and mass squadron deaths, with damaged ships in frame (E24). One capital dies for DS9.
func _flash_run() -> void:
	rng.seed = 2320
	await _build("flash", 4232)
	_apply("base")
	var fx = b.gfx
	if fx == null:
		return
	fx.manual = true
	# E24: damaged and burning ships in frame for the continuous-flicker rules.
	var n := 0
	for id in fx.ships:
		var s = fx.ships[id]
		if s.dead or s.squadron:
			continue
		if n % 3 == 0:
			s.set_stages(fx, [4, 3, 4])
			s._set_burning(fx, true)
		n += 1
	_settle(fx)
	# HD12: the production HUD's floating combat text (make_float), captured while it is up.
	var fid := ""
	for id in side_ids["enemy"]:
		if b.views.has(id):
			fid = id
			break
	if fid != "":
		b._float_hit(fid, 12, 7, true)
		b._float_hit(fid, 0, 9, false)
	var deaths: Array = []
	for id in fx.ships:
		var s = fx.ships[id]
		if s.squadron and not s.dead:
			deaths.append(str(id))
	var capital := ""
	for u in b.V.get("units", []):
		if str(u.get("side", "")) == "enemy" and str(u.get("cls", "")) in ["Battle-barge", "Dreadnought", "Super-dreadnought", "Carrier", "Battleship"]:
			capital = str(u["id"])
			break
	var rows: Array = []
	var death_t := -1.0
	var nsteps := int(args.get("frames", 240))
	var shot_steps := [2, 10, 30, 60, 90, 120, 180, 230]
	for i in nsteps:
		_settle(fx)
		# Three waves, spaced inside the 1 s WCAG window, so the budget has to hold the rolling second.
		if i in [0, 18, 36]:
			_worst_salvo(fx, 0.0)
		if i == 60:
			death_t = fx.now
			for d in deaths:
				if fx.ships.has(d) and not fx.ships[d].dead:
					fx.death(d, "blast")
			if capital != "" and fx.ships.has(capital) and not fx.ships[capital].dead:
				fx.death(capital, "big")
		fx.step(1.0 / 60.0)
		await _post()
		var img := get_viewport().get_texture().get_image()
		var lum := _luma(img)
		rows.append({"i": i, "t": snappedf(fx.now, 0.001), "mean": snappedf(float(lum["mean"]), 0.00001),
			"block": snappedf(float(lum["block"]), 0.00001), "flashes": fx.flash_log.size(), "refused": fx._refused.size()})
		if i in shot_steps:
			var p := out.path_join("flash_%03d.png" % i)
			if img != null and not img.is_empty():
				img.save_png(p)
	# DS9: the capital death's counted flashes and the secondaries' timing from the same log.
	var deaths_at: Array = []
	for k in fx.flash_log:
		if float(k) > death_t:
			deaths_at.append(snappedf(float(k), 0.001))
	# the effect system's own rolling-second count (its budget is the thing under test)
	var flash_times: Array = []
	for k in fx.flash_log:
		flash_times.append(float(k))
	var eff_max := 0
	for f in flash_times:
		var c := 0
		for g in flash_times:
			if float(g) >= float(f) - 1.0 and float(g) <= float(f):
				c += 1
		eff_max = maxi(eff_max, c)
	var max_delta := 0.0
	var max_luma := 0.0
	for j in range(1, rows.size()):
		max_delta = maxf(max_delta, maxf(absf(float(rows[j]["mean"]) - float(rows[j - 1]["mean"])), absf(float(rows[j]["block"]) - float(rows[j - 1]["block"]))))
	for r in rows:
		max_luma = maxf(max_luma, float(r["mean"]))
	# HD12: the HUD's own floating-text size (make_float uses hud.s(16)).
	var float_px := 0
	if b.hud != null and b.hud.has_method("s"):
		float_px = int(b.hud.s(16))
	var fs := FileAccess.open(out.path_join("flash_luma.csv"), FileAccess.WRITE)
	fs.store_line("i,t,mean_relative_luminance,max_block,counted_flashes,refused")
	for r in rows:
		fs.store_line("%d,%.4f,%.6f,%.6f,%d,%d" % [int(r["i"]), float(r["t"]), float(r["mean"]), float(r["block"]), int(r["flashes"]), int(r["refused"])])
	fs.close()
	var stats := _flash_stats(rows)
	var rep := {"kind": "flash", "frames": nsteps, "wire": "WCAG 2.3.1 general flash threshold: opposing relative-luminance changes of 0.10 or more, darker of the pair below 0.80", "cap_per_second": 3,
		"mean_max_per_second": stats["mean_max"], "block_max_per_second": stats["block_max"],
		"flash_events_mean": stats["mean_events"], "flash_events_block": stats["block_events"],
		"pass": bool(stats["mean_max"] <= 3 and stats["block_max"] <= 3),
		"counted_effect_flashes": int(fx.flash_log.size()), "refused_effect_flashes": int(fx._refused.size()),
		"effect_flashes_max_per_second": eff_max, "max_frame_luminance_delta": snappedf(max_delta, 0.00001),
		"max_mean_luminance": snappedf(max_luma, 0.00001), "death_start_t": snappedf(death_t, 0.001),
		"death_flashes_after_start": deaths_at, "hud_float_font_px": float_px, "damage_counts": fx.damage_counts(),
		"shots": shot_steps, "build_ms": build_ms}
	var ff := FileAccess.open(out.path_join("flash.json"), FileAccess.WRITE)
	ff.store_string(JSON.stringify(rep, "  ") + "\n")
	ff.close()
	print("[flash] mean_max_per_s %d block_max_per_s %d counted %d refused %d PASS %s float_px %d" % [stats["mean_max"], stats["block_max"], int(fx.flash_log.size()), int(fx._refused.size()), str(rep["pass"]), float_px])
	print("[scene_gate] FLASH DONE")


func _worst_salvo(fx, t: float) -> void:
	var from_ids: Array = []
	for id in side_ids["player"] + side_ids["enemy"]:
		if fx.ships.has(id) and not fx.ships[id].dead:
			from_ids.append(str(id))
	if from_ids.is_empty():
		return
	var i := 0
	for fac in LOOKS:
		for lk in LOOKS[fac]:
			var att := ""
			var tgt := ""
			for id in from_ids:
				if att == "" and str(fac_of.get(id, "")) == str(fac):
					att = id
				if att != "" and id != att:
					tgt = id
					break
			if att == "" or tgt == "":
				continue
			_fire_at(fx, att, str(lk[0]), tgt, str(lk[1]), t, 3)
			i += 1
	# heavy gauss, a heavy torpedo volley, and a flak screen on top of the faction looks
	var a: String = from_ids[0]
	var tgt2: String = from_ids[from_ids.size() - 1]
	_fire_at(fx, a, "gauss", tgt2, "gauss", t, 2)
	_fire_at(fx, a, "torp", tgt2, "torp", t, 4)
	_fire_at(fx, a, "flak", tgt2, "flak", t, 8)


func _fire_at(fx, att: String, kind: String, tgt: String, weapon: String, t: float, n: int) -> void:
	var shield := rng.randf() < 0.35
	var shots := []
	var hits := []
	for k in n:
		shots.append(true)
		hits.append({"shield": 8 if shield else 0, "hull": 0 if shield else 9, "section": ["prow", "mid", "eng"][rng.randi() % 3], "crit": false})
	if fx.ships.has(att) and fx.ships.has(tgt) and not fx.ships[att].dead and not fx.ships[tgt].dead:
		fx.volley(att, kind, tgt, {"weapon_id": weapon, "shots": shots, "hits": hits})


# Per-frame screen luminance, downsampled: mean over the whole frame and the brightest 1/6-screen block (the WCAG
# 10-degree field is about a quarter of the screen, so the block is the stricter read).
func _luma(img: Image) -> Dictionary:
	if img == null or img.is_empty():
		return {"mean": 0.0, "block": 0.0}
	var im: Image = img.duplicate()
	im.convert(Image.FORMAT_RGBA8)
	im.resize(96, 54, Image.INTERPOLATE_BILINEAR)
	var data: PackedByteArray = im.get_data()
	var sum := 0.0
	var bw := 16
	var bh := 9
	var blocks := {}
	for y in 54:
		for x in 96:
			var o := (y * 96 + x) * 4
			var r := float(data[o]) / 255.0
			var g := float(data[o + 1]) / 255.0
			var b := float(data[o + 2]) / 255.0
			r = r / 12.92 if r <= 0.04045 else pow((r + 0.055) / 1.055, 2.4)
			g = g / 12.92 if g <= 0.04045 else pow((g + 0.055) / 1.055, 2.4)
			b = b / 12.92 if b <= 0.04045 else pow((b + 0.055) / 1.055, 2.4)
			var l := 0.2126 * r + 0.7152 * g + 0.0722 * b
			sum += l
			var key := (y / bh) * 6 + (x / bw)
			blocks[key] = float(blocks.get(key, 0.0)) + l
	var mx := 0.0
	for key in blocks:
		mx = maxf(mx, float(blocks[key]) / float(bw * bh))
	return {"mean": sum / float(96 * 54), "block": mx}


func _flash_stats(rows: Array) -> Dictionary:
	var mean_max := _rolling_max(rows, "mean")
	var block_max := _rolling_max(rows, "block")
	return {"mean_max": mean_max["max"], "block_max": block_max["max"], "mean_events": mean_max["events"], "block_events": block_max["events"]}


# Count WCAG flash pairs: a rise and the following fall (or the reverse) each of at least 0.10 relative luminance,
# merged inside 0.33 s, with the darker of the pair under 0.80. Then the most in any rolling second.
func _rolling_max(rows: Array, key: String) -> Dictionary:
	var ys: Array = []
	for r in rows:
		ys.append(float(r[key]))
	# local extrema after a light 3-frame smooth (keeps a one-frame pop)
	var sm: Array = []
	for i in ys.size():
		var a: float = float(ys[maxi(0, i - 1)])
		var b: float = float(ys[i])
		var c: float = float(ys[mini(ys.size() - 1, i + 1)])
		sm.append((a + b + c) / 3.0)
	var ext: Array = []   # [i, y, turning up?]
	for i in range(1, sm.size() - 1):
		var d0: float = float(sm[i]) - float(sm[i - 1])
		var d1: float = float(sm[i + 1]) - float(sm[i])
		if (d0 >= 0.0 and d1 < 0.0) or (d0 <= 0.0 and d1 > 0.0):
			if ext.is_empty() or absf(float(sm[i]) - float(ext[ext.size() - 1][1])) >= 0.02:
				ext.append([i, float(sm[i])])
	var flashes: Array = []   # [t, low]
	var last := -100.0
	for j in range(1, ext.size()):
		var a: float = float(ext[j - 1][1])
		var b: float = float(ext[j][1])
		var swing := absf(b - a)
		var low := minf(a, b)
		if swing < 0.10 or low >= 0.80:
			continue
		var t: float = float(ext[j][0]) / 60.0
		if t - last < 0.33:
			continue
		last = t
		flashes.append(t)
	var mx := 0
	for f in flashes:
		var c := 0
		for g in flashes:
			if float(g) >= float(f) - 1.0 and float(g) <= float(f):
				c += 1
		mx = maxi(mx, c)
	return {"max": mx, "events": flashes.size()}


func _save() -> void:
	var f := FileAccess.open(out.path_join("scene_gate.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	f.close()


func _build(mode: String, seed: int) -> void:
	b = BattleScene.instantiate()
	b.external = true
	b.args["quality"] = "max"
	b.args["no-tips"] = true
	if mode in ["fx_off", "floor"]:
		b.args["nofx"] = true
	add_child(b)
	b.tips_off = true
	var sc := {"seed": seed, "sector": 3, "admiral": "vex", "fleet": FLEET.duplicate(), "enemies": ENEMIES.duplicate(),
		"fac": "corsair", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	var api = API.new()
	var e: String = api.load_rules()
	if e != "":
		push_error(e)
	api.new_battle_scenario(sc, seed)
	api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}   # world_shots nebula_storm's region
	# every enemy hull keeps its own faction (the rules give a battle one enemy faction; this is a render benchmark,
	# no turn is played)
	var hulls: Dictionary = api.R.HULLS
	var facs: Dictionary = api.R.FACTIONS
	for u in api.R.B["units"]:
		if u["side"] != "enemy":
			continue
		var t := str(u["tpl"])
		for f in facs:
			if (facs[f].get("roster", []) as Array).has(t):
				u["fac"] = f
		if hulls.has(t) and hulls[t].get("fac") != null:
			u["fac"] = str(hulls[t]["fac"])
	b.battle_cfg = sc
	var tb := Time.get_ticks_usec()
	b.begin_with(api)
	var w0 := Time.get_ticks_msec()
	while (b.warming or b.busy) and Time.get_ticks_msec() - w0 < 30000:
		await get_tree().process_frame
	build_ms = (Time.get_ticks_usec() - tb) / 1000.0
	print("[scene_gate] %s built in %.0f ms (ready after %.0f ms)" % [mode, build_ms, Time.get_ticks_msec() - w0])
	for k in 30:
		await get_tree().process_frame
	# nobody drives this battle: no mouse or keys move the camera or pick a ship while it is measured
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.set_process_unhandled_input(false)
	b.set_process_input(false)
	# the camera: "engagement" (default) frames both fleets from the battle camera's own angle, so every faction's hulls
	# and the shots between them are on screen; "turn" keeps the turn-start view (your fleet, the enemy mostly off screen)
	if str(args.get("camera", "engagement")) == "engagement":
		var c := Vector3.ZERO
		var n := 0
		for sv in _views():
			c += sv.global_position
			n += 1
		c /= maxf(1.0, n)
		var rad := 0.0
		for sv in _views():
			rad = maxf(rad, Vector2(sv.global_position.x - c.x, sv.global_position.z - c.z).length())
		b.cam.t = Vector3(c.x, 0, c.z)
		b.cam.r = clampf(maxf(b.cam.r, rad * 2.0), 60.0, 900.0)
		b.cam.snap()
		await get_tree().process_frame
	side_ids = {"player": [], "enemy": []}
	fac_of.clear()
	for u in b.V.get("units", []):
		var id := str(u["id"])
		if b.views.has(u["id"]) or b.views.has(id):
			side_ids[str(u["side"])].append(id)
			fac_of[id] = str(u["fac"])


func _views() -> Array:
	var vs: Array = []
	for id in b.views:
		var sv = b.views[id]
		if sv != null and is_instance_valid(sv):
			vs.append(sv)
	return vs


func _shadows_off(n: Node) -> void:
	if n is Light3D:
		(n as Light3D).shadow_enabled = false
	for c in n.get_children():
		_shadows_off(c)


func _apply(mode: String) -> void:
	var vp := get_viewport()
	vp.scaling_3d_scale = 1.0
	vp.mesh_lod_threshold = 0.0   # triangles uncapped (R111): no mesh LOD swaps, every hull at full detail
	if b != null and b.gfx != null:
		b.gfx.cap_k = float(args.get("capk", 1.0))
	kill_shadows = false
	match mode:
		"shadows_off":
			kill_shadows = true
			_shadows_off(b)
		"msaa_2x":
			vp.msaa_3d = Viewport.MSAA_2X
		"msaa_off":
			vp.msaa_3d = Viewport.MSAA_DISABLED
		"post_off":
			b.env.ssao_enabled = false
			b.env.ssil_enabled = false
			b.env.glow_enabled = false
			b.env.volumetric_fog_enabled = false
			b.env.ssr_enabled = false
		"hud_off":
			b.hud.visible = false
		"world_off":
			if b.world != null:
				b.world.visible = false
		"ships_off":
			for sv in _views():
				sv.visible = false
		"half_res":
			vp.scaling_3d_scale = 0.5
		"res_1440":
			vp.scaling_3d_scale = 2560.0 / 1920.0
		"res_2160":
			vp.scaling_3d_scale = 2.0
		"fleet_x2":
			for sv in _views():
				if sv.hull == null:
					continue
				var c: Node3D = sv.hull.duplicate(0)   # meshes and materials only: no scripts, no effects
				b.add_child(c)
				c.global_transform = Transform3D(sv.hull.global_basis, sv.hull.global_position + Vector3(0, 22.0, 0))
		"floor":
			b.hud.visible = false
			if b.world != null:
				b.world.visible = false
			for sv in _views():
				sv.visible = false


func _mode(mode: String, s: int) -> Dictionary:
	rng.seed = 2070 + s
	volleys_on = false
	volley_t = 0.0
	await _build(mode, 4207)
	_apply(mode)
	if mode == "caps":
		_apply_damage_stress()
	volleys_on = mode != "floor" and mode != "fx_off"
	var vp := get_viewport()
	var vrid := vp.get_viewport_rid()
	var warm := int(args.get("warmup", 120))
	var n := int(args.get("frames", 720))
	# effects need a couple of seconds to reach a steady mix of shots in flight before the warm-up frames count
	var w0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - w0 < 2500:
		await get_tree().process_frame
	for k in warm:
		await get_tree().process_frame
	var deaths: Array = []
	if mode == "deaths":
		# a frigate, a destroyer and a cruiser, spread through the measured frames
		for want in ["Frigate", "Destroyer", "Cruiser"]:
			for u in b.V.get("units", []):
				if str(u.get("cls", "")) == want and not deaths.has(str(u["id"])):
					deaths.append(str(u["id"]))
					break
	var cols := {"gpu": [], "cpu": [], "frame": [], "dc_vis": [], "dc_sh": [], "prim_vis": [], "prim_sh": [], "obj_vis": [],
		"obj_sh": [], "proc": []}
	var trace := bool(args.get("trace", false)) and mode in ["base", "deaths"]
	var tr: Array = []
	var last := Time.get_ticks_usec()
	var t0 := last
	await _post()
	last = Time.get_ticks_usec()
	var pipes0 := _pipes()
	var vol0: int = b.gfx.stats.get("volleys", 0) if b.gfx != null else 0
	var obj0 := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	if b.gfx != null:
		b.gfx.prof_take()
	vol_looks.clear()
	for i in n:
		if mode == "deaths" and b.gfx != null:
			for d in deaths.size():
				if i == int(n * (0.2 + 0.25 * d)) and b.gfx.ships.has(deaths[d]):
					b.gfx.death(deaths[d], "big" if d == 2 else "blast")
					side_ids["player"].erase(deaths[d])
					side_ids["enemy"].erase(deaths[d])
		await get_tree().process_frame
		await _post()
		var now := Time.get_ticks_usec()
		cols["frame"].append((now - last) / 1000.0)
		last = now
		cols["gpu"].append(RenderingServer.viewport_get_measured_render_time_gpu(vrid))
		cols["cpu"].append(RenderingServer.viewport_get_measured_render_time_cpu(vrid))
		cols["dc_vis"].append(RenderingServer.viewport_get_render_info(vrid, 0, 2))
		cols["dc_sh"].append(RenderingServer.viewport_get_render_info(vrid, 1, 2))
		cols["prim_vis"].append(RenderingServer.viewport_get_render_info(vrid, 0, 1))
		cols["prim_sh"].append(RenderingServer.viewport_get_render_info(vrid, 1, 1))
		cols["obj_vis"].append(RenderingServer.viewport_get_render_info(vrid, 0, 0))
		cols["obj_sh"].append(RenderingServer.viewport_get_render_info(vrid, 1, 0))
		cols["proc"].append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		if trace:
			var pf := {}
			if b.gfx != null:
				var raw: Dictionary = b.gfx.prof_take()
				for k in raw:
					if int(raw[k]) > 0:
						pf[k] = snappedf(int(raw[k]) / 1000.0, 0.001)
			var pp := _pipes()
			var dp := {}
			for k in pp:
				if int(pp[k]) != int(pipes0.get(k, 0)):
					dp[k] = int(pp[k]) - int(pipes0.get(k, 0))
			pipes0 = pp
			var vol: int = b.gfx.stats.get("volleys", 0) if b.gfx != null else 0
			var obj := int(Performance.get_monitor(Performance.OBJECT_COUNT))
			tr.append({"i": i, "frame": snappedf(cols["frame"][-1], 0.001), "proc": snappedf(cols["proc"][-1], 0.001),
				"phys": snappedf(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, 0.001),
				"rcpu": snappedf(cols["cpu"][-1], 0.001), "gpu": snappedf(cols["gpu"][-1], 0.001), "fx": pf, "pipes": dp,
				"volleys": vol - vol0, "looks": vol_looks.duplicate(), "objects": obj - obj0, "death": mode == "deaths" and i in [int(n * 0.2), int(n * 0.45), int(n * 0.7)]})
			vol0 = vol
			obj0 = obj
		vol_looks.clear()
	var row := {"mode": mode, "frames": n, "warmup": warm, "seconds": (Time.get_ticks_usec() - t0) / 1e6,
		"viewport": [vp.get_visible_rect().size.x, vp.get_visible_rect().size.y], "msaa_3d": vp.msaa_3d,
		"scaling_3d": vp.scaling_3d_scale, "volleys": b.gfx.stats.get("volleys", 0) if b.gfx != null else 0,
		"cap_k": float(args.get("capk", 1.0)) if b.gfx != null else 1.0,
		"damage_counts": b.gfx.damage_counts() if b.gfx != null else {},
		"vram_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texture_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buffer_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0}
	for k in cols:
		var arr: Array = cols[k]
		var srt := arr.duplicate()
		srt.sort()
		row[k + "_median"] = srt[srt.size() / 2]
		row[k + "_p99"] = srt[int(srt.size() * 0.99)]
		var sum := 0.0
		for v in arr:
			sum += float(v)
		row[k + "_mean"] = sum / maxf(1.0, arr.size())
	# the still and the counts come after the measured frames, so the GPU read-back never lands inside them
	if s == 0 and mode == "base":
		await _shot("scene_base.png")
		report["scene"] = _scene_stats()
	if s == 0 and mode in ["fleet_x2", "fx_off", "shadows_off"]:
		await _shot("scene_%s.png" % mode)
	row["build_ms"] = build_ms
	if trace:
		row["trace"] = _trace_summary(tr)
		var tf := FileAccess.open(out.path_join("trace_%s_s%d.json" % [mode, s + 1]), FileAccess.WRITE)
		tf.store_string(JSON.stringify(tr) + "\n")
		tf.close()
	print("[scene_gate] %d %s gpu %.3f frame %.3f cpu %.3f dc %d+%d prims %d+%d" % [s + 1, mode, row["gpu_median"],
		row["frame_median"], row["cpu_median"], int(row["dc_vis_median"]), int(row["dc_sh_median"]),
		int(row["prim_vis_median"]), int(row["prim_sh_median"])])
	volleys_on = false
	kill_shadows = false
	b.queue_free()
	b = null
	for k in 5:
		await get_tree().process_frame
	return row


const PIPE_KINDS := ["CANVAS", "MESH", "SURFACE", "DRAW", "SPECIALIZATION"]


func _pipes() -> Dictionary:
	var out := {}
	for k in PIPE_KINDS:
		var m: String = "PIPELINE_COMPILATIONS_" + str(k)
		if ClassDB.class_has_integer_constant("Performance", m):
			out[k] = int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return out


func _trace_summary(tr: Array) -> Dictionary:
	var spikes := 0
	var spike_ms := {}
	var all_ms := {}
	var spike_pipes := 0
	var spike_frames: Array = []
	for r in tr:
		var pf: Dictionary = r["fx"]
		for k in pf:
			all_ms[k] = float(all_ms.get(k, 0.0)) + float(pf[k])
		if float(r["frame"]) > 16.7:
			spikes += 1
			for k in pf:
				spike_ms[k] = float(spike_ms.get(k, 0.0)) + float(pf[k])
			var np := 0
			for k in r["pipes"]:
				np += int(r["pipes"][k])
			if np > 0:
				spike_pipes += 1
			if spike_frames.size() < 40:
				spike_frames.append(r)
	return {"frames": tr.size(), "spikes_over_16_7": spikes, "spikes_with_pipeline_compiles": spike_pipes,
		"fx_ms_total": all_ms, "fx_ms_in_spikes": spike_ms, "spike_frames": spike_frames}


# after the frame is drawn (headless has no drawing: the next frame, so the probe can be dry-run in the cloud)
func _post() -> void:
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw


func _shot(name: String) -> void:
	await _post()
	var img := get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.save_png(out.path_join(name))


func _count(n: Node, acc: Dictionary) -> void:
	if n is GeometryInstance3D and not (n as Node3D).is_visible_in_tree():
		return
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var m: Mesh = (n as MeshInstance3D).mesh
		acc["instances"] += 1
		for i in m.get_surface_count():
			acc["surfaces"] += 1
			acc["triangles"] += _tris(m, i)
			var mat = (n as MeshInstance3D).get_active_material(i)
			if mat != null:
				acc["materials"][str(mat.get_rid())] = true
	elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		if mm.mesh != null:
			acc["instances"] += 1
			for i in mm.mesh.get_surface_count():
				acc["surfaces"] += 1
				acc["triangles"] += _tris(mm.mesh, i) * mm.visible_instance_count if mm.visible_instance_count >= 0 else _tris(mm.mesh, i) * mm.instance_count
	for c in n.get_children():
		_count(c, acc)


func _tris(m: Mesh, i: int) -> int:
	if m is ArrayMesh:
		var am := m as ArrayMesh
		var il := am.surface_get_array_index_len(i)
		return il / 3 if il > 0 else am.surface_get_array_len(i) / 3
	var arr: Array = m.surface_get_arrays(i)
	if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
		return (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3


func _scene_stats() -> Dictionary:
	var man := SV.manifest()
	var ships: Array = []
	var classes := {}
	var codes := {}
	var all_mats := {}
	for u in b.V.get("units", []):
		var sv = b.views.get(u["id"], b.views.get(str(u["id"])))
		if sv == null or not is_instance_valid(sv):
			continue
		var hull := {"instances": 0, "surfaces": 0, "triangles": 0, "materials": {}}
		if sv.hull != null:
			_count(sv.hull, hull)
		var whole := {"instances": 0, "surfaces": 0, "triangles": 0, "materials": {}}
		_count(sv, whole)
		var src := "a4 kit ship" if sv.a4 else ("max-detail hi" if man.has("hi") and man["hi"].has(sv.code) else "game hull")
		var cls := str(u.get("cls", ""))
		ships.append({"id": str(u["id"]), "side": str(u["side"]), "tpl": str(u["tpl"]), "fac": str(u["fac"]), "cls": cls,
			"tier": TIER.get(cls, cls), "code": sv.code, "source": src, "hull_triangles": hull["triangles"],
			"hull_surfaces": hull["surfaces"], "hull_instances": hull["instances"], "hull_materials": hull["materials"].size(),
			"all_triangles": whole["triangles"], "all_surfaces": whole["surfaces"], "all_instances": whole["instances"]})
		codes[sv.code] = true
		for k in whole["materials"]:
			all_mats[k] = true
		var t: String = TIER.get(cls, cls)
		if not classes.has(t):
			classes[t] = {"ships": 0, "triangles": 0, "surfaces": 0, "max_triangles": 0, "max_surfaces": 0}
		classes[t]["ships"] += 1
		classes[t]["triangles"] += hull["triangles"]
		classes[t]["surfaces"] += hull["surfaces"]
		classes[t]["max_triangles"] = maxi(int(classes[t]["max_triangles"]), int(hull["triangles"]))
		classes[t]["max_surfaces"] = maxi(int(classes[t]["max_surfaces"]), int(hull["surfaces"]))
	var world_notes := ""
	if b.world != null:
		world_notes = "; ".join(b.world.notes)
	var terr := {}
	for k in b.V.get("terrain", {}):
		var kind := str(b.V["terrain"][k])
		terr[kind] = int(terr.get(kind, 0)) + 1
	var cam_info := {"a": b.cam.a, "b": b.cam.b, "r": b.cam.r, "fov": b.cam.fov, "t": [b.cam.t.x, b.cam.t.y, b.cam.t.z]}
	return {"ships": ships, "tiers": classes, "distinct_hulls": codes.size(), "ship_count": ships.size(),
		"distinct_materials": all_mats.size(), "world_notes": world_notes, "terrain": terr, "camera": cam_info,
		"key_shadow": {"enabled": b.key_light.shadow_enabled if b.key_light != null else false,
			"mode": b.key_light.directional_shadow_mode if b.key_light != null else -1,
			"atlas": int(ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096))},
		"env": {"ssao": b.env.ssao_enabled, "ssil": b.env.ssil_enabled, "glow": b.env.glow_enabled,
			"volumetric_fog": b.env.volumetric_fog_enabled, "ssr": b.env.ssr_enabled, "sdfgi": b.env.sdfgi_enabled}}
