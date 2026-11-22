extends Control
# The Career screen (R37 step 1): records across runs, medals, the titles you can earn, the run history and the
# Chronicle of faction arcs. It reads story.career.P (godot/story/career.gd) and never changes campaign state.
# Open it with story.open_career() (from a campaign screen) or Story.open_standalone(parent) (from the title screen).
# Esc or Close emits `closed` and frees it.

signal closed

const GS := preload("res://ui/theme/glass_shell.gd")
const Portraits := preload("res://portraits/portraits.gd")
const INK := GS.CAREER_INK
const IRON := INK
const IRON3 := GS.SHEET_HAIR
const BONE := GS.TEXT
const BONE2 := GS.TEXT2
const BONE3 := GS.TEXT3
const GILT := BONE
const GILT2 := GS.SHEET_HAIR
const BLOOD := BONE
const TABS := [["records", "Records"], ["medals", "Medals"], ["titles", "Titles"], ["history", "History"], ["chronicle", "Chronicle"]]
const ROMAN := ["0", "I", "II", "III", "IV", "V"]
const Crest := preload("res://ui/career/crest.gd")
const ModalFocus := preload("res://ui/theme/modal_focus.gd")   # issue 1559
const Kit := preload("res://ui/theme/orders_kit.gd")   # issue 1448: the shared ui cues (watch_sound)

var story = null
var tab := "records"
var k := 1.0
var regular: Font
var semi: Font
var goth: Font
var figures: Font
var body: VBoxContainer
var tab_row: HBoxContainer
var scroll: ScrollContainer


func px(v: float) -> int:
	return int(round(v * k))


func lbl(t: String, size := 17.0, col := BONE, f: Font = null, wrap := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f if f != null else regular)
	l.add_theme_font_size_override("font_size", px(size))
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _btn(txt: String, cb: Callable, sel := false, action := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", semi)
	b.add_theme_font_size_override("font_size", px(18))
	b.add_theme_color_override("font_color", BONE if sel or action else BONE2)
	b.add_theme_color_override("font_hover_color", GS.ON_EMBER if action else BONE)
	b.add_theme_color_override("font_pressed_color", GS.ON_EMBER if action else BONE)
	b.add_theme_color_override("font_focus_color", BONE)
	var normal := GS.flat(Color.TRANSPARENT, 0, 0, k)
	normal.content_margin_top = px(8)
	normal.content_margin_bottom = px(8)
	if sel:
		normal.border_color = BONE
		normal.border_width_bottom = maxi(1, px(1))
	if action:
		var boxes := GS.sheet_jump_boxes(k)
		for state in boxes:
			b.add_theme_stylebox_override(state, boxes[state])
	else:
		for state in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, normal)
	b.add_theme_stylebox_override("focus", GS.ledger_focus(k))
	b.pressed.connect(cb)
	return b


func _key_button(text: String, key: String, cb: Callable, selected := false, action := false) -> Button:
	var b := _btn("", cb, selected, action)
	b.tooltip_text = text + " " + key
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", px(12))
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_top = px(8)
	row.offset_bottom = -px(8)
	row.offset_left = px(22) if action else 0
	row.offset_right = -px(22) if action else 0
	var words := lbl(text, 18, BONE if selected or action else BONE2, semi, false)
	words.mouse_filter = MOUSE_FILTER_IGNORE
	words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(words)
	if action:
		var space := Control.new()
		space.mouse_filter = MOUSE_FILTER_IGNORE
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(space)
	var keys := lbl(key, 17, BONE2, figures, false)
	keys.mouse_filter = MOUSE_FILTER_IGNORE
	keys.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(keys)
	b.add_child(row)
	# A Button does not inherit its child's minimum width. Measure the two faces before layout.
	var word_width := semi.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(18)).x
	var key_width := figures.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, px(17)).x
	b.custom_minimum_size = Vector2(px(288) if action else ceilf(word_width + key_width + px(14)), px(56 if action else 40))
	var recolour := func(over: bool):
		words.add_theme_color_override("font_color", GS.ON_EMBER if action and over else (BONE if over or selected or action else BONE2))
		keys.add_theme_color_override("font_color", GS.ON_EMBER if action and over else BONE2)
	b.mouse_entered.connect(recolour.bind(true))
	b.mouse_exited.connect(recolour.bind(false))
	return b


func _panel(bg := IRON, border := IRON3, pad := 12.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GS.flat(Color.TRANSPARENT, pad, 0, k))
	return p


func open(st) -> void:
	story = st
	Kit.watch_sound(self)   # issue 1448: tabs and buttons click like every other screen
	k = load("res://ui/ui_scale.gd").k_for(get_viewport_rect().size)   # the one shared law (ui_spec.md section 4); its ceiling was 2.0 here
	regular = GS.sheet_body()
	semi = GS.sheet_medium()
	goth = GS.sheet_name()
	figures = GS.num()
	theme = GS.ledger_theme(k)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = INK  # opaque: the title's decorative battle must not show through
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, px(72))
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, px(40))
	add_child(margin)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(14))
	margin.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", px(16))
	head.add_child(lbl("CAREER", 52, BONE, goth, false))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var close := _key_button("Close", "Esc", _close, false, true)
	close.name = "Close"
	Kit.wire_sound(close, "back")
	close.custom_minimum_size = Vector2(px(288), px(56))
	close.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(close)
	v.add_child(head)
	v.add_child(lbl("Your service across every run: records per admiral, medals, the titles your way of fighting has earned, and the runs behind them.", 17, BONE2))
	tab_row = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", px(40))
	v.add_child(tab_row)
	v.add_child(_lifetime())
	v.add_child(_rule())
	var sc := ScrollContainer.new()
	scroll = sc
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", px(12))
	sc.add_child(body)
	render()
	# issue 1559 items 4, 14, 15: Career is modal for the keyboard. Focus starts on Close, stays inside (the title menu
	# or the Progression tab behind cannot take Enter), and goes back to what had it when Career closes.
	ModalFocus.attach(self, close)


func set_tab(t: String) -> void:
	tab = t
	scroll.scroll_vertical = 0
	render()


func render() -> void:
	for c in tab_row.get_children():
		tab_row.remove_child(c)
		c.queue_free()
	for i in TABS.size():
		var t: Array = TABS[i]
		var b := _key_button(t[1], str(i + 1), set_tab.bind(t[0]), tab == t[0])
		b.name = str(t[0])
		tab_row.add_child(b)
	for c in body.get_children():
		body.remove_child(c)
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
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", px(4))
	v.add_child(lbl(value, 40, BONE, figures, false))
	v.add_child(lbl(label.to_upper(), 17, BONE3))
	return v


func _n(x) -> String:
	return str(int(float(x if x != null else 0)))


func _lifetime() -> Control:
	var T: Dictionary = _P().get("totals", {})
	var f := HBoxContainer.new()
	f.name = "Lifetime"
	f.add_theme_constant_override("separation", px(24))
	f.add_child(_tile("Runs", _n(T.get("runs"))))
	f.add_child(_tile("Victories", _n(T.get("wins")), GILT))
	f.add_child(_tile("Battles", _n(T.get("battles"))))
	f.add_child(_tile("Enemy ships\ndestroyed", _n(T.get("kills"))))
	f.add_child(_tile("Flagships\ndestroyed", _n(T.get("flag_kills")), GILT))
	f.add_child(_tile("Prizes taken", _n(T.get("captures"))))
	f.add_child(_tile("Ships lost", _n(T.get("lost")), BLOOD))
	return f


func _rule() -> Control:
	var r := ColorRect.new()
	r.color = GS.SHEET_HAIR
	r.custom_minimum_size.y = maxi(1, px(1))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _served(a: Dictionary) -> bool:
	return int(a.get("runs", 0)) > 0 or int(a.get("battles", 0)) > 0


func _grid(columns: int, gap := 40.0) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_theme_constant_override("h_separation", px(gap))
	g.add_theme_constant_override("v_separation", px(24))
	return g


func _records() -> void:
	var adm: Dictionary = _P().get("admirals", {})
	var served: Array = []
	var unserved: Array = []
	for fac in story.FACS:
		for id in story.ADM:
			if story.admiral_fac(id) != fac:
				continue
			if _served(adm.get(id, {})):
				served.append(id)
			else:
				unserved.append(id)
	body.add_child(lbl("SERVED  %d" % served.size(), 28, BONE, goth, false))
	var heroes := _grid(3)
	heroes.name = "Heroes"
	for id in served:
		heroes.add_child(_admiral_card(id, adm[id]))
	body.add_child(heroes)
	if served.is_empty():
		body.add_child(lbl("Your first service record will appear here after battle.", 18, BONE2))
	if unserved.is_empty():
		return
	body.add_child(_rule())
	body.add_child(lbl("NO SERVICE YET  %d" % unserved.size(), 28, BONE2, goth, false))
	var roster := _grid(3)
	roster.name = "Unserved"
	for fac in story.FACS:
		var ids: Array = unserved.filter(func(id): return story.admiral_fac(id) == fac)
		if ids.is_empty():
			continue
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", px(4))
		v.add_child(lbl(str(story.FAC.get(fac, {}).get("n", fac)).to_upper(), 28, BONE2, goth))
		for id in ids:
			v.add_child(_unserved_admiral(id))
		roster.add_child(v)
	body.add_child(roster)


# Rank stays beneath the name, as in CR4. Unusual names stay whole.
func _name_parts(id: String) -> Array:
	var full: String = story.admiral_name(id)
	for rank in ["First Admiral", "High Admiral", "Oath-Captain", "Fleet Marshal", "Line Admiral", "Commodore", "Admiral", "Warlord"]:
		if full.begins_with(rank + " "):
			return [full.trim_prefix(rank + " "), rank]
	return [full, ""]


func _unserved_admiral(id: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Unserved_" + id
	row.set_meta("admiral", id)
	row.add_theme_constant_override("separation", px(12))
	if story.admiral_fac(id) == "voidsworn":
		var crest := TextureRect.new()
		crest.name = "Crest"
		crest.texture = Portraits.crest(id)
		crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crest.custom_minimum_size = Vector2(px(32), px(40))
		row.add_child(crest)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	words.add_child(lbl(story.admiral_name(id), 18, BONE2))
	words.add_child(lbl(str(story.ADM[id].get("doc", "")), 17, BONE3))
	row.add_child(words)
	return row


func _admiral_card(id: String, a: Dictionary) -> Control:
	var v := VBoxContainer.new()
	v.name = "Hero_" + id
	v.set_meta("admiral", id)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", px(6))
	var fl: Array = a.get("flagships", [])
	var picture := PanelContainer.new()
	picture.name = "PictureBand"
	picture.custom_minimum_size.y = px(132)
	picture.add_theme_stylebox_override("panel", GS.flat(GS.CAREER_PICTURE, 0, 0, k))
	if id == "vex" and Portraits.has_painting(id):
		var portrait := TextureRect.new()
		var face := Portraits.face(id)
		var crop := AtlasTexture.new()
		crop.atlas = face
		# The wide strip centres on Vex's face in the upper part of the painting.
		crop.region = Rect2(0, 0, face.get_width(), face.get_height() * 0.72)
		portrait.texture = crop
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.add_child(portrait)
	else:
		var band := MarginContainer.new()
		for side in ["left", "right", "top", "bottom"]:
			band.add_theme_constant_override("margin_" + side, px(20))
		var words := VBoxContainer.new()
		words.add_child(lbl("FLAGSHIP", 17, BONE3))
		words.add_child(lbl(str(fl.back()).to_upper() if not fl.is_empty() else "Name not recorded", 34, BONE, goth))
		band.add_child(words)
		picture.add_child(band)
	v.add_child(picture)
	var parts := _name_parts(id)
	v.add_child(lbl(str(parts[0]).to_upper(), 34, BONE, goth))
	var fac: String = story.admiral_fac(id)
	v.add_child(lbl((str(parts[1]) + " · " if parts[1] != "" else "") + str(story.FAC.get(fac, {}).get("n", fac)), 17, BONE2))
	var tl: Dictionary = a.get("titles", {})
	for t in tl:
		v.add_child(lbl("%s  (%d)" % [story.career.title_name(str(t), fac).to_upper(), int(tl[t])], 28, BONE, goth))
	var arc: String = story.career.arc_title(fac, id)
	if not arc.is_empty():
		v.add_child(lbl(arc, 17, BONE2))
	var best := int(a.get("best", 0))
	var stats := _grid(3, 16)
	stats.name = "Figures"
	stats.add_theme_constant_override("v_separation", px(12))
	for stat in [["RUNS", _n(a.get("runs"))], ["WON", _n(a.get("wins"))], ["BEST SECTOR", ROMAN[clampi(best, 0, 5)]], ["BATTLES", _n(a.get("battles"))], ["KILLS", _n(a.get("kills"))], ["SHIPS LOST", _n(a.get("lost"))]]:
		var group := VBoxContainer.new()
		group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		group.add_theme_constant_override("separation", 0)
		group.add_child(lbl(stat[1], 34, BONE, figures, false))
		group.add_child(lbl(stat[0], 17, BONE3))
		stats.add_child(group)
	v.add_child(stats)
	if not fl.is_empty() and (id == "vex" or fl.size() > 1):
		v.add_child(lbl("Flagships: " + ", ".join(PackedStringArray(fl)), 17, BONE2))
	return v


func _medals() -> void:
	var have: Dictionary = _P().get("medals", {})
	var n := 0
	for m in story.career.all_medals():
		if have.has(str(m["id"])):
			n += 1
	body.add_child(lbl("%d of %d medals earned." % [n, story.career.all_medals().size()], 17, BONE2))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", px(10))
	g.add_theme_constant_override("v_separation", px(10))
	for m in story.career.all_medals():
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
		v.add_child(lbl(str(m["d"]), 17, BONE2 if not got.is_empty() else BONE3))
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
		v.add_child(lbl(str(t.get("rule", "")) + ("  Earned %d time%s." % [cnt, "" if cnt == 1 else "s"] if cnt > 0 else ""), 17, BONE2 if cnt > 0 else BONE3))
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
			(". Flagship: the " + flag) if flag != "" else "", (", %d minutes" % int(r.get("mins", 0))) if int(r.get("mins", 0)) > 0 else ""], 17, BONE2))
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
		var A: Dictionary = story.career.arcs().get(fac, {})
		var rw: Dictionary = _P().get("arc_rewards", {}).get(fac, {})
		v.add_child(lbl(str(A.get("arc", "")), 17, GILT if not rw.is_empty() else BONE3))
		if done.is_empty():
			v.add_child(lbl("Not yet told.", 17, BONE3))
		else:
			var last: Dictionary = done[done.size() - 1]
			v.add_child(lbl("%s. Rival: %s." % ["Finished" if bool(last.get("won", false)) else "Fell at the Hollow Sun", str(last.get("rival", "")) + ((" of " + str(last["rival_fac"])) if str(last.get("rival_fac", "")) != "" else "")], 17, BONE2))
			var said: Dictionary = last.get("said", {}) if last.get("said") is Dictionary else {}
			if not said.is_empty():
				var ks: Array = said.keys()
				ks.sort()
				var parts: Array = []
				for k in ks:
					parts.append(str(said[k]).trim_suffix("."))
				v.add_child(lbl(". ".join(PackedStringArray(parts)) + ".", 17, BONE3))
			if str(last.get("first_lost", "")) != "":
				v.add_child(lbl("First ship lost: the " + str(last["first_lost"]) + ".", 17, BONE3))
		if not rw.is_empty():
			v.add_child(lbl("Title: " + str(rw.get("title", "")), 17, GILT))
			if str(rw.get("unlock", "")) != "":
				v.add_child(lbl("Hull unlocked: " + str(A.get("unlock_name", rw["unlock"])), 17, BONE3))
		h.add_child(v)
		p.add_child(h)
		g.add_child(p)
	body.add_child(g)


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if ModalFocus.covered(self): return   # a dialog opened over Career has the keys
		var key := (e as InputEventKey).keycode
		if key == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			Kit.play("ui_cancel")
			_close()
		elif key >= KEY_1 and key <= KEY_5:
			get_viewport().set_input_as_handled()
			Kit.play("ui_select")
			set_tab(TABS[key - KEY_1][0])
