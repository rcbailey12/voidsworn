extends Control
## CM-A Turn Corner. One visible speaker and up to three waiting transmissions.

const GS := preload("res://ui/theme/glass_shell.gd")
const Faces := preload("res://ui/captain_face.gd")
const CAPACITY := 3
const SLIDE := 0.20
const HOLD := 3.50
const KILL_WINDOW := 1.0

enum Kind { SELECTED_LOSS, KILL, COMMAND, OTHER_LOSS, HAIL }
const TAGS := ["SECTION LOST", "KILL", "COMMAND", "SECTION LOST", "HAIL"]

var pending: Array[Dictionary] = []
var current: Dictionary = {}
var _clock := 0.0
var _age := 0.0
var _home := Rect2()
var _scale := 1.0
var _still := false
var _allowed := true
var _face: TextureRect
var _tag: Label
var _callsign: Label
var _speaker: Label
var _line: Label
var _veil: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	hide()
	_face = TextureRect.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(_face)
	_tag = _label(GS.sheet_medium(), GS.TEXT2)
	_callsign = _label(GS.sheet_medium(), GS.TEXT2)
	_callsign.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_speaker = _label(GS.sheet_name(), GS.TEXT)
	_line = _label(GS.sheet_body(), GS.TEXT)
	var shade := Gradient.new()
	shade.offsets = PackedFloat32Array([0.0, 0.96, 1.0])
	shade.colors = PackedColorArray([Color(0, 0, 0, 0.94), Color(0, 0, 0, 0.94), Color(0, 0, 0, 0)])
	_veil = GradientTexture2D.new()
	_veil.gradient = shade
	_veil.width = 256
	_veil.height = 1


func _label(font: Font, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_override("font", font)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func enqueue(kind: Kind, identity: Dictionary, line: String) -> void:
	if kind == Kind.KILL:
		if _merge_kill(current, identity):
			_show_message()
			return
		for entry in pending:
			if _merge_kill(entry, identity):
				return
	var msg := {"kind": kind, "identity": identity.duplicate(), "line": line, "count": 1, "time": _clock}
	# Stable order at equal priority. A full queue drops the latest at the lowest priority, hails first.
	var i := 0
	while i < pending.size() and int(pending[i]["kind"]) <= kind:
		i += 1
	pending.insert(i, msg)
	if pending.size() > CAPACITY:
		pending.pop_back()


func _merge_kill(entry: Dictionary, identity: Dictionary) -> bool:
	if entry.get("kind", -1) != Kind.KILL:
		return false
	var id := str(identity.get("id", ""))
	if id.is_empty() or id != entry["identity"].get("id") or _clock - float(entry["time"]) > KILL_WINDOW:
		return false
	entry["time"] = _clock
	entry["count"] += 1
	entry["line"] = "%d kills" % int(entry["count"])
	return true


func clear() -> void:
	pending.clear()
	current.clear()
	_age = 0.0
	hide()


func place(home: Rect2, scale: float, still: bool, allowed: bool) -> void:
	var resized_slot := _home.size != home.size or _scale != scale
	_home = home
	_scale = scale
	_still = still
	_allowed = allowed
	if resized_slot and home.has_area():
		size = home.size
		_layout_content()
		queue_redraw()
	_update_pose()


func _layout_content() -> void:
	var portrait := roundf(64 * _scale)
	_face.position = Vector2(0, roundf((size.y - portrait) * 0.5))
	_face.size = Vector2.ONE * portrait
	var x := portrait + roundf(12 * _scale)
	var width := maxf(0.0, size.x - x - roundf(22 * _scale))
	for row in [[_tag, 0, 17], [_callsign, 0, 17], [_speaker, 19, 28], [_line, 53, 18]]:
		var label: Label = row[0]
		label.add_theme_font_size_override("font_size", maxi(1, roundi(float(row[2]) * _scale)))
		label.position = Vector2(x, roundf((float(row[1]) + 2) * _scale))
		label.size = Vector2(width, 0)
	var call_width := minf(width * 0.45, roundf(119 * _scale))
	_tag.size.x = maxf(0.0, width - call_width - roundf(8 * _scale))
	_callsign.position.x = x + width - call_width
	_callsign.size.x = call_width


func _show_message() -> void:
	var identity: Dictionary = current["identity"]
	_face.texture = identity.get("face")
	if _face.texture == null:
		_face.texture = Faces.fallback()
	_tag.text = TAGS[int(current["kind"])]
	_speaker.text = str(identity.get("name", "")).to_upper()
	_callsign.text = str(identity.get("callsign", "")).to_upper()
	_line.text = str(current["line"]).replace("\n", " ").replace("\r", " ")


func _process(dt: float) -> void:
	if not _allowed:
		return  # Keep the active hold and waiting queue in place while the HUD hides comms.
	_clock += dt
	if not current.is_empty():
		_age += dt
		if _age >= HOLD + (0.0 if _still else SLIDE * 2.0):
			current = {}
	if current.is_empty() and not pending.is_empty():
		current = pending.pop_front()
		_age = 0.0
		_show_message()
	_update_pose()


func _update_pose() -> void:
	visible = _allowed and _home.has_area() and not current.is_empty()
	if not visible:
		return
	var reveal := 1.0
	if not _still:
		var edge := minf(_age / SLIDE, (HOLD + SLIDE * 2.0 - _age) / SLIDE)
		reveal = smoothstep(0.0, 1.0, edge)
	position = _home.position + Vector2(-28 * _scale * (1.0 - reveal), 0)
	modulate.a = reveal


func _draw() -> void:
	if _veil != null:
		draw_texture_rect(_veil, Rect2(Vector2.ZERO, size), false)
