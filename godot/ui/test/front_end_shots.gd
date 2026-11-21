extends SceneTree
# Issue 1217: pictures of the front-end screens through the real main scene. With --no-showcase no built ships are
# needed (the cloud); without it the script waits for the title battle to fade in (the PC).
# godot --path godot --resolution 1920x1080 --script res://ui/test/front_end_shots.gd -- <out dir> [tag] [--no-showcase]
#   [--only=F5] [--expect=1920x1080]   (--expect: every frame must be that size before the shrink, or the run fails)
# In the cloud run it under xvfb-run with --rendering-driver opengl3. Each picture is 1280x720 with its code name on it.

const UiScale := preload("res://ui/ui_scale.gd")
var out := ""
var tag := ""
var main: Node


var _saved_settings = null   # the settings file's bytes at the start; the capture never writes it, and checks that at the end
var _failed := 0             # pictures that did not save


# On Windows the capture runs only inside the watchdog's throwaway profile (issue 1369; tools/throwaway_profile.gd): the
# real main scene saves the campaign and may save settings, so it must never see Ryan's own profile.
func _profile_error() -> String:
	return preload("res://tools/throwaway_profile.gd").refusal("front_end_shots.gd")


func _initialize() -> void:
	var perr := _profile_error()
	if perr != "":
		printerr("[front-end-shots] FAIL ", perr); quit(2); return
	if FileAccess.file_exists("user://settings.json"):
		_saved_settings = FileAccess.get_file_as_string("user://settings.json")
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
	if _only != "" and not name.begins_with(_only): return   # --only=F5 keeps just one phase's pictures
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
	# a 1080p or 4K slot only counts if the frame really is that size before the 720 high shrink (Artoo on PR 1233:
	# a clamped window once gave two identical "sizes" on the combat capture, PR 1220)
	var want := _expect
	if want != Vector2i.ZERO and Vector2i(img.get_width(), img.get_height()) != want:
		_failed += 1; printerr("[front-end-shots] FAIL ", name, " is ", img.get_width(), "x", img.get_height(), ", not the asked ", want.x, "x", want.y)
	if img.get_height() > 720:
		img.resize(int(round(img.get_width() * 720.0 / img.get_height())), 720, Image.INTERPOLATE_LANCZOS)
	var p := out.path_join(name + ".png")
	var err: Error = preload("res://tools/picture_provenance.gd").save_png(img, p)
	if err != OK: _failed += 1; printerr("[front-end-shots] FAIL could not save ", p, " (", error_string(err), ")")
	else: print("[front-end-shots] saved ", p)
	cap.queue_free()


# Issue 1369 PC run: main starts a fresh profile full screen (settings "fullscreen" defaults to true), so every frame
# came out at the monitor size, 2560x1440, whatever --resolution asked. With --expect, put the window back to that size,
# windowed, the way main's own capture jobs do (_capture_window); a size the window cannot take still fails each shot.
func _hold_window() -> void:
	if _expect == Vector2i.ZERO or DisplayServer.get_name() == "headless": return
	for i in 3:   # main's start-up mode change can land a frame or two later; apply it until it holds
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_expect)
		await process_frame
	await _wait(0.3)
	print("[front-end-shots] window ", DisplayServer.window_get_size(), " viewport ", root.get_viewport().get_visible_rect().size)


# the frame size --expect asked for, or zero. It is a user argument because Godot keeps --resolution to itself
# (OS.get_cmdline_args() never lists it), which left the first version of this check silently passing.
var _expect := Vector2i.ZERO


func _scale(v: float) -> void:
	main.settings["ui_scale"] = v
	UiScale.set_player(v)
	main.title._rebuild()
	await _wait(0.4)


var _only := ""
func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if str(a).begins_with("--only="): _only = str(a).substr(7)
		if str(a).begins_with("--expect="):
			var parts := str(a).substr(9).split("x")
			if parts.size() == 2: _expect = Vector2i(int(parts[0]), int(parts[1]))
	await _wait(1.5)
	await _hold_window()
	# with the showcase battle (the PC, built ships): wait for it to load and fade in behind the title
	if not main.args.has("no-showcase"):
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 120000 and (main.showcase == null or not is_instance_valid(main.showcase) or not main.showcase.showcase_ready):
			await process_frame
		print("[front-end-shots] showcase ", "ready, enemy " + str(main.showcase.args.get("fac", "")) if main.showcase != null and is_instance_valid(main.showcase) else "missing")
		await _wait(4.0)
	var vs := root.get_viewport().get_visible_rect().size
	var res := "%dx%d" % [int(vs.x), int(vs.y)]
	for pair in [[1.0, "normal"], [1.3, "larger"]]:
		await _scale(pair[0])
		var t = main.title
		if t.has_method("_settings"):
			t._settings()
		await _wait(0.6)
		await _shot("F2_settings_%s" % pair[1], "%s, UI scale %s" % [res, "Normal" if pair[0] == 1.0 else "Larger"])
		if t.settings_panel != null:   # closed without saving: the player's own settings file is never written
			t.settings_panel.queue_free(); t.settings_panel = null
			if t.settings_dim != null: t.settings_dim.queue_free(); t.settings_dim = null
		await _wait(0.3)
		await _shot("F2_title_%s" % pair[1], "%s, UI scale %s" % [res, "Normal" if pair[0] == 1.0 else "Larger"])
		if t.has_method("_credits"):
			t._credits(); await _wait(0.6)
			await _shot("F2_credits_%s" % pair[1], "%s, UI scale %s" % [res, "Normal" if pair[0] == 1.0 else "Larger"])
			t._close_credits(); await _wait(0.3)
	await _scale(1.0)
	main.new_run({})
	await _wait(2.0)
	await _shot("F3_setup_normal", "%s, UI scale Normal, faction and admiral" % res)
	var host = main.campaign
	if host != null and "ui" in host and host.ui != null and "C" in host:
		for f in host.C.RUN_FACTIONS:
			host.C.act("pickFaction", f)
			await _wait(0.8)
			await _shot("F3_desk_" + str(f), "%s, UI scale Normal, %s" % [res, str(host.C.FACTIONS[f]["n"])])
		host.C.act("pickFaction", "voidsworn")
		if "desk_opts_open" in host.ui:
			host.ui.desk_opts_open = true; host.ui._dirty = true
			await _wait(0.8)
			await _shot("F3_run_options", "%s, UI scale Normal, Run options drawer" % res)
			# issue 1261: open Run options from the keyboard (focus its button, Accept), then Tab three times: where is the focus?
			host.ui.close_run_options(); await _wait(0.6)
			var rob = host.ui.page_box.find_child("RunOptionsButton", true, false)
			if rob != null: rob.grab_focus()
			for act in ["ui_accept", "WAIT", "ui_focus_next", "ui_focus_next", "ui_focus_next"]:
				if act == "WAIT": await _wait(0.6); continue
				for down in [true, false]:
					var e := InputEventAction.new(); e.action = act; e.pressed = down
					root.push_input(e); await process_frame
			await _wait(0.3)
			var fo = root.gui_get_focus_owner()
			var fo_t = "nothing" if fo == null else (("the " + str(fo.text) + " button") if fo is Button and str(fo.text) != "" else str(fo.name))
			await _shot("F3_run_options_keys", "%s, Run options after 3 Tabs: keyboard focus on %s" % [res, fo_t])
			host.ui.close_run_options()
			await _wait(0.4)
	main.settings["ui_scale"] = 1.3
	UiScale.set_player(1.3)
	root.get_viewport().size_changed.emit()
	await _wait(1.0)
	await _shot("F3_setup_larger", "%s, UI scale Larger, faction and admiral" % res)
	# phase 4: the flagship podium (the live ship turns on the PC; the cloud shows the KEEL silhouette)
	if host != null and "ui" in host and host.ui != null and "aspect_pick" in host.ui:
		host.C.act("startRun"); await _wait(1.5)
		await _shot("F4_flagship_larger", "%s, UI scale Larger, flagship and aspect" % res)
		host.C.act("backToSetup"); await _wait(0.5)
		main.settings["ui_scale"] = 1.0
		UiScale.set_player(1.0)
		root.get_viewport().size_changed.emit()
		await _wait(1.0)
		for f in ["voidsworn", "hegemony", "chorus", "ithar"]:
			host.C.act("pickFaction", f); host.C.act("startRun"); await _wait(2.5)
			await _shot("F4_flagship_" + f, "%s, UI scale Normal, %s flagship" % [res, str(host.C.FACTIONS[f]["n"])])
			if f == "voidsworn":
				host.ui.aspect_pick = str(host.C.W["aspOffer"][0]); host.ui._dirty = true; await _wait(1.0)
				await _shot("F4_flagship_picked", "%s, UI scale Normal, an aspect picked, Launch ready" % res)
			host.C.act("backToSetup"); await _wait(0.5)
		host.C.act("pickFaction", "voidsworn"); await _wait(0.3)
	# phase 5: Progression (each tab), Lineage and Help (never the title act: it hands back to main and ends the campaign)
	if host != null and "ui" in host and host.ui != null:
		host.C.act("legacy"); await _wait(0.8)
		for t in ["variants", "legacy", "mastery", "favour", "heat", "fallen"]:
			host.C.act("progTab", t); await _wait(0.6)
			await _shot("F5_progression_" + t, "%s, UI scale Normal, Progression: %s" % [res, t])
		var tree_id := ""
		for id in host.C.ADMIRALS:
			if host.C.LINEAGE_TREES.has(id): tree_id = str(id); break
		if tree_id != "":
			host.C.act("lineage", tree_id); await _wait(0.8)
			await _shot("F5_lineage", "%s, UI scale Normal, Lineage of %s" % [res, tree_id])
		host.C.act("help"); await _wait(0.8)
		await _shot("F5_help", "%s, UI scale Normal, How to play" % res)
		main.settings["ui_scale"] = 1.3
		UiScale.set_player(1.3)
		root.get_viewport().size_changed.emit()
		await _wait(1.0)
		await _shot("F5_help_larger", "%s, UI scale Larger, How to play" % res)
		host.C.act("legacy"); host.C.act("progTab", "mastery"); await _wait(0.8)
		await _shot("F5_progression_larger", "%s, UI scale Larger, Progression: mastery" % res)
		if tree_id != "":
			host.C.act("lineage", tree_id); await _wait(0.8)
			await _shot("F5_lineage_larger", "%s, UI scale Larger, Lineage of %s" % [res, tree_id])
	main.settings["ui_scale"] = 1.0
	UiScale.set_player(1.0)
	var now = FileAccess.get_file_as_string("user://settings.json") if FileAccess.file_exists("user://settings.json") else null
	if now != _saved_settings:
		_failed += 1; printerr("[front-end-shots] FAIL the settings file changed during the capture")
	print("[front-end-shots] ", "PASS" if _failed == 0 else "FAIL %d problem(s)" % _failed)
	quit(0 if _failed == 0 else 1)
