extends SceneTree
# Issue 1373: Chorus trail before/after (cloud, compatibility renderer, code-built craft; trails are the same for any craft).
#   copy to godot/trail_shot_tmp.gd, then: godot --rendering-driver opengl3 --path godot --script res://trail_shot_tmp.gd -- OUT.png [old]
const WING := preload("res://render/squadron_wing.gd")
const LOOK := preload("res://render/look.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var old := args.size() > 1 and args[1] == "old"
	root.size = Vector2i(1200, 700)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.01, 0.012, 0.02)
	world.add_child(env)
	var key := DirectionalLight3D.new(); var fill := DirectionalLight3D.new()
	world.add_child(key); world.add_child(fill)
	LOOK.apply(env.environment, key, fill)
	var w = WING.new()
	world.add_child(w)
	w.setup("chorus", "fighter", 1.6, 6, 0.3)
	if old:
		w.trail_life = 0.65
		w.trail_mat.set_shader_parameter("width_k", 0.065)
		w.trail_mat.set_shader_parameter("alpha_k", 0.22)
		w.trail_mat.set_shader_parameter("life", 0.65)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.fov = 30.0
	for f in 40:
		w.position = Vector3(f * 0.25, 0, 0)
		w.step(1.0 / 20.0)
		await process_frame
	cam.look_at_from_position(w.position + Vector3(-2.0, 22.0, 14.0), w.position + Vector3(-2.0, 0, 0), Vector3.UP)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	quit()
