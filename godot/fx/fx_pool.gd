extends RefCounted
# GPU particle storage for the effects library.
#
# Every particle is static data on the GPU (start time, motion, colour, size, kind); the shaders work out its age from
# the effect clock, so the CPU never animates particles. Two containers share one vertex format:
#   Pool  : a fixed-size ring buffer in world space for one-shot particles. Emitting writes the particle's 20 floats into
#           the next slot (all of its vertices) and marks the range dirty; flush() uploads only the dirty range once a
#           frame (RenderingServer.mesh_surface_update_attribute_region). The oldest particle is overwritten when the
#           ring wraps, so capacity is sized for several seconds of the heaviest fighting.
#   Batch : built once, then static, usually attached to a ship (looping particles: engine cores, breach fires).
# Attribute layout per vertex (checked on Godot 4.7.2): uv(2) uv2(2) custom0(4) custom1(4) custom2(4) custom3(4), 80 bytes.

const STRIDE := 20
const BIG := AABB(Vector3(-4000, -4000, -4000), Vector3(8000, 8000, 8000))
const QUAD := [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]
const STREAK := [Vector2(0, -0.5), Vector2(1, -0.5), Vector2(1, 0.5), Vector2(0, 0.5)]
const FMT := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
	| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT)


# Pack a particle: a0..a3 are the four vec4s, a4 = (period, accel, drag, spin). Returns the 20 floats in GPU order.
static func pack(a0: Vector4, a1: Vector4, a2: Vector4, a3: Vector4, a4: Vector4) -> PackedFloat32Array:
	return PackedFloat32Array([a4.x, a4.y, a4.z, a4.w, a0.x, a0.y, a0.z, a0.w, a1.x, a1.y, a1.z, a1.w, a2.x, a2.y, a2.z, a2.w,
		a3.x, a3.y, a3.z, a3.w])


static func _surface(verts: PackedVector3Array, normals: PackedVector3Array, idx: PackedInt32Array, data: PackedFloat32Array) -> Array:
	var n = verts.size()
	var uv = PackedVector2Array()
	var uv2 = PackedVector2Array()
	var c = [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	uv.resize(n)
	uv2.resize(n)
	for k in 4:
		c[k].resize(n * 4)
	for i in n:
		var o = i * STRIDE
		uv[i] = Vector2(data[o], data[o + 1])
		uv2[i] = Vector2(data[o + 2], data[o + 3])
		for k in 4:
			for j in 4:
				c[k][i * 4 + j] = data[o + 4 + k * 4 + j]
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	if not normals.is_empty():
		arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_TEX_UV2] = uv2
	arr[Mesh.ARRAY_CUSTOM0] = c[0]
	arr[Mesh.ARRAY_CUSTOM1] = c[1]
	arr[Mesh.ARRAY_CUSTOM2] = c[2]
	arr[Mesh.ARRAY_CUSTOM3] = c[3]
	arr[Mesh.ARRAY_INDEX] = idx
	return arr


static func _instance(arr: Array, mat: Material, parent: Node, name: String) -> MeshInstance3D:
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {}, FMT)
	am.custom_aabb = BIG
	var mi = MeshInstance3D.new()
	mi.name = name
	mi.mesh = am
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------- Pool (dynamic ring)

# n copies of a pattern, by doubling (native copies, no per-element script loop)
static func repeat_f(pattern: PackedFloat32Array, n: int) -> PackedFloat32Array:
	var out = pattern.duplicate()
	var have = 1
	while have * 2 <= n:
		out.append_array(out)
		have *= 2
	if have < n:
		out.append_array(out.slice(0, (n - have) * pattern.size()))
	return out


static func repeat_v3(pattern: PackedVector3Array, n: int) -> PackedVector3Array:
	var out = pattern.duplicate()
	var have = 1
	while have * 2 <= n:
		out.append_array(out)
		have *= 2
	if have < n:
		out.append_array(out.slice(0, (n - have) * pattern.size()))
	return out


class Pool:
	var cap = 0
	var vpp = 4            # vertices per particle
	var head = 0
	var start = 0
	var pending = PackedFloat32Array()
	var n_pending = 0
	var mi: MeshInstance3D
	var rid: RID
	var emitted = 0

	# shape: [verts, normals (or empty), idx] for one particle; shape_fn (optional) gives each slot its own shape
	func _init(capacity: int, mat: Material, parent: Node, name: String, shape: Array, shape_fn: Callable = Callable()) -> void:
		var P = load("res://fx/fx_pool.gd")
		cap = capacity
		vpp = (shape[0] as PackedVector3Array).size()
		var verts = PackedVector3Array()
		var nrm = PackedVector3Array()
		var idx = PackedInt32Array()
		if shape_fn.is_valid():
			for s in cap:
				var one: Array = shape_fn.call()
				var b = verts.size()
				verts.append_array(one[0])
				nrm.append_array(one[1])
				for i in (one[2] as PackedInt32Array):
					idx.append(b + i)
		else:
			verts = P.repeat_v3(shape[0], cap)
			if not (shape[1] as PackedVector3Array).is_empty():
				nrm = P.repeat_v3(shape[1], cap)
			var one_idx: PackedInt32Array = shape[2]
			idx.resize(cap * one_idx.size())
			var k = 0
			for s in cap:
				var b = s * vpp
				for i in one_idx:
					idx[k] = b + i
					k += 1
		var n = cap * vpp
		var arr = []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = verts
		if not nrm.is_empty():
			arr[Mesh.ARRAY_NORMAL] = nrm
		var z2 = PackedVector2Array()
		z2.resize(n)
		arr[Mesh.ARRAY_TEX_UV] = z2
		arr[Mesh.ARRAY_TEX_UV2] = z2
		# dead on arrival: start time far in the future
		arr[Mesh.ARRAY_CUSTOM0] = P.repeat_f(PackedFloat32Array([0.0, 0.0, 0.0, 1e9]), n)
		var z4 = PackedFloat32Array()
		z4.resize(n * 4)
		arr[Mesh.ARRAY_CUSTOM1] = z4
		arr[Mesh.ARRAY_CUSTOM2] = z4
		arr[Mesh.ARRAY_CUSTOM3] = z4
		arr[Mesh.ARRAY_INDEX] = idx
		mi = P._instance(arr, mat, parent, name)
		rid = mi.mesh.get_rid()

	func emit(p: PackedFloat32Array) -> void:
		if n_pending == 0:
			start = head
		for v in vpp:
			pending.append_array(p)
		n_pending += 1
		head += 1
		emitted += 1
		if head >= cap:
			flush()
			head = 0

	func flush() -> void:
		if n_pending == 0:
			return
		RenderingServer.mesh_surface_update_attribute_region(rid, 0, start * vpp * STRIDE * 4, pending.to_byte_array())
		pending = PackedFloat32Array()
		n_pending = 0


# ---------------------------------------------------------------- Batch (static, built once)

class Batch:
	var verts = PackedVector3Array()
	var nrm = PackedVector3Array()
	var idx = PackedInt32Array()
	var data = PackedFloat32Array()

	func add(shape: Array, p: PackedFloat32Array) -> void:
		var b = verts.size()
		verts.append_array(shape[0])
		if not (shape[1] as PackedVector3Array).is_empty():
			nrm.append_array(shape[1])
		for i in (shape[2] as PackedInt32Array):
			idx.append(b + i)
		for v in (shape[0] as PackedVector3Array).size():
			data.append_array(p)

	func count() -> int:
		return verts.size()

	func build(mat: Material, parent: Node, name: String) -> MeshInstance3D:
		if verts.is_empty():
			return null
		var arr: Array = load("res://fx/fx_pool.gd")._surface(verts, nrm, idx, data)
		return load("res://fx/fx_pool.gd")._instance(arr, mat, parent, name)


# ---------------------------------------------------------------- particle shapes

static func quad_shape() -> Array:
	var v = PackedVector3Array()
	for c in QUAD:
		v.append(Vector3(c.x, c.y, 0))
	return [v, PackedVector3Array(), PackedInt32Array([0, 1, 2, 0, 2, 3])]


static func streak_shape() -> Array:
	var v = PackedVector3Array()
	for c in STREAK:
		v.append(Vector3(c.x, c.y, 0))
	return [v, PackedVector3Array(), PackedInt32Array([0, 1, 2, 0, 2, 3])]


static func ribbon_shape(segs: int) -> Array:
	var v = PackedVector3Array()
	var idx = PackedInt32Array()
	for j in segs + 1:
		v.append(Vector3(float(j) / segs, -0.5, 0))
		v.append(Vector3(float(j) / segs, 0.5, 0))
	for j in segs:
		var q = j * 2
		idx.append_array(PackedInt32Array([q, q + 1, q + 3, q, q + 3, q + 2]))
	return [v, PackedVector3Array(), idx]


# a jittered octahedron, flat shaded (24 vertices), for debris chips
static func shard_shape(rng: RandomNumberGenerator) -> Array:
	var P: Array = []
	for q in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
		var j = 0.5 + rng.randf() * 0.5
		P.append(Vector3(q.x * j * (0.5 + rng.randf() * 0.6), q.y * j * 0.35, q.z * j * (0.5 + rng.randf() * 0.6)))
	var F = [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	var v = PackedVector3Array()
	var n = PackedVector3Array()
	var idx = PackedInt32Array()
	for f in F:
		var pa: Vector3 = P[f[0]]
		var pb: Vector3 = P[f[1]]
		var pc: Vector3 = P[f[2]]
		var nn = (pb - pa).cross(pc - pa).normalized()
		var b = v.size()
		v.append_array(PackedVector3Array([pa, pb, pc]))
		n.append_array(PackedVector3Array([nn, nn, nn]))
		idx.append_array(PackedInt32Array([b, b + 2, b + 1]))
	return [v, n, idx]
