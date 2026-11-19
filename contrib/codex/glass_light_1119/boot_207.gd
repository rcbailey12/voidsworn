extends SceneTree


func _initialize() -> void:
	root.add_child.call_deferred(preload("scene_207.gd").new())
