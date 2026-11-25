extends SceneTree
# Issue 1905: the real reward and shipyard cards, with a cold Continue from the saved text.
const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
const REFIT := "prow"

class RewardUI extends CampaignUI:
	# Continue can open the map behind the reward. Keep its 3D scene out of this test.
	func _map() -> Control: return Control.new()

var C
var ui: CampaignUI
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func frames() -> void:
	for i in 5: await process_frame

func campaign():
	var c = Campaign.new()
	var err: String = c.load_tables()
	if err != "":
		printerr(err)
		quit(1)
		return null
	c.fixed_clock = true
	c.teaching_tips = false
	return c

func bind(c) -> void:
	if is_instance_valid(ui):
		root.remove_child(ui)
		ui.queue_free()
	C = c
	ui = RewardUI.new()
	ui.use_3d_map = false
	root.add_child(ui)
	ui.bind(C)

func reload() -> void:
	var saved: String = C.save_text()
	var fresh = campaign()
	fresh.load_save_text(saved)
	bind(fresh)
	C.act("continueRun")
	await frames()

func fixture() -> void:
	Campaign.JSM.rnd_seed(1905)
	C.newRun("vex", "voidsworn")
	var ship = C.newShip("penitent")
	ship["name"] = "Quiet Resolve"
	ship["hp"] = float(ship["hp"]) - 10
	C.RUN["fleet"] = [ship]
	C.RUN["inventory"] = []
	C.RUN["credits"] = 500
	C.ensureFlagship()
	C.mapScreen()

func kind() -> String:
	return C.modal_d["kind"] if C.modal_d != null else ""

func control(action: String, arg := "", scope: Node = null) -> Control:
	if scope == null: scope = ui.modal_box
	for node in scope.find_children("*", "Control", true, false):
		if node.get_meta("press_act", "") == action and node.get_meta("press_arg", "") == arg:
			return node
	return null

func click(action: String, arg := "", scope: Node = null) -> bool:
	var button := control(action, arg, scope)
	check(button != null, "button present for " + action + " " + arg)
	if button == null: return false
	button.emit_signal("pressed")
	return true

func words() -> String:
	var lines := PackedStringArray()
	for node in ui.modal_box.find_children("*", "Label", true, false):
		lines.append(node.text)
	return "\n".join(lines)

func victory(wreck: Dictionary, offer: Dictionary) -> void:
	var node = C.RUN["map"]["cols"][0][0]
	node["rw"] = offer
	C.RUN["pos"] = node["id"]
	C.RUN["curNode"] = node["id"]
	C.rewardFlow({"cfg": {"kind": "battle", "node": node["id"]}, "kills": 1, "rounds": 3, "lost": [], "xp": [], "wrecks": [wreck]})

func captain_loss_check() -> void:
	fixture()
	for row in [["Cold Reckoning", "Lucan Ivers"], ["Iron Wake", "Octavia Vale"]]:
		var ship: Dictionary = C.newShip("penitent")
		ship["name"] = row[0]
		ship["cap"]["name"] = row[1]
		C.RUN["fleet"].append(ship)
	var node: Dictionary = C.RUN["map"]["cols"][0][0]
	C.RUN["pos"] = node["id"]
	C.RUN["curNode"] = node["id"]
	C.stub_start({"kind": "battle", "node": node["id"], "fac": "hegemony", "seed": 1402})
	for unit in C.B["units"].slice(1, 3):
		unit["dead"] = true
		unit["hp"] = 0
	Campaign.JSM.rnd_seed(8)   # the first captain escapes and the second falls
	C.finishBattle("win")
	await frames()
	var losses: String = "Lost: the Cold Reckoning, the Iron Wake and Octavia Vale."
	var escape_line: String = "Captain Lucan Ivers escaped, wounded."
	check(words().contains(losses) and words().contains(escape_line), "C19: victory lists the lost hulls and fallen captain, then the escaped captain")
	await reload()
	check(words().contains(losses) and words().contains(escape_line), "C19: the same captain fates appear after a cold Continue")
	for loss in C.RUN["reward"]["victory"]["summary"]["lost"]:
		loss.erase("escaped")   # the victory data shape before C19
	C.saveRun()
	await reload()
	check(words().contains(losses) and words().contains(escape_line), "C19: a legacy reward save recovers the escaped captain from the reserve")
	C.RUN["fleet"].append(C.newShip("penitent"))
	C.saveRun()
	await reload()
	check(words().contains(losses) and words().contains(escape_line), "C19: a legacy reward still shows the escape after the captain takes a new hull")

func promotion_words_check() -> void:
	fixture()
	var ship: Dictionary = C.RUN["fleet"][0]
	ship["cap"]["pending"] = 1
	ship["cap"]["offer"] = ["steady", "helm"]
	var steady := "Distance starts reducing this ship's accuracy 2 hexes later."
	var helm := "This ship gains 1 movement point."
	C.promotionsStep()
	await frames()
	check(kind() == "promotions" and words().contains(steady) and words().contains(helm), "C39: the battle promotion card says what each perk does for the ship")
	C.promoteModal(ship["uid"], func(): pass)
	await frames()
	check(kind() == "promote" and words().contains(steady) and words().contains(helm), "C39: the single-captain card uses the same copy")
	var rules = preload("res://rules/rules.gd").new()
	check(rules.load_tables("res://rules/data/tables.json") == "" and rules.PERKS == C.PERKS, "C39: both Godot perk tables agree")

# Issue 2095: build a real Spread Pattern burst with the rules, not a hand-written log.
# A missed torpedo bursts on the aimed hull and every hull within 1 hex of it. The aimed hull
# and one neighbour die in the burst; a third enemy is killed by the same attacker before the
# burst and is not caught by it. The rules mark only the hulls the burst actually killed.
func splash_checks() -> void:
	var api = BattleAPI.new()
	var err: String = api.load_rules()
	check(err == "", "the rules load for the splash fixture")
	if err != "": return
	var R = api.R
	var attempt := 0
	while attempt < 40:
		attempt += 1
		api.new_battle_scenario({"seed": 20 + attempt, "admiral": "vex", "fac_player": "voidsworn", "fleet": ["harrow"],
			"fac": "hegemony", "enemies": ["h_picket", "h_picket", "h_picket"], "obj": "rout", "shape": "open",
			"map": "open", "dep": "line", "kind": "battle", "sector": 1, "boons": [{"id": "e_spread", "r": 0}]})
		var B = R.B
		B["cp0"] = null   # no rout ending in the middle of the burst
		B["terrain"] = {}
		var attacker = null; var foes := []
		for u in B["units"]:
			if R.jt(u.get("isSq")): continue
			if u["side"] == "player": attacker = u
			else: foes.append(u)
		if attacker == null or foes.size() < 3: continue
		var aimed = foes[0]; var neighbour = foes[1]; var unrelated = foes[2]
		attacker["name"] = "Splash Ship"
		aimed["name"] = "Aimed Hull"; neighbour["name"] = "Near Hull"; unrelated["name"] = "Unrelated Kill"
		# The attacker fires east from (10,6); the aimed hull is 3 hexes ahead with two neighbours.
		attacker["q"] = 10; attacker["r"] = 6; attacker["facing"] = 0
		aimed["q"] = 13; aimed["r"] = 6
		neighbour["q"] = 14; neighbour["r"] = 6
		unrelated["q"] = 13; unrelated["r"] = 7
		for f in foes:
			f["dead"] = false; f["hp"] = 1; f["shp"] = 0; f["sh"] = [0, 0, 0, 0]; f["killCause"] = null; f.erase("splashKill")
			f["ev"] = 45   # the torpedo shot misses (5% hit), as Spread Pattern needs
		var wi := -1
		for i in range(attacker["weapons"].size()):
			if attacker["weapons"][i]["k"] == "torp": wi = i; break
		if wi < 0: continue
		# The same attacker kills this hull outside the burst. The log never names the attack.
		unrelated["killCause"] = "big"; R.killUnit(unrelated, attacker)
		var w = attacker["weapons"][wi]; w["fired"] = false; w["cdLeft"] = 0; w["off"] = 0
		R.fireWeapon(attacker, wi, aimed)
		var burst := false
		for entry in B["log"]:
			if String(entry.get("m", "")).contains(", catching "): burst = true; break
		if not (burst and R.jt(aimed.get("dead")) and R.jt(neighbour.get("dead")) and R.jt(aimed.get("splashKill")) and R.jt(neighbour.get("splashKill"))): continue
		check(C._heavy_wreck_cause(aimed, B["log"]) == "Torpedo strike", "a Spread Pattern burst credits the hull it was aimed at")
		check(C._heavy_wreck_cause(neighbour, B["log"]) == "Torpedo strike", "a Spread Pattern burst credits a neighbour it actually hit")
		check(C._heavy_wreck_cause(unrelated, B["log"]) == "", "an unrelated heavy kill by the same attacker keeps the generic wording")
		check(unrelated["killCause"] == "big" and not R.jt(unrelated.get("splashKill")), "the unrelated kill is heavy and carries no burst mark")
		return
	check(false, "the splash fixture never produced a real Spread Pattern burst kill")

func wreck_checks() -> void:
	var ship := {"name": "Broken Crown", "killedBy": "Quiet Resolve"}
	var ram: String = C._heavy_wreck_cause(ship, [{"m": "Quiet Resolve rams Broken Crown at full speed: 30 to its prow, 10 back to the ram."}])
	var torpedo: String = C._heavy_wreck_cause(ship, [{"m": "Torpedoes from Quiet Resolve reach Broken Crown: 36 hull."}])
	check(ram == "Rammed" and torpedo == "Torpedo strike", "the shared big kill class is distinguished by the battle log")
	var stray: String = C._heavy_wreck_cause(ship, [{"m": "Torpedoes from Quiet Resolve reach Broken Crown (a stray hit in the lane): 36 hull."}])
	check(stray == "Torpedo strike", "a stray torpedo uses the same wreck wording")
	# issue 2095: a real Spread Pattern burst, produced by the rules, credits the aimed-at hull and a
	# neighbour it actually hit, and leaves an unrelated heavy kill by the same ship on the generic wording.
	splash_checks()
	for row in [
		["big", ram, "Rammed"],
		["big", torpedo, "Torpedo strike"],
		["big", "", "Blown apart"],
		["flay", "", "Unmade by null fire"],
		["melt", "", "Dissolved"],
		["tidal", "", "Torn apart by the dead star"],
	]:
		fixture()
		var w := {"name": ship["name"], "tpl": "penitent", "cp": 2, "cause": row[0], "wk": ["battery"]}
		if row[1] != "": w["impact"] = row[1]
		victory(w, {"k": "cred"})
		await frames()
		var card := words()
		check(card.contains(row[2] + ": no module or hull recovered, +30% credits."), "wreck names cause and credits bonus for " + row[2])
		check(card.contains("Strip wreck for credits") and card.contains("+36 credits"), "exact rounded credit payout is shown")
		check(control("takeSalvage", "0:mod") == null and control("takeSalvage", "0:tow") == null, "only credits are offered for a scrapped wreck")
		var credits: float = C.RUN["credits"]
		click("takeSalvage", "0:cred")
		check(C.RUN["credits"] == credits + 36 and C.RUN["inventory"].is_empty(), "claim pays the existing credit amount once")

func blocked_tow_check() -> void:
	fixture()
	C.RUN["fac"] = "corsair"
	var towable: Array = C.HULLS.keys().filter(func(id):
		return C.HULLS[id].get("fac") == "corsair" and float(C.HULLS[id]["cp"]) <= 2 and C.factionGate("corsair", id) == null)
	check(not towable.is_empty(), "the fixture has a towable Hullbreaker hull")
	if towable.is_empty(): return
	var hull: String = towable[0]
	var cp: float = C.HULLS[hull]["cp"]
	C.RUN["cpCap"] = C.fleetCP() + cp
	victory({"name": "Broken Crown", "tpl": hull, "cp": cp, "cause": "blast"}, {"k": "cred"})
	await frames()
	check(control("takeSalvage", "0:tow") != null, "an intact Hullbreaker wreck can still be towed with room")
	# The wreck yield was recorded before a prize took the last command points.
	C.RUN["cpCap"] = C.fleetCP()
	C.victoryCard()
	await frames()
	check(control("takeSalvage", "0:tow") == null and words().contains("No command points left to tow this wreck."), "the card explains a tow blocked by the fleet's current capacity")
	check(control("takeSalvage", "0:cred") != null, "the unchanged credits choice is still available")

func won_checks() -> void:
	fixture()
	var ship = C.RUN["fleet"][0]
	var uid: String = ship["uid"]
	C.RUN["inventory"] = [REFIT]
	C.fleetScreen("map")
	C.act("equip", "0:" + uid)
	var manifest_hull: float = ship["hp"]

	fixture()
	ship = C.RUN["fleet"][0]; uid = ship["uid"]
	victory({"name": "Broken Crown", "tpl": "penitent", "cp": 2, "cause": "blast"}, {"k": "mod"})
	C.RUN["reward"]["modOffer"] = [REFIT, "hangar"]
	await frames()
	click("takeSalvage", "0:cred")
	await frames()
	check(kind() == "mod" and C.RUN["inventory"].is_empty(), "the won offer opens without a grant")
	check(control("fitRewardRefit", "hangar:" + uid) == null, "incompatible hulls are excluded even with a free slot")
	C.W["relicChoice"] = ["compass"]
	C.RUN["reward"]["relics"] = ["compass"]
	C.saveRun()
	await reload()
	check(kind() == "mod" and C.modal_d["data"]["opts"] == [REFIT, "hangar"], "cold Continue reopens the same won offer")
	var fit := control("fitRewardRefit", REFIT + ":" + uid) as Button
	check(fit != null and fit.text == "Fit onto Quiet Resolve", "the real reward card names the compatible ship")
	if fit == null: return
	fit.pressed.emit()
	check(kind() == "relic" and C.RUN["reward"].get("modOffer") == null, "quick-fit clears the saved offer before the next reward")
	await reload()
	ship = C.RUN["fleet"][0]
	check(ship["mods"] == [REFIT] and ship["hp"] == manifest_hull and C.RUN["inventory"].is_empty(), "quick-fit grants once and matches the manifest hull result")
	check(kind() == "relic", "Continue after quick-fit reopens the next reward")
	C.act("fitRewardRefit", REFIT + ":" + uid)
	C.act("takeMod", REFIT)
	check(ship["mods"] == [REFIT] and C.RUN["inventory"].is_empty(), "neither claim action can grant it again after Continue")

func double_click_reward_check() -> void:
	fixture()
	var ship = C.RUN["fleet"][0]
	var uid: String = ship["uid"]
	victory({"name": "Broken Crown", "tpl": "penitent", "cp": 2, "cause": "blast"}, {"k": "mod"})
	C.RUN["reward"]["modOffer"] = [REFIT]
	C.act("takeSalvage", "0:cred")
	await frames()
	var fit := control("fitRewardRefit", REFIT + ":" + uid) as Button
	check(fit != null, "quick-fit button is present for the double click")
	if fit == null: return
	var first_event: int = C.tel_log.size()
	fit.pressed.emit()
	fit.pressed.emit()
	C.act("takeMod", REFIT)
	var claims: Array = C.tel_log.slice(first_event).filter(func(entry): return entry["ev"] == "reward_pick" and entry.get("k") == "mod")
	check(claims.size() == 1 and ship["mods"] == [REFIT] and C.RUN["inventory"].is_empty(), "two presses of the same quick-fit button and a stale keep action claim exactly once")

func wreck_refit_check() -> void:
	fixture()
	var ship = C.RUN["fleet"][0]
	var uid: String = ship["uid"]
	var wreck := {"name": "Broken Crown", "tpl": "penitent", "cp": 2, "cause": "blast", "wk": ["gauss"]}
	victory(wreck, {"k": "cred"})
	await frames()
	check(control("takeSalvage", "0:mod") != null, "an intact wreck still offers its refit")
	click("fitWreckRefit", "0:" + uid)
	C.act("fitWreckRefit", "0:" + uid)
	await reload()
	check(C.RUN["fleet"][0]["mods"] == ["cogitator"] and C.RUN["inventory"].is_empty(), "a wreck refit fits and is granted only once")

func full_reward_check() -> void:
	fixture()
	var ship = C.RUN["fleet"][0]
	var uid: String = ship["uid"]
	for i in int(C.HULLS[ship["tpl"]]["slots"]): ship["mods"].append(REFIT)
	var slot_count: int = ship["mods"].size()
	victory({"name": "Broken Crown", "tpl": "penitent", "cp": 2, "cause": "blast"}, {"k": "mod"})
	C.RUN["reward"]["modOffer"] = [REFIT]
	C.act("takeSalvage", "0:cred")
	await frames()
	check(control("fitRewardRefit", REFIT + ":" + uid) == null and words().contains("No free compatible slot."), "a full fleet sees why it cannot fit a won refit")
	C.act("fitRewardRefit", REFIT + ":" + uid)
	check(kind() == "mod" and C.W["modOffer"] == [REFIT] and C.RUN["inventory"].is_empty(), "a rejected fit leaves the offer available")
	await reload()
	check(kind() == "mod" and C.W["modOffer"] == [REFIT], "a rejected fit leaves the same offer available on Continue")
	click("takeMod", REFIT)
	C.act("takeMod", REFIT)
	C.act("fitRewardRefit", REFIT + ":" + uid)
	await reload()
	check(C.RUN["fleet"][0]["mods"].size() == slot_count and C.RUN["inventory"] == [REFIT], "keeping a won refit grants exactly one to the hold")

func bought_checks() -> void:
	for keep in [false, true]:
		fixture()
		var uid: String = C.RUN["fleet"][0]["uid"]
		if keep:
			var ship = C.RUN["fleet"][0]
			for i in int(C.HULLS[ship["tpl"]]["slots"]): ship["mods"].append(REFIT)
		# A pre-existing copy must survive fitting the purchase.
		C.RUN["inventory"] = [REFIT]
		var yard = C.RUN["map"]["cols"][0][0]
		yard["type"] = "shipyard"
		C.RUN["pos"] = yard["id"]; C.RUN["curNode"] = yard["id"]
		C.shipyardScreen(yard)
		yard["stock"]["mods"] = [REFIT]; yard["stock"]["sold"] = []
		C.shipyardScreen(yard)
		var price: float = C.jsround(float(C.MODULES[REFIT]["cost"]) * C.priceMult())
		await frames()
		click("buyMod", "0", ui.page_box)
		await reload()
		var ship = C.RUN["fleet"][0]
		var fitted: int = ship["mods"].size()
		check(kind() == "bought_refit" and C.RUN["inventory"] == [REFIT, REFIT], "Continue restores the paid refit card and one new copy")
		if keep:
			check(control("fitBoughtRefit", uid) == null and words().contains("No free compatible slot."), "a full fleet can keep the purchased module")
			C.act("fitBoughtRefit", uid)
			check(kind() == "bought_refit" and ship["mods"].size() == fitted, "a full slot cannot consume the purchase")
			var escape := InputEventKey.new()
			escape.keycode = KEY_ESCAPE
			escape.pressed = true
			ui._unhandled_input(escape)
		else:
			click("fitBoughtRefit", uid)
			C.act("fitBoughtRefit", uid)
		await reload()
		check(C.page["kind"] == "shipyard" and kind() == "", "fit or cancel returns to the shipyard after a reload")
		check(C.RUN["credits"] == 500 - price and C._has_num(C.yard_node["stock"]["sold"], 0), "the yard charges once and keeps the item sold")
		check(C.RUN["inventory"] == ([REFIT, REFIT] if keep else [REFIT]), "cancel keeps the purchase and fitting leaves the old copy in the hold")
		check(C.RUN["fleet"][0]["mods"].size() == fitted + (0 if keep else 1), "the purchase is fitted at most once")

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var c = campaign()
	if c == null: return
	bind(c)
	await wreck_checks()
	await blocked_tow_check()
	await won_checks()
	await double_click_reward_check()
	await wreck_refit_check()
	await full_reward_check()
	await bought_checks()
	await captain_loss_check()
	await promotion_words_check()
	ui.queue_free()
	await frames()
	if failures == 0: print("PASS: wreck payouts, reward quick-fit, paid refits, full slots, Continue, captain fates and promotion wording")
	quit(0 if failures == 0 else 1)
