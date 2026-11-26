extends RefCounted
## CaptainData is plain save data. Perks, offer and pending are the existing progression state.

const Portraits = preload("res://portraits/portraits.gd")
const CALLSIGNS := {
	"voidsworn": ["Cinder", "Vigil", "Vesper", "Flint", "Lantern", "Reliquary", "Penance", "Kindle"],
	"corsair": ["Scrap", "Maw", "Knuckle", "Rust", "Crowbar", "Sparks", "Rivet", "Jackal"],
	"ithar": ["Facet", "Glint", "Prism", "Mirage", "Halation", "Shard", "Afterlight", "Veil"],
	"deathless": ["Echo", "Latch", "Null", "Relay", "Cipher", "Wake", "Archive", "Trace"],
	"chorus": ["Spore", "Thorn", "Hush", "Drift", "Bloom", "Pollen", "Tendril", "Hollow"],
	"hegemony": ["Vector", "Ledger", "Needle", "Marker", "Grid", "Relay", "Abacus", "Compass"],
}


static func identity_hash(value: String) -> int:
	var hash_word := 0x811c9dc5
	for byte in value.to_utf8_buffer():
		hash_word = ((hash_word ^ byte) * 0x01000193) & 0xffffffff
	return hash_word


static func make(id: String, fac: String, full_name: String, xp = 0, rank = 0, perks: Array = []) -> Dictionary:
	var pool: Array = CALLSIGNS.get(fac, CALLSIGNS["voidsworn"])
	# Identity draws use the captain's key, not the run's rules random stream.
	return {"captain_id": id, "portrait_id": "", "full_name": full_name,
		"callsign": pool[posmod(identity_hash(id + "|" + full_name), pool.size())], "rank": rank, "xp": xp,
		"trait_line": "", "fac": fac, "perks": perks, "pending": 0}


static func migrate(data, id: String, fac: String, perks: Dictionary) -> Dictionary:
	var c: Dictionary = data if data is Dictionary else {}
	var name = c.get("full_name", c.get("name", "Captain"))
	if not (name is String) or name.strip_edges().is_empty(): name = "Captain"
	var faction := str(c.get("fac", fac))
	if not CALLSIGNS.has(faction): faction = fac
	if not (c.get("captain_id") is String) or c["captain_id"].is_empty(): c["captain_id"] = id
	var defaults := make(c["captain_id"], faction, name)
	c.merge(defaults)
	c["full_name"] = name
	c["fac"] = faction
	c.erase("name")
	if not (c["portrait_id"] is String): c["portrait_id"] = ""
	if not (c["callsign"] is String) or c["callsign"].is_empty(): c["callsign"] = defaults["callsign"]
	for key in ["rank", "xp", "pending"]:
		if not (c[key] is int or c[key] is float): c[key] = 0
	c["perks"] = c["perks"].filter(func(p): return p is String and perks.has(p)) if c["perks"] is Array else []
	update_trait(c, perks)
	return c


static func update_trait(c: Dictionary, perks: Dictionary) -> void:
	var lines := PackedStringArray()
	for id in c["perks"]:
		if perks.has(id): lines.append(str(perks[id]["d"]))
	c["trait_line"] = " ".join(lines).replace("\n", " ")


static func assign_portrait(c: Dictionary, used: Dictionary) -> void:
	var pool := Portraits.captain_pool(c["fac"])
	var id: String = c["portrait_id"]
	if not pool.has(id) or used.has(id):
		id = ""
		for i in range(pool.size()):
			var candidate: String = pool[posmod(identity_hash(c["captain_id"]) + i, pool.size())]
			if not used.has(candidate):
				id = candidate
				break
	c["portrait_id"] = id
	if not id.is_empty(): used[id] = true


# Claim existing unique faces first so migrating an unpainted captain cannot change a later captain's face.
static func restore_portraits(captains: Array) -> void:
	var used := {}
	var needs_face := []
	for c in captains:
		var id: String = c["portrait_id"]
		if not Portraits.captain_pool(c["fac"]).has(id) or used.has(id): needs_face.append(c)
		else: used[id] = true
	for c in needs_face: assign_portrait(c, used)


static func used_portraits(run) -> Dictionary:
	var used := {}
	if run is Dictionary:
		for s in run.get("fleet", []) + run.get("reserve", []):
			var id := str(s.get("cap", {}).get("portrait_id", ""))
			if not id.is_empty(): used[id] = true
	return used
