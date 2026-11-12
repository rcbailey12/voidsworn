extends SceneTree
# Issue 271, step 1: capture the ember battle screen options on the game's own battle (capture only; nothing here ships).
# Run (the PC job contrib/opus/ui_battle_ember/pc/ember271_shots.bat copies this folder to godot/_ember271/ first):
#   godot --path godot --rendering-method forward_plus --script res://_ember271/ember_shots.gd -- --ember-out OUT --seed 7 --ui-demo --obj ambush --no-tips
# The battle is played to the same moment ui_shots.gd step 5 reaches (a player ship moved to where its guns bear, an enemy
# targeted, the odds up), through the same handlers a player uses. Then, for each layout: the frame with each of the three
# shield colours, the tree prompt in its place, and six backgrounds (the veils with no words, the camera turned through a
# full circle) for the contrast measure. Every word drawn is written to OUT/<layout>_items.json.

const Overlay := preload("res://_ember271/ember_overlay.gd")
const PG := preload("res://render/placeholder_guard.gd")

const SHIELDS := {"S1_cyan": "#3fcbe0", "S2_glacier": "#92b8e8", "S3_verdigris": "#63c3a0"}
const PICK := "S2_glacier"
# the "you may" prompt of issue 529, word for word from PR 533 (data.js TREE_MAY.debtDue); the role prompt takes the same place
const PROMPT := {"n": "Debt Comes Due", "q": "Delay the whole volley to the start of next round? It fires then with +20% damage.",
	"opts": [{"n": "Delay the volley"}, {"n": "Fire it now"}]}
# the part of the screen each layout leaves clear for the two ships (fractions of the window)
const CLEAR := {"E1": Rect2(0.44, 0.22, 0.52, 0.56), "E2": Rect2(0.36, 0.18, 0.28, 0.50), "E3": Rect2(0.26, 0.12, 0.48, 0.48)}

var out := ""
var bt
var us
var ov
var notes: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--ember-out")
	out = a[i + 1] if i >= 0 and i + 1 < a.size() else "user://ember271"
	DirAccess.make_dir_recursive_absolute(out)
	bt = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(bt)
	current_scene = bt
	_run.call_deferred()


func _note(s: String) -> void:
	notes.append(s)
	print("[ember271] ", s)


func _frames(n := 3) -> void:
	for i in n:
		await process_frame


func _snap(name: String) -> void:
	await _frames(2)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var p := out.path_join(name + ".png")
	img.save_png(p)
	_note("saved %s (%dx%d)" % [p, img.get_width(), img.get_height()])


func _run() -> void:
	for i in 4:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
		await process_frame
	_note("window %s, viewport %s" % [str(DisplayServer.window_get_size()), str(root.get_visible_rect().size)])
	while bt.api == null or bt.warming:
		await process_frame
	while bt.opening:
		await process_frame
	us = load("res://ui/battle/ui_shots.gd").new()
	us.name = "EmberHelper"
	us.b = bt
	bt.add_child(us)
	await us._idle()
	await create_timer(2.0).timeout
	if PG.stop_if_any():
		_finish(1)
		return
	# the moment of ui_shots.gd step 5: move to the hex where the most guns bear, then target an enemy the guns reach
	bt._update_reach()
	var best = null
	for key in bt.reach_map:
		var st = bt.reach_map[key]
		if not bt._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		if best == null or int(st.get("guns", 0)) * 100 + int(st.cost) > int(best.get("guns", 0)) * 100 + int(best.cost):
			best = st
	if best != null and int(best.get("guns", 0)) > 0:
		us._hover_hex(int(best.q), int(best.r))
		bt._on_click()
		await us._idle()
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
	bt.cam.glide(bt._pos(t2).lerp(bt._pos(bt.sel), 0.5), 0.3)
	await create_timer(0.9).timeout
	us._hover_hex(int(bt.VU[t2]["q"]), int(bt.VU[t2]["r"]))
	bt._on_click()
	await us._idle()
	us._hover_hex(int(bt.VU[t2]["q"]), int(bt.VU[t2]["r"]))
	bt._refresh_ui()
	await create_timer(0.6).timeout
	_note("moment: %s up, %s targeted (%s), %d guns bear" % [bt._name(bt.sel), bt._name(t2), "ok" if bt.target == t2 else "NOT TARGETED", bt._firing_set(t2).size()])
	# before: today's HUD at this moment
	await _snap("before_lime")
	# the overlay over the scene, the game's HUD hidden; the ring under the ship that is up in ember (lime retired, R191)
	var cl := CanvasLayer.new()
	cl.layer = 60
	root.add_child(cl)
	ov = Overlay.new()
	ov.b = bt
	cl.add_child(ov)
	bt.hud.visible = false
	bt.board.set_hover(-9999, -9999)
	if bt.views.has(bt.sel):
		bt.views[bt.sel].set_selected(true, Color("#ff8a3a"))
	Input.warp_mouse(Vector2(4, 540))
	var cam = bt.cam
	var a0: float = cam.a
	var r0: float = cam.r
	for L in ["E1", "E2", "E3"]:
		cam.a = a0
		cam.r = r0
		_frame(CLEAR[L])
		await _frames(4)
		ov.layout = L
		ov.prompt = {}
		ov.show_text = true
		for sname in SHIELDS:
			ov.shield_col = Color(SHIELDS[sname])
			ov.gather()
			ov.queue_redraw()
			await _snap("%s_%s" % [L, sname])
		ov.shield_col = Color(SHIELDS[PICK])
		ov.queue_redraw()
		await _snap("%s_main" % L)
		var f := FileAccess.open(out.path_join("%s_items.json" % L), FileAccess.WRITE)
		f.store_string(JSON.stringify({"layout": L, "viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "items": ov.items}, "\t"))
		f.close()
		ov.prompt = PROMPT
		ov.queue_redraw()
		await _snap("%s_prompt" % L)
		var fp := FileAccess.open(out.path_join("%s_prompt_items.json" % L), FileAccess.WRITE)
		fp.store_string(JSON.stringify({"layout": L, "items": ov.items}, "\t"))
		fp.close()
		ov.prompt = {}
		# the backgrounds: veils only, the camera turned through a full circle about the same point
		ov.show_text = false
		ov.queue_redraw()
		var aL: float = cam.a
		for i in 6:
			cam.a = aL + TAU * i / 6.0
			cam.snap()
			await _frames(4)
			await _snap("%s_bg%d" % [L, i])
		cam.a = aL
		cam.snap()
	_finish(0)


# put the two ships in the part of the screen the layout leaves clear: zoom so they span about 40% of its width, then pan
# (by a measured two-by-two step, the camera's pan being in board units) until their midpoint sits at its centre
func _frame(clear_f: Rect2) -> void:
	var cam = bt.cam
	var vs: Vector2 = root.get_visible_rect().size
	var clear := Rect2(clear_f.position * vs, clear_f.size * vs)
	var p1: Vector3 = bt._pos(bt.sel)
	var p2: Vector3 = bt._pos(bt.target)
	var mid := (p1 + p2) * 0.5
	cam.t = Vector3(mid.x, 0, mid.z)
	cam.snap()
	for it in 5:
		var d: float = (cam.unproject_position(p1) - cam.unproject_position(p2)).length()
		cam.r = clampf(cam.r * clampf(d / (0.40 * clear.size.x), 0.6, 1.6), 60.0, 420.0)
		cam.snap()
	for it in 6:
		var sp: Vector2 = cam.unproject_position(mid)
		var err := clear.get_center() - sp
		if err.length() < 6.0:
			break
		var t0: Vector3 = cam.t
		cam.pan_by(20, 0)
		cam.snap()
		var jx: Vector2 = (cam.unproject_position(mid) - sp) / 20.0
		cam.t = t0
		cam.pan_by(0, 20)
		cam.snap()
		var jz: Vector2 = (cam.unproject_position(mid) - sp) / 20.0
		cam.t = t0
		var det := jx.x * jz.y - jz.x * jx.y
		if absf(det) < 1e-6:
			break
		var u := (err.x * jz.y - jz.x * err.y) / det
		var v := (jx.x * err.y - err.x * jx.y) / det
		cam.pan_by(u, v)
		cam.snap()
	_note("framed: ships at %s and %s, clear %s" % [str(cam.unproject_position(p1)), str(cam.unproject_position(p2)), str(clear)])


func _finish(code: int) -> void:
	var f := FileAccess.open(out.path_join("ember_log.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(notes)) + "\n")
		f.close()
	quit(code)
