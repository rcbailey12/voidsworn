extends SceneTree
# Issue 335 (Godot half): a tree pick made through the real campaign must reach the battle.
# One admiral per faction takes three branch picks and a capstone through campaign.gd lineagePick, then newRun,
# then start_battle, which reaches the rules through the same battle_setup hand-off godot/main/campaign_host.gd uses.
# Nothing here types RUN.lineage by hand. Before the fix the campaign stores short picks ("A:0:0") and rules.gd
# treeBuild looked only for the long TREE_FX keys, so only the capstone reached B.tree. This fails with three
# skills back and passes with four.
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
		c.RUN = null; c.SAVED_RUN = null   # picks are made between runs, as the game allows
		c.META["mastery"][id] = 230        # level 8: three branch picks and a capstone are earned
		for key in keys:
			check(c.lineagePick(key) == true, fac + ": lineagePick(" + key + ") was refused")
		c.newRun(id, fac)
		check(c.RUN != null and c.RUN["lineage"]["id"] == id, fac + ": newRun did not snapshot the admiral tree")
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
	print("PASS: real campaign picks reach the battle for all six factions (four skills each)." if failures == 0 else "FAIL: %d tree hand-off check(s) failed" % failures)
	quit(0 if failures == 0 else 1)
