extends Camera3D
# The game's RTS camera (scene3d.js CamCtl): orbit about a target on or above the board, smoothed.
# Right-drag orbits, left-drag or WASD / arrow keys pan, the wheel zooms, T toggles top-down, Home resets, F focuses.
# Angles as in the game's Babylon ArcRotateCamera (alpha around, beta down from straight up), with the world's z mirrored
# (Godot is right-handed, the game's Babylon scene left-handed), so the board looks the same way round.

signal pose_applied

var a := -PI / 2.0
var b := 0.98
var r := 170.0
var home_r := 170.0
var home_b := 0.98
var t := Vector3.ZERO
var home := Vector3.ZERO
var bounds := Vector2(300, 220)
var min_r := 26.0
var topdown := false
var prev_b := 0.88
var _ca := -PI / 2.0
var _cb := 0.86
var _cr := 215.0
var _ct := Vector3.ZERO
var _drag := 0          # 0 none, 1 pan (left), 2 orbit (right)
var _drag_moved := 0.0
var input_enabled := true
var keyboard_enabled := true
var slow_until := 0.0
var _clock := 0.0
var shake := Vector3.ZERO
# issue 1460: the trauma shake from fx.gd, as the camera's own h and v offsets in world units. fx writes it here and
# _apply adds it on top of screen_shift, so the sideways part is no longer wiped when the rig runs after fx.
var shake_offset := Vector2.ZERO
# issue 271 (E1 LEDGER): pixels to move the board's centre to the right of the screen's middle, so the point the camera
# looks at sits in the middle of the part the orders sheet leaves clear (hud.gd clear_shift). 0 keeps it centred.
var screen_shift := 0.0
const CUT_RETURN_S := 0.72
var _cut_return := Vector3.ZERO
var _cut_return_target := Vector3.ZERO
var _cut_return_elapsed := CUT_RETURN_S

var _close_dof := false
var _dof_room := 0.0
const DOF_AMOUNT := 0.075
const DOF_ENTER_S := 0.55
const DOF_CLOSE_LIMIT := 105.0
# Issue 2029 item 6 (Neon review): a pointer ray hitting the board plane farther out than this many times the bounds is
# treated as sky for the zoom-to-pointer anchor.
const HIT_MARGIN := 1.5


# Each camera owns its attributes, so a close-up cannot turn on blur in another viewport.
static func far_dof(focus_depth: float, subject_margin: float) -> CameraAttributesPractical:
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_near_enabled = false
	lens.dof_blur_far_distance = focus_depth + subject_margin
	lens.dof_blur_far_transition = maxf(40.0, 2.0 * subject_margin)
	lens.dof_blur_amount = 0.0
	return lens


func set_close_dof(active: bool, subject_length := 0.0) -> void:
	_close_dof = active
	if active:
		_dof_room = maxf(10.0, subject_length * 1.2)
		if attributes == null:
			attributes = far_dof(_cr, _dof_room)
	elif attributes is CameraAttributesPractical:
		attributes.dof_blur_far_enabled = false
		attributes.dof_blur_amount = 0.0


func _step_close_dof(dt: float) -> void:
	if not _close_dof:
		return
	var lens := attributes as CameraAttributesPractical
	if r >= DOF_CLOSE_LIMIT:
		lens.dof_blur_far_enabled = false
		lens.dof_blur_amount = 0.0
		return
	# Wait for the shot to approach focus before fading in. Keep the target and nearby silhouettes sharp.
	var near_shot := 1.0 - smoothstep(r * 1.15, r * 1.65, _cr)
	lens.dof_blur_far_distance = _cr + _dof_room
	lens.dof_blur_amount = move_toward(lens.dof_blur_amount, DOF_AMOUNT * near_shot, DOF_AMOUNT * dt / DOF_ENTER_S)
	lens.dof_blur_far_enabled = lens.dof_blur_amount > 0.0001


# Issue 1264: the far plane follows the zoom and pan, so the backdrop system is never cut off. The worst case from the
# board centre is a giant planet's ring at the largest framing a stop can give (issue 1272: a boss stop scales the
# planet's angle by up to PLANET_FRAME_MAX): world.gd DIST 3300 + 2.3 ring radii of 3300 * sin(0.18 * 1.5) = 5325 units (moons
# reach 1.15 * 3300 * (1 + sin(0.04)) = 3947, mountains about 2620). A camera r units out, looking at t (inside bounds),
# is at most r + |t| from the board origin, and the board centre is at most |bounds| from the origin; depth never
# exceeds straight-line distance. godot/world/test/backdrop_clip_check.gd builds ringed giants and holds this to the
# real meshes. Shadows (directional_shadow_max_distance 600) and volumetric fog (its own length) do not key off far.
const BACKDROP_REACH := 5400.0
# The largest planet framing scale any stop may use (world_sky.gd STOP_MOOD "frame" and STOP_FRAMES "scale", issue 1272).
# backdrop_clip_check fails if a stop table ever asks for more, and builds every ringed planet at this scale.
const PLANET_FRAME_MAX := 1.5
const FAR_MARGIN := 100.0
# Issue 1264: ROCK_SHADER fades a rock before this live near plane cuts it (global shader uniform, project.godot).
const NEAR_GLOBAL := &"cam_near"
# Artoo on PR 1306: the fade also needs this camera's eye and forward, so a shadow pass (drawn from the light) fades a
# rock against the same camera the near plane belongs to. cam_eye.w is 1 while a rig is current, 0 otherwise.
const EYE_GLOBAL := &"cam_eye"
const FWD_GLOBAL := &"cam_fwd"


func _ready() -> void:
	fov = 45.0
	near = 0.5
	_apply()


func _exit_tree() -> void:
	if current:
		RenderingServer.global_shader_parameter_set(EYE_GLOBAL, Vector4.ZERO)


static func far_for(radius: float, target: Vector3, board_bounds: Vector2) -> float:
	return BACKDROP_REACH + radius + target.length() + board_bounds.length() + FAR_MARGIN


func reset_view() -> void:
	a = -PI / 2.0
	b = home_b
	r = home_r
	t = home
	topdown = false


func snap() -> void:
	_cut_return_elapsed = CUT_RETURN_S
	_ca = a
	_cb = b
	_cr = r
	_ct = t
	_apply()


func cut_pose() -> Dictionary:
	return {"a": a, "b": b, "r": r, "t": t}


# Low shoulder for a battery volley. A chase looks nearly along the shot from behind the firing ship, but
# keeps a shoulder offset so the attacker cannot hide the target. Only the target has to clear the frame on impact.
func shot_cut(kind: String, source: Vector3, target: Vector3, source_len: float, target_len: float, calm: bool) -> Dictionary:
	var axis := target - source
	var dist := Vector2(axis.x, axis.z).length()
	if dist < 0.01 or kind in ["kill", "nova"]:
		return impact_cut(target, target_len, target_len >= 20.0, [], calm)
	var line := atan2(-axis.z, axis.x)
	var chase := kind in ["lance", "torp"]
	var shoulder := deg_to_rad(32.0 if chase else 62.0)
	var left := angle_difference(_ca, line + PI - shoulder)
	var right := angle_difference(_ca, line + PI + shoulder)
	var turn := left if absf(left) <= absf(right) else right
	var azimuth := _ca if calm else _ca + turn
	var beta := _cb if calm else (1.20 if chase else 1.29)
	var across := absf(sin(azimuth - line))
	var along := absf(cos(azimuth - line))
	var aspect := get_viewport().get_visible_rect().size.aspect()
	var span := 2.0 * tan(deg_to_rad(fov) * 0.5)
	# Allow for both the projected width and perspective (the foreground ship is closer than the focal point).
	var width := (dist * across + (source_len + target_len) * 0.52) / (span * maxf(aspect, 1.0) * 0.78)
	var height := (dist * along * cos(beta) + maxf(source_len, target_len) * 0.55 + absf(axis.y)) / (span * 0.72)
	var radius := maxf(width, height) + dist * along * 0.50
	return {"a": azimuth, "b": beta, "r": maxf(min_r, radius),
		"t": source.lerp(target, 0.57 if chase else 0.48)}


const IMPACT_BETA := 1.12


func impact_cut(target: Vector3, length: float, capital: bool, blockers: Array, calm: bool, yaw := 0.0) -> Dictionary:
	var span := 2.0 * tan(deg_to_rad(fov) * 0.5)
	var radius := clampf(maxf(length, 6.0) / ((1.0 if capital else 0.85) * span), min_r, 200.0)
	var best := _ca
	var beta := _cb if calm else IMPACT_BETA
	var score := INF
	if not calm:
		for quarter in [PI / 4.0, 3.0 * PI / 4.0, -PI / 4.0, -3.0 * PI / 4.0]:
			var turn := angle_difference(_ca, yaw + float(quarter))
			var azimuth := _ca + turn
			var eye := target + Vector3(cos(azimuth) * sin(beta), cos(beta), -sin(azimuth) * sin(beta)) * radius
			var seg := target - eye
			var cost := absf(turn)
			for blocker in blockers:
				var p: Vector3 = blocker[0]
				var k := clampf((p - eye).dot(seg) / seg.length_squared(), 0.0, 1.0)
				if k < 0.92 and (eye + seg * k).distance_to(p) < float(blocker[1]) * 0.6 + length * 0.15:
					cost += 10.0
			if cost < score:
				score = cost
				best = azimuth
	return {"a": best, "b": beta, "r": radius, "t": target}


func enter_cut(pose: Dictionary, hold := false) -> void:
	_cut_return_elapsed = CUT_RETURN_S
	_set_cut_pose(pose)
	slow_until = _clock + 1.2 if hold else _clock


func return_from_cut(pose: Dictionary) -> void:
	_cut_return = Vector3(_ca, _cb, _cr)
	_cut_return_target = _ct
	_cut_return_elapsed = 0.0
	_set_cut_pose(pose)
	slow_until = _clock


func _set_cut_pose(pose: Dictionary) -> void:
	a = pose["a"]
	b = pose["b"]
	r = pose["r"]
	t = pose["t"]


func focus(p: Vector3, rr := -1.0) -> void:
	t = p
	if rr > 0.0:
		r = rr


# F1: a slow glide to a point or ship above the board (the next ship handed over, a reinforcement arriving): the target moves
# there with the camera's slow easing for dur seconds; the zoom is kept unless rr is given (then only pulled in, never out)
func glide(p: Vector3, dur := 1.1, rr := -1.0) -> void:
	t = Vector3(clampf(p.x, -bounds.x, bounds.x), p.y, clampf(p.z, -bounds.y, bounds.y))
	if rr > 0.0 and rr < r:
		r = rr
	slow_until = _clock + dur


# true when a board point falls inside a part of the screen given as fractions (x0, y0, x1, y1), for framing a view
# inside the part the HUD panels leave clear
func sees_in(p: Vector3, x0: float, y0: float, x1: float, y1: float) -> bool:
	if is_position_behind(p):
		return false
	var vs := get_viewport().get_visible_rect().size
	var sp := unproject_position(p)
	return sp.x > vs.x * x0 and sp.x < vs.x * x1 and sp.y > vs.y * y0 and sp.y < vs.y * y1


# true when a board point is well inside the view (so a hand-over needs no glide)
func sees(p: Vector3, margin := 0.22) -> bool:
	if is_position_behind(p):
		return false
	var vs := get_viewport().get_visible_rect().size
	var sp := unproject_position(p)
	return sp.x > vs.x * margin and sp.x < vs.x * (1.0 - margin) and sp.y > vs.y * margin and sp.y < vs.y * (1.0 - margin)


func toggle_top() -> void:
	if topdown:
		b = prev_b
		topdown = false
	else:
		prev_b = b
		b = 0.05
		topdown = true


func pan_by(dx: float, dz: float) -> void:
	var s := r / 340.0
	# screen-up on the board, given the camera's azimuth (mirrored z)
	var fwd := Vector3(-cos(a), 0, sin(a))
	var right := Vector3(-sin(a), 0, -cos(a))
	t += right * (dx * s) + fwd * (dz * s)
	t.x = clampf(t.x, -bounds.x, bounds.x)
	t.z = clampf(t.z, -bounds.y, bounds.y)


func orbit(dx: float, dy: float) -> void:
	a -= dx * 0.0055
	b = clampf(b - dy * 0.0045, 0.05, 1.36)
	topdown = false


# Issue 2029 item 6: a wheel step zooms about the board point under the pointer, not about the screen's middle. The factor,
# the limits (min_r to 900) and the easing are today's; only the orbit target t moves, by the amount that puts the point
# under the pointer (on the plane through the target) back under it at the new distance. Over empty sky, where the pointer
# ray never reaches that plane, it is the plain zoom about the target.
func zoom_at(screen_pos: Vector2, factor: float) -> void:
	var new_r := clampf(r * factor, min_r, 900.0)
	if is_equal_approx(new_r, r):
		r = new_r
		return
	# Both trial poses use the target angles (a, b), so an orbit still easing is not turned into a pan jump: only the
	# distance and the target differ between the two points.
	var anchor = _plane_hit(screen_pos, a, b, _cr, _ct, t.y)   # the point the player sees under the pointer now
	r = new_r
	if anchor == null:
		_apply()
		return
	var after = _plane_hit(screen_pos, a, b, new_r, t, t.y)   # where the same pixel will land once the zoom settles
	if after != null:
		var nt: Vector3 = t + ((anchor as Vector3) - (after as Vector3))
		t.x = clampf(nt.x, -bounds.x, bounds.x)
		t.z = clampf(nt.z, -bounds.y, bounds.y)
	_apply()   # put the live pose back after the trial poses


# The board point (on the plane y = plane_y) under a pixel for a camera pose (angles, distance, target), or null when that
# pixel looks at or above the horizon, or grazes the plane so far out that the hit lies beyond HIT_MARGIN times the board
# bounds (a wheel click over distant sky then falls back to the plain zoom, not a slam to the map edge). Poses the camera briefly; the caller calls _apply() to restore the live one.
func _plane_hit(screen_pos: Vector2, pa: float, pb: float, pr: float, pt: Vector3, plane_y: float) -> Variant:
	if not is_inside_tree():
		return null
	_set_pose(pa, pb, pr, pt, Vector3.ZERO)
	var o := project_ray_origin(screen_pos)
	var d := project_ray_normal(screen_pos)
	if d.y > -0.02:
		return null
	var hit := o + d * ((plane_y - o.y) / d.y)
	if absf(hit.x) > bounds.x * HIT_MARGIN or absf(hit.z) > bounds.y * HIT_MARGIN:
		return null
	return hit


# returns true when the event was a drag the camera used (so a click is not fired at the end of it)
func handle_input(e: InputEvent) -> bool:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and not e.pressed:
		if _drag == 2:
			_drag = 0
			_drag_moved = 0.0
		return false
	if not input_enabled:
		return false
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, exp(-120.0 * 0.0011))
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, exp(120.0 * 0.0011))
			return true
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_drag = 2
			_drag_moved = 0.0
			return false
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag = 1
				_drag_moved = 0.0
			else:
				var was := _drag_moved
				_drag = 0
				return was > 6.0
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _drag == 2:
			orbit(mm.relative.x, mm.relative.y)
			_drag_moved += mm.relative.length()
		elif _drag == 1:
			_drag_moved += mm.relative.length()
			if _drag_moved > 6.0:
				pan_by(-mm.relative.x, mm.relative.y)
	return false


# Poll held physical keys, independent of GUI focus and the OS repeat delay.
# Text fields and modified shortcuts keep their keys. Ordinary buttons may keep focus.
static func keyboard_pan(viewport: Viewport, arrows := true) -> Vector2:
	if DisplayServer.get_name() != "headless" and not viewport.get_window().has_focus():
		return Vector2.ZERO
	# issue 1559 (Artoo on PR 1601): an open modal overlay (the battle menu, Career, a drawer) has the keyboard, so held
	# WASD and arrows move its focus, never the camera behind it
	if load("res://ui/theme/modal_focus.gd").any_open():
		return Vector2.ZERO
	var owner := viewport.gui_get_focus_owner()
	if owner is LineEdit or owner is TextEdit or Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_ALT) or Input.is_key_pressed(KEY_META):
		return Vector2.ZERO
	var p := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or (arrows and Input.is_physical_key_pressed(KEY_UP)):
		p.y += 1.0
	if Input.is_physical_key_pressed(KEY_S) or (arrows and Input.is_physical_key_pressed(KEY_DOWN)):
		p.y -= 1.0
	if Input.is_physical_key_pressed(KEY_A) or (arrows and Input.is_physical_key_pressed(KEY_LEFT)):
		p.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or (arrows and Input.is_physical_key_pressed(KEY_RIGHT)):
		p.x += 1.0
	return p.limit_length(1.0)


static func is_pan_key(e: InputEventKey) -> bool:
	var k := e.physical_keycode if e.physical_keycode != 0 else e.keycode
	return not (e.ctrl_pressed or e.alt_pressed or e.meta_pressed) and k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]


func _process(dt: float) -> void:
	_clock += dt
	if input_enabled and keyboard_enabled and is_visible_in_tree():
		var p := keyboard_pan(get_viewport())
		if p != Vector2.ZERO:
			pan_by(p.x * dt * 300.0, p.y * dt * 300.0)
	r = maxf(r, min_r)
	if _cut_return_elapsed < CUT_RETURN_S:
		_cut_return_elapsed = minf(_cut_return_elapsed + dt, CUT_RETURN_S)
		var f := smoothstep(0.0, CUT_RETURN_S, _cut_return_elapsed)
		_ca = _cut_return.x + angle_difference(_cut_return.x, a) * f
		_cb = lerpf(_cut_return.y, b, f)
		_cr = lerpf(_cut_return.z, r, f)
		_ct = _cut_return_target.lerp(t, f)
		if _cut_return_elapsed >= CUT_RETURN_S:
			_ca = a   # same rendered angle, with the board's original turn count
	else:
		var f := 1.0 - exp(-dt * (1.7 if _clock < slow_until else 7.0))
		_ca += (a - _ca) * f
		_cb += (b - _cb) * f
		_cr += (r - _cr) * f
		_ct += (t - _ct) * f
	_apply()
	_step_close_dof(dt)


func _apply() -> void:
	# Issue 368: fixed zoom bands reserve froxels for the board.
	if OS.get_environment("VS_NEBULA_ROUTE") != "today":
		near = 15.0 if _cr >= 100.0 else (5.0 if _cr >= 45.0 else 1.0)
	far = far_for(_cr, _ct + shake, bounds)
	if current:
		RenderingServer.global_shader_parameter_set(NEAR_GLOBAL, near)
	# Keep the far side of a cloud in range as the player zooms out.
	var env := get_world_3d().environment if is_inside_tree() else null
	if env != null and env.volumetric_fog_enabled and OS.get_environment("VS_NEBULA_ROUTE") != "today":
		env.volumetric_fog_length = maxf(250.0, _cr + 200.0)
	var p := _set_pose(_ca, _cb, _cr, _ct, shake)
	var tg := _ct + shake
	if current:
		RenderingServer.global_shader_parameter_set(EYE_GLOBAL, Vector4(p.x, p.y, p.z, 1.0))
		RenderingServer.global_shader_parameter_set(FWD_GLOBAL, (tg - p).normalized())
	if pose_applied.has_connections():
		pose_applied.emit()


# Place the camera for a pose (angles, distance, target) and its screen shift; returns the eye. The one copy of the
# placement, so _apply and the zoom-to-pointer trial poses cannot drift apart.
func _set_pose(pa: float, pb: float, pr: float, pt: Vector3, shake_v: Vector3) -> Vector3:
	var tg := pt + shake_v
	var p := tg + Vector3(cos(pa) * sin(pb), cos(pb), -sin(pa) * sin(pb)) * pr
	var up := Vector3.UP if pb > 0.02 else Vector3(-cos(pa), 0, sin(pa))
	look_at_from_position(p, tg, up)
	# a sideways shift of the camera in its own plane moves the target right on screen by screen_shift pixels at its
	# distance (the field of view is vertical, so half the window height spans tan(fov / 2) * distance)
	var vh := get_viewport().get_visible_rect().size.y if is_inside_tree() else 1080.0
	h_offset = -screen_shift / maxf(vh * 0.5, 1.0) * pr * tan(deg_to_rad(fov) * 0.5) + shake_offset.x
	v_offset = shake_offset.y
	return p
