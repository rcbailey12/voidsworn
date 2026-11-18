extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")

class TestBattle extends Battle:
	func _ready() -> void:
		set_process(false)

	func _refresh_ui() -> void:
		pass

	func _ui(_id: String) -> Dictionary:
		return {"ability": {"hexes": [{"q": 3, "r": 0}]}}

	func _cmd(f: Callable) -> bool:
		return bool(f.call())

class RulesSpy extends RefCounted:
	var phase := "player"
	var received := {}

	func ability(_id: String, opts: Dictionary) -> bool:
		received = opts
		return true


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var failures := 0
	for ability in ["nova", "blink"]:
		var battle := TestBattle.new()
		root.add_child(battle)
		battle.hud = Battle.HUD.new()
		var rules := RulesSpy.new()
		battle.api = rules
		battle.sel = "player"
		battle.mode = ability
		battle.hover = Vector2i(3, 0)
		battle.VU = {"player": {"id": "player"}}
		battle._on_click()
		if rules.received.get("hex") != {"q": 3, "r": 0}:
			failures += 1
			printerr("FAIL: %s click on a highlighted hex sent no ability command" % ability)
		battle.hud.free()
		battle.free()
	quit(1 if failures else 0)
