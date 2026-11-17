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

func annotation_points(camera: Camera3D, station: Node3D, manifest: Dictionary, fit: Dictionary, kinds: Array) -> Array:
	var candidates: Array = manifest.detail_geometry.duplicate(true)
	var scale_factor: float = manifest.uniform_fit.scale
	for row in candidates:
		row.factor = scale_factor
	for row in manifest.modules:
		if row.kind == "viewport":
			var box: Dictionary = fit.modules[row.id]
			# Module annotations target a real panel or pod face, not its volume centre.
			var anchors: Array = []
			for axis in range(3):
				for end in [box.min, box.max]:
					var centre: Array = []
					for k in range(3): centre.append(float(end[k]) if k == axis else (float(box.min[k])+float(box.max[k]))*0.5)
					anchors.append(centre)
			candidates.append({"kind": row.kind, "module": row.id, "anchors": anchors, "factor": 1.0})
	var result: Array = []
	for kind in kinds:
		var best := {}
		var best_score := INF
		for row in candidates:
			if row.kind != kind: continue
			for anchor in row.anchors:
				var centre := Vector3(anchor[0], anchor[1], anchor[2]) * float(row.factor)
				# Blender Z up to the GLB's Godot Y up, plus the studio placement.
				var point := Vector3(centre.x, centre.z, -centre.y) + station.position
				if camera.is_position_behind(point): continue
				var pixel := camera.unproject_position(point)
				if pixel.x < 170 or pixel.x > 1110 or pixel.y < 115 or pixel.y > 625: continue
				var query := PhysicsRayQueryParameters3D.create(camera.global_position, point + (point-camera.global_position).normalized()*0.06)
				var hit := station.get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty() or (hit.position as Vector3).distance_to(point)>0.20: continue
				var score := camera.global_position.distance_to(point) + pixel.distance_to(Vector2(640, 360)) * 0.025
				if score < best_score:
					best_score = score
					best = {"kind": kind, "module": row.module, "pixel": [pixel.x, pixel.y], "world": [point.x, point.y, point.z], "visible_surface": true}
		if not best.is_empty(): result.append(best)
	return result

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: printerr("Expected review output folder"); quit(1); return
	var out: String = args[0]
	if not PROBE.imports_ready(): quit(1); return
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		printerr("GPU capture requires forward_plus, not the headless dummy renderer"); quit(1); return
	var inputs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("game_inputs.json")))
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("manifest.json")))
	var fit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("fit.json")))
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
	# Isolated review-only collision meshes let labels reject hidden anchors.
	# They do not enter the live board or change the station GLB.
	for child in station.find_children("*", "MeshInstance3D", true, false):
		var body := StaticBody3D.new()
		world.add_child(body)
		body.global_transform = child.global_transform
		var shape := CollisionShape3D.new()
		shape.shape = child.mesh.create_trimesh_shape()
		body.add_child(shape)
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
			label_at(overlay, "FLEET STATION / RUN 5 / REVIEW ONLY / CAMERA " + ("170" if mode == "170" else "170 LOW ANGLE"), Vector2(24, 48), 18)
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
	# Native camera-60 crops, each showing a connected station system. Project
	# measured geometry anchors for the labelled versions made by sheets.py.
	report.details = []
	for view in [
		{"file": "game_detail60.png", "title": "HABITAT / EVA ACCESS", "target": Vector3(-24, 12, 9), "alpha": -2.08,
		 "kinds": ["airlock", "maintenance_hatch", "service_pipe", "handrail", "viewport", "thruster_quad"]},
		{"file": "game_detail60_docking.png", "title": "DOCKING / CARGO HANDLING", "target": Vector3(-54, 3, 1), "alpha": -2.08,
		 "kinds": ["docking_port", "cargo_crane", "hangar_door", "maintenance_hatch", "handrail", "cargo_pod"]},
		{"file": "game_detail60_systems.png", "title": "POWER / THERMAL / SENSORS", "target": Vector3(-24, 3, 4), "alpha": -0.8,
		 "kinds": ["solar_panel", "cold_radiator", "sensor_mast", "dish_array", "cargo_pod", "maintenance_truss"]},
		{"file": "game_detail60_thermal.png", "title": "LOWER THERMAL / ATTITUDE CONTROL", "target": Vector3(-22, -15, 0), "alpha": -1.0,
		 "kinds": ["radiator", "coolant_manifold", "thruster_quad", "maintenance_truss", "cold_radiator"]},
		{"file": "game_detail60_power.png", "title": "SOLAR POWER OUTRIGGERS", "target": Vector3(-8, 4, 6), "alpha": -0.8,
		 "kinds": ["solar_panel", "maintenance_truss", "thruster_quad"]}]:
		for child in overlay.get_children(): child.free()
		label_bands(overlay)
		camera.r = 60.0
		camera.b = 1.40 if view.file == "game_detail60_thermal.png" else float(inputs.camera.beta)
		camera.a = view.alpha
		camera.t = view.target
		camera.snap()
		label_at(overlay, "station_T2 | CAMERA 60 / " + str(view.title), Vector2(24, 14), 26)
		label_at(overlay, "FLEET STATION / RUN 5 / PREVIEW MATERIALS / PARTIAL CLOSE VIEW", Vector2(24, 48), 18)
		label_at(overlay, "Named working parts; all towers upright. Review only; production paint and live swap pending.", Vector2(24, 674), 18)
		for i in range(24): await process_frame
		await RenderingServer.frame_post_draw
		if viewport.get_texture().get_image().save_png(out.path_join(view.file)) != OK:
			printerr("Cannot write camera 60 close view"); quit(1); return
		var detail := {"file": view.file, "camera_radius": camera.r, "beta": camera.b, "alpha": camera.a,
			"target": [camera.t.x, camera.t.y, camera.t.z], "framing": "partial close view",
			"annotations": annotation_points(camera, station, manifest, fit, view.kinds)}
		report.details.append(detail)
	report.detail = report.details[0]
	var file := FileAccess.open(out.path_join("captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	world.free()
	SV.clear_static()
	quit(0)
