extends CanvasLayer
# The battle HUD: the ember orders sheet, E1 LEDGER (issue 271 step 2; Ryan's pick R210, as captured in step 1,
# docs/shots/ui_battle_ember/E1_ledger.jpg; the look is the campaign map's rail, contrib/opus/briefs/campaign_rail_orders_sheet.md,
# R176). The sheet itself is godot/ui/battle/ledger.gd: one left sheet in decision order (whose turn, the ship, its hull
# and four shields, its guns, the target and the odds, the action, the orders and the Command, the fleet at the foot),
# the menu, the enemy, Heat and the Nemesis top right, the last three log lines bottom right. No panels: words on a
# darkened edge of the scene; ember the one accent; Glacier for shield readouts only; square corners; one box.
#
# This file keeps the battle's HUD interface (the setters battle.gd calls, the menu, the end card, the tip card, the
# hover tips, banners, toasts, floats and nameplates) and hands every setter's data to the sheet. Everything here that is
# still visible is in the sheet's look. SAY LESS (R177): what the sheet does not show is one hover or one key away; the
# list is in docs/playbooks/screens.md (battle screen).
#
# The Lime Tactical shell of the previous build is gone: the PC capture tools (ui_shots.gd, f1_trace.gd,
# bench/scene_gate.gd) and story_beat3_test read the sheet (ledger.gd) now, so nothing is built for them (issue 578).
#
# Regions now: the sheet (left, ledger.sheet_r) | the clear part of the screen to its right, where the banner, toasts,
# the tip card and hover tips sit (_column) | top right and bottom right corners (the sheet's own words).
#
# Every number shown comes from the battle (battle.gd builds the rows from the rules' own queries); this file only
# draws them.

signal action(name: String, arg: Variant)
signal rescaled   # the HUD was rebuilt at a new size; the battle refreshes what it shows

const Brand := preload("res://ui/battle/brand.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const GS := preload("res://ui/theme/glass_shell.gd")
const Ledger := preload("res://ui/battle/ledger.gd")

# the orders sheet palette (glass_shell.gd, R176; Glacier R210)
const S_EMBER := GS.MAP_EMBER
const S_TEXT := GS.TEXT
const S_TEXT2 := GS.TEXT2
const S_TEXT3 := GS.TEXT3
const S_NEM := GS.NEM
const S_GLACIER := GS.GLACIER
const S_HAIR := GS.SHEET_HAIR

const INK := GS.INK
const IRON := GS.IRON
const IRON2 := GS.IRON2
const IRON3 := GS.IRON3
const BONE := GS.BONE
const BONE2 := GS.BONE2
const BONE3 := GS.BONE3
const GILT := GS.GILT
const GILT2 := GS.GILT2
const VERD := GS.VERD
const BLOOD := GS.BLOOD
const ALERT := GS.ALERT
const EMBER := GS.EMBER
const SHIELD := GS.SHIELD
const HULL := GS.HULL
const HULL_LOW := GS.HULL_LOW
const FRIEND := GS.FRIEND
const FOE := GS.FOE
const FOE_RING := GS.FOE_RING

# the layout at the 1080 design height
const M := 12.0          # screen margin
const COL_W := 440.0     # the tip card's offset from the sheet's margin
const TOP_H := 38.0      # kept for the old shell helpers below (not built)
const BAND_H := 26.0
const FLEET_W := 250.0
const LOG_W := 600.0     # the full log
const LOG_LINES := 4
const LOG_H := 134.0
# The battle log view keeps the newest 200 entries, the browser's own cap (ui3d.js log(): while el.childNodes.length > 200
# remove the first). Only the view is capped: the rules' own log array keeps every entry for saves, the debrief and parity.
const LOG_VIEW_MAX := 200

var font: Font                      # sentences: Barlow Regular (the orders sheet, R176)
var font_semi: Font                 # buttons, short labels: Barlow Medium
var font_name: Font                 # names in capitals: Big Shoulders Display (banner, menu and end card titles)
var font_goth: Font                 # display (banner, end card): Chakra Petch Bold, tracked caps
var font_caps: Font                 # section heads and tags: Chakra Petch Bold, tracked caps
var font_num: Font                  # numbers that decide something (odds, damage, hull, keys): Azeret Mono
var font_num_b: Font                # the same, bold
var font_act: Font                  # the finish button's caps label
var k := 1.0                        # the UI scale (ui_scale.gd: window height / 1080, clamped, times the player scale)
var root: Control
# the previous build's controls: no longer built (issue 578); the names stay so the old helpers below parse while they
# are removed. Nothing here is created or shown.
var top: PanelContainer
var title_lbl: Label
var crest: TextureRect
var turn_lbl: Label
var pips: Control
var acted_lbl: Label
var obj_lbl: Label
var foe_crest: TextureRect
var foe_lbl: Label
var heat_box: HBoxContainer
var heat_bar: Control
var heat_lbl: Label
var end_btn: Button
var speed_btn: Button
var threat_btn: Button
var retreat_btn: Button
var cmd_btn: Button
var roster: PanelContainer
var roster_box: VBoxContainer
var roster_sc: ScrollContainer
var roster_head: Label
var panel_sc: ScrollContainer
var panel: PanelContainer
var panel_box: VBoxContainer
var hint: Label
var unacted: PanelContainer
var unacted_row: HBoxContainer
var nem_well: PanelContainer
var up_well: PanelContainer
var move_well: PanelContainer
var fire_well: PanelContainer
var orders_well: PanelContainer
var target_well: PanelContainer
var card: PanelContainer
var card_box: VBoxContainer
var _card_sig := ""
var legacy: Control
var _rows: Array = []
var _info := {}
var _card_info := {}
var _phase_kind := ""
var log_panel: PanelContainer
var log_text: RichTextLabel
var log_open := false
var banner_lbl: Label
var tip: PanelContainer
var tip_text: RichTextLabel
var dtip: PanelContainer            # the "more on hover" layer of the ship that is up
var dtip_text: RichTextLabel
var aichip: Label
var plates_root: Control
var plates := {}                    # unit id -> Control
var tipcard: PanelContainer
var endcard: PanelContainer
var _banner_t := 0.0
var _banner_dur := 0.0
var toast_lbl: Label
var _toast_t := 0.0
var legend: PanelContainer
var legend_open := false
var _legend := {}                   # {title, desc, rows: [[name, colour, effect]]}

var ledger                          # the orders sheet (ledger.gd): what the player sees
var _log_lines: Array = []          # the log as plain lines, for the sheet's last three
var ask_panel: Control              # issue 529: the sheet while a tree prompt is open in it, else null
var ask_key := ""

var _panel_info := {}               # the last ship info (set_panel)
var _round := 1


func _ready() -> void:
	layer = 10
	font = GS.sheet_body()
	font_semi = GS.sheet_medium()
	font_name = GS.sheet_name()
	k = scale_for(get_viewport().get_visible_rect().size)
	_scaled_fonts()
	_built_vs = get_viewport().get_visible_rect().size
	_build_all()


# the UI scale for a window: the one shared law (godot/ui/ui_scale.gd, ui_spec.md section 4)
static func scale_for(vs: Vector2) -> float:
	return UiScale.k_for(vs)


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
	_build_log()
	_build_ledger()
	_build_banner()
	_build_chip()
	_build_legend()
	_build_tip()
	# the full log (L) sits over the sheet's corner; the banner, toasts, tips and dialogs over everything
	root.move_child(log_panel, ledger.get_index() + 1)


# the orders sheet: every setter hands it its data (ledger.gd lays it out and draws it)
func _build_ledger() -> void:
	ledger = Ledger.new()
	ledger.name = "ledger"
	ledger.k = k
	root.add_child(ledger)
	ledger.log_lines = _log_lines
	ledger.keys_bb = keys_text()
	ledger.act.connect(func(n: String, arg: Variant) -> void: action.emit(n, arg))
	ledger.hover_tip.connect(_ledger_tip)
	# the board's hover tip belongs to the board: it goes when the pointer comes onto the sheet (the board gets no motion there)
	ledger.mouse_entered.connect(func() -> void: tip.visible = false)


# The window changed size: build every part again at the new scale and put back what each part showed. The battle log's
# text, the floating callouts and the dialogs move across as they are; nameplates are made again on the next frame.
func _rebuild() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_vs = vs
	var nk := scale_for(vs)
	if absf(nk - k) < 0.004 or root == null:
		return
	var keep := {
		"banner": banner_lbl.text, "banner_col": banner_lbl.get_theme_color("font_color"), "banner_a": banner_lbl.modulate.a,
		"toast": toast_lbl.text, "toast_a": toast_lbl.modulate.a}
	# N5 (#282): a rebuild while the menu is open keeps its keyboard row. Read the row before the menu is thrown away.
	var keep_row := -1
	if menu != null and is_instance_valid(menu):
		var mfo := get_viewport().gui_get_focus_owner()
		if mfo != null and menu.is_ancestor_of(mfo): keep_row = maxi(0, mfo.get_index() - 1)
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
	ask_panel = null
	k = nk
	_scaled_fonts()
	_build_all()
	for key in ["set_crest", "set_info", "set_command", "set_top", "set_roster", "set_nemesis", "set_panel", "set_target", "set_legend", "set_chip", "set_phase", "set_card", "set_retreat"]:
		if _last.has(key):
			callv(key, _last[key])
	if _last.has("show_tipcard"):
		callv("show_tipcard", _last["show_tipcard"])
	if _last.has("show_menu"):
		var sm: Array = _last["show_menu"]
		show_menu(sm[0], sm[1], keep_row, str(sm[2]) if sm.size() > 2 else "")
	if _last.has("show_end"):
		callv("show_end", _last["show_end"])
	if _last.has("show_ask"):
		var sa: Array = _last["show_ask"]
		ask_panel = null   # the old sheet went with the old root
		ask_key = ""
		show_ask(sa[0])
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


# the faces whose letter spacing follows the UI scale (Lime Tactical type, glass_shell.gd): made again on a rebuild
func _scaled_fonts() -> void:
	font_goth = GS.display(k)
	font_caps = GS.caps(k)
	font_act = GS.action_font(k)
	font_num = GS.num()
	font_num_b = GS.num_bold()


func s(v: float) -> int:
	return int(round(v * k))


# the battle theme: the shared theme (glass_shell.gd make_theme, focus ring included) in the orders sheet faces, with the
# sheet's plain buttons: words only, ember while the pointer is on them; no fill, no edge, square (R176)
func _theme() -> Theme:
	var th := GS.make_theme(k, font, font_semi, 17)
	th.default_font_size = s(17)
	var plain := GS.flat(Color(0, 0, 0, 0), 10.0, 5.0, k)
	for st in ["normal", "hover", "pressed", "disabled"]:
		th.set_stylebox(st, "Button", plain)
	th.set_color("font_color", "Button", S_TEXT)
	th.set_color("font_hover_color", "Button", S_EMBER)
	th.set_color("font_pressed_color", "Button", S_EMBER)
	th.set_color("font_focus_color", "Button", S_TEXT)
	th.set_color("font_hover_pressed_color", "Button", S_EMBER)
	th.set_color("font_disabled_color", "Button", S_TEXT2)
	th.set_color("font_color", "Label", S_TEXT)
	th.set_color("default_color", "RichTextLabel", S_TEXT)
	th.set_stylebox("panel", "TooltipPanel", _tipbox())
	th.set_color("font_color", "TooltipLabel", S_TEXT)
	# AC5 (UI audit, ui_spec.md 6.2): the focus ring comes from the theme alone (glass_shell.gd focus_ring via make_theme),
	# one source for every screen (#314 check condition 4). Only the menu and the end card take keyboard focus (_button
	# keys); the board-time buttons stay out of it because Space, Enter and Tab belong to the battle there (F1 key scheme).
	th.set_font_size("font_size", "Button", s(19))
	th.set_font_size("normal_font_size", "RichTextLabel", s(18))
	th.set_font_size("bold_font_size", "RichTextLabel", s(18))
	th.set_font_size("font_size", "TooltipLabel", s(18))
	return th


# the one kind of box besides the action: a hover tip, the menu, the end card, the full log. Near-black, a quiet hairline
# edge, square, no shadow, no glow (the map's hover tip, glass_shell.gd tip)
func _tipbox(pad_x := 14.0, pad_y := 10.0) -> StyleBoxFlat:
	var b := GS.flat(Color(GS.COLUMN, 0.96), pad_x, pad_y, k)
	b.border_color = S_HAIR
	b.set_border_width_all(maxi(1, s(1)))
	return b


# the HUD's palette translation: the battle still writes some of its words in the previous build's colours (bbcode and
# Color arguments). Lime and the old amber become the ember, the old shield cyan becomes Glacier (shield readouts only),
# every other old colour one of the three text strengths. Nothing lime reaches the screen.
const BB_MAP := {"#ffb23e": "#ff8a3a", "#4fc4ff": "#92b8e8", "#9fe2ff": "#92b8e8",
	"#a7b09d": "#c4beb0", "#7c8674": "#969084", "#e8eee0": "#f0eade", "#c4a4ff": "#f0eade", "#8d86a0": "#c4beb0",
	"#52f0c4": "#f0eade", "#59d6a8": "#f0eade", "#ffad3b": "#f0eade", "#ff8a72": "#f0eade", "#ff8a6a": "#f0eade",
	"#9fd4ff": "#f0eade", "#7fc4ff": "#f0eade", "#f08a4b": "#f0eade", "#f0c58b": "#c4beb0", "#d9f78a": "#f0eade"}


static func recol(t: String) -> String:
	var o := t
	for c in BB_MAP:
		o = o.replace("color=" + c, "color=" + str(BB_MAP[c]))
	return o


static func col_of(c: Color) -> Color:
	var h := "#" + c.to_html(false)
	if BB_MAP.has(h):
		return Color(str(BB_MAP[h]))
	if c.is_equal_approx(GILT) or c.is_equal_approx(Color(0.78, 0.96, 0.23)):
		return S_EMBER
	return c


# plain words over the scene: the map's dark halo, no strip (ui_style.md 3, the orders sheet exception)
func _halo(l: Label) -> void:
	l.add_theme_color_override("font_outline_color", Color(GS.HALO, 0.92))
	l.add_theme_constant_override("outline_size", maxi(3, s(6)))
	l.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


# a panel (the matte black-olive slab, chamfered); its marks (scanline, bevel, brackets) come from _frame
func _glass(radius := 6) -> StyleBoxFlat:
	var g := GS.shell(k, 8)
	if radius > 6:
		g.content_margin_left = s(12)
		g.content_margin_right = s(12)
	return g


# Lime Tactical marks: every panel has the scanline and the two lime corner brackets; the lime bevel on the top-left
# chamfer is off on the flat top bar (ticks false), as in the mockup
func _frame(p: PanelContainer, ticks := true) -> void:
	p.add_theme_stylebox_override("panel", _glass())
	GS.frame_marks(p, k, true, ticks)


func _panel(l: float, t: float, r: float, b: float, w := -1.0, h := -1.0, ticks := true) -> PanelContainer:
	var p := PanelContainer.new()
	root.add_child(p)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	_frame(p, ticks)
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


# a solid well (a block inside the shell): every line of text sits on one
func _well(accent := Color(0, 0, 0, 0), pad_x := 12.0, pad_y := 8.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GS.well(k, accent, pad_x, pad_y))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
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


# a section head: "1 MOVE" (Lime Tactical: the number and the word both lime, tracked caps, as in the mockup)
func _head(n: String, word: String, right: String = "", right_col := BONE2) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(6))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if n != "":
		var nl := _label(n, 13, GILT, font_caps)
		nl.name = "step_no"   # _route_card relabels it (a tick when done); a head without a number has none
		h.add_child(nl)
	h.add_child(_label(word.to_upper(), 13, GILT, font_caps))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sp)
	if right != "":
		var r := _label(right, 14, right_col)
		h.add_child(r)
	return h


# a small solid tag ("UP", "NEMESIS", "ENEMY", "LOW")
func _tag(txt: String, col: Color, filled := true, size := 13) -> Label:
	var l := _label(txt, size, GS.ON_GILT if filled else col, font_caps)
	if filled and col != GILT:
		l.add_theme_color_override("font_color", Color("#14070a") if col == ALERT else INK)
	l.add_theme_stylebox_override("normal", GS.tag(k, col, filled))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


# a key cap beside an action ("B", "Tab", "Space")
func _keycap(key: String, size := 13) -> Label:
	var l := _label(key, size, GS.KEY_FG, font_num_b)
	l.add_theme_stylebox_override("normal", GS.keycap(k))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


# the danger badge: a reticle and the number of enemies that can reach that hex next turn (a glyph plus a number, so it
# never rides on colour alone, ui_spec.md 5.2)
func _badge(n: int, size := 13) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", GS.tag(k, FOE_RING, false))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.tooltip_text = "%d enem%s can bring guns on this ship's hex next turn." % [n, "y" if n == 1 else "ies"]
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(3))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(_reticle(size))
	h.add_child(_label(str(n), size, FOE, font_num_b))
	p.add_child(h)
	return p


# a small reticle glyph (drawn, so it never depends on a font having the character)
func _reticle(size := 13) -> Control:
	var c := Control.new()
	var d := float(s(size - 2))
	c.custom_minimum_size = Vector2(d, d)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		var o := c.size * 0.5
		var r := minf(c.size.x, c.size.y) * 0.5 - 1.0
		var lw := maxf(1.0, float(s(1)))
		c.draw_arc(o, r * 0.62, 0, TAU, 20, FOE, lw, true)
		c.draw_line(o + Vector2(0, -r), o + Vector2(0, -r * 0.3), FOE, lw)
		c.draw_line(o + Vector2(0, r), o + Vector2(0, r * 0.3), FOE, lw)
		c.draw_line(o + Vector2(-r, 0), o + Vector2(-r * 0.3, 0), FOE, lw)
		c.draw_line(o + Vector2(r, 0), o + Vector2(r * 0.3, 0), FOE, lw))
	return c


# a small hatched swatch (the "expected" key on the Target block)
func _hatch_key() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(s(16), s(9))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(GS.WELL, 1.0))
		var x := -c.size.y
		while x < c.size.x:
			c.draw_line(Vector2(maxf(x, 0.0), c.size.y - maxf(0.0, -x)), Vector2(minf(x + c.size.y, c.size.x), c.size.y - (minf(x + c.size.y, c.size.x) - x)), HULL, 1.0)
			x += 3.0)
	return c


# keys: the button takes keyboard focus (Tab, the arrows, Enter or Space press it). Only for the menu and the end card,
# where the battle's own keys are not in play; everywhere else Space, Enter and Tab drive the battle (ui_spec.md 6.2).
func _button(txt: String, act: String, arg: Variant = null, primary := false, keys := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_ALL if keys else Control.FOCUS_NONE
	if primary:
		# the dialog's one action: the sheet's action box, a square ember outline that fills ember under the pointer
		var bx := GS.sheet_jump_boxes(k)
		for st in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(st, bx[st])
		b.add_theme_color_override("font_color", S_EMBER)
		b.add_theme_color_override("font_focus_color", S_EMBER)
		b.add_theme_color_override("font_hover_color", GS.ON_EMBER)
		b.add_theme_color_override("font_pressed_color", GS.ON_EMBER)
		b.add_theme_color_override("font_hover_pressed_color", GS.ON_EMBER)
		b.add_theme_font_override("font", font_semi)
	b.pressed.connect(func() -> void: action.emit(act, arg))
	return b


# an action with its key cap inside: "[B] Brace". The key is read from a "(B)" at the end of the text when there is one.
func _key_button(txt: String, act: String, arg: Variant = null, primary := false, key := "") -> Button:
	var t := txt
	var kk := key
	var re := RegEx.new()
	re.compile("^(.*?)\\s*\\(([^()]{1,6})\\)$")
	var m := re.search(t)
	if m != null and kk == "":
		t = m.get_string(1)
		kk = m.get_string(2)
	var b := _button("", act, arg, primary)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(8))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = s(8)
	h.offset_right = -s(6)
	if kk != "":
		var kc := _keycap(kk, 12 if kk.length() > 2 else 13)
		if primary:
			kc.add_theme_stylebox_override("normal", GS.keycap_on_gilt(k))
			kc.add_theme_color_override("font_color", GS.ON_GILT)
		h.add_child(kc)
	var l := _label(t, 15 if primary else 14, GS.ON_GILT if primary else BONE, GS.bold() if primary else font_semi)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	b.add_child(h)
	b.set_meta("lbl", l)
	b.set_meta("key", kk)
	b.custom_minimum_size = Vector2(_kb_width(b), s(32))
	b.tooltip_text = txt
	return b


# 3 End: End ship is the big filled lime slab of the Lime Tactical mockup in every state (R148, R149): "END SHIP" in
# tracked bold caps, centred, its key cap ("SPACE") after it, dark on lime. Whatever the step, this is the one filled
# button on the screen; a step's own confirm (Move here, Fire N weapons) is drawn lit instead (_hint_into).
func _end_button(b: Dictionary) -> Button:
	var t := str(b["text"])
	var kk := ""
	var re := RegEx.new()
	re.compile("^(.*?)\\s*\\(([^()]{1,6})\\)$")
	var m := re.search(t)
	if m != null:
		t = m.get_string(1)
		kk = m.get_string(2)
	var on := bool(b.get("on", true))
	var bt := _button("", str(b["act"]), b.get("arg"))
	var fb := GS.finish_boxes(k)
	for st in ["normal", "hover", "pressed", "disabled"]:
		bt.add_theme_stylebox_override(st, fb[st])
	bt.disabled = not on
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_theme_constant_override("separation", s(10))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	var l := _label(t.to_upper(), 17, GS.ON_GILT if on else BONE3, font_act)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(l)
	if kk != "":
		var kc := _keycap(kk.to_upper(), 12 if kk.length() > 2 else 13)
		kc.add_theme_stylebox_override("normal", GS.keycap_on_gilt(k))
		kc.add_theme_color_override("font_color", GS.ON_GILT if on else BONE3)
		h.add_child(kc)
	bt.add_child(h)
	bt.set_meta("lbl", l)
	bt.set_meta("key", kk)
	GS.gilt_sheen(bt, k)
	bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bt.custom_minimum_size = Vector2(_kb_width(bt), s(46))
	return bt


# a key button's natural width, measured from its fonts (a container's minimum size is not known before it is drawn)
func _kb_width(b: Button) -> float:
	var l: Label = b.get_meta("lbl")
	var kk := str(b.get_meta("key", ""))
	var fs := l.get_theme_font_size("font_size") if l.has_theme_font_size_override("font_size") else s(14)
	var lf: Font = l.get_theme_font("font") if l.has_theme_font_override("font") else font_semi
	var w := lf.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if kk != "":
		w += font_num_b.get_string_size(kk, HORIZONTAL_ALIGNMENT_LEFT, -1, s(12 if kk.length() > 2 else 13)).x + s(10) + s(8)
	return ceilf(w + s(16) + s(6))


# ---------------------------------------------------------------- top bar

func _build_top() -> void:
	top = _panel(M, 8, M + COL_W + 10, -1, -1, TOP_H, false)
	var sb := GS.shell(k, 8)
	sb.content_margin_top = s(3)
	sb.content_margin_bottom = s(3)
	sb.content_margin_left = s(GS.CUT)      # clear of the chamfers
	sb.content_margin_right = s(GS.CUT)
	top.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(10))
	top.add_child(row)
	# every line of text sits on a solid backing (ui_style.md 2 and 3; #314 check condition 1): the round, the turn, the
	# acted pips and the objective share one well on the left, the enemy and Heat a second well; the buttons keep their
	# own boxes on the bar
	var lw := _well(Color(0, 0, 0, 0), 10, 1)
	lw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lw.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(lw)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", s(10))
	lw.add_child(lrow)
	crest = TextureRect.new()
	crest.custom_minimum_size = Vector2(s(28), s(28))
	crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest.visible = false
	lrow.add_child(crest)
	title_lbl = _label("ROUND 1", 19, BONE, font_goth)
	title_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lrow.add_child(title_lbl)
	turn_lbl = _label("", 13, GILT, font_caps)
	turn_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lrow.add_child(turn_lbl)
	# the acted pips: your ships (filled when done, gilt for the one that is up), a dash, then the enemy's ships
	pips = Control.new()
	pips.mouse_filter = Control.MOUSE_FILTER_PASS
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pips.draw.connect(_draw_pips)
	lrow.add_child(pips)
	acted_lbl = _label("", 13, BONE2)
	acted_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lrow.add_child(acted_lbl)
	# the objective takes the room the buttons leave and ends in "..." when there is not enough, so the buttons on the
	# right are never pushed off the screen
	obj_lbl = _label("", 14, GILT)
	obj_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	obj_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obj_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	obj_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	obj_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	lrow.add_child(obj_lbl)
	# the enemy: its crest (the faction accent, R3) and its name in plain bone, then Heat, on their own well (set_info
	# shows it when either shows)
	info_well = _well(Color(0, 0, 0, 0), 10, 1)
	info_well.mouse_filter = Control.MOUSE_FILTER_PASS
	info_well.visible = false
	row.add_child(info_well)
	var irow := HBoxContainer.new()
	irow.add_theme_constant_override("separation", s(10))
	info_well.add_child(irow)
	foe_crest = TextureRect.new()
	foe_crest.custom_minimum_size = Vector2(s(22), s(22))
	foe_crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foe_crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foe_crest.visible = false
	irow.add_child(foe_crest)
	foe_lbl = _label("", 14, BONE)
	foe_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foe_lbl.visible = false
	irow.add_child(foe_lbl)
	# Heat: the run's difficulty level, nine segments (data HEAT: seven optional rules weighing 1 or 2)
	heat_box = HBoxContainer.new()
	heat_box.add_theme_constant_override("separation", s(6))
	heat_box.mouse_filter = Control.MOUSE_FILTER_PASS
	heat_box.visible = false
	heat_box.add_child(_label("HEAT", 13, BONE2, font_caps))
	heat_bar = Control.new()
	heat_bar.custom_minimum_size = Vector2(s(84), s(12))
	heat_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heat_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heat_bar.draw.connect(_draw_heat)
	heat_box.add_child(heat_bar)
	heat_lbl = _label("0", 15, EMBER, font_num_b)
	heat_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heat_box.add_child(heat_lbl)
	irow.add_child(heat_box)
	top_row = row
	# Command moved to the Orders block (C); the button lives there (set_command)
	cmd_btn = _key_button("Command", "command", null, false, "C")
	cmd_btn.visible = false
	retreat_btn = _button("Retreat", "retreat")
	retreat_btn.visible = false
	retreat_btn.tooltip_text = "Pull the fleet out of this battle."
	row.add_child(retreat_btn)
	# board look C's "Grid (Z)" button (board.gd) lives here, in the top bar, once the battle hands it over (adopt_grid)
	if _grid_btn != null and is_instance_valid(_grid_btn):
		_grid_btn.add_theme_font_size_override("font_size", s(14))
		row.add_child(_grid_btn)
	threat_btn = _top_key("R", "threat", "Threat map (R): how much enemy fire can reach each hex next turn. The hatching (who can reach) shows anyway.")
	row.add_child(threat_btn)
	row.add_child(_top_key("T", "top", "Top-down view (T)"))
	speed_btn = _top_key("1x", "speed", "Battle speed: normal or fast")
	row.add_child(speed_btn)
	var mb := _top_key("Menu", "menu", "Menu (Esc): options, help, retreat, quit")
	mb.text = "Esc  Menu"
	row.add_child(mb)
	end_btn = _button("End turn", "end", null, true)
	end_btn.visible = false
	row.add_child(end_btn)


func _top_key(txt: String, act: String, tipt: String) -> Button:
	var b := _button(txt, act)
	b.tooltip_text = tipt
	b.custom_minimum_size = Vector2(s(32), 0)
	b.add_theme_font_size_override("font_size", s(14))
	return b


var top_row: HBoxContainer
var info_well: PanelContainer   # the top bar's right well: the enemy's crest and name, and Heat
var _grid_btn: Button


# board look C's "Grid (Z)" toggle: the sheet has no top bar for it, so it is kept off the screen; the Z key and the
# battle menu still work (the X and Z keys are unchanged in battle.gd).
func adopt_grid(b: Button) -> void:
	if b == null or not is_instance_valid(b):
		return
	_grid_btn = b
	b.visible = false


# the admiral's crest is not part of E1 LEDGER (the admiral's name is in the Command line); kept for the battle's call
func set_crest(_tex: Texture2D, _tip: String) -> void:
	_last["set_crest"] = [_tex, _tip]


# the Admiral's Command: the sheet draws it in the orders line with the C key
func set_command(label: String, ready: bool) -> void:
	_last["set_command"] = [label, ready]
	ledger.cmd = {"label": label, "ready": ready}
	ledger.mark()


func _size_key_button(b: Button) -> void:
	if b.has_meta("lbl"):
		b.custom_minimum_size.x = _kb_width(b)


func set_top(round_n: int, turn: String, objective: String, end_text: String, end_on: bool, speed_fast: bool, threat_on: bool) -> void:
	_last["set_top"] = [round_n, turn, objective, end_text, end_on, speed_fast, threat_on]
	ledger.top = {"round": round_n, "turn": turn, "objective": objective, "end_text": end_text, "end_on": end_on}
	ledger.mark()
	_round = round_n


# what the battle knows beyond the rows: the enemy's faction, its ship count, the run's Heat level
# info: {foe_name, foe_crest (Texture2D or null), foe_ships, heat (-1 hides the gauge), heat_tip}
func set_info(info: Dictionary) -> void:
	_last["set_info"] = [info]
	_info = info
	ledger.info = info
	ledger.mark()


# Retreat on the sheet: on when it can be used, off (dimmed) while it cannot
func set_retreat(on: bool, off: bool) -> void:
	_last["set_retreat"] = [on, off]
	ledger.retreat = {"on": on, "off": off}
	ledger.mark()


func _draw_heat() -> void:
	var n := 9
	var lit := clampi(int(_info.get("heat", 0)), 0, n)
	var gap := maxf(1.0, float(s(2)))
	var w := (heat_bar.size.x - gap * float(n - 1)) / float(n)
	for i in n:
		var r := Rect2(float(i) * (w + gap), 0, w, heat_bar.size.y)
		if i < lit:
			heat_bar.draw_rect(r, EMBER)
		else:
			heat_bar.draw_rect(r, Color(EMBER, 0.55), false, maxf(1.0, float(s(1))))


# the acted pips and "4/10 acted · then enemy"
func _refresh_acted() -> void:
	if pips == null:
		return
	var total := 0
	var acted := 0
	for r in _rows:
		if str(r.get("status", "")) == "Lost":
			continue
		total += 1
		if str(r.get("status", "")) == "Done":
			acted += 1
	var foes := int(_info.get("foe_ships", 0))
	var cell := float(s(9))
	var gap := float(s(3))
	var w := float(total) * (cell + gap) + (float(s(18)) + float(foes) * (cell + gap) if foes > 0 else 0.0)
	pips.custom_minimum_size = Vector2(minf(w, float(s(420))), s(12))
	pips.queue_redraw()
	acted_lbl.text = "%d/%d acted · then enemy" % [acted, total] if total > 0 else ""
	acted_lbl.visible = total > 0 and _phase_kind != "enemy"
	pips.visible = total > 0


func _draw_pips() -> void:
	var cell := float(s(9))
	var gap := float(s(3))
	var x := 0.0
	var h := pips.size.y
	var lw := maxf(1.0, float(s(1)))
	var room := pips.size.x
	var shown := 0
	for r in _rows:
		var st := str(r.get("status", ""))
		if st == "Lost":
			continue
		if x + cell > room:
			break
		var rc := Rect2(x, 0, cell, h)
		if st == "Done":
			pips.draw_rect(rc, VERD)
		elif st == "Up" or st == "Acting":
			pips.draw_rect(rc, GILT)
		else:
			pips.draw_rect(rc, Color(VERD, 0.9), false, lw)
		x += cell + gap
		shown += 1
	var foes := int(_info.get("foe_ships", 0))
	if foes > 0 and x + float(s(18)) < room:
		pips.draw_line(Vector2(x + s(3), h * 0.5), Vector2(x + s(13), h * 0.5), BONE3, lw)
		x += float(s(18))
		for i in foes:
			if x + cell > room:
				break
			pips.draw_rect(Rect2(x, 0, cell, h), Color(FOE_RING, 0.95), false, lw)
			x += cell + gap


# ---------------------------------------------------------------- the unacted set (under the top bar)
# How many ships still have to act and up to three names; the ships the enemy can reach come first, each with its badge.
# No arrows and no numbering: the player picks the order.

func _build_unacted() -> void:
	unacted = PanelContainer.new()
	unacted.add_theme_stylebox_override("panel", GS.strip(k, IRON3, Color(IRON3, 0.8)))
	unacted.mouse_filter = Control.MOUSE_FILTER_STOP
	unacted_row = HBoxContainer.new()
	unacted_row.add_theme_constant_override("separation", s(6))
	unacted.add_child(unacted_row)
	unacted.visible = false
	root.add_child(unacted)


func _refresh_unacted() -> void:
	if unacted == null:
		return
	for c in unacted_row.get_children():
		unacted_row.remove_child(c)
		c.queue_free()
	var ready: Array = []
	for r in _rows:
		if str(r.get("status", "")) == "Ready":
			ready.append(r)
	if ready.is_empty() or _phase_kind == "enemy" or _card_info.is_empty():
		unacted.visible = false
		return
	unacted.visible = true
	var inreach: Array = []
	var rest: Array = []
	for r in ready:
		if int(r.get("danger", 0)) > 0:
			inreach.append(r)
		else:
			rest.append(r)
	inreach.sort_custom(func(a, b): return int(a.get("danger", 0)) > int(b.get("danger", 0)))
	unacted_row.add_child(_label("%d unacted" % ready.size(), 14, BONE, font_semi))
	if not inreach.is_empty():
		unacted_row.add_child(_label("in reach first:", 13, BONE3))
	var order: Array = inreach + rest
	var n := mini(3, order.size())
	for i in n:
		var r: Dictionary = order[i]
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", GS.strip(k, FRIEND, Color(FRIEND, 0.35)))
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.tooltip_text = "Pick the %s" % str(r["name"])
		var id = r["id"]
		chip.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				action.emit("pick", id))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", s(5))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(_label(str(r["name"]), 14, FRIEND, font_semi))
		if int(r.get("danger", 0)) > 0:
			var bd := _badge(int(r["danger"]), 12)
			bd.mouse_filter = Control.MOUSE_FILTER_IGNORE
			h.add_child(bd)
		chip.add_child(h)
		unacted_row.add_child(chip)
	if order.size() > n:
		var more := _label("+%d" % (order.size() - n), 13, BONE2)
		more.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		unacted_row.add_child(more)
	unacted.reset_size()


# ---------------------------------------------------------------- roster (your fleet)

func _build_roster() -> void:
	roster = _panel(M, 8 + TOP_H + 6 + BAND_H + 6, -1, -1, FLEET_W, 10)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	roster.add_child(v)
	var hh := HBoxContainer.new()
	hh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hl := _label("FLEET", 13, GILT, font_caps)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(hl)
	roster_head = _label("", 13, BONE2, font_caps)
	hh.add_child(roster_head)
	var hw := PanelContainer.new()
	hw.add_theme_stylebox_override("panel", GS.well(k, Color(0, 0, 0, 0), 8, 3))
	hw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hw.add_child(hh)
	v.add_child(hw)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size.x = s(FLEET_W - 16)
	roster_sc = sc
	v.add_child(sc)
	roster_box = VBoxContainer.new()
	roster_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_box.add_theme_constant_override("separation", s(2))
	sc.add_child(roster_box)


# a side panel is as tall as what it holds, up to the room it has (then it scrolls)
func _fit(sc: ScrollContainer, box: VBoxContainer, p: PanelContainer, max_h: float) -> void:
	await get_tree().process_frame
	if not is_instance_valid(box) or not is_instance_valid(p):
		return
	_heights[p] = box.get_combined_minimum_size().y
	_apply_heights()


var _heights := {}                  # side panel -> the height of what it holds


# the fleet list is as tall as what it holds, but stops short of the log below it; past that it scrolls
func _apply_heights() -> void:
	if not _heights.has(roster) or log_panel == null:
		return
	var pr: Rect2 = roster.get_global_rect()
	var bottom := log_panel.get_global_rect().position.y - s(8)
	var head_h := float(s(30))
	var room := maxf(float(s(60)), bottom - pr.position.y - float(s(16)) - head_h)
	var h := minf(float(_heights[roster]), room)
	if absf(roster_sc.custom_minimum_size.y - h) > 0.5:
		roster_sc.custom_minimum_size.y = h
		roster.reset_size()


func set_roster(rows: Array) -> void:
	_last["set_roster"] = [rows]
	_rows = rows
	ledger.rows = rows
	ledger.mark()
	# rows: [{id, name, cls, hp, maxHp, sh: [4], shMax, status, sel, done, flag, new, danger}]


func _roster_row(r: Dictionary) -> Control:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	# Lime Tactical: the selected row is a lime-tinted solid with a lime edge; the rest sit on the well colour with a quiet
	# lime separator under each. Both fills are at the well's alpha (ui_style.md 3, WELL_A; #314 check condition 1), so
	# every name sits on a solid backing over the scene
	sb.bg_color = Color("#1b210d", GS.WELL_A) if r["sel"] else Color(GS.WELL, GS.WELL_A)
	sb.border_color = GILT if r["sel"] else Color(0, 0, 0, 0)
	sb.set_border_width_all(1 if r["sel"] else 0)
	sb.border_width_bottom = 1
	if not r["sel"]:
		sb.border_color = GS.LINE
	sb.content_margin_left = s(8)
	sb.content_margin_right = s(7)
	sb.content_margin_top = s(3)
	sb.content_margin_bottom = s(4)
	card.add_theme_stylebox_override("panel", sb)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.tooltip_text = str(r.get("cls", ""))
	var id = r["id"]
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			action.emit("pick", id))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(2))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# a ship that has acted dims its words and bars, never its backing (the backing stays solid)
	v.modulate.a = 0.55 if r["done"] else 1.0
	card.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(5))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 14, not 15: Chakra Petch is wider than the old Barlow (the Lime Tactical mockup does the same; still above the 12 floor)
	var nm := _label(("★ " if r["flag"] else "") + str(r["name"]), 14, BONE, font_semi)
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = s(90)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(nm)
	var f := clampf(float(r["hp"]) / maxf(float(r["maxHp"]), 1.0), 0.0, 1.0)
	if f < 0.35 and str(r["status"]) != "Lost":
		var low := _label("LOW", 12, HULL_LOW, font_caps)
		low.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		low.tooltip_text = "Hull below 35%."
		row.add_child(low)
	if int(r.get("danger", 0)) > 0 and str(r["status"]) != "Lost":
		row.add_child(_badge(int(r["danger"]), 12))
	if r.get("new", false):
		row.add_child(_label("NEW", 12, EMBER, font_caps))
	var st := str(r["status"])
	var stc := GILT if st in ["Up", "Acting"] else (FRIEND if st == "Ready" else (BLOOD if st == "Lost" else BONE3))
	var sl := _label(st, 13, stc, font_semi)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(sl)
	v.add_child(row)
	v.add_child(_hull_bar(float(r["hp"]), float(r["maxHp"]), 4))
	if float(r["shMax"]) > 0.0:
		v.add_child(_shield_quads(r["sh"], float(r["shMax"]), 2))
	return card


func _hull_bar(hp: float, mx: float, h: int, ghost_after := -1.0) -> Control:
	var f := clampf(hp / maxf(mx, 1.0), 0.0, 1.0)
	var col := HULL_LOW if f < 0.35 else HULL   # HD9: one hull-low line, 0.35, as the browser and the campaign bars (ui_spec.md 3; was 0.34)
	var g := clampf(ghost_after / maxf(mx, 1.0), 0.0, 1.0) if ghost_after >= 0.0 else -1.0
	return GS.seg_bar(k, f, col, GS.BAR_TRACK, h, 10, g)


func _shield_quads(sh: Array, mx: float, h := 3, ghost: Array = []) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(3))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the game's order on the strip: prow, starboard, rear, port (sh[0..3])
	for i in 4:
		var f := clampf(float(sh[i]) / maxf(mx, 1.0), 0.0, 1.0)
		var g := -1.0
		if ghost.size() == 4 and float(ghost[i]) > 0.5:
			g = clampf((float(sh[i]) - float(ghost[i])) / maxf(mx, 1.0), 0.0, 1.0)
		var c := GS.seg_bar(k, f, SHIELD, GS.SHIELD_TRACK, h, 1, g)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(c)
	return row


# ---------------------------------------------------------------- the shell: seven blocks in decision order

func _build_panel() -> void:
	panel = _panel(-1, 8, M, 8, COL_W, -1)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(6))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.custom_minimum_size.x = s(COL_W - 18)
	panel_sc = sc
	v.add_child(sc)
	panel_box = VBoxContainer.new()
	panel_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_box.add_theme_constant_override("separation", s(6))
	sc.add_child(panel_box)
	nem_well = _well(Color(0, 0, 0, 0), 10, 7)
	nem_well.add_theme_stylebox_override("panel", GS.well(k, Color(0, 0, 0, 0), 10, 7, ALERT))   # the reserved red bar
	up_well = _well()
	move_well = _well()
	fire_well = _well()
	orders_well = _well()
	target_well = _well()
	for w in [nem_well, up_well, move_well, fire_well, orders_well, target_well]:
		w.visible = false
		panel_box.add_child(w)
	up_well.mouse_entered.connect(_show_dtip)
	up_well.mouse_exited.connect(func() -> void: dtip.visible = false)
	# 3 End: fixed at the bottom of the shell, outside the scroll, so End ship never moves
	card = _well(Color(0, 0, 0, 0), 12, 9)
	card_box = VBoxContainer.new()
	card_box.add_theme_constant_override("separation", s(6))
	card.add_child(card_box)
	card.visible = false
	v.add_child(card)


func _clear(c: Control) -> void:
	for x in c.get_children():
		c.remove_child(x)
		x.queue_free()


func _rich(bb: String, size := 14) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bb
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_size_override("normal_font_size", s(size))
	r.add_theme_font_size_override("bold_font_size", s(size))
	r.add_theme_font_size_override("mono_font_size", s(size))
	return r


# rich text set in the number face (Azeret Mono): hull "312/370 to about 75" and the like
func _num_rich(bb: String, size := 14) -> RichTextLabel:
	var r := _rich(bb, size)
	r.add_theme_font_override("normal_font", font_num)
	r.add_theme_font_override("bold_font", font_num_b)
	return r


# --- Nemesis: who leads the enemy, what he adapted to, what you have found out about him
# info: {name, title, ship, flee, tex, adapted: [[name, effect, why]], weak: [[name, effect]], state ("" | fled | destroyed)}
func set_nemesis(info: Dictionary) -> void:
	_last["set_nemesis"] = [info]
	ledger.nem = info
	ledger.mark()


# --- the ship that is up (or the one you inspect): name, class and captain, hull, shields, armour, move, turns
func set_panel(info: Dictionary) -> void:
	_last["set_panel"] = [info]
	_panel_info = info
	ledger.ship = info
	ledger.detail_bb = recol(_detail_bb(info)) if not info.is_empty() else ""
	ledger.mark()


# four shield facings: a bar each with its name and number under it
func _facings(sh: Array, mx: float, ghost: Array = []) -> Control:
	var g := GridContainer.new()
	g.columns = 4
	g.add_theme_constant_override("h_separation", s(6))
	g.add_theme_constant_override("v_separation", s(1))
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var names := ["Prow", "Stbd", "Rear", "Port"]
	for i in 4:
		var gi := -1.0
		if ghost.size() == 4 and float(ghost[i]) > 0.5:
			gi = clampf((float(sh[i]) - float(ghost[i])) / maxf(mx, 1.0), 0.0, 1.0)
		var b := GS.seg_bar(k, clampf(float(sh[i]) / maxf(mx, 1.0), 0.0, 1.0), SHIELD, GS.SHIELD_TRACK, 4, 1, gi)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(b)
	for i in 4:
		var t := "[color=#7c8674]%s[/color] [color=#4fc4ff]%d[/color]" % [names[i], int(sh[i])]
		if ghost.size() == 4 and float(ghost[i]) > 0.5:
			t += " [color=#7c8674]to about %d[/color]" % maxi(0, int(round(float(sh[i]) - float(ghost[i]))))
		var l := _rich(t, 12)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g.add_child(l)
	return g


func _detail_bb(info: Dictionary) -> String:
	var bb := "[b]%s[/b]  [color=#a7b09d]%s[/color]" % [str(info.get("name", "")), str(info.get("cls", ""))]
	if str(info.get("captain", "")) != "":
		bb += "\n" + str(info["captain"])
	bb += "\n" + str(info.get("stats", ""))
	if info.get("secs") is Array and not (info["secs"] as Array).is_empty():
		var parts := PackedStringArray()
		for sc in info["secs"]:
			parts.append("%s %d/%d" % [str(sc[0]), int(sc[1]), int(sc[2])])
		bb += "\n[color=#a7b09d]Sections:[/color] " + ", ".join(parts)
	if str(info.get("note", "")) != "":
		bb += "\n" + str(info["note"])
	for ex in info.get("extra", []):
		bb += "\n[b]%s[/b]\n%s" % [str(ex[0]), str(ex[1])]
	if info.get("side", "") == "player":
		bb += "\n\n" + keys_text()
	return bb


# the ship's "more on hover" layer (the sheet shows it on hover over the ship's name; tools call this to show it at once)
func _show_dtip() -> void:
	if _panel_info.is_empty():
		return
	_ledger_tip(recol(_detail_bb(_panel_info)), Vector2(ledger.sheet_r.position.x, s(110)))


func keys_text() -> String:
	return "[font_size=%d][color=#a7b09d]Click a blue hex to plan a move, click it again (or [b]Enter[/b]) to go. Click an enemy to target it and see the odds, click it again (or [b]Enter[/b]) to fire. [b]Q[/b]/[b]E[/b] turn, [b]1[/b]-[b]6[/b] pick one weapon, [b]B[/b] brace, [b]X[/b] ram, [b]G[/b] board, [b]C[/b] Command, [b]Tab[/b] next ship, [b]Space[/b] end ship, [b]Esc[/b] cancel the plan. In the enemy turn [b]Enter[/b] or [b]Space[/b] hurries. Right-drag orbit, left-drag or WASD pan, wheel zoom, [b]T[/b] top-down, [b]R[/b] threat map, [b]V[/b] firing arcs, [b]F[/b] focus, [b]L[/b] full log, [b]Home[/b] reset view.[/color][/font_size]" % s(17)


func _sect(t: String) -> Control:
	return _head("", t)


# --- 2 Fire: one line per weapon, scanned left to right: key, name, arc and range token, hit, expected damage, cost
func _build_fire(info: Dictionary) -> void:
	fire_well.visible = true
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(4))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_well.add_child(v)
	var mine: bool = info.get("side", "") == "player"
	var tname := str(info.get("fire_at", ""))
	var right := ""
	if mine and tname != "":
		right = "%s, at [color=#c4a4ff]%s[/color]" % [str(info.get("fire_from", "from here")), tname]
	elif mine:
		right = str(info.get("fire_from", ""))
	var hh := _head("2" if mine else "", "Fire" if mine else "Weapons")
	if right != "":
		var rl := _rich("[right][color=#a7b09d]%s[/color][/right]" % right, 13)
		rl.autowrap_mode = TextServer.AUTOWRAP_OFF
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hh.remove_child(hh.get_child(hh.get_child_count() - 1))
		hh.add_child(rl)
	v.add_child(hh)
	v.add_child(_weapon_cols(["Weapon", "Arc", "Hit", "Dmg", "Cost"], true))
	for w in info["weapons"]:
		v.add_child(_weapon_row(w))


const WCOL := [26.0, 0.0, 52.0, 44.0, 40.0, 40.0]   # key, name (fills), arc, hit, dmg, cost


func _weapon_cols(cells: Array, head := false) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(6))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := Control.new()
	sp.custom_minimum_size.x = s(WCOL[0])
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sp)
	for i in cells.size():
		var l := _label(str(cells[i]), 12, BONE3, font_caps)
		if i == 0:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			l.custom_minimum_size.x = s(WCOL[i + 1])
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if i == 1 else HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(l)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", s(7))
	m.add_theme_constant_override("margin_right", s(7))
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(h)
	return m


func _weapon_row(w: Dictionary) -> Control:
	var p := PanelContainer.new()
	var armed: bool = w.get("armed", false)
	var sb := GS.well(k, GILT if armed else Color(0, 0, 0, 0), 7, 3)
	sb.bg_color = Color(GS.IRON, 0.9) if not armed else Color("#171d0c", 0.96)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.tooltip_text = str(w.get("desc", ""))
	var idx = w["i"]
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			action.emit("arm", idx))
	var dim := not bool(w.get("ready", true))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", s(6))
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kc := _keycap(str(int(idx) + 1))
	kc.custom_minimum_size.x = s(WCOL[0])
	h.add_child(kc)
	var n := _label(str(w["name"]), 15, BONE3 if dim else BONE, font_semi)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(n)
	var arc := str(w.get("arc", ""))
	var at := _label(("%s %s" % [arc, str(w.get("rng", ""))]).strip_edges(), 13, BONE, font_num_b)
	at.add_theme_stylebox_override("normal", GS.keycap(k))
	at.custom_minimum_size.x = s(WCOL[2])
	at.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	at.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	at.mouse_filter = Control.MOUSE_FILTER_PASS
	at.tooltip_text = str(w.get("arc_tip", ""))
	h.add_child(at)
	var hit := int(w.get("hit", -1))
	if hit >= 0:
		var hl := _label("%d%%" % hit, 15, GILT, font_num_b)
		hl.custom_minimum_size.x = s(WCOL[3])
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(hl)
		var dl := _label("~%d" % int(w.get("dmg", 0)), 15, BONE, font_num_b)
		dl.custom_minimum_size.x = s(WCOL[4])
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		dl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(dl)
	else:
		# a gun that cannot fire shows the reason in place of its odds
		var why := _label(str(w.get("why", w.get("right", ""))), 12, BONE3)
		why.tooltip_text = why.text
		why.mouse_filter = Control.MOUSE_FILTER_PASS
		why.custom_minimum_size.x = s(WCOL[3] + WCOL[4] + 6)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		why.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		why.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		h.add_child(why)
	var cost := str(w.get("cost", ""))
	var cl := _label(cost, 13, EMBER if cost.begins_with("CD") else BONE3, font_num)
	cl.custom_minimum_size.x = s(WCOL[5])
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cl.mouse_filter = Control.MOUSE_FILTER_PASS
	cl.tooltip_text = "Cooldown: rounds before it can fire again after firing." if cost.begins_with("CD") else "Free: it can fire every round."
	h.add_child(cl)
	p.add_child(h)
	return p


# --- Orders: three to a row, each with its key
func _build_orders(orders: Array) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(5))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orders_well.add_child(v)
	var hh := _head("", "Orders")
	if cmd_btn.get_parent() != null:
		cmd_btn.get_parent().remove_child(cmd_btn)
	hh.add_child(cmd_btn)
	v.add_child(hh)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", s(5))
	g.add_theme_constant_override("v_separation", s(5))
	for o in orders:
		var b := _key_button(str(o["text"]), str(o["act"]), o.get("arg"))
		b.disabled = not o.get("on", true)
		if b.disabled:
			(b.get_meta("lbl") as Label).add_theme_color_override("font_color", BONE3)
		b.tooltip_text = str(o.get("tip", "")) if str(o.get("tip", "")) != "" else str(o["text"])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.x = s(60)
		g.add_child(b)
	v.add_child(g)


# --- Target: the enemy you aim at (or hover), with what the volley is expected to take, hatched and labelled expected
# info: {name, cls, hp, maxHp, sh: [4], shMax, exp_hull, exp_sh: [4], line (bbcode), flag}
func set_target(info: Dictionary) -> void:
	_last["set_target"] = [info]
	ledger.target = info
	ledger.mark()


# ---------------------------------------------------------------- 1 Move and 3 End (from the activation card)
# The card's data (battle.gd _card_info) is split across the blocks: the Move step and its plan go in 1 Move, the Fire
# step's state heads 2 Fire, the hint goes to the block of the step you are on, and Next ship and End ship sit in 3 End.
# info: {name, cls, flag, tag, more, steps: [{n, label, detail, st}], hint, buttons: [{text, act, arg, on, primary, big, tip}]}

func set_card(info: Dictionary) -> void:
	_last["set_card"] = [info]
	ledger.card = info
	ledger.mark()


func _route_card() -> void:
	if move_well == null:
		return
	_clear(move_well)
	_clear(card_box)
	var info := _card_info
	if info.is_empty():
		move_well.visible = false
		# no ship is up (the enemy's turn, a bot, the end): the Fire block is a plain weapons table again
		if fire_well.get_child_count() > 0:
			var fv0 := fire_well.get_child(0) as VBoxContainer
			for nm in ["fire_hint", "fire_detail"]:
				var o := fv0.find_child(nm, false, false)
				if o != null:
					fv0.remove_child(o)
					o.queue_free()
			fire_well.add_theme_stylebox_override("panel", GS.well(k))
			fire_well.modulate.a = 1.0
			fv0.modulate.a = 1.0
		return
	var steps: Array = info.get("steps", [])
	var now := ""
	for st in steps:
		if str(st.get("st", "")) == "now":
			now = str(st.get("label", ""))
			break
	var hint_txt := str(info.get("hint", ""))
	var btns: Array = info.get("buttons", [])
	var local: Array = []      # confirm and cancel: they go with the hint
	var bottom: Array = []     # Next ship and End ship
	for b in btns:
		var a := str(b.get("act", ""))
		if a in ["next", "end"]:
			bottom.append(b)
		elif a in ["brace", "ability"] and orders_well.visible:
			continue   # the Orders block has them, with their keys
		else:
			local.append(b)
	# where the hint and its buttons go: the Fire block when you aim at something, else the step you are on
	var hint_to := "Move"
	if now == "Fire" or info.get("aim", false):
		hint_to = "Fire"
	elif now == "End ship" or steps.is_empty():
		hint_to = "End"
	# 1 Move
	var mv: Dictionary = {}
	for st in steps:
		if str(st.get("label", "")) == "Move":
			mv = st
	move_well.visible = not mv.is_empty()
	if not mv.is_empty():
		var lit: bool = str(mv.get("st", "")) == "now"
		move_well.add_theme_stylebox_override("panel", GS.well(k, GILT if lit else Color(0, 0, 0, 0)))
		move_well.modulate.a = 1.0
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", s(4))
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# a step that is off dims its words, never its backing (ui_style.md 3: the well stays solid)
		v.modulate.a = 0.5 if str(mv.get("st", "")) == "off" else 1.0
		v.add_child(_head("✓" if str(mv.get("st", "")) == "done" else "1", "Move", str(mv.get("detail", "")), BONE if lit else BONE2))
		if hint_to == "Move":
			_hint_into(v, hint_txt, local)
		move_well.add_child(v)
	# 2 Fire: lit when it is the step you are on; the hint goes on top of the table when aiming
	var fi: Dictionary = {}
	for st in steps:
		if str(st.get("label", "")) == "Fire":
			fi = st
	if fire_well.visible and fire_well.get_child_count() > 0:
		var lit2: bool = str(fi.get("st", "")) == "now"
		fire_well.add_theme_stylebox_override("panel", GS.well(k, GILT if lit2 else Color(0, 0, 0, 0)))
		fire_well.modulate.a = 1.0
		var fv := fire_well.get_child(0) as VBoxContainer
		fv.modulate.a = 0.6 if str(fi.get("st", "")) == "off" else 1.0   # the words dim, the well stays solid
		var old := fv.find_child("fire_hint", false, false)
		if old != null:
			fv.remove_child(old)
			old.queue_free()
		# the step number and its detail line belong to your own Fire table ("2 FIRE"); an enemy's table ("WEAPONS",
		# shown while you inspect or hover it mid-activation) has no step number and keeps its header (#314 check
		# condition 2)
		var hh: HBoxContainer = fv.get_child(0) as HBoxContainer if fv.get_child_count() > 0 else null
		var step_no: Label = hh.find_child("step_no", false, false) as Label if hh != null else null
		if not fi.is_empty() and step_no != null:
			step_no.text = "✓" if str(fi.get("st", "")) == "done" else "2"
			var det := _label(str(fi.get("detail", "")), 13, BONE if lit2 else BONE2)
			det.name = "fire_detail"
			var od := fv.find_child("fire_detail", false, false)
			if od != null:
				fv.remove_child(od)
				od.queue_free()
			fv.add_child(det)
			fv.move_child(det, 1)
		if hint_to == "Fire":
			var hb := VBoxContainer.new()
			hb.name = "fire_hint"
			hb.add_theme_constant_override("separation", s(4))
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_hint_into(hb, hint_txt, local)
			fv.add_child(hb)
	elif hint_to == "Fire":
		hint_to = "End"
	# 3 End, and what happens next
	var en: Dictionary = {}
	for st in steps:
		if str(st.get("label", "")) == "End ship":
			en = st
	var lit3: bool = str(en.get("st", "")) == "now"
	card.add_theme_stylebox_override("panel", GS.well(k, GILT if lit3 else Color(0, 0, 0, 0), 12, 9))
	card_box.add_child(_head("3" if not steps.is_empty() else "", "End, and what happens next" if not steps.is_empty() else str(info.get("name", "Your turn"))))
	if hint_to == "End":
		_hint_into(card_box, hint_txt, local)
	# the counted line: kept at its height even when no ship is Ready, so End ship never moves
	var cnt := _rich("", 14)
	cnt.name = "counted"
	cnt.custom_minimum_size = Vector2(s(COL_W - 44), s(20))
	card_box.add_child(cnt)
	var nxt := _rich("", 13)
	nxt.name = "next_line"
	nxt.custom_minimum_size.x = s(COL_W - 44)
	card_box.add_child(nxt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(8))
	for b in bottom:
		var big_end: bool = str(b.get("act", "")) == "end"
		var bt: Button
		if big_end:
			bt = _end_button(b)
		else:
			bt = _key_button(str(b["text"]), str(b["act"]), b.get("arg"), bool(b.get("primary", false)))
			bt.disabled = not bool(b.get("on", true))
			if bt.disabled:
				(bt.get_meta("lbl") as Label).add_theme_color_override("font_color", BONE3)
		bt.tooltip_text = str(b.get("tip", ""))
		bt.custom_minimum_size.y = s(46)
		if b.get("name", "") != "":
			bt.name = str(b["name"])
		row.add_child(bt)
	card_box.add_child(row)
	_refresh_end()


func _hint_into(v: Container, hint_txt: String, btns: Array) -> void:
	if hint_txt != "":
		var h := _rich(hint_txt, 14)
		h.custom_minimum_size.x = s(COL_W - 44)   # a fixed wrap width, so its height is measured right the first time
		v.add_child(h)
	if btns.is_empty():
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(6))
	for b in btns:
		# the step's confirm (Move here, Fire N weapons) is lit, not filled: End ship is the screen's one gold button
		var lit := bool(b.get("primary", false))
		var bt := _key_button(str(b["text"]), str(b["act"]), b.get("arg"), false)
		if lit:
			var lb := GS.lit_boxes(k)
			for st in ["normal", "hover", "pressed", "disabled"]:
				bt.add_theme_stylebox_override(st, lb[st])
			(bt.get_meta("lbl") as Label).add_theme_color_override("font_color", GILT)
		bt.disabled = not bool(b.get("on", true))
		bt.tooltip_text = str(b.get("tip", ""))
		bt.custom_minimum_size.y = s(32)
		if b.get("name", "") != "":
			bt.name = str(b["name"])
		row.add_child(bt)
	v.add_child(row)


# the counted line ("5 ships still Ready", Tab jumps to the next) and what happens after: who is up next, then the enemy
func _refresh_end() -> void:
	if card_box == null or not card.visible:
		return
	var cnt := card_box.find_child("counted", false, false) as RichTextLabel
	var nxt := card_box.find_child("next_line", false, false) as RichTextLabel
	if cnt == null or nxt == null:
		return
	var ready: Array = []
	var after_sel := false
	var next_name := ""
	for r in _rows:
		if r.get("sel", false):
			after_sel = true
			continue
		if str(r.get("status", "")) == "Ready":
			ready.append(r)
			if after_sel and next_name == "":
				next_name = str(r["name"])
	if next_name == "" and not ready.is_empty():
		next_name = str(ready[0]["name"])
	cnt.text = ("[color=#52f0c4]%d ship%s still Ready[/color] [color=#7c8674]·[/color] [color=#a7b09d]Tab jumps to the next[/color]" % [ready.size(), "" if ready.size() == 1 else "s"]) if ready.size() > 0 else ""
	var foes := int(_info.get("foe_ships", 0))
	var t := ""
	if next_name != "":
		t = "Then [color=#52f0c4]%s[/color] is up (Tab). " % next_name
	t += "After your ships, the [color=#c4a4ff]enemy turn[/color]%s." % ((": %d ship%s" % [foes, "" if foes == 1 else "s"]) if foes > 0 else "")
	nxt.text = "[color=#a7b09d]%s[/color]" % t


# ---------------------------------------------------------------- log ticker, banner, tip, chip, hint

func _build_log() -> void:
	# the full log (L, or "Log L" on the sheet): a box over the bottom right corner, where the sheet shows the last three lines
	log_panel = PanelContainer.new()
	log_panel.name = "full_log"
	log_panel.add_theme_stylebox_override("panel", _tipbox(16, 12))
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	log_panel.anchor_left = 1.0
	log_panel.anchor_right = 1.0
	log_panel.anchor_top = 1.0
	log_panel.anchor_bottom = 1.0
	log_panel.offset_left = -s(52 + LOG_W + 16)
	log_panel.offset_right = -s(36)
	log_panel.offset_bottom = -s(24)
	log_panel.offset_top = -s(24 + _log_h())
	log_panel.visible = log_open
	root.add_child(log_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(8))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	log_panel.add_child(v)
	var hh := HBoxContainer.new()
	hh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ht := _label("Battle log", 19, S_TEXT, font_semi)
	ht.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hh.add_child(ht)
	var lb := _button("Close  L", "log")
	lb.tooltip_text = "Close the full battle log (L)"
	hh.add_child(lb)
	v.add_child(hh)
	if log_text != null and is_instance_valid(log_text):   # a rebuild keeps the log's text
		_log_text_style()
		v.add_child(log_text)
		_log_bar()
		return
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.scroll_following = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_text_style()
	v.add_child(log_text)
	_log_bar()


func _log_text_style() -> void:
	log_text.add_theme_font_override("normal_font", font)
	log_text.add_theme_font_override("bold_font", font_semi)
	log_text.add_theme_font_size_override("normal_font_size", s(18))
	log_text.add_theme_font_size_override("bold_font_size", s(18))
	log_text.add_theme_constant_override("line_separation", s(4))


# the scroll bar shows only when the full log is open
func _log_bar() -> void:
	var sb := log_text.get_v_scroll_bar()
	sb.self_modulate.a = 1.0 if log_open else 0.0
	sb.mouse_filter = Control.MOUSE_FILTER_STOP if log_open else Control.MOUSE_FILTER_IGNORE


# the full log's height: most of the screen's height
func _log_h() -> float:
	if root != null:
		return maxf(200.0, root.get_viewport_rect().size.y / k * 0.62)
	return 600.0


func toggle_log() -> void:
	log_open = not log_open
	log_panel.offset_top = -s(24 + _log_h())
	log_panel.visible = log_open
	_log_bar()
	log_text.scroll_to_line(maxi(0, log_text.get_line_count() - 1))


# the log in the sheet's strengths: your side and the story in TEXT, the enemy and the system in TEXT2 (no colour codes
# for shield or hull damage: the words say it)
const LOG_COL := {"p": "#f0eade", "e": "#c4beb0", "s": "#f0eade", "x": "#c4beb0", "ember": "#f0eade"}


func add_log(m: String, c: String) -> void:
	var txt := m.replace("[", "(").replace("]", ")")
	var col: String = LOG_COL.get(c, "#f0eade")
	log_text.append_text("[color=#969084]R%d[/color]  [color=%s]%s[/color]\n" % [_round, col, txt])
	# Drop the oldest from the view only. Each entry ends in a newline, which leaves one empty paragraph after the last
	# entry, so 200 entries are 201 paragraphs. The rules log array is never touched here.
	while log_text.get_paragraph_count() > LOG_VIEW_MAX + 1:
		log_text.remove_paragraph(0)
	_log_lines.append(txt)
	if _log_lines.size() > LOG_VIEW_MAX:
		_log_lines = _log_lines.slice(_log_lines.size() - LOG_VIEW_MAX)
	if ledger != null:
		ledger.log_lines = _log_lines
		ledger.mark()


func _build_banner() -> void:
	# the banner ("Round 2", "Victory", a Command's name): a name in Big Shoulders over the scene with the dark halo
	banner_lbl = _label("", 46, S_TEXT, font_name)
	banner_lbl.set_anchors_preset(Control.PRESET_CENTER)
	banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	_halo(banner_lbl)
	banner_lbl.add_theme_constant_override("outline_size", maxi(4, s(12)))
	banner_lbl.modulate.a = 0.0
	root.add_child(banner_lbl)
	toast_lbl = _label("", 19, S_TEXT, font_semi)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = s(124)
	toast_lbl.offset_bottom = s(150)
	_halo(toast_lbl)
	toast_lbl.modulate.a = 0.0
	root.add_child(toast_lbl)


func banner(text: String, col := BONE, dur := 0.9) -> void:
	banner_lbl.text = text.to_upper()
	var c := col_of(col)
	banner_lbl.add_theme_font_size_override("font_size", maxi(s(28), Brand.fit_size(banner_lbl.text, font_name, s(64), _column().y - _column().x - s(80))))
	banner_lbl.add_theme_color_override("font_color", S_EMBER if c == S_EMBER else S_TEXT)
	_banner_t = 0.0
	_banner_dur = dur


func toast(text: String) -> void:
	toast_lbl.text = text
	_toast_t = 2.6 if text != "" else 0.0
	if text == "":
		toast_lbl.modulate.a = 0.0


func _build_tip() -> void:
	tip = PanelContainer.new()
	tip.add_theme_stylebox_override("panel", _tipbox())
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.visible = false
	tip_text = RichTextLabel.new()
	tip_text.bbcode_enabled = true
	tip_text.fit_content = true
	tip_text.scroll_active = false
	tip_text.custom_minimum_size = Vector2(s(340), 0)
	tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_text.add_theme_font_size_override("normal_font_size", s(18))
	tip_text.add_theme_font_size_override("bold_font_size", s(18))
	tip.add_child(tip_text)
	root.add_child(tip)
	# the sheet's hover layer: what moved off the sheet (the captain, armour, evasion and turns behind the ship's name; a
	# gun's damage and cost; the target's shields; the Nemesis; the keys)
	dtip = PanelContainer.new()
	dtip.add_theme_stylebox_override("panel", _tipbox(16, 12))
	dtip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dtip.visible = false
	dtip_text = RichTextLabel.new()
	dtip_text.bbcode_enabled = true
	dtip_text.fit_content = true
	dtip_text.scroll_active = false
	dtip_text.custom_minimum_size = Vector2(s(420), 0)
	dtip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dtip_text.add_theme_font_size_override("normal_font_size", s(18))
	dtip_text.add_theme_font_size_override("bold_font_size", s(18))
	dtip.add_child(dtip_text)
	root.add_child(dtip)


# a hover on the sheet: its tip beside the sheet (for the corners' words, beside them, toward the middle)
func _ledger_tip(t: String, at: Vector2) -> void:
	if t == "":
		dtip.visible = false
		return
	dtip_text.text = recol(t)
	dtip.visible = true
	dtip.reset_size()
	var vs := root.get_viewport_rect().size
	var p: Vector2
	if at.x < ledger.sheet_r.end.x:
		p = Vector2(ledger.sheet_r.end.x + s(8), at.y - s(6))
	else:
		p = Vector2(at.x - dtip.size.x - s(16), at.y - s(6))
		if at.y > vs.y * 0.5:
			p.y = at.y - dtip.size.y - s(12)
	p.y = clampf(p.y, float(s(8)), maxf(float(s(8)), vs.y - dtip.size.y - s(8)))
	p.x = clampf(p.x, float(s(8)), maxf(float(s(8)), vs.x - dtip.size.x - s(8)))
	dtip.position = p.round()


func show_tip(bb: String, at: Vector2) -> void:
	if bb == "":
		tip.visible = false
		return
	var rb := recol(bb)
	if tip_text.text != rb:
		tip_text.text = rb
	tip.visible = true
	tip.reset_size()
	_tip_at = at
	_place_tip()


var _tip_at := Vector2.ZERO


# the hover tip beside the cursor, kept inside the middle column (never over the fleet list or the shell) and off the
# log, the strip, the unacted set and the tip card (it moves above whichever it would cover, or below when no room)
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
	var t := float(s(8))
	p.y = clampf(p.y, t, maxf(t, vs.y - h - gap))
	for i in 3:
		var moved := false
		for c in [log_panel, tipcard, legend, aichip]:
			if c == null or not is_instance_valid(c) or not c.visible or c.modulate.a < 0.01:
				continue
			var cr: Rect2 = c.get_global_rect()
			if Rect2(p, Vector2(w, h)).intersects(cr):
				p.y = cr.position.y - h - gap if cr.position.y - h - gap >= t else cr.end.y + gap
				moved = true
		if not moved:
			break
	tip.position = p.round()


# the clear part of the screen, right of the sheet: Vector2(left x, right x)
func _column() -> Vector2:
	var vs := root.get_viewport_rect().size
	var l := float(s(M))
	if ledger != null and ledger.visible:
		l = ledger.sheet_r.end.x + float(s(10))
	var r := vs.x - s(M)
	return Vector2(l, maxf(l + s(200), r))


# how far right of the screen's middle the clear part's middle is, in pixels: the camera puts the board's centre there
# (camera_rig.gd screen_shift), so the ship it focuses is not under the sheet. 0 while the sheet is hidden (cut-ins).
func clear_shift() -> float:
	if root == null or ledger == null or not ledger.visible or ledger.modulate.a < 0.5 or not visible:
		return 0.0
	var vs := root.get_viewport_rect().size
	var c := _column()
	return maxf(0.0, (c.x + vs.x) * 0.5 - vs.x * 0.5)


func _build_chip() -> void:
	aichip = _label("", 19, S_TEXT2, font_semi)
	aichip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	aichip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aichip.grow_horizontal = Control.GROW_DIRECTION_BOTH
	aichip.offset_top = s(70)
	_halo(aichip)
	aichip.visible = false
	root.add_child(aichip)


func set_chip(txt: String) -> void:
	_last["set_chip"] = [txt]
	aichip.text = txt
	aichip.visible = txt != ""


# the previous build's key line along the bottom (kept for the tools; never shown: the keys are on the ship name's hover
# and in the menu)
func _build_hint() -> void:
	hint = _label("Right-drag orbit   Left-drag or WASD pan   Wheel zoom   T top-down   R threat   V arcs   L log   Tab next ship   Space end ship", 17, S_TEXT2)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.offset_top = -s(40)
	hint.offset_bottom = -s(14)
	root.add_child(hint)


# ---------------------------------------------------------------- terrain legend (ui3d.js refreshLegend)
# Only what is on this battlefield: the encounter, its zones and its terrain. Closed it is one line under the Nemesis, top
# right: the encounter's name and a swatch per terrain; a click opens the names and what each does, another click closes.

func _build_legend() -> void:
	legend = PanelContainer.new()
	legend.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	legend.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(legend)
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
		legend.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", s(8))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.alignment = BoxContainer.ALIGNMENT_END
		h.add_child(_label(title if title != "" else "Terrain", 19, S_TEXT2, font_semi))
		for r in rows:
			h.add_child(_swatch(str(r[1])))
		legend.add_child(h)
		legend.size = Vector2.ZERO
		legend.reset_size()
		return
	legend.add_theme_stylebox_override("panel", _tipbox(14, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(6))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := "[b]%s[/b]" % (title if title != "" else "Terrain")
	if str(_legend.get("desc", "")) != "":
		hb += "\n[color=#c4beb0]%s[/color]" % str(_legend["desc"])
	var head := _rich(recol(hb), 18)
	head.custom_minimum_size.x = s(380)
	v.add_child(head)
	for r in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", s(8))
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(_swatch(str(r[1])))
		var t := _rich(recol("[b]%s[/b] %s" % [str(r[0]), str(r[2])]), 18)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size.x = s(356)
		h.add_child(t)
		v.add_child(h)
	v.add_child(_label("Click to close", 17, S_TEXT2))
	legend.add_child(v)
	legend.size = Vector2.ZERO
	legend.reset_size()


# ---------------------------------------------------------------- nameplates
# E1: words on the board only for the ship that is up (ember) and the target (the Nemesis in its red); the ship under the
# pointer and the enemy acting now get theirs while they are; every other name waits for hover. Plain words with the
# map's dark halo: no strip, no bars, no tags (the hull and shields are on the sheet and on the hover tip).

func plate(id: String) -> Control:
	if plates.has(id):
		return plates[id]
	var c := VBoxContainer.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_constant_override("separation", 0)
	var tags := HBoxContainer.new()
	tags.name = "tags"
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tags.visible = false
	c.add_child(tags)
	var st := PanelContainer.new()
	st.name = "st"
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	c.add_child(st)
	var v := VBoxContainer.new()
	v.name = "v"
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st.add_child(v)
	var nm := _label("", 19, S_TEXT, font_semi)
	nm.name = "nm"
	_halo(nm)
	v.add_child(nm)
	var bars_c := Control.new()
	bars_c.name = "bars"
	bars_c.visible = false
	bars_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_c.set_meta("v", [1.0, 0.0, false, -1.0, -1.0])
	bars_c.draw.connect(func() -> void: _draw_plate_bars(bars_c))
	v.add_child(bars_c)
	plates_root.add_child(c)
	plates[id] = c
	return c


# hull: 8 segments over the strip's width; shield: one thin line under it. v = [hull f, shield f, has shields, ghost hull f, ghost shield f]
func _draw_plate_bars(c: Control) -> void:
	var v: Array = c.get_meta("v")
	var w := c.size.x
	var hh := float(s(4))
	var gap := maxf(1.0, float(s(2)))
	var n := 8
	var cw := (w - gap * float(n - 1)) / float(n)
	var f := float(v[0])
	var col := HULL_LOW if f < 0.35 else HULL   # HD9: one hull-low line at 0.35 (Muse check of #269)
	var fill := f * w
	var gx := float(v[3]) * w if float(v[3]) >= 0.0 else fill
	for i in n:
		var x0 := float(i) * (cw + gap)
		c.draw_rect(Rect2(x0, 0, cw, hh), GS.BAR_TRACK)
		if fill > x0:
			var xe := minf(x0 + cw, fill)
			c.draw_rect(Rect2(x0, 0, xe - x0, hh), col)
			if gx < xe:
				var hs := maxf(x0, gx)
				c.draw_rect(Rect2(hs, 0, xe - hs, hh), Color(GS.WELL, 0.7))
				var xx := hs
				while xx < xe:
					c.draw_line(Vector2(xx, hh), Vector2(minf(xx + hh, xe), 0), col, 1.0)
					xx += maxf(3.0, float(s(3)))
	if bool(v[2]):
		var y := hh + float(s(1))
		var sh := clampf(float(v[1]), 0.0, 1.0)
		c.draw_rect(Rect2(0, y, w, maxf(1.0, float(s(2)))), GS.SHIELD_TRACK)
		c.draw_rect(Rect2(0, y, w * sh, maxf(1.0, float(s(2)))), SHIELD)


# extra: {nem: bool, odds: "64% 2 guns", ghost: expected hull after the volley (or -1), target: bool}. The odds and the
# ghost are on the sheet now; the plate is the name only.
func set_plate(id: String, screen: Vector2, on: bool, name_txt: String, friend: bool, flag: bool, hp: float, mx: float, sh: float, shmx: float, up := false, extra := {}) -> void:
	var c := plate(id)
	c.visible = on
	if not on:
		return
	var nm := c.get_node("st/v/nm") as Label
	nm.text = name_txt
	var target: bool = extra.get("target", false)
	var col := S_EMBER if up else (S_NEM if bool(extra.get("nem", false)) else S_TEXT)
	# issue 221: an override sends THEME_CHANGED, which reshapes the label's text and re-sorts the plate; set it only when
	# the colour changes, not every frame for every ship
	if not nm.has_theme_color_override("font_color") or nm.get_theme_color("font_color") != col:
		nm.add_theme_color_override("font_color", col)
	c.set_meta("keep", up or target)
	var bars_c := c.get_node("st/v/bars") as Control
	var f := clampf(hp / maxf(mx, 1.0), 0.0, 1.0)
	var g := float(extra.get("ghost", -1.0))
	bars_c.set_meta("v", [f, clampf(sh / maxf(shmx, 1.0), 0.0, 1.0), shmx > 0.0, clampf(g / maxf(mx, 1.0), 0.0, 1.0) if g >= 0.0 else -1.0, -1.0])
	c.reset_size()
	c.position = screen - Vector2(c.size.x * 0.5, c.size.y)


# F1: nameplate declutter, once a frame after every plate is placed. prio: id -> 3 (up, targeted), 2 (hovered, acting),
# 1 (flagship), 0. Highest first, then nearer the camera (lower on screen); a plate of rank under 2 that would overlap a
# plate already shown is hidden. Any plate that would sit under a HUD panel is hidden whatever its rank (the up ship and
# the target are named in the shell anyway).
var plates_hidden := 0


# screen rects of the HUD panels a ship name must not sit under
func hud_blockers() -> Array:
	var out: Array = []
	if ledger != null and ledger.is_visible_in_tree():
		out.append(Rect2(ledger.sheet_r.position, Vector2(ledger.sheet_r.size.x - s(24), ledger.sheet_r.size.y)))
		for h in ledger.hits:
			if not Rect2(h["r"]).intersects(ledger.sheet_r):
				out.append(Rect2(h["r"]))
	for p in [log_panel, tipcard, legend]:
		if p != null and is_instance_valid(p) and (p as Control).is_visible_in_tree():
			out.append((p as Control).get_global_rect())
	return out


func _plate_rect(c: Control) -> Rect2:
	return Rect2(c.position, c.size)


func declutter_plates(prio: Dictionary) -> void:
	var blockers := hud_blockers()
	var items: Array = []
	for id in plates:
		var c: Control = plates[id]
		c.modulate.a = 1.0
		if c.visible:
			items.append([int(prio.get(id, 0)), c.position.y + c.size.y, id])
	items.sort_custom(func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1] > b[1])
	var shown: Array = []
	plates_hidden = 0
	for it in items:
		var c: Control = plates[it[2]]
		if not bool(c.get_meta("keep", false)) and int(it[0]) < 2:
			# E1: a name that is neither the ship that is up, the target, the hovered ship nor the enemy acting waits for hover
			c.modulate.a = 0.0
			continue
		var pr := _plate_rect(c).grow(s(1))
		if _hits_any(pr, blockers):
			c.modulate.a = 0.0
			plates_hidden += 1
			continue
		if int(it[0]) >= 2:
			# a plate that must stay: lift it above whatever it would cover (at most a few steps)
			for kk in 4:
				var hit := Rect2()
				var any := false
				for x in shown:
					if pr.intersects(x):
						hit = x
						any = true
						break
				if not any:
					break
				var dy: float = pr.end.y - hit.position.y + s(2)
				c.position.y -= dy
				pr.position.y -= dy
			if _hits_any(pr, blockers):
				c.modulate.a = 0.0
				plates_hidden += 1
				continue
			shown.append(pr)
			continue
		if _hits_any(pr, shown):
			c.modulate.a = 0.0
			plates_hidden += 1
			continue
		shown.append(pr)


func _hits_any(r: Rect2, rs: Array) -> bool:
	for x in rs:
		if r.intersects(x):
			return true
	return false


# for the trace: visible plates that overlap another visible plate (0 after the declutter)
func plate_name_overlaps() -> int:
	var rs: Array = []
	for id in plates:
		var c: Control = plates[id]
		if c.visible and c.modulate.a > 0.5:
			rs.append(_plate_rect(c))
	var n := 0
	for i in rs.size():
		for j in range(i + 1, rs.size()):
			if (rs[i] as Rect2).intersects(rs[j]):
				n += 1
	return n


# for the trace: visible ship plates that sit under a HUD panel
func plate_names_under_panels() -> int:
	var blockers := hud_blockers()
	var n := 0
	for id in plates:
		var c: Control = plates[id]
		if c.visible and c.modulate.a > 0.5 and _hits_any(_plate_rect(c), blockers):
			n += 1
	return n


# a floating callout over a ship ("-12 shield", "Miss", "Critical"); the battle scene moves and fades it
func make_float(text: String, col: Color) -> Label:
	var l := _label(text, 19, col_of(col), font_semi)
	_halo(l)
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
	tipcard = _panel(-1, 86, M + COL_W + 22, -1, 380, -1)
	tipcard.add_theme_stylebox_override("panel", _tipbox(18, 14))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(10))
	tipcard.add_child(v)
	var tl := _label(title, 21, S_TEXT, font_semi)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(s(340), 0)
	v.add_child(tl)
	var b := _rich(recol(body), 18)
	b.custom_minimum_size = Vector2(s(340), 0)
	v.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(12))
	row.add_child(_button("Got it", "tip_ok", id, true))
	row.add_child(_button("Turn off all tips", "tip_off"))
	v.add_child(row)


func hide_tipcard() -> void:
	_last.erase("show_tipcard")
	if tipcard != null:
		tipcard.queue_free()
		tipcard = null


# N4 (#282): the end card's focus grab retries once, so a transient focus holder that releases after the timer does not leave
# Continue unfocused. The guard still refuses to steal focus from a menu opened meanwhile (the owner keeps it).
func _grab_end_focus(first: Button, attempt := 1) -> void:
	if not is_instance_valid(first) or not first.is_visible_in_tree(): return
	if get_viewport().gui_get_focus_owner() == null: first.grab_focus()
	elif attempt < 2:
		get_tree().create_timer(0.75).timeout.connect(func() -> void: _grab_end_focus(first, attempt + 1), CONNECT_ONE_SHOT)


# a centred box (the end card and the menu): the hover tip's near-black square with its hairline edge, in the middle of
# the clear part of the screen. Its first child is the content (the menu's rows are read by index: row 0 is the title).
func _modal(pad_x: float, pad_y: float) -> Array:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _tipbox(pad_x, pad_y))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(p)
	return [p, p]


func show_end(title: String, body: String, win: bool, external := false) -> void:
	_last["show_end"] = [title, body, win, external]
	var mw := _modal(40, 30)
	endcard = mw[0]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(14))
	(mw[1] as Control).add_child(v)
	var t := _label(title.to_upper(), 56, S_EMBER if win else S_TEXT, font_name)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := _label(body, 19, S_TEXT2)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(s(520), 0)
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", s(14))
	if external:
		row.add_child(_button("Continue", "continue", null, true, true))
	else:
		row.add_child(_button("Fight again", "restart", null, true, true))
		row.add_child(_button("Quit", "quit", null, false, true))
	for c in row.get_children():
		(c as Button).custom_minimum_size = Vector2(s(180), s(56))
	v.add_child(row)
	# keyboard focus on the first button, after a beat: a Space still held down to hurry the last enemy turn must not
	# press Continue the moment the card appears (the battle's own 0.5 s guard on Space, battle.gd _on_key)
	var first := row.get_child(0) as Button
	get_tree().create_timer(0.75).timeout.connect(func() -> void: _grab_end_focus(first), CONNECT_ONE_SHOT)


# the in-battle menu (Esc with nothing to cancel, or Menu on the sheet): items are [text, action, arg]. body, when given,
# is a paragraph under the title (the Keys page).
var menu: PanelContainer


func show_menu(title: String, items: Array, row := -1, body := "") -> void:
	# a toggle in the menu builds it again: keep the keyboard on the same row
	var refocus := row if row >= 0 else 0
	if row < 0 and menu != null and is_instance_valid(menu):
		var fo := get_viewport().gui_get_focus_owner()
		if fo != null and menu.is_ancestor_of(fo):
			refocus = maxi(0, fo.get_index() - 1)   # row 0 is the title label
	hide_menu()
	_last["show_menu"] = [title, items, body]
	var mw := _modal(30, 22)
	menu = mw[0]
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(2))
	v.custom_minimum_size = Vector2(s(360), 0)
	(mw[1] as Control).add_child(v)
	var t := _label(title.to_upper(), 40, S_TEXT, font_name)
	v.add_child(t)
	for it in items:
		var bt := _button(str(it[0]), str(it[1]), it[2] if it.size() > 2 else null, it == items[0], true)
		bt.alignment = HORIZONTAL_ALIGNMENT_LEFT
		bt.custom_minimum_size.y = s(44)
		v.add_child(bt)
	if body != "":
		var bl := _rich(recol(body), 18)
		bl.custom_minimum_size = Vector2(s(560), 0)
		v.add_child(bl)
	if items.size() > 0:
		(v.get_child(1 + mini(refocus, items.size() - 1)) as Button).grab_focus.call_deferred()


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
	for c in [ledger, log_panel, legend]:
		if c != null:
			c.modulate.a = 0.0 if on else 1.0


# the loading cover while the battle warms up its shaders
var load_cover: ColorRect


func loading(on: bool) -> void:
	_last["loading"] = on
	if on and load_cover == null:
		load_cover = ColorRect.new()
		load_cover.color = Color(GS.INK, 1.0)
		load_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
		load_cover.mouse_filter = Control.MOUSE_FILTER_STOP
		var l := _label("PREPARING THE BATTLE", 40, S_TEXT, font_name)
		l.set_anchors_preset(Control.PRESET_CENTER)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.grow_vertical = Control.GROW_DIRECTION_BOTH
		load_cover.add_child(l)
		root.add_child(load_cover)
	elif not on and load_cover != null:
		load_cover.queue_free()
		load_cover = null


# Issue 529 (PR 533): a tree prompt (a "you may" skill's yes or no, a Chorus role) takes the shot's place in the sheet,
# with the skill's name, one line that says what the choice does, and its choices numbered. Keys 1 to 3 pick (battle.gd),
# so does a click. It stays until answered: the rules hold the open prompt (view().ask). ask_panel is the sheet while a
# prompt is open, so battle.gd's "a prompt is open" test (hud.ask_panel != null) reads as before.
func show_ask(a: Dictionary) -> void:
	var key := "%s|%s|%s" % [str(a.get("kind")), str(a.get("key")), str(a.get("id", ""))]
	if ask_panel != null and ask_key == key:
		return
	_last["show_ask"] = [a]
	ask_key = key
	ledger.ask = a
	ledger.mark()
	ask_panel = ledger


func hide_ask() -> void:
	_last.erase("show_ask")
	ask_key = ""
	if ledger != null:
		ledger.ask = {}
		ledger.mark()
	ask_panel = null


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
	var col := _column()
	# top right, under the Nemesis line: the terrain key, right aligned at the sheet's right margin
	var right := vs.x - s(52)
	var below := float(s(150))
	if legend != null and legend.visible:
		legend.reset_size()
		legend.position = Vector2(right - legend.size.x, below).round()
		below = legend.position.y + legend.size.y + s(10)
	if aichip.visible:
		aichip.reset_size()
		aichip.position = Vector2(clampf((col.x + col.y) * 0.5 - aichip.size.x * 0.5, col.x, maxf(col.x, col.y - aichip.size.x)), s(40)).round()
	# the onboarding tip card: right side of the clear part, under the corner's words
	if tipcard != null and is_instance_valid(tipcard):
		tipcard.position = Vector2(right - tipcard.size.x, below + s(6)).round()
	# toasts: centred in the clear part, near the top, below the tip card if they would meet
	if toast_lbl.modulate.a > 0.0:
		toast_lbl.reset_size()
		var w := toast_lbl.size.x
		var p := Vector2(clampf((col.x + col.y) * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), s(96))
		if tipcard != null and is_instance_valid(tipcard) and Rect2(p, toast_lbl.size).intersects(tipcard.get_global_rect()):
			p.x = maxf(col.x, tipcard.get_global_rect().position.x - w - s(16))
		toast_lbl.position = p.round()
	# the big banner: centred in the clear part
	if banner_lbl.modulate.a > 0.0:
		banner_lbl.reset_size()
		var w := banner_lbl.size.x
		banner_lbl.position = Vector2(clampf((col.x + col.y) * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), vs.y * 0.42 - banner_lbl.size.y * 0.5).round()
	# the menu and the end card: centred in the clear part
	for m in [menu, endcard]:
		if m != null and is_instance_valid(m):
			(m as Control).position.x = roundf(clampf((col.x + col.y) * 0.5 - (m as Control).size.x * 0.5, col.x, maxf(col.x, col.y - (m as Control).size.x)))
	if tip.visible:
		_place_tip()


# the widest the old activation card could be (kept for callers; the End block now lives in the shell)
func _card_room() -> float:
	return float(s(COL_W - 24))


func over_ui(p: Vector2) -> bool:
	if ledger != null and ledger.is_visible_in_tree() and ledger.modulate.a > 0.5 and ledger._has_point(p):
		return true
	for c in [log_panel, tipcard, endcard, menu, legend]:
		if c != null and is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return true
	return false


# ---------------------------------------------------------------- the turn strip (the enemy's turn)

var phase: PanelContainer
var phase_lbl: RichTextLabel
var phase_bar: ColorRect
var phase_fill: ColorRect
var _phase_sb: StyleBoxFlat


# the strip under the top bar in the enemy's turn: whose turn it is and how far along it is. In your turn the top bar
# and the unacted set carry the turn, so the strip hides.
func _build_phase() -> void:
	phase = PanelContainer.new()
	_phase_sb = GS.strip(k, FOE_RING, Color(FOE_RING, 0.6))
	_phase_sb.content_margin_left = s(16)
	_phase_sb.content_margin_right = s(16)
	_phase_sb.content_margin_top = s(3)
	_phase_sb.content_margin_bottom = s(4)
	phase.add_theme_stylebox_override("panel", _phase_sb)
	phase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(3))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase.add_child(v)
	phase_lbl = RichTextLabel.new()
	phase_lbl.bbcode_enabled = true
	phase_lbl.fit_content = true
	phase_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	phase_lbl.scroll_active = false
	phase_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_lbl.add_theme_font_size_override("normal_font_size", s(15))
	phase_lbl.add_theme_font_size_override("bold_font_size", s(15))
	v.add_child(phase_lbl)
	phase_bar = ColorRect.new()
	phase_bar.color = Color(0.2, 0.12, 0.3, 0.9)
	phase_bar.custom_minimum_size = Vector2(0, s(3))
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
	_phase_kind = kind
	ledger.phase = {"kind": kind, "text": bb, "p": progress}
	ledger.mark()
