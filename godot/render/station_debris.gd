extends Node3D
# Refs #863. Bounded slow tumble, no collision objects or changes to terrain.
var _pieces: Array = []
var _time := 0.0

func _ready() -> void:
	for child in find_children("T2_debris_*", "MeshInstance3D", true, false):
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
	pose_at(_time)
