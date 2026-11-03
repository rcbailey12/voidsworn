extends "res://probe.gd"
# Same studio, G4 settings and benchmark loop as rounds 1 and 2.


func model(code: String, route: String) -> Node3D:
	var ship := super.model(code,route)
	load("res://assembly.gd").add_parts(ship,str(cfg["work"]),route)
	for mi in nodes(ship):
		for i in mi.mesh.get_surface_count():
			var original: BaseMaterial3D=mi.get_active_material(i)
			if original==null or original.resource_name!="native_AI_shared_trim":continue
			var mat: BaseMaterial3D=original.duplicate()
			for prop in ["albedo_texture","normal_texture","orm_texture","roughness_texture","metallic_texture","ao_texture"]:
				if mat.get(prop)!=null:mat.set(prop,compress_map(mat.get(prop),prop=="normal_texture"))
			mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			mi.set_surface_override_material(i,mat)
	return ship


func detail(ship: Node3D, kind: String) -> void:
	var target := ship.to_global(Vector3(0.23, -0.10, 0.242))
	var direction := Vector3(0, 0.05, 1)
	var distance := 6.0
	if kind == "grazing":direction = Vector3(0.94, 0.06, 0.34)
	if kind == "blob":
		target = ship.to_global(Vector3(-0.19, 0.16, 0))
		direction = Vector3(0.38, 0.48, 0.79)
		distance = 7.5
	if kind == "engine_part":
		target=ship.to_global(Vector3(-.46,-.064,0))
		direction=Vector3(-.75,.28,.59);distance=5.0
	if kind == "gun_part":
		target=ship.to_global(Vector3(.10,-.045,.25))
		direction=Vector3(.38,.50,.79);distance=4.5
	if kind == "bridge_part":
		target=ship.to_global(Vector3(-.19,.16,0))
		direction=Vector3(.38,.48,.79);distance=6.5
	if kind == "midships_join":
		target=ship.to_global(Vector3(.24,-.025,0))
		direction=Vector3(.2,.4,1);distance=9
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.fov = 32
	cam.look_at_from_position(target+direction.normalized()*distance,target,Vector3.UP)


func concept_view(kind: String) -> void:
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 41.6*1.18
	var direction := Vector3(1,0,0) if kind == "front" else Vector3(0,0,-1)
	if kind == "concept":direction=Vector3(0.65,0.45,-0.61).normalized()
	cam.look_at_from_position(direction*140,Vector3.ZERO,Vector3.UP)


func run() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	out=cfg["shots"]; facets=cfg["factions"]
	DirAccess.make_dir_recursive_absolute(out)
	root.size=Vector2i(1920,1080)
	setup_world();view("battle",41.6)
	var blank := await bench("empty")
	for route in cfg["routes"]:
		var ship := model("C19_51",str(route))
		var stats := fit(ship,41.6)
		for kind in ["battle","close","top","side","below"]:
			view(kind,41.6);await settle();await snap("C19_51_%s_%s" % [route,kind])
		var fill := DirectionalLight3D.new()
		fill.rotation_degrees=Vector3(55,25,0);fill.light_energy=1
		world.add_child(fill)
		view("below",41.6);await settle();await snap("C19_51_%s_below_inspect" % route)
		fill.free()
		for kind in ["front","side_reference","concept"]:
			concept_view(kind);await settle();await snap("C19_51_%s_%s" % [route,kind])
		for kind in ["head","grazing","blob","engine_part","gun_part","bridge_part"]:
			detail(ship,kind);await settle();await snap("C19_51_%s_%s" % [route,kind])
		view("battle",41.6)
		var single := await bench(str(route)+"_1")
		var spacing := 41.6*1.15
		cam.look_at_from_position(Vector3(0,cos(.98),sin(.98))*41.6*8,Vector3.ZERO,Vector3.UP)
		ship.position+=Vector3(-2*spacing,0,-1.5*spacing)
		for i in range(1,20):
			var copy := ship.duplicate()
			copy.position+=Vector3((i%5)*spacing,0,(i/5)*spacing)
			holder.add_child(copy)
		var fleet := await bench(str(route)+"_20")
		report.append({"code":"C19_51","route":route,"geometry":stats,"single":single,"fleet":fleet})
		for child in holder.get_children():child.free()
		await settle(5)
	var joined := model("C19_51","Midships")
	fit(joined,41.6)
	detail(joined,"midships_join");await settle();await snap("midships_join")
	joined.free()
	var result := {"adapter":RenderingServer.get_video_adapter_name(),"godot":Engine.get_version_info(),
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1920,1080],
		"vsync":"disabled","blank":blank,"rows":report,
		"fleet_layout":"5 by 4 shared copies; spacing 1.15 lengths; camera r=8 lengths",
		"textures":"BC7 colour/ORM; BC5 trim normal; mipmaps; 100 warm-up, 360 measured frames"}
	var file := FileAccess.open(str(cfg["work"]).path_join("gpu.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  ")+"\n");file.close()
	print("[repair129] GPU PASS")
	load("res://assembly.gd").clear_static()
	quit(0)
