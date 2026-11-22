extends SceneTree
# Issue 1079: the nebula wake prototype's clip and cost, on the dense-storm fixture (PR 976's seed-4103 storm case,
# docs/shots/storm_cost/measure.gd) so the storm flare sits in the same frame.
# A frigate and a capital of your fleet fly the same scripted line through the nebula with the wake off, then on.
# The flight is visual only (ShipView positions; no rule, move or terrain is touched).
#   godot --path godot --fixed-fps 30 --script res://world/nebula_wake_capture.gd -- OUT shots [max|high|low] [W H [camera radius]]
#   godot --path godot --script res://world/nebula_wake_capture.gd -- OUT timing        (run through tmo.bat, GPU solo)
#   godot --path godot --script res://world/nebula_wake_capture.gd -- OUT still [max|high|low] [W H]
# still: OUT/still_<tier>_c<radius>_<off|on|off_again>.jpg, one frozen moment, the frigate and capital mid-line with
# their trails: no wake points, the wake on, then no points again (the two offs must match: the wake is the only change).
# Camera radius defaults to 170, the battle camera (Artoo on PR 1181); 120 is the closer extra view.
# shots: OUT/<tier>_c<radius>_<off|on>/f0000.jpg ... one per frame at a fixed 30 frames a second, plus OUT/<tier>_meta.json.
# timing: OUT/results.json; three sessions, wake off and on alternated, max, high and low, 1080p and 4K (scaling 2.0),
# ships flying the line on a loop the whole time, plus a held worst case (every wake point live at full strength).
const SCENE = preload("res://scenes/battle/battle.tscn")
const API = preload("res://rules/battle_api.gd")
const BL = preload("res://world/board_look.gd")
const PG = preload("res://render/placeholder_guard.gd")
const CLIP_FRAMES := 330      # 11 s at 30 frames a second
const FRIGATE_GO := 30        # the frigate's flight starts at 1 s and takes 3.5 s
const CAPITAL_GO := 105       # the capital's at 3.5 s and takes 4 s
var out := ""
var mode := ""
var rows: Array = []
var b = null
var focus := Vector3.ZERO
var cam_r := 170.0           # the battle camera's radius (c170); shots and still take another as their last argument


# VS_DRAFT=1: a cloud draft on a checkout without the built hulls; placeholder blocks are allowed and every picture
# says DRAFT in its meta. Never a sheet for Ryan.
var draft := OS.get_environment("VS_DRAFT") == "1"


func _stop() -> bool:
	return false if draft else PG.stop_if_any()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var argv := OS.get_cmdline_user_args()
	out = argv[0]
	mode = argv[1]
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	AudioServer.set_bus_mute(0, true)
	if mode == "still":
		var tier := argv[2] if argv.size() > 2 else "max"
		var size := Vector2i(int(argv[3]), int(argv[4])) if argv.size() > 4 else Vector2i(1280, 720)
		if argv.size() > 5: cam_r = float(argv[5])
		if not await _battle(tier, true): return
		await _still(tier, size)
		await _close()
	elif mode == "shots":
		var tier := argv[2] if argv.size() > 2 else "max"
		var size := Vector2i(int(argv[3]), int(argv[4])) if argv.size() > 4 else Vector2i(1920, 1080)
		if argv.size() > 5: cam_r = float(argv[5])
		for wake in [false, true]:
			if not await _battle(tier, wake): return
			await _clip(tier, wake, size)
			await _close()
	else:
		for session in 3:
			for tier in (["max", "high", "low"] if session % 2 == 0 else ["low", "high", "max"]):
				for wake in ([false, true] if session % 2 == 0 else [true, false]):
					if not await _battle(tier, wake): return
					await _timing(tier, wake, session + 1)
					await _close()
					if _stop(): return
		var f := FileAccess.open(out.path_join("results.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(rows, "  ") + "\n")
	if draft: quit(0)
	else: PG.finish(0)


func _battle(tier: String, wake: bool) -> bool:
	BL.set_look("cine", false)
	BL.tactical = false
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.use_taa = false
	b = SCENE.instantiate()
	b.external = true
	b.args["quality"] = tier
	b.args["no-tips"] = true
	b.args["nebula_wake"] = "true" if wake else "false"
	root.add_child(b)
	b.args["shots"] = true
	b.tips_off = true
	Engine.max_fps = 0
	var sc := {"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["ascendant", "harrow", "warden", "warden"], "fac": "ithar",
		"obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return false
	api.new_battle_scenario(sc, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B.biome = {"rock": "ice", "planet": 7, "station": "ring"}
	b.battle_cfg = sc
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > int(OS.get_environment("VS_WARM_MS") if OS.get_environment("VS_WARM_MS") != "" else "120000"):
			push_error("Battle warmup timed out")
			quit(1)
			return false
		await process_frame
	for i in 60: await process_frame
	if _stop(): return false
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.set_process_unhandled_input(false)
	b.set_process_input(false)
	b.set_process(false)
	b.cam.screen_shift = 0.0
	focus = _nebula_focus()
	b.cam.a = -PI / 2.0
	b.cam.b = 0.85
	b.cam.r = cam_r
	b.cam.t = focus
	b.cam.snap()
	# Same start for both runs: the gas clock, the storm bolts' schedule and the effect clock.
	_zero_clock()
	return true


func _zero_clock() -> void:
	var living = b.world._living
	var was := float(living.clock)
	for burst in living._storm_bursts: burst.next = float(burst.next) - was
	for bolt in living.bolts: bolt.start = float(bolt.start) - was
	living.clock = 0.0


# The nebula hex nearest the middle of the calm gas, kept clear of the storm so the storm stays as it is.
func _nebula_focus() -> Vector3:
	# The densest calm gas: most nebula hexes close by, fewest storm hexes.
	var neb: Array = b.world._terr_pts["neb"]
	var storm: Array = b.world._terr_pts["storm"]
	var best: Vector3 = neb[0]
	var best_score := -1e9
	for p in neb:
		var score := 0.0
		for q in neb: if (q as Vector3).distance_to(p) < 30.0: score += 1.0
		for q in storm: if (q as Vector3).distance_to(p) < 45.0: score -= 3.0
		if score > best_score:
			best_score = score
			best = p
	return Vector3(best.x, 0.0, best.z)


func _pair() -> Array:
	var ships: Array = []
	for sv in b.views.values():
		if str(sv.u.get("side", "")) == "player" and not bool(sv.u.get("squadron", false)) and sv.squad_kind.is_empty():
			ships.append(sv)
	ships.sort_custom(func(x, y): return float(x.L) < float(y.L))
	return [ships[0], ships[-1]]   # the smallest (a frigate) and the largest (the capital)


# The scripted line for frame k: a frigate crossing west to east above the focus, the capital east to west below it.
func _fly(pair: Array, k: int, loop := false) -> void:
	var legs := [[pair[0], FRIGATE_GO, 105, Vector3(-38, 0, -10), Vector3(38, 0, -6)], [pair[1], CAPITAL_GO, 120, Vector3(36, 0, 14), Vector3(-36, 0, 10)]]
	for leg in legs:
		var sv = leg[0]
		var kk := k % CLIP_FRAMES if loop else k
		var t := clampf(float(kk - int(leg[1])) / float(leg[2]), 0.0, 1.0)
		t = t * t * (3.0 - 2.0 * t)
		var a: Vector3 = focus + leg[3]
		var z: Vector3 = focus + leg[4]
		var p := a.lerp(z, t)
		sv.position = Vector3(p.x, sv.position.y, p.z)
		var d := z - a
		sv.rotation.y = atan2(-d.z, d.x)
		sv.cur_yaw = sv.rotation.y


func _clip(tier: String, wake: bool, size: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = size
	root.content_scale_size = Vector2i.ZERO
	root.scaling_3d_scale = 1.0
	var pair := _pair()
	_fly(pair, 0)
	for i in 20: await process_frame
	if b.world._living._wake != null: b.world._living._wake.forget()
	var dir := out.path_join("%s_c%d_%s" % [tier, int(cam_r), "on" if wake else "off"])
	DirAccess.make_dir_recursive_absolute(dir)
	_zero_clock()
	for k in CLIP_FRAMES:
		_fly(pair, k)
		await process_frame
		await RenderingServer.frame_post_draw
		preload("res://tools/picture_provenance.gd").save_jpg(root.get_texture().get_image(), dir.path_join("f%04d.jpg" % k), 0.92, preload("res://tools/picture_provenance.gd").capture_stage())
	var meta := {"draft": draft, "camera_r": cam_r, "tier": tier, "actual_quality": b.world.quality, "wake": wake, "frames": CLIP_FRAMES, "fps": 30, "size": [size.x, size.y],
		"focus": [focus.x, focus.z], "frigate": [str(pair[0].u.get("cls")), str(pair[0].code), pair[0].L], "capital": [str(pair[1].u.get("cls")), str(pair[1].code), pair[1].L],
		"adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"wake_sha256": FileAccess.get_sha256("res://world/nebula_wake.gd"), "living_sha256": FileAccess.get_sha256("res://world/world_living.gd"),
		"wake_materials": b.world._living._wake_mats.size()}
	var f := FileAccess.open(out.path_join("%s_c%d_%s_meta.json" % [tier, int(cam_r), "on" if wake else "off"]), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  ") + "\n")
	print("WAKE1079 clip ", JSON.stringify(meta))


# One frozen moment, the wake's only difference: the frigate and the capital halfway along their lines with the trail
# each would leave behind it, wake points held at a fixed strength, and the same frame with no points.
func _still(tier: String, size: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = size
	root.content_scale_size = Vector2i.ZERO
	var pair := _pair()
	_fly(pair, 0)
	var living = b.world._living
	var wake = living._wake
	for i in 30: await process_frame
	# frigate 70 of 105 frames along its line, capital 60 of 120
	_fly_one(pair[0], 0, 70.0 / 105.0)
	_fly_one(pair[1], 1, 60.0 / 120.0)
	living.set_process(false)
	for ship in b.views.values(): ship.set_process(false)
	b.gfx.manual = true
	var trails := [[pair[0], 0, 70.0 / 105.0], [pair[1], 1, 60.0 / 120.0]]
	wake.forget()
	for t in trails:
		var sv = t[0]
		var r: float = clampf(float(sv.L) * wake.R_PER_L, wake.R_MIN, wake.R_MAX)
		var leg: Array = _legs()[t[1]]
		var a: Vector3 = focus + leg[0]
		var z: Vector3 = focus + leg[1]
		var dir := Vector2(z.x - a.x, z.z - a.z).normalized()
		# the trail each ship would leave: segments back from the bow, newest end 0.1 s old, each 0.45 s older
		var bow: Vector3 = sv.visual_position() + Vector3(dir.x, 0.0, dir.y) * float(sv.L) * wake.BOW
		wake.lay_trail(bow, dir, r, wake.points / 2, 0.1, 0.45)
	wake.held = false
	var trail: Array = wake._ring.duplicate(true)
	# Let the board and its look finish settling (its grid fades in after a build; run 3's Low pair caught that fade).
	for i in 180: await process_frame
	# off, on, then off again: the two offs must match, so the only change in the pair is the wake.
	for pass_i in 3:
		wake.forget()
		if pass_i == 1:
			wake._ring = trail.duplicate(true)
		wake.apply(living._wake_mats)
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		var tag: String = ["off", "on", "off_again"][pass_i]
		preload("res://tools/picture_provenance.gd").save_jpg(root.get_texture().get_image(), out.path_join("still_%s_c%d_%s.jpg" % [tier, int(cam_r), tag]), 0.95, preload("res://tools/picture_provenance.gd").capture_stage())
	print("WAKE1079 still ", tier, " ", size)


func _legs() -> Array:
	return [[Vector3(-38, 0, -10), Vector3(38, 0, -6)], [Vector3(36, 0, 14), Vector3(-36, 0, 10)]]


func _fly_one(sv, i: int, t: float) -> void:
	var leg: Array = _legs()[i]
	var a: Vector3 = focus + leg[0]
	var z: Vector3 = focus + leg[1]
	var p := a.lerp(z, t)
	sv.position = Vector3(p.x, sv.position.y, p.z)
	sv.rotation.y = atan2(-(z - a).z, (z - a).x)
	sv.cur_yaw = sv.rotation.y


func _timing(tier: String, wake: bool, session: int) -> void:
	var pair := _pair()
	for scale in [1.0, 2.0]:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1920, 1080)
		root.content_scale_size = Vector2i(1920, 1080)
		root.scaling_3d_scale = scale
		for case in (["flying", "held"] if wake else ["flying"]):
			var living = b.world._living
			if case == "held":
				living._wake.hold_full(b.world._terr_pts["neb"])
			var k := 0
			for i in 180:
				_fly(pair, k, true); k += 1
				await process_frame
			var frame := []; var gpu := []; var cpu := []
			var last := Time.get_ticks_usec()
			var start := last
			while frame.size() < 720 or Time.get_ticks_usec() - start < 8000000:
				_fly(pair, k, true); k += 1
				await process_frame
				await RenderingServer.frame_post_draw
				var now := Time.get_ticks_usec()
				frame.append((now - last) / 1000.0); last = now
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
				cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
			var row := {"tier": tier, "actual_quality": b.world.quality, "wake": wake, "case": case, "session": session,
				"resolution": "1080p" if scale == 1.0 else "4K", "frames": frame.size(), "frame_ms": _stats(frame), "gpu_ms": _stats(gpu),
				"render_cpu_ms": _stats(cpu), "adapter": RenderingServer.get_video_adapter_name(),
				"wake_sha256": FileAccess.get_sha256("res://world/nebula_wake.gd"), "living_sha256": FileAccess.get_sha256("res://world/world_living.gd")}
			rows.append(row)
			print("WAKE1079 ", JSON.stringify(row))


func _close() -> void:
	b.queue_free()
	b = null
	for i in 5: await process_frame


func _stats(values: Array) -> Dictionary:
	values.sort()
	return {"median": values[values.size() / 2], "p95": values[int(values.size() * 0.95)], "p99": values[int(values.size() * 0.99)], "max": values[-1]}
