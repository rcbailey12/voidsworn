extends SceneTree
# Issue 1559 items 1 and 18 (menus audit): the battle Esc menu is modal and keeps its row. Test battle s1 in the real battle scene, a player ship
# picked, the menu opened. Checks, through the engine's own input path (Viewport.push_input):
#   - the keyboard is inside the menu on open, and a control outside that grabs focus is put back inside;
#   - order keys (B brace, X ram, G board, C command, Q/E turn, 1 weapon, Backspace undo) change nothing in the battle;
#   - a left click on the board outside the menu plans nothing and picks nothing, and the HUD reports the point as UI;
#   - Esc closes the menu, after which B braces again (the keys work once the menu is gone).
# Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://scenes/battle/test/menu_modal_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
var fails := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player" \
		and not b._threat_busy


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 10:
		await process_frame


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)
		await process_frame


func _click(p: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = p
		e.global_position = p
		e.pressed = pressed
		root.push_input(e)
		await process_frame


func _state() -> String:
	var us: Array = []
	for u in b.V["units"]:
		us.append([u["id"], u["q"], u["r"], u["facing"], u.get("braced", false), u["activated"], u.get("mp", 0), u.get("order", "")])
	return str([us, b.sel, b.mode, b.plan != null, b.target, b.armed, b.api.phase])


func _focus_inside() -> bool:
	var fo: Control = root.gui_get_focus_owner()
	return fo != null and b.hud.menu != null and is_instance_valid(b.hud.menu) and b.hud.menu.is_ancestor_of(fo)


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	b.start_default()
	await _wait_idle(120000)
	if not _idle():
		_check(false, "the battle reached the player's turn")
		quit(1)
		return
	var ship := ""
	var foe := ""
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"] and ship == "":
			ship = str(u["id"])
		if u["side"] == "enemy" and not u["dead"] and foe == "":
			foe = str(u["id"])
	b.select(ship, "roster")
	await _wait_idle(5000)
	b._open_menu()
	await _frames(4)
	_check(b.hud.menu != null, "the menu opened")
	_check(_focus_inside(), "the keyboard is inside the menu when it opens")
	# a control behind the menu takes focus for itself: it is put back inside
	var stray := Button.new()
	stray.text = "behind"
	stray.position = Vector2(4, 4)
	root.add_child(stray)
	stray.grab_focus()
	await _frames(3)
	_check(_focus_inside(), "a control behind the menu cannot keep the keyboard")
	stray.queue_free()
	await _frames(2)
	var before := _state()
	for code in [KEY_B, KEY_X, KEY_G, KEY_C, KEY_Q, KEY_E, KEY_1, KEY_BACKSPACE]:
		await _key(code)
	await _frames(3)
	_check(_state() == before, "order keys do nothing while the menu is open")
	_check(b.hud.menu != null and _focus_inside(), "the menu is still open with the keyboard inside it")
	# a click on the enemy ship's spot on the board, outside the menu
	var vs: Vector2 = root.get_visible_rect().size
	var foe_px: Vector2 = b.cam.unproject_position(b._pos(foe))
	if b.hud.menu.get_global_rect().has_point(foe_px):
		foe_px = Vector2(vs.x * 0.06, vs.y * 0.5)
	_check(b.hud.over_ui(foe_px), "the HUD reports the board as covered while the menu is open")
	await _click(foe_px)
	await _frames(3)
	_check(_state() == before, "a click on the board behind the menu plans and picks nothing")
	# item 18: Enter on the UI scale row keeps the keyboard on that row after the HUD rebuilds for the new scale
	var ui_row := -1
	var v: Node = b.hud.menu.get_child(0)
	for i in v.get_child_count():
		var c = v.get_child(i)
		if c is Button and (c as Button).text.begins_with("UI scale"):
			ui_row = i - 1
			(c as Button).grab_focus()
	await _frames(2)
	var rows_ok := ui_row >= 0
	for n in 4:   # four scales: back to where it started
		await _key(KEY_ENTER)
		await _frames(4)
		rows_ok = rows_ok and b.hud.menu != null and b.hud.menu_row() == ui_row
	_check(rows_ok, "item 18: cycling the UI scale keeps the keyboard on its row (row %d)" % ui_row)
	await _key(KEY_ESCAPE)
	await _frames(3)
	_check(b.hud.menu == null, "Esc closes the menu")
	await _wait_idle(20000)   # a UI scale rebuild redraws the threat map first
	await _key(KEY_B)
	await _frames(3)
	_check(_state() != before, "with the menu closed, B acts again")
	print("MENU_MODAL fails=%d" % fails)
	quit(1 if fails else 0)
