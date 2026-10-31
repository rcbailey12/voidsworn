extends SceneTree
const Rules = preload("res://rules/rules.gd")
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func clean(v: Variant) -> Variant:
	if v is float and (v != floor(v) or absf(v) >= 9007199254740992.0): return "d:" + JSM.hex64(v)
	if v is Array:
		var a = []
		for x in v: a.append(clean(x))
		return a
	if v is Dictionary:
		var out = {}
		for k in v:
			if not ["t", "ship", "log", "prog", "cfg"].has(k) and v[k] != null: out[k] = clean(v[k])
		return out
	return v
func set_of(values: Variant) -> Variant:
	if values == null: return null
	var out = {}
	for k in values: out[k] = true
	return out
func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1: printerr("output file required"); quit(2); return
	var input = JSON.parse_string(FileAccess.get_file_as_string("res://codex/pilot_input.json")); var out = FileAccess.open(args[0], FileAccess.WRITE); var count = 0
	for raw_test in input["battles"]:
		var r = Rules.new(); var err = r.load_tables("res://rules/data/tables.json")
		if err != "": printerr(err); quit(1); return
		var test = r._dec(raw_test)
		r.B = test["battle"].duplicate(true); r.RUN = test["run"].duplicate(true)
		r.BW = int(test["globals"]["BW"]); r.BH = int(test["globals"]["BH"]); r.UID = int(test["globals"]["UID"]); r.ARENA = test["globals"]["ARENA"]
		r.CUT = set_of(test["globals"]["CUT"]); r.SOLID = set_of(test["globals"]["SOLID"]); JSM.rnd_seed(int(test["seed"]))
		var ok = r.useCommand("player"); r.flush_deferred()
		if r.not_ported != "": printerr(r.not_ported); quit(1); return
		out.store_line(JSON.stringify({"kind":"pilot_battle", "case":test["id"], "ok":ok, "state":clean(r.B), "rng":JSM.rng_s & 0xFFFFFFFF})); count += 1
	for test in input["rewards"]:
		var c = Campaign.new(); var err = c.load_tables()
		if err != "": printerr(err); quit(1); return
		c.fixed_clock = true; c.persist_on = false; c.META = test["meta"].duplicate(true); c.RUN = test["run"].duplicate(true)
		var ended = c.RUN
		c.endRun(test["profile"]["win"])
		var lineage_state = c.META["lineageV1"].duplicate(true); var encoded = JSON.parse_string(c.save_text())
		if encoded["meta"]["lineageV1"] != lineage_state: printerr("native save dropped lineage state"); quit(1); return
		out.store_line(JSON.stringify({"kind":"pilot_reward", "case":test["profile"]["id"], "namespace":lineage_state, "legacyMastery":c.META["mastery"]["vaelen"], "masteryXP":c.masteryXP("vaelen"), "carry":{"mxGain":ended["carry"]["mxGain"], "mx0":ended["carry"]["mx0"], "mx1":ended["carry"]["mx1"]}, "keepThis":c.META["keepThis"]})); count += 1
	for test in input["snapshots"]:
		var c = Campaign.new(); var err = c.load_tables()
		if err != "": printerr(err); quit(1); return
		c.fixed_clock = true; c.persist_on = false; c.META = test["meta"].duplicate(true); c.UID = 1; JSM.rnd_seed(90210)
		c.newRun(test["profile"]["admiral"], test["profile"]["fac"], {})
		var snapshot = c.RUN.get("lineagePilot"); var persisted = c.SAVED_RUN.get("lineagePilot")
		if snapshot is Dictionary: snapshot = snapshot.duplicate(true)
		if persisted is Dictionary: persisted = persisted.duplicate(true)
		c.META["lineageV1"]["lines"]["vaelen"]["picks"] = []
		if c.RUN.get("lineagePilot") != snapshot or c.SAVED_RUN.get("lineagePilot") != persisted: printerr("run snapshot aliases META"); quit(1); return
		out.store_line(JSON.stringify({"kind":"pilot_snapshot", "case":test["profile"]["id"], "snapshot":snapshot, "persisted":persisted, "detached":true})); count += 1
	out.close(); print(count, " native Godot pilot records"); quit()
