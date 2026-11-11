extends SceneTree
# Issue 335 (Godot half): a tree pick made through the real campaign must reach the battle.
# One admiral per faction takes three branch picks and a capstone through campaign.gd lineagePick, then newRun,
# then start_battle, which reaches the rules through the same battle_setup hand-off godot/main/campaign_host.gd uses.
# Nothing here types RUN.lineage by hand. Before the fix the campaign stores short picks ("A:0:0") and rules.gd
# treeBuild looked only for the long TREE_FX keys, so only the capstone reached B.tree. This fails with three
# skills back and passes with four.
# Issue 374: the run is saved with the real save function (saveRun) and read back through the real load path
# (load_save_text, the same pair persist_save and persist_load use and campaign parity's page reload uses), after
# every piece of in-memory state is dropped, then continued the way the title screen's Continue button does.
# The save is written before the repair's short-pick shape and read back after it.
const Campaign = preload("res://campaign/campaign.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _init() -> void:
	var c = Campaign.new()
	var error = c.load_tables()
	if error != "":
		printerr(error); quit(1); return
	c.persist_on = false
	var api = BattleAPI.new()
	error = api.load_rules()
	if error != "":
		printerr(error); quit(1); return
	c.battle_mode = "external"
	c.battle_setup = func(run, cfg):
		api.new_battle(run, cfg)
		return api.R.B
	# one admiral per faction, with three branch rows and a capstone that all carry a TREE_FX effect
	var cases := {
		"voidsworn": ["malek", ["malek:A:0:0", "malek:B:0:0", "malek:C:0:0", "malek:cap:1"]],
		"hegemony": ["kassar", ["kassar:A:0:0", "kassar:B:0:0", "kassar:C:0:0", "kassar:cap:0"]],
		"corsair": ["grax", ["grax:A:0:0", "grax:B:0:0", "grax:C:0:0", "grax:cap:0"]],
		"chorus": ["razormaw", ["razormaw:A:0:0", "razormaw:B:0:1", "razormaw:C:0:0", "razormaw:cap:0"]],
		"ithar": ["vaelen", ["vaelen:A:0:0", "vaelen:B:0:0", "vaelen:C:0:0", "vaelen:cap:1"]],
		"deathless": ["nekhet", ["nekhet:A:0:0", "nekhet:B:0:1", "nekhet:C:0:0", "nekhet:cap:0"]]
	}
	for fac in cases.keys():
		var id: String = cases[fac][0]
		var keys: Array = cases[fac][1]
		c.RUN = null; c.SAVED_RUN = null; c.B = null
		c.META = c.defaultMeta()
		c.META["mastery"][id] = 230        # level 8: three branch picks and a capstone are earned
		for key in keys:
			check(c.lineagePick(key) == true, fac + ": lineagePick(" + key + ") was refused")
		c.newRun(id, fac)                  # newRun ends in saveRun, so the real save function has run
		check(c.RUN != null and c.RUN["lineage"]["id"] == id, fac + ": newRun did not snapshot the admiral tree")
		c.saveRun()                        # the game's real save function: SAVED_RUN is the saved copy
		check(c.SAVED_RUN != null, fac + ": saveRun did not write the saved copy")
		var saved_text: String = c.save_text()   # exactly the text persist_save writes to user://
		# Close the game: every piece of state in memory goes, only the save text survives.
		c.RUN = null; c.SAVED_RUN = null; c.B = null; c.META = c.defaultMeta()
		c.load_save_text(saved_text)       # the game's real load path
		check(c.SAVED_RUN != null and c.SAVED_RUN["lineage"]["id"] == id, fac + ": the real load path did not restore the saved run")
		c.ACT_continueRun()                # the title screen's Continue button: the real way a saved run starts again
		check(c.RUN != null and c.RUN["lineage"]["id"] == id, fac + ": Continue did not restore the saved run")
		var cfg := {"kind": "battle", "fac": "hegemony", "col": 1, "seed": 7, "obj": "rout", "shape": "open", "map": "belt", "enemies": [{"tpl": "h_picket"}]}
		c.start_battle(cfg)
		check(c.B != null, fac + ": start_battle did not build a battle")
		var got := {}
		if c.B != null and c.B.get("tree") is Array:
			for s in c.B["tree"]: got[s["k"]] = s["key"]
		for key in keys:
			var fx = api.R.TREE_FX.get(key, null)
			check(fx != null, fac + ": " + key + " has no TREE_FX row (the check needs an effect to look for)")
			if fx == null: continue
			check(got.has(fx["k"]), fac + ": " + key + " (" + str(fx["k"]) + ") did not reach B.tree (got " + str(got.keys()) + ")")
			check(got.get(fx["k"]) == key, fac + ": " + str(fx["k"]) + " reached B.tree under key " + str(got.get(fx["k"])) + ", not " + key)
	# Issue 361: lineageNodes marks a row with no battle effect as waiting, from the same TREE_FX table the battle reads.
	# The campaign copy and the battle copy are the same exported table; a node with no entry is waiting, nothing else is.
	var fx_missing := 0
	for fx_key in api.R.TREE_FX.keys():
		if not c.TREE_FX.has(fx_key): fx_missing += 1
	check(fx_missing == 0 and c.TREE_FX.size() == api.R.TREE_FX.size(), "the campaign TREE_FX table is the battle TREE_FX table (" + str(fx_missing) + " rows missing)")
	var row_total := 0
	for id in c.LINEAGE_TREES.keys():
		var tree = c.LINEAGE_TREES[id]
		for b in tree["branches"].keys():
			for pair in tree["branches"][b]["tiers"]: row_total += pair.size()
		row_total += tree["capstones"].size()
	var node_count := 0
	var waiting_seen := 0
	var active_seen := 0
	for id in c.LINEAGE_TREES.keys():
		c.META["mastery"][str(id)] = 230
		for n in c.lineageNodes(str(id)):
			var key := str(n["key"])
			var expected: bool = not api.R.TREE_FX.has(key)
			check(n.has("waiting") and bool(n["waiting"]) == expected, "waiting flag for " + key)
			node_count += 1
			if bool(n.get("waiting", false)): waiting_seen += 1
			else: active_seen += 1
	check(node_count == row_total, "lineageNodes walks every tree row (walked " + str(node_count) + " of " + str(row_total) + ")")
	print("PASS: real campaign picks reach the battle for all six factions (four skills each), each run saved with saveRun and read back through load_save_text before the battle; lineageNodes marks " + str(waiting_seen) + " waiting rows and " + str(active_seen) + " active rows from the battle TREE_FX table." if failures == 0 else "FAIL: %d tree hand-off and waiting check(s) failed" % failures)
	quit(0 if failures == 0 else 1)
