extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestHud extends "res://ui/battle/hud.gd":
	func toast(_text: String) -> void:
		pass

class TestBoard extends "res://render/board.gd":
	func refresh() -> void:
		pass

class TestBattle extends Battle:
	var commands := 0
	func _ready() -> void:
		set_process(false)
	func _refresh_ui() -> void:
		_overlay()
	func _cmd(f: Callable) -> bool:
		commands += 1
		return bool(f.call())


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	api.new_battle_scenario("s1")
	var ship: Dictionary = api.R.alive("player")[1]  # Warden: gun and flak.
	var foe: Dictionary = api.R.alive("enemy")[0]
	ship.merge({"q": 2, "r": 6, "facing": 0}, true)
	foe.merge({"q": 3 + int(ship["weapons"][0]["r"]), "r": 6}, true)
	var flak: int = ship["weapons"].find_custom(func(w): return w["k"] == "flak")
	var b := TestBattle.new()
	b.api = api
	b.V = api.view()
	b._index_view()
	b.sel = ship["id"]
	b.danger_on = false
	b.hud = TestHud.new()
	b.sfx = Sfx.new()
	b.board = TestBoard.new()
	b.cam = Battle.CamRig.new()
	b.arrow = MeshInstance3D.new()
	b.path_line = MeshInstance3D.new()
	b.path_dots = MultiMeshInstance3D.new()
	b.path_dots.multimesh = MultiMesh.new()
	for node in [b.board, b.cam, b.arrow, b.path_line, b.path_dots]:
		b.add_child(node)
	var view := Battle.ShipView.new()
	b.views[b.sel] = view
	b.add_child(view)
	root.add_child(b)
	b._target(foe["id"])
	var ok := flak >= 0 and b.atk != null and b.ghost != null and b.ghost.visible and b.path_line.visible and _offers_burn(b)
	if not ok:
		printerr("FAIL: fixture did not make a burn-and-fire preview (flak %d, plan %s)" % [flak, str(b.atk)])
	else:
		b._on_key(KEY_1 + flak)
		ok = b.atk == null and not b.ghost.visible and not b.path_line.visible and not _offers_burn(b)
		b._confirm()
		ok = ok and b.commands == 0
		if not ok: printerr("FAIL: arming flak left the old burn-and-fire ghost, card or command")
		b._on_action("arm", flak)
		b._target(foe["id"])
		var restored := b.atk != null and b.ghost.visible and b.path_line.visible and _offers_burn(b)
		if not restored: printerr("FAIL: re-targeting with the guns enabled did not restore the preview")
		ok = ok and restored
	b.hud.free()
	b.sfx.free()
	b.free()
	if ok: print("PASS: gun changes clear the stale burn-and-fire ghost, card and confirmation")
	quit(0 if ok else 1)


func _offers_burn(b: TestBattle) -> bool:
	return b._card_info().get("buttons", []).any(func(button): return str(button["text"]).begins_with("Burn and fire"))
