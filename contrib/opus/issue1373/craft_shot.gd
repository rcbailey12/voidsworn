extends SceneTree
# Issue 1373: a close shot of one strike craft as the game builds it (render/squadron_wing.gd setup, with the R362 finish),
# lit by render/look.gd. Cloud use: compatibility renderer under xvfb; the PC's in-game captures stay the done-when evidence.
#   godot --rendering-driver opengl3 --path godot --script res://../contrib/... -- <faction> <kind> <out.png> [glb]
const WING := preload("res://render/squadron_wing.gd")
const LOOK := preload("res://render/look.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var fac: String = args[0] if args.size() > 0 else "ithar"
	var kind: String = args[1] if args.size() > 1 else "fighter"
	var out: String = args[2] if args.size() > 2 else "/tmp/craft.png"
	var glb: String = args[3] if args.size() > 3 else ""
	root.size = Vector2i(1200, 800)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.01, 0.012, 0.02)
	world.add_child(env)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	world.add_child(key)
	world.add_child(fill)
	LOOK.apply(env.environment, key, fill)
	var craft: Node3D
	if glb != "":
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		doc.append_from_file(glb, st)
		craft = Node3D.new()
		var body := doc.generate_scene(st) as Node3D
		craft.add_child(body)
		# fit to unit length like squadron_wing._make_craft, so every shot uses the same camera
		var w := WING.new()
		var box: AABB = w._mesh_bounds(body, body.transform)
		w.free()
		body.transform = Transform3D(Basis.from_scale(Vector3.ONE / box.size.x), -box.get_center() / box.size.x) * body.transform
		WING.finish(craft, fac)
	else:
		var w := WING.new()
		world.add_child(w)
		w.setup(fac, kind, 1.0, 1, 0.0)
		craft = w.craft[0]
		craft.get_parent().remove_child(craft)
		w.free()
	world.add_child(craft)
	craft.position = Vector3.ZERO
	craft.rotation = Vector3.ZERO
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 30.0
	for i in 2:
		await process_frame
	cam.look_at_from_position(Vector3(-0.95, 0.75, -1.15) * 1.25, Vector3(0.02, -0.02, 0.0), Vector3.UP)
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
