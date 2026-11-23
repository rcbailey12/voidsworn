extends CanvasLayer
# The campaign screens (G3): draws the campaign's current page and modal (godot/campaign/campaign.gd) the way today's game
# lays them out (campaign_run.js, campaign_meta.js, head.html): the same wording, the same buttons in the same order.
# Every button calls campaign.act(name, arg); the UI never changes campaign state itself.
# PC only: mouse, plus keys: Esc closes a dialog that has a close button, 1 to 9 pick a dialog's choices in order,
# Tab and the arrow keys move between buttons and map nodes, Enter or Space presses the focused one.
# Colours and fonts match the battle HUD (godot/ui/battle/hud.gd). Sizes scale with the window height (designed at 1080).

const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
var teaching: Node
const Map3D = preload("res://ui/campaign/map3d.gd")
const ChoiceScript = preload("res://ui/campaign/choice_button.gd")
const Crest = preload("res://ui/campaign/crest.gd")
const UiScale = preload("res://ui/ui_scale.gd")
const ModalFocus = preload("res://ui/theme/modal_focus.gd")   # issue 1559

const GS = preload("res://ui/theme/glass_shell.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")   # issue 1217: the shared front-end kit (wrap-safe labels, sound)
const View = preload("res://campaign/campaign_view.gd")   # read-only views of the run for the screens (audit pass 1, finding 12)
# The colours come from glass_shell.gd. Keep the existing campaign text roles and use the orders-sheet strengths.
const INK := GS.INK
const IRON := GS.IRON
const IRON2 := GS.IRON2
const IRON3 := GS.IRON3
const BONE := GS.TEXT
const BONE2 := GS.TEXT2
const BONE3 := GS.TEXT3
const VERD := GS.VERD
const BLOOD := GS.BLOOD
const EMBER := GS.EMBER
const ALERT := GS.NEM
const HULL := GS.HULL
const HULL_LOW := GS.HULL_LOW
const FRIEND := GS.FRIEND
const GLASS := GS.SHELL
const BLUE := GS.BLUE            # B4 blue event options (ui_spec.md 5.1 BLUE)
# The approved words (lore round 8, R59; rename_map_final.md): core, signal, protocol, sync, and salvage for the relic
# item type (Opus's veto of V14). The map screen's own strings read these. Ids never change.
const TERMS := {"patron": "core", "patrons": "cores", "sigil": "signal", "boon": "protocol", "boons": "protocols", "favour": "sync", "relic": "salvage", "relics": "salvage"}
static func term(k: String, cap: bool = false) -> String:
	var t: String = TERMS.get(k, k)
	return (t.substr(0, 1).to_upper() + t.substr(1)) if cap else t

var C                      # the campaign (campaign.gd)
var k := 1.0
var font: Font
var font_semi: Font
var font_goth: Font                   # the display face for page and dialog titles: Chakra Petch Bold caps, tracked (GS.display)
var font_caps: Font                    # section heads and tags: Chakra Petch Bold caps, tracked (GS.caps)
var font_act: Font                     # the finishing action's label (GS.action_font)
var font_num: Font                     # numbers that decide something: Azeret Mono (GS.num)
var font_num_b: Font
var root: Control
var bg: ColorRect
var page_box: Control
var map3d: Control                    # the 3D sector map, kept alive between renders (it animates)
var use_3d_map := true                # always true: the flat map (map_view.gd) is retired (R51 audit); kept for the shot harness
var ai_level := "standard"             # the battle setting the shell uses (godot/main settings "ai"); the map's danger bands follow it
var map_quality := "high"             # the 3D map's detail, "high" or "low" (R51): from the game's Graphics setting, then the map's own toggle
var modal_box: Control
var toast_box: VBoxContainer
var theme_main: Theme
var extra_title_buttons: Array = []   # [label, Callable] added under the title menu by the game shell (skirmish, settings ...)
var hide_on_battle := false           # the game shell shows its own battle scene on the battle page
var _acts: Array = []                 # the buttons the current screen allows
var _modal_acts: Array = []
var _modal_scroll: ScrollContainer
var _modal_kind := ""
var _dirty := false
var _yard_bar: Button = null     # the shipyard's repair bar of the last render (the teaching card keeps off it)
var _fs_name := ""

func _ready() -> void:
	layer = 20
	font = GS.body(); font_semi = GS.semi(); font_num = GS.num(); font_num_b = GS.num_bold()   # Lime Tactical faces (ui_style.md 4)
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(root)
	bg = ColorRect.new(); bg.color = INK; bg.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(bg)
	map3d = Map3D.new(); map3d.ui = self; map3d.visible = false; root.add_child(map3d)
	page_box = Control.new(); page_box.set_anchors_preset(Control.PRESET_FULL_RECT); page_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(page_box)
	modal_box = Control.new(); modal_box.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(modal_box)
	toast_box = VBoxContainer.new(); toast_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH; toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; toast_box.alignment = BoxContainer.ALIGNMENT_END; root.add_child(toast_box)
	get_viewport().size_changed.connect(func(): _rescale(); _dirty = true)
	_rescale()
	map_quality = _load_map_quality()
	Kit.watch_sound(self)   # issue 1448: every button and choice on every campaign screen and dialog plays the ui cues

const MAP_PREFS := "user://campaign_map.json"
func _load_map_quality() -> String:   # the map's own toggle wins; otherwise the game's Graphics setting (Low -> low)
	for path in [MAP_PREFS, "user://settings.json"]:
		if not FileAccess.file_exists(path): continue
		var o = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (o is Dictionary): continue
		if path == MAP_PREFS and o.get("quality") in ["high", "low"]: return o["quality"]
		if path != MAP_PREFS and o.has("quality"): return "low" if str(o["quality"]) == "low" else "high"
	return "high"
func set_map_quality(qv: String) -> void:
	map_quality = qv
	var f = FileAccess.open(MAP_PREFS, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify({"quality": qv}))
	if map3d != null: map3d.set_quality(qv)
	_dirty = true
func _font(p: String) -> Font:
	if ResourceLoader.exists(p): return load(p)
	var f = FontFile.new()
	if FileAccess.file_exists(p): f.load_dynamic_font(p)
	return f

func bind(campaign) -> void:
	C = campaign
	teaching = CampaignTips.new(); add_child(teaching); teaching.bind(C)
	if "playtest_default" in C: C.playtest_default = true   # R1 (Ryan, Nov 1): the real game opens with everything unlocked for playtests; the player can switch it off
	C.changed.connect(func(): _dirty = true)
	_dirty = true

func _rescale() -> void:
	k = UiScale.k_for(get_viewport().get_visible_rect().size)   # the one shared law (ui_spec.md section 4); its ceiling was 2.5 here
	font_goth = GS.display(k); font_caps = GS.caps(k); font_act = GS.action_font(k)   # tracked faces follow k (ui_style.md 4)
	theme_main = _make_theme(); root.theme = theme_main

func px(v: float) -> int: return int(round(v * k))

func _process(delta: float) -> void:
	if C == null: return
	if C.RUN != null:
		if not is_same(_end_live_run, C.RUN): _end_live_run = C.RUN; _end_last_flagship = {}
		var fs = C.flagshipOf()
		if fs != null: _end_last_flagship = fs # Keep the real dictionary, which applyBattle updates before removing a lost hull.
	if _dirty:
		_dirty = false; render()
	if C.arc_source == null and _story() != null:   # story arcs: the campaign asks the story layer for the card (shown only while C.arcs_on)
		var st = _story(); C.arc_source = st.arc_beat; C.arc_chose_cb = st.arc_chose; C.arc_end_cb = st.arc_end
	if C.RUN != null and _story() != null:   # a rename in the story dialog changes the flagship's name without a campaign signal
		var fs = C.flagshipOf(); var nm = str(fs["name"]) if fs != null else ""
		if nm != _fs_name:
			_fs_name = nm; _dirty = true
	if C.toasts.size() > 0:
		for t in C.toasts: _toast(t)
		C.toasts.clear()

# ---------------- theme ----------------
# The existing campaign shapes and metrics take their colours from the orders sheet.
func _sb(bgc: Color, border: Color, bw: int = 1, rad: int = 0, pad: float = 8.0) -> StyleBoxFlat:   # a plain square box (rare: a few bars)
	var s = StyleBoxFlat.new(); s.bg_color = bgc; s.border_color = border
	s.set_border_width_all(bw); s.set_corner_radius_all(0)
	s.content_margin_left = px(pad * 1.4); s.content_margin_right = px(pad * 1.4); s.content_margin_top = px(pad); s.content_margin_bottom = px(pad)
	return s
# A backing with an accent bar on its left (the old "glass" panels): a solid well, its left bar in the accent colour.
# Kept by name for the map's hover card and the older pages; side, aw, rad and shadow are no longer used (square, flat).
func _glass(_bgc: Color, accent: Color, _side: String = "left", _aw: int = 3, _rad: int = 3, pad: float = 10.0, _shadow: float = 10.0) -> StyleBoxFlat:
	return GS.well(k, Color(0, 0, 0, 0), pad * 1.2, pad, accent)
func _make_theme() -> Theme:
	var t = GS.make_theme(k, font, font_semi, 17)   # campaign and menus keep base 17 (ui_spec.md 4.2; the default label was 18)
	t.set_font_size("font_size", "Button", px(17))
	for f in ["normal_font_size", "bold_font_size", "mono_font_size"]: t.set_font_size(f, "RichTextLabel", px(17))
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(state, "Button", BONE)
	t.set_color("font_disabled_color", "Button", BONE3)
	t.set_color("font_color", "Label", BONE)
	t.set_color("default_color", "RichTextLabel", BONE)
	t.set_color("font_color", "TooltipLabel", BONE)
	t.set_font_size("font_size", "TooltipLabel", px(17))
	t.set_stylebox("panel", "PanelContainer", GS.well(k))
	var sep = StyleBoxLine.new(); sep.color = GS.LINE; sep.thickness = max(1, px(1))
	t.set_stylebox("separator", "HSeparator", sep)
	return t

# ---------------- small builders ----------------
func hexs(c: Color) -> String: return "#" + c.to_html(false)
func esc(s) -> String: return str(s).replace("[", "[lb]")
func lbl(text: String, size: float = 17, col: Color = BONE, f: Font = null, wrap: bool = true) -> Label:
	var l = Label.new(); l.text = text; l.add_theme_font_size_override("font_size", px(size)); l.add_theme_color_override("font_color", col)
	if f != null: l.add_theme_font_override("font", f)
	# issue 1217: every label wraps inside its container (the kit's wrap_safe). A short label keeps its natural width; a
	# longer one starts at LBL_CAP and wraps to whatever room it is given, so a long admiral name no longer widens its card
	# (the old rule wrapped only past 30 characters).
	if wrap: Kit.wrap_safe(l, f if f != null else font, px(size), px(LBL_CAP))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
const LBL_CAP := 200.0
func num(text: String, size: float = 17, col: Color = BONE, bold: bool = true) -> Label:   # a number that decides something: Azeret Mono
	return lbl(text, size, col, font_num_b if bold else font_num, false)
func rich(bb: String, size: float = 17) -> RichTextLabel:
	var r = RichTextLabel.new(); r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false; r.text = bb
	r.add_theme_font_size_override("normal_font_size", px(size)); r.add_theme_font_size_override("bold_font_size", px(size)); r.add_theme_font_size_override("mono_font_size", px(size))
	r.mouse_filter = Control.MOUSE_FILTER_PASS; r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r
func rich_inline(bb: String, size: float = 17) -> RichTextLabel:   # one line, as wide as its text (for flow rows)
	var r = rich(bb, size); r.autowrap_mode = TextServer.AUTOWRAP_OFF; r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
func c(text: String, col: Color) -> String: return "[color=" + hexs(col) + "]" + text + "[/color]"
func n_(text: String, col: Color = BONE) -> String: return "[code]" + c(text, col) + "[/code]"   # a number in rich text: the number face
# a page or dialog title: Chakra Petch Bold caps, tracked (GS.display); the size argument keeps the old scale (x 0.7)
func gothic(text: String, size: float = 52) -> Label: return lbl(text.to_upper(), size * 0.7, BONE, font_goth, true)
func _readout(label: String, value: String, col: Color, right: bool = false) -> Control:   # a big number: Azeret Mono, its label in caps
	var v = vbox(0); var a = caps(label, 17, BONE3); var b = num(value, 28, col)   # label 17: the text floor (RULEBOOK 9.4)
	if right: a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(a); v.add_child(b); return v

func vbox(sep: float = 8) -> VBoxContainer:
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", px(sep)); return v
func hbox(sep: float = 10) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", px(sep)); return h
func spacer() -> Control:
	var s = Control.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; return s
func flow(sep: float = 14) -> HFlowContainer:
	var f = HFlowContainer.new(); f.add_theme_constant_override("h_separation", px(sep)); f.add_theme_constant_override("v_separation", px(sep)); return f
# A block of text on a solid well (ui_style.md 3). The border colour, when it is not the quiet IRON3, becomes the well's left
# bar (for example a core's colour). A box filled with its own border colour is a tag.
func panel(border: Color = IRON3, bgc: Color = IRON, pad: float = 14) -> PanelContainer:
	var p = PanelContainer.new()
	var sb: StyleBoxFlat
	if bgc.a > 0.9 and bgc == border: sb = GS.tag(k, border, true); sb.content_margin_left = px(pad); sb.content_margin_right = px(pad)
	elif border == IRON3 or border.a == 0.0: sb = GS.well(k, Color(0, 0, 0, 0), pad, pad * 0.7)
	elif border == BONE3: sb = GS.well(k, BONE3, pad, pad * 0.7)
	else: sb = GS.well(k, Color(0, 0, 0, 0), pad, pad * 0.7, border)
	p.add_theme_stylebox_override("panel", sb); return p
# A card: a well with a neutral outline when selected or owned.
func card(sel: bool = false, width: float = 300) -> Array: # [PanelContainer, VBoxContainer]
	var p = PanelContainer.new(); p.custom_minimum_size.x = px(width)
	p.add_theme_stylebox_override("panel", GS.well(k, BONE3 if sel else Color.TRANSPARENT, 14, 12))
	var v = vbox(6); p.add_child(v); return [p, v]
# One panel per region (ui_style.md 2): the matte slab with its chamfers, scanline, bevel and brackets.
func shell_panel(pad: float = 14) -> PanelContainer:
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", GS.shell(k, pad)); GS.frame_marks(p, k); return p
# A section head inside a panel: neutral tracked caps (GS.caps).
func sec_head(t: String, right: String = "", right_col: Color = BONE3) -> Control:
	var h = hbox(8); h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(lbl(t.to_upper(), 17, BONE, font_caps, false))
	if right != "": h.add_child(spacer()); h.add_child(lbl(right, 17, right_col, font_caps, false))
	return h
# A small square tag (UP, NEMESIS, ELITE, LOCKED): filled for a state, outlined for a side or a kind
func tagl(t: String, col: Color, filled: bool = false, size: float = 17) -> Label:
	var l = lbl(t.to_upper(), size, INK if filled else col, font_caps, false)
	l.add_theme_stylebox_override("normal", GS.tag(k, col, filled)); l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l
# A key cap beside an action ("1", "Esc"): the key always shows next to what it does
func keycap(key: String, on_ember: bool = false) -> Label:
	var l = lbl(key, 17, GS.ON_EMBER if on_ember else BONE2, font_num_b, false)
	l.add_theme_stylebox_override("normal", GS.keycap_on_ember(k) if on_ember else GS.keycap(k))
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l
func bar(f: float, w: float = 0) -> Control:   # a hull bar: segmented, HULL_LOW under the one hull-low line (HD9)
	var b = GS.seg_bar(k, f, HULL_LOW if f < 0.35 else HULL, GS.BAR_TRACK, 6, 10)
	b.custom_minimum_size.x = px(w); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b
# A button for one of the screen's allowed actions; returns null when the screen does not offer it.
func _find(list: Array, act: String, arg) -> Array:
	var a = "" if arg == null else str(arg)
	for x in list:
		if x[0] == act and x[1] == a: return x
	return []
func _arg_of(list: Array, act: String) -> String:   # the arg of the first button with this action ("" when none)
	for x in list:
		if x[0] == act: return x[1]
	return ""
# The number key that picks this action in a dialog (1 to 9 pick the dialog's enabled actions in order, _unhandled_input)
func _key_for(list, act: String, arg) -> String:
	if list == null or C.modal_d == null or list != C.modal_d["acts"]: return ""
	var on = list.filter(func(a): return a[2] == 1)
	var a0 = "" if arg == null else str(arg)
	for i in range(min(9, on.size())):
		if on[i][0] == act and on[i][1] == a0: return str(i + 1)
	return ""
# A highlighted button either confirms an action (ember) or shows the current selection (bone).
func abtn(text: String, act: String, arg = "", primary: bool = false, small: bool = false, list = null) -> Button:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = Button.new(); b.text = "Back to ledger" if _end_return and act == "title" else text; b.disabled = found[2] == 0; b.focus_mode = Control.FOCUS_ALL
	if small: b.add_theme_font_size_override("font_size", px(17))
	if primary:
		var accent = BONE2 if act in ["pickFaction", "pickAdmiral", "progTab"] else GS.MAP_EMBER
		var lb = GS.lit_boxes(k, accent)
		for st in ["normal", "hover", "pressed", "disabled"]: b.add_theme_stylebox_override(st, lb[st])
		for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]: b.add_theme_color_override(fc, accent)
	# issue 1559 item 7: in a dialog its number key shows after the label, as on the choices and the finishing action (a
	# boon's 4 and 5 ran Reroll and Decline with no cap shown, and Decline cannot be taken back)
	var kk = _key_for(list, act, arg)
	if kk != "":
		var cap = keycap(kk); cap.mouse_filter = Control.MOUSE_FILTER_IGNORE; cap.name = "keycap"
		cap.anchor_left = 1.0; cap.anchor_right = 1.0; cap.anchor_top = 0.5; cap.anchor_bottom = 0.5
		cap.offset_left = -px(10); cap.offset_right = -px(10); cap.offset_top = 0; cap.offset_bottom = 0
		cap.grow_horizontal = Control.GROW_DIRECTION_BEGIN; cap.grow_vertical = Control.GROW_DIRECTION_BOTH
		b.add_child(cap)
		var tw = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, b.get_theme_font_size("font_size")).x
		var cw = font_num_b.get_string_size(kk, HORIZONTAL_ALIGNMENT_LEFT, -1, px(17)).x + px(20)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.x = maxf(b.custom_minimum_size.x, ceil(tw) + cw + px(44))
	var aa = found[1]
	press_tag(b, act, aa)
	b.pressed.connect(func(): _campaign_action(act, aa))
	Kit.wire_sound(b, cue_role(act, "primary" if primary and not act in ["pickFaction", "pickAdmiral", "progTab"] else "quiet"))
	return b
# The screen's finishing action (Continue, Confirm, Plot a course, Done, Leave shipyard): the filled ember button, its label
# in action caps, its key cap after the label in a dialog (ui_style.md 7). It sits at the bottom right of its screen or dialog.
func fin(text: String, act: String, arg = "", list = null) -> Button:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = Button.new(); b.disabled = found[2] == 0; b.focus_mode = Control.FOCUS_ALL; b.set_meta("finish", true)
	var fb = GS.finish_boxes(k)
	for st in ["normal", "hover", "pressed", "disabled"]: b.add_theme_stylebox_override(st, fb[st])
	var h = hbox(10); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.mouse_filter = Control.MOUSE_FILTER_IGNORE; h.set_anchors_preset(Control.PRESET_FULL_RECT)
	var l = lbl(text.to_upper(), 17, BONE3 if b.disabled else GS.ON_EMBER, font_act, false); l.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(l)
	var kk = _key_for(list, act, arg)
	if kk != "": h.add_child(keycap(kk, not b.disabled))
	b.add_child(h)
	# the width from the faces' own metrics (a container's minimum size is not known before it is drawn; hud.gd _kb_width)
	var tw = font_act.get_string_size(text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, px(17)).x
	if kk != "": tw += font_num_b.get_string_size(kk, HORIZONTAL_ALIGNMENT_LEFT, -1, px(13)).x + px(10) + px(10) + px(10)
	b.custom_minimum_size = Vector2(ceil(tw) + px(24) + px(28), px(46))
	GS.finish_sheen(b, k)
	var aa = found[1]
	press_tag(b, act, aa)
	b.pressed.connect(func(): _campaign_action(act, aa))
	Kit.wire_sound(b, cue_role(act, "primary"))
	return b
# A footer row: the other buttons on the left of the finishing action, the finishing action last, at the right edge.
func foot(buttons: Array) -> HBoxContainer:
	var r = hbox(10); r.add_child(spacer())
	for b in buttons:
		if b != null: b.size_flags_vertical = Control.SIZE_SHRINK_END; r.add_child(b)
	return r
# A choice (the browser's .choice): a bold line and a small line under it on a well. The selected one is lit; an accent
# (a core's colour, BLUE for a requirement you meet) is the well's left bar; in a dialog its number key shows on the right.
# Disabled (MN12): the words dim and a LOCKED tag says so; the backing keeps its alpha (ui_style.md 3), no 50% fade.
func choice(title: String, small: String, act: String, arg = "", list = null, accent = null, tag_t: String = "", tagcol: Color = BONE2, sel: bool = false) -> Control:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var off = found[2] == 0
	var b = ChoiceScript.new(); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bar_c = accent if accent != null else Color(0, 0, 0, 0)
	if off: bar_c = GS.LINE
	var n = GS.well(k, BONE2 if sel and not off else Color.TRANSPARENT, 12, 9, bar_c)
	var h = GS.well(k, BONE2 if sel else BONE3, 12, 9, bar_c)
	b.setup(n, h, h, off)
	b.ring = GS.focus_ring(k)
	var row = hbox(10); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v = vbox(2); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if tag_t != "": v.add_child(lbl(tag_t.to_upper(), 17, BONE3 if off else tagcol, font_caps))
	v.add_child(lbl(title, 18, BONE3 if off else BONE, font_semi))
	if small != "": v.add_child(lbl(small, 17, BONE3 if off else BONE2))
	for l in v.get_children():
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	if off: row.add_child(tagl("Locked", BONE3))
	else:
		var kk = _key_for(list, act, arg)
		if kk != "": row.add_child(keycap(kk))
	b.add_child(row)
	var aa = found[1]
	b.set_meta("act", act); b.set_meta("arg", aa)   # its key for keeping focus across a re-render (_focus_key)
	press_tag(b, act, aa)
	b.pressed.connect(func(): _campaign_action(act, aa))
	Kit.wire_sound(b, cue_role(act, "quiet"))
	return b
func add(parent: Node, child) -> void:
	if child != null: parent.add_child(child)
func _boon_fleet_line(id: String, rarity: int) -> String:
	var relevance: Dictionary = C.boonFleetRelevance(id, rarity)
	if relevance.get("brace_blocked", false): return "No effect on this fleet: none of its ships can Brace."
	var kit: String = {
		"lance": "with lances", "torp": "with torpedoes", "broad": "with flank guns",
		"still": "with flank guns or batteries", "shields": "with shields",
		"brace": "that can Brace",
		"carrier": "with hangars", "sq": "with squadrons",
	}.get(relevance.get("need"), "")
	if kit == "": return ""
	var ships: PackedStringArray = relevance["ships"]
	var count := ships.size()
	if count > 0:
		var condition := " that have not moved" if relevance["need"] == "still" else ""
		if count == 1 and condition != "": condition = " that has not moved"
		var names := ", ".join(ships.slice(0, 3))
		if count > 3: names += " and %d more" % (count - 3)
		return "Affects %d %s %s%s: %s" % [count, "ship" if count == 1 else "ships", kit, condition, names]
	if relevance["capped"]: return "No added benefit: ships %s are already at the limit." % kit
	if relevance.has("refit"):
		return "No ship %s now; could use later with the %s refit in your hold." % [kit, C.modName(relevance["refit"])]
	if relevance.has("hull"): return "No ship %s now; could use later on a fitting hull." % kit
	return "No current ship %s." % kit

func _toast(msg: String) -> void:   # a strip with a calm VERD bar (ui_style.md 3): toasts here are news, not warnings
	var p = PanelContainer.new(); var sb = GS.strip(k, VERD); sb.content_margin_left = px(14); sb.content_margin_right = px(18); sb.content_margin_top = px(8); sb.content_margin_bottom = px(8)
	p.add_theme_stylebox_override("panel", sb); p.add_child(lbl(msg, 18, BONE)); p.custom_minimum_size.x = px(min(900, 260 + msg.length() * 7))
	toast_box.add_child(p)
	while toast_box.get_child_count() > 3: var o = toast_box.get_child(0); toast_box.remove_child(o); o.queue_free()
	var tw = create_tween(); tw.tween_interval(clamp(msg.length() * 0.06, 2.2, 9.0)); tw.tween_property(p, "modulate:a", 0.0, 0.4); tw.tween_callback(p.queue_free)
# ---------------- render ----------------
func render() -> void:
	_route_click_id = ""
	_refocus_key = _focus_key(get_viewport().gui_get_focus_owner()) if desk_opts_open else ""
	for ch in page_box.get_children(): ch.queue_free()
	for ch in modal_box.get_children(): ch.queue_free()
	var pg = C.page; _acts = pg["acts"]
	if pg["kind"] != "admiral": desk_opts_open = false; _drawer_shown = false; _focus_opener = false
	if pg["kind"] != "aspect": aspect_pick = ""; podium = null
	var battle = pg["kind"] == "battle"
	root.visible = not (battle and hide_on_battle and (C.modal_d == null or C.modal_d["kind"] == "retreat"))   # rewards after a fight show over the battle scene
	bg.color = INK
	var on_map = pg["kind"] == "map" and use_3d_map and C.RUN != null
	if pg["kind"] != "map" or C.modal_d != null: _overlay = ""   # a slide-over belongs to the open map
	# in a run, the fleet, shipyard and battle pages sit over the star system, dimmed (R51 panels pass)
	var behind = (not on_map) and use_3d_map and C.RUN != null and C.RUN.get("map") != null and pg["kind"] in ["fleet", "shipyard", "battle"]
	map3d.visible = on_map or behind; bg.visible = not on_map
	if behind: bg.color = Color(INK, 0.86)
	if map3d.visible: map3d.backdrop = behind; map3d.sync()
	var body: Control = null
	match pg["kind"]:
		"title": body = _title()
		"admiral": body = _desk()
		"aspect": body = _podium()
		"map": body = _map()
		"fleet": body = _fleet(pg["data"])
		"shipyard": body = _wrap_page(_shipyard())
		"battle":   # the test battle's panel; a dialog over the battle (the rewards) shows over the scene alone, as in the game shell
			body = _battle_stub(pg["data"]) if (C.modal_d == null or C.modal_d["kind"] == "retreat") else Control.new()
		"legacy": body = _kit_page(_legacy(), 1440, [kbtn("Back", "title", "", "back")])
		"lineage": body = _kit_page(_lineage(pg["data"]["id"]), 1440, [kbtn("Back", "progTab", "mastery", "back"), kbtn("Reset line: " + C.numstr(C.lineageRespecCost(pg["data"]["id"])) + " renown", "offerRespec", pg["data"]["id"], "quiet")])
		"help": body = _kit_page(_help(), 1120, [kbtn("Back", "title", "", "back")])
		"end": body = _end(pg["data"])
		_: body = lbl("")
	page_box.add_child(body)
	_page_finish(str(pg["kind"]))
	if C.modal_d != null: _modal(C.modal_d)
	_teaching_screen()
	call_deferred("_focus_first")
func _teaching_screen() -> void:
	var kind := str(C.page.get("kind", ""))
	var modal := str(C.modal_d.get("kind", "")) if C.modal_d != null else ""
	var sector := str(C.RUN.get("sector", 0)) if C.RUN != null else "0"
	var pos := str(C.RUN.get("pos", "")) if C.RUN != null else ""
	var ids: Array = []
	if modal == "victory": ids = ["c_reward"]
	elif modal == "":
		match kind:
			"map": ids = ["c_map", "c_clock"]
			"shipyard": ids = ["c_shipyard"]
			"end": ids = [] # First-loss teaching is on The record R, beside the receipt.
	# the first-visit card stays off the Map key and the Dossier (it waits while one is open) and off the shipyard's repair bar
	var clear: Array = []
	if kind == "shipyard" and modal == "" and _yard_bar != null and is_instance_valid(_yard_bar): clear.append(_yard_bar)
	teaching.set_context(_overlay != "", clear)
	teaching.open_screen(kind + "|" + sector + "|" + pos + "|" + modal, ids)

func _focus_first() -> void:
	if _live_count(modal_box) > 0 or _overlay != "": return   # ModalFocus owns the keyboard while a dialog or drawer is open.
	if C.modal_d == null and C.page.get("kind") == "fleet":
		get_viewport().gui_release_focus()
		return
	# The chart takes the keys again when the dialog or drawer closes (issue 1559 item 6).
	if C.page.get("kind") == "map" and use_3d_map and map3d != null and map3d.visible:
		map3d.grab_focus()
		return
	# issue 1261: the Run options drawer holds keyboard and controller focus while it is open (the control that was
	# focused before a re-render keeps it), and closing it gives focus back to Run options
	if C.page.get("kind") == "admiral":
		var dr = _live_child("RunOptionsDrawer")
		if dr != null and desk_opts_open:
			_trap_focus(page_box, dr)
			var keep = _find_focus_key(dr, _refocus_key) if _refocus_key != "" else null
			var fb = keep if keep != null else _first_button(dr)
			if fb != null: fb.grab_focus()
			return
		if _focus_opener:
			_focus_opener = false
			var ro = _live_child("RunOptionsButton")
			if ro != null: ro.grab_focus(); return
	if C.page.get("kind") == "end":
		var exit = _end_primary(page_box)
		if exit != null:
			exit.grab_focus()
			var sc = exit.get_parent()
			while sc != null and not sc is ScrollContainer: sc = sc.get_parent()
			if sc is ScrollContainer: sc.set_deferred("scroll_vertical", 0)
			return
	var b = _first_button(page_box)
	if b != null: b.grab_focus()
# a node of the current page by name: the last render's nodes are still in page_box until the frame ends (queue_free)
func _live_child(nm: String) -> Control:
	for ch in page_box.get_children():
		if ch.is_queued_for_deletion(): continue
		var f = ch if str(ch.name) == nm else ch.find_child(nm, true, false)
		if f != null: return f
	return null
var _refocus_key := ""      # the focused control's key before the last render, while the Run options drawer is open
var _focus_opener := false  # set when the drawer closes: focus goes back to Run options
func _focus_key(n) -> String:
	if not (n is Control) or not is_instance_valid(n): return ""
	if n.has_meta("act"): return "act:" + str(n.get_meta("act")) + "|" + str(n.get_meta("arg", ""))
	return "name:" + str(n.name)
func _find_focus_key(n: Node, key: String) -> Control:
	for ch in n.get_children():
		if ch is Control and ch.focus_mode != Control.FOCUS_NONE and _focus_key(ch) == key and ch.is_visible_in_tree(): return ch
		var r = _find_focus_key(ch, key)
		if r != null: return r
	return null
# every focusable control under root but outside keep stops taking focus, so Tab, the arrows and a controller stay in keep
# (the page is rebuilt when keep closes, which brings the focus modes back)
func _trap_focus(root_n: Node, keep: Node) -> void:
	for ch in root_n.get_children():
		if ch == keep: continue
		if ch is Control and ch.focus_mode != Control.FOCUS_NONE: ch.focus_mode = Control.FOCUS_NONE
		_trap_focus(ch, keep)
func _end_primary(n: Node) -> Button:
	if n.is_queued_for_deletion(): return null   # issue 1559 item 6
	if n is Button and n.get_meta("end_primary", false): return n
	for ch in n.get_children():
		var found = _end_primary(ch)
		if found != null: return found
	return null
func _live_count(n: Node) -> int:
	var c := 0
	for ch in n.get_children():
		if not ch.is_queued_for_deletion(): c += 1
	return c
func _first_button(n: Node) -> Control:
	for ch in n.get_children():
		if ch.is_queued_for_deletion(): continue   # issue 1559 item 6: the last render's buttons are on their way out
		if (ch is Button or ch.get_script() == ChoiceScript) and not ch.disabled and ch.visible: return ch
		var r = _first_button(ch)
		if r != null: return r
	return null
# ---------------- the start pages on the orders kit (issue 1217 phase 5): Progression, Lineage, How to play ----------------
# The desk's frame: the ledger veil, one centred column that scrolls, and a fixed bar below it that never moves (Back on the
# left, the page's other quiet actions beside it). Card rows become kit grids (Kit.card_grid): one width, one height per
# row, actions pinned to the card's foot.
var _kit_scroll: ScrollContainer = null
func _kit_page(inner: Control, maxw: float, left_btns: Array) -> Control:
	var vs = get_viewport().get_visible_rect().size
	var host = Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.theme = Kit.theme(k)
	var veil = TextureRect.new(); veil.texture = GS.ledger_veil(); veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; veil.stretch_mode = TextureRect.STRETCH_SCALE; veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(veil)
	var cw = minf(vs.x - px(DESK_PAD) * 2, float(px(maxw)))
	var left = (vs.x - cw) * 0.5
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.anchor_right = 1.0; sc.anchor_bottom = 1.0; sc.offset_top = px(28); sc.offset_bottom = -px(96)
	host.add_child(sc); _kit_scroll = sc
	var row = HBoxContainer.new(); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(row)
	var lm = Control.new(); lm.custom_minimum_size.x = left; row.add_child(lm)
	inner.custom_minimum_size.x = cw; row.add_child(inner)
	_regrid(inner, cw)
	var bar = Kit.action_bar(k, left_btns)
	bar.anchor_top = 1.0; bar.anchor_bottom = 1.0; bar.anchor_right = 1.0
	bar.offset_left = left; bar.offset_right = -left; bar.offset_top = -px(80); bar.offset_bottom = -px(24)
	host.add_child(bar)
	return host
# Turns the page's card flows into kit grids. A flow of cards becomes a Kit.card_grid; a flow of columns (Lineage's trunk
# and branches) becomes equal columns whose cards take the column's width. width is the room the node has.
func _regrid(node: Node, width: float) -> void:
	for ch in node.get_children():
		if ch is HFlowContainer and ch.get_child_count() > 0:
			var kids = ch.get_children()
			var idx = ch.get_index(); var parent = ch.get_parent()
			if kids.all(func(x): return x is PanelContainer):
				for x in kids:
					ch.remove_child(x); _pin_foot(x)
				var g = Kit.card_grid(kids, width, k)
				parent.remove_child(ch); ch.queue_free(); parent.add_child(g); parent.move_child(g, idx)
				continue
			if kids.all(func(x): return x is VBoxContainer):
				var gp = float(px(16)); var n = kids.size()
				var cols = n if (width - gp * (n - 1)) / float(n) >= px(240) else maxi(1, int(floor((width + gp) / (px(300) + gp))))
				var g2 = GridContainer.new(); g2.columns = cols
				g2.add_theme_constant_override("h_separation", int(gp)); g2.add_theme_constant_override("v_separation", int(gp))
				var cw2 = floorf((width - gp * (cols - 1)) / float(cols))
				for x in kids:
					ch.remove_child(x); (x as Control).custom_minimum_size.x = cw2; g2.add_child(x)
					for c2 in x.get_children():
						if c2 is PanelContainer:
							(c2 as Control).custom_minimum_size.x = cw2; _pin_foot(c2)
						elif c2 is Label: (c2 as Label).custom_minimum_size.x = minf((c2 as Label).custom_minimum_size.x, cw2)
				parent.remove_child(ch); ch.queue_free(); parent.add_child(g2); parent.move_child(g2, idx)
				continue
		if ch is PanelContainer: _regrid(ch, width - px(36))
		elif ch is Container: _regrid(ch, width)
# A card's last action sits at its foot, so a row of cards lines its buttons up.
func _pin_foot(cardp: Node) -> void:
	if cardp.get_child_count() == 0: return
	var body = cardp.get_child(0)
	if not (body is VBoxContainer) or body.get_child_count() < 2: return
	var last = body.get_child(body.get_child_count() - 1)
	if last is Button or last is HBoxContainer:
		var gap = Control.new(); gap.size_flags_vertical = Control.SIZE_EXPAND_FILL; gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.add_child(gap); body.move_child(gap, body.get_child_count() - 2)
		body.size_flags_vertical = Control.SIZE_EXPAND_FILL
func _wrap_page(inner: Control, maxw: float = 1440) -> Control:
	var sc = ScrollContainer.new(); sc.set_anchors_preset(Control.PRESET_FULL_RECT); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hb = HBoxContainer.new(); hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_top", px(12)); m.add_theme_constant_override("margin_bottom", px(96))   # room under the page for the fixed finishing action
	inner.custom_minimum_size.x = min(px(maxw), int(get_viewport().get_visible_rect().size.x) - px(80))
	var sh = shell_panel(18); sh.add_child(inner)   # one matte panel per page (ui_style.md 2): the page's wells sit on it
	m.add_child(sh); hb.add_child(spacer()); hb.add_child(m); hb.add_child(spacer()); sc.add_child(hb)
	return sc
# The page's finishing action, fixed in the bottom right corner of the screen where it never moves (ui_style.md 7):
# Done on the fleet screen, Leave shipyard in the shipyard.
func _page_finish(kind: String) -> void:
	var b: Button = null
	match kind:
		"shipyard": b = fin("Leave shipyard", "leaveYard")
	if b == null: return
	b.anchor_left = 1.0; b.anchor_top = 1.0; b.anchor_right = 1.0; b.anchor_bottom = 1.0
	b.grow_horizontal = Control.GROW_DIRECTION_BEGIN; b.grow_vertical = Control.GROW_DIRECTION_BEGIN
	b.offset_right = -px(24); b.offset_bottom = -px(24); b.offset_left = b.offset_right - b.custom_minimum_size.x; b.offset_top = b.offset_bottom - b.custom_minimum_size.y
	page_box.add_child(b)

# ---------------- title ----------------
func _title() -> Control:
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var v = vbox(10); v.custom_minimum_size.x = px(640); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var title_txt = "EMBERS OF THE HOLLOW SUN"   # the game's name from G2's brand.gd (one place for the title, R59)
	if ResourceLoader.exists("res://ui/battle/brand.gd"): title_txt = str(load("res://ui/battle/brand.gd").TITLE).to_upper()
	var h = lbl(title_txt, 96 if title_txt.length() <= 12 else 58, BONE, font_goth, false); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(h)
	var s = lbl("Command a fleet through three contested sectors to the Hollow Sun. Every hull you lose stays lost, and so does its captain.", 20, BONE2)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(s)
	var menu = vbox(10); menu.custom_minimum_size.x = px(260)
	var saved = C.SAVED_RUN != null
	add(menu, abtn("Continue run", "continueRun", "", true))
	add(menu, abtn("New run", "newRunScreen", "", not saved))
	add(menu, abtn("Progression" + (" ●" if float(C.z0(C.META.get("renown"))) >= 15 else ""), "legacy"))
	add(menu, abtn("How to play", "help"))
	for e in extra_title_buttons:
		var b = Button.new(); b.text = e[0]; b.pressed.connect(e[1]); menu.add_child(b)
	for b in menu.get_children():
		if b is Button: b.add_theme_font_size_override("font_size", px(18)); b.custom_minimum_size.y = px(46)
	var mc = CenterContainer.new(); mc.add_child(menu); v.add_child(mc)
	if C.has_method("playtestAll"):   # R1 (Ryan, Nov 1): the playtest switch, one plain line and a toggle (not a campaign act, so parity is untouched)
		var on = C.playtestAll()
		var pl = lbl("Playtest: everything unlocked (all admirals, carriers, battleships and hull variants). " + ("On." if on else "Off: unlock them with renown."), 18, BONE if on else BONE2)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(pl)
		var pb = Button.new(); pb.text = "Switch playtest unlocks " + ("off" if on else "on"); pb.focus_mode = Control.FOCUS_ALL
		pb.add_theme_font_size_override("font_size", px(17))
		pb.pressed.connect(func(): C.set_playtest_all(not C.playtestAll()); C.titleScreen())
		var pc = CenterContainer.new(); pc.add_child(pb); v.add_child(pc)
	var st = C.META["stats"]; var best = float(C.z0(st.get("best"))); var wins = int(C.z0(st.get("wins")))
	if best > 0:
		var t = "Best: sector " + C.roman(min(3, best)) + ((" · " + str(wins) + " full victor" + ("ies" if wins > 1 else "y")) if wins > 0 else "")
		var r = lbl(t, 17, BONE2); r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(r)
	cc.add_child(v); return cc

# ---------------- admiral and run options ----------------
# ---------------- the command desk (issue 1217 phase 3): faction and admiral on one screen ----------------
# Built from the orders kit (godot/ui/theme/orders_kit.gd). Top: the six faction crests in one strip (the picked one carries
# its faction accent, from fx/faction_looks.json, as an underline) and its music plays. Then the faction in two columns:
# who they are (blurb) and the battle rule. Then the faction's four admirals as four cards of one height (painted portrait,
# doctrine, bonus, mastery, Command, the starting fleet as silhouettes, Lineage and Select at the bottom of every card).
# The bottom bar is fixed: Back, Run options (a drawer from the right), and the one ember action, Launch.
# Moved to a hover (R177, listed in the pull request): the starting fleet's hull names (on the silhouettes), the
# heir or shadow XP line (on the mastery bar) and "Gets stronger each round you hold it" (on Command, as before).
const DESK_PAD := 56.0
const DESK_GAP := 16.0
var desk_opts_open := false         # the Run options drawer stays open across re-renders until closed
var _desk_cards: Array = []         # the admiral cards of the last render (front_end_test checks their bottoms)
var _preview_fac := ""
var _desk_compact := false          # under 960 design pixels of height (Larger at 16:9): smaller portraits, Command text on hover
func kbtn(text: String, act: String, arg = "", role: String = "quiet", size: float = 18) -> Button:   # a kit button for an allowed action
	var found = _find(_acts, act, arg)
	if found.is_empty(): return null
	var b = Kit.link(text, k, Callable(), size) if role == "link" else Kit.button(text, k, role, Callable(), size)
	b.disabled = found[2] == 0
	var aa = found[1]
	press_tag(b, act, aa)
	b.pressed.connect(func(): _campaign_action(act, aa))
	Kit.wire_sound(b, cue_role(act, role))
	return b
func _music():
	var m = get_node_or_null("/root/Main")
	return m.music if m != null and "music" in m and m.music != null else null
func _desk() -> Control:
	var vs = get_viewport().get_visible_rect().size
	var fac = str(C.picked_faction); var accent = Kit.faction_accent(fac)
	if _preview_fac != fac:
		_preview_fac = fac
		var mu = _music()
		if mu != null and mu.has_method("play_faction_preview"): mu.play_faction_preview(fac)
	var host = Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.theme = Kit.theme(k)
	var veil = TextureRect.new(); veil.texture = GS.ledger_veil(); veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; veil.stretch_mode = TextureRect.STRETCH_SCALE; veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(veil)
	_desk_compact = vs.y / k < 960.0
	var cw = minf(vs.x - px(DESK_PAD) * 2, float(px(1640)))
	var left = (vs.x - cw) * 0.5
	# the scrolling part (only scrolls when a window's shape leaves no room); the action bar below it never moves
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.anchor_right = 1.0; sc.anchor_bottom = 1.0; sc.offset_top = px(28); sc.offset_bottom = -px(96)
	host.add_child(sc)
	var row = HBoxContainer.new(); row.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(row)
	var lm = Control.new(); lm.custom_minimum_size.x = left; row.add_child(lm)
	var v = VBoxContainer.new(); v.custom_minimum_size.x = cw; v.add_theme_constant_override("separation", px(12 if _desk_compact else 18)); row.add_child(v)
	# the crest strip
	v.add_child(Kit.section("Faction", k))
	var strip = HBoxContainer.new(); strip.add_theme_constant_override("separation", px(6)); v.add_child(strip)
	var tab_w = (cw - px(6) * 5) / 6.0
	for f in C.RUN_FACTIONS:
		var b = _crest_tab(str(f), tab_w)
		if b != null: strip.add_child(b)
	# the faction: who they are, and the rule they fight by
	var fr = HBoxContainer.new(); fr.add_theme_constant_override("separation", px(40)); v.add_child(fr)
	var who = VBoxContainer.new(); who.add_theme_constant_override("separation", px(6)); who.size_flags_horizontal = Control.SIZE_EXPAND_FILL; who.size_flags_stretch_ratio = 1.3; fr.add_child(who)
	who.add_child(Kit.heading(str(C.FACTIONS[fac]["n"]), 40, k))
	var rule_bar = ColorRect.new(); rule_bar.color = accent; rule_bar.custom_minimum_size = Vector2(px(72), maxi(2, px(3))); rule_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; rule_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; who.add_child(rule_bar)
	var bl = Kit.label(str(C.FACTIONS[fac].get("blurb", "")), 18, k, GS.TEXT2); bl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; who.add_child(bl)
	var rules = VBoxContainer.new(); rules.add_theme_constant_override("separation", px(6)); rules.size_flags_horizontal = Control.SIZE_EXPAND_FILL; fr.add_child(rules)
	var FR = C.TB.FAC_RULES.get(fac, {})
	rules.add_child(Kit.section("Battle rule: " + str(FR.get("n", "")), k))
	var rl = Kit.label(str(FR.get("d", "")), 18, k, GS.TEXT2); rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; rules.add_child(rl)
	# the four admirals
	v.add_child(Kit.section("Admiral", k))
	var mine: Array = C.page["data"]["mine"]
	var cols = maxi(1, mini(4, mine.size()))
	var grid = GridContainer.new(); grid.columns = cols
	grid.add_theme_constant_override("h_separation", px(DESK_GAP)); grid.add_theme_constant_override("v_separation", px(DESK_GAP))
	v.add_child(grid)
	var card_w = floorf((cw - px(DESK_GAP) * (cols - 1)) / float(cols))
	_desk_cards = []
	for id in mine:
		var cd = _admiral_card(id, card_w, accent)
		grid.add_child(cd); _desk_cards.append(cd)
	_story_line(v)
	# the fixed bar: Back, Run options, Launch
	var back = kbtn("Back", "title", "", "back")
	var ro = Kit.button("Run options" + _run_opts_summary(), k, "quiet", func(): desk_opts_open = true; _dirty = true)
	ro.name = "RunOptionsButton"
	var go = fin("Launch the " + C.runWord(C.picked_faction), "startRun")
	var bar = Kit.action_bar(k, [back, ro], go)
	bar.anchor_top = 1.0; bar.anchor_bottom = 1.0; bar.anchor_right = 1.0
	bar.offset_left = left; bar.offset_right = -left; bar.offset_top = -px(80); bar.offset_bottom = -px(24)
	host.add_child(bar)
	if desk_opts_open: _desk_drawer(host)
	return host
func _crest_tab(f: String, w: float) -> Button:
	var found = _find(_acts, "pickFaction", f)
	if found.is_empty(): return null
	var picked = C.picked_faction == f
	var b = Button.new(); b.custom_minimum_size = Vector2(w, px(58)); b.focus_mode = Control.FOCUS_ALL; b.disabled = found[2] == 0
	b.tooltip_text = str(C.FACTIONS[f]["n"])
	var bx = Kit.button_boxes(k, "quiet")
	for st in bx: b.add_theme_stylebox_override(st, bx[st])
	b.add_theme_stylebox_override("focus", GS.focus_ring(k))
	if picked:
		var pb = (bx["normal"] as StyleBoxFlat).duplicate(); pb.bg_color = Color(GS.CAREER_PICTURE, 0.97); pb.border_color = GS.TEXT3
		pb.border_width_bottom = maxi(3, px(3)); pb.border_color = Kit.faction_accent(f)
		for st in ["normal", "hover", "pressed"]: b.add_theme_stylebox_override(st, pb)
	var h = HBoxContainer.new(); h.set_anchors_preset(Control.PRESET_FULL_RECT); h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", px(10)); h.alignment = BoxContainer.ALIGNMENT_CENTER
	var cr = TextureRect.new(); cr.texture = load("res://portraits/portraits.gd").faction_crest(f) if ResourceLoader.exists("res://portraits/portraits.gd") else null
	cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cr.custom_minimum_size = Vector2(px(34), px(34)); cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.modulate = Color(1, 1, 1, 1.0 if picked else 0.6)
	var crest_on = w / k >= 170.0   # a narrow strip drops the crest so the name keeps its words whole
	if crest_on: h.add_child(cr)
	else: cr.free()   # issue 1457: an unparented crest was 6 leaked TextureRects and crests at exit on a narrow window
	var name_w = w - (px(34) + px(10) if crest_on else 0) - px(20)
	var nl = Kit.label(str(C.FACTIONS[f]["n"]), 18, k, GS.TEXT if picked else GS.TEXT2, Kit.medium_font(), true, name_w / k)
	Kit.fit_words(nl, name_w, k)
	nl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(nl)
	b.add_child(h)
	b.pressed.connect(func(): _campaign_action("pickFaction", f))
	Kit.wire_sound(b, "tab")
	return b
func _admiral_card(id, w: float, accent: Color) -> Control:
	var a = C.ADMIRALS[id]; var un = C.admiralOwned(id); var picked = C.picked_admiral == id
	var cv = Kit.card(k, w / k, picked, accent if picked else Color(0, 0, 0, 0)); var body: VBoxContainer = cv[1]; var foot: VBoxContainer = cv[2]
	cv[0].custom_minimum_size.x = w
	var inner = floorf(w - px(14) * 2 - px(3) - px(4))   # the well margins, the picked bar on every card so all cards wrap alike, and a little slack for rounding
	var top = HBoxContainer.new(); top.add_theme_constant_override("separation", px(12)); body.add_child(top)
	var face = _face(id)
	var tr = TextureRect.new(); tr.texture = face; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var fs = minf(float(px(112 if _desk_compact else 160)), inner * (0.42 if inner / k >= 300.0 else 0.3))   # a narrow card keeps more room for the name
	tr.custom_minimum_size = Vector2(fs, fs); tr.mouse_filter = Control.MOUSE_FILTER_IGNORE; top.add_child(tr)
	var nv = VBoxContainer.new(); nv.add_theme_constant_override("separation", px(4)); nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(nv)
	var nm = Kit.label(_admiral_title(id), 21, k, GS.TEXT, Kit.medium_font(), true, (inner - fs - px(12)) / k); nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nv.add_child(nm)
	Kit.fit_words(nm, inner - fs - px(12), k)
	var dl = Kit.label(str(a["doc"]), 18, k, GS.TEXT2, null, true, (inner - fs - px(12)) / k); dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nv.add_child(dl)
	if picked: nv.add_child(Kit.label("SELECTED", 17, k, accent, Kit.medium_font(), false))
	elif not un: nv.add_child(Kit.label("LOCKED", 17, k, GS.TEXT3, Kit.medium_font(), false))
	var d = Kit.label(str(a["d"]), 18, k, GS.TEXT, null, true, inner / k); d.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(d)
	var mb = _mastery_bar(id, _desk_compact)
	var tips = [str(mb.get_meta("next_line", ""))]
	if mb.get_child_count() >= 3:   # the heir or shadow line moves to the bar's hover
		var hl = mb.get_child(2); tips.append((hl as Label).text); hl.queue_free(); mb.remove_child(hl)
	mb.tooltip_text = "\n".join(PackedStringArray(tips.filter(func(t): return t != ""))); mb.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(mb)
	if C.jt(a.get("cmd")):
		var ct = _cmd_text(a["cmd"], C.picked_faction)
		var cmd_l = rich(c("Command:", BONE3) + " [b]" + esc(a["cmd"]["n"]) + "[/b]" + ("" if _desk_compact else ". " + c(esc(ct), GS.TEXT2)), 17)
		cmd_l.tooltip_text = (ct + "\n" if _desk_compact else "") + "Gets stronger each round you hold it."; body.add_child(cmd_l)
	# the starting fleet as silhouettes; the names on hover
	var names = []; var sil = HBoxContainer.new(); sil.add_theme_constant_override("separation", px(10))
	var n_ships = maxi(1, a["start"].size())
	var sil_w = minf(float(px(90)), (inner - px(10) * (n_ships - 1)) / float(n_ships))   # the strip never widens its card
	for t in a["start"]:
		var hid = C.equivHull(t, C.picked_faction); var H = C.HULLS[hid]; names.append(str(H["n"]))
		var tex = Kit.silhouette(load("res://render/hull_table.gd").code_for(str(H.get("fac", C.picked_faction)), str(H.get("cls", ""))))
		if tex != null:
			var st = TextureRect.new(); st.texture = tex; st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var sh = float(px(26)); var asp = float(tex.get_width()) / maxf(1.0, float(tex.get_height()))
			st.custom_minimum_size = Vector2(minf(clampf(sh * asp, sh, px(90)), sil_w), sh); st.modulate = GS.TEXT2; st.mouse_filter = Control.MOUSE_FILTER_IGNORE; sil.add_child(st)
	var fl = VBoxContainer.new(); fl.add_theme_constant_override("separation", px(4)); fl.tooltip_text = "Starting fleet: " + ", ".join(PackedStringArray(names)); fl.mouse_filter = Control.MOUSE_FILTER_PASS
	fl.add_child(Kit.label("STARTING FLEET  " + str(names.size()) + " SHIPS", 17, k, GS.TEXT3, Kit.medium_font(), false))
	if sil.get_child_count() > 0: fl.add_child(sil)
	else: fl.add_child(Kit.label(", ".join(PackedStringArray(names)), 17, k, GS.TEXT2, null, true, inner / k))
	body.add_child(fl)
	if not un:
		for ch in body.get_children(): ch.modulate.a = 0.55
	# the foot: Lineage on the left, Select or Unlock on the right
	var fr = HBoxContainer.new(); fr.add_theme_constant_override("separation", px(8)); fr.custom_minimum_size.y = px(40); foot.add_child(fr)
	var lin = kbtn("Lineage", "lineage", id, "link", 17) if C.LINEAGE_TREES.has(id) else null
	if lin != null: fr.add_child(lin)
	var sp = Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sp.mouse_filter = Control.MOUSE_FILTER_IGNORE; fr.add_child(sp)
	if un:
		var sb = kbtn("Selected" if picked else "Select", "pickAdmiral", id, "tab")
		if sb != null:
			if picked: sb.add_theme_color_override("font_color", GS.TEXT)
			fr.add_child(sb)
	else:
		var ub = kbtn("Unlock: " + C.numstr(a.get("cost")) + " renown", "buyAdmiral", id, "quiet")
		if ub != null: fr.add_child(ub)
		else: fr.add_child(Kit.label("Unlock: " + C.numstr(a.get("cost")) + " renown", 17, k, GS.TEXT2, null, false))
	return cv[0]
func _run_opts_summary() -> String:
	var bits = []
	if C.run_opt.get("alt", false): bits.append("alternate fleet")
	if C.run_opt.get("cmdAlt", false): bits.append("alternate Command")
	var hl = C.heatLevel(C.run_opt.get("heat", []))
	if float(hl) > 0: bits.append("Threat " + C.numstr(hl))
	if C.map_trial_choice: bits.append("test maps")
	return (": " + ", ".join(PackedStringArray(bits))) if not bits.is_empty() else ""
func _desk_drawer(host: Control) -> void:
	var vs = get_viewport().get_visible_rect().size
	var dim = ColorRect.new(); dim.set_anchors_preset(Control.PRESET_FULL_RECT); dim.color = Color(GS.HALO, 0.45); dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: close_run_options())
	host.add_child(dim)
	var first = not host.has_meta("drawer_seen") and not _drawer_shown
	var dr = Kit.drawer(host, k, minf(float(px(560)), vs.x - px(24)), first, _reduce_motion())
	dr.name = "RunOptionsDrawer"
	_drawer_shown = true
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", px(14)); dr.add_child(v)
	var dsc = ScrollContainer.new(); dsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; dsc.size_flags_vertical = Control.SIZE_EXPAND_FILL; v.add_child(dsc)
	var ro = _run_options(); ro.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dsc.add_child(ro)
	v.add_child(Kit.action_bar(k, [], Kit.button("Done", k, "primary", func(): close_run_options())))
var _drawer_shown := false
func close_run_options() -> void:
	if not desk_opts_open: return
	desk_opts_open = false; _drawer_shown = false; _dirty = true; _focus_opener = true
	Kit.play("ui_cancel")
func _reduce_motion() -> bool:
	var m = get_node_or_null("/root/Main")
	return m != null and "settings" in m and bool(m.settings.get("reduce_motion", false))
# ---------------- story layer hooks (godot/story/README.md, hook 3): all guarded, nothing here changes campaign state ----------------
func _story() -> Node:
	var p = get_parent()
	return p.get_node_or_null("Story") if p != null else null
func _story_text() -> String:
	var st = _story()
	return str(st.campaign_line()) if st != null else ""
func _story_line(v: Control) -> void:
	var t = _story_text()
	if t != "": v.add_child(lbl(t, 17, VERD))   # the admiral's voice: calm information, not an action
func _admiral_title(id) -> String:   # the admiral's name with the latest earned title
	var st = _story()
	if st != null:
		var t = str(st.titled_name(str(id)))
		if t != "": return t
	return str(C.ADMIRALS[id]["n"])
var _faces := {}
func _face(id) -> Texture2D:
	if not ResourceLoader.exists("res://portraits/portraits.gd"): return null
	# Restoration frames (R78 Q17, issue 43): an Eclipse admiral's portrait shows his mastery level,
	# so the levelled frame must be part of the cache key or the portrait freezes at its first level.
	var level := 0; var cap := 0
	if C.ADMIRALS.has(id) and str(C.ADMIRALS[id].get("fac", "")) == "deathless":
		level = C.masteryLevel(id); cap = C.capstoneMasteryLevel(id) if C.LINEAGE_TREES.has(id) else 0
	var key := str(id) + ":" + str(level) + ":" + str(cap)
	if not _faces.has(key): _faces[key] = load("res://portraits/portraits.gd").face(str(id), level, cap)
	return _faces[key]
func _cmd_text(cmd, fac) -> String:
	var t = C.CMD_TEXT.get(cmd["id"])
	return str(t.get(fac, "")) if t != null else ""
func _mastery_bar(id, short := false) -> Control:
	var l = C.masteryLevel(id); var x = C.masteryXP(id); var thresholds = C.masteryThresholds(id); var nx = thresholds[l + 1] if l + 1 < thresholds.size() else null
	var tree = C.LINEAGE_TREES.has(id); var build = C.lineageBuild(id) if tree else null; var has_cap = build != null and build["capstone"] != null
	var label = ""; var right = ""; var f = 1.0
	if has_cap:
		var cm = C.capstoneMasteryLevel(id); var cm_next = C.capstoneMasteryNext(id)
		var base = float(C.CAPSTONE_MASTERY_XP[cm - 1]) if cm > 0 else float(thresholds[thresholds.size() - 1])
		label = "Capstone mastery " + str(cm) + "/" + str(C.CAPSTONE_MASTERY_XP.size())
		right = (C.numstr(x) + "/" + C.numstr(cm_next) + ": next " + str(C.capstoneMasteryPerk(cm + 1)["n"]).to_lower()) if cm_next != null else "fully mastered"
		f = min(1.0, (x - base) / (float(cm_next) - base)) if cm_next != null else 1.0
	else:
		label = "Mastery " + str(l) + "/" + str(thresholds.size() - 1)
		right = (C.numstr(x) + "/" + C.numstr(nx) + ": next " + str(C.masteryPerk(l + 1)["n"]).to_lower()) if nx != null else ("Level 8 reached: choose a Command evolution" if tree else "mastered")
		f = min(1.0, (x - float(thresholds[l])) / (float(nx) - float(thresholds[l]))) if nx != null else 1.0
	var v = vbox(3)
	v.add_child(rich(c(label, BONE) + ("" if short else " " + c(right, BONE3)), 17))
	if short: v.set_meta("next_line", right)   # the desk's narrow card shows the next unlock on hover
	var b = GS.seg_bar(k, f, VERD, GS.BAR_TRACK, 6, 10); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_child(b)   # progress, not an action: VERD
	v.add_child(lbl(("Priority: 50%" if C.META["heirs"].get(C.or_(C.ADMIRALS[id].get("fac"), "voidsworn")) == id else "Shadow: 25%") + " XP while benched", 17, BONE3))
	return v
func _run_options() -> Control:
	var v = vbox(10)
	v.add_child(Kit.heading("Run options", 34, k))
	var trial = CheckBox.new()
	trial.name = "MapTrialToggle"
	trial.text = "Test new battle maps, faster ships and longer gun ranges"
	trial.tooltip_text = "Also changes where ships start in Hunt, Ambush and boss fights. Applies to this whole run."
	trial.add_theme_font_size_override("font_size", px(18))
	trial.button_pressed = C.map_trial_choice
	trial.toggled.connect(func(on): C.act("optMapTrial", "1" if on else "0"))
	trial.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(trial)
	var cards = vbox(14); var o = C.page["data"]["opts"]; var id = C.picked_admiral; var a = C.ADMIRALS[id]   # issue 1217: stacked in the desk's drawer
	if int(o["ml"]) >= 1:
		var cv = card(false, 380); cv[1].add_child(lbl("Starting fleet", 20, BONE, font_semi))
		var std = []
		for t in a["start"]: std.append(C.HULLS[C.equivHull(t, C.picked_faction)]["n"])
		var alt = []
		for t in o["alt"]["fleet"]: alt.append(C.HULLS[t]["n"])
		var alts = ", ".join(PackedStringArray(alt)) + ((" (the carrier starts with a " + str(C.MODULES[o["alt"]["mod"]]["n"]).to_lower() + ")") if o["alt"]["mod"] != null else "")
		add(cv[1], choice("Standard", ", ".join(PackedStringArray(std)), "optAlt", "0", null, null, "", BONE2, not C.run_opt["alt"]))
		add(cv[1], choice("Alternate", alts, "optAlt", "1", null, null, "", BONE2, C.run_opt["alt"]))
		cards.add_child(cv[0])
	if o["cmd2"] != null:
		var cv2 = card(false, 380); cv2[1].add_child(lbl("Command", 20, BONE, font_semi))
		add(cv2[1], choice(a["cmd"]["n"], _cmd_text(a["cmd"], C.picked_faction), "optCmd", "0", null, null, "", BONE2, not C.run_opt["cmdAlt"]))
		add(cv2[1], choice(o["cmd2"]["n"], _cmd_text(o["cmd2"], C.picked_faction), "optCmd", "1", null, null, "", BONE2, C.run_opt["cmdAlt"]))
		cards.add_child(cv2[0])
	if o["heat"]:
		var hl = C.heatLevel(C.run_opt["heat"]); var best = float(C.z0(C.META["heatBest"].get(C.picked_faction)))
		var cv3 = card(false, 420)
		cv3[1].add_child(rich("[b]Threat " + C.numstr(hl) + "[/b] " + c("+" + C.numstr(hl * 10) + "% renown" + ((" \u00b7 best win with this faction: Threat " + C.numstr(best)) if best > 0 else ""), BONE3), 19))
		cv3[1].add_child(lbl("Optional rules that make the run harder. Pick any.", 17, BONE3))
		for kk in C.HEAT.keys():
			var h = C.HEAT[kk]
			add(cv3[1], choice(h["n"] + "  +" + C.numstr(h["w"]), h["d"], "optHeat", kk, null, null, "", BONE2, C.run_opt["heat"].has(kk)))
		cards.add_child(cv3[0])
	else:
		var cv4 = card(false, 380); cv4[0].modulate.a = 0.55; cv4[1].add_child(lbl("Threat", 20, BONE, font_semi))
		cv4[1].add_child(lbl("Lose a run to unlock Threat: optional rules that make runs harder and pay more renown.", 18, BONE3)); cards.add_child(cv4[0])
	v.add_child(cards)
	return v

# ---------------- aspect ----------------
# ---------------- the flagship podium (issue 1217 phase 4; Ryan: its own screen with a big live 3D ship) ----------------
# Left: the flagship, big, turning slowly (still under Reduce motion), with its name plate. Right: the aspect offers as
# cards you pick, then what rides along (a patron's gift, Heat, the cores in range). The bar: Back (the rules action
# backToSetup, both twins) and one ember Launch that takes the picked aspect.
const Podium = preload("res://ui/campaign/flagship_podium.gd")
var aspect_pick := ""               # the aspect card picked on this page; Launch takes it
var _aspect_cards: Array = []       # [card, id] of the last render (front_end_test)
var podium: Control = null
func _podium() -> Control:
	var vs = get_viewport().get_visible_rect().size
	var d = C.page["data"]; var f = d["flag"]; var R = C.RUN
	if not (d["opts"] as Array).has(aspect_pick): aspect_pick = ""
	var fac = str(R["fac"]); var accent = Kit.faction_accent(fac)
	var host = Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.theme = Kit.theme(k)
	var veil = TextureRect.new(); veil.texture = GS.ledger_veil(); veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; veil.stretch_mode = TextureRect.STRETCH_SCALE; veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; host.add_child(veil)
	var cw = minf(vs.x - px(DESK_PAD) * 2, float(px(1640)))
	var left = (vs.x - cw) * 0.5
	var col_w = clampf(cw * 0.36, float(px(420)), float(px(620)))
	var stage_w = cw - col_w - px(40)
	# the stage: the ship over a soft glow in its engine colour, and its name plate
	var stage = Control.new(); stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.offset_left = left; stage.offset_top = px(28); stage.anchor_bottom = 1.0; stage.offset_bottom = -px(96); stage.offset_right = left + stage_w
	host.add_child(stage)
	var glow = TextureRect.new(); glow.texture = _podium_glow(accent); glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; glow.stretch_mode = TextureRect.STRETCH_SCALE; glow.mouse_filter = Control.MOUSE_FILTER_IGNORE; stage.add_child(glow)
	# issue 1559 item 27: a pick re-renders the page; the same flagship keeps its live podium (no reload hitch, and the
	# turning ship carries on from where it was instead of snapping back to its start angle)
	var pkey = str(f.get("uid", "")) + "|" + str(f["tpl"]) + "|" + accent.to_html() + "|" + str(_reduce_motion())
	if podium != null and is_instance_valid(podium) and not podium.is_queued_for_deletion() and str(podium.get_meta("podium_key", "")) == pkey:
		if podium.get_parent() != null: podium.get_parent().remove_child(podium)
		stage.add_child(podium); podium.offset_bottom = -px(120)
	else:
		podium = Podium.new(); podium.set_anchors_preset(Control.PRESET_FULL_RECT); podium.offset_bottom = -px(120); stage.add_child(podium)
		podium.setup(C, f, accent, _reduce_motion()); podium.set_meta("podium_key", pkey)
	var plate = VBoxContainer.new(); plate.add_theme_constant_override("separation", px(4)); plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.anchor_top = 1.0; plate.anchor_bottom = 1.0; plate.anchor_right = 1.0; plate.offset_top = -px(112); stage.add_child(plate)
	plate.add_child(Kit.section("Your flagship", k))
	plate.add_child(Kit.heading(str(f["name"]), 44, k))
	var rb = ColorRect.new(); rb.color = accent; rb.custom_minimum_size = Vector2(px(72), maxi(2, px(3))); rb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; rb.mouse_filter = Control.MOUSE_FILTER_IGNORE; plate.add_child(rb)
	plate.add_child(Kit.label(str(C.HULLS[f["tpl"]]["n"]) + ", " + str(C.FACTIONS[fac]["n"]), 18, k, GS.TEXT2, null, false))
	# the column: the aspects, then what rides along
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.offset_left = left + stage_w + px(40); sc.offset_right = sc.offset_left + col_w; sc.offset_top = px(28); sc.anchor_bottom = 1.0; sc.offset_bottom = -px(96)
	host.add_child(sc)
	var v = VBoxContainer.new(); v.custom_minimum_size.x = col_w - px(4); v.add_theme_constant_override("separation", px(12)); sc.add_child(v)
	v.add_child(Kit.heading("Choose its refit", 36, k))
	v.add_child(Kit.label("One refit for the whole " + C.runWord() + ". If the flagship falls, it passes to your next-largest ship.", 18, k, GS.TEXT2, null, true, (col_w - px(4)) / k))
	_aspect_cards = []
	for kk in d["opts"]:
		var ac = _aspect_card(str(kk), col_w - px(4), accent); v.add_child(ac); _aspect_cards.append([ac, str(kk)])
	if C.jt(R.get("giftBoon")):
		var gb = R["giftBoon"]
		v.add_child(rich(c("A gift from " + esc(C.PATRONS[C.BOONS[gb]["p"]]["n"]) + ", now Synced with you: ", BONE2) + "[b]" + esc(C.BOONS[gb]["n"]) + "[/b]", 17))
	if R.get("heat") is Array and R["heat"].size() > 0:
		var hn = []
		for kk in R["heat"]: hn.append(C.HEAT[kk]["n"])
		v.add_child(Kit.label("Threat " + C.numstr(C.heatLevel(R["heat"])) + ": " + ", ".join(PackedStringArray(hn)) + ".", 17, k, BLOOD, null, true, (col_w - px(4)) / k))
	var ps = []
	for p in R["patrons"]: ps.append("[b]" + c(esc(C.PATRONS[p]["n"]), Color(C.PATRONS[p]["col"])) + "[/b]")
	var pl = rich(c("Cores in range: ", BONE3) + ", ".join(PackedStringArray(ps)) + c(". Win battles carrying their signal to earn their protocols.", BONE3), 17)
	var pt = []
	for p in R["patrons"]: pt.append(str(C.PATRONS[p]["n"]) + ": " + str(C.PATRONS[p]["theme"]).to_lower())
	pl.tooltip_text = "\n".join(PackedStringArray(pt)); pl.mouse_filter = Control.MOUSE_FILTER_PASS; v.add_child(pl)
	# the bar
	var back = kbtn("Back", "backToSetup", "", "back")
	var go: Button
	if aspect_pick != "": go = kbtn("Launch with " + str(C.ASPECTS[aspect_pick]["n"]), "pickAspect", aspect_pick, "primary")
	else:
		go = Kit.button("Pick a refit to launch", k, "primary", Callable()); go.disabled = true
	go.name = "LaunchButton"
	var bar = Kit.action_bar(k, [back], go)
	bar.anchor_top = 1.0; bar.anchor_bottom = 1.0; bar.anchor_right = 1.0
	bar.offset_left = left; bar.offset_right = -left; bar.offset_top = -px(80); bar.offset_bottom = -px(24)
	host.add_child(bar)
	return host
func _aspect_card(id: String, w: float, accent: Color) -> Control:
	var picked = aspect_pick == id
	var cv = Kit.card(k, w / k, picked, accent if picked else Color(0, 0, 0, 0)); var body: VBoxContainer = cv[1]
	cv[0].custom_minimum_size.x = w
	var inner = floorf(w - px(14) * 2 - px(3) - px(4))
	var top = HBoxContainer.new(); top.add_theme_constant_override("separation", px(10)); body.add_child(top)
	var nm = Kit.label(str(C.ASPECTS[id]["n"]), 22, k, GS.TEXT, Kit.medium_font(), true, (inner - px(110)) / k); nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(nm)
	if picked: top.add_child(Kit.label("PICKED", 17, k, accent, Kit.medium_font(), false))
	var dl = Kit.label(str(C.ASPECTS[id]["d"]), 18, k, GS.TEXT2, null, true, inner / k); dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(dl)
	# the whole card is the button: a click, or Enter on its focus, picks it
	var hit = Button.new(); hit.flat = true; hit.set_anchors_preset(Control.PRESET_FULL_RECT); hit.focus_mode = Control.FOCUS_ALL
	hit.add_theme_stylebox_override("focus", GS.focus_ring(k)); hit.tooltip_text = "Pick " + str(C.ASPECTS[id]["n"])
	for st in ["normal", "hover", "pressed", "disabled"]: hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	Kit.wire_sound(hit, "tab")
	hit.pressed.connect(func(): aspect_pick = id; _dirty = true)
	cv[0].add_child(hit)
	cv[0].name = "Aspect_" + id
	return cv[0]
var _glow_cache := {}
func _podium_glow(col: Color) -> Texture2D:
	var key = col.to_html()
	if _glow_cache.has(key): return _glow_cache[key]
	var g = Gradient.new(); g.set_color(0, Color(col, 0.20)); g.set_color(1, Color(col, 0.0))
	var t = GradientTexture2D.new(); t.gradient = g; t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.55); t.fill_to = Vector2(0.5, 0.0); t.width = 256; t.height = 256
	_glow_cache[key] = t
	return t

# ---------------- the sector map: the Briefing layout (Ryan's pick, Nov 10 2026, FINDINGS R165) ----------------
# The first spec (archived) is docs/archive/briefs/campaign_map_briefing.md; the live look is contrib/opus/briefs/campaign_rail_orders_sheet.md; the first picture is contrib/opus/ui_map_design/map_option_C_briefing.jpg.
# Left: one flat column, 480 wide (the sector, the routes you can take as numbered rows, the ember action, the
# Nemesis in a few lines, the fleet). Right: the real 3D chart with plain words on it (map3d.gd). Two colours on top of the
# pale text: ember is the next action and the next jumps, NEM red is the Nemesis. Everything else the old screen said is one
# hover or one click away: the map's hover tip, the Map key and the Dossier (the two slide-overs below).
# Every fact comes through campaign_view.gd, which only reads; every size is on the mockup's ladder (13, 14, 15, 18, 20, 22,
# 28 to 30, 40) and every gap on an 8 px grid, at the 1080 design height.
const COL_W := 540.0
const COL_PAD := 40.0
const OVER_W := 520.0            # the Dossier and the Map key slide-overs
var picked := ""                 # the next jump picked in the route list (a stop's id); the map and the list share it
var _overlay := ""               # "", "dossier" or "key"
var _routes: Array = []          # View.routes(C), each with its danger (map_intel.gd)
var _rows: Array = []            # [{id, btn, num}] the route rows of the last render
var _jump_btn: Button = null
var _jump_lbl: Label = null
var _rail_host: Control
var _rail_pending := false
var _route_click_id := ""
var _route_click_rect := Rect2()
func caps(text: String, size: float = 17, col: Color = BONE3) -> Label: return lbl(text.to_upper(), size, col, font_caps, false)
# a well holding a block of a dialog: [PanelContainer, VBoxContainer]; bar is the left bar's colour
func blk(bar_col: Color = Color(0, 0, 0, 0), sep: float = 5, pad_x: float = 12, pad_y: float = 9) -> Array:
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", GS.well(k, Color(0, 0, 0, 0), pad_x, pad_y, bar_col))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var v = vbox(sep); p.add_child(v); return [p, v]
# One line of text in a fixed line box (its size and its line height, as the mockup writes them), so the column's heights add
# up exactly and every baseline sits where the grid puts it. expand: the line takes the row's free width and trims with an
# ellipsis; otherwise it is as wide as its words.
func tl(text: String, size: float, lh: float, col: Color = GS.TEXT, f: Font = null, expand: bool = false) -> Control:
	var w = Control.new(); w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ff = f if f != null else GS.sheet_body()
	var l = Label.new(); l.text = text; l.add_theme_font_override("font", ff); l.add_theme_font_size_override("font_size", px(size)); l.add_theme_color_override("font_color", col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		w.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true; l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	else: w.custom_minimum_size.x = ceil(ff.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(size)).x) + 1.0
	w.custom_minimum_size.y = px(lh)
	w.add_child(l); l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); w.set_meta("label", l)
	return w
# A paragraph in fixed line boxes: wraps to width w (at 1080), shows at most max_lines and trims the rest with an ellipsis.
# Returns [Label, lines shown]. The label's height is lines x lh, so a caller can add it up.
func para(text: String, size: float, lh: float, col: Color, w: float, max_lines: int = 2, f: Font = null) -> Array:
	var ff = f if f != null else GS.sheet_body()
	var l = Label.new(); l.text = text; l.add_theme_font_override("font", ff); l.add_theme_font_size_override("font_size", px(size)); l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.max_lines_visible = max_lines; l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var fh = ff.get_height(px(size))
	l.add_theme_constant_override("line_spacing", int(px(lh) - fh))
	l.custom_minimum_size.x = px(w); l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lines = _lines_of(text, ff, px(size), px(w), max_lines)
	l.custom_minimum_size.y = lines * px(lh); l.clip_text = false
	return [l, lines]
func _lines_of(text: String, ff: Font, size: int, w: int, max_lines: int) -> int:
	if text == "": return 0
	var h = ff.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, size).y
	return clampi(int(round(h / max(1.0, ff.get_height(size)))), 1, max_lines)
func gap(h: float) -> Control:
	var g = Control.new(); g.custom_minimum_size.y = px(h); g.mouse_filter = Control.MOUSE_FILTER_IGNORE; return g
func hgap(w: float) -> Control:
	var g = Control.new(); g.custom_minimum_size.x = px(w); g.mouse_filter = Control.MOUSE_FILTER_IGNORE; return g
func padded(ctl: Control, side: float = COL_PAD) -> MarginContainer:
	var m = MarginContainer.new(); m.add_theme_constant_override("margin_left", px(side)); m.add_theme_constant_override("margin_right", px(side))
	m.add_theme_constant_override("margin_top", 0); m.add_theme_constant_override("margin_bottom", 0); m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(ctl); return m
func row0(sep: float = 0) -> HBoxContainer:   # a row whose parts keep the mouse off themselves (the row's owner takes it)
	var h = hbox(sep); h.mouse_filter = Control.MOUSE_FILTER_IGNORE; return h
# a plain text button in a fixed line box (GS.plain_button): words only
# over_map: the words sit straight on the chart (Map key, Save and quit), so they carry the map's dark halo (issue 678: the
# Map key read 2.68 to 1 over a bright star); the same words on the briefing column or a slide-over need none.
func tbtn(text: String, size: float, lh: float, cb: Callable, tip_t: String = "", over_map: bool = false) -> Control:
	var w = Control.new()
	var b = Button.new(); b.text = text; b.alignment = HORIZONTAL_ALIGNMENT_LEFT; GS.plain_button(b, k, maxf(17, size), GS.sheet_body())
	b.add_theme_color_override("font_color", GS.TEXT2); b.add_theme_color_override("font_hover_color", GS.TEXT); b.add_theme_color_override("font_focus_color", GS.TEXT)
	if over_map:
		b.add_theme_color_override("font_outline_color", Color(GS.HALO, 1.0)); b.add_theme_constant_override("outline_size", maxi(6, px(10)))
	w.custom_minimum_size = Vector2(ceil(GS.sheet_body().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(size)).x) + 2.0, px(lh))
	if tip_t != "": b.tooltip_text = tip_t
	b.pressed.connect(cb); w.add_child(b); b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); w.set_meta("button", b)
	return w
# words broken into lines for a tooltip (tooltips do not wrap by themselves)
func _wrap_words(t: String, n: int = 64) -> String:
	var out: Array = []
	for para_t in t.split("\n"):
		var line = ""
		for w in para_t.split(" "):
			if line != "" and line.length() + 1 + w.length() > n: out.append(line); line = w
			else: line = w if line == "" else line + " " + w
		out.append(line)
	return "\n".join(PackedStringArray(out))
# the danger of a fight as the column and the tip show it: four pips and the band's word (two channels, neither a colour)
func danger_of(n) -> Dictionary:
	if n == null or map3d == null or map3d.intel == null: return {}
	return map3d.intel.danger(n)

func _map() -> Control:
	var wrap = Control.new(); wrap.set_anchors_preset(Control.PRESET_FULL_RECT); wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var th = GS.sheet_theme(k); th.set_stylebox("panel", "TooltipPanel", GS.tip(k)); th.set_font_size("font_size", "TooltipLabel", px(17)); th.set_color("font_color", "TooltipLabel", GS.TEXT2)
	wrap.theme = th
	if map3d != null and map3d.intel == null: map3d.sync()
	_routes = View.routes(C)
	for r in _routes: r["danger"] = danger_of(C.findNode(r["id"]))
	if not _routes.any(func(r): return r["id"] == picked): picked = str(_routes[0]["id"]) if _routes.size() > 0 else ""
	# the right side: plain text buttons top right, the purse bottom right (the chart itself is map3d.gd, under this page)
	var top = row0(36); top.anchor_left = 1.0; top.anchor_right = 1.0; top.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	top.offset_right = -px(48); top.offset_top = px(44)
	top.add_child(tbtn("Map key", 17, 24, func(): _open_overlay("key"), "What the marks mean, this sector, your run, the controls.", true))
	if not _find(_acts, "saveQuit", "").is_empty(): top.add_child(tbtn("Save and quit", 17, 24, func(): C.act("saveQuit", ""), "", true))
	wrap.add_child(top)
	var P = View.purse(C)
	var bio_cells = [["Biomass", GS.sheet_body(), 17, GS.TEXT2], [12], [C.numstr(P["bio"]), font_num_b, 28, GS.TEXT], [48]] if P.has("bio") else []
	var purse = _baseline_row(bio_cells + [["Credits", GS.sheet_body(), 17, GS.TEXT2], [12], [C.numstr(P["credits"]), font_num_b, 28, GS.TEXT], [48],
		["Command points", GS.sheet_body(), 17, GS.TEXT2], [12], [C.numstr(P["cp"]), font_num_b, 28, GS.TEXT], [0], ["/" + C.numstr(P["cp_cap"]), font_num, 28, GS.TEXT2]], 32)
	purse.anchor_left = 1.0; purse.anchor_right = 1.0; purse.anchor_top = 1.0; purse.anchor_bottom = 1.0
	purse.offset_right = -px(48); purse.offset_left = purse.offset_right - purse.custom_minimum_size.x; purse.offset_bottom = -px(40); purse.offset_top = purse.offset_bottom - purse.custom_minimum_size.y
	wrap.add_child(purse)
	_rail_host = Control.new(); _rail_host.set_anchors_preset(Control.PRESET_FULL_RECT); _rail_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(_rail_host); _rail_host.add_child(_briefing_column())
	if _overlay == "dossier": wrap.add_child(_slide_over(_dossier(), COL_W))
	elif _overlay == "key": wrap.add_child(_slide_over(_map_key(), -1.0))
	return wrap
# several pieces of text on one baseline (a small label beside a big number): parts are [text, font, size, colour] or [gap]
func _baseline_row(parts: Array, lh: float) -> Control:
	var c = Control.new(); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w = 0.0; var big = 0
	for p in parts:
		if p.size() == 1: w += px(p[0])
		else: w += ceil(p[1].get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, px(p[2])).x); big = max(big, px(p[2]))
	c.custom_minimum_size = Vector2(w, px(lh)); c.set_meta("sheet_parts", parts)
	c.draw.connect(func():
		var bf: Font = font_num_b
		for p in parts:
			if p.size() > 1 and px(p[2]) == big: bf = p[1]; break
		var base = c.size.y * 0.5 + (bf.get_ascent(big) - bf.get_descent(big)) * 0.5
		var x = 0.0
		for p in parts:
			if p.size() == 1: x += px(p[0]); continue
			c.draw_string(p[1], Vector2(x, base), p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, px(p[2]), p[3])
			x += ceil(p[1].get_string_size(p[0], HORIZONTAL_ALIGNMENT_LEFT, -1, px(p[2])).x))
	return c

# Orders sheet: an unboxed rail. The route group can scroll in extreme cases; the fleet stays at the foot.
func _sheet_words(text: String, size: float, col: Color = GS.TEXT, medium := false) -> Label:
	return lbl(text, maxf(17, size), col, GS.sheet_medium() if medium else GS.sheet_body())

# Fit names by wrapping whole words, keeping Big Shoulders at or above 28 px.
func _sheet_name(text: String, size: float, width: float, lines := 2) -> Label:
	var f = GS.sheet_name(); var fs = size; var t = text.to_upper()
	while fs > 28 and (f.get_multiline_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, px(width), px(fs)).y > f.get_height(px(fs)) * lines + 1 or Array(t.split(" ")).any(func(w): return f.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, px(fs)).x > px(width))): fs -= 1
	var l = lbl(t, fs, GS.TEXT, f); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.custom_minimum_size.x = px(width)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _sheet_rule() -> Control:
	var line = ColorRect.new(); line.color = GS.SHEET_HAIR; line.custom_minimum_size.y = px(1); line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _approach_strip(H: Dictionary) -> Control:
	var h = row0(16)
	for i in 3:
		var v = vbox(4); var on = i + 1 == H["sector"]
		var bar = ColorRect.new(); bar.color = GS.MAP_EMBER if on else GS.TEXT3; bar.custom_minimum_size = Vector2(px(58), px(4 if on else 1)); bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(bar); v.add_child(tl(["I", "II", "III"][i], 17, 22, GS.MAP_EMBER if on else GS.TEXT2, font_num))
		h.add_child(v)
	var star = Control.new(); star.custom_minimum_size = Vector2(px(18), px(24)); star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.draw.connect(func(): star.draw_arc(Vector2(px(9), px(8)), px(7), 0, TAU, 32, GS.MAP_EMBER, px(1.5), false))
	h.add_child(star); h.add_child(_sheet_words("Jump %d of %d" % [H["jump"], H["jumps"]], 19, GS.TEXT2, true))
	return h

func _condition_line(S: Dictionary) -> String:
	var short = {"Ion season": "shields recharge 25% slower.", "Dark sector": "nebula hexes give -15 to hit.", "Wreck belt": "wreckage pays 15% more credits.", "War zone": "reinforcements; fights pay 20% more.", "Scarcity": "repairs restore 25% less."}
	return str(S["cond_n"]) + ": " + str(short.get(S["cond_n"], S["cond_d"])) if S["cond_n"] != "" else ""

func _briefing_column() -> Control:
	var H = View.header(C); var S = View.sector_notes(C); var N = View.nemesis(C); var fleet = View.fleet_rows(C)
	var cw = COL_W - COL_PAD * 2.0
	var col = MarginContainer.new(); col.name = "OrdersSheet"; col.mouse_filter = Control.MOUSE_FILTER_STOP
	col.mouse_force_pass_scroll_events = false
	col.anchor_bottom = 1.0; col.offset_right = px(COL_W)
	for side in ["left", "right"]: col.add_theme_constant_override("margin_" + side, px(COL_PAD))
	col.add_theme_constant_override("margin_top", px(40)); col.add_theme_constant_override("margin_bottom", px(28))
	var v = vbox(0); col.add_child(v)
	var sc = ScrollContainer.new(); sc.name = "OrdersScroll"; sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var upper = vbox(0); upper.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(upper); v.add_child(sc)
	upper.add_child(_approach_strip(H)); upper.add_child(gap(8))
	var region_line = row0(12)
	var region_name = _sheet_name(H["region"] if H["region"] != "" else "Sector " + H["sector_roman"], 70, cw - 52, 1)
	region_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL; region_line.add_child(region_name)
	region_line.add_child(GS.region_emblem(_region_key(H["region"]), k)); upper.add_child(region_line)
	var _holder := str(S["holder"])
	upper.add_child(_sheet_words(("Held by " + _holder) if _holder == "Eclipse" else ("Held by the " + _holder.trim_prefix("The ")), 21, GS.TEXT, true))
	if H["map_trial"]:   # issue 1175: the issue 1050 trial label shows only while the trial is on
		var trial_status := _sheet_words("Test map package on", 17, GS.TEXT2)
		trial_status.name = "MapTrialStatus"
		upper.add_child(trial_status)
	upper.add_child(gap(4)); var cond = _sheet_words(_condition_line(S), 19, GS.TEXT2); cond.tooltip_text = _wrap_words(S["cond_d"]); upper.add_child(cond)
	upper.add_child(gap(28)); _rows.clear()
	for r in _routes:
		upper.add_child(_route_row(r)); upper.add_child(gap(8 if _routes.size() >= 4 else 16))
	if not N.is_empty():
		v.add_child(gap(12)); v.add_child(_sheet_rule()); v.add_child(gap(16)); v.add_child(_nemesis_block(N, cw)[0]); v.add_child(gap(16))
	v.add_child(_sheet_rule()); v.add_child(gap(12))
	var list = vbox(0); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for ship in fleet: list.add_child(_fleet_line(ship, 36))
	var fleet_scroll = ScrollContainer.new(); fleet_scroll.name = "FleetScroll"; fleet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Seven standard 36 px lines fit at the foot. Larger fleets scroll without shrinking the text.
	fleet_scroll.custom_minimum_size.y = px(36 * mini(7, fleet.size())); fleet_scroll.add_child(list); v.add_child(fleet_scroll)
	v.add_child(gap(6))
	var pend = View.promotion_waiting(C)
	var fleet_tip = "Captains, perks, refits, spare hold, and faction map action."
	if map3d != null and map3d.intel != null:
		var fc = map3d.intel.fleet_condition()
		if fc["hurt"]:
			var repairs = map3d.intel.all_paths().any(func(path): return map3d.intel.path_stats(path)["repair_before_boss"])
			fleet_tip += "\nFleet hull at %d%%. " % int(round(fc["avg"] * 100)) + ("Plan a repair stop before the flagship." if repairs else "No repair stop remains before the flagship.")
	v.add_child(tbtn("Promote captains and refit" if pend else "Fleet and refits", 17, 26, func(): C.act("fleetScreen", ""), _wrap_words(fleet_tip)))
	# Give the routes their full height first. The fleet scrolls in whole standard rows in the space left.
	var fit_fleet = func():
		if not is_instance_valid(v) or v.size.y <= 0: return
		var fixed = 0.0
		for child in v.get_children():
			if child != sc and child != fleet_scroll: fixed += child.get_combined_minimum_size().y
		var minimum_lines = mini(3, maxi(1, fleet.size()))
		var lines = clampi(int(floor((v.size.y - fixed - upper.get_combined_minimum_size().y) / px(36))), minimum_lines, mini(7, maxi(1, fleet.size())))
		fleet_scroll.custom_minimum_size.y = px(36 * lines)
	upper.minimum_size_changed.connect(func(): fit_fleet.call_deferred())
	v.resized.connect(func(): fit_fleet.call_deferred())
	fit_fleet.call_deferred()
	return col

func _objective_line(r: Dictionary) -> String:
	var short = {"Engagement": "Break their fleet to make it flee.", "Ambush": "Break the fleets closing in from both sides.", "Hold the station": "Keep enemies off the station through round 6.", "Hunt": "Destroy their flagship before round 6 ends.", "Intercept": "Destroy the transports before they escape.", "Breakthrough": "Get your ships onto the far jump hexes.", "Relay": "Hold the relay, unopposed, for 3 rounds.", "Decapitation": "Destroy their flagship to scatter the fleet.", "Sector flagship": "Beat the command ship to end the sector."}
	var be := str(r.get("boss_enc", ""))
	if be != "" and short.has(be):   # issue 1175: the flagship stop names the fight it rolled with the map
		var o := str(short[be]).trim_suffix(".")
		return be + ": " + o.substr(0, 1).to_lower() + o.substr(1) + ", or destroy the command ship."
	return str(short.get(r["name"], str(r["objective"]).split(". ")[0].trim_suffix(".") + ".")) if r["objective"] != "" else ""

func _route_row(r: Dictionary) -> Control:
	var cw = COL_W - COL_PAD * 2.0; var on = r["id"] == picked
	var v = vbox(0); var b = Button.new(); b.name = "Route" + str(r["num"]); b.focus_mode = Control.FOCUS_ALL; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "disabled"]: b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", GS.focus_ring(k))
	var h = row0(20); b.add_child(h); h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var numw = _baseline_row([[str(r["num"]), GS.sheet_name(), 132 if on else 36, GS.MAP_EMBER if on else GS.TEXT]], 132 if on else 36)
	numw.custom_minimum_size.x = px(60 if on else 20); numw.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; h.add_child(numw)
	var tv = vbox(0); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; tv.mouse_filter = Control.MOUSE_FILTER_IGNORE; h.add_child(tv)
	var nw = cw - (80 if on else 40)
	var title = _sheet_name(r["name"], 54 if on else 32, nw)
	var dg: Dictionary = r.get("danger", {})
	tv.add_child(title)
	if on:
		var what = str(r["what"]).replace("Fight against ", "Fight ").replace("Elite fight against ", "Elite fight ")
		tv.add_child(_sheet_words(what, 20, GS.TEXT, true))
		var danger = row0(10)
		if r["fight"] and not dg.is_empty(): danger.add_child(GS.sheet_pips(k, float(dg["level"]), GS.TEXT, 10)); danger.add_child(_sheet_words(str(dg["band"]), 19, GS.TEXT2))
		elif not r["fight"]: danger.add_child(_sheet_words("No fight", 19, GS.TEXT2))
		tv.add_child(danger)
	else:
		var note = ("Nemesis meeting. " if r.get("nemesis", false) else "") + (str(dg.get("band", "")) + " fight." if r["fight"] else "No fight")   # issue 1175
		if r.get("nemesis", false) and r["kind"] in ["shipyard", "drydock", "field", "event"]:
			note = "Nemesis fight, then use the stop."
		if r["fight"] and r["reward"] != "": note += " Pays " + str(r["reward"])
		tv.add_child(_sheet_words(note, 18, GS.TEXT2))
	var row_height = 132 if on else (54 if _routes.size() >= 4 else 62)
	b.custom_minimum_size.y = maxf(px(row_height), tv.get_combined_minimum_size().y)
	# Children get their final widths before the minimum height is used, including a wrapped long name.
	tv.minimum_size_changed.connect(func(): if is_instance_valid(b): b.custom_minimum_size.y = maxf(px(row_height), tv.get_combined_minimum_size().y))
	var id = str(r["id"])
	b.pressed.connect(func():
		map3d.clear_keyboard_preview()
		pick_route(id))
	b.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_route_click_id = id
			_route_click_rect = b.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, b.size)
		elif e is InputEventKey and e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			b.accept_event()
			if e.pressed and not e.echo: _confirm_map_jump())
	b.tooltip_text = _wrap_words(_detail_text(r)); v.add_child(b)
	if on:
		v.add_child(gap(8)); v.add_child(_sheet_words(_objective_line(r), 20)); v.add_child(gap(4))
		var reward = row0(10); reward.add_child(tl("Pays", 19, 28, GS.TEXT3, GS.sheet_body()))
		reward.add_child(_sheet_words(str(r["reward"]) if r["reward"] != "" else ("Unknown" if r["kind"] == "event" else "Repairs" if r["kind"] in ["field", "drydock"] else "Shipyard access"), 19)); v.add_child(reward)
		v.add_child(gap(16)); v.add_child(_jump_button())
	_rows.append({"id": id, "btn": b, "num": numw})
	return v
# the detail under the list for the picked route: the objective, the enemy's archetype, a modifier, the board, the estimate
func _detail_text(r: Dictionary) -> String:
	var parts: Array = []
	if r["objective"] != "": parts.append(r["objective"])
	if r["arch"] != "": parts.append(r["arch"] + ": " + r["arch_d"])
	if r["mod"] != "": parts.append(r["mod"] + ": " + r["mod_d"])
	var where: Array = []
	if r["shape"] != "": where.append(r["shape"] + " board")
	if r["place"] != "": where.append("at " + ("an " if r["place"].substr(0, 1) in ["a", "e", "i", "o", "u"] else "a ") + r["place"])
	if where.size() > 0: parts.append(", ".join(PackedStringArray(where)).substr(0, 1).to_upper() + ", ".join(PackedStringArray(where)).substr(1) + ".")
	var dg: Dictionary = r.get("danger", {})
	if r["fight"] and not dg.is_empty():
		var t = "%s: their strength is about %d%% of your fleet's" % [dg["band"], int(round(dg["ratio"] * 100.0))]
		var wy: Array = dg.get("why", [])
		if not wy.is_empty():
			var ps: Array = []
			for w in wy: ps.append("%s %s%d%%" % [w[0], "+" if w[1] >= 1.0 else "", int(round((w[1] - 1.0) * 100.0))])
			t += " (includes " + ", ".join(PackedStringArray(ps)) + ")"
		parts.append(t + ".")
	return " ".join(PackedStringArray(parts))
func _jump_button() -> Button:
	var cur = {}
	for r in _routes:
		if r["id"] == picked: cur = r
	var b = Button.new(); b.name = "JumpAction"; b.custom_minimum_size.y = px(56); b.focus_mode = Control.FOCUS_ALL; b.set_meta("finish", true)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var jb = GS.sheet_jump_boxes(k)
	for st in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(st, jb["hover" if st == "focus" else st])
	var h = row0(12); b.add_child(h); h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); h.offset_left = px(16); h.offset_right = -px(16)
	var text = "JUMPING WHEN READY" if map3d != null and map3d._queued_jump else "JUMP TO " + str(cur.get("name", "")).to_upper(); var fs = 34.0
	while fs > 28 and GS.sheet_name().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(fs)).x > px(COL_W - COL_PAD * 2 - 132): fs -= 1
	var lw = tl(text, fs, 56, GS.MAP_EMBER, GS.sheet_name(), true); _jump_lbl = lw.get_meta("label"); h.add_child(lw)
	var key = tl("Enter", 19, 56, GS.MAP_EMBER, GS.sheet_body()); h.add_child(key)
	var arrow = tl("", 19, 56, GS.MAP_EMBER, GS.sheet_body()); arrow.custom_minimum_size.x = px(12); h.add_child(arrow)
	var action_label = _jump_lbl
	var paint = func():
		var active = b.is_hovered() or b.has_focus(); var col = GS.ON_EMBER if active else GS.MAP_EMBER
		action_label.add_theme_color_override("font_color", col); key.get_meta("label").add_theme_color_override("font_color", col)
		arrow.queue_redraw()
	arrow.draw.connect(func():
		var col = GS.ON_EMBER if b.is_hovered() or b.has_focus() else GS.MAP_EMBER
		var ctr = arrow.size * 0.5; arrow.draw_colored_polygon(PackedVector2Array([ctr + Vector2(-px(5), -px(6)), ctr + Vector2(px(6), 0), ctr + Vector2(-px(5), px(6))]), col))
	for sig in [b.mouse_entered, b.mouse_exited, b.focus_entered, b.focus_exited]: sig.connect(paint)
	b.disabled = cur.is_empty() or _find(_acts, "enterNode", picked).is_empty() or _find(_acts, "enterNode", picked)[2] == 0
	b.pressed.connect(_jump); _jump_btn = b
	Kit.wire_sound(b, "primary")
	return b
func route_num(id: String) -> int:   # the number a next jump wears in the list and on the map (0: not a next jump)
	for r in _routes:
		if r["id"] == id: return int(r["num"])
	return 0
# pick a next jump (a row click, its number key, or its stop on the map): the row lights, the button names it
func pick_route(id: String) -> void:
	# issue 1559 item 24: the fleet is already flying to its pick; a new pick would relight a route it is not taking
	if map3d != null and bool(map3d.get("_flying")): return
	# item 25: with the Dossier or the Map key open, a route on the rail still works: it shuts the slide-over first
	if _overlay != "": _close_overlay()
	if id == picked or not _routes.any(func(r): return r["id"] == id): return
	# A new pick is only a selection: it cancels a Jump queued under the loading cover, so the player confirms again (issue 1448).
	if map3d != null and map3d.has_method("cancel_queued_jump"): map3d.cancel_queued_jump()
	picked = id; _show_pick()
func _show_pick() -> void:
	if not _rail_pending and is_instance_valid(_rail_host):
		_rail_pending = true; call_deferred("_rebuild_rail")
func _rebuild_rail() -> void:
	_rail_pending = false
	if not is_instance_valid(_rail_host) or C.page.get("kind") != "map": return
	var focus = get_viewport().gui_get_focus_owner(); var restore = ""
	for r in _rows:
		if r["btn"] == focus: restore = r["id"]
	var scrolls := {}
	for scroll_name in ["OrdersScroll", "FleetScroll"]:
		var sc := _rail_host.find_child(scroll_name, true, false) as ScrollContainer
		if sc != null: scrolls[scroll_name] = sc.scroll_vertical
	for child in _rail_host.get_children(): _rail_host.remove_child(child); child.queue_free()
	var rail := _briefing_column()
	_rail_host.add_child(rail)
	if restore != "":
		for r in _rows:
			if r["id"] == restore: r["btn"].grab_focus()
	# The scrollbars know their new limits after the containers have laid out.
	get_tree().process_frame.connect(func():
		if not is_instance_valid(rail) or rail.is_queued_for_deletion() or rail.get_parent() != _rail_host: return
		for scroll_name in scrolls:
			var sc := rail.find_child(scroll_name, true, false) as ScrollContainer
			sc.scroll_vertical = scrolls[scroll_name], CONNECT_ONE_SHOT)
func _confirm_map_jump() -> void:
	if picked != "": Kit.play("ui_confirm")
	_jump()
func _jump() -> void:
	if picked == "" or C.modal_d != null or _find(_acts, "enterNode", picked).is_empty(): return
	if _overlay != "": _close_overlay()   # issue 1559 item 25: Jump on the rail works with a slide-over open
	if map3d != null and map3d.visible and not map3d.backdrop: map3d.fly_to(picked)   # the fleet flies the route, then the campaign enters the stop
	else: C.act("enterNode", picked)
# The Nemesis block: [control, its height at 1080]
func _nemesis_block(N: Dictionary, cw: float) -> Array:
	var v = vbox(8); var h = row0(16); var tex = nem_portrait()
	if tex != null:
		var frame = PanelContainer.new(); var sb = _sb(Color(0, 0, 0, 0), GS.NEM, 2, 0, 2); frame.add_theme_stylebox_override("panel", sb)
		var tr = TextureRect.new(); tr.texture = tex; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.custom_minimum_size = Vector2(px(64), px(64)); frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; frame.add_child(tr); h.add_child(frame)
	var tv = vbox(0); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(tv)
	var hd = row0(0); hd.add_child(_sheet_words("Nemesis", 17, GS.NEM, true)); hd.add_child(spacer()); hd.add_child(tbtn("Dossier", 17, 22, func(): _open_overlay("dossier")))
	tv.add_child(hd); tv.add_child(_sheet_name(N["full"], 32, cw - 80)); v.add_child(h)
	var clock = row0(16); clock.add_child(GS.sheet_pips(k, float(N["clock"]), GS.NEM, 12))
	clock.add_child(_baseline_row([["Hunt clock ", GS.sheet_body(), 17, GS.TEXT2], [C.numstr(N["clock"]), font_num, 17, GS.TEXT], [" of ", GS.sheet_body(), 17, GS.TEXT2], [C.numstr(N["clock_max"]), font_num, 17, GS.TEXT]], 24)); v.add_child(clock)
	if N["dead"] or N["strike"]: v.add_child(_sheet_words("Hunter defeated" if N["dead"] else "Strike incoming", 17, GS.NEM))
	return [v, v.get_combined_minimum_size().y / k]

func _fleet_line(s: Dictionary, rh: float) -> Control:
	var h = hbox(16); h.mouse_filter = Control.MOUSE_FILTER_STOP; h.custom_minimum_size.y = px(rh)
	if s["flagship"]:
		var diamond = Control.new(); diamond.custom_minimum_size = Vector2(px(10), px(rh)); diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		diamond.draw.connect(func(): GS.diamond(diamond, Vector2(px(5), px(rh) * 0.5), px(5), GS.MAP_EMBER)); h.add_child(diamond)
	var hp = C.hull_text(s["hp"]) + " / " + C.hull_text(s["max_hp"])
	var hw = ceil(font_num.get_string_size(hp, HORIZONTAL_ALIGNMENT_LEFT, -1, px(19)).x)
	var available = COL_W - COL_PAD * 2 - 16 - hw / k - (26 if s["flagship"] else 0)
	h.add_child(_sheet_name(s["name"], 28, available, 3))
	var figures = _baseline_row([[C.hull_text(s["hp"]), font_num, 19, (HULL_LOW if float(s["frac"]) < 0.35 else HULL) if float(s["frac"]) < 0.999 else GS.TEXT], [" / " + C.hull_text(s["max_hp"]), font_num, 19, GS.TEXT]], rh)
	figures.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(figures)
	h.tooltip_text = _wrap_words(s["name"] + ", " + s["cls"] + " Mk " + s["mk"] + "\n" + s["captain"] + ("\nPromotion ready" if s["promotion"] else ""))
	return h

# The purchase now lives at the top of Fleet and refits. It still calls the campaign's unchanged factionVerb action.
func _action_line(FA: Dictionary) -> Control:
	var v = vbox(6)
	v.add_child(lbl(FA["n"], 22, BONE, font_semi)); v.add_child(lbl(FA["d"], 18, BONE2))
	var b = Button.new(); b.focus_mode = Control.FOCUS_ALL; b.disabled = not C.verbCanUse()
	b.text = "Used this sector" if FA["used"] else str(FA["cost"])
	b.pressed.connect(func(): C.act("factionVerb", "")); v.add_child(b)
	return v

# ---------------- the two slide-overs: the Dossier and the Map key ----------------
func _open_overlay(which: String) -> void:
	_overlay = which; _dirty = true
func _close_overlay() -> void:
	if _overlay == "": return
	_overlay = ""; _dirty = true
# A slide-over: a flat panel the height of the screen (beside the column when left_at >= 0, at the right edge otherwise)
# and a shade over the rest of the chart. A click on the shade, Close or Esc shuts it.
func _slide_over(body: Control, left_at: float) -> Control:
	var host = Control.new(); host.set_anchors_preset(Control.PRESET_FULL_RECT); host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade = ColorRect.new(); shade.color = GS.SHADE; shade.set_anchors_preset(Control.PRESET_FULL_RECT); shade.offset_left = px(COL_W); shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.mouse_force_pass_scroll_events = false
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: _close_overlay())
	host.add_child(shade)
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", GS.column(k, left_at >= 0.0)); p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_bottom = 1.0
	if left_at >= 0.0: p.offset_left = px(left_at); p.offset_right = px(left_at + OVER_W)
	else: p.anchor_left = 1.0; p.anchor_right = 1.0; p.offset_left = -px(OVER_W); p.offset_right = 0
	var m = MarginContainer.new()
	for side in ["left", "right"]: m.add_theme_constant_override("margin_" + side, px(COL_PAD))
	m.add_theme_constant_override("margin_top", px(40)); m.add_theme_constant_override("margin_bottom", px(32))
	m.add_child(body); p.add_child(m); host.add_child(p)
	p.mouse_force_pass_scroll_events = false
	ModalFocus.attach(p)
	return host
func _over_head(kicker: String, kicker_col: Color, title: String) -> Control:
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 0)
	var h = row0(0); h.add_child(tl(kicker, 17, 24, kicker_col, GS.sheet_medium())); h.add_child(spacer())
	h.add_child(tbtn("Close", 17, 24, _close_overlay, "Esc"))
	v.add_child(h); v.add_child(gap(8))
	v.add_child(_sheet_name(title, 32, OVER_W - COL_PAD * 2) if kicker == "Nemesis" else _sheet_words(title, 28, GS.TEXT, true))
	return v
func _over_text(bb: String, size: float = 17, col: Color = GS.TEXT2) -> RichTextLabel:
	var r = rich(c(bb, col).replace("[b]", "[b][color=" + hexs(GS.TEXT) + "]").replace("[/b]", "[/color][/b]"), size)
	r.add_theme_font_override("normal_font", GS.sheet_body()); r.add_theme_font_override("bold_font", GS.sheet_medium())
	r.add_theme_constant_override("line_separation", px(3)); r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
func _over_scroll(v: VBoxContainer) -> ScrollContainer:
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(v); return sc
# The Dossier: everything the old long Nemesis block said (strengths, the patient or cruel text, the clock, the meeting rule,
# comeback, weaknesses, adaptations, lessons, earlier hunters), unchanged in wording, from View.nem_dossier.
func _dossier() -> Control:
	var N = View.nemesis(C); var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 0)
	if N.is_empty(): v.add_child(_over_head("Nemesis", GS.NEM, "No hunter")); return v
	v.add_child(_over_head("Nemesis", GS.NEM, N["full"])); v.add_child(gap(16))
	var top = row0(20); var tex = nem_portrait()
	if tex != null:
		var tr = TextureRect.new(); tr.texture = tex; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.custom_minimum_size = Vector2(px(120), px(120)); tr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; top.add_child(tr)
	var tv = VBoxContainer.new(); tv.add_theme_constant_override("separation", 0); tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; top.add_child(tv)
	tv.add_child(tl(N["fac_name"] + ((", scarred %dx" % N["scars"]) if N["scars"] > 0 else ""), 17, 24, GS.TEXT, GS.sheet_medium(), true))
	if N["persona_n"] != "": tv.add_child(para(N["persona_n"] + ": " + N["persona_d"], 17, 24, GS.TEXT2, OVER_W - COL_PAD * 2.0 - (140.0 if tex != null else 0.0), 3)[0])
	if not N["dead"]:
		tv.add_child(gap(8)); var cl = row0(10)
		cl.add_child(tl("Hunt clock", 17, 24, GS.TEXT2)); cl.add_child(GS.pips(k, float(N["clock"]), GS.NEM, 16.0, 6.0, 3.0, int(N["clock_max"])))
		cl.add_child(_baseline_row([[C.numstr(N["clock"]), font_num, 17, GS.TEXT], [0], ["/" + C.numstr(N["clock_max"]), font_num, 17, GS.TEXT2]], 24)); tv.add_child(cl)
	v.add_child(top); v.add_child(gap(24)); v.add_child(GS.rule(k)); v.add_child(gap(16))
	var body = VBoxContainer.new(); body.add_theme_constant_override("separation", px(12))
	for ln in View.nem_dossier(C):
		match ln[0]:
			"head": body.add_child(gap(4)); body.add_child(tl(str(ln[1]), 17, 24, GS.TEXT2, GS.sheet_medium()))
			"warn": body.add_child(_over_text(esc(ln[1]), 17, GS.TEXT))
			_: body.add_child(_over_text(_bb_safe(ln[1])))
	v.add_child(_over_scroll(body))
	return v
func _bb_safe(t: String) -> String:   # the view marks names with [b]; every other bracket in the words is escaped
	return esc(t).replace("[lb]b]", "[b]").replace("[lb]/b]", "[/b]")
# The Map key: what the marks mean, the danger pips, this sector (rival raiders, cores in range, Heat), your run (admiral,
# flagship aspect, protocols, salvage, the hold, the faction action), the controls, and the two switches the header used to
# carry (Map detail, Tips).
func _map_key() -> Control:
	var S = View.sector_notes(C); var RN = View.run_notes(C); var FA = View.faction_action(C)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", 0)
	v.add_child(_over_head("Sector map", GS.TEXT2, "Map key")); v.add_child(gap(16)); v.add_child(GS.rule(k)); v.add_child(gap(16))
	var body = VBoxContainer.new(); body.add_theme_constant_override("separation", px(8))
	var head = func(t: String): body.add_child(gap(8)); body.add_child(tl(t, 17, 24, GS.TEXT2, GS.sheet_medium()))
	var region = _region_key(View.header(C)["region"])
	if C.REGIONS.has(region):
		var place = row0(12); place.add_child(GS.region_emblem(region, k)); place.add_child(tl(C.REGIONS[region]["n"], 22, 40, GS.TEXT, GS.sheet_medium())); body.add_child(place)
		var places: Array = []; var names = {"graveyard": "wreck fields", "belt": "asteroid belts", "storm": "ion storms", "station": "stations", "planet": "planets"}
		for route in C.REGIONS[region]["route"]:
			if not places.has(names[route]): places.append(names[route])
		body.add_child(_over_text("Battles take place among " + ", ".join(PackedStringArray(places)) + ".", 17))
	body.add_child(tl("On the map", 17, 24, GS.TEXT2, GS.sheet_medium()))
	body.add_child(_key_mark("marker", "Your next jumps, numbered as in the route list. The filled one is picked."))
	body.add_child(_key_mark("ember", "A route you can fly now."))
	body.add_child(_key_mark("pale", "Every other route. Fainter: cut off. Flown routes are hidden."))
	body.add_child(_key_mark("nem", "The Nemesis meets you at this stop."))
	body.add_child(_over_text("Stops further on are smaller and darker. Point at any stop for its card: what it is, its danger, its reward and the route on from it.", 17))
	head.call("Stops")
	for icon_kind in GS.STOP_ICONS:
		var icon_row = row0(8); icon_row.add_child(GS.stop_key(icon_kind, k)); icon_row.add_child(tl(GS.STOP_ICONS[icon_kind], 17, 26, GS.TEXT))
		body.add_child(icon_row)
	var LEG = {"battle": "a fight, pays its reward", "elite": "veteran fleet, drops " + term("relic"), "shipyard": "buy, repair, upgrade", "drydock": View.KIND_NOTE["drydock"], "field": View.KIND_NOTE["field"], "event": "anything can happen", "boss": "ends the sector"}
	var st: Array = []
	for kk in C.NODE_INFO.keys(): st.append("[b]" + esc(C.NODE_INFO[kk]["n"]) + "[/b] " + esc(LEG.get(kk, "")))
	body.add_child(_over_text(". ".join(PackedStringArray(st)) + ".", 17))
	head.call("Danger against your fleet now")
	var dr = vbox(8)
	for i in 4:
		var it = row0(8); it.add_child(GS.pips(k, float(i + 1))); it.add_child(tl(Map3D.Intel.BANDS[i][1], 17, 24, GS.TEXT)); dr.add_child(it)
	body.add_child(dr)
	body.add_child(_over_text("An estimate of the enemy's strength against the fleet you have now. It moves as your fleet is hurt or grows.", 17))
	head.call("This sector")
	body.add_child(_over_text("[b]" + esc(S["holder"]) + "[/b] hold it. " + esc(S["holder_blurb"]), 17))
	if S["cond_n"] != "": body.add_child(_over_text("[b]" + esc(S["cond_n"]) + "[/b] " + esc(S["cond_d"]), 17))
	if S["rivals"].size() > 0: body.add_child(_over_text("[b]Rival raiders[/b] " + esc(", ".join(PackedStringArray(S["rivals"]))) + ". About one ordinary fight in five comes from a rival outside the sector's main enemy; its row and its card say so.", 17))
	var cs: Array = []
	for p in S["cores"]: cs.append(esc(p["short"]))
	body.add_child(_over_text("[b]" + term("patrons", true) + " in range[/b] " + ", ".join(PackedStringArray(cs)) + ". Win at a stop carrying a " + term("patron") + "'s " + term("sigil") + " and that " + term("patron") + " offers a " + term("boon") + ".", 17))
	if S["heat"].size() > 0:
		var hs: Array = []
		for hh in S["heat"]: hs.append("[b]" + esc(hh["n"]) + "[/b] " + esc(str(hh["d"]).trim_suffix(".")))
		body.add_child(_over_text("[b]Threat " + C.numstr(S["heat_level"]) + "[/b] " + "; ".join(PackedStringArray(hs)) + ".", 17))
	head.call("Your run")
	var A = RN["admiral"]; var HH = View.header(C)
	body.add_child(_over_text("[b]" + esc(_admiral_title(A["id"])) + "[/b] " + esc(A["doc"].to_lower()) + ". Sector " + HH["sector_roman"] + " of III, " + str(HH["fights"]) + " fight" + ("" if HH["fights"] == 1 else "s") + " won this run.", 17))
	if not RN["aspect"].is_empty(): body.add_child(_over_text("[b]Flagship " + esc(RN["aspect"]["ship"]) + ": " + esc(RN["aspect"]["n"]) + "[/b] " + esc(RN["aspect"]["d"]), 17))
	if not FA.is_empty(): body.add_child(_over_text("[b]Faction action: " + esc(FA["n"]) + "[/b] " + esc(FA["d"]) + " " + esc("Used this sector." if FA["used"] else FA["cost"] + "."), 17))
	if RN["boons"].size() > 0:
		for b in RN["boons"]: body.add_child(_over_text("[b]" + esc(b["n"]) + "[/b] " + esc(b["tier"]) + ". " + esc(b["d"]), 17))
	else: body.add_child(_over_text("[b]" + term("boons", true) + "[/b] None yet. Win at a stop carrying a " + term("patron") + "'s " + term("sigil") + " to earn one.", 17))
	if RN["relics"].size() > 0:
		for r in RN["relics"]: body.add_child(_over_text("[b]" + esc(r["n"]) + "[/b] " + esc(r["d"]), 17))
	else: body.add_child(_over_text("[b]" + term("relics", true) + "[/b] None yet. Elite fleets and flagships carry it.", 17))
	if RN["hold"] > 0: body.add_child(_over_text(str(RN["hold"]) + " refit" + ("s" if RN["hold"] > 1 else "") + " in the hold.", 17))
	head.call("Controls")
	body.add_child(_over_text("Click a route, press its number, or point at its stop to pick it. Enter, the jump button or a double click flies it; click or Space skips the flight. Scroll to zoom, right-drag or WASD to pan, Home to reset.", 17))
	head.call("Settings")
	var sr = row0(32)
	sr.add_child(tbtn("Map detail: " + ("High" if map_quality != "low" else "Low"), 17, 24, func(): set_map_quality("low" if map_quality != "low" else "high"),
		"High draws the full star system. Low draws fewer stars, clouds and debris\nfor a smoother map on slower machines."))
	sr.add_child(tbtn("Tips: " + ("off" if CampaignTips.is_off() else "on"), 17, 24, _toggle_tips, "Teaching tips on the campaign screens."))
	body.add_child(sr)
	v.add_child(_over_scroll(body))
	return v
func _region_key(region_name: String) -> String:
	for key in C.REGIONS:
		if C.REGIONS[key]["n"] == region_name: return key
	return ""
func _toggle_tips() -> void:
	teaching.toggle(); _dirty = true
func _key_mark(kind: String, text: String) -> Control:   # one row of the key: the mark as the map draws it, then what it means
	var h = row0(16)
	var m = Control.new(); m.custom_minimum_size = Vector2(px(40), px(34)); m.mouse_filter = Control.MOUSE_FILTER_IGNORE; m.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	m.draw.connect(func():
		var ctr = m.size * 0.5
		if kind == "marker": GS.marker(m, ctr, k, "1", font_num_b, true)
		elif kind == "ember": m.draw_line(Vector2(0, ctr.y), Vector2(m.size.x, ctr.y), GS.MAP_EMBER, max(2.0, px(2.5)), false)
		elif kind == "pale": m.draw_line(Vector2(0, ctr.y), Vector2(m.size.x, ctr.y), Color(GS.TEXT, GS.PALE), max(1.0, px(1)), false)
		else: GS.diamond(m, ctr, px(5), GS.NEM))
	h.add_child(m)
	var p = para(text, 17, 24, GS.TEXT2, OVER_W - COL_PAD * 2.0 - 56.0, 2); p[0].size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(p[0])
	return h
func _reward_label(rw) -> String: return View.reward_label(C, rw)
# The Nemesis face (godot/portraits, R42): his stored portrait id (nem_<faction>_<1..6>) with one overlay per scar he carries, framed red-black.
# The run stores how each scar was made (scarKinds: fled, big, cut, flay, melt, dark, blast, tidal); this maps them onto the portrait set's
# overlays his faction can take (burn for blasts and melts, the faction's own kinds for the rest). Presentation only, no random draws.
# He is read through the view (C.nemRead): drawing his face never resolves or creates him.
const SCAR_BURN := ["big", "melt", "blast", "fled"]
var _nem_key := ""
var _nem_tex: Texture2D = null
func nem_portrait() -> Texture2D:
	var N = View.nem(C) if C != null and C.RUN != null else null
	if not C.jt(N) or not ResourceLoader.exists("res://portraits/portraits.gd"): return null
	var idx = 1
	var pid = str(N.get("portrait", ""))
	if pid.begins_with("nem_") and pid.get_slice("_", pid.get_slice_count("_") - 1).is_valid_int(): idx = int(pid.get_slice("_", pid.get_slice_count("_") - 1))
	else:   # an older run without a stored portrait: one picked from his name
		var h = 0
		for ch in str(N["name"]).to_utf8_buffer(): h = (h * 31 + ch) % 1000003
		idx = 1 + h % 6
	var Pt = load("res://portraits/portraits.gd")
	var sc = Pt._scars().get("kinds", {})
	var own = []
	for k in ["eye", "cyber", "carapace", "porcelain", "machine"]:
		if sc.get(k, []).has(N["fac"]): own.append(k)
	var causes = N.get("scarKinds") if N.get("scarKinds") is Array else []
	if causes.is_empty():
		for i in range(int(C.z0(N.get("scars")))): causes.append("blast")
	var scars = []; var j = 0
	for cs in causes:
		if cs in SCAR_BURN or own.is_empty(): scars.append("burn")
		else:
			scars.append(own[j % own.size()]); j += 1
	var key = str(N["fac"]) + ":" + str(idx) + ":" + ",".join(PackedStringArray(scars))
	if key != _nem_key:
		_nem_key = key; _nem_tex = Pt.nemesis(str(N["fac"]), idx, scars)
		if _nem_tex == null: _nem_tex = Crest.faction_texture(str(N["fac"]))   # the portraits helper's faction crest
		if _nem_tex == null: _nem_tex = _fac_crest(Pt, str(N["fac"]))   # pools held back (Ithar, Deathless until the new looks are signed off): his faction's crest
	return _nem_tex
func _fac_crest(Pt, fac: String) -> Texture2D:   # the crest of the first admiral of a faction (there are no faction crests of their own)
	for id in C.ADMIRALS:
		if str(C.ADMIRALS[id].get("fac", "")) == fac:
			var t = Pt.crest(str(id))
			if t != null: return t
	return null

# ---------------- ship cards, fleet, shipyard ----------------
func _ship_card(s: Dictionary, refit: bool, extra: Array = []) -> Control:
	var t = C.HULLS[s["tpl"]]; var d = C.derive(s); var cap = s["cap"]
	var cv = card(false, 330); var v = cv[1]
	var r0 = hbox(); var name_label = lbl(s["name"], 20, BONE, font_semi); name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r0.add_child(name_label); r0.add_child(lbl("MK " + C.roman(s["mk"]), 17, BONE2, font_caps, false)); v.add_child(r0)
	v.add_child(lbl(t["n"], 18, BONE2))
	if C.jt(s.get("ripped")): v.add_child(lbl("Captured prize, links ripped out.", 17, VERD))
	var r1 = hbox(); r1.add_child(lbl("Hull " + C.hull_text(s["hp"]) + "/" + C.hull_text(d["maxHp"]), 17)); r1.add_child(spacer()); r1.add_child(lbl(C.numstr(t["cp"]) + " CP", 17, BONE3, null, false)); v.add_child(r1)
	v.add_child(bar(float(s["hp"]) / float(d["maxHp"])))
	v.add_child(rich("[b]" + c("Shields", BONE2) + "[/b] " + C.numstr(d["shMax"]) + ", +" + C.numstr(d["regen"]) + "/turn   [b]" + c("Armor", BONE2) + "[/b] " + C.pct(d["armor"]) + "\n[b]" + c("Speed", BONE2) + "[/b] " + C.numstr(d["speed"]) + "   [b]" + c("Turns", BONE2) + "[/b] " + C.numstr(d["turns"]) + "   [b]" + c("Evasion", BONE2) + "[/b] " + C.numstr(d["ev"]), 17))
	if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]): v.add_child(rich(c(esc(C.ABILITIES[t["ab"]]["n"]) + ".", VERD) + " " + c(esc(C.ABILITIES[t["ab"]]["d"]), BONE3), 17))
	for w in d["weapons"]:
		var arc = "Turret" if w["arc"] == "T" else str(C.ARC_NAME.get(w["arc"], w["arc"]))
		v.add_child(lbl(str(w["n"]) + "  " + arc + "  " + C.numstr(w["shots"]) + "×" + C.numstr(w["dmg"]) + ", range " + C.numstr(w["r"]) + ((", reload " + C.numstr(w["cd"])) if C.jt(w.get("cd")) else ""), 17, BONE3))
	var sect = vbox(4); sect.add_child(HSeparator.new())
	sect.add_child(lbl(C.rankName(cap) + " " + str(cap["name"]), 18, BONE, font_semi))
	var nx = C.RANK_XP[int(cap["rank"]) + 1] if int(cap["rank"]) + 1 < C.RANK_XP.size() else null
	if nx != null:
		var nxt = cap.duplicate(); nxt["rank"] = float(cap["rank"]) + 1
		sect.add_child(lbl(C.numstr(cap["xp"]) + "/" + C.numstr(nx) + " experience to " + C.rankName(nxt), 17, BONE3))
	else: sect.add_child(lbl(C.numstr(cap["xp"]) + " experience, highest rank", 17, BONE3))
	if cap["perks"].size() > 0:
		var pf = flow(4)
		for p in cap["perks"]:
			var pl = lbl(str(C.PERKS[p]["n"]), 17, VERD, null, false); pl.tooltip_text = str(C.PERKS[p]["d"]); pl.mouse_filter = Control.MOUSE_FILTER_PASS; pf.add_child(pl)
		sect.add_child(pf)
	else: sect.add_child(lbl("No perks yet.", 17, BONE3))
	add(sect, abtn("Choose promotion perk", "promote", s["uid"], true, true))
	v.add_child(sect)
	var rs = vbox(4); rs.add_child(HSeparator.new()); rs.add_child(sec_head("Refits"))
	for i in range(int(C.z0(t.get("slots")))):   # R1: hulls without refit slots (sector flagships) show none
		if i < s["mods"].size() and C.jt(s["mods"][i]):
			var m = s["mods"][i]; var rr = hbox(6)
			rr.add_child(rich("[b]" + esc(C.modName(m)) + "[/b] " + c(esc(C.MODULES[m]["d"]), BONE3), 17))
			if refit: add(rr, abtn("Remove", "unequip", s["uid"] + ":" + str(i), false, true))
			rs.add_child(rr)
		else: rs.add_child(lbl("Empty refit slot", 17, BONE3))
	v.add_child(rs)
	if extra.size() > 0:
		var ex = flow(6)
		for b in extra: add(ex, b)
		v.add_child(HSeparator.new()); v.add_child(ex)
	return cv[0]
const FleetManifest = preload("res://ui/campaign/fleet_manifest.gd")
var fleet_manifest: Control
var fleet_state := {"uid": "", "mode": "", "held": {}}
var _fleet_run = null
func _fleet(d: Dictionary) -> Control:
	if not is_same(_fleet_run, C.RUN):
		_fleet_run = C.RUN; fleet_state = {"uid": "", "mode": "", "held": {}}
	fleet_manifest = FleetManifest.new(); fleet_manifest.setup(self, d, fleet_state)
	return fleet_manifest
# Issue 1449: a "Full specs" link under a shipyard card opens the full specification (FleetManifest.spec_lines) in place.
# Open drawers are UI state only (no campaign action), so the card stays short until the player asks.
var spec_open := {}
# The short card lines read the same derived ship as the drawer, so the card and its specs never disagree (faction weapon
# names, fleet-wide bonuses): CP, hull, shields, speed, turns, guns with arcs, the ability name.
func _hull_summary(parent: VBoxContainer, ship: Dictionary, key: String) -> void:
	var t = C.HULLS[ship["tpl"]]; var d = C.derive(ship)
	parent.add_child(lbl(C.numstr(t["cp"]) + " CP. Hull " + C.hull_text(d["maxHp"]) + ", shields " + C.numstr(d["shMax"]) + ", speed " + C.numstr(d["speed"]) + ", turns " + C.numstr(d["turns"]) + ".", 17, BONE2))
	var ws = []
	for w in d["weapons"]: ws.append(str(w["n"]) + " (" + ("turret" if w["arc"] == "T" else str(C.ARC_NAME.get(w["arc"], w["arc"])).to_lower()) + ")")
	parent.add_child(lbl(", ".join(PackedStringArray(ws)) + ".", 17, BONE2))
	parent.add_child(lbl("Ability: " + (str(C.ABILITIES[t["ab"]]["n"]) if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]) else "none"), 17, BONE3))
	_spec_drawer(parent, ship, key)
func _spec_drawer(parent: VBoxContainer, ship: Dictionary, key: String) -> void:
	var open: bool = spec_open.get(key, false)
	var b = Button.new(); b.text = ("Hide specs" if open else "Full specs") + "  " + ("▴" if open else "▾"); b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.focus_mode = Control.FOCUS_ALL; b.add_theme_font_size_override("font_size", int(px(17)))
	b.add_theme_color_override("font_color", BLUE); b.add_theme_color_override("font_hover_color", BONE)
	b.set_meta("spec_key", key)
	parent.add_child(b)
	var box = vbox(3); box.visible = open; parent.add_child(box)
	b.pressed.connect(func():
		spec_open[key] = not spec_open.get(key, false); box.visible = spec_open[key]
		b.text = ("Hide specs" if box.visible else "Full specs") + "  " + ("▴" if box.visible else "▾"))
	for line in FleetManifest.spec_lines(C, ship):
		match line["k"]:
			"shield": box.add_child(lbl(line["t"], 17, GS.GLACIER))
			"captain": box.add_child(lbl(line["t"], 17, VERD))
			"ability": box.add_child(lbl("Ability: " + str(line["t"]), 17, BONE, font_semi))
			"ability_d": box.add_child(lbl(line["t"], 17, BONE2))
			"weapon": box.add_child(lbl(line["t"], 17, BONE, font_semi))
			_: box.add_child(lbl(line["t"], 17, BONE2))
func _shipyard() -> Control:
	var v = vbox(10); var R = C.RUN; var n = C.page["data"]["node"]; var st = n["stock"]; var pm = C.priceMult(); var cp = C.fleetCP()
	var head = hbox(); head.add_child(gothic("Shipyard")); head.add_child(spacer())
	var hw = " biomass" if C.hullKey() == "bio" else ""   # issue 1178: Chorus hull work is paid in biomass
	if hw != "":
		head.add_child(_readout("Biomass", C.numstr(C.z0(R.get("bio"))), BONE, true)); var gb = Control.new(); gb.custom_minimum_size.x = px(28); head.add_child(gb)
	head.add_child(_readout("Credits", C.numstr(R["credits"]), BONE, true)); var gp = Control.new(); gp.custom_minimum_size.x = px(28); head.add_child(gp); head.add_child(_readout("Command points", C.numstr(cp) + "/" + C.numstr(R["cpCap"]), BONE, true))
	var rb = abtn("Refits", "yardFleet")
	if rb != null: rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER; head.add_child(rb)
	v.add_child(head)   # Leave shipyard is the finishing action, fixed at the bottom right (_page_finish)
	if hw != "": v.add_child(lbl("The Chorus regrow with biomass: repairs, new hulls and Marks are paid in biomass. Refits, upgrade tracks, protocol rerolls and the late market take biomass first, then credits.", 18, VERD))
	v.add_child(lbl("Repairs cost %s per 2 hull, rounded up. A Mark upgrade adds 20%% hull and shields and 15%% damage. New hulls come with a fresh %s." % [(("1" if pm == 1.0 else C.numstr(snappedf(pm, 0.0001))) + (hw if hw != "" else (" credit" if pm == 1.0 else " credits"))), str(C.CAPTAINS.get(str(R["fac"]), C.CAPTAINS["voidsworn"])["ranks"][0]).to_lower()], 18, BONE2))
	var allMiss = 0.0
	for s in R["fleet"]: allMiss += float(C.derive(s)["maxHp"]) - float(s["hp"])
	_yard_bar = abtn(("Repair entire fleet for " + C.numstr(ceil(allMiss / 2.0 * pm)) + hw) if allMiss > 0 else "Fleet fully repaired", "repairAll")   # the teaching card keeps off this bar
	add(v, _yard_bar)
	var cores = C.or_(R.get("cores"), [])
	if not cores.is_empty():   # issue 1178: Eclipse core recovery
		v.add_child(sec_head("Recovered cores"))
		v.add_child(lbl("Each core regrows its ship at Mk I, full hull, no refits.", 17, BONE3))
		var crow = flow(8)
		for i in range(cores.size()):
			var cc = card(false, 320)
			cc[1].add_child(rich("[b]" + esc(C.HULLS[cores[i]]["n"]) + "[/b]", 20))
			_hull_summary(cc[1], FleetManifest.preview_ship(C, cores[i]), "core:" + str(i))
			add(cc[1], abtn("Regrow the " + str(C.HULLS[cores[i]]["n"]) + " for " + C.numstr(C.coreCost(cores[i])), "restoreCore", i))
			crow.add_child(cc[0])
		v.add_child(crow)
	if st.get("late") is Dictionary:   # issue 1178: the Sector 3 market
		v.add_child(sec_head("Late market"))
		v.add_child(lbl("Sector 3 yards sell whatever the war left behind: salvage and room for one more ship.", 17, BONE3))
		var lm = flow()
		for o in C.lateShopOffers():
			var lc = card(false, 300)
			if o["kind"] == "relic":
				lc[1].add_child(lbl(C.relicName(o["r"]), 20, BONE, font_semi)); lc[1].add_child(lbl(C.relicText(o["r"]), 18, BONE2))
			else:
				lc[1].add_child(lbl("Command expansion", 20, BONE, font_semi)); lc[1].add_child(lbl("+1 command point for the rest of the run (at most " + C.numstr(C.TB["LATE_SHOP"]["cpMax"]) + " a run).", 18, BONE2))
			if C.jt(o["done"]): lc[1].add_child(lbl("Bought", 18, VERD))
			elif C.jt(o.get("full")): lc[1].add_child(lbl("Already at the limit", 18, BONE3))
			else: add(lc[1], abtn("Buy for " + C.numstr(o["cost"]) + C.shopWord(o["cost"]), "lateBuy", o["id"]))
			lm.add_child(lc[0])
		v.add_child(lm)
	var cards = flow()
	for s in R["fleet"]:
		var d = C.derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var rc = ceil(miss / 2.0 * pm); var mc = C.mkCost(s); var sell = C.sellValue(s)   # R1 (TXT-8): what the button pays; hulls without a shop price too
		var ex = [abtn(("Repair " + C.numstr(miss) + " for " + C.numstr(rc) + hw) if miss > 0 else "Fully repaired", "repair", s["uid"], false, true),
			abtn(("Mk " + C.roman(float(s["mk"]) + 1) + " for " + C.numstr(mc) + hw) if float(s["mk"]) < 3 else "Max Mark", "upgradeMk", s["uid"], false, true),
			abtn("Decommission (+" + C.numstr(sell) + hw + ")", "sellShip", s["uid"], false, true)]
		cards.add_child(_ship_card(s, false, ex))
	v.add_child(cards)
	v.add_child(sec_head("Hulls for sale"))
	var hs = flow()
	for h in st["hulls"]:
		var t = C.HULLS[h]; var cost = C.jsround(float(t["cost"]) * pm); var fits = cp + float(t["cp"]) <= float(R["cpCap"])
		var uniq = C.jt(t.get("unique")) and R["fleet"].any(func(s): return s["tpl"] == h)
		var cv = card(false, 320); var cvv = cv[1]
		cvv.add_child(rich("[b]" + esc(t["n"]) + "[/b]" + (" " + c("Variant", VERD) if C.jt(t.get("variant")) else ""), 20))
		if C.jt(t.get("variant")): cvv.add_child(lbl(C.HULL_VARIANTS[t["variant"]]["d"], 17, VERD))
		_hull_summary(cvv, FleetManifest.preview_ship(C, h), "yard:" + str(h))
		var fr = hbox(); add(fr, abtn("Buy for " + C.numstr(cost) + hw, "buyHull", h))
		if not fits: fr.add_child(lbl("Not enough command points", 17, BONE3, null, false))
		elif uniq: fr.add_child(lbl("Only one allowed", 17, BONE3, null, false))
		cvv.add_child(fr); hs.add_child(cv[0])
	v.add_child(hs)
	if st.get("cap") is Array and not st["cap"].is_empty():
		v.add_child(sec_head("Captured hulls"))
		v.add_child(lbl("Prizes taken from the Meridian Directorate and Eclipse, refitted along the Cinder Line. Their links are ripped out: no synchronized fire, no Archive restore. Sold at Crusade prices.", 17, BONE3))
		var cs = flow()
		for h in st["cap"]:
			var t2 = C.HULLS[h]; var cost2 = C.capturedHullPrice(t2); var fits2 = cp + float(t2["cp"]) <= float(R["cpCap"])
			var cv3 = card(false, 320); var cvv3 = cv3[1]
			cvv3.add_child(rich("[b]" + esc(t2["n"]) + "[/b]", 20))
			cvv3.add_child(lbl("Captured prize, links ripped out.", 17, VERD))
			_hull_summary(cvv3, FleetManifest.preview_ship(C, h, true), "cap:" + str(h))
			var fr2 = hbox(); add(fr2, abtn("Buy for " + C.numstr(cost2) + hw, "buyHull", h))
			if not fits2: fr2.add_child(lbl("Not enough command points", 17, BONE3, null, false))
			cvv3.add_child(fr2); cs.add_child(cv3[0])
		v.add_child(cs)
	v.add_child(sec_head("Refits for sale"))
	var ms = flow()
	for i in range(st["mods"].size()):
		var m = st["mods"][i]; var cv2 = card(false, 300)
		cv2[1].add_child(lbl(C.modName(m), 20, BONE, font_semi)); cv2[1].add_child(lbl(C.MODULES[m]["d"], 18, BONE2))
		if C._has_num(st["sold"], i): cv2[1].add_child(lbl("Bought", 18, VERD))
		else: add(cv2[1], abtn("Buy for " + C.numstr(C.jsround(float(C.MODULES[m]["cost"]) * pm)) + C.shopWord(C.jsround(float(C.MODULES[m]["cost"]) * pm)), "buyMod", i))
		ms.add_child(cv2[0])
	v.add_child(ms)
	v.add_child(sec_head("Class refits"))
	v.add_child(lbl("A class refit upgrades every ship of that class you own now or later: +6% hull and +6% damage per level, up to " + C.numstr(C.CLASS_TRACK_MAX) + ".", 17, BONE3))
	var tr = flow(8)
	for cls in C.fleetClasses():
		var lv = int(C.classTrack(cls)); var mx = lv >= int(C.CLASS_TRACK_MAX)
		add(tr, abtn(C.clsName(cls) + " " + "●".repeat(lv) + "○".repeat(int(C.CLASS_TRACK_MAX) - lv) + " " + ("(full)" if mx else "for " + C.numstr(C.classTrackCost(cls)) + C.shopWord(C.classTrackCost(cls))), "buyTrack", cls))
	v.add_child(tr)
	return v

# ---------------- the battle page (stub battles; the game shell replaces it with the real battle) ----------------
func _battle_stub(d: Dictionary) -> Control:
	var cfg = d["cfg"]; var E = C.ENCOUNTERS.get(cfg.get("obj"), C.ENCOUNTERS["rout"])
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p = panel(GS.SHEET_HAIR, IRON, 24); p.custom_minimum_size.x = px(720); var v = vbox(10); p.add_child(v)
	var kind = "flagship battle" if cfg["kind"] == "boss" else (("elite " if cfg["kind"] == "elite" else "") + str(E["n"]).to_lower())
	v.add_child(lbl("Sector " + C.roman(C.RUN["sector"]) + ": " + kind + " against " + str(C.FACTIONS[cfg["fac"]]["n"]), 22, BONE, font_goth))
	v.add_child(lbl(("The sector flagship and its escort." if cfg["kind"] == "boss" else str(E["d"])), 17, BONE2))
	v.add_child(lbl("Test battle: the real battle scene plugs in here. Pick how this fight ends.", 17, BONE3))
	var row = flow(8)
	add(row, abtn("Win", "battle", "win", true)); add(row, abtn("Win, objective missed (half pay)", "battle", "partial")); add(row, abtn("Lose the fleet", "battle", "loss")); add(row, abtn("Retreat", "c3retreat"))
	v.add_child(row)
	cc.add_child(p); return cc

# ---------------- progression and help ----------------
func _legacy() -> Control:
	var v = vbox(12); var M = C.META; var st = M["stats"]
	# the heading beside the four numbers that carry between runs
	var head = hbox(32); v.add_child(head)
	var hcol = vbox(6); hcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL; head.add_child(hcol)
	hcol.add_child(Kit.heading("Progression", 44, k))
	var rb = ColorRect.new(); rb.color = GS.MAP_EMBER; rb.custom_minimum_size = Vector2(px(72), maxi(2, px(3))); rb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; rb.mouse_filter = Control.MOUSE_FILTER_IGNORE; hcol.add_child(rb)
	for r in [["Runs launched", C.numstr(st["runs"]), BONE], ["Deepest sector", C.numstr(C.z0(st.get("best"))), BONE], ["Runs won", C.numstr(st["wins"]), BONE], ["Renown", C.numstr(C.z0(M.get("renown"))), GS.MAP_EMBER]]:
		head.add_child(_readout(r[0], r[1], r[2], true))
	var tabs = hbox(6)
	for t in [["variants", "Hull variants"], ["legacy", "Legacy"], ["mastery", "Admiral mastery"], ["favour", "Core sync"], ["heat", "Threat"], ["fallen", "Hall of the fallen"]]:
		if _find(_acts, "progTab", t[0]).is_empty(): continue
		var tt = t[0]
		var tb = Kit.tab_button(t[1], k, C.prog_tab == tt, GS.MAP_EMBER, func(): _campaign_action("progTab", tt))
		tb.set_meta("act", "progTab"); tb.set_meta("arg", tt); tabs.add_child(tb)
	var stc = _story()
	if stc != null:   # story layer: the Career screen (records, medals, titles, history)
		tabs.add_child(Kit.tab_button("Career", k, false, GS.MAP_EMBER, func(): stc.open_career()))
	v.add_child(tabs)
	match C.prog_tab:
		"variants":
			v.add_child(rich(c("Spend renown to add a variant hull to your faction's shipyards. It sits beside the standard hull whenever that hull is in stock. ", BONE2) + c("You have " + C.numstr(C.z0(M.get("renown"))) + " renown.", BONE) + c(" Renown comes from every run: battles, elites, flagships and sectors reached, plus 10% per Threat level.", BONE2), 17))
			for f in C.favFirst():
				var vs = []
				for vid in C.HULL_VARIANTS.keys():
					if C.HULLS[C.HULL_VARIANTS[vid]["base"]].get("fac") == f: vs.append(vid)
				if vs.is_empty(): continue
				v.add_child(Kit.section(str(C.FACTIONS[f]["n"]), k))
				var cards = flow()
				for vid in vs:
					var hv = C.HULL_VARIANTS[vid]; var own = C.jt(M["variants"].get(vid)); var t = C.HULLS[vid]
					var cv = card(own, 320); cv[1].add_child(lbl(hv["n"], 20, BONE, font_semi)); cv[1].add_child(lbl("Variant of the " + str(C.HULLS[hv["base"]]["n"]), 17, BONE3)); cv[1].add_child(lbl(hv["d"], 18, BONE2))
					var ws = []
					for e in t["w"]: ws.append(str(C.W_[e[0]]["n"]) + " (" + ("turret" if e[1] == "T" else str(C.ARC_NAME.get(e[1], e[1])).to_lower()) + ")")
					cv[1].add_child(lbl(C.numstr(t["cp"]) + " CP. Hull " + C.hull_text(t["hp"]) + ", shields " + C.numstr(t["sh"]) + ", speed " + C.numstr(t["sp"]) + ". " + ", ".join(PackedStringArray(ws)) + ".", 17, BONE2))
					if own: cv[1].add_child(lbl("In your shipyards", 18, VERD))
					elif C.jt(hv.get("arc")): cv[1].add_child(lbl("Finish the " + str(C.FACTIONS[hv["arc"]]["n"]) + " story to unlock", 17, BONE3))
					else: add(cv[1], abtn("Unlock for " + C.numstr(hv["cost"]) + " renown", "buyVariant", vid))
					cards.add_child(cv[0])
				v.add_child(cards)
		"legacy":   # R1 (PROG-2): lasting unlocks bought with renown (campaign.gd legacyScreen lists the buyLegacy buttons)
			v.add_child(rich(c("Spend renown on lasting advantages for every later run. ", BONE2) + c("You have " + C.numstr(C.z0(M.get("renown"))) + " renown.", BONE), 17))
			var lc = flow()
			for id in C.LEGACY.keys():
				var u = C.LEGACY[id]; var own = C.jt(M["unlocked"].get(id)); var lock = C.jt(u.get("req")) and not C.jt(M["unlocked"].get(u["req"]))
				var cv = card(own, 300); cv[1].add_child(lbl(u["n"], 20, BONE, font_semi)); cv[1].add_child(lbl(u.get("group", ""), 17, BONE3)); cv[1].add_child(lbl(u["d"], 18, BONE2))
				if own: cv[1].add_child(lbl("Unlocked", 18, VERD))
				elif lock: cv[1].add_child(lbl("Needs " + str(C.LEGACY[u["req"]]["n"]) + " first", 17, BONE3))
				else: add(cv[1], abtn("Unlock for " + C.numstr(u["cost"]) + " renown", "buyLegacy", id))
				lc.add_child(cv[0])
			v.add_child(lc)
		"mastery":
			v.add_child(lbl("Every run levels up the admiral who led it: 1 per battle won, 2 per elite, 5 per flagship and 10 for a victory.", 17, BONE2))
			var mc = flow()
			for i in range(1, C.MASTERY_PERKS.size()):
				var cv = card(false, 300); cv[1].add_child(lbl("Level " + str(i) + ": " + str(C.MASTERY_PERKS[i]["n"]), 19, BONE, font_semi)); cv[1].add_child(lbl(C.MASTERY_PERKS[i]["d"], 18, BONE2)); cv[1].add_child(lbl(C.numstr(C.MASTERY_XP[i]) + " mastery", 17, BONE3)); mc.add_child(cv[0])
			var cv_m = card(false, 300); cv_m[1].add_child(lbl("Capstone mastery", 19, BONE, font_semi)); cv_m[1].add_child(lbl("Choose a Command evolution at level 8 (230 XP), then keep deepening it at 320, 440 and 600 XP.", 18, BONE2)); mc.add_child(cv_m[0])
			v.add_child(mc)
			for f in C.favFirst():
				v.add_child(Kit.section(str(C.FACTIONS[f]["n"]), k)); var ac = flow()
				for id in C.ADMIRALS.keys():
					if C.or_(C.ADMIRALS[id].get("fac"), "voidsworn") != f: continue
					var cv2 = card(false, 260); cv2[1].add_child(lbl(C.ADMIRALS[id]["n"], 19, BONE, font_semi)); cv2[1].add_child(lbl(C.ADMIRALS[id]["doc"], 17, BONE2)); cv2[1].add_child(_mastery_bar(id))
					if C.LINEAGE_TREES.has(id): add(cv2[1], abtn("View lineage tree", "lineage", id))
					ac.add_child(cv2[0])
				v.add_child(ac)
		"favour":
			v.add_child(lbl("Every protocol you take raises your sync with that core (rare protocols count double, epic triple).", 17, BONE2))
			var fc = flow()
			for i in range(1, C.FAVOUR_TIERS.size()):
				var cv = card(false, 300); cv[1].add_child(rich("[b]" + esc(C.FAVOUR_TIERS[i]["n"]) + "[/b] " + c(C.numstr(C.FAVOUR_TIERS[i]["at"]) + "+", BONE3), 19)); cv[1].add_child(lbl(C.FAVOUR_TIERS[i].get("d", ""), 18, BONE2)); fc.add_child(cv[0])
			v.add_child(fc)
			for p in C.PATRONS.keys():
				var P = C.PATRONS[p]; var f = C.favourOf(p); var t = C.favourTier(p); var nx = C.FAVOUR_TIERS[t + 1] if t + 1 < C.FAVOUR_TIERS.size() else null
				var r = hbox(); r.add_child(lbl(P["glyph"], 18, Color(P["col"]), font_semi, false)); r.add_child(rich("[b]" + esc(P["n"]) + "[/b]\n" + c(esc(P["theme"]), BONE3), 17))
				r.add_child(rich("[right][b]" + c(esc(C.FAVOUR_TIERS[t]["n"]), Color(P["col"])) + "[/b]\n" + c(C.numstr(f) + ((" / " + C.numstr(nx["at"])) if nx != null else ""), BONE3) + "[/right]", 17)); v.add_child(r)
		"heat":
			var heat_open = C.heatUnlocked()
			v.add_child(lbl("Threat is open. Pick rules on the admiral screen before a run; each level adds 10% renown." if heat_open else "Lose a run to open Threat.", 17, BONE2))
			var hc = flow()
			for kk in C.HEAT.keys():
				var cv = card(false, 300); cv[1].add_child(rich("[b]" + esc(C.HEAT[kk]["n"]) + "[/b] " + c("+" + C.numstr(C.HEAT[kk]["w"]), BONE3), 19)); cv[1].add_child(lbl(C.HEAT[kk]["d"], 18, BONE2)); hc.add_child(cv[0])
			v.add_child(hc); v.add_child(Kit.section("Best Threat won", k))
			var bc = flow()
			for f in C.RUN_FACTIONS:
				var hb = float(C.z0(M["heatBest"].get(f))); var won = C.or_(st.get("wonFacs"), []).has(f)
				var cv = card(false, 220); cv[1].add_child(lbl(C.FACTIONS[f]["n"], 18, BONE, font_semi)); cv[1].add_child(lbl(("Threat " + C.numstr(hb)) if hb > 0 else ("Won at Threat 0" if won else "Not yet won"), 18, BONE if hb > 0 else BONE3)); bc.add_child(cv[0])
			v.add_child(bc)
		"fallen":
			var fallen = M["fallen"].slice(max(0, M["fallen"].size() - 40)); fallen.reverse()
			if fallen.is_empty(): v.add_child(lbl("No captain has died yet.", 17, BONE2))
			else:
				var fc2 = flow()
				for f in fallen:
					var cv = card(false, 260); cv[1].add_child(lbl(f["name"], 18, BONE, font_semi)); cv[1].add_child(lbl(C.rankName(f) + ", " + str(f.get("ship", "")), 17, BONE2)); cv[1].add_child(lbl("Lost in sector " + C.roman(f.get("sector", 1)), 17, BONE3)); fc2.add_child(cv[0])
				v.add_child(fc2)
	return v   # Back sits in the page's fixed bar (_kit_page)
const HELP := [
	["", "Embers of the Hollow Sun is a hex fleet-tactics roguelite. Lead your ships across three contested sectors toward the Hollow Sun, fighting a sector flagship at the end of each map. Any hull or captain lost in battle stays lost for the rest of the run."],
	["", "Between runs, check Progression on the title screen: spend renown to unlock hull variants and permanent legacy upgrades, level up admirals to open branch skills and Command evolutions, and raise sync with Lattice cores so they offer rarer protocols (and eventually a starting gift). Finishing your first run unlocks Threat modifiers for extra difficulty and renown."],
	["Your turn", "Each ship moves, turns, and then fires its ready weapons once per round. Most hulls cannot move after firing (Glasswright ships and the Slip the Net protocol are the exceptions). Forward hexes cost 1 movement; turning 60° costs 1 movement and uses a turn charge (capital ships only turn once per round, so plan headings early). Press Q or E to turn the ghost in place; the turn happens when you commit."],
	["", "Attitude thrusters keep your formation flexible: ships can sideslip diagonally or reverse one hex without rotating (2 movement each, or a slow hull's entire move). Ships can also pass above or below asteroids, wrecks, and enemy hulls for +1 movement, though they cannot end their move on an occupied hex. Each faction bends one thruster rule (check the Helm readout)."],
	["", "Click an enemy outside current weapon range to plot the cleanest burn into firing range (the ghost shows the stop); click it again or press Enter to burn and fire on arrival."],
	["", "Keep moving. Stationary ships take +10 enemy aim, while moving 3+ hexes grants -5 to be hit. Port and starboard flank batteries hit 10% harder after moving 2+ hexes (45% harder for Sunward Crusade)."],
	["Firing arcs", "Weapons only fire inside their mounted arc: fore guns cover a 120° front cone, port and starboard flank mounts cover 120° to each side, and turrets track 360°. Colored hex overlays show weapon reach (amber fore, teal flanks). Click a target to aim every bearing weapon at it (from the ghost when a move is planned), or press 1 to 6 first to aim one gun alone; nothing fires until you commit."],
	["Shields and flanking", "Each shielded ship shares one shield pool across four quadrants (fore catches the highest share, aft the least). Repeated hits on one side route extra power at a drain penalty, and once the pool empties, shields drop everywhere at once. Shields recharge at the start of your turn. Aft hits halve armor and boost crit odds. Lances and bombers pierce shields, ion cannons strip pools fast, and null cannons cut through both shields and armor."],
	["Different fights", "Every battle stop shows its objective on the star map: Engagement and Ambush end when one fleet breaks; Hold the station defends an ally through round 6; Hunt destroys a fleeing flagship before round 6; Intercept stops escaping transports; Breakthrough gets half your fleet onto the far jump edge; Relay holds the central beacon unopposed for 3 rounds; and Decapitation breaks the enemy fleet by killing its flagship."],
	["", "Some battles shift mid-fight with jump-in reinforcements or a solar flare that knocks shields offline for a round. You always receive one full round of warning."],
	["Brace, abilities and Command", "Brace skips firing to cut incoming hull damage by 40% until your next turn. Ramming requires a clear straight line ahead and deals heavier damage with longer run-ups (capped at 40% of a healthy hull without protocols). Boarding an adjacent enemy can capture it outright; enemy boarders can cripple your systems, never steal your ships. Carriers start with squadrons already launched, replace one lost wing per round from spares, and let you order wings directly to Strike or Guard. Once per battle, trigger your admiral's Command; holding it until round 3 (or losing a ship) raises it to full power."],
	["Cores, protocols and your flagship", "Four of the six Lattice cores are in range each run. Winning battles carrying a core's signal lets you pick one of three run-long protocols (Common, Rare, or Epic). Mixing protocols from two cores unlocks Duo protocols, and every run opens by choosing a flagship Refit."],
	["Between battles", "Hull damage persists between battles. Dock at shipyards to repair, buy hulls, fit modules, or upgrade ship Marks. Captains earn XP and pick perks on promotion, while Salvage grants permanent fleet-wide bonuses for the run."],
	["Keys", "Plan each ship's turn on its ghost: click a blue hex to move it, Q/E to turn it, click enemies to aim. Enter (or a second click on the hex or a target) plays the plan, Space ends the ship. Tab next ship, Backspace take back the plan's last step (with no plan, the last move, until the ship fires), 1 to 6 aim one weapon, B brace, V firing arcs, Esc clears the plan. On campaign screens: Tab and the arrow keys move between buttons, Enter presses, Esc closes a dialog, 1 to 9 pick a dialog's choices."]]
# How to play: an index of the sections on the left (a link scrolls to its section), the text in one readable column.
func _help() -> Control:
	var outer = hbox(40)
	var idx = vbox(4); idx.custom_minimum_size.x = px(240); idx.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; outer.add_child(idx)
	var v = vbox(10); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; outer.add_child(v)
	v.add_child(Kit.heading("How to play", 44, k))
	var rb = ColorRect.new(); rb.color = GS.MAP_EMBER; rb.custom_minimum_size = Vector2(px(72), maxi(2, px(3))); rb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; rb.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.add_child(rb)
	idx.add_child(Kit.section("Sections", k))
	var first = Kit.link("The run", k, Callable(), 18); first.alignment = HORIZONTAL_ALIGNMENT_LEFT; idx.add_child(first)
	var text_w = (minf(get_viewport().get_visible_rect().size.x - px(DESK_PAD) * 2, float(px(1120))) - px(280)) / k
	var anchors = []
	for h in HELP:
		if h[0] != "":
			var sh = Kit.section(str(h[0]), k); v.add_child(sh)
			var lk = Kit.link(str(h[0]), k, Callable(), 18); lk.alignment = HORIZONTAL_ALIGNMENT_LEFT; idx.add_child(lk); anchors.append([lk, sh])
		var l = Kit.label(str(h[1]), 18, k, GS.TEXT2, null, true, minf(text_w, 820.0)); l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_child(l)
	first.pressed.connect(func(): if _kit_scroll != null: _kit_scroll.scroll_vertical = 0)
	for a in anchors:
		var target: Control = a[1]
		(a[0] as Button).pressed.connect(func(): if _kit_scroll != null: _kit_scroll.scroll_vertical = int(target.position.y + v.position.y))
	return outer

# ---------------- run end ----------------
# Debrief presentation reads the paid receipt. Local selections never write the profile.
var _end_run = null
var _end_heir_pick := ""
var _end_heir_named := ""

func _end_plain(pad: float = 0) -> MarginContainer:
	var m = MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: m.add_theme_constant_override("margin_" + side, px(pad))
	return m

func _end_btn(text: String, act: String, arg = "", primary := false) -> Button:
	var b = abtn(text, act, arg)
	if b != null:
		b.set_meta("end_primary", primary)
		b.add_theme_font_override("font", GS.sheet_medium())
		b.add_theme_color_override("font_color", GS.MAP_EMBER if primary else GS.TEXT)
		b.add_theme_color_override("font_focus_color", GS.MAP_EMBER if primary else GS.TEXT)
		b.add_theme_color_override("font_hover_color", GS.ON_EMBER if primary else GS.TEXT)
		b.add_theme_color_override("font_pressed_color", GS.ON_EMBER if primary else GS.TEXT)
		for state in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, GS.sheet_jump_boxes(k)[state] if primary else GS.flat(Color(0, 0, 0, 0), 10, 8, k))
		b.custom_minimum_size.y = px(56 if primary else 40)
	return b

func _end_style(n: Node) -> void:
	if n is Label and not n.get_meta("end_number", false): n.add_theme_font_override("font", GS.sheet_body())
	if n is Button:
		var focus = StyleBoxFlat.new(); focus.bg_color = Color(0, 0, 0, 0); focus.border_color = GS.TEXT2; focus.border_width_bottom = maxi(1, px(1)); n.add_theme_stylebox_override("focus", focus)
	if n is Button and not n.get_meta("end_primary", false):
		n.add_theme_color_override("font_color", GS.TEXT); n.add_theme_color_override("font_focus_color", GS.TEXT); n.add_theme_color_override("font_hover_color", GS.TEXT)
		for state in ["normal", "hover", "pressed", "disabled"]: n.add_theme_stylebox_override(state, GS.flat(Color(0, 0, 0, 0), 10, 8, k))
	if n is RichTextLabel:
		n.add_theme_font_override("normal_font", GS.sheet_body()); n.add_theme_font_override("bold_font", GS.sheet_medium())
		n.add_theme_color_override("default_color", GS.TEXT)
	for ch in n.get_children(): _end_style(ch)

func _end_row(parent: VBoxContainer, title: String) -> VBoxContainer:
	var sep = HSeparator.new(); sep.add_theme_stylebox_override("separator", GS.flat(GS.SHEET_HAIR, 0, 0, k)); sep.custom_minimum_size.y = px(1); parent.add_child(sep)
	var v = vbox(4); parent.add_child(v)
	v.add_child(lbl(title.to_upper(), 17, GS.TEXT2))
	return v

func _end_afford(R: Dictionary) -> Array:
	var all = []; var balance = float(R["carry"]["inheritance"]["balance"]); var before = balance - float(R["carry"]["ren"])
	for id in C.LEGACY:
		var u = C.LEGACY[id]
		if not C.jt(C.META["unlocked"].get(id)) and (not C.jt(u.get("req")) or C.jt(C.META["unlocked"].get(u["req"]))): all.append({"n": u["n"], "cost": u["cost"], "tab": "legacy"})
	for id in C.HULL_VARIANTS:
		var u = C.HULL_VARIANTS[id]
		if not C.jt(u.get("arc")) and not C.jt(C.META["variants"].get(id)): all.append({"n": u["n"], "cost": u["cost"], "tab": "variants"})
	for id in C.ADMIRALS:
		var u = C.ADMIRALS[id]
		if float(u.get("cost", 0)) > 0 and not C.jt(C.META["admirals"].get(id)): all.append({"n": u["n"], "cost": u["cost"], "tab": "admiral", "fac": u.get("fac", "voidsworn")})
	if C.LINEAGE_TREES.has(R["admiral"]): all.append({"n": str(C.ADMIRALS[R["admiral"]]["n"]) + " line reset", "cost": C.lineageRespecCost(R["admiral"]), "tab": "mastery"})
	all.sort_custom(func(x, y): return float(x["cost"]) < float(y["cost"]))
	var fresh = all.filter(func(x): return float(x["cost"]) > before and float(x["cost"]) <= balance)
	if not fresh.is_empty(): return [fresh[0], fresh.size(), true]
	var next = all.filter(func(x): return float(x["cost"]) > balance)
	return [next[0] if not next.is_empty() else (all[0] if not all.is_empty() else {}), 0, false]

func _end_nem_name(entry: Dictionary) -> String:
	var title = str(entry.get("title", "")); var name = str(entry.get("name", "")).trim_prefix(title + " ")
	return name + (", " + title if title != "" else "")

func _end_nem(v: VBoxContainer, R: Dictionary) -> void:
	var nz = R["carry"]["inheritance"].get("nem", {})
	var lessons = nz.get("lessons", [])
	var shown = false
	if lessons.is_empty() and int(nz.get("met", 0)) > 0:
		v.add_child(lbl("No weakness was taught this run.", 18, GS.TEXT2)); shown = true
	for l in lessons:
		var nw = C.BattleAPI.nem_entry(C.NEM_WEAK, l.get("w"), l.get("fac"))
		var lead = " beat you and taught you a weakness: " if l.get("taught", true) else ". Weakness found: "
		v.add_child(rich("Nemesis lesson: " + ("you broke " if not l.get("taught", true) else "") + c(esc(_end_nem_name(l)), GS.NEM) + lead + esc(nw["n"] if nw != null else "the hunter's tactics") + ".", 18)); shown = true
		if str(l.get("text", "")) != "": v.add_child(lbl(str(l["text"]), 17, GS.TEXT2))
	for N in R.get("nems", {}).values():
		if not N is Dictionary: continue
		var met = float(N.get("met", 0)) > 0 or float(N.get("beaten", 0)) > 0 or float(N.get("scars", 0)) > 0
		if not met: continue
		var who = c(esc(_end_nem_name(N)), GS.NEM)
		for w in N.get("revealed", []):
			if lessons.any(func(l): return l.get("fac") == N.get("fac") and l.get("w") == w): continue
			var entry = C.BattleAPI.nem_entry(C.NEM_WEAK, w, N.get("fac"))
			if entry != null: v.add_child(rich("Nemesis lesson: you broke " + who + ". Weakness found: " + esc(entry["n"]) + ".", 18)); shown = true
		for ad in N.get("adapt", []):
			v.add_child(rich("Nemesis lesson: " + who + " adapted. " + esc(C.nemAdaptName(ad, N["fac"])) + ": " + esc(C.nemAdaptWhyLine(ad, N)) + ".", 18)); shown = true
		if float(N.get("loot", 0)) > 0:
			v.add_child(rich("Raided: " + c(esc(N["name"]), GS.NEM) + "'s Hullbreakers took " + C.numstr(N["loot"]) + " credits this run. One raider line crossed.", 18)); shown = true
		if N.get("dead", false): v.add_child(rich("Nemesis lesson: " + who + " is destroyed. Everything you learned fighting them carries forward.", 18)); shown = true
	if not shown: v.add_child(lbl("No Nemesis meeting this run." if int(nz.get("met", 0)) == 0 else "No weakness was taught this run.", 18, GS.TEXT2))

func _end_heir_rank_words() -> Array:
	var out = []
	for f in C.CAPTAINS.keys():
		for w in C.CAPTAINS[f]["ranks"]:
			if not out.has(w): out.append(w)
	for w in ["High Admiral", "First Admiral", "Line Admiral", "Fleet Marshal", "Oath-Captain", "Admiral"]:
		if not out.has(w): out.append(w)
	out.sort_custom(func(a, b): return a.length() > b.length())
	return out

func _end_heir_label(id: String) -> String:
	# Design 4.5: the row names the candidate, then their rank. A name that already opens with a rank
	# word keeps that word in the rank slot; otherwise the candidate holds their faction's top rank.
	var nm = str(C.ADMIRALS[id]["n"])
	for w in _end_heir_rank_words():
		if nm.begins_with(w + " "): return nm.substr(w.length() + 1) + ", " + w
	var ranks = C.CAPTAINS[str(C.or_(C.ADMIRALS[id].get("fac"), "voidsworn"))]["ranks"]
	return nm + ", " + str(ranks[ranks.size() - 1])

var _end_data: Dictionary = {}
var _end_confirmed := false
var _end_return := false
var _end_last_flagship: Dictionary = {}
var _end_live_run = null
var debrief: Control
const Debrief = preload("res://ui/campaign/debrief_ledger.gd")

func _end(d: Dictionary) -> Control:
	var R = d["run"]
	if not is_same(_end_run, R):
		_end_run = R; _end_heir_named = ""; _end_confirmed = false
		_end_heir_pick = str(C.META["heirs"].get(R["fac"], ""))
		if not C.shadowAdmirals(R["fac"], R["admiral"]).has(_end_heir_pick):
			var ids = C.shadowAdmirals(R["fac"], R["admiral"])
			_end_heir_pick = str(ids[0]) if not ids.is_empty() else ""
	_end_data = d; _end_return = false
	debrief = Debrief.new(); debrief.setup(self, d)
	return debrief

func _end_confirm() -> void:
	if _end_confirmed: return
	_end_confirmed = true
	if _end_heir_pick != "" and C.META["heirs"].get(_end_run["fac"]) != _end_heir_pick:
		_end_heir_named = _end_heir_pick; C.act("nameHeir", _end_heir_pick)
	_dirty = true

func _end_back() -> void:
	_end_return = false
	C.show_page("end", _end_data, C.endActions(_end_data["run"], _end_data["next"]))

func _campaign_action(act: String, arg = "") -> void:
	# All end-page exits, including the old progression page's title link, pass here.
	if _end_return and act == "title": _end_back(); return
	var ending = C.page.get("kind") == "end" or _end_return
	if ending and act in ["title", "newRunScreen", "nextFac"] and not _end_confirmed: return
	if ending and act in ["progTab", "lineage"]: _end_return = true
	C.act(act, arg)
	if ending and act == "buyAdmiral": _end_back()

func _end_detail_body(d: Dictionary, section: String) -> Control:
	# Original receipt sentences live here, behind their named keys and hovers.
	var R = d["run"]; var victory = d["victory"]; var s = R["stats"]; var cy = R["carry"]
	var receipt = cy["inheritance"]; var flown = receipt["flown"]
	var first = not victory and not d["abandoned"] and int(C.META["stats"].get("losses", 0)) == 1
	var crusade = R["fac"] == "voidsworn"
	var v = vbox(10)
	if section == "renown":
		var r1 = _end_row(v, "Doctrine and renown")
		r1.add_child(lbl("Renown: " + C.numstr(cy["ren"]) + " earned. " + C.numstr(receipt["balance"]) + " in the vault.", 18, GS.TEXT))
		if float(cy["ren"]) == 0: r1.add_child(lbl("No renown earned this run", 18, GS.TEXT2))
		r1.add_child(lbl(C.numstr(float(s["battles"]) * 2) + " from battles, " + C.numstr(float(s["elites"]) * 4) + " from elites, " + C.numstr(float(s["bosses"]) * 15) + " from flagships, " + C.numstr(floor(float(s["kills"]) / 4)) + " from kills, " + C.numstr((float(R["sector"]) - 1) * 5) + " for sectors reached.", 17, GS.TEXT2))
		if float(cy["hl"]) > 0: r1.add_child(lbl("Threat " + C.numstr(cy["hl"]) + ": renown paid at x" + C.numstr(1 + 0.1 * float(cy["hl"])) + ".", 17, GS.TEXT2))
		var aff = _end_afford(R); var target = aff[0]
		var at = "Playtest: everything unlocked. Earnings recorded." if C.playtestAll() else ("Now affordable: " + str(target["n"]) + ", " + C.numstr(target["cost"]) + " renown" + (", and " + str(aff[1] - 1) + " more within reach." if aff[1] > 1 else ".") if aff[2] else ("Next: " + str(target["n"]) + " at " + C.numstr(target["cost"]) + ". " + C.numstr(max(0, float(target["cost"]) - float(receipt["balance"]))) + " more renown." if not target.is_empty() else "All rewards owned."))
		var affordability = lbl(at, 18, GS.TEXT); affordability.mouse_filter = Control.MOUSE_FILTER_PASS
		var available = []
		for item in receipt["affordable"]: available.append(str(item["n"]) + ": " + C.numstr(item["cost"]) + " renown")
		affordability.tooltip_text = "\n".join(PackedStringArray(available)); r1.add_child(affordability)
		var spend = flow(8)
		var tab = str(target.get("tab", "legacy"))
		add(spend, _end_btn("Spend renown" if not C.playtestAll() and tab == "legacy" else "View doctrine", "progTab", "legacy"))
		add(spend, _end_btn("Spend renown" if not C.playtestAll() and tab == "variants" else "View hull rewards", "progTab", "variants"))
		# Admiral rewards share the receipt view, so they cannot bypass the heir.
		var admirals = Button.new(); admirals.text = "View admirals" if C.playtestAll() else "Unlock admirals"
		admirals.pressed.connect(func(): debrief.open_detail("admirals"))
		spend.add_child(admirals)
		r1.add_child(spend)
	if section == "admirals":
		for id in C.ADMIRALS:
			var adm = C.ADMIRALS[id]
			v.add_child(lbl(str(adm["n"]), 20, GS.TEXT))
			v.add_child(lbl(str(adm.get("doc", "")), 18, GS.TEXT2))
			if C.jt(C.META["admirals"].get(id)) or float(adm.get("cost", 0)) == 0:
				v.add_child(lbl("Unlocked", 17, GS.TEXT2))
			else:
				var buy = Button.new(); buy.text = "Unlock for " + C.numstr(adm["cost"]) + " renown"
				buy.disabled = float(C.META.get("renown", 0)) < float(adm["cost"])
				buy.pressed.connect(func(): _campaign_action("buyAdmiral", id)); v.add_child(buy)
	if section == "lineage":
		var r2 = _end_row(v, "Lineage")
		r2.add_child(lbl(str(C.ADMIRALS[flown["id"]]["n"]) + ": +" + C.numstr(snapped(float(cy["mxGain"]), 0.01)) + " XP. Level " + str(flown["level"]) + ".", 18, GS.TEXT))
		var track = ColorRect.new(); track.color = GS.SHEET_HAIR; track.custom_minimum_size.y = px(6)
		var fill = ColorRect.new(); fill.color = GS.TEXT2; fill.anchor_bottom = 1; fill.anchor_right = 1.0 if flown["next"] == null else clampf(float(flown["xp"]) / maxf(1, float(flown["next"])), 0, 1); track.add_child(fill); r2.add_child(track)
		if float(cy["mxGain"]) == 0: r2.add_child(lbl("No mastery earned this run", 18, GS.TEXT2))
		r2.add_child(lbl(C.numstr(flown["xp"]) + (" XP. This evolution is at full mastery." if flown.get("hasCap", false) else " XP. This line is at its current cap.") if flown["next"] == null else C.numstr(flown["xp"]) + " of " + C.numstr(flown["next"]) + " XP. " + C.numstr(flown["remaining"]) + (" XP to capstone mastery " + C.roman(int(flown.get("capLevel", 0)) + 1) if flown.get("hasCap", false) else " XP to level " + str(int(flown["level"]) + 1)) + ".", 17, GS.TEXT2))
		var linebtn = _end_btn("Choose " + str(C.ADMIRALS[flown["id"]]["n"]) + "'s level " + str(5 + C.lineageBuild(flown["id"])["picks"].size()) + " skill" if int(flown["pending"]) > 0 else ("Choose Command evolution" if flown["capstoneReady"] else "View admiral line"), "lineage" if flown["tree"] else "progTab", flown["id"] if flown["tree"] else "mastery")
		if linebtn != null:
			linebtn.tooltip_text = "Recorded skills: " + (", ".join(PackedStringArray(flown["chosen"])) if not flown["chosen"].is_empty() else "None yet") + "."
			if flown.get("hasCap", false) and int(flown.get("capLevel", 0)) > 0:
				var effect := _capstone_effect(int(flown["capLevel"]) - 1)
				if not effect.is_empty(): linebtn.tooltip_text += "\nCapstone mastery: " + effect
			for perk in flown["earned"]: linebtn.tooltip_text += "\n" + str(perk["n"]) + " earned: " + str(perk["d"])
			r2.add_child(linebtn)
		for row in receipt["shadow"]:
			if float(row["xp"]) > 0:
				var shadow = lbl(str(C.ADMIRALS[row["id"]]["n"]) + ": +" + C.numstr(snapped(float(row["xp"]), 0.01)) + " shadow XP (Level " + C.numstr(row["level"]) + ")." + (" Priority: double rate." if float(row["rate"]) == 0.5 else ""), 17, GS.TEXT2)
				shadow.mouse_filter = Control.MOUSE_FILTER_PASS; shadow.tooltip_text = "Total " + C.numstr(row["total"]) + " XP. " + ("Fully mastered." if row["next"] == null else C.numstr(row["remaining"]) + " XP to " + ("capstone mastery " + C.roman(int(row.get("capLevel", 0)) + 1) if row.get("hasCap", false) else "level " + str(int(row["level"]) + 1)) + ".")
				r2.add_child(shadow)
		if float(cy["mxOverflow"]) > 0: r2.add_child(lbl(C.numstr(cy["mxOverflow"]) + " XP past this line's cap went to shadow learning.", 17, GS.TEXT2))
		if float(cy["shadowBank"]) > 0: r2.add_child(lbl(C.numstr(cy["shadowBank"]) + " shadow XP saved for an uncapped benched line.", 17, GS.TEXT2))
		if float(cy["hl"]) > 0: r2.add_child(lbl("Threat " + C.numstr(cy["hl"]) + " paid " + C.numstr(float(cy["hl"]) * 2) + " XP to " + str(C.ADMIRALS[R["admiral"]]["n"]) + " and " + C.numstr(cy["hl"]) + " XP to the faction shadow pool.", 17, GS.TEXT2))
	if section == "cores":
		var r3 = _end_row(v, "Core sync"); var cores = receipt.get("cores", []).duplicate(); cores.sort_custom(func(x, y): return x["tierUp"] and not y["tierUp"])
		if cores.is_empty(): r3.add_child(lbl("No protocols taken this run.", 18, GS.TEXT2))
		for row in cores:
			var nm = c(esc(str(C.PATRONS[row["id"]]["n"])), GS.TEXT)
			if row["tierUp"]: r3.add_child(rich(nm + ": crossed into " + esc(str(C.FAVOUR_TIERS[row["tier"]]["n"])) + " this run at " + C.numstr(row["total"]) + " protocols.", 18))
			r3.add_child(rich(nm + (": Full sync, " + C.numstr(row["total"]) + " protocols." if row["next"] == null else ": " + C.numstr(row["total"]) + " of " + C.numstr(row["next"]) + " to " + esc(str(C.FAVOUR_TIERS[int(row["tier"]) + 1]["n"])) + "."), 18))
			var total = row["next"] if row["next"] != null else maxf(1, float(row["total"]))
			r3.add_child(GS.thin_bar(k, float(row["total"]) / float(total), GS.TEXT2, 600, 8, GS.SHEET_HAIR))
	if section == "fleet":
		var fl = R["fleet"].filter(func(x): return float(x["hp"]) > 0)
		var score = func(x): return (float(x["car"]["dealt"]) + float(x["car"]["kills"]) * 40.0) if x.get("car") != null else 0.0
		fl = C.ssort(fl, func(a, b): return score.call(b) - score.call(a))
		if fl.size() > 0:
			var best = fl[0]
			if score.call(best) > 0: v.add_child(rich("Standout ship: [b]" + c(esc(best["name"]), GS.TEXT) + "[/b], " + C.numstr(best["car"]["kills"]) + " kills and " + C.numstr(best["car"]["dealt"]) + " damage across " + C.numstr(best["car"]["battles"]) + " battle" + ("s" if float(best["car"]["battles"]) > 1 else "") + ".", 17))
			v.add_child(lbl("The fleet that finished it" if victory else "Still flying", 20, GS.TEXT, GS.sheet_medium()))
			for x in fl:
				var cr = x.get("car") if x.get("car") != null else {"dealt": 0, "kills": 0}
				var p = _end_plain(8); var r = hbox()
				r.add_child(rich("[b]" + esc(x["name"]) + "[/b] " + c(esc(C.HULLS[x["tpl"]]["n"]), GS.TEXT2) + "\n" + c(esc(C.rankName(x["cap"])) + " " + esc(x["cap"]["name"]), GS.TEXT2), 17))
				r.add_child(rich("[right]" + C.numstr(cr["kills"]) + " kills\n" + c(C.numstr(cr["dealt"]) + " dmg", GS.TEXT2) + "[/right]", 17)); p.add_child(r); v.add_child(p)
		if R["fallen"].size() > 0:
			var nm = []
			for f in R["fallen"]: nm.append(f["name"])
			v.add_child(lbl("Captains lost this run: " + ", ".join(PackedStringArray(nm)) + ".", 18, GS.TEXT2))
	if section == "nemesis": _end_nem(v, R)
	if section == "record":
		for teaching_card in CampaignTips.CARDS:
			if teaching_card[0] == "c_loss": v.add_child(lbl(str(teaching_card[2]), 18, GS.TEXT2))
		v.add_child(lbl(_story_text(), 18, GS.TEXT2))
		var payoff: String = C.beat3Payoff(R)
		if payoff != "": v.add_child(lbl(payoff, 18, GS.TEXT))
		if C.jt(R.get("eatenCore")) and C.PATRONS.has(R["eatenCore"]): v.add_child(lbl("The swarm ate " + str(C.PATRONS[R["eatenCore"]]["n"]) + ".", 18, GS.TEXT2))
		if first: v.add_child(lbl("Your first expedition did not reach the rim, and Vesper always knew it might take more than one push. Every credit of renown, every admiral XP point, and every enemy weakness you exposed carries straight into the next fleet." if crusade else "Your fleet fell short, though the effort stays with you. Keep the renown you earned, the admiral XP you banked, and the tactical weaknesses you uncovered, and take a sharper build into the next run.", 18, GS.TEXT))
		if victory:
			var wf = []
			for f in C.or_(C.META["stats"].get("wonFacs"), []): wf.append(C.FACTIONS[f]["n"])
			var w = int(C.META["stats"]["wins"])
			v.add_child(lbl(("Victories so far: " + str(w)) if w > 1 else "Your first victory." + "", 18, GS.TEXT))
			v.add_child(lbl("Won with: " + ", ".join(PackedStringArray(wf)) + ".", 18, GS.TEXT))
		else:
			var pb = float(d["prevBest"])
			v.add_child(lbl(("New best: sector " + C.roman(R["sector"])) if float(R["sector"]) > pb else ("Best so far: sector " + C.roman(min(3, float(C.META["stats"]["best"])))), 20, GS.TEXT))
	_end_style(v)
	return v

# ---------------- lineage trees ----------------
# issue #305: a lineage pick key (admiral:branch:tier:choice or admiral:cap:n) as its skill name
func _tree_name(key: String) -> String:
	var p = key.split(":")
	if p.size() < 3: return key
	var tree = C.LINEAGE_TREES.get(p[0])
	if not tree is Dictionary: return key
	if p[1] == "cap":
		var c = int(p[2]); var caps = tree.get("capstones", [])
		return str(caps[c]["n"]) if c < caps.size() else key
	var t = int(p[2]); var c2 = int(p[3]) if p.size() > 3 else 0
	var br = tree.get("branches", {}).get(p[1])
	if not br is Dictionary: return key
	var tiers = br.get("tiers", [])
	if t >= tiers.size(): return key
	var pair = tiers[t]
	return str(pair[c2]["n"]) if c2 < pair.size() else key
func _lineage_node(n) -> Control:
	var chosen = n["state"] == "chosen"; var cv = card(chosen, 300); var col = cv[1]
	col.add_child(lbl(n["n"], 19, BONE, font_semi)); col.add_child(lbl(n["d"], 18, BONE2))
	var labels = {"chosen": "Recorded", "locked": "Locked until reset", "available": "Choose this skill", "future": "Not yet available"}
	add(col, abtn(labels[n["state"]], "offerLineage", n["key"], n["state"] == "available"))
	if n["state"] == "locked": cv[0].modulate.a = 0.55
	return cv[0]
func _lineage(id) -> Control:
	var v = vbox(12); var tree = C.LINEAGE_TREES[id]; var build = C.lineageBuild(id); var nodes = C.lineageNodes(id); var level = C.masteryLevel(id)
	v.add_child(Kit.section("Lineage", k))
	v.add_child(Kit.heading(str(C.ADMIRALS[id]["n"]), 44, k))
	var _lin_lead: String = {"voidsworn": "Chalked into Vesper's fleet doctrine.", "hegemony": "Logged into Meridian command doctrine.", "corsair": "Passed down through the Ashfall dens.", "chorus": "Encoded into the next brood's neural sacs.", "ithar": "Recorded in optical glass.", "deathless": "Committed permanently to the Archive."}.get(str(C.ADMIRALS[id].get("fac", "")), "Recorded in fleet doctrine.")
	v.add_child(lbl(_lin_lead + " Pick one branch skill at levels 5, 6, and 7; its partner locks until you reset this line.", 17, BONE2))
	v.add_child(_mastery_bar(id))
	v.add_child(lbl(str(maxi(0, mini(3, level - 4) - build["picks"].size())) + " branch picks ready. Capstone at level 8 (230 XP).", 17, BONE2))
	v.add_child(lbl("Command skills and capstones use " + str(C.ADMIRALS[id]["cmd"]["n"]) + ", the primary Command. Fleet and flagship branches open their first tier.", 17, BONE3))
	if not C.lineageBetweenRuns(): v.add_child(lbl("Finish or abandon your saved run before changing this line.", 17, BLOOD))
	var columns = flow(16); var trunk = vbox(8); trunk.custom_minimum_size.x = px(300)
	trunk.add_child(lbl("Trunk: levels 1 to 4", 20, BONE, font_semi))
	for i in range(1, C.MASTERY_PERKS.size()):
		var cv = card(false, 300); cv[1].add_child(lbl(str(i) + ". " + str(C.MASTERY_PERKS[i]["n"]), 19, BONE, font_semi)); cv[1].add_child(lbl(C.MASTERY_PERKS[i]["d"], 18, BONE2)); cv[1].add_child(lbl(C.numstr(C.MASTERY_XP[i]) + " XP: " + ("earned" if level >= i else "not yet earned"), 17, BONE3)); trunk.add_child(cv[0])
	columns.add_child(trunk)
	for b in tree["branches"].keys():
		var col = vbox(8); col.custom_minimum_size.x = px(300)
		var glyph = {"A": "[+] Command", "B": "[=] Fleet", "C": "[*] Flagship and line"}
		col.add_child(lbl(glyph[b] + ": " + str(tree["branches"][b]["n"]), 20, BONE, font_semi))
		for t in range(tree["branches"][b]["tiers"].size()):
			col.add_child(lbl("Tier " + str(t + 1), 18, BONE3))
			for n in nodes:
				if n["branch"] == b and n["tier"] == t + 1: col.add_child(_lineage_node(n))
		columns.add_child(col)
	v.add_child(columns)
	var cap = panel(BONE3, IRON, 16); var capv = vbox(8); cap.add_child(capv)
	capv.add_child(lbl("Level 8: Command evolution", 23, BONE, font_goth)); var capnodes = flow()
	for n in nodes:
		if n["branch"] == "cap": capnodes.add_child(_lineage_node(n))
	capv.add_child(capnodes); capv.add_child(_capstone_mastery(id)); v.add_child(cap)
	v.add_child(lbl("Reset clears all branch picks and the capstone. XP and trunk perks stay. This line has been reset " + C.numstr(build["respecs"]) + " times. You have " + C.numstr(C.z0(C.META.get("renown"))) + " renown.", 18, BONE3))
	return v   # Back (to Admiral mastery) and Reset line sit in the page's fixed bar (_kit_page)
func _capstone_effect(i: int) -> String:
	var value = C.CAPSTONE_MASTERY_PERKS[i].get("d")
	var effect := value.strip_edges() as String if value is String else ""
	return "" if effect.begins_with("Placeholder:") else effect

# Job 7 step 14: the mastery levels on the chosen capstone evolution, in the same block as the evolution choice.
func _capstone_mastery(id) -> Control:
	var tree = C.LINEAGE_TREES[id]; var build = C.lineageBuild(id); var v = vbox(6)
	if build["capstone"] == null:
		v.add_child(lbl("Choose a Command evolution to open capstone mastery at 320, 440 and 600 XP.", 17, BONE3)); return v
	var chosen = tree["capstones"][int(build["capstone"])]; var xp = C.masteryXP(id); var l = C.capstoneMasteryLevel(id); var nx = C.capstoneMasteryNext(id)
	v.add_child(lbl("Capstone mastery: " + str(chosen["n"]), 20, BONE, font_semi))
	v.add_child(lbl((C.numstr(xp) + " XP. This evolution is at full mastery.") if nx == null else (C.numstr(xp) + " / " + C.numstr(nx) + " XP. " + C.numstr(float(nx) - xp) + " XP to capstone mastery " + C.roman(l + 1) + "."), 17, BONE3))
	var row = flow(10)
	for i in range(C.CAPSTONE_MASTERY_PERKS.size()):
		var earned = l > i; var cv = card(earned, 300)
		cv[1].add_child(lbl("Mastery " + C.roman(i + 1) + ": " + str(C.CAPSTONE_MASTERY_PERKS[i].get("n", "")) + (" (earned)" if earned else ""), 18, BONE, font_semi))
		var effect := _capstone_effect(i)
		var sig = C.capstoneSignature(id) if i == 2 else null   # issue 1650: Mastery III names the chosen capstone's own signature
		if sig is Dictionary: effect = str(sig["n"]) + ". " + str(sig["d"])
		if not effect.is_empty(): cv[1].add_child(lbl(effect, 17, BONE2))
		cv[1].add_child(lbl(C.numstr(C.CAPSTONE_MASTERY_XP[i]) + " XP", 17, BONE3))
		if not earned: cv[0].modulate.a = 0.55
		row.add_child(cv[0])
	v.add_child(row)
	return v

# ---------------- dialogs ----------------
func _modal(md: Dictionary) -> void:
	_modal_acts = md["acts"]; var acts = _modal_acts; var d = md["data"]
	var scroll := 0
	if md["kind"] == "promotions" and _modal_kind == "promotions" and is_instance_valid(_modal_scroll):
		scroll = _modal_scroll.scroll_vertical
	_modal_kind = md["kind"]
	var dim = ColorRect.new(); dim.color = GS.SHADE; dim.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(dim)
	dim.mouse_force_pass_scroll_events = false
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(cc)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box = shell_panel(20)   # a dialog: one matte panel (chamfers, scanline, bevel, brackets); its words sit on wells (_well_text)
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_modal_scroll = sc
	var v = vbox(8); v.custom_minimum_size.x = px(700); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(v); box.add_child(sc); cc.add_child(box)
	var h2 = func(t: String): v.add_child(lbl(t.to_upper(), 27, BONE, font_goth))
	var p = func(t: String, col: Color = BONE): v.add_child(lbl(t, 17, col))
	var R = C.RUN
	match md["kind"]:
		"lineagePick":
			h2.call("Record " + str(d["n"]) + "?"); p.call(d["d"]); p.call("The other skill at this tier locks until you pay to reset this line.", BONE3)
			v.add_child(foot([abtn("Back", "closeModal", "", false, false, acts), fin("Confirm choice", "confirmLineage", d["key"], acts)]))
		"lineageRespec":
			h2.call("Reset " + str(C.ADMIRALS[d["id"]]["n"]) + "?"); p.call("Spend " + C.numstr(d["cost"]) + " renown to clear every branch pick and the capstone. Keep all XP and trunk perks.")
			v.add_child(foot([abtn("Back", "closeModal", "", false, false, acts), fin("Reset for " + C.numstr(d["cost"]) + " renown", "confirmRespec", d["id"], acts)]))
		"intro", "sector":
			var F = C.FACTIONS[d["fac"]]
			if md["kind"] == "intro":
				h2.call("Sector I"); v.add_child(rich("The " + C.runWord() + " crosses into contested space. Long-range scans confirm [b]" + esc(F["n"]) + "[/b] activity along every jump route.", 17))
			else:
				h2.call("Sector " + C.roman(R["sector"]) + ((": " + str(C.REGIONS[d["region"]]["n"])) if d.get("region") != null and C.REGIONS.has(d["region"]) else ""))
				v.add_child(rich("With the flagship broken, the fleet jumps deeper. Fleet command expands: [b]" + c("+3 command points", VERD) + "[/b], and crews patch 40% of every hull during the transit.", 17))
				v.add_child(rich("Scanners confirm [b]" + esc(F["n"]) + "[/b] ahead.", 17))
			if md["kind"] == "intro": p.call(F.get("blurb", ""), BONE2)
			if md["kind"] == "sector" and d.get("adapt") != null and d.get("adaptFac") != null and C.nemCanReturn(d["adaptFac"]):
				var na = d["adapt"]; var nf = d["adaptFac"]
				# the Nemesis adaptation: its own well with the reserved red bar and the NEMESIS tag, as the battle's Nemesis block
				var aw = blk(ALERT, 5, 14, 10); aw[0].set_meta("keep", true)
				var ah = hbox(8); ah.add_child(tagl("Nemesis", ALERT, true)); ah.add_child(lbl("ADAPTED TO YOU", 17, BONE, font_caps, false)); aw[1].add_child(ah)
				aw[1].add_child(rich(c(esc(str(d.get("adaptWho", ""))) + " has adapted: ", BONE2) + "[b]" + c(esc(C.nemAdaptName(na, nf)), BLOOD) + "[/b] " + c("(" + esc(str(d.get("adaptWhy", ""))) + ")", BONE3), 17))
				aw[1].add_child(rich(c("If you meet this hunter again: " + esc(C.nemAdaptDesc(na, nf)), BONE2), 18))
				if str(d.get("adaptLine", "")) != "": aw[1].add_child(rich("[i]" + c(esc(str(d["adaptLine"])), BLOOD) + "[/i]", 17))
				v.add_child(aw[0])
			if d["cond"] != null: v.add_child(rich(c("Sector condition: [b]" + esc(d["cond"]["n"]) + "[/b].", EMBER) + " " + c(esc(d["cond"]["d"]), BONE2), 17))
			if md["kind"] == "sector": p.call(F.get("blurb", ""), BONE2)
			if md["kind"] == "intro": p.call("Pick a route across the sector map. Battles carrying a core’s signal pay out that core’s protocols, so the route you choose shapes your build. The flagship of the sector waits at the far end.", BONE2)
			_story_line(v)
			v.add_child(foot([fin("Plot a course", "beat3" if float(R["sector"]) == 3 else "closeModal", "", acts)]))
		"abandon":
			h2.call("Abandon the current run?"); p.call("Starting over ends your saved run. Your best result so far is kept either way.", BONE2)
			v.add_child(foot([abtn("Keep it", "closeModal", "", false, false, acts), fin("Abandon and start over", "abandonRun", "", acts)]))
		"sell":
			var _s_fac := str(R.get("fac", "")); var _s_nm := str(d["ship"]["name"])
			h2.call(("Reabsorb " if _s_fac == "chorus" else "Decommission ") + _s_nm + "?")
			var _s_body: String = ("Its refits return to the hold and you recover " if _s_fac == "chorus" else ("Its mind-core returns to the Archive and its refits return to the hold. You recover " if _s_fac == "deathless" else "Its crew stands down and its refits return to the hold. You recover ")) + C.numstr(d["value"]) + " " + str(d.get("word", "credits")) + "." + (" A regrown ship has nothing to strip until it has fought." if d["ship"].get("regrown") else "")
			p.call(_s_body, BONE2)
			v.add_child(foot([abtn("Keep it", "closeModal", "", false, false, acts), fin("Decommission", "sellConfirm", d["ship"]["uid"], acts)]))
		"repair_stop":
			var drydock: bool = d["kind"] == "drydock"
			h2.call("Repair dock" if drydock else "Field repairs")
			for i in range(d["options"].size()):
				var opt: Dictionary = d["options"][i]
				var detail := "%s of each ship's %s hull. +%s hull across the fleet" % [opt["rate"], "missing" if drydock else "maximum", C.numstr(opt["hp"])]
				if opt["credits"] > 0: detail += " and +" + C.numstr(opt["credits"]) + " credits"
				add(v, choice("Repairs and credits" if i else "Take the full service", detail + ".", "repairStop", "stipend" if i else "service", acts))
		"event":
			var ev = d["ev"]; h2.call(ev["t"]); p.call(ev["b"])
			for i in range(ev["o"].size()):
				var o = ev["o"][i]; var cost = o["r"].get("cost") if o["r"] is Dictionary else null; var ok = not C.jt(cost) or float(R["credits"]) >= float(cost)
				var blue = C.jt(o.get("need"))   # B4 blue options: the requirement in plain words, shown either way
				add(v, choice(o["l"], str(o["s"]) + C.relicTradeNote(o) + ("" if ok else " (not enough credits)"), "eventChoice", i, acts, BLUE if blue else null, ("[" + C.needText(o["need"]) + "]") if blue else "", BLUE))
		"relic_pick":   # issue 1449: the player picks which piece of salvage a trade takes
			h2.call(d["ev"]["t"]); p.call("Which piece of salvage do you give up?")
			for j in range(d["relics"].size()):
				var rl = d["relics"][j]
				add(v, choice(C.relicName(rl), C.relicText(rl), "eventChoice", str(d["i"]) + ":" + str(j), acts))
			v.add_child(foot([abtn("Back", "eventBack", "", false, false, acts)]))
		"event_result":
			h2.call(d["ev"]["t"])
			for l in d["lines"]: p.call(l)
			v.add_child(foot([fin("Continue", "storyCore" if R.get("reward") != null and R["reward"].get("kind") == "story" else "closeModal", "", acts)]))
		"victory":
			var sm: Dictionary = d.get("summary", {})
			h2.call("Flagship destroyed" if d["kind"] == "boss" else "Victory")
			if str(d.get("beat3Debrief", "")) != "": p.call(d["beat3Debrief"], VERD)
			if not sm.is_empty(): v.add_child(rich(C.numstr(sm["kills"]) + " enemy ship" + ("" if int(sm["kills"]) == 1 else "s") + " destroyed in " + C.numstr(sm["rounds"]) + " round" + ("" if float(sm["rounds"]) == 1 else "s") + ". " + c("+", VERD) + n_(C.numstr(d["econ"]["bio"] if d.get("econ") is Dictionary and d["econ"].has("bio") else d["credits"]), VERD) + c(" biomass." if d.get("econ") is Dictionary and d["econ"].has("bio") else " credits.", VERD), 17))
			if not sm.get("lost", []).is_empty():
				var ls = []
				for l in sm["lost"]: ls.append(C.ship_with_article(str(l["ship"])) + " and " + str(l["cap"]))
				p.call("Lost: " + ", ".join(PackedStringArray(ls)) + ".", BLOOD)
			var econ: Dictionary = d["econ"] if d.get("econ") is Dictionary else {}   # issue 1178: faction economies on the victory card
			if econ.has("cullet"): p.call("Cullet from the lost glass: +" + C.numstr(econ["cullet"]) + " credits.", VERD)
			if econ.has("core"): p.call("Core recovered: the " + str(C.HULLS[econ["core"]]["n"]) + " can be regrown at a shipyard.", VERD)
			if d.get("extra", "") != "": p.call(d["extra"], VERD)
			for line in d.get("weaknessConfirmed", []): p.call(line, VERD)
			if not d["wrecks"].is_empty(): _salvage_choices(v, d["wrecks"], acts)
			if not sm.is_empty() and (R.get("boons") as Array).size() > 0 and (sm.get("boonStats", {}) as Dictionary).is_empty(): p.call("No protocol triggered this battle. Check the Fleet protocols section on a ship to see what sets each one off.", BONE3)
			var tstats: Dictionary = sm.get("treeStats", {}) if sm.get("treeStats") is Dictionary else {}
			if not tstats.is_empty():
				var tks = tstats.keys(); tks.sort(); var tls = []
				for key in tks: tls.append(_tree_name(str(key)) + " x" + C.numstr(tstats[key]))
				p.call("Lineage in action: " + ", ".join(PackedStringArray(tls)) + ".", VERD)
			if d.get("flagName", "") != "": p.call("The admiral transfers the flag to " + C.ship_with_article(str(d["flagName"])) + ". Its refit goes with it.", VERD)
			for x in sm.get("xp", []): v.add_child(rich("• " + esc(x["cap"]) + " (" + esc(x["ship"]) + "): +" + C.numstr(x["xp"]) + " experience" + ((" " + c("promoted to " + str(C.RANKS[int(x["rank"])]), VERD)) if x["up"] else ""), 18))
			if d["wrecks"].is_empty():
				var rw = d["rw"]
				var next := "Continue"
				if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): next = str(C.PATRONS[rw["p"]]["short"]) + " offers a protocol"
				elif rw.get("k") == "mod": next = "Choose a refit"
				v.add_child(foot([fin(next, "rewardNext", "", acts)]))
		"prize":
			var rows = d["rows"]; var n = rows.size()
			h2.call("Prize ship" + ("s" if n > 1 else ""))
			p.call("Your boarders took " + ((str(n) + " enemy ships") if n > 1 else "an enemy ship") + ". Keep, strip or sell back each one, then confirm once.", BONE3)
			var cpAfter = C.fleetCP(); var cred = 0.0; var refits = 0; var joins = 0
			for r in rows:
				if r["k"] == "add": cpAfter += float(C.or_(r["p"].get("cp"), 1)); joins += 1
				if r["k"] == "ransom": cred += float(r["o"]["ransom"])
				if r["k"] == "strip":
					cred += float(r["o"]["strip"]["cred"])
					if C.jt(r["o"]["strip"]["mod"]): refits += 1
			p.call("Command points: " + C.numstr(C.fleetCP()) + " of " + C.numstr(R["cpCap"]) + " used" + ((", " + C.numstr(cpAfter) + " after these join") if joins > 0 else "") + "." + (" Owners pay less for each ship you sell back to them." if (C.jt(R.get("ransoms")) or rows.any(func(x): return x["k"] == "ransom")) else ""), BONE2)
			for i in range(n):
				var r = rows[i]; var H = C.HULLS[r["p"]["tpl"]]; var hp = int(C.jsround(float(C.or_(r["p"].get("hpf"), 1)) * 100))
				var pp = panel(IRON3, IRON2, 10); var pv = vbox(6); pp.add_child(pv)
				pv.add_child(rich("[b]" + esc(r["p"]["name"]) + "[/b] " + c(esc(H["n"]) + ", " + C.numstr(C.or_(H.get("cp"), 1)) + " command point" + ("s" if float(C.or_(H.get("cp"), 1)) > 1 else "") + ", " + str(hp) + "% hull", BONE3), 18))
				if C.jt(r.get("rip")) and not C.jt(r.get("cinder")): pv.add_child(lbl("Kept, she joins with her links ripped out.", 17, VERD))
				_spec_drawer(pv, FleetManifest.preview_ship(C, r["p"]["tpl"], C.jt(r.get("rip")), rows.slice(0, i).filter(func(x): return x["k"] == "add").size()), "prize:" + str(i) + ":" + str(r["p"]["tpl"]))   # issue 1449
				var g = GridContainer.new(); g.columns = 3; g.add_theme_constant_override("h_separation", px(6))
				var sm2 = (C.modName(r["o"]["strip"]["mod"]) + " + ") if C.jt(r["o"]["strip"]["mod"]) else ""
				for opt in [["add", "Add", ("Joins at " + str(hp) + "% hull") if r["room"] else ("The Cinder Line opens from run 3" if C.jt(r.get("cinder")) else ("Your faction cannot field it" if r.get("gate") != null else "No command points left"))], ["strip", "Strip", sm2 + C.numstr(r["o"]["strip"]["cred"]) + " credits"], ["ransom", "Ransom", C.numstr(r["o"]["ransom"]) + " credits"]]:
					var b = choice(opt[1], opt[2], "prizeSet", str(i) + ":" + opt[0], acts, null, "", BONE2, r["k"] == opt[0])
					if b != null: b.custom_minimum_size.x = px(210); g.add_child(b)
				pv.add_child(g); v.add_child(pp)
			var parts = []
			if joins > 0: parts.append(str(joins) + " ship" + ("s join" if joins > 1 else " joins"))
			if refits > 0: parts.append(str(refits) + " refit" + ("s" if refits > 1 else "") + " for the hold")
			if cred > 0: parts.append("+" + C.numstr(cred) + " credits")
			p.call("You get: " + (", ".join(PackedStringArray(parts)) if parts.size() > 0 else "Nothing") + ".", BONE2)
			v.add_child(foot([fin("Confirm", "prizeConfirm", "", acts)]))
		"mod":
			h2.call("Recovered refits"); p.call(str(C.REWARD_DEF["refit"]), BONE3); p.call("Take one. It goes in the hold; fit it at a shipyard or from the fleet screen.")
			for m in d["opts"]: add(v, choice(C.modName(m), C.MODULES[m]["d"], "takeMod", m, acts))
		"boon":
			var P = C.PATRONS[d["patron"]]; var pc = Color(P["col"])
			var hd = hbox(12); var sg = lbl(P["glyph"], 26, INK, font_semi, false); var sgp = panel(pc, pc, 6); sgp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; sgp.add_child(sg); hd.add_child(sgp)
			var hv = vbox(0); hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hv.add_child(lbl(P["n"], 23, pc, font_goth)); hv.add_child(lbl(P["theme"], 17, BONE2)); hd.add_child(hv); v.add_child(hd)
			p.call("“" + str(P["quote"]) + "”", BONE2); p.call(str(C.REWARD_DEF["boon"]), BONE3)
			var offer = d["offer"]
			for i in range(offer.size()):
				var o = offer[i]; var b = C.BOONS[o["id"]]; var r = int(C.z0(o.get("r"))); var R0 = C.RARITY[r]; var duo = b.get("duo")
				var tag = ("Duo: " + " + ".join(PackedStringArray(duo.map(func(q): return str(C.PATRONS[q]["short"]))))) if C.jt(duo) else str(R0["n"])
				var detail: String = C.BOON_D[o["id"]][r]
				var fleet_line := _boon_fleet_line(o["id"], r)
				if fleet_line != "": detail += "\n" + fleet_line
				add(v, choice(b["n"], detail, "takeBoon", i, acts, Color(C.PATRONS[duo[0]]["col"]) if C.jt(duo) else pc, tag, EMBER if C.jt(duo) else Color(R0["col"])))
			v.add_child(foot([abtn("Reroll the offer (" + C.numstr(d.get("rerollCost", 0)) + (C.shopWord(d.get("rerollCost", 0)) if C.shopWord(d.get("rerollCost", 0)) != "" else " credits") + ", once)", "boonReroll", _arg_of(acts, "boonReroll"), false, false, acts),
				abtn("Decline: take " + C.numstr(d.get("declineCred", 0)) + " credits", "boonDecline", "", false, false, acts)]))
		"eatCore":
			h2.call("The swarm hungers.")
			p.call("A core you have not synced with lies within reach. Eat one now, or refuse.", BONE2)
			for core in d["cores"]:
				var P = C.PATRONS[core]; var pc = Color(P["col"])
				add(v, choice("Eat " + str(P["n"]), "every ship +10% hull for this run; lose its protocols for this run", "eatCore", core, acts, pc, str(P["glyph"])))
			v.add_child(foot([abtn("Refuse", "refuseCoreEat", "", false, false, acts)]))
		"relic":
			h2.call("The flagship’s vault" if d["boss"] else "Spoils of the elite"); p.call(str(C.REWARD_DEF["relic"]), BONE3); p.call("Choose one.")
			for r in d["opts"]: add(v, choice(C.relicName(r), C.relicText(r), "takeRelic", r, acts))
		"promote":
			var s = d["ship"]; h2.call("Promotion")
			v.add_child(rich(esc(s["cap"]["name"]) + " of the [i]" + esc(s["name"]) + "[/i] is now " + esc(C.rankName(s["cap"])) + ". Choose one perk.", 17)); p.call(str(C.REWARD_DEF["promotion"]), BONE3)
			for pk in s["cap"]["offer"]: add(v, choice(C.PERKS[pk]["n"], C.PERKS[pk]["d"], "takePerk", s["uid"] + ":" + pk, acts))
		"promotions":
			h2.call("Promotions"); p.call("Choose a perk for each captain.", BONE2)
			p.call(str(C.REWARD_DEF["promotion"]), BONE3)
			for s in d["ships"]:
				var pp := panel(IRON3, IRON2, 10); var pv := vbox(6); pp.add_child(pv)
				pv.add_child(rich("[b]" + esc(s["cap"]["name"]) + "[/b]  " + c(esc(C.rankName(s["cap"])), VERD) + "  " + esc(s["name"]), 18))
				var options := hbox(8)
				for perk in s["cap"]["offer"]:
					var button = choice(C.PERKS[perk]["n"], C.PERKS[perk]["d"], "takePerk", s["uid"] + ":" + perk, acts)
					if button == null: continue
					button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					options.add_child(button)
				pv.add_child(options); v.add_child(pp)
		"retreat":
			h2.call("Retreat?"); p.call("The fleet jumps clear. Every surviving ship takes 10% hull strain, and this stop counts as cleared.")
			v.add_child(foot([abtn("Stay and fight", "c3retreatNo", "", false, false, acts), fin("Jump out", "c3retreatYes", "", acts)]))
		_:
			for a in acts: add(v, abtn(a[0] + " " + a[1], a[0], a[1], false, false, acts))
	_well_text(v)
	# size the box to its content, up to 90% of the window height
	var vh = get_viewport().get_visible_rect().size.y
	sc.custom_minimum_size = Vector2(px(700), min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))
	v.minimum_size_changed.connect(func(): sc.custom_minimum_size.y = min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))
	if scroll > 0: sc.set_deferred("scroll_vertical", scroll)
	ModalFocus.attach(box)

func _salvage_choices(v: VBoxContainer, wrecks: Array, acts: Array) -> void:
	v.add_child(lbl("Salvage one wreck", 20, BONE))
	v.add_child(lbl(str(C.REWARD_DEF["salvage"]), 17, BONE3))
	for i in range(wrecks.size()):
		var w = wrecks[i]; var y = w["yield"]; var F = C.FACTIONS.get(w.get("fac"))
		var pp = panel(IRON3, IRON2, 10); var pv = vbox(6); pp.add_child(pv)
		pv.add_child(rich("[b]" + esc(w["name"]) + "[/b] " + c(esc(C.clsName(C.or_(w.get("cls"), ""))) + ((", " + esc(F["n"])) if F != null else ""), BONE3) + "\n" + c(esc(C.CAUSE_WORD.get(w.get("cause"), "destroyed")) + ((" by the " + esc(w["by"])) if C.jt(w.get("by")) else "") + ".", BONE2), 18))
		var g = GridContainer.new(); g.columns = 3; g.add_theme_constant_override("h_separation", px(6))
		if C.jt(y.get("mod")): add(g, choice("Strip it: " + C.modName(y["mod"]), C.MODULES[y["mod"]]["d"], "takeSalvage", str(i) + ":mod", acts))
		add(g, choice("Scrap it", "+" + C.numstr(y["cred"]) + " credits", "takeSalvage", str(i) + ":cred", acts))
		if C.jt(y.get("tow")): add(g, choice("Tow it home", "Joins your fleet at 35% hull", "takeSalvage", str(i) + ":tow", acts))
		pv.add_child(g); v.add_child(pp)

# Every line of a dialog sits on a backing (ui_style.md 3): runs of plain words (labels, rich text, the title) are gathered
# into one well each, in place; choices, rows of buttons and blocks that already are wells stay as they are.
func _well_text(v: VBoxContainer) -> void:
	var kids = v.get_children(); var cur: VBoxContainer = null
	for ch in kids:
		var words = (ch is Label or ch is RichTextLabel) and not ch.has_meta("keep")
		if not words: cur = null; continue
		if cur == null:
			var w = blk(Color(0, 0, 0, 0), 6, 14, 10); v.add_child(w[0]); v.move_child(w[0], ch.get_index()); cur = w[1]
		v.remove_child(ch); cur.add_child(ch)

# Esc goes Back on the start pages (issue 1217): the first enabled action of the page's list below, the same action its
# Back button runs. The flagship aspect page has no back action yet (phase 4 adds one to both twins), so Esc does nothing
# there until then.
const BACK_ACTS := ["title", "backToSetup"]
# Issue 1448: the confirms that take a reward, relic or promotion perk, or buy a hull, play the built reward chime
# (cues.json ui_reward) in place of the plain confirm.
const REWARD_ACTS := ["takeMod", "takeBoon", "takeRelic", "takeSalvage", "prizeConfirm", "takePerk", "buyHull"]
# Names the action a button runs, so the player-path recorder presses the real button (and hears its cue) instead of
# calling the action under it (issue 1448: SND1C's reward picks were silent because the recorder skipped the buttons).
static func press_tag(b: Control, act: String, arg) -> void:
	b.set_meta("press_act", act); b.set_meta("press_arg", str(arg))
func cue_role(act: String, fallback: String) -> String:
	if act in REWARD_ACTS: return "reward"
	if act in BACK_ACTS: return "back"
	return fallback
# The cue for a key that did a screen's job (issue 1448): Esc sounds like Back, Enter like the finishing action.
func _key_cue(e: InputEventKey) -> void:
	Kit.play("ui_cancel" if e.keycode == KEY_ESCAPE else ("ui_confirm" if e.keycode in [KEY_ENTER, KEY_KP_ENTER] else "ui_click"))
const ESC_BACK := {"admiral": [["title", ""]], "aspect": [["backToSetup", ""]], "legacy": [["title", ""]], "help": [["title", ""]], "lineage": [["progTab", "mastery"]]}
func esc_back() -> bool:
	if C == null or C.modal_d != null: return false
	var kind := str(C.page.get("kind", ""))
	if kind == "admiral" and desk_opts_open: close_run_options(); return true
	if not ESC_BACK.has(kind): return false
	for pair in ESC_BACK[kind]:
		var found = _find(C.page.get("acts", []), pair[0], pair[1])
		if not found.is_empty() and found[2] == 1:
			Kit.play("ui_cancel"); _campaign_action(pair[0], pair[1]); return true
	return false
func _input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT): return
	# A route expands after the first click. Its original hit area owns the second click of that pair.
	var route := _route_click_id
	_route_click_id = ""
	if route == "" or route != picked or not e.double_click or not _route_click_rect.has_point(e.position): return
	if C == null or C.page.get("kind") != "map" or C.modal_d != null or _overlay != "" or not root.visible or ModalFocus.covered(self) or map3d._flying: return
	get_viewport().set_input_as_handled()
	_confirm_map_jump()

func _unhandled_input(e: InputEvent) -> void:
	if C == null or not root.visible or not (e is InputEventKey) or not e.pressed or e.echo: return
	if ModalFocus.covered(self): return   # issue 1559 item 5: Career (or another overlay) over the page has the keys
	if e.keycode == KEY_ESCAPE and esc_back(): get_viewport().set_input_as_handled(); return
	if C.modal_d == null and C.page.get("kind") == "fleet" and is_instance_valid(fleet_manifest):
		if fleet_manifest.handle_key(e): _key_cue(e); get_viewport().set_input_as_handled(); return
	if C.modal_d == null and C.page.get("kind") == "map":   # the map: Esc shuts a slide-over, 1 to 9 pick a route, Enter flies it
		if _overlay != "":
			if e.keycode == KEY_ESCAPE: _close_overlay(); get_viewport().set_input_as_handled()
			return
		var rn = e.keycode - KEY_1
		if rn < 0 or rn >= 9: rn = e.keycode - KEY_KP_1
		if rn >= 0 and rn < 9 and rn < _routes.size():
			if str(_routes[rn]["id"]) != picked: Kit.play(Kit.HOVER_CUE)
			map3d.clear_keyboard_preview()
			pick_route(str(_routes[rn]["id"])); get_viewport().set_input_as_handled(); return
		if e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_confirm_map_jump(); get_viewport().set_input_as_handled(); return
	if C.modal_d == null and C.page.get("kind") == "end" and is_instance_valid(debrief):
		if debrief.handle_key(e): _key_cue(e); get_viewport().set_input_as_handled(); return
	if C.modal_d != null:
		var acts = C.modal_d["acts"]
		if e.keycode == KEY_ESCAPE:
			for a in acts:   # issue 1559 item 26: the relic pick's Back (eventBack) answers Esc too
				if a[2] == 1 and (a[0] == "closeModal" or a[0] == "c3retreatNo" or a[0] == "eventBack"):
					Kit.play("ui_cancel"); C.act(a[0], a[1]); get_viewport().set_input_as_handled(); return
		var n = e.keycode - KEY_1
		if n < 0 or n >= 9: n = e.keycode - KEY_KP_1   # the keypad's digits too, as on the map (item 26)
		if n >= 0 and n < 9:
			var on = acts.filter(func(a): return a[2] == 1)
			if n < on.size():
				Kit.play(Kit.press_cue(cue_role(str(on[n][0]), "quiet"))); C.act(on[n][0], on[n][1]); get_viewport().set_input_as_handled()
