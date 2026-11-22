# Progression step 6: replay the Nemesis adaptation cases.
# Saved from contrib/opus/tools/nemesis_clash_tests.js at the R405 cutover.
# Replay the saved baseline with -- res://campaign/test/nemesis_clash_cases.json.gz.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")

func _fixture_text(path: String) -> String:
	if path.ends_with(".gz"):
		return FileAccess.get_file_as_bytes(path).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	return FileAccess.get_file_as_string(path)

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the saved fixture JSON path"); quit(1); return
	var fixtures = JSON.parse_string(_fixture_text(args[0]))
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
	print("PASS: ", fixtures.size(), " Nemesis clash cases match the saved results.")
	quit()
