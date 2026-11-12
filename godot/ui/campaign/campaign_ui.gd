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

const GS = preload("res://ui/theme/glass_shell.gd")
const View = preload("res://campaign/campaign_view.gd")   # read-only views of the run for the screens (audit pass 1, finding 12)
# Lime Tactical (R149, issue #344): the palette is glass_shell.gd's; these names stay so every screen keeps its meanings
# (ui_style.md section 5). No colour value is written in this file: a new one goes into glass_shell.gd first.
const INK := GS.INK
const IRON := GS.IRON
const IRON2 := GS.IRON2
const IRON3 := GS.IRON3
const BONE := GS.BONE
const BONE2 := GS.BONE2
const BONE3 := GS.BONE3
const GILT := GS.GILT            # neon lime: the next action only
const GILT2 := GS.GILT2
const VERD := GS.VERD
const BLOOD := GS.BLOOD
const EMBER := GS.EMBER
const ALERT := GS.ALERT
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
var ai_level := "veteran"             # the battle setting the shell uses (godot/main settings "ai"); the map's danger bands follow it
var map_quality := "high"             # the 3D map's detail, "high" or "low" (R51): from the game's Graphics setting, then the map's own toggle
var modal_box: Control
var toast_box: VBoxContainer
var theme_main: Theme
var extra_title_buttons: Array = []   # [label, Callable] added under the title menu by the game shell (skirmish, settings ...)
var hide_on_battle := false           # the game shell shows its own battle scene on the battle page
var _acts: Array = []                 # the buttons the current screen allows
var _modal_acts: Array = []
var _dirty := false
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
# Lime Tactical (R149; ui_style.md, section 8 for the campaign): every piece comes from godot/ui/theme/glass_shell.gd.
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
	t.set_color("font_focus_color", "Button", BONE)
	t.set_font_size("font_size", "TooltipLabel", px(15))
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
	if wrap and text.length() > 30:   # short labels keep their natural width (a wrapping label in a row would shrink to nothing)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
func num(text: String, size: float = 17, col: Color = BONE, bold: bool = true) -> Label:   # a number that decides something: Azeret Mono
	return lbl(text, size, col, font_num_b if bold else font_num, false)
func rich(bb: String, size: float = 17) -> RichTextLabel:
	var r = RichTextLabel.new(); r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false; r.text = bb
	r.add_theme_font_size_override("normal_font_size", px(size)); r.add_theme_font_size_override("bold_font_size", px(size)); r.add_theme_font_size_override("mono_font_size", px(size))
	r.mouse_filter = Control.MOUSE_FILTER_PASS; r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r
func rich_inline(bb: String, size: float = 15) -> RichTextLabel:   # one line, as wide as its text (for flow rows)
	var r = rich(bb, size); r.autowrap_mode = TextServer.AUTOWRAP_OFF; r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
func c(text: String, col: Color) -> String: return "[color=" + hexs(col) + "]" + text + "[/color]"
func n_(text: String, col: Color = BONE) -> String: return "[code]" + c(text, col) + "[/code]"   # a number in rich text: the number face
# a page or dialog title: Chakra Petch Bold caps, tracked (GS.display); the size argument keeps the old scale (x 0.7)
func gothic(text: String, size: float = 52) -> Label: return lbl(text.to_upper(), size * 0.7, BONE, font_goth, true)
func _readout(label: String, value: String, col: Color, right: bool = false) -> Control:   # a big number: Azeret Mono, its label in caps
	var v = vbox(0); var a = caps(label, 12, BONE3); var b = num(value, 28, col)   # label 12: the text floor (ui_spec.md 4.3)
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
# bar (a core's colour, VERD for calm information, lime for the lit block). A box filled with its own border colour is a tag.
func panel(border: Color = IRON3, bgc: Color = IRON, pad: float = 14) -> PanelContainer:
	var p = PanelContainer.new()
	var sb: StyleBoxFlat
	if bgc.a > 0.9 and bgc == border: sb = GS.tag(k, border, true); sb.content_margin_left = px(pad); sb.content_margin_right = px(pad)
	elif border == IRON3 or border.a == 0.0: sb = GS.well(k, Color(0, 0, 0, 0), pad, pad * 0.7)
	elif border == GILT: sb = GS.well(k, GILT, pad, pad * 0.7)   # the lit block
	else: sb = GS.well(k, Color(0, 0, 0, 0), pad, pad * 0.7, border)
	p.add_theme_stylebox_override("panel", sb); return p
# A card: a well; the selected one is lit (lime edge all round), nothing else lights a well.
func card(sel: bool = false, width: float = 300) -> Array: # [PanelContainer, VBoxContainer]
	var p = PanelContainer.new(); p.custom_minimum_size.x = px(width)
	p.add_theme_stylebox_override("panel", GS.well(k, GILT if sel else Color(0, 0, 0, 0), 14, 12))
	var v = vbox(6); p.add_child(v); return [p, v]
# One panel per region (ui_style.md 2): the matte slab with its chamfers, scanline, bevel and brackets.
func shell_panel(pad: float = 14) -> PanelContainer:
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", GS.shell(k, pad)); GS.frame_marks(p, k); return p
# A section head inside a panel: lime caps, tracked (GS.caps), as the battle HUD's "1 MOVE"
func sec_head(t: String, right: String = "", right_col: Color = BONE3) -> Control:
	var h = hbox(8); h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(lbl(t.to_upper(), 13, GILT, font_caps, false))
	if right != "": h.add_child(spacer()); h.add_child(lbl(right, 13, right_col, font_caps, false))
	return h
# A small square tag (UP, NEMESIS, ELITE, LOCKED): filled for a state, outlined for a side or a kind
func tagl(t: String, col: Color, filled: bool = false, size: float = 12) -> Label:
	var l = lbl(t.to_upper(), size, GS.ON_GILT if filled and col == GILT else (INK if filled else col), font_caps, false)
	l.add_theme_stylebox_override("normal", GS.tag(k, col, filled)); l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l
# A key cap beside an action ("1", "Esc"): the key always shows next to what it does
func keycap(key: String, on_gilt: bool = false) -> Label:
	var l = lbl(key, 12 if key.length() > 2 else 13, GS.ON_GILT if on_gilt else GS.KEY_FG, font_num_b, false)
	l.add_theme_stylebox_override("normal", GS.keycap_on_gilt(k) if on_gilt else GS.keycap(k))
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
# primary: a lit button (dark fill, lime edge, lime words), for a step's own confirm when the screen's finishing action is
# the filled lime slab (fin). Only one filled lime button at a time (R148).
func abtn(text: String, act: String, arg = "", primary: bool = false, small: bool = false, list = null) -> Button:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = Button.new(); b.text = text; b.disabled = found[2] == 0; b.focus_mode = Control.FOCUS_ALL
	if small: b.add_theme_font_size_override("font_size", px(15))
	if primary:
		var lb = GS.lit_boxes(k)
		for st in ["normal", "hover", "pressed", "disabled"]: b.add_theme_stylebox_override(st, lb[st])
		for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]: b.add_theme_color_override(fc, GILT)
	var aa = found[1]
	b.pressed.connect(func(): C.act(act, aa))
	return b
# The screen's finishing action (Continue, Confirm, Plot a course, Done, Leave shipyard): the one filled lime slab, its label
# in action caps, its key cap after the label in a dialog (ui_style.md 7). It sits at the bottom right of its screen or dialog.
func fin(text: String, act: String, arg = "", list = null) -> Button:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = Button.new(); b.disabled = found[2] == 0; b.focus_mode = Control.FOCUS_ALL; b.set_meta("finish", true)
	var fb = GS.finish_boxes(k)
	for st in ["normal", "hover", "pressed", "disabled"]: b.add_theme_stylebox_override(st, fb[st])
	var h = hbox(10); h.alignment = BoxContainer.ALIGNMENT_CENTER; h.mouse_filter = Control.MOUSE_FILTER_IGNORE; h.set_anchors_preset(Control.PRESET_FULL_RECT)
	var l = lbl(text.to_upper(), 17, BONE3 if b.disabled else GS.ON_GILT, font_act, false); l.size_flags_vertical = Control.SIZE_SHRINK_CENTER; h.add_child(l)
	var kk = _key_for(list, act, arg)
	if kk != "": var kc = keycap(kk, true); kc.add_theme_color_override("font_color", BONE3 if b.disabled else GS.ON_GILT); h.add_child(kc)
	b.add_child(h)
	# the width from the faces' own metrics (a container's minimum size is not known before it is drawn; hud.gd _kb_width)
	var tw = font_act.get_string_size(text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, px(17)).x
	if kk != "": tw += font_num_b.get_string_size(kk, HORIZONTAL_ALIGNMENT_LEFT, -1, px(13)).x + px(10) + px(10) + px(10)
	b.custom_minimum_size = Vector2(ceil(tw) + px(24) + px(28), px(46))
	GS.gilt_sheen(b, k)
	var aa = found[1]
	b.pressed.connect(func(): C.act(act, aa))
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
	var n = GS.well(k, GILT if sel else Color(0, 0, 0, 0), 12, 9, bar_c)
	var h = GS.well(k, Color(GILT, 0.55), 12, 9, bar_c); h.shadow_size = 0
	b.setup(n, h, h, off)
	b.ring = GS.focus_ring(k)
	var row = hbox(10); row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v = vbox(2); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if tag_t != "": v.add_child(lbl(tag_t.to_upper(), 12, BONE3 if off else tagcol, font_caps))
	v.add_child(lbl(title, 18, BONE3 if off else (GILT if sel else BONE), font_semi))
	if small != "": v.add_child(lbl(small, 15, BONE3 if off else BONE2))
	for l in v.get_children():
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(v)
	if off: row.add_child(tagl("Locked", BONE3))
	else:
		var kk = _key_for(list, act, arg)
		if kk != "": row.add_child(keycap(kk))
	b.add_child(row)
	var aa = found[1]
	b.pressed.connect(func(): C.act(act, aa))
	return b
func add(parent: Node, child) -> void:
	if child != null: parent.add_child(child)
func _toast(msg: String) -> void:   # a strip with a calm VERD bar (ui_style.md 3): toasts here are news, not warnings
	var p = PanelContainer.new(); var sb = GS.strip(k, VERD); sb.content_margin_left = px(14); sb.content_margin_right = px(18); sb.content_margin_top = px(8); sb.content_margin_bottom = px(8)
	p.add_theme_stylebox_override("panel", sb); p.add_child(lbl(msg, 16, BONE)); p.custom_minimum_size.x = px(min(900, 260 + msg.length() * 7))
	toast_box.add_child(p)
	while toast_box.get_child_count() > 3: var o = toast_box.get_child(0); toast_box.remove_child(o); o.queue_free()
	var tw = create_tween(); tw.tween_interval(clamp(msg.length() * 0.06, 2.2, 9.0)); tw.tween_property(p, "modulate:a", 0.0, 0.4); tw.tween_callback(p.queue_free)
# ---------------- render ----------------
func render() -> void:
	for ch in page_box.get_children(): ch.queue_free()
	for ch in modal_box.get_children(): ch.queue_free()
	var pg = C.page; _acts = pg["acts"]
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
		"admiral": body = _wrap_page(_admiral())
		"aspect": body = _wrap_page(_aspect())
		"map": body = _map()
		"fleet": body = _wrap_page(_fleet(pg["data"]))
		"shipyard": body = _wrap_page(_shipyard())
		"battle":   # the test battle's panel; a dialog over the battle (the rewards) shows over the scene alone, as in the game shell
			body = _battle_stub(pg["data"]) if (C.modal_d == null or C.modal_d["kind"] == "retreat") else Control.new()
		"legacy": body = _wrap_page(_legacy())
		"lineage": body = _wrap_page(_lineage(pg["data"]["id"]))
		"help": body = _wrap_page(_help(), 820)
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
	elif modal == "drydock": ids = ["c_shipyard"]
	elif modal == "":
		match kind:
			"map":
				var n = C.findNode(pos) if pos != "" else null
				ids = ["c_shipyard"] if n != null and n.get("type") == "field" else ["c_map", "c_clock"]
			"shipyard": ids = ["c_shipyard"]
			"end": ids = ["c_loss"]
			"admiral":
				# Automatic mastery is not spendable experience. Keep this hook ready for the skill-tree port.
				if C.has_method("admiralXPToSpend") and float(C.call("admiralXPToSpend", C.picked_admiral)) > 0: ids = ["c_tree"]
	teaching.open_screen(kind + "|" + sector + "|" + pos + "|" + modal, ids)

func _focus_first() -> void:
	# the map page: the keys go to the chart (arrows, Enter, zoom), so no button wears a ring when the screen opens;
	# with a slide-over open they go to its Close
	if modal_box.get_child_count() == 0 and C.page.get("kind") == "map" and use_3d_map and map3d != null and map3d.visible:
		if _overlay == "": map3d.grab_focus()
		else: get_viewport().gui_release_focus()   # a slide-over: Esc or Close shuts it, Tab walks its buttons
		return
	var host = modal_box if modal_box.get_child_count() > 0 else page_box
	var b = _first_button(host)
	if b != null: b.grab_focus()
func _first_button(n: Node) -> Control:
	for ch in n.get_children():
		if (ch is Button or ch.get_script() == ChoiceScript) and not ch.disabled and ch.visible: return ch
		var r = _first_button(ch)
		if r != null: return r
	return null
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
		"fleet": b = fin("Done", "backShipyard" if C.page["data"].get("back") == "shipyard" else "backMap")
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
	var title_txt = "VOIDSWORN"   # the game's name from G2's brand.gd (one place for the title, R59)
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
		var pl = lbl("Playtest: everything unlocked (all admirals, carriers, battleships and hull variants). " + ("On." if on else "Off: unlock them with renown."), 16, GILT if on else BONE3)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(pl)
		var pb = Button.new(); pb.text = "Switch playtest unlocks " + ("off" if on else "on"); pb.focus_mode = Control.FOCUS_ALL
		pb.add_theme_font_size_override("font_size", px(15))
		pb.pressed.connect(func(): C.set_playtest_all(not C.playtestAll()); C.titleScreen())
		var pc = CenterContainer.new(); pc.add_child(pb); v.add_child(pc)
	var st = C.META["stats"]; var best = float(C.z0(st.get("best"))); var wins = int(C.z0(st.get("wins")))
	if best > 0:
		var t = "Best: sector " + C.roman(min(3, best)) + ((" · " + str(wins) + " full victor" + ("ies" if wins > 1 else "y")) if wins > 0 else "")
		var r = lbl(t, 17, GILT); r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(r)
	cc.add_child(v); return cc

# ---------------- admiral and run options ----------------
func _admiral() -> Control:
	var v = vbox(10)
	v.add_child(gothic("Choose your faction"))
	v.add_child(lbl("Your faction sets your ships and shipyards. Each run you face three of the other five, in a random order, with rival raiders along the way.", 18, BONE2))
	var fr = flow(8)
	for f in C.RUN_FACTIONS:
		var b = abtn(C.FACTIONS[f]["n"], "pickFaction", f, C.picked_faction == f)
		add(fr, b)
	v.add_child(fr)
	v.add_child(gothic("Choose your admiral"))
	v.add_child(lbl("Your admiral sets the fleet you start with and a doctrine that shapes every battle.", 18, BONE2))
	var cards = flow()
	for id in C.page["data"]["mine"]:
		var a = C.ADMIRALS[id]; var un = C.admiralOwned(id)   # R1 (PROG-6): bought, or free (each faction's first admiral)
		var cv = card(C.picked_admiral == id, 330); var col = cv[1]
		var face = _face(id)
		if face != null:   # godot/portraits: the painting when one is picked, else the crest
			var hr = hbox(10); var tr = TextureRect.new(); tr.texture = face; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.custom_minimum_size = Vector2(px(84), px(84)); hr.add_child(tr)
			var nv = vbox(2); nv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; nv.add_child(lbl(_admiral_title(id), 20, BONE, font_semi)); nv.add_child(lbl(a["doc"], 16, GILT)); hr.add_child(nv); col.add_child(hr)
		else: col.add_child(lbl(_admiral_title(id), 20, BONE, font_semi)); col.add_child(lbl(a["doc"], 16, GILT))
		col.add_child(lbl(a["d"], 16, BONE2))
		col.add_child(_mastery_bar(id))
		if C.LINEAGE_TREES.has(id): add(col, abtn("View lineage tree", "lineage", id))
		var fleet = []
		for t in a["start"]: fleet.append(C.HULLS[C.equivHull(t, C.picked_faction)]["n"])
		col.add_child(rich(c("Starting fleet:", BONE3) + " " + esc(", ".join(PackedStringArray(fleet))), 16))
		if C.jt(a.get("cmd")):
			col.add_child(rich(c("Command:", BONE3) + " [b]" + c(esc(a["cmd"]["n"]), GILT) + "[/b]. " + esc(_cmd_text(a["cmd"], C.picked_faction)) + " " + c("Gets stronger each round you hold it.", BONE3), 16))
		if un: add(col, abtn("Selected" if C.picked_admiral == id else "Select", "pickAdmiral", id, C.picked_admiral == id))
		else:   # R1 (PROG-2): unlock it here with renown; the card reads locked (dimmed), the button stays bright and gilt when you can afford it
			for ch in col.get_children(): ch.modulate.a = 0.55
			var can = float(C.z0(C.META.get("renown"))) >= float(C.z0(a.get("cost")))
			var ub = abtn("Unlock for " + C.numstr(a.get("cost")) + " renown", "buyAdmiral", id, can)
			if ub != null: col.add_child(ub)
			else: col.add_child(lbl("Unlock for " + C.numstr(a.get("cost")) + " renown", 15, BONE2))
		cards.add_child(cv[0])
	v.add_child(cards)
	_story_line(v)
	v.add_child(_run_options())
	var row = hbox(); add(row, abtn("Launch the " + C.runWord(C.picked_faction), "startRun", "", true)); add(row, abtn("Back", "title")); v.add_child(row)
	return v
# ---------------- story layer hooks (godot/story/README.md, hook 3): all guarded, nothing here changes campaign state ----------------
func _story() -> Node:
	var p = get_parent()
	return p.get_node_or_null("Story") if p != null else null
func _story_text() -> String:
	var st = _story()
	return str(st.campaign_line()) if st != null else ""
func _story_line(v: Control) -> void:
	var t = _story_text()
	if t != "": v.add_child(lbl(t, 17, VERD))   # the admiral's voice: calm information, not an action (lime is the next action only)
func _admiral_title(id) -> String:   # the admiral's name with the latest earned title
	var st = _story()
	if st != null:
		var t = str(st.titled_name(str(id)))
		if t != "": return t
	return str(C.ADMIRALS[id]["n"])
var _faces := {}
func _face(id) -> Texture2D:
	if not ResourceLoader.exists("res://portraits/portraits.gd"): return null
	if not _faces.has(id): _faces[id] = load("res://portraits/portraits.gd").face(str(id))
	return _faces[id]
func _cmd_text(cmd, fac) -> String:
	var t = C.CMD_TEXT.get(cmd["id"])
	return str(t.get(fac, "")) if t != null else ""
func _mastery_bar(id) -> Control:
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
	v.add_child(rich(c(label, GILT) + " " + c(right, BONE3), 14))
	var b = GS.seg_bar(k, f, VERD, GS.BAR_TRACK, 6, 10); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v.add_child(b)   # progress, not an action: VERD
	v.add_child(lbl(("Heir: 50%" if C.META["heirs"].get(C.or_(C.ADMIRALS[id].get("fac"), "voidsworn")) == id else "Shadow: 25%") + " XP while benched", 13, BONE3))
	return v
func _run_options() -> Control:
	var v = vbox(10)
	v.add_child(gothic("Run options", 52))
	var cards = flow(); var o = C.page["data"]["opts"]; var id = C.picked_admiral; var a = C.ADMIRALS[id]
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
		cv3[1].add_child(rich("[b]Heat " + c(C.numstr(hl), GILT) + "[/b] " + c("+" + C.numstr(hl * 10) + "% renown" + ((" · best win with this faction: Heat " + C.numstr(best)) if best > 0 else ""), BONE3), 19))
		cv3[1].add_child(lbl("Optional rules that make the run harder. Pick any.", 15, BONE3))
		for kk in C.HEAT.keys():
			var h = C.HEAT[kk]
			add(cv3[1], choice(h["n"] + "  +" + C.numstr(h["w"]), h["d"], "optHeat", kk, null, null, "", BONE2, C.run_opt["heat"].has(kk)))
		cards.add_child(cv3[0])
	else:
		var cv4 = card(false, 380); cv4[0].modulate.a = 0.55; cv4[1].add_child(lbl("Heat", 20, BONE, font_semi))
		cv4[1].add_child(lbl("Lose a run to unlock Heat: optional rules that make runs harder and pay more renown.", 16, BONE3)); cards.add_child(cv4[0])
	v.add_child(cards)
	return v

# ---------------- aspect ----------------
func _aspect() -> Control:
	var v = vbox(10); var d = C.page["data"]; var f = d["flag"]
	v.add_child(gothic("Choose your flagship's aspect"))
	v.add_child(rich(c("The ", BONE2) + "[b]" + esc(f["name"]) + "[/b]" + c(" (" + esc(C.HULLS[f["tpl"]]["n"]) + ") carries your flag. Pick one aspect for it; it lasts the whole run, and passes to your next-largest ship if the flagship falls.", BONE2), 18))
	var cards = flow()
	for kk in d["opts"]:
		var cv = card(false, 320); cv[1].add_child(lbl(C.ASPECTS[kk]["n"], 20, BONE, font_semi)); cv[1].add_child(lbl(C.ASPECTS[kk]["d"], 16, BONE2))
		add(cv[1], abtn("Take this aspect", "pickAspect", kk, true)); cards.add_child(cv[0])
	v.add_child(cards)
	var R = C.RUN
	if C.jt(R.get("giftBoon")):
		var gb = R["giftBoon"]; v.add_child(rich(c("A gift from " + esc(C.PATRONS[C.BOONS[gb]["p"]]["n"]) + ", now Synced with you: [b]" + esc(C.BOONS[gb]["n"]) + "[/b].", GILT), 17))
	if R.get("heat") is Array and R["heat"].size() > 0:
		var hn = []
		for kk in R["heat"]: hn.append(C.HEAT[kk]["n"])
		v.add_child(lbl("Heat " + C.numstr(C.heatLevel(R["heat"])) + ": " + ", ".join(PackedStringArray(hn)) + ".", 17, BLOOD))
	var ps = []
	for p in R["patrons"]: ps.append("[b]" + c(esc(C.PATRONS[p]["n"]), Color(C.PATRONS[p]["col"])) + "[/b] (" + esc(str(C.PATRONS[p]["theme"]).to_lower()) + ")")
	v.add_child(rich(c("Cores in range of this " + C.runWord() + ": ", BONE3) + "; ".join(PackedStringArray(ps)) + c(". Win battles carrying their signal to earn their protocols.", BONE3), 16))
	return v

# ---------------- the sector map: the Briefing layout (Ryan's pick, Nov 10 2026, FINDINGS R165) ----------------
# The first spec (archived) is docs/archive/briefs/campaign_map_briefing.md; the live look is contrib/opus/briefs/campaign_rail_orders_sheet.md; the first picture is contrib/opus/ui_map_design/map_option_C_briefing.jpg.
# Left: one flat column, 480 wide (the sector, the routes you can take as numbered rows, the one filled lime button, the
# Nemesis in a few lines, the fleet). Right: the real 3D chart with plain words on it (map3d.gd). Two colours on top of the
# sage text: lime is the next action and the next jumps, ALERT red is the Nemesis. Everything else the old screen said is one
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
func caps(text: String, size: float = 12, col: Color = BONE3) -> Label: return lbl(text.to_upper(), size, col, font_caps, false)
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
func tbtn(text: String, size: float, lh: float, cb: Callable, tip_t: String = "") -> Control:
	var w = Control.new()
	var b = Button.new(); b.text = text; b.alignment = HORIZONTAL_ALIGNMENT_LEFT; GS.plain_button(b, k, maxf(17, size), GS.sheet_body())
	b.add_theme_color_override("font_color", GS.TEXT2); b.add_theme_color_override("font_hover_color", GS.TEXT); b.add_theme_color_override("font_focus_color", GS.TEXT)
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
	top.add_child(tbtn("Map key", 17, 24, func(): _open_overlay("key"), "What the marks mean, this sector, your run, the controls."))
	if not _find(_acts, "saveQuit", "").is_empty(): top.add_child(tbtn("Save and quit", 17, 24, func(): C.act("saveQuit", "")))
	wrap.add_child(top)
	var P = View.purse(C)
	var purse = _baseline_row([["Credits", GS.sheet_body(), 17, GS.TEXT2], [12], [C.numstr(P["credits"]), font_num_b, 28, GS.TEXT], [48],
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
	var short = {"Ion season": "shields recharge 25% slower.", "Dark sector": "nebula hexes give -15 to hit.", "Wreck belt": "salvage pays 15% more.", "War zone": "reinforcements; fights pay 20% more.", "Scarcity": "repairs restore 25% less."}
	return str(S["cond_n"]) + ": " + str(short.get(S["cond_n"], S["cond_d"])) if S["cond_n"] != "" else ""

func _briefing_column() -> Control:
	var H = View.header(C); var S = View.sector_notes(C); var N = View.nemesis(C); var fleet = View.fleet_rows(C)
	var cw = COL_W - COL_PAD * 2.0
	var col = MarginContainer.new(); col.name = "OrdersSheet"; col.mouse_filter = Control.MOUSE_FILTER_PASS
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
	upper.add_child(_sheet_words("Held by " + "the " + str(S["holder"]).trim_prefix("The "), 21, GS.TEXT, true))
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
	var fleet_tip = "Captains, perks, refits, the hold and your faction purchase."
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
	return str(short.get(r["name"], str(r["objective"]).split(". ")[0].trim_suffix(".") + ".")) if r["objective"] != "" else ""

func _route_row(r: Dictionary) -> Control:
	var cw = COL_W - COL_PAD * 2.0; var on = r["id"] == picked
	var v = vbox(0); var b = Button.new(); b.name = "Route" + str(r["num"]); b.focus_mode = Control.FOCUS_ALL; b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for st in ["normal", "hover", "pressed", "disabled", "focus"]: b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
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
		var note = (str(dg.get("band", "")) + " fight." if r["fight"] else "No fight")
		if r["fight"] and r["reward"] != "": note += " Pays " + str(r["reward"])
		tv.add_child(_sheet_words(note, 18, GS.TEXT2))
	var row_height = 132 if on else (54 if _routes.size() >= 4 else 62)
	b.custom_minimum_size.y = maxf(px(row_height), tv.get_combined_minimum_size().y)
	# Children get their final widths before the minimum height is used, including a wrapped long name.
	tv.minimum_size_changed.connect(func(): if is_instance_valid(b): b.custom_minimum_size.y = maxf(px(row_height), tv.get_combined_minimum_size().y))
	var id = str(r["id"])
	b.pressed.connect(func(): pick_route(id)); b.focus_entered.connect(func(): pick_route(id))
	b.gui_input.connect(func(e: InputEvent):
		var enter = e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER]
		var dbl = e is InputEventMouseButton and e.pressed and e.double_click and e.button_index == MOUSE_BUTTON_LEFT
		if enter or dbl: pick_route(id); b.accept_event(); _jump())
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
	var text = "JUMP TO " + str(cur.get("name", "")).to_upper(); var fs = 34.0
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
	return b
func route_num(id: String) -> int:   # the number a next jump wears in the list and on the map (0: not a next jump)
	for r in _routes:
		if r["id"] == id: return int(r["num"])
	return 0
# pick a next jump (a row click, its number key, or its stop on the map): the row lights, the button names it
func pick_route(id: String) -> void:
	if id == picked or not _routes.any(func(r): return r["id"] == id): return
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
	for child in _rail_host.get_children(): _rail_host.remove_child(child); child.queue_free()
	_rail_host.add_child(_briefing_column())
	if restore != "":
		for r in _rows:
			if r["id"] == restore: r["btn"].grab_focus()
func _jump() -> void:
	if picked == "" or C.modal_d != null or _overlay != "" or _find(_acts, "enterNode", picked).is_empty(): return
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
	var hp = C.numstr(s["hp"]) + " / " + C.numstr(s["max_hp"])
	var hw = ceil(font_num.get_string_size(hp, HORIZONTAL_ALIGNMENT_LEFT, -1, px(19)).x)
	var available = COL_W - COL_PAD * 2 - 16 - hw / k - (26 if s["flagship"] else 0)
	h.add_child(_sheet_name(s["name"], 28, available, 3))
	var figures = _baseline_row([[C.numstr(s["hp"]), font_num, 19, (HULL_LOW if float(s["frac"]) < 0.35 else HULL) if float(s["frac"]) < 0.999 else GS.TEXT], [" / " + C.numstr(s["max_hp"]), font_num, 19, GS.TEXT]], rh)
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
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed: _close_overlay())
	host.add_child(shade)
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", GS.column(k, left_at >= 0.0)); p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.anchor_bottom = 1.0
	if left_at >= 0.0: p.offset_left = px(left_at); p.offset_right = px(left_at + OVER_W)
	else: p.anchor_left = 1.0; p.anchor_right = 1.0; p.offset_left = -px(OVER_W); p.offset_right = 0
	var m = MarginContainer.new()
	for side in ["left", "right"]: m.add_theme_constant_override("margin_" + side, px(COL_PAD))
	m.add_theme_constant_override("margin_top", px(40)); m.add_theme_constant_override("margin_bottom", px(32))
	m.add_child(body); p.add_child(m); host.add_child(p)
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
	var LEG = {"battle": "a fight, pays its reward", "elite": "veteran fleet, drops " + term("relic"), "shipyard": "buy, repair, upgrade", "drydock": "free repairs", "field": "every ship patches 20%", "event": "anything can happen", "boss": "ends the sector"}
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
		body.add_child(_over_text("[b]Heat " + C.numstr(S["heat_level"]) + "[/b] " + "; ".join(PackedStringArray(hs)) + ".", 17))
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
	r0.add_child(name_label); r0.add_child(lbl("MK " + C.roman(s["mk"]), 13, BONE2, font_caps, false)); v.add_child(r0)
	v.add_child(lbl(t["n"], 16, BONE2))
	var r1 = hbox(); r1.add_child(lbl("Hull " + C.numstr(s["hp"]) + "/" + C.numstr(d["maxHp"]), 15)); r1.add_child(spacer()); r1.add_child(lbl(C.numstr(t["cp"]) + " CP", 15, BONE3, null, false)); v.add_child(r1)
	v.add_child(bar(float(s["hp"]) / float(d["maxHp"])))
	v.add_child(rich("[b]" + c("Shields", BONE2) + "[/b] " + C.numstr(d["shMax"]) + ", +" + C.numstr(d["regen"]) + "/turn   [b]" + c("Armor", BONE2) + "[/b] " + C.pct(d["armor"]) + "\n[b]" + c("Speed", BONE2) + "[/b] " + C.numstr(d["speed"]) + "   [b]" + c("Turns", BONE2) + "[/b] " + C.numstr(d["turns"]) + "   [b]" + c("Evasion", BONE2) + "[/b] " + C.numstr(d["ev"]), 15))
	if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]): v.add_child(rich(c(esc(C.ABILITIES[t["ab"]]["n"]) + ".", VERD) + " " + c(esc(C.ABILITIES[t["ab"]]["d"]), BONE3), 15))
	for w in d["weapons"]:
		var arc = "Turret" if w["arc"] == "T" else str(C.ARC_NAME.get(w["arc"], w["arc"]))
		v.add_child(lbl(str(w["n"]) + "  " + arc + "  " + C.numstr(w["shots"]) + "×" + C.numstr(w["dmg"]) + ", range " + C.numstr(w["r"]) + ((", reload " + C.numstr(w["cd"])) if C.jt(w.get("cd")) else ""), 14, BONE3))
	var sect = vbox(4); sect.add_child(HSeparator.new())
	sect.add_child(lbl(C.rankName(cap) + " " + str(cap["name"]), 16, BONE, font_semi))
	var nx = C.RANK_XP[int(cap["rank"]) + 1] if int(cap["rank"]) + 1 < C.RANK_XP.size() else null
	if nx != null:
		var nxt = cap.duplicate(); nxt["rank"] = float(cap["rank"]) + 1
		sect.add_child(lbl(C.numstr(cap["xp"]) + "/" + C.numstr(nx) + " experience to " + C.rankName(nxt), 14, BONE3))
	else: sect.add_child(lbl(C.numstr(cap["xp"]) + " experience, highest rank", 14, BONE3))
	if cap["perks"].size() > 0:
		var pf = flow(4)
		for p in cap["perks"]:
			var pl = lbl(str(C.PERKS[p]["n"]), 13, VERD, null, false); pl.tooltip_text = str(C.PERKS[p]["d"]); pl.mouse_filter = Control.MOUSE_FILTER_PASS; pf.add_child(pl)
		sect.add_child(pf)
	else: sect.add_child(lbl("No perks yet.", 14, BONE3))
	add(sect, abtn("Choose promotion perk", "promote", s["uid"], true, true))
	v.add_child(sect)
	var rs = vbox(4); rs.add_child(HSeparator.new()); rs.add_child(sec_head("Refits"))
	for i in range(int(C.z0(t.get("slots")))):   # R1: hulls without refit slots (sector flagships) show none
		if i < s["mods"].size() and C.jt(s["mods"][i]):
			var m = s["mods"][i]; var rr = hbox(6)
			rr.add_child(rich("[b]" + esc(C.modName(m)) + "[/b] " + c(esc(C.MODULES[m]["d"]), BONE3), 14))
			if refit: add(rr, abtn("Remove", "unequip", s["uid"] + ":" + str(i), false, true))
			rs.add_child(rr)
		else: rs.add_child(lbl("Empty refit slot", 14, BONE3))
	v.add_child(rs)
	if extra.size() > 0:
		var ex = flow(6)
		for b in extra: add(ex, b)
		v.add_child(HSeparator.new()); v.add_child(ex)
	return cv[0]
func _fleet(d: Dictionary) -> Control:
	var v = vbox(10)
	var head = hbox(); head.add_child(gothic("Fleet")); head.add_child(spacer())
	var st = _story()
	if st != null and C.flagshipOf() != null:   # story layer: name your flagship
		var rb = Button.new(); rb.text = "Rename flagship"; rb.focus_mode = Control.FOCUS_ALL; rb.pressed.connect(func(): st.open_rename()); head.add_child(rb)
	v.add_child(head)   # Done is the finishing action, fixed at the bottom right of the screen (_page_finish)
	v.add_child(lbl("Refits can be moved between ships freely. Mark upgrades and repairs happen at shipyards and drydocks.", 18, BONE2))
	var R = C.RUN
	var FA = View.faction_action(C)
	if not FA.is_empty(): v.add_child(_action_line(FA))
	if R["inventory"].size() > 0:
		v.add_child(sec_head("In the hold"))
		var inv = flow()
		for i in range(R["inventory"].size()):
			var m = R["inventory"][i]; var cv = card(false, 300)
			cv[1].add_child(lbl(C.modName(m), 20, BONE, font_semi)); cv[1].add_child(lbl(C.MODULES[m]["d"], 16, BONE2))
			var fr = flow(6); var any = false
			for s in R["fleet"]:
				var b = abtn("Fit to " + str(s["name"]), "equip", str(i) + ":" + s["uid"], false, true)
				if b != null: fr.add_child(b); any = true
			if not any: fr.add_child(lbl("No free compatible slot. Remove a refit first.", 14, BONE3))
			cv[1].add_child(fr); inv.add_child(cv[0])
		v.add_child(inv)
	var cards = flow()
	for s in R["fleet"]: cards.add_child(_ship_card(s, true))
	v.add_child(cards)
	return v
func _shipyard() -> Control:
	var v = vbox(10); var R = C.RUN; var n = C.page["data"]["node"]; var st = n["stock"]; var pm = C.priceMult(); var cp = C.fleetCP()
	var head = hbox(); head.add_child(gothic("Shipyard")); head.add_child(spacer())
	head.add_child(_readout("Credits", C.numstr(R["credits"]), BONE, true)); var gp = Control.new(); gp.custom_minimum_size.x = px(28); head.add_child(gp); head.add_child(_readout("Command points", C.numstr(cp) + "/" + C.numstr(R["cpCap"]), BONE, true))
	var rb = abtn("Refits", "yardFleet")
	if rb != null: rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER; head.add_child(rb)
	v.add_child(head)   # Leave shipyard is the finishing action, fixed at the bottom right (_page_finish)
	v.add_child(lbl("Repairs cost 1 credit per 2 hull. A Mark upgrade adds 20% hull and shields and 15% damage. New hulls come with a fresh lieutenant.", 18, BONE2))
	var allMiss = 0.0
	for s in R["fleet"]: allMiss += float(C.derive(s)["maxHp"]) - float(s["hp"])
	add(v, abtn(("Repair entire fleet for " + C.numstr(ceil(allMiss / 2.0 * pm))) if allMiss > 0 else "Fleet fully repaired", "repairAll"))
	var cards = flow()
	for s in R["fleet"]:
		var d = C.derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var rc = ceil(miss / 2.0 * pm); var mc = C.mkCost(s); var sell = C.prizeScrap(s["tpl"])   # R1 (TXT-8): what the button pays; hulls without a shop price too
		var ex = [abtn(("Repair " + C.numstr(miss) + " for " + C.numstr(rc)) if miss > 0 else "Fully repaired", "repair", s["uid"], false, true),
			abtn(("Mk " + C.roman(float(s["mk"]) + 1) + " for " + C.numstr(mc)) if float(s["mk"]) < 3 else "Max Mark", "upgradeMk", s["uid"], false, true),
			abtn("Decommission (+" + C.numstr(sell) + ")", "sellShip", s["uid"], false, true)]
		cards.add_child(_ship_card(s, false, ex))
	v.add_child(cards)
	v.add_child(sec_head("Hulls for sale"))
	var hs = flow()
	for h in st["hulls"]:
		var t = C.HULLS[h]; var cost = C.jsround(float(t["cost"]) * pm); var fits = cp + float(t["cp"]) <= float(R["cpCap"])
		var uniq = C.jt(t.get("unique")) and R["fleet"].any(func(s): return s["tpl"] == h)
		var cv = card(false, 320); var cvv = cv[1]
		cvv.add_child(rich("[b]" + esc(t["n"]) + "[/b]" + (" " + c("Variant", VERD) if C.jt(t.get("variant")) else ""), 20))
		if C.jt(t.get("variant")): cvv.add_child(lbl(C.HULL_VARIANTS[t["variant"]]["d"], 15, VERD))
		cvv.add_child(lbl(C.numstr(t["cp"]) + " CP. Hull " + C.numstr(t["hp"]) + ", shields " + C.numstr(t["sh"]) + ", speed " + C.numstr(t["sp"]) + ", turns " + C.numstr(t["tn"]) + ".", 15, BONE2))
		var ws = []
		for e in t["w"]: ws.append(str(C.W_[e[0]]["n"]) + " (" + ("turret" if e[1] == "T" else str(C.ARC_NAME.get(e[1], e[1])).to_lower()) + ")")
		cvv.add_child(lbl(", ".join(PackedStringArray(ws)) + ".", 15, BONE2))
		cvv.add_child(lbl("Ability: " + (str(C.ABILITIES[t["ab"]]["n"]) if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]) else "none"), 15, BONE3))
		var fr = hbox(); add(fr, abtn("Buy for " + C.numstr(cost), "buyHull", h))
		if not fits: fr.add_child(lbl("Not enough command points", 14, BONE3, null, false))
		elif uniq: fr.add_child(lbl("Only one allowed", 14, BONE3, null, false))
		cvv.add_child(fr); hs.add_child(cv[0])
	v.add_child(hs)
	v.add_child(sec_head("Refits for sale"))
	var ms = flow()
	for i in range(st["mods"].size()):
		var m = st["mods"][i]; var cv2 = card(false, 300)
		cv2[1].add_child(lbl(C.modName(m), 20, BONE, font_semi)); cv2[1].add_child(lbl(C.MODULES[m]["d"], 16, BONE2))
		if C._has_num(st["sold"], i): cv2[1].add_child(lbl("Bought", 16, VERD))
		else: add(cv2[1], abtn("Buy for " + C.numstr(C.jsround(float(C.MODULES[m]["cost"]) * pm)), "buyMod", i))
		ms.add_child(cv2[0])
	v.add_child(ms)
	v.add_child(sec_head("Class refits"))
	v.add_child(lbl("A class refit upgrades every ship of that class you own now or later: +6% hull and +6% damage per level, up to " + C.numstr(C.CLASS_TRACK_MAX) + ".", 15, BONE3))
	var tr = flow(8)
	for cls in C.fleetClasses():
		var lv = int(C.classTrack(cls)); var mx = lv >= int(C.CLASS_TRACK_MAX)
		add(tr, abtn(C.clsName(cls) + " " + "●".repeat(lv) + "○".repeat(int(C.CLASS_TRACK_MAX) - lv) + " " + ("(full)" if mx else "for " + C.numstr(C.classTrackCost(cls))), "buyTrack", cls))
	v.add_child(tr)
	return v

# ---------------- the battle page (stub battles; the game shell replaces it with the real battle) ----------------
func _battle_stub(d: Dictionary) -> Control:
	var cfg = d["cfg"]; var E = C.ENCOUNTERS.get(cfg.get("obj"), C.ENCOUNTERS["rout"])
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p = panel(GILT2, IRON, 24); p.custom_minimum_size.x = px(720); var v = vbox(10); p.add_child(v)
	var kind = "flagship battle" if cfg["kind"] == "boss" else (("elite " if cfg["kind"] == "elite" else "") + str(E["n"]).to_lower())
	v.add_child(lbl("Sector " + C.roman(C.RUN["sector"]) + ": " + kind + " against " + str(C.FACTIONS[cfg["fac"]]["n"]), 22, BONE, font_goth))
	v.add_child(lbl(("The sector flagship and its escort." if cfg["kind"] == "boss" else str(E["d"])), 17, BONE2))
	v.add_child(lbl("Test battle: the real battle scene plugs in here. Pick how this fight ends.", 15, BONE3))
	var row = flow(8)
	add(row, abtn("Win", "battle", "win", true)); add(row, abtn("Win, objective missed (half pay)", "battle", "partial")); add(row, abtn("Lose the fleet", "battle", "loss")); add(row, abtn("Retreat", "c3retreat"))
	v.add_child(row)
	cc.add_child(p); return cc

# ---------------- progression and help ----------------
func _legacy() -> Control:
	var v = vbox(10); var M = C.META; var st = M["stats"]
	v.add_child(gothic("Progression"))
	v.add_child(rich(c("Runs launched: " + C.numstr(st["runs"]) + ". Deepest sector reached: " + C.numstr(C.z0(st.get("best"))) + ". Runs won: " + C.numstr(st["wins"]) + ". Renown: ", BONE2) + c(C.numstr(C.z0(M.get("renown"))), GILT) + c(".", BONE2), 17))
	var tabs = hbox(6)
	for t in [["variants", "Hull variants"], ["legacy", "Legacy"], ["mastery", "Admiral mastery"], ["favour", "Core sync"], ["heat", "Heat"], ["fallen", "Hall of the fallen"]]: add(tabs, abtn(t[1], "progTab", t[0], C.prog_tab == t[0]))
	var stc = _story()
	if stc != null:   # story layer: the Career screen (records, medals, titles, history)
		var cb = Button.new(); cb.text = "Career"; cb.focus_mode = Control.FOCUS_ALL; cb.pressed.connect(func(): stc.open_career()); tabs.add_child(cb)
	v.add_child(tabs)
	match C.prog_tab:
		"variants":
			v.add_child(rich(c("Spend renown to add a variant hull to your faction's shipyards. It sits beside the standard hull whenever that hull is in stock. ", BONE2) + c("You have " + C.numstr(C.z0(M.get("renown"))) + " renown.", GILT) + c(" Renown comes from every run: battles, elites, flagships and sectors reached, plus 10% per Heat level.", BONE2), 17))
			for f in C.favFirst():
				var vs = []
				for vid in C.HULL_VARIANTS.keys():
					if C.HULLS[C.HULL_VARIANTS[vid]["base"]].get("fac") == f: vs.append(vid)
				if vs.is_empty(): continue
				v.add_child(lbl(C.FACTIONS[f]["n"], 20, BONE, font_semi))
				var cards = flow()
				for vid in vs:
					var hv = C.HULL_VARIANTS[vid]; var own = C.jt(M["variants"].get(vid)); var t = C.HULLS[vid]
					var cv = card(own, 320); cv[1].add_child(lbl(hv["n"], 20, BONE, font_semi)); cv[1].add_child(lbl("Variant of the " + str(C.HULLS[hv["base"]]["n"]), 14, BONE3)); cv[1].add_child(lbl(hv["d"], 16, BONE2))
					var ws = []
					for e in t["w"]: ws.append(str(C.W_[e[0]]["n"]) + " (" + ("turret" if e[1] == "T" else str(C.ARC_NAME.get(e[1], e[1])).to_lower()) + ")")
					cv[1].add_child(lbl(C.numstr(t["cp"]) + " CP. Hull " + C.numstr(t["hp"]) + ", shields " + C.numstr(t["sh"]) + ", speed " + C.numstr(t["sp"]) + ". " + ", ".join(PackedStringArray(ws)) + ".", 14, BONE2))
					if own: cv[1].add_child(lbl("In your shipyards", 16, VERD))
					elif C.jt(hv.get("arc")): cv[1].add_child(lbl("Finish the " + str(C.FACTIONS[hv["arc"]]["n"]) + " story to unlock", 15, BONE3))
					else: add(cv[1], abtn("Unlock for " + C.numstr(hv["cost"]) + " renown", "buyVariant", vid))
					cards.add_child(cv[0])
				v.add_child(cards)
		"legacy":   # R1 (PROG-2): lasting unlocks bought with renown (campaign.gd legacyScreen lists the buyLegacy buttons)
			v.add_child(rich(c("Spend renown on lasting advantages for every later run. ", BONE2) + c("You have " + C.numstr(C.z0(M.get("renown"))) + " renown.", GILT), 17))
			var lc = flow()
			for id in C.LEGACY.keys():
				var u = C.LEGACY[id]; var own = C.jt(M["unlocked"].get(id)); var lock = C.jt(u.get("req")) and not C.jt(M["unlocked"].get(u["req"]))
				var cv = card(own, 300); cv[1].add_child(lbl(u["n"], 20, BONE, font_semi)); cv[1].add_child(lbl(u.get("group", ""), 14, BONE3)); cv[1].add_child(lbl(u["d"], 16, BONE2))
				if own: cv[1].add_child(lbl("Unlocked", 16, VERD))
				elif lock: cv[1].add_child(lbl("Needs " + str(C.LEGACY[u["req"]]["n"]) + " first", 15, BONE3))
				else: add(cv[1], abtn("Unlock for " + C.numstr(u["cost"]) + " renown", "buyLegacy", id))
				lc.add_child(cv[0])
			v.add_child(lc)
		"mastery":
			v.add_child(lbl("Every run levels up the admiral who led it: 1 per battle won, 2 per elite, 5 per flagship and 10 for a victory.", 17, BONE2))
			var mc = flow()
			for i in range(1, C.MASTERY_PERKS.size()):
				var cv = card(false, 300); cv[1].add_child(lbl("Level " + str(i) + ": " + str(C.MASTERY_PERKS[i]["n"]), 19, BONE, font_semi)); cv[1].add_child(lbl(C.MASTERY_PERKS[i]["d"], 16, BONE2)); cv[1].add_child(lbl(C.numstr(C.MASTERY_XP[i]) + " mastery", 14, BONE3)); mc.add_child(cv[0])
			var cv_m = card(false, 300); cv_m[1].add_child(lbl("Capstone mastery", 19, BONE, font_semi)); cv_m[1].add_child(lbl("Choose a Command evolution at level 8 (230 XP), then keep deepening it at 320, 440 and 600 XP.", 16, BONE2)); mc.add_child(cv_m[0])
			v.add_child(mc)
			for f in C.favFirst():
				v.add_child(lbl(C.FACTIONS[f]["n"], 20, BONE, font_semi)); var ac = flow()
				for id in C.ADMIRALS.keys():
					if C.or_(C.ADMIRALS[id].get("fac"), "voidsworn") != f: continue
					var cv2 = card(false, 300); cv2[1].add_child(lbl(C.ADMIRALS[id]["n"], 19, BONE, font_semi)); cv2[1].add_child(lbl(C.ADMIRALS[id]["doc"], 15, GILT)); cv2[1].add_child(_mastery_bar(id))
					if C.LINEAGE_TREES.has(id): add(cv2[1], abtn("View lineage tree", "lineage", id))
					ac.add_child(cv2[0])
				v.add_child(ac)
		"favour":
			v.add_child(lbl("Every protocol you take raises your sync with that core (rare protocols count double, epic triple).", 17, BONE2))
			var fc = flow()
			for i in range(1, C.FAVOUR_TIERS.size()):
				var cv = card(false, 300); cv[1].add_child(rich("[b]" + esc(C.FAVOUR_TIERS[i]["n"]) + "[/b] " + c(C.numstr(C.FAVOUR_TIERS[i]["at"]) + "+", BONE3), 19)); cv[1].add_child(lbl(C.FAVOUR_TIERS[i].get("d", ""), 16, BONE2)); fc.add_child(cv[0])
			v.add_child(fc)
			for p in C.PATRONS.keys():
				var P = C.PATRONS[p]; var f = C.favourOf(p); var t = C.favourTier(p); var nx = C.FAVOUR_TIERS[t + 1] if t + 1 < C.FAVOUR_TIERS.size() else null
				var r = hbox(); r.add_child(lbl(P["glyph"], 18, Color(P["col"]), font_semi, false)); r.add_child(rich("[b]" + esc(P["n"]) + "[/b]\n" + c(esc(P["theme"]), BONE3), 15))
				r.add_child(rich("[right][b]" + c(esc(C.FAVOUR_TIERS[t]["n"]), Color(P["col"])) + "[/b]\n" + c(C.numstr(f) + ((" / " + C.numstr(nx["at"])) if nx != null else ""), BONE3) + "[/right]", 15)); v.add_child(r)
		"heat":
			var heat_open = C.heatUnlocked()
			v.add_child(lbl("Heat is open. Pick rules on the admiral screen before a run; each level adds 10% renown." if heat_open else "Lose a run to open Heat.", 17, BONE2))
			var hc = flow()
			for kk in C.HEAT.keys():
				var cv = card(false, 300); cv[1].add_child(rich("[b]" + esc(C.HEAT[kk]["n"]) + "[/b] " + c("+" + C.numstr(C.HEAT[kk]["w"]), BONE3), 19)); cv[1].add_child(lbl(C.HEAT[kk]["d"], 16, BONE2)); hc.add_child(cv[0])
			v.add_child(hc); v.add_child(lbl("Best Heat won", 20, BONE, font_semi))
			var bc = flow()
			for f in C.RUN_FACTIONS:
				var hb = float(C.z0(M["heatBest"].get(f))); var won = C.or_(st.get("wonFacs"), []).has(f)
				var cv = card(false, 220); cv[1].add_child(lbl(C.FACTIONS[f]["n"], 18, BONE, font_semi)); cv[1].add_child(lbl(("Heat " + C.numstr(hb)) if hb > 0 else ("Won at Heat 0" if won else "Not yet won"), 16, GILT if hb > 0 else BONE3)); bc.add_child(cv[0])
			v.add_child(bc)
		"fallen":
			var fallen = M["fallen"].slice(max(0, M["fallen"].size() - 40)); fallen.reverse()
			if fallen.is_empty(): v.add_child(lbl("No captain has died yet.", 17, BONE2))
			else:
				var fc2 = flow()
				for f in fallen:
					var cv = card(false, 260); cv[1].add_child(lbl(f["name"], 18, BONE, font_semi)); cv[1].add_child(lbl(C.rankName(f) + " of the " + str(f.get("ship", "")), 15, BONE2)); cv[1].add_child(lbl("Lost in sector " + C.roman(f.get("sector", 1)), 14, BONE3)); fc2.add_child(cv[0])
				v.add_child(fc2)
	add(v, abtn("Back to title", "title", "", true))
	return v
const HELP := [
	["", "Embers of the Hollow Sun is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run; every faction, admiral and ship is available from the start."],
	["", "What carries between runs (Progression, on the title screen): renown buys hull variants for your shipyards; each admiral levels up as you fly with them, unlocking an alternate fleet, a fourth aspect, a second Command and a veteran flag captain; cores sync with you as you take their protocols, offering rarer protocols and eventually a gift at the start of a run; and after your first loss, Heat lets you add harder rules for more renown. After each sector flagship falls, the fleet docks at a shipyard before its next fight."],
	["Your turn", "Every ship can move, turn and fire each of its weapons once per turn, in any order. Click a ship, then click a highlighted hex to move. Moving forward costs 1 movement. Turning 60° also costs 1 movement and uses one of the ship’s turns; big ships only get one turn per round, so plan their heading early. Press Q and E to turn in place."],
	["", "Thrusters keep you from getting boxed in. A ship can slip into either forward-diagonal hex, or back off one hex, without changing its heading (2 movement each; a slow ship can always spend its whole move on one hop). It can climb over a rock or wreck, or dive under an enemy ship, for +1 movement, but cannot stop there. Each faction bends one of these rules: see the Helm panel."],
	["", "Ships fight on the move. Click an enemy your guns can't reach yet and the ship burns to the best spot and fires as it arrives."],
	["", "Moving matters. A ship that did not move last turn gets hit more easily (+10 to hit). One that moved 3+ hexes is harder to hit (−5). Port and starboard guns hit 10% harder on a raking pass, after moving 2+ hexes."],
	["Firing arcs", "Weapons only fire into their arc. Prow weapons cover the 120° in front, port and starboard broadsides each cover a wide 120° cone to the side, and turrets fire anywhere. The tinted hexes around a selected ship show where its guns reach: amber for the prow, teal for broadsides. Click an enemy to fire everything that can reach it, or press a number key to fire a single weapon."],
	["Shields and flanking", "Each ship has four shield facings: prow, port, starboard and rear. Damage hits the facing that points at the attacker, and shields regenerate at the start of each of your turns. Rear hits halve armor and are far more likely to crit, so getting behind a battleship matters. Lances and bombers punch partly or fully through shields. Ion cannons shred shields; null weapons mostly ignore them."],
	["Different fights", "Each fight on the sector map is labelled with its goal. Engagements and ambushes end when one fleet breaks. In Hold the station you keep enemies off a friendly station until round 6 ends. In a Hunt their flagship runs and jumps out after round 6. In an Intercept you destroy transports before they cross the field. In a Breakthrough you get half your fleet off the far edge. Missing a Hunt or Intercept still pays half; losing the station or a breakthrough means a retreat, not the end of the run. Click the chip under the top bar in battle for the rules and the coloured hexes."],
	["", "Some fights change partway through: reinforcements for either side, or a solar flare that knocks out every shield for a round. You always get a round of warning."],
	["Brace, abilities and Command", "Brace is the alternative to firing: a ship that hasn’t fired can brace to take 40% less hull damage until your next turn (it can still move first). To ram, point your bow at an enemy ship with at least one clear hex between you and enough movement left to cross the gap: a red lane shows when a ram is ready, and red-ringed move hexes line one up. A longer run-up hits harder; a ram can’t take more than 40% of a healthy ship’s hull without protocols. Boarding an adjacent enemy can capture it for your fleet; enemy boarders can cripple your ships, but never take them. Carriers start every battle with their wings already flying; the wings fight on their own unless you order them: click a wing, then click an enemy ship to strike it or one of your ships to guard it. At round start, each ready carrier automatically replaces one lost wing if it has a spare and an open hex beside it. Replacements fight from the following round. Most hulls have an ability with a cooldown, and each faction has its own. Enemy flagships carry a Command too: they announce it a round ahead, so you can brace or scatter. Once per battle, your admiral’s Command is a fleet-wide signature move. It gets stronger each round you hold it (power 1 in round 1, 2 in round 2, full power from round 3, and losing a ship charges it a level), so the choice is a smaller boost now or a bigger one later, if the fight lasts that long. The ship panel shows exactly what the next level adds."],
	["Cores, protocols and your flagship", "Each run, four of the six cores are in range. Battles on the map carry a core’s signal: win there and that core offers three protocols, and you take one. Protocols change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare and Epic strength. Hold protocols from two cores and a duo protocol can appear. At the start of a run you also pick one of three aspects for your flagship, which shapes how it fights for the whole run. Each sector’s enemies have a set strength, so a stronger fleet feels stronger; a battered fleet meets slightly smaller ones."],
	["Between battles", "Hull damage carries between battles. Shipyards sell hulls, refits and repairs, and can upgrade a ship’s Mark. Captains earn experience and pick a perk at each promotion. Salvage gives fleet-wide bonuses that last for the run."],
	["Keys", "Tab next ship, Q/E turn, 1 to 6 arm a weapon, B brace, A toggle arcs, Esc or right-click to cancel, Enter end turn. On campaign screens: Tab and the arrow keys move between buttons, Enter presses, Esc closes a dialog, 1 to 9 pick a dialog's choices."]]
func _help() -> Control:
	var v = vbox(10); v.add_child(gothic("How to play"))
	for h in HELP:
		if h[0] != "": v.add_child(lbl(h[0], 20, GILT, font_semi))
		v.add_child(lbl(h[1], 17, BONE2))
	add(v, abtn("Back", "title", "", true))
	return v

# ---------------- run end ----------------
func _end(d: Dictionary) -> Control:
	var R = d["run"]; var victory = d["victory"]; var s = R["stats"]; var cy = R["carry"]
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sc = ScrollContainer.new(); sc.custom_minimum_size = Vector2(px(760), min(px(1000), get_viewport().get_visible_rect().size.y - px(40))); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v = vbox(10); v.custom_minimum_size.x = px(720); sc.add_child(v); cc.add_child(sc)
	var title = (str(C.WIN_TITLE.get(R["fac"], "Victory"))) if victory else ("Run abandoned" if d["abandoned"] else "The fleet is lost")
	var h = lbl(title, 62, BONE, font_goth); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(h)
	var sub = ""
	if victory: sub = "Three sectors broken, three flagships burning behind you. " + str(C.ADMIRALS[R["admiral"]]["n"]) + " brings the " + str(C.FACTIONS[R["fac"]]["n"]).trim_prefix("The ") + " home."
	elif d["abandoned"]: sub = "The fleet stands down. Its deeds are recorded."
	else: sub = "The last hull goes dark in sector " + C.roman(R["sector"]) + ". The survivors will tell it differently."
	var sl = lbl(sub, 20, BONE2); sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sl)
	v.add_child(lbl(C.TB.STORY_BEAT3[R["fac"]]["learning"], 18, GILT))
	var stl = _story_text()
	if stl != "":
		var sll = lbl(stl, 18, GILT); sll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sll)
	var carry = panel(GILT, Color(0.37, 0.7, 0.65, 0.08), 12); var cv = vbox(4); carry.add_child(cv)
	var receipt = cy["inheritance"]; var flown = receipt["flown"]
	cv.add_child(lbl("YOUR INHERITANCE", 24, GILT, font_semi))
	cv.add_child(lbl("What this run leaves for the next generation.", 16, BONE2))
	cv.add_child(rich("[b]" + c("+" + C.numstr(cy["ren"]) + " renown", GILT) + "[/b]" + ((" (Heat " + C.numstr(cy["hl"]) + ": +" + C.numstr(cy["hl"] * 10) + "%)") if C.jt(cy["hl"]) else "") + ". Balance: " + C.numstr(receipt["balance"]) + " renown.", 18))
	cv.add_child(lbl("Affordable now", 20, GILT, font_semi))
	cv.add_child(lbl("Each reward can be bought on its own. Choose how to spend your renown in Progression.", 15, BONE3))
	for u in receipt["affordable"]:
		cv.add_child(lbl(str(u["n"]) + ": " + C.numstr(u["cost"]) + " renown (" + str(u["kind"]) + ")" + (" - Newly affordable" if u["fresh"] else ""), 16, GILT if u["fresh"] else BONE2))
	if receipt["affordable"].is_empty(): cv.add_child(lbl("No unowned doctrine or hull reward is affordable yet. Your renown stays saved.", 16, BONE3))
	cv.add_child(lbl(str(C.ADMIRALS[flown["id"]]["n"]) + (": lineage tree" if flown["tree"] else ": admiral line"), 20, GILT, font_semi))
	cv.add_child(lbl("+" + C.numstr(snapped(float(cy["mxGain"]), 0.01)) + " XP. Level " + str(flown["level"]) + ((" (was " + C.numstr(cy["mx0"]) + ")") if cy["mx1"] > cy["mx0"] else "") + ".", 17, BONE))
	for perk in flown["earned"]: cv.add_child(lbl(str(perk["n"]) + " earned: " + str(perk["d"]), 16, GILT))
	if flown.get("hasCap", false):
		if flown["next"] == null: cv.add_child(lbl(C.numstr(flown["xp"]) + " XP. This evolution is at full mastery.", 16, BONE3))
		else: cv.add_child(lbl(C.numstr(flown["xp"]) + " / " + C.numstr(flown["next"]) + " XP. " + C.numstr(flown["remaining"]) + " XP to capstone mastery " + C.roman(int(flown["capLevel"]) + 1) + ".", 16, BONE3))
		if int(flown["capLevel"]) > 0:
			var cap_perk = C.CAPSTONE_MASTERY_PERKS[int(flown["capLevel"]) - 1]
			cv.add_child(lbl("Capstone mastery " + C.roman(int(flown["capLevel"])) + ": " + str(cap_perk["d"]), 16, GILT))
	elif flown["next"] == null: cv.add_child(lbl(C.numstr(flown["xp"]) + " XP. This line is at its current cap.", 16, BONE3))
	else: cv.add_child(lbl(C.numstr(flown["xp"]) + " / " + C.numstr(flown["next"]) + " XP. " + C.numstr(flown["remaining"]) + " XP to level " + str(int(flown["level"]) + 1) + ": " + str(C.masteryPerk(int(flown["level"]) + 1)["n"]) + ".", 16, BONE3))
	if flown["tree"]:
		cv.add_child(lbl(str(flown["pending"]) + (" branch pick ready." if flown["pending"] == 1 else " branch picks ready.") + (" Command evolution ready." if flown["capstoneReady"] else ""), 17, GILT))
		cv.add_child(lbl("Recorded skills: " + (", ".join(PackedStringArray(flown["chosen"])) if not flown["chosen"].is_empty() else "None yet") + ".", 15, BONE3))
	var sv = cv
	sv.add_child(lbl("SHADOW LEARNING", 16, GILT, font_semi))
	for row in receipt["shadow"]:
		var snext = ((", fully mastered") if row.get("hasCap", false) else (", at current cap")) if row["next"] == null else ((", " + C.numstr(snapped(float(row["remaining"]), 0.01)) + " XP to capstone mastery " + C.roman(int(row.get("capLevel", 0)) + 1)) if row.get("hasCap", false) else (", " + C.numstr(snapped(float(row["remaining"]), 0.01)) + " XP to level " + str(int(row["level"]) + 1)))
		sv.add_child(lbl(str(C.ADMIRALS[row["id"]]["n"]) + ": +" + C.numstr(snapped(float(row["xp"]), 0.01)) + " shadow XP" + (" (heir rate)" if row["rate"] == 0.5 else "") + ". Total " + C.numstr(snapped(float(row["total"]), 0.01)) + " XP, level " + C.numstr(row["level"]) + snext + ".", 15, BONE2))
	if cy["mxOverflow"] > 0: sv.add_child(lbl(C.numstr(snapped(float(cy["mxOverflow"]), 0.01)) + " XP past this line's cap went to shadow learning.", 15, BONE3))
	if cy["shadowBank"] > 0: sv.add_child(lbl(C.numstr(snapped(float(cy["shadowBank"]), 0.01)) + " shadow XP saved for an uncapped benched line.", 15, BONE3))
	if not receipt.get("cores", []).is_empty():
		cv.add_child(lbl("CORE SYNC", 20, GILT, font_semi))
		for row in receipt["cores"]:
			cv.add_child(lbl(str(C.PATRONS[row["id"]]["n"]) + ": +" + C.numstr(row["gain"]) + " sync. " + str(C.FAVOUR_TIERS[row["tier"]]["n"]) + (" (Tier up this run)" if row["tierUp"] else "") + ".", 17, Color(C.PATRONS[row["id"]]["col"])))
			cv.add_child(lbl((C.numstr(row["total"]) + " sync. Full sync reached.") if row["next"] == null else (C.numstr(row["total"]) + " / " + C.numstr(row["next"]) + " sync. " + C.numstr(row["remaining"]) + " to " + str(C.FAVOUR_TIERS[int(row["tier"]) + 1]["n"]) + "."), 15, BONE3))
	# Job 7 step 7 (R85 Q5): the run's Nemesis lesson, recorded on the commander who fought the lost meeting
	var nz = receipt.get("nem") if receipt.get("nem") is Dictionary else {"met": 0, "lessons": []}
	cv.add_child(lbl("Nemesis lesson", 20, GILT, font_semi))
	var nl = nz.get("lessons") if nz.get("lessons") is Array else []
	if nl.is_empty(): cv.add_child(lbl("No weakness was taught this run." if int(nz.get("met", 0)) > 0 else "No Nemesis meeting this run.", 16, BONE3))
	for l in nl:
		var NW = C.NEM_WEAK.get(l.get("w")) if l.get("w") != null else null
		if NW != null: cv.add_child(rich("Nemesis lesson: [b]" + c(esc(l.get("name")), BLOOD) + "[/b] beat you and taught you a weakness: [b]" + c(esc(NW["n"]), GILT) + "[/b].", 17))
		else: cv.add_child(rich("Nemesis lesson: [b]" + c(esc(l.get("name")), BLOOD) + "[/b] beat you.", 17))
		if l.get("text") != null and str(l.get("text")) != "": cv.add_child(lbl(str(l["text"]), 15, BONE3))
	var choices = flow(8)
	add(choices, abtn("Choose doctrine", "progTab", "legacy")); add(choices, abtn("Choose hull rewards", "progTab", "variants"))
	add(choices, abtn("View admiral line", "lineage" if flown["tree"] else "progTab", flown["id"] if flown["tree"] else "mastery")); sv.add_child(choices)
	sv.add_child(lbl("Name an heir", 20, GILT, font_semi))
	sv.add_child(lbl("Benched lines of this faction earn 25% shadow XP. Your named heir earns 50% on future runs. You can replace this faction's heir after any run.", 15, BONE2))
	for id in C.shadowAdmirals(R["fac"], R["admiral"]):
		var heir = C.META["heirs"].get(R["fac"]) == id
		add(sv, abtn(("Heir: " if heir else "Name ") + str(C.ADMIRALS[id]["n"]), "nameHeir", id, heir))
	v.add_child(carry)
	var tiles = flow(8)
	var tl = [[s["battles"], "battles won"], [s["bosses"], "flagships destroyed"], [s["kills"], "enemy ships destroyed"], [C.z0(s.get("lost")), "ships lost"]]
	if d.get("mins") != null: tl.append([(C.numstr(d["mins"]) + "m") if float(d["mins"]) < 90 else (str(snapped(float(d["mins"]) / 60.0, 0.1)) + "h"), "played"])
	for t in tl:
		var p = panel(IRON3, GLASS, 8); p.custom_minimum_size.x = px(120); var tv = vbox(0)
		var a = lbl(str(t[0]) if t[0] is String else C.numstr(t[0]), 26, GILT, font_semi); a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv.add_child(a)
		var b = lbl(t[1], 13, BONE2); b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tv.add_child(b); p.add_child(tv); tiles.add_child(p)
	v.add_child(tiles)
	var fl = R["fleet"].filter(func(x): return float(x["hp"]) > 0)
	var score = func(x): return (float(x["car"]["dealt"]) + float(x["car"]["kills"]) * 40.0) if x.get("car") != null else 0.0
	fl = C.ssort(fl, func(a, b): return score.call(b) - score.call(a))
	if fl.size() > 0:
		var best = fl[0]
		if score.call(best) > 0: v.add_child(rich("Standout ship: [b]" + c(esc(best["name"]), GILT) + "[/b], " + C.numstr(best["car"]["kills"]) + " kills and " + C.numstr(best["car"]["dealt"]) + " damage across " + C.numstr(best["car"]["battles"]) + " battle" + ("s" if float(best["car"]["battles"]) > 1 else "") + ".", 17))
		v.add_child(lbl("The fleet that finished it" if victory else "Still flying", 20, GILT, font_semi))
		for x in fl:
			var cr = x.get("car") if x.get("car") != null else {"dealt": 0, "kills": 0}
			var p = panel(GILT if (x == best and score.call(x) > 0) else IRON3, GLASS, 8); var r = hbox()
			r.add_child(rich("[b]" + esc(x["name"]) + "[/b] " + c(esc(C.HULLS[x["tpl"]]["n"]), BONE3) + "\n" + c(esc(C.rankName(x["cap"])) + " " + esc(x["cap"]["name"]), BONE3), 15))
			r.add_child(rich("[right]" + C.numstr(cr["kills"]) + " kills\n" + c(C.numstr(cr["dealt"]) + " dmg", BONE3) + "[/right]", 15)); p.add_child(r); v.add_child(p)
	if R["fallen"].size() > 0:
		var nm = []
		for f in R["fallen"]: nm.append(f["name"])
		v.add_child(lbl("Captains lost this run: " + ", ".join(PackedStringArray(nm)) + ".", 16, BONE2))
	if victory:
		var wf = []
		for f in C.or_(C.META["stats"].get("wonFacs"), []): wf.append(C.FACTIONS[f]["n"])
		var w = int(C.META["stats"]["wins"])
		v.add_child(lbl(("Victories so far: " + str(w)) if w > 1 else "Your first victory." + "", 18, GILT))
		v.add_child(lbl("Won with: " + ", ".join(PackedStringArray(wf)) + ".", 16, GILT))
	else:
		var pb = float(d["prevBest"])
		v.add_child(lbl(("New best: sector " + C.roman(R["sector"])) if float(R["sector"]) > pb else ("Best so far: sector " + C.roman(min(3, float(C.META["stats"]["best"])))), 20, GILT))
	if d["next"] != null:
		var NF = C.FACTIONS[d["next"]]; var p2 = panel(VERD, Color(0.37, 0.7, 0.65, 0.08), 12); var nv = vbox(4); p2.add_child(nv)
		nv.add_child(lbl("NEXT RUN", 12, BONE3)); nv.add_child(lbl("Try the " + str(NF["n"]).trim_prefix("The "), 18, BONE, font_semi)); nv.add_child(lbl(NF.get("blurb", ""), 15, BONE2)); v.add_child(p2)
	var menu = hbox(); menu.alignment = BoxContainer.ALIGNMENT_CENTER
	if d["next"] != null:
		add(menu, abtn("Play as " + str(C.FACTIONS[d["next"]]["n"]), "nextFac", d["next"], true)); add(menu, abtn("Pick a faction", "newRunScreen"))
	else: add(menu, abtn("New run", "newRunScreen", "", true))
	add(menu, abtn("Title screen", "title")); v.add_child(menu)
	return cc

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
	col.add_child(lbl(n["n"], 19, GILT if chosen else BONE, font_semi)); col.add_child(lbl(n["d"], 16, BONE2))
	var labels = {"chosen": "Recorded", "locked": "Locked until reset", "available": "Choose this skill", "future": "Not yet available"}
	add(col, abtn(labels[n["state"]], "offerLineage", n["key"], n["state"] == "available"))
	if n["state"] == "locked": cv[0].modulate.a = 0.55
	return cv[0]
func _lineage(id) -> Control:
	var v = vbox(12); var tree = C.LINEAGE_TREES[id]; var build = C.lineageBuild(id); var nodes = C.lineageNodes(id); var level = C.masteryLevel(id)
	v.add_child(lbl(C.ADMIRALS[id]["n"], 30, BONE, font_goth))
	v.add_child(lbl("Recorded in the glass. One pick at each of levels 5, 6 and 7. Choose a branch, then one skill at its next tier. Its partner locks until you reset this line.", 17, BONE2))
	v.add_child(_mastery_bar(id))
	v.add_child(lbl(str(maxi(0, mini(3, level - 4) - build["picks"].size())) + " branch picks ready. Capstone at level 8 (230 XP).", 17, GILT))
	v.add_child(lbl("Command skills and capstones use " + str(C.ADMIRALS[id]["cmd"]["n"]) + ", the primary Command. Fleet and flagship branches open their first tier.", 15, BONE3))
	if not C.lineageBetweenRuns(): v.add_child(lbl("Finish or abandon your saved run before changing this line.", 17, BLOOD))
	var columns = flow(16); var trunk = vbox(8); trunk.custom_minimum_size.x = px(300)
	trunk.add_child(lbl("Trunk: levels 1 to 4", 20, BONE, font_semi))
	for i in range(1, C.MASTERY_PERKS.size()):
		var cv = card(false, 300); cv[1].add_child(lbl(str(i) + ". " + str(C.MASTERY_PERKS[i]["n"]), 19, BONE, font_semi)); cv[1].add_child(lbl(C.MASTERY_PERKS[i]["d"], 16, BONE2)); cv[1].add_child(lbl(C.numstr(C.MASTERY_XP[i]) + " XP: " + ("earned" if level >= i else "not yet earned"), 14, BONE3)); trunk.add_child(cv[0])
	columns.add_child(trunk)
	for b in tree["branches"].keys():
		var col = vbox(8); col.custom_minimum_size.x = px(300)
		var glyph = {"A": "[+] Command", "B": "[=] Fleet", "C": "[*] Flagship and line"}
		col.add_child(lbl(glyph[b] + ": " + str(tree["branches"][b]["n"]), 20, GILT, font_semi))
		for t in range(tree["branches"][b]["tiers"].size()):
			col.add_child(lbl("Tier " + str(t + 1), 16, BONE3))
			for n in nodes:
				if n["branch"] == b and n["tier"] == t + 1: col.add_child(_lineage_node(n))
		columns.add_child(col)
	v.add_child(columns)
	var cap = panel(GILT, Color(0.37, 0.7, 0.65, 0.08), 16); var capv = vbox(8); cap.add_child(capv)
	capv.add_child(lbl("Level 8: Command evolution", 23, GILT, font_goth)); var capnodes = flow()
	for n in nodes:
		if n["branch"] == "cap": capnodes.add_child(_lineage_node(n))
	capv.add_child(capnodes); capv.add_child(_capstone_mastery(id)); v.add_child(cap)
	v.add_child(lbl("Reset clears all branch picks and the capstone. XP and trunk perks stay. This line has been reset " + C.numstr(build["respecs"]) + " times. You have " + C.numstr(C.z0(C.META.get("renown"))) + " renown.", 16, BONE3))
	var row = hbox(); add(row, abtn("Reset line: " + C.numstr(C.lineageRespecCost(id)) + " renown", "offerRespec", id)); add(row, abtn("Back to Admiral mastery", "progTab", "mastery")); v.add_child(row)
	return v
# Job 7 step 14: the mastery levels on the chosen capstone evolution, in the same block as the evolution choice.
func _capstone_mastery(id) -> Control:
	var tree = C.LINEAGE_TREES[id]; var build = C.lineageBuild(id); var v = vbox(6)
	if build["capstone"] == null:
		v.add_child(lbl("Choose a Command evolution to open capstone mastery at 320, 440 and 600 XP.", 15, BONE3)); return v
	var chosen = tree["capstones"][int(build["capstone"])]; var xp = C.masteryXP(id); var l = C.capstoneMasteryLevel(id); var nx = C.capstoneMasteryNext(id)
	v.add_child(lbl("Capstone mastery: " + str(chosen["n"]), 20, GILT, font_semi))
	v.add_child(lbl((C.numstr(xp) + " XP. This evolution is at full mastery.") if nx == null else (C.numstr(xp) + " / " + C.numstr(nx) + " XP. " + C.numstr(float(nx) - xp) + " XP to capstone mastery " + C.roman(l + 1) + "."), 15, BONE3))
	var row = flow(10)
	for i in range(C.CAPSTONE_MASTERY_PERKS.size()):
		var earned = l > i; var cv = card(earned, 300)
		cv[1].add_child(lbl("Mastery " + C.roman(i + 1) + (" (earned)" if earned else ""), 18, GILT if earned else BONE, font_semi))
		cv[1].add_child(lbl(str(C.CAPSTONE_MASTERY_PERKS[i]["d"]), 15, BONE2))
		cv[1].add_child(lbl(C.numstr(C.CAPSTONE_MASTERY_XP[i]) + " XP", 14, BONE3))
		if not earned: cv[0].modulate.a = 0.55
		row.add_child(cv[0])
	v.add_child(row)
	return v

# ---------------- dialogs ----------------
func _modal(md: Dictionary) -> void:
	_modal_acts = md["acts"]; var acts = _modal_acts; var d = md["data"]
	var dim = ColorRect.new(); dim.color = GS.SHADE; dim.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(dim)
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(cc)
	var box = shell_panel(20)   # a dialog: one matte panel (chamfers, scanline, bevel, brackets); its words sit on wells (_well_text)
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
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
			if md["kind"] == "sector" and d.get("adapt") != null and d.get("adaptFac") != null:   # #121 (A4): the commander who fought the sector just ended
				var na = d["adapt"]; var nf = d["adaptFac"]
				# the Nemesis adaptation: its own well with the reserved red bar and the NEMESIS tag, as the battle's Nemesis block
				var aw = blk(ALERT, 5, 14, 10); aw[0].set_meta("keep", true)
				var ah = hbox(8); ah.add_child(tagl("Nemesis", ALERT, true)); ah.add_child(lbl("ADAPTED TO YOU", 13, GILT, font_caps, false)); aw[1].add_child(ah)
				aw[1].add_child(rich(c(esc(str(d.get("adaptWho", ""))) + " has adapted: ", BONE2) + "[b]" + c(esc(C.nemAdaptName(na, nf)), BLOOD) + "[/b] " + c("(" + esc(str(d.get("adaptWhy", ""))) + ")", BONE3), 17))
				aw[1].add_child(rich(c(esc(C.nemAdaptDesc(na, nf)), BONE2), 16))
				if str(d.get("adaptLine", "")) != "": aw[1].add_child(rich("[i]" + c(esc(str(d["adaptLine"])), BLOOD) + "[/i]", 15))
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
			h2.call("Decommission the " + str(d["ship"]["name"]) + "?"); p.call("Its captain retires and its refits return to the hold. You receive " + C.numstr(d["value"]) + " credits.", BONE2)
			v.add_child(foot([abtn("Keep it", "closeModal", "", false, false, acts), fin("Decommission", "sellConfirm", d["ship"]["uid"], acts)]))
		"drydock":
			h2.call("Drydock"); p.call("Your crews work around the clock under a friendly station’s floodlights. Repair teams restore 60% of every ship’s missing hull.")
			if d["lines"].size() > 0:
				for l in d["lines"]: p.call("• " + l)
			else: p.call("The fleet was already in good order.", BONE2)
			v.add_child(foot([abtn("Manage fleet", "fleetFromModal", "", false, false, acts), fin("Continue", "closeModal", "", acts)]))
		"event":
			var ev = d["ev"]; h2.call(ev["t"]); p.call(ev["b"])
			for i in range(ev["o"].size()):
				var o = ev["o"][i]; var cost = o["r"].get("cost") if o["r"] is Dictionary else null; var ok = not C.jt(cost) or float(R["credits"]) >= float(cost)
				var blue = C.jt(o.get("need"))   # B4 blue options: the requirement in plain words, shown either way
				add(v, choice(o["l"], str(o["s"]) + ("" if ok else " (not enough credits)"), "eventChoice", i, acts, BLUE if blue else null, ("[" + C.needText(o["need"]) + "]") if blue else "", BLUE))
		"event_result":
			h2.call(d["ev"]["t"])
			for l in d["lines"]: p.call(l)
			v.add_child(foot([fin("Continue", "storyCore" if R.get("reward") != null and R["reward"].get("kind") == "story" else "closeModal", "", acts)]))
		"victory":
			var sm = d["summary"]; var cfg = sm["cfg"]
			h2.call("Flagship destroyed" if cfg["kind"] == "boss" else "Victory"); v.get_child(v.get_child_count() - 1).add_theme_color_override("font_color", GILT)   # Victory in lime display caps (ui_style.md 8)
			if C.beat3Debrief() != "": p.call(C.beat3Debrief(), VERD)
			v.add_child(rich(C.numstr(sm["kills"]) + " enemy ship" + ("" if int(sm["kills"]) == 1 else "s") + " destroyed in " + C.numstr(sm["rounds"]) + " round" + ("" if float(sm["rounds"]) == 1 else "s") + ". " + c("+", VERD) + n_(C.numstr(d["credits"]), VERD) + c(" credits.", VERD), 17))
			if sm["lost"].size() > 0:
				var ls = []
				for l in sm["lost"]: ls.append("the " + str(l["ship"]) + " and " + str(l["cap"]))
				p.call("Lost: " + ", ".join(PackedStringArray(ls)) + ".", BLOOD)
			if d["extra"] != "": p.call(d["extra"], VERD)
			if (R.get("boons") as Array).size() > 0 and (sm.get("boonStats", {}) as Dictionary).is_empty(): p.call("No protocol triggered this battle. Check the Fleet protocols section on a ship to see what sets each one off.", BONE3)
			var tstats: Dictionary = sm.get("treeStats", {}) if sm.get("treeStats") is Dictionary else {}
			if not tstats.is_empty():
				var tks = tstats.keys(); tks.sort(); var tls = []
				for key in tks: tls.append(_tree_name(str(key)) + " x" + C.numstr(tstats[key]))
				p.call("Lineage in action: " + ", ".join(PackedStringArray(tls)) + ".", VERD)
			if d["flagMoved"] != null: p.call("The admiral transfers the flag to the " + str(d["flagMoved"]["name"]) + ". Its aspect goes with it.", VERD)
			for x in sm["xp"]: v.add_child(rich("• " + esc(x["cap"]) + " of the " + esc(x["ship"]) + ": +" + C.numstr(x["xp"]) + " experience" + ((" " + c("promoted to " + str(C.RANKS[int(x["rank"])]), VERD)) if x["up"] else ""), 16))
			var rw = d["rw"]
			var nx: Button = null
			if _find(acts, "prizeStep", "").size() > 0: nx = fin("Decide on the prize ship" + ("s" if R["reward"]["prizes"].size() > 1 else ""), "prizeStep", "", acts)
			elif _find(acts, "salvageStep", "").size() > 0: nx = fin("Strip the wrecks", "salvageStep", "", acts)
			elif rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): nx = fin(str(C.PATRONS[rw["p"]]["short"]) + " offers a protocol", "rewardNext", "", acts)
			elif rw.get("k") == "mod": nx = fin("Choose a refit", "rewardNext", "", acts)
			else: nx = fin("Continue", "rewardNext", "", acts)
			v.add_child(foot([nx]))
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
				pv.add_child(rich("[b]" + esc(r["p"]["name"]) + "[/b] " + c(esc(H["n"]) + ", " + C.numstr(C.or_(H.get("cp"), 1)) + " command point" + ("s" if float(C.or_(H.get("cp"), 1)) > 1 else "") + ", " + str(hp) + "% hull", BONE3), 16))
				var g = GridContainer.new(); g.columns = 3; g.add_theme_constant_override("h_separation", px(6))
				var sm2 = (C.modName(r["o"]["strip"]["mod"]) + " + ") if C.jt(r["o"]["strip"]["mod"]) else ""
				for opt in [["add", "Add", ("Joins at " + str(hp) + "% hull") if r["room"] else ("Your faction cannot field it" if r.get("gate") != null else "No command points left")], ["strip", "Strip", sm2 + C.numstr(r["o"]["strip"]["cred"]) + " credits"], ["ransom", "Ransom", C.numstr(r["o"]["ransom"]) + " credits"]]:
					var b = choice(opt[1], opt[2], "prizeSet", str(i) + ":" + opt[0], acts, null, "", BONE2, r["k"] == opt[0])
					if b != null: b.custom_minimum_size.x = px(210); g.add_child(b)
				pv.add_child(g); v.add_child(pp)
			var parts = []
			if joins > 0: parts.append(str(joins) + " ship" + ("s join" if joins > 1 else " joins"))
			if refits > 0: parts.append(str(refits) + " refit" + ("s" if refits > 1 else "") + " for the hold")
			if cred > 0: parts.append("+" + C.numstr(cred) + " credits")
			p.call("You get: " + (", ".join(PackedStringArray(parts)) if parts.size() > 0 else "Nothing") + ".", BONE2)
			v.add_child(foot([fin("Confirm", "prizeConfirm", "", acts)]))
		"salvage":
			h2.call("Strip the wrecks"); p.call("Your crews have time to work one wreck before the fleet moves on.", BONE2); p.call(str(C.REWARD_DEF["salvage"]), BONE3)
			var ws = d["wrecks"]
			for i in range(ws.size()):
				var w = ws[i]; var y = w["yield"]; var F = C.FACTIONS.get(w.get("fac"))
				var pp = panel(IRON3, IRON2, 10); var pv = vbox(6); pp.add_child(pv)
				pv.add_child(rich("[b]" + esc(w["name"]) + "[/b] " + c(esc(C.clsName(C.or_(w.get("cls"), ""))) + ((", " + esc(F["n"])) if F != null else ""), BONE3) + "\n" + c(esc(C.CAUSE_WORD.get(w.get("cause"), "destroyed")) + ((" by the " + esc(w["by"])) if C.jt(w.get("by")) else "") + ".", BONE2), 16))
				var g = GridContainer.new(); g.columns = 3; g.add_theme_constant_override("h_separation", px(6))
				if C.jt(y.get("mod")): add(g, choice("Strip it: " + C.modName(y["mod"]), C.MODULES[y["mod"]]["d"], "takeSalvage", str(i) + ":mod", acts))
				add(g, choice("Scrap it", "+" + C.numstr(y["cred"]) + " credits", "takeSalvage", str(i) + ":cred", acts))
				if C.jt(y.get("tow")): add(g, choice("Tow it home", "Joins your fleet at 35% hull", "takeSalvage", str(i) + ":tow", acts))
				pv.add_child(g); v.add_child(pp)
		"mod":
			h2.call("Recovered refits"); p.call(str(C.REWARD_DEF["refit"]), BONE3); p.call("Take one. It goes in the hold; fit it at a shipyard or from the fleet screen.")
			for m in d["opts"]: add(v, choice(C.modName(m), C.MODULES[m]["d"], "takeMod", m, acts))
		"boon":
			var P = C.PATRONS[d["patron"]]; var pc = Color(P["col"])
			var hd = hbox(12); var sg = lbl(P["glyph"], 26, INK, font_semi, false); var sgp = panel(pc, pc, 6); sgp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN; sgp.add_child(sg); hd.add_child(sgp)
			var hv = vbox(0); hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hv.add_child(lbl(P["n"], 23, pc, font_goth)); hv.add_child(lbl(P["theme"], 15, BONE2)); hd.add_child(hv); v.add_child(hd)
			p.call("“" + str(P["quote"]) + "”", BONE2); p.call(str(C.REWARD_DEF["boon"]), BONE3)
			var offer = d["offer"]
			for i in range(offer.size()):
				var o = offer[i]; var b = C.BOONS[o["id"]]; var r = int(C.z0(o.get("r"))); var R0 = C.RARITY[r]; var duo = b.get("duo")
				var tag = ("Duo: " + " + ".join(PackedStringArray(duo.map(func(q): return str(C.PATRONS[q]["short"]))))) if C.jt(duo) else str(R0["n"])
				add(v, choice(b["n"], C.BOON_D[o["id"]][r], "takeBoon", i, acts, Color(C.PATRONS[duo[0]]["col"]) if C.jt(duo) else pc, tag, EMBER if C.jt(duo) else Color(R0["col"])))
			v.add_child(foot([abtn("Reroll the offer (" + C.numstr(d.get("rerollCost", 0)) + " credits, once)", "boonReroll", _arg_of(acts, "boonReroll"), false, false, acts),
				abtn("Decline: take " + C.numstr(d.get("declineCred", 0)) + " credits", "boonDecline", "", false, false, acts)]))
		"relic":
			h2.call("The flagship’s vault" if d["boss"] else "Spoils of the elite"); p.call(str(C.REWARD_DEF["relic"]), BONE3); p.call("Choose one.")
			for r in d["opts"]: add(v, choice(C.relicName(r), C.RELICS[r]["d"], "takeRelic", r, acts))
		"promote":
			var s = d["ship"]; h2.call("Promotion")
			v.add_child(rich(esc(s["cap"]["name"]) + " of the [i]" + esc(s["name"]) + "[/i] is now " + esc(C.rankName(s["cap"])) + ". Choose one perk.", 17)); p.call(str(C.REWARD_DEF["promotion"]), BONE3)
			for pk in s["cap"]["offer"]: add(v, choice(C.PERKS[pk]["n"], C.PERKS[pk]["d"], "takePerk", s["uid"] + ":" + pk, acts))
		"retreat":
			h2.call("Retreat?"); p.call("The fleet jumps out. Every surviving ship loses 10% of its hull, and this node counts as passed.")
			v.add_child(foot([abtn("Stay and fight", "c3retreatNo", "", false, false, acts), fin("Jump out", "c3retreatYes", "", acts)]))
		_:
			for a in acts: add(v, abtn(a[0] + " " + a[1], a[0], a[1], false, false, acts))
	_well_text(v)
	# size the box to its content, up to 90% of the window height
	var vh = get_viewport().get_visible_rect().size.y
	sc.custom_minimum_size = Vector2(px(700), min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))
	v.minimum_size_changed.connect(func(): sc.custom_minimum_size.y = min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))

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

func _unhandled_input(e: InputEvent) -> void:
	if C == null or not root.visible or not (e is InputEventKey) or not e.pressed or e.echo: return
	if C.modal_d == null and C.page.get("kind") == "map":   # the map: Esc shuts a slide-over, 1 to 9 pick a route, Enter flies it
		if _overlay != "":
			if e.keycode == KEY_ESCAPE: _close_overlay(); get_viewport().set_input_as_handled()
			return
		var rn = e.keycode - KEY_1
		if rn < 0 or rn >= 9: rn = e.keycode - KEY_KP_1
		if rn >= 0 and rn < 9 and rn < _routes.size():
			pick_route(str(_routes[rn]["id"])); get_viewport().set_input_as_handled(); return
		if e.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_jump(); get_viewport().set_input_as_handled(); return
	if C.modal_d != null:
		var acts = C.modal_d["acts"]
		if e.keycode == KEY_ESCAPE:
			for a in acts:
				if a[2] == 1 and (a[0] == "closeModal" or a[0] == "c3retreatNo"):
					C.act(a[0], a[1]); get_viewport().set_input_as_handled(); return
		var n = e.keycode - KEY_1
		if n >= 0 and n < 9:
			var on = acts.filter(func(a): return a[2] == 1)
			if n < on.size():
				C.act(on[n][0], on[n][1]); get_viewport().set_input_as_handled()
