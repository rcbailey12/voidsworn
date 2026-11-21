extends SceneTree
# Issue 1434. Three things the title backdrop and the battle load must keep:
# 1. W4: the title's decorative battle loads no sound bank and never changes the shared sfx bus, at volume 0.25 and muted
#    (before: the bus jumped from -21.42 to -5.25 dB for a frame and the whole bank loaded, about 435 ms).
# 2. Item 10: the backdrop is capped at High, and stop_build() (main.gd, leaving the title) puts the menu's viewport
#    settings back and stops a build still under way.
# 3. Item 2: the sliced build (the windowed path, forced here with --sliced-load) builds every ship, counts them on the
#    cover, and a stop part way builds nothing more.

const BattleScene := preload("res://scenes/battle/battle.tscn")
const Sfx := preload("res://audio/sfx.gd")

var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		fails += 1
		printerr("FAIL: ", what)


func _bus() -> Array:
	var i := AudioServer.get_bus_index("sfx")
	return [AudioServer.get_bus_volume_db(i), AudioServer.is_bus_mute(i)] if i >= 0 else [null, null]


func _run() -> void:
	# the title's own sound node, as main.gd makes it
	var ui := Sfx.new()
	ui.only = "ui_"
	root.add_child(ui)
	for setting in [[true, 0.25], [false, 0.25]]:
		ui.set_on(setting[0])
		ui.set_volume(setting[1])
		await process_frame
		var before := _bus()
		var sc = BattleScene.instantiate()
		sc.showcase = true
		sc.title_backdrop = true
		sc.args["quality"] = "max"
		sc.args["noworld"] = true
		var seen: Array = [before]
		root.add_child(sc)
		seen.append(_bus())
		for i in 4:
			await process_frame
			seen.append(_bus())
		_check(sc.sfx != null and sc.sfx.silent and sc.sfx.cues.is_empty() and sc.sfx.clips.is_empty(),
			"backdrop sound node is silent and loaded no cues (%d cues)" % [sc.sfx.cues.size() if sc.sfx != null else -1])
		_check(str(sc.args.get("quality")) == "high", "backdrop quality capped at High from Max (%s)" % [sc.args.get("quality")])
		_check(root.get_viewport().msaa_3d == sc.SHOWCASE_MSAA, "backdrop sets its own MSAA")
		sc.stop_build()
		sc.queue_free()
		for i in 3:
			await process_frame
			seen.append(_bus())
		var same := true
		for b in seen:
			same = same and is_equal_approx(float(b[0]), float(before[0])) and b[1] == before[1]
		_check(same, "shared sfx bus unchanged through the backdrop's start and end (sound %s, volume %.2f): %s" % [setting[0], setting[1], seen])
	# stop_build puts the viewport back
	var vp := root.get_viewport()
	vp.msaa_3d = Viewport.MSAA_8X
	var sc2 = BattleScene.instantiate()
	sc2.showcase = true
	sc2.title_backdrop = true
	sc2.args["noworld"] = true
	root.add_child(sc2)
	await process_frame
	_check(vp.msaa_3d == sc2.SHOWCASE_MSAA, "backdrop MSAA in force while it shows")
	sc2.stop_build()
	_check(vp.msaa_3d == Viewport.MSAA_8X, "stop_build restored the menu's MSAA (%d)" % vp.msaa_3d)
	sc2.queue_free()
	await process_frame
	# a showcase without title_backdrop (tests and benches: a battle that takes no turns) keeps its tier and its sound
	var sc3 = BattleScene.instantiate()
	sc3.showcase = true
	sc3.args["quality"] = "max"
	sc3.args["noworld"] = true
	root.add_child(sc3)
	await process_frame
	_check(str(sc3.args.get("quality")) == "max" and not sc3.sfx.silent, "a plain showcase keeps Max and its sound")
	sc3.queue_free()
	await process_frame
	# the sliced build: every ship, the count, and a stop part way
	var b = BattleScene.instantiate()
	b.args["sliced-load"] = true
	b.args["noworld"] = true
	b.args["seed"] = 7
	b.bot = true
	root.add_child(b)
	var units: int = (b.api.view()["units"] as Array).size() if b.api != null else -1
	var t0 := Time.get_ticks_msec()
	while b.views.size() < units and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	_check(units > 0 and b.views.size() == units, "sliced build made every ship (%d of %d)" % [b.views.size(), units])
	b.stop_build()
	b.queue_free()
	await process_frame
	var c = BattleScene.instantiate()
	c.args["sliced-load"] = true
	c.args["noworld"] = true
	c.args["seed"] = 7
	c.bot = true
	root.add_child(c)
	c.stop_build()   # before its first frame: the build must stop where it is
	for i in 6:
		await process_frame
	_check(c.views.is_empty(), "a stopped build makes no ships (%d made)" % c.views.size())
	c.queue_free()
	ui.queue_free()
	await process_frame
	if fails > 0:
		printerr("SHOWCASE_QUIET failures=%d" % fails)
		quit(1)
	else:
		print("SHOWCASE_QUIET OK")
		quit(0)
