extends SceneTree
const GUARD := preload("res://tools/ci/check_guard.gd")
const WING := preload("res://render/squadron_wing.gd")
const CRAFT := preload("res://render/squadron_craft.gd")
var checks := 0
var failures := 0

func _init() -> void:
	GUARD.arm(self, "formation_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

# Independent mesh walk: project the real, animated mesh boxes into the wing's
# board plane, including the craft root and all nested part transforms.
func footprint(n: Node3D, xf: Transform3D) -> Rect2:
	var result := Rect2()
	if n is MeshInstance3D and n.mesh != null:
		var box: AABB = n.get_aabb()
		var points := PackedVector2Array()
		for i in 8:
			var p := xf * box.get_endpoint(i)
			points.append(Vector2(p.x, p.z))
		result = Rect2(points[0], Vector2.ZERO)
		for p in points: result = result.expand(p)
	for child in n.get_children():
		if child is Node3D and not String(child.name).begins_with("fx_"):
			var part := footprint(child, xf * child.transform)
			if part.has_area(): result = result.merge(part) if result.has_area() else part
	return result

func exercise(wing: Node3D, label: String) -> void:
	var overlap := ""
	# Different seeds, a full minute at 30 fps, then far-future phases. The
	# height separation is deliberately ignored: no crossing projected hulls.
	for frame in 1920:
		wing.clock = frame / 30.0 if frame < 1800 else 1000.0 + (frame - 1800) * 13.173
		wing.step(0.0)
		var boxes: Array[Rect2] = []
		for n in wing.craft: boxes.append(footprint(n, n.transform))
		for i in boxes.size():
			for j in i:
				if boxes[i].intersects(boxes[j]):
					overlap = "%s: craft %d and %d at %.3f" % [label, i, j, wing.clock]
		if not overlap.is_empty(): break
	check(overlap.is_empty(), "projected footprints overlap: " + overlap)
	var pose: Transform3D = wing.craft[0].transform
	wing.active = false
	wing.step(1.0)
	check(wing.craft[0].transform == pose, label + ": dead craft stay still")
	wing.free()

func make_wing(fac: String, kind: String, size: float, count: int, seed_value: float) -> Node3D:
	var wing := WING.new()
	root.add_child(wing)
	wing.setup(fac, kind, size, count, seed_value)
	wing.set_process(false)
	return wing

func replace_meshes(wing: Node3D, dimensions: Vector3, offset := Vector3.ZERO) -> void:
	for n in wing.craft:
		for child in n.get_children():
			n.remove_child(child)
			child.free()
		var part := Node3D.new()
		part.position = offset
		n.add_child(part)
		var skin := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = dimensions
		skin.mesh = mesh
		part.add_child(skin)
	wing.fit_formation()
	wing.step(0.0)

func _run() -> void:
	# Every craft kind the factory can draw, not only the faction defaults.
	# Counts 3 and 6 are the arrowhead Ryan asked for (R280); 4 stays covered
	# because setup accepts any count.
	for fac in CRAFT.DEFAULT_KIND:
		for kind in ["fighter", "bomber", "spore"]:
			for count in [3, 4, 6]:
				var wing := make_wing(fac, kind, 3.84, count, 2.731)
				exercise(wing, "%s|%s count %d" % [fac, kind, count])
	# Read the accepted sheets' own measurements instead of copying their sizes.
	var sheets := ProjectSettings.globalize_path("res://../docs/ship_pipeline/build_sheets")
	for code in ["voidsworn_SF3", "voidsworn_SB4"]:
		var path := sheets.path_join(code + "/checks.json")
		check(FileAccess.file_exists(path), code + ": sheet measurements exist")
		if not FileAccess.file_exists(path): continue
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var dimensions := Vector3(sheet.model_length, sheet.height_side, maxf(sheet.beam_top, sheet.beam_bow)) / float(sheet.length_from_game)
		var wing := make_wing("voidsworn", "fighter", 3.84, 4, 0.0)
		replace_meshes(wing, dimensions)
		check(is_equal_approx(wing.rests[1].z, 0.95 * wing.length), code + ": original lateral formation retained")
		exercise(wing, code)
	# Mesh-driven regressions: broader than long (KB1CC), long, tall, nested,
	# off-centre and breathing hulls, at different sizes and formation counts.
	for size in [2.0, 3.84, 6.0]:
		for shape in [Vector3(1, 0.18, 1.25), Vector3(2.4, 0.2, 0.4), Vector3(1, 1.6, 0.3), Vector3(1, 0.2, 3.0)]:
			var wing := make_wing("corsair", "bomber", size, 8, 5.19)
			replace_meshes(wing, shape, Vector3(0.13, 0.07, -0.11))
			exercise(wing, "mesh %s size %.2f" % [shape, size])
	var spores := make_wing("chorus", "spore", 3.84, 6, -3.12)
	replace_meshes(spores, Vector3(1.1, 0.4, 1.4))
	exercise(spores, "wide breathing spores")
	var single := make_wing("hegemony", "fighter", 3.84, 1, 0.0)
	check(single.rests == [Vector3.ZERO], "a single craft stays at the anchor")
	exercise(single, "single craft")
	# PC evidence can supply the unchanged sheet GLBs exported by the capture
	# helper. CI still covers every factory mesh without unshipped assets.
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		for code in ["corsair_KB1CC", "hegemony_HF1D", "voidsworn_SF3", "voidsworn_SB4"]:
			var gltf := GLTFDocument.new()
			var state := GLTFState.new()
			var err := gltf.append_from_file(args[0].path_join(code + ".glb"), state)
			check(err == OK, code + ": exported sheet mesh loads")
			if err != OK: continue
			var model: Node3D = gltf.generate_scene(state)
			var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0].path_join(code + ".json")))
			var wing := make_wing(code.get_slice("_", 0), "bomber" if code == "corsair_KB1CC" else "fighter", 3.84, 4, 0.0)
			for n in wing.craft:
				for child in n.get_children():
					n.remove_child(child)
					child.free()
				var hull := model.duplicate()
				hull.scale = Vector3.ONE / float(meta.length)
				n.add_child(hull)
			model.free()
			wing.fit_formation()
			check(wing.rests[1].z > 0.95 * wing.length if code == "corsair_KB1CC" else is_equal_approx(wing.rests[1].z, 0.95 * wing.length), code + ": wide craft spreads, slim craft retains original lateral spacing")
			print("[formation] %s lateral step %.4f (original %.4f)" % [code, wing.rests[1].z, 0.95 * wing.length])
			exercise(wing, code + " actual sheet meshes")
	print("FORMATION_CHECK %d checks, %d failures; every factory craft and mesh regressions, 1920 flight samples per case" % [checks, failures])
	quit(0 if failures == 0 else 1)
