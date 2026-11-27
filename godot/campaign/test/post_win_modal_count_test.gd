# Count the cards after the first win on 30 seeded runs. --report records the baseline on main.
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const RUNS := 30
const NEXT := ["prizeConfirm", "prizeStep", "salvageStep", "takeSalvage", "rewardNext", "takeBoon", "takeMod", "takeRelic", "takePerk"]

func _init() -> void:
	var counts := {}
	var totals := {}
	var bad := 0
	for seed in range(1, RUNS + 1):
		var trace := _count(seed)
		if trace.is_empty():
			bad += 1
			continue
		for card in trace: counts[card] = counts.get(card, 0) + 1
		totals[trace.size()] = totals.get(trace.size(), 0) + 1
	print("post-win cards on %d seeded runs: %s" % [RUNS, JSON.stringify(counts)])
	print("cards per win (cards: runs): %s" % JSON.stringify(totals))
	var ok: bool = bad == 0 and counts.get("victory", 0) == RUNS
	if not OS.get_cmdline_user_args().has("--report"):
		ok = _check_repairs() and ok and counts.get("promotions", 0) > 0 and not counts.has("salvage") and not counts.has("promote")
	print("PASS" if ok else "FAIL")
	quit(0 if ok else 1)

func _count(seed: int) -> Array[String]:
	var c = Campaign.new()
	var err: String = c.load_tables()
	if err != "":
		printerr(err)
		return []
	c.fixed_clock = true
	c.rng.rnd_seed(seed)
	c.newRun("vex", "voidsworn")
	c.mapScreen()
	c.act("enterNode", c.availableNodes()[0])
	if c.page.get("kind") != "battle":
		printerr("seed %d did not open the first battle" % seed)
		return []
	c.act("battle", "win")
	var trace: Array[String] = []
	var last := ""
	for step in range(30):
		if c.modal_d == null and c.page.get("kind") == "map" and not c.availableNodes().is_empty():
			if trace.count("promotions") > 1 or c.RUN["fleet"].any(func(s): return s["cap"]["pending"] > 0): break
			return trace
		if c.modal_d == null: break
		var kind: String = c.modal_d["kind"]
		var key := kind
		if kind == "promote":
			var ship = c.modal_d["data"]["ship"]
			key += str(ship["uid"]) + ":" + str(ship["cap"]["pending"])
		if kind == "promotions" and c.modal_d["data"]["ships"].size() != c.RUN["fleet"].filter(func(s): return s["cap"]["pending"] > 0).size(): break
		if key != last: trace.append(kind)
		last = key
		var acts: Array = c.screen_acts().filter(func(a): return a[2] == 1 and a[0] in NEXT)
		acts.sort_custom(func(a, b): return NEXT.find(a[0]) < NEXT.find(b[0]))
		if acts.is_empty(): break
		c.act(acts[0][0], acts[0][1])
	printerr("seed %d did not return to a route choice: %s" % [seed, trace])
	return []

func _check_repairs() -> bool:
	var c = Campaign.new()
	if c.load_tables() != "": return false
	c.fixed_clock = true
	var failures := 0
	for kind in ["drydock", "field"]:
		for choice in ["service", "stipend"]:
			c.rng.rnd_seed(1177)
			c.newRun("vex", "voidsworn")
			var n = c.RUN["map"]["cols"][0][0]
			n["type"] = kind
			var id: String = n["id"]
			var credits: float = c.RUN["credits"]
			var expected := []
			var hp_before := []
			var rate: float = (0.6 if kind == "drydock" else 0.2) * c.repairMult()
			if choice == "stipend": rate /= 2
			for s in c.RUN["fleet"]:
				var mx: float = c.derive(s)["maxHp"]
				s["hp"] = floor(mx / 2)
				hp_before.append(s["hp"])
				expected.append(s["hp"] + (ceil((mx - s["hp"]) * rate) if kind == "drydock" else c.jsround(mx * rate)))
			c.mapScreen(); c.act("enterNode", id)
			c.titleScreen(); c.act("continueRun")
			if c.modal_d == null or c.modal_d["kind"] != "repair_stop" or c.screen_acts().size() != 2 or c.RUN["credits"] != credits or _fleet_hp(c) != hp_before:
				failures += 1; printerr("%s did not restore both unpaid choices" % kind); continue
			c.act("repairStop", choice)
			c.act("repairStop", choice)
			var payout: int = (35 if kind == "drydock" else 15) if choice == "stipend" else 0
			if _fleet_hp(c) != expected or c.RUN["credits"] != credits + payout or not c.jt(c.findNode(id).get("done")) or c.modal_d != null:
				failures += 1; printerr("%s %s did not apply the expected hull and credits exactly once" % [kind, choice])
	print("repair stops: both choices at drydock and field repairs, including reload and repeat click (%d failed)" % failures)
	return failures == 0

func _fleet_hp(c) -> Array:
	return c.RUN["fleet"].map(func(s): return s["hp"])
