extends SceneTree
# Issue 426. Draw the real production calls, isolated against black at the 1080p battle camera.
# Saves 60 Hz frames and material lifetimes so the widest lit extent and clock can be measured independently.
# godot --path godot --fixed-fps 60 --script res://bench/rebake_measure.gd -- OUT
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const CAM := preload("res://render/camera_rig.gd")
const LOOK := preload("res://render/look.gd")
var out := ""

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	world.add_child(key)
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	env.background_color = Color.BLACK
	we.environment = env
	world.add_child(we)
	var cam := CAM.new()
	world.add_child(cam)
	cam.input_enabled = false
	cam.keyboard_enabled = false
	cam.a = -PI / 2.0
	cam.b = 0.98
	cam.r = 170.0
	cam.t = Vector3.ZERO
	cam.snap()
	cam.current = true
	var report := {}
	for event in ["macro", "torpedo", "frigate", "cruiser", "capital", "macro_body", "torpedo_body"]:
		for reduced in [false, true]:
			if OS.get_cmdline_user_args().has("calibrate_macro") and (event != "macro" or reduced): continue
			if OS.get_cmdline_user_args().has("calibrate") and (reduced or event.ends_with("_body")): continue
			if OS.get_cmdline_user_args().has("calibrate_reduced") and (not reduced or event.ends_with("_body")): continue
			if reduced and event.ends_with("_body"): continue
			var fx := FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "reduce_flashing": reduced})
			await fx.warmup(cam)
			# Warm-up also fills particle pools near the camera. Keep its compiled materials, but hide the whole system.
			var warmed = fx
			warmed.visible = false
			fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "reduce_flashing": reduced})
			await process_frame
			fx.now = 0.0
			fx._flashes.clear()
			if event.begins_with("macro") or event.begins_with("torpedo"):
				WEAP._staged_hit(fx, null, Vector3.ZERO, 0.0, event.begins_with("torpedo"))
			else:
				var length: float = {"frigate": 12.0, "cruiser": 24.0, "capital": 36.0}[event]
				DEATH._core_flash(fx, Vector3.ZERO, length * 0.16, 70.0, Color.WHITE)
			var name: String = event + ("_reduced" if reduced else "")
			var folder := out.path_join(name)
			DirAccess.make_dir_recursive_absolute(folder)
			var macro_grid := OS.get_cmdline_user_args().has("calibrate_macro")
			var calibrating := OS.get_cmdline_user_args().has("calibrate") or OS.get_cmdline_user_args().has("calibrate_reduced") or macro_grid
			for frame in (72 if macro_grid else (24 if calibrating else 62)):
				fx.step(0.0 if frame == 0 else 1.0 / 60.0)
				if calibrating:
					fx.now = {"macro": .21, "torpedo": .25, "frigate": .275, "cruiser": .30, "capital": .325}[event] if reduced else 0.0
					RenderingServer.global_shader_parameter_set("scene_t", fx.now)
				for node in fx.get_children():
					if node is MeshInstance3D and String(node.name).begins_with("fx_staged_"):
						node.visible = (String(node.name) == "fx_staged_body") == event.ends_with("_body")
					if calibrating and node is MeshInstance3D and node.material_override is ShaderMaterial:
						var mat := node.material_override as ShaderMaterial
						mat.set_shader_parameter("size_divisor", [1.0, 1.5, 2.0, 3.0, 4.0, 5.0][(frame / 3) % 6] if macro_grid else [0.8, 1.0, 1.2, 1.4, 1.6, 2.0, 2.4, 3.0][frame / 3])
						if macro_grid: mat.set_shader_parameter("intensity", [1.25, 2.0, 3.0, 4.0][frame / 18])
				await process_frame
				await RenderingServer.frame_post_draw
				var image := vp.get_texture().get_image()
				image.save_png(folder.path_join("%03d.png" % frame))
				if frame == 3:
					var materials := []
					for node in fx.get_children():
						if node is MeshInstance3D and node.material_override is ShaderMaterial:
							var mat: ShaderMaterial = node.material_override
							materials.append({"name": node.name, "life": mat.get_shader_parameter("lifetime"), "px": mat.get_shader_parameter("min_pixels")})
					report[name] = materials
			world.remove_child(fx)
			fx.queue_free()
			world.remove_child(warmed)
			warmed.queue_free()
			await process_frame
			print("REBAKE_MEASURE ", name)
	var file := FileAccess.open(out.path_join("materials.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	print("REBAKE_MEASURE_DONE")
	quit()
