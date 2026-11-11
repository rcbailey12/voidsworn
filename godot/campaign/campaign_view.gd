extends RefCounted
# Read-only views of the campaign for the screens (issue #344, UI rollout 1; outside audit pass 1, finding 12, Board verdict:
# "build the read-only view API with the Lime Tactical screen rollout, screen by screen").
#
# A screen asks one of these functions for what it shows and gets plain values back (numbers, strings, small dictionaries and
# arrays it may keep or change freely). Nothing here writes to the campaign, draws a random number or keeps state, so calling
# a view never changes a run, a save or parity. When a save field is renamed or reshaped, only this file has to follow it;
# the screens that read through it do not.
#
# The Nemesis (Muse's check of PR 349, condition 1): every Nemesis fact here starts from C.nemRead() (issue 364, PR 399), the
# campaign's read with no side effect, and the commander it returns is handed to the campaign's own rules (nemNodeIs,
# nemBeh, nemWarnLine, nemPanelData, nemFull, nemMeetingLine), which resolve nothing when they are given one. This file
# never calls one of them without a commander, and never calls nemActive or ensureNemesis: those resolve the commander
# first (nemActive migrates an old save and builds a missing record). The rules stay in campaign.gd; nothing is restated
# here. godot/campaign/test/map_readonly_test.gd proves the property itself: opening the map, the Dossier and the Map key
# never creates or changes the Nemesis record, the run, the save or the random stream, even when the record is missing.
#
# The campaign map's Briefing layout (FINDINGS R165) reads: header, sector_notes, routes, stop_tip, nemesis, nem_dossier,
# purse, fleet_rows, faction_action and run_notes. Other readers move with their own screen groups.

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


# ---------------------------------------------------------------- the Nemesis, read only

# the commander the run is fighting now, or null (C.nemRead: no migration, no creation, no cache write)
static func nem(C) -> Variant:
	return C.nemRead() if C.RUN != null else null


# is this stop his meeting? campaign.gd nemNodeIs, asked of the commander already read (never without one)
static func nem_node_is(C, n) -> bool:
	var N = nem(C)
	return C.nemNodeIs(n, N) if _jt(N) and n != null else false


# his faction's behaviour table (campaign.gd nemBeh for a commander already read)
static func nem_beh(C, N) -> Dictionary:
	return C.nemBeh(N) if _jt(N) else {}


# what the next win does when it fills his clock (campaign.gd nemWarnLine); "" when it does not, or with no commander
static func nem_warn(C, N) -> String:
	return str(C.nemWarnLine(N)) if _jt(N) else ""


# The Nemesis block of the briefing column: who hunts you this sector, in a name and two or three lines. {} when the run has
# no commander. status is the one line that changes: dead, his strike is coming, met this sector, or the warning that the
# next win fills his clock ("" when there is nothing to say).
static func nemesis(C) -> Dictionary:
	var N = nem(C)
	if not _jt(N): return {}
	var R = C.RUN
	var F = C.FACTIONS.get(N.get("fac"), {})
	var P = C.NEM_PERSONA.get(N.get("persona")) if N.get("persona") != null else null
	var dead := _jt(N.get("dead"))
	var met := float(C.z0(N.get("met"))) >= float(R["sector"])
	var strike := _jt(R.get("nemStrike"))
	var status := ""
	if dead: status = str(C.nemFull(N)) + " is dead."
	elif strike: status = str(C.nemStrikeLine(N))
	elif met: status = "Met this sector."
	else: status = nem_warn(C, N)
	return {
		"fac": str(N.get("fac", "")), "fac_name": str(F.get("n", "")),
		"full": str(C.nemFull(N)), "dead": dead, "met": met, "strike": strike,
		"scars": int(float(C.z0(N.get("scars")))),
		"persona_n": str(P["n"]) if P != null else "", "persona_d": str(P["d"]) if P != null else "",
		"clock": C.nemClockGet(), "clock_max": float(C.NEM_CLOCK),
		"status": status,
	}


# The Dossier: everything the old long Nemesis block said, as lines of [kind, text] in the old order and wording. kind is
# "text", "warn" (what the next win will do), "head" (a caps head) or "name" (an earlier hunter's name line).
# His return, his lessons and the earlier hunters come from campaign.gd nemPanelData (nem_panel).
static func nem_dossier(C) -> Array:
	var out: Array = []
	var N = nem(C)
	if not _jt(N): return out
	var R = C.RUN
	var beh := nem_beh(C, N)
	var D = nem_panel(C, N)
	if _jt(N.get("dead")):
		out.append(["text", str(C.nemFull(N)) + " is dead."])
		_nem_earlier(out, D); return out
	if N.get("traits") is Array and N["traits"].size() > 0:
		var ts: Array = []
		for t in N["traits"]:
			if C.NEM_TRAITS.has(t): ts.append("[b]" + str(C.NEM_TRAITS[t]["n"]) + "[/b] (" + str(C.NEM_TRAITS[t]["d"]).trim_suffix(".") + ")")
		if not ts.is_empty(): out.append(["text", "Strengths: " + "; ".join(PackedStringArray(ts))])
	if beh.get("d") != null: out.append(["text", str(C.nemSay(str(beh["d"]), N))])
	var warn := nem_warn(C, N)
	if warn != "": out.append(["warn", warn])
	var ck: float = C.nemClockGet()
	var met := float(C.z0(N.get("met"))) >= float(R["sector"])
	var tail := (" " + str(C.nemStrikeLine(N))) if _jt(R.get("nemStrike")) else (" (met this sector)" if met else "")
	out.append(["text", "Hunting you: " + str(C.numstr(ck)) + "/" + str(C.numstr(C.NEM_CLOCK)) + tail])
	out.append(["text", str(C.nemMeetingLine(N))])
	if _jt(beh.get("feeds")):
		var fd := int(float(C.z0(N.get("fed"))))
		out.append(["text", "Fed: " + str(fd) + " of 8" + str(C.nemSay(" (his fleet has " + str(mini(32, 4 * fd)) + "% more hull; every ship you lose feeds him)", N))])
	if beh.get("strike") == "raid":
		var rc := int(float(C.z0(N.get("riches"))))
		out.append(["text", "Riches: " + str(rc) + str(C.nemSay(" (" + ("no extra ships yet" if rc == 0 else str(rc) + " extra ship" + ("s" if rc > 1 else "") + " in his fleet") + "; each escape or ship he tows adds one)", N))])
	if _jt(N.get("loot")) or _jt(N.get("held")):
		var hs: Array = []
		if _jt(N.get("loot")): hs.append(str(C.numstr(N["loot"])) + " of your credits")
		if _jt(N.get("held")): hs.append("the " + str(N["held"]["name"]))
		out.append(["text", str(C.nemPr(N)["He"]) + " holds " + " and ".join(PackedStringArray(hs)) + ": it all comes back when " + str(C.nemPr(N)["he"]) + " dies."])
	if beh.get("strike") == "duel" and _jt(N.get("honed")):
		var hn := mini(3, int(float(N["honed"])))
		out.append(["text", "Honed: " + str(hn) + " of 3" + str(C.nemSay(" (his few ships aim " + str(3 * hn) + " better and carry " + str(10 * hn) + "% stronger shields)", N))])
	if _jt(beh.get("revive")):
		out.append(["text", "Comeback: " + ("spent, the next kill is final" if _jt(N.get("revived")) else str(C.nemSay("in sector III his flagship rises once more after it falls; before that he withdraws like any rival", N)))])
	var ws: Array = []; var unknown := 0
	for w in N["weak"]:
		if N["revealed"].has(w): ws.append("[b]" + str(C.NEM_WEAK[w]["n"]) + "[/b] (" + str(C.NEM_WEAK[w].get("d", "")).trim_suffix(".") + ")")
		else: unknown += 1
	if unknown > 0: ws.append(("%d unknown" % unknown if ws.size() > 0 or unknown > 1 else "unknown") + " (win against him to learn " + ("one" if unknown > 1 else "it") + ")")
	out.append(["text", "Weaknesses: " + "; ".join(PackedStringArray(ws))])
	if N["adapt"].size() > 0:
		var ad: Array = []
		for a in N["adapt"]: ad.append("[b]" + str(C.nemAdaptName(a, N["fac"])) + "[/b] (" + str(C.nemAdaptDesc(a, N["fac"])).trim_suffix(".") + ")")
		out.append(["text", "Adapted: " + "; ".join(PackedStringArray(ad))])
	if _jt(N.get("last_beat")):
		out.append(["text", str(C.nemPr(N)["He"]) + " remembers losing to your " + str(C.NEM_BEAT_WORD.get(N["last_beat"], N["last_beat"])) + "."])
	if str(D.get("back", "")) != "": out.append(["text", str(D["back"])])
	if D.get("lessons") is Array and D["lessons"].size() > 0: out.append(["text", "Lessons: " + "; ".join(PackedStringArray(D["lessons"]))])
	_nem_earlier(out, D)
	return out


static func _nem_earlier(out: Array, D: Dictionary) -> void:
	if not (D.get("earlier") is Array) or D["earlier"].is_empty(): return
	out.append(["head", "Earlier hunters"])
	for E in D["earlier"]:
		out.append(["name", "[b]" + str(E["name"]) + "[/b] " + str(E["faction"])])
		out.append(["text", str(E["line"])])
		if E.get("lessons") is Array and E["lessons"].size() > 0: out.append(["text", "Lessons: " + "; ".join(PackedStringArray(E["lessons"]))])


# his return, his lessons and the commanders of the sectors passed: campaign.gd nemPanelData for a commander already read
# (the campaign decides what is shown, #122; this only asks without resolving anyone)
static func nem_panel(C, N) -> Dictionary:
	if not _jt(N): return {}
	var D = C.nemPanelData(N)
	return D if D is Dictionary else {}


# ---------------------------------------------------------------- the map's words

const KIND_WORD := {"battle": "Fight", "elite": "Elite fight", "boss": "Flagship fight", "event": "Event", "shipyard": "Shipyard", "drydock": "Drydock", "field": "Field repairs"}
const KIND_NOTE := {"shipyard": "buy, repair, upgrade", "drydock": "free repairs", "field": "every ship patches 20%", "event": "anything can happen"}


# a faction's name inside a sentence ("the Glasswrights", "Ashfall Hullbreakers")
static func fac_in_sentence(C, fac) -> String:
	if not C.FACTIONS.has(fac): return ""
	var n := str(C.FACTIONS[fac]["n"])
	return ("the " + n.trim_prefix("The ")) if n.begins_with("The ") else n


static func _article(word: String) -> String:
	return "an" if word.substr(0, 1).to_lower() in ["a", "e", "i", "o", "u"] else "a"


# what a stop is called on the map: the encounter's name for a fight not yet fought, else its kind
static func stop_name(C, n) -> String:
	if n == null: return ""
	var t := str(n["type"])
	if t == "boss": return "Sector flagship"
	if _jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]) and not _jt(n.get("done")): return str(C.ENCOUNTERS[n["enc"]]["n"])
	return str(C.NODE_INFO[t]["n"]) if C.NODE_INFO.has(t) else t


# One stop in words, for a route row or the map's hover tip. Everything the old fight card and the old hover card said
# about the stop itself is here; the screen decides what sits on the row and what waits one hover away.
#   kind: the stop's type; kind_word: "Fight", "Elite fight", "Flagship fight", "Event", "Shipyard", ...
#   what: one line, what it is and against whom ("Fight against a Glasswrights sliver flight", "Event: anything can happen")
#   fight: whether there is a fight; reward: the reward in words ("" when none); note: the one-line note of a stop with no fight
#   objective, arch, arch_d, mod, mod_d, shape, place: the old card's long words; nemesis: the Nemesis meets you here
static func stop(C, n) -> Dictionary:
	if n == null or C.RUN == null: return {}
	var t := str(n["type"])
	var fight := t in ["battle", "elite", "boss"]
	var done := _jt(n.get("done"))
	var row := {"id": str(n["id"]), "kind": t, "kind_word": str(KIND_WORD.get(t, t)), "name": stop_name(C, n), "fight": fight, "done": done,
		"fac": "", "fac_name": "", "rival": false, "what": "", "note": "", "objective": "", "arch": "", "arch_d": "", "mod": "", "mod_d": "",
		"shape": "", "place": "", "reward": "", "reward_min": false, "nemesis": false}
	if not fight:
		row["note"] = str(KIND_NOTE.get(t, ""))
		row["objective"] = str(C.NODE_INFO[t]["d"]) if C.NODE_INFO.has(t) else ""
		row["what"] = row["kind_word"] + ((": " + row["note"]) if row["note"] != "" else "")
		return row
	var fac = C.nodeFaction(n) if t != "boss" else C.RUN["map"]["fac"]
	row["fac"] = str(fac); row["fac_name"] = str(C.FACTIONS[fac]["n"]) if C.FACTIONS.has(fac) else ""
	row["rival"] = t == "battle" and str(fac) != str(C.RUN["map"]["fac"])
	row["nemesis"] = not done and nem_node_is(C, n)
	if t == "boss":
		row["objective"] = "The sector's command ship and its escort. Beat it to end the sector."
	elif _jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]):
		row["objective"] = str(C.ENCOUNTERS[n["enc"]]["d"])
		if _jt(n.get("arch")) and C.ARCHETYPES.has(n["arch"]):
			var a = C.effArch(n["arch"], fac)
			if a != null and C.ARCHETYPES.has(a):
				var names = C.ARCHETYPES[a]["names"]
				row["arch"] = str(names.get(fac, names.get("hegemony", "")))
				row["arch_d"] = str(C.ARCHETYPES[a]["d"])
		if _jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]):
			row["mod"] = str(C.NODE_MODS[n["mod"]]["n"]); row["mod_d"] = str(C.NODE_MODS[n["mod"]]["d"])
		if _jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]): row["shape"] = str(C.SHAPES[n["shape"]])
	if _jt(n.get("map")) and C.MAP_NAME.has(n["map"]): row["place"] = str(C.MAP_NAME[n["map"]])
	var who := fac_in_sentence(C, fac)
	if row["nemesis"]:
		row["what"] = "Nemesis meeting: an elite fight with " + str(C.nemPr(nem(C))["his"]) + " fleet"
		row["what_tip"] = "Elite fight against " + str(C.nemFull(nem(C))) + "'s fleet"   # the tip says "The Nemesis meets you here" on its own red line
	elif row["arch"] != "":
		var adj := str(row["fac_name"]).trim_prefix("The ")
		row["what"] = row["kind_word"] + " against " + _article(adj) + " " + adj + " " + str(row["arch"]).to_lower()
	else:
		row["what"] = row["kind_word"] + " against " + who
	if row["rival"] and not row["nemesis"]: row["what"] += " (rival raiders)"
	var rw = n.get("rw")
	if rw is Dictionary and not done:
		row["reward"] = reward_label(C, rw) + (" (rare or better)" if _jt(rw.get("min")) else "")
		row["reward_min"] = _jt(rw.get("min"))
	if t == "elite" and not done: row["reward"] = (str(row["reward"]) + " and salvage") if row["reward"] != "" else "Salvage"
	return row


# The route rows of the briefing column: one per stop you can jump to now, numbered from the outer orbit inward (the
# stop's own place in its column, so 1, 2, 3 read across the map the way they read down the list; the number keys and the
# map markers use the same numbers). Each is stop() plus num and then: the names of the stops that route leads to, from
# the real map edges, each name once.
static func routes(C) -> Array:
	var out: Array = []
	if C.RUN == null or C.page.get("kind") != "map": return out
	var ids: Array = []
	for id in C.page["data"]["avail"]:
		if C.findNode(id) != null: ids.append(id)
	var order := {}
	for j in ids.size(): order[ids[j]] = j
	ids.sort_custom(func(a, b):
		var ya := float(C.z0(C.findNode(a).get("y"))); var yb := float(C.z0(C.findNode(b).get("y")))
		return ya < yb if ya != yb else int(order[a]) < int(order[b]))
	var i := 0
	for id in ids:
		var n = C.findNode(id)
		i += 1
		var row := stop(C, n)
		row["num"] = i
		var then: Array = []
		for e in C.RUN["map"]["edges"]:
			if e[0] != id: continue
			var nm := stop_name(C, C.findNode(e[1]))
			if nm != "" and not then.has(nm): then.append(nm)
		row["then"] = then
		out.append(row)
	return out


# where the fleet is, in words: the stop it holds, or "" before the first jump of a sector
static func here_name(C) -> String:
	if C.RUN == null or not _jt(C.RUN.get("pos")): return ""
	var n = C.findNode(C.RUN["pos"])
	if n == null: return ""
	if _jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]): return str(C.ENCOUNTERS[n["enc"]]["n"])
	return stop_name(C, n)


# The sector in words: who holds it, the sector condition, the rival raiders, the cores in range and the run's Heat rules.
# The header carries holder and cond; the rest sits in the Map key under "This sector".
static func sector_notes(C) -> Dictionary:
	var R = C.RUN
	if R == null: return {}
	var m = R["map"]; var F = C.FACTIONS.get(m["fac"], {})
	var cond = C.sectorCond()
	var rivals: Array = []
	if R.get("foes") is Array and R["foes"].size() >= 5:
		for f in [R["foes"][3], R["foes"][4]]:
			if C.FACTIONS.has(f): rivals.append(str(C.FACTIONS[f]["n"]).trim_prefix("The "))
	var cores: Array = []
	for p in R["patrons"]:
		if C.PATRONS.has(p): cores.append({"short": str(C.PATRONS[p]["short"]), "name": str(C.PATRONS[p]["n"]), "theme": str(C.PATRONS[p]["theme"])})
	var heat: Array = []
	if R.get("heat") is Array:
		for kk in R["heat"]:
			if C.HEAT.has(kk): heat.append({"n": str(C.HEAT[kk]["n"]), "d": str(C.HEAT[kk]["d"])})
	return {"holder": str(F.get("n", "")), "holder_blurb": str(F.get("blurb", "")),
		"cond_n": str(cond["n"]) if cond != null else "", "cond_d": str(cond["d"]) if cond != null else "",
		"rivals": rivals, "cores": cores, "heat": heat, "heat_level": float(C.heatLevel(R["heat"])) if R.get("heat") is Array and R["heat"].size() > 0 else 0.0}


# The faction action in one line: its name, what it does, its cost in short words, and whether it is used this sector or
# armed for the next battle. {} when the faction has none.
static func faction_action(C) -> Dictionary:
	var V = C.verbFor()
	if V == null: return {}
	var R = C.RUN
	var used := float(C.z0(R.get("verbUsed"))) >= float(R["sector"])
	var cost := str(C.verbCostText(V))
	var short := "Free" if cost.begins_with("Free") else cost.trim_prefix("Costs ")
	return {"n": str(V["n"]), "d": str(V["d"]), "cost": cost, "cost_short": short, "used": used, "armed": _jt(R.get("verbNext"))}


# What carries the run, for the Map key's "Your run": the admiral, the flagship's aspect, the protocols and the salvage.
static func run_notes(C) -> Dictionary:
	var R = C.RUN
	if R == null: return {}
	var boons: Array = []
	for b in R["boons"]:
		var B0 = C.BOONS[b["id"]]; var r := int(float(C.z0(b.get("r"))))
		boons.append({"n": str(B0["n"]), "tier": "Duo" if _jt(B0.get("duo")) else str(C.RARITY[r]["n"]), "d": str(C.BOON_D[b["id"]][r])})
	var relics: Array = []
	for r in R["relics"]: relics.append({"n": str(C.relicName(r)), "d": str(C.RELICS[r]["d"])})
	return {"admiral": admiral(C), "aspect": aspect(C), "boons": boons, "relics": relics, "hold": hold_count(C)}


# a reward in words ("Signal of Crucible", "Refit", "Credits", "Repairs")
static func reward_label(C, rw) -> String:
	if rw == null or not (rw is Dictionary): return ""
	if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): return "Signal of " + str(C.PATRONS[rw["p"]]["short"])
	match rw.get("k"):
		"mod": return "Refit"
		"cred": return "Credits"
		"repair": return "Repairs"
	return ""
