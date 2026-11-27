extends SceneTree

const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
const Rules = preload("res://rules/rules.gd")
const SimBattle = preload("res://rules/sim/sim_battle.gd")
const GUARD = preload("res://tools/ci/check_guard.gd")

var api := API.new()
var r: Rules
var c := Campaign.new()
var failures := 0


func _init() -> void:
	GUARD.arm(self, "rules_2205_test")
	var error := api.load_rules()
	if error == "":
		error = c.load_tables()
	if error != "":
		printerr(error)
		quit(2)
		return
	r = api.R
	c.persist_on = false
	_offers()
	_warlord()
	_wall()
	_breach()
	_post_fire()
	_orders()
	_ledger()
	_bonus_salvo()
	_bot_defense()
	_symmetry()
	_h5()
	_shields()
	_determinism()
	_kill_and_arc()
	print("rules_2205: ", failures, " failures")
	quit(0 if failures == 0 else 1)


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)


func setup(admiral: String, fac: String, fleet: Array, picks: Array = [], capstone = null,
		enemies: Array = ["h_picket", "h_vanguard"], foe := "hegemony") -> void:
	api.new_battle_scenario({"seed": 7, "fac": foe, "enemies": enemies, "fac_player": fac,
		"fleet": fleet, "admiral": admiral, "lineage": {"id": admiral, "picks": picks, "capstone": capstone},
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1, "undo": true})
	r.B.terrain.clear()


func at(u: Dictionary, q: int, y: int, facing := 0) -> void:
	u.merge({"q": q, "r": y, "facing": facing}, true)


func move_to(u: Dictionary, q: int, y: int) -> bool:
	for state in r.computeReach(u).states:
		if state.q == q and state.r == y and not state.path.is_empty():
			r.moveUnit(u, state)
			return true
	return false


func api_move_to(u: Dictionary, q: int, y: int) -> bool:
	for state in api.reach(u.id):
		if state.q == q and state.r == y and not state.path.is_empty():
			return api.move(u.id, state)
	return false


func _offers() -> void:
	c.newRun("aelith", "ithar", {})
	var good := true
	for seed in range(32):
		c.seed_rng(seed)
		var ship: Dictionary = c.newShip("i_wisp", true)
		c._offer_perks(ship)
		for perk in ship.cap.perks + ship.cap.offer:
			if perk in ["broad", "stubborn", "wing", "lanceadept"]:
				good = false
	check(not c._captain_perk_pool(c.newShip("i_carrier")).has("rapid"), "W1 launch cooldown is already at its floor")
	c.META.mastery["aelith"] = c.masteryThresholds("aelith")[-1]
	for seed in range(16):
		c.seed_rng(seed)
		c.newRun("aelith", "ithar", {})
		var flag: Dictionary = c.flagshipOf()
		for perk in flag.cap.perks:
			if perk == "stubborn" or (perk == "rapid" and c.HULLS[flag.tpl].ab == "launch"): good = false
	check(good and not c._captain_perk_pool(c.newShip("b_drone")).has("deflector"), "W1 veteran and promotion offers exclude dead perks")
	c.RUN.fleet = [c.newShip("i_wisp")]
	c.RUN.patrons = ["iron", "storm"]
	check(not c.boonOfferPool("iron").has("i_brace") and not c.boonOfferPool("iron").has("i_wall"), "W7 a Glasswright fleet cannot use Brace boons")
	c.RUN.fleet.append(c.newShip("warden"))
	check(c.boonOfferPool("iron").has("i_brace"), "W7 a captured ship can make a Brace offer useful")
	c.RUN.fleet = [c.newShip("warden")]
	var fit := true
	for seed in range(24):
		c.seed_rng(seed)
		var nem: Dictionary = c.newNemesis("chorus")
		fit = fit and not nem.weak.has("ion") and not nem.weak.has("torp")
		nem.seen = {"torp": 100, "lance": 100}
		var adapt = c.nemAdapt(true, nem)
		fit = fit and adapt not in ["pd", "shields"]
	check(fit, "W6 the rival does not learn counters for missing weapons or shields")


func _warlord() -> void:
	setup("grax", "corsair", ["c_marauder"], [], 1)
	var p: Dictionary = r.caps("player")[0]
	var e: Array = r.caps("enemy")
	at(p, 8, 8)
	at(e[0], 9, 9)
	at(e[1], 11, 8, 3)
	p.crew = 100; p.crewMax = 100
	e[0].crew = 100; e[1].crew = 100
	var used := api.command()
	var first := api_move_to(p, 9, 8) and api.board(p.id, e[0].id)
	var blocked := r.boardTargets(p).is_empty()
	var second := api_move_to(p, 10, 8) and not r.boardTargets(p).has(e[0]) and api.board(p.id, e[1].id)
	var exhausted := r.boardTargets(p).is_empty()
	r.B.round += 1
	r.startSideTurn("player")
	check(used and first and blocked and second and exhausted and not p.has("treeWarlord") and not p.has("warlordBoard"),
		"W2 two moves, two distinct targets, then a clean next round")


func _wall() -> void:
	setup("maren", "hegemony", ["h_picket"], ["A:1:0"])
	var p: Dictionary = r.caps("player")[0]
	var e: Dictionary = r.caps("enemy")[0]
	r.useCommand("player")
	var w := r.mkWeapon("laser", "F", {})
	r.applyHit(e, w, p, 1.0, 0)
	var intact: bool = not r.jt(r.B.tr.bellUsed)
	p.shp = 0.0; r.syncShields(p)
	var hit := r.applyHit(e, w, p, 50.0, 0)
	check(intact and r.jt(r.B.tr.bellUsed) and hit.hull == 0, "W3 a shield-only hit does not spend the Chime")

	setup("khepra", "deathless", ["d_jackal", "d_jackal"], ["A:0:0"])
	var fleet := r.caps("player")
	r.useCommand("player")
	r.B.treePlate = {"id": fleet[0].id, "r": r.B.round}
	var levels := true
	for tier in range(3):
		r.B.cmd.tier = tier
		levels = levels and is_equal_approx(r.cmdTaken(fleet[0]), 0.35 - 0.1 * tier)
		levels = levels and is_equal_approx(r.cmdTaken(fleet[1]), 0.85 - 0.1 * tier)
	check(levels, "W4 both damage cuts follow the wall tier without a shieldless bonus")


func _breach() -> void:
	setup("vorn", "hegemony", ["h_picket"], ["A:2:1"])
	var p: Dictionary = r.caps("player")[0]
	var e: Dictionary = r.caps("enemy")[0]
	e.sec = null
	e.weapons = [r.mkWeapon("laser", "F", {})]
	e.weapons[0].off = 0
	e.shp = 0.0; r.syncShields(e)
	var w := r.mkWeapon("laser", "F", {})
	p.m3CritNext = 1
	r.applyHit(p, w, e, 20.0, 0)
	var outside := not r.jt(e.weapons[0].get("off"))
	r.useCommand("player")
	p.m3CritNext = 1
	r.applyHit(p, w, e, 20.0, 0)
	check(outside and r.jt(e.weapons[0].get("off")), "W5 a crit silences a section only during the strike round")


func _post_fire() -> void:
	setup("vex", "voidsworn", ["warden"])
	var p: Dictionary = r.caps("player")[0]
	var ok := true
	for ab in ["evasive", "overburn", "phase"]:
		p.merge({"ab": ab, "abCd": 0, "postFire": true, "mp": 10, "postMp": 0}, true)
		ok = ok and not r.canAbility(p)
		p.postMp = 1
		ok = ok and r.useAbility(p) and r.postFireMp(p) > 1
	check(ok, "W8 movement abilities do not spend a cooldown for movement the ship cannot use")


func _orders() -> void:
	setup("vex", "voidsworn", ["warden"])
	var p: Dictionary = r.caps("player")[0]
	at(p, 8, 8)
	var moved := move_to(p, 9, 8)
	var before = r.UNDO
	var info: Dictionary = api.ui_info(p.id).orders
	var ok := not info.has("full") and not info.has("lock") and not info.has("helm")
	for order in ["full", "lock", "helm", "bad"]:
		ok = ok and not r.canOrder(p, order)
		r.giveOrder(p, order)
	p.weapons[0].fired = true
	r.giveOrder(p, "brace")
	check(ok and moved and before != null and is_same(before, r.UNDO) and r.B.usage.ord.is_empty(),
		"B1 refused orders are not advertised, tracked or charged against undo")


func _ledger() -> void:
	setup("vex", "voidsworn", ["penitent", "warden"], ["C:0:0"])
	var p := r.caps("player")
	var e: Array = r.caps("enemy")
	at(p[0], 8, 8); at(p[1], 8, 9)
	at(e[0], 10, 8, 3); at(e[1], 24, 8, 3)
	for ship in p:
		ship.weapons = [r.mkWeapon("autocannon", "T", {})]
		ship.weapons[0].acc = 500
		ship.weapons[0].dmg = 1
		ship.weapons[0].merge({"shots": 1, "fired": false, "off": 0, "cdLeft": 0}, true)
	r.fireWeapon(p[1], 0, e[0])
	r.fireWeapon(p[0], 0, e[0])
	check(r.jt(r.B.tr.ledgerUsed) and r.jt(p[1].weapons[0].fired), "B2 the Ledger repeats a spent gun and keeps it spent")


func _bonus_salvo() -> void:
	for row in [["voice", "chorus", "b_drone", [], 0, "voice:cap:0"],
			["vorn", "hegemony", "h_picket", [], 1, "vorn:cap:1"],
			["vesh", "corsair", "c_hulk", ["A:1:1"], null, "vesh:A:1:1"]]:
		setup(row[0], row[1], [row[2]], row[3], row[4])
		var p: Dictionary = r.caps("player")[0]
		var e: Dictionary = r.caps("enemy")[0]
		at(p, 8, 8); at(e, 10, 8, 3)
		p.hp *= 0.5   # Welded Fight needs a successful repair before its shot.
		p.weapons = [r.mkWeapon("bioplasma", "T", {})]
		p.weapons[0].merge({"fired": true, "cdLeft": 2, "off": 0, "acc": 500, "dmg": 1}, true)
		var used := r.useCommand("player")
		check(used and r.B.get("treeStats", {}).get(row[5], 0) > 0 and p.weapons[0].fired and p.weapons[0].cdLeft == 2,
			"M2 %s's follow-up can fire a spent mount without reloading it" % row[0])


func _bot_defense() -> void:
	setup("vex", "voidsworn", ["warden"])
	var p: Dictionary = r.caps("player")[0]
	var e: Dictionary = r.caps("enemy")[0]
	at(p, 8, 8); at(e, 10, 8, 3)
	e.weapons = [r.mkWeapon("battery", "T", {})]
	e.weapons[0].merge({"dmg": 100, "fired": false, "cdLeft": 0, "off": 0}, true)
	p.merge({"ab": "surge", "abCd": 0, "shp": p.shMax}, true)
	var full := r.botAbility(p, false) == null
	p.shp -= 1.0; r.syncShields(p)
	check(full and r.botAbility(p, false) != null and r.botShouldBrace(p), "W10 bot conserves shield surge and braces against heavy fire")


func _symmetry() -> void:
	setup("ashgrove", "voidsworn", ["reliquary"], [], null, ["reliquary"], "voidsworn")
	var p: Array = r.caps("player")
	var e: Array = r.caps("enemy")
	var pcar: Dictionary = p[0]; var ecar: Dictionary = e[0]
	for u in r.alive():
		if u.isSq: u.dead = true
	ecar.ab = ""; var bomber_p = r.wingKind(pcar)
	ecar.ab = "launch"; pcar.ab = ""; var bomber_e = r.wingKind(ecar)
	pcar.ab = "launch"
	r.startSideTurn("player")
	r.startSideTurn("enemy")
	check(bomber_p == "bomber" and bomber_e == bomber_p, "H1 identical anti-capital wing selection")
	check(r.squadronsOf(pcar).size() == 1 and r.squadronsOf(ecar).size() == 1 and r.B.usage.ab.get("launch") == 1,
		"B3/H5 automatic launch is counted and happens at turn start on both sides")


func _h5() -> void:
	setup("vex", "voidsworn", ["warden"], [], null, ["warden"], "voidsworn")
	var p: Dictionary = r.caps("player")[0]
	var e: Dictionary = r.caps("enemy")[0]
	at(p, 8, 8); at(e, 20, 8, 3)
	var near_p: String = r.hkey(8, 10); var near_e: String = r.hkey(20, 10)
	r.B.terrain = {near_p: "rock", near_e: "rock"}
	r.clearSpawns()
	check(r.B.terrain.is_empty(), "H5 both spawn clearances reach two hexes")
	var chosen := -1
	for seed in range(80):
		r.rng.rnd_seed(seed)
		var roll := r.rnd()
		if roll >= 0.2 and roll < 0.35:
			chosen = seed
			break
	for unit in [p, e]:
		unit.reanimate = true
		unit.hp = 0
		r.rng.rnd_seed(chosen)
		r.killUnit(unit, null)
	check(chosen >= 0 and p.get("reanimated") and e.get("reanimated"), "H5 the same reanimation draw works on both sides")


func _shields() -> void:
	var sim := SimBattle.new()
	check(sim._shield_total({"shp": 12, "sh": [10, 8, 5, 8]}) == 12.0, "H3 sim telemetry reads the shield pool")
	setup("mirelle", "ithar", ["i_carrier", "i_wisp"], ["A:0:0"])
	var p := r.caps("player")
	p[0].shMax = 20.0; p[1].shMax = 20.1
	p[0].shp = p[0].shMax; p[1].shp = p[1].shMax
	for ship in p: r.syncShields(ship)
	var catches := func(ship): return ship.sh.reduce(func(total, v): return total + v, 0)
	check(catches.call(p[0]) > catches.call(p[1]) and r.useCommand("player") and r.B.treeWeakShip.id == p[0].id,
		"H3 the Weak Side chooses by pool even when side catches disagree")


func _determinism() -> void:
	var left := Rules.new(); var right := Rules.new(); var control := Rules.new()
	left.rng.rnd_seed(77); right.rng.rnd_seed(123); control.rng.rnd_seed(77)
	right.rnd()
	right.startBattle({})
	check(left.rnd() == control.rnd() and left.not_ported == "" and right.not_ported != "", "H6 RNG and bad seed cannot cross rules instances")
	var captain := preload("res://rules/captain_data.gd")
	check(captain.identity_hash("abc") == 0x1a47e90b and r._sorted_keys({"z": 1, "a": 2}) == ["a", "z"], "M4 stable identity hash and key order")


func _kill_and_arc() -> void:
	check(r.killCauseOf(r.mkWeapon("bombs", "T", {}), null) == "big", "M1 bomber deaths use a bomb blast")
	var mounts: Array = r.HULLS.c_reaver.w
	check(mounts == [["torp", "F"], ["scatter", "T"]] and c.HULLS.c_reaver.w == mounts
		and not r.inArc({"q": 8, "r": 8, "facing": 0}, {"q": 7, "r": 8}, "R"),
		"M5 the Reaver's spine turrets share one symmetric Scatter mount")
