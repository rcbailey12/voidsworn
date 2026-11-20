extends SceneTree
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	var w0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - w0 < 120000:
		await process_frame
	for i in 300: await process_frame
	var xs: Array = []; var busy_frames := 0; var tasks := 0
	var t0 := Time.get_ticks_msec()
	for i in 1500:
		await process_frame
		xs.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		if b._threat_tid >= 0: busy_frames += 1
	var wall := Time.get_ticks_msec() - t0
	xs.sort()
	print("[idle] %d units, 1500 idle frames in %d ms wall: script process time median %.2f ms, p90 %.2f, p99 %.2f, max %.2f; threat task running on %d frames; fx notes %d" % [b.V["units"].size(), wall, xs[750], xs[1350], xs[1485], xs[1499], busy_frames, b.gfx.notes.size() if b.gfx != null else -1])
	quit()
