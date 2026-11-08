extends Node
# Issue 207: the scene gate benchmark (R111). One representative battle on the RTX 5080, measured the round 4 way
# (1920x1080, MSAA 4x, vsync off, warm-up then measured frames, GPU and frame medians), plus isolation runs that take one
# cost out at a time so the binder can be named and the headroom shown. Triangles are never capped: every hull loads at
# the most detail the build has (A4 kit ships, then the max-detail "hi" hulls, then the game hulls), mesh LOD off.
#
# The scene: the real battle scene (scenes/battle/battle.tscn) on a storm map (nebula and ion storm hexes) with the
# world's planet, sky, rocks and clouds, the board in Ryan's look C (cine), the HUD up, at the default battle camera.
# 20 ships in the 8/6/4/2 reporting mix (#207, R111 point 2): 8 frigates, 6 destroyers, 4 cruiser tier (cruiser,
# carrier, battleship), 2 capitals (the Sunward Crusade dreadnought and the Hullbreaker Pyre-Barge, the round 4 anchor).
# Your side is ten Sunward Crusade hulls; the enemy side is two hulls from each of the other five factions, so every
# faction's hull, paint and shader is on screen (distinct hulls and materials, not 20 copies of one mesh).
# Effects on: a seeded running battle of faction weapon volleys (about 3 a second, a third on shields), as in the effects
# gallery's fleet bench but between the battle's own ships.
#
#   godot --path godot --rendering-method forward_plus --resolution 1920x1080 res://bench/scene_gate.tscn -- --out DIR
#         [--sessions 3] [--warmup 120] [--frames 720] [--modes base,shadows_off,...]
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
		fx.volley(att, str(lk[0]), tgt, {"weapon_id": str(lk[1]), "shots": shots, "hits": hits})


func _run() -> void:
	var sessions := int(args.get("sessions", 3))
	var modes: Array = MODES.duplicate()
	if args.has("modes"):
		modes = Array(str(args["modes"]).split(",", false))
	report = {"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"api_version": RenderingServer.get_video_adapter_api_version(), "godot": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(), "driver": OS.get_video_adapter_driver_info(),
		"resolution_asked": [RES.x, RES.y], "vsync": "disabled", "warmup_frames": int(args.get("warmup", 120)),
		"measured_frames": int(args.get("frames", 720)), "sessions": sessions, "volley_every_s": VOLLEY_EVERY,
		"fleet": FLEET, "enemies": ENEMIES, "map": "storm", "shape": "open", "look": "cine", "camera": "default battle camera",
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
	var last := Time.get_ticks_usec()
	var t0 := last
	await _post()
	last = Time.get_ticks_usec()
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
	var row := {"mode": mode, "frames": n, "warmup": warm, "seconds": (Time.get_ticks_usec() - t0) / 1e6,
		"viewport": [vp.get_visible_rect().size.x, vp.get_visible_rect().size.y], "msaa_3d": vp.msaa_3d,
		"scaling_3d": vp.scaling_3d_scale, "volleys": b.gfx.stats.get("volleys", 0) if b.gfx != null else 0,
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
