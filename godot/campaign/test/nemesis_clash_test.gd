# Progression step 6. Read the fixtures from contrib/opus/tools/nemesis_clash_tests.js.
# godot --headless --path godot --script res://campaign/test/nemesis_clash_test.gd -- <fixtures.json>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the browser fixture JSON path"); quit(1); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not fixtures is Array or fixtures.is_empty():
		printerr("Missing or empty clash fixtures"); quit(1); return
	var c = CampaignScript.new()
	var err = c.load_tables()
	if err != "":
		printerr(err); quit(1); return
	for fixture in fixtures:
		c.RUN = fixture["run"].duplicate(true)
		JSM.rnd_seed(int(fixture["seed"]))
		var who = fixture.get("who")
		var n = c.RUN["nems"][who] if who != null else null
		var pick = c.nemAdapt(fixture["force"], n) if who != null else c.nemAdapt(fixture["force"])   # #121: a registry case adapts the commander named
		if who == null: n = c.RUN["nem"]
		var got = {"pick": pick, "adapt": n["adapt"], "seen": n["seen"], "revealed": n["revealed"], "rng": JSM.rng_s & 0xFFFFFFFF}
		if who != null:
			var others = {}
			for k in c.RUN["nems"].keys():
				if k != who: others[k] = c.RUN["nems"][k]
			got["others"] = others
		if JSM.canon(got) != JSM.canon(fixture["expected"]):
			printerr("FAIL: ", fixture["name"], " expected ", fixture["expected"], " got ", got)
			quit(1); return
	print("PASS: ", fixtures.size(), " Nemesis clash cases match the live browser results.")
	quit()
