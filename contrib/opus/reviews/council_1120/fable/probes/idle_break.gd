extends SceneTree
const BattleScene = preload("res://scenes/battle/battle.tscn")
var b
func _init() -> void:
	_run.call_deferred()
func _avg(n: int) -> Array:
	var sum := 0.0; var mx := 0.0
	for i in n:
		await process_frame
		var p: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		sum += p; mx = maxf(mx, p)
	return [sum / n, mx]
func _group(file: String) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.is_processing() and n.get_script() != null and n.get_script().resource_path.get_file() == file:
			out.append(n)
		stack.append_array(n.get_children())
	return out
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	b = BattleScene.instantiate()
	b.tips_off = true
	b.external = true
	var t0 := Time.get_ticks_usec()
	root.add_child(b)
	print("[load] add_child (scene _ready, external) blocked %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	t0 = Time.get_ticks_usec()
	b.start_default()
	print("[load] start_default first sync stretch blocked %.0f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	var w0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - w0 < 120000:
		await process_frame
	for i in 300: await process_frame
	print("[idle] threat pending=%s thinking=%s busy=%s units=%d" % [b._threat_tid >= 0, b.thinking, b.busy, b.V["units"].size()])
	var base: Array = await _avg(240)
	print("[idle] baseline avg %.2f ms max %.2f ms" % base)
	for f in ["battle.gd", "hud.gd", "ship_view.gd", "squadron_wing.gd", "fx.gd", "world_living.gd", "board.gd", "look_rim.gd", "camera_rig.gd", "backdrop.gd", "fx_stub.gd", "sfx.gd"]:
		var g := _group(f)
		for n in g: n.set_process(false)
		var r: Array = await _avg(180)
		for n in g: n.set_process(true)
		print("[idle] without %s (%d nodes): avg %.2f ms  -> its share about %.2f ms" % [f, g.size(), r[0], base[0] - r[0]])
	quit()
