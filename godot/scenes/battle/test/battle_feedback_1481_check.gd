extends SceneTree
# Issue 1481 (independent game audit Nov 21, F-08 to F-11, F-14), the battle scene's half:
#   a shield drop with no volley zeroes every side of the readout (R246: an empty pool drops every side at once);
#   a ram's soak reaches the shield readout (the rules now send the pool's sides after the ram);
#   counter-fire, ram shockwave and reactor hits tick the plate when they land, with no second number over the boon's own;
#   the end banner counts ships, not wings;
#   the problem report toast speaks to the player, not to the developers.
# Real battle scene on rules scenario s1. The rules half is godot/rules/test/rules_1481_test.gd.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")

class Probe extends "res://scenes/battle/battle.gd":
	var hit_floats := 0

	func _float_hit(id, sh: float, hull: float, crit) -> void:
		hit_floats += 1
		super._float_hit(id, sh, hull, crit)

var failures := 0


func _init() -> void:
	GUARD.arm(self, "battle_feedback_1481_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
	else:
		print("ok    ", message)


func _run() -> void:
	# the end banner count (no scene needed)
	var view := {"units": [
		{"side": "player", "dead": true, "fled": false, "squadron": false},
		{"side": "player", "dead": true, "fled": false, "squadron": true},
		{"side": "player", "dead": true, "fled": true, "squadron": false},
		{"side": "enemy", "dead": true, "fled": false, "squadron": false},
		{"side": "enemy", "dead": true, "fled": false, "squadron": true},
		{"side": "enemy", "dead": true, "fled": false, "squadron": true},
		{"side": "enemy", "dead": false, "fled": false, "squadron": false}]}
	var tally: Array = BATTLE.end_tally(view)
	_check(tally == [1, 1], "the end banner counts 1 ship lost and 1 killed, not the 3 wings (got %s)" % str(tally))

	# review of PR 1595 (finding 2): a generator lost on the first of two hits breaks the shield on that hit, inside the volley
	var g1 := {"t": "hit", "target": "x", "shield": 4, "hull": 3}
	var g2 := {"t": "hit", "target": "x", "shield": 0, "hull": 9}
	var grp := [g1, {"t": "section_down", "unit": "x", "section": "mid"}, {"t": "shield_down", "unit": "x", "quad": 0}, g2]
	_check(BATTLE.section_break_hit(grp, BATTLE.shield_break_hit([g1, g2])) == 0, "a mid-volley generator loss breaks the shield on hit 1 of 2")
	_check(BATTLE.section_break_hit([g1, g2, {"t": "shield_down", "unit": "x", "quad": 0}], 0) == 0, "an ordinary volley break keeps its pick")
	var gsrc := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	_check(gsrc.find('"burning", "section_down"]') >= 0, "the volley groups its section loss with its hits")
	var src := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	_check(src.find("Ryan's helpers") < 0, "the problem report toast has no developer wording")

	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		_done()
		return
	api.new_battle_scenario("s1", 1481)
	api.R.B["terrain"].clear()
	var me: Dictionary = api.R.alive("player")[0]
	var foe: Dictionary = api.R.alive("enemy")[0]
	me.merge({"q": 2, "r": 6, "facing": 0}, true)
	foe.merge({"q": 5, "r": 6, "facing": 3}, true)
	var b := Probe.new()
	b.cine = "off"
	b.follow = false
	b.external = true   # review of PR 1595: _ready must not start its own battle; this check starts the one it reads
	root.add_child(b)
	await b._begin(api)
	var t := str(me["id"])
	var a := str(foe["id"])
	var d: Dictionary = b.disp.get(t, {})
	_check(d.get("sh") is Array, "the target has a shield readout")
	if not (d.get("sh") is Array):
		b.free()
		_done()
		return

	# a storm drop (no volley): every side goes to zero, not only the quadrant named
	d["sh"] = [9, 7, 5, 7]
	await b._play_event({"t": "shield_down", "unit": t, "quad": 0})
	_check((d["sh"] as Array).all(func(x): return float(x) == 0.0), "a drop with no volley zeroes every side (got %s)" % str(d["sh"]))

	# a ram: the soak shows on the readout as the rules left it
	d["sh"] = [20, 15, 10, 15]
	var hp0 := float(d["hp"])
	await b._play_event({"t": "ram", "unit": a, "target": t, "path": [], "dmg": 5, "recoil": 2, "soak": 6, "section": "prow", "sh": [11, 8, 5, 8]})
	_check(d["sh"] == [11, 8, 5, 8] and float(d["hp"]) == hp0 - 5.0, "a ram updates the shield readout and the hull (sh %s, hp %s)" % [str(d["sh"]), str(d["hp"])])

	# a counter-fire hit: the plate ticks at once, the boon float is the only number
	var hp1 := float(d["hp"])
	var f0 := b.hit_floats
	await b._play_event({"t": "hit", "unit": a, "target": t, "quad": 0, "section": null, "shield": 0, "hull": 18, "crit": false, "float": false})
	_check(float(d["hp"]) == hp1 - 18.0 and b.hit_floats == f0, "a quiet hit ticks the plate with no second number (hp %s, floats %d)" % [str(d["hp"]), b.hit_floats - f0])
	await b._play_event({"t": "hit", "unit": a, "target": t, "quad": 0, "section": "mid", "shield": 0, "hull": 3, "crit": false})
	_check(b.hit_floats == f0 + 1, "an ordinary hit still floats its number")
	b.free()
	_done()


func _done() -> void:
	print("battle_feedback_1481_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
