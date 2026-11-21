extends SceneTree
# Issue 1433 (Astra item 1): after a ship moves, the threat map computes on a worker. Mouse handlers must never wait on
# it: no handler over 50 ms while the worker runs, the tip and danger arrive once the result lands, and a click made
# while it runs is kept once and played after the result (not dropped). Also: a retired battle publishes nothing.
# Same input loop as contrib/opus/reviews/council_1120/fable/probes/hover_probe.gd; headless, placeholder hulls.
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
var fails := 0


func _init() -> void:
	_run.call_deferred()


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player"


func _fail(m: String) -> void:
	fails += 1
	printerr("FAIL: ", m)


func _move_one() -> bool:
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
			var r = b.api.reach(str(u["id"]))
			if r.size() > 1:
				var st = r[r.size() / 2]
				if b._cmd(func(): return b.api.move(str(u["id"]), st)):
					return true
	return false


func _wait_idle() -> void:
	var w0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - w0 < 60000:
		await process_frame


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	if not _idle():
		_fail("battle never reached the player's turn")
		quit(1)
		return
	for i in 600:
		await process_frame
		if b._threat_tid < 0 and b._threat_current(): break
	var vs: Vector2 = root.get_visible_rect().size
	var pending_frames := 0
	for round_i in 3:
		if not _move_one():
			print("[hover_wait] round %d: no move left, stop" % round_i)
			break
		await _wait_idle()
		var worst := 0.0
		var saw_pending := false
		for f in 120:
			var ev := InputEventMouseMotion.new()
			ev.position = Vector2(vs.x * (0.3 + 0.4 * fmod(f * 0.037, 1.0)), vs.y * (0.35 + 0.3 * fmod(f * 0.061, 1.0)))
			ev.global_position = ev.position
			var pending: bool = b._threat_tid >= 0
			var c0 := Time.get_ticks_usec()
			b._unhandled_input(ev)
			var c := (Time.get_ticks_usec() - c0) / 1000.0
			if pending:
				saw_pending = true
				pending_frames += 1
				worst = maxf(worst, c)
			await process_frame
		print("[hover_wait] round %d: worst handler while the map computed %.1f ms (pending seen %s)" % [round_i, worst, saw_pending])
		if worst > 50.0:
			_fail("round %d: a mouse handler took %.1f ms while the threat worker ran" % [round_i, worst])
		if b._threat_tid >= 0 or not b._threat_current():
			for i in 600:
				await process_frame
				if b._threat_tid < 0 and b._threat_current(): break
		if not b._threat_current():
			_fail("round %d: the threat map never published" % round_i)
	if pending_frames == 0:
		print("[hover_wait] note: the map finished before any mouse event saw it pending (fast machine)")
	# a click while the worker runs is queued once, then played after the result lands
	await _click_check()
	# a retired battle publishes nothing
	await _retire_check()
	print("[hover_wait] %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)


func _click_check() -> void:
	await _wait_idle()
	var su: Dictionary = {}
	for u in b.V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"] and b._usable(u):
			su = u
			break
	if su.is_empty():
		print("[hover_wait] click check skipped: no usable ship")
		return
	b.select(str(su["id"]))
	await process_frame
	if b.reach_map.is_empty():
		b._update_reach()
	if b.reach_map.is_empty():
		print("[hover_wait] click check skipped: no reach")
		return
	var hk := ""
	for k in b.reach_map:
		var kp: PackedStringArray = str(k).split(",")
		if b._unit_at(int(kp[0]), int(kp[1])).is_empty():
			hk = str(k)
			break
	if hk == "":
		print("[hover_wait] click check skipped: no empty reach hex")
		return
	var parts := hk.split(",")
	# force a fresh computation, then click while it runs
	b._threat_version = -1
	b._threat_request()
	if b._threat_tid < 0:
		print("[hover_wait] click check skipped: no worker started (threat map off)")
		return
	b.hover = Vector2i(int(parts[0]), int(parts[1]))
	var c0 := Time.get_ticks_usec()
	b._on_click()
	var c := (Time.get_ticks_usec() - c0) / 1000.0
	var queued: bool = not b._click_q.is_empty()
	var still: bool = b._threat_tid >= 0
	print("[hover_wait] click while computing: handler %.1f ms, queued %s, worker still running %s" % [c, queued, still])
	if c > 50.0 and still:
		_fail("the click handler waited %.1f ms on the worker" % c)
	if still and not queued:
		_fail("a click while the worker ran was dropped")
	for i in 600:
		await process_frame
		if b._threat_tid < 0 and b._click_q.is_empty(): break
	await process_frame
	await process_frame
	if queued and b.plan_k != hk:
		_fail("the queued click was not played after the result landed (plan_k=%s, want %s)" % [b.plan_k, hk])
	elif queued:
		print("[hover_wait] queued click played: planned move at %s" % hk)


func _retire_check() -> void:
	await _wait_idle()
	b._threat_version = -1
	b._threat_request()
	if b._threat_tid < 0:
		print("[hover_wait] retire check skipped: no worker started")
		return
	var v0: int = b._threat_version
	b._retire()
	for i in 600:
		await process_frame
		if b._threat_tid < 0: break
	await process_frame
	if b._threat_version != v0 or b._threat_busy:
		_fail("a retired battle still published its threat map (version %d, busy %s)" % [b._threat_version, b._threat_busy])
	else:
		print("[hover_wait] retired battle: threat result discarded, busy cleared")
