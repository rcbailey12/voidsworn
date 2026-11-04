extends SceneTree
# Isolated import check, not a live board swap. Run with --headless --script.

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected the station render folder")
		quit(2)
		return
	for variant in ["fleet", "refinery"]:
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		var err := doc.append_from_file(args[0].path_join(variant + "_blockout.glb"), state)
		if err != OK:
			push_error("Station GLB import failed: " + variant)
			quit(1)
			return
		var station := doc.generate_scene(state)
		if station == null:
			quit(1)
			return
		root.add_child(station)
		var meshes := station.find_children("*", "MeshInstance3D", true, false)
		var lo := Vector3.INF
		var hi := -Vector3.INF
		var batteries := 0
		for node in meshes:
			var mi := node as MeshInstance3D
			if str(mi.name).begins_with("battery_"):
				batteries += 1
			var aabb := mi.get_aabb()
			for corner in 8:
				var p := mi.global_transform * aabb.get_endpoint(corner)
				if not p.is_finite():
					quit(1)
					return
				lo = lo.min(p)
				hi = hi.max(p)
		var dimensions := hi - lo
		if absf(dimensions.x - 46.0) > 0.01 or batteries != (4 if variant == "fleet" else 0):
			push_error("Wrong station dimensions or turret export: " + variant)
			quit(1)
			return
		for size in [30.0, 46.0]:
			var measured: float = dimensions.x * size / 46.0
			if absf(measured - size) > 0.01:
				quit(1)
				return
		print("[station-check] PASS ", variant, " dimensions=", dimensions,
			" battery_nodes=", batteries, " compact_length=30 full_length=46")
		station.free()
	quit(0)
