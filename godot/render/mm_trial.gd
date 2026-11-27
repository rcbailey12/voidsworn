extends RefCounted
# Issue 2001: record which trial maps the ship and planet materials actually request.

static var has_missing := false


static func enabled() -> bool:
	return OS.get_environment("VS_MM_TRIAL") == "1"


static func load_tile(owner: String, path: String) -> Texture2D:
	# A checkout can have a stale cache. Exported packs carry the remapped resource instead.
	if OS.has_feature("editor"):
		if not FileAccess.file_exists(path):
			return _missing(owner, path)
		if not FileAccess.file_exists(path + ".import"):
			return _missing(owner, path + ".import")
	var tile := ResourceLoader.load(path, "Texture2D") as Texture2D if ResourceLoader.exists(path, "Texture2D") else null
	if tile == null:
		return _missing(owner, path)
	print("MM_TRIAL LOADED %s %s" % [owner, path])
	return tile


static func _missing(owner: String, path: String) -> Texture2D:
	has_missing = true
	push_error("MM_TRIAL MISSING %s %s" % [owner, path])
	return null
