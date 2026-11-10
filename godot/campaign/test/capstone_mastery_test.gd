extends SceneTree
# Job 7 step 14: capstone mastery in the Godot campaign. A chosen level 8 evolution deepens at 320, 440 and 600 XP.
# The effect texts are placeholders until the tree pack carries them.
#   godot --headless --path godot --script res://campaign/test/capstone_mastery_test.gd
const Campaign = preload("res://campaign/campaign.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func evo(c, id: String) -> void:
	if not (c.META.get("lineage") is Dictionary): c.META["lineage"] = {}
	c.META["lineage"][id] = {"picks": ["A:0:0", "B:0:0", "C:0:0"], "capstone": 0, "respecs": 0}

func _init() -> void:
	var c = Campaign.new()
	var error = c.load_tables()
	if error != "":
		printerr(error); quit(1); return
	c.fixed_clock = true

	# a line at 320 XP on its chosen evolution shows mastery level 1 and its effect
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 320.0; evo(c, "vaelen")
	check(c.masteryLevel("vaelen") == 8, "the evolution stays at tree level 8")
	check(c.capstoneMasteryLevel("vaelen") == 1, "320 XP is capstone mastery 1")
	check(is_equal_approx(c.masteryXPCap("vaelen"), 600.0), "a chosen evolution opens the cap to 600")
	check(c.capstoneMasteryPerk(1) != null and str(c.capstoneMasteryPerk(1)["d"]).length() > 0, "mastery 1 has an effect line")
	c.act("lineage", "vaelen")
	check(c.page.get("kind") == "lineage", "the lineage screen builds")

	# XP below 230 cannot buy mastery
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 229.0
	check(not c.lineagePick("vaelen:cap:0"), "no evolution below level 8")
	check(c.capstoneMasteryLevel("vaelen") == 0, "no mastery below the evolution")
	check(is_equal_approx(c.masteryXPCap("vaelen"), 230.0), "an unmet line still caps at 230")
	c.META["mastery"]["vaelen"] = 320.0
	check(c.capstoneMasteryLevel("vaelen") == 0, "XP alone cannot buy mastery without the evolution")

	# the three thresholds
	for pair in [[0, 0], [319, 0], [320, 1], [439, 1], [440, 2], [599, 2], [600, 3], [900, 3]]:
		c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = float(pair[0]); evo(c, "vaelen")
		check(c.capstoneMasteryLevel("vaelen") == pair[1], "capstone mastery threshold " + str(pair[0]))
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 320.0; evo(c, "vaelen")
	check(c.capstoneMasteryNext("vaelen") == 440, "320 XP points at 440 next")
	c.META["mastery"]["vaelen"] = 600.0
	check(c.capstoneMasteryNext("vaelen") == null, "600 XP is full mastery")

	# XP past 230 deepens the chosen evolution on a real run instead of spilling at once
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 300.0; evo(c, "vaelen")
	c.newRun("vaelen", "ithar"); c.RUN["stats"]["battles"] = 8; c.endRun(false); c.RUN = null
	check(c.masteryXP("vaelen") == 308.0, "XP past 230 deepens the chosen evolution")
	check(c.capstoneMasteryLevel("vaelen") == 0, "308 XP is still below mastery 1")

	# without an evolution the same run still stops at 230
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 229.0
	c.newRun("vaelen", "ithar"); c.RUN["stats"]["battles"] = 8; c.endRun(false); c.RUN = null
	check(c.masteryXP("vaelen") == 230.0, "an unmet line stops at 230")
	check(c.capstoneMasteryLevel("vaelen") == 0, "an unmet line shows no mastery")

	# save round trip
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 440.0; evo(c, "vaelen")
	c.load_save_text(c.save_text())
	check(c.capstoneMasteryLevel("vaelen") == 2, "mastery survives reopening a save")

	# a respec withdraws the evolution and with it the mastery display and the raised cap
	c.META = c.migrateMeta(c.defaultMeta()); c.META["mastery"]["vaelen"] = 440.0; evo(c, "vaelen"); c.META["renown"] = 100
	check(c.lineageRespec("vaelen"), "the line resets")
	check(c.capstoneMasteryLevel("vaelen") == 0, "a reset evolution shows no mastery")
	check(is_equal_approx(c.masteryXPCap("vaelen"), 230.0), "a reset line caps at 230 again")
	var gain = c.masteryCredit("vaelen", 50.0)
	check(c.masteryXP("vaelen") == 440.0, "a reset line keeps the XP it already earned")
	check(is_equal_approx(float(gain["overflow"]), 50.0), "new XP past the reset cap goes to shadow learning")

	print("PASS: capstone mastery opens at 320, 440 and 600 XP only after the level 8 evolution, and shows its effect." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
