extends SceneTree
# Issue 463: isolate the real production flash/body calls at camera 170, at 60 Hz, against black.
# godot --path godot --fixed-fps 60 --script res://bench/death_small_measure.gd -- OUT
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const CAM := preload("res://render/camera_rig.gd")
const LOOK := preload("res://render/look.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	var out := OS.get_cmdline_user_args()[0]
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
	for event in ["wing", "frigate", "destroyer", "cruiser", "frigate_body", "destroyer_body"]:
		if OS.get_cmdline_user_args().size() > 1 and not OS.get_cmdline_user_args()[1].split(",").has(event): continue
		for reduced in [false, true]:
			if reduced and event.ends_with("body"): continue
			var fx := FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "reduce_flashing": reduced})
			await fx.warmup(cam)
			var warmed = fx
			warmed.visible = false
			fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "reduce_flashing": reduced})
			fx.now = 0.0
			fx.rng.seed = 11
			seed(2070)
			var measured_ship: Node3D = null
			if event == "wing":
				var ship := Node3D.new()
				measured_ship = ship
				world.add_child(ship)
				var mi := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(4.0, 1.0, 2.0)
				mi.mesh = mesh
				ship.add_child(mi)
				fx.add_ship("wing", ship, {"cls": "Squadron", "meshes": [mi]})
				fx.death("wing")
			elif event.ends_with("body"):
				# Let the real break caller choose the body row, then isolate its material. No copied size or life.
				var ship := Node3D.new()
				measured_ship = ship
				world.add_child(ship)
				var mi := MeshInstance3D.new()
				var mesh := BoxMesh.new()
				mesh.size = Vector3(10.0, 2.0, 3.0)
				mi.mesh = mesh
				ship.add_child(mi)
				fx.add_ship("body", ship, {"cls": "Destroyer" if event == "destroyer_body" else "Frigate", "meshes": [mi]})
				var source = fx.ship("body")
				source.dead = true
				DEATH._break_up(fx, source, "blast", Color.WHITE)
				var found_body := false
				for step in 60:
					fx.step(1.0 / 60.0)
					for node in fx.get_children():
						if node is MeshInstance3D and node.get_meta("fx_picture_kind", "") == "impact": found_body = true
					if found_body: break
				if not found_body:
					push_error("The production break did not spawn its body")
					quit(2)
					return
				for node in fx.get_children():
					if node is Node3D:
						node.visible = node is MeshInstance3D and node.get_meta("fx_picture_kind", "") == "impact"
						if node.visible:
							var body_mat := (node as MeshInstance3D).material_override as ShaderMaterial
							body_mat.set_shader_parameter("born", 0.0)
				fx.now = 0.0
			else:
				DEATH._core_flash(fx, Vector3.ZERO, 2.0, 70.0, Color.WHITE, null, Vector3.ZERO, null, "small" if event == "frigate" else event)
			var name: String = event + ("_reduced" if reduced else "")
			var folder := out.path_join(name)
			DirAccess.make_dir_recursive_absolute(folder)
			var materials := []
			for node in fx.get_children():
				if node is MeshInstance3D and node.visible and node.material_override is ShaderMaterial:
					var mat: ShaderMaterial = node.material_override
					materials.append({"name": node.name, "life": mat.get_shader_parameter("lifetime"), "px": mat.get_shader_parameter("min_pixels")})
			report[name] = materials
			for frame in 64:
				fx.step(0.0 if frame == 0 else 1.0 / 60.0)
				if event == "wing" and frame == 1:
					for node in fx.get_children():
						if node is MeshInstance3D and node.get_meta("fx_picture_kind", "") == "flash":
							var mat: ShaderMaterial = node.material_override
							report[name].append({"name": node.name, "life": mat.get_shader_parameter("lifetime"), "px": mat.get_shader_parameter("min_pixels")})
				# Wing puff follows the spark; measure the layers separately with the same production calls.
				if event == "wing":
					for node in fx.get_children():
						if node is MeshInstance3D and node.has_meta("fx_picture_kind") and node.get_meta("fx_picture_kind") != "flash": node.visible = false
				await process_frame
				await RenderingServer.frame_post_draw
				preload("res://tools/picture_provenance.gd").save_png(vp.get_texture().get_image().get_region(Rect2i(640, 300, 640, 480)), folder.path_join("%03d.png" % frame), preload("res://tools/picture_provenance.gd").capture_stage())
			fx.release()
			if measured_ship != null: measured_ship.queue_free()
			world.remove_child(fx)
			fx.queue_free()
			warmed.release()
			world.remove_child(warmed)
			warmed.queue_free()
			await process_frame
			print("DEATH_SMALL_MEASURE ", name)
	var file := FileAccess.open(out.path_join("materials.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, " "))
	file.close()
	print("DEATH_SMALL_MEASURE_DONE")
	quit()
