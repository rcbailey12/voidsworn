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
	rec(tag, {"nem": C.RUN["nem"], "credits": C.RUN["credits"], "fleet": C.RUN["fleet"].map(func(s): return [s["uid"], s["hp"]]), "variants": C.META["variants"], "rng": JSM.rng_s & 0xFFFFFFFF})
func setup(seed: int, fac: String) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	C.RUN["foes"][3] = fac; C.RUN["nem"] = C.newNemesis(); state("new " + fac)
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
	var a := OS.get_cmdline_user_args()
	var fo = FileAccess.open(a[0], FileAccess.WRITE); fo.store_string("\n".join(OUT) + "\n"); fo.close()
	print(OUT.size(), " records")
	quit()
