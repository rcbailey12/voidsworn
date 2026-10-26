extends SceneTree
# A4 check: load A4 ship glb files with Godot's own GLTFDocument (as an importer would) and print nodes, metadata, meshes and materials.
# usage: godot --headless --path <any project folder> --script godot_check.gd -- FILE.glb [...]   (Godot 4.7.2 headless runs in the cloud too)
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for path in args:
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		var err := doc.append_from_file(path, st)
		print("FILE ", path, " err ", err)
		if err != OK:
			continue
		var root := doc.generate_scene(st)
		_walk(root, 0)
		root.free()
	quit()

func _walk(n: Node, d: int) -> void:
	var pad := "  ".repeat(d)
	var line := pad + n.name + " (" + n.get_class() + ")"
	if n is Node3D:
		line += " pos " + str((n as Node3D).position) + " fwd " + str(-(n as Node3D).basis.z)
	if n.has_meta("extras"):
		line += " extras " + str(n.get_meta("extras"))
	if n is MeshInstance3D:
		var m: Mesh = (n as MeshInstance3D).mesh
		line += " surfaces %d aabb %s" % [m.get_surface_count(), str(m.get_aabb())]
		for s in m.get_surface_count():
			var mat := m.surface_get_material(s) as StandardMaterial3D
			if mat:
				line += " | mat %s albedo_tex %s normal %s orm %s emis %s x%.1f" % [mat.resource_name, mat.albedo_texture != null, mat.normal_enabled, mat.roughness_texture != null, mat.emission_enabled, mat.emission_energy_multiplier]
	line += " kids %d" % n.get_child_count()
	if d < 3 or n is MeshInstance3D:
		print(line)
	for c in n.get_children():
		_walk(c, d + 1)
