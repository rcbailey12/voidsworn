# Issue 1479 (independent game audit Nov 21, F-01 and F-03): battle endings when a boarding overruns a special enemy, when a
# carrier is captured, and when an Eclipse wreck is about to rise. The state cases have a browser twin with the same names,
# contrib/opus/tools/rules_1479_tests.js (battle.js).
#   godot --headless --path godot --script res://rules/test/rules_1479_test.gd
# Every case fails on main 6aca4f9e (before the fix) except two guards: an ordinary hull is still captured, and a wreck with no room lets the fight end.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(fleet: Array, fac: String, enemies: Array, pfac: String = "voidsworn") -> void:
	api.new_battle_scenario({"seed": 7, "admiral": "vex", "fac_player": pfac, "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	B = R.B; B["terrain"] = {}; B["log"] = []
	R._tc = {}
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 16; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3
	B["cp0"] = null   # no rout check: these cases are about who is left
	R.events_on = true; R.events.clear()

# u boards t from the next hex with a crew t cannot hold
func board(u, t) -> bool:
	u["q"] = int(t["q"]) - 1; u["r"] = int(t["r"]); u["crew"] = 9999; u["boarded"] = false; u["mp"] = 4; t["crew"] = 1; t["repel"] = false
	return R.boardUnit(u, t)

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["1: overrunning the Nemesis flagship destroys it", c_nem],
		["1: overrunning a hunt target ends the fight as its kill does", c_hunt],
		["1: overrunning a convoy transport counts as a transport destroyed", c_convoy],
		["1: an ordinary hull is still captured (guard)", c_plain],
		["2: a captured carrier's wings lose their carrier", c_carrier],
		["3: the last Eclipse ship of yours reassembling keeps the fight open, and it rises", c_rise_player],
		["3: the last enemy Eclipse ship reassembling is not a win yet", c_rise_enemy],
		["3: a wreck with no room to rise lets the fight end", c_rise_stuck],
		["3: a ship rising next round counts toward a breakthrough", c_rise_break],
		["3: a big wreck rising next round holds the enemy above the rout line", c_rise_rout],
		["3: a small wreck rising does not stop a fleet that has broken (guard)", c_rise_rout_small],
	]
	var ok := 0; var bad := 0
	for c in cases:
		var r: Array = c[1].call()
		if r[0]: ok += 1; print("ok    ", c[0])
		else: bad += 1; printerr("FAIL  ", c[0], ": ", r[1])
	print("Issue 1479 rules tests (rules.gd): ", ok, " ok, ", bad, " FAIL")
	quit(1 if bad > 0 else 0)

func c_nem() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var t = E[0]; t["nemFlag"] = true
	board(P[0], t)
	return [R.jt(t.get("dead")) and t["side"] == "enemy" and not R.jt(t.get("captured")) and t.get("killCause") == "dark", "dead " + str(t.get("dead")) + ", side " + str(t["side"]) + ", captured " + str(t.get("captured"))]
func c_hunt() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var t = E[0]; t["flagship"] = true
	B["obj"] = {"type": "hunt"}
	board(P[0], t)
	return [str(B.get("over")) == "win" and R.jt(B.get("routed")) and R.jt(t.get("dead")) and t["side"] == "enemy", "over " + str(B.get("over")) + ", dead " + str(t.get("dead")) + ", side " + str(t["side"])]
func c_convoy() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket", "h_picket"]); var t = E[0]; t["transport"] = true; E[1]["transport"] = true
	B["obj"] = {"type": "intercept", "need": 2, "total": 2}
	board(P[0], t)
	return [R.jt(t.get("dead")) and not R.jt(t.get("fled")) and t["side"] == "enemy" and int(B["obj"].get("kill", -1)) == 1 and not R.jt(B.get("over")), "dead " + str(t.get("dead")) + ", side " + str(t["side"]) + ", kill " + str(B["obj"].get("kill")) + ", over " + str(B.get("over"))]
func c_plain() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var t = E[0]
	board(P[0], t)
	return [t["side"] == "player" and R.jt(t.get("captured")) and not R.jt(t.get("dead")), "side " + str(t["side"]) + ", captured " + str(t.get("captured"))]
func c_carrier() -> Array:
	fresh(["penitent"], "corsair", ["c_hulk", "c_hulk"]); var c = E[0]
	var hexes = R.launchHexes(c)
	var w = R.makeWing(c, hexes[0], R.wingKind(c))
	board(P[0], c)
	return [c["side"] == "player" and w["side"] == "enemy" and w.get("parent") == null, "carrier " + str(c["side"]) + ", wing " + str(w["side"]) + ", wing parent " + str(w.get("parent"))]

func _legion(side: String) -> void:
	B["legion"][side]["max"] = 1; B["legion"][side]["used"] = 0
func c_rise_player() -> Array:
	fresh(["d_jackal"], "hegemony", ["h_picket"], "deathless"); var u = P[0]; u["pflag"] = false; _legion("player")
	u["hp"] = 0; R.killUnit(u, E[0])
	var open: bool = not R.jt(B.get("over")) and u.get("riseAt") != null
	B["round"] = int(u["riseAt"]); R.legionTurn("player")
	return [open and not R.jt(u.get("dead")) and not R.jt(B.get("over")), "open " + str(open) + ", over " + str(B.get("over")) + ", dead " + str(u.get("dead"))]
func c_rise_enemy() -> Array:
	fresh(["penitent"], "deathless", ["d_jackal"]); var t = E[0]; _legion("enemy")
	t["hp"] = 0; R.killUnit(t, P[0])
	return [not R.jt(B.get("over")) and t.get("riseAt") != null, "over " + str(B.get("over")) + ", riseAt " + str(t.get("riseAt"))]
func c_rise_stuck() -> Array:
	fresh(["penitent"], "deathless", ["d_jackal"]); var t = E[0]; _legion("enemy")
	t["hp"] = 0; R.killUnit(t, P[0])
	for h in R.boardHexes(): B["terrain"][R.hkey(h.q, h.r)] = "rock"   # nowhere to reassemble
	R._tc = {}
	B["round"] = int(t["riseAt"]); R.legionTurn("enemy")
	return [str(B.get("over")) == "win" and R.jt(t.get("dead")), "over " + str(B.get("over")) + ", dead " + str(t.get("dead"))]
func c_rise_break() -> Array:
	fresh(["d_jackal", "d_jackal"], "hegemony", ["h_picket"], "deathless"); var a = P[0]; var b = P[1]; b["pflag"] = false; _legion("player")
	B["obj"] = {"type": "break", "need": 2}
	a["exited"] = true; a["dead"] = true; a["fled"] = true
	b["hp"] = 0; R.killUnit(b, E[0])
	return [not R.jt(B.get("over")) and b.get("riseAt") != null, "over " + str(B.get("over")) + ", riseAt " + str(b.get("riseAt"))]
# Artoo on PR 1621: with the real starting strength and the rout rule on, a pending rise counts toward the rout line too
func _cp0() -> void:
	B["cp0"] = {"player": R.sideCP("player"), "enemy": R.sideCP("enemy")}
func c_rise_rout() -> Array:
	fresh(["penitent"], "deathless", ["d_jackal"]); var t = E[0]; _legion("enemy"); _cp0()
	t["hp"] = 0; R.killUnit(t, P[0])
	return [not R.jt(B.get("over")) and t.get("riseAt") != null, "over " + str(B.get("over")) + ", cp0 " + str(B["cp0"])]
func c_rise_rout_small() -> Array:
	fresh(["penitent"], "deathless", ["d_scythe", "d_jackal", "d_jackal"]); _legion("enemy"); _cp0()
	E[1]["reanimated"] = true; E[2]["reanimated"] = true   # these two stay down
	E[1]["hp"] = 0; R.killUnit(E[1], P[0]); E[2]["hp"] = 0; R.killUnit(E[2], P[0])
	var t = E[0]; t["hp"] = 0; R.killUnit(t, P[0])
	return [str(B.get("over")) == "win" and t.get("riseAt") != null, "over " + str(B.get("over")) + ", riseAt " + str(t.get("riseAt")) + ", cp0 " + str(B["cp0"])]
