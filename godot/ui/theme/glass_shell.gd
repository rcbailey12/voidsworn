extends RefCounted
# Glass Shell (issue #271, Ryan's pick Nov 9 2026, FINDINGS R145: "C bold, let's try"): the one look every screen of the
# game follows. The battle HUD is the first user; the title, the campaign map, the end screen and the menus follow it
# from contrib/opus/briefs/ui_style.md, which states these rules in plain words.
#
#   - Frames are glass: a see-through shell, a thin etched edge and gilt corner ticks. The scene shows through the
#     frame, never through text.
#   - Text always sits on a solid backing: a well inside a frame, or a strip on the board (nameplates, chips, tags).
#   - Faction colour is a small accent only (a crest, a 3 px bar); the friend and foe channel in battle stays
#     FRIEND green and the FOE lavender family (ui_spec.md 5.1 and 5.4).
#   - Sizes are written at the 1080 design height and scaled by ui_scale.gd k (ui_spec.md 4.1). No text under 12.
#
# Every function takes k (the UI scale) so a screen can build its pieces at its own size. Nothing here reads the rules.

const UiScale := preload("res://ui/ui_scale.gd")

# ---------------------------------------------------------------- palette (ui_spec.md 5.1; the shell entries are new)
const INK := Color("#0f1626")
const IRON := Color("#182133")
const IRON2 := Color("#222d44")
const IRON3 := Color("#2d3a56")
const BONE := Color("#e6dcc4")
const BONE2 := Color("#b3aa95")
const BONE3 := Color("#7d7768")
const GILT := Color("#d0a64b")
const GILT2 := Color("#8c6d2c")
const GILT_HOVER := Color("#e2bb62")
const ON_GILT := Color("#1c1405")
const VERD := Color("#5fb3a6")
const BLOOD := Color("#e27f74")
const ALERT := Color("#ff6b5a")
const EMBER := Color("#f0b35a")
const SHIELD := Color("#62ccff")
const HULL := Color("#ffae42")
const HULL_LOW := Color("#ff5a3c")
const BAR_TRACK := Color("#3a1d1d")
const FRIEND := Color("#8ff0a0")
const FOE := Color("#c9a2ff")          # FOE family: enemy names
const FOE_RING := Color("#a64dff")     # FOE family: rings, chip borders, danger badges
const FOE_TEXT := Color("#e2d2ff")     # FOE family: text on the enemy chip
# Glass Shell entries (added to ui_spec.md 5.1 with this PR)
const WELL := Color("#0b111c")         # the solid backing under every block of text (alpha WELL_A)
const WELL_A := 0.94
const STRIP_A := 0.86                  # a text strip on the board (nameplates, chips): WELL at this alpha
const SHELL := Color(0.035, 0.055, 0.095, 0.38)   # the glass frame: the scene shows through it
const SHELL_EDGE := Color(0.816, 0.651, 0.294, 0.30)  # GILT at 30%: the etched frame edge
const WELL_EDGE := Color(0.176, 0.227, 0.337, 0.9)    # IRON3 at 90%: a well's border
const SHIELD_TRACK := Color("#16304a") # the empty part of a shield bar


static func px(v: float, k: float) -> int:
	return UiScale.px(v, k)


# ---------------------------------------------------------------- frames and backings

# the glass shell: a see-through frame with an etched edge (corner ticks are drawn by ticks_on())
static func shell(k: float, pad := 8.0) -> StyleBoxFlat:
	var g := StyleBoxFlat.new()
	g.bg_color = SHELL
	g.border_color = SHELL_EDGE
	g.set_border_width_all(1)
	g.set_corner_radius_all(0)
	g.shadow_color = Color(0, 0, 0, 0.35)
	g.shadow_size = px(10, k)
	g.content_margin_left = px(pad, k)
	g.content_margin_right = px(pad, k)
	g.content_margin_top = px(pad, k)
	g.content_margin_bottom = px(pad, k)
	return g


# a solid well: every line of text inside a frame sits on one
static func well(k: float, accent := Color(0, 0, 0, 0), pad_x := 12.0, pad_y := 8.0) -> StyleBoxFlat:
	var w := StyleBoxFlat.new()
	w.bg_color = Color(WELL, WELL_A)
	w.border_color = WELL_EDGE
	w.set_border_width_all(1)
	w.set_corner_radius_all(px(2, k))
	if accent.a > 0.0:
		# a lit well (the step you are on, the armed weapon, the ship that is up): gilt edge and a soft glow
		w.border_color = accent
		w.shadow_color = Color(accent, 0.18)
		w.shadow_size = px(6, k)
	w.content_margin_left = px(pad_x, k)
	w.content_margin_right = px(pad_x, k)
	w.content_margin_top = px(pad_y, k)
	w.content_margin_bottom = px(pad_y, k)
	return w


# a text strip on the board (nameplates, the unacted chips, tags): solid, a 3 px accent bar on the left
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
	s.set_corner_radius_all(px(1, k))
	s.content_margin_left = px(7, k)
	s.content_margin_right = px(6, k)
	s.content_margin_top = px(2, k)
	s.content_margin_bottom = px(3, k)
	return s


# a small solid tag ("UP", "NEMESIS", "ENEMY", "LOW"): filled or outlined
static func tag(k: float, col: Color, filled := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = col if filled else Color(WELL, WELL_A)
	s.border_color = col
	s.set_border_width_all(1)
	s.set_corner_radius_all(px(1, k))
	s.content_margin_left = px(6, k)
	s.content_margin_right = px(6, k)
	s.content_margin_top = px(0, k)
	s.content_margin_bottom = px(1, k)
	return s


# a key cap ("B", "Tab", "Space") beside an action: the key always shows next to what it does
static func keycap(k: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = IRON2
	s.border_color = Color(BONE3, 0.8)
	s.set_border_width_all(1)
	s.set_corner_radius_all(px(2, k))
	s.content_margin_left = px(5, k)
	s.content_margin_right = px(5, k)
	s.content_margin_top = px(0, k)
	s.content_margin_bottom = px(1, k)
	return s


# buttons: a plain one sits on a well colour with an iron edge; the primary is solid gilt with dark text
static func button_boxes(k: float, primary := false) -> Dictionary:
	var n := StyleBoxFlat.new()
	n.bg_color = GILT if primary else Color(IRON, 0.96)
	n.border_color = GILT if primary else IRON3
	n.set_border_width_all(1)
	n.set_corner_radius_all(px(2, k))
	n.content_margin_left = px(10, k)
	n.content_margin_right = px(10, k)
	n.content_margin_top = px(5, k)
	n.content_margin_bottom = px(5, k)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = GILT_HOVER if primary else IRON2
	h.border_color = GILT_HOVER if primary else GILT2
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(GILT2, 0.35) if primary else Color(IRON, 0.5)
	d.border_color = Color(IRON3, 0.6)
	return {"normal": n, "hover": h, "pressed": h, "disabled": d}


# the focus ring every screen uses (ui_spec.md 6): no fill, a BONE border at least 2 px, 3 px outside the button
static func focus_ring(k: float) -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = BONE
	f.set_border_width_all(maxi(2, px(2, k)))
	f.set_corner_radius_all(px(4, k))
	f.expand_margin_left = px(3, k)
	f.expand_margin_right = px(3, k)
	f.expand_margin_top = px(3, k)
	f.expand_margin_bottom = px(3, k)
	return f


# the shared theme for any screen: body font and base size, buttons, labels, rich text, tooltips. The battle HUD adds
# its focus ring on top (hud.gd _theme); other screens can use focus_ring(k) the same way.
static func make_theme(k: float, body: Font, body_semi: Font, base := 15) -> Theme:
	var th := Theme.new()
	th.default_font = body
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
	th.set_font("normal_font", "RichTextLabel", body)
	th.set_font("bold_font", "RichTextLabel", body_semi)
	th.set_font_size("normal_font_size", "RichTextLabel", px(14, k))
	th.set_font_size("bold_font_size", "RichTextLabel", px(14, k))
	# tooltips: a solid well with bone text (keyword definitions, one layer deep)
	var tp := well(k, Color(0, 0, 0, 0), 10, 7)
	tp.border_color = GILT2
	th.set_stylebox("panel", "TooltipPanel", tp)
	th.set_color("font_color", "TooltipLabel", BONE)
	th.set_font("font", "TooltipLabel", body)
	th.set_font_size("font_size", "TooltipLabel", px(14, k))
	# scroll bars: thin, iron, out of the way
	var sg := StyleBoxFlat.new()
	sg.bg_color = Color(IRON3, 0.9)
	sg.set_corner_radius_all(px(2, k))
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


# gilt corner ticks on a frame (the etched-glass look): drawn by the frame itself, over its edge, under its children
static func ticks_on(p: Control, k: float, col := GILT) -> void:
	var arm := float(px(14, k))
	var w := maxf(1.0, float(px(2, k)))
	p.draw.connect(func() -> void:
		var r := Rect2(Vector2.ZERO, p.size)
		var a := Color(col, 0.85)
		for corner in [[r.position, Vector2(1, 1)], [Vector2(r.end.x, r.position.y), Vector2(-1, 1)],
				[Vector2(r.position.x, r.end.y), Vector2(1, -1)], [r.end, Vector2(-1, -1)]]:
			var q: Vector2 = corner[0]
			var d: Vector2 = corner[1]
			p.draw_line(q, q + Vector2(arm * d.x, 0), a, w)
			p.draw_line(q, q + Vector2(0, arm * d.y), a, w))


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
