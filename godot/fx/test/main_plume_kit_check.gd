extends SceneTree
# Issue 2042 item 3: main engine plume bright core + outer wash + faction palettes + throttle response (headless).

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const SHIP := preload("res://fx/fx_ship.gd")

var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "main_plume_kit_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)


func _run() -> void:
	# 1. Shader carries bright core, soft outer wash, smooth bell entry, and throttle uniform.
	_check(SH.RIBBON.contains("uniform vec3 plume_core") and SH.RIBBON.contains("uniform vec3 plume_wash"),
		"SH.RIBBON exposes plume_core and plume_wash faction uniforms")
	_check(SH.RIBBON.contains("uniform float plume_style") and SH.RIBBON.contains("uniform float throttle_k"),
		"SH.RIBBON exposes plume_style and throttle_k uniforms")
	_check(SH.RIBBON.contains("inner_core") and SH.RIBBON.contains("outer_wash") and SH.RIBBON.contains("bell_in"),
		"SH.RIBBON layers bright inner_core, outer_wash and smooth bell_in root blend")

	# 2. All 6 factions get distinct faction_looks.json plume palettes and respect approved faction looks.
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	var styles := {}
	var cores := {}
	var washes := {}
	for fac in ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]:
		var body := Node3D.new()
		world.add_child(body)
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(14.0, 2.5, 4.5)
		mi.mesh = box
		body.add_child(mi)
		fx.add_ship("plume_" + fac, body, {"meshes": [mi], "shielded": false, "faction": fac})
		var s = fx.ships["plume_" + fac]
		_check(s._eng_rib_mat != null, "%s builds main plume ribbon material" % fac)
		var st := int(roundf(float(s._eng_rib_mat.get_shader_parameter("plume_style"))))
		var pc: Vector3 = s._eng_rib_mat.get_shader_parameter("plume_core")
		var pw: Vector3 = s._eng_rib_mat.get_shader_parameter("plume_wash")
		styles[fac] = st
		cores[fac] = pc
		washes[fac] = pw
		_check(pc.length() > 0.5 and pw.length() > 0.2, "%s sets non-zero core and outer wash" % fac)

		# Throttle response from movement stage 2: idle vs full burn updates gate, lenk, and throttle_k.
		fx.set_engine("plume_" + fac, 0.3)
		for k in 30:
			fx.step(0.05)
		var idle_gate := float(s._eng_rib_mat.get_shader_parameter("gate"))
		var idle_lenk := float(s._eng_rib_mat.get_shader_parameter("lenk"))
		var idle_tk := float(s._eng_rib_mat.get_shader_parameter("throttle_k"))

		fx.set_engine("plume_" + fac, 1.6)
		for k in 30:
			fx.step(0.05)
		var burn_gate := float(s._eng_rib_mat.get_shader_parameter("gate"))
		var burn_lenk := float(s._eng_rib_mat.get_shader_parameter("lenk"))
		var burn_tk := float(s._eng_rib_mat.get_shader_parameter("throttle_k"))
		_check(burn_gate > idle_gate * 3.0 and burn_lenk > idle_lenk + 0.4 and burn_tk > idle_tk * 2.5,
			"%s keeps stage-2 throttle response across gate, lenk and throttle_k (idle %.2f/%.2f/%.2f -> burn %.2f/%.2f/%.2f)"
			% [fac, idle_gate, idle_lenk, idle_tk, burn_gate, burn_lenk, burn_tk])

		fx.remove_ship("plume_" + fac)
		body.free()

	# Verify all 6 factions have unique styles and Eclipse stays violet (no green, no orange).
	var seen_styles := {}
	for fac in styles:
		seen_styles[styles[fac]] = true
	_check(seen_styles.size() == 6, "all 6 factions carry distinct plume styles (%s)" % str(styles))
	var ec_core: Vector3 = cores["deathless"]
	var ec_wash: Vector3 = washes["deathless"]
	_check(ec_core.z > ec_core.x and ec_core.x > ec_core.y and ec_wash.z > ec_wash.x and ec_wash.x > ec_wash.y,
		"Eclipse plume core and outer wash stay strictly violet (no green, no orange)")

	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("MAIN_PLUME_KIT_CHECK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
