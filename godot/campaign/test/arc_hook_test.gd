# G3: the story arc hook (campaign.gd arcs_on, arc_source, arc_chose_cb, arc_end_cb). Headless:
#   godot --headless --path godot --script res://campaign/test/arc_hook_test.gd
# Checks: with arcs off, or on with no arc file, a whole run is identical to a run without the hook; with a test card, the card
# opens after the sector I intro and after each sector change, its choice pays out and writes its flag without completing a map
# node, the story callbacks fire, and a run that played beat 3 reports its end.
extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM
const CampaignScript = preload("res://campaign/campaign.gd")

var shown: Array = []
var chosen: Array = []
var ended: Array = []
var fails := 0

func check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1; printerr("FAIL: " + what)

func card(beat: int) -> Dictionary:
	shown.append(beat)
	return {"id": "arc_%s_%d" % [C0.RUN["fac"], beat] + "a", "t": "Test beat " + str(beat), "b": "A test card.", "arc": true,
		"o": [{"k": "take", "l": "Take the money", "s": "+25 credits", "r": {"cred": 25}, "fl": {"mercy": 1}},
			{"k": "rich", "l": "Too dear", "s": "costs 99999", "r": {"cost": 99999}}],
		"outs": {"take": "You took it."}}

var C0
func play(seed: int, mode: String) -> Dictionary:
	var C = CampaignScript.new(); C0 = C
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return {}
	C.fixed_clock = true
	if mode != "plain":
		C.arcs_on = mode != "off"
		C.arc_source = (func(_b): return {}) if mode == "empty" else card
		C.arc_chose_cb = func(ev, k): chosen.append([ev["id"], k])
		C.arc_end_cb = func(won): ended.append(won)
	JSM.rnd_seed(seed); C.UID = 1; C.META = C.defaultMeta(); C.SAVED_RUN = null; C.ended = false
	C.titleScreen()
	var s := seed; var steps := 0; var streak := 0
	const STAY = ["closeModal", "buyHull", "buyMod", "repair", "repairAll", "upgradeMk", "sellShip", "sellConfirm", "yardFleet", "equip", "unequip", "promote", "fleetScreen", "pickFaction", "pickAdmiral", "optAlt", "optCmd", "optHeat", "progTab", "buyVariant", "c3retreat", "c3retreatNo", "factionVerb", "buyTrack"]
	var trail := PackedStringArray(); var maxs := 0
	while not C.ended and steps < 4000:
		steps += 1
		if C.RUN != null:
			maxs = max(maxs, int(C.RUN["sector"]))
			if C.modal_d == null or not C.jt(C.modal_d["data"].get("ev", {}).get("arc")): trail.append(JSM.sha256(JSM.canon(C.RUN, "", {"t0": 1, "flags": 1, "credits": 1}, true)))
		if C.modal_d != null and C.modal_d["kind"] == "event" and C.jt(C.cur_event.get("arc")):
			var cr0 = float(C.RUN["credits"]); var node0 = C.RUN.get("curNode"); var nd0 = C.findNode(node0) if node0 != null else null; var done0 = C.jt(nd0.get("done")) if nd0 != null else false
			check(C.screen_acts()[1][2] == 0, "an arc option the player cannot afford is disabled")
			C.act("eventChoice", "0")
			check(float(C.RUN["credits"]) == cr0 + 25, "the arc choice pays its credits")
			check(C.RUN["flags"].get(C.cur_event["id"]) == "take", "the arc choice writes its flag")
			check(float(C.RUN["flags"].get("mercy", 0)) >= 1, "the arc choice adds its counters")
			check(C.RUN.get("curNode") == node0 and (nd0 == null or C.jt(nd0.get("done")) == done0), "an arc card completes no map node")
			check(C.modal_d != null and C.modal_d["kind"] == "event_result" and C.modal_d["data"]["lines"][0] == "You took it.", "the result opens with the card's outcome line")
			continue
		var acts = C.screen_acts().filter(func(x): return x[2] == 1 and not (x[0] in ["legacy", "help", "saveQuit", "title", "abandonRun"]))
		if streak >= 8:
			var go = acts.filter(func(x): return not (x[0] in STAY))
			if go.size() > 0: acts = go
		if acts.is_empty(): break
		s = (s * 1103515245 + 12345) % 2147483648
		var x = acts[(s >> 16) % acts.size()]
		if x[0] == "battle": x = ["battle", "loss" if (s >> 16) % 40 == 0 else "win", 1]
		if x[0] == "eventChoice" and C.jt(C.cur_event.get("arc")): continue
		streak = streak + 1 if x[0] in STAY else 0
		C.act(x[0], x[1])
	return {"canon": JSM.canon(C.META, "", {"updated": 1, "runAt": 1}, true) + str(JSM.rng_s), "trail": trail, "sector": maxs, "ended": C.ended}

func _init() -> void:
	var seeds = [11, 12, 13, 14]
	if OS.get_cmdline_user_args().size() > 0: seeds = [int(OS.get_cmdline_user_args()[0])]
	for seed in seeds:
		var a = play(seed, "plain"); var b = play(seed, "off"); var c = play(seed, "empty")
		check(a["canon"] == b["canon"] and a["trail"] == b["trail"], "seed %d: arcs off changes nothing" % seed)
		check(a["trail"] == c["trail"], "seed %d: arcs on without an arc file changes nothing, step by step" % seed)
		check(a["canon"] == c["canon"], "seed %d: arcs on without an arc file changes nothing" % seed)
		shown.clear(); chosen.clear(); ended.clear()
		var d = play(seed, "on")
		check(d["ended"], "seed %d: the run with arc cards ends" % seed)
		check(shown.size() == d["sector"] and shown == range(1, d["sector"] + 1), "seed %d: one card per sector reached (%s, sector %d)" % [seed, str(shown), d["sector"]])
		check(chosen.size() == shown.size(), "seed %d: the story hears every choice" % seed)
		check(ended.size() == (1 if d["sector"] >= 3 else 0), "seed %d: arc_end only after beat 3 (%s)" % [seed, str(ended)])
		print("seed %d: sector %d, cards %s, end %s" % [seed, d["sector"], str(shown), str(ended)])
	print("arc hook: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails > 0 else 0)
