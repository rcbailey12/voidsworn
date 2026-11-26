extends SceneTree
## R460 battle and campaign rules regressions.
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "return_value_discarded")

const API := preload("res://rules/battle_api.gd")
const Campaign := preload("res://campaign/campaign.gd")
const JSM := preload("res://rules/jsm.gd")
const FIXTURE := {"seed": 2206, "fac": "hegemony", "enemies": ["h_picket"],
	"kind": "battle", "obj": "rout", "shape": "open", "map": "open", "dep": "line", "sector": 1}
var api := API.new()
var rules
var failures := 0


func _init() -> void:
	var error := api.load_rules()
	if error != "":
		printerr(error)
		quit(2)
		return
	rules = api.R
	_shields()
	_fade()
	_enemy_budget()
	_boon()
	_deploy()
	_roster()
	print("rules_2206 failures: ", failures)
	quit(int(failures > 0))


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1


func _start(faction: String, admiral: String, fleet: Array, extra: Dictionary = {}) -> void:
	var sc := FIXTURE.duplicate()
	sc.merge({"fac_player": faction, "admiral": admiral, "fleet": fleet})
	sc.merge(extra, true)
	api.new_battle_scenario(sc)


func _shields() -> void:
	_start("ithar", "vaelen", ["i_song"])
	var ship: Dictionary = rules.caps("player")[0]
	var foe: Dictionary = rules.caps("enemy")[0]
	var weapon: Dictionary = rules.mkWeapon("laser", "F", {})
	ship.shp = 10
	rules.syncShields(ship)
	rules.applyHit(foe, weapon, ship, 4.0, 0)
	var after_strike: float = ship.shp
	rules.startSideTurn("player")
	_check(after_strike < 10.0 and ship.shp == after_strike + ship.regen and ship.shp < ship.shMax,
		"C1 a shield hit allows normal regen only")
	ship.shp = 0
	rules.syncShields(ship)
	rules.applyHit(foe, weapon, ship, 1.0, 0)
	rules.startSideTurn("player")
	_check(ship.shp == ship.regen and ship.shp < ship.shMax, "C1 a hull hit allows normal regen only")
	rules.startSideTurn("player")
	_check(ship.shp == ship.shMax, "C1 an untouched turn refills the pool")
	ship.shp = 0
	rules.syncShields(ship)
	ship.regenLock = 1
	rules.startSideTurn("player")
	_check(ship.shp == 0, "C1 ion lock still stops recharge")
	ship.abCd = 0
	_check(ship.ab == "surge" and rules.useAbility(ship) and ship.shp == ship.shMax, "C1 a Prism's Shield Surge refills its depleted pool")


func _fade() -> void:
	_start("ithar", "vaelen", ["i_wisp"])
	var ship: Dictionary = rules.caps("player")[0]
	var foe: Dictionary = rules.caps("enemy")[0]
	rules.B.terrain = {}
	ship.merge({"q": 9, "r": 9, "facing": 3, "mp": 4, "postFire": true, "postMp": 2}, true)
	foe.merge({"q": 12, "r": 9, "facing": 3}, true)
	var fired := false
	for damage in [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]:
		for gun in foe.weapons:
			gun.dmg = damage
		var before: float = rules.evalThreat(ship, [foe])
		if before < 1.0 or before >= 5.0: continue
		if rules.fadeMove(ship):
			fired = ship.q != 9 and rules.evalThreat(ship, [foe]) < before
			break
	_check(fired, "W9 fades to safety even below the old threat floor")
	_check(not rules.fadeMove(foe), "W9 cannot fade a non-Glasswright hull")
	ship.merge({"q": 9, "r": 9, "facing": 3, "mp": 2, "postFire": true, "postMp": 1, "turnsLeft": 0, "shp": 0}, true)
	rules.syncShields(ship)
	var long_gun: Dictionary = rules.mkWeapon("laser", "T", {})
	var close_gun: Dictionary = rules.mkWeapon("laser", "T", {})
	long_gun.merge({"r": 9, "dmg": 20.0, "acc": 100}, true)
	close_gun.merge({"r": 3, "acc": 100}, true)
	foe.weapons = [long_gun, close_gun]
	var moderate_cut := false
	for damage in range(1, 12):
		close_gun.dmg = damage
		var here: float = rules.evalThreat(ship, [foe])
		var there: float = rules.evalThreat(rules.stateView(ship, {"q": 8, "r": 9, "f": 3}), [foe])
		if here >= 5.0 and there > here * 0.75 and there <= here * 0.95:
			moderate_cut = rules.fadeMove(ship) and ship.q == 8
			break
	_check(moderate_cut, "W9 accepts a useful threat cut smaller than twenty-five percent")


func _enemy_budget() -> void:
	_start("voidsworn", "vex", ["warden"], {"enemies": null, "col": 6, "sector": 3, "arch": "swarm", "encounterCurve": 1})
	var unblocked: float = rules.enemy_budget(3, 6, "battle", null)
	var small_count: int = rules.caps("enemy").size()
	var large: Array = []
	large.resize(7)
	large.fill("warden")
	_start("voidsworn", "vex", large, {"enemies": null, "col": 6, "sector": 3, "arch": "swarm", "encounterCurve": 1})
	var enemy: Array = rules.caps("enemy")
	_check(unblocked == rules.enemy_budget(3, 6, "battle", null), "C2 V1 budget stays independent of player fleet size")
	_check(enemy.size() == 13 and enemy.size() <= small_count and enemy.any(func(u): return u.elite),
		"C2 generated roster fills the existing cap and spends blocked CP on elites")
	_start("voidsworn", "vex", ["warden"])
	_check(not rules.caps("enemy")[0].elite, "C2 explicit rosters are not upgraded with generated-fleet CP")


func _boon() -> void:
	_start("voidsworn", "vex", ["warden"], {"boons": [{"id": "r_slip", "r": 2}]})
	var ship: Dictionary = rules.caps("player")[0]
	var foe: Dictionary = rules.caps("enemy")[0]
	ship.merge({"q": 9, "r": 9, "facing": 0}, true)
	foe.merge({"q": 11, "r": 9, "facing": 3}, true)
	var fired: bool = rules.fireWeapon(ship, 0, foe)
	_check(fired and ship.postFire and rules.postFireMp(ship) == 0 and not rules.canRotate(ship),
		"C3 an old Slip the Net boon grants no move or pivot after a shot")
	var campaign := Campaign.new()
	var error: String = campaign.load_tables()
	_check(error == "" and not campaign.BOONS.has("r_slip") and not campaign.BOON_FX.has("r_slip") and not campaign.BOON_D.has("r_slip"),
		"C3 the campaign cannot offer the retired boon or show its effect text")
	var existing := {"id": "e_spread", "r": 0}
	var retired := {"id": "r_slip", "r": 0}
	var run: Dictionary = campaign.normalizeRun({"boons": [retired, existing], "giftBoon": "r_slip",
		"reward": {"boonOffer": [retired, existing]}})
	_check(run.boons == [existing] and run.giftBoon == null and run.reward.boonOffer == [existing],
		"C3 continuing an old save drops the retired boon from its inventory, gift and pending offer only")
	_check(error == "" and campaign.effArch("swarm", "ithar") == "heavy", "H4 the campaign previews the real Glasswright formation")


func _deploy() -> void:
	api.interactive_deployment = true
	for scenario in ["t_deployread", "t_sworndeploy"]:
		api.new_battle_scenario(scenario)
		var pick: Dictionary = api.view().skill_target
		if pick.get("targets", []).is_empty():
			_check(false, "C4 %s offers ship options" % scenario)
			continue
		var ship: Dictionary = pick.targets.back()
		var spots: Array = pick.hexes.filter(func(h): return h.open)
		_check(not spots.is_empty() and not api.pick_skill_hex(spots.back().q, spots.back().r), "C4 choose a ship before the hex")
		if spots.is_empty(): continue
		var spot: Dictionary = spots.back()
		var outside: Dictionary = api.view().hexes.filter(func(h):
			return not pick.hexes.any(func(zone): return h.q == zone.q and h.r == zone.r))[0]
		_check(api.pick_skill_target(ship.id) and not api.pick_skill_hex(ship.q, ship.r) and not api.pick_skill_hex(outside.q, outside.r),
			"C4 occupied and on-board but out-of-zone destinations are rejected")
		var key: String = rules.hkey(spot.q, spot.r)
		var terrain = rules.B.terrain.get(key)
		rules.B.terrain[key] = "rock"
		_check(not api.pick_skill_hex(spot.q, spot.r), "C4 blocking terrain cannot be picked")
		if terrain == null: rules.B.terrain.erase(key)
		else: rules.B.terrain[key] = terrain
		_check(api.pick_skill_hex(spot.q, spot.r) and api.phase == "player" and api.unit(ship.id).q == spot.q and api.unit(ship.id).r == spot.r,
			"C4 chosen ally starts on the chosen open hex")
		_check(not api.pick_skill_hex(spot.q, spot.r), "C4 placement can only be spent once")
		var initial: Array = pick.targets
		api.interactive_deployment = false
		api.new_battle_scenario(scenario)
		var moved: Array = initial.filter(func(u): return u.q != api.unit(u.id).q or u.r != api.unit(u.id).r)
		_check(api.phase == "player" and moved.size() == 1 and spots.any(func(h):
			return h.q == api.unit(moved[0].id).q and h.r == api.unit(moved[0].id).r),
			"C4 the automatic path moves one ship onto a legal starting hex")
		api.interactive_deployment = true
	api.new_battle_scenario("t_castcorrected")
	var ships: Array = api.view().skill_target.get("targets", [])
	if ships.size() >= 2:
		var a: Dictionary = ships.back()
		var b: Dictionary = ships[0]
		_check(api.pick_skill_target(a.id) and api.pick_skill_target(b.id) and api.unit(a.id).q == b.q and api.unit(a.id).r == b.r
			and api.unit(b.id).q == a.q and api.unit(b.id).r == a.r, "C4 Casting Corrected swaps the two ships the player picks")
	else:
		_check(false, "C4 Casting Corrected offers two picks")
	api.interactive_deployment = false


func _roster() -> void:
	_check(rules.HULLS.i_wisp.cp == 2 and rules.HULLS.i_wisp_l.cp == 2 and rules.HULLS.i_blade.cp == 3,
		"H4 Glasswright light hulls cost elite-tier CP, including the Wisp variant")
	_check(rules.effArch("swarm", "ithar") == "heavy" and rules.effArch("swarm", "chorus") == "swarm",
		"H4 the Glasswrights do not use the swarm roster filter")
	JSM.rnd_seed(2206)
	var fleet: Array = rules.genEnemyFleet("ithar", 2, 4, "battle", "swarm", null)
	JSM.rnd_seed(2206)
	var swarm: Array = rules.genEnemyFleet("chorus", 2, 4, "battle", "swarm", null)
	_check(not fleet.is_empty() and rules.HULLS[fleet[0].tpl].cp >= 4 and fleet.size() < swarm.size(),
		"H4 generated Glasswright line leads with a strong ship and fields fewer ships than a swarm")
