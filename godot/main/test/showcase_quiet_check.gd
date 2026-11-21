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
const SV := preload("res://render/ship_view.gd")

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
	# the same fight with every hull a kit ship (a stand-in scene): threaded load, worker instances, setup in two steps
	var codes := {}
	var hulls_n := 0
	for id in b.views:
		if not b.views[id].squad_kind.is_empty():
			continue
		codes[b.views[id].code] = true
		hulls_n += 1
	b.stop_build()
	b.queue_free()
	await process_frame
	var fixture := "user://showcase_quiet_hull_%d.tscn" % OS.get_process_id()
	var hull := Node3D.new()
	var part := MeshInstance3D.new()
	var mesh := ArrayMesh.new()
	var box := BoxMesh.new()
	box.size = Vector3(12.0, 3.0, 4.0)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	part.mesh = mesh
	hull.add_child(part)
	part.owner = hull
	var core := Node3D.new()
	core.name = "hp_core"
	hull.add_child(core)
	core.owner = hull
	var scene := PackedScene.new()
	_check(scene.pack(hull) == OK and ResourceSaver.save(scene, fixture) == OK, "saved a stand-in kit hull")
	hull.free()
	var ships := {}
	for code in codes:
		ships[code] = {"res": fixture}
	SV._manifest = {"ships": ships}
	var k = BattleScene.instantiate()
	k.args["sliced-load"] = true
	k.args["noworld"] = true
	k.args["seed"] = 7
	k.bot = true
	root.add_child(k)
	t0 = Time.get_ticks_msec()
	while (k.views.size() < units or k.load_stats.is_empty()) and Time.get_ticks_msec() - t0 < 20000:   # load_stats: the build's end
		await process_frame
	var kits := 0
	var staged := 0
	for id in k.views:
		if k.views[id].a4:
			kits += 1
			if k.views[id].stage_us.has("inst") and k.views[id].stage_us.has("look"):
				staged += 1
	_check(k.views.size() == units and kits == hulls_n and hulls_n > 0 and k._inst_tasks.is_empty(),
		"kit hulls built from worker instances (%d views, %d kit ships of %d expected, %d tasks left)" % [k.views.size(), kits, hulls_n, k._inst_tasks.size()])
	_check(staged == kits, "every kit ship timed its setup stages (%d of %d)" % [staged, kits])
	_check(int(k.load_stats.get("worker_insts", 0)) == kits, "every kit hull was instanced on a worker (%d of %d)" % [int(k.load_stats.get("worker_insts", 0)), kits])
	# leaving mid-build never waits on the main thread for a worker instance (Artoo on PR 1445): a task still running
	# (300 ms) is handed on, collected over the next frames, and its instance freed
	var slow_out := [null]
	var slow := WorkerThreadPool.add_task(func() -> void:
		OS.delay_msec(300)
		slow_out[0] = Node3D.new())
	k._inst_tasks[999] = {"tid": slow, "out": slow_out}
	var td := Time.get_ticks_usec()
	k.stop_build()
	k.queue_free()
	await process_frame
	var leave_ms := (Time.get_ticks_usec() - td) / 1000
	_check(leave_ms < 150 and SV.retired_build_count() == 1, "leaving mid-build did not wait for a running worker instance (%d ms, %d retired)" % [leave_ms, SV.retired_build_count()])
	var tr0 := Time.get_ticks_msec()
	while SV.retired_build_count() > 0 and Time.get_ticks_msec() - tr0 < 5000:
		await process_frame
	await process_frame
	_check(SV.retired_build_count() == 0 and not is_instance_valid(slow_out[0]), "the retired instance was collected and freed over the next frames")
	SV._manifest = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	# the hull look a surface at a time (LOAD9: one hull's 17 surfaces took up to 840 ms): budget 0 does one per call
	var lv = SV.new()
	var lmi := MeshInstance3D.new()
	var lmesh := ArrayMesh.new()
	var larr := BoxMesh.new().get_mesh_arrays()
	for si in 5:
		lmesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, larr)
		lmesh.surface_set_material(si, StandardMaterial3D.new())
	lmi.mesh = lmesh
	lv.add_child(lmi)
	lv.meshes = [lmi]
	lv.fac = "voidsworn"
	var calls := 0
	var done := false
	while not done and calls < 20:
		done = lv._look_some(0)
		calls += 1
	var set_n := 0
	for si in 5:
		if lmi.get_surface_override_material(si) != null:
			set_n += 1
	_check(done and calls == 5 and set_n == 5 and int(lv.stage_us.get("look_counts", 0)) == 5005,
		"the hull look goes a surface per call on a zero budget (%d calls, %d of 5 set, counts %d)" % [calls, set_n, int(lv.stage_us.get("look_counts", 0))])
	lv.free()
	SV.clear_look_cache()
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
