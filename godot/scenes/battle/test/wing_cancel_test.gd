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

var fails := 0


class FakeHud extends CanvasLayer:
	var menu = null
	var ask_panel = null   # issue 529: the real HUD has a prompt panel; null means no prompt is open
	func toast(_text: String, _opts := {}) -> void:
		pass


class FakeSfx extends Node:
	func play(_name: String, _opts := {}) -> void:
		pass


class FakeCam extends Camera3D:
	func glide(_pos: Vector3, _seconds := 0.8) -> void:
		pass


class FakeApi extends RefCounted:
	var phase := "player"


class TestBattle extends "res://scenes/battle/battle.gd":
	func _refresh_ui() -> void:
		pass
	func _update_reach() -> void:
		pass


func check(ok: bool, what: String) -> void:
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

	b.hud.free()
	b.sfx.free()
	b.cam.free()
	b.free()
	print("Wing cancel: %s (%d checks)" % ["PASS" if fails == 0 else "FAIL", 6])
	quit(1 if fails > 0 else 0)
