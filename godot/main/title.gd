extends CanvasLayer
# The title screen (campaign_meta.js titleScreen) and the settings panel. Words and colours as today's game.

const HUD := preload("res://ui/battle/hud.gd")
const Brand := preload("res://ui/battle/brand.gd")
const UiScale := preload("res://ui/ui_scale.gd")
# The palette this screen had before the battle HUD moved to Lime Tactical (R149, #271). The screen keeps it until its own
# rollout moves it onto godot/ui/theme/glass_shell.gd (contrib/opus/briefs/ui_style.md section 8), so it never shows a
# half-changed look. The focus ring stays HUD.BONE, the battle ring's own colour (ui_spec.md 6).
const T_GILT := Color("#d0a64b")
const T_GILT2 := Color("#8c6d2c")
const T_BONE := Color("#e6dcc4")
const T_BONE2 := Color("#b3aa95")
const T_BONE3 := Color("#7d7768")
const T_IRON3 := Color("#2d3a56")
const T_EMBER := Color("#f0b35a")

var main: Node
var k := 1.0
var root: Control
var menu: VBoxContainer
var font: FontFile
var font_semi: FontFile
var font_goth: Font
var settings_panel: PanelContainer
var settings_dim: ColorRect
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
	font = _font("BarlowSemiCondensed-Regular.ttf")
	font_semi = _font("BarlowSemiCondensed-SemiBold.ttf")
	font_goth = Brand.display()  # the sci-fi display face (lore round 5); the blackletter is retired
	_build()
	_report.call_deferred()
	# screenshot jobs: --title-open credits opens the Credits screen (main.gd opens Settings for --title-open settings)
	if main != null and "args" in main and main.args.has("title-rebuild-test"):   # the rebuild a window resize triggers
		get_tree().create_timer(1.0).timeout.connect(func() -> void: _built_vs = Vector2.ONE)
	if main != null and "args" in main and str(main.args.get("title-open", "")) == "credits":
		get_tree().create_timer(1.5).timeout.connect(func() -> void: _credits())


# UI pass (Nov 1): the title is built for the window it is in, and built again when the window changes size (the game
# starts maximised and capture jobs or Full screen resize it a moment later; the title used to keep the first size, so
# at 1920x1080 a 4K-sized title ran off both edges and the menu off the bottom)
var _built_vs := Vector2.ZERO
var _resize_t := -1.0


func _build() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_vs = vs
	k = UiScale.k_for(vs)
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
	# the game's name (brand.gd TITLE, the one place to rename it): one line at the largest size that fits 88% of the
	# window width; if that would be small (a narrow window), two centred lines at a larger size instead
	var vw := vs.x
	var h := _label(Brand.TITLE, 84, T_GILT, font_goth)
	h.text = _title_text(vw * 0.88)
	h.add_theme_font_size_override("font_size", _title_size)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_lbl = h
	v.add_child(h)
	var sub := _label(Brand.TAGLINE, 19, T_BONE2, font)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(minf(vw * 0.86, font.get_string_size(Brand.TAGLINE, HORIZONTAL_ALIGNMENT_LEFT, -1, s(19)).x + s(4)), 0)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(sub)
	# the playtest switch (R1, Nov 1): every admiral, hull and variant unlocked; the line says so in gold on the title
	var pt := _playtest_on()
	if pt != null:
		var pl := _label("Playtest: everything unlocked (all admirals, carriers, battleships and hull variants)" if pt else "Playtest unlocks are off: unlock admirals and hulls with renown", 17, T_GILT if pt else T_BONE3, font_semi)
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.custom_minimum_size = Vector2(minf(vw * 0.86, font_semi.get_string_size(pl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, s(17)).x + s(4)), 0)
		pl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		playtest_lbl = pl
		v.add_child(pl)
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
	menu.add_child(_button("Credits", func() -> void: _credits()))
	menu.add_child(_button("Quit", func() -> void: main.quit_clean()))
	(menu.get_child(0) as Control).grab_focus.call_deferred()  # arrow keys, Enter and a controller work from the start
	toast_lbl = _label("", 17, T_EMBER, font_semi)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.offset_top = -s(80)
	root.add_child(toast_lbl)


var title_lbl: Label
var playtest_lbl: Label
var _title_size := 84


# the title's text (one line, or two at the middle word) and its size, for a width in pixels
func _title_text(w: float) -> String:
	var one := Brand.fit_size(Brand.TITLE, font_goth, s(84), w)
	_title_size = one
	var words := Brand.TITLE.split(" ")
	if one >= s(56) or words.size() < 2:
		return Brand.TITLE
	var best := ""
	var best_sz := one
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		var sz := mini(Brand.fit_size(a, font_goth, s(84), w), Brand.fit_size(b, font_goth, s(84), w))
		if sz > best_sz:
			best_sz = sz
			best = a + "\n" + b
	if best == "":
		return Brand.TITLE
	_title_size = best_sz
	return best


# the playtest switch as the campaign save has it (on unless the player switched it off; the real game defaults it on,
# campaign_ui.gd); null when this build has no campaign
func _playtest_on() -> Variant:
	if main == null or not main.has_campaign():
		return null
	var on := true
	var p := "user://voidsworn_campaign.json"
	if FileAccess.file_exists(p):
		var d = JSON.parse_string(FileAccess.get_file_as_string(p))
		if d is Dictionary and d.get("meta") is Dictionary and d["meta"].get("opts") is Dictionary and d["meta"]["opts"].has("playtestAll"):
			on = bool(d["meta"]["opts"]["playtestAll"])
	return on


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
	sb.bg_color = T_GILT if primary else Color(0.133, 0.176, 0.267, 0.85)
	sb.border_color = T_GILT if primary else T_IRON3
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(s(4))
	sb.content_margin_top = s(9)
	sb.content_margin_bottom = s(9)
	sb.content_margin_left = s(20)   # a short label (Done) keeps clear of its own edges
	sb.content_margin_right = s(20)
	var sh := sb.duplicate() as StyleBoxFlat
	sh.bg_color = Color("#e2bb62") if primary else T_IRON3
	sh.border_color = T_GILT2 if not primary else T_GILT
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
	var fc := Color("#1c1405") if primary else T_BONE
	b.add_theme_color_override("font_color", fc)
	b.add_theme_color_override("font_hover_color", fc)
	b.pressed.connect(cb)
	return b


func toast(t: String) -> void:
	toast_lbl.text = t
	_toast_t = 3.0


func _process(dt: float) -> void:
	var vs := get_viewport().get_visible_rect().size
	if vs != _built_vs and root != null:
		if _resize_t < 0.0:
			_resize_t = 0.12
		_resize_t -= dt
		if _resize_t <= 0.0:
			_resize_t = -1.0
			_rebuild()
	if _toast_t > 0.0:
		_toast_t -= dt
		toast_lbl.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)


# ---------------------------------------------------------------- settings (the game's options menu)

func _settings() -> void:
	if settings_panel != null:
		settings_panel.queue_free()
	var S: Dictionary = main.settings
	# the title dims hard behind the panel (a modal over the menu, not a window into it), and the panel itself is opaque
	if settings_dim == null:
		settings_dim = ColorRect.new()
		settings_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		settings_dim.color = Color(0.016, 0.024, 0.043, 0.93)
		settings_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(settings_dim)
	settings_panel = PanelContainer.new()
	var g := StyleBoxFlat.new()
	g.bg_color = Color(0.047, 0.07, 0.12, 1.0)
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
	v.add_child(_label("Settings", 24, T_GILT, font_goth))
	# the rows scroll when the panel would be taller than the window at the larger UI scales, while the title and Done stay put
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", s(10))
	rows.custom_minimum_size = Vector2(s(460), 0)
	sc.add_child(rows)
	rows.add_child(_toggle("Sound", "sound"))
	rows.add_child(_slider("Volume", "volume", 0.0, 1.0))
	rows.add_child(_toggle("Music", "music"))
	rows.add_child(_slider("Music volume", "music_volume", 0.0, 1.0))
	rows.add_child(_choice("Speed", "speed", [[1.0, "Normal"], [0.45, "Fast"]]))
	rows.add_child(_choice("Movement", "movement", [["cinematic", "Cinematic"], ["brisk", "Brisk"]]))
	rows.add_child(_choice("Enemy AI", "ai", [["veteran", "Veteran"], ["standard", "Standard"]]))
	rows.add_child(_choice("UI scale", "ui_scale", [[0.9, "Small"], [1.0, "Normal"], [1.15, "Large"], [1.3, "Larger"]]))
	rows.add_child(_toggle("Reduce motion", "reduce_motion"))
	rows.add_child(_toggle("Reduce flashing", "reduce_flashing"))
	rows.add_child(_choice("Screen shake", "shake", [[1.0, "Full"], [0.5, "Reduced"], [0.0, "Off"]]))
	rows.add_child(_toggle("Follow enemy activations", "follow"))
	rows.add_child(_choice("Cut-ins", "cine", [["key", "Key moments"], ["all", "Every attack"], ["off", "Off"]]))
	rows.add_child(_toggle("Teaching tips", "tips"))
	rows.add_child(_toggle("Full screen", "fullscreen"))
	rows.add_child(_choice("Graphics", "quality", [["max", "Max"], ["high", "High"], ["low", "Low"]]))
	rows.add_child(_toggle("Temporal AA (smoother edges, softer motion)", "taa"))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_button("Done", func() -> void:
		main.save_settings()
		settings_panel.queue_free()
		settings_panel = null
		if settings_dim != null:
			settings_dim.queue_free()
			settings_dim = null
		_focus_first(menu), true))
	v.add_child(row)
	var vs := get_viewport().get_visible_rect().size
	sc.custom_minimum_size = Vector2(s(460), minf(rows.get_combined_minimum_size().y, vs.y - s(150)))
	_focus_first(settings_panel)


# ---------------------------------------------------------------- credits (the game, and every music track's attribution)

var credits_panel: PanelContainer


# a modal like Settings: a scrolling list built from godot/music/music.json (each track's credit, the same lines as
# godot/music/CREDITS.md; the CC BY tracks need this visible attribution), then Done. Esc or Done closes it.
func _credits() -> void:
	if credits_panel != null and is_instance_valid(credits_panel):
		credits_panel.queue_free()
	if settings_dim == null:
		settings_dim = ColorRect.new()
		settings_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		settings_dim.color = Color(0.016, 0.024, 0.043, 0.93)
		settings_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(settings_dim)
	var vs := get_viewport().get_visible_rect().size
	credits_panel = PanelContainer.new()
	var g := StyleBoxFlat.new()
	g.bg_color = Color(0.047, 0.07, 0.12, 1.0)
	g.border_color = Color(0.816, 0.651, 0.294, 0.3)
	g.set_border_width_all(1)
	g.set_corner_radius_all(s(8))
	g.content_margin_left = s(28)
	g.content_margin_right = s(28)
	g.content_margin_top = s(20)
	g.content_margin_bottom = s(20)
	credits_panel.add_theme_stylebox_override("panel", g)
	credits_panel.set_anchors_preset(Control.PRESET_CENTER)
	credits_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	credits_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(credits_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(10))
	credits_panel.add_child(v)
	v.add_child(_label("Credits", 24, T_GILT, font_goth))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(minf(float(s(760)), vs.x * 0.8), minf(float(s(560)), vs.y * 0.62))
	sc.focus_mode = Control.FOCUS_ALL   # arrow keys and a controller scroll the list
	v.add_child(sc)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("normal_font", font)
	t.add_theme_font_override("bold_font", font_semi)
	t.add_theme_font_size_override("normal_font_size", s(16))
	t.add_theme_font_size_override("bold_font_size", s(16))
	t.add_theme_color_override("default_color", T_BONE2)
	t.text = credits_bbcode()
	sc.add_child(t)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_button("Done", func() -> void: _close_credits(), true))
	v.add_child(row)
	(row.get_child(0) as Control).grab_focus.call_deferred()


func _close_credits() -> void:
	if credits_panel != null and is_instance_valid(credits_panel):
		credits_panel.queue_free()
	credits_panel = null
	if settings_dim != null and (settings_panel == null or not is_instance_valid(settings_panel)):
		settings_dim.queue_free()
		settings_dim = null
	_focus_first(menu)


func _unhandled_input(e: InputEvent) -> void:
	if credits_panel != null and is_instance_valid(credits_panel) and e.is_action_pressed("ui_cancel"):
		_close_credits()
		get_viewport().set_input_as_handled()


# the credits text: the game, then every music track from music.json (title, author, licence, the attribution line)
func credits_bbcode() -> String:
	var out := "[b][color=#d0a64b]%s[/color][/b]\nA game by Ryan Bailey. Made with the Godot Engine (MIT licence, godotengine.org).\nFonts: Michroma, Oxanium and Barlow Semi Condensed (SIL Open Font Licence).\n\n[b][color=#d0a64b]Music[/color][/b]\nEvery track comes from OpenGameArt.org. The game plays edited versions (cut, looped, levelled, re-encoded).\n" % Brand.TITLE
	var p := "res://music/music.json"
	var d = JSON.parse_string(FileAccess.get_file_as_string(p)) if FileAccess.file_exists(p) else null
	if not (d is Dictionary) or not (d.get("tracks") is Dictionary):
		return out + "\n(The music list is missing from this build.)"
	var seen := {}
	for id in d["tracks"]:
		var c = d["tracks"][id].get("credit")
		if not (c is Dictionary):
			continue
		var key := str(c.get("title", "")) + "|" + str(c.get("author", ""))
		if seen.has(key):
			continue
		seen[key] = true
		var line := "\n[b][color=#e6dcc4]%s[/color][/b] by %s  [color=#7d7768](%s)[/color]" % [str(c.get("title", "")), str(c.get("author", "")), str(c.get("licence", ""))]
		var at := str(c.get("attribution", ""))
		if at != "":
			line += "\n[font_size=%d]%s[/font_size]" % [s(14), at.replace("[", "(").replace("]", ")")]
		out += line + "\n"
	return out


func _focus_first(n: Node) -> void:
	if n == null:
		return
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).visible and not (b as Button).disabled:
			(b as Button).grab_focus.call_deferred()
			return


func _row(t: String) -> HBoxContainer:
	var r := HBoxContainer.new()
	var l := _label(t, 18, T_BONE, font)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_child(l)
	return r


func _toggle(t: String, key: String) -> Control:
	var r := _row(t)
	if key == "tips": main.settings["tips"] = not preload("res://ui/campaign/campaign_tips.gd").is_off()
	var b: Button
	if not main.settings.has(key):
		main.settings[key] = true
	b = _button("On" if main.settings[key] else "Off", func() -> void:
		main.settings[key] = not bool(main.settings[key])
		if key == "tips": preload("res://ui/campaign/campaign_tips.gd").set_off(not main.settings[key])
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
		main.save_settings()
		if key == "ui_scale":
			_rebuild())
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
var _revealed := false
var _reveal_tw: Tween


func _rebuild() -> void:
	var had_settings := settings_panel != null and is_instance_valid(settings_panel)
	var had_credits := credits_panel != null and is_instance_valid(credits_panel)
	credits_panel = null
	var shade_a := _shade.color.a if _shade != null else 0.55
	var bg_a := _bg.modulate.a if _bg != null else 1.0
	if _revealed:   # the showcase is (or is fading) in: finish the fade on the new parts
		if _reveal_tw != null and _reveal_tw.is_valid():
			_reveal_tw.kill()
		shade_a = 0.42
		bg_a = 0.0
	remove_child(root)
	root.queue_free()
	settings_panel = null
	settings_dim = null
	_build()
	_bg.modulate.a = bg_a
	_shade.color.a = shade_a
	if had_settings:
		_settings()
	if had_credits:
		_credits()
	print("[title] rebuilt for %d x %d (scale %.3f, title size %d)" % [int(_built_vs.x), int(_built_vs.y), k, _title_size])
	_report.call_deferred()


# for screenshot jobs: where the title, the playtest line and the menu sit, and whether they fit the window
func _report() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if root == null or not is_instance_valid(title_lbl):
		return
	var vs := get_viewport().get_visible_rect().size
	var scr := Rect2(Vector2.ZERO, vs)
	var tr := title_lbl.get_global_rect()
	var tw := font_goth.get_multiline_string_size(title_lbl.text, HORIZONTAL_ALIGNMENT_CENTER, -1, _title_size).x
	var ok := tw <= vs.x and scr.encloses(tr)
	var line := "[title-layout] window %dx%d title %dpx text %d wide, %s" % [int(vs.x), int(vs.y), _title_size, int(tw), "fits" if ok else "DOES NOT FIT"]
	if playtest_lbl != null:
		var pr := playtest_lbl.get_global_rect()
		var pok := scr.encloses(pr) and playtest_lbl.is_visible_in_tree()
		ok = ok and pok
		line += ", playtest line %s" % ("on screen" if pok else "OFF SCREEN")
	var mr := menu.get_global_rect()
	var mok := scr.encloses(mr)
	ok = ok and mok
	line += ", menu %s (bottom %d)" % ["on screen" if mok else "OFF SCREEN", int(mr.end.y)]
	var fo := get_viewport().gui_get_focus_owner()
	var nfocus := 0
	for b in menu.get_children():
		if b is Button and (b as Button).focus_mode == Control.FOCUS_ALL:
			nfocus += 1
	line += ", %d of %d menu buttons take keyboard focus, focus on %s" % [nfocus, menu.get_child_count(), ("\"" + (fo as Button).text + "\"") if fo is Button else "nothing"]
	ok = ok and nfocus == menu.get_child_count() and fo != null
	print(line + (" PASS" if ok else " FAIL"))


func reveal_showcase() -> void:
	if _bg == null or not is_instance_valid(_bg):
		return
	_revealed = true
	_reveal_tw = create_tween().set_parallel(true)
	_reveal_tw.tween_property(_bg, "modulate:a", 0.0, 2.5)
	_reveal_tw.tween_property(_shade, "color:a", 0.42, 2.5)
