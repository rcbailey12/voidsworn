extends SceneTree
# issue 1077: these checks measure the multi-cut split (two cuts, three sections, staged parting), which stays the
# death_story="off" path; the default one-crack strained death has its own check, fx/test/death_story_check.gd.
const GUARD = preload("res://tools/ci/check_guard.gd")
# Runtime contracts for staged deaths, class gating, flash limits and the hurry key.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0

func _init() -> void:
	GUARD.arm(self, "destruction_staging_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ship(world: Node3D, fx, cls: String, size: float, flagship := false, sid := "T"):
	var r := Node3D.new()
	world.add_child(r)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 3, 4)
	bm.subdivide_width = 11
	bm.subdivide_height = 2
	bm.subdivide_depth = 3
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.8)
	mi.material_override = mat
	r.add_child(mi)
	fx.add_ship(sid, r, {"faction": "voidsworn", "cls": cls, "size": size, "flagship": flagship, "meshes": [mi]})
	return fx.ship(sid)

# Issue 484 (owner, Nov 11: "straight lines and even halves"): a big death's wreck is blown apart, not sliced. Fails
# when the main pieces are near-equal, the bite of hull where the core went off is missing, or the break is one straight
# line square across the hull.
func _check_blown_apart(s, w: Dictionary, capital: bool) -> void:
	var job: Dictionary = s.get_meta("cut_job", {})
	var plan: Dictionary = job.get("plan", {})
	_check(not plan.is_empty(), "a big hull breaks on a fracture plan")
	if plan.is_empty(): return
	var pieces: Array = job.get("out", [])
	var n_main: int = int(plan["n_main"])
	var L: float = s.hull.L
	# piece size by its share of the hull's side skin (even along the box's length; a slanted break makes the pieces'
	# end to end extents overlap, so extents would hide the difference)
	var sizes: Array = []
	for i in n_main:
		var area := 0.0
		for sd in pieces[i]["surfs"]:
			var v: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
			for t in range(0, idx.size() - 2, 3):
				var c: Vector3 = (v[idx[t + 1]] - v[idx[t]]).cross(v[idx[t + 2]] - v[idx[t]])
				if absf(c.normalized().x) < 0.9: area += c.length() * 0.5   # the side skin, not the box's end faces
		sizes.append(area)
	sizes.sort()
	_check(float(sizes[0]) <= float(sizes.back()) * 0.72, "the pieces are plainly uneven (smallest %.1f, largest %.1f)" % [sizes[0], sizes.back()])
	if capital:
		_check(float(sizes[1]) <= float(sizes[2]) * 0.88 and float(sizes[0]) <= float(sizes[1]) * 0.88, "a capital's three pieces are three different sizes (%s)" % str(sizes))
	# the bite: hull fragments cut out where the core went off, a real share of the length, thrown out as pieces
	var subs: int = (plan["bite"]["subs"] as PackedVector3Array).size()
	var bite_box := AABB()
	var bite_n := 0
	for i in range(n_main, n_main + subs):
		for p in (pieces[i]["pts"] as PackedVector3Array):
			bite_box = AABB(p, Vector3.ZERO) if bite_n == 0 else bite_box.expand(p)
			bite_n += 1
	_check(bite_n > 0 and bite_box.size.x >= L * 0.12, "a bite of hull is missing where the core went off (%.2f of the length)" % (bite_box.size.x / L))
	_check((w.get("frags", []) as Array).size() >= 3, "the bite's fragments fly as their own pieces")
	# no straight line: across the beam, the torn end of the first piece wanders along the length
	var bins := {}
	for p in (pieces[0]["pts"] as PackedVector3Array):
		var b := int(floor((p.z - s.hull.box.position.z) / maxf(s.hull.W, 0.001) * 4.0))
		bins[b] = maxf(float(bins.get(b, -INF)), p.x)
	var ends: Array = bins.values()
	ends.sort()
	_check(ends.size() >= 2 and float(ends.back()) - float(ends[0]) >= L * 0.05, "the break is not one straight line square across the hull")

func _advance(fx, seconds: float) -> void:
	var end: float = fx.now + seconds
	while fx.now < end:
		fx.step(1.0 / 60.0)
		await process_frame

func _run() -> void:
	for spec in [["Frigate", 1.5, false, false], ["Escort", 0.5, false, false], ["Destroyer", 1.5, false, false],
		["Cruiser", 0.4, false, true], ["Destroyer", 0.4, true, true], ["Battleship", 1.0, false, true], ["Squadron", 0.1, false, false]]:
		for calm in [false, true]:
			var world := Node3D.new()
			root.add_child(world)
			var fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"death_story": "off", "quality": "high", "reduce_flashing": calm, "shake": 0.0})
			fx.check_radius = true
			# Issue 504: the beats are staged on bright-flash requests (flash_area_log); the safety checks (zero counted in
			# calm mode, never more than three counted in a rolling second) stay on flash_log, the counted flashes.
			fx.flash_area_logging = true
			var s = _ship(world, fx, spec[0], spec[1], spec[2])
			_check(s.death_big == spec[3], "slow motion uses class/flagship, independent of size")
			DEATH.precompute(fx, s)
			await _advance(fx, 0.7)
			var root_pose: Transform3D = s.root.transform
			var mesh_pose: Transform3D = s.meshes[0].transform
			# The small jet starts on the killing frame, so measure requests before death().
			var before: int = fx.flash_log.size()
			var before_req: int = fx.flash_area_log.size()
			var duration: float = fx.death("T", "big")
			if s.squadron:
				_check(duration > 0.0 and duration <= 0.25, "a wing dies as a brief spark")
				_check(s.has_meta("death_hidden"), "a wing disappears on its spark")
				await _advance(fx, 1.0 / 60.0)
				var sparks := 0
				for node in fx.get_children():
					if node is MeshInstance3D and node.get_meta("fx_picture_kind", "") == "flash":
						sparks += 1
						var mat: ShaderMaterial = node.material_override
						_check(float(mat.get_shader_parameter("min_pixels")) < 40.0, "wing spark uses the sub-40 px row")
						_check(float(mat.get_shader_parameter("lifetime")) <= (0.70 if calm else 1.0 / 60.0), "wing flash keeps its one-frame normal life and softened twin")
				_check(sparks == 1, "a wing emits one spark")
				await _advance(fx, 0.4)
				_check(fx.dstate.wrecks.is_empty() and fx.dstate.debris.is_empty(), "a wing has no wreck or physical debris")
				_check(fx.stray_spawns().is_empty(), "a wing spark and puff start on a craft")
				_check(fx._pauses.is_empty() and fx._death_slow_left == 0.0, "wing deaths never hold the battle")
				print("DESTRUCTION_STAGE wing calm=%s duration=%.3f wrecks=0" % [calm, duration])
				fx.release()
				world.queue_free()
				await process_frame
				continue
			# issue 462: a capital's tell runs to 2.0 s, so its death is longer (deaths_and_hits.md rule 3)
			_check(duration >= (1.0 if s.death_big else 0.72) and duration < (2.8 if s.death_tier == "capital" else (2.1 if s.death_big else 1.0)), "bounded staged death duration")
			await _advance(fx, 0.36)
			_check(s.meshes[0].visible, "hull remains through power-down/death spin")
			_check(s._eng_cur < 0.02, "engines extinguish before split")
			for m in s.get_meta("death_power", []):
				_check(float(m.get_shader_parameter("fx_power")) < 0.01, "running-light emission extinguishes")
			# A big hull waits for its first chain blast; a small hull vents on the kill frame.
			_check(fx.flash_log.size() - before == 0 if calm else fx.flash_area_log.size() - before_req == (0 if s.death_big else 1), "one vent ignition before the split, none counted in calm mode")
			if s.death_big:
				_check(s._eng_cur < 0.02 and s.has_meta("death_flare_until"), "the drive flared once and is black by 0.36 s")
			if not s.death_big:
				_check(s.meshes[0].transform != mesh_pose, "small hull spins before break")
				_check(s.root.transform == root_pose, "death spin does not move the rules/view root")
				_check(fx._pauses.is_empty() and fx._death_slow_left == 0.0, "small kills have no hit pause/slow motion")
			if s.death_big:
				# Issue 462, beat 1: the tear is drawn on the hull and chain blasts flash along it before the break.
				var tl = s.get_meta("death_timeline")
				_check(tl.tier == ("capital" if spec[0] == "Battleship" else "cruiser"), "the class picks the cruiser or capital row")
				await _advance(fx, 1.2 - 0.36)
				var ov = s.meshes[0].material_overlay
				_check(ov is ShaderMaterial and (ov as ShaderMaterial).get_shader_parameter("half_span") != null, "the tear is drawn on the dying hull")
				_check(s.meshes[0].visible, "the hull holds through the tell")
				var chain_n: int = fx.flash_log.size() - before
				_check(chain_n == 0 if calm else fx.flash_area_log.size() - before_req >= 2, "chain blasts flash during the tell (none counted in calm mode)")
				# beat 2: the break, then the core flash 0.28 s later at the torn face
				await _advance(fx, float(tl.cut) + float(tl.core_delay) + 0.1 - 1.2)
				_check(not s.meshes[0].visible, "the hull parts at the break")
				var t_split: float = float(fx.dstate["wrecks"][0]["t0"]) if not fx.dstate["wrecks"].is_empty() else -10.0
				var core_seen := false
				for r in fx.flash_area_log.slice(before_req):
					var f: float = float(r[0])
					if f >= t_split + float(tl.core_delay) - 0.02 and f <= t_split + float(tl.core_delay) + 0.13: core_seen = true
				_check(calm or core_seen, "the core flash follows the break by 0.28 s")
				_check(fx.flash_log.size() - before == 0 if calm else fx.flash_area_log.size() - before_req >= 3, "bounded vent, chain and core flash sequence")
			else:
				await _advance(fx, 0.55)
				_check(fx.flash_log.size() - before == 0 if calm else fx.flash_area_log.size() - before_req >= 2, "vent and core flash sequence")
				_check(s.get_meta("death_timeline").tier == ("destroyer" if spec[0] == "Destroyer" else "small"), "small hulls use their class row even at an oversized draw scale")
			var warm := {}
			for wreck in fx.dstate.wrecks:
				for mat in wreck.mats: warm[mat] = float(mat.get_shader_parameter("heat"))
			await _advance(fx, 3.6)
			_check(not s.meshes[0].visible, "live hull replaced after split")
			_check(fx.dstate["wrecks"].size() == 1, "one lingering wreck record per kill")
			var w: Dictionary = fx.dstate["wrecks"][0]
			if s.death_big:
				var capital: bool = s.death_tier == "capital"
				# R186/R215: the rule is a wreck that is blown apart and not hollow, never a typed piece count. Check the
				# pieces the plan made: every main piece has an opaque torn face, every released piece has its cut event,
				# and the break is not one straight full-width line (checked in _check_blown_apart).
				var job: Dictionary = s.get_meta("cut_job", {})
				var plan: Dictionary = job.get("plan", {})
				var main_pieces: Array = job.get("out", [])
				var n_main: int = int(plan.get("n_main", 0))
				var hollow := 0
				for i in n_main:
					if i >= main_pieces.size() or not main_pieces[i].has("cap") \
							or (main_pieces[i]["cap"][Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
						hollow += 1
				_check(n_main > 0 and hollow == 0, "every main piece has an opaque torn face (hollow pieces: %d)" % hollow)
				var cuts: Array = w["cut_events"]
				_check(not w["nodes"].is_empty() and cuts.size() == w["nodes"].size(), "every parted piece is released once")
				_check(float(cuts.back().t) - float(cuts.front().t) >= 0.28 if capital else true, "a capital's pieces part one after another")
				_check(float(w.get("cool", 0.0)) >= (14.0 if capital else 8.0), "big wrecks cool over the playbook's time")
				var late := 0
				for r in fx.flash_area_log.slice(before_req):
					if float(r[0]) >= float(w["t0"]) + 0.6: late += 1
				_check(calm or late >= 2, "secondaries flash on the pieces after the core")
				_check_blown_apart(s, w, capital)
			var flashes: int = fx.flash_log.size() - before
			_check(fx.stray_spawns().is_empty(), "death pictures start on the hull or their drifting piece")
			_check(flashes == 0 if calm else fx.flash_area_log.size() - before_req >= 1, "calm has zero flashes; normal keeps its core")
			for a in fx.flash_log:
				var in_second := 0
				for b in fx.flash_log:
					if b >= a and b < a + 1.0: in_second += 1
				_check(in_second <= 3, "secondary explosions respect the rolling flash limit")
			if s.weight > 0:
				_check(not w["nodes"].is_empty(), "small ship retains a tumbling hull chunk")
				if not s.death_big:
					_check(w["nodes"].size() >= 2 and w["nodes"].size() <= 4, "small hull throws two to four chunks")
					_check(w["mats"].size() == (0 if fx.quality == "low" else 1), "one small chunk keeps glowing coals")
				for m in w["mats"]:
					_check(float(m.get_shader_parameter("heat")) < float(warm.get(m, 1.0)), "wreck ember cools from its own release time")
				for f in w["fires"]:
					if f.has("cool"):
						_check(float(f["mat"].get_shader_parameter("gate")) > 0.5, "slow coals survive the initial flames")
			# R186/R215: the wreck cleans up. Clear this kill's wreck and check every one of its pieces was released.
			var pieces_alive := 0
			fx.clear_wreck("T")
			await process_frame
			for nd in w["nodes"]:
				if is_instance_valid(nd): pieces_alive += 1
			_check(fx.dstate["wrecks"].is_empty() and pieces_alive == 0, "wreck cleanup frees every piece")
			print("DESTRUCTION_STAGE class=%s size=%.1f flagship=%s calm=%s duration=%.2f pieces=%d flashes=%d" % [spec[0], spec[1], spec[2], calm, duration, w["nodes"].size(), flashes])
			fx.release()
			world.queue_free()
			await process_frame
	# A mass wing loss stays tiny and leaves no lingering ship effects, in either comfort setting.
	for calm in [false, true]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = FX.new()
		world.add_child(fx)
		fx.manual = true
		fx.setup({"death_story": "off", "quality": "high", "reduce_flashing": calm})
		for i in 20:
			_ship(world, fx, "Squadron", 0.1, false, "wing%d" % i)
		for id in fx.ships: fx.death(id, "blast")
		fx.step(1.0 / 60.0)
		for node in fx.get_children():
			if node is MeshInstance3D and node.has_meta("fx_picture_kind"):
				var mat: ShaderMaterial = node.material_override
				_check(float(mat.get_shader_parameter("min_pixels")) < 40.0, "twenty wing sparks keep the sub-40 px row")
		await _advance(fx, 0.5)
		_check(fx.dstate.wrecks.is_empty() and fx.dstate.debris.is_empty(), "twenty wings leave no wrecks or debris")
		_check(fx.flash_log.size() <= 3 and (not calm or fx.flash_log.is_empty()), "mass wing loss respects the flash counter")
		print("DESTRUCTION_WINGS count=20 calm=%s wrecks=0 flashes=%d" % [calm, fx.flash_log.size()])
		fx.release()
		world.queue_free()
		await process_frame
	# The whole hulk is independent of the original root and has exactly one gas
	# emitter, no lights/fire/core, bounded drift, and the same wreck cleanup.
	for quality in ["high", "low"]:
		var world := Node3D.new()
		root.add_child(world)
		var fx = FX.new()
		world.add_child(fx)
		fx.manual = true
		fx.setup({"death_story": "off", "quality": quality, "shake": 0.0})
		var s = _ship(world, fx, "Cruiser", 0.8)
		fx.death("T", "dark")
		await _advance(fx, 0.8)
		var w: Dictionary = fx.dstate["wrecks"][0]
		_check(w.get("hulk", false) and w["nodes"].size() == 1, "whole hulk outcome")
		var hulk: Node3D = w["nodes"][0]
		_check(hulk.find_children("fx_hulk_vent", "MeshInstance3D", false, false).size() == 1, "hulk has one gas vent")
		_check(w["lights"].is_empty() and w["mats"].is_empty() and fx.flash_log.is_empty(), "hulk has no lights, fire or flashes")
		var start := hulk.global_position
		fx.remove_ship("T")
		s.root.queue_free()
		await _advance(fx, 6.0)
		_check(is_instance_valid(hulk) and hulk.global_position.distance_to(start) > 0.1, "hulk drifts after live root removal")
		fx.clear_wreck("T")
		await process_frame
		_check(not is_instance_valid(hulk), "hulk cleanup releases its node")
		print("DESTRUCTION_HULK quality=%s cold_drift=ok cleanup=ok" % quality)
		fx.release()
		world.queue_free()
		await process_frame
	# A real-time bound at three frame rates; hurry cancels both an active and a queued beat.
	for hz in [30.0, 60.0, 144.0]:
		var fx = FX.new()
		root.add_child(fx)
		fx.manual = true
		fx.setup({"death_story": "off", "quality": "low"})
		fx.death_slowmo()
		var real_t := 0.0
		while fx._death_slow_left > 0.0 or fx.anim_speed() < 0.99:
			fx.step(1.0 / hz)
			real_t += 1.0 / hz
		_check(real_t < 0.8, "kill slow motion ends under one real second")
		fx.death_slowmo()
		fx.hurry_death()
		fx.death_slowmo()
		fx.step(1.0 / hz)
		_check(fx.anim_speed() == 1.0 and fx._death_slow_left == 0.0, "Enter/Space hurry cancels current and queued beat")
		print("DESTRUCTION_SLOWMO hz=%d real_seconds=%.3f hurry=ok" % [hz, real_t])
		fx.queue_free()
		await process_frame
	print("DESTRUCTION_STAGING failures=%d" % failures)
	quit(1 if failures > 0 else 0)
