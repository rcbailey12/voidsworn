# Godot --headless --path godot --script res://rules/test/effect_caps_test.gd -- <fixtures.json>
# Saved from contrib/opus/tools/effect_caps_tests.js at the R405 cutover.
# Replay the saved baseline with -- res://rules/test/effect_caps_cases.json.
extends SceneTree
const RulesScript = preload("res://rules/rules.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the saved fixture JSON path"); quit(2); return
	var fixtures = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not fixtures is Dictionary:
		printerr("Cannot read saved fixtures"); quit(2); return
	var bad := 0
	for script in [RulesScript, CampaignScript]:
		var port = script.new()
		var cases = port._dec(fixtures)
		var err = port.load_tables("res://rules/data/tables.json" if script == RulesScript else "res://campaign/data/campaign_tables.json")
		if err != "":
			printerr(err); bad += 1; continue
		for fixture in cases.sums:
			if JSM.canon(port.sumFx(fixture.list)) != JSM.canon(fixture.expected):
				printerr(script.resource_path, ": ", fixture.name); bad += 1
		for fixture in cases.derives:
			port.RUN = fixture.run
			var got = port.derive(fixture.ship)
			if JSM.canon({"speed": got.speed, "fx": got.fx}) != JSM.canon(fixture.expected):
				printerr(script.resource_path, ": ", fixture.name); bad += 1
	print("Effect caps: ", fixtures.sums.size(), " sum fixtures and ", fixtures.derives.size(), " derive fixtures in each Godot port; failures: ", bad)
	quit(1 if bad > 0 else 0)
