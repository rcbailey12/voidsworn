extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")

class TestBoard extends "res://render/board.gd":
	func refresh() -> void:
		pass

class TestBattle extends Battle:
	func _ready() -> void:
		set_process(false)
	func _overlay() -> void:
		board.set_danger(_danger_bands())
	func _refresh_ui() -> void:
		pass


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	# Native Glasswright fade leaves movement after firing, so hatching stays visible.
	api.new_battle_scenario({"seed": 1001, "sector": 1, "admiral": "aelith", "fac_player": "ithar",
		"fleet": ["i_blade", "i_wisp", "i_wisp"], "fac": "hegemony", "enemies": ["h_interdictor", "h_picket", "h_picket"],
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle"})
	var shot: Dictionary = api.R.alive("player")[1]
	var foe: Dictionary = api.R.alive("enemy")[0]
	var other: Dictionary = api.R.alive("enemy")[1]
	shot.merge({"q": 2, "r": 6, "facing": 0}, true)
	foe.merge({"q": 4, "r": 6, "facing": 3, "shp": 0}, true)
	other.merge({"q": 3, "r": 7}, true)
	api.R.syncShields(foe)
	foe["sec"]["prow"]["hp"] = 1
	for e in api.R.alive("enemy"):
		for w in e["weapons"]: w["off"] = 99
	var gun: Dictionary = foe["weapons"][0]
	gun.merge({"off": 0, "cdLeft": 0, "arc": "F", "r": 5}, true)
	other["weapons"][0].merge({"off": 0, "cdLeft": 0, "arc": "T", "r": 5}, true)
	shot["weapons"][0]["shots"] = 8
	var b := TestBattle.new()
	b.api = api
	b.V = api.view()
	b._index_view()
	b.sel = shot["id"]
	b.board = TestBoard.new()
	b.add_child(b.board)
	b.hud = Battle.HUD.new()
	b.hud.log_text = RichTextLabel.new()
	b.hud.add_child(b.hud.log_text)
	root.add_child(b)
	b._threat_request()
	b._api_join()
	b._overlay()
	var hex: String = b.board.key(shot["q"], shot["r"])
	var ok: bool = b.board.danger_over.get(hex) == 2 and b._danger_at(shot) == 2
	if not ok: printerr("FAIL: two live enemy guns did not warn on the player's hex")
	var round_before: int = b.V["round"]
	var pose := Vector3i(foe["q"], foe["r"], foe["facing"])
	api.fire(shot["id"], 0, foe["id"], "prow")
	b.V = api.view()
	b._index_view()
	if gun["off"] <= 1 or foe["dead"] or b.V["round"] != round_before or api.phase != "player" or Vector3i(foe["q"], foe["r"], foe["facing"]) != pose:
		printerr("FAIL: fixture did not disable a stationary enemy gun during the same player turn")
		ok = false
	b._threat_request()
	b._api_join()
	b._overlay()
	var fresh := api.threat_both()
	if b.board.danger_over.get(hex) != 1 or b._danger_at(shot) != 1 or b._threat_cache != fresh["dmg"]:
		printerr("FAIL: disabled gun was not removed from hatching, badge or threat map (band %s, count %d, map current %s)" % [str(b.board.danger_over.get(hex)), b._danger_at(shot), str(b._threat_cache == fresh["dmg"])])
		ok = false
	b.hud.free()
	b.free()
	if ok: print("PASS: a gun knocked out mid-turn is removed from hatching, badges and threat fills")
	quit(0 if ok else 1)
