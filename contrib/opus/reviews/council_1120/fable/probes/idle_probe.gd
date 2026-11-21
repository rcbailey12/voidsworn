extends SceneTree
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var q := "max"
	for i in a.size():
		if a[i] == "--q": q = a[i + 1]
	root.size = Vector2i(1920, 1080)
	# 1) FXAA stickiness: a Low battle, then a Max battle, on the same root viewport as the game does
	var lowb = BattleScene.instantiate(); lowb.external = true; lowb.args["quality"] = "low"; root.add_child(lowb)
	await process_frame
	print("[aa] after a Low battle: screen_space_aa=%d msaa=%d" % [root.screen_space_aa, root.msaa_3d])
	lowb.queue_free()
	await process_frame; await process_frame
	b = BattleScene.instantiate()
	b.tips_off = true
	b.args["quality"] = q
	var t0 := Time.get_ticks_usec()
	root.add_child(b)
	print("[load] add_child(battle) blocked %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	print("[aa] then a %s battle: screen_space_aa=%d (0 off, 1 FXAA) msaa=%d" % [q, root.screen_space_aa, root.msaa_3d])
	var last := Time.get_ticks_usec(); var worst := 0.0; var frames := 0; var over100 := 0
	var w0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - w0 < 120000:
		await process_frame
		var now := Time.get_ticks_usec()
		var d := (now - last) / 1000.0
		worst = maxf(worst, d); frames += 1
		if d > 100.0: over100 += 1
		last = now
	print("[load] battle ready after %d ms, %d frames, longest frame %.0f ms, frames over 100 ms: %d" % [Time.get_ticks_msec() - w0, frames, worst, over100])
	for i in 200: await process_frame
	var units: int = b.V["units"].size()
	# idle cost: script time per frame with the player doing nothing
	var sum := 0.0; var mx := 0.0
	for i in 300:
		await process_frame
		var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		sum += p; mx = maxf(mx, p)
	print("[idle] %d units, quality %s: process time avg %.2f ms, max %.2f ms per frame; nodes %d, orphans %d" % [units, q, sum / 300.0, mx, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)])
	# what runs per frame
	var procs := {}
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_processing() and n.get_script() != null:
			var s: String = n.get_script().resource_path.get_file()
			procs[s] = int(procs.get(s, 0)) + 1
		stack.append_array(n.get_children())
	print("[idle] nodes with _process on: ", procs)
	quit()
