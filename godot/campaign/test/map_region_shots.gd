extends SceneTree
# Issue 465: generated regions, matched sectors, and a real four-route fork. No saves.
# godot --path godot --script res://campaign/test/map_region_shots.gd -- OUTPUT --no-tips
const Scene = preload("res://scenes/campaign/campaign_scene.gd")
class Driver extends Scene:
	var evidence: Array = []
	var seed_now := 344
	var failed := false
	func _ready():
		_ro_dir = OS.get_cmdline_user_args()[0]; DirAccess.make_dir_recursive_absolute(_ro_dir)
		C = CampaignScript.new(); var err = C.load_tables()
		if err != "": push_error(err); get_tree().quit(1); return
		C.persist_on = false; ui = UIScript.new(); add_child(ui); ui.bind(C); _run()
	func fresh(seed_value: int):
		seed_now = seed_value
		C.UID = 1; C.RUN = null; C.B = null; C.SAVED_RUN = null; C.META = C.defaultMeta()
		C.picked_admiral = "vex"; C.picked_faction = "voidsworn"; C.run_opt = {"alt": false, "cmdAlt": false, "heat": []}; C.ended = false
		JSM.rnd_seed(seed_value); C.titleScreen(); C.act("newRunScreen"); C.act("startRun")
		if C.page.get("kind") == "aspect": C.act("pickAspect", C.W["aspOffer"][0])
		C.act("closeModal"); _ro_seen = {"fleet": true, "retreat": true}
	func first_stop() -> bool:
		return await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN.get("pos") != null, 100)
	func capture(name: String):
		get_viewport().warp_mouse(Vector2(550, 1000)); ui.map3d._set_hot("")
		await _ro_shot(name)
		if ui.map3d.loading: push_error("Map still loading"); get_tree().quit(1); return
		if preload("res://render/placeholder_guard.gd").stop_if_any(): return
		await _frames(90)
		var times: Array = []
		for i in 240:
			var t = Time.get_ticks_usec(); await RenderingServer.frame_post_draw; await get_tree().process_frame
			times.append(float(Time.get_ticks_usec() - t) / 1000.0)
		times.sort()
		var scroll = ui._rail_host.find_child("FleetScroll", true, false)
		var orders = ui._rail_host.find_child("OrdersScroll", true, false)
		var item = {"name": name, "seed": seed_now, "sector": C.RUN["sector"], "region": C.RUN["map"]["region"], "p50_ms": times[120], "p95_ms": times[228], "frames": times.size(), "texture_bytes": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED), "fleet_rows": floori(scroll.size.y / ui.px(36)), "next_jumps": ui._routes.size()}
		var groups: Array = []
		for id in ui.map3d._nodes:
			var data = ui.map3d._nodes[id]; var fleet = data["obj"].get_node_or_null("EnemyFleet")
			if fleet == null: continue
			var members: Array = []
			for ship in fleet.get_children():
				members.append({"class": ship.get_child(0).u["cls"], "length": ship.get_child(0).L * ship.scale.x, "position": str(ship.position), "heading": ship.rotation.y})
			groups.append({"id": id, "kind": data["n"]["type"], "level": fleet.get_meta("danger_level"), "members": members})
		item["fight_groups"] = groups
		item["scenery_geometry"] = _geometry(ui.map3d.region_scenery)
		item["orders_overflow_px"] = maxf(0, orders.get_child(0).get_combined_minimum_size().y - orders.size.y)
		if name.begins_with("four_routes") and (item["fleet_rows"] < mini(3, C.RUN["fleet"].size()) or item["orders_overflow_px"] > 1):
			push_error("Four-route fork does not fit three fleet lines and all routes"); failed = true
		var words: Array = []; _words(ui._rail_host, words)
		var overlaps: Array = []
		for i in words.size():
			if words[i]["size"] < 17: push_error("Rail text below 17 px"); failed = true
			for j in range(i + 1, words.size()):
				if words[i]["rect"].grow(-1).intersects(words[j]["rect"].grow(-1)): overlaps.append([words[i]["text"], words[j]["text"]])
		item["rail_overlaps"] = overlaps
		if not overlaps.is_empty(): push_error("Overlapping rail words " + str(overlaps)); failed = true
		evidence.append(item); print("REGION_CAPTURE ", JSON.stringify(item))
		var img = Image.load_from_file(_ro_dir.path_join(name + ".png"))
		if img == null or img.get_size() != Vector2i(1920, 1080): push_error("Missing 1080 capture " + name); get_tree().quit(1)
	func _run():
		get_window().mode = Window.MODE_WINDOWED; get_window().size = Vector2i(1920, 1080); get_window().position = Vector2i.ZERO
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps = 0; await _frames(15)
		fresh(344)
		for sector in [1, 2, 3]:
			if not await _br_play(func(): return C.modal_d == null and C.page.get("kind") == "map" and C.RUN["sector"] == sector and C.RUN.get("pos") != null and int(C.findNode(C.RUN["pos"])["col"]) == 0, 700):
				push_error("Cannot reach sector " + str(sector)); get_tree().quit(1); return
			await capture("sector_" + str(sector))
		# Search the campaign generator, then play to the first stop. No region override.
		for region in ["boneyard", "nebula", "world", "frontier", "deep"]:
			var found := false
			for seed_value in range(1, 301):
				fresh(seed_value)
				if C.RUN["map"]["region"] == region: found = true; break
			if not found or not await first_stop(): push_error("Cannot reach " + region); get_tree().quit(1); return
			await capture("region_" + region)
			if region == "world":
				ui._open_overlay("key"); await _ro_shot("map_key"); ui._close_overlay()
		var fork := false
		for seed_value in range(1, 100):
			fresh(seed_value)
			if C.RUN["map"]["cols"][1].size() == 4: fork = true; break
		if not fork or not await first_stop(): push_error("Cannot reach four-route fork"); get_tree().quit(1); return
		for route in ui._routes.duplicate():
			ui.pick_route(str(route["id"])); await _frames(5); await capture("four_routes_" + str(route["num"]))
		var file = FileAccess.open(_ro_dir.path_join("metrics.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"resolution": "1920x1080", "renderer": RenderingServer.get_current_rendering_method(), "vsync": "off", "states": evidence}, "\t")); file.close()
		get_tree().quit(1 if failed else 0)
	func _geometry(node: Node) -> Dictionary:
		var triangles := 0; var vertices := 0; var unique := {}; var bytes := 0
		var stack = [node]
		while not stack.is_empty():
			var child = stack.pop_back(); stack.append_array(child.get_children())
			var mesh: Mesh = null; var instances := 1
			if child is MeshInstance3D: mesh = child.mesh
			elif child is MultiMeshInstance3D: mesh = child.multimesh.mesh; instances = child.multimesh.instance_count
			if mesh == null: continue
			for surface in mesh.get_surface_count():
				var arrays = mesh.surface_get_arrays(surface)
				if mesh is ArrayMesh and mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES: continue
				var count = arrays[Mesh.ARRAY_VERTEX].size()
				var indices = arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX] != null else 0
				vertices += count * instances; triangles += (indices if indices > 0 else count) / 3 * instances
				if not unique.has(mesh.get_instance_id()):
					# Position + normal + color for generated rocks; array storage, excluding driver overhead.
					bytes += count * 40 + indices * 4
			unique[mesh.get_instance_id()] = true
		return {"instanced_triangles": triangles, "instanced_vertices": vertices, "unique_meshes": unique.size(), "estimated_mesh_bytes": bytes}
	func _words(node: Node, out: Array):
		if node is Control and node.is_visible_in_tree():
			var rect = node.get_global_rect(); var parent = node.get_parent()
			while parent != null:
				if parent is Control and parent.clip_contents: rect = rect.intersection(parent.get_global_rect())
				parent = parent.get_parent()
			if not rect.has_area(): return
			if node is Label and node.text != "": out.append({"text": node.text, "size": node.get_theme_font_size("font_size") / ui.k, "rect": rect})
			elif node.has_meta("sheet_parts"):
				var text = ""; var sizes: Array = []
				for part in node.get_meta("sheet_parts"):
					if part.size() > 1: text += part[0]; sizes.append(part[2])
				out.append({"text": text, "size": sizes.min(), "rect": rect})
		for child in node.get_children(): _words(child, out)
func _initialize(): root.add_child.call_deferred(Driver.new())
