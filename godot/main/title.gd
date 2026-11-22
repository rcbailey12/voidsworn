extends CanvasLayer
# The title screen (campaign_meta.js titleScreen), Settings and Credits.

const HUD := preload("res://ui/battle/hud.gd")
const Brand := preload("res://ui/battle/brand.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const GS := preload("res://ui/theme/glass_shell.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")   # issue 1217: the shared front-end kit (fonts, buttons, rows, sound)

const T_GILT := Color("#d0a64b")  # The title wordmark keeps its original gold.

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
	font = Kit.body_font()        # the kit's one font set (issue 1217); the wordmark keeps its own display face
	font_semi = Kit.medium_font()
	font_goth = Brand.display()  # the sci-fi display face (lore round 5); the blackletter is retired
	_build()
	_report.call_deferred()
	# screenshot jobs: --title-open credits opens the Credits screen (main.gd opens Settings for --title-open settings)
	if main != null and "args" in main and main.args.has("title-rebuild-test"):   # the rebuild a window resize triggers
		get_tree().create_timer(1.0).timeout.connect(set.bind("_built_vs", Vector2.ONE))   # issue 1482: a bound method, dropped with the title
	if main != null and "args" in main and str(main.args.get("title-open", "")) == "credits":
		get_tree().create_timer(1.5).timeout.connect(_credits)   # issue 1482: a bound method, dropped with the title


# UI pass (Nov 1): the title is built for the window it is in, and built again when the window changes size (the game
# starts maximised and capture jobs or Full screen resize it a moment later; the title used to keep the first size, so
# at 1920x1080 a 4K-sized title ran off both edges and the menu off the bottom)
var _built_vs := Vector2.ZERO
var _resize_t := -1.0


# Phase 2 (issue 1217): the words sit in one column on a smooth left veil (glass_shell sheet_veil) and the showcase battle
# keeps the rest of the screen. One ember action (Continue run when a save exists, else New run), then quiet links in two
# groups, the playtest note in the bottom corner. Settings and Credits open as drawers from the right edge over a light dim,
# so the menu and the battle stay in view.
const SHADE_SKY := 0.30      # the even dim over the sky picture while the battle loads
const SHADE_SHOWN := 0.10    # once the battle is in: the veil carries the words, the battle stays bright
var _veil: TextureRect

func _build() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_vs = vs
	k = UiScale.k_for(vs)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = Kit.theme(k)
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
	shade.color = Color(GS.HALO, SHADE_SKY)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	_bg = bg
	_shade = shade
	# the veil: near black under the column, clear by about 60% of the window
	var vw := vs.x
	var veil_w := clampf(vw * 0.62, float(s(900)), vw)
	_veil = TextureRect.new()
	_veil.texture = GS.sheet_veil()
	_veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_veil.stretch_mode = TextureRect.STRETCH_SCALE
	_veil.anchor_bottom = 1.0
	_veil.offset_right = veil_w
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_veil)
	var margin := float(s(104))
	var col_w := minf(float(s(620)), vw - margin * 2.0)
	var v := VBoxContainer.new()
	v.anchor_top = 0.46
	v.anchor_bottom = 0.46
	v.offset_left = margin
	v.offset_right = margin + col_w
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", s(14))
	root.add_child(v)
	# the game's name (brand.gd TITLE, the one place to rename it), in its gold, on one or two lines fitted to the column
	var h := _label(Brand.TITLE, 84, T_GILT, font_goth)
	h.text = _title_text(col_w)
	h.add_theme_font_size_override("font_size", _title_size)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h.add_theme_constant_override("line_spacing", -int(round(_title_size * 0.22)))   # two lines read as one name
	title_lbl = h
	v.add_child(h)
	var rule := ColorRect.new()
	rule.color = GS.MAP_EMBER
	rule.custom_minimum_size = Vector2(s(96), maxi(2, s(3)))
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule)
	var sub := Kit.label(Brand.TAGLINE, 20, k, GS.TEXT2, null, true, col_w / k)
	sub.custom_minimum_size.x = col_w
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size.y = s(6)
	v.add_child(gap)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", s(4))
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(menu)
	var camp: bool = main.has_campaign()
	var saved := camp and _campaign_has_save()
	var first: Button
	if saved:
		first = _button("Continue run", func() -> void: main.new_run({"continue": true}), true)
	else:
		first = _button("New run", func() -> void: main.new_run({}), true)
	first.custom_minimum_size = Vector2(s(340), s(56))
	first.alignment = HORIZONTAL_ALIGNMENT_LEFT
	menu.add_child(first)
	_menu_gap(10)
	if saved:
		_menu_link("New run", func() -> void: main.new_run({}))
	_menu_link("Quick battle", func() -> void: main.quick_battle())
	if camp:
		_menu_link("Progression", func() -> void: main.new_run({"screen": "legacy"}))
	if ResourceLoader.exists("res://story/story.gd"):   # story hook: the Career screen (godot/story/README.md)
		_menu_link("Career", func() -> void: load("res://story/story.gd").open_standalone(self))
	if camp:
		_menu_link("How to play", func() -> void: main.new_run({"screen": "help"}))
	_menu_gap(10)
	_menu_link("Settings", func() -> void: _settings())
	_menu_link("Credits", func() -> void: _credits())
	_menu_link("Quit", func() -> void: main.quit_clean(), "back")
	first.grab_focus.call_deferred()  # arrow keys, Enter and a controller work from the start
	# The playtest notice (R1, Nov 1) reports whether every admiral, hull and variant is unlocked: a quiet line in the corner.
	var pt := _playtest_on()
	if pt != null:
		var pl := Kit.label("Playtest: everything unlocked (all admirals, carriers, battleships and hull variants)" if pt else "Playtest unlocks are off: unlock admirals and hulls with renown", 17, k, GS.TEXT3, null, true, col_w / k)
		pl.custom_minimum_size.x = col_w
		pl.anchor_top = 1.0
		pl.anchor_bottom = 1.0
		pl.offset_left = margin
		pl.offset_right = margin + col_w
		pl.grow_vertical = Control.GROW_DIRECTION_BEGIN
		pl.offset_top = -s(28)
		pl.offset_bottom = -s(28)
		playtest_lbl = pl
		root.add_child(pl)
	# the toast sits a fixed distance above the bottom edge and grows upwards when it wraps (issue 1217: it used to grow
	# down off the screen)
	toast_lbl = _label("", 17, GS.TEXT, font_semi)
	toast_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_lbl.custom_minimum_size = Vector2(minf(vs.x * 0.8, float(s(900))), 0)
	toast_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	toast_lbl.offset_left = -toast_lbl.custom_minimum_size.x * 0.5
	toast_lbl.offset_right = toast_lbl.custom_minimum_size.x * 0.5
	toast_lbl.offset_top = -s(96)
	toast_lbl.offset_bottom = -s(96)
	root.add_child(toast_lbl)


func _menu_link(t: String, cb: Callable, role := "link") -> Button:
	var b := Kit.link(t, k, cb, 20)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(s(340), s(33))
	if role == "back":
		Kit.wire_sound(b, "back")
	menu.add_child(b)
	return b


func _menu_gap(h: float) -> void:
	var g := Control.new()
	g.custom_minimum_size.y = s(h)
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(g)


var title_lbl: Label
var playtest_lbl: Label
var _title_size := 84


# the title's text (one line, or two at the middle word) and its size, for a width in pixels
const TITLE_MAX := 76   # the wordmark's largest size at 1080 in the left column
func _title_text(w: float) -> String:
	var one := Brand.fit_size(Brand.TITLE, font_goth, s(TITLE_MAX), w)
	_title_size = one
	var words := Brand.TITLE.split(" ")
	if one >= s(56) or words.size() < 2:
		return Brand.TITLE
	var best := ""
	var best_sz := one
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		var sz := mini(Brand.fit_size(a, font_goth, s(TITLE_MAX), w), Brand.fit_size(b, font_goth, s(TITLE_MAX), w))
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


# every title and settings button comes from the kit: one ember primary, quiet secondaries, the shared focus ring (WCAG
# 2.4.7), keyboard and controller focus (WCAG 2.1.1) and the front-end sound
func _button(t: String, cb := Callable(), primary := false, role := "") -> Button:
	var b := Kit.button(t, k, role if role != "" else ("primary" if primary else "quiet"), cb, 19)
	b.custom_minimum_size.y = s(46) if primary else 0
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

func _dialog_box() -> StyleBoxFlat:
	return Kit.sheet_box(k)


# The settings, in four sections on two columns so the whole panel fits the window at every UI scale without scrolling
# (Larger at 1080 leaves 831 design pixels; issue 1217). Every control sits in one right-hand column of one width; long
# names wrap. Esc or Done saves and closes. Changing the UI scale rebuilds the panel and keeps focus on that row.
const SETTINGS_LAYOUT := [   # [section, column, rows]
	["Sound and music", 0, [["toggle", "Sound", "sound"], ["slider", "Volume", "volume"], ["toggle", "Music", "music"], ["slider", "Music volume", "music_volume"]]],
	["Display", 0, [["choice", "UI scale", "ui_scale"], ["toggle", "Full screen", "fullscreen"], ["choice", "Graphics", "quality"], ["toggle", "Temporal AA (smoother edges, softer motion)", "taa"], ["toggle", "Nebula wakes (ships stir the clouds)", "nebula_wake_on"], ["choice", "Render scale", "render_scale"], ["choice", "Frame cap", "fps_cap"], ["toggle", "V-Sync", "vsync"]]],
	["Battle", 1, [["choice", "Speed", "speed"], ["choice", "Movement", "movement"], ["choice", "Enemy AI", "ai"], ["toggle", "Follow enemy activations", "follow"], ["choice", "Cut-ins", "cine"], ["toggle", "Teaching tips", "tips"]]],
	["Comfort", 1, [["toggle", "Reduce motion", "reduce_motion"], ["toggle", "Reduce flashing", "reduce_flashing"], ["choice", "Screen shake", "shake"]]],
]
const SETTINGS_CHOICES := {
	"speed": [[1.0, "Normal"], [0.45, "Fast"]],
	"movement": [["cinematic", "Cinematic"], ["brisk", "Brisk"]],
	"ai": [["veteran", "Veteran"], ["standard", "Standard"]],
	"ui_scale": [[0.9, "Small"], [1.0, "Normal"], [1.15, "Large"], [1.3, "Larger"]],
	"shake": [[1.0, "Full"], [0.5, "Reduced"], [0.0, "Off"]],
	"cine": [["key", "Key moments"], ["all", "Every attack"], ["off", "Off"]],
	"quality": [["max", "Max"], ["high", "High"], ["low", "Low"]],
	# issue 1437: performance options, today's game first (full scale, no cap)
	"render_scale": [[1.0, "100%"], [0.85, "85%"], [0.7, "70%"]],
	"fps_cap": [[0.0, "Off"], [60.0, "60"], [120.0, "120"], [144.0, "144"]],
}
var _settings_focus := ""   # the setting whose control takes focus when the panel is rebuilt (the UI scale row)
var _ctrl_w := 0.0


# Settings and Credits are drawers (phase 2): an opaque sheet on the right edge, full height, over a light dim, so the menu
# and the battle stay in view. A click on the dim closes the drawer like Esc. It slides in unless Reduce motion is on.
const DIM_A := 0.45

func _ensure_dim() -> void:
	if settings_dim == null:
		settings_dim = ColorRect.new()
		settings_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		settings_dim.color = Color(GS.HALO, DIM_A)
		settings_dim.mouse_filter = Control.MOUSE_FILTER_STOP
		settings_dim.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				if credits_panel != null and is_instance_valid(credits_panel): _close_credits()
				elif settings_panel != null and is_instance_valid(settings_panel): _close_settings())
		root.add_child(settings_dim)


func _drawer(w: float, slide := true) -> PanelContainer:
	return Kit.drawer(root, k, w, slide, bool(main.settings.get("reduce_motion", false)))


func _settings() -> void:
	if settings_panel != null:
		settings_panel.queue_free()
	# the title dims hard behind the panel (a modal over the menu, not a window into it), and the panel itself is opaque
	_ensure_dim()
	var texts: Array = ["On", "Off"]
	for key in SETTINGS_CHOICES:
		for o in SETTINGS_CHOICES[key]:
			texts.append(o[1])
	_ctrl_w = maxf(Kit.fit_width(texts, k, 19), float(s(150)))
	var vs := get_viewport().get_visible_rect().size
	var dw := minf(float(s(1080)), vs.x - float(s(24)))
	settings_panel = _drawer(dw, _settings_focus == "")   # a rebuild for a new UI scale does not slide in again
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(18))
	settings_panel.add_child(v)
	v.add_child(Kit.heading("Settings", 34, k))
	# the columns scroll only if a window's shape leaves no room (a very narrow or very short window); the heading and
	# Done stay put
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", s(48))
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(cols)
	var two := dw >= float(s(1000))   # a narrow window stacks the sections in one column
	var col_a := _settings_column()
	cols.add_child(col_a)
	var col_b := col_a
	if two:
		col_b = _settings_column()
		cols.add_child(col_b)
	for i in SETTINGS_LAYOUT.size():
		var sec: Array = SETTINGS_LAYOUT[i]
		var col := col_a if int(sec[1]) == 0 else col_b
		if i > 0 and col.get_child_count() > 0:
			var gap := Control.new()
			gap.custom_minimum_size.y = s(8)
			col.add_child(gap)
		col.add_child(Kit.section(sec[0], k))
		for item in sec[2]:
			match str(item[0]):
				"toggle": col.add_child(_toggle(item[1], item[2]))
				"slider": col.add_child(_slider(item[1], item[2], 0.0, 1.0))
				"choice": col.add_child(_choice(item[1], item[2], SETTINGS_CHOICES[item[2]]))
	var done := _button("Done", func() -> void: _close_settings(), true)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fill)
	v.add_child(Kit.action_bar(k, [], done))
	sc.custom_minimum_size = Vector2(0, minf(cols.get_combined_minimum_size().y, vs.y - s(190)))
	_fit_settings.call_deferred(sc, cols)
	if _settings_focus != "":
		for c in settings_panel.find_children("*", "Control", true, false):
			if str(c.get_meta("setting_key", "")) == _settings_focus:
				(c as Control).grab_focus.call_deferred()
				break
		_settings_focus = ""
	else:
		_focus_first(settings_panel)


func _settings_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", s(8))
	col.custom_minimum_size.x = s(440)
	col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return col


# after layout (wrapped names know their height only then): the scroll area is exactly as tall as the columns, or the
# window's room if that is less
func _fit_settings(sc: ScrollContainer, cols: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(sc) or not is_instance_valid(cols):
		return
	var vs := get_viewport().get_visible_rect().size
	sc.custom_minimum_size.y = minf(cols.get_combined_minimum_size().y, vs.y - s(190))


func _close_settings() -> void:
	if settings_panel == null or not is_instance_valid(settings_panel):
		return
	main.save_settings()
	settings_panel.queue_free()
	settings_panel = null
	if settings_dim != null:
		settings_dim.queue_free()
		settings_dim = null
	_focus_first(menu)


# ---------------------------------------------------------------- credits (the game, and every music track's attribution)

var credits_panel: PanelContainer


# a modal like Settings: a scrolling list built from godot/music/music.json (each track's credit, the same lines as
# godot/music/CREDITS.md; the CC BY tracks need this visible attribution), then Done. Esc or Done closes it.
func _credits() -> void:
	if credits_panel != null and is_instance_valid(credits_panel):
		credits_panel.queue_free()
	_ensure_dim()
	var vs := get_viewport().get_visible_rect().size
	credits_panel = _drawer(minf(float(s(820)), vs.x - float(s(24))))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", s(18))
	credits_panel.add_child(v)
	v.add_child(Kit.heading("Credits", 34, k))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL   # the list fills the drawer's height and scrolls inside it
	sc.focus_mode = Control.FOCUS_ALL   # arrow keys and a controller scroll the list
	v.add_child(sc)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_override("normal_font", font)
	t.add_theme_font_override("bold_font", font_semi)
	t.add_theme_font_size_override("normal_font_size", s(17))
	t.add_theme_font_size_override("bold_font_size", s(17))
	t.add_theme_color_override("default_color", GS.TEXT2)
	t.text = credits_bbcode()
	sc.add_child(t)
	var done := _button("Done", func() -> void: _close_credits(), true)
	v.add_child(Kit.action_bar(k, [], done))
	done.grab_focus.call_deferred()


func _close_credits() -> void:
	if credits_panel != null and is_instance_valid(credits_panel):
		credits_panel.queue_free()
	credits_panel = null
	if settings_dim != null and (settings_panel == null or not is_instance_valid(settings_panel)):
		settings_dim.queue_free()
		settings_dim = null
	_focus_first(menu)


# Esc (or a pad's back) closes Credits, then Settings (saving them), the same as their Done buttons
func _unhandled_input(e: InputEvent) -> void:
	if not e.is_action_pressed("ui_cancel"):
		return
	if credits_panel != null and is_instance_valid(credits_panel):
		Kit.play("ui_cancel")
		_close_credits()
		get_viewport().set_input_as_handled()
	elif settings_panel != null and is_instance_valid(settings_panel):
		Kit.play("ui_cancel")
		_close_settings()
		get_viewport().set_input_as_handled()


# the credits text: the game, then every music track from music.json (title, author, licence, the attribution line)
func credits_bbcode() -> String:
	var text_hex := GS.TEXT.to_html(false)
	var detail_hex := GS.TEXT2.to_html(false)
	var out := "[b][color=#%s]%s[/color][/b]\nA game by Ryan Bailey. Made with the Godot Engine (MIT licence, godotengine.org).\nFonts: %s (SIL Open Font Licence).\n\n[b][color=#%s]Music[/color][/b]\nEvery track comes from OpenGameArt.org. The game plays edited versions (cut, looped, levelled, re-encoded).\n" % [text_hex, Brand.TITLE, Kit.credits_fonts(), text_hex]
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
		var line := "\n[b][color=#%s]%s[/color][/b] by %s  [color=#%s](%s)[/color]" % [text_hex, str(c.get("title", "")), str(c.get("author", "")), detail_hex, str(c.get("licence", ""))]
		var at := str(c.get("attribution", ""))
		if at != "":
			line += "\n[font_size=%d]%s[/font_size]" % [s(17), at.replace("[", "(").replace("]", ")")]
		out += line + "\n"
	return out


func _focus_first(n: Node) -> void:
	if n == null:
		return
	for b in n.find_children("*", "Button", true, false):
		if (b as Button).visible and not (b as Button).disabled:
			(b as Button).grab_focus.call_deferred()
			return


func _toggle(t: String, key: String) -> Control:
	if key == "tips": main.settings["tips"] = not preload("res://ui/campaign/campaign_tips.gd").is_off()
	if not main.settings.has(key):
		main.settings[key] = true
	var b := _button("On" if main.settings[key] else "Off")
	b.set_meta("setting_key", key)
	b.pressed.connect(func() -> void:
		main.settings[key] = not bool(main.settings[key])
		if key == "tips": preload("res://ui/campaign/campaign_tips.gd").set_off(not main.settings[key])
		b.text = "On" if main.settings[key] else "Off"
		main.save_settings()
		if key == "taa" and main.has_method("restart_showcase"):
			main.restart_showcase())
	return Kit.row(t, b, k, _ctrl_w)


func _choice(t: String, key: String, opts: Array) -> Control:
	if not main.settings.has(key):
		main.settings[key] = opts[0][0]   # a settings file from before this row reads as the list's first value
	var label_of := func() -> String:
		for o in opts:
			if str(o[0]) == str(main.settings[key]):
				return o[1]
		return str(opts[0][1])
	var b := _button(label_of.call())
	b.set_meta("setting_key", key)
	b.pressed.connect(func() -> void:
		var i := 0
		for j in opts.size():
			if str(opts[j][0]) == str(main.settings[key]):
				i = j
		main.settings[key] = opts[(i + 1) % opts.size()][0]
		b.text = label_of.call()
		main.save_settings()
		if key == "quality" and main.has_method("restart_showcase"):
			main.restart_showcase()   # issue 1437: the battle behind the menu takes the new Graphics at once
		if key == "ui_scale":
			_settings_focus = key   # the rebuilt panel puts focus back on this row, not on Sound
			_rebuild())
	return Kit.row(t, b, k, _ctrl_w)


func _slider(t: String, key: String, lo: float, hi: float) -> Control:
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 0.05
	sl.focus_mode = Control.FOCUS_ALL
	sl.set_meta("setting_key", key)
	if not main.settings.has(key):
		main.settings[key] = 0.7
	sl.value = float(main.settings[key])
	sl.custom_minimum_size.y = s(24)
	sl.add_theme_stylebox_override("focus", GS.focus_ring(k))
	# issue 1559 item 23: a drag sets the volume live and saves once when it ends; a key or controller step saves at once
	var dragging := [false]
	sl.drag_started.connect(func() -> void: dragging[0] = true)
	sl.drag_ended.connect(func(_changed: bool) -> void:
		dragging[0] = false
		main.save_settings())
	sl.value_changed.connect(func(x: float) -> void:
		main.settings[key] = x
		if dragging[0]:
			main.apply_volumes()
		else:
			main.save_settings())
	return Kit.row(t, sl, k, _ctrl_w)


# main's decorative battle is ready behind the menu: the sky picture fades out over it, the shade stays for the menu
var _bg: TextureRect
var _shade: ColorRect
var _revealed := false
var _reveal_tw: Tween


func _rebuild() -> void:
	var had_settings := settings_panel != null and is_instance_valid(settings_panel)
	var had_credits := credits_panel != null and is_instance_valid(credits_panel)
	credits_panel = null
	var shade_a := _shade.color.a if _shade != null else SHADE_SKY
	var bg_a := _bg.modulate.a if _bg != null else 1.0
	if _revealed:   # the showcase is (or is fading) in: finish the fade on the new parts
		if _reveal_tw != null and _reveal_tw.is_valid():
			_reveal_tw.kill()
		shade_a = SHADE_SHOWN
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
	var nbuttons := 0
	for b in menu.get_children():
		if b is Button:
			nbuttons += 1
			if (b as Button).focus_mode == Control.FOCUS_ALL:
				nfocus += 1
	line += ", %d of %d menu buttons take keyboard focus, focus on %s" % [nfocus, nbuttons, ("\"" + (fo as Button).text + "\"") if fo is Button else "nothing"]
	ok = ok and nfocus == nbuttons and fo != null
	print(line + (" PASS" if ok else " FAIL"))


# Issue 1437 (review on PR 1607): the showcase was rebuilt for a new Graphics or TAA setting, or removed for Low: the sky
# picture comes back until the new battle is in
func cover_showcase() -> void:
	if _reveal_tw != null and _reveal_tw.is_valid():
		_reveal_tw.kill()
	_revealed = false
	if _bg != null and is_instance_valid(_bg):
		_bg.modulate.a = 1.0
	if _shade != null and is_instance_valid(_shade):
		_shade.color.a = SHADE_SKY


func reveal_showcase() -> void:
	if _bg == null or not is_instance_valid(_bg):
		return
	_revealed = true
	_reveal_tw = create_tween().set_parallel(true)
	_reveal_tw.tween_property(_bg, "modulate:a", 0.0, 2.5)
	_reveal_tw.tween_property(_shade, "color:a", SHADE_SHOWN, 2.5)
