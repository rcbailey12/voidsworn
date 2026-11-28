extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Sfx := preload("res://audio/sfx.gd")
const Hud := preload("res://ui/battle/hud.gd")

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
	b.TBL = b._api_tables()
	b.V = api.view()
	b._index_view()
	b.sel = ship["id"]
	b.danger_on = false
	b.hud = Hud.new()
	b.sfx = Sfx.new()
	b.board = TestBoard.new()
	b.cam = Battle.CamRig.new()
	b.arrow = MeshInstance3D.new()
	b.path_line = MeshInstance3D.new()
	b.path_dots = MultiMeshInstance3D.new()
	b.path_dots.multimesh = MultiMesh.new()
	for node in [b.hud, b.board, b.cam, b.arrow, b.path_line, b.path_dots]:
		b.add_child(node)
	var view := Battle.ShipView.new()
	b.views[b.sel] = view
	b.add_child(view)
	root.add_child(b)
	var words_ok := _check_words(b, ship, foe)
	b._target(foe["id"])
	var ok := flak >= 0 and b.atk != null and b.ghost != null and b.ghost.visible and b.path_line.visible and _offers_burn(b)
	if not ok:
		printerr("FAIL: fixture did not make a burn-and-fire preview (flak %d, plan %s)" % [flak, str(b.atk)])
	else:
		var planned: Dictionary = b.atk.duplicate(true)
		var preview: Dictionary = b._target_info()
		var hit := int(api.R.previewVolley(api.R.stateView(ship, planned.st), [0], foe)[0].hit)
		var shelf: Dictionary = b._panel_info()
		var hover_tip := b._attack_tip(foe["id"])
		var odds_match: bool = preview.line.begins_with("In reach after") and preview.bearing == 1 and preview.hit == hit \
			and shelf.weapons[0].hit == hit and hover_tip.contains("%d%%" % hit) and hover_tip.contains("marked hex")
		if not odds_match:
			printerr("FAIL: Council 1 and 7: Burn and fire box, shelf and hover must agree with the stop-hex odds")
		words_ok = words_ok and odds_match
		var armed_before: int = b.armed
		b._on_key(KEY_1 + flak)
		# flak never arms (it cannot fire at a ship), so the key leaves the arm selection as it was (Artoo on PR 1873)
		ok = b.armed == armed_before and b.armed != flak and b.atk == planned and b.ghost.visible and b.path_line.visible and _offers_burn(b)
		if not ok:
			printerr("FAIL: the flak key armed flak or changed the planned Burn and fire or its preview")
		var toast: Label = b.hud.toast_lbl
		var shown := toast.is_visible_in_tree() and toast.modulate.a > 0.0 \
			and toast.text == "Planned shot keeps its guns. Cancel the plan to change weapons."
		if not shown:
			printerr("FAIL: weapon hotkey did not show the planned guns toast")
		b._on_key(KEY_ENTER)
		var shots := api.take_events().filter(func(event): return event.t == "fire" and event.unit == ship["id"])
		var fired: bool = b.commands == 1 and shots.size() == 1 and shots[0].weapon == 0 and shots[0].target == foe["id"]
		if not fired:
			printerr("FAIL: Enter did not commit the planned shot from the main gun")
		ok = ok and shown and fired
	b.sfx.free()
	b.free()
	if ok and words_ok: print("PASS: Burn and fire odds agree, red-ring and blocked-shot text match the board, and the flak key keeps the plan")
	quit(0 if ok and words_ok else 1)


func _offers_burn(b: TestBattle) -> bool:
	return b._card_info().get("buttons", []).any(func(button): return str(button["text"]).begins_with("Burn and fire"))


func _check_words(b: TestBattle, ship: Dictionary, foe: Dictionary) -> bool:
	var u: Dictionary = b.VU[ship.id]
	b.hover = Vector2i(foe.q, foe.r)
	u["moveLeft"] = 0
	b._target(foe.id)
	var no_shot := b._target_info()
	var clear_reason: bool = b.target.is_empty() and b.atk == null and b._red_ring_guns() == 0 \
		and str(no_shot.get("line", "")).contains("No ready gun can reach it") and b.hud.toast_lbl.text.is_empty() \
		and not str(b._card_info().hint).contains("click an enemy with a red ring")
	if not clear_reason: printerr("FAIL: Council 1 and 24: an unreachable target gets one reason and no red-ring click hint")
	var terrain: Dictionary = b.api.R.B["terrain"]
	b.api.R.B["terrain"] = {"3,6": "rock", "4,6": "rock"}
	var blocked: bool = b._blocker_text(b.VU[foe.id]) == "Blocked by 2 marked asteroids." \
		and b.api.entry_reason(ship.id, 3, 6) == "Blocked by the asteroid on this hex."
	b.api.R.B["terrain"] = terrain
	if not blocked: printerr("FAIL: Council 29: blockers are named and counted without hex numbers")
	b.V = b.api.view()
	b._index_view()
	return clear_reason and blocked
