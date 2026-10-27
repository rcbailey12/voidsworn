extends Control
# A faction crest for the campaign screens (lore round 8, approved R59). Uses the portraits helper's crest when one exists
# (Portraits.faction_crest(id) if the method is there, else res://portraits/crests/faction_<id>.svg); otherwise draws the
# bible's crest as clean vector art in the faction's colours (map3d_system.gd LOOKS):
#   voidsworn  a half sun, its lower half black, over a broken link
#   hegemony   a wedge in a ring of five linked nodes
#   corsair    a ring of welded scrap teeth around three claw slashes
#   chorus     a ring of nine open mouths
#   ithar      a cracked lens with one beam of light passing through
#   deathless  an eclipsed sun: a black disc with a thin white-gold ring
# Ids never change (the faction ids above are the game's ids).

const System := preload("res://ui/campaign/map3d_system.gd")
var fac := "voidsworn"
var tex: Texture2D = null

static func make(f: String, size: float) -> Control:
	var c = load("res://ui/campaign/crest.gd").new()
	c.fac = f; c.custom_minimum_size = Vector2(size, size); c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.tex = faction_texture(f)
	return c

static func faction_texture(f: String) -> Texture2D:
	if ResourceLoader.exists("res://portraits/portraits.gd"):
		var Pt = load("res://portraits/portraits.gd")
		if Pt.has_method("faction_crest"):
			var t = Pt.faction_crest(f)
			if t is Texture2D: return t
	var p = "res://portraits/crests/faction_%s.svg" % f
	if ResourceLoader.exists(p):
		var r = load(p)
		if r is Texture2D: return r
	return null

func _draw() -> void:
	var s = min(size.x, size.y); var c = size * 0.5; var R = s * 0.46
	if tex != null:
		draw_texture_rect(tex, Rect2(c - Vector2(R, R), Vector2(R, R) * 2.0), false); return
	var L = System.look(fac)
	var main: Color = L["light"]; var dark = Color(0.02, 0.025, 0.04, 0.92); var w = max(1.5, s * 0.05)
	draw_circle(c, R, dark)
	draw_arc(c, R, 0, TAU, 48, Color(main, 0.55), max(1.0, s * 0.03), true)
	match fac:
		"voidsworn":   # half sun, lower half black, over a broken link
			var sc = c + Vector2(0, -R * 0.12); var sr = R * 0.5
			draw_colored_polygon(_half_disc(sc, sr, true), main)
			draw_colored_polygon(_half_disc(sc, sr, false), Color(0, 0, 0, 1))   # the lower half black
			draw_arc(sc, sr, 0, PI, 24, Color(main, 0.7), w * 0.5, true)
			for i in 7:
				var a = PI + PI * (i + 0.5) / 7.0
				draw_line(sc + Vector2(cos(a), sin(a)) * sr * 1.12, sc + Vector2(cos(a), sin(a)) * sr * 1.4, main, w * 0.6, true)
			var ly = c.y + R * 0.52; var lw = R * 0.32; var lh = R * 0.17
			for sx in [-1.0, 1.0]:
				var lc = Vector2(c.x + sx * R * 0.36, ly)
				draw_arc(lc, lh, PI * 0.5 if sx < 0 else -PI * 0.5, PI * 1.5 if sx < 0 else PI * 0.5, 16, main, w * 0.7, true)
				draw_line(lc + Vector2(0, -lh), lc + Vector2(sx * -lw * 0.12, -lh), main, w * 0.7, true)   # the link cut open: a clear gap
				draw_line(lc + Vector2(0, lh), lc + Vector2(sx * -lw * 0.12, lh), main, w * 0.7, true)
		"hegemony":   # a wedge in a ring of five linked nodes
			var pts = []
			for i in 5:
				var a = -PI * 0.5 + TAU * i / 5.0; pts.append(c + Vector2(cos(a), sin(a)) * R * 0.66)
			for i in 5: draw_line(pts[i], pts[(i + 1) % 5], Color(main, 0.8), w * 0.5, true)
			for p in pts: draw_circle(p, R * 0.1, main)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -R * 0.38), c + Vector2(R * 0.24, R * 0.3), c + Vector2(0, R * 0.16), c + Vector2(-R * 0.24, R * 0.3)]), main)
		"corsair":   # a ring of welded scrap teeth around three claw slashes
			for i in 14:
				var a = TAU * i / 14.0; var dir = Vector2(cos(a), sin(a)); var tn = Vector2(-dir.y, dir.x)
				var b = c + dir * R * 0.66; var tip = c + dir * R * (0.5 if i % 2 == 0 else 0.55)
				draw_colored_polygon(PackedVector2Array([b + tn * R * 0.1, b - tn * R * 0.1, tip]), Color(main, 0.9))
			draw_arc(c, R * 0.7, 0, TAU, 40, main, w * 0.6, true)
			for k in 3:
				var x = (k - 1) * R * 0.2
				draw_line(c + Vector2(x - R * 0.12, -R * 0.32), c + Vector2(x + R * 0.12, R * 0.32), main, w * 0.9, true)
		"chorus":   # a ring of nine open mouths
			for i in 9:
				var a = -PI * 0.5 + TAU * i / 9.0; var p = c + Vector2(cos(a), sin(a)) * R * 0.6
				draw_arc(p, R * 0.13, 0, TAU, 14, main, w * 0.6, true)
				draw_circle(p, R * 0.06, Color(main, 0.6))
			draw_circle(c, R * 0.18, Color(main, 0.35))
		"ithar":   # a cracked lens with one beam of light passing through
			draw_arc(c, R * 0.5, 0, TAU, 40, main, w * 0.7, true)
			draw_polyline(PackedVector2Array([c + Vector2(-R * 0.1, -R * 0.5), c + Vector2(R * 0.05, -R * 0.15), c + Vector2(-R * 0.08, R * 0.1), c + Vector2(R * 0.12, R * 0.5)]), Color(main, 0.7), w * 0.4, true)
			var beam_a = c + Vector2(-R * 0.95, -R * 0.35); var beam_b = c + Vector2(R * 0.95, R * 0.35)
			draw_line(beam_a, beam_b, Color(1, 1, 1, 0.9), w * 0.7, true)
			for k in 3:   # the rainbow fringe where the beam leaves the lens
				var hc = Color.from_hsv(0.0 + k * 0.3, 0.7, 1.0, 0.7)
				draw_line(c + Vector2(R * 0.45, R * 0.16), c + Vector2(R * 0.95, R * (0.22 + k * 0.1)), hc, w * 0.35, true)
		"deathless":   # an eclipsed sun: a black disc with a thin white-gold ring
			for i in 12:
				var a = TAU * i / 12.0
				draw_line(c + Vector2(cos(a), sin(a)) * R * 0.56, c + Vector2(cos(a), sin(a)) * R * 0.78, Color(main, 0.45), w * 0.35, true)
			draw_circle(c, R * 0.5, Color(main, 0.9))
			draw_circle(c, R * 0.45, Color(0, 0, 0, 1))
		_:
			draw_circle(c, R * 0.3, main)
func _half_disc(cc: Vector2, r: float, top: bool) -> PackedVector2Array:
	var pts = PackedVector2Array()
	for i in 25:
		var a = PI + PI * i / 24.0 if top else PI * i / 24.0
		pts.append(cc + Vector2(cos(a), sin(a)) * r)
	return pts
