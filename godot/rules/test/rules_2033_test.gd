# Issue 2033 (AAA hidden tactics, item 7): called shots. The table sets the trade-off, the preview shows the aim cost, a
# called volley lands on its section, and only the Veteran AI calls (engines on a runner, weapons on the top threat).
#   godot --headless --path godot --script res://rules/test/rules_2033_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(fleet: Array, fac: String, enemies: Array) -> void:
	api.new_battle_scenario({"seed": 7, "admiral": "vex", "fac_player": "voidsworn", "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	B = R.B; B["terrain"] = {}; B["log"] = []
	R._tc = {}
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 11; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3

func gun(u, shots: int) -> Dictionary:
	var w = R.mkWeapon("battery", "F", {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0; w["shots"] = shots
	u["weapons"] = [w]
	return w

func near(a: float, b: float) -> bool: return absf(a - b) < 1e-6

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["the trade-off lives in the table (-10 to hit, +15 crit)", c_table],
		["the preview takes the aim cost off a called gun", c_preview],
		["the preview never goes under 5 to hit", c_preview_floor],
		["a called volley lands on its section only and gives the crit back", c_fire],
		["strike craft and destroyed sections cannot be called", c_ok],
		["Standard AI never calls", c_standard],
		["Veteran calls Engines on a ship under Full Ahead", c_vet_runner],
		["Veteran calls Engines on a Breakthrough fleet", c_vet_break],
		["Veteran calls Weapons on the top threat, nothing on the others", c_vet_threat],
		["Veteran never calls on a shot that should kill", c_vet_kill],
		["Veteran never calls a destroyed section", c_vet_broken],
	]
	var ok := 0; var bad := 0
	for c in cases:
		var r: Array = c[1].call()
		if r[0]: ok += 1; print("ok    ", c[0])
		else: bad += 1; printerr("FAIL  ", c[0], ": ", r[1])
	print("Issue 2033 rules tests (rules.gd): ", ok, " ok, ", bad, " FAIL")
	quit(1 if bad > 0 else 0)

func c_table() -> Array:
	var t = R.TB.CALLED_SHOT
	return [int(t["aim"]) == 10 and int(t["crit"]) == 15 and near(R.calledAim(), 10.0) and R.calledCrit() == 15, str(t)]

func c_preview() -> Array:
	fresh(["penitent"], "hegemony", ["h_dominion"]); var u = P[0]; var t = E[0]
	gun(u, 4)
	var plain = float(R.previewVolley(u, [0], t)[0]["hit"])
	var called = float(R.previewVolley(u, [0], t, "eng")[0]["hit"])
	return [plain > 15.0 and near(called, plain - 10.0), "hit " + str(plain) + " plain, " + str(called) + " called"]

func c_preview_floor() -> Array:
	fresh(["penitent"], "hegemony", ["h_dominion"]); var u = P[0]; var t = E[0]
	gun(u, 4); u["aim"] = -500
	var called = float(R.previewVolley(u, [0], t, "prow")[0]["hit"])
	return [near(called, 5.0), "called hit " + str(called)]

func c_fire() -> Array:
	fresh(["penitent"], "hegemony", ["h_dominion"]); var u = P[0]; var t = E[0]
	gun(u, 6); u["aim"] = 200
	t["hp"] = 99999; t["maxHp"] = 99999; t["shp"] = 0; R.syncShields(t); t["ev"] = 0
	for k in R.CALLED_SECS: t["sec"][k]["hp"] = 99999
	var crit0 = u["crit"]
	var ok = R.fireWeapon(u, 0, t, {"called": "eng"})
	var eng = 99999 - float(t["sec"]["eng"]["hp"]); var prow = 99999 - float(t["sec"]["prow"]["hp"]); var mid = 99999 - float(t["sec"]["mid"]["hp"])
	return [ok and eng > 0.0 and prow == 0.0 and mid == 0.0 and u["crit"] == crit0 and t.get("_calledSec") == null,
		"fired " + str(ok) + ", eng " + str(eng) + ", prow " + str(prow) + ", mid " + str(mid) + ", crit " + str(crit0) + " -> " + str(u["crit"])]

func c_ok() -> Array:
	fresh(["penitent"], "hegemony", ["h_dominion"]); var t = E[0]
	var live = R.calledOk(t, "prow") and R.calledOk(t, "mid") and R.calledOk(t, "eng") and not R.calledOk(t, "rear")
	t["sec"]["prow"]["hp"] = 0
	var sq = {"isSq": true, "side": "enemy", "sec": t["sec"]}
	return [live and not R.calledOk(t, "prow") and not R.calledOk(sq, "eng"), "live " + str(live)]

func _vet_setup(level: String) -> Array:
	fresh(["penitent", "penitent"], "hegemony", ["h_dominion"]); var u = E[0]
	R.AI_LEVEL = level
	var w = gun(u, 2)
	for p in P: p["hp"] = 99999; p["maxHp"] = 99999
	gun(P[0], 6); gun(P[1], 1)   # P[0] carries the most firepower: the top threat
	return [u, w]

func c_standard() -> Array:
	var s = _vet_setup("standard"); P[0]["fullAhead"] = true
	var a = R.aiCalledSec(s[0], s[1], P[0]); var b = R.aiCalledSec(s[0], s[1], P[1])
	R.AI_LEVEL = "veteran"
	return [a == null and b == null, str(a) + ", " + str(b)]

func c_vet_runner() -> Array:
	var s = _vet_setup("veteran"); P[1]["fullAhead"] = true
	var a = R.aiCalledSec(s[0], s[1], P[1])
	return [a == "eng", str(a)]

func c_vet_break() -> Array:
	var s = _vet_setup("veteran"); B["obj"] = {"type": "break", "exitC": 99}
	var a = R.aiCalledSec(s[0], s[1], P[1])
	return [a == "eng", str(a)]

func c_vet_threat() -> Array:
	var s = _vet_setup("veteran")
	var a = R.aiCalledSec(s[0], s[1], P[0]); var b = R.aiCalledSec(s[0], s[1], P[1])
	return [a == "prow" and b == null, str(a) + ", " + str(b)]

func c_vet_kill() -> Array:
	var s = _vet_setup("veteran"); P[0]["hp"] = 1; P[0]["shp"] = 0; R.syncShields(P[0]); P[0]["ev"] = 0
	if R.expectedVs(s[0], s[1], P[0]).hull < 1.0: return [false, "setup: the shot is not expected to kill"]
	var a = R.aiCalledSec(s[0], s[1], P[0])
	return [a == null, str(a)]

func c_vet_broken() -> Array:
	var s = _vet_setup("veteran"); P[0]["sec"]["prow"]["hp"] = 0
	var a = R.aiCalledSec(s[0], s[1], P[0])
	return [a == null, str(a)]
