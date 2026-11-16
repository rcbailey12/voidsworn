extends SceneTree
# Runs the actual wing code and unchanged sheet meshes, at camera 170.
# godot --path godot --script ../contrib/codex/issue843/capture.gd -- MODEL_DIR OUT
const WING := preload("res://render/squadron_wing.gd")
var vp: SubViewport
var world: Node3D

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var models := args[0]
	var out := args[1]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(640, 360)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(640, 360))
	vp = SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.012, 0.012, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.look_at_from_position(Vector3(0.45, 0.70, 0.55), Vector3.ZERO)
	key.light_energy = 4.0
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.fov = 45.0
	camera.current = true
	var target := Vector3(-3, 0, 0)
	camera.look_at_from_position(target + Vector3(0, cos(0.98), sin(0.98)) * 170.0, target)
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	if gltf.append_from_file(models.path_join("corsair_KB1CC.glb"), state) != OK:
		quit(1)
		return
	var model: Node3D = gltf.generate_scene(state)
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(models.path_join("corsair_KB1CC.json")))
	var wing := WING.new()
	world.add_child(wing)
	wing.setup("corsair", "bomber", 3.84, 4, 0.0)
	wing.set_process(false)
	for n in wing.craft:
		for child in n.get_children():
			n.remove_child(child)
			child.free()
		var hull := model.duplicate()
		hull.scale = Vector3.ONE / float(metadata.length)
		n.add_child(hull)
	model.free()
	wing.fit_formation()
	var after := wing.rests.duplicate()
	var before: Array = [Vector3.ZERO]
	for i in range(1, 4):
		var row := 1 + (i - 1) / 2
		before.append(Vector3(-0.95 * row, 0.12 if i % 2 else -0.09, (0.95 if i % 2 else -1.02) * row) * wing.length)
	for mode in ["before", "after"]:
		wing.rests = before if mode == "before" else after
		wing.clock = 0.0
		wing.step(0.0)
		# Same geometry, camera, lights and flight phase. Warm up both passes.
		for frame in 8: await RenderingServer.frame_post_draw
		var err := vp.get_texture().get_image().save_png(out.path_join(mode + ".png"))
		if err != OK:
			quit(2)
			return
		print("CAPTURE ", mode, " KB1CC lateral step ", wing.rests[1].z)
	world.free()
	await process_frame
	quit(0)
