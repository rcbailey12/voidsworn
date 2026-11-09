# Issue #24, progression step 7: screenshots for the review.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/nemesis_teach_shots.gd -- <out dir>
# Two states, same seed and run each time:
#   map_certain   sector I map: the assigned hunter named, the once-per-sector meeting called certain, the "Nemesis meeting" tags
#   debrief_lesson the run-end debrief after losing that meeting: the Nemesis lesson row, recorded against the commander who fought it
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://nemesis_teach_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://nemesis_teach_shots_save.json"
	ui = UIScript.new(); root.add_child(ui); ui.bind(C)
	_run()

func _frames(n: int) -> void:
	for i in range(n): await process_frame

func _find_text(n: Node, needle: String) -> Node:
	if n is Label and needle in n.text: return n
	if n is RichTextLabel and needle in n.get_parsed_text(): return n
	for ch in n.get_children():
		var r = _find_text(ch, needle); if r != null: return r
	return null

func _scroll_for(needle: String) -> Control:
	var node = _find_text(ui, needle)
	if node == null: return null
	var p = node.get_parent()
	while p != null and not (p is ScrollContainer): p = p.get_parent()
	if p == null: return null
	p.scroll_vertical = max(0, int(node.global_position.y - p.get_child(0).global_position.y) - 12)
	return p

func _covered(n: Node) -> bool:
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("load_screen.gd"): return true
	for ch in n.get_children():
		if _covered(ch): return true
	return false

func _shot(name: String, needle: String, crop := false) -> void:
	await _frames(8)
	var sc = _scroll_for(needle) if needle != "" else null
	await _frames(4)
	if DisplayServer.get_name() == "headless":
		print("built ", name, " (", C.page.get("kind"), ")"); return
	var t0 = Time.get_ticks_msec()
	while _covered(root) and Time.get_ticks_msec() - t0 < 300000: await process_frame
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	if crop and sc != null:
		var host = sc.get_parent()
		var r = Rect2i(Vector2i(host.global_position), Vector2i(host.size)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if r.size.x > 0 and r.size.y > 0: img.get_region(r).save_png(dir.path_join(name + "_panel.png"))
	print("shot ", name)

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	C.playtest_default = true
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["opts"]["playtestAll"] = true
	C.picked_faction = "voidsworn"; C.picked_admiral = "vex"
	C.titleScreen(); C.act("newRunScreen"); C.act("pickFaction", "voidsworn")
	C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal"); await _frames(4)
	C.RUN["nemAssign"] = ["hegemony", "corsair", "ithar"]; C.RUN["nems"] = {}; C.RUN["nem"] = null
	C.RUN["nemClock"] = 0; C.RUN["nemStrike"] = false; C.RUN["sector"] = 1; C.nemActive()
	C.mapScreen()
	await _shot("map_certain", "You will meet", true)
	# lose the meeting: the commander stays the sector's assigned hunter, and the loss teaches one weakness on him
	C.nemAfterBattle("loss", false, {})
	C.endRun(false, false)
	await _shot("debrief_lesson", "Nemesis lesson", false)
	print("nemesis teach shots done")
	quit(0)
