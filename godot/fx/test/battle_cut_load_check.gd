extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const ROOT := preload("res://tools/ci/world_root.gd")
const HULLS := [
	["a16", "res://fx/test/fixtures/C19_51_unbaked.glb.gz", "corsair", "Battle-barge", 1.22],
	["t560", "res://render/test/fixtures/T560_fx/T560_fx.glb", "corsair", "Cruiser", 1.0],
	["h7a", "res://../contrib/codex/picket_astra_1122/export/hegemony_H7A.glb", "hegemony", "Frigate", 0.6],
]
var failures := 0


func _init() -> void:
	GUARD.arm(self, "battle_cut_load_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("  ok: " if ok else "  FAIL: ") + message)
	if not ok:
		failures += 1


func _load(path: String) -> Node3D:
	var full := ProjectSettings.globalize_path(path).simplify_path()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var result: Error
	if path.ends_with(".gz"):
		var bytes := FileAccess.get_file_as_bytes(full).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		result = doc.append_from_buffer(bytes, full.get_base_dir(), state)
	else:
		result = doc.append_from_file(full, state)
	if result != OK:
		return null
	return doc.generate_scene(state)


func _geometry(pieces: Array) -> Array:
	var geometry: Array = []
	for pc in pieces:
		geometry.append([pc["surfs"], pc.get("cap", []), pc["n"], pc["pts"], pc["edge"], pc.get("lip", []),
			pc.get("boundary_edges", 0), pc.get("cap_loops", 0), pc.get("cap_fallbacks", 0)])
	return geometry


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.setup({"quality": "low"})
	fx.defer_initial_cuts = true
	var twin: Node3D
	for hull in HULLS:
		var model := _load(hull[1])
		_check(model != null, "%s fixture loads" % hull[0])
		if model == null:
			world.free()
			quit(1)
			return
		var holder := ROOT.hold(world, model)
		if hull[0] == "t560":
			twin = holder.duplicate()
			world.add_child(twin)
		fx.add_ship(hull[0], holder, {"faction": hull[2], "cls": hull[3], "size": hull[4], "shielded": false})
	var t0 := Time.get_ticks_usec()
	await fx.prepare_battle_hulls()
	print("  prepared three hulls in %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	for hull in HULLS:
		var ship := fx.ship(hull[0])
		var job: Dictionary = ship.get_meta("cut_job", {})
		var pieces: Array = job.get("out", [])
		# The original serial pass is the reference. Compare full ordered surface and cap arrays.
		DEATH.cut_serial = true
		var reference := DEATH._cut(job)
		DEATH.cut_serial = false
		_check(job.get("built", false) and not pieces.is_empty() and _geometry(pieces) == _geometry(reference),
			"%s load cut matches its serial pieces (%d)" % [hull[0], pieces.size()])
	_check(fx.ship("a16").hull.authored, "A16 uses its authored seams")

	# Prepare two instances from the same resources and seed, then vary the cut seed alone.
	# The hull analysis also uses the ID for its surface samples and core search.
	fx.defer_initial_cuts = true
	var first := fx.ship("t560")
	fx.discard_ship_cut(first)
	fx.ships.erase("t560")
	fx.add_ship("t560", twin, {"faction": "corsair", "cls": "Cruiser", "size": 1.0, "shielded": false})
	var second := fx.ship("t560")
	fx.ships["t560"] = first
	fx.ships["twin"] = second
	second.id = "twin"
	var shared := {}
	DEATH.precompute(fx, first, "blast", true, shared)
	DEATH.precompute(fx, second, "blast", true, shared)
	_check(first.get_meta("cut_task") != second.get_meta("cut_task"), "different ship seeds split into separate jobs")
	fx.discard_ship_cut(second)
	second.id = first.id
	var mesh := second.meshes.back() as MeshInstance3D
	var rest := mesh.position
	mesh.position += Vector3(0.05, 0.0, 0.0)
	DEATH.precompute(fx, second, "blast", true, shared)
	_check(first.get_meta("cut_task") != second.get_meta("cut_task"), "different geometry with the same seed needs its own cut")
	fx.discard_ship_cut(second)
	mesh.position = rest
	DEATH.precompute(fx, second, "blast", true, shared)
	second.id = "twin"
	_check(first.get_meta("cut_task") == second.get_meta("cut_task"), "identical snapshots share one job")
	while not DEATH.finish_precompute(fx, first) or not DEATH.finish_precompute(fx, second):
		await process_frame
	var a: Array = first.get_meta("cut_job")["out"]
	var b: Array = second.get_meta("cut_job")["out"]
	_check(not a.is_empty() and _geometry(a) == _geometry(b), "both ships receive the shared geometry")
	_check(not a.is_empty() and not is_same(a[0], b[0]), "each ship owns its piece state")

	var ship := fx.ship("a16")
	fx.discard_ship_cut(ship)
	DEATH.precompute(fx, ship, "blast", true)
	var cut: DEATH.CutWork = ship.get_meta("cut_work")
	world.remove_child(fx)
	FX.drain_retired()
	_check(fx.cut_abort.cancelled() and cut.pieces.is_empty(), "leaving the battle aborts a pending A16 cut")
	fx.free()
	world.free()
	print("battle_cut_load_check: %d failures" % failures)
	quit(1 if failures else 0)
