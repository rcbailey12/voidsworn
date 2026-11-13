extends Node
# Shared teaching cards and profile preferences. The battle and campaign use one file and one off switch.
const HUD = preload("res://ui/battle/hud.gd")
const OPTS := "user://battle_opts.json"
const ACTION_IDS := ["select", "target", "fired", "close"]
const CARDS := [
	["c_map", "The sector map", "This is the sector map. Pick a stop on a connected lane and work toward the boss at the end. Stops are fights, events, rest stops, and shipyards. There is at least one elite fight on a route you can choose: harder enemies, better rewards. You cannot visit every stop, so choose."],
	["c_clock", "The Nemesis clock", "The clock at the top fills when you win fights and make loud choices. When it runs out, the Nemesis catches up and the fights ahead get harder. Side stops pay, but they can fill the clock too."],
	["c_reward", "Rewards", "Winning pays credits, and offers salvage: guns and parts you can fit at a shipyard. Sometimes you can claim a beaten enemy ship instead. If your fleet is full, a claimed ship is scrapped for credits on the spot. Rerolls are not free: when one is offered, it costs credits."],
	["c_shipyard", "Repair and refit", "Here you spend credits to repair hull damage, refit (swap guns and parts between your ships), and buy ships. After a boss fight you also regroup here: repair, upgrade, or buy before the next sector."],
	["c_loss", "The next run", "The run is over, and that is expected. Losing teaches your faction: renown, core progress, and what your admiral learned all carry into the next run. Your ships and credits do not."],
	["c_tree", "Your admiral's skill tree", "Spend experience on your admiral's skill tree between runs. Heat is a difficulty you choose: each point of Heat gives +2 experience to the admiral you fly and +1 to your faction's shared pool, and makes the run harder."],
]

var C
var hud: CanvasLayer
var current := ""
var screen := ""
var shown_on_screen := false
var disabled := false
var covered := false        # a slide-over is open over the page: the card waits out of sight
var keep_clear: Array = []  # controls on the page the card must not sit on

static func load_opts() -> Dictionary:
	var o = JSON.parse_string(FileAccess.get_file_as_string(OPTS)) if FileAccess.file_exists(OPTS) else {}
	if not (o is Dictionary): o = {}
	if not (o.get("tips") is Dictionary): o["tips"] = {}
	o["tips"]["start"] = true
	o["tips"]["turns"] = true
	return o

static func save_opts(patch: Dictionary) -> void:
	var o := load_opts()
	for key in patch:
		if key == "tips": o["tips"].merge(patch[key], true)
		else: o[key] = patch[key]
	var f := FileAccess.open(OPTS, FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(o))

static func is_off() -> bool:
	return bool(load_opts().get("tipsOff", false))

static func set_off(off: bool) -> void:
	save_opts({"tipsOff": off})

func bind(campaign) -> void:
	C = campaign
	var a := OS.get_cmdline_user_args()
	for key in ["--no-tips", "--shots", "--ui-shots", "--f1-trace", "--bot", "--bot-runs", "shots", "mapshots", "bot"]:
		if key in a: disabled = true
	save_opts({}) # Retire start and turns for new and existing profiles, preserving every other preference.

func open_screen(key: String, ids: Array) -> void:
	if key != screen:
		if current != "": _dismiss("screen_left", false)
		screen = key
		shown_on_screen = false
	if disabled or is_off() or shown_on_screen: return
	for id in ids:
		if try_show(str(id)): return

func try_show(id: String, clock_pair := false) -> bool:
	if disabled or is_off() or current != "" or (shown_on_screen and not clock_pair): return false
	if load_opts()["tips"].has(id): return false
	for t in CARDS:
		if t[0] != id: continue
		if hud == null:
			hud = HUD.new()
			add_child(hud)
			hud.layer = 30
			hud.set_process(false)
			hud.action.connect(_action)
			get_viewport().size_changed.connect(_resize)
		current = id
		shown_on_screen = true
		hud.show_tipcard(t[0], t[1], t[2])
		_card_only()
		_log("show", id)
		return true
	return false

func _card_only() -> void:
	for child in hud.root.get_children():
		if child is CanvasItem: child.visible = child == hud.tipcard
	if hud.tipcard != null:
		hud.tipcard.visible = false # shown again by _place, once the page under it has its layout
		_place_later(hud.tipcard)

# The screen tells the card what it must stay off (issue 652): `covered` is true while a slide-over (the Map key, the
# Dossier) is open, and the card waits out of sight until it closes; `clear` lists the controls on the page the card must
# not sit on (the shipyard's repair bar). The campaign screen calls this every time it draws a page.
func set_context(is_covered: bool, clear: Array = []) -> void:
	covered = is_covered
	keep_clear = clear
	if hud != null and hud.tipcard != null: _place_later(hud.tipcard)

# The page under the card gets its layout a frame or two after it is built, so the card is placed then.
func _place_later(card: Control) -> void:
	for i in 2: await get_tree().process_frame
	if hud == null or not is_instance_valid(card) or card != hud.tipcard: return
	place_card()

# Top right under the corner buttons, pushed down below any control it would cover. Hidden while a slide-over is open.
func place_card() -> void:
	var card: Control = hud.tipcard if hud != null else null
	if card == null or not is_instance_valid(card): return
	card.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	card.reset_size()
	var vs := get_viewport().get_visible_rect().size
	var margin := float(hud.s(24))
	var gap := float(hud.s(12))
	var x := vs.x - margin - card.size.x
	var y := float(hud.s(90))
	for pass_n in 6:
		var moved := false
		var r := Rect2(Vector2(x, y), card.size)
		for c in keep_clear:
			if not is_instance_valid(c) or not (c as Control).is_visible_in_tree(): continue
			var cr: Rect2 = (c as Control).get_global_rect()
			if r.intersects(cr):
				y = cr.end.y + gap
				moved = true
				break
		if not moved: break
	y = maxf(0.0, minf(y, vs.y - card.size.y - margin))
	card.position = Vector2(x, y).round()
	card.visible = not covered

func _resize() -> void:
	if hud == null: return
	hud._rebuild()
	_card_only()

func _log(kind: String, id: String, why := "") -> void:
	if C != null:
		C.tel("teaching_tip", {"k": kind, "id": id, "screen": screen, "why": why})
		C.persist_save()

func _dismiss(why: String, retire: bool) -> void:
	var id := current
	if id == "": return
	_log("dismiss", id, why)
	if retire: save_opts({"tips": {id: true}})
	current = ""
	hud.hide_tipcard()

func _action(name: String, _arg) -> void:
	if name == "tip_off":
		_dismiss("off", false)
		set_off(true)
		if C != null: C.set_teaching_tips(false)
	elif name == "tip_ok":
		var id := current
		_dismiss("got_it", true)
		if id == "c_map" and screen.begins_with("map|"): try_show("c_clock", true)

func toggle() -> void:
	set_off(not is_off())
	if C != null: C.set_teaching_tips(not disabled and not is_off())
	if is_off(): _dismiss("off", false)
