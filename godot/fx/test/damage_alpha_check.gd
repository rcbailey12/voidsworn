extends SceneTree
# Issue 569: a see-through hull surface (the Glasswright sail membranes) stays see-through
# after damage takes the surface over. The damage shader must carry the base material's
# alpha; the opaque fleet must stay on the opaque shader.
const HULL := preload("res://fx/fx_hull.gd")
const FX := preload("res://fx/fx.gd")
var failures := 0
var fx
var world: Node3D

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error(why)

func _flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0: s.flush_damage(fx)

func _run() -> void:
	# The imported Glasswright sail: GLTF alphaMode BLEND, base colour factor alpha 0.55.
	# Godot imports that as TRANSPARENCY_ALPHA_DEPTH_PRE_PASS, not plain ALPHA, so test both.
	for mode in [BaseMaterial3D.TRANSPARENCY_ALPHA, BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS]:
		var sail := StandardMaterial3D.new()
		sail.albedo_color = Color(1, 1, 1, 0.55)
		sail.transparency = mode
		sail.cull_mode = BaseMaterial3D.CULL_DISABLED
		var damaged := HULL.damage_material(sail, Transform3D.IDENTITY, {}, 24.0)
		var code: String = damaged.shader.code
		check(code.contains("ALPHA = hull_albedo.a * texture(hull_color, UV).a"), "damage shader carries the sail alpha, mode %d" % mode)
		check(is_equal_approx((damaged.get_shader_parameter("hull_albedo") as Color).a, 0.55), "sail alpha reaches the damage shader, mode %d" % mode)
		check(code.contains("fx_mouth_count"), "damage code still injected, mode %d" % mode)
	# An opaque hull must stay on the opaque path, or the whole fleet would be sorted as glass.
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.4, 0.4, 0.45)
	var solid := HULL.damage_material(steel, Transform3D.IDENTITY, {}, 24.0)
	check(not solid.shader.code.contains("ALPHA ="), "opaque hull keeps the opaque shader")
	check(is_equal_approx((solid.get_shader_parameter("hull_albedo") as Color).a, 1.0), "opaque hull keeps alpha 1")

	# Live path: an opaque hull surface and a transparent sail surface, hurt until the breach
	# rebuild hands every surface to the damage shader.
	world = Node3D.new()
	root.add_child(world)
	var body := Node3D.new()
	world.add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24, 5, 8)
	bm.subdivide_width = 17
	bm.subdivide_depth = 7
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	var plane := PlaneMesh.new()
	plane.size = Vector2(18, 9)
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.get_mesh_arrays())
	var hull_mat := StandardMaterial3D.new()
	hull_mat.albedo_color = Color(0.55, 0.6, 0.58)
	var sail_mat := StandardMaterial3D.new()
	sail_mat.albedo_color = Color(0.85, 1.0, 0.92, 0.55)
	sail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	sail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	am.surface_set_material(0, hull_mat)
	am.surface_set_material(1, sail_mat)
	mi.mesh = am
	body.add_child(mi)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.add_ship("glass", body, {"faction": "ithar", "cls": "Cruiser", "size": 0.8, "meshes": [mi], "shielded": false})
	fx._later.clear()
	var s = fx.ship("glass")
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	s.set_stages(fx, [4, 4, 4])
	_flush(s)
	check(not s._dmg_job.is_empty(), "damage rebuild ran")
	var sail_live: Material = mi.get_active_material(1)
	var hull_live: Material = mi.get_active_material(0)
	check(sail_live is ShaderMaterial, "sail surface took the damage shader")
	check(hull_live is ShaderMaterial, "hull surface took the damage shader")
	if sail_live is ShaderMaterial:
		check((sail_live as ShaderMaterial).shader.code.contains("ALPHA = hull_albedo.a"), "live sail material writes alpha")
		check(is_equal_approx(((sail_live as ShaderMaterial).get_shader_parameter("hull_albedo") as Color).a, 0.55), "live sail keeps its alpha")
	if hull_live is ShaderMaterial:
		check(not (hull_live as ShaderMaterial).shader.code.contains("ALPHA ="), "live hull material stays opaque")
	fx.remove_ship("glass")
	world.queue_free()
	print("DAMAGE_ALPHA failures=%d" % failures)
	await process_frame
	FX.clear_static()
	quit(1 if failures else 0)
