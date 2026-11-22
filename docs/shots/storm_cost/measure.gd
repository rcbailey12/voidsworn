extends SceneTree
# Issue 982. PR 976's real storm case, warm-up and two-pass measurement.
# Run through tmo.bat with PC_GPU_MODE=solo. User args: OUT timing|diagnose|shots.
const SCENE = preload("res://scenes/battle/battle.tscn")
const API = preload("res://rules/battle_api.gd")
const BL = preload("res://world/board_look.gd")
const PG = preload("res://render/placeholder_guard.gd")
var out = ""
var mode = ""
var rows = []
func _initialize():
	_run.call_deferred()
func _run():
	var argv = OS.get_cmdline_user_args()
	out = argv[0]
	mode = argv[1]
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	AudioServer.set_bus_mute(0, true)
	for session in (3 if mode == "timing" else 1):
		for tier in (["max", "low"] if session % 2 == 0 else ["low", "max"]):
			await _case(tier, session + 1)
			if PG.stop_if_any(): return
	var f = FileAccess.open(out.path_join("results.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  ") + "\n")
	PG.finish(0)
func _case(tier, session):
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
	var sc = {"seed":4103, "sector":1, "admiral":"vex", "fleet":["penitent","harrow","warden","warden"], "fac":"ithar", "obj":"rout", "shape":"open", "map":"storm", "dep":"line", "kind":"battle"}
	var api = API.new()
	if api.load_rules() != "": quit(1); return
	api.new_battle_scenario(sc, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond":{"terr":"neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B.biome = {"rock":"ice", "planet":7, "station":"ring"}
	b.battle_cfg = sc
	b.begin_with(api)
	var t0 = Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - t0 > 120000: push_error("Battle warmup timed out"); quit(1); return
		await process_frame
	for i in 120: await process_frame
	if PG.stop_if_any(): return
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	b.set_process_unhandled_input(false)
	b.set_process_input(false)
	b.set_process(false)
	b.cam.screen_shift = 0.0
	var living = b.world._living
	var focus = b.world._terr_pts["storm"][0]
	var metadata = {"tier":tier, "session":session, "seed":4103, "storm_hexes":b.world._terr_pts.storm.size(), "nebula_hexes":b.world._terr_pts.neb.size(), "lights":_counts(b.world), "ship_count":b.views.size(), "msaa_3d":root.msaa_3d, "screen_aa":root.screen_space_aa, "living_sha256":FileAccess.get_sha256("res://world/world_living.gd"), "probe_sha256":FileAccess.get_sha256(get_script().resource_path), "adapter":RenderingServer.get_video_adapter_name()}
	metadata["actual_quality"] = b.world.quality
	metadata["ion_shader_sha256"] = FileAccess.get_sha256("res://world/ion_storm.gd")
	metadata["noise_sha256"] = FileAccess.get_sha256("res://world/nebula_noise.res")
	if mode == "shots":
		living.set_process(false)
		living.clock = 0.08
		for burst in living._storm_bursts: burst.next = 1000.0
		for bolt in living.bolts: bolt.start = -10.0; bolt.next = 1000.0
		for ship in b.views.values():
			ship.set_process(false)
			if ship.squad_kind.is_empty(): ship.hull.position = ship.hull_base
		b.gfx.manual = true
		b.gfx.now = 0.08
		RenderingServer.global_shader_parameter_set("scene_t", 0.08)
		b.world.set_process(false)
		_freeze(b.world)
		b.views.values()[0].position = focus
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(3840,2160)
		root.content_scale_size = Vector2i.ZERO
		root.scaling_3d_scale = 1.0
		for radius in [170,60]:
			_camera(b, focus, radius)
			for charged in [false,true]:
				for bolt in living.bolts: bolt.start = -10.0; bolt.mi.visible = false
				if charged:
					var nearest = living.bolts[0]
					for bolt in living.bolts:
						if bolt.pos.distance_to(focus) < nearest.pos.distance_to(focus): nearest = bolt
					nearest.start = living.clock - 0.025
					nearest.mi.visible = true
				living._process(0.0)
				for i in 80: await process_frame
				await RenderingServer.frame_post_draw
				var name = "storm_%s_c%d_%s.jpg" % [tier,radius,"bolt" if charged else "calm"]
				preload("res://tools/picture_provenance.gd").save_jpg(root.get_texture().get_image(), out.path_join(name), 0.96, preload("res://tools/picture_provenance.gd").capture_stage())
		rows.append(metadata)
	else:
		var variants = ["full", "cards_off", "storm_cards_off", "nebula_cards_off", "fog_off", "fog_64", "lights_off"] if mode == "diagnose" and tier == "max" else (["full","cards_off","storm_cards_off","nebula_cards_off","lights_off"] if mode == "diagnose" else ["full"])
		for scale in ([2.0] if mode == "diagnose" else [1.0,2.0]):
			root.mode = Window.MODE_WINDOWED
			root.size = Vector2i(1920,1080)
			root.content_scale_size = Vector2i(1920,1080)
			root.scaling_3d_scale = scale
			_camera(b, focus, 170)
			for variant in variants:
				for child in living.get_children():
					if child is FogVolume: child.visible = variant != "fog_off"
					if child is MultiMeshInstance3D and living.gas_mats.any(func(g): return g[0] == child.material_override):
						var storm = living.storm_mats.has(child.material_override)
						child.visible = not (variant == "cards_off" or (variant == "storm_cards_off" and storm) or (variant == "nebula_cards_off" and not storm))
				for bolt in living.bolts:
					if bolt.light != null: bolt.light.visible = variant != "lights_off"
				if tier == "max": RenderingServer.environment_set_volumetric_fog_volume_size(64 if variant == "fog_64" else 128,128)
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
					row.merge({"variant":variant,"pass":pass_i+1,"resolution":"1080p" if scale==1.0 else "4K", "frames":frame.size(), "viewport":[root.size.x,root.size.y], "scaling_3d":root.scaling_3d_scale, "frame_ms":_stats(frame), "gpu_ms":_stats(gpu), "render_cpu_ms":_stats(cpu)})
					rows.append(row)
					print("STORM982 ", JSON.stringify(row))
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
func _counts(n):
	var result = {"omni":0,"fog_injecting":0,"fog_volumes":0,"storm_cards":0,"nebula_cards":0}
	if n is OmniLight3D:
		result.omni += 1
		if n.light_volumetric_fog_energy > 0: result.fog_injecting += 1
	if n is FogVolume: result.fog_volumes += 1
	if n is MultiMeshInstance3D and n.get_parent().get("gas_mats") is Array:
		var living = n.get_parent()
		if living.gas_mats.any(func(g): return g[0] == n.material_override):
			if living.storm_mats.has(n.material_override): result.storm_cards += n.multimesh.instance_count
			else: result.nebula_cards += n.multimesh.instance_count
	for child in n.get_children():
		var sub = _counts(child)
		for key in result: result[key] += sub[key]
	return result
func _freeze(n):
	if n is GeometryInstance3D and n.material_override is ShaderMaterial and "TIME" in n.material_override.shader.code:
		var m = n.material_override.duplicate()
		m.shader = m.shader.duplicate()
		m.shader.code = m.shader.code.replace("TIME", "0.0")
		n.material_override = m
	for child in n.get_children(): _freeze(child)
