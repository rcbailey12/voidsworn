# Pass an absolute JSON path after -- to save per-event counts and net rewards.
extends SceneTree

const CampaignScript = preload("res://campaign/campaign.gd")
const Seed = preload("res://rules/battle_api.gd").JSM
const RUNS := 64
const METRICS := ["credits", "xp", "relics", "refits", "ships", "hull", "marks", "wing_perks", "intel", "clock"]

# One canonical row set per faction from main a3b9f555. The band is exact equality.
const MAIN := {
	"chorus": "cdb2b040fed65c1b9a5b831c9a033d96694976bfde26fca3174cf6f475106b7d",
	"corsair": "1953add5bc1aad50839426d9bbfa576dc44c7b093c3810d2b4e1c2d5a49fc938",
	"deathless": "9e11f0657802b3bb11b6645165b9cb7fa95af649ddc3e618464e24ecb6caef65",
	"hegemony": "9200c28f72550d4741aa9364162f363e7ec51119c0286f87cfd12de38aadc798",
	"ithar": "b3ff3d24a8f3f42dd978ddf7d15653d4af1786ff65b2adce27d5861f31358efd",
	"voidsworn": "707fb16a1f5fdcc0343e57f26f29db9b4509b0db47e715a631b84891c80d0e93",
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
	for fragment in HUMAN_COPY:
		check(not line.to_lower().contains(fragment), "%s uses human fleet wording: %s" % [context, line])

func check_cards(c: CampaignScript) -> void:
	for faction in ["chorus", "deathless"]:
		c.META = c.defaultMeta()
		c.UID = 1
		c.fixed_clock = true
		Seed.rnd_seed(1)
		c.newRun("vex", faction)
		var available := 0
		for base in c.EVENTS:
			if faction in base.get("not", []):
				continue
			if base["id"] != c.EVENT_FALLBACK:
				available += 1
			var card := c._event_for_faction(base)
			var context := "%s/%s" % [faction, base["id"]]
			check_copy(card["t"], context)
			check_copy(card["b"], context)
			check(card["id"] == base["id"] and card["o"].size() == base["o"].size(), context + " changed keys or option count")
			if base["id"] in FACTION_CARDS:
				check(card["t"] != base["t"] and card["b"] != base["b"], context + " is missing its faction voice")
			for i in range(base["o"].size()):
				var option: Dictionary = card["o"][i]
				var original: Dictionary = base["o"][i]
				var key: String = str(original.get("k", i))
				check_copy(option["l"], context + "/" + key)
				check_copy(option["s"], context + "/" + key)
				check_copy(c.needText(option.get("need")), context + "/" + key)
				var mechanical := option.duplicate()
				mechanical.erase("l")
				mechanical.erase("s")
				var expected := original.duplicate()
				expected.erase("l")
				expected.erase("s")
				check(mechanical == expected, context + "/" + key + " changed its choice, requirements, flags or reward")

		for i in range(available):
			var draw := c.nextEvent()
			check(draw["id"] != c.EVENT_FALLBACK and faction not in draw.get("not", []),
				"%s drew the fallback too early or drew a barred event" % faction)
		check(c.nextEvent()["id"] == c.EVENT_FALLBACK, "%s never reached the quiet fallback" % faction)

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
	Seed.rnd_seed(seed)
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
			var key: String = str(option.get("k", choice[1]))
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
	for preferred in ["battle", "refuseCoreEat", "repairAll", "prizeConfirm", "salvageStep",
		"takeRelic", "takeMod", "takeBoon", "pickAspect", "eventChoice", "closeModal", "beat3",
		"storyCore", "rewardNext", "prizeStep", "takeSalvage", "takePerk", "leaveYard", "boonDecline"]:
		for a in acts:
			if a[0] == preferred:
				return a
	return []

func _init() -> void:
	var c := CampaignScript.new()
	var err := c.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return
	check_cards(c)
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
		var digest := Seed.sha256(Seed.canon(rows))
		check(digest == MAIN.get(faction), "%s event rows differ from main (%s)" % [faction, digest])
		report[faction] = {"total": total, "events": rows}
		print("%s %s" % [faction, JSON.stringify(total)])
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var out := FileAccess.open(args[0], FileAccess.WRITE)
		if out == null:
			check(false, "Cannot write report: " + args[0])
		else:
			out.store_string(JSON.stringify(report, "\t") + "\n")
	print("event distribution: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

