extends SceneTree

# Run from the repo root with Godot on PATH:
# godot --headless --path godot --script ../contrib/openai/audit_1118/tests/rules_campaign_ui/handoff_regressions.gd
const Campaign = preload("res://campaign/campaign.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var failures := 0


func _initialize() -> void:
	var api = BattleAPI.new()
	var c = Campaign.new()
	var restored = Campaign.new()
	if api.load_rules() != "" or c.load_tables() != "" or restored.load_tables() != "":
		printerr("ERROR: could not load the real game tables")
		quit(2)
		return
	_story_checkpoint(c, restored, api)
	_breakthrough(c, api)
	_hegemony_event(c, api)
	_backup_without_primary(c, restored)
	_prize_then_reload(c, restored, api)
	_doctrine_at_yard(c)
	quit(1 if failures != 0 else 0)


func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1


func _run(c) -> void:
	BattleAPI.JSM.rnd_seed(1091)
	c.fixed_clock = true
	c.newRun("vex", "voidsworn")
	c.mapScreen()


func _external(c, api) -> void:
	c.battle_mode = "external"
	c.battle_setup = func(run, cfg):
		api.new_battle(run, cfg)
		return api.R.B


func _story_checkpoint(c, restored, api) -> void:
	_run(c)
	c.RUN["sector"] = 3
	c.RUN["map"] = c.genSector(3)
	c.mapScreen()
	c.showBeat3()
	c.act("eventChoice", "0") # Sunward flagship power
	c.act("closeModal")
	c.act("enterNode", c.availableNodes()[0]) # Sector III starts at a shipyard.
	c.act("leaveYard")
	var next = c.availableNodes().filter(func(id): return c.findNode(id)["type"] == "battle")[0]
	_external(c, api)
	c.act("enterNode", next)
	if c.page["kind"] != "battle" or not c.B["cfg"].get("storyMods", {}).get("power", false):
		printerr("ERROR: story battle fixture did not start with the earned modifier")
		quit(2)
		return
	restored.load_save_text(c.save_text())
	restored.act("continueRun")
	var n = restored.findNode(next)
	var reopened = restored.B != null and restored.B.get("cfg", {}).get("node") == next and restored.B.get("cfg", {}).get("storyMods", {}).get("power", false)
	var pending = restored.RUN.get("storyNext")
	var can_retry = restored.availableNodes().has(next) and not n.get("done", false) and pending is Dictionary and pending.get("power", false)
	var resume_same_fight: bool = reopened or can_retry
	_check(resume_same_fight, "unfinished story fight remains playable with its reward after reload (page=%s, node_done=%s, node_reachable=%s)" % [restored.page["kind"], n.get("done", false), restored.availableNodes().has(next)])


func _breakthrough(c, api) -> void:
	_run(c)
	while c.RUN["fleet"].size() < 3: c.RUN["fleet"].append(c.newShip("warden"))
	var next = c.availableNodes()[0]
	c.RUN["curNode"] = next
	c.RUN["pos"] = next
	api.new_battle(c.RUN, {"kind": "battle", "obj": "break", "fac": "hegemony", "col": 1, "seed": 1091, "map": "belt", "shape": "open", "campaign": true})
	var r = api.R
	var ships: Array = r.caps("player")
	var escaped = ships[0]
	var hex = r.boardHexes().filter(func(h): return r.objZone(h.q, h.r) == "exit")[0]
	escaped["q"] = hex.q; escaped["r"] = hex.r
	r.objAfterMove(escaped)
	for ship in ships.slice(1):
		ship["dead"] = true
		ship["hp"] = 0
	r.checkEnd()
	if r.B.get("over") != "loss" or not r.B.get("withdraw", false) or r.survivorsP() != 1:
		printerr("ERROR: breakthrough fixture did not produce a withdrawal with one survivor")
		quit(2)
		return
	c.finish_battle("loss", r.B)
	_check(c.page["kind"] == "map" and c.RUN != null and c.RUN["fleet"].size() == 1, "failed breakthrough returns the ship that already jumped clear (page=%s)" % c.page["kind"])


func _hegemony_event(c, api) -> void:
	_run(c)
	var nem = c.newNemesis("hegemony")
	c.RUN["nem"] = nem
	c.RUN["nemAssign"][0] = "hegemony"
	c.RUN["nems"]["hegemony"] = nem
	var cfg = {"kind": "elite", "obj": "rout", "fac": "hegemony", "col": 1, "seed": 1091, "map": "belt", "shape": "open", "nemesis": c.nemBattleCfg()}
	_external(c, api)
	c.battleScreen(cfg)
	var event = api.R.B.get("event")
	_check(event is Dictionary and event.get("k") == "reinf_enemy" and event.get("r") == 3, "Hegemony Nemesis always calls enemy reinforcements in round 3 (event=%s)" % str(event))


func _backup_without_primary(c, restored) -> void:
	_run(c)
	c.META["renown"] = 41
	var backup: String = c.save_text()
	restored.META = restored.defaultMeta()
	restored.SAVED_RUN = null
	restored.load_save_text("", backup)
	_check(restored.SAVED_RUN != null and restored.META.get("renown") == 41, "an empty or missing primary save recovers the backup run and profile (renown=%s)" % restored.META.get("renown"))


func _prize_then_reload(c, restored, api) -> void:
	_run(c)
	var next = c.availableNodes()[0]
	c.RUN["curNode"] = next
	c.RUN["pos"] = next
	_external(c, api)
	c.battleScreen({"kind": "elite", "obj": "rout", "fac": "hegemony", "col": 1, "node": next,
		"seed": 1091, "map": "belt", "shape": "open", "enemies": [{"tpl": "h_picket"}, {"tpl": "h_picket"}]})
	var r = api.R
	var foes: Array = r.caps("enemy")
	# One captured escort and one wreck; use the real rules result and reward flow.
	foes[0]["side"] = "player"
	foes[0]["captured"] = true
	foes[1]["hp"] = 0
	r.killUnit(foes[1], r.caps("player")[0])
	c.finish_battle(r.B["over"], r.B)
	c.act("prizeStep")
	if c.modal_d == null or c.modal_d["kind"] != "prize":
		printerr("ERROR: prize fixture did not create a prize")
		quit(2)
		return
	c.act("prizeSet", "0:ransom")
	c.act("prizeConfirm")
	if c.modal_d == null or c.modal_d["kind"] != "salvage":
		printerr("ERROR: prize fixture did not reach salvage")
		quit(2)
		return
	restored.load_save_text(c.save_text())
	restored.act("continueRun")
	var kind: String = restored.modal_d.get("kind", "") if restored.modal_d != null else "none"
	_check(kind == "salvage" and restored.RUN["credits"] == c.RUN["credits"], "reopening during salvage resumes salvage after the paid prize (modal=%s)" % kind)


func _doctrine_at_yard(c) -> void:
	_run(c)
	c.RUN["sector"] = 2
	c.RUN["map"] = c.genSector(2)
	c.mapScreen()
	var yard = c.availableNodes()[0]
	c.act("enterNode", yard)
	c.act("yardFleet")
	if c.page["kind"] != "fleet" or c.page["data"].get("back") != "shipyard" or not c.verbCanUse():
		printerr("ERROR: doctrine fixture did not reach the yard fleet with a payable action")
		quit(2)
		return
	c.act("factionVerb")
	_check(c.page["kind"] == "shipyard" or (c.page["kind"] == "fleet" and c.page["data"].get("back") == "shipyard"),
		"using doctrine from the yard fleet keeps a way back to the yard (page=%s)" % c.page["kind"])
