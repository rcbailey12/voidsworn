extends Node3D
# The environment for max and board modes (SPEC.md "Environment"): the asteroid field and big rocks from
# ../assets/env/asteroids.json (seed 7, the same placements as the Babylon half), tumbling slowly, with sphere colliders
# for the physics debris, and a thin dust haze. The dead-star sky is chosen in main.gd. Missing files: nothing is added.

var rocks: Array = []          # {node or multimesh index, axis, rate, base basis, position, scale}
var _mm: Dictionary = {}       # mesh name -> MultiMeshInstance3D
var _mm_rocks: Dictionary = {} # mesh name -> Array of rock entries
var notes: PackedStringArray = []


func setup(env_dir: String, env: Environment, phys: Node, compat: bool) -> bool:
	var jpath := env_dir.path_join("asteroids.json")
	if not FileAccess.file_exists(jpath):
		notes.append("env: assets/env/asteroids.json not found, no asteroids or haze")
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(jpath))
	if typeof(data) != TYPE_DICTIONARY or not data.has("rocks"):
		notes.append("env: asteroids.json unreadable")
		return false
	var meshes := {}
	for r in data["rocks"]:
		var name: String = r["mesh"]
		if meshes.has(name):
			continue
		meshes[name] = _load_rock(env_dir.path_join("rocks/%s.glb" % name))
	# field rocks: one MultiMesh per rock mesh (instanced); big rocks: their own nodes
	var field := {}
	var big := 0
	for r in data["rocks"]:
		var m: Mesh = meshes.get(r["mesh"])
		if m == null:
			continue
		var q: Array = r["rotation"]
		var e := {"pos": _v(r["position"]), "scale": float(r["scale"]), "rot": Basis(Quaternion(q[0], q[1], q[2], q[3])),
			"axis": _v(r["spin_axis"]).normalized(), "rate": float(r["spin_rate"])}
		if String(r.get("kind", "field")) == "field":
			if not field.has(r["mesh"]):
				field[r["mesh"]] = []
			field[r["mesh"]].append(e)
		else:
			var mi := MeshInstance3D.new()
			mi.mesh = m
			add_child(mi)
			e["node"] = mi
			rocks.append(e)
			big += 1
		if phys != null:
			phys.add_rock(e["pos"], e["scale"] * 0.45)
	for name in field:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = meshes[name]
		mm.instance_count = field[name].size()
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)
		_mm[name] = mmi
		_mm_rocks[name] = field[name]
	update(0.0)
	if not compat:
		# a thin dust haze through the battle area: Godot's volumetric fog, lit by every light in it
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0009
		env.volumetric_fog_albedo = Color(0.75, 0.72, 0.7)
		env.volumetric_fog_length = maxf(env.volumetric_fog_length, 320.0)
		env.volumetric_fog_anisotropy = 0.3
		env.volumetric_fog_ambient_inject = 0.3
		notes.append("env: %d asteroids (%d instanced in %d MultiMeshes, %d big rocks), dust haze in volumetric fog" % [
			data["rocks"].size(), data["rocks"].size() - big, _mm.size(), big])
	else:
		env.fog_enabled = true
		env.fog_density = 0.0003
		env.fog_sky_affect = 0.0
		env.fog_light_color = Color(0.35, 0.33, 0.32)
		notes.append("env: %d asteroids, dust haze as plain distance fog (no volumetric fog in Compatibility)" % data["rocks"].size())
	return true


func _load_rock(path: String) -> Mesh:
	if not FileAccess.file_exists(path):
		return null
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	st.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	if doc.append_from_file(path, st) != OK:
		return null
	for tex in st.get_images():
		if tex is ImageTexture:
			var img: Image = tex.get_image()
			if img != null and not img.is_empty() and not img.has_mipmaps():
				img.generate_mipmaps()
				(tex as ImageTexture).set_image(img)
	var root := doc.generate_scene(st)
	var mesh: Mesh = null
	var stack: Array = [root]
	while not stack.is_empty() and mesh == null:
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		stack.append_array(n.get_children())
	root.free()
	return mesh


# Slow tumbling: each rock turns about its own axis at its own rate (deterministic from the clock).
func update(t: float) -> void:
	for e in rocks:
		(e["node"] as Node3D).transform = Transform3D(Basis(e["axis"], e["rate"] * t) * e["rot"] * Basis.from_scale(Vector3.ONE * e["scale"]), e["pos"])
	for name in _mm:
		var mm: MultiMesh = (_mm[name] as MultiMeshInstance3D).multimesh
		var list: Array = _mm_rocks[name]
		for i in list.size():
			var e: Dictionary = list[i]
			mm.set_instance_transform(i, Transform3D(Basis(e["axis"], e["rate"] * t) * e["rot"] * Basis.from_scale(Vector3.ONE * e["scale"]), e["pos"]))


func _v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
