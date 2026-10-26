extends Camera3D
# The game's RTS camera (scene3d.js CamCtl): orbit about a target on the board plane, smoothed.
# Right-drag orbits, left-drag or WASD / arrow keys pan, the wheel zooms, T toggles top-down, Home resets, F focuses.
# Angles as in the game's Babylon ArcRotateCamera (alpha around, beta down from straight up), with the world's z mirrored
# (Godot is right-handed, the game's Babylon scene left-handed), so the board looks the same way round.

var a := -PI / 2.0
var b := 0.86
var r := 215.0
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
var slow_until := 0.0
var _clock := 0.0
var shake := Vector3.ZERO


func _ready() -> void:
	fov = 45.0
	near = 0.5
	far = 5000.0
	_apply()


func reset_view() -> void:
	a = -PI / 2.0
	b = 0.86
	r = 215.0
	t = home
	topdown = false


func snap() -> void:
	_ca = a
	_cb = b
	_cr = r
	_ct = t
	_apply()


func focus(p: Vector3, rr := -1.0) -> void:
	t = Vector3(p.x, 0, p.z)
	if rr > 0.0:
		r = rr


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


func _process(dt: float) -> void:
	_clock += dt
	if input_enabled:
		var px := 0.0
		var pz := 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			pz += 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			pz -= 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			px -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			px += 1.0
		if px != 0.0 or pz != 0.0:
			pan_by(px * dt * 300.0, pz * dt * 300.0)
	r = maxf(r, min_r)
	var f := 1.0 - exp(-dt * (1.7 if _clock < slow_until else 7.0))
	_ca += (a - _ca) * f
	_cb += (b - _cb) * f
	_cr += (r - _cr) * f
	_ct += (t - _ct) * f
	_apply()


func _apply() -> void:
	var tg := _ct + shake
	var p := tg + Vector3(cos(_ca) * sin(_cb), cos(_cb), -sin(_ca) * sin(_cb)) * _cr
	var up := Vector3.UP if _cb > 0.02 else Vector3(-cos(_ca), 0, sin(_ca))
	look_at_from_position(p, tg, up)
