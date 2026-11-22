extends SceneTree
# Issue 1559 items 10, 11, 12, 17, 19, 20 and 21 (menus audit): the battle HUD's parts do not cover each other or let
# clicks through. Test battle s1 in the real battle scene, at the player's turn:
#   10: with a teaching tip card up, the full log's Close button is not under the tip card, and the open log draws over
#       the terrain key;
#   11: a toast fired with the big banner sits below it;
#   12: during a cut-in the faded sheet, log and key take no mouse, so a click reaches the cut-in;
#   17: a long toast wraps inside the clear part at Larger instead of running off the screen;
#   19: the tip card hides under the end card and during a cut-in, and comes back after;
#   20: a click on the corner words ("Round N", the objective) is the HUD's, not the board's: it plans and picks nothing;
#   21: the Controls page names Backspace (take back a move) and Z (the grid).
# Prints PASS or FAIL lines; exit 0 when all pass. Pictures: -- --hud-shots DIR (needs a window: xvfb-run with opengl3 in
# the cloud; the 3D board is covered by a plain sheet, so they show the HUD layout only).
# Run: godot --headless --path godot --script res://scenes/battle/test/hud_overlap_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
const UiScale = preload("res://ui/ui_scale.gd")
var b
var fails := 0
var shots := ""


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


func _shot(name: String) -> void:
	if shots == "":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(shots.path_join("I1559_" + name + ".png"))
	print("shot I1559_" + name)


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
		us.append([u["id"], u["q"], u["r"], u["facing"], u["activated"], u.get("mp", 0)])
	return str([us, b.sel, b.mode, b.plan != null, b.target, b.armed])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--hud-shots":
		shots = args[1]
		DirAccess.make_dir_recursive_absolute(shots)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080)
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
	if shots != "":
		var cover := CanvasLayer.new()
		cover.layer = 9
		var bg := ColorRect.new()
		bg.color = Color(0.05, 0.06, 0.09)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cover.add_child(bg)
		root.add_child(cover)
	var hud = b.hud
	# 21
	var keys: String = hud.keys_text()
	_check(keys.contains("[b]Backspace[/b]") and keys.contains("[b]Z[/b]"), "item 21: the Controls page names Backspace and Z")
	# 20: a point on the corner words that is not a button
	hud.ledger.ensure_layout()
	var corner := Vector2(-1, -1)
	for r in hud.ledger.blockers:
		if r != hud.ledger.sheet_r and r != hud.ledger.log_r and r.size.x > 20 and r.position.x < 960:
			corner = r.position + Vector2(8, r.size.y - 8)
			break
	_check(corner.x >= 0, "item 20: the corner words are laid out")
	if corner.x >= 0:
		_check(hud.over_ui(corner), "item 20: the HUD reports the corner words as its own (%s)" % str(corner))
		var before := _state()
		await _click(corner)
		await _frames(3)
		_check(_state() == before, "item 20: a click on the corner words plans and picks nothing")
	# 10
	hud.show_tipcard("t1559", "A teaching tip", "A few lines of teaching text that sit at the top right of the clear part of the screen.")
	await _frames(3)
	hud.toggle_log()
	await _frames(4)
	var close: Button = null
	for c in hud.log_panel.find_children("*", "Button", true, false):
		if (c as Button).text == "Close":
			close = c
	_check(close != null and hud.tipcard.visible and not close.get_global_rect().intersects(hud.tipcard.get_global_rect()),
		"item 10: the full log's Close is not under the tip card (%s vs %s)" % [str(close.get_global_rect() if close else Rect2()), str(hud.tipcard.get_global_rect())])
	_check(hud.legend == null or hud.log_panel.get_index() > hud.legend.get_index(), "item 10: the open log draws over the terrain key")
	await _shot("log_and_tip")
	hud.toggle_log()
	# 19: end card, then cut-in
	hud.show_end("Victory", "The line holds.", true)
	await _frames(2)
	_check(not hud.tipcard.visible, "item 19: the tip card hides under the end card")
	hud.hide_end()
	await _frames(2)
	_check(hud.tipcard.visible, "item 19: the tip card comes back when the end card goes")
	hud.letterbox(true)
	await _frames(2)
	_check(not hud.tipcard.visible, "item 19: the tip card hides during a cut-in")
	# 12
	var sheet_pt: Vector2 = hud.ledger.sheet_r.get_center()
	_check(hud.ledger.mouse_filter == Control.MOUSE_FILTER_IGNORE and hud.log_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE \
		and (hud.legend == null or hud.legend.mouse_filter == Control.MOUSE_FILTER_IGNORE) and not hud.over_ui(sheet_pt),
		"item 12: during a cut-in the faded sheet, log and key take no mouse")
	hud.letterbox(false)
	await _frames(2)
	_check(hud.tipcard.visible and hud.ledger.mouse_filter == Control.MOUSE_FILTER_STOP and hud.over_ui(sheet_pt), "item 12 and 19: after the cut-in the sheet takes the mouse and the tip card is back")
	hud.hide_tipcard()
	# 11
	hud.banner("Reinforcements", Color.WHITE, 1.6)
	hud.toast("Two Hullbreaker raiders join the enemy line from the north edge.")
	for i in 4:
		await process_frame
	_check(hud.banner_lbl.modulate.a > 0.0 and not hud.toast_lbl.get_global_rect().intersects(hud.banner_lbl.get_global_rect()), "item 11: the toast sits clear of the big banner (%s vs %s)" % [str(hud.toast_lbl.get_global_rect()), str(hud.banner_lbl.get_global_rect())])
	await _shot("banner_and_toast")
	# 17: Larger
	UiScale.set_player(1.3)
	hud._rebuild()
	await _frames(4)
	hud.toast("Reinforcements: Ashfall Breaker, Ashfall Breaker, Ashfall Cutter, Ashfall Cutter, Ashfall Hulk, Ashfall Hulk, Ashfall Tender and two wings of strike craft join the enemy line.")
	for i in 6:
		await process_frame
	var vr := Rect2(Vector2.ZERO, Vector2(root.size))
	var tr: Rect2 = hud.toast_lbl.get_global_rect()
	var clear := vr.encloses(tr)
	hud.ledger.ensure_layout()
	for r in hud.ledger.blockers:
		if r != hud.ledger.sheet_r and r != hud.ledger.log_r and r.intersects(tr):
			clear = false
	_check(clear and tr.size.y > 40, "item 17: a long toast wraps, stays on screen and clear of the corner words at Larger (%s)" % str(tr))
	await _shot("long_toast_larger")
	UiScale.set_player(1.0)
	hud._rebuild()
	await _frames(3)
	print("HUD_OVERLAP fails=%d" % fails)
	quit(1 if fails else 0)
