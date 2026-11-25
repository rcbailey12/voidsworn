extends PanelContainer
# A choice button (the browser's .choice): a bold line, a small line under it, sized by its text. Mouse click, or Enter / Space
# when focused. Emits pressed. Disabled choices ignore input; the caller dims their words and marks them (a LOCKED tag), never
# the backing (ui_style.md 3, MN12: the old 50% fade of the whole choice is gone). Focus draws the shared ring (ring).

signal pressed

var disabled := false
var sb_normal: StyleBox
var sb_hover: StyleBox
var sb_pressed: StyleBox
var _hover := false
var _mouse_down := false
var ring: StyleBox = null   # the focus ring (glass_shell.gd focus_ring), drawn round the choice while it has focus

func setup(normal: StyleBox, hover: StyleBox, down: StyleBox, is_disabled: bool) -> void:
	sb_normal = normal; sb_hover = hover; sb_pressed = down; disabled = is_disabled
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func(): _hover = true; _style())
	mouse_exited.connect(func(): _hover = false; _style())
	focus_entered.connect(_style); focus_exited.connect(_style)
	_style()

func _style() -> void:
	var s = sb_normal
	if not disabled and _mouse_down and _hover: s = sb_pressed
	elif not disabled and (_hover or has_focus()): s = sb_hover
	add_theme_stylebox_override("panel", s)
	queue_redraw()

func _draw() -> void:
	if ring != null and not disabled and has_focus(): draw_style_box(ring, Rect2(Vector2.ZERO, size))

func _gui_input(e: InputEvent) -> void:
	if disabled: return
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		var inside := Rect2(Vector2.ZERO, size).has_point(e.position)
		if e.pressed:
			_mouse_down = inside
			if inside: grab_focus()
			_style()
		else:
			var fire := _mouse_down and inside
			_mouse_down = false
			if fire: _fire()
			else: _style()
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		accept_event(); _fire()

func _fire() -> void:
	disabled = true
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	_style()
	pressed.emit()
