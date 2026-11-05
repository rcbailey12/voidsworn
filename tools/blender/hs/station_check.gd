extends SceneTree
# Isolated import check, not a live board swap. Run with --headless --script.

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 4 and args[0] == "--measure":
		await measure(args[1], args[2], args[3])
		return
	if args.size() == 4 and args[0] == "--review":
		await review(args[1], args[2], args[3])
		return
	if args.size() != 1:
		push_error("Expected the station render folder")
		quit(2)
		return
	for variant in ["fleet", "refinery"]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var suffix := "detail" if FileAccess.file_exists(args[0].path_join(variant + "_detail.glb")) else "blockout"
		var err := doc.append_from_file(args[0].path_join(variant + "_" + suffix + ".glb"), state)
		if err != OK:
			push_error("Station GLB import failed: " + variant)
			quit(1)
			return
		var station := doc.generate_scene(state)
		if station == null:
			quit(1)
			return
		root.add_child(station)
		var meshes := station.find_children("*", "MeshInstance3D", true, false)
		var lo := Vector3.INF
		var hi := -Vector3.INF
		var batteries := 0
		var triangles := 0
		var material_names := {}
		for node in meshes:
			var mi := node as MeshInstance3D
			for surface in mi.mesh.get_surface_count():
				var arrays := mi.mesh.surface_get_arrays(surface)
				triangles += (arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else arrays[Mesh.ARRAY_VERTEX].size()) / 3
				var material := mi.get_active_material(surface)
				material_names[material.resource_name] = true
				if suffix == "detail":
					assert(material is StandardMaterial3D and material.albedo_texture != null and material.normal_texture != null, "Missing baked paint")
			if str(mi.name).begins_with("battery_"):
				batteries += 1
			var aabb := mi.get_aabb()
			for corner in 8:
				var p := mi.global_transform * aabb.get_endpoint(corner)
				if not p.is_finite():
					quit(1)
					return
				lo = lo.min(p)
				hi = hi.max(p)
		var dimensions := hi - lo
		if absf(dimensions.x - 46.0) > 0.01 or dimensions.y < 19.0 or batteries != (4 if variant == "fleet" else 0):
			push_error("Wrong station dimensions or turret export: " + variant)
			quit(1)
			return
		for size in [30.0, 46.0]:
			station.scale = Vector3.ONE * size / 46.0
			var fitted_lo := Vector3.INF
			var fitted_hi := -Vector3.INF
			for node in meshes:
				var mi := node as MeshInstance3D
				for corner in 8:
					var p := mi.global_transform * mi.get_aabb().get_endpoint(corner)
					fitted_lo = fitted_lo.min(p)
					fitted_hi = fitted_hi.max(p)
			if absf((fitted_hi - fitted_lo).x - size) > 0.01:
				quit(1)
				return
		print("[station-check] PASS ", variant, " dimensions=", dimensions,
			" battery_nodes=", batteries, " triangles=", triangles, " materials=", material_names.size(), " compact_length=30 full_length=46")
		if suffix == "detail":
			var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0].path_join("detail_audit.json")))
			assert(triangles == int(report.variants[variant].triangles_roundtrip), "Godot triangle count differs")
			assert(material_names.size() == 3, "Expected three export material slots")
			for line in ["a", "b"]:
				var wreck := imported(args[0].path_join(variant + "_break_" + line + ".glb"))
				var pieces := wreck.find_children("*", "MeshInstance3D", true, false)
				assert(pieces.size() == 2, "Expected two named break pieces")
				wreck.free()
		station.free()
	quit(0)


func imported(path: String) -> Node3D:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(path, state) == OK, "GLB import failed: " + path)
	var scene := doc.generate_scene(state)
	assert(scene != null)
	return scene


func review(folder: String, source: String, suffix: String) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(3840, 2160)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	var stage := Node3D.new()
	vp.add_child(stage)
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
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.fov = 45
	var view = load(source.path_join("render/ship_view.gd"))
	var captures: Array = []
	for variant in ["fleet", "refinery"]:
		for length in [46.0, 30.0]:
			var assembly := Node3D.new()
			stage.add_child(assembly)
			assembly.rotation.y = PI
			var station := imported(folder.path_join(variant + "_" + suffix + ".glb"))
			assembly.add_child(station)
			station.scale = Vector3.ONE * length / 46
			station.position.y = 3
			for code in ["H10_23", "H7_23"]:
				var node = view.new()
				assembly.add_child(node)
				var capital: bool = code == "H10_23"
				var pos := Vector3(0, 4.5, -6 if variant == "fleet" and length == 46 else -20) if capital else Vector3(-32, 5, 0)
				node.setup({"id": code, "fac": "hegemony", "cls": "Battleship" if capital else "Frigate",
					"code": code, "L": 33.6 if capital else 10.4, "facing": 0}, pos, true)
				node.set_process(false)
				assert(node.a4, "Required real ship reference missing")
				for engine in node.engines: engine.hide()
			for shot in ["plan", "battle", "close", "macro46", "macro30", "service", "side", "below"]:
				var distance := 170.0 if shot in ["plan", "battle"] else 90.0
				if shot == "macro46": distance = 46
				if shot == "macro30": distance = 30
				var target := Vector3(0, 3, 0)
				var direction := Vector3(0, cos(0.98), sin(0.98))
				if shot == "plan": direction = Vector3.UP
				if shot == "side": direction = Vector3(0, 0.05, 1)
				if shot == "service": direction = Vector3(0, cos(0.98), -sin(0.98))
				if shot == "below": direction = Vector3(0, -0.7, 0.7).normalized()
				if shot.begins_with("macro"): target = Vector3(0, 6, 0)
				camera.look_at_from_position(target + direction * distance, target, Vector3.FORWARD if shot == "plan" else Vector3.UP)
				for frame in 24: await process_frame
				await RenderingServer.frame_post_draw
				var file := "%s_%s_%d_%s_4k.png" % [variant, suffix, int(length), shot]
				assert(vp.get_texture().get_image().save_png(folder.path_join(file)) == OK)
				captures.append({"image": file, "length": length, "radius": distance,
					"fov": camera.fov, "beta": 0.98, "real_ships": [33.6, 10.4]})
				if length == 46 and shot in ["plan", "side", "below"]:
					for child in assembly.get_children():
						if child != station: child.hide()
					camera.look_at_from_position(target + direction * 75, target, Vector3.FORWARD if shot == "plan" else Vector3.UP)
					for frame in 12: await process_frame
					await RenderingServer.frame_post_draw
					assert(vp.get_texture().get_image().save_png(folder.path_join(variant + "_" + suffix + "_isolated_" + shot + ".png")) == OK)
					for child in assembly.get_children(): child.show()
			assembly.free()
		if suffix == "detail":
			for line in ["a", "b"]:
				var wreck := imported(folder.path_join(variant + "_break_" + line + ".glb"))
				stage.add_child(wreck)
				wreck.rotation.y = PI
				wreck.position.y = 3
				for mesh in wreck.find_children("*", "MeshInstance3D", true, false):
					if str(mesh.name).contains("detached"):
						mesh.position += Vector3(0, 3, -8)
				camera.look_at_from_position(Vector3(25, 42, 55), Vector3(0, 3, 0))
				for frame in 24: await process_frame
				await RenderingServer.frame_post_draw
				assert(vp.get_texture().get_image().save_png(folder.path_join(variant + "_break_" + line + "_4k.png")) == OK)
				var cap_target := Vector3(19.5, 3, 3) if variant == "fleet" and line == "b" else Vector3(13, 3, -5)
				if variant == "refinery": cap_target = Vector3(16, 3, 2) if line == "a" else Vector3(-13, 3, -5)
				camera.look_at_from_position(cap_target + Vector3(14, 10, 18), cap_target)
				var inspection := DirectionalLight3D.new()
				stage.add_child(inspection)
				inspection.rotation = camera.rotation
				inspection.light_energy = 1.3
				for frame in 24: await process_frame
				await RenderingServer.frame_post_draw
				assert(vp.get_texture().get_image().save_png(folder.path_join(variant + "_break_" + line + "_close_4k.png")) == OK)
				inspection.free()
				wreck.free()
	var file := FileAccess.open(folder.path_join(suffix + "_captures.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(captures, "  ") + "\n")
	stage.free()
	view.clear_static()
	print("[station-review] PASS ", suffix, " captures=", captures.size())
	quit(0)


# GPU timestamps include the real painted fleet. Alternate visibility so the
# reported addition is paired with the same fleet and lighting, at 4K.
func measure(folder: String, source: String, suffix: String) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var vp := SubViewport.new()
	vp.size = Vector2i(3840, 2160)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	root.add_child(vp)
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	var stage := Node3D.new()
	vp.add_child(stage)
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
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.current = true
	camera.fov = 45
	camera.look_at_from_position(Vector3(0, cos(0.98), sin(0.98)) * 250, Vector3.ZERO)
	var fleet := Node3D.new()
	stage.add_child(fleet)
	var view = load(source.path_join("render/ship_view.gd"))
	for i in 20:
		var capital := i < 2
		var node = view.new()
		fleet.add_child(node)
		var pos := Vector3((i % 5 - 2) * 34, 3, (floori(i / 5.0) - 1.5) * 35)
		node.setup({"id": "measure_%d" % i, "fac": "hegemony",
			"cls": "Battleship" if capital else "Frigate", "code": "H10_23" if capital else "H7_23",
			"L": 33.6 if capital else 10.4, "facing": 0}, pos, true)
		node.set_process(false)
		assert(node.a4, "Required real painted ship failed to load")
		for engine in node.engines: engine.hide()
	var rows: Array = []
	for variant in ["fleet", "refinery"]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		assert(doc.append_from_file(folder.path_join(variant + "_" + suffix + ".glb"), state) == OK)
		var station := doc.generate_scene(state)
		stage.add_child(station)
		station.position.y = 3
		var pairs: Array = []
		for repetition in 5:
			var pair := {}
			for visible in ([false, true] if repetition % 2 == 0 else [true, false]):
				station.visible = visible
				for frame in 100: await process_frame
				var gpu: Array[float] = []
				var cpu: Array[float] = []
				var wall: Array[float] = []
				var previous := Time.get_ticks_usec()
				for frame in 180:
					await process_frame
					await RenderingServer.frame_post_draw
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid()))
					cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid()))
					var now := Time.get_ticks_usec()
					wall.append((now - previous) / 1000.0)
					previous = now
				gpu.sort()
				cpu.sort()
				wall.sort()
				pair["station" if visible else "fleet_only"] = gpu[gpu.size() / 2]
				pair["station_cpu" if visible else "fleet_only_cpu"] = cpu[cpu.size() / 2]
				pair["station_frame" if visible else "fleet_only_frame"] = wall[wall.size() / 2]
			pair["delta_ms"] = pair.station - pair.fleet_only
			pair["cpu_delta_ms"] = pair.station_cpu - pair.fleet_only_cpu
			pair["frame_delta_ms"] = pair.station_frame - pair.fleet_only_frame
			pairs.append(pair)
			print("[station-measure] ", variant, " pair ", repetition, " ", pair)
		var deltas: Array = pairs.map(func(p): return p.delta_ms)
		deltas.sort()
		rows.append({"variant": variant, "pairs": pairs, "median_delta_ms": deltas[2],
			"paired_range_ms": [deltas[0], deltas[4]], "target_ms": 0.35, "ceiling_ms": 1.0,
			"interpretation": "Below timing noise if the paired range crosses zero"})
		var capture := vp.get_texture().get_image()
		assert(capture.save_png(folder.path_join(variant + "_" + suffix + "_20ships_4k.png")) == OK)
		station.free()
	var result := {"adapter": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(), "resolution": [3840, 2160],
		"ships": 20, "warmup": 100, "samples_per_pair_state": 180, "pairs": 5,
		"metric": "paired median viewport GPU ms; station shown minus hidden", "rows": rows}
	var file := FileAccess.open(folder.path_join(suffix + "_gpu.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n")
	stage.free()
	view.clear_static()
	quit(0)
