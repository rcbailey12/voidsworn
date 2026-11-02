# Progression step 8: replay the live browser's event entry, exit and map fixtures.
# godot --headless --path godot --script res://campaign/test/free_exit_test.gd -- <fixtures.json>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")

func snapshot(c) -> Dictionary:
	var meta = c.META.duplicate(false)
	meta.erase("tel") # Browser-only telemetry, excluded by campaign parity too.
	return {"run": c.RUN, "saved": c.SAVED_RUN, "meta": meta, "rng": JSM.rng_s & 0xFFFFFFFF,
		"uid": c.UID, "acts": c.screen_acts()}

func check_stage(c, fixture: Dictionary, stage: String) -> bool:
	if JSM.canon(snapshot(c)) != JSM.canon(fixture[stage]):
		printerr("FAIL: ", fixture["name"], " at ", stage)
		for key in snapshot(c):
			if JSM.canon(snapshot(c)[key]) != JSM.canon(fixture[stage][key]):
				printerr("  differs: ", key)
				printerr("  browser: ", JSM.canon(fixture[stage][key]))
				printerr("  Godot: ", JSM.canon(snapshot(c)[key]))
		return false
	return true

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the browser fixture JSON path"); quit(1); return
	var c = CampaignScript.new()
	var err = c.load_tables()
	if err != "":
		printerr(err); quit(1); return
	var fixtures = c._dec(JSON.parse_string(FileAccess.get_file_as_string(args[0])))
	if not fixtures is Array or fixtures.is_empty():
		printerr("Missing or empty free exit fixtures"); quit(1); return
	c.fixed_clock = true
	for fixture in fixtures:
		var initial = fixture["initial"]
		c.RUN = initial["run"].duplicate(true); c.META = initial["meta"].duplicate(true)
		c.SAVED_RUN = initial["saved"].duplicate(true); c.UID = int(initial["uid"])
		c.B = null; c.cur_event = null; c.modal_d = null; c.W = {}
		JSM.rnd_seed(int(initial["rng"]))
		c.act("enterNode", fixture["node"])
		if c.modal_d == null or c.modal_d["kind"] != "event" or c.cur_event["id"] != fixture["event"]:
			printerr("FAIL: did not enter ", fixture["name"]); quit(1); return
		if not check_stage(c, fixture, "entered"): quit(1); return
		c.act("eventChoice", str(int(fixture["exit"])))
		if c.B != null or c.modal_d == null or c.modal_d["kind"] != "event_result":
			printerr("FAIL: exit started a fight or lost its result: ", fixture["name"]); quit(1); return
		if not check_stage(c, fixture, "result"): quit(1); return
		c.act("closeModal")
		if c.modal_d != null or c.page["kind"] != "map":
			printerr("FAIL: exit did not return to the map: ", fixture["name"]); quit(1); return
		if not check_stage(c, fixture, "map"): quit(1); return
	print("PASS: ", fixtures.size(), " free exits match the live browser at entry, result and sector map.")
	quit()
