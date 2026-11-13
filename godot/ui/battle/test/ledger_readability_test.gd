extends SceneTree
# Issue 271 step 2: the battle screen's orders sheet (E1 LEDGER) against the rail spec's readability checks, at 1920x1080
# and 2560x1440, headless. contrib/opus/briefs/campaign_rail_orders_sheet.md, "The readability pass":
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
		{"i": 0, "name": "Sear battery", "arc": "P", "rng": "1-5", "hit": -1, "why": "out of range", "right": "ready", "ready": true, "armed": false, "dmg": -1, "cost": "free", "desc": "Port broadside, 3x6 damage, range 5", "arc_tip": "Port broadside, range 1 to 5 hexes."},
		{"i": 1, "name": "Sear battery", "arc": "S", "rng": "1-5", "hit": -1, "why": "out of range", "right": "ready", "ready": true, "armed": false, "dmg": -1, "cost": "free", "desc": "Starboard broadside, 3x6 damage, range 5", "arc_tip": "Starboard broadside, range 1 to 5 hexes."},
		{"i": 2, "name": "Oath lance", "arc": "F", "rng": "1-7", "hit": 92 if odds else -1, "why": "92%" if odds else "ready", "right": "92%", "ready": true, "armed": false, "dmg": 16, "cost": "CD 2", "desc": "Forward, 1x18 damage, range 7, reload 2", "arc_tip": "Forward, range 1 to 7 hexes."}]


func orders(all := false) -> Array:
	var o: Array = [{"text": "Brace (B)", "act": "brace", "on": true, "tip": "Hull damage -40% until its next turn."},
		{"text": "Concentrated fire", "act": "ability", "on": true, "tip": "+15 aim this round."},
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
	return {"name": name, "cls": cls, "side": "player", "flag": true, "hp": 135, "maxHp": 135, "sh": [20, 20, 20, 20], "shMax": 20,
		"stats": "Hull 135/135   Armor 20%   Evasion 10\nMovement 0 of 4   Turns 1", "captain": "Captain Ilsa Marr", "move": [0, 4], "arm": 20, "turns": 1,
		"tag": "UP", "danger": 2, "flags": flags, "weapons": ws if not ws.is_empty() else weapons(), "orders": ords if not ords.is_empty() else orders()}


func rows(n := 3, long := false) -> Array:
	var names := ["Unyielding Oath", "Unpaid Debt", "Iron Dusk"]
	var out: Array = []
	for i in n:
		var nm: String = names[i] if i < names.size() and not long else ("Sunward Martyr of the Ninth Pyre" if long and i == 0 else "Ember Picket %d" % (i + 1))
		var st := "Up" if i == 0 else ("Ready" if i < n / 2 else "Done")
		out.append({"id": "p%d" % i, "name": nm, "cls": "Picket", "hp": 135 - i * 3 if i != 1 else 85, "maxHp": 135, "sh": [10, 10, 10, 10], "shMax": 10,
			"status": st, "sel": i == 0, "done": st == "Done", "flag": i == 0, "new": false, "danger": 1 if i == 1 else 0})
	return out


func target(name := "Fleet Marshal Petra Valk") -> Dictionary:
	return {"name": name, "flag": true, "nem": true, "hp": 120, "maxHp": 120, "sh": [20, 20, 20, 20], "shMax": 20, "exp_hull": 8.0, "exp_sh": [7.0, 0.0, 0.0, 0.0],
		"line": "The bearing gun: about 15 damage, about 7 on its prow shield and 8 on hull."}


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
		if nm == "NEM" and not ("Nemesis" == str(it["t"]) or str(it["t"]).to_lower() == str(h.ledger.nem.get("name", "")).to_lower() or str(it["t"]) == str(h.ledger.target.get("name", "")).to_upper() or (str(it["t"]).length() > 3 and str(it["t"]) in str(h.ledger.target.get("name", "")).to_upper())):
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
		var bright := Color(1, 1, 1).lerp(Color(0, 0, 0), d)
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


func _run() -> void:
	for sz in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = sz
		root.content_scale_size = Vector2i.ZERO
		await process_frame
		var h = HUD.new()
		root.add_child(h)
		await process_frame
		await process_frame
		var tag := "%dx%d" % [sz.x, sz.y]
		check(absf(h.ledger.size.x - sz.x) < 1.0, "%s: the sheet covers the window (%s)" % [tag, str(h.ledger.size)])
		for i in 3:
			h.add_log(["Fleet Marshal Petra Valk: \"Every move you can make has been planned for.\"", "Fleet Marshal Petra Valk: \"All reserve squadrons, jump in now. Encircle them.\"", "Contact: Hegemony Navy, 2 ships on the scanners."][i], "e")
		# 1. your turn with a target (the step 1 moment)
		feed(h, {})
		await process_frame
		var r1 := measure(h, tag + " your turn, target", sz.y == 1080)
		var a := acts(h)
		for need in ["confirm", "arm", "brace", "ability", "rotl", "rotr", "next", "command", "end", "pick", "menu", "log"]:
			check(a.has(need), "%s: '%s' is reachable on the sheet" % [tag, need])
		check(int(a.get("arm", 0)) == 3 and int(a.get("pick", 0)) == 3, "%s: every gun and every fleet line can be clicked" % tag)
		var words := PackedStringArray()
		for x in h.ledger.items:
			words.append(str(x["t"]))
		var joined := " | ".join(words)
		check("FIRE THE OATH LANCE" in joined and "92%" in joined and "UNYIELDING OATH" in joined and "Hegemony Navy, 2 ships" in joined, "%s: the moment reads as E1 (FIRE THE OATH LANCE, 92%%, the ship, the enemy)" % tag)
		check("About 15 damage: 7 to its prow shield, 8 to hull." in " ".join(words), "%s: the expected damage is one sentence" % tag)
		var tips_ok := true
		for x in h.ledger.hits:
			if str(x["act"]) == "" and str(x["tip"]) == "":
				tips_ok = false
		check(tips_ok, "%s: every hover area has something to show" % tag)
		check(h.ledger.detail_bb.contains("Armor") and h.ledger.detail_bb.contains("Captain") and h.ledger.detail_bb.contains("Tab"), "%s: the ship name's hover carries the captain, armour and the keys" % tag)
		no_lime(h, tag)
		# hover over the ship name shows the detail layer
		h.ledger._gui_input(_motion(Vector2(h.ledger.px(80), h.ledger.px(140))))
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
		check(h.over_ui(Vector2(h.ledger.px(200), sz.y * 0.5)) and not h.over_ui(Vector2(sz.x * 0.7, sz.y * 0.5)), "%s: clicks on the sheet stay off the board, clicks in the clear part reach it" % tag)
		check(h.clear_shift() > 100.0, "%s: the camera looks at the middle of the clear part (shift %.0f px)" % [tag, h.clear_shift()])
		# 2. the enemy's turn
		feed(h, {"turn": "Enemy turn", "card": {}, "target": {}, "ship": {}, "cmd": false, "phase_kind": "enemy",
			"phase_text": "[b][color=#c4a4ff]ENEMY TURN[/color][/b]  ·  Hegemony Navy: Iron Warden  ·  [color=#8d86a0]Enter hurries[/color]", "phase_p": 0.4})
		await process_frame
		measure(h, tag + " enemy turn")
		var j2 := ""
		for x in h.ledger.items:
			j2 += str(x["t"]) + " | "
		check("Enemy turn" in j2 and "Hegemony Navy: Iron Warden" in j2 and not "FIRE" in j2, "%s: the enemy's turn says whose turn and who is moving, no action" % tag)
		# 3. a "you may" prompt (issue 529, PR 533's words) in the shot's place
		feed(h, {"ask": {"kind": "may", "key": "debtDue", "n": "Debt Comes Due", "q": "Delay the whole volley to the start of next round? It fires then with +20% damage.",
			"opts": [{"id": "yes", "n": "Delay the volley"}, {"id": "no", "n": "Fire it now"}]}})
		await process_frame
		measure(h, tag + " you may prompt")
		check(h.ask_panel != null and int(acts(h).get("ask", 0)) == 2 and not acts(h).has("confirm"), "%s: the prompt takes the shot's place with its two choices; FIRE waits" % tag)
		h.hide_ask()
		check(h.ask_panel == null, "%s: answering the prompt clears it" % tag)
		# 4. the long cases: the longest names, six guns, every order, 20 ships
		var ws: Array = weapons()
		for i in 3:
			ws.append({"i": 3 + i, "name": "Hellfire torpedo rack", "arc": "T", "rng": "2-9", "hit": 41 + i, "why": "", "right": "", "ready": true, "armed": i == 1, "dmg": 30, "cost": "CD 3", "desc": "Turret, 1x30 damage."})
		var long_ship := ship("Sunward Martyr of the Ninth Pyre", "Pyre-Barge, elite captain", ws, orders(true),
			"[color=#9fd4ff]Braced: hull damage -40% until its next turn.[/color] [color=#ff8a72]Torpedoes inbound: move 3 or more hexes from its marked hex to dodge.[/color]")
		var big := rows(20, true)
		feed(h, {"rows": big})
		await process_frame
		var r4 := measure(h, tag + " 20 ships")
		check(int(r4["fleet"].get("shown", 0)) >= 2 and int(acts(h).get("pick", 0)) == int(r4["fleet"].get("shown", 0)), "%s: a 20-ship fleet shows %d lines and folds the rest into one (hover lists them)" % [tag, int(r4["fleet"].get("shown", 0))])
		feed(h, {"ship": long_ship, "target": target("Grand Admiral Seraphine Voss-Haldane"), "rows": rows(3, true)})
		await process_frame
		measure(h, tag + " six guns, every order, the longest names")
		feed(h, {"ship": long_ship, "target": target("Grand Admiral Seraphine Voss-Haldane"), "rows": big})
		await process_frame
		var r6 := measure(h, tag + " all of it at once (6 guns, every order, 20 ships)")
		check(h.ledger.compact == 1 and (int(r6["fleet"].get("shown", 0)) >= 1 or bool(r6["fleet"].get("summary", false))), "%s: when the sheet runs out of room the guns that cannot fire fold into one line and the fleet keeps its foot" % tag)
		# 5. no ship up yet: pick a ship
		feed(h, {"ship": {}, "target": {}, "card": {"name": "Pick a ship", "tag": "YOUR TURN", "steps": [], "say": "Pick a ship: click one of yours or press Tab.",
			"buttons": [{"text": "Next ship (Tab)", "act": "next", "on": true, "big": true}]}})
		await process_frame
		measure(h, tag + " pick a ship")
		check(acts(h).has("next"), "%s: with no ship up, the action is Next ship (Tab)" % tag)
		h.queue_free()
		await process_frame
	print("ledger readability: %d checks failed" % fails)
	var f := FileAccess.open("user://ledger_readability.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
	quit(1 if fails > 0 else 0)


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
