extends Camera3D
# The game's RTS camera (scene3d.js CamCtl): orbit about a target on or above the board, smoothed.
# Right-drag orbits, left-drag or WASD / arrow keys pan, the wheel zooms, T toggles top-down, Home resets, F focuses.
# Angles as in the game's Babylon ArcRotateCamera (alpha around, beta down from straight up), with the world's z mirrored
# (Godot is right-handed, the game's Babylon scene left-handed), so the board looks the same way round.

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
# issue 271 (E1 LEDGER): pixels to move the board's centre to the right of the screen's middle, so the point the camera
# looks at sits in the middle of the part the orders sheet leaves clear (hud.gd clear_shift). 0 keeps it centred.
var screen_shift := 0.0


# Issue 1264: the far plane follows the zoom and pan, so the backdrop system is never cut off. The worst case from the
# board centre is a giant planet's ring: world.gd DIST 3300 + 2.3 ring radii of 3300 * sin(0.18) = 4659 units (moons
# reach 1.15 * 3300 * (1 + sin(0.04)) = 3947, mountains about 2620). A camera r units out, looking at t (inside bounds),
# is at most r + |t| from the board origin, and the board centre is at most |bounds| from the origin; depth never
# exceeds straight-line distance. godot/world/test/backdrop_clip_check.gd builds ringed giants and holds this to the
# real meshes. Shadows (directional_shadow_max_distance 600) and volumetric fog (its own length) do not key off far.
const BACKDROP_REACH := 4700.0
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
	_ca = a
	_cb = b
	_cr = r
	_ct = t
	_apply()


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


# returns true when the event was a drag the camera used (so a click is not fired at the end of it)
func handle_input(e: InputEvent) -> bool:
	if not input_enabled:
		return false
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			r = clampf(r * exp(-120.0 * 0.0011), min_r, 900.0)
			return true
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			r = clampf(r * exp(120.0 * 0.0011), min_r, 900.0)
			return true
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_drag = 2 if mb.pressed else 0
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
	var f := 1.0 - exp(-dt * (1.7 if _clock < slow_until else 7.0))
	_ca += (a - _ca) * f
	_cb += (b - _cb) * f
	_cr += (r - _cr) * f
	_ct += (t - _ct) * f
	_apply()


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
	var tg := _ct + shake
	var p := tg + Vector3(cos(_ca) * sin(_cb), cos(_cb), -sin(_ca) * sin(_cb)) * _cr
	var up := Vector3.UP if _cb > 0.02 else Vector3(-cos(_ca), 0, sin(_ca))
	look_at_from_position(p, tg, up)
	if current:
		RenderingServer.global_shader_parameter_set(EYE_GLOBAL, Vector4(p.x, p.y, p.z, 1.0))
		RenderingServer.global_shader_parameter_set(FWD_GLOBAL, (tg - p).normalized())
	# a sideways shift of the camera in its own plane moves the target right on screen by screen_shift pixels at its
	# distance (the field of view is vertical, so half the window height spans tan(fov / 2) * distance)
	var vh := get_viewport().get_visible_rect().size.y if is_inside_tree() else 1080.0
	h_offset = -screen_shift / maxf(vh * 0.5, 1.0) * _cr * tan(deg_to_rad(fov) * 0.5)
