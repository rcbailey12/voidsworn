extends RefCounted

const PreviewOp = preload("res://campaign/preview_op.gd")
const CombatRecords = preload("res://rules/combat_records.gd")
const CaptainData = preload("res://rules/captain_data.gd")
# Voidsworn campaign (G3): the rules of a run and its screen flow, a GDScript port of the browser game's core.js (run parts),
# campaign_run.js, campaign_meta.js and campaign3d.js (the root game files). Same names, same order, same maths as the JS.
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
signal fleet_results(lost: bool, ranked_up: bool)  # one report per settled battle, never on a reopened reward panel

const BattleAPI = preload("res://rules/battle_api.gd")   # the rules are reached only through the battle API (rules/API.md)
const JSM = BattleAPI.JSM   # shared JS maths and PRNG algorithm, with a separate stream per campaign
const TABLES_PATH := "res://campaign/data/campaign_tables.json"

# ---------------- tables ----------------
var TB: Dictionary = {}
var W_; var HULLS; var FACTIONS; var MODULES; var PERKS; var RELICS; var ADMIRALS; var RANKS; var RANK_XP; var PATRONS; var BOONS
var BOON_FX; var BOON_D; var BOON_NEED; var RARITY; var ASPECTS; var HEAT; var HULL_VARIANTS; var MASTERY_XP; var MASTERY_PERKS; var LINEAGE_XP; var LINEAGE_TREES; var TREE_FX; var CAPSTONE_MASTERY_XP; var CAPSTONE_MASTERY_PERKS; var CAPSTONE_MASTERY_FX; var MASTERY_I_FX
var FAVOUR_TIERS; var SECTOR_CONDS; var SECTOR_POOL; var EVENTS; var CAPTAINS; var SHIP_NAMES; var MORE_SHIP_NAMES; var FNAMES
var MOD_NEED; var MOD_NAMES; var RELIC_NAMES; var RUN_WORD; var ENCOUNTERS; var ENC_POOL; var ENC_SPECIAL; var REGIONS; var FAC_REGION
var REGION_BIOME; var ROCK_KINDS; var DEEP_MAPS; var FAC_MAP; var BEVENTS; var KILL_CAUSES; var FAC_WNAMES; var FAC_WTRAIT; var WTRAITS
var ABILITIES; var ARC_NAME; var NODE_INFO; var NODE_MODS; var ARCHETYPES; var SHAPES; var REWARD_DEF; var MAP_NAME; var WIN_TITLE
var LEGACY; var CMD_TEXT; var CAUSE_WORD; var RUN_FACTIONS
var NEM_TRAITS; var NEM_PERSONA; var NEM_FAC; var NEM_ADAPT_FAC; var NEM_LINES; var NEM_BEAT_WORD; var ARC_VARIANT; var NEM_VOICE; var NEM_BEAT_COUNTER
var NEM_WEAK; var NEM_ADAPT; var NEM_CLOCK; var FAC_VERBS; var WING_PERKS; var WING_XP; var EVENT_FALLBACK; var FAC_GATES; var CLASS_TRACK_MAX; var KIND_WORD; var CINDER_PRIZES; var CINDER_FIRST_RUN

# ---------------- state ----------------
var META: Dictionary = {}
var RUN = null          # the run (Dictionary) or null
var SAVED_RUN = null    # the last saved copy of the run
var _broken_run := false
var _aspect_setup: Dictionary = {}   # the offer and launch RNG while the flagship choice is pending
# Issue 1451 (R378): the battle in progress, saved at the start of its newest round: {"node", "round", "fp", "size", "data"} (data:
# the rules snapshot, base64), or null. It belongs with SAVED_RUN (the last checkpoint, usually the map before the stop; kept as the fallback) and clears
# when the battle is settled. Continue resumes that round when the snapshot fits the game's rules (battle_restore).
var saved_battle = null
var battle_restore: Callable = Callable()   # external mode: battle_restore(saved_battle) -> {"B", "run"} or {"error"}
var saved_in_yard := true   # issue 1175: the save was taken inside a shipyard (Continue reopens it); old saves count as in the yard
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
var map_trial_choice := false
var prog_tab := "variants"
var page := {"kind": "none", "data": {}, "acts": []}
var modal_d = null       # {kind, data, acts} or null
var toasts: Array = []   # messages for the UI to show (and clear)
var ended := false       # endRun ran (the end screen is up)
var battle_mode := "stub"   # "stub": act("battle", outcome) resolves fights; "external": the battle scene plays them
var pending_battle = null   # external mode: the battle config waiting for the battle scene
var fixed_clock := false    # the parity harness pins the clock to 0, like the JS harness pins Date.now()
var persist_on := false     # write the save file on every save (the game); the harness keeps saves in memory
var teaching_tips := false  # supplied by the host; bots and parity leave it off
const SAVE_PATH := "user://voidsworn_campaign.json"
var save_path := SAVE_PATH
var tel_log: Array = []     # a slim run log (events only), kept with the save; not part of parity

# ======================= setup =======================
# Every table the campaign reads. load_tables refuses to start when one is missing, and export_campaign.js fails when the oracle
# lacks one (it also scans the campaign scripts for every TB table they read, so a new table cannot slip past this list).
const REQUIRED_TABLES = ["ABILITIES", "ADMIRALS", "ARCHETYPES", "ARC_NAME", "ARC_VARIANT", "ASPECTS", "BEVENTS", "BOONS", "BOON_D", "BOON_FX", "BOON_NEED", "BOSS_DMG", "BOSS_ENC", "BOSS_FAC", "BOSS_SCALE", "CAPTAINS", "CAUSE_WORD", "CINDER_FIRST_RUN", "CINDER_PRIZES", "CLASS_TRACK_MAX", "CMD_TEXT", "CORE_EAT_HULL", "DEEP_MAPS", "ENCOUNTERS", "ENC_POOL", "ENC_SPECIAL", "EVENTS", "EVENT_FALLBACK", "FACTIONS", "FAC_GATES", "FAC_MAP", "FAC_REGION", "FAC_VERBS", "FAC_WNAMES", "FAC_WTRAIT", "FAVOUR_TIERS", "FNAMES", "FX_CAPS", "HEAT", "HULLS", "HULL_VARIANTS", "KILL_CAUSES", "KIND_WORD", "LEGACY", "MAP_NAME", "MASTERY_PERKS", "MASTERY_XP", "LINEAGE_XP", "LINEAGE_TREES", "CAPSTONE_MASTERY_XP", "CAPSTONE_MASTERY_PERKS", "CAPSTONE_MASTERY_FX", "MASTERY_I_FX", "MODULES", "MOD_NAMES", "MOD_NEED", "MORE_SHIP_NAMES", "NEM_ADAPT", "NEM_ADAPT_FAC", "NEM_BEAT_WORD", "NEM_CLOCK", "NEM_FAC", "NEM_LINES", "NEM_PERSONA", "NEM_TRAITS", "NEM_VOICE", "NEM_WEAK", "NODE_INFO", "NODE_MODS", "PATRONS", "PERKS", "RAMP", "RANKS", "RANK_XP", "RARITY", "REGIONS", "REGION_BIOME", "RELICS", "RELIC_NAMES", "REWARD_DEF", "ROCK_KINDS", "RUN_FACTIONS", "RUN_WORD", "SECTOR_CONDS", "SECTOR_POOL", "SHAPES", "SHIP_NAMES", "TREE_FX", "W", "WING_PERKS", "WING_XP", "WIN_TITLE", "WTRAITS", "LATE_SHOP", "CULLET", "BIO_KILL"]
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
	RARITY = TB.RARITY; ASPECTS = TB.ASPECTS; HEAT = TB.HEAT; HULL_VARIANTS = TB.HULL_VARIANTS; MASTERY_XP = TB.MASTERY_XP; MASTERY_PERKS = TB.MASTERY_PERKS; LINEAGE_XP = TB.LINEAGE_XP; LINEAGE_TREES = TB.LINEAGE_TREES; TREE_FX = TB.TREE_FX
	CAPSTONE_MASTERY_XP = TB.CAPSTONE_MASTERY_XP; CAPSTONE_MASTERY_PERKS = TB.CAPSTONE_MASTERY_PERKS; CAPSTONE_MASTERY_FX = TB.CAPSTONE_MASTERY_FX; MASTERY_I_FX = TB.MASTERY_I_FX
	FAVOUR_TIERS = TB.FAVOUR_TIERS; SECTOR_CONDS = TB.SECTOR_CONDS; SECTOR_POOL = TB.SECTOR_POOL; EVENTS = TB.EVENTS; CAPTAINS = TB.CAPTAINS
	SHIP_NAMES = TB.SHIP_NAMES; MORE_SHIP_NAMES = TB.MORE_SHIP_NAMES; FNAMES = TB.FNAMES; MOD_NEED = TB.MOD_NEED; MOD_NAMES = TB.MOD_NAMES
	RELIC_NAMES = TB.RELIC_NAMES; RUN_WORD = TB.RUN_WORD; ENCOUNTERS = TB.ENCOUNTERS; ENC_POOL = TB.ENC_POOL; ENC_SPECIAL = TB.ENC_SPECIAL
	REGIONS = TB.REGIONS; FAC_REGION = TB.FAC_REGION; REGION_BIOME = TB.REGION_BIOME; ROCK_KINDS = TB.ROCK_KINDS; DEEP_MAPS = TB.DEEP_MAPS
	FAC_MAP = TB.FAC_MAP; BEVENTS = TB.BEVENTS; KILL_CAUSES = TB.KILL_CAUSES; FAC_WNAMES = TB.FAC_WNAMES; FAC_WTRAIT = TB.FAC_WTRAIT; WTRAITS = TB.WTRAITS
	ABILITIES = TB.ABILITIES; ARC_NAME = TB.ARC_NAME; NODE_INFO = TB.NODE_INFO; NODE_MODS = TB.NODE_MODS; ARCHETYPES = TB.ARCHETYPES; SHAPES = TB.SHAPES
	REWARD_DEF = TB.REWARD_DEF; MAP_NAME = TB.MAP_NAME; WIN_TITLE = TB.WIN_TITLE; LEGACY = TB.LEGACY; CMD_TEXT = TB.CMD_TEXT; CAUSE_WORD = TB.CAUSE_WORD
	RUN_FACTIONS = TB.RUN_FACTIONS
	NEM_TRAITS = TB.NEM_TRAITS; NEM_PERSONA = TB.NEM_PERSONA; NEM_FAC = TB.NEM_FAC; NEM_ADAPT_FAC = TB.NEM_ADAPT_FAC; NEM_LINES = TB.NEM_LINES; NEM_BEAT_WORD = TB.NEM_BEAT_WORD; ARC_VARIANT = TB.ARC_VARIANT; NEM_VOICE = TB.NEM_VOICE; NEM_BEAT_COUNTER = TB.NEM_BEAT_COUNTER
	NEM_WEAK = TB.NEM_WEAK; NEM_ADAPT = TB.NEM_ADAPT; NEM_CLOCK = TB.NEM_CLOCK; FAC_VERBS = TB.FAC_VERBS; WING_PERKS = TB.WING_PERKS; WING_XP = TB.WING_XP
	EVENT_FALLBACK = TB.EVENT_FALLBACK; FAC_GATES = TB.FAC_GATES; CLASS_TRACK_MAX = TB.CLASS_TRACK_MAX; KIND_WORD = TB.KIND_WORD
	CINDER_PRIZES = TB.CINDER_PRIZES; CINDER_FIRST_RUN = TB.CINDER_FIRST_RUN   # R78 Q9: captured Hegemony and Eclipse hulls at the Crusade yards from run 3
	META = defaultMeta(); META["backfilled"] = 1; META["wonFix41"] = 1   # a fresh Godot profile has no browser history to back-fill
	return ""
static func _dec(v):
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
static func jt(x) -> bool: # JS truthiness
	if x == null: return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING: return x != ""
	return true
func z0(x) -> Variant: return x if jt(x) else 0
func or_(a, b) -> Variant: return a if jt(a) else b
var rng := JSM.RandomStream.new()
func seed_rng(seed: int) -> void: rng.rnd_seed(seed)
func rnd() -> float: return rng.rnd()
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
static func hull_text(n) -> String: # a hull figure as a whole number, rounded up so a live ship never reads 0 (issue 932)
	var f = float(n)
	if f <= 0.0: return "0"
	return str(int(ceil(f)))
static func ship_with_article(ship_name: String, sentence_start := false) -> String:
	if ship_name.begins_with("MDV ") or ship_name.begins_with("HNS "): return ship_name
	if ship_name.to_lower().begins_with("the "): return ("The " if sentence_start else "the ") + ship_name.substr(4)
	return ("The " if sentence_start else "the ") + ship_name
static func ship_bare(ship_name: String) -> String: # after "a fresh": no article, and a leading "The" dropped (issue 1551)
	return ship_name.substr(4) if ship_name.to_lower().begins_with("the ") else ship_name
func toast(msg: String) -> void: toasts.append(msg)
func tel(ev: String, d: Dictionary = {}) -> void:
	var e = {"t": now_ms(), "ev": ev, "sector": RUN["sector"] if RUN != null else 0}
	for k in d.keys(): e[k] = d[k]
	tel_log.append(e)
	if tel_log.size() > 600: tel_log = tel_log.slice(tel_log.size() - 600)
# F1 play log (feel pass; announced in contrib/opus/compute/port_notes.md): the battle scene hands over one entry per battle
# with every player activation (scenes/battle/play_log.gd); only the newest 40 battles keep their activations (save size)
func tel_battle(pl: Dictionary) -> void:
	tel("battle_play", pl)
	var n = 0
	for i in range(tel_log.size() - 1, -1, -1):
		if tel_log[i].get("ev") == "battle_play":
			n += 1
			if n > 40: tel_log[i].erase("acts")
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
# R78 Q9 (issue 41): from run 3 the Crusade's Cinder Line yards sell captured Hegemony and Eclipse hulls, links ripped
# out, at Crusade prices. A 'ripped' ship loses the Hegemony sync and Eclipse Archive restore in battle (rules.gd).
func cinderOpen() -> bool:
	return RUN != null and RUN.get("fac") == "voidsworn" and META != null and META.get("stats") != null and int(z0(META["stats"].get("runs"))) >= int(z0(CINDER_FIRST_RUN))
# the price of a captured hull at the Cinder Line yards: the Crusade's own ladder (base cost before the owner's faction
# pricing, times the Crusade class price), then the yard price multiplier, like any other hull for sale there.
func capturedHullPrice(t: Dictionary) -> float:
	var base = float(t["cost0"]) if t.get("cost0") != null else (float(t["val"]) if t.get("val") != null else float(t["cost"]))   # issue 1354: val is the price before the shop discount
	var ladder = (TB.FAC_PRICE["voidsworn"].get(t.get("cls")) if jt(TB.FAC_PRICE.get("voidsworn")) else null)
	var disc = float(TB.SHOP_DISCOUNT["voidsworn"])   # issue 1384: the Crusade's own hulls carry the shop discount, so a captured hull does too
	return jsround(jsround(jsround(base * (float(ladder) if ladder != null else 1.0) / 5.0) * 5.0 * disc / 5.0) * 5.0 * priceMult())
# R78 Q9 (Board call, Nov 15): the captured draw is gated by the same class unlocks as normal stock (legacyHullOn, so
# the playtest switch keeps working), so a captured battleship waits for u_battleship like the Cathedral.
func cinderPool() -> Array:
	var out := []
	for h in CINDER_PRIZES:
		var cl = HULLS[h].get("cls")
		if cl == "Carrier" and not legacyHullOn("u_carrier"): continue
		if cl == "Battleship" and not legacyHullOn("u_battleship"): continue
		if cl == "Dreadnought" and not legacyHullOn("u_dread"): continue
		out.append(h)
	return out
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
		"mastery": {}, "heirs": {}, "shadowPool": {}, "favour": {}, "variants": {}, "heatBest": {}}
# The browser's mastery and favour back-fill of old run logs (backfilled, wonFix41) is not carried: a Godot profile never had a
# browser log (R33: old saves are not migrated). The loss back-fill is carried: a Godot profile saved before the Heat gate still
# has its run log, and Heat must open on the next load.
func migrateMeta(m: Dictionary, log: Array = []) -> Dictionary:
	var d = defaultMeta()
	for k in d.keys():
		if k != "v" and m.get(k) == null: m[k] = d[k]
	if not (m["stats"] is Dictionary): m["stats"] = d["stats"]
	for k in d["stats"].keys():
		var v = m["stats"].get(k)
		if not (v is int or v is float): m["stats"][k] = z0(d["stats"][k])
	# #246: a profile that lost runs before the Heat gate has no loss count. Count the run_end entries that were
	# neither a win nor abandoned, so Heat opens on the next load. Only written when above 0, so old fixtures stay unchanged.
	if not (m["stats"].get("losses") is int or m["stats"].get("losses") is float):
		var losses = 0
		var entries = log if log.size() > 0 else (m.get("tel") if m.get("tel") is Array else [])
		for e in entries:
			if e is Dictionary and e.get("ev") == "run_end" and not jt(e.get("victory")) and not jt(e.get("abandoned")): losses += 1
		if losses > 0: m["stats"]["losses"] = losses
	if not jt(m.get("v")) or float(m["v"]) < 2:
		m["opts"] = or_(m.get("opts"), {}); m["tel"] = or_(m.get("tel"), []); m["v"] = 2
	for k in ["mastery", "favour", "variants", "heatBest"]: m[k] = or_(m.get(k), {})
	if not jt(m.get("backfilled")): m["backfilled"] = 1
	if not jt(m.get("wonFix41")): m["wonFix41"] = 1
	m["fallen"] = _migrate_fallen(m["fallen"], "voidsworn", "hall")
	return m
func migrateRun(r) -> Variant:
	if r != null and not jt(r.get("fac")): r["fac"] = "voidsworn"
	if r != null and (not jt(r.get("v")) or float(r["v"]) < 2):
		r["v"] = 2; r["stats"] = or_(r.get("stats"), {"battles": 0, "elites": 0, "bosses": 0, "kills": 0}); r["fallen"] = or_(r.get("fallen"), [])
	return normalizeRun(r)
func runDefaults() -> Dictionary:
	return {"fac": "voidsworn", "foes": null, "admiral": "vex", "credits": 0, "cpCap": 10, "sector": 1, "relics": [], "inventory": [], "fleet": [], "pos": null,
		"stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0, "lost": 0}, "t0": 0, "fallen": [], "timeline": [], "ambush": false, "over": false, "boons": [], "patrons": [],
		"aspect": null, "flagUid": null, "heat": [], "mastery": 0, "ransoms": 0, "altFleet": false, "cmdOverride": null, "giftBoon": null, "reserve": [], "seenEvents": [],
		"regionsUsed": [], "condsUsed": [], "curNode": null, "reinf": 0, "flags": {}, "nem": null, "verbUsed": 0, "verbNext": null, "classTrack": {}, "boonRerolls": 0,
		"eatenCore": null, "eatCoreSeen": false}
func normalizeRun(r) -> Variant:
	if not (r is Dictionary): return r
	var d = runDefaults()
	for k in d.keys():
		if r.get(k) == null: r[k] = d[k]
	for k in ["relics", "inventory", "fleet", "fallen", "timeline", "boons", "patrons", "heat", "reserve", "seenEvents", "regionsUsed", "condsUsed"]:
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
	return repairRunIds(r)
func _keep(arr: Array, T: Dictionary, kind: String, rep: Array, get_id: Callable = Callable()) -> Array:
	var out = []
	for x in arr:
		var id = get_id.call(x) if get_id.is_valid() else x
		if id != null and (id is String) and T.has(id): out.append(x)
		else: rep.append(kind + " " + str(id).substr(0, 40))
	return out
func _migrate_fallen(rows: Array, fac: String, scope: String) -> Array:
	var out := []
	for f in rows:
		if not (f is Dictionary): continue
		if not (f.get("cap") is Dictionary) and not (f.get("name") is String): continue
		if not (f.get("cap") is Dictionary):
			var legacy := {}
			for key in ["name", "rank", "xp", "fac", "perks"]:
				if f.has(key): legacy[key] = f[key]; f.erase(key)
			f["cap"] = legacy
		f["cap"] = CaptainData.migrate(f["cap"], "captain:legacy:%s:%d" % [scope, out.size()], fac, PERKS)
		out.append(f)
	return out

func _migrate_report(summary: Dictionary, r: Dictionary) -> void:
	for key in ["lost", "xp"]:
		var rows = summary.get(key)
		if not (rows is Array): continue
		for i in range(rows.size()):
			var row = rows[i]
			if not (row is Dictionary) or row.get("cap") is Dictionary: continue
			var legacy := {"name": row.get("cap"), "rank": row.get("rank", 0)}
			row["cap"] = CaptainData.migrate(legacy, "captain:legacy:report:%s:%d" % [key, i], r["fac"], PERKS)
			row.erase("rank")

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
	var active_captains := []
	for i in range(r["fleet"].size()):
		var s: Dictionary = r["fleet"][i]
		s["cap"] = CaptainData.migrate(s.get("cap"), "captain:" + str(s.get("uid", i)), r["fac"], PERKS)
		active_captains.append(s["cap"])
		s["mods"] = _keep(s["mods"], MODULES, "refit", rep)
		if not (s.get("name") is String): s["name"] = HULLS[s["tpl"]]["n"]
		if not (s.get("hp") is int or s.get("hp") is float) or not (float(s["hp"]) > 0): s["hp"] = 1
	var res = []
	for x in r["reserve"]:
		if not (x is Dictionary): continue
		x["cap"] = CaptainData.migrate(x.get("cap"), "captain:legacy:reserve:%d" % res.size(), r["fac"], PERKS)
		active_captains.append(x["cap"])
		res.append(x)
	CaptainData.restore_portraits(active_captains)
	r["reserve"] = res
	r["fallen"] = _migrate_fallen(r["fallen"], r["fac"], "fallen")
	if r.get("flagUid") != null:
		var ok = false
		for s in r["fleet"]:
			if s.get("uid") == r["flagUid"]: ok = true
		if not ok: r["flagUid"] = null
	if not (r.get("credits") is int or r.get("credits") is float) or is_nan(float(r["credits"])) or is_inf(float(r["credits"])): rep.append("credits"); r["credits"] = 0
	if r.get("fac") == "chorus" and not (r.get("bio") is int or r.get("bio") is float):   # issue 1178: a Chorus run saved before biomass moves its purse to biomass
		r["bio"] = float(r["credits"]); r["credits"] = 0.0
	if r.get("reward") != null:
		var R = r["reward"]
		if not (R is Dictionary): r["reward"] = null
		else:
			if not (R.get("stage") in ["prize", "salvage", "victory", "pick", "relic", "promo"]): R["stage"] = "promo"
			var pz = []
			if R.get("prizes") is Array:
				for p in R["prizes"]:
					if p is Dictionary and HULLS.has(p.get("tpl")): pz.append(p)
			R["prizes"] = pz
			if R.get("victory") is Dictionary and R["victory"].get("summary") is Dictionary:
				_migrate_report(R["victory"]["summary"], r)
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
static func saneMeta(m) -> bool:
	if not (m is Dictionary): return false
	for k in ["unlocked", "admirals", "stats", "opts", "mastery", "lineage", "heirs", "shadowPool", "favour", "variants", "heatBest"]:
		if m.get(k) != null and not (m[k] is Dictionary): return false
	for k in ["tel", "fallen"]:
		if m.get(k) != null and not (m[k] is Array): return false
	return m.get("renown") == null or m["renown"] is int or m["renown"] is float
static func saneRun(r) -> bool:
	if r == null: return true
	if not (r is Dictionary): return false
	if jt(r.get("none")): return true
	var m = r.get("map")
	if not (r.get("fleet") is Array and m is Dictionary and m.get("cols") is Array and m.get("edges") is Array): return false
	if m["cols"].is_empty() or not (m["cols"][0] is Array) or m["cols"][0].is_empty(): return false
	for col in m["cols"]:
		if not (col is Array) or not col.all(func(n): return n is Dictionary and n.get("id") is String and n.get("type") is String): return false
	return m["edges"].all(func(e): return e is Array and e.size() >= 2)
static func saneSave(o) -> bool:
	return o is Dictionary and (o.has("run") or o.get("meta") != null) and (o.get("meta") == null or saneMeta(o["meta"])) and saneRun(o.get("run"))

static func _has_run(r) -> bool:
	return r is Dictionary and not jt(r.get("none")) and not jt(r.get("over"))

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
	# storyGuard (issue 1338): saves from this build on never need the old story-buff repair (_restore_legacy_story_modifier)
	var data = {"format": "voidsworn-godot-campaign", "v": 1, "uid": UID, "meta": META, "run": SAVED_RUN if SAVED_RUN != null else {"none": true}, "yard": saved_in_yard, "tel": tel_log,
		"battle": saved_battle if SAVED_RUN != null else null, "storyGuard": true}
	if _broken_run: data["brokenRun"] = true
	if not _aspect_setup.is_empty() and _aspect_pending(SAVED_RUN): data["aspectSetup"] = _aspect_setup
	return JSON.stringify(_enc(data))
var last_save_ok := true   # issue 1451: did the newest persist_save reach the disk (true while saves are off)
func persist_save(meta_only: bool = false) -> void:
	_persist_save(meta_only, false)
func _persist_save(meta_only: bool, cleared_run: bool) -> void:
	var now = now_ms()
	META["updated"] = now
	if not meta_only: META["runAt"] = now
	last_save_ok = true
	if not persist_on: return
	var data = save_text()
	# Atomic: the new save is written whole to a temp file, flushed and checked, then renamed over the old one, so a crash or a
	# power cut mid-write leaves either the old save or the new one, never half a file. The save before it becomes the .bak.
	if cleared_run:
		# Prepare a profile-only backup first so a successful abandon cannot be undone by a damaged primary later.
		# Until the primary write succeeds it still takes precedence over the staged backup.
		var backup := save_path + ".bak"
		var prior := FileAccess.get_file_as_string(backup)
		if _write_atomic(backup, data):
			if _write_atomic(save_path, data): return
			if prior.is_empty(): prior = FileAccess.get_file_as_string(save_path)
			if not prior.is_empty() and not _write_atomic(backup, prior):
				push_warning("campaign: could not restore the prior backup after the failed write")
		last_save_ok = false; toast("This computer could not save the game (is the disk full?).")
		return
	if FileAccess.file_exists(save_path):
		var prev = FileAccess.get_file_as_string(save_path)
		if prev != data and saneSave(_dec(_json_quiet(prev))):
			if not _write_atomic(save_path + ".bak", prev): push_warning("campaign: could not refresh the backup save")
	if not _write_atomic(save_path, data):
		last_save_ok = false; toast("This computer could not save the game (is the disk full?).")
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
static func _json_quiet(t: String) -> Variant:   # a damaged save is expected now and then: parse without an engine error
	var j = JSON.new()
	return j.data if j.parse(t) == OK else null
# A valid primary wins even if it is profile-only. If neither copy is sound, recover the profile from either copy.
static func _resolve_save(primary, backup) -> Dictionary:
	if saneSave(primary): return primary
	if saneSave(backup): return backup
	var resolved: Dictionary = primary if primary is Dictionary else {}
	if not saneMeta(resolved.get("meta")):
		resolved.erase("meta")
		if backup is Dictionary and saneMeta(backup.get("meta")):
			# Keep a usable primary run. Otherwise take the backup profile and its telemetry together.
			var run = resolved.get("run")
			if run == null or not saneRun(run):
				resolved = backup
			else:
				resolved["meta"] = backup["meta"]
	if not saneRun(resolved.get("run")):
		resolved.erase("run")
		resolved["brokenRun"] = true
	return resolved

static func _read_save(path: String) -> Dictionary:
	var primary = _dec(_json_quiet(FileAccess.get_file_as_string(path)))
	if saneSave(primary): return primary
	var resolved := _resolve_save(primary, _dec(_json_quiet(FileAccess.get_file_as_string(path + ".bak"))))
	if resolved.is_empty() and (FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak")):
		resolved["brokenRun"] = true
	return resolved

static func has_saved_run(path: String = SAVE_PATH) -> bool:
	var data := _read_save(path)
	return _has_run(data.get("run")) or jt(data.get("brokenRun"))

func _apply_save(o: Dictionary) -> void:
	tel_log = o["tel"] if o.get("tel") is Array else []
	if o.get("meta") is Dictionary:
		var m = defaultMeta()
		for k in o["meta"].keys(): m[k] = o["meta"][k]
		META = migrateMeta(m, tel_log)
	var r = o.get("run")
	SAVED_RUN = migrateRun(r) if _has_run(r) else null
	_broken_run = jt(o.get("brokenRun")) or _unplayable_run(SAVED_RUN)
	_aspect_setup = o["aspectSetup"] if _aspect_pending(SAVED_RUN) and o.get("aspectSetup") is Dictionary else {}
	_launch_rng = int(z0(_aspect_setup.get("launchRng"))) if _aspect_setup.has("launchRng") else -1
	var sb = o.get("battle")
	saved_battle = sb if (SAVED_RUN != null and sb is Dictionary and sb.get("data") is String and sb.get("node") is String and sb.get("fp") is String) else null
	# Issue 1338: only a save written before storyGuard may be missing a story buff the old mid-battle checkpoint erased
	if SAVED_RUN != null and o.get("storyGuard") != true: SAVED_RUN["storyLegacy"] = true
	# Older builds showed the line on every Sector III win. Use the saved log when it can prove it already appeared.
	if SAVED_RUN != null and not _broken_run and not SAVED_RUN.has("beat3DebriefSeen") and _beat3_line(SAVED_RUN, "debrief") != "":
		var started: float = float(z0(SAVED_RUN.get("t0")))
		if started > 0 and tel_log.any(func(e): return e is Dictionary and e.get("ev") == "battle_end" and e.get("result") == "win" and e.get("sector") == 3 and float(z0(e.get("t"))) >= started):
			SAVED_RUN["beat3DebriefSeen"] = true
	saved_in_yard = o.get("yard") != false
	if o.get("uid") is float or o.get("uid") is int: UID = max(UID, int(o["uid"]))

func load_save_text(s: String, bak: String = "") -> void:
	_apply_save(_resolve_save(_dec(_json_quiet(s)), _dec(_json_quiet(bak))))
func persist_load() -> void:
	_apply_save(_read_save(save_path))

# ======================= core.js: run state =======================
func capName(fac) -> String:
	var C = CAPTAINS.get(fac) if CAPTAINS.has(fac) else CAPTAINS["voidsworn"]
	var used = {}
	if RUN != null and RUN.get("fleet") != null:
		for s in RUN["fleet"]: used[String(s["cap"]["full_name"]).split(" ")[0]] = true
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
func newCaptain(vet, fac, uid: String, ship: Dictionary = {}) -> Dictionary:
	var faction := str(fac) if jt(fac) else "voidsworn"
	var name := capName(fac)
	var perks: Array = []
	var c := CaptainData.make("captain:" + uid, faction, name, RANK_XP[1] if jt(vet) else 0, 1 if jt(vet) else 0, perks)
	if jt(vet) and not ship.is_empty():
		ship["cap"] = c
		_roll_captain_perk(ship)
	CaptainData.update_trait(c, PERKS)
	CaptainData.assign_portrait(c, CaptainData.used_portraits(RUN))
	return c

func _newShip(tpl, vet) -> Dictionary:
	var fac = factionOfTpl(tpl)
	var uid := new_id()
	var s = {"uid": uid, "tpl": tpl, "name": shipName(fac), "mk": 1, "hp": 0, "mods": []}
	s["cap"] = newCaptain(vet, fac, uid, s)
	s["hp"] = derive(s)["maxHp"]
	return s
# campaign3d.js: wounded captains take the next hull (not during a battle, not a veteran hire)
func newShip(tpl, vet = false) -> Dictionary:
	var sh = _newShip(tpl, vet)
	if B == null and not jt(vet) and RUN != null and RUN.get("reserve") is Array and RUN["reserve"].size() > 0:
		var r = RUN["reserve"].pop_front(); var f = float(sh["hp"]) / max(1.0, float(derive(sh)["maxHp"]))
		sh["cap"] = r["cap"]; sh["hp"] = max(1.0, jsround(float(derive(sh)["maxHp"]) * f))
		toast(str(r["cap"]["full_name"]) + " recovers and takes command of " + ship_with_article(str(sh["name"])) + ".")
	return sh
func sumFx(list: Array) -> Dictionary:
	var o = {}
	for fx in list:
		if not jt(fx): continue
		for k in fx.keys(): o[k] = float(z0(o.get(k))) + float(fx[k])
	for k in o.keys():
		if TB.FX_CAPS.has(k): o[k] = min(o[k], TB.FX_CAPS[k])
	return o
func fleetFxList() -> Array:
	var l = []
	if RUN != null:
		for r in RUN["relics"]:
			if RELICS.has(r) and jt(RELICS[r].get("fx")): l.append(RELICS[r]["fx"])
		if ADMIRALS.has(RUN["admiral"]): l.append(admiralFx(RUN["admiral"]))
		for b in or_(RUN.get("boons"), []):
			if BOONS.has(b["id"]): l.append(BOON_FX[b["id"]][int(z0(b.get("r")))])
	return l
# Issue 1650 (R404) Mastery I: from capstone mastery I the admiral's doctrine bonus is the authored row in MASTERY_I_FX
func runCapMastery() -> int:
	var L = RUN.get("lineage") if RUN != null else null
	return int(z0(L.get("mastery"))) if L is Dictionary and L.get("capstone") != null else 0
func admiralFx(id) -> Variant:
	if runCapMastery() >= 1 and RUN["admiral"] == id and MASTERY_I_FX.has(id): return MASTERY_I_FX[id]
	return ADMIRALS[id].get("fx")
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
	for sh in (RUN.get("fleet", []) if RUN != null else []):
		k.merge(_ship_kit(HULLS[sh["tpl"]], derive(sh)))
	return k
func _ship_kit(hull: Dictionary, d: Dictionary) -> Dictionary:
	var k := {}
	for w in d["weapons"]:
		if w["k"] == "torp": k["torp"] = 1
		if w["k"] == "lance": k["lance"] = 1
		if jt(w.get("ion")): k["ion"] = 1
		if w["k"] == "battery": k["batt"] = 1
		if w["k"] == "flak": k["flak"] = 1
		if w["arc"] == "P" or w["arc"] == "S": k["broad"] = 1
		if w["arc"] == "P" or w["arc"] == "S" or w["k"] == "battery": k["still"] = 1
	if d["shMax"] > 0: k["shields"] = 1
	if _hull_can_brace(hull): k["brace"] = 1
	if jt(hull.get("hangar")): k["carrier"] = 1
	if jt(d["hangar"]): k["sq"] = 1
	return k

# The offer card explains an existing pick. Only the kit is shared with offer eligibility:
# caps and possible future fits here never add, remove or reweight an offer.
func boonFleetRelevance(id: String, rarity: int) -> Dictionary:
	if RUN == null: return {}
	# These three protocols only act when a hull braces.
	var brace := id in ["d_bastion", "i_brace", "i_wall"]
	var need: String = "brace" if brace else BOON_NEED.get(id, "")
	if need == "": return {}
	var fx: Dictionary = BOON_FX[id][rarity]
	var ships := PackedStringArray()
	var capped := false
	var can_brace := false
	for sh in RUN["fleet"]:
		if brace and not _boon_can_brace(sh["tpl"]): continue
		if brace: can_brace = true
		var d = derive(sh)
		if need != "brace" and not _ship_kit(HULLS[sh["tpl"]], d).has(need): continue
		if _boon_has_room(d, fx): ships.append(sh["name"])
		else: capped = true
	if brace and not can_brace: return {"brace_blocked": true}
	var result := {"need": need, "ships": ships, "capped": capped}
	if not ships.is_empty() or capped: return result
	for mod in or_(RUN.get("inventory"), []):
		for sh in RUN["fleet"]:
			if not canFitModule(sh, mod): continue
			var refitted: Dictionary = sh.duplicate()
			refitted["mods"] = sh["mods"] + [mod]
			if _boon_fits_ship(refitted, need, fx):
				result["refit"] = mod
				return result
	for tpl in HULLS:
		if factionGate(RUN.get("fac"), tpl) != null: continue
		# A hull the fleet could gain later, without rolling a name or using a reserve captain.
		var hull := {"tpl": tpl, "uid": null, "mods": [], "cap": {"perks": []}}
		if _boon_fits_ship(hull, need, fx):
			result["hull"] = true
			break
	return result

func _boon_fits_ship(ship: Dictionary, need: String, fx: Dictionary) -> bool:
	if need == "brace" and not _boon_can_brace(ship["tpl"]): return false
	var d = derive(ship)
	return (need == "brace" or _ship_kit(HULLS[ship["tpl"]], d).has(need)) and _boon_has_room(d, fx)

func _boon_can_brace(tpl) -> bool:
	return _hull_can_brace(HULLS[tpl])

func _hull_can_brace(hull: Dictionary) -> bool:
	return not jt(hull.get("sq")) and not jt(FAC_GATES.get(hull.get("fac"), {}).get("noBrace"))

func _boon_has_room(derived: Dictionary, fx: Dictionary) -> bool:
	var current: Dictionary = derived["fx"]
	var with_boon := sumFx([current, fx])
	for key in fx:
		if with_boon[key] <= z0(current.get(key)): continue
		if key == "bastion" and derived["shMax"] <= 0: continue
		# Hot Tubes can hit the weapon's reload floor before the stacked bonus cap.
		if key == "torpCd" and not derived["weapons"].any(func(w): return w["k"] == "torp" and w["cd"] > 1): continue
		return true
	return false

func boonUseful(id, kit: Dictionary) -> bool:
	if id in ["i_brace", "i_wall", "d_bastion"] and not kit.has("brace"): return false
	var n = BOON_NEED.get(id)
	return not jt(n) or jt(kit.get(n))
# R1 (Nov 1, Codex PR #1 boon fix, Ryan's ruling R64; port of core.js): one pool of useful ordinary protocols from the offering core and the run's
# other cores, the offering core's picks weighted 3 to 1, without replacement, every pick at the offering core's sync; no owned, duplicate or
# useless fillers (an exhausted pool gives a short offer, which boonStep pays 60 credits for). One special slot: legendary or duo, duo 45%.
func boonOfferPool(p) -> Array:
	var kit = fleetKit(); var pool = []
	var eaten = RUN.get("eatenCore")
	for id in BOONS.keys():
		var b = BOONS[id]; var bp = b.get("p")
		if jt(bp) and not jt(b.get("leg")) and (bp == p or RUN["patrons"].has(bp)) and not hasBoon(id) and boonUseful(id, kit) and bp != eaten: pool.append(id)
	return pool
func boonOfferDuos(p) -> Array:
	var have = boonPatrons(); var kit = fleetKit(); var duos = []
	for id in BOONS.keys():
		var b = BOONS[id]
		if not jt(b.get("duo")) or hasBoon(id) or not boonUseful(id, kit) or not b["duo"].has(p) or b["duo"].has(RUN.get("eatenCore")): continue
		var all_ok = true; var some = false
		for q in b["duo"]:
			if not (have.has(q) or q == p): all_ok = false
			if q != p and have.has(q): some = true
		if all_ok and some: duos.append(id)
	return duos
func rollBoonOffer(p, minR) -> Array:
	ensurePatrons()
	var s = RUN["sector"] if RUN != null else 1
	var pool = boonOfferPool(p); var out = []
	while out.size() < 3 and not pool.is_empty():
		var total = 0
		for id in pool: total += 3 if BOONS[id].get("p") == p else 1
		var x = rnd() * total; var at = 0
		while at < pool.size() - 1:
			var weight = 3 if BOONS[pool[at]].get("p") == p else 1
			if x < weight: break
			x -= weight; at += 1
		var id = pool[at]; pool.remove_at(at); out.append({"id": id, "r": rollRarity(minR, s, p)})
	var duos = boonOfferDuos(p); var L = legendaryFor(p, minR); var special = null
	if L != null: special = {"id": pick(duos), "r": 0} if (not duos.is_empty() and rnd() < 0.45) else {"id": L, "r": 3}
	elif not duos.is_empty() and (out.size() < 3 or rnd() < 0.45): special = {"id": pick(duos), "r": 0}
	if special != null:
		if out.size() >= 3: out[2] = special
		else: out.append(special)
	return out
# R1 (RWD-6): every protocol an offer from this core could show, so a reroll that cannot change the offer is refused before it charges
func boonOfferCan(p, minR) -> Array:
	ensurePatrons()
	var L = legendaryFor(p, minR); var out = []
	for id in boonOfferPool(p) + boonOfferDuos(p) + ([L] if L != null else []):
		if not out.has(id): out.append(id)
	return out
func legendaryFor(p, minR) -> Variant:
	if not (float(z0(minR)) >= 1): return null
	if RUN != null and p == RUN.get("eatenCore"): return null
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
	var ps = RUN["patrons"].filter(func(q): return q != RUN.get("eatenCore"))
	var p = pick(ps if not ps.is_empty() else RUN["patrons"])
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
	if H != null and (H.get("val") is int or H.get("val") is float): return float(H["val"])   # issue 1354: shop discounts do not lower prize, strip or scrap values
	if H != null and (H.get("cost") is int or H.get("cost") is float): return float(H["cost"])
	return 40.0 * float(or_(H.get("cp") if H != null else null, 1))
func prizeScrap(tpl) -> float: return jsround(shipValue(tpl) * 0.35)
# issue 1290: what decommissioning pays; a ship regrown from an Eclipse core pays nothing until it has fought (core.js sellValue)
# issue 1384: after it has fought, a regrown ship pays at most what its regrow cost (corePaid), so regrow, fight, sell never profits
func sellValue(s) -> float:
	if s != null and s.get("regrown"): return 0.0
	if s != null and s.get("corePaid") != null: return minf(float(s["corePaid"]), prizeScrap(s["tpl"]))
	return prizeScrap(s["tpl"])
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
# issue 1653 Heavy Breach Lockers: -1 speed, never below 2 (a ship already at 2 or less keeps its speed)
func lockerSpeed(sp: float, fx) -> float: return (sp - 1.0 if sp - 1.0 >= 2.0 else min(sp, max(sp, 2.0))) if jt(fx.get("lockerSlow")) else sp
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
	var eat = float(TB.CORE_EAT_HULL) if (RUN != null and jt(RUN.get("eatenCore")) and factionOfTpl(ship["tpl"]) == "chorus") else 0.0   # R78 Q15: an eaten core grows every Chorus ship, new ships included
	var maxHp = jsround(float(t["hp"]) * mm * (1.0 + float(z0(fx.get("hpPct"))) + 0.06 * tr + eat))
	var ws = []
	for e in t["w"]: ws.append(mkWeapon(e[0], e[1], fx))
	return {
		"maxHp": maxHp, "shMax": jsround(float(t["sh"]) * mm * (1.0 + float(z0(fx.get("shPct")))) * float(TB.SHIELD_POOL_MULT) * (float(TB.SHIELD_POOL_FAC[t["fac"]]) if (t.get("fac") != null and TB.SHIELD_POOL_FAC.has(t["fac"])) else 1.0)),   # core.js (SHIELD_POOL_FAC[t.fac]||1)
		"regen": jsround(float(t["rg"]) * mm * (1.0 + float(z0(fx.get("regenPct")))) * float(TB.SHIELD_REGEN_MULT)),
		"armor": min(0.6, float(t["ar"]) + float(z0(fx.get("armor")))), "speed": lockerSpeed(float(t["sp"]) + float(z0(fx.get("speed"))), fx), "turns": float(t["tn"]) + float(z0(fx.get("turns"))), "ev": float(t["ev"]) + float(z0(fx.get("ev"))),
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
	if not shopCan(c): return false
	shopPay(c); changeFleet(_track_up.bind(cls)); return true
# Issue 1556: a change that would take the hull under 1 keeps what it could not take (hpOwed [amount, the hull it left]),
# and a later gain on the same hull pays that back first, so taking a hull refit off and on again never adds hull.
# Twin: core.js changeShip.
# One hull adjustment for every max-hull change, one ship (changeShip) or the fleet (changeFleet: class refits, the Aspect).
func changeShip(ship: Dictionary, fn: Callable) -> void:
	var before = derive(ship)["maxHp"]; fn.call(ship); adjustHull(ship, before, derive(ship)["maxHp"])
func adjustHull(ship: Dictionary, before, after) -> void:
	# The owed amount stays through changes that do not raise max hull, a partial gain carries the rest, and anything else that
	# moves the hull (a repair, a battle) ends it (Artoo on PR 1602).
	var ow = ship.get("hpOwed")
	var owed: float = float(ow[0]) if (ow is Array and float(ship["hp"]) == float(ow[1])) else 0.0
	var hp = float(ship["hp"]) + (after - before)
	if after > before and owed > 0:
		var pay = min(owed, float(after - before)); hp -= pay; owed -= pay
	if hp < 1:
		owed += 1 - hp; hp = 1
	hp = clampv(hp, 1, after)
	if owed > 0: ship["hpOwed"] = [owed, hp]
	else: ship.erase("hpOwed")
	ship["hp"] = hp
func changeFleet(fn: Callable) -> void:
	var b = []
	for s in RUN["fleet"]: b.append(derive(s)["maxHp"])
	fn.call()
	for i in range(RUN["fleet"].size()):
		var s = RUN["fleet"][i]; adjustHull(s, b[i], derive(s)["maxHp"])
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
# issue 1178 (R335, the 1085 sim pick): the Chorus pay for hull work (repairs, new hulls, Marks) in biomass; everyone else in credits.
# Twin of core.js hullKey / hullFunds / hullPay.
func hullKey() -> String: return "bio" if RUN != null and RUN.get("fac") == "chorus" else "credits"
func hullFunds() -> float: return float(z0(RUN.get(hullKey()))) if RUN != null else 0.0
func hullPay(c) -> void: RUN[hullKey()] = hullFunds() - float(c)
func hullWord() -> String: return "biomass" if hullKey() == "bio" else "credits"
# issue 1484 (R382): the Chorus pay for refits, class refit tracks, protocol rerolls and the late market in biomass when it covers the
# price, otherwise in credits. Every other fleet pays these in credits. One purse per purchase. Twin of core.js shopKey/shopCan/shopPay/shopWord.
func shopKey(c) -> String: return "bio" if RUN != null and RUN.get("fac") == "chorus" and float(z0(RUN.get("bio"))) >= float(c) else "credits"
func shopCan(c) -> bool: return RUN != null and float(z0(RUN.get(shopKey(c)))) >= float(c)
func shopPay(c) -> void:
	var k = shopKey(c); RUN[k] = float(z0(RUN.get(k))) - float(c)
func shopWord(c) -> String:
	if RUN == null or RUN.get("fac") != "chorus": return ""
	return " biomass" if shopKey(c) == "bio" or float(z0(RUN.get("credits"))) < float(c) else " credits"
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
# issue 1653: the effect line, then the flavour line when the salvage has one (the card footer)
func relicText(r) -> String: return str(RELICS[r]["d"]) + (("\n" + str(RELICS[r]["fl"])) if jt(RELICS[r].get("fl")) else "")
func relicName(r) -> String:
	var f = RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn"
	if RELIC_NAMES.has(f) and jt(RELIC_NAMES[f].get(r)): return RELIC_NAMES[f][r]
	return RELICS[r]["n"]
func runWord(fac = null) -> String:
	var f = fac if jt(fac) else (RUN["fac"] if RUN != null and jt(RUN.get("fac")) else "voidsworn")
	return or_(RUN_WORD.get(f), "run")
# no shield relic for a shieldless fleet; R1 (relics synthesis fix 4): none that can never act: the coils with no ability in the fleet,
# the logbook when every captain is at the top rank, the chalked roll for a lone ship
func relicUseful(r) -> bool:
	var F = RUN["fleet"] if RUN != null and RUN.get("fleet") is Array else []
	if r == "lattice": return jt(fleetKit().get("shields"))
	if r == "coils": return F.any(func(s): return HULLS.has(s["tpl"]) and jt(HULLS[s["tpl"]].get("ab")))
	if r == "logbook": return F.any(func(s): return s.get("cap") is Dictionary and float(z0(s["cap"].get("rank"))) < RANKS.size() - 1)
	if r == "martyr": return F.size() > 1
	# issue 1653 offer gates for the new salvage: each needs the fleet shape it works with
	if r == "spotter": return F.any(func(s): return HULLS.has(s["tpl"]) and HULLS[s["tpl"]].get("ab") == "launch")
	if r == "lastlight": return F.size() > 1
	if r == "coolant": return F.any(func(s): return HULLS.has(s["tpl"]) and jt(HULLS[s["tpl"]].get("ab")) and HULLS[s["tpl"]].get("ab") != "launch")
	if r == "ram": return RUN != null and (jt(TB["RAM_FAC"].get(RUN.get("fac"))) or F.any(func(s): return HULLS.has(s["tpl"]) and HULLS[s["tpl"]].get("ab") == "overburn"))
	return true
# R1 (MOD-3, Codex PR #1): a refit fits only where it can do something: a free slot, the hull type it is for, the weapon or system it improves
func canFitModule(sh, m) -> bool:
	if not (sh is Dictionary) or not (m is String) or not MODULES.has(m): return false
	var t = HULLS.get(sh.get("tpl"))
	if t == null or not (sh.get("mods") is Array) or sh["mods"].size() >= int(z0(t.get("slots"))): return false
	var md = MODULES[m]
	if jt(md.get("only")) and t.get("ab") != md["only"]: return false
	var need = MOD_NEED.get(m)
	if need == "shields": return float(z0(t.get("sh"))) > 0.0
	if need == "carrier": return t.get("ab") == "launch" and float(z0(t.get("hangar"))) > 0.0
	if need == "board": return true   # issue 1653: every ship has a crew that can board
	if need == "brace": return not (FAC_GATES.has(t.get("fac")) and jt(FAC_GATES[t["fac"]].get("noBrace")))   # issue 1653: never on hulls that cannot brace
	if need == "chaser":   # issue 1653: a non-turret fore or flank weapon to swivel
		for pair in t.get("w", []):
			if W_.has(pair[0]) and W_[pair[0]].get("k") != "turret" and (pair[1] == "F" or pair[1] == "S" or pair[1] == "P"): return true
		return false
	var kind = {"batt": "battery", "lance": "lance", "torp": "torp", "flak": "flak"}.get(need)
	if kind != null:
		for pair in t.get("w", []):
			if W_.has(pair[0]) and W_[pair[0]].get("k") == kind: return true
		return false
	return not jt(need)
# Issue 2029 item 8: why a refit cannot go on a ship, in words ("" when it fits). The item that fills the slot is named, or
# the class is said to have no slot of the kind the refit needs. Never changes what canFitModule answers.
func fitBlock(sh, m) -> String:
	if canFitModule(sh, m): return ""
	var t = HULLS.get(sh.get("tpl")) if sh is Dictionary else null
	if t == null or not (m is String) or not MODULES.has(m): return "That refit cannot go there."
	var cls = str(t.get("n", "ship")); cls = cls if cls.begins_with("The ") else "The " + cls
	if int(z0(t.get("slots"))) <= 0: return cls + " has no refit slot."
	var probe = sh.duplicate(); probe["mods"] = []   # the same ship with every slot free: what is left in the way is the class itself
	if not canFitModule(probe, m):
		var md = MODULES[m]; var need = MOD_NEED.get(m)
		if jt(md.get("only")) and t.get("ab") != md["only"]: return cls + " has no " + {"launch": "launch bay"}.get(md["only"], "slot of that kind") + " for this refit."
		if need == "brace": return cls + " cannot brace, so this refit has nothing to do."
		var what = {"shields": "shield", "carrier": "hangar", "chaser": "fore or flank gun to swivel", "batt": "battery", "lance": "lance", "torp": "torpedo tube", "flak": "flak gun"}.get(need, "slot of that kind")
		return cls + " has no " + what + " for this refit."
	var held = []
	for x in sh["mods"]: held.append(modName(x) if MODULES.has(x) else str(x))
	return ("Slot taken by " if held.size() == 1 else "Slots taken by ") + " and ".join(held) + "."
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
	if n["type"] in ["battle", "elite"]:
		var lesson := node_teaching_battle(n, n["type"])
		if lesson == 1: return "hegemony"
		if lesson == 2: return "corsair"
	if not jt(RUN.get("foes")) or n["type"] != "battle": return main
	var h = 0
	for ch in (String(n["id"]) + numstr(RUN["sector"])): h = (h * 31 + ch.unicode_at(0)) & 0xFFFFFFFF
	var hs = h if h < 0x80000000 else h - 0x100000000   # JS h>>3 is a signed 32-bit shift
	return RUN["foes"][3 + (hs >> 3) % 2] if h % 5 == 0 else main

# ---------------- battle.js helpers the campaign uses ----------------
func rollBattleEvent(cfg, force) -> Variant:
	if cfg == null or (cfg.get("teachingGate") == true and cfg.get("teachingBattle") == 1) or cfg.get("kind") == "boss": return null
	if cfg.get("teachingGate") == true and cfg.get("teachingBattle") == 2: force = "reinf_enemy"
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
# R1 (Nov 1, Ryan): never the dead star in sector 1; it stays a set piece for later sectors (sec defaults to the run's sector)
func fitEncounter(n, sec = null) -> void:
	if n == null or not jt(n.get("enc")): return
	if n["enc"] == "defend": n["map"] = "station"
	var s1 = float(sec if sec != null else (or_(RUN.get("sector"), 1) if RUN != null else 1)) == 1.0
	if n.get("shape") == "deadstar" and (s1 or (jt(n.get("map")) and not DEEP_MAPS.has(n["map"]))):
		var sh = []
		for x in ENCOUNTERS[n["enc"]]["shapes"]:
			if x != "deadstar": sh.append(x)
		n["shape"] = pick(sh if sh.size() > 0 else ["open"])
func bossEncounter() -> Dictionary:
	var enc = pick(TB.BOSS_ENC); var sh = []   # R63 boss objective table (battle.js BOSS_ENC): no Decapitation
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
		if b == null:   # R1 (W3-1, Codex PR #1): an all-rest column still gets its elite
			for n in c4:
				if n["type"] == "shipyard" or n["type"] == "drydock": b = n; break
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
	var edges = []
	for c in range(COLS - 1):
		var from_col: Array = cols[c]
		var to_col: Array = cols[c + 1]
		if to_col.size() == 1 or (from_col.size() == 1 and to_col.size() > 2):
			for a in from_col:
				for b in to_col: edges.append([a["id"], b["id"]])
			continue
		# Keep two types available and give each repeated type enough distinct origins.
		var max_copies := mini(from_col.size(), to_col.size() - 1)
		var counts := {}
		for b in to_col:
			if counts.get(b["type"], 0) == max_copies:
				if c == COLS - 3: b["type"] = "shipyard" if b["type"] == "drydock" else "drydock"
				else: b["type"] = "event" if b["type"] == "battle" else "battle"
			counts[b["type"]] = counts.get(b["type"], 0) + 1
		var routes := from_col.map(func(a): return {"a": a, "stops": []})
		# Cover every stop, placing repeated types first while the most origins are free.
		for b in ssort(to_col.duplicate(), func(x, y): return counts[y["type"]] - counts[x["type"]]):
			var nearest = ssort(routes.duplicate(), func(x, y): return absf(x["a"]["y"] - b["y"]) - absf(y["a"]["y"] - b["y"]))
			for route in nearest:
				var stops: Array = route["stops"]
				if stops.size() < 2 and stops.all(func(n): return n["type"] != b["type"]):
					stops.append(b)
					break
		for route in routes:
			var a: Dictionary = route["a"]
			var stops: Array = route["stops"]
			var nearest = ssort(to_col.duplicate(), func(x, y): return absf(x["y"] - a["y"]) - absf(y["y"] - a["y"]))
			for b in nearest:
				if stops.size() == 2: break
				if stops.all(func(n): return n["type"] != b["type"]): stops.append(b)
			stops = ssort(stops, func(x, y):
				var distance := absf(x["y"] - a["y"]) - absf(y["y"] - a["y"])
				return distance if distance != 0.0 else x["row"] - y["row"])
			for b in stops: edges.append([a["id"], b["id"]])
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
			n["map"] = regionMap(region, n["col"], COLS); fitEncounter(n, s)
	var biome = rollBiome(region)
	# issue 1175: the flagship fight's objective and board shape are rolled with the map (after the regions, so its board is
	# the one the fight always used) and shown on the boss stop; the fight reads them (an old save without them rolls there)
	for n in cols[COLS - 1]:
		if n["type"] == "boss": n.merge(bossEncounter(), true)
	if RUN != null and RUN.get("teachingGate") == true and s == 1:
		cols[0][0]["teachingShape"] = cols[0][0]["shape"]; cols[0][0]["shape"] = "open"
	return {"fac": fac, "cols": cols, "edges": edges, "cond": cond, "region": region, "biome": biome}
func sectorCond() -> Variant:
	if RUN == null or RUN.get("map") == null: return null
	var k = RUN["map"].get("cond")
	return SECTOR_CONDS[k] if jt(k) and SECTOR_CONDS.has(k) else null

# ---------------- progression helpers ----------------
func masteryXP(id) -> float: return float(z0(META["mastery"].get(id))) if META.get("mastery") != null else 0.0
func masteryLevel(id) -> int:
	var x = masteryXP(id); var l = 0
	for i in range(1, masteryThresholds(id).size()):
		if x >= float(masteryThresholds(id)[i]): l = i
	return l
func masteryThresholds(id) -> Array: return LINEAGE_XP if LINEAGE_TREES.has(id) else MASTERY_XP
func masteryPerk(level) -> Dictionary:
	if level < MASTERY_PERKS.size(): return MASTERY_PERKS[level]
	return {"n": "Command evolution", "d": "Choose a capstone in Admiral mastery."} if level == 8 else {"n": "Lineage choice", "d": "Choose a branch skill in Admiral mastery."}
# Job 7 step 14: capstone mastery. Choosing the level 8 evolution opens three more levels at 320, 440 and 600 XP.
# The line still stops at 230 until an evolution is chosen, so an unmet tree never banks mastery it cannot show.
func masteryXPCap(id) -> float:
	var t = masteryThresholds(id)
	if not LINEAGE_TREES.has(id): return float(t[-1])
	return maxf(float(t[-1]), float(CAPSTONE_MASTERY_XP[-1])) if lineageBuild(id)["capstone"] != null else float(t[-1])
func capstoneMasteryLevel(id) -> int:
	if not LINEAGE_TREES.has(id) or lineageBuild(id)["capstone"] == null: return 0
	var x = masteryXP(id); var l = 0
	for i in range(CAPSTONE_MASTERY_XP.size()):
		if x >= float(CAPSTONE_MASTERY_XP[i]): l = i + 1
	return l
func capstoneMasteryPerk(level) -> Variant:
	return CAPSTONE_MASTERY_PERKS[level - 1] if level >= 1 and level <= CAPSTONE_MASTERY_PERKS.size() else null
# issue 1650: the Mastery III signature (name and line) of the admiral's chosen capstone, or null before one is chosen
func capstoneSignature(id) -> Variant:
	if not LINEAGE_TREES.has(id): return null
	var c = lineageBuild(id)["capstone"]
	return null if c == null else CAPSTONE_MASTERY_FX.get("%s:cap:%d" % [id, int(c)])
func capstoneMasteryNext(id) -> Variant:
	var l = capstoneMasteryLevel(id)
	return null if l >= CAPSTONE_MASTERY_XP.size() else CAPSTONE_MASTERY_XP[l]
func lineageBuild(id) -> Dictionary:
	var tree = LINEAGE_TREES.get(id); var raw = or_(or_(META.get("lineage"), {}).get(id), {}); var picks = []; var ranks = {"A": 0, "B": 0, "C": 0}
	var lvl = 8 if playtestAll() else masteryLevel(id)   # R69 playtest switch (issue #305): every tree node is open while it is on
	if tree != null and raw is Dictionary and raw.get("picks") is Array:
		for key in raw["picks"].slice(0, maxi(0, mini(3, lvl - 4))):
			var node = str(key).split(":")
			if node.size() != 3: break
			var b = node[0]; var t = node[1]; var c = node[2]
			if not tree["branches"].has(b) or str(ranks[b]) != t or not c in ["0", "1"] or int(t) >= tree["branches"][b]["tiers"].size(): break
			picks.append(key); ranks[b] += 1
	var capstone = raw.get("capstone") if raw is Dictionary else null
	if tree == null or picks.size() != 3 or lvl < 8 or not (capstone is float or capstone is int) or (capstone != 0 and capstone != 1): capstone = null
	var respecs = raw.get("respecs", 0) if raw is Dictionary else 0
	if not (respecs is float or respecs is int) or not is_finite(float(respecs)) or float(respecs) != floor(float(respecs)) or float(respecs) <= 0 or float(respecs) > 9007199254740991: respecs = 0
	return {"picks": picks, "capstone": capstone, "respecs": respecs}
func lineageBetweenRuns() -> bool: return SAVED_RUN == null and (RUN == null or jt(RUN.get("over")))
func lineageNodes(id) -> Array:
	var tree = LINEAGE_TREES.get(id)
	if tree == null: return []
	var build = lineageBuild(id); var ranks = {"A": 0, "B": 0, "C": 0}; var nodes = []; var level = 8 if playtestAll() else masteryLevel(id)
	for key in build["picks"]: ranks[str(key).substr(0, 1)] += 1
	for b in tree["branches"].keys():
		var tiers = tree["branches"][b]["tiers"]
		for t in range(tiers.size()):
			for c in range(tiers[t].size()):
				var key = "%s:%d:%d" % [b, t, c]; var chosen = build["picks"].has(key); var locked = t < ranks[b]
				var state = "chosen" if chosen else ("locked" if locked else ("available" if t == ranks[b] and build["picks"].size() < mini(3, level - 4) else "future"))
				# Issue 361: a row the battle has no TREE_FX entry for does nothing yet. The tree screens mark it from this
				# flag (UI rollout, group 4); the flag reads the same table the battle's treeBuild reads.
				var node = tiers[t][c].duplicate(); node.merge({"key": str(id) + ":" + key, "branch": b, "tier": t + 1, "state": state, "waiting": not TREE_FX.has(str(id) + ":" + key)}); nodes.append(node)
	for c in range(tree["capstones"].size()):
		var state = "chosen" if build["capstone"] != null and build["capstone"] == c else ("locked" if build["capstone"] != null else ("available" if level >= 8 and build["picks"].size() == 3 else "future"))
		var node = tree["capstones"][c].duplicate(); node.merge({"key": "%s:cap:%d" % [id, c], "branch": "cap", "tier": 1, "state": state, "waiting": not TREE_FX.has("%s:cap:%d" % [id, c])}); nodes.append(node)
	return nodes
func lineageCanPick(key) -> bool:
	var id = str(key).split(":")[0]
	return lineageBetweenRuns() and lineageNodes(id).any(func(n): return n["key"] == key and n["state"] == "available")
func lineagePick(key) -> bool:
	if not lineageCanPick(key): return false
	var parts = str(key).split(":"); var id = parts[0]; var build = lineageBuild(id)
	if parts[1] == "cap": build["capstone"] = int(parts[2])
	else: build["picks"].append(str(key).substr(id.length() + 1))
	META["lineage"] = or_(META.get("lineage"), {}); META["lineage"][id] = build; return true
func lineageRespecCost(id) -> float: return 25.0 + 10.0 * float(lineageBuild(id)["respecs"])
func lineageCanRespec(id) -> bool:
	var b = lineageBuild(id)
	return LINEAGE_TREES.has(id) and lineageBetweenRuns() and (b["picks"].size() > 0 or b["capstone"] != null) and float(z0(META.get("renown"))) >= lineageRespecCost(id)
func lineageRespec(id) -> bool:
	if not lineageCanRespec(id): return false
	var respecs = float(lineageBuild(id)["respecs"]) + 1; META["renown"] = float(META["renown"]) - lineageRespecCost(id)
	META["lineage"] = or_(META.get("lineage"), {}); META["lineage"][id] = {"picks": [], "capstone": null, "respecs": respecs}; return true
func favourOf(p) -> float: return float(z0(META["favour"].get(p))) if META.get("favour") != null else 0.0
func favourTier(p) -> int:
	var f = favourOf(p); var t = 0
	for i in range(FAVOUR_TIERS.size()):
		if f >= float(FAVOUR_TIERS[i]["at"]): t = i
	return t
# R78 Q15 (issue 42): the first time a Chorus run reaches sector 3 it may eat one core it has not synced with.
# Every core below Synced qualifies; if none does, there is no offer. Refusing marks the offer seen with no other change.
func syncedTier() -> int:
	for i in range(FAVOUR_TIERS.size()):
		if float(FAVOUR_TIERS[i]["at"]) == 12.0: return i
	return FAVOUR_TIERS.size() - 1
func coreEatEligible() -> Array:
	var out = []
	if RUN == null or RUN["fac"] != "chorus": return out
	var synced = syncedTier()
	for p in PATRONS.keys():
		if favourTier(p) < synced: out.append(p)
	return out
func coreEatDue() -> bool:
	return RUN != null and RUN["fac"] == "chorus" and float(RUN["sector"]) == 3.0 and not jt(RUN.get("eatCoreSeen")) and not coreEatEligible().is_empty()
func eatsCoreBoon(b, p) -> bool:
	if not (b is Dictionary) or not BOONS.has(b.get("id")): return false
	var B = BOONS[b["id"]]
	return B.get("p") == p or (jt(B.get("duo")) and B["duo"].has(p))
func _eat_core(p) -> void:
	RUN["eatenCore"] = p; RUN["eatCoreSeen"] = true
	RUN["boons"] = or_(RUN.get("boons"), []).filter(func(b): return not eatsCoreBoon(b, p))
	if RUN.get("reward") is Dictionary and RUN["reward"].get("boonOffer") is Array:
		RUN["reward"]["boonOffer"] = RUN["reward"]["boonOffer"].filter(func(o): return not eatsCoreBoon(o, p))
	var alt = null
	for q in or_(RUN.get("patrons"), []):
		if q != p: alt = q; break
	if alt != null:
		if RUN.get("map") is Dictionary:
			for c in RUN["map"]["cols"]:
				for n in c:
					if n.get("rw") is Dictionary and n["rw"].get("k") == "boon" and n["rw"].get("p") == p: n["rw"]["p"] = alt
		if RUN.get("reward") is Dictionary and RUN["reward"].get("rw") is Dictionary and RUN["reward"]["rw"].get("k") == "boon" and RUN["reward"]["rw"].get("p") == p: RUN["reward"]["rw"]["p"] = alt
func applyEatCore(p) -> bool:
	if RUN == null or jt(RUN.get("eatCoreSeen")) or not coreEatEligible().has(p): return false
	changeFleet(_eat_core.bind(p))
	return true
func refuseCoreEat() -> bool:
	if RUN == null or jt(RUN.get("eatCoreSeen")): return false
	RUN["eatenCore"] = null; RUN["eatCoreSeen"] = true; return true
func heatLevel(list) -> float:
	var t = 0.0
	for k in or_(list, []): t += float(z0(HEAT[k].get("w"))) if HEAT.has(k) else 0.0
	return t
# Heat opens after the first loss; a winner from an older profile keeps it open too.
func heatUnlocked() -> bool:
	var s = META.get("stats") if META.get("stats") is Dictionary else {}
	return float(z0(s.get("losses"))) > 0 or float(z0(s.get("wins"))) > 0
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
func newRun(admiralId, fac, opt = {}, checkpoint := true) -> void:
	if not ADMIRALS.has(admiralId): return
	# R1 (PROG-6): an admiral you do not own cannot launch. The screen checks this too; the rules function is the gate now.
	# Harnesses that start a run with an admiral they have not bought grant that ownership in their own setup first.
	if not admiralOwned(admiralId): RUN = null; return
	var adm = ADMIRALS[admiralId]
	_aspect_setup.clear()
	fac = fac if RUN_FACTIONS.has(fac) else "voidsworn"
	var foes = shuffle(RUN_FACTIONS.filter(func(f): return f != fac))
	RUN = {"fac": fac, "foes": foes, "admiral": admiralId, "credits": 120, "cpCap": 10, "sector": 1, "relics": [], "inventory": [], "fleet": [], "pos": null,
		"stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0, "lost": 0}, "t0": now_ms(), "fallen": [], "timeline": [], "ambush": false, "over": false, "boons": [], "eatenCore": null, "eatCoreSeen": false}
	RUN["encounterCurve"] = BattleAPI.RulesScript.ENCOUNTER_CURVE_V1
	# Missing means off, so old saves and default runs keep their existing save format.
	if opt.get("mapTrial") == true: RUN["mapTrial"] = true
	RUN["patrons"] = shuffle(PATRONS.keys()).slice(0, 4); RUN["aspect"] = null; RUN["flagUid"] = null; RUN["nem"] = null
	if teaching_tips and float(z0(META["stats"].get("finishedRuns", META["stats"].get("runs")))) < 2: RUN["teachingGate"] = true
	if jt(META["unlocked"].get("chest1")): RUN["credits"] += 75
	if jt(META["unlocked"].get("chest2")): RUN["credits"] += 75
	if jt(META["unlocked"].get("chest3")): RUN["credits"] += 75
	if fac == "chorus":   # issue 1178: the Chorus start with their purse as biomass
		RUN["bio"] = RUN["credits"]; RUN["credits"] = 0.0
	if jt(META["unlocked"].get("cmd1")): RUN["cpCap"] += 2
	if jt(META["unlocked"].get("cmd2")): RUN["cpCap"] += 2
	if jt(META["unlocked"].get("founder")):
		var r = randomRelic()
		if r != null: addRelic(r)
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
			if f["cap"]["perks"].size() < 2: _roll_captain_perk(f)
			f["hp"] = derive(f)["maxHp"]
		CaptainData.update_trait(f["cap"], PERKS)
	var lb = lineageBuild(admiralId)   # issue #305: a run snapshots the flown admiral's tree, because picks can only change between runs
	RUN["lineage"] = {"id": admiralId, "picks": lb["picks"].duplicate(), "capstone": lb["capstone"]}
	var cmL = capstoneMasteryLevel(admiralId) if lb["capstone"] != null else 0
	if cmL > 0: RUN["lineage"]["mastery"] = cmL   # issue 1650: capstone mastery steps earned when the run starts (set only when earned, so older saves keep their shape)
	var dev = null
	for p in RUN["patrons"]:
		if favourTier(p) >= 2: dev = p; break
	if dev != null:
		var pool = BOONS.keys().filter(func(id): return BOONS[id].get("p") == dev and not jt(BOONS[id].get("leg")) and boonUseful(id, fleetKit()))
		if pool.size() > 0:
			var id = pick(pool); RUN["boons"].append({"id": id, "r": 1 if favourTier(dev) >= 3 else 0}); RUN["giftBoon"] = id
	RUN["map"] = genSector(1)
	RUN["flags"] = {}; RUN["nems"] = {}; RUN["nemAssign"] = drawNemAssign(); RUN["nemClock"] = 0; RUN["nemStrike"] = false; RUN["nemEscapes"] = 0; RUN["nem"] = newNemesis(RUN["nemAssign"][0])   # B4: the first hunter is ready, the rest are created lazily
	META["stats"]["runs"] = float(META["stats"]["runs"]) + 1
	if checkpoint: saveRun()
func saveRun() -> void:
	SAVED_RUN = clone(RUN) if (RUN != null and not jt(RUN.get("over"))) else null
	if B == null: saved_battle = null   # a new checkpoint outside a battle replaces any battle save
	saved_in_yard = page.get("kind") == "shipyard" or (page.get("kind") == "fleet" and page.get("data") is Dictionary and page["data"].get("back") == "shipyard")
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
		"beat3":
			if not showCoreEatOffer() and not showBeat3(): close_modal()
		"eatCore":
			ACT_eatCore(a)
		"refuseCoreEat":
			ACT_refuseCoreEat()
		"storyCore":
			close_modal(); resumeReward()
		"continueRun": ACT_continueRun()
		"newRunScreen": ACT_newRunScreen()
		"abandonRun":
			if _needs_run_recovery(): _show_run_recovery()
			elif SAVED_RUN != null:
				RUN = clone(SAVED_RUN); endRun(false, true)
		"discardBrokenRun": ACT_discardBrokenRun()
		"legacy": legacyScreen()
		"help": helpScreen()
		"progTab":
			prog_tab = a; legacyScreen()
		"lineage": lineageScreen(a)
		"offerLineage":
			if not lineageCanPick(a): return
			var node = lineageNodes(a.split(":")[0]).filter(func(n): return n["key"] == a)[0]
			var acts = []; A(acts, "confirmLineage", a); A(acts, "closeModal"); show_modal("lineagePick", node, acts)
		"confirmLineage":
			if not lineagePick(a): return
			persist_save(true); lineageScreen(a.split(":")[0])
		"offerRespec":
			if not lineageCanRespec(a): return
			var acts = []; A(acts, "confirmRespec", a); A(acts, "closeModal"); show_modal("lineageRespec", {"id": a, "cost": lineageRespecCost(a)}, acts)
		"confirmRespec":
			if not lineageRespec(a): return
			persist_save(true); lineageScreen(a)
		"buyVariant": ACT_buyVariant(a)
		"buyLegacy": ACT_buyLegacy(a)
		"buyAdmiral": ACT_buyAdmiral(a)
		"pickAdmiral":
			if not admiralOwned(a): return
			if picked_admiral != a:
				run_opt["alt"] = false; run_opt["cmdAlt"] = false
			picked_admiral = a; admiralScreen()
		"pickFaction":
			picked_faction = a; META["opts"]["lastFac"] = a; admiralScreen()
		"optAlt":
			run_opt["alt"] = a == "1"; admiralScreen()
		"optCmd":
			run_opt["cmdAlt"] = a == "1"; admiralScreen()
		"optMapTrial":
			if page.get("kind") == "admiral": map_trial_choice = a == "1"
		"optHeat":
			var i = run_opt["heat"].find(a)
			if i >= 0: run_opt["heat"].remove_at(i)
			else: run_opt["heat"].append(a)
			admiralScreen()
		"startRun": ACT_startRun()
		"pickAspect": ACT_pickAspect(a)
		"backToSetup": ACT_backToSetup()
		"nameHeir": ACT_nameHeir(a)
		"nextFac":
			picked_faction = a; META["opts"]["lastFac"] = a; admiralScreen()
		"saveQuit":
			if page.get("kind") != "battle": saveRun()
			titleScreen()
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
		"fitBoughtRefit": ACT_finishBoughtRefit(a)
		"keepBoughtRefit": ACT_finishBoughtRefit()
		"repair": ACT_repair(a)
		"repairAll": ACT_repairAll()
		"repairStop": ACT_repairStop(a)
		"upgradeMk": ACT_upgradeMk(a)
		"lateBuy": ACT_lateBuy(a)
		"restoreCore": ACT_restoreCore(a)
		"sellShip": ACT_sellShip(a)
		"sellConfirm": ACT_sellConfirm(a)
		"eventChoice": ACT_eventChoice(a)
		"eventBack": ACT_eventBack()
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
		"takeSalvage": ACT_takeSalvage(a)
		"fitWreckRefit": ACT_takeSalvage(a, true)
		"rewardNext": ACT_rewardNext()
		"takeMod": ACT_takeMod(a)
		"fitRewardRefit":
			var pair = a.split(":", true, 1)
			if pair.size() == 2 and pair[1] != "": ACT_takeMod(pair[0], pair[1])
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
	map_trial_choice = false
	var acts = []
	var saved = SAVED_RUN != null or _broken_run
	if saved: A(acts, "continueRun")
	A(acts, "newRunScreen"); A(acts, "legacy"); A(acts, "help")
	show_page("title", {"saved": saved, "renown_dot": float(z0(META.get("renown"))) >= 15, "best": META["stats"].get("best"), "wins": META["stats"].get("wins")}, acts)
func _unplayable_run(run) -> bool:
	return run != null and (not saneRun(run) or run["fleet"].is_empty()
		or not FACTIONS.has(run["map"].get("fac")) or not (run["sector"] is int or run["sector"] is float)
		or not run["fleet"].all(func(s): return s is Dictionary and s.has("uid")))
func _needs_run_recovery() -> bool:
	return _broken_run or _unplayable_run(SAVED_RUN)
func _show_run_recovery() -> void:
	var acts = []; A(acts, "discardBrokenRun"); A(acts, "closeModal")
	show_modal("brokenRun", {}, acts)
func ACT_discardBrokenRun() -> void:
	if not _needs_run_recovery(): return
	var old = [SAVED_RUN, saved_battle, saved_in_yard, _broken_run, META.duplicate(true)]
	SAVED_RUN = null; saved_battle = null; saved_in_yard = false; _broken_run = false
	_persist_save(false, true)
	if not last_save_ok:
		SAVED_RUN = old[0]; saved_battle = old[1]; saved_in_yard = old[2]; _broken_run = old[3]; META = old[4]
		changed.emit()
		return
	RUN = null; B = null
	admiralScreen()
func _aspect_pending(run) -> bool:
	if not (run is Dictionary) or jt(run.get("aspect")) or run.get("sector") != 1 or run.get("pos") != null \
			or run.get("curNode") != null or run.get("reward") != null or not (run.get("stats") is Dictionary) \
			or z0(run["stats"].get("battles")) != 0 or not saneRun(run):
		return false
	# Old pre-pick checkpoints have no setup record. Opening the map seeds its stops, even before the first jump.
	for col in run["map"]["cols"]:
		if col.any(func(n): return n.get("seed") != null): return false
	return true
func ACT_continueRun() -> void:
	if _needs_run_recovery(): _show_run_recovery(); return
	if SAVED_RUN == null: return
	if saved_battle != null and _resume_saved_battle(): return
	if _aspect_pending(SAVED_RUN):
		RUN = clone(SAVED_RUN)
		picked_admiral = RUN["admiral"]; picked_faction = RUN["fac"]
		run_opt = {"alt": jt(RUN.get("altFleet")), "cmdAlt": jt(RUN.get("cmdOverride")), "heat": RUN.get("heat", []).duplicate()}
		aspectScreen()
		return
	RUN = clone(SAVED_RUN)
	ensureFlagship()
	if RUN.get("reward") != null:
		mapScreen(); resumeReward()
	elif not _resume_node():
		mapScreen()
	if SAVED_RUN != null: SAVED_RUN.erase("storyLegacy")   # issue 1338: the old-save repair gets this one Continue only
	if RUN == null: return
	RUN.erase("storyLegacy")
	var rep = (RUN["_repairs"] as Array).size() if RUN.get("_repairs") is Array else 0
	var lost = int(z0(RUN.get("_shipsDropped")))
	if rep > 0:
		toast("Your save came from an older version: " + ((str(lost) + " ship" + ("s" if lost > 1 else "") + " and ") if lost > 0 else "") + ((str(rep - lost) + " item" + ("s" if rep - lost > 1 else "") + " ") if rep - lost > 0 else "") + "no longer in the game " + ("were" if (lost > 0 or rep > 1) else "was") + " removed.")
		RUN.erase("_repairs"); RUN.erase("_shipsDropped")
		if page.get("kind") != "battle": saveRun()
func ACT_newRunScreen() -> void:
	if _needs_run_recovery(): _show_run_recovery(); return
	if SAVED_RUN != null:
		var acts = []; A(acts, "abandonRun"); A(acts, "closeModal")
		show_modal("abandon", {}, acts); return
	admiralScreen()
func _mine() -> Array:
	var out = []
	for id in ADMIRALS.keys():
		if or_(ADMIRALS[id].get("fac"), "voidsworn") == picked_faction: out.append(id)
	return out
# R1 (PROG-6): an admiral is yours when bought or when it costs nothing (each faction's first admiral); only yours can be picked or launched
func admiralOwned(id) -> bool:
	var a = ADMIRALS.get(id)
	return a != null and (playtestAll() or jt(META["admirals"].get(id)) or not (float(z0(a.get("cost"))) > 0))
# R1 (Ryan, Nov 1 11:54: "A for now for play tests"): the playtest switch. On, every admiral, the Legacy hull unlocks (carriers,
# battleships, the dreadnought) and every hull variant count as owned; renown, the unlock buttons and META underneath are untouched,
# so switching it off restores the R62 progression. Godot only: the browser oracle has no switch, so playtest_default stays false
# for the parity harnesses; campaign_ui.gd (the real game) turns the default on. The player's choice lives in META.opts.playtestAll.
var playtest_default := false
const PLAYTEST_HULLS = ["u_carrier", "u_battleship", "u_dread"]
func playtestAll() -> bool:
	if META == null: return false
	var o = META.get("opts") if META.get("opts") is Dictionary else {}
	return jt(o.get("playtestAll")) if o.has("playtestAll") else playtest_default
func set_playtest_all(on: bool) -> void:
	if not (META.get("opts") is Dictionary): META["opts"] = {}
	META["opts"]["playtestAll"] = on; persist_save(true)
func legacyHullOn(id) -> bool: return jt(META["unlocked"].get(id)) or (playtestAll() and PLAYTEST_HULLS.has(id))
func variantOwned(vid) -> bool: return playtestAll() or (META.get("variants") != null and jt(META["variants"].get(vid)))
func admiralScreen() -> void:
	var mine = _mine()
	if not mine.has(picked_admiral) or not admiralOwned(picked_admiral):
		var pa = null
		for id in mine:
			if admiralOwned(id):
				pa = id; break
		picked_admiral = pa if pa != null else mine[0]
	var acts = []
	for f in RUN_FACTIONS: A(acts, "pickFaction", f)
	for id in mine:
		if LINEAGE_TREES.has(id): A(acts, "lineage", id)
		if admiralOwned(id): A(acts, "pickAdmiral", id)
		else: A(acts, "buyAdmiral", id, float(z0(META.get("renown"))) >= float(ADMIRALS[id]["cost"]))   # R1 (PROG-2): locked admirals can be bought here
	var id0 = picked_admiral; var a = ADMIRALS[id0]; var ml = masteryLevel(id0)
	var opts = {"ml": ml, "alt": null, "cmd2": null, "heat": heatUnlocked()}
	if ml >= 1:
		opts["alt"] = altFleetPlan(id0, picked_faction); A(acts, "optAlt", "0"); A(acts, "optAlt", "1")
	if ml >= 3 and jt(a.get("cmd")):
		var c2 = altCommand(id0)
		if c2 != null:
			opts["cmd2"] = c2; A(acts, "optCmd", "0"); A(acts, "optCmd", "1")
	if opts["heat"]:
		for k in HEAT.keys(): A(acts, "optHeat", k)
	A(acts, "startRun", "", admiralOwned(picked_admiral)); A(acts, "title")
	show_page("admiral", {"mine": mine, "opts": opts}, acts)
func ACT_startRun() -> void:
	if not admiralOwned(picked_admiral): return
	var ml = masteryLevel(picked_admiral)
	# Issue 1217 phase 4: a Launch after Back reuses the random state the dropped run started from, so Back then Launch
	# cannot reroll patrons, founder relic, map or the aspect offer. Twin: ACT.startRun in campaign_meta.js.
	if META.has("parkedRng"):
		rng.rnd_seed(int(META["parkedRng"])); META.erase("parkedRng")
	_launch_rng = JSM.to_u32(rng.rng_s)
	newRun(picked_admiral, picked_faction, {"alt": run_opt["alt"] and ml >= 1, "cmdAlt": run_opt["cmdAlt"] and ml >= 3,
		"heat": run_opt["heat"].duplicate() if heatUnlocked() else [], "mapTrial": map_trial_choice}, false)
	map_trial_choice = false
	tel("run_start", {"fac": RUN["fac"], "admiral": picked_admiral})
	_aspect_setup = {"offer": _roll_aspect_offer(), "launchRng": _launch_rng}
	saveRun()
	aspectScreen()
func _roll_aspect_offer() -> Array:
	return shuffle(ASPECTS.keys()).slice(0, 4 if float(z0(RUN.get("mastery"))) >= 2 else 3)
func aspectScreen() -> void:
	var f = ensureFlagship()
	var opts = _aspect_setup.get("offer")
	if not (opts is Array) or opts.is_empty() or not opts.all(func(k): return ASPECTS.has(k)):
		opts = _roll_aspect_offer()
		_aspect_setup = {"offer": opts, "launchRng": _launch_rng}
	W["aspOffer"] = opts
	var acts = []
	for k in opts: A(acts, "pickAspect", k)
	A(acts, "backToSetup")
	show_page("aspect", {"flag": f, "opts": opts}, acts)
func _set_aspect(k) -> void:
	RUN["aspect"] = k; ensureFlagship()
# Issue 1217 phase 4: Back from the flagship page. The run newRun just made has no aspect yet and was never played: drop it,
# its save and its count (its starting random state is parked in META for the next Launch), and return to the faction and admiral desk with every pick kept. Twin: ACT.backToSetup in
# campaign_meta.js.
var _launch_rng = -1   # the random state the newest Launch started from (Back parks it in META)
func ACT_backToSetup() -> void:
	if RUN == null or jt(RUN.get("aspect")): return
	if _launch_rng >= 0: META["parkedRng"] = _launch_rng
	map_trial_choice = RUN.get("mapTrial") == true   # Test maps stays on for the next Launch (Godot only; the browser has none)
	META["stats"]["runs"] = max(0.0, float(z0(META["stats"].get("runs"))) - 1.0)
	RUN = null; SAVED_RUN = null; persist_save()
	admiralScreen()
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
	for t in ["variants", "legacy", "mastery", "favour", "heat", "fallen"]: A(acts, "progTab", t)
	if prog_tab == "legacy":   # R1 (PROG-2): the Legacy unlocks get a screen again
		for id in LEGACY.keys():
			var u = LEGACY[id]
			if jt(META["unlocked"].get(id)) or (jt(u.get("req")) and not jt(META["unlocked"].get(u["req"]))): continue
			A(acts, "buyLegacy", id, float(z0(META.get("renown"))) >= float(u["cost"]))
	if prog_tab == "variants":
		for f in favFirst():
			for vid in HULL_VARIANTS.keys():
				var v = HULL_VARIANTS[vid]
				if HULLS[v["base"]].get("fac") != f: continue
				if not jt(META["variants"].get(vid)) and not jt(v.get("arc")): A(acts, "buyVariant", vid, float(z0(META.get("renown"))) >= float(v["cost"]))   # R41: arc variants are earned, never bought
	if prog_tab == "mastery":
		for f in favFirst():
			for id in ADMIRALS.keys():
				if or_(ADMIRALS[id].get("fac"), "voidsworn") == f and LINEAGE_TREES.has(id): A(acts, "lineage", id)
	A(acts, "title")
	show_page("legacy", {"tab": prog_tab}, acts)
func lineageScreen(id) -> void:
	if not LINEAGE_TREES.has(id): return
	var acts = []
	for n in lineageNodes(id): A(acts, "offerLineage", n["key"], lineageCanPick(n["key"]))
	A(acts, "offerRespec", id, lineageCanRespec(id)); A(acts, "progTab", "mastery")
	show_page("lineage", {"id": id}, acts)
func ACT_buyLegacy(id: String) -> void:   # R1 (PROG-2)
	var u = LEGACY.get(id)
	if u == null or jt(META["unlocked"].get(id)) or (jt(u.get("req")) and not jt(META["unlocked"].get(u["req"]))) or float(z0(META.get("renown"))) < float(u["cost"]): return
	META["renown"] = float(META["renown"]) - float(u["cost"]); META["unlocked"][id] = true
	persist_save(true); legacyScreen()
func ACT_buyAdmiral(id: String) -> void:   # R1 (PROG-2): bought on the admiral screen, where locked admirals show
	var a = ADMIRALS.get(id)
	if a == null or admiralOwned(id) or float(z0(META.get("renown"))) < float(a["cost"]): return
	META["renown"] = float(META["renown"]) - float(a["cost"]); META["admirals"][id] = true
	tel("admiral_buy", {"id": id, "cost": a["cost"]}); persist_save(true); act("pickAdmiral", id)
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
func facProgress(fac: String) -> float:
	var total = 0.0
	for id in ADMIRALS.keys():
		if or_(ADMIRALS[id].get("fac"), "voidsworn") == fac: total += masteryXP(id)
	return total
func nextFacPick() -> Variant:
	var won = or_(META["stats"].get("wonFacs"), [])
	var pool = RUN_FACTIONS.filter(func(f): return f != RUN["fac"] and not won.has(f))
	if pool.is_empty(): pool = RUN_FACTIONS.filter(func(f): return f != RUN["fac"])
	if pool.is_empty(): return null
	var best = pool[0]; var bestv = facProgress(best)
	for f in pool:
		var v = facProgress(f)
		if v > bestv: best = f; bestv = v
	return best
func shadowAdmirals(fac, flown) -> Array:
	return ADMIRALS.keys().filter(func(id): return or_(ADMIRALS[id].get("fac"), "voidsworn") == fac and id != flown)
func shadowRate(id) -> float:
	return 0.5 if META["heirs"].get(or_(ADMIRALS[id].get("fac"), "voidsworn")) == id else 0.25
func masteryCredit(id, xp) -> Dictionary:
	var cap = masteryXPCap(id); var old = masteryXP(id); var total = old + xp
	META["mastery"][id] = max(old, min(cap, total))   # a reset evolution keeps its earned XP even when the cap drops back to 230
	return {"xp": max(0.0, META["mastery"][id] - old), "overflow": max(0.0, total - max(cap, old))}
func awardLineageXP(flown, fac, xp) -> Dictionary:
	var active = masteryCredit(flown, xp); var shadow = []
	for id in shadowAdmirals(fac, flown): shadow.append({"id": id, "xp": 0.0, "rate": shadowRate(id)})
	var pool = float(z0(META["shadowPool"].get(fac))) + active["overflow"]
	for row in shadow:
		var gain = masteryCredit(row["id"], xp * shadowRate(row["id"])); row["xp"] += gain["xp"]; pool += gain["overflow"]
	while pool > 0:
		var open = shadow.filter(func(row): return masteryXP(row["id"]) < masteryXPCap(row["id"]))
		if open.is_empty(): break
		var weight = 0.0
		for row in open: weight += shadowRate(row["id"])
		var budget = pool; pool = 0.0
		for row in open:
			var gain = masteryCredit(row["id"], budget * shadowRate(row["id"]) / weight); row["xp"] += gain["xp"]; pool += gain["overflow"]
	META["shadowPool"][fac] = pool
	return {"mxGain": active["xp"], "mxOverflow": active["overflow"], "shadow": shadow, "shadowBank": pool}
func inheritanceLine(id) -> Dictionary:
	var level = masteryLevel(id); var xp = masteryXP(id); var thresholds = masteryThresholds(id)
	var tree = LINEAGE_TREES.has(id); var build = lineageBuild(id) if tree else null; var has_cap = build != null and build["capstone"] != null
	var cap_level = capstoneMasteryLevel(id) if tree else 0; var cap_next = capstoneMasteryNext(id) if tree else null
	var next = cap_next if has_cap else (thresholds[level + 1] if level + 1 < thresholds.size() else null)
	return {"id": id, "xp": xp, "level": level, "next": next, "remaining": 0 if next == null else max(0.0, float(next) - xp), "hasCap": has_cap, "capLevel": cap_level, "capNext": cap_next}
func inheritanceSummary(run) -> Dictionary:
	var cy = run["carry"]; var balance = float(z0(META.get("renown"))); var affordable = []
	for id in LEGACY:
		var u = LEGACY[id]
		if not jt(META["unlocked"].get(id)) and (not jt(u.get("req")) or jt(META["unlocked"].get(u["req"]))) and float(u["cost"]) <= balance:
			affordable.append({"id": id, "n": u["n"], "cost": u["cost"], "kind": "Doctrine", "fresh": float(u["cost"]) > balance - float(cy["ren"])})
	for id in HULL_VARIANTS:
		var u = HULL_VARIANTS[id]
		if not jt(u.get("arc")) and not jt(META["variants"].get(id)) and float(u["cost"]) <= balance:
			affordable.append({"id": id, "n": u["n"], "cost": u["cost"], "kind": FACTIONS[HULLS[u["base"]]["fac"]]["n"] + " hull", "fresh": float(u["cost"]) > balance - float(cy["ren"])})
	var flown = inheritanceLine(run["admiral"]); var tree = LINEAGE_TREES.has(run["admiral"]); var build = lineageBuild(run["admiral"])
	var nodes = lineageNodes(run["admiral"]) if tree else []; var chosen = []; var ready = false
	for node in nodes:
		if node["state"] == "chosen": chosen.append(node["n"])
		if node["branch"] == "cap" and node["state"] == "available": ready = true
	var earned = []
	for level in range(int(cy["mx0"]) + 1, mini(4, int(cy["mx1"])) + 1): earned.append(MASTERY_PERKS[level].duplicate(true))
	flown.merge({"tree": tree, "pending": maxi(0, mini(3, int(flown["level"]) - 4) - build["picks"].size()) if tree else 0, "capstoneReady": ready, "chosen": chosen, "earned": earned})
	var shadow = []
	for row in cy["shadow"]:
		var entry = inheritanceLine(row["id"]); entry.merge(row, true); entry["total"] = masteryXP(row["id"]); shadow.append(entry)
	var cores = []
	for id in run.get("coreSync", {}):
		var before = run["coreSync"][id]
		if not PATRONS.has(id) or favourOf(id) <= float(before): continue
		var total = favourOf(id); var tier = favourTier(id); var next = FAVOUR_TIERS[tier + 1] if tier + 1 < FAVOUR_TIERS.size() else null
		cores.append({"id": id, "before": before, "gain": total - float(before), "total": total, "tier": tier, "next": next["at"] if next != null else null,
			"remaining": float(next["at"]) - total if next != null else 0, "tierUp": total >= float(FAVOUR_TIERS[tier]["at"]) and float(before) < float(FAVOUR_TIERS[tier]["at"])})
	return {"balance": balance, "affordable": affordable, "flown": flown, "shadow": shadow, "cores": cores, "nem": nemDebrief(run)}
func endActions(run, nf) -> Array:
	var acts = []
	A(acts, "progTab", "legacy"); A(acts, "progTab", "variants")
	if LINEAGE_TREES.has(run["admiral"]): A(acts, "lineage", run["admiral"])
	else: A(acts, "progTab", "mastery")
	for id in shadowAdmirals(run["fac"], run["admiral"]): A(acts, "nameHeir", id, META["heirs"].get(run["fac"]) != id)
	if nf != null:
		A(acts, "nextFac", nf); A(acts, "newRunScreen")
	else: A(acts, "newRunScreen")
	A(acts, "title")
	return acts
func ACT_nameHeir(id) -> void:
	if page.get("kind") != "end" or RUN != null or SAVED_RUN != null: return
	var d = page["data"]; var run = d["run"]
	if not shadowAdmirals(run["fac"], run["admiral"]).has(id): return
	META["heirs"][run["fac"]] = id; persist_save(true)
	show_page("end", d, endActions(run, d["next"]))
func endRun(victory: bool, abandoned: bool = false) -> void:
	if RUN == null or jt(RUN.get("over")): return
	# Clear the old checkpoint before staging its earnings. Commit both changes together or leave the run as it was.
	var old = []
	if abandoned:
		old = [SAVED_RUN, saved_battle, saved_in_yard, META.duplicate(true), tel_log.duplicate()]
		SAVED_RUN = null; saved_battle = null; saved_in_yard = false
	var s = RUN["stats"]
	if META["stats"].has("finishedRuns") and not jt(RUN.get("over")): META["stats"]["finishedRuns"] += 1
	var prevBest = float(z0(META["stats"].get("best"))); META["stats"]["best"] = max(prevBest, float(RUN["sector"]))
	if victory:
		META["stats"]["wins"] = float(META["stats"]["wins"]) + 1; META["stats"]["wonFacs"] = or_(META["stats"].get("wonFacs"), [])
		if not META["stats"]["wonFacs"].has(RUN["fac"]): META["stats"]["wonFacs"].append(RUN["fac"])
	elif not abandoned:
		META["stats"]["losses"] = float(z0(META["stats"].get("losses"))) + 1
	for f in RUN["fallen"]: META["fallen"].append(f)
	if META["fallen"].size() > 80: META["fallen"] = META["fallen"].slice(META["fallen"].size() - 80)
	tel("run_end", {"victory": victory, "abandoned": abandoned, "fac": RUN["fac"], "stats": s, "nem": nemTelSummary()})   # #122: the run's Nemesis record
	var hl = heatLevel(RUN.get("heat")); var ren = jsround(runRenown() * (1.0 + 0.1 * hl)); META["renown"] = float(z0(META.get("renown"))) + ren
	var mx0 = masteryLevel(RUN["admiral"]); var mxEarned = (float(s["battles"]) - float(s["elites"]) - float(s["bosses"])) + float(s["elites"]) * 2 + float(s["bosses"]) * 5 + (10.0 if victory else 0.0)
	var earnings = awardLineageXP(RUN["admiral"], RUN["fac"], mxEarned)
	if hl > 0:
		# R63: +2 XP per Heat point to the flown line, +1 to the faction shadow pool; cap overflow joins the pool
		var hx = masteryCredit(RUN["admiral"], hl * 2.0)
		earnings["mxGain"] = float(earnings["mxGain"]) + float(hx["xp"]); earnings["mxOverflow"] = float(earnings["mxOverflow"]) + float(hx["overflow"])
		earnings["shadowBank"] = float(z0(META["shadowPool"].get(RUN["fac"]))) + float(hx["overflow"]) + hl; META["shadowPool"][RUN["fac"]] = earnings["shadowBank"]
	var mx1 = masteryLevel(RUN["admiral"])
	runXPTel(RUN, earnings, victory)   # Job 7 step 11: per run XP by line for the F1 play log report
	if victory and hl > 0:
		META["heatBest"] = or_(META.get("heatBest"), {}); META["heatBest"][RUN["fac"]] = max(float(z0(META["heatBest"].get(RUN["fac"]))), hl)
	RUN["carry"] = {"ren": ren, "mx0": mx0, "mx1": mx1, "hl": hl}
	RUN["carry"].merge(earnings)
	if arcs_on and not abandoned and arc_end_cb is Callable and (arc_end_cb as Callable).is_valid() and _arc_played(3): arc_end_cb.call(victory)
	RUN["carry"]["inheritance"] = inheritanceSummary(RUN)
	RUN["over"] = true; SAVED_RUN = null; saved_battle = null
	if abandoned: _persist_save(false, true)
	else: persist_save()
	if abandoned and not last_save_ok:
		SAVED_RUN = old[0]; saved_battle = old[1]; saved_in_yard = old[2]; META = old[3]; tel_log = old[4]
		RUN = null
		changed.emit()
		return
	var nf = nextFacPick() if victory else null
	var acts = endActions(RUN, nf)
	var mins = null
	if jt(RUN.get("t0")): mins = max(1.0, jsround((now_ms() - float(RUN["t0"])) / 60000.0))
	show_page("end", {"victory": victory, "abandoned": abandoned, "run": RUN, "next": nf, "prevBest": prevBest, "mins": mins}, acts)
	RUN = null
	ended = true

# ======================= campaign_run.js: map, fleet, shipyard, drydock, events, rewards =======================
func completeNode(checkpoint := true) -> void:
	var n = findNode(RUN.get("curNode")) if RUN.get("curNode") != null else null
	if n != null: n["done"] = true
	RUN["curNode"] = null; RUN.erase("inYard")
	if checkpoint: saveRun()
# issue 1480 (R381, RULEBOOK 11.8): a retreat puts the fleet back on the stop it came from (the visited stop one column back, or
# the sector's start before the first column); the stop it fled stays on the map unbeaten, with the same seed and enemy
func retreatBack() -> void:
	var n = findNode(RUN.get("curNode")) if RUN.get("curNode") != null else null; var from = null
	if n != null:
		for e in RUN["map"]["edges"]:
			var p = findNode(e[0])
			if e[1] == n["id"] and p != null and jt(p.get("done")):
				from = p["id"]; break
	RUN["pos"] = from; RUN["curNode"] = null; RUN.erase("inYard")
	saveRun()
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
	if showCoreEatOffer(): return
	if showBeat3(): return
	var n = findNode(id); RUN["pos"] = id; RUN["curNode"] = id
	tel("node", {"type": n["type"], "col": n["col"]})
	if _is(n, ["battle", "elite", "boss"]) or nemNodeIs(n):   # issue 1175: an unmet Nemesis meets you at any column 4 stop
		_enter_battle_node(n)
	else: _open_stop(n)

func _open_stop(n: Dictionary) -> void:
	if n["type"] == "event": eventScreen(n)
	elif n["type"] == "shipyard": shipyardScreen(n)
	elif n["type"] in ["drydock", "field"]: repairStopScreen(n)

func battle_node_kind(n: Dictionary, nem: bool) -> String:
	var kind: String = n["type"]
	if kind == "boss": return kind
	if nem or (kind == "battle" and jt(RUN.get("ambush"))): return "elite"
	return kind

func _enter_battle_node(n: Dictionary) -> void:
	var nem = nemNodeIs(n)
	var kind = battle_node_kind(n, nem); var fac = nodeFaction(n)
	if kind == "boss" and nem:   # issue 1480 (R384): he joins the boss fight
		battleScreen({"kind": "boss", "fac": fac, "col": n["col"], "node": n["id"], "nemesis": nemBattleCfg()}); return
	if nem:   # B4: the Nemesis fight (marked on the map beforehand)
		var nem0 = nemActive(); var fa = nemBeh().get("fleet")
		var nc = {"kind": kind, "fac": nem0["fac"], "col": n["col"], "node": n["id"], "nemesis": nemBattleCfg()}
		if fa != null and ARCHETYPES.has(fa): nc["arch"] = fa
		battleScreen(nc); return
	if n["type"] == "battle" and kind == "elite":
		fac = RUN["map"]["fac"] if RUN["fac"] == "hegemony" else "hegemony"; RUN["ambush"] = false
		toast("The Directorate escort you robbed has found you.")
	battleScreen({"kind": kind, "fac": fac, "col": n["col"], "node": n["id"]})

# Issue 1451: Continue into the round the battle was saved at. False (and the save is dropped) when it cannot be restored: Continue
# then loads the last checkpoint (usually the map before the stop), as it did before round saves.
func _resume_saved_battle() -> bool:
	var sb = saved_battle
	var why = ""
	if battle_mode != "external" or not battle_restore.is_valid(): why = "no battle scene"
	# The snapshot carries its own run (taken at the round start), so it does not need the checkpoint to point at the fight: the
	# checkpoint is usually the map before the stop was entered (Artoo on PR 1486). It must belong to the same run, and any newer
	# checkpoint outside a battle has already dropped it (saveRun).
	elif str(SAVED_RUN.get("t0")) != str(sb.get("t0")) or SAVED_RUN.get("reward") != null: why = "the save belongs to another run"
	var res = {}
	if why == "":
		res = battle_restore.call(sb)
		if not (res is Dictionary) or res.has("error") or not (res.get("B") is Dictionary) or not (res.get("run") is Dictionary): why = str(res.get("error", "restore failed")) if res is Dictionary else "restore failed"
	if why != "":
		saved_battle = null
		push_warning("campaign: the round save was not used (%s); back to the last checkpoint" % why)
		if why == "the snapshot is from other rules": toast("The game was updated since this save, so the run goes back to its last checkpoint before this fight.")
		return false
	RUN = res["run"]; B = res["B"]
	if sb.get("campaignRng") is int or sb.get("campaignRng") is float:
		rng.rng_s = int(sb["campaignRng"])
	var c = B["cfg"]
	tel("battle_resume", {"round": B["round"], "kind": c.get("kind"), "fac": c.get("fac")})
	var acts = []
	A(acts, "battle", "win"); A(acts, "battle", "partial"); A(acts, "battle", "loss")
	if c.get("kind") != "boss": A(acts, "c3retreat")
	show_page("battle", {"cfg": c}, acts)
	pending_battle = c; battle_requested.emit()
	return true
# Issue 1451: the battle scene's round start has settled; write the round's snapshot beside the last checkpoint.
# snap: battle_api take_round_snapshot(). True when it is on disk (or saves are off).
func save_battle_round(snap: Dictionary) -> bool:
	if snap.is_empty() or RUN == null or B == null or SAVED_RUN == null or jt(B.get("over")) or jt(B.get("finished")) or not jt(RUN.get("curNode")): return false
	var prev = saved_battle
	saved_battle = {"campaignRng": rng.rng_s, "node": RUN["curNode"], "t0": str(RUN.get("t0")), "round": snap["round"], "fp": snap["fp"], "size": snap["size"], "data": Marshalls.raw_to_base64(snap["bytes"])}
	persist_save()
	if not last_save_ok: saved_battle = prev   # keep memory equal to the disk: a later write never jumps to a round the player was not told about
	return last_save_ok
# Issue 1451: Save and quit to title from the battle menu. The newest round save stays on disk (if none was written, the last
# checkpoint is still there, so nothing is lost and nothing is settled); the run is left, not ended.
func leave_battle_saved() -> void:
	pending_battle = null
	persist_save()
	B = null
	titleScreen()
func _resume_node() -> bool:
	var n = findNode(RUN.get("pos"))
	if n == null: return false
	if jt(n.get("done")):
		# Old saves could land here after the boss prize was paid but before sector exit.
		if n["type"] != "boss": return false
		_advance_sector()
		return true
	if RUN.get("curNode") != n["id"]: return false
	if jt(n.get("nemCleared")):
		if n["type"] != "event" or not jt(n.get("nemEvent")):
			_open_stop(n)
			return true
	if n["type"] == "shipyard" and (saved_in_yard or RUN.get("inYard") == n["id"]):   # issue 1556: inYard is the twins' own mark   # issue 1175: a save taken on the map after leaving through the fleet screen opens the map, as the browser game does
		shipyardScreen(n)
		return true
	if _is(n, ["battle", "elite", "boss"]) or nemNodeIs(n):   # issue 1175: a Nemesis meeting at a rest stop resumes as the fight
		_restore_legacy_story_modifier()
		_enter_battle_node(n)
		return true
	if n["type"] in ["drydock", "field"]:
		repairStopScreen(n)
		return true
	if n["type"] == "event" and not RUN["seenEvents"].is_empty():
		var id = n.get("evId", n.get("nemEvent", RUN["seenEvents"].back()))   # issue 1556: the event drawn on entry
		for e in EVENTS:
			if e["id"] != id: continue
			var ev = _event_for_faction(e)
			for i in range(ev["o"].size()):
				var o = ev["o"][i]; var r = o.get("r")
				if RUN["flags"].get(id) == or_(o.get("k"), str(i)) and r is Dictionary and jt(r.get("fight")):
					_restore_legacy_story_modifier()
					battleScreen(_event_battle_cfg(n, r))
					return true
			show_event(ev)
			return true
		if jt(n.get("nemCleared")):
			eventScreen(n)
			return true
	return false
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
			if canFitModule(s, m): A(acts, "equip", str(i) + ":" + s["uid"])   # R1 (MOD-3)
	for s in RUN["fleet"]: shipCardActs(acts, s, true)
	show_page("fleet", {"back": back}, acts)
	RUN["_fleetBack"] = back
	saveRun()   # issue 1556: a refit fitted or taken off survives a window close (twin: campaign_run.js fleetScreen)
func _fleet_back() -> void: fleetScreen(RUN.get("_fleetBack"))   # undefined in the JS when the fleet screen was never opened this session
func _push_mod(sh, m) -> void: sh["mods"].append(m)
func _fit_module(ship, module_id) -> bool:
	if not canFitModule(ship, module_id): return false
	changeShip(ship, _push_mod.bind(module_id))
	return true

func _fit_from_hold(index: int, ship) -> bool:
	if ship == null: return false
	return not _apply_preview_op("refit", ship["uid"], index).is_empty()

func ACT_equip(arg: String) -> void:   # R1 (MOD-3, Codex PR #1): only a well-formed index and a fit that can do something
	if RUN == null: return
	var p = arg.split(":")
	if p.size() != 2 or p[0].length() > 15 or not p[0].is_valid_int() or p[0].begins_with("-") or p[0].begins_with("+") or (p[0].length() > 1 and p[0].begins_with("0")): return
	if _fit_from_hold(int(p[0]), _ship(p[1])): _fleet_back()
func _pop_mod(sh, i, got: Array) -> void:
	if i < sh["mods"].size(): got.append(sh["mods"].pop_at(i))
func ACT_unequip(arg: String) -> void:
	var p = arg.split(":")
	if p.size() != 2 or not p[1].is_valid_int(): return   # issue 1556: only a well-formed uid:index
	var s = _ship(p[0])
	if s == null: return
	var got = []
	changeShip(s, _pop_mod.bind(int(p[1]), got))
	if got.size() > 0 and jt(got[0]): RUN["inventory"].append(got[0])
	_fleet_back()
func promoteModal(uid: String, after: Callable) -> void:
	var s = _ship(uid)
	if s == null or not jt(s["cap"].get("pending")):
		after.call(); return
	_offer_perks(s)
	promote_after = after
	var acts = []
	for p in s["cap"]["offer"]: A(acts, "takePerk", uid + ":" + p)
	show_modal("promote", {"ship": s}, acts)
func _captain_perk_pool(ship: Dictionary) -> Array:
	var hull: Dictionary = HULLS[ship["tpl"]]
	var d: Dictionary = derive(ship)
	var ab = hull.get("ab")
	var cooldown: float = TB.ABILITIES.get(ab, {}).get("cd", 0) - z0(d["fx"].get("cdMod"))
	if ab != "launch" and z0(runFx().get("coolant")) > 0: cooldown -= 1
	var known: Array = PERKS.keys()
	known.sort()
	return CaptainData.perk_pool(known, ship.cap.perks, d, _hull_can_brace(hull), cooldown, ab == "launch" and d.hangar > 0)

func _roll_captain_perk(ship: Dictionary) -> void:
	var pool := _captain_perk_pool(ship)
	if not pool.is_empty(): ship["cap"]["perks"].append(pick(pool))

func _offer_perks(s: Dictionary) -> void:
	var pool := _captain_perk_pool(s)
	var offer: Array = or_(s["cap"].get("offer"), [])
	if offer.is_empty() or offer.any(func(perk): return not pool.has(perk)):
		s["cap"]["offer"] = shuffle(pool).slice(0, 2)
func _take_perk(sh, perk) -> void:
	sh["cap"]["perks"].append(perk); sh["cap"]["pending"] = float(sh["cap"]["pending"]) - 1; sh["cap"]["offer"] = null
	CaptainData.update_trait(sh["cap"], PERKS)
func ACT_takePerk(arg: String) -> void:
	var p = arg.split(":"); var s = _ship(p[0])
	if s == null or p.size() != 2 or not jt(s["cap"].get("pending")) or not or_(s["cap"].get("offer"), []).has(p[1]): return
	changeShip(s, _take_perk.bind(p[1]))
	if RUN.get("reward") != null and RUN["reward"]["stage"] == "promo":
		promotionsStep()
		return
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
	if legacyHullOn("u_carrier"): hulls.append("reliquary")
	if legacyHullOn("u_battleship"): hulls.append("cathedral")
	if legacyHullOn("u_dread"): hulls.append("ascendant")
	var own = []
	for h in hulls:
		var e = equivHull(h, RUN["fac"])
		if not own.has(e): own.append(e)
	hulls = own
	var pickH = ssort(shuffle(hulls.duplicate()).slice(0, 3), func(a, b): return float(or_(HULLS[a].get("cp"), 1)) - float(or_(HULLS[b].get("cp"), 1)))
	for h in pickH.duplicate():
		for vid in HULL_VARIANTS.keys():
			if HULL_VARIANTS[vid]["base"] == h and variantOwned(vid): pickH.insert(pickH.find(h) + 1, vid)
	var cap = shuffle(cinderPool()).slice(0, 2) if cinderOpen() else []   # R78 Q9: captured Hegemony and Eclipse hulls from run 3, class unlocks apply
	n["stock"] = {"hulls": pickH, "mods": shuffle(modulePool()).slice(0, 3), "sold": [], "cap": cap}
	if float(RUN["sector"]) >= 3: n["stock"]["late"] = lateStock(n)
	return n["stock"]
# issue 1178: the Sector 3 market (twin of campaign_run.js lateStock / lateShopOffers / ACT.lateBuy). Picked without the random stream.
func lateStock(n: Dictionary) -> Dictionary:
	var pool = []
	for r in RELICS.keys():
		if not RUN["relics"].has(r) and relicUseful(r) and not TB["LATE_SHOP"]["skip"].has(r): pool.append(r)
	pool.sort()
	var k = (int(z0(n.get("col"))) * 7 + int(RUN["stats"]["battles"]) * 3) % pool.size() if pool.size() > 0 else 0
	return {"relics": [pool[k], pool[(k + 1) % pool.size()]] if pool.size() > 1 else pool.duplicate(), "bought": [], "cp": false}
func lateShopOffers() -> Array:
	if yard_node == null or not yard_node.get("stock") is Dictionary or not yard_node["stock"].get("late") is Dictionary: return []
	var st = yard_node["stock"]["late"]; var pm = priceMult(); var L = TB["LATE_SHOP"]
	var rc = jsround(float(L["relic"]) * pm); var cc = jsround(float(L["cp"]) * pm); var out = []
	for r in st["relics"]:
		if L["skip"].has(r) and not st["bought"].has(r): continue   # issue 1290: an older save's yard stock never sells a skipped relic
		out.append({"id": "relic:" + str(r), "kind": "relic", "r": r, "cost": rc, "value": 2, "ok": not st["bought"].has(r) and not RUN["relics"].has(r) and shopCan(rc), "done": st["bought"].has(r)})
	var lc = float(z0(RUN.get("lateCp")))
	out.append({"id": "cp", "kind": "cp", "cost": cc, "value": 1, "ok": not jt(st["cp"]) and lc < float(L["cpMax"]) and shopCan(cc), "done": jt(st["cp"]), "full": lc >= float(L["cpMax"])})
	return out
func ACT_lateBuy(id: String) -> void:
	var o = null
	for x in lateShopOffers():
		if x["id"] == id: o = x
	if o == null or not o["ok"]: return
	var st = yard_node["stock"]["late"]; shopPay(o["cost"])
	if o["kind"] == "relic":
		st["bought"].append(o["r"]); changeFleet(func(): addRelic(o["r"]))
		toast(relicName(o["r"]) + " is yours. " + str(RELICS[o["r"]]["d"]))
	else:
		st["cp"] = true; RUN["lateCp"] = float(z0(RUN.get("lateCp"))) + 1; RUN["cpCap"] = float(RUN["cpCap"]) + 1
		toast("Command grows: " + numstr(RUN["cpCap"]) + " command points.")
	tel("shop", {"k": "late", "id": id, "cost": o["cost"]}); shipyardScreen(yard_node)
# issue 1178: Eclipse core recovery (twin of campaign_run.js coreCost / ACT.restoreCore)
func coreCost(tpl) -> float: return jsround(shipValue(tpl) * float(TB["LATE_SHOP"]["core"]) * priceMult())
# issue 1384: after a battle a regrown ship loses its sell-for-0 mark but keeps the cap; a ship regrown in a save from before
# issue 1384 has no corePaid, so it takes today's regrow price as its cap before the mark is cleared (campaign_run.js settleRegrown)
func settleRegrown() -> void:
	for sh in RUN["fleet"]:
		if sh.get("regrown") and sh.get("corePaid") == null: sh["corePaid"] = coreCost(sh["tpl"])
		sh.erase("regrown")
func ACT_restoreCore(a: String) -> void:
	var cs = or_(RUN.get("cores"), []); var i = int(a)
	if i < 0 or i >= cs.size() or not HULLS.has(cs[i]): return
	var tpl = cs[i]; var c = coreCost(tpl)
	if float(RUN["credits"]) < c or fleetCP() + float(or_(HULLS[tpl].get("cp"), 1)) > float(RUN["cpCap"]): return
	RUN["credits"] = float(RUN["credits"]) - c; cs.remove_at(i); var s = newShip(tpl); s["regrown"] = true; s["corePaid"] = c; RUN["fleet"].append(s)
	tel("shop", {"k": "core", "id": tpl, "cost": c}); toast(ship_with_article(s["name"], true) + " wakes from its core."); shipyardScreen(yard_node)
func shipyardScreen(n) -> void:
	yard_node = n
	var st = shipyardStock(n); var pm = priceMult(); var cp = fleetCP()
	var acts = []
	A(acts, "yardFleet"); A(acts, "leaveYard")
	A(acts, "repairAll", "", preview_op("repairAll")[0]["disabled_reason"].is_empty())
	var cores = or_(RUN.get("cores"), [])
	for i in range(cores.size()):
		A(acts, "restoreCore", i, float(RUN["credits"]) >= coreCost(cores[i]) and cp + float(or_(HULLS[cores[i]].get("cp"), 1)) <= float(RUN["cpCap"]))
	for o in lateShopOffers():
		if not jt(o["done"]) and not jt(o.get("full")): A(acts, "lateBuy", o["id"], o["ok"])
	for s in RUN["fleet"]:
		shipCardActs(acts, s, false)
		A(acts, "repair", s["uid"], preview_op("repair", s["uid"])[0]["disabled_reason"].is_empty())
		A(acts, "upgradeMk", s["uid"], preview_op("upgradeMk", s["uid"])[0]["disabled_reason"].is_empty())
		A(acts, "sellShip", s["uid"], RUN["fleet"].size() > 1)
	for h in st["hulls"]:
		A(acts, "buyHull", h, preview_op("buyHull", h)[0]["disabled_reason"].is_empty())
	for h in (st["cap"] if st.get("cap") is Array else []):
		A(acts, "buyHull", h, preview_op("buyHull", h)[0]["disabled_reason"].is_empty())
	for i in range(st["mods"].size()):
		if not _has_num(st["sold"], i): A(acts, "buyMod", i, preview_op("buyMod", "", i)[0]["disabled_reason"].is_empty())
	for cls in fleetClasses():
		A(acts, "buyTrack", cls, classTrack(cls) < float(CLASS_TRACK_MAX) and shopCan(classTrackCost(cls)))
	show_page("shipyard", {"node": n, "pm": pm}, acts)
	if n.get("id") != null: RUN["inYard"] = n["id"]
	else: RUN.erase("inYard")
	saveRun()   # issue 1556: every stock roll, buy, sale, repair and refit is on disk at once (twin: campaign_run.js)
	if RUN.has("boughtRefit"): _bought_refit_card()
# a class as players see it (data.js clsName, lore round 8 row 4.0): cls stays the lookup key
func clsName(c) -> String: return str(TB.get("CLS_NAME", {}).get(str(c), str(c)))
func fleetClasses() -> Array:
	var out = []
	for s in RUN["fleet"]:
		var c = HULLS[s["tpl"]].get("cls")
		if not out.has(c): out.append(c)
	return out
func ACT_buyTrack(cls: String) -> void:
	if not buyClassTrack(cls): return
	tel("shop", {"k": "track", "id": cls, "lv": classTrack(cls)})
	toast(clsName(cls) + " refit level " + numstr(classTrack(cls)) + ": every " + clsName(cls).to_lower() + " gains."); shipyardScreen(yard_node)
func ACT_buyHull(h: String) -> void:
	var p := _apply_preview_op("buyHull", h)
	if p.is_empty(): return
	tel("shop", {"k": "hull", "id": h, "cost": p["price"]})
	toast(ship_with_article(p["ship"]["name"], true) + " joins the fleet.")
	shipyardScreen(yard_node)
func ACT_buyMod(a: String, show_fit := false) -> void:
	if yard_node == null or not str(a).is_valid_int(): return
	if show_fit and (page.get("kind") != "shipyard" or modal_d != null): return
	var p := _apply_preview_op("buyMod", "", int(a))
	if p.is_empty(): return
	var m: String = p["key"]
	tel("shop", {"k": "mod", "id": m, "cost": p["price"]})
	if show_fit:
		RUN["boughtRefit"] = {"yard": yard_node.get("id"), "module": m, "index": RUN["inventory"].size() - 1}
		saveRun()
		_bought_refit_card()
	else:
		toast(modName(m) + " is in the hold. Fit it from Refits.")
		shipyardScreen(yard_node)

func _bought_refit_card() -> void:
	var receipt = RUN.get("boughtRefit")
	if not (receipt is Dictionary) or receipt.get("yard") != yard_node.get("id"): return
	var index = receipt.get("index")
	if not (index is float or index is int) or index < 0 or index >= RUN["inventory"].size(): return
	var module_id = RUN["inventory"][int(index)]
	if module_id != receipt.get("module") or not MODULES.has(module_id): return
	var acts = []
	A(acts, "keepBoughtRefit")
	show_modal("bought_refit", {"module": module_id, "index": int(index)}, acts)

func ACT_finishBoughtRefit(uid := "") -> void:
	if modal_d == null or modal_d["kind"] != "bought_refit" or not RUN.has("boughtRefit"): return
	var offer = modal_d["data"]
	if uid != "":
		var ship = _ship(uid)
		var index: int = offer["index"]
		if index >= RUN["inventory"].size() or RUN["inventory"][index] != offer["module"]: return
		if not _fit_from_hold(index, ship): return
		_refit_fitted_notice(offer["module"], ship)
	else:
		toast(modName(offer["module"]) + " stowed in the hold.")
	RUN.erase("boughtRefit")
	shipyardScreen(yard_node)
# Issue 2029 item 7: a yard repair buys as many hull points as the purse allows, at the price of a full repair per point
# (priceMult / 2 each, the whole bill rounded up as ever). repairPoints is how many of the `miss` missing points `funds` pays
# for; repairBill is what those points cost. A purse that covers everything pays exactly the old bill; one that cannot buy a
# single point gets 0 (the button stays off). repairAll stays all or nothing.
func repairBill(points: float, pm: float) -> float: return ceil(points / 2.0 * pm)
func repairPoints(miss: float, pm: float, funds: float) -> float:
	if miss <= 0.0: return 0.0
	if repairBill(miss, pm) <= funds: return miss
	var pts = floor(funds * 2.0 / maxf(pm, 0.0001) + 0.000001)
	while pts > 0.0 and repairBill(pts, pm) > funds: pts -= 1.0
	return clampf(pts, 0.0, miss)
func preview_op(action: String, key := "", slot := -1) -> Array:
	return PreviewOp.plan(self, action, key, slot)["rows"]

# An incoming hull starts at full derived hull. A recovered captain's perks apply before that derivation.
func incoming_ship(tpl: String, captured := false, nth := 0) -> Dictionary:
	var cap := CaptainData.make("", factionOfTpl(tpl), "")
	var reserve_present: bool = B == null and RUN != null and RUN.get("reserve") is Array and nth >= 0 and nth < RUN["reserve"].size()
	if reserve_present: cap = RUN["reserve"][nth]["cap"].duplicate(true)
	var ship := {"uid": "", "tpl": tpl, "mk": 1, "mods": [], "cap": cap, "hp": 0}
	if captured: ship["ripped"] = true
	ship["hp"] = derive(ship)["maxHp"]
	return ship

func _apply_preview_op(action: String, key := "", slot := -1) -> Dictionary:
	var p := PreviewOp.plan(self, action, key, slot)
	if not p["reason"].is_empty(): return {}
	var purse: String = p["purse"]
	if purse in ["bio", "credits"]: RUN[purse] = float(z0(RUN.get(purse))) - p["price"]
	if action == "buyHull":
		var ship: Dictionary = p["ship"]
		var fac := factionOfTpl(key)
		ship["uid"] = new_id()
		ship["name"] = shipName(fac)
		var fresh := newCaptain(false, fac, ship["uid"]) # Keep the same seeded name draw even if the reserve takes command.
		if ship["cap"]["full_name"].is_empty():
			ship["cap"] = fresh
		else:
			var recovered: Dictionary = RUN["reserve"].pop_front()
			toast(str(recovered["cap"]["full_name"]) + " recovers and takes command of " + ship_with_article(ship["name"]) + ".")
		RUN["fleet"].append(ship)
	elif action == "buyMod":
		yard_node["stock"]["sold"].append(slot)
		RUN["inventory"].append(p["key"])
	else:
		for entry in p["entries"]:
			var live: Dictionary = entry["before"]; var after: Dictionary = entry["after"]
			live["hp"] = after["hp"]
			if action == "refit" or action == "upgradeMk":
				live["mk"] = after["mk"]; live["mods"] = after["mods"]
				if after.has("hpOwed"): live["hpOwed"] = after["hpOwed"]
				else: live.erase("hpOwed")
		if action == "refit": RUN["inventory"].remove_at(slot)
	return p

func ACT_repair(uid: String) -> void:
	if not _apply_preview_op("repair", uid).is_empty(): shipyardScreen(yard_node)
func ACT_repairAll() -> void:
	if not _apply_preview_op("repairAll").is_empty(): shipyardScreen(yard_node)
func _mk_up3(sh) -> void:
	if float(sh["mk"]) < 3: sh["mk"] = float(sh["mk"]) + 1
func ACT_upgradeMk(uid: String) -> void:
	var p := _apply_preview_op("upgradeMk", uid)
	if p.is_empty(): return
	var s: Dictionary = p["ship"]
	tel("shop", {"k": "mk", "id": s["tpl"], "cost": p["price"]})
	toast(str(s["name"]) + " refitted to Mk " + roman(s["mk"]) + "."); shipyardScreen(yard_node)
func ACT_sellShip(uid: String) -> void:
	if RUN["fleet"].size() <= 1: return
	var s = _ship(uid)
	var acts = []; A(acts, "sellConfirm", uid); A(acts, "closeModal")
	show_modal("sell", {"ship": s, "value": sellValue(s), "word": hullWord()}, acts)
func ACT_sellConfirm(uid: String) -> void:
	var i = -1
	for k in range(RUN["fleet"].size()):
		if RUN["fleet"][k]["uid"] == uid:
			i = k; break
	if i < 0: return
	var s = RUN["fleet"][i]
	RUN["inventory"].append_array(s["mods"]); hullPay(-sellValue(s)); RUN["fleet"].remove_at(i)
	changeFleet(func(): ensureFlagship())   # issue 1384: selling the flagship hands the Aspect on at once (campaign_run.js sellConfirm)
	close_modal(); shipyardScreen(yard_node)
func _repair_stop_options(kind: String) -> Array:
	var drydock := kind == "drydock"
	var rate := (0.6 if drydock else 0.2) * repairMult()
	var options := []
	for cut in [false, true]:
		var r: float = rate / 2 if cut else rate
		var hp := 0.0
		var gains := []
		for s in RUN["fleet"]:
			var mx := float(derive(s)["maxHp"])
			var miss := maxf(0, mx - float(s["hp"]))
			var gain := minf(miss, ceilf(miss * r) if drydock else jsround(mx * r))
			gains.append(gain)
			hp += gain
		options.append({"rate": numstr(jsround(r * 10000) / 100.0) + "%", "hp": hp, "gains": gains, "credits": (35 if drydock else 15) if cut else 0})
	return options

func repairStopScreen(n: Dictionary) -> void:
	mapScreen()
	saveRun()
	var acts := []
	A(acts, "repairStop", "service"); A(acts, "repairStop", "stipend")
	show_modal("repair_stop", {"kind": n["type"], "options": _repair_stop_options(n["type"])}, acts)

func ACT_repairStop(choice: String) -> void:
	if not (choice in ["service", "stipend"]) or modal_d == null or modal_d["kind"] != "repair_stop": return
	var n = findNode(RUN.get("curNode"))
	if n == null or jt(n.get("done")) or not (n["type"] in ["drydock", "field"]): return
	var opt = _repair_stop_options(n["type"])[0 if choice == "service" else 1]
	for i in range(RUN["fleet"].size()):
		var s = RUN["fleet"][i]
		s["hp"] = float(s["hp"]) + opt["gains"][i]
	RUN["credits"] = float(RUN["credits"]) + opt["credits"]
	if n["type"] == "field": tel("field_repairs", {})
	completeNode(); mapScreen()
	var result := "+" + numstr(opt["hp"]) + " hull across the fleet"
	if opt["credits"] > 0: result += " and +" + numstr(opt["credits"]) + " credits"
	toast(result + ".")
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
	if jt(nd.get("flag")) and not flagIs(nd["flag"], nd.get("flagK")): return false
	if jt(nd.get("intel")):
		var nem0 = nemActive(); var rv = nem0["revealed"] if (nem0 is Dictionary and nem0.get("revealed") is Array) else []
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
	if jt(nd.get("relic")): p.append("a piece of salvage" if ((nd["relic"] is float or nd["relic"] is int) and float(nd["relic"]) == 1.0) else relicName(nd["relic"]))
	if jt(nd.get("mod")): p.append("a refit in the hold")
	if jt(nd.get("cred")): p.append(numstr(nd["cred"]) + " credits")
	if jt(nd.get("vet")):
		var fac = RUN["fac"]
		var ranks = CAPTAINS[fac]["ranks"] if fac in ["chorus", "deathless"] else RANKS
		p.append("a " + str(ranks[int(nd["vet"])]) + " or better")
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
func _event_for_faction(ev: Dictionary) -> Dictionary:
	var out = ev.duplicate(false)
	if jt(ev.get("v")) and jt(ev["v"].get(RUN["fac"])): out.merge(ev["v"][RUN["fac"]], true)
	return out
func eventScreen(n) -> void:
	# issue 1556: the event drawn on entry stays on the node and on disk, so a reload shows the same event (twin: campaign_run.js)
	var event = null
	var want = (n.get("evId") if jt(n.get("evId")) else n.get("nemEvent")) if n != null else null
	if jt(want):
		for e in EVENTS:
			if e["id"] == want: event = e; break
	if event == null:
		event = nextEvent()
		if n != null: n["evId"] = event["id"]
	if n != null and jt(n.get("nemCleared")): n["nemEvent"] = event["id"]
	if n != null: saveRun()
	if n != null and (jt(n.get("nemCleared")) or n.get("evFight") != null):   # issue 1628: a stop whose fight choice was made (then retreated from) goes straight back to that fight (twin: campaign_run.js)
		var evf = _event_for_faction(event); var want_k = n["evFight"] if n.get("evFight") != null else RUN["flags"].get(event["id"])
		for i in range(evf["o"].size()):
			var o = evf["o"][i]; var r = o.get("r")
			if want_k == or_(o.get("k"), str(i)) and r is Dictionary and jt(r.get("fight")):
				battleScreen(_event_battle_cfg(n, r)); return
	show_event(_event_for_faction(event))
func show_event(ev: Dictionary) -> void:
	cur_event = ev
	mapScreen()
	var acts = []
	for i in range(cur_event["o"].size()):
		A(acts, "eventChoice", i, eventOptOk(cur_event["o"][i]))
	show_modal("event", {"ev": cur_event}, acts)
# issue 1449: a relic trade never takes salvage silently. With one piece the choice names it; with two or more the player picks first.
func relicTradeNote(o) -> String:
	var r = o.get("r") if o is Dictionary else null
	if not (r is Dictionary) or not jt(r.get("payRelic")) or RUN["relics"].is_empty(): return ""
	return (" You give up " + relicName(RUN["relics"][0]) + ".") if RUN["relics"].size() == 1 else " You choose which piece."
func relic_pick_modal(i: int) -> void:
	var acts = []
	for j in range(RUN["relics"].size()): A(acts, "eventChoice", str(i) + ":" + str(j))
	A(acts, "eventBack")
	show_modal("relic_pick", {"ev": cur_event, "i": i, "relics": RUN["relics"].duplicate()}, acts)
func ACT_eventBack() -> void:
	if cur_event is Dictionary and not cur_event.is_empty(): show_event(cur_event)
# B4: every event choice writes a flag later systems read (faction verbs, the Nemesis): RUN.flags[event id] = the option's key, plus any counters
# R1 (EVT-1): a flag gate can name the choices that open it (flagK), not only that the event happened
func flagIs(id, ks) -> bool:
	var v = RUN["flags"].get(id) if RUN != null and RUN.get("flags") is Dictionary else null
	return v != null and (not jt(ks) or ks.has(v))
func eventFlags(ev, o, i: int) -> void:
	if not (RUN.get("flags") is Dictionary): RUN["flags"] = {}
	RUN["flags"][ev["id"]] = o["k"] if jt(o.get("k")) else str(i)
	var fl = o.get("fl") if o.get("fl") is Dictionary else {}
	for k in fl.keys(): RUN["flags"][k] = float(z0(RUN["flags"].get(k))) + float(fl[k])
# ---------- B4 the Nemesis (campaign rules; the battle rules apply his weaknesses and adaptations in the fight) ----------
# R42 (Oct 26): a fresh identity every run from the faction's own pools (never a CAPTAINS or ADMIRALS name), a personality, two strength
# traits, a portrait id (nem_<faction>_1..6) with scar overlays, and faction behaviour (NEM_FAC[fac].beh) on the map and in battle.
# #120: the section 1 draw: H1 uniform over the five non-player factions; H2 uniform over the four that are not H1;
# H3 uniform over the four that are not H2 (so H3 may be H1 again). Drawn once at run start from the run RNG.
func drawNemAssign() -> Array:
	var pool = RUN["foes"].duplicate() if (RUN.get("foes") is Array and RUN["foes"].size() >= 3) else RUN_FACTIONS.filter(func(f): return f != RUN["fac"])
	var a = [pick(pool)]
	a.append(pick(pool.filter(func(f): return f != a[0])))
	a.append(pick(pool.filter(func(f): return f != a[1])))
	return a
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
# Capabilities come from the actual refitted fleet and the rival's hull roster.
func _nem_kit_fit(key: String, fac: String, kit: Dictionary) -> bool:
	# Legacy summaries can describe an opponent without a player fleet to inspect.
	if not RUN.has("fleet"): return true
	match key:
		"ion", "shields":
			return (kit.has("lance") or kit.has("ion")) and HULLS.values().any(func(h): return h.get("fac") == fac and z0(h.get("sh")) > 0)
		"torp": return kit.has("torp")
		"pd": return (kit.has("torp") or kit.has("sq")) and HULLS.values().any(func(h):
			return h.get("fac") == fac and not h.get("w", []).any(func(w): return W_[w[0]]["k"] == "flak"))
		"board", "armor": return not RUN.get("fleet", []).is_empty()
		"evasion", "aim", "flank", "brawl", "slow": return not RUN.get("fleet", []).is_empty()
	return true

func newNemesis(fac0 = null) -> Dictionary:
	var fac = fac0 if jt(fac0) else RUN["foes"][3] if (RUN.get("foes") is Array and RUN["foes"].size() > 3 and jt(RUN["foes"][3])) else pick(RUN_FACTIONS.filter(func(f): return f != RUN["fac"]))
	var F = NEM_FAC[fac]; var beh = F["beh"]
	var name = nemName(fac)
	var title = pick(F["titles"]); var persona = pick(F["personas"]); var traits = shuffle(F["traits"].duplicate()).slice(0, 2)
	var portrait = "nem_" + str(fac) + "_" + numstr(1 + floor(rnd() * 6))
	var clash = {"slow": "swift", "board": "boarders", "ion": "shielded"}   # no strength and weakness that cancel out
	var kit := fleetKit()
	var weakPool = NEM_WEAK.keys().filter(func(k): return not (k == "anchor" and (jt(beh.get("noFlee")) or jt(beh.get("revive")))) and not (clash.has(k) and traits.has(clash[k])))   # zealots and the Deathless never break
	var g = nemGender(fac, name)
	var weak = shuffle(weakPool).filter(func(k): return _nem_kit_fit(k, fac, kit)).slice(0, 2)
	return {"fac": fac, "name": name, "g": g, "title": title, "persona": persona, "traits": traits, "portrait": portrait, "weak": weak, "revealed": [], "adapt": [], "adaptSector": 0, "met": 0,
		"beaten": 0, "scars": 0, "scarKinds": [], "epithets": [], "epithet": null, "last_beat": null, "fed": 0, "riches": 0, "loot": 0, "held": null, "gloat": null, "honed": 0,
		"revived": false, "dead": false, "seen": {}, "signatures": [], "lessons": []}   # #121: no clock or strike here (they are the run's)
# R1 (NEM-7): what a pre-persona save keeps when it gets its new identity: everything the rival has built up
const NEM_CARRY = ["weak", "revealed", "adapt", "clock", "met", "beaten", "scars", "dead", "strike", "seen", "loot", "riches", "fed", "honed", "held", "revived", "gloat", "last_beat"]
# a pre-persona rival keeps his faction: the stored one, else the one whose own adaptation he already carries
func nemOldFac(old) -> Variant:
	if jt(old.get("fac")) and NEM_FAC.has(old["fac"]): return old["fac"]
	var a = or_(old.get("adapt"), [])
	for f in NEM_ADAPT_FAC.keys():
		var sp = NEM_ADAPT_FAC[f].get("special")
		if NEM_FAC.has(f) and jt(sp) and a.has(sp["id"]): return f
	return null
# #120 save migration: a pre-registry run has one RUN.nem and no assignment or registry. It becomes the current story
# point's entry (the owner ruled the other story points need no rule; no pre-Nemesis saves exist). New-format runs keep theirs.
func nemMigrate() -> void:
	if RUN == null or RUN.get("fleet") == null: return
	if not (RUN.get("nems") is Dictionary): RUN["nems"] = {}
	if not (RUN.get("nemAssign") is Array): RUN["nemAssign"] = [null, null, null]
	var reg = RUN["nems"]
	if jt(RUN.get("nem")) and reg.size() == 0:
		var old = RUN["nem"]; var n = old
		if not jt(old.get("persona")) and RUN.get("fleet") != null:
			n = newNemesis(nemOldFac(old))
			for k in NEM_CARRY:
				if old.get(k) != null: n[k] = old[k]
			if jt(old.get("beat")) and not jt(old.get("last_beat")): n["last_beat"] = old["beat"]
			var sp = NEM_ADAPT_FAC[n["fac"]].get("special") if NEM_ADAPT_FAC.has(n["fac"]) else null
			n["adapt"] = n["adapt"].filter(func(x): return NEM_ADAPT.has(x) or (jt(sp) and sp["id"] == x))
		var i = max(0, min(int(RUN["nemAssign"].size()) - 1, int(RUN.get("sector", 1)) - 1))
		RUN["nemAssign"][i] = n["fac"]; reg[n["fac"]] = n; RUN["nem"] = null
	for k in reg.keys():
		var N = reg[k]
		if not (N is Dictionary) or not jt(N.get("persona")): continue
		if jt(N.get("beat")) and not jt(N.get("last_beat")): N["last_beat"] = "battery" if N["beat"] == "ion" else N["beat"]
		N.erase("beat")
		if not jt(N.get("g")): N["g"] = nemGender(N["fac"], str(N["name"]) if jt(N.get("name")) else "")
		N.erase("pronoun")
		if N.get("scarList") is Array and not jt(N.get("scarKinds")):
			N["scarKinds"] = N["scarList"].filter(func(x): return not str(x).begins_with("ep:"))
			N["epithets"] = N["scarList"].filter(func(x): return str(x).begins_with("ep:")).map(func(x): return str(x).substr(3))
		N.erase("scarList")
		N["scarKinds"] = or_(N.get("scarKinds"), []); N["epithets"] = or_(N.get("epithets"), ([N["epithet"]] if jt(N.get("epithet")) else [])); N["signatures"] = or_(N.get("signatures"), [])
		N["lessons"] = N["lessons"] if N.get("lessons") is Array else []
	# #121: a save from before the run clock keeps the clock and strike of the commander it was on (the active one), then no commander holds one
	if not (RUN.get("nemClock") is float or RUN.get("nemClock") is int):
		var slot = nemAssignSlot(); var src = reg[slot] if (slot != null and reg.has(slot)) else (reg.values()[0] if reg.size() > 0 else null)
		RUN["nemClock"] = src["clock"] if (src is Dictionary and (src.get("clock") is float or src.get("clock") is int)) else 0
		RUN["nemStrike"] = src is Dictionary and jt(src.get("strike"))
	if not (RUN.get("nemStrike") is bool): RUN["nemStrike"] = jt(RUN.get("nemStrike"))
	# #122: a save from before the escape counter rebuilds it from the scars his commanders carry (each escape left one; a revive's scar is
	# not an escape), at most two a run. A sector 3 flight also scars, so a save made after one can count one escape too many.
	if not (RUN.get("nemEscapes") is float or RUN.get("nemEscapes") is int):
		var e = 0.0
		for k in reg.keys():
			if reg[k] is Dictionary: e += max(0.0, float(z0(reg[k].get("scars"))) - (1.0 if jt(reg[k].get("revived")) else 0.0))
		RUN["nemEscapes"] = min(2.0, e)
	for k in reg.keys():
		if reg[k] is Dictionary:
			reg[k].erase("clock"); reg[k].erase("strike")
func nemAssignSlot() -> Variant:
	var a = RUN.get("nemAssign") if RUN != null else null
	if not (a is Array): return null
	var i = int(RUN["sector"]) - 1
	if i >= 0 and i < a.size() and jt(a[i]): return a[i]
	var j = min(i, a.size() - 1)
	while j >= 0:
		if jt(a[j]): return a[j]
		j -= 1
	return null
# The sector dialog may name an outgoing hunter who is no longer active. Read
# the existing assignment and registry without resolving or creating anybody.
func nemCanReturn(fac: String) -> bool:
	if RUN == null or jt(RUN.get("over")) or not (RUN.get("nemAssign") is Array): return false
	var N = RUN.get("nems", {}).get(fac)
	if not (N is Dictionary) or jt(N.get("dead")): return false
	var assigned = nemAssignSlot()
	var slots: Array = RUN["nemAssign"]
	for sector in range(int(RUN["sector"]), 4):
		if sector <= slots.size() and jt(slots[sector - 1]): assigned = slots[sector - 1]
		if assigned == fac and z0(N.get("met")) < sector: return true
	return false
func nemActive() -> Variant:
	if RUN == null: return null
	if RUN.get("fleet") == null: return RUN.get("nem")
	nemMigrate()
	var fac = nemAssignSlot()
	if jt(fac):
		var reg = RUN["nems"]
		if not reg.has(fac): reg[fac] = newNemesis(fac)
		RUN["nem"] = reg[fac]
	return RUN.get("nem")
# Issue 364: the Nemesis the run is fighting now, read with no side effect. A screen asks this instead of RUN.nem (the cache
# nemActive keeps fresh) or a run dictionary's own "nem" field, so a reader can never show the commander of a sector already
# passed. It resolves the run's current assignment against the commander registry and never migrates a save, creates or draws
# a commander, or writes the cache. Pass run0 (a page's finished run) or leave it null for the current run. Null when the run
# has no commander yet, or the assigned one has not been built. A save from before the registry (no nemAssign) answers its
# one commander exactly as before.
func nemRead(run0 = null) -> Variant:
	var run = run0 if run0 is Dictionary else RUN
	if not (run is Dictionary):
		return null
	if run.get("fleet") == null:
		return run.get("nem")
	var cur = run.get("nem")
	var a = run.get("nemAssign")
	if not (a is Array) or a.is_empty():
		return cur
	var i = int(or_(run.get("sector"), 1)) - 1
	var fac = null
	var j = min(i, a.size() - 1)
	while j >= 0:
		if jt(a[j]): fac = a[j]; break
		j -= 1
	if not jt(fac):
		return cur
	var reg = run.get("nems") if run.get("nems") is Dictionary else {}
	if reg.has(fac) and reg[fac] is Dictionary:
		return reg[fac]
	return cur if (jt(cur) and str(cur.get("fac", "")) == str(fac)) else null
func ensureNemesis() -> Variant: return nemActive()   # B4 saves get an R42 identity; the active commander resolves from the assignment
# R42 gender for the story layer's pronouns: 'n' (it) for the Chorus, 'f' when his first name part is a feminine one, else 'm'. No random draw.
func nemGender(fac, name: String) -> String:
	var F = NEM_FAC.get(fac, {}) if fac != null else {}
	if jt(F.get("g")): return str(F["g"])
	# Saves from before the name pool changed may still need a pronoun for Maren.
	if fac == "hegemony" and name.get_slice(" ", 0) == "Maren": return "f"
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
# Issue 344: his behaviour is read from the commander given (nemBeh(N)), so a screen that read him with nemRead gets the line
# without resolving anyone. Every caller passes the active commander, so the words are what they were.
func nemWarnLine(N) -> String:
	var st = nemBeh(N).get("strike")
	if nemBossOnly(N) or jt(RUN.get("nemStrike")) or float(N["met"]) >= float(RUN["sector"]) or nemClockGet() + float(or_(nemBeh(N).get("clock"), 1)) < float(NEM_CLOCK): return ""
	if st == "raid":
		var canTow = RUN["fleet"].size() >= 3   # NEM-5: the warning names the tow when the fleet is big enough, since the fight can cripple a ship before the strike lands
		return nemSay("Your next win fills his clock: he will raid", N) + " " + (numstr(jsround(float(RUN["credits"]) * 0.25)) + " credits" if float(RUN["credits"]) >= 30 else ("your most damaged ship (repair it above 25% hull, or keep 30 credits, to stop it)" if canTow else "and find nothing to take")) + "."
	if st == "tithe": return "Your next win fills the clock: every ship will lose 6% of its hull (never below 1)."
	return nemSay("Your next win fills the clock: your next fight will be his.", N)
func nemFull(N0 = null) -> String:
	var N = N0 if jt(N0) else nemActive()
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
# #122: the event and his capped list (40, oldest dropped) belong to the commander who acted (the active one unless given), tagged with his faction
func nemSignature(kind: String, N0 = null) -> void:
	var N = N0 if jt(N0) else nemActive()
	if not jt(N): return
	if not (N.get("signatures") is Array): N["signatures"] = []
	N["signatures"].append(kind)
	if N["signatures"].size() > 40: N["signatures"].pop_front()
	tel("nem_signature", {"fac": N["fac"], "kind": kind, "sector": RUN["sector"]})
# Issue 344 (the campaign map only reads): nemBeh, nemNodeIs and nemPanelData take the commander a screen already read with
# nemRead (N0). Given one, they resolve nothing: no migration, no new commander, no cache write. With none (every rules
# caller, and the browser game's twin) they resolve the active commander first, exactly as before.
func nemBeh(N0 = null) -> Dictionary:
	var N = N0 if jt(N0) else nemActive()
	if jt(N) and NEM_FAC.has(N["fac"]) and jt(NEM_FAC[N["fac"]].get("beh")): return NEM_FAC[N["fac"]]["beh"]
	return {}
# the clock: returns a line to show when it fills (the next fight becomes his); his faction sets the pace (Deathless patient, Voidsworn zealous)
# #121: the clock is the run's (RUN.nemClock), one for the whole run; the active commander's faction sets its pace
# #282 (Muse, #274 design call 4): it is the full clock that crosses a sector advance, not a pending strike. nemClockAdd arms
# the strike only when the active commander is unmet this sector, so a clock filled after this sector's meeting arms nothing
# until the next sector's first add, when the incoming commander's met is 0.
func nemClockGet() -> float: return float(RUN["nemClock"]) if (RUN != null and (RUN.get("nemClock") is float or RUN.get("nemClock") is int)) else 0.0
func nemClockAdd(n) -> String:
	var N = ensureNemesis()
	if not jt(N) or jt(N.get("dead")): return ""
	var step = float(n) * float(or_(nemBeh().get("clock"), 1)) if float(n) > 0 else float(n)
	RUN["nemClock"] = clampv(jsround((nemClockGet() + step) * 2) / 2.0, 0, NEM_CLOCK)
	if float(RUN["nemClock"]) >= float(NEM_CLOCK) and float(N["met"]) < float(RUN["sector"]) and not jt(RUN.get("nemStrike")) and not nemBossOnly(N):
		RUN["nemStrike"] = true; var extra = nemStrike()
		return nemSay(nemFull() + " has found your trail. Your next fight will be against his fleet." + ((" " + extra) if extra != "" else ""), N)   # #122: through nemSay (a she or an it read "his")
	return ""
# #282: the map card's strike line is text like the rest of the card: through nemSay so a she or an it reads right
func nemStrikeLine(N) -> String:
	return nemSay("His fleet is coming: your next fight is his.", N)
# what a full clock does on the map, by faction (always written on his card beforehand)
func nemStrike() -> String:
	var N = nemActive(); var st = nemBeh().get("strike")
	if st == "raid" or st == "tithe": nemSignature(str(st), N)
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
			return "With your credits empty, his raiders clamp onto the crippled " + str(cand["name"]) + " and tow it away. Kill him and you take it back."
		return "His raiders find nothing worth taking."
	if st == "tithe":
		for x in RUN["fleet"]: x["hp"] = max(1.0, float(x["hp"]) - jsround(float(derive(x)["maxHp"]) * 0.06))
		return "The hunt wears on your fleet: every ship loses 6% of its hull."
	# NEM-4: the four battle strikes are ruled effects that land in the meeting (rules.gd applyNemesis / campaign.gd's round 3 reinforcement); the clock line names the one coming
	if st == "duel": return "He will meet you with a small elite fleet, keep his range and cut out your damaged ships."
	if st == "swarm": return "He will come at you in numbers, and his swarm grows tougher with every ship you lose."
	if st == "reinforce": return "His line will bring reinforcements in round 3; end the fight before the line doubles."
	if st == "challenge": return "His flagship will challenge yours to single combat; screen your flagship."
	return ""
# is this stop his? (strike pending: the next fight; unmet this sector: every stop of the column before the rest stop, whatever
# its type, so no route reaches the flagship without the meeting nemMeetingLine promises; issue 1175)
func nemNodeIs(n, N0 = null) -> bool:
	var N = N0 if jt(N0) else nemActive()
	if not jt(N) or jt(N.get("dead")) or float(N["met"]) >= float(RUN["sector"]) or n == null: return false
	if nemBossOnly(N): return n["type"] == "boss"   # issue 1480 (R384): the revived Eclipse rival's last fight is the Sector 3 boss battle, and no stop before it
	if n["type"] == "boss": return false
	var c4 = float(RUN["map"]["cols"].size() - 3)
	if n["type"] != "battle" and n["type"] != "elite": return float(n["col"]) == c4
	return jt(RUN.get("nemStrike")) or float(n["col"]) >= c4
# issue 1480 (R384): the revived rival waits for the boss battle
func nemBossOnly(N) -> bool: return jt(N) and jt(N.get("revived")) and float(RUN["sector"]) >= 3
# Job 7 step 7 (R85 Q5): the map tag and the one sentence that name the meeting as a certainty, not a chance.
func nemNodeTag(n, N0 = null) -> String: return "Nemesis meeting" if nemNodeIs(n, N0) else ""
func nemMeetingLine(N0 = null) -> String:
	var N = N0 if jt(N0) else nemActive()
	if not jt(N): return ""
	if jt(N.get("dead")): return nemFull(N) + " is dead. No hunter will meet you this sector."
	if nemBossOnly(N) and float(N["met"]) < float(RUN["sector"]): return nemSay(nemFull(N) + " came back. He waits for you in the Sector 3 boss battle.", N)
	if float(N["met"]) >= float(RUN["sector"]): return nemSay("You have met " + nemFull(N) + " this sector. That meeting is done; the next sector brings the next hunter.", N)
	return nemSay("You will meet " + nemFull(N) + " this sector. One meeting every sector is certain, and it comes at the latest before the rest stop. The clock is only an accelerant: every fight you win moves it at his pace, and a full clock brings the meeting sooner, never later.", N)
func nemBattleCfg() -> Dictionary:
	var N = ensureNemesis(); var full = nemFull(); var tp = str(N["title"]) + " "; var i = full.find(tp)
	var nm = (full.substr(0, i) + full.substr(i + tp.length())) if i >= 0 else full
	return {"gloat": N.get("gloat") if jt(N.get("gloat")) else null, "honed": z0(N.get("honed")), "beaten": z0(N.get("beaten")), "name": nm, "title": N["title"], "fac": N["fac"], "persona": N["persona"], "traits": N["traits"].duplicate(), "weak": N["weak"].duplicate(), "revealed": N["revealed"].duplicate(),
		"adapt": N["adapt"].duplicate(), "scars": N["scars"], "fed": N.get("fed"), "riches": N.get("riches"), "last_beat": N.get("last_beat"), "g": N.get("g"), "met": float(N["beaten"]) + float(N["scars"]) > 0, "line": nemOpenLine(N)}
# adaptation: once per sector (Chorus also after every meeting), read from how you fought (RUN.nem.seen); his faction names it, and when nothing
# stood out he takes his faction's own special adaptation
# #121: nemAdapt(force, N) adapts the commander given (the sector advance passes the one who fought the sector just ended), else the active one
func nemAdapt(force: bool = false, N0 = null) -> Variant:
	var N = N0 if jt(N0) else nemActive()
	if not jt(N) or jt(N.get("dead")): return null
	var fast = jt(NEM_FAC.get(N.get("fac"), {}).get("beh", {}).get("adaptFast")); var cap = max(0.0, float(RUN["sector"]) - 1.0) + ((float(N["beaten"]) + float(N["scars"])) if fast else 0.0)
	if not force and float(z0(N.get("adaptSector"))) == float(RUN["sector"]): return null   # NEM-3: one adaptation a sector, not a cumulative budget spent twice in one visit
	if N["adapt"].size() >= min(cap, 6.0) and not force: return null
	var s = N["seen"] if N.get("seen") is Dictionary else {}
	var sp = NEM_ADAPT_FAC[N["fac"]].get("special") if NEM_ADAPT_FAC.has(N["fac"]) else null
	var score = {"shields": float(z0(s.get("lance"))) * 2 + float(z0(s.get("ion"))) * 2, "pd": float(z0(s.get("torp"))) * 2 + float(z0(s.get("sq"))), "armor": float(z0(s.get("ram"))) * 4 + float(z0(s.get("board"))) * 4,
		"evasion": float(z0(s.get("battery"))) + float(z0(s.get("broad"))), "aim": float(z0(s.get("evaded"))) * 3}
	var blocked = []   # R1 (NEM-2, R63 clash check, Codex PR #1): never a direct counter to a known weakness
	if or_(N.get("revealed"), []).has("ion"): blocked.append("shields")
	if or_(N.get("revealed"), []).has("torp"): blocked.append("pd")
	var kit := fleetKit()
	var eligible := score.keys().filter(func(k): return not blocked.has(k) and not N["adapt"].has(k) and _nem_kit_fit(k, N["fac"], kit))
	var ks = ssort(eligible.filter(func(k): return score[k] > 0), func(a, b): return score[b] - score[a])
	var pickA = ks[0] if ks.size() > 0 else null
	if pickA == null and jt(sp) and not N["adapt"].has(sp["id"]): pickA = sp["id"]
	if pickA == null:
		var rest = eligible
		if rest.size() > 0: pickA = rest[0]
	if pickA == null: return null
	N["adapt"].append(pickA); N["adaptSector"] = RUN["sector"]; N["seen"] = {}; return pickA
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
# #282: the sector modal's adaptation reason, through nemSay with the commander who adapted (the outgoing one)
func nemAdaptWhyLine(a, N) -> String:
	return nemSay(nemAdaptWhy(a, N.get("fac") if jt(N) else null), N)
# #121 (R101): his own lines from NEM_VOICE, through nemSay. A pool's line is chosen without the rules PRNG: the pick turns with how many
# times you have met and hurt him and with the sector. Every faction has a table (#395 added the Sunward Crusade); a faction without one would say nothing new and keep NEM_LINES.
func nemPersonaVoice(N) -> Variant:
	if not jt(N) or not NEM_VOICE.has(N.get("fac")): return null
	var V = NEM_VOICE[N["fac"]]
	return V[N["persona"]] if (N.get("persona") != null and V.get(N["persona"]) is Dictionary) else null
func nemPickLine(arr, N) -> String:
	if not (arr is Array) or arr.is_empty(): return ""
	var i = int(float(z0(N.get("beaten"))) + float(z0(N.get("scars"))) + float(or_(RUN.get("sector") if RUN != null else null, 1))) % arr.size()
	return str(arr[i])
func nemSpeak(N, slot: String) -> String:
	var P = nemPersonaVoice(N)
	var t = nemSay(nemPickLine(P.get(slot), N), N) if P != null else ""
	return (nemFull(N) + ": \"" + t + "\"") if t != "" else ""
func _beat_fill(tpl, bw) -> String:   # JS replace: the first occurrence only
	var ts = str(tpl); var bi = ts.find("{beat}")
	return (ts.substr(0, bi) + str(bw) + ts.substr(bi + 6)) if bi >= 0 else ts
# the line that opens his battle (rules.gd logs cfg.nemesis.line; null keeps the old NEM_LINES path): a gloat, else again or remember, else meet
func nemOpenLine(N) -> Variant:
	var P = nemPersonaVoice(N)
	if P == null: return null
	if jt(N.get("gloat")) and jt(NEM_LINES["gloat"].get(N["gloat"])): return NEM_LINES["gloat"][N["gloat"]]
	var bw = (NEM_BEAT_WORD[N["last_beat"]] if jt(NEM_BEAT_WORD.get(N["last_beat"])) else N["last_beat"]) if jt(N.get("last_beat")) else null
	if float(z0(N.get("beaten"))) + float(z0(N.get("scars"))) > 0 and jt(bw):
		var cnt = NEM_BEAT_COUNTER.get(N["last_beat"])
		var tpl = P["again"] if or_(N.get("adapt"), []).has(cnt) else (P["remember"] if jt(P.get("remember")) else P["again"])
		return nemSay(_beat_fill(tpl, bw), N)
	var m = nemSay(nemPickLine(P.get("meet"), N), N)
	return m if m != "" else null
# what he says when he adapts (the six NEM_ADAPT_FAC slots; his faction's own adaptation is 'special')
func nemAdaptLine(N, a) -> String:
	if not jt(N) or not NEM_VOICE.has(N.get("fac")): return ""
	var V = NEM_VOICE[N["fac"]]; var sp = NEM_ADAPT_FAC[N["fac"]].get("special") if NEM_ADAPT_FAC.has(N["fac"]) else null
	var key = "special" if (jt(sp) and sp["id"] == a) else a
	var t = V["adapt"].get(key) if V.get("adapt") is Dictionary else null
	return (nemFull(N) + ": \"" + nemSay(t, N) + "\"") if jt(t) else ""
# R85 Q3, G2: a lost meeting records the lesson it taught on the commander met (N.lessons: {w, t, sector}), with the NEM_VOICE lesson
# text for the weakness taught; when the file is already complete it teaches his faction's strike instead, once. No table: the weakness's own words.
func nemLessonText(N, w) -> String:
	var V = NEM_VOICE.get(N.get("fac")) if jt(N) else null
	if V is Dictionary and V.get("lessons") is Dictionary and jt(V["lessons"].get(w)): return nemSay(V["lessons"][w], N)
	var entry = BattleAPI.nem_entry(NEM_WEAK, w, N.get("fac") if N != null else null)
	return (str(entry["n"]) + ": " + str(entry["d"])) if entry != null else ""
func nemLessonAdd(N, w, taught: bool = false) -> String:
	if not (N.get("lessons") is Array): N["lessons"] = []
	for l in N["lessons"]:
		if l is Dictionary and l.get("w") == w: return ""
	var t = nemLessonText(N, w)
	if t == "": return ""
	N["lessons"].append({"w": w, "t": t, "sector": RUN["sector"], "taught": taught}); return t
# each survival adds a scar (a portrait overlay keyed by how he was hurt) and a new epithet
func nemScar(cause) -> void:
	var N = nemActive(); var F = NEM_FAC[N["fac"]]
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
	var N = nemActive()
	if not jt(N): return []
	var out = []; var beh = nemBeh(); var P = nemPr(N)
	if result == "retreat":   # issue 1480 (R381): a retreat is not the meeting
		N["gloat"] = "retreat"; out.append(nemSay("You pull back. " + nemFull() + " holds the field, and the meeting still waits.", N)); return out
	N["met"] = RUN["sector"]; RUN["nemStrike"] = false; RUN["nemClock"] = 0; var back = false   # #121: any meeting resets the run's clock and strike
	if result == "win":
		N["beaten"] = float(N["beaten"]) + 1; N["gloat"] = null
		if jt(o.get("beat")):
			N["last_beat"] = o["beat"]; nemBeatTeach(o["beat"])
		var w = nemReveal()
		if w != null: out.append(nemSay("His captured logs reveal a weakness: " + BattleAPI.nem_entry_name(NEM_WEAK, w, N["fac"]) + ".", N))
		if jt(o.get("fled")):
			if beh.get("strike") == "raid": N["riches"] = float(z0(N.get("riches"))) + 1
			if beh.get("strike") == "duel": N["honed"] = float(z0(N.get("honed"))) + 1
			nemScar("fled"); nemSignature("flee", N); nemEscape(N, "fled")
			out.append(nemSay(nemFull() + " breaks off and runs before you can finish him." + (" He will come back richer." if beh.get("strike") == "raid" else (" He will be back with the same few ships, honed sharper." if beh.get("strike") == "duel" else " He will be back.")), N))
			_speak(out, N, "flee")
		elif flagDead and float(RUN["sector"]) >= 3 and jt(beh.get("revive")) and not jt(N.get("revived")):
			N["revived"] = true; back = true; nemScar(o.get("cause") if jt(o.get("cause")) else "big"); nemSignature("revive", N); N["met"] = float(RUN["sector"]) - 1
			out.append(nemSay(nemFull() + "'s flagship is destroyed, and then the wreck begins to move. He is reassembling for one last fight.", N))
			_speak(out, N, "fall_final")   # A1: the kill that triggers the revive
		elif flagDead and float(RUN["sector"]) >= 3:
			N["dead"] = true; out.append(nemSay(nemFull() + " is dead. The feud is over.", N))
			if not jt(beh.get("revive")): _speak(out, N, "fall")   # A1: the Eclipse commander's second, permanent death says nothing
		elif flagDead:   # R49: before the last sector every rival, the Deathless one too, withdraws like this; issue 1505: a rival who never flees (noFlee, revive) withdraws, he does not escape
			nemScar(o.get("cause") if jt(o.get("cause")) else "big"); nemEscape(N, "flagship"); out.append(nemSay(nemFull() + "'s flagship breaks apart, " + ("and he withdraws" if (jt(beh.get("noFlee")) or jt(beh.get("revive"))) else "but he escapes") + ", scarred and furious. He will be back.", N))
			_speak(out, N, "fall")
		else: out.append(nemSay(nemFull() + " withdraws to fight another day.", N))
		# R49 fairness: what a Corsair raid took (credits and a towed ship) comes back when he dies
		if jt(N.get("dead")) and jt(N.get("loot")):
			RUN["credits"] = float(RUN["credits"]) + float(N["loot"]); out.append(nemSay("You take back " + numstr(N["loot"]) + " credits from his hold.", N)); N["loot"] = 0
		if jt(N.get("dead")) and jt(N.get("held")):
			var held: Dictionary = N["held"]
			held["cap"] = CaptainData.migrate(held.get("cap"), "captain:" + str(held["uid"]), RUN["fac"], PERKS)
			CaptainData.assign_portrait(held["cap"], CaptainData.used_portraits(RUN))
			RUN["fleet"].append(held); out.append("You take back " + str(N["held"]["name"]) + "."); N["held"] = null
		if float(RUN["sector"]) >= 3 and not back:   # R41: the last meeting won (dead, fled or withdrawn) ends the arc
			var u = arcComplete(RUN["fac"])
			if u != "": out.append(u)
	else:
		RUN["nemClock"] = 1; N["gloat"] = "flagship" if jt(o.get("myFlagDead")) else ("retreat" if result == "retreat" else "loss")
		out.append(nemSay(nemFull() + " drove you off. He will remember this.", N)); _speak(out, N, "win")
		# R1 (FR-2, Ryan's Q5 ruling, Codex PR #1): a lost meeting still teaches: what the fight uncovered, else one new weakness, never more
		var found = o["found"].filter(func(k): return N["weak"].has(k)) if o.get("found") is Array else []
		nemFoundMerge(found)
		var learned = []
		for k in found:
			if not learned.has(k): learned.append(k)
		var w = learned[0] if not learned.is_empty() else nemReveal()
		if w != null:
			var ws = learned if not learned.is_empty() else [w]
			var names = ws.map(func(k): return BattleAPI.nem_entry_name(NEM_WEAK, k, N["fac"]))
			out.append("After-action telemetry breaks down the engagement. " + ("Weaknesses" if ws.size() > 1 else "Weakness") + " found: " + ", ".join(PackedStringArray(names)) + ".")
			for k in ws:
				var lt = nemLessonAdd(N, k, true)
				if lt != "": out.append("Lesson: " + lt)
		else:
			out.append("Combat telemetry confirms what you already knew about " + str(N["name"]) + ".")
			var ls = nemLessonAdd(N, "strike", true)
			if ls != "": out.append("Lesson: " + ls)
	if result == "win":
		var fw = nemFoundMerge(o.get("found"))
		if not fw.is_empty(): out.append("Weakness confirmed: " + ", ".join(PackedStringArray(fw.map(func(k): return BattleAPI.nem_entry_name(NEM_WEAK, k, N["fac"])))) + ".")
	if jt(beh.get("adaptFast")):
		N["adaptSector"] = 0
		var a = nemAdapt(false, N)
		if a != null:
			nemSignature("fast_adapt", N); out.append(P["He"] + " learns from it at once: " + nemAdaptName(a, N["fac"]) + " (" + nemSay(nemAdaptWhy(a, N["fac"]), N) + ").")
			var al = nemAdaptLine(N, a)
			if al != "": out.append(al)
	return out
func _speak(out: Array, N, slot: String) -> void:
	var l = nemSpeak(N, slot)
	if l != "": out.append(l)
# R42: when you beat him with something, his next adaptation counters it (so "it will not work twice" is true when he says it)
const NEM_BEAT_SEEN = {"lance": "lance", "torp": "torp", "sq": "sq", "ram": "ram", "board": "board", "battery": "battery", "evasive": "evaded"}
func nemBeatTeach(beat) -> void:
	var N = nemActive(); var k = NEM_BEAT_SEEN.get(beat) if beat != null else null
	if not jt(N) or k == null: return
	if not (N.get("seen") is Dictionary): N["seen"] = {}
	N["seen"][k] = float(z0(N["seen"].get(k))) + 8
# weaknesses you found in battle by triggering them (B.nemFound) are known from then on
func nemFoundMerge(list) -> Array:
	var N = nemActive()
	if not jt(N) or not (list is Array) or list.is_empty(): return []
	var out = []
	for k in list:
		if N["weak"].has(k) and not N["revealed"].has(k):
			N["revealed"].append(k); out.append(k)
	return out
# the Chorus Nemesis grows from every ship you lose while he is the one hunting you (his own counter, capped at 8)
func nemFeedLosses(n) -> String:
	var N = nemActive()
	if not jt(N) or jt(N.get("dead")) or not jt(n) or not jt(nemBeh().get("feeds")): return ""
	var f0 = float(z0(N.get("fed"))); N["fed"] = min(8.0, f0 + float(n))
	if float(N["fed"]) == f0: return ""
	nemSignature("feed", N); nemCompoundTel(N)
	return nemFull() + " feeds on your losses: " + nemPr(N)["his"] + " fleet is now " + numstr(jsround(min(0.32, 0.04 * float(N["fed"])) * 100)) + "% tougher (fed " + numstr(N["fed"]) + " of 8)."
# #122 telemetry (synthesis section 4, G3): two counters, never merged. The escape counter is the run's (RUN.nemEscapes): a commander
# who escapes a meeting before the last sector (he flees, or his flagship dies and he withdraws), so at most two a run (SP1 and SP2);
# a sector 3 flight, revive or death never counts. The compounding counter is the commander's own where his behaviour compounds: the
# Chorus fed counter (N.fed, capped at 8). Other factions carry none (riches and honed stay as they are and are not re-counted).
func nemEscape(N, how: String) -> void:
	if RUN == null or float(or_(RUN.get("sector"), 1)) >= 3: return
	RUN["nemEscapes"] = float(z0(RUN.get("nemEscapes"))) + 1
	tel("nem_escape", {"fac": N["fac"], "how": how, "sector": RUN["sector"], "n": RUN["nemEscapes"]})
func nemCompound(N) -> Variant:
	if not (N is Dictionary) or not NEM_FAC.has(N.get("fac")): return null
	var beh = NEM_FAC[N["fac"]].get("beh")
	if beh is Dictionary and jt(beh.get("feeds")): return {"kind": "fed", "n": float(z0(N.get("fed"))), "cap": 8}
	return null
func nemCompoundTel(N) -> void:
	var c = nemCompound(N)
	if c == null: return
	tel("nem_compound", {"fac": N["fac"], "kind": c["kind"], "n": c["n"], "cap": c["cap"], "sector": RUN["sector"]})
# the run's Nemesis record for the run_end event: who hunted each story point, the escapes, and each compounding commander's counter
func nemTelSummary() -> Variant:
	if RUN == null: return null
	var reg = RUN.get("nems") if RUN.get("nems") is Dictionary else {}; var comp = {}
	for f in reg.keys():
		var c = nemCompound(reg[f])
		if c != null: comp[f] = c["n"]
	return {"assign": (RUN["nemAssign"].duplicate() if RUN.get("nemAssign") is Array else []), "escapes": float(z0(RUN.get("nemEscapes"))), "compound": comp}
# Job 7 step 11: per run XP earnings by line, one event per finished run, saved with the profile in the play log.
# A line is an admiral's lineage: the flown line earns its full payout and each benched line of the same faction earns
# its shadow share (the row the debrief already shows). The F1 play log report reads these events for median XP per run
# per line. No Nemesis counter is kept here: escapes and compounding are read from the #122 run_end record.
func runXPTel(run, earnings, victory) -> Dictionary:
	if run == null or earnings == null: return {}
	var lines = [{"id": run["admiral"], "xp": earnings["mxGain"]}]
	for row in earnings.get("shadow", []): lines.append({"id": row["id"], "xp": row["xp"]})
	var rec = {"fac": run["fac"], "admiral": run["admiral"], "victory": victory, "sector": run.get("sector", 1), "lines": lines}
	tel("run_xp", rec)
	return rec
# #122: what the Nemesis panel shows, as data; campaign_ui.gd _nem_panel and the browser's nemPanel only draw it.
# cur: the current sector's assigned hunter (RUN.nemAssign[RUN.sector - 1]); back: the earlier sectors he hunted you in (a return);
# earlier: every other commander of a story point already passed, in order, still readable after the rotation.
func nemStatus(N) -> String:
	if jt(N.get("dead")): return "dead"
	if not jt(N.get("met")): return "never met"
	if jt(N.get("scars")): return "escaped, scarred " + numstr(N["scars"]) + "x"
	if jt(N.get("beaten")): return "beaten, withdrew"
	return "drove you off"
func _nem_sps(a: Array, f, cur: int) -> Array:
	var o = []
	for i in range(a.size()):
		if a[i] == f and i < cur: o.append(i + 1)
	return o
func _nem_secs(l: Array) -> String:
	var o = []
	for i in l: o.append(roman(i))
	return " and ".join(PackedStringArray(o))
func nemPanelData(N0 = null) -> Variant:
	var N = N0 if jt(N0) else nemActive()
	if not jt(N) or not jt(N.get("persona")): return null
	var a = RUN["nemAssign"] if RUN.get("nemAssign") is Array else []; var cur = int(or_(RUN.get("sector"), 1)); var reg = RUN["nems"] if RUN.get("nems") is Dictionary else {}
	var back = _nem_sps(a, N["fac"], cur).filter(func(i): return i < cur)
	var earlier = []; var seen = {N["fac"]: 1}
	for i in range(min(cur - 1, a.size())):
		var f = a[i]
		if not jt(f) or not reg.has(f) or seen.has(f): continue
		var E = reg[f]
		if not (E is Dictionary) or not jt(E.get("persona")): continue
		seen[f] = 1; var F = FACTIONS.get(f)
		var sp = _nem_sps(a, f, cur)
		earlier.append({"fac": f, "name": nemFull(E), "faction": (F["n"] if F != null else ""), "sectors": sp, "line": "Sector " + _nem_secs(sp) + ": " + nemStatus(E) + ".",
			"lessons": (E["lessons"] if E.get("lessons") is Array else []).map(func(l): return l["t"])})
	return {"fac": N["fac"], "name": nemFull(N), "scars": float(z0(N.get("scars"))), "back": (nemSay("He is back: you met him in sector " + _nem_secs(back) + ".", N) if back.size() > 0 else ""),
		"lessons": (N["lessons"] if N.get("lessons") is Array else []).map(func(l): return l["t"]), "compound": nemCompound(N), "escapes": float(z0(RUN.get("nemEscapes"))), "earlier": earlier}
# Job 7 step 7 (R85 Q3): the run debrief's Nemesis lesson row, keyed per commander. It reads the lesson log the lost meeting
# wrote on the commander who fought it; a missing taught flag is an old save from before this step and reads as taught,
# because every lesson the game records comes from a meeting that went against the player.
func nemDebrief(run0 = null) -> Dictionary:
	var run = run0 if jt(run0) else RUN
	var reg = run.get("nems") if run is Dictionary and run.get("nems") is Dictionary else {}
	var rows = []; var lessons = []; var met = 0
	for fac in reg.keys():
		var N = reg[fac]
		if not (N is Dictionary) or not jt(N.get("persona")): continue
		if float(z0(N.get("met"))) > 0.0 or float(z0(N.get("beaten"))) > 0.0 or float(z0(N.get("scars"))) > 0.0 or jt(N.get("dead")): met += 1
		var ls = N["lessons"] if N.get("lessons") is Array else []
		if ls.is_empty(): continue
		var nm = nemFull(N); var ti = N.get("title"); var row = {"fac": fac, "name": nm, "title": ti, "lessons": []}
		for l in ls:
			var taught = not (l is Dictionary) or not l.has("taught") or jt(l.get("taught"))
			var txt = str(l.get("t")) if l is Dictionary and l.get("t") != null else ""
			var e = {"w": l.get("w") if l is Dictionary else null, "text": txt, "sector": l.get("sector") if l is Dictionary else null, "taught": taught}
			row["lessons"].append(e)
			lessons.append({"fac": fac, "name": nm, "title": ti, "w": e["w"], "text": txt, "sector": e["sector"], "taught": taught})
		rows.append(row)
	return {"met": met, "lessons": lessons, "rows": rows}
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
	var N = nemActive()
	if not jt(N) or not jt(usage): return
	if not (N.get("seen") is Dictionary): N["seen"] = {}
	var s = N["seen"]; var k = usage["kind"] if usage.get("kind") is Dictionary else {}
	for x in ["lance", "torp", "battery"]: s[x] = float(z0(s.get(x))) + float(z0(k.get(x)))
	s["ion"] = float(z0(s.get("ion"))) + float(z0(usage.get("ion"))); s["sq"] = float(z0(s.get("sq"))) + float(z0(k.get("sq")))
	s["ram"] = float(z0(s.get("ram"))) + float(z0(usage.get("ram"))); s["board"] = float(z0(s.get("board"))) + float(z0(usage.get("board")))
	var fire = usage.get("fire") if usage.get("fire") is Dictionary else null
	var br = (float(z0(fire.get("Port flank"))) + float(z0(fire.get("Starboard flank"))) + float(z0(fire.get("Port broadside"))) + float(z0(fire.get("Starboard broadside")))) if jt(fire) else 0.0
	s["broad"] = float(z0(s.get("broad"))) + br; s["evaded"] = float(z0(s.get("evaded"))) + float(z0(evadedShare))
# ---------- B4 faction campaign verbs ----------
func verbFor() -> Variant:
	if RUN == null: return null
	return FAC_VERBS[RUN["fac"]] if FAC_VERBS.has(RUN["fac"]) else null
func verbFree(V) -> bool: return jt(V) and jt(V.get("free")) and flagIs(V["free"], V.get("freeK"))   # R1 (EVT-1): only the choices freeK names
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
	saveRun()
	if page.get("kind") == "fleet" and page["data"].get("back") == "shipyard":
		fleetScreen("shipyard")
	else:
		mapScreen()
	toast(" ".join(PackedStringArray(lines)))
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
			out.append("Your boarding parties return with a " + modName(m) + " and 40 credits in spoils.")
		else:
			var s = randShip(); var d = derive(s); var dm = jsround(float(d["maxHp"]) * 0.25); s["hp"] = max(1.0, float(s["hp"]) - dm); RUN["credits"] = float(RUN["credits"]) + 20
			out.append("Something was awake. " + str(s["name"]) + " takes " + numstr(dm) + " hull damage covering the retreat. You pull 20 credits in spoils.")
		return out
	if not (r is Dictionary): r = {}
	if jt(r.get("cost")): RUN["credits"] = float(RUN["credits"]) - float(r["cost"])
	if jt(r.get("cred")):
		RUN["credits"] = float(RUN["credits"]) + float(r["cred"]); out.append("+" + numstr(r["cred"]) + " credits.")
	if jt(r.get("xp")):
		for s in RUN["fleet"]: addXp(s, r["xp"])
		if RUN["fac"] in ["chorus", "deathless"]:
			out.append("+" + numstr(r["xp"]) + " experience per ship.")
		else:
			out.append("Every captain gains " + numstr(r["xp"]) + " experience.")
	if jt(r.get("xpLow")):
		var s = ssort(RUN["fleet"].duplicate(), func(a, b): return float(a["cap"]["xp"]) - float(b["cap"]["xp"]))[0]
		addXp(s, r["xpLow"]); out.append(str(s["cap"]["full_name"]) + " of the " + str(s["name"]) + " gains " + numstr(r["xpLow"]) + " experience.")
	if jt(r.get("loseMod")):
		var withMod = RUN["fleet"].filter(func(s): return s["mods"].size() > 0)
		if withMod.size() > 0:
			var s = pick(withMod); var got = []
			changeShip(s, _pop_rand_mod.bind(got))
			out.append(ship_with_article(s["name"], true) + " gives up its " + modName(got[0]) + ".")
		elif RUN["inventory"].size() > 0:
			var m = RUN["inventory"].pop_at(0); out.append("You hand over the " + modName(m) + " from the hold.")
		else: out.append("You have no refits to give. The Glasswright keeper pulses warm amber and gifts the hardware anyway.")
	if jt(r.get("relic")):
		var rl = randomRelic()
		if rl != null:
			addRelic(rl); changeFleet(_noop); out.append("Salvage gained: " + relicName(rl) + ". " + str(RELICS[rl]["d"]))
		else:
			RUN["credits"] = float(RUN["credits"]) + 80; out.append("No salvage left to find. +80 credits instead.")
	if jt(r.get("dmgOne")):
		var s = randShip(); var d = derive(s); var dm = jsround(float(d["maxHp"]) * float(r["dmgOne"])); s["hp"] = max(1.0, float(s["hp"]) - dm)
		out.append(ship_with_article(s["name"], true) + " takes " + numstr(dm) + " hull damage.")
	if jt(r.get("dmgAll")):
		for s in RUN["fleet"]: s["hp"] = max(1.0, float(s["hp"]) - jsround(float(derive(s)["maxHp"]) * float(r["dmgAll"])))
		out.append("Every ship takes " + pct(r["dmgAll"]) + " hull damage.")
	if jt(r.get("ship")):
		var tp = equivHull(r["ship"], RUN["fac"])
		if fleetCP() + float(HULLS[tp]["cp"]) <= float(RUN["cpCap"]):
			var s = newShip(tp, r.get("vet")); RUN["fleet"].append(s)
			out.append(ship_with_article(s["name"], true) + " joins the fleet under " + rankName(s["cap"]) + " " + str(s["cap"]["full_name"]) + ".")
		else:
			RUN["credits"] = float(RUN["credits"]) + float(z0(r.get("cost"))); out.append("You don’t have the command points to add this ship. Your credits are returned.")
	var upgraded_uid = null   # R1 (TXT-2, Codex PR #1): the shipwright's repair goes to the next most damaged ship, not back to the one he upgraded
	if jt(r.get("upgradeOne")):
		var s = ssort(RUN["fleet"].duplicate(), func(a, b): return float(a["hp"]) / float(derive(a)["maxHp"]) - float(b["hp"]) / float(derive(b)["maxHp"]))[0]
		upgraded_uid = s["uid"]
		changeShip(s, _mk_up3)
		s["hp"] = derive(s)["maxHp"]; out.append(ship_with_article(s["name"], true) + " leaves the forge fully repaired at Mk " + roman(s["mk"]) + ".")
	if jt(r.get("healAll")):
		for s in RUN["fleet"]:
			var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * float(r["healAll"])))
		out.append("Every ship is fully repaired." if float(r["healAll"]) >= 1 else "Every ship repairs " + pct(r["healAll"]) + " of its hull.")
	if jt(r.get("gamble")):
		if rnd() < 0.5:
			for s in RUN["fleet"]:
				var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * 0.3))
			out.append("Luck holds. Every ship repairs 30% of its hull.")
		else: out.append("Nothing answers except static across the empty berth.")
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
			f["cap"]["xp"] = max(float(z0(RANK_XP[int(f["cap"]["rank"])])), float(f["cap"]["xp"]) - float(r["payXp"])); out.append(str(f["cap"]["full_name"]) + " loses " + numstr(r["payXp"]) + " experience.")
	if jt(r.get("payRelic")):
		if RUN["relics"].size() > 0:
			var at: int = int(r["payRelicAt"]) if r.get("payRelicAt") != null and int(r["payRelicAt"]) >= 0 and int(r["payRelicAt"]) < RUN["relics"].size() else RUN["relics"].size() - 1
			var rl = RUN["relics"].pop_at(at); changeFleet(_noop); out.append("You give up " + relicName(rl) + ".")
	if jt(r.get("repairOne")):
		var cands = RUN["fleet"]
		if jt(upgraded_uid) and cands.size() > 1: cands = cands.filter(func(sh): return sh.get("uid") != upgraded_uid)
		var srt = ssort(cands.duplicate(), func(a, b): return float(a["hp"]) / float(derive(a)["maxHp"]) - float(b["hp"]) / float(derive(b)["maxHp"]))
		var s = srt[0] if srt.size() > 0 else null
		if s != null:
			s["hp"] = derive(s)["maxHp"]; out.append(ship_with_article(s["name"], true) + " is fully repaired.")
	if jt(r.get("dmgBig")):
		var srt = ssort(RUN["fleet"].duplicate(), func(a, b): return float(or_(HULLS[b["tpl"]].get("cp"), 1)) - float(or_(HULLS[a["tpl"]].get("cp"), 1)))
		if srt.size() > 0:
			var s = srt[0]; var dm = jsround(float(derive(s)["maxHp"]) * float(r["dmgBig"])); s["hp"] = max(1.0, float(s["hp"]) - dm)
			out.append(ship_with_article(s["name"], true) + " takes " + numstr(dm) + " hull damage.")
	if jt(r.get("xpTop")):
		var srt = ssort(RUN["fleet"].duplicate(), func(a, b): return float(b["cap"]["xp"]) - float(a["cap"]["xp"]))
		if srt.size() > 0:
			var s = srt[0]; addXp(s, r["xpTop"]); out.append(str(s["cap"]["full_name"]) + " of the " + str(s["name"]) + " gains " + numstr(r["xpTop"]) + " experience.")
	if jt(r.get("modId")) and MODULES.has(r["modId"]):
		RUN["inventory"].append(r["modId"]); out.append("Found: " + modName(r["modId"]) + ". It’s in the hold.")
	if jt(r.get("shipRaw")) and HULLS.has(r["shipRaw"]):
		if fleetCP() + float(or_(HULLS[r["shipRaw"]].get("cp"), 1)) <= float(RUN["cpCap"]):
			var s = newShip(r["shipRaw"], r.get("vet")); RUN["fleet"].append(s)
			out.append(ship_with_article(s["name"], true) + " joins the fleet under " + rankName(s["cap"]) + " " + str(s["cap"]["full_name"]) + ".")
		else:
			RUN["credits"] = float(RUN["credits"]) + 40; out.append("No command points to add this ship. You sell the berth for 40 credits.")
	if jt(r.get("wingPerk")):
		var cs = ssort(RUN["fleet"].filter(func(s): return jt(HULLS[s["tpl"]].get("hangar"))), func(a, b): return float(or_(HULLS[b["tpl"]].get("cp"), 1)) - float(or_(HULLS[a["tpl"]].get("cp"), 1)))
		if cs.size() > 0:
			var c = cs[0]; var got = wingPerkGrant(c)
			out.append((ship_with_article(c["name"], true) + "’s wings gain a veteran perk: " + str(WING_PERKS[got]["n"]) + ".") if got != null else (ship_with_article(c["name"], true) + "’s wings already hold every perk they can."))
	if jt(r.get("nemIntel")):
		var w = nemReveal()
		var entry = BattleAPI.nem_entry(NEM_WEAK, w, nemRead()["fac"]) if w != null else null
		out.append(("Nemesis weakness revealed: " + str(entry["n"]) + ". " + str(entry["d"])) if entry is Dictionary else (("Nemesis weakness revealed: " + str(w) + ".") if w != null else "You learn nothing new about the enemy commander."))
	if jt(r.get("nemClock")):
		var m2 = nemClockAdd(r["nemClock"])
		if m2 != "": out.append(m2)
	if jt(r.get("power")) or jt(r.get("syncDown")) or jt(r.get("dmgPctUp")) or jt(r.get("dmgPctDown")):
		RUN["storyNext"] = _story_modifiers(r, or_(RUN.get("storyNext"), {}))
		if jt(r.get("power")):
			out.append("Flagship weapon damage +25% for the next battle only.")
		if jt(r.get("syncDown")):
			out.append("Next battle: Synchronized fire is off in round 1 and returns in round 2.")
		if jt(r.get("dmgPctUp")) or jt(r.get("dmgPctDown")):
			out.append("Fleet damage " + ("+10%" if jt(r.get("dmgPctUp")) else "-10%") + " for the next battle only.")
	if jt(r.get("core")):
		var p = TB.BEAT3_REWARDS.core.get(RUN["fac"])
		if p != null and RUN.get("eatenCore") != null and RUN["eatenCore"] == p:   # issue 1384: an eaten core offers nothing, so another patron speaks (campaign_run.js Beat 3)
			var alt = null
			for q in or_(RUN.get("patrons"), []):
				if q != p:
					alt = q; break
			if alt != null: p = alt
		if p != null:
			RUN["reward"] = {"kind": "story", "rw": {"k": "boon", "p": p}, "stage": "pick", "relics": [], "wrecks": [], "prizes": [], "boonOffer": null, "modOffer": null}
			out.append("1 free protocol offer from " + str(PATRONS[p]["short"]) + ". Choose 1 protocol or decline for " + numstr(boonDeclineCred()) + " credits.")
	if out.size() == 0 and not jt(r.get("fight")): out.append("You move on.")
	return out

func _story_modifiers(outcome: Dictionary, mods: Dictionary) -> Dictionary:
	for k in ["power", "syncDown"]:
		if jt(outcome.get(k)): mods[k] = true
	if jt(outcome.get("dmgPctUp")) or jt(outcome.get("dmgPctDown")):
		mods["dmgPct"] = float(z0(mods.get("dmgPct"))) + float(TB.BEAT3_REWARDS.dmgPct) * ((1 if jt(outcome.get("dmgPctUp")) else 0) - (1 if jt(outcome.get("dmgPctDown")) else 0))
	return mods

func _restore_legacy_story_modifier() -> void:
	# Issue 1338: a spent buff cannot be told from an erased one, so only a save from before storyGuard is repaired, and only once
	var legacy = RUN.get("storyLegacy") == true
	RUN.erase("storyLegacy")
	if not legacy or jt(RUN.get("storyNext")) or int(RUN["sector"]) != 3: return
	# The old mid-battle checkpoint erased the modifier but retained the story choice.
	var beat = TB.STORY_BEAT3[RUN["fac"]]
	var choice = str(RUN["flags"].get(beat["id"], ""))
	if not choice.is_valid_int() or int(choice) < 0 or int(choice) >= beat["o"].size(): return
	var mods = _story_modifiers(beat["o"][int(choice)]["r"], {})
	if not mods.is_empty(): RUN["storyNext"] = mods
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
	var lines = applyBeat3Outcome(r) if cur_event.get("beat") == 3 else applyOutcome(r)
	var k = str(o["k"]) if jt(o.get("k")) else str(i)
	var out = cur_event.get("outs", {}).get(k, "") if cur_event.get("outs") is Dictionary else ""
	if str(out) != "": lines.insert(0, str(out))
	if lines.has("You move on."): lines.erase("You move on.")
	if arc_chose_cb is Callable and (arc_chose_cb as Callable).is_valid(): arc_chose_cb.call(cur_event, k)
	saveRun(); mapScreen()
	var acts = []; A(acts, "storyCore" if RUN.get("reward") != null and RUN["reward"].get("kind") == "story" else "closeModal")
	show_modal("event_result", {"ev": cur_event, "lines": lines}, acts)
func _arc_played(beat: int) -> bool:
	if RUN == null or not (RUN.get("flags") is Dictionary): return false
	if beat == 3 and RUN["flags"].has(TB.STORY_BEAT3[RUN["fac"]]["id"]): return true
	var pre = "arc_" + str(RUN["fac"]) + "_" + str(beat)
	for k in RUN["flags"].keys():
		if str(k).begins_with(pre): return true
	return false
func ACT_eventChoice(a: String) -> void:
	if modal_d == null or cur_event == null or modal_d["kind"] not in ["event", "relic_pick"]: return
	if not modal_d["acts"].any(func(action): return action == ["eventChoice", a, 1]): return
	var parts := a.split(":")
	var i = int(parts[0])
	var j := int(parts[1]) if parts.size() > 1 else -1
	var o = cur_event["o"][i] if (i >= 0 and i < cur_event["o"].size()) else null
	if o == null or not eventOptOk(o): return
	var paying: bool = o.get("r") is Dictionary and jt(o["r"].get("payRelic"))
	if paying and RUN["relics"].size() > 1 and not (j >= 0 and j < RUN["relics"].size()):
		relic_pick_modal(i); return   # issue 1449: pick the salvage first
	eventFlags(cur_event, o, i)
	if jt(cur_event.get("arc")):
		_arc_choice(o, i); cur_event = null; return
	var event = cur_event
	cur_event = null
	var r = o["r"]
	if paying and j >= 0:
		r = r.duplicate(); r["payRelicAt"] = j
	if r is Dictionary and jt(r.get("fight")):
		var n = findNode(RUN["curNode"])
		if n != null: n["evFight"] = or_(o.get("k"), str(i))   # issue 1628
		if n != null and jt(n.get("nemCleared")): saveRun()
		close_modal(); battleScreen(_event_battle_cfg(n, r)); return
	var lines = applyOutcome(r)
	completeNode(); mapScreen()
	var acts = []; A(acts, "closeModal")
	show_modal("event_result", {"ev": event, "lines": lines}, acts)

func _event_battle_cfg(n: Dictionary, outcome: Dictionary) -> Dictionary:
	return {"kind": "elite", "fac": outcome["fight"], "col": float(n["col"]) + 1, "node": n["id"], "eventRelic": true}

# Approved beat 3 content shares the browser table and existing event screens.
func beat3Text(t: String) -> String:
	return t.replace("{rival}", nemFull() if nemFull() != "" else "the enemy commander")
func beat3Card() -> Dictionary:
	if RUN == null or float(RUN["sector"]) != 3: return {}
	var row: Dictionary = TB.STORY_BEAT3[RUN["fac"]]
	if RUN.get("flags", {}).has(row["id"]): return {}
	var ev = row.duplicate(true)
	ev["arc"] = true; ev["beat"] = 3
	var text = row["lines"].duplicate()
	text.append(row["spotlights"].get(RUN["admiral"], ""))
	ev["b"] = "\n\n".join(PackedStringArray(text.map(func(t): return beat3Text(t))))
	ev["outs"] = {}; ev["labels"] = {}
	for i in range(ev["o"].size()):
		var o = ev["o"][i]; o["k"] = str(i); o["l"] = o["t"]; o["s"] = ""
		ev["outs"][str(i)] = beat3Text(o["tx"]); ev["labels"][str(i)] = o["l"]
	return ev
func showBeat3() -> bool:
	var ev = beat3Card()
	if ev.is_empty(): return false
	cur_event = ev
	var acts = []
	for i in range(ev["o"].size()): A(acts, "eventChoice", i)
	show_modal("event", {"ev": ev}, acts)
	return true
# R78 Q15 (issue 42): the Chorus run's one core-eating choice, offered before the first node of sector 3.
func showCoreEatOffer() -> bool:
	if not coreEatDue(): return false
	var cores = coreEatEligible()
	var acts = []
	for p in cores: A(acts, "eatCore", p)
	A(acts, "refuseCoreEat")
	show_modal("eatCore", {"cores": cores}, acts)
	return true
func ACT_eatCore(p: String) -> void:
	if not applyEatCore(p): return
	tel("core_eat", {"p": p, "sector": RUN["sector"]})
	saveRun(); close_modal(); act("beat3")
func ACT_refuseCoreEat() -> void:
	if not refuseCoreEat(): return
	tel("core_eat_refuse", {"sector": RUN["sector"]})
	saveRun(); close_modal(); act("beat3")
func _beat3_line(run: Dictionary, key: String) -> String:
	if int(run["sector"]) != 3 or not (run.get("flags") is Dictionary): return ""
	var row: Dictionary = TB.STORY_BEAT3[run["fac"]]
	return str(row[key]) if run["flags"].get(row["id"]) != null else ""
func beat3Payoff(run: Dictionary) -> String:
	return _beat3_line(run, "learning")
func beat3Debrief() -> String:
	return _beat3_line(RUN, "debrief") if RUN != null and not jt(RUN.get("beat3DebriefSeen")) else ""
func applyBeat3Outcome(r: Dictionary) -> Array:
	var adapted = r.duplicate()
	for pair in [["credits", "cred"], ["repair", "healAll"], ["weak", "nemIntel"], ["clock", "nemClock"]]:
		if r.has(pair[0]): adapted[pair[1]] = r[pair[0]]
	var out = applyOutcome(adapted).filter(func(l): return l != "You move on.")
	if jt(r.get("dmgFlag")):
		var f = flagshipOf()
		if f != null:
			var dmg = jsround(float(derive(f)["maxHp"]) * float(r["dmgFlag"]))
			f["hp"] = max(1.0, float(f["hp"]) - dmg)
			out.append(ship_with_article(f["name"], true) + " takes " + numstr(dmg) + " hull damage.")
	return out

# ---------------- rewards ----------------
# issue 1178 faction economies (twin of campaign_run.js factionWinEcon): Chorus biomass, Glasswright cullet, Eclipse core recovery
func factionWinEcon(credits: float, summary: Dictionary) -> Dictionary:
	var lost = or_(summary.get("lost"), []).filter(func(l): return l is Dictionary and HULLS.has(l.get("tpl")))
	var out = {}
	if RUN["fac"] == "chorus":
		var killBio = min(float(TB["BIO_KILL"]["cap"]), float(TB["BIO_KILL"]["per"]) * float(z0(summary.get("kills"))))
		if RUN["relics"].has("ledger2"): killBio = jsround(killBio * (1.0 + float(z0(RELICS["ledger2"]["run"].get("credPct")))))   # issue 1653: the Ledger's 10% also cuts kill biomass
		out["bio"] = credits + killBio; RUN["bio"] = float(z0(RUN.get("bio"))) + out["bio"]
	else: RUN["credits"] = float(RUN["credits"]) + credits
	if RUN["fac"] == "ithar" and lost.size() > 0:
		var CU = TB["CULLET"]; var sum = 0.0
		for l in lost: sum += float(or_(CU.get(HULLS[l["tpl"]].get("cls")), 20))
		out["cullet"] = min(float(CU["cap"]), sum); RUN["credits"] = float(RUN["credits"]) + out["cullet"]
	if RUN["fac"] == "deathless" and lost.size() > 0:
		var best = null
		for l in lost:
			if jt(HULLS[l["tpl"]].get("boss")): continue
			if best == null or shipValue(l["tpl"]) > shipValue(best["tpl"]): best = l
		if best != null:
			RUN["cores"] = or_(RUN.get("cores"), []); RUN["cores"].append(best["tpl"]); out["core"] = best["tpl"]
	return out
func rewardFlow(summary: Dictionary) -> void:
	var cfg = summary["cfg"]; var s = float(RUN["sector"]); var rf = runFx()
	RUN["stats"]["battles"] = float(RUN["stats"]["battles"]) + 1
	settleRegrown()   # issue 1290: a regrown ship that has fought decommissions like any other (capped since issue 1384)
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
	var econ = factionWinEcon(credits, summary)
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
		var v = 35.0 + 10.0 * s; RUN["credits"] = float(RUN["credits"]) + v; extra = "Spoils: +" + numstr(v) + " credits."
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
		"stage": "prize" if prizes.size() > 0 else ("salvage" if W["wrecks"].size() > 0 else "victory"), "boonOffer": null, "modOffer": null}
	var debrief := beat3Debrief()
	if debrief != "": RUN["beat3DebriefSeen"] = true
	RUN["reward"]["victory"] = {"summary": {"kills": summary["kills"], "rounds": summary["rounds"], "lost": summary["lost"], "xp": summary["xp"],
		"boonStats": summary.get("boonStats", {}), "treeStats": summary.get("treeStats", {})}, "credits": credits, "econ": econ, "extra": extra,
		"flagName": flagMoved["name"] if flagMoved != null else "", "beat3Debrief": debrief}
	for key in ["ship_rollups", "lost_ship_records"]:
		if summary.has(key): RUN["reward"]["victory"]["summary"][key] = summary[key]
	var confirmed: Array = summary.get("nem", []).filter(func(line): return line.begins_with("Weakness confirmed: "))
	if summary.has("nemFound"): confirmed.append(summary["nemFound"])
	if not confirmed.is_empty(): RUN["reward"]["victory"]["weaknessConfirmed"] = confirmed
	# Bank the win before opening rewards, keeping a Nemesis-held service open until the fleet uses it.
	if node != null and jt(cfg.get("nemesis")) and _is(node, ["shipyard", "drydock", "field", "event"]):
		node["nemCleared"] = true
		saveRun()
	else: completeNode()
	if prizes.size() > 0: ACT_prizeStep()
	else: victoryCard()
const WRECK_SCRAP_MULTIPLIER := 1.3

func _wreck_credit_multiplier(cause) -> float:
	var kc = KILL_CAUSES.get(cause)
	return WRECK_SCRAP_MULTIPLIER if kc != null and jt(kc.get("scrap")) else 1.0

func wreck_credit_bonus(cause) -> int:
	return roundi((_wreck_credit_multiplier(cause) - 1.0) * 100.0)

# Rams and torpedoes share the rules' "big" death class. Only refine the
# card's wording when the battle log identifies the attack on this hull.
func _heavy_wreck_cause(unit: Dictionary, log: Array) -> String:
	var target: String = unit["name"]
	var ram_hit := " rams " + target + " at full speed:"
	var ram_recoil := target + " rams " + str(unit.get("killedBy", "")) + " at full speed:"
	var torp_hit := " reach " + target
	var direct_hit := " at " + target + ":"
	# Spread Pattern marks the hull it actually kills at the moment of death (rules.gd torpImpact).
	# The burst summary names only the ship that was aimed at, so it cannot identify the victims;
	# the mark does, and a hull killed by the same attacker elsewhere in the fight has no mark.
	if jt(unit.get("splashKill")): return "Torpedo strike"
	for i in range(log.size() - 1, -1, -1):
		var line: String = log[i].get("m", "")
		if line.contains(ram_hit) or line.begins_with(ram_recoil): return "Rammed"
		if line.begins_with("Torpedoes from ") and (line.contains(torp_hit + ":") or line.contains(torp_hit + " (a stray hit in the lane):")):
			return "Torpedo strike"
		var gun := line.find(" fires ")
		var hit := line.find(direct_hit)
		if gun >= 0 and hit > gun:
			var weapon := line.substr(gun + 7, hit - gun - 7).to_lower()
			return "Torpedo strike" if weapon.contains("torpedo") else ""
	return ""

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
	var multiplier = _wreck_credit_multiplier(w.get("cause"))
	var intact = multiplier == 1.0
	var m = pickM[0] if (intact and pickM.size() > 0) else null
	var cred = jsround((10.0 + 9.0 * float(w["cp"])) * multiplier)
	var tow = RUN != null and RUN["fac"] == "corsair" and float(w["cp"]) <= 2 and intact and w.get("cause") != "dark" and HULLS.has(w.get("tpl")) and factionGate(RUN["fac"], w["tpl"]) == null and fleetCP() + float(or_(HULLS[w["tpl"]].get("cp"), 1)) <= float(RUN["cpCap"])
	return {"mod": m, "cred": cred, "tow": tow}
func prizeRansom(p: Dictionary, n) -> float:
	return jsround(shipValue(p["tpl"]) * 0.55 * (0.6 + 0.4 * float(or_(p.get("hpf"), 1))) * max(0.4, pow(0.85, float(z0(n)))) * priceMult())   # R1 (ECO-4): capture money passes through the same price multiplier as the shop
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
		var p = R["prizes"][i]; var o = prizeOffer(p, nR); var c = float(or_(p.get("cp"), 1)); var gate = factionGate(RUN["fac"], p["tpl"])
		var hf = HULLS[p["tpl"]]["fac"] if HULLS.has(p["tpl"]) else null
		var rip = RUN["fac"] == "voidsworn" and (hf == "hegemony" or hf == "deathless")
		var cinder = rip and not cinderOpen()   # R78 Q9: before run 3 the Crusade cannot keep a Hegemony or Eclipse prize
		var room = cp + c <= float(RUN["cpCap"]) and gate == null and not cinder   # B3: a prize your faction cannot field can only be stripped or ransomed
		var sv = float(o["strip"]["cred"]) + (jsround(float(MODULES[o["strip"]["mod"]]["cost"]) * 0.5) if jt(o["strip"]["mod"]) else 0.0)
		var dk = "add" if (room and float(or_(p.get("hpf"), 1)) >= 0.4) else ("strip" if sv >= float(o["ransom"]) else "ransom")
		var s_i = sel[i] if i < sel.size() else null
		var k = s_i if jt(s_i) else dk
		if k == "add" and not room: k = ("strip" if sv >= float(o["ransom"]) else "ransom") if dk == "add" else dk
		if k == "add": cp += c
		if k == "ransom": nR += 1
		rows.append({"p": p, "o": o, "room": room, "gate": gate, "cinder": cinder, "rip": rip, "k": k, "mine": jt(s_i) and s_i == k})
	return rows
func ACT_prizeStep() -> void:
	var R = RUN.get("reward")
	if R == null: return
	if or_(R.get("prizes"), []).is_empty():
		R["stage"] = "victory" if or_(R.get("wrecks"), []).is_empty() else "salvage"
		victoryCard()
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
	if R == null or R["stage"] != "prize" or or_(R.get("prizes"), []).is_empty(): return
	var rows = prizePlan(R); var got = []
	for r in rows:
		var p = r["p"]; var o = r["o"]
		if r["k"] == "add":
			var sh = newShip(p["tpl"]); sh["name"] = p["name"]; var mx = float(derive(sh)["maxHp"]); sh["hp"] = clampv(jsround(mx * float(or_(p.get("hpf"), 1))), 1, mx)
			if jt(r.get("rip")): sh["ripped"] = true   # R78 Q9: a kept Hegemony or Eclipse prize joins with its links ripped out
			RUN["fleet"].append(sh); got.append(ship_with_article(p["name"]) + " joins")
		elif r["k"] == "strip":
			if jt(o["strip"]["mod"]): RUN["inventory"].append(o["strip"]["mod"])
			RUN["credits"] = float(RUN["credits"]) + float(o["strip"]["cred"]); got.append("the " + str(p["name"]) + " is stripped (+" + numstr(o["strip"]["cred"]) + ")")
		else:
			RUN["credits"] = float(RUN["credits"]) + float(o["ransom"]); RUN["ransoms"] = float(z0(RUN.get("ransoms"))) + 1; got.append("the " + str(p["name"]) + " is ransomed (+" + numstr(o["ransom"]) + ")")
		tel("prize_pick", {"k": r["k"], "tpl": p["tpl"], "def": not r["mine"]})
	R["prizes"] = []; R["prizeSel"] = null
	R["stage"] = "victory" if or_(R.get("wrecks"), []).is_empty() else "salvage"
	saveRun()
	var t = ", ".join(PackedStringArray(got))
	if t != "": toast(t.substr(0, 1).to_upper() + t.substr(1) + ".")
	victoryCard()
func victoryCard() -> void:
	var ws = or_(W.get("wrecks"), [])
	var acts = []
	for i in range(ws.size()):
		var y = ws[i]["yield"]
		if jt(y.get("mod")): A(acts, "takeSalvage", str(i) + ":mod")
		A(acts, "takeSalvage", str(i) + ":cred")
		if jt(y.get("tow")): A(acts, "takeSalvage", str(i) + ":tow")
	if ws.is_empty(): A(acts, "rewardNext")
	var stored = RUN["reward"].get("victory")
	var data: Dictionary = stored.duplicate() if stored is Dictionary else {}
	data.merge({"wrecks": ws, "rw": W["rw"], "kind": RUN["reward"]["kind"]}, true)
	show_modal("victory", data, acts)

func loss_captain_escaped(loss: Dictionary) -> bool:
	if loss.has("escaped"): return jt(loss["escaped"])
	# Legacy reward saves have the names and the roster, but a prize may already have used the reserve captain.
	for entry in or_(RUN.get("reserve"), []):
		if entry.get("from") == loss.get("ship") and entry["cap"]["full_name"] == loss["cap"]["full_name"]:
			return true
	for entry in or_(RUN.get("fallen"), []):
		if entry.get("ship") == loss.get("ship") and entry["cap"]["full_name"] == loss["cap"]["full_name"]:
			return false
	return true

func wreck_tow_over_cap(w: Dictionary) -> bool:
	var hull = HULLS.get(w.get("tpl"))
	return hull != null and fleetCP() + float(or_(hull.get("cp"), 1)) > float(RUN["cpCap"])

func ACT_takeSalvage(a: String, fit := false) -> void:
	if RUN == null: return
	var R = RUN.get("reward")
	if R == null or R["stage"] != "salvage": return
	var p = a.split(":", true, 1); var i = int(p[0]); var k = "mod" if fit else (p[1] if p.size() == 2 else "")
	var ws = or_(W.get("wrecks"), []); var w = ws[i] if i >= 0 and i < ws.size() else null
	if w == null or not p[0].is_valid_int() or not (k in ["mod", "cred", "tow"]): return
	var y = w["yield"]
	if fit:
		if p.size() != 2 or p[1] == "": return
		var ship = _ship(p[1])
		if not _fit_module(ship, y.get("mod")): return
		_refit_fitted_notice(y["mod"], ship)
	elif k == "mod" and jt(y.get("mod")):
		RUN["inventory"].append(y["mod"]); toast(modName(y["mod"]) + " stripped from the " + str(w["name"]) + " and stowed in the hold.")
	elif k == "tow" and jt(y.get("tow")) and wreck_tow_over_cap(w):
		RUN["credits"] = float(RUN["credits"]) + float(y["cred"]); toast("No command points to crew " + ship_with_article(w["name"]) + ". She is broken up for scrap: +" + numstr(y["cred"]) + " credits.")
	elif k == "tow" and jt(y.get("tow")):
		var sh = newShip(w["tpl"]); sh["name"] = w["name"]; sh["hp"] = max(1.0, jsround(float(derive(sh)["maxHp"]) * 0.35)); RUN["fleet"].append(sh)
		toast(ship_with_article(w["name"], true) + " is under tow. Patch her up at a shipyard.")
	else:
		RUN["credits"] = float(RUN["credits"]) + float(y["cred"]); toast(ship_with_article(w["name"], true) + " is broken up for scrap: +" + numstr(y["cred"]) + " credits.")
	tel("salvage_pick", {"k": k, "cause": w.get("cause")})
	W["wrecks"] = []
	R["wrecks"] = []; R["stage"] = "pick"
	saveRun(); close_modal(); ACT_rewardNext()
func ACT_rewardNext() -> void:
	if RUN.get("reward") != null and RUN["reward"]["stage"] == "victory":
		RUN["reward"]["stage"] = "pick"
		saveRun()
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
func _refit_fitted_notice(module_id, ship: Dictionary) -> void:
	toast(modName(module_id) + " fitted onto " + ship_with_article(str(ship["name"])) + ".")

func ACT_takeMod(m: String, uid := "") -> void:
	if modal_d == null or modal_d["kind"] != "mod" or not or_(W.get("modOffer"), []).has(m): return
	var ship = _ship(uid) if uid != "" else null
	if uid != "" and not canFitModule(ship, m): return
	W["modOffer"] = null
	if ship == null:
		RUN["inventory"].append(m)
		toast(modName(m) + " stowed in the hold.")
	else:
		changeShip(ship, _push_mod.bind(m))
		_refit_fitted_notice(m, ship)
	tel("reward_pick", {"k": "mod", "id": m})
	close_modal(); relicStep()
func boonStep(p, minR) -> void:
	if RUN != null and RUN.get("eatenCore") != null and RUN["eatenCore"] == p:   # issue 1384: campaign_run.js boonStep remaps an eaten core
		for q in or_(RUN.get("patrons"), []):
			if q != p:
				p = q; break
	if not PATRONS.has(p):
		relicStep(); return
	var offer = RUN["reward"]["boonOffer"] if (RUN.get("reward") != null and RUN["reward"].get("boonOffer") != null) else rollBoonOffer(p, minR)
	W["boonOffer"] = offer
	if RUN.get("reward") != null and RUN["reward"].get("boonOffer") == null:
		RUN["reward"]["boonOffer"] = offer; saveRun()
	if offer.size() < 3 and not (RUN.get("reward") != null and jt(RUN["reward"].get("shortPaid"))):   # R1 (R64): a short offer pays 60 credits, once per reward
		RUN["credits"] = float(RUN["credits"]) + 60
		if RUN.get("reward") != null:
			RUN["reward"]["shortPaid"] = 1; saveRun()
		if offer.size() > 0: toast("Only " + str(offer.size()) + " on offer: +60 credits.")
	if offer.size() == 0:
		toast("Nothing left to offer. +60 credits."); relicStep(); return
	var acts = []
	for i in range(offer.size()): A(acts, "takeBoon", i)
	A(acts, "boonReroll", str(p) + ":" + numstr(z0(minR)), boonRerollOk(p, minR)); A(acts, "boonDecline")
	show_modal("boon", {"patron": p, "offer": offer, "rerollCost": boonRerollCost(), "declineCred": boonDeclineCred()}, acts)
# B4 step 3 (v54): decline a boon offer for credits, or reroll it once per reward for a price that grows each time you reroll in a run
func boonDeclineCred() -> float: return 30.0 + 10.0 * float(or_(RUN.get("sector") if RUN != null else null, 1))
func boonRerollCost() -> float: return 25.0 + 15.0 * float(z0(RUN.get("boonRerolls") if RUN != null else null))
# R1 (RWD-6): no reroll (and no charge) when the core has nothing beyond what is already on offer
func boonRerollOk(p = null, minR = null) -> bool:
	if not (RUN != null and RUN.get("reward") != null and not jt(RUN["reward"].get("rerolled")) and shopCan(boonRerollCost())): return false
	if p == null: return true
	var cur = _offer_ids(or_(RUN["reward"].get("boonOffer"), []))
	return boonOfferCan(p, minR).any(func(id): return not cur.has(id))
func _offer_ids(off: Array) -> Array:
	var o = []
	for x in off: o.append(x["id"])
	return o
func _all_old(off: Array, old: Array) -> bool:
	for x in off:
		if not old.has(x["id"]): return false
	return true
func boonReroll(p, minR) -> Variant:
	if not boonRerollOk(p, minR): return null
	shopPay(boonRerollCost()); RUN["boonRerolls"] = float(z0(RUN.get("boonRerolls"))) + 1; RUN["reward"]["rerolled"] = true
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
	if modal_d == null or modal_d["kind"] != "boon" or W.get("boonOffer") == null: return
	W["boonOffer"] = null
	var c = boonDecline(); tel("boon_decline", {"cred": c}); toast("You decline. +" + numstr(c) + " credits."); close_modal(); relicStep()
func _add_boon(o) -> void:
	RUN["boons"] = or_(RUN.get("boons"), []); RUN["boons"].append({"id": o["id"], "r": z0(o.get("r"))})
func ACT_takeBoon(a: String) -> void:
	if modal_d == null or modal_d["kind"] != "boon": return
	var offer = or_(W.get("boonOffer"), []); var i = int(a)
	var o = offer[i] if i >= 0 and i < offer.size() else null
	if o == null: return
	W["boonOffer"] = null
	changeFleet(_add_boon.bind(o))
	var ps = [BOONS[o["id"]]["p"]] if jt(BOONS[o["id"]].get("p")) else or_(BOONS[o["id"]].get("duo"), [])
	META["favour"] = or_(META.get("favour"), {})
	RUN["coreSync"] = or_(RUN.get("coreSync"), {})
	var sync_notices = []
	for p in ps:
		var before = favourOf(p); var t0 = favourTier(p)
		if RUN["coreSync"].get(p) == null: RUN["coreSync"][p] = before
		META["favour"][p] = before + 1 + float(z0(o.get("r"))); var t1 = favourTier(p)
		if t1 > t0: sync_notices.append("Core sync: " + str(PATRONS[p]["n"]) + " reached " + str(FAVOUR_TIERS[t1]["n"]) + " (" + numstr(favourOf(p)) + " sync). " + str(FAVOUR_TIERS[t1].get("d", "")))
	if not sync_notices.is_empty(): toast(" ".join(PackedStringArray(sync_notices)))
	tel("boon_pick", {"id": o["id"], "r": z0(o.get("r"))})
	toast(str(BOONS[o["id"]]["n"]) + " gained."); close_modal(); relicStep()
func relicStep() -> void:
	if RUN.get("reward") != null and RUN["reward"].get("kind") == "story":
		RUN["reward"] = null; W["boonOffer"] = null; saveRun(); mapScreen(); return
	if RUN.get("reward") != null and RUN["reward"]["stage"] != "relic" and RUN["reward"]["stage"] != "promo":
		RUN["reward"]["stage"] = "relic"; RUN["reward"]["boonOffer"] = null; RUN["reward"]["modOffer"] = null; saveRun()
	var rc = W.get("relicChoice")
	if rc != null and rc.size() > 0:
		var acts = []
		for r in rc: A(acts, "takeRelic", r)
		show_modal("relic", {"boss": or_(W.get("rewardCfg"), {}).get("kind") == "boss", "opts": rc}, acts); return
	promotionsStep()
func _add_relic(r) -> void: addRelic(r)
# issue 1653: every way a relic joins the run goes through here, so Black Fleet Ledger's command point is never missed
func addRelic(r) -> void:
	RUN["relics"].append(r)
	if r == "ledger2": RUN["cpCap"] = float(RUN["cpCap"]) + 1
func ACT_takeRelic(r: String) -> void:
	if not or_(W.get("relicChoice"), []).has(r): return
	changeFleet(_add_relic.bind(r))
	W["relicChoice"] = null
	if RUN.get("reward") != null: RUN["reward"]["relics"] = []
	close_modal(); promotionsStep()
func promotionsStep() -> void:
	var ships := []
	var acts := []
	for s in RUN["fleet"]:
		if float(z0(s["cap"].get("pending"))) <= 0: continue
		_offer_perks(s)
		ships.append(s)
		for p in s["cap"]["offer"]: A(acts, "takePerk", s["uid"] + ":" + p)
	if ships.is_empty():
		afterBattle()
		return
	if RUN.get("reward") != null:
		RUN["reward"]["stage"] = "promo"; RUN["reward"]["relics"] = []; saveRun()
	show_modal("promotions", {"ships": ships}, acts)
func resumeReward() -> bool:
	var R = RUN.get("reward") if RUN != null else null
	if R == null: return false
	var rc = {"kind": R.get("kind")}
	if R.get("node") != null: rc["node"] = R["node"]
	W["rewardCfg"] = rc; W["rw"] = or_(R.get("rw"), {}); W["relicChoice"] = or_(R.get("relics"), []); W["wrecks"] = or_(R.get("wrecks"), [])
	W["boonOffer"] = R.get("boonOffer"); W["modOffer"] = R.get("modOffer")
	toast("Picking up your rewards where you left off.")
	if R["stage"] == "prize":
		# Old saves kept the prize stage after paying and clearing the prize list.
		ACT_prizeStep(); return true
	if R["stage"] in ["victory", "salvage"]:
		if W["wrecks"].is_empty(): R["stage"] = "victory"
		victoryCard(); return true
	if R["stage"] == "pick":
		ACT_rewardNext(); return true
	if R["stage"] == "relic":
		relicStep(); return true
	promotionsStep(); return true
func afterBattle() -> void:
	var cfg = W.get("rewardCfg") if W.get("rewardCfg") != null else {"kind": RUN["reward"].get("kind") if RUN.get("reward") != null else null}
	RUN["reward"] = null
	var stop = findNode(RUN.get("curNode")) if RUN.get("curNode") != null else null
	if stop != null and jt(stop.get("nemCleared")) and not jt(stop.get("done")) and not jt(stop.get("nemEvent")):
		_open_stop(stop)
		if stop["type"] == "shipyard": saveRun()
		return
	if cfg.get("kind") == "boss":
		completeNode(false)
		_advance_sector()
		return
	completeNode()
	mapScreen()

func _advance_sector() -> void:
	if float(RUN["sector"]) >= 3:
		endRun(true); return
	var prev = nemActive()
	RUN["sector"] = float(RUN["sector"]) + 1; RUN["cpCap"] = float(RUN["cpCap"]) + 3; RUN["map"] = genSector(int(RUN["sector"])); RUN["pos"] = null
	var na = nemAdapt(false, prev) if jt(prev) else null   # B4, #121 (A4): the outgoing commander adapts once, from his own seen
	nemActive()   # then the incoming one resolves
	for s in RUN["fleet"]:
		var d = derive(s); s["hp"] = min(float(d["maxHp"]), float(s["hp"]) + jsround(float(d["maxHp"]) * 0.4 * repairMult()))
	saveRun(); mapScreen()
	var acts = []; A(acts, "beat3" if float(RUN["sector"]) == 3 else "closeModal")
	show_modal("sector", {"fac": RUN["map"]["fac"], "cond": sectorCond(), "region": RUN["map"].get("region"), "adapt": na if jt(prev) else null,
		"adaptFac": prev.get("fac") if jt(prev) else null, "adaptWho": nemFull(prev) if jt(prev) else "", "adaptLine": nemAdaptLine(prev, na) if (jt(prev) and na != null) else "", "adaptWhy": nemAdaptWhyLine(na, prev) if (jt(prev) and na != null) else ""}, acts)

# ======================= campaign3d.js: battles =======================
func nodeSeeds(nodes: Array) -> int:
	var n = 0
	for nd in nodes:
		# issue 1175: every column 4 stop can hold the Nemesis fight, so each carries a battle seed like a fight stop
		var c4 = RUN != null and RUN.get("map") is Dictionary and nd != null and float(nd.get("col", -1)) == float(RUN["map"]["cols"].size() - 3)
		if nd != null and not jt(nd.get("done")) and nd.get("seed") == null and (_is(nd, ["battle", "elite", "boss", "event"]) or c4):
			nd["seed"] = floor(rnd() * 4294967296.0); n += 1
	return n
func initFinishedRuns() -> void:
	# Only the real host opts in to tracking. Old profiles counted launches, including one saved active run.
	if not META["stats"].has("finishedRuns"):
		var active = (RUN != null and not jt(RUN.get("over"))) or (SAVED_RUN != null and not jt(SAVED_RUN.get("over"))) or _broken_run
		META["stats"]["finishedRuns"] = max(0, float(z0(META["stats"].get("runs"))) - (1 if active else 0))
func set_teaching_tips(on: bool) -> void:
	teaching_tips = on
	if on: initFinishedRuns()
	if RUN == null: return
	var enabled = on and float(z0(META["stats"].get("finishedRuns"))) < 2
	if enabled or RUN.has("teachingGate"): RUN["teachingGate"] = enabled
	var first = RUN.get("map", {}).get("cols", [[]])[0][0] if RUN.get("sector") == 1 and RUN.get("map", {}).has("cols") else null
	if first != null:
		if enabled and not jt(first.get("done")):
			if not first.has("teachingShape"): first["teachingShape"] = first.get("shape")
			first["shape"] = "open"
		elif first.has("teachingShape"):
			first["shape"] = first["teachingShape"]; first.erase("teachingShape")
func _teaching_battle_base() -> int:
	var won = RUN.get("stats", {}).get("battles", 0)
	return max(0, int(won)) if (won is int or won is float) and is_finite(float(won)) else 0
func _teaching_battle_number(key: String) -> int:
	var seen: Array = RUN["teachingBattles"] if RUN.get("teachingBattles") is Array else []
	var base = RUN.get("teachingBattleBase")
	var index := seen.find(key)
	return (int(base) if base != null else _teaching_battle_base()) + (seen.size() if index < 0 else index) + 1
func node_teaching_battle(node: Dictionary, kind: String) -> int:
	if RUN.get("teachingGate") != true or int(RUN["sector"]) != 1 or kind == "boss": return 0
	return _teaching_battle_number(numstr(RUN["sector"]) + ":" + str(node["id"]))
func teachingBattle(cfg: Dictionary) -> Dictionary:
	if RUN == null or RUN.get("teachingGate") != true: return cfg
	var key = numstr(RUN["sector"]) + ":" + str(or_(cfg.get("node"), "event")) + (":event" if jt(cfg.get("eventRelic")) else "")
	if not (RUN.get("teachingBattles") is Array): RUN["teachingBattles"] = []
	if RUN.get("teachingBattleBase") == null: RUN["teachingBattleBase"] = _teaching_battle_base()
	var seen = RUN["teachingBattles"]
	var n := _teaching_battle_number(key)
	if not seen.has(key): seen.append(key)
	cfg = cfg.duplicate(); cfg["runBattle"] = n; cfg["teachingGate"] = true
	if float(RUN["sector"]) != 1.0 or n > 2 or cfg.get("kind") == "boss": return cfg
	cfg["teachingBattle"] = n; cfg["fac"] = "hegemony" if n == 1 else "corsair"
	if n == 1 or n == 2: cfg.merge({"shape": "open", "arena": "strip", "dep": "line", "edgeFeature": true}, true)   # R366 (issue 1393): Battle 2 gets Battle 1's open strip; Corsairs and reinforcements stay
	return cfg
func saveTeachingHistory() -> void:
	if RUN == null or RUN.get("teachingGate") != true: return
	if SAVED_RUN != null:
		SAVED_RUN["teachingBattles"] = RUN["teachingBattles"].duplicate()
		SAVED_RUN["teachingBattleBase"] = RUN["teachingBattleBase"]
	persist_save() # Preserve the existing pre-battle checkpoint, including its position.
func battleScreen(cfg: Dictionary) -> void:
	close_modal()
	var sn = findNode(cfg["node"]) if jt(cfg.get("node")) else null
	if sn != null:
		nodeSeeds([sn])
		if sn.get("seed") != null and cfg.get("seed") == null:
			var sd = float((int(sn["seed"]) ^ 0x27d4eb2f) & 0xFFFFFFFF) if jt(cfg.get("eventRelic")) else float(sn["seed"])
			cfg = cfg.duplicate(); cfg["seed"] = sd
			rng.rnd_seed((int(sd) ^ 0x5bd1e995) & 0xFFFFFFFF)
	if RUN["fleet"].size() <= 1 and float(z0(RUN.get("reinf"))) < float(RUN["sector"]):
		RUN["reinf"] = RUN["sector"]; var sh = newShip(cheapHull(RUN["fac"])); RUN["fleet"].append(sh)
		var r_line: String = str({"chorus": "Your surviving spores coalesce into a fresh " + ship_bare(str(sh["name"])) + ".", "deathless": "An automated reserve berth dispatches " + ship_with_article(str(sh["name"])) + " to reinforce you.", "corsair": "A straggling raider from the outer belt joins your pack: " + ship_with_article(str(sh["name"])) + ".", "ithar": "A distant picket answers your distress pulse: " + ship_with_article(str(sh["name"])) + "."}.get(str(RUN["fac"]), "An allied sector patrol sends " + ship_with_article(str(sh["name"])) + " to reinforce you."))
		toast(r_line); tel("reinforced", {})
	var nd = findNode(cfg["node"]) if jt(cfg.get("node")) else null
	if nd != null and not jt(nd.get("enc")) and cfg["kind"] != "boss":
		nd.merge(rollEncounter(nd["type"], nd["col"]), true)
		if not jt(nd.get("map")) and RUN.get("map") != null and jt(RUN["map"].get("region")): nd["map"] = regionMap(RUN["map"]["region"], nd["col"], 7)
		fitEncounter(nd)
	var ro
	if cfg["kind"] == "boss": ro = {"enc": nd["enc"], "shape": nd.get("shape")} if (nd != null and jt(nd.get("enc"))) else bossEncounter()
	elif nd != null and jt(nd.get("enc")): ro = {"enc": nd["enc"], "shape": nd.get("shape")}
	else: ro = rollEncounter(cfg["kind"], or_(cfg.get("col"), 1))
	var mp = nd.get("map") if nd != null else null
	if not jt(mp) and RUN.get("map") != null and jt(RUN["map"].get("region")): mp = regionMap(RUN["map"]["region"], 6 if cfg["kind"] == "boss" else (nd["col"] if nd != null else 3), 7)
	if not jt(mp): mp = FAC_MAP[cfg["fac"]][0] if (cfg["kind"] == "boss" and FAC_MAP.has(cfg["fac"])) else "random"
	var c = {"map": mp, "dep": "line" if cfg["kind"] == "boss" else pick(["line", "line", "flank"]), "obj": ro["enc"], "shape": ro.get("shape"),
		"arch": nd.get("arch") if (cfg["kind"] != "boss" and nd != null) else null, "mod": nd.get("mod") if (cfg["kind"] != "boss" and nd != null) else null,
		"noStar": float(RUN["sector"]) == 1.0}   # R1: no dead star in sector 1
	c.merge(cfg, true)
	c = teachingBattle(c)
	saveTeachingHistory()
	if jt(RUN.get("verbNext")) and not jt(c.get("verb")): c["verb"] = RUN["verbNext"]   # B4: a next-battle faction verb
	if jt(RUN.get("storyNext")): c["storyMods"] = RUN["storyNext"].duplicate()
	var ext = battle_mode == "external" and battle_setup.is_valid()
	# Spend the modifier for this attempt, but leave the playable pre-fight save alone until the result is paid. Spent before
	# the battle is set up (the rules never read it), so the round 1 save (issue 1451) already has it spent.
	if jt(RUN.get("storyNext")): RUN["storyNext"] = null
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
# its PRNG from cfg.seed) and returns its B; the battle scene then plays it and calls finish_battle(result).
var battle_setup: Callable = Callable()
func start_battle(c: Dictionary) -> void:
	if battle_mode == "external" and battle_setup.is_valid():
		var c2 = c.duplicate(); c2["campaign"] = true   # the rules roll the mid-battle event right after setup, as campaign3d.js does
		var sc = sectorCond()
		if sc != null and jt(sc.get("war")) and c["kind"] != "boss": c2["event_war"] = true   # sectors at war force reinforcements (G1: draw it after setup)
		if c2.get("seed") == null: c2["seed"] = int(floor(rnd() * 4294967296.0))
		B = battle_setup.call(RUN, c2)
	else: stub_start(c)
# External mode: the battle scene reports the end. result is "win", "loss" or "retreat"; battle is the rules' B (units with the JS field names).
func finish_battle(result: String, battle = null) -> void:
	if battle != null: B = battle
	pending_battle = null
	if B == null: return
	if result == "retreat":
		# Bosses only use rout and ambush, so they cannot end in a forced breakthrough withdrawal.
		if jt(B.get("campaign")) and not jt(B.get("finished")) and B["cfg"].get("kind") != "boss":
			finishBattle("retreat")
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
	saved_battle = null   # issue 1451: the fight is being settled; its round save goes with the next checkpoint
	result = BattleAPI.settled_result(result, B)
	B["campaignResult"] = result
	if RUN.get("teachingGate") == true and B["units"].any(func(u): return jt(u.get("reinf"))): RUN["teachingReinforced"] = true
	var cfg = B["cfg"]
	var summary = {"cfg": cfg, "xp": [], "lost": [], "kills": 0, "rounds": B["round"], "prizes": [], "partial": jt(B.get("partial")), "boonStats": or_(B.get("boonStats"), {}).duplicate(), "treeStats": or_(B.get("treeStats"), {}).duplicate()}
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
		summary["nem"] = nemAfterBattle(result, fl != null and jt(fl.get("dead")) and not jt(fl.get("fled")), {"found": or_(B.get("nemFound"), []), "fled": jt(B.get("nemFled")), "beat": nemBeatOf(B.get("usage"), evasive), "cause": fl.get("killCause") if fl != null else null, "myFlagDead": B["units"].any(func(u): return jt(u.get("pflag")) and jt(u.get("dead")))})
	elif result == "win" and jt(nemActive()):
		var m = nemClockAdd(1)
		if m != "": summary["nemWarn"] = m
	var lostN = 0   # R42: a Chorus Nemesis grows from your losses
	for u in B["units"]:
		if u["side"] == "player" and u.get("ship") != null and jt(u.get("dead")) and not jt(u.get("exited")): lostN += 1
	if lostN > 0:
		var fm = nemFeedLosses(lostN)
		if fm != "": summary["nemFeed"] = fm
	var fw = nemFoundMerge(B.get("nemFound"))   # R42: weaknesses you triggered in battle stay known
	if fw.size() > 0:
		var fac = nemRead()["fac"]
		summary["nemFound"] = "Weakness confirmed: " + ", ".join(PackedStringArray(fw.map(func(k): return BattleAPI.nem_entry_name(NEM_WEAK, k, fac)))) + "."
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
			var loss := {"ship": ship["name"], "cap": ship["cap"].duplicate(true), "tpl": ship["tpl"], "escaped": false}
			summary["lost"].append(loss); RUN["stats"]["lost"] = float(z0(RUN["stats"].get("lost"))) + 1
			RUN["fleet"] = RUN["fleet"].filter(func(x): return not is_same(x, ship))
			if rnd() < 0.6:
				loss["escaped"] = true
				RUN["reserve"] = or_(RUN.get("reserve"), []); RUN["reserve"].append({"cap": ship["cap"], "from": ship["name"]})
				summary["escaped"] = or_(summary.get("escaped"), []); summary["escaped"].append(ship["cap"]["full_name"])
			else: RUN["fallen"].append({"cap": ship["cap"].duplicate(true), "ship": ship["name"], "sector": RUN["sector"]})
			continue
		ship["hp"] = clampv(jsround(float(u["hp"])), 1, derive(ship)["maxHp"])
		if result == "retreat":
			ship["hp"] = max(1.0, float(ship["hp"]) - jsround(float(u["maxHp"]) * 0.1)); continue
		if result == "win":
			var xp = min(60.0, jsround(8.0 + float(z0(u.get("dealt"))) / 4.0 + float(z0(u.get("kills"))) * 12.0)); var rk = ship["cap"]["rank"]
			var xp_before: float = ship["cap"]["xp"]
			addXp(ship, xp)
			CombatRecords.ship_rollup(B, u["id"])["captain_xp"] = float(ship["cap"]["xp"]) - xp_before
			summary["xp"].append({"ship": ship["name"], "cap": ship["cap"].duplicate(true), "xp": xp, "up": float(ship["cap"]["rank"]) > float(rk)})
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
		toast("Prize money: the crews strip a " + modName(m0) + " and 20 credits from " + str(summary["prizes"][0]["name"]) + " before anyone signs for it.")
	if result == "win":
		var dead = B["units"].filter(func(u): return u["side"] == "enemy" and jt(u.get("dead")) and not jt(u.get("fled")) and not jt(u.get("isSq")) and u.get("ship") == null and not jt(u.get("captured")))
		dead = ssort(dead, func(a, b): return float(z0(b["t"].get("cp"))) - float(z0(a["t"].get("cp"))))
		var wr = []
		for u in dead.slice(0, 3):
			var w = {"name": u["name"], "tpl": u["tpl"], "cls": u["t"].get("cls"), "fac": u.get("fac"), "cp": or_(u["t"].get("cp"), 1), "wk": _kinds(u["weapons"]), "ab": u.get("ab") if jt(u.get("ab")) else null,
				"regen": jt(u.get("hullRegen")) or (jt(u.get("regen")) and not jt(u.get("shMax"))), "sh": z0(u.get("shMax")), "cause": or_(u.get("killCause"), "blast"), "by": u.get("killedBy") if jt(u.get("killedBy")) else null}
			if w["cause"] == "big":
				var impact := _heavy_wreck_cause(u, or_(B.get("log"), []))
				if impact != "": w["impact"] = impact
			wr.append(w)
		summary["wrecks"] = wr
	if summary.get("escaped") != null:
		var esc_tail: String = {"chorus": " survived in a detached spore-node and bonds to your next hull.", "deathless": " streamed its backup clear before hull loss and awaits a fresh frame."}.get(str(RUN["fac"]), " escaped in a life pod and will take command of your next hull.")
		toast(" and ".join(PackedStringArray(summary["escaped"])) + esc_tail)
	if B.has("combat_events") or battle_mode == "external":
		summary["ship_rollups"] = CombatRecords.rollups(B)
		summary["lost_ship_records"] = B.get("lost_ship_records", []).duplicate(true)
		# The defeat and retreat paths do not open the victory reward, so keep their data on the run too.
		RUN["last_battle_report"] = {"result": result, "rounds": B["round"], "ship_rollups": summary["ship_rollups"],
			"lost_ship_records": summary["lost_ship_records"]}
	var msg = []
	for x in or_(summary.get("nem"), []): msg.append(x)
	if jt(summary.get("nemWarn")): msg.append(summary["nemWarn"])
	if jt(summary.get("nemFeed")): msg.append(summary["nemFeed"])
	if jt(summary.get("nemFound")): msg.append(summary["nemFound"])
	for w in or_(summary.get("wingPerks"), []):
		var pn = []
		for p in w["perks"]: pn.append(str(WING_PERKS[p]["n"]))
		msg.append(ship_with_article(str(w["ship"]), true) + "'s wings earn " + " and ".join(PackedStringArray(pn)) + ".")
	if msg.size() > 0: toast(" ".join(PackedStringArray(msg)))
	tel("battle_end", {"result": result, "kind": cfg.get("kind"), "fac": cfg.get("fac"), "rounds": B["round"], "kills": kills, "lost": summary["lost"].size()})
	B = null
	fleet_results.emit(not summary["lost"].is_empty(), summary["xp"].any(func(entry): return entry["up"]))
	if result == "win" and RUN["fleet"].size() == 0:
		var sh2 = newShip(cheapHull(RUN["fac"])); RUN["fleet"].append(sh2); ensureFlagship()
		var p_line: String = str({"chorus": "Your surviving spores coalesce into a fresh " + ship_bare(str(sh2["name"])) + " to carry the brood.", "deathless": "An automated reserve berth dispatches " + ship_with_article(str(sh2["name"])) + " to hold the uplink.", "corsair": "A straggling raider from the outer belt joins your pack to carry the flag: " + ship_with_article(str(sh2["name"])) + ".", "ithar": "A distant picket answers your distress pulse to carry the standard: " + ship_with_article(str(sh2["name"])) + "."}.get(str(RUN["fac"]), "An allied sector patrol sends " + ship_with_article(str(sh2["name"])) + " to carry the flag."))
		toast("The last ships traded themselves for the win. " + p_line); tel("reinforced", {"why": "pyrrhic"})
	if result == "loss" or RUN["fleet"].size() == 0:
		endRun(false); return
	if result == "retreat":
		retreatBack(); mapScreen(); toast("The fleet jumps clear, back to the last stop. The fight is still on the map."); return   # issue 1480 (R381)
	rewardFlow(summary)
	if summary.get("scrapped") != null:
		var tot = 0.0; var names = []
		for x in summary["scrapped"]:
			tot += float(x["cred"]); names.append(x["name"])
		toast("No command points to crew " + ", ".join(PackedStringArray(names)) + ": scrapped for " + numstr(tot) + " credits.")

# ---------------- the stub battle (test/node/golden_campaign.js has the same, line for line) ----------------
func stub_start(cfg: Dictionary) -> void:
	var seed = float(int(cfg["seed"]) & 0xFFFFFFFF) if cfg.get("seed") != null else floor(rnd() * 4294967296.0)
	rng.rnd_seed(int(seed))
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
			if u["side"] == "enemy" and not (cfg["kind"] == "boss" and jt(u.get("boss"))):   # issue 1480: in a boss fight, beside the boss
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
