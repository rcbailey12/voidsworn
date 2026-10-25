extends Node3D
# Jolt rigid bodies for the max mode (SPEC.md, trimmed scope): impact and breach debris and the destruction chunks are
# real bodies that bounce off the hulls (one convex collider per ship, moving with it) and off each other, and drift.
# Godot's built-in Jolt (project setting physics/3d/physics_engine), zero gravity.

const HULL_LAYER := 1
const DEBRIS_LAYER := 2

const FX := preload("res://fx.gd")
const DEBRIS_BODY := """
shader_type spatial;
render_mode cull_disabled;
global uniform float scene_t;
instance uniform float spawn_t = -100.0;
varying vec3 lp;
""" + FX.EMBER + """
void vertex() {
	lp = VERTEX;
}
void fragment() {
	ALBEDO = vec3(0.11, 0.105, 0.10);
	METALLIC = 0.65;
	ROUGHNESS = 0.5;
	EMISSION = ember(lp, exp(-max(scene_t - spawn_t, 0.0) / 0.9));
}
"""
const DEBRIS_BODY_COMPAT := """
shader_type spatial;
render_mode cull_disabled;
void fragment() {
	ALBEDO = vec3(0.11, 0.105, 0.10);
	METALLIC = 0.65;
	ROUGHNESS = 0.5;
}
"""

var now := 0.0
var pool: Array = []
var next := 0
var cap := 600
var _shapes: Array = []
var _meshes: Array = []
var _mat: ShaderMaterial
var _bounce: PhysicsMaterial
var _rng := RandomNumberGenerator.new()


func setup(ships: Array, max_bodies: int) -> void:
	cap = max_bodies
	_rng.seed = 77
	_bounce = PhysicsMaterial.new()
	_bounce.bounce = 0.45
	_bounce.friction = 0.4
	# dark hull metal with a few dim glowing specks that cool within a second or two of the throw (per-body spawn time)
	var sh := Shader.new()
	var compat := RenderingServer.get_current_rendering_method() == "gl_compatibility"
	sh.code = DEBRIS_BODY_COMPAT if compat else DEBRIS_BODY
	_mat = ShaderMaterial.new()
	_mat.shader = sh
	# irregular shards (see fx.gd shard_mesh) in three sizes, each with a convex collider from its own corners
	for sz in [0.45, 0.8, 1.2]:
		var sm: Array = FX.shard_mesh(_rng, sz)
		var cs := ConvexPolygonShape3D.new()
		cs.points = sm[1]
		_shapes.append(cs)
		_meshes.append(sm[0])
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


# Asteroids: sphere colliders on one static body (a rock's tumble does not change a sphere).
var _rock_body: StaticBody3D = null


func add_rock(pos: Vector3, radius: float) -> void:
	if _rock_body == null:
		_rock_body = StaticBody3D.new()
		_rock_body.collision_layer = HULL_LAYER
		_rock_body.collision_mask = 0
		_rock_body.physics_material_override = _bounce
		add_child(_rock_body)
	var sh := SphereShape3D.new()
	sh.radius = radius
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = pos
	_rock_body.add_child(cs)


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
	mi.name = "mesh"
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
		var mi := b.get_node("mesh") as GeometryInstance3D
		if _mat.shader.code.contains("instance uniform"):
			mi.set_instance_shader_parameter("spawn_t", now)


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
