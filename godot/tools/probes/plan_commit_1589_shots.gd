extends SceneTree
# Issue 1589: pictures and a clip of a planned turn in the real battle scene. Two enemies are brought a few hexes ahead of
# the first ready ship (s1 opens far apart), then:
#   PLN-1589_plan   four frames while planning: the ghost on the planned hex, the first pick, the second pick, the card
#   PLN-1589_commit four frames after the commit, on the game clock: the move and the volley playing as one event
#   ENY-1589        four frames of the enemy's next activation (it plays the same way)
# All waits are on the game clock, so a movie run (Godot's --write-movie with --fixed-fps 60) records the same moments as
# one clip. Each strip is 2 by 2, no taller than 720 px, its code name and stage on every frame.
# usage (needs a window): godot --path godot --script res://tools/probes/plan_commit_1589_shots.gd -- --out <folder>
#   [--cam 170] [--stage "PC, installed in game"] [--seed 1001]

var b
const ShipViewS := preload("res://render/ship_view.gd")
const COMMIT_AT := [0.4, 1.6, 3.0, 4.6]   # seconds after the commit
const ENEMY_AT := [0.8, 2.2, 3.8, 5.6]    # seconds after the player's ship ends
var out := ""
var stage := ""
var label: Label


func _initialize() -> void:
	_run.call_deferred()


func _arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--" + k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d


func _idle() -> void:
	var t0 := Time.get_ticks_msec()
	while b.busy or b.warming or b._threat_busy or b.thinking or not b.batches.is_empty():
		await process_frame
		if Time.get_ticks_msec() - t0 > 120000:
			break
	for i in 4:
		await process_frame


func _sync() -> void:
	b.api.version += 1
	b.V = b.api.view()
	b._index_view()
	for u in b.V["units"]:
		var sv = b.views.get(u["id"])
		if sv != null and not u["dead"]:
			sv.position = b.board.hex_world(int(u["q"]), int(u["r"]))
			sv.rotation.y = ShipViewS.yaw_of(int(u["facing"]))
	b.reach_map.clear()
	b._refresh_ui()


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	img.resize(640, int(640.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_LANCZOS)
	return img


func _save(code: String, frames: Array) -> void:
	if frames.size() < 4:
		print("[plan-1589-shots] %s: only %d frames" % [code, frames.size()])
		return
	var w: int = (frames[0] as Image).get_width()
	var h: int = (frames[0] as Image).get_height()
	var sheet := Image.create(w * 2, h * 2, false, (frames[0] as Image).get_format())
	for i in 4:
		sheet.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	if sheet.get_height() > 720:
		sheet.resize(int(sheet.get_width() * 720.0 / sheet.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var pp = preload("res://tools/picture_provenance.gd")
	var p := out.path_join("%s.jpg" % code)
	pp.save_jpg(sheet, p, 0.9, pp.capture_stage())
	print("[plan-1589-shots] ", p)


func _tag(code: String, what: String) -> void:
	label.text = "%s   %s   (1589 r1, %s)" % [code, what, stage]


func _strip(code: String, what: String, at: Array) -> Array:
	var frames: Array = []
	var prev := 0.0
	for t in at:
		if float(t) > prev:
			await create_timer(float(t) - prev).timeout
		prev = float(t)
		_tag(code, "%s +%.1f s" % [what, float(t)])
		frames.append(await _grab())
	return frames


func _enemies() -> Array:
	var out_ids: Array = []
	for u in b.V["units"]:
		if u["side"] == "enemy" and not u["dead"]:
			out_ids.append(str(u["id"]))
	return out_ids


func _plan_and_commit() -> void:
	var R = b.api.R
	var me = null
	for u in R.alive("player"):
		if not R.jt(u.get("isSq")) and not R.jt(u.get("activated")):
			me = u
			break
	if me == null:
		print("[plan-1589-shots] no ready ship"); return
	var foes: Array = R.alive("enemy")
	var f := int(me["facing"])
	var d0: Array = R.DIRS[f]
	var d1: Array = R.DIRS[(f + 1) % 6]
	var spots := [Vector2i(int(me["q"]) + d0[0] * 4, int(me["r"]) + d0[1] * 4),
		Vector2i(int(me["q"]) + d0[0] * 4 + d1[0] * 2, int(me["r"]) + d0[1] * 4 + d1[1] * 2)]
	for i in mini(2, foes.size()):
		if R.onBoard(spots[i].x, spots[i].y) and R.unitAt(spots[i].x, spots[i].y) == null:
			foes[i]["q"] = spots[i].x
			foes[i]["r"] = spots[i].y
	_sync()
	b.select(str(me["id"]), "pick")
	await _idle()
	# the planned hex that brings the most enemies under the guns (one hex or more away)
	var best = null
	var best_n := 0
	for k in b.reach_map:
		var st = b.reach_map[k]
		if (int(st.q) == int(me["q"]) and int(st.r) == int(me["r"])) or not b._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		b.plan = st
		var n := 0
		for e in _enemies():
			if not b._firing_set(e).is_empty():
				n += 1
		b.plan = null
		if n > best_n:
			best_n = n
			best = st
	if best == null:
		print("[plan-1589-shots] no planned hex puts an enemy under the guns"); return
	var mid: Vector3 = b._pos(str(me["id"])).lerp(b.board.hex_world(int(best.q), int(best.r)), 0.5)
	b.cam.focus(mid, float(_arg("cam", "170")))
	await create_timer(1.2).timeout
	var frames: Array = []
	b.hover = Vector2i(int(best.q), int(best.r))
	b._on_click()
	b._overlay()
	await create_timer(0.6).timeout
	_tag("PLN-1589", "1 ghost on the planned hex (nothing has moved)")
	frames.append(await _grab())
	var picks := 0
	for e in _enemies():
		if picks < 2 and not b._firing_set(e).is_empty():
			b._target(e)
			picks += 1
			await create_timer(0.6).timeout
			_tag("PLN-1589", "%d pick %d aimed from the ghost" % [picks + 1, picks])
			frames.append(await _grab())
	while frames.size() < 3:
		frames.append(frames[-1])
	b._refresh_ui()
	await create_timer(0.4).timeout
	_tag("PLN-1589", "4 the card: Move and fire")
	frames.append(await _grab())
	await _save("PLN-1589_plan", frames)
	b._confirm()
	await _save("PLN-1589_commit", await _strip("PLN-1589", "commit: one event", COMMIT_AT))
	await _idle()
	b._end_ship("probe")
	await _save("ENY-1589", await _strip("ENY-1589", "enemy activation", ENEMY_AT))


func _run() -> void:
	out = _arg("out", "user://plan_commit_1589")
	stage = _arg("stage", "cloud, compatibility renderer")
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	b = scene.instantiate()
	b.args["scenario"] = "s1"
	b.args["seed"] = int(_arg("seed", "1001"))
	root.add_child(b)
	var cl := CanvasLayer.new(); cl.layer = 120; root.add_child(cl)
	label = Label.new(); label.position = Vector2(40, 14)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	cl.add_child(label)
	while b.api == null or b.V.is_empty():
		await process_frame
	await create_timer(2.5).timeout
	await _idle()
	b.tips_off = true
	await _plan_and_commit()
	await create_timer(1.0).timeout
	quit(0)
