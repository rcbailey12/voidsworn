extends SceneTree
# Run with -- <fixtures.json> from contrib/opus/tools/heat_tests.js.
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func reset(c, meta: Dictionary) -> void:
	c.META = c.migrateMeta(meta.duplicate(true)); c.SAVED_RUN = null; c.RUN = null; c.B = null
	c.picked_admiral = "vex"; c.picked_faction = "voidsworn"
	c.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; c.ended = false

func heat_actions(c) -> int:
	return c.page["acts"].filter(func(a): return a[0] == "optHeat").size()

func _init() -> void:
	var c = Campaign.new(); var error = c.load_tables()
	if error != "":
		printerr(error); quit(1); return
	c.fixed_clock = true
	reset(c, c.defaultMeta())
	check(not c.heatAvailable(), "fresh profile cannot use Heat")
	c.admiralScreen()
	check(not c.page["data"]["opts"]["heat"] and heat_actions(c) == 0, "fresh profile has no Heat control")
	c.run_opt["heat"] = ["h_hunted"]; c.act("optHeat", "h_cmd")
	check(c.run_opt["heat"] == ["h_hunted"], "locked Heat action is ignored")
	c.act("startRun")
	check(c.RUN["heat"].is_empty(), "launch strips Heat on a fresh profile")

	reset(c, c.defaultMeta())
	c.newRun("vex", "voidsworn"); c.RUN["stats"]["battles"] = 8; c.endRun(false)
	check(c.META["stats"]["losses"] == 1 and c.heatAvailable(), "a defeat records one loss and opens Heat")
	c.act("newRunScreen")
	check(c.page["data"]["opts"]["heat"] and heat_actions(c) == c.HEAT.size(), "one-loss profile has every Heat control")
	c.act("optHeat", "h_hunted"); c.act("optHeat", "h_cmd"); c.act("startRun")
	check(c.heatLevel(c.RUN["heat"]) == 3, "one-loss profile launches its selected Heat")

	reset(c, c.defaultMeta())
	c.newRun("vex", "voidsworn"); c.endRun(false, true)
	check(float(c.z0(c.META["stats"].get("losses"))) == 0 and not c.heatAvailable(), "abandoning does not open Heat")

	var winner = c.defaultMeta(); winner["stats"]["wins"] = 1; reset(c, winner)
	check(c.heatAvailable(), "existing winners keep Heat access")
	c.admiralScreen()
	check(c.page["data"]["opts"]["heat"] and heat_actions(c) == c.HEAT.size(), "existing winner keeps every Heat control")

	var old = c.defaultMeta(); old["stats"].erase("losses")
	old["tel"] = [{"ev": "run_end", "victory": false, "abandoned": false}, {"ev": "run_end", "victory": false, "abandoned": true}]
	reset(c, old)
	check(c.META["stats"]["losses"] == 1, "migration recovers a recorded defeat but not an abandon")

	var args = OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Expected browser fixture path"); quit(1); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for f in fixtures:
		reset(c, f["meta"])
		c.newRun(f["flown"], f["fac"], {"heat": f["heat"]})
		c.RUN["stats"] = f["stats"].duplicate(true); c.RUN["sector"] = f["sector"]
		c.endRun(f["victory"], f["abandoned"])
		var carry = c.page["data"]["run"]["carry"]
		check(JSM.canon(carry) == JSM.canon(f["carry"]), f["name"] + ": exact Heat receipt parity")
		for key in ["mastery", "shadowPool", "stats"]:
			check(JSM.canon(c.META[key]) == JSM.canon(f["expected"][key]), f["name"] + ": profile " + key)
		if f["name"] == "heat_3":
			check(float(carry["mxGain"]) == 14.0, "Heat 3 pays eight base XP plus six flown Heat XP")
		if f["name"] == "heat_cap":
			check(float(carry["mxGain"]) == 1.0 and float(carry["mxOverflow"]) == 5.0 and float(carry["shadowBank"]) == 8.0, "Heat cap overflow and direct shadow XP are preserved")
	print("PASS: first-loss Heat controls, +2/+1 XP payouts, migration, cap overflow and exact browser parity." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
