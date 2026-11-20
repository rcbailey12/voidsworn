extends SceneTree
# Issue 1271: the dawn finale flag is on from the fifth run on, and battle.gd still lights dawn only for the sector 3 boss.

const Main := preload("res://main/main.gd")
const Battle := preload("res://scenes/battle/battle.gd")

class FakeRules:
	var B := {}
	var RUN = null

class FakeApi:
	var R := FakeRules.new()

var failures := 0


func _initialize() -> void:
	for runs in [0, 4]:
		_check(not Main.finale_for_runs(runs), "run %d has no finale" % runs)
	for runs in [5, 6, 9]:
		_check(Main.finale_for_runs(runs), "run %d has the finale" % runs)
	var b = Battle.new()
	b.api = FakeApi.new()
	b.args["finale"] = Main.finale_for_runs(6)
	for sector in [1, 2, 3]:
		b.api.R.RUN = {"sector": sector}
		b.api.R.B = {"cfg": {"kind": "boss"}}
		_check(b._api_battle_finale() == (sector == 3), "run 6, sector %d boss: dawn only in sector 3" % sector)
	b.api.R.RUN = {"sector": 3}
	b.api.R.B = {"cfg": {"kind": "battle"}}
	_check(not b._api_battle_finale(), "run 6, sector 3 ordinary battle: no dawn")
	b.args["finale"] = Main.finale_for_runs(4)
	b.api.R.B = {"cfg": {"kind": "boss"}}
	_check(not b._api_battle_finale(), "run 4, sector 3 boss: no dawn")
	b.free()
	if failures == 0: print("finale runs check: ok")
	quit(1 if failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if ok: print("  ok: ", what)
	else:
		failures += 1
		printerr("FAIL: ", what)
