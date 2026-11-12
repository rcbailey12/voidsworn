extends SceneTree
# Run with --headless, or pass -- <screenshot directory> with a renderer.
const Campaign = preload("res://campaign/campaign.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
var fails := 0
var screenshot_dir := ""

func check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: " + message)

func text_of(node: Node) -> String:
	var text := ""
	if node is Label or node is RichTextLabel: text += node.text + "\n"
	for child in node.get_children(): text += text_of(child)
	return text

# the words the orders sheet lays out (the battle HUD's only screen since issue 578)
func sheet_text(h) -> String:
	h.ledger.layout()
	var text := ""
	for it in h.ledger.items: text += str(it["t"]) + "\n"
	return text

func shot(name_: String) -> void:
	if screenshot_dir == "": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(screenshot_dir.path_join(name_ + ".png"))

func settle() -> void:
	for i in range(4): await process_frame

func choose(c, fac: String, i: int) -> void:
	var row: Dictionary = c.TB.STORY_BEAT3[fac]
	var id = row["spotlights"].keys()[0]
	c.META["admirals"][id] = true  # the harness owns the admiral it flies
	c.newRun(id, fac); c.RUN["sector"] = 3
	c.mapScreen(); c.showBeat3(); c.act("eventChoice", str(i))

func real_battle(c, api, extra := {}) -> Dictionary:
	c.battle_mode = "external"
	c.battle_setup = func(run, cfg):
		api.new_battle(run, cfg)
		return api.R.B
	var cfg = {"kind": "battle", "fac": "hegemony", "col": 1, "seed": 110, "obj": "rout", "shape": "open", "map": "belt", "enemies": [{"tpl": "h_picket"}]}
	cfg.merge(extra, true); c.battleScreen(cfg)
	return c.B

func battle_shot(api, ui, name_: String) -> void:
	if screenshot_dir == "": return
	var scene = load("res://scenes/battle/battle.tscn").instantiate()
	scene.external = true; scene.in_campaign = true; scene.tips_off = true
	scene.args["quality"] = "low"
	ui.hide(); root.add_child(scene); scene.begin_with(api)
	var deadline = Time.get_ticks_msec() + 60000
	while scene.warming and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not scene.warming, "battle screenshot finishes loading")
	await settle(); await shot(name_)
	var flag = api.R.B["units"].filter(func(u): return u["side"] == "player" and bool(u.get("pflag", false)))[0]
	scene.select(flag["id"]); await settle()
	var shown := sheet_text(scene.hud)
	for line in api.R.storyModifierLines(flag): check(shown.contains(line), "ship status shows " + line)
	await shot(name_ + "_status")
	scene.queue_free(); await settle(); ui.show()

func reward_checks(c, ui) -> void:
	var api = BattleAPI.new()
	check(api.load_rules() == "", "battle rules load")
	for row in [["voidsworn", 0, 1.25, "+25%"], ["chorus", 0, 0.9, "-10%"], ["chorus", 1, 1.1, "+10%"]]:
		choose(c, row[0], row[1]); await settle()
		check(text_of(ui).contains(row[3]), str(row[0]) + " numeric outcome")
		var pending = c.clone(c.RUN["storyNext"])
		c.RUN = c.clone(c.SAVED_RUN)
		check(c.RUN["storyNext"] == pending, "pending modifier survives reload")
		if row[0] == "chorus" and row[1] == 0: c.act("storyCore"); c.act("boonDecline")
		var b = real_battle(c, api); var r = api.R
		check(c.RUN.get("storyNext") == null and c.SAVED_RUN.get("storyNext") == null, "battle entry saves consumption")
		check(" ".join(PackedStringArray(r.storyModifierLines())).contains(row[3]), "battle modifier visible")
		for u in b["units"]:
			var wanted = row[2] if u["side"] == "player" and (row[0] != "voidsworn" or c.jt(u.get("pflag"))) else 1.0
			check(r.storyDamageMult(u) == wanted, "only intended ships receive damage modifier")
			if u["weapons"].is_empty(): continue
			var t = b["units"].filter(func(t): return t["side"] != u["side"])[0]
			var actual = r.dmgMult(u, u["weapons"][0], t, false)
			var mods = b["cfg"]["storyMods"]; b["cfg"].erase("storyMods")
			var base = r.dmgMult(u, u["weapons"][0], t, false); b["cfg"]["storyMods"] = mods
			check(actual == base * wanted, "exact weapon damage multiplier")
		check(r.storyDamageMult({"side": "player", "isSq": true}) == (1.0 if row[0] == "voidsworn" else row[2]), "later wings share fleet damage only")
		await battle_shot(api, ui, str(row[0]) + ("_power_battle" if row[0] == "voidsworn" else "_damage_down_battle" if row[1] == 0 else "_damage_up_battle"))
		c.RUN = c.clone(c.SAVED_RUN); real_battle(c, api)
		check(api.R.storyDamageMult(c.B["units"][0]) == 1.0, "following battle is normal")
	choose(c, "hegemony", 0)
	var b = real_battle(c, api); var r = api.R
	var ships = b["units"].filter(func(u): return u["side"] == "player" and not c.jt(u.get("isSq")))
	var target = b["units"].filter(func(u): return u["side"] == "enemy")[0]
	ships[1]["q"] = ships[0]["q"]; ships[1]["r"] = ships[0]["r"]
	r.syncMarkShot(ships[0], target)
	check(not r.inSync(ships[0]) and not r.syncOn(ships[1], target), "round 1 sync is off")
	check(b["syncMark"]["player"].is_empty(), "disabled shots leave no sync marks")
	check(r.inSync(target), "enemy synchronization stays enabled")
	await battle_shot(api, ui, "hegemony_sync_off_battle")
	b["round"] = 2; r.syncMarkShot(ships[0], target)
	check(r.inSync(ships[0]) and r.syncOn(ships[1], target), "round 2 sync works normally")
	for pair in [["corsair", "rook"], ["chorus", "hunger"]]:
		for take in [true, false]:
			choose(c, pair[0], 0)
			var credits = c.RUN["credits"]; var boons = c.RUN["boons"].size(); var pos = c.RUN["pos"]
			check(c.RUN["reward"]["rw"]["p"] == pair[1], "offer uses the faction core")
			c.RUN = c.clone(c.SAVED_RUN); c.act("storyCore"); await settle()
			check(c.RUN["credits"] == credits and c.z0(c.RUN.get("boonRerolls")) == 0, "core offer has no charge or reroll spent")
			var offer = c.clone(c.W["boonOffer"])
			check(text_of(ui).contains(c.PATRONS[pair[1]]["n"]), "offering core is shown")
			if take: await shot(str(pair[0]) + "_core_offer")
			c.RUN = c.clone(c.SAVED_RUN); c.resumeReward()
			check(c.W["boonOffer"] == offer, "reload keeps the same offer")
			c.act("takeBoon", "0") if take else c.act("boonDecline")
			check(c.RUN["boons"].size() == boons + (1 if take else 0), "take adds one protocol")
			check(c.RUN["credits"] == credits + (0 if take else 60), "decline pays 60 credits")
			check(c.RUN["reward"] == null and c.RUN["pos"] == pos, "story offer returns without completing a map node")
			c.RUN = c.clone(c.SAVED_RUN); check(c.RUN["reward"] == null, "resolved offer stays resolved")
		choose(c, pair[0], 0)
		c.RUN["boons"] = c.BOONS.keys().map(func(id): return {"id": id, "r": 0})
		var credits = c.RUN["credits"]; c.act("storyCore")
		check(c.RUN["credits"] == credits + 60 and c.RUN["reward"] == null and not c.resumeReward(), "exhausted pool pays once")
	for extra in [{"kind": "battle"}, {"kind": "elite"}, {"kind": "boss"}, {"kind": "elite", "eventRelic": true}, {"kind": "battle", "nemesis": {"fac": "hegemony", "name": "Test", "title": "Admiral", "traits": [], "weak": [], "revealed": [], "adapt": []}}]:
		choose(c, "voidsworn", 0); real_battle(c, api, extra)
		check(c.B["cfg"]["storyMods"]["power"] and c.RUN["storyNext"] == null, "any battle kind consumes the reward")
	for result in ["win", "loss", "retreat"]:
		choose(c, "voidsworn", 0); real_battle(c, api)
		var run = c.RUN; c.finish_battle(result, c.B)
		check(run["storyNext"] == null, result + " does not restore the modifier")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: screenshot_dir = args[0]
	if screenshot_dir != "": DirAccess.make_dir_recursive_absolute(screenshot_dir)
	var c = Campaign.new()
	check(c.load_tables() == "", "campaign tables load")
	c.persist_on = false
	var ui = UI.new()
	ui.use_3d_map = false  # Text screen checks do not need sector models.
	root.add_child(ui)
	ui.bind(c)
	await process_frame
	for fac in c.RUN_FACTIONS:
		var row: Dictionary = c.TB.STORY_BEAT3[fac]
		var count := 0
		for id in c.ADMIRALS:
			if c.ADMIRALS[id]["fac"] != fac: continue
			count += 1
			c.META["admirals"][id] = true  # the harness owns the admiral it flies
			c.newRun(id, fac); c.RUN["sector"] = 3
			c.mapScreen()
			check(c.showBeat3(), str(id) + " opens decision")
			await settle()
			var text := text_of(ui)
			check(text.contains(row["spotlights"][id]), str(id) + " spotlight renders")
			for line in row["lines"]: check(text.contains(line), str(id) + " spoken line renders")
			check(not text.contains("{rival}") and not text.contains("undefined"), str(id) + " no placeholder")
			if count == 1: await shot(str(fac) + "_decision")
		check(count == 4, str(fac) + " four admirals")
		for i in range(2):
			var id = row["spotlights"].keys()[0]
			c.META["admirals"][id] = true  # the harness owns the admiral it flies
			c.newRun(id, fac); c.RUN["sector"] = 3; c.mapScreen(); c.showBeat3()
			c.act("eventChoice", str(i))
			check(c.RUN["flags"].get(row["id"]) == str(i), str(fac) + " shipped choice id")
			c.RUN = c.clone(c.SAVED_RUN)
			check(c.beat3Card().is_empty(), str(fac) + " saved choice does not replay")
			check(c.beat3Debrief() == row["debrief"], str(fac) + " battle debrief text")
			await settle()
			check(text_of(ui).contains(c.beat3Text(row["o"][i]["tx"])), str(fac) + " result text renders")
			if i == 0: await shot(str(fac) + "_result")
			c.rewardFlow({"cfg": {"kind": "battle", "fac": "hegemony"}, "kills": 2, "rounds": 4, "lost": [], "xp": []})
			await settle()
			check(text_of(ui).contains(row["debrief"]), str(fac) + " battle debrief renders")
			if i == 0: await shot(str(fac) + "_battle_debrief")
		for won in [false, true]:
			var id = row["spotlights"].keys()[0]
			c.META["admirals"][id] = true  # the harness owns the admiral it flies
			c.newRun(id, fac); c.RUN["sector"] = 3
			c.endRun(won)
			await settle()
			check(text_of(ui).contains(row["learning"]), str(fac) + " learning renders after " + str(won))
			await shot(str(fac) + ("_win" if won else "_loss"))
	await reward_checks(c, ui)
	ui.queue_free()
	print("PASS: beat 3 screens, all five rewards, exact damage, round 1 sync, free core offers, reloads, all battle kinds and win/loss/retreat expiry." if fails == 0 else "FAIL: %d checks" % fails)
	quit(0 if fails == 0 else 1)
