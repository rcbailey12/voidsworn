extends SceneTree
# Issue 1236 round 4 (WRECK5c showed two pieces on most real hulls): prints each installed hull's authored transverse
# joints along its length, as fx_hull reads them (the node's voidsworn_destruct seams through the node transform), and
# the hull's x extent, so the breakup's joint choice can be checked on the real ships. Headless; reads the built cache.
# Run: godot --headless --path godot --script res://../contrib/opus/wreck_1236/seam_dump.gd (or copied under godot/)

const SV := preload("res://render/ship_view.gd")


func _init() -> void:
	var man: Dictionary = SV.manifest()
	var out := {}
	var res := {}
	for kind in ["hi", "ships"]:   # A4's kit ship wins where both exist, as ShipView picks it
		if man.has(kind):
			for code in (man[kind] as Dictionary).keys(): res[code] = man[kind][code]["res"]
	var codes: Array = res.keys()
	codes.sort()
	for code in codes:
		var ps = load(res[code])
		if not ps is PackedScene: continue
		var inst: Node3D = (ps as PackedScene).instantiate()
		root.add_child(inst)
		var lo := INF
		var hi := -INF
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m: Mesh = (mi as MeshInstance3D).mesh
			if m == null: continue
			var bb: AABB = m.get_aabb()
			var xf: Transform3D = inst.global_transform.affine_inverse() * (mi as Node3D).global_transform
			for c in 8:
				var p: Vector3 = xf * bb.get_endpoint(c)
				lo = minf(lo, p.x)
				hi = maxf(hi, p.x)
		var joints: Array = []
		var nodes: Array = [inst]
		nodes.append_array(inst.find_children("*", "", true, false))
		for nd in nodes:
			var extras = nd.get_meta("extras", {})
			var contract = nd.get_meta("voidsworn_destruct", extras.get("voidsworn_destruct", {}) if extras is Dictionary else {})
			if contract is String: contract = JSON.parse_string(contract)
			if not contract is Dictionary: continue
			var xf2: Transform3D = inst.global_transform.affine_inverse() * (nd as Node3D).global_transform if nd is Node3D else Transform3D.IDENTITY
			for seam in contract.get("seams", []):
				if seam.has("span"): continue
				var p: Array = seam["p"]
				var at: Vector3 = xf2 * Vector3(float(p[0]), float(p[1]), float(p[2]))
				var path_x: Array = []
				for q in seam.get("path", []):
					path_x.append(snappedf((xf2 * Vector3(float(q[0]), 0.0, float(q[1]))).x, 0.001))
				joints.append({"x": snappedf(at.x, 0.001), "path_x": path_x})
		var L := hi - lo
		var fr: Array = []
		for j in joints: fr.append(snappedf((float(j["x"]) - lo) / maxf(L, 1e-6), 0.001))
		fr.sort()
		out[code] = {"x0": snappedf(lo, 0.001), "L": snappedf(L, 0.001), "joints": joints, "joint_frac": fr}
		print("SEAMS %s L=%.3f joints along the length (0 stern, 1 bow): %s" % [code, L, str(fr)])
		inst.queue_free()
	var f := FileAccess.open(OS.get_environment("SEAM_OUT") if OS.get_environment("SEAM_OUT") != "" else "user://seams_1236.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out, " "))
		f.close()
	print("SEAM_DUMP_DONE %d hulls" % out.size())
	quit(0)
