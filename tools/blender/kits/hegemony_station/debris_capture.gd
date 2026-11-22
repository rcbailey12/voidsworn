extends SceneTree
# Refs #863. Same installed prop, camera and lights as the battle renderer.
const PROPS = preload("res://assets/ships/a4_props.gd")
const CAM = preload("res://render/camera_rig.gd")
const LOOK = preload("res://render/look.gd")

func _init() -> void:
	process_frame.connect(_run,CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(1); return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("080c12")
	world.add_child(env)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.look_at(LOOK.KEY_DIR)
	var fill := DirectionalLight3D.new()
	world.add_child(fill)
	fill.look_at(LOOK.FILL_DIR)
	LOOK.apply(env.environment,key,fill)
	var station := PROPS.station(46.0)
	if station == null or not station.has_node("station_T2_debris"):
		printerr("Capture requires installed painted T2 plus debris"); quit(1); return
	world.add_child(station)
	station.position.y = 3.0
	var debris := station.get_node("station_T2_debris")
	debris.set_process(false)
	for player in station.find_children("*","AnimationPlayer",true,false): player.pause()
	var camera := CAM.new()
	world.add_child(camera)
	camera.set_process(false)
	camera.input_enabled = false
	camera.current = true
	var views := [
		{"name":"station_T2_debris170","radius":170.0,"target":Vector3(-2,-7,14),"beta":0.98,"alpha":0.35,"time":0.0},
		{"name":"station_T2_debris60","radius":60.0,"target":Vector3(-3,-24,51),"beta":0.67,"alpha":0.35,"time":0.0},
		{"name":"station_T2_debris60_t600","radius":60.0,"target":Vector3(-3,-24,51),"beta":0.67,"alpha":0.35,"time":600.0},
		{"name":"station_T2_debris_plan","radius":170.0,"target":Vector3(-2,0,12),"beta":0.12,"alpha":0.35,"time":0.0}]
	var report: Array = []
	for view in views:
		camera.r = view.radius
		camera.t = view.target
		camera.b = view.beta
		camera.a = view.alpha
		camera.snap()
		debris.pose_at(view.time)
		for i in 60: await process_frame
		await RenderingServer.frame_post_draw
		var frame := viewport.get_texture().get_image()
		if preload("res://tools/picture_provenance.gd").save_png(frame,args[0].path_join(view.name+".png"), preload("res://tools/picture_provenance.gd").capture_stage()) != OK: quit(1); return
		var pixels := {}
		for piece in debris.find_children("T2_debris_*", "MeshInstance3D", true, false):
			var point := camera.unproject_position(piece.global_position)
			pixels[piece.name] = [point.x, point.y]
		report.append({"name":view.name,"radius":view.radius,"target":[camera.t.x,camera.t.y,camera.t.z],
			"beta":view.beta,"alpha":view.alpha,"seconds":view.time,
			"piece_centres_px":pixels})
		print("T2 DEBRIS CAPTURE ",view.name)
	var file := FileAccess.open(args[0].path_join("debris_captures.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	quit(0)
