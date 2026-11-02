extends CanvasLayer
# The battle HUD, laid out like today's game (head.html, ui3d.js): top bar, your fleet on the left, the selected ship's
# panel on the right (stats, weapons with hit chances, orders), the battle log bottom left, ship nameplates over the
# board, the round banner, hover tips, the enemy-acting chip, one-at-a-time onboarding tips, and the end card.
# Colours from the game's CSS variables. Sizes scale with the window height (designed at 1080).
#
# Screen layout (UI pass, Nov 1): every part has its own region, so nothing sits on anything else at any window size.
#   top bar (full width) | under it, between the fleet list and the ship panel: the banner strip (legend chip, then the
#   turn strip, the enemy-AI chip, toasts, the tip card) | left: fleet list, battle log under it | right: ship panel |
#   bottom, between the log and the ship panel: the activation card (or the key hint).
# _layout() enforces this every frame: the strip, chip, toast, card, hint and hover tip stay inside the middle column,
# and the fleet list and ship panel get shorter (they scroll) rather than run under the log or the card.
# The HUD is rebuilt at the new scale when the window size changes (a capture window, Full screen, un-maximise): before
# this it kept the size of the window it was built in, so a 1920x1080 window could carry a 4K-sized HUD.

signal action(name: String, arg: Variant)
signal rescaled   # the HUD was rebuilt at a new size; the battle refreshes what it shows

const Brand := preload("res://ui/battle/brand.gd")

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
const EMBER := Color("#f0b35a")
const SHIELD := Color("#62ccff")
const HULL := Color("#ffae42")
const HULL_LOW := Color("#ff5a3c")
const GLASS := Color(0.047, 0.07, 0.12, 0.80)
const FRIEND := Color(0.56, 0.94, 0.63)
const FOE := Color(0.79, 0.64, 1.0)

var font: FontFile
var font_semi: FontFile
var font_goth: Font                 # headers: Michroma (brand.gd), the sci-fi display face
var font_caps: Font                 # section heads: Oxanium small caps
var k := 1.0                        # window height / 1080
var root: Control
var top: PanelContainer
var title_lbl: Label
var crest: TextureRect
var turn_lbl: Label
var obj_lbl: Label
var end_btn: Button
var speed_btn: Button
var threat_btn: Button
var retreat_btn: Button
var cmd_btn: Button
var roster: PanelContainer
var roster_box: VBoxContainer
var roster_sc: ScrollContainer
var panel_sc: ScrollContainer
var panel: PanelContainer
var panel_box: VBoxContainer
var log_panel: PanelContainer
var log_text: RichTextLabel
var banner_lbl: Label
var tip: PanelContainer
var tip_text: RichTextLabel
var aichip: Label
var plates_root: Control
var plates := {}                    # unit id -> Control
var tipcard: PanelContainer
var endcard: PanelContainer
var hint: Label
var _banner_t := 0.0
var _banner_dur := 0.0
var toast_lbl: Label
var _toast_t := 0.0
var legend: PanelContainer
var legend_open := false
var _legend := {}                   # {title, desc, rows: [[name, colour, effect]]}


func _ready() -> void:
	layer = 10
	font = _font("BarlowSemiCondensed-Regular.ttf")
	font_semi = _font("BarlowSemiCondensed-SemiBold.ttf")
	font_goth = Brand.display()
	font_caps = Brand.caps()
	k = scale_for(get_viewport().get_visible_rect().size)
	_built_vs = get_viewport().get_visible_rect().size
	_build_all()


# the UI scale for a window: its height over 1080 (the design size), within 0.6 and 2.2
static func scale_for(vs: Vector2) -> float:
	return clampf(vs.y / 1080.0, 0.6, 2.2)


var _built_vs := Vector2.ZERO       # the window size the HUD was built for
var _resize_t := -1.0               # counts down to a rebuild after the window size changes
var _last := {}                     # the last call of each setter, replayed after a rebuild


func _build_all() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
	if plates_root == null:
		plates_root = Control.new()
		plates_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		plates_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plates_root)
	_build_top()
	_build_roster()
	_build_panel()
	_build_log()
	_build_banner()
	_build_tip()
	_build_chip()
	_build_hint()
	_build_legend()
	_build_phase()
	_build_card()


# the window changed size: build every part again at the new scale and put back what each part showed. The battle log's
# text, the floating callouts and the grid button move across as they are; nameplates are made again on the next frame.
func _rebuild() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_vs = vs
	var nk := scale_for(vs)
	if absf(nk - k) < 0.004 or root == null:
		return
	var keep := {"retreat_v": retreat_btn.visible, "retreat_d": retreat_btn.disabled, "hint": hint.visible,
		"banner": banner_lbl.text, "banner_col": banner_lbl.get_theme_color("font_color"), "banner_a": banner_lbl.modulate.a,
		"toast": toast_lbl.text, "toast_a": toast_lbl.modulate.a}
	if _grid_btn != null and is_instance_valid(_grid_btn) and _grid_btn.get_parent() != null:
		_grid_btn.get_parent().remove_child(_grid_btn)
	plates_root.get_parent().remove_child(plates_root)
	for id in plates:
		(plates[id] as Control).queue_free()
	plates.clear()
	log_text.get_parent().remove_child(log_text)
	remove_child(root)
	root.queue_free()
	menu = null
	endcard = null
	tipcard = null
	bars = []
	load_cover = null
	_card_sig = ""
	_card_gen += 1
	_phase_fs = -1
	_heights = {}
	k = nk
	_build_all()
	retreat_btn.visible = keep["retreat_v"]
	retreat_btn.disabled = keep["retreat_d"]
	for key in ["set_crest", "set_command", "set_top", "set_roster", "set_panel", "set_legend", "set_chip", "set_phase", "set_card"]:
		if _last.has(key):
			callv(key, _last[key])
	hint.visible = keep["hint"]
	if _last.has("show_tipcard"):
		callv("show_tipcard", _last["show_tipcard"])
	if _last.has("show_menu"):
		callv("show_menu", _last["show_menu"])
	if _last.has("show_end"):
		callv("show_end", _last["show_end"])
	if bool(_last.get("letterbox", false)):
		letterbox(true)
	if bool(_last.get("loading", false)):
		loading(true)
	banner_lbl.text = keep["banner"]
	banner_lbl.add_theme_color_override("font_color", keep["banner_col"])
	banner_lbl.modulate.a = keep["banner_a"]
	toast_lbl.text = keep["toast"]
	toast_lbl.modulate.a = keep["toast_a"]
	print("[hud] rebuilt for %d x %d (scale %.3f)" % [int(vs.x), int(vs.y), k])
	rescaled.emit()


# true when the project has been imported (or exported) and the imported data for this file is really there; a project
# copied without its .godot folder keeps the .import files but not the data, and load() would fail
static func imported_ok(p: String) -> bool:
	var ip := p + ".import"
	if not FileAccess.file_exists(ip):
		return false
	for line in FileAccess.get_file_as_string(ip).split("\n"):
		if line.begins_with("path=") or line.begins_with("path."):
			var q := line.substr(line.find("\"") + 1)
			q = q.substr(0, q.find("\""))
			return q != "" and FileAccess.file_exists(q)
	return false


func _font(name: String) -> FontFile:
	# the imported font when the project has been imported or exported, else the raw file
	var p := "res://ui/battle/fonts/" + name
	if imported_ok(p):
		var r = load(p)
		if r is FontFile:
			return r
	var f := FontFile.new()
	if FileAccess.file_exists(p):
		f.data = FileAccess.get_file_as_bytes(p)
	return f


func s(v: float) -> int:
	return int(round(v * k))


func _theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = s(15)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.133, 0.176, 0.267, 0.85)
	sb.border_color = IRON3
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(s(4))
	sb.content_margin_left = s(12)
	sb.content_margin_right = s(12)
	sb.content_margin_top = s(6)
	sb.content_margin_bottom = s(6)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = IRON3
	sbh.border_color = GILT2
	var sbd := sb.duplicate() as StyleBoxFlat
	sbd.bg_color = Color(0.133, 0.176, 0.267, 0.35)
	th.set_stylebox("normal", "Button", sb)
	th.set_stylebox("hover", "Button", sbh)
	th.set_stylebox("pressed", "Button", sbh)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_stylebox("disabled", "Button", sbd)
	th.set_color("font_color", "Button", BONE)
	th.set_color("font_hover_color", "Button", BONE)
	th.set_color("font_disabled_color", "Button", BONE3)
	th.set_font_size("font_size", "Button", s(14))
	th.set_color("font_color", "Label", BONE)
	th.set_color("default_color", "RichTextLabel", BONE)
	th.set_font("normal_font", "RichTextLabel", font)
	th.set_font("bold_font", "RichTextLabel", font_semi)
	th.set_font_size("normal_font_size", "RichTextLabel", s(14))
	th.set_font_size("bold_font_size", "RichTextLabel", s(14))
	return th


func _glass(radius := 6) -> StyleBoxFlat:
	var g := StyleBoxFlat.new()
	g.bg_color = GLASS
	g.border_color = Color(0.816, 0.651, 0.294, 0.2)
	g.set_border_width_all(1)
	g.set_corner_radius_all(s(radius))
	g.shadow_color = Color(0, 0, 0, 0.45)
	g.shadow_size = s(16)
	g.content_margin_left = s(12)
	g.content_margin_right = s(12)
	g.content_margin_top = s(8)
	g.content_margin_bottom = s(8)
	return g


func _panel(l: float, t: float, r: float, b: float, w := -1.0, h := -1.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _glass())
	root.add_child(p)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	# offsets: negative means "not anchored to that side"
	if l >= 0.0 and r >= 0.0:
		p.anchor_left = 0.0
		p.anchor_right = 1.0
		p.offset_left = s(l)
		p.offset_right = -s(r)
	elif l >= 0.0:
		p.anchor_left = 0.0
		p.anchor_right = 0.0
		p.offset_left = s(l)
		p.offset_right = s(l + w)
	else:
		p.anchor_left = 1.0
		p.anchor_right = 1.0
		p.offset_left = -s(r + w)
		p.offset_right = -s(r)
	if t >= 0.0 and b >= 0.0:
		p.anchor_top = 0.0
		p.anchor_bottom = 1.0
		p.offset_top = s(t)
		p.offset_bottom = -s(b)
	elif t >= 0.0:
		p.anchor_top = 0.0
		p.anchor_bottom = 0.0
		p.offset_top = s(t)
		p.offset_bottom = s(t + h)
	else:
		p.anchor_top = 1.0
		p.anchor_bottom = 1.0
		p.offset_top = -s(b + h)
		p.offset_bottom = -s(b)
	return p


func _label(txt: String, size := 15, col := BONE, f: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", s(size))
	l.add_theme_color_override("font_color", col)
	if f != null:
		l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(txt: String, act: String, arg: Variant = null, primary := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	if primary:
		var sb := StyleBoxFlat.new()
		sb.bg_color = GILT
		sb.border_color = GILT
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(s(4))
		sb.content_margin_left = s(14)
		sb.content_margin_right = s(14)
		sb.content_margin_top = s(6)
		sb.content_margin_bottom = s(6)
		var sh := sb.duplicate() as StyleBoxFlat
		sh.bg_color = Color("#e2bb62")
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sh)
		b.add_theme_stylebox_override("pressed", sh)
		b.add_theme_color_override("font_color", Color("#1c1405"))
		b.add_theme_color_override("font_hover_color", Color("#1c1405"))
		b.add_theme_font_override("font", font_semi)
	b.pressed.connect(func() -> void: action.emit(act, arg))
	return b


# ---------------------------------------------------------------- top bar

func _build_top() -> void:
	top = _panel(12, 12, 12, -1, -1, 52)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(12))
	top.add_child(row)
	crest = TextureRect.new()
	crest.custom_minimum_size = Vector2(s(36), s(36))
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.visible = false
	row.add_child(crest)
	title_lbl = _label("Round 1", 21, BONE, font_goth)
	row.add_child(title_lbl)
	turn_lbl = _label("", 17, BONE2, font_semi)
	turn_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(turn_lbl)
	# the objective takes the room the buttons leave and ends in "..." when there is not enough, so the buttons on the
	# right are never pushed off the screen (the Speed and End ship buttons were cut off)
	obj_lbl = _label("", 15, GILT)
	obj_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	obj_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obj_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	obj_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(obj_lbl)
	top_row = row
	cmd_btn = _button("Command", "command")
	cmd_btn.visible = false
	row.add_child(cmd_btn)
	retreat_btn = _button("Retreat", "retreat")
	retreat_btn.visible = false
	row.add_child(retreat_btn)
	# board look C's "Grid (Z)" button (board.gd) lives here, in the top bar, once the battle hands it over (adopt_grid)
	if _grid_btn != null and is_instance_valid(_grid_btn):
		_grid_btn.add_theme_font_size_override("font_size", s(14))
		row.add_child(_grid_btn)
	threat_btn = _button("Threat (R)", "threat")
	row.add_child(threat_btn)
	row.add_child(_button("Top-down (T)", "top"))
	row.add_child(_button("Menu", "menu"))
	speed_btn = _button("Speed: normal", "speed")
	row.add_child(speed_btn)
	end_btn = _button("End activation", "end", null, true)
	row.add_child(end_btn)


var top_row: HBoxContainer
var _grid_btn: Button


# board look C's "Grid (Z)" toggle (board.gd makes it on its own layer at a fixed spot, where the ship panel covered it):
# moved into the top bar before Threat, at the HUD's size. board.gd still owns its state, text and when it shows.
func adopt_grid(b: Button) -> void:
	if b == null or not is_instance_valid(b) or top_row == null:
		return
	if _grid_btn == b and b.get_parent() == top_row:
		return
	_grid_btn = b
	if b.get_parent() != null:
		b.get_parent().remove_child(b)
	b.set_anchors_preset(Control.PRESET_TOP_LEFT)
	b.offset_left = 0
	b.offset_top = 0
	b.offset_right = 0
	b.offset_bottom = 0
	b.text = "Grid (Z)"
	b.add_theme_font_size_override("font_size", s(14))
	top_row.add_child(b)
	top_row.move_child(b, threat_btn.get_index())


# your admiral's crest (godot/portraits) at the left of the top bar
func set_crest(tex: Texture2D, tip: String) -> void:
	_last["set_crest"] = [tex, tip]
	crest.texture = tex
	crest.visible = tex != null
	crest.tooltip_text = tip


func set_command(label: String, ready: bool) -> void:
	_last["set_command"] = [label, ready]
	cmd_btn.visible = ready
	cmd_btn.text = "Command: " + label
	cmd_btn.add_theme_color_override("font_color", GILT)


func set_top(round_n: int, turn: String, objective: String, end_text: String, end_on: bool, speed_fast: bool, threat_on: bool) -> void:
	_last["set_top"] = [round_n, turn, objective, end_text, end_on, speed_fast, threat_on]
	title_lbl.text = "Round %d" % round_n
	turn_lbl.text = turn
	obj_lbl.text = objective
	obj_lbl.tooltip_text = objective
	end_btn.text = end_text
	end_btn.disabled = not end_on
	speed_btn.text = "Speed: fast" if speed_fast else "Speed: normal"
	threat_btn.add_theme_color_override("font_color", GILT if threat_on else BONE)


# ---------------------------------------------------------------- roster (your fleet)

func _build_roster() -> void:
	roster = _panel(12, 76, -1, -1, 250, 10)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.x = s(226)
	roster_sc = sc
	roster.add_child(sc)
	roster_box = VBoxContainer.new()
	roster_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_box.add_theme_constant_override("separation", s(3))
	sc.add_child(roster_box)


# a side panel is as tall as what it holds, up to max_h (then it scrolls)
func _fit(sc: ScrollContainer, box: VBoxContainer, p: PanelContainer, max_h: float) -> void:
	await get_tree().process_frame
	if not is_instance_valid(box) or not is_instance_valid(p):
		return
	_heights[p] = box.get_combined_minimum_size().y
	_apply_heights()


var _heights := {}                  # side panel -> the height of what it holds


# each side panel is as tall as what it holds, but stops short of the parts below it (the log under the fleet list; the
# activation card when it reaches under the ship panel); past that it scrolls
func _apply_heights() -> void:
	var vs := root.get_viewport_rect().size
	var gap := float(s(8))
	for p in [roster, panel]:
		if not _heights.has(p):
			continue
		var pr: Rect2 = (p as Control).get_global_rect()
		var bottom := vs.y - s(12)
		var below: Array = [card]
		if p == roster:
			below.append(log_panel)
		for c in below:
			if c != null and c.visible and c.modulate.a > 0.01:
				var cr: Rect2 = c.get_global_rect()
				if cr.position.x < pr.end.x and cr.end.x > pr.position.x:
					bottom = minf(bottom, cr.position.y - gap)
		var sc: ScrollContainer = roster_sc if p == roster else panel_sc
		var room := maxf(float(s(60)), bottom - pr.position.y - float(s(16)))
		var h := minf(float(_heights[p]), room)
		if absf(sc.custom_minimum_size.y - h) > 0.5:
			sc.custom_minimum_size.y = h
			(p as Control).reset_size()


func set_roster(rows: Array) -> void:
	_last["set_roster"] = [rows]
	# rows: [{id, name, cls, hp, maxHp, sh: [4], shMax, status, sel, done, flag}]
	for c in roster_box.get_children():
		roster_box.remove_child(c)
		c.queue_free()
	_fit(roster_sc, roster_box, roster, get_viewport().get_visible_rect().size.y - s(76 + 160))
	var head := _label("YOUR FLEET", 13, GILT, font_caps)
	roster_box.add_child(head)
	for r in rows:
		var card := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.176, 0.227, 0.337, 0.55) if r["sel"] else Color(0, 0, 0, 0)
		sb.border_color = GILT if r["sel"] else Color(0, 0, 0, 0)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(s(4))
		sb.content_margin_left = s(9)
		sb.content_margin_right = s(9)
		sb.content_margin_top = s(6)
		sb.content_margin_bottom = s(6)
		card.add_theme_stylebox_override("panel", sb)
		card.modulate.a = 0.5 if r["done"] else 1.0
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var id = r["id"]
		card.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				action.emit("pick", id))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", s(2))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nm := _label(("★ " if r["flag"] else "") + str(r["name"]), 15, BONE, font_semi)
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.custom_minimum_size.x = s(130)
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		var stc := GILT if r["status"] in ["Up", "Acting"] else (VERD if r["status"] == "Ready" else BONE2)
		row.add_child(_label(str(r["status"]), 13, stc, font_semi if stc != BONE2 else null))
		if r.get("new", false):
			row.add_child(_label(" NEW", 12, EMBER, font_semi))
		v.add_child(row)
		v.add_child(_label(str(r["cls"]), 13, BONE2))
		v.add_child(_hull_bar(float(r["hp"]), float(r["maxHp"]), 5))
		if float(r["shMax"]) > 0.0:
			v.add_child(_shield_quads(r["sh"], float(r["shMax"])))
		roster_box.add_child(card)


func _hull_bar(hp: float, mx: float, h: int) -> Control:
	var bg := ColorRect.new()
	bg.color = Color("#3a1d1d")
	bg.custom_minimum_size = Vector2(0, s(h))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fg := ColorRect.new()
	var f := clampf(hp / maxf(mx, 1.0), 0.0, 1.0)
	fg.color = HULL_LOW if f < 0.34 else HULL
	fg.anchor_right = f
	fg.anchor_bottom = 1.0
	fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fg)
	return bg


func _shield_quads(sh: Array, mx: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(3))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the game's order on the strip: prow, starboard, rear, port (sh[0..3])
	for i in 4:
		var c := ColorRect.new()
		c.custom_minimum_size = Vector2(0, s(3))
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var f := clampf(float(sh[i]) / maxf(mx, 1.0), 0.0, 1.0)
		c.color = SHIELD.lerp(IRON3, 1.0 - f) if f > 0.02 else IRON3
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(c)
	return row


# ---------------------------------------------------------------- ship panel

func _build_panel() -> void:
	panel = _panel(-1, 76, 12, -1, 340, 10)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.x = s(316)
	panel_sc = sc
	panel.add_child(sc)
	panel_box = VBoxContainer.new()
	panel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_box.add_theme_constant_override("separation", s(6))
	sc.add_child(panel_box)


func set_panel(info: Dictionary) -> void:
	_last["set_panel"] = [info]
	for c in panel_box.get_children():
		panel_box.remove_child(c)
		c.queue_free()
	_fit(panel_sc, panel_box, panel, get_viewport().get_visible_rect().size.y - s(76 + 24))
	if info.is_empty():
		panel_box.add_child(_rich("[color=#b3aa95]Select one of your ships, or hover an enemy to see it.[/color]\n\n" + keys_text()))
		return
	var nm := _label(("★ " if info.get("flag", false) else "") + str(info["name"]), 21, FRIEND if info["side"] == "player" else FOE, font_semi)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_box.add_child(nm)
	panel_box.add_child(_label(str(info["cls"]), 14, BONE2))
	if str(info.get("captain", "")) != "":
		panel_box.add_child(_rich("[font_size=%d]%s[/font_size]" % [s(13), str(info["captain"])]))
	panel_box.add_child(_hull_bar(float(info["hp"]), float(info["maxHp"]), 7))
	if info.get("secs") is Array and not (info["secs"] as Array).is_empty():
		var sg := GridContainer.new()
		sg.columns = (info["secs"] as Array).size()
		sg.add_theme_constant_override("h_separation", s(6))
		for sc in info["secs"]:
			var sv := VBoxContainer.new()
			sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sv.add_theme_constant_override("separation", s(1))
			sv.add_child(_label(str(sc[0]), 12, BLOOD if float(sc[1]) <= 0.0 else BONE2))
			sv.add_child(_hull_bar(float(sc[1]), float(sc[2]), 4))
			sg.add_child(sv)
		panel_box.add_child(sg)
	if float(info["shMax"]) > 0.0:
		panel_box.add_child(_shield_quads(info["sh"], float(info["shMax"])))
	panel_box.add_child(_rich(info["stats"]))
	if info.has("note") and str(info["note"]) != "":
		panel_box.add_child(_rich(info["note"]))
	if info.has("weapons"):
		panel_box.add_child(_sect("Weapons"))
		for w in info["weapons"]:
			panel_box.add_child(_weapon_row(w))
	if info.has("orders"):
		panel_box.add_child(_sect("Orders"))
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", s(5))
		g.add_theme_constant_override("v_separation", s(5))
		for o in info["orders"]:
			var b := _button(o["text"], o["act"], o.get("arg"))
			b.disabled = not o.get("on", true)
			b.tooltip_text = o.get("tip", "")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			g.add_child(b)
		panel_box.add_child(g)
	for ex in info.get("extra", []):
		panel_box.add_child(_sect(str(ex[0])))
		panel_box.add_child(_rich("[font_size=%d]%s[/font_size]" % [s(13), str(ex[1])]))
	if info.get("side", "") == "player":
		panel_box.add_child(_rich("\n" + keys_text()))


func keys_text() -> String:
	return "[font_size=%d][color=#b3aa95]Click a blue hex to plan a move, click it again (or [b]Enter[/b]) to go. Click an enemy to target it and see the odds, click it again (or [b]Enter[/b]) to fire. [b]Q[/b]/[b]E[/b] turn, [b]1[/b]-[b]6[/b] pick one weapon, [b]B[/b] brace, [b]X[/b] ram, [b]G[/b] board, [b]Tab[/b] next ship, [b]Space[/b] end ship, [b]Esc[/b] cancel the plan. In the enemy turn [b]Enter[/b] or [b]Space[/b] hurries. Right-drag orbit, left-drag or WASD pan, wheel zoom, [b]T[/b] top-down, [b]R[/b] threat map, [b]V[/b] firing arcs, [b]F[/b] focus, [b]Home[/b] reset view.[/color][/font_size]" % s(12)


func _sect(t: String) -> Control:
	var v := VBoxContainer.new()
	var line := ColorRect.new()
	line.color = Color(0.176, 0.227, 0.337, 0.8)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	v.add_child(_label(t.to_upper(), 13, GILT, font_caps))
	return v


func _weapon_row(w: Dictionary) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.133, 0.176, 0.267, 0.6)
	sb.border_color = EMBER if w.get("armed", false) else IRON3
	sb.set_border_width_all(2 if w.get("armed", false) else 1)
	sb.set_corner_radius_all(s(4))
	sb.content_margin_left = s(8)
	sb.content_margin_right = s(8)
	sb.content_margin_top = s(5)
	sb.content_margin_bottom = s(5)
	p.add_theme_stylebox_override("panel", sb)
	p.modulate.a = 1.0 if w.get("ready", true) else 0.45
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	var idx = w["i"]
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			action.emit("arm", idx))
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := _label("%d  %s" % [int(idx) + 1, w["name"]], 14, BONE, font_semi)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	row.add_child(_label(str(w.get("right", "")), 14, EMBER if str(w.get("right", "")).ends_with("%") else BONE2, font_semi))
	v.add_child(row)
	var d := _label(str(w["desc"]), 12, BONE2)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(d)
	return p


func _rich(bb: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", s(14))
	r.add_theme_font_size_override("bold_font_size", s(14))
	return r


# ---------------------------------------------------------------- log, banner, tip, chip, hint

func _build_log() -> void:
	log_panel = _panel(12, -1, -1, 12, 430, 126)
	if log_text != null and is_instance_valid(log_text):   # a rebuild keeps the log's text
		log_text.add_theme_font_size_override("normal_font_size", s(13))
		log_text.add_theme_font_size_override("bold_font_size", s(13))
		log_panel.add_child(log_text)
		return
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.add_theme_font_size_override("normal_font_size", s(13))
	log_text.add_theme_font_size_override("bold_font_size", s(13))
	log_panel.add_child(log_text)


const LOG_COL := {"p": "#5fb3a6", "e": "#e27f74", "s": "#d0a64b", "x": "#b3aa95", "ember": "#f0b35a"}


func add_log(m: String, c: String) -> void:
	var txt := m.replace("[", "(").replace("]", ")")
	# the game's colouring: shield damage cyan, hull damage amber
	var re := RegEx.new()
	re.compile("(\\d+) to (\\w+) shields")
	txt = re.sub(txt, "[color=#62ccff]$1 to $2 shields[/color]", true)
	re.compile("(\\d+) hull")
	txt = re.sub(txt, "[color=#ffae42]$1 hull[/color]", true)
	var col: String = LOG_COL.get(c, "#e6dcc4")
	log_text.append_text("[color=%s]%s[/color]\n" % [col, txt])


func _build_banner() -> void:
	banner_lbl = _label("", 46, BONE, font_goth)
	banner_lbl.set_anchors_preset(Control.PRESET_CENTER)
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	banner_lbl.add_theme_constant_override("shadow_offset_x", 0)
	banner_lbl.add_theme_constant_override("shadow_offset_y", s(3))
	banner_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner_lbl.modulate.a = 0.0
	root.add_child(banner_lbl)
	toast_lbl = _label("", 16, EMBER, font_semi)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = s(124)
	toast_lbl.offset_bottom = s(150)
	toast_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	toast_lbl.modulate.a = 0.0
	root.add_child(toast_lbl)


func banner(text: String, col := BONE, dur := 0.9) -> void:
	banner_lbl.text = text
	banner_lbl.add_theme_font_size_override("font_size", Brand.fit_size(text, font_goth, s(46), _column().y - _column().x - s(24)))
	banner_lbl.add_theme_color_override("font_color", col)
	_banner_t = 0.0
	_banner_dur = dur


func toast(text: String) -> void:
	toast_lbl.text = text
	_toast_t = 2.6 if text != "" else 0.0
	if text == "":
		toast_lbl.modulate.a = 0.0


func _build_tip() -> void:
	tip = PanelContainer.new()
	var g := _glass(5)
	g.bg_color = Color(0.047, 0.07, 0.12, 0.94)
	tip.add_theme_stylebox_override("panel", g)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip_text = RichTextLabel.new()
	tip_text.bbcode_enabled = true
	tip_text.fit_content = true
	tip_text.scroll_active = false
	tip_text.custom_minimum_size = Vector2(s(300), 0)
	tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(tip_text)
	root.add_child(tip)


func show_tip(bb: String, at: Vector2) -> void:
	if bb == "":
		tip.visible = false
		return
	if tip_text.text != bb:
		tip_text.text = bb
	tip.visible = true
	tip.reset_size()
	_tip_at = at
	_place_tip()


var _tip_at := Vector2.ZERO


# the hover tip beside the cursor, kept inside the middle column (never over the fleet list or the ship panel) and off
# the card, the log, the strip and the tip card (it moves above whichever it would cover, or below when there is no room)
func _place_tip() -> void:
	var vs := root.get_viewport_rect().size
	var col := _column()
	var w := tip.size.x
	var h := tip.size.y
	var gap := float(s(8))
	var p := _tip_at + Vector2(s(18), s(18))
	if p.x + w > col.y:
		p.x = _tip_at.x - w - s(18)
	p.x = clampf(p.x, col.x, maxf(col.x, col.y - w))
	var t := top.get_global_rect().end.y + gap
	p.y = clampf(p.y, t, maxf(t, vs.y - h - gap))
	for i in 3:
		var moved := false
		for c in [card, log_panel, tipcard, phase, legend, aichip]:
			if c == null or not is_instance_valid(c) or not c.visible or c.modulate.a < 0.01:
				continue
			var cr: Rect2 = c.get_global_rect()
			if Rect2(p, Vector2(w, h)).intersects(cr):
				p.y = cr.position.y - h - gap if cr.position.y - h - gap >= t else cr.end.y + gap
				moved = true
		if not moved:
			break
	tip.position = p.round()


# the middle column between the fleet list and the ship panel: Vector2(left x, right x)
func _column() -> Vector2:
	var vs := root.get_viewport_rect().size
	var gap := float(s(10))
	var l := float(s(12))
	var r := vs.x - s(12)
	if roster != null and roster.visible:
		l = roster.get_global_rect().end.x + gap
	if panel != null and panel.visible:
		r = panel.get_global_rect().position.x - gap
	return Vector2(l, maxf(l + s(200), r))


func _build_chip() -> void:
	aichip = _label("", 15, Color("#e2d2ff"))
	aichip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	aichip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aichip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aichip.offset_top = s(70)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.086, 0.04, 0.157, 0.88)
	sb.border_color = Color("#a64dff")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(s(14))
	sb.content_margin_left = s(14)
	sb.content_margin_right = s(14)
	sb.content_margin_top = s(5)
	sb.content_margin_bottom = s(5)
	aichip.add_theme_stylebox_override("normal", sb)
	aichip.visible = false
	root.add_child(aichip)


func set_chip(txt: String) -> void:
	_last["set_chip"] = [txt]
	aichip.text = txt
	aichip.visible = txt != ""


func _build_hint() -> void:
	hint = _label("Right-drag orbit   Left-drag or WASD pan   Wheel zoom   T top-down   R threat   V arcs   Tab next ship   Space end ship", 13, BONE2)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.offset_top = -s(34)
	hint.offset_bottom = -s(14)
	root.add_child(hint)


# ---------------------------------------------------------------- terrain legend (ui3d.js refreshLegend)
# Only what is on this battlefield: the encounter, its zones and its terrain. Collapsed it is a chip of swatches beside
# your fleet list; a click opens the names and what each does (and the encounter's own rule), another click closes it.

func _build_legend() -> void:
	legend = _panel(274, 76, -1, -1, 380, 10)
	legend.visible = false
	legend.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	legend.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			legend_open = not legend_open
			_draw_legend()
			legend.accept_event())


func set_legend(title: String, desc: String, rows: Array) -> void:
	_last["set_legend"] = [title, desc, rows]
	_legend = {"title": title, "desc": desc, "rows": rows}
	_draw_legend()


func _swatch(col: String) -> Control:
	var c := ColorRect.new()
	c.color = Color(col)
	c.custom_minimum_size = Vector2(s(12), s(12))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _draw_legend() -> void:
	for c in legend.get_children():
		legend.remove_child(c)
		c.queue_free()
	var rows: Array = _legend.get("rows", [])
	var title: String = _legend.get("title", "")
	if rows.is_empty() and title == "":
		legend.visible = false
		return
	legend.visible = true
	if not legend_open:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", s(6))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(_label(title if title != "" else "Terrain", 14, BONE2))
		for r in rows:
			h.add_child(_swatch(str(r[1])))
		h.add_child(_label("▾", 14, BONE3))
		legend.add_child(h)
		legend.offset_right = legend.offset_left + h.get_combined_minimum_size().x + s(24)
		legend.reset_size()
		return
	legend.offset_right = legend.offset_left + s(380)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bb := "[b][color=#d0a64b]%s[/color][/b] [color=#7d7768](click to close)[/color]" % (title if title != "" else "Terrain")
	if str(_legend.get("desc", "")) != "":
		bb += "\n[color=#b3aa95]%s[/color]" % str(_legend["desc"])
	var head := _rich(bb)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.custom_minimum_size.x = s(352)
	v.add_child(head)
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", s(8))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(_swatch(str(r[1])))
		var t := _rich("[b]%s[/b] %s" % [str(r[0]), str(r[2])])
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size.x = s(332)
		h.add_child(t)
		v.add_child(h)
	legend.add_child(v)
	legend.reset_size()


# ---------------------------------------------------------------- nameplates

func plate(id: String) -> Control:
	if plates.has(id):
		return plates[id]
	var c := VBoxContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_constant_override("separation", s(2))
	var nm := _label("", 14, BONE, font_semi)
	nm.name = "nm"
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	nm.add_theme_constant_override("shadow_offset_y", s(1))
	c.add_child(nm)
	var hb := ColorRect.new()
	hb.name = "hb"
	hb.color = Color(0.1, 0.06, 0.06, 0.8)
	hb.custom_minimum_size = Vector2(s(90), s(4))
	hb.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hf := ColorRect.new()
	hf.name = "f"
	hf.color = HULL
	hf.anchor_bottom = 1.0
	hb.add_child(hf)
	c.add_child(hb)
	var sbar := ColorRect.new()
	sbar.name = "sb"
	sbar.color = Color(0.05, 0.08, 0.12, 0.8)
	sbar.custom_minimum_size = Vector2(s(90), s(3))
	sbar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sf := ColorRect.new()
	sf.name = "f"
	sf.color = SHIELD
	sf.anchor_bottom = 1.0
	sbar.add_child(sf)
	c.add_child(sbar)
	plates_root.add_child(c)
	plates[id] = c
	return c


func set_plate(id: String, screen: Vector2, on: bool, name_txt: String, friend: bool, flag: bool, hp: float, mx: float, sh: float, shmx: float, up := false) -> void:
	var c := plate(id)
	c.visible = on
	if not on:
		return
	var nm := c.get_node("nm") as Label
	# F1: the ship that is up reads at a glance: a gold marker and a bigger name
	nm.text = ("▼ UP  " if up else "") + ("★ " if flag else "") + name_txt
	nm.add_theme_color_override("font_color", GILT if up else (FRIEND if friend else FOE))
	nm.add_theme_font_size_override("font_size", s(17) if up else s(14))
	var hf := c.get_node("hb/f") as ColorRect
	var f := clampf(hp / maxf(mx, 1.0), 0.0, 1.0)
	hf.anchor_right = f
	hf.color = HULL_LOW if f < 0.34 else HULL
	var sbar := c.get_node("sb") as ColorRect
	sbar.visible = shmx > 0.0
	(c.get_node("sb/f") as ColorRect).anchor_right = clampf(sh / maxf(shmx, 1.0), 0.0, 1.0)
	c.reset_size()
	c.position = screen - Vector2(c.size.x * 0.5, c.size.y)


# F1: nameplate declutter, once a frame after every plate is placed. prio: id -> 3 (up, targeted), 2 (hovered, acting),
# 1 (flagship), 0. Highest first, then nearer the camera (lower on screen); a name of rank under 2 that would overlap a
# name or bars already shown is hidden, and if its bars would overlap too, the whole plate is. Any plate whose name or
# bars would sit under a HUD panel is hidden whole, whatever its rank (the panels are see-through, so a name under one
# printed across the panel's own text, and a lone bar beside a panel reads as a glitch; the up ship and the target are
# named in the activation card anyway).
var plates_hidden := 0


# screen rects of the HUD panels a ship name must not sit under
func hud_blockers() -> Array:
	var out: Array = []
	for p in [top, roster, panel, log_panel, card, tipcard, phase, legend]:
		if p != null and is_instance_valid(p) and (p as Control).is_visible_in_tree():
			out.append((p as Control).get_global_rect())
	return out


func declutter_plates(prio: Dictionary) -> void:
	var blockers := hud_blockers()
	var items: Array = []
	for id in plates:
		var c: Control = plates[id]
		c.modulate.a = 1.0
		(c.get_node("nm") as Control).modulate.a = 1.0
		if c.visible:
			items.append([int(prio.get(id, 0)), c.position.y + c.size.y, id])
	items.sort_custom(func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1] > b[1])
	var shown: Array = []
	plates_hidden = 0
	for it in items:
		var c: Control = plates[it[2]]
		var nm := c.get_node("nm") as Label
		var tw := nm.get_minimum_size().x
		var nr := Rect2(c.position + Vector2((c.size.x - tw) * 0.5, 0), Vector2(tw, nm.size.y)).grow(s(2))
		var bw := float(s(90))
		var br := Rect2(c.position + Vector2((c.size.x - bw) * 0.5, nm.size.y), Vector2(bw, maxf(c.size.y - nm.size.y, 1.0)))
		if _hits_any(nr, blockers) or _hits_any(br, blockers):
			c.modulate.a = 0.0
			plates_hidden += 1
			continue
		if int(it[0]) >= 2:
			# a name that must stay: lift its plate above whatever it would cover (at most a few steps)
			for k in 4:
				var hit := Rect2()
				var any := false
				for x in shown:
					if nr.intersects(x) or br.intersects(x):
						hit = x
						any = true
						break
				if not any:
					break
				var dy: float = (nr.position.y + nr.size.y + br.size.y) - hit.position.y + s(2)
				c.position.y -= dy
				nr.position.y -= dy
				br.position.y -= dy
			if _hits_any(nr, blockers) or _hits_any(br, blockers):
				c.modulate.a = 0.0
				plates_hidden += 1
				continue
			shown.append(nr)
			shown.append(br)
			continue
		if _hits_any(br, shown):
			c.modulate.a = 0.0
			plates_hidden += 1
			continue
		if _hits_any(nr, shown):
			nm.modulate.a = 0.0
			plates_hidden += 1
		else:
			shown.append(nr)
		shown.append(br)


func _hits_any(r: Rect2, rs: Array) -> bool:
	for x in rs:
		if r.intersects(x):
			return true
	return false


# for the trace: visible names that overlap another visible name (0 after the declutter)
func plate_name_overlaps() -> int:
	var rs: Array = []
	for id in plates:
		var c: Control = plates[id]
		var nm := c.get_node("nm") as Label
		if c.visible and c.modulate.a > 0.5 and nm.modulate.a > 0.5 and nm.text != "":
			var tw := nm.get_minimum_size().x
			rs.append(Rect2(c.position + Vector2((c.size.x - tw) * 0.5, 0), Vector2(tw, nm.size.y)))
	var n := 0
	for i in rs.size():
		for j in range(i + 1, rs.size()):
			if (rs[i] as Rect2).intersects(rs[j]):
				n += 1
	return n


# for the trace: visible ship names or bars that sit under a HUD panel
func plate_names_under_panels() -> int:
	var blockers := hud_blockers()
	var n := 0
	for id in plates:
		var c: Control = plates[id]
		var nm := c.get_node("nm") as Label
		if not c.visible or c.modulate.a <= 0.5:
			continue
		var tw := nm.get_minimum_size().x
		var bw := float(s(90))
		var nr := Rect2(c.position + Vector2((c.size.x - tw) * 0.5, 0), Vector2(tw, nm.size.y))
		var br := Rect2(c.position + Vector2((c.size.x - bw) * 0.5, nm.size.y), Vector2(bw, maxf(c.size.y - nm.size.y, 1.0)))
		if (nm.modulate.a > 0.5 and nm.text != "" and _hits_any(nr, blockers)) or _hits_any(br, blockers):
			n += 1
	return n


# a floating callout over a ship ("-12 shield", "Miss", "Critical"); the battle scene moves and fades it
func make_float(text: String, col: Color) -> Label:
	var l := _label(text, 16, col, font_semi)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_y", s(2))
	l.add_theme_constant_override("outline_size", s(3))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	plates_root.add_child(l)
	l.reset_size()
	return l


func remove_plate(id: String) -> void:
	if plates.has(id):
		(plates[id] as Control).queue_free()
		plates.erase(id)


# ---------------------------------------------------------------- onboarding tip card and end card

func show_tipcard(id: String, title: String, body: String) -> void:
	hide_tipcard()
	_last["show_tipcard"] = [id, title, body]
	tipcard = _panel(-1, 76, 364, -1, 360, -1)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(8))
	tipcard.add_child(v)
	v.add_child(_label(title, 17, GILT, font_semi))
	var b := _rich(body)
	b.custom_minimum_size = Vector2(s(330), 0)
	v.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(8))
	row.add_child(_button("Got it", "tip_ok", id, true))
	row.add_child(_button("Hide tips", "tip_off"))
	v.add_child(row)


func hide_tipcard() -> void:
	_last.erase("show_tipcard")
	if tipcard != null:
		tipcard.queue_free()
		tipcard = null


func show_end(title: String, body: String, win: bool, external := false) -> void:
	_last["show_end"] = [title, body, win, external]
	endcard = PanelContainer.new()
	var g := _glass(8)
	g.content_margin_left = s(36)
	g.content_margin_right = s(36)
	g.content_margin_top = s(28)
	g.content_margin_bottom = s(28)
	endcard.add_theme_stylebox_override("panel", g)
	endcard.set_anchors_preset(Control.PRESET_CENTER)
	endcard.grow_horizontal = Control.GROW_DIRECTION_BOTH
	endcard.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(endcard)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(12))
	endcard.add_child(v)
	var t := _label(title, 34, GILT if win else BLOOD, font_goth)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := _label(body, 16, BONE2)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(s(520), 0)
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", s(10))
	if external:
		row.add_child(_button("Continue", "continue", null, true))
	else:
		row.add_child(_button("Fight again", "restart", null, true))
		row.add_child(_button("Quit", "quit"))
	v.add_child(row)


# the in-battle menu (Esc with nothing to cancel, or Menu in the top bar): items are [text, action, arg]
var menu: PanelContainer


func show_menu(title: String, items: Array) -> void:
	hide_menu()
	_last["show_menu"] = [title, items]
	menu = PanelContainer.new()
	var g := _glass(8)
	g.content_margin_left = s(28)
	g.content_margin_right = s(28)
	g.content_margin_top = s(20)
	g.content_margin_bottom = s(20)
	menu.add_theme_stylebox_override("panel", g)
	menu.set_anchors_preset(Control.PRESET_CENTER)
	menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(8))
	v.custom_minimum_size = Vector2(s(320), 0)
	menu.add_child(v)
	var t := _label(title, 24, GILT, font_goth)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for it in items:
		v.add_child(_button(str(it[0]), str(it[1]), it[2] if it.size() > 2 else null, it == items[0]))


# cut-in letterbox bars
var bars: Array = []


func letterbox(on: bool) -> void:
	_last["letterbox"] = on
	if bars.is_empty():
		for top_bar in [true, false]:
			var b := ColorRect.new()
			b.color = Color(0, 0, 0, 1)
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.anchor_left = 0.0
			b.anchor_right = 1.0
			b.anchor_top = 0.0 if top_bar else 0.91
			b.anchor_bottom = 0.09 if top_bar else 1.0
			b.visible = false
			root.add_child(b)
			bars.append(b)
	for b in bars:
		(b as ColorRect).visible = on
	for c in [top, roster, panel, log_panel]:
		if c != null:
			c.modulate.a = 0.0 if on else 1.0


# the loading cover while the battle warms up its shaders
var load_cover: ColorRect


func loading(on: bool) -> void:
	_last["loading"] = on
	if on and load_cover == null:
		load_cover = ColorRect.new()
		load_cover.color = Color(0.02, 0.025, 0.04, 1.0)
		load_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		load_cover.mouse_filter = Control.MOUSE_FILTER_STOP
		var l := _label("Preparing the battle...", 22, GILT, font_goth)
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.grow_vertical = Control.GROW_DIRECTION_BOTH
		load_cover.add_child(l)
		root.add_child(load_cover)
	elif not on and load_cover != null:
		load_cover.queue_free()
		load_cover = null


func hide_menu() -> void:
	_last.erase("show_menu")
	if menu != null:
		menu.queue_free()
		menu = null


func hide_end() -> void:
	_last.erase("show_end")
	if endcard != null:
		endcard.queue_free()
		endcard = null


func _process(dt: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	if vs != _built_vs:
		if _resize_t < 0.0:
			_resize_t = 0.12
		_resize_t -= dt
		if _resize_t <= 0.0 or Engine.get_process_frames() < 30:
			_resize_t = -1.0
			_rebuild()
	if root != null:
		_layout()
	if _banner_dur > 0.0:
		_banner_t += dt
		var a := 1.0
		if _banner_t < 0.18:
			a = _banner_t / 0.18
		elif _banner_t > _banner_dur:
			a = maxf(0.0, 1.0 - (_banner_t - _banner_dur) / 0.3)
		banner_lbl.modulate.a = a
		if _banner_t > _banner_dur + 0.3:
			_banner_dur = 0.0
	if _toast_t > 0.0:
		_toast_t -= dt
		toast_lbl.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


# Every frame: keep each part in its region (see the top of this file). Cheap: a handful of rects.
var _phase_fs := -1


func _layout() -> void:
	var vs := root.get_viewport_rect().size
	var gap := float(s(10))
	var col := _column()
	var band_top := top.get_global_rect().end.y + s(8)
	var band_bot := band_top
	# the legend chip sits at the left of the banner strip; the turn strip takes the room to its right
	var avail_l := col.x
	if legend != null and legend.visible:
		legend.position = Vector2(col.x, band_top + s(4)).round()
		var lr := legend.get_global_rect()
		avail_l = lr.end.x + gap
		if not legend_open:
			band_bot = maxf(band_bot, lr.end.y)
	var avail_w := maxf(float(s(200)), col.y - avail_l)
	if phase.visible:
		# the strip's text shrinks (down to 12) and then wraps to fit between the legend chip and the ship panel
		var plain := phase_lbl.get_parsed_text()
		var fs := s(16)
		var marg := float(s(36))
		while fs > s(12) and font_semi.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + marg > avail_w:
			fs -= 1
		if fs != _phase_fs:
			_phase_fs = fs
			phase_lbl.add_theme_font_size_override("normal_font_size", fs)
			phase_lbl.add_theme_font_size_override("bold_font_size", fs)
		var wide: bool = font_semi.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + marg > avail_w
		var want_wrap := TextServer.AUTOWRAP_WORD_SMART if wide else TextServer.AUTOWRAP_OFF
		var want_min := avail_w - marg if wide else 0.0
		if phase_lbl.autowrap_mode != want_wrap or absf(phase_lbl.custom_minimum_size.x - want_min) > 1.0:
			phase_lbl.autowrap_mode = want_wrap
			phase_lbl.custom_minimum_size.x = want_min
			phase.reset_size()
		if phase.size.x > phase.get_combined_minimum_size().x + 1.0:
			phase.reset_size()
		var w := phase.size.x
		var x := clampf(vs.x * 0.5 - w * 0.5, avail_l, maxf(avail_l, col.y - w))
		phase.position = Vector2(x, band_top).round()
		band_bot = maxf(band_bot, phase.position.y + phase.size.y)
	if aichip.visible:
		aichip.reset_size()
		var w := aichip.size.x
		var y := band_bot + s(6) if phase.visible else band_top
		aichip.position = Vector2(clampf(vs.x * 0.5 - w * 0.5, avail_l, maxf(avail_l, col.y - w)), y).round()
		band_bot = maxf(band_bot, aichip.position.y + aichip.size.y)
	var below := band_bot + s(8)
	# the onboarding tip card: right side of the middle column, under the strip
	if tipcard != null and is_instance_valid(tipcard):
		tipcard.position = Vector2(col.y - tipcard.size.x, below).round()
	# toasts: centred under the strip, below the tip card if they would meet
	if toast_lbl.modulate.a > 0.0:
		toast_lbl.reset_size()
		var w := toast_lbl.size.x
		var p := Vector2(clampf(vs.x * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), below)
		if tipcard != null and is_instance_valid(tipcard) and Rect2(p, toast_lbl.size).intersects(tipcard.get_global_rect()):
			p.y = tipcard.get_global_rect().end.y + s(8)
		toast_lbl.position = p.round()
	# the big banner: centred in the middle column
	if banner_lbl.modulate.a > 0.0:
		banner_lbl.reset_size()
		var w := banner_lbl.size.x
		banner_lbl.position = Vector2(clampf(vs.x * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), vs.y * 0.5 - banner_lbl.size.y * 0.5).round()
	# the bottom row: the card (or the key hint) between the battle log and the ship panel
	var bl := col.x
	if log_panel != null and log_panel.visible:
		bl = maxf(bl, log_panel.get_global_rect().end.x + gap)
	for c in [card, hint]:
		if c.visible:
			var w: float = c.size.x
			c.position.x = roundf(clampf(vs.x * 0.5 - w * 0.5, bl, maxf(bl, col.y - w)))
	_apply_heights()
	if tip.visible:
		_place_tip()


# the widest the activation card may be: the room between the battle log and the ship panel
func _card_room() -> float:
	var col := _column()
	var bl := col.x
	if log_panel != null and log_panel.visible:
		bl = maxf(bl, log_panel.get_global_rect().end.x + s(10))
	return col.y - bl


func over_ui(p: Vector2) -> bool:
	for c in [top, roster, panel, log_panel, tipcard, endcard, menu, legend, card]:
		if c != null and is_instance_valid(c) and c.visible and c.get_global_rect().has_point(p):
			return true
	return false


# ---------------------------------------------------------------- F1: the phase strip and the activation card

var phase: PanelContainer
var phase_lbl: RichTextLabel
var phase_bar: ColorRect
var phase_fill: ColorRect
var _phase_sb: StyleBoxFlat


# the strip under the top bar: whose turn it is, and in the enemy's turn how far along it is
func _build_phase() -> void:
	phase = PanelContainer.new()
	_phase_sb = StyleBoxFlat.new()
	_phase_sb.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	_phase_sb.border_color = GILT
	_phase_sb.set_border_width_all(1)
	_phase_sb.set_corner_radius_all(s(14))
	_phase_sb.content_margin_left = s(18)
	_phase_sb.content_margin_right = s(18)
	_phase_sb.content_margin_top = s(5)
	_phase_sb.content_margin_bottom = s(6)
	phase.add_theme_stylebox_override("panel", _phase_sb)
	phase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase.set_anchors_preset(Control.PRESET_CENTER_TOP)
	phase.grow_horizontal = Control.GROW_DIRECTION_BOTH
	phase.offset_top = s(72)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase.add_child(v)
	phase_lbl = RichTextLabel.new()
	phase_lbl.bbcode_enabled = true
	phase_lbl.fit_content = true
	phase_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	phase_lbl.scroll_active = false
	phase_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_lbl.add_theme_font_size_override("normal_font_size", s(16))
	phase_lbl.add_theme_font_size_override("bold_font_size", s(16))
	v.add_child(phase_lbl)
	phase_bar = ColorRect.new()
	phase_bar.color = Color(0.2, 0.12, 0.3, 0.9)
	phase_bar.custom_minimum_size = Vector2(0, s(4))
	phase_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_fill = ColorRect.new()
	phase_fill.color = Color("#b98cff")
	phase_fill.anchor_bottom = 1.0
	phase_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_bar.add_child(phase_fill)
	v.add_child(phase_bar)
	phase.visible = false
	root.add_child(phase)


# kind: "player", "enemy" or "" (hidden); bb: the strip's text; progress 0..1 (enemy turn only, negative hides the bar)
func set_phase(kind: String, bb: String, progress := -1.0) -> void:
	_last["set_phase"] = [kind, bb, progress]
	phase.visible = kind != ""
	if kind == "":
		return
	_phase_sb.border_color = GILT if kind == "player" else Color("#a64dff")
	_phase_sb.bg_color = Color(0.06, 0.07, 0.10, 0.9) if kind == "player" else Color(0.086, 0.04, 0.157, 0.9)
	if phase_lbl.text != bb:
		phase_lbl.text = bb
	phase_bar.visible = progress >= 0.0
	phase_fill.anchor_right = clampf(progress, 0.0, 1.0)
	phase.reset_size()
	phase.offset_left = -phase.size.x * 0.5
	phase.offset_right = phase.size.x * 0.5


var card: PanelContainer
var card_box: VBoxContainer
var _card_sig := ""


func _build_card() -> void:
	card = PanelContainer.new()
	var g := _glass(8)
	g.border_color = Color(0.816, 0.651, 0.294, 0.55)
	g.content_margin_left = s(16)
	g.content_margin_right = s(16)
	g.content_margin_top = s(10)
	g.content_margin_bottom = s(12)
	card.add_theme_stylebox_override("panel", g)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	# anchored at the bottom centre with a zero-size rect: Godot grows it upward and to both sides to fit what it holds
	card.anchor_left = 0.5
	card.anchor_right = 0.5
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.offset_left = 0
	card.offset_right = 0
	card.offset_bottom = -s(16)
	card.offset_top = -s(16)
	card_box = VBoxContainer.new()
	card_box.add_theme_constant_override("separation", s(7))
	card_box.custom_minimum_size = Vector2(s(660), 0)
	card.add_child(card_box)
	card.visible = false
	root.add_child(card)


# The ship that is up and how to finish it. info: {name, cls, flag, more (ready ships after this one), steps: [{n, label,
# detail, st: done | now | todo | off}], hint (bbcode), buttons: [{text, act, arg, on, primary, big, tip}]}; {} hides it
func set_card(info: Dictionary) -> void:
	_last["set_card"] = [info]
	var sig := JSON.stringify(info)
	if sig == _card_sig:
		return
	_card_sig = sig
	for c in card_box.get_children():
		card_box.remove_child(c)
		c.queue_free()
	card.visible = not info.is_empty()
	hint.visible = info.is_empty()   # the card carries the keys while it shows; the old hint line sat under it
	if info.is_empty():
		return
	# the card is as wide as it needs, up to the room between the battle log and the ship panel
	var cw := minf(float(s(660)), _card_room() - s(32))
	card_box.custom_minimum_size.x = cw
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", s(10))
	var nm := _label(("★ " if info.get("flag", false) else "") + str(info.get("name", "")), 22, GILT, font_semi)
	head.add_child(_label(str(info.get("tag", "UP")), 13, INK, font_caps))
	(head.get_child(0) as Label).add_theme_stylebox_override("normal", _chip_sb(GILT, GILT))
	head.add_child(nm)
	var cl := _label(str(info.get("cls", "")), 15, BONE2)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(cl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	var more := _label(str(info.get("more", "")), 14, BONE2)
	more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(more)
	card_box.add_child(head)
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", s(6))
	var first := true
	for st in info.get("steps", []):
		if not first:
			var ar := _label("›", 18, BONE3)
			ar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			steps.add_child(ar)
		first = false
		steps.add_child(_step_chip(st))
	card_box.add_child(steps)
	if str(info.get("hint", "")) != "":
		var h := _rich(str(info["hint"]))
		h.custom_minimum_size.x = cw   # a fixed wrap width, so its height is measured right the first time
		h.add_theme_font_size_override("normal_font_size", s(15))
		h.add_theme_font_size_override("bold_font_size", s(15))
		card_box.add_child(h)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(8))
	var spacer_done := false
	for b in info.get("buttons", []):
		if b.get("big", false) and not spacer_done:
			var sp2 := Control.new()
			sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(sp2)
			spacer_done = true
		var bt := _button(str(b["text"]), str(b["act"]), b.get("arg"), bool(b.get("primary", false)))
		bt.disabled = not bool(b.get("on", true))
		bt.tooltip_text = str(b.get("tip", ""))
		bt.custom_minimum_size.y = s(40) if b.get("big", false) else s(34)
		bt.add_theme_font_size_override("font_size", s(17) if b.get("big", false) else s(15))
		if b.get("name", "") != "":
			bt.name = str(b["name"])
		row.add_child(bt)
	card_box.add_child(row)
	_place_card()


# the card's rect from what it holds, two frames after it is built (text heights settle once the width is known); never
# taller than 320 (a container never shrinks by itself, so a bad first measure must not stick)
var _card_gen := 0


func _place_card() -> void:
	_card_gen += 1
	var g := _card_gen
	card.modulate.a = 0.0
	for i in 2:
		await get_tree().process_frame
	if g != _card_gen or not is_instance_valid(card):
		return
	var ms := card_box.get_combined_minimum_size() + Vector2(s(32), s(22))
	ms.y = minf(ms.y, float(s(320)))
	card.offset_left = -ms.x * 0.5
	card.offset_right = ms.x * 0.5
	card.offset_bottom = -s(16)
	card.offset_top = -s(16) - ms.y
	card.modulate.a = 1.0


func _chip_sb(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(s(4))
	sb.content_margin_left = s(7)
	sb.content_margin_right = s(7)
	sb.content_margin_top = s(2)
	sb.content_margin_bottom = s(2)
	return sb


# one step of the activation: "1 MOVE  4 of 5 left", lit when it is the step you are on, ticked when done, dim when gone
func _step_chip(st: Dictionary) -> Control:
	var p := PanelContainer.new()
	var now: bool = st.get("st", "") == "now"
	var off: bool = st.get("st", "") == "off"
	var done: bool = st.get("st", "") == "done"
	p.add_theme_stylebox_override("panel", _chip_sb(Color(0.30, 0.24, 0.10, 0.85) if now else Color(0.10, 0.13, 0.20, 0.7), GILT if now else IRON3))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.modulate.a = 0.45 if off else 1.0
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(6))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_label(("✓ " if done else "%s " % str(st.get("n", ""))) + str(st.get("label", "")).to_upper(), 14, GILT if now else (VERD if done else BONE), font_caps))
	h.add_child(_label(str(st.get("detail", "")), 14, BONE if now else BONE2))
	p.add_child(h)
	return p
