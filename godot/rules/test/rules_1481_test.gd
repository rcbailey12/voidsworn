# Issue 1481 (independent game audit Nov 21, F-08 to F-11, F-14): shield drops and damage the battle scene never heard about,
# on rules.gd. The state cases have a browser twin with the same names, contrib/opus/tools/rules_1481_tests.js (battle.js).
#   godot --headless --path godot --script res://rules/test/rules_1481_test.gd
# Every case fails on main 1a000813 (before the fix) except two guards: the one-break volley and the good blink.
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
	R.events_on = true; R.events.clear()

func evs(kind: String, unit = null) -> Array:
	var o := []
	for e in R.events:
		if e.get("t") == kind and (unit == null or str(e.get("unit")) == str(unit) or str(e.get("target")) == str(unit)): o.append(e)
	return o

func fx_set(u, k: String, v) -> void:
	var f: Dictionary = (u["fx"] as Dictionary).duplicate(); f[k] = v; u["fx"] = f

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["1: an ion storm that empties the pool sends the break", c_storm],
		["1: an ion storm that leaves under 1 point empties the pool", c_storm_clamp],
		["1: a solar flare sends the break", c_flare],
		["1: losing the mid section sends the break", c_mid],
		["1: a mid-section loss inside a volley sends one break, not two", c_mid_volley],
		["1: an ion pulse that empties the pool sends the break", c_ionpulse],
		["1: a nova that empties the pool sends the break", c_nova],
		["2: a ram spends the shield through the shared spend (routing loss)", c_ram_route],
		["2: a ram that empties the pool sends the break and the readout", c_ram_break],
		["3: braced counter-fire sends a hit", c_riposte],
		["3: the ram shockwave sends a hit", c_ram_splash],
		["3: a reactor going up sends a hit", c_chain],
		["5: a blink to a bad hex is refused before it counts or plays", c_blink_bad],
		["5: a good blink still jumps", c_blink_good],
		["5: a nova with no hex is refused, nothing counted", c_nova_bad],
		["review: a nova that takes out the generator with shield left sends one break", c_nova_section],
		["review: a nova aimed off its arc, out of range, fractional or malformed spends nothing", c_nova_aims],
	]
	var ok := 0; var bad := 0
	for c in cases:
		var r: Array = c[1].call()
		if r[0]: ok += 1; print("ok    ", c[0])
		else: bad += 1; printerr("FAIL  ", c[0], ": ", r[1])
	print("Issue 1481 rules tests (rules.gd): ", ok, " ok, ", bad, " FAIL")
	quit(1 if bad > 0 else 0)

func c_storm() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	B["terrain"][R.hkey(u["q"], u["r"])] = "storm"; R._tc = {}
	u["st"]["shieldOff"] = 1   # no regen this tick
	u["shp"] = 6; R.syncShields(u); R.events.clear()
	R.startSideTurn("player")
	return [float(u["shp"]) == 0.0 and evs("shield_down", u["id"]).size() == 1, "shp " + str(u["shp"]) + ", breaks " + str(evs("shield_down", u["id"]).size())]
func c_storm_clamp() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	B["terrain"][R.hkey(u["q"], u["r"])] = "storm"; R._tc = {}
	u["st"]["shieldOff"] = 1   # no regen this tick, so the storm alone sets the pool
	u["shp"] = 10.5; R.syncShields(u); R.events.clear()
	R.startSideTurn("player")
	return [float(u["shp"]) == 0.0 and evs("shield_down", u["id"]).size() == 1, "shp " + str(u["shp"]) + ", breaks " + str(evs("shield_down", u["id"]).size())]
func c_flare() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	B["event"] = {"k": "flare", "r": B["round"], "done": true}; R.events.clear()
	R.startSideTurn("player")
	return [float(u["shp"]) == 0.0 and evs("shield_down", u["id"]).size() == 1, "shp " + str(u["shp"]) + ", breaks " + str(evs("shield_down", u["id"]).size())]
func c_mid() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; R.events.clear()
	R.damageSection(u, "mid", 99999, E[0])
	return [float(u["shp"]) == 0.0 and evs("shield_down", u["id"]).size() == 1, "shp " + str(u["shp"]) + ", breaks " + str(evs("shield_down", u["id"]).size())]
func c_mid_volley() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var a = P[0]; var t = E[0]
	a["q"] = 5; a["r"] = 5; a["facing"] = 0; t["q"] = 7; t["r"] = 5; t["facing"] = 0   # a hits t from behind... any side works
	t["sec"]["mid"]["hp"] = 1; t["shp"] = 2; R.syncShields(t); t["hp"] = 99999; t["maxHp"] = 99999; t["ev"] = 0
	var w = R.mkWeapon("battery", "F", {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0; w["shots"] = 6
	a["weapons"] = [w]; a["aim"] = 200
	var quad = R.shieldQuad(t, a)
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	R.events.clear()
	R.landVolley(a, w, t, {"quad": quad, "shBefore": 2.0, "shots": [true, true, true, true, true, true], "called": "mid", "res": res})
	var n := evs("shield_down", t["id"]).size()
	return [n == 1 and float(t["shp"]) == 0.0, "breaks " + str(n) + ", shp " + str(t["shp"]) + ", mid hp " + str(t["sec"]["mid"]["hp"])]
func c_ionpulse() -> Array:
	fresh(["penitent"], "hegemony", ["h_interdictor"]); var u = E[0]; var t = P[0]
	u["q"] = 10; u["r"] = 6; t["shp"] = 1; R.syncShields(t); u["abCd"] = 0; R.events.clear()
	var ok: bool = R.useAbility(u, null)
	return [ok and float(t["shp"]) == 0.0 and evs("shield_down", t["id"]).size() == 1, "used " + str(ok) + ", shp " + str(t["shp"]) + ", breaks " + str(evs("shield_down", t["id"]).size())]
func c_nova() -> Array:
	fresh(["ascendant"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 10; t["r"] = 5; t["shp"] = 2; R.syncShields(t); t["hp"] = 99999; t["maxHp"] = 99999
	u["abCd"] = 0; R.events.clear()
	var ok: bool = R.useAbility(u, {"hex": {"q": 10, "r": 5}})
	return [ok and float(t["shp"]) == 0.0 and evs("shield_down", t["id"]).size() == 1, "used " + str(ok) + ", shp " + str(t["shp"]) + ", breaks " + str(evs("shield_down", t["id"]).size())]

func _ram_setup(shp: float, routed: bool) -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; u["mp"] = 4; u["turnsLeft"] = 2; t["q"] = 8; t["r"] = 5; t["facing"] = 3
	t["hp"] = 99999; t["maxHp"] = 99999
	t["shp"] = shp; t["route"] = [0, 0, 0, 0]
	var qd = R.shieldQuad(t, u)
	if routed: t["route"][qd] = 1
	R.syncShields(t); R.events.clear()
	return [u, t, qd]
func c_ram_route() -> Array:
	var s = _ram_setup(200, true); var u = s[0]; var t = s[1]
	var info = R.ramInfo(u); var e = R.ramEstimate(u, t, info.path.size())
	var want: float = max(0.0, 200.0 - float(e.soak) * 1.5 * (1.0 + float(R.TB.SHIELD_ROUTE_LOSS)))
	R.ramUnit(u)
	return [float(e.soak) > 0 and absf(float(t["shp"]) - want) < 1e-9, "soak " + str(e.soak) + ", shp " + str(t["shp"]) + ", want " + str(want)]
func c_ram_break() -> Array:
	var s = _ram_setup(3, false); var u = s[0]; var t = s[1]
	R.ramUnit(u)
	var rams := evs("ram", u["id"]); var sh = rams[0].get("sh") if rams.size() > 0 else null
	var zero: bool = sh is Array and (sh as Array).size() == 4 and (sh as Array).all(func(x): return float(x) == 0.0)
	return [float(t["shp"]) == 0.0 and evs("shield_down", t["id"]).size() == 1 and zero, "shp " + str(t["shp"]) + ", breaks " + str(evs("shield_down", t["id"]).size()) + ", ram readout " + str(sh)]
func c_riposte() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var a = E[0]; var t = P[0]
	a["q"] = 7; a["r"] = 5; a["facing"] = 3; t["q"] = 5; t["r"] = 5; t["braced"] = true; fx_set(t, "riposte", 18)
	var w = R.mkWeapon("battery", "F", {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	var hp0 = a["hp"]; R.events.clear()
	R.landVolley(a, w, t, {"quad": R.shieldQuad(t, a), "shBefore": float(t["shp"]), "shots": [true], "called": null, "res": res})
	var hits := []
	for e in evs("hit", a["id"]):
		if str(e["target"]) == str(a["id"]): hits.append(e)
	return [hits.size() == 1 and int(hits[0]["hull"]) == 18 and hits[0].get("float") == false and a["hp"] == hp0 - 18, "hits on the shooter " + str(hits) + ", hp " + str(hp0) + " to " + str(a["hp"])]
func c_ram_splash() -> Array:
	var s = _ram_setup(0, false); var u = s[0]; var t = s[1]
	var x = E[1] if E.size() > 1 else null
	if x == null:
		return [false, "need a second enemy"]
	x["q"] = 9; x["r"] = 5; x["hp"] = 99999; x["maxHp"] = 99999; fx_set(u, "ramSplash", 0.25); R.events.clear()
	R.ramUnit(u)
	var hits := []
	for e in R.events:
		if e.get("t") == "hit" and str(e.get("target")) == str(x["id"]): hits.append(e)
	return [hits.size() == 1 and int(hits[0]["hull"]) > 0, "hits on the neighbour " + str(hits)]
func c_chain() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var by = P[0]; var t = E[0]; var x = E[1]
	t["q"] = 10; t["r"] = 5; x["q"] = 11; x["r"] = 5; x["hp"] = 99999; x["maxHp"] = 99999; fx_set(by, "chainBoom", 20); R.events.clear()
	t["hp"] = 0; R.killUnit(t, by)
	var hits := []
	for e in R.events:
		if e.get("t") == "hit" and str(e.get("target")) == str(x["id"]): hits.append(e)
	return [hits.size() == 1 and int(hits[0]["hull"]) == 20, "hits on the neighbour " + str(hits)]
func c_blink_bad() -> Array:
	fresh(["i_blade"], "hegemony", ["h_picket"], "ithar"); var u = P[0]; u["abCd"] = 0
	B["usage"] = {"ab": {}}; R.UNDO = {"spent": false, "stack": [1]}; R.events.clear()
	var q0 = u["q"]; var r0 = u["r"]
	var ok: bool = R.useAbility(u, {"hex": {"q": int(q0) + 9, "r": int(r0)}})
	var counted = R.z0(B["usage"]["ab"].get("blink"))
	var ability_ev := evs("ability", u["id"]).size()
	var spent: bool = R.UNDO.spent
	R.UNDO = null
	return [not ok and counted == 0 and ability_ev == 0 and not spent and u["q"] == q0, "used " + str(ok) + ", counted " + str(counted) + ", ability events " + str(ability_ev) + ", undo spent " + str(spent)]
func c_blink_good() -> Array:
	fresh(["i_blade"], "hegemony", ["h_picket"], "ithar"); var u = P[0]; u["abCd"] = 0; B["usage"] = {"ab": {}}
	var h = R.blinkHexes(u)[0]
	var ok: bool = R.useAbility(u, {"hex": {"q": h.q, "r": h.r}})
	return [ok and u["q"] == h.q and u["r"] == h.r and R.z0(B["usage"]["ab"].get("blink")) == 1 and evs("blink", u["id"]).size() == 1, "used " + str(ok) + " at " + str(u["q"]) + "," + str(u["r"])]
func c_nova_bad() -> Array:
	fresh(["ascendant"], "hegemony", ["h_picket"]); var u = P[0]; u["abCd"] = 0; B["usage"] = {"ab": {}}; R.events.clear()
	var ok: bool = R.useAbility(u, null)
	var counted = R.z0(B["usage"]["ab"].get("nova"))
	return [not ok and counted == 0 and evs("ability", u["id"]).size() == 0 and float(u["abCd"]) == 0.0, "used " + str(ok) + ", counted " + str(counted)]
# review of PR 1595 (OpenAI, finding 1): the direct spend leaves shield, the hull share destroys the mid section, and the
# section loss empties the pool. One break, not a second one from shieldDrained with the old pool.
func c_nova_section() -> Array:
	fresh(["ascendant"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 10; t["r"] = 5; t["hp"] = 99999; t["maxHp"] = 99999
	t["shp"] = float(t["shMax"]); R.syncShields(t); t["sec"]["mid"]["hp"] = 1; t["_calledSec"] = "mid"
	u["abCd"] = 0; R.events.clear()
	var ok: bool = R.useAbility(u, {"hex": {"q": 10, "r": 5}})
	var n := evs("shield_down", t["id"]).size()
	return [ok and bool(t["sec"]["mid"].get("broken")) and float(t["shp"]) == 0.0 and n == 1, "used " + str(ok) + ", mid broken " + str(t["sec"]["mid"].get("broken")) + ", shp " + str(t["shp"]) + ", breaks " + str(n)]
# finding 3: only a hex novaTargets offers (forward arc, range 3 to 9); a refused aim counts nothing and keeps the cooldown
func c_nova_aims() -> Array:
	fresh(["ascendant"], "hegemony", ["h_picket"]); var u = P[0]
	u["q"] = 8; u["r"] = 6; u["facing"] = 0; B["usage"] = {"ab": {}}
	var bad := [{"hex": {"q": 3, "r": 6}}, {"hex": {"q": 9, "r": 6}}, {"hex": {"q": 10.5, "r": 6}}, {"hex": {"q": "11", "r": 6}}, {"hex": {"q": 11}}, {"q": 11, "r": 6}]
	var legal = R.novaTargets(u)
	var far := {}
	for h in R.boardHexes():
		if R.hdist(u, h) > 9 and R.inArc(u, h, "F"): far = {"q": h.q, "r": h.r}; break
	if not far.is_empty(): bad.append({"hex": far})
	for arg in bad:
		u["abCd"] = 0; R.events.clear()
		var ok: bool = R.useAbility(u, arg)
		if ok or R.z0(B["usage"]["ab"].get("nova")) != 0 or float(u["abCd"]) != 0.0: return [false, "aim " + str(arg) + " was taken"]
	var g = legal[0]; u["abCd"] = 0
	var ok2: bool = R.useAbility(u, {"hex": {"q": g.q, "r": g.r}})
	return [ok2 and R.z0(B["usage"]["ab"].get("nova")) == 1 and not far.is_empty(), "legal shot used " + str(ok2) + ", far hex " + str(far)]
