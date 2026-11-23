extends SceneTree
# Issue 1264: the backdrop planet, its rings and its moons are never cut by the battle camera's far plane, and a near
# rock fades out before the live near plane can slice it open.
# 1. Builds the system (world.gd system) for every ringed planet in every palette table, at frame scale 1 and at
#    camera_rig.gd PLANET_FRAME_MAX (issue 1272 boss framing), over several seeds and yaws, with the board
#    centre off the origin, and puts the camera rig at its widest zoom (r 900), panned to every corner of its bounds,
#    orbiting all the way round and over its full tilt. Every vertex of the planet, ring, atmosphere and moon meshes
#    must sit nearer than the rig's far plane in view depth.
# 2. At r 26, 45, 100 and 170 the rig's near plane is pushed into the cam_near shader global, and ROCK_SHADER's fade
#    (both copies) reaches zero before the rock's nearest point reaches that plane.

const GUARD := preload("res://tools/ci/check_guard.gd")
const WORLD := preload("res://world/world.gd")
const SKY := preload("res://world/world_sky.gd")
const RIG := preload("res://render/camera_rig.gd")

class StubBaker extends Node:
	func bake(_key, _code, _params, _size, _n) -> Image:
		return null

var failures := 0


func _init() -> void:
	GUARD.arm(self, "backdrop_clip_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


# Every vertex of every mesh the system added, in world space.
func _points(world: Node3D, first_child: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in range(first_child, world.get_child_count()):
		var mi := world.get_child(i) as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf := mi.transform
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				out.append(xf * v)
	return out


func _far_case(rig: Camera3D, pts: PackedVector3Array, label: String) -> float:
	var worst := 0.0
	var b: Vector2 = rig.bounds
	for corner in [Vector3(b.x, 0, b.y), Vector3(-b.x, 0, b.y), Vector3(b.x, 0, -b.y), Vector3(-b.x, 0, -b.y), Vector3.ZERO]:
		for ai in 12:
			for tilt in [0.05, 0.5, 1.0, 1.36]:
				rig.a = float(ai) * TAU / 12.0
				rig.b = tilt
				rig.r = 900.0
				rig.t = corner
				rig.snap()
				var inv := rig.global_transform.affine_inverse()
				var deepest := 0.0
				for p in pts:
					deepest = maxf(deepest, -(inv * p).z)
				worst = maxf(worst, deepest / rig.far)
				if deepest >= rig.far:
					_check(false, "%s: a backdrop point is %.0f deep, past the far plane %.0f (pan %s, a %.2f, b %.2f)" % [label, deepest, rig.far, corner, rig.a, tilt])
					return worst
	return worst


func _run() -> void:
	var rig: Camera3D = RIG.new()
	rig.bounds = Vector2(320, 260)
	root.add_child(rig)
	rig.current = true
	# Every ringed planet in every palette table (PLANETS, PLANETS_ALT and any later one), giants and the rest.
	var ringed: Array = []
	var consts: Dictionary = (load("res://world/world_sky.gd") as Script).get_script_constant_map()
	for key in consts:
		if not String(key).begins_with("PLANETS") or not (consts[key] is Array):
			continue
		for P in consts[key]:
			if P is Dictionary and bool(P.get("rings", false)):
				ringed.append(P)
	_check(ringed.size() >= 2, "fewer than two ringed planets found in world_sky.gd's palette tables")
	# Issue 1272 stop framing: no stop may frame the planet larger than the rig's far plane was sized for.
	var biggest := 1.0
	for row in (consts.get("STOP_FRAMES", []) as Array):
		biggest = maxf(biggest, float(row.get("scale", 1.0)))
	var mood: Dictionary = consts.get("STOP_MOOD", {})
	for k in mood:
		biggest = maxf(biggest, float(mood[k].get("frame", 1.0)))
	_check(biggest <= RIG.PLANET_FRAME_MAX, "a stop frames the planet at %.2f, past camera_rig.gd PLANET_FRAME_MAX %.2f" % [biggest, RIG.PLANET_FRAME_MAX])
	var cases := 0
	var worst := 0.0
	for P in ringed:
		for frame in [1.0, RIG.PLANET_FRAME_MAX]:
			for seed in [3, 41, 777, 4103]:
				for yaw in [0.0, 1.3, 2.9, 4.4]:
					var world: Node3D = WORLD.new()
					world._baker = StubBaker.new()
					world.add_child(world._baker)
					root.add_child(world)
					world.setting = {"planet": P, "seed": seed, "planet_i": 0, "frame_scale": frame}
					world._yaw = yaw
					world._center = Vector3(40, 0, -30)
					var first := world.get_child_count()
					world.system(true)
					var pts := _points(world, first)
					_check(pts.size() > 1000, "seed %d yaw %.1f: the system built no meshes" % [seed, yaw])
					worst = maxf(worst, _far_case(rig, pts, "kind %d frame %.1f seed %d yaw %.1f" % [int(P["kind"]), frame, seed, yaw]))
					cases += 1
					world.free()
	print("far plane: %d ringed systems, deepest backdrop point at %.0f%% of the far plane" % [cases, worst * 100.0])
	_check(worst > 0.5, "the far check saw no backdrop (deepest %.2f of far)" % worst)

	# 2. near fade
	var src: String = FileAccess.get_file_as_string("res://world/world_rocks.gd")
	# every rock shader in the file (one since Ryan scrapped the crystal clusters, issue 1361)
	var shaders := src.count("shader_type spatial")
	_check(shaders >= 1, "world_rocks.gd holds no rock shader")
	var fades := src.count("camera_cover = smoothstep(cam_near + 1.5, cam_near + 1.5 + max(1.0, radius * 0.25), min(clearance, depth_clear));")
	_check(fades == shaders, "every rock shader must fade from the live near plane (found %d of %d)" % [fades, shaders])
	_check(src.count("global uniform float cam_near;") == shaders, "every rock shader must read the cam_near global")
	_check(ProjectSettings.has_setting("shader_globals/cam_near"), "project.godot must declare the cam_near shader global")
	# Artoo on PR 1306: the fade must measure from the rig's published camera, never the pass's own VIEW_MATRIX, so a
	# shadow pass (seen from the light) fades a rock the same way the view does.
	_check(src.count("vec3 eye = cam_eye.w > 0.5 ? cam_eye.xyz : CAMERA_POSITION_WORLD;") == shaders, "every rock fade must measure from the cam_eye global")
	_check(src.count("float depth_clear = dot(MODEL_MATRIX[3].xyz - eye, fwd) - radius;") == shaders, "every rock fade must take depth along cam_fwd")
	_check(src.count("(VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz") == 0, "the rock fade must not use the pass's VIEW_MATRIX")
	_check(ProjectSettings.has_setting("shader_globals/cam_eye") and ProjectSettings.has_setting("shader_globals/cam_fwd"), "project.godot must declare cam_eye and cam_fwd")
	for radius in [26.0, 45.0, 100.0, 170.0]:
		rig.r = radius
		rig.snap()
		var live: float = RenderingServer.global_shader_parameter_get(&"cam_near") if DisplayServer.get_name() != "headless" else rig.near
		# The fade's zero point (cover 0, every fragment dithered out) against the plane: the rock's nearest depth is
		# its centre depth minus its radius, which is what depth_clear measures.
		var zero_at := rig.near + 1.5
		_check(zero_at > rig.near, "r %.0f: the rock fade ends at %.1f, not before the near plane %.1f" % [radius, zero_at, rig.near])
		_check(is_equal_approx(live, rig.near), "r %.0f: cam_near %.2f does not follow the rig's near %.2f" % [radius, live, rig.near])
		# The published forward is the rig's own view axis, so depth along it equals the view's depth.
		var fwd: Vector3 = (rig.t - rig.global_position).normalized() if rig.is_inside_tree() else Vector3.ZERO
		if rig.is_inside_tree():
			_check(fwd.dot(-rig.global_transform.basis.z) > 0.9999, "r %.0f: cam_fwd is not the rig's view axis" % radius)
		print("r %.0f: near %.1f, rock gone by depth %.1f" % [radius, rig.near, zero_at])
	rig.free()
	print("backdrop_clip_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
