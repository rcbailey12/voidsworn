# Issue 364: a Nemesis reader asks the campaign instead of the cached "nem" field, so an old commander cannot reach a
# story or battle screen. Headless:
#   godot --headless --path godot --script res://campaign/test/nem_read_test.gd
# Fixtures come from the real functions only: the same start-run clicks as nem_scenarios.gd, the campaign's own boss
# advance (afterBattle), and the real save and load path. Nothing here types a run, a registry or an assignment.
#
# What it proves:
#   1. After a real advance into sector 2, the story layer (arc_context, the card context) names the sector 2 commander,
#      not the sector 1 one, and asking does not change the registry, the PRNG or the cache.
#   2. A run saved after the advance and loaded through the real continue path still reads the sector 2 commander.
#   3. The four readers in story.gd and battle.gd source call the campaign read, not run.get("nem") / Bs.get("nem") at
#      those sites. The behaviour in 1 already holds on main because afterBattle resolves the incoming commander at
#      campaign.gd:2977; this source row is what fails on main first, and the job's fallback says to state that plainly.
extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM
const CampaignScript = preload("res://campaign/campaign.gd")
const Story = preload("res://story/story.gd")
const Tokens = preload("res://story/tokens.gd")
var C
var fails := 0
var lines: Array = []


func check(ok: bool, what: String) -> void:
	if ok:
		lines.append("PASS " + what)
	else:
		fails += 1
		lines.append("FAIL " + what)


func fresh(seed: int) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null; C.tel_log = []
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun")


func _init() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true
	fresh(101)
	C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	var N1 = C.nemRead()
	var f1 = str(C.RUN["nemAssign"][0])
	check(N1 is Dictionary and str(N1.get("fac", "")) == f1, "sector 1: the campaign read is the sector 1 commander (" + f1 + ")")

	# Advance into sector 2 through the campaign's own boss path. W["rewardCfg"] is the transient the boss reward screen
	# hands afterBattle; the sector counter, the registry and the commander are all made by campaign.gd itself.
	C.W["rewardCfg"] = {"kind": "boss"}
	C.afterBattle()
	var f2 = str(C.RUN["nemAssign"][1])
	var reg = C.RUN["nems"]
	check(int(C.RUN["sector"]) == 2, "the real boss advance moved the run to sector 2")
	check(reg.has(f2) and reg[f2] is Dictionary, "the campaign built the sector 2 commander (" + f2 + ")")

	# Ask the story layer, before any further campaign call, for the commander it will name.
	var reg_n = reg.size()
	var rng0 = JSM.rng_s
	var cache0 = C.RUN.get("nem")
	var S = Story.new()
	S.C = C
	var ctx: Dictionary = S.arc_context(C.RUN)
	var got = ctx.get("nem")
	check(got is Dictionary and str(got.get("fac", "")) == f2, "story arc context asks the campaign and gets the sector 2 commander (" + f2 + ")")
	check(got is Dictionary and str(got.get("name", "")) == str(reg[f2].get("name", "")), "the sector 2 commander's name reaches the story context")
	var rival: String = S._fill("{rival}", C.RUN)
	check(rival == Tokens.full_name(reg[f2]), "the story text reader names the sector 2 commander: " + rival)
	check(reg.size() == reg_n and JSM.rng_s == rng0 and is_same(C.RUN.get("nem"), cache0), "asking for the Nemesis changed nothing: registry, PRNG and the RUN.nem alias are as they were")

	# A save written after the advance loads and reads the same commander through the real continue path.
	C.saveRun()
	C.ACT_continueRun()
	var loaded = C.nemRead()
	check(loaded is Dictionary and str(loaded.get("fac", "")) == f2, "a save written after the advance loads and still reads the sector 2 commander (" + f2 + ")")
	check(is_same(C.RUN.get("nem"), loaded), "the RUN.nem alias is kept, as the job asks")

	# The readers themselves: the four sites must ask the campaign, not the cached field.
	var story_src := FileAccess.get_file_as_string("res://story/story.gd")
	var battle_src := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	check(not story_src.contains("var nem = run.get(\"nem\")"), "story.gd lines 141 and 295 no longer read run.get(\"nem\")")
	check(not story_src.contains("\"nem\": run.get(\"nem\")"), "story.gd line 261 no longer reads run.get(\"nem\")")
	check(not battle_src.contains("_jt(Bs.get(\"nem\"))") and not battle_src.contains("Bs[\"nem\"][\"weak\"]"), "battle.gd's Nemesis block no longer reads the battle's cached copy")

	for l in lines:
		print(l)
	print("stale read through the campaign's own sector advance: not reproduced end to end, because afterBattle resolves the incoming commander at campaign.gd:2977; the reader change is kept anyway, as the job allows")
	print("Nemesis read: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
