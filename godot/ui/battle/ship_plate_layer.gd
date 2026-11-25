extends Control
## Packs ship plates in screen space. The same final rectangles drive drawing and hover.

const GS = preload("res://ui/theme/glass_shell.gd")
const Plate = preload("res://ui/battle/ship_plate.gd")

var plates := {}
var hidden_count := 0
var _leaders: Array[Vector4] = []
var _target := Rect2()
var _hover_id := ""
var _hover_entry := Rect2()


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_ship(id: String, at: Vector2, data: Dictionary, detail: bool, distance: float, k: float, priority: int, leader := Vector2.INF) -> void:
	var p: Plate = plates.get(id)
	if p == null:
		if data.is_empty():
			return
		p = Plate.new()
		add_child(p)
		plates[id] = p
	p.wanted = not data.is_empty()
	if p.wanted:
		p.anchor = at
		p.leader_start = at if leader == Vector2.INF else leader
		p.priority = priority
		p.present(data, detail, distance, k)
	else:
		p.hide()


func remove_ship(id: String) -> void:
	var p: Plate = plates.get(id)
	if p != null:
		p.hide()
		p.queue_free()
		plates.erase(id)
	if _hover_id == id:
		_hover_id = ""


func hovered_ship(at: Vector2) -> String:
	# An expansion can push the plate away from the mouse. Keep the entry hitbox
	# until the mouse leaves both it and the actual expanded plate.
	var current: Plate = plates.get(_hover_id)
	if current != null and current.visible and (_hover_entry.has_point(at) or current.get_rect().has_point(at)):
		return _hover_id
	_hover_id = ""
	for id in plates:
		var p: Plate = plates[id]
		if p.visible and p.get_rect().has_point(at):
			_hover_id = id
			_hover_entry = p.get_rect()
			break
	return _hover_id


func overlap_count() -> int:
	var rects: Array[Rect2] = []
	for p: Plate in plates.values():
		if p.visible:
			rects.append(p.get_rect())
	var count := 0
	for i in rects.size():
		for j in range(i + 1, rects.size()):
			if rects[i].intersects(rects[j]):
				count += 1
	return count


func place(blockers: Array, viewport_size: Vector2, k: float, target_box := Rect2()) -> void:
	var gap := maxf(3.0, 5.0 * k)
	var area := Rect2(Vector2.ONE * gap, viewport_size - Vector2.ONE * gap * 2.0)
	var taken := blockers.duplicate()
	# Put a plate outside the brackets, even in the close camera.
	if target_box.has_area():
		taken.append(target_box)
	var order: Array[String] = []
	for id in plates:
		if plates[id].wanted:
			order.append(id)
	order.sort_custom(func(a: String, b: String) -> bool:
		var pa: Plate = plates[a]
		var pb: Plate = plates[b]
		if pa.priority != pb.priority:
			return pa.priority > pb.priority
		var ra := roundi(pa.anchor.y / (12.0 * k))
		var rb := roundi(pb.anchor.y / (12.0 * k))
		return ra > rb if ra != rb else a.naturalnocasecmp_to(b) < 0)
	var rail: Array[Plate] = []
	var leaders: Array[Vector4] = []
	hidden_count = 0
	for id in order:
		var p: Plate = plates[id]
		var base := p.anchor - Vector2(p.size.x * 0.5, p.size.y + gap)
		var found := false
		p.on_rail = false
		# Prefer up. Once displaced sideways, keep that side until the center has
		# additional clearance, so a one-pixel pan does not swap lanes.
		var sides: Array[int] = [0, -1, 1]
		if p.lane != 0:
			sides[1] = p.lane
			sides[2] = -p.lane
		for side in sides:
			var at := base + Vector2(side * (p.size.x * 0.58 + gap), 0.0)
			var keep_gap := gap * 2.0 if side == 0 and p.lane != 0 else gap
			var candidate := _lift(Rect2(at, p.size), taken, keep_gap)
			if base.y - candidate.position.y <= 86.0 * k and area.encloses(candidate):
				p.lane = side
				_accept(p, candidate, taken, leaders)
				found = true
				break
		if not found:
			rail.append(p)
	# ST-C fallback. Fill edge slots only after normal placements are known.
	for p in rail:
		var found := false
		var floor_y := area.end.y - p.size.y
		var step := maxf(1.0, 2.0 * k)
		var x := area.position.x
		while x + p.size.x <= area.end.x + 0.01:
			var candidate := _lift(Rect2(Vector2(x, floor_y), p.size), taken, gap)
			if area.encloses(candidate):
				p.on_rail = true
				_accept(p, candidate, taken, leaders)
				found = true
				break
			var right := area.end.x - p.size.x
			if x < right:
				candidate = _lift(Rect2(Vector2(right, floor_y), p.size), taken, gap)
				if area.encloses(candidate):
					p.on_rail = true
					_accept(p, candidate, taken, leaders)
					found = true
					break
			# If both edge columns are full, look one slot further in.
			x += maxf(step, p.size.x * 0.5)
		if not found:
			p.hide()
			hidden_count += 1
	if _leaders != leaders or _target != target_box:
		_leaders = leaders
		_target = target_box
		queue_redraw()


func _lift(r: Rect2, taken: Array, gap: float) -> Rect2:
	while true:
		var next_y := r.position.y
		for other: Rect2 in taken:
			if r.grow(gap).intersects(other):
				next_y = minf(next_y, other.position.y - r.size.y - gap)
		if next_y >= r.position.y - 0.01:
			return r
		r.position.y = next_y
	return r


func _accept(p: Plate, r: Rect2, taken: Array, leaders: Array[Vector4]) -> void:
	p.position = r.position
	p.show()
	taken.append(r)
	var end := p.leader_start.clamp(r.position, r.end)
	leaders.append(Vector4(p.leader_start.x, p.leader_start.y, end.x, end.y))


func _draw() -> void:
	for line in _leaders:
		var from := Vector2(line.x, line.y)
		var to := Vector2(line.z, line.w)
		draw_line(from, to, Color(GS.TEXT2, 0.68), 1.0, true)
	if not _target.has_area():
		return
	for dx in [0.0, 1.0]:
		for dy in [0.0, 1.0]:
			var corner := _target.position + _target.size * Vector2(dx, dy)
			var arm := (_target.size * 0.22).clamp(Vector2(5, 5), Vector2(15, 15))
			var ends := [corner + Vector2(arm.x * (1.0 - 2.0 * dx), 0), corner + Vector2(0, arm.y * (1.0 - 2.0 * dy))]
			for end in ends:
				draw_line(corner, end, GS.INK, 4.0)
				draw_line(corner, end, GS.TEXT, 2.0)
