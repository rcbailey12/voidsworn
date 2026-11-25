extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const SHIELD_CACHE := preload("res://fx/fx_shield_cache.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SV := preload("res://render/ship_view.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "shield_cache_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _register(mesh: Mesh, facing: float, bob: float) -> Dictionary:
	var view := SV.new()
	root.add_child(view)
	view.code = "shield_fixture"
	view.rotation.y = facing
	view.position = Vector3(122, 0, -69)
	view.hull = Node3D.new()
	view.add_child(view.hull)
	view.hull.position.y = bob
	var part := MeshInstance3D.new()
	part.mesh = mesh
	view.hull.add_child(part)
	var core := Node3D.new()
	core.name = "hp_core"
	view.hull.add_child(core)
	var ship := SHIP.new()
	ship.root = view
	ship.meshes = [part]
	ship.hull = HULL.new()
	ship.hull.code = view.code
	ship.hull.analyse(view, ship.meshes, 1)
	var skin := ship._shield_skin()
	var hit := ship.shield_point(view.to_global(Vector3(0, 10, 0)))
	var result := {"bounds": ship.hull.box, "triangles": ship.hull.tri_count, "core": ship.hull.core,
		"skin": skin.get_faces() if skin != null else PackedVector3Array(),
		"hit": view.to_local(hit.p)}
	view.free()
	return result


func _prune_check() -> void:
	var dir := "user://shield_cache_prune_test"
	DirAccess.make_dir_recursive_absolute(dir)
	var paths: Array = []
	for i in 3:
		var path := dir.path_join("entry%d.bin" % i)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			_check(false, "could not write a prune fixture entry")
			return
		f.store_string("x".repeat(1000))
		f.close()
		paths.append(path)
		if i < 2:
			OS.delay_msec(1100)
	# issue 2172: three 1000 byte entries against a 1500 byte cap keep the newest and drop both older ones
	SHIELD_CACHE._prune_dir(dir, str(paths[2]), 1500)
	_check(not FileAccess.file_exists(str(paths[0])) and not FileAccess.file_exists(str(paths[1])) and FileAccess.file_exists(str(paths[2])),
		"the disk cache drops its oldest entries down to the size cap and keeps the newest")
	for path in paths:
		DirAccess.remove_absolute(str(path))
	DirAccess.remove_absolute(dir)


func _run() -> void:
	var box := BoxMesh.new()
	box.size = Vector3(12, 3, 4)
	var first := _register(box, 0.0, 0.0)
	var key: String = SHIP._shield_skin_arrays.keys()[0]
	var baked := SHIP._bake_shield_skin(box.get_aabb(), box.get_faces())
	SHIP._shield_skin_arrays.clear()
	_check(var_to_bytes(SHIELD_CACHE.read_skin(key)) == var_to_bytes(baked),
		"disk cache retains every fitted shield vertex attribute")
	var turned := _register(box, TAU / 3.0, 0.0)
	var bobbed := _register(box, TAU / 3.0, 0.25)
	_check(SHIP._shield_skin_arrays.size() == 1, "facing and idle bob share a single cache entry")
	_check(not first.skin.is_empty() and first.skin == turned.skin and first.skin == bobbed.skin,
		"facing and idle bob keep the same fitted contour relative to the core")
	_check((bobbed.hit as Vector3).is_equal_approx((first.hit as Vector3) + Vector3.UP * 0.25),
		"the ray contact moves with the visible skin at registration")
	var arrays := box.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		if verts[i].x > 0.0 and verts[i].y > 0.0:
			verts[i].y *= 0.5
	arrays[Mesh.ARRAY_VERTEX] = verts
	var replacement := ArrayMesh.new()
	replacement.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var revised := _register(replacement, 0.0, 0.0)
	_check(first.bounds == revised.bounds and first.core == revised.core and first.triangles == revised.triangles,
		"replacement fixture collides under the original cache key")
	_check(SHIP._shield_skin_arrays.size() == 2 and not revised.skin.is_empty() and revised.skin != first.skin,
		"changed geometry with the same old key gets its own contour")
	var oldest = SHIP._shield_skin_arrays.keys()[0]
	for i in range(SHIP._shield_skin_arrays.size(), SHIP.SHIELD_SKIN_CACHE_LIMIT):
		SHIP._shield_skin_arrays[i] = []
	box.size.z += 0.5
	_register(box, 0.0, 0.0)
	_check(SHIP._shield_skin_arrays.size() == SHIP.SHIELD_SKIN_CACHE_LIMIT and not SHIP._shield_skin_arrays.has(oldest),
		"a new contour evicts the oldest entry when the cache is full")
	SHIP._shield_skin_arrays.clear()
	var puff := weakref(SV._puff_mat())
	var texture := weakref(SV._pm.albedo_texture)
	_check(puff.get_ref() != null and texture.get_ref() != null, "the live puff cache holds both resources")
	SV.clear_static()
	_check(puff.get_ref() == null and texture.get_ref() == null, "shutdown releases the cached puff material and texture")
	_check(SV._puff_mat().albedo_texture != null, "the puff material can be built again after cleanup")
	SV.clear_static()
	_prune_check()
	print("Shield cache and puff cleanup failures=%d" % failures)
	quit(0 if failures == 0 else 1)
