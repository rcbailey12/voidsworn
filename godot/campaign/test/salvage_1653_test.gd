# Issue 1653 (Parts B and C of build variety 1453): the twelve new salvage relics and four new refits are only offered where
# they can act, every new id has its data and card text, and ledger2 raises the Command cap. The battle effects are checked in
# res://rules/test/rules_1653_test.gd.
#   godot --headless --path godot --script res://campaign/test/salvage_1653_test.gd
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
var C
var fails := 0
const NEW_RELICS = ["gunnery", "afterburn", "flankmark", "spotter", "lastlight", "coolant", "spare", "ledger2", "ram", "mirror", "beacon", "quiet"]
const NEW_MODS = ["locker", "chaser", "spill", "relay"]

func check(value, message: String) -> void:
	if not value: fails += 1; printerr("FAIL: " + message)

func admiral_for(fac: String) -> String:
	for k in C.ADMIRALS:
		if C.or_(C.ADMIRALS[k].get("fac"), "voidsworn") == fac: return k
	return "vex"

func start(fac: String) -> void:
	C.META = C.migrateMeta(C.defaultMeta())
	C.newRun(admiral_for(fac), fac)

func ship(tpl: String) -> Dictionary:
	return {"tpl": tpl, "mods": [], "uid": "t_" + tpl}

func _initialize() -> void:
	C = CampaignScript.new(); var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true; C.persist_on = false

	# every new id has its data and its card text
	for r in NEW_RELICS:
		check(C.RELICS.has(r), "relic %s has data" % r)
		if not C.RELICS.has(r): continue
		check(str(C.RELICS[r].get("n", "")) != "" and str(C.RELICS[r].get("d", "")) != "" and str(C.RELICS[r].get("fl", "")) != "", "relic %s has name, text and flavour" % r)
		check(C.relicText(r).contains("\n"), "relic %s card shows its flavour line" % r)
	for m in NEW_MODS:
		check(C.MODULES.has(m) and C.MOD_NEED.has(m), "refit %s has data and a fit rule" % m)

	# refit gates, over every hull in the game
	var relay_n := 0; var spill_n := 0; var chaser_n := 0; var locker_n := 0
	for tpl in C.HULLS:
		var t = C.HULLS[tpl]
		if int(C.z0(t.get("slots"))) <= 0: continue
		var fac = str(t.get("fac", ""))
		var s = ship(tpl)
		if C.canFitModule(s, "relay"):
			relay_n += 1; check(fac != "ithar", "relay never fits a Glasswright hull (%s)" % tpl)
		if C.canFitModule(s, "spill"):
			spill_n += 1; check(fac != "chorus" and fac != "deathless", "spill never fits a shieldless Chorus or Eclipse hull (%s)" % tpl)
			check(float(C.z0(t.get("sh"))) > 0, "spill only on shielded hulls (%s)" % tpl)
		if C.canFitModule(s, "chaser"): chaser_n += 1
		if C.canFitModule(s, "locker"): locker_n += 1
	check(relay_n > 0 and spill_n > 0 and chaser_n > 0 and locker_n > 0, "each refit fits some hull: relay %d, spill %d, chaser %d, locker %d" % [relay_n, spill_n, chaser_n, locker_n])

	# relic offer gates
	start("ithar")
	check(not C.relicUseful("ram") or C.RUN["fleet"].any(func(x): return C.HULLS[x["tpl"]].get("ab") == "overburn"), "no ram charter for a Glasswright fleet that cannot ram")
	start("voidsworn")
	C.RUN["fleet"] = [C.RUN["fleet"][0]]
	check(not C.relicUseful("lastlight"), "no last light for a one ship fleet")
	var launch_tpl := ""; var plain_tpl := ""
	for tpl in C.HULLS:
		var ab = C.HULLS[tpl].get("ab")
		if ab == "launch" and launch_tpl == "": launch_tpl = tpl
		if not C.jt(ab) and plain_tpl == "": plain_tpl = tpl
	C.RUN["fleet"] = [ship(launch_tpl)]
	check(not C.relicUseful("coolant"), "no coolant for a fleet whose only ability is launching wings")
	check(C.relicUseful("spotter"), "spotter offered to a carrier fleet")
	C.RUN["fleet"] = [ship(plain_tpl), ship(plain_tpl)]
	check(not C.relicUseful("spotter"), "no spotter without a carrier")
	check(C.relicUseful("lastlight"), "last light offered to a two ship fleet")

	# ledger2 raises the Command cap by one
	start("voidsworn")
	var cap0 = float(C.RUN["cpCap"]); C.addRelic("ledger2")
	check(float(C.RUN["cpCap"]) == cap0 + 1 and C.RUN["relics"].has("ledger2"), "ledger2 gives +1 Command cap")
	check(C.TB["LATE_SHOP"]["skip"].has("ledger2"), "ledger2 stays out of the late shop")

	print("salvage_1653: %s" % ("PASS" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)
