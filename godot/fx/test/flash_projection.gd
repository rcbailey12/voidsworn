extends SceneTree

const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var failures := 0


func _initialize() -> void:
	GUARD.arm(self, "flash_projection")
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
	fx.flash_area_logging = true

	# The audit's equal-depth centre and corner, with the entire disc in view.
	_measure(fx, camera, "centre, no floor", Vector3(0, 0, -80), 9.25, 0.0, 0.0)
	var edge := Vector3(51.2, 26.4, -80)
	_measure(fx, camera, "edge, no floor", edge, 9.25, 0.0, 0.0)
	_measure(fx, camera, "edge, world size wins", edge, 9.25, 110.0, 1.0)
	_measure(fx, camera, "edge, floor wins", edge, 2.0, 151.0, 1.0)
	for t in [0.0, 0.2, 0.4, 0.6]:
		fx.flash_at(edge, t, 9.25, 0.0, 0.12)
	var bright := 0
	for row in fx.flash_area_log:
		bright += int(row[6])
	_result(bright == 3, "edge flash cap: %d bright in one second (expected 3)" % bright)

	# Check the projection matrix, not just the default vertical perspective FOV.
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	_measure(fx, camera, "horizontal FOV", camera.project_position(Vector2(1590, 240), 80.0), 4.5, 0.0, 0.0)
	camera.set_orthogonal(90.0, 0.05, 400.0)
	_measure(fx, camera, "orthographic", camera.project_position(Vector2(1590, 240), 140.0), 7.0, 110.0, 1.0)
	viewport.free()
	quit(0 if failures == 0 else 1)


func _measure(fx: Node, camera: Camera3D, label: String, p: Vector3, extent: float, px: float, floor_scale: float) -> void:
	fx.min_px = floor_scale
	var centre := camera.unproject_position(p)
	var half_width := camera.get_camera_transform().basis.x * extent * 0.5
	var width := camera.unproject_position(p - half_width).distance_to(camera.unproject_position(p + half_width))
	var view := camera.get_viewport().get_visible_rect()
	var shown := maxf(width, px * floor_scale * view.size.y / 1080.0)
	var half_disc := Vector2.ONE * shown * 0.5
	var disc: PackedFloat64Array = fx._flash_disc(p, extent, px)
	var booked := disc[2] if disc.size() == 3 else -1.0
	var same_centre := disc.size() == 3 and Vector2(disc[0], disc[1]).is_equal_approx(centre)
	_result(same_centre and view.has_point(centre - half_disc) and view.has_point(centre + half_disc)
			and booked >= shown - 0.01 and booked < shown + 1.01,
			"flash projection (%s): %.2f px shown, %.0f px booked" % [label, shown, booked])


func _result(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)
