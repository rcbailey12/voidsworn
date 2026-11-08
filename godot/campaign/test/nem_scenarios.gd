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
	rec(tag, {"nem": C.RUN.get("nem"), "nemAssign": C.RUN.get("nemAssign"), "nems": C.RUN.get("nems"), "credits": C.RUN["credits"], "fleet": C.RUN["fleet"].map(func(s): return [s["uid"], s["hp"]]), "variants": C.META["variants"], "rng": JSM.rng_s & 0xFFFFFFFF})
func setup(seed: int, fac: String) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	C.RUN["nemAssign"] = [fac, fac, fac]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.nemActive(); state("new " + fac)
func fresh(seed: int) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null
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
	C.RUN["nem"]["clock"] = 3; C.RUN["nem"]["loot"] = 40; rec("b0", C.nemWarnLine(C.RUN["nem"])); rec("b1", C.nemClockAdd(1)); state("b1")
	rec("b2", C.nemAfterBattle("win", false, {"fled": true})); state("b2"); C.RUN["sector"] = 3; rec("b3", C.nemAfterBattle("win", true, {})); state("b3")
	setup(112, "corsair"); C.RUN["credits"] = 200; C.RUN["nem"]["clock"] = 3; rec("b4", C.nemWarnLine(C.RUN["nem"])); rec("b5", C.nemClockAdd(1)); state("b5")
	setup(103, "ithar"); rec("c1", C.nemAfterBattle("win", false, {"fled": true, "beat": "torp"})); state("c1"); rec("c1cfg", C.nemBattleCfg())
	setup(104, "chorus"); rec("d1", C.nemFeedLosses(3)); rec("d2", C.nemFeedLosses(10)); rec("d3", C.nemFeedLosses(2)); state("d3")
	C.RUN["nem"]["seen"] = {"ram": 3}; rec("d4", C.nemAfterBattle("loss", false, {"myFlagDead": true})); state("d4"); rec("d4cfg", C.nemBattleCfg())
	setup(105, "voidsworn"); C.RUN["nem"]["seen"] = {"battery": 5}; rec("e1", C.nemAfterBattle("win", false, {"beat": "lance"})); C.RUN["sector"] = 2; rec("e2", C.nemAdapt()); state("e2")
	setup(106, "hegemony"); rec("f1", C.nemFoundMerge(["flank", C.RUN["nem"]["weak"][0], C.RUN["nem"]["weak"][1], "nonsense"])); state("f1")
	C.RUN["nem"]["g"] = "f"; rec("f2", C.nemSay("He holds his line; his guns follow him.", C.RUN["nem"])); C.RUN["nem"]["g"] = "n"; rec("f3", C.nemSay("He holds his line; his guns follow him.", C.RUN["nem"]))
	var facs = ["voidsworn", "hegemony", "ithar", "deathless", "chorus", "corsair"]
	for i in facs.size():
		var f = facs[i]; setup(110 + i, f); C.RUN["nem"]["clock"] = 3.5 if f == "deathless" else 3.0
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
	C.RUN["nem"] = {"fac": FM, "persona": C.NEM_FAC[FM]["personas"][0], "weak": ["ion", "slow"], "revealed": ["ion"], "adapt": [], "clock": 2.5, "met": 1, "beaten": 1, "scars": 1, "seen": {"lance": 2}}
	C.ensureNemesis(); rec("l1", {"size": C.RUN["nems"].size(), "slot": C.RUN["nemAssign"][1], "fac": C.nemActive()["fac"], "weak": C.RUN["nem"]["weak"], "revealed": C.RUN["nem"]["revealed"], "adapt": C.RUN["nem"]["adapt"], "clock": C.RUN["nem"]["clock"], "met": C.RUN["nem"]["met"], "beaten": C.RUN["nem"]["beaten"], "scars": C.RUN["nem"]["scars"], "seen": C.RUN["nem"]["seen"]}); state("l1")
	fresh(136); toMap(); var FP = C.RUN["nemAssign"][0]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.RUN["nemAssign"] = [null, null, null]; C.RUN["sector"] = 1
	C.RUN["nem"] = {"fac": FP, "weak": ["ion", "slow"], "revealed": ["ion"], "adapt": [], "clock": 2, "met": 1, "beaten": 1, "scars": 1, "dead": false, "strike": false, "seen": {}, "loot": 500, "riches": 2, "fed": 3, "honed": 1, "last_beat": "lance"}
	C.ensureNemesis(); rec("m1", {"size": C.RUN["nems"].size(), "slot": C.RUN["nemAssign"][0], "fac": C.nemActive()["fac"], "weak": C.RUN["nem"]["weak"], "revealed": C.RUN["nem"]["revealed"], "clock": C.RUN["nem"]["clock"], "met": C.RUN["nem"]["met"], "beaten": C.RUN["nem"]["beaten"], "scars": C.RUN["nem"]["scars"], "loot": C.RUN["nem"]["loot"], "riches": C.RUN["nem"]["riches"], "fed": C.RUN["nem"]["fed"], "honed": C.RUN["nem"]["honed"], "last_beat": C.RUN["nem"]["last_beat"]}); state("m1")
	fresh(137); toMap(); C.RUN["nemAssign"] = [FA, FB, FA]; C.RUN["nems"] = {}; C.RUN["nem"] = null
	C.RUN["sector"] = 1; var rA = C.nemActive(); rA["scars"] = 1; rA["scarKinds"] = ["blast"]; rA["epithet"] = "the Scarred"
	C.RUN["sector"] = 2; var rB = C.nemActive(); rB["revealed"] = [rB["weak"][0]]
	var RB = JSM.canon({"a": C.RUN["nemAssign"], "n": C.RUN["nems"]}, "", {}, true)
	C.SAVED_RUN = C.clone(C.RUN)
	C.RUN = C.migrateRun(C.clone(C.SAVED_RUN)); C.ensureNemesis()
	rec("n1", {"same": RB == JSM.canon({"a": C.RUN["nemAssign"], "n": C.RUN["nems"]}, "", {}, true), "size": C.RUN["nems"].size(), "fac": C.nemBattleCfg()["fac"], "scars": C.RUN["nems"][FA]["scars"], "revealed": C.RUN["nems"][FB]["revealed"]}); state("n1")
	var a := OS.get_cmdline_user_args()
	var fo = FileAccess.open(a[0], FileAccess.WRITE); fo.store_string("\n".join(OUT) + "\n"); fo.close()
	print(OUT.size(), " records")
	quit()
