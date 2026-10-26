extends Control
# A faction crest or a medal, drawn as vector strokes (crest symbols instead of portraits, R37). Any screen can use it:
#   var c = load("res://ui/career/crest.gd").new(); c.fac = "ithar"; c.custom_minimum_size = Vector2(64, 64)
# Medal mode: set glyph (one character) and col instead of fac. dim = true draws it greyed (not earned yet).
#
# Crests: Voidsworn a cracked halo over a sword; Hegemony a wedge in a ring of five stars; Corsairs a skull with a gear
# for a jaw; Chorus a ring of nine open mouths; Ithar a sail over a falling star; Deathless an open eye over a sealed vault door, a seal ring between them.

const GLOW := {"voidsworn": "#ff7a2a", "hegemony": "#5fa0ff", "corsair": "#e0402c", "chorus": "#d6d24a", "ithar": "#9fffd2", "deathless": "#3dff6a"}

var fac := ""
var glyph := ""
var col := Color("#d0a64b")
var dim := false
var font: Font = null


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _c() -> Color:
	var c: Color = Color(GLOW[fac]) if fac != "" and GLOW.has(fac) else col
	return Color(0.42, 0.40, 0.36, 0.55) if dim else c


func _draw() -> void:
	var s := minf(size.x, size.y)
	if s < 8.0:
		return
	var o := (size - Vector2(s, s)) * 0.5
	var c := o + Vector2(s, s) * 0.5
	var r := s * 0.46
	var k := _c()
	var w := maxf(1.5, s * 0.035)
	draw_circle(c, r, Color(0.06, 0.08, 0.12, 0.92))
	draw_arc(c, r, 0, TAU, 64, k, w, true)
	draw_arc(c, r * 0.86, 0, TAU, 64, Color(k, 0.35), maxf(1.0, w * 0.5), true)
	if fac == "":
		_glyph(c, s, k)
		return
	var u := r / 10.0   # drawing unit
	match fac:
		"voidsworn":
			draw_arc(c + Vector2(0, -3.2 * u), 3.6 * u, deg_to_rad(200), deg_to_rad(265), 16, k, w, true)
			draw_arc(c + Vector2(0, -3.2 * u), 3.6 * u, deg_to_rad(280), deg_to_rad(340), 16, k, w, true)
			draw_line(c + Vector2(0, -4.5 * u), c + Vector2(0, 6.5 * u), k, w * 1.3, true)
			draw_line(c + Vector2(-2.6 * u, 2.0 * u), c + Vector2(2.6 * u, 2.0 * u), k, w, true)
			draw_line(c + Vector2(0, -4.5 * u), c + Vector2(-0.6 * u, -3.4 * u), k, w, true)
		"hegemony":
			var tri := PackedVector2Array([c + Vector2(0, -4.6 * u), c + Vector2(3.4 * u, 3.6 * u), c + Vector2(0, 2.0 * u), c + Vector2(-3.4 * u, 3.6 * u), c + Vector2(0, -4.6 * u)])
			draw_polyline(tri, k, w, true)
			for i in 5:
				var a := deg_to_rad(-90 + i * 72)
				draw_circle(c + Vector2(cos(a), sin(a)) * 7.0 * u, maxf(1.2, 0.6 * u), k)
		"corsair":
			draw_arc(c + Vector2(0, -1.2 * u), 4.2 * u, deg_to_rad(160), deg_to_rad(380), 24, k, w, true)
			draw_circle(c + Vector2(-1.6 * u, -1.4 * u), 1.0 * u, k)
			draw_circle(c + Vector2(1.6 * u, -1.4 * u), 1.0 * u, k)
			var jaw := PackedVector2Array()
			for i in 7:
				jaw.append(c + Vector2((-3.0 + i) * u, (2.8 if i % 2 == 0 else 4.4) * u))
			draw_polyline(jaw, k, w, true)
			draw_arc(c + Vector2(0, 3.6 * u), 2.0 * u, 0, TAU, 16, Color(k, 0.6), maxf(1.0, w * 0.6), true)
		"chorus":
			for i in 9:
				var a := TAU * i / 9.0
				var p := c + Vector2(cos(a), sin(a)) * 5.2 * u
				draw_arc(p, 1.2 * u, a + PI * 0.25, a + PI * 1.75, 10, k, w * 0.8, true)
			draw_circle(c, 1.4 * u, k)
		"ithar":
			var sail := PackedVector2Array([c + Vector2(-0.5 * u, -5.5 * u), c + Vector2(3.6 * u, 2.0 * u), c + Vector2(-0.5 * u, 2.0 * u), c + Vector2(-0.5 * u, -5.5 * u)])
			draw_polyline(sail, k, w, true)
			draw_line(c + Vector2(-0.5 * u, -5.5 * u), c + Vector2(-0.5 * u, 3.0 * u), k, w, true)
			var st := c + Vector2(-3.4 * u, 4.4 * u)
			draw_line(st, st + Vector2(-2.4 * u, -2.4 * u), Color(k, 0.6), w * 0.7, true)
			for i in 4:
				var a := deg_to_rad(45 + i * 90)
				draw_line(st, st + Vector2(cos(a), sin(a)) * 1.3 * u, k, w * 0.8, true)
		"deathless":
			draw_arc(c + Vector2(0, 2.4 * u), 3.8 * u, deg_to_rad(215), deg_to_rad(325), 16, k, w, true)
			draw_arc(c + Vector2(0, -2.4 * u), 3.8 * u, deg_to_rad(35), deg_to_rad(145), 16, k, w, true)
			draw_circle(c, 1.1 * u, k)
			# an open eye above a sealed vault door, a seal ring between them (no crown: R45 40k distance pass)
			draw_arc(c + Vector2(0, 3.0 * u), 1.0 * u, 0, TAU, 16, k, w * 0.8, true)
			draw_rect(Rect2(c + Vector2(-1.8 * u, 4.4 * u), Vector2(3.6 * u, 2.4 * u)), k, false, w * 0.8)
			draw_line(c + Vector2(0, 4.4 * u), c + Vector2(0, 6.8 * u), k, w * 0.6, true)
		_:
			_glyph(c, s, k)


func _glyph(c: Vector2, s: float, k: Color) -> void:
	if glyph == "":
		return
	var f: Font = font if font != null else ThemeDB.fallback_font
	var fs := int(s * 0.42)
	var ts := f.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, c + Vector2(-ts.x * 0.5, ts.y * 0.32), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, k)
