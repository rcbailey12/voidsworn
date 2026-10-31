extends SceneTree
# Exact counterpart of fix_vectors.js; executes real campaign functions.
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var C

func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() < 1: printerr("Provide output.jsonl and optional map-seeds"); quit(2); return
	var seeds = int(args[1]) if args.size() > 1 else 1500
	if seeds < 1: printerr("map-seeds must be positive"); quit(2); return
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true
	var output = FileAccess.open(args[0], FileAccess.WRITE)
	if output == null: printerr("Cannot open vector output"); quit(2); return
	var total = 0
	for seed in range(1, seeds + 1):
		for sector in range(1, 4):
			C.META = C.defaultMeta(); C.RUN = C.runDefaults(); C.RUN["sector"] = sector
			C.RUN["foes"] = null; C.RUN["condsUsed"] = []; C.RUN["regionsUsed"] = []
			JSM.rnd_seed(seed * 31 + sector)
			var map = C.genSector(sector)
			output.store_line(JSON.stringify({"kind": "map", "seed": seed, "sector": sector,
				"hash": JSM.sha256(JSM.canon(map, "", {}, true)), "rng": JSM.rng_s & 0xFFFFFFFF,
				"elite": map["cols"][4].any(func(n): return n["type"] == "elite")}))
			total += 1
	var cases = [
		["three identical names", 3, {"upgradeOne": 1, "repairOne": 1}, false],
		["two ships", 2, {"upgradeOne": 1, "repairOne": 1}, false],
		["single ship", 1, {"upgradeOne": 1, "repairOne": 1}, false],
		["repair only", 2, {"repairOne": 1}, false],
		["upgrade only", 2, {"upgradeOne": 1}, false],
		["max Mark", 3, {"upgradeOne": 1, "repairOne": 1}, true]
	]
	for i in range(cases.size()):
		var case = cases[i]; var label = case[0]; var count = case[1]; var outcome = case[2]
		C.META = C.defaultMeta(); C.RUN = C.runDefaults(); C.B = null; C.UID = 1; JSM.rnd_seed(90210 + i)
		var fleet = []
		for j in range(count):
			var sh = C.newShip("warden"); sh["name"] = "Same display name"
			if case[3] and j == 0: sh["mk"] = 3
			sh["hp"] = JSM.jsround(float(C.derive(sh)["maxHp"]) * [0.2, 0.5, 0.8][j]); fleet.append(sh)
		C.RUN["fleet"] = fleet; C.RUN["flagUid"] = fleet[0]["uid"]
		var before = fleet.map(func(sh): return sh["hp"])
		C.applyOutcome(outcome)
		var holds = fleet[0]["hp"] == C.derive(fleet[0])["maxHp"]
		if count > 1:
			holds = holds and (fleet[1]["hp"] == C.derive(fleet[1])["maxHp"] if outcome.has("upgradeOne") and outcome.has("repairOne") else fleet[1]["hp"] == before[1])
		if count > 2: holds = holds and fleet[2]["hp"] == before[2]
		var state = fleet.map(func(sh): return {"uid": sh["uid"], "hp": sh["hp"], "mk": sh["mk"], "maxHp": C.derive(sh)["maxHp"]})
		output.store_line(JSON.stringify({"kind": "shipwright", "label": label,
			"hash": JSM.sha256(JSM.canon(state, "", {}, true)), "state": state,
			"contractHolds": holds, "rng": JSM.rng_s & 0xFFFFFFFF}))
		total += 1
	output.close()
	print(total, " vectors written")
	quit()
