extends RefCounted
# Short-lived status and boarding paths all play on the battle effects clock.

const TUBE := preload("res://render/fx_conduit.gd")
const LIMIT := 96
var live: Array[Dictionary] = []


static func anchor(ship, local: Vector3) -> Callable:
	return func() -> Vector3:
		return ship.to_world(local) if not ship.dead and not ship.gone and is_instance_valid(ship.root) else Vector3.INF


func add(fx, tag: String, points: PackedVector3Array, radii: PackedFloat32Array, tint: Color, core: Color,
		style: int, pixels: float, start: float, end: float, first := Callable(), last := Callable()) -> Dictionary:
	if end <= start or points.size() < 2:
		return {}
	if live.size() >= LIMIT:
		live.pop_front()["node"].queue_free()
	var node := TUBE.make(fx, points, radii, tint, core, style, pixels)
	node.name = "fx_" + tag
	node.top_level = true
	fx.add_child(node)
	node.global_transform = Transform3D.IDENTITY
	node.hide()
	var row := {"node": node, "path": points, "start": start, "end": end, "first": first, "last": last,
		"pod": null, "tag": tag}
	live.append(row)
	return row


func step(now: float) -> void:
	for i in range(live.size() - 1, -1, -1):
		var row := live[i]
		var node: MeshInstance3D = row.node
		if not is_instance_valid(node):
			live.remove_at(i)
			continue
		var first: Callable = row.first
		var last: Callable = row.last
		var path: PackedVector3Array = row.path
		var a: Vector3 = first.call() if first.is_valid() else path[0]
		var b: Vector3 = last.call() if last.is_valid() else path[-1]
		if now >= row.end or not a.is_finite() or not b.is_finite():
			node.queue_free()
			live.remove_at(i)
			continue
		if now < row.start:
			continue
		var t: float = (now - row.start) / (row.end - row.start)
		var gain := smoothstep(0.0, 0.14, t) * (1.0 - smoothstep(0.82, 1.0, t))
		var da := a - path[0]
		var db := b - path[-1]
		var mat := node.material_override as ShaderMaterial
		mat.set_shader_parameter("first_shift", da)
		mat.set_shader_parameter("last_shift", db)
		mat.set_shader_parameter("phase", t)
		mat.set_shader_parameter("gain", gain)
		node.show()
		var pod: MeshInstance3D = row.pod
		if is_instance_valid(pod):
			# Staggering comes from the start of each cable. The pod has weight as it leaves and brakes at the cut.
			var u := smoothstep(0.13, 0.87, t)
			pod.visible = t > 0.13 and t < 0.92
			var p := _at(path, u) + da.lerp(db, u)
			var lo := maxf(0.0, u - 0.01)
			var hi := minf(1.0, u + 0.01)
			var axis := (_at(path, hi) + da.lerp(db, hi) - _at(path, lo) - da.lerp(db, lo)).normalized()
			pod.position = p
			if axis.length_squared() > 0.01:
				var up := Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.99 else Vector3.UP
				pod.basis = Basis.looking_at(axis, up) * Basis(Vector3.UP, PI * 0.5)
			var skin := pod.material_override as ShaderMaterial
			skin.set_shader_parameter("gain", gain)
			skin.set_shader_parameter("phase", t * 0.25)


static func _at(points: PackedVector3Array, u: float) -> Vector3:
	var f := u * float(points.size() - 1)
	var i := mini(int(f), points.size() - 2)
	return points[i].lerp(points[i + 1], f - i)


func clear() -> void:
	for row in live:
		if is_instance_valid(row.node):
			row.node.queue_free()
	live.clear()
