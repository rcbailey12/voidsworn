extends RefCounted
## Closed pieces with a shared index layout, drawn by one MultiMesh.
## Each control point is (x, bend height, z, half thickness), ordered around the cap centre.

const HULL := preload("res://fx/fx_hull.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const PLATE := 0
const RIB := 4
const GLASS := 8
const VARIANTS := 4
const STEPS_PER_EDGE := 5
const RIM := 6 * STEPS_PER_EDGE
const CAP := 1 + RIM * 4
const WALL_LEVELS := Vector4(0.66, 0.38, -0.44, -0.66)
const WALL_RINGS := 4
const VERTICES := 2 * CAP + 2 * RIM * WALL_RINGS
const DATA_COLUMNS := 9
const FINISH_SLOTS := 8
const COMPAT_FINISH_SLOTS := 3
const PROFILES := [
	# Buckled armour, one folded corner and one deep bite.
	[Vector4(.57,.12,-.05,.07), Vector4(.20,-.05,.27,.09), Vector4(-.18,-.06,.41,.06),
		Vector4(-.49,.04,.11,.11), Vector4(-.19,.18,-.09,.08), Vector4(.12,.02,-.38,.05)],
	[Vector4(.45,-.08,.02,.08), Vector4(.18,.14,.43,.065), Vector4(-.07,.10,.20,.07),
		Vector4(-.56,-.11,.09,.05), Vector4(-.27,-.02,-.33,.10), Vector4(.25,.03,-.29,.075)],
	# Crushed ribs, with a broken flange and a thicker web down the length.
	[Vector4(.65,-.13,.025,.045), Vector4(.14,.01,.18,.14), Vector4(-.16,.08,.13,.17),
		Vector4(-.63,.11,-.05,.075), Vector4(-.10,-.02,-.15,.15), Vector4(.24,.04,-.23,.08)],
	[Vector4(.63,.11,.06,.07), Vector4(.29,.02,.16,.14), Vector4(-.43,-.07,.19,.095),
		Vector4(-.56,.02,-.13,.15), Vector4(-.17,.10,-.13,.18), Vector4(.16,-.10,-.24,.08)],
	# Long fracture points taper to a thin edge. The middle keeps the thickness of broken glass.
	[Vector4(.66,.04,.015,.012), Vector4(.16,.01,.11,.065), Vector4(-.17,-.04,.36,.026),
		Vector4(-.35,-.01,.085,.085), Vector4(-.22,.07,-.09,.07), Vector4(.16,.08,-.21,.035)],
	[Vector4(.46,-.06,.025,.03), Vector4(.12,.02,.19,.095), Vector4(-.08,.09,.31,.016),
		Vector4(-.48,.02,.065,.055), Vector4(-.18,-.06,-.07,.07), Vector4(.16,-.02,-.35,.02)],
]
const CROWN := [0.095, -0.06, 0.045, -0.035, 0.03, 0.055]
const CENTRE_DEPTH := [0.075, 0.075, 0.15, 0.15, 0.12, 0.105]

static var _meshes: Array[Array] = []   # not GPU: vertex arrays (Packed arrays), not meshes
static var _atlas_image: Image


# Each template is [positions, normals, indices, chart]. Cap vertices share normals across the bend.
# The walls have their own normals and vertices, and meet the caps at the same positions.
static func templates() -> Array[Array]:
	if _meshes.is_empty():
		for profile in PROFILES.size() * 2:
			_meshes.append(_build(profile))
	return _meshes


static func atlas() -> ImageTexture:
	if _atlas_image == null:
		var meshes := templates()
		_atlas_image = Image.create_empty(VERTICES, meshes.size() * 3, false, Image.FORMAT_RGBAF)
		for profile in meshes.size():
			var vertices: PackedVector3Array = meshes[profile][0]
			var normals: PackedVector3Array = meshes[profile][1]
			var chart: PackedVector3Array = meshes[profile][3]
			for i in VERTICES:
				var v := vertices[i]
				var n := normals[i]
				var surface := 0 if i < CAP else (1 if i < CAP * 2 else 2)
				_atlas_image.set_pixel(i, profile * 3, Color(v.x, v.y, v.z, chart[i].z))
				_atlas_image.set_pixel(i, profile * 3 + 1, Color(n.x, n.y, n.z, surface))
				_atlas_image.set_pixel(i, profile * 3 + 2, Color(chart[i].x, chart[i].y, 0.0, 0.0))
	# The pool material owns the GPU texture. The static cache only holds CPU data.
	return ImageTexture.create_from_image(_atlas_image)


static func _build(profile: int) -> Array:
	var control := profile / 2
	var rim := PackedVector4Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 731 + profile * 97
	for edge in 6:
		var a: Vector4 = PROFILES[control][edge]
		var b: Vector4 = PROFILES[control][(edge + 1) % 6]
		for j in STEPS_PER_EDGE:
			var t := (j + rng.randf_range(-0.26, 0.26)) / STEPS_PER_EDGE if j > 0 else 0.0
			var q := a.lerp(b, t)
			var bite := rng.randf_range(0.80, 1.08) if j > 0 else rng.randf_range(0.94, 1.08)
			q.x *= bite
			q.z *= bite
			q.y += rng.randf_range(-0.006, 0.006)
			q.w *= rng.randf_range(0.92, 1.08)
			rim.append(q)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var chart := PackedVector3Array()
	normals.resize(VERTICES)
	# Three rows roll the painted faces down to the tear. A middle row gives bent and curled
	# pieces a smooth highlight across the fold. Both skins meet the flat-shaded fracture wall.
	for side in 2:
		var sign_y := 1.0 if side == 0 else -1.0
		var crown: float = CROWN[control]
		var depth: float = CENTRE_DEPTH[control]
		vertices.append(Vector3(0.0, crown + depth * sign_y, 0.0))
		chart.append(Vector3.ZERO)
		for ring in 4:
			var r: float = [0.53, 0.89, 0.97, 1.0][ring]
			var lift: float = [1.0, 1.04, 0.91, WALL_LEVELS[0]][ring]
			for q in rim:
				var curl := sin(q.x * 4.0 + q.z * 6.0) * (0.35 if profile % 2 else 0.14)
				var bend: float = (crown + curl * r) * (1.0 - r)
				var half := lerpf(q.w, depth, 0.28) if ring == 0 else q.w
				var point := Vector3(q.x * r, q.y * r + bend + half * lift * sign_y, q.z * r)
				vertices.append(point)
				chart.append(Vector3(point.x, point.z, r))
		var centre := side * CAP
		for i in RIM:
			var a := centre + 1 + i
			var b := centre + 1 + (i + 1) % RIM
			_add_face(vertices, normals, indices, centre, a, b, side == 1)
			for ring in 3:
				_add_face(vertices, normals, indices, a, a + RIM, b + RIM, side == 1)
				_add_face(vertices, normals, indices, a, b + RIM, b, side == 1)
				a += RIM
				b += RIM

	var walk := 0.0
	for i in RIM:
		var a := rim[i]
		var b := rim[(i + 1) % RIM]
		var span := Vector2(a.x - b.x, a.z - b.z).length()
		var start := vertices.size()
		for level in WALL_RINGS:
			var h: float = WALL_LEVELS[level]
			var upper := CAP - RIM
			var next := (i + 1) % RIM
			var pa := Vector3(a.x, a.y + a.w * h, a.z)
			var pb := Vector3(b.x, b.y + b.w * h, b.z)
			if level == 0 or level == WALL_RINGS - 1:
				var edge := upper if level == 0 else upper + CAP
				pa = vertices[edge + i]
				pb = vertices[edge + next]
			vertices.append_array(PackedVector3Array([pb, pa]))
			chart.append(Vector3(walk + span, h, 1.0))
			chart.append(Vector3(walk, h, 1.0))
		for level in WALL_RINGS - 1:
			var row := start + 2 * level
			_add_face(vertices, normals, indices, row, row + 1, row + 3, false)
			_add_face(vertices, normals, indices, row, row + 3, row + 2, false)
		walk += span
	for i in VERTICES:
		normals[i] = normals[i].normalized()
	return [vertices, normals, indices, chart]


static func _add_face(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array,
		a: int, b: int, c: int, reverse: bool) -> void:
	if reverse:
		var next := c
		c = b
		b = next
	indices.append_array(PackedInt32Array([a, b, c]))
	# Godot uses clockwise front faces.
	var normal := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a]).normalized()
	normals[a] += normal
	normals[b] += normal
	normals[c] += normal


# The hull BVH keeps the shipping mesh's triangle order. Resolve its hit back to the
# original part (the live hull may already have a damage material over that part).
static func source(target, at: Vector3, normal: Vector3) -> Dictionary:
	if target == null or target.hull.tm == null:
		return {}
	var inv: Transform3D = target.xf().affine_inverse()
	var p := inv * at
	var out := (inv.basis * normal).normalized()
	var finish := _source_at(target, p, out)
	if not finish.is_empty():
		return finish
	# Running lights and other unpainted fittings can sit over the plate.
	var u := out.cross(Vector3.UP if absf(out.y) < 0.8 else Vector3.RIGHT).normalized() * 0.22
	var v := out.cross(u)
	for shift: Vector3 in [u, -u, v, -v]:
		finish = _source_at(target, p + shift, out)
		if not finish.is_empty():
			return finish
	return {}


static func _source_at(target, p: Vector3, out: Vector3) -> Dictionary:
	var hit: Dictionary = target.hull.tm.intersect_segment(p + out * 0.13, p - out * 0.22)
	if hit.is_empty():
		return {}
	var face := int(hit["face_index"])
	# Face numbers belong to the BVH. A damage rebuild can replace or split the live mesh's triangles.
	for row in target.hull.bvh_ranges:
		var start := int(row["start"])
		if face >= start and face < start + int(row["count"]):
			var mi = row["mi"]
			if not is_instance_valid(mi):
				return {}
			var at: Vector3 = (row["to_part"] as Transform3D) * (hit["position"] as Vector3)
			var corners := HULL.face_corners(face - start, row["strip"])
			var paint: BaseMaterial3D = row["paint"]
			if paint == null or paint.albedo_texture == null:
				return {}
			var arrays: Array = target.arrays_of(row["mesh"], int(row["surface"]))
			return _finish(mi.global_transform.basis, arrays, paint, corners, at)
	return {}


# Use the original BVH ranges. Damage can replace the visible surface, but the
# fragment paint still comes from the original UVs.
static func warm_source(target) -> void:
	for row in target.hull.bvh_ranges:
		var paint: BaseMaterial3D = row["paint"]
		if paint != null and paint.albedo_texture != null:
			target.arrays_of(row["mesh"], int(row["surface"]))


static func _finish(world: Basis, arrays: Array, material: BaseMaterial3D, corners: Vector3i, at: Vector3) -> Dictionary:
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	if uv.is_empty():
		return {}
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	var a := corners.x
	var b := corners.y
	var c := corners.z
	if not indices.is_empty():
		a = indices[a]
		b = indices[b]
		c = indices[c]
	var weights := Geometry3D.get_triangle_barycentric_coords(at, vertices[a], vertices[b], vertices[c])
	var centre := uv[a] * weights.x + uv[b] * weights.y + uv[c] * weights.z
	var scale := Vector2(material.uv1_scale.x, material.uv1_scale.y)
	var offset := Vector2(material.uv1_offset.x, material.uv1_offset.y)
	var edge := world * (vertices[b] - vertices[a])
	var across := world * (vertices[c] - vertices[a])
	var tangent := edge.normalized()
	var rise := across.slide(tangent).length()
	if edge.length_squared() < 1e-10 or rise < 1e-5:
		return {}
	var along_uv := (uv[b] - uv[a]) / edge.length()
	var across_uv := (uv[c] - uv[a] - along_uv * across.dot(tangent)) / rise
	var maps := finish_maps(material)
	return {"maps": maps, "uv": centre * scale + offset, "u": (along_uv * scale).limit_length(0.4),
		"v": (across_uv * scale).limit_length(0.4), "tint": material.albedo_color.srgb_to_linear(),
		"finish": Vector4(material.roughness, material.metallic, material.metallic_specular, 1.0 if maps[1] != null else 0.0),
		"normal_scale": material.normal_scale if material.normal_enabled else 0.0, "slot": -1}


static func finish_maps(material: BaseMaterial3D) -> Array:
	var orm := material.get_texture(BaseMaterial3D.TEXTURE_ORM)
	if orm == null:
		var rough := material.get_texture(BaseMaterial3D.TEXTURE_ROUGHNESS)
		var metal := material.get_texture(BaseMaterial3D.TEXTURE_METALLIC)
		# Older glTFs use a StandardMaterial3D pointing both channels at the same packed map.
		if rough != null and rough == metal and material.roughness_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_GREEN \
				and material.metallic_texture_channel == BaseMaterial3D.TEXTURE_CHANNEL_BLUE:
			orm = rough
	return [material.albedo_texture, orm, material.normal_texture if material.normal_enabled else null]


class Pool:
	var cap: int
	var emitted := 0
	var mi: MultiMeshInstance3D
	var particles: Array[PackedFloat32Array] = []
	var _slots: Array = []
	var _until := PackedFloat32Array()
	var _data: ImageTexture
	var _material: ShaderMaterial
	var _dirty := false
	var _next_end := INF

	func _init(capacity: int, material: ShaderMaterial, slots: int, parent: Node3D, shape: Array, meshes: Texture2D) -> void:
		cap = capacity
		_material = material
		_slots.resize(slots)
		_until.resize(slots)
		_data = ImageTexture.create_from_image(Image.create_empty(DATA_COLUMNS, cap, false, Image.FORMAT_RGBAF))
		material.set_shader_parameter("fragment_instances", _data)
		material.set_shader_parameter("fragment_meshes", meshes)
		material.set_shader_parameter("glass_profile", GLASS)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = shape[0]
		arrays[Mesh.ARRAY_NORMAL] = shape[1]
		arrays[Mesh.ARRAY_INDEX] = shape[2]
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = mesh
		batch.instance_count = cap
		batch.visible_instance_count = 0
		batch.custom_aabb = POOLS.BIG
		for i in cap:
			batch.set_instance_transform(i, Transform3D.IDENTITY)
		mi = MultiMeshInstance3D.new()
		mi.name = "fx_hit_fragments"
		mi.multimesh = batch
		mi.material_override = material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		parent.add_child(mi)

	# A binding stays pinned until every piece that uses it has expired. Reusing it
	# early would repaint pieces in mid-flight. No image reads, uploads or downsampling.
	func bind_finish(finish: Dictionary, now: float, until: float) -> void:
		if finish.is_empty():
			return
		var maps: Array = finish["maps"]
		var available := -1
		for i in _slots.size():
			if _slots[i] == maps:
				finish["slot"] = i
				_until[i] = maxf(_until[i], until)
				return
			if available < 0 and _until[i] <= now:
				available = i
		if available < 0:
			return
		_slots[available] = maps
		_until[available] = until
		finish["slot"] = available
		for i in maps.size():
			_material.set_shader_parameter("%s_%d" % [["hull_color", "hull_orm", "hull_normal"][i], available], maps[i])

	func emit(particle: PackedFloat32Array, finish: Dictionary) -> void:
		var slot := int(finish.get("slot", -1))
		var uv: Vector2 = finish.get("uv", Vector2.ZERO)
		var u: Vector2 = finish.get("u", Vector2.ZERO)
		var v: Vector2 = finish.get("v", Vector2.ZERO)
		var tint: Color = finish.get("tint", Color.WHITE)
		var factors: Vector4 = finish.get("finish", Vector4.ONE)
		particle.append_array(PackedFloat32Array([uv.x, uv.y, u.x, u.y, v.x, v.y, slot, finish.get("normal_scale", 0.0),
			tint.r, tint.g, tint.b, factors.x, factors.y, factors.z, factors.w, 0.0]))
		if particles.size() == cap:
			particles.pop_front()
		particles.append(particle)
		emitted += 1
		_dirty = true

	func flush(now: float) -> void:
		if not _dirty and now < _next_end:
			return
		_dirty = false
		_next_end = INF
		var live: Array[PackedFloat32Array] = []
		var data := PackedFloat32Array()
		for particle in particles:
			var expires := particle[7] + particle[11]
			if expires > now:
				live.append(particle)
				data.append_array(particle)
				_next_end = minf(_next_end, expires)
		particles = live
		mi.multimesh.visible_instance_count = live.size()
		if not live.is_empty():
			data.resize(cap * DATA_COLUMNS * 4)
			_data.update(Image.create_from_data(DATA_COLUMNS, cap, false, Image.FORMAT_RGBAF, data.to_byte_array()))
