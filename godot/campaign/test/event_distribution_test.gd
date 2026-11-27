# With -- --compare [output.json], also compare the seeded routes to the issue 1149 baseline.
extends SceneTree

const CampaignScript = preload("res://campaign/campaign.gd")
const Seed = preload("res://rules/battle_api.gd").JSM
const RUNS := 64
const METRICS := ["credits", "xp", "relics", "refits", "ships", "hull", "marks", "wing_perks", "intel", "clock"]

const BASELINE := "res://campaign/test/fixtures/event_distribution_a3b9f555.json"

# These ids and choice keys are read from existing saves and flags.
const SAVED_KEYS := {
	"derelict": ["0", "1", "cut", "3"],
	"beacon": ["0", "tow", "2", "3"],
	"astropath": ["0", "shield", "2"],
	"merc": ["0", "oath", "2"],
	"storm": ["0", "shields", "2"],
	"seer": ["0", "song", "2"],
	"wright": ["0", "pay", "2"],
	"moon": ["0", "flak", "2"],
	"shrine": ["offer", "chalk", "relic", "leave"],
	"deserters": ["0", "question", "2"],
	"cache": ["0", "both", "2"],
	"tithe": ["crack", "lance", "leave"],
	"pilot": ["take", "wing", "leave"],
	"reactor": ["vent", "refit", "metal", "pay"],
	"squall": ["ride", "shield", "round"],
	"broker": ["buy", "debt", "leave"],
	"bait": ["loud", "sweep", "ignore"],
	"spawn": ["burn", "harvest", "feed"],
	"lament": ["listen", "join", "archive"],
	"tomb": ["wake", "map"],
	"tombhome": ["wake", "tithe"],
	"mutiny": ["pay", "discipline", "talk"],
	"convoy": ["escort", "trade", "shake"],
	"battlefield": ["salvage", "wings", "leave"],
	"scout": ["hunt", "torp", "ignore"],
	"defector": ["question", "ransom", "enlist"],
	"dock": ["use", "frame", "leave"],
	"well": ["sling", "sails", "round"],
	"auction": ["bid", "swap", "leave"],
	"saboteur": ["search", "face", "ignore"],
	"veterans": ["pay", "oath", "leave"],
	"haven": ["raid", "tribute", "recruit", "leave"],
	"quiet": ["rest", "drill"],
}
const FACTION_CARDS := ["merc", "mutiny", "pilot", "deserters", "veterans", "reactor", "convoy", "auction"]
const HUMAN_COPY := [
	"your crew", "the crews", "below decks", "captain", "engineers report",
	"stranded pilot", "retired admiral", "hire her", "pay a bonus", "crew her", "signals officer",
]
var failures := 0

func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + why)

func check_copy(line: String, context: String) -> void:
	var lower := line.to_lower()
	for fragment in HUMAN_COPY:
		check(not lower.contains(fragment), "%s uses human fleet wording: %s" % [context, line])

func option_key(option: Dictionary, index: int) -> String:
	return str(option.get("k", str(index)))

func check_lookup_keys(c: CampaignScript) -> Dictionary:
	var cards := {}
	check(c.EVENT_FALLBACK == "quiet", "the quiet fallback lookup key changed")
	for card in c.EVENTS:
		var id: String = card["id"]
		check(not cards.has(id), "duplicate event lookup key: " + id)
		cards[id] = card
		var keys := []
		for i in range(card["o"].size()):
			keys.append(option_key(card["o"][i], i))
		check(keys == SAVED_KEYS.get(id), "%s choice keys: expected %s, got %s" % [id, SAVED_KEYS.get(id), keys])
	for id in SAVED_KEYS:
		check(cards.has(id), "missing event lookup key: " + id)
	return cards

func check_card(c: CampaignScript, base: Dictionary, card: Dictionary) -> void:
	var id: String = base["id"]
	var faction: String = c.RUN["fac"]
	var context := "%s/%s" % [faction, id]
	var scan_copy := faction in ["chorus", "deathless"]
	var variant: Dictionary = base.get("v", {}).get(faction, {})
	check(card["t"] == variant.get("t", base["t"]) and card["b"] == variant.get("b", base["b"])
		and card["o"] == variant.get("o", base["o"]), context + " showed the wrong faction copy")
	check(card["id"] == id, context + " changed the event lookup key")
	check(card["o"].size() == base["o"].size(), context + " changed the choice count")
	check(not card["t"].strip_edges().is_empty() and not card["b"].strip_edges().is_empty(), context + " has no title or body")
	if scan_copy:
		check_copy(card["t"], context)
		check_copy(card["b"], context)
		if id in FACTION_CARDS:
			check(card["t"] != base["t"] and card["b"] != base["b"], context + " is missing its faction voice")
	if card["o"].size() != base["o"].size():
		return
	var actions := c.screen_acts()
	check(actions.size() == card["o"].size(), context + " did not show every choice")
	check(actions.any(func(a): return a[0] == "eventChoice" and a[2] == 1), context + " has no available choice")
	for i in range(card["o"].size()):
		var option: Dictionary = card["o"][i]
		var original: Dictionary = base["o"][i]
		var key := option_key(original, i)
		var choice_context := context + "/" + key
		check(not option["l"].strip_edges().is_empty() and option["s"] is String, choice_context + " has invalid choice text")
		if i < actions.size():
			check(actions[i][0] == "eventChoice" and str(actions[i][1]) == str(i)
				and (actions[i][2] == 1) == c.eventOptOk(option), choice_context + " has the wrong action or availability")
		var mechanics := option.duplicate()
		mechanics.erase("l")
		mechanics.erase("s")
		var expected := original.duplicate()
		expected.erase("l")
		expected.erase("s")
		check(mechanics == expected, choice_context + " changed its choice key, requirements, flags or reward")
		var flags: Dictionary = c.RUN["flags"].duplicate()
		c.eventFlags(card, option, i)
		check(c.RUN["flags"].get(id) == key, choice_context + " did not write its saved choice key")
		c.RUN["flags"] = flags
		if scan_copy:
			check_copy(option["l"], choice_context)
			check_copy(option["s"], choice_context)
			check_copy(c.needText(option.get("need")), choice_context)
			check_receipt(c, option, choice_context)

func check_receipt(c: CampaignScript, option: Dictionary, context: String) -> void:
	var need_faction = option.get("need", {}).get("fac")
	if need_faction != null and c.RUN["fac"] not in (need_faction if need_faction is Array else [need_faction]):
		return
	var outcome = option["r"]
	if outcome is Dictionary and outcome.has("fight"):
		return
	# Use the real outcome text for resource-gated choices too. Restore the fleet after each probe.
	var run: Dictionary = c.RUN
	var uid: int = c.UID
	c.RUN = run.duplicate(true)
	for line in c.applyOutcome(outcome):
		check_copy(line, context + " result")
	c.RUN = run
	c.UID = uid

func check_cards(c: CampaignScript, cards: Dictionary) -> void:
	if failures != 0:
		return
	for faction in c.RUN_FACTIONS:
		c.META = c.defaultMeta()
		c.UID = 1
		c.fixed_clock = true
		c.seed_rng(1)
		c.newRun("vex", faction)
		var eligible := {}
		for id in cards:
			if id != c.EVENT_FALLBACK and faction not in cards[id].get("not", []):
				eligible[id] = true
		var draws := eligible.size()
		for i in range(draws + 1):
			c.eventScreen(null)
			var id: String = c.RUN["seenEvents"].back()
			var card: Dictionary = c.modal_d["data"]["ev"]
			if i == draws:
				check(id == c.EVENT_FALLBACK, "%s never reached the quiet fallback" % faction)
			else:
				check(eligible.erase(id), "%s drew an ineligible or repeated event: %s" % [faction, id])
			if cards.has(id):
				check_card(c, cards[id], card)
		check(eligible.is_empty(), "%s did not draw these eligible events: %s" % [faction, eligible.keys()])

	check(CampaignScript.BattleAPI.nem_entry(c.NEM_TRAITS, "boarders", "chorus")["n"] == "Breach broods",
		"Chorus boarders retain their key and use the biological name")
	check(CampaignScript.BattleAPI.nem_entry(c.NEM_WEAK, "flank", "chorus")["n"] == "Thin aft hide",
		"Chorus flank retains its key and uses the biological name")
	check(CampaignScript.BattleAPI.nem_entry(c.NEM_WEAK, "flank", "corsair")["n"] == "Thin stern plating",
		"Other factions still use the base weakness name")

func state(c: CampaignScript) -> Dictionary:
	var run: Dictionary = c.RUN
	var s := {"credits": run["credits"], "xp": 0, "relics": run["relics"].size(),
		"refits": run["inventory"].size(), "ships": run["fleet"].size(), "hull": 0,
		"marks": 0, "wing_perks": 0, "intel": 0, "clock": run["nemClock"]}
	for ship in run["fleet"]:
		s["xp"] += ship["cap"]["xp"]
		s["refits"] += ship["mods"].size()
		s["hull"] += ship["hp"]
		s["marks"] += ship["mk"]
		s["wing_perks"] += ship.get("wingVet", {}).get("perks", []).size()
	for nem in run["nems"].values():
		s["intel"] += nem["revealed"].size()
	return s

func add_delta(row: Dictionary, before: Dictionary, after: Dictionary) -> void:
	for key in METRICS:
		row[key] = row.get(key, 0) + after[key] - before[key]

func play(faction: String, seed: int, rows: Dictionary, total: Dictionary) -> void:
	var route_rng := RandomNumberGenerator.new()
	route_rng.seed = seed
	var c := CampaignScript.new()
	var err := c.load_tables()
	if err != "":
		check(false, err)
		return
	c.META = c.defaultMeta()
	c.fixed_clock = true
	c.seed_rng(seed)
	c.newRun("vex", faction)
	c.mapScreen()

	var event_id := ""
	var event_node := ""
	var before := {}
	for step in range(250):
		if c.ended:
			total["wins"] += int(c.page["data"]["victory"])
			return
		var acts := c.screen_acts().filter(func(a): return a[2] == 1)
		if c.modal_d != null and c.modal_d["kind"] == "event" and not c.cur_event.get("arc", false):
			event_id = c.cur_event["id"]
			if faction in ["chorus", "deathless"]:
				var base: Dictionary = c.EVENTS.filter(func(e): return e["id"] == event_id)[0]
				check(c.modal_d["data"]["ev"] == c._event_for_faction(base),
					"%s/%s did not show its faction card" % [faction, event_id])
			event_node = c.RUN["curNode"]
			before = state(c)
			var row: Dictionary = rows[event_id]
			row["draws"] += 1
			var choice: Array = acts[route_rng.randi_range(0, acts.size() - 1)]
			var option: Dictionary = c.cur_event["o"][int(choice[1])]
			var key: String = option_key(option, int(choice[1]))
			row["choices"][key] = row["choices"].get(key, 0) + 1
			c.act(choice[0], choice[1])
			check(c.RUN["flags"].get(event_id) == key, "%s changed its saved option key" % event_id)
			if c.page["kind"] == "battle":
				row["fights"] += 1
				check(c.page["data"]["cfg"].get("eventRelic", false), "%s lost its event battle route" % event_id)
			elif c.modal_d == null or c.modal_d["kind"] != "event_result":
				check(false, "%s lost its event result route" % event_id)
			elif faction in ["chorus", "deathless"]:
				for line in c.modal_d["data"]["lines"]:
					check_copy(line, "%s/%s result" % [faction, event_id])
		else:
			var action := choose(c, acts, route_rng)
			if action.is_empty():
				check(false, "%s seed %d stalled on %s %s" % [faction, seed, c.page["kind"], str(acts)])
				return
			c.act(action[0], action[1])
		if event_id != "" and c.RUN != null and c.RUN["curNode"] != event_node:
			add_delta(rows[event_id], before, state(c))
			event_id = ""

	check(false, "%s seed %d did not finish" % [faction, seed])

func choose(c: CampaignScript, acts: Array, rng: RandomNumberGenerator) -> Array:
	if c.modal_d == null and c.page["kind"] == "map":
		var nodes := acts.filter(func(a): return a[0] == "enterNode")
		var events := nodes.filter(func(a): return c.findNode(a[1])["type"] == "event")
		var pool := nodes if events.is_empty() else events
		return [] if pool.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]
	for preferred in ["battle", "refuseCoreEat", "repairAll", "repairStop", "prizeConfirm",
		"takeRelic", "takeMod", "takeBoon", "pickAspect", "eventChoice", "closeModal", "beat3",
		"storyCore", "rewardNext", "takeSalvage", "takePerk", "leaveYard", "boonDecline"]:
		for a in acts:
			if a[0] == preferred:
				return a
	return []

func seeded_report(c: CampaignScript) -> Dictionary:
	var report := {}
	for faction in c.RUN_FACTIONS:
		var rows := {}
		for event in c.EVENTS:
			rows[event["id"]] = {"draws": 0, "fights": 0, "choices": {}}
		var total := {"runs": RUNS, "wins": 0, "draws": 0, "fights": 0}
		for seed in range(1, RUNS + 1):
			play(faction, seed, rows, total)
		for row in rows.values():
			total["draws"] += row["draws"]
			total["fights"] += row["fights"]
			for key in METRICS:
				total[key] = total.get(key, 0) + row.get(key, 0)
		check(total["wins"] == RUNS, "%s did not complete all seeded campaigns" % faction)
		report[faction] = {"total": total, "events": rows}
		print("%s %s" % [faction, JSON.stringify(total)])
	return report

func compare_rows(context: String, expected: Dictionary, actual: Dictionary) -> void:
	var keys := expected.merged(actual).keys()
	keys.sort()
	for key in keys:
		var before = expected.get(key)
		var after = actual.get(key)
		if Seed.canon(before) != Seed.canon(after):
			check(false, "%s/%s\n  expected: %s\n  actual:   %s"
				% [context, key, JSON.stringify(before, "", true, true), JSON.stringify(after, "", true, true)])

func compare_report(report: Dictionary) -> void:
	var expected = JSON.parse_string(FileAccess.get_file_as_string(BASELINE))
	if not (expected is Dictionary):
		check(false, "Cannot read baseline: " + BASELINE)
		return
	var factions: Array = expected.merged(report).keys()
	factions.sort()
	for faction in factions:
		if not expected.has(faction) or not report.has(faction):
			check(false, "%s is missing from the %s report" % [faction, "baseline" if report.has(faction) else "current"])
			continue
		compare_rows(faction + "/total", expected[faction]["total"], report[faction]["total"])
		compare_rows(faction, expected[faction]["events"], report[faction]["events"])

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var compare := not args.is_empty()
	if compare and (args[0] != "--compare" or args.size() > 2):
		printerr("Usage: event_distribution_test.gd [-- --compare [output.json]]")
		quit(1)
		return
	var c := CampaignScript.new()
	var err := c.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return
	check_cards(c, check_lookup_keys(c))
	var label := "event invariants"
	if compare and failures == 0:
		label = "event invariants and seeded comparison"
		var report := seeded_report(c)
		compare_report(report)
		if args.size() == 2:
			var out := FileAccess.open(args[1], FileAccess.WRITE)
			if out == null:
				check(false, "Cannot write report: " + args[1])
			else:
				out.store_string(JSON.stringify(report, "\t", true, true) + "\n")
	print(label + ": " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
