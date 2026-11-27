# Issue 1451 (Artoo on PR 1486): the battle scene's Save and quit hand-off, headless, on the real battle scene.
#   godot --headless --path godot --script res://scenes/battle/test/save_quit_handoff_check.gd
# A campaign fight plays in battle.tscn with round saves wired as main.play_api wires them. Two runs:
#   1. the write succeeds: the menu offers "Save and quit to title"; choosing it ends the scene through _finish (the retire
#      guard runs) with result save_quit; the campaign leaves to the title, nothing settled; a cold load of the save text and
#      Continue resume the same fight at the saved round.
#   2. the write fails: the menu does not offer Save and quit; it names what Continue loads ("from the last checkpoint"), and
#      choosing it also ends through _finish without settling; Continue then opens the map checkpoint.
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant", "unsafe_property_access")
const API = preload("res://rules/battle_api.gd")
const Campaign = preload("res://campaign/campaign.gd")
var api = null
var fails := 0

class Probe extends "res://scenes/battle/battle.gd":
	var finished_via := ""
	func _finish(r: Dictionary) -> void:
		finished_via = "_finish"
		super._finish(r)

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

func _fresh() -> Variant:
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true
	C.battle_mode = "external"; C.battle_setup = _setup; C.battle_restore = _restore
	return C

func _init() -> void:
	_go.call_deferred()

func _run(write_ok: bool) -> void:
	var tag := "write ok" if write_ok else "write fails"
	var C = _fresh()
	C.rng.rnd_seed(11); C.META = C.defaultMeta(); C.newRun("vex", "voidsworn", {})
	var node = C.RUN["map"]["cols"][0][0]
	for n in C.RUN["map"]["cols"][0]:
		if n["type"] == "battle": node = n
	C.mapScreen(); C.saveRun()   # the map checkpoint, as a player has it
	C.act("enterNode", node["id"])
	_check(C.pending_battle != null and api != null, "%s: the fight starts from the map" % tag)
	var b = load("res://scenes/battle/battle.tscn").instantiate()
	b.set_script(Probe)
	b.external = true; b.in_campaign = true; b.args["no-tips"] = true
	b.round_save_cb = func() -> bool:
		return C.save_battle_round(api.take_round_snapshot()) if write_ok else false
	root.add_child(b)
	b.begin_with(api)
	var t0 := Time.get_ticks_msec()
	while (b.round_saved == 0 or b.busy or b.warming) and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	_check(b.round_saved >= 1, "%s: the scene handed round %d to the save" % [tag, b.round_saved])
	b._open_menu()
	await process_frame
	var items: Array = b.hud._last.get("show_menu", ["", []])[1]
	var acts: Array = items.map(func(x): return str(x[1]))
	var labels: Array = items.map(func(x): return str(x[0]))
	var got := {}
	b.finished.connect(func(r): got.merge(r), CONNECT_ONE_SHOT)
	if write_ok:
		_check(acts.has("save_quit") and not acts.has("save_quit_older"), "%s: the menu offers Save and quit to title" % tag)
		b._on_action("save_quit", null)
	else:
		_check(not acts.has("save_quit") and acts.has("save_quit_older") and labels.has("Quit to title (Continue starts from the last checkpoint)"),
			"%s: no Save and quit; the row names the last checkpoint (%s)" % [tag, str(labels.filter(func(l): return l.begins_with("Quit to title")))])
		b._on_action("save_quit", null)   # not offered, so it must not leave
		await process_frame
		_check(got.is_empty() and not b.ended, "%s: a forced Save and quit does not leave the battle" % tag)
		b._on_action("save_quit_older", null)
	await process_frame
	_check(str(got.get("result", "")) == "save_quit" and b.finished_via == "_finish", "%s: the scene ends through _finish with save_quit (%s via %s)" % [tag, str(got.get("result")), b.finished_via])
	var rnd := int(api.round_snap_round)
	C.leave_battle_saved()
	_check(C.page.get("kind") == "title" and C.SAVED_RUN != null and int(C.SAVED_RUN["stats"].get("battles", 0)) == 0 and C.B == null, "%s: the campaign is on the title, the run saved, nothing settled" % tag)
	var text: String = C.save_text()
	b.queue_free()
	await process_frame
	api = null
	var D = _fresh(); D.load_save_text(text); D.titleScreen(); D.act("continueRun")
	if write_ok:
		_check(D.pending_battle != null and api != null and int(api.R.B["round"]) == rnd, "%s: a cold Continue resumes the fight at round %d" % [tag, rnd])
	else:
		_check(D.page.get("kind") == "map" and D.pending_battle == null and int(D.RUN["stats"].get("battles", 0)) == 0, "%s: Continue opens the map checkpoint (page %s)" % [tag, str(D.page.get("kind"))])

func _go() -> void:
	await _run(true)
	await _run(false)
	quit(1 if fails > 0 else 0)
