# Issue 2029 items 2 to 5, on the real campaign screens (headless):
#   godot --headless --path godot --script res://ui/campaign/test/desk_polish_2029_test.gd
#   2. the Run options drawer is solid (alpha 1) and the page behind it is dimmed;
#   3. the one run option is labelled as an experimental mode in plain words, and still works as before;
#   4. in the shipyard Decommission sits on its own row away from Repair and Mk, and asks first: the confirm names the ship
#      and the credits returned; Keep it changes nothing; Decommission sells;
#   5. the admiral's quote takes the faction accent (faction_looks.json through Kit.faction_accent), not the shared green.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const API = preload("res://rules/battle_api.gd")
var C
var ui
var fails := 0

class DeskUI extends CampaignUI:
	func _map() -> Control: return Control.new()   # keep the 3D map out of this test

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + message)
	if not ok: fails += 1

func frames(n := 5) -> void:
	for i in n: await process_frame

func _bind() -> void:
	C = Campaign.new(); C.load_tables(); C.fixed_clock = true; C.teaching_tips = false; C.persist_on = false
	var host := Node.new(); host.name = "Host"; root.add_child(host)
	var story = load("res://story/story.gd").new(); story.name = "Story"; host.add_child(story)
	story.attach(C, false)   # the story layer as the game shell attaches it, career kept in memory only
	ui = DeskUI.new(); ui.use_3d_map = false; host.add_child(ui); ui.bind(C)

func _texts(scope: Node) -> String:
	var lines := PackedStringArray()
	for n in scope.find_children("*", "Label", true, false): lines.append(n.text)
	for n in scope.find_children("*", "Button", true, false): lines.append(n.text)
	for n in scope.find_children("*", "RichTextLabel", true, false): lines.append(n.get_parsed_text())
	return "\n".join(lines)

func _press_node(scope: Node, action: String, arg := "") -> Control:
	for node in scope.find_children("*", "Control", true, false):
		if node.get_meta("press_act", "") == action and node.get_meta("press_arg", "") == arg: return node
	return null

func run() -> void:
	root.size = Vector2i(1920, 1080)
	_bind()
	await frames()
	C.act("newRunScreen"); await frames()
	check(str(C.page["kind"]) == "admiral", "the setup desk opens")
	# 2 and 3: the Run options drawer
	ui.desk_opts_open = true; ui.render(); await frames(8)
	var dr = ui.page_box.find_child("RunOptionsDrawer", true, false)
	var dim = ui.page_box.find_child("RunOptionsDim", true, false)
	check(dr != null and dim != null, "the drawer and its dim are on the desk")
	var sb: StyleBoxFlat = dr.get_theme_stylebox("panel")
	check(sb != null and is_equal_approx(sb.bg_color.a, 1.0), "the drawer panel is solid (alpha %.2f)" % (sb.bg_color.a if sb != null else -1.0))
	check(dim != null and dim.color.a >= 0.6 and dim.color.a < 1.0, "the page behind is dimmed (alpha %.2f)" % (dim.color.a if dim != null else -1.0))
	var tg: CheckBox = dr.find_child("MapTrialToggle", true, false)
	var drawer_text: String = _texts(dr)
	check(tg != null and tg.text.begins_with("Experimental mode"), "the test switch is labelled Experimental mode (%s)" % (tg.text if tg != null else "none"))
	check(drawer_text.contains("test setting, not the tuned game"), "the drawer says in plain words what it is")
	var before: bool = C.map_trial_choice
	tg.button_pressed = not before; await frames(3)
	check(C.map_trial_choice == (not before), "the switch still turns the trial on and off")
	tg = ui.page_box.find_child("MapTrialToggle", true, false)
	if tg != null: tg.button_pressed = before
	await frames(3)
	check(C.map_trial_choice == before, "and back")
	ui.desk_opts_open = false; ui.render(); await frames()
	# 5: the admiral's quote colour, every faction
	var bad := []
	for fac in C.RUN_FACTIONS:
		C.act("pickFaction", str(fac)); await frames(4)
		var line: String = ui._story_text()
		var found = null
		for n in ui.page_box.find_children("*", "Label", true, false):
			if n.text == line and line != "": found = n
		var want: Color = Kit.faction_accent(str(fac))
		if found == null: bad.append(str(fac) + ": no quote shown")
		else:
			var got: Color = found.get_theme_color("font_color")
			if not got.is_equal_approx(want): bad.append(str(fac) + ": quote " + str(got) + " not " + str(want))
			if got.is_equal_approx(GS.VERD): bad.append(str(fac) + ": still the shared green")
	check(bad.is_empty(), "every faction's admiral quote is in its own accent (%s)" % str(bad))
	var seen := {}
	for fac in C.RUN_FACTIONS: seen[str(Kit.faction_accent(str(fac)))] = true
	check(seen.size() >= 4, "the factions' accents differ from each other (%d distinct)" % seen.size())
	# 4: the shipyard
	C.rng.rnd_seed(2029); C.META = C.defaultMeta()
	var adm = null
	for id in C.ADMIRALS.keys():
		if C.ADMIRALS[id].get("fac") == "voidsworn" and adm == null: adm = id
	C.newRun(adm, "voidsworn", {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null; C.RUN["credits"] = 5000
	if C.RUN.get("aspect") == null: C.RUN["aspect"] = C.ASPECTS.keys()[0]
	C.RUN["fleet"].append(C.newShip(C.cheapHull("voidsworn")))
	var target := ""
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if target != "": break
			C.RUN["pos"] = n["id"]
			for id in C.availableNodes():
				var m = C.findNode(id)
				if target == "" and m != null and m["type"] == "shipyard" and not C.nemNodeIs(m): target = id
			if target != "": n["done"] = true
	C.RUN["curNode"] = null
	C.mapScreen(); await frames()
	C.act("enterNode", target); await frames(8)
	check(str(C.page["kind"]) == "shipyard", "the shipyard is open")
	var ship = C.RUN["fleet"][1]; var uid: String = ship["uid"]
	var roster: Array = ui.page_box.find_children("*", "Button", true, false).filter(func(b): return b.get_meta("yard_ship", "") == uid)
	check(roster.size() == 1, "the ship has one selectable Gantry roster row")
	if roster.size() == 1:
		roster[0].pressed.emit()
		await frames()
	var dec = _press_node(ui.page_box, "sellShip", uid)
	var rep = _press_node(ui.page_box, "repair", uid)
	var mk = _press_node(ui.page_box, "upgradeMk", uid)
	check(dec != null and rep != null and mk != null, "the ship card has Decommission, Repair and Mk buttons")
	if dec != null and rep != null and mk != null:
		check(dec.get_parent() != rep.get_parent() and dec.get_parent() != mk.get_parent(), "Decommission is not in the row with Repair and Mk")
		check(dec.get_parent().name == "ApartRow", "it sits on its own row")
		check(dec.get_global_rect().position.y > maxf(rep.get_global_rect().end.y, mk.get_global_rect().end.y) + 8.0, "and below them with a gap (%d px)" % int(dec.get_global_rect().position.y - rep.get_global_rect().end.y))
	var fleet_before: int = C.RUN["fleet"].size(); var cr_before: float = float(C.RUN["credits"])
	C.act("sellShip", uid); await frames(6)
	check(C.modal_d != null and C.modal_d["kind"] == "sell", "pressing Decommission opens a confirm, it does not sell")
	check(C.RUN["fleet"].size() == fleet_before and is_equal_approx(float(C.RUN["credits"]), cr_before), "nothing is sold yet")
	var modal: String = _texts(ui.modal_box)
	var value: String = C.numstr(C.sellValue(ship))
	check(modal.to_lower().contains(str(ship["name"]).to_lower()), "the confirm names the ship (%s)" % str(ship["name"]))
	check(modal.contains(value), "and the credits returned (%s)" % value)
	check(_press_node(ui.modal_box, "sellConfirm", uid) != null and _press_node(ui.modal_box, "closeModal") != null, "with Keep it and Decommission to choose from")
	C.act("closeModal"); await frames(3)
	check(C.RUN["fleet"].size() == fleet_before, "Keep it keeps the ship")
	C.act("sellShip", uid); await frames(3)
	C.act("sellConfirm", uid); await frames(3)
	check(C.RUN["fleet"].size() == fleet_before - 1 and float(C.RUN["credits"]) > cr_before, "Decommission then sells it and pays the credits")
	print("desk_polish_2029_test: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
