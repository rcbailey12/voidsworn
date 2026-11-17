extends SceneTree
# godot --headless --path godot --script res://tests/hit_fragments_check.gd

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
	var volume := 0.0
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var normal := (points[c] - points[a]).cross(points[b] - points[a])
		_check(normal.length_squared() > 1e-8 and normal.dot(normals[a] + normals[b] + normals[c]) > 0.0,
			label + ": non-degenerate triangle with outward shading normals")
		volume += points[a].dot(points[c].cross(points[b])) / 6.0
		if a >= FRAGMENTS.CAP * 2:
			side_triangles += 1
			_check(b >= FRAGMENTS.CAP * 2 and c >= FRAGMENTS.CAP * 2 and absf(normal.normalized().y) < 0.01,
				label + ": wall uses the fracture vertices and has a lateral normal")
		var triangle := [ids[a], ids[b], ids[c]]
		for j in 3:
			var u: int = triangle[j]
			var v: int = triangle[(j + 1) % 3]
			var edge := Vector2i(mini(u, v), maxi(u, v))
			uses[edge] = uses.get(edge, 0) + 1
			balance[edge] = balance.get(edge, 0) + (1 if u < v else -1)
	for edge in uses:
		_check(uses[edge] == 2 and balance[edge] == 0, label + ": every welded edge has two opposite uses")
	_check(side_triangles == FRAGMENTS.RIM * 2 and volume > 0.01, label + ": closed piece with real thickness")


func _check_bursts(fx) -> void:
	var pool: POOLS.Pool = fx.pools["plate"]
	var legacy_rng := RandomNumberGenerator.new()
	legacy_rng.state = fx.rng.state
	# The old recipe used ten draws per chip, including the direction, tumble axis and phase.
	for i in 7 * 10:
		legacy_rng.randf()
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "hegemony")
	_check(fx.rng.state == legacy_rng.state, "Later effects keep their seeded random sequence")
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "ithar")
	WEAP._throw_debris(fx, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, 2.0, 1.0, 4, 11.0, 0.16, 0.7, "shell", "chorus")
	_check(pool.emitted == 14 and fx.pools["smk"].emitted == 4, "Metal and glass preserve the seven-piece count. Chorus emits four sprites.")
	# Each pending slot repeats its 20 packed attributes for every template vertex.
	var stride: int = pool.vpp * POOLS.STRIDE
	for burst in 2:
		var floor_count := 0
		for j in 7:
			var i := (burst * 7 + j) * stride
			var key := int(pool.pending[i + 18])
			var profile := -1 - key if key < 0 else key
			_check((profile >= FRAGMENTS.GLASS) == (burst == 1), "The target picks the fragment mesh family")
			_check(pool.pending[i + 9] > 0.0, "The fragment leaves the face outward")
			if key < 0:
				floor_count += 1
		_check(floor_count == 2, "Only the lead pieces get a screen-size floor")
		var first := burst * 7 * stride
		var chip := first + 2 * stride
		_check(pool.pending[first + 16] > pool.pending[chip + 16]
			and absf(pool.pending[first + 15]) < absf(pool.pending[chip + 15])
			and absf(pool.pending[first + 8]) < absf(pool.pending[chip + 8]),
			"Lead piece is larger, slower and tumbles more gently than a chip")


func _run() -> void:
	var templates := FRAGMENTS.templates()
	for profile in templates.size():
		_check_mesh(profile, templates[profile])
	for quality in ["max", "high", "low"]:
		var fx := FX.new()
		root.add_child(fx)
		fx.manual = true
		fx.setup({"quality": quality})
		var pool: POOLS.Pool = fx.pools["plate"]
		_check(pool.cap == (384 if quality == "max" else 192), "Original pool capacity at " + quality)
		_check(pool.vpp == FRAGMENTS.VERTICES, "The live pool uses the shared template stride")
		if quality == "max":
			_check_bursts(fx)
		fx.free()
	print("PASS hit fragment topology, side walls, burst and pool sizes" if failures == 0 else "FAIL hit fragments: %d" % failures)
	quit(0 if failures == 0 else 1)
