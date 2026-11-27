# Issue 1451, Artoo on PR 1486: a round save the disk rejects is never promised. Real files, cold restart.
#   godot --headless --path godot --script res://campaign/test/round_save_disk_test.gd
# A campaign with saves on (persist_on, its own file under user://) plays a fight. Round 2's save is written. Then the disk refuses
# writes (a folder sits where the temp file must go), so round 3's save fails: save_battle_round says so, the campaign keeps round
# 2 as its battle save, and Save and quit leaves without settling. A brand-new campaign then loads the file from disk and
# Continue must resume round 2, not round 3 and not the pre-fight start. Exit 0 when every step holds.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
const DIR := "user://round_save_disk_test"
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

func _fresh(path: String) -> Variant:
	var C = Campaign.new(); C.load_tables(); C.fixed_clock = true; C.persist_on = true; C.save_path = path
	C.battle_mode = "external"; C.battle_setup = _setup; C.battle_restore = _restore
	return C

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

func _init() -> void:
	_rmdir(DIR); DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var path := DIR.path_join("campaign.json")
	var C = _fresh(path)
	C.rng.rnd_seed(4242); C.META = C.defaultMeta(); C.newRun("vex", "voidsworn", {})
	C.RUN["sector"] = 2; C.RUN["map"] = C.genSector(2); C.RUN["pos"] = null
	for i in 3: C.RUN["fleet"].append(C.newShip(C.cheapHull("voidsworn")))
	var node = null
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if node == null and n["type"] == "battle": node = n
	C.RUN["pos"] = node["id"]; C.RUN["curNode"] = node["id"]; C.saveRun()
	C._enter_battle_node(node)
	_play_to(C, 2)
	_check(api.phase == "player" and api.round_snap_round == 2, "the fight reached round 2 (round %d, phase %s)" % [api.round_snap_round, api.phase])
	_check(C.save_battle_round(api.take_round_snapshot()) == true, "round 2's save is written")
	_play_to(C, 3)
	_check(api.phase == "player" and api.round_snap_round == 3, "the fight reached round 3 (round %d, phase %s)" % [api.round_snap_round, api.phase])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path + ".tmp"))   # the disk now refuses the save
	_check(C.save_battle_round(api.take_round_snapshot()) == false, "round 3's save is reported failed")
	_check(C.saved_battle != null and int(C.saved_battle["round"]) == 2, "the campaign keeps round 2 as its battle save (in memory as on disk)")
	C.leave_battle_saved()
	_check(C.page.get("kind") == "title" and C.SAVED_RUN != null, "Save and quit reaches the title with the run still saved, nothing settled")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
	api = null
	var D = _fresh(path)   # a cold start: everything from the file
	D.persist_load(); D.titleScreen(); D.act("continueRun")
	_check(D.pending_battle != null and api != null, "Continue from disk resumes the fight (page %s)" % str(D.page.get("kind")))
	if api != null: _check(int(api.R.B["round"]) == 2, "Continue from disk starts round 2, the last round that reached the disk (got %d)" % int(api.R.B["round"]))
	_rmdir(DIR)
	quit(1 if fails > 0 else 0)
