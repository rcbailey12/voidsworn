extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1713 (Ryan, Nov 22 2026: "torpedoes all seem to go up and then down, why? I'd think we'd keep it flat"):
# a torpedo or rocket slides out of its tube (1379, kept) at no more than about 20 degrees up, then flies flat to the
# target: no point of its flight rises above the higher of its ignition point and its target.
const FX := preload("res://fx/fx.gd")
const FXW := preload("res://fx/fx_weapons.gd")
var failures := 0

func _init() -> void:
	GUARD.arm(self, "torpedo_flat_flight_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	var fac := {"engine": Color(1.0, 0.6, 0.3)}
	var cases := [
		["torp", Vector3.UP, "deck tube"],
		["torp", Vector3(0.3, 0.9, 0.2).normalized(), "tilted deck tube"],
		["torp", Vector3(1, 0, 0), "bow tube"],
		["torp", Vector3(0, 0, 1), "side tube"],
		["rockets", Vector3.UP, "deck rack"],
		["star", Vector3.UP, "star"],
	]
	var checked := 0
	for c in cases:
		for to in [Vector3(60, 2, 10), Vector3(25, 2, -8), Vector3(90, 0, 0)]:
			var from := Vector3(0, 2, 0)
			fx.dstate["proj"] = []
			FXW._launch(fx, c[0], from, c[1], to, 1.0, 3.0, Color.WHITE, fac, 1.0, 0, false, null, null, 1.0, "hegemony")
			var expected := 4 if c[0] == "rockets" else 1
			check(fx.dstate["proj"].size() == expected, "%s to %s launched %d rounds (want %d)" % [c[2], to, fx.dstate["proj"].size(), expected])
			for p in fx.dstate["proj"]:
				var a: Vector3 = p["a"]
				var ed: Vector3 = p["ed"]
				check(ed.y <= 0.35, "%s %s: slide rises at most about 20 degrees (sine %.2f)" % [c[0], c[2], ed.y])
				var top := maxf(a.y, (p["c"] as Vector3).y) + 0.05
				var peak := -INF
				for s in 41:
					peak = maxf(peak, FXW._bez(p["a"], p["b"], p["c"], float(s) / 40.0).y)
				check(peak <= top, "%s %s to %s: flight stays flat (peak %.2f, limit %.2f)" % [c[0], c[2], to, peak, top])
				checked += 1
				if is_instance_valid(p["mesh"]):
					(p["mesh"] as Node).queue_free()
	fx.dstate["proj"] = []
	print("TORPEDO_FLAT_FLIGHT failures=%d rounds=%d" % [failures, checked])
	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	quit(1 if failures else 0)
