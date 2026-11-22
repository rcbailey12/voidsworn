extends Control
# DB1, The Ledger Page. Presentation only: the paid receipt remains the source.
const GS = preload("res://ui/theme/glass_shell.gd")
const Portraits = preload("res://portraits/portraits.gd")
const ShipPortrait = preload("res://ui/campaign/ledger_ship.gd")
const FIT_H := 1080.0   # issue 1559 item 3: the design sheet the fixed layout needs (height, and width before columns meet)
const FIT_W := 1800.0
const KEYS := {KEY_S: "cores", KEY_L: "nemesis", KEY_R: "record", KEY_P: "spend", KEY_B: "renown", KEY_V: "hulls", KEY_A: "lineage", KEY_F: "fleet"}
var ui
var C
var d: Dictionary
var R: Dictionary
var receipt: Dictionary
var k := 1.0
var width := 1920.0
var ink: Array = []
var cards: Array = []
var exits: Array = []
var primary: Button
var overlay: Control
var section := ""
var timeline: Array = []
var flagship: Dictionary = {}
var ship_portrait: Control

func setup(host, data: Dictionary) -> void:
	ui = host; C = ui.C; d = data; R = d["run"]; receipt = R["carry"]["inheritance"]
	# issue 1559 item 3: the page is laid out in fixed places on a 1080-high, at least 1800-wide design sheet, so its scale
	# is the shared one capped where that sheet still fits the window. At Large and Larger (and in a narrow window) the
	# page stops growing instead of running off the bottom or squeezing its columns into each other.
	var vs: Vector2 = ui.get_viewport().get_visible_rect().size
	k = minf(ui.k, minf(vs.y / FIT_H, vs.x / FIT_W))
	width = vs.x / k
	name = "DB1"; set_anchors_preset(Control.PRESET_FULL_RECT); theme = GS.ledger_theme(k)
	var veil = TextureRect.new(); veil.texture = GS.ledger_veil(); veil.set_anchors_preset(Control.PRESET_FULL_RECT); veil.mouse_filter = MOUSE_FILTER_IGNORE; add_child(veil)
	_build()

func px(v: float) -> int: return int(round(v * k))   # this page's own scale (see setup)

func _at(node: Control, rect: Rect2, parent: Control = self) -> Control:
	parent.add_child(node); node.position = rect.position * k; node.size = rect.size * k
	return node

func words(t: String, rect: Rect2, size_px := 18, col := GS.TEXT2, face: Font = null, parent: Control = self) -> Label:
	var l = Label.new(); l.text = t; l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", GS.sheet_body() if face == null else face)
	l.add_theme_font_size_override("font_size", px(size_px)); l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF if t in ["S", "L", "R", "P", "V", "A", "F", "Esc", "Enter"] else TextServer.AUTOWRAP_WORD_SMART
	_at(l, rect, parent); ink.append({"node": l, "size": size_px, "color": col, "text": t})
	return l

func heading(t: String, rect: Rect2, size_px := 30) -> Label:
	return words(t.to_upper(), rect, size_px, GS.TEXT, GS.sheet_name())

func link(t: String, rect: Rect2, cb: Callable, tip := "", parent: Control = self) -> Button:
	var b = Button.new(); b.text = t; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GS.plain_button(b, k, 18, GS.sheet_body())
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_disabled_color"]: b.add_theme_color_override(state, GS.TEXT2 if state != "font_hover_color" else GS.TEXT)
	b.add_theme_stylebox_override("focus", GS.ledger_focus(k)); b.tooltip_text = tip
	b.pressed.connect(cb); _at(b, rect, parent)
	var parts = t.rsplit(" ", true, 1)
	if parts.size() == 2 and parts[1] in ["S", "L", "R", "P", "V", "A", "F", "Esc"]:
		b.text = parts[0].strip_edges()
		var start = GS.sheet_body().get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(18)).x / k + 10
		var key_label = words(parts[1], Rect2(start, 0, rect.size.x - start, rect.size.y), 17, GS.TEXT2, GS.num(), b)
		key_label.autowrap_mode = TextServer.AUTOWRAP_OFF; key_label.size.y = rect.size.y * k; key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ink.append({"node": b, "size": 18, "color": GS.TEXT2, "text": b.text})
	return b

func hover(node: Control, text: String) -> void:
	node.mouse_filter = MOUSE_FILTER_PASS; node.tooltip_text = text

func meter(rect: Rect2, value: float, total: float, ticks: Array = []) -> Control:
	var track = Control.new(); track.mouse_filter = MOUSE_FILTER_PASS
	track.set_meta("value", value); track.set_meta("total", total); track.set_meta("ticks", ticks)
	track.draw.connect(func():
		track.draw_rect(Rect2(Vector2.ZERO, track.size), GS.SHEET_HAIR)
		track.draw_rect(Rect2(Vector2.ZERO, Vector2(track.size.x * clampf(value / maxf(1.0, total), 0, 1), track.size.y)), GS.TEXT2)
		for tick in ticks:
			var x = track.size.x * float(tick) / maxf(1, total)
			track.draw_line(Vector2(x, -5 * k), Vector2(x, track.size.y + 5 * k), GS.TEXT, maxf(1, k)))
	_at(track, rect)
	return track

func _build() -> void:
	var w = width - 144.0; var left = (w - 80.0) * 0.5; var right = 72.0 + left + 80.0
	var first = not d["victory"] and not d["abandoned"] and int(C.META["stats"].get("losses", 0)) == 1
	if first: words("THE FIRST CRUSADE FALLS. THE CHALK REMEMBERS." if R["fac"] == "voidsworn" else "THE FIRST RUN ENDS. THE NEXT INHERITS.", Rect2(72, 20, w, 25), 17)
	var title = str(C.WIN_TITLE.get(R["fac"], "Victory")) if d["victory"] else ("Run abandoned" if d["abandoned"] else "The fleet is lost")
	var h = heading(title, Rect2(72, 46, w, 112), 84)
	var context = ui._story_text() + "\nVictories so far: " + str(C.META["stats"].get("wins", 0)) + ".\nWon with: "
	var facs = []
	for fac in C.META["stats"].get("wonFacs", []): facs.append(str(C.FACTIONS[fac]["n"]))
	context += ", ".join(PackedStringArray(facs)) + ".\nThe record R."
	hover(h, context)
	var story = str(C.ADMIRALS[R["admiral"]]["n"]) + " brings the " + str(C.FACTIONS[R["fac"]]["n"]).trim_prefix("The ") + " home."
	if d["victory"]: story = C.numstr(R["stats"]["bosses"]) + (" flagship broken across " if int(R["stats"]["bosses"]) == 1 else " flagships broken across ") + C.numstr(R["sector"]) + " sectors. " + story
	else: story = "The fleet stands down. Its deeds are recorded." if d["abandoned"] else "The last hull goes dark in sector " + C.roman(R["sector"]) + (". The next fleet inherits what this run bought." if first else ". The survivors will tell it differently.")
	words(story, Rect2(72, 169, w, 58), 23)
	var s = R["stats"]
	var figures = [[C.numstr(s["battles"]), "BATTLES WON"], [C.numstr(s["bosses"]), "FLAGSHIPS DESTROYED"], [C.numstr(s["kills"]), "ENEMY SHIPS DESTROYED"], [C.numstr(s.get("lost", 0)), "SHIPS LOST"]]
	if d.get("mins") != null: figures.append([C.numstr(d["mins"]) + "m", "PLAYED"])
	for i in figures.size():
		var x = 72 + w * i / figures.size()
		words(figures[i][0], Rect2(x, 232, w / figures.size() - 18, 78), 60, GS.TEXT, GS.num())
		var caption = words(figures[i][1], Rect2(x, 307, w / figures.size() - 18, 30), 17, GS.TEXT3)
		if i == 3: hover(caption, _fallen_text())
	_build_timeline(w)
	_build_renown(left)
	_build_admiral(left)
	_build_heirs(right, left)
	_build_fleet(w, right)

func _run_events() -> Array:
	# Stop at this run's end and start, never include events from a previous run.
	var events = []; var found_end = false
	for i in range(C.tel_log.size() - 1, -1, -1):
		var event = C.tel_log[i]
		if event.get("ev") == "run_end":
			if found_end: break
			found_end = true
		if event.get("ev") == "run_start": break
		if event.get("ev") == "battle_end": events.push_front(event)
	return events

func _build_timeline(w: float) -> void:
	words("THE RUN", Rect2(72, 369, w, 28), 17, GS.TEXT3)
	timeline = _run_events()
	var chart = Control.new(); chart.mouse_filter = MOUSE_FILTER_PASS; chart.name = "RunTimeline"
	var tips = []
	for event in timeline: tips.append("Sector " + C.roman(event.get("sector", 1)) + ": " + str(event.get("kind", "battle")) + ", " + str(event.get("result", "")) + "; " + C.numstr(event.get("lost", 0)) + " ships lost.")
	if timeline.is_empty(): tips.append("The older run has no battle sequence recorded. Totals above are its saved figures.")
	chart.tooltip_text = "\n".join(PackedStringArray(tips))
	_at(chart, Rect2(72, 410, w, 42))
	for sector in range(1, 4):
		var label = "SECTOR " + C.roman(sector) if sector <= int(R["sector"]) else "UNREACHED"
		var caption = words(label, Rect2(72 + w * (sector - 1) / 3.0, 382, w / 3, 28), 17, GS.TEXT3, GS.num())
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nodes = []
	for sector in range(1, 4):
		var events = timeline.filter(func(e): return int(e.get("sector", 1)) == sector)
		for i in events.size(): nodes.append({"x": ((sector - 1) + float(i + 1) / (events.size() + 1)) / 3.0, "event": events[i]})
	chart.set_meta("events", nodes)
	chart.draw.connect(func():
		chart.draw_line(Vector2(0, 9 * k), Vector2(chart.size.x, 9 * k), GS.SHEET_HAIR, maxf(1, k))
		for sector in mini(3, int(R["sector"])):
			chart.draw_circle(Vector2(chart.size.x * sector / 3.0, 9 * k), 7 * k, GS.TEXT2, false, maxf(1, k), true)
		for node in nodes:
			var x = chart.size.x * node["x"]; var e = node["event"]
			chart.draw_line(Vector2(x, 2 * k), Vector2(x, 16 * k), GS.TEXT2, maxf(1, k))
			if e.get("kind") == "boss" and e.get("result") == "win": chart.draw_circle(Vector2(x, 9 * k), 15 * k, GS.TEXT, false, maxf(1, k), true)
			if int(e.get("lost", 0)) > 0:
				chart.draw_line(Vector2(x - 5 * k, 26 * k), Vector2(x + 5 * k, 36 * k), GS.HULL_LOW, maxf(1, k))
				chart.draw_line(Vector2(x - 5 * k, 36 * k), Vector2(x + 5 * k, 26 * k), GS.HULL_LOW, maxf(1, k)))
	var legend = "Battle |   Flagship kill O   Loss x   " + ("HOME" if d["victory"] else ("STOOD DOWN" if d["abandoned"] else "FLEET LOST"))
	if timeline.is_empty(): legend = "Battle sequence unavailable for this older run. Saved totals above."
	words(legend, Rect2(72, 459, w, 27), 17)

func _build_renown(w: float) -> void:
	heading("What it bought", Rect2(72, 507, w, 41))
	var cy = R["carry"]; var balance = float(C.META.get("renown", receipt["balance"]))
	var earned = words(C.numstr(cy["ren"]), Rect2(72, 557, 160, 70), 52, GS.TEXT, GS.num())
	words("earned this run", Rect2(240, 580, w - 440, 30), 20)
	words("in the vault", Rect2(72 + w - 260, 580, 140, 30), 20)
	words(C.numstr(balance), Rect2(72 + w - 114, 557, 114, 70), 52, GS.TEXT, GS.num())
	var breakdown = "What this " + ("victory" if d["victory"] else "death") + " bought:\n" + C.numstr(float(R["stats"]["battles"]) * 2) + " from battles, " + C.numstr(float(R["stats"]["elites"]) * 4) + " from elites, " + C.numstr(float(R["stats"]["bosses"]) * 15) + " from flagships, " + C.numstr(floor(float(R["stats"]["kills"]) / 4)) + " from kills, " + C.numstr((float(R["sector"]) - 1) * 5) + " for sectors reached.\nFull receipt B."
	hover(earned, breakdown)
	var aff = ui._end_afford(R); var target = aff[0]; var next = {}
	var available = []
	for id in C.LEGACY:
		var u = C.LEGACY[id]
		if not C.jt(C.META["unlocked"].get(id)) and (not C.jt(u.get("req")) or C.jt(C.META["unlocked"].get(u["req"]))): available.append(u)
	for u in C.HULL_VARIANTS.values():
		if not C.jt(u.get("arc")) and not C.jt(C.META["variants"].get(C.HULL_VARIANTS.find_key(u))): available.append(u)
	for id in C.ADMIRALS:
		if float(C.ADMIRALS[id].get("cost", 0)) > 0 and not C.jt(C.META["admirals"].get(id)): available.append(C.ADMIRALS[id])
	available.sort_custom(func(a, b): return float(a["cost"]) < float(b["cost"]))
	for u in available:
		if float(u["cost"]) > balance: next = u; break
	var limit = maxf(1, maxf(balance * 1.15, float(next.get("cost", target.get("cost", 1))) * 1.15))
	var ticks = []
	if not target.is_empty(): ticks.append(float(target["cost"]))
	if not next.is_empty() and next.get("cost") != target.get("cost"): ticks.append(float(next["cost"]))
	var bar = meter(Rect2(72, 639, w, 9), balance, limit, ticks)
	var detail = "Playtest: everything unlocked. Earnings recorded." if C.playtestAll() else (str(target.get("n", "All rewards owned")) + (" - " + C.numstr(target["cost"]) if not target.is_empty() else ""))
	var marker = "All rewards owned" if target.is_empty() else str(target["n"]) + " - " + C.numstr(target["cost"]) + (" - NOW AFFORDABLE" if balance >= float(target["cost"]) else " - NEXT UNLOCK")
	words(marker, Rect2(72, 663, w * 0.72, 32), 17)
	if not next.is_empty():
		words("NEXT " + C.numstr(next["cost"]), Rect2(72 + w * 0.76, 663, w * 0.24, 32), 17, GS.TEXT3, GS.num())
	else:
		words("ALL WITHIN REACH" if not target.is_empty() else "ALL OWNED", Rect2(72 + w * 0.76, 663, w * 0.24, 32), 17, GS.TEXT3)
	var reward_lines = [detail, str(next.get("n", "")), str(aff[1]) + " rewards newly within reach."]
	for item in receipt["affordable"]: reward_lines.append(str(item["n"]) + ": " + C.numstr(item["cost"]) + " renown")
	if float(cy["hl"]) > 0: reward_lines.append("Heat " + C.numstr(cy["hl"]) + ": renown paid at x" + C.numstr(1 + 0.1 * float(cy["hl"])) + ".")
	if float(cy["ren"]) == 0: reward_lines.append("No renown earned this run.")
	bar.tooltip_text = "\n".join(PackedStringArray(reward_lines)) + "\nSpend renown P; full receipt B; view hull rewards V."
	earned.tooltip_text += "\n" + bar.tooltip_text
	link("Spend renown   P", Rect2(72, 700, 190, 34), func(): open_detail("spend"))
	link("View hull rewards   V", Rect2(280, 700, 250, 34), func(): open_detail("hulls"))

func _build_admiral(w: float) -> void:
	var id = str(R["admiral"]); var line = receipt["flown"]
	var portrait = TextureRect.new(); portrait.texture = Portraits.face(id, int(line["level"]), int(line.get("capLevel", 0))); portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_at(portrait, Rect2(72, 748, 84, 84)); hover(portrait, "View admiral line A.\n+" + C.numstr(R["carry"]["mxGain"]) + " XP this run.\nRecorded skills: " + ", ".join(PackedStringArray(line["chosen"])))
	portrait.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: open_detail("lineage"))
	heading(str(C.ADMIRALS[id]["n"]), Rect2(176, 744, w - 104, 42), 30)
	words("LEVEL " + str(line["level"]), Rect2(176, 794, 140, 28), 17, GS.TEXT3, GS.num())
	meter(Rect2(330, 795, w - 258, 9), float(line["xp"]), float(line["next"]) if line["next"] != null else maxf(1, float(line["xp"])))
	var xp = C.numstr(line["xp"]) + (" XP - FULL MASTERY" if line["next"] == null else " / " + C.numstr(line["next"]) + " XP - " + C.numstr(line["remaining"]) + " TO NEXT LEVEL")
	words(xp, Rect2(330, 812, w - 258, 28), 17)
	link("View admiral line   A", Rect2(176, 849, w - 104, 32), func(): open_detail("lineage"))

func _build_heirs(x: float, w: float) -> void:
	heading("Heir to the line", Rect2(x, 507, w, 41))
	var ids = C.shadowAdmirals(R["fac"], R["admiral"])
	var current = str(C.META["heirs"].get(R["fac"], "")); var cw = (w - 32) / maxf(1, ids.size())
	var group = ButtonGroup.new()
	for i in ids.size():
		var id = str(ids[i]); var cx = x + i * (cw + 16)
		var card = Button.new(); card.toggle_mode = true; card.button_group = group; card.button_pressed = ui._end_heir_pick == id; card.disabled = ui._end_confirmed
		card.name = "Heir_" + id; card.set_meta("id", id)
		for state in ["normal", "hover", "pressed", "disabled"]: card.add_theme_stylebox_override(state, GS.ledger_card(k, ui._end_heir_pick == id))
		card.add_theme_stylebox_override("focus", GS.ledger_focus(k))
		_at(card, Rect2(cx, 548, cw, 272)); cards.append(card)
		card.pressed.connect(func(): choose_heir(id))
		var crest = TextureRect.new(); crest.texture = Portraits.crest(id); crest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; crest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; crest.mouse_filter = MOUSE_FILTER_IGNORE
		_at(crest, Rect2(cx + (cw - 144) / 2, 564, 144, 112))
		var ranked = ui._end_heir_label(id); var comma = ranked.rfind(", ")
		var label = heading(ranked.substr(0, comma), Rect2(cx + 8, 668, cw - 16, 72), 28); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var rank = words(ranked.substr(comma + 2), Rect2(cx + 8, 744, cw - 16, 26), 17, GS.TEXT3); rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var line = C.inheritanceLine(id); var total = float(line["next"]) if line["next"] != null else maxf(1, float(line["xp"]))
		meter(Rect2(cx + 16, 779, cw - 32, 8), float(line["xp"]), total)
		var shadow = C.numstr(snapped(float(line["xp"]), 0.01)) + " shadow XP"
		words(shadow, Rect2(cx + 16, 790, cw - 32, 29), 17, GS.TEXT2, GS.num())
		var tip = ranked + ". Total " + C.numstr(line["xp"]) + " shadow XP. " + ("Fully mastered." if line["next"] == null else C.numstr(line["remaining"]) + " XP to next level.") + "\nDouble earnings for this line when named."
		for row in receipt["shadow"]:
			if row["id"] == id: tip += "\n+" + C.numstr(snapped(float(row["xp"]), 0.01)) + " shadow XP this run (Level " + C.numstr(row["level"]) + ")." + (" Heir: double rate." if float(row["rate"]) == 0.5 else "")
		if id == current: tip += "\nCurrent heir. Confirming this card keeps the current heir."
		card.tooltip_text = tip
		if id == current:
			var current_label = words("CURRENT HEIR", Rect2(cx + 8, 550, cw - 16, 25), 17, GS.TEXT3)
			current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if ids.is_empty(): words("No benched admirals to name. Confirm to continue.", Rect2(x, 570, w, 90), 20)
	var note = "Named: " + str(C.ADMIRALS[ui._end_heir_pick]["n"]) if ui._end_confirmed and ui._end_heir_pick != "" else "Whoever is named earns double for this line."
	if current == "" and not ui._end_confirmed: note = "No heir named. Confirm the selected line to continue."
	words(note, Rect2(x, 823, w, 26), 17)
	primary = Button.new(); primary.name = "ConfirmHeir"; primary.set_meta("end_primary", true)
	for state in ["normal", "hover", "pressed", "disabled"]: primary.add_theme_stylebox_override(state, GS.sheet_jump_boxes(k)[state])
	primary.add_theme_stylebox_override("focus", GS.ledger_focus(k))
	primary.add_theme_color_override("font_color", GS.TEXT); primary.add_theme_color_override("font_hover_color", GS.ON_EMBER)
	_at(primary, Rect2(x, 851, w, 56))
	var label = "CONFIRM HEIR" if not ui._end_confirmed else ("PLAY AS " + str(C.FACTIONS[d["next"]]["n"]).to_upper() if d["next"] != null else "PICK THE NEXT FACTION")
	var action_words = words(label, Rect2(22, 0, w - 130, 56), 20, GS.TEXT, GS.sheet_medium(), primary)
	var key_words = words("Enter", Rect2(w - 90, 0, 74, 56), 17, GS.TEXT2, GS.num(), primary)
	action_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; key_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary.mouse_entered.connect(func(): action_words.add_theme_color_override("font_color", GS.ON_EMBER); key_words.add_theme_color_override("font_color", GS.ON_EMBER))
	primary.mouse_exited.connect(func(): action_words.add_theme_color_override("font_color", GS.TEXT); key_words.add_theme_color_override("font_color", GS.TEXT2))
	primary.pressed.connect(advance)

func choose_heir(id: String) -> void:
	if ui._end_confirmed: return
	ui._end_heir_pick = id
	for card in cards:
		var selected = card.get_meta("id") == id; card.button_pressed = selected
		for state in ["normal", "hover", "pressed", "disabled"]: card.add_theme_stylebox_override(state, GS.ledger_card(k, selected))

func advance() -> void:
	if not ui._end_confirmed: ui._end_confirm(); return
	ui._campaign_action("nextFac", d["next"]) if d["next"] != null else ui._campaign_action("newRunScreen")

func _fallen_text() -> String:
	var names = []
	for f in R["fallen"]: names.append(str(f["name"]))
	return "Captains lost: " + (", ".join(PackedStringArray(names)) if not names.is_empty() else "None")

func _fleet_tip() -> String:
	var lines = ["The fleet that finished it (full record F):"]
	for ship in R["fleet"]:
		var car = ship.get("car", {})
		lines.append(str(ship["name"]) + ", " + str(C.HULLS[ship["tpl"]]["n"]) + ": " + C.numstr(car.get("kills", 0)) + " kills, " + C.numstr(car.get("dealt", 0)) + " damage. " + str(C.rankName(ship["cap"])) + " " + str(ship["cap"]["name"]))
	if R["fleet"].is_empty(): lines.append("No ships still flying.")
	lines.append(_fallen_text())
	return "\n".join(PackedStringArray(lines))

func _build_fleet(w: float, right: float) -> void:
	for ship in R["fleet"]:
		if ship.get("uid") == R.get("flagUid"): flagship = ship; break
	if flagship.is_empty() and not ui._end_last_flagship.is_empty() and is_same(ui._end_live_run, R): flagship = ui._end_last_flagship
	words("THE FLEET THAT FINISHED IT" if d["victory"] else ("LAST FLAGSHIP - LOST" if R["fleet"].is_empty() and not flagship.is_empty() else "THE FLEET'S LAST RECORD"), Rect2(72, 931, w, 25), 17, GS.TEXT3)
	if not flagship.is_empty():
		ship_portrait = ShipPortrait.new(); _at(ship_portrait, Rect2(72, 961, 264, 104)); ship_portrait.setup(C, flagship)
		hover(ship_portrait, _fleet_tip())
		ship_portrait.gui_input.connect(func(e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: open_detail("fleet"))
		if not ship_portrait.installed: words("Hull render unavailable", Rect2(72, 999, 264, 30), 17)
		var name_label = heading(str(flagship["name"]), Rect2(360, 953, width - 1100, 44), 30)
		var car = flagship.get("car", {}); var caption = C.numstr(car.get("kills", 0)) + " KILLS - " + C.numstr(car.get("dealt", 0)) + " DMG"
		hover(name_label, "Flagship: " + str(flagship["name"]) + ", " + caption + " across " + C.numstr(car.get("battles", 0)) + " battles.\nFull fleet F.")
		words(str(C.HULLS[flagship["tpl"]]["n"]) + " - " + str(C.rankName(flagship["cap"])) + " " + str(flagship["cap"]["name"]), Rect2(360, 1000, 320, 46), 17)
		words(caption, Rect2(360, 1044, 320, 28), 17, GS.TEXT2, GS.num())
	else: words("No ships still flying.\nThe fleet and its losses are recorded.   F", Rect2(72, 965, 560, 76), 20)
	var lost_text = _fallen_text()
	if GS.sheet_body().get_string_size(lost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(18)).x > (width - 1448) * k:
		lost_text = "Captains lost: " + str(R["fallen"].size()) + " - full roll F"
	var lost = words(lost_text, Rect2(704, 1000, width - 1448, 28), 18); hover(lost, _fallen_text())
	link("Core sync S", Rect2(704, 1027, 135, 32), func(): open_detail("cores"))
	link("Nemesis lesson L", Rect2(850, 1027, 174, 32), func(): open_detail("nemesis"))
	link("The record R", Rect2(1032, 1027, 145, 32), func(): open_detail("record"))
	var nx = maxf(right, width - 620)
	words("NEXT RUN", Rect2(nx, 961, 548, 28), 17, GS.TEXT3)
	var next_name = str(C.FACTIONS[d["next"]]["n"]) if d["next"] != null else str(C.FACTIONS[R["fac"]]["n"])
	var next_label = heading(next_name, Rect2(nx, 990, width - nx - 72, 42), 30)
	hover(next_label, str(C.FACTIONS[d["next"] if d["next"] != null else R["fac"]].get("blurb", "")))
	var pick = link("Pick a faction", Rect2(nx, 1033, 140, 32), func(): ui._campaign_action("newRunScreen"))
	var title = link("Title screen", Rect2(nx + 160, 1033, 130, 32), func(): ui._campaign_action("title"))
	for exit in [pick, title]:
		exit.disabled = not ui._end_confirmed; exit.tooltip_text = "Confirm the heir first." if exit.disabled else ""; exits.append(exit)

func open_detail(which: String) -> void:
	if is_instance_valid(overlay): overlay.queue_free()
	section = which
	if which == "spend": ui._campaign_action("progTab", "legacy"); return
	if which == "hulls": ui._campaign_action("progTab", "variants"); return
	overlay = Control.new(); overlay.name = "LedgerDetail"; overlay.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(overlay)
	var shade = ColorRect.new(); shade.color = Color(GS.INK, 0.96); shade.set_anchors_preset(Control.PRESET_FULL_RECT); overlay.add_child(shade)
	var panel = PanelContainer.new(); panel.add_theme_stylebox_override("panel", GS.tip(k))
	_at(panel, Rect2((width - 1080) / 2, 110, 1080, 860), overlay)
	var col = ui.vbox(16); panel.add_child(col)
	var close = link("Close   Esc", Rect2(0, 0, 160, 34), close_detail, "", col)
	close.custom_minimum_size.y = px(40)
	var titles = {"cores": "Core sync", "nemesis": "Nemesis lesson", "record": "The record", "renown": "What it bought", "lineage": "Admiral line", "fleet": "The fleet", "admirals": "Admiral rewards"}
	var title = ui.lbl(str(titles.get(which, which)).to_upper(), 32, GS.TEXT, GS.sheet_name()); col.add_child(title)
	var sc = ScrollContainer.new(); sc.size_flags_vertical = SIZE_EXPAND_FILL; sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; col.add_child(sc)
	var body = ui._end_detail_body(d, which); body.size_flags_horizontal = SIZE_EXPAND_FILL; sc.add_child(body)
	if which == "fleet" and R["fleet"].is_empty(): body.add_child(ui.lbl("No ships still flying.", 18, GS.TEXT2))
	close.grab_focus()
	# issue 1559 item 16: modal for the keyboard (Tab cannot reach the heir cards or Confirm behind the shade)
	load("res://ui/theme/modal_focus.gd").attach(overlay, close)

func close_detail() -> void:
	if is_instance_valid(overlay): overlay.queue_free()
	overlay = null; section = ""; primary.grab_focus()

func handle_key(e: InputEventKey) -> bool:
	if is_instance_valid(overlay):
		if e.keycode == KEY_ESCAPE: close_detail()
		return true
	if KEYS.has(e.keycode): open_detail(KEYS[e.keycode]); return true
	if e.keycode >= KEY_1 and e.keycode <= KEY_3:
		var i = int(e.keycode - KEY_1)
		if i < cards.size(): choose_heir(str(cards[i].get_meta("id")))
		return true
	if e.keycode in [KEY_ENTER, KEY_KP_ENTER]: advance(); return true
	return false
