extends RefCounted
# Exact-quarter counterpart of lineage.js. Public failures return null/false and set error.
const LEVEL_XP = [0, 6, 16, 30, 50, 75, 110, 160, 230]
const MASTERY_XP = [320, 440, 600]
var skills: Dictionary = {}
var admirals: Dictionary = {}
var error: String = ""

func configure(catalog: Dictionary, roster: Dictionary) -> bool:
	for s in catalog["skills"]:
		if skills.has(s["id"]): return fail("duplicate catalog id")
		skills[s["id"]] = s
	for a in roster["admirals"]:
		if admirals.has(a["id"]): return fail("duplicate admiral id")
		admirals[a["id"]] = a
	return true
func fail(message: String) -> bool:
	error = message
	return false
func integer(n: Variant) -> bool:
	return (n is int or n is float) and is_finite(float(n)) and float(n) >= 0.0 and float(n) <= 9007199254740991.0 and floor(float(n)) == float(n)
func level(xp_q: Variant) -> int:
	if not integer(xp_q): fail("invalid XP quarters"); return -1
	var n = 0
	for i in range(1, LEVEL_XP.size()):
		if xp_q >= LEVEL_XP[i] * 4: n = i
	return n
func validate_build(id: String, xp_q: Variant, picks: Variant, capstone: Variant) -> bool:
	if not admirals.has(id) or not integer(xp_q) or not (picks is Array): return fail("invalid build")
	if picks.size() > maxi(0, mini(3, level(xp_q) - 4)): return fail("too many picks for XP")
	var seen = {}; var tiers = {"A": [], "B": [], "C": []}
	for key in picks:
		if seen.has(key): return fail("duplicate pick")
		seen[key] = true
		var s = skills.get(key)
		if s == null or not s["owner"]["members"].has(id) or not tiers.has(s["branch"]): return fail("wrong owner or branch")
		tiers[s["branch"]].append(s["tier"])
	for ts in tiers.values():
		ts.sort()
		for i in range(ts.size()):
			if ts[i] != i + 1: return fail("exclusive pair or skipped branch tier")
	if capstone != null and capstone != "":
		var c = skills.get(capstone)
		if c == null or c["branch"] != "CAP" or not c["owner"]["members"].has(id) or level(xp_q) < 8: return fail("invalid capstone")
	return true
func new_state(masteries: Dictionary = {}) -> Variant:
	var lines = {}
	for a in admirals.values():
		var xp = masteries.get(a["id"], 0)
		if not (xp is int or xp is float) or not integer(float(xp) * 4.0): fail("invalid native mastery"); return null
		lines[a["id"]] = {"xpQ": minf(2400.0, float(xp) * 4.0), "overflowQ": maxf(0.0, float(xp) * 4.0 - 2400.0), "picks": [], "capstone": "", "respecs": 0}
	return {"version": 1, "lines": lines, "shadowPoolQ": {}, "awards": {}}
func valid_settlement_id(id: Variant) -> bool:
	if not (id is String) or id.length() < 1 or id.length() > 128: return false
	var letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	if not letters.contains(id[0]): return false
	for c in id:
		if not (letters + "._:-").contains(c): return false
	return true
func validate(state: Variant) -> bool:
	if not (state is Dictionary) or state.get("version") != 1 or not (state.get("lines") is Dictionary) or not (state.get("shadowPoolQ") is Dictionary) or not (state.get("awards") is Dictionary): return fail("unsupported lineage save")
	var facs = {}
	for a in admirals.values(): facs[a["fac"]] = true
	for fac in state["shadowPoolQ"]:
		if not facs.has(fac) or not integer(state["shadowPoolQ"][fac]): return fail("invalid shadow pool")
	for id in state["lines"]:
		if not admirals.has(id): return fail("unknown admiral line")
		var l = state["lines"][id]
		if not (l is Dictionary) or not (l.get("capstone") is String) or not integer(l.get("xpQ")) or l["xpQ"] > 2400 or not integer(l.get("overflowQ")) or not integer(l.get("respecs")): return fail("invalid line")
		if not validate_build(id, l["xpQ"], l.get("picks"), l.get("capstone")): return false
	for id in admirals:
		if not state["lines"].has(id): return fail("missing admiral line")
	for id in state["awards"]:
		if not valid_settlement_id(id) or not (state["awards"][id] is String): return fail("invalid settlement receipt")
	return true
func deserialize(text: String) -> Variant:
	var parsed = JSON.parse_string(text)
	return parsed if validate(parsed) else null
func serialize(state: Dictionary) -> String:
	return JSON.stringify(state) if validate(state) else ""
func choose(state: Dictionary, id: String, key: String, options: Dictionary = {}) -> Variant:
	if not validate(state): return null
	if options.get("liveRun", false): fail("choices are between runs"); return null
	var s = skills.get(key)
	if s == null or not admirals.has(id) or not s["owner"]["members"].has(id): fail("wrong owner"); return null
	if options.get("implementedOnly", true) and s["availability"] != "pilot_candidate": fail("effect not implemented in pilot"); return null
	var next = state.duplicate(true); var line = next["lines"][id]
	if s["branch"] == "CAP":
		if line["capstone"] != "": fail("capstone already chosen"); return null
		line["capstone"] = key
	else: line["picks"].append(key)
	return next if validate(next) else null
func respec(state: Dictionary, id: String, keys: Array, wallet: Variant, options: Dictionary = {}) -> Variant:
	if not validate(state) or not admirals.has(id) or not integer(wallet): fail("invalid respec"); return null
	if options.get("liveRun", false) or keys.is_empty(): fail("respec is between runs and needs picks"); return null
	var next = state.duplicate(true); var line = next["lines"][id]; var seen = {}; var owned = line["picks"].duplicate()
	if line["capstone"] != "": owned.append(line["capstone"])
	for key in keys:
		if seen.has(key) or not owned.has(key): fail("invalid refund"); return null
		seen[key] = true
	var cost = keys.size() * (25.0 + 10.0 * line["respecs"])
	if not integer(cost) or wallet < cost: fail("not enough renown"); return null
	var kept = []
	for key in line["picks"]:
		if not keys.has(key): kept.append(key)
	line["picks"] = kept
	if keys.has(line["capstone"]): line["capstone"] = ""
	line["respecs"] += 1
	return {"state": next, "wallet": wallet - cost, "cost": cost} if validate(next) else null
func base_xp(stats: Variant, victory: Variant) -> Variant:
	if not (stats is Dictionary) or not (victory is bool): fail("invalid reward stats"); return null
	for k in ["battles", "elites", "bosses"]:
		if not integer(stats.get(k)): fail("invalid reward count"); return null
	if stats["elites"] + stats["bosses"] > stats["battles"]: fail("elite/boss subsets invalid"); return null
	var xp = stats["battles"] + 2.0 * stats["elites"] + 5.0 * stats["bosses"] + (10.0 if victory else 0.0)
	if not integer(xp): fail("XP overflow"); return null
	return xp
func grant(state: Dictionary, report: Dictionary, id: String, q: Variant) -> bool:
	if not integer(q): return fail("invalid grant quarters")
	var l = state["lines"][id]; var credit = minf(float(q), 2400.0 - l["xpQ"])
	l["xpQ"] += credit; l["overflowQ"] += q - credit
	if not integer(l["overflowQ"]): return fail("overflow bank out of range")
	report["creditedQ"][id] = credit; report["overflowQ"][id] = q - credit
	return true
func award(state: Dictionary, event: Dictionary) -> Variant:
	if not validate(state): return null
	var id = event.get("id"); var heat = event.get("heat", 0); var heirs = event.get("heirLines", []); var receipt = event.get("settlementId")
	if not admirals.has(id) or not integer(heat) or heat > 1000 or not valid_settlement_id(receipt) or not (heirs is Array): fail("invalid reward event"); return null
	var active = admirals[id]; var seen = {}
	for h in heirs:
		if seen.has(h) or not admirals.has(h) or admirals[h]["fac"] != active["fac"] or h == id: fail("invalid heir line"); return null
		seen[h] = true
	var base = base_xp(event.get("stats"), event.get("victory"))
	if base == null: return null
	var stats = event["stats"]; var ordered = heirs.duplicate(); ordered.sort()
	var fingerprint = "%s|%d|%d|%d|%d|%d|%s" % [id, stats["battles"], stats["elites"], stats["bosses"], 1 if event["victory"] else 0, heat, ",".join(ordered)]
	if state["awards"].has(receipt):
		if state["awards"][receipt] != fingerprint: fail("conflicting settlement replay"); return null
		return {"state": state.duplicate(true), "duplicate": true, "report": null}
	var next = state.duplicate(true); var report = {"baseXp": base, "heatXp": 2.0 * heat, "creditedQ": {}, "overflowQ": {}, "shadowPoolQ": heat * 4.0}
	var flown = (base + 2.0 * heat) * 4.0
	if not grant(next, report, id, flown): return null
	for a in admirals.values():
		if a["id"] != id and a["fac"] == active["fac"]:
			if not grant(next, report, a["id"], flown / 4.0 * (2.0 if heirs.has(a["id"]) else 1.0)): return null
	next["shadowPoolQ"][active["fac"]] = next["shadowPoolQ"].get(active["fac"], 0) + heat * 4.0
	next["awards"][receipt] = fingerprint
	return {"state": next, "duplicate": false, "report": report} if validate(next) else null
