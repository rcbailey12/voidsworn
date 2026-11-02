extends SceneTree
# Step 2 acceptance test in the Godot campaign, including actual run-end XP.
const Campaign = preload("res://campaign/campaign.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _init() -> void:
	var c = Campaign.new()
	var error = c.load_tables()
	if error != "":
		printerr(error); quit(1); return
	c.fixed_clock = true
	c.META["admirals"]["vaelen"] = true
	for run in range(5):
		c.newRun("vaelen", "ithar")
		c.RUN["stats"]["battles"] = 15
		c.endRun(false)
		c.RUN = null
	check(c.masteryXP("vaelen") == 75 and c.masteryLevel("vaelen") == 5, "five runs earn the first tree pick")
	check(not c.lineagePick("vaelen:A:1:0"), "cannot skip a tier")
	c.act("lineage", "vaelen"); c.act("offerLineage", "vaelen:A:0:0")
	check(c.lineageBuild("vaelen")["picks"].is_empty(), "preview does not spend the pick")
	c.act("closeModal"); c.act("confirmLineage", "vaelen:A:0:0")
	check(c.lineageNodes("vaelen")[1]["state"] == "locked", "unchosen partner locks")
	check(not c.lineagePick("vaelen:B:0:0"), "one pick at level 5")
	c.META["mastery"]["vaelen"] = 110
	check(c.lineagePick("vaelen:B:0:1"), "independent branch tier")
	c.META["mastery"]["vaelen"] = 160
	check(c.lineagePick("vaelen:A:1:0"), "deepen the first branch")
	check(not c.lineagePick("vaelen:A:2:0") and not c.lineagePick("vaelen:cap:0"), "only three branch picks and no early capstone")
	c.META["mastery"]["vaelen"] = 230
	check(c.lineagePick("vaelen:cap:1") and not c.lineagePick("vaelen:cap:0"), "one capstone evolution")
	c.load_save_text(c.save_text())
	check(c.lineageBuild("vaelen")["capstone"] == 1, "choices survive reopening")
	c.META["renown"] = 24
	check(not c.lineageRespec("vaelen"), "insufficient renown")
	c.META["renown"] = 25
	c.newRun("vaelen", "ithar")
	check(not c.lineageRespec("vaelen"), "no reset in an active run")
	c.RUN = null
	check(not c.lineageRespec("vaelen"), "no reset with a saved run")
	c.SAVED_RUN = null
	c.act("offerRespec", "vaelen"); c.act("closeModal")
	check(c.META["renown"] == 25, "cancel does not charge")
	c.act("confirmRespec", "vaelen")
	check(c.META["renown"] == 0 and c.lineageBuild("vaelen")["picks"].is_empty() and c.lineageBuild("vaelen")["capstone"] == null, "25 renown resets the full tree")
	check(c.masteryXP("vaelen") == 230 and c.lineageRespecCost("vaelen") == 35 and c.lineageRespecCost("aelith") == 25, "XP stays and prices escalate per line")
	for key in ["vaelen:A:0:1", "vaelen:A:1:1", "vaelen:A:2:1", "vaelen:cap:0"]:
		check(c.lineagePick(key), "deep branch after reset: " + key)
	c.META["renown"] = 100
	check(c.lineageRespec("vaelen") and c.META["renown"] == 65 and c.lineageRespecCost("vaelen") == 45, "second reset costs 35")
	check(not c.lineageRespec("vaelen"), "no charge for an empty reset")
	for id in c.ADMIRALS.keys():
		c.META["mastery"][id] = 230
		if c.ADMIRALS[id].get("fac") != "ithar":
			check(c.masteryLevel(id) == 4 and c.lineageNodes(id).is_empty() and not c.lineageRespec(id), "fixed perks: " + id)
		else:
			check(c.masteryLevel(id) == 8, "Glasswright level 8: " + id)
			for suffix in [":B:0:0", ":C:0:0", ":A:0:0", ":cap:0"]:
				check(c.lineagePick(id + suffix), "spread build: " + id + suffix)
	for pair in [[0,0],[6,1],[16,2],[30,3],[50,4],[74,4],[75,5],[109,5],[110,6],[159,6],[160,7],[229,7],[230,8]]:
		c.META["mastery"]["vaelen"] = pair[0]
		check(c.masteryLevel("vaelen") == pair[1], "XP threshold " + str(pair[0]))
	var old = c.defaultMeta(); old.erase("lineage")
	c.META = c.migrateMeta(old)
	check(c.lineageBuild("vaelen")["picks"].is_empty(), "old profiles migrate")
	print("PASS: Glasswright XP, tiers, locks, capstones, saves and per-line resets; other factions unchanged." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
