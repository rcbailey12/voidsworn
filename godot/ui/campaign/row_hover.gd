extends Panel
## A mouse-transparent tooltip for rows in a column whose other text must stay readable.

const WRAP_FLAGS := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE

var column: Control
var gap := 12.0
var _row: Control
var _label := Label.new()
var _timer := Timer.new()
var _natural_width := 0.0
var _text_heights: Dictionary = {}


func _ready() -> void:
	name = "RowHoverCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_label)
	_timer.one_shot = true
	_timer.timeout.connect(set_process.bind(true))
	add_child(_timer)
	set_process(false)
	hide()


func watch(row: Control) -> void:
	var text := row.tooltip_text
	if text.is_empty(): return
	row.tooltip_text = ""
	row.mouse_entered.connect(_start.bind(row, text))
	row.mouse_exited.connect(_stop.bind(row))
	row.tree_exiting.connect(_stop.bind(row))
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton: _stop(row))


func _start(row: Control, text: String) -> void:
	hide()
	set_process(false)
	_row = row
	add_theme_stylebox_override("panel", row.get_theme_stylebox("panel", "TooltipPanel"))
	_label.add_theme_font_override("font", row.get_theme_font("font", "TooltipLabel"))
	_label.add_theme_font_size_override("font_size", row.get_theme_font_size("font_size", "TooltipLabel"))
	_label.add_theme_color_override("font_color", row.get_theme_color("font_color", "TooltipLabel"))
	_label.text = text
	var font := _label.get_theme_font("font")
	var font_size := _label.get_theme_font_size("font_size")
	_natural_width = 0.0
	_text_heights.clear()
	for line in text.split("\n"):
		_natural_width = maxf(_natural_width, ceilf(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x))
	_timer.start(maxf(0.001, float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec", 0.5))))


func _stop(row: Control) -> void:
	if row != _row: return
	_row = null
	_timer.stop()
	set_process(false)
	hide()


func _process(_delta: float) -> void:
	if not is_instance_valid(_row) or not _row.is_visible_in_tree():
		_stop(_row)
		return
	var bounds := get_viewport_rect().grow(-gap)
	var blocked := column.get_global_rect().intersection(bounds)
	var row_rect := _row.get_global_rect()
	if not blocked.intersects(row_rect):
		hide()
		return

	# Prefer the space alongside the entire rail or manifest, then above or below it.
	var right := blocked.end.x + gap
	var bottom := blocked.end.y + gap
	var slots := [
		Rect2(right, bounds.position.y, bounds.end.x - right, bounds.size.y),
		Rect2(bounds.position.x, bounds.position.y, blocked.position.x - gap - bounds.position.x, bounds.size.y),
		Rect2(bounds.position.x, bottom, bounds.size.x, bounds.end.y - bottom),
		Rect2(bounds.position.x, bounds.position.y, bounds.size.x, blocked.position.y - gap - bounds.position.y),
	]
	var style := get_theme_stylebox("panel")
	var padding := style.get_minimum_size()
	var inset := Vector2(style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP))
	var font := _label.get_theme_font("font")
	var font_size := _label.get_theme_font_size("font_size")
	for slot in slots:
		var width := minf(_natural_width, floorf(slot.size.x - padding.x))
		if width < minf(_natural_width, 12.0 * font_size) or slot.size.y <= 0.0: continue
		if not _text_heights.has(width):
			var height := font.get_multiline_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, -1, WRAP_FLAGS).y
			var lines := roundi(height / font.get_height(font_size))
			_text_heights[width] = ceilf(height + maxi(0, lines - 1) * _label.get_theme_constant("line_spacing"))
		var text_size := Vector2(width, _text_heights[width])
		var card_size := text_size + padding
		if card_size.y > slot.size.y: continue
		_label.position = inset
		_label.size = text_size
		size = card_size
		global_position = row_rect.position.round().clamp(slot.position, slot.end - size)
		show()
		return
	hide()
