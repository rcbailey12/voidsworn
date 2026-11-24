extends SceneTree
# Issue 1978: the real main scene must keep its battle on screen for the entire --seed / --shots run.
# Run with a window and built hulls. The real capture still refuses to save placeholder hulls.
const GUARD := preload("res://tools/ci/check_guard.gd")
const MAIN := preload("res://main/main.tscn")


func _init() -> void:
	GUARD.arm(self, "quick_battle_shots_check", 600.0)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var cli := OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless" or not cli.has("--seed") or not cli.has("--shots"):
		_fail("requires a window and -- --seed <n> --shots <folder>")
		return
	var started := int(Time.get_unix_time_from_system())
	var main := MAIN.instantiate()
	root.add_child(main)
	current_scene = main
	# Main may defer the battle start past its first draw (issue 1434 prefetch), so wait for it with a deadline,
	# while still failing at once if the title shows up or Main quits first.
	var deadline := Time.get_ticks_msec() + 60000
	while main.battle == null and Time.get_ticks_msec() < deadline:
		if main.title != null or main.showcase != null or main.quitting:
			_fail("title appeared or Main quit before the battle started")
			return
		await process_frame
	var battle: Node = main.battle
	if battle == null or battle.shots_dir.is_empty():
		_fail("Main did not start a seeded battle with a screenshot folder")
		return
	var folder: String = battle.shots_dir
	var saw_end_card := false
	while not main.quitting:
		if main.title != null or main.showcase != null:
			_fail("title appeared during the battle capture")
			return
		if not is_instance_valid(battle) or root.get_camera_3d() != battle.cam or not battle.hud.visible:
			_fail("the battle camera and HUD must own the window until capture quits")
			return
		var end_card: Control = battle.hud.endcard
		saw_end_card = saw_end_card or (is_instance_valid(end_card) and end_card.is_visible_in_tree())
		await process_frame
	var saved_end := false
	for file in DirAccess.get_files_at(folder):
		if file.ends_with("_end.png") and _fresh_png(folder.path_join(file), started):
			saved_end = true
	if not saw_end_card or not saved_end or not _fresh_png(folder.path_join("01_start.png"), started):
		_fail("expected a visible battle end card and a fresh start and end PNG")
		return
	print("PASS: seeded quick battle stayed visible and saved its start and end frames")
	# Main owns the clean exit so this check also exercises capture shutdown.


func _fresh_png(path: String, started: int) -> bool:
	return FileAccess.get_modified_time(path) >= started and Image.load_from_file(path) != null


func _fail(message: String) -> void:
	printerr("FAIL: quick_battle_shots_check: ", message)
	quit(1)
