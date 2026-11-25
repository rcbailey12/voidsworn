extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")

class TestApi extends RefCounted:
	var phase := "player"

class TestHud extends "res://ui/battle/hud.gd":
	var blocked := false
	func over_ui(_p: Vector2) -> bool:
		return blocked
	func show_tip(_text: String, _p: Vector2) -> void:
		pass

class TestBoard extends "res://render/board.gd":
	func refresh() -> void:
		pass

class ClickSink extends Control:
	var presses := 0
	var right_releases := 0
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
				presses += 1
			if e.button_index == MOUSE_BUTTON_RIGHT and not e.pressed:
				right_releases += 1
			accept_event()

class TestBattle extends Battle:
	var clicks: Array[Vector2i] = []
	func _ready() -> void:
		set_process(false)
	func _overlay() -> void:
		pass
	func _on_click() -> void:
		clicks.append(hover)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var b := TestBattle.new()
	root.add_child(b)
	b.api = TestApi.new()
	b.V = {"terrain": {}}
	b.hud = TestHud.new()
	b.board = TestBoard.new()
	b.add_child(b.board)
	for q in [0, 2]:
		b.board.index[b.board.key(q, 0)] = q
	b.cam = Battle.CamRig.new()
	b.add_child(b.cam)
	b.cam.current = true
	b.cam.set_process(false)
	var p := root.get_visible_rect().size * 0.5
	b.cam.t = b.board.hex_world(0, 0)
	b.cam.snap()
	b.hover = b._ray_hex(p)
	_mouse(p, true)
	b.cam.t = b.board.hex_world(2, 0)
	b.cam.snap()
	_mouse(p, false)
	var ok := b.clicks == [Vector2i(2, 0)]
	if not ok: printerr("FAIL: release after camera motion picked %s instead of (2, 0)" % str(b.clicks))
	b.clicks.clear()
	b.hud.blocked = true
	_mouse(p, true)
	b.hud.blocked = false
	_mouse(p, false)
	_mouse(p, true)
	b.hud.blocked = true
	_mouse(p, false)
	b.hud.blocked = false
	_mouse(p, true)
	var motion := InputEventMouseMotion.new()
	motion.position = p + Vector2(30, 0)
	motion.relative = Vector2(30, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion, true)
	_mouse(motion.position, false)
	if not b.clicks.is_empty():
		printerr("FAIL: a HUD gesture or camera drag became a board click")
		ok = false
	var sink := ClickSink.new()
	sink.position = p - Vector2(4, 4)
	sink.size = Vector2(8, 8)
	root.add_child(sink)
	_mouse(p, true)
	_mouse(p + Vector2(12, 0), false)
	if sink.presses != 1 or b.cam._drag != 0 or not b.clicks.is_empty():
		printerr("FAIL: a press consumed by GUI became a board gesture")
		ok = false
	var off_hud := p + Vector2(80, 0)
	_mouse(off_hud, true, MOUSE_BUTTON_RIGHT)
	var angle: float = b.cam.a
	_motion(off_hud + Vector2(20, 0), MOUSE_BUTTON_MASK_RIGHT)
	var orbit_started: bool = b.cam.a != angle
	# Headless Viewport input only delivers releases to a Control with mouse capture.
	_mouse(p, true, MOUSE_BUTTON_RIGHT)
	_mouse(p, false, MOUSE_BUTTON_RIGHT)
	angle = b.cam.a
	_motion(off_hud, 0)
	if not orbit_started or sink.right_releases != 1 or b.cam._drag != 0 or b.cam.a != angle:
		printerr("FAIL D2: GUI release must stop orbit (started %s, GUI releases %d, drag %d, moved %s)" % [
			orbit_started, sink.right_releases, b.cam._drag, b.cam.a != angle])
		ok = false
	else:
		print("PASS D2: right release consumed by GUI stops orbit")
	_mouse(off_hud, false, MOUSE_BUTTON_RIGHT)
	sink.free()
	b.hud.free()
	b.hud = Battle.HUD.new()
	b.add_child(b.hud)
	await process_frame
	b.hud.set_playing(true)
	b.hud.ledger.ensure_layout()
	var shelf: Vector2 = b.hud.ledger.sheet_r.get_center()
	var radius: float = b.cam.r
	b.clicks.clear()
	_mouse(shelf, true)
	_mouse(shelf, false)
	var clicked := b.clicks.size() == 1
	_mouse(shelf, true, MOUSE_BUTTON_WHEEL_UP)
	var angle_before: float = b.cam.a
	_mouse(shelf, true, MOUSE_BUTTON_RIGHT)
	_motion(shelf + Vector2(20, 0), MOUSE_BUTTON_MASK_RIGHT)
	_mouse(shelf + Vector2(20, 0), false, MOUSE_BUTTON_RIGHT)
	if b.hud.over_ui(shelf) or not clicked or b.cam.r >= radius or b.cam.a == angle_before:
		printerr("FAIL D1: the hidden shelf must pass clicks, wheel zoom and orbit drags to the board")
		ok = false
	else:
		print("PASS D1: clicks, wheel zoom and orbit drags reach the board over the hidden shelf")
	if not b.hud.over_ui(b.hud.ledger.log_r.get_center()):
		printerr("FAIL D1: the visible log must still catch input during playback")
		ok = false
	b.hud.set_playing(false)
	if not b.hud.over_ui(shelf):
		printerr("FAIL D1: the shelf must catch input when it returns")
		ok = false
	b.free()
	if ok: print("PASS: battle picks the release ray after camera motion and skips HUD gestures and drags")
	quit(0 if ok else 1)


func _mouse(p: Vector2, pressed: bool, button := MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.position = p
	e.pressed = pressed
	root.push_input(e, true)


func _motion(p: Vector2, mask: int) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.relative = Vector2(20, 0)
	e.button_mask = mask
	root.push_input(e, true)
