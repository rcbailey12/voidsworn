extends SceneTree
# Issue 271 step 2: before and after pictures of the real battle screen at 1920x1080, three moments, the same steps in
# both builds (nothing here ships). The PC job (contrib/opus/ui_battle_ember/build/build271_shots.bat) copies this folder
# into godot/_build271/ of a clone of main (before, the Lime HUD) and of opus/issue-271-build2 (after, E1 LEDGER):
#   godot --path godot --script res://_build271/build_shots.gd -- --b271-out OUT --b271-tag before|after --seed 7 --ui-demo --obj ambush --no-tips
# Moments, reached through the handlers a player uses (the steps of step 1's capture and ui_shots.gd moment 5):
#   1_target  your turn: the ship moved to where its guns bear, an enemy targeted, the odds up
#   2_prompt  the same moment with the issue 529 "you may" prompt open (Debt Comes Due, PR 533's words); after only
#             (main has no prompt yet; the before is PR 533's own picture)
#   3_enemy   the shot fired, every ship ended, the enemy's turn under way
# The camera: the two ships' midpoint, zoomed so they span about 40% of the part of the screen the HUD leaves clear.
# No panning by hand: the after build's camera shift (camera_rig.gd screen_shift) does its own work.

const PG := preload("res://render/placeholder_guard.gd")
const PROMPT := {"kind": "may", "key": "debtDue", "n": "Debt Comes Due", "q": "Delay the whole volley to the start of next round? It fires then with +20% damage.",
	"opts": [{"id": "yes", "n": "Delay the volley"}, {"id": "no", "n": "Fire it now"}]}

var out := ""
var tag := "after"
var bt
var us
var notes: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--b271-out")
	out = a[i + 1] if i >= 0 and i + 1 < a.size() else "user://b271"
	var j := a.find("--b271-tag")
	tag = a[j + 1] if j >= 0 and j + 1 < a.size() else "after"
	DirAccess.make_dir_recursive_absolute(out)
	bt = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(bt)
	current_scene = bt
	_run.call_deferred()


func _note(s: String) -> void:
	notes.append(s)
	print("[b271] ", s)


func _frames(n := 3) -> void:
	for i in n:
		await process_frame


func _snap(name: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := out.path_join("%s_%s.png" % [tag, name])
	img.save_png(p)
	_note("saved %s (%dx%d)" % [p, img.get_width(), img.get_height()])


func _quiet_pointer() -> void:
	# the pointer off the board (on the HUD's own empty foot), the hovered hex cleared
	bt.board.set_hover(-9999, -9999)
	Input.warp_mouse(Vector2(600, root.get_visible_rect().size.y - 14))
	bt.hud.show_tip("", Vector2.ZERO)


func _clear_w() -> float:
	var vs: Vector2 = root.get_visible_rect().size
	var h = bt.hud
	if h.get("ledger") != null:
		return vs.x - h.ledger.sheet_r.end.x - 40.0
	return vs.x - 262.0 - 452.0


func _zoom_to(p1: Vector3, p2: Vector3) -> void:
	var cam = bt.cam
	var mid := (p1 + p2) * 0.5
	cam.t = Vector3(mid.x, 0, mid.z)
	cam.snap()
	for it in 5:
		var d: float = (cam.unproject_position(p1) - cam.unproject_position(p2)).length()
		cam.r = clampf(cam.r * clampf(d / (0.40 * _clear_w()), 0.6, 1.6), 60.0, 420.0)
		cam.snap()


func _run() -> void:
	for i in 4:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		await process_frame
	_note("%s: window %s, viewport %s" % [tag, str(DisplayServer.window_get_size()), str(root.get_visible_rect().size)])
	while bt.api == null or bt.warming:
		await process_frame
	while bt.opening:
		await process_frame
	us = load("res://ui/battle/ui_shots.gd").new()
	us.name = "B271Helper"
	us.b = bt
	bt.add_child(us)
	await us._idle()
	await create_timer(2.0).timeout
	if PG.stop_if_any():
		_note("FAIL: placeholder hulls on screen; no pictures")
		_finish(1)
		return
	# 1. move to the hex where the most guns bear, then target an enemy the guns reach
	bt._update_reach()
	var best = null
	for key in bt.reach_map:
		var st = bt.reach_map[key]
		if not bt._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		if best == null or int(st.get("guns", 0)) * 100 + int(st.cost) > int(best.get("guns", 0)) * 100 + int(best.cost):
			best = st
	if best != null and int(best.get("guns", 0)) > 0:
		for k in 2:
			us._hover_hex(int(best.q), int(best.r))
			bt._on_click()
			await us._idle()
		await create_timer(0.5).timeout
	var t2 := ""
	for e in bt.V["units"]:
		if e["side"] == "enemy" and not e["dead"] and not bt._firing_set(e["id"]).is_empty():
			t2 = e["id"]
			break
	if t2 == "" or bt.sel == "":
		_note("FAIL: no enemy in reach after the move; no pictures")
		_finish(1)
		return
	us._hover_hex(int(bt.VU[t2]["q"]), int(bt.VU[t2]["r"]))
	bt._on_click()
	await us._idle()
	_zoom_to(bt._pos(bt.sel), bt._pos(t2))
	_quiet_pointer()
	bt._refresh_ui()
	await create_timer(1.6).timeout
	_note("moment 1: %s up, %s targeted (%s), %d guns bear, camera shift %.0f" % [bt._name(bt.sel), bt._name(t2), "ok" if bt.target == t2 else "NOT TARGETED", bt._firing_set(t2).size(), float(bt.cam.get("screen_shift") if bt.cam.get("screen_shift") != null else 0.0)])
	await _snap("1_target")
	# 2. the "you may" prompt in the shot's place (after only)
	if bt.hud.has_method("show_ask"):
		bt.hud.show_ask(PROMPT)
		await create_timer(0.4).timeout
		await _snap("2_prompt")
		bt.hud.hide_ask()
		await create_timer(0.3).timeout
	# 3. fire, end every ship, and catch the enemy's turn
	bt._confirm()
	await us._idle()
	var guard := 0
	while bt.api.phase == "player" and not bt.ended and guard < 30:
		guard += 1
		bt.handed_t = -10.0
		bt._end_ship("space")
		for w in 40:
			await process_frame
			if bt.api.phase != "player":
				break
		await us._idle()
		if bt.api.phase == "player" and bt.sel == "":
			bt._next_ship()
	var t0 := Time.get_ticks_msec()
	while not (bt.api.phase == "enemy" or bt.busy) and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	await create_timer(1.4).timeout
	_quiet_pointer()
	_note("moment 3: phase %s, busy %s, after %d end presses" % [str(bt.api.phase), str(bt.busy), guard])
	await _snap("3_enemy")
	_finish(0)


func _finish(code: int) -> void:
	var f := FileAccess.open(out.path_join("%s_log.txt" % tag), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(notes)) + "\n")
		f.close()
	quit(code)
