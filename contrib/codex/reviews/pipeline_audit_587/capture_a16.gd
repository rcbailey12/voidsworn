extends SceneTree
# Issue 557. Args: authored export folder, legacy folder, moved folder, output folder.
# Uses the production ShipView loader and FX damage/death paths. Saves each installed scene beside its GLB.
const FX = preload("res://fx/fx.gd")
const SV = preload("res://render/ship_view.gd")
const LOOK = preload("res://render/look.gd")
const BREACH = preload("res://fx/fx_breach.gd")
const DEATH = preload("res://fx/fx_death.gd")
const CAMRIG = preload("res://render/camera_rig.gd")
var world: Node3D
var vp: SubViewport
var cam: Camera3D
var fx
var out: String
var result := {}

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2: quit(2); return
	out = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_mute(0, true)
	vp = SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.017, 0.024)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	world.add_child(key); world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	cam = CAMRIG.new()
	cam.input_enabled = false
	cam.keyboard_enabled = false
	cam.set_process(false)
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	var title := Label.new()
	title.text = "corsair_A16 | issue 587 | UNPAINTED DIAGNOSTIC, EXPORT CHECK FAILED"
	title.position = Vector2(20, 16)
	title.add_theme_font_size_override("font_size", 20)
	vp.add_child(title)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "camera": cam, "shake": 0.0, "reduce_flashing": true})
	for pair in [["corsair_A16", args[0]]]:
		var tag: String = pair[0]
		var folder: String = pair[1]
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		if doc.append_from_file(folder.path_join("C19_51.glb"), state) != OK: quit(1); return
		var model := doc.generate_scene(state)
		var packed := PackedScene.new()
		packed.pack(model)
		var installed: String = folder.path_join("installed.scn")
		ResourceSaver.save(packed, installed)
		model.free()
		SV.manifest()["ships"]["C19_51"] = {"res": installed}
		var sv = SV.new()
		world.add_child(sv)
		sv.setup({"id": "C", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "hp": 100, "maxHp": 100, "size": 0.8}, Vector3.ZERO, true)
		sv.set_process(false)
		fx.add_ship("C", sv, {"faction": "corsair", "cls": "Battle-barge", "size": 0.8, "code": sv.code})
		var s = fx.ship("C")
		print("INSTALLED %s code=%s authored=%s seams=%s" % [tag, sv.code, s.hull.authored, s.hull.seams])
		await _camera(170)
		await fx.warmup(cam)
		await _steps(150)
		await _shots(tag, "intact")
		fx.sync_ship("C", {"hp": 12.0, "maxHp": 100.0, "sh": [0, 0, 0, 0],
			"sec": {"prow": {"hp": 3.6, "max": 30.0}, "mid": {"hp": 4.8, "max": 40.0}, "eng": {"hp": 3.6, "max": 30.0}}})
		# A controlled section opening, same entry and seed for all three exported assets.
		var hit: Dictionary = s.hull.ray(s.hull.c + Vector3.UP * s.hull.L, Vector3.DOWN)
		var opening = BREACH.hole(null, hit.p, hit.n, s.hull.L * 0.14, 0.8, s.hull.L * 0.008, 73.0)
		opening.cut = s.hull.H * 0.65
		opening.D = s.hull.H * 0.5
		s._ents = [[], [opening], []]
		s._dmg_request(fx)
		await _steps(150)
		while s._dmg_task >= 0 or s.has_meta("cut_task"): await _steps(1)
		await _shots(tag, "wound")
		var job: Dictionary = s.get_meta("cut_job", {})
		result[tag] = {"L": s.hull.L, "exterior_triangles": s.hull.tri_count, "seams": str(s.hull.seams), "cut_triangles": 0, "piece_triangles": []}
		result[tag]["export"] = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("C19_51_export.json")))
		for pc in job.get("out", []):
			var count := 0
			for sd in pc.surfs: result[tag].cut_triangles += sd.arrays[Mesh.ARRAY_INDEX].size() / 3
			for sd in pc.surfs: count += sd.arrays[Mesh.ARRAY_INDEX].size() / 3
			result[tag].piece_triangles.append(count)
		s.set_meta("death_timeline", DEATH.DeathTimeline.new(true, 1, "capital")) # existing fx.death reads this key before the first kill
		fx.death("C", "blast")
		var guard := 0
		while fx.dstate.wrecks.is_empty() and guard < 1800:
			await _steps(1)
			guard += 1
		if fx.dstate.wrecks.is_empty(): quit(1); return
		await _steps(100)
		await _shots(tag, "death")
		await _steps(340)
		await _shots(tag, "cooled")
		fx.clear_wreck("C")
		fx.remove_ship("C")
		sv.queue_free()
		await _steps(160)
	FileAccess.open(out.path_join("interiors_cost.json"), FileAccess.WRITE).store_string(JSON.stringify(result, "  "))
	print("INTERIORS_PROBE done ", out)
	SV.clear_static()
	quit(0)

func _camera(radius: float) -> void:
	cam.a = -PI / 2.0
	cam.b = cam.home_b
	cam.r = radius
	cam.t = Vector3.ZERO
	cam.snap()
	for i in 3: await RenderingServer.frame_post_draw

func _steps(count: int) -> void:
	for i in count:
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw

func _shots(tag: String, stage: String) -> void:
	for radius in [170, 60]:
		await _camera(radius)
		print("CAPTURE ", tag, " ", stage, " radius=", radius)
		vp.get_texture().get_image().save_png(out.path_join("%s_%s_camera%d.png" % [tag, stage, radius]))
