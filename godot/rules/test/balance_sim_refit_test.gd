extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const Policy = preload("res://rules/sim/sim_run_policy.gd")
const REFIT := "prow"
const RESERVE := 120.0

var campaign := Campaign.new()


func _initialize() -> void:
	var error := campaign.load_tables()
	if not error.is_empty():
		printerr("FAIL: " + error)
		quit(1)
		return
	var passed := _check_shop(0.0, 0.0, true)
	passed = _check_shop(1000.0, 0.0, true) and passed
	passed = _check_shop(1000.0, -1.0, false) and passed
	if passed:
		print("PASS: the Chorus sim buys and fits biomass refits while keeping its reserve")
	quit(0 if passed else 1)


func _check_shop(credits: float, reserve_adjustment: float, should_buy: bool) -> bool:
	campaign.rng.rnd_seed(1992)
	campaign.fixed_clock = true
	campaign.META.admirals.matriarch = true
	campaign.newRun("matriarch", "chorus")
	var run: Dictionary = campaign.RUN
	var cost: float = Campaign.JSM.jsround(campaign.MODULES[REFIT].cost * campaign.priceMult())
	var biomass := cost + RESERVE + reserve_adjustment
	run.bio = biomass
	run.credits = credits
	var stock := {"hulls": [], "mods": [REFIT], "sold": [], "cap": []}
	var node := {"id": "refit_test", "type": "shipyard", "stock": stock}
	campaign.shipyardScreen(node)
	Policy.new(campaign).shop(node, func(action, arg, _kind): campaign.act(action, arg))
	var fitted: bool = run.fleet.any(func(ship): return ship.mods.has(REFIT))
	var paid := biomass - cost if should_buy else biomass
	if stock.sold.has(0) == should_buy and fitted == should_buy and run.inventory.is_empty() \
			and run.bio == paid and run.credits == credits:
		return true
	printerr("FAIL: expected Chorus refit purchase and fit = %s with %s biomass and %s credits" % [
		should_buy, biomass, credits])
	return false
