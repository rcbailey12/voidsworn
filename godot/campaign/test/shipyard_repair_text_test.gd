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
	JSM.rnd_seed(1551)
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
	var cases := [
		["voidsworn", " credit", "New hulls come with a fresh lieutenant."],
		["chorus", " biomass per 2 hull", "New hulls come with a fresh spawn-mind."],
	]
	for c in cases:
		var t := _repair_line(c[0])
		if t.begins_with("ERR "): _fail(c[0] + ": " + t.substr(4)); return
		var cost := t.get_slice(" per 2 hull", 0)   # "Repairs cost 1.2 credits": the price multiplier varies by sector
		if not t.begins_with("Repairs cost ") or not (cost + " per 2 hull").contains(c[1]) or not t.ends_with(c[2]) or (c[0] != "chorus" and cost.contains("biomass")): _fail(c[0] + ": repair line reads \"" + t + "\""); return
		print("ok ", c[0], ": ", t)
	print("PASS: shipyard repair text names credits and a fresh lieutenant, and biomass and a fresh spawn-mind for the Chorus")
	quit(0)

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)
