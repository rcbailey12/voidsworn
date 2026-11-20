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
	check(C.capturedHullPrice(mote) == warden["val"], "the mote sells at the Crusade 1 CP frigate ladder price (issue 1354: the Crusade shop discount is not applied to captured hulls)")
	check(mote["cost"] > warden["cost"], "the table price really carries the Eclipse premium, so the check means something")
	check(C.capturedHullPrice(picket) == picket["val"], "a captured picket sells at its baseline, Hegemony is the 1.0 ladder (before the issue 1354 Navy shop discount)")

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

	# the prize screen: before run 3 the Crusade cannot keep a Hegemony or Eclipse prize (strip and ransom only)
	start_run("voidsworn", 1)
	C.RUN["cpCap"] = 10.0; C.RUN["fleet"] = []
	var early = {"tpl": "h_picket", "name": "HNS Early", "cp": 1, "hpf": 0.7, "wk": ["laser"], "ab": null, "regen": 0, "sh": 10}
	var rows = C.prizePlan({"prizes": [early], "prizeSel": null})
	check(not rows[0]["room"] and rows[0]["cinder"] and rows[0]["rip"] and rows[0]["k"] != "add", "before run 3 the Add choice is not offered for a Hegemony prize")
	check(float(rows[0]["o"]["ransom"]) > 0 and float(rows[0]["o"]["strip"]["cred"]) > 0, "strip and ransom are still on offer before run 3")
	rows = C.prizePlan({"prizes": [early], "prizeSel": ["add"]})
	check(rows[0]["k"] != "add", "a saved Add pick falls back to strip or ransom before run 3")

	# from run 3 the Add path is back, and a kept Hegemony or Eclipse prize joins with its links ripped out
	start_run("voidsworn", 2)
	C.RUN["cpCap"] = 10.0; C.RUN["fleet"] = []
	var keep = {"tpl": "h_interdictor", "name": "HNS Kept", "cp": 2, "hpf": 0.6, "wk": ["battery"], "ab": null, "regen": 0, "sh": 12}
	C.W["rw"] = {}
	C.RUN["reward"] = {"kind": "elite", "stage": "prize", "prizes": [keep], "prizeSel": ["add"], "wrecks": []}
	rows = C.prizePlan(C.RUN["reward"])
	check(rows[0]["room"] and not rows[0]["cinder"] and rows[0]["rip"], "from run 3 the Add choice is offered again for a Hegemony prize")
	C.ACT_prizeConfirm()
	var kept = null
	for shp in C.RUN["fleet"]:
		if shp["tpl"] == "h_interdictor": kept = shp
	check(kept != null and C.jt(kept.get("ripped")) and str(kept["name"]) == "HNS Kept", "the kept Hegemony prize joins with its links ripped out")
	var keep2 = {"tpl": "c_raider", "name": "RVD Plain", "cp": 1, "hpf": 0.7, "wk": ["autocannon"], "ab": null, "regen": 0, "sh": 8}
	C.RUN["reward"] = {"kind": "elite", "stage": "prize", "prizes": [keep2], "prizeSel": ["add"], "wrecks": []}
	rows = C.prizePlan(C.RUN["reward"])
	check(not rows[0]["cinder"] and not rows[0]["rip"], "only Hegemony and Eclipse prizes carry the rip")
	C.ACT_prizeConfirm()
	var kept2 = null
	for shp2 in C.RUN["fleet"]:
		if shp2["tpl"] == "c_raider": kept2 = shp2
	check(kept2 != null and not C.jt(kept2.get("ripped")), "a Corsair prize is kept without ripping")

	# the captured yard draw waits for the class unlocks like normal stock
	start_run("voidsworn", 2)
	C.META["unlocked"] = {}
	var pool = C.cinderPool()
	check(not pool.has("h_dominion"), "the captured battleship waits for u_battleship")
	check(pool.has("h_picket") and pool.has("d_scythe"), "frigates are always in the captured draw")
	C.META["unlocked"]["u_battleship"] = true
	pool = C.cinderPool()
	check(pool.has("h_dominion"), "u_battleship puts the captured battleship in the draw")
	var st2 = C.shipyardStock({"id": "y6", "type": "shipyard"})
	check(st2["cap"].size() == 2 and st2["cap"].all(func(h): return pool.has(h)), "the yard stock draws from the unlocked pool")

	# a save and load round trip of a ripped hull
	start_run("voidsworn", 2)
	C.RUN["credits"] = 1000.0
	C.shipyardScreen({"id": "y7", "type": "shipyard", "stock": {"hulls": [], "mods": [], "sold": [], "cap": ["d_scythe"]}})
	C.ACT_buyHull("d_scythe")
	C.saveRun()
	var saved = C.clone(C.SAVED_RUN)
	C.RUN = C.migrateRun(C.clone(saved))
	var back = null
	for shp3 in C.RUN["fleet"]:
		if shp3["tpl"] == "d_scythe": back = shp3
	check(back != null and C.jt(back.get("ripped")), "the ripped flag survives save and load")

	print("cinder prizes: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails > 0 else 0)
