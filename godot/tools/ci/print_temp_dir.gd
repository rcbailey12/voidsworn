# The shell runner must use the same temp root as the onboarding profile guard.
extends SceneTree


func _init() -> void:
	print("GODOT_TEMP_DIR=", OS.get_temp_dir().replace("\\", "/").simplify_path())
	quit()
