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
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed: presses += 1
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
	sink.free()
	b.hud.free()
	b.free()
	if ok: print("PASS: battle picks the release ray after camera motion and skips HUD gestures and drags")
	quit(0 if ok else 1)


func _mouse(p: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = p
	e.pressed = pressed
	root.push_input(e, true)
