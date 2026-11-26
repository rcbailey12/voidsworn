extends RefCounted
## Plays a whole campaign through Campaign.act and the existing battle pilot.

const Campaign = preload("res://campaign/campaign.gd")
const SimBattle = preload("res://rules/sim/sim_battle.gd")
const Bot = preload("res://rules/sim/sim_bot.gd")
const Policy = preload("res://rules/sim/sim_run_policy.gd")
const RUN_STEP_LIMIT := 800
const RETREAT_LIMIT := 3

var campaign: Campaign
var battle: SimBattle
var bot: Bot
var policy: Policy
var record: Dictionary
var retreats: Dictionary


func _init(rules: Campaign, pilot_battle: SimBattle, pilot: Bot) -> void:
	campaign = rules
	battle = pilot_battle
	bot = pilot
	policy = Policy.new(rules)
	campaign.battle_mode = "external"
	campaign.battle_setup = battle.start_campaign
	campaign.fixed_clock = true


func new_record(faction: String, difficulty: String, admiral: String, seed: int, arm: String) -> Dictionary:
	return {"faction": faction, "difficulty": difficulty, "admiral": admiral, "seed": seed, "arm": arm,
		"terminal_reason": "engine_error", "sector": 1, "battles_fought": 0, "boss_fights": 0,
		"boss_credits": null, "boss_biomass": null, "shop_buys": {}, "abilities_fired": {},
		"battle_timeouts": 0, "retreats": 0}


func play(row: Dictionary) -> void:
	record = row
	retreats = {}
	campaign.META = campaign.defaultMeta()
	campaign.META.admirals[row.admiral] = true
	campaign.ended = false
	campaign.B = null
	campaign.pending_battle = null
	campaign.W.clear()
	campaign.toasts.clear()
	campaign.tel_log.clear()
	battle.AI_LEVEL = row.difficulty
	campaign.rng.rnd_seed(row.seed)
	campaign.picked_faction = row.faction
	campaign.picked_admiral = row.admiral
	campaign.act("startRun")
	if campaign.RUN == null or campaign.page.kind != "aspect":
		row.error = "Campaign could not start."
		return
	campaign.act("pickAspect", policy.pick_effect(campaign.page.data.opts, campaign.ASPECTS))
	for step in range(RUN_STEP_LIMIT):
		if campaign.ended:
			row.terminal_reason = "won" if campaign.page.data.victory else "lost"
			return
		row.sector = int(campaign.RUN.sector)
		if campaign.pending_battle != null:
			var stop := _fight()
			if not stop.is_empty():
				row.terminal_reason = stop
				return
		elif campaign.modal_d != null:
			if not _modal(campaign.modal_d):
				row.error = "Unhandled campaign modal: " + str(campaign.modal_d.kind)
				return
		elif campaign.page.kind == "shipyard":
			policy.shop(campaign.page.data.node, _buy)
		elif campaign.page.kind == "map":
			policy.maybe_verb()
			var available := campaign.availableNodes()
			if available.is_empty():
				row.error = "No available route nodes."
				return
			var id := policy.choose_node(available, retreats)
			if retreats.get(id, 0) >= RETREAT_LIMIT:
				campaign.endRun(false, true)
				row.terminal_reason = "bot_concession"
				return
			campaign.act("enterNode", id)
		else:
			row.error = "Unhandled campaign page: " + str(campaign.page.kind)
			return
	row.error = "Campaign step limit reached."
	row.terminal_reason = "timeout"


func _fight() -> String:
	var cfg: Dictionary = campaign.pending_battle
	var run: Dictionary = campaign.RUN
	var boss: bool = cfg.kind == "boss"
	record.battles_fought += 1
	if boss:
		record.boss_fights += 1
		if run.sector == 3:
			record.boss_credits = run.credits
			record.boss_biomass = run.get("bio", 0)
	battle.fight(bot, true)
	if not battle.not_ported.is_empty():
		record.error = battle.not_ported
		return "engine_error"
	var fired := battle.player_abilities_fired()
	for id in fired:
		record.abilities_fired[id] = record.abilities_fired.get(id, 0) + fired[id]
	var result = battle.B.over
	var timed_out := not battle.jt(result)
	if timed_out:
		record.battle_timeouts += 1
		# Muse treats a non-boss timeout as a retreat, and a boss timeout as a loss.
		result = "loss" if boss else "retreat"
	if result not in ["win", "loss", "retreat"]:
		record.error = "Unexpected battle result: " + str(result)
		return "engine_error"
	campaign.finish_battle(result, battle.B)
	if timed_out and boss:
		return "timeout"
	if not campaign.ended and battle.B.get("campaignResult") == "retreat":
		var id: String = cfg.node
		retreats[id] = retreats.get(id, 0) + 1
		record.retreats += 1
	return ""


func _modal(modal: Dictionary) -> bool:
	var data: Dictionary = modal.data
	match modal.kind:
		"intro", "event_result":
			campaign.act("closeModal")
		"sector":
			campaign.act(modal.acts[0][0])
		"eatCore":
			campaign.act("refuseCoreEat")
		"event":
			var choice := policy.choose_event(data.ev.o, modal.acts)
			if choice.is_empty():
				# The baseline passes a stop with no legal options.
				campaign.completeNode()
				campaign.mapScreen()
			else:
				campaign.act("eventChoice", choice)
		"repair_stop":
			campaign.act("repairStop", policy.repair_stop(data.options))
		"prize":
			campaign.act("prizeConfirm")
		"victory":
			if data.wrecks.is_empty():
				campaign.act("rewardNext")
			else:
				var yield_data: Dictionary = data.wrecks[0]["yield"]
				var kind := "mod" if yield_data.get("mod") else ("tow" if yield_data.get("tow") else "cred")
				campaign.act("takeSalvage", "0:" + kind)
		"boon":
			var pick := policy.pick_boon(data.offer)
			if pick < 0:
				campaign.act("boonDecline")
			else:
				campaign.act("takeBoon", pick)
		"mod":
			campaign.act("takeMod", policy.pick_module(data.opts))
		"relic":
			campaign.act("takeRelic", policy.pick_relic(data.opts))
		"promotions":
			var ship: Dictionary = data.ships[0]
			var perk := policy.pick_effect(ship.cap.offer, campaign.PERKS)
			campaign.act("takePerk", ship.uid + ":" + perk)
		_:
			return false
	return true


func _buy(action: String, arg, kind: String) -> void:
	var run: Dictionary = campaign.RUN
	var funds: float = run.credits + run.get("bio", 0)
	campaign.act(action, arg)
	if run.credits + run.get("bio", 0) < funds:
		record.shop_buys[kind] = record.shop_buys.get(kind, 0) + 1
