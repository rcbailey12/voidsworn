# Issue 1182: a save from an older build can name a Nemesis trait or weakness the tables no longer have. Every place that
# names one (nem_entry callers) must show the raw key or skip it, never index null. Headless:
#   godot --headless --path godot --script res://campaign/test/nem_unknown_key_test.gd
#
# The save is the campaign's own: a real run, its commander given one unknown trait and one unknown weakness (revealed) plus
# one unknown weakness still hidden, saved with save_text(), loaded into a fresh campaign with load_save_text() and continued.
# Then it walks: the campaign view (Nemesis panel and Dossier), the battle log (the rules' nemTrip on an unknown weakness),
# the after-battle text (a win that reveals, a loss that teaches, a win that confirms) and the after-battle summary
# (finishBattle with an unknown weakness found in the battle), and the intel reward that reveals one.
extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM
const CampaignScript = preload("res://campaign/campaign.gd")
const View = preload("res://campaign/campaign_view.gd")
const FAC := "corsair"
var fails := 0


func check(ok: bool, what: String) -> void:
	if ok: print("PASS " + what)
	else:
		fails += 1; print("FAIL " + what)


func new_campaign() -> Variant:
	var C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); return null
	C.fixed_clock = true; C.persist_on = false
	return C


func start(C, seed: int) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null; C.tel_log = []
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	C.RUN["nemAssign"] = [FAC, FAC, FAC]; C.RUN["nems"] = {}; C.RUN["nem"] = null; C.nemActive()


# an older save: the commander holds keys the tables lack
func old_save(seed: int) -> Variant:
	var C = new_campaign()
	if C == null: return null
	start(C, seed)
	var N = C.RUN["nem"]
	N["traits"].append("old_trait")
	for w in N["weak"]:
		if not N["revealed"].has(w): N["revealed"].append(w)   # the real weaknesses are known, so the next one revealed is the unknown one
	N["weak"].append("old_weak"); N["revealed"].append("old_weak"); N["weak"].append("old_hidden"); N["weak"].append("old_late")
	N["met"] = 1; N["beaten"] = 1
	C.saveRun()
	var text: String = C.save_text()
	var L = new_campaign()
	L.load_save_text(text)
	L.act("continueRun")
	return L


func _init() -> void:
	var C = old_save(1182)
	if C == null: quit(1); return
	var N = C.nemRead()
	check(N is Dictionary and N["traits"].has("old_trait") and N["revealed"].has("old_weak"), "the old save loads with its unknown trait and weakness")
	check(not C.NEM_TRAITS.has("old_trait") and not C.NEM_WEAK.has("old_weak"), "the keys really are missing from the tables")

	# campaign view
	var panel = View.nemesis(C)
	check(panel is Dictionary, "campaign view: the Nemesis panel opens")
	var dossier: Array = View.nem_dossier(C)
	var text := JSON.stringify(dossier)
	check(text.contains("Weaknesses:") and text.contains("[b]old_weak[/b]"), "campaign view: the Dossier shows the unknown weakness by its key")
	check(text.contains("Strengths:") and not text.contains("old_trait"), "campaign view: the Dossier skips the unknown trait")

	# battle log: the rules find the unknown weakness in battle
	var R = BattleAPI.RulesScript.new()
	check(R.load_tables("res://rules/data/tables.json") == "", "battle log: the rules tables load")
	R.B = {"nem": {"fac": FAC, "weak": ["old_weak"], "revealed": []}, "log": [], "units": []}
	R.nemTrip("old_weak")
	var logged = R.B["log"].map(func(e): return str(e["m"]))
	check(logged.has("Weakness found: old_weak."), "battle log: an unknown weakness found in battle logs its key")

	# after-battle text: a win that reveals the hidden unknown weakness, a loss that teaches, a win that confirms one
	C.RUN["sector"] = 1
	var out: Array = C.nemAfterBattle("win", false, {})
	check(JSON.stringify(out).contains("reveal a weakness: old_hidden."), "after battle: a win reveals the unknown hidden weakness by its key")
	C = old_save(1183)
	var lout: Array = C.nemAfterBattle("loss", false, {"found": ["old_weak"]})
	check(JSON.stringify(lout).contains("Weakness found: old_weak."), "after battle: a loss that teaches names the unknown weakness by its key")
	C = old_save(1184)
	var wout: Array = C.nemAfterBattle("win", true, {"found": ["old_late"]})
	check(JSON.stringify(wout).contains("Weakness confirmed: old_late."), "after battle: a confirmed unknown weakness shows its key")

	# the after-battle summary: a real (stub) Nemesis battle where the unknown weakness was found
	C = old_save(1185)
	var cfg = {"kind": "battle", "fac": FAC, "nemesis": C.nemBattleCfg(), "node": null}
	C.battleScreen(cfg)
	check(C.B != null, "summary: the Nemesis battle starts from the old save")
	if C.B != null:
		C.B["nemFound"] = ["old_late"]
		C.act("battle", "win")
		var found := JSON.stringify([C.page, C.modal_d])
		check(found.contains("Weakness confirmed: old_late."), "summary: the after-battle summary names the unknown weakness by its key")

	# the intel reward that reveals a weakness
	C = old_save(1186)
	var iout = C.applyOutcome({"nemIntel": 1})
	check(JSON.stringify(iout).contains("Nemesis weakness revealed: old_hidden."), "intel: the intel reward names the unknown weakness by its key")

	print(("PASS" if fails == 0 else "FAIL") + " nem_unknown_key_test: %d failure(s)" % fails)
	quit(1 if fails > 0 else 0)
