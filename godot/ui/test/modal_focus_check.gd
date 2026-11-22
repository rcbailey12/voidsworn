extends SceneTree
# Issue 1559 (menus audit, common causes A and C): overlays are modal for the keyboard, through the one shared trap
# (ui/theme/modal_focus.gd). Headless, mouse and keyboard through the engine's own input path where it matters.
#   1. the trap itself: focus goes in on open, a control behind cannot keep it, two overlays stack (the newer one traps),
#      closing each hands focus back to what had it;
#   2. the orders kit drawer (title Settings and Credits, the desk's Run options) is trapped (item 22);
#   3. Career over a title button: focus starts on Close, a title rebuild that grabs its first button is put back inside
#      (item 15), a second open gives the open Career (item 14), Esc closes it and the title button has focus again (4);
#   4. Career over the Progression page: Esc closes Career and leaves the page where it was (item 5);
#   5. after a dialog closes on the campaign map, keyboard focus goes to the map again, not to a button on its way out
#      (item 6, the render's queue_free race).
# Prints PASS or FAIL lines; exit 0 when all pass.
# Run: godot --headless --path godot --script res://ui/test/modal_focus_check.gd
const ModalFocus := preload("res://ui/theme/modal_focus.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const StoryScript = preload("res://story/story.gd")
var fails := 0


class FakeStory extends RefCounted:
	var C = null
	func flagship_name() -> String:
		return "Long Watch"
	func rename_flagship(_n: String) -> void:
		pass


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _frames(n := 3) -> void:
	for i in n:
		await process_frame


func _key(code: int) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)
		await process_frame


func _focus() -> Control:
	return root.gui_get_focus_owner()


func _in(panel: Node) -> bool:
	var f := _focus()
	return f != null and is_instance_valid(panel) and (f == panel or panel.is_ancestor_of(f))


func _button(parent: Node, text: String) -> Button:
	var b := Button.new()
	b.text = text
	parent.add_child(b)
	return b


func _panel(name: String) -> VBoxContainer:
	var p := VBoxContainer.new()
	p.name = name
	_button(p, name + " one")
	_button(p, name + " two")
	return p


func _run() -> void:
	root.size = Vector2i(1920, 1080)   # the design screen (headless starts at 64 x 64)
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)
	# 1. the trap
	var behind := _button(host, "behind")
	behind.grab_focus()
	await _frames()
	var a := _panel("A")
	host.add_child(a)
	ModalFocus.attach(a)
	await _frames()
	_check(_in(a), "the trap: focus goes into the overlay when it opens")
	behind.grab_focus()
	await _frames()
	_check(_in(a), "the trap: a control behind cannot keep the keyboard")
	await _key(KEY_TAB)
	await _key(KEY_TAB)
	await _key(KEY_TAB)
	_check(_in(a), "the trap: Tab walks round inside the overlay")
	var b := _panel("B")
	host.add_child(b)
	ModalFocus.attach(b)
	await _frames()
	_check(_in(b), "the trap: a second overlay on top takes the keyboard")
	(a.get_child(0) as Control).grab_focus()
	await _frames()
	_check(_in(b), "the trap: only the newest overlay holds it")
	b.queue_free()
	await _frames()
	_check(_in(a), "the trap: closing the top overlay hands focus back to the one under it")
	a.queue_free()
	await _frames()
	_check(_focus() == behind, "the trap: closing the last overlay hands focus back to what had it")
	# 2. the kit drawer
	var dr := Kit.drawer(host, 1.0, 400.0, false)
	_button(dr, "drawer button")
	await _frames()
	_check(_in(dr), "drawer: focus goes into the drawer")
	behind.grab_focus()
	await _frames()
	_check(_in(dr), "drawer: the screen behind cannot take the keyboard (item 22)")
	dr.queue_free()
	await _frames()
	_check(_focus() == behind, "drawer: closing it hands focus back")
	# 3. Career over a title button
	var title_btn := _button(host, "New run")
	title_btn.grab_focus()
	await _frames()
	var career = StoryScript.open_standalone(host)
	await _frames()
	_check(career != null, "Career opens")
	if career != null:
		var close: Control = career.find_child("Close", true, false)
		_check(close != null and _focus() == close, "Career: focus starts on Close (item 4)")
		title_btn.grab_focus()   # what title.gd _rebuild does after a window resize
		await _frames()
		_check(_in(career), "Career: a title rebuild that grabs its first button is put back inside (item 15)")
		var story: Node = career.story
		_check(story.open_career() == career, "Career: a second open gives the open Career (item 14)")
		# item 28: a window resize lays Career out again at the new scale, on the same tab, keyboard on the same control
		career.set_tab("medals")
		var tab_b: Control = career.find_child("medals", true, false)
		if tab_b != null:
			tab_b.grab_focus()
		await _frames()
		var k0: float = career.k
		root.size = Vector2i(1280, 720)
		await create_timer(0.4).timeout
		await _frames()
		var fo := _focus()
		_check(absf(career.k - k0) > 0.01 and career.tab == "medals" and fo != null and _in(career) and str(fo.name) == "medals",
			"Career: a resize lays it out at the new scale on the same tab, keyboard on the same tab button (item 28; k %.2f to %.2f, focus %s)" % [k0, career.k, str(fo.name) if fo else "none"])
		var close2: Control = career.find_child("Close", true, false)
		_check(close2 != null and close2.custom_minimum_size.x < 288.0 * k0 - 1.0, "Career: its Close button shrank with the window (item 28)")
		root.size = Vector2i(1920, 1080)
		await create_timer(0.4).timeout
		await _frames()
		_check(_in(career), "Career: the keyboard is still inside after resizing back")
		await _key(KEY_ESCAPE)
		await _frames()
		_check(not is_instance_valid(career) or career.is_queued_for_deletion(), "Career: Esc closes it")
		_check(_focus() == title_btn, "Career: the title button has the keyboard again")
	# item 28: the rename dialog keeps the name typed so far through a resize, laid out at the new scale
	var rn = load("res://ui/career/rename_dialog.gd").new()
	host.add_child(rn)
	rn.open(FakeStory.new())
	await _frames()
	rn.edit.text = "Half typed"
	rn.edit.caret_column = 4
	var rk0: float = rn.k
	root.size = Vector2i(1280, 720)
	await create_timer(0.4).timeout
	await _frames()
	_check(absf(rn.k - rk0) > 0.01 and rn.edit.text == "Half typed" and rn.edit.caret_column == 4 and _focus() == rn.edit,
		"rename: a resize lays it out at the new scale and keeps the typed name, caret and keyboard (item 28)")
	root.size = Vector2i(1920, 1080)
	await create_timer(0.4).timeout
	rn._close()
	await _frames()
	# 4 and 5: the campaign pages
	var C = Campaign.new()
	var err = C.load_tables()
	if err != "":
		_check(false, "campaign tables load: " + err)
		quit(1)
		return
	C.persist_on = false
	C.fixed_clock = true
	C.teaching_tips = false
	var page_host := Node.new()
	page_host.name = "CampaignHost"
	root.add_child(page_host)
	var st = StoryScript.new()
	st.name = "Story"
	page_host.add_child(st)
	var ui = UI.new()
	page_host.add_child(ui)
	ui.bind(C)
	ui.use_3d_map = false
	st.attach(C, false)
	C.act("legacy", "")
	await _frames(6)
	var kind_before := str(C.page.get("kind", ""))
	_check(kind_before == "legacy", "Progression page is up (%s)" % kind_before)
	var c2 = st.open_career()
	await _frames()
	await _key(KEY_ESCAPE)
	await _frames(4)
	_check(not is_instance_valid(c2) or c2.is_queued_for_deletion(), "Progression: Esc closes Career (item 5)")
	_check(str(C.page.get("kind", "")) == kind_before, "Progression: the page behind stays where it was (item 5, was %s)" % str(C.page.get("kind", "")))
	# 5. a dialog closes: focus goes to a live control of the new render, never to one queued for deletion
	ui.render()
	await _frames(1)
	var fo := _focus()
	_check(fo == null or not _queued_up(fo), "after a render: focus is not on a control on its way out (item 6)")
	ui.render()
	ui.render()
	await _frames(2)
	fo = _focus()
	_check(fo != null and is_instance_valid(fo) and not _queued_up(fo) and fo.is_inside_tree(), "after chained renders: a live control has the keyboard (item 6)")
	print("MODAL_FOCUS fails=%d" % fails)
	quit(1 if fails else 0)


func _queued_up(n: Node) -> bool:
	var p := n
	while p != null:
		if p.is_queued_for_deletion():
			return true
		p = p.get_parent()
	return false
