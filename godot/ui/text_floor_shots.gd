extends SceneTree
# Issue 644: before and after captures for the 17 px text floor (RULEBOOK 9.4), five screens at 1920 by 1080.
#   godot --path godot --resolution 1920x1080 --script res://ui/text_floor_shots.gd -- <out dir> [campaign|battle|glass|career|title|all]
# Campaign pages (map, fleet at the smallest and largest fleet, shipyard, event, progression, run end), the battle HUD
# (the orders sheet with one ship and with twenty, fed the readability test's sample moment over a plain dark board: a
# battle with real ships needs the built ship files, which the sandbox lacks), the Career screen
# with sample data, and the title's Credits and Settings panels. Sample data only: no save, no career file, no settings
# file is written (the campaign's persistence is off, the career is a fresh default profile in memory).
# Prints one TEXT_FLOOR line per capture with the smallest font size found in the visible tree and any overlapping
# labels, so a run also checks what the picture shows.

const PG := preload("res://render/placeholder_guard.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
const Career = preload("res://story/career.gd")
const StoryScript = preload("res://story/story.gd")
const Title = preload("res://main/title.gd")

var dir := ""
var C
var ui
var report: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://text_floor_shots"
	var which := a[1] if a.size() > 1 else "all"
	DirAccess.make_dir_recursive_absolute(dir)
	_run(which)


func _run(which: String) -> void:
	await _frames(4)
	var win := get_root()
	win.mode = Window.MODE_WINDOWED
	await _frames(4)
	win.size = Vector2i(1920, 1080)
	await _frames(8)
	if which in ["campaign", "all"]:
		await _campaign()
	if which in ["battle", "all"]:
		await _battle()
	if which in ["glass", "all"]:
		await _glass()
	if which in ["career", "all"]:
		await _career()
	if which in ["title", "all"]:
		await _title()
	var f := FileAccess.open(dir.path_join("text_floor_report.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(report) + "\n")
	print("text_floor_shots: wrote ", dir)
	PG.finish(0)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String, top: Node = null) -> void:
	await _frames(6)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	var m := _measure(top if top != null else root)
	var line := "TEXT_FLOOR %s smallest=%d at %s overlaps=%d %s" % [name, int(m["min"]), str(m["min_at"]), m["over"].size(), " | ".join(m["over"].slice(0, 4))]
	print(line)
	report.append(line)


# the smallest font size among visible labels, buttons and rich text (in px at this window, which is 1080 tall), and
# every pair of visible text controls whose text boxes overlap (a box clipped by a scroll container is left out)
func _measure(top: Node) -> Dictionary:
	var items: Array = []
	_collect(top, items)
	var mn := 999.0
	var mn_at := ""
	for it in items:
		if it["size"] < mn:
			mn = it["size"]
			mn_at = it["text"]
	var over: Array = []
	for i in items.size():
		for j in range(i + 1, items.size()):
			var a: Dictionary = items[i]
			var b: Dictionary = items[j]
			if a["node"].is_ancestor_of(b["node"]) or b["node"].is_ancestor_of(a["node"]):
				continue
			var r: Rect2 = a["rect"].intersection(b["rect"])
			if r.size.x > 2.0 and r.size.y > 2.0:
				over.append("'%s' x '%s'" % [a["text"], b["text"]])
	return {"min": mn, "min_at": mn_at, "over": over}


func _collect(n: Node, out: Array) -> void:
	if n is CanvasItem and not (n as CanvasItem).is_visible_in_tree():
		return
	if n is Control and (n as Control).modulate.a < 0.05:
		return
	if n is Label or n is Button or n is RichTextLabel:
		var c := n as Control
		var txt := ""
		var sz := 0
		if n is Label:
			txt = (n as Label).text
			sz = c.get_theme_font_size("font_size")
		elif n is Button:
			txt = (n as Button).text
			sz = c.get_theme_font_size("font_size")
		else:
			txt = (n as RichTextLabel).get_parsed_text()
			sz = c.get_theme_font_size("normal_font_size")
		txt = txt.strip_edges().replace("\n", " ")
		if txt != "" and c.size.x > 0 and c.size.y > 0:
			var r := c.get_global_rect()
			if n is Label:
				var w := minf(r.size.x, (n as Label).get_minimum_size().x)
				var lb := n as Label
				if lb.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
					r = Rect2(r.end.x - w, r.position.y, w, r.size.y)
				elif lb.horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER:
					r = Rect2(r.position.x + (r.size.x - w) * 0.5, r.position.y, w, r.size.y)
				else:
					r = Rect2(r.position, Vector2(w, r.size.y))
			var clip := _clip_of(c)
			if clip.size.x > 0:
				r = r.intersection(clip)
			if r.size.x > 1 and r.size.y > 1 and r.intersects(Rect2(Vector2.ZERO, Vector2(1920, 1080))):
				out.append({"node": n, "text": txt.substr(0, 40), "size": sz, "rect": r})
	for ch in n.get_children():
		_collect(ch, out)


func _clip_of(c: Control) -> Rect2:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer or (p is Control and (p as Control).clip_contents):
			return (p as Control).get_global_rect()
		p = p.get_parent()
	return Rect2()


# ---------------------------------------------------------------- the campaign pages
func _campaign() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err)
		return
	C.persist_on = false
	ui = UIScript.new()
	root.add_child(ui)
	ui.bind(C)
	await _frames(4)
	BattleAPI.JSM.rnd_seed(644)
	C.UID = 1; C.RUN = null; C.B = null; C.SAVED_RUN = null; C.META = C.defaultMeta(); C.picked_admiral = "vex"; C.picked_faction = "voidsworn"
	C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; C.ended = false
	C.titleScreen(); C.act("newRunScreen")
	await _shot("campaign_admiral", ui)
	C.act("startRun")
	if C.page.get("kind") == "aspect":
		await _shot("campaign_aspect", ui)
		C.act("pickAspect", C.W["aspOffer"][0])
	C.act("closeModal")
	await _frames(30)
	await _shot("campaign_map", ui)
	# the two slide-overs on the map take the shared orders-sheet theme (glass_shell.gd sheet_theme and make_theme)
	ui._open_overlay("dossier")
	await _shot("glass_dossier", ui)
	ui._open_overlay("key")
	await _shot("glass_map_key", ui)
	ui._close_overlay()
	await _frames(4)
	C.act("fleetScreen", "")
	await _shot("campaign_fleet_small", ui)
	C.act("backMap", "")
	var yard = {"id": "tf_yard", "type": "shipyard", "col": 3, "row": 0}
	C.shipyardScreen(yard)
	await _shot("campaign_shipyard", ui)
	# the largest fleet the run allows in practice: twelve ships, the longest hull names, two of them damaged
	var have: Array = C.RUN["fleet"]
	var tpls: Array = []
	for s in have:
		tpls.append(str(s["tpl"]))
	if C.HULLS.has("c_boss") and C.HULLS["c_boss"].has("slots"):
		tpls.append("c_boss")
	var i := 0
	while have.size() < 12:
		have.append(C.newShip(str(tpls[i % tpls.size()])))
		i += 1
	for s in have.slice(1, 3):
		s["hp"] = maxf(1.0, float(s.get("hp", 100)) * 0.3)
	C.mapScreen()
	await _frames(30)
	await _shot("campaign_map_big_fleet", ui)
	C.act("fleetScreen", "")
	await _shot("campaign_fleet_big", ui)
	C.act("backMap", "")
	C.eventScreen({"id": "tf_event", "type": "event"})
	await _shot("campaign_event", ui)
	C.act("closeModal")
	C.act("title")
	C.act("legacy")
	await _shot("campaign_progression", ui)
	C.act("title")
	C.act("newRunScreen"); C.act("startRun")
	if C.page.get("kind") == "aspect":
		C.act("pickAspect", C.W["aspOffer"][0])
	C.act("closeModal")
	C.RUN["stats"]["battles"] = 4
	C.endRun(false)
	await _shot("campaign_run_end", ui)
	ui.queue_free()
	await _frames(4)


# ---------------------------------------------------------------- the battle HUD (sample moment from ledger_readability_test.gd)
func _bweapons() -> Array:
	return [
		{"i": 0, "name": "Sear battery", "arc": "P", "rng": "1-5", "hit": -1, "why": "out of range", "right": "ready", "ready": true, "armed": false, "dmg": -1, "cost": "free", "desc": "Port broadside, 3x6 damage, range 5", "arc_tip": "Port broadside, range 1 to 5 hexes."},
		{"i": 1, "name": "Sear battery", "arc": "S", "rng": "1-5", "hit": -1, "why": "out of range", "right": "ready", "ready": true, "armed": false, "dmg": -1, "cost": "free", "desc": "Starboard broadside, 3x6 damage, range 5", "arc_tip": "Starboard broadside, range 1 to 5 hexes."},
		{"i": 2, "name": "Oath lance", "arc": "F", "rng": "1-7", "hit": 92, "why": "92%", "right": "92%", "ready": true, "armed": false, "dmg": 16, "cost": "CD 2", "desc": "Forward, 1x18 damage, range 7, reload 2", "arc_tip": "Forward, range 1 to 7 hexes."}]


func _brows(n: int) -> Array:
	var names := ["Unyielding Oath", "Unpaid Debt", "Iron Dusk"]
	var out: Array = []
	for i in n:
		var nm: String = names[i] if i < names.size() else ("Sunward Martyr of the Ninth Pyre" if i == 3 else "Ember Picket %d" % (i + 1))
		var st := "Up" if i == 0 else ("Ready" if i < n / 2 else "Done")
		out.append({"id": "p%d" % i, "name": nm, "cls": "Picket", "hp": 135 - i * 3 if i != 1 else 85, "maxHp": 135, "sh": [10, 10, 10, 10], "shMax": 10,
			"status": st, "sel": i == 0, "done": st == "Done", "flag": i == 0, "new": false, "danger": 1 if i == 1 else 0})
	return out


func _battle() -> void:
	var board := ColorRect.new()
	board.color = Color("#1d2430")   # a plain mid-dark board: the sheet's own darkening does the rest
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bl := CanvasLayer.new()
	bl.layer = -1
	bl.add_child(board)
	root.add_child(bl)
	for n in [1, 20]:
		var h = load("res://ui/battle/hud.gd").new()
		root.add_child(h)
		await _frames(2)
		h.set_info({"foe_name": "Hegemony Navy", "foe_ships": 2, "heat": 3, "heat_tip": "Heat 3 of 9."})
		h.set_command("Fire for effect", true)
		h.set_top(1, "Your turn (%d ready)" % maxi(1, n / 2), "Objective: break their fleet", "End ship (Space)", true, false, false)
		h.set_nemesis({"name": "Fleet Marshal Petra Valk", "ship": "Dominion", "flee": "flees below 25% hull", "adapted": [["Layered screens", "Shields +10%.", "you leaned on lances"]], "weak": [], "state": ""})
		h.set_roster(_brows(n))
		h.set_panel({"name": "Unyielding Oath", "cls": "Vigil-class cruiser", "side": "player", "flag": true, "hp": 135, "maxHp": 135, "sh": [20, 20, 20, 20], "shMax": 20,
			"stats": "Hull 135/135   Armor 20%   Evasion 10\nMovement 0 of 4   Turns 1", "captain": "Captain Ilsa Marr", "move": [0, 4], "arm": 20, "turns": 1,
			"tag": "UP", "danger": 2, "flags": "[color=#ff8a72]The enemy fleet is focusing its fire on this ship.[/color]", "weapons": _bweapons(),
			"orders": [{"text": "Brace (B)", "act": "brace", "on": true, "tip": "Hull damage -40% until its next turn."}, {"text": "Concentrated fire", "act": "ability", "on": true, "tip": "+15 aim this round."},
				{"text": "Turn left (Q)", "act": "rotl", "on": true}, {"text": "Turn right (E)", "act": "rotr", "on": true}]})
		h.set_target({"name": "Fleet Marshal Petra Valk", "flag": true, "nem": true, "hp": 120, "maxHp": 120, "sh": [20, 20, 20, 20], "shMax": 20, "exp_hull": 8.0, "exp_sh": [7.0, 0.0, 0.0, 0.0],
			"line": "The bearing gun: about 15 damage, about 7 on its prow shield and 8 on hull."})
		h.set_card({"name": "Unyielding Oath", "cls": "Vigil-class cruiser", "flag": true, "tag": "UP", "more": "2 more ready",
			"steps": [{"n": 1, "label": "Move", "detail": "0 of 4 left", "st": "done"}, {"n": 2, "label": "Fire", "detail": "3 of 3 guns ready", "st": "now"}, {"n": 3, "label": "End ship", "detail": "Space", "st": "todo"}],
			"hint": "[color=#ff8a6a]Target: Fleet Marshal Petra Valk.[/color] 1 gun bears from here. [b]Click it again or press Enter to fire.[/b] Esc cancels.", "say": "",
			"buttons": [{"text": "Fire 1 weapon (Enter)", "act": "confirm", "on": true, "primary": true}, {"text": "Cancel (Esc)", "act": "cancel", "on": true},
				{"text": "Next ship (Tab)", "act": "next", "on": true, "big": true}, {"text": "End ship (Space)", "act": "end", "on": true, "big": true}], "aim": true})
		h.set_phase("player", "", -1.0)
		for line in ["Contact: Hegemony Navy, 2 ships on the scanners.", "Fleet Marshal Petra Valk: \"All reserve squadrons, jump in now.\"", "Unyielding Oath moves 2 hexes."]:
			h.add_log(line, "e")
		await _frames(4)
		await _shot("battle_fleet_%d" % n, h)
		var lg = h.ledger
		var line := "TEXT_FLOOR battle_fleet_%d sheet words=%d fleet=%s" % [n, lg.items.size(), str(lg.fleet_fit)]
		print(line)
		report.append(line)
		h.queue_free()
		await _frames(2)
	bl.queue_free()


# ---------------------------------------------------------------- the shared theme (glass_shell.gd make_theme): what a
# screen gets when it sets no size of its own, a button, rich text and a hover tip, with the orders-sheet faces
const GS := preload("res://ui/theme/glass_shell.gd")


func _glass() -> void:
	var host := Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.theme = GS.make_theme(1.0, GS.sheet_body(), GS.sheet_medium())
	var bg := ColorRect.new()
	bg.color = Color("#0b0a09")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.add_child(bg)
	var v := VBoxContainer.new()
	v.position = Vector2(120, 140)
	v.custom_minimum_size = Vector2(760, 0)
	v.add_theme_constant_override("separation", 24)
	host.add_child(v)
	var head := Label.new()
	head.text = "The shared theme's own sizes (a screen that sets none gets these)"
	head.add_theme_font_size_override("font_size", 24)
	v.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	for t in ["Got it", "Turn off all tips", "Fleet and refits"]:
		var b := Button.new()
		b.text = t
		row.add_child(b)
	v.add_child(row)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.text = "Rich text: [b]Shipyard[/b] buy, repair, upgrade. [b]Drydock[/b] free repairs. [code]135 / 135[/code] hull."
	v.add_child(r)
	var tip := PanelContainer.new()
	tip.add_theme_stylebox_override("panel", host.theme.get_stylebox("panel", "TooltipPanel"))
	var tl := Label.new()
	tl.text = "A hover tip: Captains, perks, refits, the hold and your faction purchase."
	tl.add_theme_font_size_override("font_size", host.theme.get_font_size("font_size", "TooltipLabel"))
	tip.add_child(tl)
	v.add_child(tip)
	var plain := Label.new()
	plain.text = "A plain label at the theme's base size."
	v.add_child(plain)
	root.add_child(host)
	await _frames(6)
	await _shot("glass_theme", host)
	host.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- the Career screen (sample data, never the real file)
func _B(kind: String, lost: int, kills: int, us: Dictionary) -> Dictionary:
	var units: Array = []
	for i in 4:
		units.append({"id": "p%d" % i, "side": "player", "dead": i < lost, "name": ["Oathkeeper", "Ashen Vigil", "Cinder Vow", "Debt of Vesper"][i]})
	for i in 6:
		units.append({"id": "e%d" % i, "side": "enemy", "dead": i < kills, "boss": kind == "boss" and i == 0})
	return {"cfg": {"kind": kind}, "units": units, "usage": us, "round": 5, "over": "win", "finished": true}


func _career() -> void:
	var S = StoryScript.new()
	root.add_child(S)
	await process_frame
	var c = S.career
	c.P = Career.default_profile()
	var runs := [
		{"t0": 1, "admiral": "grax", "fac": "corsair", "sector": 3, "won": true, "us": {"kind": {"battery": 20, "torp": 6}, "ram": 3, "board": 2, "cap": 1}, "flag": "Rust Bucket"},
		{"t0": 2, "admiral": "aelith", "fac": "ithar", "sector": 2, "won": false, "us": {"kind": {"sq": 30, "lance": 10}}, "flag": "Clear Facet"},
		{"t0": 3, "admiral": "kassar", "fac": "hegemony", "sector": 3, "won": true, "us": {"kind": {"battery": 40}, "fire": {"Port broadside": 20, "Starboard broadside": 18, "Prow": 5}}, "flag": "Order Forty-One"},
		{"t0": 4, "admiral": "vex", "fac": "voidsworn", "sector": 1, "won": false, "us": {"kind": {"lance": 20, "battery": 15}, "aim": 9}, "flag": "Wrath of Vesper"}]
	for r in runs:
		var run := {"t0": r["t0"], "admiral": r["admiral"], "fac": r["fac"], "sector": 1, "flagUid": "f", "fleet": [{"uid": "f", "name": r["flag"]}], "heat": []}
		for s in range(1, int(r["sector"]) + 1):
			run["sector"] = s
			for b in 3:
				c.record_battle(run, _B("boss" if b == 2 else "battle", 1 if (b == 1 and s == 2) else 0, 5, r["us"]), "win")
		c.record_run_end(run, bool(r["won"]), S.admiral_name(str(r["admiral"])))
	c.record_arc_end("hegemony", "kassar", "High Nadir Halvane of the Late Copy", {"1": "offbook", "2": "broke", "3": "names"}, true)
	var scr = S.open_career()
	for t in ["records", "medals", "titles", "history", "chronicle"]:
		scr.set_tab(t)
		await _shot("career_" + t, scr)
	scr.queue_free()
	S.queue_free()
	await _frames(4)


# ---------------------------------------------------------------- the title (no showcase battle: the sky picture only)
class FakeMain:
	extends Node
	var settings := {"fullscreen": false, "sound": true, "volume": 0.8, "music": true, "music_volume": 0.7, "speed": 1.0,
		"ai": "normal", "quality": "max", "reduce_flashing": false, "shake": 1.0, "tips": true, "ui_scale": 1.0, "reduce_motion": false,
		"follow": true, "cine": "key", "movement": "cinematic", "taa": false}
	var args := {}
	func has_campaign() -> bool:
		return true
	func campaign_has_save() -> bool:
		return false
	func save_settings() -> void:
		pass   # sample settings only: nothing is written


func _title() -> void:
	var m := FakeMain.new()
	root.add_child(m)
	var t = Title.new()
	t.main = m
	m.add_child(t)
	await _frames(20)
	await _shot("title_menu", t)
	t._credits()
	await _frames(6)
	await _shot("title_credits", _last_panel(t))
	t.queue_free()
	t = Title.new()
	t.main = m
	m.add_child(t)
	await _frames(10)
	t._settings()
	await _frames(6)
	await _shot("title_settings", _last_panel(t))
	m.queue_free()


# the dialog the title opened last (its overlap check looks only inside it; the menu under it is dimmed)
func _last_panel(t: Node) -> Node:
	var best: Node = t
	for ch in t.find_children("*", "PanelContainer", true, false):
		if (ch as Control).is_visible_in_tree():
			best = ch
	return best
