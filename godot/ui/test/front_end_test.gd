extends SceneTree
# Issue 1217 phase 1: the orders kit and the front-end fixes, headless.
#   - kit labels wrap inside their container and a short one keeps its width; kit buttons play their cue on press;
#   - Esc closes Settings (saving) and Credits on the title; changing the UI scale keeps focus on that row; Settings fits
#     the window at Larger with no scroll; every settings name wraps; the toast grows up from a fixed bottom gap; Credits
#     names every font the game ships;
#   - Esc goes Back on the faction and admiral page, Progression, Help and Lineage, and is harmless on the aspect page;
#     a campaign Back button plays the back cue; at Larger every admiral card keeps its width (no name widens it);
#   - the faction music preview picks each faction's own track.
const Kit := preload("res://ui/theme/orders_kit.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const Title := preload("res://main/title.gd")
const Campaign := preload("res://campaign/campaign.gd")
const UI := preload("res://ui/campaign/campaign_ui.gd")
var fails := 0


class FakeSound extends Node:
	var heard: Array = []
	func play(n: String, _o := {}) -> void:
		heard.append(n)


class FakeMusic extends Node:
	var music = self
	var previews := []
	func play_faction_preview(fac: String) -> void: previews.append(fac)


class FakeMain extends Node:
	var settings := {"volume": 0.8, "sound": true, "reduce_flashing": false, "shake": 1.0, "speed": 1.0, "tips": true, "fullscreen": true, "quality": "max", "ai": "standard", "follow": true, "music": true, "music_volume": 0.7, "cine": "key", "movement": "cinematic", "taa": false, "ui_scale": 1.0, "reduce_motion": false}
	var args := {}
	var saves := 0
	func has_campaign() -> bool: return false
	func campaign_has_save() -> bool: return false
	func save_settings() -> void:
		saves += 1
		UiScale.set_player(settings["ui_scale"])
	func new_run(_o := {}) -> void: pass
	func quick_battle() -> void: pass
	func quit_clean(_c := 0) -> void: pass


func check(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else: fails += 1; printerr("FAIL: " + message)


func frames(n := 3) -> void:
	for i in n: await process_frame


# one press and release of an input action, through the real GUI (focus moves, Accept presses the focused button)
func press(action: String) -> void:
	for down in [true, false]:
		var e := InputEventAction.new(); e.action = action; e.pressed = down
		root.push_input(e)
		await process_frame


func esc() -> InputEventKey:
	var e := InputEventKey.new(); e.keycode = KEY_ESCAPE; e.physical_keycode = KEY_ESCAPE; e.pressed = true
	return e


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
	var snd := FakeSound.new(); root.add_child(snd); Kit.sound = snd
	await kit_checks(snd)
	await title_checks(snd)
	await campaign_checks(snd)
	music_checks()
	showcase_checks()
	Kit.sound = null; UiScale.set_player(1.0)
	print("Front end: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)


func kit_checks(snd: FakeSound) -> void:
	var box := VBoxContainer.new(); box.size = Vector2(200, 400); box.custom_minimum_size.x = 200; root.add_child(box)
	var long := Kit.label("Temporal AA (smoother edges, softer motion) and a few more words to be sure", 18, 1.0)
	var short := Kit.label("Sound", 18, 1.0)
	var row := HBoxContainer.new(); box.add_child(row); row.add_child(short)
	box.add_child(long)
	await frames()
	check(long.size.x <= 201.0 and long.get_line_count() > 1, "a long kit label wraps inside a 200 px column (%d px, %d lines)" % [int(long.size.x), long.get_line_count()])
	check(short.get_line_count() == 1 and short.size.x >= Kit.body_font().get_string_size("Sound", HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x, "a short kit label keeps its natural width on one line")
	box.queue_free()
	for pair in [["primary", "ui_confirm"], ["quiet", "ui_click"], ["back", "ui_cancel"]]:
		snd.heard.clear()
		var b := Kit.button("Go", 1.0, pair[0])
		b.pressed.emit()
		check(snd.heard == [pair[1]], "a %s kit button plays %s on press" % [pair[0], pair[1]])
		b.free()
	snd.heard.clear()
	var l := Kit.link("Credits", 1.0)
	l.mouse_entered.emit(); l.pressed.emit()
	check(snd.heard == ["ui_select", "ui_click"], "a kit link plays the hover cue, then the press cue")
	l.free()


func title_checks(snd: FakeSound) -> void:
	var m := FakeMain.new(); root.add_child(m)
	m.settings["ui_scale"] = 1.3; UiScale.set_player(1.3)
	var t := Title.new(); t.main = m; root.add_child(t)
	await frames()
	var vs := Vector2(root.size)
	t._settings(); await frames(5)
	await create_timer(0.35).timeout   # the drawer's slide
	var pr: Rect2 = t.settings_panel.get_global_rect()
	check(absf(pr.end.x - vs.x) <= 1.0 and pr.position.y <= 1.0 and absf(pr.end.y - vs.y) <= 1.0, "Settings is a full-height drawer on the right edge (%s)" % str(pr))
	var screen := Rect2(Vector2.ZERO, vs).grow(0.5)
	check(screen.encloses(pr), "Settings fits the 1920x1080 window at Larger (bottom %d)" % int(pr.end.y))
	check(t.settings_dim.color.a <= 0.5, "the dim behind a drawer is light (%.2f), so the battle stays in view" % t.settings_dim.color.a)
	var sc: ScrollContainer = t.settings_panel.find_children("*", "ScrollContainer", true, false)[0]
	check(sc.get_v_scroll_bar().max_value <= sc.size.y + 1.0, "Settings needs no scrolling at Larger")
	var unwrapped := 0; var rows := 0
	for r in t.settings_panel.find_children("*", "HBoxContainer", true, false):
		if r.has_meta("row_label"):
			rows += 1
			var lb: Label = r.get_child(0)
			if lb.autowrap_mode == TextServer.AUTOWRAP_OFF or lb.get_global_rect().end.x > r.get_child(1).get_global_rect().position.x: unwrapped += 1
	check(rows == 21 and unwrapped == 0, "all 21 settings names (issue 1437 added Render scale, Frame cap and V-Sync) wrap and stay clear of their control (%d rows, %d bad)" % [rows, unwrapped])
	var xs := {}
	for c in t.settings_panel.find_children("*", "Control", true, false):
		if c.has_meta("setting_key"): xs[int(round(c.size.x))] = true
	check(xs.size() == 1, "every settings control is one width (%s)" % str(xs.keys()))
	# the UI scale row keeps focus through the rebuild
	var us: Button = null
	for c in t.settings_panel.find_children("*", "Button", true, false):
		if c.get_meta("setting_key", "") == "ui_scale": us = c
	us.grab_focus(); us.pressed.emit(); await frames(6)
	var fo := root.gui_get_focus_owner()
	check(fo != null and fo.get_meta("setting_key", "") == "ui_scale" and t.settings_panel != null, "changing the UI scale keeps focus on the UI scale row")
	check(str(m.settings["ui_scale"]) == "0.9", "the UI scale cycled from Larger to Small")
	# Esc closes and saves Settings
	var saves := m.saves; snd.heard.clear()
	t._unhandled_input(esc()); await frames()
	check(t.settings_panel == null and t.settings_dim == null and m.saves == saves + 1, "Esc closes Settings and saves")
	check(snd.heard.has("ui_cancel"), "Esc on Settings plays the back cue")
	# phase 2 title: one ember action first, every other entry a quiet link, all in the left column
	var kids: Array = t.menu.get_children().filter(func(c): return c is Button)
	var primaries := 0
	for b in kids:
		if b.get_meta("kit_sound", "") == "primary": primaries += 1
	check(kids.size() >= 6 and kids[0].get_meta("kit_sound", "") == "primary" and primaries == 1, "the title has exactly one ember action, first (%d entries)" % kids.size())
	check(t.menu.get_global_rect().end.x < vs.x * 0.45, "the title menu stays in the left column")
	# a click on the dim closes a drawer like Esc
	t._settings(); await frames()
	var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true
	t.settings_dim.gui_input.emit(click); await frames()
	check(t.settings_panel == null, "a click beside the Settings drawer closes it")
	# Credits: Esc closes it, and it names every font the game ships
	t._credits(); await frames()
	var text := t.credits_bbcode()
	var missing: Array = []
	for f in Kit.FONT_FACES: if not text.contains(f) or not FileAccess.file_exists(Kit.FONT_FACES[f]): missing.append(f)
	for d in Kit.FONT_DIRS:
		for fn in DirAccess.get_files_at(d):
			if not fn.ends_with(".ttf"): continue
			var covered := false
			for f in Kit.FONT_FACES: if fn.begins_with(str(f).replace(" ", "")): covered = true
			if not covered: missing.append(fn)
	check(missing.is_empty() and not text.contains("Oxanium and Barlow Semi Condensed (SIL"), "Credits names every shipped font (missing: %s)" % str(missing))
	t._unhandled_input(esc()); await frames()
	check(t.credits_panel == null and t.settings_dim == null, "Esc closes Credits")
	# the toast grows upwards from its bottom gap
	m.settings["ui_scale"] = 1.3; UiScale.set_player(1.3); t._rebuild(); await frames()
	t.toast("A long notice that has to wrap onto a second and a third line at the larger interface scale, so it shows how the toast grows when it holds more words than one line")
	await frames()
	var tr: Rect2 = t.toast_lbl.get_global_rect()
	check(t.toast_lbl.grow_vertical == Control.GROW_DIRECTION_BEGIN and tr.end.y <= vs.y - 1 and t.toast_lbl.get_line_count() > 1, "a wrapped toast grows up and stays on screen (bottom %d of %d)" % [int(tr.end.y), int(vs.y)])
	t.queue_free(); m.queue_free(); UiScale.set_player(1.0)
	await frames()


func campaign_checks(snd: FakeSound) -> void:
	var C = Campaign.new(); var err = C.load_tables()
	if err != "": check(false, "campaign tables load: " + err); return
	C.persist_on = false; C.fixed_clock = true; C.teaching_tips = false
	UiScale.set_player(1.3)
	var ui = UI.new(); root.add_child(ui); ui.bind(C); ui.use_3d_map = false
	await frames()
	C.act("newRunScreen"); await frames(4)
	check(str(C.page["kind"]) == "admiral", "the setup page opens")
	var mus := FakeMusic.new(); mus.name = "Main"; root.add_child(mus); await frames()
	var bad := []
	for fac in C.RUN_FACTIONS:
		C.act("pickFaction", str(fac)); await frames(3)
		var tops := {}; var bots := {}; var ws := {}
		for cd in ui._desk_cards:
			var r: Rect2 = (cd as Control).get_global_rect()
			tops[int(round(r.position.y))] = true; bots[int(round(r.end.y))] = true; ws[int(round(r.size.x))] = true
		var sc: ScrollContainer = null
		for n in ui.page_box.find_children("*", "ScrollContainer", true, false): sc = n; break
		var fits: bool = sc != null and sc.get_v_scroll_bar().max_value <= sc.size.y + 1.0
		if ui._desk_cards.is_empty() or bots.size() > tops.size() or ws.size() != 1 or not fits:
			bad.append("%s(cards %d, rows %d, bottoms %d, widths %s, fits %s)" % [fac, ui._desk_cards.size(), tops.size(), bots.size(), str(ws.keys()), str(fits)])
	check(bad.is_empty(), "at Larger every faction's desk fits with no scroll and its admiral cards line up: one width, one bottom per row (%s)" % str(bad))
	check(mus.previews.size() >= C.RUN_FACTIONS.size() - 1 and mus.previews.has(str(C.picked_faction)), "picking a faction plays its music preview (%s)" % str(mus.previews))
	root.size = Vector2i(1280, 1024); ui._dirty = true; await frames(4)   # a 5:4 window at Larger is the tightest 831-tall case
	var sc5: ScrollContainer = null
	for n in ui.page_box.find_children("*", "ScrollContainer", true, false): sc5 = n; break
	var over := -1.0
	if sc5 != null: over = sc5.get_v_scroll_bar().max_value - sc5.size.y
	check(sc5 != null and over <= 1.0, "at Larger the desk also fits a 1280x1024 window with no scroll (over by %d px)" % int(over))
	root.size = Vector2i(1920, 1080); ui._dirty = true; await frames(4)
	# issue 1261: Run options opened by keyboard holds the focus; Tab and Accept never reach the desk behind it; Esc closes
	# it and the focus goes back to Run options
	var ro_btn: Control = ui.page_box.find_child("RunOptionsButton", true, false)
	if ro_btn != null: ro_btn.grab_focus()
	await frames()
	await press("ui_accept"); await frames(4)
	var dr: Node = ui.page_box.find_child("RunOptionsDrawer", true, false)
	var fo: Control = root.gui_get_focus_owner()
	check(ui.desk_opts_open and dr != null and fo != null and dr.is_ancestor_of(fo), "Accept on Run options opens the drawer and focus starts inside it (%s)" % (str(fo.name) if fo != null else "none"))
	var fac_before := str(C.picked_faction); var adm_before := str(C.picked_admiral); var escaped := []
	for i in 24:
		await press("ui_focus_next"); await frames(2)
		dr = ui.page_box.find_child("RunOptionsDrawer", true, false); fo = root.gui_get_focus_owner()
		if dr == null or fo == null or not dr.is_ancestor_of(fo): escaped.append(str(fo.name) if fo != null else "none")
	for i in 6:
		await press("ui_focus_prev"); await frames(2)
		dr = ui.page_box.find_child("RunOptionsDrawer", true, false); fo = root.gui_get_focus_owner()
		if dr == null or fo == null or not dr.is_ancestor_of(fo): escaped.append(str(fo.name) if fo != null else "none")
	check(escaped.is_empty(), "Tab and Shift+Tab stay inside the open drawer (left it for %s)" % str(escaped))
	ui.page_box.find_child("MapTrialToggle", true, false).grab_focus(); await frames()
	var trial0: bool = C.map_trial_choice
	await press("ui_accept"); await frames(4)
	dr = ui.page_box.find_child("RunOptionsDrawer", true, false); fo = root.gui_get_focus_owner()
	check(C.map_trial_choice != trial0 and dr != null and fo != null and str(fo.name) == "MapTrialToggle", "Accept inside the drawer changes its option and the focus stays on that control after the redraw (%s)" % (str(fo.name) if fo != null else "none"))
	if C.map_trial_choice != trial0: C.act("optMapTrial", "1" if trial0 else "0"); await frames(3)
	check(str(C.picked_faction) == fac_before and str(C.picked_admiral) == adm_before and str(C.page["kind"]) == "admiral", "nothing on the desk behind the drawer was pressed")
	var ro_open: bool = ui.desk_opts_open
	ui._unhandled_input(esc()); await frames(4)
	fo = root.gui_get_focus_owner()
	check(ro_open and not ui.desk_opts_open and str(C.page["kind"]) == "admiral" and fo != null and str(fo.name) == "RunOptionsButton",
		"Esc closes the Run options drawer first, stays on the desk, and gives focus back to Run options (%s)" % (str(fo.name) if fo != null else "none"))
	mus.queue_free()
	var back: Button = null
	for b in ui.page_box.find_children("*", "Button", true, false):
		if (b as Button).text == "Back": back = b
	snd.heard.clear()
	var found_back := back != null
	if found_back: back.pressed.emit()
	await frames()
	check(found_back and snd.heard.has("ui_cancel") and str(C.page["kind"]) == "title", "the setup page's Back plays the back cue and goes back (%s, %s)" % [str(snd.heard), str(C.page["kind"])])
	for pg in [["newRunScreen", "", "admiral", "title"], ["legacy", "", "legacy", "title"], ["help", "", "help", "title"]]:
		C.act(pg[0], pg[1]); await frames()
		var was := str(C.page["kind"])
		ui._unhandled_input(esc()); await frames()
		check(was == pg[2] and str(C.page["kind"]) == pg[3], "Esc on %s goes back to %s" % [pg[2], pg[3]])
	var tree_id := ""
	for id in C.ADMIRALS:
		if C.LINEAGE_TREES.has(id): tree_id = str(id); break
	C.act("legacy"); C.act("lineage", tree_id); await frames()
	var was_l := str(C.page["kind"])
	ui._unhandled_input(esc()); await frames()
	check(was_l == "lineage" and str(C.page["kind"]) == "legacy" and str(C.prog_tab) == "mastery", "Esc on Lineage goes back to Progression's mastery tab")
	# phase 5: Progression, Lineage and How to play on the kit frame
	var bad_pages := []
	for pg in [["legacy", "", "variants"], ["legacy", "", "legacy"], ["legacy", "", "mastery"], ["legacy", "", "favour"], ["legacy", "", "heat"], ["lineage", tree_id, ""], ["help", "", ""]]:
		C.act(pg[0], pg[1])
		if pg[2] != "": C.act("progTab", pg[2])
		await frames(3)
		var tag := str(pg[0]) + ":" + str(pg[2])
		var backs := 0
		for b in ui.page_box.find_children("*", "Button", true, false):
			if (b as Button).text == "Back": backs += 1
		var grids: Array = ui.page_box.find_children("*", "GridContainer", true, false)
		for g in grids:
			if not g.has_meta("card_w"): continue
			var ws := {}
			for cd in g.get_children(): ws[int(round((cd as Control).size.x))] = true
			if ws.size() > 1: bad_pages.append(tag + " card widths " + str(ws.keys()))
		if ui.page_box.find_children("*", "HFlowContainer", true, false).size() > 0: bad_pages.append(tag + " still has a loose card flow")
		if backs != 1: bad_pages.append(tag + " has %d Back buttons" % backs)
	check(bad_pages.is_empty(), "Progression (each tab), Lineage and How to play: one Back in the fixed bar, card rows on the kit grid, one card width per grid (%s)" % str(bad_pages))
	C.act("help"); await frames(3)
	var names := UI.HELP.filter(func(h): return str(h[0]) != "").map(func(h): return str(h[0]))
	var named := names.size(); var links := 0
	for b in ui.page_box.find_children("*", "Button", true, false):
		if names.has((b as Button).text): links += 1
	check(links >= named, "How to play has an index link for each of its %d sections (%d links)" % [named, links])
	var runs0 := float(C.META["stats"]["runs"]); var adm0 := str(C.picked_admiral); var fac0 := str(C.picked_faction)
	C.act("newRunScreen"); C.act("startRun"); await frames()
	var was_a := str(C.page["kind"])
	var roll = func(): return JSON.stringify({"pat": C.RUN["patrons"], "relics": C.RUN["relics"], "foes": C.RUN["foes"], "map": C.RUN["map"], "offer": C.W["aspOffer"]}, "", true)
	var roll1: String = roll.call()
	ui._unhandled_input(esc()); await frames()
	check(was_a == "aspect" and str(C.page["kind"]) == "admiral" and C.RUN == null and C.SAVED_RUN == null and float(C.META["stats"]["runs"]) == runs0
		and str(C.picked_admiral) == adm0 and str(C.picked_faction) == fac0,
		"Esc on the flagship page goes Back to the desk: the unplayed run, its save and its count are gone, the picks kept")
	C.act("pickFaction", "corsair"); C.act("pickFaction", fac0); await frames()
	C.act("startRun"); await frames(3)
	check(roll.call() == roll1 and float(C.META["stats"]["runs"]) == runs0 + 1.0,
		"Back then Launch is no reroll: same patrons, founder relic, foes, map and aspect offer, and the run counted once")
	var go: Button = ui.page_box.find_child("LaunchButton", true, false)
	check(go != null and go.disabled and ui._aspect_cards.size() >= 3, "the flagship page opens with Launch waiting for an aspect pick (%d offers)" % ui._aspect_cards.size())
	var pick_id: String = ui._aspect_cards[1][1] if ui._aspect_cards.size() > 1 else ""
	var hit: Button = null
	if ui._aspect_cards.size() > 1:
		for b in (ui._aspect_cards[1][0] as Node).find_children("*", "Button", true, false): hit = b
	var found_hit := hit != null   # the button is freed by the re-render, so remember that it was there
	var podium0 = ui.podium
	if found_hit: hit.pressed.emit()
	await frames(3)
	go = ui.page_box.find_child("LaunchButton", true, false)
	# issue 1559 item 27: the pick keeps the live podium (its turning ship carries on; no reload, no snap to the start angle)
	check(podium0 != null and is_instance_valid(podium0) and ui.podium == podium0 and podium0.is_inside_tree() and ui.page_box.is_ancestor_of(podium0),
		"an aspect pick keeps the same flagship podium on the new render (item 27)")
	check(found_hit and go != null and not go.disabled and ui.aspect_pick == pick_id and go.text.ends_with(str(C.ASPECTS[pick_id]["n"])),
		"clicking an aspect card picks it and Launch names it (%s)" % (go.text if go != null else "no button"))
	var bk: Button = null
	for b in ui.page_box.find_children("*", "Button", true, false):
		if (b as Button).text == "Back": bk = b
	check(bk != null, "the flagship page has a Back button")
	if go != null: go.pressed.emit()
	await frames(3)
	check(C.RUN != null and str(C.RUN.get("aspect")) == pick_id and str(C.page["kind"]) != "aspect", "Launch takes the picked aspect and starts the run (page %s)" % str(C.page["kind"]))
	ui.queue_free(); UiScale.set_player(1.0)
	await frames()


func showcase_checks() -> void:
	var M = load("res://main/main.gd")
	var facs: Array = M.showcase_factions()
	var seen := {}
	for i in facs.size(): seen[M.next_showcase_fac()] = true
	check(facs.size() == 5 and not facs.has("voidsworn") and seen.size() == 5, "the title battle cycles the enemy through the five other factions with built ships (%s)" % str(facs))


func music_checks() -> void:
	if not ResourceLoader.exists("res://music/music_player.gd"):
		return
	var mp = load("res://music/music_player.gd").new()
	root.add_child(mp)
	var got := {}
	for f in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		got[f] = mp.faction_preview_id(f)
	var ok := true
	for f in got: if got[f] != "fac_" + f: ok = false
	check(ok, "the faction preview plays each faction's own track (%s)" % str(got))
	check(mp.faction_preview_id("nobody") == "", "an unknown faction has no preview (the title music stays)")
	mp.queue_free()
