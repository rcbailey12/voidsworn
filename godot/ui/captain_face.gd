extends RefCounted
## The same face and fallback for the KEEL panel, comms and the Hall of the Fallen.

const Portraits := preload("res://portraits/portraits.gd")
const SILHOUETTE := """<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
<path fill="#15171b" d="M0 0h64v64H0z"/>
<path fill="#7a746a" d="M32 10c8 0 13 6 13 14s-4 13-8 16l1 4c11 2 20 8 22 20H4c2-12 11-18 22-20l1-4c-4-3-8-8-8-16s5-14 13-14z"/>
</svg>"""
static var _fallback: Texture2D
static var _memorials := {}


static func clear_static() -> void:
	_fallback = null
	_memorials.clear()


static func fallback() -> Texture2D:
	if _fallback == null:
		var image := Image.new()
		image.load_svg_from_string(SILHOUETTE)
		_fallback = ImageTexture.create_from_image(image)
	return _fallback


static func captain(cap: Dictionary) -> Texture2D:
	var face := Portraits.captain_face(str(cap.get("portrait_id", "")))
	return face if face != null else fallback()


static func memorial(cap: Dictionary) -> Texture2D:
	var id := str(cap.get("portrait_id", ""))
	if _memorials.has(id):
		return _memorials[id]
	var image := captain(cap).get_image()
	if image == null or image.is_empty():
		return fallback()
	image = image.duplicate()
	if image.is_compressed() and image.decompress() != OK:
		return fallback()
	image.resize(96, 96, Image.INTERPOLATE_BILINEAR)
	image.convert(Image.FORMAT_LA8)
	var gray := ImageTexture.create_from_image(image)
	_memorials[id] = gray
	return gray
