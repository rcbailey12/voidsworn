extends SceneTree

const FX := preload("res://fx/fx.gd")

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

	# Put the entire billboard inside the view, near a corner. Project both
	# ends at the same view depth, as the billboard vertex shader does.
	var p := Vector3(51.2, 26.4, -80.0)
	var extent := 2.0 * -p.z * tan(deg_to_rad(camera.fov) * 0.5) * 151.0 / viewport.size.y
	var edge := Vector3.RIGHT * extent * 0.5
	var left := camera.unproject_position(p - edge)
	var right := camera.unproject_position(p + edge)
	var shown := right.distance_to(left)
	var area := PI * pow(shown * 0.5, 2.0)
	var limit := fx.flash_limit_px2()
	var booked := float(fx._flash_disc(p, extent, 0.0)[2])
	if not viewport.get_visible_rect().has_point(left) or not viewport.get_visible_rect().has_point(right) or area <= limit:
		print("ERROR: fixture must show a full disc above the area limit")
		viewport.free()
		quit(2)
		return
	var bright := 0
	for t in [0.0, 0.2, 0.4, 0.6]:
		if fx.flash_at(p, t, extent, 0.0, 0.12):
			bright += 1
	var ok := bright == 3
	print("%s flash projection: %.1f px shown, %.0f px booked, %.0f px2 shown, %.0f px2 limit, %d bright in one second (expected 3)" % ["PASS" if ok else "FAIL", shown, booked, area, limit, bright])
	viewport.free()
	quit(0 if ok else 1)
