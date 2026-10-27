extends CanvasLayer
# A plain stand-in for the campaign screens until G3's res://ui/campaign/campaign_ui.gd lands: the page title, the facts
# it carries, and one button per act in the browser's order (greyed when the browser greys it). Every screen of a run can
# be clicked through with it. Words for the buttons follow the browser's where known.

const HUD := preload("res://ui/battle/hud.gd")
const WORDS := {"newRunScreen": "New run", "continueRun": "Continue run", "startRun": "Launch the crusade", "enterNode": "Go to", "leaveYard": "Leave the shipyard",
	"backMap": "Back to the map", "backShipyard": "Back to the shipyard", "repairAll": "Repair all", "repair": "Repair", "buyHull": "Buy hull", "buyMod": "Buy module",
	"upgradeMk": "Upgrade", "sellShip": "Sell", "sellConfirm": "Sell it", "equip": "Equip", "unequip": "Unequip", "promote": "Promote", "fleetScreen": "Fleet",
	"fleetFromModal": "Fleet", "closeModal": "Close", "title": "Title screen", "legacy": "Progression", "help": "How to play", "pickAdmiral": "Admiral",
	"pickFaction": "Faction", "pickAspect": "Aspect", "eventChoice": "Choose", "prizeStep": "Decide on the prize ships", "prizeSet": "Set", "prizeConfirm": "Confirm",
	"salvageStep": "Salvage", "takeSalvage": "Take", "rewardNext": "Continue", "takeMod": "Take module", "takeBoon": "Take boon", "takeRelic": "Take relic",
	"takePerk": "Take perk", "c3continue": "Continue", "c3retreat": "Retreat", "c3retreatYes": "Retreat", "c3retreatNo": "Stay", "saveQuit": "Save and quit",
	"abandonRun": "Abandon run", "buyVariant": "Unlock", "progTab": "Tab", "optAlt": "Alternate start", "optCmd": "Alternate Command", "optHeat": "Heat",
	"battle": "Battle", "yardFleet": "Fleet"}

var C
var k := 1.0
var root: Control
var box: VBoxContainer
var font_goth: Font


func bind(campaign) -> void:
	C = campaign
	C.changed.connect(_draw)
	_draw()


func _ready() -> void:
	k = clampf(get_viewport().get_visible_rect().size.y / 1080.0, 0.6, 2.2)
	font_goth = load("res://ui/battle/brand.gd").display()  # the sci-fi display face (lore round 5)
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.07)
	root.add_child(bg)
	var sc := ScrollContainer.new()
	sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.offset_left = 60 * k
	sc.offset_right = -60 * k
	sc.offset_top = 40 * k
	sc.offset_bottom = -40 * k
	root.add_child(sc)
	box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", int(8 * k))
	sc.add_child(box)


func _draw() -> void:
	if box == null or C == null:
		return
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	_screen(C.page, false)
	if C.modal_d != null:
		_screen(C.modal_d, true)
	for t in C.toasts:
		box.add_child(_lbl(str(t), 16, HUD.EMBER))
	C.toasts.clear()


func _screen(s: Dictionary, modal: bool) -> void:
	var h := _lbl(str(s.get("kind", "")).capitalize(), 30 if not modal else 23, HUD.GILT)
	h.add_theme_font_override("font", font_goth)
	box.add_child(h)
	var facts := _facts(s.get("data", {}))
	if facts != "":
		var r := RichTextLabel.new()
		r.bbcode_enabled = false
		r.fit_content = true
		r.text = facts
		r.add_theme_font_size_override("normal_font_size", int(15 * k))
		r.add_theme_color_override("default_color", HUD.BONE2)
		box.add_child(r)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", int(8 * k))
	flow.add_theme_constant_override("v_separation", int(8 * k))
	for a in s.get("acts", []):
		var b := Button.new()
		b.text = str(WORDS.get(a[0], str(a[0]).capitalize())) + ("" if str(a[1]) == "" else ": " + str(a[1]))
		b.disabled = int(a[2]) != 1
		b.add_theme_font_size_override("font_size", int(16 * k))
		var act: String = a[0]
		var arg: String = a[1]
		b.pressed.connect(func() -> void: C.act(act, arg))
		flow.add_child(b)
	box.add_child(flow)
	var line := ColorRect.new()
	line.color = HUD.IRON3
	line.custom_minimum_size = Vector2(0, 1)
	box.add_child(line)


func _facts(d) -> String:
	# a short readable summary of a screen's data: scalars and short lists, one per line
	if not (d is Dictionary):
		return ""
	var out := PackedStringArray()
	for key in d:
		var v = d[key]
		if v is String or v is float or v is int or v is bool:
			out.append("%s: %s" % [str(key), str(v)])
		elif v is Array and v.size() <= 12:
			var parts := PackedStringArray()
			for x in v:
				if x is Dictionary:
					parts.append(str(x.get("name", x.get("n", x.get("id", x.get("type", "?"))))))
				else:
					parts.append(str(x))
			out.append("%s: %s" % [str(key), ", ".join(parts)])
		elif v is Dictionary and v.has("name"):
			out.append("%s: %s" % [str(key), str(v["name"])])
	return "\n".join(out)


func _lbl(t: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", int(size * k))
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
