extends SceneTree
## Refs #2087. CPU timing probe, not a frame-time gate. Run from the repo root:
## godot --headless --path godot --script res://bench/arrival_damage_probe.gd [-- <installed godot/gen folder>]
## Use the installed A4 scenes, never the block or the legacy mesh fallback.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SV := preload("res://render/ship_view.gd")
const HULL := preload("res://fx/fx_hull.gd")

# Six wounds-reference hulls plus a second hull each for Chorus and Glasswrights.
const HULLS := [
	["I15_11", "ithar", "Cruiser"],
	["B21_11", "chorus", "Cruiser"],
	["V16_37", "voidsworn", "Cruiser"],
	["H10_23", "hegemony", "Battleship"],
	["C15s_23", "corsair", "Cruiser"],
	["D21_23", "deathless", "Cruiser"],
	["I8_37", "ithar", "Ark"],
	["B22_11", "chorus", "Carrier"],
]
const HITS := [["torp", 3, "mid"], ["battery", 1, "prow"], ["torp", 3, "eng"]]
const STEP := 1.0 / 60.0


func _init() -> void:
	GUARD.arm(self, "arrival_damage_probe", 420.0)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var gen := str(args[0]).replace("\\", "/") if not args.is_empty() else "res://gen"
	SV.manifest_path = gen.path_join("manifest.json")
	var ships: Dictionary = SV.manifest().get("ships", {})
	for row in HULLS:
		var code: String = row[0]
		var path := gen.path_join("ships/%s.scn" % code)
		if not ships.has(code) or not ResourceLoader.exists(path, "PackedScene"):
			printerr("ARRIVAL_PROBE missing A4 scene: ", path)
			quit(1)
			return
		ships[code]["res"] = path
	print("ARRIVAL_PROBE source=", gen, " display=", DisplayServer.get_name())
	for row in HULLS:
		if not await _measure(row):
			quit(1)
			return
	print("ARRIVAL_PROBE PASS (%d hulls)" % HULLS.size())
	quit()


func _measure(row: Array) -> bool:
	var code: String = row[0]
	var world := Node3D.new()
	root.add_child(world)
	var sv := SV.new()
	world.add_child(sv)
	seed(2070)
	sv.setup({"id": "T", "code": code, "fac": row[1], "cls": row[2], "facing": 0,
		"hp": 100, "maxHp": 100, "size": 1.0}, Vector3.ZERO, true)
	sv.set_process(false)
	if not sv.a4:
		printerr("ARRIVAL_PROBE did not load the A4 hull: ", code)
		world.queue_free()
		return false
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "seed": 20261026, "shake": 0.0})
	fx.warmed = true   # Match the bench's arrival branch, without drawing a warm-up.
	fx.defer_initial_cuts = false
	fx.add_ship("T", sv, {"faction": row[1], "cls": row[2], "code": code, "size": 1.0, "shielded": false})
	var s := fx.ship("T")
	fx.prof_take()
	print("ARRIVAL_PROBE begin ", code, " wounds_v2=", s.wounds_v2)
	# Advance the scheduled arrival to submission, then time the worker apart from the mesh install.
	var t0 := Time.get_ticks_usec()
	while not s.has_meta("cut_task") and fx.now < 0.25:
		fx.step(STEP)
	if not s.has_meta("cut_task"):
		printerr("ARRIVAL_PROBE no arrival cut: ", code)
		world.queue_free()
		return false
	var t_worker := Time.get_ticks_usec()
	var tid: int = s.get_meta("cut_task")
	while not WorkerThreadPool.is_task_completed(tid):
		await process_frame
	var worker_ms := _ms(Time.get_ticks_usec() - t_worker)
	var job: Dictionary = s.get_meta("cut_job")
	DEATH.finish_precompute(fx, s)
	# Let the frame budget build pieces, but pin effect time so the wound time uniforms hash the same on every run.
	while not job.get("built", false):
		fx.step(0.0)
		await process_frame
	var ready_ms := _ms(Time.get_ticks_usec() - t0)
	var tris := 0
	var skin_tris := 0
	for sd in job["surfs"]:
		var n := _triangles(sd["arrays"])
		tris += n
		if not sd["interior"]:
			skin_tris += n
	var parts: Array = job.get("out", [])
	if parts.is_empty():
		printerr("ARRIVAL_PROBE empty arrival cut: ", code)
		world.queue_free()
		return false
	var prof := fx.prof_take()
	var cuts: Array = []
	for pc in parts:
		var surfaces: Array = []
		for sd in pc["surfs"]:
			surfaces.append(hash(sd["arrays"]))
		cuts.append([surfaces, hash(pc.get("cap", []))])
	print("ARRIVAL_PROBE cut %s tri=%d exterior_tri=%d gather_ms=%.2f worker_wait_ms=%.2f cut_ms=%.2f hull_reach_ms=%.2f prebuild_ms=%.2f worst_prebuild_ms=%.2f ready_ms=%.2f pieces=%d geometry=%s"
		% [code, tris, skin_tris, _ms(prof.get("cut_first", 0)), worker_ms, _ms(job["cut_usec"]), _ms(job["hulls_usec"]),
			_ms(prof.get("piece_meshes", 0)), _ms(job["build_max_usec"]), ready_ms, parts.size(), hash(cuts)])
	# Isolate wound worker time from the next death recut. This is the normal six-second refresh cooldown
	# after a just-built cut, and the manual clock advances only a handful of steps here.
	s._cut_t = fx.now
	var phase := 0
	for hit in HITS:
		var p: Dictionary = s.hull.hit_point(Vector3(0, 0, -60), HULL.SEC_NAMES[hit[2]])
		s.add_mark(fx, hit[0], hit[1], p["p"], p["n"], Vector3.BACK)
		phase += 1
		if not await _rebuild(fx, s, code, "hit%d" % phase):
			world.queue_free()
			return false
	fx.sync_ship("T", {"hp": 50, "maxHp": 100, "sh": [0, 0, 0, 0],
		"sec": {"prow": {"hp": 55, "max": 100}, "mid": {"hp": 35, "max": 100}, "eng": {"hp": 45, "max": 100}}})
	var ok := await _rebuild(fx, s, code, "hp50")
	world.queue_free()
	await process_frame
	return ok


func _rebuild(fx: FX, s, code: String, phase: String) -> bool:
	if s._dmg_task < 0:
		printerr("ARRIVAL_PROBE no wound rebuild: %s %s" % [code, phase])
		return false
	var pass_no := 0
	while s._dmg_task >= 0:
		var tid: int = s._dmg_task
		var job: Dictionary = s._dmg_job
		while not WorkerThreadPool.is_task_completed(tid):
			await process_frame
		s.flush_damage(fx)   # A sync can queue another rebuild while regrading marks and changing wound stages.
		var out: Dictionary = job["out"]
		var prof := fx.prof_take()
		pass_no += 1
		print("ARRIVAL_PROBE rebuild %s %s pass=%d ents=%d gather_ms=%.2f worker_ms=%d surface_ms=%d apply_ms=%.2f geometry=%s"
			% [code, phase, pass_no, job["ents"].size(), _ms(prof.get("hull_gather", 0)),
				out["ms"], out["phases"][0], _ms(prof.get("breach_apply", 0)),
				hash([out["surfs"], out["inside_a"], out["skin_a"]])])
	return true


func _triangles(arrays: Array) -> int:
	var idx = arrays[Mesh.ARRAY_INDEX]
	return (idx.size() if idx != null and not idx.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3


func _ms(usec: int) -> float:
	return usec / 1000.0
