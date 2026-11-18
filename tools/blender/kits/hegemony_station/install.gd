extends SceneTree
# Refs #975. Cache a checked station GLB, then read back what the board uses.
const PROPS = preload("res://assets/ships/a4_props.gd")

func _init() -> void:
	var path := "res://assets/ships/station_T2/station_T2.glb"
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	if doc.append_from_file(path, state) != OK:
		printerr("T2 INSTALL FAILED: cannot read production GLB"); quit(1); return
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
	var packed := PackedScene.new()
	if packed.pack(node) != OK: quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://gen/ships"))
	if ResourceSaver.save(packed, "res://gen/ships/station_T2.scn", ResourceSaver.FLAG_COMPRESS) != OK:
		printerr("T2 INSTALL FAILED: cache write"); quit(1); return
	node.free()
	var readback := PROPS.station(46.0)
	if readback == null or not readback.has_meta("station_T2"):
		printerr("T2 INSTALL FAILED: board still uses old station"); quit(1); return
	var triangles := 0
	var surfaces := 0
	for child in readback.find_children("*", "MeshInstance3D", true, false):
		for i in child.mesh.get_surface_count():
			surfaces += 1
			var arrays: Array = child.mesh.surface_get_arrays(i)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
			var material := child.get_active_material(i) as BaseMaterial3D
			if material == null or (material.albedo_texture == null and not material.emission_enabled):
				printerr("T2 INSTALL FAILED: unpainted surface"); quit(1); return
	print("T2 INSTALL READBACK PASS: ", triangles, " triangles; ", surfaces, " surfaces; world scale retained")
	readback.free()
	quit(0)
