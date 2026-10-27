extends CanvasLayer
# The battle HUD, laid out like today's game (head.html, ui3d.js): top bar, your fleet on the left, the selected ship's
# panel on the right (stats, weapons with hit chances, orders), the battle log bottom left, ship nameplates over the
# board, the round banner, hover tips, the enemy-acting chip, one-at-a-time onboarding tips, and the end card.
# Colours from the game's CSS variables. Sizes scale with the window height (designed at 1080).

signal action(name: String, arg: Variant)

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
var font_goth: FontFile
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
	font_goth = _font("UnifrakturMaguntia-Book.ttf")
	k = clampf(get_viewport().get_visible_rect().size.y / 1080.0, 0.6, 2.2)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
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
	title_lbl = _label("Round 1", 28, BONE, font_goth)
	row.add_child(title_lbl)
	turn_lbl = _label("", 17, BONE2, font_semi)
	turn_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(turn_lbl)
	obj_lbl = _label("", 15, GILT)
	obj_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(obj_lbl)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	cmd_btn = _button("Command", "command")
	cmd_btn.visible = false
	row.add_child(cmd_btn)
	retreat_btn = _button("Retreat", "retreat")
	retreat_btn.visible = false
	row.add_child(retreat_btn)
	threat_btn = _button("Threat (R)", "threat")
	row.add_child(threat_btn)
	row.add_child(_button("Top-down (T)", "top"))
	row.add_child(_button("Menu", "menu"))
	speed_btn = _button("Speed: normal", "speed")
	row.add_child(speed_btn)
	end_btn = _button("End activation", "end", null, true)
	row.add_child(end_btn)


# your admiral's crest (godot/portraits) at the left of the top bar
func set_crest(tex: Texture2D, tip: String) -> void:
	crest.texture = tex
	crest.visible = tex != null
	crest.tooltip_text = tip


func set_command(label: String, ready: bool) -> void:
	cmd_btn.visible = ready
	cmd_btn.text = "Command: " + label
	cmd_btn.add_theme_color_override("font_color", GILT)


func set_top(round_n: int, turn: String, objective: String, end_text: String, end_on: bool, speed_fast: bool, threat_on: bool) -> void:
	title_lbl.text = "Round %d" % round_n
	turn_lbl.text = turn
	obj_lbl.text = objective
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
	if not is_instance_valid(box):
		return
	var h := minf(box.get_combined_minimum_size().y, max_h)
	sc.custom_minimum_size.y = h
	p.reset_size()


func set_roster(rows: Array) -> void:
	# rows: [{id, name, cls, hp, maxHp, sh: [4], shMax, status, sel, done, flag}]
	for c in roster_box.get_children():
		roster_box.remove_child(c)
		c.queue_free()
	_fit(roster_sc, roster_box, roster, get_viewport().get_visible_rect().size.y - s(76 + 160))
	var head := _label("Your fleet", 15, GILT, font_semi)
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
		row.add_child(_label(str(r["status"]), 13, GILT if r["status"] == "Active" else BONE2))
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
	panel_box.add_child(_hull_bar(float(info["hp"]), float(info["maxHp"]), 7))
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
	if info.get("side", "") == "player":
		panel_box.add_child(_rich("\n" + keys_text()))


func keys_text() -> String:
	return "[font_size=%d][color=#b3aa95]Click a gold hex to move, an enemy to fire. [b]Q[/b]/[b]E[/b] turn, [b]1[/b]-[b]6[/b] pick a weapon, [b]B[/b] brace, [b]X[/b] ram, [b]G[/b] board, [b]Tab[/b] next ship, [b]Enter[/b] end activation, [b]Space[/b] hurry the enemy, [b]Esc[/b] cancel. Right-drag orbit, left-drag or WASD pan, wheel zoom, [b]T[/b] top-down, [b]R[/b] threat map, [b]V[/b] firing arcs, [b]F[/b] focus, [b]Home[/b] reset view.[/color][/font_size]" % s(12)


func _sect(t: String) -> Control:
	var v := VBoxContainer.new()
	var line := ColorRect.new()
	line.color = Color(0.176, 0.227, 0.337, 0.8)
	line.custom_minimum_size = Vector2(0, 1)
	v.add_child(line)
	v.add_child(_label(t, 15, GILT, font_semi))
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
	banner_lbl = _label("", 64, BONE, font_goth)
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
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = -s(90)
	toast_lbl.offset_bottom = -s(60)
	toast_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	toast_lbl.modulate.a = 0.0
	root.add_child(toast_lbl)


func banner(text: String, col := BONE, dur := 0.9) -> void:
	banner_lbl.text = text
	banner_lbl.add_theme_color_override("font_color", col)
	_banner_t = 0.0
	_banner_dur = dur


func toast(text: String) -> void:
	toast_lbl.text = text
	_toast_t = 2.6


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
	var vs := root.get_viewport_rect().size
	var p := at + Vector2(s(18), s(18))
	if p.x + tip.size.x > vs.x - s(360):
		p.x = at.x - tip.size.x - s(18)
	if p.y + tip.size.y > vs.y:
		p.y = vs.y - tip.size.y - s(8)
	tip.position = p


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
	aichip.text = txt
	aichip.visible = txt != ""


func _build_hint() -> void:
	hint = _label("Right-drag orbit   Left-drag or WASD pan   Wheel zoom   T top-down   R threat   Enter end activation", 13, BONE2)
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


func set_plate(id: String, screen: Vector2, on: bool, name_txt: String, friend: bool, flag: bool, hp: float, mx: float, sh: float, shmx: float) -> void:
	var c := plate(id)
	c.visible = on
	if not on:
		return
	var nm := c.get_node("nm") as Label
	nm.text = ("★ " if flag else "") + name_txt
	nm.add_theme_color_override("font_color", FRIEND if friend else FOE)
	var hf := c.get_node("hb/f") as ColorRect
	var f := clampf(hp / maxf(mx, 1.0), 0.0, 1.0)
	hf.anchor_right = f
	hf.color = HULL_LOW if f < 0.34 else HULL
	var sbar := c.get_node("sb") as ColorRect
	sbar.visible = shmx > 0.0
	(c.get_node("sb/f") as ColorRect).anchor_right = clampf(sh / maxf(shmx, 1.0), 0.0, 1.0)
	c.reset_size()
	c.position = screen - Vector2(c.size.x * 0.5, c.size.y)


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
	if tipcard != null:
		tipcard.queue_free()
		tipcard = null


func show_end(title: String, body: String, win: bool, external := false) -> void:
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
	var t := _label(title, 44, GILT if win else BLOOD, font_goth)
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
	var t := _label(title, 32, GILT, font_goth)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	for it in items:
		v.add_child(_button(str(it[0]), str(it[1]), it[2] if it.size() > 2 else null, it == items[0]))


# cut-in letterbox bars
var bars: Array = []


func letterbox(on: bool) -> void:
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
	if on and load_cover == null:
		load_cover = ColorRect.new()
		load_cover.color = Color(0.02, 0.025, 0.04, 1.0)
		load_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		load_cover.mouse_filter = Control.MOUSE_FILTER_STOP
		var l := _label("Preparing the battle...", 30, GILT, font_goth)
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.grow_vertical = Control.GROW_DIRECTION_BOTH
		load_cover.add_child(l)
		root.add_child(load_cover)
	elif not on and load_cover != null:
		load_cover.queue_free()
		load_cover = null


func hide_menu() -> void:
	if menu != null:
		menu.queue_free()
		menu = null


func hide_end() -> void:
	if endcard != null:
		endcard.queue_free()
		endcard = null


func _process(dt: float) -> void:
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


func over_ui(p: Vector2) -> bool:
	for c in [top, roster, panel, log_panel, tipcard, endcard, menu, legend]:
		if c != null and is_instance_valid(c) and c.visible and c.get_global_rect().has_point(p):
			return true
	return false
