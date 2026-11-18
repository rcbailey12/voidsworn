extends SceneTree

const Rules = preload("res://rules/rules.gd")
const ENCOUNTERS := ["rout", "ambush", "defend", "hunt", "intercept", "break", "hold", "flagship",
	"boss1_rout", "boss1_ambush", "boss2_rout", "boss2_ambush", "boss3_rout", "boss3_ambush"]

func snapshot(R: Rules) -> Dictionary:
	var units := []
	for u in R.B["units"]:
		var weapons := []
		for w in u["weapons"]: weapons.append([w["id"], float(w["r"])])
		units.append([u.side, u.tpl, float(u.q), float(u.r), float(u.facing), float(u.speed), weapons])
	return {"shape": R.B["shape"], "arena": R.B["arena"], "map": R.B["map"]["map"],
		"bearing": R.B.get("mapTrialBearing"), "units": units}

func compare_case(actual: Dictionary, expected: Dictionary) -> String:
	for key in ["shape", "arena", "map", "bearing"]:
		if actual[key] != expected[key]: return "%s: got %s, expected %s" % [key, actual[key], expected[key]]
	if actual.units.size() != expected.units.size():
		return "%s units, expected %s" % [actual.units.size(), expected.units.size()]
	for i in range(actual.units.size()):
		if actual.units[i] != expected.units[i]:
			return "unit %d: got %s, expected %s" % [i, actual.units[i], expected.units[i]]
	return ""

func _initialize() -> void:
	var fixture_script := ProjectSettings.globalize_path("res://rules/test/node/map_trial_fixtures.js")
	var output := []
	if OS.execute("node", [fixture_script], output, true) != 0 or output.is_empty():
		printerr("FAIL: could not generate map trial fixtures: ", output)
		quit(1)
		return
	var fixtures = JSON.parse_string(output[0])
	if not (fixtures is Array):
		printerr("FAIL: invalid map trial fixtures")
		quit(1)
		return
	var R := Rules.new()
	var error := R.load_tables("res://rules/data/tables.json")
	if error != "":
		printerr(error)
		quit(1)
		return
	var failures := 0
	var seeds := {}
	for f in fixtures:
		if not seeds.has(f.enc): seeds[f.enc] = {}
		seeds[f.enc][f.seed] = true
		R.RUN = f.run
		R.RUN["mapTrial"] = true
		R.startBattle(f.cfg)
		var difference := compare_case(snapshot(R), f.expected)
		if difference != "":
			if failures < 8: printerr("FAIL: ", f.enc, " seed ", f.seed, ": ", difference)
			failures += 1
	for enc in ENCOUNTERS:
		if seeds.get(enc, {}).size() < 20:
			printerr("FAIL: ", enc, " has fewer than 20 distinct seeds")
			failures += 1
	if failures == 0: print("PASS: %d map trial battles match the JS sim across %d encounters" % [fixtures.size(), ENCOUNTERS.size()])
	else: printerr("FAIL: ", failures, " map trial comparisons failed")
	quit(0 if failures == 0 else 1)
