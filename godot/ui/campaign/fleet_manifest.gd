extends Control
# FL5, The Manifest (R285). Selection and held refits are local UI state.
# All changes still go through the campaign's existing equip, unequip and verb actions.
const GS = preload("res://ui/theme/glass_shell.gd")
const View = preload("res://campaign/campaign_view.gd")
const Portrait = preload("res://ui/campaign/fleet_portrait.gd")
var ui
var C
var state: Dictionary
var back := ""
var k := 1.0
var width := 1920.0
var height := 1080.0
var manifest_w := 736.0
var middle_x := 848.0
var middle_w := 608.0
var sheet_x := 1528.0
var sheet_w := 320.0
var rows: Array = []
var ink: Array = []
var portraits := {}
var workspace: Control
var detail: Control
var primary: Button
var manifest_scroll: ScrollContainer

func setup(host, data: Dictionary, local_state: Dictionary) -> void:
	ui = host; C = ui.C; state = local_state; back = str(data.get("back", "")); k = ui.k
	var size = ui.get_viewport().get_visible_rect().size / k; width = size.x; height = size.y
	# Preserve FL5's proportions at the shared player UI scale, without shrinking type.
	manifest_w = (width - 144) * 0.4144
	sheet_w = (width - 144) * 0.1802; sheet_x = width - 72 - sheet_w
	middle_x = 72 + manifest_w + 40; middle_w = sheet_x - 72 - middle_x
	name = "FL5"; set_anchors_preset(Control.PRESET_FULL_RECT); theme = GS.ledger_theme(k)
	var veil = TextureRect.new(); veil.texture = GS.ledger_veil(); veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = MOUSE_FILTER_IGNORE; add_child(veil)
	if C._ship(state["uid"]) == null:
		var flag = C.flagshipOf(); state["uid"] = str(flag["uid"]) if flag != null else (str(C.RUN["fleet"][0]["uid"]) if not C.RUN["fleet"].is_empty() else "")
	build()

func at(n: Control, rect: Rect2, parent: Control = self) -> Control:
	parent.add_child(n); n.position = rect.position * k; n.size = rect.size * k; return n

func words(t: String, rect: Rect2, fs := 18, col := GS.TEXT2, face: Font = null, parent: Control = self) -> Label:
	var l = Label.new(); l.text = t; l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", GS.sheet_body() if face == null else face)
	l.add_theme_font_size_override("font_size", ui.px(fs)); l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; at(l, rect, parent)
	ink.append(l); return l

func head(t: String, rect: Rect2, fs := 28, parent: Control = self) -> Label:
	return words(t.to_upper(), rect, fs, GS.TEXT, GS.sheet_name(), parent)

func style_link(b: Button) -> void:
	GS.plain_button(b, k, 18, GS.sheet_body()); b.add_theme_stylebox_override("focus", GS.ledger_focus(k))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(st, GS.TEXT if st in ["font_hover_color", "font_pressed_color", "font_focus_color"] else GS.TEXT2)

func link(t: String, rect: Rect2, cb: Callable, parent: Control = self, tip := "") -> Button:
	var b = Button.new(); b.text = t; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	style_link(b)
	b.tooltip_text = tip; b.pressed.connect(cb); at(b, rect, parent); ink.append(b); return b

func meter(parent: Control, rect: Rect2, hp: float, total: float, col := GS.TEXT2) -> void:
	var bar = Control.new(); bar.mouse_filter = MOUSE_FILTER_IGNORE
	bar.draw.connect(func():
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), GS.SHEET_HAIR)
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * clampf(hp / maxf(1, total), 0, 1), bar.size.y)), col))
	at(bar, rect, parent)

func picture(ship: Dictionary, rect: Rect2, parent: Control) -> void:
	var tpl = str(ship["tpl"])
	if not portraits.has(tpl): portraits[tpl] = Portrait.make(self, C, ship, Vector2i(ui.px(middle_w * 2), ui.px(middle_w)))
	var art = portraits[tpl]
	if art["texture"] == null:
		words("Model unavailable", rect, 17, GS.TEXT2, null, parent); return
	var tr = TextureRect.new(); tr.texture = art["texture"]; tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; tr.mouse_filter = MOUSE_FILTER_IGNORE; at(tr, rect, parent)

func build() -> void:
	head("Fleet", Rect2(72, 38, 400, 78), 52)
	var damaged = C.RUN["fleet"].filter(func(s): return float(s["hp"]) < float(C.derive(s)["maxHp"]))
	words(str(C.RUN["fleet"].size()), Rect2(middle_x + middle_w * 0.2, 48, 150, 56), 40, GS.TEXT, GS.num_bold())
	words("SHIPS", Rect2(middle_x + middle_w * 0.2, 108, 150, 26), 17, GS.TEXT3)
	words(str(damaged.size()), Rect2(middle_x + middle_w * 0.55, 48, 150, 56), 40, GS.TEXT, GS.num_bold())
	words("DAMAGED", Rect2(middle_x + middle_w * 0.55, 108, 160, 26), 17, GS.TEXT3)
	var fa = View.faction_action(C)
	if not fa.is_empty():
		var title = head(fa["n"], Rect2(72, 140, manifest_w * 0.55, 38))
		title.mouse_filter = MOUSE_FILTER_PASS; title.tooltip_text = fa["d"] + "\n" + fa["cost"]
		var cost = str(fa["cost_short"]).replace("credits", "CR").replace("a refit from the hold", "1 refit").replace("experience from your flagship captain", "XP")
		if cost.begins_with("Free"): cost = "Free"
		var price = words(cost, Rect2(72 + manifest_w * 0.55, 148, manifest_w * 0.3, 28), 17, GS.TEXT2, GS.num())
		price.mouse_filter = MOUSE_FILTER_PASS; price.tooltip_text = fa["cost"]
		link("Change  C", Rect2(72 + manifest_w * 0.87, 142, 130, 36), func(): mode("doctrine"))
	var rule = ColorRect.new(); rule.color = GS.SHEET_HAIR; rule.mouse_filter = MOUSE_FILTER_IGNORE
	at(rule, Rect2(72, 184, width - 144, 1))
	manifest_scroll = ScrollContainer.new(); manifest_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	at(manifest_scroll, Rect2(50, 210, manifest_w + 22, height - 314))
	var list = VBoxContainer.new(); list.size_flags_horizontal = Control.SIZE_EXPAND_FILL; list.add_theme_constant_override("separation", 0)
	manifest_scroll.add_child(list)
	for group in [damaged, C.RUN["fleet"].filter(func(s): return not damaged.has(s))]:
		if group.is_empty(): continue
		var heading = Control.new(); heading.custom_minimum_size.y = ui.px(40); list.add_child(heading)
		head(("Damaged" if group == damaged else "Full hull") + "  " + str(group.size()), Rect2(22, 0, manifest_w, 36), 28, heading)
		for ship in group: row(ship, group == damaged, list)
	if C.RUN["fleet"].is_empty(): words("No ships in the fleet.", Rect2(72, 216, manifest_w, 40))
	words("Hover a ship for its class and ability", Rect2(72, height - 52, manifest_w, 28), 17)
	workspace = Control.new(); at(workspace, Rect2(middle_x, 216, middle_w, height - 330))
	detail = Control.new(); at(detail, Rect2(sheet_x, 210, sheet_w, height - 330))
	primary = link("", Rect2(sheet_x, height - 80, sheet_w, 56), done)
	for style in GS.sheet_jump_boxes(k): primary.add_theme_stylebox_override(style, GS.sheet_jump_boxes(k)[style])
	primary.add_theme_color_override("font_hover_color", GS.ON_EMBER); primary.add_theme_color_override("font_pressed_color", GS.ON_EMBER)
	var label = head("Done", Rect2(24, 0, 130, 56), 28, primary); label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var key = words("Enter", Rect2(sheet_w - 95, 0, 80, 56), 17, GS.TEXT2, GS.num(), primary); key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary.mouse_entered.connect(func(): label.add_theme_color_override("font_color", GS.ON_EMBER); key.add_theme_color_override("font_color", GS.ON_EMBER))
	primary.mouse_exited.connect(func(): label.add_theme_color_override("font_color", GS.TEXT); key.add_theme_color_override("font_color", GS.TEXT2))
	refresh()

func row(ship: Dictionary, damaged: bool, parent: Control) -> void:
	var hull = C.HULLS[ship["tpl"]]; var derived = C.derive(ship)
	var name_w = GS.sheet_name().get_string_size(str(ship["name"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, ui.px(28)).x / k
	var cls_w = GS.sheet_body().get_string_size(hull["n"], HORIZONTAL_ALIGNMENT_LEFT, -1, ui.px(17)).x / k
	var available = manifest_w - 238; var wrap_class = name_w + cls_w + 18 > available
	var name_height = maxf(38, ceilf(name_w / maxf(1, available)) * 36)
	var rh = maxf(54, name_height + (24 if wrap_class else 0) + (28 if damaged else 0))
	var b = Button.new(); b.text = ""; style_link(b)
	b.custom_minimum_size.y = ui.px(rh); parent.add_child(b)
	b.pressed.connect(func(): select_ship(str(ship["uid"])))
	var ability = C.ABILITIES.get(hull.get("ab"), {})
	b.tooltip_text = str(ship["name"]) + "\n" + str(hull["n"]) + " Mk " + C.roman(ship["mk"]) + "\nHull " + C.hull_text(ship["hp"]) + " / " + C.hull_text(derived["maxHp"]) + "\n" + str(ability.get("n", "")) + ": " + str(ability.get("d", ""))
	picture(ship, Rect2(22, 5, 150, 40), b)
	head(ship["name"], Rect2(188, 0, available if wrap_class else name_w + 2, name_height), 28, b)
	words(hull["n"], Rect2(188 if wrap_class else 206 + name_w, name_height - 4 if wrap_class else 9, available if wrap_class else cls_w + 3, 26), 17, GS.TEXT2, null, b)
	words(C.numstr(hull["cp"])+ " CP", Rect2(manifest_w - 52, 9, 72, 28), 17, GS.TEXT2, GS.num(), b)
	if damaged:
		var y = name_height + (24 if wrap_class else 0)
		meter(b, Rect2(188, y + 9, 130, 5), ship["hp"], derived["maxHp"], GS.HULL_LOW)
		words(C.hull_text(ship["hp"]) + " / " + C.hull_text(derived["maxHp"]), Rect2(334, y - 2, 210, 28), 17, GS.HULL_LOW, GS.num(), b)
	b.draw.connect(func():
		if state["uid"] == ship["uid"]: b.draw_rect(Rect2(Vector2(0, 18) * k, Vector2(10, 10) * k), GS.TEXT))
	rows.append({"ship": ship, "button": b, "damaged": damaged})

func clear_region(region: Control) -> void:
	for ch in region.get_children(): region.remove_child(ch); ch.queue_free()
	ink = ink.filter(func(n): return is_instance_valid(n) and n.is_inside_tree())

func mode(which: String) -> void:
	state["mode"] = which; state["held"] = {}; refresh()

func select_ship(uid: String) -> void:
	var held = state["held"]
	if not held.is_empty() and held["uid"] != uid:
		var source = C._ship(held["uid"]); var target = C._ship(uid)
		if source != null and int(held["slot"]) < source["mods"].size():
			var m = source["mods"][held["slot"]]
			if C.canFitModule(target, m):
				var inventory_index = C.RUN["inventory"].size()
				C.act("unequip", held["uid"] + ":" + str(held["slot"]))
				C.act("equip", str(inventory_index) + ":" + uid)
				state["held"] = {}; state["mode"] = ""
	state["uid"] = uid
	if state["held"].is_empty(): state["mode"] = ""
	refresh()

func refresh() -> void:
	clear_region(workspace); clear_region(detail)
	for r in rows: r["button"].queue_redraw()
	var ship = C._ship(state["uid"])
	if ship != null: specification(ship)
	if state["mode"] == "doctrine": doctrine(); return
	if ship == null: words("Select a ship to inspect its refits.", Rect2(0, 40, middle_w, 60), 18, GS.TEXT2, null, workspace); return
	if state["mode"] == "hold": hold(ship); return
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.set_anchors_preset(PRESET_FULL_RECT); workspace.add_child(sc)
	var v = VBoxContainer.new(); v.size_flags_horizontal = SIZE_EXPAND_FILL; v.add_theme_constant_override("separation", ui.px(8)); sc.add_child(v)
	v.add_child(ui.gap(24))
	var art = Control.new(); art.custom_minimum_size.y = ui.px(middle_w * 0.54); v.add_child(art)
	picture(ship, Rect2(0, 0, middle_w, middle_w * 0.54), art)
	v.add_child(ui.gap(16))
	var hull = C.HULLS[ship["tpl"]]
	v.add_child(body(str(ship["name"]).to_upper(), 32, GS.TEXT, GS.sheet_name()))
	v.add_child(body(str(hull["n"]) + " · Mk " + C.roman(ship["mk"]) + " · " + C.numstr(hull["cp"]) + " CP"))
	v.add_child(ui.gap(20))
	v.add_child(body("REFITS", 17, GS.TEXT3))
	for i in int(C.z0(hull.get("slots"))):
		var line = HBoxContainer.new(); line.add_theme_constant_override("separation", ui.px(16)); v.add_child(line)
		var filled = i < ship["mods"].size() and C.jt(ship["mods"][i])
		var t = C.modName(ship["mods"][i]) if filled else "Empty refit slot"
		var slot = Button.new(); slot.text = t; style_link(slot); slot.alignment = HORIZONTAL_ALIGNMENT_LEFT; slot.size_flags_horizontal = SIZE_EXPAND_FILL
		for st in ["normal", "hover", "pressed", "disabled"]:
			var empty = StyleBoxEmpty.new(); empty.content_margin_left = ui.px(38); slot.add_theme_stylebox_override(st, empty)
		var held_here = not state["held"].is_empty() and state["held"]["uid"] == ship["uid"] and state["held"]["slot"] == i
		if held_here: slot.add_theme_color_override("font_color", GS.MAP_EMBER)
		slot.draw.connect(func(): slot.draw_rect(Rect2(Vector2(1, 4) * k, Vector2(24, 24) * k), GS.MAP_EMBER if held_here else GS.TEXT2, false, maxf(1, k)))
		slot.set_meta("slot", i); slot.set_meta("uid", ship["uid"]); slot.custom_minimum_size.y = ui.px(32)
		slot.tooltip_text = str(C.MODULES[ship["mods"][i]]["d"]) + "\nClick, then choose a ship to move this refit." if filled else "Choose a refit from the hold."
		slot.pressed.connect(func():
			if filled: state["held"] = {"uid": ship["uid"], "slot": i}; refresh()
			else: mode("hold"))
		line.add_child(slot)
		if filled:
			var remove = Button.new(); remove.text = "Remove"; style_link(remove)
			remove.set_meta("remove_slot", i); remove.pressed.connect(func(): state["held"] = {}; C.act("unequip", ship["uid"] + ":" + str(i))); line.add_child(remove)
	if int(C.z0(hull.get("slots"))) == 0: v.add_child(body("This hull has no refit slots."))
	v.add_child(body("Refits move between ships freely."))
	if not state["held"].is_empty():
		v.add_child(body("Choose a ship with a free compatible slot. Esc cancels.", 18, GS.TEXT))
		var source = C._ship(state["held"]["uid"])
		if source != null:
			v.add_child(body("Moving " + C.modName(source["mods"][state["held"]["slot"]]), 18, GS.MAP_EMBER))
	var hold_button = Button.new(); hold_button.text = "In the hold  " + str(C.RUN["inventory"].size()) + "   H"; style_link(hold_button); hold_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	hold_button.pressed.connect(func(): mode("hold")); v.add_child(hold_button)

func body(t: String, fs := 18, col := GS.TEXT2, face: Font = null) -> Label:
	var l = Label.new(); l.text = t; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_override("font", GS.sheet_body() if face == null else face); l.add_theme_font_size_override("font_size", ui.px(fs)); l.add_theme_color_override("font_color", col)
	l.mouse_filter = MOUSE_FILTER_IGNORE; ink.append(l); return l

func specification(ship: Dictionary) -> void:
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; sc.set_anchors_preset(PRESET_FULL_RECT); detail.add_child(sc)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", ui.px(10)); v.size_flags_horizontal = SIZE_EXPAND_FILL; sc.add_child(v)
	var hull = C.HULLS[ship["tpl"]]; var d = C.derive(ship); var cap = ship["cap"]
	v.add_child(body(str(ship["name"]).to_upper(), 32, GS.TEXT, GS.sheet_name()))
	v.add_child(body("Mk " + C.roman(ship["mk"]) + " · " + str(hull["n"]) + " · " + C.numstr(hull["cp"]) + " CP", 17))
	if C.jt(ship.get("ripped")): v.add_child(body("Captured prize, links ripped out.", 17))
	v.add_child(body(C.hull_text(ship["hp"]) + " / " + C.hull_text(d["maxHp"]), 30, GS.HULL_LOW if float(ship["hp"]) < float(d["maxHp"]) else GS.TEXT, GS.num_bold()))
	var hp = Control.new(); hp.custom_minimum_size.y = ui.px(10); v.add_child(hp); meter(hp, Rect2(0, 0, sheet_w - 14, 8), ship["hp"], d["maxHp"])
	for line in spec_lines(C, ship):
		match line["k"]:
			"shield": v.add_child(body(line["t"], 17, GS.GLACIER, GS.num()))
			"ability": v.add_child(body(str(line["t"]).to_upper(), 28, GS.TEXT, GS.sheet_name()))
			"weapon": v.add_child(body(line["t"], 18, GS.TEXT, GS.sheet_medium()))
			"gun": v.add_child(body(line["t"], 17, GS.TEXT2, GS.num()))
			"stat": v.add_child(body(line["t"], 17))
			_: v.add_child(body(line["t"]))
	v.add_child(body(str(cap["name"]).to_upper(), 28, GS.TEXT, GS.sheet_name()))
	var rank = int(cap["rank"]); var next = C.RANK_XP[rank + 1] if rank + 1 < C.RANK_XP.size() else null
	var xp = C.rankName(cap) + " · " + C.numstr(cap["xp"])
	if next != null:
		var promoted = cap.duplicate(); promoted["rank"] = rank + 1
		xp += " of " + C.numstr(next) + " to " + C.rankName(promoted)
	else: xp += " experience, highest rank"
	v.add_child(body(xp, 17))
	if next != null:
		var progress = Control.new(); progress.custom_minimum_size.y = ui.px(8); v.add_child(progress)
		var start = float(C.RANK_XP[rank]); meter(progress, Rect2(0, 0, sheet_w - 14, 5), float(cap["xp"]) - start, float(next) - start)
	if cap["perks"].is_empty(): v.add_child(body("No perks yet.", 17))
	for p in cap["perks"]:
		v.add_child(body(str(C.PERKS[p]["n"]) + ". " + str(C.PERKS[p]["d"]), 17))
	if C.jt(cap.get("pending")):
		var promote = Button.new(); promote.text = "Choose promotion perk"; style_link(promote)
		promote.pressed.connect(func(): C.act("promote", ship["uid"])); v.add_child(promote)
	v.add_child(body("Repairs and Mark upgrades happen at shipyards and repair docks.", 17))
	var st = ui._story()
	if st != null and C.flagshipOf() != null and C.flagshipOf()["uid"] == ship["uid"]:
		var rename = Button.new(); rename.text = "Rename flagship"; style_link(rename); rename.pressed.connect(func(): st.open_rename()); v.add_child(rename)

# Issue 1449: the one full specification, shared by this sheet and the shipyard's "Full specs" drawer (shop, captured and
# regrown hulls). Each line is {"t": text, "k": shield | stat | ability | ability_d | weapon | gun}; callers pick the type.
static func spec_lines(c, ship: Dictionary) -> Array:
	var hull = c.HULLS[ship["tpl"]]; var d = c.derive(ship); var out = []
	if ship["uid"] == "" and ship["cap"].has("name"):   # a preview with a recovered captain: say whose perks the numbers include
		var ps = ship["cap"]["perks"].map(func(p): return str(c.PERKS[p]["n"]))
		out.append({"k": "captain", "t": "Comes with " + c.rankName(ship["cap"]) + " " + str(ship["cap"]["name"]) + ", recovered from the reserve" + ((" (" + ", ".join(PackedStringArray(ps)) + ")") if not ps.is_empty() else "") + ". The numbers include their perks."})
	out.append({"k": "shield", "t": "Shields " + c.numstr(d["shMax"]) + "  +" + c.numstr(d["regen"]) + "/turn"})
	out.append({"k": "stat", "t": "Armor " + c.pct(d["armor"]) + "   Speed " + c.numstr(d["speed"]) + "\nTurns " + c.numstr(d["turns"]) + "   Evasion " + c.numstr(d["ev"])})
	var ability = c.ABILITIES.get(hull.get("ab"), {})
	if not ability.is_empty():
		out.append({"k": "ability", "t": str(ability["n"])}); out.append({"k": "ability_d", "t": str(ability["d"])})
	for w in d["weapons"]:
		out.append({"k": "weapon", "t": str(w["n"])})
		var arc = "Turret" if w["arc"] == "T" else str(c.ARC_NAME.get(w["arc"], w["arc"]))
		out.append({"k": "gun", "t": arc + " · " + c.numstr(w["shots"]) + "×" + c.numstr(w["dmg"]) + " · range " + c.numstr(w["r"]) + ((" · reload " + c.numstr(w["cd"])) if c.jt(w.get("cd")) else "")})
	return out
# A hull as it would arrive (Mk I, no refits), for spec_lines only: never added to the run. Its captain is the one newShip
# would really install: the nth recovered captain in the reserve when newShip would take one (same test as newShip: no
# battle running, a reserve to draw from), else a fresh lieutenant. The reserve is read, never popped (issue 1449, Artoo).
static func preview_ship(c, tpl: String, ripped := false, nth := 0) -> Dictionary:
	var cap = {"perks": [], "rank": 0, "xp": 0}
	var R = c.RUN
	if c.B == null and R != null and R.get("reserve") is Array and nth < R["reserve"].size(): cap = R["reserve"][nth]["cap"].duplicate(true)
	var s = {"uid": "", "tpl": tpl, "mk": 1, "mods": [], "cap": cap, "hp": c.HULLS[tpl]["hp"]}
	if ripped: s["ripped"] = true
	return s

func chooser(title: String) -> VBoxContainer:
	head(title, Rect2(0, 0, middle_w, 60), 32, workspace)
	link("Back  Esc", Rect2(0, 66, middle_w, 36), func(): mode(""), workspace)
	var sc = ScrollContainer.new(); sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	at(sc, Rect2(0, 120, middle_w, height - 460), workspace)
	var v = VBoxContainer.new(); v.add_theme_constant_override("separation", ui.px(16)); v.size_flags_horizontal = SIZE_EXPAND_FILL; sc.add_child(v)
	return v

func hold(ship: Dictionary) -> void:
	var v = chooser("In the hold")
	v.add_child(body("Fit to " + str(ship["name"]), 20, GS.TEXT))
	v.add_child(body("Refits move between ships freely."))
	if C.RUN["inventory"].is_empty(): v.add_child(body("No refits in the hold. Select a fitted refit to move it to another ship."))
	for i in C.RUN["inventory"].size():
		var m = C.RUN["inventory"][i]
		v.add_child(body(C.modName(m), 20, GS.TEXT, GS.sheet_medium())); v.add_child(body(C.MODULES[m]["d"]))
		var b = Button.new(); b.text = "Fit refit" if C.canFitModule(ship, m) else "Needs a free compatible slot"
		style_link(b); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.disabled = not C.canFitModule(ship, m); b.set_meta("inventory_index", i)
		b.pressed.connect(func(): state["mode"] = ""; C.act("equip", str(i) + ":" + ship["uid"])); v.add_child(b)

func doctrine() -> void:
	var v = chooser("Fleet doctrine"); var fa = View.faction_action(C)
	if fa.is_empty(): v.add_child(body("No faction action available.")); return
	v.add_child(body(str(fa["n"]).to_upper(), 32, GS.TEXT, GS.sheet_name())); v.add_child(body(fa["d"]))
	v.add_child(body(fa["cost"], 18, GS.TEXT))
	if fa["armed"]: v.add_child(body("Armed for the next battle."))
	var b = Button.new(); b.text = "Used this sector" if fa["used"] else "Use doctrine"
	style_link(b); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.disabled = not C.verbCanUse(); b.set_meta("faction_action", true)
	b.pressed.connect(func(): state["mode"] = ""; C.act("factionVerb", "")); v.add_child(b)

func done() -> void:
	state["held"] = {}; state["mode"] = ""; C.act("backShipyard" if back == "shipyard" else "backMap", "")

func handle_key(e: InputEventKey) -> bool:
	if e.keycode == KEY_C: mode("doctrine"); return true
	if e.keycode == KEY_H: mode("hold"); return true
	if e.keycode == KEY_ESCAPE:
		if state["mode"] != "" or not state["held"].is_empty(): mode("")
		else: done()
		return true
	if e.keycode in [KEY_ENTER, KEY_KP_ENTER]: done(); return true
	return false
