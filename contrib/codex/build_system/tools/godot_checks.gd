extends SceneTree
const Model = preload("res://codex/lineage.gd")
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1: printerr("output.jsonl required"); quit(2); return
	var l = Model.new()
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://codex/catalog.json"))
	var roster = JSON.parse_string(FileAccess.get_file_as_string("res://codex/roster.json"))
	if not l.configure(catalog, roster): printerr(l.error); quit(1); return
	var input = JSON.parse_string(FileAccess.get_file_as_string("res://codex/input.json"))
	var out = FileAccess.open(args[0], FileAccess.WRITE); var records = 0
	if out == null: printerr("cannot open output"); quit(2); return
	for c in input["cases"]:
		var state = l.new_state(c["masteries"]); var wallet = c.get("wallet", 200)
		for i in range(c["ops"].size()):
			var op = c["ops"][i]; var result = null; var detail = null; var ok = true
			if op["op"] == "choose": result = l.choose(state, op["id"], op["key"], op.get("options", {}))
			elif op["op"] == "respec":
				var r = l.respec(state, op["id"], op["keys"], wallet, op.get("options", {}))
				if r != null: result = r["state"]; wallet = r["wallet"]; detail = {"cost": r["cost"]}
			elif op["op"] == "award":
				var r = l.award(state, op["event"])
				if r != null: result = r["state"]; detail = {"duplicate": r["duplicate"], "report": r["report"]}
			else: result = l.deserialize(l.serialize(state))
			if result == null: ok = false
			else: state = result
			out.store_line(JSON.stringify({"kind": "model", "case": c["id"], "step": i, "ok": ok, "state": state, "wallet": wallet, "detail": detail})); records += 1
	for b in input["builds"]:
		if not l.validate_build(b["id"], 920, b["picks"], b["capstone"]): printerr("legal build rejected: ", l.error); quit(1); return
	var camp = Campaign.new(); var err = camp.load_tables()
	if err != "": printerr(err); quit(1); return
	camp.fixed_clock = true
	# Keep native table drift visible, then test predicates on exactly identical input.
	var native_hulls = camp.HULLS; var native_weapons = camp.W_; var native_differences = []
	for tpl in native_hulls:
		for m in camp.MODULES:
			var native_fit = camp.canFitModule({"tpl": tpl, "mods": []}, m)
			if input["fitExpected"].get(tpl + ":" + m) != native_fit:
				native_differences.append({"tpl": tpl, "mod": m, "browserAllowed": input["fitExpected"].get(tpl + ":" + m), "godotAllowed": native_fit, "browserWeapons": input["fitHulls"][tpl]["w"], "godotWeapons": native_hulls[tpl]["w"]})
	var drift_file = FileAccess.open(args[0] + ".native_table_drift.json", FileAccess.WRITE)
	drift_file.store_string(JSON.stringify({"note": "Native inventories are retained separately. Shared-input predicate vectors do not clear existing table drift.", "differences": native_differences}, "  ")); drift_file.close()
	camp.HULLS = input["fitHulls"]; camp.W_ = input["fitWeapons"]
	for tpl in camp.HULLS:
		var t = camp.HULLS[tpl]
		for m in camp.MODULES:
			out.store_line(JSON.stringify({"kind": "fit", "tpl": tpl, "mod": m, "allowed": camp.canFitModule({"tpl": tpl, "mods": []}, m)})); records += 1
			var full = []
			for j in range(int(t.get("slots", 0))): full.append("auspex")
			if camp.canFitModule({"tpl": tpl, "mods": full}, m): printerr("full slots accepted"); quit(1); return
	camp.HULLS = native_hulls; camp.W_ = native_weapons
	for i in range(input["actionCases"].size()):
		var a = input["actionCases"][i]; var mod = a[0]; var tpl = a[1]; var index = a[2]
		camp.META = camp.defaultMeta(); camp.RUN = camp.runDefaults(); camp.B = null; camp.UID = 1; JSM.rnd_seed(1111 + i)
		var sh = camp.newShip(tpl)
		if index == "full":
			for j in range(int(camp.HULLS[tpl]["slots"])): sh["mods"].append("auspex")
		camp.RUN["fleet"] = [sh]; camp.RUN["flagUid"] = sh["uid"]; camp.RUN["inventory"] = [mod]
		var before = {"mods": sh["mods"].duplicate(true), "hp": sh["hp"], "inventory": camp.RUN["inventory"].duplicate(true)}
		camp.ACT_equip(("0" if index == "full" else index) + ":" + sh["uid"])
		var after = {"mods": sh["mods"].duplicate(true), "hp": sh["hp"], "inventory": camp.RUN["inventory"].duplicate(true)}
		out.store_line(JSON.stringify({"kind": "equip", "case": i, "before": before, "after": after})); records += 1
	out.close(); print(records, " Godot records; ", input["builds"].size(), " legal builds accepted"); quit()
