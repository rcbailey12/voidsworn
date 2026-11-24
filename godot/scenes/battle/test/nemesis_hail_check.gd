extends SceneTree
# Issue 1911 (C27, Board pick Option A): a campaign Nemesis battle opens with ONE Nemesis hail in the battle log, not two.
# The story voice (godot/story/data/rival_lines.json) owns the hail; the rules hail (NEM_VOICE through cfg.nemesis.line)
# stays in B.log, so the saved rules hashes hold, and is kept off the screen. The opening reads in order: "<Nemesis>
# commands this fleet", the one hail, the admiral's reply, then the contact lines. A second part feeds the merge an
# opening with no story hail: the rules hail then still shows, with the voice lines after it.
#   godot --headless --path godot --script res://scenes/battle/test/nemesis_hail_check.gd

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const JSM = API.JSM
const CampaignScript := preload("res://campaign/campaign.gd")
const SEED := 1

class Playback extends "res://scenes/battle/battle.gd":
	func wait(_ms: float) -> void:
		pass

var failures := 0


func _init() -> void:
	GUARD.arm(self, "nemesis_hail_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _index(lines: Array, pred: Callable) -> int:
	for i in lines.size():
		if pred.call(str(lines[i])):
			return i
	return -1


func _run() -> void:
	Engine.time_scale = 40.0   # playback timing is not under test
	var api := API.new()
	var error: String = api.load_rules()
	if error != "":
		_check(false, error)
		quit(1)
		return
	# a real campaign run and its Sector 1 Nemesis, set up the way the game does it (external battle mode)
	var C = CampaignScript.new()
	error = C.load_tables()
	if error != "":
		_check(false, error)
		quit(1)
		return
	C.fixed_clock = true
	C.persist_on = false
	JSM.rnd_seed(SEED)
	C.newRun("vex", "voidsworn")
	C.battle_mode = "external"
	C.battle_setup = func(run, cfg):
		api.new_battle(run, cfg)
		return api.R.B
	var nem: Dictionary = C.nemBattleCfg()
	C.battleScreen({"kind": "elite", "fac": nem["fac"], "nemesis": nem, "node": null, "col": 1})
	_check(api.R.B != null and api.R.B.get("nem") is Dictionary and api.halted == "", "the campaign starts a Nemesis battle (halt: %s)" % api.halted)
	if api.R.B == null:
		quit(1)
		return
	var rules_log: Array = api.R.B["log"].map(func(e): return str(e["m"]))
	var intro_at := _index(rules_log, func(m): return m.contains(" commands this fleet: your Nemesis."))
	_check(intro_at >= 0, "the rules log the Nemesis intro")
	var flag_name: String = rules_log[intro_at].substr(0, rules_log[intro_at].find(" commands this fleet")) if intro_at >= 0 else "?"
	var hail_prefix := flag_name + ": \""
	var rules_hail := _index(rules_log, func(m): return m.begins_with(hail_prefix))
	_check(rules_hail > intro_at, "the rules hail stays in B.log, after the intro (saved hashes unchanged)")
	var rules_hail_text: String = rules_log[rules_hail] if rules_hail >= 0 else ""

	var battle := Playback.new()
	battle.external = true
	battle.user_speed = 0.0
	battle.args = {"noworld": true}
	var cues: Array = []
	battle.recording_cue.connect(func(kind, text): if kind == "voice": cues.append(text))
	root.add_child(battle)
	await battle._begin(api)
	var n := 0
	while (battle.busy or not battle.batches.is_empty()) and n < 600:
		await process_frame
		n += 1
	_check(not battle.busy and battle.batches.is_empty(), "the opening batch played out (%d frames)" % n)
	_check(api.halted == "", "the rules did not halt (%s)" % api.halted)

	var shown: Array = battle.hud._log_lines.duplicate()
	print("  battle log:")
	for l in shown:
		print("    ", l)
	var hails := shown.filter(func(l): return str(l).begins_with(hail_prefix))
	_check(hails.size() == 1, "exactly one Nemesis opening hail in the battle log (%d)" % hails.size())
	_check(not shown.has(rules_hail_text), "the rules hail is not shown when the story voice gives its own")
	var text: String = battle.hud.log_text.get_parsed_text()
	_check(text.count(hail_prefix) == 1, "hud.log_text holds one Nemesis hail too")
	var i_intro := _index(shown, func(l): return l.contains(" commands this fleet: your Nemesis."))
	var i_hail := _index(shown, func(l): return l.begins_with(hail_prefix))
	var i_adm := _index(shown, func(l): return l.begins_with("Admiral "))
	var i_contact := _index(shown, func(l): return l.begins_with("Contact: "))
	_check(i_intro >= 0 and i_hail == i_intro + 1, "the hail follows the Nemesis intro (intro %d, hail %d)" % [i_intro, i_hail])
	_check(i_adm == i_hail + 1, "the admiral's reply follows the hail (hail %d, admiral %d)" % [i_hail, i_adm])
	_check(i_contact > i_adm, "the contact lines come after the exchange (admiral %d, contact %d)" % [i_adm, i_contact])
	_check(i_hail >= 0 and cues.has(shown[i_hail]) and i_adm >= 0 and cues.has(shown[i_adm]),
		"the story hail and the reply still reach the recording cue")
	battle.free()

	# no story hail (an opening with only the admiral's line): the rules hail stays on screen and the voice follows it
	var b2 := Playback.new()
	b2.batches = [{"events": [
		{"t": "log", "text": "X commands this fleet: your Nemesis.", "kind": "e", "nem": "intro"},
		{"t": "log", "text": "X: \"rules hail\"", "kind": "e", "nem": "hail"},
		{"t": "log", "text": "Contact: Y.", "kind": "s"}], "view": {}}]
	var merged: bool = b2._merge_nemesis_opening([{"text": "Admiral Z: \"reply\"", "kind": "s", "who": "admiral", "moment": "nemesis"}])
	var texts: Array = b2.batches[0]["events"].map(func(e): return e["text"])
	_check(merged and texts == ["X commands this fleet: your Nemesis.", "X: \"rules hail\"", "Admiral Z: \"reply\"", "Contact: Y."],
		"with no story hail the rules hail shows and the reply follows it: %s" % [texts])
	# a battle with no Nemesis lines in its opening batch is left to the old path
	var b3 := Playback.new()
	b3.batches = [{"events": [{"t": "log", "text": "Contact: Y.", "kind": "s"}], "view": {}}]
	_check(not b3._merge_nemesis_opening([{"text": "Admiral Z: \"go\"", "kind": "s", "moment": "start"}]) and b3.batches[0]["events"].size() == 1,
		"a battle without a Nemesis keeps its opening lines as before")
	b2.free()
	b3.free()

	if failures == 0:
		print("PASS: nemesis_hail_check (one Nemesis opening hail, intro, hail, reply, contact in order)")
	else:
		printerr("FAIL: nemesis_hail_check: %d failed" % failures)
	quit(0 if failures == 0 else 1)
