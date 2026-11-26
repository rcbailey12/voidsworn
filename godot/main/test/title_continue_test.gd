extends SceneTree

const Main := preload("res://main/main.gd")
const Campaign := preload("res://campaign/campaign.gd")

class TestMain extends Main:
	func _ready() -> void:
		pass

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/godot_checks/xdg/"):
		printerr("FAIL: refusing to write a campaign save outside the game check sandbox")
		quit(1)
		return
	var c := Campaign.new()
	var error := c.load_tables()
	if error != "":
		printerr("FAIL: ", error)
		quit(1)
		return
	c.persist_on = false
	c.fixed_clock = true
	preload("res://rules/jsm.gd").rnd_seed(1124)
	c.META["renown"] = 22
	var profile := c.save_text()
	root.size = Vector2i(1920, 1080)
	var main := TestMain.new()
	main.args["no-tips"] = true
	root.add_child(main)
	_write(c.save_path, profile)
	_write(c.save_path + ".bak", profile)
	await _check_title(main, "New run", "profile-only save")
	main.new_run({"continue": true})
	_check(main.campaign == null and main.title != null, "a stale Continue returns to the title safely")
	for i in 3: await process_frame  # Let the title's deferred layout report finish before replacing it.
	var invalid: Dictionary = JSON.parse_string(profile)
	invalid["run"] = {"fleet": []}
	_write(c.save_path, JSON.stringify(invalid))
	await _check_title(main, "New run", "run rejected by the loader")
	c.titleScreen()
	c.act("newRunScreen")
	c.act("startRun")
	_check(c.page.get("kind") == "aspect", "the migration fixture reaches the aspect page")
	c.act("pickAspect", c.W["aspOffer"][0])   # the map fixture has finished flagship setup
	c.act("saveQuit")
	var old: Dictionary = JSON.parse_string(c.save_text())
	old["run"].erase("v")
	old["run"].erase("mapTrial")
	var old_text := JSON.stringify(old)
	_write(c.save_path + ".bak", old_text)
	await _check_title(main, "Continue run", "resumable backup after rejection")
	_write(c.save_path, old_text)
	await _check_title(main, "Continue run", "old resumable run")
	_check(FileAccess.get_file_as_string(c.save_path) == old_text, "opening the title leaves the old save bytes alone")
	(main.title.menu.get_child(0) as Button).pressed.emit()
	var resumed = main.campaign.C if main.campaign != null else null
	_check(resumed != null and resumed.page.get("kind") == "map" and resumed.RUN["v"] == 2
		and resumed.RUN["fleet"].size() == old["run"]["fleet"].size() and resumed.META["renown"] == 22,
		"the actual Continue button resumes the migrated fleet and profile")
	if main.campaign != null: main.campaign.free()
	main.free()
	if failures == 0: print("PASS: title offers Continue only for a resumable run, and loads an old run")
	quit(0 if failures == 0 else 1)


func _check_title(main: TestMain, first: String, case_name: String) -> void:
	main.show_title()
	for i in 3: await process_frame
	var button := main.title.menu.get_child(0) as Button
	_check(button.text == first and button.has_focus(), "%s should show and focus %s, got %s" % [case_name, first, button.text])


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	_check(f != null, "could not write isolated fixture " + path)
	if f != null:
		f.store_string(text)
		f.close()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)
