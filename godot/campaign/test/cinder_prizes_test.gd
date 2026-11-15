# Issue 41 (R78 Q9): from run 3 the Crusade keeps captured Hegemony and Eclipse hulls, links ripped out, at Crusade
# prices, via the Cinder Line yards. Headless:
#   godot --headless --path godot --script res://campaign/test/cinder_prizes_test.gd
# Covers the run gate, the yard stock, the Crusade price, the ripped buy, and the ripped battle rules on both nets.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const RulesScript = preload("res://rules/rules.gd")
var C
var R
var fails := 0

func check(value, message: String) -> void:
	if not value: fails += 1; printerr("FAIL: " + message)

func start_run(fac: String, prior_runs: float) -> void:
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["stats"]["runs"] = prior_runs
	C.newRun("vex", fac)
	C.RUN["map"]["cond"] = null   # the price checks want the plain 1.0 price multiplier

func battle_with(fleet: Array) -> void:
	R.RUN = {"sector": 1, "fleet": fleet, "map": {"biome": "", "cond": null}, "admiral": "vex", "flagUid": null,
		"aspect": null, "boons": [], "relics": [], "heat": [], "lineage": null, "mastery": 0, "nem": null}
	R.startBattle({"kind": "battle", "fac": "corsair", "col": 3, "enemies": [{"tpl": "c_raider"}], "seed": 11})

func _initialize() -> void:
	C = CampaignScript.new(); var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true; C.persist_on = false
	R = RulesScript.new(); err = R.load_tables("res://rules/data/tables.json")
	if err != "": printerr(err); quit(1); return

	# the run gate: closed before run 3, closed for other factions, open for the Crusade from run 3
	start_run("voidsworn", 1)   # newRun pushes it to 2
	check(not C.cinderOpen(), "run 2 is too early")
	check(C.shipyardStock({"id": "y1", "type": "shipyard"})["cap"].is_empty(), "no captured stock at run 2")
	start_run("hegemony", 4)
	check(not C.cinderOpen(), "the Hegemony never gets Cinder Line stock")
	start_run("voidsworn", 2)   # newRun pushes it to 3
	check(C.cinderOpen(), "run 3 opens the Cinder Line stock")
	var st = C.shipyardStock({"id": "y3", "type": "shipyard"})
	check(st["cap"].size() == 2 and st["cap"].all(func(h): return C.CINDER_PRIZES.has(h)), "a Crusade yard stocks two captured Hegemony or Eclipse hulls")

	# Crusade prices: a captured Eclipse mote costs what a Warden costs, not what Eclipse pays for it
	var warden = C.HULLS["warden"]; var mote = C.HULLS["d_scythe"]; var picket = C.HULLS["h_picket"]
	check(C.capturedHullPrice(mote) == warden["cost"], "the mote sells at the Crusade 1 CP frigate price")
	check(mote["cost"] > warden["cost"], "the table price really carries the Eclipse premium, so the check means something")
	check(C.capturedHullPrice(picket) == picket["cost"], "a captured picket sells at its baseline, Hegemony is the 1.0 ladder")

	# buying: charged the captured price, links ripped out, normal hulls unaffected
	C.RUN["credits"] = 1000.0
	C.shipyardScreen({"id": "y4", "type": "shipyard", "stock": {"hulls": ["warden"], "mods": [], "sold": [], "cap": ["d_scythe"]}})
	C.ACT_buyHull("d_scythe")
	var s = C.RUN["fleet"][C.RUN["fleet"].size() - 1]
	check(s["tpl"] == "d_scythe" and C.jt(s.get("ripped")), "the bought mote joins with its links ripped out")
	check(C.RUN["credits"] == 1000.0 - C.capturedHullPrice(mote), "the captured price was charged")
	C.ACT_buyHull("warden")
	var w = C.RUN["fleet"][C.RUN["fleet"].size() - 1]
	check(w["tpl"] == "warden" and not C.jt(w.get("ripped")), "an ordinary hull is not ripped")

	# battle rules: a ripped Hegemony hull is no part of the synchronized fire net
	var ripped_h = C.newShip("h_interdictor"); ripped_h["ripped"] = true
	var plain_h = C.newShip("h_interdictor")
	battle_with([ripped_h, plain_h])
	var units = R.B["units"].filter(func(u): return u["side"] == "player")
	var ru = units.filter(func(u): return C.jt(u.get("ripped")))[0]
	var pu = units.filter(func(u): return not C.jt(u.get("ripped")))[0]
	check(R.syncAnchor("player") == pu, "the plain hull anchors, the ripped one is no anchor candidate")
	ru["q"] = pu["q"]; ru["r"] = pu["r"]
	check(not R.inSync(ru), "even parked on the anchor, a ripped hull is out of sync")
	battle_with([C.clone(ripped_h)])
	check(R.syncAnchor("player") == null, "a lone ripped hull gives the fleet no anchor at all")

	# battle rules: a ripped Eclipse hull neither restores nor feeds the Archive count
	var ripped_d = C.newShip("d_scythe"); ripped_d["ripped"] = true
	battle_with([ripped_d])
	var du = R.B["units"].filter(func(u): return u["side"] == "player")[0]
	check(R.B["legion"]["player"]["max"] == 0, "ripped hulls do not count toward Archive restores")
	check(not R.legionCan(du), "a ripped hull cannot rise again")
	battle_with([C.newShip("d_scythe")])
	check(R.B["legion"]["player"]["max"] == 1, "an ordinary captured mote would still count")

	print("cinder prizes: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails > 0 else 0)
