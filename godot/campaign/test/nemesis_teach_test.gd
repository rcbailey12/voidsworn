# Issue #24, progression step 7: the Godot twin of the Nemesis teaching loop.
# Reads fixtures written by contrib/opus/tools/nemesis_teach_tests.js and proves the same debrief data and map line.
# godot --headless --path godot --script res://campaign/test/nemesis_teach_test.gd -- <fixtures.json>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0

func check(value, message: String) -> void:
	if not value:
		failures += 1; printerr("FAIL: " + message)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the browser fixture JSON path"); quit(1); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not fixtures is Array or fixtures.is_empty():
		printerr("Missing or empty teaching fixtures"); quit(1); return
	var c = CampaignScript.new()
	var err = c.load_tables()
	if err != "":
		printerr(err); quit(1); return
	c.fixed_clock = true
	for fixture in fixtures:
		var name := str(fixture["name"])
		var run = fixture["run"].duplicate(true)
		c.RUN = run
		check(JSM.canon(c.nemDebrief(run)) == JSM.canon(fixture["expected"]), name + ": debrief data")
		var N = run["nems"][fixture["who"]]
		check(c.nemMeetingLine(N) == str(fixture["line"]), name + ": meeting line")
		# the end page carries the same lesson row through endRun
		c.META = c.migrateMeta(c.defaultMeta()); c.SAVED_RUN = null; c.RUN = fixture["run"].duplicate(true)
		c.endRun(false, false)
		check(c.page["kind"] == "end", name + ": end screen")
		var got = c.page["data"]["run"]["carry"]["inheritance"]["nem"]
		check(JSM.canon(got) == JSM.canon(fixture["expected"]), name + ": end-page lesson row")
	# the taught flag itself, and an old save's lesson reading as taught
	c.RUN = {"sector": 1}
	var N = {"lessons": [], "fac": "hegemony", "title": "T", "name": "N", "persona": "x"}
	check(c.nemLessonAdd(N, "ion", true) != "" and N["lessons"][0]["taught"] == true, "new lesson records taught")
	var old = {"lessons": [{"w": "ion", "t": "old", "sector": 1}], "fac": "hegemony", "title": "T", "name": "N", "persona": "x"}
	check(c.nemDebrief({"nems": {"hegemony": old}})["lessons"][0]["taught"] == true, "old save lesson reads as taught")
	print("PASS: %d Nemesis teaching fixtures match the browser debrief and map line." % fixtures.size() if failures == 0 else "FAIL: %d checks" % failures)
	quit(0 if failures == 0 else 1)
