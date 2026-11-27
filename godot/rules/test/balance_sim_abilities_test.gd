extends "res://rules/sim/balance_sim.gd"
## Issue 1705: each campaign trial reports abilities used by the selected player fleet.

const GUARD = preload("res://tools/ci/check_guard.gd")
const CASES := [
	{"faction": "deathless", "kind": "battle", "ability": "phase", "rewards": false},
	{"faction": "chorus", "kind": "battle", "ability": "frenzy", "rewards": true},
	{"faction": "deathless", "kind": "boss", "ability": "phase", "rewards": false},
]

var expected: Dictionary
var trial_record := {}
var rows_checked := 0


func _initialize() -> void:
	GUARD.arm(self, "balance_sim_abilities_test")
	var error := battle.load_tables("res://rules/data/tables.json")
	if error.is_empty():
		error = campaign.load_tables()
	if not error.is_empty():
		_fail(error)
		return
	pair_seed = "1705"
	OS.set_environment("SIM_ARM", "fixed_seed")
	OS.set_environment("CSEC", "1")
	OS.unset_environment("ONLY_BOSS")
	for test_case in CASES:
		expected = test_case
		trial_record = {}
		OS.set_environment("PFACTION", expected.faction)
		if expected.kind == "boss":
			OS.set_environment("ONLY_BOSS", "1")
		_campaign(1, expected.rewards)
		if failed:
			return
	if rows_checked != CASES.size():
		_fail("Expected %d campaign report rows, got %d." % [CASES.size(), rows_checked])
		return
	if not _ability_fixtures():
		return
	print("PASS: every ship ability on both sides and SIM_BUILD capstone mastery")
	print("PASS: balance sim trial keys and player abilities in campaign, campaignrewards and boss cells")
	quit()


func _campaign_cells() -> Array:
	# Exercise the actual cell filters while keeping each case to one battle.
	return super._campaign_cells().slice(0, 1)


func _print_trial(record: Dictionary) -> void:
	if not trial_record.is_empty():
		_fail("Expected one trial record for %s %s." % [expected.faction, expected.kind])
		return
	trial_record = record
	super._print_trial(record)


func _print_campaign(player_faction: String, cell: Array, count: float, totals: Dictionary, carried: Dictionary) -> void:
	if failed:
		return
	if player_faction != expected.faction or cell[1] != expected.kind:
		_fail("Expected a %s %s row, got %s %s." % [expected.faction, expected.kind, player_faction, cell[1]])
		return
	var ships: Array = battle.B.units.filter(func(unit): return unit.side == "player" and not unit.isSq)
	if ships.is_empty() or ships.any(func(unit): return unit.fac != player_faction):
		_fail("The %s cell did not field the %s player fleet." % [cell[1], player_faction])
		return
	var expected_cell := {"mode": "campaignrewards" if expected.rewards else "campaign", "sector": 1,
		"kind": expected.kind, "column": 6 if expected.kind == "boss" else 1}
	if trial_record.get("faction") != expected.faction or trial_record.get("cell") != expected_cell \
			or trial_record.get("seed") != 1706 or trial_record.get("arm") != "fixed_seed" \
			or trial_record.get("difficulty") != "veteran":
		_fail("Unexpected trial record: " + str(trial_record))
		return
	var reason := "completed_win" if totals.wins == 1 else ("timeout" if totals.timeouts == 1 else "completed_loss")
	if trial_record.get("terminal_reason") != reason or trial_record.get("abilities_fired") != totals.fired:
		_fail("Trial outcome and fired counts do not match the summary: " + str(trial_record))
		return
	var uses: int = trial_record.abilities_fired.get(expected.ability, 0)
	if uses <= 0:
		_fail("The %s player fleet did not fire %s in the %s cell." % [player_faction, expected.ability, cell[1]])
		return
	rows_checked += 1
	super._print_campaign(player_faction, cell, count, totals, carried)

# Use real hull kits and the same policy that drives the sim, with the minimum legal
# prerequisites staged for abilities that a short seeded campaign may never need.
func _ability_fixtures() -> bool:
	var ship_for := {}
	for tpl in battle.HULLS:
		var ab: Variant = battle.HULLS[tpl].get("ab")
		if ab != null and not ship_for.has(ab):
			ship_for[ab] = tpl
	for ab in battle.ABILITIES:
		if not ship_for.has(ab):
			_fail("No hull fixture for " + ab)
			return false
		var tpl: String = ship_for[ab]
		for side in ["player", "enemy"]:
			var mine: String = tpl if side == "player" else "warden"
			var other: String = tpl if side == "enemy" else "warden"
			var fac: String = battle.HULLS[mine].fac
			_new_run("vex", fac, 1, 0, 9)
			campaign.RUN.fleet = [battle.newShip(mine, false)]
			campaign.RUN.flagUid = campaign.RUN.fleet[0].uid
			battle.startBattle({"seed": 7, "kind": "battle", "fac": battle.HULLS[other].fac,
				"col": 1, "obj": "rout", "dep": "line", "shape": "open", "map": "open", "enemies": [{"tpl": other}]})
			battle.matrix = true
			battle.abilities.clear()
			battle.B.terrain.clear()
			var p: Dictionary = battle.caps("player")[0]; var e: Dictionary = battle.caps("enemy")[0]
			p.merge({"q": 8, "r": 8, "facing": 0}, true)
			e.merge({"q": 11, "r": 8, "facing": 3}, true)
			var u := p if side == "player" else e
			u.hp = u.maxHp * 0.5
			u.shp = u.shMax * 0.5; battle.syncShields(u)
			for w in u.weapons:
				if w.k == "torp": w.cdLeft = 2
			if ab == "launch":
				for wing in battle.squadronsOf(u): wing.dead = true
				battle.startSideTurn(side)
			elif ab == "ionpulse" and side == "player":
				e.q = 13
				for w in p.weapons: w.r = mini(w.r, 4)
				if battle.canAbility(p):
					_fail("Ion pulse must begin out of range")
					return false
				bot.bot_unit(p)
			else:
				bot._use_ability(u, false)
				bot._use_ability(u, true)
			if battle.abilities.get(side + ":" + ab, 0) != 1:
				_fail("%s did not use %s on %s" % [tpl, ab, side])
				return false
	battle.matrix = false
	_new_run("vex", "voidsworn", 1, 0, 9)
	build = {"mastery": 3, "lineage": {"id": "vex", "capstone": 0, "picks": []}}
	if not _apply_build() or battle.capMastery() != 3:
		_fail("SIM_BUILD mastery did not reach the battle capstone")
		return false
	return true
