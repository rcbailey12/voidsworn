extends SceneTree
# Step 10 acceptance test in the Godot campaign: Heat after the first loss and the ruled XP payout.
const Campaign = preload("res://campaign/campaign.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func has_act(c, name: String) -> bool:
	return c.screen_acts().any(func(a): return a[0] == name)

func _init() -> void:
	var c = Campaign.new()
	var error = c.load_tables()
	if error != "": printerr(error); quit(1); return
	c.fixed_clock = true
	c.META["admirals"]["vaelen"] = true
	c.picked_faction = "ithar"; c.picked_admiral = "vaelen"

	c.admiralScreen()
	check(not c.heatUnlocked() and not has_act(c, "optHeat"), "a fresh profile sees no Heat control")

	c.newRun("vaelen", "ithar"); c.RUN["stats"]["battles"] = 0; c.endRun(false)
	check(c.META["stats"]["losses"] == 1, "a lost run is recorded")
	check(c.heatUnlocked(), "one loss opens Heat")
	c.admiralScreen()
	check(has_act(c, "optHeat"), "one loss shows the Heat control")

	c.META = c.migrateMeta(c.defaultMeta()); c.META["admirals"]["vaelen"] = true; c.newRun("vaelen", "ithar"); c.endRun(false, true)
	check(float(c.z0(c.META["stats"].get("losses"))) == 0 and not c.heatUnlocked(), "an abandoned run is not a recorded loss")

	c.META = c.defaultMeta()
	c.META["tel"] = [
		{"ev": "run_end", "victory": false, "abandoned": false},
		{"ev": "run_end", "victory": false, "abandoned": false},
		{"ev": "run_end", "victory": false, "abandoned": true},
		{"ev": "run_end", "victory": true, "abandoned": false}]
	c.META = c.migrateMeta(c.META)
	check(c.META["stats"].get("losses") == 2, "a profile from before the Heat gate back-fills its recorded losses from the run log")
	check(c.heatUnlocked(), "the back-filled losses open Heat on the next load")

	c.META = c.defaultMeta()
	c.META["tel"] = [{"ev": "run_end", "victory": false, "abandoned": true}, {"ev": "run_end", "victory": true, "abandoned": false}]
	c.META = c.migrateMeta(c.META)
	check(not c.META["stats"].has("losses"), "a log with no real loss leaves the count absent so old fixtures stay unchanged")

	var saved = {"format": "voidsworn-godot-campaign", "v": 1, "uid": 1, "meta": c.defaultMeta(), "run": {"none": true},
		"tel": [{"ev": "run_end", "victory": false, "abandoned": false}, {"ev": "run_end", "victory": false, "abandoned": false},
			{"ev": "run_end", "victory": false, "abandoned": true}, {"ev": "run_end", "victory": true, "abandoned": false}]}
	c.load_save_text(JSON.stringify(saved))
	check(c.META["stats"].get("losses") == 2 and c.heatUnlocked(), "a saved pre-gate profile back-fills from its saved run log on load")

	c.META = c.migrateMeta(c.defaultMeta()); c.META["admirals"]["vaelen"] = true; c.META["stats"]["losses"] = 1
	c.newRun("vaelen", "ithar", {"heat": ["h_hunted"]})
	check(c.heatLevel(c.RUN["heat"]) == 2, "h_hunted is two Heat points")
	c.RUN["stats"]["battles"] = 0; c.endRun(false)
	check(c.masteryXP("vaelen") == 4, "the flown line gets 2 XP per Heat point")
	check(c.masteryXP("aelith") == 0, "the Heat payout is not split to benched lines")
	check(c.META["shadowPool"]["ithar"] == 2, "the faction shadow pool gets 1 XP per Heat point")
	check(c.META["stats"]["losses"] == 2, "the paid run also records its loss")

	c.META = c.migrateMeta(c.defaultMeta()); c.META["admirals"]["vaelen"] = true; c.META["stats"]["losses"] = 1; c.META["mastery"]["vaelen"] = 229
	c.newRun("vaelen", "ithar", {"heat": ["h_flag"]}); c.RUN["stats"]["battles"] = 0; c.endRun(false)
	check(c.masteryXP("vaelen") == 230, "Heat XP respects the line cap")
	check(c.META["shadowPool"]["ithar"] == 2, "cap overflow joins the shadow pool with the pool point")

	c.META = c.migrateMeta(c.defaultMeta()); c.META["stats"]["wins"] = 1
	check(c.heatUnlocked(), "an older winner keeps Heat open")

	c.META = c.migrateMeta(c.defaultMeta()); c.META["admirals"]["vaelen"] = true; c.picked_faction = "ithar"; c.picked_admiral = "vaelen"; c.run_opt["heat"] = ["h_flag"]
	c.ACT_startRun()
	check(c.RUN["heat"].is_empty(), "a fresh profile cannot launch with Heat")
	c.META["stats"]["losses"] = 1; c.ACT_startRun()
	check(c.RUN["heat"] == ["h_flag"], "a profile with one loss can launch with Heat")
	print("PASS: Heat opens after the first loss and pays 2 XP per point to the flown line and 1 to the shadow pool." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
