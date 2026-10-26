extends Control
# "Name your flagship" (R37 step 1). story.gd opens it once at the start of each run (over the sector I intro), and any
# screen can open it again with story.open_rename(). Enter or Rename saves; Esc or Keep the name closes.

signal closed

const INK := Color("#0f1626")
const IRON := Color("#182133")
const IRON3 := Color("#2d3a56")
const BONE := Color("#e6dcc4")
const BONE2 := Color("#b3aa95")
const GILT := Color("#d0a64b")
const GILT2 := Color("#8c6d2c")

var story = null
var edit: LineEdit
var k := 1.0


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


func open(st) -> void:
	story = st
	k = clampf(get_viewport_rect().size.y / 1080.0, 0.6, 2.0)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var regular := _font("res://ui/battle/fonts/BarlowSemiCondensed-Regular.ttf")
	var semi := _font("res://ui/battle/fonts/BarlowSemiCondensed-SemiBold.ttf")
	var goth := _font("res://ui/battle/fonts/UnifrakturMaguntia-Book.ttf")
	var dimr := ColorRect.new()
	dimr.color = Color(0.024, 0.035, 0.063, 0.7)
	dimr.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimr)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", _sb(IRON, GILT2, 1, 6, 24))
	cc.add_child(box)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(12))
	v.custom_minimum_size.x = px(560)
	box.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", px(14))
	var crest = load("res://ui/career/crest.gd").new()
	crest.fac = str(story.C.RUN.get("fac", "")) if story.C != null and story.C.RUN is Dictionary else ""
	crest.custom_minimum_size = Vector2(px(60), px(60))
	h.add_child(crest)
	var t := Label.new()
	t.text = "Name your flagship"
	t.add_theme_font_override("font", goth)
	t.add_theme_font_size_override("font_size", px(40))
	t.add_theme_color_override("font_color", BONE)
	h.add_child(t)
	v.add_child(h)
	var p := Label.new()
	p.text = "She carries your colours and your Command into every fight this run. The crews will paint the name on her prow tonight."
	p.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_theme_font_override("font", regular)
	p.add_theme_font_size_override("font_size", px(17))
	p.add_theme_color_override("font_color", BONE2)
	v.add_child(p)
	edit = LineEdit.new()
	edit.text = story.flagship_name()
	edit.max_length = 28
	edit.select_all_on_focus = true
	edit.add_theme_font_override("font", semi)
	edit.add_theme_font_size_override("font_size", px(22))
	edit.add_theme_color_override("font_color", BONE)
	edit.add_theme_stylebox_override("normal", _sb(INK, IRON3, 1, 4, 10))
	edit.add_theme_stylebox_override("focus", _sb(INK, GILT, 1, 4, 10))
	edit.text_submitted.connect(func(_t: String) -> void: _save())
	v.add_child(edit)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", px(10))
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_btn("Keep the name", _close, semi, false))
	row.add_child(_btn("Rename", _save, semi, true))
	v.add_child(row)
	edit.grab_focus.call_deferred()
	edit.select_all.call_deferred()


func _btn(txt: String, cb: Callable, f: Font, primary: bool) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_override("font", f)
	b.add_theme_font_size_override("font_size", px(18))
	b.add_theme_color_override("font_color", INK if primary else BONE)
	b.add_theme_color_override("font_hover_color", INK if primary else GILT)
	b.add_theme_stylebox_override("normal", _sb(GILT if primary else IRON, GILT2 if primary else IRON3, 1, 4, 10))
	b.add_theme_stylebox_override("hover", _sb(Color("#e0b85c") if primary else IRON, GILT, 1, 4, 10))
	b.add_theme_stylebox_override("pressed", _sb(GILT2 if primary else INK, GILT, 1, 4, 10))
	b.add_theme_stylebox_override("focus", _sb(Color(0, 0, 0, 0), GILT, 1, 4, 10))
	b.pressed.connect(cb)
	return b


func _save() -> void:
	if story != null:
		story.rename_flagship(edit.text)
	_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and (e as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()
