extends RefCounted
# The game's UI theme (issue #271). Layout: Glass Shell C bold (Ryan, Nov 9 2026, FINDINGS R145: "C bold, let's try").
# Identity: Lime Tactical (Ryan, Nov 9 2026 12:00 CST, FINDINGS R149: "yeah i like lime tactical, run it"): a combat
# targeting computer. Chakra Petch (angular) for words, Azeret Mono for numbers, black-olive panels, pale sage text, neon
# lime as the one accent for the next action, chamfered corners, lime brackets, slanted strips, a fine scanline on panels.
# The battle HUD is the first user; the title, the campaign map, the end screen and the menus follow it from
# contrib/opus/briefs/ui_style.md, which states these rules in plain words.
#
#   - Panels are matte, near-solid slabs (80%): the scene only hints through. Text never sits on the panel itself.
#   - Text always sits on a solid backing: a well inside a panel, or a strip on the board (nameplates, chips, tags).
#   - Lime means "do this next" (the filled End ship slab, the UP tag, the lit step, the armed weapon) and marks the
#     panel furniture (section heads, brackets, the bevel). Only one filled lime button at a time (R148).
#   - ALERT red is reserved for danger (the Nemesis). Faction colour is a small accent only (a crest, a 3 px bar); the
#     friend and foe channel in battle is FRIEND mint and the FOE lavender family (ui_spec.md 5.1 and 5.4).
#   - Sizes are written at the 1080 design height and scaled by ui_scale.gd k (ui_spec.md 4.1). No text under 12.
#
# Every function takes k (the UI scale) so a screen can build its pieces at its own size. Nothing here reads the rules.

const UiScale := preload("res://ui/ui_scale.gd")

# ---------------------------------------------------------------- palette: Lime Tactical (FINDINGS R149)
# The names are the old ones (ui_spec.md 5.1) so every screen keeps its meaning: GILT is still "the accent", now neon lime;
# BONE is the text family, now pale sage; INK and IRON are the backgrounds, now black-olive. The values are the mockup's
# (docs/shots/ui_redesign/identity/2_lime_tactical.png, contrib/opus/ui271_mockups/identity/identity.css body.id2).
const INK := Color("#090c09")
const IRON := Color("#111611")
const IRON2 := Color("#182019")
const IRON3 := Color("#283228")
const BONE := Color("#e8eee0")         # pale sage: body text
const BONE2 := Color("#a7b09d")        # secondary text
const BONE3 := Color("#7c8674")        # dim text (units, maxima, "done"): 4.5:1 or better on a well
const GILT := Color("#c8f53a")         # THE accent, neon lime: the next action (End ship, the lit step, UP, the armed weapon)
const GILT2 := Color("#6f8a1c")        # dim lime: tooltip edges, a disabled finish button
const GILT_HOVER := Color("#d9ff5c")
const ON_GILT := Color("#0d1200")      # text on lime
const VERD := Color("#59d6a8")
const BLOOD := Color("#ff8a72")
const ALERT := Color("#ff4433")        # reserved red: the Nemesis and danger, nothing else
const EMBER := Color("#ffb23e")
const SHIELD := Color("#4fc4ff")
const HULL := Color("#ffad3b")
const HULL_LOW := Color("#ff5530")
const BAR_TRACK := Color("#2b2a20")
# the friend and foe channel (ui_spec.md 5.4). FRIEND moved from the mockup's spring green #5ff0a0 to mint (R149): next to
# the lime they both read "green" at a glance, and under deuteranopia the gap shrinks further; mint keeps them apart
# (CIE76 distance to lime 71 vs 55, deuteranopia 69 vs 51) and still clear of SHIELD blue (61).
const FRIEND := Color("#52f0c4")       # your ships: names, nameplate bars, Ready, the ring under your hulls
const FOE := Color("#c4a4ff")          # FOE family: enemy names
const FOE_RING := Color("#a06bff")     # FOE family: rings, chip borders, danger badges
const FOE_TEXT := Color("#e2d2ff")     # FOE family: text on the enemy chip
const KEY_FG := Color("#d9f78a")       # key cap text (light lime, in the number face)
# the campaign pages (issue #344, UI rollout 1). The map's danger band colours, stop glyph colours and route planner colours
# left with the Briefing build (FINDINGS R165): danger is four pips and a word, a stop is its 3D model, a route is lime or pale.
const BLUE := Color("#62a8ff")         # B4 blue event options (an option your fleet qualifies for)
const SHADE := Color(0.035, 0.047, 0.035, 0.80)  # the dim layer behind a dialog: INK-toned, the scene only hints through
# the campaign map's Briefing layout (FINDINGS R165, contrib/opus/briefs/campaign_map_briefing.md): one flat column and plain
# words on the chart. Two colours on top of the sage text: lime for the next action and the next jumps, ALERT for the Nemesis.
const COLUMN := Color("#0b0e0b")       # the flat briefing column and the map's one box (the hover tip)
const HAIR := Color("#1c241c")         # the column's quiet edge and the rules inside it
const ROW_LIT := Color("#161c16")      # the picked route row: a slightly lighter fill
const ROW_HOVER := Color("#111611")    # a route row under the pointer
const HALO := Color("#070907")         # the dark halo under plain words on the map
const PALE := 0.25                     # a route you cannot take yet: one thin sage line at this share of full strength, as the eye reads it
const PALE_CUT := 0.10                 # a route that is cut off or already flown
const GRID := 8.0                      # the spacing grid of the Briefing layout, at 1080
# the material
const WELL := Color("#080a08")         # the solid backing under every block of text (alpha WELL_A)
const WELL_A := 0.93
const STRIP_A := 0.88                  # a text strip on the board (nameplates, chips): WELL at this alpha
const SHELL := Color(0.039, 0.051, 0.039, 0.80)   # the matte panel: near-solid black-olive, the scene only hints through
const SHELL_EDGE := Color(0.784, 0.961, 0.227, 0.20)  # lime at 20%: the panel edge
const WELL_EDGE := Color(0.784, 0.961, 0.227, 0.35)   # lime at 35%: a well's 2 px left bar
const LINE := Color(0.784, 0.961, 0.227, 0.12)        # lime at 12%: row separators and quiet edges
const SCAN := Color(0.784, 0.961, 0.227, 0.025)       # the fine scanline on panels (one line every 4 px)
const SHIELD_TRACK := Color("#1b2a2e") # the empty part of a shield bar
const CUT := 14.0                      # the panel chamfer (top left and bottom right), at 1080
const BTN_CUT := 10.0                  # the finish button's chamfer
const BRACKET := 18.0                  # the lime corner brackets (top right and bottom left), 2 px lines

# ---------------------------------------------------------------- type (OFL, godot/ui/theme/fonts)
# Chakra Petch (angular) for every word, Azeret Mono for numbers that decide something (odds, damage, hull, keys).
const FONT_DIR := "res://ui/theme/fonts/"
static var _fonts := {}


static func px(v: float, k: float) -> int:
	return UiScale.px(v, k)


# ---------------------------------------------------------------- fonts

# the imported font when the project has been imported or exported, else the raw file (a copy without .godot/)
static func _font_file(name: String) -> Font:
	var p := FONT_DIR + name
	if _fonts.has(p):
		return _fonts[p]
	var f: Font = null
	if _imported_ok(p):
		var r = load(p)
		if r is Font:
			f = r
	if f == null:
		var ff := FontFile.new()
		if FileAccess.file_exists(p):
			ff.data = FileAccess.get_file_as_bytes(p)
		f = ff
	_fonts[p] = f
	return f


static func _imported_ok(p: String) -> bool:
	var ip := p + ".import"
	if not FileAccess.file_exists(ip):
		return false
	for line in FileAccess.get_file_as_string(ip).split("\n"):
		if line.begins_with("path=") or line.begins_with("path."):
			var q := line.substr(line.find("\"") + 1)
			q = q.substr(0, q.find("\""))
			return q != "" and FileAccess.file_exists(q)
	return false


# a face with letter spacing (em x size x k, in whole pixels) and, for the variable number face, a weight
static func _variant(key: String, base: Font, spacing_px: int, wght := 0) -> Font:
	if _fonts.has(key):
		return _fonts[key]
	var v := FontVariation.new()
	v.base_font = base
	v.spacing_glyph = spacing_px
	if wght > 0:
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): wght}
	_fonts[key] = v
	return v


# body text: Chakra Petch Regular
static func body() -> Font:
	return _font_file("ChakraPetch-Regular.ttf")


static func medium() -> Font:
	return _font_file("ChakraPetch-Medium.ttf")


# names, buttons, numbers in prose: Chakra Petch SemiBold
static func semi() -> Font:
	return _font_file("ChakraPetch-SemiBold.ttf")


static func bold() -> Font:
	return _font_file("ChakraPetch-Bold.ttf")


# section heads and tags ("1 MOVE", "FLEET", "UP", "NEMESIS"): Chakra Petch Bold in caps, tracked 0.18 em at 13
static func caps(k: float) -> Font:
	var sp := maxi(1, int(round(13.0 * 0.18 * k)))
	return _variant("caps%d" % sp, bold(), sp)


# display (the round title, the banner, the end card, menu titles): Chakra Petch Bold in caps, tracked 0.14 em at 19
static func display(k: float) -> Font:
	var sp := maxi(1, int(round(19.0 * 0.14 * k)))
	return _variant("disp%d" % sp, bold(), sp)


# the finish button's label ("END SHIP"): Chakra Petch Bold in caps, tracked 0.12 em at 17
static func action_font(k: float) -> Font:
	var sp := maxi(1, int(round(17.0 * 0.12 * k)))
	return _variant("act%d" % sp, bold(), sp)


# the name of the ship that is up (star, "LONG WATCH"): Chakra Petch Bold in caps, tracked 0.06 em at 20
static func ship_name(k: float) -> Font:
	var sp := maxi(1, int(round(20.0 * 0.06 * k)))
	return _variant("name%d" % sp, bold(), sp)


# numbers that decide something (odds, damage, hull, Heat, key caps): Azeret Mono, medium and bold
static func num() -> Font:
	return _variant("num", _font_file("AzeretMono-VF.ttf"), 0, 500)


static func num_bold() -> Font:
	return _variant("numb", _font_file("AzeretMono-VF.ttf"), 0, 700)


# ---------------------------------------------------------------- frames and backings

# the panel: a matte, near-solid black-olive slab with a lime edge at 20% and two chamfered corners (top left, bottom
# right). frame_marks() draws the scanline, the lime bevel on the top-left chamfer and the corner brackets.
static func shell(k: float, pad := 8.0) -> StyleBoxFlat:
	var g := StyleBoxFlat.new()
	g.bg_color = SHELL
	g.border_color = SHELL_EDGE
	g.set_border_width_all(1)
	g.set_corner_radius_all(0)
	g.corner_detail = 1
	g.corner_radius_top_left = px(CUT, k)
	g.corner_radius_bottom_right = px(CUT, k)
	g.content_margin_left = px(pad, k)
	g.content_margin_right = px(pad, k)
	g.content_margin_top = px(pad, k)
	g.content_margin_bottom = px(pad, k)
	return g


# a solid well: every line of text inside a frame sits on one. Square, with a 2 px lime bar on the left (an ALERT bar
# for the Nemesis block: pass bar). A lit well (the step you are on, the armed weapon, the ship that is up) gets a lime
# edge all round and a soft lime glow; nothing else lights a well.
static func well(k: float, accent := Color(0, 0, 0, 0), pad_x := 12.0, pad_y := 8.0, bar := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var w := StyleBoxFlat.new()
	w.bg_color = Color(WELL, WELL_A)
	w.border_color = bar if bar.a > 0.0 else WELL_EDGE
	w.set_border_width_all(0)
	w.border_width_left = maxi(2, px(3 if bar.a > 0.0 else 2, k))
	w.set_corner_radius_all(0)
	if accent.a > 0.0:
		w.border_color = accent
		w.set_border_width_all(1)
		w.border_width_left = maxi(2, px(2, k))
		w.shadow_color = Color(accent, 0.16)
		w.shadow_size = px(6, k)
	w.content_margin_left = px(pad_x, k)
	w.content_margin_right = px(pad_x, k)
	w.content_margin_top = px(pad_y, k)
	w.content_margin_bottom = px(pad_y, k)
	return w


# a text strip on the board (nameplates, the unacted chips, toasts): solid black-olive, a 3 px accent bar on the left
# and a slanted right end (an 8 px cut on the bottom-right corner)
static func strip(k: float, accent: Color, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(WELL, STRIP_A)
	s.border_color = accent
	s.border_width_left = maxi(2, px(3, k))
	s.border_width_top = 0
	s.border_width_right = 0
	s.border_width_bottom = 0
	if border.a > 0.0:
		s.border_color = border
		s.set_border_width_all(1)
		s.border_width_left = maxi(2, px(3, k))
	s.set_corner_radius_all(0)
	s.corner_detail = 1
	s.corner_radius_bottom_right = px(8, k)
	s.content_margin_left = px(7, k)
	s.content_margin_right = px(9, k)
	s.content_margin_top = px(2, k)
	s.content_margin_bottom = px(3, k)
	return s


# a small solid tag ("UP", "NEMESIS", "ENEMY", "LOW"): filled or outlined, square
static func tag(k: float, col: Color, filled := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col if filled else Color(WELL, WELL_A)
	s.border_color = col
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = px(6, k)
	s.content_margin_right = px(6, k)
	s.content_margin_top = px(0, k)
	s.content_margin_bottom = px(1, k)
	return s


# a key cap ("B", "Tab", "Space") beside an action: the key always shows next to what it does. A lime-tinted square with
# a lime edge; the text is KEY_FG in the number face.
static func keycap(k: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("#141a0c")
	s.border_color = Color(GILT, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(0)
	s.content_margin_left = px(5, k)
	s.content_margin_right = px(5, k)
	s.content_margin_top = px(0, k)
	s.content_margin_bottom = px(1, k)
	return s


# buttons: a plain one is a dark square with a lime edge at 28% (55% on hover); the primary is solid lime with dark text
static func button_boxes(k: float, primary := false) -> Dictionary:
	var n := StyleBoxFlat.new()
	n.bg_color = GILT if primary else Color("#10140b", 0.97)
	n.border_color = GILT if primary else Color(GILT, 0.28)
	n.set_border_width_all(1)
	n.set_corner_radius_all(0)
	if primary:
		n.corner_detail = 1
		n.corner_radius_top_left = px(BTN_CUT * 0.6, k)
		n.corner_radius_bottom_right = px(BTN_CUT * 0.6, k)
	n.content_margin_left = px(10, k)
	n.content_margin_right = px(10, k)
	n.content_margin_top = px(5, k)
	n.content_margin_bottom = px(5, k)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = GILT_HOVER if primary else Color("#1b210d", 0.97)
	h.border_color = GILT_HOVER if primary else Color(GILT, 0.55)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(GILT2, 0.35) if primary else Color("#060806", 0.9)
	d.border_color = LINE
	return {"normal": n, "hover": h, "pressed": h, "disabled": d}


# the screen's one finishing action (End ship; Continue, Confirm or Launch elsewhere): the big filled lime slab of the
# Lime Tactical mockup. Flat lime, chamfered top left and bottom right, a soft lime glow, dark caps label. One per screen.
static func finish_boxes(k: float) -> Dictionary:
	var n := StyleBoxFlat.new()
	n.bg_color = GILT
	n.border_color = GILT
	n.set_border_width_all(1)
	n.set_corner_radius_all(0)
	n.corner_detail = 1
	n.corner_radius_top_left = px(BTN_CUT, k)
	n.corner_radius_bottom_right = px(BTN_CUT, k)
	n.shadow_color = Color(GILT, 0.35)
	n.shadow_size = px(14, k)
	n.anti_aliasing = true
	for side in [SIDE_LEFT, SIDE_RIGHT]:
		n.set_content_margin(side, px(12, k))
	for side in [SIDE_TOP, SIDE_BOTTOM]:
		n.set_content_margin(side, px(6, k))
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = GILT_HOVER
	h.border_color = GILT_HOVER
	h.shadow_color = Color(GILT, 0.55)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color("#1a2109")
	d.border_color = Color(GILT2, 0.8)
	d.shadow_size = 0
	return {"normal": n, "hover": h, "pressed": h, "disabled": d}


# a lit button: the step's own confirm (Move here, Fire N weapons) when the finishing action is already the filled lime
# one. A dark lime-tinted fill, a lime edge, lime text and a soft glow, so the screen never shows two filled buttons (R148).
static func lit_boxes(k: float) -> Dictionary:
	var bb := button_boxes(k)
	var n := (bb["normal"] as StyleBoxFlat).duplicate() as StyleBoxFlat
	n.bg_color = Color("#171d0c", 0.97)
	n.border_color = GILT
	n.shadow_color = Color(GILT, 0.20)
	n.shadow_size = px(6, k)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color("#232d10", 0.97)
	h.border_color = GILT_HOVER
	return {"normal": n, "hover": h, "pressed": h, "disabled": bb["disabled"]}


# the finish button's highlight: a thin light line along its top edge (the slab is flat lime, as in the mockup). Off while
# the button is disabled. The name is kept from the Glass Shell build so callers stay the same.
static func gilt_sheen(b: Button, k: float) -> void:
	b.draw.connect(func() -> void:
		if b.disabled:
			return
		var c := float(px(BTN_CUT, k))
		var y := 1.5
		if b.size.x <= c * 2.0:
			return
		b.draw_line(Vector2(c, y), Vector2(b.size.x - 1.0, y), Color(1, 1, 1, 0.35), maxf(1.0, float(px(1, k)))))
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)


# a key cap sitting on the lime button: dark text on a light wash with a dark edge
static func keycap_on_gilt(k: float) -> StyleBoxFlat:
	var s := keycap(k)
	s.bg_color = Color(1, 1, 1, 0.22)
	s.border_color = Color(ON_GILT, 0.55)
	return s


# the focus ring every screen uses (ui_spec.md 6): no fill, a BONE (pale sage) border at least 2 px, 3 px outside the
# button, square like everything else in Lime Tactical
static func focus_ring(k: float) -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = BONE
	f.set_border_width_all(maxi(2, px(2, k)))
	f.set_corner_radius_all(0)
	f.expand_margin_left = px(3, k)
	f.expand_margin_right = px(3, k)
	f.expand_margin_top = px(3, k)
	f.expand_margin_bottom = px(3, k)
	return f


# the shared theme for any screen: body font and base size, buttons, labels, rich text ([code] uses the number face),
# tooltips and the focus ring (focus_ring). Every screen takes its focus ring from here, the battle HUD included.
static func make_theme(k: float, body_f: Font, body_semi: Font, base := 15) -> Theme:
	var th := Theme.new()
	th.default_font = body_f
	th.default_font_size = px(base, k)
	var bb := button_boxes(k)
	for st in ["normal", "hover", "pressed", "disabled"]:
		th.set_stylebox(st, "Button", bb[st])
	th.set_stylebox("focus", "Button", focus_ring(k))
	th.set_color("font_color", "Button", BONE)
	th.set_color("font_hover_color", "Button", BONE)
	th.set_color("font_pressed_color", "Button", BONE)
	th.set_color("font_disabled_color", "Button", BONE3)
	th.set_font("font", "Button", body_semi)
	th.set_font_size("font_size", "Button", px(14, k))
	th.set_color("font_color", "Label", BONE)
	th.set_color("default_color", "RichTextLabel", BONE)
	th.set_font("normal_font", "RichTextLabel", body_f)
	th.set_font("bold_font", "RichTextLabel", body_semi)
	th.set_font("mono_font", "RichTextLabel", num())
	th.set_font_size("normal_font_size", "RichTextLabel", px(14, k))
	th.set_font_size("bold_font_size", "RichTextLabel", px(14, k))
	th.set_font_size("mono_font_size", "RichTextLabel", px(14, k))
	# tooltips: a solid well with sage text (keyword definitions, one layer deep), a dim lime edge
	var tp := well(k, Color(0, 0, 0, 0), 10, 7)
	tp.border_color = GILT2
	tp.set_border_width_all(1)
	th.set_stylebox("panel", "TooltipPanel", tp)
	th.set_color("font_color", "TooltipLabel", BONE)
	th.set_font("font", "TooltipLabel", body_f)
	th.set_font_size("font_size", "TooltipLabel", px(14, k))
	# scroll bars: thin, olive, out of the way
	var sg := StyleBoxFlat.new()
	sg.bg_color = Color(IRON3, 0.9)
	sg.set_corner_radius_all(0)
	sg.content_margin_left = px(2, k)
	sg.content_margin_right = px(2, k)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0, 0, 0, 0.0)
	sbg.content_margin_left = px(2, k)
	sbg.content_margin_right = px(2, k)
	th.set_stylebox("grabber", "VScrollBar", sg)
	th.set_stylebox("grabber_highlight", "VScrollBar", sg)
	th.set_stylebox("grabber_pressed", "VScrollBar", sg)
	th.set_stylebox("scroll", "VScrollBar", sbg)
	return th


# the panel's marks, drawn by the panel itself over its fill and under its children:
#   - the fine scanline (SCAN, one 1 px line every 4 px, kept inside the two chamfers),
#   - a 2 px lime bevel along the top-left chamfer (bevel; off on the flat top bar),
#   - lime corner brackets, 18 px arms of 2 px, at the top right and bottom left (brackets).
static func frame_marks(p: Control, k: float, brackets := true, bevel := true, col := GILT) -> void:
	var cut := float(px(CUT, k))
	var arm := float(px(BRACKET, k))
	var w := maxf(2.0, float(px(2, k)))
	var step := maxf(3.0, float(px(4, k)))
	p.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, p.size)
		if r.size.x < cut * 2.0 or r.size.y < cut * 2.0:
			return
		var pts := PackedVector2Array()
		var y := step * 0.5
		while y < r.size.y - 1.0:
			var x0 := maxf(1.0, cut - y)
			var x1 := r.size.x - 1.0 - maxf(0.0, y - (r.size.y - cut))
			if x1 > x0:
				pts.append(Vector2(x0, y))
				pts.append(Vector2(x1, y))
			y += step
		if pts.size() >= 2:
			p.draw_multiline(pts, SCAN, maxf(1.0, float(px(1, k))))
		if bevel:
			p.draw_line(Vector2(0, cut), Vector2(cut, 0), col, w, true)
		if brackets:
			var tr := Vector2(r.end.x - w * 0.5, w * 0.5)
			p.draw_line(tr + Vector2(-arm, 0), tr, col, w)
			p.draw_line(tr, tr + Vector2(0, arm), col, w)
			var bl := Vector2(w * 0.5, r.end.y - w * 0.5)
			p.draw_line(bl + Vector2(0, -arm), bl, col, w)
			p.draw_line(bl, bl + Vector2(arm, 0), col, w))


# the old name (Glass Shell's corner ticks): the full panel marks
static func ticks_on(p: Control, k: float, col := GILT) -> void:
	frame_marks(p, k, true, true, col)


# a segmented bar (hull, the heat gauge): n cells, the first `fill` of them lit; ghost cells (expected loss) hatched
static func seg_bar(k: float, f: float, col: Color, track: Color, h := 5.0, cells := 10, ghost_from := -1.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px(h, k))
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gap := maxf(1.0, float(px(2, k)))
	c.draw.connect(func() -> void:
		var w := c.size.x
		var cw := (w - gap * float(cells - 1)) / float(cells)
		if cw <= 1.0:
			return
		var fill := clampf(f, 0.0, 1.0) * w
		var gfrom := clampf(ghost_from, 0.0, 1.0) * w if ghost_from >= 0.0 else fill
		for i in cells:
			var x0 := float(i) * (cw + gap)
			var x1 := x0 + cw
			c.draw_rect(Rect2(x0, 0, cw, c.size.y), track)
			if fill > x0:
				var xe := minf(x1, fill)
				c.draw_rect(Rect2(x0, 0, xe - x0, c.size.y), col)
				# the expected loss: hatched over the part the volley should take (labelled "expected" where it shows)
				if gfrom < xe:
					var hs := maxf(x0, gfrom)
					c.draw_rect(Rect2(hs, 0, xe - hs, c.size.y), Color(WELL, 0.75))
					var step := maxf(3.0, float(px(4, k)))
					var x := hs - c.size.y
					while x < xe:
						var a0 := Vector2(maxf(x, hs), c.size.y - (maxf(x, hs) - x))
						var a1 := Vector2(minf(x + c.size.y, xe), c.size.y - (minf(x + c.size.y, xe) - x))
						c.draw_line(a0, a1, Color(col, 0.95), maxf(1.0, float(px(1, k))))
						x += step)
	c.resized.connect(func() -> void: c.queue_redraw())
	return c

# ---------------------------------------------------------------- the Briefing layout (campaign map, FINDINGS R165)

# the flat column: a solid fill and a 1 px quiet edge on its right. No chamfers, brackets, scanline or wells.
static func column(k: float, edge_right := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = COLUMN
	s.border_color = HAIR
	s.set_border_width_all(0)
	if edge_right:
		s.border_width_right = maxi(1, px(1, k))
	else:
		s.border_width_left = maxi(1, px(1, k))
	s.set_corner_radius_all(0)
	return s


# a flat fill with no edge (a route row, a hull bar track)
static func flat(col: Color, pad_x := 0.0, pad_y := 0.0, k := 1.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col
	s.set_border_width_all(0)
	s.set_corner_radius_all(0)
	s.content_margin_left = px(pad_x, k)
	s.content_margin_right = px(pad_x, k)
	s.content_margin_top = px(pad_y, k)
	s.content_margin_bottom = px(pad_y, k)
	return s


# a 1 px rule in the quiet edge colour
static func rule(k: float) -> ColorRect:
	var r := ColorRect.new()
	r.color = HAIR
	r.custom_minimum_size = Vector2(0, maxi(1, px(1, k)))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# a route row: transparent, a slightly lighter fill when it is the picked one, a hint under the pointer
static func row_boxes(k: float, picked: bool, pad_x := 40.0, pad_y := 14.0) -> Dictionary:
	var n := flat(ROW_LIT if picked else Color(0, 0, 0, 0), pad_x, pad_y, k)
	var h := flat(ROW_LIT if picked else ROW_HOVER, pad_x, pad_y, k)
	return {"normal": n, "hover": h, "pressed": h, "disabled": n}


# a plain text button ("Map key", "Dossier", "Fleet and refits"): words only, secondary sage, primary sage under the pointer.
# It keeps the shared focus ring from make_theme.
static func plain_button(b: Button, k: float, size := 15.0, f: Font = null) -> void:
	var e := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, e)
	b.add_theme_color_override("font_color", BONE2)
	b.add_theme_color_override("font_hover_color", BONE)
	b.add_theme_color_override("font_pressed_color", BONE)
	b.add_theme_color_override("font_focus_color", BONE)
	b.add_theme_color_override("font_disabled_color", BONE3)
	b.add_theme_font_size_override("font_size", px(size, k))
	b.add_theme_font_override("font", f if f != null else body())
	b.focus_mode = Control.FOCUS_ALL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# the one filled lime button of the Briefing layout ("JUMP TO RELAY"): flat lime, square, no glow
static func jump_boxes(k: float) -> Dictionary:
	var n := flat(GILT, 20.0, 0.0, k)
	var h := flat(GILT_HOVER, 20.0, 0.0, k)
	var d := flat(Color("#1a2109"), 20.0, 0.0, k)
	return {"normal": n, "hover": h, "pressed": h, "disabled": d}


# the key cap on the lime button: dark text on a light dark wash, no edge
static func keycap_flat(k: float) -> StyleBoxFlat:
	var s := flat(Color(ON_GILT, 0.16), 7.0, 2.0, k)
	return s


# the map's hover tip, the only box on the map: the column's fill and a quiet edge
static func tip(k: float) -> StyleBoxFlat:
	var s := flat(COLUMN, 12.0, 8.0, k)
	s.border_color = IRON3
	s.set_border_width_all(maxi(1, px(1, k)))
	return s


# pips: n of total lit (a half shows as a half), for the danger of a fight (four, sage) and the hunt clock (four, ALERT)
static func pips(k: float, n: float, on := BONE, w := 5.0, h := 12.0, gap := 3.0, total := 4, off := IRON3) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px(w, k) * total + px(gap, k) * (total - 1), px(h, k))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void: draw_pips(c, Vector2.ZERO, k, n, on, w, h, gap, total, off))
	return c


static func draw_pips(ci: CanvasItem, at: Vector2, k: float, n: float, on := BONE, w := 5.0, h := 12.0, gap := 3.0, total := 4, off := IRON3) -> void:
	var pw := float(px(w, k))
	var ph := float(px(h, k))
	var pg := float(px(gap, k))
	for i in total:
		var r := Rect2(at.x + float(i) * (pw + pg), at.y, pw, ph)
		ci.draw_rect(r, off)
		var f := clampf(n - float(i), 0.0, 1.0)
		if f > 0.0:
			ci.draw_rect(Rect2(r.position, Vector2(pw * f, ph)), on)


# plain words on the map with a dark halo, no strip or tag behind them (the campaign map exception, ui_style.md 3).
# at is the left end of the baseline.
static func halo_text(ci: CanvasItem, f: Font, at: Vector2, t: String, size: int, col: Color, k: float) -> void:
	ci.draw_string_outline(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(6, px(10, k)), Color(HALO, 0.5))
	ci.draw_string_outline(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(3, px(5, k)), Color(HALO, 0.92))
	ci.draw_string(f, at, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


# the square number marker of a next jump on the map (the same 1, 2, 3 as the route rows): filled lime with dark text
# for the picked one, outlined for the others
static func marker(ci: CanvasItem, center: Vector2, k: float, label: String, f: Font, picked: bool, side := 34.0) -> void:
	var s := float(px(side, k))
	var r := Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s))
	ci.draw_rect(r, GILT if picked else INK)
	ci.draw_rect(r.grow(-float(px(1, k))), GILT, false, float(maxi(2, px(2, k))))
	var fs := px(17, k)
	var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := center.y + (f.get_ascent(fs) - f.get_descent(fs)) * 0.5
	ci.draw_string(f, Vector2(center.x - w * 0.5, base), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ON_GILT if picked else GILT)


# a small filled diamond: the Nemesis mark (ALERT) over a stop, beside a route row
static func diamond(ci: CanvasItem, center: Vector2, r: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), col)


# a thin hull bar for the briefing column: one line, the lit part in col
static func thin_bar(k: float, f: float, col: Color, w := 72.0, h := 3.0, track := IRON3) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px(w, k), px(h, k))
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		c.draw_rect(Rect2(Vector2.ZERO, c.size), track)
		c.draw_rect(Rect2(Vector2.ZERO, Vector2(c.size.x * clampf(f, 0.0, 1.0), c.size.y)), col))
	return c
