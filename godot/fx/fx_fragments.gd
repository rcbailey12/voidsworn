extends RefCounted
## Templates share an index layout, so the hit pool can draw any fragment from any slot in one call.
## Each rim point is (x, bend height, z, half thickness), ordered around the cap centre.

const PLATE := 0
const RIB := 2
const GLASS := 4
const RIM := 6
const CAP := RIM + 1
const VERTICES := CAP * 2 + RIM * 4
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
		Vector4(-.56,.02,-.13,.15), Vector4(-.17,.10,-.075,.18), Vector4(.16,-.10,-.24,.08)],
	# Long fracture points taper to a thin edge. The middle keeps the thickness of broken glass.
	[Vector4(.66,.04,.015,.012), Vector4(.16,.01,.11,.065), Vector4(-.17,-.04,.36,.026),
		Vector4(-.35,-.01,.085,.085), Vector4(-.22,.07,-.09,.07), Vector4(.16,.08,-.21,.035)],
	[Vector4(.46,-.06,.025,.03), Vector4(.12,.02,.19,.095), Vector4(-.08,.09,.31,.016),
		Vector4(-.48,.02,.065,.055), Vector4(-.18,-.06,-.07,.07), Vector4(.16,-.02,-.35,.02)],
]
const CROWN := [0.095, -0.06, 0.045, -0.035, 0.03, 0.055]
const CENTRE_DEPTH := [0.075, 0.075, 0.15, 0.15, 0.12, 0.105]

static var _meshes: Array[Array] = []
static var _atlas_image: Image


# Each template is [positions, normals, indices]. Cap vertices share normals across the bend.
# The walls have their own normals and vertices, and meet the caps at the same positions.
static func templates() -> Array[Array]:
	if _meshes.is_empty():
		for profile in PROFILES.size():
			_meshes.append(_build(profile))
	return _meshes


static func atlas() -> ImageTexture:
	if _atlas_image == null:
		var meshes := templates()
		_atlas_image = Image.create_empty(VERTICES, meshes.size() * 2, false, Image.FORMAT_RGBAF)
		for profile in meshes.size():
			var vertices: PackedVector3Array = meshes[profile][0]
			var normals: PackedVector3Array = meshes[profile][1]
			for i in VERTICES:
				var v := vertices[i]
				var n := normals[i]
				_atlas_image.set_pixel(i, profile * 2, Color(v.x, v.y, v.z, float(profile >= GLASS)))
				_atlas_image.set_pixel(i, profile * 2 + 1, Color(n.x, n.y, n.z, float(i >= CAP * 2)))
	# The pool material owns the GPU texture. The static cache only holds CPU data.
	return ImageTexture.create_from_image(_atlas_image)


static func _build(profile: int) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	normals.resize(VERTICES)
	for side in 2:
		var sign_y := 1.0 if side == 0 else -1.0
		vertices.append(Vector3(0.0, CROWN[profile] + CENTRE_DEPTH[profile] * sign_y, 0.0))
		for point: Vector4 in PROFILES[profile]:
			vertices.append(Vector3(point.x, point.y + point.w * sign_y, point.z))
		var centre := side * CAP
		for i in RIM:
			var a := centre + 1 + i
			var b := centre + 1 + (i + 1) % RIM
			var first := a if side == 0 else b
			var second := b if side == 0 else a
			indices.append_array(PackedInt32Array([centre, first, second]))
			# Godot uses clockwise front faces.
			var n := (vertices[second] - vertices[centre]).cross(vertices[first] - vertices[centre])
			normals[centre] += n
			normals[a] += n
			normals[b] += n
	for i in CAP * 2:
		normals[i] = normals[i].normalized()
	for i in RIM:
		var a := 1 + i
		var b := 1 + (i + 1) % RIM
		var start := vertices.size()
		vertices.append_array(PackedVector3Array([vertices[b], vertices[a], vertices[CAP + a], vertices[CAP + b]]))
		var n := (vertices[start + 2] - vertices[start]).cross(vertices[start + 1] - vertices[start]).normalized()
		for j in 4:
			normals[start + j] = n
		indices.append_array(PackedInt32Array([start, start + 1, start + 2, start, start + 2, start + 3]))
	return [vertices, normals, indices]
