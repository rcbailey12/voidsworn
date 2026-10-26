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
var rng := RandomNumberGenerator.new()
var streak := 0
var in_battle := false
var t0 := 0.0


func start(m: Node, o: Dictionary) -> void:
	main = m
	opts = o
	bot = bool(o.get("bot", false))
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
	C.finish_battle(res if res in ["win", "loss", "retreat"] else "loss", a.R.B)


# ---------------------------------------------------------------- the full-run bot

func _choose(list: Array):
	var on: Array = list.filter(func(x): return int(x[2]) == 1 and x[0] != "battle" and x[0] != "c3retreat")
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
		var a = _choose(C.screen_acts())
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
	run_over.emit({"result": "win" if won else ("loss" if C.ended else "unfinished"), "sector": sector, "battles": battles, "clicks": steps, "errors": errors, "game_s": Time.get_ticks_msec() / 1000.0 - t0})
