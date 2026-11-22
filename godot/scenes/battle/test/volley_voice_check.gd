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

class Recorder extends RefCounted:
	var seen: Array = []
	func on_event(e: Dictionary) -> Array:
		seen.append(e)
		return []
	func closing(_win) -> String:
		return ""

var failures := 0


func _init() -> void:
	GUARD.arm(self, "volley_voice_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _battle(api) -> Playback:
	var battle := Playback.new()
	battle.external = true
	battle.showcase = true   # no voice of its own; the check installs one
	battle.user_speed = 0.0
	root.add_child(battle)
	await battle._begin(api)
	return battle


func _new_api(seed := SEED):
	var api := API.new()
	var error: String = api.load_rules()
	if error != "":
		_check(false, error)
		return null
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	api.new_battle_scenario(scenarios["s1"], seed)
	return api


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


func _grouped(events: Array) -> int:
	var n := 0
	for i in events.size():
		if events[i]["t"] == "fire" and i + 1 < events.size() and events[i + 1]["t"] == "hit":
			n += 1
	return n


# Part 1: every event of real batches with grouped volleys reaches voice once, in batch order.
func _every_event_once() -> void:
	var api = _new_api()
	if api == null:
		return
	var battle := await _battle(api)
	var rec := Recorder.new()
	battle.voice = rec
	var volleys := 0
	var turns := 0
	while volleys < 3 and turns < 12 and api.view().get("winner") == null:
		var events: Array = _turn(api)
		turns += 1
		volleys += _grouped(events)
		rec.seen.clear()
		await battle._play_batch({"events": events, "view": api.view()})
		_check(rec.seen.size() == events.size(), "turn %d: voice saw %d of %d events" % [turns, rec.seen.size(), events.size()])
		for i in mini(rec.seen.size(), events.size()):
			if not is_same(rec.seen[i], events[i]):
				_check(false, "turn %d: event %d (%s) reached voice out of order or twice" % [turns, i, events[i]["t"]])
				break
	_check(volleys >= 1, "the real turns include at least one grouped volley (%d seen)" % volleys)
	print("  every event once: %d grouped volleys over %d turns" % [volleys, turns])
	battle.free()


# Part 2: real voice, a grouped enemy volley on the player flagship that leaves it alive below 40%.
func _flag_hurt_in_volley() -> void:
	for attempt in 8:
		var api = _new_api(SEED + attempt)
		if api == null:
			return
		var flag: Dictionary = api.R.alive("player")[0]
		flag["pflag"] = true
		var battle := await _battle(api)
		var voice = VOICE.new()
		voice.setup_from_rules(api.R, api.view())
		battle.voice = voice
		var lines: Array = []
		battle.recording_cue.connect(func(kind, text): if kind == "voice": lines.append(text))
		for turn in 12:
			if api.view().get("winner") != null or flag.get("dead", false):
				break
			var events: Array = _turn(api)
			var hit_flag := false
			for i in events.size():
				if events[i]["t"] == "fire" and str(events[i].get("target")) == str(flag["id"]) and i + 1 < events.size() and events[i + 1]["t"] == "hit":
					hit_flag = true
			if not hit_flag:
				await battle._play_batch({"events": events, "view": api.view()})
				continue
			# The rules have already resolved this batch; put the flagship alive at 30% so the volley is the one that
			# leaves it below 40% when voice reads the live state.
			flag["dead"] = false
			flag["hp"] = maxf(1.0, floorf(float(flag["maxHp"]) * 0.3))
			lines.clear()
			await battle._play_batch({"events": events, "view": api.view()})
			_check(voice.said.has("flag_hurt"), "a grouped volley leaving the flagship at 30% says the flag_hurt line")
			if voice.adm_text("flag_hurt") != "" or str(voice.info.get("admiral", "")) != "":
				_check(lines.size() >= 1, "the flag_hurt line reaches the battle log (%d voice lines)" % lines.size())
			print("  flag_hurt in a grouped volley: %s" % ("PASS" if voice.said.has("flag_hurt") else "FAIL"))
			battle.free()
			return
		battle.free()
	_check(false, "no seed gave a grouped enemy volley on the player flagship")


func _run() -> void:
	await _every_event_once()
	await _flag_hurt_in_volley()
	if failures == 0:
		print("volley voice: PASS (every event once, flag_hurt inside a grouped volley)")
	quit(0 if failures == 0 else 1)
