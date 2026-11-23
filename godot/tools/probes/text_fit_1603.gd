extends SceneTree
# Issue 1603: does the issue 1551 story text fit on Windows? Builds the real campaign screens (campaign_ui.gd) and the real
# battle HUD log (hud.gd) at Normal (UI scale 1.0) and Larger (1.3) text and checks every visible piece of text on them:
#   STORY-1603  the Sector III story card (STORY_BEAT3) of every faction, and the result after its first choice
#   EVENT-1603  every event card (EVENTS) of every faction
#   SHIP-1603   the shipyard page of every faction (the 1551 repair line among them)
#   LOG-1603    the full battle log (L) holding a real fight's log plus the 1551 rules lines
# A piece of text fails when part of it is not shown: a one-line label or button whose words are wider than the box, a
# wrapped label showing fewer lines than it holds, a rich text box taller than its frame with no scroll bar, or text
# outside the window or outside the panel that clips it. Text inside a scroll box may run past the visible part (the
# player can scroll to it); that is listed as "scrolls", never failed.
# With a window it saves one picture per item and scale, named <code>_<scale>.png, with the code name on it, at most 720 px
# tall; headless it runs the same checks without pictures.
#   godot --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://tools/probes/text_fit_1603.gd -- <out folder> [<commit>]
# Prints TEXT_FIT_1603 PASS or TEXT_FIT_1603 FAIL <n>, writes <out>/text_fit_1603.txt, exits 0 only on PASS.

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
const UiScale = preload("res://ui/ui_scale.gd")
const HUD = preload("res://ui/battle/hud.gd")
const API = preload("res://rules/battle_api.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const MapIntel = preload("res://ui/campaign/map_intel.gd")
const FACS := ["voidsworn", "corsair", "ithar", "deathless", "chorus", "hegemony"]
const SCALES := [[1.0, "normal"], [1.3, "larger"]]
# the 1551 rules lines the battle log shows (godot/rules/rules.gd after PR 1579), so the log page holds the new words
const LOG_1551 := ["Vesper's Wrath breaks off and jumps clear with the surviving hulls. Expect another encounter."]

var campaign
var ui: CampaignUI
var out := ""
var commit := ""
var headless := false
var report: PackedStringArray = []
var fails := 0
var checked := 0
var pictures := 0

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	headless = DisplayServer.get_name() == "headless"
	out = args[0] if args.size() > 0 else ""
	commit = args[1] if args.size() > 1 else ""
	if out == "" and not headless: _done("supply an output folder after --"); return
	if out != "" and DirAccess.make_dir_recursive_absolute(out) != OK: _done("cannot create " + out); return
	root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
	_line("text_fit_1603 window %dx%d commit %s headless %s" % [root.size.x, root.size.y, commit, str(headless)])
	campaign = Campaign.new()
	var err: String = campaign.load_tables()
	if err != "": _done("campaign tables: " + err); return
	campaign.fixed_clock = true; campaign.persist_on = false
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = campaign
	ui.teaching = CampaignTips.new(); ui.teaching.disabled = true; ui.add_child(ui.teaching)
	ui.set_process(false)
	ui.use_3d_map = false

	if not await _self_test(): _done("the text checker missed text it must catch"); return
	for sc in SCALES:
		_set_scale(sc[0])
		await _story(sc)
		await _events(sc)
		await _shipyard(sc)
	_set_scale(1.0)
	ui.queue_free(); await process_frame
	for sc in SCALES: await _battle_log(sc)
	_set_scale(1.0)
	_done("")

func _set_scale(v: float) -> void:
	UiScale.set_player(v)
	if ui != null and is_instance_valid(ui): ui._rescale()

func _admiral_for(fac: String) -> String:
	var row = campaign.TB["STORY_BEAT3"].get(fac)
	if row is Dictionary and row.get("spotlights") is Dictionary and not row["spotlights"].is_empty(): return str(row["spotlights"].keys()[0])
	for id in campaign.TB["ADMIRALS"].keys():
		if str(campaign.TB["ADMIRALS"][id].get("fac", "")) == fac: return str(id)
	return ""

func _new_run(fac: String, seed: int) -> bool:
	var adm := _admiral_for(fac)
	if adm == "": _bad("setup", fac, "no admiral for " + fac); return false
	JSM.rnd_seed(seed)
	campaign.META = campaign.defaultMeta()
	campaign.META["admirals"][adm] = true
	campaign.modal_d = null
	campaign.newRun(adm, fac)
	ui.map3d.intel = MapIntel.new(campaign)
	return true

# ---------------------------------------------------------------- the pages

func _story(sc: Array) -> void:
	for fac in FACS:
		if not _new_run(fac, 1603): continue
		campaign.RUN["sector"] = 3
		campaign.mapScreen()
		if not campaign.showBeat3(): _bad("STORY-1603", fac, "no Sector III story card"); continue
		var ev: Dictionary = campaign.cur_event
		await _page("STORY-1603", fac + " card", str(ev.get("t", "")), "STORY-1603_" + fac + "_card", sc)
		campaign.act("eventChoice", "0")
		var lines = campaign.modal_d["data"].get("lines", []) if campaign.modal_d != null and campaign.modal_d.get("data") is Dictionary else []
		var must := str(lines[0]) if lines is Array and lines.size() > 0 else ""
		await _page("STORY-1603", fac + " result", must.substr(0, 40), "STORY-1603_" + fac + "_result" if fac == "voidsworn" else "", sc)

func _events(sc: Array) -> void:
	var longest := ""; var longest_n := -1; var longest_fac := ""
	for fac in FACS:
		if not _new_run(fac, 1604): continue
		campaign.RUN["flags"] = {}
		campaign.RUN["curNode"] = campaign.RUN["map"]["cols"][0][0]["id"]
		for e in campaign.TB["EVENTS"]:
			var ev = campaign._event_for_faction(e)
			var n := str(ev.get("b", "")).length()
			for o in ev.get("o", []): n += str(o.get("l", "")).length() + str(o.get("s", "")).length()
			if n > longest_n: longest_n = n; longest = str(e["id"]); longest_fac = fac
			campaign.modal_d = null
			campaign.show_event(ev)
			await _page("EVENT-1603", fac + " " + str(e["id"]), str(ev.get("t", "")), "", sc)
	# the one with the most words, again, for its picture
	if longest != "" and _new_run(longest_fac, 1604):
		campaign.RUN["flags"] = {}
		campaign.RUN["curNode"] = campaign.RUN["map"]["cols"][0][0]["id"]
		var ev2 = campaign._event_for_faction(campaign.TB["EVENTS"].filter(func(x): return x["id"] == longest)[0])
		campaign.modal_d = null
		campaign.show_event(ev2)
		await _page("EVENT-1603", longest_fac + " " + longest + " (most words)", str(ev2.get("t", "")), "EVENT-1603_" + longest, sc)

func _shipyard(sc: Array) -> void:
	for fac in FACS:
		if not _new_run(fac, 1605): continue
		campaign.RUN["credits"] = 900.0
		var n = campaign.RUN["map"]["cols"][0][0]
		n["type"] = "shipyard"; n.erase("stock"); campaign.modal_d = null; campaign.RUN["curNode"] = n["id"]
		campaign.shipyardScreen(n)
		await _page("SHIP-1603", fac + " shipyard", "Repairs cost ", "SHIP-1603_" + fac if fac in ["voidsworn", "chorus"] else "", sc)

func _battle_log(sc: Array) -> void:
	UiScale.set_player(sc[0])
	var api = API.new()
	var err: String = api.load_rules()
	if err != "": _bad("LOG-1603", "rules", err); return
	api.new_battle_scenario("s1")
	var g := 0
	while int(api.R.B["round"]) < 3 and api.phase != "over" and g < 4000:
		g += 1
		if api.phase == "player":
			var me = null
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]: me = u; break
			if me == null: api.end_activation(); api.take_events(); continue
			var r0 = int(api.R.B["round"])
			api.ai_activate(me["id"])
			if api.phase == "player" and int(api.R.B["round"]) == r0 and api.unit(me["id"]) != null and not campaign.jt(api.unit(me["id"]).get("activated")): api.end_activation(me["id"])
			api.take_events()
		else: api.step()
	var h = HUD.new()
	root.add_child(h)
	for i in range(3): await process_frame
	var lines: Array = api.R.B.get("log", [])
	for e in lines: h.add_log(str(e.get("m", "")), str(e.get("c", "x")))
	for m in LOG_1551: h.add_log(m, "s")
	_line("LOG-1603 %s: %d rules log lines from scenario s1 (%d rounds) plus %d 1551 lines" % [sc[1], lines.size(), int(api.R.B["round"]), LOG_1551.size()])
	if lines.is_empty(): _bad("LOG-1603", sc[1], "the fight wrote no log lines")
	h.toggle_log()
	for i in range(4): await process_frame
	h.log_text.scroll_to_line(maxi(0, h.log_text.get_line_count() - 1))
	await process_frame
	var probs := _audit(h.root)
	_tally("LOG-1603", "battle log " + sc[1], probs)
	if not _visible_text(h.root, "Expect another encounter"): _bad("LOG-1603", sc[1], "the 1551 line is not in the log view")
	await _shoot("LOG-1603_battle_log", sc, "battle log (L), a real fight's log (scenario s1) plus the 1551 nemesis line")
	h.queue_free(); await process_frame

# ---------------------------------------------------------------- checks

# the checker must catch what it is for, on this PC's fonts, before its silence counts: a one-line label cut short, a
# wrapped label with lines hidden, a button cut short, and a label outside the window
func _self_test() -> bool:
	var box := Control.new(); box.position = Vector2(100, 100); box.size = Vector2(400, 300)
	root.add_child(box)
	var long := "The Glasswright keeper pulses warm amber and gifts the hardware anyway, which is far too long for this box."
	var a := Label.new(); a.text = long; a.clip_text = true; a.size = Vector2(120, 30); box.add_child(a)
	var b := Label.new(); b.text = long; b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; b.max_lines_visible = 1; b.position = Vector2(0, 40); b.size = Vector2(120, 30); box.add_child(b)
	var c := Button.new(); c.text = long; c.clip_text = true; c.position = Vector2(0, 80); c.size = Vector2(120, 30); box.add_child(c)
	var d := Label.new(); d.text = "outside"; d.position = Vector2(-400, 0); d.size = Vector2(100, 30); box.add_child(d)
	var ok := Label.new(); ok.text = "fits"; ok.position = Vector2(0, 160); ok.size = Vector2(200, 30); box.add_child(ok)
	for i in range(3): await process_frame
	var probs := _audit(box)
	box.queue_free(); await process_frame
	var want := 4
	var got := probs.filter(func(p): return not str(p).begins_with("scrolls:")).size()
	var fits_flagged := probs.any(func(p): return str(p).contains("\"fits\""))
	_line("self test: the checker flagged %d of the %d planted problems%s" % [got, want, ", and wrongly flagged the label that fits" if fits_flagged else ""])
	for p in probs: _line("  self test: " + str(p))
	return got == want and not fits_flagged

func _page(code: String, what: String, must: String, pic: String, sc: Array) -> void:
	ui.render()
	for i in range(4): await process_frame
	if must != "" and not _visible_text(ui, must):
		_bad(code, what + " " + sc[1], "the screen does not show \"" + must + "\"")
	_tally(code, what + " " + sc[1], _audit(ui))
	if pic != "":
		await _scroll_hint(must)
		await _shoot(pic, sc, what)

func _tally(code: String, what: String, probs: Array) -> void:
	checked += 1
	for p in probs:
		if str(p).begins_with("scrolls:"): _line("  note " + code + " " + what + ": " + str(p))
		else: _bad(code, what, str(p))

func _visible_text(n: Node, must: String) -> bool:
	for l in n.find_children("*", "Label", true, false) + n.find_children("*", "RichTextLabel", true, false) + n.find_children("*", "Button", true, false):
		if l.is_visible_in_tree() and _text_of(l).to_lower().contains(must.to_lower()): return true
	return false

func _text_of(c: Control) -> String:
	if c is RichTextLabel: return (c as RichTextLabel).get_parsed_text()
	return str(c.text)

# every visible text control under n: what part of it is hidden
func _audit(n: Node) -> Array:
	var probs := []
	var win := Rect2(Vector2.ZERO, Vector2(root.size)).grow(1.0)
	for c in n.find_children("*", "Label", true, false) + n.find_children("*", "RichTextLabel", true, false) + n.find_children("*", "Button", true, false):
		if c.is_queued_for_deletion() or not c.is_visible_in_tree(): continue
		var t := _text_of(c).strip_edges()
		if t == "": continue
		var name := "\"" + (t.substr(0, 48).replace("\n", " ") + ("..." if t.length() > 48 else "")) + "\""
		var r: Rect2 = c.get_global_rect()
		if r.size.x < 1.0 or r.size.y < 1.0: probs.append(name + " has no room (" + str(r.size) + ")"); continue
		# the nearest scroll box or clipping panel above it
		var scroll: ScrollContainer = null
		var clip: Control = null
		var p = c.get_parent()
		while p is Control:
			if p is ScrollContainer and scroll == null: scroll = p
			elif (p as Control).clip_contents and clip == null and scroll == null: clip = p
			p = p.get_parent()
		if scroll != null:
			var sr: Rect2 = scroll.get_global_rect()
			if not win.encloses(sr): probs.append(name + "'s scroll box runs outside the window (" + str(sr) + ")")
			if not sr.grow(1.0).encloses(r): probs.append("scrolls: " + name + " runs past the visible part of its scroll box")
		else:
			if not win.encloses(r): probs.append(name + " is outside the window (" + str(r) + ")")
			if clip != null and not clip.get_global_rect().grow(1.0).encloses(r): probs.append(name + " is cut by its panel")
		if c is Label:
			var l := c as Label
			if l.autowrap_mode == TextServer.AUTOWRAP_OFF:
				if l.clip_text or l.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
					var f := l.get_theme_font("font"); var fs := l.get_theme_font_size("font_size")
					var w := f.get_multiline_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
					if w > l.size.x + 1.0: probs.append(name + " is cut short: needs %d px, has %d" % [int(w), int(l.size.x)])
			elif l.get_visible_line_count() < l.get_line_count():
				probs.append(name + " shows %d of its %d lines" % [l.get_visible_line_count(), l.get_line_count()])
		elif c is Button:
			var b := c as Button
			if b.clip_text or b.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING:
				var f2 := b.get_theme_font("font"); var fs2 := b.get_theme_font_size("font_size")
				var sb := b.get_theme_stylebox("normal")
				var pad := (sb.get_margin(SIDE_LEFT) + sb.get_margin(SIDE_RIGHT)) if sb != null else 0.0
				var w2 := f2.get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x + pad
				if b.icon != null: w2 += b.icon.get_width()
				if w2 > b.size.x + 1.0: probs.append(name + " (button) is cut short: needs %d px, has %d" % [int(w2), int(b.size.x)])
		elif c is RichTextLabel:
			var rt := c as RichTextLabel
			if not rt.fit_content:
				var bar := rt.get_v_scroll_bar()
				var over := rt.get_content_height() > rt.size.y + 1.0
				if over and not (rt.scroll_active and bar != null and bar.max_value > bar.page): probs.append(name + " (rich text) is taller than its frame: %d of %d px" % [int(rt.size.y), rt.get_content_height()])
				elif over: probs.append("scrolls: " + name + " (rich text) scrolls")
	return probs

# ---------------------------------------------------------------- pictures

func _scroll_hint(must: String) -> void:
	if must == "": return
	for l in ui.find_children("*", "Label", true, false) + ui.find_children("*", "RichTextLabel", true, false):
		if l.is_visible_in_tree() and _text_of(l).contains(must):
			var p = l.get_parent()
			while p != null and not (p is ScrollContainer): p = p.get_parent()
			if p is ScrollContainer: p.ensure_control_visible(l); await process_frame
			return

func _shoot(code: String, sc: Array, what: String) -> void:
	if headless or out == "": return
	var cap := CanvasLayer.new(); cap.layer = 120
	var l := Label.new()
	l.text = code + "   " + str(sc[1]).capitalize() + " text (UI scale " + str(sc[0]) + ")   " + what + "   issue 1603   " + commit.substr(0, 8) + "   PC, pinned checkout"
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1, 1, 1)); l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(12, 8)
	cap.add_child(l); root.add_child(cap)
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_height() > 720: img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var f := code + "_" + str(sc[1]) + ".png"
	if preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(f)) != OK: _bad(code, f, "could not write the picture")
	else: pictures += 1; _line("saved " + f)
	cap.queue_free(); await process_frame

# ---------------------------------------------------------------- report

func _bad(code: String, what: String, why: String) -> void:
	fails += 1
	_line("FAIL " + code + " " + what + ": " + why)

func _line(s: String) -> void:
	report.append(s); print(s)

func _done(fatal: String) -> void:
	if fatal != "": fails += 1; _line("FAIL " + fatal)
	_line("pages checked %d, pictures %d" % [checked, pictures])
	_line("TEXT_FIT_1603 " + ("PASS" if fails == 0 else "FAIL %d" % fails))
	if out != "":
		var f := FileAccess.open(out.path_join("text_fit_1603.txt"), FileAccess.WRITE)
		if f != null: f.store_string("\n".join(report) + "\n"); f.close()
	UiScale.set_player(1.0)
	quit(0 if fails == 0 else 1)
