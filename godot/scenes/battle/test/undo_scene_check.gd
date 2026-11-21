extends SceneTree
# Issue 1450: Undo in the live battle scene (headless). Test battle s1 in the real battle scene: one player ship moves
# one hex and keeps movement, the card offers "Undo move", Backspace takes it back. Checks: the ship's view and the drawn
# ship stand on the start hex and facing again, the reach overlay is rebuilt from there, the button is gone, Next ship is
# back, a second Backspace does nothing, and no "unknown event kind" warning was raised (the undo event has its playback
# branch). Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://scenes/battle/test/undo_scene_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
const ShipView = preload("res://render/ship_view.gd")
var b
var fails := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player"


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 10:
		await process_frame


func _card_acts() -> Array:
	var out: Array = []
	var u: Dictionary = b._sel_unit()
	if u.is_empty():
		return out
	var c: Dictionary = b._card_info()
	for x in c.get("buttons", []):
		out.append(str(x.get("act", "")))
	return out


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	b.start_default()
	await _wait_idle(120000)
	if not _idle():
		_check(false, "the battle reached the player's turn")
		quit(1)
		return
	var ship := ""
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
			ship = str(u["id"])
			break
	b.select(ship, "roster")
	var u0: Dictionary = b.VU[ship]
	var q0 := int(u0["q"])
	var r0 := int(u0["r"])
	var f0 := int(u0["facing"])
	await _wait_idle(5000)
	var reach0: Array = b.reach_map.keys()
	reach0.sort()
	var st = null
	for s in b.api.reach(ship):
		if s.path.size() == 1 and not bool(s.path[0].get("rot", false)) and int(s.cost) < int(u0["mp"]):
			st = s
			break
	_check(st != null, "a one-hex move that keeps movement exists")
	b._cmd(func(): return b.api.move(ship, st))
	await _wait_idle(60000)
	b.sel = ship
	b._refresh_ui()
	await _wait_idle(5000)
	var u1: Dictionary = b.VU[ship]
	_check(int(u1["q"]) != q0 or int(u1["r"]) != r0, "the ship moved")
	_check(bool(u1.get("undo", false)), "the view says the move can be undone")
	var acts := _card_acts()
	if not acts.is_empty():
		_check(acts.has("undo") and acts.has("end"), "the card offers Undo move beside End ship (%s)" % ", ".join(acts))
	b._on_key(KEY_BACKSPACE)
	await _wait_idle(30000)
	b._refresh_ui()
	await _wait_idle(5000)
	var u2: Dictionary = b.VU[ship]
	_check(int(u2["q"]) == q0 and int(u2["r"]) == r0 and int(u2["facing"]) == f0, "after Backspace the ship stands on its start hex and facing")
	var sv = b.views[ship]
	var want: Vector3 = b.board.hex_world(q0, r0)
	var dist := Vector2(sv.position.x - want.x, sv.position.z - want.z).length()
	_check(dist < 0.5 and absf(angle_difference(sv.cur_yaw, ShipView.yaw_of(f0))) < 0.05, "the drawn ship is back on the start hex (%.2f away)" % dist)
	var reach1: Array = b.reach_map.keys()
	reach1.sort()
	_check(not reach1.is_empty() and reach1 == reach0, "the reach overlay is rebuilt from the start hex (%d hexes, %d before)" % [reach1.size(), reach0.size()])
	_check(not bool(u2.get("undo", false)) and not u2["active"], "nothing left to undo and the ship is free again")
	acts = _card_acts()
	if not acts.is_empty():
		_check(not acts.has("undo") and acts.has("next"), "the card drops Undo move and offers Next ship (%s)" % ", ".join(acts))
	b._on_key(KEY_BACKSPACE)
	await _wait_idle(5000)
	_check(b.api.take_events().is_empty() and int(b.VU[ship]["q"]) == q0, "a second Backspace changes nothing")
	var unknown: Dictionary = b.get_meta("unknown_events", {})
	_check(not unknown.has("undo") and unknown.is_empty(), "no unknown event kind warning (%s)" % str(unknown.keys()))
	print("undo scene check: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
