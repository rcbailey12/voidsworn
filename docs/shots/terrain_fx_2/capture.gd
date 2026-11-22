extends SceneTree
const SCENE = preload("res://scenes/battle/battle.tscn")
const API = preload("res://rules/battle_api.gd")
const BL = preload("res://world/board_look.gd")
const PG = preload("res://render/placeholder_guard.gd")
const PROV = preload("res://tools/picture_provenance.gd")
var out = ""
var timing = false
var rows = []
var failed = false
func _initialize():
	_run.call_deferred()
func _run():
	var argv = OS.get_cmdline_user_args()
	out = argv[0]
	timing = argv.size() > 1 and argv[1] == "timing"
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	# Fixed TIME is applied to world materials in memory after warm-up.
	var cases = [
		["graveyard", "deathless", "graveyard", "dense", 4107, {"rock":"carbon", "planet":5, "station":"spire"}],
		["station", "hegemony", "station", "open", 4102, {"rock":"iron", "planet":4, "station":"rig"}],
		["planet", "hegemony", "planet", "open", 4105, {"rock":"stone", "planet":3, "station":"ring"}],
		["deadstar", "ithar", "storm", "deadstar", 4110, {"rock":"ice", "planet":7, "station":"ring"}],
		["storm", "ithar", "storm", "open", 4103, {"rock":"ice", "planet":7, "station":"ring"}],
		["belt", "corsair", "belt", "open", 4101, {"rock":"stone", "planet":0, "station":"rig"}]]
	for c in cases:
		if OS.get_environment("FX100_ONLY") != "" and c[0] not in OS.get_environment("FX100_ONLY").split(","): continue
		if timing and c[0] not in ["storm", "graveyard"]: continue
		var tiers = ["max", "low"] if timing or (argv.has("quality-shots") and c[0] in ["graveyard", "deadstar"]) else ["max"]
		for tier in tiers:
			await _case(c, tier)
			if failed: quit(1); return
	var f = FileAccess.open(out.path_join("results.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  "))
	PG.finish(0)
func _case(c, tier):
	BL.set_look("cine", false)
	BL.tactical = false
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	root.use_taa = false
	var b = SCENE.instantiate()
	b.external = true
	b.args["quality"] = tier
	b.args["no-tips"] = true
	root.add_child(b)
	b.args["shots"] = true
	b.tips_off = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var sc = {"seed":c[4], "sector":1, "admiral":"vex", "fleet":["penitent","harrow","warden","warden"], "fac":c[1], "obj":"rout", "shape":c[3], "map":c[2], "dep":"line", "kind":"battle"}
	var api = API.new()
	api.load_rules()
	api.new_battle_scenario(sc, c[4])
	# Task 10 stacking case: the same real storm generator with its nebula condition.
	if timing and c[0] == "storm":
		api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond":{"terr":"neb"}})
		api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B.biome = c[5].duplicate()
	b.battle_cfg = sc
	b.begin_with(api)
	print("FX100 START ", c[0], " ", tier)
	var t0 = Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > 120000:
			push_error("Battle warmup timed out"); failed = true; return
		await process_frame
	while b.world._living != null and b.world._living._chunk_task >= 0:
		await process_frame
	for i in 120: await process_frame
	if PG.stop_if_any(): failed = true; return
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.set_process_unhandled_input(false)
	b.cam.screen_shift = 0.0
	var kind = "storm" if c[0] == "storm" else ("neb" if c[0] == "belt" else "debris")
	var ps = b.world._terr_pts[kind]
	var focus = ps[0] if not ps.is_empty() else Vector3.ZERO
	if c[0] == "deadstar": focus = b.world._well
	var living = b.world._living
	if not timing:
		living.set_process(false)
		living.clock = 0.08
		for burst in living._storm_bursts: burst.next = 1000.0
		for bolt in living.bolts: bolt.start = -10.0
		living._process(0.0)
		for ship in b.views.values(): ship.set_process(false)
		b.world.set_process(false)
		_freeze(b.world)
	# Put a real hull at the review hex. This changes presentation only, never rules.
	var subject = b.views.values()[0]
	if not timing: subject.position = focus
	var prefix = c[0] if tier == "max" else c[0]+"_low"
	var lights = _lights(b.world)
	var metadata = {"case":c[0], "tier":tier, "seed":c[4], "lights":lights, "camera_radius":170, "focus":[focus.x,focus.y,focus.z], "notes":b.world.notes, "actual_quality":b.world.quality, "vsync":DisplayServer.window_get_vsync_mode(), "msaa_3d":root.msaa_3d, "screen_aa":root.screen_space_aa, "ship_count":b.views.size()}
	if timing:
		for scale in [1.0, 2.0]:
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(1920,1080)
			root.content_scale_size = Vector2i(1920,1080)
			root.scaling_3d_scale = scale
			_camera(b, focus, 170)
			for pass_i in 2:
				for i in 180: await process_frame
				var frame = []; var gpu = []; var cpu = []
				var last = Time.get_ticks_usec()
				var measure_start = last
				while frame.size() < 720 or Time.get_ticks_usec() - measure_start < 8000000:
					await process_frame
					await RenderingServer.frame_post_draw
					var now = Time.get_ticks_usec()
					frame.append((now-last)/1000.0); last=now
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
					cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
				var row = metadata.duplicate(true)
				row.merge({"pass":pass_i+1,"resolution":"1080p" if scale==1.0 else "4K", "frames":frame.size(), "viewport":[root.size.x,root.size.y], "scaling_3d":root.scaling_3d_scale, "frame_ms":_stats(frame), "gpu_ms":_stats(gpu), "render_cpu_ms":_stats(cpu)})
				rows.append(row)
				print("FX100 BENCH ", JSON.stringify(row))
			if scale == 1.0: await _shot(c[0]+"_"+tier+"_1080p")
	else:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(3840,2160)
		root.content_scale_size = Vector2i.ZERO
		root.scaling_3d_scale = 1.0
		for look in (["cine","tac"] if c[0] not in ["belt","storm"] else ["today","holo"]):
			BL.set_look("cine" if look=="tac" else look, false)
			BL.tactical = look=="tac"
			b.board.apply_look(false)
			for radius in ([170.0,60.0] if look=="cine" else [170.0]):
				_camera(b, focus, radius)
				for i in 80: await process_frame
				await _shot(prefix+"_"+look+"_c"+str(int(radius)))
		rows.append(metadata)
		if c[0] == "deadstar" and OS.get_cmdline_user_args().has("guard-proof"):
			BL.set_look("cine", false)
			BL.tactical = false
			b.board.apply_look(false)
			subject.position = Vector3(focus.x + 60.0, 0.0, focus.z)
			b.gfx.manual = true
			_camera(b, subject.position, 170.0)
			for i in 60: await process_frame
			await _shot("well_guard_on")
			for child in living.get_children():
				if child is MeshInstance3D and child.material_override is ShaderMaterial and "bool foreground" in child.material_override.shader.code:
					child.visible = false
			for i in 30: await process_frame
			await _shot("well_guard_off")
			metadata["guard_ship_pixel"] = [b.cam.unproject_position(subject.visual_position()).x,b.cam.unproject_position(subject.visual_position()).y]
	print("FX100 DONE ", c[0], " ", tier, " ", lights)
	b.queue_free()
	for i in 5: await process_frame
func _camera(b, focus, radius):
	b.cam.a = -PI/2
	b.cam.b = 0.98
	b.cam.r = radius
	b.cam.t = focus
	b.cam.snap()
func _stats(values):
	values.sort()
	return {"median":values[values.size()/2], "p95":values[int(values.size()*0.95)], "max":values[-1]}
func _lights(n):
	var result = {"omni":0,"fog_injecting":0,"fog_volumes":0}
	if n is OmniLight3D:
		result.omni += 1
		if n.light_volumetric_fog_energy > 0: result.fog_injecting += 1
	if n is FogVolume: result.fog_volumes += 1
	for child in n.get_children():
		var sub = _lights(child)
		for key in result: result[key] += sub[key]
	return result
func _shot(name):
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	preload("res://tools/picture_provenance.gd").save_jpg(img, out.path_join(name+".jpg"), 0.94, preload("res://tools/picture_provenance.gd").capture_stage())
	print("FX100 SHOT ", name, " ", img.get_size())

func _freeze(n):
	if n is GeometryInstance3D and n.material_override is ShaderMaterial:
		var m = n.material_override.duplicate()
		m.shader = m.shader.duplicate()
		m.shader.code = m.shader.code.replace("TIME", "0.0")
		n.material_override = m
	for child in n.get_children(): _freeze(child)