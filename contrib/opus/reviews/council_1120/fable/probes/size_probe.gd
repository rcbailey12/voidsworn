extends SceneTree
const BattleScene = preload("res://scenes/battle/battle.tscn")
const UIS = preload("res://ui/ui_scale.gd")
var b
func _init() -> void:
	_run.call_deferred()
func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var want := Vector2i(0, 0)
	for i in a.size():
		if a[i] == "--win": 
			var wh = a[i + 1].split("x"); want = Vector2i(int(wh[0]), int(wh[1]))
	print("[size] default root.size=", root.size, " visible=", root.get_visible_rect().size)
	if want.x > 0:
		root.size = want
	await process_frame
	b = BattleScene.instantiate()
	b.tips_off = true
	root.add_child(b)
	var t0 := Time.get_ticks_msec()
	while (b.api == null or b.warming or b.busy or b.api.phase != "player") and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	# select first player ship as a click would
	for i in 30: await process_frame
	var vs: Vector2 = root.get_visible_rect().size
	var lg = b.hud.ledger
	lg.layout()
	var neg := 0; var off := 0; var tiny := 0; var names := []
	for h in lg.hits:
		var r: Rect2 = h.r
		if r.size.x < 0 or r.size.y < 0:
			neg += 1; names.append("NEG %s %s" % [h.act, r])
		elif r.position.x < -1 or r.position.y < -1 or r.end.x > vs.x + 1 or r.end.y > vs.y + 1:
			off += 1; names.append("OFF %s %s" % [h.act, r])
		elif h.act != "" and (r.size.x < 24 or r.size.y < 24):
			tiny += 1; names.append("TINY %s %s" % [h.act, r.size])
	var minfont := 1000
	print("[size] window %s k=%.2f compact=%s hits=%d negative=%d offscreen=%d tiny(<24px)=%d  text floor %d px" % [vs, UIS.k_for(vs), vs.x < 1510 * UIS.k_for(vs), lg.hits.size(), neg, off, tiny, UIS.px(UIS.MIN_TEXT, UIS.k_for(vs))])
	for n in names.slice(0, 8): print("   ", n)
	quit()
