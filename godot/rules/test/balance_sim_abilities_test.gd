extends "res://rules/sim/balance_sim.gd"
## Issue 1705: the campaign cell report counts abilities used by the selected player fleet.

const GUARD = preload("res://tools/ci/check_guard.gd")
const CASES := [
	{"faction": "deathless", "kind": "battle", "ability": "phase", "rewards": false},
	{"faction": "chorus", "kind": "battle", "ability": "frenzy", "rewards": true},
	{"faction": "deathless", "kind": "boss", "ability": "phase", "rewards": false},
]

var expected: Dictionary
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
	OS.set_environment("CSEC", "1")
	OS.unset_environment("ONLY_BOSS")
	for test_case in CASES:
		expected = test_case
		OS.set_environment("PFACTION", expected.faction)
		if expected.kind == "boss":
			OS.set_environment("ONLY_BOSS", "1")
		_campaign(1, expected.rewards)
		if failed:
			return
	if rows_checked != CASES.size():
		_fail("Expected %d campaign report rows, got %d." % [CASES.size(), rows_checked])
		return
	print("PASS: balance sim player abilities in campaign, campaignrewards and boss cells")
	quit()


func _campaign_cells() -> Array:
	# Exercise the actual cell filters while keeping each case to one battle.
	return super._campaign_cells().slice(0, 1)


func _print_campaign(player_faction: String, cell: Array, count: float, totals: Dictionary, carried: Dictionary) -> void:
	if player_faction != expected.faction or cell[1] != expected.kind:
		_fail("Expected a %s %s row, got %s %s." % [expected.faction, expected.kind, player_faction, cell[1]])
		return
	var ships: Array = battle.B.units.filter(func(unit): return unit.side == "player" and not unit.isSq)
	if ships.is_empty() or ships.any(func(unit): return unit.fac != player_faction):
		_fail("The %s cell did not field the %s player fleet." % [cell[1], player_faction])
		return
	var uses: int = totals.fired.get(expected.ability, 0)
	if uses <= 0:
		_fail("The %s player fleet did not fire %s in the %s cell." % [player_faction, expected.ability, cell[1]])
		return
	rows_checked += 1
	super._print_campaign(player_faction, cell, count, totals, carried)
