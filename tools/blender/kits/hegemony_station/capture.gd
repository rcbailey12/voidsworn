extends SceneTree
# Review GLB in an isolated GPU viewport. No installed station or profile writes.
const SV = preload("res://render/ship_view.gd")
const PG = preload("res://render/placeholder_guard.gd")
const CAM = preload("res://render/camera_rig.gd")
const LOOK = preload("res://render/look.gd")
const PROBE = preload("inspect.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func label_at(parent: Node, text: String, pos: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("e8e3d8"))
	parent.add_child(label)

func label_bands(parent: Node) -> void:
	# Keep captions readable even where the close view crops bright structure.
	for area in [Rect2(0, 0, 1280, 78), Rect2(0, 665, 1280, 55)]:
		var band := ColorRect.new()
		band.position = area.position
		band.size = area.size
		band.color = Color("10161d")
		parent.add_child(band)

func screen_bounds(camera: Camera3D, box: AABB) -> Array:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in range(8):
		var point := camera.unproject_position(box.get_endpoint(i))
		lo = lo.min(point)
		hi = hi.max(point)
	return [lo.x, lo.y, hi.x, hi.y]

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: printerr("Expected review output folder"); quit(1); return
	var out: String = args[0]
	if not PROBE.imports_ready(): quit(1); return
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		printerr("GPU capture requires forward_plus, not the headless dummy renderer"); quit(1); return
	var inputs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("game_inputs.json")))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("10161d")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.60, 0.68, 0.80)
	env.environment.ambient_light_energy = 0.65
	world.add_child(env)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.look_at(LOOK.KEY_DIR)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	fill.look_at(LOOK.FILL_DIR)
	LOOK.apply(env.environment, key, fill)
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(out.path_join("station_T2_review.glb"), state) != OK:
		printerr("Cannot load review station GLB"); quit(1); return
	var station := doc.generate_scene(state) as Node3D
	world.add_child(station)
	station.position.x = -22.0
	# Hold its passive animation at frame zero for like-for-like comparisons.
	for player in station.find_children("*", "AnimationPlayer", true, false):
		player.stop()
	var camera := CAM.new()
	world.add_child(camera)
	camera.set_process(false)
	camera.input_enabled = false
	camera.current = true
	camera.r = float(inputs.camera.radius)
	camera.b = float(inputs.camera.beta)
	camera.t = Vector3(4, 0, 0)
	camera.snap()
	var overlay := Control.new()
	viewport.add_child(overlay)
	var report := {"scope": "GPU studio comparisons, not the station-map performance gate",
		"renderer": RenderingServer.get_current_rendering_method(), "size": [1280, 720],
		"station_bounds": {}, "comparisons": []}
	var box := PROBE.mesh_bounds(station, world)
	report.station_bounds = {"size": [box.size.x, box.size.y, box.size.z]}
	var rows: Array = inputs.comparisons.duplicate(true)
	for row in rows:
		var sv := SV.new()
		world.add_child(sv)
		sv.setup(row.unit, Vector3(61, 0, 0))
		if PG.stop_if_any(): return
		sv.set_process(false)
		sv.rotation.y = 0.0
		if sv.ring: sv.ring.visible = false
		var cls: String = row["class"]
		var name := "game_compare170_" + cls.to_lower().replace("-", "_")
		for mode in (["170", "low"] if cls == "Cruiser" else ["170"]):
			for child in overlay.get_children(): child.free()
			label_bands(overlay)
			camera.r = float(inputs.camera.radius)
			camera.b = float(inputs.camera.beta) if mode == "170" else 1.32
			camera.snap()
			label_at(overlay, "station_T2  |  " + cls + "  " + str(row.code), Vector2(24, 14), 26)
			label_at(overlay, "FLEET STATION / REVIEW ONLY / CAMERA " + ("170" if mode == "170" else "170 LOW ANGLE"), Vector2(24, 48), 18)
			label_at(overlay, "Actual ShipView %.2f u | Uniform station %.2f u | GPU studio, no live swap" % [sv.L, maxf(box.size.x, maxf(box.size.y, box.size.z))], Vector2(24, 674), 18)
			for i in range(24): await process_frame
			await RenderingServer.frame_post_draw
			var path := name + ".png" if mode == "170" else "game_compare_low.png"
			var picture := viewport.get_texture().get_image()
			if picture.save_png(out.path_join(path)) != OK: printerr("Cannot write " + path); quit(1); return
			report.comparisons.append({"class": cls, "code": sv.code, "length": sv.L,
				"camera_radius": camera.r, "beta": camera.b, "file": path,
				"station_pixels": screen_bounds(camera, box),
				"ship_pixels": screen_bounds(camera, PROBE.mesh_bounds(sv.hull, world)),
				"ship_position": [sv.position.x, sv.position.y, sv.position.z]})
			print("T2 GPU CAPTURE ", path)
		sv.free()
	# A true game-zoom close view, deliberately a partial station crop.
	for child in overlay.get_children(): child.free()
	label_bands(overlay)
	camera.r = 60.0
	camera.b = float(inputs.camera.beta)
	camera.a = -2.08
	camera.t = Vector3(-24, 12, 9)
	camera.snap()
	label_at(overlay, "station_T2 | CAMERA 60 / FINE SERVICE DETAIL", Vector2(24, 14), 26)
	label_at(overlay, "FLEET STATION / REVIEW ONLY / PARTIAL CLOSE VIEW", Vector2(24, 48), 18)
	label_at(overlay, "Small fittings, varied drums, one observation pane. Preview materials; no live swap.", Vector2(24, 674), 18)
	for i in range(24): await process_frame
	await RenderingServer.frame_post_draw
	if viewport.get_texture().get_image().save_png(out.path_join("game_detail60.png")) != OK:
		printerr("Cannot write camera 60 close view"); quit(1); return
	report.detail = {"file": "game_detail60.png", "camera_radius": camera.r, "beta": camera.b,
		"alpha": camera.a, "target": [camera.t.x, camera.t.y, camera.t.z], "framing": "partial close view"}
	var file := FileAccess.open(out.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	world.free()
	SV.clear_static()
	quit(0)
