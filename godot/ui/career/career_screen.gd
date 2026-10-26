extends Control
# The Career screen (R37 step 1): records across runs, medals, the titles you can earn, the run history and the
# Chronicle of faction arcs. It reads story.career.P (godot/story/career.gd) and never changes campaign state.
# Open it with story.open_career() (from a campaign screen) or Story.open_standalone(parent) (from the title screen).
# Esc or Close emits `closed` and frees it.

signal closed

const INK := Color("#0f1626")
const IRON := Color("#182133")
const IRON2 := Color("#222d44")
const IRON3 := Color("#2d3a56")
const BONE := Color("#e6dcc4")
const BONE2 := Color("#b3aa95")
const BONE3 := Color("#7d7768")
const GILT := Color("#d0a64b")
const GILT2 := Color("#8c6d2c")
const VERD := Color("#5fb3a6")
const BLOOD := Color("#e27f74")
const TABS := [["records", "Records"], ["medals", "Medals"], ["titles", "Titles"], ["history", "History"], ["chronicle", "Chronicle"]]
const ROMAN := ["0", "I", "II", "III", "IV", "V"]
const Crest := preload("res://ui/career/crest.gd")

var story = null
var tab := "records"
var k := 1.0
var regular: Font
var semi: Font
var goth: Font
var body: VBoxContainer
var tab_row: HBoxContainer


static func _font(p: String) -> Font:
	if ResourceLoader.exists(p):
		return load(p)
	var f := FontFile.new()
	if FileAccess.file_exists(p):
		f.load_dynamic_font(p)
	return f


func px(v: float) -> int:
	return int(round(v * k))


func _sb(bg: Color, border: Color, bw := 1, rad := 4, pad := 10.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(rad)
	s.set_content_margin_all(px(pad))
	return s


func lbl(t: String, size := 17.0, col := BONE, f: Font = null, wrap := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f if f != null else regular)
	l.add_theme_font_size_override("font_size", px(size))
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(txt: String, cb: Callable, sel := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", semi)
	b.add_theme_font_size_override("font_size", px(18))
	b.add_theme_color_override("font_color", GILT if sel else BONE2)
	b.add_theme_color_override("font_hover_color", GILT)
	b.add_theme_stylebox_override("normal", _sb(IRON2 if sel else IRON, GILT2 if sel else IRON3, 1, 4, 8))
	b.add_theme_stylebox_override("hover", _sb(IRON2, GILT, 1, 4, 8))
	b.add_theme_stylebox_override("pressed", _sb(INK, GILT, 1, 4, 8))
	b.add_theme_stylebox_override("focus", _sb(Color(0, 0, 0, 0), GILT, 1, 4, 8))
	b.pressed.connect(cb)
	return b


func _panel(bg := IRON, border := IRON3, pad := 12.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(bg, border, 1, 5, pad))
	return p


func open(st) -> void:
	story = st
	k = clampf(get_viewport_rect().size.y / 1080.0, 0.6, 2.0)
	regular = _font("res://ui/battle/fonts/BarlowSemiCondensed-Regular.ttf")
	semi = _font("res://ui/battle/fonts/BarlowSemiCondensed-SemiBold.ttf")
	goth = _font("res://ui/battle/fonts/UnifrakturMaguntia-Book.ttf")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.024, 0.035, 0.063, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, px(80))
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, px(44))
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(14))
	margin.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", px(16))
	head.add_child(lbl("Career", 56, BONE, goth, false))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var close := _btn("Close", _close)
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(close)
	v.add_child(head)
	v.add_child(lbl("Your service across every run: records per admiral, medals, the titles your way of fighting has earned, and the runs behind them.", 17, BONE2))
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", px(8))
	v.add_child(tab_row)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", px(12))
	sc.add_child(body)
	render()


func set_tab(t: String) -> void:
	tab = t
	render()


func render() -> void:
	for c in tab_row.get_children():
		c.queue_free()
	for t in TABS:
		var b := _btn(t[1], set_tab.bind(t[0]), tab == t[0])
		tab_row.add_child(b)
	for c in body.get_children():
		c.queue_free()
	match tab:
		"records": _records()
		"medals": _medals()
		"titles": _titles()
		"history": _history()
		"chronicle": _chronicle()


# ---------------------------------------------------------------- tabs

func _P() -> Dictionary:
	return story.career.P if story != null else {}


func _tile(label: String, value: String, col := BONE) -> Control:
	var p := _panel(IRON, IRON3, 12)
	p.custom_minimum_size.x = px(150)
	var v := VBoxContainer.new()
	v.add_child(lbl(value, 34, col, semi, false))
	v.add_child(lbl(label.to_upper(), 12, BONE3, semi, false))
	p.add_child(v)
	return p


func _n(x) -> String:
	return str(int(float(x if x != null else 0)))


func _records() -> void:
	var T: Dictionary = _P().get("totals", {})
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", px(10))
	f.add_theme_constant_override("v_separation", px(10))
	f.add_child(_tile("Runs", _n(T.get("runs"))))
	f.add_child(_tile("Victories", _n(T.get("wins")), GILT))
	f.add_child(_tile("Battles", _n(T.get("battles"))))
	f.add_child(_tile("Enemy ships destroyed", _n(T.get("kills"))))
	f.add_child(_tile("Flagships destroyed", _n(T.get("flag_kills")), GILT))
	f.add_child(_tile("Prizes taken", _n(T.get("captures"))))
	f.add_child(_tile("Ships lost", _n(T.get("lost")), BLOOD))
	body.add_child(f)
	var adm: Dictionary = _P().get("admirals", {})
	for fac in story.FACS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", px(10))
		var cr = Crest.new()
		cr.fac = fac
		cr.custom_minimum_size = Vector2(px(40), px(40))
		row.add_child(cr)
		row.add_child(lbl(str(story.FAC.get(fac, {}).get("n", fac)), 26, BONE, goth, false))
		body.add_child(row)
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", px(10))
		g.add_theme_constant_override("v_separation", px(10))
		for id in story.ADM:
			if story.admiral_fac(id) != fac:
				continue
			g.add_child(_admiral_card(id, adm.get(id, {})))
		body.add_child(g)


func _admiral_card(id: String, a: Dictionary) -> Control:
	var served := int(a.get("runs", 0)) > 0 or int(a.get("battles", 0)) > 0
	var p := _panel(IRON if served else INK, IRON3, 12)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(3))
	v.add_child(lbl(story.titled_name(id), 19, BONE if served else BONE3, semi))
	if not served:
		v.add_child(lbl(str(story.ADM[id].get("doc", "")) + ". No service yet.", 15, BONE3))
		p.add_child(v)
		return p
	var best := int(a.get("best", 0))
	v.add_child(lbl("%s runs, %s won. Best: sector %s. %s battles, %s kills, %s ships lost." % [_n(a.get("runs")), _n(a.get("wins")), ROMAN[clampi(best, 0, 5)], _n(a.get("battles")), _n(a.get("kills")), _n(a.get("lost"))], 15, BONE2))
	var tl: Dictionary = a.get("titles", {})
	if not tl.is_empty():
		var parts: Array = []
		for t in tl:
			parts.append("%s (%d)" % [story.career.title_name(str(t), story.admiral_fac(id)), int(tl[t])])
		v.add_child(lbl("Titles: " + ", ".join(PackedStringArray(parts)), 15, GILT))
	var fl: Array = a.get("flagships", [])
	if not fl.is_empty():
		v.add_child(lbl("Flagships: " + ", ".join(PackedStringArray(fl)), 15, BONE3))
	p.add_child(v)
	return p


func _medals() -> void:
	var have: Dictionary = _P().get("medals", {})
	var n := 0
	for m in story.career.medals_data.get("medals", []):
		if have.has(str(m["id"])):
			n += 1
	body.add_child(lbl("%d of %d medals earned." % [n, story.career.medals_data.get("medals", []).size()], 17, BONE2))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", px(10))
	g.add_theme_constant_override("v_separation", px(10))
	for m in story.career.medals_data.get("medals", []):
		var got: Dictionary = have.get(str(m["id"]), {})
		var p := _panel(IRON if not got.is_empty() else INK, GILT2 if not got.is_empty() else IRON3, 10)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", px(12))
		var cr = Crest.new()
		cr.glyph = str(m.get("glyph", "?"))
		cr.col = Color(str(m.get("col", "#d0a64b")))
		cr.dim = got.is_empty()
		cr.font = semi
		cr.custom_minimum_size = Vector2(px(58), px(58))
		h.add_child(cr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(lbl(str(m["n"]) + ("" if got.is_empty() or int(got.get("count", 1)) <= 1 else "  x%d" % int(got["count"])), 18, BONE if not got.is_empty() else BONE3, semi))
		v.add_child(lbl(str(m["d"]), 14, BONE2 if not got.is_empty() else BONE3))
		h.add_child(v)
		p.add_child(h)
		g.add_child(p)
	body.add_child(g)


func _titles() -> void:
	var TD: Dictionary = story.career.titles_data
	body.add_child(lbl("At the end of a run your admiral earns one title from how the fleet fought (a run needs %d battles or more). The strongest style wins. Each faction says it in its own words." % int(TD.get("min_battles", 3)), 17, BONE2))
	var earned := {}
	for id in _P().get("admirals", {}):
		var tl: Dictionary = _P()["admirals"][id].get("titles", {})
		for t in tl:
			earned[t] = int(earned.get(t, 0)) + int(tl[t])
	var rows: Array = TD.get("titles", []).duplicate()
	rows.append(TD.get("fallback", {}))
	for t in rows:
		if not (t is Dictionary) or t.is_empty():
			continue
		var cnt := int(earned.get(str(t["id"]), 0))
		var p := _panel(IRON if cnt > 0 else INK, GILT2 if cnt > 0 else IRON3, 10)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", px(2))
		var names: Array = []
		for fac in story.FACS:
			names.append(str(t.get("n", {}).get(fac, "")))
		v.add_child(lbl(" / ".join(PackedStringArray(names)), 18, GILT if cnt > 0 else BONE2, semi))
		v.add_child(lbl(str(t.get("rule", "")) + ("  Earned %d time%s." % [cnt, "" if cnt == 1 else "s"] if cnt > 0 else ""), 15, BONE2 if cnt > 0 else BONE3))
		p.add_child(v)
		body.add_child(p)


func _history() -> void:
	var h: Array = _P().get("history", [])
	if h.is_empty():
		body.add_child(lbl("No runs recorded yet. Every run you finish, won or lost, is written here.", 17, BONE3))
		return
	for i in range(h.size() - 1, -1, -1):
		var r: Dictionary = h[i]
		var p := _panel(IRON, GILT2 if bool(r.get("victory", false)) else IRON3, 10)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", px(12))
		var cr = Crest.new()
		cr.fac = str(r.get("fac", ""))
		cr.custom_minimum_size = Vector2(px(44), px(44))
		row.add_child(cr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var res: String = "Victory" if bool(r.get("victory", false)) else "Fell in sector " + ROMAN[clampi(int(r.get("sector", 1)), 0, 5)]
		var who: String = str(r.get("admiral_name", "")) if str(r.get("admiral_name", "")) != "" else story.admiral_name(str(r.get("admiral", "")))
		v.add_child(lbl("%s %s: %s" % [who, str(r.get("title_name", "")), res], 18, GILT if bool(r.get("victory", false)) else BONE, semi))
		var flag := str(r.get("flagship", ""))
		var date := Time.get_date_string_from_unix_time(int(r.get("t", 0)))
		v.add_child(lbl("%s. %d battles, %d kills, %d ships lost, %d prizes%s%s." % [date, int(r.get("battles", 0)), int(r.get("kills", 0)), int(r.get("lost", 0)), int(r.get("captures", 0)),
			(". Flagship: the " + flag) if flag != "" else "", (", %d minutes" % int(r.get("mins", 0))) if int(r.get("mins", 0)) > 0 else ""], 15, BONE2))
		row.add_child(v)
		p.add_child(row)
		body.add_child(p)


func _chronicle() -> void:
	var ch: Array = _P().get("chronicle", [])
	body.add_child(lbl("Each faction has its own story, told across the three sectors of a run and settled against your Nemesis. Finished stories are recorded here with the choices you made.", 17, BONE2))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", px(10))
	g.add_theme_constant_override("v_separation", px(10))
	for fac in story.FACS:
		var done: Array = ch.filter(func(e): return e is Dictionary and str(e.get("fac", "")) == fac)
		var p := _panel(IRON if not done.is_empty() else INK, GILT2 if not done.is_empty() else IRON3, 12)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", px(10))
		var cr = Crest.new()
		cr.fac = fac
		cr.dim = done.is_empty()
		cr.custom_minimum_size = Vector2(px(54), px(54))
		h.add_child(cr)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(lbl(str(story.FAC.get(fac, {}).get("n", fac)), 18, BONE if not done.is_empty() else BONE3, semi))
		if done.is_empty():
			v.add_child(lbl("Not yet told.", 15, BONE3))
		else:
			var last: Dictionary = done[done.size() - 1]
			v.add_child(lbl("%s. Rival: %s." % [str(last.get("arc", "")), str(last.get("rival", ""))], 15, BONE2))
		h.add_child(v)
		p.add_child(h)
		g.add_child(p)
	body.add_child(g)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
