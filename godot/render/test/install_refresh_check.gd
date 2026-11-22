extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 592: proves the stage 7 install route refreshes the game's ship cache. With its own ship folder and cache in user://
# (never the project's gen/), it runs the real asset builder (render/build_assets.gd --ships-only) as a separate Godot
# process, exactly as tools/recipe/7_export.bat does after an install:
#   1. an old hull ZZ592 (the turret test ship's glb) with damage and wreck glbs: the cache names all three;
#      the saved hull shares its packed ORM with fragments, its meshes have automatic LODs, and repainting an
#      external map refreshes the cache without changing the GLB.
#   2. a new hull is installed the way stage 7 does it (the old damage and wreck glbs moved aside, the new glb copied in):
#      the cache is rebuilt from the new file and names no damage or wreck scene;
#   3. the install readback (render/test/installed_ship_check.gd) passes, and ShipView, reading that cache, draws the new
#      hull's own node and none of the old hull's turrets.
# Each run writes into its own user://install_refresh_check/<time>/ folder and removes nothing.
#   godot --headless --path godot --script res://render/test/install_refresh_check.gd
# Prints INSTALL REFRESH PASS or FAIL; exit 0 only on PASS.

const SV := preload("res://render/ship_view.gd")
const BUILD := preload("res://render/build_assets.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const GATE := preload("res://bench/scene_gate.gd")
const OLD := "res://render/test/fixtures/T560_fx/T560_fx.glb"
const CODE := "ZZ592"
const MAPS := ["packed orm.png", "albedo.jpg", "emission.webp"]

var fails := 0
var run := ""


func _init() -> void:
	GUARD.arm(self, "install_refresh_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func copy(src: String, dst: String) -> void:
	var f := FileAccess.open(dst, FileAccess.WRITE)
	f.store_buffer(FileAccess.get_file_as_bytes(src))
	f.close()


func builder() -> String:
	var out := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
		"res://render/build_assets.gd", "--", "--ships-only", "--ships", run.path_join("ships"), "--gen", run.path_join("gen")], out, true)
	check(code == 0, "the asset builder ran (--ships-only), exit %d" % code)
	return "\n".join(out)


func entry() -> Dictionary:
	var m = JSON.parse_string(FileAccess.get_file_as_string(run.path_join("gen/manifest.json")))
	return (m["ships"].get(CODE, {}) as Dictionary) if m is Dictionary and m.has("ships") else {}


func new_hull(path: String) -> void:
	# a plainly different hull: one box mesh, its own marker node, a core and an engine point
	var r := Node3D.new()
	r.name = CODE
	var mi := MeshInstance3D.new()
	mi.name = "zz592_new_hull"
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.2, 0.3)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	r.add_child(mi)
	for n in ["hp_core", "hp_eng_0"]:
		var e := Node3D.new()
		e.name = n
		r.add_child(e)
	for c in r.get_children():
		c.owner = r
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_scene(r, st)
	doc.write_to_filesystem(st, ProjectSettings.globalize_path(path))
	r.free()


func check_external_atlas() -> void:
	var path := run.path_join("paint.png")
	var atlas := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	atlas.fill(Color.REBECCA_PURPLE)
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "the new atlas can be written")
	if file == null:
		return
	file.store_buffer(atlas.save_png_to_buffer())
	file.close()
	atlas.fill(Color.BLACK)
	var stale := ImageTexture.create_from_image(atlas)
	stale.take_over_path(path)
	var gltf := run.path_join("paint.gltf")
	file = FileAccess.open(gltf, FileAccess.WRITE)
	file.store_string(JSON.stringify({"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0]}],
		"nodes": [{"name": "paint"}], "images": [{"uri": "paint.png"}]}))
	file.close()
	var control := GLTFState.new()
	check(GLTFDocument.new().append_from_file(gltf, control) == OK and control.get_images().size() == 1
		and control.get_images()[0] == stale, "plain glTF loading uses the planted old atlas")
	var fresh := GLTFState.new()
	fresh.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	check(BUILD.append_ship_glb(GLTFDocument.new(), gltf, fresh) == OK and fresh.get_images().size() == 1
		and fresh.get_images()[0].get_image().get_pixel(0, 0).is_equal_approx(Color.REBECCA_PURPLE),
		"the ship cache builder reads the new atlas from disk")


func write_paint(path: String, color: Color) -> void:
	var image := Image.create_empty(16, 16, false, Image.FORMAT_RGB8)
	image.fill(color)
	var bytes := PackedByteArray()
	match path.get_extension():
		"png": bytes = image.save_png_to_buffer()
		"jpg": bytes = image.save_jpg_to_buffer()
		"webp": bytes = image.save_webp_to_buffer()
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null and not bytes.is_empty(), "wrote %s" % path.get_file())
	if file != null:
		file.store_buffer(bytes)


func textured_hull(path: String) -> void:
	var original := FileAccess.get_file_as_bytes(OLD)
	var binary_start := 20 + original.decode_u32(12)
	var json: Dictionary = JSON.parse_string(original.slice(20, binary_start).get_string_from_utf8())
	json["images"] = [{"uri": "maps/packed%20orm.png"}, {"uri": "maps/albedo.jpg"}, {"uri": "maps/emission.webp"}]
	json["extensionsUsed"] = ["EXT_texture_webp"]
	json["textures"] = [{"source": 0}, {"source": 1}, {"extensions": {"EXT_texture_webp": {"source": 2}}}]
	for material: Dictionary in json["materials"]:
		material["occlusionTexture"] = {"index": 0}
		material["pbrMetallicRoughness"]["metallicRoughnessTexture"] = {"index": 0}
		material["pbrMetallicRoughness"]["baseColorTexture"] = {"index": 1}
		material["emissiveTexture"] = {"index": 2}
	var chunk := JSON.stringify(json).to_utf8_buffer()
	while chunk.size() % 4 != 0:
		chunk.append(32)
	var binary := original.slice(binary_start)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_32(0x46546C67)
	file.store_32(2)
	file.store_32(20 + chunk.size() + binary.size())
	file.store_32(chunk.size())
	file.store_32(0x4E4F534A)
	file.store_buffer(chunk)
	file.store_buffer(binary)


func check_cached_hull(source: String, cached: String) -> void:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var packed := ResourceLoader.load(cached, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(packed != null and BUILD.append_ship_glb(doc, source, state) == OK, "raw and cached hulls load")
	if packed == null or state.get_meshes().is_empty():
		return
	var raw := doc.generate_scene(state)
	var built := packed.instantiate()
	var gate := GATE.new()
	var full_tris := 0
	var cached_tris := 0
	var orm: Texture2D
	for node: MeshInstance3D in built.find_children("*", "MeshInstance3D", true, false):
		var original: MeshInstance3D = raw.get_node(built.get_path_to(node))
		var mesh := ImporterMesh.from_mesh(node.mesh)
		var has_lod := false
		for surface in mesh.get_surface_count():
			var full: int = gate._tris(original.mesh, surface)
			full_tris += full
			cached_tris += gate._tris(node.mesh, surface)
			for lod in mesh.get_surface_lod_count(surface):
				var indices := mesh.get_surface_lod_indices(surface, lod)
				check(indices.size() > 0 and indices.size() < full * 3, "%s surface %d LOD %d reduces triangles" % [node.name, surface, lod])
				has_lod = true
			var paint := node.get_active_material(surface) as StandardMaterial3D
			check(paint != null and paint.ao_texture != null, "%s surface %d has packed paint" % [node.name, surface])
			if paint != null and paint.ao_texture != null:
				if orm == null:
					orm = paint.ao_texture
				check(orm == paint.ao_texture and orm == paint.roughness_texture and orm == paint.metallic_texture
					and FRAGMENTS.finish_maps(paint)[1] == orm, "hull and fragment share one ORM")
		check(has_lod, "%s has automatic LODs after saving" % node.name)
	var image := orm.get_image() if orm != null else null
	check(image != null and image.get_format() == Image.FORMAT_BPTC_RGBA and image.has_mipmaps(),
		"one mipmapped BC7 ORM payload for three material slots (one third of three identical payloads)")
	check(full_tris > 0 and cached_tris == full_tris, "scene gate full-detail fixture triangles hold: %d -> %d" % [full_tris, cached_tris])
	gate.free()
	raw.free()
	built.free()


func check_cached_paint(cached: String, expected: Color) -> void:
	var packed := ResourceLoader.load(cached, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	check(packed != null, "repainted scene loads")
	if packed == null:
		return
	var built := packed.instantiate()
	var hull := built.find_child("T560_fx", true, false) as MeshInstance3D
	var paint := hull.get_active_material(0) as StandardMaterial3D
	var image := paint.albedo_texture.get_image() if paint.albedo_texture != null else null
	check(image != null and image.decompress() == OK and Vector3(image.get_pixel(0, 0).r,
		image.get_pixel(0, 0).g, image.get_pixel(0, 0).b).distance_to(Vector3(expected.r, expected.g, expected.b)) < 0.08,
		"the saved ship scene uses the repainted albedo")
	built.free()


func _run() -> void:
	run = "user://install_refresh_check/%d" % int(Time.get_unix_time_from_system())
	var sh := run.path_join("ships").path_join(CODE)
	for d in [sh.path_join("maps"), run.path_join("gen"), run.path_join("replaced")]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	check_external_atlas()
	# 1. the old hull, with its breach parts and wreck chunks
	for suf in ["_damage", "_wreck"]:
		copy(OLD, sh.path_join(CODE + suf + ".glb"))
	var hull := sh.path_join(CODE + ".glb")
	textured_hull(hull)
	for map in MAPS:
		write_paint(sh.path_join("maps").path_join(map), Color.DARK_ORANGE)
	builder()
	var e := entry()
	check(e.has("res") and e.has("damage") and e.has("wreck"), "the old hull is cached with its damage and wreck scenes")
	if e.has("res"):
		check_cached_hull(hull, e["res"])
	var built_marker := "[assets] A4 ship " + CODE
	check(not built_marker in builder(), "unchanged paint keeps the warm ship cache")
	for map in MAPS:
		var path := sh.path_join("maps").path_join(map)
		var stamp := BUILD.source_stamp(run.path_join("ships"), CODE)
		if map == MAPS[0]:
			# Rewrite identical bytes after the file clock ticks to prove mtime alone invalidates the cache.
			OS.delay_msec(1100)
			copy(path, path + ".copy")
			copy(path + ".copy", path)
		else:
			write_paint(path, Color.REBECCA_PURPLE)
		var repaint_log := builder()
		check(str(entry().get("src", "")) != stamp and built_marker in repaint_log, "changing only %s rebuilds gen/ships" % map)
	e = entry()
	if e.has("res"):
		check_cached_paint(e["res"], Color.REBECCA_PURPLE)
	# 2. the install: the old hull's damage and wreck moved aside, the new hull copied over the old glb
	OS.delay_msec(1100)   # file times count in seconds: the new glb must not share the old one's stamp by chance
	for suf in ["_damage", "_wreck"]:
		DirAccess.rename_absolute(ProjectSettings.globalize_path(sh.path_join(CODE + suf + ".glb")), ProjectSettings.globalize_path(run.path_join("replaced").path_join(CODE + suf + ".glb")))
	var tmp := run.path_join("new_" + CODE + ".glb")
	new_hull(tmp)
	copy(tmp, sh.path_join(CODE + ".glb"))
	var log := builder()
	var e2 := entry()
	check(e2.has("res") and str(e2.get("src", "")) != str(e.get("src", "")), "the cache was rebuilt from the new hull (its source stamp changed)")
	check(not e2.has("damage") and not e2.has("wreck"), "the cache dropped the old hull's damage and wreck scenes")
	# 3. the readback stage 7 runs, and ShipView itself
	var out := []
	var rc := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script",
		"res://render/test/installed_ship_check.gd", "--", CODE, "--ships", run.path_join("ships"), "--gen", run.path_join("gen")], out, true)
	check(rc == 0 and "INSTALL READBACK PASS" in "\n".join(out), "the install readback passes on the new hull")
	SV.manifest_path = run.path_join("gen/manifest.json")
	SV.clear_static()
	var sv = SV.new()
	root.add_child(sv)
	sv.setup({"id": "t592", "fac": "corsair", "cls": "Battle-barge", "facing": 0, "code": CODE}, Vector3.ZERO)
	check(bool(sv.a4) and sv.find_child("zz592_new_hull", true, false) != null, "ShipView draws the new hull from the cache")
	check(sv.find_child("turret_0", true, false) == null, "ShipView draws none of the old hull's turrets")
	sv.queue_free()
	SV.clear_static()
	print("INSTALL REFRESH %s (%s)" % ["PASS" if fails == 0 else "FAIL: %d" % fails, ProjectSettings.globalize_path(run)])
	quit(0 if fails == 0 else 1)
