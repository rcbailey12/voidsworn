extends SceneTree
## godot --headless --path godot --script res://rules/sim/balance_sim.gd -- campaign 10

const SimBattle = preload("res://rules/sim/sim_battle.gd")
const Bot = preload("res://rules/sim/sim_bot.gd")
const Campaign = preload("res://campaign/campaign.gd")
const Rewards = preload("res://rules/sim/sim_rewards.gd")
const JSM = preload("res://rules/jsm.gd")
const CAMPAIGN_FLEETS := {
	1: ["penitent", "harrow", "warden", "warden"],
	2: ["cathedral", "penitent", "harrow", "warden", "warden"],
	3: ["ascendant", "cathedral", "penitent", "reliquary", "harrow"],
}
const CAMPAIGN_NODES := [["battle", 1], ["battle", 4], ["elite", 4], ["boss", 6]]
const MODES := ["campaign", "campaignrewards", "fmatrix"]

class TrialErrors extends Logger:
	var first := ""
	var mutex := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		mutex.lock()
		if first.is_empty():
			first = "%s (%s:%d)" % [rationale if not rationale.is_empty() else code, file, line]
		mutex.unlock()

var battle := SimBattle.new()
var bot := Bot.new(battle)
var campaign := Campaign.new()
var rewards := Rewards.new(campaign)
var pair_seed := ""
var pair_index := 0
var build := {}
var build_enabled := false
var alternating := true
var failed := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 3 or (args.size() == 3 and args[2] != "--classic"):
		_fail("Usage: balance_sim.gd -- [campaign|campaignrewards|fmatrix] [battles per cell] [--classic]")
		return
	var mode := args[0] if not args.is_empty() else "campaign"
	if mode not in MODES:
		_fail("Unknown mode: " + mode)
		return
	var count := 6 if mode == "fmatrix" else 10
	if args.size() >= 2:
		if not args[1].is_valid_int() or int(args[1]) <= 0:
			_fail("Battles per cell must be a positive integer.")
			return
		count = int(args[1])
	alternating = args.size() < 3
	var error := battle.load_tables("res://rules/data/tables.json")
	if error.is_empty():
		error = campaign.load_tables()
	if not error.is_empty():
		_fail(error)
		return
	var seed := OS.get_environment("SEED")
	pair_seed = OS.get_environment("PAIRSEED")
	if (not seed.is_empty() and not seed.is_valid_int()) or (not pair_seed.is_empty() and not pair_seed.is_valid_int()):
		_fail("SEED and PAIRSEED must be integers.")
		return
	JSM.rnd_seed(int(seed) if not seed.is_empty() else randi())
	var ai := OS.get_environment("AI")
	if not ai.is_empty():
		if ai not in ["standard", "veteran"]:
			_fail("AI must be standard or veteran.")
			return
		battle.AI_LEVEL = ai
	if OS.get_environment("CAP") == "0":
		battle.RAMP.pwMin = 1.0
		battle.RAMP.pwMax = 1.0
	if OS.get_environment("PACE_OLD") == "1":
		battle.PACE.merge({"move": 1.0, "rot": 0.75, "enemy": 0.65, "tail": 0.65, "swarm": 1.0,
			"banner": 520, "aiGap": 60, "aiEnd": 120, "volley": 1.0, "bigMin": 1.0}, true)
	bot.command_enabled = OS.get_environment("BOTCMD") != "0"
	bot.brace_enabled = OS.get_environment("BOTBRACE") != "0"
	if not _load_build():
		return
	if mode == "fmatrix":
		_fmatrix(count)
	else:
		_campaign(count, mode == "campaignrewards")
	if not failed:
		quit()


func _fail(message: String) -> void:
	failed = true
	printerr("Balance sim: " + message)
	quit(1)


func _next_pair() -> void:
	if not pair_seed.is_empty():
		pair_index += 1
		JSM.rnd_seed(int(pair_seed) + pair_index)


func _new_run(admiral: String, faction: String, sector: int, credits: int, cp_cap: int) -> void:
	campaign.RUN = {"admiral": admiral, "fac": faction, "credits": credits, "cpCap": cp_cap, "sector": sector,
		"relics": [], "inventory": [], "fleet": [], "stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0},
		"fallen": [], "boons": [], "patrons": []}
	battle.RUN = campaign.RUN


func _load_build() -> bool:
	var path := OS.get_environment("SIM_BUILD")
	if path.is_empty():
		return true
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		_fail("SIM_BUILD must point to a JSON object: " + path)
		return false
	for key in data:
		match key:
			"admiral":
				if data[key] is String and battle.ADMIRALS.has(data[key]):
					continue
			"relics", "refits":
				var table: Dictionary = battle.RELICS if key == "relics" else battle.MODULES
				if data[key] is Array and data[key].all(func(id): return id is String and table.has(id)):
					continue
			"lineage":
				if data[key] is Dictionary and battle.LINEAGE_TREES.has(data[key].get("id")):
					continue
			"mastery":
				if data[key] is float and data[key] >= 0 and data[key] == floorf(data[key]):
					continue
		_fail("Unknown or invalid SIM_BUILD field: " + key)
		return false
	build = data
	build_enabled = true
	return true


func _apply_build() -> bool:
	var run: Dictionary = campaign.RUN
	if build.is_empty():
		return true
	campaign.changeFleet(func():
		for field in ["admiral", "mastery"]:
			if build.has(field):
				run[field] = build[field]
		if build.has("lineage"):
			run.lineage = build.lineage.duplicate(true)
		for relic in build.get("relics", []):
			if not run.relics.has(relic):
				run.relics.append(relic)
	)
	for refit in build.get("refits", []):
		if not rewards.fit_first(refit):
			_fail("No ship can fit SIM_BUILD refit " + refit + " in this fleet.")
			return false
	return true


func _campaign_cells() -> Array:
	if not OS.get_environment("ONLY_BOSS").is_empty():
		return [[1, "boss", 6], [3, "boss", 6], [1, "elite", 4]]
	var filters := OS.get_environment("CSEC")
	var cells := []
	var sectors := filters.split(",") if not filters.is_empty() else PackedStringArray(["1", "2", "3"])
	for raw_sector in sectors:
		var sector := raw_sector.strip_edges()
		if sector not in ["1", "2", "3"]:
			_fail("CSEC must list sectors 1, 2, or 3.")
			return []
		for node in CAMPAIGN_NODES:
			cells.append([int(sector), node[0], node[1]])
	return cells


func _campaign(count: int, carry_rewards: bool) -> void:
	var selected := OS.get_environment("PFACTION")
	if not selected.is_empty() and selected not in campaign.RUN_FACTIONS:
		_fail("Unknown PFACTION faction: " + selected)
		return
	var factions: Array = campaign.RUN_FACTIONS if selected.is_empty() else [selected]
	var cells := _campaign_cells()
	for faction in factions:
		pair_index = 0
		for cell in cells:
			_campaign_cell(faction, cell, count, carry_rewards)
			if failed:
				return
	if not failed:
		print("TRIALS_COMPLETE %d" % (factions.size() * cells.size() * count))


func _campaign_cell(player_faction: String, cell: Array, count: int, carry_rewards: bool) -> void:
	battle.timed = true
	var totals := {"wins": 0, "rounds": 0, "hull": 0.0, "lost": 0, "timeouts": 0, "player": 0, "enemy": 0,
		"fired": {}}
	var carried := {"boons": 0, "relics": 0, "refits": 0, "marks": 0, "credits": 0.0, "top": {}}
	var arm := OS.get_environment("SIM_ARM")
	var trial_cell := {"mode": "campaignrewards" if carry_rewards else "campaign", "sector": cell[0],
		"kind": cell[1], "column": cell[2]}
	battle.reset_timing()
	for trial in range(count):
		_next_pair()
		var seed := JSM.rng_u32()
		var previous_battle: Variant = battle.B
		var errors := TrialErrors.new()
		OS.add_logger(errors)
		var stats := _campaign_trial(player_faction, cell, carry_rewards)
		OS.remove_logger(errors)
		if failed:
			return
		var reason := _terminal_reason(errors.first, stats)
		var has_usage: bool = battle.B is Dictionary and not is_same(previous_battle, battle.B) and battle.B.has("usage")
		var fired := battle.player_abilities_fired() if has_usage else {}
		var record := {"faction": player_faction, "difficulty": battle.AI_LEVEL, "cell": trial_cell,
			"seed": seed, "arm": arm if not arm.is_empty() else "single", "terminal_reason": reason, "abilities_fired": fired}
		for metric in ["rounds", "hull", "lost"]:
			if stats.has(metric):
				record[metric] = stats[metric]
		_print_trial(record)
		if reason == "engine_error":
			var detail := errors.first if not errors.first.is_empty() else battle.not_ported
			_fail("Trial failed: " + (detail if not detail.is_empty() else "missing stats or invalid battle outcome"))
			return
		for id in fired:
			totals.fired[id] = totals.fired.get(id, 0) + fired[id]
		for metric in ["player", "enemy", "rounds", "hull", "lost"]:
			totals[metric] += stats[metric]
		totals.wins += int(reason == "completed_win")
		totals.timeouts += int(reason == "timeout")
		if carry_rewards:
			for metric in ["boons", "relics", "refits", "marks", "credits"]:
				carried[metric] += stats.carried[metric]
			for id in stats.carried.top:
				carried.top[id] = carried.top.get(id, 0) + stats.carried.top[id]
	_print_campaign(player_faction, cell, count, totals, carried if carry_rewards else {})


func _terminal_reason(error: String, stats: Dictionary) -> String:
	if not error.is_empty() or not battle.not_ported.is_empty() or stats.is_empty():
		return "engine_error"
	match battle.B.over:
		"win": return "completed_win"
		"loss": return "completed_loss"
		"bot_concession": return "bot_concession"
		false: return "timeout"
	return "engine_error"


func _print_trial(record: Dictionary) -> void:
	print("TRIAL " + JSON.stringify(record, "", true, true))


func _campaign_trial(player_faction: String, cell: Array, carry_rewards: bool) -> Dictionary:
	var sector: int = cell[0]
	var kind: String = cell[1]
	var column: int = cell[2]
	_new_run("vex", player_faction, sector, 120 if carry_rewards else 0, 40)
	var run: Dictionary = campaign.RUN
	for hull in CAMPAIGN_FLEETS[sector]:
		run.fleet.append(battle.newShip(campaign.equivHull(hull, player_faction), true))
	if carry_rewards:
		campaign.ensurePatrons()
		run.flagUid = run.fleet[0].uid
		rewards.carry_to(sector, column)
	if not _apply_build():
		return {}
	# A build fixture can target its own flagship. The plain reference campaign leaves it unset.
	if build_enabled and not run.has("flagUid"):
		run.flagUid = run.fleet[0].uid
	var stats := {"player": 0, "enemy": 0, "lost": 0}
	if carry_rewards:
		stats.carried = _measure_carry(run)
	var faction: String = battle.pick(campaign.SECTOR_POOL[sector - 1])
	var objective: String = "rout" if kind == "boss" else battle.pick(["rout", "rout", "flagship", "hold"])
	var deployment: String = "line" if kind == "boss" else battle.pick(["line", "line", "flank", "ambush"])
	battle.startBattle({"kind": kind, "fac": faction, "col": column, "obj": objective, "dep": deployment})
	for unit in battle.B.units:
		if not unit.isSq:
			stats[unit.side] += 1
	battle.fight(bot, alternating)
	var hp := 0.0
	var max_hp := 0.0
	for unit in battle.B.units:
		if not battle.jt(unit.get("ship")):
			continue
		if unit.side == "player":
			hp += 0.0 if unit.dead else maxf(0.0, unit.hp)
			max_hp += unit.maxHp
		if unit.dead or unit.side != "player":
			stats.lost += 1
	stats.hull = hp / maxf(1.0, max_hp)
	stats.rounds = battle.B.round
	return stats


func _measure_carry(run: Dictionary) -> Dictionary:
	var carried := {"boons": run.boons.size(), "relics": run.relics.size(), "credits": run.credits,
		"refits": 0, "marks": 0, "top": {}}
	for ship in run.fleet:
		carried.refits += ship.mods.size()
		carried.marks += ship.mk
	for boon in run.boons:
		carried.top[boon.id] = carried.top.get(boon.id, 0) + 1
	return carried


func _print_campaign(player_faction: String, cell: Array, count: float, totals: Dictionary, carried: Dictionary) -> void:
	var clock: Dictionary = battle.clock
	var tempo: Dictionary = battle.tempo
	var rounds := maxf(1.0, clock.rounds)
	var round_line := "sector %d %-6s col %d  player %-9s  win %d%%  rounds %.1f  hull left %d%%  ships lost %.1f  timeouts %d"
	var wait_line := "  wait old %ds new %ds  real %ds  per round %.1fs  max round %.1fs  ships %.1f+%.1f"
	print((round_line + wait_line) % [cell[0], cell[1], cell[2], player_faction, JSM.jsround(totals.wins / count * 100),
		totals.rounds / count, JSM.jsround(totals.hull / count * 100), totals.lost / count, totals.timeouts,
		JSM.jsround(clock.old / count), JSM.jsround(clock.neu / count), JSM.jsround(clock.real / count),
		clock.real / rounds, clock.max_round, totals.player / count, totals.enemy / count])
	var fired_ids: Array = totals.fired.keys()
	fired_ids.sort()
	var fired_labels := PackedStringArray()
	for id in fired_ids:
		fired_labels.append("%s %.2f (%d total)" % [id, totals.fired[id] / count, totals.fired[id]])
	print("   player abilities fired per battle: " + (", ".join(fired_labels) if not fired_labels.is_empty() else "none"))
	var first := "%.1f" % (float(tempo.first_loss) / tempo.first_count) if tempo.first_count > 0 else "none"
	print("   tempo: enemy activations per player activation %.2f, enemy ships firing per round %.1f, first player ship lost in round %s" %
		[tempo.enemy / maxf(1.0, tempo.player), tempo.fire / rounds, first])
	if not carried.is_empty():
		var keys := JSM.ssort(carried.top.keys(), func(a, b): return carried.top[b] - carried.top[a])
		var labels := PackedStringArray()
		for id in keys.slice(0, 5):
			labels.append("%s %.1f" % [id, carried.top[id] / count])
		var top := ", ".join(labels) if not labels.is_empty() else "none"
		print("   carried: protocols %.1f (%s), relics %.1f, refits %.1f, mk sum %.1f, credits left %.0f" %
			[carried.boons / count, top, carried.relics / count, carried.refits / count, carried.marks / count, carried.credits / count])
	elif not OS.get_environment("CATS").is_empty():
		var keys := JSM.ssort(battle.categories.keys(), func(a, b): return battle.categories[b] - battle.categories[a])
		var labels := PackedStringArray()
		for key in keys:
			labels.append("%s %.2f" % [key, battle.categories[key] / rounds])
		print("   per round: " + ", ".join(labels))


func _fmatrix(count: int) -> void:
	var factions: Array = campaign.RUN_FACTIONS
	var rows := OS.get_environment("FROWS")
	var player_factions: Array = Array(rows.split(",")) if not rows.is_empty() else factions
	var budget_text := OS.get_environment("CPT")
	if not budget_text.is_empty() and (not budget_text.is_valid_int() or int(budget_text) <= 0):
		_fail("CPT must be a positive integer.")
		return
	var budget := int(budget_text) if not budget_text.is_empty() else 8
	for faction in player_factions:
		if faction not in factions:
			_fail("Unknown FROWS faction: " + faction)
			return
	var result := {}
	battle.matrix = true
	var no_admiral := not OS.get_environment("NOADM").is_empty()
	for player in player_factions:
		var row := {}
		result[player] = row
		var admirals: Array = battle.ADMIRALS.keys().filter(func(id): return battle.ADMIRALS[id].get("fac", "voidsworn") == player)
		for enemy in factions:
			var wins := 0
			for trial in range(count):
				_next_pair()
				var admiral: String = "none" if no_admiral else battle.pick(admirals)
				_new_run(admiral, player, 2, 0, 60)
				var players := _random_fleet(player, budget)
				var enemies := _random_fleet(enemy, budget)
				for tpl in players:
					campaign.RUN.fleet.append(battle.newShip(tpl, false))
				if players.is_empty() or enemies.is_empty():
					_fail("CPT produced an empty fleet for %s or %s." % [player, enemy])
					return
				campaign.RUN.flagUid = campaign.RUN.fleet[0].uid
				if not _apply_build():
					return
				var shape: String = battle.pick(battle.SHAPES.keys())
				battle.startBattle({"kind": "battle", "fac": enemy, "col": 3, "dep": "line", "obj": "rout",
					"shape": shape, "map": "random", "enemies": enemies.map(func(tpl): return {"tpl": tpl})})
				battle.fight(bot, alternating)
				battle.collect_matrix()
				wins += int(battle.B.over == "win")
			row[enemy] = JSM.jsround(float(wins) / count * 100)
	print("FM " + JSON.stringify({"out": result, "st": battle.matrix_stats, "hull": battle.hulls,
		"weap": battle.weapons, "ab": battle.abilities}, "", false))
	print("FID " + JSON.stringify(battle.faction_report(), "", false))


func _random_fleet(faction: String, budget: int) -> Array:
	var roster: Array = battle.FACTIONS[faction].roster.filter(func(id): return not battle.jt(battle.HULLS[id].get("unique")))
	var fleet := []
	var spent := 0.0
	for attempt in range(40):
		if spent >= budget:
			break
		var id: String = battle.pick(roster)
		var cp: float = battle.HULLS[id].get("cp", 1)
		if spent + cp <= budget + 1:
			fleet.append(id)
			spent += cp
	return fleet
