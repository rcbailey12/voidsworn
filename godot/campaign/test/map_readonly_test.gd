# The campaign map only reads (Muse's outside check of PR 349, condition 1; issue #344; FINDINGS R165). Headless:
#   godot --headless --path godot --script res://campaign/test/map_readonly_test.gd
#
# The older check for this (ui_spec_tests.js) read the spelling of campaign_view.gd. This one tests the property itself:
# opening the map never creates or changes the Nemesis record, the run, the saved run, the profile or the random stream.
# Runs come from the campaign's own clicks (the start-run clicks of nem_scenarios.gd, the boss advance of nem_read_test.gd,
# the campaign's own nemClockAdd). The one typed state is the fault in part 3, and it is typed on purpose.
#
#   1. Views. On a real run at the map, every campaign_view.gd function the map screen calls and the danger estimate of
#      map_intel.gd leave the run, the save, the profile, the commander registry and the random stream exactly as they were.
#   2. The screen. The real campaign_ui.gd builds the map page with the 3D map, picks every route, points at every stop
#      (the tip card), opens the Dossier and the Map key. Same result.
#   3. Teeth. The sector's commander record and the cached alias are taken away: the state in which the campaign's own
#      nemActive builds a commander. Parts 1 and 2 run again; the record must still be missing and the stream unmoved.
#      Then nemActive is called on that state and does build the record, which shows the test would catch a reader that
#      called it (the map did, through nemNodeIs, before this change).
#   4. Asking with the commander already read gives what the campaign's own resolving calls give on the same runs:
#      nem_node_is against nemNodeIs() for every stop, nem_warn against nemWarnLine, nem_panel against nemPanelData(),
#      nem_beh against nemBeh(), in sectors 1 and 2 and with the clock one step from full.
extends SceneTree
const BattleAPI = preload("res://rules/battle_api.gd")
const JSM = BattleAPI.JSM
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const View = preload("res://campaign/campaign_view.gd")
const Intel = preload("res://ui/campaign/map_intel.gd")
var C
var ui
var fails := 0
var lines: Array = []
var fleet_coverage := {}
var fleet_shapes := {}


func check(ok: bool, what: String) -> void:
	if ok:
		lines.append("PASS " + what)
	else:
		fails += 1
		lines.append("FAIL " + what)


func fresh(seed: int) -> void:
	C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.META["backfilled"] = 1; C.META["wonFix41"] = 1; C.SAVED_RUN = null; C.RUN = null; C.B = null; C.tel_log = []
	C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
	C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")


# everything a reader must not touch, as one string
func snap() -> String:
	return JSON.stringify([C.RUN, C.SAVED_RUN, C.META]) + "|" + str(JSM.rng_s) + "|" + str(C.UID)


func all_nodes() -> Array:
	var out: Array = []
	for col in C.RUN["map"]["cols"]:
		for n in col: out.append(n)
	return out


# every read the map screen makes through the view and the estimate
func read_views() -> void:
	View.header(C); View.sector_notes(C); View.purse(C); View.admiral(C); View.fleet_rows(C); View.hold_count(C)
	View.promotion_waiting(C); View.aspect(C); View.routes(C); View.here_name(C); View.nemesis(C); View.nem_dossier(C)
	View.faction_action(C); View.run_notes(C); View.nem(C)
	var intel = Intel.new(C)
	for n in all_nodes():
		View.stop(C, n); View.stop_name(C, n); View.nem_node_is(C, n); intel.danger(n)
		intel.routes_through(str(n["id"]))
	intel.fleet_condition(); intel.all_paths()


func frames(n: int) -> void:
	for i in n: await process_frame


# the real screen: the map page, every pick, every tip, both slide-overs
func read_screen() -> void:
	# no campaign call here: the page is the one the campaign already built
	ui._dirty = true
	await frames(3)
	var t0 = Time.get_ticks_msec()
	while ui.map3d.loading and Time.get_ticks_msec() - t0 < 60000: await process_frame
	ui.render(); await frames(2)
	for id in C.page["data"]["avail"]: ui.pick_route(str(id))
	for id in ui.map3d._nodes.keys():
		ui.map3d._set_hot(str(id)); ui.map3d._update_card()
	ui.map3d._set_hot("")
	ui._open_overlay("dossier"); ui.render(); await frames(1)
	ui._open_overlay("key"); ui.render(); await frames(1)
	ui._close_overlay(); ui.render(); await frames(1)
	read_fleets()


# Read the actual built models, not a second list of what each stop should render.
func read_fleets() -> void:
	var same := true; var oriented := true; var tiers := true; var count := 0
	var groups := true; var wedge := true; var stable := true; var compact := true
	for id in ui.map3d._nodes:
		var d = ui.map3d._nodes[id]; var n = d["n"]
		if n["type"] not in ["battle", "elite", "boss"]: continue
		count += 1
		var fleet = d["obj"].get_node_or_null("EnemyFleet")
		var expected = View.stop(C, n)["fac"]
		if fleet == null: same = false; continue
		var ships = fleet.get_children()
		var level = int(ui.map3d.intel.danger(n)["level"])
		var kind = str(n["type"])
		if kind == "boss":
			if ships.size() != 1 or ships[0].get_child(0).u["cls"] != C.HULLS[C.FACTIONS[expected]["boss"]]["cls"]: groups = false
		elif kind == "elite":
			if ships.size() != 3 or ships[0].get_child(0).u["cls"] != "Cruiser": groups = false
		elif level == 1:
			if ships.size() not in [1, 2] or ships[0].get_child(0).u["cls"] not in ["Frigate", "Destroyer"]: groups = false
		else:
			if ships.size() != 3 or ships[0].get_child(0).u["cls"] not in ["Destroyer", "Cruiser"]: groups = false
		var lead_length = ships[0].get_child(0).L * ships[0].scale.x
		var shape: Array = []
		for ship in ships:
			if ship.get_child(0).u["fac"] != expected: same = false
			var length = ship.get_child(0).L * ship.scale.x
			shape.append([ship.get_child(0).u["cls"], ship.position, ship.rotation, length])
			if ship != ships[0]:
				if length > lead_length * 0.56: groups = false
				if ship.position.x >= ships[0].position.x - 1.0 or is_equal_approx(ship.position.y, ships[0].position.y): wedge = false
		if ships.size() == 3:
			if ships[1].position.z * ships[2].position.z >= 0 or is_equal_approx(ships[1].position.x, ships[2].position.x): wedge = false
		var key = str(C.RUN["sector"]) + "|" + str(id) + "|" + expected + "|" + str(level) + "|" + kind
		var signature = var_to_str(shape)
		if fleet_shapes.has(key) and fleet_shapes[key] != signature: stable = false
		fleet_shapes[key] = signature
		var bounds = ui.map3d._parts(fleet)["aabb"].size
		if maxf(bounds.x, bounds.z) > (12.0 if kind == "boss" else 9.0): compact = false
		var previous = ui.map3d._pos({"col": float(n["col"]) - 1.0, "y": 0.5})
		if fleet.basis.x.dot((previous - d["pos"]).normalized()) < 0.99: oriented = false
		var tier = int(d["tier"])
		if not is_equal_approx(float(d["sc"]), ui.map3d.TIER_SCALE[tier]): tiers = false
		for light in d["parts"]["lights"]:
			if not is_equal_approx(light[0].light_energy, light[1] * ui.map3d.TIER_LIGHT[tier]) or light[0].light_cull_mask != d["layer"]: tiers = false
		fleet_coverage[str(n["type"])] = true
		if expected != C.RUN["map"]["fac"]: fleet_coverage["rival"] = true
	check(count > 3 and same, "built fight fleets have the same faction as the rail")
	check(groups, "actual group counts and classes follow stop kind and danger, with escorts less than 56% of lead length")
	check(wedge and compact, "actual escorts trail in a staggered wedge with height differences, within a single stop footprint")
	check(stable, "repeated stop builds keep the same seeded group transforms")
	check(oriented and tiers, "enemy bows face the player's approach and models and lights use the stop tiers")


func parity(tag: String) -> void:
	var N = C.nemRead()
	var same_nodes := true
	for n in all_nodes():
		if View.nem_node_is(C, n) != C.nemNodeIs(n): same_nodes = false
	check(same_nodes, tag + ": nem_node_is equals the campaign's nemNodeIs for every stop")
	check(View.nem_warn(C, N) == C.nemWarnLine(N), tag + ": nem_warn equals the campaign's nemWarnLine (\"" + View.nem_warn(C, N) + "\")")
	check(JSON.stringify(View.nem_panel(C, N)) == JSON.stringify(C.nemPanelData()), tag + ": nem_panel equals the campaign's nemPanelData")
	check(JSON.stringify(View.nem_beh(C, N)) == JSON.stringify(C.nemBeh()), tag + ": nem_beh equals the campaign's nemBeh")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(1); return
	C.fixed_clock = true
	fresh(101)
	check(C.page.get("kind") == "map" and C.modal_d == null, "a real run stands on the map (seed 101)")
	check(C.nemRead() is Dictionary, "the campaign resolved this sector's commander when it built the map page")

	# 1. the views
	var s0 := snap()
	read_views()
	check(snap() == s0, "sector 1: reading every view and estimate changed nothing (run, save, profile, registry, random stream)")

	# 2. the real screen
	ui = UIScript.new(); root.add_child(ui); ui.bind(C)
	ui.teaching.disabled = true   # a teaching card logs that it was shown; that is the tips' own telemetry, not the map's
	var s1 := snap()
	await read_screen()
	check(snap() == s1, "sector 1: building the map page, every pick, every tip card, the Dossier and the Map key changed nothing")
	parity("sector 1")

	# Teaching changes the named opponent while the graph stays the same. Use its real setter and history function.
	C.set_teaching_tips(true)
	var teaching_snap := snap()
	await read_screen()
	check(snap() == teaching_snap, "teaching enabled: rebuilding the named enemy fleets only reads")
	var first = C.RUN["map"]["cols"][0][0]
	C.teachingBattle({"kind": "battle", "node": first["id"]})
	var next_snap := snap()
	await read_screen()
	check(snap() == next_snap, "teaching history advanced: fleets refresh to the newly named opponent without changing the run")
	C.set_teaching_tips(false)
	var tips_off_snap := snap()
	await read_screen()
	check(snap() == tips_off_snap, "teaching disabled: sector and rival fleets return without changing the run")

	# the clock one step from full, by the campaign's own function (the warning line then has words)
	var guard := 0
	while C.nemClockGet() + float(C.or_(View.nem_beh(C, C.nemRead()).get("clock"), 1)) < float(C.NEM_CLOCK) and guard < 20:
		C.nemClockAdd(1); guard += 1
	if not C.jt(C.RUN.get("nemStrike")):
		check(View.nem_warn(C, C.nemRead()) != "", "the clock is one step from full: the warning line has words")
		var s2 := snap()
		read_views(); await read_screen()
		check(snap() == s2, "clock nearly full: the views and the screen changed nothing")
		parity("clock nearly full")

	# sector 2, through the campaign's own boss advance
	C.W["rewardCfg"] = {"kind": "boss"}
	C.afterBattle()
	while C.modal_d != null and guard < 60:
		guard += 1
		var acts = C.screen_acts().filter(func(x): return x[2] == 1)
		if acts.is_empty(): break
		C.act(acts[0][0], acts[0][1])
	check(int(C.RUN["sector"]) == 2 and C.page.get("kind") == "map" and C.modal_d == null, "the campaign's own boss advance stands on the sector 2 map")
	var s3 := snap()
	read_views(); await read_screen()
	check(snap() == s3, "sector 2: the views and the screen changed nothing")
	parity("sector 2")

	# 3. teeth: no record and no cached alias for this sector's commander
	var fac = C.nemAssignSlot()
	C.RUN["nems"].erase(fac); C.RUN["nem"] = null
	check(C.nemRead() == null, "fault set: the sector's commander record and the cached alias are gone (" + str(fac) + ")")
	var s4 := snap()
	read_views(); await read_screen()
	check(not C.RUN["nems"].has(fac) and C.RUN.get("nem") == null, "with no record: the views and the screen did not build a commander")
	check(snap() == s4, "with no record: the views and the screen changed nothing, the random stream included")
	C.nemActive()
	check(C.RUN["nems"].has(fac) and snap() != s4, "the campaign's own nemActive does build the record on that state: a reader that called it would fail the two rows above")

	check(fleet_coverage.has("battle") and fleet_coverage.has("elite") and fleet_coverage.has("boss") and fleet_coverage.has("rival"), "fleet checks covered ordinary, elite, capital and rival encounters")
	var seen_regions := {}
	for seed_value in range(1, 101):
		fresh(seed_value)
		var region = str(C.RUN["map"]["region"])
		if seen_regions.has(region): continue
		var unchanged = snap()
		await read_screen()
		var scenery = ui.map3d.region_scenery
		check(snap() == unchanged, region + ": region scenery and emblem leave the run, saves and random streams unchanged")
		check(scenery != null and scenery.get_meta("region") == region and scenery.get_meta("scenery") == ui.map3d.System.REGION_SCENERY[region], region + ": generated region selects its actual scenery")
		var emblem = ui._rail_host.find_child("RegionEmblem", true, false)
		check(emblem != null and emblem.get_meta("region") == region and ui.GS.REGION_EMBLEMS.has(region), region + ": matching emblem is built on the rail")
		ui._open_overlay("key"); await frames(2)
		var key_emblems = ui.find_children("RegionEmblem", "Control", true, false)
		check(key_emblems.size() == 2 and key_emblems.all(func(e): return e.get_meta("region") == region), region + ": Map key uses the same emblem")
		ui._close_overlay()
		var parts = ui.map3d._parts(scenery)
		check(parts["vis"].all(func(v): return v.layers == ui.map3d.LAYER_SCENERY) and parts["lights"].all(func(l): return l[0].light_cull_mask == ui.map3d.LAYER_SCENERY), region + ": scenery lighting is isolated from the stops")
		var landmark = scenery.get_node("Landmark"); var built := false
		match region:
			"boneyard":
				var wrecks: Array = []; var factions := {}; var classes := {}; var broken := 0
				for grave in landmark.get_children():
					for body in grave.get_children():
						if not body.has_meta("wreck"): continue
						var wreck = body.get_meta("wreck"); wrecks.append(float(wreck["length"]))
						factions[wreck["fac"]] = true; classes[wreck["cls"]] = true
						if wreck["split"] and body.get_child_count() >= 8: broken += 1
				wrecks.sort()
				built = wrecks.size() >= 8 and wrecks.size() <= 12 and factions.size() >= 2 and classes.size() >= 3 and broken >= 2 and wrecks[-1] <= wrecks[-2] * 2.0
			"nebula": built = parts["vis"].size() >= 20 and landmark.get_child_count() >= 4
			"world": built = landmark.has_node("body/spin") and landmark.get_child_count() == 4 and landmark.get_node("body/spin").mesh.radius > 10 and not landmark.get_node("body/spin").material_override.shader.code.contains("abs(p.y)")
			"frontier": built = landmark.get_child(0).material_override.shader.code.contains("discard") and landmark.get_child(0).mesh.surface_get_array_index_len(0) >= 20480 * 3 and scenery.get_child_count() >= 15
			"deep": built = not landmark.visible and scenery.get_child_count() == 5 and is_zero_approx(ui.map3d.env.sky.sky_material.get_shader_parameter("neb_gain")) and ui.map3d.props.blinkers.any(func(b): return is_equal_approx(b[2], 7.0))
		check(built, region + ": the expected landmark and dressing were actually built")
		seen_regions[region] = true
		if seen_regions.size() == C.REGIONS.size(): break
	check(seen_regions.size() == 5 and C.REGIONS.keys().all(func(key): return ui.GS.REGION_EMBLEMS.has(key) and ui.map3d.System.REGION_SCENERY.has(key)), "every live region has scenery and an emblem")
	for l in lines: print(l)
	print("Map read-only: " + ("PASS" if fails == 0 else "FAIL (%d)" % fails) + " (%d checks)" % lines.size())
	ui.queue_free(); await process_frame
	quit(0 if fails == 0 else 1)
