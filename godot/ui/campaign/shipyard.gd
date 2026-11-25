extends MarginContainer
## SY-A Gantry. The yard owns selection and preview display. Campaign owns every transaction.

const GS := preload("res://ui/theme/glass_shell.gd")
const Kit := preload("res://ui/theme/orders_kit.gd")
const Podium := preload("res://ui/campaign/flagship_podium.gd")
const Portraits := preload("res://portraits/portraits.gd")
const PreviewOp := preload("res://campaign/preview_op.gd")

const STAT_NAMES := {
	"hull": "Hull", "max_hull": "Hull capacity", "shield_pool": "Shield pool", "shield_regen": "Shield recharge",
	"armor": "Armor", "speed": "Speed", "turns": "Turns", "evasion": "Evasion", "aim": "Aim", "crit": "Critical chance",
	"weapon_damage_multiplier": "Weapon multiplier", "hangar": "Hangar", "hull_regen": "Hull repair",
	"mark": "Mark", "refit_count": "Fitted refits", "command_points": "Command points",
}
const WEAPON_NAMES := {"damage": "Damage", "shots": "Shots", "range": "Range", "optimal_range": "Optimal range", "reload": "Reload"}
const SHIP_SECTIONS := {"F": "Prow", "P": "Mid", "S": "Mid", "R": "Engines", "T": "Turret"}

var ui
var C
var k := 1.0
var selected := {}
var state: Dictionary
var stock: Dictionary
var market_scroll: ScrollContainer
var inspector_scroll: ScrollContainer
var tip_dock: HBoxContainer
var repair_all: Button
var _narrow_scroll: ScrollContainer
var _roster: VBoxContainer
var _market: VBoxContainer
var _refits: VBoxContainer
var _hull_offers: Control
var _inspector: VBoxContainer
var _stage: Control
var _podium: Control
var _bay_code: Label
var _bay_status: Label
var _live_stats: VBoxContainer
var _delta_stats: VBoxContainer
var _delta_caption: Label
var _meters := {}
var _preview_key := ""
var _preview_tpl := ""
var _pending_model := 0
var _compact := false


func setup(owner_ui, shared_state: Dictionary) -> void:
	ui = owner_ui
	C = ui.C
	k = ui.k
	state = shared_state
	stock = C.page["data"]["node"]["stock"]
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	for side in ["top", "left", "right"]:
		add_theme_constant_override("margin_" + side, px(24))
	add_theme_constant_override("margin_bottom", px(86))
	draw.connect(func(): draw_rect(Rect2(Vector2.ZERO, size), Color(GS.INK, 0.94)))
	var page := _column(10)
	add_child(page)
	var available: float = ui.get_viewport().get_visible_rect().size.x / k - 48.0
	_compact = available < 900.0
	_build_head(page)
	tip_dock = HBoxContainer.new()
	tip_dock.alignment = BoxContainer.ALIGNMENT_END
	tip_dock.hide()
	page.add_child(tip_dock)
	var layout: BoxContainer
	if _compact:
		_narrow_scroll = _scroll()
		page.add_child(_narrow_scroll)
		layout = _column(18)
		_narrow_scroll.add_child(layout)
	else:
		layout = _row(20)
		layout.size_flags_vertical = SIZE_EXPAND_FILL
		page.add_child(layout)
	var left := _column(9)
	left.add_child(_section("Fleet"))
	if not _compact: left.custom_minimum_size.x = px(306 if available >= 1350 else 238)
	layout.add_child(left)
	market_scroll = _scroll()
	if _compact: market_scroll.custom_minimum_size.y = px(230)
	left.add_child(market_scroll)
	var listing := _column(8)
	market_scroll.add_child(listing)
	_roster = _column(6)
	listing.add_child(_roster)
	_refits = _column(4)
	listing.add_child(_refits)
	_market = _column(7)
	listing.add_child(_market)
	_build_market()
	layout.add_child(_build_bay())
	_inspector = _column(7)
	if not _compact: _inspector.custom_minimum_size.x = px(482 if available >= 1450 else (408 if available >= 1120 else 350))
	layout.add_child(_inspector)
	var first = C._ship(str(state.get("uid", "")))
	if first == null: first = C.flagshipOf()
	if first == null and not C.RUN["fleet"].is_empty(): first = C.RUN["fleet"][0]
	if first != null: _select(first, false)
	else: _inspector.add_child(_word("No ships in the fleet.", GS.TEXT2))


func _build_head(page: VBoxContainer) -> void:
	var head := HFlowContainer.new()
	head.add_theme_constant_override("h_separation", px(24))
	head.add_child(Kit.heading("Shipyard", 42, k))
	var gap := Control.new()
	gap.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(gap)
	if C.hullKey() == "bio": head.add_child(ui._readout("Biomass", C.numstr(C.z0(C.RUN.get("bio"))), GS.TEXT, true))
	head.add_child(ui._readout("Credits", C.numstr(C.RUN["credits"]), GS.TEXT, true))
	head.add_child(ui._readout("Command points", C.numstr(C.fleetCP()) + "/" + C.numstr(C.RUN["cpCap"]), GS.TEXT, true))
	page.add_child(head)
	var offers := HFlowContainer.new()
	offers.add_theme_constant_override("h_separation", px(10))
	page.add_child(offers)
	var repairs: Array = C.preview_op("repairAll")
	var hurt := repairs.any(func(row): return row["delta"] > 0)
	repair_all = _campaign_button("Repair entire fleet for " + _price(repairs[0], false) if hurt else "Fleet fully repaired", "repairAll")
	var all := _with_reason(offers, repair_all, str(repairs[0]["disabled_reason"]))
	if hurt: _wire_preview(repair_all, "repairAll", "", -1, "Repair fleet", all)
	var hold := _campaign_button("Manage refits", "yardFleet")
	offers.add_child(hold)
	var biomass: bool = C.hullKey() == "bio"
	if biomass:
		page.add_child(_word("The Chorus regrow with biomass: repairs, new hulls and Marks are paid in biomass. Refits, upgrade tracks, protocol rerolls and the late market take biomass first, then credits.", GS.TEXT2))
	var pm: float = C.priceMult()
	var rate: String = C.numstr(snappedf(pm, 0.0001))
	var unit: String = "biomass" if biomass else ("credit" if pm == 1.0 else "credits")
	var rank: String = str(C.CAPTAINS[C.RUN["fac"]]["ranks"][0]).to_lower()
	var help := _word("Repairs cost %s %s per 2 hull, rounded up. A Mark upgrade adds 20%% hull and shields and 15%% damage. New hulls come with a fresh %s." % [rate, unit, rank], GS.TEXT2)
	page.add_child(help)


func _build_bay() -> Control:
	var bay := _column(6)
	bay.size_flags_horizontal = SIZE_EXPAND_FILL
	var log := _row(10)
	log.add_child(_section("Gantry"))
	var fill := Control.new()
	fill.size_flags_horizontal = SIZE_EXPAND_FILL
	log.add_child(fill)
	_bay_code = _line("", GS.TEXT2, Kit.mono_font())
	log.add_child(_bay_code)
	bay.add_child(log)
	_stage = Control.new()
	_stage.name = "GantryBay"
	_stage.size_flags_vertical = SIZE_EXPAND_FILL
	_stage.custom_minimum_size.y = px(370) if _compact else 0
	var backing := ColorRect.new()
	backing.color = Color("#0d1218")
	backing.mouse_filter = MOUSE_FILTER_IGNORE
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(backing)
	bay.add_child(_stage)
	_bay_status = _word("", GS.TEXT2)
	bay.add_child(_bay_status)
	return bay


func _select(ship: Dictionary, keep_focus: bool) -> void:
	_clear_preview(_preview_key)
	selected = ship
	state["uid"] = ship["uid"]
	_clear(_roster)
	var picked: Button
	for s: Dictionary in C.RUN["fleet"]:
		var b := _roster_row(s)
		_roster.add_child(b)
		if s["uid"] == ship["uid"]: picked = b
	if keep_focus and is_instance_valid(picked): picked.grab_focus()
	_build_inspector()
	_build_refits()
	_show_model(ship, false)


func _roster_row(ship: Dictionary) -> Button:
	var id: String = ship["uid"]
	var active: bool = id == selected["uid"]
	var full: float = C.derive(ship)["maxHp"]
	var hurt := float(ship["hp"]) < full
	var hull: Dictionary = C.HULLS[ship["tpl"]]
	var b := Kit.button("", k, "quiet")
	b.flat = true
	b.set_meta("yard_ship", id)
	b.custom_minimum_size.y = px(74)
	b.pressed.connect(_select.bind(ship, true))
	b.tooltip_text = "%s\n%s · Mk %s\nHull %s/%s" % [ship["name"], hull["n"], C.roman(ship["mk"]), C.hull_text(ship["hp"]), C.hull_text(full)]
	var inset := MarginContainer.new()
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		inset.add_theme_constant_override("margin_" + side, px(8))
	b.add_child(inset)
	var line := _row(8)
	inset.add_child(line)
	line.add_child(_face(ship["cap"], 34))
	var words := _column(1)
	words.size_flags_horizontal = SIZE_EXPAND_FILL
	line.add_child(words)
	words.add_child(_line(str(ship["name"]), GS.MAP_EMBER if active else GS.TEXT, Kit.medium_font(), true))
	words.add_child(_line("%s · Mk %s" % [C.clsName(hull["cls"]), C.roman(ship["mk"])], GS.TEXT2, null, true))
	words.add_child(_meter(float(ship["hp"]), full, GS.HULL_LOW if hurt else GS.HULL, 3))
	if hurt:
		var pip := _line("●", GS.HULL_LOW)
		pip.tooltip_text = "Hull damaged"
		line.add_child(pip)
	_ignore_input(inset)
	return b


func _build_inspector() -> void:
	_clear(_inspector)
	_meters.clear()
	var t: Dictionary = C.HULLS[selected["tpl"]]
	var d: Dictionary = C.derive(selected)
	var cap: Dictionary = selected["cap"]
	_inspector.add_child(_word(str(selected["name"]).to_upper(), GS.TEXT, 34, Kit.head_font()))
	var subtitle: String = "%s · %s · Mk %s" % [t["n"], C.clsName(t["cls"]), C.roman(selected["mk"])]
	if is_same(selected, C.flagshipOf()): subtitle += " · Flagship"
	_inspector.add_child(_word(subtitle, GS.TEXT2))
	inspector_scroll = _scroll()
	if _compact: inspector_scroll.custom_minimum_size.y = px(370)
	_inspector.add_child(inspector_scroll)
	var details := _column(6)
	inspector_scroll.add_child(details)
	_captain(details, cap)
	_add_meter(details, "hull", "Hull", selected["hp"], d["maxHp"], GS.HULL_LOW if selected["hp"] < d["maxHp"] else GS.HULL)
	_add_meter(details, "shield_pool", "Shield pool", d["shMax"], d["shMax"], GS.GLACIER)
	if float(selected["hp"]) < float(d["maxHp"]) and selected.get("yard_sections") is Dictionary:
		var cut := PackedStringArray()
		var recorded: Dictionary = Podium.damage_snapshot(selected, d["maxHp"])["sec"]
		for pair in [["prow", "Prow"], ["mid", "Mid"], ["eng", "Engines"]]:
			if recorded[pair[0]].get("broken") == true: cut.append(pair[1])
		if not cut.is_empty(): details.add_child(_word("Last battle damage · " + ", ".join(cut) + " lost", GS.HULL_LOW))
	if C.jt(selected.get("ripped")): details.add_child(_word("Captured prize, links ripped out.", GS.TEXT2))
	_live_stats = _column(4)
	details.add_child(_live_stats)
	_live_stats.add_child(_section("Armament"))
	for w: Dictionary in d["weapons"]:
		var name := _word("%s  ·  %s" % [w["n"], SHIP_SECTIONS.get(w["arc"], "Unassigned")], GS.TEXT)
		var arc: String = C.ARC_NAME.get(w["arc"], w["arc"])
		name.mouse_filter = MOUSE_FILTER_PASS
		name.tooltip_text = "%s · %s × %s damage · range %s · reload %s" % [arc, C.numstr(w["shots"]), C.numstr(float(w["dmg"]) * float(d["dmg"])), C.numstr(w["r"]), C.numstr(w.get("cd", 0))]
		_live_stats.add_child(name)
	_live_stats.add_child(_section("Stats"))
	for key in ["armor", "speed", "turns", "ev", "regen"]:
		var stat: String = {"ev": "evasion", "regen": "shield_regen"}.get(key, key)
		_add_row(_live_stats, STAT_NAMES[stat], _fmt(stat, d[key]), GS.GLACIER if key == "regen" else GS.TEXT)
	if C.jt(t.get("ab")) and C.ABILITIES.has(t["ab"]):
		var ability: Dictionary = C.ABILITIES[t["ab"]]
		var text := _word(str(ability["n"]), GS.TEXT2)
		text.tooltip_text = str(ability["d"])
		text.mouse_filter = MOUSE_FILTER_PASS
		_live_stats.add_child(text)
	_live_stats.add_child(_section("Fitted refits"))
	var mods := PackedStringArray()
	var effects := PackedStringArray()
	for mod in selected["mods"]:
		mods.append(C.modName(mod))
		effects.append(str(C.MODULES[mod]["d"]))
	var equipped := _word("None fitted" if mods.is_empty() else ", ".join(mods), GS.TEXT2)
	equipped.mouse_filter = MOUSE_FILTER_PASS
	equipped.tooltip_text = "\n".join(effects)
	_live_stats.add_child(equipped)
	_live_stats.add_child(_word("%d of %d slots used" % [mods.size(), int(C.z0(t.get("slots")))], GS.TEXT2))
	_delta_stats = _column(4)
	_delta_stats.hide()
	details.add_child(_delta_stats)
	_delta_caption = _word("", GS.TEXT2, 17, Kit.medium_font())
	_delta_caption.hide()
	_inspector.add_child(_delta_caption)
	_build_actions()


func _captain(parent: VBoxContainer, cap: Dictionary) -> void:
	var row := _row(12)
	row.add_child(_face(cap, 76))
	var identity := _column(2)
	identity.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(identity)
	identity.add_child(_word(str(cap["callsign"]).to_upper(), GS.TEXT, 28, Kit.head_font()))
	identity.add_child(_word("%s %s" % [C.rankName(cap), cap["full_name"]], GS.TEXT2))
	var rank := int(cap["rank"])
	var xp := float(cap["xp"])
	var next: float = C.RANK_XP[rank + 1] if rank + 1 < C.RANK_XP.size() else 0.0
	identity.add_child(_word("XP %s / %s" % [C.numstr(xp), C.numstr(next)] if next > 0 else "%s XP · Highest rank" % C.numstr(xp), GS.TEXT2))
	if next > 0:
		var start: float = C.RANK_XP[rank]
		identity.add_child(_meter(xp - start, next - start, GS.VERD, 3))
	var trait_line: String = str(cap["trait_line"])
	if not trait_line.is_empty(): identity.add_child(_word(trait_line, GS.TEXT2))
	if C.jt(cap["pending"]):
		identity.add_child(_campaign_button("Choose promotion perk", "promote", selected["uid"]))
	parent.add_child(row)


func _build_actions() -> void:
	var uid: String = selected["uid"]
	var repairs: Array = C.preview_op("repair", uid)
	var mark: Dictionary = ui._preview_row(C.preview_op("upgradeMk", uid), "mark")
	var mark_label: String = "Mk " + C.roman(mark["new"]) + " for " + _price(mark, false) if mark["old"] < 3 else "Max Mark"
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", px(8))
	actions.add_theme_constant_override("v_separation", px(4))
	_inspector.add_child(actions)
	var repair_label: String = ui._yard_repair_label(repairs, " biomass" if repairs[0]["currency"] == "bio" else "")
	var b := _campaign_button(repair_label, "repair", uid)
	var item := _with_reason(actions, b, str(repairs[0]["disabled_reason"]))
	_wire_preview(b, "repair", uid, -1, "Repair", item)
	b = _campaign_button(mark_label, "upgradeMk", uid)
	item = _with_reason(actions, b, str(mark["disabled_reason"]))
	_wire_preview(b, "upgradeMk", uid, -1, mark_label, item)
	var fit: Array = []
	for i in C.RUN["inventory"].size():
		if C.preview_op("refit", uid, i)[0]["disabled_reason"].is_empty(): fit.append(i)
	var refit_reason := "The hold is empty." if C.RUN["inventory"].is_empty() else ("No compatible refit." if fit.is_empty() else "")
	b = Kit.button("Refit", k, "quiet", func(): _go_to(_refits), 17)
	b.disabled = not refit_reason.is_empty()
	item = _with_reason(actions, b, refit_reason)
	if fit.size() == 1: _wire_preview(b, "refit", uid, fit[0], "Fit " + C.modName(C.RUN["inventory"][fit[0]]), item)
	b = Kit.button("New hull", k, "quiet", func(): _go_to(_hull_offers), 17)
	var hulls: Array = stock["hulls"] + _captured()
	b.disabled = hulls.is_empty()
	item = _with_reason(actions, b, "No hulls in stock." if b.disabled else "")
	if hulls.size() == 1:
		_wire_preview(b, "buyHull", hulls[0], -1, C.HULLS[hulls[0]]["n"], item)
	# Decommission stays apart from the work orders because its confirmation cannot be undone.
	var gap := Control.new()
	gap.custom_minimum_size.y = px(14)
	_inspector.add_child(gap)
	_inspector.add_child(HSeparator.new())
	var cash := _price({"cost": C.sellValue(selected), "currency": C.hullKey()})
	b = _campaign_button("Decommission · +" + cash, "sellShip", uid)
	var apart := _with_reason(_inspector, b, "Keep at least one ship." if b.disabled else "")
	apart.name = "ApartRow"


func _build_refits() -> void:
	_clear(_refits)
	if C.RUN["inventory"].is_empty(): return
	_refits.add_child(_section("Refits in hold"))
	var uid: String = selected["uid"]
	for i in C.RUN["inventory"].size():
		var mod: String = C.RUN["inventory"][i]
		var name: String = "Fit " + C.modName(mod)
		var rows: Array = C.preview_op("refit", uid, i)
		var b := _campaign_button(name, "equip", "%d:%s" % [i, uid])
		b.disabled = not str(rows[0]["disabled_reason"]).is_empty()
		b.tooltip_text = str(C.MODULES[mod]["d"])
		var item := _with_reason(_refits, b, str(rows[0]["disabled_reason"]))
		_wire_preview(b, "refit", uid, i, name, item)


func _build_market() -> void:
	if stock.get("late") is Dictionary:
		_market.add_child(_section("Late market"))
		for o: Dictionary in C.lateShopOffers():
			var relic: bool = o["kind"] == "relic"
			var title: String = C.relicName(o["r"]) if relic else "Command expansion"
			_market.add_child(_word(title, GS.TEXT, 18, Kit.medium_font()))
			_market.add_child(_word(C.relicText(o["r"]) if relic else "+1 command point for the rest of the run.", GS.TEXT2))
			if C.jt(o["done"]): _market.add_child(_word("Bought", GS.TEXT2))
			elif C.jt(o.get("full")): _market.add_child(_word("Already at the limit", GS.TEXT2))
			else: _with_reason(_market, _campaign_button("Buy for " + C.numstr(o["cost"]) + C.shopWord(o["cost"]), "lateBuy", o["id"]), "" if o["ok"] else "Not enough funds.")
	_hull_offers = _section("Hulls for sale")
	_market.add_child(_hull_offers)
	for h: String in stock["hulls"]: _hull_for_sale(h, false)
	var captured := _captured()
	if not captured.is_empty():
		_market.add_child(_section("Captured hulls"))
		_market.add_child(_word("Links ripped out. No synchronized fire or Archive restore.", GS.TEXT2))
	for h: String in captured: _hull_for_sale(h, true)
	var cores: Array = C.or_(C.RUN.get("cores"), [])
	if not cores.is_empty():
		_market.add_child(_section("Recovered cores"))
		_market.add_child(_word("Each core regrows its ship at Mk I, full hull, no refits.", GS.TEXT2))
	for i in cores.size():
		_market.add_child(_word(str(C.HULLS[cores[i]]["n"]), GS.TEXT, 18, Kit.medium_font()))
		ui._hull_summary(_market, C.incoming_ship(cores[i]), "core:" + str(i))
		var b := _campaign_button("Regrow for " + C.numstr(C.coreCost(cores[i])) + " credits", "restoreCore", i)
		var reason := "Not enough credits." if float(C.RUN["credits"]) < float(C.coreCost(cores[i])) else "Not enough command points."
		_with_reason(_market, b, reason if b.disabled else "")
	_market.add_child(_section("Refits for sale"))
	for i in stock["mods"].size():
		var mod: String = stock["mods"][i]
		_market.add_child(_word(C.modName(mod), GS.TEXT, 18, Kit.medium_font()))
		_market.add_child(_word(str(C.MODULES[mod]["d"]), GS.TEXT2))
		if C._has_num(stock["sold"], i): _market.add_child(_word("Bought", GS.TEXT2))
		else:
			var quote: Dictionary = C.preview_op("buyMod", "", i)[0]
			_with_reason(_market, _campaign_button("Buy for " + _price(quote), "buyMod", i), str(quote["disabled_reason"]))
	_market.add_child(_section("Class refits"))
	_market.add_child(_word("A class refit upgrades every ship of that class you own now or later. +6% hull and +6% damage per level.", GS.TEXT2))
	for cls in C.fleetClasses():
		var lv := int(C.classTrack(cls))
		var mx := int(C.CLASS_TRACK_MAX)
		var price: float = C.classTrackCost(cls)
		var desc: String = C.clsName(cls) + " " + "●".repeat(lv) + "○".repeat(mx - lv)
		var b := _campaign_button(desc + (" (full)" if lv >= mx else " for " + C.numstr(price) + C.shopWord(price)), "buyTrack", cls)
		_with_reason(_market, b, ("Maximum refit level." if lv >= mx else "Not enough funds.") if b.disabled else "")


func _hull_for_sale(tpl: String, captured: bool) -> void:
	var hull: Dictionary = C.HULLS[tpl]
	var offer := PreviewOp.plan(C, "buyHull", tpl, -1)
	var quote: Dictionary = offer["rows"][0]
	var name: String = hull["n"]
	_market.add_child(_word(name, GS.TEXT, 19, Kit.medium_font()))
	if C.jt(hull.get("variant")): _market.add_child(_word(str(C.HULL_VARIANTS[hull["variant"]]["d"]), GS.TEXT2))
	ui._hull_summary(_market, offer["ship"], ("cap:" if captured else "yard:") + tpl)
	var b := _campaign_button("Buy for " + _price(quote), "buyHull", tpl)
	var item := _with_reason(_market, b, str(quote["disabled_reason"]))
	_wire_preview(b, "buyHull", tpl, -1, name, item)


func _captured() -> Array:
	return stock["cap"] if stock.get("cap") is Array else []


func _wire_preview(button: Button, action: String, key: String, slot: int, label: String, item: Control) -> void:
	var id := "%s:%s:%s:%s" % [action, key, slot, button.get_instance_id()]
	var show := _preview.bind(id, action, key, slot, label)
	var hide := _clear_preview.bind(id)
	item.mouse_entered.connect(show)
	item.mouse_exited.connect(hide)
	button.mouse_entered.connect(show)
	button.mouse_exited.connect(func():
		if not item.get_global_rect().has_point(item.get_global_mouse_position()): hide.call())
	button.focus_entered.connect(show)
	button.focus_exited.connect(hide)
	button.set_meta("yard_preview", id)


func _preview(id: String, action: String, key: String, slot: int, label: String) -> void:
	if selected.is_empty() or not is_instance_valid(_delta_stats) or C.modal_d != null: return
	if _preview_key == id: return
	_reset_meters()
	_preview_key = id
	var plan := PreviewOp.plan(C, action, key, slot)
	var changes: Array = plan["rows"].filter(func(r): return not is_zero_approx(float(r["delta"])))
	_clear(_delta_stats)
	_delta_stats.add_child(_section("Preview"))
	var emphasis: Dictionary = {}
	for row: Dictionary in changes:
		if emphasis.is_empty(): emphasis = row
		var name := _stat_name(row, plan)
		var val := _change_text(row)
		var rendered := _word(name + " " + val, GS.VERD if row["is_better"] else GS.BLOOD, 17, Kit.mono_font())
		rendered.set_meta("preview_row", row.duplicate())
		_delta_stats.add_child(rendered)
	if changes.is_empty(): _delta_stats.add_child(_word("No stats change.", GS.TEXT2))
	_live_stats.hide()
	_delta_stats.show()
	_delta_caption.text = "Preview · %s" % label
	if not emphasis.is_empty():
		_delta_caption.text = _stat_name(emphasis, plan) + " " + _change_text(emphasis)
		_delta_caption.add_theme_color_override("font_color", GS.VERD if emphasis["is_better"] else GS.BLOOD)
	else: _delta_caption.add_theme_color_override("font_color", GS.TEXT2)
	_delta_caption.show()
	var uid: String = selected["uid"]
	var for_ship: Array = changes.filter(func(r): return r["ship_uid"] == uid or action == "buyHull")
	var projected_full: float = _meters["hull"].get_meta("full")
	for row: Dictionary in for_ship:
		if row["stat_key"] == "max_hull": projected_full = row["new"]
	for row: Dictionary in for_ship:
		var stat: String = row["stat_key"]
		if _meters.has(stat):
			var meter: Control = _meters[stat]
			meter.set_meta("next", row["new"])
			meter.set_meta("denom", maxf(float(meter.get_meta("full")), projected_full if stat == "hull" else float(row["new"])))
			meter.queue_redraw()
	_pending_model += 1
	if action == "buyHull" and is_inside_tree():
		_preview_model_after(_pending_model, plan["ship"])
	else:
		if not _preview_tpl.is_empty(): _show_model(selected, false)
		if is_instance_valid(_podium):
			var repair := action in ["repair", "repairAll"] and for_ship.any(func(r): return r["stat_key"] == "hull" and r["delta"] > 0)
			_podium.preview_repair(repair)


func _preview_model_after(ticket: int, ship: Dictionary) -> void:
	await get_tree().create_timer(0.18).timeout
	if ticket == _pending_model and not is_queued_for_deletion() and C.modal_d == null: _show_model(ship, true)


func _clear_preview(id: String) -> void:
	if id.is_empty() or id != _preview_key: return
	_preview_key = ""
	_pending_model += 1
	_delta_caption.hide()
	_delta_stats.hide()
	_live_stats.show()
	_reset_meters()
	if not _preview_tpl.is_empty(): _show_model(selected, false)
	elif is_instance_valid(_podium): _podium.preview_repair(false)


func _reset_meters() -> void:
	for meter: Control in _meters.values():
		if meter.has_meta("next"): meter.remove_meta("next")
		if meter.has_meta("denom"): meter.remove_meta("denom")
		meter.queue_redraw()


func _show_model(ship: Dictionary, candidate: bool) -> void:
	_preview_tpl = str(ship["tpl"]) if candidate else ""
	if not _stage.is_inside_tree():
		# ShipView's fitted mesh transforms are valid only after the bay has entered the tree.
		_show_initial_model.call_deferred(ship, candidate)
		return
	if is_instance_valid(_podium):
		_stage.remove_child(_podium)
		_podium.queue_free()
	_podium = Podium.new()
	_podium.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(_podium)
	_podium.setup(C, ship, GS.TEXT2, ui._reduce_motion(), true)
	if candidate: _podium.modulate = Color(0.81, 0.9, 1.0)
	_bay_code.text = _podium.code
	_bay_status.text = ("Offer preview · " if candidate else "") + ("Drag to orbit" if _podium.installed else "Model unavailable")


func _show_initial_model(ship: Dictionary, candidate: bool) -> void:
	if is_inside_tree() and not is_queued_for_deletion(): _show_model(ship, candidate)


func _stat_name(row: Dictionary, plan: Dictionary) -> String:
	var key: String = row["stat_key"]
	if key.begins_with("weapon."):
		var parts := key.split(".")
		var guns: Array = C.derive(plan["ship"])["weapons"]
		return "%s · %s" % [guns[int(parts[1])]["n"], WEAPON_NAMES[parts[2]]]
	if plan["action"] == "repairAll":
		var ship = C._ship(row["ship_uid"])
		if ship != null and ship["uid"] != selected["uid"]: return "%s hull" % ship["name"]
	return STAT_NAMES.get(key, key.capitalize())


func _change_text(row: Dictionary) -> String:
	var stat: String = row["stat_key"]
	return "%s to %s (%s%s)" % [_fmt(stat, row["old"]), _fmt(stat, row["new"]), "+" if row["delta"] > 0 else "", _fmt(stat, row["delta"])]


func _fmt(stat: String, value: float) -> String:
	if stat in ["armor", "crit"]: return C.pct(value)
	return C.numstr(snappedf(value, 0.01))


func _price(row: Dictionary, with_credits := true) -> String:
	var purse: String = row["currency"]
	return C.numstr(row["cost"]) + (" biomass" if purse == "bio" else (" credits" if purse == "credits" and with_credits else ""))


func _campaign_button(text: String, action: String, arg = "") -> Button:
	var b := Kit.button(text, k, ui.cue_role(action, "quiet"), _activate.bind(action, arg), 17)
	var found: Array = ui._find(C.page["acts"], action, arg)
	b.disabled = found.is_empty() or found[2] == 0
	ui.press_tag(b, action, arg)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.tooltip_text = text
	return b


func _activate(action: String, arg) -> void:
	var count: int = C.RUN["fleet"].size()
	ui._campaign_action(action, arg)
	if action == "buyHull" and C.RUN["fleet"].size() > count:
		state["uid"] = C.RUN["fleet"].back()["uid"]


func _with_reason(parent: Container, button: Button, reason: String) -> VBoxContainer:
	var item := _column(1)
	if parent is HFlowContainer:
		item.custom_minimum_size.x = minf(px(310), Kit.medium_font().get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px(17)).x + px(28))
	else: item.size_flags_horizontal = SIZE_EXPAND_FILL
	if not reason.is_empty():
		var why := _word(reason, GS.TEXT2)
		item.add_child(why)
		button.tooltip_text = button.text + "\n" + reason
		if reason in ["Not enough credits.", "Not enough biomass.", "Not enough funds."]:
			button.add_theme_color_override("font_disabled_color", GS.BLOOD)
	item.add_child(button)
	parent.add_child(item)
	return item


func _go_to(target: Control) -> void:
	if not is_instance_valid(target): return
	if _narrow_scroll != null: _narrow_scroll.ensure_control_visible(market_scroll)
	market_scroll.ensure_control_visible(target)


func _add_meter(parent: VBoxContainer, key: String, label: String, value: float, full: float, tint: Color) -> void:
	_add_row(parent, label, "%s / %s" % [C.hull_text(value), C.hull_text(full)] if key == "hull" else C.numstr(value), tint)
	var meter := _meter(value, full, tint, 6)
	meter.set_meta("yard_meter", key)
	meter.set_meta("full", full)
	_meters[key] = meter
	parent.add_child(meter)


func _add_row(parent: VBoxContainer, label: String, value: String, tint: Color) -> void:
	var row := _row(6)
	var word := _word(label, GS.TEXT2)
	word.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(word)
	row.add_child(_line(value, tint, Kit.mono_font()))
	parent.add_child(row)


func _meter(value: float, full: float, tint: Color, height: float) -> Control:
	var bar := Control.new()
	bar.mouse_filter = MOUSE_FILTER_IGNORE
	bar.custom_minimum_size.y = px(height)
	bar.draw.connect(func():
		var denom := maxf(float(bar.get_meta("denom")) if bar.has_meta("denom") else full, 1.0)
		var old := clampf(value / denom, 0.0, 1.0) * bar.size.x
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), GS.BAR_TRACK)
		if old > 0.0: bar.draw_rect(Rect2(0, 0, old, bar.size.y), tint)
		if bar.has_meta("next"):
			var next := clampf(float(bar.get_meta("next")) / denom, 0.0, 1.0) * bar.size.x
			if next > old: bar.draw_rect(Rect2(old, 0, next - old, bar.size.y), Color(GS.VERD, 0.7))
			elif next < old:
				bar.draw_rect(Rect2(next, 0, old - next, bar.size.y), Color(GS.BLOOD, 0.5))
				var x := next
				while x < old:
					var run := minf(bar.size.y, old - x)
					bar.draw_line(Vector2(x, bar.size.y), Vector2(x + run, bar.size.y - run), GS.BLOOD)
					x += px(5))
	return bar


func _face(cap: Dictionary, side: float) -> Control:
	var texture := Portraits.captain_face(str(cap["portrait_id"]))
	if texture == null: texture = Portraits.faction_crest(str(cap["fac"]))
	var face := TextureRect.new()
	face.texture = texture
	face.custom_minimum_size = Vector2.ONE * px(side)
	face.size_flags_vertical = SIZE_SHRINK_BEGIN
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = MOUSE_FILTER_IGNORE
	return face


func _word(value: String, tint: Color, size_px := 17, face: Font = null) -> Label:
	return Kit.label(value, size_px, k, tint, face, true, 58)


func _line(value: String, tint: Color, face: Font = null, trim := false) -> Label:
	var label := Kit.label(value, 17, k, tint, face, false)
	if trim: label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _section(value: String) -> Control:
	return Kit.section(value, k)


func _row(gap: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", px(gap))
	return row


func _column(gap: float) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", px(gap))
	return col


func _scroll() -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = SIZE_EXPAND_FILL
	sc.follow_focus = true
	return sc


func _clear(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _ignore_input(node: Control) -> void:
	node.mouse_filter = MOUSE_FILTER_IGNORE
	for child: Control in node.get_children(): _ignore_input(child)


func px(value: float) -> int:
	return Kit.px(value, k)
