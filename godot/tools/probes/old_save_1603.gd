extends SceneTree
# Issue 1603: does a campaign saved before PR 1579 (the issue 1551 story text) still resume after it? Two modes, one file, so
# the same code runs on both pins:
#   make   <folder>                  on the commit BEFORE the merge: writes four real campaign saves, each its own file
#                                    <folder>/<case>/campaign.json (the game's own persist_save, atomic, with its .bak), and
#                                    <folder>/old_cases.json with what the old build showed (event title, credits, ships).
#   resume <folder> [<pictures>]     on the commit AFTER the merge: loads each file cold, as Continue does (persist_load,
#                                    titleScreen, continueRun), and checks it resumes where it was saved, with nothing
#                                    dropped as "no longer in the game", the same run (credits, sector, ships), and the new
#                                    words on screen. With a window it saves RESUME-1603_<case>.png for the three pages.
# The cases: map (Sector II map with a repair stop: must now read "Repair dock"), event (a Hullbreakers run standing on the
# derelict event: the card must show the new 1551 title, not the old one), yard (a Chorus run inside a shipyard: the repair
# line must name biomass and a fresh spawn-mind) and battle (a Sunward run saved at round 2 of a fight: either the round save
# resumes at round 2 and plays on, or, because the rules changed, it is set aside with the game's own "The game was updated"
# notice and the run goes back to its checkpoint; both are fine, an error is not).
#   godot --headless --path godot --script res://tools/probes/old_save_1603.gd -- make <folder>
#   godot --path godot --rendering-method forward_plus --windowed --resolution 1920x1080 --script res://tools/probes/old_save_1603.gd -- resume <folder> <pictures> [<commit>]
# Prints OLD_SAVE_1603 PASS or OLD_SAVE_1603 FAIL <n>, writes <folder>/old_save_<mode>.txt, exits 0 only on PASS.
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")

const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
const CASES := ["map", "event", "yard", "battle"]
const OLD_ARC := ["Port broadside", "Starboard broadside", "Prow ", " Rear "]   # ARC_NAME before PR 1579 (display words)

var api = null
var fails := 0
var report: PackedStringArray = []
var folder := ""
var mode := ""
var completed := false   # set at the end of make or resume: a script error part way never reads as a pass

func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api = API.new(); api.load_rules(); api.set_ai_level("veteran"); api.round_saves = true
	api.new_battle(run, cfg)
	return api.R.B

func _restore(sb: Dictionary) -> Dictionary:   # campaign_host.gd _restore_battle, without the scene
	var a = API.new()
	var e: String = a.load_rules()
	if e != "": return {"error": "rules: " + e}
	var why: String = a.restore_round(Marshalls.base64_to_raw(str(sb.get("data", ""))), int(sb.get("size", 0)), str(sb.get("fp", "")))
	if why != "": return {"error": why}
	a.round_saves = true; api = a
	return {"B": a.R.B, "run": a.R.RUN}

func _fresh(path: String):
	var C = Campaign.new()
	var err: String = C.load_tables()
	if err != "": _bad("campaign tables: " + err)
	C.fixed_clock = true; C.persist_on = true; C.save_path = path
	C.battle_mode = "external"; C.battle_setup = _setup; C.battle_restore = _restore
	return C

func _path(c: String) -> String: return folder.path_join(c).path_join("campaign.json")

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var a := OS.get_cmdline_user_args()
	mode = a[0] if a.size() > 0 else ""
	folder = a[1] if a.size() > 1 else ""
	if folder == "" or not (mode in ["make", "resume"]): _done("usage: -- make <folder> | resume <folder> [<pictures>] [<commit>]"); return
	if mode == "make": _make()
	else: await _resume(a[2] if a.size() > 2 else "", a[3] if a.size() > 3 else "")
	_done("" if completed else mode + " stopped part way (a script error above?)")

# ---------------------------------------------------------------- make (old pin)

func _make() -> void:
	var facts := {}
	for c in CASES:
		if DirAccess.make_dir_recursive_absolute(folder.path_join(c)) != OK: _bad("cannot create " + folder.path_join(c)); return
		if FileAccess.file_exists(_path(c)): _bad(c + ": a save is already there; every attempt starts in a new folder"); return
	# map: Sector II, one stop turned into a repair stop
	var C = _fresh(_path("map"))
	API.JSM.rnd_seed(16031); C.META = C.defaultMeta(); C.newRun("vex", "voidsworn", {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null
	var dock = C.RUN["map"]["cols"][1][0]; dock["type"] = "drydock"
	C.mapScreen(); C.saveRun()
	facts["map"] = _facts(C, {"dock": str(dock["id"])})
	# event: a Hullbreakers run standing on the derelict event
	C = _fresh(_path("event"))
	API.JSM.rnd_seed(16032); C.META = C.defaultMeta()
	var adm := _admiral("corsair", C)
	C.META["admirals"][adm] = true
	C.newRun(adm, "corsair", {})
	var n = C.RUN["map"]["cols"][0][0]; n["type"] = "event"; n.erase("done")
	C.RUN["pos"] = n["id"]; C.RUN["curNode"] = n["id"]; C.RUN["flags"] = {}
	if not (C.RUN.get("seenEvents") is Array): C.RUN["seenEvents"] = []
	C.RUN["seenEvents"].append("derelict")
	var ev = C._event_for_faction(C.EVENTS.filter(func(e): return e["id"] == "derelict")[0])
	C.show_event(ev); C.saveRun()
	facts["event"] = _facts(C, {"event": "derelict", "title": str(ev.get("t", "")), "body": str(ev.get("b", ""))})
	# yard: a Chorus run inside a shipyard
	C = _fresh(_path("yard"))
	API.JSM.rnd_seed(16033); C.META = C.defaultMeta()
	adm = _admiral("chorus", C)
	C.META["admirals"][adm] = true
	C.newRun(adm, "chorus", {})
	C.RUN["credits"] = 400.0
	n = C.RUN["map"]["cols"][0][0]; n["type"] = "shipyard"; n.erase("stock"); n.erase("done")
	C.RUN["pos"] = n["id"]; C.RUN["curNode"] = n["id"]
	C.shipyardScreen(n); C.saveRun()
	facts["yard"] = _facts(C, {"in_yard": C.saved_in_yard})
	# battle: round 2 of a Sector I fight
	C = _fresh(_path("battle"))
	API.JSM.rnd_seed(16034); C.META = C.defaultMeta(); C.newRun("vex", "voidsworn", {})
	for i in 2: C.RUN["fleet"].append(C.newShip(C.cheapHull("voidsworn")))
	var node = null
	for col in C.RUN["map"]["cols"]:
		for x in col:
			if node == null and x["type"] == "battle": node = x
	if node == null: _bad("battle: no battle stop on the Sector I map"); return
	C.RUN["pos"] = node["id"]; C.RUN["curNode"] = node["id"]; C.saveRun()
	C._enter_battle_node(node)
	_play_to(C, 2)
	if not (api != null and api.phase == "player" and api.round_snap_round == 2): _bad("battle: the fight did not reach round 2"); return
	if C.save_battle_round(api.take_round_snapshot()) != true: _bad("battle: the round 2 save was not written"); return
	facts["battle"] = _facts(C, {"round": 2, "log": api.R.B.get("log", []).size()})
	for c in CASES:
		if not FileAccess.file_exists(_path(c)): _bad(c + ": no save file written")
		else: _line("made %s: %s (%d bytes)" % [c, _path(c), FileAccess.get_file_as_string(_path(c)).length()])
	var f := FileAccess.open(folder.path_join("old_cases.json"), FileAccess.WRITE)
	if f == null: _bad("cannot write old_cases.json"); return
	f.store_string(JSON.stringify(facts, "  ")); f.close()
	completed = true

func _admiral(fac: String, C) -> String:
	for id in C.ADMIRALS.keys():
		if str(C.ADMIRALS[id].get("fac", "")) == fac: return str(id)
	return ""

func _facts(C, extra: Dictionary) -> Dictionary:
	var r = C.SAVED_RUN if C.SAVED_RUN != null else C.RUN
	var o := {"fac": str(r["fac"]), "sector": int(r["sector"]), "credits": float(r["credits"]), "pos": str(r.get("pos")),
		"page": str(C.page.get("kind")), "ships": r["fleet"].map(func(s): return str(s["uid"]) + " " + str(s["tpl"]) + " " + str(s["name"]))}
	o.merge(extra)
	return o

func _play_to(C, rnd: int) -> void:
	var g := 0
	while not (api.phase == "player" and api.round_snap_round >= rnd) and api.phase != "over" and g < 5000:
		g += 1
		if api.phase == "player":
			var me = null
			for u in api.view()["units"]:
				if u["side"] == "player" and not u["dead"] and not u["activated"] and not u["squadron"]:
					me = u; break
			if me == null: api.end_activation(); continue
			var r0 = int(api.R.B["round"])
			api.ai_activate(me["id"])
			if api.phase == "player" and int(api.R.B["round"]) == r0 and api.unit(me["id"]) != null and not C.jt(api.unit(me["id"]).get("activated")): api.end_activation(me["id"])
			api.take_events()
		else: api.step()

# ---------------------------------------------------------------- resume (new pin)

func _resume(pics: String, commit: String) -> void:
	var facts = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("old_cases.json")))
	if not (facts is Dictionary): _bad("no old_cases.json in " + folder + " (did the make step run?)"); return
	var headless := DisplayServer.get_name() == "headless"
	if pics != "" and not headless:
		DirAccess.make_dir_recursive_absolute(pics)
		root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
	for c in CASES:
		var old: Dictionary = facts.get(c, {})
		if old.is_empty(): _bad(c + ": the old build wrote no facts"); continue
		if not Campaign.has_saved_run(_path(c)): _bad(c + ": the save file holds no run the new build can read"); continue
		api = null
		var D = _fresh(_path(c))
		D.persist_load(); D.titleScreen()
		if D.SAVED_RUN == null: _bad(c + ": the title offers no Continue"); continue
		D.toasts.clear()
		D.act("continueRun")
		var toasts: Array = D.toasts.duplicate()
		for t in toasts: _line("  %s notice: %s" % [c, str(t)])
		if toasts.any(func(t): return str(t).contains("no longer in the game")): _bad(c + ": the save lost something as no longer in the game")
		if D.RUN == null: _bad(c + ": Continue left no run"); continue
		var kind := str(D.page.get("kind"))
		_line("%s: resumed on page %s%s" % [c, kind, (" with " + str(D.modal_d["kind"]) + " open") if D.modal_d != null else ""])
		if true:   # the same run in every case, the battle too (Artoo on PR 1837): faction, sector, credits and every ship
			if str(D.RUN["fac"]) != old["fac"] or int(D.RUN["sector"]) != int(old["sector"]) or float(D.RUN["credits"]) != float(old["credits"]):
				_bad(c + ": a different run came back: %s sector %d credits %s (saved %s sector %d credits %s)" % [D.RUN["fac"], int(D.RUN["sector"]), str(D.RUN["credits"]), old["fac"], int(old["sector"]), str(old["credits"])])
			var ships = D.RUN["fleet"].map(func(s): return str(s["uid"]) + " " + str(s["tpl"]) + " " + str(s["name"]))
			if ships != old["ships"]: _bad(c + ": the fleet changed: " + str(ships) + " (saved " + str(old["ships"]) + ")")
		match c:
			"map":
				if kind != "map": _bad("map: resumed on " + kind + ", not the map")
				var dock = D.findNode(old["dock"])
				var word := str(preload("res://campaign/campaign_view.gd").stop(D, dock).get("kind_word", "")) if dock != null else ""
				if word != "Repair dock": _bad("map: the repair stop reads \"" + word + "\", not the new \"Repair dock\"")
				else: _line("map: the repair stop now reads \"Repair dock\"")
			"event":
				var now = D.cur_event if D.modal_d != null and str(D.modal_d.get("kind")) == "event" else null
				if now == null: _bad("event: the derelict event card did not come back"); continue
				var want = D._event_for_faction(D.EVENTS.filter(func(e): return e["id"] == "derelict")[0])
				if str(now.get("t")) != str(want.get("t")): _bad("event: the card shows \"" + str(now.get("t")) + "\", not the new table's \"" + str(want.get("t")) + "\"")
				elif str(now.get("t")) == str(old["title"]): _bad("event: the card still shows the old title \"" + str(old["title"]) + "\"")
				else: _line("event: the card shows the new title \"%s\" (was \"%s\")" % [now.get("t"), old["title"]])
			"yard":
				if kind != "shipyard": _bad("yard: resumed on " + kind + ", not inside the shipyard")
				else:   # the resumed page itself must carry the 1551 Chorus repair line (Artoo on PR 1837)
					var line := _yard_line(D)
					if not (line.contains("biomass") and line.contains("fresh spawn-mind")): _bad("yard: the resumed shipyard's repair line reads \"" + line + "\", not biomass and a fresh spawn-mind")
					else: _line("yard: the resumed shipyard reads \"" + line + "\"")
			"battle":
				var set_aside: bool = toasts.any(func(t): return str(t).contains("The game was updated"))
				if set_aside: _line("battle: the round save was set aside because the rules changed (the game's own notice); the run went back to its checkpoint, page " + kind)
				# both arms must end in a live fight that plays on: the notice alone never passes (Artoo on PR 1837)
				if D.pending_battle == null or api == null:
					_bad("battle: no fight came back (%s, page %s)" % ["notice shown, but the checkpoint fight was not re-entered" if set_aside else "no round save and no notice", kind])
				else:
					var r := int(api.R.B["round"])
					if set_aside and r != 1: _bad("battle: the checkpoint fight starts at round %d, not 1" % r)
					elif set_aside: _line("battle: the fight starts again from its checkpoint at round 1")
					elif r != 2: _bad("battle: the round save resumed at round %d, not 2" % r)
					else: _line("battle: the round 2 save resumed at round 2")
					var before: int = api.R.B.get("log", []).size()
					_play_to(D, int(api.R.B["round"]) + 1)
					var newer: Array = api.R.B.get("log", []).slice(before)
					if newer.is_empty(): _bad("battle: no new log lines after resuming")
					var stale := []
					for e in newer:
						for w in OLD_ARC:
							if str(e.get("m", "")).contains(w): stale.append(str(e.get("m", "")))
					if not stale.is_empty(): _bad("battle: new log lines use the old arc names: " + str(stale.slice(0, 3)))
					if int(api.R.B["round"]) <= r and api.phase != "over": _bad("battle: the fight did not advance past round %d" % r)
					_line("battle: played on to round %d, %d new log lines, none with the old arc names" % [int(api.R.B["round"]), newer.size()])
		if pics != "" and not headless and c != "battle": await _picture(D, c, commit)
	completed = true

# the shipyard page the game builds for the resumed run: its "Repairs cost" line
func _yard_line(D) -> String:
	var ui = preload("res://ui/campaign/campaign_ui.gd").new()
	root.add_child(ui); ui.C = D
	ui.teaching = preload("res://ui/campaign/campaign_tips.gd").new(); ui.teaching.disabled = true; ui.add_child(ui.teaching)
	ui.set_process(false); ui.use_3d_map = false
	ui.map3d.intel = preload("res://ui/campaign/map_intel.gd").new(D)
	var page: Control = ui._shipyard()
	var found := ""
	for l in page.find_children("*", "Label", true, false) + page.find_children("*", "RichTextLabel", true, false):
		if str(l.text).begins_with("Repairs cost "): found = str(l.text); break
	page.free(); ui.queue_free()
	return found

func _picture(D, c: String, commit: String) -> void:
	var UI = preload("res://ui/campaign/campaign_ui.gd")
	var ui = UI.new()
	root.add_child(ui)
	ui.C = D
	ui.teaching = preload("res://ui/campaign/campaign_tips.gd").new(); ui.teaching.disabled = true; ui.add_child(ui.teaching)
	ui.set_process(false); ui.use_3d_map = false
	ui.map3d.intel = preload("res://ui/campaign/map_intel.gd").new(D)
	ui.render()
	for i in range(4): await process_frame
	var cap := CanvasLayer.new(); cap.layer = 120
	var l := Label.new()
	l.text = "RESUME-1603_" + c + "   a save made before PR 1579 (9cf8f12b), resumed on " + commit.substr(0, 8) + "   Normal text   PC, pinned checkout"
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", Color(1, 1, 1)); l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = Vector2(12, 8)
	cap.add_child(l); root.add_child(cap)
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_height() > 720: img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	var pics := OS.get_cmdline_user_args()[2]
	var f := pics.path_join("RESUME-1603_" + c + ".png")
	if preload("res://tools/picture_provenance.gd").save_png(img, f) != OK: _bad(c + ": could not write " + f)
	else: _line("saved " + f)
	cap.queue_free(); ui.queue_free(); await process_frame

# ---------------------------------------------------------------- report

func _bad(why: String) -> void:
	fails += 1; _line("FAIL " + why)

func _line(s: String) -> void:
	report.append(s); print(s)

func _done(fatal: String) -> void:
	if fatal != "": _bad(fatal)
	_line("OLD_SAVE_1603 " + ("PASS" if fails == 0 else "FAIL %d" % fails))
	if folder != "" and DirAccess.dir_exists_absolute(folder):
		var f := FileAccess.open(folder.path_join("old_save_" + mode + ".txt"), FileAccess.WRITE)
		if f != null: f.store_string("\n".join(report) + "\n"); f.close()
	quit(0 if fails == 0 else 1)
