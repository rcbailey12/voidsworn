extends SceneTree
# Issue 1524: one picture per close action, each a strip of four moments with its code name on it, in the real battle
# scene: RAM-1524 (a player ship rams an enemy dead ahead) and BRD-1524 (a player ship boards an enemy next to it).
# Run it on the commit before the wiring and on the commit after, with --arm before|after, for a before and after.
# The ram's moments are timed from the rules hit landing (the target's drawn hull drops); the boarding's from the command.
# usage (needs a window): godot --path godot --script res://tools/probes/close_action_1524_shots.gd -- --scenario s1
#   --out <folder> --arm before|after [--items RAM,BRD] [--cam 110] [--stage "PC, installed in game"]

var b
const ShipViewS := preload("res://render/ship_view.gd")
const RAM_AT := [0.05, 0.3, 0.7, 1.4]    # seconds after the ram lands
const BRD_AT := [0.3, 0.8, 1.6, 2.8]     # seconds after the boarding command
var out := ""
var stage := ""
var arm := ""
var label: Label


func _initialize() -> void:
	_run.call_deferred()


func _arg(k: String, d := "") -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--" + k)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else d


func _idle() -> void:
	var t0 := Time.get_ticks_msec()
	while b.busy or b.warming or b._threat_busy or b.thinking:
		await process_frame
		if Time.get_ticks_msec() - t0 > 60000:
			break
	for i in 4:
		await process_frame


func _free(q: int, r: int, skip := []) -> bool:
	var R = b.api.R
	if not R.onBoard(q, r) or R.blocks(R.terr(q, r)):
		return false
	var o = R.unitAt(q, r)
	return o == null or o in skip


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


# four frames in a 2 by 2 strip, no taller than 720 px
func _save(code: String, frames: Array) -> void:
	if frames.size() < 4:
		print("[close-action-shots] %s: only %d frames" % [code, frames.size()])
		return
	var w: int = (frames[0] as Image).get_width()
	var h: int = (frames[0] as Image).get_height()
	var sheet := Image.create(w * 2, h * 2, false, (frames[0] as Image).get_format())
	for i in 4:
		sheet.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i((i % 2) * w, (i / 2) * h))
	if sheet.get_height() > 720:
		sheet.resize(int(sheet.get_width() * 720.0 / sheet.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var p := out.path_join("%s_%s.jpg" % [code, arm])
	preload("res://tools/picture_provenance.gd").save_jpg(sheet, p, 0.9)
	print("[close-action-shots] ", p)


func _tag(code: String, what: String, t: float) -> void:
	label.text = "%s %s   %s +%.2f s   (1524 r1, %s)" % [code, arm, what, t, stage]


func _look(at: Vector3) -> void:
	b.cam.focus(at, float(_arg("cam", "110")))
	await create_timer(1.0).timeout


func _first_ship(side: String) -> Variant:
	var R = b.api.R
	for x in R.alive(side):
		if not R.jt(x.get("isSq")):
			return x
	return null


# a player ship and an enemy with two free hexes between them, dead ahead (the 1444 ram fixture)
func _ram_fixture() -> Array:
	var R = b.api.R
	var foe: Variant = _first_ship("enemy")
	if foe == null:
		return []
	for me in R.alive("player"):
		if R.jt(me.get("isSq")): continue
		for f in 6:
			var d: Array = R.DIRS[f]
			var line := []
			for i in range(1, 4): line.append(Vector2i(int(me["q"]) + d[0] * i, int(me["r"]) + d[1] * i))
			if line.all(func(hx): return _free(hx.x, hx.y, [foe])):
				me["facing"] = f
				foe["q"] = line[2].x; foe["r"] = line[2].y
				return [me, foe]
	return []


func _ram() -> void:
	var fx := _ram_fixture()
	if fx.is_empty():
		print("[close-action-shots] RAM: no ram line found"); return
	var me: Dictionary = fx[0]
	var foe: Dictionary = fx[1]
	b.select(me["id"], "pick")
	_sync()
	await _idle()
	if not (b.api.ui_info(me["id"]).get("ram") is Dictionary):
		print("[close-action-shots] RAM: the rules offer no ram here"); return
	await _look(b._pos(foe["id"]).lerp(b._pos(me["id"]), 0.25))
	var hp0 := float(b.disp.get(foe["id"], {}).get("hp", 0.0))
	b._ram_press()
	b._ram_press()   # the second press commits the armed ram
	var t0 := Time.get_ticks_msec()
	while float(b.disp.get(foe["id"], {}).get("hp", 0.0)) >= hp0 and Time.get_ticks_msec() - t0 < 15000:
		await process_frame
	var land := Time.get_ticks_msec()
	var frames: Array = []
	for t in RAM_AT:
		while (Time.get_ticks_msec() - land) / 1000.0 < float(t):
			await process_frame
		_tag("RAM-1524", "ram lands", float(t))
		frames.append(await _grab())
	await _save("RAM-1524", frames)


func _board() -> void:
	var R = b.api.R
	var foe: Variant = _first_ship("enemy")
	for me in R.alive("player"):
		if R.jt(me.get("isSq")) or not R.jt(me.get("crewMax")) or me["activated"]: continue
		for d in R.DIRS:
			var q := int(me["q"]) + int(d[0]); var r := int(me["r"]) + int(d[1])
			if not _free(q, r, [foe]): continue
			foe["q"] = q; foe["r"] = r
			b.select(me["id"], "pick")
			_sync()
			await _idle()
			await _look(b._pos(foe["id"]).lerp(b._pos(me["id"]), 0.3))
			var id: String = me["id"]
			var tid: String = foe["id"]
			if not b._cmd(func(): return b.api.board(id, tid)):
				print("[close-action-shots] BRD: the rules refused the boarding"); return
			var t0 := Time.get_ticks_msec()
			var frames: Array = []
			for t in BRD_AT:
				while (Time.get_ticks_msec() - t0) / 1000.0 < float(t):
					await process_frame
				_tag("BRD-1524", "boarding", float(t))
				frames.append(await _grab())
			await _save("BRD-1524", frames)
			return
	print("[close-action-shots] BRD: no ship with boarders found")


func _run() -> void:
	out = _arg("out", "user://close_action_1524")
	stage = _arg("stage", "cloud, compatibility renderer")
	arm = _arg("arm", "after")
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	b = scene.instantiate()
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
	for it in _arg("items", "RAM,BRD").split(","):
		match it:
			"RAM": await _ram()
			"BRD": await _board()
		await _idle()
		await create_timer(1.0).timeout
	quit(0)
