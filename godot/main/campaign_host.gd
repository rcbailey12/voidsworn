extends Node
# Hosts the G3 campaign (res://campaign/campaign.gd: the run's rules and screen flow as data, every choice an act()) inside
# the game: draws its screens (G3's res://ui/campaign/campaign_ui.gd when present, otherwise a plain fallback), plays its
# battles in the battle scene (external battle mode), and for --bot-runs makes every choice itself so whole runs play
# headless, title to end screen. README.md in this folder is the contract.

signal run_over(summary: Dictionary)

const API := preload("res://rules/battle_api.gd")
const CAMPAIGN := "res://campaign/campaign.gd"
const UI_G3 := "res://ui/campaign/campaign_ui.gd"
const Fallback := preload("res://main/campaign_fallback_ui.gd")

# the G3 parity bot's weights (campaign/test/parity_campaign.gd), minus the stub battle buttons: real battles decide fights
const STAY := {"closeModal": 1, "buyHull": 1, "buyMod": 1, "repair": 1, "repairAll": 1, "upgradeMk": 1, "sellShip": 1, "sellConfirm": 1, "yardFleet": 1, "equip": 1, "unequip": 1, "promote": 1,
	"fleetScreen": 1, "pickFaction": 1, "pickAdmiral": 1, "optAlt": 1, "optCmd": 1, "optHeat": 1, "progTab": 1, "buyVariant": 1}
const WT := {"enterNode": 10, "prizeSet": 3, "prizeConfirm": 4, "prizeStep": 1, "salvageStep": 1, "rewardNext": 1, "takeSalvage": 1,
	"takeBoon": 1, "takeMod": 1, "takeRelic": 1, "takePerk": 1, "eventChoice": 1, "pickAspect": 1, "closeModal": 1, "fleetFromModal": 1, "buyHull": 3, "buyMod": 3, "repair": 2, "repairAll": 3,
	"upgradeMk": 3, "sellShip": 1, "sellConfirm": 1, "yardFleet": 1, "leaveYard": 2, "equip": 4, "unequip": 1, "promote": 4, "backMap": 3, "backShipyard": 3, "fleetScreen": 1,
	"newRunScreen": 2, "pickAdmiral": 2, "startRun": 3, "c3retreatNo": 1}

var main: Node
var C                       # the campaign (RefCounted)
var ui: Node
var bot := false
var opts := {}
var api_now = null          # the rules API of the battle being set up or played
var errors: Array = []
var battles := 0
var log_b: Array = []        # one line per battle for bot runs: sector, kind, result, rounds, ships
var cfg_now := {}
var acts_n := {}            # bot runs: how often each button was pressed
var seen_n := {}            # bot runs: how often each button was offered and enabled
var rng := RandomNumberGenerator.new()
var streak := 0
var in_battle := false
var story = null            # story hook: res://story/story.gd (null when the story folder is missing)
var t0 := 0.0


func start(m: Node, o: Dictionary) -> void:
	main = m
	opts = o
	bot = bool(o.get("bot", false))
	policy = str(o.get("policy", "smart"))
	t0 = Time.get_ticks_msec() / 1000.0
	C = load(CAMPAIGN).new()
	var err: String = C.load_tables()
	if err != "":
		errors.append("campaign tables: " + err)
	C.battle_mode = "external"
	C.battle_setup = _setup_battle
	C.battle_requested.connect(_on_battle)
	if bot:
		rng.seed = int(o.get("seed", 1))
		C.persist_on = false
		C.META = C.defaultMeta()
	else:
		C.persist_on = true
		C.persist_load()
	# story hook (story stream, godot/story/README.md): admiral lines, flagship name, titles, career records. Attached before
	# the first screen and before the UI binds, so it sees every change first; bot runs keep the career in memory only.
	if ResourceLoader.exists("res://story/story.gd"):
		story = load("res://story/story.gd").new()
		story.name = "Story"
		add_child(story)
		story.attach(C, not bot)
	C.titleScreen()
	if o.get("continue", false):
		C.act("continueRun")
	elif o.has("screen"):
		C.act(str(o["screen"]))
	else:
		C.act("newRunScreen")
	if bot:
		_bot_loop.call_deferred()
		return
	if ResourceLoader.exists(UI_G3):
		ui = load(UI_G3).new()
	else:
		ui = Fallback.new()
	if "hide_on_battle" in ui:
		ui.hide_on_battle = true
	add_child(ui)
	ui.bind(C)
	C.changed.connect(_on_changed)
	_on_changed()


static func has_save() -> bool:
	return FileAccess.file_exists("user://voidsworn_campaign.json")


var _music_page := ""


func _on_changed() -> void:
	# the map's music per sector (the music helper's player)
	var kind := str(C.page.get("kind", ""))
	if main.music != null and kind != _music_page:
		_music_page = kind
		if kind == "map" and C.RUN != null:
			main.music.play_map(int(C.RUN.get("sector", 1)))
		elif kind == "title":
			main.music.play_title()
	# back on the title page (the player left the run, or the run ended and they pressed Title): hand back to main's title
	if not bot and C.page.get("kind", "") == "title" and C.modal_d == null:
		run_over.emit({"result": "title"})


# external battle mode: build the real battle (G1 rules through the API) and give the campaign its B
func _setup_battle(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api_now = API.new()
	var e: String = api_now.load_rules()
	if e != "":
		errors.append("rules: " + e)
	api_now.new_battle(run, cfg)
	cfg_now = cfg
	if bot:
		var fl: Array = run.get("fleet", [])
		var hp := 0.0; var mh := 0.0
		for sh in fl:
			if sh is Dictionary:
				hp += float(sh.get("hp", 0)); mh += float(sh.get("maxHp", sh.get("hp", 0)))
		cfg_now = cfg.duplicate()
		cfg_now["_fleet"] = "%d ships %s, hull %d%%, credits %s" % [fl.size(), str(fl.map(func(x): return str(x.get("tpl", x.get("t", "?"))) if x is Dictionary else "?")), int(100.0 * hp / max(1.0, mh)), str(run.get("credits", "?"))]
	return api_now.R.B


func _on_battle() -> void:
	if in_battle:
		return
	in_battle = true
	_play_battle.call_deferred()


func _play_battle() -> void:
	var a = api_now
	if ui != null:
		ui.visible = false
	var r: Dictionary = await main.play_api(a, {"bot": bot, "can_retreat": C.can_retreat()})
	battles += 1
	for x in r.get("errors", []):
		errors.append("battle %d: %s" % [battles, str(x)])
	var res := str(r.get("result", "loss"))
	if res == "softlock":
		res = "loss"
	if ui != null:
		ui.visible = true
	in_battle = false
	if bot:
		log_b.append(_battle_line(a, res, r))
	C.finish_battle(res if res in ["win", "loss", "retreat"] else "loss", a.R.B)


# one battle's outcome for the bot-run report (to compare with sim3d campaign: contrib/opus/compute/balance_reference.md section 2)
func _battle_line(a, res: String, r: Dictionary) -> Dictionary:
	var B: Dictionary = a.R.B
	var ps := 0; var pa := 0; var es := 0; var ea := 0; var hp := 0.0; var mh := 0.0
	for u in B.get("units", []):
		if a.R.jt(u.get("isSq")) or not a.R.jt(u.get("ship")) and u.get("side") == "player":
			continue
		var dead: bool = a.R.jt(u.get("dead")) or a.R.jt(u.get("fled"))
		if u.get("side") == "player":
			ps += 1; pa += 0 if dead else 1
			mh += float(u.get("maxHp", 0)); hp += 0.0 if dead else max(0.0, float(u.get("hp", 0)))
		elif u.get("side") == "enemy":
			es += 1; ea += 0 if dead else 1
	var o = B.get("obj")
	return {"sector": int(C.RUN.get("sector", 0)) if C.RUN != null else 0, "kind": str(cfg_now.get("kind", "?")), "fac": str(cfg_now.get("fac", "?")),
		"obj": str(o.get("type")) if o is Dictionary else "?", "result": res, "raw": str(r.get("result", "")), "rounds": int(B.get("round", 0)),
		"fleet_in": str(cfg_now.get("_fleet", "")), "player": "%d/%d" % [pa, ps], "enemy": "%d/%d" % [ea, es], "hull": snappedf(hp / max(1.0, mh), 0.01)}


# ---------------------------------------------------------------- the full-run bot

# The default bot spends like a sensible player, so bot runs say something about balance: at a shipyard it repairs,
# replaces and adds hulls, then upgrades, then fits modules; on the map it heads for a yard when the fleet is short
# or the purse is full; it tows ships home and keeps captured prizes when there is room. "--bot-policy random" keeps
# the old G3 parity weights (every enabled button picked by weight).
var policy := "smart"
var yard_steps := 0
var pressed := {}           # prize and salvage rows already set on the current screen (so a set row is not set again)
var last_kind := ""

func _pick(on: Array, k: String, pref := ""):
	var best = null
	for x in on:
		if x[0] == k and (pref == "" or str(x[1]).ends_with(pref)):
			best = x
	return best


func _hull_cost(x) -> float:
	var h = C.HULLS.get(str(x[1]))
	return float(h.get("cost", 0)) if h is Dictionary else 0.0


func _smart(list: Array):
	var on: Array = list.filter(func(x): return int(x[2]) == 1 and x[0] != "battle" and x[0] != "c3retreat")
	var kind := str(C.page.get("kind", "")) if C.modal_d == null else str(C.modal_d.get("kind", "modal"))
	if kind != last_kind:
		pressed.clear()
		last_kind = kind
	if kind != "shipyard":
		yard_steps = 0
	if kind == "shipyard":
		yard_steps += 1
		if yard_steps > 40:
			return _pick(on, "leaveYard")
		for k in ["repairAll"]:
			var x = _pick(on, k)
			if x != null: return x
		var hulls: Array = on.filter(func(x): return x[0] == "buyHull")
		if hulls.size() > 0:
			hulls.sort_custom(func(a, b): return _hull_cost(a) > _hull_cost(b))
			return hulls[0]
		for k in ["upgradeMk", "buyMod", "equip", "promote"]:
			var x = _pick(on, k)
			if x != null: return x
		return _pick(on, "leaveYard")
	if C.modal_d == null and kind == "map":
		var nodes: Array = on.filter(func(x): return x[0] == "enterNode")
		if nodes.size() > 1 and C.RUN != null:
			var short: bool = C.RUN.get("fleet", []).size() < 4 or float(C.RUN.get("credits", 0)) >= 300
			var ws: Array = []
			var tot := 0.0
			for x in nodes:
				var n = C.findNode(x[1])
				var t := str(n.get("type", "")) if n is Dictionary else ""
				var w := 1.0
				if t == "shipyard": w = 6.0 if short else 1.0
				elif t == "drydock": w = 2.0
				elif t == "elite": w = 0.6 if short else 1.0
				ws.append(w); tot += w
			var r := rng.randf() * tot
			for i in nodes.size():
				if r < ws[i]: return nodes[i]
				r -= ws[i]
			return nodes[nodes.size() - 1]
	# prizes: keep a ship when there is room, else ransom it; salvage: tow a hull home when offered
	var rows := {}
	for x in on:
		if x[0] == "prizeSet" or x[0] == "takeSalvage":
			var row := str(x[1]).get_slice(":", 0)
			if not pressed.has(x[0] + row):
				rows[x[0] + row] = rows.get(x[0] + row, []) + [x]
	for key in rows:
		for pref in [":tow", ":add", ":ransom", ":mod", ":cred"]:
			for x in rows[key]:
				if str(x[1]).ends_with(pref):
					pressed[key] = true
					return x
	var cf = _pick(on, "prizeConfirm")
	if cf != null: return cf
	return _weighted(on)


func _choose(list: Array):
	if policy != "random":
		return _smart(list)
	var on0: Array = list.filter(func(x): return int(x[2]) == 1 and x[0] != "battle" and x[0] != "c3retreat")
	return _weighted(on0)


func _weighted(on: Array):
	var ws: Array = []
	var tot := 0
	for x in on:
		var k: String = x[0]
		var w := 0
		if not (STAY.has(k) and streak >= 8):
			w = int(WT.get(k, 0))
		ws.append(w)
		tot += w
	if tot == 0:
		for p in ["closeModal", "leaveYard", "backMap", "backShipyard", "prizeConfirm", "c3retreatNo", "rewardNext", "c3continue"]:
			for x in on:
				if x[0] == p:
					return x
		return on[0] if on.size() > 0 else null
	var r := rng.randi() % tot
	for i in on.size():
		if r < ws[i]:
			return on[i]
		r -= ws[i]
	return on[on.size() - 1]


func _bot_loop() -> void:
	var steps := 0
	var sector := 1
	while not C.ended and steps < 6000:
		if C.RUN != null:
			sector = int(C.RUN.get("sector", sector))
		if in_battle or C.pending_battle != null:
			# waiting on a battle is not a click
			if not in_battle:
				_on_battle()
			await get_tree().process_frame
			continue
		steps += 1
		var sa: Array = C.screen_acts()
		for x in sa:
			if int(x[2]) == 1:
				seen_n[x[0]] = int(seen_n.get(x[0], 0)) + 1
		var a = _choose(sa)
		if a != null:
			acts_n[a[0]] = int(acts_n.get(a[0], 0)) + 1
		if a == null:
			errors.append("stuck on page %s (modal %s) with no button to press" % [str(C.page.get("kind")), str(C.modal_d.get("kind") if C.modal_d != null else "none")])
			break
		streak = streak + 1 if STAY.has(a[0]) else 0
		C.act(a[0], a[1])
		if steps % 40 == 0:
			await get_tree().process_frame
	if not C.ended and steps >= 6000:
		errors.append("no end after 6000 clicks (page %s)" % str(C.page.get("kind")))
	var won := false
	var pd: Dictionary = C.page.get("data", {}) if C.page.get("data") is Dictionary else {}
	if pd.has("victory"):
		won = bool(pd["victory"])
	run_over.emit({"result": "win" if won else ("loss" if C.ended else "unfinished"), "sector": sector, "battles": battles, "clicks": steps, "errors": errors, "log": log_b, "pressed": acts_n, "offered": seen_n, "game_s": Time.get_ticks_msec() / 1000.0 - t0})
