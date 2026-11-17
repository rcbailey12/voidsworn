extends "res://world/nebula_bench.gd"
# Capture-only additions. The measured gate adapter stays unchanged during a timing batch.
var _capture_center := Vector3.INF
var _pose_rows: Array = []


func _shot(name: String) -> void:
	var hidden: Array = []
	var subject = null
	var main_view := not name.begins_with("scale_")
	if main_view:
		for view in _views():
			if view.visible and str(view.u.cls) == "Cruiser":
				subject = view
				break
		if subject != null and _capture_center == Vector3.INF: _capture_center = subject.position
	if name.ends_with("_4k_clear.png"):
		# Keep debris, lightning lights and their shadows. Only gas leaves the paired frame.
		var living = b.world._living
		living.visible = true
		var gas_materials: Array = []
		for entry in living.gas_mats: gas_materials.append(entry[0])
		for child in living.get_children():
			if child is FogVolume or (child is MultiMeshInstance3D and gas_materials.has(child.material_override)):
				hidden.append(child)
				child.visible = false
	# Resize/layout callbacks must not move the comparison between gas and clear frames.
	b.set_process(false)
	b.cam.set_process(false)
	var settle := 60 if route == "fog" and main_view else 12
	for frame in settle:
		if main_view and subject != null:
			subject.position = _capture_center
			b.cam.t = _capture_center
			b.cam.r = 26.0 if "_c26" in name else (60.0 if "_c60" in name else 170.0)
			b.cam.a = -PI / 2.0
			b.cam.b = 0.05 if "_top" in name else 0.98
		b.cam.screen_shift = 0.0
		b.cam.snap()
		await get_tree().process_frame
	await super._shot(name)
	var projected: Vector2 = b.cam.unproject_position(subject.global_position) if subject != null else Vector2.ZERO
	_pose_rows.append({"file": name, "radius": b.cam.r, "screen_shift": b.cam.screen_shift,
		"target": [b.cam.t.x, b.cam.t.y, b.cam.t.z], "subject_screen": [projected.x, projected.y],
		"viewport": [get_window().size.x, get_window().size.y], "gas_nodes_hidden": hidden.size()})
	var file := FileAccess.open(out.path_join("capture_poses.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(_pose_rows, "  ") + "\n")
	file.close()
	if name.ends_with("_4k_clear.png") and subject != null:
		await _hull_mask(subject, name.replace("_clear.png", "_mask.png"))
	for child in hidden: child.visible = true


func _hull_mask(subject, name: String) -> void:
	# Render the real projected triangles, so contrast uses hull pixels rather than a sky rectangle.
	var hidden: Array = []
	var materials: Array = []
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.disable_fog = true
	for node in b.find_children("*", "GeometryInstance3D", true, false):
		if node is MeshInstance3D and subject.meshes.has(node):
			materials.append([node, node.material_override])
			node.material_override = white
		elif node.visible:
			hidden.append(node)
			node.visible = false
	var previous: Environment = b.cam.environment
	var mask_env := Environment.new()
	mask_env.background_mode = Environment.BG_COLOR
	mask_env.background_color = Color.BLACK
	b.cam.environment = mask_env
	for frame in 8: await get_tree().process_frame
	await super._shot(name)
	b.cam.environment = previous
	for entry in materials: entry[0].material_override = entry[1]
	for node in hidden: node.visible = true


func _scale_captures(center: Vector3, living) -> void:
	await super._scale_captures(center, living)
	if PG.stop_if_any() or route != "fog": return
	await _transport_capture(center)
	var metadata := out.path_join("scale_metadata.json")
	var gas_metadata := FileAccess.get_file_as_string(metadata)
	var original_case := map_case
	for kind in ["rock", "debris", "hulk"]:
		var point := Vector3.INF
		for key in b.V.terrain:
			if b.V.terrain[key] != kind: continue
			var qr := str(key).split(",")
			point = b.board.hex_world(int(qr[0]), int(qr[1]))
			break
		if point == Vector3.INF: continue
		map_case = kind
		# One hex beside the sampled terrain, so both the ship and the object remain visible.
		await super._scale_captures(point + Vector3(-20, 0, 0), living)
		if PG.stop_if_any(): return
		await _transport_capture(point + Vector3(-20, 0, 0))
		var context := FileAccess.open(out.path_join("scale_metadata_" + kind + ".json"), FileAccess.WRITE)
		context.store_string(FileAccess.get_file_as_string(metadata))
		context.close()
	map_case = original_case
	var file := FileAccess.open(metadata, FileAccess.WRITE)
	file.store_string(gas_metadata)
	file.close()


func _transport_capture(center: Vector3) -> void:
	# Transport is an objective prop, not a distinct roster template. Draw its real built scene.
	var table = load("res://render/hull_table.gd")
	var code: String = table.AI_HULLS["obj|transport"]
	var prop = load("res://assets/ships/a4_props.gd")._scene(code)
	if prop == null:
		PG.note(code)
		PG.stop_if_any()
		return
	var length: float = table.CLS_LEN["Transport"] * table.SHIP_K
	b.add_child(prop)
	prop.position = center
	prop.scale = Vector3.ONE * length
	for radius in [170.0, 60.0]:
		b.cam.t = center
		b.cam.r = radius
		b.cam.b = 0.98
		b.cam.snap()
		for frame in 30: await get_tree().process_frame
		await _shot("scale_%s_%s_transport_c%d.png" % [map_case, route, int(radius)])
	prop.queue_free()
	await get_tree().process_frame
	var path := out.path_join("scale_metadata.json")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.ships.append({"class": "Transport", "code": code, "length": length, "source": "built objective prop"})
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "  ") + "\n")
	file.close()
