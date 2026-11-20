extends SceneTree
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
func _init() -> void:
	_run.call_deferred()
func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player"
func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	print("[probe] idle after %d ms; danger_on=%s threat_on=%s tips_off=%s" % [Time.get_ticks_msec() - t0, b.danger_on, b.threat_on, b.tips_off])
	# let the first threat map finish untouched
	for i in 600:
		await process_frame
		if b._threat_tid < 0 and b._threat_current(): break
	print("[probe] first threat map current: ", b._threat_current())
	var vs: Vector2 = root.get_visible_rect().size
	for round_i in 4:
		# a player command, as a click would issue it
		var moved := false
		for u in b.V["units"]:
			if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
				var r = b.api.reach(str(u["id"]))
				if r.size() > 1:
					var st = r[r.size() / 2]
					moved = b._cmd(func(): return b.api.move(str(u["id"]), st))
					if moved: break
		var w0 := Time.get_ticks_msec()
		while not _idle() and Time.get_ticks_msec() - w0 < 60000:
			await process_frame
		# now the player is free: move the mouse every frame, time each frame
		var worst := 0.0; var worst_tip := 0.0; var joins := 0
		var last := Time.get_ticks_usec()
		for f in 240:
			var ev := InputEventMouseMotion.new()
			ev.position = Vector2(vs.x * (0.3 + 0.4 * fmod(f * 0.037, 1.0)), vs.y * (0.35 + 0.3 * fmod(f * 0.061, 1.0)))
			ev.global_position = ev.position
			var pending: bool = b._threat_tid >= 0
			var c0 := Time.get_ticks_usec()
			b._unhandled_input(ev)
			var c := (Time.get_ticks_usec() - c0) / 1000.0
			if pending and c > 5.0: joins += 1
			worst_tip = maxf(worst_tip, c)
			await process_frame
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
		print("[probe] action %d moved=%s: worst mouse-move handler %.0f ms, worst frame %.0f ms, blocking joins %d" % [round_i, moved, worst_tip, worst, joins])
	quit()
