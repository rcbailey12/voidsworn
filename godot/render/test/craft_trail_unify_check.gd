extends SceneTree
# Issue 2042 item 4: unified strike craft trail check (headless).
# Verifies that squadron_wing.gd uses the shared SH.CRAFT_TRAIL kit directly (no separate flat fallback),
# anchors each craft's live stern in head_world, keeps Chorus's short organic shimmer and Glasswright's
# prismatic edge, and matches fx_weapons._wing_trail_update without swapping shaders.

const GUARD := preload("res://tools/ci/check_guard.gd")
const WING := preload("res://render/squadron_wing.gd")
const SH := preload("res://fx/fx_shaders.gd")
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")

var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "craft_trail_unify_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)


func _run() -> void:
	_check(WING.TRAIL == SH.CRAFT_TRAIL, "squadron_wing.TRAIL is unified directly with SH.CRAFT_TRAIL")
	_check(SH.CRAFT_TRAIL.contains("fog_disabled") and SH.CRAFT_TRAIL.contains("uniform float life")
		and SH.CRAFT_TRAIL.contains("uniform float trail_style"),
		"SH.CRAFT_TRAIL ignores fog and carries life and trail_style uniforms")

	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	for row in [["voidsworn", "fighter", 0.0, WING.TRAIL_LIFE], ["hegemony", "fighter", 0.0, WING.TRAIL_LIFE],
			["corsair", "bomber", 0.0, WING.TRAIL_LIFE], ["ithar", "fighter", 2.0, WING.TRAIL_LIFE],
			["chorus", "spore", 1.0, WING.TRAIL_LIFE_CHORUS]]:
		var fac: String = row[0]
		var kind: String = row[1]
		var want_style: float = row[2]
		var want_life: float = row[3]
		var wing := WING.new()
		world.add_child(wing)
		wing.setup(fac, kind, 3.0, 3, 0.2)
		wing.set_process(false)
		_check(wing.trail_mat != null and wing.trail_mat.shader.code == SH.CRAFT_TRAIL,
			"%s wing uses shared SH.CRAFT_TRAIL natively" % fac)
		_check(is_equal_approx(float(wing.trail_mat.get_shader_parameter("trail_style")), want_style),
			"%s wing sets trail_style %.0f" % [fac, want_style])
		_check(is_equal_approx(float(wing.trail_mat.get_shader_parameter("life")), want_life),
			"%s wing sets trail life %.2f" % [fac, want_life])
		for k in 4:
			wing.step(1.0 / 30.0)
		var mat0: ShaderMaterial = wing.trails[0]["mat"]
		var node_mat: ShaderMaterial = (wing.trails[0]["node"] as MeshInstance3D).material_override
		_check(mat0 != null and mat0 == node_mat and mat0.shader == wing.trail_mat.shader,
			"%s craft ribbon shares compiled SH.CRAFT_TRAIL shader with own per-craft uniforms" % fac)
		var stern0: Vector3 = wing.craft[0].to_global(wing._stern)
		_check((mat0.get_shader_parameter("head_world") as Vector3).is_equal_approx(stern0),
			"%s craft trail head_world tracks live stern" % fac)
		_check(is_equal_approx(float(mat0.get_shader_parameter("anchor_ready")), 1.0),
			"%s craft trail anchor_ready is active after sampling" % fac)
		# Calling fx_weapons._wing_trail_update preserves the exact same unified material.
		WEAP._wing_trail_update(fx, wing)
		_check((wing.trails[0]["node"] as MeshInstance3D).material_override == mat0,
			"%s fx_weapons._wing_trail_update reuses squadron_wing's unified SH.CRAFT_TRAIL material" % fac)
		wing.queue_free()

	await process_frame
	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("CRAFT_TRAIL_UNIFY_CHECK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
