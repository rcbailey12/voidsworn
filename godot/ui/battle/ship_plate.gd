extends Control
## A draw-only screen-space plate. Its drawn bounds are also its layout and hover bounds.

const GS = preload("res://ui/theme/glass_shell.gd")
const Sections = preload("res://ui/battle/ship_section_state.gd")
const LOW := Color("#ffab75")
const LOST := Color("#ffb4a3")
const LOST_TRACK := Color("#74382f")
const GAP := 4.0

var anchor := Vector2.ZERO
var leader_start := Vector2.ZERO
var wanted := false
var lane := 0
var on_rail := false
var priority := 0
var expanded := false
var collapsed := false
var state := {}
var _k := 1.0
var _zoom := 1.0
var _cell_widths := PackedFloat32Array()
var _loss_rows: Array[TextParagraph] = []
var _font: Font = GS.sheet_body()
var _medium: Font = GS.sheet_medium()
var _num: Font = GS.num()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func present(data: Dictionary, detail: bool, distance: float, ui_scale: float) -> void:
	var zoom := lerpf(0.7, 1.0, clampf((distance - 26.0) / 74.0, 0.0, 1.0))
	var cells_hidden := not detail and distance > 220.0
	if state == data and expanded == detail and collapsed == cells_hidden and _zoom == zoom and _k == ui_scale:
		return
	state = data
	expanded = detail
	collapsed = cells_hidden
	_zoom = zoom
	_k = ui_scale
	var parts: Array[Dictionary] = state["sections"]
	_cell_widths.clear()
	_loss_rows.clear()
	var w := _px(352.0 if expanded else 172.0)
	if not collapsed and not parts.is_empty():
		for part in parts:
			var cell_w := ceilf(_medium.get_string_size(part["cell"], HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17)).x) + _px(5)
			_cell_widths.append(cell_w)
		w = maxf(w, _cell_widths[0] + _cell_widths[1] + _cell_widths[2] + _px(12 + GAP * 2))
	var h := _row_h(_medium, 19) + _px(6 + 4 + 5 + 6 + 5)
	if not collapsed and not parts.is_empty():
		h += _row_h(_medium, 17)
	if expanded:
		for line in Sections.losses(parts):
			var paragraph := TextParagraph.new()
			paragraph.width = w - _px(16)
			paragraph.break_flags = TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			paragraph.add_string(line, _font, _fs(17))
			_loss_rows.append(paragraph)
			h += ceilf(paragraph.get_size().y) + _px(3)
	size = Vector2(ceilf(w), ceilf(h))
	queue_redraw()


func _px(value: float) -> float:
	return value * _k * _zoom


func _fs(value: float) -> int:
	return maxi(1, roundi(maxf(17.0, value * _zoom) * _k))


func _row_h(font: Font, nominal: int) -> float:
	return ceilf(font.get_height(_fs(nominal)))


func _draw() -> void:
	if state.is_empty():
		return
	var bounds := Rect2(Vector2.ZERO, size)
	var is_up: bool = state["up"]
	var edge := GS.MAP_EMBER if is_up else (GS.TEXT3 if state["friend"] else GS.TEXT2)
	draw_rect(bounds, Color(0.064, 0.042, 0.032, 0.96))
	draw_rect(Rect2(0, 0, maxf(1.0, _px(2)), size.y), Color(edge, 1.0 if is_up else 0.60))
	if expanded:
		draw_rect(bounds, Color(edge, 0.32), false, 1.0)
	var x := _px(6)
	var w := size.x - 2.0 * x
	var y := _px(2)
	var name_w := w
	var cap: float = state["shield_max"]
	if expanded and cap > 0.0:
		var count := "%d / %d" % [roundi(float(state["shield"])), roundi(cap)]
		var cw := _num.get_string_size(count, HORIZONTAL_ALIGNMENT_LEFT, -1, _fs(17)).x
		if cw + _px(50) < w:
			name_w -= cw + _px(8)
			_word(count, _num, 17, Vector2(x + w - cw, y), cw + 1, GS.GLACIER)
	var name_color := GS.MAP_EMBER if is_up else (GS.NEM if state["nemesis"] else GS.TEXT)
	_word(state["name"], _medium, 19, Vector2(x, y), name_w, name_color)
	y += _row_h(_medium, 19) + _px(2)
	var shield := Rect2(x, y, w, _px(4))
	_bar(shield, float(state["shield"]) / maxf(1.0, cap), GS.GLACIER, GS.SHIELD_TRACK)
	if state["locked"] or state["generator_lost"]:
		_hatch(shield, GS.GLACIER)
	y += _px(8)
	var parts: Array[Dictionary] = state["sections"]
	if parts.is_empty():
		var f: float = state["hull_fraction"]
		_bar(Rect2(x, y, w, _px(6)), f, GS.MAP_EMBER if f < 0.3 else GS.TEXT, GS.BAR_TRACK)
	else:
		var step_gap := _px(GAP)
		var remaining := w - 2.0 * step_gap
		for cw in _cell_widths:
			remaining -= cw
		var bx := x
		for i in parts.size():
			var part := parts[i]
			var cw := remaining / 3.0 + (_cell_widths[i] if not _cell_widths.is_empty() else 0.0)
			var bar := Rect2(bx, y, cw, _px(6))
			var fraction: float = part["fraction"]
			if part["lost"]:
				draw_rect(bar, LOST_TRACK, false, 1.0)
			else:
				_bar(bar, fraction, GS.MAP_EMBER if fraction < 0.3 else GS.TEXT, GS.BAR_TRACK)
			if not collapsed:
				var col := LOST if part["lost"] else (LOW if fraction < 1.0 else GS.TEXT2)
				_word(part["cell"], _medium, 17, Vector2(bx, y + _px(7)), cw, col)
			bx += cw + step_gap
	y += _px(11)
	if not collapsed and not parts.is_empty():
		y += _row_h(_medium, 17)
	for paragraph in _loss_rows:
		paragraph.draw(get_canvas_item(), Vector2(x, y), LOST)
		y += ceilf(paragraph.get_size().y) + _px(3)


func _word(value: String, font: Font, nominal: int, at: Vector2, width: float, col: Color) -> void:
	var fs := _fs(nominal)
	draw_string(font, at + Vector2(0, font.get_ascent(fs)), value, HORIZONTAL_ALIGNMENT_LEFT, width, fs, col)


func _bar(r: Rect2, fraction: float, col: Color, track: Color) -> void:
	draw_rect(r, track)
	if fraction > 0.0:
		draw_rect(Rect2(r.position, Vector2(r.size.x * minf(1.0, fraction), r.size.y)), col)


func _hatch(r: Rect2, col: Color) -> void:
	var x := r.position.x
	while x + r.size.y <= r.end.x:
		draw_line(Vector2(x, r.end.y), Vector2(x + r.size.y, r.position.y), Color(col, 0.65), 1.0)
		x += maxf(3.0, _px(5))
