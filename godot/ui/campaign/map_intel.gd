extends RefCounted
# Map intel for the 3D sector map (G3, R38): the numbers behind the route planner and the danger bands. Presentation only:
# it reads the campaign state and never draws from the rules' random numbers.
#
# Danger: an estimate of how hard a fight is for the fleet you have now, from the same numbers the game uses to build the
# enemy fleet (battle.js genEnemyFleet: the column budget, RAMP.grow, the elite and boss factors, your fleet power against
# the sector's reference fleet, Standard AI, Heat, bounty) and to scale it (startBattle: sector hull and damage scale,
# RAMP.thin, boss scale), set against your fleet power (battle.js fleetPower). The fleet itself is rolled at the fight, so
# this is the expected strength, not the exact one.

const BANDS := [[0.8, "Easy", Color("#7ddc6a")], [1.05, "Even", Color("#d0a64b")], [1.4, "Hard", Color("#f0883a")], [99.0, "Deadly", Color("#e2453a")]]

var C
var ai_level := "veteran"     # the battle setting (godot/main settings "ai"); Standard meets 10% less

func _init(campaign) -> void: C = campaign

func fleet_power() -> float:   # battle.js fleetPower
	if C.RUN == null: return 99.0
	var p = 0.0
	for sh in C.RUN["fleet"]:
		if float(sh["hp"]) <= 0: continue
		var d = C.derive(sh); var hp = min(1.0, float(sh["hp"]) / max(1.0, float(d["maxHp"]))); var cp = float(C.or_(C.HULLS[sh["tpl"]].get("cp"), 1))
		p += cp * (0.4 + 0.6 * hp) * (1.0 + 0.12 * (float(C.or_(sh.get("mk"), 1)) - 1.0) + 0.03 * sh["mods"].size() + 0.04 * float(C.z0(sh["cap"].get("rank")))) + float(C.z0(d["hangar"])) * 0.45 * (0.5 + 0.5 * hp)
	var boons = 0.0
	for b in C.or_(C.RUN.get("boons"), []): boons += float(C.RARITY[int(C.z0(b.get("r")))]["m"])
	return p * (1.0 + 0.035 * boons + 0.025 * C.RUN["relics"].size())

func danger(n: Dictionary) -> Dictionary:
	var t = n["type"]
	if not (t in ["battle", "elite", "boss"]): return {}
	var R = C.TB["RAMP"]; var s = int(C.RUN["sector"]); var col = float(n["col"]); var kind = t
	var budget = ([0.0, 4.2, 9.5, 14.0][s] + col * (0.9 if s == 1 else (1.0 if s == 2 else 1.1))) * float(R["grow"][s])
	if kind == "elite": budget *= 1.05
	var P = fleet_power()
	var boss_part = 0.0
	if kind == "boss":
		budget *= float(R["boss"][s])
		var fac = C.RUN["map"]["fac"]; var btpl = C.FACTIONS[fac].get("boss")
		var bcp = float(C.or_(C.HULLS[btpl].get("cp"), 6)) if btpl != null and C.HULLS.has(btpl) else 6.0
		var fit = max(0.55, min(1.0, P / [0.0, 6.0, 9.0, 12.0][s]))
		boss_part = bcp * float(C.TB["BOSS_SCALE"][s]) * fit * float(C.TB["BOSS_FAC"].get(fac, 1.0)) * float(C.TB["BOSS_DMG"][s]) * (1.2 if C.heatOn("h_flag") else 1.0) * 1.6
	budget *= max(float(R["pwMin"]), min(float(R["pwMax"]), pow(max(0.5, P) / float(R["refP"][s]), float(R["pw"]))))
	if ai_level == "standard": budget *= float(R["std"])
	if C.heatOn("h_hunted"): budget *= 1.15
	if n.get("mod") == "bounty": budget *= 1.1
	var tough = (1.0 + 0.12 * (s - 1)) * (1.0 + 0.08 * (s - 1)) * float(R["thin"][s]) * (float(R["escort"]) if kind == "boss" else 1.0)
	var threat = budget * tough + boss_part
	if kind == "elite": threat *= 1.25            # the bigger half of an elite fleet are elites
	if n.get("mod") == "veteran": threat *= 1.08
	if C.heatOn("h_elite"): threat *= 1.08
	var ratio = threat / max(0.5, P)
	for b in BANDS:
		if ratio < b[0]: return {"ratio": ratio, "band": b[1], "col": b[2], "threat": threat, "power": P}
	return {}

func band_index(name: String) -> int:
	for i in BANDS.size():
		if BANDS[i][1] == name: return i
	return -1

# ---------------- routes ----------------
func _by_id() -> Dictionary:
	var by = {}
	for c in C.RUN["map"]["cols"]:
		for n in c: by[n["id"]] = n
	return by
func _next(id: String) -> Array:
	var out = []
	for e in C.RUN["map"]["edges"]:
		if e[0] == id: out.append(e[1])
	return out
# every path from the nodes you can jump to now to the sector flagship
func all_paths() -> Array:
	var starts = C.availableNodes()
	var out = []
	for s in starts: _walk([s], out)
	return out
func _walk(p: Array, out: Array) -> void:
	var nx = _next(p[p.size() - 1])
	if nx.is_empty():
		out.append(p.duplicate()); return
	for x in nx:
		p.append(x); _walk(p, out); p.pop_back()
func is_repair(n: Dictionary) -> bool: return n["type"] in ["shipyard", "drydock", "field"] or (n.get("rw") is Dictionary and n["rw"].get("k") == "repair")
func path_stats(p: Array) -> Dictionary:
	var by = _by_id()
	var st = {"fights": 0, "elites": 0, "repairs": 0, "shops": 0, "events": 0, "boons": 0, "refits": 0, "credits": 0, "relics": 0, "danger": 0.0, "worst": 0, "worst_name": "None", "running": [], "repair_before_boss": false}
	for id in p:
		var n = by[id]; var t = n["type"]
		if t in ["battle", "elite", "boss"]:
			if t != "boss": st["fights"] += 1
			if t == "elite": st["elites"] += 1; st["relics"] += 1
			var d = danger(n) if t != "boss" else {}   # the flagship ends every route, so it is left out of the comparison
			if not d.is_empty():
				st["danger"] += d["ratio"]; var bi = band_index(d["band"])
				if bi > st["worst"] or st["worst_name"] == "None":
					st["worst"] = bi; st["worst_name"] = d["band"]
		if t == "shipyard": st["shops"] += 1
		if t == "event": st["events"] += 1
		if is_repair(n) and t != "boss": st["repairs"] += 1; st["repair_before_boss"] = true
		var rw = n.get("rw")
		if rw is Dictionary and t != "boss":
			match rw.get("k"):
				"boon": st["boons"] += 1
				"mod": st["refits"] += 1
				"cred": st["credits"] += 1
		st["running"].append({"id": id, "fights": st["fights"], "repairs": st["repairs"], "danger": st["danger"]})
	st["value"] = st["boons"] * 3 + st["relics"] * 4 + st["refits"] * 2 + st["credits"] + st["shops"] * 2 + st["events"]
	return st
# the routes through one node: the safest and the richest (one when they are the same path)
func routes_through(id: String) -> Array:
	var ps = all_paths().filter(func(p): return p.has(id))
	if ps.is_empty(): return []
	var scored = []
	for p in ps: scored.append({"path": p, "st": path_stats(p)})
	var safe = scored[0]; var rich = scored[0]
	for x in scored:
		var a = x["st"]; var b = safe["st"]
		if a["worst"] < b["worst"] or (a["worst"] == b["worst"] and (a["danger"] - a["repairs"] * 0.3) < (b["danger"] - b["repairs"] * 0.3)): safe = x
		if x["st"]["value"] > rich["st"]["value"] or (x["st"]["value"] == rich["st"]["value"] and x["st"]["danger"] < rich["st"]["danger"]): rich = x
	var out = [{"name": "Safest", "col": Color("#62ccff"), "path": safe["path"], "st": safe["st"]}]
	if rich["path"] != safe["path"]: out.append({"name": "Richest", "col": Color("#e0b04a"), "path": rich["path"], "st": rich["st"]})
	return out
# the fleet's condition: average hull, the most damaged ship, and whether that calls for a repair stop
func fleet_condition() -> Dictionary:
	var tot = 0.0; var n = 0; var low = 1.0
	for sh in C.RUN["fleet"]:
		var f = float(sh["hp"]) / max(1.0, float(C.derive(sh)["maxHp"])); tot += f; n += 1; low = min(low, f)
	var avg = tot / max(1, n)
	return {"avg": avg, "low": low, "hurt": avg < 0.65 or low < 0.4}
