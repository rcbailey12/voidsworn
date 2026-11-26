extends SceneTree
# godot --headless --path godot --script res://fx/test/hit_fragments_check.gd

const BREACH := preload("res://fx/fx_breach.gd")
const FX := preload("res://fx/fx.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "hit_fragments_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _check_mesh(profile: int, template: Array) -> void:
	var label := "Profile %d" % profile
	var points: PackedVector3Array = template[0]
	var normals: PackedVector3Array = template[1]
	var indices: PackedInt32Array = template[2]
	_check(points.size() == FRAGMENTS.VERTICES and normals.size() == points.size(), label + ": shared stride")
	_check(indices == FRAGMENTS.templates()[0][2], label + ": shared index layout")
	var weld := {}
	var ids := PackedInt32Array()
	for p in points:
		if not weld.has(p):
			weld[p] = weld.size()
		ids.append(weld[p])
	var balance := {}
	var uses := {}
	var side_triangles := 0
	var bevel_triangles := 0
	var volume := 0.0
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var normal := (points[c] - points[a]).cross(points[b] - points[a])
		_check(normal.length_squared() > 1e-12 and normal.dot(normals[a] + normals[b] + normals[c]) > 0.0,
			label + ": triangle %d is non-degenerate with outward shading normals" % (i / 3))
		volume += points[a].dot(points[c].cross(points[b])) / 6.0
		if a >= FRAGMENTS.CAP * 2:
			side_triangles += 1
			_check(b >= FRAGMENTS.CAP * 2 and c >= FRAGMENTS.CAP * 2 and absf(normal.normalized().y) < 0.01,
				label + ": wall uses the fracture vertices and has a lateral normal")
		elif (template[3][a] as Vector3).z >= 0.89 and absf(normal.normalized().y) < 0.95:
			bevel_triangles += 1
		var triangle := [ids[a], ids[b], ids[c]]
		for j in 3:
			var u: int = triangle[j]
			var v: int = triangle[(j + 1) % 3]
			var edge := Vector2i(mini(u, v), maxi(u, v))
			uses[edge] = uses.get(edge, 0) + 1
			balance[edge] = balance.get(edge, 0) + (1 if u < v else -1)
	for edge in uses:
		_check(uses[edge] == 2 and balance[edge] == 0, label + ": every welded edge has two opposite uses")
	_check(side_triangles == FRAGMENTS.RIM * 2 * (FRAGMENTS.WALL_RINGS - 1)
		and bevel_triangles >= FRAGMENTS.RIM and volume > 0.01, label + ": bevels and a layered wall enclose real volume")


func _check_bursts(fx) -> void:
	var pool: FRAGMENTS.Pool = fx.pools["plate"]
	var legacy_rng := RandomNumberGenerator.new()
	legacy_rng.state = fx.rng.state
	# The old recipe used ten draws per chip, including the direction, tumble axis and phase.
	for i in 7 * 10:
		legacy_rng.randf()
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "hegemony", true)
	_check(fx.rng.state == legacy_rng.state, "Later effects keep their seeded random sequence")
	var macro_pieces: int = pool.emitted
	_check(macro_pieces > 7, "Macro adds fragments over the seven-piece burst")
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "ithar", true)
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "corsair")
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "chorus")
	_check(pool.emitted == 2 * macro_pieces + 7 and fx.pools["smk"].emitted == 4, "Other hits keep seven pieces. Chorus emits four sprites.")
	var first_slot := 0
	for faction in ["hegemony", "ithar", "corsair"]:
		var count := 7 if faction == "corsair" else macro_pieces
		var paint: Color = fx.faction_info(faction).fragment_paint
		var floor_count := 0
		for j in count:
			var particle := pool.particles[first_slot + j]
			var key := int(particle[18])
			var profile := -1 - key if key < 0 else key
			_check((profile >= FRAGMENTS.GLASS) == (faction == "ithar"), "The target picks the fragment mesh family")
			var packed_paint := Color(particle[0], particle[1], particle[2])
			_check(packed_paint.is_equal_approx(paint), "The target supplies the outer hull paint")
			_check(particle[9] > 0.0, "The fragment leaves the face outward")
			if key < 0:
				floor_count += 1
		_check(floor_count == 2, "Only the lead pieces get the full screen-size floor")
		var first := pool.particles[first_slot]
		var chip := pool.particles[first_slot + 2]
		_check(first[16] > chip[16] and absf(first[15]) < absf(chip[15])
			and _velocity(first).length() < _velocity(chip).length(),
			"Lead piece is larger, slower and tumbles more gently than a chip")
		first_slot += count


func _velocity(data: PackedFloat32Array) -> Vector3:
	return Vector3(data[8], data[9], data[10])


func _check_sparks(fx) -> void:
	var streaks: POOLS.Pool = fx.pools["stk"]
	var glow: POOLS.Pool = fx.pools["spr"]
	var glow_before: int = glow.emitted
	WEAP._throw_sparks(fx, Vector3.ZERO, Vector3.UP, Vector3.UP, 1.0, 1.0, "voidsworn", 4, 28.0, 0.45, "shell")
	_check(streaks.emitted == 6 and glow.emitted == glow_before, "Each hull spark uses one analytic streak")
	var stride: int = POOLS.STRIDE * streaks.vpp
	_check(streaks.pending[19] == 8.0 and streaks.pending[stride + 19] == 8.0
		and streaks.pending[16] != streaks.pending[stride + 16], "Hull sparks use distinct motion-trail lengths")
	WEAP._throw_sparks(fx, Vector3.ZERO, Vector3.UP, Vector3.UP, 1.0, 1.0, "voidsworn", 4, 28.0, 0.45, "shield")
	_check(glow.emitted == glow_before and streaks.emitted == 12 and streaks.pending[6 * stride + 19] == 8.0,
		"Shield breakup spray uses the same analytic streak without a duplicate sprite")


func _swatch(color: Color) -> ImageTexture:
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


func _check_finish(fx) -> void:
	var target := Node3D.new()
	root.add_child(target)
	target.position = Vector3(4, 3, 2)
	var maps := [_swatch(Color.CORAL), _swatch(Color(1, 0.35, 0.75)), _swatch(Color(0.51, 0.53, 1))]
	var hull_mat := ORMMaterial3D.new()
	hull_mat.albedo_texture = maps[0]
	hull_mat.orm_texture = maps[1]
	hull_mat.normal_enabled = true
	hull_mat.normal_texture = maps[2]
	var other_paint := StandardMaterial3D.new()
	other_paint.albedo_texture = _swatch(Color.BLUE)
	var mesh := ArrayMesh.new()
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT * 2, Vector3.BACK * 2])
	surface[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75)])
	surface[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	mesh.surface_set_material(0, other_paint)
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.UP, Vector3.UP + Vector3.RIGHT * 2, Vector3.UP + Vector3.BACK * 2])
	surface[Mesh.ARRAY_INDEX] = null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	mesh.surface_set_material(1, other_paint)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(1, hull_mat)
	target.add_child(mi)
	# A separate fitting adds strip faces before the two hull surfaces in the hit BVH.
	var strip_mesh := ArrayMesh.new()
	surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.BACK, Vector3.RIGHT + Vector3.BACK])
	surface[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE])
	strip_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, surface)
	strip_mesh.surface_set_material(0, other_paint)
	var fitting := MeshInstance3D.new()
	fitting.mesh = strip_mesh
	fitting.position.x = -3.0
	target.add_child(fitting)
	fx.add_ship("textured", target, {"meshes": [fitting, mi], "shielded": false})
	var strip_hit := FRAGMENTS.source(fx.ships["textured"], fitting.global_position + Vector3(0.75, 0, 0.75), Vector3.UP)
	var strip_maps: Array = strip_hit.get("maps", [])
	_check(not strip_maps.is_empty() and strip_maps[0] == other_paint.albedo_texture
		and (strip_hit.get("uv", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(0.75, 0.75)),
		"The second face of a triangle strip supplies its own paint and UVs")
	var p := target.global_position + Vector3(0.5, 1, 0.5)
	var finish := FRAGMENTS.source(fx.ships["textured"], p, Vector3.UP)
	_check(finish.get("maps") == maps, "The struck surface supplies its exact color, ORM and normal textures")
	var uv: Vector2 = finish.get("uv", Vector2.ZERO)
	_check(uv.is_equal_approx(Vector2(0.375, 0.375)), "The texture patch is centred on the hit triangle's UV")
	var pool: FRAGMENTS.Pool = fx.pools["plate"]
	var slot := pool.particles.size()
	WEAP._throw_debris(fx, p, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "hegemony", true, fx.ships["textured"])
	_check(pool.particles[slot][26] >= 0 and is_equal_approx(pool.particles[slot][20], uv.x),
		"The live burst packs the struck UV and its bound finish")
	var mat := pool.mi.material_override as ShaderMaterial
	_check(mat.get_shader_parameter("hull_color_0") == maps[0] and mat.get_shader_parameter("hull_orm_0") == maps[1]
		and mat.get_shader_parameter("hull_normal_0") == maps[2], "The one draw binds the target's full-resolution textures")
	pool.flush(2.1)
	_check(pool.mi.multimesh.visible_instance_count == pool.particles.size(), "Only living slots enter the draw")
	pool.flush(10.0)
	_check(pool.particles.is_empty() and pool.mi.multimesh.visible_instance_count == 0, "Expired pieces leave the draw")
	_check_dent(fx, fx.ships["textured"], mi, p, finish)
	fx.remove_ship("textured")
	target.free()


func _check_dent(fx, ship, mi: MeshInstance3D, p: Vector3, before: Dictionary) -> void:
	var intact := mi.mesh as ArrayMesh
	var dent := BREACH.dent(Vector3(0.5, 0, 0.15), Vector3.UP, 0.6, 0.12, 0.3)
	ship._marks.append(dent)
	ship._dmg_request(fx)
	ship.flush_damage(fx)
	var dented := mi.mesh as ArrayMesh
	_check(dented != intact and dented.surface_get_array_index_len(0) > intact.surface_get_array_index_len(0),
		"The real dent rebuild adds triangles before the second surface")
	_check(mi.get_active_material(1) is ShaderMaterial, "The damage shader took over the second surface's paint")
	var after := FRAGMENTS.source(ship, p, Vector3.UP)
	_check(after.get("maps") == before.get("maps"), "A hit after the dent still takes the second surface's paint override")
	_check((after.get("uv", Vector2.ZERO) as Vector2).is_equal_approx(Vector2(0.375, 0.375)),
		"A hit after the dent still uses the second surface's UVs")


func _run() -> void:
	var templates := FRAGMENTS.templates()
	_check(templates.size() >= 12 and FRAGMENTS.RIM >= 24 and FRAGMENTS.VERTICES >= 300,
		"Twelve detailed profiles with densely broken rims")
	for profile in templates.size():
		_check_mesh(profile, templates[profile])
	for quality in ["max", "high", "low"]:
		var fx := FX.new()
		root.add_child(fx)
		fx.manual = true
		fx.setup({"quality": quality})
		var pool: FRAGMENTS.Pool = fx.pools["plate"]
		_check(pool.cap == (384 if quality == "max" else 192), "Original pool capacity at " + quality)
		_check(pool.mi.multimesh.mesh.get_surface_count() == 1
			and pool.mi.multimesh.mesh.surface_get_array_len(0) == FRAGMENTS.VERTICES, "One mesh surface uses the detailed layout")
		if quality == "max":
			_check_bursts(fx)
			_check_sparks(fx)
			_check_finish(fx)
		fx.free()
	print("PASS hit fragment topology, target textures before and after a dent, and burst pool" if failures == 0 else "FAIL hit fragments: %d" % failures)
	quit(0 if failures == 0 else 1)
