extends RefCounted
# Issue 1373: true when a written ship GLB is a strike craft (export7 writes cls "Squadron" in the root node's extras for
# a wing craft and leaves out voidsworn_destruct). A craft has no rooms and never breaks open: the game shows its death as a
# spark and hides it (fx/fx_death.gd _wing_death), so the capital-ship interior and death-seam checks do not apply to it.
# Reads the GLB's JSON chunk directly (no scene build), so a check can decide before it loads anything.


static func is_craft(path: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(path)
	if path.ends_with(".gz"):
		bytes = bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	if bytes.size() < 20 or bytes.slice(0, 4).get_string_from_ascii() != "glTF":
		return false
	var n := bytes.decode_u32(12)
	var doc = JSON.parse_string(bytes.slice(20, 20 + n).get_string_from_utf8())
	if not doc is Dictionary:
		return false
	for node in doc.get("nodes", []):
		var ex = node.get("extras", {}) if node is Dictionary else {}
		if ex is Dictionary and str(ex.get("cls", "")) == "Squadron":
			return true
	return false
