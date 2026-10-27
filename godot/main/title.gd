extends CanvasLayer
# The title screen (campaign_meta.js titleScreen) and the settings panel. Words and colours as today's game.

const HUD := preload("res://ui/battle/hud.gd")
const Brand := preload("res://ui/battle/brand.gd")

var main: Node
var k := 1.0
var root: Control
var menu: VBoxContainer
var font: FontFile
var font_semi: FontFile
var font_goth: Font
var settings_panel: PanelContainer
var toast_lbl: Label
var _toast_t := 0.0


func _font(n: String) -> FontFile:
	# the imported font when the project has been imported or exported, else the raw file
	var p := "res://ui/battle/fonts/" + n
	if HUD.imported_ok(p):
		var r = load(p)
		if r is FontFile:
			return r
	var f := FontFile.new()
	if FileAccess.file_exists(p):
		f.data = FileAccess.get_file_as_bytes(p)
	return f


func s(v: float) -> int:
	return int(round(v * k))


func _ready() -> void:
	k = clampf(get_viewport().get_visible_rect().size.y / 1080.0, 0.6, 2.2)
	font = _font("BarlowSemiCondensed-Regular.ttf")
	font_semi = _font("BarlowSemiCondensed-SemiBold.ttf")
	font_goth = Brand.display()  # the sci-fi display face (lore round 5); the blackletter is retired
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json")) if FileAccess.file_exists("res://gen/manifest.json") else {}
	if man is Dictionary and str(man.get("sky", "")) != "" and ResourceLoader.exists(str(man["sky"])):
		bg.texture = load(str(man["sky"]))
		bg.modulate = Color(0.55, 0.55, 0.6)
	root.add_child(bg)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.04, 0.07, 0.55)
	root.add_child(shade)
	_bg = bg
	_shade = shade
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", s(14))
	root.add_child(v)
	# the game's name (brand.gd TITLE, the one place to rename it), one line at the largest size that fits
	var vw := get_viewport().get_visible_rect().size.x
	var h := _label(Brand.TITLE, 84, HUD.GILT, font_goth)
	h.add_theme_font_size_override("font_size", Brand.fit_size(Brand.TITLE, font_goth, s(84), vw * 0.86))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var sub := _label(Brand.TAGLINE, 19, HUD.BONE2, font)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(s(620), 0)
	v.add_child(sub)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", s(8))
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.custom_minimum_size = Vector2(s(300), 0)
	v.add_child(menu)
	var camp: bool = main.has_campaign()
	var saved := camp and _campaign_has_save()
	if saved:
		menu.add_child(_button("Continue run", func() -> void: main.new_run({"continue": true}), true))
	menu.add_child(_button("New run", func() -> void: main.new_run({}), not saved))
	if camp:
		menu.add_child(_button("Progression", func() -> void: main.new_run({"screen": "legacy"})))
		menu.add_child(_button("How to play", func() -> void: main.new_run({"screen": "help"})))
	if ResourceLoader.exists("res://story/story.gd"):   # story hook: the Career screen (godot/story/README.md)
		menu.add_child(_button("Career", func() -> void: load("res://story/story.gd").open_standalone(self)))
	menu.add_child(_button("Quick battle", func() -> void: main.quick_battle()))
	menu.add_child(_button("Settings", func() -> void: _settings()))
	menu.add_child(_button("Quit", func() -> void: main.quit_clean()))
	(menu.get_child(0) as Control).grab_focus.call_deferred()  # arrow keys, Enter and a controller work from the start
	toast_lbl = _label("", 17, HUD.EMBER, font_semi)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = -s(80)
	root.add_child(toast_lbl)


func _campaign_has_save() -> bool:
	return main.campaign_has_save()


func _label(t: String, size: int, col: Color, f: Font) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", s(size))
	l.add_theme_color_override("font_color", col)
	return l


func _button(t: String, cb: Callable, primary := false) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_ALL  # keyboard and controller reach every title and settings button (WCAG 2.1.1)
	b.add_theme_font_override("font", font_semi if primary else font)
	b.add_theme_font_size_override("font_size", s(19))
	var sb := StyleBoxFlat.new()
	sb.bg_color = HUD.GILT if primary else Color(0.133, 0.176, 0.267, 0.85)
	sb.border_color = HUD.GILT if primary else HUD.IRON3
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(s(4))
	sb.content_margin_top = s(9)
	sb.content_margin_bottom = s(9)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = Color("#e2bb62") if primary else HUD.IRON3
	sh.border_color = HUD.GILT2 if not primary else HUD.GILT
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	var sf := StyleBoxFlat.new()  # a visible focus ring (WCAG 2.4.7)
	sf.draw_center = false
	sf.border_color = HUD.BONE
	sf.set_border_width_all(maxi(2, s(2)))
	sf.set_corner_radius_all(s(4))
	sf.expand_margin_left = 3; sf.expand_margin_right = 3; sf.expand_margin_top = 3; sf.expand_margin_bottom = 3
	b.add_theme_stylebox_override("focus", sf)
	var fc := Color("#1c1405") if primary else HUD.BONE
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_hover_color", fc)
	b.pressed.connect(cb)
	return b


func toast(t: String) -> void:
	toast_lbl.text = t
	_toast_t = 3.0


func _process(dt: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= dt
		toast_lbl.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


# ---------------------------------------------------------------- settings (the game's options menu)

func _settings() -> void:
	if settings_panel != null:
		settings_panel.queue_free()
	var S: Dictionary = main.settings
	settings_panel = PanelContainer.new()
	var g := StyleBoxFlat.new()
	g.bg_color = Color(0.047, 0.07, 0.12, 0.95)
	g.border_color = Color(0.816, 0.651, 0.294, 0.3)
	g.set_border_width_all(1)
	g.set_corner_radius_all(s(8))
	g.content_margin_left = s(28)
	g.content_margin_right = s(28)
	g.content_margin_top = s(20)
	g.content_margin_bottom = s(20)
	settings_panel.add_theme_stylebox_override("panel", g)
	settings_panel.set_anchors_preset(Control.PRESET_CENTER)
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(settings_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(10))
	v.custom_minimum_size = Vector2(s(460), 0)
	settings_panel.add_child(v)
	v.add_child(_label("Settings", 24, HUD.GILT, font_goth))
	v.add_child(_toggle("Sound", "sound"))
	v.add_child(_slider("Volume", "volume", 0.0, 1.0))
	v.add_child(_toggle("Music", "music"))
	v.add_child(_slider("Music volume", "music_volume", 0.0, 1.0))
	v.add_child(_choice("Speed", "speed", [[1.0, "Normal"], [0.45, "Fast"]]))
	v.add_child(_choice("Movement", "movement", [["cinematic", "Cinematic"], ["brisk", "Brisk"]]))
	v.add_child(_choice("Enemy AI", "ai", [["veteran", "Veteran"], ["standard", "Standard"]]))
	v.add_child(_toggle("Reduce flashing", "reduce_flashing"))
	v.add_child(_choice("Screen shake", "shake", [[1.0, "Full"], [0.5, "Reduced"], [0.0, "Off"]]))
	v.add_child(_toggle("Follow enemy activations", "follow"))
	v.add_child(_choice("Cut-ins", "cine", [["key", "Key moments"], ["all", "Every attack"], ["off", "Off"]]))
	v.add_child(_toggle("Battle tips", "tips"))
	v.add_child(_toggle("Full screen", "fullscreen"))
	v.add_child(_choice("Graphics", "quality", [["max", "Max"], ["high", "High"], ["low", "Low"]]))
	v.add_child(_toggle("Temporal AA (smoother edges, softer motion)", "taa"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_button("Done", func() -> void:
		main.save_settings()
		settings_panel.queue_free()
		settings_panel = null
		_focus_first(menu), true))
	v.add_child(row)
	_focus_first(settings_panel)


func _focus_first(n: Node) -> void:
	if n == null:
		return
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).visible and not (b as Button).disabled:
			(b as Button).grab_focus.call_deferred()
			return


func _row(t: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	var l := _label(t, 18, HUD.BONE, font)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	return r


func _toggle(t: String, key: String) -> Control:
	var r := _row(t)
	var b: Button
	if not main.settings.has(key):
		main.settings[key] = true
	b = _button("On" if main.settings[key] else "Off", func() -> void:
		main.settings[key] = not bool(main.settings[key])
		b.text = "On" if main.settings[key] else "Off"
		main.save_settings())
	b.custom_minimum_size = Vector2(s(110), 0)
	r.add_child(b)
	return r


func _choice(t: String, key: String, opts: Array) -> Control:
	var r := _row(t)
	var b: Button
	var label_of := func() -> String:
		for o in opts:
			if str(o[0]) == str(main.settings[key]):
				return o[1]
		return str(opts[0][1])
	b = _button(label_of.call(), func() -> void:
		var i := 0
		for j in opts.size():
			if str(opts[j][0]) == str(main.settings[key]):
				i = j
		main.settings[key] = opts[(i + 1) % opts.size()][0]
		b.text = label_of.call()
		main.save_settings())
	b.custom_minimum_size = Vector2(s(110), 0)
	r.add_child(b)
	return r


func _slider(t: String, key: String, lo: float, hi: float) -> Control:
	var r := _row(t)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 0.05
	if not main.settings.has(key):
		main.settings[key] = 0.7
	sl.value = float(main.settings[key])
	sl.custom_minimum_size = Vector2(s(200), s(24))
	sl.value_changed.connect(func(x: float) -> void:
		main.settings[key] = x
		main.save_settings())  # saved on every change, so arrow keys and a controller save too
	r.add_child(sl)
	return r


# main's decorative battle is ready behind the menu: the sky picture fades out over it, the shade stays for the menu
var _bg: TextureRect
var _shade: ColorRect


func reveal_showcase() -> void:
	if _bg == null or not is_instance_valid(_bg):
		return
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bg, "modulate:a", 0.0, 2.5)
	tw.tween_property(_shade, "color:a", 0.42, 2.5)
