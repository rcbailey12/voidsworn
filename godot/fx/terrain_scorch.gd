extends RefCounted
# Issue 1779. Forward+ terrain dressing. This layer belongs only to marked receivers, including animated station parts.
const RECEIVER := 1 << 17
const SAMPLE_OFFSETS := [Vector2(0.12, 0.19), Vector2(-0.27, 0.10), Vector2(0.20, -0.23), Vector2.ZERO]
static var _albedo: Texture2D
static var _plasma: Texture2D


static func clear_static() -> void:
	_albedo = null
	_plasma = null


static func surface_hit(mesh: Mesh, pose: Transform3D) -> Dictionary:
	var triangles := mesh.generate_triangle_mesh()
	if triangles == null:
		return {}
	var bounds := pose * mesh.get_aabb()
	var inv := pose.affine_inverse()
	for offset in SAMPLE_OFFSETS:
		var from := bounds.get_center() + Vector3(offset.x * bounds.size.x, bounds.size.y * 0.5 + 0.5, offset.y * bounds.size.z)
		var hit := triangles.intersect_segment(inv * from, inv * (from - Vector3.UP * (bounds.size.y + 1.0)))
		if hit.is_empty():
			continue
		var normal := (pose.basis.inverse().transposed() * (hit["normal"] as Vector3)).normalized()
		if normal.dot(Vector3.UP) < 0.0:
			normal = -normal
		if normal.y > 0.3:
			return {"position": pose * (hit["position"] as Vector3), "normal": normal}
	return {}


static func stamp(parent: Node3D, hit: Dictionary, width: float, plasma: bool) -> Decal:
	if hit.is_empty():
		return null
	if _albedo == null:
		_make_textures()
	var normal: Vector3 = hit["normal"]
	var tangent := Vector3.RIGHT if absf(normal.x) < 0.8 else Vector3.FORWARD
	tangent = tangent.slide(normal).normalized()
	var mark := Decal.new()
	mark.name = "PlasmaBurn" if plasma else "Scorch"
	mark.cull_mask = RECEIVER
	mark.size = Vector3(width, width * 0.52, width * 0.72)
	mark.upper_fade = 0.4
	mark.lower_fade = 0.45
	mark.normal_fade = 0.5
	mark.texture_albedo = _albedo
	if plasma:
		mark.texture_emission = _plasma
		mark.emission_energy = 0.22
	parent.add_child(mark)
	mark.global_transform = Transform3D(Basis(tangent, normal, tangent.cross(normal)), hit["position"])
	return mark


static func station(root: Node3D) -> void:
	var meshes: Array[MeshInstance3D] = []
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var receiver := child as MeshInstance3D
		if receiver.mesh != null and not str(receiver.get_path()).contains("/station_T2_debris/"):
			meshes.append(receiver)
	meshes.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D) -> bool:
		return (a.global_transform * a.get_aabb()).size.length_squared() > (b.global_transform * b.get_aabb()).size.length_squared())
	var marked := 0
	for receiver in meshes:
		var hit := surface_hit(receiver.mesh, receiver.global_transform)
		if hit.is_empty():
			continue
		var width := clampf((receiver.global_transform * receiver.get_aabb()).size.length() * 0.22, 2.0, 5.0)
		receiver.layers |= RECEIVER
		stamp(receiver, hit, width, marked % 2 == 1)
		marked += 1
		if marked == 3:
			break


static func _make_textures() -> void:
	var albedo := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	var plasma := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / 32.0 - Vector2.ONE
			var theta := uv.angle()
			var edge := uv.length() * (1.0 + 0.13 * sin(7.0 * theta) + 0.07 * cos(13.0 * theta))
			var opacity := 0.78 * (1.0 - smoothstep(0.12, 0.88, edge))
			var grain := 0.88 + 0.12 * sin(float(x * 19 + y * 37))
			albedo.set_pixel(x, y, Color(0.105, 0.078, 0.065, opacity * grain))
			var heat := (1.0 - smoothstep(0.04, 0.16, absf(edge - 0.34))) * grain
			plasma.set_pixel(x, y, Color(0.08 * heat, 0.22 * heat, 0.35 * heat, 1.0))
	_albedo = ImageTexture.create_from_image(albedo)
	_plasma = ImageTexture.create_from_image(plasma)
