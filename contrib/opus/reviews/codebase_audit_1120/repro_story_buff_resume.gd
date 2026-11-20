# Issue 1333 audit, finding F3: a Sector III fight resumed from a save gets the one-battle story buff again.
#   godot --headless --path godot --script <abs path to this file>
# Read-only (persist_on is off; the save text stays in memory). Exit 1 when the resumed fight carries storyMods (the bug).
# Setup: a Sunward run in Sector III that took the "power" choice of its beat 3 story (arc_vs_owed option 0: +25% flagship
# damage, next battle only) and has already spent it (storyNext is null, as battleScreen leaves it). The save points at an
# unfinished battle node, the state every resume path through _resume_node starts from (old mid-fight saves, and the
# Nemesis-cleared event stop, which saves right before its fight).
extends SceneTree
const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")
var seen_cfg = null
func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	seen_cfg = cfg.duplicate(true)
	return {"units": [], "cfg": cfg, "round": 1}
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
	var D = Campaign.new(); D.load_tables(); D.persist_on = false; D.fixed_clock = true
	D.battle_mode = "external"; D.battle_setup = _setup
	D.load_save_text(text); D.titleScreen(); D.act("continueRun")
	var mods = seen_cfg.get("storyMods") if seen_cfg != null else null
	print("resumed fight at %s: storyMods = %s" % [node["id"], str(mods)])
	quit(1 if mods != null else 0)
