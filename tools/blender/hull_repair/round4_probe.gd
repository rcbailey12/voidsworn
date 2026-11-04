extends "res://probe.gd"
# Issue 146 uses the existing G4 studio and measured frame loop unchanged.


func reference_view(kind: String) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 41.6 * 1.18
	var direction := Vector3(0, 0, 1)
	if kind == "front": direction = Vector3(1, 0, 0)
	if kind == "quarter": direction = Vector3(.65, -.40, .64).normalized()
	if kind == "top_reference": direction = Vector3.UP
	cam.look_at_from_position(direction * 140, Vector3.ZERO, Vector3.FORWARD if kind == "top_reference" else Vector3.UP)


func run() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	out = cfg["shots"]; facets = cfg["factions"]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920, 1080)
	setup_world(); view("battle", 41.6)
	if cfg.get("anchors_only", false):
		var environment: Environment = world.get_node("WorldEnvironment").environment if world.has_node("WorldEnvironment") else null
		for child in world.get_children():
			if child is WorldEnvironment: environment = child.environment
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(.82, .82, .82)
		var anchor := model("C19_51", "today")
		fit(anchor, 41.6)
		for kind in ["quarter", "side_reference", "front", "top_reference", "battle"]:
			if kind == "battle": view("close",41.6)
			else: reference_view(kind)
			await settle(); await snap("anchor_" + kind)
		anchor.free()
		print("[round4] ANCHORS PASS"); quit(0); return
	var blank := await bench("empty")
	for route in cfg["routes"]:
		var ship := model("C19_51", str(route))
		var stats := fit(ship, 41.6)
		for kind in ["battle", "close", "top", "side", "below"]:
			view(kind, 41.6); await settle(); await snap("C19_51_%s_%s" % [route, kind])
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(55, 25, 0); fill.light_energy = 1
		world.add_child(fill)
		view("below", 41.6); await settle(); await snap("C19_51_%s_below_inspect" % route)
		fill.free()
		for kind in ["front", "side_reference", "quarter", "top_reference"]:
			reference_view(kind); await settle(); await snap("C19_51_%s_%s" % [route, kind])
		if route == "V2":
			await proof(ship)
		view("battle", 41.6)
		var single := await bench(str(route) + "_1")
		var spacing := 41.6 * 1.15
		cam.look_at_from_position(Vector3(0, cos(.98), sin(.98)) * 41.6 * 8, Vector3.ZERO, Vector3.UP)
		ship.position += Vector3(-2 * spacing, 0, -1.5 * spacing)
		for i in range(1, 20):
			var copy := ship.duplicate()
			copy.position += Vector3((i % 5) * spacing, 0, (i / 5) * spacing)
			holder.add_child(copy)
		var fleet := await bench(str(route) + "_20")
		report.append({"code":"C19_51", "route":route, "geometry":stats, "single":single, "fleet":fleet})
		for child in holder.get_children(): child.free()
		await settle(5)
	var result := {"adapter":RenderingServer.get_video_adapter_name(), "godot":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(), "resolution":[1920,1080],
		"vsync":"disabled", "blank":blank, "rows":report,
		"fleet_layout":"5 by 4 shared copies; spacing 1.15 lengths; camera r=8 lengths",
		"textures":"BC7 colour/ORM; BC5 normal; mipmaps; 100 warm-up, 360 measured frames"}
	var file := FileAccess.open(str(cfg.get("gpu_out",str(cfg["work"]).path_join("gpu.json"))), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  ") + "\n"); file.close()
	print("[round4] GPU PASS"); quit(0)


func proof(ship: Node3D) -> void:
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(cfg["work"]).path_join("C19_51/V2/build.json")))
	var p: Array = record["proof_target_godot"]
	var n: Array = record["proof_normal_godot"]
	var target := ship.to_global(Vector3(p[0],p[1],p[2]))
	var normal := Vector3(n[0],n[1],n[2]).normalized()
	var tangent := (Vector3.RIGHT-normal*normal.dot(Vector3.RIGHT)).normalized()
	var original: Array = []
	for mi in nodes(ship):
		for i in mi.mesh.get_surface_count():
			var mat: BaseMaterial3D = mi.get_active_material(i)
			if mat.normal_texture != null and mat.normal_texture.get_width() == 4096:
				original.append([mi,i,mat])
	for state in ["filtered","raw"]:
		if state == "raw":
			var img := Image.load_from_file(str(cfg["work"]).path_join("C19_51/V2/normal_raw.png"))
			var tex := compress_map(ImageTexture.create_from_image(img),true)
			for row in original:
				var mat: BaseMaterial3D = row[2].duplicate()
				mat.normal_texture = tex;row[0].set_surface_override_material(row[1],mat)
		for kind in ["head","grazing"]:
			var direction := normal if kind == "head" else (tangent*.94+normal*.34).normalized()
			cam.projection = Camera3D.PROJECTION_PERSPECTIVE;cam.fov = 32
			cam.look_at_from_position(target+direction*6,target,Vector3.UP)
			await settle();await snap("proof_%s_%s" % [state,kind])
	for row in original:row[0].set_surface_override_material(row[1],row[2])
