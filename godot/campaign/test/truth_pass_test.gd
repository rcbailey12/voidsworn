extends SceneTree

const Campaign := preload("res://campaign/campaign.gd")
const UI := preload("res://ui/campaign/campaign_ui.gd")
const API := preload("res://rules/battle_api.gd")

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
	for child in node.get_children(): text += _text(child)
	return text


func _check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
