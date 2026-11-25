extends SceneTree
# Issue 2042 item 6: TRAIL shader isolation check (headless).
# Verifies that the new taper and tail fade in SH.TRAIL apply to ship engines only (use_strip_taper > 0.5),
# torpedo and rocket kit trails (SH.kit_trail_code / fx_weapons.gd) stay as on main with use_strip_taper = 0.0,
# and style 3 keeps its orange sparkle from main.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const WEAP := preload("res://fx/fx_weapons.gd")

var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "trail_kit_isolation_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)


func _run() -> void:
	var frag_idx: int = SH.TRAIL.find("void fragment()")
	_check(frag_idx > 0, "SH.TRAIL defines fragment()")
	var frag: String = SH.TRAIL.substr(frag_idx)
	var gate_idx: int = frag.find("if (use_strip_taper > 0.5)")
	var taper_idx: int = frag.find("float taper =")
	var tail_idx: int = frag.find("float tail_end =")
	_check(gate_idx > 0 and taper_idx > gate_idx and tail_idx > gate_idx,
		"SH.TRAIL places taper and tail_end strictly inside if (use_strip_taper > 0.5)")
	_check(frag.contains("float across = exp(-x * x * 2.2);")
		and frag.contains("float fade = spow(1.0 - s, 1.8);")
		and frag.contains("vec3 col = mix(vCol.rgb, vec3(0.30, 0.38, 0.60), smoothstep(0.0, 0.55, s));")
		and frag.contains("float root = smoothstep(0.0, 0.025, s);")
		and frag.contains("hot = mix(col, vec3(1.0, 0.94, 0.82), 0.6) * exp(-x*x*16.0) * 0.5;"),
		"SH.TRAIL keeps main's exact baseline trail path when use_strip_taper <= 0.5")
	_check(frag.contains("col += vec3(1.0, 0.5, 0.15) * spow(vnoise(vec2(s * 60.0 - scene_t, seed * 3.0)), 12.0) * 2.0;"),
		"SH.TRAIL style 3 keeps main's orange sparkle")

	var kit_code: String = SH.kit_trail_code(WEAP.KIT_TRAIL_PTS)
	_check(not kit_code.contains("CUSTOM1"),
		"SH.kit_trail_code strips all CUSTOM1 references for fixed kit trail strips")
	_check(kit_code.contains("uniform float use_strip_taper = 0.0;")
		and kit_code.contains("col += vec3(1.0, 0.5, 0.15) * spow(vnoise(vec2(s * 60.0 - scene_t, seed * 3.0)), 12.0) * 2.0;"),
		"SH.kit_trail_code defaults use_strip_taper to 0.0 and preserves style 3 orange sparkle")

	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	# Spawn torpedo and rocket kit trails (including style 3) and confirm use_strip_taper stays off.
	for row in [["torp", "voidsworn", 0], ["rockets", "corsair", 1], ["torp", "deathless", 3]]:
		var body := Node3D.new()
		world.add_child(body)
		var p := {"k": 1.0, "lk": row[0], "faction": row[1], "eng": Color(0.8, 0.5, 1.0), "seed": 0.25, "mesh": body}
		var fac := {"trail": row[2], "engine_extra": "soot" if row[2] == 1 else "none"}
		WEAP._kit_trail_start(fx, p, fac)
		var tr: Dictionary = p["trail"]
		var mi := tr["mi"] as MeshInstance3D
		var mat := mi.material_override as ShaderMaterial
		_check(mat != null and mat.shader != null and mat.shader.code == WEAP.kit_trail_shader_code(),
			"%s %s uses compiled kit_trail_shader_code" % [row[1], row[0]])
		var taper_val = mat.get_shader_parameter("use_strip_taper")
		var taper_f := 0.0 if taper_val == null else float(taper_val)
		_check(is_equal_approx(taper_f, 0.0),
			"%s %s kit trail leaves use_strip_taper at 0.0 (got %.2f)" % [row[1], row[0], taper_f])
		_check(is_equal_approx(float(mat.get_shader_parameter("trail_style")), float(row[2])),
			"%s %s kit trail preserves trail_style %d" % [row[1], row[0], int(row[2])])
		mi.queue_free()
		body.queue_free()

	# Spawn a ship engine trail and confirm it turns on use_strip_taper = 1.0.
	var ship_body := Node3D.new()
	world.add_child(ship_body)
	var ship_mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(14.0, 2.5, 4.5)
	ship_mi.mesh = box
	ship_body.add_child(ship_mi)
	fx.add_ship("eng_ship", ship_body, {"meshes": [ship_mi], "shielded": false, "faction": "deathless"})
	var ship = fx.ships["eng_ship"]
	ship._eng_cur = 1.6
	ship.engine_level = 1.6
	for i in 5:
		ship_body.position.x += 1.0
		fx.now += 0.06
		ship._update_trails(fx, true)
	_check(not ship._trails.is_empty(), "ship built nozzle trails")
	var smat := (ship._trails[0]["mi"] as MeshInstance3D).material_override as ShaderMaterial
	_check(is_equal_approx(float(smat.get_shader_parameter("use_strip_taper")), 1.0),
		"ship engine trail enables use_strip_taper = 1.0")
	_check(is_equal_approx(float(smat.get_shader_parameter("trail_style")), 3.0),
		"Eclipse ship engine trail uses trail_style 3")

	fx.remove_ship("eng_ship")
	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("TRAIL_KIT_ISOLATION_CHECK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
