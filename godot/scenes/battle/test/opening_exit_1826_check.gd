extends SceneTree
# Issue 1826: leave a real battle while the opening camera is still holding.

const GUARD := preload("res://tools/ci/check_guard.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")


func _init() -> void:
	GUARD.arm(self, "opening_exit_1826_check", 60.0)
	_run.call_deferred()


func _battle(seed: int) -> Node:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL: ", error)
		return null
	api.new_battle_scenario("s1", seed)
	var battle := BATTLE.instantiate()
	battle.external = true
	battle.args["noworld"] = true
	root.add_child(battle)
	await battle._begin(api)
	return battle


func _run() -> void:
	var battle := await _battle(6)
	if battle == null or not battle.opening:
		printerr("FAIL: the battle did not start its opening")
		quit(1)
		return
	var hold_time: float = battle.OPEN_HOLD
	battle.queue_free()
	await create_timer(hold_time + 0.1).timeout
	if is_instance_valid(battle):
		printerr("FAIL: the battle was not freed during the opening")
		quit(1)
		return
	print("PASS: freed a battle during the opening and waited past the hold")

	battle = await _battle(7)
	if battle == null or not battle.opening or battle.quitting:
		printerr("FAIL: the battle did not reach the opening before removal")
		quit(1)
		return
	root.remove_child(battle)
	await create_timer(hold_time + 0.1).timeout
	var detached: bool = not battle.is_inside_tree() and not battle.quitting
	battle.free()
	if not detached:
		printerr("FAIL: the battle did not stay detached without quitting")
		quit(1)
		return
	print("PASS: detached a battle during the opening without quitting and waited past the hold")

	battle = await _battle(8)
	if battle == null or not battle.opening:
		printerr("FAIL: the battle did not start its opening before quitting")
		quit(1)
		return
	# Start the standalone quit on the timer tick that expires the opening hold.
	await create_timer(hold_time).timeout
	if not battle.opening or battle.sel == "" or not is_instance_valid(battle.views.get(battle.sel)):
		printerr("FAIL: quit did not overlap the opening with a selected ship")
		quit(1)
		return
	print("Checking standalone quit as the opening hold expires")
	battle._quit()
