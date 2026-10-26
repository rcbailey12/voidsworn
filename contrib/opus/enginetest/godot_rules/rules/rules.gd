# Voidsworn battle rules, ported line for line from data.js, core.js and battle.js (A3 parity spike, Oct 25 2026).
# Objects stay Dictionaries with the JS field names, so the golden records compare field by field. Numbers stay doubles like JS
# (division always with a float operand, Math.round through JSM.jsround, % on doubles through fmod).
# Async rules functions run synchronously: in the headless game every await resolves at once and every call is awaited in turn,
# except deaths queued by turn ticks (fire, acid, the dead star, station guns), whose tail runs later in JS; those tails are deferred
# here and run by flush_deferred() at the point where the game awaits them.
# Presentation (log text, floating numbers, sounds, camera) is not ported: the harness gives it no-op stubs on both sides.
# Anything the slice does not reach and the port does not carry stops the run with "NOT PORTED", so a gap can never pass silently.
extends RefCounted
const JSM = preload("res://rules/jsm.gd")

var TB: Dictionary = {}
var WPN; var ARC_NAME; var FAC_WNAMES; var FAC_WTRAIT; var HULLS; var MOVE_RULES; var FACTIONS; var ABILITIES; var ORDERS; var MODULES; var PERKS
var RANK_XP; var RELICS; var ADMIRALS; var SHIP_NAMES; var CAPTAINS; var MORE_SHIP_NAMES; var SECTOR_CONDS; var RARITY; var ASPECTS
var DIRS; var PACE; var BLOCKING; var SHAPES; var BEVENTS; var ENC_ARENA; var FAC_MAP; var ENCOUNTERS; var CREW_MULT; var BOARD_MULT; var RAM_FAC
var BOSS_FAC; var BOSS_SCALE; var BOSS_DMG; var RAMP; var ARENAS; var AXIS_SHAPES; var MOVE_BASE; var SEC_OF_QUAD; var CMD_POW; var BOSS_CMD; var FACTION_AI
var ROCK_KINDS; var REGION_BIOME; var COMMANDS
var BW = 30; var BH = 22; var CX = 2; var HEX_S = 10.0; var HEX_W = 0.0; var ENC_ROUNDS = 6
var WELL_RIM = 3; var WELL_PULL = 5; var WELL_ASSIST = 6; var WELL_DMG = 7

var META: Dictionary = {}
var RUN: Variant = null
var B: Variant = null
var ARENA: Dictionary = {}
var CUT: Variant = null    # Set of "q,r" (Dictionary) or null
var SOLID: Variant = null
var TERRAIN_META: Dictionary = {}
var UID = 1
var AI_LEVEL = "veteran"
var deferred: Array = []   # killUnit tails from queued deaths (JS: continuations that run when the game awaits the turn's deaths)
var SQRT3 = sqrt(3.0)

# ======================= loading =======================
func load_tables(path: String) -> String:
	var txt = FileAccess.get_file_as_string(path)
	var j = JSON.parse_string(txt)
	if j == null: return "cannot read " + path
	TB = _dec(j["tables"])
	var sum = JSM.sha256(JSM.canon(TB, "t", {}, true))
	if sum != j["sha256"]: return "table checksum differs: " + sum + " vs " + str(j["sha256"])
	WPN = TB.W; ARC_NAME = TB.ARC_NAME; FAC_WNAMES = TB.FAC_WNAMES; FAC_WTRAIT = TB.FAC_WTRAIT; HULLS = TB.HULLS; MOVE_RULES = TB.MOVE_RULES
	FACTIONS = TB.FACTIONS; ABILITIES = TB.ABILITIES; ORDERS = TB.ORDERS; MODULES = TB.MODULES; PERKS = TB.PERKS; RANK_XP = TB.RANK_XP; RELICS = TB.RELICS
	ADMIRALS = TB.ADMIRALS; SHIP_NAMES = TB.SHIP_NAMES; CAPTAINS = TB.CAPTAINS; MORE_SHIP_NAMES = TB.MORE_SHIP_NAMES; SECTOR_CONDS = TB.SECTOR_CONDS
	RARITY = TB.RARITY; ASPECTS = TB.ASPECTS; DIRS = TB.DIRS; PACE = TB.PACE; BLOCKING = TB.BLOCKING; SHAPES = TB.SHAPES; BEVENTS = TB.BEVENTS
	ENC_ARENA = TB.ENC_ARENA; FAC_MAP = TB.FAC_MAP; ENCOUNTERS = TB.ENCOUNTERS; CREW_MULT = TB.CREW_MULT; BOARD_MULT = TB.BOARD_MULT; RAM_FAC = TB.RAM_FAC
	BOSS_FAC = TB.BOSS_FAC; BOSS_SCALE = TB.BOSS_SCALE; BOSS_DMG = TB.BOSS_DMG; RAMP = TB.RAMP; ARENAS = TB.ARENAS; AXIS_SHAPES = TB.AXIS_SHAPES
	MOVE_BASE = TB.MOVE_BASE; SEC_OF_QUAD = TB.SEC_OF_QUAD; CMD_POW = TB.CMD_POW; BOSS_CMD = TB.BOSS_CMD; FACTION_AI = TB.FACTION_AI
	ROCK_KINDS = TB.ROCK_KINDS; REGION_BIOME = TB.REGION_BIOME; COMMANDS = TB.COMMANDS
	BW = int(TB.BW); BH = int(TB.BH); CX = int(TB.CX); HEX_S = float(TB.HEX_S); HEX_W = float(TB.HEX_W); ENC_ROUNDS = int(TB.ENC_ROUNDS)
	WELL_RIM = int(TB.WELL_RIM); WELL_PULL = int(TB.WELL_PULL); WELL_ASSIST = int(TB.WELL_ASSIST); WELL_DMG = int(TB.WELL_DMG)
	META = TB.META.duplicate(true)
	return ""
func _dec(v):
	if v is Dictionary:
		var o = {}
		for k in v.keys(): o[k] = _dec(v[k])
		return o
	if v is Array:
		var a = []
		for x in v: a.append(_dec(x))
		return a
	if v is String and v.begins_with("#d:"): return JSM.from_hex64(v.substr(3))
	return v

# ======================= JS helpers =======================
var not_ported := ""   # set by np(); the harness stops at the next record and reports it
func np(what: String) -> void:
	if not_ported == "": not_ported = what
	push_error("NOT PORTED: " + what)
func jt(x) -> bool: # JS truthiness (named jt: Object.tr is taken)
	if x == null: return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING: return x != ""
	return true
func z0(x) -> Variant: # x||0
	return x if jt(x) else 0
func g(d, k) -> Variant: # d && d[k]
	if d is Dictionary: return d.get(k)
	return null
func at(a, i) -> Variant: # a[i] (undefined past the end)
	if a is Array:
		var n = int(i)
		if n >= 0 and n < a.size(): return a[n]
	return null
func dup(u: Dictionary) -> Dictionary: # Object.create(u) for reads: a shallow copy
	return u.duplicate(false)
func fl(x) -> float: return floor(float(x))
func rnd() -> float: return JSM.rnd()
func ri(a, b) -> float: return float(a) + floor(rnd() * (float(b) - float(a) + 1.0))
func pick(a: Array) -> Variant:
	return a[int(floor(rnd() * a.size()))] if a.size() > 0 else null
func clamp_(v, a, b) -> Variant: return max(a, min(b, v))
func new_id() -> String:
	var id = "x0" + str(UID); UID += 1; return id
func log_(_m = null, _k = null) -> void: pass   # battle log text: presentation, not compared

# ======================= data.js =======================
func wName(fac, id) -> Variant:
	var fw = g(FAC_WNAMES, fac)
	if fw != null and jt(g(fw, id)): return fw[id]
	if WPN.has(id) and jt(WPN[id].get("n")): return WPN[id]["n"]
	return id
func trait_fx(tk: String, w: Dictionary) -> void:
	match tk:
		"las": w["fall"] = ceil(float(w["fall"]) / 2.0); w["acc"] = w["acc"] + 4
		"hellfire": w["ignite"] = 1
		"plasma": w["pierce"] = max(z0(w.get("pierce")), 0.25); w["dmg"] = w["dmg"] + 1
		"scrap": w["shots"] = w["shots"] + 1; w["acc"] = w["acc"] - 12; w["crit"] = z0(w.get("crit")) + 3
		"rockets": w["shots"] = w["shots"] * 3; w["dmg"] = JSM.jsround(float(w["dmg"]) / 2.9); w["acc"] = w["acc"] + 2; w["evMult"] = 1.5; w["rockets"] = 1
		"spines": w["shred"] = 0.03
		"acid": w["acid"] = 1
		"needle": w["acc"] = w["acc"] + 6; w["crit"] = z0(w.get("crit")) + 8
		"star": w["evMult"] = 1.2
		"gauss": w["armorPierce"] = 0.5
		_: np("weapon trait " + tk)
func nameWeapons(fac, list: Array) -> Array:
	for w in list:
		w["n"] = wName(fac, w["id"])
		var ft = g(FAC_WTRAIT, fac)
		var tk = g(ft, w["id"]) if ft != null else null
		if jt(tk) and TB.WTRAITS.has(tk) and not jt(w.get("trait")):
			w["trait"] = tk; trait_fx(tk, w)
	return list

# ======================= core.js =======================
func hkey(q, r) -> String: return str(int(q)) + "," + str(int(r))
func hdist(a, b) -> float:
	var dq = float(a["q"]) - float(b["q"]); var dr = float(a["r"]) - float(b["r"])
	return (absf(dq) + absf(dr) + absf(dq + dr)) / 2.0
func axPx(q, r) -> Dictionary: return {"x": SQRT3 * (float(q) + float(r) / 2.0), "y": 1.5 * float(r)}
func angTo(a, b) -> float:
	var pa = axPx(a["q"], a["r"]); var pb = axPx(b["q"], b["r"])
	return JSM.atan2(pb.y - pa.y, pb.x - pa.x) * 180.0 / PI
func relAng(u, t) -> float:
	var d = angTo(u, t) - float(u["facing"]) * 60.0
	d = fmod(fmod(d, 360.0) + 540.0, 360.0) - 180.0
	return d
func inArc(u, t, arc) -> bool:
	if arc == "T": return true
	var a = relAng(u, t); var A = absf(a)
	if arc == "F": return A <= 60.5
	if arc == "R": return A >= 119.5
	if arc == "S": return a >= 29.5 and a <= 150.5
	if arc == "P": return a <= -29.5 and a >= -150.5
	return false
func shieldQuad(t, att) -> int:
	var b = relAng(t, att); var A = absf(b)
	if A < 50: return 0
	if A > 130: return 2
	return 1 if b > 0 else 3
func cubeRound(x: float, z: float) -> Dictionary:
	var y = -x - z; var rx = JSM.jsround(x); var rz = JSM.jsround(z); var ry = JSM.jsround(y)
	var dx = absf(rx - x); var dy = absf(ry - y); var dz = absf(rz - z)
	if dx > dy and dx > dz: rx = -ry - rz
	elif dy <= dz: rz = -rx - ry
	return {"q": rx, "r": rz}
func hexLine(a, b) -> Array:
	var N = hdist(a, b); var out = []
	var i = 0
	while i <= N:
		var t = float(i) / N if N != 0.0 else 0.0
		out.append(cubeRound(float(a["q"]) + (float(b["q"]) - float(a["q"])) * t + 1e-6, float(a["r"]) + (float(b["r"]) - float(a["r"])) * t + 1e-6))
		i += 1
	return out
func capName(fac) -> String:
	var C = CAPTAINS.get(fac) if CAPTAINS.has(fac) else CAPTAINS["voidsworn"]
	var used = {}
	if RUN != null and RUN.get("fleet") != null:
		for s in RUN["fleet"]:
			if jt(s.get("cap")): used[String(s["cap"]["name"]).split(" ")[0]] = true
	var n = ""
	for i in range(8):
		if jt(C.get("names")):
			n = String(pick(C["names"])) + ((" " + String(pick(C["epithets"]))) if jt(C.get("epithets")) else "")
		else:
			var f = String(pick(C["first"])); n = f + " " + String(pick(C["last"]))
		if not used.has(n.split(" ")[0]): break
	return n
func factionOfTpl(tpl) -> String:
	var h = HULLS.get(tpl)
	if h != null and jt(h.get("fac")): return h["fac"]
	for f in FACTIONS.keys():
		var F2 = FACTIONS[f]
		if (F2.get("roster") if F2.get("roster") != null else []).has(tpl) or F2.get("boss") == tpl: return f
	return "voidsworn"
func shipName(fac) -> String:
	var used = {}
	if RUN != null:
		for s in RUN["fleet"]: used[s["name"]] = true
	var base: Array
	if not jt(fac) or fac == "voidsworn": base = SHIP_NAMES
	else: base = [] + (MORE_SHIP_NAMES.get(fac) if MORE_SHIP_NAMES.has(fac) else [])   # FNAMES is not defined headless (typeof check in the game)
	var pool = []
	for n in (base if base.size() > 0 else SHIP_NAMES):
		if not used.has(n): pool.append(n)
	return pick(pool if pool.size() > 0 else SHIP_NAMES)
func newCaptain(vet, fac) -> Dictionary:
	var c = {"fac": fac if jt(fac) else "voidsworn"}
	c["name"] = capName(fac); c["xp"] = 0; c["rank"] = 0; c["perks"] = []; c["pending"] = 0
	if jt(vet):
		c["xp"] = RANK_XP[1]; c["rank"] = 1; c["perks"] = [pick(PERKS.keys())]
	return c
func newShip(tpl, vet) -> Dictionary:
	var fac = factionOfTpl(tpl)
	var s = {"uid": new_id(), "tpl": tpl}
	s["name"] = shipName(fac); s["mk"] = 1; s["hp"] = 0; s["mods"] = []; s["cap"] = newCaptain(vet, fac)
	s["hp"] = derive(s)["maxHp"]
	return s
func sumFx(list: Array) -> Dictionary:
	var o = {}
	for fx in list:
		if not jt(fx): continue
		for k in fx.keys(): o[k] = z0(o.get(k)) + fx[k]
	return o
func fleetFxList() -> Array:
	var l = []
	if RUN != null:
		for r in RUN["relics"]:
			if RELICS.has(r) and jt(RELICS[r].get("fx")): l.append(RELICS[r]["fx"])
		if ADMIRALS.has(RUN["admiral"]): l.append(ADMIRALS[RUN["admiral"]].get("fx"))
		for b in (RUN.get("boons") if RUN.get("boons") != null else []): np("boon effects (BOONS[id].fx is code)")
	return l
func hasBoon(id) -> bool:
	if RUN == null or RUN.get("boons") == null: return false
	for b in RUN["boons"]:
		if b["id"] == id: return true
	return false
func runFx() -> Dictionary:
	var o = {}
	if RUN != null:
		for r in RUN["relics"]:
			var x = RELICS[r].get("run") if RELICS.has(r) else null
			if jt(x):
				for k in x.keys(): o[k] = z0(o.get(k)) + x[k]
	if RUN != null and jt(META["unlocked"].get("salvagers")): o["credPct"] = z0(o.get("credPct")) + 0.2
	return o
func mkWeapon(id, arc, fx) -> Dictionary:
	var b: Dictionary = WPN[id]
	var w = {"id": id, "arc": arc}
	for k in b.keys(): w[k] = b[k]
	w["cd"] = z0(b.get("cd"))
	if b.get("k") == "battery" and jt(fx.get("battShots")): w["shots"] = w["shots"] + fx["battShots"]
	if b.get("k") == "flak" and jt(fx.get("flakPlus")):
		w["shots"] = w["shots"] + 2 * fx["flakPlus"]; w["r"] = w["r"] + fx["flakPlus"]; w["opt"] = w["opt"] + fx["flakPlus"]
	if b.get("k") == "torp" and jt(fx.get("torpCd")): w["cd"] = max(1, w["cd"] - fx["torpCd"])
	if arc == "F" and jt(fx.get("prowRange")):
		w["r"] = w["r"] + fx["prowRange"]; w["opt"] = w["opt"] + fx["prowRange"]
	return w
func derive(ship: Dictionary) -> Dictionary:
	var t: Dictionary = HULLS[ship["tpl"]]
	var asp = []
	if RUN != null and jt(RUN.get("aspect")) and ship["uid"] == RUN.get("flagUid") and ASPECTS.has(RUN["aspect"]): asp = [ASPECTS[RUN["aspect"]]["fx"]]
	var lst = fleetFxList()
	for m in ship["mods"]:
		if MODULES.has(m): lst.append(MODULES[m]["fx"])
	for p in ship["cap"]["perks"]:
		if PERKS.has(p): lst.append(PERKS[p]["fx"])
	lst += asp
	var fx = sumFx(lst)
	var mk = ship["mk"] if jt(ship.get("mk")) else 1
	var mm = 1.0 + 0.2 * (float(mk) - 1.0)
	var maxHp = JSM.jsround(float(t["hp"]) * mm * (1.0 + float(z0(fx.get("hpPct")))))
	var ws = []
	for e in t["w"]: ws.append(mkWeapon(e[0], e[1], fx))
	return {
		"maxHp": maxHp, "shMax": JSM.jsround(float(t["sh"]) * mm * (1.0 + float(z0(fx.get("shPct"))))), "regen": JSM.jsround(float(t["rg"]) * mm * (1.0 + float(z0(fx.get("regenPct"))))),
		"armor": min(0.6, float(t["ar"]) + float(z0(fx.get("armor")))), "speed": float(t["sp"]) + float(z0(fx.get("speed"))), "turns": float(t["tn"]) + float(z0(fx.get("turns"))), "ev": float(t["ev"]) + float(z0(fx.get("ev"))),
		"aim": z0(fx.get("aim")), "crit": z0(fx.get("crit")), "dmg": 1.0 + 0.15 * (float(mk) - 1.0) + float(z0(fx.get("dmgPct"))), "fx": fx,
		"hangar": (float(t["hangar"]) + float(z0(fx.get("hangar"))) + float(z0(fx.get("hive")))) if jt(t.get("hangar")) else z0(fx.get("hive")),
		"hullRegen": float(z0(fx.get("hullRegen"))) + JSM.jsround(float(z0(fx.get("hullRegenPct"))) * maxHp) + JSM.jsround(float(z0(t.get("regen"))) * mm),
		"weapons": nameWeapons(t.get("fac"), ws),
	}
func heatOn(k) -> bool: return RUN != null and RUN.get("heat") != null and RUN["heat"].has(k)
func sectorCond() -> Variant:
	var k = g(g(RUN, "map"), "cond")
	return SECTOR_CONDS[k] if jt(k) and SECTOR_CONDS.has(k) else null

# ======================= battle.js: board =======================
func blocks(t) -> bool: return t != null and BLOCKING.has(t) and jt(BLOCKING[t])
func hexXZ(h) -> Dictionary: return {"x": HEX_W * (float(h["q"]) + float(h["r"]) / 2.0), "z": -1.5 * HEX_S * float(h["r"])}
func planetEdge(R) -> float: return float(R) * 1.5 * HEX_S + HEX_S * 0.5
func offToAx(c, r) -> Dictionary: return {"q": float(c) - floor(float(r) / 2.0), "r": float(r)}
func onBoard(q, r) -> bool:
	if r < 0 or r >= BH: return false
	var c = float(q) + floor(float(r) / 2.0)
	return c >= 0 and c < BW and not (CUT != null and CUT.has(hkey(q, r)))
func boardHexes() -> Array:
	var o = []
	for r in range(BH):
		for c in range(BW):
			var h = offToAx(c, r)
			if onBoard(h.q, h.r): o.append(h)
	return o
func boardBounds() -> Dictionary:
	var c0 = 99.0; var c1 = -1.0; var r0 = 99.0; var r1 = -1.0
	for h in boardHexes():
		var c: float = h.q + floor(h.r / 2.0)
		c0 = min(c0, c); c1 = max(c1, c); r0 = min(r0, h.r); r1 = max(r1, h.r)
	return {"c0": c0, "c1": c1, "r0": r0, "r1": r1}
func alive(side = null) -> Array:
	var o = []
	for u in B["units"]:
		if not jt(u.get("dead")) and (side == null or u["side"] == side): o.append(u)
	return o
func caps(side) -> Array:
	var o = []
	for u in alive(side):
		if not jt(u.get("isSq")): o.append(u)
	return o
func unitAt(q, r) -> Variant:
	for u in B["units"]:
		if not jt(u.get("dead")) and u["q"] == q and u["r"] == r: return u
	return null
func occMap() -> Dictionary:
	var m = {}
	for u in B["units"]:
		if not jt(u.get("dead")): m[hkey(u["q"], u["r"])] = u
	return m
func terr(q, r): return B["terrain"].get(hkey(q, r))
func _cpOf(id) -> float: return float(HULLS[id]["cp"]) if jt(HULLS[id].get("cp")) else 1.0
func _cmpCheap(a, b) -> float:
	var d = _cpOf(a) - _cpOf(b)
	return d if d != 0.0 else float(HULLS[a]["hp"]) - float(HULLS[b]["hp"])
func cheapHull(fac) -> Variant:
	var F = FACTIONS[fac] if FACTIONS.has(fac) else FACTIONS["voidsworn"]
	var l = []
	for id in F["roster"]:
		if HULLS.has(id) and not jt(HULLS[id].get("boss")) and HULLS[id].get("ab") != "launch": l.append(id)
	JSM.ssort(l, _cmpCheap)
	return l[0] if l.size() > 0 else F["roster"][0]
func edgeHex(side) -> Variant:
	var bb = boardBounds(); var mr = floor((bb.r0 + bb.r1) / 2.0); var occ = occMap(); var c: float = bb.c0 + 1 if side == "player" else bb.c1 - 1
	var best: Variant = null; var bd = 1e9
	for h in boardHexes():
		var hc: float = h.q + floor(h.r / 2.0)
		if absf(hc - c) > 1 or blocks(terr(h.q, h.r)) or occ.has(hkey(h.q, h.r)): continue
		var d: float = absf(h.r - mr) + absf(hc - c) * 0.5
		if d < bd: bd = d; best = h
	return best
func eventTick() -> void:
	var e = B.get("event")
	if not jt(e) or jt(e.get("done")) or jt(B.get("over")): return
	if B["round"] >= e["warnR"] and not jt(e.get("warned")): e["warned"] = true
	if B["round"] < e["r"]: return
	e["done"] = true
	if e["k"] == "reinf_enemy" or e["k"] == "reinf_ally":
		var side = "enemy" if e["k"] == "reinf_enemy" else "player"; var h = edgeHex(side)
		if h == null: return
		var fac = B["cfg"]["fac"] if side == "enemy" else (RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn")
		var s = B["sector"] if jt(B.get("sector")) else 1
		var u = makeUnit(side, cheapHull(fac), {"scale": (1.0 + 0.12 * (s - 1)) if side == "enemy" else 1, "dmg": (1.0 + 0.08 * (s - 1)) if side == "enemy" else 1, "fac": fac})
		u["q"] = h.q; u["r"] = h.r; u["facing"] = 0 if side == "player" else 3; u["reinf"] = true
		if side == "player": u["name"] = "Garrison " + String(u["name"])
		B["units"].append(u)
		if jt(B.get("cp0")): B["cp0"][side] = B["cp0"][side] + (u["t"]["cp"] if jt(u["t"].get("cp")) else 1)
func rollBiome(region) -> Dictionary:
	var R = REGION_BIOME.get(region) if region != null else null
	if R == null: R = {"rock": ROCK_KINDS.keys(), "planet": [0, 1, 2, 3, 4, 5, 6, 7], "station": ["ring", "rig", "spire"]}
	var o = {}
	o["rock"] = pick(R["rock"]); o["planet"] = pick(R["planet"]); o["station"] = pick(R["station"])
	return o
func terrainConnected(T: Dictionary) -> bool:
	var all = boardHexes(); var bb = boardBounds()
	var ok = func(h): return onBoard(h.q, h.r) and not (T.has(hkey(h.q, h.r)) and BLOCKING.has(T[hkey(h.q, h.r)]))
	var col = func(h): return h.q + floor(h.r / 2.0)
	var reach = func(from: Array, goal: Callable) -> bool:
		var seen = {}
		for h in from: seen[hkey(h.q, h.r)] = true
		var q = from.duplicate()
		while q.size() > 0:
			var h = q.pop_back()
			if goal.call(h): return true
			for d in DIRS:
				var n = {"q": h.q + d[0], "r": h.r + d[1]}; var k = hkey(n.q, n.r)
				if not seen.has(k) and ok.call(n):
					seen[k] = true; q.append(n)
		return false
	var f1 = []
	for h in all:
		if col.call(h) == bb.c0 + 2 and ok.call(h): f1.append(h)
	var lr: bool = reach.call(f1, func(h): return col.call(h) == bb.c1 - 2)
	var band = []
	for h in all:
		if col.call(h) >= 10 + CX and col.call(h) <= 16 + CX and ok.call(h): band.append(h)
	var rs = []
	for h in band: rs.append(h.r)
	var r0 = JSM.amin(rs); var r1 = JSM.amax(rs)
	var tb = false
	if band.size() > 0:
		var f2 = []
		for h in band:
			if h.r <= r0 + 1: f2.append(h)
		tb = reach.call(f2, func(h): return h.r >= r1 - 1 and col.call(h) >= 8 + CX and col.call(h) <= 18 + CX)
	return lr and tb

func genTerrain(map, shape, opt) -> Dictionary:
	if opt == null: opt = {}
	CUT = null; var VOID = {}
	var cut = {}; var inner = {}
	var ph = []
	for i in range(6): ph.append(rnd() * 6.28)
	var nz = func(x, i): return 0.5 + 0.5 * (JSM.sin(float(x) * 0.55 + ph[i]) * 0.62 + JSM.sin(float(x) * 1.37 + ph[i + 1]) * 0.38)
	var A = ARENA; var round_ = A.get("kind") == "round"; var amb: bool = opt.get("enc") == "ambush" or opt.get("enc") == "intercept"
	var eT = 0 if round_ else (1 if amb else 2); var eS = 0 if (round_ or opt.get("enc") == "break") else 1; var deep = 1 if (shape == "archipelago" and not round_) else 0
	for r in range(BH):
		for c in range(BW):
			var h = offToAx(c, r); var out: bool = r < A.mT or r >= BH - A.mB or c < A.mL or c >= BW - A.mR
			if round_:
				var p = hexXZ(h); var cc = hexXZ(offToAx((BW - 1) / 2.0, (BH - 1) / 2.0)); var a = JSM.atan2(p.z - cc.z, p.x - cc.x)
				var rad: float = A.R * HEX_W * (1.0 + 0.05 * JSM.sin(a * 3.0 + ph[0]) + 0.04 * JSM.sin(a * 7.0 + ph[1]))
				out = out or JSM.hypot([(p.x - cc.x) * 0.94, p.z - cc.z]) > rad
			if out: cut[hkey(h.q, h.r)] = true
	var mid = floori(BW / 2.0); var midR = floori(BH / 2.0)
	for c in range(BW):
		var top: float = min(eT + deep, JSM.jsround(nz.call(c, 0) * (eT + deep) * 1.25)); var bot: float = min(eT + deep, JSM.jsround(nz.call(c, 2) * (eT + deep) * 1.25))
		if shape == "hourglass":
			var q = (c - mid) / 4.4
			var w = JSM.jsround(4.2 * JSM.exp(-(q * q))); top = max(top, w); bot = max(bot, w)   # Math.pow(x,2) is x*x in fdlibm
		for r in range(BH):
			if r < top + A.mT or r >= BH - bot - A.mB: cut[hkey(offToAx(c, r).q, offToAx(c, r).r)] = true
	for r in range(BH):
		var L: float = min(eS, JSM.jsround(nz.call(r, 1) * eS * 1.3)); var R: float = min(eS, JSM.jsround(nz.call(r, 3) * eS * 1.3))
		for c in range(BW):
			if c < L + A.mL or c >= BW - R - A.mR: cut[hkey(offToAx(c, r).q, offToAx(c, r).r)] = true
	if shape == "corridor" or shape == "compact":
		for r in range(BH):
			for c in range(BW):
				var h = offToAx(c, r)
				if (shape == "corridor" and (r < 3 + A.mT or r > BH - 4 - A.mB)) or (shape == "compact" and (c < 4 + CX or c > BW - 5 - CX or r < 2 + A.mT or r > BH - 3 - A.mB)): cut[hkey(h.q, h.r)] = true
	if shape == "deadstar":
		var a1 = ri(-1, 1); var a2 = ri(-1, 1)
		var c0 = offToAx(mid + a1, midR + a2); VOID["deadstar"] = {"q": c0.q, "r": c0.r}
		for r in range(BH):
			for c in range(BW):
				var h = offToAx(c, r); var d = hdist(h, c0)
				if d <= 2 or (d == 3 and nz.call(c * 3 + r, 4) > 0.62):
					cut[hkey(h.q, h.r)] = true; inner[hkey(h.q, h.r)] = true
	if shape == "rift":
		var n = 2 if rnd() < 0.5 else 3; var rows = []
		var k = 0
		while k < 40 and rows.size() < n:
			var r = ri(2, BH - 3); var okr = true
			for x in rows:
				if absf(x - r) < 4: okr = false
			if okr: rows.append(r)
			k += 1
		var cells = []
		for r in range(BH):
			var skip = false
			for x in rows:
				if absf(x - r) <= 1: skip = true
			if skip: continue
			var cx = mid - 1 + JSM.jsround(JSM.sin(r * 0.62 + ph[5]) * 1.6)
			for c in [cx, cx + 1]:
				var h = offToAx(c, r); cut[hkey(h.q, h.r)] = true; cells.append([h.q, h.r])
		VOID["rift"] = rows; VOID["riftCells"] = cells
	if shape == "shoals":
		var cs = []; var k = 0
		while k < 80 and cs.size() < 3:
			var a1 = ri(9, BW - 10); var a2 = ri(3, BH - 4); var h = offToAx(a1, a2); var okh = true
			for p in cs:
				if hdist(p, h) < 5: okh = false
			if okh: cs.append(h)
			k += 1
		for c0 in cs:
			var R = 1 if rnd() < 0.5 else 2
			for r in range(BH):
				for c in range(BW):
					var h = offToAx(c, r); var d = hdist(h, c0)
					if d <= R or (d == R + 1 and nz.call(c * 5 + r * 3, 4) > 0.7):
						cut[hkey(h.q, h.r)] = true; inner[hkey(h.q, h.r)] = true
	if shape == "colossus":
		var a1 = ri(11, BW - 12); var a2 = ri(5, BH - 6); var c0 = offToAx(a1, a2)
		for r in range(BH):
			for c in range(BW):
				var h = offToAx(c, r); var d = hdist(h, c0)
				if d <= 2 or (d == 3 and nz.call(c * 7 + r * 2, 4) > 0.55):
					cut[hkey(h.q, h.r)] = true; inner[hkey(h.q, h.r)] = true
	if cut.size() > 0: CUT = cut
	SOLID = null
	if cut.size() > 0:
		var seen = {}; var holes = []; var rift = {}
		for x in (VOID.get("riftCells") if VOID.has("riftCells") else []): rift[str(int(x[0])) + "," + str(int(x[1]))] = true
		for k0 in inner.keys():
			if seen.has(k0): continue
			var comp = []; var st = [k0]; seen[k0] = true
			while st.size() > 0:
				var k = st.pop_back(); comp.append(k); var qr = String(k).split(","); var q = float(qr[0]); var r = float(qr[1])
				for d in DIRS:
					var nk = str(int(q + d[0])) + "," + str(int(r + d[1]))
					if inner.has(nk) and not seen.has(nk):
						seen[nk] = true; st.append(nk)
			var allr = true
			for k in comp:
				if not rift.has(k): allr = false
			if allr: continue
			holes.append(comp)
		if holes.size() > 0:
			SOLID = {}
			var hl = []
			for comp in holes:
				for k in comp: SOLID[k] = true
				var ds: bool = VOID.has("deadstar") and comp.has(hkey(VOID.deadstar.q, VOID.deadstar.r))
				var cells = []
				for k in comp:
					var qr = String(k).split(","); cells.append([float(qr[0]), float(qr[1])])
				hl.append({"cells": cells, "kind": "deadstar" if ds else pick(opt["pieces"] if jt(opt.get("pieces")) else ["asteroid", "asteroid", "station", "moon", "hulk", "comet"])})
			VOID["holes"] = hl
	var T = {}; var kinds = ["belt", "station", "planet", "storm", "graveyard"]
	var m = map if kinds.has(map) else pick(kinds)
	TERRAIN_META = {"map": m}
	var put = func(h, t): _put(T, h, t)
	var blob = func(type, n, c0, c1, r0, r1): _blob(T, type, n, c0, c1, r0, r1)
	var all = boardHexes()
	var col = func(h): return h.q + floor(h.r / 2.0)
	var midh = offToAx(floori(BW / 2.0), floori(BH / 2.0))
	var xy = func(h): return {"x": col.call(h) + (0.5 if int(h.r) % 2 != 0 else 0.0), "y": h.r * 0.866}
	if m == "belt":
		var up = rnd() < 0.5; var Ap = {"x": BW * 0.28, "y": (1.0 if up else BH - 2.0) * 0.866}; var Bp = {"x": BW * 0.72, "y": (BH - 2.0 if up else 1.0) * 0.866}
		var dx: float = Bp.x - Ap.x; var dy: float = Bp.y - Ap.y; var L2 = dx * dx + dy * dy; var gaps = []
		for t in [0.22, 0.55, 0.85]: gaps.append({"x": Ap.x + dx * t, "y": Ap.y + dy * t})
		for h in all:
			var p = xy.call(h); var t: float = ((p.x - Ap.x) * dx + (p.y - Ap.y) * dy) / L2
			if t < -0.15 or t > 1.15: continue
			var px: float = Ap.x + dx * t; var py: float = Ap.y + dy * t; var d = JSM.hypot([p.x - px, p.y - py])
			var ingap = false
			for gp in gaps:
				if JSM.hypot([p.x - gp.x, p.y - gp.y]) < 1.6: ingap = true; break
			if ingap: continue
			if d < 1.1 and rnd() < 0.72: put.call(h, "rock")
			elif d < 2.4 and rnd() < 0.16: put.call(h, "rock")
			elif d < 3 and rnd() < 0.12: put.call(h, "debris")
		for i in range(2): blob.call("neb", ri(5, 9), 5, BW - 6, 1, BH - 2)
	if m == "station":
		var want
		if jt(opt.get("stationAt")): want = opt["stationAt"]
		else:
			var a1 = ri(-1, 1); var q1: float = midh.q + a1; var a2 = ri(-1, 1); want = {"q": q1, "r": midh.r + a2}
		var okSite = func(h):
			if not onBoard(h.q, h.r): return false
			for d in DIRS:
				if not onBoard(h.q + d[0], h.r + d[1]): return false
			for o in (VOID.get("holes") if VOID.has("holes") else []):
				for qr in o["cells"]:
					if hdist(h, {"q": qr[0], "r": qr[1]}) <= 3: return false
			return true
		var c
		if okSite.call(want): c = want
		else:
			var l1 = []
			for h in all:
				if okSite.call(h): l1.append(h)
			JSM.ssort(l1, func(a, b): return hdist(a, want) - hdist(b, want))
			if l1.size() > 0: c = l1[0]
			else:
				var l2 = []
				for h in all:
					var okk = onBoard(h.q, h.r)
					for d in DIRS:
						if not onBoard(h.q + d[0], h.r + d[1]): okk = false
					if okk: l2.append(h)
				JSM.ssort(l2, func(a, b): return hdist(a, want) - hdist(b, want))
				c = l2[0] if l2.size() > 0 else want
		TERRAIN_META["station"] = c
		for h in all:
			var d = hdist(h, c)
			if d <= 1: T[hkey(h.q, h.r)] = "station"
			elif d <= 3 and rnd() < 0.42: put.call(h, "debris")
		for i in range(3): blob.call("rock", ri(2, 4), 5, BW - 6, 1, BH - 2)
		blob.call("neb", ri(5, 8), 5, BW - 6, 1, BH - 2)
	if m == "planet":
		var top = rnd() < 0.5; var a1 = ri(-3, 3); var c = offToAx(floori(BW / 2.0) + a1, -5 if top else BH + 4); var R = 8; var edge = planetEdge(R); var cw = hexXZ(c)
		TERRAIN_META["planet"] = {"q": c.q, "r": c.r, "R": R, "top": top}
		for h in all:
			var p = hexXZ(h); var d = JSM.hypot([p.x - cw.x, p.z - cw.z])
			if d <= edge + HEX_S * 0.45: T[hkey(h.q, h.r)] = "planet"
			elif d <= edge + HEX_S * 3 and rnd() < 0.22: put.call(h, "debris")
		for i in range(3): blob.call("rock", ri(2, 4), 5, BW - 6, 6 if top else 1, BH - 2 if top else BH - 7)
		blob.call("neb", ri(4, 7), 5, BW - 6, 1, BH - 2); TERRAIN_META["planetKeep"] = {"cw": cw, "edge": edge}
	if m == "storm":
		for i in range(4): blob.call("storm", ri(8, 14), 5, BW - 6, 1, BH - 2)
		for i in range(2): blob.call("neb", ri(5, 8), 5, BW - 6, 1, BH - 2)
		for i in range(2): blob.call("rock", ri(2, 4), 6, BW - 7, 1, BH - 2)
	if m == "graveyard":
		var spots = []; var k = 0
		while k < 60 and spots.size() < 7:
			var a1 = ri(6, BW - 7); var a2 = ri(1, BH - 2); var h = offToAx(a1, a2); var okh = true
			for p in spots:
				if hdist(p, h) < 3: okh = false
			if okh: spots.append(h)
			k += 1
		for h in spots:
			T[hkey(h.q, h.r)] = "hulk"
			for d in DIRS:
				if rnd() < 0.55: put.call({"q": h.q + d[0], "r": h.r + d[1]}, "debris")
		TERRAIN_META["wrecks"] = spots
		for i in range(2): blob.call("rock", ri(2, 4), 6, BW - 7, 1, BH - 2)
		blob.call("neb", ri(4, 7), 5, BW - 6, 1, BH - 2)
	var sc = opt.get("cond")
	if jt(sc) and jt(sc.get("terr")):
		var tt = sc["terr"]; var n = 3 if tt == "storm" else (3 if tt == "neb" else 4)
		for i in range(n): blob.call(tt, ri(4 if tt == "debris" else 6, 7 if tt == "debris" else 11), 8, BW - 9, 1, BH - 2)
	var force = func(h, t):
		var k = hkey(h.q, h.r)
		if onBoard(h.q, h.r) and not (T.has(k) and BLOCKING.has(T[k])): T[k] = t
	if shape == "lanes":
		var g1 = ri(8, 10) + CX; var g2 = ri(14, 16) + CX
		for c in range(7, BW - 7):
			if (c >= g1 and c <= g1 + 1) or (c >= g2 and c <= g2 + 1): continue
			force.call(offToAx(c, midR), "rock")
			if rnd() < 0.45 and c != g1 - 1 and c != g2 - 1 and c != g1 + 2 and c != g2 + 2: force.call(offToAx(c, midR - 1), "rock")
	if shape == "ring":
		for h in all:
			if not onBoard(h.q, h.r): continue
			var d = hdist(h, midh)
			if d <= 1 or (d == 2 and rnd() < 0.55): force.call(h, "rock")
			elif d >= 3 and d <= 4 and rnd() < 0.16: put.call(h, "debris")
	if shape == "dense":
		for i in range(4): blob.call("rock", ri(3, 5), 6, BW - 7, 1, BH - 2)
		for i in range(3): blob.call("debris", ri(4, 7), 5, BW - 6, 1, BH - 2)
		blob.call("neb", ri(4, 7), 5, BW - 6, 1, BH - 2)
	if shape == "archipelago":
		var cs = []; var k = 0
		while k < 120 and cs.size() < 6:
			var a1 = ri(8, BW - 9); var a2 = ri(2, BH - 3); var h = offToAx(a1, a2); var okh = true
			for p in cs:
				if hdist(p, h) < 4: okh = false
			if okh: cs.append(h)
			k += 1
		for c0 in cs:
			force.call(c0, "rock")
			for d in DIRS:
				if rnd() < 0.55: force.call({"q": c0.q + d[0], "r": c0.r + d[1]}, "rock")
			for d in DIRS:
				if rnd() < 0.3: put.call({"q": c0.q + 2 * d[0], "r": c0.r + 2 * d[1]}, "debris")
	if shape == "deadstar" and VOID.has("deadstar"):
		for h in all:
			var d = hdist(h, VOID.deadstar)
			if d >= 3 and d <= 4 and rnd() < 0.22: put.call(h, "debris")
	if shape == "rift":
		for h in all:
			if not onBoard(h.q, h.r): continue
			var edge = false
			for d in DIRS:
				if not onBoard(h.q + d[0], h.r + d[1]) and absf(col.call(h) - floori(BW / 2.0)) <= 4: edge = true; break
			if edge and rnd() < 0.2: put.call(h, "debris")
	if TERRAIN_META.has("planetKeep"):
		var cw = TERRAIN_META.planetKeep.cw; var edge = TERRAIN_META.planetKeep.edge
		for k in T.keys():
			if T[k] != "rock": continue
			var qr = String(k).split(","); var p = hexXZ({"q": float(qr[0]), "r": float(qr[1])})
			if JSM.hypot([p.x - cw.x, p.z - cw.z]) < edge + HEX_S * 1.8: T.erase(k)
		TERRAIN_META.erase("planetKeep")
	for k in VOID.keys(): TERRAIN_META[k] = VOID[k]
	TERRAIN_META["shape"] = shape if jt(shape) else "open"
	return T

func _put(T: Dictionary, h, t) -> void:
	if onBoard(h.q, h.r) and not T.has(hkey(h.q, h.r)): T[hkey(h.q, h.r)] = t
func _blob(T: Dictionary, type, n, c0, c1, r0, r1) -> void:
	var a1 = ri(c0, c1); var a2 = ri(r0, r1); var cur = offToAx(a1, a2)
	for k in range(int(n)):
		_put(T, cur, type); var d = pick(DIRS); cur = {"q": cur.q + d[0], "r": cur.r + d[1]}
func deploy(units: Array, side, zoneFn = null) -> void:
	var mode = B["deployMode"] if jt(B.get("deployMode")) else "line"; var midR = floori(BH / 2.0)
	var capsl = []
	for u in units:
		if not jt(u.get("isSq")): capsl.append(u)
	JSM.ssort(capsl, func(a, b): return b["size"] - a["size"])
	var zone: Callable; var facing: Variant = null
	var A = ARENA; var L0 = A.mL; var R0 = BW - A.mR; var T0 = A.mT; var T1 = BH - A.mB
	if mode == "flank":
		if side == "player":
			zone = func(h): return h.c >= L0 + 3 and h.c <= L0 + 9 and h.r >= T1 - 7
			facing = 5
		else:
			zone = func(h): return h.c >= R0 - 10 and h.c <= R0 - 4 and h.r <= T0 + 6
			facing = 2
	elif mode == "ambush":
		if side == "player":
			zone = func(h): return h.c >= L0 + 5 + CX and h.c <= L0 + 9 + CX and absf(h.r - midR) <= 3
			facing = 0
		else:
			zone = func(h): return h.c >= R0 - 14 - CX and h.c <= R0 - 6 and (h.r <= T0 + 2 or h.r >= T1 - 3)
	else:
		if side == "player":
			zone = func(h): return h.c >= L0 + 4 and h.c <= L0 + 6 and absf(h.r - midR) <= 5
			facing = 0
		else:
			zone = func(h): return h.c >= R0 - 7 and h.c <= R0 - 5 and absf(h.r - midR) <= 5
			facing = 3
	if zoneFn != null: zone = zoneFn
	var occ = occMap()
	var free = func(h): return not blocks(terr(h.q, h.r)) and not occ.has(hkey(h.q, h.r))
	var cand = []
	for h in boardHexes():
		h["c"] = h.q + floor(h.r / 2.0)
		if zone.call(h) and free.call(h): cand.append(h)
	if cand.size() < capsl.size() + 1:
		cand = []
		for h in boardHexes():
			h["c"] = h.q + floor(h.r / 2.0)
			var half: bool = h.c < BW / 2.0 - 1 if side == "player" else h.c >= BW / 2.0 + 1
			if half and free.call(h): cand.append(h)
	var sq = 0.0; var sr = 0.0
	for h in cand: sq += h.q
	for h in cand: sr += h.r
	var cq = sq / cand.size(); var cr = sr / cand.size(); var centre = {"q": JSM.jsround(cq), "r": JSM.jsround(cr)}
	var target = offToAx(floori(BW / 2.0), midR); var placed = []
	for u in capsl:
		var best: Variant = null; var bs = -1e9
		for h in cand:
			var taken = false
			for p in placed:
				if p.q == h.q and p.r == h.r: taken = true; break
			if taken: continue
			var dmin = 3.0
			if placed.size() > 0:
				var ds = []
				for p in placed: ds.append(hdist(p, h))
				dmin = JSM.amin(ds)
			var sc: float = min(dmin, 2.0) * 100.0 - hdist(h, centre) * 4.0 + rnd()
			if sc > bs: bs = sc; best = h
		if best == null: best = cand[0]
		placed.append(best); u["q"] = best.q; u["r"] = best.r
		if facing != null: u["facing"] = facing
		else:
			var x = SQRT3 * ((target.q - u.q) + (target.r - u.r) / 2.0); var y = 1.5 * (target.r - u.r)
			u["facing"] = fmod(fmod(JSM.jsround(JSM.atan2(y, x) * 180.0 / PI / 60.0), 6.0) + 6.0, 6.0)

func approachDeploy() -> void:
	var ap = B["approach"]; var hs = boardHexes()
	if hs.size() == 0: return
	var cx = 0.0; var cz = 0.0
	for h in hs:
		var p = hexXZ(h); cx += p.x; cz += p.z
	cx /= hs.size(); cz /= hs.size()
	var ext = 0.0
	for h in hs:
		var p = hexXZ(h); ext = max(ext, JSM.hypot([p.x - cx, p.z - cz]))
	var th = ap["th"] if jt(ap.get("th")) else 0.0; var R = ext * (0.74 if ap["k"] == "diagonal" else 0.68)
	var pt = func(a, k = null):
		var kk = k if jt(k) else 1.0
		return {"x": cx + JSM.cos(a) * R * kk, "z": cz + JSM.sin(a) * R * kk}
	var zoneAt = func(P, n):
		var rad = 2.4
		while rad < 9:
			var o = occMap(); var lim = rad * HEX_W
			var z = func(h):
				var p = hexXZ(h); return JSM.hypot([p.x - P.x, p.z - P.z]) <= lim
			var cnt = 0
			for h in hs:
				if z.call(h) and not blocks(terr(h.q, h.r)) and not o.has(hkey(h.q, h.r)): cnt += 1
			if cnt >= n + 2: return z
			rad += 0.6
		return null
	var P = []; var E = []
	for u in B["units"]:
		if u["side"] == "player": P.append(u)
		if u["side"] == "enemy" and not jt(u.get("transport")): E.append(u)
	var nP = 0
	for u in P:
		if not jt(u.get("isSq")): nP += 1
	var Ec = []
	for u in E:
		if not jt(u.get("isSq")): Ec.append(u)
	JSM.ssort(Ec, func(a, b): return b["size"] - a["size"])
	var pP = pt.call(th + PI)
	deploy(P, "player", zoneAt.call(pP, nP))
	if ap["k"] == "pincer" and Ec.size() >= 3:
		var g1 = []; var g2 = []
		for i in range(Ec.size()):
			if i % 2 == 0: g1.append(Ec[i])
			else: g2.append(Ec[i])
		deploy(g1, "enemy", zoneAt.call(pt.call(th + 0.95, 0.95), g1.size())); deploy(g2, "enemy", zoneAt.call(pt.call(th - 0.95, 0.95), g2.size()))
	elif ap["k"] == "cross":
		var a: float = th + PI / 2.0 * (1.0 if rnd() < 0.5 else -1.0); deploy(E, "enemy", zoneAt.call(pt.call(a, 0.95), Ec.size()))
	else: deploy(E, "enemy", zoneAt.call(pt.call(th), Ec.size()))
	for side in ["player", "enemy"]:
		var other = "enemy" if side == "player" else "player"; var l = []
		for u in B["units"]:
			if u["side"] == other and not jt(u.get("isSq")): l.append(u)
		var tq = 0.0; var trr = 0.0
		for u in l: tq += u.q
		for u in l: trr += u.r
		var t = {"q": tq / max(1, l.size()), "r": trr / max(1, l.size())}
		for u in B["units"]:
			if u["side"] != side or jt(u.get("isSq")): continue
			var x = SQRT3 * ((t.q - u.q) + (t.r - u.r) / 2.0); var y = 1.5 * (t.r - u.r)
			u["facing"] = fmod(fmod(JSM.jsround(JSM.atan2(y, x) * 180.0 / PI / 60.0), 6.0) + 6.0, 6.0)

func wellTick(u, dq) -> Variant:
	var W = B.get("well") if B != null else null
	if not jt(W) or jt(u.get("isSq")) or jt(u.get("dead")): return null
	var d = hdist(u, W); u["gravAssist"] = false
	if d <= WELL_ASSIST:
		u["mp"] = u["mp"] + 1; u["gravAssist"] = true
	if d <= WELL_RIM:
		u["hp"] = u["hp"] - WELL_DMG
		if u["hp"] <= 0:
			u["hp"] = 0; u["killCause"] = "tidal"; queueDeath(u, dq); return "dead"
	elif d <= WELL_PULL:
		var occ = occMap(); var best: Variant = null
		for dd in DIRS:
			var n = {"q": u.q + dd[0], "r": u.r + dd[1]}
			if hdist(n, W) != d - 1 or not onBoard(n.q, n.r) or blocks(terr(n.q, n.r)) or occ.has(hkey(n.q, n.r)): continue
			best = n; break
		if best != null:
			u["q"] = best.q; u["r"] = best.r
	return null
func aiWellScore(u, v) -> float:
	var W = B.get("well") if B != null else null
	if not jt(W) or jt(u.get("isSq")): return 0.0
	var d = hdist(v, W)
	return -45.0 if d <= WELL_RIM else (-6.0 if d <= WELL_PULL else 0.0)
func B0small(cfg) -> bool:
	if cfg.get("kind") == "boss" or RUN == null or RUN.get("fleet") == null: return false
	var n = 0
	for x in RUN["fleet"]:
		if x["hp"] > 0: n += 1
	return n <= 2
func clearSpawns() -> void:
	var T = B["terrain"]; var cnt = [0]
	var clr = func(q, r):
		var k = hkey(q, r); var t = T.get(k)
		if t == "rock" or t == "hulk":
			T.erase(k); cnt[0] += 1
	var near = func(h, R):
		for dq in range(-R, R + 1):
			var dr: int = max(-R, -dq - R)
			while dr <= min(R, -dq + R):
				clr.call(h.q + dq, h.r + dr); dr += 1
	for side in ["player", "enemy"]:
		var mine = []; var foes = []
		for u in B["units"]:
			if u["side"] == side and not jt(u.get("isSq")) and not jt(u.get("transport")): mine.append(u)
			if u["side"] != side and not jt(u.get("isSq")): foes.append(u)
		if mine.size() == 0 or foes.size() == 0: continue
		var sq = 0.0; var sr = 0.0
		for u in foes: sq += u.q
		for u in foes: sr += u.r
		var tgt = {"q": JSM.jsround(sq / foes.size()), "r": JSM.jsround(sr / foes.size())}
		for u in mine:
			near.call(u, 2 if side == "player" else 1)
			var line = hexLine(u, tgt); var L: int = min(line.size() - 1, 6 if side == "player" else 4)
			for i in range(1, L + 1): near.call(line[i], 1 if (i <= 3 and side == "player") else 0)
	if jt(B.get("map")) and jt(B["map"].get("wrecks")):
		var w = []
		for h in B["map"]["wrecks"]:
			if T.get(hkey(h.q, h.r)) == "hulk": w.append(h)
		B["map"]["wrecks"] = w
	B["spawnCleared"] = cnt[0]

# ======================= battle.js: units and setup =======================
func makeUnit(side, tpl, opts: Dictionary = {}) -> Dictionary:
	var t: Dictionary = HULLS[tpl]; var s: Dictionary
	if jt(opts.get("ship")): s = derive(opts["ship"])
	else:
		var sc = opts["scale"] if jt(opts.get("scale")) else 1
		var fx = opts["fx"] if jt(opts.get("fx")) else {}
		var ws = []
		for e in t["w"]: ws.append(mkWeapon(e[0], e[1], fx))
		s = {"maxHp": JSM.jsround(float(t["hp"]) * sc * (1.1 if jt(opts.get("elite")) else 1.0)), "shMax": JSM.jsround(float(t["sh"]) * sc), "regen": JSM.jsround(float(t["rg"]) * sc), "armor": t["ar"], "speed": t["sp"], "turns": t["tn"], "ev": t["ev"],
			"aim": 6 if jt(opts.get("elite")) else 0, "crit": 5 if jt(opts.get("elite")) else 0, "dmg": opts["dmg"] if jt(opts.get("dmg")) else 1, "fx": fx, "hangar": z0(t.get("hangar")),
			"hullRegen": JSM.jsround(float(z0(t.get("regen"))) * sc), "weapons": nameWeapons(t.get("fac"), ws)}
	var ship = opts.get("ship")
	var u = {"id": new_id(), "side": side, "tpl": tpl, "t": t, "name": ship["name"] if jt(ship) else (opts["name"] if jt(opts.get("name")) else t["n"]), "cls": t.get("cls"),
		"fac": t["fac"] if jt(t.get("fac")) else (opts["fac"] if jt(opts.get("fac")) else "voidsworn"), "size": t["size"], "q": 0, "r": 0, "facing": 0 if side == "player" else 3,
		"hp": min(ship["hp"], s["maxHp"]) if jt(ship) else s["maxHp"], "maxHp": s["maxHp"], "sh": [s["shMax"], s["shMax"], s["shMax"], s["shMax"]], "shMax": s["shMax"], "regen": s["regen"],
		"armor": s["armor"], "speed": s["speed"], "turns": s["turns"], "ev": s["ev"], "aim": s["aim"], "crit": s["crit"], "dmg": s["dmg"], "fx": s["fx"], "hangar": s["hangar"], "hullRegen": s["hullRegen"]}
	var wl = []
	for w in s["weapons"]:
		w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0; wl.append(w)
	u["weapons"] = wl
	u["ab"] = t["ab"] if jt(t.get("ab")) else null; u["abCd"] = 0; u["isSq"] = jt(t.get("sq")); u["sqKind"] = t["sq"] if jt(t.get("sq")) else null; u["boss"] = jt(t.get("boss")); u["reanimate"] = jt(t.get("reanimate")); u["reanimated"] = false
	u["ship"] = ship if jt(ship) else null; u["parent"] = opts["parent"] if jt(opts.get("parent")) else null; u["sqPct"] = z0(opts.get("sqPct"))
	u["mp"] = 0; u["turnsLeft"] = 0; u["order"] = null; u["braced"] = false; u["lockOn"] = false; u["focus"] = false; u["fullAhead"] = false; u["noTurn"] = false; u["evBuff"] = 0
	u["pflag"] = jt(ship) and RUN != null and jt(RUN.get("flagUid")) and ship["uid"] == RUN["flagUid"]
	u["intercepts"] = 0; u["dealt"] = 0; u["kills"] = 0; u["dead"] = false; u["st"] = {"fire": 0, "shieldOff": 0, "engine": 0}; u["usedLastStand"] = false; u["elite"] = jt(opts.get("elite"))
	if u["isSq"] and jt(opts.get("sqHp")):
		u["maxHp"] = JSM.jsround(u["maxHp"] * (1.0 + opts["sqHp"])); u["hp"] = u["maxHp"]
	if jt(ship) and u["hp"] <= 0: u["hp"] = 1
	if not u["isSq"]:
		var f: float = clamp_(float(u["hp"]) / u["maxHp"], 0.0, 1.0)
		u["sec"] = {"prow": {"max": JSM.jsround(u["maxHp"] * 0.3)}, "mid": {"max": JSM.jsround(u["maxHp"] * 0.45)}, "eng": {"max": JSM.jsround(u["maxHp"] * 0.25)}}
		for k in u["sec"].keys(): u["sec"][k]["hp"] = JSM.jsround(u["sec"][k]["max"] * f)
		u["crewMax"] = JSM.jsround((12.0 + u["size"] * 40.0) * (CREW_MULT[u["fac"]] if jt(CREW_MULT.get(u["fac"])) else 1.0) * (1.8 if u["boss"] else 1.0)); u["crew"] = u["crewMax"]; u["speed"] = u["speed"] + 1
	return u
func fleetPower() -> float:
	if RUN == null or RUN.get("fleet") == null: return 99.0
	var p = 0.0
	for sh in RUN["fleet"]:
		if sh["hp"] <= 0: continue
		var d = derive(sh); var hp: float = min(1.0, float(sh["hp"]) / (d["maxHp"] if jt(d["maxHp"]) else 1.0)); var cp = HULLS[sh["tpl"]]["cp"] if jt(HULLS[sh["tpl"]].get("cp")) else 1
		p += cp * (0.4 + 0.6 * hp) * (1.0 + 0.12 * ((sh["mk"] if jt(sh.get("mk")) else 1) - 1) + 0.03 * (sh["mods"] if sh.get("mods") != null else []).size() + 0.04 * (z0(g(sh.get("cap"), "rank")))) + z0(d.get("hangar")) * 0.45 * (0.5 + 0.5 * hp)
	var boons = 0.0
	for b in (RUN["boons"] if RUN.get("boons") != null else []):
		var rr = at(RARITY, z0(b.get("r"))); boons += (rr if rr != null else RARITY[0])["m"]
	return p * (1.0 + 0.035 * boons + 0.025 * (RUN["relics"] if RUN.get("relics") != null else []).size())
func playerStrength() -> float: return fleetPower()

func startBattle(cfg: Dictionary) -> void:
	var seed = (int(cfg["seed"]) & 0xFFFFFFFF) if cfg.get("seed") != null else int(floor(rnd() * 4294967296.0))
	JSM.rnd_seed(seed)
	var enc = cfg["obj"] if ENCOUNTERS.has(cfg.get("obj")) else "rout"; var midR = floori(BH / 2.0)
	var shape = cfg["shape"] if SHAPES.has(cfg.get("shape")) else "open"; var map = "station" if enc == "defend" else cfg.get("map")
	if shape == "open" and B0small(cfg) and ["rout", "hunt", "ambush"].has(enc): shape = "compact"
	if not ["belt", "station", "planet", "storm", "graveyard"].has(map) and FAC_MAP.has(cfg.get("fac")) and rnd() < 0.55: map = pick(FAC_MAP[cfg["fac"]])
	if (shape == "lanes" or shape == "ring") and map == "belt": map = pick(["station", "planet", "storm", "graveyard"])
	var axisFree: bool = ["rout", "hold", "flagship"].has(enc) and cfg.get("kind") != "boss" and shape != "compact" and not (cfg.get("dep") == "ambush")
	var wpick = func(l: Array):
		var tot = 0.0
		for e in l: tot += e[1]
		var x = rnd() * tot
		for e in l:
			x -= e[1]
			if x <= 0: return e[0]
		return l[0][0]
	var ak = cfg["arena"] if ARENAS.has(cfg.get("arena")) else (wpick.call(ENC_ARENA[enc]) if axisFree and ENC_ARENA.has(enc) else "strip")
	ARENA = {"kind": ak}
	for k in ARENAS[ak].keys(): ARENA[k] = ARENAS[ak][k]
	if shape == "deadstar" and ["belt", "station", "planet"].has(map) and not jt(cfg.get("keepShape")):
		var sh = []
		for x in (ENCOUNTERS[enc] if ENCOUNTERS.has(enc) else ENCOUNTERS["rout"])["shapes"]:
			if x != "deadstar": sh.append(x)
		shape = pick(sh if sh.size() > 0 else ["open"])
	if ak != "strip" and AXIS_SHAPES.has(shape): shape = pick(["open", "dense", "deadstar", "shoals", "archipelago", "colossus", "ring"])
	var approach: Variant = null
	if ak == "square": approach = {"k": "diagonal" if rnd() < 0.6 else "cross"}
	elif ak == "round":
		if rnd() < 0.4: approach = {"k": "headon"}
		else: approach = {"k": "cross" if rnd() < 0.5 else "pincer"}
	if approach != null:
		if ak == "square":
			if approach["k"] == "diagonal":
				var sgn = 1.0 if rnd() < 0.5 else -1.0; approach["th"] = sgn * (PI / 4.0 + (rnd() - 0.5) * 0.35)
			else:
				var a = 0.0 if rnd() < 0.5 else PI / 2.0; approach["th"] = a * (1.0 if rnd() < 0.5 else -1.0)
		else: approach["th"] = rnd() * PI * 2.0
		if jt(cfg.get("approach")): approach["k"] = cfg["approach"]
	var pieces_by = {"belt": ["asteroid", "asteroid", "comet", "station"], "graveyard": ["hulk", "hulk", "station", "asteroid"], "planet": ["moon", "moon", "asteroid", "station"], "station": ["station", "station", "hulk", "asteroid"], "storm": ["comet", "asteroid", "asteroid", "moon"]}
	var topt = {"cond": null if cfg.get("kind") == "boss" else sectorCond(), "stationAt": offToAx(9 + CX, midR) if enc == "defend" else null, "enc": enc, "pieces": pieces_by.get(map) if pieces_by.has(map) else null}
	var T: Variant = null
	for k in range(6):
		T = genTerrain(map, shape, topt)
		if terrainConnected(T): break
		T = null
	if T == null:
		shape = "open"; T = genTerrain(map, "open", topt)
	if cfg.get("kind") == "boss":
		for k in T.keys():
			if T[k] == "rock" and rnd() < 0.45: T.erase(k)
	var biome = cfg["biome"] if jt(cfg.get("biome")) else (RUN["map"]["biome"] if RUN != null and jt(RUN.get("map")) and jt(RUN["map"].get("biome")) else rollBiome(null))
	var well = {"q": TERRAIN_META.deadstar.q, "r": TERRAIN_META.deadstar.r} if shape == "deadstar" and TERRAIN_META.has("deadstar") else null
	var depm = "ambush" if enc == "ambush" else ("line" if ["defend", "hunt", "intercept", "break"].has(enc) else (cfg["dep"] if jt(cfg.get("dep")) else "line"))
	B = {"seed": seed, "units": [], "terrain": T, "map": TERRAIN_META, "shape": shape, "enc": enc, "arena": ARENA["kind"], "biome": biome, "approach": approach, "well": well, "deployMode": depm,
		"resolve": {"player": 1, "enemy": 1}, "round": 1, "side": "player", "sel": null, "armed": null, "mode": null, "hover": null, "reach": null,
		"busy": false, "log": [], "fx": [], "cfg": cfg, "over": false, "reviveUsed": false, "inspect": null, "showArcs": true, "showThreat": false, "called": null, "wingSel": null, "activeUnit": null, "sector": RUN["sector"]}
	var scd = sectorCond(); B["cond"] = RUN["map"]["cond"] if jt(scd) and RUN != null and jt(RUN.get("map")) else null; B["condRegen"] = scd["regen"] if jt(scd) and jt(scd.get("regen")) else 1
	var s = RUN["sector"]
	for ship in RUN["fleet"]:
		if ship["hp"] <= 0: continue
		B["units"].append(makeUnit("player", ship["tpl"], {"ship": ship}))
	var eList = cfg["enemies"] if jt(cfg.get("enemies")) else genEnemyFleet(cfg["fac"], s, cfg["col"], cfg.get("kind"), cfg.get("arch"), cfg.get("mod"))
	var sc = 1.0 + 0.12 * (s - 1); var dm = 1.0 + 0.08 * (s - 1)
	var bf = at([0, 6, 9, 12], s); var bossFit: float = max(0.55, min(1.0, playerStrength() / (bf if jt(bf) else 12)))
	var eliteIdx: Variant = null
	if cfg.get("kind") == "elite":
		var pairs = []
		for i in range(eList.size()): pairs.append([i, HULLS[eList[i]["tpl"]]["cp"] if jt(HULLS[eList[i]["tpl"]].get("cp")) else 1])
		JSM.ssort(pairs, func(x, y): return y[1] - x[1])
		eliteIdx = {}
		for i in range(int(ceil(eList.size() / 2.0))): eliteIdx[pairs[i][0]] = true
	var thin = 1.0 if jt(cfg.get("enemies")) else (float(at(RAMP.thin, s)) if jt(at(RAMP.thin, s)) else 1.0) * (RAMP.escort if cfg.get("kind") == "boss" else 1.0)
	for ei in range(eList.size()):
		var e = eList[ei]; var isb: bool = jt(HULLS[e["tpl"]].get("boss"))
		var scale = sc * (float(at(BOSS_SCALE, s)) * bossFit * (BOSS_FAC[cfg["fac"]] if jt(BOSS_FAC.get(cfg["fac"])) else 1.0) * (1.2 if heatOn("h_flag") else 1.0) if isb else thin)
		var dmg = dm * (float(at(BOSS_DMG, s)) if isb else thin)
		var elite: bool = (eliteIdx != null and eliteIdx.has(ei))
		if not elite: elite = cfg.get("kind") == "boss" and not isb and rnd() < 0.3
		if not elite and heatOn("h_elite"): np("heat h_elite")
		if not elite and cfg.get("mod") == "veteran": np("node mod veteran")
		B["units"].append(makeUnit("enemy", e["tpl"], {"scale": scale, "dmg": dmg, "elite": elite, "fac": cfg["fac"]}))
	if heatOn("h_undying"): np("heat h_undying")
	var nCar0 = 0
	for sh in RUN["fleet"]:
		if sh["hp"] > 0 and HULLS.has(sh["tpl"]) and jt(HULLS[sh["tpl"]].get("hangar")): nCar0 += 1
	var adm = ADMIRALS.get(RUN["admiral"])
	var carDoc: bool = (adm != null and jt(adm.get("cmd")) and adm["cmd"]["id"] == "scramble") or RUN.get("aspect") == "hive"
	var nCar = nCar0 + (1 if carDoc and nCar0 >= 1 else 0)
	if nCar >= 2 and not jt(cfg.get("enemies")): np("carrier adaptation")
	if enc == "intercept": np("intercept transports")
	if enc == "break": np("breakthrough deploy")
	elif enc == "hunt": np("hunt deploy")
	elif B.get("approach") != null: approachDeploy()
	else:
		var pl = []
		for u in B["units"]:
			if u["side"] == "player": pl.append(u)
		deploy(pl, "player")
		if cfg.get("kind") == "boss" and B["deployMode"] == "line":
			var bl = []; var esc = []
			for u in B["units"]:
				if u["side"] == "enemy" and jt(u["t"].get("boss")): bl.append(u)
				if u["side"] == "enemy" and not jt(u.get("transport")) and not jt(u["t"].get("boss")): esc.append(u)
			deploy(bl, "enemy", func(h): return h.c >= BW - ARENA.mR - 10 and h.c <= BW - ARENA.mR - 8 and absf(h.r - midR) <= 5)
			deploy(esc, "enemy")
		else:
			var el = []
			for u in B["units"]:
				if u["side"] == "enemy" and not jt(u.get("transport")): el.append(u)
			deploy(el, "enemy")
	clearSpawns()
	deployWings()
	B["cp0"] = {"player": sideCP("player"), "enemy": sideCP("enemy")}
	B["usage"] = {"fire": {}, "aim": 0, "ab": {}, "ord": {}, "cmd": 0, "moves": 0, "cant": {}}
	setupObjective(cfg.get("obj"))
	startSideTurn("player")
	for u in alive("enemy"): u["intercepts"] = 2 if _has_flak(u) else 0
func _has_flak(u) -> bool:
	for w in u["weapons"]:
		if w["k"] == "flak": return true
	return false
func genEnemyFleet(_fac, _s, _col, _kind, _arch, _mod) -> Array:
	np("genEnemyFleet (scenarios pass their enemy list)"); return []

func gainResolve(side, n) -> void:
	if not jt(B.get("resolve")): B["resolve"] = {"player": 0, "enemy": 0}
	B["resolve"][side] = min(5, z0(B["resolve"].get(side)) + n)
func escortsBreak() -> void:
	if not jt(B.get("cfg")) or B["cfg"].get("kind") != "boss" or jt(B.get("escortsFled")): return
	var boss: Variant = null
	for u in B["units"]:
		if jt(u.get("boss")) and u["side"] == "enemy" and not jt(u.get("dead")): boss = u; break
	if boss == null or boss["hp"] > boss["maxHp"] * 0.5: return
	var esc = []
	for u in alive("enemy"):
		if not is_same(u, boss) and not jt(u.get("isSq")): esc.append(u)
	B["escortsFled"] = true
	for e in esc:
		e["dead"] = true; e["fled"] = true
	boss["regen"] = 0; boss["hullRegen"] = 0; boss["reanimate"] = false
	var nsh = []
	for v in boss["sh"]: nsh.append(JSM.jsround(v * 0.5))
	boss["sh"] = nsh; boss["burning"] = true
func startSideTurn(side) -> int:
	var deaths = []
	if side == "player" and B["round"] > 1:
		eventTick(); objectiveTick(deaths)
	if side == "enemy":
		aiRefreshFocus(); bossCmdTick()
	escortsBreak()
	gainResolve(side, 1); var burned = false
	for u in B["units"]:
		if jt(u.get("dead")) or u["side"] != side: continue
		u["braced"] = false; u["pivotUsed"] = false; u["lockOn"] = false; u["focus"] = false; u["fullAhead"] = false; u["noTurn"] = false; u["evBuff"] = 0; u["order"] = null; u["ramBoost"] = 0
		u["mp"] = max(1, u["speed"] - u["st"]["engine"]); u["turnsLeft"] = u["turns"]
		for w in u["weapons"]:
			w["fired"] = false
			if w["cdLeft"] > 0: w["cdLeft"] = w["cdLeft"] - 1
			if w["off"] > 0: w["off"] = w["off"] - 1
		if u["abCd"] > 0: u["abCd"] = u["abCd"] - 1
		if u["st"]["shieldOff"] > 0: u["st"]["shieldOff"] = u["st"]["shieldOff"] - 1
		elif u["shMax"] > 0:
			var rg = u["regen"] * (B["condRegen"] if B != null and jt(B.get("condRegen")) else 1)
			for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + rg)
		if jt(u.get("hullRegen")) and u["hp"] < u["maxHp"] and not jt(u.get("pyre")): u["hp"] = min(u["maxHp"], u["hp"] + u["hullRegen"])
		if z0(u["st"].get("acid")) > 0 and not jt(u.get("isSq")):
			u["st"]["acid"] = u["st"]["acid"] - 1; u["hp"] = u["hp"] - 4
			if u["hp"] <= 0:
				u["hp"] = 0; burned = true; u["killCause"] = "melt"; queueDeath(u, deaths)
		if u["st"]["fire"] > 0 and not jt(u.get("dead")):
			var fd = u["st"]["fireDmg"] if jt(u["st"].get("fireDmg")) else 6
			u["st"]["fire"] = u["st"]["fire"] - 1; u["hp"] = u["hp"] - fd
			if u["hp"] <= 0:
				u["hp"] = 0; burned = true; u["killCause"] = "dark"; queueDeath(u, deaths)
			if not jt(u["st"]["fire"]): u["st"]["fireDmg"] = 0
		u["hexMoved"] = 0
		if jt(u.get("fx")) and jt(u["fx"].get("stormRegen")) and u["shMax"] > 0 and not (z0(u["st"].get("shieldOff")) > 0):
			for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + JSM.jsround(u["shMax"] * u["fx"]["stormRegen"]))
		u["intercepts"] = 2 if _has_flak(u) else 0
		u["boarded"] = false; u["rammed"] = false; u["emerg"] = false; u["repel"] = false
		if terr(u["q"], u["r"]) == "storm" and not jt(u.get("isSq")) and u["shMax"] > 0:
			for i in range(4): u["sh"][i] = max(0, u["sh"][i] - 10)
		if jt(u.get("crewMax")) and u["crew"] <= 0:
			u["mp"] = 0; u["turnsLeft"] = 0
			for w in u["weapons"]: w["fired"] = true
		if jt(B.get("well")) and wellTick(u, deaths) == "dead": burned = true
	var ev = B.get("event")
	if jt(ev) and ev["k"] == "flare" and B["round"] == ev["r"] and jt(ev.get("done")):
		for u in B["units"]:
			if not jt(u.get("dead")) and u["side"] == side and u["shMax"] > 0: u["sh"] = [0, 0, 0, 0]
	if burned: checkEnd()
	return deaths.size()
func queueDeath(u, dq) -> void:
	killUnit(u, null, true)
	if dq != null: dq.append(true)
func flush_deferred() -> void:
	while deferred.size() > 0:
		var c: Callable = deferred.pop_front(); c.call()

# ======================= movement =======================
func passable(u, q, r, occ) -> bool:
	if not onBoard(q, r): return false
	if blocks(terr(q, r)): return false
	var o = occ.get(hkey(q, r))
	if o != null and o["side"] != u["side"] and not jt(u.get("isSq")): return false
	return true
func moveRules(u) -> Dictionary:
	var o = MOVE_BASE.duplicate()
	if u != null and not jt(u.get("isSq")) and jt(MOVE_RULES.get(u["fac"])):
		for k in MOVE_RULES[u["fac"]].keys(): o[k] = MOVE_RULES[u["fac"]][k]
	return o
func canEnd(u, q, r, occ) -> bool:
	if not onBoard(q, r) or blocks(terr(q, r)): return false
	var o = occ.get(hkey(q, r))
	return o == null or is_same(o, u)
func _sk(s) -> String: return hkey(s.q, s.r) + "," + str(int(s.f)) + "," + str(int(s.t))
func computeReach(u) -> Dictionary:
	var map = {}; var states = []
	var occ = occMap(); var R = moveRules(u)
	var start = {"q": u["q"], "r": u["r"], "f": u["facing"], "t": 0, "cost": 0, "path": []}
	var seen = {_sk(start): 0}; var queue = [start]; var qi = 0
	var pivotFree: bool = jt(R.get("pivot")) and not jt(u.get("pivotUsed"))
	while qi < queue.size():
		var s = queue[qi]; qi += 1
		if seen[_sk(s)] < s.cost: continue
		states.append(s)
		if s.cost >= u["mp"]: continue
		var nexts = []
		if jt(u.get("isSq")):
			for f in range(6):
				var d = DIRS[f]; var nq = s.q + d[0]; var nr = s.r + d[1]
				if passable(u, nq, nr, occ):
					var pth: Array = s.path.duplicate(); pth.append({"q": nq, "r": nr, "f": f})
					nexts.append({"q": nq, "r": nr, "f": f, "t": s.t, "cost": s.cost + 1, "path": pth})
		else:
			var sf = int(s.f)
			var opts = [[sf, 1, null], [(sf + 1) % 6, R["slip"], "slip"], [(sf + 5) % 6, R["slip"], "slip"], [(sf + 3) % 6, R["rev"], "rev"]]
			for o3 in opts:
				var df: int = o3[0]; var c0 = o3[1]; var kind = o3[2]
				var d = DIRS[df]; var nq = s.q + d[0]; var nr = s.r + d[1]
				if not onBoard(nq, nr): continue
				var c = min(c0, u["mp"]) if (kind != null and s.cost == 0) else c0
				var over = 0; var tt = terr(nq, nr)
				if blocks(tt):
					if tt != "rock" and tt != "hulk": continue
					over = 1
				var o = occ.get(hkey(nq, nr))
				if o != null and o["side"] != u["side"]: over = over if over != 0 else -1
				if over != 0: c += R["over"]
				if s.cost + c > u["mp"]: continue
				var st = {"q": nq, "r": nr, "f": s.f}
				if kind != null: st[kind] = 1
				if kind == "slip": st["side"] = 1 if df == (sf + 1) % 6 else -1
				if over != 0: st["over"] = over
				var pth: Array = s.path.duplicate(); pth.append(st)
				nexts.append({"q": nq, "r": nr, "f": s.f, "t": s.t, "cost": s.cost + c, "path": pth, "slips": z0(s.get("slips")) + (1 if kind == "slip" else 0), "revs": z0(s.get("revs")) + (1 if kind == "rev" else 0), "overs": z0(s.get("overs")) + (1 if over != 0 else 0)})
		if not jt(u.get("isSq")) and not jt(u.get("noTurn")) and s.t < u["turnsLeft"]:
			var tc = 0 if (pivotFree and s.t == 0) else 1
			if s.cost + tc <= u["mp"] or tc == 0:
				for dd in [1, -1]:
					var f = (int(s.f) + dd + 6) % 6
					var pth: Array = s.path.duplicate(); pth.append({"q": s.q, "r": s.r, "f": f, "rot": true})
					nexts.append({"q": s.q, "r": s.r, "f": f, "t": s.t + 1, "cost": s.cost + tc, "path": pth, "slips": s.get("slips"), "revs": s.get("revs"), "overs": s.get("overs")})
		for n in nexts:
			var k = _sk(n)
			if seen.has(k) and seen[k] <= n.cost: continue
			seen[k] = n.cost; queue.append(n)
	var ok = []
	for s in states:
		if seen[_sk(s)] == s.cost and canEnd(u, s.q, s.r, occ): ok.append(s)
	for s in ok:
		if s.q == u["q"] and s.r == u["r"]: continue
		var k = hkey(s.q, s.r); var c = map.get(k)
		if c == null or s.cost < c.cost or (s.cost == c.cost and s.t < c.t): map[k] = s
	return {"map": map, "states": ok}
func _commit(u, state, ctx: Dictionary) -> void:
	if ctx.committed: return
	ctx.committed = true
	var path: Array = state.path
	for st in path:
		if not jt(st.get("rot")):
			u["q"] = st.q; u["r"] = st.r
	u["facing"] = path[path.size() - 1].f
	u["mp"] = max(0, u["mp"] - state.cost); u["turnsLeft"] = u["turnsLeft"] - state.t
	if state.t > 0 and jt(moveRules(u).get("pivot")): u["pivotUsed"] = true
	u["moved"] = true
	var n = 0
	for p in path:
		if not jt(p.get("rot")): n += 1
	u["hexMoved"] = z0(u.get("hexMoved")) + n
	if jt(B.get("usage")) and u["side"] == "player" and not jt(u.get("isSq")): B["usage"]["moves"] = B["usage"]["moves"] + 1
# opts.onLate (fire on the move) runs inside the burn, after the ship is committed to its hex, exactly as the headless game does
func moveUnit(u, state, opts = null) -> void:
	if not inThisBattle(u): return
	var live = liveFrom(null); var ctx = {"committed": false}
	if opts != null and opts.get("onLate") != null:
		if live.call():
			_commit(u, state, ctx); opts["onLate"].call()
	if B != null: B["prog"] = z0(B.get("prog")) + 1
	if not live.call(): return
	if ctx.committed:
		objAfterMove(u); return
	_commit(u, state, ctx)
	objAfterMove(u)

# ======================= combat math =======================
func sightBlocked(q, r) -> bool: return blocks(terr(q, r)) or (SOLID != null and SOLID.has(hkey(q, r)))
func los(a, b) -> bool:
	var line = hexLine(a, b)
	for i in range(1, line.size() - 1):
		if sightBlocked(line[i].q, line[i].r): return false
	return true
func weaponReady(w) -> bool: return not jt(w.get("fired")) and w["cdLeft"] == 0 and w["off"] == 0
func readyList(u) -> Array:
	var o = []
	for w in u["weapons"]:
		if weaponReady(w): o.append(w)
	return o
func inReach(u, w, t) -> bool:
	var d = hdist(u, t)
	if d < 1 or d > w["r"]: return false
	if not inArc(u, t, w["arc"]): return false
	return los(u, t)
func canFire(u, w, t) -> bool:
	if jt(u.get("dead")) or jt(t.get("dead")) or u["side"] == t["side"] or jt(u.get("braced")) or w["k"] == "flak": return false
	if not weaponReady(w): return false
	return inReach(u, w, t)
func motionHit(t) -> float:
	if t == null or jt(t.get("isSq")) or t.get("hexMoved") == null or jt(t.get("braced")): return 0.0
	var R = moveRules(t)
	if t["hexMoved"] == 0: return R["still"]
	if t["hexMoved"] >= R["evadeAt"]: return -R["evade"]
	return 0.0
func rakeBonus(u, w) -> float:
	if u == null or jt(u.get("isSq")) or not (w["arc"] == "P" or w["arc"] == "S") or z0(u.get("hexMoved")) < 2: return 0.0
	return moveRules(u)["rake"]
func hitChance(u, w, t) -> float:
	var d = hdist(u, t); var over: float = max(0, d - w["opt"] - z0(u["fx"].get("longAim")))
	var c: float = w["acc"] + u["aim"] + (15 if jt(u.get("lockOn")) else 0) - (15 if jt(u.get("fullAhead")) else 0) - over * w["fall"] - min(45, t["ev"] + z0(t.get("evBuff"))) * (w["evMult"] if jt(w.get("evMult")) else 1)
	if jt(t.get("isSq")) and w["k"] != "flak" and w["k"] != "sq": c -= 15
	if terr(t["q"], t["r"]) == "neb": c -= 15
	if terr(t["q"], t["r"]) == "debris": c -= 10
	if terr(u["q"], u["r"]) == "storm": c -= 10
	if jt(u.get("crewMax")):
		if u["crew"] < u["crewMax"] * 0.5: c -= 10
		if u["crew"] < u["crewMax"] * 0.25: c -= 10
	if jt(t.get("fx")) and jt(t["fx"].get("burnEv")) and z0(t.get("hexMoved")) >= 3: c -= t["fx"]["burnEv"]
	c += motionHit(t)
	var surge = cmdActive(t["side"], "surge")
	if u["side"] == "player" and not jt(u.get("isSq")) and not (z0(u.get("sureUsed")) > 0) and jt(runFx().get("firstSure")): return 75.0 if surge else 95.0
	var h: float = clamp_(JSM.jsround(c), 5, 95)
	return max(5, h - 20) if surge else h
func boonFx(_u, id, _txt = null, _dy = null) -> void:
	if B != null:
		if B.get("boonStats") == null: B["boonStats"] = {}
		B["boonStats"][id] = z0(B["boonStats"].get(id)) + 1
func ownerFx(u) -> Dictionary:
	if u == null: return {}
	if jt(u.get("isSq")):
		var p: Variant = null
		if B != null:
			for x in B["units"]:
				if x["id"] == u.get("parent"): p = x; break
		return p["fx"] if p != null and jt(p.get("fx")) else {}
	return u["fx"] if jt(u.get("fx")) else {}
func guardMul(t) -> float:
	if B == null or jt(t.get("isSq")): return 1.0
	var m = 1.0; var near = []
	for x in B["units"]:
		if not jt(x.get("dead")) and not is_same(x, t) and x["side"] == t["side"] and not jt(x.get("isSq")) and hdist(x, t) == 1: near.append(x)
	if near.size() == 0: return 1.0
	if jt(t.get("fx")) and jt(t["fx"].get("lineGuard")): m *= 1.0 - min(0.5, t["fx"]["lineGuard"])
	var aura = 0.0
	for x in near: aura = max(aura, float(z0(g(x.get("fx"), "guardAura"))))
	if aura != 0.0: m *= 1.0 - aura
	return m
func ionOf(att, w) -> float:
	var f = ownerFx(att)
	return float(w["ion"] if jt(w.get("ion")) else 1) + z0(f.get("ionPlus")) + (z0(f.get("ionLance")) if w.get("k") == "lance" else 0)
func dmgMult(u, w, t, rear) -> float:
	var m: float = u["dmg"]
	var fx = u["fx"]
	if w["arc"] == "P" or w["arc"] == "S": m += z0(fx.get("broadPct"))
	if w["k"] == "lance": m += z0(fx.get("lancePct"))
	if w["k"] == "torp": m += z0(fx.get("torpPct"))
	if jt(u.get("isSq")): m += z0(u.get("sqPct"))
	if rear: m += z0(fx.get("rearPct"))
	if t["hp"] < t["maxHp"] / 2.0: m += z0(fx.get("huntPct"))
	if jt(u.get("focus")): m += 0.3
	if jt(fx.get("stillPct")) and not jt(u.get("hexMoved")) and (w["arc"] == "P" or w["arc"] == "S" or w["k"] == "battery"): m += fx["stillPct"]
	if jt(fx.get("momPct")): m += min(4, z0(u.get("hexMoved"))) * fx["momPct"]
	if jt(fx.get("prowPct")) and w["arc"] == "F": m += fx["prowPct"]
	m += rakeBonus(u, w)
	var base: float = w["dmg"] * m
	base *= (w["vsSq"] if jt(w.get("vsSq")) else 1.0) if jt(t.get("isSq")) else (w["vsCap"] if jt(w.get("vsCap")) else 1.0)
	if jt(u.get("bloodied")) and not jt(u.get("isSq")): base *= 1.0 + 0.15 * u["bloodied"]
	if cmdActive(u["side"], "hunt"): base *= 1.0 + cmdPow("hunt", null, u["side"])
	if jt(u.get("isSq")) and cmdActive(u["side"], "scramble"): base *= 1.0 + cmdPow("scramble", null, u["side"])
	if B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: base *= B["volleyMul"]["m"]
	return base
func expectedVs(u, w, t) -> Dictionary:
	var quad = shieldQuad(t, u); var rear = quad == 2
	var hit = hitChance(u, w, t) / 100.0; var per = dmgMult(u, w, t, rear)
	var raw: float = per * w["shots"] * hit
	var pierce = z0(w.get("pierce")); var ion = ionOf(u, w)
	var shieldable: float = raw * (1.0 - pierce)
	var absorbed: float = min(shieldable, float(z0(t["sh"][quad])) / ion)
	var hull: float = (raw - absorbed) * (1.0 - (t["armor"] * 0.5 if rear else t["armor"]))
	if jt(t.get("braced")): hull *= max(0.15, 1.0 - 0.4 - z0(t["fx"].get("bracePlus")))
	hull *= cmdTaken(t) * guardMul(t)
	return {"hit": hit, "raw": raw, "hull": hull, "shield": absorbed * ion, "quad": quad, "rear": rear}
func applyHit(att, w, t, dmg: float, quad: int) -> Dictionary:
	var rear = quad == 2; var pierce = z0(w.get("pierce")); var ion = ionOf(att, w); var of = ownerFx(att)
	var shieldable: float = dmg * (1.0 - pierce); var through: float = dmg - shieldable
	var s = z0(t["sh"][quad]); var absorbed: float = min(shieldable, float(s) / ion)
	t["sh"][quad] = max(0, s - absorbed * ion); shieldable -= absorbed
	var arm: float = max(0, t["armor"] - z0(t.get("shredded"))) * (1.0 - z0(w.get("armorPierce"))); var hull: float = (through + shieldable) * (1.0 - (arm * 0.5 if rear else arm))
	if jt(t.get("braced")): hull *= max(0.15, 1.0 - 0.4 - z0(t["fx"].get("bracePlus")))
	hull *= cmdTaken(t) * guardMul(t)
	var crit = false
	if hull > 0.5 and rnd() * 100.0 < z0(w.get("crit")) + att["crit"] + (10 if jt(att.get("lockOn")) else 0) + (15 if rear else 0) + (z0(of.get("momCrit")) if z0(att.get("hexMoved")) >= 3 else 0):
		hull *= 1.5 + z0(of.get("critMul")); crit = true
	hull = JSM.jsround(hull)
	if hull > 0 and not jt(t.get("isSq")) and not jt(t.get("dead")):
		var ch = z0(of.get("igniteCh")) + (z0(of.get("broadIgnite")) if (w.get("arc") == "P" or w.get("arc") == "S") else 0) + (z0(of.get("sqIgnite")) if jt(att.get("isSq")) else 0)
		if ch > 0 and rnd() < ch: np("ignite boons")
	if hull > 0 and not jt(t.get("isSq")) and not jt(t.get("dead")):
		if jt(w.get("ignite")):
			t["st"]["fire"] = max(z0(t["st"].get("fire")), 2); t["st"]["fireDmg"] = max(t["st"]["fireDmg"] if jt(t["st"].get("fireDmg")) else 6, 6)
		if jt(w.get("shred")): t["shredded"] = min(0.15, z0(t.get("shredded")) + w["shred"])
		if jt(w.get("acid")): t["st"]["acid"] = 2
	if jt(of.get("pyre")) and not jt(t.get("isSq")) and t["hp"] < t["maxHp"] / 2.0: t["pyre"] = true
	t["hp"] = t["hp"] - hull; att["dealt"] = att["dealt"] + hull
	damageSection(t, t["_calledSec"] if jt(t.get("_calledSec")) else SEC_OF_QUAD[quad], hull, att)
	return {"shield": JSM.jsround(absorbed * ion), "hull": hull, "crit": crit}
func repairSection(t, sec, frac) -> bool:
	var s = g(t.get("sec"), sec)
	if s == null: return false
	if not jt(s.get("broken")):
		if s["hp"] > 0: s["hp"] = min(s["max"], s["hp"] + JSM.jsround(s["max"] * frac))
		return false
	s["broken"] = false; s["hp"] = max(1, JSM.jsround(s["max"] * frac))
	if sec == "prow":
		for w in t["weapons"]:
			if w["arc"] == "F" and w["off"] >= 99: w["off"] = 0
	if sec == "mid":
		for w in t["weapons"]:
			if (w["arc"] == "P" or w["arc"] == "S") and w["off"] >= 99: w["off"] = 0
		if t["shMax"] > 0 and t["st"]["shieldOff"] >= 99: t["st"]["shieldOff"] = 0
	if sec == "eng":
		t["st"]["engine"] = 0
		if jt(t.get("secSave")):
			t["turns"] = t["secSave"]["turns"]; t["ev"] = t["secSave"]["ev"]; t["secSave"] = null
	return true
func damageSection(t, sec, dmg, by) -> void:
	if not jt(t.get("sec")) or not jt(t["sec"].get(sec)) or dmg <= 0: return
	var s = t["sec"][sec]
	if jt(t.get("crewMax")): t["crew"] = max(0, t["crew"] - JSM.jsround(float(dmg) / t["maxHp"] * t["crewMax"] * 0.35))
	if s["hp"] <= 0: return
	s["hp"] = max(0, s["hp"] - dmg)
	if s["hp"] > 0 or jt(s.get("broken")): return
	s["broken"] = true
	if sec == "prow":
		for w in t["weapons"]:
			if w["arc"] == "F": w["off"] = 999
	if sec == "mid":
		for w in t["weapons"]:
			if w["arc"] == "P" or w["arc"] == "S": w["off"] = 999
		if t["shMax"] > 0:
			t["st"]["shieldOff"] = 999; t["sh"] = [0, 0, 0, 0]
	if sec == "eng":
		t["secSave"] = {"turns": t["turns"], "ev": t["ev"]}; t["st"]["engine"] = max(0, t["speed"] - 1); t["turns"] = min(t["turns"], 1); t["ev"] = 0
	if by != null and not jt(by.get("dead")): gainResolve(by["side"], 1)
func systemDamage(t, forced = null) -> Variant:
	if jt(t.get("isSq")) or jt(t.get("dead")): return null
	var mp = {"engines": "engine", "shields": "shields", "weapons": "weapon", "eng": "engine", "mid": "shields", "prow": "weapon"}
	var r = mp[forced] if jt(forced) and mp.has(forced) else pick(["engine", "shields", "weapon", "fire"])
	if r == "shields" and not (t["shMax"] > 0): r = "fire"
	if r == "weapon" and t["weapons"].size() == 0: r = "fire"
	if r == "weapon" and jt(forced):
		var live = []
		for w in t["weapons"]:
			if w["off"] == 0: live.append(w)
		JSM.ssort(live, func(a, b): return b["dmg"] * b["shots"] - a["dmg"] * a["shots"])
		if live.size() > 0:
			live[0]["off"] = 2; return String(live[0]["n"]) + " knocked out"
	if r == "engine":
		t["st"]["engine"] = min(t["speed"] - 1, t["st"]["engine"] + 1); return "Engines hit"
	if r == "shields" and t["shMax"] > 0 and z0(t["st"].get("shieldOff")) < 99:
		t["st"]["shieldOff"] = max(z0(t["st"].get("shieldOff")), 2); return "Shield generator down"
	if r == "weapon":
		var ws = []
		for w in t["weapons"]:
			if z0(w.get("off")) < 99: ws.append(w)
		if ws.size() > 0:
			var w = pick(ws); w["off"] = max(z0(w.get("off")), 2); return String(w["n"]) + " knocked out"
	if r == "shields" and z0(t["st"].get("shieldOff")) >= 99:
		t["st"]["fire"] = 2; return "Fire on deck"
	t["st"]["fire"] = 2; return "Fire on deck"

func fireWeapon(u, wi: int, t, opts: Dictionary = {}) -> bool:
	if not inThisBattle(u): return false
	var live = liveFrom(null)
	var w = u["weapons"][wi]
	if not jt(opts.get("intercept")) and not canFire(u, w, t): return false
	var keep = [w["fired"], w["cdLeft"], u.get("sureUsed")]; var b0 = B
	if not jt(opts.get("intercept")):
		w["fired"] = true
		if jt(w.get("cd")): w["cdLeft"] = w["cd"]
		if u["side"] == "player" and not jt(u.get("isSq")): u["sureUsed"] = z0(u.get("sureUsed")) + 1
	if jt(B.get("usage")) and u["side"] == "player" and not jt(opts.get("intercept")) and not jt(u.get("isSq")):
		var k = ARC_NAME[w["arc"]] if jt(ARC_NAME.get(w["arc"])) else str(w["arc"])
		B["usage"]["fire"][k] = z0(B["usage"]["fire"].get(k)) + 1
		if jt(opts.get("called")): B["usage"]["aim"] = B["usage"]["aim"] + 1
	if jt(u.get("isSq")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")): np("squadron flak gauntlet")
	var quad = shieldQuad(t, u); var shBefore = z0(t["sh"][quad]) if t.get("sh") != null else 0
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	var called = opts["called"] if jt(opts.get("called")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")) else null
	var hc = hitChance(u, w, t)
	var shots = []
	for i in range(int(w["shots"])): shots.append(rnd() * 100.0 < hc)
	if jt(w.get("rockets")) and not jt(t.get("isSq")):
		var shot = 0
		for d in alive(t["side"]):
			if jt(d.get("isSq")) or d["intercepts"] <= 0 or jt(d.get("braced")): continue
			var fw: Variant = null
			for x in d["weapons"]:
				if x["k"] == "flak" and not (z0(x.get("off")) > 0): fw = x; break
			if fw == null or hdist(d, t) > fw["r"]: continue
			var i = 0
			while i < shots.size() and d["intercepts"] > 0:
				if shots[i] and rnd() < 0.55:
					shots[i] = false; d["intercepts"] = d["intercepts"] - 1; shot += 1
				i += 1
		if shot != 0: res["pd"] = shot
	if B != null: B["prog"] = z0(B.get("prog")) + 1
	if not live.call():
		if not jt(opts.get("intercept")) and is_same(B, b0):
			w["fired"] = keep[0]; w["cdLeft"] = keep[1]; u["sureUsed"] = keep[2]
		return false
	if called != null:
		u["crit"] = u["crit"] + 15; t["_calledSec"] = called
	for h in shots:
		if jt(t.get("dead")): break
		if not h:
			res.misses += 1; continue
		res.hits += 1
		var d = dmgMult(u, w, t, quad == 2) * (0.85 + rnd() * 0.3)
		var r = applyHit(u, w, t, d, quad)
		res.shield += r.shield; res.hull += r.hull
		if r.crit:
			res.crits += 1; var cs = ownerFx(u).get("critSys")
			if not jt(res.sys) and (jt(called) or jt(cs) or rnd() < 0.4):
				res.sys = systemDamage(t, called)
				if jt(cs) and jt(res.sys): boonFx(t, "a_crit")
	if called != null:
		u["crit"] = u["crit"] - 15; t["_calledSec"] = null
	if res.shield > 0:
		if t["shMax"] > 0 and t["sh"][quad] <= 0.5:
			var ar = ownerFx(u).get("arcShort")
			if jt(ar) and shBefore > 0.5 and not jt(t.get("dead")): np("arcShort boon")
	if res.hits > 0 and jt(t.get("braced")) and not jt(t.get("dead")) and not jt(u.get("dead")) and not jt(opts.get("intercept")) and t["side"] != u["side"]:
		var rp = ownerFx(t).get("riposte")
		if jt(rp): np("riposte boon")
	if t["hp"] <= 0:
		t["killCause"] = killCauseOf(w, t); killUnit(t, u)
	return true
func ramInfo(u) -> Variant:
	if u == null or jt(u.get("isSq")) or jt(u.get("braced")) or jt(u.get("dead")) or jt(u.get("rammed")) or (jt(u.get("crewMax")) and u["crew"] <= 0): return null
	var left = min(u["mp"], max(1, u["speed"] - u["st"]["engine"]))
	if left < 1: return null
	var d = DIRS[int(u["facing"])]; var q = u["q"]; var r = u["r"]; var path = []
	var i = 0
	while i <= left:
		var nq = q + d[0]; var nr = r + d[1]
		if not onBoard(nq, nr) or blocks(terr(nq, nr)): return null
		var o = unitAt(nq, nr)
		if o != null and o["id"] != u["id"]:
			return {"t": o, "path": path} if (o["side"] != u["side"] and not jt(o.get("isSq")) and path.size() >= 1) else null
		path.append({"q": nq, "r": nr, "f": u["facing"]}); q = nq; r = nr
		i += 1
	return null
func ramEstimate(u, t, run = null) -> Dictionary:
	var f = u["fx"] if jt(u.get("fx")) else {}
	var runk = 1.0 if run == null else (0.75 if run <= 1 else (1.0 if run == 2 else 1.15))
	var base = (14.0 + 46.0 * u["size"]) * (1.2 if jt(RAM_FAC.get(u["fac"])) else 1.0) * runk; var quad = shieldQuad(t, u)
	var raw = base * (1.0 + z0(f.get("ramPct"))) * (u["ramBoost"] if jt(u.get("ramBoost")) else 1.0) * (1.0 if quad == 0 else 1.2) * (1.0 - t["armor"] * 0.5)
	var soak: float = min(raw * 0.5, float(z0(t["sh"][quad])) if t.get("sh") != null else 0.0)
	return {"dmg": JSM.jsround(min(raw - soak, t["maxHp"] * (0.4 + min(0.3, z0(f.get("ramCap")))))), "soak": JSM.jsround(soak),
		"recoil": JSM.jsround(base * (0.35 if jt(RAM_FAC.get(u["fac"])) else 0.5) * clamp_(float(t["size"]) / u["size"], 0.5, 1.6) * (1.0 - u["armor"] * 0.5) * (1.0 - min(1, z0(f.get("ramGuard"))))), "sec": SEC_OF_QUAD[quad]}
func ramUnit(u) -> bool:
	var info = ramInfo(u)
	if info == null: return false
	var t = info.t; var live = liveFrom(u)
	if not live.call(): return false
	for p in info.path:
		u["q"] = p.q; u["r"] = p.r
	u["facing"] = info.path[info.path.size() - 1].f
	u["mp"] = 0; u["turnsLeft"] = 0; u["rammed"] = true
	if jt(B.get("usage")) and u["side"] == "player": np("player ram usage")
	var e = ramEstimate(u, t, info.path.size())
	if not live.call() or jt(t.get("dead")): return false
	var qd = shieldQuad(t, u)
	if jt(e.soak) and t.get("sh") != null: t["sh"][qd] = max(0, t["sh"][qd] - e.soak * 1.5)
	t["hp"] = t["hp"] - e.dmg; u["dealt"] = u["dealt"] + e.dmg; damageSection(t, e.sec, e.dmg, u); u["hp"] = u["hp"] - e.recoil; damageSection(u, "prow", e.recoil, t)
	if rnd() < 0.35: systemDamage(t, e.sec)
	if jt(u.get("fx")) and jt(u["fx"].get("ramSplash")): np("ramSplash boon")
	if t["hp"] <= 0:
		t["killCause"] = "big"; killUnit(t, u)
	if u["hp"] <= 0:
		u["killCause"] = "big"; killUnit(u, t)
	checkEnd(); return true
func boardTargets(u) -> Array:
	if u == null or jt(u.get("isSq")) or jt(u.get("braced")) or jt(u.get("boarded")) or jt(u.get("dead")) or not jt(u.get("crewMax")) or u["crew"] < max(4, u["crewMax"] * 0.4): return []
	for w in u["weapons"]:
		if jt(w.get("fired")): return []
	var o = []
	for t in alive("enemy" if u["side"] == "player" else "player"):
		if not jt(t.get("isSq")) and hdist(u, t) == 1: o.append(t)
	return o
func captureChance(u, t) -> float:
	if t != null and jt(t.get("boss")): return 0.0
	var s: float = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct"))) * 0.38
	if s <= 0: return 0.0
	var x: float = (t["crew"] - 0.5) / s
	return JSM.jsround(100.0 * max(0.0, min(1.0, (1.25 - x) / 0.5)))
func boardOdds(u, t) -> Dictionary:
	var a: float = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct")))
	var d: float = t["crew"] * (BOARD_MULT[t["fac"]] if jt(BOARD_MULT.get(t["fac"])) else 1.0) * (2.25 if jt(t.get("repel")) else 1.5)
	var p = captureChance(u, t)
	return {"kill": JSM.jsround(a * 0.38), "loss": JSM.jsround(d * 0.3), "chance": p, "capture": p >= 50}
func boardUnit(_u, _t) -> bool:
	np("boarding action"); return false
func tacticRam(u) -> bool:
	var info = ramInfo(u)
	if info == null or info.path.size() < 2: return false
	var e = ramEstimate(u, info.t, info.path.size()); var bold: bool = jt(RAM_FAC.get(u["fac"]))
	if e.dmg >= info.t["hp"] or e.dmg >= info.t["hp"] * (0.3 if bold else 0.45):
		ramUnit(u); return true
	return false
func tacticBoard(u) -> bool:
	var best: Variant = null; var bv = 0.0
	for t in boardTargets(u):
		var o = boardOdds(u, t); var v: float = 100.0 + t["maxHp"] / 10.0 if o.chance >= 70 else 0.0
		if v > bv: bv = v; best = t
	if best != null:
		boardUnit(u, best); return true
	return false
func killCauseOf(w, t) -> String:
	if w == null: return "blast"
	var k = w.get("k"); var trt = w.get("trait")
	if trt == "gauss" or k == "gauss" or k == "doom": return "flay"
	if trt == "acid" or trt == "spines" or k == "bioplasma" or k == "tendril" or k == "sporeb": return "melt"
	if k == "lance" or k == "beam" or (trt == "plasma" and String(w.get("n") if w.get("n") != null else "").to_lower().contains("lance")): return "cut"
	if k == "torp" or k == "htorp" or k == "startorp" or k == "bombs": return "big"
	if k == "battery" or k == "hbattery" or k == "turret" or k == "autocannon" or k == "scatter":
		var h: int = int(B["round"]) if B != null and jt(B.get("round")) else 0
		var s = String(t["id"]) if t != null else "undefined"
		for i in range(s.length()): h = JSM.to_i32(h * 31 + s.unicode_at(i))
		if JSM.to_u32(h) % 10 < 3: return "dark"
	return "blast"
func killUnit(t, by, defer_tail: bool = false) -> void:
	if t != null and by != null and not jt(t.get("killedBy")):
		if jt(by.get("isSq")): np("squadron kill credit")
		t["killedBy"] = by["name"]
	if jt(t.get("dead")): return
	if jt(t["fx"].get("lastStand")) and not jt(t.get("usedLastStand")):
		t["usedLastStand"] = true; t["hp"] = 1; return
	if t["side"] == "player" and not jt(t.get("isSq")) and jt(runFx().get("revive")) and not jt(B.get("reviveUsed")):
		B["reviveUsed"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.25); return
	if jt(t.get("reanimate")) and not jt(t.get("reanimated")) and not jt(t.get("pyre")) and rnd() < (0.2 if t["side"] == "enemy" else 0.35):
		t["reanimated"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.3); return
	t["dead"] = true; t["hp"] = 0
	if t["side"] == "player" and not jt(t.get("isSq")) and not jt(t.get("transport")):
		if jt(runFx().get("avenge")): np("avenge relic")
	if by != null and by["side"] == "player" and not jt(t.get("isSq")) and jt(runFx().get("bloodied")): np("bloodied relic")
	if not jt(t.get("isSq")) and t["size"] >= 0.7 and not blocks(B["terrain"].get(hkey(t["q"], t["r"]))):
		B["terrain"][hkey(t["q"], t["r"])] = "hulk"; t["hulk"] = true
	if by != null and not jt(t.get("isSq")): gainResolve(by["side"], 1)
	if by != null:
		by["kills"] = by["kills"] + 1
		if jt(by.get("parent")): pass   # p.kills += 0
	if by != null and jt(by.get("isSq")): np("feast boon")
	var tail = func():
		var cb = ownerFx(by).get("chainBoom") if (by != null and not jt(t.get("isSq")) and by["side"] != t["side"]) else 0
		if jt(cb): np("chainBoom boon")
		checkEnd()
	if defer_tail: deferred.append(tail)
	else: tail.call()
func sideCP(side) -> float:
	var s = 0.0
	for u in B["units"]:
		if u["side"] == side and not jt(u.get("isSq")) and not jt(u.get("dead")): s += float(u["t"]["cp"]) if jt(u["t"].get("cp")) else 1.0
	return s
func _byCpHp(a, c) -> float:
	var d = (float(c["t"]["cp"]) if jt(c["t"].get("cp")) else 1.0) - (float(a["t"]["cp"]) if jt(a["t"].get("cp")) else 1.0)
	return d if d != 0.0 else float(c["maxHp"] - a["maxHp"])
func setupObjective(type) -> void:
	var o = {"type": type if jt(type) else "rout", "score": 0, "escore": 0}
	if o.type == "flagship" and caps("enemy").size() < 3:
		var hasb = false
		for u in caps("enemy"):
			if jt(g(u.get("t"), "boss")): hasb = true
		o.type = "rout" if hasb else "hunt"
	if o.type == "defend" and not jt(B["map"].get("station")): o.type = "hold"
	if o.type == "hunt": np("hunt objective")
	if o.type == "defend": np("defend objective")
	if o.type == "intercept": np("intercept objective")
	if o.type == "break": np("breakthrough objective")
	if o.type == "flagship":
		var l = []
		for u in alive("enemy"):
			if not jt(u.get("isSq")): l.append(u)
		JSM.ssort(l, func(a, c): return _byCpHp(a, c))
		if l.size() > 0: l[0]["flagship"] = true
		else: o.type = "rout"
	if o.type == "hold": np("relay objective")
	B["obj"] = o
func objAfterMove(u) -> void:
	var o = B.get("obj") if B != null else null
	if o == null or u == null or jt(u.get("dead")) or jt(u.get("isSq")): return
	if o.type == "break" or o.type == "intercept": np("objective exits")
func aiObjScore(u, v) -> float:
	var o = B.get("obj")
	if o == null or jt(u.get("isSq")): return 0.0
	if jt(u.get("transport")): np("transport scoring")
	if o.type == "hunt" and jt(u.get("flagship")): np("hunt scoring")
	var vet = aiVet(); var _urg = aiObjUrgency(o) if vet else 1
	if o.type == "defend" or o.type == "break" or o.type == "hold": np("objective scoring " + String(o.type))
	if vet and o.type == "intercept": np("intercept scoring")
	return 0.0
func aiObjUrgency(o) -> float:
	var done: float = clamp_((float(B["round"] if jt(B.get("round")) else 1) - 1.0) / float(o["rounds"] if jt(o.get("rounds")) else ENC_ROUNDS), 0.0, 1.0)
	if o.type == "defend": return 1.0 + done * 1.2 + (0.6 if o["hp"] <= 2 else 0.0)
	if o.type == "hold": return 1.0 + done * 0.8 + (0.8 if o["score"] >= 2 else 0.0) + (0.4 if o["escore"] >= 2 else 0.0)
	return 1.0
func objectiveTick(_dq) -> void:
	var o = B.get("obj")
	if o == null or jt(B.get("over")): return
	if o.type == "defend" or o.type == "hunt": np("objective tick " + String(o.type))
	if o.type != "hold": return
	np("relay tick")
func checkEnd() -> void:
	checkEndRules()   # scheduleBattleEnd: the end screen is presentation
func checkEndRules() -> void:
	if jt(B.get("over")): return
	if caps("enemy").size() == 0:
		B["over"] = "win"; return
	var o = B.get("obj")
	if o != null and o.type == "break": np("breakthrough end")
	if caps("player").size() == 0:
		B["over"] = "loss"; return
	if o != null and (o.type == "intercept" or o.type == "defend" or o.type == "hunt" or o.type == "hold"): np("objective end " + String(o.type))
	if jt(B.get("obj")) and B["obj"].type == "flagship":
		var any = false
		for u in B["units"]:
			if jt(u.get("flagship")) and u["side"] == "enemy" and not jt(u.get("dead")): any = true
		if not any:
			B["over"] = "win"; B["routed"] = true; return
	if not jt(B.get("cp0")): return
	var bossDown = false
	if jt(B.get("cfg")) and B["cfg"].get("kind") == "boss":
		bossDown = true
		for u in B["units"]:
			if jt(u.get("boss")) and u["side"] == "enemy" and not jt(u.get("dead")): bossDown = false
	if bossDown or sideCP("enemy") <= B["cp0"]["enemy"] * 0.35:
		B["over"] = "win"; B["routed"] = true

# ======================= orders, commands, abilities =======================
func canOrder(u, o) -> bool:
	if jt(u.get("dead")) or jt(u.get("order")) or jt(u.get("braced")): return false
	if o == "full": return not jt(u.get("moved")) and not jt(u.get("isSq"))
	if o == "lock": return true
	if o == "helm": return not jt(u.get("isSq")) and not jt(u.get("noTurn"))
	if o == "brace":
		if jt(u.get("isSq")): return false
		for w in u["weapons"]:
			if jt(w.get("fired")) and w["k"] != "flak": return false
		return true
	return false
func giveOrder(u, o) -> void:
	if jt(B.get("usage")) and u["side"] == "player": B["usage"]["ord"][o] = z0(B["usage"]["ord"].get(o)) + 1
	if not canOrder(u, o): return
	u["order"] = o
	if o == "brace":
		u["braced"] = true; u["mp"] = 0
		for w in u["weapons"]: w["fired"] = true
		if jt(u["fx"].get("bastion")) and u["shMax"] > 0: np("bastion boon")
	if o == "full":
		u["fullAhead"] = true; u["noTurn"] = true; u["mp"] = u["mp"] + ceil(u["mp"] * 0.5)
	if o == "lock":
		u["lockOn"] = true; u["mp"] = 0
	if o == "helm": u["turnsLeft"] = u["turnsLeft"] + 1
func abilityCd(u) -> float: return max(1, ABILITIES[u["ab"]]["cd"] - z0(u["fx"].get("cdMod")))
func liveFrom(u) -> Callable:
	var b0 = B; var ep = z0(B.get("epoch")) if B != null else 0
	return func(): return is_same(B, b0) and (z0(B.get("epoch")) if B != null else 0) == ep and (u == null or not jt(u.get("dead")))
func cmdRec(side) -> Variant:
	if B == null: return null
	return B.get("cmdE") if side == "enemy" else B.get("cmd")
func cmdPow(id, tier, side = null) -> float:
	var p = CMD_POW.get(id)
	if p == null: return 0.0
	if tier == null:
		var c = cmdRec(side if side != null else "player"); tier = z0(g(c, "tier"))
	return p[int(tier)]
func cmdActive(side, id) -> bool:
	var c = cmdRec(side)
	return c != null and c.get("id") == id and c.get("round") == B["round"]
func cmdTaken(t) -> float:
	if cmdActive(t["side"], "iron"): return 1.0 - cmdPow("iron", null, t["side"]) - (0.0 if jt(t.get("shMax")) else 0.1)
	return 1.0
func bossCmdTick() -> void:
	if B == null or jt(B.get("over")) or jt(B.get("cmdEUsed")): return
	var boss: Variant = null
	for u in B["units"]:
		if u["side"] == "enemy" and jt(g(u.get("t"), "boss")) and not jt(u.get("dead")): boss = u; break
	if boss == null: return
	var c = BOSS_CMD.get(boss["fac"])
	if c == null: return
	if B.get("cmdENext") == null:
		if B["round"] >= 2 or boss["hp"] < boss["maxHp"] * 0.6: B["cmdENext"] = B["round"] + 1
func bossCmdFire() -> void:
	if B == null or jt(B.get("over")) or jt(B.get("cmdEUsed")) or B.get("cmdENext") == null or B["round"] < B["cmdENext"]: return
	var boss: Variant = null
	for u in B["units"]:
		if u["side"] == "enemy" and jt(g(u.get("t"), "boss")) and not jt(u.get("dead")): boss = u; break
	if boss == null:
		B["cmdEUsed"] = true; return
	var c = BOSS_CMD[boss["fac"]]
	B["cmdEUsed"] = true; B["cmdE"] = {"id": c["id"], "side": "enemy", "round": B["round"], "tier": 1}
	runCommand("enemy", c, 1)
func runCommand(side, c, tier) -> bool:
	var foe = "enemy" if side == "player" else "player"; var bStart = B
	if c["id"] == "barrage":
		var b0 = B; var live = liveFrom(null); B["volleyMul"] = {"side": side, "m": 1.0 + cmdPow("barrage", tier)}
		for u in caps(side):
			if jt(B.get("over")) or not live.call(): break
			var keep = []
			for w in u["weapons"]: keep.append([w["fired"], w["cdLeft"]])
			for w in u["weapons"]:
				w["fired"] = false; w["cdLeft"] = 0
			for i in range(u["weapons"].size()):
				if jt(B.get("over")) or not live.call() or jt(u.get("dead")): break
				var w = u["weapons"][i]; var ts = []
				for t in alive(foe):
					if canFire(u, w, t): ts.append(t)
				if ts.size() == 0: continue
				var val = func(t):
					var e = expectedVs(u, w, t); return e.hull + e.shield * 0.3 + (25.0 if e.hull >= t["hp"] else 0.0)
				JSM.ssort(ts, func(a, b2): return val.call(b2) - val.call(a))
				fireWeapon(u, i, ts[0])
			for i in range(u["weapons"].size()):
				u["weapons"][i]["fired"] = keep[i][0]; u["weapons"][i]["cdLeft"] = keep[i][1]
		if is_same(B, b0): B["volleyMul"] = null
	if c["id"] == "hunt":
		for u in alive(side):
			for w in u["weapons"]:
				if w["k"] == "torp":
					w["cdLeft"] = 0; w["fired"] = false
	if c["id"] == "iron":
		for u in alive(side):
			if jt(u.get("shMax")): u["sh"] = [u["shMax"], u["shMax"], u["shMax"], u["shMax"]]
	if c["id"] == "restore":
		for u in caps(side):
			var rp = cmdPow("restore", tier); u["hp"] = min(u["maxHp"], u["hp"] + JSM.jsround(u["maxHp"] * rp))
			if jt(u.get("sec")):
				for k in u["sec"].keys(): repairSection(u, k, rp)
	if c["id"] == "surge":
		for u in caps(side):
			u["mp"] = z0(u.get("mp")) + cmdPow("surge", tier); u["turnsLeft"] = z0(u.get("turnsLeft")) + (2 if tier >= 2 else 1)
	if c["id"] == "scramble": np("scramble command")
	if is_same(B, bStart): checkEnd()
	return true
func inThisBattle(u) -> bool: return B != null and u != null and JSM.has_same(B["units"], u)
func deployWings() -> void:
	for x in B["units"]:
		if (x.get("ab") == "launch" or jt(g(x.get("fx"), "hive"))) and not jt(x.get("dead")) and not jt(x.get("isSq")): np("carrier wings")
	if jt(B.get("adaptWings")): np("adaptive fighter screen")
func squadronsOf(u) -> Array:
	var o = []
	for x in alive():
		if x.get("parent") == u["id"]: o.append(x)
	return o
func canAbility(u) -> bool:
	if not jt(u.get("ab")) or jt(u.get("dead")) or u["abCd"] > 0 or jt(u.get("braced")): return false
	var ab = u["ab"]
	if ab == "surge" and jt(u.get("st")) and u["st"]["shieldOff"] >= 99: return false
	if ab == "launch": return squadronsOf(u).size() < u["hangar"] and (u.get("spare") == null or u["spare"] > 0) and launchHexes(u).size() > 0
	if ab == "reload":
		for w in u["weapons"]:
			if w["k"] == "torp" and (w["cdLeft"] > 0 or jt(w.get("fired"))): return true
		return false
	if ab == "regrow": return u["hp"] < u["maxHp"]
	if ab == "reclaim":
		for x in alive(u["side"]):
			if not jt(x.get("isSq")) and hdist(x, u) <= 3 and x["hp"] < x["maxHp"]: return true
		return false
	if ab == "blink": return blinkHexes(u).size() > 0
	if ab == "ionpulse":
		for t in alive("enemy" if u["side"] == "player" else "player"):
			if not jt(t.get("isSq")) and hdist(t, u) <= 4: return true
		return false
	return true
func novaTargets(u) -> Array:
	var o = []
	for h in boardHexes():
		var d = hdist(u, h)
		if d >= 3 and d <= 9 and inArc(u, h, "F"): o.append(h)
	return o
func blinkHexes(u) -> Array:
	var occ = occMap(); var out = []
	for h in boardHexes():
		var d = hdist(u, h)
		if d < 1 or d > 3 or blocks(terr(h.q, h.r)) or occ.has(hkey(h.q, h.r)): continue
		out.append(h)
	return out
func launchHexes(u) -> Array:
	var occ = occMap(); var o = []
	for d in DIRS:
		var h = {"q": u["q"] + d[0], "r": u["r"] + d[1]}
		if onBoard(h.q, h.r) and not blocks(terr(h.q, h.r)) and not occ.has(hkey(h.q, h.r)): o.append(h)
	return o
func useAbility(u, arg = null) -> bool:
	if not inThisBattle(u) or not canAbility(u): return false
	if jt(B.get("usage")) and u["side"] == "player": B["usage"]["ab"][u["ab"]] = z0(B["usage"]["ab"].get(u["ab"])) + 1
	var a = u["ab"]
	if a == "evasive":
		u["evBuff"] = 25; u["mp"] = u["mp"] + 2
	if a == "reload":
		for w in u["weapons"]:
			if w["k"] == "torp":
				w["cdLeft"] = 0; w["fired"] = false
	if a == "focus": u["focus"] = true
	if a == "phase":
		u["evBuff"] = 25; u["mp"] = u["mp"] + 2
	if a == "frenzy": u["focus"] = true
	if a == "overburn":
		u["mp"] = u["mp"] + 3; u["ramBoost"] = 1.5
	if a == "regrow":
		var h = min(u["maxHp"] - u["hp"], JSM.jsround(u["maxHp"] * 0.25)); u["hp"] = u["hp"] + h
	if a == "reclaim":
		var ts = []
		for x in alive(u["side"]):
			if not jt(x.get("isSq")) and hdist(x, u) <= 3 and x["hp"] < x["maxHp"]: ts.append(x)
		JSM.ssort(ts, func(p, q): return float(p["hp"]) / p["maxHp"] - float(q["hp"]) / q["maxHp"])
		if ts.size() > 0:
			var t = ts[0]; var h = min(t["maxHp"] - t["hp"], JSM.jsround(t["maxHp"] * 0.2)); t["hp"] = t["hp"] + h
	if a == "ionpulse":
		for t in alive("enemy" if u["side"] == "player" else "player"):
			if not jt(t.get("isSq")) and hdist(t, u) <= 4 and t.get("sh") != null:
				var ns = []
				for x in t["sh"]: ns.append(floor(x * 0.5))
				t["sh"] = ns
	if a == "blink": np("phase jump")
	if a == "surge":
		for i in range(4): u["sh"][i] = u["shMax"]
		if u["st"]["shieldOff"] < 99: u["st"]["shieldOff"] = 0
	if a == "launch": np("launch wing")
	if a == "nova":
		var c = arg["hex"]
		var live = liveFrom(u)
		if not live.call(): return false
		u["abCd"] = abilityCd(u)
		var hitList = []
		for x in alive():
			if hdist(x, c) <= 1: hitList.append(x)
		for x in hitList:
			var dmg = (40.0 if hdist(x, c) == 0 else 20.0) * u["dmg"] * (1.5 if jt(x.get("isSq")) else 1.0)
			var quad = shieldQuad(x, u)
			applyHit(u, {"pierce": 0.3, "crit": 5}, x, dmg, quad)
			if x["hp"] <= 0: killUnit(x, u)
		return true
	u["abCd"] = abilityCd(u)
	return true

# ======================= enemy AI =======================
func stateView(u, s) -> Dictionary:
	var v = dup(u); v["q"] = s.q; v["r"] = s.r; v["facing"] = s.f
	if s.get("path") != null and not jt(u.get("isSq")):
		var n = 0
		for p in s.path:
			if not jt(p.get("rot")): n += 1
		v["hexMoved"] = z0(u.get("hexMoved")) + n
	return v
func evalOffense(a, ready: Array, targets: Array) -> float:
	var tot = 0.0
	for w in ready:
		var best = 0.0
		for t in targets:
			if not inReach(a, w, t): continue
			var e = expectedVs(a, w, t); var v: float = e.hull + e.shield * 0.3
			if e.hull >= t["hp"]: v += 15.0 + t["maxHp"] * 0.1
			if jt(t.get("isSq")) and not jt(w.get("vsSq")): v *= 0.5
			if v > best: best = v
		tot += best
	return tot
func aiVet() -> bool: return AI_LEVEL == "veteran"
func evalThreatVet(v, foes: Array) -> float:
	var tot = 0.0
	for p in foes:
		var d = hdist(p, v)
		if d > 13: continue
		var ls: Variant = null
		for w in p["weapons"]:
			if w["cdLeft"] > 1 or w["off"] > 1 or not aiGunLive(p, w): continue
			if d <= w["r"] and inArc(p, v, w["arc"]):
				var e = expectedVs(p, w, v); tot += e.hull + e.shield * 0.2
			elif d <= w["r"] + max(1, (p["speed"] if jt(p.get("speed")) else 2) - 1) and aiArcSoon(p, v, w["arc"]):
				if ls == null: ls = los(p, v)
				if ls:
					var e = expectedVs(p, w, v); tot += (e.hull + e.shield * 0.2) * 0.2
	return tot
func aiGunLive(p, w) -> bool:
	if w["k"] == "flak": return false
	if B != null and jt(B.get("alt")) and (jt(w.get("fired")) or jt(p.get("braced"))): return false
	return true
func aiArcSoon(p, v, arc) -> bool:
	if arc == "T" or inArc(p, v, arc): return true
	if not (z0(p.get("turns")) > 0): return false
	var f = int(p["facing"])
	return inArc({"q": p["q"], "r": p["r"], "facing": (f + 1) % 6}, v, arc) or inArc({"q": p["q"], "r": p["r"], "facing": (f + 5) % 6}, v, arc)
func ramSetup(v, u) -> float:
	var d = DIRS[int(v["facing"])]; var q = v["q"]; var r = v["r"]
	var i = 0
	while i <= (u["speed"] if jt(u.get("speed")) else 2):
		q += d[0]; r += d[1]
		if not onBoard(q, r) or blocks(terr(q, r)): return 0.0
		var o = unitAt(q, r)
		if o != null and not is_same(o, u):
			if o["side"] != u["side"] and not jt(o.get("isSq")) and i >= 1:
				var vv = dup(u); vv["q"] = v["q"]; vv["r"] = v["r"]; vv["facing"] = v["facing"]
				return ramEstimate(vv, o)["dmg"]
			return 0.0
		i += 1
	return 0.0
func aiShooters() -> Array:
	var o = []
	for u in caps("enemy"):
		if not jt(u.get("transport")) and u["weapons"].size() > 0: o.append(u)
	return o
func aiFocusVal(t, shooters: Array) -> float:
	if t == null or jt(t.get("dead")) or jt(t.get("isSq")): return 0.0
	var br: float = max(0.15, 1.0 - 0.4 - z0(g(t.get("fx"), "bracePlus"))) if jt(t.get("braced")) else 1.0
	var take: float = max(0.15, br * guardMul(t) * cmdTaken(t))
	var shs = 0.0
	for x in t["sh"]: shs += x
	var ehp: float = t["hp"] / take + shs * 0.3; var n = 0
	for u in shooters:
		var rr = 0.0
		for w in u["weapons"]:
			if w["cdLeft"] <= 1 and w["off"] <= 1 and w["k"] != "flak" and w["r"] > rr: rr = w["r"]
		if rr != 0.0 and hdist(u, t) <= rr + (u["speed"] if jt(u.get("speed")) else 2): n += 1
	return ((float(t["t"]["cp"]) if jt(t["t"].get("cp")) else 1.0) * 12.0 + (20.0 if jt(t.get("flagship")) or jt(t.get("pflag")) else 0.0)) / max(20.0, ehp) * (1.0 if n >= 2 else (0.8 if n == 1 else 0.4))
func aiRefreshFocus() -> Variant:
	if B == null: return null
	if not aiVet():
		B["aiFocus"] = null; return null
	var sh = aiShooters(); var af = B.get("aiFocus")
	var cur = af if (af != null and not jt(af.get("dead")) and af["side"] == "player" and inThisBattle(af)) else null
	var cv = aiFocusVal(cur, sh) if cur != null else 0.0
	var best: Variant = null; var bv = 0.0
	for t in alive("player"):
		if jt(t.get("isSq")) or (cur != null and is_same(t, cur)): continue
		var v = aiFocusVal(t, sh)
		if v > bv: bv = v; best = t
	B["aiFocus"] = (best if best != null else cur) if (cur == null or (best != null and bv > cv * 1.25)) else cur
	return B["aiFocus"]
func evalOffenseVet(a, ready: Array, targets: Array, focus) -> float:
	var tot = 0.0
	for w in ready:
		var best = 0.0
		for t in targets:
			if not inReach(a, w, t): continue
			var e = expectedVs(a, w, t); var v: float = e.hull + e.shield * 0.3
			if e.hull >= t["hp"]: v += 15.0 + t["maxHp"] * 0.1
			if jt(t.get("isSq")) and not jt(w.get("vsSq")): v *= 0.5
			if focus != null and is_same(t, focus): v *= 1.3
			if e.rear: v *= 1.1
			if v > best: best = v
		tot += best
	return tot
func aiPickActivation(list: Array) -> Variant:
	if not aiVet() or list.size() < 2: return list[0]
	aiRefreshFocus(); var foes = alive("player"); var best = list[0]; var bv = -1e9
	var foc = B.get("aiFocus")
	for u in list:
		if jt(u.get("isSq")): continue
		var ready = readyList(u); var mx = 0.0
		for f in range(6):
			var vv = dup(u); vv["facing"] = f
			var o = evalOffenseVet(vv, ready, foes, foc)
			if o > mx: mx = o
		var reach = 0.0
		for t in foes:
			var d = hdist(u, t)
			for w in ready:
				if d <= w["r"] + (u["speed"] if jt(u.get("speed")) else 2): reach = max(reach, w["dmg"] * w["shots"] * (1.3 if (foc != null and is_same(t, foc)) else 1.0))
		var val: float = mx + reach * 0.5 + evalThreat(u, foes) * 0.25 + (10.0 if u["hp"] < u["maxHp"] * 0.3 else 0.0)
		if val > bv: bv = val; best = u
	return best
func evalThreat(v, foes: Array) -> float:
	var tot = 0.0
	for p in foes:
		if hdist(p, v) > 9: continue
		for w in p["weapons"]:
			if w["cdLeft"] > 1 or w["off"] > 1 or not aiGunLive(p, w): continue
			if hdist(p, v) > w["r"]: continue
			if not inArc(p, v, w["arc"]): continue
			var e = expectedVs(p, w, v); tot += e.hull + e.shield * 0.2
	return tot
func aiPickPrimary(u, ws: Array, focus) -> Variant:
	var pv = 0.0; var primary: Variant = null
	for t in alive("player"):
		var sh = 0.0; var hull = 0.0
		for w in ws:
			if not canFire(u, w, t): continue
			var e = expectedVs(u, w, t); sh += e.shield * 0.3; hull += e.hull
		if sh == 0.0 and hull == 0.0: continue
		var val: float = (min(hull, t["hp"]) + sh) * (0.6 if jt(t.get("isSq")) else 1.1) + ((25.0 + t["maxHp"] * 0.15) if hull >= t["hp"] else 0.0) + (10.0 if (focus != null and is_same(t, focus)) else 0.0) + (1.0 - float(t["hp"]) / t["maxHp"]) * 15.0
		if val > pv: pv = val; primary = t
	return primary
func aiGunOrder(u, ws: Array, t) -> Array:
	var keys = []   # Map keyed by weapon identity: parallel array
	for w in ws:
		var v = -1.0
		if t != null and canFire(u, w, t):
			var e = expectedVs(u, w, t); v = JSM.jsround(e.shield / e.raw * 4.0) if e.raw > 0 else 0.0
		keys.append(v)
	var idx = []
	for i in range(ws.size()): idx.append(i)
	var cmp = func(a, b):
		var d: float = keys[b] - keys[a]
		return d if d != 0.0 else float(ws[b]["dmg"] * ws[b]["shots"] - ws[a]["dmg"] * ws[a]["shots"])
	JSM.ssort(idx, cmp)
	var o = []
	for i in idx: o.append(ws[i])
	return o
func aiVolley(u, live: Callable) -> Variant:
	var vet = aiVet(); var focus = B["aiFocus"] if (vet and B.get("aiFocus") != null and not jt(B["aiFocus"].get("dead"))) else null; var tried = []
	var fired = false
	for gi in range(u["weapons"].size()):
		if jt(B.get("over")): return null
		if jt(u.get("dead")): break
		var ws = []
		for w in u["weapons"]:
			if weaponReady(w) and w["k"] != "flak" and not JSM.has_same(tried, w): ws.append(w)
		if ws.size() == 0: break
		var primary = aiPickPrimary(u, ws, focus)
		var w = aiGunOrder(u, ws, primary)[0]; var wi = JSM.index_same(u["weapons"], w); tried.append(w)
		var bt: Variant = null; var bv = 0.0
		var taunt: Variant = null
		for p in alive("player"):
			if not jt(p.get("isSq")) and jt(g(p.get("fx"), "taunt")) and hdist(p, u) <= p["fx"]["taunt"]: taunt = p; break
		var sqblock = false
		if vet and primary != null and canFire(u, w, primary) and z0(w.get("vsSq")) > 1 and not jt(primary.get("isSq")):
			for s in alive("player"):
				if jt(s.get("isSq")) and canFire(u, w, s): sqblock = true
		if taunt != null and canFire(u, w, taunt):
			bt = taunt; bv = 1.0
		elif vet and primary != null and canFire(u, w, primary) and not sqblock:
			bt = primary; bv = 1.0
			if expectedVs(u, w, primary).hull >= primary["hp"] * 2:
				var other = false
				for x in ws:
					if not is_same(x, w) and canFire(u, x, primary) and expectedVs(u, x, primary).hull >= primary["hp"]: other = true; break
				if other:
					var av = 3.0
					for t in alive("player"):
						if is_same(t, primary) or not canFire(u, w, t): continue
						var e = expectedVs(u, w, t); var v: float = min(e.hull, t["hp"]) + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
						if v > av: av = v; bt = t
		else:
			for t in alive("player"):
				if not canFire(u, w, t): continue
				var e = expectedVs(u, w, t); var v: float = min(e.hull, t["hp"]) + e.shield * 0.3
				if e.hull >= t["hp"]: v += 20.0
				if not jt(t.get("isSq")): v *= 1.1
				if v > bv: bv = v; bt = t
		if bt != null and bv > 0.5:
			fireWeapon(u, wi, bt, {"called": null}); fired = true
			if not live.call(): return null
	return fired
func pathField(targets: Array) -> Dictionary:
	var D = {}; var q = []
	for t in targets:
		var k = hkey(t["q"], t["r"])
		if not D.has(k):
			D[k] = 0; q.append(t)
	var i = 0
	while i < q.size():
		var h = q[i]; var d = D[hkey(h["q"], h["r"])]
		for dd in DIRS:
			var n = {"q": h["q"] + dd[0], "r": h["r"] + dd[1]}; var k = hkey(n.q, n.r)
			if D.has(k) or not onBoard(n.q, n.r) or blocks(terr(n.q, n.r)): continue
			D[k] = d + 1; q.append(n)
		i += 1
	return D
func fieldDist(D: Dictionary, v, fallback) -> float:
	var d = D.get(hkey(v["q"], v["r"]))
	return fallback + 6.0 if d == null else float(d)
func aiAbilities(u, live: Callable, mode) -> bool:
	var foes = alive("player")
	if foes.size() == 0 or jt(u.get("dead")): return live.call()
	var pre: bool = mode == "pre"; var aim: bool = mode == "aim"
	if pre and u.get("ab") == "launch" and canAbility(u): np("AI wing launch")
	var nearF: Variant = null
	for f in foes:
		if jt(f.get("isSq")): continue
		if nearF == null or hdist(u, f) < hdist(u, nearF): nearF = f
	if pre and u.get("ab") == "surge" and canAbility(u) and nearF != null and hdist(u, nearF) <= 8 and u["sh"][shieldQuad(u, nearF)] < u["shMax"] * 0.5:
		useAbility(u)
		if not live.call(): return false
	if aim and (u.get("ab") == "focus" or u.get("ab") == "frenzy") and canAbility(u):
		var any = false
		for w in u["weapons"]:
			if not weaponReady(w): continue
			for f in foes:
				if canFire(u, w, f): any = true; break
			if any: break
		if any: useAbility(u)
	if pre and (u.get("ab") == "evasive" or u.get("ab") == "phase") and canAbility(u):
		var any = false
		for f in foes:
			if hdist(u, f) <= 5: any = true; break
		if any: useAbility(u)
	if u.get("ab") == "reload" and canAbility(u):
		var go = false
		if pre:
			for f in foes:
				if not jt(f.get("isSq")) and hdist(u, f) <= 6 + (u["speed"] if jt(u.get("speed")) else 2): go = true; break
		elif aim:
			for w in u["weapons"]:
				if w["k"] == "torp" and w["off"] == 0 and not weaponReady(w):
					for f in foes:
						if not jt(f.get("isSq")) and inReach(u, w, f): go = true; break
				if go: break
		if go:
			useAbility(u)
			if not live.call(): return false
	if pre and u.get("ab") == "regrow" and canAbility(u) and u["hp"] < u["maxHp"] * 0.6: useAbility(u)
	if pre and u.get("ab") == "reclaim" and canAbility(u):
		var any = false
		for x in alive("enemy"):
			if not jt(x.get("isSq")) and hdist(x, u) <= 3 and x["hp"] < x["maxHp"] * 0.6: any = true; break
		if any: useAbility(u)
	if pre and u.get("ab") == "ionpulse" and canAbility(u):
		var tot = 0.0
		for t in foes:
			if not jt(t.get("isSq")) and hdist(t, u) <= 4:
				for x in t["sh"]: tot += x
		if tot >= 30: useAbility(u)
	if pre and u.get("ab") == "overburn" and canAbility(u) and nearF != null and hdist(u, nearF) > (u["speed"] if jt(u.get("speed")) else 2) + 1: useAbility(u)
	if u.get("ab") == "blink" and canAbility(u) and nearF != null: np("AI phase jump")
	return live.call()
func aiAfterFire(u, live: Callable, runner) -> bool:
	if not jt(u.get("isSq")) and not jt(runner) and not jt(u.get("dead")): tacticRam(u)
	if jt(B.get("over")) or jt(u.get("dead")) or not live.call(): return false
	return aiAbilities(u, live, "escape") and not jt(B.get("over"))
func aiUnit(u) -> void:
	if jt(u.get("isSq")): np("squadron AI")
	if u["side"] == "enemy" and not jt(B.get("cmdEUsed")) and B.get("cmdENext") != null:
		bossCmdFire()
		if jt(B.get("over")) or jt(u.get("dead")): return
	var live = liveFrom(u)
	if jt(B.get("over")) or jt(u.get("dead")) or u["side"] != "enemy": return
	u["_calledUsed"] = false
	B["aiActive"] = u
	if not live.call(): return
	var foes = alive("player")
	if foes.size() == 0: return
	if not aiAbilities(u, live, "pre"): return
	var runner = u.get("transport") if jt(u.get("transport")) else (jt(B.get("obj")) and B["obj"].type == "hunt" and jt(u.get("flagship")))
	if not jt(u.get("isSq")) and not jt(runner): tacticRam(u)
	if jt(B.get("over")) or jt(u.get("dead")) or not live.call(): return
	var ready = readyList(u)
	var states: Array = computeReach(u).states
	var opts = []
	for w in u["weapons"]: opts.append(w["opt"])
	var minR = JSM.amin(opts)
	var best: Variant = null; var bestScore = -1e9
	var pff = []
	for f in foes:
		if not jt(f.get("isSq")) or jt(u.get("isSq")): pff.append(f)
	var PF = pathField(pff)
	var vet0 = aiVet(); var focus0 = aiRefreshFocus() if vet0 else null
	var flE: Variant = null; var escO = []; var escIn = 0
	if vet0 and jt(B.get("obj")) and B["obj"].type == "flagship" and not jt(u.get("flagship")) and not jt(u.get("isSq")):
		for x in B["units"]:
			if jt(x.get("flagship")) and not jt(x.get("dead")) and x["side"] == "enemy": flE = x; break
	if flE != null:
		for x in caps("enemy"):
			if not is_same(x, u) and not is_same(x, flE) and not jt(x.get("transport")): escO.append(x)
		for x in escO:
			if hdist(x, flE) <= 3: escIn += 1
	for s in states:
		var v = stateView(u, s)
		var vet = vet0; var focus = focus0
		var off = evalOffenseVet(v, ready, foes, focus) if vet else evalOffense(v, ready, foes)
		var threat = evalThreatVet(v, foes) if vet else evalThreat(v, foes)
		var prof = FACTION_AI[u["fac"]] if (not jt(u.get("isSq")) and jt(FACTION_AI.get(u["fac"]))) else FACTION_AI["voidsworn"]
		var tw: float = (0.15 if jt(u.get("isSq")) else (0.3 if not vet else (0.65 if jt(u.get("flagship")) else (0.6 * prof["hurt"] if u["hp"] < u["maxHp"] * 0.3 else 0.32)))) * prof["tw"]
		var score: float = off - threat * tw
		if vet and not jt(u.get("isSq")) and threat >= u["hp"]: score -= 25.0
		if vet and not jt(u.get("isSq")) and jt(prof.get("range")):
			var ds = [99]
			for f in foes:
				if not jt(f.get("isSq")): ds.append(hdist(v, f))
			var nd2 = JSM.amin(ds)
			if prof["range"] > 0: score -= max(0, prof["range"] - nd2) * prof["rw"]
			else: score -= max(0, nd2 + prof["range"]) * prof["rw"]
		if vet and not jt(u.get("isSq")) and jt(RAM_FAC.get(u["fac"])): score += ramSetup(v, u) * 0.35
		if vet and jt(B.get("obj")) and B["obj"].type == "flagship" and not jt(u.get("flagship")) and not jt(u.get("isSq")):
			if flE != null:
				var dv = hdist(v, flE); score -= max(0, dv - 3) * (0.6 if escIn >= 2 else 2.0)
				if dv <= 3:
					for x in escO:
						if hdist(x, v) == 1: score -= 1
		if off <= 0:
			var hds = []
			for f in foes:
				if not jt(f.get("isSq")) or jt(u.get("isSq")): hds.append(hdist(v, f))
			hds.append(99)
			var hd = JSM.amin(hds); var nd: float = max(hd, fieldDist(PF, v, hd)); score -= max(0, nd - minR) * 4.0
		score -= s.cost * 0.05
		if jt(B.get("obj")) and B["obj"].type == "hold" and not jt(u.get("isSq")) and not vet: np("relay pull (standard AI)")
		score += aiObjScore(u, v); score += aiWellScore(u, v)
		if score > bestScore:
			bestScore = score; best = s
	var vctx = {"started": false, "result": null}
	if best != null and best.path.size() > 0:
		var midFire: bool = not jt(u.get("isSq")) and not jt(runner) and not (u.get("ab") == "nova" and canAbility(u))
		var mopts: Variant = null
		if midFire:
			var on_late = func():
				if boardTargets(u).size() > 0: return
				vctx.started = true
				if not aiAbilities(u, live, "aim") or jt(u.get("dead")):
					vctx.result = null; return
				vctx.result = aiVolley(u, live)
			mopts = {"onLate": on_late}
		moveUnit(u, best, mopts)
		if not live.call(): return
	if vctx.started:
		var fired = vctx.result
		if not live.call() or jt(B.get("over")): return
		if not aiAfterFire(u, live, runner): return
		if not jt(fired) and not jt(u.get("dead")) and u["hp"] < u["maxHp"] * 0.5 and canOrder(u, "brace") and evalThreat(u, alive("player")) > 10: giveOrder(u, "brace")
		B["aiActive"] = null; u["activated"] = true; return
	if u.get("ab") == "nova" and canAbility(u):
		var bh = null; var bv = 0.0
		for h in novaTargets(u):
			var v = 0.0
			for x in alive():
				var d = hdist(x, h)
				if d > 1: continue
				var dm = 40.0 if d == 0 else 20.0
				v += dm if x["side"] == "player" else -dm * 1.5
			if v > bv:
				bv = v; bh = h
		if bh != null and bv >= 40:
			useAbility(u, {"hex": bh})
			if not live.call(): return
	if not jt(u.get("isSq")) and not jt(runner) and tacticBoard(u):
		if live.call():
			B["aiActive"] = null; u["activated"] = true
		return
	if not live.call(): return
	if aiVet() and not jt(u.get("isSq")) and not jt(u["t"].get("boss")) and canOrder(u, "brace"):
		var pf = alive("player"); var myOff = evalOffense(u, readyList(u), pf); var thr = evalThreat(u, pf)
		if thr > u["hp"] * 0.45 and myOff < thr * 0.35 and u["hp"] < u["maxHp"] * 0.7:
			giveOrder(u, "brace"); B["aiActive"] = null; u["activated"] = true; return
	if not aiAbilities(u, live, "aim"): return
	var fired2 = aiVolley(u, live)
	if fired2 == null: return
	if not aiAfterFire(u, live, runner): return
	if not jt(fired2) and not jt(u.get("isSq")) and not jt(u.get("dead")) and u["hp"] < u["maxHp"] * 0.5 and canOrder(u, "brace") and evalThreat(u, alive("player")) > 10: giveOrder(u, "brace")
	B["aiActive"] = null; u["activated"] = true
