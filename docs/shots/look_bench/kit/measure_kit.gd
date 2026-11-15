extends SceneTree
# Actual raster proof, separate from the world/ship comparison bench.
# Exercises the production emitters and shaders at both render resolutions.
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const RIG := preload("res://render/camera_rig.gd")
var vp: SubViewport
var stage: Node3D
var cam
var fx
var out: String
var records: Array = []
const RIBBON_KINDS := {"plume": 0, "idle": 1, "lance": 2, "sputter": 3,
	"ion": 5, "doom": 6, "pulsar": 7, "needle": 8, "tendril": 9}

func _initialize() -> void:
	_run.call_deferred()

func draw() -> void:
	await process_frame
	await RenderingServer.frame_post_draw

func save_frame(name: String) -> void:
	await draw()
	var img := vp.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))

func _run() -> void:
	out = OS.get_environment("KIT_MEASURE_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	stage = Node3D.new()
	vp.add_child(stage)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	we.environment.background_mode = Environment.BG_COLOR
	we.environment.background_color = Color.BLACK
	we.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment.glow_enabled = false
	stage.add_child(we)
	cam = RIG.new()
	stage.add_child(cam)
	cam.input_enabled = false
	cam.keyboard_enabled = false
	cam.current = true
	for height in [1080, 2160]:
		vp.size = Vector2i(height * 16 / 9, height)
		for radius in [170, 60, 26]:
			cam.r = radius
			cam.t = Vector3.ZERO
			cam.snap()
			for test in ["spark", "spark_no_floor", "shell", "gauss", "gauss_low",
				"plume", "idle", "lance", "sputter", "ion", "doom", "pulsar", "needle", "tendril"]:
				fx = FX.new()
				stage.add_child(fx)
				fx.manual = true
				fx.setup({"camera": cam, "quality": "low" if test == "gauss_low" else "max", "shake": 0.0, "seed": 367, "min_px": 0.0 if test == "spark_no_floor" else 1.0})
				await fx.warmup(cam)
				fx.step(1.0)
				# Future booking lets the first frame be captured at exact age zero.
				var t0: float = fx.now + 0.2
				if test.begins_with("spark"):
					# Excessive world length deliberately tests the screen cap.
					fx.stk(Vector3(-18, 0, 0), t0, 1.0, Color(1, 0.5, 0.1), 5.0, 0.8, 0.12, 1, Vector3(180, 0, 0), 1.8)
				elif test == "shell":
					fx.stk(Vector3(-18, 0, 0), t0, 1.0, Color(1, 0.6, 0.2), 8.0, 9.0, 0.6, 0, Vector3(90, 0, 0))
				elif test in ["gauss", "gauss_low"]:
					WEAP._gauss_wake(fx, Vector3(-12, 0, 0), Vector3(12, 0, 0), t0, Color(0.6, 1.0, 0.5), 1.0)
				else:
					fx.rib(Vector3(-12, 0, 0), Vector3.RIGHT, 24.0, t0, 0.7, Color(0.4, 0.9, 0.5), 2.4, 1.6, 1.6, int(RIBBON_KINDS[test]))
				var times: Array = [0.20] if not test.begins_with("gauss") else [0.0, 1.0/60.0, 2.0/60.0, 3.0/60.0]
				for i in times.size():
					fx.step(t0 + float(times[i]) - fx.now)
					var name := "%s_h%d_c%d_f%d" % [test, height, radius, i]
					await save_frame(name)
					records.append({"file": name + ".png", "test": test, "height": height, "camera": radius, "age": times[i],
						"ribbon_kind": RIBBON_KINDS.get(test, -1),
						"projected_axis": [cam.unproject_position(Vector3.ZERO), cam.unproject_position(Vector3.RIGHT)]})
				stage.remove_child(fx)
				fx.queue_free()
				await process_frame
	var file := FileAccess.open(out.path_join("raster_frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records, " "))
	FX.clear_static()
	print("KIT_RASTER_DONE")
	quit(0)
