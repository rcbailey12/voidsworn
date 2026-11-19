extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")
const Career = preload("res://story/career.gd")
const Story = preload("res://story/story.gd")
const Host = preload("res://main/campaign_host.gd")

class SaveProbe extends Campaign:
	var writes: Array[String] = []

	func persist_save(meta_only: bool = false) -> void:
		super.persist_save(meta_only)
		writes.append(save_text())

class CareerProbe extends Career:
	var result := ""

	func record_battle(run: Dictionary, battle: Dictionary, outcome: String) -> Dictionary:
		result = outcome
		return super.record_battle(run, battle, outcome)

class EndHud extends CanvasLayer:
	var heading := ""
	var banner_text := ""

	func banner(text: String, _color: Color, _seconds: float) -> void:
		banner_text = text

	func show_end(title: String, _body: String, _win: bool, _external: bool) -> void:
		heading = title

class EndSound extends Node:
	func sting(_win: bool) -> void: pass

class EndScene extends "res://scenes/battle/battle.gd":
	func _ready() -> void: pass
	func wait(_ms: float) -> void: pass
	func _play_log_out(_res: String) -> void: pass

var failures := 0
var scratch := ""
var legacy_dir := ""
var record_legacy := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2:
		record_legacy = args[0] == "--record-legacy"
		legacy_dir = args[1]
	scratch = OS.get_environment("TEMP") if OS.has_environment("TEMP") else "/tmp"
	scratch = scratch.path_join("voidsworn_resume_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	if DirAccess.make_dir_absolute(scratch) != OK:
		printerr("FAIL: could not create isolated save folder")
		quit(2)
		return
	_story_boss()
	await _breakthrough()
	_backup_continue()
	_boss_payout()
	_prize_reload()
	_yard_doctrine()
	_career_backup()
	quit(1 if failures else 0)

func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1

func _campaign(sector := 1):
	var c := SaveProbe.new()
	assert(c.load_tables() == "")
	API.JSM.rnd_seed(1091)
	c.fixed_clock = true
	c.newRun("vex", "voidsworn")
	if sector > 1:
		c.RUN["sector"] = sector
		c.RUN["map"] = c.genSector(sector)
		c.saveRun()
	c.mapScreen()
	return c

func _load(text: String):
	var c = _campaign()
	c.titleScreen()
	c.load_save_text(text)
	return c

func _legacy(name_: String, text: String) -> String:
	if legacy_dir.is_empty(): return text
	var path := legacy_dir.path_join(name_ + ".json")
	if record_legacy:
		_put(path, text)
		return text
	assert(FileAccess.file_exists(path))
	return FileAccess.get_file_as_string(path)

func _external(c):
	var api = API.new()
	assert(api.load_rules() == "")
	c.battle_mode = "external"
	c.battle_setup = func(run, cfg):
		api.new_battle(run, cfg)
		return api.R.B
	return api

# Reach the column before the real boss without simulating the preceding fights.
func _boss_approach(c) -> String:
	var cols: Array = c.RUN["map"]["cols"]
	var id: String = cols.back()[0]["id"]
	var edge: Array = c.RUN["map"]["edges"].filter(func(e): return e[1] == id)[0]
	c.RUN["pos"] = edge[0]
	c.findNode(edge[0])["done"] = true
	c.saveRun()
	c.mapScreen()
	return id

func _story_boss() -> void:
	var c = _campaign(3)
	var id = _boss_approach(c)
	c.showBeat3()
	c.act("eventChoice", "0")
	c.act("closeModal")
	_external(c)
	c.act("enterNode", id)
	var cfg: Dictionary = c.B["cfg"]
	assert(cfg["storyMods"]["power"])
	var d = _load(c.save_text())
	_external(d)
	d.act("continueRun")
	if d.page["kind"] == "map" and d.availableNodes().has(id): d.act("enterNode", id)
	var reopened: bool = d.B != null and d.B["cfg"].get("node") == id and d.B["cfg"].get("seed") == cfg["seed"] and d.B["cfg"].get("storyMods", {}).get("power", false)
	_check(reopened, "1: closing mid-fight lets Continue replay the same boosted boss")
	# Serialize the exact old checkpoint: arrived at an unfinished node, modifier already consumed.
	c.saveRun()
	d = _load(_legacy("story_boss", c.save_text()))
	_external(d)
	d.act("continueRun")
	_check(d.B != null and d.B["cfg"].get("node") == id and d.B["cfg"].get("storyMods", {}).get("power", false),
		"1 legacy: an already stranded story boss reopens with the chosen power")

func _breakthrough() -> void:
	var c = _campaign()
	while c.RUN["fleet"].size() < 3: c.RUN["fleet"].append(c.newShip("warden"))
	var id = c.availableNodes()[0]
	c.RUN["curNode"] = id
	c.RUN["pos"] = id
	var story := Story.new()
	var career := CareerProbe.new()
	story.career = career
	story.attach(c, false)
	var api = _external(c)
	c.battleScreen({"kind": "battle", "obj": "break", "fac": "hegemony", "col": 1, "seed": 1091, "map": "belt", "shape": "open", "node": id})
	var r = api.R
	var ships: Array = r.caps("player")
	var escaped = ships[0]
	var uid = escaped["ship"]["uid"]
	var hex = r.boardHexes().filter(func(h): return r.objZone(h.q, h.r) == "exit")[0]
	escaped["q"] = hex.q; escaped["r"] = hex.r
	r.objAfterMove(escaped)
	for ship in ships.slice(1):
		ship["dead"] = true
		ship["hp"] = 0
	r.checkEnd()
	assert(r.B["over"] == "loss" and r.B["withdraw"] and r.survivorsP() == 1)
	var scene := EndScene.new()
	var hud := EndHud.new()
	var sound := EndSound.new()
	scene.hud = hud; scene.sfx = sound; scene.api = api; scene.V = api.view()
	scene.add_child(hud); scene.add_child(sound); root.add_child(scene)
	scene.set_process(false); scene.set_physics_process(false)
	await scene._end_flow()
	c.finish_battle(scene.result["result"], r.B)
	_check(hud.heading == "Withdrawal" and hud.banner_text == "Withdrawal" and scene.result["result"] == "retreat",
		"2 HUD: a failed breakthrough with a ship clear is called Withdrawal")
	_check(c.page["kind"] == "map" and c.RUN != null and c.RUN["fleet"].size() == 1 and c.RUN["fleet"][0]["uid"] == uid and c.findNode(id)["done"] and c.SAVED_RUN != null and career.result == "retreat",
		"2 campaign and Career: the ship that jumped clear survives and the run continues")
	scene.free()
	story.free()

func _put(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(text)
	f.close()

func _backup_continue() -> void:
	var c = _campaign()
	c.META["renown"] = 41
	var path := scratch.path_join("campaign.json")
	_put(path + ".bak", c.save_text())
	var recovered := true
	for primary in [null, "", "{", '{"meta":[],"run":null}']:
		if primary != null: _put(path, primary)
		var d = _campaign()
		d.SAVED_RUN = null
		d.save_path = path
		d.persist_load()
		d.titleScreen()
		recovered = recovered and Host.has_save(path) and d.page["data"]["saved"] and d.META["renown"] == 41
	_check(recovered, "3: missing, empty and malformed primary saves fall back to a valid backup")
	c.SAVED_RUN = null
	_put(path, c.save_text())
	var d = _campaign()
	d.save_path = path
	d.persist_load()
	d.titleScreen()
	var offered: bool = d.screen_acts().any(func(a): return a[0] == "continueRun")
	d.act("continueRun")
	_check(not Host.has_save(path) and not offered and d.page["kind"] == "title" and d.RUN == null and d.META["renown"] == 41,
		"3: a valid profile-only primary wins over a backup run and has no Continue action")

func _boss_payout() -> void:
	for sector in [1, 3]:
		var c = _campaign(sector)
		var id = _boss_approach(c)
		if sector == 3:
			c.showBeat3(); c.act("eventChoice", "0"); c.act("closeModal")
		c.act("enterNode", id)
		assert(c.page["kind"] == "battle")
		c.act("battle", "win")
		assert(c.RUN["reward"]["kind"] == "boss")
		var legacy := ""
		var before_credits: float = c.RUN["credits"]
		for i in range(20):
			if c.RUN == null or c.RUN.get("reward") == null: break
			var acts: Array = c.screen_acts().filter(func(a): return a[2] == 1)
			var click: Array = acts[0]
			c.writes.clear()
			c.act(click[0], click[1])
			for text in c.writes:
				var run = JSON.parse_string(text)["run"]
				if run.get("pos") == id and run.get("sector") == sector and not run.has("reward"): legacy = text
		_check(legacy == "" and (c.page["kind"] == "end" if sector == 3 else c.RUN["sector"] == 2),
			"5: finishing sector %d never saves a paid boss with no onward route" % sector)
		if legacy == "":
			# Equivalent old window, built from the last real promotion checkpoint.
			for text in c.writes:
				var old: Dictionary = JSON.parse_string(text)
				if old["run"].get("pos") != id or old["run"].get("reward", {}).get("stage") != "promo": continue
				old["run"].erase("reward")
				legacy = JSON.stringify(old)
			assert(legacy != "")
		var d = _load(_legacy("boss_%d" % sector, legacy))
		var credits_once: float = d.SAVED_RUN["credits"]
		var cap_once: float = d.SAVED_RUN["cpCap"]
		d.act("continueRun")
		var advanced: bool = d.page["kind"] == "end" and d.SAVED_RUN == null if sector == 3 else d.RUN["sector"] == 2 and d.RUN["cpCap"] == cap_once + 3 and not d.availableNodes().is_empty()
		var settled: Dictionary = d.page["data"]["run"] if d.page["kind"] == "end" else d.RUN
		_check(advanced and settled["credits"] == credits_once and credits_once >= before_credits,
			"5 legacy: paid sector %d boss advances on Continue without paying again" % sector)

func _prize_reload() -> void:
	var c = _campaign()
	var id = c.availableNodes()[0]
	c.RUN["curNode"] = id
	c.RUN["pos"] = id
	var api = _external(c)
	c.battleScreen({"kind": "elite", "obj": "rout", "fac": "hegemony", "col": 1, "node": id,
		"seed": 1091, "map": "belt", "shape": "open", "enemies": [{"tpl": "h_picket"}, {"tpl": "h_picket"}]})
	var r = api.R
	var foes: Array = r.caps("enemy")
	foes[0]["side"] = "player"; foes[0]["captured"] = true
	foes[1]["hp"] = 0
	r.killUnit(foes[1], r.caps("player")[0])
	c.finish_battle(r.B["over"], r.B)
	c.act("prizeStep"); c.act("prizeSet", "0:ransom")
	c.writes.clear()
	c.act("prizeConfirm")
	var credits: float = c.RUN["credits"]
	var old: Dictionary = JSON.parse_string(c.writes[0])
	_check(old["run"]["reward"]["stage"] == "salvage", "7: the first paid-prize save already points to wreck salvage")
	var d = _load(c.writes[0])
	d.act("continueRun")
	_check(_salvage_then_reward(d, credits), "7: reloading a paid prize shows salvage and then the next reward, with one ransom")
	old["run"]["reward"]["stage"] = "prize"
	d = _load(_legacy("prize", JSON.stringify(old)))
	d.act("continueRun")
	_check(_salvage_then_reward(d, credits), "7 legacy: an empty prize stage still shows salvage and the next reward")

func _salvage_then_reward(c, credits: float) -> bool:
	if c.modal_d == null or c.modal_d["kind"] != "salvage" or c.RUN["credits"] != credits or c.RUN["ransoms"] != 1: return false
	c.act("takeSalvage", "0:cred")
	return c.modal_d != null and c.modal_d["kind"] in ["boon", "mod", "relic"] and c.RUN["credits"] > credits and c.RUN["ransoms"] == 1

func _yard_doctrine() -> void:
	var c = _campaign(2)
	var yard = c.availableNodes()[0]
	c.act("enterNode", yard)
	c.act("yardFleet")
	assert(c.page["kind"] == "fleet" and c.verbCanUse())
	c.act("factionVerb")
	var d = _load(c.save_text())
	d.act("continueRun")
	_check(d.page["kind"] == "shipyard" and d.page["data"]["node"]["id"] == yard and not d.verbCanUse(),
		"8: reloading after a yard doctrine purchase returns to the same yard")
	if c.page["kind"] == "fleet" and c.page["data"].get("back") == "shipyard": c.act("backShipyard")
	var still_in_yard: bool = c.page["kind"] == "shipyard" and not c.findNode(yard).get("done", false)
	if still_in_yard: c.act("leaveYard")
	_check(still_in_yard and c.page["kind"] == "map" and c.findNode(yard).get("done", false) and not c.verbCanUse(),
		"8: buying doctrine from the yard fleet leaves the same yard open until Leave")
	c = _campaign(2)
	c.act("fleetScreen"); c.act("factionVerb")
	if c.page["kind"] == "fleet" and c.page["data"].get("back") == "map": c.act("backMap")
	_check(c.page["kind"] == "map" and not c.verbCanUse(), "8: buying the same doctrine from the map fleet still returns to the map")

func _career_backup() -> void:
	var c := Career.new()
	c.persist = true
	c.save_path = scratch.path_join("career.json")
	c.award("first_blood")
	c.save_profile()
	c.award("lightning")
	c.save_profile()
	var backup := _legacy("career", FileAccess.get_file_as_string(c.save_path + ".bak"))
	assert(not backup.is_empty())
	_put(c.save_path + ".bak", backup)
	_put(c.save_path, '{"v":')
	assert(DirAccess.make_dir_absolute(c.save_path + ".tmp") == OK)
	for i in range(2):
		c.load_profile()
		c.award("last_stand")
		c.save_profile()
	var d := Career.new()
	d.save_path = c.save_path
	d.load_profile()
	_check(FileAccess.get_file_as_string(d.save_path + ".bak") == backup and d.P["medals"].has("first_blood") and not d.P["medals"].has("last_stand"),
		"9: a damaged Career primary and two blocked writes leave the last good copy readable")
