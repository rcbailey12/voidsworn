extends CanvasLayer
# Draw the real scene under a cover so gameplay's material pipelines get warmed.

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
	var US = load("res://ui/ui_scale.gd")   # the one shared scale law (ui_spec.md section 4); was a fixed 24 at every size
	label.add_theme_font_size_override("font_size", US.px(24, US.k_for(get_viewport().get_visible_rect().size)))
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	cover.add_child(label)

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
