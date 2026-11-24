extends SceneTree
# Issue 1871: keep the pre-brisk cut list, then drive the new choices through the battle camera and its input.
const GUARD := preload("res://tools/ci/check_guard.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const MAIN := preload("res://main/main.gd")
const CAMERA_ROWS := [
	["volley", "cruiser", "escort"], ["lance", "escort", "cruiser"], ["torp", "cruiser", "escort"],
	["nova", "escort", "cruiser"], ["volley", "capital", "low"], ["volley", "capital", "cruiser"],
	["volley", "escort", "low"], ["volley", "capital", "boss"], ["lance", "boss", "escort"],
	["kill", "escort", "escort"], ["kill", "escort", "wing"], ["kill", "escort", "cruiser"],
	["kill", "escort", "capital"], ["kill", "escort", "boss"],
]
const LEGACY_KEY_CUTS := [1, 2, 3, 4, 7, 8, 11, 12, 13]
const LEGACY_ALL_CUTS := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

var b
var failures := 0
var cues: Array[String] = []


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
	root.size = Vector2i(1920, 1080)
	b = BATTLE.instantiate()
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
	main.free()
	b.brisk_camera = false
	b.busy = true
	b.start_default()
	while b.warming:
		await process_frame
	b.busy = false
	b.batches.clear()
	b._end_opening()
	b.speed = 0.2
	var changed := []
	b.option_changed.connect(func(key: String, value: Variant) -> void: changed.append([key, value]))
	b._open_menu()
	var brisk_row: Button
	for row in b.hud.menu.find_children("*", "Button", true, false):
		if row.text == "Brisk camera: off":
			brisk_row = row
			break
	_check(brisk_row != null, "the battle menu offers Brisk camera")
	if brisk_row != null:
		brisk_row.pressed.emit()
		_check(b.brisk_camera and changed == [["brisk_camera", true]], "the battle menu sends the updated preference to settings")
	b.hud.hide_menu()
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
	_check(_cut_list() == [7, 8, 11, 12, 13], "brisk keeps flagship shots and cruiser, capital and flagship kills")
	b.cine = "all"
	_check(_cut_list() == [7, 8, 9, 10, 11, 12, 13], "brisk filters routine shots even in Every attack and keeps its kill cuts")
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
	_check(b.cam.t == board_target and b.cam_saved.is_empty(), "brisk leaves the camera on the board during routine enemy moves")
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

	b.recording_cue.connect(func(kind: String, detail: String) -> void: cues.append(kind + " " + detail))
	var shot := {"unit": "escort", "target": "cruiser", "kind": "lance", "name": "Test lance", "quad": 0, "shots": []}
	(func() -> void:
		_check(not b.cine_saved.is_empty(), "a routine lance starts its cut-in when brisk is off")
		_key_skip()
		_check(b.cine_saved.is_empty() and b._shot_cut_timer != null and b._shot_cut_timer.time_left == 0.0,
			"K releases the camera and ends its lead wait")
	).call_deferred()
	await b._play_fire(shot, [])
	await b._play_fire(shot, [])
	_check(cues == ["cut_start lance: Escort to Cruiser", "cut_end "], "a later routine lance emits no cut-in")
	_check(b._cine_wants("torp", "escort", "cruiser") and b._cine_wants("lance", "boss", "escort"),
		"the sticky lance skip leaves torpedoes and flagship lances available")
	_check(not b.brisk_camera and not b.skip, "the shortcut leaves the preferences and hurry state alone")
	b.busy = true
	b.start_default()
	_check(b._skipped_camera_kinds.is_empty(), "starting the next battle clears the sticky skips")
	while b.warming:
		await process_frame
	b._end_opening()
	b.queue_free()
	await process_frame
	quit(1 if failures != 0 else 0)
