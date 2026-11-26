extends Control
## A flat preview of the actual deployment zone. Legality stays in the rules.

const GS := preload("res://ui/theme/glass_shell.gd")
const HEX := [Vector2(0, -1), Vector2(0.866, -0.5), Vector2(0.866, 0.5),
	Vector2(0, 1), Vector2(-0.866, 0.5), Vector2(-0.866, -0.5)]

var cells: Array = []
var landings: Dictionary = {}
var ships: Dictionary = {}
var selected := ""
var hover: Variant = null
var _radius := 1.0
var _origin := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func show_zone(picker: Dictionary, battle_view: Dictionary) -> void:
	cells = battle_view["hexes"]
	selected = picker["picked"].get("id", "")
	landings.clear()
	for h in picker["hexes"]:
		landings[Vector2i(h.q, h.r)] = h.open
	ships.clear()
	for unit in battle_view["units"]:
		ships[Vector2i(unit["q"], unit["r"])] = unit
	visible = not cells.is_empty()
	hover = null
	queue_redraw()


func _axial(cell: Vector2i) -> Vector2:
	return Vector2(sqrt(3.0) * (cell.x + cell.y * 0.5), 1.5 * cell.y)


func _fit() -> void:
	var lo := Vector2(INF, INF)
	var hi := -lo
	for h in cells:
		var p := _axial(Vector2i(h.q, h.r))
		lo = lo.min(p); hi = hi.max(p)
	var span := hi - lo + Vector2(2, 2)
	_radius = minf(32.0, minf(size.x * 0.72 / span.x, size.y * 0.43 / span.y))
	_origin = Vector2(size.x * 0.5, size.y * 0.32) - (lo + hi) * 0.5 * _radius


func centre(cell: Vector2i) -> Vector2:
	_fit()
	return _origin + _axial(cell) * _radius


func _outline(at: Vector2) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for v in HEX:
		polygon.append(at + v * maxf(1.0, _radius - 1.0))
	return polygon


func open_at(screen: Vector2) -> Variant:
	if not visible or selected.is_empty(): return null
	_fit()
	var p := get_global_transform_with_canvas().affine_inverse() * screen
	for cell: Vector2i in landings:
		if not landings[cell]: continue
		if Geometry2D.is_point_in_polygon(p, _outline(_origin + _axial(cell) * _radius)):
			return cell
	return null


func point_at(screen: Vector2) -> void:
	var cell = open_at(screen)
	if hover == cell: return
	hover = cell
	queue_redraw()


func _draw() -> void:
	if cells.is_empty(): return
	_fit()
	for h in cells:
		var cell := Vector2i(h.q, h.r)
		var at := _origin + _axial(cell) * _radius
		var open: bool = landings.get(cell, false)
		var in_zone := landings.has(cell)
		var filled := Color(GS.TEXT2, 0.14 if open else 0.03)
		var edge := Color(GS.TEXT2, 0.50 if open else (0.22 if in_zone else 0.08))
		if hover == cell:
			filled = Color(GS.MAP_EMBER, 0.28)
			edge = GS.MAP_EMBER
		var polygon := _outline(at)
		draw_colored_polygon(polygon, filled)
		polygon.append(polygon[0])
		draw_polyline(polygon, edge, 1.0, true)
		if ships.has(cell):
			var ship: Dictionary = ships[cell]
			var ink := GS.MAP_EMBER if ship.id == selected else GS.TEXT2
			draw_circle(at, _radius * 0.32, ink, ship.side == "player", 1.5, true)
