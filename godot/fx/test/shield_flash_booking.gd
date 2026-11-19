extends SceneTree

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var failures := 0


func _initialize() -> void:
	GUARD.arm(self, "shield_flash_booking")
	_run.call_deferred()


func _run() -> void:
	for mode in ["normal", "budget full", "reduced"]:
		_check_crackle(mode)
	quit(0 if failures == 0 else 1)


func _check_crackle(mode: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.fov = 45.0
	viewport.add_child(camera)
	var fx := FX.new()
	fx.manual = true
	fx.camera = camera
	viewport.add_child(fx)
	var pool := POOLS.Pool.new(16, StandardMaterial3D.new(), fx, "test_glow", POOLS.quad_shape())
	fx.pools["spr"] = pool
	var p := Vector3(0, 0, -170)
	var n := Vector3.RIGHT
	var when := 0.1
	var px := 110.0 # One cruiser torpedo crackle is smaller than the area limit.
	if mode == "budget full":
		px = 180.0
		for t in [0.0, 0.24, 0.48]:
			fx.flash_at(p, t, 0.0, px)
		when = 0.72
	fx.reduce_flashing = mode == "reduced"
	fx.flash_area_logging = true
	var counted_before := fx.flash_log.size()
	WEAP._shield_crackle(fx, p, n, when, 1.0, Color.WHITE, px, 0, true)
	var requests := fx.flash_area_log.size()
	var counted := fx.flash_log.size() - counted_before
	var power: float = pool.pending[15] if pool.n_pending == 1 else -1.0
	var ok := pool.emitted == 1 and counted == 0 and is_equal_approx(power, 4.2 if mode == "normal" else 1.25)
	if mode == "reduced":
		ok = ok and requests == 0
	else:
		ok = ok and requests == 1
		if requests == 1:
			var row: Array = fx.flash_area_log[0]
			var centre := camera.unproject_position(p + n * 0.15)
			ok = ok and Vector2(row[1], row[2]).is_equal_approx(centre) and is_equal_approx(row[3], px)
			ok = ok and int(row[6]) == (1 if mode == "normal" else 0)
	if not ok:
		failures += 1
	print("%s shield torpedo flash (%s): %d bookings, %d counted, %d sprites, %.2f power" % [
		"PASS" if ok else "FAIL", mode, requests, counted, pool.emitted, power])
	viewport.free()
