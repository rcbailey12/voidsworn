extends SceneTree
# Issue 1559 items 1, 2, 8, 13 and 18 (menus audit): the battle Esc menu is modal, fits the screen at every UI scale and keeps
# its row. Test battle s1 in the real battle scene, a player ship
# picked, the menu opened. Checks, through the engine's own input path (Viewport.push_input):
#   - the keyboard is inside the menu on open, and a control outside that grabs focus is put back inside;
#   - order keys (B brace, X ram, G board, C command, Q/E turn, 1 weapon, Backspace undo) change nothing in the battle;
#   - a left click on the board outside the menu plans nothing and picks nothing, and the HUD reports the point as UI;
#   - Esc closes the menu, after which B braces again (the keys work once the menu is gone).
# Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://scenes/battle/test/menu_modal_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
const UiScale = preload("res://ui/ui_scale.gd")
const BL := preload("res://world/board_look.gd")
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


var shots := ""   # -- --menu-shots DIR: also saves the menu at each UI scale (needs a window: xvfb-run with opengl3 in the
# cloud). The 3D board is covered by a plain sheet in these pictures: they show the HUD layout only, never ships.


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	# the shared writer refuses a stage it does not know (the "cloud direction check" stage arrives with #1606): say so
	var err: int = preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), shots.path_join("I1559_" + name + ".png"), "cloud direction check")
	_check(err == OK, "shot I1559_" + name + " saved with its stamp (error %d)" % err)


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


func _click(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = button
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
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--menu-shots":
		shots = args[1]
		DirAccess.make_dir_recursive_absolute(shots)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)   # the design screen (headless starts at 64 x 64)
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
	if shots != "":
		var cover := CanvasLayer.new()
		cover.layer = 9   # under the HUD (10), over the board
		var bg := ColorRect.new()
		bg.color = Color(0.05, 0.06, 0.09)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.add_child(bg)
		root.add_child(cover)
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
	# held WASD and arrows move the menu's focus, never the camera behind it (Artoo on PR 1601)
	var cam_t: Vector3 = b.cam.t
	for code in [KEY_D, KEY_RIGHT]:
		var hold := InputEventKey.new()
		hold.keycode = code
		hold.physical_keycode = code
		hold.pressed = true
		Input.parse_input_event(hold)
	await _frames(20)
	for code in [KEY_D, KEY_RIGHT]:
		var up := InputEventKey.new()
		up.keycode = code
		up.physical_keycode = code
		up.pressed = false
		Input.parse_input_event(up)
	await _frames(2)
	_check(b.cam.t.distance_to(cam_t) < 0.001, "held pan keys do not move the camera while the menu is open")
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
	for c in b.hud.menu.find_children("*", "Button", true, false):
		if (c as Button).text.begins_with("UI scale"):
			ui_row = c.get_index() - 1   # row 0 is the title
			(c as Button).grab_focus()
	await _frames(2)
	var rows_ok := ui_row >= 0
	for n in 4:   # four scales: back to where it started
		await _key(KEY_ENTER)
		await _frames(4)
		rows_ok = rows_ok and b.hud.menu != null and b.hud.menu_row() == ui_row
	_check(rows_ok, "item 18: cycling the UI scale keeps the keyboard on its row (row %d)" % ui_row)
	# item 2: at Large and Larger the menu stays on screen, and the keyboard can reach its last row ("Quit the game")
	for sc in [1.0, 1.15, 1.3]:
		UiScale.set_player(sc)
		b.hud._rebuild()
		b._open_menu()
		await _frames(6)
		var vr := Rect2(Vector2.ZERO, root.get_visible_rect().size)
		var mr: Rect2 = b.hud.menu.get_global_rect()
		_check(vr.grow(1).encloses(mr), "item 2: at UI scale %.2f the menu fits the screen (%s in %s)" % [sc, str(mr), str(vr.size)])
		var last: Button = null
		for c in b.hud.menu.find_children("*", "Button", true, false):
			last = c
		if last != null:
			last.grab_focus()
		await _frames(4)
		_check(last != null and last.text == "Quit the game" and vr.grow(1).encloses(last.get_global_rect()), "item 2: at UI scale %.2f the last row is on screen once the keyboard reaches it" % sc)
		await _shot("menu_scale_%d" % int(round(sc * 100)))
	UiScale.set_player(1.0)
	b.hud._rebuild()
	b._open_menu()
	await _frames(4)
	await _key(KEY_ESCAPE)
	await _frames(3)
	_check(b.hud.menu == null, "Esc closes the menu")
	await _wait_idle(20000)   # a UI scale rebuild redraws the threat map first
	await _key(KEY_B)
	await _frames(3)
	_check(_state() != before, "with the menu closed, B acts again")
	await _grid_shortcut()
	await _overlay_escape()
	# item 13: the end card keeps the keyboard after Esc, Esc (a menu over it opens and closes)
	for early in [false, true]:
		b.hud.show_end("Victory", "The line holds.", true)
		var card: Control = b.hud.endcard
		var first: Control = b.hud._end_first
		if not early:
			await create_timer(0.9).timeout
			await _frames(3)
			_check(root.gui_get_focus_owner() == first, "item 13: the end card's first button has the keyboard")
		b._open_menu()
		await _frames(4)
		await _key(KEY_ESCAPE)
		await _frames(4)
		if early:
			await create_timer(0.9).timeout
			await _frames(3)
		var fo := root.gui_get_focus_owner()
		_check(b.hud.menu == null and fo != null and card.is_ancestor_of(fo), "item 13: after a menu over the end card closes%s, the card has the keyboard again" % (" (opened inside the first beat)" if early else ""))
		b.hud.hide_end()
		await _frames(3)
	# issue 2172: Fight again while the enemy turn is still playing (busy true) must start a live battle
	b.busy = true
	b._on_action("restart", null)
	await create_timer(2.5).timeout
	await _wait_idle(20000)
	_check(not b.busy and b.api != null and not b.ended, "issue 2172: Fight again mid-turn leaves no stuck busy flag in the new battle")
	# item 8: Fight again during the victory beat; the old battle's end card must not land in the new fight
	b._end_flow()
	await create_timer(0.3).timeout
	b._on_action("restart", null)
	await create_timer(2.5).timeout
	await _wait_idle(20000)
	_check(b.hud.endcard == null and not b.ended, "item 8: Fight again during the victory beat leaves no old end card in the new fight")
	await _end_modal()
	b.hud.hide_end()
	await _hold_end_cards()
	b.hud.hide_end()
	b.queue_free()
	await _frames(3)
	print("MENU_MODAL fails=%d" % fails)
	quit(1 if fails else 0)


func _grid_row() -> Button:
	for child in b.hud.menu.find_children("*", "Button", true, false):
		if (child as Button).text.begins_with("Tactical grid"):
			return child
	return null


func _grid_shortcut() -> void:
	BL.set_look("cine", false)
	BL.tactical = false
	b.board.apply_look(false)
	b._refresh_ui()
	b._open_menu()
	await _frames(4)
	var row := _grid_row()
	_check(row != null and row.text == "Tactical grid: off (Z)", "D3: the cinematic menu offers the grid before Z is pressed")
	await _key(KEY_Z)
	_check(not BL.tactical, "D3: Z does nothing while the modal menu is open")
	if row != null:
		row.grab_focus()
		await _key(KEY_ENTER)
		row = _grid_row()
		_check(BL.tactical and row != null and row.text == "Tactical grid: on (Z)", "D3: the menu toggles the grid and reflects its state")
	await _key(KEY_ESCAPE)
	var was := BL.tactical
	await _key(KEY_Z)
	var legacy = b.board.get("_look_btn")
	_check(BL.tactical != was and (legacy == null or not legacy.is_visible_in_tree()), "D3: Z toggles the grid without showing a top-right button")
	BL.tactical = false
	b.board.apply_look(false)


func _overlay_escape() -> void:
	b.hud.set_legend("Terrain", "", [["Debris", "#887766", "Cover"]])
	await _frames(3)
	await _click(b.hud.legend.get_global_rect().get_center())
	await _key(KEY_L)
	_check(b.hud.log_open and b.hud.legend_open, "D5: the full log and terrain legend can both be open")
	await _key(KEY_ESCAPE)
	_check(not b.hud.log_open and b.hud.legend_open and b.hud.menu == null, "D5: Esc closes the full log first")
	await _key(KEY_ESCAPE)
	_check(not b.hud.legend_open and b.hud.menu == null, "D5: the next Esc closes the terrain legend")
	if b.hud.menu != null:
		b.hud.hide_menu()
	if b.hud.log_open:
		b.hud.toggle_log()
	if b.hud.legend_open:
		await _click(b.hud.legend.get_global_rect().get_center())
	await _frames(3)


func _end_modal() -> void:
	b._end_flow()
	var deadline := Time.get_ticks_msec() + 5000
	while b.hud.endcard == null and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(b.hud.endcard != null, "D5: the end card appeared")
	if b.hud.endcard == null:
		return
	_check(b.hud._end_first.text == "Continue to title", "C2: a quick battle names the title as its destination")
	var point := Vector2(90, 580)
	var view := [b.cam.topdown, b.cam.r, b.cam.a, b.cam.t, b.threat_on, b.arcs_on, BL.tactical]
	var menu_point := Vector2.ZERO
	b.hud.ledger.ensure_layout()
	for hit in b.hud.ledger.hits:
		if hit.act == "menu":
			menu_point = Rect2(hit.r).get_center()
	_check(b.hud.over_ui(point), "D5: the end card covers the whole board")
	await _click(point, MOUSE_BUTTON_WHEEL_UP)
	for code in [KEY_Z, KEY_T, KEY_R, KEY_V, KEY_HOME, KEY_F, KEY_L, KEY_ESCAPE]:
		await _key(code)
	_check(not b.hud.log_open and b.hud.menu == null, "D5: L and Esc open nothing behind the end card")
	_check(view == [b.cam.topdown, b.cam.r, b.cam.a, b.cam.t, b.threat_on, b.arcs_on, BL.tactical], "D5: wheel zoom and view shortcuts do nothing behind the end card")
	if b.hud.menu != null:
		b.hud.hide_menu()
		await _frames(3)
	await _click(menu_point)
	_check(menu_point != Vector2.ZERO and b.hud.menu == null, "D5: clicks cannot reach Menu behind the end card")


func _hold_end_cards() -> void:
	var rules = b.api.R
	rules.setupObjective("hold")
	var enemy: Dictionary = rules.caps("enemy")[0]
	b.in_campaign = true
	for row in [
		[2, "Their fleet broke and fled.", "Continue to battle rewards"],
		[3, "You held the relay for three rounds.", "Continue to battle rewards"],
		[2, "Your last ship was destroyed with the relay at 2/3.", "Continue to run debrief"],
	]:
		rules.B["over"] = false
		rules.B["obj"]["score"] = row[0]
		b.ended = false
		b.sel = ""
		b.inspect = enemy["id"]
		b.hud.set_panel(b._panel_info())
		_check(not b.hud.ledger.ship.is_empty(), "C2: an enemy was on the shelf before the end")
		# Keep opponents in the fight. The same hold mission can end by rout, relay score or fleet loss.
		rules.B["cp0"] = {"enemy": rules.sideCP("enemy") * 3.0}
		if row[2] == "Continue to run debrief":
			for ship in rules.caps("player"):
				ship["hp"] = 0
				ship["dead"] = true
		rules.checkEnd()
		b.V = b.api.view()
		await b._end_flow()
		var labels: Array[Node] = b.hud.endcard.find_children("*", "Label", true, false)
		_check(labels.any(func(label): return label.text.begins_with(row[1])), "C2: hold card starts with " + row[1])
		_check(b.hud._end_first.text == row[2], "C2: end card offers " + row[2])
		_check(b.inspect == "" and b.hud.ledger.ship.is_empty() and b._panel_info().is_empty(), "C2: the end card clears the inspected enemy from the shelf")
		b.hud.hide_end()
		await _frames(2)
