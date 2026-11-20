extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const CampaignUI = preload("res://ui/campaign/campaign_ui.gd")
const API = preload("res://rules/battle_api.gd")

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var c := Campaign.new()
	var restored := Campaign.new()
	var api := API.new()
	for error in [c.load_tables(), restored.load_tables(), api.load_rules()]:
		if error != "":
			printerr(error)
			quit(1)
			return
	for campaign in [c, restored]:
		campaign.persist_on = false
		campaign.fixed_clock = true

	var ui := CampaignUI.new()
	root.add_child(ui)
	ui.set_process(false)
	ui.C = c
	c.titleScreen()
	c.act("newRunScreen")
	var options := ui._run_options()
	var toggle := options.find_child("MapTrialToggle", true, false) as CheckBox
	check(toggle != null and not toggle.button_pressed, "the new-run screen defaults to off")
	if toggle == null:
		options.free()
		quit(1)
		return
	toggle.button_pressed = true
	options.free()
	c.act("startRun")
	check(c.RUN.get("mapTrial") == true, "launch carries the selected checkbox into the run")
	c.act("backToSetup")   # issue 1217 phase 4: Back from the flagship page keeps Test maps for the next Launch
	check(c.RUN == null and c.map_trial_choice, "Back from the flagship page keeps Test maps chosen")
	c.act("startRun")
	check(c.RUN.get("mapTrial") == true, "Launch after Back still uses Test maps")
	c.act("pickAspect", c.W["aspOffer"][0])
	c.act("closeModal")
	c.act("optMapTrial", "0")
	check(c.RUN.get("mapTrial") == true, "the selection cannot change an active run")
	c.act("saveQuit")
	var saved_on := c.save_text()

	restored.load_save_text(saved_on)
	restored.titleScreen()
	restored.act("continueRun")
	check(restored.RUN.get("mapTrial") == true, "the save retains the flag after Continue")
	ui.C = restored
	check_map_status(ui, "on")

	var cfg := {"kind": "battle", "fac": "hegemony", "col": 1, "seed": 7, "obj": "hunt", "shape": "open", "map": "belt",
		"enemies": [{"tpl": "h_picket"}, {"tpl": "h_dominion"}]}
	restored.battle_mode = "external"
	restored.battle_setup = func(run, battle_cfg):
		api.new_battle(run, battle_cfg)
		return api.R.B
	restored.start_battle(cfg)
	check(restored.B.get("mapTrialReady") == true and restored.B.has("mapTrialBearing"), "the resumed run starts a real trial battle")
	var teaching := cfg.merged({"obj": "rout", "arena": "strip", "edgeFeature": true}, true)
	restored.start_battle(teaching)
	check(restored.B["shape"] == "open" and restored.B["arena"] == "strip", "the first teaching battle keeps its scripted field")

	var old_save: Dictionary = JSON.parse_string(saved_on)
	old_save["run"].erase("mapTrial")
	restored.load_save_text(JSON.stringify(old_save))
	restored.titleScreen()
	restored.act("continueRun")
	check(not restored.RUN.has("mapTrial"), "a save without the flag loads with it off")
	restored.start_battle(cfg)
	check(not restored.B.has("mapTrialReady") and not restored.B.has("mapTrialBearing"), "old saves start standard battles")

	# The map label follows the saved run, and a later new run starts unchecked.
	check_map_status(ui, "off")
	c.SAVED_RUN = null
	c.act("newRunScreen")
	ui.C = c
	options = ui._run_options()
	toggle = options.find_child("MapTrialToggle", true, false) as CheckBox
	check(toggle != null and not toggle.button_pressed, "a later new run starts unchecked")
	options.free()
	c.act("startRun")
	check(not c.RUN.has("mapTrial") and not c.SAVED_RUN.has("mapTrial"), "a default run omits the flag")
	ui.queue_free()
	if failures == 0: print("PASS: map trial toggle, map label, battle hand-off and save compatibility")
	quit(0 if failures == 0 else 1)

func check_map_status(ui: CampaignUI, state: String) -> void:
	var rail := ui._briefing_column()
	var status := rail.find_child("MapTrialStatus", true, false) as Label
	if state == "on": check(status != null and status.text == "Test map package on", "the map displays the on state")
	else: check(status == null, "the map shows no trial label while the trial is off (issue 1175)")
	rail.queue_free()
