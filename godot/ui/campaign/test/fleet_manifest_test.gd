extends SceneTree
# Real Fleet page and real campaign actions. Optional GPU captures: --shots DIR.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const JSM = preload("res://rules/jsm.gd")
var C
var ui
var failures := 0
var shots := ""

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: " + message)
func frames(n := 5) -> void:
	for i in n: await process_frame
func snap() -> String: return C.save_text() + "|" + str(JSM.rng_s) + "|" + str(C.UID)
func key(code: int) -> void:
	var e = InputEventKey.new(); e.keycode = code; e.pressed = true; ui._unhandled_input(e)
func page(): return ui.fleet_manifest
func text(n: Node) -> String:
	var t = str(n.text) + "\n" if n is Label or n is Button else ""
	for ch in n.get_children(): t += text(ch)
	return t
func buttons(n: Node, meta: String, value) -> Array:
	return n.find_children("*", "Button", true, false).filter(func(b): return b.has_meta(meta) and b.get_meta(meta) == value)
func press_slot(slot: int) -> void:
	var bs = buttons(page().workspace, "slot", slot); check(bs.size() == 1, "selected slot reachable")
	if not bs.is_empty(): bs[0].pressed.emit()
func fixture(fac := "voidsworn", count := 12) -> void:
	C.RUN = null; C.META = C.migrateMeta(C.defaultMeta()); C.SAVED_RUN = null; C.modal_d = null
	var adm = "vex"
	for id in C.ADMIRALS:
		if C.ADMIRALS[id].get("fac", "voidsworn") == fac: adm = str(id); break
	JSM.rnd_seed(868); C.newRun(adm, fac)
	C.modal_d = null; C.RUN["fleet"] = []; C.RUN["inventory"] = ["prow"]; C.RUN["credits"] = 500
	var names = ["Wrath of Vesper", "Vigilant Ash", "Cold Fury", "Oath Flame", "Resolve of the Reach", "Cinder Vow", "Burning Spire", "Unyielding Oath", "Last Light", "Dawn's Promise", "Silent Ember", "Ashen Wake"]
	for i in count:
		var tpl = C.equivHull(["penitent", "harrow", "warden"][i % 3], fac)
		var ship = C.newShip(tpl); ship["name"] = names[i % names.size()] if i < 12 else "Sunward Martyr of the Ninth Pyre " + str(i)
		if i in [1, 2]: ship["hp"] = round(float(C.derive(ship)["maxHp"]) * 0.3)   # whole hull, as real play stores it (issue 894)
		C.RUN["fleet"].append(ship)
	C.RUN["flagUid"] = C.RUN["fleet"][0]["uid"] if count > 0 else ""
	C.fleetScreen("")

func readability(tag: String) -> void:
	var screen = Rect2(Vector2.ZERO, root.size)
	var labels = page().find_children("*", "Label", true, false)
	for l in labels:
		check(l.get_theme_font_size("font_size") / ui.k >= 16.99, tag + ": 17 px floor: " + l.text)
		if l.get_theme_font("font") == GS.sheet_name(): check(l.get_theme_font_size("font_size") >= ui.px(28), tag + ": name floor")
		# Scrollable areas intentionally retain content outside the visible screen.
		var ancestor = l.get_parent(); var scroll = false
		while ancestor != page():
			if ancestor is ScrollContainer: scroll = true; break
			ancestor = ancestor.get_parent()
		if not scroll: check(screen.grow(1).encloses(l.get_global_rect()), tag + ": on screen: " + l.text)
	check(page().sheet_w / page().width <= 0.25, tag + ": narrow detail sheet")
	var boxed = 0
	for b in page().find_children("*", "Button", true, false):
		var sb = b.get_theme_stylebox("normal")
		if sb is StyleBoxFlat and sb.border_color == GS.MAP_EMBER and sb.border_width_left > 0: boxed += 1
	check(boxed == 1, tag + ": only Done has an ember box")
	for n in page().find_children("*", "Control", true, false):
		if not (n is Label or n is Button): continue
		var col = n.get_theme_color("font_disabled_color" if n is Button and n.disabled else "font_color")
		for bg in [Color.WHITE, Color.BLACK]:
			var backing = bg.blend(Color(0, 0, 0, GS.LEDGER_VEIL_MIN))
			check((maxf(lum(col), lum(backing)) + 0.05) / (minf(lum(col), lum(backing)) + 0.05) >= 4.5, tag + ": contrast: " + n.text)
	var boxes = []
	for row in page().rows:
		var row_labels = row["button"].find_children("*", "Label", true, false)
		for l in row_labels:
			var p = TextParagraph.new(); p.width = l.size.x
			p.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
			p.add_string(l.text, l.get_theme_font("font"), l.get_theme_font_size("font_size"))
			check(p.get_size().y <= l.size.y + 1, tag + ": row text fits: " + l.text)
			var y = l.global_position.y + (l.size.y - p.get_size().y) * 0.5
			for line in p.get_line_count():
				var sz = p.get_line_size(line); boxes.append({"rect": Rect2(l.global_position.x, y, sz.x, sz.y), "text": l.text}); y += sz.y
	for i in boxes.size():
		for j in range(i + 1, boxes.size()):
			check(not boxes[i]["rect"].grow(-1).intersects(boxes[j]["rect"].grow(-1)), tag + ": row overlap: " + boxes[i]["text"] + " / " + boxes[j]["text"])

func lum(col: Color) -> float:
	var f = func(x): return x / 12.92 if x <= 0.04045 else pow((x + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(col.r) + 0.7152 * f.call(col.g) + 0.0722 * f.call(col.b)

func capture(code: String) -> void:
	if shots == "": return
	await frames(12); await RenderingServer.frame_post_draw
	if preload("res://render/placeholder_guard.gd").stop_if_any(): failures += 1; return
	for art in page().portraits.values(): check(art["installed"], "capture has installed hull " + art["code"])
	check(preload("res://tools/picture_provenance.gd").save_png(root.get_texture().get_image(), shots.path_join("FL5_" + code + ".png")) == OK, "capture " + code)
	print("shot FL5_" + code)

func capture_states() -> void:
	fixture(); await frames(); await capture("1080")
	page().select_ship(C.RUN["fleet"][1]["uid"]); await frames(); await capture("damaged")
	page().select_ship(C.RUN["fleet"][0]["uid"]); key(KEY_H); await frames(); await capture("hold"); key(KEY_ESCAPE)
	key(KEY_C); await frames(); await capture("doctrine"); key(KEY_ESCAPE)
	Input.warp_mouse(Vector2(350, 270))
	var motion = InputEventMouseMotion.new(); motion.position = Vector2(350, 270); motion.global_position = motion.position; Input.parse_input_event(motion)
	await create_timer(0.8).timeout; await capture("hover"); Input.warp_mouse(Vector2(10, 10))
	DisplayServer.window_set_size(Vector2i(3840, 2160)); root.size = Vector2i(3840, 2160); await frames()
	fixture(); await frames(); await capture("2160")
	DisplayServer.window_set_size(Vector2i(1920, 1080)); root.size = Vector2i(1920, 1080); await frames()
	fixture("voidsworn", 20); await frames(); page().manifest_scroll.scroll_vertical = 100000
	page().select_ship(C.RUN["fleet"][-1]["uid"]); await frames(); await capture("busy")

func run() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--shots":
		shots = args[1]; DirAccess.make_dir_recursive_absolute(shots)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
	C = Campaign.new(); var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.persist_on = false; C.fixed_clock = true; C.teaching_tips = false
	check(C.MODULES.has("prow"), "fixture uses real refit")
	ui = UI.new(); root.add_child(ui); ui.bind(C); ui.use_3d_map = false
	await frames()
	if shots != "":
		await capture_states()
		print("FL5 captures: " + ("PASS" if failures == 0 else "FAIL"))
		ui.queue_free(); await frames(); preload("res://render/ship_view.gd").clear_static(); quit(0 if failures == 0 else 1); return
	fixture(); await frames()
	var before = snap(); ui.render(); await frames()
	check(snap() == before, "drawing is read only, including save and campaign random stream")
	check(page().rows.size() == 12 and page().rows[0]["damaged"] and page().rows[1]["damaged"] and not page().rows[2]["damaged"], "damage groups contain real ships")
	check(page().manifest_scroll.get_v_scroll_bar().max_value <= page().manifest_scroll.size.y + 1, "twelve ships fit with no scroll at 1080")
	readability("1080"); await capture("1080")
	var source = C.RUN["fleet"][0]; var target = C.RUN["fleet"][3]
	page().select_ship(str(target["uid"])); page().select_ship(str(source["uid"])); key(KEY_C); key(KEY_ESCAPE); key(KEY_H); key(KEY_ESCAPE)
	check(snap() == before, "selection, doctrine inspection and hold inspection do not write")
	press_slot(0); await frames()
	var fit = buttons(page().workspace, "inventory_index", 0); check(fit.size() == 1 and not fit[0].disabled, "empty slot opens compatible hold refit")
	if not fit.is_empty(): fit[0].pressed.emit()
	await frames()
	check(source["mods"] == ["prow"] and C.RUN["inventory"].is_empty(), "real Fleet screen performs a refit")
	press_slot(0); await frames()
	check(not page().state["held"].is_empty(), "filled slot starts a local move")
	# A full target does not silently strip the source or write a partial transfer.
	var filled_target = C.RUN["fleet"][4]
	for i in int(C.HULLS[filled_target["tpl"]]["slots"]): filled_target["mods"].append("prow")
	before = snap(); page().select_ship(filled_target["uid"])
	check(snap() == before and not page().state["held"].is_empty(), "full target leaves source and held refit intact")
	page().select_ship(source["uid"])
	before = snap(); key(KEY_ESCAPE); check(snap() == before and page().state["held"].is_empty(), "cancel move is read only")
	press_slot(0); page().select_ship(str(target["uid"])); await frames()
	check(source["mods"].is_empty() and target["mods"] == ["prow"], "clicking another ship transfers through real campaign actions")
	var remove = buttons(page().workspace, "remove_slot", 0)
	if not remove.is_empty(): remove[0].pressed.emit()
	await frames(); check(target["mods"].is_empty() and C.RUN["inventory"] == ["prow"], "remove returns refit to the hold")
	# An incompatible carrier refit stays visible but cannot fit to this cruiser.
	var carrier_mod = ""
	for id in C.MODULES:
		if C.MOD_NEED.get(id) == "carrier": carrier_mod = str(id); break
	check(carrier_mod != "", "real carrier-only refit exists")
	if carrier_mod != "":
		C.RUN["inventory"].append(carrier_mod); C.fleetScreen(""); await frames(); key(KEY_H)
		var incompatible = buttons(page().workspace, "inventory_index", 1)
		check(incompatible.size() == 1 and incompatible[0].disabled, "incompatible refit remains disabled")
	await capture("hold"); key(KEY_ESCAPE)
	# Pending promotions stay on the selected ship's sheet and use the old modal.
	target["cap"]["pending"] = 1; C.fleetScreen(""); await frames()
	var promotion = page().detail.find_children("*", "Button", true, false).filter(func(b): return b.text == "Choose promotion perk")
	check(not promotion.is_empty(), "promotion remains reachable")
	if not promotion.is_empty():
		promotion[0].pressed.emit(); await frames(); check(C.modal_d != null and C.modal_d["kind"] == "promote", "real promotion modal opens")
		if C.modal_d != null:
			var action = C.modal_d["acts"][0]; C.act(action[0], action[1]); await frames()
			check(int(target["cap"]["pending"]) == 0 and target["cap"]["perks"].size() == 1, "promotion applies and returns to Fleet")
	key(KEY_C); await frames(); await capture("doctrine")
	var credit = C.RUN["credits"]; var action = buttons(page().workspace, "faction_action", true)
	check(action.size() == 1 and not action[0].disabled, "faction action remains reachable")
	if not action.is_empty(): action[0].pressed.emit()
	await frames(); check(C.RUN["credits"] == credit - 40 and C.page["kind"] == "map", "doctrine uses original cost and original return route")
	C.fleetScreen(""); await frames(); page().primary.pressed.emit(); await frames(); check(C.page["kind"] == "map", "Done returns to map")
	# issue 1559 item 9: a mouse click on a ship row picks it without keeping the keyboard, so Enter (through the engine's
	# input path) is the screen's Done, not a second press of the row
	C.fleetScreen(""); await frames()
	var row_b: Button = page().rows[1]["button"]; var at = row_b.get_global_rect().get_center()
	for pressed in [true, false]:
		var mb = InputEventMouseButton.new(); mb.button_index = MOUSE_BUTTON_LEFT; mb.position = at; mb.global_position = at; mb.pressed = pressed
		root.push_input(mb); await process_frame
	await frames()
	var fo = root.gui_get_focus_owner()
	check(fo == null or not (fo in page().rows.map(func(r): return r["button"])), "item 9: a clicked ship row does not keep the keyboard")
	for pressed in [true, false]:
		var ke = InputEventKey.new(); ke.keycode = KEY_ENTER; ke.physical_keycode = KEY_ENTER; ke.pressed = pressed
		root.push_input(ke); await process_frame
	await frames(); check(C.page["kind"] == "map", "item 9: Enter after a row click is Done")
	var yard = {"stock": {"hulls": [], "mods": [], "sold": [], "cap": []}}
	C.yard_node = yard; C.fleetScreen("shipyard"); await frames(); key(KEY_ENTER); await frames()
	check(C.page["kind"] == "shipyard", "Done returns to originating shipyard")
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]:
		if shots != "": DisplayServer.window_set_size(sz)
		root.size = sz; await frames(); fixture(); await frames(); readability(str(sz))
		check(page().manifest_scroll.get_v_scroll_bar().max_value <= page().manifest_scroll.size.y + 1, "twelve ships fit at " + str(sz))
		if sz.y == 2160: await capture("2160")
	root.size = Vector2i(1920, 1080)
	if shots != "": DisplayServer.window_set_size(root.size)
	await frames()
	for fac in C.RUN_FACTIONS:
		fixture(fac, 20); await frames(); readability(fac + " long fleet")
		check(page().rows.size() == 20, "all ships remain reachable for " + fac)
		page().manifest_scroll.scroll_vertical = 100000; page().select_ship(C.RUN["fleet"][-1]["uid"]); await frames()
		check(text(page().detail).contains(C.RUN["fleet"][-1]["name"].to_upper()), "last ship's full name remains reachable")
		if fac == "voidsworn": await capture("busy")
	for scale in [0.8, 1.4]:
		UI.UiScale.player = scale; ui._rescale(); fixture("ithar", 20); await frames(); readability("player scale " + str(scale))
	UI.UiScale.player = 1.0; ui._rescale()
	fixture("voidsworn", 0); await frames(); check(text(page()).contains("No ships"), "empty fleet stays usable")
	print("FL5: " + ("PASS" if failures == 0 else "FAIL " + str(failures)))
	ui.queue_free(); await frames(); preload("res://render/ship_view.gd").clear_static(); quit(0 if failures == 0 else 1)
