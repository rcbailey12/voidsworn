# R1 (Nov 1, feel pass): fixed screenshots of the campaign screens the R1 batch changed, for before and after sets.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/r1_ui_shots.gd -- <out dir>
# Same profile, seed and steps every time: 100 renown, only Vex bought, War chest I unlocked.
# a1/a2 the admiral screen (Hegemony, then the Sunward Crusade), b1 Progression on the Legacy tab,
# c1 a shipyard with the starting fleet, c2 the same shipyard with a sector flagship hull in the fleet (no shop price).
# t1, a0, t2 (when the build has the playtest switch): the title and the admiral screen with "everything unlocked" on, then the title with it off.
extends SceneTree
const PG := preload("res://render/placeholder_guard.gd")
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://r1_ui_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://r1_ui_shots_save.json"
	ui = UIScript.new(); root.add_child(ui); ui.bind(C)
	_run()

func _frames(n: int) -> void:
	for i in range(n): await process_frame

func _shot(name: String) -> void:
	if PG.stop_if_any():
		return
	await _frames(8)
	if DisplayServer.get_name() == "headless":   # cloud smoke run: the screens build, there is nothing to capture
		print("built ", name, " (", C.page.get("kind"), ")"); return
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png")); print("shot ", name)

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	var M = C.META
	M["renown"] = 100; M["admirals"] = {"vex": true}; M["unlocked"] = {"chest1": true}
	if C.has_method("set_playtest_all"):   # Ryan's Nov 1 playtest switch: first with it on (the game's default), then off for the progression shots
		C.set_playtest_all(true)
		C.titleScreen(); await _shot("t1_title_playtest_on")
		C.act("newRunScreen"); C.act("pickFaction", "hegemony"); await _shot("a0_admiral_hegemony_playtest_on")
		C.act("title"); C.set_playtest_all(false); C.titleScreen(); await _shot("t2_title_playtest_off")
	C.titleScreen(); C.act("newRunScreen"); C.act("pickFaction", "hegemony"); await _shot("a1_admiral_hegemony")
	C.act("pickFaction", "voidsworn"); await _shot("a2_admiral_crusade")
	C.act("title"); C.act("legacy"); C.act("progTab", "legacy"); await _shot("b1_progression_legacy")
	C.act("progTab", "variants"); C.act("title"); C.act("newRunScreen"); C.act("pickFaction", "voidsworn")
	C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal"); await _frames(4)
	var yard = {"id": "r1y", "type": "shipyard", "col": 3, "row": 0}
	C.shipyardScreen(yard); await _shot("c1_shipyard")
	C.RUN["fleet"].append(C.newShip("c_boss")); C.shipyardScreen(yard); await _shot("c2_shipyard_flagship_hull")
	print("r1 ui shots done")
	PG.finish(0)
