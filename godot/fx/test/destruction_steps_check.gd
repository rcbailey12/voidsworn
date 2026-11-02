extends SceneTree
# Geometry contract: every open edge of the existing triangle buckets is sealed,
# including mirrored meshes, multiple surfaces and disconnected openings.
const DEATH := preload("res://fx/fx_death.gd")
const HULL := preload("res://fx/fx_hull.gd")
const BREACH := preload("res://fx/fx_breach.gd")
var failures := 0

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	DEATH._init_dirs()
	# The cut cap can include pre-existing breach rims. A more camera-facing
	# breach must never attract the split's core flash or edge fires.
	var sites := DEATH._edge_sites({"edge": PackedVector3Array([Vector3(0.1, 1, 0), Vector3(8, 5, 0)]),
		"split_at": Vector3.ZERO, "split_axis": Vector3.RIGHT, "split_width": 0.5}, Vector3.ZERO, Vector3.UP, 1)
	_check(sites[0].x < 0.5, "split effects reject unrelated breach rims")
	for mirrored in [false, true]:
		for disconnected in [false, true]:
			var bm := BoxMesh.new()
			bm.size = Vector3(12, 4, 6)
			bm.subdivide_width = 7
			bm.subdivide_height = 3
			bm.subdivide_depth = 4
			var surfaces: Array = []
			for i in (2 if disconnected else 1):
				var xf := Transform3D(Basis.from_scale(Vector3(1, 1, -1 if mirrored else 1)), Vector3(0, i * 8, 0))
				surfaces.append({"arrays": bm.get_mesh_arrays(), "xf": xf, "mat": StandardMaterial3D.new(), "fmt": 0})
			var job := {"seeds": PackedVector3Array([Vector3(-4, 0, 0), Vector3(1, 0, 0), Vector3(5, 0, 0)]), "surfs": surfaces}
			var pieces := DEATH._cut(job)
			DEATH._piece_hulls(pieces)
			for pc in pieces:
				_check(not pc["pts"].is_empty() and not pc["hull"].is_empty(), "piece retains surface samples and collider extrema")
				_check((pc["cen"] as Vector3).is_finite(), "piece centre is finite")
				_check(pc.has("cap"), "piece has an opaque cap")
				if not pc.has("cap"): continue
				var edges := {}
				for sd in pc["surfs"]:
					_count_edges(edges, sd["arrays"])
				_count_edges(edges, pc["cap"])
				var open := 0
				for key in edges:
					if int(edges[key]) % 2 != 0: open += 1
				_check(open == 0, "sealed mesh has no unmatched edges: %d" % open)
				_check((pc["cap"][Mesh.ARRAY_VERTEX] as PackedVector3Array).size() > int(pc["boundary_edges"]) * 3, "cap includes thickness bands and ribs")
			print("DESTRUCTION_GEOMETRY mirror=%s disconnected=%s pieces=%d" % [mirrored, disconnected, pieces.size()])
	# A concave cut must cover its outline, without a shared centre-point fan.
	var outline := PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 4, 0), Vector3(0, 4, 1),
		Vector3(0, 1, 1), Vector3(0, 1, 4), Vector3(0, 0, 4)])
	var cap := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()}
	var pc := {"cap_loops": 0, "cap_fallbacks": 0}
	DEATH._cap_outline(cap, outline, AABB(Vector3(-6, 0, 0), Vector3(6, 4, 4)), 0.000001, pc)
	_check(pc["cap_fallbacks"] == 0, "concave outline uses polygon triangulation")
	var area := 0.0
	for i in range(0, (outline.size() - 2) * 3, 3):
		var p: PackedVector3Array = cap["v"]
		var a := Vector2(p[i].y, p[i].z)
		var b := Vector2(p[i + 1].y, p[i + 1].z)
		var c := Vector2(p[i + 2].y, p[i + 2].z)
		area += absf((b - a).cross(c - a)) * 0.5
	_check(absf(area - 7.0 * 0.982 * 0.982) < 0.001, "concave cap covers exactly the recessed outline")
	# The material keeps actual imported texture resources and never nests wrappers.
	var material := ORMMaterial3D.new()
	material.albedo_color = Color(0.2, 0.3, 0.4)
	var normal := PlaceholderTexture2D.new()
	material.normal_enabled = true
	material.normal_texture = normal
	var mat := HULL.damage_material(material, Transform3D.IDENTITY, {}, 24.0)
	_check(mat.get_shader_parameter("hull_has_orm") == true, "ORM flag retained")
	_check(mat.get_shader_parameter("hull_normal") == normal, "normal texture retained")
	var again := HULL.damage_material(mat, Transform3D.IDENTITY, {}, 24.0)
	_check(again.get_meta("fx_hull_source") == material, "no wrapper stacking")
	var hole := BREACH.hole(null, Vector3.ZERO, Vector3.UP, 1.0, 0.8, 0.1, 73.0)
	var mouth := BREACH._mouth_uniforms([hole])
	var cut := HULL.damage_material(material, Transform3D.IDENTITY, mouth, 24.0)
	_check(cut.get_shader_parameter("fx_mouth_count") == 1, "live breach has a shader cut")
	_check(again.get_shader_parameter("fx_mouth_count") == 0, "wreck/repair material has no stale shader cuts")
	var owner := Node3D.new()
	root.add_child(owner)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = am
	mi.material_override = material
	owner.add_child(mi)
	var state := {"dead": false, "_dmg_root": owner, "hull": {"L": 24.0}}
	BREACH._inside_overlay(null, state, [mi], [hole], Color.WHITE)
	_check(mi.material_override == null, "global override cannot hide shader cuts")
	_check(mi.get_active_material(0).get_meta("fx_hull_source") == material, "global override texture source retained")
	BREACH._restore_overrides(mi, [{"ov": null, "si": 0, "global_ov": material}], [0])
	BREACH._inside_overlay(null, state, [mi], [], Color.WHITE)
	_check(mi.get_active_material(0).get_meta("fx_hull_source") == material, "source retained after repair/rebuild")
	_check(mi.get_active_material(0).get_shader_parameter("fx_mouth_count") == 0, "repair removes live cuts")
	print("DESTRUCTION_STEPS failures=%d" % failures)
	if OS.get_environment("DESTRUCTION_OUT") != "":
		await _sealed_stills()
	quit(1 if failures > 0 else 0)

func _sealed_stills() -> void:
	load("res://fx/fx.gd").register_globals()
	var out := OS.get_environment("DESTRUCTION_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 540)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.065, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.4
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	world.add_child(key)
	key.rotation_degrees = Vector3(-55, -30, 0)
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	cam.look_at_from_position(Vector3(17, 11, 18), Vector3.ZERO, Vector3.UP)
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 4, 6)
	bm.subdivide_width = 15
	bm.subdivide_height = 3
	bm.subdivide_depth = 4
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.34, 0.4)
	var pieces := DEATH._cut({"seeds": PackedVector3Array([Vector3(-4, 0, 0), Vector3(1, 0, 0), Vector3(5, 0, 0)]),
		"surfs": [{"arrays": bm.get_mesh_arrays(), "xf": Transform3D.IDENTITY, "mat": m, "fmt": 0}]})
	for i in pieces.size():
		var mi := MeshInstance3D.new()
		mi.mesh = DEATH._piece_mesh(pieces[i])
		mi.position.x = (i - 1) * 2.7
		world.add_child(mi)
	for state in ["hot", "cold"]:
		for pc in pieces:
			(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("heat", 1.0 if state == "hot" else 0.0)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		vp.get_texture().get_image().save_png(out.path_join("sealed_" + state + ".png"))
	print("DESTRUCTION_STILLS wrote hot/cold opaque caps")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _count_edges(edges: Dictionary, arr: Array) -> void:
	var p: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx := PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null: idx = arr[Mesh.ARRAY_INDEX]
	else:
		for i in p.size(): idx.append(i)
	for t in range(0, idx.size() - 2, 3):
		for j in 3:
			var a := p[idx[t + j]]
			var b := p[idx[t + (j + 1) % 3]]
			_check(a.is_finite() and b.is_finite(), "finite cap vertices")
			var ka := Vector3i((a * 10000.0).round())
			var kb := Vector3i((b * 10000.0).round())
			if ka == kb: continue
			var key: Array = [ka, kb] if ka < kb else [kb, ka]
			edges[key] = int(edges.get(key, 0)) + 1
