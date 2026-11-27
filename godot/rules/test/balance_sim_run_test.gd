extends "res://rules/sim/balance_sim.gd"
## Exercise the public run 2 entry point and check the records it prints.

# Seed 3 still reaches both the shipyard and bosses under the symmetric carrier and bot rules.
const PAIR_SEED := 2

class RunLog extends Logger:
	var records: Array[Dictionary] = []
	var footer := ""
	var after_footer := false

	func _log_message(message: String, error: bool) -> void:
		if error:
			return
		var line := message.strip_edges()
		if line.begins_with("RUN "):
			after_footer = not footer.is_empty()
			var row = JSON.parse_string(line.substr(4))
			if row is Dictionary:
				records.append(row)
		elif line.begins_with("RUNS_COMPLETE "):
			footer = line if footer.is_empty() else "duplicate footer"


func _initialize() -> void:
	for option in ["CAP", "BOTCMD", "BOTBRACE", "SIM_BUILD", "SEED"]:
		OS.unset_environment(option)
	OS.set_environment("PFACTION", "voidsworn")
	OS.set_environment("AI", "standard")
	OS.set_environment("PAIRSEED", str(PAIR_SEED))
	OS.set_environment("SIM_ARM", "run_smoke")
	var log := RunLog.new()
	OS.add_logger(log)
	super._initialize()
	OS.remove_logger(log)
	if failed:
		return
	if log.records.size() != 2 or log.footer != "RUNS_COMPLETE 2" or log.after_footer:
		_fail("Expected two RUN records followed by RUNS_COMPLETE 2.")
		return
	var shop_buys := 0
	var boss_fights := 0
	for i in range(log.records.size()):
		var row: Dictionary = log.records[i]
		if row.faction != "voidsworn" or row.difficulty != "standard" or row.arm != "run_smoke" \
				or row.seed != PAIR_SEED + i + 1 or row.terminal_reason == "engine_error":
			_fail("Unexpected campaign run record: " + str(row))
			return
		for kind in row.shop_buys:
			if kind != "repair":
				shop_buys += int(row.shop_buys[kind])
		boss_fights += int(row.boss_fights)
	if shop_buys == 0 or boss_fights == 0:
		_fail("Expected at least one shipyard purchase and one boss fight.")
		return
	print("PASS: two full campaign runs, %d shop buys, %d boss fights" % [shop_buys, boss_fights])
