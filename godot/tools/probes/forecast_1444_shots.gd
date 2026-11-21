extends SceneTree
# Issue 1444: one picture per forecast at camera 170, each with its code name on it: RAM-1 (armed ram), RAM-2 (armed ram
# whose recoil would kill the ship), BRD-1 (boarding odds on hover), NOVA-1 (nova blast with a friendly ship inside),
# WELL-1 (the Hollow Sun line in a move tip), WING-1 (an Aspect of the Brood flagship's Wings buttons). It plays the real
# battle scene and moves ships in the rules by hand to set each moment up (the models are snapped to match).
# usage (needs a window): godot --path godot --script res://tools/probes/forecast_1444_shots.gd -- --scenario s1
#   --out <folder> [--items RAM-1,BRD-1] [--quality low] [--stage "cloud, compatibility renderer"]
# WELL-1 needs a dead-star board: run it again with --scenario s19 --items WELL-1.

var b
const ShipViewS := preload("res://render/ship_view.gd")
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


func _snap(code: String, what: String) -> void:
	label.text = "%s   %s   (1444 r1, %s)" % [code, what, stage]
	await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	if img.get_height() > 720:
		img.resize(int(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var p := out.path_join("%s.jpg" % code)
	preload("res://tools/picture_provenance.gd").save_jpg(img, p, 0.9, stage)   # the shared stamp
	print("[forecast-shots] ", p)


func _hover_hex(q: int, r: int) -> void:
	var p: Vector2 = b.cam.unproject_position(b.board.hex_world(q, r))
	root.get_viewport().warp_mouse(p)
	b._on_hover(p)
	b.hud.show_tip(b._tip(), p)


func _look(id: String, at = null) -> void:
	b.cam.focus(b._pos(id) if at == null else at, 170.0)
	await create_timer(1.0).timeout


# a player ship and an enemy with two free hexes between them, dead ahead
func _ram_fixture() -> Array:
	var R = b.api.R
	for me in R.alive("player"):
		if R.jt(me.get("isSq")): continue
		for f in 6:
			var d: Array = R.DIRS[f]
			var line := []
			for i in range(1, 4): line.append(Vector2i(int(me["q"]) + d[0] * i, int(me["r"]) + d[1] * i))
			var foe = null
			for e in R.alive("enemy"):
				if not R.jt(e.get("isSq")): foe = e; break
			if foe == null: return []
			if line.all(func(h): return _free(h.x, h.y, [foe])):
				me["facing"] = f
				foe["q"] = line[2].x; foe["r"] = line[2].y
				return [me, foe]
	return []


func _select(id: String) -> void:
	b.select(id, "pick")
	_sync()
	await _idle()


func _ram(lethal: bool) -> void:
	var fx := _ram_fixture()
	if fx.is_empty():
		print("[forecast-shots] no ram line found"); return
	var me: Dictionary = fx[0]
	if lethal:
		var rm0 = b.api.ui_info(me["id"]).get("ram")
		if rm0 is Dictionary:
			me["hp"] = maxf(1.0, float(rm0["recoil"]) - 2.0)
			if b.disp.has(me["id"]): b.disp[me["id"]]["hp"] = me["hp"]   # the panel shows the same hull
	await _select(me["id"])
	b._on_action("ram", null)
	await _look(me["id"])
	_hover_hex(int(fx[1]["q"]), int(fx[1]["r"]))
	b._refresh_ui()
	await create_timer(0.4).timeout
	await _snap("RAM-2" if lethal else "RAM-1", "lethal recoil warning" if lethal else "armed ram: run, target, damage, recoil")
	b._on_key(KEY_ESCAPE)


func _board() -> void:
	var R = b.api.R
	for me in R.alive("player"):
		if R.jt(me.get("isSq")) or not R.jt(me.get("crewMax")): continue
		for d in R.DIRS:
			var q := int(me["q"]) + int(d[0]); var r := int(me["r"]) + int(d[1])
			if not _free(q, r): continue
			var foe = null
			for e in R.alive("enemy"):
				if not R.jt(e.get("isSq")): foe = e; break
			foe["q"] = q; foe["r"] = r
			await _select(me["id"])
			b._on_action("board", null)
			await _look(me["id"])
			_hover_hex(q, r)
			await create_timer(0.4).timeout
			await _snap("BRD-1", "boarding odds on hover")
			b._on_key(KEY_ESCAPE)
			return


func _nova() -> void:
	var R = b.api.R
	var mine: Array = R.alive("player").filter(func(x): return not R.jt(x.get("isSq")))
	var me: Dictionary = mine[0]
	var pal: Dictionary = mine[1]
	me["ab"] = "nova"; me["abCd"] = 0
	await _select(me["id"])
	b._on_action("ability", null)
	var hs: Array = b._ability_hexes()
	for h in hs:
		var c := Vector2i(int(h["q"]), int(h["r"]))
		if _hd(c, Vector2i(int(me["q"]), int(me["r"]))) != 4 or not _free(c.x + 1, c.y): continue
		pal["q"] = c.x + 1; pal["r"] = c.y
		for e in R.alive("enemy"):
			if not R.jt(e.get("isSq")) and _free(c.x, c.y): e["q"] = c.x; e["r"] = c.y; break
		_sync()
		await _idle()
		b.mode = "nova"
		await _look(me["id"], b.board.hex_world(c.x, c.y).lerp(b._pos(me["id"]), 0.5))
		_hover_hex(c.x, c.y)
		b._overlay()
		await create_timer(0.4).timeout
		await _snap("NOVA-1", "nova blast, friendly ship inside")
		b._on_key(KEY_ESCAPE)
		return


func _hd(a: Vector2i, c: Vector2i) -> int:
	return int((absi(a.x - c.x) + absi(a.x + a.y - c.x - c.y) + absi(a.y - c.y)) / 2)


func _well() -> void:
	var R = b.api.R
	var W = R.B.get("well")
	if not W is Dictionary:
		print("[forecast-shots] WELL-1 needs a dead-star board (--scenario s19)"); return
	var me = null
	for x in R.alive("player"):
		if not R.jt(x.get("isSq")): me = x; break
	await _select(me["id"])
	b._update_reach()
	var best = null; var bd := 99
	for k in b.reach_map:
		var st = b.reach_map[k]
		var d := _hd(Vector2i(int(st.q), int(st.r)), Vector2i(int(W["q"]), int(W["r"])))
		if d <= int(R.WELL_PULL) and d > int(R.WELL_RIM) and d < bd and b._unit_at(int(st.q), int(st.r)).is_empty(): best = st; bd = d
	if best == null:
		# bring the ship within reach of the pull band
		for h in R.boardHexes():
			var d := _hd(Vector2i(int(h.q), int(h.r)), Vector2i(int(W["q"]), int(W["r"])))
			if d == int(R.WELL_ASSIST) + 1 and _free(int(h.q), int(h.r)): me["q"] = int(h.q); me["r"] = int(h.r); break
		await _select(me["id"])
		await _well_again(W)
		return
	await _look(me["id"])
	_hover_hex(int(best.q), int(best.r))
	await create_timer(0.4).timeout
	await _snap("WELL-1", "Hollow Sun line in the move tip")


func _well_again(W) -> void:
	var R = b.api.R
	b._update_reach()
	for k in b.reach_map:
		var st = b.reach_map[k]
		var d := _hd(Vector2i(int(st.q), int(st.r)), Vector2i(int(W["q"]), int(W["r"])))
		if d <= int(R.WELL_ASSIST) and b._unit_at(int(st.q), int(st.r)).is_empty():
			await _look(b.sel)
			_hover_hex(int(st.q), int(st.r))
			await create_timer(0.4).timeout
			await _snap("WELL-1", "Hollow Sun line in the move tip")
			return


func _wing() -> void:
	var R = b.api.R
	var me = null
	for x in R.alive("player"):
		if not R.jt(x.get("isSq")) and x.get("ab") != "launch": me = x; break
	me["ab"] = null
	if not me.get("fx") is Dictionary: me["fx"] = {}
	me["fx"]["hive"] = 1
	await _select(me["id"])
	await _look(me["id"])
	b.hud.show_tip("", Vector2.ZERO)
	b._refresh_ui()
	await create_timer(0.4).timeout
	await _snap("WING-1", "Brood flagship: Wings buttons")


func _run() -> void:
	out = _arg("out", "user://forecast_1444")
	stage = _arg("stage", "cloud, compatibility renderer")
	DirAccess.make_dir_recursive_absolute(out)
	var scene: PackedScene = load("res://scenes/battle/battle.tscn")
	b = scene.instantiate()
	root.add_child(b)
	var cl := CanvasLayer.new(); cl.layer = 120; root.add_child(cl)
	label = Label.new(); label.position = Vector2(560, 14)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	cl.add_child(label)
	while b.api == null or b.V.is_empty():
		await process_frame
	await create_timer(2.5).timeout
	await _idle()
	var items := _arg("items", "RAM-1,RAM-2,BRD-1,NOVA-1,WING-1").split(",")
	for it in items:
		match it:
			"RAM-1": await _ram(false)
			"RAM-2": await _ram(true)
			"BRD-1": await _board()
			"NOVA-1": await _nova()
			"WELL-1": await _well()
			"WING-1": await _wing()
		await _idle()
	quit(0)
