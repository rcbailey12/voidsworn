# Issue 1484: picture CHO-1, a Sector 3 Chorus shipyard with every price in biomass (refits, class refit tracks and the late
# market). Headless it only checks the page builds and names biomass on those buttons; with a display it saves the picture.
#   godot --path godot --rendering-method gl_compatibility --resolution 1280x720 --script res://campaign/test/chorus_biomass_1484_shots.gd -- <out folder>
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const MapIntel = preload("res://ui/campaign/map_intel.gd")

var campaign = Campaign.new()
var ui: CampaignUI
var out := ""
var headless := false

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	headless = DisplayServer.get_name() == "headless"
	if not headless:
		if args.is_empty(): _fail("supply a picture output folder after --"); return
		out = args[0]
		if DirAccess.make_dir_recursive_absolute(out) != OK: _fail("cannot create " + out); return
	var err: String = campaign.load_tables()
	if err != "": _fail(err); return
	campaign.fixed_clock = true
	JSM.rnd_seed(1484)
	campaign.META["admirals"]["matriarch"] = true
	campaign.newRun("matriarch", "chorus")
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = campaign
	ui.teaching = CampaignTips.new()
	ui.teaching.disabled = true
	ui.add_child(ui.teaching)
	ui.set_process(false)
	ui.use_3d_map = false
	ui.map3d.intel = MapIntel.new(campaign)

	campaign.RUN["sector"] = 3; campaign.RUN["bio"] = 640.0; campaign.RUN["credits"] = 0.0
	var n = campaign.RUN["map"]["cols"][0][0]
	n["type"] = "shipyard"; n.erase("stock")
	campaign.modal_d = null
	campaign.RUN["curNode"] = n["id"]
	campaign.shipyardScreen(n)
	for k in ["buyMod", "buyTrack", "lateBuy"]:
		if not campaign.screen_acts().any(func(a): return a[0] == k and a[2] == 1): _fail("no open " + k + " button with 640 biomass and 0 credits"); return
	ui.render()
	for i in range(4): await process_frame
	var words := []
	for b in ui.find_children("*", "Button", true, false):
		if b.text.begins_with("Buy for ") or b.text.contains(" for "): words.append(b.text)
	for want in ["Buy for", "○"]:
		if not words.any(func(t): return t.contains(want) and t.ends_with(" biomass")): _fail("no \"" + want + "\" button names biomass: " + str(words)); return
	if headless:
		print("PASS: built CHO-1, biomass prices on refits, tracks and the late market")
		quit(0); return
	if not await _shot("CHO-1_chorus_late_market"): return
	# CHO-2: scroll down to the refits for sale and the class refit tracks
	var tl = ui.find_children("*", "Label", true, false).filter(func(l): return l.text.begins_with("A class refit upgrades"))
	if tl.is_empty(): _fail("no class refit line"); return
	var sp = tl[0].get_parent()
	while sp != null and not (sp is ScrollContainer): sp = sp.get_parent()
	if sp == null: _fail("the shipyard page does not scroll"); return
	sp.scroll_vertical = int(max(0.0, tl[0].global_position.y + float(sp.scroll_vertical) - sp.global_position.y - sp.size.y + 330.0))
	for i in range(4): await process_frame
	if not await _shot("CHO-2_chorus_refits_tracks"): return
	print("Saved CHO-1 and CHO-2")
	quit(0)

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)

func _shot(code: String) -> bool:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_height() > 720:
		img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	if preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(code + ".png"), preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
		_fail("could not write " + code)
		return false
	return true
