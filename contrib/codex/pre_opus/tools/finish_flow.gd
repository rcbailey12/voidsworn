extends SceneTree
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
func _init() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1: printerr("output required"); quit(2); return
	var tests = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/pre_opus_flow_input.json"))
	if not tests is Array or tests.size() != 18: printerr("expected 18 flow fixtures"); quit(2); return
	var c = Campaign.new(); var err = c.load_tables()
	if err != "": printerr(err); quit(1); return
	c.fixed_clock = true; c.persist_on = false
	var out = FileAccess.open(args[0], FileAccess.WRITE)
	for test in tests:
		c.META = test["meta"].duplicate(true); c.RUN = test["run"].duplicate(true); c.B = test["battle"].duplicate(true); c.SAVED_RUN = null
		for u in c.B["units"]:
			if u.get("ship") is Dictionary:
				for sh in c.RUN["fleet"]:
					if sh["uid"] == u["ship"]["uid"]: u["ship"] = sh; break
		var original = c.RUN
		JSM.rnd_seed(int(test["seed"])); c.finishBattle("loss")
		out.store_line(JSON.stringify({"kind":"finish_flow", "case":test["id"], "revealed":original["nem"]["revealed"], "adapt":original["nem"]["adapt"], "rng":JSM.rng_s & 0xFFFFFFFF}))
	out.close(); print("18 native finishBattle loss flows"); quit()
