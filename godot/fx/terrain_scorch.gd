extends RefCounted
# Issue 1779 & Issue 2048. Forward+ terrain dressing. This layer belongs only to marked receivers, including animated station parts.
# 256x256 multi-layered crater/char albedo, tangent-space normal, ORM (AO/roughness/metallic) and light-blue plasma vein emission.
# Uses native FastNoiseLite + Image.bump_map_to_normal_map so cold first-mark generation stays fast (no multi-hundred-ms stall).
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


static func _make_textures() -> void:
	var n := TEX_SIZE
	var inv_half := 2.0 / float(n)
	# C++ FastNoiseLite images supply multi-octave noise and fracture veins in ~2 ms total.
	var fn_fbm := FastNoiseLite.new()
	fn_fbm.seed = 20481
	fn_fbm.noise_type = FastNoiseLite.TYPE_VALUE
	fn_fbm.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn_fbm.fractal_octaves = 3
	fn_fbm.frequency = 0.028
	var fbm_bytes: PackedByteArray = fn_fbm.get_image(n, n, false, false, false).get_data()

	var fn_grit := FastNoiseLite.new()
	fn_grit.seed = 20482
	fn_grit.noise_type = FastNoiseLite.TYPE_VALUE
	fn_grit.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	fn_grit.fractal_octaves = 2
	fn_grit.frequency = 0.068
	var grit_bytes: PackedByteArray = fn_grit.get_image(n, n, false, false, false).get_data()

	var height_bytes := PackedByteArray()
	height_bytes.resize(n * n)
	var albedo_bytes := PackedByteArray()
	albedo_bytes.resize(n * n * 4)
	var orm_bytes := PackedByteArray()
	orm_bytes.resize(n * n * 4)
	var plasma_bytes := PackedByteArray()
	plasma_bytes.resize(n * n * 4)

	var inv255 := 1.0 / 255.0
	var p := 0
	var idx := 0
	for y in n:
		var vy := (float(y) + 0.5) * inv_half - 1.0
		var vy2 := vy * vy
		for x in n:
			var vx := (float(x) + 0.5) * inv_half - 1.0
			var r2 := vx * vx + vy2
			var fbm_v := float(fbm_bytes[p]) * inv255
			var ridge_v := float(grit_bytes[p]) * inv255
			if r2 >= 0.9604:
				height_bytes[p] = 128
				albedo_bytes[idx] = 24
				albedo_bytes[idx + 1] = 20
				albedo_bytes[idx + 2] = 18
				albedo_bytes[idx + 3] = 0
				orm_bytes[idx] = 255
				orm_bytes[idx + 1] = 240
				orm_bytes[idx + 2] = 0
				orm_bytes[idx + 3] = 255
				plasma_bytes[idx] = 0
				plasma_bytes[idx + 1] = 0
				plasma_bytes[idx + 2] = 0
				plasma_bytes[idx + 3] = 255
				p += 1
				idx += 4
				continue
			var r := sqrt(r2)
			var theta := atan2(vy, vx)
			var ray_sig := 0.5 + 0.5 * sin(theta * 9.0 + fbm_v * 2.4) * cos(theta * 5.0 - ridge_v * 1.8)
			var ray_sharp := ray_sig * ray_sig
			var warp := 1.0 + 0.13 * sin(5.0 * theta + 0.4) + 0.08 * cos(11.0 * theta - 0.9) + (fbm_v - 0.5) * 0.34
			var edge := r * warp
			# Heightfield (0..255 centered at 128): deep concave pit, raised chipped crater rim, radial gouges.
			var t_pit := clampf((edge - 0.06) / 0.34, 0.0, 1.0)
			var pit := -0.78 * (1.0 - t_pit * t_pit * (3.0 - 2.0 * t_pit))
			var rd_rim := (edge - 0.42) / 0.11
			var rim := 0.38 * exp(-rd_rim * rd_rim) * (0.65 + 0.70 * ridge_v)
			var t_g0 := clampf((edge - 0.28) / 0.27, 0.0, 1.0)
			var t_g1 := clampf((edge - 0.55) / 0.37, 0.0, 1.0)
			var gouge := -0.14 * ray_sharp * (t_g0 * t_g0 * (3.0 - 2.0 * t_g0)) * (1.0 - t_g1 * t_g1 * (3.0 - 2.0 * t_g1))
			var t_ef := clampf((r - 0.74) / 0.24, 0.0, 1.0)
			var edge_fade := 1.0 - t_ef * t_ef * (3.0 - 2.0 * t_ef)
			var h_val := 0.5 + (pit + rim + gouge + (ridge_v - 0.5) * 0.14 * edge_fade) * 0.45
			height_bytes[p] = int(clampf(h_val * 255.0, 0.0, 255.0))

			# Layered carbonized albedo + radial ejecta soot streaks.
			var t_cm := clampf((edge - 0.14) / 0.32, 0.0, 1.0)
			var core_mask := 1.0 - t_cm * t_cm * (3.0 - 2.0 * t_cm)
			var t_sh := clampf((edge - ray_sharp * 0.14 - 0.20) / 0.70, 0.0, 1.0)
			var soot_halo := (1.0 - t_sh * t_sh * (3.0 - 2.0 * t_sh)) * (0.62 + 0.38 * fbm_v)
			var alpha := clampf((core_mask * 0.88 + soot_halo * 0.62) * edge_fade, 0.0, 0.94)
			var t_ct := clampf((edge - 0.10) / 0.55, 0.0, 1.0)
			var char_tone := lerpf(0.032, 0.115, t_ct * t_ct * (3.0 - 2.0 * t_ct)) * (0.78 + 0.34 * ridge_v)
			var ash_tint := 0.025 * rim * (0.5 + fbm_v)
			albedo_bytes[idx] = int(clampf((char_tone * 1.12 + ash_tint) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 1] = int(clampf((char_tone * 0.94 + ash_tint * 0.92) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 2] = int(clampf((char_tone * 0.86 + ash_tint * 0.88) * 255.0, 0.0, 255.0))
			albedo_bytes[idx + 3] = int(clampf(alpha * 255.0, 0.0, 255.0))

			# ORM: R=AO (dark inside pit), G=Roughness (matte char, slightly vitrified rim), B=Metallic.
			var ao := clampf(1.0 - core_mask * 0.72 - rim * 0.20, 0.18, 1.0)
			var rough := clampf(lerpf(0.94, 0.48, rim * 0.85) - (ridge_v - 0.5) * 0.08, 0.35, 0.98)
			var metal := clampf(rim * 0.24, 0.0, 0.35)
			orm_bytes[idx] = int(ao * 255.0)
			orm_bytes[idx + 1] = int(rough * 255.0)
			orm_bytes[idx + 2] = int(metal * 255.0)
			orm_bytes[idx + 3] = 255

			# Light-blue plasma-melt emission (RULEBOOK 6.13): glowing ridged fracture veins inside pit + hot rim.
			var t_vm := clampf((edge - 0.18) / 0.44, 0.0, 1.0)
			var v_pow := ridge_v * ridge_v
			var vein := v_pow * v_pow * ridge_v * (1.0 - t_vm * t_vm * (3.0 - 2.0 * t_vm))
			var rd_rg := (edge - 0.38) / 0.075
			var rim_glow := exp(-rd_rg * rd_rg) * (0.45 + 0.55 * ray_sharp) * (0.65 + 0.35 * fbm_v)
			var heat := clampf((vein * 1.45 + rim_glow * 0.82) * edge_fade, 0.0, 1.0)
			plasma_bytes[idx] = int(clampf(0.14 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 1] = int(clampf(0.46 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 2] = int(clampf(0.88 * heat * 255.0, 0.0, 255.0))
			plasma_bytes[idx + 3] = 255
			p += 1
			idx += 4

	var normal_img := Image.create_from_data(n, n, false, Image.FORMAT_L8, height_bytes)
	normal_img.bump_map_to_normal_map(12.0)
	var albedo_img := Image.create_from_data(n, n, false, Image.FORMAT_RGBA8, albedo_bytes)
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
