extends RefCounted
# The game's name, its title-screen line and its type faces, in one place for every G2 screen (title, settings, battle
# HUD, campaign fallback). Lore round 5 (hard sci-fi): the blackletter display face is retired. Headers use Michroma (wide
# sci-fi display face) and small labels Oxanium small caps, the same faces G3's campaign map uses
# (godot/ui/campaign/fonts, OFL); body text stays Barlow Semi Condensed.
#
# Renaming the game: change TITLE (and TAGLINE) here only, after Ryan signs off the lore. The title screen fits any
# length on one line; the window title follows TITLE.

const TITLE := "Voidsworn"
const TAGLINE := "Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain."

const DISPLAY_PATH := "res://ui/campaign/fonts/Michroma-Regular.ttf"
const CAPS_PATH := "res://ui/campaign/fonts/Oxanium-Variable.ttf"
const BODY_DIR := "res://ui/battle/fonts/"

static var _cache := {}


# the imported font when the project has been imported or exported, else the raw file (a copy without .godot/)
static func load_font(p: String) -> Font:
	if _cache.has(p):
		return _cache[p]
	var f: Font = null
	if _imported_ok(p):
		var r = load(p)
		if r is Font:
			f = r
	if f == null and FileAccess.file_exists(p):
		var ff := FontFile.new()
		ff.data = FileAccess.get_file_as_bytes(p)
		f = ff
	if f == null:
		f = body_semi() if p != BODY_DIR + "BarlowSemiCondensed-SemiBold.ttf" else FontFile.new()
	_cache[p] = f
	return f


# headers: the title logo, "Round 1", banners, end card, menu and panel titles
static func display() -> Font:
	return load_font(DISPLAY_PATH)


# small caps labels (section heads): Oxanium semi-bold, letter-spaced; pass the text upper-cased
static func caps() -> Font:
	if _cache.has("caps"):
		return _cache["caps"]
	var v := FontVariation.new()
	v.base_font = load_font(CAPS_PATH)
	v.spacing_glyph = 1
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	_cache["caps"] = v
	return v


static func body() -> Font:
	return load_font(BODY_DIR + "BarlowSemiCondensed-Regular.ttf")


static func body_semi() -> Font:
	return load_font(BODY_DIR + "BarlowSemiCondensed-SemiBold.ttf")


# the largest size up to max_size at which text fits in width pixels on one line
static func fit_size(text: String, f: Font, max_size: int, width: float) -> int:
	var sz := max_size
	while sz > 12 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width:
		sz -= 2
	return sz


static func _imported_ok(p: String) -> bool:
	var ip := p + ".import"
	if not FileAccess.file_exists(ip):
		return false
	for line in FileAccess.get_file_as_string(ip).split("\n"):
		if line.begins_with("path=") or line.begins_with("path."):
			var q := line.substr(line.find("\"") + 1)
			q = q.substr(0, q.find("\""))
			return q != "" and FileAccess.file_exists(q)
	return false
