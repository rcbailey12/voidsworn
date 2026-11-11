extends SceneTree
# Issue 209 round 3 (from round 2's bench209.gd). Each cell glb now carries a hand-made LOD chain (nodes CELL_lod0 to CELL_lod3, export3.py)
# and real textures. Modes per cell: "off" (lod0 only, Godot auto LOD off), "auto" (lod0 only, Godot auto LOD on) and "hand" (the hand
# chain switched by visibility range at HAND_D ship lengths, auto LOD off). Textures get mipmaps and VRAM compression on load, as the
# Godot importer would give them (S3TC; the normal map with the normal source, which Godot stores as RGTC). A glb with no lod nodes (round 2's Ab) runs "off"
# and "auto" only.
# Round 2's header follows.
# Issue 209 round 2: the cells in Godot (LOD addendum, Nov 8). Runtime glTF load (no import step), the studio protocol of
# round 4 (twenty copies of one hull, 5 by 4, battle camera, MSAA 4x, shadows, SSAO and SSIL, 100 warm-up and 360 measured
# frames, GPU and frame medians), read at 1080p and with the 3D drawn at 4K (scaling_3d_scale 2.0, the R116 gate's GPU half).
# Each cell runs with Godot's automatic mesh LOD off (mesh_lod_threshold 0, as the scene gate runs) and on (ImporterMesh
# generate_lods, the same simplifier the Godot importer uses, and the default threshold of 1 pixel). For LOD on, a single-ship
# distance sweep records the triangles drawn per frame, so the switch distances can be read off, plus stills with LOD on and off
# at four distances for judging pops by eye.
#   godot --path PROJECT --resolution 1920x1080 --script res://bench209.gd -- GLB_DIR OUT_DIR CELLS(comma list) [REPEATS]

const LENGTH := 14.5        # C15s_23 length_world (godot/assets/ships/manifest.json)
const DIR := Vector3(0.0, 0.5570, 0.8305)   # the battle camera direction of the round 4 protocol: (0, cos .98, sin .98)
var world: Node3D
var cam: Camera3D
var holder: Node3D
var out := ""
const HAND_D := [0.0, 3.0, 8.0, 18.0]   # hand chain: lod k from HAND_D[k] ship lengths (camera to ship centre) to HAND_D[k + 1]
var tex_done := {}
var WARM := 100
var MEAS := 360
var NSWEEP := 36
var tex_seconds := 0.0


func _initialize() -> void:
	call_deferred("run")


func nodes(n: Node) -> Array:
	var found: Array = []
	if n is MeshInstance3D:
		found.append(n)
	for c in n.get_children():
		found.append_array(nodes(c))
	return found


func setup_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.020, 0.024, 0.040)
	psm.sky_horizon_color = Color(0.050, 0.052, 0.070)
	psm.ground_horizon_color = Color(0.050, 0.052, 0.070)
	psm.ground_bottom_color = Color(0.010, 0.010, 0.015)
	sky.sky_material = psm
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = 0.5
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssil_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	for lc in [[Vector3(-0.45, -0.70, -0.55), Color(1.0, 0.96, 0.90), 2.0], [Vector3(0.6, -0.2, 0.75), Color(0.55, 0.65, 0.85), 0.5]]:
		var light := DirectionalLight3D.new()
		light.transform = Transform3D(Basis.looking_at(lc[0].normalized(), Vector3.UP), Vector3.ZERO)
		light.light_color = lc[1]
		light.light_energy = lc[2]
		if lc[2] > 1.0:
			light.shadow_enabled = true
			light.shadow_normal_bias = 2.0
			light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
			light.directional_shadow_max_distance = 600.0
		world.add_child(light)
	root.msaa_3d = Viewport.MSAA_4X
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	cam = Camera3D.new()
	cam.near = 0.2
	cam.far = 5000.0
	cam.fov = 45.0
	world.add_child(cam)
	cam.current = true
	holder = Node3D.new()
	world.add_child(holder)


func load_ship(path: String, lods: bool) -> Dictionary:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var err := doc.append_from_file(path, st)
	if err != OK:
		return {"error": "glTF load failed %d" % err}
	var t0 := Time.get_ticks_usec()
	var info := {"surfaces": 0, "triangles": 0, "lod_triangles": [], "lod_sizes": []}
	for gm in st.get_meshes():
		var im: ImporterMesh = gm.mesh
		var is_chain_low := false
		for k in [1, 2, 3]:
			if im.resource_name.ends_with("_lod%d" % k):
				is_chain_low = true
		if lods and not is_chain_low:
			# callv: the argument list changed across Godot 4 versions (normal_split_angle was dropped); try both
			im.callv("generate_lods", [60.0, 25.0, []])
			if im.get_surface_count() > 0 and im.get_surface_lod_count(0) == 0:
				im.callv("generate_lods", [60.0, []])
		if is_chain_low:
			var lt := 0
			for s in im.get_surface_count():
				var a2: Array = im.get_surface_arrays(s)
				var i2 = a2[Mesh.ARRAY_INDEX]
				lt += (i2.size() if i2 != null else a2[Mesh.ARRAY_VERTEX].size()) / 3
			info["chain_triangles"] = info.get("chain_triangles", []) + [[im.resource_name, lt]]
			continue
		for s in im.get_surface_count():
			info["surfaces"] += 1
			var arr: Array = im.get_surface_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			var t: int = (idx.size() if idx != null else arr[Mesh.ARRAY_VERTEX].size()) / 3
			info["triangles"] += t
			var tl: Array = [t]
			var sl: Array = [0.0]
			for l in im.get_surface_lod_count(s):
				tl.append(im.get_surface_lod_indices(s, l).size() / 3)
				sl.append(im.get_surface_lod_size(s, l))
			info["lod_triangles"].append(tl)
			info["lod_sizes"].append(sl)
	info["lod_seconds"] = (Time.get_ticks_usec() - t0) / 1000000.0
	info["node"] = doc.generate_scene(st)
	prep_textures(info["node"])
	return info


func prep_textures(n: Node) -> void:
	# mipmaps and VRAM compression for every texture of every material, once per texture (the importer's defaults)
	var t0 := Time.get_ticks_usec()
	for mi in nodes(n):
		var mesh: Mesh = mi.mesh
		if mesh == null:
			continue
		for si in mesh.get_surface_count():
			var mat = mesh.surface_get_material(si)
			if not (mat is BaseMaterial3D):
				continue
			for prop in ["albedo_texture", "metallic_texture", "roughness_texture", "ao_texture", "normal_texture", "emission_texture", "orm_texture"]:
				if not (prop in mat):
					continue
				var tx = mat.get(prop)
				if tx == null or not (tx is Texture2D):
					continue
				var key: int = tx.get_instance_id()
				if not tex_done.has(key):
					var img: Image = tx.get_image()
					if img == null:
						tex_done[key] = tx
					else:
						img.decompress()
						if not img.has_mipmaps():
							img.generate_mipmaps(prop == "normal_texture")
						if prop == "normal_texture":
							img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL)
						else:
							img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_SRGB if prop in ["albedo_texture", "emission_texture"] else Image.COMPRESS_SOURCE_GENERIC)
						tex_done[key] = ImageTexture.create_from_image(img)
				mat.set(prop, tex_done[key])
	tex_seconds += (Time.get_ticks_usec() - t0) / 1000000.0


func lod_nodes(ship: Node) -> Array:
	# [lod0, lod1, lod2, lod3] mesh instances by name, or [] when the glb has no hand chain
	var found := [null, null, null, null]
	for mi in nodes(ship):
		for k in 4:
			if String(mi.name).ends_with("_lod%d" % k):
				found[k] = mi
	return found if found[0] != null and found[3] != null else []


func set_mode(ship: Node3D, mode: String) -> void:
	var L := lod_nodes(ship)
	if L.is_empty():
		return
	for k in 4:
		var mi: MeshInstance3D = L[k]
		if mode == "hand":
			mi.visible = true
			mi.visibility_range_begin = HAND_D[k] * LENGTH
			mi.visibility_range_end = HAND_D[k + 1] * LENGTH if k < 3 else 0.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		else:
			mi.visible = k == 0
			mi.visibility_range_begin = 0.0
			mi.visibility_range_end = 0.0


func fit(ship: Node3D) -> void:
	holder.add_child(ship)
	var box := AABB()
	var first := true
	for mi in nodes(ship):
		var xf: Transform3D = ship.global_transform.affine_inverse() * mi.global_transform
		var bb: AABB = xf * mi.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	var k := LENGTH / maxf(box.size.x, 0.001)
	ship.scale = Vector3.ONE * k
	ship.position = -box.get_center() * k


func settle(n := 40) -> void:
	for i in n:
		await process_frame


func median(a: Array) -> float:
	var b := a.duplicate()
	b.sort()
	return float(b[b.size() / 2])


func bench(label: String) -> Dictionary:
	await settle(WARM)
	var gpu: Array = []
	var cpu: Array = []
	var frames: Array = []
	var last := Time.get_ticks_usec()
	var prims := 0
	for i in MEAS:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		await process_frame
	prims = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var s := frames.duplicate()
	s.sort()
	var row := {"label": label, "gpu_median_ms": median(gpu), "render_cpu_median_ms": median(cpu), "frame_median_ms": median(frames),
		"frame_p99_ms": s[int(s.size() * 0.99)], "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": prims, "scaling_3d": root.scaling_3d_scale, "lod_threshold": root.mesh_lod_threshold}
	print("[209] bench ", JSON.stringify(row))
	return row


func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))


func one_ship_view(d: float) -> void:
	cam.look_at_from_position(DIR * d * LENGTH, Vector3.ZERO, Vector3.UP)


func run() -> void:
	var a := OS.get_cmdline_user_args()
	var glb_dir: String = a[0]
	out = a[1]
	var cells: PackedStringArray = a[2].split(",")
	var repeats := int(a[3]) if a.size() > 3 else 2
	if a.size() > 4 and a[4] == "quick":   # a logic test only (software renderer): a few frames, no real numbers
		WARM = 2
		MEAS = 3
		NSWEEP = 4
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1920, 1080)
	setup_world()
	one_ship_view(8.0)
	var result := {"adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"length_world": LENGTH, "hand_d": HAND_D, "empty": [], "cells": {}, "method": "round 4 studio protocol: 20 copies 5x4 at 1.15 length spacing, camera at 8 lengths, MSAA 4x, 100 warm-up + 360 frames; 1080p and 3D at 4K (scaling 2.0); modes off / auto / hand"}
	for sc in [1.0, 2.0]:
		root.scaling_3d_scale = sc
		result["empty"].append(await bench("empty_%s" % sc))
	root.scaling_3d_scale = 1.0
	var sweep_d: Array = []
	for i in NSWEEP:
		sweep_d.append(0.8 * pow(50.0, i / float(NSWEEP - 1)))
	for rep in repeats:
		var order := cells.duplicate()
		if rep % 2 == 1:
			order.reverse()
		for cell in order:
			var path := glb_dir.path_join(cell + ".glb")
			if not FileAccess.file_exists(path):
				print("[209] missing ", path)
				continue
			if not result["cells"].has(cell):
				result["cells"][cell] = {"runs": []}
			var modes := ["off", "auto", "hand"]
			if rep % 2 == 1:
				modes.reverse()
			for mode in modes:
				var info := load_ship(path, mode == "auto")
				if info.has("error"):
					print("[209] ", cell, " ", info["error"])
					continue
				var ship: Node3D = info["node"]
				info.erase("node")
				if mode == "hand" and lod_nodes(ship).is_empty():
					ship.free()
					continue
				set_mode(ship, mode)
				fit(ship)
				root.mesh_lod_threshold = 1.0 if mode == "auto" else 0.0
				var tag := "%s_%s" % [cell, mode]
				if rep == 0:
					result["cells"][cell]["load_" + mode] = info
					var sweep: Array = []
					for d in sweep_d:
						one_ship_view(d)
						await settle(6)
						sweep.append([d, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))])
					result["cells"][cell]["sweep_" + mode] = sweep
					var stills := [1.2, 3.0, 8.0, 16.0]
					if mode == "hand":
						stills = [1.2, 2.9, 3.1, 7.75, 8.25, 17.4, 18.6]
					for d in stills:
						one_ship_view(d)
						await settle(20)
						await snap("%s_d%s" % [tag, str(d)])
					one_ship_view(8.0)
					result["cells"][cell]["one_" + mode] = await bench(tag + "_1")
				var spacing := LENGTH * 1.15
				ship.position += Vector3(-2 * spacing, 0, -1.5 * spacing)
				for i in range(1, 20):
					var c := ship.duplicate() as Node3D
					c.position += Vector3((i % 5) * spacing, 0, (i / 5) * spacing)
					holder.add_child(c)
				one_ship_view(8.0)
				for sc in [1.0, 2.0]:
					root.scaling_3d_scale = sc
					var row := await bench("%s_20_%s" % [tag, sc])
					row["repeat"] = rep + 1
					row["mode"] = mode
					result["cells"][cell]["runs"].append(row)
				root.scaling_3d_scale = 1.0
				if rep == 0:
					await snap(tag + "_20")
				for c in holder.get_children():
					c.free()
				await settle(5)
	result["texture_prep_seconds"] = tex_seconds
	var f := FileAccess.open(out.path_join("bench209.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "  ") + "\n")
	f.close()
	print("[209] BENCH DONE")
	quit(0)
