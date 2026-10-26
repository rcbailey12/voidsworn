extends RefCounted
# Admiral faces for any screen (owner: music and portraits helper; R37, R40).
#   const Portraits := preload("res://portraits/portraits.gd")
#   var tex: Texture2D = Portraits.face("vex")      # painted portrait when one is chosen, else the admiral's crest
#   var tex2: Texture2D = Portraits.crest("vex")    # always the crest (small slots, lists, map tokens)
#   Portraits.has_painting("vex")                   # true when a painted portrait is in godot/portraits/painted/
# Admiral ids are data.js ADMIRALS keys (vex, kassar, grax, matriarch, aelith, nekhet, ...).
# index.json lists the picked painting per admiral and the kept alternates (alts/) Ryan can swap in by editing "pick".

const INDEX := "res://portraits/index.json"
static var _idx := {}
static var _cache := {}


static func _index() -> Dictionary:
	if _idx.is_empty() and FileAccess.file_exists(INDEX):
		var d = JSON.parse_string(FileAccess.get_file_as_string(INDEX))
		if d is Dictionary:
			_idx = d
	return _idx


static func has_painting(id: String) -> bool:
	var e = _index().get("painted", {}).get(id, {})
	return e is Dictionary and String(e.get("pick", "")) != "" and _exists("res://portraits/" + String(e["pick"]))


static func face(id: String) -> Texture2D:
	if has_painting(id):
		var e: Dictionary = _index()["painted"][id]
		var t := _tex("res://portraits/" + String(e["pick"]))
		if t != null:
			return t
	return crest(id)


static func crest(id: String) -> Texture2D:
	return _tex("res://portraits/crests/" + id + ".svg")


static func _exists(p: String) -> bool:
	return ResourceLoader.exists(p) or FileAccess.file_exists(p)


static func _tex(p: String) -> Texture2D:
	if _cache.has(p):
		return _cache[p]
	var t: Texture2D = null
	if ResourceLoader.exists(p):
		var r = load(p)
		if r is Texture2D:
			t = r
	if t == null and FileAccess.file_exists(p):
		# not imported yet (fresh checkout run headless): load the raw file
		var img := Image.new()
		var err := img.load_svg_from_buffer(FileAccess.get_file_as_bytes(p)) if p.ends_with(".svg") else img.load(p)
		if err == OK:
			t = ImageTexture.create_from_image(img)
	_cache[p] = t
	return t


static func clear_static() -> void:
	_cache.clear()
	_idx.clear()
