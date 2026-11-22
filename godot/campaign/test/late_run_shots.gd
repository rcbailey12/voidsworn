# Issue 1178: capture the Sector 3 late market, the Chorus biomass shipyard, the Eclipse recovered cores and the Glasswright
# cullet victory line from the campaign UI. Headless it only checks the pages build; with a display it saves the pictures.
#   godot --path godot --rendering-method gl_compatibility --resolution 1280x720 --script res://campaign/test/late_run_shots.gd -- <out folder>
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

func _start(admiral: String, fac: String, seed_: int) -> void:
	JSM.rnd_seed(seed_)
	campaign.META["admirals"][admiral] = true
	campaign.newRun(admiral, fac)

func _yard(sector: int) -> Dictionary:
	campaign.RUN["sector"] = sector
	var n = campaign.RUN["map"]["cols"][0][0]
	n["type"] = "shipyard"; n.erase("stock")
	for s in campaign.RUN["fleet"]: s["hp"] = floor(campaign.derive(s)["maxHp"] * 0.7)
	campaign.modal_d = null
	campaign.RUN["curNode"] = n["id"]
	campaign.shipyardScreen(n)
	return n

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
	_start("vex", "voidsworn", 1178)
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = campaign
	ui.teaching = CampaignTips.new()
	ui.teaching.disabled = true
	ui.add_child(ui.teaching)
	ui.set_process(false)
	ui.use_3d_map = false
	ui.map3d.intel = MapIntel.new(campaign)

	# 1. Sector 3 late market (Sunward Crusade, 620 credits)
	campaign.RUN["credits"] = 620.0
	_yard(3)
	if not campaign.screen_acts().any(func(a): return a[0] == "lateBuy" and a[2] == 1): _fail("no late market offer is open: page " + str(campaign.page.get("kind")) + " modal " + str(campaign.modal_d) + " acts " + str(campaign.screen_acts().slice(0, 8))); return
	if not await _page("shipyard", "L1178_late_market", "Late market"): return

	# 2. Chorus shipyard paid in biomass
	_start("matriarch", "chorus", 1179)
	campaign.RUN["bio"] = 260.0; campaign.RUN["credits"] = 90.0
	_yard(1)
	if not await _page("shipyard", "B1178_chorus_biomass", "Biomass"): return

	# 3. Eclipse recovered cores
	_start("nekhet", "deathless", 1180)
	var core_tpl = campaign.RUN["fleet"][campaign.RUN["fleet"].size() - 1]["tpl"]
	campaign.RUN["cores"] = [core_tpl]; campaign.RUN["credits"] = 240.0
	_yard(1)
	if not campaign.screen_acts().any(func(a): return a[0] == "restoreCore"): _fail("no core regrow button"); return
	if not await _page("shipyard", "E1178_eclipse_cores", "Recovered cores"): return

	# 4. Glasswright victory with cullet from a lost ship
	_start("aelith", "ithar", 1181)
	campaign.mapScreen()
	campaign.act("enterNode", campaign.availableNodes()[0])
	var lost = null
	for u in campaign.B["units"]:
		if u["side"] == "player" and u.get("ship") != null and u["ship"]["uid"] != campaign.RUN["flagUid"]: lost = u; break
	if lost == null: _fail("no escort to lose"); return
	lost["dead"] = true; lost["hp"] = 0
	campaign.act("battle", "win")
	if campaign.modal_d != null and campaign.modal_d["kind"] == "prize": campaign.act("prizeConfirm")
	if campaign.modal_d == null or campaign.modal_d["kind"] != "victory": _fail("no victory card"); return
	if not await _page("victory", "C1178_glass_cullet", "Cullet from the lost glass"): return
	print("PASS: built all four issue 1178 pictures")
	quit(0)

func _page(kind: String, code: String, must: String) -> bool:
	ui.render()
	for i in range(4): await process_frame
	var found = ui.find_children("*", "Label", true, false).any(func(l): return l.text.to_lower().contains(must.to_lower())) \
		or ui.find_children("*", "RichTextLabel", true, false).any(func(l): return l.text.to_lower().contains(must.to_lower()))
	if not found:
		_fail(code + ": the " + kind + " page does not show \"" + must + "\"")
		return false
	if headless:
		print("Built ", code)
		return true
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_height() > 720:
		img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
	if preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(code + ".png"), preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
		_fail("could not write " + code)
		return false
	print("Saved ", code)
	return true

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)
