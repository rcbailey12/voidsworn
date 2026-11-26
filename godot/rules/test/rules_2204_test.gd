# Issue 2204: test the outcomes of the repaired skills, not just whether they log.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "return_value_discarded")

const API = preload("res://rules/battle_api.gd")
const JSM = preload("res://rules/jsm.gd")
const BATTLE := {"seed": 7, "fac": "hegemony", "enemies": ["h_dominion"],
	"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1}

var api := API.new()
var rules
var battle: Dictionary
var failures := 0


func _init() -> void:
	var error := api.load_rules()
	if error != "":
		printerr(error)
		quit(2)
		return
	rules = api.R
	test_teeth()
	test_knives()
	test_many_mouths()
	test_private_wing()
	test_oath()
	test_reserve()
	print("rules_2204: %d of 6 passed" % (6 - failures))
	quit(0 if failures == 0 else 1)


func expect(ok: bool, name: String, detail) -> void:
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + name + ("" if ok else ": " + str(detail)))


func fresh(faction: String, admiral: String, fleet: Array, picks: Array, capstone = null, mastery := 0) -> void:
	var scenario := BATTLE.duplicate(true)
	scenario.merge({"fac_player": faction, "fleet": fleet, "admiral": admiral,
		"lineage": {"id": admiral, "picks": picks, "capstone": capstone, "mastery": mastery}})
	api.new_battle_scenario(scenario)
	battle = rules.B
	battle["terrain"] = {}


func place(unit: Dictionary, q: int, r: int, facing := 0) -> void:
	unit["q"] = q
	unit["r"] = r
	unit["facing"] = facing


func weapon(kind: String, shots: int, damage := 100) -> Dictionary:
	var w: Dictionary = rules.mkWeapon(kind, "T", {})
	w.merge({"fired": false, "cdLeft": 0, "off": 0, "shots": shots, "acc": 999, "dmg": damage}, true)
	return w


func ready_target(target: Dictionary) -> void:
	target.merge({"weapons": [], "hp": 99999, "maxHp": 99999, "shp": 0, "armor": 0, "sec": null}, true)
	rules.syncShields(target)


func damage_shots(ship: Dictionary, target: Dictionary, kind: String, shots: int) -> Array:
	var from: int = battle.get("combat_events", []).size()
	ship["weapons"] = [weapon(kind, shots)]
	JSM.rnd_seed(7)
	rules.fireWeapon(ship, 0, target)
	return battle.get("combat_events", []).slice(from).map(func(e): return e["damage_applied"])


func start_next_round() -> void:
	battle["round"] += 1
	rules.roundStartBoth()


func teeth_damage(kind: String, equipped: bool) -> Array:
	fresh("chorus", "razormaw", ["b_razor"], ["A:0:1"] if equipped else [])
	var ship: Dictionary = rules.caps("player")[0]
	var target: Dictionary = rules.caps("enemy")[0]
	place(ship, 8, 8)
	place(target, 10, 8)
	ready_target(target)
	rules.useCommand("player")
	return damage_shots(ship, target, kind, 2)


func test_teeth() -> void:
	var ok := true
	var detail := []
	for kind in ["autocannon", "torp"]:
		var control := teeth_damage(kind, false)
		var skill := teeth_damage(kind, true)
		detail.append([kind, control, skill])
		ok = ok and control.size() == 2 and skill.size() == 2 and skill[0] > control[0] and skill[1] == control[1]
	expect(ok, "R2 Teeth at the Throat boosts only the first rear hit, gun or torpedo", detail)


func knife_damage(kind: String, equipped: bool) -> Array:
	fresh("corsair", "sable", ["c_reaver"], [], 0 if equipped else null)
	var ship: Dictionary = rules.caps("player")[0]
	var target: Dictionary = rules.caps("enemy")[0]
	place(ship, 8, 8)
	place(target, 10, 8, 3)
	ready_target(target)
	rules.useCommand("player")
	start_next_round()
	var front := damage_shots(ship, target, kind, 1)
	target["facing"] = 0
	return front + damage_shots(ship, target, kind, 2)


func test_knives() -> void:
	var ok := true
	var detail := []
	for kind in ["autocannon", "torp"]:
		var control := knife_damage(kind, false)
		var skill := knife_damage(kind, true)
		detail.append([kind, control, skill])
		ok = ok and control.size() == 3 and skill.size() == 3 and skill[0] == control[0] and skill[1] > control[1] and skill[2] == control[2]
	expect(ok, "R3 Dark Full of Knives leaves front fire alone and boosts one rear hit", detail)


func test_many_mouths() -> void:
	fresh("chorus", "voice", ["b_spitter", "b_spitter", "b_spitter", "b_spitter"], ["A:2:1"])
	var ships: Array = rules.caps("player")
	var target: Dictionary = rules.caps("enemy")[0]
	place(target, 10, 8, 3)
	ready_target(target)
	var hexes := [Vector2i(8, 8), Vector2i(8, 9), Vector2i(9, 7), Vector2i(10, 7)]
	for i in ships.size():
		place(ships[i], hexes[i].x, hexes[i].y)
		ships[i]["weapons"] = [weapon("autocannon", 4, 1)]
	JSM.rnd_seed(7)
	rules.useCommand("player")
	start_next_round()
	var w := weapon("autocannon", 1)
	w["acc"] = 60
	var clear_ship := target.duplicate()
	clear_ship.erase("treeAcidAim")
	var penalty: float = rules.hitChance(clear_ship, w, ships[0]) - rules.hitChance(target, w, ships[0])
	start_next_round()
	expect(is_equal_approx(penalty, 20.0) and not rules.jt(target.get("treeAcidAim")),
		"R4 Many Mouths cuts enemy aim by 20 for exactly the next round", [penalty, target.get("treeAcidAim")])


func mott_extra(capstone) -> Array:
	fresh("corsair", "mott", ["c_hulk", "c_reaver"], ["A:0:0"], capstone)
	var carrier: Dictionary = rules.treeChoice("carrier")
	place(carrier, 8, 8)
	place(rules.caps("enemy")[0], 18, 14)
	rules.useCommand("player")
	return battle["units"].filter(func(u): return u.get("parent") == carrier["id"] and rules.jt(u.get("extra")))


func test_private_wing() -> void:
	var patch := mott_extra(null)
	var private := mott_extra(1)
	var patch_lost := not patch.is_empty() and patch.all(func(u): return rules.jt(u.get("dead")))
	var private_lives := private.any(func(u): return rules.jt(u.get("treePrivate")) and not rules.jt(u.get("dead")) and u["hp"] > 0)
	expect(patch_lost and private_lives, "R5 Patched Wing expires unless it is Mott's private wing", [patch_lost, private_lives])


func torpedo_pd(ship: Dictionary, target: Dictionary, seed: int) -> int:
	ship["weapons"] = [weapon("torp", 1, 1)]
	JSM.rnd_seed(seed)
	var from: int = rules.events.size()
	rules.fireWeapon(ship, 0, target)
	for event in rules.events.slice(from):
		if event["t"] == "fire" and event["unit"] == ship["id"]: return int(event["pd"])
	return -1


func oath_trial(mastery: int) -> Array:
	fresh("voidsworn", "ashgrove", ["reliquary", "penitent", "penitent"], [], 1, mastery)
	var ships: Array = rules.caps("player")
	var enemy: Dictionary = rules.caps("enemy")[0]
	place(ships[0], 8, 8)
	place(ships[1], 10, 8)
	place(ships[2], 11, 8)
	place(enemy, 12, 8, 3)
	# One empty shield, one nearly full, one outside the wall. None has ordinary screening wings.
	ships[0]["shp"] = 0
	ships[1]["shp"] = ships[1]["shMax"] - 1
	ships[2]["shp"] = 0
	for ship in ships: rules.syncShields(ship)
	enemy["hp"] = 99999
	enemy["maxHp"] = 99999
	var command: Dictionary = rules.commandFor("player")
	var used: bool = rules.useCommand("player")
	var refill: bool = used and ships[0]["shp"] == JSM.jsround(ships[0]["shMax"] * 0.25) and ships[1]["shp"] == ships[1]["shMax"] and ships[2]["shp"] == 0
	var count_before: int = battle["treeStats"].get("ashgrove:cap:1", 0)
	var miss := torpedo_pd(enemy, ships[0], 36)
	var quiet: bool = battle["treeStats"].get("ashgrove:cap:1", 0) == count_before
	# Seed 5 hits, then rolls above the ordinary wing interception chance.
	var stops := [torpedo_pd(enemy, ships[0], 5), torpedo_pd(enemy, ships[0], 7), torpedo_pd(enemy, ships[0], 7),
		torpedo_pd(enemy, ships[1], 7), torpedo_pd(enemy, ships[2], 7)]
	start_next_round()
	var expired := torpedo_pd(enemy, ships[0], 7)
	# Reapply the same Command next round and verify the per-ship allowance refreshes.
	battle["cmdUsed"] = false
	rules.useCommand("player")
	var renewed := torpedo_pd(enemy, ships[0], 7)
	return [refill, miss, quiet, stops, expired, renewed, command["id"]]


func test_oath() -> void:
	var basic := oath_trial(0)
	var mastered := oath_trial(3)
	expect(basic == [true, 0, true, [1, 0, 0, 1, 0], 0, 1, "scramble"] and mastered == [true, 0, true, [1, 1, 0, 1, 0], 0, 1, "scramble"],
		"R6 Oath refills shields and stops one torpedo per escorted ship per round, two at Mastery III", [basic, mastered])


func test_reserve() -> void:
	fresh("chorus", "matriarch", ["b_brood", "b_drone"], ["B:0:1"])
	var carrier: Dictionary = battle["units"].filter(func(u): return u["tpl"] == "b_brood")[0]
	var held: bool = rules.jt(carrier.get("treeOff")) and rules.squadronsOf(carrier).is_empty()
	start_next_round()
	var initial: Array = rules.squadronsOf(carrier)
	var launches := initial.size()
	var arrived: bool = not rules.jt(carrier.get("treeOff")) and carrier.get("spare") == carrier["hangar"] - launches
	for wing in initial: wing["dead"] = true
	for i in int(carrier["hangar"]) + 1:
		carrier["abCd"] = 0
		rules.replaceWings("player")
		var wings: Array = rules.squadronsOf(carrier)
		launches += wings.size()
		for wing in wings: wing["dead"] = true
	expect(held and arrived and launches == carrier["hangar"] and carrier.get("spare") == 0,
		"R7 a reserve carrier arrives and exhausts its replacement wings", [held, arrived, launches, carrier.get("spare")])
