# Voidsworn battle rules, ported line for line from data.js, core.js and battle.js (A3 parity spike, Oct 25 2026).
# Objects stay Dictionaries with the JS field names, so the golden records compare field by field. Numbers stay doubles like JS
# (division always with a float operand, Math.round through JSM.jsround, % on doubles through fmod).
# Async rules functions run synchronously: in the headless game every await resolves at once and every call is awaited in turn,
# except deaths queued by turn ticks (fire, acid, the dead star, station guns), whose tail runs later in JS; those tails are deferred
# here and run by flush_deferred() at the point where the game awaits them.
# Presentation (log text, floating numbers, sounds, camera) is not ported: the harness gives it no-op stubs on both sides.
# Anything the slice does not reach and the port does not carry stops the run with "NOT PORTED", so a gap can never pass silently.
extends RefCounted
# The JS port keeps JS shapes (untyped Dictionaries, JS-style numbers), so the untyped-code warnings are silenced for this file only.
# Of the six classes the project leaves on, three stay ON here and give 0 warnings (Oct 26, checked by turning them into errors):
# integer_division and narrowing_conversion (the JS-port number traps) and unsafe_property_access. The other three are silenced
# because they are the JS shapes themselves (2,676 call arguments, 1,097 method calls, 68 discarded results at Oct 26): unsafe_call_argument
# (Variant into a typed float), unsafe_method_access (calls on untyped values) and return_value_discarded (JS ignores results the same way).
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "shadowed_variable", "shadowed_variable_base_class", "shadowed_global_identifier", "unused_variable", "unused_parameter", "confusable_local_declaration", "confusable_local_usage", "return_value_discarded", "incompatible_ternary")
const JSM = preload("res://rules/jsm.gd")

var TB: Dictionary = {}
var WPN; var ARC_NAME; var FAC_WNAMES; var FAC_WTRAIT; var HULLS; var MOVE_RULES; var FACTIONS; var ABILITIES; var ORDERS; var MODULES; var PERKS
var RANK_XP; var RELICS; var ADMIRALS; var SHIP_NAMES; var CAPTAINS; var MORE_SHIP_NAMES; var SECTOR_CONDS; var RARITY; var ASPECTS
var DIRS; var PACE; var BLOCKING; var SHAPES; var BEVENTS; var ENC_ARENA; var FAC_MAP; var ENCOUNTERS; var CREW_MULT; var BOARD_MULT; var RAM_FAC
var BOSS_FAC; var BOSS_SCALE; var BOSS_DMG; var RAMP; var ARENAS; var AXIS_SHAPES; var MOVE_BASE; var SEC_OF_QUAD; var CMD_POW; var BOSS_CMD; var FACTION_AI
var ROCK_KINDS; var REGION_BIOME; var COMMANDS; var SEC_NAME; var QUAD_NAME; var FNAMES
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
# Event stream for rendering (API.md). Emitted where the JS game calls its presentation hooks; never read by the rules.
var events: Array = []
var events_on := true
func emit(e: Dictionary) -> void:
	if events_on: events.append(e)
func _uid(u): return u["id"] if u is Dictionary and u.get("id") != null else null
# The battle log (battle.js log(m, c)): B.log gets {m, c} exactly as the game writes it (hashed by the parity test), and a log event.
func logm(m: String, c = null) -> void:
	if B == null or B.get("log") == null: return
	var e = {"m": m}
	if c != null: e["c"] = c
	B["log"].append(e)
	emit({"t": "log", "text": m, "kind": c})
func ns(x) -> String: return JSM.numstr(x)   # a number as JS prints it in a template string
func tv(x) -> String: return "undefined" if x == null else (ns(x) if (x is float or x is int) else String(x))   # any value in a template string
func pe(u) -> String: return "e" if u["side"] == "player" else "p"   # log colour for a loss on u's side
func pp(u) -> String: return "p" if u["side"] == "player" else "e"
# A floating callout over a ship (battle.js fxText): presentation only, never touches rules state
func flt(u, text: String, color: String, dy = null) -> void:
	if u != null: emit({"t": "float", "unit": u.get("id"), "text": text, "color": color, "dy": dy})
# Per-action hash points for the parity test: called exactly where the JS game calls a presentation hook (animPath, animWeapon,
# animExplode, fxRam, fxBoard, animNova) and after each ability, order and turn-start tick. The game leaves hook_cb null.
var hook_cb = null
func hook(kind: String, u = null) -> void:
	if hook_cb != null: hook_cb.call(kind, u)

# ======================= loading =======================
func load_tables(path: String) -> String:
	var txt = FileAccess.get_file_as_string(path)
	var j = JSON.parse_string(txt)
	if j == null: return "cannot read " + path
	TB = _dec(j["tables"])
	var sum = JSM.sha256(JSM.canon(TB, "t", {}, true))
	if sum != j["sha256"]: return "table checksum differs: " + sum + " vs " + str(j["sha256"])
	# fail hard on a missing table (the exporter lists every table this port reads; it refuses to write the file if one is missing)
	if not (j.get("required") is Array): return "tables.json has no required-table list: re-export it with rules/test/node/export_data.js"
	var missing: Array = []
	for n in j["required"]:
		if not TB.has(n): missing.append(n)
	if not missing.is_empty(): return "tables missing from " + path + ": " + " ".join(missing)
	WPN = TB.W; ARC_NAME = TB.ARC_NAME; FAC_WNAMES = TB.FAC_WNAMES; FAC_WTRAIT = TB.FAC_WTRAIT; HULLS = TB.HULLS; MOVE_RULES = TB.MOVE_RULES
	FACTIONS = TB.FACTIONS; ABILITIES = TB.ABILITIES; ORDERS = TB.ORDERS; MODULES = TB.MODULES; PERKS = TB.PERKS; RANK_XP = TB.RANK_XP; RELICS = TB.RELICS
	ADMIRALS = TB.ADMIRALS; SHIP_NAMES = TB.SHIP_NAMES; CAPTAINS = TB.CAPTAINS; MORE_SHIP_NAMES = TB.MORE_SHIP_NAMES; SECTOR_CONDS = TB.SECTOR_CONDS
	RARITY = TB.RARITY; ASPECTS = TB.ASPECTS; DIRS = TB.DIRS; PACE = TB.PACE; BLOCKING = TB.BLOCKING; SHAPES = TB.SHAPES; BEVENTS = TB.BEVENTS
	ENC_ARENA = TB.ENC_ARENA; FAC_MAP = TB.FAC_MAP; ENCOUNTERS = TB.ENCOUNTERS; CREW_MULT = TB.CREW_MULT; BOARD_MULT = TB.BOARD_MULT; RAM_FAC = TB.RAM_FAC
	BOSS_FAC = TB.BOSS_FAC; BOSS_SCALE = TB.BOSS_SCALE; BOSS_DMG = TB.BOSS_DMG; RAMP = TB.RAMP; ARENAS = TB.ARENAS; AXIS_SHAPES = TB.AXIS_SHAPES
	MOVE_BASE = TB.MOVE_BASE; SEC_OF_QUAD = TB.SEC_OF_QUAD; CMD_POW = TB.CMD_POW; BOSS_CMD = TB.BOSS_CMD; FACTION_AI = TB.FACTION_AI
	ROCK_KINDS = TB.ROCK_KINDS; REGION_BIOME = TB.REGION_BIOME; COMMANDS = TB.COMMANDS; SEC_NAME = TB.SEC_NAME; QUAD_NAME = TB.QUAD_NAME; FNAMES = TB.get("FNAMES", {})
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
# set by np() or by an unported maths branch in jsm.gd; the harness stops at the next record and reports it, the battle scene logs it.
# Clearing it (not_ported = "") clears both.
var _np_rules := ""
var not_ported: String:
	get: return _np_rules if _np_rules != "" else JSM.not_ported
	set(v):
		_np_rules = v
		if v == "": JSM.not_ported = ""
func np(what: String) -> void:
	if not_ported == "": not_ported = what
	push_error("NOT PORTED: " + what)
func jt(x) -> bool: # JS truthiness (named jt: Object.tr is taken)
	if x == null: return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING, TYPE_STRING_NAME: return x != ""
	return true
# JS strict equality (a === b) for untyped values. GDScript stops the call with a script error when == or != meets two different
# types (Dictionary vs false, "x" vs 1, [] vs "s", true vs 1; only null, int/float and String/StringName mix), where JS just says false.
# Use this, or js_false, wherever a value from outside the rules (a battle config, a save, a scene call) is compared.
static func js_eq(a, b) -> bool:
	if a == null or b == null: return a == null and b == null
	var ta := typeof(a); var tb := typeof(b)
	if (ta == TYPE_INT or ta == TYPE_FLOAT) and (tb == TYPE_INT or tb == TYPE_FLOAT): return a == b
	if (ta == TYPE_STRING or ta == TYPE_STRING_NAME) and (tb == TYPE_STRING or tb == TYPE_STRING_NAME): return String(a) == String(b)
	if ta != tb: return false
	if ta == TYPE_DICTIONARY or ta == TYPE_ARRAY or ta == TYPE_OBJECT: return is_same(a, b)
	return a == b
static func js_false(x) -> bool: return x is bool and x == false # x === false
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
func dup(u: Dictionary) -> Dictionary: # Object.create(u) for reads: a shallow copy, marked as a view (never stored in the battle)
	var v = u.duplicate(false); v["__view"] = true; return v
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
# Speed (A3 timing, Oct 25): caches that cannot change a result.
#  - angTo is a pure function of the two hexes, so it is memoised for the whole run.
#  - While the AI (or the bot) only scores positions, nothing on the board changes, so line of sight and the guard multiplier
#    are memoised inside those scoring loops only (eval_begin / eval_end) and dropped afterwards.
#  - runFx reads relics and unlocks, which do not change during a battle.
var _ang := {}
var _evc := false
var _los := {}
var _guard := {}
var _tc := {}      # terrain by packed hex, inside a scoring window (terrain cannot change there)
var _ob := {}      # onBoard by packed hex, for the whole battle (the board and its cut-outs are fixed at setup)
var _mr := {}      # moveRules by faction (read-only tables)
var _hc := {}      # hitChance inside a scoring window, keyed by both ships' positions and hexes moved
var _lw := {}      # evalThreatVet: each foe's live guns inside a scoring window
var _slot := {}    # unit id -> small number, for the packed cache keys
var _runfx = null
func eval_begin() -> void:
	_evc = true; _los.clear(); _guard.clear(); _tc.clear(); _hc.clear(); _lw.clear(); _slot.clear()
	if B != null:
		for i in range(B["units"].size()): _slot[B["units"][i]["id"]] = i
func eval_end() -> void:
	_evc = false; _los.clear(); _guard.clear(); _tc.clear(); _hc.clear(); _lw.clear(); _slot.clear()
func angTo(a, b) -> float:
	var k = ((int(a["q"]) + 64) * 128 + int(a["r"]) + 64) * 16384 + (int(b["q"]) + 64) * 128 + int(b["r"]) + 64
	var c = _ang.get(k)
	if c != null: return c
	var pa = axPx(a["q"], a["r"]); var pb = axPx(b["q"], b["r"])
	var v = JSM.atan2(pb.y - pa.y, pb.x - pa.x) * 180.0 / PI
	_ang[k] = v
	return v
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
	else: base = (FNAMES.get(fac) if FNAMES.has(fac) else []) + (MORE_SHIP_NAMES.get(fac) if MORE_SHIP_NAMES.has(fac) else [])   # FNAMES: the browser's ui3d.js table, exported
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
		for b in (RUN.get("boons") if RUN.get("boons") != null else []):
			if TB.BOONS.has(b["id"]): l.append(boon_fx(b["id"], float(RARITY[int(z0(b.get("r")))]["m"])))
	return l
# data.js BOONS[id].fx(m): the boon effects are code in the game, so they are ported here (m = RARITY[r].m: 1, 1.5 or 2)
func boon_fx(id, m: float) -> Dictionary:
	match id:
		"i_broad": return {"broadPct": 0.2 * m}
		"i_still": return {"stillPct": 0.25 * m}
		"i_plate": return {"armor": 0.08 * m}
		"i_brace": return {"riposte": JSM.jsround(18.0 * m), "bracePlus": 0.1 * m}
		"i_line": return {"lineGuard": 0.12 * m, "lineEv": 5 if m >= 2 else 0}
		"s_cap": return {"shPct": 0.2 * m}
		"s_arc": return {"arcShort": JSM.jsround(9.0 * m)}
		"s_ion": return {"ionPlus": 0.22 * m}
		"s_regen": return {"stormRegen": 0.18 * m}
		"s_ev": return {"ev": JSM.jsround(6.0 * m)}
		"h_hatch": return {"hangar": 2 if m >= 1.5 else 1}
		"h_wings": return {"sqPct": 0.25 * m}
		"h_chitin": return {"sqHp": 0.3 * m}
		"h_board": return {"boardPct": 0.25 * m}
		"h_feast": return {"feast": 0.05 * m}
		"a_lance": return {"lancePct": 0.35 * m}
		"a_aim": return {"aim": JSM.jsround(5.0 * m)}
		"a_crit": return {"crit": JSM.jsround(6.0 * m), "critMul": 0.25 * m, "critSys": 1}
		"a_long": return {"longAim": floor(m * 1.5), "lanceRange": 1 if m >= 2 else 0}
		"a_rear": return {"rearPct": 0.25 * m}
		"r_burn": return {"speed": 2 if m >= 2 else 1, "ev": 10 if m >= 2 else (6 if m >= 1.5 else 0)}
		"r_prow": return {"ramPct": 0.35 * m, "ramCap": 0.1 * m, "ramGuard": 0.5}
		"r_mom": return {"momPct": 0.05 * m}
		"r_jink": return {"burnEv": JSM.jsround(15.0 * m)}
		"r_shock": return {"ramSplash": 0.25 * m}
		"e_war": return {"torpPct": 0.25 * m}
		"e_reload": return {"torpCd": 2 if m >= 1.5 else 1}
		"e_kindle": return {"igniteCh": 0.12 * m, "fireDmg": JSM.jsround(4.0 * m)}
		"e_chain": return {"chainBoom": JSM.jsround(20.0 * m), "chainFire": 1 if m >= 2 else 0}
		"e_hunt": return {"huntPct": 0.2 * m, "pyre": 1}
		"d_jugg": return {"ramPct": 0.5, "ramGuard": 1}
		"d_bastion": return {"bastion": 1, "bracePlus": 0.1}
		"d_ionlance": return {"ionLance": 1}
		"d_burnswarm": return {"sqIgnite": 0.3}
		"d_hunter": return {"momCrit": 25}
		"d_inferno": return {"broadIgnite": 0.4, "fireLong": 1, "fireDmg": 4}
		"i_wall": return {"wallBrace": 1}
		"s_chain": return {"chainSh": 1}
		"h_brood": return {"broodTithe": 1}
		"a_mark": return {"markLance": 1}
		"r_slip": return {"fade": 1}
		"e_spread": return {"spread": 0.3}
		"L_iron": return {"lastStand": 1}
		"L_storm": return {"stormRegen": 1}
		"L_hunger": return {"hangar": 2, "endless": 1}
		"L_star": return {"lanceSure": 1}
		"L_rook": return {"ramPct": 0.5, "ramCap": 0.3, "ramGuard": 1}
		"L_ember": return {"chainBoom": 40}
	np("boon " + str(id)); return {}
func hasBoon(id) -> bool:
	if RUN == null or RUN.get("boons") == null: return false
	for b in RUN["boons"]:
		if b["id"] == id: return true
	return false
func runFx() -> Dictionary:
	if _runfx == null: _runfx = _runFx_raw()
	return _runfx
func _runFx_raw() -> Dictionary:
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
	if b.get("k") == "lance" and jt(fx.get("lanceRange")):
		w["r"] = w["r"] + fx["lanceRange"]; w["opt"] = w["opt"] + fx["lanceRange"]
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
	var mm = 1.0 + 0.2 * (float(mk) - 1.0); var tr = classTrack(t.get("cls"))
	var maxHp = JSM.jsround(float(t["hp"]) * mm * (1.0 + float(z0(fx.get("hpPct"))) + 0.06 * tr))
	var ws = []
	for e in t["w"]: ws.append(mkWeapon(e[0], e[1], fx))
	return {
		"maxHp": maxHp, "shMax": JSM.jsround(float(t["sh"]) * mm * (1.0 + float(z0(fx.get("shPct"))))), "regen": JSM.jsround(float(t["rg"]) * mm * (1.0 + float(z0(fx.get("regenPct"))))),
		"armor": min(0.6, float(t["ar"]) + float(z0(fx.get("armor")))), "speed": float(t["sp"]) + float(z0(fx.get("speed"))), "turns": float(t["tn"]) + float(z0(fx.get("turns"))), "ev": float(t["ev"]) + float(z0(fx.get("ev"))),
		"aim": z0(fx.get("aim")), "crit": z0(fx.get("crit")), "dmg": 1.0 + 0.15 * (float(mk) - 1.0) + float(z0(fx.get("dmgPct"))) + 0.06 * tr, "fx": fx,
		"hangar": (float(t["hangar"]) + float(z0(fx.get("hangar"))) + float(z0(fx.get("hive")))) if jt(t.get("hangar")) else z0(fx.get("hive")),
		"hullRegen": float(z0(fx.get("hullRegen"))) + JSM.jsround(float(z0(fx.get("hullRegenPct"))) * maxHp) + JSM.jsround(float(z0(t.get("regen"))) * mm),
		"weapons": nameWeapons(t.get("fac"), ws),
	}
func classTrack(cls) -> float: # core.js: shared refit level per class (RUN.classTrack)
	var v = g(g(RUN, "classTrack"), cls) if cls != null else null
	return float(v) if jt(v) else 0.0
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
	var k = (int(q) + 512) * 1024 + int(r) + 512
	var c = _ob.get(k)
	if c == null:
		c = _onBoard_raw(q, r); _ob[k] = c
	return c
func _onBoard_raw(q, r) -> bool:
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
func terr(q, r):
	if _evc:
		var k = (int(q) + 512) * 1024 + int(r) + 512
		if _tc.has(k): return _tc[k]
		var v = B["terrain"].get(hkey(q, r)); _tc[k] = v; return v
	return B["terrain"].get(hkey(q, r))
func _cpOf(id) -> float: return float(HULLS[id]["cp"]) if jt(HULLS[id].get("cp")) else 1.0
func _cmpCheap(a, b) -> float:
	var d = _cpOf(a) - _cpOf(b)
	return d if d != 0.0 else float(HULLS[a]["hp"]) - float(HULLS[b]["hp"])
func rollBattleEvent(cfg, force = null): # campaign3d.js rolls this after startBattle (campaign battles only)
	if cfg == null or cfg.get("kind") == "boss": return null
	if not jt(force) and rnd() > 0.45: return null
	return {"k": force if (jt(force) and BEVENTS.has(force)) else pick(BEVENTS.keys()), "warnR": 2, "r": ri(3, 4)}
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
	var E = BEVENTS[e["k"]]
	if B["round"] >= e["warnR"] and not jt(e.get("warned")):
		e["warned"] = true; logm(JSM.rep1(String(E["warn"]), "{r}", ns(e["r"])), "x")
	if B["round"] < e["r"]: return
	e["done"] = true
	if e["k"] == "reinf_enemy" or e["k"] == "reinf_ally":
		var side = "enemy" if e["k"] == "reinf_enemy" else "player"; var h = edgeHex(side)
		if h == null:
			logm("The reinforcements could not find a clear lane and turn back.", "x"); return
		var fac = B["cfg"]["fac"] if side == "enemy" else (RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn")
		var s = B["sector"] if jt(B.get("sector")) else 1
		var u = makeUnit(side, cheapHull(fac), {"scale": (1.0 + 0.12 * (s - 1)) if side == "enemy" else 1, "dmg": (1.0 + 0.08 * (s - 1)) if side == "enemy" else 1, "fac": fac})
		u["q"] = h.q; u["r"] = h.r; u["facing"] = 0 if side == "player" else 3; u["reinf"] = true
		if side == "player": u["name"] = "Garrison " + String(u["name"])
		B["units"].append(u)
		if jt(B.get("cp0")): B["cp0"][side] = B["cp0"][side] + (u["t"]["cp"] if jt(u["t"].get("cp")) else 1)
	logm(String(E["go"]), "p" if e["k"] == "reinf_ally" else "e")
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
	CUT = null; var VOID = {}; _ob.clear()
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
	_ob.clear()
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
		u["hp"] = u["hp"] - WELL_DMG; emit({"t": "tick", "unit": u["id"], "kind": "tidal", "hull": WELL_DMG}); flt(u, "Tidal stress −" + ns(WELL_DMG), "#c79bff")
		if u["hp"] <= 0:
			u["hp"] = 0; logm(String(u["name"]) + " is torn apart by the dead star's gravity.", pe(u)); u["killCause"] = "tidal"; queueDeath(u, dq); return "dead"
	elif d <= WELL_PULL:
		var occ = occMap(); var best: Variant = null
		for dd in DIRS:
			var n = {"q": u.q + dd[0], "r": u.r + dd[1]}
			if hdist(n, W) != d - 1 or not onBoard(n.q, n.r) or blocks(terr(n.q, n.r)) or occ.has(hkey(n.q, n.r)): continue
			best = n; break
		if best != null:
			emit({"t": "pulled", "unit": u["id"], "from": {"q": u["q"], "r": u["r"]}, "to": {"q": best.q, "r": best.r}}); flt(u, "Dragged by gravity", "#c79bff")
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
	_runfx = null
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
		if not elite and heatOn("h_elite"): elite = ei == (1 if (jt(HULLS[eList[0]["tpl"]].get("boss")) and eList.size() > 1) else 0)
		if not elite and cfg.get("mod") == "veteran":
			var pr = []
			for i in range(eList.size()): pr.append([i, HULLS[eList[i]["tpl"]]["cp"] if jt(HULLS[eList[i]["tpl"]].get("cp")) else 1])
			JSM.ssort(pr, func(x, y): return y[1] - x[1])
			elite = ei == pr[0][0]
		B["units"].append(makeUnit("enemy", e["tpl"], {"scale": scale, "dmg": dmg, "elite": elite, "fac": cfg["fac"]}))
	if heatOn("h_undying"):
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u.get("isSq")) and not jt(u["t"].get("boss")): u["reanimate"] = true
	var nCar0 = 0
	for sh in RUN["fleet"]:
		if sh["hp"] > 0 and HULLS.has(sh["tpl"]) and jt(HULLS[sh["tpl"]].get("hangar")): nCar0 += 1
	var adm = ADMIRALS.get(RUN["admiral"])
	var carDoc: bool = (adm != null and jt(adm.get("cmd")) and adm["cmd"]["id"] == "scramble") or RUN.get("aspect") == "hive"
	var nCar = nCar0 + (1 if carDoc and nCar0 >= 1 else 0)
	if nCar >= 2 and not jt(cfg.get("enemies")):
		var pd = "spores" if cfg["fac"] == "chorus" else "flak"; var cand = []
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u["t"].get("boss")) and not jt(u.get("isSq")) and not _has_flak(u): cand.append(u)
		JSM.ssort(cand, func(x, y): return (y["t"]["cp"] if jt(y["t"].get("cp")) else 1) - (x["t"]["cp"] if jt(x["t"].get("cp")) else 1))
		var n = min(cand.size(), cand.size() if nCar >= 3 else int(ceil(cand.size() / 2.0)))
		for i in range(n):
			var u = cand[i]; u["weapons"].append(mkWeapon(pd, "T", u["fx"] if jt(u.get("fx")) else {})); u["pdRefit"] = true
		if n != 0: B["adapt"] = n
		if FACTIONS.has(cfg["fac"]) and jt(FACTIONS[cfg["fac"]].get("sq")): B["adaptWings"] = 2 if nCar >= 3 else 1
	if enc == "intercept":
		var nT = 3 if eList.size() >= 3 else 2; var ros = []
		for id in FACTIONS[cfg["fac"]]["roster"]:
			if HULLS.has(id) and not jt(HULLS[id].get("boss")) and HULLS[id].get("ab") != "launch": ros.append(id)
		JSM.ssort(ros, func(a, b):
			var d = (HULLS[a]["cp"] if jt(HULLS[a].get("cp")) else 1) - (HULLS[b]["cp"] if jt(HULLS[b].get("cp")) else 1)
			return d if d != 0 else HULLS[a]["hp"] - HULLS[b]["hp"])
		for i in range(nT):
			var u = makeUnit("enemy", ros[0] if ros.size() > 0 else FACTIONS[cfg["fac"]]["roster"][0], {"scale": sc * 1.3, "dmg": dm, "fac": cfg["fac"]})
			u["transport"] = true; u["weapons"] = []; u["ab"] = null; u["speed"] = min(u["speed"], 3); u["hp"] = JSM.jsround(u["maxHp"] * 1.5); u["maxHp"] = u["hp"]
			u["name"] = "Transport " + ["Aurum", "Bastion", "Cinder"][i]; B["units"].append(u)
	if enc == "break":
		var bb0 = boardBounds(); var mr = floori((bb0.r0 + bb0.r1) / 2.0)
		var pl0 = []
		for u in B["units"]:
			if u["side"] == "player": pl0.append(u)
		deploy(pl0, "player", func(h): return h.c >= 8 + CX and h.c <= 10 + CX and absf(h.r - mr) <= 4)
		var es = []
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u.get("isSq")): es.append(u)
		JSM.ssort(es, func(a, b): return b["size"] - a["size"])
		var back = []; var front = []
		for i in range(es.size()):
			if i % 3 == 2: back.append(es[i])
		for u in es:
			if not JSM.has_same(back, u): front.append(u)
		deploy(front, "enemy", func(h): return h.c >= 16 + CX and h.c <= 20 + CX and absf(h.r - mr) <= 6)
		if back.size() > 0: deploy(back, "enemy", func(h): return h.c >= bb0.c0 and h.c <= bb0.c0 + 3 and absf(h.r - mr) <= 5)
	elif enc == "hunt":
		var bb0 = boardBounds(); var mr = floori((bb0.r0 + bb0.r1) / 2.0); var es = []
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u.get("isSq")) and not jt(u.get("transport")): es.append(u)
		JSM.ssort(es, func(a, c):
			var d = (c["t"]["cp"] if jt(c["t"].get("cp")) else 1) - (a["t"]["cp"] if jt(a["t"].get("cp")) else 1)
			return d if d != 0 else c["maxHp"] - a["maxHp"])
		var pl0 = []
		for u in B["units"]:
			if u["side"] == "player": pl0.append(u)
		deploy(pl0, "player", func(h): return h.c >= 5 + CX and h.c <= 8 + CX and absf(h.r - mr) <= 5)
		deploy(es.slice(0, 1), "enemy", func(h): return h.c >= 12 + CX and h.c <= 14 + CX and absf(h.r - mr) <= 3)
		if es.size() > 1: deploy(es.slice(1), "enemy")
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
	if enc == "intercept":
		var bb = boardBounds(); var tr = []
		for u in B["units"]:
			if jt(u.get("transport")): tr.append(u)
		deploy(tr, "enemy", func(h): return h.r <= bb.r0 + 1 and h.c >= 13 + CX and h.c <= 18 + CX)
	clearSpawns()
	deployWings()
	B["cp0"] = {"player": sideCP("player"), "enemy": sideCP("enemy")}
	B["usage"] = {"fire": {}, "aim": 0, "ab": {}, "ord": {}, "cmd": 0, "moves": 0, "cant": {}}
	setupObjective(cfg.get("obj"))
	setupFactionRules()
	if jt(cfg.get("nemesis")): applyNemesis(cfg["nemesis"])
	if jt(cfg.get("verb")): applyVerb(cfg["verb"])
	if jt(B.get("adapt")) or jt(B.get("adaptWings")):
		var ad = B.get("adapt"); var aw = B.get("adaptWings")
		logm("Scouts report your carriers. The enemy " + (("bolted extra point defense onto " + (ns(ad) + " ships" if ad > 1 else "one ship")) if jt(ad) else "") + (" and " if (jt(ad) and jt(aw)) else "") + (("launched " + ("two fighter wings" if aw > 1 else "a fighter wing") + " to hunt your craft") if jt(aw) else "") + ".", "ember")
	startSideTurn("player")
	for u in alive("enemy"): u["intercepts"] = 2 if _has_flak(u) else 0
	var F = FACTIONS[cfg["fac"]]
	logm("Contact: " + String(F["n"]) + ". " + ns(eList.size()) + " ship" + ("s" if eList.size() > 1 else "") + " on the auspex.", "s")
	if jt(B.get("well")): logm("A dead star warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.", "ember")
	if cfg.get("kind") == "elite": logm("Elite captains command this fleet.", "e")
	if cfg.get("kind") == "boss": logm(String(HULLS[F["boss"]]["n"]) + " is here. Everything else is escort.", "e")
func _has_flak(u) -> bool:
	for w in u["weapons"]:
		if w["k"] == "flak": return true
	return false
func effArch(arch, fac):
	if arch == "carrier":
		var F = FACTIONS.get(fac); var any = false
		if F != null:
			for id in F["roster"]:
				if HULLS.has(id) and HULLS[id].get("ab") == "launch": any = true
		if not any: return "heavy"
	return arch if jt(arch) else null
func genEnemyFleet(fac, s, col, kind, arch, mod) -> Array:
	arch = effArch(arch, fac)
	var F = FACTIONS[fac]; s = int(s)
	var budget = ([0.0, 4.2, 9.5, 14.0][s] + col * (0.9 if s == 1 else (1.0 if s == 2 else 1.1))) * RAMP.grow[s]
	if kind == "elite": budget *= 1.05
	var list = []
	if kind == "boss":
		list.append({"tpl": F["boss"]}); budget *= RAMP.boss[s]
	if RUN != null and RUN.get("fleet") != null: budget *= max(RAMP.pwMin, min(RAMP.pwMax, JSM.pow(max(0.5, fleetPower()) / RAMP.refP[s], RAMP.pw)))
	if AI_LEVEL == "standard": budget *= RAMP.std
	if heatOn("h_hunted"): budget *= 1.15
	if mod == "bounty": budget *= 1.1
	var roster = []
	for id in F["roster"]: roster.append({"id": id, "cp": HULLS[id]["cp"], "car": HULLS[id].get("ab") == "launch"})
	if arch == "swarm":
		var cps = []
		for x in roster: cps.append(x.cp)
		var mn = JSM.amin(cps); var light = []
		for x in roster:
			if x.cp <= mn + 1 and not x.car: light.append(x)
		if light.size() > 0: roster = light
	if arch == "heavy":
		var any3 = false
		for y in roster:
			if y.cp >= 3 and not y.car: any3 = true
		var big = []
		for x in roster:
			if x.cp >= 2 and (not x.car or not any3): big.append(x)
		var bcp = []
		for x in big: bcp.append(x.cp)
		if big.size() > 0 and budget >= JSM.amin(bcp):
			var tops = []
			for x in big:
				if x.cp <= budget + 0.3: tops.append(x)
			JSM.ssort(tops, func(a, b): return b.cp - a.cp)
			if tops.size() > 0:
				list.append({"tpl": tops[0].id}); budget -= tops[0].cp
			var nr = big.duplicate()
			for x in roster:
				if x.cp < 2 and not x.car:
					nr.append(x); break
			roster = nr
	if arch == "carrier" and kind != "boss":
		var crs = []
		for x in roster:
			if x.car and x.cp <= budget + 0.3: crs.append(x)
		JSM.ssort(crs, func(a, b): return b.cp - a.cp)
		if crs.size() > 0:
			list.append({"tpl": crs[0].id}); budget -= crs[0].cp
			var nr = []
			for x in roster:
				if not x.car: nr.append(x)
			roster = nr
	var g = 0
	var hasFleet: bool = RUN != null and RUN.get("fleet") != null
	var nlive = 0
	if hasFleet:
		for sh in RUN["fleet"]:
			if sh["hp"] > 0: nlive += 1
	var ceil_ = RAMP.ceil[s] - (min(7, nlive) if hasFleet else 4)
	while budget >= 1 and list.size() < max(4, ceil_):
		g += 1
		if g > 80: break
		var opts = []
		for x in roster:
			if x.cp <= budget + 0.3: opts.append(x)
		if opts.size() == 0: break
		var wts = []
		for x in opts:
			if arch == "heavy": wts.append(JSM.pow(x.cp, 1.6))
			else: wts.append((1.1 if x.cp == 1 else min(2.0, budget / (x.cp * 2.0)) + 0.35) * (RAMP.light[s] if (x.cp <= 2 and arch != "swarm") else 1.0))
		var tot = 0.0
		for w in wts: tot += w
		var r = rnd() * tot; var ch = opts[0]
		for i in range(opts.size()):
			r -= wts[i]
			if r <= 0:
				ch = opts[i]; break
		list.append({"tpl": ch.id}); budget -= ch.cp
	return list

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
		e["dead"] = true; e["fled"] = true; emit({"t": "fled", "unit": e["id"]})
	boss["regen"] = 0; boss["hullRegen"] = 0; boss["reanimate"] = false
	var nsh = []
	for v in boss["sh"]: nsh.append(JSM.jsround(v * 0.5))
	boss["sh"] = nsh; boss["burning"] = true
	logm(String(boss["name"]) + " is burning. " + ("Its escorts break off and flee. " if esc.size() > 0 else "") + "Its shields falter and it can no longer repair itself.", "s")
func startSideTurn(side) -> int:
	var deaths = []
	if side == "player" and B["round"] > 1:
		eventTick(); objectiveTick(deaths)
	if side == "enemy":
		aiRefreshFocus(); bossCmdTick()
	escortsBreak(); nemBreak()
	if side == "enemy":
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u.get("dead")) and not jt(u.get("isSq")): aiStance(u)
	gainResolve(side, 1); var burned = false
	var risen = legionTurn(side)
	for u in B["units"]:
		if jt(u.get("dead")) or u["side"] != side: continue
		u["braced"] = false; u["coverBy"] = null; u["postFire"] = false; u["postMp"] = 0; u["pivotUsed"] = false; u["lockOn"] = false; u["focus"] = false; u["fullAhead"] = false; u["noTurn"] = false; u["evBuff"] = 0; u["order"] = null; u["ramBoost"] = 0
		u["mp"] = max(1, u["speed"] - u["st"]["engine"]); u["turnsLeft"] = u["turns"]
		for w in u["weapons"]:
			w["fired"] = false
			if gt(w.get("cdLeft"), 0): w["cdLeft"] = w["cdLeft"] - 1
			if gt(w.get("off"), 0): w["off"] = w["off"] - 1
		if u["abCd"] > 0: u["abCd"] = u["abCd"] - 1
		if u["st"]["shieldOff"] > 0: u["st"]["shieldOff"] = u["st"]["shieldOff"] - 1
		elif u["shMax"] > 0:
			var rg = u["regen"] * (B["condRegen"] if B != null and jt(B.get("condRegen")) else 1)
			for i in range(4):
				if not (u.get("regenLock") != null and jt(u["regenLock"][i])): u["sh"][i] = min(u["shMax"], u["sh"][i] + rg)
		ithChargeTurn(u); u["regenLock"] = null
		if jt(u.get("hullRegen")) and u["hp"] < u["maxHp"] and not jt(u.get("pyre")): u["hp"] = min(u["maxHp"], u["hp"] + u["hullRegen"])
		if z0(u["st"].get("acid")) > 0 and not jt(u.get("isSq")):
			u["st"]["acid"] = u["st"]["acid"] - 1; u["hp"] = u["hp"] - 4; emit({"t": "tick", "unit": u["id"], "kind": "acid", "hull": 4}); flt(u, "Acid −4", "#c8e04a", -12)
			if u["hp"] <= 0:
				u["hp"] = 0; burned = true; logm(String(u["name"]) + " dissolves.", pe(u)); u["killCause"] = "melt"; queueDeath(u, deaths)
		if u["st"]["fire"] > 0 and not jt(u.get("dead")):
			var fd = u["st"]["fireDmg"] if jt(u["st"].get("fireDmg")) else 6
			u["st"]["fire"] = u["st"]["fire"] - 1; u["hp"] = u["hp"] - fd; emit({"t": "tick", "unit": u["id"], "kind": "fire", "hull": fd}); flt(u, "Fire −" + ns(fd), "#f08a4b")
			if u["hp"] <= 0:
				u["hp"] = 0; burned = true; logm(String(u["name"]) + " burns out.", pe(u)); u["killCause"] = "dark"; queueDeath(u, deaths)
			if not jt(u["st"]["fire"]): u["st"]["fireDmg"] = 0
		u["hexMoved"] = 0
		if jt(u.get("fx")) and jt(u["fx"].get("stormRegen")) and u["shMax"] > 0 and not (z0(u["st"].get("shieldOff")) > 0):
			for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + JSM.jsround(u["shMax"] * u["fx"]["stormRegen"]))
		u["intercepts"] = 2 if _has_flak(u) else 0
		u["boarded"] = false; u["rammed"] = false; u["emerg"] = false; u["repel"] = false
		if terr(u["q"], u["r"]) == "storm" and not jt(u.get("isSq")) and u["shMax"] > 0:
			for i in range(4): u["sh"][i] = max(0, u["sh"][i] - 10)
			emit({"t": "tick", "unit": u["id"], "kind": "storm", "hull": 0}); flt(u, "Ion storm", "#9fb8ff", -24)
		if jt(u.get("crewMax")) and u["crew"] <= 0:
			u["mp"] = 0; u["turnsLeft"] = 0
			for w in u["weapons"]: w["fired"] = true
		if jt(B.get("well")) and wellTick(u, deaths) == "dead": burned = true
	var ev = B.get("event")
	if jt(ev) and ev["k"] == "flare" and B["round"] == ev["r"] and jt(ev.get("done")):
		for u in B["units"]:
			if not jt(u.get("dead")) and u["side"] == side and u["shMax"] > 0: u["sh"] = [0, 0, 0, 0]
	for u in risen:
		for w in u["weapons"]: w["fired"] = true
	if burned: checkEnd()
	hook("tick " + String(side))
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
func moveRules(u) -> Dictionary: # the same values as the game's fresh object; callers only read it
	var k = "sq" if (u != null and jt(u.get("isSq"))) else (String(u["fac"]) if u != null else "")
	var c = _mr.get(k)
	if c == null:
		c = _moveRules_raw(u); _mr[k] = c
	return c
func _moveRules_raw(u) -> Dictionary:
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
	var occ = occMap(); var R = moveRules(u); var MP = postFireMp(u); var noOver = jt(u.get("postFire"))
	var start = {"q": u["q"], "r": u["r"], "f": u["facing"], "t": 0, "cost": 0, "path": []}
	var seen = {_sk(start): 0}; var queue = [start]; var qi = 0
	var pivotFree: bool = jt(R.get("pivot")) and not jt(u.get("pivotUsed"))
	while qi < queue.size():
		var s = queue[qi]; qi += 1
		if seen[_sk(s)] < s.cost: continue
		states.append(s)
		if s.cost >= MP: continue
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
				var c = min(c0, MP) if (kind != null and s.cost == 0) else c0
				var over = 0; var tt = terr(nq, nr)
				if blocks(tt):
					if tt != "rock" and tt != "hulk": continue
					over = 1
				var o = occ.get(hkey(nq, nr))
				if o != null and o["side"] != u["side"]: over = over if over != 0 else -1
				if over != 0:
					if noOver: continue
					c += R["over"]
				if s.cost + c > MP: continue
				var st = {"q": nq, "r": nr, "f": s.f}
				if kind != null: st[kind] = 1
				if kind == "slip": st["side"] = 1 if df == (sf + 1) % 6 else -1
				if over != 0: st["over"] = over
				var pth: Array = s.path.duplicate(); pth.append(st)
				nexts.append({"q": nq, "r": nr, "f": s.f, "t": s.t, "cost": s.cost + c, "path": pth, "slips": z0(s.get("slips")) + (1 if kind == "slip" else 0), "revs": z0(s.get("revs")) + (1 if kind == "rev" else 0), "overs": z0(s.get("overs")) + (1 if over != 0 else 0)})
		if not jt(u.get("isSq")) and not jt(u.get("noTurn")) and s.t < u["turnsLeft"]:
			var tc = 0 if (pivotFree and s.t == 0) else 1
			if s.cost + tc <= MP or tc == 0:
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
	u["mp"] = max(0, u["mp"] - state.cost)
	if jt(u.get("postFire")): u["postMp"] = max(0, z0(u.get("postMp")) - state.cost)
	u["turnsLeft"] = u["turnsLeft"] - state.t
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
	emit({"t": "move", "unit": u["id"], "path": state.path.duplicate(true), "late_fire": opts != null and opts.get("onLate") != null}); hook("move", u)
	if opts != null and opts.get("onLate") != null:
		if live.call():
			_commit(u, state, ctx); opts["onLate"].call()
	if B != null: B["prog"] = z0(B.get("prog")) + 1
	if not live.call(): return
	if ctx.committed:
		objAfterMove(u); return
	_commit(u, state, ctx)
	objAfterMove(u)

func freePivot(u) -> bool: return jt(moveRules(u).get("pivot")) and not jt(u.get("pivotUsed"))
func canRotate(u) -> bool: return not jt(u.get("dead")) and not jt(u.get("isSq")) and not jt(u.get("noTurn")) and u["turnsLeft"] > 0 and (u["mp"] > 0 or freePivot(u)) and not jt(u.get("braced"))
func rotateUnit(u, dir) -> void:
	if not canRotate(u) or not inThisBattle(u): return
	var live = liveFrom(u); var f = (int(u["facing"]) + int(dir) + 6) % 6
	if freePivot(u): u["pivotUsed"] = true
	else: u["mp"] = u["mp"] - 1
	u["turnsLeft"] = u["turnsLeft"] - 1; u["moved"] = true
	emit({"t": "move", "unit": u["id"], "path": [{"q": int(u["q"]), "r": int(u["r"]), "f": f, "rot": true}], "late_fire": false}); hook("rotate", u)
	if not live.call(): return
	u["facing"] = f
# ======================= B3 faction identity, travelling torpedoes, B4 Nemesis, verbs, wing doctrines, v54 doctrines =======================
func canFade(u) -> bool: return u["fac"] == "ithar" or jt(g(u.get("fx"), "fade"))
func postFireMp(u): return min(u["mp"], z0(u.get("postMp"))) if jt(u.get("postFire")) else u["mp"]
func fstat(fac, k, n = null) -> void: # telemetry counters in B.fstat (never read by rules, but part of the battle state)
	if B == null or not jt(fac): return
	if B.get("fstat") == null: B["fstat"] = {}
	if B["fstat"].get(fac) == null: B["fstat"][fac] = {}
	var F = B["fstat"][fac]; F[k] = z0(F.get(k)) + (1 if n == null else n)
func setupFactionRules() -> void:
	B["syncMark"] = {"player": {}, "enemy": {}}; B["syncLost"] = {"player": false, "enemy": false}
	B["legion"] = {"player": {"max": 0, "used": 0}, "enemy": {"max": 0, "used": 0}}; B["torps"] = []
	for side in ["player", "enemy"]:
		var heg = []
		for u in B["units"]:
			if u["side"] == side and not jt(u.get("isSq")) and not jt(u.get("transport")) and u["fac"] == "hegemony": heg.append(u)
		if heg.size() > 0:
			var a = null
			for u in heg:
				if jt(u.get("pflag")): a = u; break
			if a == null:
				for u in heg:
					if jt(u.get("boss")): a = u; break
			if a == null:
				for u in heg:
					if jt(u.get("flagship")): a = u; break
			if a == null:
				var hs = heg.duplicate()
				JSM.ssort(hs, func(x, y): return _byCpHp(x, y))
				a = hs[0]
			a["anchor"] = true
		var dl = 0
		for u in B["units"]:
			if u["side"] == side and not jt(u.get("isSq")) and u["fac"] == "deathless" and jt(u.get("t")) and jt(u["t"].get("reanimate")): dl += 1
		B["legion"][side]["max"] = 2 if dl >= 6 else (1 if dl >= 1 else 0)
func syncAnchor(side):
	if B == null or B.get("syncMark") == null or (B.get("syncLost") != null and jt(B["syncLost"].get(side))): return null
	for u in B["units"]:
		if jt(u.get("anchor")) and u["side"] == side and not jt(u.get("dead")): return u
	return null
func syncR(side): return B["syncR"][side] if (B != null and B.get("syncR") != null and jt(B["syncR"].get(side))) else TB.SYNC_R
func syncDmg(side): return B["syncDmg"][side] if (B != null and B.get("syncDmg") != null and jt(B["syncDmg"].get(side))) else TB.SYNC_DMG
func inSync(u) -> bool:
	if u == null or jt(u.get("isSq")) or u.get("fac") != "hegemony" or jt(u.get("dead")): return false
	var a = syncAnchor(u["side"])
	return a != null and hdist(u, a) <= syncR(u["side"])
func syncOn(u, t) -> bool:
	if not inSync(u) or t == null: return false
	var m = B["syncMark"][u["side"]].get(t["id"])
	if m == null or m["r"] != B["round"]: return false
	for id in m["ids"]:
		if id != u["id"]: return true
	return false
func syncMarkShot(u, t) -> void:
	if not inSync(u) or t == null: return
	var Mk = B["syncMark"][u["side"]]; var m = Mk.get(t["id"])
	if m == null or m["r"] != B["round"]:
		m = {"r": B["round"], "ids": []}; Mk[t["id"]] = m
	if not m["ids"].has(u["id"]): m["ids"].append(u["id"])
func syncLose(t) -> void:
	if B == null or t == null or not jt(t.get("anchor")) or B.get("syncLost") == null or jt(B["syncLost"].get(t["side"])): return
	B["syncLost"][t["side"]] = true; t["anchor"] = false
	for u in B["units"]:
		if u["side"] == t["side"] and not jt(u.get("dead")) and not jt(u.get("isSq")) and u["fac"] == "hegemony":
			logm(String(t["name"]) + " is lost: the " + ("fleet" if t["side"] == "player" else "enemy line") + " loses its synchronized fire.", pe(t)); break
func syncPull(u, v) -> float:
	if u == null or jt(u.get("isSq")) or u.get("fac") != "hegemony" or jt(u.get("anchor")): return 0.0
	var a = syncAnchor(u["side"])
	if a == null: return 0.0
	return max(0, hdist(v, a) - syncR(u["side"]))
func ithChargeTurn(u) -> void:
	if u["fac"] != "ithar" or not (u["shMax"] > 0) or jt(u.get("isSq")): return
	var hit = u["shHit"] if u.get("shHit") != null else [0, 0, 0, 0]
	if not (z0(u["st"].get("shieldOff")) > 0):
		var gg = 0; var rg = JSM.jsround(u["regen"] * (B["condRegen"] if (B != null and jt(B.get("condRegen"))) else 1))
		for i in range(4):
			if u.get("regenLock") != null and jt(u["regenLock"][i]): continue
			var add = (u["shMax"] - u["sh"][i]) if not jt(hit[i]) else min(rg, u["shMax"] - u["sh"][i])
			if add > 0:
				gg += add; u["sh"][i] = u["sh"][i] + add
		if gg > 0: fstat("ithar", "charge", gg)
	u["shHit"] = [0, 0, 0, 0]
func chorusFeed(t, by) -> void:
	if B == null or t == null or jt(t.get("isSq")): return
	var side = by["side"] if by != null else ("enemy" if t["side"] == "player" else "player")
	if side == t["side"]: return
	var killer = null
	if by != null:
		if jt(by.get("isSq")):
			for x in B["units"]:
				if x["id"] == by.get("parent"): killer = x; break
		else: killer = by
	for u in B["units"]:
		if jt(u.get("dead")) or u["side"] != side or jt(u.get("isSq")) or u["fac"] != "chorus" or jt(u.get("pyre")) or u["hp"] >= u["maxHp"]: continue
		var share = TB.FEED_KILL if (killer != null and is_same(u, killer)) else (TB.FEED_NEAR if hdist(u, t) <= TB.FEED_R else 0.0)
		if not jt(share): continue
		chorusRegrow(u, JSM.jsround(u["maxHp"] * share), "Feeds")
func chorusRegrow(u, amt, label) -> float:
	if u == null or jt(u.get("dead")) or jt(u.get("pyre")) or amt <= 0: return 0.0
	if u.get("fedR") != B["round"]:
		u["fedR"] = B["round"]; u["fed"] = 0
	var room = max(0, JSM.jsround(u["maxHp"] * TB.FEED_CAP) - u["fed"]); var h = min(room, min(u["maxHp"] - u["hp"], amt))
	if h <= 0: return 0.0
	u["hp"] = u["hp"] + h; u["fed"] = u["fed"] + h; fstat("chorus", "feed", h)
	flt(u, (label if jt(label) else "Feeds") + " +" + ns(h), "#d6d24a", -26)
	return h
func chorusBiteEst(u, t, hull) -> float:
	if u != null and t != null and u["fac"] == "chorus" and not jt(u.get("isSq")) and hdist(u, t) <= 2: return JSM.jsround(hull * TB.CHORUS_BITE)
	return 0.0
func legionCan(t) -> bool:
	if B == null or B.get("legion") == null or jt(t.get("isSq")) or t.get("fac") != "deathless" or not jt(t.get("t")) or not jt(t["t"].get("reanimate")) or jt(t.get("reanimated")) or jt(t.get("pyre")) or jt(t.get("boss")) or jt(t.get("pflag")) or jt(t.get("flagship")) or jt(t.get("transport")): return false
	var L = B["legion"].get(t["side"])
	return L != null and L["used"] < L["max"]
func legionRiseHex(u):
	var occ = occMap()
	var ok = func(h): return onBoard(h.q, h.r) and not blocks(terr(h.q, h.r)) and not occ.has(hkey(h.q, h.r))
	if ok.call({"q": u["q"], "r": u["r"]}): return {"q": u["q"], "r": u["r"]}
	var best = null; var bd = 9
	for h in boardHexes():
		var d = hdist(h, u)
		if d <= 2 and d < bd and ok.call(h):
			bd = d; best = h
	return best
func legionRise(u, quiet = false) -> bool:
	var h = legionRiseHex(u)
	if h == null:
		u["riseAt"] = null
		if not quiet: logm(String(u["name"]) + " cannot find room to reassemble and stays dark.", "x")
		return false
	u["q"] = h.q; u["r"] = h.r; u["dead"] = false; u["riseAt"] = null; u["hp"] = max(1, JSM.jsround(u["maxHp"] * TB.LEGION_HP)); u["st"] = {"fire": 0, "shieldOff": 0, "engine": 0}; u["shredded"] = 0
	if jt(u.get("sec")):
		for k in u["sec"].keys():
			repairSection(u, k, TB.LEGION_HP); u["sec"][k]["hp"] = max(1, JSM.jsround(u["sec"][k]["max"] * TB.LEGION_HP))
	u["risen"] = B["round"]; fstat("deathless", "revive")
	emit({"t": "risen", "unit": u["id"], "q": int(u["q"]), "r": int(u["r"])})
	if not quiet:
		logm(String(u["name"]) + " reassembles from its wreck with " + ns(u["hp"]) + " hull. It cannot fire this round.", pp(u)); flt(u, "Reassembled", "#7dff9b", -30)
	return true
func legionTurn(side) -> Array:
	if B == null or jt(B.get("over")): return []
	var out = []
	for u in B["units"].duplicate():
		if jt(u.get("dead")) and u["side"] == side and u.get("riseAt") != null and B["round"] >= u["riseAt"] and not jt(u.get("fled")) and legionRise(u): out.append(u)
	return out
func torpTravels(w, u) -> bool: return w != null and w.get("k") == "torp" and not (u != null and jt(u.get("isSq")))
func torpGhost(u, sure) -> Dictionary:
	var gh = u.duplicate(false); gh["sureUsed"] = sure; gh["ghost"] = true; return gh
func torpThreat(u, v) -> float:
	if B == null or B.get("torps") == null or B["torps"].size() == 0 or jt(u.get("isSq")): return 0.0
	var tot = 0.0
	for sv in B["torps"]:
		if sv["side"] == u["side"]: continue
		var d = hdist(v, sv["aim"])
		if sv["tid"] == u["id"]:
			if d <= 2: tot += sv["w"]["dmg"] * sv["w"]["shots"] * [0.62, 0.52, 0.38][int(d)]
		elif d == 0: tot += sv["w"]["dmg"] * sv["w"]["shots"] * 0.5
	return tot
func nemWeak(k) -> bool: return B != null and B.get("nem") != null and B["nem"].get("weak") != null and B["nem"]["weak"].has(k)
func applyNemesis(N) -> void:
	B["nem"] = N; var es = []
	for u in B["units"]:
		if u["side"] == "enemy" and not jt(u.get("isSq")) and not jt(u.get("transport")): es.append(u)
	if es.size() == 0: return
	var srt = es.duplicate(); JSM.ssort(srt, func(a, b): return _byCpHp(a, b)); var fl = srt[0]
	fl["nemFlag"] = true; fl["elite"] = true; fl["name"] = String(N["title"]) + " " + String(N["name"]); fl["dmg"] = fl["dmg"] * (1.0 + 0.1 * z0(N.get("scars")))
	if fl["fac"] == "hegemony":
		for u in es: u["anchor"] = false
		fl["anchor"] = true
	var adapt = N["adapt"] if N.get("adapt") != null else []
	for u in es:
		u["nem"] = true
		if nemWeak("board"):
			u["crewMax"] = max(4, JSM.jsround(u["crewMax"] * 0.7)); u["crew"] = min(u["crew"], u["crewMax"])
		if nemWeak("slow"): u["speed"] = max(1, u["speed"] - 1)
		for a in adapt:
			if a == "shields" and u["shMax"] > 0:
				u["shMax"] = JSM.jsround(u["shMax"] * 1.2); u["sh"] = [u["shMax"], u["shMax"], u["shMax"], u["shMax"]]
			if a == "armor": u["armor"] = min(0.6, u["armor"] + 0.1)
			if a == "evasion": u["ev"] = u["ev"] + 8
			if a == "aim": u["aim"] = u["aim"] + 8
	if adapt.has("pd"):
		var pd = "spores" if fl["fac"] == "chorus" else "flak"; var nf = []
		for u in es:
			if not _has_flak(u): nf.append(u)
		for u in nf.slice(0, 2):
			var w = mkWeapon(pd, "T", u["fx"] if jt(u.get("fx")) else {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0; u["weapons"].append(w)
	var an = []
	for a in adapt: an.append(String(TB.NEM_ADAPT[a]["n"]).to_lower())
	logm(String(fl["name"]) + " commands this fleet: your Nemesis." + ((" He has adapted: " + ", ".join(an) + ".") if adapt.size() > 0 else ""), "e")
func nemBreak() -> void:
	if B == null or B.get("nem") == null or jt(B.get("nemBroken")) or not nemWeak("anchor"): return
	var f = null
	for u in B["units"]:
		if jt(u.get("nemFlag")) and not jt(u.get("dead")) and u["side"] == "enemy": f = u; break
	if f == null or f["hp"] > f["maxHp"] * 0.6: return
	B["nemBroken"] = true; var esc = []
	for u in alive("enemy"):
		if not is_same(u, f) and not jt(u.get("isSq")) and not jt(u.get("transport")): esc.append(u)
	for e in esc:
		e["dead"] = true; e["fled"] = true; emit({"t": "fled", "unit": e["id"]})
	logm(String(f["name"]) + "'s flagship is burning. " + ("His escorts lose their nerve and flee." if esc.size() > 0 else ""), "s")
func ionVs(att, w, t) -> float: return ionOf(att, w) * (1.5 if (t != null and jt(t.get("nem")) and nemWeak("ion") and (jt(w.get("ion")) or w.get("k") == "lance")) else 1.0)
func applyVerb(id) -> void:
	var P = []
	for u in B["units"]:
		if u["side"] == "player" and not jt(u.get("isSq")): P.append(u)
	B["verb"] = id
	if id == "vigil":
		for u in P:
			var fx = u["fx"].duplicate(); fx["lineGuard"] = z0(u["fx"].get("lineGuard")) + 0.15; u["fx"] = fx
	if id == "drill":
		B["syncR"] = {"player": TB.SYNC_R + 1}; B["syncDmg"] = {"player": 0.2}
	if id == "attune":
		for u in P:
			if u["shMax"] > 0:
				u["shMax"] = JSM.jsround(u["shMax"] * 1.25); u["sh"] = [u["shMax"], u["shMax"], u["shMax"], u["shMax"]]
	if id == "waken" and B.get("legion") != null: B["legion"]["player"]["max"] = B["legion"]["player"]["max"] + 1
	for V in TB.FAC_VERBS.values():
		if V["id"] == id:
			var d = String(V["d"])
			if d.begins_with("Next battle, "): d = d.substr(13)
			logm(String(V["n"]) + ": " + d, "p"); break
func wingStance(sv) -> String:
	var p = sv
	if sv != null and jt(sv.get("isSq")):
		p = null
		for x in B["units"]:
			if x["id"] == sv.get("parent"): p = x; break
	return String(p["stance"]) if (p != null and jt(p.get("stance"))) else "strike"
func canStance(u) -> bool: return B != null and u != null and not jt(u.get("dead")) and not jt(u.get("isSq")) and (u.get("ab") == "launch" or jt(g(u.get("fx"), "hive"))) and u.get("stanceRound") != B["round"]
func setStance(u, st) -> bool:
	if not TB.WING_STANCES.has(st) or not canStance(u) or u.get("stance") == st: return false
	u["stance"] = st; u["stanceRound"] = B["round"]
	emit({"t": "stance", "unit": u["id"], "stance": st})
	logm(String(u["name"]) + "'s wings: " + String(TB.WING_STANCES[st]["n"]) + ".", pp(u)); return true
func aiStance(u) -> void:
	if not canStance(u): return
	var foe = "enemy" if u["side"] == "player" else "player"; var mineSq = 0; var foeSq = 0
	for x in alive(u["side"]):
		if jt(x.get("isSq")): mineSq += 1
	for x in alive(foe):
		if jt(x.get("isSq")): foeSq += 1
	var torps = false
	for sv in (B["torps"] if B.get("torps") != null else []):
		if sv["side"] == foe: torps = true
	var weak = false
	for x in alive(foe):
		if not jt(x.get("isSq")) and x["hp"] < x["maxHp"] * 0.5: weak = true
	var st = "screen" if (torps or foeSq > mineSq + 1) else ("hunt" if weak else "strike")
	if st != (String(u["stance"]) if jt(u.get("stance")) else "strike"): setStance(u, st)
func wingPerks(p) -> Array:
	var pk = g(g(g(p, "ship"), "wingVet"), "perks")
	return pk if pk != null else []
func screenTorps(t, shots: Array, res) -> void:
	var shot = 0
	for sv in alive(t["side"]):
		if not jt(sv.get("isSq")) or wingStance(sv) != "screen" or hdist(sv, t) > TB.WING_SCREEN_R: continue
		var p = null
		for x in B["units"]:
			if x["id"] == sv.get("parent"): p = x; break
		var ch = TB.WING_SCREEN_TORP + (0.2 if wingPerks(p).has("pickets") else 0.0)
		for i in range(shots.size()):
			if shots[i]:
				if rnd() < ch:
					shots[i] = false; shot += 1
				break
	if shot != 0:
		res["pd"] = z0(res.get("pd")) + shot; flt(t, ns(shot) + " torpedo" + ("es" if shot > 1 else "") + " shot down by wings", "#bfe3ff", 30)
func braceCover(u) -> Array:
	var wall = jt(g(u.get("fx"), "wallBrace"))
	if u["fac"] != "voidsworn" and not wall: return []
	var near = []
	for x in B["units"]:
		if not jt(x.get("dead")) and not is_same(x, u) and x["side"] == u["side"] and not jt(x.get("isSq")) and hdist(x, u) == 1 and (wall or x["facing"] == u["facing"]): near.append(x)
	if not wall:
		JSM.ssort(near, func(a, b): return float(a["hp"]) / a["maxHp"] - float(b["hp"]) / b["maxHp"])
		near = near.slice(0, 1)
	for x in near:
		x["coverBy"] = u["id"]; flt(x, "Covered", "#7fd6c8", -24)
	return near
func braceMul(t) -> float:
	if jt(t.get("braced")): return max(0.15, 1.0 - 0.4 - z0(g(t.get("fx"), "bracePlus")))
	if jt(t.get("coverBy")) and B != null:
		for c in B["units"]:
			if c["id"] == t["coverBy"]:
				if not jt(c.get("dead")) and jt(c.get("braced")): return max(0.15, 1.0 - 0.4 - z0(g(c.get("fx"), "bracePlus")))
				break
	return 1.0
func aiHurtW(u, prof) -> float:
	var f = float(u["hp"]) / max(1, u["maxHp"])
	if f < 0.3: u["aiHurt"] = true
	elif f > 0.45: u["aiHurt"] = false
	var k = 1.0 if jt(u.get("aiHurt")) else clamp_((0.6 - f) / 0.3, 0.0, 1.0); var x = k * k * (3.0 - 2.0 * k)
	return 0.32 + (0.6 * prof["hurt"] - 0.32) * x
func fadeMove(u) -> bool:
	if u == null or jt(u.get("dead")) or jt(u.get("isSq")) or not jt(u.get("postFire")) or postFireMp(u) < 1: return false
	var foes = alive("enemy" if u["side"] == "player" else "player")
	if foes.size() == 0: return false
	var here = evalThreat(u, foes) + torpThreat(u, u)
	if here < 5: return false
	var best = null; var bv = here
	eval_begin()
	for st in computeReach(u).states:
		if st.q == u["q"] and st.r == u["r"]: continue
		var v = stateView(u, st); var th = evalThreat(v, foes) + torpThreat(u, v)
		if th < bv:
			bv = th; best = st
	eval_end()
	if best == null or bv > here * 0.75: return false
	moveUnit(u, best); fstat(u["fac"], "fade"); return true
func rocketDefense(w, t, shots: Array, res) -> void:
	if not jt(w.get("rockets")) or jt(t.get("isSq")): return
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
	if shot != 0:
		res["pd"] = shot; flt(t, ns(shot) + " rocket" + ("s" if shot > 1 else "") + " shot down", "#bfe3ff", 30)
func launchTorp(u, w, t, opts, live, keep, b0) -> bool:
	B["torpSeq"] = z0(B.get("torpSeq")) + 1
	var S = {"id": B["torpSeq"], "side": u["side"], "by": u["id"], "fac": u["fac"], "w": w.duplicate(), "tid": t["id"], "aim": {"q": t["q"], "r": t["r"]}, "from": {"q": u["q"], "r": u["r"]}, "r": B["round"], "called": opts["called"] if (jt(opts.get("called")) and not jt(t.get("isSq"))) else null}
	fstat(u["fac"], "shots")
	if syncOn(u, t): fstat(u["fac"], "syncShots")
	S["base"] = dmgMult(u, w, t, false) * TB.TORP_WARHEAD; S["rearAdd"] = dmgMult(u, w, t, true) * TB.TORP_WARHEAD - S["base"]; S["ghost"] = torpGhost(u, keep[2])
	syncMarkShot(u, t); B["torps"].append(S); fstat(u["fac"], "torpLaunch"); B["prog"] = z0(B.get("prog")) + 1
	emit({"t": "torpedo", "unit": u["id"], "target": t["id"], "id": S["id"], "aim": {"q": int(t["q"]), "r": int(t["r"])}, "name": w.get("n")})
	logm(String(u["name"]) + " launches " + tv(w.get("n")) + " at " + String(t["name"]) + ". They strike its marked hex next turn.", pp(u)); flt(t, "Torpedo lane: impact next turn", "#ff9f3a", -44)
	return true
func torpImpact(S) -> void:
	var live = liveFrom(null); var w = S["w"]; var gh = S["ghost"]; gh["q"] = S["from"]["q"]; gh["r"] = S["from"]["r"]
	var real = null; var orig = null
	for x in B["units"]:
		if x["id"] == S["by"] and real == null: real = x
		if x["id"] == S["tid"] and orig == null: orig = x
	var t = null; var pen = 0
	if orig != null and not jt(orig.get("dead")) and orig["side"] != S["side"] and hdist(orig, S["aim"]) <= 2:
		t = orig; pen = TB.TORP_RING[int(hdist(orig, S["aim"]))]
	else:
		var lim = 0 if (orig != null and not jt(orig.get("dead"))) else 1; var fs = []
		for o in B["units"]:
			if not jt(o.get("dead")) and not jt(o.get("isSq")) and o["side"] != S["side"] and hdist(o, S["aim"]) <= lim: fs.append(o)
		JSM.ssort(fs, func(a, b):
			var dd = hdist(a, S["aim"]) - hdist(b, S["aim"])
			return dd if dd != 0 else (-1 if String(a["id"]) < String(b["id"]) else 1))
		if fs.size() > 0:
			t = fs[0]; pen = TB.TORP_STRAY
	if t == null and jt(g(gh.get("fx"), "spread")):
		var near = []
		for x in alive("enemy" if S["side"] == "player" else "player"):
			if not jt(x.get("isSq")) and hdist(x, S["aim"]) <= 1: near.append(x)
		if near.size() > 0:
			logm(tv(w.get("n")) + " from " + String(gh["name"]) + " burst in the lane, catching " + ns(near.size()) + " ship" + ("s" if near.size() > 1 else "") + ".", "p" if S["side"] == "player" else "e")
			for x in near:
				if jt(x.get("dead")): continue
				var r = applyHit(gh, w, x, S["base"] * gh["fx"]["spread"], shieldQuad(x, gh)); boonFx(x, "e_spread", "−" + ns(r.hull), -20)
				if x["hp"] <= 0:
					x["killCause"] = "big"; killUnit(x, real if real != null else gh)
	if t == null:
		fstat(S["fac"], "torpDodge" if (orig != null and not jt(orig.get("dead"))) else "torpGone")
		emit({"t": "torpedo_miss", "id": S["id"], "aim": {"q": int(S["aim"]["q"]), "r": int(S["aim"]["r"])}})
		logm(tv(w.get("n")) + " from " + String(gh["name"]) + " run wide: " + ((String(orig["name"]) + " slipped out of the lane") if (orig != null and not jt(orig.get("dead"))) else "nothing left in the lane") + ".", "x")
		return
	var quad = shieldQuad(t, gh); var shBefore = z0(t["sh"][quad]) if t.get("sh") != null else 0
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	var hc = clamp_(hitChance(gh, w, t) - pen + (15 if (jt(t.get("nem")) and nemWeak("torp")) else 0), 5, 95); var shots = []
	for i in range(int(w["shots"])): shots.append(rnd() * 100.0 < hc)
	rocketDefense(w, t, shots, res); screenTorps(t, shots, res)
	emit({"t": "fire", "unit": gh["id"], "weapon": -1, "weapon_id": w["id"], "kind": w["k"], "arc": w["arc"], "name": w.get("n"), "target": t["id"], "shots": shots.duplicate(), "pd": z0(res.get("pd")), "quad": quad, "torpedo": S["id"], "from": {"q": int(S["from"]["q"]), "r": int(S["from"]["r"])}}); hook("fire", gh)
	if not live.call() or jt(t.get("dead")): return
	var d0 = z0(gh.get("dealt")); var same = orig != null and is_same(t, orig)
	var per = (func(rear): return S["base"] + (S["rearAdd"] if rear else 0.0)) if same else null
	landVolley(gh, w, t, {"quad": quad, "shBefore": shBefore, "shots": shots, "called": S.get("called") if same else null, "res": res, "torp": true, "stray": not same, "per": per, "by": real if real != null else gh})
	if jt(res.hits): fstat(S["fac"], "torpHit")
	if real != null: real["dealt"] = z0(real.get("dealt")) + z0(gh.get("dealt")) - d0
func resolveTorps(side) -> void:
	if B == null or B.get("torps") == null or B["torps"].size() == 0: return
	var b0 = B; var due = []; var rest = []
	for sv in B["torps"]:
		if sv["side"] == side and sv["r"] < B["round"]: due.append(sv)
		else: rest.append(sv)
	if due.size() == 0: return
	B["torps"] = rest
	for S in due:
		if not is_same(B, b0) or jt(B.get("over")): return
		torpImpact(S); flush_deferred()
	if is_same(B, b0): checkEnd()
func turnStart(side) -> void: # one side's turn start: ticks and their deaths, then that side's torpedoes land
	startSideTurn(side); flush_deferred()
	if B != null and not jt(B.get("over")): resolveTorps(side)
func roundStartBoth() -> void: # alternating round start: player ticks, enemy ticks, then player torpedoes, then enemy torpedoes
	var b0 = B
	startSideTurn("player")
	if not jt(B.get("over")): startSideTurn("enemy")
	flush_deferred()
	if not is_same(B, b0) or jt(B.get("over")): return
	resolveTorps("player")
	if not is_same(B, b0) or jt(B.get("over")): return
	resolveTorps("enemy")
# ======================= combat math =======================
func sightBlocked(q, r) -> bool: return blocks(terr(q, r)) or (SOLID != null and SOLID.has(hkey(q, r)))
func los(a, b) -> bool:
	if _evc:
		var k = ((int(a["q"]) + 64) * 128 + int(a["r"]) + 64) * 16384 + (int(b["q"]) + 64) * 128 + int(b["r"]) + 64
		var c = _los.get(k)
		if c == null:
			c = _los_raw(a, b); _los[k] = c
		return c
	return _los_raw(a, b)
func _los_raw(a, b) -> bool:
	var line = hexLine(a, b)
	for i in range(1, line.size() - 1):
		if sightBlocked(line[i].q, line[i].r): return false
	return true
func weaponReady(w) -> bool: return not jt(w.get("fired")) and w.get("cdLeft") != null and w["cdLeft"] == 0 and w.get("off") != null and w["off"] == 0
# JS compares undefined as false both ways: the point-defence refit (battle.js:328) adds a weapon without fired, cdLeft or off (B-20)
func gt(a, b) -> bool: return a != null and a > b
func ge(a, b) -> bool: return a != null and a >= b
func le(a, b) -> bool: return a != null and a <= b
func eqn(a, b) -> bool: return a != null and a == b
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
	if _evc:
		var su = _slot.get(u.get("id")); var st = _slot.get(t.get("id")); var wi = -1
		var ws = u["weapons"]
		for i in range(ws.size()):
			if is_same(ws[i], w):
				wi = i; break
		var hu = int(z0(u.get("hexMoved"))); var ht = int(z0(t.get("hexMoved")))
		if su != null and st != null and su < 128 and st < 128 and wi >= 0 and wi < 16 and hu < 64 and ht < 64:
			var k = ((((((((su * 16 + wi) * 128 + st) * 128 + (int(u["q"]) + 64)) * 128 + (int(u["r"]) + 64)) * 128 + (int(t["q"]) + 64)) * 128 + (int(t["r"]) + 64)) * 64 + hu) * 64 + ht)
			var c = _hc.get(k)
			if c == null:
				c = _hitChance_raw(u, w, t); _hc[k] = c
			return c
	return _hitChance_raw(u, w, t)
func _hitChance_raw(u, w, t) -> float:
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
	if syncOn(u, t): c += TB.SYNC_AIM
	if jt(u.get("nem")) and nemWeak("brawl") and d <= 2: c -= 10
	if jt(t.get("isSq")) and wingStance(t) == "hunt": c += 10
	if jt(t.get("fx")) and jt(t["fx"].get("lineEv")) and B != null:
		for x in B["units"]:
			if not jt(x.get("dead")) and not is_same(x, t) and x["side"] == t["side"] and not jt(x.get("isSq")) and hdist(x, t) == 1:
				c -= t["fx"]["lineEv"]; break
	if B != null and B.get("mark") != null and B["mark"].get(u["side"]) != null and B["mark"][u["side"]]["r"] == B["round"] and B["mark"][u["side"]]["id"] == t.get("id"): c += 10
	var surge = cmdActive(t["side"], "surge")
	if w.get("k") == "lance" and jt(g(u.get("fx"), "lanceSure")): return 75.0 if surge else 95.0
	if u["side"] == "player" and not jt(u.get("isSq")) and not (z0(u.get("sureUsed")) > 0) and jt(runFx().get("firstSure")): return 75.0 if surge else 95.0
	var h: float = clamp_(JSM.jsround(c), 5, 95)
	return max(5, h - 20) if surge else h
func boonFx(u, id, txt = null, dy = null) -> void:
	if B != null:
		if B.get("boonStats") == null: B["boonStats"] = {}
		B["boonStats"][id] = z0(B["boonStats"].get(id)) + 1
	var b = TB.BOONS.get(id); var P = null
	if b != null: P = TB.PATRONS.get(b["p"]) if jt(b.get("p")) else (TB.PATRONS.get(b["duo"][0]) if jt(b.get("duo")) else null)
	flt(u, ((String(b["n"]) + ": ") if b != null else "") + tv(txt), String(P["col"]) if P != null else "#f0b35a", -30 if dy == null else dy)
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
	if _evc:
		var k = String(t["id"]) + "," + str(int(t["q"])) + "," + str(int(t["r"])) + ("v" if t.has("__view") else "")
		var c = _guard.get(k)
		if c == null:
			c = _guard_raw(t); _guard[k] = c
		return c
	return _guard_raw(t)
func _guard_raw(t) -> float:
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
	if rear and jt(t.get("nem")) and nemWeak("flank"): m += 0.25
	if jt(u.get("isSq")) and not jt(t.get("isSq")):
		if wingStance(u) == "hunt" and t["hp"] < t["maxHp"] / 2.0: m += 0.2
		var par = null
		if B != null:
			for x in B["units"]:
				if x["id"] == u.get("parent"): par = x; break
		if wingPerks(par).has("killers"): m += 0.15
	if t["hp"] < t["maxHp"] / 2.0: m += z0(fx.get("huntPct"))
	if jt(u.get("focus")): m += 0.3
	var still = fx["stillPct"] if (jt(fx.get("stillPct")) and not jt(u.get("hexMoved")) and (w["arc"] == "P" or w["arc"] == "S" or w["k"] == "battery")) else 0.0
	var sy = syncDmg(u["side"]) if syncOn(u, t) else 0.0
	m += max(still, sy)
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
	var pierce = 1.0 if (w.get("k") == "lance" and jt(ownerFx(u).get("lanceSure"))) else z0(w.get("pierce")); var ion = ionVs(u, w, t)
	var shieldable: float = raw * (1.0 - pierce)
	var absorbed: float = min(shieldable, float(z0(t["sh"][quad])) / ion)
	var hull: float = (raw - absorbed) * (1.0 - (t["armor"] * 0.5 if rear else t["armor"]))
	hull *= braceMul(t)
	hull *= cmdTaken(t) * guardMul(t)
	return {"hit": hit, "raw": raw, "hull": hull, "shield": absorbed * ion, "quad": quad, "rear": rear}
func applyHit(att, w, t, dmg: float, quad: int) -> Dictionary:
	var of = ownerFx(att); var rear = quad == 2; var pierce = 1.0 if (w.get("k") == "lance" and jt(of.get("lanceSure"))) else z0(w.get("pierce")); var ion = ionVs(att, w, t)
	if not jt(t.get("isSq")):
		if t.get("shHit") == null: t["shHit"] = [0, 0, 0, 0]
		t["shHit"][quad] = 1
		if jt(w.get("ion")) and att != null and att.get("fac") == "hegemony" and t["shMax"] > 0:
			if t.get("regenLock") == null: t["regenLock"] = [0, 0, 0, 0]
			t["regenLock"][quad] = 1
	var shieldable: float = dmg * (1.0 - pierce); var through: float = dmg - shieldable
	var s = z0(t["sh"][quad]); var absorbed: float = min(shieldable, float(s) / ion)
	t["sh"][quad] = max(0, s - absorbed * ion); shieldable -= absorbed
	var arm: float = max(0, t["armor"] - z0(t.get("shredded"))) * (1.0 - z0(w.get("armorPierce"))); var hull: float = (through + shieldable) * (1.0 - (arm * 0.5 if rear else arm))
	hull *= braceMul(t)
	hull *= cmdTaken(t) * guardMul(t)
	var crit = false
	if hull > 0.5 and rnd() * 100.0 < z0(w.get("crit")) + att["crit"] + (10 if jt(att.get("lockOn")) else 0) + (15 if rear else 0) + (z0(of.get("momCrit")) if z0(att.get("hexMoved")) >= 3 else 0):
		hull *= 1.5 + z0(of.get("critMul")); crit = true
	hull = JSM.jsround(hull)
	if hull > 0 and not jt(t.get("isSq")) and not jt(t.get("dead")):
		var ch = z0(of.get("igniteCh")) + (z0(of.get("broadIgnite")) if (w.get("arc") == "P" or w.get("arc") == "S") else 0) + (z0(of.get("sqIgnite")) if jt(att.get("isSq")) else 0)
		if ch > 0 and rnd() < ch:
			var fd = 6 + z0(of.get("fireDmg"))
			if not (z0(t["st"].get("fire")) > 0): boonFx(t, "d_burnswarm" if (jt(att.get("isSq")) and jt(of.get("sqIgnite"))) else ("d_inferno" if ((w.get("arc") == "P" or w.get("arc") == "S") and jt(of.get("broadIgnite")) and not jt(of.get("igniteCh"))) else "e_kindle"), "ignited", -28)
			t["st"]["fire"] = max(z0(t["st"].get("fire")), 2 + z0(of.get("fireLong"))); t["st"]["fireDmg"] = max(t["st"]["fireDmg"] if jt(t["st"].get("fireDmg")) else 6, fd)
			emit({"t": "burning", "unit": t["id"]})
	if hull > 0 and not jt(t.get("isSq")) and not jt(t.get("dead")):
		if jt(w.get("ignite")):
			t["st"]["fire"] = max(z0(t["st"].get("fire")), 2); t["st"]["fireDmg"] = max(t["st"]["fireDmg"] if jt(t["st"].get("fireDmg")) else 6, 6)
			emit({"t": "burning", "unit": t["id"]})
		if jt(w.get("shred")): t["shredded"] = min(0.15, z0(t.get("shredded")) + w["shred"])
		if jt(w.get("acid")): t["st"]["acid"] = 2
	if jt(of.get("pyre")) and not jt(t.get("isSq")) and t["hp"] < t["maxHp"] / 2.0: t["pyre"] = true
	t["hp"] = t["hp"] - hull; att["dealt"] = att["dealt"] + hull
	emit({"t": "hit", "unit": _uid(att), "target": t["id"], "quad": quad, "section": t["_calledSec"] if jt(t.get("_calledSec")) else SEC_OF_QUAD[quad], "shield": JSM.jsround(absorbed * ion), "hull": hull, "crit": crit})
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
			if w["arc"] == "F" and ge(w.get("off"), 99): w["off"] = 0
	if sec == "mid":
		for w in t["weapons"]:
			if (w["arc"] == "P" or w["arc"] == "S") and ge(w.get("off"), 99): w["off"] = 0
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
	emit({"t": "section_down", "unit": t["id"], "section": sec})
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
	flt(t, String(SEC_NAME[sec]).substr(0, 1).to_upper() + String(SEC_NAME[sec]).substr(1) + " destroyed", "#f0b35a", -36)
	logm(String(t["name"]) + ": " + String(SEC_NAME[sec]) + " destroyed. " + ("Forward weapons silenced." if sec == "prow" else ("Broadsides and shield generator gone." if sec == "mid" else "Engines crippled.")), pe(t))
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
			if eqn(w.get("off"), 0): live.append(w)
		JSM.ssort(live, func(a, b): return b["dmg"] * b["shots"] - a["dmg"] * a["shots"])
		if live.size() > 0:
			live[0]["off"] = 2; return tv(live[0].get("n")) + " knocked out"
	if r == "engine":
		t["st"]["engine"] = min(t["speed"] - 1, t["st"]["engine"] + 1); return "Engines hit"
	if r == "shields" and t["shMax"] > 0 and z0(t["st"].get("shieldOff")) < 99:
		t["st"]["shieldOff"] = max(z0(t["st"].get("shieldOff")), 2); return "Shield generator down"
	if r == "weapon":
		var ws = []
		for w in t["weapons"]:
			if z0(w.get("off")) < 99: ws.append(w)
		if ws.size() > 0:
			var w = pick(ws); w["off"] = max(z0(w.get("off")), 2); return tv(w.get("n")) + " knocked out"   # B-20: a refit has no name ("undefined knocked out")
	if r == "shields" and z0(t["st"].get("shieldOff")) >= 99:
		t["st"]["fire"] = 2; return "Fire on deck"
	t["st"]["fire"] = 2; return "Fire on deck"

func fireWeapon(u, wi: int, t, opts: Dictionary = {}) -> bool:
	if not inThisBattle(u): return false
	var live = liveFrom(null)
	var w = u["weapons"][wi]
	if not jt(opts.get("intercept")) and not canFire(u, w, t): return false
	var keep = [w.get("fired"), w.get("cdLeft"), u.get("sureUsed"), u.get("postFire"), u.get("postMp")]; var b0 = B   # get(): B-20 refits lack fired and cdLeft
	if not jt(opts.get("intercept")):
		w["fired"] = true
		if jt(w.get("cd")): w["cdLeft"] = w["cd"]
		if u["side"] == "player" and not jt(u.get("isSq")): u["sureUsed"] = z0(u.get("sureUsed")) + 1
	if jt(B.get("usage")) and u["side"] == "player" and not jt(opts.get("intercept")) and not jt(u.get("isSq")):
		var k = ARC_NAME[w["arc"]] if jt(ARC_NAME.get(w["arc"])) else str(w["arc"])
		B["usage"]["fire"][k] = z0(B["usage"]["fire"].get(k)) + 1
		if jt(opts.get("called")): B["usage"]["aim"] = B["usage"]["aim"] + 1
	if jt(B.get("usage")) and u["side"] == "player" and not jt(opts.get("intercept")):
		if B["usage"].get("kind") == null: B["usage"]["kind"] = {}
		var kk = "sq" if jt(u.get("isSq")) else w["k"]; B["usage"]["kind"][kk] = z0(B["usage"]["kind"].get(kk)) + 1
		if jt(w.get("ion")): B["usage"]["ion"] = z0(B["usage"].get("ion")) + 1
	if not jt(opts.get("intercept")) and not jt(u.get("isSq")) and w["k"] != "flak" and not jt(u.get("postFire")):
		u["postFire"] = true; u["postMp"] = floor(u["mp"] / 2.0) if canFade(u) else 0
	if not jt(opts.get("intercept")) and torpTravels(w, u): return launchTorp(u, w, t, opts, live, keep, b0)
	if jt(u.get("isSq")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")):
		for d in alive(t["side"]):
			if jt(d.get("isSq")) or d["intercepts"] <= 0 or jt(d.get("braced")): continue
			var fi = -1
			for k in range(d["weapons"].size()):
				if d["weapons"][k]["k"] == "flak" and eqn(d["weapons"][k].get("off"), 0):
					fi = k; break
			if fi < 0: continue
			if hdist(d, u) > d["weapons"][fi]["r"]: continue
			d["intercepts"] = d["intercepts"] - 1
			fireWeapon(d, fi, u, {"intercept": true})
			if jt(u.get("dead")): return true
	var quad = shieldQuad(t, u); var shBefore = z0(t["sh"][quad]) if t.get("sh") != null else 0
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	var called = opts["called"] if jt(opts.get("called")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")) else null
	var su = u.get("sureUsed")
	if not jt(opts.get("intercept")): u["sureUsed"] = keep[2]
	var hc = hitChance(u, w, t); u["sureUsed"] = su   # the rangefinder relic reads the count from before this shot
	if not jt(opts.get("intercept")) and not jt(u.get("isSq")):
		fstat(u["fac"], "shots")
		if syncOn(u, t): fstat(u["fac"], "syncShots")
	var shots = []
	for i in range(int(w["shots"])): shots.append(rnd() * 100.0 < hc)
	rocketDefense(w, t, shots, res)
	emit({"t": "fire", "unit": u["id"], "weapon": wi, "weapon_id": w["id"], "kind": w["k"], "arc": w["arc"], "name": w.get("n"), "target": t["id"], "shots": shots.duplicate(), "pd": z0(res.get("pd")), "quad": quad}); hook("fire", u)
	if B != null: B["prog"] = z0(B.get("prog")) + 1
	if not live.call():
		if not jt(opts.get("intercept")) and is_same(B, b0):
			w["fired"] = keep[0]; w["cdLeft"] = keep[1]; u["sureUsed"] = keep[2]; u["postFire"] = keep[3]; u["postMp"] = keep[4]
		return false
	if not jt(opts.get("intercept")): syncMarkShot(u, t)
	return landVolley(u, w, t, {"quad": quad, "shBefore": shBefore, "shots": shots, "called": called, "res": res, "intercept": jt(opts.get("intercept"))})
func landVolley(u, w, t, o) -> bool: # the shots of one weapon land (direct fire and torpedo impact)
	var quad = o["quad"]; var shots = o["shots"]; var called = o["called"]; var res = o["res"]; var shBefore = o["shBefore"]
	if called != null:
		u["crit"] = u["crit"] + 15; t["_calledSec"] = called
	for h in shots:
		if jt(t.get("dead")): break
		if not h:
			res.misses += 1; continue
		res.hits += 1
		var d = (o["per"].call(quad == 2) if o.get("per") != null else dmgMult(u, w, t, quad == 2)) * (0.85 + rnd() * 0.3)
		var r = applyHit(u, w, t, d, quad)
		res.shield += r.shield; res.hull += r.hull
		if r.crit:
			res.crits += 1; var cs = ownerFx(u).get("critSys")
			if not jt(res.sys) and (jt(called) or jt(cs) or rnd() < 0.4):
				res.sys = systemDamage(t, called)
				if res.sys != null: emit({"t": "system", "unit": t["id"], "text": res.sys})
				if jt(cs) and jt(res.sys): boonFx(t, "a_crit", res.sys, -48)
	if called != null:
		u["crit"] = u["crit"] - 15; t["_calledSec"] = null
	if res.shield > 0:
		flt(t, "−" + ns(res.shield) + " shield", "#62ccff", -18)
		if t["shMax"] > 0 and t["sh"][quad] <= 0.5:
			emit({"t": "shield_down", "unit": t["id"], "quad": quad}); flt(t, "Shields down", "#9fe2ff", -40)
		if t["shMax"] > 0 and t["sh"][quad] <= 0.5:
			if jt(ownerFx(u).get("chainSh")) and shBefore > 0.5 and not jt(t.get("dead")) and t.get("sh") != null:
				for qq in [(quad + 1) % 4, (quad + 3) % 4]: t["sh"][qq] = JSM.jsround(t["sh"][qq] * 2.0 / 3.0)
				boonFx(t, "s_chain", "chain lightning", -62)
			var ar = ownerFx(u).get("arcShort")
			if jt(ar) and shBefore > 0.5 and not jt(t.get("dead")):
				t["hp"] = t["hp"] - ar; res.hull += ar; u["dealt"] = u["dealt"] + ar; boonFx(t, "s_arc", "−" + ns(ar), -56)
	if res.hull > 0: flt(t, "−" + ns(res.hull) + " hull", "#ffd27a" if res.crits else "#ffae42", 0)
	if res.hits == 0: flt(t, "Miss", "#9a9384", 0)
	if jt(res.crits): flt(t, "Critical", "#f0b35a", 18)
	var parts = []
	if jt(res.get("pd")): parts.append(ns(res.pd) + " shot down by point defense")
	if res.hits == 0: parts.append("all shots miss")
	else:
		if jt(res.shield): parts.append(ns(res.shield) + " to " + String(QUAD_NAME[quad]) + " shields")
		if jt(res.hull): parts.append(ns(res.hull) + " hull")
		if not jt(res.shield) and not jt(res.hull): parts.append("no damage")
	if jt(res.crits): parts.append((ns(res.crits) + " criticals") if res.crits > 1 else "critical")
	if not jt(o.get("torp")) and not jt(o.get("intercept")) and res.hull > 0 and t["side"] != u["side"]:
		var bite = chorusBiteEst(u, t, res.hull)
		if jt(bite): chorusRegrow(u, bite, "Bites")
	if res.hits > 0 and w.get("k") == "lance" and not jt(o.get("intercept")) and jt(ownerFx(u).get("markLance")) and B != null and not jt(t.get("dead")):
		if B.get("mark") == null: B["mark"] = {}
		if B["mark"].get(u["side"]) == null or B["mark"][u["side"]]["r"] != B["round"]:
			B["mark"][u["side"]] = {"id": t["id"], "r": B["round"]}; boonFx(t, "a_mark", "marked", -62)
	var tail = ": " + ", ".join(parts) + "." + ((" " + String(res.sys) + "!") if jt(res.sys) else "")
	if jt(o.get("torp")): logm("Torpedoes from " + String(u["name"]) + " reach " + String(t["name"]) + (" (a stray hit in the lane)" if jt(o.get("stray")) else "") + tail, pp(u))
	else: logm(String(u["name"]) + " " + ("intercepts with" if jt(o.get("intercept")) else "fires") + " " + tv(w.get("n")) + " at " + String(t["name"]) + tail, pp(u))
	if not jt(o.get("torp")) and res.hits > 0 and jt(t.get("braced")) and not jt(t.get("dead")) and not jt(u.get("dead")) and not jt(o.get("intercept")) and t["side"] != u["side"]:
		var rp = ownerFx(t).get("riposte")
		if jt(rp):
			u["hp"] = u["hp"] - rp; t["dealt"] = z0(t.get("dealt")) + rp; boonFx(u, "i_brace", "−" + ns(rp), -40)
			if u["hp"] <= 0: killUnit(u, t)
	if t["hp"] <= 0:
		t["killCause"] = killCauseOf(w, t); killUnit(t, o["by"] if o.get("by") != null else u)
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
	hook("move", u)
	if not live.call(): return false
	for p in info.path:
		u["q"] = p.q; u["r"] = p.r
	u["facing"] = info.path[info.path.size() - 1].f
	u["mp"] = 0; u["turnsLeft"] = 0; u["rammed"] = true
	if jt(B.get("usage")) and u["side"] == "player":
		B["usage"]["ram"] = z0(B["usage"].get("ram")) + 1
		for id in ["d_jugg", "r_prow"]:
			if hasBoon(id):
				if B.get("boonStats") == null: B["boonStats"] = {}
				B["boonStats"][id] = z0(B["boonStats"].get(id)) + 1
	var e = ramEstimate(u, t, info.path.size())
	emit({"t": "ram", "unit": u["id"], "target": t["id"], "path": info.path.duplicate(true), "dmg": e.dmg, "recoil": e.recoil, "soak": e.soak, "section": e.sec}); hook("ram", u)
	if not live.call() or jt(t.get("dead")): return false
	var qd = shieldQuad(t, u)
	if jt(e.soak) and t.get("sh") != null: t["sh"][qd] = max(0, t["sh"][qd] - e.soak * 1.5)
	t["hp"] = t["hp"] - e.dmg; u["dealt"] = u["dealt"] + e.dmg; damageSection(t, e.sec, e.dmg, u); u["hp"] = u["hp"] - e.recoil; damageSection(u, "prow", e.recoil, t)
	flt(t, "−" + ns(e.dmg), "#f0b35a", 0); flt(u, "−" + ns(e.recoil), "#ff7a6e", 0)
	logm(String(u["name"]) + " rams " + String(t["name"]) + " at full speed: " + ns(e.dmg) + " to its " + String(SEC_NAME[e.sec]) + ", " + ns(e.recoil) + " back to the ram.", pp(u))
	if rnd() < 0.35:
		var sy = systemDamage(t, e.sec)
		if jt(sy): logm(String(t["name"]) + ": " + String(sy) + ".", pp(u))
	if jt(u.get("fx")) and jt(u["fx"].get("ramSplash")):
		var sd = JSM.jsround(e.dmg * u["fx"]["ramSplash"])
		var hitl = []
		for x in B["units"]:
			if not jt(x.get("dead")) and not is_same(x, t) and x["side"] == t["side"] and hdist(x, t) == 1: hitl.append(x)
		for x in hitl:
			x["hp"] = x["hp"] - sd; boonFx(x, "r_shock", "−" + ns(sd), -10)
			if x["hp"] <= 0: killUnit(x, u)
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
func boardUnit(u, t) -> bool:
	if not JSM.has_same(boardTargets(u), t): return false
	if jt(B.get("usage")) and u["side"] == "player": B["usage"]["board"] = z0(B["usage"].get("board")) + 1
	u["boarded"] = true; u["repel"] = true; u["mp"] = 0
	for w in u["weapons"]: w["fired"] = true
	var live = liveFrom(u)
	hook("board", u)
	if not live.call() or jt(t.get("dead")): return false
	var a = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct"))) * (0.75 + rnd() * 0.5)
	var d = t["crew"] * (BOARD_MULT[t["fac"]] if jt(BOARD_MULT.get(t["fac"])) else 1.0) * (2.25 if jt(t.get("repel")) else 1.5) * (0.75 + rnd() * 0.5)
	var kill = JSM.jsround(a * 0.38); var loss = min(u["crew"] - 1, JSM.jsround(d * 0.3)); t["crew"] = max(0, t["crew"] - kill); u["crew"] = max(1, u["crew"] - loss)
	var outcome = "overrun" if (t["crew"] <= 0 and (t["side"] == "player" or jt(t.get("boss"))) and not jt(t.get("captured"))) else ("capture" if t["crew"] <= 0 else "raid")
	emit({"t": "board", "unit": u["id"], "target": t["id"], "result": outcome, "kill": kill, "loss": loss})
	if t["crew"] <= 0 and (t["side"] == "player" or jt(t.get("boss"))) and not jt(t.get("captured")):
		t["crew"] = max(2, JSM.jsround(t["crewMax"] * 0.15)); var s1 = systemDamage(t); var s2 = systemDamage(t)
		flt(t, "Holds the bridge", "#f0b35a", -30)
		logm(String(u["name"]) + "'s boarders overrun " + String(t["name"]) + ", but the last of its crew hold the bridge." + ((" Saboteurs: " + String(s1).to_lower()) if jt(s1) else "") + ((", " + String(s2).to_lower()) if jt(s2) else "") + ".", pp(u))
		if jt(B.get("usage")) and t["side"] == "player": B["usage"]["overrun"] = z0(B["usage"].get("overrun")) + 1
		return true
	if t["crew"] <= 0:
		if jt(B.get("usage")) and u["side"] == "player": B["usage"]["cap"] = z0(B["usage"].get("cap")) + 1
		if jt(t.get("anchor")): syncLose(t)
		t["side"] = u["side"]; t["crew"] = max(3, JSM.jsround(t["crewMax"] * 0.4)); t["captured"] = true; t["activated"] = true; t["mp"] = 0; t["turnsLeft"] = 0; t["braced"] = false
		for w in t["weapons"]: w["fired"] = true
		gainResolve(u["side"], 2); flt(t, "Captured", "#f0b35a", -30); logm("Boarding parties from " + String(u["name"]) + " take " + String(t["name"]) + ". It now fights for " + ("you" if u["side"] == "player" else "the enemy") + ".", pp(u))
		checkEnd(); return true
	flt(t, "−" + ns(kill) + " crew", "#f0b35a", -18); flt(u, "−" + ns(loss) + " crew", "#ff7a6e", -18)
	var extra = ""
	if rnd() < 0.5 or jt(g(u.get("fx"), "boardPct")):
		var sy = systemDamage(t)
		if jt(sy): extra = " Saboteurs: " + String(sy).to_lower() + "."
	logm(String(u["name"]) + " boards " + String(t["name"]) + ": " + ns(kill) + " defenders killed, " + ns(loss) + " boarders lost." + extra, pp(u))
	return true
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
		if jt(by.get("isSq")):
			var pu = null
			for x in B["units"]:
				if x["id"] == by.get("parent"): pu = x; break
			t["killedBy"] = (pu if pu != null else by)["name"]
		else: t["killedBy"] = by["name"]
	if jt(t.get("dead")): return
	if jt(t["fx"].get("lastStand")) and not jt(t.get("usedLastStand")):
		t["usedLastStand"] = true; t["hp"] = 1; flt(t, "Last stand", "#f0b35a", -30); logm(String(t["name"]) + " refuses to die! (Last stand)", "s"); return
	if t["side"] == "player" and not jt(t.get("isSq")) and jt(runFx().get("revive")) and not jt(B.get("reviveUsed")):
		B["reviveUsed"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.25); flt(t, "Reawakens", "#7dff9b", -30); logm("The phylactery hums. " + String(t["name"]) + " reawakens at 25% hull.", "s"); return
	var legion = legionCan(t)
	if not legion and jt(t.get("reanimate")) and not jt(t.get("reanimated")) and not jt(t.get("pyre")) and not (t.get("fac") == "deathless" and jt(t.get("t")) and jt(t["t"].get("reanimate"))) and rnd() < (0.2 if t["side"] == "enemy" else 0.35):
		t["reanimated"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.3); flt(t, "Reanimating", "#7dff9b", -30); logm(String(t["name"]) + " reassembles itself from the wreckage.", "e"); return
	t["dead"] = true; t["hp"] = 0
	if legion:
		t["reanimated"] = true; t["riseAt"] = B["round"] + 1; B["legion"][t["side"]]["used"] = B["legion"][t["side"]]["used"] + 1
		logm(String(t["name"]) + " falls, but its wreck is already reassembling. It rises next round.", pp(t)); flt(t, "Reassembling: rises next round", "#7dff9b", -30)
	syncLose(t); chorusFeed(t, by)
	if by != null and not jt(t.get("isSq")) and by["side"] != t["side"] and jt(ownerFx(by).get("broodTithe")):
		var cs = []
		for x in alive(by["side"]):
			if not jt(x.get("isSq")) and (x.get("ab") == "launch" or jt(g(x.get("fx"), "hive"))) and launchHexes(x).size() > 0: cs.append(x)
		JSM.ssort(cs, func(a, b): return hdist(a, t) - hdist(b, t))
		if cs.size() > 0:
			var c = cs[0]; var h = launchHexes(c)[0]; var sq = makeWing(c, h, wingKind(c)); sq["mp"] = 0
			for w in sq["weapons"]: w["fired"] = true
			boonFx(c, "h_brood", "free wing", -30)
	if t["side"] == "player" and not jt(t.get("isSq")) and not jt(t.get("transport")):
		var av = runFx().get("avenge")
		if jt(av):
			for x in alive("player"):
				if not jt(x.get("isSq")) and x["hp"] < x["maxHp"]:
					var h = min(x["maxHp"] - x["hp"], JSM.jsround(x["maxHp"] * av)); x["hp"] = x["hp"] + h; flt(x, "+" + ns(h) + " hull", "#8ff0a0", -20)
			logm("The fleet rallies around the loss of " + String(t["name"]) + ".", "s")
	if by != null and by["side"] == "player" and not jt(t.get("isSq")) and jt(runFx().get("bloodied")):
		var k = by
		if jt(by.get("isSq")):
			k = null
			for x in B["units"]:
				if x["id"] == by.get("parent"): k = x; break
		if k != null and not jt(k.get("dead")):
			k["bloodied"] = min(3, z0(k.get("bloodied")) + 1); flt(k, "Bloodied +" + ns(JSM.jsround(15 * k["bloodied"])) + "%", "#ff9f3a", -36)
	if not jt(t.get("isSq")) and t["size"] >= 0.7 and not legion and not blocks(B["terrain"].get(hkey(t["q"], t["r"]))):
		B["terrain"][hkey(t["q"], t["r"])] = "hulk"; t["hulk"] = true; emit({"t": "wreck", "unit": t["id"], "q": t["q"], "r": t["r"]})
		logm("The wreck of " + String(t["name"]) + " drifts in place, blocking movement and fire.", "x")
	if by != null and not jt(t.get("isSq")): gainResolve(by["side"], 1)
	if by != null:
		by["kills"] = by["kills"] + 1
		if jt(by.get("parent")): pass   # p.kills += 0
	if by != null and jt(by.get("isSq")):
		var p = null
		for x in B["units"]:
			if x["id"] == by.get("parent") and not jt(x.get("dead")): p = x; break
		if p != null and jt(p.get("fx")) and jt(p["fx"].get("feast")):
			p["spare"] = z0(p.get("spare")) + 1; var h = JSM.jsround(p["maxHp"] * p["fx"]["feast"]); p["hp"] = min(p["maxHp"], p["hp"] + h); boonFx(p, "h_feast", "+" + ns(h) + " hull, +1 wing", -30)
	emit({"t": "death", "unit": t["id"], "cause": t.get("killCause") if t.get("killCause") != null else "blast", "by": _uid(by)}); hook("death", t)
	var tail = func():
		var cb = ownerFx(by).get("chainBoom") if (by != null and not jt(t.get("isSq")) and by["side"] != t["side"]) else 0
		if jt(cb):
			var near = []
			for x in B["units"]:
				if not jt(x.get("dead")) and x["side"] == t["side"] and not is_same(x, t) and hdist(x, t) <= 2: near.append(x)
			if near.size() > 0: logm(String(t["name"]) + "'s reactor goes up, scorching " + ns(near.size()) + " nearby ship" + ("s" if near.size() > 1 else "") + ".", pp(by))
			var cf = ownerFx(by).get("chainFire")
			for x in near:
				if jt(x.get("dead")): continue
				x["hp"] = x["hp"] - cb
				if jt(cf) and not jt(x.get("isSq")):
					x["st"]["fire"] = max(z0(x["st"].get("fire")), 2); x["st"]["fireDmg"] = max(x["st"]["fireDmg"] if jt(x["st"].get("fireDmg")) else 6, 6)
				boonFx(x, "e_chain", "−" + ns(cb), -12)
				if x["hp"] <= 0: killUnit(x, by)
		logm(String(t["name"]) + " " + ("is shot down" if jt(t.get("isSq")) else "is destroyed") + ".", pe(t))
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
	if o.type == "hunt":
		var l = []
		for u in alive("enemy"):
			if not jt(u.get("isSq")): l.append(u)
		JSM.ssort(l, func(a, c): return _byCpHp(a, c))
		if l.size() > 0:
			l[0]["flagship"] = true; o["rounds"] = ENC_ROUNDS
		else: o.type = "rout"
	if o.type == "defend":
		o["hex"] = {"q": B["map"]["station"]["q"], "r": B["map"]["station"]["r"]}; o["hp"] = 5; o["hpMax"] = 5; o["rounds"] = ENC_ROUNDS
	if o.type == "intercept":
		var tr = []
		for u in B["units"]:
			if jt(u.get("transport")): tr.append(u)
		o["total"] = tr.size(); o["need"] = max(1, tr.size() - 1); o["exitR"] = boardBounds().r1; o["kill"] = 0; o["esc"] = 0
		if tr.size() == 0: o.type = "rout"
	if o.type == "break":
		var n = caps("player").size(); o["need"] = max(1, int(ceil(n / 2.0))); o["exitC"] = boardBounds().c1 - 1; o["out"] = 0
	if o.type == "flagship":
		var l = []
		for u in alive("enemy"):
			if not jt(u.get("isSq")): l.append(u)
		JSM.ssort(l, func(a, c): return _byCpHp(a, c))
		if l.size() > 0: l[0]["flagship"] = true
		else: o.type = "rout"
	if o.type == "hold":
		var c = offToAx(floori(BW / 2.0), floori(BH / 2.0)); var best = null; var bd = 1e9
		for h in boardHexes():
			if blocks(terr(h.q, h.r)) or unitAt(h.q, h.r) != null: continue
			var d = hdist(h, c)
			if d < bd:
				bd = d; best = h
		o["hex"] = {"q": best.q, "r": best.r}
		for h in boardHexes():
			if hdist(h, o.hex) <= 1 and blocks(terr(h.q, h.r)): B["terrain"].erase(hkey(h.q, h.r))
	B["obj"] = o
func survivorsP() -> int:
	var n = 0
	for u in B["units"]:
		if u["side"] == "player" and not jt(u.get("isSq")) and (not jt(u.get("dead")) or jt(u.get("exited"))): n += 1
	return n
func objZone(q, r):
	var o = B.get("obj") if B != null else null
	if o == null or not onBoard(q, r): return null
	if o.type == "break" and q + floor(r / 2.0) >= o.exitC: return "exit"
	if o.type == "intercept" and r >= o.exitR: return "texit"
	if o.type == "defend" and hdist({"q": q, "r": r}, o.hex) == 2: return "guard"
	return null
func stationFire(dq) -> void:
	var o = B.get("obj")
	if o == null or o.type != "defend": return
	var src = {"q": o.hex.q, "r": o.hex.r, "facing": 0}; var ts = []
	for u in caps("enemy"):
		if hdist(u, o.hex) <= 5: ts.append(u)
	JSM.ssort(ts, func(a, b): return hdist(a, o.hex) - hdist(b, o.hex))
	ts = ts.slice(0, 2)
	var att = {"side": "player", "dealt": 0, "kills": 0, "crit": 0, "lockOn": false, "fx": {}}
	for t in ts:
		var r = applyHit(att, {"crit": 0, "pierce": 0.2}, t, 12, shieldQuad(t, src))
		flt(t, "Station −" + ns(r.hull + r.shield), "#7fd6ff", -30)
		logm("Station batteries hit " + String(t["name"]) + ": " + ns(r.shield) + " shield, " + ns(r.hull) + " hull.", "p")
		if t["hp"] <= 0 and not jt(t.get("dead")):
			t["hp"] = 0; queueDeath(t, dq)
func objAfterMove(u) -> void:
	var o = B.get("obj") if B != null else null
	if o == null or u == null or jt(u.get("dead")) or jt(u.get("isSq")): return
	if o.type == "break" and u["side"] == "player" and objZone(u["q"], u["r"]) == "exit":
		u["exited"] = true; u["dead"] = true; u["fled"] = true
		emit({"t": "fled", "unit": u["id"], "why": "exit"}); logm(String(u["name"]) + " breaks through and jumps clear.", "s"); checkEnd()
	elif o.type == "intercept" and jt(u.get("transport")) and objZone(u["q"], u["r"]) == "texit":
		u["dead"] = true; u["fled"] = true
		emit({"t": "fled", "unit": u["id"], "why": "exit"}); logm(String(u["name"]) + " gets through.", "e"); checkEnd()
func aiObjScore(u, v) -> float:
	var o = B.get("obj")
	if o == null or jt(u.get("isSq")): return 0.0
	if jt(u.get("transport")): return -(o.exitR - v.r) * 14.0
	if o.type == "hunt" and jt(u.get("flagship")):
		var d = _mind(v, caps("player"), 30); return min(d, 9) * 3.0
	var vet = aiVet(); var urg = aiObjUrgency(o) if vet else 1.0
	if o.type == "defend": return -max(0, hdist(v, o.hex) - 2) * 3.0 * urg
	if o.type == "break":
		var pl = caps("player")
		if pl.size() == 0: return 0.0
		var cols = []
		for p in pl: cols.append(p["q"] + floor(p["r"] / 2.0))
		var lead = JSM.amax(cols); var c = v.q + floor(v.r / 2.0)
		if not vet: return -max(0, lead + 1 - c) * 1.2
		var L = null
		for p in pl:
			if p["q"] + floor(p["r"] / 2.0) == lead:
				L = p; break
		if o.get("c0") == null: o["c0"] = boardBounds().c0
		var c0 = o.c0; var prog = clamp_((lead - c0) / max(1, o.exitC - c0), 0, 1)
		return -(max(0, lead + 1 - c) * 1.2 + max(0, absf(v.r - L["r"]) - 2) * 0.5) * (1 + 1.5 * prog)
	if vet and o.type == "intercept":
		var d = 99.0
		for x in B["units"]:
			if jt(x.get("transport")) and not jt(x.get("dead")): d = min(d, hdist(v, x))
		return -max(0, d - 3) * 1.5 if d < 99 else 0.0
	if vet and o.type == "hold":
		var mine = []
		for x in caps("enemy"):
			if not jt(x.get("transport")): mine.append(x)
		JSM.ssort(mine, func(a, b):
			var dd = hdist(a, o.hex) - hdist(b, o.hex)
			return dd if dd != 0 else (-1 if String(a["id"]) < String(b["id"]) else 1))
		var k = JSM.index_same(mine, u); var d = hdist(v, o.hex)
		if k < 0 or k > 1: return -max(0, d - 5) * 0.4
		var contested = false
		for p in caps("player"):
			if hdist(p, o.hex) <= 1: contested = true
		var held = hdist(u, o.hex) <= 1 and not contested
		return -d * 1.6 * urg + (4.0 if (held and d <= 1) else 0.0)
	return 0.0
func aiObjUrgency(o) -> float:
	var done: float = clamp_((float(B["round"] if jt(B.get("round")) else 1) - 1.0) / float(o["rounds"] if jt(o.get("rounds")) else ENC_ROUNDS), 0.0, 1.0)
	if o.type == "defend": return 1.0 + done * 1.2 + (0.6 if o["hp"] <= 2 else 0.0)
	if o.type == "hold": return 1.0 + done * 0.8 + (0.8 if o["score"] >= 2 else 0.0) + (0.4 if o["escore"] >= 2 else 0.0)
	return 1.0
func objectiveTick(_dq) -> void:
	var o = B.get("obj")
	if o == null or jt(B.get("over")): return
	if o.type == "defend":
		var near = []
		for u in caps("enemy"):
			if hdist(u, o.hex) <= 2: near.append(u)
		if near.size() > 0:
			o["hp"] = max(0, o["hp"] - near.size()); logm(ns(near.size()) + " enemy ship" + ("s" if near.size() > 1 else "") + " at the station. Integrity " + ns(o["hp"]) + "/" + ns(o["hpMax"]) + ".", "e")
		if o["hp"] > 0 and B["round"] <= o["rounds"]: stationFire(_dq)
		checkEnd(); return
	if o.type == "hunt":
		if B["round"] > o["rounds"]:
			var f = null
			for u in B["units"]:
				if jt(u.get("flagship")) and u["side"] == "enemy" and not jt(u.get("dead")):
					f = u; break
			if f != null:
				f["dead"] = true; f["fled"] = true; o["escaped"] = true
				emit({"t": "fled", "unit": f["id"], "why": "escape"}); logm(String(f["name"]) + " jumps out. Its escorts follow.", "e")
		checkEnd(); return
	if o.type != "hold": return
	var p = false; var e = false
	for u in alive("player"):
		if not jt(u.get("isSq")) and hdist(u, o.hex) <= 1: p = true
	for u in alive("enemy"):
		if not jt(u.get("isSq")) and hdist(u, o.hex) <= 1: e = true
	if p and not e:
		o["score"] = o["score"] + 1; logm("You hold the relay (" + ns(o["score"]) + "/3).", "p")
	elif e and not p:
		o["escore"] = o["escore"] + 1; logm("The enemy holds the relay (" + ns(o["escore"]) + "/3).", "e")
	elif p and e: logm("The relay is contested.", "x")
	checkEnd()
func checkEnd() -> void:
	var was = B != null and jt(B.get("over"))
	checkEndRules()   # scheduleBattleEnd: the end screen is presentation
	if B != null and not was and jt(B.get("over")) and B["over"] == "win":
		for u in B["units"]:
			if jt(u.get("dead")) and u["side"] == "player" and u.get("riseAt") != null and not jt(u.get("fled")): legionRise(u, true)
func checkEndRules() -> void:
	if jt(B.get("over")): return
	if caps("enemy").size() == 0:
		B["over"] = "win"; return
	var o = B.get("obj")
	if o != null and o.type == "break":
		var out = 0
		for u in B["units"]:
			if jt(u.get("exited")): out += 1
		o["out"] = out
		if out >= o.need:
			B["over"] = "win"; logm(ns(out) + " ship" + ("s" if out > 1 else "") + " broke through. The fleet jumps clear.", "s"); return
		if out > 0 and caps("player").size() + out < o.need:
			B["over"] = "loss"; B["withdraw"] = true; logm("Too few ships can still get through. The survivors jump clear.", "e"); return
	if caps("player").size() == 0:
		B["over"] = "loss"; return
	if o != null and o.type == "intercept":
		var kill = 0; var esc = 0
		for u in B["units"]:
			if not jt(u.get("transport")): continue
			if jt(u.get("dead")) and not jt(u.get("fled")): kill += 1
			if jt(u.get("fled")): esc += 1
		o["kill"] = kill; o["esc"] = esc
		if kill >= o.need:
			B["over"] = "win"; B["routed"] = true; logm("The convoy is broken. The escorts break off.", "s"); return
		if esc > o.total - o.need:
			B["over"] = "win"; B["partial"] = true; logm("Enough transports got through. The escorts break off.", "e"); return
	if o != null and o.type == "defend":
		if o["hp"] <= 0:
			B["over"] = "loss"; B["withdraw"] = true; logm("The station falls. Your fleet is forced to withdraw.", "e"); return
		if B["round"] > o["rounds"]:
			B["over"] = "win"; logm("The station holds. The enemy withdraws.", "s"); return
	if o != null and o.type == "hunt":
		var f = null
		for u in B["units"]:
			if jt(u.get("flagship")) and u["side"] == "enemy":
				f = u; break
		if f != null and jt(f.get("dead")):
			B["over"] = "win"
			if jt(o.get("escaped")):
				B["partial"] = true; logm("The flagship got away. Its escorts withdraw.", "e")
			else:
				B["routed"] = true; logm("The flagship is destroyed. Its escorts scatter.", "s")
			return
	if jt(B.get("obj")) and B["obj"].type == "flagship":
		var any = false
		for u in B["units"]:
			if jt(u.get("flagship")) and u["side"] == "enemy" and not jt(u.get("dead")): any = true
		if not any:
			B["over"] = "win"; B["routed"] = true; logm("The enemy flagship is gone. The rest of their fleet scatters.", "s"); return
	if jt(B.get("obj")) and B["obj"].type == "hold":
		if B["obj"]["score"] >= 3:
			B["over"] = "win"; logm("The relay is yours. The enemy withdraws.", "s"); return
		if B["obj"]["escore"] >= 3:
			B["over"] = "loss"; B["withdraw"] = true; logm("The enemy secures the relay. Your fleet is forced to withdraw.", "e"); return
	if not jt(B.get("cp0")) or (o != null and (o.type == "intercept" or o.type == "hunt")): return
	var bossDown = false
	if jt(B.get("cfg")) and B["cfg"].get("kind") == "boss":
		bossDown = true
		for u in B["units"]:
			if jt(u.get("boss")) and u["side"] == "enemy" and not jt(u.get("dead")): bossDown = false
	if bossDown or sideCP("enemy") <= B["cp0"]["enemy"] * 0.35:
		B["over"] = "win"; B["routed"] = true; logm("The flagship is gone. Its escorts break and flee." if bossDown else "The enemy fleet breaks and flees.", "s")

# ======================= orders, commands, abilities =======================
func canOrder(u, o) -> bool:
	if jt(u.get("dead")) or jt(u.get("order")) or jt(u.get("braced")): return false
	if o == "full": return not jt(u.get("moved")) and not jt(u.get("isSq"))
	if o == "lock": return true
	if o == "helm": return not jt(u.get("isSq")) and not jt(u.get("noTurn"))
	if o == "brace":
		if jt(u.get("isSq")): return false
		if TB.FAC_GATES.has(u.get("fac")) and jt(TB.FAC_GATES[u["fac"]].get("noBrace")): return false
		for w in u["weapons"]:
			if jt(w.get("fired")) and w["k"] != "flak": return false
		return true
	return false
func giveOrder(u, o) -> void:
	_giveOrder_raw(u, o); hook("order", u)
func _giveOrder_raw(u, o) -> void:
	if jt(B.get("usage")) and u["side"] == "player": B["usage"]["ord"][o] = z0(B["usage"]["ord"].get(o)) + 1
	if not canOrder(u, o): return
	u["order"] = o
	emit({"t": "order", "unit": u["id"], "order": o})
	if o == "brace":
		fstat(u["fac"], "braces"); u["braced"] = true; u["mp"] = 0; flt(u, "Braced", "#7fd6c8", -24)
		for w in u["weapons"]: w["fired"] = true
		braceCover(u)
		if jt(u["fx"].get("bastion")) and u["shMax"] > 0:
			var ns = []
			for x in u["sh"]: ns.append(u["shMax"])
			u["sh"] = ns; boonFx(u, "d_bastion", "shields full", -44)
	if o == "full":
		u["fullAhead"] = true; u["noTurn"] = true; u["mp"] = u["mp"] + ceil(u["mp"] * 0.5)
	if o == "lock":
		u["lockOn"] = true; u["mp"] = 0
	if o == "helm": u["turnsLeft"] = u["turnsLeft"] + 1
	logm(String(u["name"]) + ": " + String(ORDERS[o]["n"]) + ".", pp(u))
func abilityCd(u) -> float: return max(1, ABILITIES[u["ab"]]["cd"] - z0(u["fx"].get("cdMod")))
func liveFrom(u) -> Callable:
	var b0 = B; var ep = z0(B.get("epoch")) if B != null else 0
	return func(): return is_same(B, b0) and (z0(B.get("epoch")) if B != null else 0) == ep and (u == null or not jt(u.get("dead")))
func cmdDesc(c, tier, fac) -> String:
	if c == null: return ""
	var v = cmdPow(c["id"], tier); var car = "brood" if fac == "chorus" else "carrier"; var sq = "swarm" if fac == "chorus" else "squadron"
	var pct = func(x): return ns(JSM.jsround(x * 100.0)) + "%"
	match c["id"]:
		"barrage": return "Every ship fires a free extra volley right now at the best target in range" + ((", with +" + pct.call(v) + " damage") if jt(v) else "") + ". Its normal shots this round still happen."
		"hunt": return "Torpedoes reload at once and every ship deals +" + pct.call(v) + " damage for the rest of this round."
		"scramble": return "Every " + car + " launches " + ("two extra wings" if tier >= 2 else "an extra wing") + " right now, even past its limit. Then every " + sq + " you have makes a bonus attack immediately, with +" + pct.call(v) + " damage."
		"iron": return ("Your ships take " + pct.call(v + 0.1) + " less hull damage for the rest of this round.") if (fac == "chorus" or fac == "deathless") else ("All shields refill and your ships take " + pct.call(v) + " less hull damage for the rest of this round.")
		"restore": return "Every ship repairs " + pct.call(v) + " of its hull right now."
		"surge": return "Every ship gains +" + ns(v) + " movement and " + ("+2 turns" if tier >= 2 else "+1 turn") + " this round, and enemy fire loses 20 accuracy against you."
	return String(c.get("d")) if jt(c.get("d")) else ""
func bossCmdText(c, fac) -> String: return cmdDesc(c, 1, fac).replace("your ships", "its ships").replace("against you", "against them").replace("Every ship", "Every enemy ship")
func cmdTier() -> float:
	if B == null or B["round"] < 1: return 0.0
	var bonus = 0; var lost = 0
	for u in B["units"]:
		if u["side"] == "player" and not jt(u.get("dead")) and jt(u.get("fx")) and jt(u["fx"].get("cmdTier")): bonus = 1
		if u["side"] == "player" and not jt(u.get("isSq")) and not jt(u.get("transport")) and jt(u.get("dead")): lost = 1
	return max(0, min(2, B["round"] - 1 + bonus + lost - (1 if heatOn("h_cmd") else 0)))
func commandFor(side):
	if side != "player": return null
	if RUN != null and jt(RUN.get("cmdOverride")): return RUN["cmdOverride"]
	var id = RUN["admiral"] if RUN != null and jt(RUN.get("admiral")) else "vex"; var a = ADMIRALS.get(id)
	if a != null and jt(a.get("cmd")): return a["cmd"]
	return COMMANDS[id] if COMMANDS.has(id) else COMMANDS["vex"]
func canCommand(side) -> bool: return B != null and not jt(B.get("over")) and side == "player" and commandFor(side) != null and B["round"] >= 1 and not jt(B.get("cmdUsed"))
func useCommand(side) -> bool:
	if not canCommand(side): return false
	var c = commandFor(side); var tier = cmdTier(); B["cmdUsed"] = true; B["cmd"] = {"id": c["id"], "side": side, "round": B["round"], "tier": tier}
	if jt(B.get("usage")) and side == "player": B["usage"]["cmd"] = B["usage"]["cmd"] + 1
	logm("Admiral's Command" + ((" at power " + ns(tier + 1) + " of 3") if jt(tier) else "") + ": " + String(c["n"]) + ". " + cmdDesc(c, tier, RUN["fac"] if (RUN != null and jt(RUN.get("fac"))) else "voidsworn"), "p" if side == "player" else "e")
	emit({"t": "command", "side": side, "id": c["id"], "tier": tier, "unit": null})
	var ok = runCommand(side, c, tier); hook("command " + side); return ok
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
		if B["round"] >= 2 or boss["hp"] < boss["maxHp"] * 0.6:
			B["cmdENext"] = B["round"] + 1; flt(boss, "Preparing: " + String(c["n"]), "#ff8a6a", -56); logm(String(boss["name"]) + " is preparing " + String(c["n"]) + ". " + bossCmdText(c, boss["fac"]) + " It strikes next round.", "e")
			emit({"t": "command_warning", "side": "enemy", "id": c["id"], "round": B["cmdENext"], "unit": boss["id"]})
func bossCmdFire() -> void:
	if B == null or jt(B.get("over")) or jt(B.get("cmdEUsed")) or B.get("cmdENext") == null or B["round"] < B["cmdENext"]: return
	var boss: Variant = null
	for u in B["units"]:
		if u["side"] == "enemy" and jt(g(u.get("t"), "boss")) and not jt(u.get("dead")): boss = u; break
	if boss == null:
		B["cmdEUsed"] = true; return
	var c = BOSS_CMD[boss["fac"]]
	B["cmdEUsed"] = true; B["cmdE"] = {"id": c["id"], "side": "enemy", "round": B["round"], "tier": 1}; logm(String(boss["name"]) + ": " + String(c["n"]) + "!", "e")
	emit({"t": "command", "side": "enemy", "id": c["id"], "tier": 1, "unit": boss["id"]})
	runCommand("enemy", c, 1)
func runCommand(side, c, tier) -> bool:
	var foe = "enemy" if side == "player" else "player"; var bStart = B
	for u in caps(side): flt(u, String(c["n"]), "#e8c66a" if side == "player" else "#ff8a6a", -44)
	if c["id"] == "barrage":
		var b0 = B; var live = liveFrom(null); B["volleyMul"] = {"side": side, "m": 1.0 + cmdPow("barrage", tier)}
		for u in caps(side):
			if jt(B.get("over")) or not live.call(): break
			var keep = []
			for w in u["weapons"]: keep.append([w.get("fired"), w.get("cdLeft")])   # B-20 refits lack both; restored as undefined
			var pf = [u.get("postFire"), u.get("postMp")]
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
			u["postFire"] = pf[0]; u["postMp"] = pf[1]
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
				var fixed = 0
				for k in u["sec"].keys():
					if repairSection(u, k, rp): fixed += 1
				if fixed != 0: flt(u, (ns(fixed) + " sections restored") if fixed > 1 else "Section restored", "#8ff0a0", -34)
			flt(u, "+" + ns(JSM.jsround(u["maxHp"] * rp)) + " hull", "#8ff0a0", -20)
	if c["id"] == "surge":
		for u in caps(side):
			u["mp"] = z0(u.get("mp")) + cmdPow("surge", tier); u["turnsLeft"] = z0(u.get("turnsLeft")) + (2 if tier >= 2 else 1)
	if c["id"] == "scramble":
		var cars = []
		for u in alive(side):
			if u.get("ab") == "launch": cars.append(u)
		for u in cars:
			var hs = launchHexes(u)
			if hs.size() == 0: continue
			var fs = alive(foe)
			JSM.ssort(hs, func(a, b2): return _mind(a, fs) - _mind(b2, fs))
			var k = 0
			while k < (2 if tier >= 2 else 1) and k < hs.size():
				makeWing(u, hs[k], wingKind(u)); k += 1
		for sq in alive(side):
			if not jt(sq.get("isSq")): continue
			sq["activated"] = false; sq["mp"] = sq["speed"]
			for w in sq["weapons"]:
				w["fired"] = false; w["cdLeft"] = 0
		swarmPhase(side)
	if is_same(B, bStart): checkEnd()
	return true
func _mind(h, fs: Array, cap = null) -> float: # Math.min(...fs.map(f=>hdist(h,f))), or Math.min(cap, ...)
	var m = INF if cap == null else float(cap)
	for f in fs: m = min(m, hdist(h, f))
	return m
func inThisBattle(u) -> bool: return B != null and u != null and JSM.has_same(B["units"], u)
func makeWing(u, h, kind) -> Dictionary:
	var fx = sumFx(fleetFxList()) if u["side"] == "player" else {}
	var sq = makeUnit(u["side"], kind, {"parent": u["id"], "fac": u["fac"], "sqPct": z0(u["fx"].get("sqPct")), "sqHp": z0(fx.get("sqHp")), "scale": (1.0 + 0.1 * (B["sector"] - 1)) if u["side"] == "enemy" else 1})
	var pk = wingPerks(u)
	if pk.has("aces"): sq["aim"] = sq["aim"] + 10
	if pk.has("jinkers"): sq["ev"] = sq["ev"] + 8
	if pk.has("armored"):
		sq["maxHp"] = JSM.jsround(sq["maxHp"] * 1.25); sq["hp"] = sq["maxHp"]
	sq["fac"] = u["fac"]; sq["q"] = h.q; sq["r"] = h.r; sq["facing"] = u["facing"]
	var tn = String(u["t"]["n"]).split(" "); sq["name"] = String(HULLS[kind]["n"]) + " (" + (String(u["name"]) if u["side"] == "player" else tn[tn.size() - 1]) + ")"
	B["units"].append(sq)
	emit({"t": "wing", "unit": sq["id"], "parent": u["id"], "kind": kind, "q": int(h.q), "r": int(h.r)})
	return sq
func deployWings() -> void:
	var carriers = []
	for x in B["units"]:
		if (x.get("ab") == "launch" or jt(g(x.get("fx"), "hive"))) and not jt(x.get("dead")) and not jt(x.get("isSq")): carriers.append(x)
	for u in carriers:
		var foes = alive("enemy" if u["side"] == "player" else "player"); var sec = B["sector"] if jt(B.get("sector")) else 1; var bossWings: bool = u["side"] == "enemy" and jt(u["t"].get("boss"))
		u["spare"] = max(0, sec - 1) if bossWings else (99 if jt(g(u.get("fx"), "endless")) else z0(u.get("hangar")) + (1 if wingPerks(u).has("reserve") else 0))
		var n = min(z0(u.get("hangar")), sec) if bossWings else z0(u.get("hangar"))
		for i in range(int(n)):
			var hs = launchHexes(u)
			if hs.size() == 0: break
			JSM.ssort(hs, func(a, b): return _mind(a, foes, 99) - _mind(b, foes, 99))
			makeWing(u, hs[0], wingKind(u, i))
	if jt(B.get("adaptWings")):
		var foes = alive("player"); var hosts = []
		for x in alive("enemy"):
			if not jt(x.get("isSq")) and not jt(x.get("transport")): hosts.append(x)
		JSM.ssort(hosts, func(a, b): return (0 if jt(b["t"].get("boss")) else (b["t"]["cp"] if jt(b["t"].get("cp")) else 1)) - (0 if jt(a["t"].get("boss")) else (a["t"]["cp"] if jt(a["t"].get("cp")) else 1)))
		var i = 0
		while i < B["adaptWings"] and hosts.size() > 0:
			var h = hosts[i % hosts.size()]; var hs = launchHexes(h)
			if hs.size() > 0:
				JSM.ssort(hs, func(a, b): return _mind(a, foes, 99) - _mind(b, foes, 99))
				makeWing(h, hs[0], "fighter")
			i += 1
func wingKind(u, i = null):
	var set_ = g(FACTIONS.get(u["fac"]), "sq"); var own = set_ if jt(set_) else "fighter"
	if own != "fighter": return own
	if jt(set_) and u["side"] == "enemy": return own
	var foe = "enemy" if u["side"] == "player" else "player"; var air = false
	for x in B["units"]:
		if not jt(x.get("dead")) and x["side"] == foe and (jt(x.get("isSq")) or x.get("ab") == "launch"): air = true
	if not air: return "bomber"
	var have = squadronsOf(u); var nb = 0
	for x in have:
		if x["t"].get("sq") != "fighter": nb += 1
	var nf = have.size() - nb
	if i != null: return "fighter" if int(i) % 2 != 0 else "bomber"
	return "bomber" if nb <= nf else "fighter"
const SQ_LEASH = 8
func sqRole(s) -> String: return "fighter" if s["t"].get("sq") == "fighter" else "bomber"
func sqWants(s, t) -> bool:
	if jt(t.get("dead")) or t["side"] == s["side"]: return false
	if sqRole(s) == "bomber": return not jt(t.get("isSq"))
	for x in alive(t["side"]):
		if jt(x.get("isSq")): return jt(t.get("isSq"))
	return true
func sqValue(t, e, s) -> float:
	var v = e.hull + e.shield * 0.3
	if e.hull >= t["hp"]: v += 25
	if jt(t.get("isSq")) and sqRole(t) == "bomber": v *= 1.5
	if s != null and s["side"] == "enemy" and B.get("aiFocus") != null and is_same(t, B["aiFocus"]) and aiVet(): v *= 1.3
	if s != null and (s["side"] == "player" or aiVet()) and sqObjNear(t): v += 6
	return v + (1.0 - float(t["hp"]) / t["maxHp"]) * 10.0
func sqObjNear(t) -> bool:
	var o = B.get("obj") if B != null else null
	if o == null: return false
	if o.type == "defend" and o.get("hex") != null: return hdist(t, o.hex) <= 3
	if o.type == "intercept":
		for x in B["units"]:
			if jt(x.get("transport")) and not jt(x.get("dead")) and hdist(x, t) <= 3: return true
	return false
func sqOrder(s):
	var o = s.get("wingOrder")
	if not jt(o): return null
	var t = null
	for x in B["units"]:
		if x["id"] == o["id"]:
			t = x; break
	if t == null or jt(t.get("dead")) or t["side"] == s["side"]:
		s["wingOrder"] = null; return null
	return {"kind": o["kind"], "t": t}
func sqPlan(s):
	var ord = sqOrder(s); var foes = []
	for t in alive("enemy" if s["side"] == "player" else "player"):
		if sqWants(s, t) or (ord != null and ord.kind == "strike" and is_same(ord.t, t)): foes.append(t)
	if foes.size() == 0: return null
	var carrier = null
	for x in B["units"]:
		if x["id"] == s.get("parent") and not jt(x.get("dead")):
			carrier = x; break
	var ready = readyList(s); var states = computeReach(s).states; var here = {"q": s["q"], "r": s["r"], "f": s["facing"], "cost": 0, "stay": true}
	var stc = null if ord != null else wingStance(s)
	var guard = ord.t if (ord != null and ord.kind == "guard") else (carrier if (stc == "screen" and carrier != null) else null)
	var lim = SQ_LEASH + (2 if (ord != null and ord.kind == "strike") else 0) + (TB.WING_HUNT_LEASH if stc == "hunt" else 0)
	var gr = (TB.WING_SCREEN_R + 1) if stc == "screen" else 3
	var leashOK = func(v): return hdist(v, guard) <= gr if guard != null else (carrier == null or hdist(v, carrier) <= lim)
	var best = null
	eval_begin()
	for st in [here] + states:
		var v = stateView(s, st)
		if not leashOK.call(v): continue
		for t in foes:
			for w in ready:
				if not inReach(v, w, t): continue
				var val = sqValue(t, expectedVs(v, w, t), s) - z0(st.get("cost")) * 0.01
				if ord != null and ord.kind == "strike" and is_same(ord.t, t): val = val * 3 + 60
				if guard != null and hdist(t, guard) <= 3: val = val * 2 + 20
				if stc == "screen" and jt(t.get("isSq")): val *= 2
				if stc == "hunt" and not jt(t.get("isSq")) and t["hp"] < t["maxHp"] / 2.0: val *= 1.6
				if best == null or val > best.val: best = {"st": st, "t": t, "val": val, "attack": true}
	eval_end()
	if best != null: return best
	if guard != null:
		var hm = null; var hd = hdist(s, guard)
		for st in states:
			var d = hdist(stateView(s, st), guard)
			if d < hd or (d == hd and hm == null):
				hd = d; hm = st
		return {"st": hm, "t": null, "attack": false} if (hm != null and hd < hdist(s, guard)) else null
	if ord != null and ord.kind == "strike":
		var T = ord.t; var PFo = pathField([T]); var mv = null; var md = fieldDist(PFo, s, hdist(s, T))
		for st in states:
			var v = stateView(s, st)
			if carrier != null and hdist(v, carrier) > lim: continue
			var d = fieldDist(PFo, v, hdist(v, T))
			if d < md:
				md = d; mv = st
		if mv != null: return {"st": mv, "t": T, "attack": false}
	var T = foes[0]
	for t in foes:
		if hdist(s, t) < hdist(s, T): T = t
	var PFs = pathField([T]); var mv = null; var md = fieldDist(PFs, s, hdist(s, T))
	for st in states:
		var v = stateView(s, st)
		if not leashOK.call(v): continue
		var d = fieldDist(PFs, v, hdist(v, T))
		if d < md:
			md = d; mv = st
	if mv != null: return {"st": mv, "t": T, "attack": false}
	if carrier != null:
		var hm = null; var hd = hdist(s, carrier)
		for st in states:
			var d = hdist(stateView(s, st), carrier)
			if d < hd:
				hd = d; hm = st
		if hm != null: return {"st": hm, "t": null, "attack": false}
	return null
func sqAct(s) -> void:
	var live = liveFrom(s); var p = sqPlan(s)
	if p == null: return
	if not jt(p.st.get("stay")): moveUnit(s, p.st)
	if not live.call() or not p.attack or jt(s.get("dead")) or jt(p.t.get("dead")): return
	for i in range(s["weapons"].size()):
		if jt(p.t.get("dead")) or jt(s.get("dead")) or not live.call(): break
		if canFire(s, s["weapons"][i], p.t): fireWeapon(s, i, p.t)
func swarmPhase(side) -> void: # each wing runs under stallGuard in the game; headless it never stalls
	var b0 = B
	var l = []
	for x in alive(side):
		if jt(x.get("isSq")) and not jt(x.get("activated")): l.append(x)
	for sq in l:
		if not is_same(B, b0) or jt(B.get("over")): return
		emit({"t": "activation", "unit": sq["id"], "side": side})
		sqAct(sq); sq["activated"] = true
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
			if w["k"] == "torp" and (gt(w.get("cdLeft"), 0) or jt(w.get("fired"))): return true
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
func autoBlink(u):
	var hs = blinkHexes(u); var foes = []
	for x in alive("enemy" if u["side"] == "player" else "player"):
		if not jt(x.get("isSq")): foes.append(x)
	if hs.size() == 0 or foes.size() == 0: return null
	var hurt: bool = u["hp"] < u["maxHp"] * 0.35; var best = null; var bv = -1e9
	eval_begin()
	for h in hs:
		var v = -1e9
		for f in range(6):
			var st = stateView(u, {"q": h.q, "r": h.r, "f": f}); var o = evalOffense(st, readyList(u), foes); var th = evalThreat(st, foes)
			v = max(v, -th if hurt else o - th * 0.3)
		var near = _mind(h, foes); var val = v + (near * 2 if hurt else -near * 0.5)
		if val > bv:
			bv = val; best = h
	eval_end()
	return best
func launchHexes(u) -> Array:
	var occ = occMap(); var o = []
	for d in DIRS:
		var h = {"q": u["q"] + d[0], "r": u["r"] + d[1]}
		if onBoard(h.q, h.r) and not blocks(terr(h.q, h.r)) and not occ.has(hkey(h.q, h.r)): o.append(h)
	return o
func useAbility(u, arg = null) -> bool:
	var r = _useAbility_raw(u, arg); hook("ability", u); return r
func _useAbility_raw(u, arg = null) -> bool:
	if not inThisBattle(u) or not canAbility(u): return false
	if jt(B.get("usage")) and u["side"] == "player": B["usage"]["ab"][u["ab"]] = z0(B["usage"]["ab"].get(u["ab"])) + 1
	var a = u["ab"]
	emit({"t": "ability", "unit": u["id"], "ab": a, "hex": arg.get("hex") if arg is Dictionary else null})
	if a == "evasive":
		u["evBuff"] = 25; u["mp"] = u["mp"] + 2; flt(u, "Evasive", "#9fe3ff", -24)
	if a == "reload":
		for w in u["weapons"]:
			if w["k"] == "torp":
				w["cdLeft"] = 0; w["fired"] = false
		flt(u, "Tubes loaded", "#f0b35a", -24)
	if a == "focus":
		u["focus"] = true; flt(u, "Focus fire", "#f0b35a", -24)
	if a == "phase":
		u["evBuff"] = 25; u["mp"] = u["mp"] + 2; flt(u, "Phase shift", "#7dff9b", -24)
	if a == "frenzy":
		u["focus"] = true; flt(u, "Blood frenzy", "#ff8fe0", -24)
	if a == "overburn":
		u["mp"] = u["mp"] + 3; u["ramBoost"] = 1.5; flt(u, "Overburn", "#ffb35c", -24)
	if a == "regrow":
		var h = min(u["maxHp"] - u["hp"], JSM.jsround(u["maxHp"] * 0.25)); u["hp"] = u["hp"] + h; flt(u, "+" + ns(h) + " hull", "#8ff0a0", -24)
	if a == "reclaim":
		var ts = []
		for x in alive(u["side"]):
			if not jt(x.get("isSq")) and hdist(x, u) <= 3 and x["hp"] < x["maxHp"]: ts.append(x)
		JSM.ssort(ts, func(p, q): return float(p["hp"]) / p["maxHp"] - float(q["hp"]) / q["maxHp"])
		if ts.size() > 0:
			var t = ts[0]; var h = min(t["maxHp"] - t["hp"], JSM.jsround(t["maxHp"] * 0.2)); t["hp"] = t["hp"] + h; flt(t, "+" + ns(h) + " hull", "#7dff9b", -24)
			logm(String(u["name"]) + " reanimates " + ("its own hull" if is_same(t, u) else String(t["name"])) + " for " + ns(h) + ".", pp(u))
	if a == "ionpulse":
		var nf = 0
		for t in alive("enemy" if u["side"] == "player" else "player"):
			if not jt(t.get("isSq")) and hdist(t, u) <= 4:
				nf += 1
				if t.get("sh") != null:
					var nsh = []
					for x in t["sh"]: nsh.append(floor(x * 0.5))
					t["sh"] = nsh
		flt(u, "Ion pulse", "#9fd4ff", -24)
		logm(String(u["name"]) + " fires an ion pulse: " + ns(nf) + " enemy ship" + ("" if nf == 1 else "s") + " lose half their shields.", pp(u))
	if a == "blink":
		var h = arg["hex"] if (arg is Dictionary and jt(arg.get("hex"))) else autoBlink(u)
		var okh = false
		if h != null:
			for x in blinkHexes(u):
				if x.q == h.q and x.r == h.r:
					okh = true; break
		if h == null or not okh: return false
		var live = liveFrom(u); var from = {"q": int(u["q"]), "r": int(u["r"])}
		u["q"] = h.q; u["r"] = h.r; u["vis"] = null
		emit({"t": "blink", "unit": u["id"], "from": from, "to": {"q": int(h.q), "r": int(h.r)}}); hook("blink", u)
		if not live.call():
			u["abCd"] = abilityCd(u); return false
		flt(u, "Phase jump", "#9fe3ff", -24); objAfterMove(u)
	if a == "surge":
		for i in range(4): u["sh"][i] = u["shMax"]
		flt(u, "Shields surge", "#7fd6c8", -24)
		if u["st"]["shieldOff"] < 99: u["st"]["shieldOff"] = 0
	if a == "launch":
		var h = arg["hex"] if (arg is Dictionary and jt(arg.get("hex"))) else pick(launchHexes(u))
		var kind = arg["kind"] if (arg is Dictionary and jt(arg.get("kind"))) else wingKind(u)
		if u.get("spare") != null: u["spare"] = max(0, u["spare"] - 1)
		var sq = makeWing(u, h, kind); sq["mp"] = 0
		for w in sq["weapons"]: w["fired"] = true
		logm(String(u["name"]) + " launches a " + String(HULLS[kind]["n"]).to_lower() + ".", pp(u))
	if a == "nova":
		var c = arg["hex"]
		logm(String(u["name"]) + " fires its nova cannon.", pp(u))
		var live = liveFrom(u)
		hook("nova", u)
		if not live.call(): return false
		u["abCd"] = abilityCd(u)
		var hitList = []
		for x in alive():
			if hdist(x, c) <= 1: hitList.append(x)
		for x in hitList:
			var dmg = (40.0 if hdist(x, c) == 0 else 20.0) * u["dmg"] * (1.5 if jt(x.get("isSq")) else 1.0)
			var quad = shieldQuad(x, u)
			var r = applyHit(u, {"pierce": 0.3, "crit": 5}, x, dmg, quad)
			if jt(r.shield): flt(x, "−" + ns(r.shield), "#7fd6c8", -18)
			flt(x, "−" + ns(r.hull), "#ff7a6e", 0)
			logm("Nova blast hits " + String(x["name"]) + " for " + ns(r.hull) + " hull" + ((" and " + ns(r.shield) + " shields") if jt(r.shield) else "") + ".", pe(x))
			if x["hp"] <= 0: killUnit(x, u)
		return true
	u["abCd"] = abilityCd(u)
	if a != "launch": logm(String(u["name"]) + ": " + String(ABILITIES[a]["n"]) + ".", pp(u))
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
		var lw = _lw.get(p["id"]) if _evc else null
		if lw == null:
			lw = []
			for w in p["weapons"]:
				if gt(w.get("cdLeft"), 1) or gt(w.get("off"), 1) or not aiGunLive(p, w): continue
				lw.append(w)
			if _evc: _lw[p["id"]] = lw
		for w in lw:
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
	var br: float = braceMul(t)
	var take: float = max(0.15, br * guardMul(t) * cmdTaken(t))
	var shs = 0.0
	for x in t["sh"]: shs += x
	var ehp: float = t["hp"] / take + shs * 0.3; var n = 0
	for u in shooters:
		var rr = 0.0
		for w in u["weapons"]:
			if le(w.get("cdLeft"), 1) and le(w.get("off"), 1) and w["k"] != "flak" and w["r"] > rr: rr = w["r"]
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
	eval_begin()
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
	eval_end()
	return best
func evalThreat(v, foes: Array) -> float:
	var tot = 0.0
	for p in foes:
		if hdist(p, v) > 9: continue
		for w in p["weapons"]:
			if gt(w.get("cdLeft"), 1) or gt(w.get("off"), 1) or not aiGunLive(p, w): continue
			if hdist(p, v) > w["r"]: continue
			if not inArc(p, v, w["arc"]): continue
			var e = expectedVs(p, w, v); tot += e.hull + e.shield * 0.2
	return tot
func aiPickPrimary(u, ws: Array, focus) -> Variant: # with target hysteresis: keep last activation's primary while it is worth AI_STICK of the best
	var pv = 0.0; var primary: Variant = null; var lastV = 0.0
	var last = u.get("aiLastT")
	if last != null and (jt(last.get("dead")) or last["side"] == u["side"]): last = null
	for t in alive("player"):
		var sh = 0.0; var hull = 0.0
		for w in ws:
			if not canFire(u, w, t): continue
			var e = expectedVs(u, w, t); sh += e.shield * 0.3; hull += e.hull
		if sh == 0.0 and hull == 0.0: continue
		var val: float = (min(hull, t["hp"]) + sh) * (0.6 if jt(t.get("isSq")) else 1.1) + ((25.0 + t["maxHp"] * 0.15) if hull >= t["hp"] else 0.0) + (10.0 if (focus != null and is_same(t, focus)) else 0.0) + (1.0 - float(t["hp"]) / t["maxHp"]) * 15.0
		if last != null and is_same(t, last): lastV = val
		if val > pv: pv = val; primary = t
	if last != null and lastV > 0 and lastV >= pv * TB.AI_STICK: primary = last
	if primary != null: u["aiLastT"] = primary
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
	if pre and u.get("ab") == "launch" and canAbility(u):
		var hs = launchHexes(u)
		JSM.ssort(hs, func(a, b): return _mind(a, foes) - _mind(b, foes))
		useAbility(u, {"hex": hs[0]})
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
				if w["k"] == "torp" and eqn(w.get("off"), 0) and not weaponReady(w):
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
	if u.get("ab") == "blink" and canAbility(u) and nearF != null:
		var go = false
		if pre:
			if u["hp"] < u["maxHp"] * 0.35 and evalThreat(u, foes) > u["hp"] * 0.3: go = true
			else:
				var any = false
				for w in u["weapons"]:
					if not weaponReady(w): continue
					for f in foes:
						if hdist(u, f) <= w["r"] + (u["speed"] if jt(u.get("speed")) else 2):
							any = true; break
					if any: break
				go = not any
		else: go = mode == "escape" and u["hp"] < u["maxHp"] * 0.35 and evalThreat(u, foes) > u["hp"] * 0.3
		if go:
			useAbility(u)
			if not live.call(): return false
	return live.call()
func aiAfterFire(u, live: Callable, runner) -> bool:
	if not jt(u.get("isSq")) and not jt(runner) and not jt(u.get("dead")): tacticRam(u)
	if jt(B.get("over")) or jt(u.get("dead")) or not live.call(): return false
	if not jt(u.get("isSq")) and not jt(runner) and canFade(u):
		fadeMove(u)
		if jt(B.get("over")) or jt(u.get("dead")) or not live.call(): return false
	return aiAbilities(u, live, "escape") and not jt(B.get("over"))
func aiUnit(u) -> void:
	if jt(u.get("isSq")):
		if not jt(B.get("over")) and not jt(u.get("dead")) and u["side"] == "enemy": sqAct(u)
		return
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
	eval_begin()
	for s in states:
		var v = stateView(u, s)
		var vet = vet0; var focus = focus0
		var off = evalOffenseVet(v, ready, foes, focus) if vet else evalOffense(v, ready, foes)
		var threat = evalThreatVet(v, foes) if vet else evalThreat(v, foes)
		var prof = FACTION_AI[u["fac"]] if (not jt(u.get("isSq")) and jt(FACTION_AI.get(u["fac"]))) else FACTION_AI["voidsworn"]
		var tw: float = (0.15 if jt(u.get("isSq")) else (0.3 if not vet else (0.65 if jt(u.get("flagship")) else aiHurtW(u, prof)))) * prof["tw"]
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
		if not jt(u.get("isSq")):
			score -= torpThreat(u, v) * 0.9; score -= syncPull(u, v) * (2.0 if vet else 1.2)
		if jt(B.get("obj")) and B["obj"].type == "hold" and not jt(u.get("isSq")) and not vet: score -= hdist(v, B["obj"].hex) * 1.6
		score += aiObjScore(u, v); score += aiWellScore(u, v)
		if score > bestScore:
			bestScore = score; best = s
	eval_end()
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
