# Issue 1651 (Part D of build variety 1453): the 24 Command riders, checked on rules.gd directly, one case each, plus the key
# coverage check (every admiral has exactly one rider row, under the Command it owns, with a handler in the rules) and the
# swapped Command check (a Command swapped in by Mastery III brings its own admiral's rider). The r1651_* battles in
# scenarios.json play each rider inside a whole seeded battle.
#   godot --headless --path godot --script res://rules/test/rules_1651_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(adm: String, pfac: String, fleet: Array, fac: String, enemies: Array) -> void:
	api.new_battle_scenario({"seed": 7, "admiral": adm, "fac_player": pfac, "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	B = R.B; B["terrain"] = {}; B["log"] = []
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 11; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3
	for x in B["units"]: x["evBuff"] = 0

func rider(k: String) -> void: B["rider"] = {"k": k, "r": B["round"]}
func volley(on: bool) -> void: B["volleyMul"] = {"side": "player", "m": 1.0} if on else null
func wpn(id: String, arc: String) -> Dictionary:
	var w = R.mkWeapon(id, arc, {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0
	return w
func floated(txt: String) -> bool:
	for e in R.events:
		if e.get("t") == "float" and str(e.get("text")) == txt: return true
	return false
func near(a: float, b: float) -> bool: return absf(a - b) < 1e-9

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["key coverage: 24 admirals, one rider row each under the Command it owns, a line of 70 or fewer, a handler", c_keys],
		["swapped Command: Mastery III's altCommand brings its own admiral's rider", c_swap],
		["vex: flank guns in the free volley +10% damage, not forward guns, not outside the volley", c_vex],
		["kassar: battery shots in the free volley cannot miss", c_kassar],
		["voice: a volley hit strips 10% armor for the round, once per target", c_voice],
		["vaelen: a volley lance hit lands on the weakest section", c_vaelen],
		["sekhmar: a target hit by the volley loses 10 aim this round and next, not after", c_sekhmar],
		["malek: torpedoes this round pass point defense", c_malek],
		["vorn: each hit cuts the target's evasion by 5 this round, capped at 15", c_vorn],
		["sable: a rear-arc hit gives the shooter +10 evasion, once a round", c_sable],
		["anuket: a rear-arc hit gives the shooter +10 critical chance this round", c_anuket],
		["ashgrove: wings this Command launches start with +1 movement", c_ashgrove],
		["reyes: a bonus wing attack goes to the lowest-hull enemy in reach", c_reyes],
		["mott: the Command's extra wings gain +10 critical chance this round", c_mott],
		["matriarch: a swarm hit heals its parent brood 3% hull", c_matriarch],
		["aelith: wings are not intercepted by flak this round", c_aelith],
		["thale: the wall repairs 5% hull on every ship", c_thale],
		["maren: a ship next to the flagship takes a further 10% less hull damage", c_maren],
		["mirelle: warded ships gain +15% shields over the top", c_mirelle],
		["khepra: ships that held still or braced repair 5% hull at round end; a ship that moved does not", c_khepra],
		["vesh: each ship's worst section is patched in full, a broken one included", c_vesh],
		["mending: the ship that regrows the most hull gains +10% damage this round", c_mending],
		["nekhet: repaired ships gain +5% armor this round", c_nekhet],
		["grax: ram recoil is cut in half", c_grax],
		["razormaw: a ship next to a wounded enemy gains +1 movement", c_razormaw],
		["thorne: turning in place costs no movement or turns this round", c_thorne],
		["thorne: a turn keeps a tree free turn until the rider ends (issue 2172)", c_thorne_keeps_tree],
		["enemy side: a boss Command never carries a rider", c_enemy],
	]
	var fails := 0
	for c in cases:
		var r: Array = c[1].call()
		print(("PASS " if r[0] else "FAIL ") + str(c[0]) + ("" if r[0] else ": " + str(r[1])))
		if not r[0]: fails += 1
	print("rules_1651: %d of %d passed" % [cases.size() - fails, cases.size()])
	quit(0 if fails == 0 else 1)

func c_keys() -> Array:
	var T: Dictionary = R.TB.CMD_RIDERS
	var src := FileAccess.get_file_as_string("res://rules/rules.gd")
	if T.size() != 24 or R.ADMIRALS.size() != 24: return [false, "rows %d, admirals %d" % [T.size(), R.ADMIRALS.size()]]
	for k in R.ADMIRALS.keys():
		if not T.has(k): return [false, "no rider row for " + k]
		if T[k]["cmd"] != R.ADMIRALS[k]["cmd"]["id"]: return [false, k + " row is under " + str(T[k]["cmd"])]
		var line := str(T[k]["line"])
		if line.length() == 0 or line.length() > 70 or line.contains(char(0x2014)): return [false, k + " line: " + line]
		if not (src.contains('riderOn("%s")' % k) or src.contains('riderVolley("%s"' % k) or src.contains('"k") == "%s"' % k)): return [false, "no handler for " + k]
	for k in T.keys():
		if not R.ADMIRALS.has(k): return [false, "extra rider row " + k]
	return [true, ""]

func c_swap() -> Array:
	fresh("vex", "voidsworn", ["penitent"], "hegemony", ["h_picket"])
	if R.riderOf(R.commandFor("player")) != "vex": return [false, "own Command rider is " + R.riderOf(R.commandFor("player"))]
	R.RUN["cmdOverride"] = R.ADMIRALS["thale"]["cmd"].duplicate(true)   # a saved run keeps a copy, not the table entry
	var k = R.riderOf(R.commandFor("player"))
	if k != "thale": return [false, "swapped Command rider is " + k]
	P[0]["hp"] = P[0]["maxHp"] - 20; var hp0 = P[0]["hp"]
	R.useCommand("player")
	if B["rider"]["k"] != "thale" or P[0]["hp"] <= hp0: return [false, "the swapped wall did not repair: %s %s" % [str(B["rider"]), str(P[0]["hp"])]]
	R.RUN.erase("cmdOverride")
	return [true, ""]

func c_vex() -> Array:
	fresh("vex", "voidsworn", ["penitent"], "hegemony", ["h_picket"])
	var u = P[0]; var t = E[0]; var wP = wpn("battery", "P"); var wF = wpn("lance", "F")
	volley(true); B["rider"] = null; var off = R.dmgMult(u, wP, t, false)
	rider("vex"); var on = R.dmgMult(u, wP, t, false); var fOn = R.dmgMult(u, wF, t, false)
	volley(false); var outside = R.dmgMult(u, wP, t, false)
	rider(""); volley(true); var fOff = R.dmgMult(u, wF, t, false)
	var want = wP["dmg"] * 0.1
	if not near(on - off, want): return [false, "flank +%f want %f" % [on - off, want]]
	if not near(fOn, fOff): return [false, "forward gun changed"]
	volley(false); rider("")
	if not near(outside, R.dmgMult(u, wP, t, false)): return [false, "rider outside the volley"]
	return [true, ""]

func c_kassar() -> Array:
	fresh("kassar", "hegemony", ["h_picket"], "voidsworn", ["penitent"])
	var u = P[0]; var t = E[0]; t["ev"] = 200; t["hp"] = 9999; t["maxHp"] = 9999
	var w = wpn("hbattery", "F"); u["weapons"] = [w]
	rider("kassar"); volley(true); R.events.clear()
	R.fireWeapon(u, 0, t)
	var shots = null
	for e in R.events:
		if e.get("t") == "fire": shots = e["shots"]
	volley(false)
	if shots == null: return [false, "no shot fired"]
	for s in shots:
		if not s: return [false, "a battery shot missed: %s" % str(shots)]
	return [true, ""]

func c_voice() -> Array:
	fresh("voice", "chorus", ["b_razor"], "voidsworn", ["penitent"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999; t["armor"] = 0.3
	var w = wpn("bioplasma", "F"); u["weapons"] = [w]; w["acc"] = 500
	var a0 = R.hitArmor(u, w, t)
	rider("voice"); volley(true)
	R.fireWeapon(u, 0, t)
	var a1 = R.hitArmor(u, w, t)
	w["fired"] = false; R.fireWeapon(u, 0, t)
	var a2 = R.hitArmor(u, w, t)
	volley(false); B["round"] = B["round"] + 1; var a3 = R.hitArmor(u, w, t)
	if not near(a0 - a1, 0.1): return [false, "strip %f" % (a0 - a1)]
	if not near(a1, a2): return [false, "stacked on the same target: %f" % a2]
	if not near(a3, a0): return [false, "lasted past the round: %f" % a3]
	return [true, ""]

func c_vaelen() -> Array:
	fresh("vaelen", "ithar", ["i_lancer" if R.HULLS.has("i_lancer") else "penitent"], "voidsworn", ["penitent"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999
	var w = wpn("lance", "F"); u["weapons"] = [w]; w["acc"] = 500
	for k in t["sec"].keys(): t["sec"][k]["hp"] = t["sec"][k]["max"]
	t["sec"]["eng"]["hp"] = int(t["sec"]["eng"]["max"] * 0.6)   # the weakest; the lance from the front would hit the prow
	var before := {}
	for k in t["sec"].keys(): before[k] = t["sec"][k]["hp"]
	rider("vaelen"); volley(true); R.fireWeapon(u, 0, t); volley(false)
	if t["sec"]["eng"]["hp"] >= before["eng"]: return [false, "engine section not hit: %s" % str(t["sec"])]
	for k in ["prow", "mid"]:
		if t["sec"][k]["hp"] != before[k]: return [false, k + " was hit"]
	return [true, ""]

func c_sekhmar() -> Array:
	fresh("sekhmar", "deathless", ["penitent"], "hegemony", ["h_picket"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999
	var w = wpn("lance", "F"); u["weapons"] = [w]; w["acc"] = 500
	var tw = t["weapons"][0]
	var h0 = R._hitChance_raw(t, tw, u)
	rider("sekhmar"); volley(true); R.fireWeapon(u, 0, t); volley(false)
	var h1 = R._hitChance_raw(t, tw, u)
	B["round"] = B["round"] + 1; var h2 = R._hitChance_raw(t, tw, u)
	B["round"] = B["round"] + 1; var h3 = R._hitChance_raw(t, tw, u)
	if not near(h0 - h1, 10) or not near(h0 - h2, 10) or not near(h3, h0): return [false, "%f %f %f %f" % [h0, h1, h2, h3]]
	return [true, ""]

func c_malek() -> Array:
	fresh("malek", "voidsworn", ["harrow"], "hegemony", ["h_picket", "h_picket"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999; var d = E[1]; d["q"] = 11; d["r"] = 7
	t["weapons"] = []; d["intercepts"] = 2
	var w = wpn("htorp", "F"); w["acc"] = 500; u["weapons"] = [w]
	rider("malek"); R.fireWeapon(u, 0, t)
	if d["intercepts"] != 2: return [false, "point defense spent %d" % (2 - d["intercepts"])]
	if not floated("Point defense blind"): return [false, "no callout"]
	return [true, ""]

func c_vorn() -> Array:
	fresh("vorn", "hegemony", ["h_picket"], "voidsworn", ["penitent"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999; t["ev"] = 30
	var w = wpn("hbattery", "F"); u["weapons"] = [w]; var acc = w["acc"]; w["acc"] = acc - 40
	var h0 = R._hitChance_raw(u, w, t)
	w["acc"] = 500; rider("vorn"); R.fireWeapon(u, 0, t)   # five shots, five hits: capped at 15
	w["acc"] = acc - 40; var cut = R.riderEvCut(t); var h1 = R._hitChance_raw(u, w, t)
	B["round"] = B["round"] + 1; var cut2 = R.riderEvCut(t)
	if not near(cut, 15) or cut2 != 0.0: return [false, "cut %f, next round %f" % [cut, cut2]]
	if h1 <= h0: return [false, "hit chance %f -> %f" % [h0, h1]]
	return [true, ""]

func rear_setup(adm: String, pfac: String) -> Array:
	fresh(adm, pfac, ["penitent"], "hegemony", ["h_picket"])
	var u = P[0]; var t = E[0]; t["hp"] = 9999; t["maxHp"] = 9999
	t["facing"] = 0   # facing away from the shooter: a stern hit
	var w = wpn("lance", "F"); u["weapons"] = [w]; w["acc"] = 500
	return [u, t]

func c_sable() -> Array:
	var ut = rear_setup("sable", "corsair"); var u = ut[0]; var t = ut[1]
	if R.shieldQuad(t, u) != 2: return [false, "setup is not a stern hit"]
	rider("sable"); R.fireWeapon(u, 0, t)
	var e1 = u["evBuff"]; u["weapons"][0]["fired"] = false; R.fireWeapon(u, 0, t)
	if not near(e1, 10) or not near(u["evBuff"], 10): return [false, "evBuff %f then %f" % [e1, u["evBuff"]]]
	return [true, ""]

func c_anuket() -> Array:
	var ut = rear_setup("anuket", "deathless"); var u = ut[0]; var t = ut[1]
	rider("anuket")
	if R.riderCrit(u) != 0.0: return [false, "crit before the hit"]
	R.fireWeapon(u, 0, t)
	if not near(R.riderCrit(u), 10): return [false, "crit %f" % R.riderCrit(u)]
	B["round"] = B["round"] + 1
	if R.riderCrit(u) != 0.0: return [false, "crit lasted past the round"]
	return [true, ""]

func carrier_fleet(adm: String, pfac: String, hull: String) -> void:
	fresh(adm, pfac, [hull], "voidsworn", ["penitent"])
	E[0]["q"] = 14; E[0]["hp"] = 9999; E[0]["maxHp"] = 9999

func c_ashgrove() -> Array:
	carrier_fleet("ashgrove", "voidsworn", "reliquary")
	var old = R.makeWing(P[0], R.launchHexes(P[0])[0], R.wingKind(P[0]))
	R.events.clear()
	R.useCommand("player")
	var newWing = false; var oldBump = false
	for e in R.events:
		if e.get("t") == "float" and e.get("text") == "+1 move":
			if e.get("unit") == old["id"]: oldBump = true
			else: newWing = true
	if not newWing or oldBump: return [false, "new wing bumped %s, old wing bumped %s" % [newWing, oldBump]]
	return [true, ""]

func c_reyes() -> Array:
	fresh("reyes", "hegemony", ["h_vanguard"], "voidsworn", ["penitent", "penitent"])
	var c = P[0]; var a = E[0]; var b = E[1]
	a["q"] = 11; a["r"] = 6; b["q"] = 11; b["r"] = 8
	a["hp"] = a["maxHp"]; b["hp"] = b["maxHp"] - 1; b["armor"] = 0.5   # b has less hull left, but is armored and nowhere near a kill
	var sq = R.makeWing(c, R.launchHexes(c)[0], R.wingKind(c)); sq["q"] = 10; sq["r"] = 7; sq["mp"] = sq["speed"]
	B["tr"]["strikeAgain"] = B["round"]; rider("reyes")
	var p = R.sqPlan(sq)
	rider(""); var p0 = R.sqPlan(sq)
	B["tr"]["strikeAgain"] = 0
	if p0 == null or p0.t["id"] != a["id"]: return [false, "control: without the rider the wing should pick the healthier, nearer ship"]
	if p == null or not p.attack: return [false, "no attack planned"]
	if p.t["id"] != b["id"]: return [false, "picked %s (a %s b %s, wing at %d,%d)" % [str(p.t["id"]), a["id"], b["id"], sq["q"], sq["r"]]]
	return [true, ""]

func c_mott() -> Array:
	carrier_fleet("mott", "corsair", "c_hulk")
	var sq = R.makeWing(P[0], R.launchHexes(P[0])[0], R.wingKind(P[0]))
	rider("mott")
	if R.riderCrit(sq) != 0.0: return [false, "a wing from before the Command gained crit"]
	sq["extra"] = 1
	if not near(R.riderCrit(sq), 10): return [false, "extra wing crit %f" % R.riderCrit(sq)]
	return [true, ""]

func c_matriarch() -> Array:
	carrier_fleet("matriarch", "chorus", "b_brood")
	var c = P[0]; c["hp"] = int(c["maxHp"] * 0.5); var hp0 = c["hp"]
	var sq = R.makeWing(c, R.launchHexes(c)[0], R.wingKind(c)); var t = E[0]; sq["q"] = t["q"] - 1; sq["r"] = t["r"]
	for w in sq["weapons"]: w["acc"] = 500
	rider("matriarch"); R.fireWeapon(sq, 0, t)
	var want = R.JSM.jsround(c["maxHp"] * 0.03)
	if c["hp"] - hp0 != want: return [false, "healed %d want %d" % [c["hp"] - hp0, want]]
	return [true, ""]

func c_aelith() -> Array:
	carrier_fleet("aelith", "ithar", "i_carrier")
	var c = P[0]; var t = E[0]; t["weapons"] = [wpn("flak", "T")]; t["intercepts"] = 2
	var sq = R.makeWing(c, R.launchHexes(c)[0], R.wingKind(c)); sq["q"] = t["q"] - 1; sq["r"] = t["r"]; sq["hp"] = 999
	rider("aelith"); R.fireWeapon(sq, 0, t)
	if t["intercepts"] != 2: return [false, "flak fired %d times" % (2 - t["intercepts"])]
	rider(""); sq["weapons"][0]["fired"] = false; R.fireWeapon(sq, 0, t)
	if t["intercepts"] == 2: return [false, "control: flak did not fire without the rider"]
	return [true, ""]

func c_thale() -> Array:
	fresh("thale", "voidsworn", ["penitent", "penitent"], "hegemony", ["h_picket"])
	for u in P: u["hp"] = u["maxHp"] - 40
	R.useCommand("player")
	for u in P:
		if u["hp"] != u["maxHp"] - 40 + R.JSM.jsround(u["maxHp"] * 0.05): return [false, "hp %d of %d" % [u["hp"], u["maxHp"]]]
	return [true, ""]

func c_maren() -> Array:
	fresh("maren", "hegemony", ["h_picket", "h_picket", "h_picket"], "voidsworn", ["penitent"])
	var f = P[0]; var a = P[1]; var far = P[2]
	f["pflag"] = true; a["pflag"] = false; far["pflag"] = false
	f["q"] = 8; f["r"] = 6; a["q"] = 8; a["r"] = 7; far["q"] = 8; far["r"] = 12
	R.useCommand("player")
	var ca = R.cmdTaken(a); var cf = R.cmdTaken(far)
	if not near(cf - ca, 0.1): return [false, "adjacent %f far %f" % [ca, cf]]
	return [true, ""]

func c_mirelle() -> Array:
	fresh("mirelle", "ithar", ["i_carrier"], "voidsworn", ["penitent"])
	var u = P[0]
	if not (u["shMax"] > 0): return [false, "setup ship has no shields"]
	R.useCommand("player")
	var want = minf(u["shMax"] * 1.25, u["shMax"] + R.JSM.jsround(u["shMax"] * 0.15))
	if not near(float(u["shp"]), want): return [false, "shp %f want %f" % [u["shp"], want]]
	return [true, ""]

func c_khepra() -> Array:
	fresh("khepra", "deathless", ["penitent", "penitent"], "hegemony", ["h_picket"])
	var still = P[0]; var moved = P[1]
	for u in P: u["hp"] = u["maxHp"] - 40
	R.useCommand("player")
	still["hexMoved"] = 0; moved["hexMoved"] = 2
	B["round"] = B["round"] + 1; R.startSideTurn("player")
	if still["hp"] != still["maxHp"] - 40 + R.JSM.jsround(still["maxHp"] * 0.05): return [false, "still ship hp %d" % still["hp"]]
	if moved["hp"] != moved["maxHp"] - 40: return [false, "moved ship repaired"]
	return [true, ""]

func c_vesh() -> Array:
	fresh("vesh", "corsair", ["c_hulk"], "voidsworn", ["penitent"])
	var u = P[0]; u["sec"]["mid"]["hp"] = 0; u["sec"]["mid"]["broken"] = true
	u["sec"]["prow"]["hp"] = int(u["sec"]["prow"]["max"] * 0.5)
	R.useCommand("player")
	if R.jt(u["sec"]["mid"].get("broken")) or u["sec"]["mid"]["hp"] != u["sec"]["mid"]["max"]: return [false, "mid %s" % str(u["sec"]["mid"])]
	return [true, ""]

func c_mending() -> Array:
	fresh("mending", "chorus", ["b_razor", "b_razor"], "voidsworn", ["penitent"])
	var a = P[0]; var b = P[1]; a["hp"] = a["maxHp"] - 2; b["hp"] = int(b["maxHp"] * 0.5)
	var w = wpn("bioplasma", "F")
	var t = E[0]; var m0 = R.dmgMult(b, w, t, false)
	R.useCommand("player")
	if b.get("riderDmgR") != B["round"] or a.get("riderDmgR") != null: return [false, "a %s b %s" % [str(a.get("riderDmgR")), str(b.get("riderDmgR"))]]
	if not near(R.dmgMult(b, w, t, false) - m0, w["dmg"] * 0.1): return [false, "damage did not rise by 10%"]
	return [true, ""]

func c_nekhet() -> Array:
	fresh("nekhet", "deathless", ["penitent", "penitent"], "hegemony", ["h_picket"])
	var hurt = P[0]; var whole = P[1]; hurt["hp"] = hurt["maxHp"] - 40
	var w = E[0]["weapons"][0]
	var a0 = R.hitArmor(E[0], w, hurt); var b0 = R.hitArmor(E[0], w, whole)
	R.useCommand("player")
	if not near(R.hitArmor(E[0], w, hurt) - a0, 0.05): return [false, "hurt ship armor %f -> %f" % [a0, R.hitArmor(E[0], w, hurt)]]
	if not near(R.hitArmor(E[0], w, whole), b0): return [false, "an unrepaired ship gained armor"]
	return [true, ""]

func c_grax() -> Array:
	fresh("grax", "corsair", ["c_hulk"], "voidsworn", ["penitent"])
	var u = P[0]; var t = E[0]
	var r0 = R.ramEstimate(u, t)["recoil"]
	rider("grax"); var r1 = R.ramEstimate(u, t)["recoil"]
	if r0 <= 0 or r1 != R.JSM.jsround(r0 * 0.5) and absf(r1 - r0 * 0.5) > 1.0: return [false, "recoil %s -> %s" % [str(r0), str(r1)]]
	return [true, ""]

func c_razormaw() -> Array:
	fresh("razormaw", "chorus", ["b_razor", "b_razor"], "voidsworn", ["penitent"])
	var a = P[0]; var b = P[1]; var t = E[0]
	a["q"] = 10; a["r"] = 6; t["q"] = 11; t["r"] = 6; b["q"] = 4; b["r"] = 12; t["hp"] = t["maxHp"] - 10
	var ma = a["mp"]; var mb = b["mp"]
	R.useCommand("player")
	var surge = R.cmdPow("surge", B["cmd"]["tier"])
	if a["mp"] != ma + surge + 1 or b["mp"] != mb + surge: return [false, "mp %s %s" % [str(a["mp"] - ma), str(b["mp"] - mb)]]
	return [true, ""]

func c_thorne() -> Array:
	fresh("thorne", "ithar", ["i_carrier"], "voidsworn", ["penitent"])
	var u = P[0]
	R.useCommand("player")
	var mp0 = u["mp"]; var t0 = u["turnsLeft"]
	for i in range(4): R.rotateUnit(u, 1)
	if u["mp"] != mp0 or u["turnsLeft"] != t0: return [false, "mp %s turns %s" % [str(u["mp"] - mp0), str(u["turnsLeft"] - t0)]]
	if int(u["facing"]) != 4: return [false, "facing %s" % str(u["facing"])]
	R.UNDO_ON = true; R.rotateUnit(u, 1)
	var ok = R.canUndo(u)
	if ok: R.undoMove(u)
	R.UNDO_ON = false
	if not ok or int(u["facing"]) != 4: return [false, "a free turn could not be undone (facing %s)" % str(u["facing"])]
	return [true, ""]

func c_thorne_keeps_tree() -> Array:
	fresh("thorne", "ithar", ["i_carrier"], "voidsworn", ["penitent"])
	var u = P[0]
	u["treeFreeTurn"] = 1
	R.useCommand("player")
	var mp0 = u["mp"]; var t0 = u["turnsLeft"]
	R.rotateUnit(u, 1)
	var kept: bool = R.z0(u.get("treeFreeTurn")) == 1 and u["mp"] == mp0 and u["turnsLeft"] == t0
	u.erase("riderFace")
	R.rotateUnit(u, 1)
	var used: bool = R.z0(u.get("treeFreeTurn")) == 0 and u["mp"] == mp0 and u["turnsLeft"] == t0
	R.rotateUnit(u, 1)
	var charged: bool = u["mp"] == mp0 - 1 and u["turnsLeft"] == t0 - 1
	return [kept and used and charged, "kept %s, tree %s after the rider, mp %s turns %s after both" % [str(kept), str(u.get("treeFreeTurn")), str(u["mp"] - mp0), str(u["turnsLeft"] - t0)]]


func c_enemy() -> Array:
	fresh("vex", "voidsworn", ["penitent"], "hegemony", ["h_picket"])
	R.runCommand("enemy", R.ADMIRALS["thale"]["cmd"], 1)
	if B.get("rider") != null: return [false, "an enemy Command set a rider"]
	return [true, ""]
