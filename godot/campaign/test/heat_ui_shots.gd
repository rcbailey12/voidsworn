# Step 10 screenshots: the run setup Heat card before and after the first loss.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/heat_ui_shots.gd -- <out dir>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://heat_ui_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://heat_ui_shots_save.json"
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

func _scroll_to(needle: String) -> void:
	var target = _find_text(ui.page_box, needle)
	if target == null: return
	var panel = target.get_parent().get_parent()
	for ch in ui.page_box.get_children():
		if ch is ScrollContainer:
			ch.ensure_control_visible(panel)
			ch.scroll_vertical = max(0, ch.scroll_vertical - 24)
			return

func _shot(name: String) -> void:
	await _frames(8)
	if DisplayServer.get_name() == "headless":
		print("built ", name, " (", C.page.get("kind"), ")"); return
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png")); print("shot ", name)

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	C.playtest_default = true
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["opts"]["playtestAll"] = true   # R69 stays on, as in the shipped game
	C.picked_faction = "voidsworn"; C.picked_admiral = "vex"
	C.titleScreen(); C.act("newRunScreen")
	await _frames(4); _scroll_to("Lose a run to unlock Heat")
	await _shot("heat_01_fresh_no_heat")
	C.META["stats"]["losses"] = 1
	C.admiralScreen()
	await _frames(4); _scroll_to("Heat")
	await _shot("heat_02_after_one_loss")
	print("heat ui shots done")
	quit(0)
