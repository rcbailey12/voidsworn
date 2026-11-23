# Issue 1885: the escort rout must leave the boss fight open until the boss dies.
extends SceneTree

const API = preload("res://rules/battle_api.gd")
const Rules = preload("res://rules/rules.gd")
const JSM = preload("res://rules/jsm.gd")

func _init() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		fail(error)
		return
	api.new_battle_scenario({
		"seed": 7, "sector": 1, "kind": "boss", "fac": "hegemony",
		"admiral": "vex", "fleet": ["penitent"],
		"enemies": ["h_boss", "h_dominion", "h_dominion", "h_dominion", "h_dominion"],
		"obj": "rout", "shape": "open", "map": "station", "dep": "line",
	})
	var rules := api.R as Rules
	var battle := rules.B as Dictionary
	var enemies := rules.caps("enemy")
	var boss: Dictionary = {}
	var escorts: Array[Dictionary] = []
	for ship: Dictionary in enemies:
		if ship["boss"]:
			boss = ship
		else:
			escorts.append(ship)
	if boss.is_empty() or escorts.size() != 4 or rules.jt(battle["over"]):
		fail("expected an active boss fight with four escorts")
		return
	var rout_line := float(battle["cp0"]["enemy"]) * 0.35
	var shields_before := float(boss["shp"])
	boss["hp"] = float(boss["maxHp"]) * 0.5
	rules.escortsBreak()
	for escort in escorts:
		if not escort["dead"] or not escort.get("fled", false):
			fail("all four escorts must flee at half hull")
			return
	if rules.sideCP("enemy") > rout_line or boss["dead"] or float(boss["hp"]) <= 0.0:
		fail("the living boss must be below the old fleet rout threshold")
		return
	if shields_before <= 0.0 or boss["shp"] != JSM.jsround(shields_before * 0.5) or boss["regen"] != 0 or boss["hullRegen"] != 0:
		fail("the boss must still lose shields and repair when the escorts flee")
		return
	rules.checkEnd()
	if rules.jt(battle["over"]):
		fail("battle ended with a living boss after its escorts fled (over=%s)" % str(battle["over"]))
		return
	boss["hp"] = 0
	rules.killUnit(boss, null)
	if not boss["dead"] or str(battle["over"]) != "win":
		fail("the boss's death must win the fight")
		return
	print("Boss victory: PASS (escorts fled at half hull, victory followed the boss's death)")
	quit()

func fail(message: String) -> void:
	printerr("Boss victory: FAIL: ", message)
	quit(1)
