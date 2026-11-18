extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const Map3D = preload("res://ui/campaign/map3d.gd")
const UI = preload("res://ui/campaign/campaign_ui.gd")
const Loading = preload("res://main/load_screen.gd")

class PausedMap extends Map3D:
	var pause_bake := false
	var builds := 0
	var arrivals := 0

	func _build(sig: String) -> void:
		super._build(sig)
		builds += 1
		# Headless world bakes can finish immediately. Hold the real wait_ready loop open.
		if pause_bake: sector_world.pending_bakes += 1

	func _arrive(new_sector: bool) -> void:
		arrivals += 1
		super._arrive(new_sector)

var fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var campaign := Campaign.new()
	var error := campaign.load_tables()
	if error != "":
		printerr(error)
		quit(1)
		return
	var ui := UI.new()
	root.add_child(ui)
	ui.bind(campaign)
	ui.set_process(false)
	var map := PausedMap.new()
	map.ui = ui
	ui.root.add_child(map)
	map.hide()

	var admiral: String = campaign.TB.STORY_BEAT3["voidsworn"]["spotlights"].keys()[0]
	campaign.META["admirals"][admiral] = true
	campaign.newRun(admiral, "voidsworn")
	map.sync()
	_check(map.loading and _covers(map) == 1, "early load starts under a cover")
	campaign.titleScreen()
	await _frames()
	_check(not map.loading and _covers(map) == 0 and map.builds == 0, "ending the run before the first frame clears the cover without building")

	campaign.newRun(admiral, "voidsworn")
	var same_run = campaign.RUN
	map.pause_bake = true
	map.sync()
	await _frames()
	_check(map.loading and _covers(map) == 1 and map.builds == 1 and map.sector_world != null,
		"map is waiting for its world under a cover")
	if map.sector_world == null:
		quit(1)
		return
	campaign.titleScreen()
	map.sector_world.pending_bakes -= 1
	await _wait_for_load(map)
	_check(not map.loading and _covers(map) == 0 and map.arrivals == 0, "ending a run during the world wait skips arrival and clears the cover")

	campaign.RUN = same_run
	map.pause_bake = false
	map.sync()
	await _wait_for_load(map)
	_check(not map.loading and _covers(map) == 0 and map.builds == 2 and map.arrivals == 1,
		"returning to the same sector starts and finishes a fresh covered load")
	print("MAP LOAD CANCEL: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails else 0)

func _frames() -> void:
	for i in 5: await process_frame

func _wait_for_load(map: Control) -> void:
	# The real world wait can take up to 20 seconds.
	var deadline := Time.get_ticks_msec() + 25000
	while map.loading and Time.get_ticks_msec() < deadline:
		await process_frame
	await process_frame

func _covers(map: Control) -> int:
	return map.get_children().filter(func(child): return child is Loading).size()

func _check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: ", message)
