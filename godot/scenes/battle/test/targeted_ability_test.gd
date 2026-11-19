extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestHud extends "res://ui/battle/hud.gd":
	func toast(_text: String) -> void:
		pass

class TestBattle extends Battle:
	func _refresh_ui() -> void:
		pass
	func _cmd(f: Callable) -> bool:
		return bool(f.call())  # Run the real command without its animation.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	var b := TestBattle.new()
	b.hud = TestHud.new()
	b.sfx = Sfx.new()
	b.api = api
	var ok := true
	for ab in ["nova", "blink"]:
		api.new_battle_scenario("s1")
		var ship: Dictionary = api.R.alive("player")[0]
		ship["ab"] = ab
		b.V = api.view()
		b._index_view()
		b.sel = ship["id"]
		b._on_action("ability", null)
		var marked := b._ability_hexes()
		if marked.is_empty():
			printerr("FAIL: ", ab, " marked no legal hexes")
			ok = false
			continue
		api.take_events()
		b.hover = Vector2i(ship["q"], ship["r"])
		b._on_click()
		if not api.take_events().is_empty() or ship["abCd"] != 0:
			printerr("FAIL: ", ab, " fired on an unmarked hex")
			ok = false
		if b.mode == "": b._on_action("ability", null)
		var h: Dictionary = marked[0]
		b.hover = Vector2i(h["q"], h["r"])
		b._on_click()
		var used := api.take_events().any(func(e): return e["t"] == "ability" and e["ab"] == ab and e["hex"] == h)
		if not used or ship["abCd"] <= 0 or b.mode != "" or (ab == "blink" and Vector2i(ship["q"], ship["r"]) != b.hover):
			printerr("FAIL: ", ab, " did not fire on the marked hex")
			ok = false
	b.hud.free()
	b.sfx.free()
	b.free()
	if ok: print("PASS: Nova and Blink fire on marked hexes and ignore unmarked hexes")
	quit(0 if ok else 1)
