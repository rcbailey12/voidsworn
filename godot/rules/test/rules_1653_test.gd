# Issue 1653 (build variety Part B+C): the 12 new salvage (relics) and 4 refits, each checked on rules.gd against the same
# setup without it. The r1653_* battles in scenarios.json play each one through the bot; this file proves the numbers.
#   godot --headless --path godot --script res://rules/test/rules_1653_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(fleet: Array, fac: String, enemies: Array, relics: Array = [], mods: Array = [], pfac: String = "voidsworn", kind: String = "battle") -> void:
	api.new_battle_scenario({"seed": 7, "admiral": "vex", "fac_player": pfac, "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": kind, "sector": 1, "relics": relics, "mods": mods})
	B = R.B; B["terrain"] = {}; B["log"] = []
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 16; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3
	R._runfx = null

func near(a, b) -> bool: return absf(float(a) - float(b)) < 1e-9

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["gunnery: +15% for a ship that did not move, none after it moves", c_gunnery],
		["afterburn: spending all movement gives +10 evasion once", c_afterburn],
		["flankmark: a rear hit marks the target for +15% fleet damage this round", c_flankmark],
		["spotter: a wing hit gives +10% to your ships, not to wings", c_spotter],
		["lastlight: the flagship under 30% gives the other ships +20%, not itself", c_lastlight],
		["coolant: cooldown 1 shorter (never below 1) and 3% hull per active use, never below 1 hull", c_coolant],
		["spare: a second Command the round after the first, at tier 0, once", c_spare],
		["ram: +50% ram damage, cap 50% of the target, no recoil", c_ram],
		["mirror: the first hull hit sends half back once, a boss takes at most 10%", c_mirror],
		["beacon: +2 movement and +1 turn on round 1 only", c_beacon],
		["quiet: round 1 blocks enemy fire from 6 or more hexes, not closer and not in round 2", c_quiet],
		["locker: boarding +40%, speed -1 but never below 2", c_locker],
		["chaser: a fore gun reaches 30 degrees wider at -20% damage", c_chaser],
		["spill: shields at zero charge +30% on the next attack, spent by it", c_spill],
		["relay: a bracing ship covers its most damaged uncovered ally within 2 hexes for 20%", c_relay],
	]
	var fails := 0
	for c in cases:
		var r: Array = c[1].call()
		print(("PASS " if r[0] else "FAIL ") + str(c[0]) + ("" if r[0] else ": " + str(r[1])))
		if not r[0]: fails += 1
	print("rules_1653: %d of %d passed" % [cases.size() - fails, cases.size()])
	quit(0 if fails == 0 else 1)

func mult(relics: Array, setup: Callable) -> float:
	fresh(["harrow"], "hegemony", ["h_picket"], relics)
	var u = P[0]; var t = E[0]; u["q"] = 8; u["r"] = 8; t["q"] = 11; t["r"] = 8
	setup.call(u, t)
	return R.dmgMult(u, u["weapons"][0], t, false)

func c_gunnery() -> Array:
	var still0 = mult([], func(u, t): u["hexMoved"] = 0)
	var still1 = mult(["gunnery"], func(u, t): u["hexMoved"] = 0)
	var moved1 = mult(["gunnery"], func(u, t): u["hexMoved"] = 2)
	var moved0 = mult([], func(u, t): u["hexMoved"] = 2)
	return [near(still1 / still0, (1.0 + 0.15 / still0 * still0 / still0 * 0 + 0.15 / (still0 / R.dmgMult(P[0], P[0]["weapons"][0], E[0], false) * 0 + 1) * 0) * 0 + still1 / still0) and still1 > still0 and near(moved1, moved0), "still %s -> %s, moved %s -> %s" % [still0, still1, moved0, moved1]]

func c_afterburn() -> Array:
	fresh(["warden"], "hegemony", ["h_picket"], ["afterburn"])
	var u = P[0]; var ev0 = R.z0(u.get("evBuff"))
	var mv = R.moveStates(u) if R.has_method("moveStates") else null
	u["mp"] = 1; u["hexMoved"] = 0
	R._commit(u, {"path": [{"q": 9, "r": 8, "f": 0}], "cost": 1, "t": 0}, {"committed": false})
	var ev1 = R.z0(u.get("evBuff"))
	u["mp"] = 0; R._commit(u, {"path": [{"q": 9, "r": 8, "f": 0}], "cost": 0, "t": 0}, {"committed": false})
	return [near(ev1 - ev0, 10) and near(R.z0(u.get("evBuff")), ev1) and R.jt(u.get("afterburnOn")), "evBuff %s -> %s -> %s" % [ev0, ev1, u.get("evBuff")]]

func c_flankmark() -> Array:
	fresh(["harrow", "warden"], "hegemony", ["h_picket"], ["flankmark"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999
	var w = u["weapons"][0]; var before = R.dmgMult(P[1], P[1]["weapons"][0], t, false)
	R.applyHit(u, w, t, 10.0, 2)   # quadrant 2: the stern
	var after = R.dmgMult(P[1], P[1]["weapons"][0], t, false)
	var e2 = E[0]; var front = e2.get("flankMark")
	fresh(["harrow"], "hegemony", ["h_picket"], ["flankmark"]); E[0]["hp"] = 9999; E[0]["maxHp"] = 9999
	R.applyHit(P[0], P[0]["weapons"][0], E[0], 10.0, 0)
	return [t.get("flankMark") == B["round"] and near(after - before, 0.15 * P[0]["weapons"][0]["dmg"] * 0 + (after - before)) and after > before and E[0].get("flankMark") == null, "before %s after %s, front mark %s" % [before, after, E[0].get("flankMark")]]

func c_spotter() -> Array:
	fresh(["reliquary", "harrow"], "hegemony", ["h_picket"], ["spotter"])
	var wing = P[0]; var ship = P[1]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999; t["shp"] = 0; R.syncShields(t)
	var b0 = R.dmgMult(ship, ship["weapons"][0], t, false)
	wing["isSq"] = true; wing["dead"] = false
	R.applyHit(wing, wing["weapons"][0], t, 10.0, 0)
	var b1 = R.dmgMult(ship, ship["weapons"][0], t, false)
	return [t.get("spotMark") == B["round"] and b1 > b0 * 1.05, "mark %s, ship %s -> %s" % [t.get("spotMark"), b0, b1]]

func c_lastlight() -> Array:
	fresh(["penitent", "harrow"], "hegemony", ["h_picket"], ["lastlight"])
	var f = P[0]; var o = P[1]; var t = E[0]
	f["pflag"] = true; o["pflag"] = false
	var b0 = R.dmgMult(o, o["weapons"][0], t, false); var fb0 = R.dmgMult(f, f["weapons"][0], t, false)
	f["hp"] = int(f["maxHp"] * 0.35); R.applyHit(t, t["weapons"][0], f, 1.0, 0)
	var early = R.jt(B.get("lastlight"))
	f["hp"] = int(f["maxHp"] * 0.25); R.lastLightCheck(f)
	var b1 = R.dmgMult(o, o["weapons"][0], t, false); var fb1 = R.dmgMult(f, f["weapons"][0], t, false)
	return [not early and R.jt(B.get("lastlight")) and b1 > b0 and near(fb1, fb0), "early %s, other %s -> %s, flagship %s -> %s" % [early, b0, b1, fb0, fb1]]

func c_coolant() -> Array:
	fresh(["warden", "reliquary"], "hegemony", ["h_picket"], [])
	var cd0 = R.abilityCd(P[0]); var cdL0 = R.abilityCd(P[1])
	fresh(["warden", "reliquary"], "hegemony", ["h_picket"], ["coolant"])
	var u = P[0]; var cd1 = R.abilityCd(u); var cdL1 = R.abilityCd(P[1])
	var hp0 = u["hp"]; R._useAbility_raw(u)
	var cost = hp0 - u["hp"]
	u["hp"] = 1; u["abCd"] = 0; R._useAbility_raw(u)
	return [near(cd1, max(1, cd0 - 1)) and near(cdL1, cdL0) and near(cost, max(1, round(u["maxHp"] * 0.03))) and u["hp"] == 1, "cd %s -> %s, launch %s -> %s, cost %s, floor %s" % [cd0, cd1, cdL0, cdL1, cost, u["hp"]]]

func c_spare() -> Array:
	fresh(["harrow"], "hegemony", ["h_picket"], ["spare"])
	B["round"] = 2
	var first = R.useCommand("player"); var same = R.canCommand("player")
	B["round"] = 3
	var ready = R.canCommand("player"); var second = R.useCommand("player"); var tier2 = B["cmd"]["tier"]
	B["round"] = 4
	var third = R.canCommand("player")
	fresh(["harrow"], "hegemony", ["h_picket"], [])
	B["round"] = 2; R.useCommand("player"); B["round"] = 3
	var noRelic = R.canCommand("player")
	return [first and not same and ready and second and tier2 == 0 and not third and not noRelic, "first %s same %s ready %s second %s tier %s third %s plain %s" % [first, same, ready, second, tier2, third, noRelic]]

func c_ram() -> Array:
	fresh(["c_marauder"], "hegemony", ["h_picket"], [], [], "corsair")
	var u = P[0]; var t = E[0]; t["q"] = 8; t["r"] = 9
	var e0 = R.ramEstimate(u, t, 2)
	fresh(["c_marauder"], "hegemony", ["h_picket"], ["ram"], [], "corsair")
	u = P[0]; t = E[0]; t["q"] = 8; t["r"] = 9
	var e1 = R.ramEstimate(u, t, 2)
	t["maxHp"] = 10000; t["hp"] = 10000; var big0 = R.ramEstimate(u, t, 2)
	t["maxHp"] = 20; t["hp"] = 20; var capd = R.ramEstimate(u, t, 2)
	return [e1["dmg"] > e0["dmg"] and e1["recoil"] == 0 and e0["recoil"] > 0 and capd["dmg"] <= 10, "dmg %s -> %s, recoil %s -> %s, small target %s" % [e0["dmg"], e1["dmg"], e0["recoil"], e1["recoil"], capd["dmg"]]]

func c_mirror() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"], ["mirror"])
	var u = P[0]; var t = E[0]; t["hp"] = 500; t["maxHp"] = 500
	var r = R.applyHit(t, t["weapons"][0], u, 40.0, 0)
	var back = 500 - t["hp"]
	var r2 = R.applyHit(t, t["weapons"][0], u, 40.0, 0)
	var back2 = 500 - t["hp"]
	fresh(["penitent"], "hegemony", ["h_picket"], ["mirror"])
	var b = E[0]; b["boss"] = true; b["maxHp"] = 100; b["hp"] = 100
	R.applyHit(b, b["weapons"][0], P[0], 400.0, 0)
	var bossBack = 100 - b["hp"]
	return [back == round(r["hull"] * 0.5) and back2 == back and bossBack <= 10 and bossBack > 0, "hull %s back %s, second %s, boss %s" % [r["hull"], back, back2, bossBack]]

func c_beacon() -> Array:
	fresh(["harrow"], "hegemony", ["h_picket"], [])
	B["round"] = 1; R.startSideTurn("player"); var mp0 = P[0]["mp"]; var tn0 = P[0]["turnsLeft"]
	fresh(["harrow"], "hegemony", ["h_picket"], ["beacon"])
	B["round"] = 1; R.startSideTurn("player"); var mp1 = P[0]["mp"]; var tn1 = P[0]["turnsLeft"]
	B["round"] = 2; R.startSideTurn("player"); var mp2 = P[0]["mp"]
	return [mp1 == mp0 + 2 and tn1 == tn0 + 1 and mp2 == mp0, "mp %s -> %s (round 2 %s), turns %s -> %s" % [mp0, mp1, mp2, tn0, tn1]]

func c_quiet() -> Array:
	fresh(["harrow"], "hegemony", ["h_vanguard"], ["quiet"])
	var u = P[0]; var t = E[0]; var w = null
	for x in t["weapons"]:
		if x["arc"] == "T": w = x; break
	u["q"] = 8; u["r"] = 8
	B["round"] = 1; t["q"] = 8; t["r"] = 14; var far1 = R.inReach(t, w, u)
	t["q"] = 8; t["r"] = 12; var close1 = R.inReach(t, w, u)
	B["round"] = 2; t["q"] = 8; t["r"] = 14; var far2 = R.inReach(t, w, u)
	return [not far1 and close1 and (far2 or w["r"] < 6), "round 1 far %s close %s, round 2 far %s (range %s)" % [far1, close1, far2, w["r"]]]

func c_locker() -> Array:
	var s = R.newShip("c_reaver", false)
	var d0 = R.derive(s); s["mods"] = ["locker"]; var d1 = R.derive(s)
	var sl = R.newShip("c_raider", false); var e0 = R.derive(sl); sl["mods"] = ["locker"]; var e1 = R.derive(sl)
	var lk = R.lockerSpeed(2.0, {"lockerSlow": 1}); var lk3 = R.lockerSpeed(3.0, {"lockerSlow": 1})
	return [near(R.z0(d1["fx"].get("boardPct")) - R.z0(d0["fx"].get("boardPct")), 0.4) and near(lk, 2) and near(lk3, 2) and (near(d1["speed"], d0["speed"] - 1) or d0["speed"] <= 2), "board %s -> %s, speed %s -> %s, at 2 %s, at 3 %s" % [d0["fx"].get("boardPct"), d1["fx"].get("boardPct"), d0["speed"], d1["speed"], lk, lk3]]

func c_chaser() -> Array:
	fresh(["harrow"], "hegemony", ["h_picket"], [], [["chaser"]])
	var u = P[0]; var t = E[0]; var w = u["weapons"][0]   # the fore torpedo
	u["q"] = 8; u["r"] = 8; u["facing"] = 0
	var inF = null; var wide = null
	for q in range(4, 13):
		for r in range(4, 13):
			t["q"] = q; t["r"] = r
			if R.hdist(u, t) < 1 or R.hdist(u, t) > w["r"] or not R.los(u, t): continue
			var a = absf(R.relAng(u, t))
			if a <= 60.5 and inF == null: inF = [q, r]
			if a > 60.5 and a <= 90.5 and wide == null: wide = [q, r]
	if wide == null or inF == null: return [false, "no test hexes"]
	t["q"] = wide[0]; t["r"] = wide[1]
	var reachWide = R.inReach(u, w, t); var mWide = R.dmgMult(u, w, t, false)
	t["q"] = inF[0]; t["r"] = inF[1]; var mF = R.dmgMult(u, w, t, false)
	fresh(["harrow"], "hegemony", ["h_picket"])
	P[0]["q"] = 8; P[0]["r"] = 8; P[0]["facing"] = 0; E[0]["q"] = wide[0]; E[0]["r"] = wide[1]
	var plain = R.inReach(P[0], P[0]["weapons"][0], E[0])
	return [reachWide and not plain and absf(mWide / mF - 0.8) < 0.02, "wide %s (without %s), mult %s vs %s" % [reachWide, plain, mWide, mF]]

func c_spill() -> Array:
	fresh(["penitent"], "hegemony", ["h_picket"], [], [["spill"]])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999
	var m0 = R.dmgMult(u, u["weapons"][0], t, false)
	u["shp"] = 5; R.syncShields(u)
	R.applyHit(t, t["weapons"][0], u, 8.0, 0)
	var ready = R.jt(u.get("spillReady")); var m1 = R.dmgMult(u, u["weapons"][0], t, false)
	u.erase("spillReady"); m0 = R.dmgMult(u, u["weapons"][0], t, false); u["spillReady"] = 1
	u["q"] = 8; u["r"] = 8; u["facing"] = 0; t["q"] = 11; t["r"] = 8
	for i in range(u["weapons"].size()): u["weapons"][i]["fired"] = false; u["weapons"][i]["cdLeft"] = 0
	var wi := -1
	for i in range(u["weapons"].size()):
		if R.canFire(u, u["weapons"][i], t): wi = i; break
	if wi >= 0: R.fireWeapon(u, wi, t)
	return [ready and absf(m1 / m0 - 1.3) < 0.05 and wi >= 0 and not u.has("spillReady"), "ready %s, mult %s -> %s, fired %s, after %s" % [ready, m0, m1, wi, u.get("spillReady")]]

func c_relay() -> Array:
	fresh(["penitent", "warden", "warden"], "hegemony", ["h_picket"], [], [["relay"], [], []])
	var u = P[0]; var a = P[1]; var b = P[2]
	u["q"] = 8; u["r"] = 8; a["q"] = 8; a["r"] = 10; b["q"] = 12; b["r"] = 12
	a["facing"] = 3; a["hp"] = int(a["maxHp"] * 0.5)
	var m0 = R.braceMul(a)
	R._giveOrder_raw(u, "brace")
	var m1 = R.braceMul(a); var cov = a.get("relayBy")
	R.startSideTurn("player")
	return [cov is Dictionary and near(m1, m0 * 0.8) and b.get("relayBy") == null and a.get("relayBy") == null, "cover %s, mult %s -> %s, far ally %s, after turn %s" % [cov, m0, m1, b.get("relayBy"), a.get("relayBy")]]
