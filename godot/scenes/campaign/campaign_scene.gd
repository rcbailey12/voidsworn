extends Node
# The campaign on its own (G3): title to the end of a run with test battles, for playing and checking the campaign screens
# before the battle scene is wired in. The game shell (godot/main/) builds the same two objects and handles the battle page.
#
# Command-line modes (after "--"):
#   shots <dir>     plays a scripted run and saves a screenshot of every campaign screen into <dir> (needs a real renderer)
#   mapshots <dir>  the sector map only, at fixed angles, for before/after sets (R51): the start of a run, a hover card,
#                   a closer view and low quality (when the map has them), and the start of sector II
#   bot <runs>      plays <runs> whole runs through the screens with the parity bot and quits; exit code 1 on any problem
#   rollout <dir>   issue #344 (UI rollout 1, Lime Tactical): plays one seeded run through the campaign's own actions and
#                   saves every campaign-map and between-battle page by name (see _rollout); add --no-tips for clean shots

const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")   # the rules are reached only through the battle API (rules/API.md)
const JSM = BattleAPI.JSM   # the shared JS maths and the one PRNG the rules and the campaign both draw from

var C
var ui

func _ready() -> void:
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		push_error(err); get_tree().quit(1); return
	var a := OS.get_cmdline_user_args()
	if ResourceLoader.exists("res://story/story.gd"):   # the story layer (godot/story/README.md), as the game shell attaches it
		var story = load("res://story/story.gd").new(); story.name = "Story"; add_child(story)
		story.attach(C, a.is_empty())   # test modes keep the career in memory only
	ui = UIScript.new(); add_child(ui); ui.bind(C)
	if a.size() >= 2 and a[0] == "shots":
		C.save_path = "user://campaign_shots_save.json"; _shots(a[1]); return
	if a.size() >= 2 and a[0] == "mapshots":
		C.save_path = "user://campaign_shots_save.json"; _mapshots(a[1]); return
	if a.size() >= 2 and a[0] == "rollout":
		C.save_path = "user://ui344_rollout_save.json"; _rollout(a[1]); return
	if a.size() >= 2 and a[0] == "bot":
		C.save_path = "user://campaign_bot_save.json"; _bot(int(a[1])); return
	JSM.rnd_seed(int(Time.get_unix_time_from_system()) & 0xFFFFFFFF)   # the browser seeds its PRNG at random on load
	C.persist_on = true; C.persist_load()
	C.titleScreen()

func _close_story_dialogs() -> void:   # the story's own prompts (Name your flagship) sit over the map in test shots
	var st = get_node_or_null("Story")
	if st != null and st.get("_ui_layer") != null and is_instance_valid(st._ui_layer):
		for ch in st._ui_layer.get_children(): ch.queue_free()
func _frames(n: int = 3) -> void:
	for i in range(n): await get_tree().process_frame
func _shot(dir: String, name: String) -> void:
	await _frames(4)
	if C.page.get("kind") == "map" and ui.use_3d_map: await get_tree().create_timer(2.2).timeout   # the 3D map's arrival camera settles first
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(name + ".png")); print("shot ", name)

# A scripted run that visits every screen kind once and saves a picture of each.
func _shots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	JSM.rnd_seed(4242)
	var M = C.META
	M["renown"] = 95; M["stats"]["runs"] = 6; M["stats"]["best"] = 3; M["stats"]["wins"] = 1; M["stats"]["wonFacs"] = ["voidsworn"]
	M["mastery"]["vex"] = 34; M["favour"]["iron"] = 13; M["favour"]["storm"] = 5
	M["fallen"] = [{"name": "Casimir Holloway", "rank": 2, "fac": "voidsworn", "ship": "Banked Fire", "sector": 2}]
	C.titleScreen(); await _shot(dir, "01_title")
	C.act("legacy"); await _shot(dir, "02_progression")
	C.act("progTab", "favour"); await _shot(dir, "03_progression_favour")
	C.act("title"); C.act("newRunScreen"); await _shot(dir, "04_admiral")
	C.act("optHeat", "h_flag"); C.act("startRun"); await _shot(dir, "05_aspect")
	C.act("pickAspect", C.W["aspOffer"][0]); await _shot(dir, "06_intro")
	C.act("closeModal"); await _frames(2); _close_story_dialogs(); await _shot(dir, "07_map")
	if ui.use_3d_map:   # the hover card over a fight in the middle of the sector (danger, what moved it, the routes through it)
		var m = ui.map3d; var mid = C.RUN["map"]["cols"][min(3, C.RUN["map"]["cols"].size() - 2)][0]["id"]
		get_viewport().warp_mouse(m._screen(m._nodes[mid]["pos"])); await _frames(3); m._set_hot(mid); await _frames(6)
		await _shot(dir, "07b_map_hover"); m._set_hot("")
	var seen = {}; var steps = 0
	while not C.ended and steps < 400:
		steps += 1
		var kind = C.modal_d["kind"] if C.modal_d != null else C.page["kind"]
		if not seen.has(kind):
			seen[kind] = true; await _shot(dir, "%02d_%s" % [7 + seen.size(), kind])
		var acts = C.screen_acts().filter(func(x): return x[2] == 1)
		var pick = _shots_pick(kind, acts, seen)
		if pick == null: break
		C.act(pick[0], pick[1]); await _frames(1)
	await _shot(dir, "99_end")
	get_tree().quit(0)
func _mapshots(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	JSM.rnd_seed(4242)
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal")
	await _frames(2); _close_story_dialogs()
	await _shot(dir, "m1_map")
	var m = ui.map3d
	var mid = C.RUN["map"]["cols"][min(3, C.RUN["map"]["cols"].size() - 2)][0]["id"]
	get_viewport().warp_mouse(m._screen(m._nodes[mid]["pos"])); await _frames(3); m._set_hot(mid); await _frames(6)
	await _shot(dir, "m2_hover"); m._set_hot("")
	if m.has_method("zoom_by"):
		m.zoom_by(0.55, m._screen(m._nodes[C.page["data"]["avail"][0]]["pos"])); await get_tree().create_timer(1.5).timeout
		await _shot(dir, "m3_zoom"); m.reset_view(); await get_tree().create_timer(1.2).timeout
		m.zoom_by(0.5, m._screen(m._nodes[mid]["pos"])); await get_tree().create_timer(1.5).timeout   # zoomed on the middle of the sector
		await _shot(dir, "m3b_zoom_mid"); m.reset_view(); await get_tree().create_timer(1.2).timeout
	if ui.has_method("set_map_quality"):
		var q0 = ui.map_quality; ui.set_map_quality("low"); await _frames(4)
		await _shot(dir, "m4_low"); ui.set_map_quality(q0); await _frames(4)
	var seen = {"fleet": true, "retreat": true, "sell": true}; var steps = 0
	while not C.ended and steps < 600 and int(C.RUN["sector"]) < 2:
		steps += 1
		var kind = C.modal_d["kind"] if C.modal_d != null else C.page["kind"]
		var acts = C.screen_acts().filter(func(x): return x[2] == 1)
		var pick = _shots_pick(kind, acts, seen)
		if pick == null: break
		C.act(pick[0], pick[1]); await _frames(1)
	while C.modal_d != null and steps < 650:
		steps += 1; var acts2 = C.screen_acts().filter(func(x): return x[2] == 1)
		if acts2.is_empty(): break
		C.act(acts2[0][0], acts2[0][1]); await _frames(1)
	await _frames(2); _close_story_dialogs()
	if C.page["kind"] == "map": await _shot(dir, "m5_sector2")
	get_tree().quit(0)
func _shots_pick(kind: String, acts: Array, seen: Dictionary):
	var want = {"event": "event", "drydock": "drydock", "shipyard": "shipyard", "field": "field"}
	var has = func(name, arg = null):
		for x in acts:
			if x[0] == name and (arg == null or x[1] == arg): return x
		return null
	match kind:
		"map":
			if not seen.has("fleet") and has.call("fleetScreen") != null: return has.call("fleetScreen")
			for x in acts:   # prefer a node of a kind not pictured yet
				if x[0] == "enterNode":
					var t = C.findNode(x[1])["type"]
					if want.has(t) and not seen.has(want[t]): return x
			return has.call("enterNode")
		"fleet":
			return has.call("equip") if has.call("equip") != null else (has.call("backMap") if has.call("backMap") != null else has.call("backShipyard"))
		"shipyard":
			if not seen.has("sell") and has.call("sellShip") != null: return has.call("sellShip")
			for n in ["buyMod", "repairAll", "buyHull"]:
				if has.call(n) != null and randi() % 3 > 0: return has.call(n)
			return has.call("leaveYard")
		"sell": return has.call("closeModal")
		"battle":
			if not seen.has("retreat") and has.call("c3retreat") != null: return has.call("c3retreat")
			var lose = int(C.RUN["sector"]) >= 3 and C.RUN["fleet"].size() > 0 and seen.has("sector")
			return has.call("battle", "loss" if lose else "win")
		"retreat": return has.call("c3retreatNo")
		"prize": return has.call("prizeConfirm")
	return acts[0] if acts.size() > 0 else null

# Whole runs through the screens with the parity bot (the UI renders every step), for script errors and dead ends.
func _bot(runs: int) -> void:
	const STAY = ["closeModal", "buyHull", "buyMod", "repair", "repairAll", "upgradeMk", "sellShip", "sellConfirm", "yardFleet", "equip", "unequip", "promote", "fleetScreen", "pickFaction", "pickAdmiral", "optAlt", "optCmd", "optHeat", "progTab", "buyVariant", "c3retreat", "c3retreatNo"]
	var bad = 0
	for r in range(runs):
		var seed = 1000 + r
		JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.SAVED_RUN = null; C.ended = false
		var s = seed; var streak = 0
		C.titleScreen()
		var steps = 0
		while not C.ended and steps < 4000:
			steps += 1
			var acts = C.screen_acts().filter(func(x): return x[2] == 1 and not (x[0] in ["legacy", "help", "saveQuit", "title", "abandonRun"]))
			if streak >= 8:
				var go = acts.filter(func(x): return not (x[0] in STAY))
				if go.size() > 0: acts = go
			if acts.is_empty(): break
			s = (s * 1103515245 + 12345) % 2147483648
			var x = acts[(s >> 16) % acts.size()]
			if x[0] == "battle": x = ["battle", "loss" if (s >> 16) % 25 == 0 else "win", 1]
			streak = streak + 1 if x[0] in STAY else 0
			C.act(x[0], x[1])
			if steps % 20 == 0: await _frames(1)
		print("run %d: %d steps, %s" % [r + 1, steps, "ended" if C.ended else "DID NOT END"])
		if not C.ended: bad += 1
	get_tree().quit(1 if bad > 0 else 0)

# ---------------- issue #344: the UI rollout 1 captures ----------------
# Every page is reached by playing: the run starts from the title through the campaign's own actions (newRunScreen,
# startRun, pickAspect), moves on the map with enterNode, fights with the campaign's battle actions (the stub battle's
# win, the same path the parity bot takes) and answers each dialog with its own buttons. Nothing types a page state.
# The driver prefers stops of a kind it has not pictured yet, so one seeded run shows every page. Files (<dir>/<name>.png):
#   01_map (the campaign map as the player sees it), 01b_map_hover, 01c_side_panel (crop), 02_intro, 03_map_elite_card,
#   04_map_boss_card, 05_battle_retreat, 06_reward_victory, 07_reward_<boon|mod|relic|prize|salvage>, 08_shipyard,
#   09_fleet, 10_event, 11_event_result, 12_drydock, 13_promote, 14_sector (with the Nemesis adaptation when one is told),
#   15_map_sector2. reached.txt lists what was reached, and what was not (a page this seed's run never offers).
var _ro_dir := ""
var _ro_seen := {}
var _ro_log: Array = []
func _ro_shot(name: String, crop_side := false) -> void:
	_close_story_dialogs()
	await _frames(4)
	var t0 = Time.get_ticks_msec()   # the map draws under a "Preparing the sector" cover (main/load_screen.gd) until its sky is baked
	while _ro_covered(get_tree().root) and Time.get_ticks_msec() - t0 < 420000: await get_tree().process_frame
	_close_story_dialogs()   # the story layer's own prompts (Name your flagship) open once the cover lifts
	for t in ui.toast_box.get_children(): t.queue_free()   # news toasts from the step before fade in seconds; they would cover the page
	await _frames(2)
	if C.page.get("kind") == "map" and C.modal_d == null and ui.use_3d_map: await get_tree().create_timer(2.4).timeout   # the arrival camera settles
	await _frames(2)
	_ro_log.append("%s  page=%s modal=%s sector=%s" % [name, C.page.get("kind"), (C.modal_d["kind"] if C.modal_d != null else "-"), str(C.RUN.get("sector")) if C.RUN != null else "-"])
	if DisplayServer.get_name() == "headless":   # a smoke run in the cloud: the page builds, there is nothing to draw
		print("built ", name); return
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	img.save_png(_ro_dir.path_join(name + ".png")); print("shot ", name)
	if crop_side:
		var host = _ro_find_shell()
		if host != null:
			var r = Rect2i(Vector2i(host.global_position), Vector2i(host.size)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			if r.size.x > 0 and r.size.y > 0: img.get_region(r).save_png(_ro_dir.path_join(name.replace("01_map", "01c_side_panel") + ".png"))
func _ro_covered(n: Node) -> bool:
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("load_screen.gd") and (not (n is CanvasItem) or n.visible): return true
	for ch in n.get_children():
		if _ro_covered(ch): return true
	return false
func _ro_find_shell() -> Control:   # the map's side panel: the widest shell panel at the right edge
	var best: Control = null
	for n in _ro_all(ui):
		if n is PanelContainer and n.custom_minimum_size.x > 0 and n.is_visible_in_tree() and n.get_global_rect().end.x > get_viewport().get_visible_rect().size.x - 40:
			if best == null or n.size.y > best.size.y: best = n
	return best
func _ro_all(n: Node) -> Array:
	var out = [n]
	for ch in n.get_children(): out.append_array(_ro_all(ch))
	return out
func _ro_kind() -> String: return C.modal_d["kind"] if C.modal_d != null else str(C.page["kind"])
func _ro_has(acts: Array, name: String, arg = null):
	for x in acts:
		if x[0] == name and (arg == null or x[1] == str(arg)): return x
	return null
func _ro_avail_types() -> Array:
	var out = []
	if C.page.get("kind") != "map": return out
	for id in C.page["data"]["avail"]:
		var n = C.findNode(id)
		if n != null: out.append(str(n["type"]))
	return out
func _rollout(dir: String) -> void:
	_ro_dir = dir; DirAccess.make_dir_recursive_absolute(dir)
	# the project opens maximised (window/size/mode 2), which ignores --resolution: --win WxH sets the window to that exact size
	var a := OS.get_cmdline_user_args(); var wi = a.find("--win")
	if wi >= 0 and wi + 1 < a.size() and DisplayServer.get_name() != "headless":
		var wh = a[wi + 1].split("x")
		if wh.size() == 2:
			var win = get_window(); win.mode = Window.MODE_WINDOWED; win.size = Vector2i(int(wh[0]), int(wh[1])); win.position = Vector2i(0, 0)
			await _frames(20)
	JSM.rnd_seed(344)
	C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
	if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
	if _ro_kind() == "intro": await _ro_shot("02_intro"); _ro_seen["intro"] = true
	C.act("closeModal"); await _frames(2)
	await _ro_shot("01_map", true)
	if ui.use_3d_map:   # the hover card over a fight you can take
		var m = ui.map3d; var tgt = ""
		for id in C.page["data"]["avail"]:
			if C.findNode(id)["type"] in ["battle", "elite"]: tgt = id; break
		if tgt == "": tgt = C.page["data"]["avail"][0]
		get_viewport().warp_mouse(m._screen(m._nodes[tgt]["pos"])); await _frames(3); m._set_hot(tgt); await _frames(6)
		await _ro_shot("01b_map_hover"); m._set_hot("")
	var steps = 0
	var names = {"victory": "06_reward_victory", "boon": "07_reward_boon", "mod": "07_reward_mod", "relic": "07_reward_relic", "prize": "07_reward_prize",
		"salvage": "07_reward_salvage", "shipyard": "08_shipyard", "fleet": "09_fleet", "event": "10_event", "event_result": "11_event_result",
		"drydock": "12_drydock", "promote": "13_promote", "sector": "14_sector", "retreat": "05_battle_retreat"}
	while not C.ended and steps < 900:
		steps += 1
		var kind = _ro_kind()
		if C.RUN != null and int(C.RUN["sector"]) >= 2 and kind == "map":
			await _ro_shot("15_map_sector2"); break
		if kind == "map":
			var ty = _ro_avail_types()
			if not _ro_seen.has("elite_card") and ty.has("elite"): _ro_seen["elite_card"] = true; await _ro_shot("03_map_elite_card")
			if not _ro_seen.has("boss_card") and ty.has("boss"): _ro_seen["boss_card"] = true; await _ro_shot("04_map_boss_card")
		elif names.has(kind) and not _ro_seen.has(kind):
			_ro_seen[kind] = true; await _ro_shot(names[kind])
		var acts = C.screen_acts().filter(func(x): return x[2] == 1)
		var pick = _ro_pick(kind, acts)
		if pick == null: _ro_log.append("stuck on " + kind); break
		C.act(pick[0], pick[1]); await _frames(1)
	var want = ["01_map", "01b_map_hover", "02_intro", "03_map_elite_card", "04_map_boss_card", "05_battle_retreat", "06_reward_victory", "08_shipyard", "09_fleet", "10_event", "11_event_result", "14_sector", "15_map_sector2"]
	var got = _ro_log.map(func(l): return l.split(" ")[0])
	var missing = want.filter(func(w): return not got.has(w))
	var f = FileAccess.open(dir.path_join("reached.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string("seed 344, %d steps, window %s\n" % [steps, str(get_viewport().get_visible_rect().size)] + "\n".join(PackedStringArray(_ro_log)) + "\nnot reached: " + (", ".join(PackedStringArray(missing)) if missing.size() > 0 else "none") + "\n")
		f.close()
	print("rollout: ", _ro_log.size(), " pages; not reached: ", missing)
	get_tree().quit(0)
func _ro_pick(kind: String, acts: Array):
	var want = ["elite", "event", "shipyard", "drydock", "battle", "field", "boss"]
	match kind:
		"map":
			if not _ro_seen.has("fleet") and _ro_has(acts, "fleetScreen") != null: return _ro_has(acts, "fleetScreen")
			var best = null; var bi = 99
			for x in acts:
				if x[0] != "enterNode": continue
				var t = str(C.findNode(x[1])["type"]); var i = want.find(t)
				if t in ["event", "shipyard", "drydock", "elite"] and _ro_seen.has(t if t != "elite" else "elite_fought"): i += 10
				if i >= 0 and i < bi: bi = i; best = x
			if best != null and C.findNode(best[1])["type"] == "elite": _ro_seen["elite_fought"] = true
			return best if best != null else _ro_has(acts, "enterNode")
		"fleet":
			return _ro_has(acts, "backMap") if _ro_has(acts, "backMap") != null else _ro_has(acts, "backShipyard")
		"shipyard":
			if not _ro_seen.has("fleet") and _ro_has(acts, "yardFleet") != null: return _ro_has(acts, "yardFleet")
			return _ro_has(acts, "leaveYard")
		"battle":
			if not _ro_seen.has("retreat") and _ro_has(acts, "c3retreat") != null: return _ro_has(acts, "c3retreat")
			return _ro_has(acts, "battle", "win")
		"retreat": return _ro_has(acts, "c3retreatNo")
		"prize": return _ro_has(acts, "prizeConfirm")
		"boon":
			var t = _ro_has(acts, "takeBoon"); return t if t != null else acts[0]
		"sell", "abandon": return _ro_has(acts, "closeModal")
	return acts[0] if acts.size() > 0 else null

