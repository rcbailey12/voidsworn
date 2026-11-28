# Step 14 screenshots: capstone mastery on a flown evolution, at 320, 440 and 600 XP (issue 1650), plus the admiral bar.
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/capstone_mastery_shots.gd -- <out dir>
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
	var sc = target.get_parent()
	while sc != null and not (sc is ScrollContainer): sc = sc.get_parent()   # the page scroller may sit deeper than page_box's children
	if sc == null: return
	await _frames(2)
	sc.scroll_vertical = max(0, sc.scroll_vertical + int(target.global_position.y - sc.global_position.y) - 24)   # the target near the top
	await _frames(2)

var failed := 0

# counts a picture as made only when the PNG and its provenance file are both written (Artoo on PR 1738)
func _shot(name: String) -> void:
	if PG.stop_if_any():
		return
	await _frames(8)
	if DisplayServer.get_name() == "headless":
		print("built ", name, " (", C.page.get("kind"), ")"); return
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	var path := dir.path_join(name + ".png")
	var err = preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage())
	if err != OK or not FileAccess.file_exists(path) or not FileAccess.file_exists(path + ".provenance.json"):
		failed += 1; printerr("FAIL could not save ", name, " (error ", err, ")"); return
	print("shot ", name)

func _profile(xp: float) -> void:
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["mastery"]["vaelen"] = xp
	C.META["lineage"] = {"vaelen": {"picks": ["A:0:0", "B:0:0", "C:0:0"], "capstone": 0, "respecs": 0}}
	C.picked_faction = "ithar"; C.picked_admiral = "vaelen"

func _run() -> void:
	await _frames(4)
	C.rng.rnd_seed(4242)
	_profile(320.0)
	C.act("lineage", "vaelen")
	await _frames(4); await _scroll_to("Capstone mastery: ")
	await _shot("capstone_01_mastery_320")
	_profile(440.0)
	C.act("lineage", "vaelen")
	await _frames(4); await _scroll_to("Capstone mastery: ")
	await _shot("capstone_02_mastery_440")
	_profile(600.0)   # issue 1650: Mastery III names the capstone's signature
	C.act("lineage", "vaelen")
	await _frames(4); await _scroll_to("Capstone mastery: ")
	await _shot("capstone_04_mastery_600")
	_profile(440.0)
	C.act("progTab", "mastery")
	await _frames(4); await _scroll_to("Saro of Long Focus")
	await _shot("capstone_03_bar_and_mastery_tab")
	print("capstone mastery shots done" if failed == 0 else "capstone mastery shots: %d picture(s) not saved" % failed)
	PG.finish(0 if failed == 0 else 1)
