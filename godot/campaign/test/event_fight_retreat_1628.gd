# Issue 1628, Godot twin of contrib/opus/tools/event_fight_retreat_1628_tests.js (both read
# fixtures/issue_1628/event_fight_retreat.json): after a retreat from a fight that an event choice started, entering the
# event stop again goes straight back to that fight, with no second pick. Prints PASS or FAIL lines; exit 0 when all pass.
#   godot --headless --path godot --script res://campaign/test/event_fight_retreat_1628.gd
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/battle_api.gd").JSM

var c = Campaign.new()
var fails := 0


func _initialize() -> void: _run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok: fails += 1


func _cfg():
	return c.B.get("cfg") if c.B is Dictionary else null


func _run() -> void:
	c.load_tables(); c.persist_on = false
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/fixtures/issue_1628/event_fight_retreat.json"))
	for cs in fx["cases"]:
		var name: String = cs["name"]; var ex: Dictionary = cs["expect"]
		c.rng.rnd_seed(int(fx["seed"]))
		c.META["admirals"][fx["admiral"]] = true
		c.newRun(fx["admiral"], fx["fac"])
		var n: Dictionary = c.RUN["map"]["cols"][0][0]
		n["type"] = "event"; n["evId"] = cs["event"]
		for k in ["enc", "shape", "arch", "mod", "rw"]: n.erase(k)
		c.RUN["pos"] = n["id"]; c.RUN["curNode"] = n["id"]; c.B = null
		c.eventScreen(n); c.ACT_eventChoice(str(int(cs["pick"])))
		var cfg = _cfg()
		_check(cfg is Dictionary and cfg.get("fac") == ex["firstFight"] and cfg.get("node") == n["id"] and cfg.get("eventRelic") == true, name + ": the choice starts the fight")
		_check(n.get("evFight") == ex["evFight"], name + ": the stop remembers the choice (%s)" % str(n.get("evFight")))
		c.B = null; c.modal_d = null
		if c.has_method("retreatBack"): c.retreatBack()
		c.RUN["pos"] = n["id"]; c.RUN["curNode"] = n["id"]
		c.eventScreen(n)
		cfg = _cfg()
		var modal_up: bool = c.modal_d != null and c.modal_d.get("kind") == "event"
		_check(cfg is Dictionary and cfg.get("fac") == ex["againFight"] and cfg.get("node") == n["id"] and modal_up == bool(ex["againModal"]), name + ": entering again goes straight to the same fight, no second pick")
	print("EVENT_FIGHT_RETREAT_1628 fails=%d" % fails)
	quit(1 if fails else 0)
