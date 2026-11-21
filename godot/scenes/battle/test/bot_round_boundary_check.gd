extends SceneTree
# Issue 1499 (Artoo, issue 906, found in PR 1486): the scene bot (rendered tests and player-path recordings, never a human
# turn) must not spend a ship's next-round move. battle.gd _bot_step hands a ship to the rules AI (ai_activate) and then
# passes it if the AI left it idle. When that AI action ended the round, the rules reset every activation flag and hand the
# turn back to the player, so the old fallback passed the same ship again and used up its first move of the new round.
# Test battle s1 in the real battle scene, two cases:
#   A. same round, ship left idle: the enemy ships are held off the field (treeOff, as a reserve) so the AI has no foe and
#      leaves the ship idle; another player ship still waits, so the round goes on. The bot must pass the idle ship.
#   B. round boundary: every other ship on both sides has acted, so the AI's own end of activation ends the round. In the
#      new round the ship must still have its move (activated false), and nothing else moved for it.
# Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://scenes/battle/test/bot_round_boundary_check.gd
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
var fails := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player" \
		and not b._threat_busy


func _wait_idle(ms: int) -> void:
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < ms:
		await process_frame
	for k in 10:
		await process_frame


func _free_ships() -> Array:
	var out: Array = []
	for u in b.api.R.B["units"]:
		if u["side"] == "player" and not b.api.R.jt(u.get("dead")) and not b.api.R.jt(u.get("isSq")) and not b.api.R.jt(u.get("activated")):
			out.append(u)
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
	if not _idle() or not b.api.has_method("ai_activate") or b._classic():
		_check(false, "the battle reached the player's turn in activation mode with the rules AI")
		quit(1)
		return
	var B: Dictionary = b.api.R.B
	var free := _free_ships()
	_check(free.size() >= 2, "at least two player ships wait at the start (%d)" % free.size())
	if free.size() < 2:
		quit(1)
		return

	# A. same round, the AI leaves the ship idle: the bot passes it
	var ua: Dictionary = free[0]
	var ida := str(ua["id"])
	var r_a := int(B["round"])
	var held: Array = []
	for u in B["units"]:
		if u["side"] == "enemy" and not b.api.R.jt(u.get("treeOff")):
			u["treeOff"] = true
			held.append(u)
	b.V = b.api.view()
	b.bot_tried.clear()
	b._bot_step()
	await _wait_idle(60000)
	for u in held:
		u.erase("treeOff")
	b.V = b.api.view()
	_check(int(B["round"]) == r_a, "A: the round did not change (round %d)" % int(B["round"]))
	_check(int(b.api.R.z0(ua.get("hexMoved"))) == 0, "A: the AI found no foe and left the ship where it was")
	_check(b.api.R.jt(ua.get("activated")), "A: the bot passed the idle ship, as the player's Pass does (activated true)")
	_check(b.api.phase == "player" and _free_ships().size() >= 1, "A: the other player ship still waits in the same round")

	# B. round boundary: the AI's action is the last of the round
	var ub: Dictionary = _free_ships()[0]
	var idb := str(ub["id"])
	for u in B["units"]:
		if not is_same(u, ub) and not b.api.R.jt(u.get("dead")) and not b.api.R.jt(u.get("isSq")):
			u["activated"] = true
	B["activeUnit"] = null
	b.V = b.api.view()
	b.bot_tried.clear()
	var r_b := int(B["round"])
	b._bot_step()
	await _wait_idle(120000)
	_check(int(B["round"]) == r_b + 1, "B: the AI's end of activation ended round %d (now round %d)" % [r_b, int(B["round"])])
	_check(b.api.phase == "player", "B: the new round is the player's turn (phase %s)" % b.api.phase)
	var still := false
	for u in _free_ships():
		if str(u["id"]) == idb:
			still = true
	_check(still, "B: %s keeps its first move of round %d (activated %s; on main it was spent by the bot's pass)" % [idb, r_b + 1, str(ub.get("activated"))])
	_check(B.get("activeUnit") == null, "B: no ship is mid-activation for the player")

	print("bot round boundary check: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(0 if fails == 0 else 1)
