extends Node3D
# Refs #863. Bounded slow tumble, no collision objects or changes to terrain.
const POSE_INTERVAL := 1.0 / 12.0
var _pieces: Array = []
var _time := 0.0
var _next_pose := 0.0

func keep_outside(blocked_radius: float) -> void:
	# Push the whole group along the damaged arm only when the live cells need it.
	# Full tumble spheres keep this valid for every phase and station bearing.
	var push := 0.0
	for child in find_children("T2_debris_*", "MeshInstance3D", true, false):
		var p: Vector3 = child.position
		var limit := blocked_radius + float(child.get_meta("debris_radius")) + 0.5
		var gap := sqrt(maxf(0.0, limit * limit - p.x * p.x)) - p.z
		push = maxf(push, gap)
	position.z = push

func _ready() -> void:
	for child in find_children("T2_debris_*", "MeshInstance3D", true, false):
		# The field is below the flight plane and detached from the station.
		child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var axis: Array = child.get_meta("debris_axis")
		# glTF converts Blender Z up to Godot Y up; custom extras need the same turn.
		_pieces.append({"node":child,"rest":child.basis,
			"axis":Vector3(axis[0],axis[2],-axis[1]).normalized(),
			"rate":float(child.get_meta("debris_rate"))})

func pose_at(seconds: float) -> void:
	for piece in _pieces:
		piece.node.basis = Basis(piece.axis, fmod(seconds * piece.rate, TAU)) * piece.rest

func _process(dt: float) -> void:
	_time += dt
	# Even at camera 60, the slowest update spacing moves an edge under a pixel.
	if _time < _next_pose:
		return
	pose_at(_time)
	_next_pose = _time + POSE_INTERVAL
