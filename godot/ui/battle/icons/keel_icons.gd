extends RefCounted
## The KEEL glyphs are white vectors; the ledger supplies all state colours.
const DIR := "res://ui/battle/icons/"

const PATHS := {
	"battery": '<path d="M6 7v17l4 3M6 9h16M6 15h22M6 21h16"/><path d="M25 13v4" stroke-width="1"/>',
	"lance": '<path d="M4 9v14l19-4 5 3M4 9l19 4 5-3M5 16h19"/><path d="M3 12H1v8h2" stroke-width="1"/>',
	"torpedo": '<path d="M8 11h16l5 5-5 5H8zM8 11 3 6m5 15-4 4m16-14v10"/><path d="M9 16h7" stroke-width="1"/>',
	"flak": '<path d="M13 25l-3-10m8 10 4-13M11 27h10M4 11a13 13 0 0124 0M9 5l2 3m11-3-1 3"/>',
	"bio": '<path d="M3 23C9 23 9 9 17 9h10l-6 6 6 8c-13 0-13-7-16-6m7-3 3-1"/>',
	"gauss": '<path d="M3 12h17l8 4-8 4H3m5-11v14m5-14v14m5-14v14"/>',
	"hull": '<path d="M3 13h22l4 5-2 3H7l-4-4zM3 17h25M15 13v8"/>',
	"shield": '<path d="M16 3 27 9.5v13L16 29 5 22.5v-13zM16 3v26"/>',
	"brace": '<path d="m5 10 10 10h2l10-10" stroke-width="3"/><path d="M12 25h8"/>',
	"focus": '<path d="M5 12V5h7m8 0h7v7m0 8v7h-7m-8 0H5v-7"/><circle cx="16" cy="16" r="2" fill="white" stroke="none"/>',
	"turn": '<path d="M13 4a12 12 0 1014 9l-2-5m-1 7-1-7 7 1"/><circle cx="16" cy="16" r="1.8" fill="white" stroke="none"/>',
	"fire_effect": '<path d="M6 6h8m4 0h8M9 11v11m7-10v15m7-16v13M6 19l3 4 3-4m1 5 3 4 3-4m1-3 3 4 3-4"/>',
	"end": '<path d="M25 6v15M4 11h16l3 2-3 2H4zM12 21l4 4 4-4M4 24h4m-4 4h8"/>',
	"command": '<path fill="white" fill-rule="evenodd" stroke="none" d="m16 1 3.3 11.7L31 16l-11.7 3.3L16 31l-3.3-11.7L1 16l11.7-3.3zM16 12a4 4 0 100 8 4 4 0 000-8z"/>',
	"move": '<path d="M16 3 27 9.5v13L16 29 5 22.5v-13zM10 16h11m-5-5 5 5-5 5"/>',
	"arc": '<path d="M6 8l20 8L6 24zM10 12v8"/>',
	"ram": '<path d="M3 9h9l10 7-10 7H3m16-15 9 8-9 8M3 16h9"/>',
	"board": '<path d="M3 6v20m26-20v20M6 12h11v-3l8 7-8 7v-3H6z"/>',
	"wings": '<path d="m4 24 5-12 5 12-5-3zm9-6 5-13 5 13-5-3zm8 7 4-9 4 9-4-2z"/>',
	"role": '<path d="M16 4 28 16 16 28 4 16zM9 16h14m-7-7v14"/>',
	"repair": '<path d="M12 4h8v8h8v8h-8v8h-8v-8H4v-8h8z"/>',
	"phase": '<path d="M10 3 4 9v14l6 6m12-26 6 6v14l-6 6m-3-24-8 11h7l-5 11"/>',
	"next": '<path d="m10 6 10 10-10 10M24 6v20"/>',
	"cancel": '<path d="M7 7l18 18M25 7 7 25"/>',
	"collapse": '<path d="m7 12 9 9 9-9"/>',
}

static var _glyphs := {}
static var _silhouettes := {}


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit)
static func clear_static() -> void:
	_glyphs.clear()
	_silhouettes.clear()


static func glyph(id: String) -> Texture2D:
	if not _glyphs.has(id):
		var mirror := id in ["turn_left", "back"]
		var source := {"turn_left": "turn", "back": "next", "expand": "collapse"}.get(id, id) as String
		var xf := 'translate(32 0) scale(-1 1)' if mirror else ('translate(0 32) scale(1 -1)' if id == "expand" else '')
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 32 32"><g transform="%s" fill="none" stroke="white" stroke-width="2" stroke-linejoin="miter" stroke-linecap="square">%s</g></svg>' % [xf, PATHS[source]]
		var image := Image.new()
		image.load_svg_from_string(svg)
		image.generate_mipmaps()
		_glyphs[id] = ImageTexture.create_from_image(image)
	return _glyphs[id]


static func silhouette(id: String) -> Texture2D:
	if not _silhouettes.has(id):
		var path := DIR + "ships/" + id + ".png"
		_silhouettes[id] = load(path) if ResourceLoader.exists(path, "Texture2D") else null
	return _silhouettes[id]


static func weapon(kind: String) -> String:
	match kind:
		"beam", "lance", "ion": return "lance"
		"torp", "missile": return "torpedo"
		"flak", "pd": return "flak"
		"bio", "gauss": return kind
		"sq": return "wings"
		_: return "battery"


static func order(id: String) -> String:
	match id:
		"brace", "focus", "ram", "board", "role": return id
		"stance", "launch": return "wings"
		"evasive", "overburn": return "move"
		"reload": return "torpedo"
		"surge": return "shield"
		"nova", "ionpulse": return "lance"
		"frenzy": return "focus"
		"regrow", "reclaim": return "repair"
		"blink", "phase": return "phase"
		"Fire for effect": return "fire_effect"
		_: return "command"
