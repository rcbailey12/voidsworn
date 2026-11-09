# Issue #122: fixed screenshots of the Nemesis panel on the map, for the before and after sets (check 122-7).
#   godot --path godot --resolution 1920x1080 --script res://campaign/test/nem_panel_shots.gd -- <out dir>
# Same profile, seed and steps every time; it only calls campaign functions that exist before and after #122, so the same file
# takes the pre-build set (on the #121 branch) and the post-build set (on the #122 branch).
# The run: the Sunward Crusade with a forced assignment Glasswrights, Chorus, Glasswrights (the SP1 hunter returns at SP3).
#   p1_first_sector  sector I, the Glasswright commander, one clock step, not met yet
#   p2_rotated       sector II after a real sector advance: he fled in sector I (scar, epithet); the Chorus commander fed on 3 losses
#                    and won its meeting (a lesson)
#   p3_return        sector III after a real sector advance: the Glasswright commander back, scarred; the Chorus commander earlier
# Each state saves the full screen (<name>.png) and the side panel cropped (<name>_panel.png), scrolled so the Nemesis head is on top.
extends SceneTree
const CampaignScript = preload("res://campaign/campaign.gd")
const UIScript = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var C
var ui
var dir := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://nem_panel_shots"
	DirAccess.make_dir_recursive_absolute(dir)
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "":
		printerr(err); quit(1); return
	C.save_path = "user://nem_panel_shots_save.json"
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

# the side panel scrolls; put the Nemesis head at the top of it so the whole card and what follows it are in view
func _side_scroll() -> Control:
	var head = _find_text(ui, "NEMESIS")
	if head == null: head = _find_text(ui, "Nemesis")
	if head == null: return null
	var p = head.get_parent()
	while p != null and not (p is ScrollContainer): p = p.get_parent()
	if p == null: return null
	p.scroll_vertical = max(0, int(head.global_position.y - p.get_child(0).global_position.y) - 8)
	return p

func _shot(name: String) -> void:
	C.mapScreen()
	await _frames(8)
	var sc = _side_scroll()
	await _frames(4)
	if DisplayServer.get_name() == "headless":   # cloud smoke run: the screens build, there is nothing to capture
		print("built ", name, " (", C.page.get("kind"), ")", " panel: ", "found" if sc != null else "missing"); return
	var t0 = Time.get_ticks_msec()   # the map draws under a "Preparing the sector" cover (main/load_screen.gd); a software renderer can take minutes
	while _covered(root) and Time.get_ticks_msec() - t0 < 300000: await process_frame
	await _frames(4)
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join(name + ".png"))
	if sc != null:
		var host = sc.get_parent()
		var r = Rect2i(Vector2i(host.global_position), Vector2i(host.size)).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		if r.size.x > 0 and r.size.y > 0: img.get_region(r).save_png(dir.path_join(name + "_panel.png"))
	print("shot ", name)

func _covered(n: Node) -> bool:
	if n.get_script() != null and str(n.get_script().resource_path).ends_with("load_screen.gd"): return true
	for ch in n.get_children():
		if _covered(ch): return true
	return false

# the real sector advance (the sector flagship beaten): the outgoing commander adapts, the incoming one resolves
func _advance() -> void:
	C.RUN["reward"] = null; C.W["rewardCfg"] = {"kind": "boss"}; C.afterBattle(); C.act("closeModal")
	await _frames(2)

func _run() -> void:
	await _frames(4)
	BattleAPI.JSM.rnd_seed(4242)
	C.playtest_default = true
	C.META = C.migrateMeta(C.defaultMeta())
	C.META["opts"]["playtestAll"] = true   # R69 stays on, as in the shipped game
	C.picked_faction = "voidsworn"; C.picked_admiral = "vex"
	C.titleScreen(); C.act("newRunScreen"); C.act("pickFaction", "voidsworn")
	C.act("startRun"); C.act("pickAspect", C.W["aspOffer"][0]); C.act("closeModal"); await _frames(4)
	C.RUN["nemAssign"] = ["ithar", "chorus", "ithar"]; C.RUN["nems"] = {}; C.RUN["nem"] = null
	C.RUN["nemClock"] = 0; C.RUN["nemStrike"] = false; C.nemActive()
	C.nemClockAdd(1)
	await _shot("p1_first_sector")
	C.nemAfterBattle("win", false, {"fled": true, "beat": "torp"})   # he flees: a scar, an epithet, honed
	await _advance()
	C.nemFeedLosses(3); C.nemAfterBattle("loss", false, {})   # the Chorus feeds, then wins its meeting: a lesson on it
	await _shot("p2_rotated")
	await _advance()
	await _shot("p3_return")
	print("nem panel shots done")
	quit(0)
