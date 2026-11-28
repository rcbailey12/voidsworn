extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const API = preload("res://rules/battle_api.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const Report = preload("res://ui/campaign/after_action_report.gd")
const Focus = preload("res://ui/theme/modal_focus.gd")
const MapIntel = preload("res://ui/campaign/map_intel.gd")
const Portraits = preload("res://portraits/portraits.gd")
const Picture = preload("res://tools/picture_provenance.gd")
const UiScale = preload("res://ui/ui_scale.gd")

var failures := 0
var c: Campaign
var ui: UI
var shots := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--shots" and DisplayServer.get_name() != "headless":
		shots = args[1]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	c = Campaign.new()
	var err := c.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return
	c.fixed_clock = true
	c.persist_on = false
	c.teaching_tips = false
	c.battle_mode = "external"
	ui = UI.new()
	root.add_child(ui)
	ui.bind(c)
	ui.teaching.disabled = true
	ui.use_3d_map = false
	ui.map3d.intel = MapIntel.new(c)
	_scoring()
	await _victory()
	if shots.is_empty():
		await _eclipse()
		await _defeat()
	print("AR-A report and killmail: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)


func _stats(kills: int, dealt: float, taken: float, flag := false) -> Dictionary:
	return {"kills": kills, "damage_dealt": dealt, "damage_taken": taken, "flagship": flag}


func _scoring() -> void:
	check(Report.score(_stats(3, 1420, 126)) == 1901.5, "MVP weights and fractional score")
	check(Report.figure(1420) == "1,420" and Report.figure(12.25) == "12.25", "MVP figures retain useful precision and grouping")
	var winner := _stats(0, 0, 1000)
	check(Report.mvp([_stats(1, 0, 10, true), winner]) == winner, "score outranks every tie-break")
	for pair in [
		[_stats(2, 100, 40), _stats(1, 250, 40, true)],
		[_stats(1, 150, 40), _stats(1, 100, 240, true)],
		[_stats(1, 100, 41), _stats(1, 100, 40, true)],
		[_stats(1, 100, 40, true), _stats(1, 100, 40)],
	]:
		check(Report.mvp([pair[1], pair[0]]) == pair[0] and Report.mvp(pair) == pair[0], "ordered MVP comparison: " + str(pair))
	check(Report.mvp([]).is_empty(), "no ships means no MVP")


func _battle(faction: String, admiral: String) -> API:
	c.META = c.defaultMeta()
	API.JSM.rnd_seed(2082)
	c.newRun(admiral, faction)
	var api := API.new()
	check(api.load_rules() == "", "rules loaded")
	c.battle_setup = func(run: Dictionary, cfg: Dictionary) -> Dictionary:
		api.new_battle(run, cfg)
		return api.R.B
	if faction == "deathless":
		c.RUN["fleet"].append(c.newShip("d_scythe"))
	var stop: Dictionary = c.RUN["map"]["cols"][0][0]
	stop["rw"] = {"k": "repair"}
	c.battleScreen({"node": stop["id"], "seed": 2082, "kind": "battle", "obj": "rout", "col": 1, "map": "belt",
		"shape": "open", "arena": "strip", "fac": "hegemony",
		"enemies": [{"tpl": "h_picket"}, {"tpl": "h_interdictor"}, {"tpl": "h_vanguard"}]})
	# Do not leave a closure retaining the rules after settlement.
	c.battle_setup = Callable()
	return api


func _hit(api: API, from: Dictionary, target: Dictionary, amount: float) -> void:
	var gun: Dictionary = from["weapons"][0].duplicate()
	gun.merge({"pierce": 0.0, "ion": false, "crit": -1000, "acid": false, "ignite": false}, true)
	api.R.landVolley(from, gun, target, {"shots": [true], "quad": 0, "called": null,
		"res": {"hull": 0, "shield": 0, "hits": 0, "misses": 0, "crits": 0, "sys": null},
		"shBefore": target["shp"], "per": func(_rear): return amount, "torp": false})
	api.R.flush_deferred()


func _frames(count := 5) -> void:
	for i in count: await process_frame


func _label(n: Node, id: String) -> String:
	var field := n.find_child(id, true, false) as Label
	return field.text if field != null else ""


func _click(point: Vector2) -> void:
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = point
		e.global_position = point
		root.push_input(e, true)


func _key(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.pressed = down
		root.push_input(e, true)


func _verify_killmail(card: Node, record: Dictionary) -> void:
	check(card != null and Focus.top_panel() == card, "killmail opened and owns keyboard")
	if card == null: return
	var cap: Dictionary = record["captain"]
	var portrait := card.find_child("VictimPortrait", true, false) as TextureRect
	check(portrait != null and portrait.get_meta("portrait_id") == cap["portrait_id"] and portrait.texture == Portraits.captain_face(cap["portrait_id"]), "portrait comes from recorded identity")
	check(_label(card, "VictimName") == cap["full_name"], "victim name comes from record")
	check(_label(card, "Callsign") == cap["callsign"], "callsign comes from record")
	check(_label(card, "VictimShip") == "%s  /  %s" % [record["ship_name"], c.clsName(record["ship_class"])], "victim ship and class come from record")
	check(_label(card, "When") == "Round %d  |  Battle %d" % [record["round"], record["battle"]], "round and battle come from record")
	check(_label(card, "FinalBlow") == "Final blow: %s damage" % Report.figure(record["final_damage"]), "final blow comes from record")
	if record["hazard_name"] != "":
		check(_label(card, "Hazard") == "Hazard: " + record["hazard_name"] and _label(card, "Killer") == "" and _label(card, "Weapon") == "", "hazard replaces killer and weapon")
	else:
		check(_label(card, "Hazard") == "" and _label(card, "Killer") == "Killed by %s  /  %s" % [record["killer_ship_name"], c.clsName(record["killer_ship_class"])], "killer ship and class come from record")
		check(_label(card, "Weapon") == record["weapon_name"], "in-game weapon name comes from record")
	var assists := card.find_children("Assist*", "Label", true, false)
	check(assists.size() == record["assists"].size(), "assist count comes from record")
	for i in mini(assists.size(), record["assists"].size()):
		var a: Dictionary = record["assists"][i]
		check(assists[i].text == "Assist: %s  /  %s  %s%%" % [a["ship_name"], c.clsName(a["ship_class"]), Report.figure(100.0 * a["damage_share"])], "assist ship, class and share come from record")


func _victory() -> void:
	var api := _battle("voidsworn", "vex")
	var players: Array = api.R.caps("player")
	var enemies: Array = api.R.caps("enemy")
	if players.size() < 2 or enemies.size() != 3:
		check(false, "victory fixture has a fleet and three enemies")
		return
	var hero: Dictionary = players[0]
	var victim: Dictionary = players.back()
	hero["ship"]["cap"]["xp"] = float(c.RANK_XP[1]) - 1
	api.R.B["round"] = 5
	_hit(api, enemies[0], victim, 7)
	_hit(api, enemies[1], victim, 13)
	_hit(api, enemies[2], victim, 10000)
	var losses: Array = api.combat_report()["lost_ship_records"]
	if losses.size() != 1:
		check(false, "exactly one permanent combat loss")
		return
	var record: Dictionary = losses[0]
	check(record["assists"].size() == 2 and record["captain"]["portrait_id"] != "" and record["captain"]["callsign"] != "", "fixture exercises both assists, real portrait and callsign")
	for foe in enemies: _hit(api, hero, foe, 10000)
	api.R.B["round"] += 1
	c.finish_battle("win", api.R.B)
	if shots.is_empty():
		victim["name"] = "Moved ship name"
		victim["ship"]["cap"]["full_name"] = "Changed captain"
		victim["ship"]["cap"]["callsign"] = "Changed callsign"
		victim["ship"]["cap"]["portrait_id"] = ""
		enemies[2]["name"] = "Changed killer"
		enemies[2]["weapons"][0]["n"] = "Changed weapon"
	await _frames()
	var sm: Dictionary = c.RUN["last_battle_report"]
	var before := c.save_text()
	var run_before: Dictionary = c.RUN.duplicate(true)
	var table := ui.modal_box.find_child("SpotlightReport", true, false)
	check(table != null and c.modal_d["kind"] == "victory", "settled victory draws the report before salvage")
	if table == null: return
	var row: Dictionary = sm["ship_rollups"][hero["id"]]
	check(row["captain_xp"] > 0 and not row.has("promoted") and not row.has("flagship") and not row.has("hull_max"), "settled XP on 2078's rollup, which the report does not extend")
	check(sm["lost_ship_records"].size() == 1 and sm["lost_ship_records"][0] == record, "the killmail record is the LostShipRecord in RUN.last_battle_report")
	check(c.modal_d["data"]["summary"]["xp"].any(func(x): return x["cap"]["captain_id"] == row["captain"]["captain_id"] and x["up"]), "promotion comes from the settled XP line")
	var facts: Array = Report.with_fleet_facts(Report.fleet_rows(sm["ship_rollups"]), c)
	var hero_facts: Array = facts.filter(func(f): return f["ship_uid"] == hero["ship"]["uid"])
	check(hero_facts.size() == 1 and hero_facts[0]["flagship"] and hero_facts[0]["hull_max"] == float(c.derive(hero["ship"])["maxHp"]), "flagship and maximum hull read from the run")
	check(facts.filter(func(f): return f["flagship"]).size() == 1 and not sm["ship_rollups"][hero["id"]].has("flagship"), "one flagship, and the saved report is not written")
	check(table.find_child("Promotion", true, false) != null, "promotion shown in the table")
	check(_label(table, "MvpReason") == "MVP: 3 kills, %s damage dealt" % Report.figure(row["damage_dealt"]), "spotlight uses settled applied damage")
	check(ui.modal_box.find_children("*", "Label", true, false).any(func(l): return l.text.begins_with("Field repairs:")), "field repairs kept")
	check(c.screen_acts().any(func(a): return a[0] == "takeSalvage"), "salvage still reachable")
	var loss_link := table.find_child("ViewKillmail", true, false) as Button
	check(loss_link != null and loss_link.get_parent().get_parent().get_meta("lost", false), "permanent loss has a row and killmail link")
	if loss_link == null: return
	await _capture("AR-A_victory")
	loss_link.grab_focus()
	_click(loss_link.get_global_rect().get_center())
	await _frames()
	var mail := ui.modal_box.get_node_or_null("Killmail")
	_verify_killmail(mail, record)
	if mail == null: return
	await _capture("AR-A_killmail")
	_click((mail.find_child("KillmailCard", true, false) as Control).get_global_rect().get_center())
	await _frames()
	check(is_instance_valid(mail), "click inside does not close card")
	_key(KEY_1)
	check(c.save_text() == before, "killmail blocks salvage shortcut")
	_click(Vector2(3, 3))
	await _frames()
	check(not is_instance_valid(mail) and root.gui_get_focus_owner() == loss_link, "outside click closes without click-through and restores focus")
	loss_link.pressed.emit()
	await _frames()
	_key(KEY_ESCAPE)
	await _frames()
	check(ui.modal_box.get_node_or_null("Killmail") == null and c.save_text() == before and c.RUN == run_before, "Escape closes only killmail and never writes")
	if shots.is_empty():
		UiScale.set_player(1.3)
		root.size = Vector2i(800, 900)
		await _frames()
		var compact := ui.modal_box.find_child("SpotlightReport", true, false) as Control
		check(compact != null and root.get_visible_rect().encloses(Rect2(Vector2(compact.global_position.x, 0), Vector2(compact.size.x, 1))), "large text report fits a narrow window")
		UiScale.set_player(1.0)
		root.size = Vector2i(1920, 1080)
		await _frames()
		c.load_save_text(before)
		c.ACT_continueRun()
		await _frames()
		var restored := ui.modal_box.find_child("ViewKillmail", true, false) as Button
		check(restored != null, "saved victory report still has its loss link")
		if restored != null:
			restored.pressed.emit()
			await _frames()
			_verify_killmail(ui.modal_box.get_node_or_null("Killmail"), record)
			_key(KEY_ESCAPE)
			await _frames()
	c.endRun(true)
	await _frames()
	var timeline := ui.debrief.find_child("TimelineLossRecords", true, false) as Button
	check(timeline != null, "loss link on run timeline")
	if timeline == null: return
	var end_save := c.save_text()
	timeline.pressed.emit()
	await _frames()
	_verify_killmail(ui.debrief.get_node_or_null("Killmail"), record)
	_key(KEY_ESCAPE)
	await _frames()
	check(ui.debrief.get_node_or_null("Killmail") == null and c.save_text() == end_save, "timeline killmail is read only")


func _eclipse() -> void:
	var api := _battle("deathless", "nekhet")
	var victim: Dictionary = api.R.caps("player").back()
	var enemies: Array = api.R.caps("enemy")
	check(api.R.legionCan(victim), "Eclipse test uses a reassembly-capable hull")
	_hit(api, enemies[0], victim, 10000)
	if victim.get("riseAt") == null:
		check(false, "the Eclipse ship is queued to rise")
		return
	check(api.combat_report()["lost_ship_records"].size() == 1 and c.RUN["timeline"].size() == 1, "wreck recorded while waiting to reassemble")
	api.R.B["round"] = victim["riseAt"]
	check(api.R.legionTurn("player").has(victim), "Eclipse hull reassembles through the round path")
	check(api.combat_report()["lost_ship_records"].is_empty() and c.RUN["timeline"].is_empty(), "reassembled hull has no battle or timeline LostShipRecord")
	for foe in enemies: _hit(api, victim, foe, 10000)
	c.finish_battle("win", api.R.B)
	await _frames()
	var rollup: Dictionary = c.RUN["last_battle_report"]["ship_rollups"][victim["id"]]
	check(not rollup["lost"] and c.RUN["last_battle_report"]["lost_ship_records"].is_empty(), "settled report keeps the recovered ship alive")
	var table := ui.modal_box.find_child("SpotlightReport", true, false)
	check(table != null and table.get_children().any(func(row): return row.get_meta("ship_uid", "") == victim["ship"]["uid"] and not row.get_meta("lost")), "recovered ship has a non-lost row")
	check(table != null and table.find_child("ViewKillmail", true, false) == null, "recovered ship has no killmail button")
	c.endRun(true)
	await _frames()
	check(ui.debrief.find_child("TimelineLossRecords", true, false) == null, "recovered ship does not add a timeline loss link")


func _defeat() -> void:
	var api := _battle("voidsworn", "vex")
	for ship in api.R.caps("player"):
		ship["hp"] = 1.0
		api.R.B["well"] = {"q": ship["q"], "r": ship["r"]}
		api.R.wellTick(ship, [])
		api.R.flush_deferred()
	var records: Array = api.combat_report()["lost_ship_records"]
	check(records.size() > 1, "defeat fixture has multiple hazards recorded")
	c.finish_battle("loss", api.R.B)
	await _frames()
	var table := ui.modal_box.find_child("SpotlightReport", true, false)
	check(c.modal_d != null and c.modal_d["kind"] == "defeat_report" and table != null, "defeat shows the same table")
	if table == null: return
	var loss_links := table.find_children("ViewKillmail*", "Button", true, false)
	check(loss_links.size() == records.size(), "every lost ship has its own card")
	if loss_links.is_empty(): return
	loss_links[0].pressed.emit()
	await _frames()
	_verify_killmail(ui.modal_box.get_node_or_null("Killmail"), records[0])
	_key(KEY_ESCAPE)
	await _frames()
	check(c.modal_d != null, "first Escape keeps defeat report open")
	_key(KEY_ESCAPE)
	await _frames()
	check(c.modal_d == null and c.page["kind"] == "end", "continue releases to run debrief")
	var timeline := ui.debrief.find_child("TimelineLossRecords", true, false) as Button
	check(timeline != null, "defeat losses stay on run timeline")
	if timeline == null: return
	timeline.pressed.emit()
	await _frames()
	var choices: Array = ui.debrief.overlay.find_children("*", "Button", true, false).filter(func(b): return b.text.begins_with("Battle "))
	check(choices.size() == records.size(), "timeline lists every lost hull")
	if choices.is_empty(): return
	choices.back().pressed.emit()
	await _frames()
	_verify_killmail(ui.debrief.get_node_or_null("Killmail"), records.back())
	_key(KEY_ESCAPE)
	await _frames()
	check(is_instance_valid(ui.debrief.overlay), "closing timeline killmail keeps the loss list open")


func _capture(code: String) -> void:
	if shots.is_empty() or failures > 0: return
	check(not Picture.capture_is_direction_check(), code + " requires the game's hardware renderer")
	if failures > 0: return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check(img.get_size() == Vector2i(1920, 1080), code + " uses the full HD viewport")
	if failures > 0: return
	img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	check(preload("res://tools/picture_provenance.gd").save_png(img, shots.path_join(code + ".png"), Picture.capture_stage()) == OK, "saved and stamped " + code)
