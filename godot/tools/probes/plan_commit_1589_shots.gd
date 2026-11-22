extends SceneTree
# Issue 1589: pictures and a clip of a planned turn in the real battle scene. Two enemies are brought a few hexes ahead of
# the first ready ship (s1 opens far apart), then:
#   PLN-1589_plan   four frames while planning: the ghost on the planned hex, the first pick, the second pick, the card
#   PLN-1589_commit four frames after the commit, on the game clock: the move and the volley playing as one event
#   PLN-1589_steps  four frames of the step controls: E turns the ghost, Backspace takes the turn back, the second pick,
#                   Backspace takes that pick back
#   ENY-1589        four frames of the enemy's next activation (it plays the same way)
# --glass (r2, the outside review on PR 1643): a Glasswright fleet instead of s1, one strip GLS-1589: the shot planned
# from where the ship sits, the commit, the move it still has after firing (issue 1560, R396: firing ends movement for
# every ship except Glasswrights) planned as a ghost, and that move playing. The probe exits 1 (and names the step) when
# it cannot show a ready ship, a planned hex with two distinct picks (or, with --glass, a move left after firing), or any
# of its pictures. --nopics skips the screen grabs (a headless logic run).
# All waits are on the game clock, so a movie run (Godot's --write-movie with --fixed-fps 60) records the same moments as
# one clip. Each strip is 2 by 2, no taller than 720 px, its code name and stage on every frame.
# usage (needs a window): godot --path godot --script res://tools/probes/plan_commit_1589_shots.gd -- --out <folder>
#   [--cam 170] [--stage "PC, installed in game"] [--seed 1001] [--glass] [--nopics]

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
	if OS.get_cmdline_user_args().has("--nopics"):
		await process_frame
		return Image.create(640, 360, false, Image.FORMAT_RGB8)
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
	var p := out.path_join("%s.jpg" % code)
	preload("res://tools/picture_provenance.gd").save_jpg(sheet, p, 0.9, preload("res://tools/picture_provenance.gd").capture_stage())
	print("[plan-1589-shots] ", p)


func _tag(code: String, what: String) -> void:
	label.text = "%s   %s   (1589 r2, %s)" % [code, what, stage]


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
		_fail("no ready ship"); return
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
		var used := {}
		for e in _enemies():   # count an enemy only when it brings guns no earlier one took (two distinct picks)
			var fresh := false
			for i in b._firing_set(e):
				if not used.has(int(i)):
					fresh = true
					used[int(i)] = true
			if fresh:
				n += 1
		b.plan = null
		if n > best_n:
			best_n = n
			best = st
	if best == null or best_n < 2:
		_fail("no planned hex gives two distinct picks (%d)" % best_n); return
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
	var picks: Array = []
	for e in _enemies():
		if picks.size() < 2 and not b._firing_set(e).is_empty():
			b._target(e)
			if b.aims.size() == picks.size() + 1:
				picks.append(e)
				await create_timer(0.6).timeout
				_tag("PLN-1589", "%d pick %d aimed from the ghost" % [picks.size() + 1, picks.size()])
				frames.append(await _grab())
	if picks.size() < 2:
		_fail("only %d distinct picks could be made" % picks.size()); return
	b._refresh_ui()
	await create_timer(0.4).timeout
	_tag("PLN-1589", "4 the card: Move and fire")
	frames.append(await _grab())
	await _save("PLN-1589_plan", frames)
	# the step controls: take the second pick back, turn the ghost and take the turn back, then aim the second pick again
	var steps: Array = []
	b._on_key(KEY_BACKSPACE)
	await create_timer(0.5).timeout
	_tag("PLN-1589", "steps 1 Backspace: the second pick is taken back (%d left)" % b.aims.size())
	steps.append(await _grab())
	var f_keep := int(b.plan.f)
	b._rotate(1)
	if b.plan == null or int(b.plan.f) == f_keep:
		_fail("E did not turn the ghost"); return
	await create_timer(0.6).timeout
	_tag("PLN-1589", "steps 2 E: the ghost turns")
	steps.append(await _grab())
	b._on_key(KEY_BACKSPACE)
	if b.plan == null or int(b.plan.f) != f_keep:
		_fail("Backspace did not turn the ghost back"); return
	await create_timer(0.6).timeout
	_tag("PLN-1589", "steps 3 Backspace: the turn is taken back")
	steps.append(await _grab())
	b._target(picks[1])
	await create_timer(0.6).timeout
	_tag("PLN-1589", "steps 4 the second pick again (%d picks)" % b.aims.size())
	steps.append(await _grab())
	await _save("PLN-1589_steps", steps)
	if b.aims.size() != 2 or b.plan == null:
		_fail("the plan did not come back to the move and two picks"); return
	b._confirm()
	await _save("PLN-1589_commit", await _strip("PLN-1589", "commit: one event", COMMIT_AT))
	await _idle()
	b._end_ship("probe")
	await _save("ENY-1589", await _strip("ENY-1589", "enemy activation", ENEMY_AT))


# --glass: a Glasswright fires, then still moves (the only faction whose firing does not end its movement)
func _glass() -> void:
	var R = b.api.R
	var me = null
	for u in R.alive("player"):
		if not R.jt(u.get("isSq")) and not R.jt(u.get("activated")) and R.canFade(u):
			me = u
			break
	if me == null:
		_fail("no ready Glasswright ship"); return
	var foes: Array = R.alive("enemy")
	var d0: Array = R.DIRS[int(me["facing"])]
	var spot := Vector2i(int(me["q"]) + d0[0] * 3, int(me["r"]) + d0[1] * 3)
	if foes.is_empty() or not R.onBoard(spot.x, spot.y) or R.unitAt(spot.x, spot.y) != null:
		_fail("no free hex ahead for the enemy"); return
	foes[0]["q"] = spot.x
	foes[0]["r"] = spot.y
	_sync()
	var id := str(me["id"])
	var eid := str(foes[0]["id"])
	b.select(id, "pick")
	await _idle()
	b.cam.focus(b._pos(id).lerp(b.board.hex_world(spot.x, spot.y), 0.5), float(_arg("cam", "170")))
	await create_timer(1.2).timeout
	b._target(eid)
	if b.aims.size() != 1:
		_fail("the Glasswright could not aim at the enemy ahead"); return
	await create_timer(0.6).timeout
	var frames: Array = []
	_tag("GLS-1589", "1 Glasswright: the shot planned from where it sits")
	frames.append(await _grab())
	b._confirm()
	await create_timer(1.4).timeout
	_tag("GLS-1589", "2 commit: the shot plays")
	frames.append(await _grab())
	await _idle()
	var after = b.api.unit(id)
	if after == null or not R.jt(after.get("postFire")) or R.postFireMp(after) <= 0 or b.sel != id or b.reach_map.is_empty():
		_fail("no move left after firing (postMp %s, up %s, %d hexes)" % [str(after.get("postMp")) if after != null else "?", b.sel, b.reach_map.size()]); return
	var far = null
	var far_d := -1
	for k in b.reach_map:   # the reach hex farthest from the enemy: the Glasswright slips away after its shot
		var st = b.reach_map[k]
		var dd := int(R.hdist({"q": int(st.q), "r": int(st.r)}, {"q": spot.x, "r": spot.y}))
		if b._unit_at(int(st.q), int(st.r)).is_empty() and dd > far_d:
			far_d = dd
			far = st
	if far == null:
		_fail("no free hex to move to after firing"); return
	b.hover = Vector2i(int(far.q), int(far.r))
	b._on_click()
	b._overlay()
	await create_timer(0.6).timeout
	_tag("GLS-1589", "3 after firing: %d hex move left, planned as a ghost" % R.postFireMp(after))
	frames.append(await _grab())
	b._confirm()
	await create_timer(1.6).timeout
	_tag("GLS-1589", "4 the move after firing plays")
	frames.append(await _grab())
	await _idle()
	var end = b.api.unit(id)
	if end == null or int(end["q"]) != int(far.q) or int(end["r"]) != int(far.r):
		_fail("the Glasswright did not reach the hex planned after firing"); return
	await _save("GLS-1589", frames)


var failed := ""


func _fail(why: String) -> void:
	failed = why
	print("[plan-1589-shots] FAILED: ", why)


func _run() -> void:
	out = _arg("out", "user://plan_commit_1589")
	stage = _arg("stage", "cloud, compatibility renderer")
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	b = scene.instantiate()
	var glass := OS.get_cmdline_user_args().has("--glass")
	if glass:
		b.args = {"fleet": "i_blade,i_song,i_wisp", "admiral": "aelith", "fac": "hegemony", "map": "open"}
	else:
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
	if glass:
		await _glass()
	else:
		await _plan_and_commit()
	await create_timer(1.0).timeout
	for f in (["GLS-1589"] if glass else ["PLN-1589_plan", "PLN-1589_steps", "PLN-1589_commit", "ENY-1589"]):
		if failed == "" and not FileAccess.file_exists(out.path_join(f + ".jpg")):
			_fail("%s.jpg was not written" % f)
	print("[plan-1589-shots] ", "PASS" if failed == "" else "FAILED: " + failed)
	quit(0 if failed == "" else 1)
