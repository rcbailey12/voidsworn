extends SceneTree
# Issue 1871: keep the pre-brisk cut list, then drive the new choices through the battle camera and its input.
const GUARD := preload("res://tools/ci/check_guard.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const MAIN := preload("res://main/main.gd")
const THROWAWAY := preload("res://tools/throwaway_profile.gd")
const CAMERA_ROWS := [
	["volley", "cruiser", "escort"], ["lance", "escort", "cruiser"], ["torp", "cruiser", "escort"],
	["nova", "escort", "cruiser"], ["volley", "capital", "low"], ["volley", "capital", "cruiser"],
	["volley", "escort", "low"], ["volley", "capital", "boss"], ["lance", "boss", "escort"],
	["kill", "escort", "escort"], ["kill", "escort", "wing"], ["kill", "escort", "cruiser"],
	["kill", "escort", "capital"], ["kill", "escort", "boss"],
]
const LEGACY_KEY_CUTS := [1, 2, 3, 4, 7, 8, 11, 12, 13]
const LEGACY_ALL_CUTS := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

class Playback extends "res://scenes/battle/battle.gd":
	signal shot_hold_started(ms: float)
	var waits: Array[float] = []

	func wait(ms: float, skippable_cut := false) -> void:
		waits.append(ms)
		if skippable_cut:
			shot_hold_started.emit(ms)
		await super.wait(ms, skippable_cut)

var b
var failures := 0


func _init() -> void:
	GUARD.arm(self, "brisk_camera_check", 90.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _cut_list() -> Array[int]:
	var cuts: Array[int] = []
	for i in CAMERA_ROWS.size():
		var row: Array = CAMERA_ROWS[i]
		if b._cine_wants(row[0], row[1], row[2]):
			cuts.append(i)
	return cuts


func _key_skip() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_K
	e.pressed = true
	root.push_input(e)
	e = InputEventKey.new()
	e.keycode = KEY_K
	root.push_input(e)


func _run() -> void:
	var profile := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if not profile.contains("/godot_checks/xdg/") and (OS.get_name() != "Windows" or THROWAWAY.refusal("brisk_camera_check.gd") != ""):
		_check(false, "run the settings check with an isolated Godot profile")
		quit(1)
		return
	var previous_settings = FileAccess.get_file_as_bytes(MAIN.SETTINGS_PATH) if FileAccess.file_exists(MAIN.SETTINGS_PATH) else null
	root.size = Vector2i(1920, 1080)
	b = BATTLE.instantiate()
	b.set_script(Playback)
	b.external = true
	b.args.merge({"scenario": "s1", "seed": 1871, "quality": "low", "noworld": true, "no-tips": true})
	root.add_child(b)
	var main := MAIN.new()
	_check(not main.settings["brisk_camera"], "the saved preference defaults to off")
	main.settings.erase("brisk_camera")
	b.brisk_camera = true
	main._settings_to_battle(b)
	_check(not b.brisk_camera, "a profile without the setting uses the original camera")
	main.settings["brisk_camera"] = true
	main._settings_to_battle(b)
	_check(b.brisk_camera, "the saved preference reaches the battle")
	main.settings["brisk_camera"] = false
	main._settings_to_battle(b)
	main.save_settings()
	b.busy = true
	b.start_default()
	while b.warming:
		await process_frame
	b.busy = false
	b.batches.clear()
	b._end_opening()
	b.speed = 0.2
	b._open_menu()
	var brisk_row: Button
	for row in b.hud.menu.find_children("*", "Button", true, false):
		if row.text == "Brisk camera: off":
			brisk_row = row
			break
	_check(brisk_row != null, "the battle menu offers Brisk camera")
	if brisk_row != null:
		brisk_row.pressed.emit()
		_check(b.brisk_camera and main.settings["brisk_camera"], "the battle menu updates Main's Brisk camera setting")
		var restored := MAIN.new()
		restored._load_settings()
		_check(restored.settings["brisk_camera"], "a fresh Main reloads Brisk camera On from the battle menu save")
		restored.free()
	b.hud.hide_menu()
	main.free()
	_restore_settings(previous_settings)
	b.brisk_camera = false
	b.VU.merge({
		"escort": {"name": "Escort", "size": 0.5, "side": "player"}, "cruiser": {"name": "Cruiser", "size": 0.6, "side": "enemy"},
		"capital": {"name": "Capital", "size": 0.8}, "low": {"size": 0.6, "hp": 34, "maxHp": 100},
		"boss": {"name": "Boss", "size": 0.9, "flagship": true}, "wing": {"squadron": true, "size": 0.2},
	})
	_check(_cut_list() == LEGACY_KEY_CUTS, "brisk off, Key moments matches the baseline cut list: %s" % str(_cut_list()))
	b.cine = "all"
	_check(_cut_list() == LEGACY_ALL_CUTS, "brisk off, Every attack matches the baseline cut list: %s" % str(_cut_list()))
	b.cine = "off"
	_check(_cut_list().is_empty(), "brisk off, Cut-ins Off matches the empty baseline cut list")

	b.cine = "key"
	b.brisk_camera = true
	_check(_cut_list() == [3, 4, 7, 8, 11, 12, 13], "brisk keeps novas, low-hull capital volleys, flagship shots and big kills")
	b.cine = "all"
	_check(_cut_list() == [3, 4, 7, 8, 9, 10, 11, 12, 13], "brisk filters routine shots even in Every attack and keeps its kill cuts")
	b.cine = "off"
	_check(_cut_list().is_empty(), "brisk respects Cut-ins Off")
	b.cine = "key"
	var enemy_id := ""
	for u in b.V["units"]:
		if u["side"] == "enemy" and not u["flagship"]:
			enemy_id = str(u["id"])
			break
	var board_target: Vector3 = b.cam.t
	b._follow_enemy_activation(enemy_id)
	_check(b.cam.t != board_target and not b.cam_saved.is_empty(), "Brisk camera leaves enemy follow to its own setting")
	b._end_enemy_follow()
	b.VU[enemy_id]["flagship"] = true
	b._follow_enemy_activation(enemy_id)
	_check(b.cam.t != board_target and not b.cam_saved.is_empty(), "brisk still follows the flagship")
	_key_skip()
	_check(not b.cam_saved.is_empty(), "the sticky shortcut leaves flagship follow in place")
	b.VU[enemy_id]["flagship"] = false
	b._end_enemy_follow()
	b.brisk_camera = false
	b._follow_enemy_activation(enemy_id)
	_check(b.cam.t != board_target, "brisk off follows routine enemy activations")
	_key_skip()
	b._follow_enemy_activation(enemy_id)
	_check(b.cam.t == board_target and b.cam_saved.is_empty(), "K restores the board and skips subsequent routine follow")

	b._cine_frame(enemy_id, enemy_id)
	b._kill_hold()
	var skips_before_kill: Dictionary = b._skipped_camera_kinds.duplicate()
	_key_skip()
	_check(b.kill_hold_until < 0.0 and b.cine_saved.is_empty() and b._skipped_camera_kinds == skips_before_kill,
		"K dismisses the kill hold without adding a sticky skip")
	await _playback_checks()
	b.busy = true
	b.start_default()
	_check(b._skipped_camera_kinds.is_empty(), "starting the next battle clears the sticky skips")
	while b.warming:
		await process_frame
	b._end_opening()
	b.queue_free()
	await process_frame
	quit(1 if failures != 0 else 0)


func _restore_settings(previous_settings) -> void:
	# Other checks in the shard share this throwaway profile.
	if previous_settings == null:
		if FileAccess.file_exists(MAIN.SETTINGS_PATH):
			_check(DirAccess.remove_absolute(MAIN.SETTINGS_PATH) == OK, "removed this check's temporary settings")
		return
	var file := FileAccess.open(MAIN.SETTINGS_PATH, FileAccess.WRITE)
	_check(file != null, "restored the settings file for the other checks")
	if file != null:
		file.store_buffer(previous_settings)
		file.close()


func _enemy_volley_batch() -> Dictionary:
	var api = b.api
	for i in 12:
		if api.phase == "player":
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"]:
					api.end_activation(u["id"])
			api.take_events()
		if api.phase != "enemy":
			break
		var events: Array = api.step()
		var view: Dictionary = api.view()
		if events.any(func(e): return e["t"] == "fire" and not e["shots"].is_empty()):
			return {"events": events, "view": view}
		b._sync(view)
	return {}


func _skip_hold(ms: float, skip_at: float) -> void:
	if ms != skip_at:
		return
	var timer: SceneTreeTimer = b._shot_cut_timer
	_check(b.busy and not b.cine_saved.is_empty()
		and timer != null and timer.time_left > 0.0 and timer.time_left <= ms / 1000.0 * b.speed + 0.001,
		"a real enemy volley starts its %d ms hold at battle speed" % int(ms))
	_key_skip()
	_check(b.cine_saved.is_empty() and timer != null and timer.time_left == 0.0,
		"K releases the camera and ends its %d ms hold" % int(ms))


func _playback_checks() -> void:
	b.busy = true
	b.cine = "all"
	b.user_speed = 0.5
	var batch := _enemy_volley_batch()
	_check(not batch.is_empty(), "the rules produce a firing batch during the enemy turn")
	if batch.is_empty():
		return
	var finish_lead := _skip_hold.bind(320.0)
	b.shot_hold_started.connect(finish_lead, CONNECT_DEFERRED)
	b.waits.clear()
	await b._play_batch(batch)
	b.shot_hold_started.disconnect(finish_lead)
	_check(b._skipped_camera_kinds.has("volley") and b.waits.has(320.0) and b.waits.has(900.0),
		"brisk off keeps the 900 ms tail after K ends the lead hold")
	b.waits.clear()
	await b._play_batch(batch)
	_check(not b.waits.has(320.0) and not b.waits.has(900.0), "the next routine volley of the same kind has no cut-in")
	_check(b._cine_wants("torp", "escort", "cruiser") and not b.brisk_camera and not b.skip,
		"the shortcut leaves other shot kinds, the preference and enemy hurry alone")
	b._skipped_camera_kinds.erase("volley")
	var finish_tail := _skip_hold.bind(900.0)
	b.shot_hold_started.connect(finish_tail, CONNECT_DEFERRED)
	await b._play_batch(batch)
	b.shot_hold_started.disconnect(finish_tail)
	_check(b._skipped_camera_kinds.has("volley"), "K also saves the skip when pressed during the tail hold")
