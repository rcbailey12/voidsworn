extends SceneTree


func _initialize() -> void:
	root.add_child.call_deferred(preload("res://bench/perf_1118.gd").new())
