extends SceneTree
# Issue 811: the accepted E14 export through the real ShipView, board, camera and battle light.
# godot --path godot --script res://tools/e14_lift_capture.gd -- --glb PATH --out DIR [--tag after]
# Render at 1920x1080, save a 1280x720 centre crop without resizing, so camera 170 keeps true game pixels.
# Run twice after an import; keep the second. No ship files or cache in the project are changed.
const SV := preload("res://render/ship_view.gd")
const HT := preload("res://render/hull_table.gd")
const CAM := preload("res://render/camera_rig.gd")
const BOARD := preload("res://render/board.gd")
const LOOK := preload("res://render/look.gd")
const FX := preload("res://fx/fx.gd")
const PG := preload("res://render/placeholder_guard.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")

class EmptyBoard extends RefCounted:
	func view() -> Dictionary:
		var hexes: Array = []
		for q in range(-3, 4):
			for r in range(-3, 4):
				hexes.append({"q": q, "r": r})
		return {"hexes": hexes, "terrain": {}}
	func world_info() -> Dictionary:
		return {}


func _init() -> void:
	GUARD.arm(self, "e14_lift_capture", 120.0)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func caption(text: String, y: float, size := 22) -> Label:
	var label := Label.new()
	label.text = text
	label.position = Vector2(350, y)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("#f0eade"))
	root.add_child(label)
	return label


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var opts := {}
	for i in range(0, args.size() - 1, 2):
		opts[args[i].trim_prefix("--")] = args[i + 1]
	if not opts.has("glb") or not opts.has("out") or DisplayServer.get_name() == "headless":
		printerr("Needs --glb PATH --out DIR and a GPU renderer")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	await process_frame
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(opts.glb, state) != OK:
		quit(2)
		return
	var source := doc.generate_scene(state)
	var packed := PackedScene.new()
	if packed.pack(source) != OK or ResourceSaver.save(packed, "user://E14_capture.scn") != OK:
		quit(2)
		return
	source.free()
	SV._manifest = {"ships": {"D20_23": {"res": "user://E14_capture.scn"}}}
	var world := Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	key.basis = Basis.looking_at(Vector3(-0.45, -0.70, -0.55).normalized(), Vector3.UP)
	key.light_color = Color(1.0, 0.96, 0.90)
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.basis = Basis.looking_at(Vector3(0.6, -0.2, 0.75).normalized(), Vector3.UP)
	fill.light_color = Color(0.55, 0.65, 0.85)
	fill.light_energy = 0.5
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	key.directional_shadow_max_distance = 600.0
	root.msaa_3d = Viewport.MSAA_4X
	var board := BOARD.new()
	world.add_child(board)
	board.build(EmptyBoard.new())
	board.set_focus(Vector3.ZERO)
	var sv := SV.new()
	world.add_child(sv)
	sv.setup({"id": "E14", "fac": "deathless", "cls": "Destroyer", "facing": 1}, Vector3.ZERO)
	sv.set_process(false)
	sv.set_selected(true)
	sv.set_marker(true)
	if PG.stop_if_any():
		return
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "shake": 0.0})
	fx.add_ship("E14", sv, {"faction": "deathless", "cls": "Destroyer", "meshes": sv.meshes, "flagship": true})
	sv.fx_engines = true
	fx.step(0.0)
	var box := AABB()
	var first := true
	for mi in sv.meshes:
		var bb: AABB = mi.global_transform * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	var lift: float = float(sv.get("hull_lift")) if sv.get("hull_lift") != null else 0.0
	var tag: String = opts.get("tag", "after")
	caption("E14 / D20_23  |  " + tag.to_upper(), 202, 28)
	var detail := caption("", 240)
	caption("Accepted R266 / R269 model | ShipView + battle lights + board | true pixel crop", 826, 18)
	var cam := CAM.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.set_process(false)
	cam.current = true
	cam.focus(sv.call("visual_position") if sv.has_method("visual_position") else sv.position)
	DirAccess.make_dir_recursive_absolute(opts.out)
	for radius in [170.0, 60.0]:
		detail.text = "Camera %d | fitted height %.2f | lowest idle clearance %.3f" % [int(radius), lift, box.position.y - 0.25]
		cam.r = radius
		cam.snap()
		for frame in 24:
			await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image().get_region(Rect2i(320, 180, 1280, 720))
		var file: String = opts.out.path_join("E14_%s_cam%d.png" % [tag, int(radius)])
		if preload("res://tools/picture_provenance.gd").save_png(shot, file, preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
			quit(1)
			return
	var report := {"code": sv.code, "lift": lift, "bounds_min": var_to_str(box.position), "bounds_size": var_to_str(box.size),
		"lowest_idle_clearance": box.position.y - 0.25, "camera_target": var_to_str(cam.t),
		"selection_ring_y": sv.ring.global_position.y, "marker_y": sv.marker.global_position.y,
		"muzzles": fx.ship("E14").hull.points.get("gun", []), "glb_sha256": FileAccess.get_sha256(opts.glb)}
	var output := FileAccess.open(opts.out.path_join("E14_%s.json" % tag), FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "  "))
	output.close()
	print("E14 CAPTURE: ", JSON.stringify(report))
	world.free()
	FX.clear_static()
	SV.clear_static()
	PG.finish()
