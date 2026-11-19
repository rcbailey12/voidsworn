extends SceneTree

const Title := preload("res://main/title.gd")

class MainSpy extends Node:
	var settings := {"sound": true, "quality": "max"}
	var saves := 0

	func save_settings() -> void:
		saves += 1


func _initialize() -> void:
	var main := MainSpy.new()
	var title := Title.new()
	title.main = main
	title.font = FontFile.new()
	var toggle: Control = title._toggle("Sound", "sound")
	var choice: Control = title._choice("Graphics", "quality", [["max", "Max"], ["high", "High"]])
	var sound_button: Button = toggle.get_child(1)
	var quality_button: Button = choice.get_child(1)
	sound_button.pressed.emit()
	quality_button.pressed.emit()
	var sound_ok: bool = sound_button.text == "Off" and not main.settings.sound
	var quality_ok: bool = quality_button.text == "High" and main.settings.quality == "high"
	var saves_ok := main.saves == 2
	if not sound_ok or not quality_ok or not saves_ok:
		printerr("FAIL: Sound=%s (%s), Graphics=%s (%s), saves=%d; expected Off, High, 2 saves" % [
			sound_button.text, main.settings.sound, quality_button.text, main.settings.quality, main.saves])
	toggle.free()
	choice.free()
	title.free()
	main.free()
	quit(0 if sound_ok and quality_ok and saves_ok else 1)
