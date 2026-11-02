extends SceneTree
# Read-only coverage against generated rule footprints. Does not change terrain.
const API := preload("res://rules/battle_api.gd")
const BOARD := preload("res://render/board.gd")
const WORLD := preload("res://world/world.gd")
const WR := preload("res://world/world_rocks.gd")
const JSM := preload("res://rules/jsm.gd")
var failures := 0
var total := 0
var kinds_seen := {}
func _init() -> void: process_frame.connect(_run, CONNECT_ONE_SHOT)
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func _contains(node: Node3D, p: Vector3) -> bool:
	if node is MeshInstance3D and node.mesh != null:
		var bounds: AABB = node.global_transform * node.mesh.get_aabb()
		if p.x >= bounds.position.x and p.x <= bounds.end.x and p.z >= bounds.position.z and p.z <= bounds.end.z: return true
	if node is MultiMeshInstance3D and node.multimesh != null:
		for i in node.multimesh.instance_count:
			var bounds: AABB = node.global_transform * node.multimesh.get_instance_transform(i) * node.multimesh.mesh.get_aabb()
			if p.x >= bounds.position.x and p.x <= bounds.end.x and p.z >= bounds.position.z and p.z <= bounds.end.z: return true
	for c in node.get_children():
		if c is Node3D and _contains(c, p): return true
	return false
func _batch_contains(world, p: Vector3) -> bool:
	# The headless dummy RenderingServer does not retain MultiMesh buffers.
	# Inspect the exact mesh and transforms submitted by the real batch builder.
	for group in world._batch.groups.values():
		if group.mat != world._mats.get(world._rock_kind + "|hero"): continue
		var mesh: Mesh = WR.mesh(group.mesh)
		if mesh == null: continue
		for xf in group.xf:
			if Vector2(xf.origin.x - p.x, xf.origin.z - p.z).length() > 0.1: continue
			var bounds: AABB = xf * mesh.get_aabb()
			if p.x >= bounds.position.x and p.x <= bounds.end.x and p.z >= bounds.position.z and p.z <= bounds.end.z: return true
	return false
func _run() -> void:
	var api := API.new()
	check(api.load_rules() == "", "rules loaded")
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	var cases := 0
	for map in ["belt", "planet", "station", "storm", "graveyard"]:
		for shape in api.R.SHAPES:
			for seed in [1001, 9027]:
				var scenario: Dictionary = scenarios.s1.duplicate(true)
				scenario.map = map; scenario.shape = shape; scenario.seed = seed
				api.new_battle_scenario(scenario)
				var view := api.view()
				var board := BOARD.new()
				root.add_child(board)
				board.props_world = true
				board.build(api)
				var world := WORLD.new()
				root.add_child(world)
				world.build(view, {"seed": seed, "fac": "hegemony", "quality": "low", "hex_world": board.hex_world,
					"biome": {"rock": ["stone", "iron", "carbon", "ice", "crystal"][cases % 5]}})
				var before := var_to_str(api.R.B)
				var rng_before := JSM.rng_u32()
				var version_before := api.version
				var expected := {}
				for k in view.terrain:
					if api.R.blocks(view.terrain[k]): expected[k] = view.terrain[k]
				if api.R.SOLID != null:
					for k in api.R.SOLID: expected[k] = api._blocker_kind(int(str(k).split(",")[0]), int(str(k).split(",")[1]))
				for k in expected:
					var qr: PackedStringArray = str(k).split(",")
					var p := board.hex_world(int(qr[0]), int(qr[1]))
					var kind: String = expected[k]
					kinds_seen[kind] = int(kinds_seen.get(kind, 0)) + 1
					var solid := _contains(board.props, p) or _batch_contains(world, p)
					if kind == "deadstar" and world.has_node("DeadStar"):
						solid = solid or _contains(world.get_node("DeadStar"), p)
					check(solid, "solid missing: %s %s %s %s" % [map, shape, kind, k])
					check(api.entry_reason(view.units[0].id, int(qr[0]), int(qr[1])).begins_with("Blocked by"), "blocked hex has a named reason: " + k)
					total += 1
				# Query and sight predicate must agree on the very same intermediate hexes.
				var a: Dictionary = view.units[0]
				var b: Dictionary = view.units[-1]
				check(api.line_blockers(a, b).is_empty() == api.R.los(a, b), "blocker query agrees with los")
				for h in api.line_blockers(a, b): check(api.R.sightBlocked(h.q, h.r), "outlined blocker really blocks")
				check(var_to_str(api.R.B) == before and JSM.rng_u32() == rng_before and api.version == version_before, "presentation queries preserve battle state, RNG and API version")
				world.free(); board.free()
				cases += 1
				await process_frame
	for kind in api.R.BLOCKING: check(kinds_seen.has(kind), "generated sample covers " + str(kind))
	print("BLOCKING_VISUALS battles=%d hexes=%d kinds=%s failures=%d" % [cases, total, str(kinds_seen), failures])
	quit(1 if failures else 0)
