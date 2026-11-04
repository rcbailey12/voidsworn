extends SceneTree
# Review-only scene: real Board, ShipView, battle lights and CameraRig.
# Run against the PC's built Godot project for its painted ship resources.
# No live station path or game asset is changed by this preview.

var stage: Node3D
var camera: Camera3D
var out: String
var source: String
var ship_view: Script
var records: Array = []


class ReviewBoard extends RefCounted:
	func view() -> Dictionary:
		var hexes: Array = []
		for q in range(-5, 6):
			for r in range(-4, 5):
				hexes.append({"q": q, "r": r})
		return {"hexes": hexes, "terrain": {}, "zones": {}}

	func world_info() -> Dictionary:
		return {"seed": 61}


func _init() -> void:
	_run.call_deferred()


func _require(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		quit(1)
		# Stop immediately rather than letting a missing real asset become a proxy.
		assert(ok, message)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	_require(args.size() == 2, "Expected shots folder and source Godot folder")
	out = args[0]
	source = args[1]
	# Offscreen 4K viewport keeps review captures independent of monitor size.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3840, 2160)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	stage = Node3D.new()
	viewport.add_child(stage)
	_world()
	var board = load(source.path_join("render/board.gd")).new()
	stage.add_child(board)
	board.build(ReviewBoard.new())
	board.set_process(false)
	if board.get("_look_layer") != null:
		board.get("_look_layer").hide()
	ship_view = load(source.path_join("render/ship_view.gd"))
	var rig = load(source.path_join("render/camera_rig.gd")).new()
	rig.input_enabled = false
	rig.keyboard_enabled = false
	stage.add_child(rig)
	rig.set_process(false)
	camera = rig
	camera.current = true
	for variant in ["fleet", "refinery"]:
		for size in [46.0, 30.0]:
			var assembly := Node3D.new()
			stage.add_child(assembly)
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			var err := doc.append_from_file(out.path_join(variant + "_blockout.glb"), state)
			_require(err == OK, "Station GLB import: " + variant)
			var station := doc.generate_scene(state)
			_require(station != null, "Station scene: " + variant)
			assembly.add_child(station)
			station.scale = Vector3.ONE * size / 46.0
			station.position.y = 3.0
			var bs := Vector3(0, 4.5, -6) if variant == "fleet" else Vector3(0, 5, -20)
			var frig := Vector3(-13, 5, 10) if variant == "fleet" else Vector3(-32, 5, 0)
			if size == 30.0 and variant == "fleet":
				# Compact berths cannot fit these classes. Show them alongside,
				# rather than clipping real ships into the scaled-down cradle.
				bs = Vector3(0, 4.5, -20)
				frig = Vector3(-32, 5, 0)
			var battleship := _ship(assembly, "H10_23", "Battleship", 33.6, bs)
			var frigate := _ship(assembly, "H7_23", "Frigate", 10.4, frig)
			for facing in [0, 180]:
				assembly.rotation.y = deg_to_rad(float(facing))
				# Keep the service-face berth proof at 46 / 0. On the working
				# face, place the Frigate alongside so it is not hidden by the tower.
				frigate.position = Vector3(-32, 5, 0) if facing == 180 else frig
				for distance in [170.0, 90.0]:
					rig.a = -PI / 2.0
					rig.b = 0.98
					rig.r = distance
					rig.t = Vector3.ZERO
					rig.snap()
					for frame in 12:
						await process_frame
					await RenderingServer.frame_post_draw
					var name := "%s_godot_%d_%d_%s_4k.png" % [variant, int(size), facing, "battle" if distance == 170.0 else "close"]
					var image := viewport.get_texture().get_image()
					_require(image != null and image.get_size() == Vector2i(3840, 2160), "4K viewport capture failed")
					_require(image.save_png(out.path_join(name)) == OK, "Screenshot save failed")
					records.append({"image": name, "station_length": size, "lift": 3,
						"facing_degrees": facing, "camera_radius": distance,
						"camera_beta": 0.98, "camera_fov": camera.fov,
						"battleship_length": battleship.get("L"), "frigate_length": frigate.get("L")})
			assembly.free()
			print("[station-preview] PASS ", variant, " length=", size, " real ships=33.6,10.4")
	var report := FileAccess.open(out.path_join("godot_preview.json"), FileAccess.WRITE)
	_require(report != null, "Preview report could not be opened")
	report.store_string(JSON.stringify({"phase": "R91 review scene only", "captures": records}, "  ") + "\n")
	report.close()
	stage.free()
	ship_view.clear_static()
	quit(0)


func _ship(parent: Node3D, code: String, cls: String, length: float, pos: Vector3) -> Node3D:
	var manifest: Dictionary = ship_view.manifest()
	_require(manifest.get("ships", {}).has(code), "Required painted A4 ship missing: " + code)
	var node = ship_view.new()
	parent.add_child(node)
	node.setup({"id": code, "fac": "hegemony", "cls": cls, "code": code,
		"L": length, "facing": 0}, pos, true)
	node.set_process(false)
	_require(node.a4, "Real ship did not load: " + code)
	for engine in node.engines:
		(engine as Node3D).hide()
	# Verify fitted world dimensions, including the full mesh and its kit.
	var bounds := AABB()
	var first := true
	for mesh in node.meshes:
		var mi := mesh as MeshInstance3D
		var fitted: AABB = mi.global_transform * mi.get_aabb()
		bounds = fitted if first else bounds.merge(fitted)
		first = false
	_require(absf(bounds.size.x - length) < 0.01, "Ship fitted at the wrong length: " + code)
	return node


func _world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.009, 0.013, 0.023)
	var world := WorldEnvironment.new()
	world.environment = env
	stage.add_child(world)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	stage.add_child(key)
	stage.add_child(fill)
	load(source.path_join("render/look.gd")).apply(env, key, fill, {"quality": "max"})
	key.directional_shadow_max_distance = 600.0
