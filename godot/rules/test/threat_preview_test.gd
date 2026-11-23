# Issue 1859. Run with Godot --headless --path godot --script res://rules/test/threat_preview_test.gd.
extends SceneTree
@warning_ignore_start("unsafe_property_access", "unsafe_method_access", "unsafe_call_argument", "return_value_discarded")

const API := preload("res://rules/battle_api.gd")
const Preview := preload("res://rules/threat_preview.gd")
const Snap := preload("res://rules/battle_snapshot.gd")
const Guard := preload("res://tools/ci/check_guard.gd")

var failures := 0


func _initialize() -> void:
	Guard.arm(self, "threat_preview_test")
	for level in ["standard", "veteran"]:
		for alt in [true, false]:
			_compare_activation(level, alt, "wing")
			_compare_activation(level, alt, "hull")
	_compare_activation("standard", true, "taunt")
	_compare_activation("veteran", true, "focus")
	_compare_activation("veteran", true, "nemesis")
	_compare_activation("veteran", true, "break")
	_compare_activation("standard", true, "moving")
	_compare_activation("standard", true, "drain")
	_compare_activation("standard", true, "reinforcement")
	_compare_activation("standard", false, "classic_done")
	_check_alternating_scheduler()
	print("THREAT_PREVIEW ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("THREAT_PREVIEW " + message)


func _compare_activation(level: String, alt: bool, kind: String) -> void:
	var label := "%s %s %s" % [level, "Alternating" if alt else "Classic", kind]
	var control := _fixture(level, alt, kind)
	if control == null:
		return
	var before_control := _state(control)
	var control_events := control.step()
	var after_control := _state(control)

	var subject := _fixture(level, alt, kind)
	if subject == null:
		return
	var before := _state(subject)
	_check(before == before_control, label + ": control setup differs from subject")
	var order := _ids(subject.R.B["units"])
	var view := _view(subject)
	var current = subject.R.B.get("aiFocus")
	var focus_id: String = "" if current == null else current["id"]
	var preview := {}
	for i in range(50):
		var result := Preview.score(view, focus_id, order)
		if i == 0:
			preview = result
		else:
			_check(var_to_bytes(result) == var_to_bytes(preview), label + ": result changed on call %d" % (i + 1))
	var after := _state(subject)
	for key in before:
		_check(after[key] == before[key], "%s: %s changed after 50 calls" % [label, key])

	var players: Array = subject.R.caps("player")
	var enemies: Array = subject.R.caps("enemy")
	var reinforcement: Dictionary = enemies[-1]
	_check(reinforcement.get("reinf") == true and preview.has(reinforcement["id"]), label + ": missing arrived reinforcement")
	if kind == "reinforcement":
		_check(not preview.get(reinforcement["id"], []).is_empty(), label + ": reinforcement has no target")
	if kind == "drain":
		_check(preview.keys() == _ids(subject._queue), label + ": full Alternating batch order differs")
	var reversed := {}
	if kind == "hull" and level == "standard":
		order.reverse()
		reversed = Preview.score(view, focus_id, order)
	var actual_events := subject.step()
	_check(var_to_bytes(actual_events) == var_to_bytes(control_events), label + ": next activation events differ from control")
	_check(_state(subject) == after_control, label + ": next activation state differs from control")

	var actor := _event_id(actual_events, "activation", "", "unit")
	var target := _event_id(actual_events, "fire", actor, "target")
	_check(actor != "" and target != "", label + ": missing real activation or first shot for " + actor)
	if actor == "" or target == "":
		return
	if kind == "reinforcement":
		_check(actor == reinforcement["id"], label + ": expected the reinforcement to act")
	if kind == "nemesis":
		_check(subject.R.B["nemDuel"] == target, label + ": the real activation did not retarget its duel")
	if kind == "break":
		_check(subject.R.B["obj"].has("c0"), label + ": the real AI did not set the objective edge")
	_check(not preview.is_empty() and preview.keys()[0] == actor, label + ": first scheduled unit differs (%s vs %s)" % [preview.keys(), actor])
	var candidates: Array = preview.get(actor, [])
	_check(not candidates.is_empty() and candidates[0]["id"] == target, label + ": first target differs (%s vs %s)" % [candidates, target])
	if kind == "hull" and level == "standard":
		_check(candidates.size() == 2 and candidates[1]["likelihood"] == "tied", label + ": expected equal shot scores")
		if candidates.size() == 2:
			_check(candidates[0]["id"] == players[0]["id"], label + ": initial tie order")
			var reverse_candidates: Array = reversed.get(actor, [])
			_check(not reverse_candidates.is_empty() and reverse_candidates[0]["id"] == players[1]["id"], label + ": explicit reverse tie order ignored")
	if kind == "focus" or kind == "taunt":
		_check(target == players[1]["id"], label + ": expected second player hull")
		_check(not candidates.is_empty() and candidates[0]["reason"] == ("fleet focus" if kind == "focus" else "taunt"), label + ": reason missing")
	print("  %s: %s targets %s" % [label, actor, target])


func _check_alternating_scheduler() -> void:
	for kind in ["wing", "drain", "reinforcement"]:
		var api := _fixture("standard", true, kind, false)
		if api == null:
			continue
		var preview := Preview.score(_view(api), "", _ids(api.R.B["units"]))
		api.end_activation(api.R.caps("player")[0]["id"])
		var ids := _ids(api._queue)
		_check(not ids.is_empty() and preview.keys().slice(0, ids.size()) == ids, "Alternating %s: pre-pass batch differs from committed queue" % kind)


func _fixture(level: String, alt: bool, kind: String, start_enemy := true) -> API:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, "rules load: " + error)
		return null
	api.new_battle_scenario({
		"seed": 1859, "sector": 1, "admiral": "vex", "fleet": ["warden", "warden"],
		"kind": "battle", "fac": "hegemony", "enemies": ["h_picket", "h_picket"],
		"obj": "break" if kind == "break" else "rout", "shape": "open", "map": "belt", "arena": "strip", "dep": "line",
		"ai": level, "alt": alt, "campaign": true, "event_force": "reinf_enemy",
	})
	var rules = api.R
	var battle: Dictionary = rules.B
	var arrival: Dictionary = battle["event"]
	battle["round"] = arrival["r"]
	rules.eventTick()
	var player: Array = rules.caps("player")
	var enemy: Array = rules.caps("enemy")
	if player.size() != 2 or enemy.size() != 3 or enemy[2].get("reinf") != true:
		_check(false, "fixture did not deploy the two fleets and the real reinforcement")
		return null

	battle["terrain"] = {}
	rules.CUT = null
	rules.SOLID = null
	rules._ob.clear()
	_put(player[0], 8, 5)
	_put(player[1], 5, 8)
	player[0]["facing"] = 3
	player[1]["facing"] = 4
	for t in player:
		t["pflag"] = false
		t["sh"] = [0.0, 0.0, 0.0, 0.0]
		t["shp"] = 0.0
		t["armor"] = 0.0
		t["intercepts"] = 0
		for w in t["weapons"]:
			w["fired"] = true
	_put(enemy[0], 5, 5)
	_put(enemy[1], 13, 10)
	_put(enemy[2], 14, 10)
	for u in enemy:
		u["ab"] = null
		u["weapons"] = [_ready_weapon(rules, "laser", 5)]
	if kind == "wing" or kind == "hull":
		var wing: Dictionary = rules.makeWing(enemy[0], {"q": 7, "r": 6}, "bomber")
		wing["weapons"] = [_ready_weapon(rules, "bombs", 3)]
		# For the hull fixture the real wing acts first, out of range, and spends its step.
		if kind == "hull":
			_put(wing, 14, 9)
	if kind == "taunt":
		player[1]["fx"]["taunt"] = 4
	if kind == "focus":
		battle["aiFocus"] = player[1]
	if kind == "nemesis":
		battle["nemDuel"] = "departed"
		battle["nemChallenge"] = true
		battle["nemAi"] = {"hunt": true}
		enemy[0]["nem"] = true
		enemy[0]["nemFlag"] = true
	if kind == "moving":
		_put(enemy[0], 2, 5)
	if kind == "drain":
		player[1]["activated"] = true
		# Drain uses board order even when the second hull has more speed.
		enemy[1]["speed"] += 2
	if kind == "reinforcement":
		_put(enemy[0], 14, 9)
		_put(enemy[2], 5, 5)
		enemy[2]["speed"] += 2
	if kind == "break":
		battle["obj"].erase("c0")
	if kind == "classic_done":
		_put(enemy[1], 6, 6)
	if alt:
		_hold_enemy(rules, kind)
		if not start_enemy:
			return api
		api.end_activation(player[0]["id"])
	else:
		api.end_turn()
		_hold_enemy(rules, kind)
	if kind == "hull":
		var wing_events := api.step()
		var wing_actor := _event_id(wing_events, "activation", "", "unit")
		_check(wing_actor != "" and rules.jt(api.unit(wing_actor).get("isSq")), "hull fixture did not step past the wing")
	if kind == "classic_done":
		api.step()
		_check(api._c_done.size() == 1 and api.phase == "enemy", "Classic fixture did not finish its first hull activation")
	return api


func _ready_weapon(rules, id: String, reach: int) -> Dictionary:
	var gun: Dictionary = rules.mkWeapon(id, "T", {})
	gun.merge({"r": reach, "opt": reach, "fired": false, "cdLeft": 0, "off": 0}, true)
	return gun


func _put(u: Dictionary, q: int, r: int) -> void:
	u["q"] = q
	u["r"] = r
	u["facing"] = 0
	u["hexMoved"] = 0


func _hold_enemy(rules, kind: String) -> void:
	for u in rules.alive("enemy"):
		u["mp"] = 0
		u["noTurn"] = true
	if kind == "moving":
		rules.caps("enemy")[0]["mp"] = 2


func _ids(group: Array) -> Array:
	return group.map(func(unit): return unit["id"])


func _view(api: API) -> Dictionary:
	var rules = api.R
	return {
		"B": rules.B, "run": rules.RUN, "meta": rules.META, "tables": rules.TB,
		"board_size": Vector2i(rules.BW, rules.BH), "cut": rules.CUT, "solid": rules.SOLID,
		"level": rules.AI_LEVEL, "phase": api.phase, "queue": _ids(api._queue),
		"classic_order": _ids(api._c_order), "classic_index": api._c_i, "classic_done": _ids(api._c_done),
	}


func _state(api: API) -> Dictionary:
	var rules = api.R
	var queue := [api.phase, api._queue, api._c_order, api._c_i, api._c_g, api._c_done]
	var packed := Snap.pack({"B": rules.B, "RUN": rules.RUN, "queue": queue})
	_check(packed.has("bytes"), "could not serialize the real B/RUN/queue graph: %s" % [packed.get("error")])
	return {
		"B/RUN/queue graph": packed.get("bytes"),
		"queue": var_to_bytes([api.phase, _ids(api._queue), _ids(api._c_order), api._c_i, api._c_g, _ids(api._c_done)]),
		"RNG word": API.JSM.rng_s,
		"events": var_to_bytes(rules.events),
		"score caches": var_to_bytes([rules._evc, rules._ang, rules._mr, rules._runfx, rules._ev, rules._guard]),
	}


func _event_id(events: Array, type: String, unit: String, field: String) -> String:
	for event in events:
		if event["t"] == type and (unit == "" or event.get("unit") == unit) and (type != "activation" or event.get("side") == "enemy"):
			return event[field]
	return ""
