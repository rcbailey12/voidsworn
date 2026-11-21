# Issue 1447: when the enemy AI fires the Cordon's ion pulse, on rules.gd. Twin of contrib/opus/tools/ion_pulse_ai_tests.js (battle.js).
#   godot --headless --path godot --script res://rules/test/ion_pulse_ai_test.gd
# Reads the cases and their fixed expectations from res://rules/test/ion_pulse_ai_cases.json. Fails on main before the fix:
# a lone 13-pool frigate drew a pulse (the four per-side catches sum to about 2.35 x the pool), a ship that moved into range never
# pulsed, and the log counted every ship in range.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
const DIRS = [[1, 0], [0, 1], [-1, 0], [0, -1], [1, -1], [-1, 1]]

func _init() -> void:
	var doc = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/ion_pulse_ai_cases.json"))
	if not doc is Dictionary:
		printerr("Cannot read ion_pulse_ai_cases.json"); quit(2); return
	var api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	var R = api.R
	var ok := 0; var bad := 0
	for c in doc.cases:
		var fleet := []
		for t in c.targets: fleet.append(t.tpl)
		api.new_battle_scenario({"seed": 7, "admiral": "vex", "fac_player": "voidsworn", "fleet": fleet, "fac": "hegemony", "enemies": ["h_interdictor"],
			"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
		R.B["terrain"] = {}
		var cordon = null; var ps := []
		for u in R.B["units"]:
			if R.jt(u.get("isSq")): u["dead"] = true; continue
			if u["side"] == "enemy" and cordon == null: cordon = u
			elif u["side"] == "player": ps.append(u)
		if cordon == null or cordon.get("ab") != "ionpulse" or ps.size() != c.targets.size():
			printerr("FAIL  ", c.name, ": setup"); bad += 1; continue
		cordon["q"] = 10; cordon["r"] = 10
		for i in range(ps.size()):
			var t = c.targets[i]; var u = ps[i]; var d = DIRS[i]
			u["q"] = 10 + d[0] * int(t.dist); u["r"] = 10 + d[1] * int(t.dist); u["shp"] = t.shp; R.syncShields(u)
		if c.has("moveTo"):
			cordon["q"] = ps[0]["q"] - DIRS[0][0] * int(c.moveTo); cordon["r"] = ps[0]["r"] - DIRS[0][1] * int(c.moveTo)
		R.B["log"] = []; R.B["side"] = "enemy"
		R.aiAbilities(cordon, func() -> bool: return true, c.mode)
		var line = null
		for e in R.B["log"]:
			if String(e["m"]).contains(" fires an ion pulse: "): line = String(e["m"]); break
		var n = -1
		if line != null: n = int(line.split("ion pulse: ")[1].split(" ")[0])
		var pulse: bool = line != null
		if pulse == bool(c.pulse) and (not pulse or not c.has("logN") or n == int(c.logN)):
			ok += 1; print("ok    ", c.name)
		else:
			bad += 1; printerr("FAIL  ", c.name, ": pulse ", pulse, (" (" + line + ")") if line != null else "", ", wanted pulse ", c.pulse, (" with " + str(int(c.logN)) + " in the log") if c.has("logN") else "")
	print("Ion pulse AI tests (rules.gd): ", ok, " ok, ", bad, " FAIL")
	quit(1 if bad > 0 else 0)
