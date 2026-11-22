# Issue 1290: the late-balance fixes from the PR 1276 review. Checks that the late market never offers the Smuggler's ledger, the Scrap rig or
# the logbook, that a ship regrown from an Eclipse core decommissions for 0 until it has fought a battle (then for the usual
# 35%, capped at what the regrow cost since issue 1384), and that the Chorus decommission into biomass. Headless it checks the rules and that the pages build; with a display it
# also saves the two decommission pictures.
#   godot --path godot --rendering-method gl_compatibility --resolution 1280x720 --script res://campaign/test/late_fixes_1290.gd -- <out folder>
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
	ui = CampaignUI.new()
	root.add_child(ui)
	ui.C = campaign
	ui.teaching = CampaignTips.new()
	ui.teaching.disabled = true
	ui.add_child(ui.teaching)
	ui.set_process(false)
	ui.use_3d_map = false

	# 1. The late market never offers the ledger or the logbook, at any yard column or battle count
	_start("vex", "voidsworn", 1290)
	ui.map3d.intel = MapIntel.new(campaign)
	campaign.RUN["sector"] = 3
	for col in range(8):
		for b in range(12):
			campaign.RUN["stats"]["battles"] = b
			var st = campaign.lateStock({"col": col})
			for r in st["relics"]:
				if r == "ledger" or r == "logbook" or r == "salvage": _fail("late market offered " + r + " at col " + str(col) + " battles " + str(b)); return
	print("PASS: no ledger, logbook or Scrap rig in 96 late market rolls")

	# 1b. An older save's yard stock (fixtures/issue_1290/old_yard.json, shared with contrib/opus/tools/late_stock_1290_tests.js):
	# the stored ledger is never sold, the bought logbook stays bought, the command point stays taken, the stock is not rewritten
	var fx = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/fixtures/issue_1290/old_yard.json"))
	if fx == null: _fail("cannot read the old yard fixture"); return
	for k in fx["run"]: campaign.RUN[k] = fx["run"][k].duplicate(true) if fx["run"][k] is Array else fx["run"][k]
	var oy = {"id": "y", "col": 2, "type": "shipyard", "stock": fx["stock"].duplicate(true)}
	campaign.yard_node = oy
	var offers = campaign.lateShopOffers()
	for o in offers:
		if fx["expect"]["hidden"].has(o.get("r")): _fail("old yard still offers " + str(o.get("r"))); return
	var sale = offers.filter(func(o): return o["kind"] == "relic" and o["ok"]).map(func(o): return o["r"])
	var shown = offers.filter(func(o): return o["kind"] == "relic" and o["done"]).map(func(o): return o["r"])
	if sale != fx["expect"]["forSale"] or shown != fx["expect"]["boughtShown"]: _fail("old yard offers " + str(sale) + " bought " + str(shown)); return
	if offers.filter(func(o): return o["kind"] == "cp")[0]["done"] != fx["expect"]["cpDone"]: _fail("old yard command point state changed"); return
	campaign.ACT_lateBuy("relic:ledger")
	if float(campaign.RUN["credits"]) != float(fx["expect"]["creditsAfterLedgerTry"]) or campaign.RUN["relics"].has("ledger"): _fail("the stored ledger was sold"); return
	var mc = offers.filter(func(o): return o.get("r") == "martyr")[0]["cost"]
	campaign.ACT_lateBuy("relic:martyr")
	if float(campaign.RUN["credits"]) != 500.0 - float(mc) or not campaign.RUN["relics"].has("martyr"): _fail("buying the martyr from the old yard failed"); return
	if oy["stock"]["late"]["relics"] != fx["stock"]["late"]["relics"] or oy["stock"]["late"]["bought"] != ["logbook", "martyr"]: _fail("the old yard stock was rewritten"); return
	print("PASS: an older save's yard never sells the ledger, keeps its history, and still sells the martyr")

	# 2. Eclipse: a regrown ship decommissions for 0 until it has fought
	_start("nekhet", "deathless", 1291)
	var tpl = campaign.RUN["fleet"][campaign.RUN["fleet"].size() - 1]["tpl"]
	campaign.RUN["cores"] = [tpl]; campaign.RUN["credits"] = 600.0; campaign.RUN["cpCap"] = 99.0
	_yard(1)
	campaign.act("restoreCore", "0")
	var grown = campaign.RUN["fleet"][campaign.RUN["fleet"].size() - 1]
	if not grown.get("regrown"): _fail("restoreCore did not mark the ship regrown"); return
	if campaign.sellValue(grown) != 0.0: _fail("a regrown ship sells for " + str(campaign.sellValue(grown))); return
	campaign.act("sellShip", grown["uid"])
	if not await _page("shipyard", "D1290_regrown_decommission", "nothing to strip"): return
	var c0 = float(campaign.RUN["credits"])
	campaign.act("sellConfirm", grown["uid"])
	if float(campaign.RUN["credits"]) != c0: _fail("selling a regrown ship paid " + str(float(campaign.RUN["credits"]) - c0)); return
	print("PASS: a regrown ship decommissions for 0")
	campaign.RUN["cores"] = [tpl]; campaign.RUN["credits"] = 600.0
	_yard(1)
	campaign.act("restoreCore", "0")
	grown = campaign.RUN["fleet"][campaign.RUN["fleet"].size() - 1]
	campaign.act("leaveYard")
	var next = campaign.availableNodes()[0]
	campaign.findNode(next)["type"] = "battle"
	campaign.act("enterNode", next)
	if campaign.B == null: _fail("no battle started: page " + str(campaign.page.get("kind"))); return
	campaign.act("battle", "win")
	if grown.get("regrown"): _fail("the regrown mark survived a battle"); return
	if campaign.sellValue(grown) != minf(float(grown["corePaid"]), campaign.prizeScrap(grown["tpl"])): _fail("after a battle the ship sells for " + str(campaign.sellValue(grown))); return   # issue 1384: at most its regrow cost
	print("PASS: after one battle it decommissions for ", campaign.sellValue(grown))

	# 3. Chorus: decommission pays biomass, not credits
	_start("matriarch", "chorus", 1292)
	campaign.RUN["bio"] = 100.0; campaign.RUN["credits"] = 50.0
	_yard(1)
	var ship = campaign.RUN["fleet"][campaign.RUN["fleet"].size() - 1]
	var v = campaign.prizeScrap(ship["tpl"])
	campaign.act("sellShip", ship["uid"])
	if not await _page("shipyard", "B1290_chorus_decommission", str(int(v)) + " biomass"): return
	campaign.act("sellConfirm", ship["uid"])
	if float(campaign.RUN["bio"]) != 100.0 + v or float(campaign.RUN["credits"]) != 50.0: _fail("Chorus sell: bio " + str(campaign.RUN["bio"]) + " credits " + str(campaign.RUN["credits"])); return
	print("PASS: Chorus decommission pays ", v, " biomass")
	print("PASS: issue 1290 late fixes")
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
