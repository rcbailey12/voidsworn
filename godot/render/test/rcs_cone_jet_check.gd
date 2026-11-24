extends SceneTree
# Issue 2042 item 1: directional RCS cone-jet kit check (headless).
# Verifies that ShipView's RCS puffs use the shared SH.RCS_JET directional cone-jet shader
# (hot core, soft wash, quick fade, fog_disabled), faction tinted from fx/faction_looks.json,
# keeping Glasswright non-mechanical (prismatic vane flare, no white cold gas), Chorus organic
# (no metal sparks), Eclipse strictly violet (no green, no orange), and anchored to the moving hull.

const GUARD := preload("res://tools/ci/check_guard.gd")
const SV := preload("res://render/ship_view.gd")
const SH := preload("res://fx/fx_shaders.gd")
const TP := preload("res://fx/thrust_profile.gd")
const FLOOK := preload("res://fx/faction_look.gd")

var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "rcs_cone_jet_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)


func _run() -> void:
	# 1. Shared shader contract
	_check(SH.RCS_JET.contains("fog_disabled") and SH.RCS_JET.contains("blend_add"),
		"SH.RCS_JET ignores fog and uses additive blending")
	_check(SH.RCS_JET.contains("cross(wdir, CAMERA_POSITION_WORLD - wp)"),
		"SH.RCS_JET orients its cone along the 3D jet direction toward the camera")
	_check(SH.RCS_JET.contains("core_col") and SH.RCS_JET.contains("wash_col") and SH.RCS_JET.contains("spow(1.0 - u"),
		"SH.RCS_JET carries hot core, soft wash and quick fade")

	# 2. Faction palettes come from faction_looks.json and preserve approved faction looks
	var expected_kind := {"voidsworn": 0, "hegemony": 0, "corsair": 0, "ithar": 1, "chorus": 2, "deathless": 3}
	var washes := {}
	for fac in expected_kind:
		var pal: Dictionary = TP.palette(fac)
		var core: Color = pal["core"]
		var wash: Color = pal["wash"]
		var kind := int(pal["kind"])
		_check(kind == int(expected_kind[fac]), "%s uses RCS mode %d (got %d)" % [fac, int(expected_kind[fac]), kind])
		washes[fac] = wash
		var mi := SV.build_rcs_jet(fac, Vector3(0, 0, 1), 2.4, 0.45, 1.3, 0.9, 0.25)
		_check(mi is MeshInstance3D and mi.mesh == SV._rcs_quad_mesh(), "%s builds shared cone-jet mesh" % fac)
		_check(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "%s casts no shadows" % fac)
		var mat := mi.material_override as ShaderMaterial
		_check(mat != null and mat.shader != null and mat.shader.code == SH.RCS_JET, "%s uses shared SH.RCS_JET shader" % fac)
		_check(is_equal_approx(float(mat.get_shader_parameter("jet_kind")), float(kind)), "%s sets jet_kind uniform" % fac)
		var c_u: Vector3 = mat.get_shader_parameter("core_col")
		var w_u: Vector3 = mat.get_shader_parameter("wash_col")
		_check(c_u.is_equal_approx(Vector3(core.r, core.g, core.b)), "%s passes faction core_col" % fac)
		_check(w_u.is_equal_approx(Vector3(wash.r, wash.g, wash.b)), "%s passes faction wash_col" % fac)
		mi.free()

	# Faction look invariants
	var ithar_pal: Dictionary = TP.palette("ithar")
	_check(str(ithar_pal["style"]) == "glint" and int(ithar_pal["kind"]) == 1,
		"Glasswrights keep non-mechanical prismatic flare (no white cold gas)")
	_check((ithar_pal["wash"] as Color).is_equal_approx(FLOOK.engine("ithar")),
		"Glasswright wash reads stored violet engine colour from faction_looks.json")
	var chorus_pal: Dictionary = TP.palette("chorus")
	_check(str(chorus_pal["style"]) == "pulse" and int(chorus_pal["kind"]) == 2 and int(TP.of("chorus")["sparks"]) == 0,
		"Chorus keeps organic pulse with no metal sparks")
	_check((chorus_pal["wash"] as Color).is_equal_approx(FLOOK.engine("chorus")),
		"Chorus wash reads organic engine colour from faction_looks.json")
	var ec_pal: Dictionary = TP.palette("deathless")
	var ec_c: Color = ec_pal["core"]
	var ec_w: Color = ec_pal["wash"]
	_check(ec_c.b > ec_c.r and ec_c.r > ec_c.g and ec_w.b > ec_w.r and ec_w.r > ec_w.g,
		"Eclipse RCS palette stays strictly violet (no green, no orange)")
	_check(not (washes["voidsworn"] as Color).is_equal_approx(washes["hegemony"] as Color)
		and not (washes["hegemony"] as Color).is_equal_approx(washes["corsair"] as Color),
		"Mechanical gas factions get distinct faction-tinted washes")

	# 3. Anchored stepping and expiry in ShipView._puffs_step
	var world := Node3D.new()
	root.add_child(world)
	var sv := SV.new()
	world.add_child(sv)
	sv.set_process(false)
	sv.fac = "hegemony"
	sv.tp = TP.of("hegemony")
	var local_at := Vector3(4.0, 0.2, 1.5)
	var local_dir := Vector3(0.0, 0.0, 1.0)
	var jet := SV.build_rcs_jet("hegemony", local_dir, 2.5, 0.5, 1.4, 0.9, 0.1)
	jet.top_level = true
	sv.add_child(jet)
	jet.global_position = sv.to_global(local_at)
	sv.puffs.append({"n": jet, "mat": jet.material_override, "t": 0.0, "life": 0.25, "style": "gas",
		"local_at": local_at, "local_dir": local_dir})
	sv.position = Vector3(10.0, 0.0, -3.0)
	sv.rotation.y = PI * 0.5
	sv._puffs_step(0.1)
	var mat_live := jet.material_override as ShaderMaterial
	_check(is_equal_approx(float(mat_live.get_shader_parameter("age_u")), 0.4),
		"stepping advances cone-jet age_u cleanly")
	_check(jet.global_position.is_equal_approx(sv.to_global(local_at)),
		"cone jet stays anchored to the moving and turning hull nozzle")
	var expected_dir := sv.global_transform.basis.orthonormalized() * local_dir
	_check((mat_live.get_shader_parameter("jet_dir") as Vector3).is_equal_approx(expected_dir),
		"cone jet direction rotates with the hull")
	sv._puffs_step(0.2)
	_check(sv.puffs.is_empty(), "cone jet frees cleanly once its quick fade finishes")

	world.queue_free()
	await process_frame
	var mesh_ref := weakref(SV._rcs_quad_mesh())
	SV.clear_static()
	_check(mesh_ref.get_ref() == null, "ShipView.clear_static releases the shared RCS cone-jet mesh")
	print("RCS_CONE_JET_CHECK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
