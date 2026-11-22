extends SceneTree
# Issue 1551 (Artoo on PR 1552): a volley's fire and its grouped hits are played by _play_fire, not _play_event.
# This plays real rules batches through the battle scene and checks that every event reaches battle voice exactly
# once, and that a grouped enemy volley leaving the player flagship alive below 40% hull says the flag_hurt line.

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const VOICE := preload("res://story/battle_voice.gd")
const SEED := 1551

class Playback extends "res://scenes/battle/battle.gd":
	func wait(_ms: float) -> void:
		pass

# Records every event the scene hands to voice, then passes it on to the real battle voice.
class Recorder extends RefCounted:
	var seen: Array = []
	var real = null
	var said: Dictionary:
		get: return real.said
	func on_event(e: Dictionary) -> Array:
		seen.append(e)
		return real.on_event(e)
	func closing(win) -> String:
		return real.closing(win)

var failures := 0


func _init() -> void:
	GUARD.arm(self, "volley_voice_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


# One full round of real rules: the bot plays each player ship, then the enemy side steps to the end of its phase.
func _turn(api) -> Array:
	var ev: Array = []
	for u in api.R.alive("player"):
		if api.phase == "player" and not u.get("activated", false):
			api.ai_activate(u["id"])
			ev += api.take_events()
	api.end_turn()
	ev += api.take_events()
	var n := 0
	while api.phase == "enemy" and n < 60:
		ev += api.step()
		n += 1
	return ev


# One battle scene, one pass (kept short for the CI time budget): every event of each real batch must reach voice
# once and in order, and the first grouped enemy volley on the player flagship, with the flagship put at 30% hull,
# must say flag_hurt.
func _run() -> void:
	Engine.time_scale = 40.0   # playback timing is not under test; tweens and timers run 40x so the check fits the CI budget
	var api := API.new()
	var error: String = api.load_rules()
	if error != "":
		_check(false, error)
		quit(1)
		return
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	api.new_battle_scenario(scenarios["s1"], SEED)
	var flag: Dictionary = api.R.alive("player")[0]
	flag["pflag"] = true
	var battle := Playback.new()
	battle.external = true
	battle.showcase = true   # no voice of its own; the check installs one
	battle.user_speed = 0.0
	root.add_child(battle)
	await battle._begin(api)
	var rec := Recorder.new()
	rec.real = VOICE.new()
	rec.real.setup_from_rules(api.R, api.view())
	battle.voice = rec
	var lines: Array = []
	battle.recording_cue.connect(func(kind, text): if kind == "voice": lines.append(text))
	var volleys := 0
	var hurt_tested := false
	var turns := 0
	while turns < 14 and api.view().get("winner") == null and not (volleys >= 2 and hurt_tested):
		var events: Array = _turn(api)
		turns += 1
		var on_flag := false
		for i in events.size():
			if events[i]["t"] == "fire" and i + 1 < events.size() and events[i + 1]["t"] == "hit":
				volleys += 1
				on_flag = on_flag or str(events[i].get("target")) == str(flag["id"])
		var test_hurt := on_flag and not hurt_tested and not bool(flag.get("dead", false))
		if test_hurt:
			flag["hp"] = maxf(1.0, floorf(float(flag["maxHp"]) * 0.3))   # the volley leaves it alive below 40%
			rec.real.said.erase("flag_hurt")
			lines.clear()
		rec.seen.clear()
		await battle._play_batch({"events": events, "view": api.view()})
		_check(rec.seen.size() == events.size(), "turn %d: voice saw %d of %d events" % [turns, rec.seen.size(), events.size()])
		for i in mini(rec.seen.size(), events.size()):
			if not is_same(rec.seen[i], events[i]):
				_check(false, "turn %d: event %d (%s) reached voice out of order or twice" % [turns, i, events[i]["t"]])
				break
		if test_hurt:
			hurt_tested = true
			_check(rec.real.said.has("flag_hurt"), "a grouped volley leaving the flagship at 30% says the flag_hurt line")
			_check(lines.size() >= 1, "the flag_hurt line reaches the battle log (%d voice lines)" % lines.size())
	_check(volleys >= 1, "the real turns include at least one grouped volley (%d seen)" % volleys)
	_check(hurt_tested, "a grouped enemy volley hit the player flagship within %d turns" % turns)
	print("  %d grouped volleys over %d turns, flag_hurt tested: %s" % [volleys, turns, hurt_tested])
	battle.free()
	if failures == 0:
		print("volley voice: PASS (every event once, flag_hurt inside a grouped volley)")
	quit(0 if failures == 0 else 1)
