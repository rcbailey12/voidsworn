extends RefCounted
# Voidsworn campaign (G3): the rules of a run and its screen flow, a GDScript port of the browser game's core.js (run parts),
# campaign_run.js, campaign_meta.js and campaign3d.js (pinned copies in test/oracle/). Same names, same order, same maths as the JS.
#
# How the screens work: every place the JS calls show(html) or modal(html), this port calls page()/modal() with a screen kind,
# the data the screen needs and its buttons, in the same order as the browser's buttons: [act, arg, enabled]. The Godot UI
# (godot/ui/campaign/) draws the current page and modal; a click (or a bot, or a test) calls act(name, arg). Nothing else
# changes campaign state, so every choice in a run can be made by a function call.
#
# Parity: test/parity_campaign.gd plays the same seeded runs as the JS (test/node/golden_campaign.js) and compares the state
# after every click. Battles go through one function, start_battle(), which uses the stub battle until real battles are hooked in.

signal changed            # the page or the modal changed
signal battle_requested   # a battle page is up (external mode): the battle side reads pending_battle and calls finish_battle()

const BattleAPI = preload("res://rules/battle_api.gd")   # the rules are reached only through the battle API (rules/API.md)
const JSM = BattleAPI.JSM   # the shared JS maths and the one PRNG the rules and the campaign both draw from
const TABLES_PATH := "res://campaign/data/campaign_tables.json"

# ---------------- tables ----------------
var TB: Dictionary = {}
var W_; var HULLS; var FACTIONS; var MODULES; var PERKS; var RELICS; var ADMIRALS; var RANKS; var RANK_XP; var PATRONS; var BOONS
var BOON_FX; var BOON_D; var BOON_NEED; var RARITY; var ASPECTS; var HEAT; var HULL_VARIANTS; var MASTERY_XP; var MASTERY_PERKS
var FAVOUR_TIERS; var SECTOR_CONDS; var SECTOR_POOL; var EVENTS; var CAPTAINS; var SHIP_NAMES; var MORE_SHIP_NAMES; var FNAMES
var MOD_NEED; var MOD_NAMES; var RELIC_NAMES; var RUN_WORD; var ENCOUNTERS; var ENC_POOL; var ENC_SPECIAL; var REGIONS; var FAC_REGION
var REGION_BIOME; var ROCK_KINDS; var DEEP_MAPS; var FAC_MAP; var BEVENTS; var KILL_CAUSES; var FAC_WNAMES; var FAC_WTRAIT; var WTRAITS
var ABILITIES; var ARC_NAME; var NODE_INFO; var NODE_MODS; var ARCHETYPES; var SHAPES; var REWARD_DEF; var MAP_NAME; var WIN_TITLE
var LEGACY; var CMD_TEXT; var CAUSE_WORD; var RUN_FACTIONS
var NEM_TRAITS; var NEM_PERSONA; var NEM_FAC; var NEM_ADAPT_FAC; var NEM_LINES; var NEM_BEAT_WORD; var ARC_VARIANT
var NEM_WEAK; var NEM_ADAPT; var NEM_CLOCK; var FAC_VERBS; var WING_PERKS; var WING_XP; var EVENT_FALLBACK; var FAC_GATES; var CLASS_TRACK_MAX; var KIND_WORD

# ---------------- state ----------------
var META: Dictionary = {}
var RUN = null          # the run (Dictionary) or null
var SAVED_RUN = null    # the last saved copy of the run
var B = null            # the battle in progress (the stub's, or the rules' B handed back by finish_battle)
var UID := 1
var W: Dictionary = {}  # the JS window._* transients: rewardCfg, rw, relicChoice, wrecks, boonOffer, modOffer, aspOffer
var promote_after: Callable = Callable()
var cur_event = null
# Story arcs (godot/story/README.md "Story arcs"): a faction arc card at the start of each sector, drawn by the event screen.
# OFF until the coordinator relays Ryan's approval of the arc text; with arcs_on false nothing below runs, so parity is unchanged.
var arcs_on := false
var arc_source = null    # Callable(beat 1..3) -> event-shaped card (story.arc_beat), {} when the faction has no arc file
var arc_chose_cb = null  # Callable(card, key) (story.arc_chose), after the campaign applied the choice
var arc_end_cb = null    # Callable(won) (story.arc_end), at the end of a run whose beat 3 was played
var yard_node = null
var picked_admiral := "vex"
var picked_faction := "voidsworn"
var run_opt := {"alt": false, "cmdAlt": false, "heat": []}
var prog_tab := "variants"
var page := {"kind": "none", "data": {}, "acts": []}
var modal_d = null       # {kind, data, acts} or null
var toasts: Array = []   # messages for the UI to show (and clear)
var ended := false       # endRun ran (the end screen is up)
var battle_mode := "stub"   # "stub": act("battle", outcome) resolves fights; "external": the battle scene plays them
var pending_battle = null   # external mode: the battle config waiting for the battle scene
var fixed_clock := false    # the parity harness pins the clock to 0, like the JS harness pins Date.now()
var persist_on := false     # write the save file on every save (the game); the harness keeps saves in memory
var save_path := "user://voidsworn_campaign.json"
var tel_log: Array = []     # a slim run log (events only), kept with the save; not part of parity

# ======================= setup =======================
# Every table the campaign reads. load_tables refuses to start when one is missing, and export_campaign.js fails when the oracle
# lacks one (it also scans the campaign scripts for every TB table they read, so a new table cannot slip past this list).
const REQUIRED_TABLES = ["ABILITIES", "ADMIRALS", "ARCHETYPES", "ARC_NAME", "ARC_VARIANT", "ASPECTS", "BEVENTS", "BOONS", "BOON_D", "BOON_FX", "BOON_NEED", "BOSS_DMG", "BOSS_FAC", "BOSS_SCALE", "CAPTAINS", "CAUSE_WORD", "CLASS_TRACK_MAX", "CMD_TEXT", "DEEP_MAPS", "ENCOUNTERS", "ENC_POOL", "ENC_SPECIAL", "EVENTS", "EVENT_FALLBACK", "FACTIONS", "FAC_GATES", "FAC_MAP", "FAC_REGION", "FAC_VERBS", "FAC_WNAMES", "FAC_WTRAIT", "FAVOUR_TIERS", "FNAMES", "HEAT", "HULLS", "HULL_VARIANTS", "KILL_CAUSES", "KIND_WORD", "LEGACY", "MAP_NAME", "MASTERY_PERKS", "MASTERY_XP", "MODULES", "MOD_NAMES", "MOD_NEED", "MORE_SHIP_NAMES", "NEM_ADAPT", "NEM_ADAPT_FAC", "NEM_BEAT_WORD", "NEM_CLOCK", "NEM_FAC", "NEM_LINES", "NEM_PERSONA", "NEM_TRAITS", "NEM_WEAK", "NODE_INFO", "NODE_MODS", "PATRONS", "PERKS", "RAMP", "RANKS", "RANK_XP", "RARITY", "REGIONS", "REGION_BIOME", "RELICS", "RELIC_NAMES", "REWARD_DEF", "ROCK_KINDS", "RUN_FACTIONS", "RUN_WORD", "SECTOR_CONDS", "SECTOR_POOL", "SHAPES", "SHIP_NAMES", "W", "WING_PERKS", "WING_XP", "WIN_TITLE", "WTRAITS"]
func load_tables(path: String = TABLES_PATH) -> String:
	var txt = FileAccess.get_file_as_string(path)
	var j = JSON.parse_string(txt)
	if j == null: return "cannot read " + path
	if not (j is Dictionary) or not (j.get("tables") is Dictionary): return "campaign tables: " + path + " has no tables"
	var missing := []
	for n in REQUIRED_TABLES:
		if not j["tables"].has(n): missing.append(n)
	if not missing.is_empty(): return "campaign tables missing (re-run godot/campaign/test/node/export_campaign.js): " + ", ".join(missing)
	TB = _dec(j["tables"])
	var sum = JSM.sha256(JSM.canon(TB, "t", {}, true))
	if sum != j["sha256"]: return "campaign table checksum differs: " + sum + " vs " + str(j["sha256"])
	W_ = TB.W; HULLS = TB.HULLS; FACTIONS = TB.FACTIONS; MODULES = TB.MODULES; PERKS = TB.PERKS; RELICS = TB.RELICS; ADMIRALS = TB.ADMIRALS
	RANKS = TB.RANKS; RANK_XP = TB.RANK_XP; PATRONS = TB.PATRONS; BOONS = TB.BOONS; BOON_FX = TB.BOON_FX; BOON_D = TB.BOON_D; BOON_NEED = TB.BOON_NEED
	RARITY = TB.RARITY; ASPECTS = TB.ASPECTS; HEAT = TB.HEAT; HULL_VARIANTS = TB.HULL_VARIANTS; MASTERY_XP = TB.MASTERY_XP; MASTERY_PERKS = TB.MASTERY_PERKS
	FAVOUR_TIERS = TB.FAVOUR_TIERS; SECTOR_CONDS = TB.SECTOR_CONDS; SECTOR_POOL = TB.SECTOR_POOL; EVENTS = TB.EVENTS; CAPTAINS = TB.CAPTAINS
	SHIP_NAMES = TB.SHIP_NAMES; MORE_SHIP_NAMES = TB.MORE_SHIP_NAMES; FNAMES = TB.FNAMES; MOD_NEED = TB.MOD_NEED; MOD_NAMES = TB.MOD_NAMES
	RELIC_NAMES = TB.RELIC_NAMES; RUN_WORD = TB.RUN_WORD; ENCOUNTERS = TB.ENCOUNTERS; ENC_POOL = TB.ENC_POOL; ENC_SPECIAL = TB.ENC_SPECIAL
	REGIONS = TB.REGIONS; FAC_REGION = TB.FAC_REGION; REGION_BIOME = TB.REGION_BIOME; ROCK_KINDS = TB.ROCK_KINDS; DEEP_MAPS = TB.DEEP_MAPS
	FAC_MAP = TB.FAC_MAP; BEVENTS = TB.BEVENTS; KILL_CAUSES = TB.KILL_CAUSES; FAC_WNAMES = TB.FAC_WNAMES; FAC_WTRAIT = TB.FAC_WTRAIT; WTRAITS = TB.WTRAITS
	ABILITIES = TB.ABILITIES; ARC_NAME = TB.ARC_NAME; NODE_INFO = TB.NODE_INFO; NODE_MODS = TB.NODE_MODS; ARCHETYPES = TB.ARCHETYPES; SHAPES = TB.SHAPES
	REWARD_DEF = TB.REWARD_DEF; MAP_NAME = TB.MAP_NAME; WIN_TITLE = TB.WIN_TITLE; LEGACY = TB.LEGACY; CMD_TEXT = TB.CMD_TEXT; CAUSE_WORD = TB.CAUSE_WORD
	RUN_FACTIONS = TB.RUN_FACTIONS
	NEM_TRAITS = TB.NEM_TRAITS; NEM_PERSONA = TB.NEM_PERSONA; NEM_FAC = TB.NEM_FAC; NEM_ADAPT_FAC = TB.NEM_ADAPT_FAC; NEM_LINES = TB.NEM_LINES; NEM_BEAT_WORD = TB.NEM_BEAT_WORD; ARC_VARIANT = TB.ARC_VARIANT
	NEM_WEAK = TB.NEM_WEAK; NEM_ADAPT = TB.NEM_ADAPT; NEM_CLOCK = TB.NEM_CLOCK; FAC_VERBS = TB.FAC_VERBS; WING_PERKS = TB.WING_PERKS; WING_XP = TB.WING_XP
	EVENT_FALLBACK = TB.EVENT_FALLBACK; FAC_GATES = TB.FAC_GATES; CLASS_TRACK_MAX = TB.CLASS_TRACK_MAX; KIND_WORD = TB.KIND_WORD
	META = defaultMeta(); META["backfilled"] = 1; META["wonFix41"] = 1   # a fresh Godot profile has no browser history to back-fill
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
func jt(x) -> bool: # JS truthiness
	if x == null: return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING: return x != ""
	return true
func z0(x) -> Variant: return x if jt(x) else 0
func or_(a, b) -> Variant: return a if jt(a) else b
func rnd() -> float: return JSM.rnd()
func ri(a, b) -> float: return float(a) + floor(rnd() * (float(b) - float(a) + 1.0))
func pick(a: Array) -> Variant:
	var i = int(floor(rnd() * a.size()))
	return a[i] if i < a.size() else null
func shuffle(a: Array) -> Array:
	var i = a.size() - 1
	while i > 0:
		var j = int(floor(rnd() * (i + 1))); var t = a[i]; a[i] = a[j]; a[j] = t
		i -= 1
	return a
func clampv(v, a, b) -> float: return max(float(a), min(float(b), float(v)))
func jsround(x) -> float: return JSM.jsround(float(x))
func ssort(a: Array, cmp: Callable) -> Array: return JSM.ssort(a, cmp)
func keys(d: Dictionary) -> Array: return d.keys()
func clone(v) -> Variant: return v.duplicate(true) if (v is Dictionary or v is Array) else v
func now_ms() -> float: return 0.0 if fixed_clock else floor(Time.get_unix_time_from_system() * 1000.0)
func b36(n: int) -> String:
	if n == 0: return "0"
	var s = ""; var d = "0123456789abcdefghijklmnopqrstuvwxyz"
	while n > 0:
		s = d[n % 36] + s; n = n / 36
	return s
func new_id() -> String:
	var id = "x" + b36(int(now_ms())) + str(UID); UID += 1; return id
func roman(n) -> String:
	var r = ["", "I", "II", "III", "IV"]; var i = int(n)
	return r[i] if i >= 0 and i < r.size() else str(i)
func pct(n) -> String: return str(int(jsround(float(n) * 100.0))) + "%"
func numstr(n) -> String: # a JS number as the browser prints it in text
	var f = float(n)
	if f == floor(f) and absf(f) < 1e15: return str(int(f))
	return str(f)
func toast(msg: String) -> void: toasts.append(msg)
func tel(ev: String, d: Dictionary = {}) -> void:
	var e = {"t": now_ms(), "ev": ev, "sector": RUN["sector"] if RUN != null else 0}
	for k in d.keys(): e[k] = d[k]
	tel_log.append(e)
	if tel_log.size() > 600: tel_log = tel_log.slice(tel_log.size() - 600)
func unknown_id(_kind, _id) -> Variant: return null

# ======================= screens (the JS show/modal) =======================
func show_page(kind: String, data: Dictionary, acts: Array) -> void:
	modal_d = null; page = {"kind": kind, "data": data, "acts": acts}; changed.emit()
func show_modal(kind: String, data: Dictionary, acts: Array) -> void:
	modal_d = {"kind": kind, "data": data, "acts": acts}; changed.emit()
func close_modal() -> void:
	modal_d = null; changed.emit()
func screen_acts() -> Array: return modal_d["acts"] if modal_d != null else page["acts"]
func A(list: Array, act: String, arg = "", on: bool = true) -> void: list.append([act, str(arg), 1 if on else 0])

# ======================= data.js helpers =======================
func wName(fac, id) -> Variant:
	var fw = FAC_WNAMES.get(fac) if fac != null else null
	if fw != null and jt(fw.get(id)): return fw[id]
	if W_.has(id) and jt(W_[id].get("n")): return W_[id]["n"]
	return id
# B3 roster gates: what a faction cannot field (Corsairs and lance weapons). Returns the reason, or null.
func factionGate(fac, tpl) -> Variant:
	var G = FAC_GATES.get(fac) if fac != null else null; var h = HULLS.get(tpl) if tpl != null else null
	if G == null or h == null: return null
	if jt(G.get("noKind")):
		for e in h["w"]:
			if W_.has(e[0]) and G["noKind"].has(W_[e[0]].get("k")): return G["d"]
	return null
var _trait_rules = null   # a rules object with no battle loaded, used only for its weapon trait effects (one source: godot/rules/rules.gd)
func trait_fx(tk: String, w: Dictionary) -> void: # the weapon trait effects, from the rules through the battle API (no copy kept here)
	if _trait_rules == null: _trait_rules = BattleAPI.RulesScript.new()
	_trait_rules.trait_fx(tk, w)
func nameWeapons(fac, list: Array) -> Array:
	for w in list:
		w["n"] = wName(fac, w["id"])
		var ft = FAC_WTRAIT.get(fac) if fac != null else null
		var tk = ft.get(w["id"]) if ft != null else null
		if jt(tk) and WTRAITS.has(tk) and not jt(w.get("trait")):
			w["trait"] = tk; trait_fx(tk, w)
	return list

# ======================= core.js: persistence =======================
const SAVE_VERSION := 2
func defaultMeta() -> Dictionary:
	return {"v": SAVE_VERSION, "renown": 0, "unlocked": {}, "admirals": {"vex": true}, "fallen": [], "stats": {"runs": 0, "best": 0, "wins": 0}, "opts": {}, "tel": [], "updated": 0,
		"mastery": {}, "favour": {}, "variants": {}, "heatBest": {}}
# The browser's back-fill of old run logs (backfilled, wonFix41) is not carried: a Godot profile never had a browser log (R33: old saves are not migrated).
func migrateMeta(m: Dictionary) -> Dictionary:
	var d = defaultMeta()
	for k in d.keys():
		if k != "v" and m.get(k) == null: m[k] = d[k]
	if not (m["stats"] is Dictionary): m["stats"] = d["stats"]
	for k in d["stats"].keys():
		var v = m["stats"].get(k)
		if not (v is int or v is float): m["stats"][k] = z0(d["stats"][k])
	if not jt(m.get("v")) or float(m["v"]) < 2:
		m["opts"] = or_(m.get("opts"), {}); m["tel"] = or_(m.get("tel"), []); m["v"] = 2
	for k in ["mastery", "favour", "variants", "heatBest"]: m[k] = or_(m.get(k), {})
	if not jt(m.get("backfilled")): m["backfilled"] = 1
	if not jt(m.get("wonFix41")): m["wonFix41"] = 1
	return m
func migrateRun(r) -> Variant:
	if r != null and not jt(r.get("fac")): r["fac"] = "voidsworn"
	if r != null and (not jt(r.get("v")) or float(r["v"]) < 2):
		r["v"] = 2; r["stats"] = or_(r.get("stats"), {"battles": 0, "elites": 0, "bosses": 0, "kills": 0}); r["fallen"] = or_(r.get("fallen"), [])
	return normalizeRun(r)
func runDefaults() -> Dictionary:
	return {"fac": "voidsworn", "foes": null, "admiral": "vex", "credits": 0, "cpCap": 10, "sector": 1, "relics": [], "inventory": [], "fleet": [], "pos": null,
		"stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0, "lost": 0}, "t0": 0, "fallen": [], "ambush": false, "over": false, "boons": [], "patrons": [],
		"aspect": null, "flagUid": null, "heat": [], "mastery": 0, "ransoms": 0, "altFleet": false, "cmdOverride": null, "giftBoon": null, "reserve": [], "seenEvents": [],
		"regionsUsed": [], "condsUsed": [], "curNode": null, "reinf": 0, "flags": {}, "nem": null, "verbUsed": 0, "verbNext": null, "classTrack": {}, "boonRerolls": 0}
func normalizeRun(r) -> Variant:
	if not (r is Dictionary): return r
	var d = runDefaults()
	for k in d.keys():
		if r.get(k) == null: r[k] = d[k]
	for k in ["relics", "inventory", "fleet", "fallen", "boons", "patrons", "heat", "reserve", "seenEvents", "regionsUsed", "condsUsed"]:
		if not (r[k] is Array): r[k] = []
	if not (r["stats"] is Dictionary): r["stats"] = {}
	for k in d["stats"].keys():
		var v = r["stats"].get(k)
		if not (v is int or v is float): r["stats"][k] = 0
	var fl = []
	for s in r["fleet"]:
		if s is Dictionary: fl.append(s)
	r["fleet"] = fl
	for s in r["fleet"]:
		if not (s.get("mods") is Array): s["mods"] = []
		if not jt(s.get("mk")): s["mk"] = 1
		if not (s.get("cap") is Dictionary): s["cap"] = {"fac": r["fac"], "name": "Captain", "xp": 0, "rank": 0, "perks": [], "pending": 0}
		if not (s["cap"].get("perks") is Array): s["cap"]["perks"] = []
	return repairRunIds(r)
func _keep(arr: Array, T: Dictionary, kind: String, rep: Array, get_id: Callable = Callable()) -> Array:
	var out = []
	for x in arr:
		var id = get_id.call(x) if get_id.is_valid() else x
		if id != null and (id is String) and T.has(id): out.append(x)
		else: rep.append(kind + " " + str(id).substr(0, 40))
	return out
func _capFix(c, r) -> Dictionary:
	if not (c is Dictionary): return {"fac": r["fac"], "name": "Captain", "xp": 0, "rank": 0, "perks": [], "pending": 0}
	if not (c.get("name") is String) or String(c["name"]).strip_edges() == "": c["name"] = "Captain"
	if not (c.get("perks") is Array): c["perks"] = []
	c["perks"] = _keep(c["perks"], PERKS, "perk", [])
	if not (c.get("xp") is int or c.get("xp") is float): c["xp"] = 0
	if not (c.get("rank") is int or c.get("rank") is float): c["rank"] = 0
	if not (c.get("pending") is int or c.get("pending") is float): c["pending"] = 0
	if not jt(c.get("fac")): c["fac"] = r["fac"]
	return c
func repairRunIds(r) -> Variant:
	if not (r is Dictionary) or jt(r.get("none")): return r
	var rep = []
	if not FACTIONS.has(r["fac"]): rep.append("faction " + str(r["fac"])); r["fac"] = "voidsworn"
	if not ADMIRALS.has(r["admiral"]):
		var a = "vex"
		for k in ADMIRALS.keys():
			if or_(ADMIRALS[k].get("fac"), "voidsworn") == r["fac"]: a = k; break
		rep.append("admiral " + str(r["admiral"]).substr(0, 40)); r["admiral"] = a
	if r.get("foes") != null and not (r["foes"] is Array): r["foes"] = null
	if r.get("foes") is Array:
		for f in r["foes"]:
			if not FACTIONS.has(f): rep.append("sector foes"); r["foes"] = null; break
	r["relics"] = _keep(r["relics"], RELICS, "relic", rep); r["inventory"] = _keep(r["inventory"], MODULES, "refit", rep); r["heat"] = _keep(r["heat"], HEAT, "heat", rep)
	var bs = []
	for b in r["boons"]:
		if b is Dictionary: bs.append(b)
	r["boons"] = _keep(bs, BOONS, "boon", rep, func(b): return b.get("id"))
	r["patrons"] = _keep(r["patrons"], PATRONS, "patron", rep)
	if r.get("aspect") != null and not ASPECTS.has(r["aspect"]): rep.append("aspect " + str(r["aspect"])); r["aspect"] = null
	if r.get("giftBoon") != null and not BOONS.has(r["giftBoon"]): r["giftBoon"] = null
	var before = r["fleet"].size()
	r["fleet"] = _keep(r["fleet"], HULLS, "ship hull", rep, func(s): return s.get("tpl"))
	for s in r["fleet"]:
		s["cap"] = _capFix(s.get("cap"), r); s["mods"] = _keep(s["mods"], MODULES, "refit", rep)
		if not (s.get("name") is String): s["name"] = HULLS[s["tpl"]]["n"]
		if not (s.get("hp") is int or s.get("hp") is float) or not (float(s["hp"]) > 0): s["hp"] = 1
	var res = []
	for x in r["reserve"]:
		if x is Dictionary: x["cap"] = _capFix(x.get("cap"), r); res.append(x)
	r["reserve"] = res
	var fal = []
	for f in r["fallen"]:
		if f is Dictionary and f.get("name") is String: fal.append(f)
	r["fallen"] = fal
	if r.get("flagUid") != null:
		var ok = false
		for s in r["fleet"]:
			if s.get("uid") == r["flagUid"]: ok = true
		if not ok: r["flagUid"] = null
	if not (r.get("credits") is int or r.get("credits") is float) or is_nan(float(r["credits"])) or is_inf(float(r["credits"])): rep.append("credits"); r["credits"] = 0
	if r.get("reward") != null:
		var R = r["reward"]
		if not (R is Dictionary): r["reward"] = null
		else:
			if not (R.get("stage") in ["prize", "salvage", "pick", "relic", "promo"]): R["stage"] = "promo"
			var pz = []
			if R.get("prizes") is Array:
				for p in R["prizes"]:
					if p is Dictionary and HULLS.has(p.get("tpl")): pz.append(p)
			R["prizes"] = pz
			if not (R.get("rw") is Dictionary): R["rw"] = {}
			R["relics"] = _keep(R["relics"], RELICS, "relic", rep) if R.get("relics") is Array else []
			var wr = []
			if R.get("wrecks") is Array:
				for w in R["wrecks"]:
					if w is Dictionary and w.get("yield") is Dictionary: wr.append(w)
			R["wrecks"] = wr
			for w in R["wrecks"]:
				if w["yield"].get("mod") != null and not MODULES.has(w["yield"]["mod"]): w["yield"]["mod"] = null
				if not HULLS.has(w.get("tpl")): w["yield"]["tow"] = false
			if R.get("boonOffer") != null:
				var bad = not (R["boonOffer"] is Array)
				if not bad:
					for o in R["boonOffer"]:
						if not (o is Dictionary) or not BOONS.has(o.get("id")): bad = true
				if bad: R["boonOffer"] = null
			if R.get("modOffer") != null:
				var bad2 = not (R["modOffer"] is Array)
				if not bad2:
					for m in R["modOffer"]:
						if not MODULES.has(m): bad2 = true
				if bad2: R["modOffer"] = null
	if r["fleet"].size() < before: r["_shipsDropped"] = float(z0(r.get("_shipsDropped"))) + (before - r["fleet"].size())
	if rep.size() > 0:
		var all = (r["_repairs"] if r.get("_repairs") is Array else []) + rep
		r["_repairs"] = all.slice(max(0, all.size() - 20))
	return r
func saneMeta(m) -> bool:
	if not (m is Dictionary): return false
	for k in ["unlocked", "admirals", "stats", "opts", "mastery", "favour", "variants", "heatBest"]:
		if m.get(k) != null and not (m[k] is Dictionary): return false
	for k in ["tel", "fallen"]:
		if m.get(k) != null and not (m[k] is Array): return false
	return m.get("renown") == null or m["renown"] is int or m["renown"] is float
func saneRun(r) -> bool:
	return r == null or (r is Dictionary and (jt(r.get("none")) or (r.get("fleet") is Array and r.get("map") is Dictionary and r["map"].get("cols") is Array)))
func saneSave(o) -> bool:
	return o is Dictionary and (o.get("meta") == null or saneMeta(o["meta"])) and saneRun(o.get("run"))

# The Godot save (a fresh format; browser saves are not carried over, R33): one JSON file in user://, plus a backup one save behind.
# Godot's JSON number parser can land one unit in the last place off, so every non-integer number is written as "#d:" + its exact
# IEEE hex (the same trick as the data tables) and read back exactly.
func _enc(v):
	if v is Dictionary:
		var o = {}
		for k in v.keys():
			if v[k] != null and typeof(v[k]) != TYPE_CALLABLE: o[k] = _enc(v[k])
		return o
	if v is Array:
		var a = []
		for x in v: a.append(_enc(x))
		return a
	if v is float and (v != floor(v) or absf(v) >= 9007199254740992.0): return "#d:" + JSM.hex64(v)
	return v
func save_text() -> String:
	return JSON.stringify(_enc({"format": "voidsworn-godot-campaign", "v": 1, "uid": UID, "meta": META, "run": SAVED_RUN if SAVED_RUN != null else {"none": true}, "tel": tel_log}))
func persist_save(meta_only: bool = false) -> void:
	var now = now_ms()
	META["updated"] = now
	if not meta_only: META["runAt"] = now
	if not persist_on: return
	var data = save_text()
	# Atomic: the new save is written whole to a temp file, flushed and checked, then renamed over the old one, so a crash or a
	# power cut mid-write leaves either the old save or the new one, never half a file. The save before it becomes the .bak.
	if FileAccess.file_exists(save_path):
		var prev = FileAccess.get_file_as_string(save_path)
		if prev != "" and prev != data and _json_quiet(prev) != null:
			if not _write_atomic(save_path + ".bak", prev): push_warning("campaign: could not refresh the backup save")
	if not _write_atomic(save_path, data): toast("This computer could not save the game (is the disk full?).")
func _write_atomic(path: String, text: String) -> bool:
	var tmp = path + ".tmp"
	var f = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(text); f.flush()
	var ok = f.get_error() == OK and f.get_length() == text.to_utf8_buffer().size()
	f.close()
	if not ok:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp)); return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK
func _json_quiet(t: String) -> Variant:   # a damaged save is expected now and then: parse without an engine error
	var j = JSON.new()
	return j.data if j.parse(t) == OK else null
# Load a save text the way the browser loads its storage: a damaged save falls back to the backup; the half that is sound is kept.
func load_save_text(s: String, bak: String = "") -> void:
	var o = _dec(_json_quiet(s)) if s != "" else null
	if s != "" and not saneSave(o):
		var ob = _dec(_json_quiet(bak)) if bak != "" else null
		if saneSave(ob): o = ob
	if o is Dictionary and not saneSave(o):
		if not saneRun(o.get("run")): o["run"] = null
		if o.get("meta") != null and not saneMeta(o["meta"]): o["meta"] = null
	if o is Dictionary:
		if o.get("meta") is Dictionary:
			var m = defaultMeta()
			for k in o["meta"].keys(): m[k] = o["meta"][k]
			META = migrateMeta(m)
		var r = o.get("run")
		SAVED_RUN = migrateRun(r if (r is Dictionary and not jt(r.get("none"))) else null)
		if o.has("uid"): UID = max(UID, int(o["uid"]))
		if o.get("tel") is Array: tel_log = o["tel"]
func persist_load() -> void:
	var s = FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else ""
	var b = FileAccess.get_file_as_string(save_path + ".bak") if FileAccess.file_exists(save_path + ".bak") else ""
	load_save_text(s, b)

# ======================= core.js: run state =======================
func capName(fac) -> String:
	var C = CAPTAINS.get(fac) if CAPTAINS.has(fac) else CAPTAINS["voidsworn"]
	var used = {}
	if RUN != null and RUN.get("fleet") != null:
		for s in RUN["fleet"]: used[String(s["cap"]["name"]).split(" ")[0]] = true
	var n = ""
	for i in range(8):
		if jt(C.get("names")):
			n = String(pick(C["names"])) + ((" " + String(pick(C["epithets"]))) if jt(C.get("epithets")) else "")
		else:
			var f = String(pick(C["first"])); n = f + " " + String(pick(C["last"]))
		if not used.has(n.split(" ")[0]): break
	return n
func rankName(c) -> String:
	var fac = c.get("fac") if c is Dictionary and jt(c.get("fac")) else "voidsworn"
	var R = (CAPTAINS.get(fac) if CAPTAINS.has(fac) else CAPTAINS["voidsworn"])["ranks"]
	var rk = int(z0(c.get("rank"))) if c is Dictionary else 0
	return R[max(0, min(R.size() - 1, rk))]
func factionOfTpl(tpl) -> String:
	var h = HULLS.get(tpl)
	if h != null and jt(h.get("fac")): return h["fac"]
	for f in FACTIONS.keys():
		var F2 = FACTIONS[f]
		if or_(F2.get("roster"), []).has(tpl) or F2.get("boss") == tpl: return f
	return "voidsworn"
func shipName(fac) -> String:
	var used = {}
	if RUN != null:
		for s in RUN["fleet"]: used[s["name"]] = true
	var base: Array
	if not jt(fac) or fac == "voidsworn": base = SHIP_NAMES
	else: base = or_(FNAMES.get(fac), []) + or_(MORE_SHIP_NAMES.get(fac), [])
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
func _newShip(tpl, vet) -> Dictionary:
	var fac = factionOfTpl(tpl)
	var s = {"uid": new_id(), "tpl": tpl, "name": shipName(fac), "mk": 1, "hp": 0, "mods": [], "cap": newCaptain(vet, fac)}
	s["hp"] = derive(s)["maxHp"]
	return s
# campaign3d.js: wounded captains take the next hull (not during a battle, not a veteran hire)
func newShip(tpl, vet = false) -> Dictionary:
	var sh = _newShip(tpl, vet)
	if B == null and not jt(vet) and RUN != null and RUN.get("reserve") is Array and RUN["reserve"].size() > 0:
		var r = RUN["reserve"].pop_front(); var f = float(sh["hp"]) / max(1.0, float(derive(sh)["maxHp"]))
		sh["cap"] = r["cap"]; sh["hp"] = max(1.0, jsround(float(derive(sh)["maxHp"]) * f))
		toast(str(r["cap"]["name"]) + " recovers and takes command of the " + str(sh["name"]) + ".")
	return sh
func sumFx(list: Array) -> Dictionary:
	var o = {}
	for fx in list:
		if not jt(fx): continue
		for k in fx.keys(): o[k] = float(z0(o.get(k))) + float(fx[k])
	return o
func fleetFxList() -> Array:
	var l = []
	if RUN != null:
		for r in RUN["relics"]:
			if RELICS.has(r) and jt(RELICS[r].get("fx")): l.append(RELICS[r]["fx"])
		if ADMIRALS.has(RUN["admiral"]): l.append(ADMIRALS[RUN["admiral"]].get("fx"))
		for b in or_(RUN.get("boons"), []):
			if BOONS.has(b["id"]): l.append(BOON_FX[b["id"]][int(z0(b.get("r")))])
	return l
func ensurePatrons() -> void:
	if RUN == null: return
	if not jt(RUN.get("patrons")) or RUN["patrons"].size() == 0: RUN["patrons"] = shuffle(PATRONS.keys()).slice(0, 4)
	if not jt(RUN.get("boons")): RUN["boons"] = []
func hasBoon(id) -> bool:
	if RUN == null or RUN.get("boons") == null: return false
	for b in RUN["boons"]:
		if b["id"] == id: return true
	return false
func boonPatrons() -> Dictionary:
	var s = {}
	if RUN != null:
		for b in or_(RUN.get("boons"), []):
			if BOONS.has(b["id"]) and jt(BOONS[b["id"]].get("p")): s[BOONS[b["id"]]["p"]] = true
	return s
func rollRarity(minR, s, p = null) -> int:
	var ft = favourTier(p) if jt(p) else 0
	var x = rnd(); var sv = float(or_(s, 1))
	var rare = 0.24 + 0.06 * (sv - 1.0) + (0.12 if ft >= 1 else 0.0)
	var epic = 0.06 + 0.03 * (sv - 1.0) + (0.03 if ft >= 1 else 0.0)
	var r = 2 if x < epic else (1 if x < epic + rare else 0)
	if ft >= 3: r = max(r, 1)
	return max(int(z0(minR)), r)
func fleetKit() -> Dictionary:
	var k = {}
	for sh in (RUN["fleet"] if RUN != null else []):
		var d = derive(sh)
		for w in d["weapons"]:
			if w["k"] == "torp": k["torp"] = 1
			if w["k"] == "lance": k["lance"] = 1
			if w["k"] == "battery": k["batt"] = 1
			if w["k"] == "flak": k["flak"] = 1
			if w["arc"] == "P" or w["arc"] == "S": k["broad"] = 1
			if w["arc"] == "P" or w["arc"] == "S" or w["k"] == "battery": k["still"] = 1
		if float(z0(HULLS[sh["tpl"]].get("sh"))) > 0: k["shields"] = 1
		if jt(HULLS[sh["tpl"]].get("hangar")): k["carrier"] = 1
		if jt(d["hangar"]): k["sq"] = 1
	return k
func boonUseful(id, kit: Dictionary) -> bool:
	var n = BOON_NEED.get(id)
	return not jt(n) or jt(kit.get(n))
func rollBoonOffer(p, minR) -> Array:
	ensurePatrons()
	var s = RUN["sector"] if RUN != null else 1
	var have = boonPatrons(); var kit = fleetKit()
	var pool = []
	for id in BOONS.keys():
		if BOONS[id].get("p") == p and not jt(BOONS[id].get("leg")) and not hasBoon(id): pool.append(id)
	pool = shuffle(pool)
	var junk = []; var good = []
	for id in pool:
		if boonUseful(id, kit): good.append(id)
		else: junk.append(id)
	pool = good
	var duos = []
	for id in BOONS.keys():
		var b = BOONS[id]
		if not jt(b.get("duo")) or hasBoon(id) or not boonUseful(id, kit) or not b["duo"].has(p): continue
		var all_ok = true; var some = false
		for q in b["duo"]:
			if not (have.has(q) or q == p): all_ok = false
			if q != p and have.has(q): some = true
		if all_ok and some: duos.append(id)
	var out = []
	for id in pool.slice(0, 3): out.append({"id": id, "r": rollRarity(minR, s, p)})
	if duos.size() > 0 and (out.size() < 3 or rnd() < 0.45):
		var d = {"id": pick(duos), "r": 0}
		if out.size() >= 3: out[2] = d
		else: out.append(d)
	if out.size() < 3:
		var extra0 = []
		for id in BOONS.keys():
			var bp = BOONS[id].get("p")
			if not jt(bp) or jt(BOONS[id].get("leg")) or bp == p or not RUN["patrons"].has(bp) or hasBoon(id) or not boonUseful(id, kit): continue
			var dup = false
			for o in out:
				if o["id"] == id: dup = true
			if not dup: extra0.append(id)
		var extra = shuffle(extra0)
		while out.size() < 3 and extra.size() > 0: out.append({"id": extra.pop_back(), "r": rollRarity(minR, s)})
		while out.size() < 3 and junk.size() > 0: out.append({"id": junk.pop_back(), "r": rollRarity(minR, s)})
	var L = legendaryFor(p, minR)   # B4 step 3: the patron's legendary, at elite and flagship rewards, once you hold two of its boons
	if L != null:
		if out.size() >= 3: out[2] = {"id": L, "r": 3}
		else: out.append({"id": L, "r": 3})
	return out
func legendaryFor(p, minR) -> Variant:
	if not (float(z0(minR)) >= 1): return null
	var L = null
	for id in BOONS.keys():
		if jt(BOONS[id].get("leg")) and BOONS[id].get("p") == p:
			L = id; break
	if L == null or hasBoon(L) or not boonUseful(L, fleetKit()): return null
	var n = 0
	for b in or_(RUN.get("boons"), []):
		if BOONS.has(b["id"]) and BOONS[b["id"]].get("p") == p and not jt(BOONS[b["id"]].get("leg")): n += 1
	return L if n >= 2 else null
func rollNodeReward(type) -> Dictionary:
	ensurePatrons()
	var p = pick(RUN["patrons"])
	if type == "elite" or type == "boss": return {"k": "boon", "p": p, "min": 1}
	var x = rnd()
	if x < 0.62: return {"k": "boon", "p": p}
	if x < 0.78: return {"k": "mod"}
	if x < 0.9: return {"k": "cred"}
	return {"k": "repair"}
func flagshipOf() -> Variant:
	if RUN == null or RUN.get("fleet") == null: return null
	for s in RUN["fleet"]:
		if s["uid"] == RUN.get("flagUid"): return s
	return null
func shipValue(tpl) -> float:
	var H = HULLS.get(tpl)
	if H != null and (H.get("cost") is int or H.get("cost") is float): return float(H["cost"])
	return 40.0 * float(or_(H.get("cp") if H != null else null, 1))
func prizeScrap(tpl) -> float: return jsround(shipValue(tpl) * 0.35)
func ensureFlagship() -> Variant:
	if RUN == null or RUN.get("fleet") == null or RUN["fleet"].size() == 0: return null
	if flagshipOf() == null:
		var f = ssort(RUN["fleet"].duplicate(), func(a, b): return or_(float(or_(HULLS[b["tpl"]].get("cp"), 1)) - float(or_(HULLS[a["tpl"]].get("cp"), 1)), float(derive(b)["maxHp"]) - float(derive(a)["maxHp"])))[0]
		RUN["flagUid"] = f["uid"]
		return f
	return flagshipOf()
func runFx() -> Dictionary:
	var o = {}
	if RUN != null:
		for r in RUN["relics"]:
			var x = RELICS[r].get("run") if RELICS.has(r) else null
			if jt(x):
				for k in x.keys(): o[k] = float(z0(o.get(k))) + float(x[k])
	if RUN != null and jt(META["unlocked"].get("salvagers")): o["credPct"] = float(z0(o.get("credPct"))) + 0.2
	return o
func mkWeapon(id, arc, fx) -> Dictionary:
	var b: Dictionary = W_[id]
	var w = {"id": id, "arc": arc}
	for k in b.keys(): w[k] = b[k]
	w["cd"] = z0(b.get("cd"))
	if b.get("k") == "battery" and jt(fx.get("battShots")): w["shots"] = w["shots"] + fx["battShots"]
	if b.get("k") == "flak" and jt(fx.get("flakPlus")):
		w["shots"] = w["shots"] + 2 * fx["flakPlus"]; w["r"] = w["r"] + fx["flakPlus"]; w["opt"] = w["opt"] + fx["flakPlus"]
	if b.get("k") == "torp" and jt(fx.get("torpCd")): w["cd"] = max(1, w["cd"] - fx["torpCd"])
	if arc == "F" and jt(fx.get("prowRange")):
		w["r"] = w["r"] + fx["prowRange"]; w["opt"] = w["opt"] + fx["prowRange"]
	if b.get("k") == "lance" and jt(fx.get("lanceRange")):   # Long Silence, Epic
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
	var mk = float(ship["mk"]) if jt(ship.get("mk")) else 1.0
	var mm = 1.0 + 0.2 * (mk - 1.0); var tr = classTrack(t.get("cls"))   # B4 step 3: the class refit track adds 6% hull and 6% damage per level
	var maxHp = jsround(float(t["hp"]) * mm * (1.0 + float(z0(fx.get("hpPct"))) + 0.06 * tr))
	var ws = []
	for e in t["w"]: ws.append(mkWeapon(e[0], e[1], fx))
	return {
		"maxHp": maxHp, "shMax": jsround(float(t["sh"]) * mm * (1.0 + float(z0(fx.get("shPct"))))), "regen": jsround(float(t["rg"]) * mm * (1.0 + float(z0(fx.get("regenPct"))))),
		"armor": min(0.6, float(t["ar"]) + float(z0(fx.get("armor")))), "speed": float(t["sp"]) + float(z0(fx.get("speed"))), "turns": float(t["tn"]) + float(z0(fx.get("turns"))), "ev": float(t["ev"]) + float(z0(fx.get("ev"))),
		"aim": z0(fx.get("aim")), "crit": z0(fx.get("crit")), "dmg": 1.0 + 0.15 * (mk - 1.0) + float(z0(fx.get("dmgPct"))) + 0.06 * tr, "fx": fx,
		"hangar": (float(t["hangar"]) + float(z0(fx.get("hangar"))) + float(z0(fx.get("hive")))) if jt(t.get("hangar")) else z0(fx.get("hive")),
		"hullRegen": float(z0(fx.get("hullRegen"))) + jsround(float(z0(fx.get("hullRegenPct"))) * maxHp) + jsround(float(z0(t.get("regen"))) * mm),
		"weapons": nameWeapons(t.get("fac"), ws),
	}
# B4 step 3: shared refit tracks per class, bought at shipyards (RUN.classTrack[cls] 0..3)
func classTrack(cls) -> float:
	if RUN == null or not (RUN.get("classTrack") is Dictionary) or cls == null: return 0.0
	return float(z0(RUN["classTrack"].get(cls)))
func classTrackCost(cls) -> float: return jsround((60.0 + 50.0 * classTrack(cls)) * priceMult())
func _track_up(cls) -> void:
	if not (RUN.get("classTrack") is Dictionary): RUN["classTrack"] = {}
	RUN["classTrack"][cls] = classTrack(cls) + 1
func buyClassTrack(cls) -> bool:
	if RUN == null or classTrack(cls) >= float(CLASS_TRACK_MAX): return false
	var c = classTrackCost(cls)
	if float(RUN["credits"]) < c: return false
	RUN["credits"] = float(RUN["credits"]) - c; changeFleet(_track_up.bind(cls)); return true
func changeShip(ship: Dictionary, fn: Callable) -> void:
	var before = derive(ship)["maxHp"]; fn.call(ship); var after = derive(ship)["maxHp"]
	ship["hp"] = clampv(float(ship["hp"]) + (after - before), 1, after)
func changeFleet(fn: Callable) -> void:
	var b = []
	for s in RUN["fleet"]: b.append(derive(s)["maxHp"])
	fn.call()
	for i in range(RUN["fleet"].size()):
		var s = RUN["fleet"][i]; var a = derive(s)["maxHp"]
		s["hp"] = clampv(float(s["hp"]) + (a - b[i]), 1, a)
func fleetCP() -> float:
	var t = 0.0
	for s in RUN["fleet"]: t += float(HULLS[s["tpl"]]["cp"])
	return t
func priceMult() -> float:
	var c = sectorCond()
	return (0.85 if jt(META["unlocked"].get("wrights")) else 1.0) * (1.25 if heatOn("h_coffers") else 1.0) * float(or_(c.get("price") if c != null else null, 1))
func heatOn(k) -> bool: return RUN != null and RUN.get("heat") is Array and RUN["heat"].has(k)
func repairMult() -> float:
	var c = sectorCond()
	return (0.5 if heatOn("h_repair") else 1.0) * float(or_(c.get("repair") if c != null else null, 1))
func mkCost(s) -> float: return jsround((40.0 * float(HULLS[s["tpl"]]["cp"]) * float(s["mk"]) + 30.0) * priceMult())
func addXp(ship, n) -> void:
	var c = ship["cap"]; c["xp"] = float(c["xp"]) + jsround(float(n) * (1.0 + float(z0(runFx().get("xpPct")))))
	while float(c["rank"]) < RANKS.size() - 1 and float(c["xp"]) >= float(RANK_XP[int(c["rank"]) + 1]):
		c["rank"] = float(c["rank"]) + 1; c["pending"] = float(c["pending"]) + 1
func modulePool() -> Array:
	var kit = fleetKit(); var all = MODULES.keys(); var ok = []
	for m in all:
		if not jt(MOD_NEED.get(m)) or jt(kit.get(MOD_NEED[m])): ok.append(m)
	return ok if ok.size() >= 3 else all
func randomModule() -> Variant: return pick(modulePool())
func modName(m) -> String:
	var f = RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn"
	if MOD_NAMES.has(f) and jt(MOD_NAMES[f].get(m)): return MOD_NAMES[f][m]
	return MODULES[m]["n"]
func relicName(r) -> String:
	var f = RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn"
	if RELIC_NAMES.has(f) and jt(RELIC_NAMES[f].get(r)): return RELIC_NAMES[f][r]
	return RELICS[r]["n"]
func runWord(fac = null) -> String:
	var f = fac if jt(fac) else (RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn")
	return or_(RUN_WORD.get(f), "run")
func relicUseful(r) -> bool: return not (r == "lattice" and not jt(fleetKit().get("shields")))
func randomRelic() -> Variant:
	var pool = []
	for r in RELICS.keys():
		if not RUN["relics"].has(r) and relicUseful(r): pool.append(r)
	return pick(pool) if pool.size() > 0 else null
func equivHull(tpl, fac) -> Variant:
	if not jt(fac) or fac == "voidsworn" or HULLS[tpl].get("fac") == fac: return tpl
	var T = HULLS[tpl]; var ros = []
	for h in (FACTIONS[fac].get("roster") if FACTIONS.has(fac) and FACTIONS[fac].get("roster") != null else []):
		if HULLS.has(h) and not jt(HULLS[h].get("boss")): ros.append(h)
	if ros.size() == 0: return tpl
	var pool = ros
	if T.get("ab") == "launch":
		pool = []
		for h in ros:
			if HULLS[h].get("ab") == "launch": pool.append(h)
	if pool.size() == 0: pool = ros
	var a = pool[0]
	for h in pool:
		var dh = absf(float(HULLS[h]["cp"]) - float(T["cp"])); var da = absf(float(HULLS[a]["cp"]) - float(T["cp"]))
		if dh < da or (dh == da and float(HULLS[h]["cp"]) > float(HULLS[a]["cp"])): a = h
	return a
func nodeFaction(n) -> String:
	var main = RUN["map"]["fac"]
	if not jt(RUN.get("foes")) or n["type"] != "battle": return main
	var h = 0
	for ch in (String(n["id"]) + numstr(RUN["sector"])): h = (h * 31 + ch.unicode_at(0)) & 0xFFFFFFFF
	var hs = h if h < 0x80000000 else h - 0x100000000   # JS h>>3 is a signed 32-bit shift
	return RUN["foes"][3 + (hs >> 3) % 2] if h % 5 == 0 else main

# ---------------- battle.js helpers the campaign uses ----------------
func rollBattleEvent(cfg, force) -> Variant:
	if cfg == null or cfg.get("kind") == "boss": return null
	if not jt(force) and rnd() > 0.45: return null
	var k = force if (jt(force) and BEVENTS.has(force)) else pick(BEVENTS.keys())
	return {"k": k, "warnR": 2, "r": ri(3, 4)}
func cheapHull(fac) -> Variant:
	var F = FACTIONS.get(fac) if FACTIONS.has(fac) else FACTIONS["voidsworn"]
	var l = []
	for id in F["roster"]:
		if HULLS.has(id) and not jt(HULLS[id].get("boss")) and HULLS[id].get("ab") != "launch": l.append(id)
	l = ssort(l, func(a, b): return or_(float(or_(HULLS[a].get("cp"), 1)) - float(or_(HULLS[b].get("cp"), 1)), float(HULLS[a]["hp"]) - float(HULLS[b]["hp"])))
	return l[0] if l.size() > 0 else F["roster"][0]
func pickRegion(fac) -> Variant:
	var used = RUN["regionsUsed"] if RUN != null and RUN.get("regionsUsed") != null else []
	var base = FAC_REGION.get(fac) if FAC_REGION.has(fac) else REGIONS.keys()
	var pool = []
	for k in base:
		if not used.has(k): pool.append(k)
	var r = pick(pool if pool.size() > 0 else (FAC_REGION.get(fac) if FAC_REGION.has(fac) else ["frontier"]))
	if RUN != null: RUN["regionsUsed"] = used + [r]
	return r
func regionMap(reg, c, COLS) -> Variant:
	if not REGIONS.has(reg): return null
	var R = REGIONS[reg]["route"]
	return R[min(R.size() - 1, int(floor(float(c) / float(or_(COLS, 7)) * R.size())))]
func rollBiome(region) -> Dictionary:
	var R = REGION_BIOME.get(region) if region != null and REGION_BIOME.has(region) else {"rock": ROCK_KINDS.keys(), "planet": [0, 1, 2, 3, 4, 5, 6, 7], "station": ["ring", "rig", "spire"]}
	var rock = pick(R["rock"]); var planet = pick(R["planet"]); var station = pick(R["station"])
	return {"rock": rock, "planet": planet, "station": station}
func fitEncounter(n) -> void:
	if n == null or not jt(n.get("enc")): return
	if n["enc"] == "defend": n["map"] = "station"
	if n.get("shape") == "deadstar" and jt(n.get("map")) and not DEEP_MAPS.has(n["map"]):
		var sh = []
		for x in ENCOUNTERS[n["enc"]]["shapes"]:
			if x != "deadstar": sh.append(x)
		n["shape"] = pick(sh if sh.size() > 0 else ["open"])
func bossEncounter() -> Dictionary:
	var enc = pick(["rout", "rout", "ambush", "flagship"]); var sh = []
	for s in ["ring", "open", "hourglass"]:
		if ENCOUNTERS[enc]["shapes"].has(s): sh.append(s)
	return {"enc": enc, "shape": pick(sh if sh.size() > 0 else ["open"])}
func rollEncounter(kind, col) -> Dictionary:
	if kind == "boss": return bossEncounter()
	var enc = "rout" if float(col) == 0 else pick(ENC_POOL)
	return {"enc": enc, "shape": pick(ENCOUNTERS[enc]["shapes"])}
func effArch(arch, fac) -> Variant:
	if arch == "carrier":
		var F = FACTIONS.get(fac)
		var has_car = false
		if F != null:
			for id in F["roster"]:
				if HULLS.has(id) and HULLS[id].get("ab") == "launch": has_car = true
		if not has_car: return "heavy"
	return arch if jt(arch) else null

# ---------------- sector map generation ----------------
func _is(n, types: Array) -> bool: return types.has(n["type"])
func genSector(s: int) -> Dictionary:
	var fac = RUN["foes"][s - 1] if RUN != null and RUN.get("foes") is Array and s - 1 < RUN["foes"].size() and jt(RUN["foes"][s - 1]) else pick(SECTOR_POOL[s - 1])
	var cols = []; var COLS = 7
	for c in range(COLS):
		var n = 1 if (c == 0 or c == COLS - 1) else int(ri(2, 4))
		var col = []
		for i in range(n):
			var type
			if c == 0: type = "shipyard" if s >= 2 else "battle"
			elif c == COLS - 1: type = "boss"
			elif c == COLS - 2: type = pick(["shipyard", "drydock", "field"])
			else:
				var x = rnd()
				type = "battle" if x < 0.48 else ("elite" if x < 0.61 else ("event" if x < 0.78 else ("shipyard" if x < 0.9 else "drydock")))
				if c == 1 and (type == "elite" or type == "drydock"): type = "battle"
			col.append({"id": str(c) + "-" + str(i), "col": c, "row": i, "n": n, "y": (float(i) + 0.5) / float(n), "type": type, "done": false})
		cols.append(col)
	var c4 = cols[COLS - 3]
	if not c4.any(func(n): return n["type"] == "elite"):
		var b = null
		for n in c4:
			if n["type"] == "battle": b = n; break
		if b == null:
			for n in c4:
				if n["type"] == "event": b = n; break
		if b != null: b["type"] = "elite"
	if not cols[3].any(func(n): return n["type"] == "shipyard"):
		var py = pick(cols[3]); py["type"] = "shipyard"
	if not cols[COLS - 2].any(func(n): return n["type"] == "drydock" or n["type"] == "shipyard"): cols[COLS - 2][0]["type"] = "drydock"
	for c2 in range(1, COLS - 2):
		var col = cols[c2]
		for n in col:
			if n["type"] == "drydock": n["type"] = "battle" if rnd() < 0.5 else "event"
		var rests = col.filter(func(n): return n["type"] == "shipyard" or n["type"] == "drydock")
		while rests.size() > 1:
			var rp = rests.pop_back(); rp["type"] = "battle"; rests = col.filter(func(n): return n["type"] == "shipyard" or n["type"] == "drydock")
		if not col.any(func(n): return n["type"] == "battle" or n["type"] == "elite"):
			var cand = col.filter(func(n): return n["type"] != "shipyard" and n["type"] != "drydock")
			var nb = pick(cand) if cand.size() > 0 else col[col.size() - 1]
			nb["type"] = "battle"
	if true:
		var c3 = int(ri(2, COLS - 3)); var col = cols[c3]
		var fights = col.filter(func(n): return n["type"] == "battle" or n["type"] == "elite")
		var cand = col.filter(func(n): return n["type"] == "event" or (n["type"] == "battle" and fights.size() > 1))
		if cand.size() > 0:
			var nf = pick(cand); nf["type"] = "field"
	for col in cols:
		for n in col:
			if n["type"] == "battle" or n["type"] == "elite": n.merge(rollEncounter(n["type"], n["col"]), true)
	if RUN != null:
		for col in cols:
			for n in col:
				if _is(n, ["battle", "elite", "boss"]): n["rw"] = rollNodeReward(n["type"])
	for c2 in range(1, COLS - 1):
		var f = cols[c2].filter(func(n): return n["type"] == "battle" or n["type"] == "elite")
		if f.size() > 0 and not f.any(func(n): return ENC_SPECIAL.has(n["enc"])):
			var n = pick(f); var e = pick(ENC_SPECIAL); n["enc"] = e; n["shape"] = pick(ENCOUNTERS[e]["shapes"])
		for i in range(1, f.size()):
			if f[i]["enc"] == f[i - 1]["enc"]:
				var cur = f[i]["enc"]
				var e2 = pick(ENC_POOL.filter(func(x): return x != cur)); f[i]["enc"] = e2; f[i]["shape"] = pick(ENCOUNTERS[e2]["shapes"])
	var edges = []
	for c in range(COLS - 1):
		var Acol = cols[c]; var Bcol = cols[c + 1]
		for a in Acol:
			var ay = float(a["y"])
			var near = ssort(Bcol.duplicate(), func(x, y): return absf(float(x["y"]) - ay) - absf(float(y["y"]) - ay))
			edges.append([a["id"], near[0]["id"]])
			if near.size() > 1 and rnd() < 0.45 and absf(float(near[1]["y"]) - ay) < 0.5: edges.append([a["id"], near[1]["id"]])
		for b in Bcol:
			if not edges.any(func(e): return e[1] == b["id"]):
				var by = float(b["y"])
				var near2 = ssort(Acol.duplicate(), func(x, y): return absf(float(x["y"]) - by) - absf(float(y["y"]) - by))[0]
				edges.append([near2["id"], b["id"]])
	for col in cols:
		for n in col:
			if n["type"] == "battle" or n["type"] == "elite":
				var x = rnd(); n["arch"] = "swarm" if x < 0.25 else ("heavy" if x < 0.47 else ("carrier" if x < 0.62 else null))
				var y = rnd(); n["mod"] = "bounty" if (float(n["col"]) >= 2 and y < 0.14) else ("veteran" if (float(n["col"]) >= 2 and n["type"] == "battle" and y < 0.26) else null)
	var used = RUN["condsUsed"] if RUN != null and RUN.get("condsUsed") != null else []
	var pool = SECTOR_CONDS.keys().filter(func(k): return not used.has(k))
	var cond = pick(pool if pool.size() > 0 else SECTOR_CONDS.keys())
	if RUN != null: RUN["condsUsed"] = used + [cond]
	var region = pickRegion(fac)
	for col in cols:
		for n in col:
			n["map"] = regionMap(region, n["col"], COLS); fitEncounter(n)
	var biome = rollBiome(region)
	return {"fac": fac, "cols": cols, "edges": edges, "cond": cond, "region": region, "biome": biome}
func sectorCond() -> Variant:
	if RUN == null or RUN.get("map") == null: return null
	var k = RUN["map"].get("cond")
	return SECTOR_CONDS[k] if jt(k) and SECTOR_CONDS.has(k) else null

# ---------------- progression helpers ----------------
func masteryXP(id) -> float: return float(z0(META["mastery"].get(id))) if META.get("mastery") != null else 0.0
func masteryLevel(id) -> int:
	var x = masteryXP(id); var l = 0
	for i in range(1, MASTERY_XP.size()):
		if x >= float(MASTERY_XP[i]): l = i
	return l
func favourOf(p) -> float: return float(z0(META["favour"].get(p))) if META.get("favour") != null else 0.0
func favourTier(p) -> int:
	var f = favourOf(p); var t = 0
	for i in range(FAVOUR_TIERS.size()):
		if f >= float(FAVOUR_TIERS[i]["at"]): t = i
	return t
func heatLevel(list) -> float:
	var t = 0.0
	for k in or_(list, []): t += float(z0(HEAT[k].get("w"))) if HEAT.has(k) else 0.0
	return t
func _cp(t) -> float: return float(or_(HULLS[t].get("cp"), 1))
func _car(t) -> bool: return HULLS[t].get("ab") == "launch"
func _sum(l: Array) -> float:
	var s = 0.0
	for t in l: s += _cp(t)
	return s
func _key(l: Array) -> String:
	var c = l.duplicate(); c.sort(); return ",".join(PackedStringArray(c))
func _by(ros: Array, c: float) -> Variant:
	for h in ros:
		if not _car(h) and _cp(h) == c: return h
	return null
func altFleetPlan(admiralId, fac) -> Dictionary:
	var base = []
	for t in ADMIRALS[admiralId]["start"]: base.append(equivHull(t, fac))
	var ros = FACTIONS[fac]["roster"].filter(func(h): return HULLS.has(h) and not jt(HULLS[h].get("boss")) and not jt(HULLS[h].get("unique")))
	var need = base.filter(func(t): return _car(t)).size(); var total = _sum(base)
	var nc = ssort(base.filter(func(t): return not _car(t)), func(x, y): return _cp(y) - _cp(x))
	var splits = []; var merges = []
	for L in nc:
		var c = _cp(L)
		var x = ceil(c / 2.0)
		while x < c:
			var Ah = _by(ros, x); var Bh = _by(ros, c - x)
			if Ah != null and Bh != null:
				var out = base.duplicate(); var ix = out.find(L); out.remove_at(ix); out.insert(ix, Bh); out.insert(ix, Ah); splits.append(out)
			x += 1.0
	var sm = nc.duplicate(); sm.reverse()
	for i in range(sm.size() - 1):
		var H = _by(ros, _cp(sm[i]) + _cp(sm[i + 1]))
		if H != null:
			var out2 = base.duplicate(); out2.remove_at(out2.find(sm[i])); var j = out2.find(sm[i + 1]); out2.remove_at(j); out2.insert(j, H); merges.append(out2)
	var big = nc.size() > 0 and _cp(nc[0]) >= 4
	var cands = (splits + merges) if big else (merges + splits)
	for o in cands:
		if _sum(o) == total and o.filter(func(t): return _car(t)).size() >= need and _key(o) != _key(base): return {"fleet": o, "mod": null}
	return {"fleet": base, "mod": "hangar" if (need > 0 and MODULES.has("hangar")) else null}
func altCommand(admiralId) -> Variant:
	var a = ADMIRALS[admiralId]; var fac = or_(a.get("fac"), "voidsworn")
	var ids = ADMIRALS.keys().filter(func(k): return or_(ADMIRALS[k].get("fac"), "voidsworn") == fac)
	var i = ids.find(admiralId)
	for k in range(1, ids.size()):
		var c = ADMIRALS[ids[(i + k) % ids.size()]].get("cmd")
		if jt(c) and jt(a.get("cmd")) and c["id"] != a["cmd"]["id"]: return c
	return null
func newRun(admiralId, fac, opt = {}) -> void:
	var adm = ADMIRALS[admiralId]
	fac = fac if RUN_FACTIONS.has(fac) else "voidsworn"
	var foes = shuffle(RUN_FACTIONS.filter(func(f): return f != fac))
	RUN = {"fac": fac, "foes": foes, "admiral": admiralId, "credits": 120, "cpCap": 10, "sector": 1, "relics": [], "inventory": [], "fleet": [], "pos": null,
		"stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0, "lost": 0}, "t0": now_ms(), "fallen": [], "ambush": false, "over": false, "boons": []}
	RUN["patrons"] = shuffle(PATRONS.keys()).slice(0, 4); RUN["aspect"] = null; RUN["flagUid"] = null
	if jt(META["unlocked"].get("chest1")): RUN["credits"] += 75
	if jt(META["unlocked"].get("chest2")): RUN["credits"] += 75
	if jt(META["unlocked"].get("chest3")): RUN["credits"] += 75
	if jt(META["unlocked"].get("cmd1")): RUN["cpCap"] += 2
	if jt(META["unlocked"].get("cmd2")): RUN["cpCap"] += 2
	if jt(META["unlocked"].get("founder")):
		var r = randomRelic()
		if r != null: RUN["relics"].append(r)
	RUN["heat"] = or_(opt.get("heat"), []).filter(func(k): return HEAT.has(k)); RUN["mastery"] = masteryLevel(admiralId)
	var plan = altFleetPlan(admiralId, fac) if (jt(opt.get("alt")) and RUN["mastery"] >= 1) else null
	var start = []
	if plan != null: start = plan["fleet"]
	else:
		for t in adm["start"]: start.append(equivHull(t, fac))
	RUN["altFleet"] = plan != null
	for t in start: RUN["fleet"].append(newShip(t, jt(META["unlocked"].get("vets"))))
	if plan != null and plan["mod"] != null:
		var c = null
		for s in RUN["fleet"]:
			if HULLS[s["tpl"]].get("ab") == "launch": c = s; break
		if c != null: c["mods"].append(plan["mod"]); c["hp"] = derive(c)["maxHp"]
	if jt(opt.get("cmdAlt")) and RUN["mastery"] >= 3:
		var c2 = altCommand(admiralId)
		if c2 != null: RUN["cmdOverride"] = c2
	RUN["cpCap"] = max(float(RUN["cpCap"]), fleetCP() + 3); ensureFlagship()
	if RUN["mastery"] >= 4:
		var f = flagshipOf()
		if f != null:
			f["mk"] = max(float(or_(f.get("mk"), 1)), 2); f["cap"]["rank"] = max(float(f["cap"]["rank"]), 2); f["cap"]["xp"] = max(float(f["cap"]["xp"]), float(RANK_XP[2]))
			if f["cap"]["perks"].size() < 2: f["cap"]["perks"].append(pick(PERKS.keys().filter(func(p): return not f["cap"]["perks"].has(p))))
			f["hp"] = derive(f)["maxHp"]
	var dev = null
	for p in RUN["patrons"]:
		if favourTier(p) >= 2: dev = p; break
	if dev != null:
		var pool = BOONS.keys().filter(func(id): return BOONS[id].get("p") == dev and not jt(BOONS[id].get("leg")) and boonUseful(id, fleetKit()))
		if pool.size() > 0:
			var id = pick(pool); RUN["boons"].append({"id": id, "r": 1 if favourTier(dev) >= 3 else 0}); RUN["giftBoon"] = id
	RUN["map"] = genSector(1)
	RUN["flags"] = {}; RUN["nem"] = newNemesis()   # B4: one named enemy commander per run
	META["stats"]["runs"] = float(META["stats"]["runs"]) + 1
	saveRun()
func saveRun() -> void:
	SAVED_RUN = clone(RUN) if (RUN != null and not jt(RUN.get("over"))) else null
	persist_save()
func availableNodes() -> Array:
	var m = RUN["map"]
	if not jt(RUN.get("pos")):
		var o = []
		for n in m["cols"][0]: o.append(n["id"])
		return o
	var out = []
	for e in m["edges"]:
		if e[0] == RUN["pos"]: out.append(e[1])
	return out
func findNode(id) -> Variant:
	for c in RUN["map"]["cols"]:
		for n in c:
			if n["id"] == id: return n
	return null

# ======================= the click dispatcher (the JS ACT table) =======================
# Every button on every campaign screen is [act, arg, enabled]; act(name, arg) is the click. arg is a string ("" when the button has none).
func act(name: String, arg = "") -> void:
	var a = "" if arg == null else str(arg)
	match name:
		"title": titleScreen()
		"closeModal":
			if not _arc_after(modal_d): close_modal()
		"continueRun": ACT_continueRun()
		"newRunScreen": ACT_newRunScreen()
		"abandonRun":
			RUN = clone(SAVED_RUN); endRun(false, true)
		"legacy": legacyScreen()
		"help": helpScreen()
		"progTab":
			prog_tab = a; legacyScreen()
		"buyVariant": ACT_buyVariant(a)
		"pickAdmiral":
			if picked_admiral != a:
				run_opt["alt"] = false; run_opt["cmdAlt"] = false
			picked_admiral = a; admiralScreen()
		"pickFaction":
			picked_faction = a; META["opts"]["lastFac"] = a; admiralScreen()
		"optAlt":
			run_opt["alt"] = a == "1"; admiralScreen()
		"optCmd":
			run_opt["cmdAlt"] = a == "1"; admiralScreen()
		"optHeat":
			var i = run_opt["heat"].find(a)
			if i >= 0: run_opt["heat"].remove_at(i)
			else: run_opt["heat"].append(a)
			admiralScreen()
		"startRun": ACT_startRun()
		"pickAspect": ACT_pickAspect(a)
		"nextFac":
			picked_faction = a; META["opts"]["lastFac"] = a; admiralScreen()
		"saveQuit":
			saveRun(); titleScreen()
		"enterNode": ACT_enterNode(a)
		"fleetScreen": fleetScreen("map")
		"backMap":
			saveRun(); mapScreen()
		"equip": ACT_equip(a)
		"unequip": ACT_unequip(a)
		"promote": promoteModal(a, Callable(self, "_fleet_back"))
		"takePerk": ACT_takePerk(a)
		"yardFleet": fleetScreen("shipyard")
		"backShipyard": shipyardScreen(yard_node)
		"leaveYard":
			completeNode(); mapScreen()
		"buyHull": ACT_buyHull(a)
		"buyMod": ACT_buyMod(a)
		"repair": ACT_repair(a)
		"repairAll": ACT_repairAll()
		"upgradeMk": ACT_upgradeMk(a)
		"sellShip": ACT_sellShip(a)
		"sellConfirm": ACT_sellConfirm(a)
		"fleetFromModal":
			close_modal(); fleetScreen("map")
		"eventChoice": ACT_eventChoice(a)
		"battle": ACT_battle(a)
		"c3continue": ACT_c3continue()
		"c3retreat": ACT_c3retreat()
		"c3retreatYes":
			close_modal()
			if B != null and jt(B.get("campaign")) and not jt(B.get("over")) and not jt(B.get("busy")) and not jt(B.get("finished")) and not jt(B.get("ending")): finishBattle("retreat")
		"c3retreatNo": close_modal()
		"prizeStep": ACT_prizeStep()
		"prizeSet": ACT_prizeSet(a)
		"prizeConfirm": ACT_prizeConfirm()
		"salvageStep": ACT_salvageStep()
		"takeSalvage": ACT_takeSalvage(a)
		"rewardNext": ACT_rewardNext()
		"takeMod": ACT_takeMod(a)
		"takeBoon": ACT_takeBoon(a)
		"takeRelic": ACT_takeRelic(a)
		"factionVerb": ACT_factionVerb()
		"boonReroll": ACT_boonReroll(a)
		"boonDecline": ACT_boonDecline()
		"buyTrack": ACT_buyTrack(a)
		_: push_warning("campaign: unknown action " + name)

# ======================= campaign_meta.js: title, admiral, aspect, progression, help, run end =======================
func titleScreen() -> void:
	RUN = null; B = null
	var acts = []
	if SAVED_RUN != null: A(acts, "continueRun")
	A(acts, "newRunScreen"); A(acts, "legacy"); A(acts, "help")
	show_page("title", {"saved": SAVED_RUN != null, "renown_dot": float(z0(META.get("renown"))) >= 15, "best": META["stats"].get("best"), "wins": META["stats"].get("wins")}, acts)
func ACT_continueRun() -> void:
	RUN = clone(SAVED_RUN)
	ensureFlagship(); mapScreen()
	if RUN.get("reward") != null: resumeReward()
	var rep = (RUN["_repairs"] as Array).size() if RUN.get("_repairs") is Array else 0
	var lost = int(z0(RUN.get("_shipsDropped")))
	if rep > 0:
		toast("Your save came from an older version: " + ((str(lost) + " ship" + ("s" if lost > 1 else "") + " and ") if lost > 0 else "") + ((str(rep - lost) + " item" + ("s" if rep - lost > 1 else "") + " ") if rep - lost > 0 else "") + "no longer in the game " + ("were" if (lost > 0 or rep > 1) else "was") + " removed.")
		RUN.erase("_repairs"); RUN.erase("_shipsDropped"); saveRun()
func ACT_newRunScreen() -> void:
	if SAVED_RUN != null:
		var acts = []; A(acts, "abandonRun"); A(acts, "closeModal")
		show_modal("abandon", {}, acts); return
	admiralScreen()
func _mine() -> Array:
	var out = []
	for id in ADMIRALS.keys():
		if or_(ADMIRALS[id].get("fac"), "voidsworn") == picked_faction: out.append(id)
	return out
func admiralScreen() -> void:
	var mine = _mine()
	if not mine.has(picked_admiral) or not jt(META["admirals"].get(picked_admiral)):
		var pa = null
		for id in mine:
			if jt(META["admirals"].get(id)):
				pa = id; break
		picked_admiral = pa if pa != null else mine[0]
	var acts = []
	for f in RUN_FACTIONS: A(acts, "pickFaction", f)
	for id in mine:
		if jt(META["admirals"].get(id)): A(acts, "pickAdmiral", id)
	var id0 = picked_admiral; var a = ADMIRALS[id0]; var ml = masteryLevel(id0)
	var opts = {"ml": ml, "alt": null, "cmd2": null, "heat": float(z0(META["stats"].get("wins"))) > 0}
	if ml >= 1:
		opts["alt"] = altFleetPlan(id0, picked_faction); A(acts, "optAlt", "0"); A(acts, "optAlt", "1")
	if ml >= 3 and jt(a.get("cmd")):
		var c2 = altCommand(id0)
		if c2 != null:
			opts["cmd2"] = c2; A(acts, "optCmd", "0"); A(acts, "optCmd", "1")
	if opts["heat"]:
		for k in HEAT.keys(): A(acts, "optHeat", k)
	A(acts, "startRun"); A(acts, "title")
	show_page("admiral", {"mine": mine, "opts": opts}, acts)
func ACT_startRun() -> void:
	var ml = masteryLevel(picked_admiral)
	newRun(picked_admiral, picked_faction, {"alt": run_opt["alt"] and ml >= 1, "cmdAlt": run_opt["cmdAlt"] and ml >= 3, "heat": run_opt["heat"].duplicate() if float(z0(META["stats"].get("wins"))) > 0 else []})
	tel("run_start", {"fac": RUN["fac"], "admiral": picked_admiral})
	aspectScreen()
func aspectScreen() -> void:
	var f = ensureFlagship()
	var opts = shuffle(ASPECTS.keys()).slice(0, 4 if float(z0(RUN.get("mastery"))) >= 2 else 3)
	W["aspOffer"] = opts
	var acts = []
	for k in opts: A(acts, "pickAspect", k)
	show_page("aspect", {"flag": f, "opts": opts}, acts)
func _set_aspect(k) -> void:
	RUN["aspect"] = k; ensureFlagship()
func ACT_pickAspect(k: String) -> void:
	if not ASPECTS.has(k) or RUN == null: return
	changeFleet(_set_aspect.bind(k))
	tel("aspect_pick", {"id": k})
	saveRun(); introModal()
func introModal() -> void:
	mapScreen()
	var acts = []; A(acts, "closeModal")
	show_modal("intro", {"fac": RUN["map"]["fac"], "cond": sectorCond()}, acts)
func favFirst() -> Array:
	var lf = or_(META["opts"].get("lastFac"), "voidsworn"); var out = [lf]
	for f in RUN_FACTIONS:
		if f != lf: out.append(f)
	return out
func legacyScreen() -> void:
	var acts = []
	for t in ["variants", "mastery", "favour", "heat", "fallen"]: A(acts, "progTab", t)
	if prog_tab == "variants":
		for f in favFirst():
			for vid in HULL_VARIANTS.keys():
				var v = HULL_VARIANTS[vid]
				if HULLS[v["base"]].get("fac") != f: continue
				if not jt(META["variants"].get(vid)) and not jt(v.get("arc")): A(acts, "buyVariant", vid, float(z0(META.get("renown"))) >= float(v["cost"]))   # R41: arc variants are earned, never bought
	A(acts, "title")
	show_page("legacy", {"tab": prog_tab}, acts)
func ACT_buyVariant(id: String) -> void:
	var v = HULL_VARIANTS.get(id); META["variants"] = or_(META.get("variants"), {})
	if v == null or jt(v.get("arc")) or jt(META["variants"].get(id)) or float(z0(META.get("renown"))) < float(v["cost"]): return   # R41: arc variants are earned, never bought
	META["renown"] = float(META["renown"]) - float(v["cost"]); META["variants"][id] = true
	tel("variant_buy", {"id": id}); persist_save(true); legacyScreen()
func helpScreen() -> void:
	var acts = []; A(acts, "title"); show_page("help", {}, acts)
func runRenown() -> float:
	if RUN == null: return 0.0
	var s = RUN["stats"]
	return float(s["battles"]) * 2 + float(s["elites"]) * 4 + float(s["bosses"]) * 15 + floor(float(s["kills"]) / 4.0) + (float(RUN["sector"]) - 1) * 5
func nextFacPick() -> Variant:
	var won = or_(META["stats"].get("wonFacs"), [])
	var pool = RUN_FACTIONS.filter(func(f): return f != RUN["fac"] and not won.has(f))
	return pick(pool if pool.size() > 0 else RUN_FACTIONS.filter(func(f): return f != RUN["fac"]))
func endRun(victory: bool, abandoned: bool = false) -> void:
	var s = RUN["stats"]
	var prevBest = float(z0(META["stats"].get("best"))); META["stats"]["best"] = max(prevBest, float(RUN["sector"]))
	if victory:
		META["stats"]["wins"] = float(META["stats"]["wins"]) + 1; META["stats"]["wonFacs"] = or_(META["stats"].get("wonFacs"), [])
		if not META["stats"]["wonFacs"].has(RUN["fac"]): META["stats"]["wonFacs"].append(RUN["fac"])
	for f in RUN["fallen"]: META["fallen"].append(f)
	if META["fallen"].size() > 80: META["fallen"] = META["fallen"].slice(META["fallen"].size() - 80)
	tel("run_end", {"victory": victory, "abandoned": abandoned, "fac": RUN["fac"], "stats": s})
	var hl = heatLevel(RUN.get("heat")); var ren = jsround(runRenown() * (1.0 + 0.1 * hl)); META["renown"] = float(z0(META.get("renown"))) + ren
	var mx0 = masteryLevel(RUN["admiral"]); var mxGain = float(s["battles"]) + float(s["elites"]) * 2 + float(s["bosses"]) * 5 + (10.0 if victory else 0.0)
	META["mastery"] = or_(META.get("mastery"), {}); META["mastery"][RUN["admiral"]] = float(z0(META["mastery"].get(RUN["admiral"]))) + mxGain
	var mx1 = masteryLevel(RUN["admiral"])
	if victory and hl > 0:
		META["heatBest"] = or_(META.get("heatBest"), {}); META["heatBest"][RUN["fac"]] = max(float(z0(META["heatBest"].get(RUN["fac"]))), hl)
	RUN["carry"] = {"ren": ren, "mxGain": mxGain, "mx0": mx0, "mx1": mx1, "hl": hl}
	if arcs_on and not abandoned and arc_end_cb is Callable and (arc_end_cb as Callable).is_valid() and _arc_played(3): arc_end_cb.call(victory)
	RUN["over"] = true; SAVED_RUN = null; persist_save()
	var nf = nextFacPick() if victory else null
	var acts = []
	if nf != null:
		A(acts, "nextFac", nf); A(acts, "newRunScreen")
	else: A(acts, "newRunScreen")
	A(acts, "title")
	var mins = null
	if jt(RUN.get("t0")): mins = max(1.0, jsround((now_ms() - float(RUN["t0"])) / 60000.0))
	show_page("end", {"victory": victory, "abandoned": abandoned, "run": RUN, "next": nf, "prevBest": prevBest, "mins": mins}, acts)
	RUN = null
	ended = true

# ======================= campaign_run.js: map, fleet, shipyard, drydock, events, rewards =======================
func completeNode() -> void:
	var n = findNode(RUN.get("curNode")) if RUN.get("curNode") != null else null
	if n != null: n["done"] = true
	RUN["curNode"] = null; saveRun()
func _nodes() -> Array:
	var out = []
	for c in RUN["map"]["cols"]:
		for n in c: out.append(n)
	return out
func mapScreen() -> void:
	B = null
	var m = RUN["map"]; var avail = availableNodes(); var all = _nodes()
	for n in all:
		if not jt(n.get("done")) and not jt(n.get("enc")) and (n["type"] == "battle" or n["type"] == "elite"): n.merge(rollEncounter(n["type"], n["col"]), true)
	if not jt(m.get("region")):
		m["region"] = pickRegion(m["fac"]); m["biome"] = rollBiome(m["region"])
		for n in all:
			if not jt(n.get("done")):
				n["map"] = regionMap(m["region"], n["col"], m["cols"].size()); fitEncounter(n)
		saveRun()
	ensureNemesis(); ensurePatrons()
	for n in all:
		if not jt(n.get("done")) and not jt(n.get("rw")) and _is(n, ["battle", "elite", "boss"]): n["rw"] = rollNodeReward(n["type"])
	if nodeSeeds(all) > 0: saveRun()
	var acts = []
	A(acts, "saveQuit")
	for n in all:
		if avail.has(n["id"]): A(acts, "enterNode", n["id"])
	if verbFor() != null: A(acts, "factionVerb", "", verbCanUse())
	A(acts, "fleetScreen")
	show_page("map", {"avail": avail}, acts)
func ACT_enterNode(id: String) -> void:
	if not availableNodes().has(id): return
	var n = findNode(id); RUN["pos"] = id; RUN["curNode"] = id
	tel("node", {"type": n["type"], "col": n["col"]})
	if _is(n, ["battle", "elite", "boss"]):
		var kind = n["type"]; var fac = nodeFaction(n)
		if nemNodeIs(n):   # B4: the Nemesis fight (marked on the map beforehand)
			ensureNemesis(); var fa = nemBeh().get("fleet"); var nc = {"kind": "elite", "fac": RUN["nem"]["fac"], "col": n["col"], "node": id, "nemesis": nemBattleCfg()}
			if fa != null and ARCHETYPES.has(fa): nc["arch"] = fa   # his fleet is built his faction's way (swarm, heavy, duel, line)
			battleScreen(nc); return
		if jt(RUN.get("ambush")) and kind == "battle":
			kind = "elite"; fac = RUN["map"]["fac"] if RUN["fac"] == "hegemony" else "hegemony"; RUN["ambush"] = false
			toast("The Hegemony escort you robbed has found you.")
		battleScreen({"kind": kind, "fac": fac, "col": n["col"], "node": id})
	elif n["type"] == "event": eventScreen(n)
	elif n["type"] == "shipyard": shipyardScreen(n)
	elif n["type"] == "drydock": drydockScreen(n)
	elif n["type"] == "field": fieldRepairs(n)
func _ship(uid) -> Variant:
	for s in RUN["fleet"]:
		if s["uid"] == uid: return s
	return null
func shipCardActs(acts: Array, s: Dictionary, refit: bool) -> void:
	if jt(s["cap"].get("pending")): A(acts, "promote", s["uid"])
	if refit:
		for i in range(int(HULLS[s["tpl"]]["slots"])):
			if i < s["mods"].size() and jt(s["mods"][i]): A(acts, "unequip", s["uid"] + ":" + str(i))
func fleetScreen(back) -> void:
	var acts = []
	A(acts, "backShipyard" if back == "shipyard" else "backMap")
	for i in range(RUN["inventory"].size()):
		var m = RUN["inventory"][i]
		for s in RUN["fleet"]:
			if s["mods"].size() < int(HULLS[s["tpl"]]["slots"]) and (not jt(MODULES[m].get("only")) or HULLS[s["tpl"]].get("ab") == MODULES[m]["only"]): A(acts, "equip", str(i) + ":" + s["uid"])
	for s in RUN["fleet"]: shipCardActs(acts, s, true)
	show_page("fleet", {"back": back}, acts)
	RUN["_fleetBack"] = back
func _fleet_back() -> void: fleetScreen(RUN.get("_fleetBack"))   # undefined in the JS when the fleet screen was never opened this session
func _push_mod(sh, m) -> void: sh["mods"].append(m)
func ACT_equip(arg: String) -> void:
	var p = arg.split(":"); var s = _ship(p[1]); var i = int(p[0])
	var m = RUN["inventory"][i] if i >= 0 and i < RUN["inventory"].size() else null
	if s == null or not jt(m): return
	changeShip(s, _push_mod.bind(m))
	RUN["inventory"].remove_at(i); _fleet_back()
func _pop_mod(sh, i, got: Array) -> void:
	if i < sh["mods"].size(): got.append(sh["mods"].pop_at(i))
func ACT_unequip(arg: String) -> void:
	var p = arg.split(":"); var s = _ship(p[0])
	if s == null: return
	var got = []
	changeShip(s, _pop_mod.bind(int(p[1]), got))
	if got.size() > 0 and jt(got[0]): RUN["inventory"].append(got[0])
	_fleet_back()
func promoteModal(uid: String, after: Callable) -> void:
	var s = _ship(uid)
	if s == null or not jt(s["cap"].get("pending")):
		after.call(); return
	if not jt(s["cap"].get("offer")):
		var pool = PERKS.keys().filter(func(p): return not s["cap"]["perks"].has(p) and (p != "wing" or HULLS[s["tpl"]].get("ab") == "launch"))
		s["cap"]["offer"] = shuffle(pool).slice(0, 2)
	promote_after = after
	var acts = []
	for p in s["cap"]["offer"]: A(acts, "takePerk", uid + ":" + p)
	show_modal("promote", {"ship": s}, acts)
func _take_perk(sh, perk) -> void:
	sh["cap"]["perks"].append(perk); sh["cap"]["pending"] = float(sh["cap"]["pending"]) - 1; sh["cap"]["offer"] = null
func ACT_takePerk(arg: String) -> void:
	var p = arg.split(":"); var s = _ship(p[0])
	if s == null: return
	changeShip(s, _take_perk.bind(p[1]))
	close_modal()
	if float(s["cap"]["pending"]) > 0: promoteModal(p[0], promote_after)
	else: promote_after.call()
func _has_num(arr: Array, x) -> bool:
	for v in arr:
		if (v is int or v is float) and float(v) == float(x): return true
	return false
func shipyardStock(n: Dictionary) -> Dictionary:
	if jt(n.get("stock")): return n["stock"]
	var hulls = ["warden", "harrow", "penitent"]
	if jt(META["unlocked"].get("u_carrier")): hulls.append("reliquary")
	if jt(META["unlocked"].get("u_battleship")): hulls.append("cathedral")
	if jt(META["unlocked"].get("u_dread")): hulls.append("ascendant")
	var own = []
	for h in hulls:
		var e = equivHull(h, RUN["fac"])
		if not own.has(e): own.append(e)
	hulls = own
	var pickH = ssort(shuffle(hulls.duplicate()).slice(0, 3), func(a, b): return float(or_(HULLS[a].get("cp"), 1)) - float(or_(HULLS[b].get("cp"), 1)))
	for h in pickH.duplicate():
		for vid in HULL_VARIANTS.keys():
			if HULL_VARIANTS[vid]["base"] == h and META.get("variants") != null and jt(META["variants"].get(vid)): pickH.insert(pickH.find(h) + 1, vid)
	n["stock"] = {"hulls": pickH, "mods": shuffle(modulePool()).slice(0, 3), "sold": []}
	return n["stock"]
func shipyardScreen(n) -> void:
	yard_node = n
	var st = shipyardStock(n); var pm = priceMult(); var cp = fleetCP()
	var acts = []
	A(acts, "yardFleet"); A(acts, "leaveYard")
	var allMiss = 0.0
	for s in RUN["fleet"]: allMiss += float(derive(s)["maxHp"]) - float(s["hp"])
	var allCost = ceil(allMiss / 2.0 * pm)
	A(acts, "repairAll", "", allMiss > 0 and float(RUN["credits"]) >= allCost)
	for s in RUN["fleet"]:
		var d = derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var rc = ceil(miss / 2.0 * pm); var mc = mkCost(s)
		shipCardActs(acts, s, false)
		A(acts, "repair", s["uid"], miss > 0 and float(RUN["credits"]) >= rc)
		A(acts, "upgradeMk", s["uid"], float(s["mk"]) < 3 and float(RUN["credits"]) >= mc)
		A(acts, "sellShip", s["uid"], RUN["fleet"].size() > 1)
	for h in st["hulls"]:
		var t = HULLS[h]; var cost = jsround(float(t["cost"]) * pm); var fits = cp + float(t["cp"]) <= float(RUN["cpCap"])
		var uniq = jt(t.get("unique")) and RUN["fleet"].any(func(s): return s["tpl"] == h)
		A(acts, "buyHull", h, float(RUN["credits"]) >= cost and fits and not uniq)
	for i in range(st["mods"].size()):
		if not _has_num(st["sold"], i): A(acts, "buyMod", i, float(RUN["credits"]) >= jsround(float(MODULES[st["mods"][i]]["cost"]) * pm))
	for cls in fleetClasses():
		A(acts, "buyTrack", cls, classTrack(cls) < float(CLASS_TRACK_MAX) and float(RUN["credits"]) >= classTrackCost(cls))
	show_page("shipyard", {"node": n, "pm": pm}, acts)
func fleetClasses() -> Array:
	var out = []
	for s in RUN["fleet"]:
		var c = HULLS[s["tpl"]].get("cls")
		if not out.has(c): out.append(c)
	return out
func ACT_buyTrack(cls: String) -> void:
	if not buyClassTrack(cls): return
	tel("shop", {"k": "track", "id": cls, "lv": classTrack(cls)})
	toast(cls + " refit level " + numstr(classTrack(cls)) + ": every " + cls.to_lower() + " gains."); shipyardScreen(yard_node)
func ACT_buyHull(h: String) -> void:
	var t = HULLS[h]; var cost = jsround(float(t["cost"]) * priceMult())
	if float(RUN["credits"]) < cost or fleetCP() + float(t["cp"]) > float(RUN["cpCap"]): return
	RUN["credits"] = float(RUN["credits"]) - cost
	tel("shop", {"k": "hull", "id": h, "cost": cost})
	var s = newShip(h); RUN["fleet"].append(s); toast("The " + str(s["name"]) + " joins the fleet."); shipyardScreen(yard_node)
func ACT_buyMod(a: String) -> void:
	var i = int(a); var st = yard_node["stock"]; var m = st["mods"][i]; var cost = jsround(float(MODULES[m]["cost"]) * priceMult())
	if _has_num(st["sold"], i) or float(RUN["credits"]) < cost: return
	RUN["credits"] = float(RUN["credits"]) - cost
	tel("shop", {"k": "mod", "id": m, "cost": cost})
	st["sold"].append(i); RUN["inventory"].append(m); toast(modName(m) + " is in the hold. Fit it from Refits."); shipyardScreen(yard_node)
func ACT_repair(uid: String) -> void:
	var s = _ship(uid); var d = derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var c = ceil(miss / 2.0 * priceMult())
	if float(RUN["credits"]) < c: return
	RUN["credits"] = float(RUN["credits"]) - c; s["hp"] = d["maxHp"]; shipyardScreen(yard_node)
func ACT_repairAll() -> void:
	var pm = priceMult(); var miss = 0.0
	for s in RUN["fleet"]: miss += float(derive(s)["maxHp"]) - float(s["hp"])
	var c = ceil(miss / 2.0 * pm)
	if float(RUN["credits"]) < c: return
	RUN["credits"] = float(RUN["credits"]) - c
	for s in RUN["fleet"]: s["hp"] = derive(s)["maxHp"]
	shipyardScreen(yard_node)
func _mk_up(sh) -> void: sh["mk"] = float(sh["mk"]) + 1
func _mk_up3(sh) -> void:
	if float(sh["mk"]) < 3: sh["mk"] = float(sh["mk"]) + 1
func ACT_upgradeMk(uid: String) -> void:
	var s = _ship(uid); var c = mkCost(s)
	if float(s["mk"]) >= 3 or float(RUN["credits"]) < c: return
	RUN["credits"] = float(RUN["credits"]) - c
	tel("shop", {"k": "mk", "id": s["tpl"], "cost": c})
	changeShip(s, _mk_up)
	toast(str(s["name"]) + " refitted to Mk " + roman(s["mk"]) + "."); shipyardScreen(yard_node)
func ACT_sellShip(uid: String) -> void:
	if RUN["fleet"].size() <= 1: return
	var s = _ship(uid)
	var acts = []; A(acts, "sellConfirm", uid); A(acts, "closeModal")
	show_modal("sell", {"ship": s, "value": prizeScrap(s["tpl"])}, acts)
func ACT_sellConfirm(uid: String) -> void:
	var i = -1
	for k in range(RUN["fleet"].size()):
		if RUN["fleet"][k]["uid"] == uid:
			i = k; break
	if i < 0: return
	var s = RUN["fleet"][i]
	RUN["inventory"].append_array(s["mods"]); RUN["credits"] = float(RUN["credits"]) + prizeScrap(s["tpl"]); RUN["fleet"].remove_at(i)
	close_modal(); shipyardScreen(yard_node)
func drydockScreen(_n) -> void:
	var lines = []
	for s in RUN["fleet"]:
		var d = derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var fix = ceil(miss * 0.6 * repairMult())
		s["hp"] = float(s["hp"]) + fix
		if fix != 0: lines.append(str(s["name"]) + ": +" + numstr(fix) + " hull")
	completeNode(); mapScreen()
	var acts = []; A(acts, "closeModal"); A(acts, "fleetFromModal")
	show_modal("drydock", {"lines": lines}, acts)
func fieldRepairs(_n) -> void:
	for sh in RUN["fleet"]:
		var mx = float(derive(sh)["maxHp"]); sh["hp"] = min(mx, float(sh["hp"]) + jsround(mx * 0.2 * repairMult()))
	tel("field_repairs", {})
	completeNode(); mapScreen(); toast("Field repairs: every ship recovers 20% of its hull.")
func _ev_fits(e) -> bool: return not (jt(e.get("not")) and e["not"].has(RUN["fac"])) and e["id"] != EVENT_FALLBACK
# B4: blue options. needMet says whether the fleet meets a requirement; needText says it in plain words (shown on the option either way)
func needMet(nd) -> bool:
	if not jt(nd): return true
	var kit = fleetKit()
	if jt(nd.get("fac")):
		if nd["fac"] is Array:
			if not nd["fac"].has(RUN["fac"]): return false
		elif nd["fac"] != RUN["fac"]: return false
	if jt(nd.get("kind")) and not jt(kit.get(nd["kind"])): return false
	if jt(nd.get("carrier")) and not jt(kit.get("carrier")): return false
	if jt(nd.get("shields")) and not jt(kit.get("shields")): return false
	if jt(nd.get("relic")):
		if (nd["relic"] is float or nd["relic"] is int) and float(nd["relic"]) == 1.0:
			if RUN["relics"].size() == 0: return false
		elif not RUN["relics"].has(nd["relic"]): return false
	if jt(nd.get("mod")) and RUN["inventory"].size() == 0: return false
	if jt(nd.get("cred")) and float(RUN["credits"]) < float(nd["cred"]): return false
	if jt(nd.get("vet")) and not RUN["fleet"].any(func(s): return float(z0(s["cap"].get("rank"))) >= float(nd["vet"])): return false
	if jt(nd.get("flag")) and not (RUN.get("flags") is Dictionary and RUN["flags"].get(nd["flag"]) != null): return false
	if jt(nd.get("intel")):
		var rv = RUN["nem"]["revealed"] if (RUN.get("nem") is Dictionary and RUN["nem"].get("revealed") is Array) else []
		if rv.size() < float(nd["intel"]): return false
	return true
func needText(nd) -> String:
	if not jt(nd): return ""
	var p = []
	if jt(nd.get("fac")):
		var fs = nd["fac"] if nd["fac"] is Array else [nd["fac"]]; var nm = []
		for f in fs: nm.append(FACTIONS[f]["n"] if FACTIONS.has(f) else str(f))
		p.append(" or ".join(PackedStringArray(nm)))
	if jt(nd.get("kind")): p.append(str(or_(KIND_WORD.get(nd["kind"]), nd["kind"])) + " in the fleet")
	if jt(nd.get("carrier")): p.append("a carrier")
	if jt(nd.get("shields")): p.append("a shielded ship")
	if jt(nd.get("relic")): p.append("a relic" if ((nd["relic"] is float or nd["relic"] is int) and float(nd["relic"]) == 1.0) else relicName(nd["relic"]))
	if jt(nd.get("mod")): p.append("a refit in the hold")
	if jt(nd.get("cred")): p.append(numstr(nd["cred"]) + " credits")
	if jt(nd.get("vet")): p.append("a " + str(RANKS[int(nd["vet"])]) + " or better")
	if jt(nd.get("flag")): p.append("an earlier choice")
	if jt(nd.get("intel")): p.append(numstr(nd["intel"]) + " Nemesis weakness" + ("es" if float(nd["intel"]) > 1 else "") + " known")
	return "Needs " + ", ".join(PackedStringArray(p))
# the next event at an event node: never one already seen this run (B4), never one barred for your faction; a quiet stretch once all are seen
func nextEvent() -> Dictionary:
	RUN["seenEvents"] = or_(RUN.get("seenEvents"), [])
	var pool = EVENTS.filter(func(e): return _ev_fits(e) and not RUN["seenEvents"].has(e["id"]))
	var ev = null
	if pool.size() > 0: ev = pick(pool)
	else:
		for e in EVENTS:
			if e["id"] == EVENT_FALLBACK:
				ev = e; break
	RUN["seenEvents"].append(ev["id"]); return ev
func eventOptOk(o) -> bool:
	var cost = o["r"].get("cost") if o.get("r") is Dictionary else null
	return (not jt(cost) or float(RUN["credits"]) >= float(cost)) and needMet(o.get("need"))
func eventScreen(_n) -> void:
	var ev = nextEvent()
	cur_event = ev.duplicate(false)
	if jt(ev.get("v")) and jt(ev["v"].get(RUN["fac"])): cur_event.merge(ev["v"][RUN["fac"]], true)
	mapScreen()
	var acts = []
	for i in range(cur_event["o"].size()):
		A(acts, "eventChoice", i, eventOptOk(cur_event["o"][i]))
	show_modal("event", {"ev": cur_event}, acts)
# B4: every event choice writes a flag later systems read (faction verbs, the Nemesis): RUN.flags[event id] = the option's key, plus any counters
func eventFlags(ev, o, i: int) -> void:
	if not (RUN.get("flags") is Dictionary): RUN["flags"] = {}
	RUN["flags"][ev["id"]] = o["k"] if jt(o.get("k")) else str(i)
	var fl = o.get("fl") if o.get("fl") is Dictionary else {}
	for k in fl.keys(): RUN["flags"][k] = float(z0(RUN["flags"].get(k))) + float(fl[k])
# ---------- B4 the Nemesis (campaign rules; the battle rules apply his weaknesses and adaptations in the fight) ----------
# R42 (Oct 26): a fresh identity every run from the faction's own pools (never a CAPTAINS or ADMIRALS name), a personality, two strength
# traits, a portrait id (nem_<faction>_1..6) with scar overlays, and faction behaviour (NEM_FAC[fac].beh) on the map and in battle.
func nemName(fac) -> String:
	var F = NEM_FAC[fac]
	for k in range(12):
		var a = str(pick(F["pre"])); var b = str(pick(F["post"]))
		var n = (a + b) if (b.length() > 0 and b.unicode_at(0) >= 97 and b.unicode_at(0) <= 122) else (a + " " + b)
		var clash = false
		for x in ADMIRALS.values():
			if str(x["n"]).contains(n):
				clash = true; break
		if not clash: return n
	var p1 = str(pick(F["pre"])); return p1 + " " + str(pick(F["post"]))
func newNemesis() -> Dictionary:
	var fac = RUN["foes"][3] if (RUN.get("foes") is Array and RUN["foes"].size() > 3 and jt(RUN["foes"][3])) else pick(RUN_FACTIONS.filter(func(f): return f != RUN["fac"]))
	var F = NEM_FAC[fac]; var beh = F["beh"]
	var name = nemName(fac)
	var title = pick(F["titles"]); var persona = pick(F["personas"]); var traits = shuffle(F["traits"].duplicate()).slice(0, 2)
	var portrait = "nem_" + str(fac) + "_" + numstr(1 + floor(rnd() * 6))
	var clash = {"slow": "swift", "board": "boarders", "ion": "shielded"}   # no strength and weakness that cancel out
	var weakPool = NEM_WEAK.keys().filter(func(k): return not (k == "anchor" and (jt(beh.get("noFlee")) or jt(beh.get("revive")))) and not (clash.has(k) and traits.has(clash[k])))   # zealots and the Deathless never break
	var g = nemGender(fac, name)
	var weak = shuffle(weakPool).slice(0, 2)
	return {"fac": fac, "name": name, "g": g, "title": title, "persona": persona, "traits": traits, "portrait": portrait, "weak": weak, "revealed": [], "adapt": [], "clock": 0, "met": 0,
		"beaten": 0, "scars": 0, "scarKinds": [], "epithets": [], "epithet": null, "last_beat": null, "fed": 0, "riches": 0, "loot": 0, "held": null, "gloat": null, "honed": 0,
		"revived": false, "dead": false, "strike": false, "seen": {}, "signatures": []}
func ensureNemesis() -> Variant:   # B4 saves get an R42 identity; older R42 saves get the story layer's field names
	if RUN == null: return null
	if RUN.get("fleet") != null and (not jt(RUN.get("nem")) or not jt(RUN["nem"].get("persona"))):
		var old = RUN.get("nem"); RUN["nem"] = newNemesis()
		if jt(old):
			for k in ["weak", "revealed", "adapt", "clock", "met", "beaten", "scars", "dead", "strike", "seen"]:
				if old.get(k) != null: RUN["nem"][k] = old[k]
			if jt(old.get("beat")): RUN["nem"]["last_beat"] = old["beat"]
			RUN["nem"]["adapt"] = RUN["nem"]["adapt"].filter(func(x): return NEM_ADAPT.has(x))
	var N = RUN.get("nem")
	if jt(N) and jt(N.get("persona")):
		if jt(N.get("beat")) and not jt(N.get("last_beat")): N["last_beat"] = "battery" if N["beat"] == "ion" else N["beat"]
		N.erase("beat")
		if not jt(N.get("g")): N["g"] = nemGender(N["fac"], str(N["name"]) if jt(N.get("name")) else "")
		N.erase("pronoun")
		if N.get("scarList") is Array and not jt(N.get("scarKinds")):
			N["scarKinds"] = N["scarList"].filter(func(x): return not str(x).begins_with("ep:"))
			N["epithets"] = N["scarList"].filter(func(x): return str(x).begins_with("ep:")).map(func(x): return str(x).substr(3))
		N.erase("scarList")
		N["scarKinds"] = or_(N.get("scarKinds"), []); N["epithets"] = or_(N.get("epithets"), ([N["epithet"]] if jt(N.get("epithet")) else [])); N["signatures"] = or_(N.get("signatures"), [])
	return N
# R42 gender for the story layer's pronouns: 'n' (it) for the Chorus, 'f' when his first name part is a feminine one, else 'm'. No random draw.
func nemGender(fac, name: String) -> String:
	var F = NEM_FAC.get(fac, {}) if fac != null else {}
	if jt(F.get("g")): return str(F["g"])
	for p in or_(F.get("fem"), []):
		if name.begins_with(str(p)): return "f"
	return "m"
func nemPr(N) -> Dictionary:
	var g = N.get("g") if jt(N) else null
	if g == "n": return {"he": "it", "He": "It", "his": "its", "His": "Its", "him": "it"}
	if g == "f": return {"he": "she", "He": "She", "his": "her", "His": "Her", "him": "her"}
	return {"he": "he", "He": "He", "his": "his", "His": "His", "him": "him"}
# his faction's lines are written with he and his; this swaps in her or it for a rival who is not a he
func nemSay(t, N) -> String:
	var g = N.get("g") if jt(N) else null
	if not jt(t) or g == "m" or not jt(g): return str(t) if t != null else ""
	var P = nemPr(N); var re = RegEx.create_from_string("\\b(he|his|him|He|His)\\b"); var out = ""; var at = 0
	for m in re.search_all(str(t)):
		out += str(t).substr(at, m.get_start() - at) + str(P[m.get_string()]); at = m.get_end()
	return out + str(t).substr(at)
# what the next win does when it fills his clock (the card's warning line, R7); "" when it does not
func nemWarnLine(N) -> String:
	var st = nemBeh().get("strike")
	if jt(N.get("strike")) or float(N["met"]) >= float(RUN["sector"]) or float(N["clock"]) + float(or_(nemBeh().get("clock"), 1)) < float(NEM_CLOCK): return ""
	if st == "raid":
		var crip = RUN["fleet"].size() >= 3 and RUN["fleet"].any(func(x): return x["uid"] != RUN["flagUid"] and float(x["hp"]) < float(derive(x)["maxHp"]) * 0.25)
		return nemSay("Your next win fills his clock: he will raid", N) + " " + (numstr(jsround(float(RUN["credits"]) * 0.25)) + " credits" if float(RUN["credits"]) >= 30 else ("your most damaged ship (repair it above 25% hull, or keep 30 credits, to stop it)" if crip else "and find nothing to take")) + "."
	if st == "tithe": return "Your next win fills the clock: every ship will lose 6% of its hull (never below 1)."
	return nemSay("Your next win fills the clock: your next fight will be his.", N)
func nemFull() -> String:
	var N = RUN.get("nem") if RUN != null else null
	return (str(N["title"]) + " " + str(N["name"]) + ((" " + str(N["epithet"])) if jt(N.get("epithet")) else "")) if jt(N) else ""
func nemReveal() -> Variant:
	var N = ensureNemesis()
	if not jt(N): return null
	var w = null
	for x in N["weak"]:
		if not N["revealed"].has(x):
			w = x; break
	if w != null: N["revealed"].append(w)
	return w
# R42: his faction behaviour firing (raid, tithe, flee, revive, feed, fast_adapt, reinforce, duel, challenge) is logged as a 'nem_signature' event
func nemSignature(kind: String) -> void:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N): return
	if not (N.get("signatures") is Array): N["signatures"] = []
	N["signatures"].append(kind)
	if N["signatures"].size() > 40: N["signatures"].pop_front()
	tel("nem_signature", {"fac": N["fac"], "kind": kind, "sector": RUN["sector"]})
func nemBeh() -> Dictionary:
	var N = RUN.get("nem") if RUN != null else null
	if jt(N) and NEM_FAC.has(N["fac"]) and jt(NEM_FAC[N["fac"]].get("beh")): return NEM_FAC[N["fac"]]["beh"]
	return {}
# the clock: returns a line to show when it fills (the next fight becomes his); his faction sets the pace (Deathless patient, Voidsworn zealous)
func nemClockAdd(n) -> String:
	var N = ensureNemesis()
	if not jt(N) or jt(N.get("dead")): return ""
	var step = float(n) * float(or_(nemBeh().get("clock"), 1)) if float(n) > 0 else float(n)
	N["clock"] = clampv(jsround((float(N["clock"]) + step) * 2) / 2.0, 0, NEM_CLOCK)
	if float(N["clock"]) >= float(NEM_CLOCK) and float(N["met"]) < float(RUN["sector"]) and not jt(N.get("strike")):
		N["strike"] = true; var extra = nemStrike()
		return nemFull() + " has found your trail. Your next fight will be against his fleet." + ((" " + extra) if extra != "" else "")
	return ""
# what a full clock does on the map, by faction (always written on his card beforehand)
func nemStrike() -> String:
	var N = RUN["nem"]; var st = nemBeh().get("strike")
	if st == "raid" or st == "tithe": nemSignature(str(st))
	if st == "raid":
		if float(RUN["credits"]) >= 30:
			var cr = jsround(float(RUN["credits"]) * 0.25); RUN["credits"] = float(RUN["credits"]) - cr; N["loot"] = float(z0(N.get("loot"))) + cr
			return "His raiders hit your supply line: -" + numstr(cr) + " credits. He holds them; kill him to take them back."
		var cand = null
		if RUN["fleet"].size() >= 3:
			var cs = ssort(RUN["fleet"].filter(func(x): return x["uid"] != RUN["flagUid"] and float(x["hp"]) < float(derive(x)["maxHp"]) * 0.25), func(a, b): return float(a["hp"]) - float(b["hp"]))
			if cs.size() > 0: cand = cs[0]
		if cand != null and not jt(N.get("held")):
			RUN["fleet"] = RUN["fleet"].filter(func(x): return not is_same(x, cand)); N["held"] = cand; N["riches"] = float(z0(N.get("riches"))) + 1
			return "With your coffers empty, his raiders cut out the crippled " + str(cand["name"]) + " and tow her away. Kill him and you take her back."
		return "His raiders find nothing worth taking."
	if st == "tithe":
		for x in RUN["fleet"]: x["hp"] = max(1.0, float(x["hp"]) - jsround(float(derive(x)["maxHp"]) * 0.06))
		return "The hunt wears on your fleet: every ship loses 6% of its hull."
	return ""
# is this battle node his? (strike pending, or the last fight before the rest stop when he has not been met this sector)
func nemNodeIs(n) -> bool:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N) or jt(N.get("dead")) or float(N["met"]) >= float(RUN["sector"]) or n == null or (n["type"] != "battle" and n["type"] != "elite"): return false
	return jt(N.get("strike")) or float(n["col"]) >= float(RUN["map"]["cols"].size() - 3)
func nemBattleCfg() -> Dictionary:
	var N = ensureNemesis(); var full = nemFull(); var tp = str(N["title"]) + " "; var i = full.find(tp)
	var nm = (full.substr(0, i) + full.substr(i + tp.length())) if i >= 0 else full
	return {"gloat": N.get("gloat") if jt(N.get("gloat")) else null, "honed": z0(N.get("honed")), "beaten": z0(N.get("beaten")), "name": nm, "title": N["title"], "fac": N["fac"], "persona": N["persona"], "traits": N["traits"].duplicate(), "weak": N["weak"].duplicate(), "revealed": N["revealed"].duplicate(),
		"adapt": N["adapt"].duplicate(), "scars": N["scars"], "fed": N.get("fed"), "riches": N.get("riches"), "last_beat": N.get("last_beat"), "g": N.get("g"), "met": float(N["beaten"]) + float(N["scars"]) > 0}
# adaptation: once per sector (Chorus also after every meeting), read from how you fought (RUN.nem.seen); his faction names it, and when nothing
# stood out he takes his faction's own special adaptation
func nemAdapt(force: bool = false) -> Variant:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N) or jt(N.get("dead")): return null
	var fast = jt(nemBeh().get("adaptFast")); var cap = max(0.0, float(RUN["sector"]) - 1.0) + ((float(N["beaten"]) + float(N["scars"])) if fast else 0.0)
	if N["adapt"].size() >= min(cap, 6.0) and not force: return null
	var s = N["seen"] if N.get("seen") is Dictionary else {}
	var sp = NEM_ADAPT_FAC[N["fac"]].get("special") if NEM_ADAPT_FAC.has(N["fac"]) else null
	var score = {"shields": float(z0(s.get("lance"))) * 2 + float(z0(s.get("ion"))) * 2, "pd": float(z0(s.get("torp"))) * 2 + float(z0(s.get("sq"))), "armor": float(z0(s.get("ram"))) * 4 + float(z0(s.get("board"))) * 4,
		"evasion": float(z0(s.get("battery"))) + float(z0(s.get("broad"))), "aim": float(z0(s.get("evaded"))) * 3}
	var ks = ssort(score.keys().filter(func(k): return not N["adapt"].has(k) and score[k] > 0), func(a, b): return score[b] - score[a])
	var pickA = ks[0] if ks.size() > 0 else null
	if pickA == null and jt(sp) and not N["adapt"].has(sp["id"]): pickA = sp["id"]
	if pickA == null:
		var rest = score.keys().filter(func(k): return not N["adapt"].has(k))
		if rest.size() > 0: pickA = rest[0]
	if pickA == null: return null
	N["adapt"].append(pickA); N["seen"] = {}; return pickA
func nemAdaptName(a, fac) -> String:
	var T = NEM_ADAPT_FAC.get(fac, {}) if fac != null else {}
	if jt(T.get("special")) and T["special"]["id"] == a: return str(T["special"]["n"])
	if jt(T.get(a)): return str(T[a])
	return str(NEM_ADAPT[a]["n"]) if NEM_ADAPT.has(a) else str(a)
func nemAdaptDesc(a, fac) -> String:
	var T = NEM_ADAPT_FAC.get(fac, {}) if fac != null else {}
	if jt(T.get("special")) and T["special"]["id"] == a: return str(T["special"]["d"])
	return str(NEM_ADAPT[a]["d"]) if NEM_ADAPT.has(a) else ""
func nemAdaptWhy(a, fac) -> String:
	var T = NEM_ADAPT_FAC.get(fac, {}) if fac != null else {}
	if jt(T.get("special")) and T["special"]["id"] == a: return "his own way of war"
	return str(NEM_ADAPT[a]["why"]) if NEM_ADAPT.has(a) else ""
# each survival adds a scar (a portrait overlay keyed by how he was hurt) and a new epithet
func nemScar(cause) -> void:
	var N = RUN["nem"]; var F = NEM_FAC[N["fac"]]
	N["scars"] = float(N["scars"]) + 1; N["scarKinds"] = or_(N.get("scarKinds"), []); N["epithets"] = or_(N.get("epithets"), [])
	N["scarKinds"].append(cause if jt(cause) else "blast")
	var tag = "fled" if cause == "fled" else ("burn" if cause in ["melt", "flay", "tidal"] else "wound")
	var sb = F.get("scarBy") if F.get("scarBy") is Dictionary else {}
	var byC = (sb.get(tag) if sb.get(tag) is Array else []).filter(func(x): return not N["epithets"].has(x))
	var left = byC if byC.size() > 0 else F["scars"].filter(func(x): return not N["epithets"].has(x))
	if left.size() > 0:
		N["epithet"] = pick(left); N["epithets"].append(N["epithet"])
# after his battle: returns plain lines for the reward summary. fled = he withdrew (Corsair, Ithar); flagDead = his flagship was destroyed
func nemAfterBattle(result: String, flagDead: bool, o: Dictionary = {}) -> Array:
	var N = RUN.get("nem")
	if not jt(N): return []
	var out = []; var beh = nemBeh(); var P = nemPr(N); N["met"] = RUN["sector"]; N["strike"] = false; N["clock"] = 0; var back = false
	if result == "win":
		N["beaten"] = float(N["beaten"]) + 1; N["gloat"] = null
		if jt(o.get("beat")):
			N["last_beat"] = o["beat"]; nemBeatTeach(o["beat"])
		var w = nemReveal()
		if w != null: out.append(nemSay("His captured logs reveal a weakness: " + str(NEM_WEAK[w]["n"]) + ".", N))
		if jt(o.get("fled")):
			if beh.get("strike") == "raid": N["riches"] = float(z0(N.get("riches"))) + 1
			if beh.get("strike") == "duel": N["honed"] = float(z0(N.get("honed"))) + 1
			nemScar("fled"); nemSignature("flee")
			out.append(nemSay(nemFull() + " breaks off and runs before you can finish him." + (" He will come back richer." if beh.get("strike") == "raid" else (" He will be back with the same few ships, honed sharper." if beh.get("strike") == "duel" else " He will be back.")), N))
		elif flagDead and float(RUN["sector"]) >= 3 and jt(beh.get("revive")) and not jt(N.get("revived")):
			N["revived"] = true; back = true; nemScar(o.get("cause") if jt(o.get("cause")) else "big"); nemSignature("revive"); N["met"] = float(RUN["sector"]) - 1
			out.append(nemSay(nemFull() + "'s flagship is destroyed, and then the wreck begins to move. He is reassembling for one last fight.", N))
		elif flagDead and float(RUN["sector"]) >= 3:
			N["dead"] = true; out.append(nemSay(nemFull() + " is dead. The feud is over.", N))
		elif flagDead:   # R49: before the last sector every rival, the Deathless one too, withdraws like this
			nemScar(o.get("cause") if jt(o.get("cause")) else "big"); out.append(nemSay(nemFull() + "'s flagship breaks apart, but he escapes, scarred and furious. He will be back.", N))
		else: out.append(nemSay(nemFull() + " withdraws to fight another day.", N))
		# R49 fairness: what a Corsair raid took (credits and a towed ship) comes back when he dies
		if jt(N.get("dead")) and jt(N.get("loot")):
			RUN["credits"] = float(RUN["credits"]) + float(N["loot"]); out.append("You take back " + numstr(N["loot"]) + " credits from his hold."); N["loot"] = 0
		if jt(N.get("dead")) and jt(N.get("held")):
			RUN["fleet"].append(N["held"]); out.append("You take back the " + str(N["held"]["name"]) + "."); N["held"] = null
		if float(RUN["sector"]) >= 3 and not back:   # R41: the last meeting won (dead, fled or withdrawn) ends the arc
			var u = arcComplete(RUN["fac"])
			if u != "": out.append(u)
	else:
		N["clock"] = 1; N["gloat"] = "flagship" if jt(o.get("myFlagDead")) else ("retreat" if result == "retreat" else "loss")
		out.append(nemSay(nemFull() + " drove you off. He will remember this.", N))
	if jt(beh.get("adaptFast")):
		var a = nemAdapt()
		if a != null:
			nemSignature("fast_adapt"); out.append(P["He"] + " learns from it at once: " + nemAdaptName(a, N["fac"]) + " (" + nemSay(nemAdaptWhy(a, N["fac"]), N) + ").")
	return out
# R42: when you beat him with something, his next adaptation counters it (so "it will not work twice" is true when he says it)
const NEM_BEAT_SEEN = {"lance": "lance", "torp": "torp", "sq": "sq", "ram": "ram", "board": "board", "battery": "battery", "evasive": "evaded"}
func nemBeatTeach(beat) -> void:
	var N = RUN.get("nem"); var k = NEM_BEAT_SEEN.get(beat) if beat != null else null
	if not jt(N) or k == null: return
	if not (N.get("seen") is Dictionary): N["seen"] = {}
	N["seen"][k] = float(z0(N["seen"].get(k))) + 8
# weaknesses you found in battle by triggering them (B.nemFound) are known from then on
func nemFoundMerge(list) -> Array:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N) or not (list is Array) or list.is_empty(): return []
	var out = []
	for k in list:
		if N["weak"].has(k) and not N["revealed"].has(k):
			N["revealed"].append(k); out.append(k)
	return out
# the Chorus Nemesis grows from every ship you lose, anywhere
func nemFeedLosses(n) -> String:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N) or jt(N.get("dead")) or not jt(n) or not jt(nemBeh().get("feeds")): return ""
	var f0 = float(z0(N.get("fed"))); N["fed"] = min(8.0, f0 + float(n))
	if float(N["fed"]) == f0: return ""
	nemSignature("feed")
	return nemFull() + " feeds on your losses: " + nemPr(N)["his"] + " fleet is now " + numstr(jsround(min(0.32, 0.04 * float(N["fed"])) * 100)) + "% tougher (fed " + numstr(N["fed"]) + " of 8)."
# R41: finishing a faction's story arc (its Nemesis's last fight, beat 3) unlocks that faction's arc hull variant for every later run
func arcComplete(fac) -> String:
	var id = ARC_VARIANT.get(fac) if fac != null else null
	if not jt(id): return ""
	META["variants"] = or_(META.get("variants"), {})
	if jt(META["variants"].get(id)): return ""
	META["variants"][id] = true; tel("arc_unlock", {"fac": fac, "id": id}); persist_save(true)
	return "Story complete: the " + str(HULL_VARIANTS[id]["n"]) + " is now sold in your shipyards."
# the way you beat him last time, from that battle's usage (what he remembers and says)
func nemBeatOf(usage, evasive: bool) -> Variant:
	if not jt(usage): return null
	var k = usage["kind"] if usage.get("kind") is Dictionary else {}
	var c = {"lance": float(z0(k.get("lance"))), "torp": float(z0(k.get("torp"))) * 2, "sq": float(z0(k.get("sq"))), "battery": float(z0(k.get("battery"))),
		"ram": float(z0(usage.get("ram"))) * 3, "board": float(z0(usage.get("board"))) * 3, "evasive": 8.0 if evasive else 0.0}
	var top = ssort(c.keys(), func(a, b): return c[b] - c[a])[0]
	return top if c[top] > 0 else null
# what a finished battle teaches him (counted into RUN.nem.seen; read at the next sector)
func nemLearn(usage, evadedShare) -> void:
	var N = RUN.get("nem") if RUN != null else null
	if not jt(N) or not jt(usage): return
	if not (N.get("seen") is Dictionary): N["seen"] = {}
	var s = N["seen"]; var k = usage["kind"] if usage.get("kind") is Dictionary else {}
	for x in ["lance", "torp", "battery"]: s[x] = float(z0(s.get(x))) + float(z0(k.get(x)))
	s["ion"] = float(z0(s.get("ion"))) + float(z0(usage.get("ion"))); s["sq"] = float(z0(s.get("sq"))) + float(z0(k.get("sq")))
	s["ram"] = float(z0(s.get("ram"))) + float(z0(usage.get("ram"))); s["board"] = float(z0(s.get("board"))) + float(z0(usage.get("board")))
	var fire = usage.get("fire") if usage.get("fire") is Dictionary else null
	var br = (float(z0(fire.get("Port broadside"))) + float(z0(fire.get("Starboard broadside")))) if jt(fire) else 0.0
	s["broad"] = float(z0(s.get("broad"))) + br; s["evaded"] = float(z0(s.get("evaded"))) + float(z0(evadedShare))
# ---------- B4 faction campaign verbs ----------
func verbFor() -> Variant:
	if RUN == null: return null
	return FAC_VERBS[RUN["fac"]] if FAC_VERBS.has(RUN["fac"]) else null
func verbFree(V) -> bool: return jt(V) and jt(V.get("free")) and RUN.get("flags") is Dictionary and RUN["flags"].get(V["free"]) != null
func verbCanUse() -> bool:
	var V = verbFor()
	if not jt(V) or float(z0(RUN.get("verbUsed"))) >= float(RUN["sector"]): return false
	if verbFree(V): return true
	var c = V["cost"] if V.get("cost") is Dictionary else {}
	if jt(c.get("cred")) and float(RUN["credits"]) < float(c["cred"]): return false
	if jt(c.get("mod")) and RUN["inventory"].size() == 0: return false
	if jt(c.get("xp")):
		var f = flagshipOf()
		if f == null and RUN["fleet"].size() > 0: f = RUN["fleet"][0]
		if f == null or float(f["cap"]["xp"]) < float(c["xp"]): return false
	return true
func verbCostText(V) -> String:
	if verbFree(V): return "Free (" + str(V["freeD"]) + ")"
	var c = V["cost"] if V.get("cost") is Dictionary else {}; var p = []
	if jt(c.get("cred")): p.append(numstr(c["cred"]) + " credits")
	if jt(c.get("mod")): p.append("a refit from the hold")
	if jt(c.get("xp")): p.append(numstr(c["xp"]) + " experience from your flagship captain")
	return ("Costs " + ", ".join(PackedStringArray(p))) if p.size() > 0 else "No cost"
# apply the verb now; next-battle verbs wait in RUN.verbNext until battleScreen hands them to the fight
func useVerb() -> Variant:
	var V = verbFor()
	if not verbCanUse(): return null
	var free = verbFree(V); var c = V["cost"] if V.get("cost") is Dictionary else {}; var out = []
	if not free:
		if jt(c.get("cred")): RUN["credits"] = float(RUN["credits"]) - float(c["cred"])
		if jt(c.get("mod")): out.append("The " + modName(RUN["inventory"].pop_at(0)) + " is consumed.")
		if jt(c.get("xp")):
			var f = flagshipOf()
			if f == null: f = RUN["fleet"][0]
			f["cap"]["xp"] = max(float(z0(RANK_XP[int(f["cap"]["rank"])])), float(f["cap"]["xp"]) - float(c["xp"]))
	RUN["verbUsed"] = RUN["sector"]
	if not (RUN.get("flags") is Dictionary): RUN["flags"] = {}
	RUN["flags"]["verb_" + str(V["id"])] = float(z0(RUN["flags"].get("verb_" + str(V["id"])))) + 1
	if jt(V.get("next")):
		RUN["verbNext"] = V["id"]; out.append(str(V["n"]) + ": " + str(V["d"]))
	if V["id"] == "shake":
		var g = 30.0 + 10.0 * float(z0(RUN["flags"].get("greed"))); RUN["credits"] = float(RUN["credits"]) + g; out.append("+" + numstr(g) + " credits.")
		var m = nemClockAdd(1)
		if m != "": out.append(m)
		RUN["flags"]["greed"] = float(z0(RUN["flags"].get("greed"))) + 1
	if V["id"] == "gorge":
		var fr = 0.3 if RUN["flags"].get("spawn") == "feed" else 0.2
		for s in RUN["fleet"]:
			var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * fr))
		out.append("Every ship regrows " + pct(fr) + " of its hull.")
	return out
func ACT_factionVerb() -> void:
	var lines = useVerb()
	if lines == null: return
	saveRun(); mapScreen(); toast(" ".join(PackedStringArray(lines)))
# ---------- B4 wing veterancy (kept on the carrier ship between battles) ----------
func wingPerkGrant(ship, id = null) -> Variant:
	if not (ship.get("wingVet") is Dictionary): ship["wingVet"] = {"kills": 0, "perks": []}
	var v = ship["wingVet"]
	if v["perks"].size() >= 3: return null
	var pool = WING_PERKS.keys().filter(func(k): return not v["perks"].has(k))
	var got = id if (jt(id) and pool.has(id)) else pick(pool)
	v["perks"].append(got); return got
# wing kills earn perks at WING_XP thresholds; returns the perks gained
func wingVetAfter(ship, kills) -> Array:
	if not (ship.get("wingVet") is Dictionary): ship["wingVet"] = {"kills": 0, "perks": []}
	var v = ship["wingVet"]; v["kills"] = float(v["kills"]) + float(kills); var out = []
	while v["perks"].size() < 3 and float(v["kills"]) >= float(WING_XP[v["perks"].size()]):
		var g = wingPerkGrant(ship)
		if g == null: break
		out.append(g)
	return out
func randShip() -> Variant: return pick(RUN["fleet"])
func _noop() -> void: pass
func _pop_rand_mod(sh, got: Array) -> void: got.append(sh["mods"].pop_at(int(floor(rnd() * sh["mods"].size()))))
func applyOutcome(r) -> Array:
	var out = []
	if r is String and r == "derelictBoard":
		if rnd() < 0.6:
			var m = randomModule(); RUN["inventory"].append(m); RUN["credits"] = float(RUN["credits"]) + 40
			out.append("Your boarding parties return with a " + modName(m) + " and 40 credits of salvage.")
		else:
			var s = randShip(); var d = derive(s); var dm = jsround(float(d["maxHp"]) * 0.25); s["hp"] = max(1.0, float(s["hp"]) - dm); RUN["credits"] = float(RUN["credits"]) + 20
			out.append("Something was awake. The " + str(s["name"]) + " takes " + numstr(dm) + " hull damage covering the retreat. You salvage 20 credits.")
		return out
	if not (r is Dictionary): r = {}
	if jt(r.get("cost")): RUN["credits"] = float(RUN["credits"]) - float(r["cost"])
	if jt(r.get("cred")):
		RUN["credits"] = float(RUN["credits"]) + float(r["cred"]); out.append("+" + numstr(r["cred"]) + " credits.")
	if jt(r.get("xp")):
		for s in RUN["fleet"]: addXp(s, r["xp"])
		out.append("Every captain gains " + numstr(r["xp"]) + " experience.")
	if jt(r.get("xpLow")):
		var s = ssort(RUN["fleet"].duplicate(), func(a, b): return float(a["cap"]["xp"]) - float(b["cap"]["xp"]))[0]
		addXp(s, r["xpLow"]); out.append(str(s["cap"]["name"]) + " of the " + str(s["name"]) + " gains " + numstr(r["xpLow"]) + " experience.")
	if jt(r.get("loseMod")):
		var withMod = RUN["fleet"].filter(func(s): return s["mods"].size() > 0)
		if withMod.size() > 0:
			var s = pick(withMod); var got = []
			changeShip(s, _pop_rand_mod.bind(got))
			out.append("The " + str(s["name"]) + " gives up its " + modName(got[0]) + ".")
		elif RUN["inventory"].size() > 0:
			var m = RUN["inventory"].pop_at(0); out.append("You hand over the " + modName(m) + " from the hold.")
		else: out.append("You have no refits to give. The seer smiles and gives anyway.")
	if jt(r.get("relic")):
		var rl = randomRelic()
		if rl != null:
			RUN["relics"].append(rl); changeFleet(_noop); out.append("Relic gained: " + relicName(rl) + ". " + str(RELICS[rl]["d"]))
		else:
			RUN["credits"] = float(RUN["credits"]) + 80; out.append("No relics left to find. +80 credits instead.")
	if jt(r.get("dmgOne")):
		var s = randShip(); var d = derive(s); var dm = jsround(float(d["maxHp"]) * float(r["dmgOne"])); s["hp"] = max(1.0, float(s["hp"]) - dm)
		out.append("The " + str(s["name"]) + " takes " + numstr(dm) + " hull damage.")
	if jt(r.get("dmgAll")):
		for s in RUN["fleet"]: s["hp"] = max(1.0, float(s["hp"]) - jsround(float(derive(s)["maxHp"]) * float(r["dmgAll"])))
		out.append("Every ship takes " + pct(r["dmgAll"]) + " hull damage.")
	if jt(r.get("ship")):
		var tp = equivHull(r["ship"], RUN["fac"])
		if fleetCP() + float(HULLS[tp]["cp"]) <= float(RUN["cpCap"]):
			var s = newShip(tp, r.get("vet")); RUN["fleet"].append(s)
			out.append("The " + str(s["name"]) + " joins the fleet under " + rankName(s["cap"]) + " " + str(s["cap"]["name"]) + ".")
		else:
			RUN["credits"] = float(RUN["credits"]) + float(z0(r.get("cost"))); out.append("You don’t have the command points to take her on. Your credits are returned.")
	if jt(r.get("upgradeOne")):
		var s = ssort(RUN["fleet"].duplicate(), func(a, b): return float(a["hp"]) / float(derive(a)["maxHp"]) - float(b["hp"]) / float(derive(b)["maxHp"]))[0]
		changeShip(s, _mk_up3)
		s["hp"] = derive(s)["maxHp"]; out.append("The " + str(s["name"]) + " leaves the forge fully repaired at Mk " + roman(s["mk"]) + ".")
	if jt(r.get("healAll")):
		for s in RUN["fleet"]:
			var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * float(r["healAll"])))
		out.append("Every ship is fully repaired." if float(r["healAll"]) >= 1 else "Every ship repairs " + pct(r["healAll"]) + " of its hull.")
	if jt(r.get("gamble")):
		if rnd() < 0.5:
			for s in RUN["fleet"]:
				var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * 0.3))
			out.append("The saint answers. Every ship repairs 30% of its hull.")
		else: out.append("Silence. The void keeps its own counsel.")
	if jt(r.get("mod")):
		var m = randomModule(); RUN["inventory"].append(m); out.append("Found: " + modName(m) + ". It’s in the hold.")
	if jt(r.get("ambush")): RUN["ambush"] = true
	# B4 outcome kinds: more currencies and the Nemesis
	if jt(r.get("payMod")):
		if RUN["inventory"].size() > 0:
			var m = RUN["inventory"].pop_at(0); out.append("The " + modName(m) + " from the hold is used up.")
	if jt(r.get("payXp")):
		var f = flagshipOf()
		if f == null and RUN["fleet"].size() > 0: f = RUN["fleet"][0]
		if f != null:
			f["cap"]["xp"] = max(float(z0(RANK_XP[int(f["cap"]["rank"])])), float(f["cap"]["xp"]) - float(r["payXp"])); out.append(str(f["cap"]["name"]) + " loses " + numstr(r["payXp"]) + " experience.")
	if jt(r.get("payRelic")):
		if RUN["relics"].size() > 0:
			var rl = RUN["relics"].pop_back(); changeFleet(_noop); out.append("You give up " + relicName(rl) + ".")
	if jt(r.get("repairOne")):
		var srt = ssort(RUN["fleet"].duplicate(), func(a, b): return float(a["hp"]) / float(derive(a)["maxHp"]) - float(b["hp"]) / float(derive(b)["maxHp"]))
		var ix = 1 if (jt(r.get("upgradeOne")) and RUN["fleet"].size() > 1) else 0
		var s = srt[ix] if ix < srt.size() else null
		if s != null:
			s["hp"] = derive(s)["maxHp"]; out.append("The " + str(s["name"]) + " is fully repaired.")
	if jt(r.get("dmgBig")):
		var srt = ssort(RUN["fleet"].duplicate(), func(a, b): return float(or_(HULLS[b["tpl"]].get("cp"), 1)) - float(or_(HULLS[a["tpl"]].get("cp"), 1)))
		if srt.size() > 0:
			var s = srt[0]; var dm = jsround(float(derive(s)["maxHp"]) * float(r["dmgBig"])); s["hp"] = max(1.0, float(s["hp"]) - dm)
			out.append("The " + str(s["name"]) + " takes " + numstr(dm) + " hull damage.")
	if jt(r.get("xpTop")):
		var srt = ssort(RUN["fleet"].duplicate(), func(a, b): return float(b["cap"]["xp"]) - float(a["cap"]["xp"]))
		if srt.size() > 0:
			var s = srt[0]; addXp(s, r["xpTop"]); out.append(str(s["cap"]["name"]) + " of the " + str(s["name"]) + " gains " + numstr(r["xpTop"]) + " experience.")
	if jt(r.get("modId")) and MODULES.has(r["modId"]):
		RUN["inventory"].append(r["modId"]); out.append("Found: " + modName(r["modId"]) + ". It’s in the hold.")
	if jt(r.get("shipRaw")) and HULLS.has(r["shipRaw"]):
		if fleetCP() + float(or_(HULLS[r["shipRaw"]].get("cp"), 1)) <= float(RUN["cpCap"]):
			var s = newShip(r["shipRaw"], r.get("vet")); RUN["fleet"].append(s)
			out.append("The " + str(s["name"]) + " joins the fleet under " + rankName(s["cap"]) + " " + str(s["cap"]["name"]) + ".")
		else:
			RUN["credits"] = float(RUN["credits"]) + 40; out.append("No command points to crew her. You sell the berth for 40 credits.")
	if jt(r.get("wingPerk")):
		var cs = ssort(RUN["fleet"].filter(func(s): return jt(HULLS[s["tpl"]].get("hangar"))), func(a, b): return float(or_(HULLS[b["tpl"]].get("cp"), 1)) - float(or_(HULLS[a["tpl"]].get("cp"), 1)))
		if cs.size() > 0:
			var c = cs[0]; var got = wingPerkGrant(c)
			out.append(("The " + str(c["name"]) + "’s wings gain a veteran perk: " + str(WING_PERKS[got]["n"]) + ".") if got != null else ("The " + str(c["name"]) + "’s wings already hold every perk they can."))
	if jt(r.get("nemIntel")):
		var w = nemReveal()
		out.append(("Nemesis weakness revealed: " + str(NEM_WEAK[w]["n"]) + ". " + str(NEM_WEAK[w]["d"])) if w != null else "You learn nothing new about the enemy commander.")
	if jt(r.get("nemClock")):
		var m2 = nemClockAdd(r["nemClock"])
		if m2 != "": out.append(m2)
	if out.size() == 0 and not jt(r.get("fight")): out.append("You move on.")
	return out
# Story arcs: after the sector intro (beat 1) and each sector change (beats 2 and 3), the arc card opens as an event.
func _arc_after(md) -> bool:
	if not arcs_on or not (arc_source is Callable) or not (arc_source as Callable).is_valid() or RUN == null: return false
	if md == null or not (md.get("kind") in ["intro", "sector"]): return false
	var card = arc_source.call(int(RUN["sector"]))
	if not (card is Dictionary) or card.is_empty() or not (card.get("o") is Array) or card["o"].is_empty(): return false
	cur_event = card.duplicate(false); cur_event["arc"] = true
	var acts = []
	for i in range(cur_event["o"].size()):
		A(acts, "eventChoice", i, eventOptOk(cur_event["o"][i]))
	show_modal("event", {"ev": cur_event}, acts)
	return true
func _arc_choice(o, i: int) -> void:   # an arc card's choice: its outcome and flags, no map node is completed
	var r = o["r"] if o.get("r") is Dictionary else {}
	var lines = applyOutcome(r)
	var k = str(o["k"]) if jt(o.get("k")) else str(i)
	var out = cur_event.get("outs", {}).get(k, "") if cur_event.get("outs") is Dictionary else ""
	if str(out) != "": lines.insert(0, str(out))
	if lines.has("You move on."): lines.erase("You move on.")
	if arc_chose_cb is Callable and (arc_chose_cb as Callable).is_valid(): arc_chose_cb.call(cur_event, k)
	saveRun(); mapScreen()
	var acts = []; A(acts, "closeModal")
	show_modal("event_result", {"ev": cur_event, "lines": lines}, acts)
func _arc_played(beat: int) -> bool:
	if RUN == null or not (RUN.get("flags") is Dictionary): return false
	var pre = "arc_" + str(RUN["fac"]) + "_" + str(beat)
	for k in RUN["flags"].keys():
		if str(k).begins_with(pre): return true
	return false
func ACT_eventChoice(a: String) -> void:
	var i = int(a)
	var o = cur_event["o"][i] if (i >= 0 and i < cur_event["o"].size()) else null
	if o == null or not eventOptOk(o): return
	eventFlags(cur_event, o, i)
	if jt(cur_event.get("arc")):
		_arc_choice(o, i); return
	var r = o["r"]
	if r is Dictionary and jt(r.get("fight")):
		close_modal(); battleScreen({"kind": "elite", "fac": r["fight"], "col": float(findNode(RUN["curNode"])["col"]) + 1, "node": RUN["curNode"], "eventRelic": true}); return
	var lines = applyOutcome(r)
	completeNode(); mapScreen()
	var acts = []; A(acts, "closeModal")
	show_modal("event_result", {"ev": cur_event, "lines": lines}, acts)

# ---------------- rewards ----------------
func rewardFlow(summary: Dictionary) -> void:
	var cfg = summary["cfg"]; var s = float(RUN["sector"]); var rf = runFx()
	RUN["stats"]["battles"] = float(RUN["stats"]["battles"]) + 1
	if cfg["kind"] == "elite": RUN["stats"]["elites"] = float(RUN["stats"]["elites"]) + 1
	if cfg["kind"] == "boss": RUN["stats"]["bosses"] = float(RUN["stats"]["bosses"]) + 1
	var kindMult = 3.0 if cfg["kind"] == "boss" else (1.6 if cfg["kind"] == "elite" else 1.0)
	var scnd = sectorCond()
	var credits = jsround((25.0 + 12.0 * s + 3.0 * float(z0(cfg.get("col")))) * kindMult * (1.0 + float(z0(rf.get("credPct"))) + float(z0(scnd.get("cred") if scnd != null else null))))
	if cfg.get("mod") == "bounty": credits = jsround(credits * 1.5)
	if jt(summary.get("partial")): credits = jsround(credits / 2.0)
	if jt(rf.get("salvage")):
		credits += 15
		for sh in RUN["fleet"]:
			var d = derive(sh); sh["hp"] = min(float(d["maxHp"]), float(sh["hp"]) + jsround(float(d["maxHp"]) * 0.08))
	RUN["credits"] = float(RUN["credits"]) + credits
	var node = findNode(cfg["node"]) if jt(cfg.get("node")) else null
	ensurePatrons()
	var rw
	if node != null and jt(node.get("rw")): rw = node["rw"]
	elif cfg["kind"] == "battle": rw = {"k": "boon", "p": pick(RUN["patrons"])}
	else: rw = {"k": "boon", "p": pick(RUN["patrons"]), "min": 1}
	var fl0 = RUN.get("flagUid"); ensureFlagship()
	var flagMoved = flagshipOf() if (jt(fl0) and RUN.get("flagUid") != fl0) else null
	var extra = ""
	if rw["k"] == "cred":
		var v = 35.0 + 10.0 * s; RUN["credits"] = float(RUN["credits"]) + v; extra = "Salvage: +" + numstr(v) + " credits."
	if rw["k"] == "repair":
		for sh in RUN["fleet"]:
			var d = derive(sh); sh["hp"] = min(float(d["maxHp"]), float(sh["hp"]) + jsround(float(d["maxHp"]) * 0.25 * repairMult()))
		extra = "Field repairs: every ship repairs 25% of its hull."
	W["rewardCfg"] = cfg; W["rw"] = rw; W["boonOffer"] = null; W["modOffer"] = null
	if cfg["kind"] == "elite" or cfg["kind"] == "boss":
		W["relicChoice"] = shuffle(RELICS.keys().filter(func(r): return not RUN["relics"].has(r) and relicUseful(r))).slice(0, 3 if cfg["kind"] == "boss" else 2)
	else: W["relicChoice"] = []
	var wr = []
	for w in or_(summary.get("wrecks"), []):
		w["yield"] = salvageYield(w); wr.append(w)
	W["wrecks"] = wr
	var prizes = or_(summary.get("prizes"), []).filter(func(p): return p != null and HULLS.has(p.get("tpl")))
	RUN["reward"] = {"kind": cfg["kind"], "node": cfg.get("node"), "rw": rw, "relics": W["relicChoice"], "wrecks": W["wrecks"], "prizes": prizes,
		"stage": "prize" if prizes.size() > 0 else ("salvage" if W["wrecks"].size() > 0 else "pick"), "boonOffer": null, "modOffer": null}
	completeNode()
	var acts = []
	if RUN["reward"]["prizes"].size() > 0: A(acts, "prizeStep")
	elif W["wrecks"].size() > 0: A(acts, "salvageStep")
	else: A(acts, "rewardNext")
	show_modal("victory", {"summary": summary, "credits": credits, "extra": extra, "flagMoved": flagMoved, "rw": rw}, acts)
func salvageYield(w: Dictionary) -> Dictionary:
	var pool = modulePool(); var wk = or_(w.get("wk"), [])
	var cand = []
	if wk.has("lance"): cand.append("crystal")
	if wk.has("torp") or wk.has("htorp") or wk.has("startorp"): cand.append("magazine")
	if wk.has("battery") or wk.has("hbattery"): cand.append("loaders")
	if wk.has("flak"): cand.append("flakplus")
	if w.get("ab") == "launch": cand.append("hangar")
	if wk.has("gauss") or wk.has("needle") or wk.has("shard"): cand.append("cogitator")
	if jt(w.get("regen")): cand.append("damcon")
	if float(z0(w.get("sh"))) >= 20: cand.append("capacitor")
	if wk.has("turret") or wk.has("autocannon"): cand.append("auspex")
	var pickM = cand.filter(func(m): return pool.has(m) and MODULES.has(m))
	var kc = KILL_CAUSES.get(w.get("cause")) if w.get("cause") != null else null
	var intact = not (kc != null and jt(kc.get("scrap")))
	var m = pickM[0] if (intact and pickM.size() > 0) else null
	var cred = jsround((10.0 + 9.0 * float(w["cp"])) * (1.0 if intact else 1.3))
	var tow = RUN != null and RUN["fac"] == "corsair" and float(w["cp"]) <= 2 and intact and w.get("cause") != "dark" and HULLS.has(w.get("tpl")) and factionGate(RUN["fac"], w["tpl"]) == null and fleetCP() + float(or_(HULLS[w["tpl"]].get("cp"), 1)) <= float(RUN["cpCap"])
	return {"mod": m, "cred": cred, "tow": tow}
func prizeRansom(p: Dictionary, n) -> float:
	return jsround(shipValue(p["tpl"]) * 0.55 * (0.6 + 0.4 * float(or_(p.get("hpf"), 1))) * max(0.4, pow(0.85, float(z0(n)))))
func prizeOffer(p: Dictionary, nR) -> Dictionary:
	var v = shipValue(p["tpl"])
	var y = salvageYield({"wk": or_(p.get("wk"), []), "ab": p.get("ab"), "regen": p.get("regen"), "sh": p.get("sh"), "cp": p.get("cp"), "tpl": p["tpl"], "cause": "board"})
	var pool = modulePool()
	var mod = y["mod"]
	if not jt(mod): mod = pool[int(floor(fmod(v * 7.0 + float(or_(p.get("cp"), 1)) * 13.0, float(pool.size()))))] if pool.size() > 0 else null
	return {"fits": fleetCP() + float(or_(p.get("cp"), 1)) <= float(RUN["cpCap"]), "ransom": prizeRansom(p, RUN.get("ransoms") if nR == null else nR), "strip": {"mod": mod, "cred": jsround(v * 0.15)}}
func prizePlan(R: Dictionary) -> Array:
	var sel = or_(R.get("prizeSel"), []); var cp = fleetCP(); var nR = float(z0(RUN.get("ransoms")))
	var rows = []
	for i in range(R["prizes"].size()):
		var p = R["prizes"][i]; var o = prizeOffer(p, nR); var c = float(or_(p.get("cp"), 1)); var gate = factionGate(RUN["fac"], p["tpl"]); var room = cp + c <= float(RUN["cpCap"]) and gate == null   # B3: a prize your faction cannot field can only be stripped or ransomed
		var sv = float(o["strip"]["cred"]) + (jsround(float(MODULES[o["strip"]["mod"]]["cost"]) * 0.5) if jt(o["strip"]["mod"]) else 0.0)
		var dk = "add" if (room and float(or_(p.get("hpf"), 1)) >= 0.4) else ("strip" if sv >= float(o["ransom"]) else "ransom")
		var s_i = sel[i] if i < sel.size() else null
		var k = s_i if jt(s_i) else dk
		if k == "add" and not room: k = ("strip" if sv >= float(o["ransom"]) else "ransom") if dk == "add" else dk
		if k == "add": cp += c
		if k == "ransom": nR += 1
		rows.append({"p": p, "o": o, "room": room, "gate": gate, "k": k, "mine": jt(s_i) and s_i == k})
	return rows
func ACT_prizeStep() -> void:
	close_modal()
	var R = RUN.get("reward")
	if R == null or or_(R.get("prizes"), []).size() == 0:
		var ws = or_(W.get("wrecks"), [])
		if R != null: R["stage"] = "salvage" if ws.size() > 0 else "pick"
		if ws.size() > 0: ACT_salvageStep()
		else: ACT_rewardNext()
		return
	var rows = prizePlan(R)
	var acts = []
	for i in range(rows.size()):
		A(acts, "prizeSet", str(i) + ":add", rows[i]["room"]); A(acts, "prizeSet", str(i) + ":strip"); A(acts, "prizeSet", str(i) + ":ransom")
	A(acts, "prizeConfirm")
	show_modal("prize", {"rows": rows}, acts)
func ACT_prizeSet(a: String) -> void:
	var R = RUN.get("reward")
	if R == null or or_(R.get("prizes"), []).size() == 0: return
	var p = a.split(":"); var i = int(p[0]); var k = p[1] if p.size() > 1 else ""
	if i < 0 or i >= R["prizes"].size() or not (k in ["add", "strip", "ransom"]): return
	R["prizeSel"] = or_(R.get("prizeSel"), [])
	while R["prizeSel"].size() <= i: R["prizeSel"].append(null)
	R["prizeSel"][i] = k; saveRun(); ACT_prizeStep()
func ACT_prizeConfirm() -> void:
	var R = RUN.get("reward")
	if R == null or or_(R.get("prizes"), []).size() == 0:
		ACT_prizeStep(); return
	var rows = prizePlan(R); var got = []
	for r in rows:
		var p = r["p"]; var o = r["o"]
		if r["k"] == "add":
			var sh = newShip(p["tpl"]); sh["name"] = p["name"]; var mx = float(derive(sh)["maxHp"]); sh["hp"] = clampv(jsround(mx * float(or_(p.get("hpf"), 1))), 1, mx)
			RUN["fleet"].append(sh); got.append("the " + str(p["name"]) + " joins")
		elif r["k"] == "strip":
			if jt(o["strip"]["mod"]): RUN["inventory"].append(o["strip"]["mod"])
			RUN["credits"] = float(RUN["credits"]) + float(o["strip"]["cred"]); got.append("the " + str(p["name"]) + " is stripped (+" + numstr(o["strip"]["cred"]) + ")")
		else:
			RUN["credits"] = float(RUN["credits"]) + float(o["ransom"]); RUN["ransoms"] = float(z0(RUN.get("ransoms"))) + 1; got.append("the " + str(p["name"]) + " is ransomed (+" + numstr(o["ransom"]) + ")")
		tel("prize_pick", {"k": r["k"], "tpl": p["tpl"], "def": not r["mine"]})
	R["prizes"] = []; R["prizeSel"] = null; saveRun()
	var t = ", ".join(PackedStringArray(got))
	if t != "": toast(t.substr(0, 1).to_upper() + t.substr(1) + ".")
	ACT_prizeStep()
func ACT_salvageStep() -> void:
	close_modal()
	var ws = or_(W.get("wrecks"), [])
	var acts = []
	for i in range(ws.size()):
		var y = ws[i]["yield"]
		if jt(y.get("mod")): A(acts, "takeSalvage", str(i) + ":mod")
		A(acts, "takeSalvage", str(i) + ":cred")
		if jt(y.get("tow")): A(acts, "takeSalvage", str(i) + ":tow")
	show_modal("salvage", {"wrecks": ws}, acts)
func ACT_takeSalvage(a: String) -> void:
	var p = a.split(":"); var i = int(p[0]); var k = p[1] if p.size() > 1 else ""
	var ws = or_(W.get("wrecks"), []); var w = ws[i] if i >= 0 and i < ws.size() else null
	if w == null:
		close_modal()
		if RUN.get("reward") != null: RUN["reward"]["stage"] = "pick"
		ACT_rewardNext(); return
	var y = w["yield"]
	if k == "mod" and jt(y.get("mod")):
		RUN["inventory"].append(y["mod"]); toast(modName(y["mod"]) + " stripped from the " + str(w["name"]) + " and stowed in the hold.")
	elif k == "tow" and jt(y.get("tow")) and HULLS.has(w.get("tpl")) and fleetCP() + float(or_(HULLS[w["tpl"]].get("cp"), 1)) > float(RUN["cpCap"]):
		RUN["credits"] = float(RUN["credits"]) + float(y["cred"]); toast("No command points to crew " + ("" if str(w["name"]).begins_with("The ") else "the ") + str(w["name"]) + ". She is broken up for scrap: +" + numstr(y["cred"]) + " credits.")
	elif k == "tow" and jt(y.get("tow")):
		var sh = newShip(w["tpl"]); sh["name"] = w["name"]; sh["hp"] = max(1.0, jsround(float(derive(sh)["maxHp"]) * 0.35)); RUN["fleet"].append(sh)
		toast("The " + str(w["name"]) + " is under tow. Patch her up at a shipyard.")
	else:
		RUN["credits"] = float(RUN["credits"]) + float(y["cred"]); toast(("" if str(w["name"]).begins_with("The ") else "The ") + str(w["name"]) + " is broken up for scrap: +" + numstr(y["cred"]) + " credits.")
	tel("salvage_pick", {"k": k, "cause": w.get("cause")})
	W["wrecks"] = []
	if RUN.get("reward") != null:
		RUN["reward"]["wrecks"] = []; RUN["reward"]["stage"] = "pick"
	saveRun(); close_modal(); ACT_rewardNext()
func ACT_rewardNext() -> void:
	var rw = or_(W.get("rw"), {}); close_modal()
	if rw.get("k") == "boon":
		boonStep(rw.get("p"), z0(rw.get("min"))); return
	if rw.get("k") == "mod":
		var opts = RUN["reward"]["modOffer"] if (RUN.get("reward") != null and RUN["reward"].get("modOffer") != null) else shuffle(modulePool()).slice(0, 3)
		W["modOffer"] = opts
		if RUN.get("reward") != null and RUN["reward"].get("modOffer") == null:
			RUN["reward"]["modOffer"] = opts; saveRun()
		var acts = []
		for m in opts: A(acts, "takeMod", m)
		show_modal("mod", {"opts": opts}, acts); return
	relicStep()
func ACT_takeMod(m: String) -> void:
	RUN["inventory"].append(m); tel("reward_pick", {"k": "mod", "id": m}); toast(modName(m) + " stowed in the hold."); close_modal(); relicStep()
func boonStep(p, minR) -> void:
	if not PATRONS.has(p):
		relicStep(); return
	var offer = RUN["reward"]["boonOffer"] if (RUN.get("reward") != null and RUN["reward"].get("boonOffer") != null) else rollBoonOffer(p, minR)
	W["boonOffer"] = offer
	if RUN.get("reward") != null and RUN["reward"].get("boonOffer") == null:
		RUN["reward"]["boonOffer"] = offer; saveRun()
	if offer.size() == 0:
		RUN["credits"] = float(RUN["credits"]) + 60; toast("Nothing left to offer. +60 credits."); relicStep(); return
	var acts = []
	for i in range(offer.size()): A(acts, "takeBoon", i)
	A(acts, "boonReroll", str(p) + ":" + numstr(z0(minR)), boonRerollOk()); A(acts, "boonDecline")
	show_modal("boon", {"patron": p, "offer": offer, "rerollCost": boonRerollCost(), "declineCred": boonDeclineCred()}, acts)
# B4 step 3 (v54): decline a boon offer for credits, or reroll it once per reward for a price that grows each time you reroll in a run
func boonDeclineCred() -> float: return 30.0 + 10.0 * float(or_(RUN.get("sector") if RUN != null else null, 1))
func boonRerollCost() -> float: return 25.0 + 15.0 * float(z0(RUN.get("boonRerolls") if RUN != null else null))
func boonRerollOk() -> bool: return RUN != null and RUN.get("reward") != null and not jt(RUN["reward"].get("rerolled")) and float(RUN["credits"]) >= boonRerollCost()
func _offer_ids(off: Array) -> Array:
	var o = []
	for x in off: o.append(x["id"])
	return o
func _all_old(off: Array, old: Array) -> bool:
	for x in off:
		if not old.has(x["id"]): return false
	return true
func boonReroll(p, minR) -> Variant:
	if not boonRerollOk(): return null
	RUN["credits"] = float(RUN["credits"]) - boonRerollCost(); RUN["boonRerolls"] = float(z0(RUN.get("boonRerolls"))) + 1; RUN["reward"]["rerolled"] = true
	var old = _offer_ids(or_(RUN["reward"].get("boonOffer"), []))
	var off = rollBoonOffer(p, minR)
	var k = 0
	while k < 4 and off.size() > 0 and _all_old(off, old):
		off = rollBoonOffer(p, minR); k += 1
	RUN["reward"]["boonOffer"] = off; return off
func boonDecline() -> float:
	var c = boonDeclineCred(); RUN["credits"] = float(RUN["credits"]) + c; return c
func ACT_boonReroll(a: String) -> void:
	var parts = a.split(":"); var p = parts[0]; var m = (float(parts[1]) if parts.size() > 1 and parts[1].is_valid_float() else 0.0)
	if boonReroll(p, m) == null: return
	saveRun(); close_modal(); boonStep(p, m)
func ACT_boonDecline() -> void:
	var c = boonDecline(); tel("boon_decline", {"cred": c}); toast("You decline. +" + numstr(c) + " credits."); close_modal(); relicStep()
func _add_boon(o) -> void:
	RUN["boons"] = or_(RUN.get("boons"), []); RUN["boons"].append({"id": o["id"], "r": z0(o.get("r"))})
func ACT_takeBoon(a: String) -> void:
	var offer = or_(W.get("boonOffer"), []); var i = int(a)
	var o = offer[i] if i >= 0 and i < offer.size() else null
	if o == null: return
	changeFleet(_add_boon.bind(o))
	var ps = [BOONS[o["id"]]["p"]] if jt(BOONS[o["id"]].get("p")) else or_(BOONS[o["id"]].get("duo"), [])
	META["favour"] = or_(META.get("favour"), {})
	for p in ps:
		var t0 = favourTier(p); META["favour"][p] = float(z0(META["favour"].get(p))) + 1 + float(z0(o.get("r"))); var t1 = favourTier(p)
		if t1 > t0: toast(str(PATRONS[p]["n"]) + " now counts you " + str(FAVOUR_TIERS[t1]["n"]) + ": " + str(FAVOUR_TIERS[t1].get("d", "")))
	tel("boon_pick", {"id": o["id"], "r": z0(o.get("r"))})
	toast(str(BOONS[o["id"]]["n"]) + " gained."); close_modal(); relicStep()
func relicStep() -> void:
	if RUN.get("reward") != null and RUN["reward"]["stage"] != "relic" and RUN["reward"]["stage"] != "promo":
		RUN["reward"]["stage"] = "relic"; RUN["reward"]["boonOffer"] = null; RUN["reward"]["modOffer"] = null; saveRun()
	var rc = W.get("relicChoice")
	if rc != null and rc.size() > 0:
		var acts = []
		for r in rc: A(acts, "takeRelic", r)
		show_modal("relic", {"boss": or_(W.get("rewardCfg"), {}).get("kind") == "boss", "opts": rc}, acts); return
	promotionsStep()
func _add_relic(r) -> void: RUN["relics"].append(r)
func ACT_takeRelic(r: String) -> void:
	if not or_(W.get("relicChoice"), []).has(r): return
	changeFleet(_add_relic.bind(r))
	W["relicChoice"] = null
	if RUN.get("reward") != null: RUN["reward"]["relics"] = []
	close_modal(); promotionsStep()
func promotionsStep() -> void:
	if RUN.get("reward") != null:
		RUN["reward"]["stage"] = "promo"; RUN["reward"]["relics"] = []; saveRun()
	for s in RUN["fleet"]:
		if float(z0(s["cap"].get("pending"))) > 0:
			promoteModal(s["uid"], Callable(self, "promotionsStep")); return
	afterBattle()
func resumeReward() -> bool:
	var R = RUN.get("reward") if RUN != null else null
	if R == null: return false
	var rc = {"kind": R.get("kind")}
	if R.get("node") != null: rc["node"] = R["node"]
	W["rewardCfg"] = rc; W["rw"] = or_(R.get("rw"), {}); W["relicChoice"] = or_(R.get("relics"), []); W["wrecks"] = or_(R.get("wrecks"), [])
	W["boonOffer"] = R.get("boonOffer"); W["modOffer"] = R.get("modOffer")
	toast("Picking up your rewards where you left off.")
	if R["stage"] == "prize" and or_(R.get("prizes"), []).size() > 0:
		ACT_prizeStep(); return true
	if R["stage"] == "salvage" and W["wrecks"].size() > 0:
		ACT_salvageStep(); return true
	if R["stage"] == "pick":
		ACT_rewardNext(); return true
	if R["stage"] == "relic":
		relicStep(); return true
	promotionsStep(); return true
func afterBattle() -> void:
	var cfg = W.get("rewardCfg") if W.get("rewardCfg") != null else {"kind": RUN["reward"].get("kind") if RUN.get("reward") != null else null}
	RUN["reward"] = null
	completeNode()
	if cfg.get("kind") == "boss":
		if float(RUN["sector"]) >= 3:
			endRun(true); return
		RUN["sector"] = float(RUN["sector"]) + 1; RUN["cpCap"] = float(RUN["cpCap"]) + 3; RUN["map"] = genSector(int(RUN["sector"])); RUN["pos"] = null
		var na = nemAdapt()   # B4: the Nemesis adapts once per sector
		for s in RUN["fleet"]:
			var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * 0.4 * repairMult()))
		saveRun(); mapScreen()
		var acts = []; A(acts, "closeModal")
		show_modal("sector", {"fac": RUN["map"]["fac"], "cond": sectorCond(), "region": RUN["map"].get("region"), "adapt": na if jt(RUN.get("nem")) else null}, acts)
		return
	mapScreen()

# ======================= campaign3d.js: battles =======================
func nodeSeeds(nodes: Array) -> int:
	var n = 0
	for nd in nodes:
		if nd != null and not jt(nd.get("done")) and nd.get("seed") == null and _is(nd, ["battle", "elite", "boss", "event"]):
			nd["seed"] = floor(rnd() * 4294967296.0); n += 1
	return n
func battleScreen(cfg: Dictionary) -> void:
	close_modal()
	var sn = findNode(cfg["node"]) if jt(cfg.get("node")) else null
	if sn != null:
		nodeSeeds([sn])
		if sn.get("seed") != null and cfg.get("seed") == null:
			var sd = float((int(sn["seed"]) ^ 0x27d4eb2f) & 0xFFFFFFFF) if jt(cfg.get("eventRelic")) else float(sn["seed"])
			cfg = cfg.duplicate(); cfg["seed"] = sd
			JSM.rnd_seed((int(sd) ^ 0x5bd1e995) & 0xFFFFFFFF)
	if RUN["fleet"].size() <= 1 and float(z0(RUN.get("reinf"))) < float(RUN["sector"]):
		RUN["reinf"] = RUN["sector"]; var sh = newShip("warden"); RUN["fleet"].append(sh)
		toast("The sector garrison sends the " + str(sh["name"]) + " to reinforce you."); tel("reinforced", {})
	var nd = findNode(cfg["node"]) if jt(cfg.get("node")) else null
	if nd != null and not jt(nd.get("enc")) and cfg["kind"] != "boss":
		nd.merge(rollEncounter(nd["type"], nd["col"]), true)
		if not jt(nd.get("map")) and RUN.get("map") != null and jt(RUN["map"].get("region")): nd["map"] = regionMap(RUN["map"]["region"], nd["col"], 7)
		fitEncounter(nd)
	var ro
	if cfg["kind"] == "boss": ro = bossEncounter()
	elif nd != null and jt(nd.get("enc")): ro = {"enc": nd["enc"], "shape": nd.get("shape")}
	else: ro = rollEncounter(cfg["kind"], or_(cfg.get("col"), 1))
	var mp = nd.get("map") if nd != null else null
	if not jt(mp) and RUN.get("map") != null and jt(RUN["map"].get("region")): mp = regionMap(RUN["map"]["region"], 6 if cfg["kind"] == "boss" else (nd["col"] if nd != null else 3), 7)
	if not jt(mp): mp = FAC_MAP[cfg["fac"]][0] if (cfg["kind"] == "boss" and FAC_MAP.has(cfg["fac"])) else "random"
	var c = {"map": mp, "dep": "line" if cfg["kind"] == "boss" else pick(["line", "line", "flank"]), "obj": ro["enc"], "shape": ro.get("shape"),
		"arch": nd.get("arch") if (cfg["kind"] != "boss" and nd != null) else null, "mod": nd.get("mod") if (cfg["kind"] != "boss" and nd != null) else null}
	c.merge(cfg, true)
	if jt(RUN.get("verbNext")) and not jt(c.get("verb")): c["verb"] = RUN["verbNext"]   # B4: a next-battle faction verb
	var ext = battle_mode == "external" and battle_setup.is_valid()
	start_battle(c)
	B["campaign"] = true
	if not ext:   # external battles: the rules roll the mid-battle event themselves (rules/API.md, cfg.campaign), in the game's order
		var sc = sectorCond()
		var force = null
		if _nem_reinforce(c):   # R42: a Hegemony Nemesis always brings reinforcements in round 3
			var ev = rollBattleEvent(c, "reinf_enemy"); ev["r"] = 3; B["event"] = ev
		else:
			if sc != null and jt(sc.get("war")) and c["kind"] != "boss": force = "reinf_enemy" if rnd() < 0.6 else "reinf_ally"
			B["event"] = rollBattleEvent(c, force)
	tel("battle_start", {"seed": B.get("seed"), "obj": c["obj"], "kind": c["kind"], "fac": c["fac"]})
	var acts = []
	A(acts, "battle", "win"); A(acts, "battle", "partial"); A(acts, "battle", "loss")
	if c["kind"] != "boss": A(acts, "c3retreat")
	show_page("battle", {"cfg": c}, acts)
	if ext:
		pending_battle = c; battle_requested.emit()
func _nem_reinforce(c) -> bool:
	var nm = c.get("nemesis")
	return jt(nm) and NEM_FAC.has(nm.get("fac")) and NEM_FAC[nm["fac"]]["beh"].get("strike") == "reinforce"
# The one place a battle starts. External mode: battle_setup(run, cfg) builds the real battle (the rules' startBattle, which reseeds
# the shared PRNG from cfg.seed) and returns its B; the battle scene then plays it and calls finish_battle(result).
var battle_setup: Callable = Callable()
func start_battle(c: Dictionary) -> void:
	if battle_mode == "external" and battle_setup.is_valid():
		var c2 = c.duplicate(); c2["campaign"] = true   # the rules roll the mid-battle event right after setup, as campaign3d.js does
		var sc = sectorCond()
		if sc != null and jt(sc.get("war")) and c["kind"] != "boss": c2["event_war"] = true   # sectors at war force reinforcements (G1: draw it after setup)
		B = battle_setup.call(RUN, c2)
	else: stub_start(c)
# External mode: the battle scene reports the end. result is "win", "loss" or "retreat"; battle is the rules' B (units with the JS field names).
func finish_battle(result: String, battle = null) -> void:
	if battle != null: B = battle
	pending_battle = null
	if B == null: return
	if result == "retreat":
		if jt(B.get("campaign")) and not jt(B.get("finished")) and B["cfg"].get("kind") != "boss": finishBattle("retreat")
		return
	B["over"] = result; ACT_c3continue()
func can_retreat() -> bool: return B != null and jt(B.get("campaign")) and not jt(B.get("over")) and B["cfg"].get("kind") != "boss"
func ACT_battle(o: String) -> void:
	if B == null or jt(B.get("over")): return
	stub_resolve(o); ACT_c3continue()
func ACT_c3continue() -> void:
	if B == null or jt(B.get("busy")) or not jt(B.get("over")) or not jt(B.get("campaign")) or jt(B.get("finished")): return
	finishBattle(B["over"])
func ACT_c3retreat() -> void:
	if B == null or jt(B.get("busy")) or jt(B.get("over")) or not jt(B.get("campaign")) or B["cfg"].get("kind") == "boss": return
	var acts = []; A(acts, "c3retreatYes"); A(acts, "c3retreatNo")
	show_modal("retreat", {}, acts)
func _kinds(ws: Array) -> Array:
	var out = []
	for w in ws:
		if not out.has(w.get("k")): out.append(w.get("k"))
	return out
func finishBattle(result: String) -> void:
	if B == null or jt(B.get("finished")): return
	B["finished"] = true
	if result == "loss" and jt(B.get("withdraw")) and B["units"].any(func(u): return u["side"] == "player" and not jt(u.get("dead")) and not jt(u.get("isSq"))): result = "retreat"
	var cfg = B["cfg"]
	var summary = {"cfg": cfg, "xp": [], "lost": [], "kills": 0, "rounds": B["round"], "prizes": [], "partial": jt(B.get("partial")), "boonStats": or_(B.get("boonStats"), {}).duplicate()}
	var wingK = {}
	for u in B["units"]:
		if jt(u.get("parent")):
			for p in B["units"]:
				if p["id"] == u["parent"]:
					p["dealt"] = float(z0(p.get("dealt"))) + float(z0(u.get("dealt"))); p["kills"] = float(z0(p.get("kills"))) + float(z0(u.get("kills")))
					if p.get("ship") != null: wingK[p["ship"]["uid"]] = float(z0(wingK.get(p["ship"]["uid"]))) + float(z0(u.get("kills")))
					break
	# R42: his behaviour that fired in the battle (the browser's nemSig calls the campaign's nemSignature as it happens; the Godot rules
	# keep them in B.nemSigs, so they are recorded here, before anything the campaign adds after the fight)
	if B.get("nemSigs") is Array:
		for sg in B["nemSigs"]: nemSignature(str(sg.get("kind")) if sg is Dictionary else str(sg))
	# B4: the Nemesis learns from how you fought; a used faction verb is spent; his own fight settles here
	var pl = B["units"].filter(func(u): return u["side"] == "player" and not jt(u.get("isSq")))
	var evs = 0.0
	for u in pl: evs += float(z0(u.get("ev")))
	nemLearn(B.get("usage"), 1 if evs / max(1.0, float(pl.size())) >= 20 else 0)
	if B.get("cfg") is Dictionary and jt(B["cfg"].get("verb")): RUN["verbNext"] = null
	if jt(cfg.get("nemesis")):
		var fl = null
		for u in B["units"]:
			if jt(u.get("nemFlag")):
				fl = u; break
		var evasive = evs / max(1.0, float(pl.size())) >= 20
		summary["nem"] = nemAfterBattle(result, fl != null and jt(fl.get("dead")) and not jt(fl.get("fled")), {"fled": jt(B.get("nemFled")), "beat": nemBeatOf(B.get("usage"), evasive), "cause": fl.get("killCause") if fl != null else null, "myFlagDead": B["units"].any(func(u): return jt(u.get("pflag")) and jt(u.get("dead")))})
	elif result == "win" and jt(RUN.get("nem")):
		var m = nemClockAdd(1)
		if m != "": summary["nemWarn"] = m
	var lostN = 0   # R42: a Chorus Nemesis grows from your losses
	for u in B["units"]:
		if u["side"] == "player" and u.get("ship") != null and jt(u.get("dead")) and not jt(u.get("exited")): lostN += 1
	if lostN > 0:
		var fm = nemFeedLosses(lostN)
		if fm != "": summary["nemFeed"] = fm
	var fw = nemFoundMerge(B.get("nemFound"))   # R42: weaknesses you triggered in battle stay known
	if fw.size() > 0: summary["nemFound"] = "Weakness confirmed: " + ", ".join(PackedStringArray(fw.map(func(k): return str(NEM_WEAK[k]["n"])))) + "."
	for sh in RUN["fleet"]:
		var wk = wingK.get(sh["uid"])
		if jt(wk):
			var g = wingVetAfter(sh, wk)
			if g.size() > 0:
				summary["wingPerks"] = or_(summary.get("wingPerks"), []); summary["wingPerks"].append({"ship": sh["name"], "perks": g})
	var kills = 0
	for u in B["units"]:
		if u["side"] == "enemy" and jt(u.get("dead")) and not jt(u.get("fled")) and not jt(u.get("isSq")) and u.get("ship") == null: kills += 1
	summary["kills"] = kills
	RUN["stats"]["kills"] = float(RUN["stats"]["kills"]) + kills
	for u in B["units"]:
		if u.get("ship") == null: continue
		var ship = u["ship"]
		if u["side"] == "player":
			if ship.get("car") == null: ship["car"] = {"dealt": 0, "kills": 0, "battles": 0}
			var c = ship["car"]; c["dealt"] = float(c["dealt"]) + jsround(float(z0(u.get("dealt")))); c["kills"] = float(c["kills"]) + float(z0(u.get("kills"))); c["battles"] = float(c["battles"]) + 1
		if jt(u.get("dead")) and not jt(u.get("exited")):
			summary["lost"].append({"ship": ship["name"], "cap": ship["cap"]["name"]}); RUN["stats"]["lost"] = float(z0(RUN["stats"].get("lost"))) + 1
			RUN["fleet"] = RUN["fleet"].filter(func(x): return not is_same(x, ship))
			if rnd() < 0.6:
				RUN["reserve"] = or_(RUN.get("reserve"), []); RUN["reserve"].append({"cap": ship["cap"], "from": ship["name"]})
				summary["escaped"] = or_(summary.get("escaped"), []); summary["escaped"].append(ship["cap"]["name"])
			else: RUN["fallen"].append({"name": ship["cap"]["name"], "rank": ship["cap"]["rank"], "fac": ship["cap"]["fac"], "ship": ship["name"], "sector": RUN["sector"]})
			continue
		ship["hp"] = clampv(jsround(float(u["hp"])), 1, derive(ship)["maxHp"])
		if result == "retreat":
			ship["hp"] = max(1.0, float(ship["hp"]) - jsround(float(u["maxHp"]) * 0.1)); continue
		if result == "win":
			var xp = min(60.0, jsround(8.0 + float(z0(u.get("dealt"))) / 4.0 + float(z0(u.get("kills"))) * 12.0)); var rk = ship["cap"]["rank"]
			addXp(ship, xp); summary["xp"].append({"ship": ship["name"], "cap": ship["cap"]["name"], "xp": xp, "up": float(ship["cap"]["rank"]) > float(rk), "rank": ship["cap"]["rank"]})
	if result == "win":
		for sh in RUN["fleet"]:
			var mx = float(derive(sh)["maxHp"]); sh["hp"] = min(mx, float(sh["hp"]) + jsround(mx * 0.15))
		summary["patched"] = true
	if result == "win":
		for u in B["units"]:
			if not (jt(u.get("captured")) and u["side"] == "player" and (not jt(u.get("dead")) or jt(u.get("exited"))) and u.get("ship") == null and not jt(u.get("isSq"))): continue
			var H = HULLS.get(u["tpl"])
			if H == null or jt(H.get("boss")) or jt(u.get("boss")): continue
			if fleetCP() + float(or_(H.get("cp"), 1)) > float(RUN["cpCap"]):
				var v = prizeScrap(u["tpl"]); RUN["credits"] = float(RUN["credits"]) + v
				summary["scrapped"] = or_(summary.get("scrapped"), []); summary["scrapped"].append({"name": u["name"], "cred": v}); continue
			summary["prizes"].append({"tpl": u["tpl"], "name": u["name"], "hpf": clampv(float(u["hp"]) / max(1.0, float(u["maxHp"])), 0.05, 1), "fac": u.get("fac"), "wk": _kinds(u["weapons"]),
				"ab": u.get("ab") if jt(u.get("ab")) else null, "regen": jt(u.get("hullRegen")) or (jt(u.get("regen")) and not jt(u.get("shMax"))), "sh": z0(u.get("shMax")), "cp": or_(H.get("cp"), 1)})
	# v54 doctrine: a Corsair capture pays a bonus refit and 20 credits on top of the normal rewards, for one prize per battle
	if result == "win" and RUN["fac"] == "corsair" and summary["prizes"].size() > 0:
		var p0 = summary["prizes"][0].duplicate(); p0["cause"] = "board"
		var y0 = salvageYield(p0); var m0 = y0["mod"] if jt(y0.get("mod")) else randomModule()
		RUN["inventory"].append(m0); RUN["credits"] = float(RUN["credits"]) + 20; summary["corsairBonus"] = m0
		toast("Prize money: the crews strip a " + modName(m0) + " and 20 credits from the " + str(summary["prizes"][0]["name"]) + " before anyone signs for her.")
	if result == "win":
		var dead = B["units"].filter(func(u): return u["side"] == "enemy" and jt(u.get("dead")) and not jt(u.get("fled")) and not jt(u.get("isSq")) and u.get("ship") == null and not jt(u.get("captured")))
		dead = ssort(dead, func(a, b): return float(z0(b["t"].get("cp"))) - float(z0(a["t"].get("cp"))))
		var wr = []
		for u in dead.slice(0, 3):
			wr.append({"name": u["name"], "tpl": u["tpl"], "cls": u["t"].get("cls"), "fac": u.get("fac"), "cp": or_(u["t"].get("cp"), 1), "wk": _kinds(u["weapons"]), "ab": u.get("ab") if jt(u.get("ab")) else null,
				"regen": jt(u.get("hullRegen")) or (jt(u.get("regen")) and not jt(u.get("shMax"))), "sh": z0(u.get("shMax")), "cause": or_(u.get("killCause"), "blast"), "by": u.get("killedBy") if jt(u.get("killedBy")) else null})
		summary["wrecks"] = wr
	if summary.get("escaped") != null: toast(" and ".join(PackedStringArray(summary["escaped"])) + " escaped in a lifepod, wounded, and will take command of your next hull.")
	var msg = []
	for x in or_(summary.get("nem"), []): msg.append(x)
	if jt(summary.get("nemWarn")): msg.append(summary["nemWarn"])
	if jt(summary.get("nemFeed")): msg.append(summary["nemFeed"])
	if jt(summary.get("nemFound")): msg.append(summary["nemFound"])
	for w in or_(summary.get("wingPerks"), []):
		var pn = []
		for p in w["perks"]: pn.append(str(WING_PERKS[p]["n"]))
		msg.append("The " + str(w["ship"]) + "'s wings earn " + " and ".join(PackedStringArray(pn)) + ".")
	if msg.size() > 0: toast(" ".join(PackedStringArray(msg)))
	tel("battle_end", {"result": result, "kind": cfg.get("kind"), "fac": cfg.get("fac"), "rounds": B["round"], "kills": kills, "lost": summary["lost"].size()})
	B = null
	if result == "win" and RUN["fleet"].size() == 0:
		var sh2 = newShip(cheapHull(RUN["fac"])); RUN["fleet"].append(sh2); ensureFlagship()
		toast("The last ships traded themselves for the win. The sector garrison sends the " + str(sh2["name"]) + " to carry the flag."); tel("reinforced", {"why": "pyrrhic"})
	if result == "loss" or RUN["fleet"].size() == 0:
		endRun(false); return
	if result == "retreat":
		completeNode(); mapScreen(); toast("The fleet jumps clear."); return
	rewardFlow(summary)
	if summary.get("scrapped") != null:
		var tot = 0.0; var names = []
		for x in summary["scrapped"]:
			tot += float(x["cred"]); names.append(x["name"])
		toast("No command points to crew " + ", ".join(PackedStringArray(names)) + ": scrapped for " + numstr(tot) + " credits.")

# ---------------- the stub battle (test/node/golden_campaign.js has the same, line for line) ----------------
func stub_start(cfg: Dictionary) -> void:
	var seed = float(int(cfg["seed"]) & 0xFFFFFFFF) if cfg.get("seed") != null else floor(rnd() * 4294967296.0)
	JSM.rnd_seed(int(seed))
	var enc = cfg["obj"] if ENCOUNTERS.has(cfg.get("obj")) else "rout"
	B = {"seed": seed, "cfg": cfg, "units": [], "round": 1, "obj": {"type": enc}, "shape": or_(cfg.get("shape"), "open"), "map": {"map": or_(cfg.get("map"), "random")}, "deployMode": or_(cfg.get("dep"), "line"),
		"alt": true, "boonStats": {}, "usage": {}, "partial": false, "over": false, "busy": false, "sector": RUN["sector"], "log": []}
	var n = 0
	for ship in RUN["fleet"]:
		if float(ship["hp"]) <= 0: continue
		var d = derive(ship); n += 1
		var ws = []
		for w in d["weapons"]: ws.append({"k": w["k"]})
		B["units"].append({"id": "s" + str(n), "side": "player", "ship": ship, "tpl": ship["tpl"], "t": HULLS[ship["tpl"]], "name": ship["name"], "fac": RUN["fac"], "hp": ship["hp"], "maxHp": d["maxHp"], "dealt": 0, "kills": 0, "dead": false, "weapons": ws})
	var F = FACTIONS[cfg["fac"]] if FACTIONS.has(cfg.get("fac")) else FACTIONS["hegemony"]
	var ros = F["roster"].filter(func(h): return HULLS.has(h) and not jt(HULLS[h].get("boss")))
	var list = []
	if cfg["kind"] == "boss" and jt(F.get("boss")) and HULLS.has(F["boss"]): list.append(F["boss"])
	var ne = 2 + int(RUN["sector"]) + (1 if cfg["kind"] == "elite" else 0)
	for i in range(ne): list.append(pick(ros))
	for tpl in list:
		var H = HULLS[tpl]; n += 1
		var ws2 = []
		for e in H["w"]: ws2.append({"k": W_[e[0]]["k"]})
		B["units"].append({"id": "s" + str(n), "side": "enemy", "tpl": tpl, "t": H, "name": H["n"], "fac": cfg["fac"], "hp": H["hp"], "maxHp": H["hp"], "dealt": 0, "kills": 0, "dead": false,
			"boss": jt(H.get("boss")), "weapons": ws2, "ab": H.get("ab") if jt(H.get("ab")) else null, "shMax": z0(H.get("sh")), "regen": z0(H.get("regen"))})
	if jt(cfg.get("nemesis")):
		for u in B["units"]:
			if u["side"] == "enemy":
				u["nemFlag"] = true; break
func stub_resolve(o: String) -> void:
	var P = B["units"].filter(func(u): return u["side"] == "player"); var E = B["units"].filter(func(u): return u["side"] == "enemy"); var loss = o == "loss"
	B["round"] = ri(3, 7)
	for u in P:
		var dmg = floor(rnd() * float(u["maxHp"]) * (1.2 if loss else 0.6)); u["hp"] = float(u["hp"]) - dmg; u["dealt"] = ri(10, 140)
		if loss or float(u["hp"]) <= 0 or rnd() < 0.06:
			u["hp"] = 0; u["dead"] = true
	var live = P.filter(func(u): return not u["dead"]); var causes = KILL_CAUSES.keys()
	for e in E:
		if loss:
			if rnd() < 0.3:
				e["dead"] = true; e["killCause"] = pick(causes)
			continue
		if not e["boss"] and live.size() > 0 and rnd() < 0.22:
			e["captured"] = true; e["side"] = "player"; e["hp"] = max(1.0, floor(float(e["maxHp"]) * (0.1 + 0.9 * rnd()))); continue
		if o == "partial" and not e["boss"] and rnd() < 0.3:
			e["dead"] = true; e["fled"] = true; continue
		e["dead"] = true; e["killCause"] = pick(causes)
		if live.size() > 0:
			var k = pick(live); k["kills"] = float(k["kills"]) + 1; e["killedBy"] = k["name"]
	if o == "partial": B["partial"] = true
	B["usage"] = {"kind": {}, "ion": 0, "ram": 0, "board": 0, "fire": {}}
	for u in P:
		for w in u["weapons"]: B["usage"]["kind"][w["k"]] = float(z0(B["usage"]["kind"].get(w["k"]))) + 1
	B["over"] = "loss" if loss else "win"

# The browser's "Copy report for Claude" (campaign3d.js copyReport): settings, the run in short and the last 200 run-log events,
# as one JSON text for the game shell to put on the clipboard. battle: the battle shell's own summary, or null.
func report_text(build_id: String = "godot", battle = null) -> String:
	var run = null
	if RUN != null:
		var fl = []
		for s in RUN["fleet"]: fl.append(str(s["tpl"]) + ":" + numstr(s["hp"]))
		run = {"fac": RUN["fac"], "admiral": RUN["admiral"], "sector": RUN["sector"], "fleet": fl}
	return JSON.stringify({"build": build_id, "at": Time.get_datetime_string_from_system(true), "os": OS.get_name(), "opts": META.get("opts"), "run": run, "battle": battle,
		"events": tel_log.slice(max(0, tel_log.size() - 200))})
