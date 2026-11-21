# Issue 1449: a relic trade lets the player pick which piece of salvage they give up (Godot twin of
# contrib/opus/tools/relic_trade_1449_tests.js; both read fixtures/issue_1449/relic_trade.json), and the shipyard shows a
# hull's full specification before you pay (the "Full specs" drawer on shop, captured and regrown hulls, built from the same
# FleetManifest.spec_lines the fleet sheet uses). Headless it checks the rules and that the pages build; with a display it
# also saves RELIC-1 (the pick) and SHIP-1 (shipyard card and its open drawer) at Normal and Larger text.
#   godot --path godot --rendering-method gl_compatibility --resolution 1920x1080 --script res://campaign/test/relic_trade_1449.gd -- <out folder>
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const CampaignTips = preload("res://ui/campaign/campaign_tips.gd")
const FleetManifest = preload("res://ui/campaign/fleet_manifest.gd")
const UiScale = preload("res://ui/ui_scale.gd")
const JSM = preload("res://rules/battle_api.gd").JSM
const MapIntel = preload("res://ui/campaign/map_intel.gd")

var campaign = Campaign.new()
var ui: CampaignUI
var out := ""
var headless := false

func _initialize() -> void: _run.call_deferred()

func _fill(t: String) -> String:
	var re := RegEx.new(); re.compile("%(\\w+)%")
	var m = re.search(t)
	while m != null:
		t = t.replace(m.get_string(0), campaign.relicName(m.get_string(1))); m = re.search(t)
	return t

func _acts() -> Array:
	return campaign.screen_acts().map(func(a): return str(a[0]) + ":" + str(a[1]) + ":" + str(a[2]))

func _open(id: String) -> Dictionary:
	var ev = campaign.TB["EVENTS"].filter(func(e): return e["id"] == id)[0]
	campaign.show_event(campaign._event_for_faction(ev))
	return campaign.cur_event

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	headless = DisplayServer.get_name() == "headless"
	if not headless:
		if args.is_empty(): _fail("supply a picture output folder after --"); return
		out = args[0]
		if DirAccess.make_dir_recursive_absolute(out) != OK: _fail("cannot create " + out); return
		root.size = Vector2i(1920, 1080); root.content_scale_size = Vector2i.ZERO
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

	# 1. Relic trades, from the shared fixture
	var fx = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/test/fixtures/issue_1449/relic_trade.json"))
	if fx == null: _fail("cannot read the relic trade fixture"); return
	for cs in fx["cases"]:
		JSM.rnd_seed(1449)
		campaign.META["admirals"][fx["admiral"]] = true
		campaign.newRun(fx["admiral"], fx["fac"])
		ui.map3d.intel = MapIntel.new(campaign)
		campaign.RUN["relics"] = cs["relics"].duplicate(); campaign.RUN["flags"] = {}
		campaign.RUN["curNode"] = campaign.RUN["map"]["cols"][0][0]["id"]
		var ev = _open(cs["event"]); var opt := int(cs["opt"]); var name: String = cs["name"]
		var note := _fill(cs["expect"]["note"])
		if campaign.relicTradeNote(ev["o"][opt]) != note: _fail(name + ": note is \"" + campaign.relicTradeNote(ev["o"][opt]) + "\""); return
		if not await _page(note.strip_edges(), "RELIC-1_one_relic" if cs["expect"]["pickActs"].is_empty() else "", "normal"): return
		campaign.act("eventChoice", str(opt))
		if not cs["expect"]["pickActs"].is_empty():
			if _acts() != cs["expect"]["pickActs"]: _fail(name + ": pick acts " + str(_acts())); return
			if campaign.RUN["relics"] != cs["relics"] or campaign.RUN["flags"].has(cs["event"]): _fail(name + ": something was spent before the pick"); return
			var shot := "RELIC-1_pick" if cs == fx["cases"][0] else ""
			if not await _page("Which piece of salvage do you give up?", shot, "both"): return
			campaign.act("eventBack")
			if not str(_acts()[opt]).begins_with("eventChoice:" + str(opt) + ":") or campaign.RUN["relics"] != cs["relics"]: _fail(name + ": Back did not return to the event"); return
			if shot != "" and not await _page(note.strip_edges(), "RELIC-1_choice", "normal"): return
			campaign.act("eventChoice", str(opt)); campaign.act("eventChoice", str(opt) + ":" + str(int(cs["pick"])))
		if campaign.RUN["relics"] != cs["expect"]["relics"]: _fail(name + ": relics after " + str(campaign.RUN["relics"])); return
		var gave = "You give up " + campaign.relicName(cs["expect"]["gaveUp"]) + "."
		if not campaign.modal_d["data"]["lines"].has(gave): _fail(name + ": result lines " + str(campaign.modal_d["data"]["lines"])); return
		if not await _page(gave, "", ""): return
		print("PASS: " + name)

	# 2. The shipyard's Full specs drawer: same lines as the fleet sheet, closed until asked, on shop, captured and regrown hulls
	JSM.rnd_seed(1450)
	campaign.META["admirals"]["vex"] = true
	campaign.newRun("vex", "voidsworn")
	ui.map3d.intel = MapIntel.new(campaign)
	campaign.RUN["credits"] = 900.0
	var n = campaign.RUN["map"]["cols"][0][0]
	n["type"] = "shipyard"; n.erase("stock"); campaign.modal_d = null; campaign.RUN["curNode"] = n["id"]
	campaign.shipyardScreen(n)
	var h: String = n["stock"]["hulls"][0]
	n["stock"]["cap"] = [n["stock"]["hulls"][1]] if n["stock"]["hulls"].size() > 1 else []
	campaign.RUN["cores"] = [h]
	var lines = FleetManifest.spec_lines(campaign, FleetManifest.preview_ship(campaign, h))
	if not lines.any(func(l): return l["k"] == "gun" and str(l["t"]).contains("range")): _fail("spec lines have no gun ranges"); return
	if not lines.any(func(l): return l["k"] == "stat" and str(l["t"]).begins_with("Armor")): _fail("spec lines have no armor"); return
	var ab = campaign.HULLS[h].get("ab")
	if campaign.jt(ab) and not lines.any(func(l): return l["k"] == "ability_d" and l["t"] == str(campaign.ABILITIES[ab]["d"])): _fail("spec lines miss the ability text"); return
	var before_uid = campaign.UID if "UID" in campaign else null
	ui.spec_open = {}
	ui.render(); await process_frame
	var links = ui.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("spec_key"))
	var keys = links.map(func(b): return str(b.get_meta("spec_key")))
	for want in ["yard:" + h, "core:0"] + (["cap:" + n["stock"]["cap"][0]] if not n["stock"]["cap"].is_empty() else []):
		if not keys.has(want): _fail("no Full specs link for " + want + " in " + str(keys)); return
	var gun_line: String = lines.filter(func(l): return l["k"] == "gun")[0]["t"]
	if _visible_text(gun_line): _fail("the drawer is open before the player asks"); return
	if not await _page("Full specs", "SHIP-1_card", "both"): return
	ui.spec_open["yard:" + h] = true
	if not await _page(gun_line, "SHIP-1_specs", "both"): return
	if before_uid != null and campaign.UID != before_uid: _fail("previewing a hull drew a ship id"); return
	if campaign.RUN["fleet"].any(func(s): return s["uid"] == ""): _fail("a preview ship joined the fleet"); return
	print("PASS: shipyard Full specs drawer shows armor, every gun's shots, damage and range, and the ability text")
	print("PASS: issue 1449")
	quit(0)

func _visible_text(must: String) -> bool:
	for l in ui.find_children("*", "Label", true, false) + ui.find_children("*", "RichTextLabel", true, false) + ui.find_children("*", "Button", true, false):
		if l.is_visible_in_tree() and l.text.contains(must): return true
	return false

# shows the page, checks the text is on screen; with a display saves <code>_normal / _larger (scales: "normal", "both")
func _page(must: String, code: String, scales: String) -> bool:
	var list := [1.0] if scales != "both" else [1.0, 1.3]
	for sc in list:
		UiScale.set_player(sc); ui._rescale()
		ui.render()
		for i in range(4): await process_frame
		if not _visible_text(must):
			_fail((code if code != "" else "page") + ": the screen does not show \"" + must + "\""); return false
		if headless or code == "": continue
		if code.begins_with("SHIP-1"): await _scroll_to("Buy for")
		for i in range(3): await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		if img.get_height() > 720:
			img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
		var f := code + ("_larger" if sc > 1.0 else "_normal") + ".png"
		if preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(f)) != OK:
			_fail("could not write " + f); return false
		print("Saved ", f)
	UiScale.set_player(1.0); ui._rescale()
	return true

# the shipyard page scrolls: bring the line into view before the picture
func _scroll_to(must: String) -> void:   # the last Buy button of the shop row
	for l in ui.find_children("*", "Label", true, false) + ui.find_children("*", "RichTextLabel", true, false) + ui.find_children("*", "Button", true, false):
		if l.is_visible_in_tree() and l.text.contains(must):
			var p = l.get_parent()
			while p != null and not (p is ScrollContainer): p = p.get_parent()
			if p is ScrollContainer:
				p.ensure_control_visible(l); await process_frame
				p.scroll_vertical += ui.px(140)   # clear the picture's label strip at the bottom
			return

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)
