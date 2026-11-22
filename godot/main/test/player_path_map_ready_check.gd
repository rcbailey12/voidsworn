extends SceneTree
# Issue 1448: the player-path recorder waits for the sector map's loading cover before it jumps. On a fresh Windows
# profile the map was still loading when the recorder pressed Jump, map3d.fly_to dropped it, and every recording failed
# at "jump to 0-0 did not open" (SND1B and LOAD14, Nov 21). This drives the recorder's own _map_ready with a stand-in map.
const PlayerPath := preload("res://main/player_path.gd")
var fails := 0


class FakeMap extends Control:
	var loading := true


class FakeUI extends Node:
	var map3d: Control


class FakeMain extends Node:
	var quit_code := -1
	func quit_clean(c := 0) -> void:
		quit_code = c


func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok:
		fails += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var pp = PlayerPath.new()
	pp.headless = true
	var fm := FakeMain.new()
	root.add_child(fm)
	pp.main = fm
	root.add_child(pp)
	var log_path := OS.get_cache_dir().path_join("player_path_map_ready_check.jsonl")
	pp.report_file = FileAccess.open(log_path, FileAccess.WRITE)
	var ui := FakeUI.new()
	ui.map3d = FakeMap.new()
	ui.add_child(ui.map3d)
	root.add_child(ui)
	# 1. the map is loading: the recorder holds until the cover is gone, then goes on
	var done := [false, false]
	var waiter := func() -> void:
		done[1] = await pp._map_ready(ui)
		done[0] = true
	waiter.call()
	for i in 20:
		await process_frame
	check(not done[0], "while the map is loading the recorder does not jump")
	ui.map3d.loading = false
	await create_timer(1.0).timeout   # the recorder settles 0.5 s after the cover goes
	check(done[0] and done[1], "once the map has loaded the recorder goes on to the jump")
	# 2. a map already loaded (or a 2D map) costs no wait
	var t0 := Engine.get_process_frames()
	var ok: bool = await pp._map_ready(ui)
	check(ok and Engine.get_process_frames() - t0 <= 1, "a loaded map costs no wait")
	# 3. a map that never loads fails the recording with its own reason, never a silent dropped jump
	ui.map3d.loading = true
	pp.map_wait_s = 1   # the real limit is 120 s; one second keeps the check short
	var ok3: bool = await pp._map_ready(ui)
	check(not ok3 and fm.quit_code == 1, "a map still loading past the limit fails the recording with its own reason")
	var text := FileAccess.get_file_as_string(log_path)
	check(text.contains("\"map_ready\"") and text.contains("still loading after 1 s"), "the trace logs the wait and the failure")
	# 4. the Windows launcher gives battle zero one retry for either startup reason (Artoo on b0a57df9): its pattern,
	# read from run.ps1, must match both real trace rows above and below, and never a later battle's failure
	var timeout_row := text.strip_edges().split("\n")[-1]
	pp.report_file = FileAccess.open(log_path, FileAccess.WRITE)
	pp._fail("jump to 0-0 did not open")
	var jump_row := FileAccess.get_file_as_string(log_path).strip_edges()
	pp.battle_number = 1
	pp.report_file = FileAccess.open(log_path, FileAccess.WRITE)
	pp._fail("jump to 1-0 did not open")
	var later_row := FileAccess.get_file_as_string(log_path).strip_edges()
	var ps1 := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../contrib/codex/player_path_1119/run.ps1"))
	var found := RegEx.create_from_string("\\$retryPattern = '((?:[^']|'')*)'").search(ps1)
	check(found != null, "run.ps1 names its retry pattern")
	if found != null:
		var retry := RegEx.create_from_string(found.get_string(1).replace("''", "'"))
		check(retry.search(timeout_row) != null, "the launcher retries a map still loading at battle zero: " + timeout_row)
		check(retry.search(jump_row) != null, "the launcher retries a dropped first jump: " + jump_row)
		check(retry.search(later_row) == null, "the launcher does not retry a later battle's failure")
	DirAccess.remove_absolute(log_path)
	pp.free(); ui.free(); fm.free()
	print("PLAYER PATH MAP READY " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
