# Issue 1560 (battle rules audit, Nov 21 2026) and R396 (Ryan, Nov 22 2026: firing ends a non-Glasswright ship's movement), on
# rules.gd. Twin of contrib/opus/tools/rules_1560_tests.js (battle.js), with the same case names; every case fails on main 8de3af33.
#   godot --headless --path godot --script res://rules/test/rules_1560_test.gd
# Three extra cases check Godot-only code: battle_api.move refusing a stale state, and the HUD volley preview (previewVolley).
# ramFrom (the browser's move-overlay ram marks) has no Godot twin, so case 15 checks ramInfo from a moved copy instead.
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
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 16; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3

func wpn(id: String, arc: String) -> Dictionary:
	var w = R.mkWeapon(id, arc, {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0
	return w

func near(a, b) -> bool: return absf(float(a) - float(b)) < 1e-9

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["R396: a Sunward ship that has fired cannot turn in place", c_r396_turn],
		["R396: a Glasswright turn after firing spends its post-fire move", c_r396_fade],
		["R396: a tree free turn (Cut and Turn) still turns a fired ship with no post-fire move left", c_r396_token],
		["R396: no ram after firing (non-Glasswright)", c_r396_ram],
		["1: a hit never heals a shieldless ship (damage taken stays at least 5%)", c_1],
		["2: a torpedo rear hit gives the real ship its Cut and Turn free turn", c_2],
		["3: escorts that flee are not raised again by the legion", c_3],
		["4: the rout line is checked as soon as the escorts flee", c_4],
		["5: Fleet drill keeps a wider tree sync radius", c_5],
		["6: a ship that broke through does not charge the Command as a loss", c_6],
		["7: point defence adds no attack value against ships", c_7],
		["8: a captured carrier stops leading its old side's wings", c_8],
		["9: the forecast meets the same armour as the hit (gauss, shred)", c_9],
		["10: a planned position never counts the ship itself as an escort", c_10],
		["11: fleet focus reads the shield pool, not the four side catches", c_11],
		["12: in alternating play a ship that has acted, or a cooling gun, is no threat this round", c_12],
		["13: a turn in place does not give back the free dive (Vell T2a)", c_13],
		["15: no ram after firing, from the move overlay either", c_15],
		["16: the corona splash hits only a ship next to the target", c_16],
		["16: the corona splash counts over the ship it hit, not in the target's hull number", c_16_attrib],
		["17: Full ahead opens again on the next turn", c_17],
		["18: the Garrison ally never turns a loss into a retreat", c_18_garrison],
		["18: the Chorus free pivot is offered with no movement left", c_18_pivot],
		["18 (Godot): a move to a hex the ship cannot reach is refused", c_18_move],
		["18 (Godot): a stale path to a still-reachable hex walks the legal path and pays its cost", c_18_stale_path],
		["18 (Godot): the same path with a stale cost pays today's cost", c_18_stale_cost],
		["18 (Godot): the volley preview never reads a miss as a routed hit", c_18_preview_route],
		["18 (Godot): the torpedo preview adds a Nemesis torpedo weakness", c_18_preview_nem],
	]
	var ok := 0; var bad := 0
	for c in cases:
		var r: Array = c[1].call()
		if r[0]: ok += 1; print("ok    ", c[0])
		else: bad += 1; printerr("FAIL  ", c[0], ": ", r[1])
	print("Issue 1560 rules tests (rules.gd): ", ok, " ok, ", bad, " FAIL")
	quit(1 if bad > 0 else 0)

# ---------- R396 ----------
func c_r396_turn() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	u["mp"] = 4; u["turnsLeft"] = 2; u["postFire"] = true; u["postMp"] = 0
	return [R.canRotate(u) == false, "canRotate " + str(R.canRotate(u))]
func c_r396_fade() -> Array:
	fresh(["i_blade"], "hegemony", ["h_picket"], "ithar"); var u = P[0]
	u["mp"] = 4; u["turnsLeft"] = 2; u["postFire"] = true; u["postMp"] = 2; u["pivotUsed"] = true
	R.rotateUnit(u, 1); R.rotateUnit(u, 1)
	return [R.z0(u.get("postMp")) == 0 and R.postFireMp(u) == 0, "postMp " + str(u.get("postMp")) + ", postFireMp " + str(R.postFireMp(u))]
func c_r396_token() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	u["mp"] = 4; u["turnsLeft"] = 2; u["postFire"] = true; u["postMp"] = 0; u["treeFreeTurn"] = 1; var f0 = int(u["facing"])
	var can: bool = R.canRotate(u); R.rotateUnit(u, 1)
	var ok: bool = can and int(u["facing"]) != f0 and R.z0(u.get("treeFreeTurn")) == 0 and R.z0(u.get("postMp")) == 0 and int(u["mp"]) == 4 and R.canRotate(u) == false
	return [ok, "canRotate " + str(can) + ", facing " + str(f0) + " to " + str(u["facing"]) + ", token " + str(u.get("treeFreeTurn")) + ", postMp " + str(u.get("postMp")) + ", mp " + str(u["mp"])]
func c_r396_ram() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; u["mp"] = 4
	var before: bool = R.ramInfo(u) != null; u["postFire"] = true; u["postMp"] = 0; var after = R.ramInfo(u)
	return [before and after == null, "ram before firing " + str(before) + ", after " + str(after != null)]
# ---------- group A ----------
func c_1() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var t = P[0]
	t["shMax"] = 0; t["ironCarry"] = 0.95; var m = R.cmdTaken(t)
	return [near(m, 0.05), "cmdTaken " + str(m)]
func c_2() -> Array:
	fresh(["penitent"], "deathless", ["d_harvester"]); var u = P[0]; var t = E[0]
	for x in E: x["weapons"] = []
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; t["facing"] = 0; t["hp"] = 9999; t["maxHp"] = 9999
	u["weapons"] = [wpn("torp", "F")]; B["tree"] = [{"k": "cutTurn", "key": "t1560:cutTurn"}]; u["treeFreeTurn"] = 0
	var i := 0
	while i < 20 and R.z0(u.get("treeFreeTurn")) != 1:
		u["weapons"][0]["fired"] = false; u["weapons"][0]["cdLeft"] = 0; u["postFire"] = false; R.fireWeapon(u, 0, t); i += 1
	return [R.z0(u.get("treeFreeTurn")) == 1, "treeFreeTurn on the real ship " + str(u.get("treeFreeTurn"))]
func c_3() -> Array:
	fresh(["penitent"], "deathless", ["d_harvester", "d_jackal", "d_scythe"])
	B["cfg"]["kind"] = "boss"; var boss = E[0]; boss["boss"] = true; boss["hp"] = floor(boss["maxHp"] * 0.4)
	var wreck = E[1]; wreck["dead"] = true; wreck["riseAt"] = B["round"]; wreck["fled"] = false
	R.escortsBreak(); var risen: Array = R.legionTurn("enemy")
	return [R.jt(wreck.get("dead")) and wreck.get("riseAt") == null and risen.size() == 0, "wreck dead " + str(wreck.get("dead")) + ", riseAt " + str(wreck.get("riseAt")) + ", risen " + str(risen.size())]
func c_4() -> Array:
	fresh(["penitent"], "deathless", ["d_scythe", "d_harvester", "d_harvester"])
	B["cfg"]["kind"] = "boss"; var boss = E[0]; boss["boss"] = true; boss["hp"] = floor(boss["maxHp"] * 0.4)
	R.escortsBreak()
	return [str(B.get("over")) == "win", "over " + str(B.get("over"))]
func c_5() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"])
	B["syncR"] = {"player": 8}; R.applyVerb("drill")
	return [near(R.syncR("player"), 8) and float(R.syncDmg("player")) >= 0.2, "syncR " + str(R.syncR("player")) + ", syncDmg " + str(R.syncDmg("player"))]
func c_6() -> Array:
	fresh(["penitent", "harrow"], "hegemony", ["h_picket"])
	B["round"] = 1; P[1]["dead"] = true; P[1]["exited"] = true; P[1]["fled"] = true
	return [near(R.cmdTier(), 0), "cmdTier " + str(R.cmdTier())]
# ---------- group B ----------
func c_7() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; t["q"] = 7; t["r"] = 5; var flak = wpn("flak", "T")
	var v = R.evalOffense(u, [flak], [t]); var vv = R.evalOffenseVet(u, [flak], [t], null)
	return [near(v, 0) and near(vv, 0), "evalOffense " + str(v) + ", evalOffenseVet " + str(vv)]
func c_8() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var c = P[0]; var w = E[1]
	w["isSq"] = true; w["parent"] = c["id"]; c["stance"] = "screen"
	var n: int = R.squadronsOf(c).size(); var st = R.wingStance(w)
	return [n == 0 and str(st) == "strike", "wings counted " + str(n) + ", wing stance " + str(st)]
func c_9() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 7; t["r"] = 5; t["facing"] = 3; t["shp"] = 0; R.syncShields(t); t["armor"] = 0.4; t["shredded"] = 0
	var w = wpn("gauss", "F"); w["armorPierce"] = 0.5; w["pierce"] = 0
	var e = R.expectedVs(u, w, t); var want = e.raw * (1 - 0.2) * R.braceMul(t) * R.cmdTaken(t) * R.guardMul(t)
	return [absf(e.hull - want) < 1e-6, "hull " + str(e.hull) + ", want " + str(want)]
func c_10() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	u["q"] = 6; u["r"] = 6; var fx = u["fx"].duplicate(); fx["lineGuard"] = 0.3; u["fx"] = fx
	var v = R.stateView(u, {"q": 7, "r": 6, "f": 0}); var m = R.guardMul(v)
	return [near(m, 1), "guardMul " + str(m)]
func c_11() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var t = P[0]; var sh = R.aiShooters()
	t["sh"] = [0, 0, 0, 0]; var a = R.aiFocusVal(t, sh); t["sh"] = [999, 999, 999, 999]; var b = R.aiFocusVal(t, sh)
	return [near(a, b), "with no side catches " + str(a) + ", with 999 each " + str(b)]
func c_12() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var p = P[0]; B["alt"] = true
	var w = null
	for x in p["weapons"]:
		if x["k"] != "flak": w = x; break
	w["fired"] = false; w["cdLeft"] = 0; p["braced"] = false
	p["activated"] = true; var a = R.aiGunLive(p, w); p["activated"] = false; w["cdLeft"] = 1; var b = R.aiGunLive(p, w)
	return [a == false and b == false, "activated " + str(a) + ", cooling " + str(b)]
# ---------- group C ----------
func c_13() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var u = P[0]
	u["q"] = 8; u["r"] = 8; u["facing"] = 0; u["mp"] = 4; u["turnsLeft"] = 2; E[0]["q"] = 9; E[0]["r"] = 8; E[1]["q"] = 9; E[1]["r"] = 9
	B["tree"] = [{"k": "mirrorAside", "key": "t1560:mirrorAside"}]; B["cmd"] = {"id": "surge", "side": "player", "round": B["round"], "tier": 0}
	var two := 0
	for s in R.computeReach(u).states:
		var n := 0
		for p in s.path:
			if R.jt(p.get("dived")): n += 1
		if n >= 2: two += 1
	return [two == 0, "states that dive twice for free " + str(two)]
func c_15() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 4; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; u["mp"] = 4; u["postFire"] = true; u["postMp"] = 0
	var v = R.dup(u); v["q"] = 5; v["r"] = 5; v["mp"] = 3
	var r = R.ramInfo(v)
	return [r == null, "ram from the moved copy " + str(r != null)]
func c_16() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var u = P[0]; var t = E[0]; var far = E[1]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; far["q"] = 8; far["r"] = 12; var hp0 = far["hp"]
	var w = wpn("doom", "F"); u["weapons"] = [w]
	B["tree"] = [{"k": "arcsWarm", "key": "t1560:arcsWarm", "n": 0.25}]; B["volleyMul"] = {"side": "player", "m": 1}
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	R.landVolley(u, w, t, {"quad": R.shieldQuad(t, u), "shBefore": R.z0(t.get("shp")), "shots": [true], "called": null, "res": res})
	return [far["hp"] == hp0, "ship 7 hexes away lost " + str(hp0 - far["hp"])]
func c_16_attrib() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket", "h_picket"]); var u = P[0]; var t = E[0]; var nb = E[1]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; nb["q"] = 9; nb["r"] = 5
	var th0 = float(t["hp"]); var n0 = float(nb["hp"]) + float(R.z0(nb.get("shp")))
	var w = wpn("doom", "F"); u["weapons"] = [w]
	B["tree"] = [{"k": "arcsWarm", "key": "t1560:arcsWarm", "n": 0.25}]; B["volleyMul"] = {"side": "player", "m": 1}
	var res = {"shield": 0, "hull": 0, "crits": 0, "hits": 0, "misses": 0, "sys": null}
	R.landVolley(u, w, t, {"quad": R.shieldQuad(t, u), "shBefore": R.z0(t.get("shp")), "shots": [true], "called": null, "res": res})
	var nLost = n0 - float(nb["hp"]) - float(R.z0(nb.get("shp")))
	return [int(R.hdist(t, nb)) == 1 and nLost > 0 and near(res.hull, th0 - float(t["hp"])), "target lost " + str(th0 - float(t["hp"])) + ", res.hull " + str(res.hull) + ", neighbour lost " + str(nLost)]
func c_17() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	u["moved"] = true; R.startSideTurn("player")
	return [u["moved"] == false and R.canOrder(u, "full") == true, "moved " + str(u["moved"]) + ", full " + str(R.canOrder(u, "full"))]
func c_18_garrison() -> Array:
	fresh(["penitent", "harrow"], "hegemony", ["h_picket"])
	P[0]["dead"] = true; P[1]["reinf"] = true
	return [R.survivorsP() == 0, "survivors " + str(R.survivorsP())]
func c_18_pivot() -> Array:
	fresh(["b_spitter"], "hegemony", ["h_picket"], "chorus"); var u = P[0]
	u["mp"] = 0; u["turnsLeft"] = 1; u["pivotUsed"] = false; u["postFire"] = false
	var turned := 0
	for s in R.computeReach(u).states:
		if int(s.q) == int(u["q"]) and int(s.r) == int(u["r"]) and int(s.f) != int(u["facing"]): turned += 1
	return [turned > 0, "turned states " + str(turned)]
func c_18_move() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	api.phase = "player"; u["mp"] = 4; u["activated"] = false
	var q0 = u["q"]; var r0 = u["r"]
	var st = {"q": q0 + 9, "r": r0, "f": 0, "t": 0, "cost": 1, "path": [{"q": q0 + 9, "r": r0, "f": 0}]}
	var moved = api.move(u["id"], st)
	return [moved == false and u["q"] == q0, "move accepted " + str(moved) + ", now at q " + str(u["q"])]
func c_18_stale_path() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	api.phase = "player"; u["mp"] = 4; u["activated"] = false
	var real = null
	for s in R.computeReach(u, true).states:
		if float(s.cost) == 1.0 and int(s.t) == 0 and not (int(s.q) == int(u["q"]) and int(s.r) == int(u["r"])): real = s; break
	if real == null: return [false, "no one-step state"]
	var st = {"q": real.q, "r": real.r, "f": real.f, "t": 0, "cost": 3, "path": [{"q": int(u["q"]) + 1, "r": int(u["r"]) + 2, "f": 0}, {"q": real.q, "r": real.r, "f": real.f}]}
	var moved = api.move(u["id"], st)
	return [moved and int(u["q"]) == int(real.q) and int(u["r"]) == int(real.r) and int(u["mp"]) == 3, "moved " + str(moved) + ", at " + str(u["q"]) + "," + str(u["r"]) + ", mp " + str(u["mp"])]
func c_18_stale_cost() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]
	api.phase = "player"; u["mp"] = 4; u["activated"] = false
	var real = null
	for s in R.computeReach(u, true).states:
		if float(s.cost) == 1.0 and int(s.t) == 0 and not (int(s.q) == int(u["q"]) and int(s.r) == int(u["r"])): real = s; break
	if real == null: return [false, "no one-step state"]
	var st = real.duplicate(true); st["cost"] = 3
	var moved = api.move(u["id"], st)
	return [moved and int(u["q"]) == int(real.q) and int(u["mp"]) == 3, "moved " + str(moved) + ", mp " + str(u["mp"])]
func _preview_shield(t, pool: float) -> float:
	var u = P[0]
	t["shp"] = pool; t["route"] = [0, 0, 0, 0]; R.syncShields(t)
	var w = wpn("autocannon", "F"); w["shots"] = 6; u["weapons"] = [w]
	var out = R.previewVolley(u, [0], t)
	return float(out[0]["shield"]) if out.has(0) else -1.0
func c_18_preview_route() -> Array:
	fresh(["penitent"], "hegemony", ["h_dominion"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; t["facing"] = 3
	var a = _preview_shield(t, 9.0); var b = _preview_shield(t, 9.4)
	return [absf(a - b) < 1e-6, "shield with a 9 pool " + str(a) + ", with 9.4 " + str(b)]
func c_18_preview_nem() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"]); var u = P[0]; var t = E[0]
	u["q"] = 5; u["r"] = 5; u["facing"] = 0; t["q"] = 8; t["r"] = 5; t["facing"] = 3
	var w = wpn("torp", "F"); u["weapons"] = [w]
	var p0 = R.previewVolley(u, [0], t)
	if not p0.has(0): return [false, "no preview"]
	var plain = float(p0[0]["hit"])
	t["nem"] = true; B["nem"] = {"weak": ["torp"], "fac": "hegemony"}
	var weak = float(R.previewVolley(u, [0], t)[0]["hit"])
	return [near(weak, minf(95.0, plain + 15.0)), "hit " + str(plain) + " plain, " + str(weak) + " with the weakness"]
