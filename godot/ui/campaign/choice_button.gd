extends PanelContainer
# A choice button (the browser's .choice): a bold line, a small line under it, sized by its text. Mouse click, or Enter / Space
# when focused. Emits pressed. Disabled choices are dimmed and ignore input.

signal pressed

var disabled := false
var sb_normal: StyleBox
var sb_hover: StyleBox
var sb_focus: StyleBox
var _hover := false

func setup(normal: StyleBox, hover: StyleBox, focus: StyleBox, is_disabled: bool) -> void:
	sb_normal = normal; sb_hover = hover; sb_focus = focus; disabled = is_disabled
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	if disabled: modulate.a = 0.5
	mouse_entered.connect(func(): _hover = true; _style())
	mouse_exited.connect(func(): _hover = false; _style())
	focus_entered.connect(_style); focus_exited.connect(_style)
	_style()

func _style() -> void:
	var s = sb_normal
	if not disabled and has_focus(): s = sb_focus
	elif not disabled and _hover: s = sb_hover
	add_theme_stylebox_override("panel", s)

func _gui_input(e: InputEvent) -> void:
	if disabled: return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		accept_event(); pressed.emit()
	elif e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		accept_event(); pressed.emit()
