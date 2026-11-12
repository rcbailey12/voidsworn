extends Control
# Issue 271, step 1: the battle screen in the ember orders-sheet look, as a capture-only overlay (nothing here ships).
# The capture job copies this folder into godot/_ember271/ of its own clone; ember_shots.gd hides the game's HUD and draws
# this over the real battle. Every word and figure is read from the battle at the moment of the capture (the HUD's own
# data: battle.gd _panel_info, _target_info, the fleet rows, the log), never typed in.
#
# The look (contrib/opus/briefs/campaign_rail_orders_sheet.md): no panels, words on a darkened edge of the scene, one large
# focus, the Hollow Sun's ember the one accent; Big Shoulders Display for names, Barlow for sentences, Azeret Mono for figures;
# square corners, no glows, no badges. Three layouts of that one look:
#   E1 LEDGER   the map's rail carried over: one left sheet holds the ship, its guns, the shot and the orders
#   E2 CROSSING yours on the left edge, theirs on the right edge, the shot between them at the foot
#   E3 FOOTING  one band along the bottom, the scene open above it
# Every drawn word is recorded in `items` (rect, size, colour, face) for the readability checks.

const GS := preload("res://ui/theme/glass_shell.gd")

const EMBER := Color("#ff8a3a")
const TEXT := Color("#f0eade")
const TEXT2 := Color("#c4beb0")
const TEXT3 := Color("#969084")
const NEM := Color("#ff6050")
const HAIR := Color("#48443c")
const DMG := Color("#ff5530")          # the game's existing hull damage colour (glass_shell HULL_LOW)
const HALO := Color("#070907")

var b                                   # the battle (scenes/battle/battle.gd)
var layout := "E1"
var shield_col := Color("#92b8e8")
var show_text := true                   # false: the veils only (the backgrounds the contrast is measured on)
var prompt := {}                        # a tree prompt (issue 529) drawn in its place, or {}
var items: Array = []                   # every word drawn: {t, x, y, w, h, size, face, col, role}
var D := {}                             # the data of the moment (gather())
var k := 1.0

var f_name: Font
var f_body: Font
var f_med: Font
var f_num: Font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	f_name = GS.sheet_name()
	f_body = GS.sheet_body()
	f_med = GS.sheet_medium()
	f_num = GS.num()


# ---------------------------------------------------------------- the data of the moment (read only)

static func _plain(s: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(s, "", true).strip_edges()


func gather() -> void:
	D = {}
	var hud = b.hud
	var P: Dictionary = hud._panel_info if hud._panel_info is Dictionary else {}
	D["ship"] = P
	D["target"] = b._target_info()
	D["rows"] = hud._rows
	D["card"] = hud._card_info if hud.get("_card_info") is Dictionary else {}
	D["round"] = int(b.V.get("round", 1))
	D["objective"] = _plain(str(b._objective()))
	D["info"] = b._battle_info()
	D["nem"] = b._nem_info()
	D["cmd"] = str(b._command_label())
	D["cmd_ready"] = b.api.has_method("can_command") and b.api.can_command()
	var pend := 0
	var tot := 0
	for r in D["rows"]:
		if str(r.get("status", "")) != "Lost":
			tot += 1
		if str(r.get("status", "")) in ["Ready", "Up", "Acting"]:
			pend += 1
	D["pend"] = pend
	D["tot"] = tot
	var lines: Array = []
	for l in str(hud.log_text.get_parsed_text()).split("\n"):
		var s := l.strip_edges()
		if s != "":
			# the HUD writes "R1  text": keep the text, the round is in the top line
			var re := RegEx.new()
			re.compile("^R\\d+\\s+")
			lines.append(re.sub(s, ""))
	D["log"] = lines.slice(maxi(0, lines.size() - 3))
	# the armed or best bearing gun and its odds
	var best := {}
	for w in P.get("weapons", []):
		if int(w.get("hit", -1)) < 0:
			continue
		if bool(w.get("armed", false)):
			best = w
			break
		if best.is_empty() or int(w["hit"]) > int(best["hit"]):
			best = w
	D["gun"] = best


# ---------------------------------------------------------------- drawing pieces

func px(v: float) -> float:
	return round(v * k)


# a word or line at (x, y top); align 0 left, 1 right (x is the right edge), 2 centre. Returns its width.
func t(x: float, y: float, s: String, f: Font, size: float, col: Color, align := 0, role := "") -> float:
	if s == "":
		return 0.0
	var fs := int(px(size))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x0 := x if align == 0 else (x - w if align == 1 else x - w * 0.5)
	var asc := f.get_ascent(fs)
	if show_text:
		draw_string(f, Vector2(x0, y + asc), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	items.append({"t": s, "x": x0, "y": y, "w": w, "h": asc + f.get_descent(fs), "size": size, "face": _face(f), "col": col.to_html(false), "role": role})
	return w


# words on the board itself (ship tags): with the map's dark halo
func th(x: float, y: float, s: String, f: Font, size: float, col: Color) -> float:
	var fs := int(px(size))
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x0 := x - w * 0.5
	if show_text:
		GS.halo_text(self, f, Vector2(x0, y + f.get_ascent(fs)), s, fs, col, k)
	items.append({"t": s, "x": x0, "y": y, "w": w, "h": f.get_ascent(fs) + f.get_descent(fs), "size": size, "face": _face(f), "col": col.to_html(false), "role": "tag"})
	return w


func _face(f: Font) -> String:
	if f == f_name:
		return "BigShoulders"
	if f == f_num:
		return "AzeretMono"
	if f == f_med:
		return "Barlow Medium"
	return "Barlow"


# a name in Big Shoulders capitals, shrunk to fit the width (never below 28)
func name_fit(x: float, y: float, s: String, size: float, maxw: float, col: Color, align := 0) -> float:
	var u := s.to_upper()
	var fs := size
	while fs > 28 and f_name.get_string_size(u, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(fs))).x > maxw:
		fs -= 1
	t(x, y, u, f_name, fs, col, align, "name")
	return fs


# a sentence wrapped to a width; returns the height used
func para(x: float, y: float, s: String, f: Font, size: float, col: Color, maxw: float, lh := 1.3, align := 0) -> float:
	var words := s.split(" ")
	var line := ""
	var yy := y
	var fs := int(px(size))
	for wd in words:
		var tryl := wd if line == "" else line + " " + wd
		if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw and line != "":
			t(x, yy, line, f, size, col, align)
			yy += px(size * lh)
			line = wd
		else:
			line = tryl
	if line != "":
		t(x, yy, line, f, size, col, align)
		yy += px(size * lh)
	return yy - y


func hair(x0: float, x1: float, y: float) -> void:
	draw_line(Vector2(x0, y), Vector2(x1, y), HAIR, maxf(1.0, px(1)))


# one smooth veil, never a panel. dir: "l" from the left edge, "r" from the right, "b" from the bottom, "t" from the top.
# reach is where it fades to nothing; the words sit in the first 72%, where it is full.
func veil(dir: String, reach: float, a0 := 0.94, along0 := 0.0, along1 := -1.0) -> void:
	var vs := size
	if along1 < 0:
		along1 = vs.y if dir in ["l", "r"] else vs.x
	var stops := [[0.0, a0 + 0.02], [0.72, a0], [1.0, 0.0]]
	for i in 2:
		var s0: Array = stops[i]
		var s1: Array = stops[i + 1]
		var c0 := Color(0, 0, 0, s0[1])
		var c1 := Color(0, 0, 0, s1[1])
		var p0: float = reach * s0[0]
		var p1: float = reach * s1[0]
		var pts: PackedVector2Array
		match dir:
			"l":
				pts = PackedVector2Array([Vector2(p0, along0), Vector2(p1, along0), Vector2(p1, along1), Vector2(p0, along1)])
			"r":
				pts = PackedVector2Array([Vector2(vs.x - p0, along0), Vector2(vs.x - p1, along0), Vector2(vs.x - p1, along1), Vector2(vs.x - p0, along1)])
			"b":
				pts = PackedVector2Array([Vector2(along0, vs.y - p0), Vector2(along0, vs.y - p1), Vector2(along1, vs.y - p1), Vector2(along1, vs.y - p0)])
			"t":
				pts = PackedVector2Array([Vector2(along0, p0), Vector2(along0, p1), Vector2(along1, p1), Vector2(along1, p0)])
		draw_polygon(pts, PackedColorArray([c0, c1, c1, c0]))


# a soft dark corner: darkest at the screen corner (cx, cy), fading smoothly over rx across and ry down (or up); a grid of
# quads with the alpha at each vertex, so there is no edge or disc to see
func corner(cx: float, cy: float, rx: float, ry: float, a := 0.9) -> void:
	var nx := 24
	var ny := 14
	var sx := -1.0 if cx > size.x * 0.5 else 1.0
	var sy := -1.0 if cy > size.y * 0.5 else 1.0
	var al := func(u: float, v: float) -> float:
		var fu := clampf((1.0 - u) * 2.2, 0.0, 1.0)
		var fv := clampf((1.0 - v) * 2.2, 0.0, 1.0)
		return a * fu * fu * (3.0 - 2.0 * fu) * fv * fv * (3.0 - 2.0 * fv)
	for i in nx:
		for j in ny:
			var u0 := float(i) / nx
			var u1 := float(i + 1) / nx
			var v0 := float(j) / ny
			var v1 := float(j + 1) / ny
			var pts := PackedVector2Array([Vector2(cx + sx * u0 * rx, cy + sy * v0 * ry), Vector2(cx + sx * u1 * rx, cy + sy * v0 * ry),
				Vector2(cx + sx * u1 * rx, cy + sy * v1 * ry), Vector2(cx + sx * u0 * rx, cy + sy * v1 * ry)])
			var cols := PackedColorArray([Color(0, 0, 0, al.call(u0, v0)), Color(0, 0, 0, al.call(u1, v0)), Color(0, 0, 0, al.call(u1, v1)), Color(0, 0, 0, al.call(u0, v1))])
			draw_polygon(pts, cols)


func diamond(c: Vector2, r: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


# the ship seen from above with its four shield facings: prow up, rear down, port left, starboard right. The figure of
# each facing beside its arc; the arc's lit share is the facing's charge. Shield colour is used for nothing else.
func shield_plan(c: Vector2, sh: Array, shmax: float, scale := 1.0, big := true) -> Vector2:
	var s := px(scale)
	var hull := PackedVector2Array([Vector2(0, -24), Vector2(8, -10), Vector2(8, 18), Vector2(-8, 18), Vector2(-8, -10), Vector2(0, -24)])
	for i in hull.size():
		hull[i] = c + hull[i] * s
	draw_polyline(hull, TEXT3, maxf(1.0, px(1.5)))
	var R := 34.0 * s
	var lw := maxf(2.0, px(3))
	var mids := [-PI / 2, 0.0, PI / 2, PI]   # prow, starboard, rear, port (screen angles, y down)
	var fs := 19.0 if big else 17.0
	for q in 4:
		var v := float(sh[q]) if q < sh.size() else 0.0
		var f := clampf(v / maxf(shmax, 1.0), 0.0, 1.0)
		var a0: float = mids[q] - 0.62
		var a1: float = mids[q] + 0.62
		draw_arc(c, R, a0, a1, 16, Color(TEXT3, 0.45), lw)
		if f > 0.0:
			var am: float = mids[q]
			draw_arc(c, R, am - 0.62 * f, am + 0.62 * f, 16, shield_col, lw)
		var label := str(int(round(v)))
		var col := shield_col if v > 0.5 else TEXT2
		var fsz := int(px(fs))
		var w := f_num.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var hgt := f_num.get_ascent(fsz)
		match q:
			0: t(c.x, c.y - R - px(8) - hgt, label, f_num, fs, col, 2, "shield")
			1: t(c.x + R + px(8), c.y - hgt * 0.5, label, f_num, fs, col, 0, "shield")
			2: t(c.x, c.y + R + px(6), label, f_num, fs, col, 2, "shield")
			3: t(c.x - R - px(8), c.y - hgt * 0.5, label, f_num, fs, col, 1, "shield")
	return Vector2(2 * R + px(70), 2 * R + px(60))


# hull as figures: "135 / 135", the first in the damage colour when hurt
func hull_fig(x: float, y: float, hp: float, mx: float, size := 26.0, align := 0, word := true) -> float:
	var a := str(int(round(hp)))
	var bb := " / %d" % int(round(mx))
	var col := TEXT if hp >= mx - 0.5 else DMG
	var fs := int(px(size))
	var wa := f_num.get_string_size(a, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var wb := f_num.get_string_size(bb, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ww := 0.0
	if word:
		ww = f_body.get_string_size("Hull ", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(19))).x
	var x0 := x if align == 0 else x - (ww + wa + wb)
	if word:
		t(x0, y + px(size - 19) * 0.7, "Hull", f_body, 19, TEXT3, 0, "join")
	t(x0 + ww, y, a, f_num, size, col, 0, "figure")
	t(x0 + ww + wa, y, bb, f_num, size, TEXT2, 0, "figure")
	return ww + wa + wb


# a key after a word, in the figure face and the second strength (no key caps, no badges)
func keyed(x: float, y: float, word: String, key: String, col := TEXT, size := 20.0) -> float:
	var w := t(x, y, word, f_med, size, col)
	if key != "":
		w += px(8)
		w += t(x + w, y + px(1), key, f_num, 18, TEXT2, 0, "key")
	return w


# the one box on the screen: the action, a square ember outline
func action_box(x: float, y: float, w: float, label: String, key := "Enter") -> float:
	var h := px(56)
	draw_rect(Rect2(x, y, w, h), EMBER, false, maxf(2.0, px(2)))
	name_fit(x + px(16), y + px(9), label, 34, w - px(140), EMBER)
	var kw := f_med.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(20))).x
	var ax := x + w - px(18)
	draw_colored_polygon(PackedVector2Array([Vector2(ax - px(10), y + h * 0.5 - px(7)), Vector2(ax, y + h * 0.5), Vector2(ax - px(10), y + h * 0.5 + px(7))]), EMBER)
	t(ax - px(18) - kw, y + px(15), key, f_med, 20, EMBER)
	return h


# ---------------------------------------------------------------- shared blocks

func _gun_rows(x: float, y: float, w: float, compact := false) -> float:
	var P: Dictionary = D["ship"]
	var yy := y
	for wpn in P.get("weapons", []):
		var hit := int(wpn.get("hit", -1))
		var armed: bool = hit >= 0 and D["gun"] == wpn
		var ncol := TEXT if (hit >= 0 or bool(wpn.get("ready", false))) else TEXT2
		var nw := t(x, yy, str(wpn.get("name", "")), f_med, 20, ncol)
		t(x + nw + px(10), yy + px(2), "%s %s" % [str(wpn.get("arc", "")), str(wpn.get("rng", ""))], f_num, 17, TEXT2, 0, "figure")
		if hit >= 0:
			t(x + w, yy - px(1), "%d%%" % hit, f_num, 22, EMBER if armed else TEXT, 1, "figure")
		else:
			var why := str(wpn.get("why", wpn.get("right", "")))
			if why == "ready":
				why = "won't bear"
			t(x + w, yy + px(1), why, f_body, 18, TEXT2, 1)
		yy += px(31 if not compact else 29)
	return yy - y


func _expect_line() -> String:
	var T: Dictionary = D["target"]
	if T.is_empty():
		return ""
	var es: Array = T.get("exp_sh", [0, 0, 0, 0])
	var eh := float(T.get("exp_hull", 0))
	var bq := 0
	var tot := eh
	for i in 4:
		tot += float(es[i])
		if float(es[i]) > float(es[bq]):
			bq = i
	if tot < 0.5:
		return _plain(str(T.get("line", "")))
	var facing: String = ["prow", "starboard", "rear", "port"][bq]
	if float(es[bq]) > 0.5:
		return "About %d damage: %d to its %s shield, %d to hull." % [int(round(tot)), int(round(float(es[bq]))), facing, int(round(eh))]
	return "About %d damage, all to hull." % int(round(tot))


# the orders that can be given now, as words with their keys; the rest wait for hover (the ship's Orders list in full)
func _orders(x: float, y: float, w: float) -> float:
	var P: Dictionary = D["ship"]
	var xx := x
	var yy := y
	var got := false
	var turn_done := false
	for o in P.get("orders", []):
		if not bool(o.get("on", false)):
			continue
		var txt := str(o.get("text", ""))
		var key := ""
		var re := RegEx.new()
		re.compile("^(.*) \\((\\w)\\)$")
		var m := re.search(txt)
		if m != null:
			txt = m.get_string(1)
			key = m.get_string(2)
		if txt.begins_with("Turn "):
			if turn_done:
				continue
			turn_done = true
			txt = "Turn"
			key = "Q E"
		var ww := f_med.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(20))).x + (px(8) + f_num.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(18))).x if key != "" else 0.0)
		if xx + ww > x + w and xx > x:
			xx = x
			yy += px(30)
		keyed(xx, yy, txt, key)
		xx += ww + px(28)
		got = true
	return (yy - y) + (px(30) if got else 0.0)


func _command(x: float, y: float) -> float:
	var w := t(x, y + px(1), "Command", f_body, 19, TEXT3, 0, "join")
	w += px(10)
	w += keyed(x + w, y, str(D["cmd"]), "C", TEXT if D["cmd_ready"] else TEXT2)
	return w


func _fleet(x: float, y: float, w: float, size := 28.0, gap := 36.0) -> float:
	var yy := y
	for r in D["rows"]:
		var done := bool(r.get("done", false))
		var col := TEXT2 if done else TEXT
		if bool(r.get("flag", false)):
			diamond(Vector2(x - px(14), yy + px(size * 0.55)), px(5), EMBER)
		if bool(r.get("sel", false)):
			draw_rect(Rect2(x - px(24), yy + px(4), px(3), px(size - 2)), EMBER)
		name_fit(x, yy, str(r.get("name", "")), size, w - px(110), col)
		var hp := float(r.get("hp", 0))
		var mx := float(r.get("maxHp", 1))
		var a := str(int(round(hp)))
		t(x + w, yy + px(size * 0.22), a, f_num, 19, (TEXT if hp >= mx - 0.5 else DMG) if not done else TEXT2, 1, "figure")
		yy += px(gap)
	return yy - y


func _log(x: float, y: float, w: float, align := 0, lines := 3) -> float:
	var yy := y
	var L: Array = D["log"]
	L = L.slice(maxi(0, L.size() - lines))
	for i in L.size():
		var col := TEXT if i == L.size() - 1 else TEXT2
		yy += para(x, yy, str(L[i]), f_body, 18, col, w, 1.28, align)
		yy += px(4)
	return yy - y


func _turn_line(x: float, y: float, align := 0) -> float:
	var parts := [["Round %d" % int(D["round"]), TEXT2], ["Your turn", EMBER], ["%d of %d ships to act" % [int(D["pend"]), int(D["tot"])], TEXT2]]
	if align == 0:
		var xx := x
		for p in parts:
			xx += t(xx, y, p[0], f_med, 19, p[1]) + px(18)
	else:
		var xx := x
		for i in range(parts.size() - 1, -1, -1):
			xx -= t(xx, y, parts[i][0], f_med, 19, parts[i][1], 1) + px(18)
	return px(26)


func _enemy_top(x: float, y: float) -> void:
	# right aligned at x: the enemy, Heat and the Nemesis, each one line
	var I: Dictionary = D["info"]
	var yy := y
	var hw := 0.0
	if int(I.get("heat", -1)) >= 0:
		hw = t(x, yy + px(1), str(int(I["heat"])), f_num, 19, TEXT, 1, "figure")
		hw += px(8) + t(x - hw - px(8), yy, "Heat", f_body, 19, TEXT3, 1, "join") + px(24)
	t(x - hw, yy, "%s, %d ships" % [str(I.get("foe_name", "")), int(I.get("foe_ships", 0))], f_med, 19, TEXT, 1)
	yy += px(30)
	var N: Dictionary = D["nem"]
	if not N.is_empty():
		var dw := t(x, yy, "Dossier", f_body, 18, TEXT3, 1, "join") + px(16)
		var nw := t(x - dw, yy, str(N.get("name", "")), f_med, 19, TEXT, 1)
		t(x - dw - nw - px(10), yy, "Nemesis", f_med, 19, NEM, 1)


func _menu_top(x: float, y: float) -> void:
	keyed(x - f_med.get_string_size("Menu", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(19))).x - px(8) - f_num.get_string_size("Esc", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(18))).x, y, "Menu", "Esc", TEXT2, 19)


# the tree prompt (issue 529) in the place of the action: the skill's name, its question, the choices numbered
func _prompt(x: float, y: float, w: float) -> float:
	var yy := y
	t(x, yy, str(prompt.get("n", "")).to_upper(), f_name, 32, TEXT, 0, "name")
	yy += px(42)
	yy += para(x, yy, str(prompt.get("q", "")), f_body, 20, TEXT, w)
	yy += px(8)
	var i := 0
	for o in prompt.get("opts", []):
		i += 1
		var h := px(48)
		if i == 1:
			draw_rect(Rect2(x, yy, w, h), EMBER, false, maxf(2.0, px(2)))
		t(x + px(16), yy + px(6), str(i), f_name, 32, EMBER if i == 1 else TEXT, 0, "name")
		t(x + px(52), yy + px(12), str(o.get("n", "")), f_med, 21, TEXT)
		yy += h + px(6)
	return yy - y


func _tag_ships() -> void:
	# words on the board: the ship that is up (ember) and the target; every other name waits for hover
	var P: Dictionary = D["ship"]
	if b.sel != "" and b.views.has(b.sel):
		var sp: Vector2 = b.cam.unproject_position(b._pos(b.sel))
		th(sp.x, sp.y + px(46), str(P.get("name", "")), f_med, 19, EMBER)
	if b.target != "" and b.views.has(b.target):
		var tp: Vector2 = b.cam.unproject_position(b._pos(b.target))
		th(tp.x, tp.y + px(52), str(D["target"].get("name", "")), f_med, 19, TEXT)


# ---------------------------------------------------------------- the three layouts

func _draw() -> void:
	if b == null or D.is_empty():
		return
	k = size.y / 1080.0
	items = []
	match layout:
		"E1": _e1()
		"E2": _e2()
		"E3": _e3()


# E1 LEDGER: the map's rail, carried over. One left sheet, top to bottom in decision order.
func _e1() -> void:
	var W := size.x
	var H := size.y
	veil("l", W * 0.45)
	corner(W, 0, px(780), px(300), 0.9)
	corner(W, H, px(1150), px(340), 0.9)
	var P: Dictionary = D["ship"]
	var T: Dictionary = D["target"]
	var x := px(52)
	var cw := px(560)
	var y := px(40)
	_turn_line(x, y)
	y += px(30)
	t(x, y, D["objective"], f_body, 19, TEXT2)
	y += px(44)
	name_fit(x, y, str(P.get("name", "")), 64, cw, TEXT)
	y += px(80)
	t(x, y, str(P.get("cls", "")), f_med, 21, TEXT)
	y += px(40)
	# hull and the four shields side by side
	hull_fig(x, y + px(20), float(P.get("hp", 0)), float(P.get("maxHp", 1)))
	var mv: Array = P.get("move", [0, 0])
	t(x, y + px(62), "Move %d of %d" % [int(mv[0]), int(mv[1])], f_body, 19, TEXT2)
	shield_plan(Vector2(x + cw - px(70), y + px(46)), P.get("sh", []), float(P.get("shMax", 1)))
	y += px(124)
	var fl := _plain(str(P.get("flags", "")))
	if fl != "":
		y += para(x, y, fl, f_body, 19, TEXT, cw) + px(6)
	y += px(6)
	y += _gun_rows(x, y, cw) + px(14)
	# the focus: the shot (while a tree prompt is open it takes this place: it is asked after the Command, and nothing else
	# acts until it is answered)
	hair(x, x + cw, y)
	y += px(18)
	if not prompt.is_empty():
		y += _prompt(x, y, cw) + px(12)
	else:
		if not T.is_empty():
			t(x, y, "Target", f_body, 19, TEXT3, 0, "join")
			var nm := str(T.get("name", ""))
			var nemn := str(D["nem"].get("name", ""))
			name_fit(x + px(70), y - px(6), nm, 34, cw - px(70), NEM if nemn != "" and nemn == nm else TEXT)
			y += px(46)
			var G: Dictionary = D["gun"]
			if not G.is_empty():
				var ow := t(x, y - px(8), "%d%%" % int(G["hit"]), f_num, 64, EMBER, 0, "focus")
				t(x + ow + px(18), y + px(4), "to hit with the %s" % str(G.get("name", "")), f_med, 20, TEXT)
				para(x + ow + px(18), y + px(34), _expect_line(), f_body, 19, TEXT2, cw - ow - px(18))
				y += px(92)
			else:
				y += para(x, y, _plain(str(T.get("line", ""))), f_body, 19, TEXT2, cw) + px(10)
		var lbl := "Fire the %s" % str(D["gun"].get("name", "guns")) if not D["gun"].is_empty() else "End ship"
		y += action_box(x, y, cw, lbl, "Enter" if not D["gun"].is_empty() else "Space") + px(18)
	y += _orders(x, y, cw) + px(4)
	var cwid := _command(x, y)
	keyed(x + cw - f_med.get_string_size("End ship", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(20))).x - px(8) - f_num.get_string_size("Space", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(18))).x, y, "End ship", "Space", TEXT2)
	# the fleet at the foot, as on the map
	var n: int = (D["rows"] as Array).size()
	var fy := H - px(48) - px(36) * n
	hair(x, x + cw, fy - px(16))
	_fleet(x + px(24), fy, cw - px(24))
	# top right: the enemy, Heat, the Nemesis; the menu
	_menu_top(W - px(52), px(40))
	_enemy_top(W - px(52), px(78))
	# bottom right: the last three lines of the log
	_log_right(W - px(52), 0, px(600), H - px(40))
	_tag_ships()


func _lines_h(txt: String, f: Font, size: float, maxw: float, lh := 1.28) -> float:
	var n := 1
	var line := ""
	var fs := int(px(size))
	for wd in txt.split(" "):
		var tryl := wd if line == "" else line + " " + wd
		if f.get_string_size(tryl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw and line != "":
			n += 1
			line = wd
		else:
			line = tryl
	return n * px(size * lh)


# the last three lines of the log as a block of left-aligned lines whose right edge is xr; "Log L" above it.
# y is the top, or with bottom > 0 the block ends at bottom
func _log_right(xr: float, y: float, w: float, bottom := -1.0) -> void:
	var L: Array = D["log"]
	var x0 := xr - w
	var tot := 0.0
	for l in L:
		tot += _lines_h(str(l), f_body, 18, w) + px(4)
	var yy := y if bottom < 0 else bottom - tot
	t(x0, yy - px(30), "Log  L", f_body, 18, TEXT3, 0, "join")
	for i in L.size():
		var col := TEXT if i == L.size() - 1 else TEXT2
		yy += para(x0, yy, str(L[i]), f_body, 18, col, w, 1.28) + px(4)


# E2 CROSSING: your ship on the left edge, the target on the right edge, the shot at the foot between them
func _e2() -> void:
	var W := size.x
	var H := size.y
	veil("l", W * 0.36)
	veil("r", W * 0.36)
	veil("b", px(230) if prompt.is_empty() else px(470), 0.9, W * 0.18, W * 0.82)
	var P: Dictionary = D["ship"]
	var T: Dictionary = D["target"]
	var x := px(52)
	var cw := px(440)
	var y := px(40)
	_turn_line(x, y)
	y += px(30)
	t(x, y, D["objective"], f_body, 19, TEXT2)
	y += px(48)
	name_fit(x, y, str(P.get("name", "")), 58, cw, TEXT)
	y += px(74)
	t(x, y, str(P.get("cls", "")), f_med, 21, TEXT)
	y += px(40)
	hull_fig(x, y + px(20), float(P.get("hp", 0)), float(P.get("maxHp", 1)))
	var mv: Array = P.get("move", [0, 0])
	t(x, y + px(62), "Move %d of %d" % [int(mv[0]), int(mv[1])], f_body, 19, TEXT2)
	shield_plan(Vector2(x + cw - px(70), y + px(46)), P.get("sh", []), float(P.get("shMax", 1)))
	y += px(124)
	var fl := _plain(str(P.get("flags", "")))
	if fl != "":
		y += para(x, y, fl, f_body, 19, TEXT, cw) + px(6)
	y += px(6)
	y += _gun_rows(x, y, cw) + px(18)
	y += _orders(x, y, cw)
	# fleet at the foot of the left edge
	var n: int = (D["rows"] as Array).size()
	var fy := H - px(48) - px(36) * n
	hair(x, x + cw, fy - px(16))
	_fleet(x + px(24), fy, cw - px(24))
	# the right edge: theirs, right aligned
	var xr := W - px(52)
	_menu_top(xr, px(40))
	_enemy_top(xr, px(78))
	var ry := px(170)
	if not T.is_empty():
		var nm := str(T.get("name", ""))
		var nemn := str(D["nem"].get("name", ""))
		t(xr, ry, "Target", f_body, 19, TEXT3, 1, "join")
		ry += px(28)
		name_fit(xr, ry, nm, 44, cw, NEM if nemn != "" and nemn == nm else TEXT, 1)
		ry += px(70)
		hull_fig(xr, ry + px(44), float(T.get("hp", 0)), float(T.get("maxHp", 1)), 26, 1)
		shield_plan(Vector2(xr - cw + px(70), ry + px(70)), T.get("sh", []), float(T.get("shMax", 1)))
		ry += px(160)
		var G: Dictionary = D["gun"]
		if not G.is_empty():
			t(xr, ry - px(10), "%d%%" % int(G["hit"]), f_num, 88, EMBER, 1, "focus")
			ry += px(100)
			t(xr, ry, "to hit with the %s" % str(G.get("name", "")), f_med, 20, TEXT, 1)
			ry += px(32)
			ry += para(xr, ry, _expect_line(), f_body, 19, TEXT2, cw, 1.3, 1)
	# the log under the target, right aligned
	_log_right(xr, 0, px(440), H - px(40))
	# the foot, between the edges: the action, the Command, End ship
	var bw := px(560)
	var bx := (W - bw) * 0.5
	var by := H - px(150)
	if prompt.is_empty():
		var lbl := "Fire the %s" % str(D["gun"].get("name", "guns")) if not D["gun"].is_empty() else "End ship"
		action_box(bx, by, bw, lbl, "Enter" if not D["gun"].is_empty() else "Space")
	else:
		_prompt(bx, H - px(330), bw)
	var cy := H - px(76)
	_command(bx, cy)
	keyed(bx + bw - f_med.get_string_size("End ship", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(20))).x - px(8) - f_num.get_string_size("Space", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(18))).x, cy, "End ship", "Space", TEXT2)
	_tag_ships()


# E3 FOOTING: one band along the bottom; the scene keeps everything above it
func _e3() -> void:
	var W := size.x
	var H := size.y
	veil("b", px(470))
	corner(0, 0, px(860), px(440), 0.9)
	corner(W, 0, px(1150), px(640), 0.9)
	var P: Dictionary = D["ship"]
	var T: Dictionary = D["target"]
	var top := H - px(300)
	# column 1: the ship
	var x1 := px(52)
	var w1 := px(470)
	var y := top
	name_fit(x1, y, str(P.get("name", "")), 58, w1, TEXT)
	y += px(72)
	t(x1, y, str(P.get("cls", "")), f_med, 21, TEXT)
	y += px(40)
	hull_fig(x1, y + px(20), float(P.get("hp", 0)), float(P.get("maxHp", 1)))
	var mv: Array = P.get("move", [0, 0])
	t(x1, y + px(62), "Move %d of %d" % [int(mv[0]), int(mv[1])], f_body, 19, TEXT2)
	shield_plan(Vector2(x1 + w1 - px(70), y + px(46)), P.get("sh", []), float(P.get("shMax", 1)))
	y += px(124)
	var fl := _plain(str(P.get("flags", "")))
	if fl != "":
		para(x1, y, fl, f_body, 19, TEXT, w1)
	# column 2: the guns and the orders
	var x2 := px(600)
	var w2 := px(520)
	var y2 := top + px(14)
	y2 += _gun_rows(x2, y2, w2) + px(16)
	y2 += _orders(x2, y2, w2)
	_command(x2, H - px(64))
	# column 3: the shot
	var x3 := px(1200)
	var w3 := W - px(52) - x3
	var y3 := top - px(4)
	if not prompt.is_empty():
		_prompt(x3, y3, w3)
	else:
		if not T.is_empty():
			var nm := str(T.get("name", ""))
			var nemn := str(D["nem"].get("name", ""))
			t(x3, y3 + px(10), "Target", f_body, 19, TEXT3, 0, "join")
			name_fit(x3 + px(70), y3, nm, 36, w3 - px(70), NEM if nemn != "" and nemn == nm else TEXT)
			y3 += px(52)
			var G: Dictionary = D["gun"]
			if not G.is_empty():
				var ow := t(x3, y3 - px(8), "%d%%" % int(G["hit"]), f_num, 64, EMBER, 0, "focus")
				t(x3 + ow + px(18), y3 + px(4), "to hit with the %s" % str(G.get("name", "")), f_med, 20, TEXT)
				para(x3 + ow + px(18), y3 + px(34), _expect_line(), f_body, 19, TEXT2, w3 - ow - px(18))
				y3 += px(96)
		var lbl := "Fire the %s" % str(D["gun"].get("name", "guns")) if not D["gun"].is_empty() else "End ship"
		action_box(x3, y3, w3, lbl, "Enter" if not D["gun"].is_empty() else "Space")
	keyed(W - px(52) - f_med.get_string_size("End ship", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(20))).x - px(8) - f_num.get_string_size("Space", HORIZONTAL_ALIGNMENT_LEFT, -1, int(px(18))).x, H - px(64), "End ship", "Space", TEXT2)
	# top left: the turn and the fleet; top right: the enemy and the log
	var x := px(52)
	_turn_line(x, px(40))
	t(x, px(70), D["objective"], f_body, 19, TEXT2)
	_fleet(x + px(24), px(112), px(380), 28, 36)
	var xr := W - px(52)
	_menu_top(xr, px(40))
	_enemy_top(xr, px(78))
	_log_right(xr, px(196), px(600))
	_tag_ships()
