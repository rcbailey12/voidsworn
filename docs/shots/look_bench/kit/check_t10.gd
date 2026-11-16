extends SceneTree
# Public volley replay, timing and stroke checks. Run against an imported project:
# godot --headless --path godot --script <absolute path to this file>
const FX := preload("res://fx/fx.gd")
const W := preload("res://fx/fx_weapons.gd")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func take(seed_value: int, quality: String, calm: bool) -> Dictionary:
	var fx = FX.new()
	root.add_child(fx)
	fx.setup({"seed": seed_value, "quality": quality, "reduce_flashing": calm})
	fx.manual = true
	var result := {}
	for wid in W.LOOK_BY_ID:
		if wid == "ram":
			continue
		var kind: String = "battery"
		for family in ["lance", "torp", "flak", "bio", "gauss", "sq"]:
			if W.LOOK_BY_ID[wid] in {"lance": ["lance", "ion", "pulsar", "doom"], "torp": ["torp", "rockets", "star"],
				"flak": ["flak", "spores", "gflak"], "bio": ["spine", "tendril"], "gauss": ["gauss"], "sq": ["guns", "bombs", "sporeb"]}[family]:
				kind = family
		var r: Dictionary = fx.volley_at(Vector3.ZERO, kind, Vector3(68, 0, 0),
			{"weapon_id": wid, "faction": "hegemony", "shots": [true, false, true, false], "pd": 1})
		check(r["fires"].size() == 4 and r["impacts"].size() == 4, wid + ": shot mapping changed")
		for i in 4:
			check(r["impacts"][i] >= r["fires"][i], wid + ": impact before fire")
			check(r["done"] >= r["impacts"][i], wid + ": done before impact")
			if i > 0:
				check(r["fires"][i] > r["fires"][i - 1], wid + ": reversed fire order")
		var gaps: Array = []
		for i in range(1, 4):
			gaps.append(r["fires"][i] - r["fires"][i - 1])
		check(gaps.max() > gaps.min() * 1.5, wid + ": metronome remains")
		result[wid] = r["fires"]
	# Read the actual submitted tracer data before a frame flushes it.
	result["strokes"] = fx.pools["stk"].pending.duplicate()
	check(not result["strokes"].is_empty(), "No tracer data was inspected")
	fx.release()
	fx.queue_free()
	return result

func surface_take(seed_value: int) -> Array:
	var fx = FX.new()
	root.add_child(fx)
	fx.setup({"seed": seed_value})
	var hull := Node3D.new()
	root.add_child(hull)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 4, 6)
	mesh.mesh = box
	hull.add_child(mesh)
	fx.add_ship("T", hull, {"faction": "hegemony", "cls": "Cruiser", "meshes": [mesh]})
	var target = fx.ship("T")
	var rhythm: RandomNumberGenerator = W._volley_rng(fx)
	var pattern: Array = W._volley_pattern(rhythm, 8)
	var clusters := {}
	var points: Array = []
	var from := Vector3(0, 10, 30)
	for i in 8:
		var tg: Dictionary = W._target(fx, target, Vector3.ZERO, from, true,
			{"hull": 1, "section": "mid"}, -1, 1.0, pattern[i], rhythm, clusters)
		var local: Vector3 = tg["lp"]
		check(target.hull.section_of(local.x) == 1, "Spread crossed a rolled section")
		var on_hull: Dictionary = target.hull.ray(from, local - from)
		check(not on_hull.is_empty() and (on_hull["p"] as Vector3).distance_to(local) < 0.001,
			"Spread placed an impact away from visible plating")
		points.append(local)
	fx.release()
	fx.queue_free()
	hull.queue_free()
	return points

func run() -> void:
	var a := take(11, "max", false)
	var b := take(11, "max", false)
	check(a == b, "Same seed did not reproduce fire times and submitted strokes")
	var c := take(12, "max", false)
	check(a != c, "Different seed did not change the replay")
	var surface := surface_take(11)
	check(surface == surface_take(11), "Same seed did not reproduce surface spread")
	check(surface != surface_take(12), "Different seed did not change surface spread")
	for quality in ["max", "low"]:
		for calm in [false, true]:
			var other := take(11, quality, calm)
			other.erase("strokes")
			var times := a.duplicate()
			times.erase("strokes")
			check(other == times, "Quality or calm changed firing rhythm")
	var accent_count := 0
	var fx = FX.new()
	fx.rng.seed = 11
	for volley in 100:
		var state: int = fx.rng.state
		var pattern: Array = W._volley_pattern(W._volley_rng(fx), 4)
		check(fx.rng.state == state, "Pattern consumed the FX particle stream")
		for pulse in pattern:
			if float(pulse["size"]) > 1.5:
				accent_count += 1
	check(accent_count == 100, "A full salvo has no standout stroke")
	fx.free()
	await process_frame
	FX.clear_static()
	print("T10_CHECK weapons=%d replay=exact quality_rhythm=exact accents=%d/100 failures=%d" % [a.size() - 1, accent_count, failures])
	quit(1 if failures else 0)
