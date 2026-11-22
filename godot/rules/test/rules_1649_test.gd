# Issue 1649 follow-up (Artoo, Nov 22; Board rulings in PR 1770): Fold skip and Blood frenzy end when the ship's next turn
# starts, and Blood frenzy's regrowth shares the Chorus feed cap with ordinary feeding (no separate frenzy cap).
#   godot --headless --path godot --script res://rules/test/rules_1649_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(fleet: Array, pfac: String, adm: String, fac: String, enemies: Array) -> void:
	api.new_battle_scenario({"seed": 7, "admiral": adm, "fac_player": pfac, "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	B = R.B; B["terrain"] = {}; B["log"] = []
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["fold: an unspent Fold ends when the ship's next turn starts", c_fold_ends],
		["fold: a spent Fold makes exactly one attack miss", c_fold_once],
		["frenzy: the +20% bonus ends when the ship's next turn starts", c_frenzy_ends],
		["frenzy: regrowth and ordinary feeding share the Chorus feed cap in a round", c_shared_cap],
	]
	var fails := 0
	for c in cases:
		var r: Array = c[1].call()
		print(("PASS " if r[0] else "FAIL ") + str(c[0]) + ("" if r[0] else ": " + str(r[1])))
		if not r[0]: fails += 1
	print("rules_1649: %d of %d passed" % [cases.size() - fails, cases.size()])
	quit(0 if fails == 0 else 1)

func c_fold_ends() -> Array:
	fresh(["d_scythe"], "deathless", "anuket", "hegemony", ["h_picket"])
	var u = P[0]; u["fold"] = true
	R.startSideTurn("enemy")   # the other side's turn keeps it
	var kept = R.jt(u.get("fold"))
	B["round"] = B["round"] + 1; R.startSideTurn("player")
	return [kept and not R.jt(u.get("fold")), "kept through the enemy turn %s, after own next turn %s" % [kept, u.get("fold")]]

func c_fold_once() -> Array:
	fresh(["d_scythe"], "deathless", "anuket", "hegemony", ["h_picket"])
	var u = P[0]; u["fold"] = true
	var s1 = [true, true, true]; var m1 = R.foldMiss(u, s1)
	var s2 = [true, true]; var m2 = R.foldMiss(u, s2)
	return [m1 and s1 == [false, false, false] and not m2 and s2 == [true, true], "first %s %s, second %s %s" % [m1, s1, m2, s2]]

func c_frenzy_ends() -> Array:
	fresh(["b_razor"], "chorus", "razormaw", "hegemony", ["h_picket"])
	var u = P[0]; var t = E[0]; var w = u["weapons"][0]
	var m0 = R.dmgMult(u, w, t, false)
	u["frenzy"] = true
	var m1 = R.dmgMult(u, w, t, false)
	R.startSideTurn("enemy")
	var kept = R.jt(u.get("frenzy"))
	B["round"] = B["round"] + 1; R.startSideTurn("player")
	var m2 = R.dmgMult(u, w, t, false)
	return [m1 > m0 and kept and not R.jt(u.get("frenzy")) and absf(m2 - m0) < 1e-9, "dmg %s -> %s -> %s" % [m0, m1, m2]]

func c_shared_cap() -> Array:
	fresh(["b_razor"], "chorus", "razormaw", "hegemony", ["h_picket"])
	var u = P[0]; u["maxHp"] = 1000; u["hp"] = 100; u["frenzy"] = true
	var cap = R.JSM.jsround(1000 * float(R.TB.FEED_CAP))
	var fed = R.chorusRegrow(u, 80, "Feeds")              # ordinary feeding first
	var fr = R.frenzyRegrow(u, 1000)                      # frenzy wants 30% of 1000 = 300
	var total = u["hp"] - 100
	var fr2 = R.frenzyRegrow(u, 1000)
	return [total == cap and fed == 80 and fr == cap - 80 and fr2 == 0, "cap %s, feed %s, frenzy %s, total %s, again %s" % [cap, fed, fr, total, fr2]]
