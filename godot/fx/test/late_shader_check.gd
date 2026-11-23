extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 376: after the warm-up ends, a shader first built later names itself once, through _mat and the hull and death
# helpers, and the counter a test reads moves with it. Logging and counting only: nothing on screen changes.
const FX := preload("res://fx/fx.gd")
const HULL := preload("res://fx/fx_hull.gd")
const DEATH := preload("res://fx/fx_death.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "late_shader_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)


func _code(tag: String) -> String:
	return "shader_type canvas_item;\nrender_mode unshaded;\n// issue 376 fixture " + tag + "\nvoid fragment() { COLOR = vec4(1.0); }\n"


func _has_line(lines: Array, part: String) -> bool:
	for line in lines:
		if str(line).contains(part):
			return true
	return false


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	HULL.reset_late()
	check(not HULL.late_watch, "the late watch starts off")
	check(HULL.late_shader_count() == 0, "the late counter starts at 0")
	var fx = FX.new()
	world.add_child(fx)
	# A shader made before the flag is not a miss in the warm-up list. Keep the returned shader alive: the shared
	# cache holds only a weak reference, as it does in the game while a material uses it.
	var keep_exterior: Shader = HULL.shared_shader(HULL.EXTERIOR)
	var early = fx._mat(_code("early"))
	check(HULL.late_shader_count() == 0, "a shader built before the warm-up ends is not named")
	check(early is ShaderMaterial, "the early material exists")
	# The warm-up's last act is to set the flag (fx.warmup calls HULL.start_late_watch).
	HULL.start_late_watch()
	check(HULL.late_watch, "the flag is set when the warm-up ends")
	var a = fx._mat(_code("a"))
	check(HULL.late_shader_count() == 1, "a shader first built after the flag is counted")
	var lines: Array = HULL.late_shader_names()
	check(lines.size() == 1 and _has_line(lines, "frame ") and _has_line(lines, " ms"),
		"the log line carries the name, the frame and the time: " + str(lines))
	check(fx.late_shader_count() == HULL.late_shader_count(), "the effects system reads the same counter")
	check(fx.late_shader_names() == lines, "the effects system reads the same names")
	# One line per name, however often the name is built.
	var again = fx._mat(_code("a"))
	check(again is ShaderMaterial and HULL.late_shader_count() == 1, "the same shader is logged only once")
	# A cached shader reached from a fresh effects system is not a new build.
	var fx2 = FX.new()
	world.add_child(fx2)
	var cached = fx2._mat(_code("a"))
	check(cached is ShaderMaterial and HULL.late_shader_count() == 1, "a cached shader is not logged again")
	# A caller can name its material (the death helpers do).
	var b = fx._mat(_code("b"), 0, "", "named by its caller")
	check(HULL.late_shader_count() == 2 and _has_line(HULL.late_shader_names(), "named by its caller"),
		"a caller's name reaches the log")
	# The death helper path names its own material.
	var r = DEATH.route_material(fx, _code("route"), "test/route_")
	check(r is ShaderMaterial and HULL.late_shader_count() == 3 and _has_line(HULL.late_shader_names(), "route test/route_"),
		"the death route helper names a late shader")
	# The hull helper path names its own material (EXTERIOR was made before the flag).
	var dm = HULL.damage_material(StandardMaterial3D.new(), Transform3D.IDENTITY, {}, 1.0)
	check(dm is ShaderMaterial and HULL.late_shader_count() == 4 and _has_line(HULL.late_shader_names(), "damage "),
		"the hull damage helper names a late shader")
	# The flag does not clear the list, but a new run does.
	HULL.pause_late_watch()
	check(HULL.late_shader_count() == 4, "a pause keeps the names already found")
	HULL.reset_late()
	check(HULL.late_shader_count() == 0 and HULL.late_shader_names().is_empty() and not HULL.late_watch,
		"a reset starts a new run clean")
	await _check_damage_warmup(fx, world)
	print("LATE_SHADER failures=%d" % failures)
	world.queue_free()
	await process_frame
	FX.clear_static()
	quit(1 if failures else 0)


func _check_damage_warmup(fx, world: Node3D) -> void:
	var cam := Camera3D.new()
	world.add_child(cam)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "low"})
	# Model the deferred fog policy changing a source after its template was cached.
	var painted := StandardMaterial3D.new()
	var before: ShaderMaterial = fx.hull_damage_template(painted, 10.0, false)
	painted.disable_fog = true
	var fogless: ShaderMaterial = fx.hull_damage_template(painted, 10.0, false)
	check(before.shader != fogless.shader and fogless.shader.code.contains("fog_disabled"),
		"changing the source's fog mode selects a different damage shader")
	fogless = null
	# Start from a fresh FX so the explicit warm list must supply the fogless
	# variants, even when no ship has been added yet.
	var warm := FX.new()
	world.add_child(warm)
	warm.manual = true
	warm.setup({"camera": cam, "quality": "low"})
	fx.release()
	await warm.warmup(cam, 0)
	check(HULL.late_watch, "the warm-up enables the late watch")
	for alpha in [false, true]:
		var source := StandardMaterial3D.new()
		source.disable_fog = true
		if alpha:
			source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var power: ShaderMaterial = warm.hull_damage_template(source, 10.0, false, true)
		check(power.shader.code.contains("fog_disabled"), "the power-down variant keeps the source fog mode")
	check(HULL.late_shader_count() == 0, "opaque and alpha fogless damage and power shaders are still warm")
