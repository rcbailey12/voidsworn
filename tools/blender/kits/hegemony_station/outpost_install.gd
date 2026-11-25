extends SceneTree
# Refs #1791. Cache the painted outpost GLB as gen/ships/station_outpost.scn (the board's small-station scene), then read
# back what the 1-hex hole and the 3-hex teaching cluster use. T2's own cache is never touched. Args: <glb path>.
const PROPS = preload("res://assets/ships/a4_props.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("OUTPOST INSTALL FAILED: pass the outpost GLB"); quit(1); return
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	if doc.append_from_file(args[0], state) != OK:
		printerr("OUTPOST INSTALL FAILED: cannot read ", args[0]); quit(1); return
	var textures := {}
	for material in state.get_materials():
		for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "emission_texture", "ao_texture"]:
			var texture = material.get(prop)
			if not texture is Texture2D: continue
			var key: String = str(texture.get_instance_id()) + str(prop)
			if not textures.has(key):
				var image: Image = texture.get_image()
				if image.is_compressed(): image.decompress()
				image.convert(Image.FORMAT_RGBA8)
				image.generate_mipmaps()
				if prop == "normal_texture": image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL)
				elif image.compress(Image.COMPRESS_BPTC, Image.COMPRESS_SOURCE_GENERIC) != OK:
					image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC)
				textures[key] = ImageTexture.create_from_image(image)
			material.set(prop, textures[key])
	var node := doc.generate_scene(state)
	if node == null: quit(1); return
	node.set_meta("outpost_export_sha256", FileAccess.get_sha256(args[0]))
	var packed := PackedScene.new()
	if packed.pack(node) != OK: quit(1); return
	var path: String = PROPS.OUTPOST_PATH
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if FileAccess.file_exists(path):
		var kept := path + ".before_" + str(Time.get_unix_time_from_system())
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(kept)) != OK:
			printerr("OUTPOST INSTALL FAILED: could not keep the old cache"); quit(1); return
	if ResourceSaver.save(packed, path, ResourceSaver.FLAG_COMPRESS) != OK:
		printerr("OUTPOST INSTALL FAILED: cache write"); quit(1); return
	node.free()
	# read back both small spots: the one-hex hole and a three-hex teaching cluster
	# cells are hex centres round the cluster centre, as the board passes them (pointy-top hexes, corner radius 10)
	var hw := 10.0 * sqrt(3.0)
	var tri: Array = [Vector2(-hw / 2.0, -0.5 * 10.0), Vector2(hw / 2.0, -0.5 * 10.0), Vector2(0, 10.0)]
	var spots := {"one hex": [Vector2.ZERO], "three hexes": tri}
	for spot in spots:
		var readback := PROPS.station(34.0, 20.0, "", true, spots[spot], 10.0, 0.0)
		if readback == null or not readback.get_meta("station_outpost", false):
			printerr("OUTPOST INSTALL FAILED: the ", spot, " spot still uses the giant station"); quit(1); return
		var triangles := 0
		for child in readback.find_children("*", "MeshInstance3D", true, false):
			for i in child.mesh.get_surface_count():
				triangles += child.mesh.surface_get_arrays(i)[Mesh.ARRAY_INDEX].size() / 3
				var material := child.get_active_material(i) as BaseMaterial3D
				if material == null or (material.albedo_texture == null and not material.emission_enabled):
					printerr("OUTPOST INSTALL FAILED: unpainted surface"); quit(1); return
		print("OUTPOST ", spot, ": scale ", snappedf(float(readback.get_meta("station_scale")), 0.001), "; ", triangles, " triangles")
		readback.free()
	if not ResourceLoader.exists(PROPS.T2_PATH):
		print("OUTPOST note: no station_T2 cache here, so the big-spot readback is skipped")
		print("OUTPOST INSTALL READBACK PASS")
		quit(0); return
	var big: Node3D = PROPS.station(PROPS.LARGE_STATION_SIZE)
	if big == null or big.get_meta("station_outpost", false):
		printerr("OUTPOST INSTALL FAILED: the big station lost T2"); quit(1); return
	big.free()
	print("OUTPOST INSTALL READBACK PASS")
	quit(0)
