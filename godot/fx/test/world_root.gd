# Issues 1309 and 1355: the one way a check hands a loaded ship to fx. The game roots fx at ShipView, an unscaled node in
# world units with the scaled hull under it; a check does the same. Rooted at the glb scene itself, the analysis runs in
# the file's own frame (an export7 ship is about one unit long), where Godot's TriangleMesh hit test misses the small
# triangles: CD5 r5d's optic seat read as clear and its inside triangles as outside the ship.
const MIN_L := 2.0   # a world-size hull is longer than this (the smallest class, Squadron, is longer); a file-size one is about 1


# The ship's class length its export wrote (length_world), else fallback.
static func length_of(scene: Node3D, fallback := 26.0) -> float:
	for nd in [scene] + scene.find_children("*", "Node3D", true, false):
		var ex = nd.get_meta("extras", {})
		if ex is Dictionary and ex.has("length_world"):
			return float(ex["length_world"])
	return fallback


# Puts scene under a new unscaled node in world (or under holder, when given) and scales scene to length along x, or by
# scale when it is above 0. Returns the node to pass to fx.add_ship.
static func hold(world: Node, scene: Node3D, length := -1.0, scale := -1.0, holder: Node3D = null) -> Node3D:
	if holder == null:
		holder = Node3D.new()
		holder.name = String(scene.name) + "_root"
		world.add_child(holder)
	if scene.get_parent() != null:
		scene.get_parent().remove_child(scene)
	holder.add_child(scene)
	scene.scale = Vector3.ONE
	if scale > 0.0:
		scene.scale = Vector3.ONE * scale
		return holder
	if length <= 0.0:
		length = length_of(scene)
	var box := AABB()
	var first := true
	for mi in scene.find_children("*", "MeshInstance3D", true, false) + ([scene] if scene is MeshInstance3D else []):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		var bb: AABB = (holder.global_transform.affine_inverse() * m.global_transform) * m.mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	scene.scale = Vector3.ONE * (length / maxf(box.size.x, 0.0001))
	return holder


# The check every caller runs once fx has the ship: its hull was analysed at world size.
static func world_sized(s: Object) -> bool:
	return s != null and float(s.hull.L) > MIN_L
