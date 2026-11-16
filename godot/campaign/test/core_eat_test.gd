# Issue 42 (R78 Q15): a Chorus run eats one core in sector 3. Headless:
#   godot --headless --path godot --script res://campaign/test/core_eat_test.gd
# Covers the offer, the growth, the lost protocols, refusing, the save round trip and other factions.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
var C
var fails := 0

func check(value, message: String) -> void:
	if not value: fails += 1; printerr("FAIL: " + message)

func start_run(admiral: String, fac: String) -> void:
	C.META = C.migrateMeta(C.defaultMeta()); C.newRun(admiral, fac)
	C.RUN["sector"] = 3; C.RUN["patrons"] = ["iron", "storm", "hunger", "rook"]; C.RUN["flags"] = {}; C.RUN["boons"] = []
	C.RUN["map"] = C.genSector(3)
	C.META["favour"] = {"iron": 0.0, "storm": 6.0, "hunger": 11.0, "star": 15.0, "rook": 0.0, "ember": 0.0}

func _initialize() -> void:
	C = CampaignScript.new(); var error = C.load_tables()
	if error != "": printerr(error); quit(1); return
	C.fixed_clock = true
	C.persist_on = false

	# the offer: title, one button per eligible core, refuse, and the Synced core left out
	start_run("matriarch", "chorus")
	check(C.coreEatDue(), "a Chorus run at sector 3 is offered the choice")
	check(C.showCoreEatOffer(), "the offer is shown")
	check(C.modal_d != null and C.modal_d["kind"] == "eatCore", "the eat screen opens")
	var acts = C.modal_d["acts"]; var cores = C.modal_d["data"]["cores"]
	check(cores.has("iron") and cores.has("hunger") and not cores.has("star"), "every core below Synced qualifies")
	check(acts.any(func(a): return a[0] == "refuseCoreEat"), "a Refuse button")
	for p in cores: check(acts.any(func(a): return a[0] == "eatCore" and a[1] == p), "a button for " + str(C.PATRONS[p]["n"]))
	start_run("matriarch", "chorus"); C.RUN["sector"] = 2
	check(not C.coreEatDue(), "sector 2 is not offered")
	start_run("matriarch", "chorus")
	for p in C.PATRONS.keys(): C.META["favour"][p] = 12.0
	check(not C.coreEatDue(), "no offer when every core is Synced")
	start_run("vex", "voidsworn")
	check(C.coreEatEligible().is_empty(), "another faction has no eligible cores")
	check(not C.coreEatDue() and not C.showCoreEatOffer(), "another faction is never offered")

	# eat: every Chorus ship grows, a non-Chorus ship does not, and new ships get the growth
	start_run("matriarch", "chorus")
	var ally = C.newShip("penitent"); ally["hp"] = C.derive(ally)["maxHp"]; C.RUN["fleet"].append(ally)
	var before = []
	for s in C.RUN["fleet"]: before.append({"uid": s["uid"], "tpl": s["tpl"], "hp": s["hp"], "max": C.derive(s)["maxHp"]})
	check(not C.applyEatCore("star"), "a Synced core cannot be eaten")
	check(C.applyEatCore("hunger"), "a core below Synced can be eaten")
	check(C.RUN["eatenCore"] == "hunger" and C.RUN["eatCoreSeen"] == true, "the choice is recorded")
	for old in before:
		var s = null
		for x in C.RUN["fleet"]:
			if x["uid"] == old["uid"]: s = x; break
		var now = C.derive(s)["maxHp"]
		if C.factionOfTpl(s["tpl"]) == "chorus":
			check(now > old["max"], "a Chorus ship gains max hull")
			check(float(s["hp"]) == float(min(now, float(old["hp"]) + (now - old["max"]))), "its current hull rises by the same amount")
		else:
			check(now == old["max"], "a non-Chorus ship keeps its max hull")
			check(float(s["hp"]) == float(old["hp"]), "a non-Chorus ship keeps its hull")
	var plain = 0.0
	start_run("matriarch", "chorus"); plain = C.derive(C.newShip("b_drone"))["maxHp"]
	start_run("matriarch", "chorus"); C.applyEatCore("hunger")
	check(C.derive(C.newShip("b_drone"))["maxHp"] > plain, "a ship built after the meal gets the growth")
	check(not C.applyEatCore("iron"), "the offer can only be taken once")
	check(not C.showCoreEatOffer(), "a taken offer never shows again")

	# protocols: the eaten core's boons and its duos are lost, other boons stay, and its pool is gone
	start_run("matriarch", "chorus")
	var iron = ""; var storm = ""; var iron_duo = ""; var other_duo = ""
	for id in C.BOONS.keys():
		var b = C.BOONS[id]
		if b.get("p") == "iron" and not C.jt(b.get("leg")) and iron == "": iron = id
		if b.get("p") == "storm" and not C.jt(b.get("leg")) and storm == "": storm = id
		if C.jt(b.get("duo")) and b["duo"].has("iron") and iron_duo == "": iron_duo = id
		if C.jt(b.get("duo")) and not b["duo"].has("iron") and other_duo == "": other_duo = id
	C.RUN["boons"] = [{"id": iron, "r": 0}, {"id": storm, "r": 0}, {"id": iron_duo, "r": 0}, {"id": other_duo, "r": 0}]
	check(C.applyEatCore("iron"), "eat a core that has protocols held")
	check(not C.hasBoon(iron) and not C.hasBoon(iron_duo), "its protocol and its duo are lost")
	check(C.hasBoon(storm) and C.hasBoon(other_duo), "other protocols stay")
	for o in C.rollBoonOffer("iron", 1):
		var b = C.BOONS[o["id"]]
		check(b.get("p") != "iron" and not (C.jt(b.get("duo")) and b["duo"].has("iron")), "the eaten core is never offered again")

	# refuse: nothing changes, the offer is marked seen
	start_run("matriarch", "chorus")
	var refused = []
	for s in C.RUN["fleet"]: refused.append({"uid": s["uid"], "hp": s["hp"], "max": C.derive(s)["maxHp"]})
	check(C.showCoreEatOffer(), "the offer is shown before refusing")
	check(C.refuseCoreEat(), "refusing is accepted")
	check(C.RUN["eatenCore"] == null and C.RUN["eatCoreSeen"] == true, "refusing marks the offer seen and eats nothing")
	for old in refused:
		var s = null
		for x in C.RUN["fleet"]:
			if x["uid"] == old["uid"]: s = x; break
		check(C.derive(s)["maxHp"] == old["max"] and float(s["hp"]) == float(old["hp"]), "refusing changes no hull")
	check(not C.coreEatDue(), "a refused offer never shows again")

	# save round trip, and an older save that lacks the fields
	start_run("matriarch", "chorus")
	check(C.applyEatCore("hunger"), "eat before saving")
	C.saveRun()
	var saved = C.clone(C.SAVED_RUN)
	C.RUN = C.migrateRun(C.clone(saved))
	check(C.RUN["eatenCore"] == "hunger" and C.RUN["eatCoreSeen"] == true, "the choice survives save and load")
	var reloaded = C.RUN["fleet"].filter(func(s): return C.factionOfTpl(s["tpl"]) == "chorus")[0]
	check(C.derive(reloaded)["maxHp"] > float(C.HULLS[reloaded["tpl"]]["hp"]), "the grown hull survives the reload")
	check(not C.coreEatDue(), "the save does not offer it a second time")
	var old = C.clone(C.RUN); old.erase("eatenCore"); old.erase("eatCoreSeen")
	C.RUN = C.migrateRun(old)
	check(C.RUN["eatenCore"] == null and C.RUN["eatCoreSeen"] == false, "an older save loads as not yet offered")

	print("core eat: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
