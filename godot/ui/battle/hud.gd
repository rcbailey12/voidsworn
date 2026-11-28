extends CanvasLayer
# KEEL hands the battle's data to ledger.gd. This layer owns the full log,
# menus, hover tips, banners, toasts, floats and nameplates.

signal action(name: String, arg: Variant)
signal rescaled   # the HUD was rebuilt at a new size; the battle refreshes what it shows

const Brand := preload("res://ui/battle/brand.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const GS := preload("res://ui/theme/glass_shell.gd")
const Ledger := preload("res://ui/battle/ledger.gd")
const ModalFocus := preload("res://ui/theme/modal_focus.gd")

# the orders sheet palette (glass_shell.gd, R176; Glacier R210)
const S_EMBER := GS.MAP_EMBER
const S_TEXT := GS.TEXT
const S_TEXT2 := GS.TEXT2
const S_TEXT3 := GS.TEXT3
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
const LOG_W := 600.0     # the full log
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
# the last data the battle handed to the sheet (a contrib overlay tool reads _rows, _panel_info and _card_info)
var _rows: Array = []
var _info := {}
var _card_info := {}
var _phase_kind := ""
var log_panel: PanelContainer
var log_text: RichTextLabel
var log_open := false
var log_enabled := true
var log_collapsed := false
var banner_lbl: Label
var tip: PanelContainer
var tip_text: RichTextLabel
var dtip: PanelContainer            # the "more on hover" layer of the ship that is up
var dtip_text: RichTextLabel
var aichip: Label
const PlateLayer = preload("res://ui/battle/ship_plate_layer.gd")
var plates_root: PlateLayer
var floats_root: Control
var plates: Dictionary:
	get:
		return plates_root.plates
var plates_hidden: int:
	get:
		return plates_root.hidden_count
var tipcard: PanelContainer
var endcard: PanelContainer
var end_block: Control
var _end_first: Button = null   # the end card's first button, for the keyboard trap (issue 1559 item 13)
var _banner_t := 0.0
var _banner_dur := 0.0
var toast_lbl: Label
var _toast_t := 0.0
var legend: PanelContainer
var legend_open := false
var _legend := {}                   # {title, desc, rows: [[name, colour, effect]]}

var ledger                          # the orders sheet (ledger.gd): what the player sees
const CommsBanner := preload("res://ui/battle/comms_banner.gd")
var comms: CommsBanner
var comms_still := false
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
		plates_root = PlateLayer.new()
	root.add_child(plates_root)
	if floats_root == null:
		floats_root = Control.new()
		floats_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		floats_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(floats_root)
	_build_log()
	_build_ledger()
	_build_banner()
	_build_chip()
	_build_legend()
	_build_tip()
	if comms == null:
		comms = CommsBanner.new()
		comms.name = "TurnCorner"
	else:
		# Keep the active line and backlog when a scale change replaces the HUD root.
		comms.get_parent().remove_child(comms)
	root.add_child(comms)
	# the full log (L) sits over the sheet's corner; the banner, toasts, tips and dialogs over everything
	root.move_child(log_panel, ledger.get_index() + 1)


# the orders sheet: every setter hands it its data (ledger.gd lays it out and draws it)
func _build_ledger() -> void:
	ledger = Ledger.new()
	ledger.name = "ledger"
	ledger.k = k
	root.add_child(ledger)
	ledger.log_lines = _log_lines
	ledger.log_enabled = log_enabled
	ledger.log_collapsed = log_collapsed
	ledger.act.connect(func(n: String, arg: Variant) -> void: action.emit(n, arg))
	ledger.hover_tip.connect(_ledger_tip)
	# the board's hover tip belongs to the board: it goes when the pointer comes onto the sheet (the board gets no motion there)
	ledger.mouse_entered.connect(func() -> void: tip.visible = false)


# The window changed size: build every part again at the new scale and put back what each part showed. The battle log's
# text, floating callouts, plates and dialogs move across as they are.
func _rebuild() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_vs = vs
	var nk := scale_for(vs)
	if absf(nk - k) < 0.004 or root == null:
		return
	var keep := {
		"banner": banner_lbl.text, "banner_col": banner_lbl.get_theme_color("font_color"), "banner_a": banner_lbl.modulate.a,
		"toast": toast_lbl.text, "toast_a": toast_lbl.modulate.a,
		"tip": tip_text.text if tip != null and tip.visible else ""}
	var fleet_page: int = ledger.fleet_page
	var fleet_id: String = ledger._fleet_id
	# N5 (#282): a rebuild while the menu is open keeps its keyboard row. Read the row before the menu is thrown away.
	var keep_row := -1
	if menu != null and is_instance_valid(menu):
		var mfo := get_viewport().gui_get_focus_owner()
		if mfo != null and menu.is_ancestor_of(mfo): keep_row = maxi(0, mfo.get_index() - 1)
	plates_root.get_parent().remove_child(plates_root)
	floats_root.get_parent().remove_child(floats_root)
	log_text.get_parent().remove_child(log_text)
	remove_child(root)
	root.queue_free()
	menu = null
	menu_block = null
	endcard = null
	end_block = null
	tipcard = null
	bars = []
	load_cover = null
	ask_panel = null
	k = nk
	_scaled_fonts()
	_build_all()
	ledger.fleet_page = fleet_page
	ledger._fleet_id = fleet_id
	for key in ["set_crest", "set_info", "set_command", "set_top", "set_roster", "set_nemesis", "set_panel", "set_target", "set_legend", "set_chip", "set_phase", "set_card", "set_retreat", "set_playing"]:
		if _last.has(key):
			callv(key, _last[key])
	if _last.has("show_tipcard"):
		callv("show_tipcard", _last["show_tipcard"])
	if _last.has("show_end"):
		callv("show_end", _last["show_end"])
	if _last.has("show_menu"):
		var sm: Array = _last["show_menu"]
		show_menu(sm[0], sm[1], keep_row, str(sm[2]) if sm.size() > 2 else "")
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
	if banner_lbl.text != "":
		_fit_banner()   # issue 1559 item 29: the banner keeps its fitted size at the new scale
	if str(keep["tip"]) != "":
		show_tip(str(keep["tip"]), get_viewport().get_mouse_position())   # and the hover tip that was up stays up
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


func _label(txt: String, size := 17, col := BONE, f: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", s(size))
	l.add_theme_color_override("font_color", col)
	if f != null:
		l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# keys: the button takes keyboard focus (Tab, the arrows, Enter or Space press it). Only for the menu and the end card,
# where the battle's own keys are not in play; everywhere else Space, Enter and Tab drive the battle (ui_spec.md 6.2).
func _button(txt: String, act: String, arg: Variant = null, primary := false, keys := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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


# ---------------------------------------------------------------- the setters the battle calls (data goes to the sheet)

# the admiral's crest is not part of E1 LEDGER (the admiral's name is in the Command line); kept for the battle's call
func set_crest(_tex: Texture2D, _tip: String) -> void:
	_last["set_crest"] = [_tex, _tip]


# The action is a once-per-battle Command, not a point counter.
func set_command(label: String, ready: bool, available := false, armed := false, tip := "") -> void:
	_last["set_command"] = [label, ready, available, armed, tip]
	ledger.cmd = {"label": label, "id": label, "ready": ready, "available": available, "active": armed, "tip": tip}
	ledger.mark()


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


func set_roster(rows: Array) -> void:
	_last["set_roster"] = [rows]
	_rows = rows
	ledger.rows = rows
	ledger.mark()
	# rows: [{id, name, cls, hp, maxHp, sh: [4], shMax, status, sel, done, flag, new, danger}]


func _rich(bb: String, size := 17) -> RichTextLabel:
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


# --- Nemesis: who leads the enemy, what he adapted to, what you have found out about him
# info: {name, title, ship, flee, tex, adapted: [[name, effect, why]], weak: [[name, effect]], state ("" | fled | destroyed)}
func set_nemesis(info: Dictionary) -> void:
	_last["set_nemesis"] = [info]
	ledger.nem = info
	ledger.mark()


# --- the ship that is up (or the one you inspect): name, class and captain, hull, shields, armour, move, turns
# issue 1708 (Ryan, Nov 22): the bottom sheet hides while an event plays and comes back when it ends
func set_playing(on: bool) -> void:
	_last["set_playing"] = [on]
	if ledger.playing == on:
		return
	ledger.playing = on
	ledger.mark()


func set_panel(info: Dictionary) -> void:
	_last["set_panel"] = [info]
	_panel_info = info
	ledger.ship = info
	ledger.detail_bb = recol(_detail_bb(info)) if not info.is_empty() else ""
	ledger.mark()


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
	for loss in info.get("section_losses", PackedStringArray()):
		bb += "\n" + loss
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
	ledger.ensure_layout()
	_ledger_tip(recol(_detail_bb(_panel_info)), ledger.sheet_r.position + Vector2(s(Ledger.MARGIN), s(28)))


func keys_text() -> String:
	return "[font_size=%d][color=#a7b09d]Plan the ship's turn on its ghost: click a blue hex to move the ghost, [b]Q[/b]/[b]E[/b] turn it, click enemies to aim the guns that bear from it. Click the hex or a target again (or [b]Enter[/b]) and it all plays out at once. [b]1[/b]-[b]6[/b] pick one weapon, [b]B[/b] brace, [b]X[/b] ram, [b]G[/b] board, [b]C[/b] Command, [b]Tab[/b] next ship, [b]Space[/b] end ship, [b]Backspace[/b] take back the plan's last step (after a move has played, the last move or turn, until the ship fires), [b]Esc[/b] clear the plan. In the enemy turn [b]Enter[/b] or [b]Space[/b] hurries. [b]K[/b] skips more cut-ins of the current routine shot kind or stops routine enemy camera follow for this battle. Right-drag orbit, left-drag or WASD pan, wheel zoom, [b]T[/b] top-down, [b]R[/b] threat map, [b]V[/b] firing arcs, [b]F[/b] focus, [b]Z[/b] tactical grid, [b]L[/b] full log, [b]Home[/b] reset view.[/color][/font_size]" % s(17)




# --- Target: the enemy you aim at (or hover), with what the volley is expected to take, hatched and labelled expected
# Side coverage is hover detail; the standing preview reads the two pooled damage amounts.
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


# ---------------------------------------------------------------- log ticker, banner, tip, chip, hint

func _build_log() -> void:
	# L opens the full history. The shelf's separate ticker only shows recent outcomes.
	log_panel = PanelContainer.new()
	log_panel.name = "full_log"
	log_panel.add_theme_stylebox_override("panel", _tipbox(16, 12))
	log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	log_panel.anchor_left = 1.0
	log_panel.anchor_right = 1.0
	log_panel.anchor_top = 1.0
	log_panel.anchor_bottom = 1.0
	log_panel.visible = log_open and not bool(_last.get("letterbox", false))
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
	var lb := _button("Close", "log")
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


func toggle_log() -> void:
	log_open = not log_open
	log_panel.visible = log_open and not bool(_last.get("letterbox", false))
	if log_open:
		# issue 1559 item 10: the open log draws over the terrain key, and _layout puts the tip card beside it, so its Close
		# button is never under either
		log_panel.move_to_front()
		for c in [end_block, endcard, menu_block, menu]:   # the overlays stay on top of it
			if c != null and is_instance_valid(c):
				c.move_to_front()
	_layout_log()
	_log_bar()
	log_text.scroll_to_line(maxi(0, log_text.get_line_count() - 1))


func set_log_preferences(enabled: bool, collapsed: bool) -> void:
	if log_enabled == enabled and log_collapsed == collapsed:
		return
	log_enabled = enabled
	log_collapsed = collapsed
	if ledger != null:
		ledger.log_enabled = enabled
		ledger.log_collapsed = collapsed
		ledger.mark()


func _layout_log() -> void:
	if not log_open:
		return
	ledger.ensure_layout()
	var vs := root.get_viewport_rect().size
	var bottom: float = ledger.sheet_r.position.y - s(12)
	var h := minf(vs.y * 0.54, bottom - s(154))
	var margin := s(Ledger.MARGIN)
	log_panel.offset_right = -margin
	log_panel.offset_left = -margin - minf(s(LOG_W), vs.x * 0.75)
	log_panel.offset_bottom = bottom - vs.y
	log_panel.offset_top = bottom - h - vs.y


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
	_fit_banner()
	banner_lbl.add_theme_color_override("font_color", S_EMBER if c == S_EMBER else S_TEXT)
	_banner_t = 0.0
	_banner_dur = dur


func toast(text: String) -> void:
	toast_lbl.text = text
	_toast_t = 2.6 if text != "" else 0.0
	if text == "":
		toast_lbl.modulate.a = 0.0
	elif root != null:
		# issue 1559 item 29: placed now, so a new toast never draws one frame at the old toast's spot
		toast_lbl.modulate.a = maxf(toast_lbl.modulate.a, 0.01)
		_layout()


# the banner's size: as large as fits the clear part (kept across a HUD rebuild, issue 1559 item 29)
func _fit_banner() -> void:
	banner_lbl.add_theme_font_size_override("font_size", maxi(s(28), Brand.fit_size(banner_lbl.text, font_name, s(64), _column().y - _column().x - s(80))))


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


# Keep detail tips off the controls. Shelf tips open upward; corner tips face the board.
func _ledger_tip(t: String, at: Vector2) -> void:
	if t == "" or bool(_last.get("letterbox", false)):
		dtip.visible = false
		return
	dtip_text.text = recol(t)
	dtip.visible = true
	dtip.reset_size()
	var vs := root.get_viewport_rect().size
	var p: Vector2
	if at.y >= ledger.sheet_r.position.y:
		p = Vector2(at.x, ledger.sheet_r.position.y - dtip.size.y - s(10))
		if p.x + dtip.size.x > vs.x * 0.67 and ledger.log_r.has_area():
			p.y = ledger.log_r.position.y - dtip.size.y - s(10)
	elif at.x < vs.x * 0.5:
		p = at + Vector2(s(20), s(28))
	else:
		p = Vector2(at.x - dtip.size.x - s(16), at.y - s(6))
	p.y = clampf(p.y, float(s(8)), maxf(float(s(8)), vs.y - dtip.size.y - s(8)))
	p.x = clampf(p.x, float(s(8)), maxf(float(s(8)), vs.x - dtip.size.x - s(8)))
	dtip.position = p.round()


func show_tip(bb: String, at: Vector2) -> void:
	if bb == "" or bool(_last.get("letterbox", false)):
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
	ledger.ensure_layout()
	var low: float = ledger.sheet_r.position.y - h - gap
	p.y = clampf(p.y, t, maxf(t, low))
	var avoid: Array = ledger.blockers.duplicate()
	var si := avoid.find(ledger.sheet_r)
	if si >= 0:
		avoid.remove_at(si)   # issue 1708: no sheet blocker while an event plays
	for c in [log_panel, tipcard, legend, aichip]:
		if c != null and is_instance_valid(c) and c.visible and c.modulate.a >= 0.01:
			avoid.append(c.get_global_rect())
	for i in 3:
		var moved := false
		for cr in avoid:
			if Rect2(p, Vector2(w, h)).intersects(cr):
				p.y = cr.position.y - h - gap if cr.position.y - h - gap >= t else cr.end.y + gap
				moved = true
		if not moved:
			break
	tip.position = p.round()


# The clear board now spans the full width.
func _column() -> Vector2:
	var vs := root.get_viewport_rect().size
	var l := float(s(M))
	var r := vs.x - s(M)
	return Vector2(l, maxf(l + s(200), r))


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
			toggle_legend()
			legend.accept_event())


func toggle_legend() -> void:
	legend_open = not legend_open
	_draw_legend()


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


# ---------------------------------------------------------------- ship state plates

# screen rects of the HUD panels a ship name must not sit under
func hud_blockers() -> Array:
	var out: Array = []
	if ledger != null and ledger.is_visible_in_tree() and ledger.modulate.a > 0.5:
		ledger.ensure_layout()
		out.append_array(ledger.blockers)
	for p in [log_panel, tipcard, legend] + bars:
		if p != null and is_instance_valid(p) and (p as Control).is_visible_in_tree():
			out.append((p as Control).get_global_rect())
	# Ship labels can move out of the way, but the banner is never included in over_ui().
	if is_instance_valid(comms) and comms.is_visible_in_tree() and comms.modulate.a > 0.5:
		out.append(comms.get_global_rect())
	return out


# for the trace: visible ship plates that sit under a HUD panel
func plate_names_under_panels() -> int:
	var blockers := hud_blockers()
	var n := 0
	for id in plates:
		var c: Control = plates[id]
		if c.visible and blockers.any(func(r: Rect2) -> bool: return c.get_rect().intersects(r)):
			n += 1
	return n


# a floating callout over a ship ("-12 shield", "Miss", "Critical"); the battle scene moves and fades it
func make_float(text: String, col: Color) -> Label:
	var l := _label(text, 19, col_of(col), font_semi)
	_halo(l)
	floats_root.add_child(l)
	l.reset_size()
	return l


func remove_plate(id: String) -> void:
	plates_root.remove_ship(id)


# ---------------------------------------------------------------- onboarding tip card and end card

func show_tipcard(id: String, title: String, body: String) -> void:
	hide_tipcard()
	_last["show_tipcard"] = [id, title, body]
	# the orders sheet's one kind of box besides the action (R191, screens.md 2): a near-black square with a hairline edge;
	# the name in Big Shoulders, the sentences in the second strength, "Got it" the one ember action box. No frame marks.
	tipcard = PanelContainer.new()
	tipcard.name = "tipcard"
	tipcard.add_theme_stylebox_override("panel", _tipbox(20, 16))
	tipcard.mouse_filter = Control.MOUSE_FILTER_STOP
	# the battle's place: top right, the sheet's margin plus the tip column in from the edge (the campaign moves it, campaign_tips.gd)
	tipcard.anchor_left = 1.0
	tipcard.anchor_right = 1.0
	tipcard.anchor_top = 0.0
	tipcard.anchor_bottom = 0.0
	tipcard.offset_left = -s(M + COL_W + 22 + 380)
	tipcard.offset_right = -s(M + COL_W + 22)
	tipcard.offset_top = s(86)
	tipcard.offset_bottom = s(86)
	tipcard.grow_vertical = Control.GROW_DIRECTION_END
	root.add_child(tipcard)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(12))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tipcard.add_child(v)
	var tl := _label(title.to_upper(), 28, S_TEXT, font_name)
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.custom_minimum_size = Vector2(s(340), 0)
	v.add_child(tl)
	var b := _rich("[color=#%s]%s[/color]" % [S_TEXT2.to_html(false), recol(body)], 18)
	b.custom_minimum_size = Vector2(s(340), 0)
	v.add_child(b)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", s(12))
	row.add_child(_button("Got it", "tip_ok", id, true))
	var off := _button("Turn off all tips", "tip_off")
	off.add_theme_color_override("font_color", S_TEXT2)
	row.add_child(off)
	v.add_child(row)
	_sync_tipcard()


func hide_tipcard() -> void:
	_last.erase("show_tipcard")
	if tipcard != null:
		tipcard.queue_free()
		tipcard = null


# issue 1559 item 13: the card holds the keyboard through the shared trap (ui/theme/modal_focus.gd), so a menu opened over
# it (Esc) hands focus back to the card when it closes and Enter or Space work again. While another overlay is open (Esc
# pressed inside the 0.75 s beat) the card waits; hide_menu calls this again at once.
# Issue 1482: the timers hold a weak reference, never the button itself: an end card closed (or a battle left) inside the
# beat frees the button, and a lambda that captured it logs "Lambda capture at index 0 was freed" when it fires.
func _grab_end_focus(first_ref: WeakRef) -> void:
	var first = first_ref.get_ref()
	if not is_inside_tree() or endcard == null or not is_instance_valid(endcard) or first != _end_first or not is_instance_valid(first) \
		or not (first as Button).is_visible_in_tree():
		return
	if endcard.get_node_or_null("modal_focus") != null:
		return   # already holds it
	if ModalFocus.any_open():
		get_tree().create_timer(0.25).timeout.connect(_grab_end_focus.bind(first_ref), CONNECT_ONE_SHOT)
		return
	ModalFocus.attach(endcard, first)


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


func show_end(title: String, body: String, win: bool, external := false, continue_label := "Continue") -> void:
	hide_end()
	_last["show_end"] = [title, body, win, external, continue_label]
	end_block = ModalFocus.blocker(root)
	end_block.mouse_force_pass_scroll_events = false
	var mw := _modal(40, 30)
	endcard = mw[0]
	for c in [menu_block, menu]:
		if is_instance_valid(c):
			c.move_to_front()
	_sync_tipcard()
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
		row.add_child(_button(continue_label, "continue", null, true, true))
	else:
		row.add_child(_button("Fight again", "restart", null, true, true))
		row.add_child(_button("Quit", "quit", null, false, true))
	for c in row.get_children():
		(c as Button).custom_minimum_size = Vector2(s(180), s(56))
	v.add_child(row)
	# keyboard focus on the first button, after a beat: a Space still held down to hurry the last enemy turn must not
	# press Continue the moment the card appears (the battle's own 0.5 s guard on Space, battle.gd _on_key)
	var first := row.get_child(0) as Button
	_end_first = first
	get_tree().create_timer(0.75).timeout.connect(_grab_end_focus.bind(weakref(first)), CONNECT_ONE_SHOT)


# the in-battle menu (Esc with nothing to cancel, or Menu on the sheet): items are [text, action, arg]. body, when given,
# is a paragraph under the title (the Keys page).
var menu: PanelContainer
var menu_block: Control = null   # issue 1559 item 1: the clear sheet under the menu that keeps clicks off the board


func show_menu(title: String, items: Array, row := -1, body := "") -> void:
	# a toggle in the menu builds it again: keep the keyboard on the same row
	var refocus := row if row >= 0 else 0
	if row < 0 and menu != null and is_instance_valid(menu):
		var fo := get_viewport().gui_get_focus_owner()
		if fo != null and menu.is_ancestor_of(fo):
			refocus = maxi(0, fo.get_index() - 1)   # row 0 is the title label
	hide_menu()
	_last["show_menu"] = [title, items, body]
	# issue 1559 item 1: the menu is modal. A clear sheet under it eats every click (the board, the sheet, the log), the
	# keyboard stays inside it (ui/theme/modal_focus.gd), and battle.gd lets only Esc through to the battle.
	menu_block = ModalFocus.blocker(root)
	var mw := _modal(30, 22)
	menu = mw[0]
	ModalFocus.attach(menu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(2))
	v.custom_minimum_size = Vector2(s(360), 0)
	# issue 1559 item 2: the rows scroll inside a box no taller than the screen (about 20 rows ran off the top and bottom at
	# Large and Larger, and the UI scale toggle lives in this menu). The keyboard scrolls it (follow_focus); row 0 is still
	# the title, so the rows keep their indices.
	var sc := ScrollContainer.new()
	sc.name = "menu_scroll"
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.follow_focus = true
	(mw[1] as Control).add_child(sc)
	sc.add_child(v)
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
	var want := v.get_combined_minimum_size()
	var room: float = get_viewport().get_visible_rect().size.y - float(s(22)) * 2.0 - float(s(16)) * 2.0
	var tall := want.y > room
	sc.custom_minimum_size = Vector2(want.x + (float(sc.get_v_scroll_bar().get_combined_minimum_size().x) + s(6) if tall else 0.0), minf(want.y, maxf(room, float(s(120)))))
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if tall else ScrollContainer.SCROLL_MODE_DISABLED
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
	# issue 1559 item 12: the faded sheet, log and legend let the mouse through to the cut-in (a click skips it, no hover
	# tips pop over it, a hidden fleet slot cannot pick a ship); item 19: the teaching tip card steps out of the cut-in too
	for c in [ledger, log_panel, legend]:
		if c != null:
			c.modulate.a = 0.0 if on else 1.0
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP
	# the open full log's own Close and scroll bar would still take clicks under a transparent parent: it steps out of the
	# cut-in whole and comes back open (Artoo on PR 1601)
	if log_panel != null:
		log_panel.visible = log_open and not on
	if on and tip != null:
		tip.visible = false
		dtip.visible = false
	_sync_tipcard()


# issue 1559 item 19: the teaching tip card is hidden (kept, not dismissed) under the end card and during a cut-in
func _sync_tipcard() -> void:
	if tipcard != null and is_instance_valid(tipcard):
		tipcard.visible = not bool(_last.get("letterbox", false)) and (endcard == null or not is_instance_valid(endcard))


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
		# issue 1434: a count under the title while the ships are built a few per frame, so the cover visibly moves
		load_count = _label("", 22, S_TEXT, font_name)
		load_count.set_anchors_preset(Control.PRESET_CENTER)
		load_count.grow_horizontal = Control.GROW_DIRECTION_BOTH
		load_count.grow_vertical = Control.GROW_DIRECTION_BOTH
		load_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		load_count.offset_top = s(56)
		load_count.offset_bottom = s(56)
		load_count.modulate.a = 0.75
		load_cover.add_child(load_count)
		root.add_child(load_cover)
	elif not on and load_cover != null:
		load_cover.queue_free()
		load_cover = null
		load_count = null


var load_count: Label


# issue 1434: "SHIPS READY 7 / 24" on the cover; a total of 0 clears it (the warm-up after the ships are built)
func loading_count(n: int, total: int) -> void:
	if load_count == null or not is_instance_valid(load_count):
		return
	load_count.text = "SHIPS READY %d / %d" % [n, total] if total > 0 else ""


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


# the menu row the keyboard is on (row 0 is the first item), or -1 with no menu or no focus in it
func menu_row() -> int:
	if menu == null or not is_instance_valid(menu):
		return -1
	var fo := get_viewport().gui_get_focus_owner()
	if fo != null and menu.is_ancestor_of(fo):
		return maxi(0, fo.get_index() - 1)   # row 0 is the title label
	return -1


func hide_menu() -> void:
	_last.erase("show_menu")
	if menu != null:
		menu.queue_free()
		menu = null
	if menu_block != null and is_instance_valid(menu_block):
		menu_block.queue_free()
	menu_block = null
	if endcard != null and is_instance_valid(endcard) and _end_first != null and is_instance_valid(_end_first):
		_grab_end_focus.call_deferred(weakref(_end_first))


func hide_end() -> void:
	_last.erase("show_end")
	if endcard != null:
		endcard.queue_free()
		endcard = null
	_end_first = null
	if is_instance_valid(end_block):
		end_block.queue_free()
	end_block = null
	_sync_tipcard()


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


func _layout() -> void:
	var vs := root.get_viewport_rect().size
	var col := _column()
	_layout_log()
	if not comms.current.is_empty() or not comms.pending.is_empty():
		ledger.ensure_layout()
		comms.place(ledger.comms_slot, k, comms_still, ledger.visible and not log_open
			and not is_instance_valid(menu) and not is_instance_valid(endcard)
			and not bool(_last.get("loading", false)) and ledger.ask.is_empty())
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
		if log_open and log_panel != null and tipcard.get_global_rect().intersects(log_panel.get_global_rect()):
			tipcard.position.x = roundf(maxf(col.x, log_panel.get_global_rect().position.x - tipcard.size.x - s(16)))   # item 10
	# toasts: centred in the clear part, near the top, below the tip card if they would meet
	# the big banner: centred in the clear part
	if banner_lbl.modulate.a > 0.0:
		banner_lbl.reset_size()
		var w := banner_lbl.size.x
		banner_lbl.position = Vector2(clampf((col.x + col.y) * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), s(72)).round()
	if toast_lbl.modulate.a > 0.0:
		# issue 1559 item 17: no wider than the band between the two corner clusters (a long reinforcement list wraps
		# instead of running off the edge or over the corner words)
		var room := clampf(col.y - col.x - s(40), float(s(200)), float(s(720)))
		var natural := font_semi.get_string_size(toast_lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s(19)).x + s(4)
		var w := minf(natural, room)
		toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if natural > room else TextServer.AUTOWRAP_OFF
		toast_lbl.custom_minimum_size.x = w if natural > room else 0.0
		toast_lbl.reset_size()
		w = toast_lbl.size.x
		var p := Vector2(clampf((col.x + col.y) * 0.5 - w * 0.5, col.x, maxf(col.x, col.y - w)), s(96))
		# issue 1559 item 11: below the big banner when both show (REINFORCEMENTS and its sentence fire together)
		if banner_lbl.modulate.a > 0.0 and banner_lbl.text != "" and Rect2(p, toast_lbl.size).intersects(banner_lbl.get_global_rect()):
			p.y = banner_lbl.get_global_rect().end.y + s(8)
		if tipcard != null and is_instance_valid(tipcard) and tipcard.visible and Rect2(p, toast_lbl.size).intersects(tipcard.get_global_rect()):
			p.x = maxf(col.x, tipcard.get_global_rect().position.x - w - s(16))
		toast_lbl.position = p.round()
	# the menu and the end card: centred in the clear part
	for m in [menu, endcard]:
		if m != null and is_instance_valid(m):
			(m as Control).position.x = roundf(clampf((col.x + col.y) * 0.5 - (m as Control).size.x * 0.5, col.x, maxf(col.x, col.y - (m as Control).size.x)))
	if tip.visible:
		_place_tip()


func over_ui(p: Vector2) -> bool:
	if is_instance_valid(menu) or is_instance_valid(endcard):
		return true
	if ledger != null and ledger.is_visible_in_tree() and ledger.modulate.a > 0.5 and ledger._has_point(p):
		return true
	for c in [log_panel, tipcard, legend]:
		if c != null and is_instance_valid(c) and c.is_visible_in_tree() and c.modulate.a > 0.5 and c.get_global_rect().has_point(p):
			return true
	return false


# ---------------------------------------------------------------- the turn strip (the enemy's turn)



# kind: "player", "enemy" or "" (hidden); bb: the strip's text; progress 0..1 (enemy turn only, negative hides the bar)
func set_phase(kind: String, bb: String, progress := -1.0) -> void:
	_last["set_phase"] = [kind, bb, progress]
	_phase_kind = kind
	ledger.phase = {"kind": kind, "text": bb, "p": progress}
	ledger.mark()
