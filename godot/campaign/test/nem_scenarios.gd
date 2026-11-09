# G3: Nemesis campaign scenarios, Godot side (see node/nem_scenarios.js, the same steps in the same order).
#   godot --headless --path godot --script res://campaign/test/nem_scenarios.gd -- <out.txt>
extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM
const CampaignScript = preload("res://campaign/campaign.gd")
var C
var OUT := PackedStringArray()
func rec(tag: String, x) -> void: OUT.append(tag + " " + JSM.canon(x, "", {}, true))
func state(tag: String) -> void:
	rec(tag, {"nem": C.RUN.get("nem"), "nemClock": C.RUN.get("nemClock"), "nemStrike": C.RUN.get("nemStrike"), "nemAssign": C.RUN.get("nemAssign"), "nems": C.RUN.get("nems"), "credits": C.RUN["credits"], "fleet": C.RUN["fleet"].map(func(s): return [s["uid"], s["hp"]]), "variants": C.META["variants"], "rng": JSM.rng_s & 0xFFFFFFFF})
func setup(seed: int, fac: String) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null; C.tel_log = []   # the JS META reset clears its tel too
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	C.RUN["nemAssign"] = [fac, fac, fac]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.nemActive(); state("new " + fac)
func fresh(seed: int) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null; C.tel_log = []   # the JS META reset clears its tel too
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
func toMap() -> void:
	C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
func _init() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true
	setup(101, "deathless"); C.RUN["sector"] = 2; rec("a1", C.nemAfterBattle("win", true, {"cause": "melt"})); state("a1")
	C.RUN["sector"] = 3; rec("a2", C.nemAfterBattle("win", true, {})); state("a2"); rec("a3", C.nemAfterBattle("win", true, {})); state("a3")
	setup(102, "corsair"); C.RUN["credits"] = 10
	for s in C.RUN["fleet"]:
		if s["uid"] != C.RUN["flagUid"]:
			s["hp"] = 1; break
	C.RUN["nemClock"] = 3; C.RUN["nem"]["loot"] = 40; rec("b0", C.nemWarnLine(C.RUN["nem"])); rec("b1", C.nemClockAdd(1)); state("b1")
	rec("b2", C.nemAfterBattle("win", false, {"fled": true})); state("b2"); C.RUN["sector"] = 3; rec("b3", C.nemAfterBattle("win", true, {})); state("b3")
	setup(112, "corsair"); C.RUN["credits"] = 200; C.RUN["nemClock"] = 3; rec("b4", C.nemWarnLine(C.RUN["nem"])); rec("b5", C.nemClockAdd(1)); state("b5")
	setup(103, "ithar"); rec("c1", C.nemAfterBattle("win", false, {"fled": true, "beat": "torp"})); state("c1"); rec("c1cfg", C.nemBattleCfg())
	setup(104, "chorus"); rec("d1", C.nemFeedLosses(3)); rec("d2", C.nemFeedLosses(10)); rec("d3", C.nemFeedLosses(2)); state("d3")
	C.RUN["nem"]["seen"] = {"ram": 3}; rec("d4", C.nemAfterBattle("loss", false, {"myFlagDead": true})); state("d4"); rec("d4cfg", C.nemBattleCfg())
	setup(105, "voidsworn"); C.RUN["nem"]["seen"] = {"battery": 5}; rec("e1", C.nemAfterBattle("win", false, {"beat": "lance"})); C.RUN["sector"] = 2; rec("e2", C.nemAdapt()); state("e2")
	setup(106, "hegemony"); rec("f1", C.nemFoundMerge(["flank", C.RUN["nem"]["weak"][0], C.RUN["nem"]["weak"][1], "nonsense"])); state("f1")
	C.RUN["nem"]["g"] = "f"; rec("f2", C.nemSay("He holds his line; his guns follow him.", C.RUN["nem"])); C.RUN["nem"]["g"] = "n"; rec("f3", C.nemSay("He holds his line; his guns follow him.", C.RUN["nem"]))
	var facs = ["voidsworn", "hegemony", "ithar", "deathless", "chorus", "corsair"]
	for i in facs.size():
		var f = facs[i]; setup(110 + i, f); C.RUN["nemClock"] = 3.5 if f == "deathless" else 3.0
		rec("g " + f, C.nemWarnLine(C.RUN["nem"])); rec("g2 " + f, C.nemClockAdd(1)); state("g " + f)
	# 8 R1 (Nov 1): loss reveals, the clash check, the pre-persona migration (node/nem_scenarios.js section 8)
	setup(120, "hegemony"); rec("h1", C.nemAfterBattle("loss", false, {})); state("h1"); rec("h2", C.nemAfterBattle("retreat", false, {"found": [C.RUN["nem"]["weak"][1], "nonsense"]})); state("h2"); rec("h3", C.nemAfterBattle("loss", false, {})); state("h3")
	setup(121, "chorus"); C.RUN["nem"]["revealed"] = ["ion", "torp"]; C.RUN["nem"]["seen"] = {"lance": 9, "ion": 9, "torp": 9, "sq": 9}; C.RUN["sector"] = 2; rec("h4", C.nemAdapt()); rec("h5", C.nemAdapt(true)); state("h5")
	setup(122, "corsair"); C.RUN["nem"] = {"weak": ["ion", "slow"], "revealed": ["ion"], "adapt": ["riches"], "clock": 2, "met": 1, "beaten": 1, "scars": 1, "dead": false, "strike": false, "seen": {}, "loot": 500, "riches": 2, "fed": 3, "honed": 1, "held": C.RUN["fleet"][1], "last_beat": "lance"}; rec("h6", C.ensureNemesis()); state("h6")
	# ---------- issue 120: assignment draw, registry, active resolution, migration ----------
	fresh(130); state("i0"); rec("i0a", {"len": C.RUN["nemAssign"].size(), "nems": C.RUN["nems"].size()})
	toMap(); state("i1"); var IA = JSM.canon(C.RUN["nemAssign"], "", {}, true)
	C.RUN["sector"] = 2; C.nemActive(); rec("i2", C.nemAfterBattle("win", false, {})); state("i2")
	C.RUN["sector"] = 3; C.nemActive(); rec("i3", C.nemAfterBattle("win", false, {})); state("i3")
	rec("i4", JSM.canon(C.RUN["nemAssign"], "", {}, true) == IA)
	fresh(131); toMap(); var FA = C.RUN["foes"][0]; var FB = C.RUN["foes"][1]; var FC = C.RUN["foes"][2]; var FD = C.RUN["foes"][3]
	C.RUN["nemAssign"] = [FA, FB, FC]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["sector"] = 1; rec("j1", C.nemBattleCfg()["fac"])
	C.RUN["sector"] = 2; rec("j2", C.nemBattleCfg()["fac"])
	C.RUN["sector"] = 3; rec("j3", C.nemBattleCfg()["fac"])
	C.RUN["sector"] = 1; C.RUN["foes"][3] = FD; rec("j4", C.nemBattleCfg()["fac"])
	fresh(1); state("k0"); C.RUN["sector"] = 1; var n1 = C.nemActive(); state("k1")
	n1["scars"] = 1; n1["scarKinds"] = ["blast"]; C.RUN["sector"] = 2; var n2 = C.nemActive(); state("k2")
	C.RUN["sector"] = 3; var n3 = C.nemActive(); state("k3")
	rec("k4", {"fac1": n1["fac"], "fac2": n2["fac"], "fac3": n3["fac"], "same": is_same(n1, n3), "scars": n3["scars"], "nems": C.RUN["nems"].size()})
	fresh(135); toMap(); var FM = C.RUN["nemAssign"][0]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["nemAssign"] = [null, null, null]; C.RUN["sector"] = 2
	C.RUN["nem"] = {"fac": FM, "persona": C.NEM_FAC[FM]["personas"][0], "weak": ["ion", "slow"], "revealed": ["ion"], "adapt": [], "clock": 2.5, "met": 1, "beaten": 1, "scars": 1, "seen": {"lance": 2}}; C.RUN.erase("nemClock"); C.RUN.erase("nemStrike")
	C.ensureNemesis(); rec("l1", {"size": C.RUN["nems"].size(), "slot": C.RUN["nemAssign"][1], "fac": C.nemActive()["fac"], "weak": C.RUN["nem"]["weak"], "revealed": C.RUN["nem"]["revealed"], "adapt": C.RUN["nem"]["adapt"], "clock": C.RUN["nemClock"], "strike": C.RUN["nemStrike"], "met": C.RUN["nem"]["met"], "beaten": C.RUN["nem"]["beaten"], "scars": C.RUN["nem"]["scars"], "seen": C.RUN["nem"]["seen"]}); state("l1")
	fresh(136); toMap(); var FP = C.RUN["nemAssign"][0]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["nemAssign"] = [null, null, null]; C.RUN["sector"] = 1
	C.RUN["nem"] = {"fac": FP, "weak": ["ion", "slow"], "revealed": ["ion"], "adapt": [], "clock": 2, "met": 1, "beaten": 1, "scars": 1, "dead": false, "strike": false, "seen": {}, "loot": 500, "riches": 2, "fed": 3, "honed": 1, "last_beat": "lance"}; C.RUN.erase("nemClock"); C.RUN.erase("nemStrike")
	C.ensureNemesis(); rec("m1", {"size": C.RUN["nems"].size(), "slot": C.RUN["nemAssign"][0], "fac": C.nemActive()["fac"], "weak": C.RUN["nem"]["weak"], "revealed": C.RUN["nem"]["revealed"], "clock": C.RUN["nemClock"], "strike": C.RUN["nemStrike"], "met": C.RUN["nem"]["met"], "beaten": C.RUN["nem"]["beaten"], "scars": C.RUN["nem"]["scars"], "loot": C.RUN["nem"]["loot"], "riches": C.RUN["nem"]["riches"], "fed": C.RUN["nem"]["fed"], "honed": C.RUN["nem"]["honed"], "last_beat": C.RUN["nem"]["last_beat"]}); state("m1")
	fresh(137); toMap(); C.RUN["nemAssign"] = [FA, FB, FA]; C.RUN["nems"] = {}; C.RUN["nem"] = null
	C.RUN["sector"] = 1; var rA = C.nemActive(); rA["scars"] = 1; rA["scarKinds"] = ["blast"]; rA["epithet"] = "the Scarred"
	C.RUN["sector"] = 2; var rB = C.nemActive(); rB["revealed"] = [rB["weak"][0]]
	var RB = JSM.canon({"a": C.RUN["nemAssign"], "n": C.RUN["nems"]}, "", {}, true)
	C.SAVED_RUN = C.clone(C.RUN)
	C.RUN = C.migrateRun(C.clone(C.SAVED_RUN)); C.ensureNemesis()
	rec("n1", {"same": RB == JSM.canon({"a": C.RUN["nemAssign"], "n": C.RUN["nems"]}, "", {}, true), "size": C.RUN["nems"].size(), "fac": C.nemBattleCfg()["fac"], "scars": C.RUN["nems"][FA]["scars"], "revealed": C.RUN["nems"][FB]["revealed"]}); state("n1")
	run_121()
	run_122()
	var a := OS.get_cmdline_user_args()
	var fo = FileAccess.open(a[0], FileAccess.WRITE); fo.store_string("\n".join(OUT) + "\n"); fo.close()
	print(OUT.size(), " records")
	quit()

# ---------- issue 121 (node/nem_scenarios.js sections 15 to 24, the same steps in the same order) ----------
func forced(seed: int, a: Array) -> void:
	fresh(seed); toMap(); C.RUN["nemAssign"] = a.duplicate(); C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["nemClock"] = 0; C.RUN["nemStrike"] = false; C.RUN["sector"] = 1; C.nemActive()
func bnodes() -> Array:
	var o = []
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if n["type"] == "battle" or n["type"] == "elite": o.append(n)
	return o
func lateN() -> Variant:
	for n in bnodes():
		if float(n["col"]) >= float(C.RUN["map"]["cols"].size() - 3): return n
	return null
func earlyN() -> Variant:
	for n in bnodes():
		if float(n["col"]) < float(C.RUN["map"]["cols"].size() - 3): return n
	return null
func nodeIsAll() -> Array: return bnodes().map(func(n): return C.nemNodeIs(n))
func adv() -> void:
	C.RUN["reward"] = null; C.W["rewardCfg"] = {"kind": "boss"}; C.afterBattle()
func run_121() -> void:
	# 15 (121-1, 121-2)
	forced(140, ["hegemony", "corsair", "hegemony"]); rec("o1", {"is": C.nemNodeIs(lateN()), "fac": C.nemBattleCfg()["fac"]}); rec("o2", C.nemAfterBattle("win", false, {})); rec("o3", nodeIsAll()); state("o3")
	C.RUN["sector"] = 2; C.nemActive(); rec("o4", {"is": C.nemNodeIs(lateN()), "fac": C.nemBattleCfg()["fac"]}); rec("o5", C.nemAfterBattle("win", false, {}))
	C.RUN["sector"] = 3; C.nemActive(); rec("o6", {"is": C.nemNodeIs(lateN()), "fac": C.nemBattleCfg()["fac"], "met": C.nemBattleCfg()["met"], "size": C.RUN["nems"].size()}); rec("o7", C.nemAfterBattle("win", false, {})); rec("o8", nodeIsAll()); state("o8")
	# 16 (121-3)
	for f in ["deathless", "voidsworn", "hegemony"]:
		forced(141, [f, f, f])
		for x in C.RUN["fleet"]: x["hp"] = 9999
		var seq = []; var i = 0
		while i < 8 and not C.jt(C.RUN.get("nemStrike")):
			rec("p " + f + " " + str(i), C.nemClockAdd(1)); seq.append(C.RUN["nemClock"]); i += 1
		rec("p " + f, seq); state("p " + f)
	# 17 (121-4)
	forced(142, ["hegemony", "corsair", "ithar"]); C.nemAfterBattle("win", false, {}); C.RUN["sector"] = 2; C.nemActive(); C.RUN["credits"] = 0; rec("q1", {"is": C.nemNodeIs(earlyN()), "fac": C.nemActive()["fac"]})
	var j = 0
	while j < 8 and not C.jt(C.RUN.get("nemStrike")):
		C.nemClockAdd(1); j += 1
	rec("q2", {"is": C.nemNodeIs(earlyN()), "fac": C.nemActive()["fac"], "assign": C.RUN["nemAssign"], "strike": C.RUN["nemStrike"]}); state("q2")
	# 18 (121-5)
	for r in ["win", "loss", "retreat"]:
		forced(143, ["hegemony", "corsair", "ithar"]); C.nemAfterBattle("win", false, {}); C.RUN["sector"] = 2; C.nemActive(); C.RUN["nemClock"] = 4; C.RUN["nemStrike"] = true; rec("r " + r, C.nemAfterBattle(r, false, {})); state("r " + r)
	# 19 (121-6, A4)
	forced(144, ["hegemony", "corsair", "hegemony"]); C.RUN["nems"]["hegemony"]["seen"] = {"battery": 5}; adv(); state("s1"); C.RUN["nems"]["corsair"]["seen"] = {"lance": 9}; adv(); state("s2")
	# 20 (121-8)
	forced(145, ["hegemony", "chorus", "ithar"]); C.RUN["sector"] = 2; var CH = C.nemActive(); CH["beaten"] = 1; CH["scars"] = 1; CH["adapt"] = ["armor", "aim"]; CH["seen"] = {"lance": 9}; rec("t1", C.nemAdapt()); CH["seen"] = {"torp": 9}; rec("t2", C.nemAdapt())
	CH["adapt"] = ["armor"]; CH["seen"] = {"ram": 2}; rec("t3", C.nemAfterBattle("loss", false, {})); state("t3")
	# 21 (121-9)
	forced(146, ["hegemony", "corsair", "voidsworn"]); rec("u1", C.nemAfterBattle("win", true, {"cause": "big"})); C.RUN["sector"] = 2; C.nemActive(); rec("u2", C.nemAfterBattle("loss", false, {})); rec("u3", C.nemAfterBattle("loss", false, {})); rec("u4", C.nemAfterBattle("loss", false, {}))
	C.RUN["sector"] = 3; C.nemActive(); rec("u5", C.nemAfterBattle("loss", false, {})); state("u5")
	# 22 (121-12)
	forced(147, ["deathless", "deathless", "deathless"]); C.RUN["sector"] = 2; rec("v1", C.nemAfterBattle("win", true, {"cause": "big"})); C.RUN["sector"] = 3; rec("v2", C.nemAfterBattle("win", true, {})); rec("v3", C.nemAfterBattle("win", true, {})); state("v3")
	forced(148, ["hegemony", "ithar", "corsair"]); var VN = C.nemActive(); rec("v4", C.nemBattleCfg()["line"]); VN["beaten"] = 1; VN["last_beat"] = "lance"; rec("v5", C.nemOpenLine(VN)); VN["adapt"] = ["shields"]; rec("v6", C.nemOpenLine(VN)); VN["gloat"] = "loss"; rec("v7", C.nemOpenLine(VN))
	VN["g"] = "f"; rec("v8", C.nemAdaptLine(VN, "shields")); rec("v9", C.nemAdaptLine(VN, "formation"))
	forced(149, ["voidsworn", "hegemony", "ithar"]); rec("v10", {"line": C.nemBattleCfg()["line"], "adapt": C.nemAdaptLine(C.nemActive(), "shields")})
	# 23 (121-13)
	forced(150, ["hegemony", "chorus", "ithar"]); C.RUN["sector"] = 2; C.nemActive(); rec("w1", [C.nemFeedLosses(5), C.nemFeedLosses(9)]); state("w1")
	# 24 saves
	forced(151, ["hegemony", "corsair", "ithar"]); C.RUN.erase("nemClock"); C.RUN.erase("nemStrike"); C.RUN["nems"]["hegemony"]["clock"] = 2.5; C.RUN["nems"]["hegemony"]["strike"] = true; C.nemActive(); state("x1")
	C.SAVED_RUN = C.clone(C.RUN); C.RUN = C.migrateRun(C.clone(C.SAVED_RUN)); C.nemActive(); state("x2")

# ---------- issue 122 (node/nem_scenarios.js sections 25 to 31, the same steps in the same order) ----------
func nemTel() -> Array:
	var o = []
	for e in C.tel_log:
		if str(e.get("ev", "")).begins_with("nem_"): o.append({"ev": e["ev"], "fac": e.get("fac"), "kind": e.get("kind"), "how": e.get("how"), "n": e.get("n"), "cap": e.get("cap"), "sector": e.get("sector")})
	return o
func tstate(tag: String) -> void:
	var ks = C.RUN["nems"].keys(); ks.sort()
	var cmd = []
	for f in ks:
		var N = C.RUN["nems"][f]; cmd.append([f, N.get("signatures"), N.get("fed"), N.get("scars"), C.jt(N.get("dead"))])
	rec(tag, {"esc": C.RUN.get("nemEscapes"), "cmd": cmd, "tel": nemTel()}); C.tel_log = []
func run_122() -> void:
	# 25 (122-1)
	forced(160, ["ithar", "corsair", "hegemony"]); C.tel_log = []; tstate("y0"); rec("y1", C.nemAfterBattle("win", false, {"fled": true})); tstate("y1")
	C.RUN["sector"] = 2; C.nemActive(); C.RUN["credits"] = 100
	var i = 0
	while i < 8 and not C.jt(C.RUN.get("nemStrike")):
		C.nemClockAdd(1); i += 1
	tstate("y2")
	var YA = C.RUN["nems"]["ithar"]
	for k in range(41): C.nemSignature("k" + str(k), YA)
	rec("y3", {"len": YA["signatures"].size(), "first": YA["signatures"][0], "last": YA["signatures"][39], "active": C.nemActive()["fac"], "tagged": nemTel().filter(func(e): return e["fac"] == "ithar").size()}); C.tel_log = []
	# 26 (122-2)
	forced(161, ["ithar", "corsair", "hegemony"]); tstate("z0"); C.nemAfterBattle("win", false, {"fled": true}); tstate("z1")
	C.RUN["sector"] = 2; C.nemActive(); C.nemAfterBattle("win", true, {"cause": "big"}); tstate("z2"); C.RUN["sector"] = 3; C.nemActive(); C.nemAfterBattle("win", true, {}); tstate("z3")
	forced(162, ["ithar", "corsair", "ithar"]); C.nemAfterBattle("win", false, {"fled": true}); tstate("z4"); C.RUN["sector"] = 2; C.nemActive(); C.nemAfterBattle("win", false, {}); tstate("z5"); C.RUN["sector"] = 3; C.nemActive(); C.nemAfterBattle("win", true, {}); tstate("z6")
	forced(163, ["hegemony", "corsair", "deathless"]); C.RUN["sector"] = 3; C.nemActive(); C.nemAfterBattle("win", true, {}); tstate("z7"); C.nemAfterBattle("win", true, {}); tstate("z8")
	forced(164, ["hegemony", "corsair", "ithar"]); C.RUN["sector"] = 3; C.nemActive(); C.nemAfterBattle("win", false, {"fled": true}); tstate("z9")
	forced(165, ["ithar", "corsair", "ithar"]); C.nemAfterBattle("loss", false, {}); C.RUN["sector"] = 2; C.nemActive(); C.nemAfterBattle("retreat", false, {}); tstate("z10")
	# 27 (122-3)
	forced(166, ["hegemony", "chorus", "ithar"]); rec("aa1", C.nemFeedLosses(5)); tstate("aa1"); C.RUN["sector"] = 2; var AC = C.nemActive(); rec("aa2", AC["fed"])
	rec("aa3", [C.nemFeedLosses(3), C.nemFeedLosses(10), C.nemFeedLosses(2)]); tstate("aa3")
	var ks = C.RUN["nems"].keys(); ks.sort()
	rec("aa4", ks.map(func(f): return [f, C.nemCompound(C.RUN["nems"][f])]))
	rec("aa5", [C.nemCompound({"fac": "corsair", "fed": 0, "riches": 2}), C.nemCompound({"fac": "ithar", "honed": 1})]); C.RUN["sector"] = 3; C.nemActive(); rec("aa6", C.nemFeedLosses(4)); tstate("aa6"); rec("aa7", C.nemTelSummary())
	# 28 (122-9)
	forced(167, ["ithar", "chorus", "hegemony"]); C.nemAfterBattle("win", false, {"fled": true}); C.RUN["sector"] = 2; C.nemActive(); C.nemFeedLosses(3); tstate("ab1")
	rec("ab2", {"onRun": C.RUN.has("fed"), "onCmd": C.RUN["nems"].values().filter(func(N): return N.has("nemEscapes")).size()}); C.nemAfterBattle("win", true, {"cause": "big"}); tstate("ab3")
	# 29 (122-4, 122-5)
	forced(168, ["ithar", "chorus", "ithar"]); rec("ac1", C.nemPanelData()); C.nemAfterBattle("win", false, {"fled": true}); adv(); rec("ac2", C.nemPanelData())
	C.nemAfterBattle("loss", false, {}); rec("ac3", C.nemPanelData()); adv(); rec("ac4", C.nemPanelData()); C.nemAfterBattle("loss", false, {}); rec("ac5", C.nemPanelData()); C.nemAfterBattle("win", true, {}); rec("ac6", C.nemPanelData())
	# 30 saves
	forced(169, ["ithar", "chorus", "deathless"]); C.nemAfterBattle("win", false, {"fled": true}); C.RUN.erase("nemEscapes"); C.nemActive(); rec("ad1", C.RUN["nemEscapes"])
	forced(170, ["hegemony", "corsair", "deathless"]); C.RUN["sector"] = 3; C.nemActive(); C.nemAfterBattle("win", true, {}); C.RUN.erase("nemEscapes"); C.nemActive(); rec("ad2", C.RUN["nemEscapes"])
	C.RUN["nemEscapes"] = 1; C.SAVED_RUN = C.clone(C.RUN); C.RUN = C.migrateRun(C.clone(C.SAVED_RUN)); C.nemActive(); rec("ad3", C.RUN["nemEscapes"])
	fresh(171); toMap(); C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["nemAssign"] = [null, null, null]; C.RUN["sector"] = 2; C.RUN.erase("nemClock"); C.RUN.erase("nemStrike"); C.RUN.erase("nemEscapes")
	C.RUN["nem"] = {"fac": "ithar", "name": "Calek", "title": "First Mirror", "persona": C.NEM_FAC["ithar"]["personas"][0], "weak": ["ion", "slow"], "revealed": ["ion"], "adapt": [], "clock": 1, "met": 1, "beaten": 2, "scars": 2, "seen": {}}; C.ensureNemesis(); rec("ad4", {"esc": C.RUN["nemEscapes"], "panel": C.nemPanelData()})
	# 31 the clock-full message through nemSay
	forced(172, ["chorus", "hegemony", "chorus"]); C.RUN["nemClock"] = 3; rec("ae1", C.nemClockAdd(1))
	forced(173, ["hegemony", "chorus", "hegemony"]); C.nemActive()["g"] = "f"; C.RUN["nemClock"] = 3; rec("ae2", C.nemClockAdd(1))
	forced(174, ["corsair", "hegemony", "corsair"]); C.nemActive()["g"] = "f"; C.RUN["credits"] = 100; C.RUN["nemClock"] = 3; rec("ae3", C.nemClockAdd(1)); tstate("ae3")
	run_282()

# ---------- issue 282 (node/nem_scenarios.js section 32 and 33, the same steps) ----------
func textRun(seed: int, fac: String) -> Variant:
	forced(seed, ["corsair", fac, "ithar"]); C.RUN["sector"] = 2; var N = C.nemActive(); N["g"] = "n" if fac == "chorus" else "f"; N["seen"] = {}; N["adapt"] = []; return N
func run_282() -> void:
	# 32 (#282) the panel strike line and the sector modal's adaptation reason read correctly for a female and a Chorus commander
	var TF = textRun(180, "hegemony"); rec("ag1", C.nemStrikeLine(TF)); var spellF = C.nemAdaptWhyLine("formation", TF); adv()
	rec("ag2", {"why": spellF, "shown": str(C.modal_d["data"].get("adaptWhy", "")) == spellF})
	var TC = textRun(181, "chorus"); rec("ag3", C.nemStrikeLine(TC)); var spellC = C.nemAdaptWhyLine("hunger", TC); adv()
	rec("ag4", {"why": spellC, "shown": str(C.modal_d["data"].get("adaptWhy", "")) == spellC})
	# 33 (#282) a full clock, not a pending strike, crosses the sector advance; the strike arms on the next sector's first clock add
	forced(182, ["hegemony", "corsair", "ithar"])
	for x in C.RUN["fleet"]: x["hp"] = 9999
	C.nemAfterBattle("win", false, {}); var cc = 0
	while C.RUN["nemClock"] < C.NEM_CLOCK and cc < 8:
		C.nemClockAdd(1); cc += 1
	rec("ah1", {"clock": C.RUN["nemClock"], "strike": C.jt(C.RUN.get("nemStrike")), "met": C.RUN["nems"]["hegemony"]["met"]}); adv(); var e2 = earlyN()
	rec("ah2", {"sector": C.RUN["sector"], "clock": C.RUN["nemClock"], "strike": C.jt(C.RUN.get("nemStrike")), "node": C.nemNodeIs(e2)})
	rec("ah3", C.nemClockAdd(1)); rec("ah4", {"clock": C.RUN["nemClock"], "strike": C.jt(C.RUN.get("nemStrike")), "node": C.nemNodeIs(e2)})
