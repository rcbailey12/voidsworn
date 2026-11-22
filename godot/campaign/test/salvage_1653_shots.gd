# Issue 1653 pictures: the salvage offer after a boss with three of the new relics, and the recovered refits card with the
# four new refits.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/salvage_1653_shots.gd -- <out dir>
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
	dir = a[0] if a.size() > 0 else "user://salvage_1653_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://salvage_1653_save.json"; C.persist_on = false
	ui = UIScript.new(); root.add_child(ui); ui.bind(C)
	_run()

func _frames(n: int) -> void:
	for i in range(n): await process_frame

func _shot(name: String) -> bool:
	if PG.stop_if_any(): return false
	await _frames(8)
	if DisplayServer.get_name() == "headless":
		print("built ", name); return true
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	var path = dir.path_join(name + ".png")
	var err = preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage())
	var ok = err == OK and FileAccess.file_exists(path) and FileAccess.file_exists(path + ".provenance.json")
	print("shot " if ok else "FAILED ", name)
	return ok

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(1653)
	C.META = C.migrateMeta(C.defaultMeta())
	C.newRun("vex", "voidsworn")
	C.RUN["reward"] = {"kind": "boss", "rw": {"k": "boon"}, "stage": "relic", "relics": [], "wrecks": [], "prizes": [], "boonOffer": null, "modOffer": null}
	C.W["rewardCfg"] = {"kind": "boss"}
	C.W["relicChoice"] = ["mirror", "lastlight", "beacon"]
	C.relicStep()
	var ok1 = await _shot("salvage_1653_01_relics")
	var acts = []
	for m in ["locker", "chaser", "spill", "relay"]: C.A(acts, "takeMod", m)
	C.show_modal("mod", {"opts": ["locker", "chaser", "spill", "relay"]}, acts)
	var ok2 = await _shot("salvage_1653_02_refits")
	PG.finish(0 if ok1 and ok2 else 1)
