extends Node
# The game slice (--board): filled in after the fix round.
var click_frames := -1
func setup(_vp: SubViewport, _world: Node3D, _cam: Camera3D, _ships: Array, _res: Vector2i, _hex: float, _scripted: bool) -> void:
	pass
func update(_t: float, _mouse: Vector2) -> void:
	pass
func camera_pose() -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3(0, -140, 100), Vector3.UP), Vector3(0, 140, -100))
func mouse_from_window(p: Vector2, _win: Vector2i) -> Vector2:
	return p
func scripted_mouse(_t: float) -> Vector2:
	return Vector2(-1, -1)
