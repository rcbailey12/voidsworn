extends SceneTree
# KEEL's readability checks at 1080, 1440, and in a narrow window.
#   - nothing the player reads is smaller than 17 px at 1080; Big Shoulders only for names, never under 28 px;
#   - three text strengths (TEXT, TEXT2, TEXT3), TEXT3 only for joining words; ember the accent, NEM the Nemesis only,
#     Glacier for shield readouts only (R210), nothing lime;
#   - every word at 4.5 to 1 or better over the brightest and the darkest board: the brightest board is taken as pure
#     white and the darkest as black, under the sheet's own veils at their weakest point beneath each word (ledger.gd
#     dark_at), so a pass here holds over any backdrop;
#   - nothing overlaps anything, and nothing leaves the screen, in each moment and in the long cases (the longest names,
#     a six-gun ship with every order, a 20-ship fleet).
# The words measured are the ones the real HUD lays out: the data goes in through hud.gd's own setters, as battle.gd
# hands it over, and ledger.gd layout() places exactly what _draw() paints. Every function the sheet must still reach has
# its hit area checked (fire, guns, orders, Command, End ship, fleet lines, menu, log, the prompt's choices).
# Run: godot --headless --path godot --script res://ui/battle/test/ledger_readability_test.gd

const HUD := preload("res://ui/battle/hud.gd")
const GS := preload("res://ui/theme/glass_shell.gd")
const Brand := preload("res://ui/battle/brand.gd")
const Icons := preload("res://ui/battle/icons/keel_icons.gd")
const Rig := preload("res://render/camera_rig.gd")
const Main := preload("res://main/main.gd")
const Battle := preload("res://scenes/battle/battle.gd")

var fails := 0
var report: Array = []


func check(ok: bool, what: String) -> void:
	if ok:
		print("PASS: " + what)
	else:
		fails += 1
		print("FAIL: " + what)


static func lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


static func contrast(a: Color, b: Color) -> float:
	var la := lum(a)
	var lb := lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _init() -> void:
	_run.call_deferred()


# ---------------------------------------------------------------- the moments (the step 1 moment: seed 7, the Nemesis demo)

func weapons(odds := true) -> Array:
	return [
		{"i": 0, "name": "Sear battery", "arc": "P", "kind": "battery", "range": 5, "distance": 6, "hit": -1, "why": "out of range", "ready": true, "cost": "free", "desc": "Port broadside, 3x6 damage, range 5"},
		{"i": 1, "name": "Sear battery", "arc": "S", "kind": "battery", "range": 5, "distance": 6, "hit": -1, "why": "out of range", "ready": true, "cost": "free", "desc": "Starboard broadside, 3x6 damage, range 5"},
		{"i": 2, "name": "Oath lance", "arc": "F", "kind": "lance", "range": 7, "distance": 6, "hit": 92 if odds else -1, "ready": true, "dmg": 16, "cost": "CD 2", "desc": "Forward, 1x18 damage, range 7, reload 2"}]


func orders(all := false) -> Array:
	var o: Array = [{"text": "Brace (B)", "act": "brace", "on": true, "tip": "Hull damage -40% until its next turn."},
		{"text": "Concentrated fire", "act": "ability", "ability": "focus", "on": true, "tip": "+15 aim this round."},
		{"text": "Ram (X)", "act": "ram", "on": all, "tip": "Charge the first enemy dead ahead."},
		{"text": "Board (G)", "act": "board", "on": all, "tip": "Send boarding crews into an adjacent enemy."}]
	if all:
		for stn in ["strike", "screen", "hunt"]:
			o.append({"text": "Wings: %s" % stn, "act": "stance", "arg": stn, "on": stn != "strike", "tip": "Wings."})
		o.append({"text": "Role: Strike", "act": "role", "on": true, "tip": "This ship's role."})
	o.append({"text": "Turn left (Q)", "act": "rotl", "on": true})
	o.append({"text": "Turn right (E)", "act": "rotr", "on": true})
	return o


func ship(name := "Unyielding Oath", cls := "Vigil-class cruiser", ws: Array = [], ords: Array = [], flags := "[color=#ff8a72]The enemy fleet is focusing its fire on this ship.[/color]") -> Dictionary:
	return {"name": name, "cls": cls, "side": "player", "flag": true, "hp": 135, "maxHp": 135, "sh": [12, 15, 20, 11], "shMax": 80, "shp": 73, "code": "V15_37",
		"stats": "Hull 135/135   Armor 20%   Evasion 10\nMovement 0 of 4   Turns 1", "captain": "Captain Ilsa Marr", "move": [0, 4], "arm": 20, "turns": 1,
		"tag": "UP", "danger": 2, "flags": flags, "weapons": ws if not ws.is_empty() else weapons(), "orders": ords if not ords.is_empty() else orders()}


func rows(n := 3, long := false) -> Array:
	var names := ["Unyielding Oath", "Unpaid Debt", "Iron Dusk"]
	var out: Array = []
	for i in n:
		var nm: String = names[i] if i < names.size() and not long else ("Sunward Martyr of the Ninth Pyre" if long and i == 0 else "Ember Picket %d" % (i + 1))
		var st := "Up" if i == 0 else ("Ready" if i < n / 2 else "Done")
		out.append({"id": "p%d" % i, "name": nm, "cls": "Picket", "code": ["V15_37", "V14_23", "V17_37"][i % 3], "hp": 135 - i * 3 if i != 1 else 85, "maxHp": 135, "shMax": 55, "shp": 43,
			"status": st, "sel": i == 0, "done": st == "Done", "flag": i == 0, "new": false, "danger": 1 if i == 1 else 0})
	return out


func target(name := "Fleet Marshal Petra Valk") -> Dictionary:
	return {"name": name, "flag": true, "nem": true, "hp": 120, "maxHp": 120, "sh": [20, 20, 20, 20], "shMax": 80, "shp": 46,
		"exp_hull": 9, "exp_shields": 7, "bearing": 1, "gun": "Oath lance", "kind": "lance", "hit": 92, "gun_index": 2,
		"line": "The bearing gun: about 16 damage: 7 to shields, 9 to hull."}


func card_fire() -> Dictionary:
	return {"name": "Unyielding Oath", "cls": "Vigil-class cruiser", "flag": true, "tag": "UP", "more": "2 more ready",
		"steps": [{"n": 1, "label": "Move", "detail": "0 of 4 left", "st": "done"}, {"n": 2, "label": "Fire", "detail": "3 of 3 guns ready", "st": "now"}, {"n": 3, "label": "End ship", "detail": "Space", "st": "todo"}],
		"hint": "[color=#ff8a6a]Target: Fleet Marshal Petra Valk.[/color] 1 gun bears from here. [b]Click it again or press Enter to fire.[/b] Esc cancels.", "say": "",
		"buttons": [{"text": "Fire 1 weapon (Enter)", "act": "confirm", "on": true, "primary": true}, {"text": "Cancel (Esc)", "act": "cancel", "on": true},
			{"text": "Next ship (Tab)", "act": "next", "on": true, "big": true}, {"text": "End ship (Space)", "act": "end", "on": true, "big": true}], "aim": true}


func nem() -> Dictionary:
	return {"name": "Fleet Marshal Petra Valk", "ship": "Dominion", "flee": "flees below 25% hull", "adapted": [["Layered screens", "Shields +10%.", "you leaned on lances"]], "weak": [], "state": ""}


func feed(h, m: Dictionary) -> void:
	h.set_info({"foe_name": "Hegemony Navy", "foe_ships": 2, "heat": 3, "heat_tip": "Heat 3 of 9."})
	h.set_command("Fire for effect", bool(m.get("cmd", true)))
	h.set_top(1, m.get("turn", "Your turn (3 ready)"), "Objective: break their fleet", "End ship (Space)", true, false, false)
	h.set_nemesis(nem())
	h.set_roster(m.get("rows", rows()))
	h.set_panel(m.get("ship", ship()))
	h.set_target(m.get("target", target()))
	h.set_card(m.get("card", card_fire()))
	h.set_phase(m.get("phase_kind", "player"), m.get("phase_text", ""), m.get("phase_p", -1.0))
	if m.has("ask"):
		h.show_ask(m["ask"])
	else:
		h.hide_ask()


# ---------------------------------------------------------------- the measure

func measure(h, label: String, need_strengths := false) -> Dictionary:
	var L = h.ledger
	L.layout()
	var vs: Vector2 = L.size
	var items: Array = L.items
	var smallest := 999.0
	var bs_min := 999.0
	var worst := 99.0
	var worst_t := ""
	var under := 0
	var overl := 0
	var out := 0
	var used := {}
	var allowed := {GS.TEXT.to_html(false): "TEXT", GS.TEXT2.to_html(false): "TEXT2", GS.TEXT3.to_html(false): "TEXT3", GS.MAP_EMBER.to_html(false): "EMBER",
		GS.NEM.to_html(false): "NEM", GS.GLACIER.to_html(false): "GLACIER", GS.HULL_LOW.to_html(false): "DMG"}
	var screen := Rect2(Vector2.ZERO, vs)
	for i in items.size():
		var it: Dictionary = items[i]
		var col: Color = it["col"]
		var hx := col.to_html(false)
		var nm: String = allowed.get(hx, "")
		if nm == "":
			check(false, "%s: '%s' is in the sheet's palette (got #%s)" % [label, it["t"], hx])
		used[nm] = true
		smallest = minf(smallest, float(it["size"]))
		if str(it["face"]) == "BigShoulders":
			bs_min = minf(bs_min, float(it["size"]))
			if str(it["role"]) not in ["name", "action"]:
				check(false, "%s: Big Shoulders only for names and the action ('%s')" % [label, it["t"]])
		if nm == "TEXT3" and str(it["role"]) != "join":
			check(false, "%s: TEXT3 only for joining words ('%s', role %s)" % [label, it["t"], it["role"]])
		if nm == "GLACIER" and str(it["role"]) != "shield":
			check(false, "%s: Glacier only for shield readouts ('%s')" % [label, it["t"]])
		if nm == "NEM" and not ("Nemesis" == str(it["t"]) or str(h.ledger.target.get("name", "")).to_upper().begins_with(str(it["t"]).trim_suffix("..."))):
			check(false, "%s: NEM only for the Nemesis ('%s')" % [label, it["t"]])
		var r: Rect2 = L.item_rect(it)
		if not screen.encloses(r):
			out += 1
			print("  off screen: '%s' %s" % [it["t"], str(r)])
		for j in range(i + 1, items.size()):
			if r.grow(-1.0).intersects(L.item_rect(items[j]).grow(-1.0)):
				overl += 1
				print("  overlap: '%s' and '%s'" % [it["t"], items[j]["t"]])
		# the weakest darkening under the word: its four corners and its middle
		var d := 1.0
		for p in [r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y), r.get_center()]:
			d = minf(d, L.dark_at(p))
		var bright := Brand.KEEL_TEXT_EDGE if bool(it.edge) else Color(1, 1, 1).lerp(Color(0, 0, 0), d)
		var c := minf(contrast(col, bright), contrast(col, Color(0, 0, 0)))
		if c < worst:
			worst = c
			worst_t = "%s (%s)" % [it["t"], nm]
		if c < 4.5:
			under += 1
			print("  under 4.5: '%s' %.2f (darkening %.2f)" % [it["t"], c, d])
	var res := {"label": label, "words": items.size(), "smallest": smallest, "bs_min": bs_min, "worst": worst, "worst_t": worst_t, "under": under,
		"overlaps": overl, "off": out, "strengths": ["TEXT", "TEXT2", "TEXT3"].filter(func(n): return used.has(n)), "fleet": L.fleet_fit}
	var k: float = L.k
	check(smallest >= 17.0, "%s: smallest text %.0f px at 1080 (17 or more)" % [label, smallest])
	check(bs_min >= 28.0 or bs_min == 999.0, "%s: Big Shoulders from %.0f px (28 or more)" % [label, bs_min])
	check(under == 0, "%s: every word at 4.5 to 1 or better over white and black boards (lowest %.2f, %s)" % [label, worst, worst_t])
	check(overl == 0, "%s: no words overlap (%d)" % [label, overl])
	check(out == 0, "%s: no word leaves the screen (%d)" % [label, out])
	var art: Array = L.marks.filter(func(m): return m.k in ["ship", "glyph"])
	var art_errors := []
	for a in art:
		var ar: Rect2 = a.r
		if not screen.encloses(ar) or (a.k == "glyph" and ar.size.x < L.px(20)):
			art_errors.append(a.id)
		for it in items:
			if ar.grow(-1).intersects(L.item_rect(it).grow(-1)):
				art_errors.append("%s overlaps %s" % [a.id, it.t])
	check(art_errors.is_empty(), "%s: silhouettes and glyphs fit; glyphs are at least 20 design px (%s)" % [label, ", ".join(art_errors)])
	if need_strengths:
		check(used.has("TEXT") and used.has("TEXT2") and used.has("TEXT3"), "%s: three text strengths in use" % label)
	report.append(res)
	print("  %s: %d words, smallest %.0f, Big Shoulders from %.0f, lowest contrast %.2f (%s), fleet %s, k %.3f" % [label, items.size(), smallest, bs_min, worst, worst_t, str(L.fleet_fit), k])
	return res


func acts(h) -> Dictionary:
	var a := {}
	for x in h.ledger.hits:
		a[str(x["act"])] = int(a.get(str(x["act"]), 0)) + 1
	return a


# no lime anywhere the player can see: walk the HUD's visible controls
func no_lime(h, label: String) -> void:
	var lime := [GS.GILT, GS.GILT2, GS.GILT_HOVER, Color(0.78, 0.96, 0.23), GS.SHIELD]
	var bad := PackedStringArray()
	var stack: Array = [h.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is CanvasItem and not (n as CanvasItem).visible:
			continue
		for c in n.get_children():
			stack.append(c)
		if n is Control:
			var ctl := n as Control
			for cn in ["font_color", "font_hover_color", "font_focus_color", "font_outline_color", "default_color"]:
				if ctl.has_theme_color_override(cn):
					var cc := ctl.get_theme_color(cn)
					for l in lime:
						if cc.is_equal_approx(l):
							bad.append("%s %s" % [ctl.name, cn])
			for sn in ["normal", "hover", "panel", "focus"]:
				if ctl.has_theme_stylebox_override(sn):
					var sb := ctl.get_theme_stylebox(sn)
					if sb is StyleBoxFlat:
						for l in lime:
							if (sb as StyleBoxFlat).bg_color.is_equal_approx(l) or (sb as StyleBoxFlat).border_color.is_equal_approx(l):
								bad.append("%s %s" % [ctl.name, sn])
	for x in h.ledger.items:
		for l in lime:
			if (x["col"] as Color).is_equal_approx(l):
				bad.append("sheet word " + str(x["t"]))
	check(bad.is_empty(), "%s: nothing lime (or the old shield cyan) on the screen %s" % [label, ", ".join(bad)])


# issue 678: a ship's name over the board (hud.gd plate) must hold 4.5 to 1 over any hull, ring or glow behind it. Measured
# 4.44 to 1 at 1440 with 20 ships when the halo was an outline at 0.92 alpha alone. The name carries a solid HALO outline and
# a solid centred shadow of the same glyph, so the pixel under a letter is the halo, never the board; each plate colour is then
# held against the halo itself.
func plate_halo(h, tag: String) -> void:
	var nm := h.plate("probe").get_node("st/v/nm") as Label
	var oc := nm.get_theme_color("font_outline_color")
	var sc := nm.get_theme_color("font_shadow_color")
	check(is_equal_approx(oc.a, 1.0) and oc.is_equal_approx(Color(GS.HALO, 1.0)), "%s: a ship name's outline is the opaque HALO (%s)" % [tag, oc.to_html(true)])
	check(is_equal_approx(sc.a, 1.0) and sc.is_equal_approx(Color(GS.HALO, 1.0)), "%s: a ship name has a solid HALO shadow under its letters (%s)" % [tag, sc.to_html(true)])
	check(nm.get_theme_constant("shadow_offset_x") == 0 and nm.get_theme_constant("shadow_offset_y") == 0 and nm.get_theme_constant("shadow_outline_size") >= nm.get_theme_constant("outline_size"), "%s: the shadow sits centred and as wide as the outline" % tag)
	for cn in [["ember (the ship that is up)", GS.MAP_EMBER], ["text", GS.TEXT], ["Nemesis", GS.NEM]]:
		var c := contrast(cn[1], Color(GS.HALO, 1.0))
		check(c >= 4.5, "%s: a ship name in %s over its halo is %.2f to 1 (4.5 or more)" % [tag, cn[0], c])
	h.plate("probe").queue_free()


func _run() -> void:
	_ship_art()
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(1152, 1024)]:
		root.size = sz
		root.content_scale_size = Vector2i.ZERO
		await process_frame
		var h = HUD.new()
		root.add_child(h)
		await process_frame
		await process_frame
		var tag := "%dx%d" % [sz.x, sz.y]
		check(absf(h.ledger.size.x - sz.x) < 1.0, "%s: the sheet covers the window (%s)" % [tag, str(h.ledger.size)])
		plate_halo(h, tag)
		for i in 3:
			h.add_log(["Fleet Marshal Petra Valk: \"Every move you can make has been planned for.\"", "Fleet Marshal Petra Valk: \"All reserve squadrons, jump in now. Encircle them.\"", "Contact: Hegemony Navy, 2 ships on the scanners."][i], "e")
		# 1. your turn with a target (the step 1 moment)
		feed(h, {})
		await process_frame
		var r1 := measure(h, tag + " your turn, target", sz.y == 1080)
		if sz.y == 1080:
			check(is_equal_approx(h.ledger.sheet_r.size.y, 248.0), "1080p: the KEEL shelf is 248 px tall")
		var a := acts(h)
		for need in ["confirm", "arm", "brace", "ability", "rotl", "rotr", "next", "command", "end", "pick", "menu", "log_collapse"]:
			check(a.has(need), "%s: '%s' is reachable on the sheet" % [tag, need])
		check(int(a.get("arm", 0)) == 3 and int(a.get("pick", 0)) == 3, "%s: every gun and every fleet line can be clicked" % tag)
		var words := PackedStringArray()
		for x in h.ledger.items:
			words.append(str(x["t"]))
		var joined := " | ".join(words)
		check("FIRE THE OATH LANCE" in joined and "92%" in joined and "UNYIELDING OATH" in joined and "Hegemony Navy, 2 ships" in joined, "%s: the KEEL shelf shows the ship, target, odds and fire button" % tag)
		check("About 16 damage" in words and "7 to shields" in words and "9 to hull" in words and "73 / 80" in words, "%s: plain damage words and the actual pool, without summing its facings" % tag)
		if sz.y == 1080:
			check("Fire for effect" in words, "1080p: Command keeps its full standing name")
		check(h.ledger.items.all(func(it): return it.role != "key"), "%s: no shortcut badges on the HUD" % tag)
		_log_states(h, tag)
		if sz.y == 1080:
			_log_settings(h)
			_interaction_states(h)
		_called_states(h, tag)
		var bare := target()
		bare.exp_shields = 0
		bare.exp_hull = 16
		h.set_target(bare)
		h.ledger.ensure_layout()
		var hull_words := " ".join(h.ledger.items.map(func(it): return it.t)).to_lower()
		check("about 16 damage" in hull_words and "all to hull" in hull_words and not "to shields" in hull_words, "%s: unshielded preview says all to hull" % tag)
		h.set_target(target())
		h.ledger.ensure_layout()
		var tips_ok := true
		for x in h.ledger.hits:
			if str(x["act"]) == "" and str(x["tip"]) == "":
				tips_ok = false
		check(tips_ok, "%s: every hover area has something to show" % tag)
		check(h.ledger.detail_bb.contains("Armor") and h.ledger.detail_bb.contains("Captain") and h.ledger.detail_bb.contains("Tab"), "%s: the ship name's hover carries the captain, armour and the keys" % tag)
		no_lime(h, tag)
		# hover over the ship name shows the detail layer
		h.ledger._gui_input(_motion(h.ledger.sheet_r.position + Vector2(h.ledger.px(80), h.ledger.px(40))))
		check(h.dtip.visible and h.dtip_text.text.contains("Captain"), "%s: hovering the ship's name shows what moved off the sheet" % tag)
		h.ledger._gui_input(_motion(Vector2(4, sz.y * 0.5)))
		# a click on the action box fires (emits confirm)
		var got: Array = []
		var cb := func(n: String, arg) -> void: got.append(n)
		h.action.connect(cb)
		for x in h.ledger.hits:
			if str(x["act"]) == "confirm":
				h.ledger._gui_input(_click(Rect2(x["r"]).get_center()))
		check(got.has("confirm"), "%s: a click on FIRE sends the battle's confirm" % tag)
		h.action.disconnect(cb)
		check(h.over_ui(h.ledger.sheet_r.get_center()) and not h.over_ui(Vector2(h.ledger.px(80), sz.y * 0.5)), "%s: shelf catches clicks and the old rail is open to the board" % tag)
		await _camera_clear(h, tag)
		# 2. the enemy's turn
		feed(h, {"turn": "Enemy turn", "card": {}, "target": {}, "ship": {}, "cmd": false, "phase_kind": "enemy",
			"phase_text": "[b][color=#c4a4ff]ENEMY TURN[/color][/b]  ·  Hegemony Navy: Iron Warden  ·  [color=#8d86a0]Enter hurries[/color]", "phase_p": 0.4})
		await process_frame
		measure(h, tag + " enemy turn")
		var j2 := ""
		for x in h.ledger.items:
			j2 += str(x["t"]) + " | "
		check("Enemy turn" in j2 and "Hegemony Navy:" in j2 and not "FIRE" in j2, "%s: the enemy's turn says whose turn and who is moving, no action" % tag)
		# 3. a "you may" prompt (issue 529, PR 533's words) in the shot's place
		feed(h, {"ask": {"kind": "may", "key": "debtDue", "n": "Debt Comes Due", "q": "Delay the whole volley to the start of next round? It fires then with +20% damage.",
			"opts": [{"id": "yes", "n": "Delay the volley"}, {"id": "no", "n": "Fire it now"}]}})
		await process_frame
		measure(h, tag + " you may prompt")
		check(h.ask_panel != null and int(acts(h).get("ask", 0)) == 2 and not acts(h).has("confirm"), "%s: the prompt takes the shot's place with its two choices; FIRE waits" % tag)
		if sz.y == 1080:
			_check_hit_feedback(h.ledger, "ask")
		h.hide_ask()
		check(h.ask_panel == null, "%s: answering the prompt clears it" % tag)
		# 4. the long cases: the longest names, six guns, every order, 20 ships
		var ws: Array = weapons()
		for i in 3:
			ws.append({"i": 3 + i, "name": "Hellfire torpedo rack", "arc": "T", "kind": "torp", "range": 9, "distance": 6, "hit": 41 + i, "ready": true, "armed": i == 1, "dmg": 30, "cost": "CD 3", "desc": "Turret, 1x30 damage."})
		var long_ship := ship("Sunward Martyr of the Ninth Pyre", "Pyre-Barge, elite captain", ws, orders(true),
			"[color=#9fd4ff]Braced: hull damage -40% until its next turn.[/color] [color=#ff8a72]The enemy fleet is focusing its fire on this ship.[/color]")
		var big := rows(20, true)
		feed(h, {"rows": big})
		await process_frame
		var r4 := measure(h, tag + " 20 ships")
		check(int(r4.fleet.shown) >= 2 and int(acts(h).get("pick", 0)) == int(r4.fleet.shown), "%s: each visible fleet slot can be picked" % tag)
		var ids := {}
		for page in int(r4.fleet.pages):
			h.ledger.fleet_page = page
			h.ledger.layout()
			for hit in h.ledger.hits:
				if hit.act == "pick":
					ids[hit.arg] = true
		check(ids.size() == 20, "%s: every one of 20 ships is reachable in the fleet strip" % tag)
		h.ledger.fleet_page = 0
		feed(h, {"ship": long_ship, "target": target("Grand Admiral Seraphine Voss-Haldane"), "rows": rows(3, true)})
		await process_frame
		measure(h, tag + " six guns, every order, the longest names")
		feed(h, {"ship": long_ship, "target": target("Grand Admiral Seraphine Voss-Haldane"), "rows": big})
		await process_frame
		measure(h, tag + " all of it at once (6 guns, every order, 20 ships)")
		check(int(acts(h).get("arm", 0)) == 6, "%s: six guns stay individually clickable above the fleet" % tag)
		# 5. no ship up yet: pick a ship
		feed(h, {"ship": {}, "target": {}, "card": {"name": "Pick a ship", "tag": "YOUR TURN", "steps": [], "say": "Pick a ship: click one of yours or press Tab.",
			"buttons": [{"text": "Next ship (Tab)", "act": "next", "on": true, "big": true}]}})
		await process_frame
		measure(h, tag + " pick a ship")
		check(acts(h).has("next"), "%s: with no ship up, the action is Next ship (Tab)" % tag)
		h.queue_free()
		await process_frame
	print("%s: KEEL readability: %d checks failed" % ["PASS" if fails == 0 else "FAIL", fails])
	var f := FileAccess.open("user://ledger_readability.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
	quit(1 if fails > 0 else 0)


func _ship_art() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ships/manifest.json")).ships
	var hashes := {}
	var hull_count := 0
	for code: String in manifest:
		# The ledger gets ShipView's faction-and-role key for a wing. The manifest code only selects its 3D craft.
		if manifest[code].get("cls") == "Squadron":
			continue
		hull_count += 1
		var tex := Icons.silhouette(code)
		if tex != null:
			hashes[FileAccess.get_sha256(Icons.DIR + "ships/" + code + ".png")] = true
	check(hashes.size() == hull_count and not hashes.has(""), "every installed hull has a distinct silhouette (%d of %d)" % [hashes.size(), hull_count])


func _log_states(h, tag: String) -> void:
	var L = h.ledger
	check(L.log_r.end.y < L.sheet_r.position.y and L.items.filter(func(it): return it.role == "log").size() == 4,
		"%s: floating log defaults to three lines above the shelf" % tag)
	check(is_equal_approx(L.dark_at(L.log_r.get_center()), Brand.KEEL_LOG_VEIL) and L.dark_at(L.sheet_r.get_center()) > 1.8 * Brand.KEEL_LOG_VEIL,
		"%s: log veil is roughly half the shelf's opacity" % tag)
	h.set_log_preferences(true, true)
	L.ensure_layout()
	var ticker: Array = L.items.filter(func(it): return it.role == "log")
	check(ticker.size() == 2 and str(ticker[1].t).begins_with("Contact:"), "%s: collapsed ticker shows only the newest line" % tag)
	var header: Array = L.hits.filter(func(hit): return hit.act == "log_collapse")
	check(header.size() == 1 and str(header[0].tip).begins_with("Contact:"), "%s: the collapsed log still exposes the whole line on hover" % tag)
	var log_r: Rect2 = L.log_r
	h.set_log_preferences(false, true)
	L.ensure_layout()
	check(not L.log_r.has_area() and not h.over_ui(log_r.get_center()) and not acts(h).has("log_collapse"), "%s: Off removes the log veil, words and hit region" % tag)
	h.toggle_log()
	check(h.log_panel.visible and h.log_text.get_parsed_text().contains("Contact:"), "%s: the manual history remains available with the ticker off" % tag)
	h.toggle_log()
	h.set_log_preferences(true, false)


func _log_settings(h) -> void:
	var main := Main.new()
	var battle := Battle.new()
	battle.hud = h
	h.set_log_preferences(false, true)
	main._settings_to_battle(battle)
	check(h.log_enabled and not h.log_collapsed, "old settings with no log fields open the three-line log")
	main.settings.merge({"battle_log_enabled": false, "battle_log_collapsed": true}, true)
	main._settings_to_battle(battle)
	check(not h.log_enabled and h.log_collapsed, "saved log visibility and collapse preferences apply independently")
	h.set_log_preferences(true, false)
	battle.free()
	main.free()


func _interaction_states(h) -> void:
	var roster := rows()
	roster[1].status = "Lost"
	roster[1].hp = 0
	h.set_roster(roster)
	h.set_retreat(true, false)
	h.ledger.ensure_layout()
	for act in ["confirm", "arm", "brace", "pick", "menu", "retreat", "log_collapse"]:
		_check_hit_feedback(h.ledger, act)
	var lost: Array = h.ledger.hits.filter(func(hit): return str(hit.arg) == "p1")
	var picks := []
	var on_action := func(act: String, arg: Variant) -> void:
		if act == "pick":
			picks.append(arg)
	h.action.connect(on_action)
	if lost.size() == 1:
		h.ledger._gui_input(_click(Rect2(lost[0].r).get_center()))
	check(lost.size() == 1 and lost[0].act == "" and "Lost" in lost[0].tip and "Click to pick" not in lost[0].tip and picks.is_empty(),
		"D4: a Lost ship keeps its tooltip but cannot be picked")
	h.action.disconnect(on_action)
	check(h.ledger.items.any(func(it): return it.t == "Hover for details"), "D4: the Nemesis line advertises its hover details")
	var button: Button = h._button("Close", "log")
	check(button.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND, "D4: HUD buttons show the pointing hand")
	button.free()
	h.set_roster(rows())
	h.set_retreat(false, false)


func _called_states(h, tag: String) -> void:
	var t := target()
	var called := {"sec": "eng", "aim": 10, "crit": 15, "secs": [
		{"id": "prow", "name": "Weapons", "ok": true},
		{"id": "mid", "name": "Midship", "ok": false},
		{"id": "eng", "name": "Engines", "ok": true}]}
	t["called"] = called
	t["hit"] = 82
	t["exp_shields"] = 135
	t["exp_hull"] = 104
	h.set_target(t)
	measure(h, tag + " called shot")
	var ledger = h.ledger
	var words := " ".join(ledger.items.map(func(it): return it.t))
	check("82%" in words and "-10 to hit" in words and "+15 crit" in words,
		"%s: called odds and their cost are readable without a hover" % tag)
	var picks: Array = []
	var on_action := func(act: String, arg: Variant) -> void:
		if act == "called":
			picks.append(arg)
	h.action.connect(on_action)
	for hit in ledger.hits.duplicate():
		if hit.act == "called" or str(hit.tip).begins_with("Midship: already destroyed"):
			ledger._gui_input(_click(Rect2(hit.r).get_center()))
	h.action.disconnect(on_action)
	check(picks == ["", "prow", "eng"], "%s: Any, Weapons, and Engines can be clicked, but destroyed Midship cannot" % tag)
	check(ledger.items.any(func(it): return it.t == "Engines" and it.col == GS.MAP_EMBER), "%s: Engines is marked as selected" % tag)
	if tag == "1152x1024":
		var scale: float = ledger.k
		ledger.k = 1.3
		ledger.layout()
		check(ledger.items.any(func(it): return it.t in ["-10 to hit, +15 crit", "-10 aim, +15 crit"]),
			"%s: Larger keeps both parts of the aim cost visible" % tag)
		ledger.k = scale
	h.set_target(target())
	ledger.ensure_layout()
	check(not acts(h).has("called"), "%s: unaimed targets have no called-shot actions" % tag)


func _check_hit_feedback(ledger, act: String) -> void:
	var hits: Array = ledger.hits.filter(func(hit): return hit.act == act)
	if hits.is_empty() or not ledger.has_method("_hit_fill"):
		check(false, "D4: %s has a hover fill and a brighter pressed fill" % act)
		return
	var hit: Dictionary = hits[0]
	var point := Rect2(hit.r).get_center()
	ledger._gui_input(_motion(point))
	var hover: Color = ledger._hit_fill(hit)
	var press := _click(point)
	ledger._gui_input(press)
	var pressed: Color = ledger._hit_fill(hit)
	press.pressed = false
	ledger._gui_input(press)
	check(hover.a > 0.0 and pressed.get_luminance() * pressed.a > hover.get_luminance() * hover.a
		and ledger._hit_fill(hit) == hover and ledger.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND,
		"D4: %s has a hover fill and a brighter pressed fill" % act)


func _camera_clear(h, tag: String) -> void:
	var cam := Rig.new()
	root.add_child(cam)
	cam.current = true
	cam.focus(Vector3.ZERO, 170.0)
	await process_frame
	await process_frame
	var shelf: Rect2 = h.ledger.sheet_r
	# Bound a 28-world-unit hull around the focus at the played camera.
	var clear := not shelf.has_point(cam.unproject_position(Vector3.ZERO))
	for x in [-14, 14]:
		for y in [-14, 14]:
			for z in [-14, 14]:
				clear = clear and cam.unproject_position(Vector3(x, y, z)).y < shelf.position.y
	check(clear, "%s: the shelf clears a selected hull at the default camera" % tag)
	cam.queue_free()


func _motion(p: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = p
	return e


func _click(p: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = p
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e
