extends CanvasLayer
# Draw the real scene under a cover so gameplay's material pipelines get warmed.

var _load_label: Label
var _load_us
var _load_vs := Vector2.ZERO

static func pipelines() -> int:
	var count := 0
	for key in [Performance.PIPELINE_COMPILATIONS_DRAW, Performance.PIPELINE_COMPILATIONS_SPECIALIZATION, Performance.PIPELINE_COMPILATIONS_CANVAS]:
		count += int(Performance.get_monitor(key))
	return count

func _ready() -> void:
	layer = 100
	var cover := ColorRect.new()
	cover.color = Color(0.02, 0.025, 0.04)
	cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cover)
	var label := Label.new()
	label.text = "Preparing the sector..."
	_load_us = load("res://ui/ui_scale.gd")   # the one shared scale law (ui_spec.md section 4); was a fixed 24 at every size
	_load_label = label
	_apply_load_size()
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	cover.add_child(label)

# N3 (#282): follow a resize, as the other screens do, instead of freezing the scale at first layout
func _apply_load_size() -> void:
	_load_vs = get_viewport().get_visible_rect().size
	_load_label.add_theme_font_size_override("font_size", _load_us.px(24, _load_us.k_for(_load_vs)))

func _process(_dt: float) -> void:
	if _load_label == null: return
	if get_viewport().get_visible_rect().size != _load_vs: _apply_load_size()

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
