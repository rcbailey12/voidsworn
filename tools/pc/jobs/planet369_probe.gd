extends SceneTree
# Real 20-ship battle. Candidate materials are installed only in this probe;
# applying planet369_board.patch is a separate, scope-gated production change.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const PL := preload("res://world/world_planet.gd")
const PG := preload("res://render/placeholder_guard.gd")
const GATE := preload("res://bench/scene_gate.gd")
var out := ""
var args := {}
var caption: Label

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	for i in range(0, a.size()-1, 2): args[a[i].trim_prefix("--")] = a[i+1]
	out = str(args.get("out", ""))
	if out == "":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func shot(name: String, full_frame := false) -> void:
	caption.text = name
	caption.position = Vector2(20,16) if full_frame else Vector2(340,196)
	await frames(8)
	await RenderingServer.frame_post_draw
	if PG.stop_if_any(): return
	var img := root.get_texture().get_image()
	if full_frame:
		img.resize(1280,720,Image.INTERPOLATE_LANCZOS)
	else:
		# True pixel crop, no enlargement of camera 170 detail.
		img = img.get_region(Rect2i((img.get_width()-1280)/2,(img.get_height()-720)/2,1280,720))
	img.save_png(out.path_join(name+".png"))
	print("R01_SHOT ", name)

func median(values: Array) -> float:
	values.sort()
	return float(values[values.size()/2]) if not values.is_empty() else -1.0

func _run() -> void:
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size",22)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_outline_size",8)
	overlay.add_child(caption)
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["shots"] = true
	root.add_child(b)
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return
	# Inputs to the real scenario constructor, never a hand-typed battle state.
	var sc := {"seed":5,"sector":3,"admiral":"vex","fleet":GATE.FLEET.duplicate(),
		"enemies":GATE.ENEMIES.duplicate(),"fac":"corsair","obj":"rout",
		"shape":"open","map":"planet","dep":"line","kind":"battle"}
	api.new_battle_scenario(sc,5)
	b.battle_cfg = sc
	b.begin_with(api)
	var start := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec()-start > 120000:
			printerr("R01 warm-up timeout")
			quit(1)
			return
		await process_frame
	if PG.stop_if_any(): return
	if b.board.planet_node == null:
		printerr("Real planet scenario made no board planet")
		quit(1)
		return
	b.hud.visible = false
	b.cam.input_enabled = false
	b.cam.keyboard_enabled = false
	var p: MeshInstance3D = b.board.planet_node
	var cold_ms := -1
	if OS.get_environment("VS_PLANET_REMIX") != "0":
		var air: MeshInstance3D = null
		for ch in p.get_parent().get_children():
			if ch != p and ch is MeshInstance3D and ch.mesh is SphereMesh and ch.position.is_equal_approx(p.position):
				air = ch
		if air == null:
			printerr("Real board planet has no air shell")
			quit(1)
			return
		var t0 := Time.get_ticks_msec()
		await PL.install_rocky(p,air,p.global_position+b.board.sun_dir.normalized()*100000.0)
		cold_ms = Time.get_ticks_msec()-t0
		if p.get_meta("planet_code","") != "R01":
			quit(1)
			return
	await frames(180)
	var home: Vector3 = b.cam.t
	var home_beta: float = b.cam.b
	for radius in [170.0,60.0,26.0]:
		b.cam.t = home if radius == 170 else Vector3(p.position.x,p.position.y+(p.mesh as SphereMesh).radius,p.position.z)
		b.cam.r = radius
		b.cam.snap()
		await shot("R01_c%d" % int(radius))
	b.cam.r = 640.0
	b.cam.b = 0.01
	b.cam.t = Vector3.ZERO
	b.cam.snap()
	await shot("R01_board_top",true)
	b.cam.r = (p.mesh as SphereMesh).radius*3.2
	b.cam.b = 1.15
	b.cam.t = Vector3(p.position.x,0,p.position.z)
	b.cam.snap()
	await shot("R01_planet",true)
	await frames(240)
	await shot("R01_cloud_motion",true)
	# Additional planet-and-rock cost at 4K. The binding #207 gate is run by
	# the wrapper as well; this scene does not pretend to replace that gate.
	root.scaling_3d_scale = 2.0
	b.cam.r = 170.0
	b.cam.b = home_beta
	b.cam.t = home
	b.cam.snap()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid,true)
	await frames(180)
	var times := []
	var frame_times := []
	var last := Time.get_ticks_usec()
	for i in 360:
		await RenderingServer.frame_post_draw
		times.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		var now := Time.get_ticks_usec()
		frame_times.append((now-last)/1000.0)
		last = now
	var report := {"seed":5,"ships":api.R.B.units.size(),"candidate":cold_ms >= 0,
		"cold_decode_mip_upload_ms":cold_ms,"camera":170,"render_pixels":[3840,2160],
		"gpu_median_ms":median(times),"frame_median_ms":median(frame_times),
		"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),
		"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"surface_gate":"Additional planet scene only; see gate/scene_gate.json for R116"}
	var f := FileAccess.open(out.path_join("R01_metrics.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("R01_PROBE_DONE ",JSON.stringify(report))
	PG.finish(0)
