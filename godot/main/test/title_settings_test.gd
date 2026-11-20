extends SceneTree

const Main := preload("res://main/main.gd")
const UiScale := preload("res://ui/ui_scale.gd")

class TestMain extends Main:
	var saves := 0
	func _ready() -> void:
		pass
	func save_settings() -> void:
		saves += 1
		super.save_settings()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# The game check runner supplies this isolated user directory.
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/godot_checks/xdg/"):
		printerr("FAIL: refusing to write settings outside the game check sandbox")
		quit(1)
		return
	# Issue 1079 (Artoo on PR 1330): a settings file saved by the off-by-default build carries "nebula_wake": false;
	# loading it must leave the wake on and drop the old key.
	var old := FileAccess.open(Main.SETTINGS_PATH, FileAccess.WRITE)
	old.store_string('{"quality":"max","nebula_wake":false}')
	old.close()
	var mig := TestMain.new()
	mig._load_settings()
	if mig.settings.has("nebula_wake") or not bool(mig.settings.get("nebula_wake_on", false)):
		printerr("FAIL: an old saved nebula_wake false kept the wake off (%s)" % [mig.settings])
		quit(1)
		return
	mig.free()
	var f := FileAccess.open(Main.SETTINGS_PATH, FileAccess.WRITE)
	if f == null:
		printerr("FAIL: could not write the old settings fixture")
		quit(1)
		return
	f.store_string('{"sound":true,"quality":"max","volume":0.35}')
	f.close()
	root.size = Vector2i(1920, 1080)
	var main := TestMain.new()
	root.add_child(main)
	main._load_settings()
	main.show_title()
	main.title._settings()
	for i in 3: await process_frame
	var sound := _row_button(main.title.settings_panel, "Sound")
	var quality := _row_button(main.title.settings_panel, "Graphics")
	var ui_scale := _row_button(main.title.settings_panel, "UI scale")
	var ok := sound != null and quality != null and ui_scale != null
	if ok:
		sound.pressed.emit()
		ok = sound.text == "Off" and main.saves == 1
		quality.pressed.emit()
		ok = quality.text == "High" and main.saves == 2 and ok
		ui_scale.pressed.emit()
		var restored := Main.new()
		restored._load_settings()
		var scale_after := _row_button(main.title.settings_panel, "UI scale")
		ok = ok and main.saves == 3 and not restored.settings["sound"] and restored.settings["quality"] == "high"
		ok = ok and is_equal_approx(float(restored.settings["volume"]), 0.35) and is_equal_approx(UiScale.player, 1.15)
		ok = ok and scale_after != null and scale_after.text == "Large"
		restored.free()
	for i in 3: await process_frame  # Let the title and its rebuild finish their layout reports.
	main.free()
	if ok: print("PASS: title settings update their labels, save each press, and apply UI scale live; an old nebula_wake false no longer keeps the wake off")
	else: printerr("FAIL: a title setting did not update, save, or apply on press")
	quit(0 if ok else 1)


func _row_button(panel: Control, label: String) -> Button:
	for item in panel.find_children("*", "Label", true, false):
		if item.text == label:
			return item.get_parent().get_child(1) as Button
	return null
