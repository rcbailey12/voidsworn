extends CanvasLayer
# The campaign screens (G3): draws the campaign's current page and modal (godot/campaign/campaign.gd) the way today's game
# lays them out (campaign_run.js, campaign_meta.js, head.html): the same wording, the same buttons in the same order.
# Every button calls campaign.act(name, arg); the UI never changes campaign state itself.
# PC only: mouse, plus keys: Esc closes a dialog that has a close button, 1 to 9 pick a dialog's choices in order,
# Tab and the arrow keys move between buttons and map nodes, Enter or Space presses the focused one.
# Colours and fonts match the battle HUD (godot/ui/battle/hud.gd). Sizes scale with the window height (designed at 1080).

const MapView = preload("res://ui/campaign/map_view.gd")
const ChoiceScript = preload("res://ui/campaign/choice_button.gd")

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
const GLASS := Color(0.047, 0.07, 0.12, 0.80)

var C                      # the campaign (campaign.gd)
var k := 1.0
var font: Font
var font_semi: Font
var font_goth: Font
var root: Control
var bg: ColorRect
var page_box: Control
var modal_box: Control
var toast_box: VBoxContainer
var theme_main: Theme
var extra_title_buttons: Array = []   # [label, Callable] added under the title menu by the game shell (skirmish, settings ...)
var hide_on_battle := false           # the game shell shows its own battle scene on the battle page
var _acts: Array = []                 # the buttons the current screen allows
var _modal_acts: Array = []
var _dirty := false

func _ready() -> void:
	layer = 20
	font = _font("res://ui/battle/fonts/BarlowSemiCondensed-Regular.ttf")
	font_semi = _font("res://ui/battle/fonts/BarlowSemiCondensed-SemiBold.ttf")
	font_goth = _font("res://ui/battle/fonts/UnifrakturMaguntia-Book.ttf")
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(root)
	bg = ColorRect.new(); bg.color = INK; bg.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(bg)
	page_box = Control.new(); page_box.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(page_box)
	modal_box = Control.new(); modal_box.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(modal_box)
	toast_box = VBoxContainer.new(); toast_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH; toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE; toast_box.alignment = BoxContainer.ALIGNMENT_END; root.add_child(toast_box)
	get_viewport().size_changed.connect(func(): _rescale(); _dirty = true)
	_rescale()

func _font(p: String) -> Font:
	if ResourceLoader.exists(p): return load(p)
	var f = FontFile.new()
	if FileAccess.file_exists(p): f.load_dynamic_font(p)
	return f

func bind(campaign) -> void:
	C = campaign
	C.changed.connect(func(): _dirty = true)
	_dirty = true

func _rescale() -> void:
	k = clamp(get_viewport().get_visible_rect().size.y / 1080.0, 0.6, 2.5)
	theme_main = _make_theme(); root.theme = theme_main

func px(v: float) -> int: return int(round(v * k))

func _process(delta: float) -> void:
	if C == null: return
	if _dirty:
		_dirty = false; render()
	if C.toasts.size() > 0:
		for t in C.toasts: _toast(t)
		C.toasts.clear()

# ---------------- theme ----------------
func _sb(bgc: Color, border: Color, bw: int = 1, rad: int = 4, pad: float = 8.0) -> StyleBoxFlat:
	var s = StyleBoxFlat.new(); s.bg_color = bgc; s.border_color = border
	s.border_width_left = bw; s.border_width_right = bw; s.border_width_top = bw; s.border_width_bottom = bw
	s.corner_radius_top_left = rad; s.corner_radius_top_right = rad; s.corner_radius_bottom_left = rad; s.corner_radius_bottom_right = rad
	s.content_margin_left = px(pad * 1.4); s.content_margin_right = px(pad * 1.4); s.content_margin_top = px(pad); s.content_margin_bottom = px(pad)
	return s
func _make_theme() -> Theme:
	var t = Theme.new()
	t.default_font = font; t.default_font_size = px(18)
	t.set_color("font_color", "Label", BONE)
	t.set_color("default_color", "RichTextLabel", BONE)
	t.set_font("normal_font", "RichTextLabel", font); t.set_font("bold_font", "RichTextLabel", font_semi)
	t.set_font_size("normal_font_size", "RichTextLabel", px(17)); t.set_font_size("bold_font_size", "RichTextLabel", px(17))
	t.set_stylebox("normal", "Button", _sb(IRON2, IRON3)); t.set_stylebox("hover", "Button", _sb(IRON3, GILT2))
	t.set_stylebox("pressed", "Button", _sb(IRON3, GILT)); t.set_stylebox("focus", "Button", _sb(Color(0, 0, 0, 0), GILT, 2))
	t.set_stylebox("disabled", "Button", _sb(Color(IRON2, 0.5), Color(IRON3, 0.5)))
	t.set_color("font_color", "Button", BONE); t.set_color("font_hover_color", "Button", BONE); t.set_color("font_pressed_color", "Button", BONE)
	t.set_color("font_disabled_color", "Button", BONE3); t.set_color("font_focus_color", "Button", BONE)
	t.set_font_size("font_size", "Button", px(17))
	t.set_stylebox("panel", "PanelContainer", _sb(IRON, IRON3, 1, 4, 12))
	t.set_stylebox("panel", "TooltipPanel", _sb(IRON2, GILT2, 1, 4, 6))
	t.set_color("font_color", "TooltipLabel", BONE); t.set_font_size("font_size", "TooltipLabel", px(15))
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
func rich(bb: String, size: float = 17) -> RichTextLabel:
	var r = RichTextLabel.new(); r.bbcode_enabled = true; r.fit_content = true; r.scroll_active = false; r.text = bb
	r.add_theme_font_size_override("normal_font_size", px(size)); r.add_theme_font_size_override("bold_font_size", px(size))
	r.mouse_filter = Control.MOUSE_FILTER_PASS; r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r
func c(text: String, col: Color) -> String: return "[color=" + hexs(col) + "]" + text + "[/color]"
func gothic(text: String, size: float = 52) -> Label: return lbl(text, size, BONE, font_goth, true)
func vbox(sep: float = 8) -> VBoxContainer:
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", px(sep)); return v
func hbox(sep: float = 10) -> HBoxContainer:
	var h = HBoxContainer.new(); h.add_theme_constant_override("separation", px(sep)); return h
func spacer() -> Control:
	var s = Control.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL; return s
func flow(sep: float = 14) -> HFlowContainer:
	var f = HFlowContainer.new(); f.add_theme_constant_override("h_separation", px(sep)); f.add_theme_constant_override("v_separation", px(sep)); return f
func panel(border: Color = IRON3, bgc: Color = IRON, pad: float = 14) -> PanelContainer:
	var p = PanelContainer.new(); p.add_theme_stylebox_override("panel", _sb(bgc, border, 1, 4, pad)); return p
func card(sel: bool = false, width: float = 300) -> Array: # [PanelContainer, VBoxContainer]
	var p = panel(GILT if sel else IRON3, IRON, 14); p.custom_minimum_size.x = px(width)
	if sel: p.add_theme_stylebox_override("panel", _sb(IRON, GILT, 2, 4, 14))
	var v = vbox(6); p.add_child(v); return [p, v]
func bar(f: float, w: float = 0) -> Control:
	var b = ColorRect.new(); b.color = Color("#3a1d1d"); b.custom_minimum_size = Vector2(px(w), px(6)); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var i = ColorRect.new(); i.color = BLOOD if f < 0.35 else Color("#ffae42"); i.anchor_bottom = 1.0; i.anchor_right = clamp(f, 0.0, 1.0); b.add_child(i)
	return b
# A button for one of the screen's allowed actions; returns null when the screen does not offer it.
func _find(list: Array, act: String, arg) -> Array:
	var a = "" if arg == null else str(arg)
	for x in list:
		if x[0] == act and x[1] == a: return x
	return []
func abtn(text: String, act: String, arg = "", primary: bool = false, small: bool = false, list = null) -> Button:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = Button.new(); b.text = text; b.disabled = found[2] == 0; b.focus_mode = Control.FOCUS_ALL
	if small: b.add_theme_font_size_override("font_size", px(15))
	if primary:
		b.add_theme_stylebox_override("normal", _sb(GILT, GILT)); b.add_theme_stylebox_override("hover", _sb(Color("#e2bb62"), Color("#e2bb62")))
		b.add_theme_color_override("font_color", Color("#1c1405")); b.add_theme_color_override("font_hover_color", Color("#1c1405")); b.add_theme_font_override("font", font_semi)
	var aa = found[1]
	b.pressed.connect(func(): C.act(act, aa))
	return b
# A choice button: a bold line and a small line under it (the browser's .choice). Sized by its text.
func choice(title: String, small: String, act: String, arg = "", list = null, accent = null, tag: String = "", tagcol: Color = BONE2, sel: bool = false) -> Control:
	var found = _find(list if list != null else _acts, act, arg)
	if found.is_empty(): return null
	var b = ChoiceScript.new(); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var n = _sb(Color(GILT, 0.12) if sel else IRON2, GILT if sel else IRON3, 2 if sel else 1, 4, 9)
	var h = _sb(IRON3, GILT2, 1, 4, 9); var f = _sb(IRON3, GILT, 2, 4, 9)
	if accent != null:
		for sb in [n, h, f]: sb.border_width_left = px(4); sb.border_color = accent
	b.setup(n, h, f, found[2] == 0)
	var v = vbox(2); v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tag != "": v.add_child(lbl(tag.to_upper(), 12, tagcol, font_semi))
	v.add_child(lbl(title, 18, GILT if sel else BONE, font_semi))
	if small != "": v.add_child(lbl(small, 15, BONE2))
	for l in v.get_children():
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_child(v)
	var aa = found[1]
	b.pressed.connect(func(): C.act(act, aa))
	return b
func add(parent: Node, child) -> void:
	if child != null: parent.add_child(child)
func _toast(msg: String) -> void:
	var p = panel(GILT2, IRON2, 10); p.add_child(lbl(msg, 16, BONE)); p.custom_minimum_size.x = px(min(900, 260 + msg.length() * 7))
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
	var body: Control = null
	match pg["kind"]:
		"title": body = _title()
		"admiral": body = _wrap_page(_admiral())
		"aspect": body = _wrap_page(_aspect())
		"map": body = _map()
		"fleet": body = _wrap_page(_fleet(pg["data"]))
		"shipyard": body = _wrap_page(_shipyard())
		"battle": body = _battle_stub(pg["data"])
		"legacy": body = _wrap_page(_legacy())
		"help": body = _wrap_page(_help(), 820)
		"end": body = _end(pg["data"])
		_: body = lbl("")
	page_box.add_child(body)
	if C.modal_d != null: _modal(C.modal_d)
	call_deferred("_focus_first")
func _focus_first() -> void:
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
	m.add_theme_constant_override("margin_top", px(28)); m.add_theme_constant_override("margin_bottom", px(60))
	inner.custom_minimum_size.x = min(px(maxw), int(get_viewport().get_visible_rect().size.x) - px(80))
	m.add_child(inner); hb.add_child(spacer()); hb.add_child(m); hb.add_child(spacer()); sc.add_child(hb)
	return sc

# ---------------- title ----------------
func _title() -> Control:
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var v = vbox(10); v.custom_minimum_size.x = px(640); v.alignment = BoxContainer.ALIGNMENT_CENTER
	var h = lbl("Voidsworn", 148, BONE, font_goth, false); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(h)
	var s = lbl("Command a crusade of gothic capital ships through three hostile sectors. Every hull you lose stays lost, and so does its captain.", 20, BONE2)
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
		var a = C.ADMIRALS[id]; var un = C.jt(C.META["admirals"].get(id))
		var cv = card(C.picked_admiral == id, 330); var col = cv[1]
		if not un: cv[0].modulate.a = 0.55
		col.add_child(lbl(a["n"], 20, BONE, font_semi)); col.add_child(lbl(a["doc"], 16, GILT)); col.add_child(lbl(a["d"], 16, BONE2))
		col.add_child(_mastery_bar(id))
		var fleet = []
		for t in a["start"]: fleet.append(C.HULLS[C.equivHull(t, C.picked_faction)]["n"])
		col.add_child(rich(c("Starting fleet:", BONE3) + " " + esc(", ".join(PackedStringArray(fleet))), 16))
		if C.jt(a.get("cmd")):
			col.add_child(rich(c("Command:", BONE3) + " [b]" + c(esc(a["cmd"]["n"]), GILT) + "[/b]. " + esc(_cmd_text(a["cmd"], C.picked_faction)) + " " + c("Gets stronger each round you hold it.", BONE3), 16))
		if un: add(col, abtn("Selected" if C.picked_admiral == id else "Select", "pickAdmiral", id, C.picked_admiral == id))
		else: col.add_child(lbl("Unlock for " + C.numstr(a.get("cost")) + " renown in Legacy", 15, BONE2))
		cards.add_child(cv[0])
	v.add_child(cards)
	v.add_child(_run_options())
	var row = hbox(); add(row, abtn("Launch the " + C.runWord(C.picked_faction), "startRun", "", true)); add(row, abtn("Back", "title")); v.add_child(row)
	return v
func _cmd_text(cmd, fac) -> String:
	var t = C.CMD_TEXT.get(cmd["id"])
	return str(t.get(fac, "")) if t != null else ""
func _mastery_bar(id) -> Control:
	var l = C.masteryLevel(id); var x = C.masteryXP(id); var nx = C.MASTERY_XP[l + 1] if l + 1 < C.MASTERY_XP.size() else null
	var f = min(1.0, (x - float(C.MASTERY_XP[l])) / (float(nx) - float(C.MASTERY_XP[l]))) if nx != null else 1.0
	var v = vbox(3)
	v.add_child(rich(c("Mastery " + str(l) + "/4", GILT) + " " + c((C.numstr(x) + "/" + C.numstr(nx) + ": next " + str(C.MASTERY_PERKS[l + 1]["n"]).to_lower()) if nx != null else "mastered", BONE3), 14))
	var b = bar(f); b.get_child(0).color = GILT; v.add_child(b)
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
		cv4[1].add_child(lbl("Win a run to unlock Heat: optional rules that make runs harder and pay more renown.", 16, BONE3)); cards.add_child(cv4[0])
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
		var gb = R["giftBoon"]; v.add_child(rich(c("A gift from " + esc(C.PATRONS[C.BOONS[gb]["p"]]["n"]) + ", who counts you Devoted: [b]" + esc(C.BOONS[gb]["n"]) + "[/b].", GILT), 17))
	if R.get("heat") is Array and R["heat"].size() > 0:
		var hn = []
		for kk in R["heat"]: hn.append(C.HEAT[kk]["n"])
		v.add_child(lbl("Heat " + C.numstr(C.heatLevel(R["heat"])) + ": " + ", ".join(PackedStringArray(hn)) + ".", 17, BLOOD))
	var ps = []
	for p in R["patrons"]: ps.append("[b]" + c(esc(C.PATRONS[p]["n"]), Color(C.PATRONS[p]["col"])) + "[/b] (" + esc(str(C.PATRONS[p]["theme"]).to_lower()) + ")")
	v.add_child(rich(c("Patrons watching this " + C.runWord() + ": ", BONE3) + "; ".join(PackedStringArray(ps)) + c(". Win battles marked with their sigil to earn their boons.", BONE3), 16))
	return v

# ---------------- the sector map ----------------
func _map() -> Control:
	var R = C.RUN; var m = R["map"]; var F = C.FACTIONS[m["fac"]]
	var hb = HBoxContainer.new(); hb.set_anchors_preset(Control.PRESET_FULL_RECT); hb.add_theme_constant_override("separation", 0)
	var main = vbox(6); main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mm = MarginContainer.new(); mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]: mm.add_theme_constant_override("margin_" + side, px(24))
	mm.add_child(main); hb.add_child(mm)
	var head = hbox()
	head.add_child(lbl("Sector " + C.roman(R["sector"]) + ((": " + str(C.REGIONS[m["region"]]["n"])) if C.jt(m.get("region")) and C.REGIONS.has(m["region"]) else ""), 44, BONE, font_goth, false))
	head.add_child(spacer()); add(head, abtn("Save and quit", "saveQuit")); main.add_child(head)
	var hp = c("Hostile presence: ", BONE2) + "[b]" + c(esc(F["n"]), BLOOD) + "[/b]. " + c(esc(F.get("blurb", "")), BONE2)
	if R.get("foes") is Array and R["foes"].size() >= 5:
		hp += " " + c("Rival raiders from the " + esc(str(C.FACTIONS[R["foes"][3]]["n"]).trim_prefix("The ")) + " and the " + esc(str(C.FACTIONS[R["foes"][4]]["n"]).trim_prefix("The ")) + " may also strike.", BONE3)
	main.add_child(rich(hp, 16))
	var cond = C.sectorCond()
	if cond != null: main.add_child(rich(c("Sector condition: [b]" + esc(cond["n"]) + "[/b].", GILT) + " " + c(esc(cond["d"]), BONE2), 16))
	var mv = MapView.new(); mv.ui = self; mv.size_flags_vertical = Control.SIZE_EXPAND_FILL; mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv.custom_minimum_size = Vector2(px(600), px(320)); main.add_child(mv)
	var legend = flow(14)
	for kk in C.NODE_INFO.keys(): legend.add_child(lbl("● " + str(C.NODE_INFO[kk]["n"]), 14, BLOOD if kk == "elite" or kk == "boss" else BONE2, null, false))
	main.add_child(legend)
	# what the reachable fights are (the browser's encounter previews)
	var seen = {}; var prev = vbox(6)
	for id in C.page["data"]["avail"]:
		var n = C.findNode(id)
		if n == null or not C.jt(n.get("enc")) or not C.ENCOUNTERS.has(n["enc"]): continue
		var key = str(n["enc"]) + "|" + _reward_label(n.get("rw")) + "|" + str(n["type"]) + "|" + str(n.get("arch")) + "|" + str(n.get("mod"))
		if seen.has(key): continue
		seen[key] = true
		var E = C.ENCOUNTERS[n["enc"]]; var fac = C.nodeFaction(n); var al = _arch_label(n, fac)
		var t = "[b]" + c(esc(E["n"]), GILT) + "[/b]"
		if al != "": t += " " + c("· " + esc(al), BLOOD)
		if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): t += " " + c("· " + esc(C.NODE_MODS[n["mod"]]["n"]), GILT)
		if n["type"] == "elite": t += " " + c("(elite)", BLOOD)
		if C.jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]): t += " " + c("· " + str(C.SHAPES[n["shape"]]).to_lower(), BONE3)
		t += "\n" + c(esc(E["d"]), BONE2)
		if C.jt(n.get("arch")) and C.ARCHETYPES.has(n["arch"]): t += "\n" + c(esc(C.ARCHETYPES[C.effArch(n["arch"], fac)]["d"]), BONE2)
		if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): t += "\n" + c(esc(C.NODE_MODS[n["mod"]]["d"]), GILT)
		if C.jt(n.get("rw")):
			var rw = n["rw"]; var rc = Color(C.PATRONS[rw["p"]]["col"]) if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")) else BONE2
			t += "\n" + c("Reward: " + _reward_label(rw) + (" (rare or better)" if C.jt(rw.get("min")) else ""), rc)
		var p = panel(Color(GILT, 0.22), Color(0.055, 0.08, 0.125, 0.55), 8); p.add_child(rich(t, 15)); prev.add_child(p)
	main.add_child(prev)
	main.add_child(lbl("Choose a pulsing node to jump there. You can only move forward along the lines.", 15, BONE3))
	hb.add_child(_side())
	return hb
func _reward_label(rw) -> String:
	if rw == null or not (rw is Dictionary): return ""
	if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): return "Boon of " + str(C.PATRONS[rw["p"]]["short"])
	match rw.get("k"):
		"mod": return "Refit"
		"cred": return "Credits"
		"repair": return "Repairs"
	return ""
func _arch_label(n, fac) -> String:
	if not C.jt(n.get("arch")): return ""
	var a = C.effArch(n["arch"], fac)
	if a == null or not C.ARCHETYPES.has(a): return ""
	var names = C.ARCHETYPES[a]["names"]
	return str(names.get(fac, names.get("hegemony", "")))
func _side() -> Control:
	var R = C.RUN
	var p = panel(Color(GILT, 0.2), Color(0.047, 0.07, 0.12, 0.85), 18); p.custom_minimum_size.x = px(380)
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var v = vbox(6); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL; sc.add_child(v); p.add_child(sc)
	var top = hbox()
	var cr = vbox(0); cr.add_child(lbl("Credits", 14, BONE3)); cr.add_child(lbl(C.numstr(R["credits"]), 26, GILT, font_semi)); top.add_child(cr)
	top.add_child(spacer())
	var cp = vbox(0); var l1 = lbl("Command points", 14, BONE3); l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; cp.add_child(l1)
	var l2 = rich("[right]" + C.numstr(C.fleetCP()) + c("/" + C.numstr(R["cpCap"]), BONE3) + "[/right]", 26); cp.add_child(l2); cp.custom_minimum_size.x = px(140); top.add_child(cp)
	v.add_child(top)
	var A = C.ADMIRALS[R["admiral"]]
	v.add_child(lbl("Admiral: " + str(A["n"]) + ", " + str(A["doc"]).to_lower(), 15, BONE3))
	v.add_child(lbl("Fleet", 19, GILT, font_semi))
	for s in R["fleet"]:
		var d = C.derive(s); var row = vbox(2)
		var r1 = hbox(); r1.add_child(lbl(s["name"], 16)); r1.add_child(spacer()); r1.add_child(lbl(C.numstr(s["hp"]) + "/" + C.numstr(d["maxHp"]), 15, BONE3, null, false)); row.add_child(r1)
		row.add_child(rich(c(esc(C.HULLS[s["tpl"]]["cls"]) + " Mk " + C.roman(s["mk"]) + ", " + esc(C.rankName(s["cap"])) + " " + esc(s["cap"]["name"]), BONE3) + (" " + c("(promotion ready)", GILT) if C.jt(s["cap"].get("pending")) else ""), 14))
		row.add_child(bar(float(s["hp"]) / float(d["maxHp"]))); v.add_child(row)
	var pend = R["fleet"].any(func(s): return C.jt(s["cap"].get("pending")))
	add(v, abtn("Promote captains and refit" if pend else "Manage fleet and refits", "fleetScreen", "", pend))
	if R["inventory"].size() > 0: v.add_child(lbl(str(R["inventory"].size()) + " refit" + ("s" if R["inventory"].size() > 1 else "") + " in the hold.", 15, BONE3))
	if C.jt(R.get("aspect")) and C.ASPECTS.has(R["aspect"]):
		v.add_child(lbl("Flagship", 19, GILT, font_semi)); var fs = C.flagshipOf()
		v.add_child(rich("[b]" + esc(fs["name"] if fs != null else "") + "[/b] " + c(esc(C.ASPECTS[R["aspect"]]["n"]), GILT), 16)); v.add_child(lbl(C.ASPECTS[R["aspect"]]["d"], 14, BONE2))
	v.add_child(lbl("Boons", 19, GILT, font_semi))
	if R["boons"].size() > 0:
		for b in R["boons"]: v.add_child(_boon_line(b))
	else: v.add_child(lbl("None yet. Win at a node with a patron’s sigil to earn one.", 15, BONE3))
	var ps = []
	for pp in R["patrons"]: ps.append(c(esc(C.PATRONS[pp]["short"]), Color(C.PATRONS[pp]["col"])))
	v.add_child(rich(c("Patrons this run: ", BONE3) + ", ".join(PackedStringArray(ps)), 14))
	v.add_child(lbl("Relics", 19, GILT, font_semi))
	if R["relics"].size() > 0:
		for r in R["relics"]: v.add_child(rich("[b]" + esc(C.relicName(r)) + "[/b]\n" + c(esc(C.RELICS[r]["d"]), BONE2), 15))
	else: v.add_child(lbl("None yet. Elite fleets and flagships carry them.", 15, BONE3))
	return p
func _boon_line(b) -> Control:
	var B0 = C.BOONS[b["id"]]; var r = int(C.z0(b.get("r")))
	var col = Color(C.PATRONS[B0["p"]]["col"]) if C.jt(B0.get("p")) else Color("#f0b35a")
	var R0 = C.RARITY[r]
	var h = hbox(8); var stripe = ColorRect.new(); stripe.color = col; stripe.custom_minimum_size.x = px(3); h.add_child(stripe)
	h.add_child(rich("[b]" + esc(B0["n"]) + "[/b] " + c("Duo" if C.jt(B0.get("duo")) else str(R0["n"]), Color(R0["col"])) + "\n" + c(esc(C.BOON_D[b["id"]][r]), BONE2), 14))
	return h

# ---------------- ship cards, fleet, shipyard ----------------
func _ship_card(s: Dictionary, refit: bool, extra: Array = []) -> Control:
	var t = C.HULLS[s["tpl"]]; var d = C.derive(s); var cap = s["cap"]
	var cv = card(false, 330); var v = cv[1]
	var r0 = hbox(); r0.add_child(lbl(s["name"], 20, BONE, font_semi)); r0.add_child(spacer()); r0.add_child(lbl("Mk " + C.roman(s["mk"]), 14, GILT, null, false)); v.add_child(r0)
	v.add_child(lbl(t["n"], 16, BONE2))
	var r1 = hbox(); r1.add_child(lbl("Hull " + C.numstr(s["hp"]) + "/" + C.numstr(d["maxHp"]), 15)); r1.add_child(spacer()); r1.add_child(lbl(C.numstr(t["cp"]) + " CP", 15, BONE3, null, false)); v.add_child(r1)
	v.add_child(bar(float(s["hp"]) / float(d["maxHp"])))
	v.add_child(rich("[b]" + c("Shields", BONE2) + "[/b] " + C.numstr(d["shMax"]) + ", +" + C.numstr(d["regen"]) + "/turn   [b]" + c("Armor", BONE2) + "[/b] " + C.pct(d["armor"]) + "\n[b]" + c("Speed", BONE2) + "[/b] " + C.numstr(d["speed"]) + "   [b]" + c("Turns", BONE2) + "[/b] " + C.numstr(d["turns"]) + "   [b]" + c("Evasion", BONE2) + "[/b] " + C.numstr(d["ev"]), 15))
	if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]): v.add_child(rich(c(esc(C.ABILITIES[t["ab"]]["n"]) + ".", GILT) + " " + c(esc(C.ABILITIES[t["ab"]]["d"]), BONE3), 15))
	for w in d["weapons"]:
		var arc = "Turret" if w["arc"] == "T" else str(C.ARC_NAME.get(w["arc"], w["arc"]))
		v.add_child(lbl(str(w["n"]) + "  " + arc + "  " + C.numstr(w["shots"]) + "×" + C.numstr(w["dmg"]) + ", range " + C.numstr(w["r"]) + ((", reload " + C.numstr(w["cd"])) if C.jt(w.get("cd")) else ""), 14, BONE3))
	var sect = vbox(4); sect.add_child(HSeparator.new())
	sect.add_child(lbl(C.rankName(cap) + " " + str(cap["name"]), 16, GILT, font_semi))
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
	var rs = vbox(4); rs.add_child(HSeparator.new()); rs.add_child(lbl("Refits", 16, GILT, font_semi))
	for i in range(int(t["slots"])):
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
	add(head, abtn("Done", "backShipyard" if d["back"] == "shipyard" else "backMap", "", true)); v.add_child(head)
	v.add_child(lbl("Refits can be moved between ships freely. Mark upgrades and repairs happen at shipyards and drydocks.", 18, BONE2))
	var R = C.RUN
	if R["inventory"].size() > 0:
		v.add_child(lbl("In the hold", 20, BONE, font_semi))
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
	head.add_child(lbl(C.numstr(R["credits"]) + " credits", 22, GILT, font_semi, false)); head.add_child(lbl(C.numstr(cp) + "/" + C.numstr(R["cpCap"]) + " CP", 18, BONE, null, false))
	add(head, abtn("Refits", "yardFleet")); add(head, abtn("Leave shipyard", "leaveYard", "", true)); v.add_child(head)
	v.add_child(lbl("Repairs cost 1 credit per 2 hull. A Mark upgrade adds 20% hull and shields and 15% damage. New hulls come with a fresh lieutenant.", 18, BONE2))
	var allMiss = 0.0
	for s in R["fleet"]: allMiss += float(C.derive(s)["maxHp"]) - float(s["hp"])
	add(v, abtn(("Repair entire fleet for " + C.numstr(ceil(allMiss / 2.0 * pm))) if allMiss > 0 else "Fleet fully repaired", "repairAll"))
	var cards = flow()
	for s in R["fleet"]:
		var d = C.derive(s); var miss = float(d["maxHp"]) - float(s["hp"]); var rc = ceil(miss / 2.0 * pm); var mc = C.mkCost(s); var sell = C.jsround(float(C.HULLS[s["tpl"]]["cost"]) * 0.35)
		var ex = [abtn(("Repair " + C.numstr(miss) + " for " + C.numstr(rc)) if miss > 0 else "Fully repaired", "repair", s["uid"], false, true),
			abtn(("Mk " + C.roman(float(s["mk"]) + 1) + " for " + C.numstr(mc)) if float(s["mk"]) < 3 else "Max Mark", "upgradeMk", s["uid"], false, true),
			abtn("Decommission (+" + C.numstr(sell) + ")", "sellShip", s["uid"], false, true)]
		cards.add_child(_ship_card(s, false, ex))
	v.add_child(cards)
	v.add_child(lbl("Hulls for sale", 20, BONE, font_semi))
	var hs = flow()
	for h in st["hulls"]:
		var t = C.HULLS[h]; var cost = C.jsround(float(t["cost"]) * pm); var fits = cp + float(t["cp"]) <= float(R["cpCap"])
		var uniq = C.jt(t.get("unique")) and R["fleet"].any(func(s): return s["tpl"] == h)
		var cv = card(false, 320); var cvv = cv[1]
		cvv.add_child(rich("[b]" + esc(t["n"]) + "[/b]" + (" " + c("Variant", GILT) if C.jt(t.get("variant")) else ""), 20))
		if C.jt(t.get("variant")): cvv.add_child(lbl(C.HULL_VARIANTS[t["variant"]]["d"], 15, GILT))
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
	v.add_child(lbl("Refits for sale", 20, BONE, font_semi))
	var ms = flow()
	for i in range(st["mods"].size()):
		var m = st["mods"][i]; var cv2 = card(false, 300)
		cv2[1].add_child(lbl(C.modName(m), 20, BONE, font_semi)); cv2[1].add_child(lbl(C.MODULES[m]["d"], 16, BONE2))
		if C._has_num(st["sold"], i): cv2[1].add_child(lbl("Bought", 16, VERD))
		else: add(cv2[1], abtn("Buy for " + C.numstr(C.jsround(float(C.MODULES[m]["cost"]) * pm)), "buyMod", i))
		ms.add_child(cv2[0])
	v.add_child(ms)
	return v

# ---------------- the battle page (stub battles; the game shell replaces it with the real battle) ----------------
func _battle_stub(d: Dictionary) -> Control:
	var cfg = d["cfg"]; var E = C.ENCOUNTERS.get(cfg.get("obj"), C.ENCOUNTERS["rout"])
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p = panel(GILT2, IRON, 24); p.custom_minimum_size.x = px(720); var v = vbox(10); p.add_child(v)
	var kind = "flagship battle" if cfg["kind"] == "boss" else (("elite " if cfg["kind"] == "elite" else "") + str(E["n"]).to_lower())
	v.add_child(lbl("Sector " + C.roman(C.RUN["sector"]) + ": " + kind + " against " + str(C.FACTIONS[cfg["fac"]]["n"]), 30, BONE, font_goth))
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
	for t in [["variants", "Hull variants"], ["mastery", "Admiral mastery"], ["favour", "Patron favour"], ["heat", "Heat"], ["fallen", "Hall of the fallen"]]: add(tabs, abtn(t[1], "progTab", t[0], C.prog_tab == t[0]))
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
					else: add(cv[1], abtn("Unlock for " + C.numstr(hv["cost"]) + " renown", "buyVariant", vid))
					cards.add_child(cv[0])
				v.add_child(cards)
		"mastery":
			v.add_child(lbl("Every run levels up the admiral who led it: 1 per battle won, 2 per elite, 5 per flagship and 10 for a victory.", 17, BONE2))
			var mc = flow()
			for i in range(1, C.MASTERY_PERKS.size()):
				var cv = card(false, 300); cv[1].add_child(lbl("Level " + str(i) + ": " + str(C.MASTERY_PERKS[i]["n"]), 19, BONE, font_semi)); cv[1].add_child(lbl(C.MASTERY_PERKS[i]["d"], 16, BONE2)); cv[1].add_child(lbl(C.numstr(C.MASTERY_XP[i]) + " mastery", 14, BONE3)); mc.add_child(cv[0])
			v.add_child(mc)
			for f in C.favFirst():
				v.add_child(lbl(C.FACTIONS[f]["n"], 20, BONE, font_semi)); var ac = flow()
				for id in C.ADMIRALS.keys():
					if C.or_(C.ADMIRALS[id].get("fac"), "voidsworn") != f: continue
					var cv2 = card(false, 300); cv2[1].add_child(lbl(C.ADMIRALS[id]["n"], 19, BONE, font_semi)); cv2[1].add_child(lbl(C.ADMIRALS[id]["doc"], 15, GILT)); cv2[1].add_child(_mastery_bar(id)); ac.add_child(cv2[0])
				v.add_child(ac)
		"favour":
			v.add_child(lbl("Every boon you take raises that patron's favour (rare boons count double, epic triple).", 17, BONE2))
			var fc = flow()
			for i in range(1, C.FAVOUR_TIERS.size()):
				var cv = card(false, 300); cv[1].add_child(rich("[b]" + esc(C.FAVOUR_TIERS[i]["n"]) + "[/b] " + c(C.numstr(C.FAVOUR_TIERS[i]["at"]) + "+", BONE3), 19)); cv[1].add_child(lbl(C.FAVOUR_TIERS[i].get("d", ""), 16, BONE2)); fc.add_child(cv[0])
			v.add_child(fc)
			for p in C.PATRONS.keys():
				var P = C.PATRONS[p]; var f = C.favourOf(p); var t = C.favourTier(p); var nx = C.FAVOUR_TIERS[t + 1] if t + 1 < C.FAVOUR_TIERS.size() else null
				var r = hbox(); r.add_child(lbl(P["glyph"], 18, Color(P["col"]), font_semi, false)); r.add_child(rich("[b]" + esc(P["n"]) + "[/b]\n" + c(esc(P["theme"]), BONE3), 15))
				r.add_child(rich("[right][b]" + c(esc(C.FAVOUR_TIERS[t]["n"]), Color(P["col"])) + "[/b]\n" + c(C.numstr(f) + ((" / " + C.numstr(nx["at"])) if nx != null else ""), BONE3) + "[/right]", 15)); v.add_child(r)
		"heat":
			var wins = float(C.z0(st.get("wins")))
			v.add_child(lbl("Heat is open. Pick rules on the admiral screen before a run; each level adds 10% renown." if wins > 0 else "Win a run to open Heat.", 17, BONE2))
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
	["", "Voidsworn is a roguelite. Each run crosses three sectors, each ending in a flagship battle. Ships and captains you lose are gone for the run; every faction, admiral and ship is available from the start."],
	["", "What carries between runs (Progression, on the title screen): renown buys hull variants for your shipyards; each admiral levels up as you fly with them, unlocking an alternate fleet, a fourth aspect, a second Command and a veteran flag captain; patrons grow fond of you as you take their boons, offering rarer boons and eventually a gift at the start of a run; and after your first victory, Heat lets you add harder rules for more renown. After each sector flagship falls, the fleet docks at a shipyard before its next fight."],
	["Your turn", "Every ship can move, turn and fire each of its weapons once per turn, in any order. Click a ship, then click a highlighted hex to move. Moving forward costs 1 movement. Turning 60° also costs 1 movement and uses one of the ship’s turns; big ships only get one turn per round, so plan their heading early. Press Q and E to turn in place."],
	["", "Thrusters keep you from getting boxed in. A ship can slip into either forward-diagonal hex, or back off one hex, without changing its heading (2 movement each; a slow ship can always spend its whole move on one hop). It can climb over a rock or wreck, or dive under an enemy ship, for +1 movement, but cannot stop there. Each faction bends one of these rules: see the Helm panel."],
	["", "Ships fight on the move. Click an enemy your guns can't reach yet and the ship burns to the best spot and fires as it arrives."],
	["", "Moving matters. A ship that did not move last turn gets hit more easily (+10 to hit). One that moved 3+ hexes is harder to hit (−5). Port and starboard guns hit 10% harder on a raking pass, after moving 2+ hexes."],
	["Firing arcs", "Weapons only fire into their arc. Prow weapons cover the 120° in front, port and starboard broadsides each cover a wide 120° cone to the side, and turrets fire anywhere. The tinted hexes around a selected ship show where its guns reach: amber for the prow, teal for broadsides. Click an enemy to fire everything that can reach it, or press a number key to fire a single weapon."],
	["Shields and flanking", "Each ship has four shield facings: prow, port, starboard and rear. Damage hits the facing that points at the attacker, and shields regenerate at the start of each of your turns. Rear hits halve armor and are far more likely to crit, so getting behind a battleship matters. Lances and bombers punch partly or fully through shields. Ion cannons shred shields; gauss weapons mostly ignore them."],
	["Different fights", "Each fight on the sector map is labelled with its goal. Engagements and ambushes end when one fleet breaks. In Hold the station you keep enemies off a friendly station until round 6 ends. In a Hunt their flagship runs and jumps out after round 6. In an Intercept you destroy transports before they cross the field. In a Breakthrough you get half your fleet off the far edge. Missing a Hunt or Intercept still pays half; losing the station or a breakthrough means a retreat, not the end of the run. Click the chip under the top bar in battle for the rules and the coloured hexes."],
	["", "Some fights change partway through: reinforcements for either side, or a solar flare that knocks out every shield for a round. You always get a round of warning."],
	["Brace, abilities and Command", "Brace is the alternative to firing: a ship that hasn’t fired can brace to take 40% less hull damage until your next turn (it can still move first). To ram, point your bow at an enemy ship with at least one clear hex between you and enough movement left to cross the gap: a red lane shows when a ram is ready, and red-ringed move hexes line one up. A longer run-up hits harder; a ram can’t take more than 40% of a healthy ship’s hull without boons. Boarding an adjacent enemy can capture it for your fleet; enemy boarders can cripple your ships, but never take them. Carriers start every battle with their wings already flying; the wings fight on their own unless you order them: click a wing, then click an enemy ship to strike it or one of your ships to guard it. The carrier’s launch only replaces wings you lose. Most hulls have an ability with a cooldown, and each faction has its own. Enemy flagships carry a Command too: they announce it a round ahead, so you can brace or scatter. Once per battle, your admiral’s Command is a fleet-wide signature move. It gets stronger each round you hold it (power 1 in round 1, 2 in round 2, full power from round 3, and losing a ship charges it a level), so the choice is a smaller boost now or a bigger one later, if the fight lasts that long. The ship panel shows exactly what the next level adds."],
	["Patrons, boons and your flagship", "Each run, four of six patrons watch your run. Battles on the map carry a patron’s sigil: win there and that patron offers three boons, and you take one. Boons change the rules (fires, chain explosions, rams that shake the whole formation) and come in Common, Rare and Epic strength. Hold boons from two patrons and a duo boon can appear. At the start of a run you also pick one of three aspects for your flagship, which shapes how it fights for the whole run. Each sector’s enemies have a set strength, so a stronger fleet feels stronger; a battered fleet meets slightly smaller ones."],
	["Between battles", "Hull damage carries between battles. Shipyards sell hulls, refits and repairs, and can upgrade a ship’s Mark. Captains earn experience and pick a perk at each promotion. Relics are fleet-wide bonuses that last for the run."],
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
	var h = lbl(title, 96, BONE, font_goth); h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(h)
	var sub = ""
	if victory: sub = "Three sectors broken, three flagships burning behind you. " + str(C.ADMIRALS[R["admiral"]]["n"]) + " brings the " + str(C.FACTIONS[R["fac"]]["n"]).trim_prefix("The ") + " home."
	elif d["abandoned"]: sub = "The fleet stands down. Its deeds are recorded."
	else: sub = "The last hull goes dark in sector " + C.roman(R["sector"]) + ". The survivors will tell it differently."
	var sl = lbl(sub, 20, BONE2); sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sl)
	var carry = panel(GILT, Color(0.37, 0.7, 0.65, 0.08), 12); var cv = vbox(4); carry.add_child(cv)
	cv.add_child(lbl("CARRIED FORWARD", 12, BONE3))
	cv.add_child(rich("[b]" + c("+" + C.numstr(cy["ren"]) + " renown", GILT) + "[/b]" + ((" " + c("(Heat " + C.numstr(cy["hl"]) + ": +" + C.numstr(cy["hl"] * 10) + "%)", BONE3)) if C.jt(cy["hl"]) else "") + " · you now have " + C.numstr(C.META["renown"]) + ". Spend it on hull variants in Progression.", 16))
	var mx1 = int(cy["mx1"]); var ml = ""
	if mx1 > int(cy["mx0"]): ml = " " + c("Level " + str(mx1) + " reached: " + esc(C.MASTERY_PERKS[mx1]["n"]) + ". " + esc(C.MASTERY_PERKS[mx1]["d"]), GILT)
	elif mx1 < 4: ml = " " + c("(" + C.numstr(C.masteryXP(R["admiral"])) + "/" + C.numstr(C.MASTERY_XP[mx1 + 1]) + " to " + esc(C.MASTERY_PERKS[min(4, mx1 + 1)]["n"]) + ")", BONE3)
	else: ml = " " + c("(mastered)", BONE3)
	cv.add_child(rich(esc(C.ADMIRALS[R["admiral"]]["n"]) + ": [b]+" + C.numstr(cy["mxGain"]) + " mastery[/b]" + ml, 16))
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

# ---------------- dialogs ----------------
func _modal(md: Dictionary) -> void:
	_modal_acts = md["acts"]; var acts = _modal_acts; var d = md["data"]
	var dim = ColorRect.new(); dim.color = Color(0.024, 0.035, 0.063, 0.78); dim.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(dim)
	var cc = CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); modal_box.add_child(cc)
	var box = panel(GILT2, IRON, 24)
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v = vbox(8); v.custom_minimum_size.x = px(700); sc.add_child(v); box.add_child(sc); cc.add_child(box)
	var h2 = func(t: String): v.add_child(lbl(t, 40, BONE, font_goth))
	var p = func(t: String, col: Color = BONE): v.add_child(lbl(t, 17, col))
	var R = C.RUN
	match md["kind"]:
		"intro", "sector":
			var F = C.FACTIONS[d["fac"]]
			if md["kind"] == "intro":
				h2.call("Sector I"); v.add_child(rich("The " + C.runWord() + " crosses into contested space. Long-range auspex confirms [b]" + esc(F["n"]) + "[/b] activity along every jump route.", 17))
			else:
				h2.call("Sector " + C.roman(R["sector"]) + ((": " + str(C.REGIONS[d["region"]]["n"])) if d.get("region") != null and C.REGIONS.has(d["region"]) else ""))
				v.add_child(rich("With the flagship broken, the fleet jumps deeper. Fleet command expands: [b]" + c("+3 command points", GILT) + "[/b], and crews patch 40% of every hull during the transit.", 17))
				v.add_child(rich("Auspex confirms [b]" + esc(F["n"]) + "[/b] ahead.", 17))
			if md["kind"] == "intro": p.call(F.get("blurb", ""), BONE2)
			if d["cond"] != null: v.add_child(rich(c("Sector condition: [b]" + esc(d["cond"]["n"]) + "[/b].", GILT) + " " + c(esc(d["cond"]["d"]), BONE2), 17))
			if md["kind"] == "sector": p.call(F.get("blurb", ""), BONE2)
			if md["kind"] == "intro": p.call("Pick a route across the sector map. Battles marked with a patron’s sigil pay out that patron’s boons, so the route you choose shapes your build. The flagship of the sector waits at the far end.", BONE2)
			add(v, abtn("Plot a course", "closeModal", "", true, false, acts))
		"abandon":
			h2.call("Abandon the current run?"); p.call("Starting over ends your saved run. Your best result so far is kept either way.", BONE2)
			var r = hbox(); add(r, abtn("Abandon and start over", "abandonRun", "", true, false, acts)); add(r, abtn("Keep it", "closeModal", "", false, false, acts)); v.add_child(r)
		"sell":
			h2.call("Decommission the " + str(d["ship"]["name"]) + "?"); p.call("Its captain retires and its refits return to the hold. You receive " + C.numstr(d["value"]) + " credits.", BONE2)
			var r = hbox(); add(r, abtn("Decommission", "sellConfirm", d["ship"]["uid"], true, false, acts)); add(r, abtn("Keep it", "closeModal", "", false, false, acts)); v.add_child(r)
		"drydock":
			h2.call("Drydock"); p.call("Your crews work around the clock under a friendly station’s floodlights. Repair teams restore 60% of every ship’s missing hull.")
			if d["lines"].size() > 0:
				for l in d["lines"]: p.call("• " + l)
			else: p.call("The fleet was already in good order.", BONE2)
			var r = hbox(); add(r, abtn("Continue", "closeModal", "", true, false, acts)); add(r, abtn("Manage fleet", "fleetFromModal", "", false, false, acts)); v.add_child(r)
		"event":
			var ev = d["ev"]; h2.call(ev["t"]); p.call(ev["b"])
			for i in range(ev["o"].size()):
				var o = ev["o"][i]; var cost = o["r"].get("cost") if o["r"] is Dictionary else null; var ok = not C.jt(cost) or float(R["credits"]) >= float(cost)
				add(v, choice(o["l"], str(o["s"]) + ("" if ok else " (not enough credits)"), "eventChoice", i, acts))
		"event_result":
			h2.call(d["ev"]["t"])
			for l in d["lines"]: p.call(l)
			add(v, abtn("Continue", "closeModal", "", true, false, acts))
		"victory":
			var sm = d["summary"]; var cfg = sm["cfg"]
			h2.call("Flagship destroyed" if cfg["kind"] == "boss" else "Victory")
			v.add_child(rich(C.numstr(sm["kills"]) + " enemy ship" + ("" if int(sm["kills"]) == 1 else "s") + " destroyed in " + C.numstr(sm["rounds"]) + " round" + ("" if float(sm["rounds"]) == 1 else "s") + ". " + c("+" + C.numstr(d["credits"]) + " credits.", GILT), 17))
			if sm["lost"].size() > 0:
				var ls = []
				for l in sm["lost"]: ls.append("the " + str(l["ship"]) + " and " + str(l["cap"]))
				p.call("Lost: " + ", ".join(PackedStringArray(ls)) + ".", BLOOD)
			if d["extra"] != "": p.call(d["extra"], GILT)
			if (R.get("boons") as Array).size() > 0 and (sm.get("boonStats", {}) as Dictionary).is_empty(): p.call("No boon triggered this battle. Check the Fleet boons section on a ship to see what sets each one off.", BONE3)
			if d["flagMoved"] != null: p.call("The admiral transfers the flag to the " + str(d["flagMoved"]["name"]) + ". Its aspect goes with it.", GILT)
			for x in sm["xp"]: v.add_child(rich("• " + esc(x["cap"]) + " of the " + esc(x["ship"]) + ": +" + C.numstr(x["xp"]) + " experience" + ((" " + c("promoted to " + str(C.RANKS[int(x["rank"])]), GILT)) if x["up"] else ""), 16))
			var rw = d["rw"]
			if _find(acts, "prizeStep", "").size() > 0: add(v, abtn("Decide on the prize ship" + ("s" if R["reward"]["prizes"].size() > 1 else ""), "prizeStep", "", true, false, acts))
			elif _find(acts, "salvageStep", "").size() > 0: add(v, abtn("Salvage the field", "salvageStep", "", true, false, acts))
			elif rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")): add(v, abtn(str(C.PATRONS[rw["p"]]["short"]) + " offers a boon", "rewardNext", "", true, false, acts))
			elif rw.get("k") == "mod": add(v, abtn("Choose a refit", "rewardNext", "", true, false, acts))
			else: add(v, abtn("Continue", "rewardNext", "", true, false, acts))
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
				for opt in [["add", "Add", ("Joins at " + str(hp) + "% hull") if r["room"] else "No command points left"], ["strip", "Strip", sm2 + C.numstr(r["o"]["strip"]["cred"]) + " credits"], ["ransom", "Ransom", C.numstr(r["o"]["ransom"]) + " credits"]]:
					var b = choice(opt[1], opt[2], "prizeSet", str(i) + ":" + opt[0], acts, null, "", BONE2, r["k"] == opt[0])
					if b != null: b.custom_minimum_size.x = px(210); g.add_child(b)
				pv.add_child(g); v.add_child(pp)
			var parts = []
			if joins > 0: parts.append(str(joins) + " ship" + ("s join" if joins > 1 else " joins"))
			if refits > 0: parts.append(str(refits) + " refit" + ("s" if refits > 1 else "") + " for the hold")
			if cred > 0: parts.append("+" + C.numstr(cred) + " credits")
			p.call("You get: " + (", ".join(PackedStringArray(parts)) if parts.size() > 0 else "Nothing") + ".", BONE2)
			add(v, abtn("Confirm", "prizeConfirm", "", true, false, acts))
		"salvage":
			h2.call("Salvage the field"); p.call("Your crews have time to work one wreck before the fleet moves on.", BONE2); p.call(str(C.REWARD_DEF["salvage"]), BONE3)
			var ws = d["wrecks"]
			for i in range(ws.size()):
				var w = ws[i]; var y = w["yield"]; var F = C.FACTIONS.get(w.get("fac"))
				var pp = panel(IRON3, IRON2, 10); var pv = vbox(6); pp.add_child(pv)
				pv.add_child(rich("[b]" + esc(w["name"]) + "[/b] " + c(esc(C.or_(w.get("cls"), "")) + ((", " + esc(F["n"])) if F != null else ""), BONE3) + "\n" + c(esc(C.CAUSE_WORD.get(w.get("cause"), "destroyed")) + ((" by the " + esc(w["by"])) if C.jt(w.get("by")) else "") + ".", BONE2), 16))
				var g = GridContainer.new(); g.columns = 3; g.add_theme_constant_override("h_separation", px(6))
				if C.jt(y.get("mod")): add(g, choice("Strip it: " + C.modName(y["mod"]), C.MODULES[y["mod"]]["d"], "takeSalvage", str(i) + ":mod", acts))
				add(g, choice("Scrap it", "+" + C.numstr(y["cred"]) + " credits", "takeSalvage", str(i) + ":cred", acts))
				if C.jt(y.get("tow")): add(g, choice("Tow it home", "Joins your fleet at 35% hull", "takeSalvage", str(i) + ":tow", acts))
				pv.add_child(g); v.add_child(pp)
		"mod":
			h2.call("Salvaged refits"); p.call(str(C.REWARD_DEF["refit"]), BONE3); p.call("Take one. It goes in the hold; fit it at a shipyard or from the fleet screen.")
			for m in d["opts"]: add(v, choice(C.modName(m), C.MODULES[m]["d"], "takeMod", m, acts))
		"boon":
			var P = C.PATRONS[d["patron"]]; var pc = Color(P["col"])
			var hd = hbox(12); var sg = lbl(P["glyph"], 26, INK, font_semi, false); var sgp = panel(pc, pc, 6); sgp.add_child(sg); hd.add_child(sgp)
			var hv = vbox(0); hv.add_child(lbl(P["n"], 34, pc, font_goth)); hv.add_child(lbl(P["theme"], 15, BONE2)); hd.add_child(hv); v.add_child(hd)
			p.call("“" + str(P["quote"]) + "”", BONE2); p.call(str(C.REWARD_DEF["boon"]), BONE3)
			var offer = d["offer"]
			for i in range(offer.size()):
				var o = offer[i]; var b = C.BOONS[o["id"]]; var r = int(C.z0(o.get("r"))); var R0 = C.RARITY[r]; var duo = b.get("duo")
				var tag = ("Duo: " + " + ".join(PackedStringArray(duo.map(func(q): return str(C.PATRONS[q]["short"]))))) if C.jt(duo) else str(R0["n"])
				add(v, choice(b["n"], C.BOON_D[o["id"]][r], "takeBoon", i, acts, Color(C.PATRONS[duo[0]]["col"]) if C.jt(duo) else pc, tag, Color("#ffd27a") if C.jt(duo) else Color(R0["col"])))
		"relic":
			h2.call("The flagship’s vault" if d["boss"] else "Spoils of the elite"); p.call(str(C.REWARD_DEF["relic"]), BONE3); p.call("Choose one.")
			for r in d["opts"]: add(v, choice(C.relicName(r), C.RELICS[r]["d"], "takeRelic", r, acts))
		"promote":
			var s = d["ship"]; h2.call("Promotion")
			v.add_child(rich(esc(s["cap"]["name"]) + " of the [i]" + esc(s["name"]) + "[/i] is now " + esc(C.rankName(s["cap"])) + ". Choose one perk.", 17)); p.call(str(C.REWARD_DEF["promotion"]), BONE3)
			for pk in s["cap"]["offer"]: add(v, choice(C.PERKS[pk]["n"], C.PERKS[pk]["d"], "takePerk", s["uid"] + ":" + pk, acts))
		"retreat":
			h2.call("Retreat?"); p.call("The fleet jumps out. Every surviving ship loses 10% of its hull, and this node counts as passed.")
			var r = hbox(); add(r, abtn("Jump out", "c3retreatYes", "", true, false, acts)); add(r, abtn("Stay and fight", "c3retreatNo", "", false, false, acts)); v.add_child(r)
		_:
			for a in acts: add(v, abtn(a[0] + " " + a[1], a[0], a[1], false, false, acts))
	# size the box to its content, up to 90% of the window height
	var vh = get_viewport().get_visible_rect().size.y
	sc.custom_minimum_size = Vector2(px(700), min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))
	v.minimum_size_changed.connect(func(): sc.custom_minimum_size.y = min(vh * 0.9 - px(48), v.get_combined_minimum_size().y + px(8)))

func _unhandled_input(e: InputEvent) -> void:
	if C == null or not root.visible or not (e is InputEventKey) or not e.pressed or e.echo: return
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
