extends SceneTree

const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const SECTORS := 3000
const REST_TYPES := ["shipyard", "drydock", "field"]

func _init() -> void:
	var campaign = CampaignScript.new()
	var err: String = campaign.load_tables()
	if not err.is_empty():
		printerr(err)
		quit(1)
		return
	var eligible := 0
	var two_exits := 0
	var same_type := 0
	var first_repeat := ""
	for seed_value in range(1, SECTORS + 1):
		var sector := 1 + (seed_value - 1) % 3
		campaign.rng.rnd_seed(seed_value)
		var map: Dictionary = campaign.genSector(sector)
		var problem := layout_problem(map)
		if not problem.is_empty():
			printerr("FAIL: seed %d, sector %d: %s" % [seed_value, sector, problem])
			quit(1)
			return
		var types_by_id := {}
		for col in map["cols"]:
			for stop in col: types_by_id[stop["id"]] = stop["type"]
		var next_types := {}
		for edge in map["edges"]:
			if not next_types.has(edge[0]): next_types[edge[0]] = []
			next_types[edge[0]].append(types_by_id[edge[1]])
		for col in range(5):
			for stop in map["cols"][col]:
				var exits: Array = next_types[stop["id"]]
				if col > 0:
					eligible += 1
					if exits.size() == 2: two_exits += 1
				if exits.size() == 2 and exits[0] == exits[1]:
					same_type += 1
					if first_repeat.is_empty():
						first_repeat = "seed %d, stop %s, type %s" % [seed_value, stop["id"], exits[0]]
	var rate := 100.0 * two_exits / eligible
	print("Sector routes: %d sectors, %d/%d stops in columns 1 to 4 with two exits (%.2f%%), %d same-type forks" % [SECTORS, two_exits, eligible, rate, same_type])
	if same_type > 0: printerr("First same-type fork: " + first_repeat)
	var passed := rate >= 80.0 and same_type == 0
	print("PASS: sector route choices" if passed else "FAIL: expected at least 80% two-exit stops and zero same-type forks")
	quit(0 if passed else 1)

func layout_problem(map: Dictionary) -> String:
	var cols: Array = map["cols"]
	if cols.size() != 7 or cols[0].size() != 1 or cols[6].size() != 1 or cols[6][0]["type"] != "boss":
		return "expected seven columns with a single start and a single boss at column 6"
	if cols[5].is_empty() or not cols[5].all(func(stop): return stop["type"] in REST_TYPES):
		return "expected only rest stops in column 5"
	if not cols[5].any(func(stop): return stop["type"] in ["shipyard", "drydock"]):
		return "expected a shipyard or drydock in column 5"
	var columns := {}
	for col in cols:
		for stop in col: columns[stop["id"]] = stop["col"]
	var incoming := {}
	var outgoing := {}
	for edge in map["edges"]:
		var source: String = edge[0]
		var target: String = edge[1]
		if not columns.has(source) or not columns.has(target) or columns[target] != columns[source] + 1:
			return "edge %s to %s must join consecutive columns" % [source, target]
		if not outgoing.has(source): outgoing[source] = {}
		if outgoing[source].has(target): return "duplicate edge %s to %s" % [source, target]
		outgoing[source][target] = true
		incoming[target] = true
	for id in columns:
		if columns[id] > 0 and not incoming.has(id): return "unreachable stop " + id
		if columns[id] < 6 and not outgoing.has(id): return "dead end at " + id
	return ""
