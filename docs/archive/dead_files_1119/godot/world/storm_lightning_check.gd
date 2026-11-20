extends SceneTree
# Refs #368 run 6. Probe actual generated terrain, bolt meshes and production time.
const API = preload("res://rules/battle_api.gd")
const Gate = preload("res://bench/scene_gate.gd")
const Living = preload("res://world/world_living.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var api = API.new()
	assert(api.load_rules() == "")
	api.new_battle_scenario({"seed": 4207, "sector": 3, "admiral": "vex", "fleet": Gate.FLEET.duplicate(),
		"enemies": Gate.ENEMIES.duplicate(), "fac": "corsair", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}, 4207)
	var points: Array = []
	for key in api.R.B.terrain:
		if api.R.B.terrain[key] != "storm": continue
		var qr = str(key).split(",")
		var p: Dictionary = api.R.hexXZ({"q": int(qr[0]), "r": int(qr[1])})
		points.append(Vector3(p.x, 0, p.z))
	var world = load("res://world/world.gd").new()
	world.quality = "max"
	var gas = Living.new()
	gas.W = world
	gas.rng.seed = 368
	gas._bolts(points)
	var forks := 0
	var branch_vertices := 0
	for burst in gas._storm_bursts:
		assert(burst.bolts.size() >= 2 and burst.bolts.size() <= 4)
		burst.next = 0.6
		var positions: Array = []
		for bolt in burst.bolts:
			assert(bolt.fork_paths.size() >= 2 and bolt.fork_paths.size() <= 4)
			forks += bolt.fork_paths.size()
			for other in positions: assert(other.distance_to(bolt.pos) > 1.0)
			positions.append(bolt.pos)
			var mesh: ArrayMesh = bolt.mi.mesh
			var arrays = mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			# Find actual hot tube rings at the branch root and tip, not a counter.
			for path in bolt.fork_paths:
				var root_radius := 0.0
				var tip_radius := 0.0
				for i in vertices.size():
					if colours[i].r < 0.99 or colours[i].g < 0.99: continue
					var dr: float = vertices[i].distance_to(path[0])
					var dt: float = vertices[i].distance_to(path[-1])
					if dr < 0.12: root_radius = maxf(root_radius, dr)
					if dt < 0.02: tip_radius = maxf(tip_radius, dt)
				assert(root_radius > 0.10 and tip_radius > 0.004 and tip_radius < root_radius * 0.10)
			for colour in colours:
				if colour.r > 0.99: branch_vertices += 1
	var samples: Array = []
	for t in [0.58, 0.69, 0.77, 0.86, 0.96, 1.10]:
		while gas.clock < t - 0.00001: gas._process(minf(1.0 / 120.0, t - gas.clock))
		var row := {"time": gas.clock, "patch_visible": []}
		for burst in gas._storm_bursts:
			var visible := 0
			for bolt in burst.bolts:
				if gas._flash(gas.clock - bolt.start) > 0.04: visible += 1
			row.patch_visible.append(visible)
		samples.append(row)
	var overlapping := 0
	for sample in samples:
		if sample.patch_visible.all(func(n): return n >= 2): overlapping += 1
	assert(overlapping >= 4)
	assert(gas._flash(0.38) > 0.04 and gas._flash(0.38 * 1.6) == 0.0)
	assert(branch_vertices > 0)
	print("STORM_LIGHTNING ", JSON.stringify({"patches": gas._storm_bursts.size(), "bolts": gas.bolts.size(), "forks": forks,
		"actual_branch_vertices": branch_vertices, "samples": samples, "overlapping_samples": overlapping, "taper_and_faster_fade": true, "world_sha256": FileAccess.get_sha256("res://world/world_living.gd"), "fixture_rng_seed": 368}))
	gas.free()
	world.free()
	quit(0)
