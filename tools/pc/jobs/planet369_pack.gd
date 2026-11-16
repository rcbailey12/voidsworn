extends SceneTree
# CPU only. Resource payloads export without image import changing data channels.
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
		for y in 4:
			for x in 4:
				var file := "%s_%d_%d.res" % [name,x,y]
				var path := OS.get_environment("TEMP").path_join("voidsworn_issue369_sources/r01_remix/webp/" + file.get_basename() + ".webp")
				var payload := FileAccess.get_file_as_bytes(path)
				var tile := Image.new()
				if tile.load_webp_from_buffer(payload) != OK or tile.get_size() != TILE:
					quit(1)
					return
				var resource := Resource.new()
				resource.set_meta("webp", payload)
				var dest := DEST + file
				if ResourceSaver.save(resource, dest, ResourceSaver.FLAG_COMPRESS) != OK:
					quit(1)
					return
				var bytes := FileAccess.get_file_as_bytes(dest)
				var reloaded := ResourceLoader.load(dest, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
				if bytes.size() > 8000000 or reloaded == null or reloaded.get_meta("webp", PackedByteArray()) != payload:
					printerr("Tile size or payload round-trip failed: ", file)
					quit(1)
					return
				meta.files[file] = {"sha256": sha(bytes), "bytes": bytes.size()}
		print("R01_PACK ", name, " 8192x4096: 16 WebP resources, each under 8 MB")
	var total := 0
	for entry in meta.files.values(): total += int(entry.bytes)
	meta["total_asset_bytes"] = total
	if total > 40000000:
		printerr("R01 exceeds 40 MB package: ", total)
		quit(1)
		return
	meta["cold_pack_seconds"] = (Time.get_ticks_msec() - started) / 1000.0
	var f := FileAccess.open(DEST + "bake.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  ") + "\n")
	quit(0)
