extends SceneTree
# Headless property check; --shots DIR also captures the same real UI at 1920x1080.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const JSM = preload("res://rules/jsm.gd")
var failures := 0
var C
var ui
var shots := ""

func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)

func _initialize() -> void: run.call_deferred()

func frames(n := 4) -> void:
	for i in n: await process_frame

func fixture(state: String, fac := "voidsworn", admiral := "vex") -> void:
	JSM.rnd_seed(805)
	C.META = C.migrateMeta(C.defaultMeta()); C.META["opts"]["playtestAll"] = false
	C.META["renown"] = 34; C.META["stats"]["losses"] = 0 if state == "first_loss" else 2
	C.META["stats"]["wins"] = 1
	C.META["mastery"][admiral] = 10
	for id in C.shadowAdmirals(fac, admiral): C.META["mastery"][id] = 2 + C.shadowAdmirals(fac, admiral).find(id) * 1.25
	C.META["heirs"][fac] = C.shadowAdmirals(fac, admiral)[0]
	C.tel_log.clear(); C.RUN = null; C.SAVED_RUN = null
	C.META["admirals"][admiral] = true
	C.newRun(admiral, fac)
	var R = C.RUN
	R["sector"] = 3 if state == "win" else 2
	R["stats"] = {"battles": 6, "elites": 1, "bosses": 1, "kills": 24, "lost": 2}
	R["t0"] = C.now_ms() - 47 * 60000
	var flag = C.flagshipOf()
	for ship in R["fleet"]: ship["car"] = {"dealt": 612, "kills": 7, "battles": 6}
	if state in ["loss", "first_loss"]:
		# Ordinary play's UI retains the last real flagship before applyBattle removes it.
		ui._end_live_run = R; ui._end_last_flagship = flag.duplicate(true)
		R["fleet"] = []
	if state == "empty": R["fleet"] = []; ui._end_last_flagship = {}
	R["fallen"] = [{"name": "Ilse Marrow", "ship": "Last Light", "fac": fac, "rank": 1, "sector": 2}]
	for i in 6:
		R["sector"] = 1 + i / 2 if state == "win" else 1 + i / 3
		C.tel("battle_end", {"kind": "boss" if i == 3 else "battle", "result": "win", "lost": 1 if i in [2, 4] else 0})
	R["sector"] = 3 if state == "win" else 2
	var patrons = C.PATRONS.keys()
	R["coreSync"] = {patrons[0]: 9.0}; C.META["favour"][patrons[0]] = 13.0
	if state == "zero":
		R["stats"] = {"battles": 0, "elites": 0, "bosses": 0, "kills": 0, "lost": 0}
		R["sector"] = 1; R["t0"] = 0; R["coreSync"] = {}; C.tel_log.clear(); C.META["heirs"].erase(fac)
	C.endRun(state == "win", state == "abandoned")

func lum(c: Color) -> float:
	var f = func(x): return x / 12.92 if x <= 0.04045 else pow((x + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)

func contrast(a: Color, b: Color) -> float:
	return (maxf(lum(a), lum(b)) + 0.05) / (minf(lum(a), lum(b)) + 0.05)

func glyph_rects(l: Label) -> Array:
	# Measure the rendered glyph rows, including wrapped longest names, rather than label boxes.
	var out = []; var font = l.get_theme_font("font"); var fs = l.get_theme_font_size("font_size")
	var text = TextParagraph.new(); text.direction = TextServer.DIRECTION_AUTO; text.alignment = l.horizontal_alignment
	text.width = l.size.x; text.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	text.add_string(l.text, font, fs)
	var y = l.global_position.y
	if l.vertical_alignment == VERTICAL_ALIGNMENT_CENTER: y += maxf(0, (l.size.y - text.get_size().y) * 0.5)
	elif l.vertical_alignment == VERTICAL_ALIGNMENT_BOTTOM: y += maxf(0, l.size.y - text.get_size().y)
	for i in text.get_line_count():
		var sz = text.get_line_size(i); var x = l.global_position.x
		if l.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER: x += maxf(0, (l.size.x - sz.x) * 0.5)
		out.append(Rect2(Vector2(x, y), sz)); y += sz.y
	return out

func readability(tag: String) -> void:
	var L = ui.debrief; var boxes = []; var worst = 99.0; var strengths = {}
	for item in L.ink:
		var n = item["node"]
		if not n.is_visible_in_tree(): continue
		var actual_size = n.get_theme_font_size("font_size") / L.k
		var actual_color = n.get_theme_color("font_disabled_color" if n is Button and n.disabled else "font_color")
		strengths[actual_color] = true
		check(actual_size >= 16.99, tag + ": 17 px floor: " + item["text"])
		if n is Label and n.get_theme_font("font") == GS.sheet_name(): check(n.get_theme_font_size("font_size") >= GS.px(28, L.k), tag + ": name face floor")
		for bg in [Color.BLACK, Color.WHITE]:
			var backing = bg.blend(Color(0, 0, 0, GS.LEDGER_VEIL_MIN))
			worst = minf(worst, contrast(actual_color, backing))
		if n is Label:
			for rect in glyph_rects(n): boxes.append({"r": rect, "text": n.text})
		elif n is Button:
			var font = n.get_theme_font("font"); var fs = n.get_theme_font_size("font_size")
			var size = font.get_string_size(n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
			var pos = n.global_position + Vector2(0, (n.size.y - size.y) * 0.5)
			if n.alignment == HORIZONTAL_ALIGNMENT_CENTER: pos.x += (n.size.x - size.x) * 0.5
			boxes.append({"r": Rect2(pos, size), "text": n.text})
	check(strengths.size() == 3, tag + ": no extra interface text colours")
	var boxes_in_ember = 0
	for b in L.find_children("*", "Button", true, false):
		var style = b.get_theme_stylebox("normal")
		if style is StyleBoxFlat and style.border_color == GS.MAP_EMBER and style.border_width_left > 0: boxes_in_ember += 1
	check(boxes_in_ember == 1, tag + ": one ember action box")
	check(strengths.has(GS.TEXT) and strengths.has(GS.TEXT2) and strengths.has(GS.TEXT3), tag + ": three text strengths")
	check(worst >= 4.5, tag + ": contrast over black and white: " + str(worst))
	var screen = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	for i in boxes.size():
		check(screen.grow(1).encloses(boxes[i]["r"]), tag + ": on screen: " + boxes[i]["text"])
		for j in range(i + 1, boxes.size()):
			check(not boxes[i]["r"].grow(-1).intersects(boxes[j]["r"].grow(-1)), tag + ": overlap: " + boxes[i]["text"] + " / " + boxes[j]["text"])
	check(contrast(GS.ON_EMBER, GS.MAP_EMBER) >= 4.5, tag + ": action hover contrast")
	print(tag + ": " + str(boxes.size()) + " text rows; contrast " + str(snapped(worst, 0.01)))

func all_text(n: Node) -> String:
	var t = str(n.text) + "\n" if n is Label or n is RichTextLabel or n is Button else ""
	for child in n.get_children(): t += all_text(child)
	return t

func key(code: int) -> void:
	var e = InputEventKey.new(); e.keycode = code; e.pressed = true
	ui._unhandled_input(e)

func capture(name: String) -> void:
	if shots == "": return
	await frames(12); await RenderingServer.frame_post_draw
	if preload("res://render/placeholder_guard.gd").stop_if_any(): return
	check(preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), shots.path_join("DB1_" + name + ".png"), preload("res://tools/picture_provenance.gd").capture_stage()) == OK, "capture " + name)
	print("shot DB1_" + name)

func run() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--shots":
		shots = args[1]; DirAccess.make_dir_recursive_absolute(shots); root.gui_embed_subwindows = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
	C = Campaign.new(); var error = C.load_tables()
	if error != "": printerr(error); quit(1); return
	C.persist_on = false; C.fixed_clock = true; C.teaching_tips = false
	ui = UI.new(); root.add_child(ui); ui.bind(C)
	await frames()
	if shots != "":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2i(1920, 1080)); await frames()
	for state in ["win", "loss", "first_loss", "abandoned", "zero", "empty"]:
		fixture(state); await frames()
		var before = C.save_text(); ui.render(); await frames()
		check(C.save_text() == before, state + ": drawing does not write run, profile or log")
		check(ui.debrief.timeline.size() == (0 if state == "zero" else 6), state + ": actual battle history, never invented")
		readability(state)
		await capture(state)
		if shots != "" and state == "win":
			Input.warp_mouse(Vector2(110, 780))
			var motion = InputEventMouseMotion.new(); motion.position = Vector2(110, 780); motion.global_position = motion.position; Input.parse_input_event(motion)
			await create_timer(0.8).timeout; await capture("portrait_hover")
			Input.warp_mouse(Vector2(10, 400)); await frames()
		if shots != "" and state == "first_loss":
			for entry in [[KEY_S, "core_sync"], [KEY_L, "nemesis"], [KEY_R, "record"], [KEY_B, "receipt"]]:
				key(entry[0]); await frames(); await capture(entry[1]); key(KEY_ESCAPE); await frames()
		if shots != "":
			check(ui.debrief.ship_portrait == null or ui.debrief.ship_portrait.installed, state + ": capture uses installed model")
	# Exercise every moved item through the actual keys and buttons.
	for code in [KEY_S, KEY_L, KEY_R, KEY_B, KEY_A, KEY_F]:
		var before_open = C.save_text(); key(code); await frames()
		check(is_instance_valid(ui.debrief.overlay), "key opens detail " + str(code))
		check(C.save_text() == before_open, "detail is read only " + str(code))
		var text = all_text(ui.debrief.overlay)
		var expected = {KEY_S: "crossed into", KEY_L: "Nemesis", KEY_R: "sector", KEY_B: "from battles", KEY_A: "XP", KEY_F: "No ships"}
		check(text.contains(expected[code]), "moved receipt reachable " + str(code))
		var run_data = C.page["data"]["run"]; var paid = run_data["carry"]["inheritance"]
		if code == KEY_B:
			for part in ["from battles", "from elites", "from flagships", "from kills", "sectors reached", "View hull rewards", "admirals"]: check(text.contains(part), "renown route keeps " + part)
		if code == KEY_A:
			check(text.contains(str(C.ADMIRALS[run_data["admiral"]]["n"])), "lineage keeps flown admiral")
			for row in paid["shadow"]:
				if float(row["xp"]) > 0: check(text.contains(str(C.ADMIRALS[row["id"]]["n"])) and text.contains(C.numstr(snapped(float(row["xp"]), 0.01))), "lineage keeps shadow earnings for " + str(row["id"]))
		if code == KEY_S:
			for row in paid["cores"]: check(text.contains(str(C.PATRONS[row["id"]]["n"])) and text.contains(C.numstr(row["total"])), "sync keeps count for " + str(row["id"]))
		if code == KEY_R:
			check(not text.contains(str(C.TB.STORY_BEAT3[run_data["fac"]]["learning"])), "record does not invent a story payoff for this Sector II run")
			for card in UI.CampaignTips.CARDS:
				if card[0] == "c_loss": check(text.contains(str(card[2])), "record keeps original next-run teaching card")
		if code == KEY_F:
			for fallen in run_data["fallen"]: check(text.contains(str(fallen["name"])), "fleet keeps each lost captain")
		key(KEY_ESCAPE); await frames()
	key(KEY_P); await frames(); check(C.page["kind"] == "legacy" and C.prog_tab == "legacy", "P opens actual renown spending")
	ui._campaign_action("title"); await frames()
	key(KEY_V); await frames(); check(C.page["kind"] == "legacy" and C.prog_tab == "variants", "V opens real hull rewards")
	ui._campaign_action("title"); await frames(); check(C.page["kind"] == "end", "rewards return to ledger")
	for action in ["title", "newRunScreen", "nextFac"]:
		ui._campaign_action(action, "corsair"); check(C.page["kind"] == "end", "unconfirmed exit blocked: " + action)
	check(ui.debrief.exits.all(func(b): return b.disabled), "both exit words inert")
	var original = C.META["heirs"]["voidsworn"]
	var ids = C.shadowAdmirals("voidsworn", "vex"); var chosen = str(ids[-1])
	ui.debrief.choose_heir(chosen); check(C.META["heirs"]["voidsworn"] == original, "selection alone does not name heir")
	key(KEY_ENTER); await frames()
	check(ui._end_confirmed and C.META["heirs"]["voidsworn"] == chosen, "Enter confirms selected heir")
	check(ui.debrief.exits.all(func(b): return not b.disabled), "exits enabled after confirmation")
	await capture("confirmed")
	var confirmed = C.save_text(); ui.render(); await frames(); check(C.save_text() == confirmed, "redraw does not reconfirm or repay")
	ui._campaign_action("title"); check(C.page["kind"] == "title", "confirmed title exit works")
	fixture("win"); await frames(); key(KEY_ENTER); await frames()
	check(C.META["heirs"]["voidsworn"] == C.shadowAdmirals("voidsworn", "vex")[0], "confirm keeps preselected current heir")
	key(KEY_ENTER); await frames(); check(C.page["kind"] == "admiral", "second Enter opens next faction")
	fixture("win"); await frames()
	var long_run = C.page["data"]["run"]
	for ship in long_run["fleet"]:
		if ship["uid"] == long_run["flagUid"]: ship["name"] = "Sunward Martyr of the Ninth Pyre"
	for i in 20: long_run["fallen"].append({"name": "Fallen captain " + str(i)})
	for i in range(20 - long_run["fleet"].size()):
		var ship = C.newShip(long_run["fleet"][0]["tpl"]); ship["name"] = "Ledger escort " + str(i); long_run["fleet"].append(ship)
	ui.render(); await frames(); readability("long flagship, 20 ships")
	key(KEY_F); await frames()
	var roster = all_text(ui.debrief.overlay)
	for ship in long_run["fleet"]: check(roster.contains(ship["name"]), "full roster keeps " + ship["name"])
	key(KEY_ESCAPE); await frames()
	# All factions, the longest authored names, and both required reading sizes.
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = sz; await frames()
		for fac in C.RUN_FACTIONS:
			var adm = ""
			for id in C.ADMIRALS:
				if C.ADMIRALS[id].get("fac", "voidsworn") == fac and (adm == "" or str(C.ADMIRALS[id]["n"]).length() > str(C.ADMIRALS[adm]["n"]).length()): adm = id
			fixture("win", fac, adm); await frames(); readability(str(sz) + " " + fac)
	print("DB1: " + ("PASS" if failures == 0 else "FAIL " + str(failures)))
	ui.queue_free(); await frames(); preload("res://render/ship_view.gd").clear_static()
	quit(0 if failures == 0 else 1)
