extends Node3D
# Filled set-piece hexes were in SOLID in both rule engines, but had no Godot
# props. These are presentation only; no playable or blocking hex changes.
const WR := preload("res://world/world_rocks.gd")
const A4P := preload("res://assets/ships/a4_props.gd")
var visuals := {}   # hex key -> actual solid node, used by the coverage check

func build(view: Dictionary, hw: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1763
	for hole in view.get("map", {}).get("holes", []):
		var kind := str(hole.get("kind", "asteroid"))
		for cell in hole.get("cells", []):
			var p: Vector3 = hw.call(int(cell[0]), int(cell[1]))
			var key := "%d,%d" % [int(cell[0]), int(cell[1])]
			if kind == "hulk":
				visuals[key] = hulk_fallback(self, p, rng)
			elif kind == "station":
				var station := A4P.station(14.0)
				if station != null:
					add_child(station)
					station.position = p + Vector3.UP * 3.0
					visuals[key] = station
				else:
					visuals[key] = station_fallback(self, p)
			elif kind == "deadstar":
				# Do not cover the lens. The solid exclusion rim marks its rule footprint.
				visuals[key] = outline(self, p, Color(0.58, 0.39, 0.16), 0.25)
			else:
				var mi := MeshInstance3D.new()
				mi.name = "Blocker_" + kind + "_" + key
				mi.mesh = WR.fallback_mesh(key)
				mi.scale = Vector3(8.1, 6.2, 8.1)
				mi.position = p + Vector3.UP * 1.5
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.25, 0.23, 0.19) if kind != "moon" else Color(0.34, 0.32, 0.29)
				mat.roughness = 0.93
				mi.material_override = mat
				add_child(mi)
				visuals[key] = mi
	# The station and planet models are protected in this batch. Show their exact
	# exclusion footprint with solid warm rims, including their otherwise empty edge hexes.
	for key in view.get("terrain", {}):
		var kind: String = view.terrain[key]
		if kind not in ["planet", "station"]: continue
		var qr: PackedStringArray = str(key).split(",")
		var p: Vector3 = hw.call(int(qr[0]), int(qr[1]))
		# Keep the real station model. Missing assets or uncovered edge cells
		# still need solid docking hardware, not just an exclusion outline.
		if kind == "station" and not solid_at(get_parent(), p):
			station_fallback(self, p)
		visuals[key] = outline(self, p, Color(0.48, 0.30, 0.13), 0.25)

static func solid_at(node: Node3D, p: Vector3) -> bool:
	if node is MeshInstance3D and node.mesh != null:
		var bounds: AABB = node.global_transform * node.mesh.get_aabb()
		if p.x >= bounds.position.x and p.x <= bounds.end.x and p.z >= bounds.position.z and p.z <= bounds.end.z: return true
	for child in node.get_children():
		if child is Node3D and solid_at(child, p): return true
	return false

static func station_fallback(parent: Node3D, p: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = "StationDock"
	parent.add_child(node)
	node.position = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.27, 0.22)
	mat.metallic = 0.65
	mat.roughness = 0.7
	for tier in 2:
		var mi := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 5.0 if tier == 0 else 2.1
		mesh.bottom_radius = 5.8 if tier == 0 else 2.5
		mesh.height = 2.4 if tier == 0 else 3.0
		mesh.radial_segments = 12
		mi.mesh = mesh
		mi.material_override = mat
		node.add_child(mi)
		mi.position.y = 1.2 if tier == 0 else 3.5
	return node

static func outline(parent: Node3D, p: Vector3, col: Color, width: float) -> Node3D:
	var node := Node3D.new()
	node.name = "BlockedFootprint"
	parent.add_child(node)
	node.position = p + Vector3.UP * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.65
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	for i in 6:
		var a := Vector3(cos(PI / 6.0 + i * TAU / 6.0), 0, sin(PI / 6.0 + i * TAU / 6.0)) * 9.6
		var b := Vector3(cos(PI / 6.0 + (i + 1) * TAU / 6.0), 0, sin(PI / 6.0 + (i + 1) * TAU / 6.0)) * 9.6
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(width, width * 0.6, a.distance_to(b))
		mi.mesh = mesh
		mi.material_override = mat
		node.add_child(mi)
		mi.position = (a + b) * 0.5
		mi.look_at_from_position(mi.position, b, Vector3.UP, true)
	return node

static func hulk_fallback(parent: Node3D, p: Vector3, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.name = "SolidDerelict"
	parent.add_child(n)
	n.position = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.19, 0.13, 0.09)
	mat.metallic = 0.55
	mat.roughness = 0.85
	for i in 3:
		var mi := MeshInstance3D.new()
		mi.mesh = WR.fallback_mesh("hulk%d" % i)
		mi.scale = Vector3(3.8, 2.2, 2.8)
		mi.position = Vector3((i - 1) * 3.2, 1.2 + rng.randf(), 0)
		mi.rotation = Vector3(0.1, rng.randf() * 0.6, 0.3)
		mi.material_override = mat
		n.add_child(mi)
	return n


static func fit_hulk(node: Node3D, centre: Vector3) -> void:
	var nodes: Array = [node]
	var bounds := AABB()
	var first := true
	while not nodes.is_empty():
		var part: Node = nodes.pop_back()
		if part is MeshInstance3D and part.mesh != null:
			var box: AABB = part.global_transform * part.mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		for child in part.get_children(): nodes.append(child)
	if first: return
	var span := maxf(bounds.size.x, bounds.size.z)
	var factor := 14.0 / maxf(span, 0.01)
	var relative := bounds.get_center() - node.global_position
	node.scale *= factor
	node.global_position = centre + Vector3.UP * 2.0 - relative * factor
