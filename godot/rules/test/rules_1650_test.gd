# Issue 1650 (Part A of build variety 1453): three Mastery III signatures whose moment the bot battles rarely reach, checked
# on rules.gd directly. Every other signature is proven by its own *_m3 battle in scenarios.json (a "Mastery:" log line).
#   godot --headless --path godot --script res://rules/test/rules_1650_test.gd
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
var api
var R
var B: Dictionary
var P: Array
var E: Array

func fresh(fleet: Array, pfac: String, fac: String, enemies: Array, adm: String, cap: int, mastery: int, k: String) -> void:
	api.new_battle_scenario({"seed": 7, "admiral": adm, "fac_player": pfac, "fleet": fleet, "fac": fac, "enemies": enemies,
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1,
		"lineage": {"id": adm, "picks": [], "capstone": cap, "mastery": mastery}})
	B = R.B; B["terrain"] = {}; B["log"] = []
	B["tree"] = [{"k": k, "key": "%s:cap:%d" % [adm, cap]}]
	P = []; E = []
	for u in B["units"]:
		if R.jt(u.get("isSq")): u["dead"] = true; continue
		if u["side"] == "player": P.append(u)
		else: E.append(u)
	for x in E: x["weapons"] = []
	for i in range(P.size()): P[i]["q"] = 8; P[i]["r"] = 6 + 3 * i; P[i]["facing"] = 0
	for i in range(E.size()): E[i]["q"] = 16; E[i]["r"] = 6 + 3 * i; E[i]["facing"] = 3

func wpn(id: String, arc: String) -> Dictionary:
	var w = R.mkWeapon(id, arc, {}); w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0
	return w

func logged(s: String) -> bool:
	for e in B["log"]:
		if str(e.get("m")).contains(s): return true
	return false

func _init() -> void:
	api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	R = api.R
	var cases := [
		["salvoEnd: the second torpedo picks a stern target and hits at full damage", c_salvo.bind(3)],
		["salvoEnd control: below Mastery III no stern callout", c_salvo_ctl],
		["broodNoStop: an extra swarm chains its kill strike twice", c_nostop.bind(3)],
		["broodNoStop control: below Mastery III it chains once", c_nostop_ctl],
		["preyEveryMouth: a ship next to the named prey deals +15% to it", c_prey],
	]
	var fails := 0
	for c in cases:
		var r: Array = c[1].call()
		print(("PASS " if r[0] else "FAIL ") + str(c[0]) + ("" if r[0] else ": " + str(r[1])))
		if not r[0]: fails += 1
	print("rules_1650: %d of %d passed" % [cases.size() - fails, cases.size()])
	quit(0 if fails == 0 else 1)

# Malek capstone 0 at Mastery III: the follow-up torpedo of the salvo round strikes a ship from behind at full damage
func salvo_run(mastery: int) -> Array:
	fresh(["harrow"], "voidsworn", "hegemony", ["h_picket", "h_picket"], "malek", 0, mastery, "salvoEnd")
	var u = P[0]; var t = E[0]; var t2 = E[1]
	u["q"] = 8; u["r"] = 8; u["facing"] = 0
	t["q"] = 11; t["r"] = 8; t["hp"] = 9999; t["maxHp"] = 9999
	t2["q"] = 11; t2["r"] = 7; t2["hp"] = 9999; t2["maxHp"] = 9999
	for f in range(6):
		t2["facing"] = f
		if R.shieldQuad(t2, u) == 2: break
	u["weapons"] = [wpn("torp", "F")]
	B["cmd"] = {"id": "hunt", "round": B["round"], "tier": 2}
	var i := 0
	while i < 30 and not logged("Lineage: Salvo Without End"):
		u.erase("treeSalvoUsed"); u["weapons"][0]["fired"] = false; u["weapons"][0]["cdLeft"] = 0; u["postFire"] = false
		R.fireWeapon(u, 0, t); i += 1
	return [R.shieldQuad(t2, u) == 2, logged("Lineage: Salvo Without End"), logged("Mastery: Through the Stern Plates")]
func c_salvo(m: int) -> Array:
	var r = salvo_run(m)
	return [r[0] and r[1] and r[2], "stern %s, salvo %s, mastery %s" % r]
func c_salvo_ctl() -> Array:
	var r = salvo_run(0)
	return [r[1] and not r[2], "salvo %s, mastery %s" % [r[1], r[2]]]

# Matriarch capstone 1 at Mastery III: the chained strike that kills again chains a second time
func nostop_run(mastery: int) -> Array:
	fresh(["b_brood", "b_brood"], "chorus", "hegemony", ["h_picket", "h_picket", "h_picket", "h_dominion", "h_dominion"], "matriarch", 1, mastery, "broodNoStop")
	P[1]["q"] = 2; P[1]["r"] = 2   # a real ship stays, so the battle is not lost
	var s = P[0]; s["isSq"] = true; s["extra"] = 1; s["q"] = 8; s["r"] = 8; s["facing"] = 0
	s["weapons"] = [wpn("autocannon", "T")]; s["weapons"][0]["dmg"] = 999; s["weapons"][0]["shots"] = 1; s["weapons"][0]["acc"] = 999
	var d = E[0]; d["dead"] = true
	var e1 = E[1]; var e2 = E[2]
	for x in [E[3], E[4]]: x["hp"] = 99999; x["maxHp"] = 99999; x["q"] = 20; x["r"] = 20   # far off, so the fleet never routs
	e1["q"] = 10; e1["r"] = 8; e1["hp"] = 1; e1["maxHp"] = 40
	e2["q"] = 10; e2["r"] = 7; e2["hp"] = 1; e2["maxHp"] = 40
	var i := 0
	while i < 30 and not (R.jt(e1.get("dead")) and R.jt(e2.get("dead"))):
		if R.jt(e1.get("dead")) and mastery < 3: break
		for e in [e1, e2]:
			if not R.jt(e.get("dead")): e["hp"] = 1
		s.erase("treeNoStopR"); s.erase("m3NoStopR"); s["treeNoStopKill"] = {"r": B["round"], "id": d["id"]}
		R.treeNoStop(s); i += 1
		if mastery < 3: break
	return [R.jt(e1.get("dead")) or R.jt(e2.get("dead")), R.jt(e1.get("dead")) and R.jt(e2.get("dead")), logged("Mastery: Endless Feeding")]
func c_nostop(m: int) -> Array:
	var r = nostop_run(m)
	return [r[1] and r[2], "one dead %s, both dead %s, mastery %s" % r]
func c_nostop_ctl() -> Array:
	var r = nostop_run(0)
	return [r[0] and not r[1] and not r[2], "one dead %s, both dead %s, mastery %s" % r]

# Razormaw capstone 1 at Mastery III: +15% damage against the named prey from an adjacent ship, in the frenzy round
func c_prey() -> Array:
	fresh(["b_razor"], "chorus", "hegemony", ["h_dominion"], "razormaw", 1, 3, "preyEveryMouth")
	var u = P[0]; var t = E[0]
	u["q"] = 8; u["r"] = 8; u["facing"] = 0; t["q"] = 9; t["r"] = 8
	var w = u["weapons"][0]
	B["treeRazorPrey"] = {"id": t["id"], "r": B["round"]}
	var m3 = R.dmgMult(u, w, t, false)
	R.RUN["lineage"]["mastery"] = 2; R._evc = false
	var m2 = R.dmgMult(u, w, t, false)
	R.RUN["lineage"]["mastery"] = 3
	for wi in range(u["weapons"].size()):
		u["weapons"][wi]["fired"] = false; u["weapons"][wi]["cdLeft"] = 0
	R.fireWeapon(u, 0, t)
	return [R.hdist(u, t) == 1 and absf(m3 / m2 - 1.15) < 1e-9 and logged("Mastery: Scent of the Pack"), "adjacent %s, m3 %s vs m2 %s, logged %s" % [R.hdist(u, t) == 1, m3, m2, logged("Mastery: Scent of the Pack")]]
