extends SceneTree
# Actual battle scene and ShipView, with prototypes substituted only in memory.
# No shipping scene, asset, user save or settings file is modified.

var cfg: Dictionary
var battle


func _initialize() -> void:
	call_deferred("run")


func nodes(n: Node) -> Array:
	var a: Array = []
	if n is MeshInstance3D:a.append(n)
	for c in n.get_children():a.append_array(nodes(c))
	return a


func settle(n := 45) -> void:
	for i in n:await process_frame


func maps(ship) -> void:
	for mi in ship.meshes:
		for i in mi.mesh.get_surface_count():
			var mat: BaseMaterial3D=mi.get_active_material(i).duplicate()
			for prop in ["albedo_texture","normal_texture","orm_texture","roughness_texture","metallic_texture","emission_texture","ao_texture"]:
				var tex: Texture2D=mat.get(prop)
				if tex==null:continue
				var img:=tex.get_image()
				if img.is_compressed():img.decompress()
				img.convert(Image.FORMAT_RGBA8);img.generate_mipmaps()
				img.compress(Image.COMPRESS_S3TC if prop=="normal_texture" else Image.COMPRESS_BPTC,
					Image.COMPRESS_SOURCE_NORMAL if prop=="normal_texture" else Image.COMPRESS_SOURCE_GENERIC)
				mat.set(prop,ImageTexture.create_from_image(img))
			mi.set_surface_override_material(i,mat)


func snap(name0: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(str(cfg["shots"]).path_join(name0+".png"))==OK)
	print("[surface111] game shot ",name0)


func run() -> void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920,1080))
	await settle(4)
	root.size=Vector2i(1920,1080)
	battle=load("res://scenes/battle/battle.tscn").instantiate()
	battle.external=true
	root.add_child(battle)
	battle.tips_off=true
	battle.start_scenario({"seed":111,"sector":3,"admiral":"vex","fleet":["penitent","harrow","warden"],
		"fac":"corsair","obj":"rout","shape":"open","map":"open","dep":"line","kind":"battle"})
	while battle.warming or battle.api==null:await process_frame
	await settle(60)
	# High uncapped frame rates can finish 60 frames before the opening round
	# banner fades. Wait real time so it cannot cover the reviewed surface.
	await create_timer(3.0).timeout
	# Keep the real rules, HUD, board, backdrop and G4 lighting. A separate
	# ShipView places the reviewed capital ship on a clear hex among the fleet.
	var sv=load("res://render/ship_view.gd").new()
	battle.add_child(sv)
	sv.setup({"id":"surface111","side":"player","fac":"corsair","cls":"Battle-barge",
		"code":"C19_51","L":41.6,"facing":0},Vector3(0,0,0))
	sv.set_process(false)
	for other in battle.views.values():
		# Move nearby ships out of the close crop without altering the rules.
		if other.position.length()<65:other.position.z-=100
	var original: Node3D=sv.hull.get_child(0)
	for route in ["today","Aplus","Bake","Reuse"]:
		if route!="today":
			for c in sv.hull.get_children():sv.hull.remove_child(c);c.free()
			var doc:=GLTFDocument.new();var state:=GLTFState.new()
			var path:=str(cfg["work"]).path_join("C19_51/"+route+"/route"+route+".glb")
			assert(doc.append_from_file(path,state)==OK)
			sv.hull.add_child(doc.generate_scene(state))
			sv.meshes.clear();sv._collect(sv.hull);maps(sv);sv._look();sv.hull.transform=Transform3D.IDENTITY;sv._fit()
		for zoom in ["battle","close"]:
			battle.cam.a=-PI/2; battle.cam.b=.98
			battle.cam.r=170.0 if zoom=="battle" else 62.0
			battle.cam.t=Vector3.ZERO; battle.cam.snap()
			await settle()
			await snap("ingame_%s_%s" % [route,zoom])
	# Match main.quit_clean: let scene nodes release their rendering resources
	# before dropping the shared caches and stopping the rendering server.
	battle.queue_free()
	battle=null
	await settle(3)
	for path in ["res://render/ship_view.gd","res://scenes/battle/fx_stub.gd","res://fx/fx.gd",
			"res://world/world.gd","res://render/look.gd","res://ui/campaign/campaign_ui.gd","res://portraits/portraits.gd"]:
		var script=load(path)
		if script!=null and script.has_method("clear_static"):script.clear_static()
	await settle(2)
	print("[surface111] GAME PASS")
	quit(0)
