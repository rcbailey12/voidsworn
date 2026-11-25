extends RefCounted
# The orders kit (issue 1217, R333): the one set of front-end pieces every start screen builds from, so a fix made here
# reaches the title, Settings, Credits, the faction and admiral desk, the flagship aspect, Progression, Lineage and Help
# at once. It sits on glass_shell.gd's orders sheet (sheet_name, sheet_body, sheet_medium, sheet_veil, sheet_theme,
# plain_button, focus_ring) and adds only what the screens kept re-making on their own:
#   - one font set: Big Shoulders Display for headings, Barlow for words, Azeret Mono for numbers;
#   - one button set: one ember primary per screen (filled, dark caps), quiet secondary, back, and plain links;
#   - labels that wrap inside their container instead of pushing it wider (wrap_safe);
#   - rows (words left, control right, every control in a column the same width), section heads, cards whose bottoms
#     line up with a spacer before their actions, and an action bar (Back on the left, the primary on the right);
#   - the front-end sound: every kit button plays the ui_* cues (hover and arrow-key focus, press, back, confirm) through
#     the sound node main.gd owns (OrdersKit.sound). Without that node (headless checks) nothing plays.
# Every size is written at the 1080 design height and scaled by k (ui_scale.gd); no text is set below UiScale.MIN_TEXT.

const GS := preload("res://ui/theme/glass_shell.gd")
const UiScale := preload("res://ui/ui_scale.gd")

# The sound node (godot/audio/sfx.gd loaded with only the ui_* cues), set by main.gd. A test may put any node with
# play(name) here.
static var sound: Node = null


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit):
# the sound node reference and the silhouette textures.
static func clear_static() -> void:
	sound = null
	_sil.clear()

# The cue each kind of button plays when pressed; hover and arrow-key focus play HOVER_CUE.
# "reward" (issue 1448): the confirm that takes a reward, relic, promotion perk or bought hull plays the built reward chime
# instead of the plain confirm, so the two never sound together.
const PRESS_CUE := {"primary": "ui_confirm", "quiet": "ui_click", "link": "ui_click", "back": "ui_cancel", "tab": "ui_select", "reward": "ui_reward"}
const HOVER_CUE := "ui_select"
const OPEN_CUE := "ui_panel"

# Every face the game ships, for Credits (title.gd) and the font check (godot/ui/test/front_end_test.gd fails when a .ttf
# under these folders is missing from this list, so Credits can never fall out of date again).
const FONT_FACES := {
	"Michroma": "res://ui/campaign/fonts/Michroma-Regular.ttf",
	"Oxanium": "res://ui/campaign/fonts/Oxanium-Variable.ttf",
	"Big Shoulders Display": "res://ui/theme/fonts/BigShouldersDisplay-VF.ttf",
	"Barlow": "res://ui/theme/fonts/Barlow-Regular.ttf",
	"Barlow Semi Condensed": "res://ui/battle/fonts/BarlowSemiCondensed-Regular.ttf",
	"Azeret Mono": "res://ui/theme/fonts/AzeretMono-VF.ttf",
	"Chakra Petch": "res://ui/theme/fonts/ChakraPetch-Regular.ttf",
}
const FONT_DIRS := ["res://ui/theme/fonts/", "res://ui/battle/fonts/", "res://ui/campaign/fonts/"]


static func px(v: float, k: float) -> int:
	return UiScale.px(v, k)


# ---------------------------------------------------------------- type

static func head_font() -> Font:
	return GS.sheet_name()


static func body_font() -> Font:
	return GS.sheet_body()


static func medium_font() -> Font:
	return GS.sheet_medium()


static func mono_font() -> Font:
	return GS.num()


static func credits_fonts() -> String:
	var names: Array = FONT_FACES.keys()
	return ", ".join(PackedStringArray(names.slice(0, names.size() - 1))) + " and " + str(names[-1])


# The theme a kit screen sets on its root: the orders sheet's theme, kit buttons and the shared focus ring.
static func theme(k: float) -> Theme:
	var th := GS.sheet_theme(k)
	var q := button_boxes(k, "quiet")
	for st in q:
		th.set_stylebox(st, "Button", q[st])
	th.set_stylebox("focus", "Button", GS.focus_ring(k))
	th.set_font("font", "Button", medium_font())
	th.set_font_size("font_size", "Button", px(18, k))
	for st in ["font_color", "font_focus_color"]:
		th.set_color(st, "Button", GS.TEXT2)
	for st in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		th.set_color(st, "Button", GS.TEXT)
	th.set_color("font_disabled_color", "Button", GS.TEXT3)
	th.set_color("font_color", "Label", GS.TEXT)
	th.set_font("font", "Label", body_font())
	th.set_font_size("font_size", "Label", px(18, k))
	return th


# ---------------------------------------------------------------- words

# A label that never pushes its container wider: it wraps by words, and its minimum width is its own one-line width up to
# cap (in pixels). A short label keeps its natural width (a row of short labels lays out as before); a long one starts at
# cap and fills whatever width its container gives it, wrapping inside. Replaces the old "wrap past 30 characters" rule
# (campaign_ui.gd lbl), which let names of 20 to 29 characters widen their cards.
static func wrap_safe(l: Label, f: Font, size_px: int, cap_px: float) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var w := 0.0
	if f != null:
		w = f.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	l.custom_minimum_size.x = ceilf(minf(w, cap_px)) + 1.0
	if w > cap_px:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL


static func label(text: String, size: float, k: float, col := GS.TEXT, f: Font = null, wrap := true, cap := 200.0) -> Label:
	var l := Label.new()
	l.text = text
	var ff := f if f != null else body_font()
	l.add_theme_font_override("font", ff)
	l.add_theme_font_size_override("font_size", px(maxf(size, UiScale.MIN_TEXT), k))
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		wrap_safe(l, ff, px(maxf(size, UiScale.MIN_TEXT), k), px(cap, k))
	return l


# Shrinks a wrapped label's font, never below UiScale.MIN_TEXT, until its longest word fits width_px, then wraps only
# between words. For names in narrow tiles: "Commodore" must never break as "Commodor / e" (issue 1217).
static func fit_words(l: Label, width_px: float, k: float) -> void:
	var ff: Font = l.get_theme_font("font")
	var s := l.get_theme_font_size("font_size")
	var floor_px := px(UiScale.MIN_TEXT, k)
	while s > floor_px:
		var longest := 0.0
		for w in l.text.split(" ", false):
			longest = maxf(longest, ff.get_string_size(w, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x)
		if longest <= width_px: break
		s -= 1
	l.add_theme_font_size_override("font_size", s)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD
	l.custom_minimum_size.x = minf(l.custom_minimum_size.x, width_px)


# A heading: Big Shoulders Display, heavy, in capitals.
static func heading(text: String, size: float, k: float, col := GS.TEXT) -> Label:
	var l := label(text.to_upper(), size, k, col, head_font(), true, 1200.0)
	return l


# A section head: small tracked capitals in the dim text colour over a hairline that runs the width of the column.
static func section(text: String, k: float) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(4, k))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text.to_upper(), 17, k, GS.TEXT3, medium_font(), false)
	var sp := maxi(1, int(round(17.0 * 0.12 * k)))
	var fv := FontVariation.new()
	fv.base_font = medium_font()
	fv.spacing_glyph = sp
	l.add_theme_font_override("font", fv)
	v.add_child(l)
	var r := ColorRect.new()
	r.color = GS.SHEET_HAIR
	r.custom_minimum_size = Vector2(0, maxi(1, px(1, k)))
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(r)
	return v


# ---------------------------------------------------------------- buttons

# role: "primary" (the one ember action on a screen: filled, dark caps), "quiet" (secondary, dark with a hairline),
# "back" (quiet, plays the back cue), "tab" (quiet; a picked tab gets an ember underline from tab_picked).
static func button_boxes(k: float, role := "quiet") -> Dictionary:
	if role == "primary":
		var fb := GS.finish_boxes(k)
		for st in fb:
			var b := (fb[st] as StyleBoxFlat).duplicate() as StyleBoxFlat
			b.content_margin_left = px(22, k)
			b.content_margin_right = px(22, k)
			b.content_margin_top = px(8, k)
			b.content_margin_bottom = px(8, k)
			fb[st] = b
		return fb
	var n := GS.flat(Color(GS.CAREER_INK, 0.92), 16, 6, k)
	n.border_color = GS.SHEET_HAIR
	n.set_border_width_all(maxi(1, px(1, k)))
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(GS.CAREER_PICTURE, 0.97)
	h.border_color = GS.TEXT3
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Color(GS.CAREER_INK, 0.8)
	d.border_color = GS.LINE
	return {"normal": n, "hover": h, "pressed": GS.pressed_box(h), "disabled": d}


static func button(text: String, k: float, role := "quiet", cb := Callable(), size := 18.0) -> Button:
	var b := Button.new()
	b.text = text
	style_button(b, k, role, size)
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


static func style_button(b: Button, k: float, role := "quiet", size := 18.0) -> void:
	var bx := button_boxes(k, role)
	for st in bx:
		b.add_theme_stylebox_override(st, bx[st])
	b.add_theme_stylebox_override("focus", GS.focus_ring(k))
	b.focus_mode = Control.FOCUS_ALL
	GS.button_pointer(b)
	b.add_theme_font_size_override("font_size", px(maxf(size, UiScale.MIN_TEXT), k))
	if role == "primary":
		b.add_theme_font_override("font", GS.action_font(k))
		for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(st, GS.ON_EMBER)
		b.add_theme_color_override("font_disabled_color", GS.TEXT3)
	else:
		b.add_theme_font_override("font", medium_font())
		for st in ["font_color", "font_focus_color"]:
			b.add_theme_color_override(st, GS.TEXT2)
		for st in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(st, GS.TEXT)
		b.add_theme_color_override("font_disabled_color", GS.TEXT3)
	wire_sound(b, role)


# A plain text link (no box): glass_shell's plain_button in the kit's face, with the kit's sound.
static func link(text: String, k: float, cb := Callable(), size := 18.0) -> Button:
	var b := Button.new()
	b.text = text
	GS.plain_button(b, k, maxf(size, UiScale.MIN_TEXT), medium_font())
	b.add_theme_color_override("font_color", GS.TEXT2)
	b.add_theme_color_override("font_hover_color", GS.TEXT)
	b.add_theme_color_override("font_focus_color", GS.TEXT)
	b.add_theme_color_override("font_pressed_color", GS.TEXT)
	b.add_theme_stylebox_override("focus", GS.focus_ring(k))
	wire_sound(b, "link")
	if cb.is_valid():
		b.pressed.connect(cb)
	return b


# The press and hover cues for any button (kit or not). Hover plays when the pointer arrives; focus plays only when the
# player moved it with the arrow keys, Tab or a pad (not when a screen puts the first focus somewhere on opening).
# Issue 1448: any Control with a `pressed` signal and a `disabled` flag counts (the campaign's choice wells,
# ui/campaign/choice_button.gd, are PanelContainers), not only BaseButton.
static func wire_sound(b: Control, role := "quiet") -> void:
	if b.has_meta("kit_sound"):
		b.set_meta("kit_sound", role)
		return
	if not b.has_signal("pressed"):
		return
	b.set_meta("kit_sound", role)
	b.connect("pressed", func() -> void: play(press_cue(str(b.get_meta("kit_sound", "quiet")))))
	b.mouse_entered.connect(func() -> void:
		if not bool(b.get("disabled")):
			play(HOVER_CUE))
	b.focus_entered.connect(func() -> void:
		if _moved_by_keys():
			play(HOVER_CUE))


# The cue a role's press plays (also for a key that does what a button does, so keys and clicks sound the same).
static func press_cue(role: String) -> String:
	return str(PRESS_CUE.get(role, "ui_click"))


# Issue 1448: the one hook that gives a whole screen its sound. Every button (or choice well) that enters the tree under
# root and was not wired by its maker gets the quiet click and hover cues, so a screen that builds plain Button.new()
# rows (the campaign map, shipyard, fleet, rewards, debrief, Career) is never silent again. A maker that wants another
# role calls wire_sound(b, role) itself, before or after adding it; meta "kit_silent" keeps a control out. Safe to call
# twice on one root.
static func watch_sound(root: Node) -> void:
	if root == null or root.has_meta("kit_watch"):
		return
	root.set_meta("kit_watch", true)
	for n in root.find_children("*", "Control", true, false):
		_auto_wire(n)
	var hook := func(n: Node) -> void:
		if is_instance_valid(root) and root.is_ancestor_of(n):
			_auto_wire(n)
	var bind := func() -> void:
		if not root.get_tree().node_added.is_connected(hook):
			root.get_tree().node_added.connect(hook)
	var unbind := func() -> void:
		if root.get_tree() != null and root.get_tree().node_added.is_connected(hook):
			root.get_tree().node_added.disconnect(hook)
	root.tree_entered.connect(bind)
	root.tree_exiting.connect(unbind)
	if root.is_inside_tree():
		bind.call()


static func _auto_wire(n: Node) -> void:
	if not (n is Control) or n.has_meta("kit_sound") or n.has_meta("kit_silent"):
		return
	if n is BaseButton or (n.has_signal("pressed") and "disabled" in n):
		wire_sound(n, "quiet")


static func _moved_by_keys() -> bool:
	for a in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_focus_next", "ui_focus_prev"]:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


static func play(cue: String) -> void:
	if sound != null and is_instance_valid(sound) and sound.has_method("play"):
		sound.play(cue)


# ---------------------------------------------------------------- rows, cards and bars

# One settings row: the words on the left (wrapping, never pushing the row wider), the control on the right at a fixed
# width so every control in the column lines up.
static func row(text: String, control: Control, k: float, control_w: float) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", px(16, k))
	var l := label(text, 18, k, GS.TEXT, body_font(), true, 200.0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(l)
	control.custom_minimum_size.x = control_w
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(control)
	r.set_meta("row_label", text)
	return r


# The width (in pixels) that fits the widest of these button texts, so a column of choice buttons is one width.
static func fit_width(texts: Array, k: float, size := 18.0, f: Font = null) -> float:
	var ff := f if f != null else medium_font()
	var w := 0.0
	for t in texts:
		w = maxf(w, ff.get_string_size(str(t), HORIZONTAL_ALIGNMENT_LEFT, -1, px(size, k)).x)
	return ceilf(w) + px(16, k) * 2 + px(8, k)


# A card: an orders-sheet well (no chamfers, no brackets) at a fixed width. Returns [panel, body, foot]: words go in body,
# actions in foot. A spacer between them keeps the foot at the card's bottom, so in a row of cards (equal_heights) every
# card's actions sit on one line.
static func card(k: float, width: float, picked := false, bar := Color(0, 0, 0, 0)) -> Array:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = px(width, k)
	var sb := GS.well(k, GS.TEXT3 if picked else Color.TRANSPARENT, 14, 12, bar)
	p.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", px(6, k))
	p.add_child(v)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", px(6, k))
	v.add_child(body)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	var foot := VBoxContainer.new()
	foot.add_theme_constant_override("separation", px(6, k))
	v.add_child(foot)
	return [p, body, foot]


# Cards in rows that fill a column: as many columns as fit at the cards' own minimum width, every card one width, every
# row one height (a grid row stretches its cells), so names never widen a card and feet line up (issue 1217 phase 5).
static func card_grid(cards: Array, width: float, k: float, gap := 14.0) -> GridContainer:
	var g := GridContainer.new()
	var gp := float(px(gap, k))
	g.add_theme_constant_override("h_separation", int(gp))
	g.add_theme_constant_override("v_separation", int(gp))
	var min_w := 1.0
	for c in cards:
		if c is Control: min_w = maxf(min_w, (c as Control).custom_minimum_size.x)
	var cols := maxi(1, int(floor((width + gp) / (min_w + gp))))
	cols = mini(cols, maxi(1, cards.size()))
	g.columns = cols
	var w := floorf((width - gp * (cols - 1)) / float(cols))
	for c in cards:
		if c is Control:
			(c as Control).custom_minimum_size.x = w
			(c as Control).size_flags_vertical = Control.SIZE_FILL
			g.add_child(c)
	g.set_meta("card_w", w)
	return g


# A tab in a strip of tabs: quiet, and the picked one lifts with an underline in the accent (the desk's crest tabs, the
# Progression tabs).
static func tab_button(text: String, k: float, picked: bool, accent: Color, cb := Callable()) -> Button:
	var b := button(text, k, "tab", cb, 18)
	if picked:
		var pb: StyleBoxFlat = (button_boxes(k, "quiet")["normal"] as StyleBoxFlat).duplicate()
		pb.bg_color = Color(GS.CAREER_PICTURE, 0.97)
		pb.border_color = accent
		pb.border_width_bottom = maxi(3, px(3, k))
		var hover := pb.duplicate() as StyleBoxFlat
		hover.bg_color = pb.bg_color.lerp(GS.TEXT, 0.08)
		b.add_theme_stylebox_override("normal", pb)
		b.add_theme_stylebox_override("hover", hover)
		b.add_theme_stylebox_override("pressed", GS.pressed_box(hover))
		b.add_theme_color_override("font_color", GS.TEXT)
	return b


# Gives every card in the list the height of the tallest, so their bottoms (and their foot actions) line up.
static func equal_heights(cards: Array) -> void:
	var h := 0.0
	for c in cards:
		if c is Control:
			h = maxf(h, (c as Control).get_combined_minimum_size().y)
	for c in cards:
		if c is Control:
			(c as Control).custom_minimum_size.y = h


# The bottom bar: Back (or anything quiet) on the left, an optional middle, the screen's one primary at the right edge.
static func action_bar(k: float, left: Array, primary: Control = null, mid: Control = null) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", px(12, k))
	for b in left:
		if b != null:
			r.add_child(b)
	var s1 := Control.new()
	s1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_child(s1)
	if mid != null:
		r.add_child(mid)
		var s2 := Control.new()
		s2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.add_child(s2)
	if primary != null:
		r.add_child(primary)
	return r


# A modal backing for Settings and Credits: the orders-sheet well with a hairline edge, opaque under the words.
static func sheet_box(k: float, pad_x := 32.0, pad_y := 24.0) -> StyleBoxFlat:
	var box := GS.flat(Color(GS.CAREER_INK, 0.97), pad_x, pad_y, k)
	box.border_color = GS.SHEET_HAIR
	box.set_border_width_all(maxi(1, px(1, k)))
	return box


# A drawer: an opaque orders-sheet panel on the right edge of parent, full height, w pixels wide, with a hairline on its
# open side. It slides in unless slide is false or the player asked for reduced motion; it plays the open cue. The title's
# Settings and Credits and the desk's Run options use it.
static func drawer(parent: Control, k: float, w: float, slide := true, reduce_motion := false) -> PanelContainer:
	var p := PanelContainer.new()
	var box := sheet_box(k, 40, 36)
	box.bg_color.a = 1.0   # issue 2029 item 2: solid, so no card text or button behind it shows through
	box.set_border_width_all(0)
	box.border_width_left = maxi(1, px(1, k))
	p.add_theme_stylebox_override("panel", box)
	p.anchor_left = 1.0
	p.anchor_right = 1.0
	p.anchor_bottom = 1.0
	p.offset_left = -w
	p.offset_right = 0
	parent.add_child(p)
	# issue 1559 item 22: a drawer is modal for the keyboard (Tab and the arrows cannot reach the screen behind it);
	# focus goes back to what had it when the drawer closes
	load("res://ui/theme/modal_focus.gd").attach(p)
	if slide:
		play(OPEN_CUE)
	if slide and not reduce_motion:
		p.offset_left = 0
		p.offset_right = w
		var tw := p.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "offset_left", -w, 0.22)
		tw.tween_property(p, "offset_right", 0.0, 0.22)
	return p


# A ship's silhouette (godot/ui/battle/icons/ships, the KEEL strip's art) by its hull code; the raw PNG when the project
# has not been imported (cloud checks). null when the hull has none.
static var _sil := {}
static func silhouette(code: String) -> Texture2D:
	if code == "":
		return null
	if not _sil.has(code):
		var path := "res://ui/battle/icons/ships/" + code + ".png"
		var t: Texture2D = null
		if ResourceLoader.exists(path, "Texture2D"):
			t = load(path)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null:
				t = ImageTexture.create_from_image(img)
		_sil[code] = t
	return _sil[code]


# The faction's accent for the front end: its engine colour from fx/faction_looks.json (issue 1205's one source), in
# screen space. Used small (an underline, a card's edge bar, a rule), never for words (RULEBOOK 9.6).
static func faction_accent(fac: String) -> Color:
	var FL = load("res://fx/faction_look.gd")
	if FL == null or not FL.has(fac):
		return GS.MAP_EMBER
	var c: Color = FL.engine(fac)
	return Color(c.linear_to_srgb(), 1.0)
