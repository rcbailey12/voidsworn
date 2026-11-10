# Voidsworn battle rules, ported line for line from data.js, core.js and battle.js (A3 parity spike, Oct 25 2026).
# Objects stay Dictionaries with the JS field names, so the golden records compare field by field. Numbers stay doubles like JS
# (division always with a float operand, Math.round through JSM.jsround, % on doubles through fmod).
# Async rules functions run synchronously: in the headless game every await resolves at once and every call is awaited in turn,
# except deaths queued by turn ticks (fire, acid, the Hollow Sun, station guns), whose tail runs later in JS; those tails are deferred
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
var ROCK_KINDS; var REGION_BIOME; var COMMANDS; var SEC_NAME; var QUAD_NAME; var FNAMES; var LINEAGE_TREES; var TREE_FX
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
	LINEAGE_TREES = TB.get("LINEAGE_TREES", {}); TREE_FX = TB.get("TREE_FX", {})
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
	_evc = true; _los.clear(); _guard.clear(); _tc.clear(); _hc.clear(); _lw.clear(); _slot.clear(); _ev.clear()
	if B != null:
		for i in range(B["units"].size()): _slot[B["units"][i]["id"]] = i
func eval_end() -> void:
	_evc = false; _los.clear(); _guard.clear(); _tc.clear(); _hc.clear(); _lw.clear(); _slot.clear(); _ev.clear()
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
	for k in o.keys():
		if TB.FX_CAPS.has(k): o[k] = min(o[k], TB.FX_CAPS[k])
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
		if not jt(u.get("dead")) and not jt(u.get("treeOff")) and (side == null or u["side"] == side): o.append(u)  # treeOff: a reserve held off the field (Thale B1b)
	return o
func caps(side) -> Array:
	var o = []
	for u in alive(side):
		if not jt(u.get("isSq")): o.append(u)
	return o
func unitAt(q, r) -> Variant:
	for u in B["units"]:
		if not jt(u.get("dead")) and not jt(u.get("treeOff")) and u["q"] == q and u["r"] == r: return u
	return null
func occMap() -> Dictionary:
	var m = {}
	for u in B["units"]:
		if not jt(u.get("dead")) and not jt(u.get("treeOff")): m[hkey(u["q"], u["r"])] = u
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
	if cfg == null or (cfg.get("teachingGate") == true and cfg.get("teachingBattle") == 1) or cfg.get("kind") == "boss": return null
	if cfg.get("teachingGate") == true and cfg.get("teachingBattle") == 2: force = "reinf_enemy"
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
		if side == "enemy" and jt(B.get("nem")): nemSig("reinforce")   # R42: a Hegemony Nemesis's reinforcements
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
	if jt(opt.get("edgeFeature")):
		var hs = boardHexes().filter(func(h): return onBoard(h.q, h.r))
		var r = hs.map(func(h): return h.r).min() + 1
		var c = offToAx(floori(BW / 2.0), r)
		var feature = "station" if opt.get("enc") == "defend" else "rock"
		for h in [c, {"q": c.q + 1, "r": c.r}, {"q": c.q, "r": c.r + 1}]:
			if onBoard(h.q, h.r): T[hkey(h.q, h.r)] = feature
		if feature == "station": TERRAIN_META["station"] = c
		TERRAIN_META["shape"] = "open"
		return T
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
			u["hp"] = 0; logm(String(u["name"]) + " is torn apart by the Hollow Sun's gravity.", pe(u)); u["killCause"] = "tidal"; queueDeath(u, dq); return "dead"
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
	if shape == "open" and not jt(cfg.get("edgeFeature")) and B0small(cfg) and ["rout", "hunt", "ambush"].has(enc): shape = "compact"
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
	if shape == "deadstar" and (jt(cfg.get("noStar")) or ["belt", "station", "planet"].has(map)) and not jt(cfg.get("keepShape")):   # R1: cfg.noStar (campaign sector 1) never fields the dead star
		var sh = []
		for x in (ENCOUNTERS[enc] if ENCOUNTERS.has(enc) else ENCOUNTERS["rout"])["shapes"]:
			if x != "deadstar": sh.append(x)
		shape = pick(sh if sh.size() > 0 else ["open"])
	if ak != "strip" and AXIS_SHAPES.has(shape): shape = pick(["open", "dense", "shoals", "archipelago", "colossus", "ring"] if jt(cfg.get("noStar")) else ["open", "dense", "deadstar", "shoals", "archipelago", "colossus", "ring"])
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
	var topt = {"edgeFeature": jt(cfg.get("edgeFeature")), "cond": null if cfg.get("kind") == "boss" else sectorCond(), "stationAt": offToAx(9 + CX, midR) if enc == "defend" else null, "enc": enc, "pieces": pieces_by.get(map) if pieces_by.has(map) else null}
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
	B["tree"] = treeBuild(); B["treeStats"] = {}; B["treeChoices"] = cfg.get("treeChoices"); B["treePending"] = []; B["treeFlaw"] = null; B["treeLens"] = null; B["treeFlakSkip"] = null
	B["treeReserve"] = []; B["treePrey"] = null; B["treeNamedPrey"] = null; B["treeIronExtra"] = null; B["treeFiled"] = null; B["treePermFile"] = null
	B["treeOneVoiceUsed"] = 0; B["treeDrillUsed"] = 0; B["treeStrikeRound"] = 0; B["treeDebtRound"] = 0; B["treeForgeRound"] = 0
	B["tr"] = {"r": 1, "enemyShots": {}, "volleyHits": {}, "logged": {}, "falseHulls": 0, "glassUsed": 0, "firstLight": null, "volleyPick": {}, "carrierHit": {}, "wingsDebt": {}, "standardUsed": 0, "ledgerUsed": 0, "escortUsed": {}, "frameZeroUsed": 0, "targeted": {}, "targetedLast": {}, "iterKill": {}, "indexTarget": null, "swarmHitBy": {}, "volleyShips": {}, "volleyHit": {}, "burnStays": null, "firstThroatUsed": 0, "smileUsed": 0, "rearShips": {}, "wingStruck": {}, "hitRound": {}, "firstScarUsed": 0, "nothingSaved": 0, "scent": null, "bigId": null,
		"syncFirst": {"player": null, "enemy": null}, "secondVolleyUsed": 0, "secondVolleyAutoDone": 0, "rollingUsed": 0, "strikeSpeed": null, "strikeSpeedId": null, "crossHits": {}, "totalShips": {}, "hitDuringStrike": {}, "bellUsed": 0, "columnUsed": 0, "firstStopTarget": null, "firstStopDone": 0, "wingFiled": null, "escortScreen": 0, "beacon": null,
		"carrierLast": {}, "wingTgt": {}, "wingTargets": {}, "lightTgt": {}, "wingCap": {}, "wingCapFirst": {}, "grandUsed": 0, "grandTarget": null, "grandFirstDone": 0, "sunTarget": null, "sunFirstDone": 0, "oneLens": null, "fleetElsewhere": 0}
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
			var u = cand[i]; var rw = nameWeapons(u["fac"], [mkWeapon(pd, "T", u["fx"] if jt(u.get("fx")) else {})])[0]
			rw["fired"] = false; rw["cdLeft"] = 0; rw["off"] = 0; u["weapons"].append(rw); u["pdRefit"] = true   # B-21: the refit gun gets the per-battle fields, so it fires and intercepts wings
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
	treeBattleStart()
	deployWings()
	B["cp0"] = {"player": sideCP("player"), "enemy": sideCP("enemy")}
	B["usage"] = {"fire": {}, "aim": 0, "ab": {}, "ord": {}, "cmd": 0, "moves": 0, "cant": {}}
	setupObjective(cfg.get("obj"))
	setupFactionRules()
	if jt(cfg.get("nemesis")): applyNemesis(cfg["nemesis"])
	if jt(cfg.get("verb")): applyVerb(cfg["verb"])
	if jt(B.get("adapt")) or jt(B.get("adaptWings")):
		emit({"t": "adaptation", "source": "carrier_report"})
		var ad = B.get("adapt"); var aw = B.get("adaptWings")
		logm("Scouts report your carriers. The enemy " + (("bolted extra point defense onto " + (ns(ad) + " ships" if ad > 1 else "one ship")) if jt(ad) else "") + (" and " if (jt(ad) and jt(aw)) else "") + (("launched " + ("two fighter wings" if aw > 1 else "a fighter wing") + " to hunt your craft") if jt(aw) else "") + ".", "ember")
	startSideTurn("player")
	for u in alive("enemy"): u["intercepts"] = max(0, 2 - z0(u.get("treeFlakDown"))) if _has_flak(u) else 0
	var F = FACTIONS[cfg["fac"]]
	logm("Contact: " + String(F["n"]) + ". " + ns(eList.size()) + " ship" + ("s" if eList.size() > 1 else "") + " on the scanners.", "s")
	if jt(B.get("well")): logm("The Hollow Sun warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.", "ember")
	if cfg.get("kind") == "elite": logm("Elite captains command this fleet.", "e")
	if cfg.get("kind") == "boss": logm(String(HULLS[F["boss"]]["n"]) + " is here. Everything else is escort.", "e")
	for line in storyModifierLines(): logm(line, "ember")
func storyDamageMult(u) -> float:
	var m = B.get("cfg", {}).get("storyMods") if B != null else null
	if m == null or u["side"] != "player": return 1.0
	return (1.0 + float(z0(m.get("dmgPct")))) * (1.0 + float(TB.BEAT3_REWARDS.power) if jt(m.get("power")) and jt(u.get("pflag")) else 1.0)
func storyModifierLines(u = null) -> Array:
	var m = B.get("cfg", {}).get("storyMods") if B != null else null
	var out = []
	if m == null or (u != null and u["side"] != "player"): return out
	if jt(m.get("power")) and (u == null or jt(u.get("pflag"))): out.append("Flagship weapon damage +25% this battle.")
	if jt(m.get("dmgPct")): out.append("Fleet damage " + ("+" if m["dmgPct"] > 0 else "") + ns(JSM.jsround(float(m["dmgPct"]) * 100.0)) + "% this battle.")
	if jt(m.get("syncDown")): out.append("Synchronized fire off in round 1. Returns in round 2." if B["round"] == 1 else "Synchronized fire restored from round 2.")
	return out
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
	if side == "player": treeRoundStart()
	if side == "player" and B["round"] > 1:
		eventTick(); objectiveTick(deaths)
	if side == "enemy":
		aiRefreshFocus(); bossCmdTick()
	escortsBreak(); nemBreak()
	if side == "enemy":   # R42: a Corsair or Ithar Nemesis withdraws from a lost fight; a slow one shows it from round 2
		nemFleeCheck()
		if B["round"] >= 2 and jt(B.get("nem")): nemTrip("slow")
	if side == "enemy":
		for u in B["units"]:
			if u["side"] == "enemy" and not jt(u.get("dead")) and not jt(u.get("isSq")): aiStance(u)
	gainResolve(side, 1); var burned = false
	var risen = legionTurn(side)
	for u in B["units"]:
		if jt(u.get("dead")) or u["side"] != side: continue
		if jt(u.get("isSq")): u["activated"] = false
		u["braced"] = false; u["coverBy"] = null; u["postFire"] = false; u["postMp"] = 0; u["pivotUsed"] = false; u["lockOn"] = false; u["focus"] = false; u["fullAhead"] = false; u["noTurn"] = false; u["evBuff"] = 0; u["order"] = null; u["ramBoost"] = 0
		u["mp"] = max(1, u["speed"] - u["st"]["engine"]); u["turnsLeft"] = u["turns"]
		if side == "player" and u.get("burnCarry") != null:
			u["mp"] = u["mp"] + z0(u["burnCarry"].get("mp")); u["turnsLeft"] = u["turnsLeft"] + z0(u["burnCarry"].get("turns"))   # Grax capstone 1: the last burn carries over
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
		if jt(u.get("hullRegen")) and u["hp"] < u["maxHp"] and not jt(u.get("pyre")):
			u["hp"] = min(u["maxHp"], u["hp"] + u["hullRegen"]); treeMarkRepair(u)
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
		u["intercepts"] = max(0, 2 - z0(u.get("treeFlakDown"))) if _has_flak(u) else 0
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
	if side == "player" and not jt(B.get("over")): replaceWings(side)
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
func _sk(s) -> String:
	var base = hkey(s.q, s.r) + "," + str(int(s.f)) + "," + str(int(s.t))
	if s.get("passed") != null:
		var a = s["passed"].duplicate(); a.sort(); var pk = ""
		for x in a: pk += ("-" if pk != "" else "") + str(x)
		base += "|" + pk
	return base
func _passAdd(s, nq, nr) -> Array:
	var out = (s.get("passed") if s.get("passed") != null else []).duplicate()
	for e in alive("enemy"):
		if jt(e.get("isSq")): continue
		if hdist({"q": nq, "r": nr}, e) == 1 and not out.has(e["id"]): out.append(e["id"])
	out.sort()
	return out
func _friendlyNear2(u, q, r) -> bool:
	for x in alive("player"):
		if x["id"] != u["id"] and not jt(x.get("isSq")) and hdist({"q": q, "r": r}, x) <= 2: return true
	return false
func _reachAllowed(s, u, baseMP, mb, scar, loose, fwd) -> bool:
	var lim = baseMP + mb
	if scar: lim += min(2, (s.get("passed") if s.get("passed") != null else []).size())
	if loose and not _friendlyNear2(u, s.q, s.r): lim += 1.0
	if fwd and treePathTowardFlag(u, s): lim += 1.0
	return s.cost <= lim
func computeReach(u) -> Dictionary:
	var map = {}; var states = []
	var baseMP = postFireMp(u); var mb = treeMoveBonus(u)   # Razormaw T2a: +1 movement only for a move that ends closer to the named prey
	var scar = treeSkill("allScars") != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge")   # Grax T3a
	var loose = treeSkill("loosePack") != null and u["side"] == "player" and not jt(u.get("isSq"))   # Hullbreakers shared B1b
	var fwd = treeSkill("standardForward") != null and u["side"] == "player" and not jt(u.get("isSq")) and treeFlagUnit() != null   # Hegemony shared C1b
	var dive = treeSkill("mirrorAside") != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and not jt(u.get("treeDiveUsed"))   # Vell T2a
	var occ = occMap(); var R = moveRules(u); var MP = baseMP + mb + (2.0 if scar else 0.0) + (1.0 if loose else 0.0) + (1.0 if fwd else 0.0); var noOver = jt(u.get("postFire"))
	var start = {"q": u["q"], "r": u["r"], "f": u["facing"], "t": 0, "cost": 0, "path": [], "passed": ([] if scar else null)}
	var seen = {_sk(start): 0}; var queue = [start]; var qi = 0
	var pivotFree: bool = jt(R.get("pivot")) and not jt(u.get("pivotUsed"))
	while qi < queue.size():
		var s = queue[qi]; qi += 1
		if seen[_sk(s)] < s.cost: continue
		if not _reachAllowed(s, u, baseMP, mb, scar, loose, fwd): continue
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
				var dived = false
				if over != 0:
					if noOver: continue
					if over < 0 and dive and z0(s.get("dived")) == 0: dived = true
					else: c += R["over"]
				if s.cost + c > MP: continue
				var st = {"q": nq, "r": nr, "f": s.f}
				if kind != null: st[kind] = 1
				if kind == "slip": st["side"] = 1 if df == (sf + 1) % 6 else -1
				if over != 0: st["over"] = over
				if dived: st["dived"] = 1
				var pth: Array = s.path.duplicate(); pth.append(st)
				nexts.append({"q": nq, "r": nr, "f": s.f, "t": s.t, "cost": s.cost + c, "path": pth, "slips": z0(s.get("slips")) + (1 if kind == "slip" else 0), "revs": z0(s.get("revs")) + (1 if kind == "rev" else 0), "overs": z0(s.get("overs")) + (1 if over != 0 else 0), "dived": z0(s.get("dived")) + (1 if dived else 0), "passed": (_passAdd(s, nq, nr) if scar else null)})
		if not jt(u.get("isSq")) and not jt(u.get("noTurn")) and s.t < u["turnsLeft"]:
			var tc = 0 if (pivotFree and s.t == 0) else 1
			if s.cost + tc <= MP or tc == 0:
				for dd in [1, -1]:
					var f = (int(s.f) + dd + 6) % 6
					var pth: Array = s.path.duplicate(); pth.append({"q": s.q, "r": s.r, "f": f, "rot": true})
					nexts.append({"q": s.q, "r": s.r, "f": f, "t": s.t + 1, "cost": s.cost + tc, "path": pth, "slips": s.get("slips"), "revs": s.get("revs"), "overs": s.get("overs"), "passed": s.get("passed")})
		for n in nexts:
			var k = _sk(n)
			if seen.has(k) and seen[k] <= n.cost: continue
			seen[k] = n.cost; queue.append(n)
	var ok = []
	var prey = treePrey() if mb > 0.0 else null
	for s in states:
		if seen[_sk(s)] == s.cost and canEnd(u, s.q, s.r, occ) and (prey == null or s.cost <= baseMP or hdist({"q": s.q, "r": s.r}, prey) < hdist(u, prey)): ok.append(s)
	for s in ok:
		if s.q == u["q"] and s.r == u["r"]: continue
		var k = hkey(s.q, s.r); var c = map.get(k)
		if c == null or s.cost < c.cost or (s.cost == c.cost and s.t < c.t): map[k] = s
	return {"map": map, "states": ok}
func _commit(u, state, ctx: Dictionary) -> void:
	if ctx.committed: return
	ctx.committed = true
	var path: Array = state.path
	var fgC = treeFlagUnit() if treeSkill("standardForward") != null else null; var fgD0 = hdist(u, fgC) if fgC != null else 0.0
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
	if state.get("passed") != null and state["passed"].size() > 0: treeFx(u, "allScars", "the scars carry")   # Grax T3a
	for pD in path:
		if jt(pD.get("dived")): u["treeDiveUsed"] = 1; treeFx(u, "mirrorAside", "the mirror steps aside"); break   # Vell T2a
	if z0(u.get("treeWarlord")) == 1: u["treeWarlord"] = 2; u["mp"] = u["mp"] + state.cost; u["postMp"] = max(z0(u.get("postMp")), state.cost)   # Grax capstone 2: the flagship regains its run once
	if jt(B.get("usage")) and u["side"] == "player" and not jt(u.get("isSq")): B["usage"]["moves"] = B["usage"]["moves"] + 1
	treeAfterMove(u)
	if fgC != null: treeMoveTowardFlag(u, path, fgD0)
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
	if u["side"] == "enemy" and not jt(u.get("isSq")): treePatrolStrike(u)
	if ctx.committed:
		treeHeldFire(u); objAfterMove(u); return
	_commit(u, state, ctx)
	treeHeldFire(u)
	objAfterMove(u)

func freePivot(u) -> bool: return jt(moveRules(u).get("pivot")) and not jt(u.get("pivotUsed"))
func canRotate(u) -> bool: return not jt(u.get("dead")) and not jt(u.get("isSq")) and not jt(u.get("noTurn")) and (u["turnsLeft"] > 0 or z0(u.get("treeFreeTurn")) > 0) and (u["mp"] > 0 or freePivot(u) or z0(u.get("treeFreeTurn")) > 0) and not jt(u.get("braced"))
func rotateUnit(u, dir) -> void:
	if not canRotate(u) or not inThisBattle(u): return
	var live = liveFrom(u); var f = (int(u["facing"]) + int(dir) + 6) % 6
	var freeTurn = z0(u.get("treeFreeTurn")) > 0
	if freeTurn: u["treeFreeTurn"] = 0
	elif freePivot(u): u["pivotUsed"] = true
	else: u["mp"] = u["mp"] - 1
	if not freeTurn: u["turnsLeft"] = u["turnsLeft"] - 1; u["moved"] = true
	else: u["moved"] = true
	emit({"t": "move", "unit": u["id"], "path": [{"q": int(u["q"]), "r": int(u["r"]), "f": f, "rot": true}], "late_fire": false}); hook("rotate", u)
	if not live.call(): return
	u["facing"] = f
	treeAfterMove(u)
# ======================= B3 faction identity, travelling torpedoes, B4 Nemesis, verbs, wing doctrines, v54 doctrines =======================
func canFade(u) -> bool: return u["fac"] == "ithar" or jt(g(u.get("fx"), "fade"))
func treeFullFade(u) -> bool: return treeSkill("splitThree") != null and u != null and u["side"] == "player" and not jt(u.get("isSq")) and not jt(u.get("dead")) and cmdActive(u["side"], "surge")   # Vell T2b
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
	if B.get("tree") != null and B["tree"].size() > 0 and (treeSkill("wideNet") != null or treeSkill("livingRelay") != null):
		var sr = B["syncR"].duplicate() if B.get("syncR") is Dictionary else {}
		sr["player"] = treeHegSyncR(); B["syncR"] = sr
		var fgH = null
		for uH in B["units"]:
			if uH["side"] == "player" and jt(uH.get("anchor")) and not jt(uH.get("dead")): fgH = uH; break
		if fgH == null:
			for uH in B["units"]:
				if uH["side"] == "player" and jt(uH.get("pflag")) and not jt(uH.get("dead")): fgH = uH; break
		if treeSkill("wideNet") != null: treeFx(fgH, "wideNet", "the net reaches one hex further")
		if treeSkill("livingRelay") != null: treeFx(fgH, "livingRelay", "the relay doubles the radius")
func syncAnchor(side):
	if B == null or B.get("syncMark") == null or (B.get("syncLost") != null and jt(B["syncLost"].get(side))): return null
	for u in B["units"]:
		if jt(u.get("anchor")) and u["side"] == side and not jt(u.get("dead")): return u
	return null
func syncR(side): return B["syncR"][side] if (B != null and B.get("syncR") != null and jt(B["syncR"].get(side))) else TB.SYNC_R
func syncDmg(side): return B["syncDmg"][side] if (B != null and B.get("syncDmg") != null and jt(B["syncDmg"].get(side))) else TB.SYNC_DMG
func inSync(u) -> bool:
	if u == null or jt(u.get("isSq")) or u.get("fac") != "hegemony" or jt(u.get("dead")): return false
	if u["side"] == "player" and B["round"] == 1 and jt(B.get("cfg", {}).get("storyMods", {}).get("syncDown")): return false
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
	if B.get("tr") != null and B["tr"].get("syncFirst") != null and B["tr"]["syncFirst"].get(u["side"]) == null: B["tr"]["syncFirst"][u["side"]] = {"id": t["id"], "r": B["round"]}   # Kassar T1b
func syncLose(t) -> void:
	if B == null or t == null or not jt(t.get("anchor")) or B.get("syncLost") == null or jt(B["syncLost"].get(t["side"])): return
	var it = treeSkill("ironTempo")
	if it != null and t["side"] == "player" and B.get("tr") != null and not jt(B["tr"].get("ironTempoUsed")):
		var cands = []
		for u in alive("player"):
			if not is_same(u, t) and not jt(u.get("isSq")) and not jt(u.get("dead")) and u["fac"] == "hegemony": cands.append(u)
		JSM.ssort(cands, func(a, b):
			var d = b["maxHp"] - a["maxHp"]
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
		if cands.size() > 0:
			B["tr"]["ironTempoUsed"] = 1; t["anchor"] = false; cands[0]["anchor"] = true; treeFx(cands[0], "ironTempo", "the line finds a new anchor"); return
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
func applyNemesis(N) -> void: # battle.js applyNemesis (R42 and R49: traits, faction behaviour, duel fleet, honed, riches, artillery line, memory lines)
	B["nem"] = N; var es = []
	for u in B["units"]:
		if u["side"] == "enemy" and not jt(u.get("isSq")) and not jt(u.get("transport")): es.append(u)
	if es.size() == 0: return
	var NF = TB.NEM_FAC.get(N.get("fac")) if TB.NEM_FAC.get(N.get("fac")) != null else {"beh": {}}
	var beh = NF["beh"] if jt(NF.get("beh")) else {}
	var tr = N["traits"] if N.get("traits") != null else []
	var ad = N["adapt"] if N.get("adapt") != null else []
	var srt = es.duplicate(); JSM.ssort(srt, func(a, b): return _byCpHp(a, b)); var fl = srt[0]
	fl["nemFlag"] = true; fl["elite"] = true; fl["name"] = String(N["title"]) + " " + String(N["name"]); fl["dmg"] = fl["dmg"] * (1.0 + 0.1 * z0(N.get("scars")))
	if beh.get("strike") == "duel" and es.size() > 4: # R42 duelist (Ithar): at most four hulls
		var rest = []
		for u in es:
			if not is_same(u, fl): rest.append(u)
		JSM.ssort(rest, func(a, b): return (float(b["t"]["cp"]) if jt(b["t"].get("cp")) else 1.0) - (float(a["t"]["cp"]) if jt(a["t"].get("cp")) else 1.0))
		var keep = [fl] + rest.slice(0, 3)
		var nu = []
		for u in B["units"]:
			var par = null
			if jt(u.get("parent")):
				for x in B["units"]:
					if x["id"] == u["parent"]: par = x; break
			if u["side"] != "enemy" or jt(u.get("isSq")) or jt(u.get("transport")) or JSM.has_same(keep, u) or (par != null and JSM.has_same(keep, par)): nu.append(u)
		B["units"] = nu
		var es2 = []
		for u in es:
			if JSM.has_same(keep, u): es2.append(u)
		es = es2
	if beh.get("strike") == "duel":
		for u in es:
			if not jt(u.get("elite")):
				u["elite"] = true; u["aim"] = u["aim"] + 6; u["crit"] = u["crit"] + 5
	if beh.get("strike") == "duel" and jt(N.get("honed")): # R49: an Ithar who fled comes back honed
		var h = min(3, N["honed"])
		for u in es:
			u["aim"] = u["aim"] + 3 * h
			if u["shMax"] > 0:
				u["shMax"] = JSM.jsround(u["shMax"] * (1.0 + 0.1 * h)); var sh = []
				for _i in range(u["sh"].size()): sh.append(u["shMax"])
				u["sh"] = sh
	var nr = (z0(N.get("riches")) if beh.get("strike") == "raid" else 0) + (1 if ad.has("riches") else 0) # R42 Corsair riches (R49: only a Corsair)
	for _i in range(int(nr)):
		var hx = edgeHex("enemy")
		if hx == null: break
		var sct = B["sector"] if jt(B.get("sector")) else 1
		var x = makeUnit("enemy", cheapHull(fl["fac"]), {"scale": 1.0 + 0.12 * (sct - 1), "dmg": 1.0 + 0.08 * (sct - 1), "fac": fl["fac"]})
		x["q"] = hx.q; x["r"] = hx.r; x["facing"] = 3; B["units"].append(x); es.append(x)
	if fl["fac"] == "hegemony":
		for u in es: u["anchor"] = false
		fl["anchor"] = true
	if jt(beh.get("line")): # R42 Hegemony artillery line
		for u in es:
			if is_same(u, fl): continue
			for w in u["weapons"]:
				if w["k"] != "flak" and w["k"] != "sq": w["opt"] = w["opt"] + 1
	var fed: float = min(0.32, 0.04 * z0(N.get("fed")))
	for u in es:
		u["nem"] = true
		if nemWeak("board"):
			u["crewMax"] = max(4, JSM.jsround(u["crewMax"] * 0.7)); u["crew"] = min(u["crew"], u["crewMax"])
		if nemWeak("slow"): u["speed"] = max(1, u["speed"] - 1)
		for a in ad:
			if a == "shields" and u["shMax"] > 0:
				u["shMax"] = JSM.jsround(u["shMax"] * 1.2); var sh = []
				for _i in range(u["sh"].size()): sh.append(u["shMax"])
				u["sh"] = sh
			if a == "armor": u["armor"] = min(0.6, u["armor"] + 0.1)
			if a == "evasion": u["ev"] = u["ev"] + 8
			if a == "aim": u["aim"] = u["aim"] + 8
			if a == "veil": u["ev"] = u["ev"] + 6
			if a == "hunger": u["hullRegen"] = u["hullRegen"] + 3
			if a == "zeal": u["dmg"] = u["dmg"] + 0.08
		if tr.has("gunnery"): u["aim"] = u["aim"] + 6
		if tr.has("armored"): u["armor"] = min(0.6, u["armor"] + 0.08)
		if tr.has("swift"): u["speed"] = u["speed"] + 1
		if tr.has("deadeye"): u["crit"] = u["crit"] + 10
		if tr.has("veil"): u["ev"] = u["ev"] + 8
		if tr.has("regrowth"): u["hullRegen"] = u["hullRegen"] + 4
		if tr.has("veterans") or fed > 0:
			var k: float = 1.0 + (0.12 if tr.has("veterans") else 0.0) + fed
			u["maxHp"] = JSM.jsround(u["maxHp"] * k); u["hp"] = JSM.jsround(u["hp"] * k)
			if jt(u.get("sec")):
				for sk in u["sec"].keys():
					u["sec"][sk]["max"] = JSM.jsround(u["sec"][sk]["max"] * k); u["sec"][sk]["hp"] = JSM.jsround(u["sec"][sk]["hp"] * k)
		if tr.has("shielded") and u["shMax"] > 0:
			u["shMax"] = JSM.jsround(u["shMax"] * 1.2); var sh = []
			for _i in range(u["sh"].size()): sh.append(u["shMax"])
			u["sh"] = sh
		if tr.has("boarders"):
			u["crewMax"] = JSM.jsround(u["crewMax"] * 1.3); u["crew"] = u["crewMax"]
		if tr.has("artillery"):
			for w in u["weapons"]:
				if w["k"] != "flak" and w["k"] != "sq":
					w["r"] = w["r"] + 1; w["opt"] = w["opt"] + 1
		if tr.has("rockets"):
			for w in u["weapons"]:
				if w["k"] == "torp": w["cd"] = max(1, (w["cd"] if jt(w.get("cd")) else 2) - 1)
		if tr.has("brood") and u.get("ab") == "launch":
			u["hangar"] = z0(u.get("hangar")) + 1; u["spare"] = z0(u.get("spare")) + 1
	if tr.has("undying") and jt(B.get("legion")): B["legion"]["enemy"]["max"] = B["legion"]["enemy"]["max"] + 1
	if ad.has("legion") and jt(B.get("legion")): B["legion"]["enemy"]["max"] = B["legion"]["enemy"]["max"] + 1
	if ad.has("formation"):
		var sr = B["syncR"].duplicate() if B.get("syncR") is Dictionary else {}
		sr["enemy"] = TB.SYNC_R + 1; B["syncR"] = sr
	if ad.has("pd"):
		var pd = "spores" if fl["fac"] == "chorus" else "flak"; var nf = []
		for u in es:
			if not _has_flak(u): nf.append(u)
		for u in nf.slice(0, 2):
			var w = nameWeapons(u["fac"], [mkWeapon(pd, "T", u["fx"] if jt(u.get("fx")) else {})])[0]; w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0; u["weapons"].append(w)
	B["nemFlee"] = beh["flee"] if jt(beh.get("flee")) else null; B["nemAi"] = beh["ai"] if jt(beh.get("ai")) else null; B["nemLine"] = jt(beh.get("line"))
	B["nemNoRout"] = jt(beh.get("noFlee")) or jt(beh.get("revive")); B["nemChallenge"] = beh.get("strike") == "challenge"
	B["nemPersona"] = TB.NEM_PERSONA.get(N.get("persona")) if N.get("persona") != null else null
	if B.get("cp0") != null: B["cp0"]["enemy"] = sideCP("enemy")
	var an = []
	for a in ad: an.append(nemAdaptName(a, N.get("fac")).to_lower())
	if ad.size() > 0: emit({"t": "adaptation", "source": "nemesis"})
	var pron = "It" if N.get("g") == "n" else ("She" if N.get("g") == "f" else "He")
	logm(String(fl["name"]) + " commands this fleet: your Nemesis." + ((" " + pron + " has adapted: " + ", ".join(an) + ".") if ad.size() > 0 else ""), "e")
	var L = TB.NEM_LINES
	var bw = null
	if jt(N.get("last_beat")): bw = TB.NEM_BEAT_WORD.get(N["last_beat"]) if jt(TB.NEM_BEAT_WORD.get(N["last_beat"])) else N["last_beat"]
	var cnt = TB.NEM_BEAT_COUNTER.get(N["last_beat"]) if N.get("last_beat") != null else null
	var line = null
	if N.get("line") is String: line = N["line"]   # #121: the campaign's own NEM_VOICE line (cfg.nemesis.line) when it sends one
	elif jt(N.get("gloat")) and jt(L.get("gloat")): line = L["gloat"].get(N["gloat"])
	elif jt(N.get("met")) and jt(bw):
		var tpl = L["again"] if ad.has(cnt) else (L["remember"] if jt(L.get("remember")) else L["again"])
		var ts = String(tpl); var bi = ts.find("{beat}")   # JS replace: the first occurrence only
		line = (ts.substr(0, bi) + String(bw) + ts.substr(bi + 6)) if bi >= 0 else ts
	else: line = L["meet"].get(N.get("persona")) if (N.get("persona") != null and jt(L["meet"].get(N["persona"]))) else ""
	if jt(line): logm(String(fl["name"]) + ": \"" + String(line) + "\"", "e")
	if jt(B.get("nemChallenge")): nemSig("challenge")
	if beh.get("strike") == "duel": nemSig("duel")
	if jt(beh.get("line")): nemSig("line")
	if jt(B.get("nemChallenge")):
		var d = nemDuelTarget()
		if d != null: logm(String(fl["name"]) + " challenges " + ("your flagship" if jt(d.get("pflag")) else String(d["name"])) + " to single combat and comes for it: the two ships deal 20% more damage to each other.", "e")
# campaign_run.js nemAdaptName: the counter's name in the Nemesis's own faction words (the browser loads it beside battle.js)
func nemAdaptName(a, fac) -> String:
	var T = TB.NEM_ADAPT_FAC.get(fac) if (fac != null and TB.NEM_ADAPT_FAC.get(fac) != null) else {}
	if T.get("special") != null and js_eq(T["special"].get("id"), a): return String(T["special"]["n"])
	if a is String and a != "special" and jt(T.get(a)): return String(T[a])
	if a is String and TB.NEM_ADAPT.get(a) != null and jt(TB.NEM_ADAPT[a].get("n")): return String(TB.NEM_ADAPT[a]["n"])
	return tv(a)
# R49 Voidsworn challenge: his flagship seeks your flagship, or your strongest ship once it is gone
func nemDuelTarget() -> Variant:
	if B == null or not jt(B.get("nemChallenge")): return null
	var d = null
	if B.get("nemDuel") != null:
		for u in B["units"]:
			if u["id"] == B["nemDuel"] and not jt(u.get("dead")) and u["side"] == "player": d = u; break
	if d == null:
		for u in B["units"]:
			if jt(u.get("pflag")) and not jt(u.get("dead")) and u["side"] == "player": d = u; break
		if d == null:
			var c = []
			for u in B["units"]:
				if u["side"] == "player" and not jt(u.get("dead")) and not jt(u.get("isSq")) and not jt(u.get("reinf")): c.append(u)
			JSM.ssort(c, func(a, b):
				var dd = _byCpHp(a, b)
				return dd if dd != 0.0 else (-1 if String(a["id"]) < String(b["id"]) else 1))
			if c.size() > 0: d = c[0]
		if d != null:
			var first = B.get("nemDuel") == null; B["nemDuel"] = d["id"]
			if not first:
				var f = null
				for u in B["units"]:
					if jt(u.get("nemFlag")) and not jt(u.get("dead")): f = u; break
				if f != null: logm(String(f["name"]) + " turns to " + String(d["name"]) + ": the duel goes on.", "e")
	return d
# R42: a Corsair or Ithar Nemesis withdraws from a lost fight (checked at each enemy turn start)
func nemFleeCheck() -> void:
	if B == null or B.get("nem") == null or not jt(B.get("nemFlee")) or jt(B.get("nemFled")) or jt(B.get("over")): return
	var f = null
	for u in B["units"]:
		if jt(u.get("nemFlag")) and not jt(u.get("dead")) and u["side"] == "enemy": f = u; break
	if f == null: return
	var Rf = B["nemFlee"]
	var low = f["hp"] <= f["maxHp"] * z0(Rf.get("hull"))
	if low and jt(Rf.get("shields")) and f["shMax"] > 0:
		for x in f["sh"]:
			if x > 0.5: low = false; break
	if not low: return
	B["nemFled"] = true; nemSig("flee_battle")
	for e in alive("enemy"):
		if jt(e.get("isSq")) or jt(e.get("transport")): continue
		e["dead"] = true; e["fled"] = true; emit({"t": "fled", "unit": e["id"]})
	logm(String(f["name"]) + " breaks off and jumps out with what is left of his fleet. He will be back.", "s"); checkEnd()
# R42 personality and faction weights for his ships in the AI's move scoring
func nemProf(u, prof) -> Dictionary:
	var P = B.get("nemPersona") if B != null else null; var F = B.get("nemAi") if B != null else null
	if u == null or not jt(u.get("nem")) or ((P == null or not jt(P.get("ai"))) and not jt(F)): return prof
	var a = P["ai"] if (P != null and jt(P.get("ai"))) else {}; var o = prof.duplicate()
	if jt(a.get("tw")): o["tw"] = prof["tw"] * a["tw"]
	if a.get("range") != null: o["range"] = a["range"]
	if jt(a.get("flagFront")) and jt(u.get("nemFlag")): o["tw"] = prof["tw"] * 0.6
	if jt(F):
		if F.get("range") != null: o["range"] = max(z0(o.get("range")), F["range"])
		if jt(F.get("charge")) and jt(u.get("nemFlag")): o["tw"] = o["tw"] * 0.7
	return o
func nemTargetBonus(u, t) -> float:
	var P = B.get("nemPersona") if B != null else null; var F = B.get("nemAi") if B != null else null
	if u == null or not jt(u.get("nem")) or t == null: return 0.0
	var a = P["ai"] if (P != null and jt(P.get("ai"))) else {}; var v = 0.0
	if jt(a.get("focusWeak")) or (jt(F) and jt(F.get("focusWeak"))): v += 20.0 * (1.0 - float(t["hp"]) / t["maxHp"])
	if jt(a.get("focusFlag")) and jt(t.get("pflag")): v += 25.0
	if jt(F) and jt(F.get("hunt")) and jt(u.get("nemFlag")) and is_same(t, nemDuelTarget()): v += 30.0
	return v
# R42 signatures: his faction behaviour firing (the campaign records them from the event)
func nemSig(kind: String) -> void:
	if B == null or B.get("nem") == null: return
	if B.get("nemSigs") == null: B["nemSigs"] = []
	B["nemSigs"].append({"kind": kind, "r": B["round"]})
	emit({"t": "nem_signature", "kind": kind})
# R42 weaknesses found by triggering them: logged once, known for the rest of the run (no random draws)
func nemTrip(k: String) -> void:
	if B == null or B.get("nem") == null or not nemWeak(k): return
	if B.get("nemFound") == null: B["nemFound"] = []
	var rev = B["nem"].get("revealed") if B["nem"].get("revealed") != null else []
	if B["nemFound"].has(k) or rev.has(k): return
	B["nemFound"].append(k)
	if B["nem"].get("revealed") == null: B["nem"]["revealed"] = []
	B["nem"]["revealed"].append(k)
	logm("Weakness found: " + String(TB.NEM_WEAK[k]["n"]) + ". " + String(TB.NEM_WEAK[k]["d"]), "s")
func nemBreak() -> void:
	if B == null or B.get("nem") == null or jt(B.get("nemBroken")) or not nemWeak("anchor"): return
	var f = null
	for u in B["units"]:
		if jt(u.get("nemFlag")) and not jt(u.get("dead")) and u["side"] == "enemy": f = u; break
	if f == null or f["hp"] > f["maxHp"] * 0.6: return
	B["nemBroken"] = true; nemTrip("anchor"); var esc = []
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
func screenTorps(t, shots: Array, res, mult = null) -> void:
	var im = 1.0 if mult == null else float(mult)
	var shot = 0
	for sv in alive(t["side"]):
		if not jt(sv.get("isSq")) or wingStance(sv) != "screen" or hdist(sv, t) > TB.WING_SCREEN_R: continue
		var p = null
		for x in B["units"]:
			if x["id"] == sv.get("parent"): p = x; break
		var ch = (TB.WING_SCREEN_TORP + (0.2 if wingPerks(p).has("pickets") else 0.0)) * im
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
func rocketDefense(w, t, shots: Array, res, mult = null) -> void:
	if not jt(w.get("rockets")) or jt(t.get("isSq")): return
	var im = 1.0 if mult == null else float(mult)
	var shot = 0
	for d in alive(t["side"]):
		if jt(d.get("isSq")) or d["intercepts"] <= 0 or jt(d.get("braced")): continue
		var fw: Variant = null
		for x in d["weapons"]:
			if x["k"] == "flak" and not (z0(x.get("off")) > 0): fw = x; break
		if fw == null or hdist(d, t) > fw["r"]: continue
		var i = 0
		while i < shots.size() and d["intercepts"] > 0:
			if shots[i] and rnd() < 0.55 * im:
				shots[i] = false; d["intercepts"] = d["intercepts"] - 1; shot += 1
			i += 1
	if shot != 0:
		res["pd"] = shot; flt(t, ns(shot) + " rocket" + ("s" if shot > 1 else "") + " shot down", "#bfe3ff", 30)
func launchTorp(u, w, t, opts, live, keep, b0) -> bool:
	B["torpSeq"] = z0(B.get("torpSeq")) + 1
	var S = {"id": B["torpSeq"], "side": u["side"], "by": u["id"], "fac": u["fac"], "w": w.duplicate(), "tid": t["id"], "aim": {"q": t["q"], "r": t["r"]}, "from": {"q": u["q"], "r": u["r"]}, "r": B["round"], "called": opts["called"] if (jt(opts.get("called")) and not jt(t.get("isSq"))) else null}
	fstat(u["fac"], "shots")
	if syncOn(u, t): fstat(u["fac"], "syncShots")
	S["base"] = dmgMult(u, w, t, false) * TB.TORP_WARHEAD; S["rearAdd"] = dmgMult(u, w, t, true) * TB.TORP_WARHEAD - S["base"]
	if opts != null and jt(opts.get("half")): S["base"] *= 0.5; S["rearAdd"] *= 0.5
	S["ghost"] = torpGhost(u, keep[2])
	var pn = treeSkill("preyName")
	if pn != null and u["side"] == "player" and B.get("treePrey") != null and B["treePrey"]["r"] == B["round"] and B["treePrey"]["id"] == t["id"]:
		var b = treeAddVal(u, "torpPct", pn["n"]); S["base"] = S["base"] * (1.0 + b); S["rearAdd"] = S["rearAdd"] * (1.0 + b); treeFx(u, "preyName", "the named prey pays")   # Malek T1a
	var ts2 = treeSkill("twoSalvos")
	if ts2 != null and u["side"] == "player" and jt(u.get("treeTorpCarry")):
		S["base"] = S["base"] * (1.0 + float(u["treeTorpCarry"])); S["rearAdd"] = S["rearAdd"] * (1.0 + float(u["treeTorpCarry"])); u["treeTorpCarry"] = 0; treeFx(u, "twoSalvos", "the first torpedo keeps the salvo bonus")   # Malek T3b
	if u["side"] == "player" and cmdActive(u["side"], "hunt") and treeSkill("darkTorps") != null: S["dark"] = 1; treeFx(u, "darkTorps", "the torpedoes come in unseen")   # Sable T1b
	var ow = treeSkill("oathWings")
	if ow != null and u["side"] == "enemy" and t["side"] == "player" and cmdActive("player", "scramble"):
		var prot = false
		for x in alive("player"):
			if not jt(x.get("isSq")) and (x.get("ab") == "launch" or jt(g(x.get("fx"), "hive"))) and hdist(x, t) <= 2: prot = true; break
		if prot: S["oath"] = 1; treeFx(t, "oathWings", "the escort wall closes")   # Ashgrove capstone 2
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
		t = orig; pen = ([0, 0, 10] if w.get("trait") == "star" else TB.TORP_RING)[int(hdist(orig, S["aim"]))]   # Ithar star torpedoes track better
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
	var im = 0.5 if jt(S.get("dark")) else 1.0   # Sable T1b: torpedoes fired in the dark are intercepted at half the usual chance
	rocketDefense(w, t, shots, res, im); screenTorps(t, shots, res, im)
	if jt(S.get("oath")):
		for si in range(shots.size()):
			if jt(shots[si]):
				if rnd() < TB.WING_SCREEN_TORP: shots[si] = false; res["pd"] = z0(res.get("pd")) + 1
				treeFx(gh, "oathWings", "the wall takes the salvo"); break   # Ashgrove capstone 2
	emit({"t": "fire", "unit": gh["id"], "weapon": -1, "weapon_id": w["id"], "kind": w["k"], "arc": w["arc"], "name": w.get("n"), "target": t["id"], "shots": shots.duplicate(), "pd": z0(res.get("pd")), "quad": quad, "torpedo": S["id"], "from": {"q": int(S["from"]["q"]), "r": int(S["from"]["r"])}}); hook("fire", gh)
	if not live.call() or jt(t.get("dead")): return
	var d0 = z0(gh.get("dealt")); var same = orig != null and is_same(t, orig)
	var per = (func(rear): return S["base"] + (S["rearAdd"] if rear else 0.0)) if same else null
	landVolley(gh, w, t, {"quad": quad, "shBefore": shBefore, "shots": shots, "called": S.get("called") if same else null, "res": res, "torp": true, "stray": not same, "per": per, "by": real if real != null else gh})
	if real != null and not jt(real.get("dead")) and not jt(res.get("hits")): treeSecondKnife(real)   # Sable T2b: a torpedo that misses reloads one turn sooner than normal
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
	if side == "player" and B != null and not jt(B.get("over")): treeRoundFx(); flush_deferred()
	if B != null and not jt(B.get("over")): resolveTorps(side)
func roundStartBoth() -> void: # alternating round start: player ticks, enemy ticks, then player torpedoes, then enemy torpedoes
	var b0 = B
	startSideTurn("player")
	if not jt(B.get("over")): startSideTurn("enemy")
	flush_deferred()
	if not is_same(B, b0) or jt(B.get("over")): return
	treeRoundFx(); flush_deferred()
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
	if treeDeepBlocks(u, t): return false
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
	var noFall = u["side"] == "player" and B != null and B.get("tr") != null and B["tr"].get("sunTarget") == t["id"] and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player"   # Saro capstone 1: no range falloff
	var c: float = w["acc"] + u["aim"] + (15 if jt(u.get("lockOn")) else 0) - (15 if jt(u.get("fullAhead")) else 0) - (0.0 if noFall else over * w["fall"]) - min(45, t["ev"] + z0(t.get("evBuff"))) * (w["evMult"] if jt(w.get("evMult")) else 1)
	if jt(t.get("isSq")) and w["k"] != "flak" and w["k"] != "sq": c -= 15
	var noShadow = treeSkill("coronaShadow") != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]   # Umbra T3a
	if not noShadow:
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
	var tl = treeSkill("flagshipLens")
	if tl != null and w["k"] == "lance" and u["side"] == "player" and B != null and B.get("treeLens") != null and B["treeLens"]["r"] == B["round"] and B["treeLens"]["id"] == t.get("id"): c += treeAddVal(u, "aim", tl["n"])
	var f1 = treeSkill("firstLight")
	if f1 != null and B != null and B.get("tr") != null and B["tr"].get("firstLight") == u.get("id") and t["side"] == "player": c -= float(f1["n"])
	var ef = treeSkill("everyFrame")
	if ef != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and z0(u.get("hexMoved")) == 0: c += treeAddVal(u, "aim", ef["a"])   # Umbra T3b
	var sa = treeSkill("silentArchive")
	if sa != null and u["side"] == "enemy" and t["side"] == "player" and not jt(t.get("isSq")) and cmdActive("player", "hunt") and not inArc(u, t, "F"): c -= float(sa["n"])   # Ostrel T3b
	var td = treeSkill("throatDeep")
	if td != null and u["side"] == "player" and not jt(u.get("isSq")):
		var fgT = null
		if B != null:
			for x in B["units"]:
				if jt(x.get("pflag")) and not jt(x.get("dead")): fgT = x; break
		if fgT != null and hdist(u, fgT) <= 2: c += treeAddVal(u, "aim", td["n"])   # Chorus shared C1b
	var bb = treeSkill("breathBite")
	if bb != null and u["side"] == "enemy" and cmdActive("player", "surge"):
		var adj = 0
		for x in alive("player"):
			if not jt(x.get("isSq")) and hdist(x, u) == 1: adj += 1
		if adj >= 2: c -= float(bb["n"])   # Razormaw T3b
	if u["side"] == "enemy" and jt(u.get("treeAcidAim")): c -= 20   # Voice T3b
	var pcP = treeSkill("packCloses")
	if pcP != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge"):
		for x in alive("player"):
			if x != u and not jt(x.get("isSq")) and hdist(x, u) == 1: c += treeAddVal(u, "aim", pcP["n"]); break   # Grax T2a
	var pgP = treeSkill("patchGuns")
	if pgP != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(u.get("treeAimGuns")): c += treeAddVal(u, "aim", u["treeAimGuns"])   # Vesh T1b
	var psP = treeSkill("preyScent")
	if psP != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and B.get("tr") != null and B["tr"].get("scent") == t.get("id"): c += treeAddVal(u, "aim", psP["n"])   # Hullbreakers shared B1a
	var ssH = treeSkill("sharedSolution")
	if ssH != null and u["side"] == "player" and not jt(u.get("isSq")) and inSync(u):
		var bestA = float(u["aim"])
		for xS in alive("player"):
			if not is_same(xS, u) and not jt(xS.get("isSq")) and inSync(xS): bestA = max(bestA, float(xS["aim"]))
		if bestA > float(u["aim"]): c += treeAddVal(u, "aim", bestA - float(u["aim"]))   # Kassar T2a
	var cdH = treeSkill("coldDrill")
	if cdH != null and u["side"] == "player" and not jt(u.get("isSq")) and inSync(u) and z0(u.get("hexMoved")) == 0: c += treeAddVal(u, "aim", cdH["n"])   # Kassar T2b
	var prH = treeSkill("rehearsed")
	if prH != null and jt(u.get("isSq")) and u["side"] == "player" and jt(u.get("extra")) and cmdActive("player", "scramble"): c += treeAddVal(u, "aim", prH["n"])   # Reyes T2b
	var bcH = treeSkill("beacon")
	if bcH != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and B.get("tr") != null and B["tr"].get("beacon") != null and B["tr"]["beacon"]["r"] == B["round"] and B["tr"]["beacon"]["id"] == t.get("id"): c += treeAddVal(u, "aim", bcH["n"])   # Hegemony shared C1a
	var fmH = treeSkill("formation")
	if fmH != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(u.get("treeFormation")): c += treeAddVal(u, "aim", fmH["n"])   # Hegemony shared B1a
	var taH = treeSkill("targetArchived")
	if taH != null and u.get("treeAimTgt") != null and t["id"] == u["treeAimTgt"]: c += treeAddVal(u, "aim", taH["n"])   # Umbra T2b: a target no other ship chose
	var ekP = treeSkill("everyKnife")
	if ekP != null and u["side"] == "enemy" and u.get("treeKnifeRound") == B["round"]: c -= float(ekP["n"])   # Sable T3b
	var surge = cmdActive(t["side"], "surge") or (t["side"] == "player" and t.get("burnCarry") != null)
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
	var lf = treeSkill("longFocus")
	if lf != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and not jt(u.get("isSq")) and hdist(u, t) > float(w["r"]) / 2.0: m += treeAddVal(u, "dmgPct", lf["n"])
	var ff = treeSkill("flawForever")
	if ff != null and w["k"] == "lance" and B != null and B.get("treeFlaw") != null and t["id"] == B["treeFlaw"]: m += treeAddVal(u, "dmgPct", ff["n"])
	var ia = treeSkill("inheritedAim")
	if ia != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and not jt(u.get("isSq")) and z0(u.get("hexMoved")) == 0: m += treeAddVal(u, "dmgPct", ia["n"])   # Vex T2b
	var np = treeSkill("namedPrey")
	if np != null and B != null and B.get("treeNamedPrey") != null and B["treeNamedPrey"]["r"] == B["round"] and u["side"] == "player" and t["id"] == B["treeNamedPrey"]["id"]: m += treeAddVal(u, "dmgPct", np["n"])   # Malek capstone 2
	var nc = treeSkill("noonChoice")
	if nc != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("treeNoon")) and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: m += treeAddVal(u, "dmgPct", nc["n"])   # Umbra T1b
	var ef = treeSkill("everyFrame")
	if ef != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and z0(u.get("hexMoved")) == 0: m += treeAddVal(u, "dmgPct", ef["n"])   # Umbra T3b
	var fi = treeSkill("flagshipIndex")
	if fi != null and u["side"] == "player" and jt(u.get("pflag")) and B != null and B.get("tr") != null and B["tr"].get("indexTarget") != null and t["id"] == B["tr"]["indexTarget"]["id"]: m += treeAddVal(u, "dmgPct", fi["n"])   # Eclipse shared C1a
	var cb = treeSkill("copiedBehind")
	if cb != null and jt(rear) and u["side"] == "player" and cmdActive(u["side"], "hunt"): m += treeAddVal(u, "rearPct", cb["n"])   # Ostrel T1a
	var ua = treeSkill("unseenArchive")
	if ua != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and B != null and B.get("tr") != null and not jt(B["tr"]["targetedLast"].get(u["id"])): m += treeAddVal(u, "dmgPct", ua["n"])   # Ostrel T1b
	var uc = treeSkill("uncopiedTarget")
	if uc != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and not jt(t.get("treeHitBattle")): m += treeAddVal(u, "dmgPct", uc["n"])   # Ostrel T2b
	var laD = treeSkill("ledgerArcs")
	if laD != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and (w["arc"] == "P" or w["arc"] == "S"): m += treeAddVal(u, "broadPct", laD["n"])   # Vex T1a
	var olD = treeSkill("oneLens")
	if olD != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and B.get("tr") != null and B["tr"].get("oneLens") != null and u["id"] == B["tr"]["oneLens"]["ship"] and t["id"] == B["tr"]["oneLens"]["tgt"] and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: m += treeAddVal(u, "dmgPct", olD["n"])   # Saro T1b
	var ltD = treeSkill("lightTogether")
	if ltD != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]:
		var arrLT = B["tr"]["lightTgt"].get(t["id"]) if (B.get("tr") != null and B["tr"].get("lightTgt") != null) else null
		if arrLT is Array:
			for idLT in arrLT:
				if idLT != u["id"]: m += treeAddVal(u, "dmgPct", ltD["n"]); break
	var ddD = treeSkill("debtDue")
	if ddD != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("treeDebtDue")): m += treeAddVal(u, "dmgPct", ddD["n"])   # Vex T3b
	if u["side"] == "player" and not jt(u.get("isSq")):
		var add = 0.0
		var rd = treeSkill("runDown")
		if rd != null and cmdActive(u["side"], "surge") and float(t["speed"]) < float(u["speed"]): add += float(rd["n"])   # Razormaw T1a
		var trd = treeSkill("throatRed")
		if trd != null and jt(u.get("treeRedFirst")): add += float(trd["n"])   # Razormaw capstone 1
		var rB = treeSkill("runBigger")
		if rB != null and cmdActive(u["side"], "surge") and u.get("treeBigStart") != null and B != null and B.get("tr") != null and B["tr"].get("bigId") != null:
			var bigB = null
			for x in B["units"]:
				if x["id"] == B["tr"]["bigId"] and not jt(x.get("dead")): bigB = x; break
			if bigB != null and z0(u.get("hexMoved")) > 0 and hdist(u, bigB) < float(u["treeBigStart"]): add += float(rB["n"])   # Grax T1a
		var smB = treeSkill("smileCut")
		if smB != null and jt(u.get("treeSmile")): add += float(smB["n"])   # Sable T3a
		var pbB = treeSkill("packBites")
		if pbB != null and u.get("treeDmgCarry") != null and u["treeDmgCarry"]["r"] == B["round"]: add += float(pbB["n"])   # Vesh T3b
		if u.get("treeHuntRearNext") != null and u["treeHuntRearNext"]["r"] == B["round"]: add += float(u["treeHuntRearNext"]["n"])   # Sable capstone 1
		if jt(u.get("treeDmgNext")): add += float(u["treeDmgNext"])   # Mending T3a
		var spD = treeSkill("shadowPos")
		if spD != null and jt(u.get("treeShadowPos")) and cmdActive(u["side"], "hunt"): add += float(spD["n"])   # Ostrel T2a
		if jt(u.get("treeIterFire")): add += float(u["treeIterFire"])   # Nadir T2a
		var sbH = treeSkill("strikeBook")
		if sbH != null and cmdActive(u["side"], "hunt") and B != null and B.get("tr") != null and B["tr"].get("strikeSpeed") != null and float(u["speed"]) >= float(B["tr"]["strikeSpeed"]): add += float(sbH["n"])   # Vorn T1b
		var cfH = treeSkill("crossFire")
		if cfH != null and cmdActive(u["side"], "hunt") and B != null and B.get("tr") != null and z0(B["tr"]["crossHits"].get(t["id"])) >= 1: add += float(cfH["n"])   # Vorn T2a
		var tiH = treeSkill("totalInterdiction")
		if tiH != null and cmdActive(u["side"], "hunt") and B != null and B.get("tr") != null and B["tr"]["totalShips"].get(t["id"]) is Dictionary and B["tr"]["totalShips"][t["id"]].size() >= 3: add += float(tiH["n"])   # Vorn T3a
		var pfH = treeSkill("permanentFile")
		if pfH != null and B != null and B.get("treePermFile") != null and B["treePermFile"]["r"] == B["round"] and jt(B["treePermFile"]["ids"].get(t["id"])): add += float(B["treePermFile"]["m"])   # Vorn capstone 1
		if add != 0.0: m += treeAddVal(u, "dmgPct", add)
	if w["arc"] == "P" or w["arc"] == "S": m += z0(fx.get("broadPct"))
	if w["k"] == "lance": m += z0(fx.get("lancePct"))
	if w["k"] == "torp": m += z0(fx.get("torpPct"))
	if jt(u.get("isSq")): m += z0(u.get("sqPct"))
	if jt(u.get("isSq")) and jt(u.get("treeBonus")): m += treeAddVal(u, "sqPct", float(u["treeBonus"]))   # Ashgrove T1b
	var otH = treeSkill("oneTarget")
	if otH != null and jt(u.get("isSq")) and u["side"] == "player" and B != null and B.get("tr") != null and B["tr"].get("wingFiled") != null and B["tr"]["wingFiled"]["r"] == B["round"] and B["tr"]["wingFiled"]["id"] == t.get("id"): m += treeAddVal(u, "sqPct", otH["n"])   # Reyes capstone 1
	if jt(u.get("isSq")) and u["side"] == "player" and B != null and B.get("tr") != null:
		var rtB = treeSkill("reTasked")
		if rtB != null and jt(u.get("extra")) and not jt(B["tr"]["wingStruck"].get(t["id"])): m += treeAddVal(u, "sqPct", rtB["n"])   # Mott T2a
		var scB = treeSkill("screaming")
		if scB != null and jt(u.get("extra")) and jt(B["tr"]["hitRound"].get(t["id"])): m += treeAddVal(u, "sqPct", scB["n"])   # Mott T3b
		var pwB = treeSkill("privateWing")
		if pwB != null and jt(u.get("treePrivate")) and u.get("treePrivateRound") != B["round"]: m += treeAddVal(u, "sqPct", pwB["n"])   # Mott capstone 2
	if jt(u.get("isSq")) and u["side"] == "player" and jt(u.get("extra")) and B != null and B.get("tr") != null:
		var fpW = treeSkill("flightPaths")
		if fpW != null:
			var parW = null
			for xW in B["units"]:
				if xW["id"] == u.get("parent"): parW = xW; break
			if parW != null and B["tr"].get("carrierLast") != null and B["tr"]["carrierLast"].get(parW["id"]) == t["id"]: m += treeAddVal(u, "sqPct", fpW["n"])   # Tamsa T1a
		var rpW = treeSkill("replay")
		if rpW != null and B["tr"].get("strikeAgain") == B["round"] and jt(B["tr"]["hitRound"].get(t["id"])): m += treeAddVal(u, "sqPct", rpW["n"])   # Tamsa T2a
		var aspW = treeSkill("accountSplits")
		if aspW != null:
			var arrAS = B["tr"].get("wingTargets") != null and B["tr"]["wingTargets"].get(u.get("parent")) is Array
			if arrAS:
				for xAS in B["tr"]["wingTargets"][u.get("parent")]:
					if xAS["sq"] != u["id"] and xAS["tid"] != t["id"]: m += treeAddVal(u, "sqPct", aspW["n"]); break
		var ntW = treeSkill("nineThroats")
		if ntW != null and B["tr"].get("swarmHunger") is Dictionary and z0(B["tr"]["swarmHunger"].get("r")) == B["round"] and B["tr"]["swarmHunger"].get("id") == t["id"]: m += treeAddVal(u, "sqPct", ntW["n"])   # Matriarch capstone 1
	if rear: m += z0(fx.get("rearPct"))
	var ttR = treeSkill("teethThroat")
	if ttR != null and rear and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and not jt(u.get("treeTeethUsed")): m += treeAddVal(u, "rearPct", ttR["n"])   # Razormaw T1b
	var rrB = treeSkill("rearReckoning")
	if rrB != null and rear and u["side"] == "player" and cmdActive(u["side"], "hunt"): m += treeAddVal(u, "rearPct", rrB["n"])   # Malek T2b
	var kbB = treeSkill("knifeBack")
	if kbB != null and rear and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "hunt"): m += treeAddVal(u, "rearPct", kbB["n"])   # Sable T1a
	if rear and jt(t.get("nem")) and nemWeak("flank"): m += 0.25
	if B != null and jt(B.get("nemChallenge")) and ((jt(u.get("nemFlag")) and js_eq(t.get("id"), B.get("nemDuel"))) or (js_eq(u.get("id"), B.get("nemDuel")) and jt(t.get("nemFlag")))): m += 0.2   # R42 Voidsworn Nemesis: the flagship duel
	if jt(u.get("nem")) and B != null and B.get("nem") != null and (B["nem"]["traits"] if B["nem"].get("traits") != null else []).has("zeal") and hdist(u, t) == 1: m += 0.12   # R42 trait: zealots up close
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
	if cmdActive(u["side"], "hunt") and not jt(u.get("treeHuntNext")): base *= 1.0 + cmdPow("hunt", null, u["side"])
	if jt(u.get("treeHuntCarry")): base *= 1.0 + float(u["treeHuntCarry"])
	if jt(u.get("isSq")) and cmdActive(u["side"], "scramble"): base *= 1.0 + cmdPow("scramble", null, u["side"])
	if B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: base *= B["volleyMul"]["m"]
	return base * storyDamageMult(u)
# Inside a scoring window (eval_begin to eval_end) nothing in the battle changes, so expectedVs depends only on the two ships, the gun,
# the shooter's hex and hexes moved (hit chance, sync, rake), the target's hex, facing (shield quadrant) and hexes moved. Not on the
# shooter's facing: arcs are checked by the callers. Callers only read the result.
var _ev := {}
func expectedVs(u, w, t) -> Dictionary:
	if _evc:
		var su = _slot.get(u.get("id")); var st = _slot.get(t.get("id")); var wi = -1
		var ws = u["weapons"]
		for i in range(ws.size()):
			if is_same(ws[i], w):
				wi = i; break
		var hu = int(z0(u.get("hexMoved"))); var ht = int(z0(t.get("hexMoved")))
		var uq = int(u["q"]) + 64; var ur = int(u["r"]); var tq = int(t["q"]) + 64; var tr = int(t["r"]); var tf = int(t["facing"])
		if su != null and st != null and su < 64 and st < 64 and wi >= 0 and wi < 16 and hu < 16 and ht < 16 and uq >= 0 and uq < 128 and tq >= 0 and tq < 128 and ur >= 0 and ur < 64 and tr >= 0 and tr < 64 and tf >= 0 and tf < 8:
			var k = (((((((((su * 16 + wi) * 64 + st) * 128 + uq) * 64 + ur) * 128 + tq) * 64 + tr) * 16 + hu) * 16 + ht) * 8 + tf)
			var c = _ev.get(k)
			if c == null:
				c = _expectedVs_raw(u, w, t); _ev[k] = c
			return c
	return _expectedVs_raw(u, w, t)
func _expectedVs_raw(u, w, t) -> Dictionary:
	var quad = shieldQuad(t, u); var rear = treeIsRear(u, t, quad)
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
	var of = ownerFx(att); var rear = treeIsRear(att, t, quad); var pierce = 1.0 if (w.get("k") == "lance" and jt(of.get("lanceSure"))) else z0(w.get("pierce")); var ion = ionVs(att, w, t)
	if jt(t.get("_treePierce")): pierce = 1.0; t["_treePierce"] = 0
	if B != null and B.get("tr") != null and B["tr"].get("firstStopTarget") == t["id"]:
		if not jt(B["tr"].get("firstStopDone")): B["tr"]["firstStopDone"] = 1
		else: pierce = 1.0   # Kassar capstone 2: shields stop only the first hit
	if B != null and B.get("tr") != null and B["tr"].get("sunTarget") == t["id"] and att != null and att["side"] == "player":
		if not jt(B["tr"].get("sunFirstDone")): B["tr"]["sunFirstDone"] = 1
		else: pierce = 1.0   # Saro capstone 1
	if B != null and B.get("tr") != null and B["tr"].get("grandTarget") == t["id"] and att != null and att["side"] == "player":
		if not jt(B["tr"].get("grandFirstDone")): B["tr"]["grandFirstDone"] = 1
		else: pierce = 1.0   # Vex capstone 1
	if not jt(t.get("isSq")):
		if t.get("shHit") == null: t["shHit"] = [0, 0, 0, 0]
		t["shHit"][quad] = 1
		if jt(w.get("ion")) and att != null and att.get("fac") == "hegemony" and t["shMax"] > 0:
			if t.get("regenLock") == null: t["regenLock"] = [0, 0, 0, 0]
			t["regenLock"][quad] = 1
	var shieldable: float = dmg * (1.0 - pierce); var through: float = dmg - shieldable
	var s = z0(t["sh"][quad]); var sh0 = s; var absorbed: float = min(shieldable, float(s) / ion)
	t["sh"][quad] = max(0, s - absorbed * ion); shieldable -= absorbed
	var gc = treeSkill("glassCorrected")
	if gc != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(B["tr"].get("glassUsed")) and t["shMax"] > 0 and sh0 > 0 and t["sh"][quad] <= 0:
		t["sh"][quad] = JSM.jsround(t["shMax"] * float(gc["n"])); B["tr"]["glassUsed"] = 1; treeFx(t, "glassCorrected", "the emptied facing refills")
	var ceH = treeSkill("columnEndures")
	if ceH != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(B["tr"].get("columnUsed")) and t["shMax"] > 0 and sh0 > 0 and t["sh"][quad] <= 0:
		t["sh"][quad] = JSM.jsround(t["shMax"] * float(ceH["n"])); B["tr"]["columnUsed"] = 1; treeFx(t, "columnEndures", "the emptied facing refills")   # Maren T3a
	var seams: bool = treeSkill("acidSeams") != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player" and att != null and att["side"] == "player" and t["side"] == "enemy" and t["hp"] < t["maxHp"] / 2.0   # Voice T3a
	var arm: float = 0.0 if seams else max(0, t["armor"] - z0(t.get("shredded"))) * (1.0 - z0(w.get("armorPierce"))); var hull: float = (through + shieldable) * (1.0 - (arm * 0.5 if rear else arm))
	hull *= braceMul(t)
	hull *= cmdTaken(t) * guardMul(t)
	var esH = treeSkill("escorts")
	if esH != null and att != null and jt(att.get("isSq")) and att["side"] == "enemy" and B != null and B.get("tr") != null and B["tr"].get("escortScreen") == B["round"]: hull *= max(0.0, 1.0 - float(esH["n"]))   # Reyes T3b
	var bellH = treeSkill("bell")
	if bellH != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(B["tr"].get("bellUsed")):
		B["tr"]["bellUsed"] = 1
		if hull > 0: hull = 0.0; treeFx(t, "bell", "the bell takes the blow")   # Maren T2a
	var up = treeSkill("unpaid")
	if up != null and t["side"] == "player" and cmdActive("player", "iron") and t["hp"] < t["maxHp"] / 2.0: treeFx(t, "unpaid", "the wall pays more")   # Thale T3a
	var tr = treeSkill("twiceRestored")
	if tr != null and t["side"] == "player" and cmdActive("player", "iron") and jt(t.get("treeRepaired")): treeFx(t, "twiceRestored", "the twice-restored hull holds")   # Seveth T1b
	var nl = treeSkill("noLayer")
	if nl != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(t.get("treeAbsorbed")) and hull > 0:
		hull = 0.0; t["treeAbsorbed"] = 1; treeFx(t, "noLayer", "the layered plates take the hit")   # Seveth T3a
	var crit = false
	var critAdd = 0
	var ftH = treeSkill("filedTriplicate")
	if ftH != null and att != null and att["side"] == "player" and B != null and B.get("treeFiled") != null and t["id"] == B["treeFiled"]["id"]: critAdd += int(ftH["n"])   # Vorn T1a
	var fbH = treeSkill("filedBefore")
	if fbH != null and att != null and att["side"] == "player" and not jt(att.get("isSq")) and cmdActive("player", "hunt") and z0(att.get("hexMoved")) == 0: critAdd += int(fbH["n"]); treeFx(att, "filedBefore", "the file is ahead of the move")   # Vorn T2b
	if hull > 0.5 and rnd() * 100.0 < z0(w.get("crit")) + att["crit"] + (10 if jt(att.get("lockOn")) else 0) + (15 if rear else 0) + (z0(of.get("momCrit")) if z0(att.get("hexMoved")) >= 3 else 0) + critAdd:
		hull *= 1.5 + z0(of.get("critMul")); crit = true
	if crit and critAdd > 0 and att != null and att["side"] == "player":
		if treeSkill("filedBefore") != null: treeFx(att, "filedBefore", "the file is ahead of the move")
		elif treeSkill("filedTriplicate") != null: treeFx(att, "filedTriplicate", "the triplicate tells")
	hull = JSM.jsround(hull)
	var faH = treeSkill("filedArmor")
	if faH != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(t.get("treeRoundFired")) and hull > 0: hull = max(0.0, hull - float(faH["n"])); treeFx(t, "filedArmor", "the armor was filed")   # Maren T3b
	var scHit = treeSkill("standardCovers")
	if scHit != null and t["side"] == "player" and cmdActive("player", "iron") and hull > 0: treeFx(t, "standardCovers", "the standard covers all")   # Maren capstone 1
	var sbrH = treeSkill("sevenBreach")
	if sbrH != null and crit and att != null and att["side"] == "player":
		var secB = t["_calledSec"] if jt(t.get("_calledSec")) else SEC_OF_QUAD[quad]
		for w2 in t["weapons"]:
			if (secB == "prow" and w2["arc"] == "F") or (secB == "mid" and (w2["arc"] == "P" or w2["arc"] == "S")): w2["off"] = max(z0(w2.get("off")), 2)
		treeFx(t, "sevenBreach", "the breach silences the section")   # Vorn T3b
	var tt = treeSkill("tenThousand")
	if tt != null and t["side"] == "player" and cmdActive("player", "iron"):
		var cap = JSM.jsround(t["maxHp"] * float(tt["n"])); var have = z0(t.get("treeRoundDmg"))
		if have + hull > cap: hull = max(0.0, float(cap) - have); treeFx(t, "tenThousand", "the wall counts ten thousand")
		t["treeRoundDmg"] = have + hull   # Seveth capstone 1
	if hull > 0 and z0(t.get("tempHp")) > 0:
		var ab = min(z0(t.get("tempHp")), hull); t["tempHp"] = z0(t.get("tempHp")) - ab; hull -= ab; flt(t, "−" + ns(ab) + " grown hull", "#8ff0a0", -30)   # H10
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
	var hard = false
	var hl = treeSkill("hardLight")
	if hl != null and t["side"] == "player" and cmdActive("player", "iron") and not jt(t.get("treeHardUsed")) and t["shMax"] > 0 and sh0 > 0:
		hard = true; t["treeHardUsed"] = 1; treeFx(t, "hardLight", "the shield holds the section")
	if not hard: damageSection(t, t["_calledSec"] if jt(t.get("_calledSec")) else SEC_OF_QUAD[quad], hull, att)
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
	if jt(s.get("treeLock")): s["hp"] = max(1, s["hp"] - dmg); return   # Mending capstone 2: a restored section cannot be destroyed again
	if s["hp"] <= 0: return
	s["hp"] = max(0, s["hp"] - dmg)
	if s["hp"] > 0 or jt(s.get("broken")): return
	var nb = treeSkill("nothingBroken")
	if nb != null and t["side"] == "player" and z0(B["tr"].get("nothingSaved")) == 0: B["tr"]["nothingSaved"] = 1; s["hp"] = s["max"]; treeFx(t, "nothingBroken", "the weld holds"); return   # Vesh capstone 2
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
	var w = u["weapons"][wi]; var svArc = false
	if not jt(opts.get("intercept")) and not canFire(u, w, t):
		if jt(opts.get("forceArc")) and treeArcLegal(u, w, t): svArc = true
		elif jt(opts.get("forceRange")) and treeRangeLegal(u, w, t): svArc = true
		elif treeSecondVolleyOK(u, w, t):
			svArc = true; B["tr"]["secondVolleyUsed"] = 1; treeFx(u, "secondVolley", "one more synced ship fires out of arc")
		else: return false
	var keep = [w.get("fired"), w.get("cdLeft"), u.get("sureUsed"), u.get("postFire"), u.get("postMp")]; var b0 = B   # get(): B-20 refits lack fired and cdLeft
	if not jt(opts.get("intercept")):
		w["fired"] = true
		if jt(w.get("cd")): w["cdLeft"] = w["cd"]
		if u["side"] == "player" and not jt(u.get("isSq")):
			u["sureUsed"] = z0(u.get("sureUsed")) + 1; u["treeHasFired"] = 1; u["treeRoundFired"] = 1
	if jt(B.get("usage")) and u["side"] == "player" and not jt(opts.get("intercept")) and not jt(u.get("isSq")):
		var k = ARC_NAME[w["arc"]] if jt(ARC_NAME.get(w["arc"])) else str(w["arc"])
		B["usage"]["fire"][k] = z0(B["usage"]["fire"].get(k)) + 1
		if jt(opts.get("called")): B["usage"]["aim"] = B["usage"]["aim"] + 1
	if jt(B.get("usage")) and u["side"] == "player" and not jt(opts.get("intercept")):
		if B["usage"].get("kind") == null: B["usage"]["kind"] = {}
		var kk = "sq" if jt(u.get("isSq")) else w["k"]; B["usage"]["kind"][kk] = z0(B["usage"]["kind"].get(kk)) + 1
		if jt(w.get("ion")): B["usage"]["ion"] = z0(B["usage"].get("ion")) + 1
	if not jt(opts.get("intercept")) and not jt(u.get("isSq")) and w["k"] != "flak" and not jt(u.get("postFire")):
		u["postFire"] = true; u["postMp"] = (u["mp"] if treeFullFade(u) else floor(u["mp"] / 2.0)) if canFade(u) else 0
		if treeFullFade(u): treeFx(u, "splitThree", "the light splits three ways")
	if not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")) and (u.get("ab") == "launch" or z0(u.get("hangar")) > 0): B["tr"]["carrierLast"][u["id"]] = t["id"]   # Tamsa T1a
	if not jt(opts.get("intercept")) and torpTravels(w, u):   # B3: torpedoes travel and strike next turn
		var rT = launchTorp(u, w, t, opts, live, keep, b0)
		if rT and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive("player", "hunt"):
			if treeSkill("torpFirst") != null and B["torps"].size() > 0:
				var ST = B["torps"][B["torps"].size() - 1]
				if ST != null and ST.get("by") == u["id"]: B["torps"].pop_back(); torpImpact(ST); treeFx(u, "torpFirst", "the torpedoes run first")   # Malek T2a: they strike at once
			if not jt(opts.get("half")) and treeSkill("salvoEnd") != null and not jt(u.get("treeSalvoUsed")):
				u["treeSalvoUsed"] = 1; var t2 = null; var bv = 0.0
				for e in alive("enemy"):
					if is_same(e, t) or jt(e.get("isSq")) or jt(e.get("dead")): continue
					var vv = 0.0
					for w2 in u["weapons"]:
						if w2["k"] != "torp" or jt(w2.get("off")): continue
						if hdist(u, e) <= w2["r"] and los(u, e) and inArc(u, e, w2["arc"]): vv += w2["dmg"] * w2["shots"]
					if vv > bv: bv = vv; t2 = e
				if t2 == null:
					for e0 in alive("enemy"):
						if not jt(e0.get("isSq")) and not jt(e0.get("dead")) and is_same(e0, t): t2 = e0; break
				if t2 == null:
					for e2 in alive("enemy"):
						if not jt(e2.get("isSq")) and not jt(e2.get("dead")): t2 = e2; break
				if t2 != null:
					var wiT = -1
					for iT in range(u["weapons"].size()):
						if u["weapons"][iT]["k"] == "torp" and not jt(u["weapons"][iT].get("off")): wiT = iT; break
					if wiT >= 0 and treeExtraShot(u, wiT, t2, {"half": true}): treeFx(u, "salvoEnd", "the salvo has no end")   # Malek capstone 1
		return rT
	if not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")):
		var smF = treeSkill("smileCut")
		if smF != null and cmdActive("player", "hunt") and not jt(B["tr"].get("smileUsed")): B["tr"]["smileUsed"] = 1; u["treeSmile"] = 1   # Sable T3a
	if jt(u.get("isSq")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")):
		for d in alive(t["side"]):
			if jt(d.get("isSq")) or d["intercepts"] <= 0 or jt(d.get("braced")): continue
			if treeSkill("flakSkip") != null and cmdActive(u["side"], "scramble") and B.get("treeFlakSkip") == d["id"]:
				treeFx(d, "flakSkip", "point defence looks the wrong way"); continue
			var fcF = treeSkill("flightCast")
			if fcF != null and cmdActive(u["side"], "scramble") and jt(u.get("isSq")) and jt(u.get("extra")) and is_same(d, t): treeFx(d, "flightCast", "the flak cannot see the strike"); continue   # Tamsa capstone 1
			var fi = -1
			for k in range(d["weapons"].size()):
				if d["weapons"][k]["k"] == "flak" and eqn(d["weapons"][k].get("off"), 0):
					fi = k; break
			if fi < 0: continue
			if hdist(d, u) > d["weapons"][fi]["r"]: continue
			d["intercepts"] = d["intercepts"] - 1
			fireWeapon(d, fi, u, {"intercept": true})
			if jt(u.get("dead")): return true
	if not jt(opts.get("intercept")) and u["side"] == "enemy" and t["side"] == "player" and not jt(t.get("isSq")):
		var fsF = treeSkill("firstScar")
		if fsF != null and B.get("tr") != null and not jt(B["tr"].get("firstScarUsed")):
			var fgF = null
			for x in B["units"]:
				if jt(x.get("pflag")) and not jt(x.get("dead")): fgF = x; break
			if fgF != null and not is_same(fgF, t) and hdist(fgF, t) == 1: t = fgF; B["tr"]["firstScarUsed"] = 1; treeFx(fgF, "firstScar", "the flagship takes the first scar")   # Hullbreakers shared C1a
	var quad = shieldQuad(t, u); var shBefore = z0(t["sh"][quad]) if t.get("sh") != null else 0
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	var called = opts["called"] if jt(opts.get("called")) and not jt(t.get("isSq")) and not jt(opts.get("intercept")) else null
	var su = u.get("sureUsed")
	if not jt(opts.get("intercept")): u["sureUsed"] = keep[2]
	var treePen = 0.0
	if not jt(opts.get("intercept")) and u["side"] == "enemy" and t["side"] == "player":
		var feF = treeSkill("fleetElsewhere")
		if feF != null and not jt(B["tr"].get("fleetElsewhere")):
			B["tr"]["fleetElsewhere"] = 1
			for xFE in alive("player"):
				if jt(xFE.get("isSq")): continue
				var addFE = treeAddVal(xFE, "speed", feF["n"]); xFE["mp"] = z0(xFE.get("mp")) + addFE; xFE["postMp"] = z0(xFE.get("postMp")) + addFE; xFE["treeFreeTurn"] = 1
			treeFx(treeFlagUnit() if treeFlagUnit() != null else t, "fleetElsewhere", "the fleet is elsewhere")   # Vell capstone 1
		var saF = treeSkill("silentArchive")
		if saF != null and not jt(t.get("isSq")) and cmdActive("player", "hunt") and not inArc(u, t, "F"): treeFx(t, "silentArchive", "the archive hides the ship")   # Ostrel T3b
		B["tr"]["targeted"][t["id"]] = 1
		if B["tr"].get("firstLight") == null:
			var f1 = treeSkill("firstLight")
			if f1 != null:
				B["tr"]["firstLight"] = u["id"]; var fg = null
				for x in B["units"]:
					if jt(x.get("pflag")) and not jt(x.get("dead")): fg = x; break
				treeFx(fg if fg != null else t, "firstLight", str(u["name"]) + " is recorded")
		var wi2 = treeSkill("twoImages")
		if wi2 != null and cmdActive("player", "surge") and not jt(B["tr"]["enemyShots"].get(t["id"])):
			B["tr"]["enemyShots"][t["id"]] = 1; treePen += float(wi2["n"]); treeFx(t, "twoImages", "the image takes the shot")
		if z0(u.get("treeAimDebuff")) > 0:
			treePen += z0(u["treeAimDebuff"]); u["treeAimDebuff"] = 0; treeFx(t, "wardGlass", "the ward reflects the aim")
	var starAim = 0.0
	var stS = treeSkill("starlings")
	if stS != null and not jt(opts.get("intercept")) and u["side"] == "player" and jt(u.get("isSq")) and jt(u.get("extra")):
		if B["tr"].get("wingTgt") == null: B["tr"]["wingTgt"] = {}
		var arrST = B["tr"]["wingTgt"].get(t["id"]) if B["tr"]["wingTgt"].get(t["id"]) is Array else []
		for idST in arrST:
			if idST != u["id"]: starAim = treeAddVal(u, "aim", stS["n"]); break
		if not arrST.has(u["id"]): arrST.append(u["id"])
		B["tr"]["wingTgt"][t["id"]] = arrST   # Tamsa T2b
	var hc = hitChance(u, w, t)
	if treePen > 0: hc = max(5.0, hc - treePen)
	if starAim > 0: hc = min(95.0, hc + starAim); treeFx(u, "starlings", "the starlings form up")
	if z0(u.get("treeAimNext")) > 0:
		hc = min(95.0, hc + z0(u["treeAimNext"])); treeFx(u, "stillnessCounted", "the stillness counts"); u["treeAimNext"] = 0   # Seveth T3b
	var eg = treeSkill("everyGun")
	if eg != null and jt(u.get("treeAimPlus")):
		hc = min(95.0, hc + float(u["treeAimPlus"])); treeFx(u, "everyGun", "a shared solution"); u["treeAimPlus"] = 0   # Vex T3a
	var bb2 = treeSkill("breathBite")
	if bb2 != null and not jt(opts.get("intercept")) and u["side"] == "enemy" and cmdActive("player", "surge"):
		var adj2 = 0
		for x in alive("player"):
			if not jt(x.get("isSq")) and hdist(x, u) == 1: adj2 += 1
		if adj2 >= 2: treeFx(t, "breathBite", "the throat has no room")   # Razormaw T3b
	var td2 = treeSkill("throatDeep")
	if td2 != null and not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")):
		var fg2 = null
		for x in B["units"]:
			if jt(x.get("pflag")) and not jt(x.get("dead")): fg2 = x; break
		if fg2 != null and hdist(u, fg2) <= 2: treeFx(u, "throatDeep", "the deep throat guides the shot")   # Chorus shared C1b
	var wg = treeSkill("wardGlass")
	if not jt(opts.get("intercept")) and u["side"] == "enemy" and t["side"] == "player" and cmdActive("player", "iron") and wg != null and not jt(u.get("treeWardOnce")):
		u["treeWardOnce"] = 1; u["treeAimDebuff"] = float(wg["n"])
	if not jt(opts.get("intercept")) and u["side"] == "enemy" and t["side"] == "player" and not jt(t.get("isSq")):
		var ew = treeEscortWing(t)
		if ew != null: t = ew; treeFx(ew, "escortName", "the escort takes the hit")   # H16 Ashgrove T1a
	u["sureUsed"] = su   # the rangefinder relic reads the count from before this shot
	if not jt(opts.get("intercept")) and not jt(u.get("isSq")):
		fstat(u["fac"], "shots")
		if syncOn(u, t): fstat(u["fac"], "syncShots")
	var shots = []
	for i in range(int(w["shots"])): shots.append(rnd() * 100.0 < hc)
	var fh = treeSkill("falseHulls")
	if not jt(opts.get("intercept")) and u["side"] == "enemy" and fh != null and cmdActive("player", "surge") and z0(B["tr"].get("falseHulls")) < float(fh["n"]):
		B["tr"]["falseHulls"] = z0(B["tr"].get("falseHulls")) + 1
		for i in range(shots.size()): shots[i] = false
		treeFx(u, "falseHulls", "the attack is wasted on a false image")
	rocketDefense(w, t, shots, res)
	var sr = treeSkill("standardReroll")
	if sr != null and not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")) and not jt(B["tr"].get("standardUsed")):
		var sf = null
		for x in B["units"]:
			if jt(x.get("pflag")) and not jt(x.get("dead")): sf = x; break
		if sf != null and hdist(u, sf) <= 2:
			var mi = -1
			for i in range(shots.size()):
				if not jt(shots[i]): mi = i; break
			if mi >= 0:
				shots[mi] = rnd() * 100.0 < hc; B["tr"]["standardUsed"] = 1; treeFx(u, "standardReroll", "the standard rerolls a miss")   # Vex shared C1b
	var halfShot = -1
	if treeSkill("frameZero") != null and not jt(opts.get("intercept")) and u["side"] == "player" and jt(u.get("pflag")) and not jt(B["tr"].get("frameZeroUsed")):
		var mi2 = -1
		for i in range(shots.size()):
			if not jt(shots[i]): mi2 = i; break
		if mi2 >= 0:
			B["tr"]["frameZeroUsed"] = 1; shots[mi2] = rnd() * 100.0 < hc
			if jt(shots[mi2]): halfShot = mi2
			treeFx(u, "frameZero", "the frame zero shot is recorded")   # Eclipse shared C1b
	emit({"t": "fire", "unit": u["id"], "weapon": wi, "weapon_id": w["id"], "kind": w["k"], "arc": w["arc"], "name": w.get("n"), "target": t["id"], "shots": shots.duplicate(), "pd": z0(res.get("pd")), "quad": quad}); hook("fire", u)
	if B != null: B["prog"] = z0(B.get("prog")) + 1
	if not live.call():
		if not jt(opts.get("intercept")) and is_same(B, b0):
			w["fired"] = keep[0]; w["cdLeft"] = keep[1]; u["sureUsed"] = keep[2]; u["postFire"] = keep[3]; u["postMp"] = keep[4]
		return false
	if not jt(opts.get("intercept")): syncMarkShot(u, t)
	if not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("pflag")) and not jt(u.get("isSq")): B["tr"]["indexTarget"] = {"id": t["id"], "r": B["round"]}   # Eclipse shared C1a
	var preSSid = B["tr"].get("strikeSpeedId")
	var landed = landVolley(u, w, t, {"quad": quad, "shBefore": shBefore, "shots": shots, "called": called, "res": res, "intercept": jt(opts.get("intercept")), "half": jt(opts.get("half")), "halfShot": halfShot})
	if landed and not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")) and B["tr"].get("strikeSpeedId") == preSSid:
		B["tr"]["strikeSpeed"] = u["speed"]; B["tr"]["strikeSpeedId"] = u["id"]   # Vorn T1b: the last ship that fired this round (a nested extra shot stays the last)
	if landed and not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")) and inSync(u): treeSecondVolleyAuto(u, t)   # Kassar T1b
	if landed and not jt(opts.get("intercept")) and u["side"] == "enemy" and t["side"] == "player" and t["shMax"] > 0 and shBefore > 0 and z0(t["sh"][quad]) <= 0:
		var wa = treeSkill("wallAnswers")
		if wa != null and cmdActive("player", "iron") and not jt(t.get("treeAnswerUsed")): t["treeAnswerUsed"] = 1; treeWallAnswer(t, u)   # H4 Thale T3b
	if landed and not jt(opts.get("intercept")) and u["side"] == "player" and jt(u.get("pflag")) and not jt(B["tr"].get("ledgerUsed")):
		var fl = treeSkill("flagshipLedger")
		if fl != null:
			var other = null
			for x in alive("player"):
				if x != u and not jt(x.get("isSq")) and jt(x.get("treeHasFired")): other = x; break
			if other != null:
				var lwi = -1; var bv = INF; var ii = 0
				for w2 in other["weapons"]:
					if not jt(w2.get("off")) and w2["k"] != "flak":
						var v2 = w2["dmg"] * w2["shots"]
						if v2 < bv: bv = v2; lwi = ii
					ii += 1
				if lwi >= 0:
					var lw = other["weapons"][lwi]; var best = null; var bs = -INF
					for t2 in alive("enemy"):
						var e2 = expectedVs(other, lw, t2); var v3 = e2["hull"] + e2["shield"] * 0.3
						if v3 > bs: bs = v3; best = t2
					if best != null and canFire(other, lw, best):
						B["tr"]["ledgerUsed"] = 1
						if treeExtraShot(other, lwi, best, {"half": true}): treeFx(u, "flagshipLedger", "the flagship calls in the debt")   # H4 Vex shared C1a
	if not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")): u["treeRedFirst"] = 0   # Razormaw capstone 1: the first shot spends it
	if landed and not jt(opts.get("intercept")) and u["side"] == "player" and not jt(u.get("isSq")) and treeSkill("rushRail") != null and cmdActive(u["side"], "surge") and not jt(u.get("treeRushLogged")):
		var nearR = false
		for xR in alive("enemy"):
			if not jt(xR.get("isSq")) and hdist(u, xR) == 1: nearR = true; break
		if nearR: u["treeRushLogged"] = 1; treeFx(u, "rushRail", "rush the rail")   # Grax T2b
	return landed
func landVolley(u, w, t, o) -> bool: # the shots of one weapon land (direct fire and torpedo impact)
	var quad = o["quad"]; var shots = o["shots"]; var called = o["called"]; var res = o["res"]; var shBefore = o["shBefore"]
	if called != null:
		u["crit"] = u["crit"] + 15; t["_calledSec"] = called
	var hiL = 0
	for h in shots:
		var shotIdx = hiL; hiL += 1
		if jt(t.get("dead")): break
		if not h:
			res.misses += 1; continue
		res.hits += 1
		var lfx = treeSkill("longFocus")
		if lfx != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and not jt(u.get("isSq")) and hdist(u, t) > float(w["r"]) / 2.0: treeFx(t, "longFocus", "the long focus bites")
		var iafx = treeSkill("inheritedAim")
		if iafx != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and not jt(u.get("isSq")) and z0(u.get("hexMoved")) == 0: treeFx(t, "inheritedAim", "the inherited aim holds")
		var npfx = treeSkill("namedPrey")
		if npfx != null and B != null and B.get("treeNamedPrey") != null and B["treeNamedPrey"]["r"] == B["round"] and u["side"] == "player" and t["id"] == B["treeNamedPrey"]["id"]: treeFx(t, "namedPrey", "the named prey falls")
		var bf = treeSkill("burnFlaw")
		if bf != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]:
			var n3 = z0(B["tr"]["volleyHits"].get(t["id"])) + 1; B["tr"]["volleyHits"][t["id"]] = n3
			if n3 >= 3: t["_treePierce"] = 1
			treeFx(t, "burnFlaw", "the third hit passes the shields" if n3 >= 3 else "hits stack")
		var ncF = treeSkill("noonChoice")
		if ncF != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(B.get("treeNoon")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: treeFx(u, "noonChoice", "the noon is chosen")   # Umbra T1b
		var efF = treeSkill("everyFrame")
		if efF != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and z0(u.get("hexMoved")) == 0: treeFx(u, "everyFrame", "every frame fires at noon")   # Umbra T3b
		var csF = treeSkill("coronaShadow")
		if csF != null and u["side"] == "player" and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: treeFx(u, "coronaShadow", "the noon throws no shadow")   # Umbra T3a
		var fiF = treeSkill("flagshipIndex")
		if fiF != null and u["side"] == "player" and jt(u.get("pflag")) and B["tr"].get("indexTarget") != null and t["id"] == B["tr"]["indexTarget"]["id"]: treeFx(u, "flagshipIndex", "the index is copied")   # Eclipse shared C1a
		var ucF = treeSkill("uncopiedTarget")
		if ucF != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and not jt(t.get("treeHitBattle")): treeFx(u, "uncopiedTarget", "the uncopied target is found")   # Ostrel T2b
		var rd2 = treeSkill("runDown")
		if rd2 != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and float(t["speed"]) < float(u["speed"]): treeFx(t, "runDown", "the slowest are run down")   # Razormaw T1a
		var as2 = treeSkill("acidSeams")
		if as2 != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player" and u["side"] == "player" and t["side"] == "enemy" and t["hp"] < t["maxHp"] / 2.0: treeFx(t, "acidSeams", "the acid finds the seams")   # Voice T3a
		var pcL = treeSkill("packCloses")
		if pcL != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge"):
			for x in alive("player"):
				if x != u and not jt(x.get("isSq")) and hdist(x, u) == 1: treeFx(u, "packCloses", "the pack closes"); break   # Grax T2a
		var pgL = treeSkill("patchGuns")
		if pgL != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(u.get("treeAimGuns")): treeFx(u, "patchGuns", "the patched guns find the mark")   # Vesh T1b
		var psL = treeSkill("preyScent")
		if psL != null and u["side"] == "player" and not jt(u.get("isSq")) and B.get("tr") != null and B["tr"].get("scent") == t.get("id"): treeFx(u, "preyScent", "the named prey is scented")   # Hullbreakers shared B1a
		var rBL = treeSkill("runBigger")
		if rBL != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and u.get("treeBigStart") != null and B.get("tr") != null and B["tr"].get("bigId") != null:
			var bigL = null
			for x in B["units"]:
				if x["id"] == B["tr"]["bigId"] and not jt(x.get("dead")): bigL = x; break
			if bigL != null and z0(u.get("hexMoved")) > 0 and hdist(u, bigL) < float(u["treeBigStart"]): treeFx(u, "runBigger", "the biggest thing is closer")   # Grax T1a
		var smL = treeSkill("smileCut")
		if smL != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(u.get("treeSmile")): treeFx(u, "smileCut", "the first cut smiles")   # Sable T3a
		var pbL = treeSkill("packBites")
		if pbL != null and u["side"] == "player" and not jt(u.get("isSq")) and u.get("treeDmgCarry") != null and u["treeDmgCarry"]["r"] == B["round"]: treeFx(u, "packBites", "the pack bites on")   # Vesh T3b
		var rq = treeIsRear(u, t, quad)
		if rq and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and not jt(u.get("treeTeethUsed")): u["treeTeethUsed"] = 1; treeFx(u, "teethThroat", "the teeth find the throat")   # Razormaw T1b
		if rq and quad != 2: treeFx(u, "debtHunts", "side hits count as rear")
		var kbL = treeSkill("knifeBack")
		if kbL != null and rq and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "hunt"): treeFx(u, "knifeBack", "the knife finds the back")   # Sable T1a
		var ctL = treeSkill("cutTurn")
		if ctL != null and rq and u["side"] == "player" and not jt(u.get("isSq")): u["treeFreeTurn"] = 1; treeFx(u, "cutTurn", "cut and turn")   # Sable T2a
		var ekL = treeSkill("everyKnife")
		if ekL != null and rq and u["side"] == "player" and not jt(u.get("isSq")):
			if B["tr"].get("rearShips") == null: B["tr"]["rearShips"] = {}
			var arrR = B["tr"]["rearShips"].get(t["id"]) if B["tr"]["rearShips"].get(t["id"]) != null else []
			if not arrR.has(u["id"]): arrR.append(u["id"])
			B["tr"]["rearShips"][t["id"]] = arrR
			if arrR.size() >= 3 and t.get("treeKnifeRound") == null: t["treeKnifeRound"] = B["round"] + 1; treeFx(t, "everyKnife", "three knives find one back")   # Sable T3b counter
		if rq and u["side"] == "player" and not jt(u.get("isSq")) and u.get("treeHuntRearNext") != null and u["treeHuntRearNext"]["r"] == B["round"]: treeFx(u, "darkKnives", "the dark keeps its knives"); u["treeHuntRearNext"] = null   # Sable capstone 1: spent on the first rear shot
		var cbF = treeSkill("copiedBehind")
		if cbF != null and rq and u["side"] == "player" and cmdActive(u["side"], "hunt"): treeFx(u, "copiedBehind", "the copy strikes the rear")   # Ostrel T1a
		var uaF = treeSkill("unseenArchive")
		if uaF != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and B.get("tr") != null and not jt(B["tr"]["targetedLast"].get(u["id"])): treeFx(u, "unseenArchive", "the unseen ship strikes")   # Ostrel T1b
		var stMul = 1.0
		var st2 = treeSkill("secondThroat")
		if st2 != null and jt(u.get("isSq")) and u["side"] == "player" and t["side"] == "enemy":
			var first = B["tr"]["swarmHitBy"].get(t["id"])
			if first != null and first != u["id"]:
				stMul = 1.0 + treeAddVal(u, "sqPct", st2["n"]); treeFx(u, "secondThroat", "the second throat bites")
			elif first == null:
				B["tr"]["swarmHitBy"][t["id"]] = u["id"]
		var tiL = treeSkill("totalInterdiction")
		if tiL != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "hunt"):
			if B["tr"]["totalShips"].get(t["id"]) == null: B["tr"]["totalShips"][t["id"]] = {}
			B["tr"]["totalShips"][t["id"]][u["id"]] = 1
			if B["tr"]["totalShips"][t["id"]].size() >= 3: treeFx(t, "totalInterdiction", "three ships have it")   # Vorn T3a
		var sbL = treeSkill("strikeBook")
		if sbL != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "hunt") and B["tr"].get("strikeSpeed") != null and float(u["speed"]) >= float(B["tr"]["strikeSpeed"]): treeFx(u, "strikeBook", "the book is followed")   # Vorn T1b
		var cfL = treeSkill("crossFire")
		if cfL != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and z0(B["tr"]["crossHits"].get(t["id"])) >= 1: treeFx(t, "crossFire", "the file is cross-referenced")   # Vorn T2a
		var pfL = treeSkill("permanentFile")
		if pfL != null and u["side"] == "player" and B.get("treePermFile") != null and B["treePermFile"]["r"] == B["round"] and jt(B["treePermFile"]["ids"].get(t["id"])): treeFx(t, "permanentFile", "the permanent file pays")   # Vorn capstone 1
		var prL = treeSkill("rehearsed")
		if prL != null and jt(u.get("isSq")) and u["side"] == "player" and jt(u.get("extra")) and cmdActive("player", "scramble"): treeFx(u, "rehearsed", "the procedure is rehearsed")   # Reyes T2b
		var d = (o["per"].call(rq) if o.get("per") != null else dmgMult(u, w, t, rq)) * (0.85 + rnd() * 0.3) * stMul
		if jt(o.get("half")): d = d * 0.5
		var itkF = treeSkill("iterationKill")
		if itkF != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and jt(B["tr"]["iterKill"].get(t["id"])):
			d = d * (1.0 + treeAddVal(u, "dmgPct", itkF["n"])); B["tr"]["iterKill"][t["id"]] = 0; treeFx(u, "iterationKill", "the next hit bites deeper")   # Ostrel T3a
		if o.get("halfShot") != null and int(o["halfShot"]) == shotIdx: d = d * 0.5   # Eclipse shared C1b
		var flightSec = null
		var fcL = treeSkill("flightCast")
		if fcL != null and jt(u.get("isSq")) and u["side"] == "player" and jt(u.get("extra")) and cmdActive("player", "scramble") and t["side"] == "enemy":
			var nFC = z0(B["tr"]["wingCap"].get(t["id"])) + 1; B["tr"]["wingCap"][t["id"]] = nFC
			if nFC > 1:
				t["_treePierce"] = 1; d = d * (1.0 + treeAddVal(u, "dmgPct", fcL["n"]))
				var bestFC = null; var brFC = 2.0
				if jt(t.get("sec")):
					for kFC in t["sec"].keys():
						var sFC = t["sec"][kFC]
						if jt(sFC.get("broken")): continue
						var rrFC = float(sFC["hp"]) / max(1.0, float(sFC["max"]))
						if rrFC < brFC: brFC = rrFC; bestFC = kFC
				if bestFC != null: flightSec = bestFC; t["_calledSec"] = bestFC
				treeFx(u, "flightCast", "the strike passes the shields")   # Tamsa capstone 1
		var ff2 = treeSkill("frenzyFeeds")
		if ff2 != null and u["side"] == "player" and not jt(u.get("isSq")) and cmdActive(u["side"], "surge") and rq and not jt(u.get("treeFrenzyMove")):
			u["treeFrenzyMove"] = 1; u["mp"] = z0(u.get("mp")) + float(ff2["n"]); u["postMp"] = max(z0(u.get("postMp")), float(ff2["n"])); treeFx(u, "frenzyFeeds", "the frenzy feeds the throat")   # Razormaw T3a
		var wd = treeSkill("wingsDebt")
		if wd != null and jt(u.get("isSq")) and u["side"] == "player" and not jt(B["tr"]["wingsDebt"].get(u.get("parent"))) and B["tr"]["carrierHit"].get(u.get("parent")) == t["id"]:
			d = d * (1.0 + treeAddVal(u, "sqPct", wd["n"])); B["tr"]["wingsDebt"][u.get("parent")] = 1; treeFx(u, "wingsDebt", "the wings settle the debt")
		var r = applyHit(u, w, t, d, quad)
		if jt(u.get("treeIterFire")): u["treeIterFire"] = 0   # Nadir T2a: the bonus belongs to the next shot only
		if flightSec != null and t.get("_calledSec") == flightSec: t["_calledSec"] = null
		if u["side"] == "player":
			B["tr"]["crossHits"][t["id"]] = z0(B["tr"]["crossHits"].get(t["id"])) + 1
			if cmdActive(u["side"], "hunt"): B["tr"]["hitDuringStrike"][t["id"]] = 1   # Vorn T2a, capstone 1
		var fpL = treeSkill("flightPaths")
		if fpL != null and jt(u.get("isSq")) and jt(u.get("extra")) and u["side"] == "player":
			var parL = null
			for xL in B["units"]:
				if xL["id"] == u.get("parent"): parL = xL; break
			if parL != null and B["tr"].get("carrierLast") != null and B["tr"]["carrierLast"].get(parL["id"]) == t["id"]: treeFx(u, "flightPaths", "the wing follows the glass")   # Tamsa T1a
		var rpL = treeSkill("replay")
		if rpL != null and jt(u.get("isSq")) and jt(u.get("extra")) and u["side"] == "player" and B["tr"].get("strikeAgain") == B["round"] and jt(B["tr"]["hitRound"].get(t["id"])): treeFx(u, "replay", "the replay corrects")   # Tamsa T2a
		var aspL = treeSkill("accountSplits")
		if aspL != null and jt(u.get("isSq")) and jt(u.get("extra")) and u["side"] == "player":
			var arrAC = B["tr"]["wingTargets"].get(u.get("parent")) if B["tr"].get("wingTargets") != null and B["tr"]["wingTargets"].get(u.get("parent")) is Array else []
			for xAC in arrAC:
				if xAC["sq"] != u["id"] and xAC["tid"] != t["id"]: treeFx(u, "accountSplits", "the account splits"); break   # Ashgrove T2a
		var laL = treeSkill("ledgerArcs")
		if laL != null and u["side"] == "player" and not jt(u.get("isSq")) and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and (w["arc"] == "P" or w["arc"] == "S"): treeFx(u, "ledgerArcs", "the broadside is on the ledger")   # Vex T1a
		var olL = treeSkill("oneLens")
		if olL != null and u["side"] == "player" and not jt(u.get("isSq")) and B["tr"].get("oneLens") != null and u["id"] == B["tr"]["oneLens"]["ship"] and t["id"] == B["tr"]["oneLens"]["tgt"] and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]: treeFx(u, "oneLens", "one lens, one target")   # Saro T1b
		var ltL = treeSkill("lightTogether")
		if ltL != null and u["side"] == "player" and not jt(u.get("isSq")) and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"]:
			var arrLT2 = B["tr"]["lightTgt"].get(t["id"]) if B["tr"].get("lightTgt") != null else null
			if arrLT2 is Array:
				for idLT2 in arrLT2:
					if idLT2 != u["id"]: treeFx(u, "lightTogether", "the light arrives together"); break   # Saro T2a
		var rrL = treeSkill("rearReckoning")
		if rrL != null and rq and u["side"] == "player" and cmdActive(u["side"], "hunt"): treeFx(u, "rearReckoning", "the rear arc reckons")   # Malek T2b
		if treeSkill("lightTogether") != null and u["side"] == "player" and not jt(u.get("isSq")) and not jt(o.get("intercept")):
			var arrLT3 = B["tr"]["lightTgt"].get(t["id"]) if B["tr"]["lightTgt"].get(t["id"]) is Array else []
			if not arrLT3.has(u["id"]): arrLT3.append(u["id"])
			B["tr"]["lightTgt"][t["id"]] = arrLT3   # Saro T2a counter
		if jt(u.get("isSq")) and u["side"] == "player":
			var arrWT = B["tr"]["wingTargets"].get(u.get("parent")) if B["tr"]["wingTargets"].get(u.get("parent")) is Array else []
			var hasWT = false
			for xWT in arrWT:
				if xWT["sq"] == u["id"] and xWT["tid"] == t["id"]: hasWT = true; break
			if not hasWT: arrWT.append({"sq": u["id"], "tid": t["id"]})
			B["tr"]["wingTargets"][u.get("parent")] = arrWT
			if jt(u.get("extra")): u["treeLastTgt"] = t["id"]   # Ashgrove T2a tracking, Tamsa capstone 2 target
		if jt(u.get("isSq")) and u["side"] == "player" and jt(u.get("extra")):
			var rtC = treeSkill("reTasked")
			if rtC != null and not jt(B["tr"]["wingStruck"].get(t["id"])): treeFx(u, "reTasked", "the wing takes a fresh target")   # Mott T2a
			var scC = treeSkill("screaming")
			if scC != null and jt(B["tr"]["hitRound"].get(t["id"])): treeFx(u, "screaming", "the wing comes back screaming")   # Mott T3b
			var pwC = treeSkill("privateWing")
			if pwC != null and jt(u.get("treePrivate")) and u.get("treePrivateRound") != B["round"]: u["treePrivateRound"] = B["round"]; treeFx(u, "privateWing", "the private wing strikes first")   # Mott capstone 2
		if jt(u.get("isSq")) and u["side"] == "player":
			B["tr"]["wingStruck"][t["id"]] = 1; B["tr"]["hitRound"][t["id"]] = 1
		elif u["side"] == "player":
			B["tr"]["hitRound"][t["id"]] = 1
		if jt(u.get("treeSmile")): u["treeSmile"] = 0   # Sable T3a: the bonus belongs to the first shot only
		var awF = treeSkill("arcsWarm")
		if awF != null and u["side"] == "player" and w.get("id") == "doom" and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == u["side"] and not jt(o.get("intercept")):
			var adjs = alive("enemy").filter(func(x): return not is_same(x, t))
			JSM.ssort(adjs, func(a, b):
				var dd = hdist(a, t) - hdist(b, t)
				if dd != 0: return dd
				return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
			if adjs.size() > 0:
				var adj = adjs[0]; var rr = applyHit(u, w, adj, d * float(awF["n"]), shieldQuad(adj, u)); res.hull += rr.hull
				if adj["hp"] <= 0: adj["killCause"] = "big"; killUnit(adj, u)
				treeFx(u, "arcsWarm", "the corona splashes")
		var bs3 = treeSkill("burnStays")
		if bs3 != null and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player" and u["side"] == "player" and not jt(u.get("isSq")) and t["side"] == "enemy":
			if B["tr"].get("burnStays") == null: B["tr"]["burnStays"] = {}
			B["tr"]["burnStays"][t["id"]] = z0(B["tr"]["burnStays"].get(t["id"])) + z0(r["hull"])   # Voice T2a
		if rq and u["side"] == "player" and cmdActive(u["side"], "hunt"): B["tr"]["iterKill"][t["id"]] = 1
		if u["side"] == "player" and not jt(t.get("isSq")): t["treeHitBattle"] = 1
		res.shield += r.shield; res.hull += r.hull
		if r.crit:
			res.crits += 1; var cs = ownerFx(u).get("critSys")
			if not jt(res.sys) and (jt(called) or jt(cs) or rnd() < 0.4):
				res.sys = systemDamage(t, called)
				if res.sys != null: emit({"t": "system", "unit": t["id"], "text": res.sys})
				if jt(cs) and jt(res.sys): boonFx(t, "a_crit", res.sys, -48)
	if res.hits > 0 and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player" and u["side"] == "player" and not jt(u.get("isSq")): u["treeVolleyHit"] = 1   # Voice capstone 1
	if res.hits > 0 and B != null and jt(B.get("volleyMul")) and B["volleyMul"]["side"] == "player" and u["side"] == "player" and not jt(u.get("isSq")) and treeSkill("manyMouths") != null:
		var arr = B["tr"]["volleyShips"].get(t["id"])
		if arr == null: arr = []
		if not arr.has(u["id"]): arr.append(u["id"])
		B["tr"]["volleyShips"][t["id"]] = arr   # Voice T3b counter
	if called != null:
		u["crit"] = u["crit"] - 15; t["_calledSec"] = null
	if res.hits > 0 and u["side"] == "player" and not jt(u.get("isSq")) and not jt(o.get("torp")) and not jt(o.get("intercept")) and (u.get("ab") == "launch" or z0(u.get("hangar")) > 0): B["tr"]["carrierHit"][u["id"]] = t["id"]   # Ashgrove T3b
	var rw = treeSkill("rollWings")
	if rw != null and jt(u.get("isSq")) and u["side"] == "player" and cmdActive("player", "scramble") and res.hits > 0 and not jt(o.get("intercept")) and not jt(t.get("dead")):
		t["st"]["fire"] = max(z0(t["st"].get("fire")), 2); t["st"]["fireDmg"] = max(t["st"]["fireDmg"] if jt(t["st"].get("fireDmg")) else 6, 6)
		t["treeFlakDown"] = z0(t.get("treeFlakDown")) + 1; treeFx(u, "rollWings", "the wing sets it burning")   # Ashgrove capstone 1
	if res.hits > 0 and jt(B.get("nem")):   # R42: weaknesses found by triggering them
		if jt(t.get("nem")) and u["side"] == "player":
			if quad == 2: nemTrip("flank")
			if (jt(w.get("ion")) or w.get("k") == "lance") and res.shield > 0: nemTrip("ion")
			if jt(o.get("torp")): nemTrip("torp")
		if jt(u.get("nem")) and t["side"] == "player" and not jt(u.get("isSq")) and hdist(u, t) <= 2: nemTrip("brawl")
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
	var maw = treeSkill("mawOpens")
	var mawAdd = treeAddVal(u, "ramPct", maw["n"]) if (maw != null and u["side"] == "player" and cmdActive(u["side"], "surge") and not jt(u.get("treeMawUsed"))) else 0.0   # Grax T3b
	var raw = base * (1.0 + z0(f.get("ramPct")) + mawAdd) * (u["ramBoost"] if jt(u.get("ramBoost")) else 1.0) * (1.0 if quad == 0 else 1.2) * (1.0 - t["armor"] * 0.5)
	var soak: float = min(raw * 0.5, float(z0(t["sh"][quad])) if t.get("sh") != null else 0.0)
	return {"dmg": JSM.jsround(min(raw - soak, t["maxHp"] * (0.4 + min(0.3, z0(f.get("ramCap")))))), "soak": JSM.jsround(soak),
		"recoil": JSM.jsround(base * (0.35 if jt(RAM_FAC.get(u["fac"])) else 0.5) * clamp_(float(t["size"]) / u["size"], 0.5, 1.6) * (1.0 - u["armor"] * 0.5) * (1.0 - min(1, z0(f.get("ramGuard"))))), "sec": SEC_OF_QUAD[quad]}
func ramUnit(u) -> bool:
	var mawPre = treeSkill("mawOpens") != null and u["side"] == "player" and cmdActive(u["side"], "surge") and not jt(u.get("treeMawUsed"))   # Grax T3b
	var info = ramInfo(u)
	if info == null: return false
	var t = info.t; var live = liveFrom(u)
	hook("move", u)
	if not live.call(): return false
	for p in info.path:
		u["q"] = p.q; u["r"] = p.r
	u["facing"] = info.path[info.path.size() - 1].f
	u["mp"] = 0; u["turnsLeft"] = 0; u["rammed"] = true
	if mawPre: u["treeMawUsed"] = 1; treeFx(u, "mawOpens", "the maw opens")   # Grax T3b: the first ram of the burn
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
	var fired_some = false
	for w in u["weapons"]:
		if jt(w.get("fired")): fired_some = true; break
	if fired_some:
		var rr = treeSkill("rushRail"); var wr = treeSkill("warlordRun")
		var okB = (rr != null and u["side"] == "player" and cmdActive(u["side"], "surge")) or (wr != null and u["side"] == "player" and jt(u.get("pflag")) and cmdActive(u["side"], "surge"))
		if not okB: return []   # Grax T2b and capstone 2: board after firing
	var o = []
	for t in alive("enemy" if u["side"] == "player" else "player"):
		if not jt(t.get("isSq")) and hdist(u, t) == 1: o.append(t)
	return o
func treeRailBonus(u) -> float:   # Grax T1b: a ship that crossed the burn at speed boards at +25% strength
	if u == null or jt(u.get("isSq")) or u["side"] != "player": return 0.0
	var r = treeSkill("railBoarding")
	return treeAddVal(u, "boardPct", r["n"]) if (r != null and cmdActive(u["side"], "surge") and z0(u.get("hexMoved")) >= 4) else 0.0
func captureChance(u, t) -> float:
	if t != null and jt(t.get("boss")): return 0.0
	var s: float = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct")) + treeRailBonus(u)) * 0.38
	if s <= 0: return 0.0
	var x: float = (t["crew"] - 0.5) / s
	return JSM.jsround(100.0 * max(0.0, min(1.0, (1.25 - x) / 0.5)))
func boardOdds(u, t) -> Dictionary:
	var a: float = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct")) + treeRailBonus(u))
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
	if jt(t.get("nem")) and u["side"] == "player": nemTrip("board")   # R42: his thin crews show once you board
	if treeRailBonus(u) > 0.0: treeFx(u, "railBoarding", "over the rail")   # Grax T1b
	var a = u["crew"] * (BOARD_MULT[u["fac"]] if jt(BOARD_MULT.get(u["fac"])) else 1.0) * (1.0 + z0(g(u.get("fx"), "boardPct")) + treeRailBonus(u)) * (0.75 + rnd() * 0.5)
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
		B["reviveUsed"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.25); flt(t, "Restarts", "#7dff9b", -30); logm("Second ignition. " + String(t["name"]) + " restarts at 25% hull.", "s"); return
	var legion = legionCan(t)
	if not legion and jt(t.get("reanimate")) and not jt(t.get("reanimated")) and not jt(t.get("pyre")) and not (t.get("fac") == "deathless" and jt(t.get("t")) and jt(t["t"].get("reanimate"))) and rnd() < (0.2 if t["side"] == "enemy" else 0.35):
		t["reanimated"] = true; t["hp"] = JSM.jsround(t["maxHp"] * 0.3); flt(t, "Rebuilding", "#7dff9b", -30); logm(String(t["name"]) + " reassembles itself from the wreckage.", "e"); return
	t["dead"] = true; t["hp"] = 0
	if treeSkill("trophyStandard") != null and by != null and by["side"] == "player" and jt(by.get("pflag")) and t["side"] == "enemy":
		for x in alive("player"):
			if not jt(x.get("isSq")) and not jt(x.get("dead")): x["treeFreeTurn"] = 1
		treeFx(by, "trophyStandard", "the trophy standard turns the fleet")   # Hullbreakers shared C1b
	if legion:
		t["reanimated"] = true; t["riseAt"] = B["round"] + 1; B["legion"][t["side"]]["used"] = B["legion"][t["side"]]["used"] + 1
		logm(String(t["name"]) + " falls, but its wreck is already reassembling. It rises next round.", pp(t)); flt(t, "Reassembling: rises next round", "#7dff9b", -30)
	syncLose(t); chorusFeed(t, by)
	var rfK = treeSkill("rollingFire")
	if rfK != null and t["side"] == "enemy" and by != null and by["side"] == "player" and not jt(by.get("isSq")) and inSync(by) and B.get("tr") != null and not jt(B["tr"].get("rollingUsed")):
		B["tr"]["rollingUsed"] = 1
		var cand = []
		for xK in alive("player"):
			if is_same(xK, by) or jt(xK.get("isSq")) or jt(xK.get("dead")) or not inSync(xK): continue
			var anyF = false
			for wK in xK["weapons"]:
				if jt(wK.get("fired")): anyF = true; break
			if not anyF: cand.append(xK)
		var bu = null; var bt = null; var bi = -1; var bs = -1e18
		for xK in cand:
			for iK in range(xK["weapons"].size()):
				var wK = xK["weapons"][iK]
				if wK["k"] == "flak" or jt(wK.get("off")) or z0(wK.get("cdLeft")) > 0: continue
				for eK in alive("enemy"):
					if jt(eK.get("isSq")) or is_same(eK, t) or jt(eK.get("dead")): continue
					if not canFire(xK, wK, eK): continue
					var e = expectedVs(xK, wK, eK); var sc = e["hull"] + e["shield"] * 0.3
					if sc > bs: bs = sc; bu = xK; bt = eK; bi = iK
		if bu != null and bt != null and treeExtraShot(bu, bi, bt, {}): treeFx(bu, "rollingFire", "another synced ship fires at once")   # Kassar T3a
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
func _has_reserve(side) -> bool:
	for u in B["units"]:
		if u["side"] == side and not jt(u.get("dead")) and jt(u.get("treeOff")): return true
	return false
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
	if caps("player").size() == 0 and not _has_reserve("player"):
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
	if bossDown or (sideCP("enemy") <= B["cp0"]["enemy"] * 0.35 and not jt(B.get("nemNoRout"))):   # R42: a Voidsworn or Deathless Nemesis fights to the last hull
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
	var v = cmdPow(c["id"], tier); var car = "brood" if fac == "chorus" else "launch ship"; var sq = "swarm" if fac == "chorus" else "squadron"
	var pct = func(x): return ns(JSM.jsround(x * 100.0)) + "%"
	match c["id"]:
		"barrage": return "Every ship fires a free extra volley right now at the best target in range" + ((", with +" + pct.call(v) + " damage") if jt(v) else "") + ". Its normal shots this round still happen."
		"hunt": return ("Every ship deals +" + pct.call(v) + " damage for the rest of this round.") if fac == "hegemony" else ("Torpedoes reload at once and every ship deals +" + pct.call(v) + " damage for the rest of this round.")
		"scramble": return "Every " + car + " launches " + ("two extra wings" if tier >= 2 else "an extra wing") + " right now if there are open adjacent hexes, even past its hangar limit. Then every " + sq + " you have makes a bonus attack immediately, with +" + pct.call(v) + " damage."
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
# ---------- admiral tree effects (issue #305 job 1: H0 plumbing, H1 choice, H2 counters, H3 next round) ----------
func treeBuild() -> Array:
	var out = []; if RUN == null or RUN.get("lineage") == null: return out
	var L = RUN["lineage"]; if not (L is Dictionary) or not LINEAGE_TREES.has(L.get("id")): return out
	var picks = L.get("picks")
	if picks is Array:
		for pick in picks:
			var key = str(pick)
			if not key.begins_with(str(L["id"]) + ":"): key = str(L["id"]) + ":" + key  # #335: old saves and the campaign store short picks ("A:0:0"); TREE_FX is keyed "admiral:A:0:0"
			if TREE_FX.has(key):
				var s = TREE_FX[key].duplicate(true); s["key"] = key; out.append(s)
	if L.get("capstone") != null:
		var key = str(L["id"]) + ":cap:" + str(int(L["capstone"]))
		if TREE_FX.has(key):
			var s2 = TREE_FX[key].duplicate(true); s2["key"] = key; out.append(s2)
	return out
func treeSkill(k) -> Variant:
	if B == null or B.get("tree") == null: return null
	for s in B["tree"]:
		if s.get("k") == k: return s
	return null
func treeHas(k) -> bool: return treeSkill(k) != null
func treeName(key) -> String:
	var p = str(key).split(":"); var id = p[0]; var b = p[1]
	var tree = LINEAGE_TREES.get(id)
	if tree == null: return str(key)
	if b == "cap":
		var c0 = int(p[2]); var caps = tree.get("capstones", [])
		return str(caps[c0]["n"]) if c0 < caps.size() else str(key)
	var t = int(p[2]); var c = int(p[3])
	var br = tree["branches"].get(b)
	if br == null: return str(key)
	var tiers = br.get("tiers", [])
	if t >= tiers.size(): return str(key)
	var pair = tiers[t]
	return str(pair[c]["n"]) if c < pair.size() else str(key)
func treeFx(u, kind, txt) -> void:
	var s = treeSkill(kind); if s == null or B == null: return
	if B.get("treeStats") == null: B["treeStats"] = {}
	B["treeStats"][s["key"]] = z0(B["treeStats"].get(s["key"])) + 1
	if B.get("tr") == null: B["tr"] = {}
	if B["tr"].get("logged") == null: B["tr"]["logged"] = {}
	if not jt(B["tr"]["logged"].get(s["key"])):
		B["tr"]["logged"][s["key"]] = 1; var nm = treeName(s["key"])
		flt(u, nm + ": " + str(txt), "#e8c66a", -60)
		logm("Lineage: " + nm + ". " + str(txt), "p" if (u != null and u.get("side") == "player") else "e")
func treeAddVal(u, key, v) -> float:
	if not TB.FX_CAPS.has(key): return float(v)
	var have = z0(u["fx"].get(key)) if (u != null and jt(u.get("fx"))) else 0.0
	return max(0.0, min(float(v), float(TB.FX_CAPS[key]) - have))
# Eclipse (issue #305 job 3): H8 hull cut, H9 repair and H11 movement helpers, one place each.
func treeFlagUnit() -> Variant:
	for x in B["units"]:
		if jt(x.get("pflag")) and not jt(x.get("dead")): return x
	var l = alive("player")
	return l[0] if l.size() > 0 else null
func treeMarkRepair(u) -> void:
	if B != null and B.get("tree") != null and B["tree"].size() > 0 and u != null and u.get("side") == "player" and not jt(u.get("isSq")):
		u["treeRepaired"] = 1; u["treeRepairedRound"] = B["round"]
# Hullbreakers (issue #305 job 5): H2 a missed torpedo reloads one turn sooner than normal
func treeSecondKnife(real) -> bool:
	if real == null or jt(real.get("dead")) or real["side"] != "player": return false
	if treeSkill("secondKnife") == null: return false
	for rw in real["weapons"]:
		if rw["k"] == "torp":
			rw["cdLeft"] = max(0, z0(rw.get("cdLeft")) - 1); treeFx(real, "secondKnife", "the second knife comes free"); return true
	return false
func treeInEnemyRear(u) -> bool:
	for t in alive("enemy"):
		if not jt(t.get("isSq")) and shieldQuad(t, u) == 2: return true
	return false
func treeInEnemyFront(u) -> bool:
	for t in alive("enemy"):
		if not jt(t.get("isSq")) and inArc(t, u, "F"): return true
	return false
func treeRearApproach(u) -> Variant:
	var best = null; var bd = 1e9
	for t in alive("enemy"):
		if jt(t.get("isSq")): continue
		var d = hdist(u, t)
		if d < bd or (d == bd and best != null and str(t["id"]) < str(best["id"])): bd = d; best = t
	if best == null: return null
	var d2 = DIRS[(int(best["facing"]) + 3) % 6]; return {"q": int(best["q"]) + int(d2[0]), "r": int(best["r"]) + int(d2[1])}
func treeStepToward(u, goal, steps) -> int:
	var moved = 0
	for s in range(int(steps)):
		var best = null; var bd = hdist(u, goal); var occ = occMap()
		for d in DIRS:
			var nq = int(u["q"]) + int(d[0]); var nr = int(u["r"]) + int(d[1])
			if not onBoard(nq, nr) or blocks(terr(nq, nr)) or occ.has(hkey(nq, nr)): continue
			var dd = hdist({"q": nq, "r": nr}, goal)
			if dd < bd: bd = dd; best = {"q": nq, "r": nr}
		if best == null: break
		u["q"] = best["q"]; u["r"] = best["r"]; moved += 1
	return moved
# H3: the Sunward Glass capstone 1 volley returns at the next round start; the turn flows call this one place after a player start
func treeRoundFx() -> void:
	if B == null or jt(B.get("over")): return
	if B.get("treeStrikeRound") == B["round"]:
		for sq in alive("player"):
			if jt(B.get("over")): break
			if not jt(sq.get("isSq")) or not jt(sq.get("treeStrikeNow")) or jt(sq.get("dead")): continue
			sq["treeStrikeNow"] = 0
			if treeWingStrikeNow(sq): treeFx(sq, "secondWave", "the held wing strikes")
		B["treeStrikeRound"] = 0
	if B.get("treeForgeRound") == B["round"] and B.get("treeForgeList") != null:
		var listF = B["treeForgeList"]; B["treeForgeRound"] = 0; B["treeForgeList"] = null; var sF = treeSkill("forgeAhead")
		for eF in listF:
			if jt(B.get("over")): break
			var tgtF = null
			for xF in B["units"]:
				if xF["id"] == eF.get("tid") and not jt(xF.get("dead")): tgtF = xF; break
			if tgtF == null: continue
			var sqF = null
			for xF2 in alive("player"):
				if jt(xF2.get("isSq")) and jt(xF2.get("extra")) and xF2.get("parent") == eF.get("carrier") and not jt(xF2.get("dead")): sqF = xF2; break
			if sqF == null: continue
			var oldB = sqF.get("treeBonus")
			if sF != null: sqF["treeBonus"] = z0(oldB) + treeAddVal(sqF, "sqPct", sF["n"])
			if treeWingStrikeAt(sqF, tgtF): treeFx(sqF, "forgeAhead", "one wing per carrier strikes again")
			sqF["treeBonus"] = oldB
	if B.get("treeDebtRound") == B["round"]:
		B["treeDebtRound"] = 0
		var bD = B; B["volleyMul"] = {"side": "player", "m": 1.0 + z0(B.get("treeDebtPow"))}; B["treeDebtDue"] = 1
		for uD in alive("player"):
			if jt(uD.get("isSq")): continue
			if jt(B.get("over")): break
			treeFreeVolleyShip(uD, "enemy", false)
		B["treeDebtDue"] = 0
		if is_same(B, bD): B["volleyMul"] = null
		if is_same(B, bD) and not jt(B.get("over")): treeFx(treeFlagUnit(), "debtDue", "the interest comes due")
	if jt(B.get("treeSpatRound")) and B["treeSpatRound"] == B["round"]:
		B["treeSpatRound"] = 0
		var bS = B; B["volleyMul"] = {"side": "player", "m": 1.0}
		for idS in (B.get("treeSpatIds") if B.get("treeSpatIds") != null else []):
			var uS = null
			for x in B["units"]:
				if x["id"] == idS and not jt(x.get("dead")) and not jt(x.get("isSq")): uS = x; break
			if uS == null or jt(B.get("over")): continue
			treeFreeVolleyShip(uS, "enemy", true)
		if is_same(B, bS): B["volleyMul"] = null
		if is_same(B, bS) and not jt(B.get("over")): treeFx(treeFlagUnit(), "spatRounds", "the held spit spits now")   # Voice T2b: the held half volley fires at half damage
	if not jt(B.get("treeNoonRound")) or B["treeNoonRound"] != B["round"]: return
	B["treeNoonRound"] = 0
	var b0 = B; B["volleyMul"] = {"side": "player", "m": 1.0}
	for u in alive("player"):
		if jt(u.get("isSq")): continue
		if jt(B.get("over")): break
		treeFreeVolleyShip(u, "enemy", true)
	if is_same(B, b0): B["volleyMul"] = null
	if is_same(B, b0) and not jt(B.get("over")): treeFx(treeFlagUnit(), "noonRepeat", "the noon volley returns")
func treeChoice(kind) -> Variant:
	if B == null: return null
	var tc = B.get("treeChoices"); var c = tc.get(kind) if tc is Dictionary else null
	if c != null:
		for x in B["units"]:
			if x["id"] == c and not jt(x.get("dead")): return x
	var l = []
	if kind == "carrier" or kind == "brood":
		for x in alive("player"):
			if not jt(x.get("isSq")) and x.get("ab") == "launch": l.append(x)
		JSM.ssort(l, func(a, b):
			var d = z0(b.get("hangar")) - z0(a.get("hangar"))
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	elif kind == "enemy":
		for x in alive("enemy"):
			if not jt(x.get("isSq")): l.append(x)
		JSM.ssort(l, func(a, b):
			var d = b["maxHp"] - a["maxHp"]
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	elif kind == "ship" or kind == "friend":
		for x in alive("player"):
			if not jt(x.get("isSq")): l.append(x)
		JSM.ssort(l, func(a, b):
			var d = (a["hp"] / max(1.0, a["maxHp"])) - (b["hp"] / max(1.0, b["maxHp"]))
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	elif kind == "reserve":
		for x in alive("player"):
			if not jt(x.get("isSq")) and not jt(x.get("pflag")): l.append(x)
		JSM.ssort(l, func(a, b):
			var d = (a["hp"] / max(1.0, a["maxHp"])) - (b["hp"] / max(1.0, b["maxHp"]))
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	elif kind == "largest":
		for x in alive("player"):
			if not jt(x.get("isSq")) and x.get("ab") != "launch" and not (z0(x.get("hangar")) > 0): l.append(x)
		JSM.ssort(l, func(a, b):
			var d = b["maxHp"] - a["maxHp"]
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	elif kind == "other":
		for x in alive("player"):
			if not jt(x.get("isSq")) and not jt(x.get("pflag")): l.append(x)
		JSM.ssort(l, func(a, b):
			var d = (a["hp"] / max(1.0, a["maxHp"])) - (b["hp"] / max(1.0, b["maxHp"]))
			if d != 0: return d
			return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	return l[0] if l.size() > 0 else null
func treePrey() -> Variant:
	var s = treeSkill("razorPrey")
	if s == null or B == null or B.get("treeRazorPrey") == null or B["treeRazorPrey"]["r"] != B["round"]: return null
	for x in B["units"]:
		if x["id"] == B["treeRazorPrey"]["id"] and not jt(x.get("dead")): return x
	return null
func treeMoveBonus(u) -> float:
	if u == null or jt(u.get("isSq")) or u["side"] != "player": return 0.0
	var s = treeSkill("razorPrey")
	return float(s["n"]) if (s != null and treePrey() != null) else 0.0
# Hegemony Navy (issue #305 job 6): one helper per hook, called from one place.
func treeHegSyncR() -> float:
	var wn = treeSkill("wideNet"); var lr = treeSkill("livingRelay")
	var r = TB.SYNC_R + (float(wn["n"]) if wn != null else 0.0)
	if lr != null: r *= 2.0
	return r
func treeShieldOver(u, frac) -> int:
	if u == null or jt(u.get("dead")) or jt(u.get("isSq")) or not (z0(u.get("shMax")) > 0): return 0
	var cap = JSM.jsround(float(u["shMax"]) * 1.25); var add = JSM.jsround(float(u["shMax"]) * float(frac)); var any = 0
	for i in range(4):
		var cur = z0(u["sh"][i])
		if cur < z0(u["shMax"]): continue
		var v = min(cap, cur + add)
		if v > cur: any += v - cur; u["sh"][i] = v
	return any
func _treeLineVal(v, k) -> int:
	if k == 0: return int(v["r"])
	if k == 1: return int(v["q"])
	if k == 2: return int(v["q"]) + int(v["r"])
	return int(v["q"]) + int(floor(float(v["r"]) / 2.0))
func treeInColumn(u) -> bool:
	if u == null or jt(u.get("isSq")) or u["side"] != "player": return false
	var fleet = []
	for x in alive("player"):
		if not jt(x.get("isSq")) and not jt(x.get("dead")): fleet.append(x)
	var fg = treeFlagUnit(); var joins = treeSkill("flagshipStandard") != null
	for k in range(4):
		var base = _treeLineVal(u, k); var n = 1; var fgOn = false
		for v in fleet:
			if is_same(v, u): continue
			if _treeLineVal(v, k) == base:
				n += 1
				if fg != null and is_same(v, fg): fgOn = true
		if joins and fg != null and not is_same(fg, u) and not fgOn: n += 1
		if n >= 3: return true
	return false
func treeInFlagLine(u) -> bool:
	var fg = treeFlagUnit()
	if u == null or fg == null or is_same(u, fg) or jt(u.get("isSq")) or u["side"] != "player": return false
	for k in range(4):
		if _treeLineVal(u, k) == _treeLineVal(fg, k): return true
	return false
func treeOffenseAt(u, q, r) -> float:
	var v = stateView(u, {"q": q, "r": r, "f": u["facing"]}); var s = 0.0
	for w in u["weapons"]:
		if not weaponReady(w) or w["k"] == "flak": continue
		var b = 0.0
		for t in alive("enemy"):
			if jt(t.get("isSq")): continue
			if not inReach(v, w, t): continue
			var e = expectedVs(v, w, t); var val = e["hull"] + e["shield"] * 0.3
			if val > b: b = val
		s += b
	return s
func treeRotSwap(u) -> void:
	if treeSkill("rotation") == null or u == null or jt(u.get("isSq")) or u["side"] != "player" or jt(u.get("dead")) or not cmdActive(u["side"], "iron") or jt(u.get("treeRotUsed")): return
	var best = null; var bs = -1e18
	for v in alive("player"):
		if is_same(v, u) or jt(v.get("isSq")) or jt(v.get("dead")) or jt(v.get("treeRotUsed")): continue
		if hdist(v, u) != 1: continue
		var gain = treeOffenseAt(v, u["q"], u["r"]) - treeOffenseAt(v, v["q"], v["r"])
		if gain > bs: bs = gain; best = v
	if best != null:
		var q = u["q"]; var r = u["r"]; u["q"] = best["q"]; u["r"] = best["r"]; best["q"] = q; best["r"] = r
		u["treeRotUsed"] = 1; best["treeRotUsed"] = 1; treeFx(best, "rotation", "the line rotates")
func treeDrillMove() -> void:
	var wl = []
	for x in alive("player"):
		if not jt(x.get("isSq")) and not jt(x.get("dead")): wl.append(x)
	JSM.ssort(wl, func(a, b):
		var d = (a["hp"] / max(1.0, a["maxHp"])) - (b["hp"] / max(1.0, b["maxHp"]))
		if d != 0: return d
		return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	if wl.size() == 0: return
	var who = wl[0]; var occ = occMap(); var best = {"q": who["q"], "r": who["r"]}; var bs = -1e18
	for h in boardHexes():
		if hdist(h, who) > 2 or blocks(terr(h.q, h.r)) or occ.has(hkey(h.q, h.r)): continue
		var md = 99.0
		for e in alive("enemy"):
			if not jt(e.get("isSq")): md = min(md, hdist(h, e))
		if md > bs or (md == bs and (h.q < best["q"] or (h.q == best["q"] and h.r < best["r"]))): bs = md; best = h
	if best["q"] != who["q"] or best["r"] != who["r"]: who["q"] = best["q"]; who["r"] = best["r"]; treeFx(who, "drillRevision", "the drill is revised")
func treePathTowardFlag(u, s) -> bool:
	var fg = treeFlagUnit()
	if fg == null: return false
	var d0 = hdist(u, fg)
	for p in (s["path"] if s.get("path") != null else []):
		if jt(p.get("rot")): continue
		if hdist({"q": p.q, "r": p.r}, fg) > d0: return false
	return true
func treeMoveTowardFlag(u, path, d0) -> bool:
	if treeSkill("standardForward") == null or u == null or jt(u.get("isSq")) or u["side"] != "player": return false
	var fg = treeFlagUnit()
	if fg == null: return false
	var steps = 0
	for p in path:
		if jt(p.get("rot")): continue
		if hdist({"q": p.q, "r": p.r}, fg) > float(d0): return false
		steps += 1
	if steps > 0: treeFx(u, "standardForward", "the standard carries the line")
	return steps > 0
func treeSecondVolleyOK(u, w, t) -> bool:
	if treeSkill("secondVolley") == null or u == null or jt(u.get("isSq")) or jt(u.get("dead")) or t == null or jt(t.get("dead")) or u["side"] != "player" or w["k"] == "flak": return false
	if not inSync(u): return false
	var sf = B["tr"]["syncFirst"].get("player") if (B != null and B.get("tr") != null and B["tr"].get("syncFirst") != null) else null
	if sf == null or sf["r"] != B["round"] or sf["id"] != t["id"] or jt(B["tr"].get("secondVolleyUsed")): return false
	var d = hdist(u, t)
	if d < 1 or d > w["r"] or treeDeepBlocks(u, t) or not los(u, t): return false
	return not inArc(u, t, w["arc"])
func treeArcLegal(u, w, t) -> bool:
	if u == null or jt(u.get("dead")) or t == null or jt(t.get("dead")) or u["side"] == t["side"] or jt(u.get("braced")) or w["k"] == "flak" or not weaponReady(w): return false
	var d = hdist(u, t)
	return d >= 1 and d <= w["r"] and not treeDeepBlocks(u, t) and los(u, t)
func treeRangeLegal(u, w, t) -> bool:
	if u == null or jt(u.get("dead")) or t == null or jt(t.get("dead")) or u["side"] == t["side"] or jt(u.get("braced")) or w["k"] == "flak" or not weaponReady(w): return false
	return not treeDeepBlocks(u, t) and los(u, t)
func treeSecondVolleyAuto(src, t) -> void:
	if treeSkill("secondVolley") == null or B == null or B.get("tr") == null or jt(B["tr"].get("secondVolleyAutoDone")): return
	var sf = B["tr"]["syncFirst"].get("player") if B["tr"].get("syncFirst") != null else null
	if sf == null or sf["r"] != B["round"] or sf["id"] != t["id"]: return
	B["tr"]["secondVolleyAutoDone"] = 1
	for x in alive("player"):
		if is_same(x, src) or jt(x.get("isSq")) or jt(x.get("dead")) or not inSync(x): continue
		var anyF = false
		for wF in x["weapons"]:
			if jt(wF.get("fired")): anyF = true; break
		if anyF: continue
		for i in range(x["weapons"].size()):
			var w = x["weapons"][i]
			if w["k"] == "flak" or jt(w.get("off")) or z0(w.get("cdLeft")) > 0: continue
			if canFire(x, w, t) or not treeArcLegal(x, w, t): continue
			if treeExtraShot(x, i, t, {"forceArc": true}): treeFx(x, "secondVolley", "one more synced ship fires out of arc"); return
func treeVolleyAt(u, t) -> void:
	if u == null or t == null or jt(u.get("dead")) or jt(t.get("dead")) or jt(B.get("over")): return
	var b0 = B; var keep = []
	for w in u["weapons"]: keep.append([w.get("fired"), w.get("cdLeft")])
	var pf = [u.get("postFire"), u.get("postMp")]
	for w in u["weapons"]: w["fired"] = false; w["cdLeft"] = 0
	for i in range(u["weapons"].size()):
		if not is_same(B, b0) or jt(B.get("over")) or jt(u.get("dead")) or jt(t.get("dead")): break
		var w = u["weapons"][i]
		if w["k"] == "flak" or jt(w.get("off")): continue
		if canFire(u, w, t): fireWeapon(u, i, t)
	for i in range(u["weapons"].size()): u["weapons"][i]["fired"] = keep[i][0]; u["weapons"][i]["cdLeft"] = keep[i][1]
	u["postFire"] = pf[0]; u["postMp"] = pf[1]
func treeWingStrikeAt(sq, t) -> bool:
	if sq == null or jt(sq.get("dead")) or t == null or jt(t.get("dead")) or jt(B.get("over")): return false
	var fired = false
	for i in range(sq["weapons"].size()):
		if jt(B.get("over")) or jt(sq.get("dead")) or jt(t.get("dead")): break
		if canFire(sq, sq["weapons"][i], t): fireWeapon(sq, i, t); fired = true
	return fired
func treeWingStrikeNow(sq) -> bool:
	if sq == null or jt(sq.get("dead")) or jt(B.get("over")): return false
	var fired = false
	for i in range(sq["weapons"].size()):
		if jt(B.get("over")) or jt(sq.get("dead")): break
		var best = null; var bv = 0.0
		for t in alive("enemy"):
			if not canFire(sq, sq["weapons"][i], t): continue
			var e = expectedVs(sq, sq["weapons"][i], t); var v = e["hull"] + e["shield"] * 0.3 + (20.0 if e["hull"] >= t["hp"] else 0.0)
			if v > bv: bv = v; best = t
		if best != null: fireWeapon(sq, i, best); fired = true
	return fired
func treePatrolStrike(enemy) -> void:
	if treeSkill("standingGroup") == null or enemy == null or jt(enemy.get("dead")) or jt(enemy.get("isSq")) or enemy["side"] != "enemy": return
	for sq in alive("player"):
		if not jt(sq.get("isSq")) or not jt(sq.get("treePatrol")) or jt(sq.get("dead")) or sq.get("treePatrolRound") == B["round"]: continue
		var p = null
		for x in B["units"]:
			if x["id"] == sq.get("parent") and not jt(x.get("dead")): p = x; break
		if p == null: continue
		var rr = 0.0
		for w in p["weapons"]:
			if w["k"] == "flak": continue
			rr = max(rr, float(w.get("r", 0)))
		if rr == 0.0: rr = 6.0
		if hdist(p, enemy) > rr: continue
		var fired = false
		for i in range(sq["weapons"].size()):
			if jt(B.get("over")) or jt(sq.get("dead")) or jt(enemy.get("dead")): break
			if canFire(sq, sq["weapons"][i], enemy) or treeRangeLegal(sq, sq["weapons"][i], enemy):
				if treeExtraShot(sq, i, enemy, {"forceArc": true, "forceRange": true}): fired = true
		if fired: sq["treePatrolRound"] = B["round"]; treeFx(sq, "standingGroup", "the patrol strikes the intruder")
func treeFacingTo(u, t) -> int:
	var a = angTo(u, t)
	return int(posmod(JSM.jsround(a / 60.0), 6))
func treeLaunchHexes(u, r) -> Array:
	var occ = occMap(); var out = []
	for h in boardHexes():
		var d = hdist(u, h)
		if d < 1 or d > r or blocks(terr(h.q, h.r)) or occ.has(hkey(h.q, h.r)): continue
		out.append(h)
	return out
func treeBestFacing(u) -> Variant:
	var foes = []
	for t in alive("enemy" if u["side"] == "player" else "player"):
		if not jt(t.get("dead")): foes.append(t)
	if foes.size() == 0: return null
	var best = null; var bv = 0.0
	for f in range(6):
		if f == int(u["facing"]): continue
		var v = stateView(u, {"q": u["q"], "r": u["r"], "f": f}); var score = 0.0
		for w in u["weapons"]:
			if not weaponReady(w): continue
			for t in foes:
				if inReach(v, w, t):
					var e = expectedVs(v, w, t); score += e["hull"] + e["shield"] * 0.3
		if score > bv: bv = score; best = f
	return best if bv > 0.0 else null
func _treeFlag() -> Variant:
	for x in B["units"]:
		if jt(x.get("pflag")) and not jt(x.get("dead")): return x
	var l = alive("player")
	return l[0] if l.size() > 0 else null
func treeRoundStart() -> void:
	if B == null or B.get("tree") == null or B["tree"].size() == 0: return
	if B.get("tr") == null: B["tr"] = {}
	var prevStrike = B["tr"].get("hitDuringStrike").duplicate(true) if B["tr"].get("hitDuringStrike") is Dictionary else {}
	B["treePermFile"] = ({"r": B["round"], "m": cmdPow("hunt", B["cmd"]["tier"]), "ids": prevStrike} if (treeSkill("permanentFile") != null and B.get("cmd") != null and B["cmd"]["id"] == "hunt" and B["cmd"]["round"] == B["round"] - 1) else null)
	B["tr"]["enemyShots"] = {}; B["tr"]["volleyHits"] = {}; B["tr"]["logged"] = {}; B["tr"]["volleyPick"] = {}; B["tr"]["wingsDebt"] = {}; B["tr"]["standardUsed"] = 0; B["tr"]["escortUsed"] = {}
	B["tr"]["smileUsed"] = 0; B["tr"]["rearShips"] = {}; B["tr"]["wingStruck"] = {}; B["tr"]["hitRound"] = {}
	B["tr"]["targetedLast"] = B["tr"].get("targeted") if B["tr"].get("targeted") != null else {}; B["tr"]["targeted"] = {}; B["tr"]["iterKill"] = {}
	B["tr"]["swarmHitBy"] = {}; B["tr"]["volleyShips"] = {}; B["tr"]["volleyHit"] = {}; B["tr"]["burnStays"] = null
	B["tr"]["syncFirst"] = {"player": null, "enemy": null}; B["tr"]["secondVolleyUsed"] = 0; B["tr"]["secondVolleyAutoDone"] = 0; B["tr"]["rollingUsed"] = 0; B["tr"]["strikeSpeed"] = null; B["tr"]["strikeSpeedId"] = null
	B["tr"]["crossHits"] = {}; B["tr"]["totalShips"] = {}; B["tr"]["hitDuringStrike"] = {}; B["tr"]["bellUsed"] = 0; B["tr"]["columnUsed"] = 0; B["tr"]["firstStopTarget"] = null; B["tr"]["firstStopDone"] = 0
	B["tr"]["wingFiled"] = null; B["tr"]["escortScreen"] = 0; B["tr"]["beacon"] = null
	B["tr"]["wingTgt"] = {}; B["tr"]["wingTargets"] = {}; B["tr"]["lightTgt"] = {}; B["tr"]["wingCap"] = {}; B["tr"]["wingCapFirst"] = {}
	B["tr"]["swarmHunger"] = null
	B["tr"]["sunTarget"] = null; B["tr"]["sunFirstDone"] = 0; B["tr"]["grandTarget"] = null; B["tr"]["grandFirstDone"] = 0; B["tr"]["oneLens"] = null
	B["treeWeakShip"] = null; B["treeShiftUp"] = null; B["treeShiftDown"] = null; B["treeWallEarly"] = 0
	B["treeIronExtra"] = null
	for u in alive("player"):
		if not jt(u.get("isSq")):
			u["treeHuntNext"] = 0; u["treeHuntCarry"] = 0; u["treeTorpCarry"] = 0; u["ironCarry"] = 0; u["treeAimNext"] = 0; u["treeRoundDmg"] = 0; u["treeRoundFired"] = 0; u["treeSilentMark"] = 0; u["treeDmgNext"] = 0; u["treeRedFirst"] = 0; u["treeAcidAim"] = 0; u["tempHp"] = 0; u["treeFrenzyMove"] = 0; u["treeVolleyHit"] = 0; u["treeSmile"] = 0; u["treeAimGuns"] = 0; u["treeFreeTurn"] = 0; u["treeRushLogged"] = 0; u["burnCarry"] = null; u["treeFormation"] = 0; u["treeRotUsed"] = 0; u["treeOverflowUsed"] = 0; u["treeDiveUsed"] = 0; u["treeLensRot"] = 0; u["treeWardFacing"] = null; u["treeSalvoUsed"] = 0; u["treeShadowPos"] = 0; u["treeEclForm"] = 0; u["treeTeethUsed"] = 0; u["treeIterFire"] = 0; u["treeAimTgt"] = null; u["treeHpStart"] = u["hp"]
	if B.get("treeReserve") != null and B["treeReserve"].size() > 0 and B["round"] >= 2:
		var keepR = []
		var rk = "broodReserve" if treeSkill("broodReserve") != null else "debtsReserve"
		for id in B["treeReserve"]:
			var u = null
			for x in B["units"]:
				if x["id"] == id: u = x; break
			if u == null or jt(u.get("dead")): continue
			var h = edgeHex("player"); u["treeOff"] = 0
			if h != null: u["q"] = h.q; u["r"] = h.r
			u["hp"] = u["maxHp"]; u["treeReserve"] = 0; u["activated"] = false
			treeFx(u, rk, "the reserve joins the line")
		B["treeReserve"] = keepR
	if B.get("treePending") != null and B["treePending"].size() > 0:
		var keep = []
		for p in B["treePending"]:
			if p["r"] >= B["round"]: keep.append(p); continue
			if p["k"] == "rechargeLit":
				var s = treeSkill("rechargeLit"); var any = false
				for u in alive("player"):
					if jt(u.get("isSq")) or not jt(u.get("shMax")): continue
					if z0(u["st"].get("shieldOff")) >= 99: continue
					for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + u["regen"])
					any = true
				if any and s != null: treeFx(_treeFlag(), "rechargeLit", "shields recharge a second time")
			if p["k"] == "holdCounted":
				for u in alive("player"):
					if not jt(u.get("isSq")) and z0(u.get("hexMoved")) == 0: u["ironCarry"] = z0(p.get("pow"))
				treeFx(_treeFlag(), "holdCounted", "the wall holds one more round")
			if p["k"] == "oathStillness":
				for u in alive("player"):
					if not jt(u.get("isSq")) and jt(u.get("shMax")) and z0(u.get("hexMoved")) == 0:
						for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + JSM.jsround(u["shMax"] * 0.5))
				treeFx(_treeFlag(), "oathStillness", "the stillness recharges the wall")
			if p["k"] == "ironTestament":
				B["treeIronExtra"] = {"r": B["round"], "pow": z0(p.get("pow"))}
				for u in alive("player"):
					if not jt(u.get("isSq")) and jt(u.get("shMax")):
						for i in range(4): u["sh"][i] = min(u["shMax"], u["sh"][i] + JSM.jsround(u["shMax"] * 0.5))
				treeFx(_treeFlag(), "ironTestament", "the wall stands a second round")
			if p["k"] == "salvoTwoHands":
				for id in (p.get("ids") if p.get("ids") != null else []):
					var u2 = null
					for x in B["units"]:
						if x["id"] == id: u2 = x; break
					if u2 != null and not jt(u2.get("dead")) and not jt(u2.get("isSq")): u2["treeHuntCarry"] = z0(p.get("pow"))
				treeFx(_treeFlag(), "salvoTwoHands", "the held salvo pays now")
			if p["k"] == "twoSalvos":
				for u in alive("player"):
					if not jt(u.get("isSq")): u["treeTorpCarry"] = z0(p.get("pow"))
				treeFx(_treeFlag(), "twoSalvos", "the next salvo keeps its bonus")
			if p["k"] == "wingReserve":
				var u3 = null
				for x in B["units"]:
					if x["id"] == p.get("carrier"): u3 = x; break
				if u3 != null and not jt(u3.get("dead")) and not jt(u3.get("isSq")):
					var hs = launchHexes(u3)
					if hs.size() > 0:
						var sq = makeWing(u3, hs[0], wingKind(u3)); sq["extra"] = 1
						treeFx(u3, "wingReserve", "the held wing launches")
			if p["k"] == "swarmScrap":
				var sSc = treeSkill("swarmScrap"); var anySc = false
				for idSc in (p.get("ids") if p.get("ids") != null else []):
					var uSc2 = null
					for x in B["units"]:
						if x["id"] == idSc: uSc2 = x; break
					if uSc2 == null or jt(uSc2.get("dead")) or jt(uSc2.get("isSq")): continue
					var hsSc = launchHexes(uSc2)
					if hsSc.size() == 0: continue
					var fsSc = alive("enemy"); JSM.ssort(hsSc, func(a, b2): return _mind(a, fsSc) - _mind(b2, fsSc))
					var sqSc = makeWing(uSc2, hsSc[0], wingKind(uSc2)); sqSc["extra"] = 1; anySc = true
				if anySc and sSc != null: treeFx(treeFlagUnit(), "swarmScrap", "the swarm launches twice")   # Mott capstone 1: the second launch after the player turn
			if p["k"] == "fleshKnit":
				var fs2 = treeSkill("fleshKnit")
				for id in (p.get("ids") if p.get("ids") != null else []):
					var u4 = null
					for x in B["units"]:
						if x["id"] == id: u4 = x; break
					if u4 != null and not jt(u4.get("dead")) and not jt(u4.get("isSq")):
						u4["treeDmgNext"] = treeAddVal(u4, "dmgPct", fs2["n"]); treeFx(u4, "fleshKnit", "the new flesh is angry")
			if p["k"] == "tideEnd":
				var rp2 = z0(p.get("pow")) * 0.5; var anyT = false
				for u in alive("player"):
					if jt(u.get("isSq")): continue
					var h2 = min(u["maxHp"] - u["hp"], JSM.jsround(u["maxHp"] * rp2))
					if h2 > 0: u["hp"] = u["hp"] + h2; anyT = true
					if jt(u.get("sec")):
						for k in u["sec"].keys(): repairSection(u, k, rp2)
				if anyT: treeFx(_treeFlag(), "tideEnd", "the tide comes a second time")
			if p["k"] == "burnStays":
				var bs2 = treeSkill("burnStays"); var anyB = false
				for id in (p.get("map") if p.get("map") != null else {}).keys():
					var tb2 = null
					for x in B["units"]:
						if x["id"] == id: tb2 = x; break
					if tb2 == null or jt(tb2.get("dead")): continue
					var dd = JSM.jsround(float(p["map"][id]) * float(bs2["n"]))
					if dd <= 0: continue
					anyB = true; tb2["hp"] = max(1, tb2["hp"] - dd); flt(tb2, "Acid −" + ns(dd), "#c8e04a", -16)
					logm(String(tb2["name"]) + " takes " + ns(dd) + " acid damage from the last volley.", pe(tb2))
				if anyB: treeFx(_treeFlag(), "burnStays", "the burn stays")
			if p["k"] == "manyMouths":
				for id in (p.get("ids") if p.get("ids") != null else []):
					var u5 = null
					for x in B["units"]:
						if x["id"] == id: u5 = x; break
					if u5 != null and not jt(u5.get("dead")) and not jt(u5.get("isSq")):
						u5["treeAcidAim"] = 1; treeFx(u5, "manyMouths", "acid eats at the scanners")
			if p["k"] == "spatRounds":
				B["treeSpatRound"] = B["round"]; B["treeSpatIds"] = p.get("ids") if p.get("ids") != null else []   # Voice T2b: the held spit fires after this round start (treeRoundFx)
			if p["k"] == "growthWound":
				var sGW = treeSkill("growthWound"); var anyGW = false
				for eGW in (p.get("list") if p.get("list") != null else []):
					var uGW = null
					for x in B["units"]:
						if x["id"] == eGW.get("id"): uGW = x; break
					if uGW == null or jt(uGW.get("dead")) or not jt(uGW.get("sec")) or uGW["sec"].get(eGW.get("sec")) == null: continue
					var secGW = uGW["sec"][eGW.get("sec")]
					if jt(secGW.get("broken")): continue
					repairSection(uGW, eGW.get("sec"), float(eGW.get("amt"))); anyGW = true
				if anyGW and sGW != null: treeFx(_treeFlag(), "growthWound", "the wound holds its growth")   # Mending T2b: the section heals again
			if p["k"] == "noonRepeat":
				B["treeNoonRound"] = B["round"]   # Umbra capstone 1: the volley repeats after this round start (treeRoundFx)
			if p["k"] == "debtDue":
				B["treeDebtRound"] = B["round"]; B["treeDebtPow"] = z0(p.get("pow"))   # Vex T3b: the delayed volley fires now
			if p["k"] == "forgeAhead":
				B["treeForgeRound"] = B["round"]; B["treeForgeList"] = p.get("list") if p.get("list") != null else []   # Tamsa capstone 2: the forge strikes now
			if p["k"] == "layersShift":
				var fgL = treeFlagUnit()
				if fgL != null:
					for uL in caps("player"):
						if is_same(uL, fgL): continue
						if treeStepToward(uL, fgL, 1) > 0: treeFx(uL, "layersShift", "the layer shifts")
			if p["k"] == "burnCarry":
				for uB in alive("player"):
					if not jt(uB.get("isSq")): uB["burnCarry"] = {"mp": z0(p.get("pow")), "turns": z0(p.get("turns"))}
				treeFx(treeFlagUnit(), "burnCarry", "the burn carries into the new round")
			if p["k"] == "secondWave":
				var anySw = false; var patrol = treeSkill("standingGroup") != null; var marked = {}
				var launchOrd = treeSkill("launchOrder"); var oneTgt = treeSkill("oneTarget"); var fullG2 = treeSkill("fullGroup")
				var filedTSw = treeChoice("enemy") if (oneTgt != null or fullG2 != null) else null
				var firstWSw = false
				for e in (p.get("ships") if p.get("ships") != null else []):
					var ue = null
					for x in B["units"]:
						if x["id"] == e.get("id"): ue = x; break
					if ue == null or jt(ue.get("dead")) or jt(ue.get("isSq")): continue
					for k in range(int(e.get("count") if e.get("count") != null else 0)):
						var hsW = launchHexes(ue)
						if hsW.size() == 0: break
						var fsW = alive("enemy"); JSM.ssort(hsW, func(a, b2): return _mind(a, fsW) - _mind(b2, fsW))
						var sqW = makeWing(ue, hsW[0], wingKind(ue)); sqW["extra"] = 1; sqW["treeStrikeNow"] = 1; anySw = true
						if (oneTgt != null or fullG2 != null) and filedTSw != null:
							sqW["wingOrder"] = {"kind": "strike", "id": filedTSw["id"]}
							if oneTgt != null: B["tr"]["wingFiled"] = {"r": B["round"], "id": filedTSw["id"]}
						if launchOrd != null and not firstWSw:
							firstWSw = true; sqW["treeBonus"] = z0(sqW.get("treeBonus")) + float(launchOrd["n"]); treeFx(sqW, "launchOrder", "the first held wing strikes first")
						if patrol and not marked.has(ue["id"]): sqW["treePatrol"] = 1; marked[ue["id"]] = 1
				if anySw: B["treeStrikeRound"] = B["round"]; treeFx(treeFlagUnit(), "secondWave", "the held wings strike at the new round")
		B["treePending"] = keep
	var bigE = null
	var foesBig = alive("enemy").filter(func(x): return not jt(x.get("isSq")))
	JSM.ssort(foesBig, func(a, b):
		var d = b["maxHp"] - a["maxHp"]
		if d != 0: return d
		return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
	if foesBig.size() > 0: bigE = foesBig[0]
	if treeSkill("runBigger") != null:
		B["tr"]["bigId"] = bigE["id"] if bigE != null else null
		for uB2 in alive("player"):
			if not jt(uB2.get("isSq")): uB2["treeBigStart"] = hdist(uB2, bigE) if bigE != null else 0   # Grax T1a: the largest enemy at the start of the burn
	var sc2 = treeSkill("stillnessCounted")
	if sc2 != null and B.get("cmd") != null and B["cmd"]["id"] == "iron" and B["cmd"]["round"] == B["round"] - 1:
		for uS in caps("player"):
			if z0(uS.get("hexMoved")) == 0:
				uS["treeAimNext"] = treeAddVal(uS, "aim", sc2["n"]); treeFx(uS, "stillnessCounted", "the stillness counts")   # Seveth T3b
	var os2 = treeSkill("outShadow")
	if os2 != null and B.get("cmd") != null and B["cmd"]["id"] == "hunt" and B["cmd"]["round"] == B["round"] - 1:
		var pow2 = cmdPow("hunt", B["cmd"]["tier"])
		for uO in caps("player"):
			if treeInEnemyRear(uO) or not jt(B["tr"]["targetedLast"].get(uO["id"])):
				uO["treeHuntCarry"] = pow2; treeFx(uO, "outShadow", "the shadow holds a second round")   # Ostrel capstone 1
	var foes = []
	for x in alive("enemy"):
		if not jt(x.get("isSq")): foes.append(x)
	for u in alive("player"):
		if not jt(u.get("isSq")):
			u["treeStartFacing"] = u["facing"]; u["treeDeep"] = 0; u["treeAngleUsed"] = 0; u["treeMirrorUsed"] = 0; u["treePreyRear"] = null
			if treeSkill("debtHunts") != null and foes.size() > 0:
				var near = null; var nd = 1e9
				for f in foes:
					var dd = hdist(u, f)
					if dd < nd: nd = dd; near = f
				if near != null:
					var closest = true
					for v in alive("player"):
						if v != u and not jt(v.get("isSq")) and hdist(v, near) < nd: closest = false; break
					if closest: u["treePreyRear"] = near["id"]
	var ls = treeSkill("flagshipLens")
	if ls != null:
		var t = treeChoice("enemy"); B["treeLens"] = ({"r": B["round"], "id": t["id"]} if t != null else null)
		if t != null:
			var fg = null
			for x in B["units"]:
				if jt(x.get("pflag")) and not jt(x.get("dead")): fg = x; break
			treeFx(fg if fg != null else t, "flagshipLens", "the lens marks " + str(t["name"]))
	var bc = treeSkill("beacon")
	if bc != null:
		var tb = treeChoice("enemy"); B["tr"]["beacon"] = ({"r": B["round"], "id": tb["id"]} if tb != null else null)
		if tb != null: treeFx(treeFlagUnit() if treeFlagUnit() != null else tb, "beacon", "the flagship stamps " + str(tb["name"]))
	if treeSkill("sharedSolution") != null:
		var synSS = []
		for xSS in alive("player"):
			if not jt(xSS.get("isSq")) and not jt(xSS.get("dead")) and inSync(xSS): synSS.append(xSS)
		if synSS.size() > 1:
			JSM.ssort(synSS, func(a, b):
				var d = float(a["aim"]) - float(b["aim"])
				if d != 0: return d
				return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
			treeFx(synSS[0], "sharedSolution", "the best solution is shared")   # Kassar T2a
	if treeSkill("coldDrill") != null:
		for xCD in alive("player"):
			if not jt(xCD.get("isSq")) and not jt(xCD.get("dead")) and inSync(xCD): treeFx(xCD, "coldDrill", "the drill runs cold"); break   # Kassar T2b
	if treeSkill("throatRed") != null and jt(B.get("cmd")) and B["cmd"]["id"] == "surge" and B["cmd"]["round"] == B["round"] - 1:
		for u in alive("player"):
			if jt(u.get("isSq")): continue
			var near2 = jt(u.get("treeRedNext"))
			if not near2:
				for x in alive("enemy"):
					if not jt(x.get("isSq")) and hdist(u, x) == 1: near2 = true; break
			if near2: u["treeRedFirst"] = 1; treeFx(u, "throatRed", "the throat turns red")
	for u in alive("player"):
		if not jt(u.get("isSq")): u["treeRedNext"] = 0
	var rh = treeSkill("refuseHoles")
	if rh != null:
		var hurt = []
		for x in alive("player"):
			if not jt(x.get("isSq")) and x["hp"] < x["maxHp"] / 2.0: hurt.append(x)
		if hurt.size() > 0:
			JSM.ssort(hurt, func(a, b):
				var d = (a["hp"] / a["maxHp"]) - (b["hp"] / b["maxHp"])
				if d != 0: return d
				return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
			var u6 = hurt[0]
			var want = min(JSM.jsround(u6["maxHp"] * float(rh["n"])), max(0, int(ceil(u6["maxHp"] / 2.0)) - int(u6["hp"])))
			if want > 0: u6["hp"] = min(u6["maxHp"], u6["hp"] + want); treeFx(u6, "refuseHoles", "the throat refuses holes")
func treeDeployMove(kind, txt) -> void:
	if B == null or B.get("tree") == null or B["tree"].size() == 0: return
	if treeSkill(kind) == null: return
	var who = treeChoice("ship")
	if who == null: return
	var bb = boardBounds(); var occ = occMap(); var best = null; var bd = 1e9
	for h in boardHexes():
		var c = float(h["q"]) + floor(float(h["r"]) / 2.0)
		if c > bb["c0"] + 2: continue
		if blocks(terr(h["q"], h["r"])) or occ.has(hkey(h["q"], h["r"])): continue
		var d = hdist(h, who)
		if d > 0 and d < bd: bd = d; best = h
	if best != null:
		who["q"] = best["q"]; who["r"] = best["r"]; treeFx(who, kind, txt)
func treeBattleStart() -> void:
	if B == null or B.get("tree") == null or B["tree"].size() == 0: return
	treeDeployMove("deployRead", "redeployed from the shards")
	treeDeployMove("swornDeploy", "sworn into place")
	if treeSkill("castCorrected") != null:
		var l = []
		for x in alive("player"):
			if not jt(x.get("isSq")): l.append(x)
		if l.size() >= 2:
			var a = l[0]; var b2 = l[1]; var q = a["q"]; var r = a["r"]
			a["q"] = b2["q"]; a["r"] = b2["r"]; b2["q"] = q; b2["r"] = r; treeFx(a, "castCorrected", "the cast is corrected")
	if treeSkill("iterationSwap") != null:
		var lS = []
		for x in alive("player"):
			if not jt(x.get("isSq")): lS.append(x)
		if lS.size() >= 2:
			var aS = lS[0]; var bS = lS[1]; var qS = aS["q"]; var rS = aS["r"]
			aS["q"] = bS["q"]; aS["r"] = bS["r"]; bS["q"] = qS; bS["r"] = rS; treeFx(aS, "iterationSwap", "the copy is swapped")
	if treeSkill("debtsReserve") != null:
		var who = treeChoice("reserve")
		if who != null:
			who["treeOff"] = 1; who["treeReserve"] = 1
			if B.get("treeReserve") == null: B["treeReserve"] = []
			B["treeReserve"].append(who["id"]); treeFx(who, "debtsReserve", "held in reserve")
	if treeSkill("broodReserve") != null:
		var who2 = treeChoice("brood")
		if who2 != null:
			who2["treeOff"] = 1; who2["treeReserve"] = 1
			if B.get("treeReserve") == null: B["treeReserve"] = []
			B["treeReserve"].append(who2["id"]); treeFx(who2, "broodReserve", "the brood is held back")
	if treeSkill("preyScent") != null:
		var ePS = treeChoice("enemy"); B["tr"]["scent"] = ePS["id"] if ePS != null else null
		if ePS != null: treeFx(treeFlagUnit() if treeFlagUnit() != null else ePS, "preyScent", "the pack names its prey")   # Hullbreakers shared B1a
func treeAfterMove(u) -> void:
	if B == null or B.get("tree") == null or B["tree"].size() == 0 or u == null or jt(u.get("isSq")): return
	if treeSkill("mirrorTurns") != null and cmdActive(u["side"], "surge") and not jt(u.get("treeMirrorUsed")):
		var f = treeBestFacing(u); u["treeMirrorUsed"] = 1
		if f != null and f != int(u["facing"]): u["facing"] = f
		treeFx(u, "mirrorTurns", "the mirror turns")
	if treeSkill("anglesRecorded") != null and cmdActive(u["side"], "surge") and not jt(u.get("treeAngleUsed")) and u.get("treeStartFacing") != null and u["facing"] != u["treeStartFacing"]:
		u["treeAngleUsed"] = 1; u["evBuff"] = min(float(TB.FX_CAPS.ev), z0(u.get("evBuff")) + float(treeSkill("anglesRecorded")["n"])); treeFx(u, "anglesRecorded", "a false angle holds")
	var lrM = treeSkill("lensRotates")
	if lrM != null and u["side"] == "player" and cmdActive(u["side"], "iron") and not jt(u.get("treeLensRot")) and u.get("treeWardFacing") != null and u["facing"] != u["treeWardFacing"]:
		u["treeLensRot"] = 1; u["evBuff"] = min(float(TB.FX_CAPS.ev), z0(u.get("evBuff")) + float(lrM["n"])); treeFx(u, "lensRotates", "the lens turns")   # Brin T2b
	if treeSkill("refraction") != null and cmdActive(u["side"], "surge") and u["mp"] <= 0:
		u["treeDeep"] = 1; treeFx(u, "refraction", "the reflection cannot be found beyond range 6")
	var saM = treeSkill("silentArchive")
	if saM != null and u["side"] == "player" and cmdActive(u["side"], "hunt") and not jt(u.get("treeSilentMark")):
		for tS in alive("enemy"):
			if not jt(tS.get("isSq")) and not inArc(tS, u, "F"): u["treeSilentMark"] = 1; treeFx(u, "silentArchive", "the archive hides the ship"); break
	if treeSkill("throatRed") != null and cmdActive(u["side"], "surge"):
		var adjT = false
		for x in alive("enemy"):
			if not jt(x.get("isSq")) and hdist(u, x) == 1: adjT = true; break
		if adjT: u["treeRedNext"] = 1   # Razormaw capstone 1
	if treeSkill("loosePack") != null and u["side"] == "player" and z0(u.get("hexMoved")) > 0 and not _friendlyNear2(u, u["q"], u["r"]):
		treeFx(u, "loosePack", "the pack runs wide")   # Hullbreakers shared B1b
	if u["side"] == "player":
		if treeSkill("formation") != null:
			var nearF = 0
			for xF in alive("player"):
				if not is_same(xF, u) and not jt(xF.get("isSq")) and hdist(xF, u) == 1: nearF += 1
			if nearF >= 2: u["treeFormation"] = 1; treeFx(u, "formation", "the formation is filed")
		var efE = treeSkill("eclFormation")
		if efE != null and not jt(u.get("treeEclForm")):
			var nearE = 0
			for xE in alive("player"):
				if not is_same(xE, u) and not jt(xE.get("isSq")) and hdist(xE, u) == 1: nearE += 1
			if nearE >= 2: u["treeEclForm"] = 1; u["evBuff"] = min(float(TB.FX_CAPS.get("ev", 45)), z0(u.get("evBuff")) + float(efE["n"])); treeFx(u, "eclFormation", "the formation holds")   # Eclipse shared B1a
		var spE = treeSkill("shadowPos")
		if spE != null and cmdActive(u["side"], "hunt") and not jt(u.get("treeShadowPos")) and treeInEnemyRear(u): u["treeShadowPos"] = 1; treeFx(u, "shadowPos", "the shadow is a position")   # Ostrel T2a
		if cmdActive(u["side"], "iron"):
			var cs = treeSkill("columnStraight")
			if cs != null and treeInColumn(u):
				if treeShieldOver(u, cs["n"]) > 0: treeFx(u, "columnStraight", "the column adds shield")
			var fs = treeSkill("flagshipStandard")
			if fs != null and treeInFlagLine(u):
				if treeShieldOver(u, fs["n"]) > 0: treeFx(u, "flagshipStandard", "the flagship holds the line")
			var ov = treeSkill("overflow")
			if ov != null and z0(u.get("shMax")) > 0 and not jt(u.get("treeOverflowUsed")):
				var allFull = true
				for i in range(4):
					if z0(u["sh"][i]) < z0(u["shMax"]): allFull = false; break
				if allFull: u["treeOverflowUsed"] = 1; u["evBuff"] = min(45, z0(u.get("evBuff")) + int(ov["n"])); treeFx(u, "overflow", "the surplus becomes evasion")
			if treeSkill("rotation") != null: treeRotSwap(u)
	if u["side"] == "enemy" and treeSkill("drillRevision") != null and not jt(B.get("treeDrillUsed")):
		B["treeDrillUsed"] = 1; treeDrillMove()
func treeDeepBlocks(u, t) -> bool:
	var s = treeSkill("refraction")
	return s != null and t != null and jt(t.get("treeDeep")) and not jt(u.get("isSq")) and hdist(u, t) > float(s["n"])
func treeIsRear(u, t, quad) -> bool:   # Malek T3a: side hits on the hunted target count as rear hits
	if quad == 2: return true
	var s = treeSkill("debtHunts")
	return s != null and u != null and t != null and u["side"] == "player" and u.get("treePreyRear") == t.get("id") and (quad == 1 or quad == 3)
func treeExtraShot(u, wi, t, opts) -> bool:   # H4: one weapon fired again, then the gun is put back
	if B == null or u == null or t == null or jt(u.get("dead")) or jt(t.get("dead")): return false
	var w = u["weapons"][wi] if wi >= 0 and wi < u["weapons"].size() else null
	if w == null: return false
	var keep = [w.get("fired"), w.get("cdLeft")]; w["fired"] = false; w["cdLeft"] = 0; var ok = false
	if canFire(u, w, t) or (opts != null and jt(opts.get("forceArc")) and treeArcLegal(u, w, t)) or (opts != null and jt(opts.get("forceRange")) and treeRangeLegal(u, w, t)): ok = fireWeapon(u, wi, t, opts if opts != null else {})
	w["fired"] = keep[0]; w["cdLeft"] = keep[1]
	return ok
func treeSpit(u) -> bool:   # Voice T1b: a ship whose guns cannot bear spits once at the nearest enemy in range, ignoring arc
	var s = treeSkill("throatSpits")
	if s == null or B == null or u == null or jt(u.get("dead")) or jt(u.get("isSq")) or u["side"] != "player": return false
	var foes = []
	for t in alive("enemy"):
		if not jt(t.get("dead")) and not jt(t.get("isSq")): foes.append(t)
	if foes.size() == 0: return false
	var tt = null; var td = 1e9
	for f in foes:
		var d = hdist(u, f)
		if d < td: td = d; tt = f
	var wi = -1; var bv = -1.0
	for i in range(u["weapons"].size()):
		var w = u["weapons"][i]
		if w["k"] == "flak": continue
		if td > w["r"]: continue
		var v = w["dmg"] * w["shots"]
		if v > bv: bv = v; wi = i
	if wi < 0: return false
	var w2 = u["weapons"][wi]; var wf = w2.get("fired"); var wc = w2.get("cdLeft"); var wo = w2.get("off")
	var pf = [u.get("postFire"), u.get("postMp")]; var old = u["facing"]
	u["facing"] = treeFacingTo(u, tt); w2["fired"] = false; w2["cdLeft"] = 0; w2["off"] = 0
	var ok = false
	if canFire(u, w2, tt): ok = fireWeapon(u, wi, tt, {"half": true})
	w2["fired"] = wf; w2["cdLeft"] = wc; w2["off"] = wo; u["facing"] = old; u["postFire"] = pf[0]; u["postMp"] = pf[1]
	if ok: treeFx(u, "throatSpits", "a throat spits without a bearing")
	return ok
func treeWallAnswer(t, att) -> bool:
	if t == null or att == null or jt(t.get("dead")) or jt(att.get("dead")): return false
	var wi = -1; var bv = INF; var i = 0
	for w in t["weapons"]:
		if not jt(w.get("off")) and w["k"] != "flak":
			var v = w["dmg"] * w["shots"]
			if v < bv: bv = v; wi = i
		i += 1
	if wi < 0: return false
	var ok = treeExtraShot(t, wi, att, {})
	if ok: treeFx(t, "wallAnswers", "the wall answers")
	return ok
func treeFreeVolleyShip(u, foe, half = false) -> void:   # H4: Vex's held volley, one ship's free barrage
	var b0 = B
	var keep = []
	for w in u["weapons"]: keep.append([w.get("fired"), w.get("cdLeft")])
	var pf = [u.get("postFire"), u.get("postMp")]
	for w in u["weapons"]: w["fired"] = false; w["cdLeft"] = 0
	for i in range(u["weapons"].size()):
		if not is_same(B, b0) or jt(B.get("over")) or jt(u.get("dead")): break
		var w = u["weapons"][i]; var ts = []
		for t in alive(foe):
			if canFire(u, w, t): ts.append(t)
		if ts.size() == 0: continue
		var val = func(t):
			var e = expectedVs(u, w, t); return e["hull"] + e["shield"] * 0.3 + (25.0 if e["hull"] >= t["hp"] else 0.0)
		JSM.ssort(ts, func(a, b2): return val.call(b2) - val.call(a))
		fireWeapon(u, i, ts[0], {"half": true} if half else {})
	for i in range(u["weapons"].size()):
		u["weapons"][i]["fired"] = keep[i][0]; u["weapons"][i]["cdLeft"] = keep[i][1]
	u["postFire"] = pf[0]; u["postMp"] = pf[1]
func treeHeldFire(u) -> void:
	if B == null or B.get("tree") == null or B["tree"].size() == 0 or u == null or jt(u.get("isSq")) or not jt(u.get("treeHeld")): return
	u["treeHeld"] = 0
	if jt(B.get("over")) or jt(u.get("dead")) or not cmdActive("player", "barrage"): return
	var b0 = B; var tierArg = B["cmd"]["tier"] if B.get("cmd") != null else null
	B["volleyMul"] = {"side": "player", "m": 1.0 + cmdPow("barrage", tierArg)}
	treeFreeVolleyShip(u, "enemy")
	if is_same(B, b0): B["volleyMul"] = null
	treeFx(u, "heldAccount", "the held volley fires after the move")
func treeEscortWing(t) -> Variant:   # H16: an escort wing takes the first gunfire aimed at its named friend
	var s = treeSkill("escortName")
	if s == null or B == null or B.get("tr") == null or t == null: return null
	if B["tr"].get("escortUsed") == null: B["tr"]["escortUsed"] = {}
	var used = B["tr"]["escortUsed"]
	for sq in alive("player"):
		if not jt(sq.get("isSq")) or sq.get("escort") != t.get("id"): continue
		if jt(used.get(sq["id"])): continue
		used[sq["id"]] = 1; return sq
	return null
func treeRecordedAngle(side) -> void:
	if treeSkill("recordedAngle") == null or side != "player" or not cmdActive(side, "barrage"): return
	for u in alive(side):
		if jt(u.get("isSq")): continue
		if not (u["turnsLeft"] >= u["turns"]): continue
		var f = treeBestFacing(u)
		if f == null or f == int(u["facing"]): continue
		u["facing"] = f; treeFx(u, "recordedAngle", "the lens turns before the volley")
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
	var cut = 0.0
	if cmdActive(t["side"], "iron"): cut = cmdPow("iron", null, t["side"])
	elif t["side"] == "player" and B != null and B.get("treeIronExtra") != null and B["treeIronExtra"]["r"] == B["round"]: cut = z0(B["treeIronExtra"].get("pow"))
	elif t["side"] == "player": cut = z0(t.get("ironCarry"))
	var wc = t.get("treeWallCarry")
	if wc != null and wc["r"] == B["round"] and t["side"] == "player": cut = max(cut, float(wc["pow"]))   # Seveth capstone 2
	var ps = treeSkill("platesShadow")
	if ps != null and t["side"] == "player" and cmdActive("player", "iron") and B.get("treePlate") != null and B["treePlate"]["r"] == B["round"]:
		cut = 0.75 if t["id"] == B["treePlate"]["id"] else 0.25   # Seveth T1a
	var tr = treeSkill("twiceRestored")
	if tr != null and t["side"] == "player" and cmdActive("player", "iron") and jt(t.get("treeRepaired")): cut = min(0.95, cut + float(tr["n"]))   # Seveth T1b
	var up = treeSkill("unpaid")
	if up != null and cut > 0 and t["side"] == "player" and t["hp"] < t["maxHp"] / 2.0: cut = min(0.95, cut + float(up["n"]))   # Thale T3a
	var scC = treeSkill("standardCovers")
	if scC != null and t["side"] == "player" and cmdActive("player", "iron"): cut = min(0.95, cut + float(scC["n"]))   # Maren capstone 1
	var wsC = treeSkill("weakSide")
	if wsC != null and t["side"] == "player" and cmdActive("player", "iron") and B != null and B.get("treeWeakShip") != null and B["treeWeakShip"]["r"] == B["round"] and t["id"] == B["treeWeakShip"]["id"]: cut = min(0.95, cut + float(wsC["n"]))   # Brin T1a
	var shC = treeSkill("screensShift")
	if shC != null and t["side"] == "player" and cmdActive("player", "iron") and B != null:
		if B.get("treeShiftUp") != null and B["treeShiftUp"]["r"] == B["round"] and t["id"] == B["treeShiftUp"]["id"]: cut = min(0.95, cut + float(shC["n"]))
		if B.get("treeShiftDown") != null and B["treeShiftDown"]["r"] == B["round"] and t["id"] == B["treeShiftDown"]["id"]: cut = max(0.0, cut - float(shC["n"]))   # Thale T1b
	var weC = treeSkill("wallEarly")
	if weC != null and t["side"] == "player" and cmdActive("player", "iron") and B != null and z0(B.get("treeWallEarly")) == B["round"]: cut = min(0.95, cut + float(weC["n"]))   # Thale T2a
	return 1.0 - cut - (0.0 if jt(t.get("shMax")) else 0.1) if cut > 0 else 1.0
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
		var ddB = treeSkill("debtDue")
		if ddB != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "debtDue", "r": B["round"], "pow": cmdPow("barrage", tier)}); treeFx(treeFlagUnit(), "debtDue", "the account waits a round")
			if is_same(B, bStart): checkEnd()
			return true   # Vex T3b: the volley is delayed
		treeRecordedAngle(side)
		var b0 = B; var live = liveFrom(null); B["volleyMul"] = {"side": side, "m": 1.0 + cmdPow("barrage", tier)}
		B["treeNoon"] = treeSkill("noonChoice") != null and side == "player" and not alive("player").any(func(x): return not jt(x.get("isSq")) and (z0(x.get("hexMoved")) > 0 or jt(x.get("treeRoundFired"))))
		var cf = treeSkill("copyFires"); var osc = treeSkill("oneSunCopied")
		var held = treeChoice("ship") if (side == "player" and treeSkill("heldAccount") != null) else null; var heldOnce = false
		var named = treeChoice("enemy") if (side == "player" and treeSkill("namedLedger") != null) else null
		if named != null: treeFx(named, "namedLedger", "the volley is aimed by name")
		var eg = treeSkill("everyGun") if side == "player" else null
		var acid = treeSkill("acidBeforeAim") if side == "player" else null
		var spits = treeSkill("throatSpits") if side == "player" else null
		var grows = treeSkill("volleyGrows") if side == "player" else null
		var mouth = treeSkill("mouthDeep") if side == "player" else null
		var mouthShip = treeChoice("ship") if mouth != null else null
		var olS = treeChoice("ship") if (side == "player" and treeSkill("oneLens") != null) else null
		var olT = treeChoice("enemy") if (olS != null and treeSkill("oneLens") != null) else null
		if olS != null and olT != null: B["tr"]["oneLens"] = {"ship": olS["id"], "tgt": olT["id"]}; treeFx(olS, "oneLens", "one lens, one target")   # Saro T1b
		var sunS = treeSkill("sunLens") if side == "player" else null
		var sunT = treeChoice("enemy") if sunS != null else null
		if sunS != null and sunT != null: B["tr"]["sunTarget"] = sunT["id"]; B["tr"]["sunFirstDone"] = 0; treeFx(sunT, "sunLens", "the sun goes through one lens")   # Saro capstone 1
		var grandS = treeSkill("grandLedger") if (side == "player" and treeSkill("grandLedger") != null and not jt(B["tr"].get("grandUsed"))) else null
		var grandT = treeChoice("enemy") if grandS != null else null
		if grandS != null and grandT != null: B["tr"]["grandUsed"] = 1; B["tr"]["grandTarget"] = grandT["id"]; B["tr"]["grandFirstDone"] = 0; treeFx(grandT, "grandLedger", "the grand ledger opens")   # Vex capstone 1
		var lastA = treeSkill("lastAccount") if side == "player" else null
		var srS = treeSkill("spatRounds") if side == "player" else null
		var spatSet = {}
		if srS != null:
			var cc = []; var allN = 0
			for xS in alive("player"):
				if jt(xS.get("isSq")) or jt(xS.get("dead")): continue
				allN += 1
				var canS = false   # only ships with nothing to fire at now hold their spit; the default never holds a ship that could fire
				for tS in alive(foe):
					if jt(tS.get("isSq")): continue
					for wS in xS["weapons"]:
						if canFire(xS, wS, tS): canS = true; break
					if canS: break
				if not canS: cc.append(xS)
			JSM.ssort(cc, func(a, b2):
				var da = 0.0
				for wA in a["weapons"]:
					if wA["k"] != "flak": da += float(wA["dmg"]) * float(wA["shots"])
				var db = 0.0
				for wB in b2["weapons"]:
					if wB["k"] != "flak": db += float(wB["dmg"]) * float(wB["shots"])
				var dd = db - da
				if dd != 0: return dd
				return -1.0 if str(a["id"]) < str(b2["id"]) else 1.0)
			var take = int(floor(float(allN) / 2.0))
			for iS in range(min(take, cc.size())): spatSet[cc[iS]["id"]] = 1
		var ta = treeSkill("targetArchived") if side == "player" else null
		var taPick = {}
		var taCount = {}
		if ta != null:
			for uT in alive("player"):
				if jt(uT.get("isSq")) or jt(uT.get("dead")): continue
				var ownT = null; var ovT = -INF
				for tT in alive(foe):
					if jt(tT.get("isSq")): continue
					for wT in uT["weapons"]:
						if canFire(uT, wT, tT):
							var eT = expectedVs(uT, wT, tT); var vT = eT["hull"] + eT["shield"] * 0.3
							if vT > ovT: ovT = vT; ownT = tT
				if ownT != null:
					taPick[uT["id"]] = ownT["id"]; taCount[ownT["id"]] = z0(taCount.get(ownT["id"])) + 1   # Umbra T2b: every ship picks its own target before the volley
		for u in caps(side):
			if jt(B.get("over")) or not live.call(): break
			var firedAny = false
			if spatSet.has(u["id"]): continue
			if held != null and not heldOnce and u["id"] == held["id"] and z0(u.get("hexMoved")) == 0:
				u["treeHeld"] = 1; heldOnce = true; treeFx(u, "heldAccount", "the volley is held for the move"); continue
			var ll = treeSkill("longLight"); var bumped = 0.0
			if ll != null and side == "player" and u["turnsLeft"] >= u["turns"]:
				bumped = treeAddVal(u, "lanceRange", ll["n"])
				if bumped > 0:
					for w in u["weapons"]:
						if w["k"] == "lance": w["r"] = w["r"] + bumped; w["opt"] = w["opt"] + bumped
					treeFx(u, "longLight", "lances reach further")
			var own = null
			if eg != null:
				var ov = -INF
				for t in alive(foe):
					if jt(t.get("isSq")): continue
					for w in u["weapons"]:
						if canFire(u, w, t):
							var eo = expectedVs(u, w, t); var vo = eo["hull"] + eo["shield"] * 0.3
							if vo > ov: ov = vo; own = t
				if own != null:
					var npick = z0(B["tr"]["volleyPick"].get(own["id"]))
					if npick > 0: u["treeAimPlus"] = treeAddVal(u, "aim", eg["n"]); treeFx(u, "everyGun", "a shared solution")
					B["tr"]["volleyPick"][own["id"]] = npick + 1
			if ta != null and taPick.get(u["id"]) != null:
				var tidT = taPick[u["id"]]
				if z0(taCount.get(tidT)) == 1: u["treeAimTgt"] = tidT; treeFx(u, "targetArchived", "the archived target is unshared")   # Umbra T2b
			var keep = []
			for w in u["weapons"]: keep.append([w.get("fired"), w.get("cdLeft")])   # B-20 refits lack both; restored as undefined
			var pf = [u.get("postFire"), u.get("postMp")]
			for w in u["weapons"]:
				w["fired"] = false; w["cdLeft"] = 0
			var foesBefore = alive(foe).size()
			u["treeVolleyHit"] = 0
			for i in range(u["weapons"].size()):
				if jt(B.get("over")) or not live.call() or jt(u.get("dead")): break
				var w = u["weapons"][i]; var ts = []
				for t in alive(foe):
					if canFire(u, w, t): ts.append(t)
				if ts.size() == 0: continue
				firedAny = true
				var val = func(t):
					var e = expectedVs(u, w, t); return e.hull + e.shield * 0.3 + (25.0 if e.hull >= t["hp"] else 0.0)
				JSM.ssort(ts, func(a, b2): return val.call(b2) - val.call(a))
				var pick = ts[0]
				if olS != null and u["id"] == olS["id"] and olT != null and canFire(u, w, olT): pick = olT
				elif sunT != null and canFire(u, w, sunT): pick = sunT
				elif grandT != null and canFire(u, w, grandT): pick = grandT
				elif named != null and canFire(u, w, named): pick = named
				elif acid != null:
					JSM.ssort(ts, func(a, b2):
						var dd = hdist(u, a) - hdist(u, b2)
						if dd != 0: return dd
						return -1.0 if str(a["id"]) < str(b2["id"]) else 1.0)
					pick = ts[0]; treeFx(u, "acidBeforeAim", "the nearest enemy is chosen")   # Voice T1a
				elif eg != null and own != null and canFire(u, w, own): pick = own
				fireWeapon(u, i, pick)
			u["treeAimPlus"] = 0
			if ta != null: u["treeAimTgt"] = null
			for i in range(u["weapons"].size()):
				u["weapons"][i]["fired"] = keep[i][0]; u["weapons"][i]["cdLeft"] = keep[i][1]
			if bumped > 0:
				for w in u["weapons"]:
					if w["k"] == "lance": w["r"] = w["r"] - bumped; w["opt"] = w["opt"] - bumped
			u["postFire"] = pf[0]; u["postMp"] = pf[1]
			if spits != null and not firedAny and not jt(u.get("dead")) and not jt(B.get("over")): treeSpit(u)   # Voice T1b
			if grows != null and jt(u.get("treeVolleyHit")) and not jt(u.get("dead")) and not jt(B.get("over")):
				var bw = -1; var bt2 = null; var bv = -1.0
				for i in range(u["weapons"].size()):
					var w2 = u["weapons"][i]
					if w2["k"] == "flak" or jt(w2.get("off")): continue
					for t2 in alive(foe):
						if not canFire(u, w2, t2): continue
						var e2 = expectedVs(u, w2, t2); var v2 = e2["hull"] + e2["shield"] * 0.3
						if v2 > bv: bv = v2; bw = i; bt2 = t2
				if bw >= 0 and bt2 != null and treeExtraShot(u, bw, bt2, {"half": true}): treeFx(u, "volleyGrows", "the first spit spits again")   # Voice capstone 1
			if mouth != null and mouthShip != null and u["id"] == mouthShip["id"] and not jt(u.get("dead")) and not jt(B.get("over")):
				var bt3 = null; var bv3 = -1.0
				for t3 in alive(foe):
					var v3 = 0.0
					for w3 in u["weapons"]:
						if w3["k"] == "flak" or jt(w3.get("off")): continue
						if canFire(u, w3, t3):
							var e3 = expectedVs(u, w3, t3); v3 += e3["hull"] + e3["shield"] * 0.3
					if v3 > bv3: bv3 = v3; bt3 = t3
				if bt3 != null:
					for rep in range(2):
						for i in range(u["weapons"].size()):
							if jt(bt3.get("dead")) or jt(B.get("over")) or jt(u.get("dead")): break
							if canFire(u, u["weapons"][i], bt3): treeExtraShot(u, i, bt3, {})
					treeFx(u, "mouthDeep", "the deep mouth spits every gun twice")   # Voice capstone 2
			if side == "player" and cf != null and not jt(u.get("dead")) and not jt(B.get("over")) and alive(foe).size() < foesBefore:
				var bt2 = null; var bv2 = -INF
				for t2 in alive(foe):
					if jt(t2.get("isSq")): continue
					for w2 in u["weapons"]:
						if not canFire(u, w2, t2): continue
						var e2 = expectedVs(u, w2, t2); var v2 = e2["hull"] + e2["shield"] * 0.3
						if v2 > bv2: bv2 = v2; bt2 = t2
				if bt2 != null:
					var wi3 = -1
					for i in range(u["weapons"].size()):
						if canFire(u, u["weapons"][i], bt2): wi3 = i; break
					if wi3 >= 0 and treeExtraShot(u, wi3, bt2, {}): treeFx(u, "copyFires", "the copy fires again")   # Umbra T2a
			if side == "player" and osc != null and not jt(u.get("dead")) and not jt(B.get("over")):
				var low = null; var lows = alive(foe).filter(func(x): return not jt(x.get("isSq")))
				JSM.ssort(lows, func(a, b3):
					var dd = a["hp"] - b3["hp"]
					if dd != 0: return dd
					return -1.0 if str(a["id"]) < str(b3["id"]) else 1.0)
				if lows.size() > 0: low = lows[0]
				if low != null:
					var any2 = false
					for i in range(u["weapons"].size()):
						if jt(B.get("over")) or jt(u.get("dead")): break
						if canFire(u, u["weapons"][i], low):
							if treeExtraShot(u, i, low, {"half": true}): any2 = true
					if any2: treeFx(u, "oneSunCopied", "the sun is copied")   # Umbra capstone 2
			if side == "player" and lastA != null and not jt(u.get("dead")) and not jt(B.get("over")) and alive(foe).size() < foesBefore:
				var btL = null; var bvL = -INF
				for t2L in alive(foe):
					if jt(t2L.get("isSq")): continue
					for w2L in u["weapons"]:
						if not canFire(u, w2L, t2L): continue
						var e2L = expectedVs(u, w2L, t2L); var v2L = e2L["hull"] + e2L["shield"] * 0.3
						if v2L > bvL: bvL = v2L; btL = t2L
				if btL != null:
					var wiL = -1
					for iL in range(u["weapons"].size()):
						if canFire(u, u["weapons"][iL], btL): wiL = iL; break
					if wiL >= 0 and treeExtraShot(u, wiL, btL, {}): treeFx(u, "lastAccount", "the last account is paid")   # Vex capstone 2
		if srS != null:
			var idsS = spatSet.keys()
			if idsS.size() > 0:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "spatRounds", "r": B["round"], "ids": idsS})
				treeFx(treeFlagUnit(), "spatRounds", "half the spits are held")   # Voice T2b
		var ovB = treeSkill("oneVoice")
		if ovB != null and side == "player" and not jt(B.get("treeOneVoiceUsed")):
			var eB = treeChoice("enemy")
			if eB != null:
				B["treeOneVoiceUsed"] = 1; B["tr"]["firstStopTarget"] = eB["id"]; B["tr"]["firstStopDone"] = 0
				for uB in alive("player"):
					if jt(B.get("over")) or jt(uB.get("dead")) or jt(uB.get("isSq")) or not inSync(uB): continue
					if jt(eB.get("dead")): break
					treeVolleyAt(uB, eB)
				B["tr"]["firstStopTarget"] = null; treeFx(treeFlagUnit(), "oneVoice", "every synced ship fires as one")
		if is_same(B, b0): B["volleyMul"] = null
		if treeSkill("flawForever") != null and side == "player" and B.get("tr") != null and B["tr"].get("volleyHits") != null:
			var best = null; var bn = 0.0
			for k in B["tr"]["volleyHits"].keys():
				var n = z0(B["tr"]["volleyHits"][k]); if n > bn: bn = n; best = k
			if best != null:
				B["treeFlaw"] = best; var bt = null; var bf2 = null
				for x in B["units"]:
					if x["id"] == best: bt = x
					if jt(x.get("pflag")) and not jt(x.get("dead")): bf2 = x
				treeFx(bt if bt != null else bf2, "flawForever", "the flaw is marked for the battle")
		var mm = treeSkill("manyMouths")
		if mm != null and side == "player" and B.get("tr") != null and B["tr"].get("volleyShips") != null:
			var ids = []
			for k in B["tr"]["volleyShips"].keys():
				if B["tr"]["volleyShips"][k].size() >= 4:
					ids.append(k); var tm = null
					for x in B["units"]:
						if x["id"] == k: tm = x; break
					if tm != null: treeFx(tm, "manyMouths", "four mouths find one throat")
			if ids.size() > 0:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "manyMouths", "r": B["round"], "ids": ids})
		var bs = treeSkill("burnStays")
		if bs != null and side == "player" and B.get("tr") != null and B["tr"].get("burnStays") != null:
			var anyB = false
			for k in B["tr"]["burnStays"].keys():
				if z0(B["tr"]["burnStays"][k]) > 0: anyB = true
			if anyB:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "burnStays", "r": B["round"], "map": B["tr"]["burnStays"].duplicate(true)})
				treeFx(_treeFlag(), "burnStays", "the burn will stay")
		if treeSkill("noonRepeat") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "noonRepeat", "r": B["round"]})
	if c["id"] == "hunt":
		if treeSkill("longCopy") != null and side == "player":
			for u in caps("player"):
				var gL = treeRearApproach(u)
				if gL != null and treeStepToward(u, gL, 2) > 0: treeFx(u, "longCopy", "the long copy strikes")   # Ostrel capstone 2
		for u in alive(side):
			for w in u["weapons"]:
				if w["k"] == "torp":
					w["cdLeft"] = 0; w["fired"] = false
		if treeSkill("preyName") != null and side == "player":
			var e = treeChoice("enemy"); B["treePrey"] = ({"id": e["id"], "r": B["round"]} if e != null else null)
			if e != null: treeFx(_treeFlag() if _treeFlag() != null else e, "preyName", "the prey is entered by name")
		if treeSkill("salvoTwoHands") != null and side == "player":
			var pl = []
			for x in alive("player"):
				if not jt(x.get("isSq")): pl.append(x)
			JSM.ssort(pl, func(a, b2):
				var d = (a["hp"] / max(1.0, a["maxHp"])) - (b2["hp"] / max(1.0, b2["maxHp"]))
				if d != 0: return d
				return -1.0 if str(a["id"]) < str(b2["id"]) else 1.0)
			var half = pl.slice(0, max(1, int(ceil(pl.size() / 2.0))))
			for u in half: u["treeHuntNext"] = 1
			if B.get("treePending") == null: B["treePending"] = []
			var ids = []
			for u in half: ids.append(u["id"])
			B["treePending"].append({"k": "salvoTwoHands", "r": B["round"], "pow": cmdPow("hunt", tier), "ids": ids})
			treeFx(_treeFlag() if _treeFlag() != null else (half[0] if half.size() > 0 else null), "salvoTwoHands", "half the salvo is held for next round")
		if treeSkill("twoSalvos") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "twoSalvos", "r": B["round"], "pow": cmdPow("hunt", tier)})
			treeFx(_treeFlag(), "twoSalvos", "the next salvo keeps its bonus")
		if treeSkill("namedPrey") != null and side == "player":
			var e2 = treeChoice("enemy")
			if e2 != null:
				B["treeNamedPrey"] = {"id": e2["id"], "r": B["round"]}
				for S in (B.get("torps") if B.get("torps") != null else []):
					if S["side"] == "player": S["tid"] = e2["id"]; S["aim"] = {"q": e2["q"], "r": e2["r"]}
				treeFx(e2, "namedPrey", "the named prey falls")
		if treeSkill("darkKnives") != null and side == "player":
			var powDK = cmdPow("hunt", tier)
			for uDK in caps("player"): uDK["treeHuntRearNext"] = {"r": B["round"] + 1, "n": powDK}   # Sable capstone 1
		if treeSkill("cutFeeds") != null and side == "player":
			for uCF in caps("player"):
				var gCF = treeRearApproach(uCF)
				if gCF != null and treeStepToward(uCF, gCF, 2) > 0: treeFx(uCF, "cutFeeds", "the cut feeds the pack")   # Sable capstone 2
		if treeSkill("filedTriplicate") != null and side == "player":
			var eFT = treeChoice("enemy"); B["treeFiled"] = ({"id": eFT["id"]} if eFT != null else null)
			if eFT != null: treeFx(treeFlagUnit() if treeFlagUnit() != null else eFT, "filedTriplicate", "the target is filed in triplicate")   # Vorn T1a
		if treeSkill("oneOrder") != null and side == "player":
			var anyOO = false
			for uOO in caps("player"):
				var bwOO = -1; var btOO = null; var bvOO = -1.0
				for iOO in range(uOO["weapons"].size()):
					var wOO = uOO["weapons"][iOO]
					if wOO["k"] == "flak" or jt(wOO.get("off")) or z0(wOO.get("cdLeft")) > 0: continue
					for tOO in alive("enemy"):
						if jt(tOO.get("isSq")): continue
						if not canFire(uOO, wOO, tOO): continue
						var eOO = expectedVs(uOO, wOO, tOO); var vOO = eOO["hull"] + eOO["shield"] * 0.3
						if vOO > bvOO: bvOO = vOO; bwOO = iOO; btOO = tOO
				if bwOO >= 0 and btOO != null and treeExtraShot(uOO, bwOO, btOO, {"half": true}): anyOO = true
			if anyOO: treeFx(treeFlagUnit(), "oneOrder", "every gun answers")   # Vorn capstone 2
	if c["id"] == "iron":
		if treeSkill("rechargeLit") != null and side == "player" and not (B.get("treePending") != null and B["treePending"].any(func(p): return p["k"] == "rechargeLit" and p["r"] == B["round"])):
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "rechargeLit", "r": B["round"]})
		for u in alive(side):
			if jt(u.get("shMax")): u["sh"] = [u["shMax"], u["shMax"], u["shMax"], u["shMax"]]
		if side == "player":
			for uIP in caps("player"):
				var ovIP = treeSkill("overflow")
				if ovIP != null and z0(uIP.get("shMax")) > 0 and not jt(uIP.get("treeOverflowUsed")):
					var fullIP = true
					for iIP in range(4):
						if z0(uIP["sh"][iIP]) < z0(uIP["shMax"]): fullIP = false; break
					if fullIP: uIP["treeOverflowUsed"] = 1; uIP["evBuff"] = min(45, z0(uIP.get("evBuff")) + int(ovIP["n"])); treeFx(uIP, "overflow", "the surplus becomes evasion")
				var csIP = treeSkill("columnStraight")
				if csIP != null and treeInColumn(uIP):
					if treeShieldOver(uIP, csIP["n"]) > 0: treeFx(uIP, "columnStraight", "the column adds shield")
				var fsIP = treeSkill("flagshipStandard")
				if fsIP != null and treeInFlagLine(uIP):
					if treeShieldOver(uIP, fsIP["n"]) > 0: treeFx(uIP, "flagshipStandard", "the flagship holds the line")
				if treeSkill("rotation") != null: treeRotSwap(uIP)
		if treeSkill("holdCounted") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "holdCounted", "r": B["round"], "pow": cmdPow("iron", tier)})
		if treeSkill("oathStillness") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "oathStillness", "r": B["round"]})
		if treeSkill("ironTestament") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "ironTestament", "r": B["round"], "pow": cmdPow("iron", tier)})
		if treeSkill("platesShadow") != null and side == "player":
			var whoP = treeChoice("ship"); B["treePlate"] = ({"id": whoP["id"], "r": B["round"]} if whoP != null else null)
			if whoP != null: treeFx(whoP, "platesShadow", "the wall stacks on " + str(whoP["name"]))
		if treeSkill("restoredFleet") != null and side == "player":
			for uR in caps("player"):
				if z0(uR.get("treeRepairedRound")) == B["round"]:
					uR["treeWallCarry"] = {"r": B["round"] + 1, "pow": cmdPow("iron", tier)}; treeFx(uR, "restoredFleet", "the restored hull keeps the wall")
		if treeSkill("layersShift") != null and side == "player":
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "layersShift", "r": B["round"]})
		if side == "player":
			for uWF in caps("player"): uWF["treeWardFacing"] = uWF["facing"]
		var wsI = treeSkill("weakSide")
		if wsI != null and side == "player":
			var candI = []
			for xI in alive("player"):
				if not jt(xI.get("isSq")) and not jt(xI.get("dead")): candI.append(xI)
			JSM.ssort(candI, func(a, b2):
				var sa = 0; var sb = 0
				for v in a["sh"]: sa += z0(v)
				for v in b2["sh"]: sb += z0(v)
				var ddS = sa - sb
				if ddS != 0: return ddS
				return -1.0 if str(a["id"]) < str(b2["id"]) else 1.0)
			if candI.size() > 0:
				B["treeWeakShip"] = {"id": candI[0]["id"], "r": B["round"]}; treeFx(candI[0], "weakSide", "the weak side takes the light")   # Brin T1a
		var pfI = treeSkill("prismsFace")
		if pfI != null and side == "player":
			for uPF in caps("player"):
				if jt(uPF.get("dead")): continue
				var nearPF = null; var ndPF = 1e9
				for fPF in alive("enemy"):
					if jt(fPF.get("isSq")) or jt(fPF.get("dead")): continue
					var dPF = hdist(uPF, fPF)
					if dPF < ndPF: ndPF = dPF; nearPF = fPF
				if nearPF == null: continue
				var wantPF = treeFacingTo(uPF, nearPF)
				if wantPF != null and int(uPF["facing"]) == int(wantPF) and treeShieldOver(uPF, pfI["n"]) > 0: treeFx(uPF, "prismsFace", "the prisms face the fire")   # Brin T1b
		var flI = treeSkill("facetLit")
		if flI != null and side == "player":
			for uFL in caps("player"):
				if not (z0(uFL.get("shMax")) > 0): continue
				var roomFL = max(0, JSM.jsround(uFL["maxHp"] * float(TB.FX_CAPS.get("treeTempHp"))) - z0(uFL.get("tempHp")))
				var addFL = max(0, min(JSM.jsround(uFL["shMax"] * float(flI["n"])), roomFL))
				if addFL > 0: uFL["tempHp"] = z0(uFL.get("tempHp")) + addFL; treeFx(uFL, "facetLit", "the facets are lit")   # Brin capstone 2
		var shI = treeSkill("screensShift")
		if shI != null and side == "player":
			var upI = treeChoice("ship")
			var downI = null; var bdr = -1.0   # the healthiest other ship gives up the 20 points
			for xI2 in alive("player"):
				if jt(xI2.get("isSq")) or jt(xI2.get("dead")) or (upI != null and xI2["id"] == upI["id"]): continue
				var rrI = float(xI2["hp"]) / max(1.0, float(xI2["maxHp"]))
				if downI == null or rrI > bdr or (rrI == bdr and str(xI2["id"]) < str(downI["id"])): bdr = rrI; downI = xI2
			if upI != null: B["treeShiftUp"] = {"id": upI["id"], "r": B["round"]}; treeFx(upI, "screensShift", "the screens shift")
			if downI != null: B["treeShiftDown"] = {"id": downI["id"], "r": B["round"]}   # Thale T1b
		var weI = treeSkill("wallEarly")
		if weI != null and side == "player":
			var earlyI = true
			for xI3 in alive("player"):
				if jt(xI3.get("isSq")): continue
				if z0(xI3.get("hexMoved")) != 0 or jt(xI3.get("treeRoundFired")): earlyI = false; break
			if earlyI: B["treeWallEarly"] = B["round"]; treeFx(treeFlagUnit(), "wallEarly", "the wall is declared early")   # Thale T2a
		var wmI = treeSkill("wallMoves")
		if wmI != null and side == "player":
			for uWM in caps("player"):
				if jt(uWM.get("dead")): continue
				var addWM = treeAddVal(uWM, "speed", wmI["n"]); uWM["mp"] = z0(uWM.get("mp")) + addWM; uWM["postMp"] = z0(uWM.get("postMp")) + addWM
			treeFx(treeFlagUnit(), "wallMoves", "the wall moves")   # Thale capstone 2
	if c["id"] == "restore":
		var rp = cmdPow("restore", tier); var p = side == "player"
		var triage = treeSkill("copiesTriage") if p else null
		var iterFire = treeSkill("iterationFire") if p else null
		var growth = treeSkill("growthWound") if p else null
		var arch = treeSkill("archiveFirst") if p else null
		var tideE = treeSkill("tideEarly") if p else null
		if p and arch != null:
			var acted = true
			for xA in alive("player"):
				if jt(xA.get("isSq")): continue
				if z0(xA.get("hexMoved")) != 0 or jt(xA.get("treeRoundFired")): acted = false; break
			if acted: rp += float(arch["n"]); treeFx(treeFlagUnit(), "archiveFirst", "the archive answers first")   # Nadir T2b
		if p and tideE != null:
			var unhurt = true
			for xT in alive("player"):
				if jt(xT.get("isSq")): continue
				var hs = float(xT["hp"]) if xT.get("treeHpStart") == null else float(xT["treeHpStart"])
				if float(xT["hp"]) < hs: unhurt = false; break
			if unhurt: rp += float(tideE["n"]); treeFx(treeFlagUnit(), "tideEarly", "the tide comes early")   # Mending T2a
		var ninth = treeSkill("restoreNinth") if p else null
		var beyond = treeSkill("restoredBeyond") if p else null
		var contribute = treeSkill("copiesContribute") if p else null
		var tenth = treeSkill("tenthFrame") if p else null
		var earlier = treeSkill("earlierCopy") if p else null
		var gh = treeChoice("ship") if (p and treeSkill("growHurts") != null) else null
		var sk = treeChoice("ship") if (p and treeSkill("skinThick") != null) else null
		var fk = treeSkill("fleshKnit") if p else null
		var te = treeSkill("tideEnd") if p else null
		var tb = treeSkill("tornBack") if p else null
		var weld = treeChoice("ship") if (p and treeSkill("weldMatters") != null) else null
		var pgun = treeSkill("patchGuns") if p else null
		var front = treeChoice("other") if (p and treeSkill("scrapFront") != null) else null
		var wfight = treeSkill("weldedFight") if p else null
		var bolted = treeSkill("doubleBolted") if p else null
		var bites = treeSkill("packBites") if p else null
		var whole = treeSkill("weldedWhole") if p else null
		var frontFlag = treeFlagUnit() if front != null else null
		var frontShare = JSM.jsround(frontFlag["maxHp"] * rp * 2.0) if (front != null and frontFlag != null and not is_same(front, frontFlag)) else 0
		var flesh = []
		var gwList = []
		var flag = treeFlagUnit() if contribute != null else null
		var chosen = treeChoice("ship") if (ninth != null or tenth != null or earlier != null or contribute != null) else null
		if contribute != null and chosen != null and flag != null and is_same(chosen, flag):
			var rest = alive("player").filter(func(x): return not jt(x.get("isSq")) and not is_same(x, flag))
			JSM.ssort(rest, func(a, b):
				var d = (a["hp"] / max(1.0, a["maxHp"])) - (b["hp"] / max(1.0, b["maxHp"]))
				if d != 0: return d
				return -1.0 if str(a["id"]) < str(b["id"]) else 1.0)
			chosen = rest[0] if rest.size() > 0 else flag
		var flagShare = 0.0
		if contribute != null and flag != null and chosen != null and not is_same(chosen, flag): flagShare = JSM.jsround(flag["maxHp"] * rp)
		var chosenBroken = null
		if tenth != null and chosen != null and jt(chosen.get("sec")):
			for k in chosen["sec"].keys():
				if jt(chosen["sec"][k].get("broken")): chosenBroken = k; break
		var firedNinth = false; var firedTenth = false; var firedEarlier = false; var firedContrib = false
		for u in caps(side):
			var amt = rp
			if p and ninth != null: amt = rp if is_same(u, chosen) else rp / 2.0
			if p and tenth != null and is_same(u, chosen): amt = rp * 3.0
			var heal = JSM.jsround(u["maxHp"] * amt)
			if contribute != null and flag != null and is_same(u, flag): heal = 0
			if contribute != null and chosen != null and is_same(u, chosen) and (flag == null or not is_same(u, flag)): heal += flagShare
			if front != null and frontFlag != null and is_same(u, frontFlag): heal = 0
			if front != null and is_same(u, front) and (frontFlag == null or not is_same(u, frontFlag)): heal += frontShare
			var hp0 = u["hp"]
			var secFullBefore = {}
			if jt(u.get("sec")):
				for kFB in u["sec"].keys():
					var sFB = u["sec"][kFB]
					if not jt(sFB.get("broken")) and float(sFB["hp"]) >= float(sFB["max"]): secFullBefore[kFB] = 1
			var skin = p and sk != null and is_same(u, sk)
			if skin:
				var skn = float(treeSkill("skinThick")["n"]); var cap = z0(TB.FX_CAPS.get("treeTempHp")) if jt(TB.FX_CAPS.get("treeTempHp")) else 0.2
				var add = max(0, min(JSM.jsround(u["maxHp"] * skn), JSM.jsround(u["maxHp"] * cap) - z0(u.get("tempHp"))))
				u["tempHp"] = z0(u.get("tempHp")) + add
				if add > 0: treeFx(u, "skinThick", "the regrowth is grown thick")
				flt(u, "+" + ns(add) + " grown hull", "#8ff0a0", -20)
			else:
				u["hp"] = min(u["maxHp"], u["hp"] + heal)
			var secFixed = []
			if jt(u.get("sec")) and not skin and not (front != null and frontFlag != null and is_same(u, frontFlag)):
				var torn = {}
				if tb != null:
					for k in u["sec"].keys():
						var sT = u["sec"][k]
						if jt(sT.get("broken")):
							repairSection(u, k, 1.0); sT["treeLock"] = 1; torn[k] = 1; treeFx(u, "tornBack", "the torn section grows back")
				if whole != null:
					for k in u["sec"].keys():
						var sW = u["sec"][k]
						if jt(sW.get("broken")):
							repairSection(u, k, 1.0); torn[k] = 1; treeFx(u, "weldedWhole", "the hull is welded whole"); break   # Vesh capstone 1
				if weld != null and is_same(u, weld):
					var bestW = null; var bvW = 2.0
					for k in u["sec"].keys():
						var sWe = u["sec"][k]
						if jt(sWe.get("broken")): continue
						var rrW = float(sWe["hp"]) / float(sWe["max"])
						if rrW < bvW: bvW = rrW; bestW = k
					if bestW != null:
						repairSection(u, bestW, amt); secFixed.append(bestW); treeFx(u, "weldMatters", "the weld goes where it matters")   # Vesh T1a
				elif gh != null and is_same(u, gh):
					var best = null; var bv = 2.0
					for k in u["sec"].keys():
						var sG = u["sec"][k]
						if jt(sG.get("broken")): continue
						var rr = float(sG["hp"]) / float(sG["max"])
						if rr < bv: bv = rr; best = k
					if best != null:
						repairSection(u, best, amt); treeFx(u, "growHurts", "the regrowth goes where it hurts")
				else:
					var fixed = 0
					for k in u["sec"].keys():
						if torn.has(k): continue
						var sN = u["sec"][k]; var h0 = sN["hp"]; repairSection(u, k, amt)
						if sN["hp"] > h0: fixed += 1; secFixed.append(k)
					if fixed != 0: flt(u, (ns(fixed) + " sections restored") if fixed > 1 else "Section restored", "#8ff0a0", -34)
			if p and earlier != null and is_same(u, chosen):
				if jt(u.get("sec")):
					for k in u["sec"].keys(): repairSection(u, k, rp)
				u["hp"] = min(u["maxHp"], u["hp"] + JSM.jsround(u["maxHp"] * rp))
				if not firedEarlier: firedEarlier = true; treeFx(u, "earlierCopy", "the earlier copy returns")
			if tenth != null and is_same(u, chosen) and chosenBroken != null and jt(u.get("sec")) and u["sec"].get(chosenBroken) != null:
				var sD = u["sec"][chosenBroken]; sD["broken"] = false; sD["hp"] = sD["max"]
			if u["hp"] > hp0 or secFixed.size() > 0: treeMarkRepair(u)
			if p and triage != null and jt(u.get("sec")):
				var toFull = false
				for kTF in u["sec"].keys():
					var sTF = u["sec"][kTF]
					if not jt(sTF.get("broken")) and float(sTF["hp"]) >= float(sTF["max"]) and not jt(secFullBefore.get(kTF)): toFull = true; break
				if toFull and (z0(u["st"].get("fire")) > 0 or z0(u["st"].get("acid")) > 0):
					u["st"]["fire"] = 0; u["st"]["acid"] = 0; treeFx(u, "copiesTriage", "the copies triage the damage")   # Nadir T1b
			if p and iterFire != null and (u["hp"] > hp0 or secFixed.size() > 0):
				u["treeIterFire"] = treeAddVal(u, "dmgPct", iterFire["n"]); treeFx(u, "iterationFire", "the rebuild does not wait")   # Nadir T2a
			if p and growth != null and secFixed.size() > 0:
				for kGW in secFixed: gwList.append({"id": u["id"], "sec": kGW, "amt": amt})   # Mending T2b
			if not skin: flt(u, "+" + ns(JSM.jsround(u["maxHp"] * rp)) + " hull", "#8ff0a0", -20)
			if p and beyond != null and secFixed.size() > 0:
				if u.get("treeRebuilt") == null: u["treeRebuilt"] = {}
				for k in secFixed:
					if jt(u["treeRebuilt"].get(k)): continue
					u["treeRebuilt"][k] = 1; var sE = u["sec"][k]; var addB = JSM.jsround(sE["max"] * float(beyond["n"]))
					sE["max"] = sE["max"] + addB; sE["hp"] = min(sE["max"], sE["hp"] + addB); treeFx(u, "restoredBeyond", "the section is rebuilt stronger")
			if p and ninth != null and is_same(u, chosen) and not firedNinth: firedNinth = true; treeFx(u, "restoreNinth", "the ninth frame is restored")
			if p and tenth != null and is_same(u, chosen) and not firedTenth: firedTenth = true; treeFx(u, "tenthFrame", "the tenth frame is restored")
			if p and contribute != null and is_same(u, chosen) and (flag == null or not is_same(u, flag)) and not firedContrib: firedContrib = true; treeFx(u, "copiesContribute", "the flagship share is divided")
			if p and pgun != null:
				var gunSec = false
				for kG in secFixed:
					if kG == "prow" or kG == "mid": gunSec = true; break
				if gunSec: u["treeAimGuns"] = treeAddVal(u, "aim", pgun["n"]); treeFx(u, "patchGuns", "the patched guns find the mark")   # Vesh T1b
			if p and bolted != null and secFixed.size() > 0:
				if u.get("treeBolted") == null: u["treeBolted"] = {}
				for kB in secFixed:
					if jt(u["treeBolted"].get(kB)): continue
					u["treeBolted"][kB] = 1; var sB = u["sec"][kB]; var addBl = JSM.jsround(sB["max"] * float(bolted["n"]))
					sB["max"] = sB["max"] + addBl; sB["hp"] = min(sB["max"], sB["hp"] + addBl); treeFx(u, "doubleBolted", "the plate is double-bolted")   # Vesh T3a
			if p and bites != null and hp0 < u["maxHp"] * 0.5 and u["hp"] >= u["maxHp"] * 0.5:
				u["treeDmgCarry"] = {"r": B["round"] + 1, "n": bites["n"]}; treeFx(u, "packBites", "the pack bites on")   # Vesh T3b
			if p and front != null and is_same(u, front) and (frontFlag == null or not is_same(u, frontFlag)): treeFx(u, "scrapFront", "the scrap goes to the front")   # Vesh T2a
			if p and wfight != null and (u["hp"] > hp0 or secFixed.size() > 0):
				var bwW = -1; var btW = null; var bvW2 = -1.0
				for iW in range(u["weapons"].size()):
					var wW = u["weapons"][iW]
					if wW["k"] == "flak" or jt(wW.get("off")): continue
					for tW in alive(foe):
						if not canFire(u, wW, tW): continue
						var eW = expectedVs(u, wW, tW); var vW = eW["hull"] + eW["shield"] * 0.3
						if vW > bvW2: bvW2 = vW; bwW = iW; btW = tW
				if bwW >= 0 and btW != null and treeExtraShot(u, bwW, btW, {"half": true}): treeFx(u, "weldedFight", "the weld fires while it is hot")   # Vesh T2b
			if p and fk != null and u["hp"] > u["maxHp"] * 0.75: flesh.append(u["id"])
		if p and fk != null and flesh.size() > 0:
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "fleshKnit", "r": B["round"], "ids": flesh})
			treeFx(_treeFlag(), "fleshKnit", "the new flesh is angry")   # Mending T3a
		if p and te != null:
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "tideEnd", "r": B["round"], "pow": rp})
			treeFx(_treeFlag(), "tideEnd", "the tide will come again")   # Mending capstone 1
		if p and growth != null and gwList.size() > 0:
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "growthWound", "r": B["round"], "list": gwList})
			treeFx(treeFlagUnit(), "growthWound", "the wound will hold its growth")   # Mending T2b
	if c["id"] == "surge":
		for u in caps(side):
			u["mp"] = z0(u.get("mp")) + cmdPow("surge", tier); u["turnsLeft"] = z0(u.get("turnsLeft")) + (2 if tier >= 2 else 1)
		if side == "player":
			if treeSkill("razorPrey") != null:
				var e = treeChoice("enemy")
				B["treeRazorPrey"] = ({"id": e["id"], "r": B["round"]} if e != null else null)
				if e != null: treeFx(_treeFlag() if _treeFlag() != null else e, "razorPrey", "the prey is named")   # Razormaw T2a
			if treeSkill("preyEveryMouth") != null:
				var e2 = treeChoice("enemy")
				B["treeRazorPrey"] = ({"id": e2["id"], "r": B["round"]} if e2 != null else null)
				for u in alive("player"):
					if not jt(u.get("isSq")): u["turnsLeft"] = z0(u.get("turnsLeft")) + 1
				treeFx(_treeFlag() if _treeFlag() != null else null, "preyEveryMouth", "every mouth turns to the prey")   # Razormaw capstone 2
			if treeSkill("burnCarry") != null:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "burnCarry", "r": B["round"], "pow": cmdPow("surge", tier), "turns": (2 if tier >= 2 else 1)})
				treeFx(treeFlagUnit(), "burnCarry", "the burn will carry")   # Grax capstone 1
			if treeSkill("warlordRun") != null:
				var pgWR = treeFlagUnit()
				if pgWR != null: pgWR["treeWarlord"] = 1; treeFx(pgWR, "warlordRun", "the warlord runs again")   # Grax capstone 2
	if c["id"] == "scramble":
		var ct = treeChoice("carrier") if treeSkill("castTwice") != null else null
		var aloft = treeSkill("lensAloft")
		var nine = treeSkill("nineThroats") if side == "player" else null
		var nineT = treeChoice("enemy") if nine != null else null
		if nine != null and nineT != null: B["tr"]["swarmHunger"] = {"r": B["round"], "id": nineT["id"]}; treeFx(nineT, "nineThroats", "nine throats choose one hunger")   # Matriarch capstone 1
		var fw = treeChoice("carrier") if (side == "player" and treeSkill("firstWave") != null) else null
		var esc = treeChoice("friend") if (side == "player" and treeSkill("escortName") != null) else null
		var gen = treeSkill("generation") if side == "player" else null
		var resv = treeSkill("wingReserve") if side == "player" else null
		var resvDone = false; var escDone = false
		var brood = treeChoice("brood") if (side == "player" and treeSkill("chooseBrood") != null) else null
		var spore = treeSkill("sporeTide") if side == "player" else null
		var every = treeSkill("everyThroat") if side == "player" else null
		var patched = treeSkill("patchedWing") if side == "player" else null
		var patchedPick = treeChoice("carrier") if patched != null else null
		var hulk = treeSkill("hulkMore") if side == "player" else null
		var hulkPick = treeChoice("largest") if hulk != null else null
		var wreck = treeSkill("wreckLine") if side == "player" else null
		var yard = treeSkill("wholeYard") if side == "player" else null
		var priv = treeSkill("privateWing") if side == "player" else null
		var privPick = treeChoice("carrier") if priv != null else null
		var scrap = treeSkill("swarmScrap") if side == "player" else null
		var cru = treeChoice("largest") if (side == "player" and treeSkill("cruisersCarriers") != null) else null
		var launchOrd = treeSkill("launchOrder") if side == "player" else null
		var secondW = treeSkill("secondWave") if side == "player" else null
		var fullG = treeSkill("fullGroup") if side == "player" else null
		var escortScr = treeSkill("escorts") if side == "player" else null
		var oneTgt = treeSkill("oneTarget") if side == "player" else null
		var stand = treeSkill("standingGroup") if side == "player" else null
		var filedT = treeChoice("enemy") if (fullG != null or oneTgt != null) else null
		var ships = []
		for uS in alive(side):
			if uS.get("ab") == "launch": ships.append(uS)
		var allLaunch = false
		if fullG != null and ships.size() > 0:
			allLaunch = true
			for uS in ships:
				if treeLaunchHexes(uS, 2).size() == 0: allLaunch = false; break
		var heldShips = []; var patrolMarked = {}; var launchFirst = false
		if escortScr != null: B["tr"]["escortScreen"] = B["round"]; treeFx(treeFlagUnit(), "escorts", "the wings form a screen")
		if treeSkill("flakSkip") != null and side == "player":
			var en = treeChoice("enemy"); B["treeFlakSkip"] = en["id"] if en != null else null
			if en != null:
				for w in en["weapons"]:
					if w["k"] == "flak": treeFx(en, "flakSkip", "point defence cannot see the wings"); break
		var cars = []
		for u in alive(side):
			if u.get("ab") == "launch": cars.append(u)
		for u in cars:
			if brood != null and u["id"] != brood["id"]: continue   # Matriarch T1a: the other broods release none extra
			var count = 2 if tier >= 2 else 1
			if brood != null and u["id"] == brood["id"]: count += 1; treeFx(u, "chooseBrood", "the chosen brood swells")
			if aloft != null and side == "player" and z0(u.get("hexMoved")) == 0: count += 1; treeFx(u, "lensAloft", "one more wing aloft")
			if gen != null and z0(u.get("hexMoved")) == 0: count += 1; treeFx(u, "generation", "one more generation aloft")
			if yard != null and (squadronsOf(u).size() + count) >= z0(u.get("hangar")): count += 1; treeFx(u, "wholeYard", "the whole yard flies")   # Mott T3a
			if allLaunch: count += 1; treeFx(u, "fullGroup", "the full group assembles")   # Reyes T3a
			if secondW != null: heldShips.append({"id": u["id"], "count": count}); treeFx(u, "secondWave", "the extra wings are held for next round"); continue
			var k = 0
			while k < count:
				var hs = treeLaunchHexes(u, float(spore["n"])) if spore != null else (treeLaunchHexes(u, 2) if allLaunch else launchHexes(u))
				if hs.size() == 0: break
				var fs = alive(foe)
				JSM.ssort(hs, func(a, b2): return _mind(a, fs) - _mind(b2, fs))
				if resv != null and not resvDone and k == count - 1:
					if B.get("treePending") == null: B["treePending"] = []
					B["treePending"].append({"k": "wingReserve", "r": B["round"], "carrier": u["id"]})
					resvDone = true; treeFx(u, "wingReserve", "one wing waits in reserve"); k += 1; continue
				var sq = makeWing(u, hs[0], wingKind(u)); sq["extra"] = 1
				if nine != null and nineT != null: sq["wingOrder"] = {"kind": "strike", "id": nineT["id"]}   # Matriarch capstone 1: every extra swarm hunts the one hunger
				if (fullG != null or oneTgt != null) and filedT != null: sq["wingOrder"] = {"kind": "strike", "id": filedT["id"]}; treeFx(sq, "fullGroup" if fullG != null else "oneTarget", "the wings file on " + str(filedT["name"]))
				if oneTgt != null and filedT != null: B["tr"]["wingFiled"] = {"r": B["round"], "id": filedT["id"]}
				if stand != null and not patrolMarked.has(u["id"]): sq["treePatrol"] = 1; patrolMarked[u["id"]] = 1; treeFx(sq, "standingGroup", "the wing stays on patrol")
				if launchOrd != null and not launchFirst: launchFirst = true; sq["treeBonus"] = z0(sq.get("treeBonus")) + float(launchOrd["n"]); treeFx(sq, "launchOrder", "the first wing strikes first")
				if spore != null: treeFx(u, "sporeTide", "the spores ride the tide")   # Matriarch T1b
				if every != null and z0(u.get("hexMoved")) == 0: sq["treeBonus"] = every["n"]; treeFx(u, "everyThroat", "the throat opens wide")   # Matriarch T3a
				if fw != null and u["id"] == fw["id"]: sq["treeBonus"] = treeSkill("firstWave")["n"]; treeFx(u, "firstWave", "the first wave owes the second")
				if wreck != null and z0(u.get("hexMoved")) == 0: sq["treeBonus"] = z0(sq.get("treeBonus")) + float(wreck["n"]); treeFx(u, "wreckLine", "the wings come off the wreck line")   # Mott T2b
				if patchedPick != null and u["id"] == patchedPick["id"]: sq["treeBonus"] = z0(sq.get("treeBonus")) + treeAddVal(sq, "sqPct", patched["n"]); sq["treeRemove"] = 1; treeFx(u, "patchedWing", "the patched wing flies")   # Mott T1a
				if privPick != null and u["id"] == privPick["id"]: sq["treePrivate"] = 1; treeFx(u, "privateWing", "the private wing flies")   # Mott capstone 2
				if esc != null and not escDone:
					sq["escort"] = esc["id"]; sq["wingOrder"] = {"kind": "guard", "id": esc["id"]}; escDone = true; treeFx(sq, "escortName", "the escort is sworn to " + str(esc["name"]))
				if ct != null and u["id"] == ct["id"]:
					sq["treeTwice"] = 1; var e = treeChoice("enemy")
					if e != null: sq["treeTgt"] = e["id"]
				k += 1
		if hulkPick != null and side == "player":
			var hsH = launchHexes(hulkPick)
			if hsH.size() > 0:
				var fsH = alive(foe); JSM.ssort(hsH, func(a, b2): return _mind(a, fsH) - _mind(b2, fsH))
				var sqH = makeWing(hulkPick, hsH[0], wingKind(hulkPick)); sqH["extra"] = 1; treeFx(hulkPick, "hulkMore", "a wing comes off the spare racks")   # Mott T1b
		if cru != null and side == "player":
			var hsC = launchHexes(cru)
			if hsC.size() > 0:
				var fsC = alive(foe); JSM.ssort(hsC, func(a, b2): return _mind(a, fsC) - _mind(b2, fsC))
				var sqC = makeWing(cru, hsC[0], wingKind(cru)); sqC["extra"] = 1
				if (fullG != null or oneTgt != null) and filedT != null: sqC["wingOrder"] = {"kind": "strike", "id": filedT["id"]}
				if stand != null: sqC["treePatrol"] = 1; patrolMarked[cru["id"]] = 1
				if launchOrd != null and not launchFirst: launchFirst = true; sqC["treeBonus"] = z0(sqC.get("treeBonus")) + float(launchOrd["n"])
				treeFx(cru, "cruisersCarriers", "a hull without a hangar launches a wing")   # Reyes T1a
		if secondW != null and side == "player" and heldShips.size() > 0:
			if B.get("treePending") == null: B["treePending"] = []
			B["treePending"].append({"k": "secondWave", "r": B["round"], "ships": heldShips}); treeFx(treeFlagUnit(), "secondWave", "the extra wings are held for next round")
		for sq in alive(side):
			if not jt(sq.get("isSq")): continue
			sq["activated"] = false; sq["mp"] = sq["speed"]
			for w in sq["weapons"]:
				w["fired"] = false; w["cdLeft"] = 0
		if side == "player": B["tr"]["strikeAgain"] = B["round"]
		swarmPhase(side)
		if side == "player": B["tr"]["strikeAgain"] = 0
		if side == "player":
			for sqR in alive("player").filter(func(x): return jt(x.get("isSq")) and jt(x.get("treeRemove"))):
				sqR["dead"] = true; sqR["hp"] = 0; treeFx(sqR, "patchedWing", "the patched wing comes apart")   # Mott T1a: removed after its strike
		if side == "player" and treeSkill("forgeAhead") != null:
			var listFo = []; var seenFo = {}
			for sqF in alive("player"):
				if not (jt(sqF.get("isSq")) and jt(sqF.get("extra")) and sqF.get("treeLastTgt") != null): continue
				if seenFo.has(sqF.get("parent")): continue
				seenFo[sqF.get("parent")] = 1
				var tgtFo = null
				for xFo in B["units"]:
					if xFo["id"] == sqF.get("treeLastTgt") and not jt(xFo.get("dead")): tgtFo = xFo; break
				if tgtFo != null: listFo.append({"carrier": sqF.get("parent"), "tid": sqF.get("treeLastTgt")})
			if listFo.size() > 0:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "forgeAhead", "r": B["round"], "list": listFo}); treeFx(treeFlagUnit(), "forgeAhead", "the forge will cast ahead")   # Tamsa capstone 2
		if scrap != null and side == "player":
			var idsSc = []
			for uSc in alive(side):
				if uSc.get("ab") == "launch" and not jt(uSc.get("isSq")): idsSc.append(uSc["id"])
			if idsSc.size() > 0:
				if B.get("treePending") == null: B["treePending"] = []
				B["treePending"].append({"k": "swarmScrap", "r": B["round"], "ids": idsSc})
				treeFx(treeFlagUnit(), "swarmScrap", "the swarm launches again after the last activation")   # Mott capstone 1: the second launch waits for the end of the player turn
		if ct != null and side == "player":
			for sq in alive(side):
				if not jt(sq.get("isSq")) or not jt(sq.get("treeTwice")): continue
				var tt = null
				for x in B["units"]:
					if x["id"] == sq.get("treeTgt"): tt = x; break
				if tt == null or jt(tt.get("dead")) or z0(tt.get("hexMoved")) != 0: continue
				var fired2 = false
				for w in sq["weapons"]: w["fired"] = false
				for i in range(sq["weapons"].size()):
					if jt(tt.get("dead")) or jt(B.get("over")): break
					if canFire(sq, sq["weapons"][i], tt):
						fireWeapon(sq, i, tt, {"half": true}); fired2 = true
				if fired2: treeFx(sq, "castTwice", "the recorded strike repeats at half damage")
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
		if (x.get("ab") == "launch" or jt(g(x.get("fx"), "hive"))) and not jt(x.get("dead")) and not jt(x.get("isSq")) and not jt(x.get("treeOff")): carriers.append(x)
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
	if t == null or jt(t.get("dead")) or (t["side"] == s["side"] if o["kind"] == "strike" else t["side"] != s["side"]):
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
	var lim = int(TB.SQ_LEASH) + (2 if (ord != null and ord.kind == "strike") else 0) + (TB.WING_HUNT_LEASH if stc == "hunt" else 0)
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
# R88: player replacement launches use the same reserves, cooldown and next-round readiness.
func launchReady(u) -> bool:
	return u.get("ab") == "launch" and not jt(u.get("dead")) and not gt(u.get("abCd"), 0) and not jt(u.get("braced")) and squadronsOf(u).size() < u["hangar"] and (u.get("spare") == null or u["spare"] > 0) and launchHexes(u).size() > 0
func launchWing(u, h, kind) -> void:
	if u.get("spare") != null: u["spare"] = max(0, u["spare"] - 1)
	var sq = makeWing(u, h, kind); sq["mp"] = 0
	for w in sq["weapons"]: w["fired"] = true
	logm(String(u["name"]) + " launches a " + String(HULLS[kind]["n"]).to_lower() + ".", pp(u))
func replaceWings(side) -> void:
	for u in alive(side):
		if jt(u.get("isSq")) or not launchReady(u): continue
		var foes = alive("enemy" if side == "player" else "player"); var hs = launchHexes(u)
		JSM.ssort(hs, func(a, b): return _mind(a, foes, 99) - _mind(b, foes, 99))
		launchWing(u, hs[0], wingKind(u)); u["abCd"] = abilityCd(u)
func canAbility(u) -> bool:
	if not jt(u.get("ab")) or jt(u.get("dead")) or u["abCd"] > 0 or jt(u.get("braced")): return false
	var ab = u["ab"]
	if ab == "surge" and jt(u.get("st")) and u["st"]["shieldOff"] >= 99: return false
	if ab == "launch": return u["side"] != "player" and launchReady(u)
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
			if not jt(t.get("isSq")) and hdist(t, u) <= 4 and t["sh"].any(func(x): return x > 0): return true
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
			logm(String(u["name"]) + " rebuilds " + ("its own hull" if is_same(t, u) else String(t["name"])) + " for " + ns(h) + ".", pp(u))
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
		launchWing(u, h, kind)
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
			var dmg = (40.0 if hdist(x, c) == 0 else 20.0) * u["dmg"] * (1.5 if jt(x.get("isSq")) else 1.0) * storyDamageMult(u)
			var quad = shieldQuad(x, u)
			var r = applyHit(u, {"pierce": 0.3, "crit": 5}, x, dmg, quad)
			if jt(r.shield): flt(x, "−" + ns(r.shield), "#7fd6c8", -18)
			flt(x, "−" + ns(r.hull), "#ff7a6e", 0)
			logm("Spinal shell hits " + String(x["name"]) + " for " + ns(r.hull) + " hull" + ((" and " + ns(r.shield) + " shields") if jt(r.shield) else "") + ".", pe(x))
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
		var val: float = (min(hull, t["hp"]) + sh) * (0.6 if jt(t.get("isSq")) else 1.1) + ((25.0 + t["maxHp"] * 0.15) if hull >= t["hp"] else 0.0) + (10.0 if (focus != null and is_same(t, focus)) else 0.0) + (1.0 - float(t["hp"]) / t["maxHp"]) * 15.0 + nemTargetBonus(u, t)
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
# veteran AI: brace instead of firing when the incoming fire is heavy, our own guns can do little and the hull is already down
func aiVetBrace(u) -> bool:
	if not (aiVet() and not jt(u.get("isSq")) and not jt(u["t"].get("boss")) and canOrder(u, "brace")): return false
	var pf = alive("player"); var myOff = evalOffense(u, readyList(u), pf); var thr = evalThreat(u, pf)
	return thr > u["hp"] * 0.45 and myOff < thr * 0.35 and u["hp"] < u["maxHp"] * 0.7
func aiUnit(u) -> void:
	if jt(u.get("isSq")):
		if not jt(B.get("over")) and not jt(u.get("dead")) and u["side"] == "enemy": sqAct(u)
		return
	# H17 The First Throat Opens: in Alternating mode the enemy's paired activation after the flagship is skipped once
	if u["side"] == "enemy" and treeSkill("firstThroat") != null and B.get("alt") != false and B.get("tr") != null and not jt(B["tr"].get("firstThroatUsed")):
		var fg = null
		for x in B["units"]:
			if jt(x.get("pflag")) and not jt(x.get("dead")): fg = x; break
		if fg != null and jt(fg.get("activated")):
			B["tr"]["firstThroatUsed"] = 1; treeFx(fg, "firstThroat", "one more throat opens"); return
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
		var prof = nemProf(u, FACTION_AI[u["fac"]] if (not jt(u.get("isSq")) and jt(FACTION_AI.get(u["fac"]))) else FACTION_AI["voidsworn"])
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
			score -= torpThreat(u, v) * 0.9; score -= syncPull(u, v) * (2.0 if vet else 1.2) * (2.0 if (jt(u.get("nem")) and jt(B.get("nemLine"))) else 1.0)
		if jt(B.get("obj")) and B["obj"].type == "hold" and not jt(u.get("isSq")) and not vet: score -= hdist(v, B["obj"].hex) * 1.6
		score += aiObjScore(u, v); score += aiWellScore(u, v)
		if score > bestScore:
			bestScore = score; best = s
	eval_end()
	var vctx = {"started": false, "result": null, "brace": false}
	if best != null and best.path.size() > 0:
		var midFire: bool = not jt(u.get("isSq")) and not jt(runner) and not (u.get("ab") == "nova" and canAbility(u))
		var mopts: Variant = null
		if midFire:
			var on_late = func():
				if boardTargets(u).size() > 0: return
				if aiVetBrace(u):   # R1 (AI-1): the veteran brace decision on the mid-move path, after the boarding deferral, before the volley
					vctx.brace = true; return
				vctx.started = true
				if not aiAbilities(u, live, "aim") or jt(u.get("dead")):
					vctx.result = null; return
				vctx.result = aiVolley(u, live)
			mopts = {"onLate": on_late}
		moveUnit(u, best, mopts)
		if not live.call(): return
	if vctx.brace:
		if not jt(u.get("dead")): giveOrder(u, "brace")
		B["aiActive"] = null; u["activated"] = true; return
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
	if aiVetBrace(u):
		giveOrder(u, "brace"); B["aiActive"] = null; u["activated"] = true; return
	if not aiAbilities(u, live, "aim"): return
	var fired2 = aiVolley(u, live)
	if fired2 == null: return
	if not aiAfterFire(u, live, runner): return
	if not jt(fired2) and not jt(u.get("isSq")) and not jt(u.get("dead")) and u["hp"] < u["maxHp"] * 0.5 and canOrder(u, "brace") and evalThreat(u, alive("player")) > 10: giveOrder(u, "brace")
	B["aiActive"] = null; u["activated"] = true
