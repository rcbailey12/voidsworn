# Step 14 screenshots: capstone mastery on a flown evolution, at 320 and 440 XP, plus the admiral bar.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/capstone_mastery_shots.gd -- <out dir>
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://capstone_mastery_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://capstone_mastery_save.json"
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

func _profile(xp: float) -> void:
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["mastery"]["vaelen"] = xp
	C.META["lineage"] = {"vaelen": {"picks": ["A:0:0", "B:0:0", "C:0:0"], "capstone": 0, "respecs": 0}}
	C.picked_faction = "ithar"; C.picked_admiral = "vaelen"

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	_profile(320.0)
	C.act("lineage", "vaelen")
	await _frames(4); _scroll_to("Capstone mastery")
	await _shot("capstone_01_mastery_320")
	_profile(440.0)
	C.act("lineage", "vaelen")
	await _frames(4); _scroll_to("Capstone mastery")
	await _shot("capstone_02_mastery_440")
	_profile(440.0)
	C.act("progTab", "mastery")
	await _frames(4); _scroll_to("Saro of Long Focus")
	await _shot("capstone_03_bar_and_mastery_tab")
	print("capstone mastery shots done")
	quit(0)
