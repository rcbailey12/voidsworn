extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const Board := preload("res://render/board.gd")
const CameraRig := preload("res://render/camera_rig.gd")

class TestHud extends "res://ui/battle/hud.gd":
	func over_ui(_p: Vector2) -> bool:
		return false

class TestBattle extends Battle:
	var clicked := Vector2i(99999, 99999)
	func _ready() -> void:
		set_process(false)
	func _on_click() -> void:
		clicked = hover


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var b := TestBattle.new()
	root.add_child(b)
	b.api = RefCounted.new()
	b.hud = TestHud.new()
	b.board = Board.new()
	b.add_child(b.board)
	for q in [0, 2]:
		b.board.index[b.board.key(q, 0)] = q
	b.cam = CameraRig.new()
	b.add_child(b.cam)
	b.cam.current = true
	b.cam.set_process(false)
	var p := root.get_visible_rect().size * 0.5
	b.cam.t = b.board.hex_world(0, 0)
	b.cam.snap()
	b.hover = b._ray_hex(p)
	b.cam.t = b.board.hex_world(2, 0)
	b.cam.snap()
	var expected := b._ray_hex(p)
	if b.hover == expected or expected.x == 99999:
		printerr("Fixture error: camera move did not change the on-board hex")
		b.hud.free()
		b.free()
		quit(2)
		return
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = p
	b._unhandled_input(release)
	var ok := b.clicked == expected
	if not ok:
		printerr("FAIL: click after camera moved picked %s, cursor is over %s" % [str(b.clicked), str(expected)])
	b.hud.free()
	b.free()
	quit(0 if ok else 1)
