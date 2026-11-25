extends SceneTree
# Issue 2161 (R437, issue 1877): the Chorus close-in weapon shows as "Acid Thorns" everywhere a weapon name is read, and
# its rules id stays `tendril` (names only: no number moves). Both table files carry the display name (the battle rules
# read tables.json, the campaign screens read campaign_tables.json through wName).
#   godot --headless --path godot --script res://rules/test/acid_thorns_name_2161_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")
const CampaignScript := preload("res://campaign/campaign.gd")
const API := preload("res://rules/battle_api.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "acid_thorns_name_2161_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	for path in ["res://rules/data/tables.json", "res://campaign/data/campaign_tables.json"]:
		var j = JSON.parse_string(FileAccess.get_file_as_string(path))
		var t: Dictionary = j["tables"]
		_check(t["W"].has("tendril"), "%s keeps the weapon id tendril" % path)
		_check(t["W"]["tendril"]["n"] == "Acid Thorns", "%s: W.tendril is named Acid Thorns (got '%s')" % [path, t["W"]["tendril"]["n"]])
		_check(t["FAC_WNAMES"]["chorus"]["tendril"] == "Acid Thorns", "%s: the Chorus name for tendril is Acid Thorns (got '%s')" % [path, t["FAC_WNAMES"]["chorus"]["tendril"]])
		_check(not FileAccess.get_file_as_string(path).contains("\"Boarding tendrils\""), "%s has no weapon named Boarding tendrils left" % path)
	# the numbers did not move
	var w: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/data/tables.json"))["tables"]["W"]["tendril"]
	_check(w["shots"] == 2 and w["dmg"] == 11 and w["r"] == 1 and w["opt"] == 1 and w["acc"] == 85 and w["crit"] == 12 and w["k"] == "bio",
		"the Acid Thorns numbers are the tendril numbers (shots 2, dmg 11, range 1, acc 85, crit 12)")
	# the readers
	var api := API.new()
	var error: String = api.load_rules()
	_check(error == "", "the rules load with the resealed table (%s)" % error)
	if error == "":
		_check(str(api.R.WPN["tendril"]["n"]) == "Acid Thorns" and str(api.R.FAC_WNAMES["chorus"]["tendril"]) == "Acid Thorns",
			"the battle rules read Acid Thorns")
	var C = CampaignScript.new()
	error = C.load_tables()
	_check(error == "", "the campaign tables load with the resealed table (%s)" % error)
	if error == "":
		_check(str(C.wName("chorus", "tendril")) == "Acid Thorns", "the campaign screens (wName) read Acid Thorns for the Chorus (got '%s')" % str(C.wName("chorus", "tendril")))
		_check(str(C.wName(null, "tendril")) == "Acid Thorns", "the campaign's plain weapon name is Acid Thorns too (got '%s')" % str(C.wName(null, "tendril")))
	if failures == 0:
		print("PASS: acid_thorns_name_2161_check (Acid Thorns in both table files, id tendril, numbers unchanged)")
	else:
		printerr("FAIL: acid_thorns_name_2161_check: %d failed" % failures)
	quit(0 if failures == 0 else 1)
