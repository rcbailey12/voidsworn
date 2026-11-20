# Issue 1384: the real bugs from Neon's late campaign review (PR 1380), the Godot twin of
# contrib/opus/tools/late_campaign_1384_tests.js. Checks that selling the flagship hands the flagship on at once, that a ship
# regrown from an Eclipse core never decommissions for more than its regrow cost, that the Daybreak dreadnought carries the
# Crusade shop discount, that a captured hull costs what the matching Crusade hull costs, and that an eaten Chorus core is
# remapped to another patron in the Sector 3 beat and in boonStep, as campaign_run.js does. Headless:
#   godot --headless --path godot --script res://campaign/test/late_fixes_1384.gd
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM

var C = Campaign.new()
var fails := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, what: String) -> void:
	if ok: print("ok    " + what)
	else:
		fails += 1; printerr("FAIL  " + what)

func _start(admiral: String, fac: String, seed_: int) -> void:
	JSM.rnd_seed(seed_)
	C.META["admirals"][admiral] = true
	C.newRun(admiral, fac)
	C.RUN["map"]["cond"] = null
	var n = {"id": "y", "col": 0, "type": "shipyard"}
	C.yard_node = n

func _run() -> void:
	var err: String = C.load_tables()
	if err != "":
		printerr("FAIL: " + err); quit(1); return
	C.fixed_clock = true

	# 1. selling the flagship hands the flagship to a ship still in the fleet
	_start("vex", "voidsworn", 1384)
	C.RUN["aspect"] = C.ASPECTS.keys()[0]
	var f = C.flagshipOf()
	C.ACT_sellConfirm(str(f["uid"]))
	var nf = C.flagshipOf()
	check(nf != null and not is_same(nf, f), "selling the flagship hands the flagship on (flagUid " + str(C.RUN.get("flagUid")) + ")")

	# 2. a regrown Eclipse ship never decommissions for more than its regrow cost
	_start("nekhet", "deathless", 1385)
	var tpl = C.RUN["fleet"][C.RUN["fleet"].size() - 1]["tpl"]
	C.RUN["cores"] = [tpl]; C.RUN["credits"] = 2000.0; C.RUN["cpCap"] = 99.0
	var cost = C.coreCost(tpl)
	C.ACT_restoreCore("0")
	var g = C.RUN["fleet"][C.RUN["fleet"].size() - 1]
	check(g.get("regrown") == true and g.get("corePaid") != null and float(g["corePaid"]) == cost, "regrow records its cost (" + str(g.get("corePaid")) + " vs " + str(cost) + ")")
	check(C.sellValue(g) == 0.0, "before a fight a regrown ship sells for 0")
	C.settleRegrown()   # what rewardFlow does after a battle
	check(g.get("regrown") == null, "the regrown mark is cleared after a battle")
	check(C.sellValue(g) <= cost, "after a fight it sells for " + str(C.sellValue(g)) + ", at most the regrow cost " + str(cost))
	check(C.sellValue({"tpl": tpl}) == C.prizeScrap(tpl), "a ship that was never regrown still sells for the full 35%")

	# 2b. a ship regrown in an older save (no corePaid) keeps a cap through its next win
	var old = C.RUN["fleet"][0]; old["regrown"] = true; old.erase("corePaid")
	C.settleRegrown()
	check(old.get("corePaid") != null and float(old["corePaid"]) == C.coreCost(old["tpl"]) and C.sellValue(old) < C.prizeScrap(old["tpl"]), "an older save's regrown ship is capped at " + str(old.get("corePaid")) + " after its next win")

	# 3. the Daybreak dreadnought carries the Crusade shop discount, its ladder value stays
	var asc = C.HULLS["ascendant"]
	check(float(asc["val"]) == 520.0 and float(asc["cost"]) == C.jsround(520.0 * float(C.TB.SHOP_DISCOUNT["voidsworn"]) / 5.0) * 5.0, "ascendant costs " + str(asc.get("cost")) + " (value " + str(asc.get("val")) + ")")

	# 4. a captured Eclipse frigate costs what a Warden costs in a Crusade shop
	_start("vex", "voidsworn", 1386)
	check(C.capturedHullPrice(C.HULLS["d_scythe"]) == float(C.HULLS["warden"]["cost"]), "a captured mote costs " + str(C.capturedHullPrice(C.HULLS["d_scythe"])) + ", a Warden " + str(C.HULLS["warden"]["cost"]))

	# 5. Sector 3: an eaten core is remapped to another patron in the beat 3 core reward and in boonStep
	_start("matriarch", "chorus", 1387)
	var eaten = C.TB.BEAT3_REWARDS["core"]["chorus"]
	if not C.RUN["patrons"].has(eaten): C.RUN["patrons"][0] = eaten
	C.RUN["eatenCore"] = eaten; C.RUN["eatCoreSeen"] = true
	C.applyOutcome({"core": true})
	var rp = C.RUN["reward"]["rw"]["p"] if C.RUN.get("reward") != null else null
	check(rp != null and rp != eaten and C.RUN["patrons"].has(rp), "the beat 3 core reward goes to " + str(rp) + ", not the eaten " + str(eaten))
	C.RUN["reward"] = {"kind": "story", "rw": {"k": "boon", "p": eaten}, "stage": "pick", "relics": [], "wrecks": [], "prizes": [], "boonOffer": null, "modOffer": null}
	C.modal_d = null
	C.boonStep(eaten, 0)
	var mp = C.modal_d["data"].get("patron") if C.modal_d != null and C.modal_d.get("kind") == "boon" else null
	check(mp != null and mp != eaten, "boonStep opens the " + str(mp) + " offer, not the eaten " + str(eaten))

	if fails > 0:
		printerr("FAIL: issue 1384 late fixes, " + str(fails) + " failed"); quit(1); return
	print("PASS: issue 1384 late fixes")
	quit(0)
