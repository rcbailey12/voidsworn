extends RefCounted
## AR-A Spotlight Report. Reads the settled battle, not the post-repair fleet.

const GS = preload("res://ui/theme/glass_shell.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const UiScale = preload("res://ui/ui_scale.gd")
const KILL_POINTS := 150
const TAKEN_WEIGHT := 0.25
const SCORE_KEYS := ["kills", "damage_dealt", "damage_taken"]
const HEADERS := ["Ship / captain", "Kills", "Damage dealt", "Damage taken", "Hull left", "Captain XP"]
const WIDTHS := [188, 48, 116, 116, 72, 128]
const TABLE_WIDTH := 760.0


static func fleet_rows(rollups: Dictionary) -> Array:
	var ids := rollups.keys()
	# Unit ids follow deployment order. Keep that order after save JSON sorts the keys as text.
	ids.sort_custom(func(a, b): return str(a).naturalnocasecmp_to(str(b)) < 0)
	var rows := []
	for id in ids:
		var row: Dictionary = rollups[id]
		if row.get("side") == "player" and row.get("ship_uid", "") != "":
			rows.append(row)
	return rows


static func score(row: Dictionary) -> float:
	return KILL_POINTS * float(row["kills"]) + float(row["damage_dealt"]) + TAKEN_WEIGHT * float(row["damage_taken"])


static func mvp(rows: Array) -> Dictionary:
	var best := {}
	for row in rows:
		if best.is_empty() or _beats(row, best):
			best = row
	return best


static func _beats(a: Dictionary, b: Dictionary) -> bool:
	var delta := score(a) - score(b)
	if delta != 0.0:
		return delta > 0.0
	for key in SCORE_KEYS:
		if a[key] != b[key]:
			return a[key] > b[key]
	# Keep fleet order if even the flagship tie-break is tied.
	return a.get("flagship", false) and not b.get("flagship", false)


static func append(ui, parent: VBoxContainer, report: Dictionary, width: float, open_loss: Callable) -> bool:
	var rows := fleet_rows(report.get("ship_rollups", {}))
	if rows.is_empty():
		return false
	var table := ui.vbox(5) as VBoxContainer
	table.name = "SpotlightReport"
	parent.add_child(table)
	var k: float = ui.k
	var best := mvp(rows)
	var strip := PanelContainer.new()
	var ink := StyleBoxFlat.new()
	ink.bg_color = Color(GS.MAP_EMBER, 0.10)
	ink.border_color = GS.MAP_EMBER
	ink.border_width_left = maxi(1, UiScale.px(3, k))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		ink.set_content_margin(side, UiScale.px(10, k))
	strip.add_theme_stylebox_override("panel", ink)
	var spotlight := ui.vbox(2) as VBoxContainer
	strip.add_child(spotlight)
	var captain: Dictionary = best["captain"]
	var spotlight_name := "%s / %s" % [best["ship_name"], captain["full_name"]]
	spotlight.add_child(Kit.label(spotlight_name.to_upper(), 28, k, GS.TEXT, GS.sheet_name()))
	var kills := int(best["kills"])
	var why := "MVP: %d %s, %s damage dealt" % [kills, "kill" if kills == 1 else "kills", figure(best["damage_dealt"])]
	var reason := Kit.label(why, 18, k, GS.TEXT)
	reason.name = "MvpReason"
	spotlight.add_child(reason)
	table.add_child(strip)

	var losses := {}
	for loss in report.get("lost_ship_records", []):
		losses[loss["ship_id"]] = loss
	var dealt_max := 1.0
	var taken_max := 1.0
	for row in rows:
		dealt_max = maxf(dealt_max, float(row["damage_dealt"]))
		taken_max = maxf(taken_max, float(row["damage_taken"]))
	var wide := width >= TABLE_WIDTH
	if wide:
		var headers := ui.hbox(8) as HBoxContainer
		for i in HEADERS.size():
			_cell(headers, Kit.label(HEADERS[i], 17, k, GS.TEXT2, GS.sheet_medium(), false), i, k)
		table.add_child(headers)
	for row in rows:
		table.add_child(GS.thin_bar(k, 0.0, GS.SHEET_HAIR, 0.0, 1.0, GS.SHEET_HAIR))
		var line: BoxContainer = ui.hbox(8) if wide else ui.vbox(4)
		line.set_meta("ship_uid", row["ship_uid"])
		line.set_meta("lost", row["lost"])
		table.add_child(line)
		var col := GS.BLOOD if row["lost"] else GS.TEXT
		var identity := ui.vbox(2) as VBoxContainer
		identity.add_child(Kit.label(str(row["ship_name"]) + ("  (Lost)" if row["lost"] else ""), 19, k, col, GS.sheet_medium()))
		identity.add_child(Kit.label(str(row["captain"]["full_name"]), 17, k, GS.TEXT2))
		if row["lost"] and losses.has(row["ship_uid"]):
			var link := Kit.button("View killmail", k, "quiet", open_loss.bind(losses[row["ship_uid"]]), 17)
			link.name = "ViewKillmail"
			link.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			identity.add_child(link)
		var stats: Array[Control] = [
			_value(ui, str(int(row["kills"])), col),
			_value(ui, figure(row["damage_dealt"]), col, float(row["damage_dealt"]) / dealt_max, Color(GS.MAP_EMBER, 0.40)),
			_value(ui, figure(row["damage_taken"]), col, float(row["damage_taken"]) / taken_max, Color(GS.TEXT2, 0.36)),
			_value(ui, _hull(ui, row), col),
			_value(ui, "+" + figure(row["captain_xp"]), col),
		]
		if _promoted(row, report.get("xp", [])):
			var rank: String = ui.C.rankName(row["captain"])
			var promotion := Kit.label(rank, 17, k, GS.TEXT2, GS.sheet_medium(), true, WIDTHS[5] - 2.0)
			promotion.name = "Promotion"
			promotion.tooltip_text = "Promoted to " + rank
			promotion.mouse_filter = Control.MOUSE_FILTER_PASS
			stats[4].add_child(Kit.label("Promoted", 17, k, GS.TEXT2))
			stats[4].add_child(promotion)
		if wide:
			_cell(line, identity, 0, k)
			for i in stats.size():
				_cell(line, stats[i], i + 1, k)
		else:
			line.add_child(identity)
			var grid := GridContainer.new()
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", UiScale.px(8, k))
			grid.add_theme_constant_override("v_separation", UiScale.px(4, k))
			for i in stats.size():
				var stat := ui.vbox(2) as VBoxContainer
				stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				stat.add_child(Kit.label(HEADERS[i + 1], 17, k, GS.TEXT2))
				stat.add_child(stats[i])
				grid.add_child(stat)
			line.add_child(grid)
	table.add_child(GS.thin_bar(k, 0.0, GS.SHEET_HAIR, 0.0, 1.0, GS.SHEET_HAIR))
	var formula := "MVP score = %d per kill + damage dealt + %d%% of damage taken." % [KILL_POINTS, roundi(TAKEN_WEIGHT * 100)]
	table.add_child(Kit.label(formula, 17, k, GS.TEXT2))
	table.add_child(Kit.label("Ties go to kills, then damage dealt, damage taken and flagship.", 17, k, GS.TEXT2))
	return true


static func _cell(line: BoxContainer, cell: Control, column: int, k: float) -> void:
	cell.custom_minimum_size.x = maxf(cell.custom_minimum_size.x, UiScale.px(WIDTHS[column], k))
	if column in [0, 2, 3, 5]:
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = WIDTHS[column]
	line.add_child(cell)


static func _value(ui, text: String, col: Color, share := -1.0, tint := GS.TEXT2) -> VBoxContainer:
	var value := ui.vbox(2) as VBoxContainer
	var number := Kit.label(text, 17, ui.k, col, GS.num(), false)
	value.add_child(number)
	if share >= 0.0:
		value.add_child(GS.thin_bar(ui.k, share, tint, 0.0, 3.0, Color(GS.SHEET_HAIR, 0.5)))
	return value


static func _hull(ui, row: Dictionary) -> String:
	var hp := float(row["hull_remaining"])
	var mx := float(row.get("hull_max", 0))
	if mx > 0:
		return "%d%%" % (clampi(roundi(hp / mx * 100), 1, 100) if hp > 0 else 0)
	# Step 0 reports saved before AR-A have hull points but not the maximum.
	return "%s HP" % ui.C.hull_text(hp)


static func _promoted(row: Dictionary, xp: Array) -> bool:
	if row.has("promoted"):
		return row["promoted"]
	for entry in xp:
		if entry["cap"].get("captain_id") == row["captain"]["captain_id"]:
			return entry["up"]
	return false


static func figure(value: float) -> String:
	var parts := ("%.2f" % value).split(".")
	var whole: String = parts[0]
	var grouped := ""
	while whole.length() > 3:
		grouped = "," + whole.right(3) + grouped
		whole = whole.left(-3)
	var fraction: String = parts[1].rstrip("0")
	return whole + grouped + ("" if fraction.is_empty() else "." + fraction)
