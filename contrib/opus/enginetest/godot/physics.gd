extends Node3D
# Jolt rigid bodies for the max mode (SPEC.md, trimmed scope): impact and breach debris and the destruction chunks are
# real bodies that bounce off the hulls (one convex collider per ship, moving with it) and off each other, and drift.
# Godot's built-in Jolt (project setting physics/3d/physics_engine), zero gravity.

const HULL_LAYER := 1
const DEBRIS_LAYER := 2

var pool: Array = []
var next := 0
var cap := 600
var _shapes: Array = []
var _meshes: Array = []
var _mat: StandardMaterial3D
var _bounce: PhysicsMaterial
var _rng := RandomNumberGenerator.new()


func setup(ships: Array, max_bodies: int) -> void:
	cap = max_bodies
	_rng.seed = 77
	_bounce = PhysicsMaterial.new()
	_bounce.bounce = 0.45
	_bounce.friction = 0.4
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.13, 0.12, 0.11)
	_mat.metallic = 0.55
	_mat.roughness = 0.55
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.35, 0.06)
	_mat.emission_energy_multiplier = 0.35
	for sz in [0.25, 0.45, 0.8]:
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.0, 0.18, 0.6) * sz
		_shapes.append(bs)
		var bm := BoxMesh.new()
		bm.size = bs.size
		_meshes.append(bm)
	for s in ships:
		add_hull(s)


# One convex hull per ship from its own vertices (a spread-out subset), on an AnimatableBody3D that rides the ship root.
func add_hull(s: Dictionary) -> void:
	var pts: PackedVector3Array = s.get("pts", PackedVector3Array())
	if pts.size() < 8 or not s.has("root"):
		return
	var sub := PackedVector3Array()
	var step := maxi(1, pts.size() / 600)
	for i in range(0, pts.size(), step):
		sub.append(pts[i])
	var shape := ConvexPolygonShape3D.new()
	shape.points = sub
	var body := AnimatableBody3D.new()
	body.sync_to_physics = false
	body.collision_layer = HULL_LAYER
	body.collision_mask = 0
	body.physics_material_override = _bounce
	var cs := CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	(s["root"] as Node3D).add_child(body)


func _new_body(size_class: int) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.gravity_scale = 0.0
	b.mass = 0.2 + 0.4 * size_class
	b.linear_damp = 0.0
	b.angular_damp = 0.05
	b.can_sleep = false
	b.collision_layer = DEBRIS_LAYER
	b.collision_mask = HULL_LAYER | DEBRIS_LAYER
	b.physics_material_override = _bounce
	var cs := CollisionShape3D.new()
	cs.shape = _shapes[size_class]
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = _meshes[size_class]
	mi.material_override = _mat
	b.add_child(mi)
	add_child(b)
	return b


# count bodies at pos, sent out at vel plus a random spread of `spread` u/s; size picks the size class
func spawn(pos: Vector3, vel: Vector3, count: int, size: float, spread := 5.0) -> void:
	var sc := 0 if size < 0.3 else (1 if size < 0.5 else 2)
	for i in count:
		var b: RigidBody3D
		if pool.size() < cap:
			b = _new_body(sc)
			pool.append(b)
		else:
			b = pool[next]
			next = (next + 1) % cap
		var d := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).normalized()
		b.global_transform = Transform3D(Basis(d, _rng.randf() * TAU), pos + d * 0.5)
		b.linear_velocity = vel + d * spread * _rng.randf_range(0.4, 1.0)
		b.angular_velocity = Vector3(_rng.randf_range(-6, 6), _rng.randf_range(-6, 6), _rng.randf_range(-6, 6))
		b.visible = true


func live_bodies() -> int:
	return pool.size()


# The destruction chunks: rigid bodies with a convex hull of the chunk's own vertices, frozen and parked until the break.
func make_chunk(points: PackedVector3Array) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.gravity_scale = 0.0
	b.mass = 40.0
	b.can_sleep = false
	b.collision_layer = DEBRIS_LAYER
	b.collision_mask = HULL_LAYER | DEBRIS_LAYER
	b.physics_material_override = _bounce
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var cs := CollisionShape3D.new()
	cs.shape = shape
	b.add_child(cs)
	b.freeze = true
	b.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	return b


func launch(b: Node3D, xf: Transform3D, vel: Vector3, ang: Vector3) -> void:
	var rb := b as RigidBody3D
	if rb == null:
		return
	rb.freeze = false
	rb.global_transform = xf
	rb.linear_velocity = vel
	rb.angular_velocity = ang
	rb.collision_layer = DEBRIS_LAYER


func park(b: Node3D) -> void:
	var rb := b as RigidBody3D
	if rb == null or rb.freeze:
		return
	rb.freeze = true
	rb.collision_layer = 0
	rb.global_transform = Transform3D(Basis(), Vector3(0, -5000, 0))
