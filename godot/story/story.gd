extends Node
# The story layer (R37 step 1, story stream): admiral lines, the flagship's name, titles earned from how you fight, and the
# career profile with records and medals. README.md in this folder is the contract with the campaign (G3) and the game
# shell and battle (G2).
#
# It watches the campaign object (godot/campaign/campaign.gd) through its `changed` and `battle_requested` signals and never
# calls act(), so campaign parity is untouched. The one thing it writes into the campaign is the flagship's name, and only
# when the player renames it (rename_flagship). Everything else lives in its own file (career.gd).

const Career := preload("res://story/career.gd")
const Voice := preload("res://story/battle_voice.gd")
const RENAME_UI := "res://ui/career/rename_dialog.gd"
const CAREER_UI := "res://ui/career/career_screen.gd"

signal medal_earned(id: String, name: String)   # for a toast; the host or UI may connect it
signal title_earned(row: Dictionary)            # at the end of a run, with the history row (title_name, admiral_name ...)

var C = null                    # the campaign
var career = Career.new()
var V: Dictionary = {}          # voices.json
var prompt_rename := true       # offer "name your flagship" once at the start of each run
var _last_B = null              # the last battle B already recorded
var _held_B = null              # the battle B being played
var _awaiting := false          # a campaign battle is being played
var _run_ended_key := ""
var _prompted_key := ""
var _ui_layer: Node = null


var ADM: Dictionary = {}        # admiral id -> {n, fac, doc} (names only, from the campaign tables)
var FAC: Dictionary = {}        # faction id -> {n, glow}
var FACS: Array = []            # the six run factions in order


func _init() -> void:
	var f := FileAccess.open("res://story/data/voices.json", FileAccess.READ)
	if f != null:
		var d = JSON.parse_string(f.get_as_text())
		V = d if d is Dictionary else {}
	# names only, read straight from G3's exported tables so the career screen also works from the title (no campaign)
	var t := FileAccess.open("res://campaign/data/campaign_tables.json", FileAccess.READ)
	if t != null:
		var j = JSON.parse_string(t.get_as_text())
		var T: Dictionary = j.get("tables", {}) if j is Dictionary else {}
		for id in T.get("ADMIRALS", {}):
			var a: Dictionary = T["ADMIRALS"][id]
			ADM[id] = {"n": str(a.get("n", id)), "fac": str(a.get("fac", "voidsworn")), "doc": str(a.get("doc", ""))}
		for id in T.get("FACTIONS", {}):
			FAC[id] = {"n": str(T["FACTIONS"][id].get("n", id)), "glow": str(T["FACTIONS"][id].get("glow", "#d0a64b"))}
		FACS = T.get("RUN_FACTIONS", ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"])


# The career screen from anywhere (the title screen has no campaign): Story.open_standalone(parent).
static func open_standalone(parent: Node) -> Node:
	var s = load("res://story/story.gd").new()
	s.name = "Story"
	parent.add_child(s)
	s.career.persist = true
	s.career.load_profile()
	var scr = s.open_career()
	if scr != null and scr.has_signal("closed"):
		scr.closed.connect(s.queue_free)
	return scr


# host: the node the rename prompt and the career screen go under (campaign_host). persist: write the career file
# (false for bot runs and tests).
func attach(campaign, persist := true) -> void:
	C = campaign
	career.persist = persist
	if persist:
		career.load_profile()
	if not C.changed.is_connected(_on_changed):
		C.changed.connect(_on_changed)
	if not C.battle_requested.is_connected(_on_battle):
		C.battle_requested.connect(_on_battle)


func _on_battle() -> void:
	_awaiting = true
	if C.B is Dictionary and not is_same(C.B, _last_B):
		_held_B = C.B


func _on_changed() -> void:
	if C == null:
		return
	# a campaign battle: hold on to its B while it is up (the campaign drops its own reference inside finishBattle,
	# before the next screen shows), then record it once finishBattle has marked it finished
	if C.B is Dictionary and not is_same(C.B, _held_B) and not is_same(C.B, _last_B):
		_held_B = C.B
	var B = _held_B
	if B is Dictionary and B.get("finished") == true and not is_same(B, _last_B):
		_last_B = B
		_held_B = null
		_awaiting = false
		var run = C.RUN
		var pd: Dictionary = C.page.get("data", {}) if C.page.get("data") is Dictionary else {}
		if run == null and pd.get("run") is Dictionary:
			run = pd["run"]
		if run is Dictionary:
			var o = B.get("over")
			career.record_battle(run, B, "win" if o == "win" else ("loss" if o == "loss" else "retreat"))
	if C.RUN is Dictionary:
		career.note_sector(C.RUN)
	# the run's end screen
	if C.page.get("kind", "") == "end" and C.page.get("data") is Dictionary and C.page["data"].get("run") is Dictionary:
		var run: Dictionary = C.page["data"]["run"]
		var key := Career.run_key(run)
		if key != _run_ended_key:
			_run_ended_key = key
			var row: Dictionary = career.record_run_end(run, bool(C.page["data"].get("victory", false)), admiral_name(str(run.get("admiral", ""))))
			if not row.is_empty():
				title_earned.emit(row)
	for id in career.take_new_medals():
		medal_earned.emit(id, medal_name(id))
	# the first sector intro of a run: offer to name the flagship
	if prompt_rename and C.modal_d is Dictionary and C.modal_d.get("kind", "") == "intro" and C.RUN is Dictionary:
		var k := Career.run_key(C.RUN)
		if k != _prompted_key:
			_prompted_key = k
			open_rename.call_deferred()


# ---------------------------------------------------------------- lines for the campaign's text boxes

func admiral_name(id: String) -> String:
	return str(ADM.get(id, {}).get("n", id))


func admiral_fac(id: String) -> String:
	return str(ADM.get(id, {}).get("fac", "voidsworn"))


func _fill(t: String, run) -> String:
	var flag := ""
	var rival := ""
	if run is Dictionary:
		flag = Career.flagship_name(run)
		var nem = run.get("nem")
		if nem is Dictionary:
			rival = ("%s %s" % [str(nem.get("title", "")), str(nem.get("name", ""))]).strip_edges()
	return t.replace("{flagship}", flag if flag != "" else "the flagship").replace("{rival}", rival if rival != "" else "the enemy commander").replace("{enemy}", "the enemy")


# The admiral's raw line for a moment (pick, sector, start, boss, nemesis, kill_flag, lost, flag_hurt, command, win, loss).
func line(admiral_id: String, moment: String, run = null, seed := 0) -> String:
	var t = V.get("admirals", {}).get(admiral_id, {}).get(moment)
	if t is Array:
		t = t[absi(seed) % t.size()] if t.size() > 0 else null
	return _fill(str(t), run) if t != null else ""


# The same line with its speaker, ready for a text box: Admiral Castellan Vex: "Form the line."
func said(admiral_id: String, moment: String, run = null) -> String:
	var t := line(admiral_id, moment, run)
	return "%s: \"%s\"" % [admiral_name(admiral_id), t] if t != "" else ""


# One line for the campaign screen the UI is drawing now ("" when none):
#   page "admiral"          the picked admiral's pick line
#   modal "intro"/"sector"  your admiral's sector line
#   page "end"              your admiral's win or loss line, then the title earned this run
func campaign_line() -> String:
	if C == null:
		return ""
	if C.modal_d is Dictionary and C.modal_d.get("kind", "") in ["intro", "sector"] and C.RUN is Dictionary:
		return said(str(C.RUN.get("admiral", "")), "sector", C.RUN)
	var kind: String = str(C.page.get("kind", ""))
	if kind == "admiral":
		return said(str(C.picked_admiral), "pick")
	if kind == "end" and C.page.get("data") is Dictionary and C.page["data"].get("run") is Dictionary:
		var run: Dictionary = C.page["data"]["run"]
		var s := said(str(run.get("admiral", "")), "win" if bool(C.page["data"].get("victory", false)) else "loss", run)
		var t := earned_title_text(run)
		return s + ("\n" + t if t != "" else "")
	return ""


# "Title earned: Admiral Castellan Vex the Breaker (4 or more rams and boarding actions in the run)."
func earned_title_text(run: Dictionary) -> String:
	var h: Array = career.P.get("history", [])
	if h.is_empty():
		return ""
	var row: Dictionary = h[h.size() - 1]
	if str(row.get("admiral", "")) != str(run.get("admiral", "")):
		return ""
	var rule := ""
	for t in career.titles_data.get("titles", []):
		if str(t["id"]) == str(row.get("title", "")):
			rule = str(t.get("rule", ""))
	return "Title earned: %s %s%s" % [admiral_name(str(row["admiral"])), str(row.get("title_name", "")), (" (" + rule.trim_suffix(".") + ").") if rule != "" else "."]


# The admiral's name with their latest earned title, for the map sidebar or the admiral card ("" title when none yet).
func titled_name(admiral_id: String) -> String:
	var a: Dictionary = career.P.get("admirals", {}).get(admiral_id, {})
	var t := str(a.get("last_title", ""))
	var at: String = career.arc_title(admiral_fac(admiral_id))
	return admiral_name(admiral_id) + (" " + career.title_name(t, admiral_fac(admiral_id)) if t != "" else "") + ((", " + at) if at != "" else "")


func medal_name(id: String) -> String:
	for m in career.all_medals():
		if str(m["id"]) == id:
			return str(m["n"])
	return id


# ---------------------------------------------------------------- arc rewards (cosmetic; the unlock's rules are stream B's)

# The flagship paint scheme to draw for a faction (default: the current run's), or {} for the faction's normal colours.
# {id, n, hull, trim, glow, pattern}, colours as hex. For the ship renderer (G2, G4 look, A4 ships): tint the player's
# flagship with it when not empty.
func flagship_paint(fac: String = "") -> Dictionary:
	if fac == "" and C != null and C.RUN is Dictionary:
		fac = str(C.RUN.get("fac", ""))
	return career.flagship_paint(fac)


func set_paint(fac: String, on: bool) -> void:
	career.set_paint(fac, on)


func arc_unlocks() -> Array:
	return career.arc_unlocks()


# ---------------------------------------------------------------- arc beats (plumbing; arc files arrive after approval)

const ArcScript := preload("res://story/arc.gd")


# Everything a card's tokens and conditions read, from the campaign run and the career profile.
func arc_context(run = null) -> Dictionary:
	if run == null and C != null:
		run = C.RUN
	if not (run is Dictionary):
		return {}
	var fac := str(run.get("fac", ""))
	var L: Dictionary = career.P.get("live", {}) if str(career.P.get("live", {}).get("key", "")) == career.run_key(run) else {}
	var best := ""
	var bx := -1.0
	for s in run.get("fleet", []):
		if s is Dictionary and s.get("cap") is Dictionary and float(s["cap"].get("xp", 0)) > bx:
			bx = float(s["cap"].get("xp", 0))
			best = str(s["cap"].get("name", ""))
	var first_lost := str(L.get("first_lost", ""))
	if first_lost == "" and run.get("fallen") is Array and run["fallen"].size() > 0:
		first_lost = str(run["fallen"][0].get("ship", ""))
	var fallen := ""
	if C != null and C.META is Dictionary and C.META.get("fallen") is Array:
		var cur: Array = run.get("fallen", []) if run.get("fallen") is Array else []
		for i in range(C.META["fallen"].size() - 1, -1, -1):
			var f = C.META["fallen"][i]
			if f is Dictionary and str(f.get("fac", "")) == fac and not cur.has(f):
				fallen = str(f.get("name", ""))
				break
	var last: Dictionary = career.last_run_of(fac)
	return {"nem": run.get("nem"), "flags": run.get("flags", {}) if run.get("flags") is Dictionary else {}, "seed": int(float(run.get("t0", 0))) % 100000,
		"first_lost": first_lost, "best_captain": best, "fallen_name": fallen, "flagship": Career.flagship_name(run), "you": admiral_name(str(run.get("admiral", ""))),
		"prior_flagship": str(last.get("flagship", "")) if not bool(last.get("victory", true)) else "",
		"prior_loss": not last.is_empty() and not bool(last.get("victory", false)), "prior_win": bool(last.get("victory", false)),
		"seen": career.P.get("arc_seen", {}), "arcs_finished": career.arcs_finished(fac)}


# The arc card for a beat (1, 2 or 3) of the current run's faction, as an event-shaped dictionary, or {} when that
# faction's arc file does not exist yet.
func arc_beat(beat_no: int) -> Dictionary:
	if C == null or not (C.RUN is Dictionary):
		return {}
	var a = ArcScript.new()
	if not a.load_arc(str(C.RUN.get("fac", ""))):
		return {}
	return a.render(beat_no, arc_context())


# Record a choice on an arc card (after the campaign applied its outcome): the variant counts as seen and the choice
# is kept for the Chronicle.
func arc_chose(ev: Dictionary, key: String) -> void:
	if C == null or not (C.RUN is Dictionary) or not bool(ev.get("arc", false)):
		return
	var id := str(ev.get("id", ""))
	career.note_arc_choice(C.RUN, id, int(id.substr(id.length() - 2, 1)) if id.length() >= 2 else 0, key)


# Called when a faction arc's beat 3 is decided (step 3 wiring). Emits medal_earned for the arc medal.
func arc_end(won: bool, choices: Dictionary = {}) -> Dictionary:
	if C == null or not (C.RUN is Dictionary):
		return {}
	var run: Dictionary = C.RUN
	var nem = run.get("nem")
	var rival := ("%s %s" % [str(nem.get("title", "")), str(nem.get("name", ""))]).strip_edges() if nem is Dictionary else ""
	if choices.is_empty() and str(career.P.get("live", {}).get("key", "")) == career.run_key(run):
		choices = career.P["live"].get("arc_choices", {}).duplicate()
	var row: Dictionary = career.record_arc_end(str(run.get("fac", "")), str(run.get("admiral", "")), rival, choices, won)
	for id in career.take_new_medals():
		medal_earned.emit(id, medal_name(id))
	return row


# A fresh battle voice for the battle scene (see battle_voice.gd).
func battle_voice():
	return Voice.new()


# ---------------------------------------------------------------- the flagship's name

static func clean_name(s: String) -> String:
	var out := ""
	for ch in s.strip_edges():
		if ch in "[]{}<>\\\"" or ch.unicode_at(0) < 32 or ch == "\u2014" or ch == "\u2013":
			continue
		out += ch
	return out.substr(0, 28).strip_edges()


# Renames the run's flagship. Writes ship.name in the campaign run (a plain field every screen and the battle already
# show), then saves the run. Returns the name used, or "" when nothing changed.
func rename_flagship(new_name: String) -> String:
	if C == null or not (C.RUN is Dictionary):
		return ""
	var n := clean_name(new_name)
	if n == "":
		return ""
	var f = C.flagshipOf()
	if not (f is Dictionary):
		return ""
	f["name"] = n
	C.saveRun()
	C.persist_save()
	C.changed.emit()
	return n


func flagship_name() -> String:
	if C == null or not (C.RUN is Dictionary):
		return ""
	return Career.flagship_name(C.RUN)


# ---------------------------------------------------------------- screens (godot/ui/career/)

func _layer() -> Node:
	if _ui_layer == null or not is_instance_valid(_ui_layer):
		_ui_layer = CanvasLayer.new()
		_ui_layer.layer = 40
		add_child(_ui_layer)
	return _ui_layer


func open_rename() -> void:
	if not is_inside_tree() or not ResourceLoader.exists(RENAME_UI) or flagship_name() == "":
		return
	var d = load(RENAME_UI).new()
	_layer().add_child(d)
	d.open(self)


func open_career() -> Node:
	if not is_inside_tree() or not ResourceLoader.exists(CAREER_UI):
		return null
	var s = load(CAREER_UI).new()
	_layer().add_child(s)
	s.open(self)
	return s
