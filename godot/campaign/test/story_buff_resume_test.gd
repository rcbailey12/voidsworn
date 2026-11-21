# Issue 1338: a resumed Sector III fight gets the one-battle story buff only when it was never spent.
#   godot --headless --path godot --script res://campaign/test/story_buff_resume_test.gd
# Based on the issue 1333 audit repro (finding F3). A Sunward run in Sector III took the "power" choice of its beat 3 story and
# has already spent the buff (storyNext null). Its save points at an unfinished battle node, the state every resume through
# _resume_node starts from.
#   1. a save from this build (storyGuard): the resumed fight carries no storyMods
#   2. the same save from an older build (no storyGuard, the old mid-battle checkpoint may have erased an unspent buff): the
#      buff is repaired, once
#   3. a second Continue of that old save in the same session: no second repair
extends SceneTree
@warning_ignore_start("untyped_declaration", "unsafe_method_access", "unsafe_call_argument", "inference_on_variant")
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var seen_cfg = null
var fails := 0

func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	seen_cfg = cfg.duplicate(true)
	return {"units": [], "cfg": cfg, "round": 1}

func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok: fails += 1

func _resume(D) -> Variant:
	seen_cfg = null
	D.titleScreen(); D.act("continueRun")
	return seen_cfg.get("storyMods") if seen_cfg != null else "no fight"

func _init() -> void:
	var C = Campaign.new(); C.load_tables(); C.persist_on = false; C.fixed_clock = true
	JSM.rnd_seed(7); C.META = C.defaultMeta(); C.newRun("vex", "voidsworn", {})
	C.RUN["sector"] = 3; C.RUN["map"] = C.genSector(3); C.RUN["pos"] = null
	var node = null
	for col in C.RUN["map"]["cols"]:
		for n in col:
			if n["type"] == "battle" and node == null: node = n
	if node == null:
		print("no battle node in this sector"); quit(2); return
	C.RUN["flags"]["arc_vs_owed"] = "0"      # the story choice was made...
	C.RUN["storyNext"] = null                # ...and its one battle has been fought (battleScreen spends it)
	C.RUN["pos"] = node["id"]; C.RUN["curNode"] = node["id"]
	C.saveRun()
	var text: String = C.save_text()
	_check(text.contains("\"storyGuard\":true"), "saves carry storyGuard")
	var D = Campaign.new(); D.load_tables(); D.persist_on = false; D.fixed_clock = true
	D.battle_mode = "external"; D.battle_setup = _setup
	D.load_save_text(text)
	var m1 = _resume(D)
	_check(m1 == null, "new save: the spent buff stays spent (storyMods %s)" % str(m1))
	var old := text.replace(",\"storyGuard\":true", "").replace("\"storyGuard\":true,", "")
	var E = Campaign.new(); E.load_tables(); E.persist_on = false; E.fixed_clock = true
	E.battle_mode = "external"; E.battle_setup = _setup
	E.load_save_text(old)
	var m2 = _resume(E)
	_check(m2 is Dictionary and not m2.is_empty(), "old save: the buff the old checkpoint could have erased is repaired (storyMods %s)" % str(m2))
	var m3 = _resume(E)
	_check(m3 == null, "old save, second Continue: no second repair (storyMods %s)" % str(m3))
	quit(1 if fails > 0 else 0)
