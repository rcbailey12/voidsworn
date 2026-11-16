extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 521 (R193 "Hold and slow"; R73): the slow-motion beat plays at the core flash of a cruiser, capital or flagship
# kill once the battle turns it on (fx.kill_slowmo), never for a small hull, never while it is off (reduce motion), and a
# key or a click (skip_death_slowmo) ends it and stops a queued one. Headless.
#   godot --headless --path godot --script res://fx/test/kill_slowmo_check.gd
const FX := preload("res://fx/fx.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "kill_slowmo_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _ship(world: Node3D, fx, id: String, cls: String, size: float) -> void:
	var r := Node3D.new()
	world.add_child(r)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 3, 4)
	bm.subdivide_width = 11
	bm.subdivide_height = 2
	bm.subdivide_depth = 3
	mi.mesh = bm
	r.add_child(mi)
	fx.add_ship(id, r, {"faction": "voidsworn", "cls": cls, "size": size, "meshes": [mi]})


# Plays a death with the beat on or off; returns [core flash time from the kill, first slow frame, last slow frame].
func _play(cls: String, size: float, on: bool, skip_at := -1.0) -> Array:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	fx.kill_slowmo = on
	_ship(world, fx, "T", cls, size)
	var t0: float = fx.now
	fx.death("T", "blast")
	var core: float = fx.death_core_at("T")
	var first := -1.0
	var last := -1.0
	var real_t := 0.0
	while real_t < 5.0:
		fx.step(1.0 / 60.0)
		real_t += 1.0 / 60.0
		if skip_at >= 0.0 and absf(real_t - skip_at) < 0.5 / 60.0:
			fx.skip_death_slowmo()
		if fx._death_slow_left > 0.0:
			if first < 0.0:
				first = fx.now - t0
			last = fx.now - t0
	fx.release()
	world.queue_free()
	await process_frame
	return [core - t0 if core >= 0.0 else -1.0, first, last]


func _run() -> void:
	var cr: Array = await _play("Cruiser", 0.76, true)
	_check(absf(float(cr[0]) - 1.66) < 0.02, "a cruiser's core flash is at 1.66 s (got %.2f)" % cr[0])
	_check(float(cr[1]) >= float(cr[0]) - 0.02 and float(cr[1]) <= float(cr[0]) + 0.05, "a cruiser kill's beat starts at the core flash (%.2f, flash %.2f)" % [cr[1], cr[0]])
	var cap: Array = await _play("Dreadnought", 1.18, true)
	_check(absf(float(cap[0]) - 2.28) < 0.02, "a capital's core flash is at 2.28 s (got %.2f)" % cap[0])
	_check(float(cap[1]) >= float(cap[0]) - 0.02 and float(cap[1]) <= float(cap[0]) + 0.05, "a capital kill's beat starts at the core flash (%.2f, flash %.2f)" % [cap[1], cap[0]])
	var small: Array = await _play("Frigate", 0.46, true)
	_check(float(small[0]) < 0.0 and float(small[1]) < 0.0, "a frigate kill has no core flash and no beat")
	var off: Array = await _play("Cruiser", 0.76, false)
	_check(float(off[1]) < 0.0, "with the beat off (reduce motion) a cruiser kill plays at full speed")
	var skipped: Array = await _play("Cruiser", 0.76, true, 1.0)
	_check(float(skipped[1]) < 0.0, "a key or a click before the core flash stops the queued beat")
	var mid: Array = await _play("Cruiser", 0.76, true, 1.8)
	_check(float(mid[1]) >= 0.0 and float(mid[2]) < float(mid[1]) + 0.1, "a key or a click during the beat ends it (%.2f to %.2f)" % [mid[1], mid[2]])
	print("KILL_SLOWMO cruiser core %.2f beat %.2f-%.2f | capital core %.2f beat %.2f-%.2f | failures=%d" % [cr[0], cr[1], cr[2], cap[0], cap[1], cap[2], failures])
	quit(1 if failures > 0 else 0)
