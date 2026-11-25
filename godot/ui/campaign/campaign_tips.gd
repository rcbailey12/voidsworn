extends Node
# Shared teaching cards and profile preferences. The battle and campaign use one file and one off switch.
const HUD_SCRIPT := "res://ui/battle/hud.gd"   # issue 1518: loaded when a tip is shown, so the title's Settings (is_off) loads no battle HUD
const OPTS := "user://battle_opts.json"
const ACTION_IDS := ["select", "target", "fired", "close"]
const CARDS := [
	["c_map", "The sector map", "This is the sector map. Pick a stop on a connected lane and work toward the boss at the end. Stops are fights, events, rest stops, and shipyards. There is at least one elite fight on a route you can choose: harder enemies, better rewards. You cannot visit every stop, so choose."],
	["c_clock", "The Nemesis clock", "Winning fights and some choices fill the Nemesis clock. A full clock can bring your one meeting for this sector forward. It does not add another meeting."],
	["c_reward", "Rewards", "Winning pays credits and can offer protocols or refit modules. Sometimes you can claim a captured ship. If it would put you over your command point limit, choose Strip for parts or Ransom for credits. A protocol reroll costs credits."],
	["c_shipyard", "Repair and refit", "Spend credits here to repair hull damage, upgrade ships or buy new ones. Use Refits to swap modules between ships or move them to and from the hold."],
	["c_loss", "The next run", "The run is over, and that is expected. Losing teaches your faction: renown, core progress, and what your admiral learned all carry into the next run. Your ships and credits do not."],
]

var C
var hud: CanvasLayer
var current := ""
var screen := ""
var shown_on_screen := false
var disabled := false
var covered := false        # a slide-over is open over the page: the card waits out of sight
var shipyard_dock: Control

# issue 2172: one cached read for every frame and every caller, and writes only when a value really changed
static var _opts_cache: Dictionary = {}   # not GPU: plain option values (text, numbers, flags)
static var _opts_loaded := false
static var _opts_writes := 0   # test seam: how many times the file was actually rewritten

static func load_opts() -> Dictionary:
	if not _opts_loaded:
		var o = JSON.parse_string(FileAccess.get_file_as_string(OPTS)) if FileAccess.file_exists(OPTS) else {}
		if not (o is Dictionary): o = {}
		if not (o.get("tips") is Dictionary): o["tips"] = {}
		o["tips"]["start"] = true
		o["tips"]["turns"] = true
		_opts_cache = o
		_opts_loaded = true
	return _opts_cache.duplicate(true)

static func save_opts(patch: Dictionary) -> void:
	var o := load_opts()
	for key in patch:
		if key == "tips": o["tips"].merge(patch[key], true)
		else: o[key] = patch[key]
	if o == _opts_cache:
		return
	_opts_cache = o.duplicate(true)
	_opts_writes += 1
	_write_opts(o)

# Write a temporary file, then rename it over the old one, so a crash never leaves a half written profile.
static func _write_opts(o: Dictionary) -> void:
	var tmp := OPTS + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify(o))
	f.flush()
	f.close()
	var err := DirAccess.rename_absolute(tmp, OPTS)
	if err != OK:
		DirAccess.remove_absolute(OPTS)
		err = DirAccess.rename_absolute(tmp, OPTS)
	if err != OK:
		push_warning("battle_opts: could not replace the options file; the new copy is kept at " + tmp)

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
			hud = load(HUD_SCRIPT).new()
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
		hud.tipcard.hide()
		_refresh_placement()

func set_context(is_covered: bool, dock: Control = null) -> void:
	covered = is_covered
	shipyard_dock = dock
	if hud != null and hud.tipcard != null: _refresh_placement()

func _refresh_placement() -> void:
	if current == "c_shipyard" and is_instance_valid(shipyard_dock):
		# Move the live card before the previous shipyard render is freed.
		place_card()
	else:
		_place_later(hud.tipcard)

# The page under the card gets its layout a frame or two after it is built, so the card is placed then.
func _place_later(card: Control) -> void:
	for i in 2: await get_tree().process_frame
	if hud == null or not is_instance_valid(card) or card != hud.tipcard: return
	place_card()

# The shipyard's scroll layout owns its card. Other pages keep the top-right overlay.
func place_card() -> void:
	var card: Control = hud.tipcard if hud != null else null
	if card == null or not is_instance_valid(card): return
	card.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	if current == "c_shipyard" and is_instance_valid(shipyard_dock):
		if card.get_parent() != shipyard_dock:
			card.theme = hud.root.theme
			card.reparent(shipyard_dock, false)
		shipyard_dock.visible = not covered
		card.visible = not covered
		return
	card.reset_size()
	var vs := get_viewport().get_visible_rect().size
	var margin := float(hud.s(24))
	var x := vs.x - margin - card.size.x
	var y := clampf(vs.y - card.size.y - margin, 0.0, float(hud.s(90)))
	card.position = Vector2(x, y).round()
	card.visible = not covered

func _resize() -> void:
	if hud == null: return
	# The HUD frees its old root when it rebuilds. Include its docked card in that cleanup.
	if hud.tipcard != null and hud.tipcard.get_parent() != hud.root:
		hud.tipcard.reparent(hud.root, false)
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
	if is_instance_valid(shipyard_dock): shipyard_dock.hide()
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
