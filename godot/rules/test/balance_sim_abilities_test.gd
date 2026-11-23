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
