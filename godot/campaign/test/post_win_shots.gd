# Issue 1177: capture the victory, promotions, drydock and field repairs cards from the campaign UI.
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const MapIntel = preload("res://ui/campaign/map_intel.gd")
const REWARD_ACTIONS := ["prizeConfirm", "takeSalvage", "rewardNext", "takeBoon", "takeMod", "takeRelic"]

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
	JSM.rnd_seed(1)
	campaign.newRun("vex", "voidsworn")
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = campaign
	# The card check uses seeded runs and leaves the player's teaching preferences alone.
	ui.teaching = CampaignTips.new()
	ui.teaching.disabled = true
	ui.add_child(ui.teaching)
	ui.set_process(false)
	ui.use_3d_map = false
	ui.map3d.intel = MapIntel.new(campaign)

	campaign.mapScreen()
	campaign.act("enterNode", campaign.availableNodes()[0])
	# Stage a weakness found during the Nemesis fight so the capture checks the victory label.
	var nem := campaign.nemBattleCfg()
	var hidden: Array = nem["weak"].filter(func(key): return not nem["revealed"].has(key))
	if hidden.size() < 2:
		_fail("the seeded Nemesis needs two hidden weaknesses"); return
	campaign.B["cfg"]["nemesis"] = nem
	campaign.B["nemFound"] = [hidden.back()]
	campaign.act("battle", "win")
	if campaign.modal_d["kind"] == "prize": campaign.act("prizeConfirm")
	if not await _card("victory", "V1177_victory"): return
	for i in range(10):
		if campaign.modal_d == null or campaign.modal_d["kind"] == "promotions": break
		var options: Array = campaign.screen_acts().filter(func(a): return a[2] == 1 and a[0] in REWARD_ACTIONS)
		if options.is_empty(): break
		campaign.act(options[0][0], options[0][1])
	if campaign.modal_d == null or campaign.modal_d["kind"] != "promotions" or campaign.modal_d["data"]["ships"].size() < 2:
		_fail("the seeded win must put at least two captains on one promotion card"); return
	if not await _card("promotions", "P1177_promotions"): return

	for stop in [["drydock", "D1177_drydock"], ["field", "F1177_field_repairs"]]:
		JSM.rnd_seed(1177)
		campaign.newRun("vex", "voidsworn")
		var n = campaign.RUN["map"]["cols"][0][0]
		n["type"] = stop[0]
		for s in campaign.RUN["fleet"]: s["hp"] = floor(campaign.derive(s)["maxHp"] / 2.0)
		campaign.mapScreen()
		campaign.act("enterNode", n["id"])
		if not await _card("repair_stop", stop[1]): return
	print("PASS: built all four issue 1177 cards")
	quit(0)

func _card(kind: String, code: String) -> bool:
	if campaign.modal_d == null or campaign.modal_d["kind"] != kind:
		_fail("the campaign did not show " + kind)
		return false
	ui.render()
	for i in range(4): await process_frame
	if ui.modal_box.get_child_count() != 2:
		_fail("the campaign did not draw " + code)
		return false
	if kind == "victory" and not ui.modal_box.find_children("*", "Label", true, false).any(func(label): return label.text.begins_with("Weakness confirmed: ")):
		_fail("the victory card did not draw the weakness confirmation")
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
