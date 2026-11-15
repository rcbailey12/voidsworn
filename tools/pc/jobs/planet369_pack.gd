extends SceneTree
# CPU only. Compressed Image resources export as resources, without PNG import
# compression changing the packed 16-bit height. Every shipped file is <8 MB.
const DEST := "res://world/rocks/r01/"
const TILE := Vector2i(2048, 1024)

func sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _initialize() -> void:
	var started := Time.get_ticks_msec()
	var meta = JSON.parse_string(FileAccess.get_file_as_string(DEST + "bake.json"))
	for name in ["colour", "relief", "roughness"]:
		var path := OS.get_environment("TEMP").path_join("voidsworn_issue369_sources/r01_remix/" + name + ".png")
		var image := Image.load_from_file(path)
		if image == null or image.get_size() != Vector2i(8192, 4096):
			printerr("Missing full 8K pack input: ", path)
			quit(1)
			return
		var desc := {"size": [8192, 4096], "format": image.get_format(), "pixel_sha256": sha(image.get_data()), "tiles": []}
		for y in 4:
			for x in 4:
				var tile := image.get_region(Rect2i(Vector2i(x,y)*TILE, TILE))
				var file := "%s_%d_%d.res" % [name,x,y]
				var dest := DEST + file
				if ResourceSaver.save(tile, dest, ResourceSaver.FLAG_COMPRESS) != OK:
					quit(1)
					return
				var bytes := FileAccess.get_file_as_bytes(dest)
				var reloaded := ResourceLoader.load(dest, "Image", ResourceLoader.CACHE_MODE_IGNORE) as Image
				if bytes.size() > 8000000 or reloaded == null or reloaded.get_data() != tile.get_data():
					printerr("Tile size or lossless round-trip failed: ", file)
					quit(1)
					return
				meta.files[file] = {"sha256": sha(bytes), "bytes": bytes.size()}
				desc.tiles.append({"file": file, "x": x*TILE.x, "y": y*TILE.y, "size": [TILE.x,TILE.y]})
		var f := FileAccess.open(DEST + name + ".json", FileAccess.WRITE)
		f.store_string(JSON.stringify(desc, "  ") + "\n")
		f.close()
		print("R01_PACK ", name, " 8192x4096: 16 lossless tiles, each under 8 MB")
	meta["cold_pack_seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	var f := FileAccess.open(DEST + "bake.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  ") + "\n")
	quit(0)
