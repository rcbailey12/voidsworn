extends SceneTree
# Production null tracer at every 60 Hz flight sample, then the cooling tail.
# A no-bloom raster measures the shot independently of ships and the sky.
const FX := preload("res://fx/fx.gd")
const W := preload("res://fx/fx_weapons.gd")
const RIG := preload("res://render/camera_rig.gd")
var vp: SubViewport
var records: Array = []

func _initialize() -> void:
	call_deferred("run")

func draw() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func run() -> void:
	var out := OS.get_environment("KIT_MEASURE_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	we.environment.background_mode = Environment.BG_COLOR
	we.environment.background_color = Color.BLACK
	we.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment.glow_enabled = false
	stage.add_child(we)
	var cam = RIG.new()
	stage.add_child(cam)
	cam.input_enabled = false
	cam.keyboard_enabled = false
	cam.current = true
	var from := Vector3(-32,0,0)
	var to := Vector3(32,0,0)
	var flight := from.distance_to(to) / 650.0
	for height in [1080,2160]:
		vp.size = Vector2i(height * 16/9, height)
		for radius in [170,60]:
			cam.r = radius
			cam.t = Vector3.ZERO
			cam.snap()
			for quality in ["max", "low"]:
				for calm in [false,true]:
					var fx = FX.new()
					stage.add_child(fx)
					fx.manual = true
					fx.setup({"camera":cam,"quality":quality,"reduce_flashing":calm,"shake":0.0,"seed":815})
					await fx.warmup(cam)
					fx.step(1.0)
					var start: float = fx.now + 0.2
					W._gauss_wake(fx,from,to,start,fx.faction_info("deathless")["weapon"],1.0)
					var times: Array = []
					for frame in int(ceil(flight*60.0)):
						times.append(frame/60.0)
					times.append_array([flight,flight+0.10,flight+0.30,flight+0.50,flight+0.60,flight+0.71])
					for i in times.size():
						fx.step(start + times[i] - fx.now)
						await draw()
						var image := vp.get_texture().get_image()
						var name := "null_h%d_c%d_%s_%s_f%d.png" % [height,radius,quality,"calm" if calm else "normal",i]
						image.save_png(out.path_join(name))
						var ph := image.duplicate()
						ph.resize(390,219,Image.INTERPOLATE_LANCZOS)
						ph.save_png(out.path_join(name.trim_suffix(".png")+"_phone.png"))
						records.append({"file":name,"height":height,"camera":radius,"quality":quality,"calm":calm,
							"age":times[i],"flight":flight,"from":cam.unproject_position(from),"to":cam.unproject_position(to)})
					fx.release()
					stage.remove_child(fx)
					fx.queue_free()
					await process_frame
	var file := FileAccess.open(out.path_join("raster_frames.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(records," "))
	FX.clear_static()
	vp.queue_free()
	await process_frame
	print("ROUND3_RASTER_DONE frames=%d" % records.size())
	quit(0)
