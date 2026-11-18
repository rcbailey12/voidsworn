extends SceneTree
# Refs #863. Cache new debris only. Keep the painted station cache untouched.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(1); return
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	if document.append_from_file(args[0], state) != OK: quit(1); return
	var textures := {}
	for material in state.get_materials():
		for prop in ["albedo_texture","normal_texture","roughness_texture","metallic_texture","ao_texture"]:
			var texture = material.get(prop)
			if not texture is Texture2D: continue
			var normal: bool = prop == "normal_texture"
			var key := [texture.get_instance_id(), normal]
			if not textures.has(key):
				var image: Image = texture.get_image()
				if image.is_compressed(): image.decompress()
				image.convert(Image.FORMAT_RGBA8)
				image.generate_mipmaps()
				if normal: image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL)
				elif image.compress(Image.COMPRESS_BPTC, Image.COMPRESS_SOURCE_GENERIC) != OK:
					image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC)
				textures[key] = ImageTexture.create_from_image(image)
			material.set(prop, textures[key])
	var node := document.generate_scene(state)
	if node == null: quit(1); return
	# Copy authored custom data explicitly. The cache must not depend on the
	# editor's glTF extras-to-metadata policy or import settings.
	var source := FileAccess.open(args[0],FileAccess.READ)
	source.seek(12)
	var json_length := source.get_32()
	if source.get_32() != 0x4e4f534a: quit(1); return
	var gltf: Dictionary = JSON.parse_string(source.get_buffer(json_length).get_string_from_utf8())
	for authored in gltf.nodes:
		if not str(authored.get("name","")).begins_with("T2_debris_"): continue
		var part := node.find_child(str(authored.name),true,false)
		if part == null: printerr("Lost debris node ",authored.name); quit(1); return
		for key in authored.get("extras",{}): part.set_meta(key,authored.extras[key])
	node.set_meta("debris_export_sha256",FileAccess.get_sha256(args[0]))
	var packed := PackedScene.new()
	if packed.pack(node) != OK: quit(1); return
	var path := "res://gen/ships/station_T2_debris.scn"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir())) != OK:
		quit(1); return
	if FileAccess.file_exists(path):
		var preserved := path + ".before_" + str(Time.get_unix_time_from_system())
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(preserved)) != OK:
			quit(1); return
	if ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) != OK: quit(1); return
	node.free()
	print("T2 DEBRIS CACHE INSTALLED")
	quit(0)
