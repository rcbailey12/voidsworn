extends Node
# Hosts the G3 campaign (res://campaign/campaign.gd: the run's rules and screen flow as data, every choice an act()) inside
# the game: draws its screens (G3's res://ui/campaign/campaign_ui.gd when present, otherwise a plain fallback), plays its
# battles in the battle scene (external battle mode), and for --bot-runs makes every choice itself so whole runs play
# headless, title to end screen. README.md in this folder is the contract.

signal run_over(summary: Dictionary)

const API := preload("res://rules/battle_api.gd")
const Campaign := preload("res://campaign/campaign.gd")
const UI_G3 := "res://ui/campaign/campaign_ui.gd"
const Fallback := preload("res://main/campaign_fallback_ui.gd")
const Teaching := preload("res://ui/campaign/campaign_tips.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")   # issue 1448: ui_boss when a boss or Nemesis fight is entered

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
	C = Campaign.new()
	var err: String = C.load_tables()
	if err != "":
		errors.append("campaign tables: " + err)
	C.battle_mode = "external"
	C.battle_setup = _setup_battle
	C.battle_restore = _restore_battle   # issue 1451: Continue into the saved round
	C.battle_requested.connect(_on_battle)
	if not bot:
		C.fleet_results.connect(_on_fleet_results)
	# the campaign's random stream: the browser seeds it at random on every load (core.js RNG_S, nothing saved), so a new
	# or continued run gets fresh draws each launch; bot runs seed it from --seed so each run differs and repeats exactly
	if o.has("player_path_seed"):
		_seed_campaign(int(o["player_path_seed"]))
	else:
		_seed_campaign(int(o.get("seed", 1)) if bot else randi())
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
	if not bot: C.initFinishedRuns()
	# issue 1217: the screens' playtest default (campaign_ui.gd bind, R1) must hold before the first page is built, or the
	# first faction and admiral page offers Select only for each faction's free admiral until something re-renders it
	if not bot and "playtest_default" in C: C.playtest_default = true
	C.set_teaching_tips(not bot and not Teaching.is_off() and not main.args.has("no-tips"))
	C.titleScreen()
	if o.get("continue", false):
		C.act("continueRun")
	elif o.has("screen"):
		C.act(str(o["screen"]))
	else:
		C.act("newRunScreen")
	C.set_teaching_tips(not bot and not Teaching.is_off() and not main.args.has("no-tips"))
	if bot:
		_bot_loop.call_deferred()
		return
	if ResourceLoader.exists(UI_G3):
		ui = load(UI_G3).new()
	else:
		ui = Fallback.new()
	if "hide_on_battle" in ui:
		ui.hide_on_battle = true
	if "ai_level" in ui:
		ui.ai_level = ai_level()   # issue 1336: the map's danger bands follow the setting
	add_child(ui)
	ui.bind(C)
	C.changed.connect(_on_changed)
	_on_changed()


func _seed_campaign(s: int) -> void:
	if C.has_method("seed_rng"):
		C.seed_rng(s & 0xFFFFFFFF)
	else:
		load("res://rules/jsm.gd").rnd_seed(s & 0xFFFFFFFF)  # fallback until campaign.seed_rng() lands (G3)


static func has_save(path: String = Campaign.SAVE_PATH) -> bool:
	return Campaign.has_saved_run(path)


var _music_page := ""   # the music key last played (music_key); "" after a battle, so the page plays again


# Issue 1482: which music a campaign page asks for. "title", "map:<sector>" (the map and the service stop: a run page
# keeps its sector's map track, and a new sector is a new key even when the page kind stays "map"), or the page kind
# itself for pages that keep whatever plays (the battle briefing, the end card, setup pages).
const MAP_MUSIC_PAGES := ["map", "shipyard"]
static func music_key(kind: String, run) -> String:
	if kind == "title":
		return "title"
	if kind in MAP_MUSIC_PAGES and run is Dictionary:
		return "map:%d" % int((run as Dictionary).get("sector", 1))
	return kind


func _on_changed() -> void:
	C.set_teaching_tips(not bot and not Teaching.is_off() and not main.args.has("no-tips"))
	# the map's music per sector (the music helper's player)
	var key := music_key(str(C.page.get("kind", "")), C.RUN)
	if main.music != null and key != _music_page:
		_music_page = key
		if key.begins_with("map:"):
			main.music.play_map(int(key.substr(4)))
		elif key == "title":
			main.music.play_title()
	# back on the title page (the player left the run, or the run ended and they pressed Title): hand back to main's title
	if not bot and C.page.get("kind", "") == "title" and C.modal_d == null:
		run_over.emit({"result": "title"})


func _on_fleet_results(lost: bool, ranked_up: bool) -> void:
	if lost:
		Kit.play("ui_ship_lost")
	if ranked_up:
		if lost:
			get_tree().create_timer(1.8).timeout.connect(_play_rank_up)
		else:
			_play_rank_up()


func _play_rank_up() -> void:
	Kit.play("ui_rank_up")


# The enemy AI level from the settings ("standard" or "veteran"; bot runs default to Veteran in main.gd), issue 1336.
# A missing setting falls back to Standard, the new-player default (R49, issue 1504); a bare host with no main keeps the
# API default, Veteran.
func ai_level() -> String:
	if main != null and "settings" in main:
		return str(main.settings.get("ai", "standard"))
	return "veteran"


# external battle mode: build the real battle (G1 rules through the API) and give the campaign its B
func _setup_battle(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api_now = API.new()
	var e: String = api_now.load_rules()
	if e != "":
		errors.append("rules: " + e)
	api_now.set_ai_level(ai_level())   # issue 1336: before new_battle, which rolls the enemy fleet at the level
	api_now.round_saves = round_saves_on()   # issue 1451: pack the rules state at each round start (round 1 included)
	api_now.interactive_deployment = not bot
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
	return _bstate(api_now)


# Issue 1451: round saves are on for the player's runs; bot runs keep them off (no disk) unless --round-saves asks for them.
func round_saves_on() -> bool:
	return not bot or (main != null and main.args.has("round-saves"))


# Issue 1451: the battle saved at a round start, rebuilt on a fresh rules API (the campaign's Continue)
func _restore_battle(sb: Dictionary) -> Dictionary:
	var a = API.new()
	var e: String = a.load_rules()
	if e != "":
		return {"error": "rules: " + e}
	var bytes := Marshalls.base64_to_raw(str(sb.get("data", "")))
	var why: String = a.restore_round(bytes, int(sb.get("size", 0)), str(sb.get("fp", "")))
	if why != "":
		return {"error": why}
	a.round_saves = round_saves_on()
	api_now = a
	cfg_now = a.R.B.get("cfg", {})
	return {"B": a.R.B, "run": a.R.RUN}


# Issue 1451: the battle scene's round start has settled (no animation playing, the player to act): write that round's save.
# True only when it reached the disk (the battle menu offers Save and quit on that alone, Artoo on PR 1486).
func _save_round() -> bool:
	if api_now == null or C == null:
		return false
	return C.save_battle_round(api_now.take_round_snapshot())


func _on_battle() -> void:
	if in_battle:
		return
	in_battle = true
	if not bot and is_boss_fight(C.pending_battle):
		Kit.play("ui_boss")
	_play_battle.call_deferred()


# A sector flagship, the finale or a Nemesis battle (issue 1448): the fights that open on the boss chord.
static func is_boss_fight(cfg) -> bool:
	if not (cfg is Dictionary):
		return false
	var nm = cfg.get("nemesis")
	return str(cfg.get("kind", "")) == "boss" or (nm is Dictionary and not nm.is_empty())


func _play_battle() -> void:
	var a = api_now
	if ui != null:
		ui.visible = false
	var po := {"bot": bot, "can_retreat": C.can_retreat()}
	if a.round_saves:
		po["on_round"] = _save_round
	var r: Dictionary = await main.play_api(a, po)
	if str(r.get("result", "")) == "closing":
		# issue 1518 (Artoo on PR 1445): the game closed while the battle was still waiting to begin. No battle was
		# played, so nothing is settled, counted or saved: the run stays at its checkpoint, as if the battle never opened
		return
	if str(r.get("result", "")) == "save_quit":
		# issue 1451 (and Artoo on the issue): Save and quit is not a result. Nothing is settled; the run stays saved at the round
		if ui != null:
			ui.visible = true
		in_battle = false
		_music_page = ""   # issue 1482
		_save_round()   # the newest round start the rules packed, if the scene had not written it yet
		C.leave_battle_saved()
		return
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
	C.set_teaching_tips(not bot and not Teaching.is_off() and not main.args.has("no-tips"))
	_music_page = ""   # issue 1482: the battle played its own music; whatever page follows (even the same one) plays its track
	C.finish_battle(res if res in ["win", "loss", "retreat"] else "loss", _bstate(a))


# the battle's rules state for the campaign's after-battle rules, through battle_api.gd (fallback until battle_state() lands)
static func _bstate(a) -> Dictionary:
	return a.battle_state() if a.has_method("battle_state") else a.R.B


static func _jt(x) -> bool:  # JS truthiness, as the rules' jt
	if x == null:
		return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING: return x != ""
	return true


# one battle's outcome for the bot-run report (to compare with sim3d campaign: contrib/opus/compute/balance_reference.md section 2)
func _battle_line(a, res: String, r: Dictionary) -> Dictionary:
	var B: Dictionary = _bstate(a)
	var ps := 0; var pa := 0; var es := 0; var ea := 0; var hp := 0.0; var mh := 0.0
	for u in B.get("units", []):
		if _jt(u.get("isSq")) or not _jt(u.get("ship")) and u.get("side") == "player":
			continue
		var dead: bool = _jt(u.get("dead")) or _jt(u.get("fled"))
		if u.get("side") == "player":
			var alive := API.RulesScript.player_ship_survives(u)
			ps += 1; pa += 1 if alive else 0
			mh += float(u.get("maxHp", 0)); hp += max(0.0, float(u.get("hp", 0))) if alive else 0.0
		elif u.get("side") == "enemy":
			es += 1; ea += 0 if dead else 1
	var o = B.get("obj")
	return {"sector": int(C.RUN.get("sector", 0)) if C.RUN != null else 0, "kind": str(cfg_now.get("kind", "?")), "fac": str(cfg_now.get("fac", "?")),
		"obj": str(o.get("type")) if o is Dictionary else "?", "result": res, "raw": str(r.get("result", "")), "rounds": int(B.get("round", 0)),
		"fleet_in": str(cfg_now.get("_fleet", "")), "player": "%d/%d" % [pa, ps], "enemy": "%d/%d" % [ea, es], "hull": snappedf(hp / max(1.0, mh), 0.01),
		"pace": r.get("pace", {}), "pfac": str(C.RUN.get("fac", "")) if C.RUN != null else ""}


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


var bot_fac := ""            # --bot-fac <faction|random>: the player faction for bot runs (default: the game's first, the Sunward Crusade, id voidsworn)


func _smart(list: Array):
	var on: Array = list.filter(func(x): return int(x[2]) == 1 and x[0] != "battle" and x[0] != "c3retreat")
	var kind := str(C.page.get("kind", "")) if C.modal_d == null else str(C.modal_d.get("kind", "modal"))
	if kind == "admiral" and main.args.has("bot-fac"):
		if bot_fac == "":
			var facs: Array = on.filter(func(x): return x[0] == "pickFaction").map(func(x): return str(x[1]))
			bot_fac = str(main.args["bot-fac"])
			if bot_fac == "random" and not facs.is_empty():
				bot_fac = facs[absi(int(main.args.get("seed", randi()))) % facs.size()]  # follows --seed, so a run can be replayed
		if str(C.picked_faction) != bot_fac:
			for x in on:
				if x[0] == "pickFaction" and str(x[1]) == bot_fac:
					return x
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
