extends SceneTree
# Issue 2048 item 3: terrain polish headless check covering Dead Star INFALL_SHADER stretched tidal embers,
# terrain_scorch.gd 256x256 crater/char albedo + normal + ORM + light-blue plasma vein decals, and both DUST_SHADERs
# (debris flecks/haze and background space dust glints). Nebula and storm gas shaders stay untouched (issue 2035).
const GUARD := preload("res://tools/ci/check_guard.gd")
const SCORCH := preload("res://fx/terrain_scorch.gd")
const WORLD := preload("res://world/world.gd")
const LIVING := preload("res://world/world_living.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "terrain_polish_2048_check")
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)
	else:
		print("  ok: " + msg)


func _run() -> void:
	# 1. terrain_scorch.gd: 256x256 albedo, normal, ORM, and light-blue plasma emission decals.
	SCORCH.clear_static()
	var holder := Node3D.new()
	root.add_child(holder)
	var t0 := Time.get_ticks_usec()
	var hit := SCORCH.surface_hit(BoxMesh.new(), Transform3D(Basis.from_scale(Vector3(3, 2, 3)), Vector3.ZERO))
	var mark := SCORCH.stamp(holder, hit, 3.2, true)
	var build_ms := float(Time.get_ticks_usec() - t0) / 1000.0
	_check(mark is Decal, "terrain_scorch.stamp returns a Decal")
	_check(build_ms < 2500.0, "terrain_scorch 256px texture generation completes promptly (%.1f ms)" % build_ms)
	_check(mark.texture_albedo != null and mark.texture_albedo.get_width() == 256 and mark.texture_albedo.get_height() == 256,
		"scorch albedo texture is 256x256")
	_check(mark.texture_normal != null and mark.texture_normal.get_width() == 256 and mark.texture_normal.get_height() == 256,
		"scorch normal texture is 256x256")
	_check(mark.texture_orm != null and mark.texture_orm.get_width() == 256 and mark.texture_orm.get_height() == 256,
		"scorch ORM texture is 256x256")
	_check(mark.texture_emission != null and mark.texture_emission.get_width() == 256 and mark.texture_emission.get_height() == 256,
		"plasma scorch emission texture is 256x256")
	var a_img: Image = mark.texture_albedo.get_image()
	var n_img: Image = mark.texture_normal.get_image()
	var p_img: Image = mark.texture_emission.get_image()
	var center_a := a_img.get_pixel(128, 128).a
	var corner_a := maxf(maxf(a_img.get_pixel(0, 0).a, a_img.get_pixel(255, 0).a),
		maxf(a_img.get_pixel(0, 255).a, a_img.get_pixel(255, 255).a))
	var edge_a := maxf(maxf(a_img.get_pixel(128, 0).a, a_img.get_pixel(128, 255).a),
		maxf(a_img.get_pixel(0, 128).a, a_img.get_pixel(255, 128).a))
	_check(center_a > 0.60, "scorch crater center is opaque char (alpha=%.3f)" % center_a)
	_check(corner_a < 0.01 and edge_a < 0.02, "scorch decal feathers cleanly to zero at all borders (corner=%.3f edge=%.3f)" % [corner_a, edge_a])
	var relief_dev := 0.0
	for y in range(48, 208, 4):
		for x in range(48, 208, 4):
			var c := n_img.get_pixel(x, y)
			relief_dev = maxf(relief_dev, absf(c.r - 0.5) + absf(c.g - 0.5))
	_check(relief_dev > 0.20, "scorch normal map carries real crater/rim relief (max_dev=%.3f)" % relief_dev)
	var max_b := 0.0
	var max_g := 0.0
	var max_r := 0.0
	for y in range(32, 224, 4):
		for x in range(32, 224, 4):
			var pc := p_img.get_pixel(x, y)
			max_r = maxf(max_r, pc.r)
			max_g = maxf(max_g, pc.g)
			max_b = maxf(max_b, pc.b)
	_check(max_b > 0.35 and max_b > max_g and max_g > max_r,
		"plasma scorch emission stays light blue (R6.13, peak RGB %.2f/%.2f/%.2f)" % [max_r, max_g, max_b])
	var plain := SCORCH.stamp(holder, hit, 2.8, false)
	_check(plain.texture_emission == null and plain.texture_normal != null and plain.texture_orm != null,
		"non-plasma scorch carries albedo+normal+ORM with no emission")
	SCORCH.clear_static()
	_check(SCORCH._albedo == null and SCORCH._normal == null and SCORCH._orm == null and SCORCH._plasma == null,
		"terrain_scorch.clear_static releases all four cached textures")
	holder.queue_free()

	# 2. Dead Star INFALL_SHADER: motion-stretched tidal embers with core + tail + tidal heating.
	var infall_code: String = LIVING.INFALL_SHADER
	_check(infall_code.contains("vec3 vel_w =") and infall_code.contains("float stretch = mix("),
		"INFALL_SHADER stretches motes along their inward spiral velocity")
	_check(infall_code.contains("varying float vHeat;") and infall_code.contains("vec3 hot_c ="),
		"INFALL_SHADER heats embers as they spiral inward toward the accretion disc")
	_check(infall_code.contains("float core =") and infall_code.contains("float sheath ="),
		"INFALL_SHADER layers a bright leading core with a tapered trailing ember tail")
	var infall_sh := Shader.new()
	infall_sh.code = infall_code
	_check(not infall_sh.code.is_empty(), "INFALL_SHADER shader resource created")

	# 3. Both DUST_SHADERs: layered glinting dust flecks + background dust core/halo/glint.
	var living_dust: String = LIVING.DUST_SHADER
	var world_dust: String = WORLD.DUST_SHADER
	_check(living_dust.contains("varying flat float vSize;") and living_dust.contains("float glint ="),
		"world_living DUST_SHADER adds tumbling flecks and warm sun glints on fine motes")
	_check(living_dust.contains("float wisp ="),
		"world_living DUST_SHADER shapes broad tan haze clouds into organic wisps")
	_check(world_dust.contains("float cross_glint =") and world_dust.contains("float halo ="),
		"world DUST_SHADER upgrades background dust from plain dots to layered glinting motes")
	_check(world_dust.contains("float mins = depth * (px * fr) * 1.6;"),
		"world DUST_SHADER preserves 1080p/2160p pixel scale floor")

	await process_frame
	print("terrain_polish_2048_check: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
