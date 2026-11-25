extends SceneTree
# Issue 2198: exercise the same effect clock for wrecks, dying hulls and deferred effects.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SHIP := preload("res://fx/fx_ship.gd")
var failures := 0


func _initialize() -> void:
	GUARD.arm(self, "death_retirement_check")
	_run.call_deferred()


func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		push_error(detail)


func _run() -> void:
	var fx := FX.new()
	fx.manual = true
	root.add_child(fx)
	fx.setup({"quality": "high"})
	fx.compat = false  # Build live fire and smoke on the headless renderer too.
	_check_queue(fx)
	_check_hulk_and_tell(fx)
	fx.queue_free()
	await process_frame
	quit(1 if failures > 0 else 0)


func _check_queue(fx: FX) -> void:
	var before := failures
	var ran: Array = []
	for i in range(511, -1, -1):
		fx.later(10.0 + float(i % 8), func() -> void: ran.append(i))
	var backing := fx._later
	var parked := backing.duplicate()
	fx.now = 1.0
	fx._run_later()
	_check(ran.is_empty() and is_same(backing, fx._later) and fx._later == parked, "AR1: a future-only frame must leave the heap alone")
	fx.later(3.0, func() -> void: ran.append("third"))
	fx.later(2.0, func() -> void:
		ran.append("first")
		fx.later(2.0, func() -> void: ran.append("immediate"))
		fx.later(2.5, func() -> void: ran.append("new")))
	fx.later(2.0, func() -> void: ran.append("second"))
	fx.now = 2.0
	fx._run_later()
	_check(ran == ["first", "immediate", "second"] and fx._later.size() == 514, "AR1: due ties stay in insertion order and later children wait")
	fx.now = 3.0
	fx._run_later()
	_check(ran == ["first", "immediate", "second", "new", "third"] and fx._later.size() == 512, "AR1: only the next two events are now due")
	fx.now = 17.0
	fx._run_later()
	var expected: Array = ["first", "immediate", "second", "new", "third"]
	for bucket in 8:
		for i in range(504 + bucket, -1, -8): expected.append(i)
	_check(ran == expected and fx._later.is_empty(), "AR1: the remaining heap drains in time order, then insertion order")
	print("%s AR1 deferred queue" % ("PASS" if before == failures else "FAIL"))


func _check_hulk_and_tell(fx: FX) -> void:
	var before := failures
	var hull := Node3D.new()
	fx.add_child(hull)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 4, 5)
	box.subdivide_width = 8
	mi.mesh = box
	mi.material_override = StandardMaterial3D.new()
	hull.add_child(mi)
	fx.add_ship("burning", hull, {"cls": "Cruiser", "size": 0.8, "shielded": false, "cut_on_arrival": false})
	var ship: SHIP = fx.ship("burning")
	ship.stage[1] = 3
	ship._refresh_damage_emitters(fx)
	var attached: Array = ship._damage_emitters.map(func(e): return e.node)
	_check(attached.size() >= 2, "W1: fixture needs real fire and smoke nodes")
	var fading := Node3D.new()
	ship._dmg_root.add_child(fading)
	ship._fading_emitters.append({"node": fading, "mat": ShaderMaterial.new(), "until": fx.now + 1.0})
	for i in 5:
		hull.position.x += 1.0
		fx.step(0.06)
	var trail: MeshInstance3D = ship._trails[0].mi
	_check(trail.visible, "F3: fixture needs existing world-space exhaust")
	fx.death("burning", "dark")
	fx.step(0.01)
	_check(ship._eng_gate_written > 1.0 and not ship.death_fx_done, "F3: the death tell still holds the engine flare")
	fx.step(0.50)
	_check(not ship.has_meta("death_hidden") and mi.visible and fading.visible and attached.all(func(n): return n.is_visible_in_tree()),
		"W1: attached fire and smoke stay visible after the kill, through the tell")
	fx.step(0.25)
	_check(ship.has_meta("death_hidden") and ship._damage_emitters.is_empty() and ship._fading_emitters.is_empty(),
		"F3/W1: break hides and retires both emitter lists")
	_check(attached.all(func(n): return not n.visible and n.is_queued_for_deletion()) and not fading.visible,
		"W1: emitter nodes are removed at the break, not the kill")
	_check(ship._eng_gate_written == 0.0 and trail.visible and not ship.death_fx_done,
		"F3: hidden hull has zero drive, but the existing trail is still draining")
	fx.step(3.0)
	_check(ship.death_fx_done and not trail.visible, "F3: the hidden death stops updating once its tail expires")
	var last := ship._last_pos as Vector3
	hull.position.x += 5.0
	fx.step(0.1)
	_check(ship._last_pos == last, "F3: retired ship no longer runs the live position update")
	print("%s F3/W1 death tell and ship FX" % ("PASS" if before == failures else "FAIL"))

	before = failures
	var wreck: Dictionary = fx.dstate.wrecks[0]
	var hulk: Node3D = wreck.nodes[0]
	var smoke := hulk.get_node_or_null("fx_hulk_vent") as MeshInstance3D
	_check(smoke != null and hulk.has_meta("leash_offset"), "F1: hulk has an attached smoke batch and build-time leash geometry")
	var fire: Array = wreck.fires
	var expired := Node3D.new()
	hulk.add_child(expired)
	fire.append({"node": expired, "vel": Vector3.ONE, "ang": Vector3.ONE, "until": fx.now})
	fx.step(0.1)
	_check(not wreck.settled and fire.size() == 1 and expired.position == Vector3.ZERO,
		"F1: prune expired motion immediately, without settling a young wreck")
	var body := RigidBody3D.new()
	body.gravity_scale = 0.0
	fx.phys_root.add_child(body)
	wreck.nodes.append(body)
	for i in 160: fx.step(0.1)
	_check(fire.is_empty() and not wreck.settled, "F1: hulk drift brakes to rest, but an awake body keeps the wreck active")
	body.freeze = true
	fx.step(0.1)
	_check(wreck.settled, "F1: old and cold wreck settles once motion expires and every body is at rest")

	DEATH.anchor_wreck(fx, "burning", hulk.global_position, 1.0)
	var canary := Node3D.new()
	fx.phys_root.add_child(canary)
	canary.global_position = hulk.global_position + Vector3(5, 0, 0)
	var at := canary.global_position
	wreck["frags"] = [canary]
	fire.append({"node": canary, "vel": Vector3.ONE, "ang": Vector3.ONE})
	var light := {"base": 0.321}
	wreck.lights.append(light)
	var plate := RigidBody3D.new()
	plate.freeze = true
	plate.set_meta("debris_piece", {"leash": "burning"})
	fx.phys_root.add_child(plate)
	fx.dstate["debris_awake"] = {plate: fx.now}
	fx.step(0.1)
	_check(canary.global_position == at and not canary.has_meta("leash_born") and is_equal_approx(light.base, 0.321),
		"F1: settled wreck skips motion, leash marking, clamping and light writes")
	_check(not plate.has_meta("leash_born") and is_instance_valid(smoke) and smoke.visible,
		"F1: frozen debris is skipped and the shader-clocked smoke child is not shut off")
	fx.dstate["physics_on"] = true
	DEATH.spawn_debris(fx, hulk.global_position, Vector3.ZERO, 1, 0.2)
	var thrown: RigidBody3D = fx.dstate.debris.back()
	var awake: Dictionary = fx.dstate.debris_awake
	awake.erase(thrown)
	thrown.sleeping = true
	thrown.sleeping_state_changed.emit()
	_check(not awake.has(thrown), "F1: the sleep signal does not put resting debris back on the active list")
	thrown.sleeping = false
	thrown.sleeping_state_changed.emit()
	_check(awake.has(thrown), "F1: the wake signal puts knocked debris back on the list without a pool scan")
	wreck.lights.clear()  # The probe light isn't registered with the FX light pool.
	print("%s F1 wreck retirement" % ("PASS" if before == failures else "FAIL"))
