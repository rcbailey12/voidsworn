extends SceneTree

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const POOLS := preload("res://fx/fx_pool.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
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
	fx.pools["spr"] = POOLS.Pool.new(16, StandardMaterial3D.new(), fx, "test_glow", POOLS.quad_shape())
	fx.flash_area_logging = true

	# A cruiser torpedo's 110 px crackle is below the threshold at this
	# camera distance. No other effect is allowed to contribute area.
	WEAP._shield_crackle(fx, Vector3(0, 0, -170), Vector3.BACK, 0.1, 1.0, Color.WHITE, 110.0, 0, true)
	var requests: int = fx.flash_area_log.size()
	var counted: int = fx.flash_log.size()
	var ok := requests == 1 and counted == 0
	print("%s shield torpedo flash: %d bookings, %d counted (expected 1 booking, 0 counted)" % ["PASS" if ok else "FAIL", requests, counted])
	viewport.free()
	quit(0 if ok else 1)
