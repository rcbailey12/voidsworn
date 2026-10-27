extends RefCounted
# Per-faction look as data (G4): every faction colour and style that effects, hull materials and backdrops use comes
# from res://fx/faction_looks.json, so a faction's palette can change in one file (lore round 3: the Deathless will likely
# go dark violet-black with a white-gold corona, the Ithar clear crystal with rainbow edges; nothing is repainted until
# Ryan signs off, but the swap is then a data edit).
#
# Fields (linear RGB triples; null where a faction has none):
#   weapon, shield, engine     effect colours (shield null: no shield bubble)
#   shield_style               0 veil, 1 hex lattice, 2 patchy, 3 prismatic
#   trail                      0 clean, 1 sooty sputter, 2 spore puffs, 3 guttering
#   shielded                   default for fx.add_ship's info.shielded
#   engine_extra               "none", "soot" (Corsair coughs), "spores" (Chorus), "embers" (Deathless)
#   damage_glow                fire and lit conduits inside hull damage
#   hull_fix                   [rim amount, rim tint, albedo lift] for look.gd's hull fix (dark hulls)
#   nebula                     three colours for the battle sky when this faction is the enemy (world.gd)
#   accent                     a second effect colour; when set, a corona round each engine core (none in use yet)
#   shield_edge                an edge colour or "rainbow" for the shield bubble's rim (none in use yet)
# Ids never change; display names live in the story tables, not here.

const PATH := "res://fx/faction_looks.json"
const FALLBACK := "voidsworn"

static var _cache: Dictionary = {}


static func _col(v) -> Variant:
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return v


static func table() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var f := FileAccess.open(PATH, FileAccess.READ)
	var raw = JSON.parse_string(f.get_as_text()) if f != null else null
	if not (raw is Dictionary):
		push_error("faction_look: cannot read " + PATH)
		raw = {}
	for id in raw:
		if String(id).begins_with("_"):
			continue
		var src: Dictionary = raw[id]
		var d := {}
		for k in src:
			var v = src[k]
			if k == "nebula" and v is Array:
				var neb: Array = []
				for c in v:
					neb.append(Vector3(float(c[0]), float(c[1]), float(c[2])))
				d[k] = neb
			elif k in ["shield_style", "trail"]:
				d[k] = int(v)
			elif k == "hull_fix":
				d[k] = [float(v[0]), float(v[1]), float(v[2])]
			else:
				d[k] = _col(v)
		_cache[String(id)] = d
	return _cache


static func of(faction: String) -> Dictionary:
	var t := table()
	return t.get(faction.to_lower(), t.get(FALLBACK, {}))


# Drop the cache (a look editor or a test that rewrites the json).
static func reload() -> void:
	_cache = {}
