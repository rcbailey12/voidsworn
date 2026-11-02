extends SceneTree
# Runtime contracts for staged deaths, class gating, flash limits and the hurry key.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _ship(world: Node3D, fx, cls: String, size: float, flagship := false):
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
	fx.add_ship("T", r, {"faction": "voidsworn", "cls": cls, "size": size, "flagship": flagship, "meshes": [mi]})
	return fx.ship("T")

func _advance(fx, seconds: float) -> void:
	var end: float = fx.now + seconds
	while fx.now < end:
		fx.step(1.0 / 60.0)
		await process_frame

func _run() -> void:
	for spec in [["Frigate", 1.5, false, false], ["Destroyer", 1.5, false, false],
		["Cruiser", 0.4, false, true], ["Destroyer", 0.4, true, true], ["Squadron", 0.1, false, false]]:
		for calm in [false, true]:
			var world := Node3D.new()
			root.add_child(world)
			var fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"quality": "high", "reduce_flashing": calm, "shake": 0.0})
			var s = _ship(world, fx, spec[0], spec[1], spec[2])
			_check(s.death_big == spec[3], "slow motion uses class/flagship, independent of size")
			DEATH.precompute(fx, s)
			await _advance(fx, 0.7)
			var root_pose: Transform3D = s.root.transform
			var mesh_pose: Transform3D = s.meshes[0].transform
			var duration: float = fx.death("T", "big")
			var before: int = fx.flash_log.size()
			_check(duration >= 1.0 and duration < 2.1, "bounded staged death duration")
			await _advance(fx, 0.36)
			_check(s.meshes[0].visible, "hull remains through power-down/death spin")
			_check(s._eng_cur < 0.02, "engines extinguish before split")
			for m in s.get_meta("death_power", []):
				_check(float(m.get_shader_parameter("fx_power")) < 0.01, "running-light emission extinguishes")
			_check(fx.flash_log.size() == before, "no cook-off flashes before the split")
			if not s.death_big:
				_check(s.meshes[0].transform != mesh_pose, "small hull spins before break")
				_check(s.root.transform == root_pose, "death spin does not move the rules/view root")
				_check(fx._pauses.is_empty() and fx._death_slow_left == 0.0, "small kills have no hit pause/slow motion")
			await _advance(fx, (1.45 if s.death_big else 0.55))
			_check(fx.flash_log.size() - before == (0 if calm else 1), "one core flash before any secondary explosions")
			await _advance(fx, 3.6)
			_check(not s.meshes[0].visible, "live hull replaced after split")
			_check(fx.dstate["wrecks"].size() == 1, "one lingering wreck record per kill")
			var w: Dictionary = fx.dstate["wrecks"][0]
			if s.death_big: _check(w["nodes"].size() == 2, "capital splits into two halves")
			var flashes: int = fx.flash_log.size() - before
			_check(flashes == 0 if calm else flashes >= 1, "calm has zero flashes; normal keeps its core")
			for a in fx.flash_log:
				var in_second := 0
				for b in fx.flash_log:
					if b >= a and b < a + 1.0: in_second += 1
				_check(in_second <= 3, "secondary explosions respect the rolling flash limit")
			if s.weight > 0:
				_check(not w["nodes"].is_empty(), "small ship retains a tumbling hull chunk")
				for m in w["mats"]:
					_check(float(m.get_shader_parameter("heat")) < 0.7, "wreck ember cools")
				for f in w["fires"]:
					if f.has("cool"):
						_check(float(f["mat"].get_shader_parameter("gate")) > 0.5, "slow coals survive the initial flames")
			print("DESTRUCTION_STAGE class=%s size=%.1f flagship=%s calm=%s duration=%.2f pieces=%d flashes=%d" % [spec[0], spec[1], spec[2], calm, duration, w["nodes"].size(), flashes])
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
		fx.setup({"quality": quality, "shake": 0.0})
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
		fx.setup({"quality": "low"})
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
