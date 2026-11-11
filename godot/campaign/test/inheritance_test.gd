extends SceneTree
# Browser endRun fixtures exercise both the receipt and the profile it describes.
const Campaign = preload("res://campaign/campaign.gd")
const DebriefUI = preload("res://ui/campaign/campaign_ui.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1; printerr("FAIL: " + message)

func _init() -> void:
	var c = Campaign.new(); var error = c.load_tables()
	if error != "": printerr(error); quit(1); return
	c.fixed_clock = true
	var args = OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Expected browser fixture path"); quit(1); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	for f in fixtures:
		c.META = c.migrateMeta(f["meta"]); c.SAVED_RUN = null
		c.META["admirals"][f["flown"]] = true
		c.newRun(f["flown"], f["fac"]); c.RUN["stats"] = f["stats"].duplicate(true); c.RUN["sector"] = f["sector"]
		c.endRun(f["victory"], f["abandoned"])
		check(c.page["kind"] == "end", f["name"] + ": end screen")
		var carry = c.page["data"]["run"]["carry"]
		check(JSM.canon(carry) == JSM.canon(f["carry"]), f["name"] + ": exact receipt parity")
		for key in ["renown", "mastery", "shadowPool", "unlocked", "variants", "lineage", "heirs", "stats"]:
			check(JSM.canon(c.META.get(key)) == JSM.canon(f["expected"].get(key)), f["name"] + ": profile " + key)
		var saved = JSON.parse_string(c.save_text())
		check(saved["run"] == {"none": true}, f["name"] + ": no resumable ended run")
		check(JSM.canon(c._dec(saved["meta"])) == JSM.canon(c.META), f["name"] + ": saved profile matches receipt source")
		var before = c.META.duplicate(true); c.endRun(f["victory"], f["abandoned"])
		check(c.META == before, f["name"] + ": no duplicate payout")
		c.act("nameHeir", c.shadowAdmirals(f["fac"], f["flown"])[0])
		check(c.page["data"]["run"]["carry"] == carry, f["name"] + ": heir choice preserves receipt")
		c.act("progTab", "legacy"); check(c.page["kind"] == "legacy", "debrief opens doctrine")
	print("PASS: inheritance receipts match browser payouts and resulting profiles on all end paths." if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
