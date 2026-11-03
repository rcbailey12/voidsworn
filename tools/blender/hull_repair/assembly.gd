extends RefCounted
# Native AI meshes share their GPU buffers between mirrored guns and ships.
static var cache: Dictionary = {}


static func add_parts(ship: Node3D, work: String, route: String) -> void:
	var metadata := work.path_join("C19_51/"+route+"/build.json")
	if not FileAccess.file_exists(metadata):return
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(metadata))
	for part in data.get("native_instances",[]):
		var path: String=part["path"]
		if not cache.has(path):
			var doc:=GLTFDocument.new();var state:=GLTFState.new()
			assert(doc.append_from_file(path,state)==OK,"Native AI part failed to load")
			cache[path]=doc.generate_scene(state)
		var node: Node3D=cache[path].duplicate()
		node.position=Vector3(part["position"][0],part["position"][1],part["position"][2])
		node.rotation.y=float(part["yaw"])
		ship.add_child(node)


static func clear_static() -> void:
	for node in cache.values():node.free()
	cache.clear()
