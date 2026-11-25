extends Node3D
# Filled set-piece hexes were in SOLID in both rule engines, but had no Godot
# props. These are presentation only; no playable or blocking hex changes.
const WR := preload("res://world/world_rocks.gd")
const A4P := preload("res://assets/ships/a4_props.gd")
const LIVING := preload("res://world/world_living.gd")
const WS := preload("res://world/world_shaders.gd")
static var _wreck_mat: ShaderMaterial
var visuals := {}   # hex key -> actual solid node, used by the coverage check


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit)
static func clear_static() -> void:
	_wreck_mat = null

# Review-only station footprint, read from the real view. No live asset swap here:
# issue 373 requires the build sheet, scene gate and Ryan's look first. The main
# seven-cell terrain station is separate from station-kind holes elsewhere.
static func station_review_footprint(view: Dictionary, hw: Callable) -> Dictionary:
	var terrain: Dictionary = view.get("terrain", {})
	var cells: Array = []
	var centre := Vector3.ZERO
	var station = view.get("map", {}).get("station")
	if not station is Dictionary:
		return {}
	var seed_key := "%d,%d" % [int(station.q), int(station.r)]
	if terrain.get(seed_key) != "station":
		return {}
	var todo: Array = [seed_key]
	var seen := {seed_key: true}
	while not todo.is_empty():
		var key: String = str(todo.pop_back())
		var qr := key.split(",")
		var q := int(qr[0]); var r := int(qr[1])
		var p: Vector3 = hw.call(q, r)
		cells.append({"q": q, "r": r, "x": p.x, "z": p.z})
		centre += p
		for d in [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]:
			var next_key := "%d,%d" % [q + int(d[0]), r + int(d[1])]
			if terrain.get(next_key) == "station" and not seen.has(next_key):
				seen[next_key] = true
				todo.append(next_key)
	centre /= float(cells.size())
	# Read the cell spacing through the board's callable, never the old 14-unit prop.
	var origin: Vector3 = hw.call(int(station.q), int(station.r))
	var neighbour: Vector3 = hw.call(int(station.q) + 1, int(station.r))
	var radius := origin.distance_to(neighbour) / sqrt(3.0)
	return {"cells": cells, "centre": [centre.x, centre.y, centre.z], "hex_radius": radius}

func build(view: Dictionary, hw: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	# The board already has the world's seed and biome. Read them through the
	# supplied hex callable, without changing the rules view or its random stream.
	var board = hw.get_object()
	var info: Dictionary = board.WI if board != null and "WI" in board else {}
	var biome: Dictionary = info.get("biome", {}) if info.get("biome") is Dictionary else {}
	var rock_kind := str(biome.get("rock", "stone"))
	var rock_mat := WR.material(rock_kind, {"haze_max": 0.0})
	rock_mat.set_shader_parameter("lift", 1.2)
	rock_mat.set_shader_parameter("amb", 0.65)
	for hole in view.get("map", {}).get("holes", []):
		var kind := str(hole.get("kind", "asteroid"))
		for cell in hole.get("cells", []):
			var p: Vector3 = hw.call(int(cell[0]), int(cell[1]))
			var key := "%d,%d" % [int(cell[0]), int(cell[1])]
			rng.seed = hash("%s|%s|%s" % [str(info.get("seed", 1763)), kind, key])
			if kind == "hulk":
				visuals[key] = hulk_fallback(self, p, rng)
			elif kind == "station":
				# issue 1767: station_T2 fitted inside its one hex at its best turn (A4P.best_bearing), no drifting debris
				var hex_r: float = p.distance_to(hw.call(int(cell[0]) + 1, int(cell[1]))) / sqrt(3.0)
				var station := A4P.station(14.0, hex_r, str(biome.get("station", "")), false, [Vector2.ZERO], hex_r, 0.0)
				if station != null:
					add_child(station)
					station.position = p + Vector3.UP * 3.0 * station.scale.x
					station.rotation.y = float(station.get_meta("station_bearing", 0.0))
					visuals[key] = station
				else:
					visuals[key] = station_fallback(self, p)
			elif kind == "deadstar":
				# Do not cover the lens. The solid exclusion rim marks its rule footprint.
				visuals[key] = outline(self, p, Color(0.58, 0.39, 0.16), 0.25)
			else:
				visuals[key] = rock_cluster(p, kind, rock_kind, rock_mat, rng)
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
		# Local-space aim (Muse review #86, Opus confirmed Nov 3): look_at_from_position works in
		# global space, so inside the tree it moved every segment to near the world origin.
		mi.basis = Basis.looking_at(b - mi.position, Vector3.UP, true)
	return node

func rock_cluster(p: Vector3, kind: String, rock_kind: String, mat: Material, rng: RandomNumberGenerator) -> Node3D:
	var node := Node3D.new()
	node.name = "Blocker_" + kind
	add_child(node)
	node.position = p
	var names := WR.names_for(rock_kind)
	var phase := rng.randf() * TAU
	# A core and six overlapping shoulders fill the hex. Bound each piece by a
	# sphere, keeping the whole cluster inside the hex's 8.66-unit inner radius.
	for i in 7:
		var mesh_name := str(names[rng.randi() % names.size()])
		var mesh := WR.mesh(mesh_name)
		var radius := rng.randf_range(5.8, 6.2) if i == 0 else rng.randf_range(3.4, 3.7)
		var angle := phase + (i - 1) * TAU / 6.0 + rng.randf_range(-0.09, 0.09)
		var off := Vector3(0, 1.8, 0) if i == 0 else Vector3(cos(angle) * 4.8, rng.randf_range(0.3, 2.2), sin(angle) * 4.8)
		var mi := cluster_piece(node, mesh, mat, off, radius, rng)
		mi.name = mesh_name
		var box := mesh.get_aabb()
		mi.set_instance_shader_parameter("rock_radius", box.position.abs().max(box.end.abs()).length())
		# issue 1361: the mesh box, so the kind's shape squeeze (ROCK_SHADER shape_k) reaches the board's own rocks too
		mi.set_instance_shader_parameter("rock_ext", box.size)
	return node


static func cluster_piece(parent: Node3D, mesh: Mesh, mat: Material, off: Vector3, radius: float, rng: RandomNumberGenerator) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	var box := mesh.get_aabb()
	var b := Basis(Quaternion(rng.randfn(), rng.randfn(), rng.randfn(), rng.randfn()).normalized())
	b = b.scaled(Vector3.ONE * (radius * 2.0 / maxf(box.size.length(), 0.01)))
	mi.transform = Transform3D(b, off - b * box.get_center())
	parent.add_child(mi)
	return mi


static func hulk_fallback(parent: Node3D, p: Vector3, rng: RandomNumberGenerator) -> Node3D:
	# Also called by the board when its painted derelict is missing. Use the
	# surrounding debris field's torn plates, ribs, trusses and deck sections.
	var wreck_meshes := LIVING._shard_meshes()
	if _wreck_mat == null:
		var sh := Shader.new()
		# Solid blockers keep a fixed pose, including their shader geometry.
		sh.code = LIVING.WRECK_SHADER.replace("%NOISE%", WS.NOISE).replace("TIME *", "0.0 *")
		_wreck_mat = ShaderMaterial.new()
		_wreck_mat.shader = sh
	var n := Node3D.new()
	n.name = "SolidDerelict"
	parent.add_child(n)
	n.position = p
	var phase := rng.randf() * TAU
	for i in 9:
		var angle := phase + (i - 3) * TAU / 6.0
		var off := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 3.0), rng.randf_range(-1, 1)) if i < 3 else Vector3(cos(angle) * 4.7, rng.randf_range(0.0, 2.5), sin(angle) * 4.7)
		var radius := rng.randf_range(5.8, 6.6) if i < 3 else rng.randf_range(3.5, 3.8)
		cluster_piece(n, wreck_meshes[rng.randi() % wreck_meshes.size()], _wreck_mat, off, radius, rng)
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
