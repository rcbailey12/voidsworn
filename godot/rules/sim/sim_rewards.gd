extends RefCounted
## Reconstruct the rewards from earlier stops using the reference simulator's pick policy.

const Campaign = preload("res://campaign/campaign.gd")
const JSM = preload("res://rules/jsm.gd")

var campaign: Campaign


func _init(campaign_rules: Campaign) -> void:
	campaign = campaign_rules


func carry_to(sector: int, column: int) -> void:
	for earlier_sector in range(1, sector + 1):
		var first_column := 0 if earlier_sector == 1 else 1
		var last_column := 6 if earlier_sector < sector else column - 1
		for earlier_column in range(first_column, last_column + 1):
			if earlier_column == 5:
				continue
			var kind := "boss" if earlier_column == 6 else ("elite" if earlier_column == 4 else "battle")
			_carry_fight(earlier_sector, earlier_column, kind)
	_spend_at_yard()
	campaign.RUN.sector = sector


func _carry_fight(sector: int, column: int, kind: String) -> void:
	var run: Dictionary = campaign.RUN
	run.sector = sector
	run.stats.battles += 1
	if kind == "elite":
		run.stats.elites += 1
	elif kind == "boss":
		run.stats.bosses += 1
	# The reference carry banks a clean win, before node rewards and without a debris or prize screen.
	var effects := campaign.runFx()
	var multiplier := 3.0 if kind == "boss" else (1.6 if kind == "elite" else 1.0)
	var credits := JSM.jsround((25 + 12 * sector + 3 * column) * multiplier * (1.0 + effects.get("credPct", 0.0)))
	if campaign.jt(effects.get("salvage")):
		credits += 15
		_repair_fleet(0.08)
	run.credits += credits
	var reward := campaign.rollNodeReward(kind)
	match reward.k:
		"boon":
			if campaign.PATRONS.has(reward.p):
				_take_boon(reward)
		"mod":
			var module = campaign.randomModule()
			if module != null:
				run.inventory.append(module)
		"cred":
			run.credits += 35 + 10 * sector
		"repair":
			_repair_fleet(0.25 * campaign.repairMult())
	if kind in ["elite", "boss"]:
		var relic = campaign.randomRelic()
		if relic != null:
			campaign.changeFleet(func(): run.relics.append(relic))


func _take_boon(reward: Dictionary) -> void:
	var run: Dictionary = campaign.RUN
	var offer := campaign.rollBoonOffer(reward.p, reward.get("min", 0))
	if offer.size() < 3:
		run.credits += 60
	var best: Dictionary = {}
	for card in offer:
		if best.is_empty() or card.get("r", 0) > best.get("r", 0):
			best = card
	if not best.is_empty():
		campaign.changeFleet(func(): run.boons.append({"id": best.id, "r": best.get("r", 0)}))


func _repair_fleet(fraction: float) -> void:
	for ship in campaign.RUN.fleet:
		var max_hp: float = campaign.derive(ship).maxHp
		ship.hp = minf(max_hp, ship.hp + JSM.jsround(max_hp * fraction))


func _spend_at_yard() -> void:
	var run: Dictionary = campaign.RUN
	for i in range(run.inventory.size() - 1, -1, -1):
		if fit_first(run.inventory[i]):
			run.inventory.remove_at(i)
	# Spend on the strongest eligible hull first. Equal-cost hulls retain fleet order.
	var marks := JSM.ssort(run.fleet.duplicate(), func(a, b): return campaign.HULLS[b.tpl].cp - campaign.HULLS[a.tpl].cp)
	for attempt in range(8):
		var bought := false
		for ship in marks:
			if ship.mk >= 3:
				continue
			var cost := campaign.mkCost(ship)
			if run.credits >= cost:
				run.credits -= cost
				campaign.changeShip(ship, func(target): target.mk += 1)
				bought = true
				break
		if not bought:
			break
	for attempt in range(3):
		var module = campaign.randomModule()
		if module == null:
			break
		var cost := JSM.jsround(campaign.MODULES[module].cost * campaign.priceMult())
		if run.credits < cost or not fit_first(module):
			break
		run.credits -= cost


func fit_first(module: String) -> bool:
	for ship in campaign.RUN.fleet:
		if campaign.canFitModule(ship, module):
			campaign.changeShip(ship, func(target): target.mods.append(module))
			return true
	return false
