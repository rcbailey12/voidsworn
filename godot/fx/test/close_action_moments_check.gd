extends SceneTree
# Issues 1524 and 1461: the close-action effects fire at their battle moment, with their approved sound, and keep the
# moment's pace. The live battle scene (test battle s1) plays a ram (with a one-hex charge), a boarding and an admiral's
# command through its own _play_event, with a recording fx stand-in and a recording sound layer:
#   ram:     the move finishes first; the ram volley (weapon_id ram) lands on the same frame as the ram's boom (gain 0.8 at
#            the target); the hold after it stays 500 ms of battle pace.
#   board:   fx.board plays on the same frame as board_grapple (the boarder's faction variant, so Chorus stays wet);
#            the hold is the breach look's (fx.board_hold_ms, issue 1547), so the player sees it before the next event.
#   command: the flagship pulse plays under the banner with the approved player cue ui_command_issue;
#            the hold stays the banner pace plus 140 ms.
# Headless:  godot --headless --path godot --script res://fx/test/close_action_moments_check.gd
const GUARD := preload("res://tools/ci/check_guard.gd")
const BattleScene := preload("res://scenes/battle/battle.tscn")
const SPEED := 0.25
var failures := 0
var log: Array = []   # [frame, ms, who, name, args, game clock ms]
var clock: Clock


# The game clock the battle's waits run on: the sum of frame deltas (a wait's timer counts the same deltas, so a hold
# measured here is exact to one frame; wall time is not: SHOTS3 on the PC read 105 ms for a 130 ms wait, because the
# timer's first delta includes the frame time spent before the wait began).
class Clock extends Node:
	var ms := 0.0
	var max_dt := 0.0
	func _process(dt: float) -> void:
		ms += dt * 1000.0
		max_dt = maxf(max_dt, dt * 1000.0)


func _init() -> void:
	GUARD.arm(self, "close_action_moments_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1
		push_error(message)


func _note(who: String, n: String, a: Array) -> void:
	log.append([Engine.get_process_frames(), Time.get_ticks_msec(), who, n, a, clock.ms])


const BOARD_HOLD := 1600.0   # issue 1547: the recording fx's breach hold (the real one is fx.gd board_hold_ms)


class RecFx extends Node:
	var tree
	var now := 0.0
	var reduce_flashing := false
	var kill_slowmo := false
	var shake_scale := 1.0
	func _r(n: String, a: Array) -> void: tree._note("fx", n, a)
	func pop(...a: Array) -> void: _r("pop", a)
	func light(...a: Array) -> void: _r("light", a)
	func command(...a: Array) -> void: _r("command", a)
	func set_engine(...a: Array) -> void: _r("set_engine", a)
	func sync_ship(...a: Array) -> void: _r("sync_ship", a)
	func volley(...a: Array) -> Dictionary:
		_r("volley", a)
		return {"done": 0.0, "impacts": [0.0], "fires": [0.0]}
	func board(...a: Array) -> float:
		_r("board", a)
		return 3.2
	# issue 1547: the breach look's hold before the next event (fx.gd BOARD)
	func board_hold_ms() -> float:
		return BOARD_HOLD


class RecSfx extends "res://audio/sfx.gd":
	var tree
	func play(name: String, o := {}) -> void:
		tree._note("sfx", name, [o])
	func boom(s := 1.0, pos = null) -> void:
		tree._note("sfx", "boom", [s, pos])


func _first(who: String, n: String) -> Array:
	for r in log:
		if r[2] == who and r[3] == n:
			return r
	return []


func _last(who: String, n: String) -> Array:
	var out: Array = []
	for r in log:
		if r[2] == who and r[3] == n:
			out = r
	return out


func _sounds() -> Array:
	var out: Array = []
	for r in log:
		if r[2] == "sfx" and r[3] != "engine":
			out.append(r[3])
	return out


# plays one event; returns the ms from the effect call to the end of the event
# (the battle's own runner is held, and the pace reset, so nothing else changes the pace mid-event: on the PC an
# enemy batch once started under the check and cut the command's hold to 19 ms, SHOTS2)
func _play(b, e: Dictionary, effect: String) -> float:
	b.hold = true
	b.skip = false
	b.speed = SPEED
	b.user_speed = SPEED
	log.clear()
	clock.max_dt = 0.0   # the band is two of this event's own frames
	await b._play_event(e)
	_check(is_equal_approx(float(b.speed), SPEED), "nothing changed the pace while %s played (%.3f)" % [str(e["t"]), float(b.speed)])
	var r := _first("fx", effect)
	return clock.ms - float(r[5]) if not r.is_empty() else -1.0


# a hold is right when the game clock ran at least the wait and at most two frames past it (the timer fires on the
# frame its deltas reach the wait; the event returns on that frame or the next)
func _held_ok(held: float, want: float) -> bool:
	return held >= want - 0.5 and held <= want + 2.0 * clock.max_dt + 0.5


func _run() -> void:
	clock = Clock.new()
	clock.process_priority = -1000
	root.add_child(clock)
	var b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	root.add_child(b)
	b.args["scenario"] = "s1"
	b.args["seed"] = 1001
	b.start_default()
	var t0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	_check(b.api != null and b.api.phase == "player", "the battle scene reached the player's turn")
	if b.api == null:
		quit(1)
		return
	b.hold = true   # the battle's own runner waits while the check plays its events
	var R = b.api.R
	var mine := ""
	var foe := ""
	var flag := ""
	for u in b.V["units"]:
		if u["dead"] or u["squadron"]:
			continue
		if u["side"] == "player" and mine == "":
			mine = str(u["id"])
		elif u["side"] == "enemy" and foe == "":
			foe = str(u["id"])
	_check(mine != "" and foe != "", "test battle s1 has a player ship and an enemy ship")
	# the run's flagship (rules pflag, from the run's flagUid): s1's own, else the first player ship made it for this check
	for u in R.B["units"]:
		if u["side"] == "player" and R.jt(u.get("pflag")) and not R.jt(u.get("dead")):
			flag = str(u["id"])
			break
	if flag == "":
		for u in R.B["units"]:
			if str(u["id"]) == mine:
				u["pflag"] = true
		flag = mine
	print("INFO the player's flagship is %s" % flag)
	var u0: Dictionary = b.VU.get(mine, {})
	var f := int(u0.get("facing", 0))
	var d: Array = R.DIRS[f]
	var step := {"q": int(u0["q"]) + int(d[0]), "r": int(u0["r"]) + int(d[1]), "f": f}
	var rec := RecFx.new()
	rec.tree = self
	root.add_child(rec)
	var real_fx = b.gfx
	var real_sfx = b.sfx
	b.gfx = rec
	var rs := RecSfx.new()
	rs.tree = self
	b.add_child(rs)
	b.sfx = rs
	b.speed = SPEED
	b.user_speed = SPEED
	var fac := str(u0.get("fac", ""))

	print("-- ram (a one-hex charge, then the hit)")
	var held := await _play(b, {"t": "ram", "unit": mine, "target": foe, "path": [step], "dmg": 1, "section": "mid", "recoil": 1}, "volley")
	var v := _first("fx", "volley")
	var bm := _first("sfx", "boom")
	var eng := _last("fx", "set_engine")
	_check(not v.is_empty() and str((v[4] as Array)[1]) == "torp" and str(((v[4] as Array)[3] as Dictionary).get("weapon_id", "")) == "ram", "the ram plays volley(torp, weapon_id ram)")
	_check(not eng.is_empty(), "the ram's charge moved the ship (its drive was driven)")
	_check(not v.is_empty() and not eng.is_empty() and int(v[0]) >= int(eng[0]), "the hit lands after the charge (volley frame %s, last drive frame %s)" % [str(v[0]) if not v.is_empty() else "-", str(eng[0]) if not eng.is_empty() else "-"])
	_check(not bm.is_empty() and is_equal_approx(float((bm[4] as Array)[0]), 0.8), "the ram's approved sound: boom at 0.8")
	_check(not bm.is_empty() and not v.is_empty() and int(bm[0]) == int(v[0]), "the boom and the crumple land on the same frame")
	_check(_first("fx", "pop").is_empty(), "no placeholder pop")
	_check(_held_ok(held, 500.0 * SPEED), "the ram keeps its 500 ms hold (%.1f game ms at pace %.2f, want %.0f to %.0f)" % [held, SPEED, 500.0 * SPEED, 500.0 * SPEED + 2.0 * clock.max_dt])
	_check(_sounds() == ["boom"], "the ram plays only its boom (%s)" % str(_sounds()))

	print("-- board")
	held = await _play(b, {"t": "board", "unit": mine, "target": foe, "result": "repelled", "kill": 1, "loss": 1}, "board")
	var bd := _first("fx", "board")
	var gr := _first("sfx", "board_grapple")
	_check(not bd.is_empty() and (bd[4] as Array).slice(0, 3) == [mine, foe, "repelled"], "the boarding plays board(unit, target, result)")
	_check(not gr.is_empty() and str(((gr[4] as Array)[0] as Dictionary).get("variant", "?")) == fac, "the boarding's approved sound: board_grapple, the boarder's variant (%s)" % fac)
	_check(not gr.is_empty() and not bd.is_empty() and int(gr[0]) == int(bd[0]), "the grapple and the breach start on the same frame")
	_check(_first("fx", "pop").is_empty(), "no placeholder pop")
	_check(_held_ok(held, BOARD_HOLD * SPEED), "the boarding holds for the breach look's hold (%.1f game ms, want %.0f to %.0f)" % [held, BOARD_HOLD * SPEED, BOARD_HOLD * SPEED + 2.0 * clock.max_dt])
	_check(_sounds() == ["board_grapple"], "the boarding plays only its grapple (%s)" % str(_sounds()))

	print("-- command (the player's: names no unit)")
	var cmd := ""
	var cs = b.TBL.get("COMMANDS", {})
	for c in (cs.values() if cs is Dictionary else cs):
		if c is Dictionary and c.has("id"):
			cmd = str(c["id"])
			break
	held = await _play(b, {"t": "command", "side": "player", "id": cmd, "tier": 0, "unit": null}, "command")
	var cm := _first("fx", "command")
	_check(not cm.is_empty() and (cm[4] as Array).slice(0, 2) == [flag, cmd], "the command pulses the player's flagship (%s)" % (str(cm[4]) if not cm.is_empty() else "none"))
	_check(_sounds() == ["ui_command_issue"], "the player command plays only its approved cue (%s)" % str(_sounds()))
	var want := (float(b.PACE["banner"]) + 140.0) * SPEED
	_check(_held_ok(held, want), "the command keeps its banner hold (%.1f game ms, want %.0f to %.0f)" % [held, want, want + 2.0 * clock.max_dt])

	b.gfx = real_fx
	b.sfx = real_sfx
	rs.queue_free()
	rec.queue_free()
	b.queue_free()
	clock.queue_free()
	await process_frame
	await process_frame
	print("CLOSE_ACTION_MOMENTS %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
