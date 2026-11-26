extends SceneTree

const API := preload("res://rules/battle_api.gd")
const Battle := preload("res://scenes/battle/battle.gd")
const Guard := preload("res://tools/ci/check_guard.gd")
const SWAP := "t_ecl_iterationswap"

var failures := 0


func _initialize() -> void:
	Guard.arm(self, "skill_target_picker_test", 30.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _api(interactive: bool, scenario: Variant = SWAP):
	var api := API.new()
	_check(api.load_rules() == "", "rules load")
	api.interactive_deployment = interactive
	api.round_saves = true
	api.new_battle_scenario(scenario)
	return api


func _battle(api) -> Battle:
	var b := Battle.new()
	b.external = true
	b.args.merge({"noworld": true, "nofx": true})
	root.add_child(b)
	b.danger_on = false
	b.threat_on = false
	b.begin_with(api)
	return b


func _hex(target: Dictionary) -> Vector2i:
	return Vector2i(int(target["q"]), int(target["r"]))


func _click_at(position: Vector2) -> void:
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = position
		click.pressed = pressed
		root.push_input(click)


func _tap_key(key: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		root.push_input(event)


func _click_hud(b: Battle, action: String, arg: String) -> bool:
	var ledger = b.hud.ledger
	ledger.ensure_layout()
	for hit in ledger.hits:
		if hit["act"] != action or hit["arg"] != arg:
			continue
		_click_at(ledger.get_global_transform_with_canvas() * Rect2(hit["r"]).get_center())
		return true
	return false


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var api = _api(true)
	var b := _battle(api)
	await process_frame
	var initial: Dictionary = api.view()
	var targets: Array = initial["skill_target"].get("targets", [])
	if targets.size() != 4:
		printerr("FAIL: expected four deployment targets, got ", targets)
		quit(1)
		return
	var enemy: Dictionary = initial["units"].back()
	var first: Dictionary = targets[2]
	var second: Dictionary = targets[1]
	var other: Dictionary = targets[0]
	_check(api.phase == "deployment" and b.hud.ask_panel != null and api.take_round_snapshot().is_empty(), "prompt opens before round one is saved")
	_check(b.board.built == 0 and b.views.is_empty(), "the picker opens before battle view creation")
	# The picker replaces the usual sheet. Put a real battle button underneath its empty middle.
	var top_button: Button = b.hud._button("Top-down view", "top", null, false, true)
	b.hud.root.add_child(top_button)
	top_button.position = root.get_visible_rect().get_center() - top_button.size * 0.5
	var presses := [0]
	top_button.pressed.connect(func() -> void: presses[0] += 1)
	top_button.grab_focus()
	_click_at(top_button.get_global_rect().get_center())
	_check(presses[0] == 0, "clicking another battle button does nothing while the picker is open")
	presses[0] = 0
	_tap_key(KEY_ENTER)
	_check(presses[0] == 0, "Enter cannot press a focused battle button while the picker is open")
	presses[0] = 0
	_check(b.hud.ledger.rows.size() == targets.size() and not _click_hud(b, "pick", enemy["id"]), "only eligible allies appear in the picker")
	b._on_action("pick", enemy["id"])
	_check(api.view()["skill_target"]["picked"].is_empty(), "the rules reject an enemy ID")
	_check(_click_hud(b, "pick", first["id"]), "clicking a fleet row picks the first ship")
	_check(not _click_hud(b, "pick", first["id"]), "the first ship is no longer a clickable choice")
	b._on_action("pick", first["id"])
	_check(api.view()["skill_target"]["picked"]["id"] == first["id"] and _hex(api.unit(first["id"])) == _hex(first), "the first click records the ship and a repeated click cannot resolve the swap")
	_check(b.board.built == 0 and b.views.is_empty(), "the first pick does not start building the battle")
	_check(_click_hud(b, "pick", second["id"]), "clicking a second fleet row completes the swap")
	var expected := _hex(api.unit(first["id"])) == _hex(second) and _hex(api.unit(second["id"])) == _hex(first)
	_check(expected and _hex(api.unit(other["id"])) == _hex(other) and _hex(api.unit(enemy["id"])) == _hex(enemy), "only the two chosen ships exchange hexes")
	_check(api.phase == "player" and api.view()["skill_target"].is_empty() and not api.pick_skill_target(other["id"]), "the swap ends deployment and cannot be spent twice")
	var snap: Dictionary = api.take_round_snapshot()
	var resumed := API.new()
	_check(resumed.load_rules() == "", "resume loads the rules")
	_check(not snap.is_empty() and resumed.restore_round(snap["bytes"], snap["size"], snap["fp"]) == "", "round one restores from the real snapshot")
	_check(resumed.phase == "player" and resumed.view() == api.view(), "restored round keeps the swap and has no pending picker")
	while b.warming or b.busy or b._threat_busy:
		await process_frame
	_check(b.hud.ask_panel == null and b._can_act(), "battle accepts normal orders after the swap")
	_check(b.board.built == 1 and b.views.size() == api.view()["units"].size(), "the battle builds once after the swap")
	_click_at(top_button.get_global_rect().get_center())
	_check(presses[0] == 1, "the battle button works after the picker closes")
	b.free()

	for skip in ["button", "Escape", "1", "right-click"]:
		api = _api(true)
		b = _battle(api)
		await process_frame
		_check(_click_hud(b, "pick", first["id"]), "the first pick is ready before %s" % skip)
		if skip == "button":
			_check(_click_hud(b, "ask", "skip_skill_target"), "the prompt offers a Skip button")
		elif skip == "right-click":
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_RIGHT
			click.pressed = true
			root.push_input(click)
		else:
			_tap_key(KEY_ESCAPE if skip == "Escape" else KEY_1)
		_check(api.phase == "player" and _hex(api.unit(first["id"])) == _hex(first) and _hex(api.unit(second["id"])) == _hex(second), "skip with %s keeps the original deployment" % skip)
		while b.warming or b.busy or b._threat_busy:
			await process_frame
		_check(b.board.built == 1, "the battle builds once after skipping")
		b.free()

	var automatic = _api(false)
	_check(automatic.phase == "player" and _hex(automatic.unit(other["id"])) == _hex(second) and _hex(automatic.unit(second["id"])) == _hex(other), "the automatic path still swaps the first two ships")
	var unrelated = _api(true, "t_glasscorrected")
	_check(unrelated.phase == "player" and unrelated.view()["skill_target"].is_empty(), "the unrelated skill does not open a deployment picker")
	await _placement_picker()
	quit(0 if failures == 0 else 1)


func _placement_picker() -> void:
	var api = _api(true, "t_sworndeploy")
	var b := _battle(api)
	await process_frame
	var picker: Dictionary = api.view()["skill_target"]
	var ships: Array = picker.get("targets", [])
	var open: Array = picker.get("hexes", []).filter(func(h): return h.open)
	_check(not ships.is_empty() and not open.is_empty(), "Sworn Deployment shows the initial fleet and legal landing hexes")
	if ships.is_empty() or open.is_empty():
		b.free()
		return
	var chosen: Dictionary = ships.back()
	var destination: Vector2i = _hex(open.back())
	_check(_click_hud(b, "pick", chosen.id) and b._deploy_grid.visible, "fleet click opens the deployment hex preview")
	var grid = b._deploy_grid
	var clicked: Vector2 = grid.get_global_transform_with_canvas() * grid.centre(destination)
	_click_at(clicked)
	_check(api.phase == "player" and _hex(api.unit(chosen.id)) == destination, "clicking a lit hex places the chosen ship and starts the battle")
	_check(b._deploy_grid == null and not api.take_round_snapshot().is_empty(), "placement closes the grid and saves round one")
	while b.warming or b.busy or b._threat_busy:
		await process_frame
	_check(b.board.built == 1, "placement builds the full battle once")
	b.free()
