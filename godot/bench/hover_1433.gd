extends SceneTree
# Issue 1433 PC proof: Fable's hover probe (contrib/opus/reviews/council_1120/fable/probes/hover_probe.gd) with a result
# file and a verdict. Four player moves; after each, the mouse moves every frame for 240 frames. Per move: the worst
# mouse handler, the worst frame interval, and waits (a handler over 5 ms while the threat task is still running, not
# merely finished and waiting to be reaped). PASS when every move has a worst frame under 50 ms and no waits.
# Run: godot --path godot [--fullscreen] --script res://bench/hover_1433.gd -- --out <folder>
const BattleScene = preload("res://scenes/battle/battle.tscn")
const LIMIT_MS := 50.0
var b
var out_dir := ""
var lines: Array = []


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--out")
	if i >= 0 and i + 1 < a.size():
		out_dir = a[i + 1]
	_run.call_deferred()


func _say(s: String) -> void:
	print(s)
	lines.append(s)


func _idle() -> bool:
	return b.api != null and not b.warming and not b.busy and not b.thinking and b.batches.is_empty() and b.api.phase == "player"


func _finish(pass_all: bool, why: String) -> void:
	_say("[hover1433] RESULT %s %s" % ["PASS" if pass_all else "FAIL", why])
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
		var f := FileAccess.open(out_dir.path_join("hover_result.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(lines) + "\n")
			f.close()
	quit(0 if pass_all else 1)


func _run() -> void:
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	_say("[hover1433] display %s, window %s" % [DisplayServer.get_name(), str(root.get_visible_rect().size)])
	var t0 := Time.get_ticks_msec()
	while not _idle() and Time.get_ticks_msec() - t0 < 180000:
		await process_frame
	if not _idle():
		_finish(false, "battle never reached the player's turn")
		return
	for i in 600:
		await process_frame
		if b._threat_tid < 0 and b._threat_current(): break
	var vs: Vector2 = root.get_visible_rect().size
	var pass_all := true
	var moves := 0
	for round_i in 4:
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
		var worst := 0.0; var worst_h := 0.0; var waits := 0; var pend := 0
		var last := Time.get_ticks_usec()
		for f in 240:
			var ev := InputEventMouseMotion.new()
			ev.position = Vector2(vs.x * (0.3 + 0.4 * fmod(f * 0.037, 1.0)), vs.y * (0.35 + 0.3 * fmod(f * 0.061, 1.0)))
			ev.global_position = ev.position
			var running: bool = b._threat_tid >= 0 and not WorkerThreadPool.is_task_completed(b._threat_tid)
			if running: pend += 1
			var c0 := Time.get_ticks_usec()
			b._unhandled_input(ev)
			var c := (Time.get_ticks_usec() - c0) / 1000.0
			if running and c > 5.0: waits += 1
			worst_h = maxf(worst_h, c)
			await process_frame
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
		if moved: moves += 1
		var ok: bool = moved and worst < LIMIT_MS and waits == 0
		pass_all = pass_all and ok
		_say("[hover1433] move %d moved=%s: worst handler %.0f ms, worst frame %.0f ms, waits %d, frames with the map computing %d: %s" % [round_i, moved, worst_h, worst, waits, pend, "ok" if ok else "OVER"])
	_finish(pass_all and moves == 4, "(%d of 4 moves, limit %d ms worst frame, 0 waits)" % [moves, int(LIMIT_MS)])
