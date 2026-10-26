extends Control
# The sector map (G3): nodes and jump lines drawn the way campaign_run.js mapScreen draws its SVG (900 x 450 layout units,
# column x = 60 + 130 * col, row y = 34 + 380 * y), scaled to fit. Reachable nodes pulse; hover shows the node's details;
# click, or Tab / arrows and Enter, jumps there (campaign.act("enterNode", id)).

var ui                     # campaign_ui.gd (colours, fonts, the campaign)
var _hot := ""             # node under the mouse
var _focus_i := 0          # keyboard focus among the reachable nodes
var _t := 0.0

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	_t += delta; queue_redraw()

func _xf() -> Array: # [scale, offset]
	var sx = size.x / 900.0; var sy = size.y / 450.0; var s = min(sx, sy)
	return [s, Vector2((size.x - 900.0 * s) * 0.5, (size.y - 450.0 * s) * 0.5)]
func _pos(n: Dictionary) -> Vector2:
	var x = _xf()
	return x[1] + Vector2(60.0 + float(n["col"]) * 130.0, 34.0 + float(n["y"]) * 380.0) * x[0]
func _nodes() -> Array: return ui.C._nodes()
func _avail() -> Array: return ui.C.page["data"]["avail"] if ui.C.page["kind"] == "map" else []
func _rad(n) -> float: return (26.0 if n["type"] == "boss" else 19.0) * _xf()[0]

func _draw() -> void:
	var C = ui.C
	if C == null or C.RUN == null or C.page["kind"] != "map": return
	var R = C.RUN; var by = {}
	for n in _nodes(): by[n["id"]] = n
	var avail = _avail(); var s = _xf()[0]
	for e in R["map"]["edges"]:
		var A = by[e[0]]; var Bn = by[e[1]]
		var trav = C.jt(A.get("done")) and (C.jt(Bn.get("done")) or R.get("pos") == e[1])
		var nxt = R.get("pos") == e[0] and avail.has(e[1])
		var col = ui.GILT if trav else (Color(ui.GILT, 0.55) if nxt else Color(ui.BONE, 0.13))
		if nxt: draw_dashed_line(_pos(A), _pos(Bn), col, 2.0 * s, 6.0 * s)
		else: draw_line(_pos(A), _pos(Bn), col, (3.0 if trav else 2.0) * s, true)
	var f = ui.font; var fs = int(12.5 * s)
	for n in _nodes():
		var p = _pos(n); var r = _rad(n); var av = avail.has(n["id"]); var cur = R.get("pos") == n["id"]; var done = C.jt(n.get("done"))
		var col = Color("#7d7768") if done else (Color("#e07a70") if (n["type"] == "elite" or n["type"] == "boss") else (ui.BONE if av else Color("#8a8474")))
		draw_circle(p, r, Color("#1b2436") if done else Color("#182133"))
		var ring = ui.GILT if cur else (Color(ui.GILT, 0.8) if av else Color(ui.BONE, 0.18))
		draw_arc(p, r, 0, TAU, 48, ring, (2.5 if (cur or av) else 1.5) * s, true)
		if av:
			var pr = r + (6.0 + 3.0 * sin(_t * TAU / 2.4)) * s
			draw_arc(p, pr, 0, TAU, 48, Color(ui.GILT, 0.35), 1.0 * s, true)
			if _hot == n["id"] or (has_focus() and _focus_id() == n["id"]): draw_arc(p, r + 3.0 * s, 0, TAU, 48, ui.GILT, 2.0 * s, true)
		_icon(n["type"], p, col, s)
		var below = p.y + r + 15.0 * s
		if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]) and not done:
			var t = str(C.ENCOUNTERS[n["enc"]]["n"]) + ((" · " + str(C.NODE_MODS[n["mod"]]["short"])) if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]) else "")
			_text(t, Vector2(p.x, below), fs, ui.BONE if av else Color("#8a8474")); below += 14.0 * s
		if C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]) and not done and (n["type"] == "battle" or n["type"] == "elite" or n["type"] == "boss"):
			_text(str(C.MAP_NAME[n["map"]]), Vector2(p.x, p.y - r - 7.0 * s), int(10.5 * s), Color("#7f8fa6"))
		if not done and C.nemNodeIs(n): _text("Nemesis", Vector2(p.x, p.y - r - 20.0 * s), int(12 * s), Color("#ff6b5a"))   # B4
		var rw = n.get("rw")
		if rw is Dictionary and not done:
			if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")):
				var P = C.PATRONS[rw["p"]]; var pc = Color(P["col"]); var bp = p + Vector2(r * 0.78, -r * 0.78)
				draw_circle(bp, 10.0 * s, pc); draw_arc(bp, 10.0 * s, 0, TAU, 24, ui.INK, 2.0 * s, true)
				_text(str(P["glyph"]), bp + Vector2(0, 4.5 * s), int(12.5 * s), ui.INK, ui.font_semi)
				_text(str(P["short"]) + (" ★" if C.jt(rw.get("min")) else ""), Vector2(p.x, below), int(11.5 * s), pc if av else Color("#8a8474"))
			else:
				var lab = ui._reward_label(rw)
				if lab != "": _text(lab, Vector2(p.x, below), int(11.5 * s), Color("#bfb6a0") if av else Color("#6f6a5e"))
func _text(t: String, at: Vector2, size: int, col: Color, fnt: Font = null) -> void:
	var f = fnt if fnt != null else ui.font
	var w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(f, Vector2(at.x - w * 0.5, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
func _icon(type: String, p: Vector2, col: Color, s: float) -> void:
	var w = 2.2 * s
	var L = func(a: Vector2, b: Vector2): draw_line(p + a * s, p + b * s, col, w, true)
	match type:
		"battle":
			L.call(Vector2(-7, -7), Vector2(7, 7)); L.call(Vector2(7, -7), Vector2(-7, 7)); L.call(Vector2(-8, 3), Vector2(-3, 8)); L.call(Vector2(8, 3), Vector2(3, 8))
		"elite":
			L.call(Vector2(-7, -7), Vector2(7, 7)); L.call(Vector2(7, -7), Vector2(-7, 7))
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -12) * s, p + Vector2(3, -8) * s, p + Vector2(-3, -8) * s]), col)
		"shipyard":
			var pts = [Vector2(-8, -2), Vector2(2, -2), Vector2(2, -6), Vector2(6, -6), Vector2(6, 6), Vector2(2, 6), Vector2(2, 2), Vector2(-8, 2), Vector2(-8, -2)]
			for i in range(pts.size() - 1): L.call(pts[i], pts[i + 1])
			L.call(Vector2(-2, 6), Vector2(-2, 10))
		"drydock":
			L.call(Vector2(0, -8), Vector2(0, 8)); L.call(Vector2(-8, 0), Vector2(8, 0))
		"event":
			_text("?", p + Vector2(0, 6.5 * s), int(18 * s), col, ui.font_semi)
		"field":
			L.call(Vector2(-7, 7), Vector2(2, -2)); draw_arc(p + Vector2(4.5, -4.5) * s, 5.5 * s, PI * 0.25, PI * 1.85, 16, col, w, true)
		"boss":
			var cr = PackedVector2Array([p + Vector2(-11, 6) * s, p + Vector2(-13, -6) * s, p + Vector2(-6, 0) * s, p + Vector2(0, -9) * s, p + Vector2(6, 0) * s, p + Vector2(13, -6) * s, p + Vector2(11, 6) * s])
			draw_colored_polygon(cr, Color(col, 0.25))
			var cl = cr.duplicate(); cl.append(cr[0]); draw_polyline(cl, col, w, true)

func _node_at(pos: Vector2) -> String:
	for n in _nodes():
		if pos.distance_to(_pos(n)) <= _rad(n) + 6.0 * _xf()[0]: return n["id"]
	return ""
func _get_tooltip(at: Vector2) -> String:
	var id = _node_at(at)
	if id == "": return ""
	var C = ui.C; var n = C.findNode(id); var I = C.NODE_INFO[n["type"]]
	var fight = n["type"] == "battle" or n["type"] == "elite" or n["type"] == "boss"
	var t = str(I["n"]) + ((" (" + str(C.MAP_NAME[n["map"]]) + ")") if C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]) and fight else "") + ": "
	t += (str(C.ENCOUNTERS[n["enc"]]["n"]) + ". " + str(C.ENCOUNTERS[n["enc"]]["d"])) if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]) else str(I["d"])
	if fight:
		var al = ui._arch_label(n, C.nodeFaction(n))
		if al != "": t += " " + al + "."
	if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): t += " " + str(C.NODE_MODS[n["mod"]]["n"]) + ": " + str(C.NODE_MODS[n["mod"]]["d"])
	return t
func _focus_id() -> String:
	var av = _avail()
	return av[_focus_i % av.size()] if av.size() > 0 else ""
func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var h = _node_at(e.position)
		if h != _hot:
			_hot = h; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _avail().has(h) else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id = _node_at(e.position)
		if id != "" and _avail().has(id): ui.C.act("enterNode", id); accept_event()
	elif e is InputEventKey and e.pressed:
		var av = _avail()
		if av.is_empty(): return
		if e.keycode in [KEY_RIGHT, KEY_DOWN]: _focus_i = (_focus_i + 1) % av.size(); accept_event()
		elif e.keycode in [KEY_LEFT, KEY_UP]: _focus_i = (_focus_i - 1 + av.size()) % av.size(); accept_event()
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: ui.C.act("enterNode", _focus_id()); accept_event()
