extends SceneTree
# Issue 1217: pictures of the front-end screens through the real main scene (no showcase battle, no built ships needed).
# godot --path godot --resolution 1920x1080 --script res://ui/test/front_end_shots.gd -- <out dir> [tag] [--no-showcase]
# In the cloud run it under xvfb-run with --rendering-driver opengl3. Each picture is 1280x720 with its code name on it.

const UiScale := preload("res://ui/ui_scale.gd")
var out := ""
var tag := ""
var main: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else "user://front_end_shots"
	tag = a[1] if a.size() > 1 and not str(a[1]).begins_with("--") else ""
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://main/main.tscn").instantiate()
	root.add_child(main)
	_run.call_deferred()


func _wait(sec: float) -> void:
	await create_timer(sec).timeout
	await process_frame
	await RenderingServer.frame_post_draw


func _shot(name: String, caption: String) -> void:
	var cap := CanvasLayer.new()
	cap.layer = 120
	var l := Label.new()
	l.text = name + "   " + caption + ("   " + tag if tag != "" else "")
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(12, 8)
	cap.add_child(l)
	root.add_child(cap)
	await _wait(0.2)
	var img := root.get_viewport().get_texture().get_image()
	if img.get_height() > 720:
		img.resize(int(round(img.get_width() * 720.0 / img.get_height())), 720, Image.INTERPOLATE_LANCZOS)
	var p := out.path_join(name + ".png")
	img.save_png(p)
	print("[front-end-shots] saved ", p)
	cap.queue_free()


func _scale(v: float) -> void:
	main.settings["ui_scale"] = v
	UiScale.set_player(v)
	main.title._rebuild()
	await _wait(0.4)


func _run() -> void:
	await _wait(1.5)
	var vs := root.get_viewport().get_visible_rect().size
	var res := "%dx%d" % [int(vs.x), int(vs.y)]
	for pair in [[1.0, "normal"], [1.3, "larger"]]:
		await _scale(pair[0])
		var t = main.title
		if t.has_method("_settings"):
			t._settings()
		await _wait(0.6)
		await _shot("F1_settings_%s" % pair[1], "%s, UI scale %s" % [res, "Normal" if pair[0] == 1.0 else "Larger"])
		if t.has_method("_close_settings"):
			t._close_settings()
		elif t.settings_panel != null:
			t.settings_panel.queue_free(); t.settings_panel = null
			if t.settings_dim != null: t.settings_dim.queue_free(); t.settings_dim = null
		await _wait(0.3)
		await _shot("F1_title_%s" % pair[1], "%s, UI scale %s" % [res, "Normal" if pair[0] == 1.0 else "Larger"])
	await _scale(1.0)
	main.new_run({})
	await _wait(2.0)
	await _shot("F1_setup_normal", "%s, UI scale Normal, faction and admiral" % res)
	main.settings["ui_scale"] = 1.3
	UiScale.set_player(1.3)
	root.get_viewport().size_changed.emit()
	await _wait(1.0)
	await _shot("F1_setup_larger", "%s, UI scale Larger, faction and admiral" % res)
	main.settings["ui_scale"] = 1.0
	UiScale.set_player(1.0)
	quit(0)
