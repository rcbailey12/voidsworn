extends RefCounted
# Cut actual loaded battle hull arrays. Preserve source UVs, paint and PBR
# materials, seal every torn edge with the same caps used by death wrecks.
const DEATH := preload("res://fx/fx_death.gd")

static func gather(ships: Array) -> Array:
	var sources: Array = []
	var seen := {}
	for ship in ships:
		if not is_instance_valid(ship): continue
		var faction := str(ship.get("fac"))
		if seen.has(faction): continue
		var surfaces: Array = []
		var inv: Transform3D = ship.global_transform.affine_inverse()
		for node in ship.get("meshes"):
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null: continue
			for i in mi.mesh.get_surface_count():
				if mi.mesh.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES: continue
				surfaces.append({"arrays": mi.mesh.surface_get_arrays(i), "xf": inv * mi.global_transform,
					"mat": mi.get_active_material(i), "fmt": mi.mesh.surface_get_format(i)})
		if surfaces.is_empty(): continue
		seen[faction] = true
		sources.append({"faction": faction, "surfs": surfaces})
	return sources

static func cut(sources: Array) -> Array:
	var chunks: Array = []
	for source in sources:
		var box := AABB()
		var first := true
		for sd in source.surfs:
			var vertices: PackedVector3Array = sd.xf * sd.arrays[Mesh.ARRAY_VERTEX]
			for p in vertices:
				if first: box = AABB(p, Vector3.ZERO); first = false
				else: box = box.expand(p)
		var seeds := PackedVector3Array()
		for j in 4:
			seeds.append(box.position + box.size * Vector3((j + 0.5) / 4.0, 0.5, 0.5))
		for pc in DEATH._cut({"surfs": source.surfs, "seeds": seeds}):
			if pc.n > 0:
				pc["faction"] = source.faction
				chunks.append(pc)
	return chunks

static func meshes(chunks: Array) -> Array:
	var out: Array = []
	for pc in chunks:
		var mesh := DEATH._piece_mesh(pc, true)
		if mesh.get_surface_count() > 0: out.append(mesh)
	return out
