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
	old.store_string('{"quality":"max","nebula_wake":false,"taa":true}')
	old.close()
	var mig := TestMain.new()
	mig._load_settings()
	if mig.settings.has("nebula_wake") or not bool(mig.settings.get("nebula_wake_on", false)):
		printerr("FAIL: an old saved nebula_wake false kept the wake off (%s)" % [mig.settings])
		quit(1)
		return
	if mig.settings.get("battle_aa") != "taa":
		printerr("FAIL: an old Temporal AA preference did not carry over to Battle AA")
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
	var wake := _row_button(main.title.settings_panel, "Nebula wakes (ships stir the clouds)")
	var ok := sound != null and quality != null and ui_scale != null and wake != null
	# Issue 1504 (R355): the nebula wake is on by default and the player can turn it off; the choice survives a restart
	ok = ok and wake.text == "On"
	if ok:
		sound.pressed.emit()
		ok = sound.text == "Off" and main.saves == 1
		quality.pressed.emit()
		ok = quality.text == "High" and main.saves == 2 and ok
		ui_scale.pressed.emit()
		wake.pressed.emit()
		ok = ok and wake.text == "Off" and main.saves == 4
		var restored := Main.new()
		restored._load_settings()
		var scale_after := _row_button(main.title.settings_panel, "UI scale")
		ok = ok and main.saves == 4 and not restored.settings["sound"] and not bool(restored.settings.get("nebula_wake_on", true)) and restored.settings["quality"] == "high"
		ok = ok and is_equal_approx(float(restored.settings["volume"]), 0.35) and is_equal_approx(UiScale.player, 1.15)
		ok = ok and scale_after != null and scale_after.text == "Large"
		restored.free()
	# Issue 1559 item 23: dragging a volume slider saves once, when the drag ends; a key step still saves at once
	var vol: HSlider = null
	if main.title.settings_panel != null and is_instance_valid(main.title.settings_panel):
		for sl in main.title.settings_panel.find_children("*", "HSlider", true, false):
			if str(sl.get_meta("setting_key", "")) == "volume":
				vol = sl
	var drag_ok := vol != null
	if drag_ok:
		var n0: int = main.saves
		vol.drag_started.emit()
		for v in [0.5, 0.55, 0.6, 0.65]:
			vol.value = v
		drag_ok = main.saves == n0 and is_equal_approx(float(main.settings["volume"]), 0.65)
		vol.drag_ended.emit(true)
		drag_ok = drag_ok and main.saves == n0 + 1
		vol.value = 0.7   # a key step
		drag_ok = drag_ok and main.saves == n0 + 2
		var back := Main.new()
		back._load_settings()
		drag_ok = drag_ok and is_equal_approx(float(back.settings["volume"]), 0.7)
		back.free()
	print(("PASS" if drag_ok else "FAIL") + ": a volume drag saves once when it ends, a key step saves at once (issue 1559 item 23)")
	ok = ok and drag_ok
	for i in 3: await process_frame  # Let the title and its rebuild finish their layout reports.
	main.free()
	if ok: print("PASS: title settings update their labels, save each press, and apply UI scale live; an old nebula_wake false no longer keeps the wake off; the Nebula wakes toggle starts on and its Off survives a restart")
	else: printerr("FAIL: a title setting did not update, save, or apply on press")
	quit(0 if ok else 1)


func _row_button(panel: Control, label: String) -> Button:
	for item in panel.find_children("*", "Label", true, false):
		if item.text == label:
			return item.get_parent().get_child(1) as Button
	return null
