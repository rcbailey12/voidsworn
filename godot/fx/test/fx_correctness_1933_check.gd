extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SH := preload("res://fx/fx_shaders.gd")
const WEAP := preload("res://fx/fx_weapons.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "fx_correctness_1933_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _add_hull(fx: FX, id: String, z: float) -> MeshInstance3D:
	var ship := Node3D.new()
	fx.add_child(ship)
	ship.position.z = z
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24.0, 4.0, 6.0)
	box.material = StandardMaterial3D.new()
	mi.mesh = box
	ship.add_child(mi)
	fx.add_ship(id, ship, {"faction": "voidsworn", "cls": "Cruiser", "meshes": [mi]})
	return mi


func _prepare_and_check_hulls(fx: FX) -> void:
	fx.defer_initial_cuts = true
	var dipped := _add_hull(fx, "rammer", 0.0)
	var worn := _add_hull(fx, "target", 14.0)
	await fx.prepare_battle_hulls()
	fx.manual = true
	_check(dipped.get_surface_override_material(0) == null and worn.get_surface_override_material(0) == null,
		"battle preparation warms the materials with no damage overrides")

	fx.ship("rammer").hit_power(fx, false, 0.4)
	fx.step(0.01)
	var dip_mat := dipped.get_surface_override_material(0) as ShaderMaterial
	_check(dip_mat != null and float(dip_mat.get_shader_parameter("fx_flick")) < 1.0,
		"a first brownout reaches the material on a battle-prepared hull")

	var healthy := {"hp": 100, "max": 100}
	fx.sync_ship("target", {"hp": 75, "maxHp": 100, "sec": {"eng": healthy, "mid": healthy, "prow": healthy}})
	var wear_mat := worn.get_surface_override_material(0) as ShaderMaterial
	_check(wear_mat != null and float(wear_mat.get_shader_parameter("fx_weather")) > 0.0,
		"early wear reaches the material before any section damage on a battle-prepared hull")


func _check_ram(fx: FX) -> void:
	var result := fx.volley("rammer", "torp", "target", {"weapon_id": "ram",
		"hits": [{"shield": 9, "hull": 0, "section": "mid", "crit": false}]})
	var impacts: Array = result["impacts"]
	var points: Array = result.get("hit_pts", [])
	_check(impacts.size() == 1 and points.size() == 1 and points[0] != Vector3.INF,
		"a shield-blocked ram with default shots has one shield impact (got %d)" % impacts.size())
	fx.step(float(result["done"]) + 0.05)
	_check(fx.ship("rammer")._mark_n == 1 and fx.ship("target")._mark_n == 0,
		"a shield-blocked ram crumples the rammer once and leaves no phantom mark on the target")


func _check_clock(fx: FX) -> void:
	var order: Array[int] = []
	for i in 24:
		fx.later(fx.now + 0.01, func() -> void: order.append(i))
	fx.step(0.1)
	_check(order == range(24), "equal-time callbacks run in insertion order")
	# issue 2172: the queue stays ordered as it is filled and only the due front leaves each step
	var order2: Array[int] = []
	fx.later(fx.now + 0.03, func() -> void: order2.append(3))
	fx.later(fx.now + 0.01, func() -> void: order2.append(1))
	fx.later(fx.now + 0.02, func() -> void: order2.append(2))
	var ordered := true
	for i in range(1, fx._later.size()):
		if float(fx._later[i][0]) < float(fx._later[i - 1][0]):
			ordered = false
	_check(ordered, "the deferred queue is kept in time order as callbacks are added")
	fx.step(0.05)
	_check(order2 == [1, 2, 3] and fx._later.is_empty(), "out of order callbacks run by time and leave the queue")

	seed(1933)
	var expected_random := randf()
	seed(1933)
	fx.board("rammer", "target")
	_check(randf() == expected_random, "boarding leaves the global random stream alone")
	var lines := fx._board_lines_live
	_check(lines.size() == 3, "boarding creates all three lines")
	if lines.is_empty():
		return
	var line: MeshInstance3D = lines[0]["node"]
	var mat := line.material_override as ShaderMaterial
	await process_frame
	_check(float(mat.get_shader_parameter("gain")) == 0.0, "boarding lines wait for the manual effect clock")
	var start: float = fx.now
	fx.step(0.1)
	_check(is_equal_approx(float(mat.get_shader_parameter("gain")), (fx.now - start) / 0.2),
		"boarding line gain follows the effect clock")
	fx.step(fx.board_lines_s)
	_check(lines.is_empty() and line.is_queued_for_deletion(), "boarding lines expire at the effect-clock hold")


func _check_code(label: String, code: String, fragments: Array[String]) -> void:
	var missing := fragments.filter(func(fragment: String) -> bool: return not code.contains(fragment))
	_check(missing.is_empty(), "%s contains its patched text%s" % [label, "" if missing.is_empty() else ": " + str(missing)])


func _check_shaders(fx: FX) -> void:
	_check_code("weapon flipbook", WEAP._weapon_shader(fx).code, [
		"uniform float looping =", "vec2(sin(spin), cos(spin))", "up * local.y * aspect", "hot > 0.5 ? age * 15.0",
		"mix(weapon_tint, vec3", "if (vent > 0.5 && vent_cone > 0.5)", "soft * opacity * mix(1.0, 0.55, fx_calm)",
		"PROJECTION_MATRIX)) * 1.45", "looping > 0.5 ? 0.15 + 0.55", "pow(clamp(UV.y, 0.0, 1.0), 0.7), looping)",
		"elapsed < lifetime || looping > 0.5"])
	_check_code("hull impact", WEAP.hull_impact_material(fx, "weapons/impact/impact_").shader.code, [
		"uniform float impact_body =", "frame = mix(flash_frame, body_frame, impact_body)", "max(extent * 0.015, 0.035)",
		"ALBEDO = mix(ALBEDO, coloured, impact_tinted)", "smoothstep(0.035, 0.18, thick.b)"])
	var source := StandardMaterial3D.new()
	var plain := HULL.damage_material(source, Transform3D.IDENTITY, {}, 24.0)
	var strained := plain.duplicate() as ShaderMaterial
	for mat in [DEATH.power_material(plain), DEATH.power_material(strained, true)]:
		_check_code("death power-down", mat.shader.code, ["uniform float death_age =", "+ death_steps.z, death_age), clamp(fx_power, 0.0, 1.0), death_hold)"])
	_check_code("strained power-down", strained.shader.code, ["VERTEX += inverse(mat3(fx_hull_frame)) * fx_strain_offset("])
	_check_code("strained tear", SH.tear_strain_code(), [
		"uniform vec3 fx_hair =", "fx_jag_offset(cut_p, axis)", "vec3 so = fx_strain_offset(cut_p, sn, scene_t)",
		"col += ember * fx_hair.z * line * dash * flick * amt"])
	_check_code("transparent exterior", HULL.exterior_alpha_code(), ["ALPHA = hull_albedo.a * texture(hull_color, UV).a;"])


func _run() -> void:
	var fx := FX.new()
	root.add_child(fx)
	fx.setup({"quality": "low"})
	await _prepare_and_check_hulls(fx)
	_check_ram(fx)
	_check_shaders(fx)
	await _check_clock(fx)
	fx.release()
	fx.queue_free()
	await process_frame
	print("FX_CORRECTNESS_1933 %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
