extends Control
## One card for both entry points. The LostShipRecord owns all the facts.

const GS = preload("res://ui/theme/glass_shell.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const ModalFocus = preload("res://ui/theme/modal_focus.gd")
const Portraits = preload("res://portraits/portraits.gd")
const Report = preload("res://ui/campaign/after_action_report.gd")
const UiScale = preload("res://ui/ui_scale.gd")


static func open(parent: Control, record: Dictionary, k: float, class_label: Callable, beside_report := false) -> void:
	var card = load("res://ui/campaign/killmail.gd").new()
	card.name = "Killmail"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card._build(record, k, class_label, beside_report)


func _build(record: Dictionary, k: float, class_label: Callable, beside_report: bool) -> void:
	var shade := ColorRect.new()
	shade.color = Color(GS.INK, 0.64)
	shade.mouse_force_pass_scroll_events = false
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(_outside_click)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if beside_report and size.x >= UiScale.px(1100, k):
		center.anchor_left = 0.34
		center.anchor_top = 0.12
	var card := PanelContainer.new()
	card.name = "KillmailCard"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_force_pass_scroll_events = false
	card.add_theme_stylebox_override("panel", GS.tip(k))
	center.add_child(card)
	var column := _column(k, 7)
	card.add_child(column)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", UiScale.px(8, k))
	column.add_child(heading)
	var title := Kit.label("KILLMAIL", 28, k, GS.TEXT, GS.sheet_name(), false)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := Kit.button("Close  Esc", k, "quiet", _close, 17)
	close.name = "CloseKillmail"
	heading.add_child(close)

	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_force_pass_scroll_events = false
	var frame := get_viewport_rect().size
	sc.custom_minimum_size.x = clampf(frame.x - UiScale.px(64, k), UiScale.px(200, k), UiScale.px(396, k))
	column.add_child(sc)
	var body := _column(k, 7)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(body)
	var cap: Dictionary = record["captain"]
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", UiScale.px(12, k))
	body.add_child(identity)
	_add_portrait(identity, str(cap["portrait_id"]), k)
	var words := _column(k, 3)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(words)
	_field(words, "VictimName", str(cap["full_name"]), k, GS.TEXT, 19)
	if not str(cap["callsign"]).is_empty():
		_field(words, "Callsign", str(cap["callsign"]), k, GS.TEXT2)
	_field(words, "VictimShip", _ship(str(record["ship_name"]), str(record["ship_class"]), class_label), k, GS.TEXT)

	_rule(body, k)
	var hazard := str(record["hazard_name"])
	var killer := str(record["killer_ship_name"])
	if not hazard.is_empty():
		_field(body, "Hazard", "Hazard: " + hazard, k)
	elif not killer.is_empty():
		_field(body, "Killer", "Killed by " + _ship(killer, str(record["killer_ship_class"]), class_label), k)
		if not str(record["weapon_name"]).is_empty():
			_field(body, "Weapon", str(record["weapon_name"]), k, GS.TEXT2)
	else:
		_field(body, "Killer", "Killer not recorded", k, GS.TEXT2)
	_field(body, "When", "Round %d  |  Battle %d" % [int(record["round"]), int(record["battle"])], k)
	_field(body, "FinalBlow", "Final blow: %s damage" % Report.figure(record["final_damage"]), k)
	for assist in record["assists"].slice(0, 2):
		var ship := _ship(str(assist["ship_name"]), str(assist["ship_class"]), class_label)
		_field(body, "Assist", "Assist: %s  %s%%" % [ship, Report.figure(100.0 * float(assist["damage_share"]))], k, GS.TEXT2)
	var body_limit := minf(UiScale.px(370, k), frame.y * 0.8 - UiScale.px(70, k))
	var fit := func() -> void:
		sc.custom_minimum_size.y = clampf(body.get_combined_minimum_size().y + UiScale.px(2, k), UiScale.px(237, k), maxf(UiScale.px(237, k), body_limit))
	body.minimum_size_changed.connect(fit)
	fit.call()
	ModalFocus.attach(self, close)


func _add_portrait(parent: HBoxContainer, id: String, k: float) -> void:
	var portrait := TextureRect.new()
	portrait.name = "VictimPortrait"
	portrait.set_meta("portrait_id", id)
	portrait.texture = Portraits.captain_face(id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(UiScale.px(82, k), UiScale.px(92, k))
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if portrait.texture == null:
		portrait.draw.connect(func():
			var w := portrait.size.x
			portrait.draw_rect(Rect2(Vector2.ZERO, portrait.size), GS.INK)
			portrait.draw_circle(Vector2(w * 0.5, w * 0.36), w * 0.15, GS.SHEET_HAIR, true, -1.0, true)
			portrait.draw_circle(Vector2(w * 0.5, w * 0.87), w * 0.31, GS.SHEET_HAIR, true, -1.0, true))
	parent.add_child(portrait)


func _column(k: float, gap: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", UiScale.px(gap, k))
	return column


func _field(parent: VBoxContainer, id: String, text: String, k: float, col := GS.TEXT, font_size := 17) -> void:
	var label := Kit.label(text, font_size, k, col, GS.sheet_body(), true, 112.0)
	label.name = id
	parent.add_child(label, true)


func _rule(parent: VBoxContainer, k: float) -> void:
	parent.add_child(GS.thin_bar(k, 0.0, GS.SHEET_HAIR, 0.0, 1.0, GS.SHEET_HAIR))


func _ship(ship_name: String, ship_class: String, class_label: Callable) -> String:
	return ship_name if ship_class.is_empty() else "%s  /  %s" % [ship_name, class_label.call(ship_class)]


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and ModalFocus.top_panel() == self:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			Kit.play("ui_cancel")
			_close()


func _outside_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		get_viewport().set_input_as_handled()
		Kit.play("ui_cancel")
		_close()


func _close() -> void:
	queue_free()
