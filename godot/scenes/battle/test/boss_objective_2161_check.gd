extends SceneTree
# Issue 2161 (R440, issue 1885): a boss fight tells the player to destroy the boss, never "break their fleet" (only the
# boss's death wins a boss fight). Other fights keep their lines.
#   godot --headless --path godot --script res://scenes/battle/test/boss_objective_2161_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "boss_objective_2161_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _run() -> void:
	var b = load("res://scenes/battle/battle.gd").new()
	var units := [
		{"name": "Escort", "side": "enemy", "flagship": false},
		{"name": "Warden", "side": "enemy", "flagship": true},
		{"name": "Mine", "side": "player", "flagship": true}]
	# a boss fight whose objective is the plain rout (what the rules hand a boss fight)
	b.boss_fight = true
	b.V = {"obj": {"type": "rout"}, "units": units, "round": 1}
	var line: String = b._objective()
	_check(line == "Objective: destroy the boss Warden", "a boss fight reads 'destroy the boss <name>' (got '%s')" % line)
	b.V = {"obj": null, "units": units, "round": 1}
	_check(b._objective() == "Objective: destroy the boss Warden", "a boss fight with no objective record reads the same")
	b.V = {"obj": {"type": "rout"}, "units": [{"name": "Mine", "side": "player", "flagship": true}], "round": 1}
	_check(b._objective() == "Objective: destroy the boss", "a boss fight with no flagship in view still names the boss")
	# other fights are unchanged
	b.boss_fight = false
	b.V = {"obj": {"type": "rout"}, "units": units, "round": 1}
	_check(b._objective() == "Objective: break their fleet", "a rout fight still reads 'break their fleet'")
	b.V = {"obj": {"type": "flagship"}, "units": units, "round": 1}
	_check(b._objective() == "Objective: destroy the flagship Warden", "a flagship fight still reads 'destroy the flagship <name>'")
	b.free()
	if failures == 0:
		print("PASS: boss_objective_2161_check (boss fights say destroy the boss)")
	else:
		printerr("FAIL: boss_objective_2161_check: %d failed" % failures)
	quit(0 if failures == 0 else 1)
