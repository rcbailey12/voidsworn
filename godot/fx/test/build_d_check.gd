extends SceneTree

const FX := preload("res://fx/fx.gd")
const SPECIAL := preload("res://fx/fx_special.gd")
const SH := preload("res://fx/fx_shaders.gd")

var fx: FX
var bad := 0
var transfers := 0


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		bad += 1
		printerr("FAIL Build D: " + message)


func _fixture(id: String, faction: String, at: Vector3, wing := false) -> Node3D:
	var view := Node3D.new()
	view.position = at
	var pivot := Node3D.new()
	pivot.name = "hull_pivot"
	view.add_child(pivot)
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14.0, 2.8, 6.0)
	part.mesh = box
	pivot.add_child(part)
	for point in [["hp_core", Vector3.ZERO], ["hp_bay_0", Vector3(2.0, 1.4, -1.7)], ["hp_eng_0", Vector3(-7.0, 0.0, 0.0)]]:
		var hp := Node3D.new()
		hp.name = point[0]
		hp.position = point[1]
		pivot.add_child(hp)
	root.add_child(view)
	fx.add_ship(id, view, {"faction": faction, "cls": "Squadron" if wing else "Cruiser", "shielded": false})
	return view


func _step_to(at: float) -> void:
	while fx.now < at - 0.00001:
		fx.step(minf(at - fx.now, 1.0 / 60.0))


func _count(key: String) -> int:
	return fx.pools[key].emitted if fx.pools.has(key) else 0


func _nova() -> void:
	var source := _fixture("nova", "voidsworn", Vector3(-34.0, 0.0, 0.0))
	var target := Vector3(34.0, 2.0, 0.0)
	var signatures: Array = []
	_check(fx.nova_look.is_empty(), "neither bench option is selected by default")
	for style in ["", "ember_hammer", "crown_lance"]:
		fx.nova_look = style
		fx.spr_kinds = {}
		var t: float = fx.now
		var rings := _count("rng")
		var sticks := _count("stk")
		var smoke := _count("smk")
		var lenses := _count("dst")
		var at := fx.nova("nova", target, 0.60)
		_check(is_equal_approx(at, t + (SPECIAL.NOVA_CHARGE + SPECIAL.NOVA_FLIGHT) * 0.60), style + " shares battle timing")
		var warm = fx.spr_kinds.duplicate()
		_step_to(at - 0.012)
		_check(not fx.spr_kinds.has(26), style + " fire tail does not start before impact")
		_step_to(at + 0.015)
		if style.is_empty():
			_check(warm.has(SH.SPR_NOVA_LEGACY) and not warm.has(12) and not fx.spr_kinds.has(26), "legacy Nova remains the live look")
			_check(SH.SPR_NOVA_LEGACY != SH.VENT_JET and SH.SPR_NOVA_LEGACY != SH.TICK_DROPLET and SH.SPR_NOVA_LEGACY != SH.TICK_EMBER and SH.SPR_NOVA_LEGACY != SH.ROCKET_SMOKE, "legacy Nova sprite kind is its own, not the hull vent jet (Artoo, PR 2222)")
		else:
			_check(warm.has(12) and warm.has(14 if style == "ember_hammer" else 17), style + " has charge and its own shell")
			_check(_count("stk") > sticks and _count("smk") > smoke and _count("rng") > rings + 3 and fx.spr_kinds.has(26),
				style + " has shell trail, shock fronts and late fire and smoke")
			_check(fx.get_children().any(func(n: Node) -> bool:
				return n.get_meta("pic_key", "") == "fb|cruiser|flash|nova" and (n as Node3D).visible),
				style + " has a live baked hot core in its own pool")
			if fx.pools.has("dst"):
				_check(_count("dst") > lenses + 1, style + " lenses both the shell and the impact")
			signatures.append([_count("rng") - rings, warm])
		_check(source.position == Vector3(-34.0, 0.0, 0.0), "Nova recoil never moves the board root")
		_step_to(at + 1.7)
	_check(signatures.size() == 2 and signatures[0] != signatures[1], "Nova options differ in more than title")
	_check(fx.flash_log.is_empty(), "reduced flashing books no Nova flash")


func _warp() -> void:
	var old := Vector3(20.0, 0.0, 0.0)
	var next := Vector3(35.0, 0.0, 10.0)
	var view := _fixture("warp", "ithar", old)
	var hull := view.get_node("hull_pivot") as Node3D
	var t: float = fx.now
	var at := fx.rift_in("warp", 1.0, 0.10)
	_check(not hull.visible and view.position == old, "reinforcement hides its hull before the first draw")
	_step_to(t + 0.42)
	_check(not hull.visible, "rift opens before the reinforcement enters")
	_step_to(t + 0.58)
	_check(hull.visible and hull.scale.z < 0.95 and hull.position.x < 0.0, "arriving hull slides and resolves")
	_step_to(at + 0.001)
	_check(hull.visible and hull.scale.is_equal_approx(Vector3.ONE) and hull.position.is_zero_approx(), "arrival restores pose")

	t = fx.now
	at = fx.fold("warp", 1.0, func blink_position() -> void:
		transfers += 1
		view.position = next)
	var ghost := fx.get_node_or_null("fx_warp_echo") as Node3D
	_check(ghost != null and ghost.get_child_count() == 1, "Blink snapshots the hull, not a sprite dot")
	_check(view.position == old, "Blink does not pre-snap on the ability cue")
	_step_to(t + 0.26)
	_check(view.position == next and transfers == 1 and hull.scale.z < 0.95, "Blink snaps exactly once between rifts")
	_step_to(at + 0.001)
	_check(hull.scale.is_equal_approx(Vector3.ONE) and ghost.is_queued_for_deletion(), "Blink restores pose and frees the echo")

	var risen := _fixture("risen", "deathless", old)
	var rp := risen.get_node("hull_pivot") as Node3D
	at = fx.rift_in("risen", 1.0, 0.0, true)
	_check(not rp.visible, "Risen shares the arrival kit")
	_step_to(at + 0.001)
	_check(rp.visible, "Risen restores the rebuilt hull")
	fx.reduce_motion = true
	t = fx.now
	at = fx.fold("risen")
	_step_to(t + 0.12)
	_check(rp.scale == Vector3.ONE and risen.position == old, "Reduced Motion Phase does not stretch or move the hull")
	_step_to(at + 0.001)
	_check(rp.visible and risen.position == old, "Phase returns to the same hex")
	fx.reduce_motion = false
	var gone := fx.jump_out("warp")
	_step_to(gone - 0.08)
	_check(hull.visible and hull.scale.z < 0.95 and view.position == next, "warp-out spools then stretches without moving the hex")
	_step_to(gone + 0.001)
	_check(not (hull.get_child(0) as MeshInstance3D).visible and fx.ship("warp").gone, "warp-out hides the hull only when the wake is left behind")

	var cancelled := _fixture("cancelled", "voidsworn", old)
	at = fx.fold("cancelled", 1.0, func unexpected() -> void: transfers += 100)
	fx.remove_ship("cancelled")
	_step_to(at + 0.001)
	_check(transfers == 1 and (cancelled.get_node("hull_pivot") as Node3D).visible, "removing a folding ship cancels its snap and resets the pose")


func _pulses_and_bay() -> void:
	var seen := {}
	for f in FX.FLOOK.table():
		var id := "pulse_" + str(f)
		_fixture(id, f, Vector3.ZERO)
		var row: Dictionary = FX.FLOOK.of(f)
		var shape: int = SPECIAL.RIFT_SHAPES.get(row.get("rift_shape"), -1)
		_check(shape >= 0 and shape not in [SH.RING_DEATH_FRONT, SH.RING_HARMONIC] and not seen.has(shape), str(f) + " has its own named shape")
		seen[shape] = true
		var ring := _count("rng")
		fx.ability(id)
		var written: PackedFloat32Array = fx.pools["rng"].pending
		var start: int = written.size() - 2 * int(fx.pools["rng"].vpp) * 20
		var c: Color = row["weapon"]
		_check(start >= 0 and int(written[start + 18]) == shape and Vector3(written[start + 12], written[start + 13], written[start + 14]).is_equal_approx(Vector3(c.r, c.g, c.b)),
			str(f) + " pulse sends its actual profile to the ring pool")
		_check(_count("rng") == ring + 2, str(f) + " ability has two directional wave layers")
		fx.command(id)
		_check(_count("rng") == ring + 5, str(f) + " command adds a third wave")
		fx.step(0.02)

	_fixture("bay", "chorus", Vector3.ZERO)
	_fixture("wing", "chorus", Vector3(10.0, 3.0, -8.0), true)
	var ring := _count("rng")
	var rail := _count("stk")
	var lens := _count("rib")
	var mist := _count("smk")
	fx.spr_kinds = {}
	fx.launch("bay", "wing")
	_check(_count("rng") == ring + 1 and _count("stk") == rail + 2 and _count("rib") == lens + 1,
		"bay has mouth, paired rails and a directional wash")
	_check(_count("smk") == mist + 2 and int(fx.spr_kinds.get(20, 0)) == 2 and int(fx.spr_kinds.get(18, 0)) >= 6,
		"Chorus bay uses organic vapor and six ignition beats")
	var packed: PackedFloat32Array = fx.pools["rng"].pending
	_check(Vector3(packed[4], packed[5], packed[6]).is_equal_approx(Vector3(2.0, 1.4, -1.7)), "bay starts on its authored mouth")
	_step_to(fx.now + 2.0)


func _run() -> void:
	fx = FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "reduce_flashing": true})
	_nova()
	_warp()
	_pulses_and_bay()
	print("Build D: ", "PASS" if bad == 0 else "%d failure(s)" % bad)
	quit(0 if bad == 0 else 1)
