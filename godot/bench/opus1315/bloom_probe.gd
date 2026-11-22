extends "res://assets/ships/test/a4_shots.gd"
# Issue 1315 probe (PC, Forward+): what makes CD5's white stern bloom. It IS a4_shots (the same world, sky, look.apply,
# ShipView spawn and close view q), with _run replaced: CD5 is drawn once per variant, each changing one input on every
# material of the ship (or one light), and every frame is measured on the same fixed stern box as W2's own I8_37_q.jpg.
# Artoo on PR 1317: match the a4 rig exactly, one count definition, a stern-only measure, the GLB hash and the renderer logged.
# Run: Godot --path <W2 clone>\godot --resolution 1920x1080 res://bench/opus1315/bloom_probe.tscn -- --out <folder>
# (the PC bat copies it to an untracked folder of the W2 clone). Writes <out>/<variant>.png/.jpg and <out>/bloom_probe.txt.
# Counts: pixels of the STERN box with channel mean over 245 (and over 200), on the jpg as a4 saves it (quality 0.9).
# The bar on W2's own I8_37_q.jpg by this definition: r5c 1193, W1C 1139, W2 1290 over 245 (of 200,000).
# Probe 3 (PC, Nov 20) found glow spreads the white and metal makes the hottest pixels, but never touched look.gd's rim
# light (LookRim: specular 8, behind the ship as the camera sees it). The Glasswright kit opts out of the soft rim
# (SOFT_RIM False), the surfaces issue 601 cut to a quarter of that specular. Probe 4 tests the rim light.
const VARIANTS := ["base", "rimoff", "rimsoft", "noglow", "rimsoft_noglow", "rimsoft_metal_0.5", "rimsoft_nofill"]
const STERN := Rect2i(1050, 100, 500, 400)     # the stern bloom in view q (W2 I8_37_q.jpg peak at 1235, 295)

static func measure(img: Image, box: Rect2i) -> Dictionary:
	var s245 := 0; var s200 := 0; var n := 0
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var c := img.get_pixel(x, y); var l := (c.r8 + c.g8 + c.b8) / 3.0
			n += 1
			if l > 245.0: s245 += 1
			if l > 200.0: s200 += 1
	return {"over245": s245, "over200": s200, "pixels": n}

func _run() -> void:
	var rep := FileAccess.open(out.path_join("bloom_probe.txt"), FileAccess.WRITE)
	var glb := ProjectSettings.globalize_path("res://assets/ships/I8_37/I8_37.glb")
	if not FileAccess.file_exists(glb):
		print("BLOOM_PROBE FAILED: no built hull at ", glb)
		rep.store_line("FAILED: no built hull at " + glb); rep.close()
		return
	var line := "BLOOM_PROBE glb %s sha256 %s renderer %s adapter %s stern box %s" % [glb, FileAccess.get_sha256(glb),
		RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), str(STERN)]
	print(line); rep.store_line(line)
	# Artoo on PR 1317: ShipView draws the generated scene the manifest names, not the glb, so prove that scene was built
	# from this glb (build_assets' own source stamp) and log its path and hash; any other hull path stops the run
	var man := ShipView.manifest()
	var ent: Dictionary = man.get("ships", {}).get("I8_37", {})
	var stamp: String = preload("res://render/build_assets.gd").source_stamp("res://assets/ships", "I8_37")
	var scn := ProjectSettings.globalize_path(str(ent.get("res", "")))
	if ent.is_empty() or not FileAccess.file_exists(scn) or str(ent.get("src", "")) != stamp:
		line = "BLOOM_PROBE FAILED: the game scene for I8_37 is missing or stale (manifest %s, glb stamp %s)" % [str(ent), stamp]
		print(line); rep.store_line(line); rep.close()
		return
	line = "BLOOM_PROBE scene %s sha256 %s built from glb stamp %s" % [scn, FileAccess.get_sha256(scn), stamp]
	print(line); rep.store_line(line)
	var L := _len_of("ithar", "Ark")
	var sv := _spawn("I8_37", "ithar", "Ark", Vector3.ZERO)
	if PG.stop_if_any() or not sv.a4:
		line = "BLOOM_PROBE FAILED: CD5 did not load as its authored scene (placeholder or fallback hull)"
		print(line); rep.store_line(line); rep.close()
		return
	var lights: Array = find_children("*", "DirectionalLight3D", true, false)
	var energies := lights.map(func(l): return (l as DirectionalLight3D).light_energy)
	var specs := lights.map(func(l): return (l as DirectionalLight3D).light_specular)
	for l in lights:
		line = "BLOOM_PROBE light %s energy %.2f specular %.2f" % [(l as Node).name, (l as DirectionalLight3D).light_energy,
			(l as DirectionalLight3D).light_specular]
		print(line); rep.store_line(line)
	var originals := {}
	for m in sv.meshes:
		var mi := m as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			originals[[mi, si]] = mi.get_active_material(si)
	var sky_src = env.reflected_light_source
	var bg = env.background_mode
	for v: String in VARIANTS:
		env.glow_enabled = not v.contains("noglow")
		env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED if v == "nosky" else sky_src
		for i in lights.size():
			var li := lights[i] as DirectionalLight3D
			li.light_energy = energies[i]; li.light_specular = specs[i]
			if li.name == "LookRim" and v.contains("rimoff"): li.light_energy = 0.0; li.light_specular = 0.0
			if li.name == "LookRim" and v.contains("rimsoft"): li.light_specular = specs[i] * 0.25   # look.gd RIM soft
		if v == "nokey" and lights.size() > 0: (lights[0] as DirectionalLight3D).light_energy = 0.0
		if v.contains("nofill") and lights.size() > 1: (lights[1] as DirectionalLight3D).light_energy = 0.0
		for k in originals:
			var src = originals[k]
			var mat = src
			if src is BaseMaterial3D and (v.contains("noemit") or v.contains("metal_") or v.begins_with("rough_")):
				mat = (src as BaseMaterial3D).duplicate()
				if v.contains("noemit"): mat.emission_enabled = false
				if v.contains("metal_"): mat.metallic = float(v.get_slice("metal_", 1))
				if v.begins_with("rough_"): mat.roughness_texture = null; mat.roughness = float(v.get_slice("rough_", 1))
			(k[0] as MeshInstance3D).set_surface_override_material(int(k[1]), mat)
		cam.current = true
		var d := L * 0.62 / tan(deg_to_rad(cam.fov * 0.5)) * 0.62
		var el := 0.45; var az := -0.62
		cam.look_at_from_position(Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az)) * d, Vector3.ZERO, Vector3.UP)
		await _settle()
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(v + ".png"), preload("res://tools/picture_provenance.gd").capture_stage())
		# the bar was counted on a4's jpg (quality 0.9), so the main count is on the same jpg, read back; png count beside it
		var jp := out.path_join(v + ".jpg")
		preload("res://tools/picture_provenance.gd").save_jpg(img, jp, 0.9, preload("res://tools/picture_provenance.gd").capture_stage())  # stamp: bottom left, off the box
		var m := measure(Image.load_from_file(jp), STERN)
		var r := measure(img, STERN)
		line = "BLOOM_PROBE %s stern over245=%d over200=%d of %d (raw png over245=%d)" % [v, m["over245"], m["over200"],
			m["pixels"], r["over245"]]
		print(line); rep.store_line(line)
	rep.close()
	print("BLOOM_PROBE done")
