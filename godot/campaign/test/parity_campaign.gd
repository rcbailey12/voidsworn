# G3 campaign parity, Godot side. Run headless:
#   godot --headless --path godot --script res://campaign/test/parity_campaign.gd -- <out_dir> <seed> [seed ...]
# Writes <out_dir>/c<seed>.jsonl for each seed. Mirrors test/node/golden_campaign.js line for line: the same seeded profile,
# the same bot (integer weights, a 31-bit LCG, the "stay" cap, the rare page reload), the same stub battle and the same records.
extends SceneTree
const JSM = preload("res://rules/jsm.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
var C

const STAY := {"closeModal": 1, "buyHull": 1, "buyMod": 1, "repair": 1, "repairAll": 1, "upgradeMk": 1, "sellShip": 1, "sellConfirm": 1, "yardFleet": 1, "equip": 1, "unequip": 1, "promote": 1,
	"fleetScreen": 1, "pickFaction": 1, "pickAdmiral": 1, "optAlt": 1, "optCmd": 1, "optHeat": 1, "progTab": 1, "buyVariant": 1, "factionVerb": 1, "buyTrack": 1}
const WT := {"enterNode": 10, "c3retreat": 2, "c3retreatYes": 1, "c3retreatNo": 1, "prizeSet": 3, "prizeConfirm": 4, "prizeStep": 1, "salvageStep": 1, "rewardNext": 1, "takeSalvage": 1,
	"takeBoon": 1, "takeMod": 1, "takeRelic": 1, "takePerk": 1, "eventChoice": 1, "pickAspect": 1, "closeModal": 1, "fleetFromModal": 1, "buyHull": 3, "buyMod": 3, "repair": 2, "repairAll": 3,
	"upgradeMk": 3, "sellShip": 1, "sellConfirm": 1, "yardFleet": 1, "leaveYard": 2, "equip": 4, "unequip": 1, "promote": 4, "backMap": 3, "backShipyard": 3, "fleetScreen": 1, "saveQuit": 1,
	"continueRun": 20, "newRunScreen": 2, "pickFaction": 1, "pickAdmiral": 2, "optAlt": 1, "optCmd": 1, "optHeat": 1, "startRun": 3, "progTab": 1, "buyVariant": 3, "nextFac": 0, "abandonRun": 0,
	"discardBrokenRun": 0, "factionVerb": 2, "boonReroll": 1, "boonDecline": 1, "buyTrack": 2}
const BATTLE_WT := {"win": 40, "partial": 4, "loss": 1}
var bot := {"s": 0, "streak": 0, "legacy": false, "help": false, "reloads": 0}

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 2:
		printerr("usage: -- <out_dir> <seed> [seed ...]"); quit(2); return
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.fixed_clock = true
	var bad := 0
	for i in range(1, a.size()):
		var seed := int(a[i]); var lines := PackedStringArray()
		var n := run_seed(seed, lines)
		var f := FileAccess.open(a[0].path_join("c%d.jsonl" % seed), FileAccess.WRITE); f.store_string("\n".join(lines) + "\n"); f.close()
		print("seed %d: %s" % [seed, (str(n) + " steps") if n > 0 else ("FAILED at step " + str(-n))])
		if n <= 0: bad += 1
	quit(1 if bad > 0 else 0)

func bot_next() -> int:
	bot["s"] = (int(bot["s"]) * 1103515245 + 12345) % 2147483648
	return bot["s"]
func weight(a: Array, on_title: bool) -> int:
	var k: String = a[0]; var arg: String = a[1]
	if k == "battle": return BATTLE_WT.get(arg, 0)
	if STAY.has(k) and bot["streak"] >= 8: return 0
	if k == "legacy": return 0 if bot["legacy"] else 3
	if k == "help": return 0 if bot["help"] else 1
	if k == "title": return 2 if on_title else 0
	return WT.get(k, 0)
func choose(list: Array):
	var on = list.filter(func(x): return x[2] == 1)
	var on_title = on.any(func(x): return x[0] == "progTab" or x[0] == "buyVariant") or (on.size() == 1 and on[0][0] == "title")
	var ws = []; var tot = 0
	for x in on:
		var w = weight(x, on_title); ws.append(w); tot += w
	if tot == 0:
		for p in ["closeModal", "leaveYard", "backMap", "backShipyard", "prizeConfirm", "c3retreatNo", "title"]:
			for x in on:
				if x[0] == p: return x
		return on[0] if on.size() > 0 else null
	var r = bot_next() % tot
	for i in range(on.size()):
		if r < ws[i]: return on[i]
		r -= ws[i]
	return on[on.size() - 1]

func reset_transients() -> void:
	C.RUN = null; C.B = null; C.W = {}; C.cur_event = null; C.yard_node = null; C.promote_after = Callable()
	C.picked_admiral = "vex"; C.picked_faction = C.or_(C.META["opts"].get("lastFac"), "voidsworn"); C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; C.prog_tab = "variants"
func do_reload() -> void:   # the page closing and reopening: only the save survives (the game's own save text and loader)
	var data = C.save_text()
	reset_transients()
	C.load_save_text(data)
	C.picked_faction = C.or_(C.META["opts"].get("lastFac"), "voidsworn")
	C.titleScreen()
func seed_meta(seed: int) -> void:
	var M = C.META; var k = seed % 4
	M["backfilled"] = 1; M["wonFix41"] = 1; M["opts"]["lastFac"] = C.RUN_FACTIONS[seed % 6]
	if k == 0: return
	M["renown"] = 30 + (seed % 7) * 15; M["stats"]["runs"] = 2 + k; M["stats"]["best"] = k
	var adms = C.ADMIRALS.keys()
	for i in range(adms.size()):
		if (i + seed) % 3 != 0: M["admirals"][adms[i]] = true
	for i in range(adms.size()): M["mastery"][adms[i]] = ((i * 7 + seed) % 6) * 10
	var ps = C.PATRONS.keys()
	for i in range(ps.size()): M["favour"][ps[i]] = ((i * 5 + seed) % 5) * 7
	if k >= 2:
		M["stats"]["wins"] = k - 1; M["stats"]["wonFacs"] = [C.RUN_FACTIONS[seed % 6]]
		var L = C.LEGACY.keys()
		for i in range(L.size()):
			if (i + seed) % 2 == 0: M["unlocked"][L[i]] = true
		var V = C.HULL_VARIANTS.keys()
		for i in range(V.size()):
			if (i + seed) % 3 == 0: M["variants"][V[i]] = true

func canon(v) -> String: return JSM.canon(v, "", {}, true)
func trans() -> Dictionary:
	var W = C.W; var b = null
	if C.B != null:
		var us = []
		for u in C.B["units"]:
			us.append([u["id"], u["side"], u["tpl"], u["hp"], C.jt(u.get("dead")), C.jt(u.get("captured")), C.jt(u.get("fled")), u["kills"], u["dealt"], u.get("killCause") if C.jt(u.get("killCause")) else null, u.get("killedBy") if C.jt(u.get("killedBy")) else null])
		b = {"seed": C.B["seed"], "round": C.B["round"], "over": C.B["over"] if C.jt(C.B.get("over")) else null, "partial": C.jt(C.B.get("partial")), "campaign": C.jt(C.B.get("campaign")),
			"finished": C.jt(C.B.get("finished")), "event": C.B.get("event"), "units": us}
	return {"rw": W.get("rw"), "relicChoice": W.get("relicChoice"), "wrecks": W.get("wrecks"), "boonOffer": W.get("boonOffer"), "modOffer": W.get("modOffer"), "aspOffer": W.get("aspOffer"),
		"rewardCfg": W.get("rewardCfg"), "ev": C.cur_event["id"] if C.cur_event != null else null, "evFac": "|".join(PackedStringArray(C.cur_event["o"].map(func(o): return str(o["l"])))) if C.cur_event != null else null, "uid": C.UID, "ended": C.ended, "yard": C.yard_node["id"] if C.yard_node != null else null, "pa": C.picked_admiral,
		"pf": C.picked_faction, "opt": C.run_opt, "tab": C.prog_tab, "b": b}
func parts() -> Dictionary:
	var run = "null"
	if C.RUN != null:
		var r = C.RUN.duplicate(false); r.erase("map"); run = canon(r)
	var mp = canon(C.RUN["map"]) if (C.RUN != null and C.RUN.get("map") != null) else "null"
	var m = C.META.duplicate(false); m.erase("tel")
	return {"run": run, "map": mp, "meta": canon(m), "t": canon(trans()), "saved": canon(C.SAVED_RUN)}
func acts_str() -> String:
	var out = PackedStringArray()
	for a in C.screen_acts(): out.append("%s:%s:%d" % [a[0], a[1], a[2]])
	return "|".join(out)

func run_seed(seed: int, lines: PackedStringArray) -> int:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); seed_meta(seed); C.SAVED_RUN = null
	reset_transients(); C.ended = false; C.toasts = []; C.tel_log = []
	bot = {"s": seed % 2147483647, "streak": 0, "legacy": false, "help": false, "reloads": 0}
	C.titleScreen()
	var last = {}
	var rec = func(i: int, act: String, arg: String) -> void:
		var p = parts(); var r = {"i": i, "act": act, "arg": arg, "acts": acts_str(), "rng": JSM.rng_s & 0xFFFFFFFF, "h": {}}
		for k in ["run", "map", "meta", "t", "saved"]:
			r["h"][k] = JSM.sha256(p[k]).substr(0, 16)
			if last.get(k) != p[k]:
				r[k] = p[k]; last[k] = p[k]
		lines.append(JSON.stringify(r))
	rec.call(0, "start", "")
	for i in range(1, 4001):
		if C.ended:
			lines.append(JSON.stringify({"i": i, "act": "end", "arg": ""})); return i
		if bot_next() % 100 < 2 and bot["reloads"] < 3 and C.RUN != null and C.SAVED_RUN != null:
			bot["reloads"] += 1; do_reload(); rec.call(i, "reload", ""); continue
		var a = choose(C.screen_acts())
		if a == null:
			lines.append(JSON.stringify({"i": i, "act": "stuck", "arg": ""})); return -i
		if a[0] == "legacy": bot["legacy"] = true
		if a[0] == "help": bot["help"] = true
		bot["streak"] = bot["streak"] + 1 if STAY.has(a[0]) else 0
		C.toasts = []
		C.act(a[0], a[1])
		rec.call(i, a[0], a[1])
	lines.append(JSON.stringify({"i": 4001, "act": "cap", "arg": ""})); return -4001
