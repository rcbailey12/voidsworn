extends Node
# UI pass layout check (Nov 1). Run: battle.tscn (or the game, through main) with -- --ui-shots <folder> [--shots <folder>]
# [--seed N | --scenario sN]. Plays the opening of a battle through the same handlers a player uses and, at six moments,
# saves a still and checks the screen layout: battle start, a move hex hovered (the "Move here" tip), an enemy clicked,
# the tip card with the terrain legend open, an enemy targeted after a move (the odds), and the enemy's turn. At each one every visible HUD part (top bar, fleet list,
# ship panel, log, card, turn strip, legend, tips, toasts, banner, key hint) must sit fully on screen and touch no other,
# and every top bar button (Grid (Z) included) must sit inside the top bar. Prints [ui-check] lines and writes
# ui_check.txt in the folder. Presentation only: it never calls the rules except to read.

const PG := preload("res://render/placeholder_guard.gd")

var b
var dir := ""
var lines: Array = []
var fails := 0


func _idle() -> void:
	var t0 := Time.get_ticks_msec()
	while is_inside_tree() and (b.busy or b.warming or b._threat_busy or b.thinking or b.ending) and not b.ended:
		await get_tree().process_frame
		if Time.get_ticks_msec() - t0 > 120000:
			return
	for i in 3:
		await get_tree().process_frame


func _note(ok: bool, what: String) -> void:
	lines.append(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1
	print("[ui-check] ", "PASS " if ok else "FAIL ", what)


# every HUD part that is showing, with its screen rect
func _parts() -> Array:
	var h = b.hud
	var out: Array = []
	# #271: the activation card is the End block inside the shell (the ship panel), checked by _check_shell
	var named := [["top bar", h.top], ["fleet list", h.roster], ["ship panel", h.panel], ["battle log", h.log_panel],
		["unacted set", h.unacted], ["turn strip", h.phase], ["legend", h.legend], ["hover tip", h.tip], ["tip card", h.tipcard],
		["enemy chip", h.aichip]]
	for n in named:
		var c = n[1]
		if c != null and is_instance_valid(c) and (c as Control).is_visible_in_tree() and (c as Control).modulate.a > 0.05:
			out.append([n[0], (c as Control).get_global_rect()])
	if h.toast_lbl.modulate.a > 0.05 and h.toast_lbl.text != "":
		out.append(["toast", h.toast_lbl.get_global_rect()])
	if h.banner_lbl.modulate.a > 0.05 and h.banner_lbl.text != "":
		out.append(["banner", _text_rect(h.banner_lbl)])
	if h.hint.is_visible_in_tree():
		out.append(["key hint", _text_rect(h.hint)])
	return out


# a centred label's rect trimmed to its text (its box can be wider than the words)
func _text_rect(l: Label) -> Rect2:
	var r := l.get_global_rect()
	var w := minf(r.size.x, l.get_minimum_size().x)
	return Rect2(r.position + Vector2((r.size.x - w) * 0.5, 0), Vector2(w, r.size.y))


func _check(name: String) -> void:
	var vs: Vector2 = b.get_viewport().get_visible_rect().size
	var scr := Rect2(Vector2.ZERO, vs).grow(1.0)
	var parts := _parts()
	var bad: Array = []
	for p in parts:
		if not scr.encloses(p[1]):
			bad.append("%s runs off the screen %s" % [p[0], _r(p[1])])
	for i in parts.size():
		for j in range(i + 1, parts.size()):
			var a: Rect2 = parts[i][1]
			var c: Rect2 = parts[j][1]
			if a.grow(-1.0).intersects(c.grow(-1.0)):
				bad.append("%s %s overlaps %s %s" % [parts[i][0], _r(a), parts[j][0], _r(c)])
	# every top bar button inside the top bar
	var tr: Rect2 = b.hud.top.get_global_rect().grow(1.0)
	var nb := 0
	for c in b.hud.top_row.get_children():
		if c is Button and (c as Button).visible:
			nb += 1
			if not tr.encloses((c as Button).get_global_rect()):
				bad.append("top bar button \"%s\" is cut off %s" % [(c as Button).text, _r((c as Button).get_global_rect())])
	# #271: the End block sits inside the shell at its bottom (End ship fixed in the bottom right corner), and the fleet
	# list shows every ship with no scroll at 1080 lines or more
	var h = b.hud
	if h.card.visible:
		var pr: Rect2 = h.panel.get_global_rect().grow(1.0)
		var cr: Rect2 = h.card.get_global_rect()
		if not pr.encloses(cr) or absf(cr.end.y - (vs.y - h.s(16))) > 2.0:
			bad.append("the End block is not at the bottom of the shell %s in %s" % [_r(cr), _r(pr)])
	if vs.y >= 1079.0 and h.roster_sc.get_v_scroll_bar().visible:
		bad.append("the fleet list scrolls (%d rows)" % h.roster_box.get_child_count())
	var gb = b.board.get("_look_btn") if b.board != null else null
	if gb != null and is_instance_valid(gb) and (gb as Button).visible and (gb as Button).get_parent() != b.hud.top_row:
		bad.append("the Grid (Z) button is not in the top bar")
	_note(bad.is_empty(), "%s at %dx%d (UI scale %.2f): %d parts, %d top bar buttons%s" % [name, int(vs.x), int(vs.y), b.hud.k, parts.size(), nb,
		"" if bad.is_empty() else ": " + "; ".join(PackedStringArray(bad))])


func _r(r: Rect2) -> String:
	return "(%d,%d %dx%d)" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]


func _shot(name: String) -> void:
	if PG.stop_if_any():
		return
	await get_tree().create_timer(0.7).timeout
	_check(name)
	await b._snap(name)


func _hover_hex(q: int, r: int) -> void:
	b.hover = Vector2i(q, r)
	b.board.set_hover(q, r)
	b._overlay()
	var sp: Vector2 = b.cam.unproject_position(b.board.hex_world(q, r))
	get_viewport().warp_mouse(sp)
	b.hud.show_tip(b._tip(), sp)


# Compare the displayed rows with the card/panel's live rule queries, without changing rules or RNG.
func _check_fire_tips(moment: String) -> void:
	var trace = preload("res://scenes/battle/f1_trace.gd").new()
	trace.b = b
	var before: Dictionary = trace._hash()
	var old_armed: int = b.armed
	var count := 0
	var ok := true
	var fresh: Dictionary = b.api.ui_info(b.sel)
	for w in fresh.get("weapons", []):
		for t in w["targets"]:
			var tid: String = t["id"]
			var wi: int = int(w["i"])
			# Prime/read the scene cache and require facts from this exact battle version.
			ok = ok and b._wtarget(b.sel, wi, tid) == t
			if not b.api.can_fire(b.sel, wi, tid):
				continue
			b.armed = wi
			var tip: String = b._attack_tip(tid)
			var odds := "%d%%" % int(b.api.preview_fire(b.sel, wi, tid)["hit"])
			ok = ok and b._firing_set(tid) == [wi] and tip.contains(odds) and not tip.contains("out of range") and not tip.contains("out of arc")
			count += 1
	b.armed = old_armed
	var after: Dictionary = trace._hash()
	trace.free()
	_note(ok, "%s: hover facts match live card/panel queries (%d bearing weapons)" % [moment, count])
	_note(before == after, "%s: checking tips leaves battle state and RNG unchanged" % moment)


func run(battle) -> void:
	b = battle
	dir = str(b.args.get("ui-shots", "user://ui_shots"))
	while b.api == null or b.warming:
		await get_tree().process_frame
	while b.opening:
		await get_tree().process_frame
	await _idle()
	await get_tree().create_timer(2.0).timeout
	if b.args.has("ui-rebuild-test"):
		# the HUD rebuilt from a wrong size (what a window resize does): every part must come back at the right size
		var nlog: int = b.hud.log_text.get_line_count()
		b.hud.k = 1.9
		b.hud._rebuild()
		await get_tree().create_timer(0.8).timeout
		_note(absf(b.hud.k - b.hud.scale_for(b.get_viewport().get_visible_rect().size)) < 0.01 and b.hud.log_text.get_line_count() == nlog and b.hud.card.visible and b.hud.plates.size() > 0,
			"rebuild: scale %.2f, log lines %d (were %d), card shown %s, %d nameplates" % [b.hud.k, b.hud.log_text.get_line_count(), nlog, str(b.hud.card.visible), b.hud.plates.size()])
	_check_fire_tips("opening")
	# 1. the opening hand-over
	await _shot("1_battle_start")
	# 2. a move hex hovered: the farthest reachable hex, with its tip
	b._update_reach()
	var far = null
	for key in b.reach_map:
		var st = b.reach_map[key]
		if not b._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		if far == null or float(st.cost) > float(far.cost):
			far = st
	if far != null:
		_hover_hex(int(far.q), int(far.r))
		await _shot("2_move_preview")
	# 3. an enemy targeted (one click: the odds in the card, nothing fires); out of reach, the attack-move preview
	var tgt := ""
	var atk := ""
	var any := ""
	for e in b.V["units"]:
		if e["side"] != "enemy" or e["dead"] or e["squadron"]:
			continue
		if any == "":
			any = e["id"]
		if tgt == "" and not b._firing_set(e["id"]).is_empty():
			tgt = e["id"]
		if atk == "" and b._attack_move(e["id"]) != null:
			atk = e["id"]
	if tgt == "":
		tgt = atk if atk != "" else any
	if tgt != "":
		var mid: Vector3 = b._pos(tgt)
		if b.sel != "" and b.views.has(b.sel):
			mid = mid.lerp(b._pos(b.sel), 0.5)
		b.cam.glide(mid, 0.3)
		await get_tree().create_timer(0.9).timeout
		_hover_hex(int(b.VU[tgt]["q"]), int(b.VU[tgt]["r"]))
		b._on_click()
		await _idle()
		_hover_hex(int(b.VU[tgt]["q"]), int(b.VU[tgt]["r"]))
		_note(true, "3_enemy_clicked: %s (%s)" % [b._name(tgt), "in reach, odds shown" if b.target == tgt else ("attack-move preview" if b.atk != null else "out of reach")])
		await _shot("3_enemy_clicked")
		b._on_key(KEY_ESCAPE)
		await _idle()
	# 4. an onboarding tip card and the terrain legend opened (both show in real play; screenshot jobs turn tips off)
	b.hud.show_tip("", Vector2.ZERO)
	b.hud.show_tipcard("ui_check", "Your ship is up", "The card at the bottom shows the ship that is up and what it can still do. Click a blue hex to plan a move, click an enemy to target it, Space ends the ship.")
	if not (b.hud._legend.get("rows", []) as Array).is_empty() or str(b.hud._legend.get("title", "")) != "":
		b.hud.legend_open = true
		b.hud._draw_legend()
	await _shot("4_tip_card_and_legend")
	b.hud.hide_tipcard()
	b.hud.legend_open = false
	b.hud._draw_legend()
	# 5. move to the hex where the most guns bear, then target an enemy in reach: the odds in the card and the tip
	b._update_reach()
	var best = null
	for key in b.reach_map:
		var st = b.reach_map[key]
		if not b._unit_at(int(st.q), int(st.r)).is_empty():
			continue
		if best == null or int(st.get("guns", 0)) * 100 + int(st.cost) > int(best.get("guns", 0)) * 100 + int(best.cost):
			best = st
	if best != null and int(best.get("guns", 0)) > 0:
		_hover_hex(int(best.q), int(best.r))
		b._on_click()
		await _idle()
		_check_fire_tips("planned move")
		# #271: the Move step with a planned move, the pointer on an enemy: the Fire block reads the odds from the planned hex
		var pe := ""
		for e in b.V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not e["squadron"]:
				for wi in (b.api.unit(b.sel)["weapons"] as Array).size():
					if b.api.in_reach(b.sel, wi, e["id"], b.plan):
						pe = e["id"]
						break
			if pe != "":
				break
		if pe != "":
			b._hover_uid = ""
			b._on_hover(b.cam.unproject_position(b.board.hex_world(int(b.VU[pe]["q"]), int(b.VU[pe]["r"]))))
			b._refresh_ui()
			_note(b.plan != null, "5a_planned_move_odds: a move planned, the pointer on %s" % b._name(pe))
			await _shot("5a_planned_move_odds")
			_hover_hex(int(best.q), int(best.r))
		_hover_hex(int(best.q), int(best.r))
		b._on_click()
		await _idle()
		await get_tree().create_timer(0.5).timeout
		_check_fire_tips("after move")
		var t2 := ""
		for e in b.V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not b._firing_set(e["id"]).is_empty():
				t2 = e["id"]
				break
		if t2 != "" and b.sel != "":
			b.cam.glide(b._pos(t2).lerp(b._pos(b.sel), 0.5), 0.3)
			await get_tree().create_timer(0.9).timeout
			_hover_hex(int(b.VU[t2]["q"]), int(b.VU[t2]["r"]))
			b._on_click()
			await _idle()
			_hover_hex(int(b.VU[t2]["q"]), int(b.VU[t2]["r"]))
			_note(b.target == t2, "5_enemy_targeted: %s targeted after a move, %d guns bear" % [b._name(t2), b._firing_set(t2).size()])
			await _shot("5_enemy_targeted")
			b._on_key(KEY_ESCAPE)
			await _idle()
	# 6. the enemy's turn: end the ship that is up
	b.hud.toast("Out of range.")
	b.handed_t = -9.0
	b._on_key(KEY_SPACE)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
		if b.hud.phase.visible and b.hud.phase_lbl.text.contains("ENEMY TURN"):
			break
		if b.api.phase == "player" and not b.busy and not b.ending:
			b.handed_t = -9.0
			b._on_key(KEY_SPACE)
	await get_tree().create_timer(0.3).timeout
	_note(b.hud.phase_lbl.text.contains("ENEMY TURN") and b.hud.toast_lbl.text != "Out of range." and not b.hud.tip.visible, "enemy turn clears firing warning and hover tip")
	_check("6_enemy_turn")
	await b._snap("6_enemy_turn")
	# let the enemy's turn finish (hurried) before quitting, so nothing is torn down mid-move
	Engine.time_scale = 6.0
	await _idle()
	Engine.time_scale = 1.0
	# 7. AC5 (ui_spec.md 6.2): the menu takes keyboard focus and shows the focus ring; a toggle keeps the keyboard on its
	# row; Esc closes the menu and gives the keys back to the battle
	b._open_menu()
	await get_tree().process_frame
	await get_tree().process_frame
	var fo := get_viewport().gui_get_focus_owner()
	var ring = fo.get_theme_stylebox("focus") if fo is Button else null
	_note(fo is Button and b.hud.menu != null and b.hud.menu.is_ancestor_of(fo) and ring is StyleBoxFlat and not (ring as StyleBoxFlat).draw_center and (ring as StyleBoxFlat).get_border_width(SIDE_LEFT) >= 2,
		"7_menu_focus: the menu's first button has keyboard focus and a visible focus ring (%s)" % (str((fo as Button).text) if fo is Button else "no focus"))
	await _shot("7_menu_focus")
	var row: Button = null
	for ch in b.hud.menu.get_child(0).get_children():
		if ch is Button and str(ch.text).begins_with("Firing arcs"):
			row = ch
	if row != null:
		row.grab_focus()
		row.pressed.emit()
		await get_tree().process_frame
		await get_tree().process_frame
		var fo2 := get_viewport().gui_get_focus_owner()
		_note(fo2 is Button and str(fo2.text).begins_with("Firing arcs"), "7_menu_focus: after a toggle the keyboard stays on its row (%s)" % (str(fo2.text) if fo2 is Button else "no focus"))
		b.arcs_on = not b.arcs_on   # put the option back as it was (the toggle saved nothing: screenshot jobs keep their settings)
	else:
		# #282 (N2): a missing row must fail the run, not skip the refocus assertion silently
		_note(false, "7_menu_focus: the Firing arcs row is missing from the menu")
	b._on_key(KEY_ESCAPE)
	await get_tree().process_frame
	await get_tree().process_frame
	_note(b.hud.menu == null and get_viewport().gui_get_focus_owner() == null, "7_menu_focus: Esc closes the menu and no button keeps the keyboard")
	_finish()


func _finish() -> void:
	var vs: Vector2 = b.get_viewport().get_visible_rect().size
	lines.append("%d checks, %d failed (window %dx%d, UI scale %.3f)" % [lines.size(), fails, int(vs.x), int(vs.y), b.hud.k])
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("ui_check.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(lines)) + "\n")
		f.close()
	print("[ui-check] %d checks, %d failed" % [lines.size() - 1, fails])
	b._quit_report()
