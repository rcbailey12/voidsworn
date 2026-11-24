extends SceneTree
# Issue 2042 item 2: moving engine trail nozzle anchoring and taper check (headless).
# Verifies that fx_ship._update_trails anchors samples and live shader head_world directly to the
# nozzle (zero detached stern offset), tapers width from nozzle root to slender tip, encodes strip
# progress along CUSTOM1.w, detaches cleanly with feathered edges when the drive cuts cold, and
# removes hardcoded orange sparks from Eclipse trail style 3.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")

var failures := 0
var checks := 0


func _init() -> void:
	GUARD.arm(self, "moving_trail_anchor_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, msg: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)


func _run() -> void:
	_check(SH.TRAIL.contains("uniform float anchor_head") and SH.TRAIL.contains("uniform vec3 head_world"),
		"SH.TRAIL exposes live nozzle anchoring uniforms")
	_check(SH.TRAIL.contains("float taper = mix(1.0,") and SH.TRAIL.contains("tail_end"),
		"SH.TRAIL tapers visual cross-section and feathers the tail end")
	_check(not SH.TRAIL.contains("vec3(1.0, 0.5, 0.15)"),
		"SH.TRAIL has no hardcoded orange leak on Eclipse style 3")

	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})

	var body := Node3D.new()
	world.add_child(body)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(16.0, 3.0, 6.0)
	mi.mesh = box
	body.add_child(mi)
	fx.add_ship("cruiser", body, {"meshes": [mi], "shielded": false, "faction": "hegemony"})
	var ship = fx.ships["cruiser"]
	ship._eng_cur = 1.6
	ship.engine_level = 1.6

	# Step forward so samples are recorded along the path.
	for i in 10:
		body.position.x += 1.2
		fx.now += 0.06
		ship._update_trails(fx, true)

	_check(not ship._trails.is_empty(), "ship built nozzle trails")
	for tr in ship._trails:
		var hist: Array = tr["hist"]
		_check(hist.size() >= 4, "moving ship accumulated trail history")
		var nozzle_w: Vector3 = ship.xf() * (tr["p"] as Vector3)
		_check((hist[0][0] as Vector3).distance_to(nozzle_w) < 0.001,
			"newest trail sample sits right on the nozzle exit (no detached stern gap)")
		var mat := (tr["mi"] as MeshInstance3D).material_override as ShaderMaterial
		_check(is_equal_approx(float(mat.get_shader_parameter("anchor_head")), 1.0),
			"active burn anchors shader head to live nozzle")
		_check((mat.get_shader_parameter("head_world") as Vector3).distance_to(nozzle_w) < 0.001,
			"shader head_world matches live nozzle position")
		var arrays: Array = (tr["mi"] as MeshInstance3D).mesh.surface_get_arrays(0)
		var c1: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM1]
		var w0 := c1[0]
		var w1 := c1[1]
		_check(w0 > w1 and w1 > 0.0, "trail tapers from nozzle width (%.3f) to narrower tail (%.3f)" % [w0, w1])
		_check(is_equal_approx(c1[3], 0.0) and is_equal_approx(c1[c1.size() - 1], 1.0),
			"CUSTOM1.w carries strip progress 0.0 at nozzle to 1.0 at tail")

	# Move a tiny distance between sample ticks: shader head_world tracks live nozzle even without pushing a new sample.
	body.position.x += 0.4
	fx.now += 0.01
	ship._update_trails(fx, true)
	var tr0: Dictionary = ship._trails[0]
	var nozzle_live: Vector3 = ship.xf() * (tr0["p"] as Vector3)
	var mat0 := (tr0["mi"] as MeshInstance3D).material_override as ShaderMaterial
	_check((mat0.get_shader_parameter("head_world") as Vector3).distance_to(nozzle_live) < 0.001
		and is_equal_approx(float(mat0.get_shader_parameter("anchor_head")), 1.0),
		"between samples head_world stays locked onto the moving nozzle")

	# Cut drive cold (braking): head detaches cleanly so old exhaust stays in space and feathers out.
	ship._moving = 0.4
	ship.engine_level = 0.0
	fx.now += 0.05
	ship._update_trails(fx, true)
	_check(is_equal_approx(float(mat0.get_shader_parameter("anchor_head")), 0.0),
		"cold braking releases head anchor so old exhaust is not dragged with the hull")

	fx.remove_ship("cruiser")
	fx.queue_free()
	await process_frame
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("MOVING_TRAIL_ANCHOR_CHECK %s: %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(1 if failures > 0 else 0)
