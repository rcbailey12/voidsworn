# Issue 1551: the shipyard repair line names the right currency and the right new captain. A normal faction pays credits
# and gets "a fresh lieutenant"; the Chorus pays biomass and gets "a fresh spawn-mind". Headless: builds the shipyard page
# and reads its labels.
#   godot --headless --path godot --script res://campaign/test/shipyard_repair_text_test.gd
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const MapIntel = preload("res://ui/campaign/map_intel.gd")

func _initialize() -> void: _run.call_deferred()

func _admiral_for(campaign, fac: String) -> String:
	for id in campaign.TB["ADMIRALS"].keys():
		if str(campaign.TB["ADMIRALS"][id].get("fac", "")) == fac: return str(id)
	return ""

func _repair_line(fac: String) -> String:
	var campaign = Campaign.new()
	var err: String = campaign.load_tables()
	if err != "": return "ERR " + err
	campaign.fixed_clock = true
	var ui = CampaignUI.new(); root.add_child(ui); ui.C = campaign
	ui.teaching = CampaignTips.new(); ui.teaching.disabled = true; ui.add_child(ui.teaching)
	ui.set_process(false); ui.use_3d_map = false
	var adm := _admiral_for(campaign, fac)
	if adm == "": ui.queue_free(); return "ERR no admiral for " + fac
	campaign.rng.rnd_seed(1551)
	campaign.META["admirals"][adm] = true
	campaign.newRun(adm, fac)
	ui.map3d.intel = MapIntel.new(campaign)
	var n = campaign.RUN["map"]["cols"][0][0]
	n["type"] = "shipyard"; n.erase("stock"); campaign.modal_d = null; campaign.RUN["curNode"] = n["id"]
	campaign.shipyardScreen(n)
	var page: Control = ui._shipyard()
	var found := ""
	for l in page.find_children("*", "Label", true, false) + page.find_children("*", "RichTextLabel", true, false):
		if str(l.text).begins_with("Repairs cost "): found = str(l.text); break
	page.free(); ui.queue_free()
	return found

func _run() -> void:
	# The whole label must match exactly; only the sector price is a number we read back (issue 1575 review: no loose prefix).
	const TAIL := " per 2 hull, rounded up. A Mark upgrade adds 20% hull and shields and 15% damage. New hulls come with a fresh {who}."
	var cases := [["voidsworn", "credit", "lieutenant"], ["chorus", "biomass", "spawn-mind"]]
	var num := RegEx.create_from_string("^Repairs cost ([0-9]+(?:\\.[0-9]+)?) ")
	for c in cases:
		var t := _repair_line(c[0])
		if t.begins_with("ERR "): _fail(c[0] + ": " + t.substr(4)); return
		var m := num.search(t)
		if m == null: _fail(c[0] + ": repair line reads \"" + t + "\""); return
		var price := m.get_string(1)
		var unit: String = c[1] if (c[1] == "biomass" or price == "1") else c[1] + "s"
		var want := "Repairs cost " + price + " " + unit + TAIL.replace("{who}", c[2])
		if t != want: _fail(c[0] + ": repair line reads \"" + t + "\", want \"" + want + "\""); return
		print("ok ", c[0], ": ", t)
	# ARTICLE_CASES: same table as contrib/opus/tools/ship_article_1551_tests.js (browser twin)
	var CC = load("res://campaign/campaign.gd")
	for a in [["Ember", true, "The Ember", "Ember"], ["Ember", false, "the Ember", "Ember"], ["The Unbroken", true, "The Unbroken", "Unbroken"],
			["The Unbroken", false, "the Unbroken", "Unbroken"], ["MDV Precedent", true, "MDV Precedent", "MDV Precedent"], ["HNS Relentless", false, "HNS Relentless", "HNS Relentless"]]:
		if CC.ship_with_article(a[0], a[1]) != a[2] or CC.ship_bare(a[0]) != a[3]:
			_fail("ship article: %s -> \"%s\" / \"%s\"" % [a[0], CC.ship_with_article(a[0], a[1]), CC.ship_bare(a[0])]); return
	print("ok ship article: bare, The, MDV and HNS names match the browser table")
	print("PASS: shipyard repair text names credits and a fresh lieutenant, and biomass and a fresh spawn-mind for the Chorus")
	quit(0)

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)
