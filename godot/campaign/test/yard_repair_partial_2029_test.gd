# Issue 2029 item 7: a yard repair buys as many hull points as the purse allows, at the price per point of a full repair.
#   godot --headless --path godot --script res://campaign/test/yard_repair_partial_2029_test.gd
# Before: 9 credits repaired 0 of 20 missing hull and 10 repaired 20. Now 9 repairs 18; 10 (the full bill) still repairs 20.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
var fails := 0

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

func _yard() -> Variant:
	var C = Campaign.new(); C.load_tables(); C.fixed_clock = true
	C.rng.rnd_seed(2029); C.META = C.defaultMeta()
	var adm = null
	for id in C.ADMIRALS.keys():
		if C.ADMIRALS[id].get("fac") == "voidsworn" and adm == null: adm = id
	C.newRun(adm, "voidsworn", {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null; C.RUN["credits"] = 5000
	if C.RUN.get("aspect") == null: C.RUN["aspect"] = C.ASPECTS.keys()[0]
	var target := ""
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if target != "": break
			C.RUN["pos"] = n["id"]
			for id in C.availableNodes():
				var m = C.findNode(id)
				if target == "" and m != null and m["type"] == "shipyard" and not C.nemNodeIs(m): target = id
			if target != "": n["done"] = true
	C.RUN["curNode"] = null
	C.mapScreen()
	C.act("enterNode", target)
	return C

func _hurt(C, miss: float) -> Variant:   # the first ship, `miss` hull points short, and the price of one point
	var s = C.RUN["fleet"][0]
	s["hp"] = float(C.derive(s)["maxHp"]) - miss
	return s

func _repair_enabled(C, uid: String) -> bool:
	C.shipyardScreen(C.yard_node)   # the acts are worked out when the screen is built
	for a in C.screen_acts():
		if a[0] == "repair" and a[1] == uid: return int(a[2]) == 1
	return false

func _run() -> void:
	var C = _yard()
	_check(C.page.get("kind") == "shipyard", "a shipyard is open")
	var pm: float = C.priceMult()
	var s = _hurt(C, 20.0)
	var uid: String = s["uid"]
	var maxhp: float = C.derive(s)["maxHp"]
	_check(is_equal_approx(pm, 1.0), "price multiplier is 1 here (%s), so a point costs half a credit" % str(pm))
	# the audit's case: 9 credits used to repair 0, 10 repaired 20
	C.RUN["credits"] = 9.0
	_check(_repair_enabled(C, uid), "9 credits: the Repair button is on")
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp - 2.0), "9 credits repair 18 of 20 missing points (hp %s of %s)" % [str(s["hp"]), str(maxhp)])
	_check(is_equal_approx(float(C.RUN["credits"]), 0.0), "9 credits are spent (%s left)" % str(C.RUN["credits"]))
	_check(not _repair_enabled(C, uid), "0 credits: the Repair button is off")
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp - 2.0), "0 credits repair nothing")
	# the full bill is unchanged: exactly 10 for 20 points
	s = _hurt(C, 20.0)
	C.RUN["credits"] = 10.0
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp) and is_equal_approx(float(C.RUN["credits"]), 0.0), "10 credits repair all 20 and cost 10 (unchanged)")
	# a rich purse pays the full bill only
	s = _hurt(C, 20.0)
	C.RUN["credits"] = 500.0
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp) and is_equal_approx(float(C.RUN["credits"]), 490.0), "500 credits: full repair, 490 left")
	# a full ship is not charged
	C.act("repair", uid)
	_check(is_equal_approx(float(C.RUN["credits"]), 490.0), "a full-hull ship costs nothing")
	# one credit buys two points; a partial repair can be topped up later
	s = _hurt(C, 20.0)
	C.RUN["credits"] = 1.0
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp - 18.0) and is_equal_approx(float(C.RUN["credits"]), 0.0), "1 credit repairs 2 points")
	C.RUN["credits"] = 100.0
	C.act("repair", uid)
	_check(is_equal_approx(float(s["hp"]), maxhp) and is_equal_approx(float(C.RUN["credits"]), 91.0), "topping up the other 18 points costs 9")
	# repair the whole fleet is still all or nothing
	for x in C.RUN["fleet"]: x["hp"] = float(C.derive(x)["maxHp"]) - 20.0
	var all_bill: float = ceil(20.0 * C.RUN["fleet"].size() / 2.0 * pm)
	C.RUN["credits"] = all_bill - 1.0
	C.act("repairAll")
	_check(is_equal_approx(float(C.RUN["fleet"][0]["hp"]), float(C.derive(C.RUN["fleet"][0])["maxHp"]) - 20.0) and is_equal_approx(float(C.RUN["credits"]), all_bill - 1.0), "Repair entire fleet one credit short does nothing (all or nothing, as before)")
	C.RUN["credits"] = all_bill
	C.act("repairAll")
	_check(is_equal_approx(float(C.RUN["fleet"][0]["hp"]), float(C.derive(C.RUN["fleet"][0])["maxHp"])) and is_equal_approx(float(C.RUN["credits"]), 0.0), "Repair entire fleet at the full bill repairs all")
	# the rule itself, over prices and purses: never overspends, never leaves a point the purse could buy, full bill unchanged
	var bad := 0
	for pmx in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]:
		for miss in [1.0, 7.0, 20.0, 33.0, 120.0]:
			var full: float = C.repairBill(miss, pmx)
			if C.repairPoints(miss, pmx, full) != miss or full != ceil(miss / 2.0 * pmx): bad += 1
			for funds in range(0, int(full) + 3):
				var pts: float = C.repairPoints(miss, pmx, float(funds))
				if C.repairBill(pts, pmx) > float(funds): bad += 1   # overspends
				if pts < miss and C.repairBill(pts + 1.0, pmx) <= float(funds): bad += 1   # left a buyable point
				if funds >= full and pts != miss: bad += 1
	_check(bad == 0, "repairPoints never overspends, never strands a buyable point, and pays the old bill for a full repair (%d bad)" % bad)
	print("yard_repair_partial_2029_test: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
