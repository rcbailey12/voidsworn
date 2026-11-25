extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 2029 item 6: the mouse wheel zooms about the board point under the pointer, with today's limits.
#   godot --headless --path godot --script res://render/test/camera_zoom_pointer_check.gd
# Builds the real rig (render/camera_rig.gd) at the battle's opening view with the orders sheet's screen shift, and sends it
# real wheel events. After each step the pose is settled (snap) and the board point under the pointer is compared with the
# one before. Checks: zoom in and back out over the same hex keeps the point under the pointer (under 0.05 world units, the
# old zoom-about-the-middle drifted a hex-sized amount), off-centre pixels in all four quarters, over empty sky (a pointer
# above the horizon) the target does not move, the limits min_r and 900 hold, and the factor per step is unchanged.
const RIG := preload("res://render/camera_rig.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "camera_zoom_pointer_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("ok   " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _wheel(cam, pos: Vector2, up: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	e.pressed = true
	e.position = pos
	cam.handle_input(e)
	cam.snap()


func _hit(cam, pos: Vector2) -> Vector3:
	var o: Vector3 = cam.project_ray_origin(pos)
	var d: Vector3 = cam.project_ray_normal(pos)
	return o + d * ((cam.t.y - o.y) / d.y)


func _fresh():
	var cam = RIG.new()
	root.add_child(cam)
	cam.current = true
	cam.screen_shift = 180.0
	cam.t = Vector3(10.0, 0.0, -6.0)
	cam.snap()
	return cam


func _run() -> void:
	root.size = Vector2i(1280, 720)   # the size the audit measured at
	await process_frame
	var vs := root.get_visible_rect().size
	print("     viewport %s" % str(vs))
	var cam = _fresh()
	var home_r: float = cam.r
	var step := exp(120.0 * 0.0011)
	var worst := 0.0
	for q in [Vector2(0.2, 0.3), Vector2(0.8, 0.3), Vector2(0.2, 0.85), Vector2(0.85, 0.9), Vector2(0.5, 0.5)]:
		cam.r = home_r
		cam.t = Vector3(10.0, 0.0, -6.0)
		cam.snap()
		var px: Vector2 = vs * q
		var p0 := _hit(cam, px)
		var t0: Vector3 = cam.t
		for i in range(3):
			_wheel(cam, px, true)
			worst = maxf(worst, _hit(cam, px).distance_to(p0))
		_check(cam.r < home_r * 0.7, "pixel %s: three wheel-up steps zoom in (r %.1f)" % [str(q), cam.r])
		for i in range(3):
			_wheel(cam, px, false)
			worst = maxf(worst, _hit(cam, px).distance_to(p0))
		_check(absf(cam.r - home_r) < 0.01, "pixel %s: back out returns r (%.3f)" % [str(q), cam.r])
		_check(cam.t.distance_to(t0) < 0.05, "pixel %s: back out returns the target (off by %.4f)" % [str(q), cam.t.distance_to(t0)])
	print("     largest drift of the point under the pointer: %.5f world units" % worst)
	_check(worst < 0.05, "the board point under the pointer stays under it through zoom in and back out")
	# one step, as the audit measured it: how far the point moves on screen
	cam.r = home_r
	cam.t = Vector3(10.0, 0.0, -6.0)
	cam.snap()
	var px2 := Vector2(vs.x * 0.15, vs.y * 0.2)
	var p1 := _hit(cam, px2)
	_wheel(cam, px2, true)
	var back: Vector2 = cam.unproject_position(p1)
	_check(back.distance_to(px2) < 1.0, "one wheel step off-centre: the point moves %.2f px (was about 22 px at 1280x720)" % back.distance_to(px2))
	# control: the old zoom (r alone, target fixed) does move that point, so the check above can fail
	cam.r = home_r
	cam.t = Vector3(10.0, 0.0, -6.0)
	cam.snap()
	cam.r = home_r * exp(-120.0 * 0.0011)
	cam.snap()
	var old_drift: float = cam.unproject_position(p1).distance_to(px2)
	_check(old_drift > 10.0, "control: zoom about the target alone moves the point %.1f px" % old_drift)
	# over empty sky: a pointer above the horizon has no board point, so the target stays and the zoom is the plain one
	cam.b = 1.36
	cam.r = home_r
	cam.t = Vector3(10.0, 0.0, -6.0)
	cam.snap()
	var sky := Vector2(vs.x * 0.5, 1.0)
	var ray: Vector3 = cam.project_ray_normal(sky)
	if ray.y > -0.02:
		var t_before: Vector3 = cam.t
		_wheel(cam, sky, true)
		_check(cam.t.is_equal_approx(t_before), "over empty sky the target does not move")
		_check(absf(cam.r - home_r * exp(-120.0 * 0.0011)) < 0.01, "over empty sky the zoom factor is the plain one")
	else:
		_check(false, "test setup: the top row of the screen should look above the horizon at b 1.36")
	# limits
	var c2 = _fresh()
	for i in range(80):
		_wheel(c2, vs * Vector2(0.3, 0.4), true)
	_check(absf(c2.r - c2.min_r) < 0.001, "zoom in stops at min_r (%.3f)" % c2.r)
	for i in range(120):
		_wheel(c2, vs * Vector2(0.3, 0.4), false)
	_check(absf(c2.r - 900.0) < 0.001, "zoom out stops at 900 (%.3f)" % c2.r)
	_check(absf(c2.t.x) <= c2.bounds.x + 0.001 and absf(c2.t.z) <= c2.bounds.y + 0.001, "the target stays inside the board bounds")
	# the per-step factor is today's
	var c3 = _fresh()
	var r3: float = c3.r
	_wheel(c3, vs * 0.5, true)
	_check(absf(c3.r - r3 * exp(-120.0 * 0.0011)) < 0.001, "one wheel-up step scales r by exp(-0.132)")
	_wheel(c3, vs * 0.5, false)
	_check(absf(c3.r - r3) < 0.001, "one wheel-down step undoes it")
	print("camera_zoom_pointer_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
