extends CanvasLayer
# Draw the real scene under a cover so gameplay's material pipelines get warmed.

const Kit := preload("res://ui/theme/orders_kit.gd")
const GS := preload("res://ui/theme/glass_shell.gd")
const UiScale := preload("res://ui/ui_scale.gd")

var briefing := {}
var reduce_motion := false


# C9: one cover for sector and battle. It can also sit inside the battle HUD's CanvasLayer.
class Briefing extends ColorRect:
	var details := {}
	var reduce_motion := false
	var ships := Vector2i.ZERO
	var status: Label
	var _box: VBoxContainer
	var _size := Vector2.ZERO
	var _scale := 0.0
	var _time := 0.0

	func _ready() -> void:
		color = GS.INK
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(center)
		_box = VBoxContainer.new()
		_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(_box)
		_layout()

	func _layout() -> void:
		_size = get_viewport_rect().size
		_scale = UiScale.k_for(_size)
		for child in _box.get_children():
			_box.remove_child(child)
			child.queue_free()
		var width := minf(710.0, _size.x * 0.85 / _scale)
		_box.add_theme_constant_override("separation", Kit.px(12, _scale))
		_box.add_child(Kit.label(details.get("title", "Flight briefing"), 42, _scale, GS.TEXT, Kit.head_font(), true, width))
		var line := ColorRect.new()
		line.color = GS.MAP_EMBER
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		line.custom_minimum_size = Vector2(Kit.px(72, _scale), maxi(1, Kit.px(3, _scale)))
		_box.add_child(line)
		for key in ["enemy", "objective", "tip"]:
			var line_text := str(details.get(key, ""))
			if not line_text.is_empty():
				var l := Kit.label(line_text, 22 if key != "tip" else 19, _scale, GS.TEXT if key != "tip" else GS.TEXT2, null, true, width)
				l.name = key.capitalize()
				_box.add_child(l)
		status = Kit.label("", 17, _scale, GS.MAP_EMBER, Kit.mono_font(), false)
		_box.add_child(status)
		_update_status()

	func _process(dt: float) -> void:
		_time += dt
		if get_viewport_rect().size != _size or not is_equal_approx(UiScale.k_for(_size), _scale):
			_layout()
		else:
			_update_status()

	func _update_status() -> void:
		var step := "Ships ready %d / %d" % [ships.x, ships.y] if ships.y > 0 else "Preparing the field"
		var mark := "  " + ".".repeat(1 + int(_time * 3.0) % 3) if not reduce_motion else ""
		status.text = step + mark

static func pipelines() -> int:
	var count := 0
	for key in [Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION, Performance.PIPELINE_COMPILATIONS_CANVAS]:
		count += int(Performance.get_monitor(key))
	return count

func _ready() -> void:
	layer = 100
	var cover := Briefing.new()
	cover.details = briefing
	cover.reduce_motion = reduce_motion
	add_child(cover)

static func settle(tree: SceneTree) -> void:
	if DisplayServer.get_name() == "headless": return
	var previous := -1
	var quiet := 0
	var since := Time.get_ticks_msec()
	var last := since
	# Hard cap (Opus review, Nov 3): on a slow PC every frame can take over 100 ms,
	# so "quiet" may never build up. The cover must lift after 12 s whatever happens.
	var start := since
	while (quiet < 12 or Time.get_ticks_msec() - since < 500) and Time.get_ticks_msec() - start < 12000:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_msec()
		var count := pipelines()
		if count == previous and now - last < 100:
			quiet += 1
		else:
			quiet = 0
			since = now
		previous = count
		last = now
