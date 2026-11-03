extends "res://probe.gd"
# Uses round 1's exact studio, camera, compressed maps and benchmark loop.


func proof_material(ship: Node3D, raw: bool) -> void:
	for mi in nodes(ship):
		var material0: Material=mi.get_active_material(0)
		if material0==null or not str(material0.resource_name).contains("shared_trim_with_donor_cavity"):
			mi.visible = false
			continue
		for i in mi.mesh.get_surface_count():
			var mat: BaseMaterial3D = mi.get_active_material(i).duplicate()
			var name0 := "normal_raw.png" if raw else "normal.png"
			var img := Image.load_from_file(str(cfg["work"]).path_join("C19_51/Bake/" + name0))
			mat.normal_texture = compress_map(ImageTexture.create_from_image(img), true)
			mi.set_surface_override_material(i, mat)


func proof_view(ship: Node3D, kind: String) -> void:
	# The outer starboard donor panel, x=.23, y=-.24, z=-.10 in Blender.
	# The same physical panel and same crop framing are used before/after.
	var target := ship.to_global(Vector3(0.23, -0.10, 0.242))
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 32.0
	var dir := Vector3(0.0, 0.05, 1.0) if kind == "head" else Vector3(0.92, 0.08, 0.38)
	cam.look_at_from_position(target + dir.normalized() * 8.5, target, Vector3.UP)


func run() -> void:
	var a := OS.get_cmdline_user_args()
	assert(a.size() == 1)
	cfg = JSON.parse_string(FileAccess.get_file_as_string(a[0]))
	out = cfg["shots"]
	facets = cfg["factions"]
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920,1080)
	setup_world()
	view("battle",41.6)
	var blank := await bench("empty")
	for route in ["today","Aplus","Bake","Reuse"]:
		var ship := model("C19_51",route)
		var stats := fit(ship,41.6)
		for kind in ["battle","close","top","side","below"]:
			view(kind,41.6)
			await settle()
			await snap("C19_51_%s_%s" % [route,kind])
		# Extra underside evidence has a fill from below, identical for every
		# route. The required comparison rows above retain round 1 lighting.
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees = Vector3(55,25,0)
		fill.light_energy = 1.0
		world.add_child(fill)
		view("below",41.6)
		await settle()
		await snap("C19_51_%s_below_inspect" % route)
		fill.free()
		view("battle",41.6)
		var single := await bench(route+"_1")
		var spacing := 41.6*1.15
		cam.look_at_from_position(Vector3(0,cos(0.98),sin(0.98))*41.6*8,Vector3.ZERO,Vector3.UP)
		ship.position += Vector3(-2*spacing,0,-1.5*spacing)
		for i in range(1,20):
			var copy := ship.duplicate()
			copy.position += Vector3((i%5)*spacing,0,(i/5)*spacing)
			holder.add_child(copy)
		var fleet := await bench(route+"_20")
		report.append({"code":"C19_51","route":route,"geometry":stats,"single":single,"fleet":fleet})
		for child in holder.get_children():child.free()
		await settle(5)
	for mode in ["raw","filtered"]:
		var ship := model("C19_51","Bake")
		fit(ship,41.6)
		proof_material(ship,mode=="raw")
		for angle in ["head","grazing"]:
			proof_view(ship,angle)
			await settle()
			await snap("proof_%s_%s" % [mode,angle])
		ship.free()
	var result := {"adapter":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1920,1080],"vsync":"disabled",
		"blank":blank,"rows":report,"fleet_layout":"5 by 4 shared copies, spacing 1.15 lengths, r=8 lengths",
		"textures":"BC7 colour and ORM; BC5 normal; mipmaps; 100 warm-up and 360 measured frames"}
	var f := FileAccess.open(str(cfg["work"]).path_join("gpu.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  ")+"\n");f.close()
	print("[surface111] GPU PASS")
	quit(0)
