extends RefCounted
## Muse Monte Carlo baseline (driver.js, policies.js) with the late-run sim_1178.js picks.

const Campaign = preload("res://campaign/campaign.gd")
const JSM = Campaign.JSM

var campaign: Campaign


func _init(rules: Campaign) -> void:
	campaign = rules


func choose_node(available: Array, retreats: Dictionary) -> String:
	var hp: float = fleet_health().fraction
	return _best(available, func(id):
		var node: Dictionary = campaign.findNode(id)
		return _node_score(node, hp) - 100 * retreats.get(id, 0))


func _node_score(node: Dictionary, hp: float) -> float:
	var run: Dictionary = campaign.RUN
	var score: float = {"elite": 50, "boss": 45, "battle": 32, "shipyard": 26, "event": 20,
		"drydock": 14, "field": 14}.get(node.type, 0)
	if node.type == "shipyard":
		score += 8 if run.credits > 180 else 0
		if run.sector >= 3 and run.credits >= 300:
			score += 40
	if 1.0 - hp > 0.45:
		score += {"drydock": 120, "field": 100, "shipyard": 90, "elite": -25}.get(node.type, 0)
	var reward: Dictionary = node.get("rw", {})
	match reward.get("k"):
		"boon":
			var held := 0
			for boon in run.boons:
				if campaign.BOONS[boon.id].get("p") == reward.p:
					held += 1
			score += 9 if held < 2 else 4
		"repair":
			score += 25 if 1.0 - hp > 0.2 else 0
		"cred": score += 3
		"mod": score += 5
	return score


func fleet_health() -> Dictionary:
	var hp := 0.0
	var max_hp := 0.0
	var missing := 0.0
	for ship in campaign.RUN.fleet:
		var hull: float = campaign.derive(ship).maxHp
		hp += maxf(0.0, ship.hp)
		max_hp += hull
		missing += hull - ship.hp
	return {"fraction": hp / max_hp if max_hp > 0.0 else 1.0, "missing": missing}


func repair_stop(options: Array) -> String:
	var flag = campaign.flagshipOf()
	var flag_hp: float = maxf(0.0, flag.hp) / campaign.derive(flag).maxHp if flag != null else 1.0
	var extra_value: float = (options[0].hp - options[1].hp) / 2.0 * campaign.priceMult()
	return "service" if extra_value > options[1].credits or fleet_health().fraction < 0.5 or flag_hp < 0.5 else "stipend"


func maybe_verb() -> void:
	if not campaign.verbCanUse():
		return
	var run: Dictionary = campaign.RUN
	var verb: Dictionary = campaign.verbFor()
	var cost: Dictionary = campaign.or_(verb.get("cost"), {})
	var flag = campaign.or_(campaign.flagshipOf(), run.fleet[0])
	var no_cost := not campaign.jt(cost.get("cred")) and not campaign.jt(cost.get("mod")) and not campaign.jt(cost.get("xp"))
	if campaign.verbFree(verb) or no_cost \
			or (cost.get("cred", 0) and run.credits >= 300) \
			or (cost.get("mod", 0) and run.inventory.size() >= 2) \
			or (cost.get("xp", 0) and flag.cap.xp >= cost.xp + 30):
		campaign.act("factionVerb")


func choose_event(options: Array, acts: Array) -> String:
	var hp: float = fleet_health().fraction
	var available := acts.filter(func(action): return action[0] == "eventChoice" and action[2])
	var best = _best(available, func(action): return _event_score(options[int(action[1])].get("r"), hp))
	if best == null:
		return ""
	var id: String = best[1]
	var outcome = options[int(id)].get("r")
	# The browser bot paid the newest relic when the option required one.
	if outcome is Dictionary and outcome.get("payRelic", false) and campaign.RUN.relics.size() > 1:
		id += ":" + str(campaign.RUN.relics.size() - 1)
	return id


func _event_score(outcome, hp: float) -> float:
	var r: Dictionary = outcome if outcome is Dictionary else {}
	var missing := 1.0 - hp
	var score: float = r.get("cred", 0) + r.get("xp", 0) * 2 + r.get("xpLow", 0) + r.get("xpTop", 0)
	score += (r.get("healAll", 0) * 300 + (80 if r.get("repairOne") else 0)) * missing
	score += 120 if r.get("relic") else 0
	score += 60 if r.get("mod") or r.get("modId") else 0
	score += 150 if r.get("ship") or r.get("shipRaw") else 0
	score += 100 if r.get("upgradeOne") else 0
	score += 40 if r.get("nemIntel") else 0
	score -= r.get("cost", 0) + r.get("dmgAll", 0) * 400 + r.get("dmgOne", 0) * 150 + r.get("dmgBig", 0) * 200
	score -= 130 if r.get("payRelic") else 0
	score -= 50 if r.get("payXp") else 0
	score -= 60 if r.get("payMod") else 0
	score -= 70 if r.get("loseMod") else 0
	score -= 10 if r.get("gamble") else 0
	if r.get("fight"):
		score += 60 if hp >= 0.7 else -200
	return score


func pick_effect(ids: Array, table: Dictionary) -> String:
	return _best(ids, func(id): return _fx_score(table[id].get("fx")))


func pick_boon(offer: Array) -> int:
	var kit := campaign.fleetKit()
	if not offer.any(func(card): return campaign.boonUseful(card.id, kit)):
		return -1
	return _best(range(offer.size()), func(i):
		var card: Dictionary = offer[i]
		var boon: Dictionary = campaign.BOONS[card.id]
		var rank: int = int(card.get("r", 0))
		return rank * 3 + _fx_score(campaign.BOON_FX[card.id][rank]) \
			+ (2 if boon.get("duo") else 0) + (4 if boon.get("leg") else 0))


func pick_module(ids: Array) -> String:
	return _best(ids, func(id): return _fx_score(campaign.MODULES[id].get("fx")) + campaign.MODULES[id].cost / 100.0)


func pick_relic(ids: Array) -> String:
	return _best(ids, func(id):
		var relic: Dictionary = campaign.RELICS[id]
		return _fx_score(relic.get("fx")) + _fx_score(relic.get("run")))


func _fx_score(effect) -> float:
	var score := 0.0
	if effect is Dictionary:
		for key in effect:
			var value = effect[key]
			if value is float or value is int or value is bool:
				score += absf(float(value)) * (30 if "Pct" in key else 2)
	return score


func _best(items: Array, score: Callable) -> Variant:
	var best = null
	var best_score := -INF
	for item in items:
		var value: float = score.call(item)
		if value > best_score:
			best_score = value
			best = item
	return best


func shop(node: Dictionary, buy: Callable) -> void:
	var run: Dictionary = campaign.RUN
	var stock: Dictionary = node.stock
	var pm := campaign.priceMult()
	if fleet_health().missing > 0:
		buy.call("repairAll", "", "repair")
	var hulls := JSM.ssort(stock.hulls.duplicate(), func(a, b):
		return campaign.HULLS[b].get("cp", 1) - campaign.HULLS[a].get("cp", 1))
	for id in hulls:
		var cost := JSM.jsround(campaign.HULLS[id].cost * pm)
		if campaign.hullFunds() - cost >= 40:
			buy.call("buyHull", id, "hull")
	# The late-run harness does all Chorus hull work on biomass before spending on refits.
	if run.fac == "chorus":
		_buy_marks(buy)
	for i in range(stock.mods.size()):
		var id: String = stock.mods[i]
		var cost := JSM.jsround(campaign.MODULES[id].cost * pm)
		var credits: float = run.credits
		if not stock.sold.has(i) and credits - cost >= 120:
			buy.call("buyMod", i, "mod")
			# The Muse bot fits a yard refit immediately when the credit purse paid for it.
			if run.credits < credits:
				_fit_module(id)
	if run.fac != "chorus":
		_buy_marks(buy)
	_late_market(buy)
	campaign.act("leaveYard")


func _buy_marks(buy: Callable) -> void:
	var run: Dictionary = campaign.RUN
	var ships := JSM.ssort(run.fleet.duplicate(), func(a, b):
		if (a.uid == run.flagUid) != (b.uid == run.flagUid):
			return -1 if a.uid == run.flagUid else 1
		return campaign.HULLS[b.tpl].get("cp", 1) - campaign.HULLS[a.tpl].get("cp", 1))
	for ship in ships:
		if ship.mk < 3 and campaign.hullFunds() - campaign.mkCost(ship) >= 250:
			buy.call("upgradeMk", ship.uid, "mk")


func _fit_module(id: String) -> void:
	var run: Dictionary = campaign.RUN
	var index: int = run.inventory.find(id)
	var need = campaign.MODULES[id].get("only")
	for ship in run.fleet:
		var hull: Dictionary = campaign.HULLS[ship.tpl]
		if ship.mods.size() < hull.slots and (not campaign.jt(need) or hull.get("ab") == need):
			campaign.act("equip", "%d:%s" % [index, ship.uid])
			return


func _late_market(buy: Callable) -> void:
	var run: Dictionary = campaign.RUN
	var cores: Array = run.get("cores", [])
	for i in range(cores.size() - 1, -1, -1):
		buy.call("restoreCore", i, "core")
	for attempt in range(4):
		var offers := campaign.lateShopOffers()
		var reserve := ceilf(fleet_health().missing / 2.0 * campaign.priceMult())
		var affordable := offers.filter(func(o): return o.ok and run.credits - o.cost >= reserve)
		if affordable.is_empty():
			break
		var offer: Dictionary = _best(affordable, func(o): return o.value)
		buy.call("lateBuy", offer.id, "late_" + offer.kind)
