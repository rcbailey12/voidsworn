extends RefCounted
# Issue 1779 & Issue 2048. Forward+ terrain dressing. This layer belongs only to marked receivers, including animated station parts.
# 256x256 multi-layered crater/char albedo, tangent-space normal, ORM (AO/roughness/metallic) and light-blue plasma vein emission.
const RECEIVER := 1 << 17
const TEX_SIZE := 256
const SAMPLE_OFFSETS := [Vector2(0.12, 0.19), Vector2(-0.27, 0.10), Vector2(0.20, -0.23), Vector2.ZERO]
static var _albedo: Texture2D
static var _normal: Texture2D
static var _orm: Texture2D
static var _plasma: Texture2D


static func clear_static() -> void:
	_albedo = null
	_normal = null
	_orm = null
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
	mark.texture_normal = _normal
	mark.texture_orm = _orm
	if plasma:
		mark.texture_emission = _plasma
		mark.emission_energy = 0.34
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


static func _hash2(ix: int, iy: int) -> float:
	var h := (ix * 374761393 + iy * 668265263) ^ ((ix * 1274126177) >> 13)
	h = (h * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


static func _vnoise(x: float, y: float) -> float:
	var ix := int(floor(x))
	var iy := int(floor(y))
	var fx := x - float(ix)
	var fy := y - float(iy)
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	var a := _hash2(ix, iy)
	var b := _hash2(ix + 1, iy)
	var c := _hash2(ix, iy + 1)
	var d := _hash2(ix + 1, iy + 1)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy)


static func _make_textures() -> void:
	var n := TEX_SIZE
	var inv_half := 2.0 / float(n)
	var heights := PackedFloat32Array()
	heights.resize(n * n)
	var albedo_bytes := PackedByteArray()
	albedo_bytes.resize(n * n * 4)
	var orm_bytes := PackedByteArray()
	orm_bytes.resize(n * n * 4)
	var plasma_bytes := PackedByteArray()
	plasma_bytes.resize(n * n * 4)

	# Pass 1: build crater heightfield, multi-layered carbonized albedo, ORM, and light-blue plasma fracture veins.
	for y in n:
		var vy := (float(y) + 0.5) * inv_half - 1.0
		for x in n:
			var vx := (float(x) + 0.5) * inv_half - 1.0
			var r := sqrt(vx * vx + vy * vy)
			var theta := atan2(vy, vx)
			# Multi-octave value noise for jagged rim, ejecta streaks, and gritty surface micro-relief.
			var n_coarse := _vnoise(vx * 3.8 + 7.1, vy * 3.8 + 4.3)
			var n_fine := _vnoise(vx * 11.5 + 19.3, vy * 11.5 + 13.7)
			var n_grit := _vnoise(vx * 28.0 + 3.7, vy * 28.0 + 29.1)
			var fbm_val := n_coarse * 0.58 + n_fine * 0.28 + n_grit * 0.14
			# Radial blast-ejecta rays fanning out from impact center.
			var ray_sig := 0.5 + 0.5 * sin(theta * 9.0 + n_coarse * 2.2) * cos(theta * 5.0 - n_fine * 1.8)
			var ray_sharp := ray_sig * ray_sig
			# Irregular crater radius: warped boundary so it never reads as a smooth circle.
			var warp := 1.0 + 0.14 * sin(5.0 * theta + 0.4) + 0.09 * cos(11.0 * theta - 0.9) + (fbm_val - 0.5) * 0.32
			var edge := r * warp
			# Heightfield: deep concave pit inside edge < 0.36, raised chipped crater rim around 0.40, radial gouges outside.
			var pit := -0.78 * (1.0 - smoothstep(0.06, 0.40, edge))
			var rim := 0.36 * exp(-pow((edge - 0.42) / 0.11, 2.0)) * (0.65 + 0.7 * n_fine)
			var gouge := -0.14 * ray_sharp * smoothstep(0.28, 0.55, edge) * (1.0 - smoothstep(0.55, 0.92, edge))
			var micro := (n_grit - 0.5) * 0.16 * (1.0 - smoothstep(0.55, 0.96, r))
			heights[y * n + x] = pit + rim + gouge + micro

			# Layered albedo: deep carbonized core + charred crater lip + streaky soot ejecta rays, smooth zero edge at r>=0.98.
			var edge_fade := 1.0 - smoothstep(0.76, 0.98, r)
			var core_mask := 1.0 - smoothstep(0.14, 0.46, edge)
			var soot_halo := (1.0 - smoothstep(0.20, 0.90, edge - ray_sharp * 0.14)) * (0.62 + 0.38 * fbm_val)
			var alpha := clampf((core_mask * 0.88 + soot_halo * 0.62) * edge_fade, 0.0, 0.94)
			var char_tone := lerpf(0.032, 0.115, smoothstep(0.10, 0.65, edge)) * (0.78 + 0.34 * n_grit)
			var ash_tint := 0.025 * rim * (0.5 + n_fine)
			var idx := (y * n + x) * 4
			albedo_bytes[idx] = int(clampf((char_tone * 1.12 + ash_tint) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 1] = int(clampf((char_tone * 0.94 + ash_tint * 0.92) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 2] = int(clampf((char_tone * 0.86 + ash_tint * 0.88) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 3] = int(clampf(alpha * 255.0, 0.0, 255.0))

			# ORM: R=AO (dark inside crater pit), G=Roughness (matte carbonized soot, slightly glassy rim), B=Metallic.
			var ao := clampf(1.0 - core_mask * 0.72 - rim * 0.20, 0.18, 1.0)
			var rough := clampf(lerpf(0.94, 0.48, rim * 0.85) - (n_grit - 0.5) * 0.08, 0.35, 0.98)
			var metal := clampf(rim * 0.24, 0.0, 0.35)
			orm_bytes[idx] = int(ao * 255.0)
			orm_bytes[idx + 1] = int(rough * 255.0)
			orm_bytes[idx + 2] = int(metal * 255.0)
			orm_bytes[idx + 3] = 255

			# Light-blue plasma-melt emission (RULEBOOK 6.13): glowing fracture veins inside pit + fractured hot rim.
			var vein_f := 1.0 - absf(_vnoise(vx * 9.0 + n_coarse * 1.8 + 4.2, vy * 9.0 + n_fine * 1.4 + 8.6) * 2.0 - 1.0)
			var vein := pow(clampf(vein_f, 0.0, 1.0), 6.0) * (1.0 - smoothstep(0.18, 0.62, edge))
			var rim_glow := exp(-pow((edge - 0.38) / 0.075, 2.0)) * (0.45 + 0.55 * ray_sharp) * (0.65 + 0.35 * n_fine)
			var heat := clampf((vein * 1.35 + rim_glow * 0.82) * edge_fade, 0.0, 1.0)
			plasma_bytes[idx] = int(clampf(0.14 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 1] = int(clampf(0.46 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 2] = int(clampf(0.88 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 3] = 255

	# Pass 2: tangent-space normal map from central differences of the crater heightfield.
	var normal_bytes := PackedByteArray()
	normal_bytes.resize(n * n * 4)
	var strength := 5.5
	for y in n:
		var ym := maxi(y - 1, 0)
		var yp := mini(y + 1, n - 1)
		for x in n:
			var xm := maxi(x - 1, 0)
			var xp := mini(x + 1, n - 1)
			var dx := (heights[y * n + xp] - heights[y * n + xm]) * strength
			var dy := (heights[yp * n + x] - heights[ym * n + x]) * strength
			var nv := Vector3(-dx, -dy, 1.0).normalized()
			var idx := (y * n + x) * 4
			normal_bytes[idx] = int(clampf((nv.x * 0.5 + 0.5) * 255.0, 0.0, 255.0))
			normal_bytes[idx + 1] = int(clampf((nv.y * 0.5 + 0.5) * 255.0, 0.0, 255.0))
			normal_bytes[idx + 2] = int(clampf((nv.z * 0.5 + 0.5) * 255.0, 0.0, 255.0))
			normal_bytes[idx + 3] = 255

	var albedo_img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, albedo_bytes)
	var normal_img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, normal_bytes)
	var orm_img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, orm_bytes)
	var plasma_img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, plasma_bytes)
	albedo_img.generate_mipmaps()
	normal_img.generate_mipmaps()
	orm_img.generate_mipmaps()
	plasma_img.generate_mipmaps()
	_albedo = ImageTexture.create_from_image(albedo_img)
	_normal = ImageTexture.create_from_image(normal_img)
	_orm = ImageTexture.create_from_image(orm_img)
	_plasma = ImageTexture.create_from_image(plasma_img)
