extends SceneTree
# Issue 970: the H10 installed bow proof, aimed at IM5's rules slot 3.
# Run with the installed game's --path, --script THIS_FILE -- OUTPUT.png.
const SV = preload("res://render/ship_view.gd")
const LOOK = preload("res://render/look.gd")
const PICTURE = preload("res://tools/picture_provenance.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("IM5 bow capture needs an output PNG path")
		quit(1)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(.01, .014, .022)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	world.add_child(key)
	world.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 45
	cam.near = .05
	cam.far = 2000
	world.add_child(cam)
	cam.current = true
	LOOK.apply(env, key, fill, {"quality": "max"})
	var ship = SV.new()
	world.add_child(ship)
	ship.setup({"id": "ion970", "fac": "hegemony", "cls": "Super-dreadnought", "code": "H4_11", "facing": 0}, Vector3.ZERO)
	if not ship.a4:
		push_error("Installed IM5 hull did not load")
		quit(1)
		return
	ship.ring.visible = false
	for k in 8:
		await process_frame
	var muzzles := ship.find_children("hp_w3_*", "Node3D", true, false)
	if muzzles.is_empty():
		push_error("IM5 ion lens hard point missing")
		quit(1)
		return
	var target: Vector3 = (muzzles[0] as Node3D).global_position
	var offset: Vector3 = Vector3(1, .14, -.16).normalized() * ship.L * .28
	cam.look_at_from_position(target + offset, target, Vector3.UP)
	for k in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := PICTURE.save_png(vp.get_texture().get_image(), args[0], "installed in game")
	print("970 INSTALLED BOW H4_11 result=", result, " target=", target)
	ship.queue_free()
	SV.clear_static()
	quit(0 if result == OK else 1)
