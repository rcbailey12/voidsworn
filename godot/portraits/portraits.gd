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


# ---------- Nemesis (R42) ----------
# Portraits.nemesis("corsair", 3, ["burn", "eye"]) -> the Nemesis nem_corsair_3 with those scars and the red-black frame.
# Scar kinds (scars.json says which faction can take which): burn (all), cyber, eye (human factions), carapace (Chorus),
# porcelain (Ithar), machine (Deathless). The first scar uses a painted (baked) version when one exists; the rest are
# overlays placed at the portrait's face anchor. Stream B stores the Nemesis as nem_<faction>_<1..6> plus its scar list.
static func nemesis(fac: String, n: int, scars: Array = []) -> Texture2D:
	var id := "nem_%s_%d" % [fac, n]
	var key := id + ":" + ",".join(PackedStringArray(scars))
	if _cache.has(key):
		return _cache[key]
	var e = _index().get("nemesis", {}).get(id, {})
	if not (e is Dictionary) or String(e.get("pick", "")) == "":
		return null
	var rest: Array = scars.duplicate()
	var src := "res://portraits/" + String(e["pick"])
	var baked = e.get("baked", {})
	if not rest.is_empty() and baked is Dictionary and baked.has(rest[0]) and _exists("res://portraits/" + String(baked[rest[0]])):
		src = "res://portraits/" + String(baked[rest[0]])
		rest.remove_at(0)
	var img := _img(src)
	if img == null:
		return null
	img.convert(Image.FORMAT_RGBA8)
	var sz := img.get_width()
	var anc: Array = e.get("anchor", [0.5, 0.42, 0.34])
	var place: Dictionary = _scars().get("place", {})
	for k in rest:
		var sc := _img("res://portraits/nemesis/scars/scar_%s.png" % k)
		if sc == null or not place.has(k):
			continue
		var pl: Array = place[k]
		var s := int(sz * float(anc[2]) * float(pl[2]))
		sc.convert(Image.FORMAT_RGBA8)
		sc.resize(s, s, Image.INTERPOLATE_LANCZOS)
		var x := int(sz * (float(anc[0]) + float(pl[0]) * float(anc[2])) - s / 2.0)
		var y := int(sz * (float(anc[1]) + float(pl[1]) * float(anc[2])) - s / 2.0)
		img.blend_rect(sc, Rect2i(0, 0, s, s), Vector2i(x, y))
	var fr := _img("res://portraits/nemesis/frame_%s.png" % fac)
	if fr != null:
		fr.convert(Image.FORMAT_RGBA8)
		if fr.get_width() != sz:
			fr.resize(sz, sz, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(fr, Rect2i(0, 0, sz, sz), Vector2i.ZERO)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func nemesis_ids(fac: String) -> Array:
	var out: Array = []
	for id in _index().get("nemesis", {}):
		if String(id).begins_with("nem_%s_" % fac):
			out.append(id)
	out.sort()
	return out


static var _sc := {}
static func _scars() -> Dictionary:
	if _sc.is_empty() and FileAccess.file_exists("res://portraits/nemesis/scars/scars.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("res://portraits/nemesis/scars/scars.json"))
		if d is Dictionary:
			_sc = d
	return _sc


static func _img(p: String) -> Image:
	var t := _tex(p)
	if t == null:
		return null
	var img := t.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	return img


static func clear_static() -> void:
	_sc.clear()
	_cache.clear()
	_idx.clear()
