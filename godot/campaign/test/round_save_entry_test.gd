# Issue 1451, Artoo on PR 1486: the round save works from a fight entered the normal way, from the map. Real files, cold restarts.
#   godot --headless --path godot --script res://campaign/test/round_save_entry_test.gd
# The run is saved on the map (the checkpoint a player really has: curNode null, the position before the stop). A cold start loads
# that file, Continue opens the map, and the fight is entered through the map's own enterNode action: a battle, an elite, an
# ambush (the robbed Hegemony escort) and an event that turns into a fight (eventChoice). Round 2's save is written; a second
# cold start from the file must Continue into that same fight at round 2. Then the fallbacks: a snapshot from other rules, and a
# round save that never reached the disk, each Continue to the map checkpoint, playable, with no fight settled.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
const DIR := "user://round_save_entry_test"
var api = null
var fails := 0

func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api = API.new(); api.load_rules(); api.set_ai_level("veteran"); api.round_saves = true
	api.new_battle(run, cfg)
	return api.R.B

func _restore(sb: Dictionary) -> Dictionary:
	var a = API.new(); a.load_rules()
	var why: String = a.restore_round(Marshalls.base64_to_raw(sb["data"]), int(sb["size"]), str(sb["fp"]))
	if why != "": return {"error": why}
	a.round_saves = true; api = a
	return {"B": a.R.B, "run": a.R.RUN}

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

func _fresh(path: String, persist := true) -> Variant:
	var C = Campaign.new(); C.load_tables(); C.fixed_clock = true; C.persist_on = persist; C.save_path = path
	C.battle_mode = "external"; C.battle_setup = _setup; C.battle_restore = _restore
	return C

func _cold(path: String, launch_seed := 11) -> Variant:   # a new launch: everything from the file, then the title's Continue
	api = null
	var D = _fresh(path); D.seed_rng(launch_seed)
	D.persist_load(); D.titleScreen(); D.act("continueRun")
	return D

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

func _rmdir(p: String) -> void:
	var g := ProjectSettings.globalize_path(p)
	if DirAccess.dir_exists_absolute(g):
		for f in DirAccess.get_files_at(g): DirAccess.remove_absolute(g.path_join(f))
		for d in DirAccess.get_directories_at(g): _rmdir(p.path_join(d))
		DirAccess.remove_absolute(g)

# The offered event choice whose outcome is a fight (campaign.gd ACT_eventChoice), or null
func _fight_choice(C) -> Variant:
	if not (C.cur_event is Dictionary): return null
	for x in _acts(C, "eventChoice"):
		var i := int(x[1])
		var o = C.cur_event["o"][i] if i >= 0 and i < C.cur_event["o"].size() else null
		if o is Dictionary and o.get("r") is Dictionary and C.jt(o["r"].get("fight")): return x[1]
	return null

func _acts(C, kind: String) -> Array:
	return C.screen_acts().filter(func(x): return x[0] == kind and int(x[2]) == 1)

# A run saved on the map with `want` reachable; returns the target node id or "".
func _map_save(path: String, seed: int, fac: String, want: String, ambush: bool) -> String:
	var C = _fresh(path)
	C.rng.rnd_seed(seed); C.META = C.defaultMeta()
	var adm = null
	for id in C.ADMIRALS.keys():
		if C.ADMIRALS[id].get("fac") == fac and adm == null: adm = id
	C.newRun(adm, fac, {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null
	for i in 3: C.RUN["fleet"].append(C.newShip(C.cheapHull(fac)))
	if C.RUN.get("aspect") == null: C.RUN["aspect"] = C.ASPECTS.keys()[0]
	var target := ""
	for col in C.RUN["map"]["cols"]:   # stand on a node, done, with the wanted stop one lane ahead
		for n in col:
			if target != "": break
			C.RUN["pos"] = n["id"]
			for id in C.availableNodes():
				var m = C.findNode(id)
				if target == "" and m != null and m["type"] == want and not C.nemNodeIs(m): target = id
			if target != "": n["done"] = true
	if target == "": return ""
	C.RUN["curNode"] = null; C.RUN["ambush"] = ambush
	C.mapScreen(); C.saveRun()
	return target

func _case(label: String, seed: int, fac: String, want: String, ambush := false) -> void:
	var path := DIR.path_join(label + ".json")
	var target := _map_save(path, seed, fac, want, ambush)
	if target == "":
		_check(false, "%s: no %s stop one lane ahead" % [label, want]); return
	var C = _cold(path, seed)
	_check(C.page.get("kind") == "map" and C.SAVED_RUN.get("curNode") == null, "%s: Continue opens the map from a map checkpoint" % label)
	C.act("enterNode", target)
	if want == "event":   # pick the event choice that becomes a fight (each tried from the same saved state)
		var pick = _fight_choice(C)
		if pick == null:
			_check(false, "%s: this event offers no fight" % label); return
		api = null; C.act("eventChoice", pick)
	_check(C.pending_battle != null and api != null, "%s: entering the stop through the map starts the fight" % label)
	if api == null: return
	var kind := str(C.B["cfg"].get("kind")); var node := str(C.RUN.get("curNode"))
	_play_to(C, 2)
	_check(api.phase == "player" and api.round_snap_round == 2, "%s: the fight reached round 2" % label)
	var units := str(api.view()["units"].map(func(u): return [u["id"], u["hp"], u["q"], u["r"]]))
	_check(C.save_battle_round(api.take_round_snapshot()), "%s: round 2's save is on disk" % label)
	C.leave_battle_saved()
	var D = _cold(path, seed)
	_check(D.pending_battle != null and api != null and int(api.R.B["round"]) == 2, "%s: a cold Continue resumes round 2 (page %s)" % [label, str(D.page.get("kind"))])
	if api != null:
		_check(str(D.B["cfg"].get("kind")) == kind and str(D.RUN.get("curNode")) == node and str(api.view()["units"].map(func(u): return [u["id"], u["hp"], u["q"], u["r"]])) == units,
			"%s: the same fight (%s at %s, every ship where it was)" % [label, kind, node])

func _init() -> void:
	_rmdir(DIR); DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	_case("battle", 11, "voidsworn", "battle")
	_case("elite", 14, "corsair", "elite")   # seed 12 until R414 (option C): the new enemy fleet changed the opening, so the fight no longer reached round 2
	_case("ambush", 13, "ithar", "battle", true)
	var ev := false
	for s in range(20, 60):   # an event that offers a fight
		var path := DIR.path_join("probe.json")
		var target := _map_save(path, s, "chorus", "event", false)
		if target == "": continue
		var C = _cold(path, s); C.act("enterNode", target)
		ev = _fight_choice(C) != null
		if ev:
			_case("event", s, "chorus", "event"); break
	if not ev: _check(false, "event: no event with a fight in seeds 20 to 59")
	# fallbacks: the map checkpoint stays usable
	var path := DIR.path_join("other_rules.json")
	var target := _map_save(path, 14, "deathless", "battle", false)
	var C = _cold(path); C.act("enterNode", target); _play_to(C, 2)
	C.save_battle_round(api.take_round_snapshot()); C.leave_battle_saved()
	var txt := FileAccess.get_file_as_string(path)
	var o = JSON.parse_string(txt); o["battle"]["fp"] = "snap0:other"
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(o)); f.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	var D = _cold(path)
	_check(D.page.get("kind") == "map" and D.RUN != null and D.RUN.get("curNode") == null and D.saved_battle == null and _acts(D, "enterNode").size() > 0,
		"other rules: Continue opens the map checkpoint, the stop can be entered again (page %s)" % str(D.page.get("kind")))
	path = DIR.path_join("never_written.json")
	target = _map_save(path, 15, "hegemony", "battle", false)
	C = _cold(path); C.act("enterNode", target); _play_to(C, 2)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path + ".tmp"))
	_check(C.save_battle_round(api.take_round_snapshot()) == false, "failed write: reported")
	C.leave_battle_saved()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
	D = _cold(path)
	_check(D.page.get("kind") == "map" and D.RUN != null and _acts(D, "enterNode").size() > 0 and int(D.RUN["stats"].get("battles", 0)) == 0,
		"failed write: Continue opens the map checkpoint, nothing settled (page %s)" % str(D.page.get("kind")))
	_rmdir(DIR)
	quit(1 if fails > 0 else 0)
