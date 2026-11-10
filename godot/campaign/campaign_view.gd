extends RefCounted
# Read-only views of the campaign for the screens (issue #344, UI rollout 1; outside audit pass 1, finding 12, Board verdict:
# "build the read-only view API with the Lime Tactical screen rollout, screen by screen").
#
# A screen asks one of these functions for what it shows and gets plain values back (numbers, strings, small dictionaries and
# arrays it may keep or change freely). Nothing here writes to the campaign, draws a random number or keeps state, so calling
# a view never changes a run, a save or parity. When a save field is renamed or reshaped, only this file has to follow it;
# the screens that read through it do not.
#
# Rollout 1 moves the readers of the map's header, its side panel (purse, fleet rows, hold, flagship aspect) and the fight
# cards (fight, elite and the sector flagship) onto these functions. Other readers move with their own screen groups.

static func _jt(v) -> bool:
	return v != null and not (v is bool and v == false) and not (v is float and v == 0.0) and not (v is int and v == 0) and not (v is String and v == "")


# where the run is: sector, region, which jump of how many, fights so far, and who holds the sector
static func header(C) -> Dictionary:
	var R = C.RUN
	if R == null: return {}
	var m = R["map"]
	var here = C.findNode(R["pos"]) if R.get("pos") != null else null
	var region := ""
	if _jt(m.get("region")) and C.REGIONS.has(m["region"]): region = str(C.REGIONS[m["region"]]["n"])
	var F = C.FACTIONS.get(m["fac"], {})
	return {
		"sector": int(R["sector"]),
		"sector_roman": C.roman(R["sector"]),
		"region": region,
		"jump": (int(here["col"]) + 1) if here != null else 0,
		"jumps": int(m["cols"].size()),
		"fights": int(float(C.z0(R["stats"].get("battles")))),
		"holder_fac": str(m["fac"]),
		"holder": str(F.get("n", "")),
		"holder_blurb": str(F.get("blurb", "")),
	}


# what the fleet can spend: credits and command points
static func purse(C) -> Dictionary:
	var R = C.RUN
	if R == null: return {}
	return {"credits": float(R["credits"]), "cp": float(C.fleetCP()), "cp_cap": float(R["cpCap"])}


# the admiral leading the run: id, doctrine
static func admiral(C) -> Dictionary:
	var R = C.RUN
	if R == null: return {}
	var A = C.ADMIRALS[R["admiral"]]
	return {"id": str(R["admiral"]), "name": str(A["n"]), "doc": str(A["doc"])}


# one row per ship in the fleet, in fleet order: the side panel's fleet list
static func fleet_rows(C) -> Array:
	var R = C.RUN
	var out: Array = []
	if R == null: return out
	var fs = C.flagshipOf()
	var hold := int(R["inventory"].size())
	for s in R["fleet"]:
		var d = C.derive(s); var T = C.HULLS[s["tpl"]]
		var hp := float(s["hp"]); var mx := maxf(1.0, float(d["maxHp"]))
		out.append({
			"uid": str(s["uid"]),
			"name": str(s["name"]),
			"flagship": fs != null and fs["uid"] == s["uid"],
			"hp": hp, "max_hp": float(d["maxHp"]), "frac": hp / mx,
			"cls": str(C.clsName(T["cls"])),
			"mk": C.roman(s["mk"]),
			"captain": str(C.rankName(s["cap"])) + " " + str(s["cap"]["name"]),
			"promotion": _jt(s["cap"].get("pending")),
			"free_slots": int(T["slots"]) - int(s["mods"].size()),
			"hold": hold,
		})
	return out


# refits waiting in the hold
static func hold_count(C) -> int:
	return int(C.RUN["inventory"].size()) if C.RUN != null else 0


# whether any captain has a promotion waiting (the fleet button then reads "Promote captains and refit")
static func promotion_waiting(C) -> bool:
	if C.RUN == null: return false
	return C.RUN["fleet"].any(func(s): return _jt(s["cap"].get("pending")))


# the flagship's aspect, or {} when the run has none
static func aspect(C) -> Dictionary:
	var R = C.RUN
	if R == null or not _jt(R.get("aspect")) or not C.ASPECTS.has(R["aspect"]): return {}
	var fs = C.flagshipOf()
	return {"ship": str(fs["name"]) if fs != null else "", "n": str(C.ASPECTS[R["aspect"]]["n"]), "d": str(C.ASPECTS[R["aspect"]]["d"])}


# The fight cards on the map: one per distinct fight you can jump to now (ordinary fights, elite fleets and the sector
# flagship). Equal fights (same encounter, reward, kind, archetype and modifier) show once, as the browser's previews do.
#   kind: "battle", "elite" or "boss"; fac and fac_name: who you fight (rival raiders included); the rest is words.
static func fight_cards(C) -> Array:
	var out: Array = []
	if C.RUN == null or C.page.get("kind") != "map": return out
	var seen := {}
	for id in C.page["data"]["avail"]:
		var n = C.findNode(id)
		if n == null: continue
		var t := str(n["type"])
		if not (t in ["battle", "elite", "boss"]): continue
		var fac = C.nodeFaction(n) if t != "boss" else C.RUN["map"]["fac"]
		var row := {"id": str(id), "kind": t, "fac": str(fac), "fac_name": str(C.FACTIONS[fac]["n"]) if C.FACTIONS.has(fac) else "",
			"name": "", "d": "", "arch": "", "arch_d": "", "mod": "", "mod_d": "", "shape": "", "reward": "", "reward_patron": "", "reward_min": false,
			"nemesis": not _jt(n.get("done")) and C.nemNodeIs(n)}
		if t == "boss":
			row["name"] = "Sector flagship"
			row["d"] = "The sector's command ship and its escort. Beat it to end the sector."
		else:
			if not _jt(n.get("enc")) or not C.ENCOUNTERS.has(n["enc"]): continue
			var E = C.ENCOUNTERS[n["enc"]]
			row["name"] = str(E["n"]); row["d"] = str(E["d"])
			if _jt(n.get("arch")) and C.ARCHETYPES.has(n["arch"]):
				var a = C.effArch(n["arch"], fac)
				if a != null and C.ARCHETYPES.has(a):
					var names = C.ARCHETYPES[a]["names"]
					row["arch"] = str(names.get(fac, names.get("hegemony", "")))
					row["arch_d"] = str(C.ARCHETYPES[a]["d"])
			if _jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]):
				row["mod"] = str(C.NODE_MODS[n["mod"]]["n"]); row["mod_d"] = str(C.NODE_MODS[n["mod"]]["d"])
			if _jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]): row["shape"] = str(C.SHAPES[n["shape"]]).to_lower()
		var rw = n.get("rw")
		if rw is Dictionary:
			row["reward"] = reward_label(C, rw); row["reward_min"] = _jt(rw.get("min"))
			if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): row["reward_patron"] = str(rw["p"])
		var key := "%s|%s|%s|%s|%s|%s" % [t, row["name"], row["reward"], row["arch"], row["mod"], row["fac"]]
		if seen.has(key): continue
		seen[key] = true
		out.append(row)
	return out


# a reward in words ("Signal of Crucible", "Refit", "Credits", "Repairs")
static func reward_label(C, rw) -> String:
	if rw == null or not (rw is Dictionary): return ""
	if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): return "Signal of " + str(C.PATRONS[rw["p"]]["short"])
	match rw.get("k"):
		"mod": return "Refit"
		"cred": return "Credits"
		"repair": return "Repairs"
	return ""
