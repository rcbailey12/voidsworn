extends SceneTree
# UI-5 (issue 387): the Godot battle screen's armed wing selection is cleared by every cancel path.
# Headless: godot --headless --path godot --script res://scenes/battle/test/wing_cancel_test.gd
#
# The findings test runs against the frozen browser screen (ui3d.js), which is not the product. This check drives the
# Godot screen's own functions with a wing selected: select() for a ship picked on the board, _on_action("pick", id) for
# the roster, _on_key(KEY_ESCAPE) for Escape, and _on_action("cancel", null) for the action card's Cancel button. It makes
# the fixture units itself, with no rules battle and no saved profile, the same way onboarding_test.gd drives the scene.
# The HUD, sound and camera are stand-ins so the check runs headless; select, _on_action, _on_key and _cancel are the
# screen's own code. The check reads wing_sel after each path and fails on the path that leaves it armed.
# Issue 1803: the same fixture checks Escape and an order key during the victory beat.

var checks := 0
var fails := 0


class FakeHud extends CanvasLayer:
	var menu: Control
	var endcard: Control
	var ask_panel = null   # issue 529: the real HUD has a prompt panel; null means no prompt is open
	var log_open := false
	var legend_open := false

	func toast(_text: String, _opts := {}) -> void:
		pass

	func toggle_log() -> void:
		log_open = not log_open

	func toggle_legend() -> void:
		legend_open = not legend_open

	func show_menu(_title: String, _items: Array, _row: int) -> void:
		menu = Control.new()
		add_child(menu)

	func hide_menu() -> void:
		menu.free()
		menu = null


class FakeSfx extends Node:
	var on := true

	func play(_name: String, _opts := {}) -> void:
		pass


class FakeCam extends Camera3D:
	func glide(_pos: Vector3, _seconds := 0.8) -> void:
		pass


class FakeApi extends RefCounted:
	var phase := "player"

	func battle_result() -> String:
		return "win"


class TestBattle extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		set_process(false)
	func wait(_ms: float) -> void:
		await get_tree().process_frame
	func _refresh_ui() -> void:
		pass
	func _update_reach() -> void:
		pass


func check(ok: bool, what: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + what)
	else:
		fails += 1
		print("FAIL: " + what)


func unit(id: String, name: String, squadron: bool) -> Dictionary:
	return {"id": id, "side": "player", "dead": false, "activated": false, "squadron": squadron, "active": false,
		"name": name, "tpl": "warden", "cls": "Frigate", "weapons": [], "braced": false, "fired": false, "mp": 0,
		"hp": 10, "maxHp": 10, "sh": [0, 0, 0, 0], "shMax": 0, "flagship": false}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var b = TestBattle.new()
	b.hud = FakeHud.new()
	b.sfx = FakeSfx.new()
	b.cam = FakeCam.new()
	b.api = FakeApi.new()
	var p1 := unit("p1", "Warden", false)
	var p2 := unit("p2", "Warden", false)
	var w1 := unit("w1", "Wing", true)
	b.V = {"round": 1, "units": [p1, p2, w1]}
	b.VU = {"p1": p1, "p2": p2, "w1": w1}
	b.sel = "p1"

	# 1. selecting another ship on the board (the hit on a friendly hull calls select)
	b.wing_sel = "w1"
	b.select("p2", "pick")
	check(b.wing_sel == "", "selecting another ship clears the armed wing")
	check(b.sel == "p2", "selecting another ship really selects it")

	# 2. picking a ship from the fleet roster
	b.wing_sel = "w1"
	b._on_action("pick", "p1")
	check(b.wing_sel == "", "picking a ship from the roster clears the armed wing")
	check(b.sel == "p1", "picking from the roster really selects the ship")

	# 3. Escape, the full cancel chain as the screen layers it
	b.wing_sel = "w1"
	b.mode = ""
	b.armed = -1
	b.plan = null
	b.target = ""
	b.inspect = ""
	b._on_key(KEY_ESCAPE)
	check(b.wing_sel == "", "Escape clears the armed wing")

	# 4. the action card's Cancel button, the path _cancel serves
	b.wing_sel = "w1"
	b.plan = {"cost": 1}
	b._on_action("cancel", null)
	check(b.plan == null, "the Cancel button drops the planned move")
	check(b.wing_sel == "", "the Cancel button clears the armed wing")

	# 5. the battle has ended, and _end_flow is waiting before it shows the end card.
	p1["weapons"] = [{}]
	b._on_key(KEY_1)
	check(b.armed == 0, "1 can arm the selected ship's weapon during battle")
	b._on_key(KEY_1)
	root.add_child(b)
	b.api.phase = "over"
	b._end_flow()
	check(b.ended and b.hud.endcard == null, "the battle ended and the end card is still pending")
	b.hud.log_open = true
	b.hud.legend_open = true
	b._on_key(KEY_ESCAPE)
	check(not b.hud.log_open and b.hud.legend_open and b.hud.menu == null, "victory beat: Esc closes the log first")
	b._on_key(KEY_ESCAPE)
	check(not b.hud.legend_open and b.hud.menu == null, "victory beat: Esc closes the legend next")
	b._on_key(KEY_ESCAPE)
	check(b.hud.menu != null, "victory beat: Esc opens the battle menu")
	b._on_key(KEY_ESCAPE)
	check(b.hud.menu == null, "victory beat: Esc closes the battle menu")
	b._on_key(KEY_1)
	check(b.armed == -1, "victory beat: 1 cannot arm a weapon")
	# Retire before the wait ends so the fixture needs no end card or sound sting.
	b._retire()
	await process_frame

	b.hud.free()
	b.sfx.free()
	b.cam.free()
	b.free()
	print("Wing cancel: %s (%d checks)" % ["PASS" if fails == 0 else "FAIL", checks])
	quit(1 if fails > 0 else 0)
