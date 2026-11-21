extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1466 (Astra pass 2 on 20f34d01, findings 3, 1 and 2): wreck debris physics. Box stand-ins, no ship files:
#   1. settled plates: with every plate at rest the physics space sleeps (issue 1279's gate); a hull collider moving
#      through the plates wakes it and shoves a plate aside (Astra's probe: 0 units with the gate, 4 with the space
#      awake); a hull moving far from every plate, and a lone hull on an empty board, leave the space asleep;
#   2. a shrinking wreck: once its pieces start to draw together (issue 1236), a released section leaves Jolt for the
#      scripted drift, so no full-size collider sits round shrunk metal; a section released after the shrink began
#      goes straight onto the drift; a wreck that fits its hex without shrinking keeps its section in Jolt;
#   3. the kill slow motion: plates thrown during it launch at the effect clock's speed, and plates in flight slow and
#      speed back up with the clock by the same ratio as a released wreck section.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "wreck_contact_check", 120.0)
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)
	print(("  ok   " if ok else "  FAIL ") + why)


func _fx(world: Node3D):
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": null, "shake": 0.0})
	return fx


func _hull(world: Node3D, at: Vector3) -> AnimatableBody3D:
	# as DEATH.add_collider makes it (layer, mask, group), with a box for the convex hull
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = DEATH.HULL_LAYER
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 2, 3)
	cs.shape = box
	body.add_child(cs)
	body.add_to_group(DEATH.HULL_GROUP)
	world.add_child(body)
	body.global_position = at
	return body


func _frames(fx, n: int, mover: Node3D = null, step := Vector3.ZERO) -> void:
	for i in n:
		fx.step(1.0 / 60.0)
		if mover != null: mover.global_position += step
		await physics_frame


func _all_asleep(fx) -> bool:
	for b in fx.dstate["debris"]:
		if not (b as RigidBody3D).sleeping: return false
	return true


func _settled_plates(fx, world: Node3D) -> void:
	DEATH.spawn_debris(fx, Vector3(0, 0, 0), Vector3.ZERO, 6, 0.5)
	var end := Time.get_ticks_msec() + int((DEATH.DEBRIS_REST_S + 1.5) * 1000.0)
	while Time.get_ticks_msec() < end:
		await _frames(fx, 1)


# 1. a moving hull wakes the space near settled plates
func _contact(world: Node3D) -> void:
	var fx = _fx(world)
	var lone := _hull(world, Vector3(400, 0, 400))
	await _frames(fx, 40, lone, Vector3(0.1, 0, 0))
	check(not fx._phys_awake, "a lone moving hull on an empty board leaves the space asleep")
	lone.queue_free()
	await _settled_plates(fx, world)
	check(_all_asleep(fx), "every plate has come to rest")
	check(not fx._phys_awake, "the space sleeps once every plate is at rest")
	# a hull moving well clear of the plates
	var far := _hull(world, Vector3(-60, 0, 60))
	await _frames(fx, 40, far, Vector3(0.1, 0, 0))
	check(not fx._phys_awake, "a hull moving 60 units from the plates leaves the space asleep")
	far.queue_free()
	# a hull driven straight through the nearest plate, at a ship's travel pace (12 units a second)
	var plate: RigidBody3D = fx.dstate["debris"][0]
	for b in fx.dstate["debris"]:
		if (b as RigidBody3D).global_position.length() < plate.global_position.length(): plate = b
	var p0 := plate.global_position
	var hull := _hull(world, p0 + Vector3(-12, 0, 0))
	var woke := false
	for i in 150:
		await _frames(fx, 1, hull, Vector3(0.2, 0, 0))
		woke = woke or bool(fx._phys_awake)
	var moved := plate.global_position.distance_to(p0)
	print("WRECK_CONTACT plate moved %.2f units as the hull crossed it" % moved)
	check(woke, "a hull moving through settled plates wakes the physics space")
	check(moved > 1.0, "the crossing hull shoves the settled plate aside (%.2f units)" % moved)
	# the hull parks; the knocked plates settle and the space sleeps again
	var end := Time.get_ticks_msec() + int((DEATH.DEBRIS_REST_S + 1.5) * 1000.0)
	while Time.get_ticks_msec() < end:
		await _frames(fx, 1)
	check(not fx._phys_awake, "with the hull parked and the plates at rest again the space sleeps")
	hull.queue_free()
	fx.queue_free()
	await process_frame


func _section(fx, at: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.gravity_scale = 0.0
	rb.axis_lock_linear_y = true
	rb.collision_layer = DEATH.DEBRIS_LAYER
	rb.collision_mask = DEATH.HULL_LAYER
	rb.freeze = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6, 2, 3)
	cs.shape = box
	rb.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "mesh"
	var bm := BoxMesh.new()
	bm.size = Vector3(6, 2, 3)
	mi.mesh = bm
	rb.add_child(mi)
	fx.phys_root.add_child(rb)
	rb.global_position = at
	return rb


func _in_jolt(rb: RigidBody3D) -> bool:
	return not rb.freeze and rb.process_mode != Node.PROCESS_MODE_DISABLED


# 2. a shrinking wreck's released sections leave Jolt as the meshes shrink
func _shrink(world: Node3D) -> void:
	var fx = _fx(world)
	var c := Vector3(50, 0, 50)
	DEATH.anchor_wreck(fx, "w1", c, 8.0)
	DEATH.anchor_wreck(fx, "w2", c + Vector3(100, 0, 0), 8.0)
	var a := _section(fx, c + Vector3(-2, 0, 0))
	var b := _section(fx, c + Vector3(2, 0, 0))
	var wk := {"id": "w1", "t0": fx.now, "nodes": [a, b], "mats": [], "lights": [], "fires": [], "speed": 1.0, "frags": [], "heat_births": {}, "cut_events": []}
	var fit := _section(fx, c + Vector3(100, 0, 0))
	var wfit := {"id": "w2", "t0": fx.now, "nodes": [fit], "mats": [], "lights": [], "fires": [], "speed": 1.0, "frags": [], "heat_births": {}, "cut_events": []}
	fx.dstate["wrecks"].append(wk)
	fx.dstate["wrecks"].append(wfit)
	DEATH._release_section(fx, wk, a, Vector3(1, 0, 0), Vector3.ZERO, [], 6.0, true, 0)
	DEATH._release_section(fx, wfit, fit, Vector3(1, 0, 0), Vector3.ZERO, [], 6.0, true, 0)
	check(_in_jolt(a), "a section released before the shrink is in Jolt")
	wk["leash_target"] = 0.5   # as _leash measures it for a hull longer than its hex
	wfit["leash_target"] = 1.0  # fits its hex: never shrinks
	var mi := a.get_node("mesh") as MeshInstance3D
	var end_t: float = fx.now + DEATH.LEASH_SHRINK_FROM + 0.4
	while fx.now < end_t:
		await _frames(fx, 1)
	var k := mi.transform.basis.get_scale().x
	print("WRECK_CONTACT shrink: mesh scale %.2f, in Jolt %s, drift entries %d" % [k, _in_jolt(a), wk["fires"].size()])
	check(k < 0.99, "the wreck has started to shrink (mesh scale %.2f)" % k)
	check(not _in_jolt(a), "a released section leaves Jolt as its mesh shrinks (no full-size collider round it)")
	var drifting := false
	for f in wk["fires"]:
		drifting = drifting or (f.get("node") == a and (f["vel"] as Vector3).length() > 0.0)
	check(drifting, "it drifts on the scripted path with its speed kept")
	DEATH._release_section(fx, wk, b, Vector3(-1, 0, 0), Vector3.ZERO, [], 6.0, true, 1)
	check(not _in_jolt(b), "a section released after the shrink began goes straight onto the scripted drift")
	check(_in_jolt(fit), "a section of a wreck that fits its hex stays in Jolt until WRECK_PHYS_S")
	fx.queue_free()
	await process_frame


# the mean speed of plates from..to in the pool (one throw each)
func _mean_speed(fx, from: int, to: int) -> float:
	var s := 0.0
	for i in range(from, to):
		s += (fx.dstate["debris"][i] as RigidBody3D).linear_velocity.length()
	return s / maxf(to - from, 1)


# 3. plates keep pace with the kill slow motion
func _slowmo(world: Node3D) -> void:
	var fx = _fx(world)
	# launch: the same throw at full speed and in the slow beat
	fx.rng.seed = 7
	DEATH.spawn_debris(fx, Vector3(0, 0, -200), Vector3.ZERO, 8, 0.5)
	var full := _mean_speed(fx, 0, 8)
	fx.kill_slowmo = true
	fx.death_slowmo()
	for i in 6: fx.step(1.0 / 60.0)
	var spd: float = fx.anim_speed()
	fx.rng.seed = 7
	DEATH.spawn_debris(fx, Vector3(0, 0, -200), Vector3.ZERO, 8, 0.5)
	var slow := _mean_speed(fx, 8, 16)
	print("WRECK_CONTACT launch: full %.2f, slow %.2f at clock %.2f" % [full, slow, spd])
	check(spd < 0.5, "the kill slow motion has slowed the effect clock (%.2f)" % spd)
	check(absf(slow / full - spd) < 0.02, "a plate thrown in the slow beat launches at the clock's speed (%.2f of full)" % (slow / full))
	# in flight: the clock eases back up and the plates speed up by the same ratio as a released section
	var sec := _section(fx, Vector3(0, 0, -300))
	var wk := {"id": "s1", "t0": fx.now, "nodes": [sec], "mats": [], "lights": [], "fires": [], "speed": fx.anim_speed(), "frags": [], "heat_births": {}, "cut_events": []}
	fx.dstate["wrecks"].append(wk)
	DEATH._release_section(fx, wk, sec, Vector3(4, 0, 0), Vector3.ZERO, [], 6.0, true, 0)
	var p0 := _mean_speed(fx, 8, 16)
	var s0 := sec.linear_velocity.length()
	var c0: float = fx.anim_speed()
	var end := Time.get_ticks_msec() + 900
	while Time.get_ticks_msec() < end:
		fx.step(1.0 / 60.0)
		await physics_frame
	var c1: float = fx.anim_speed()
	var pr := _mean_speed(fx, 8, 16) / maxf(p0, 1e-6)
	var sr := sec.linear_velocity.length() / maxf(s0, 1e-6)
	print("WRECK_CONTACT in flight: clock %.2f to %.2f, plates x%.2f, section x%.2f" % [c0, c1, pr, sr])
	check(c1 > c0 + 0.3, "the clock eased back after the beat")
	check(absf(pr - sr) < 0.05 and absf(pr - c1 / c0) < 0.05, "plates in flight follow the clock as the section does")
	fx.queue_free()
	await process_frame


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	await _contact(world)
	await _shrink(world)
	await _slowmo(world)
	world.queue_free()
	await process_frame
	print("WRECK_CONTACT %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)
