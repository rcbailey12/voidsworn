extends RefCounted
# The game's name, its title-screen line and its type faces, in one place for every G2 screen (title, settings, battle
# HUD, campaign fallback). One font set (R436, issue 1406): Michroma is the title wordmark only; headers and small caps
# labels use Big Shoulders Display, body text Barlow and figures Azeret Mono, the same faces as the orders kit
# (godot/ui/theme/fonts, OFL). Oxanium, Chakra Petch and Barlow Semi Condensed are no longer used on screen.
#
# Renaming the game: change TITLE (and TAGLINE) here only. Both follow contrib/opus/compute/rename_map_final.md. The title screen fits any
# length on one line; the window title follows TITLE.

const TITLE := "Embers of the Hollow Sun"   # lore round 8, approved by Ryan Oct 27 (FINDINGS R59)
const TAGLINE := "Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain."

const WORDMARK_PATH := "res://ui/campaign/fonts/Michroma-Regular.ttf"   # R436 C28: Michroma is the wordmark only
const BODY_DIR := "res://ui/theme/fonts/"
const GS := preload("res://ui/theme/glass_shell.gd")

# KEEL uses the same orders-sheet colours and faces as the other game screens.
const KEEL_VEIL := 0.94
const KEEL_LOG_VEIL := 0.48
const KEEL_TEXT_EDGE := Color("#08090b")


static func keel_faces() -> Array[Font]:
	return [GS.sheet_name(), GS.sheet_body(), GS.sheet_medium(), GS.num()]

static var _cache := {}


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit)
static func clear_static() -> void:
	_cache.clear()


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
		f = body_semi() if p != BODY_DIR + "Barlow-Medium.ttf" else FontFile.new()
	_cache[p] = f
	return f


# the game's name on the title screen, and nothing else (R436 C28): Michroma
static func wordmark() -> Font:
	return load_font(WORDMARK_PATH)


# headers: "Round 1", banners, end card, menu and panel titles (R436 C28): Big Shoulders Display, the orders sheet's head face
static func display() -> Font:
	return GS.sheet_name()


# small caps labels (section heads): Big Shoulders Display, letter-spaced; pass the text upper-cased
static func caps() -> Font:
	if _cache.has("caps"):
		return _cache["caps"]
	var v := FontVariation.new()
	v.base_font = load_font("res://ui/theme/fonts/BigShouldersDisplay-VF.ttf")
	v.spacing_glyph = 1
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	_cache["caps"] = v
	return v


static func body() -> Font:
	return load_font(BODY_DIR + "Barlow-Regular.ttf")


static func body_semi() -> Font:
	return load_font(BODY_DIR + "Barlow-Medium.ttf")


# the largest size up to max_size at which text fits in width pixels on one line
static func fit_size(text: String, f: Font, max_size: int, width: float) -> int:
	var sz := max_size
	while sz > 17 and f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width:
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
