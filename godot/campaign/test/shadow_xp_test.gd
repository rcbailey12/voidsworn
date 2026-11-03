extends SceneTree
# Run with -- <fixtures.json> from shadow_xp_tests.js for exact browser parity.
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1; printerr("FAIL: " + message)

func _init() -> void:
	var c = Campaign.new(); var error = c.load_tables()
	if error != "": printerr(error); quit(1); return
	c.fixed_clock = true
	c.newRun("vaelen", "ithar"); c.RUN["stats"]["battles"] = 8; c.endRun(false)
	check(c.masteryXP("vaelen") == 8 and c.masteryXP("aelith") == 2 and c.masteryXP("vex") == 0, "quarter rate and faction scope")
	c.act("nameHeir", "vex"); c.act("nameHeir", "vaelen")
	check(c.META["heirs"].is_empty(), "reject flown and foreign lines")
	c.META["runAt"] = 123; c.act("nameHeir", "aelith")
	check(c.META["runAt"] == 123, "heir naming saves meta without changing the run timestamp")
	check(c.masteryXP("aelith") == 2, "naming does not pay retroactively")
	c.load_save_text(c.save_text())
	check(c.META["heirs"]["ithar"] == "aelith", "heir survives reopening")
	c.newRun("vaelen", "ithar"); c.RUN["stats"]["battles"] = 8; c.endRun(true)
	check(c.masteryXP("aelith") == 11 and c.masteryXP("vaelen") == 26, "victory pays heir half and flown full rate")
	var before = c.META.duplicate(true); c.endRun(true)
	check(c.META == before, "duplicate ending cannot pay twice")
	var other = c.shadowAdmirals("ithar", "vaelen").filter(func(id): return id != "aelith")[0]
	c.act("nameHeir", other); check(c.META["heirs"]["ithar"] == other, "replace heir on victory debrief")
	c.act("title"); c.act("nameHeir", "aelith"); check(c.META["heirs"]["ithar"] == other, "reject naming outside debrief")
	c.newRun("vex", "voidsworn"); c.RUN["stats"]["battles"] = 4; c.endRun(false, true)
	var crusade = c.shadowAdmirals("voidsworn", "vex")[0]; c.act("nameHeir", crusade)
	check(c.META["heirs"]["ithar"] == other and c.META["heirs"]["voidsworn"] == crusade, "abandon debrief and separate faction heirs")
	var args = OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Expected browser fixture path"); quit(1); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for f in fixtures:
		c.META = c.migrateMeta(f["meta"])
		var result = c.awardLineageXP(f["flown"], f["fac"], f["xp"])
		check(JSM.canon(result) == JSM.canon(f["result"]), f["name"] + ": exact earnings parity")
		check(JSM.canon(c.META) == JSM.canon(f["expected"]), f["name"] + ": exact profile parity")
		c.load_save_text(c.save_text())
		check(c.META["shadowPool"] == f["expected"]["shadowPool"], "saved overflow survives reopening")
	var old = c.defaultMeta(); old.erase("heirs"); old.erase("shadowPool"); c.META = c.migrateMeta(old)
	check(c.META["heirs"].is_empty() and c.META["shadowPool"].is_empty(), "old profiles migrate")
	print("PASS: shadow XP, debrief heirs, saves and exact browser overflow parity." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
