extends SceneTree

const Campaign := preload("res://campaign/campaign.gd")
const UI := preload("res://ui/campaign/campaign_ui.gd")
const API := preload("res://rules/battle_api.gd")
const Battle := preload("res://scenes/battle/battle.gd")
const HUD := preload("res://ui/battle/hud.gd")
const View := preload("res://campaign/campaign_view.gd")

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var c := Campaign.new()
	var error := c.load_tables()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	c.fixed_clock = true
	_reinforcements(c)
	var ui := UI.new()
	root.add_child(ui)
	ui.C = c
	_mastery(c, ui)
	_nemesis(c, ui)
	_selection(c, ui)
	_repairs_and_joins(c, ui)
	_battle_tips(c)
	ui.free()
	quit(0 if failures == 0 else 1)


func _reinforcements(c: Campaign) -> void:
	var starters := {"voidsworn": "warden", "corsair": "c_raider", "ithar": "i_wisp",
		"deathless": "d_scythe", "chorus": "b_drone", "hegemony": "h_picket"}
	for fac in starters:
		_new_run(c, fac)
		c.RUN["fleet"].resize(1)
		c.RUN.erase("reinf")
		c.saveRun()
		c.load_save_text(c.save_text())
		c.act("continueRun")
		var cfg := {"kind": "battle", "fac": c.RUN["map"]["fac"], "seed": 1151}
		c.battleScreen(cfg)
		var fleet: Array = c.RUN["fleet"]
		_check(fleet.size() == 2 and fleet[1]["tpl"] == starters[fac] and c.B["units"][1]["tpl"] == starters[fac],
			fac + ": the right starter joins a one-ship fleet after loading")
		# Reopen a checkpoint that already received the sector's ship. Old Warden
		# grants are saved fleet entries and must neither change nor be given twice.
		c.RUN["fleet"] = [c.newShip("warden")]
		c.ensureFlagship()
		c.saveRun()
		c.load_save_text(c.save_text())
		c.act("continueRun")
		c.battleScreen(cfg)
		fleet = c.RUN["fleet"]
		_check(fleet.size() == 1 and fleet[0]["tpl"] == "warden" and c.RUN.get("reinf") == 1,
			fac + ": an existing Warden and the used sector grant survive reload")


func _mastery(c: Campaign, ui: UI) -> void:
	c.META["mastery"]["vaelen"] = 440.0
	c.META["lineage"] = {"vaelen": {"picks": ["A:0:0", "B:0:0", "C:0:0"], "capstone": 0, "respecs": 0}}
	var panel := ui._capstone_mastery("vaelen")
	var text := _text(panel)
	_check("Placeholder:" not in text and "Mastery I (earned)" in text and "600 XP" in text,
		"mastery hides unfinished descriptions and keeps the earned tiers and XP")
	panel.free()
	var perk: Dictionary = c.CAPSTONE_MASTERY_PERKS[0]
	var old = perk["d"]
	perk["d"] = "Authored description for this fixture."
	panel = ui._capstone_mastery("vaelen")
	_check("Authored description for this fixture." in _text(panel), "mastery shows real descriptions when present")
	panel.free()
	perk["d"] = old


func _nemesis(c: Campaign, ui: UI) -> void:
	for fixture in [[1, ["corsair", "hegemony", "corsair"], true, "third-sector return"],
			[1, ["corsair", "hegemony", "ithar"], false, "no return"],
			[2, ["hegemony", "corsair", "ithar"], false, "last sector, different hunter"],
			[1, ["corsair", null, null], true, "legacy assignment carries forward"]]:
		_new_run(c, "voidsworn")
		c.RUN.merge({"sector": fixture[0], "nemAssign": fixture[1],
			"nems": {"corsair": c.newNemesis("corsair")}, "nem": null}, true)
		var outgoing: Dictionary = c.nemActive()
		outgoing["met"] = fixture[0]
		outgoing["seen"] = {"ion": 10}
		c._advance_sector()
		ui._modal(c.modal_d)
		var text := _text(ui.modal_box)
		_check(("ADAPTED TO YOU" in text) == fixture[2] and outgoing["adapt"].has("shields"),
			"Nemesis " + fixture[3] + ": banner follows the remaining assignments; adaptation still happens")
		for child in ui.modal_box.get_children(): child.free()
	_new_run(c, "voidsworn")
	var n: Dictionary = c.nemActive()
	n["weak"] = ["slow"]; n["revealed"] = []; n["traits"] = ["zeal"]
	for pair in [["f", "her"], ["n", "it"], ["m", "him"]]:
		n["g"] = pair[0]
		var lines := str(View.nem_dossier(c))
		_check("win against %s to learn it" % pair[1] in lines and "Close assault" in lines, "Dossier renders the current Nemesis pronouns and trait name: " + pair[0])


func _selection(c: Campaign, ui: UI) -> void:
	var expected := {"voidsworn": ["Side guns", "Brace covers", "10% premium"], "hegemony": ["sync", "back away", "Lose the command ship"],
		"corsair": ["Boarding crews", "rocket pods", "cannot field lance"], "chorus": ["each round", "ship kills", "no shields"],
		"ithar": ["Shields refill", "after firing", "cannot Brace"], "deathless": ["reassembles next round", "Fold drives", "no shields"]}
	for fac in c.RUN_FACTIONS:
		c.picked_faction = fac; c.picked_admiral = "anuket" if fac == "deathless" else ""
		c.admiralScreen()
		ui._acts = c.page["acts"]
		var panel: Control = ui._desk()   # issue 1217: the faction and admiral desk
		var txt := _text(panel)
		_check(expected[fac].all(func(s): return s in txt) and "sets your ships and shipyards" not in txt,
			fac + ": selection shows two live mechanics and their tradeoff")
		if fac == "deathless":
			_check("Every ship deals +30% damage" in txt and "Any ships carrying torpedoes" in txt,
				"Ostrel's selection text describes fleet damage and conditional reload")
		panel.free()


func _repairs_and_joins(c: Campaign, ui: UI) -> void:
	_new_run(c, "deathless")
	c.RUN["heat"] = ["h_coffers"]
	c.RUN["credits"] = 1000
	c.RUN["map"]["cond"] = null
	c.RUN["cpCap"] = 30
	var ship: Dictionary = c.RUN["fleet"][0]
	ship["hp"] = c.derive(ship)["maxHp"] - 10
	var yard := {"id": "truth-yard", "type": "shipyard", "stock": {"hulls": ["d_scythe"], "mods": [], "sold": []}}
	c.shipyardScreen(yard)
	ui._acts = c.page["acts"]
	var panel: Control = ui._shipyard()
	_check("Repairs cost 1.25 credits per 2 hull, rounded up" in _text(panel) and ui._yard_bar.text == "Repair entire fleet for 7",
		"Lean coffers changes both the shipyard rate and the quoted repair bill")
	panel.free()
	c.act("repairAll")
	_check(c.RUN["credits"] == 993, "the displayed repair bill is the price paid")
	# Restrict the name pool to exercise the actual shop, event and prize messages without relying on a name draw.
	var names: Array = c.FNAMES["deathless"]; var more: Array = c.MORE_SHIP_NAMES["deathless"]
	c.FNAMES["deathless"] = ["The Unbroken"]; c.MORE_SHIP_NAMES["deathless"] = []
	for s in c.RUN["fleet"]: s["name"] = "Ship " + str(s["uid"])
	c.act("buyHull", "d_scythe")
	_check("The Unbroken joins the fleet." in c.toasts, "a purchased ship with The in its name joins with one article")
	c.RUN["fleet"].pop_back()
	var lines: Array = c.applyOutcome({"shipRaw": "d_scythe"})
	_check(lines.any(func(l): return l.begins_with("The Unbroken joins the fleet under ")), "an event ship joins with one article")
	c.RUN["fleet"].pop_back()
	c.FNAMES["deathless"] = names; c.MORE_SHIP_NAMES["deathless"] = more
	c.RUN["reward"] = {"kind": "elite", "prizes": [{"tpl": "d_scythe", "name": "The Unbroken", "cp": 1, "hpf": 1}], "prizeSel": ["add"], "wrecks": [], "stage": "prize", "modOffer": null}
	c.W["rw"] = {"k": "mod"}
	c.ACT_prizeConfirm()
	_check("The Unbroken joins." in c.toasts, "a prize ship joins with one article")


func _battle_tips(c: Campaign) -> void:
	_new_run(c, "deathless")
	c.RUN["admiral"] = "anuket"
	c.RUN["heat"] = ["h_cmd"]
	c.RUN["fleet"].append(c.newShip("harrow"))
	var api := API.new(); api.load_rules()
	api.new_battle(c.RUN, {"kind": "battle", "fac": "hegemony", "seed": 1147, "enemies": [{"tpl": "h_picket"}]})
	var torps: Array = []
	for u in api.R.alive("player"):
		for w in u["weapons"]:
			if w["k"] == "torp": torps.append(w)
	_check(not torps.is_empty() and api.R.alive("player").filter(func(u): return u["tpl"] != "harrow").all(
		func(u): return u["weapons"].all(func(w): return w["k"] != "torp")), "Ostrel's torpedoes come from the captured hull, not native Eclipse ships")
	_check(api.command_info()["next"] == "", "Slow orders correctly predicts no power increase from Round 1 to Round 2")
	c.RUN["heat"] = []
	var data := api.command_info()
	var h := HUD.new(); root.add_child(h)
	h.set_command(data.label, true, true, false, Battle._command_tip(data))
	# This exercises the real hover hit region, not just the formatter.
	h.ledger.layout()
	h.ledger._orders(20, 10, 440, 190, {}, false)
	_check(h.ledger.hits.any(func(x): return x["act"] == "command" and "+30% damage" in x["tip"] and "Wait one round for power 2" in x["tip"] and "+45% damage" in x["tip"]),
		"the Command hover shows the present effect and the next round's stronger effect before use")
	for w in torps: w["fired"] = true; w["cdLeft"] = 2
	_check(api.command() and torps.all(func(w): return not w["fired"] and w["cdLeft"] == 0), "Ostrel reloads the captured ship's torpedoes")
	_check("Slip the Net" in h.ledger.keyword_tip("Fired") and "Glasswright" in h.ledger.keyword_tip("Fired"), "Fired tooltip names the two movement exceptions")
	h.free()
	var b := Battle.new(); b.TBL = api.R.TB
	_check("most damaged adjacent ally facing the same way" in b._brace_tip({"fac": "voidsworn"})
		and "adjacent ally" not in b._brace_tip({"fac": "hegemony"}) and "cannot Brace" in b._brace_tip({"fac": "ithar"}),
		"Brace text follows hull faction and only promises Sunward cover where it applies")
	_check(b._class_label("Tomb-ark") == "Archive-ship" and b._class_label("Bio-titan") == "Colossus" and b._class_label("Battle-barge") == "War-barge",
		"battle display class names use the existing alias table")
	b.free()


func _new_run(c: Campaign, fac: String) -> void:
	API.JSM.rnd_seed(1144)
	c.META = c.defaultMeta()
	for id in c.ADMIRALS:
		if c.ADMIRALS[id]["fac"] == fac:
			c.newRun(id, fac)
			return


func _text(node: Node) -> String:
	var text := ""
	if node is Label or node is RichTextLabel: text = node.text + "\n"
	if node is Control and (node as Control).tooltip_text != "": text += (node as Control).tooltip_text + "\n"   # moved to hover still counts (R177)
	for child in node.get_children(): text += _text(child)
	return text


func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
