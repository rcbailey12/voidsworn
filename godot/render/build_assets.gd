extends SceneTree
# Builds the game's ships, rocks and backdrop into Godot resources with GPU-compressed textures, once, so the game loads
# fast (no runtime glTF or WebP decoding). Run headless from the project folder:
#   godot --headless --path godot --script res://render/build_assets.gd -- --repo <folder with hulls_hi/ hulls/ rocks_hi/>
#       [--hi <folder with the 8K flagship .glb files>] [--env <folder with sky_deadstar_8k.png>] [--force]
# Writes res://gen/hulls/<code>.res (a Mesh with its material), res://gen/hi/<code>.scn (the 8K flagships as scenes),
# res://gen/rocks/<code>.res, res://gen/sky.res and res://gen/manifest.json. Textures are mipmapped and compressed
# (S3TC/RGTC) so the GPU reads them as they are.

const HT := preload("res://render/hull_table.gd")
# bump when the generated files change shape; tools/pc/play_godot.bat rebuilds when gen\v<N>.txt is missing
const GEN_VERSION := 3

var repo := ""
var hi_dir := ""
var env_dir := ""
var force := false
var max_s := 0.0            # --max-seconds N: stop starting new items after N seconds (the next run carries on)
var t_start := 0
var out_of_time := false
var manifest := {"hulls": {}, "hi": {}, "rocks": {}, "sky": "", "ships": {}}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		match a[i]:
			"--repo": repo = a[i + 1]; i += 1
			"--hi": hi_dir = a[i + 1]; i += 1
			"--env": env_dir = a[i + 1]; i += 1
			"--force": force = true
			"--max-seconds": max_s = float(a[i + 1]); i += 1
		i += 1
	if repo == "":
		repo = ProjectSettings.globalize_path("res://").get_base_dir().get_base_dir()
	var t0 := Time.get_ticks_msec()
	for d in ["res://gen", "res://gen/hulls", "res://gen/hi", "res://gen/rocks"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	t_start = Time.get_ticks_msec()
	var old = _read_json("res://gen/manifest.json")
	if old is Dictionary and not force:
		manifest = old
		for k in ["hulls", "hi", "rocks", "ships"]:
			if not manifest.has(k):
				manifest[k] = {}
	var codes := {}
	for k in HT.AI_HULLS:
		codes[HT.AI_HULLS[k]] = true
	for code in codes:
		_build_hull(code)
	if hi_dir != "":
		for code in HT.HI_FILES:
			_build_hi(code)
	_build_a4_ships()
	_build_rocks()
	_build_sky()
	# the A3 asteroid field placements (seed 7), used as backdrop dressing round the board (render/backdrop.gd)
	for p in [env_dir.path_join("asteroids.json"), repo.path_join("contrib/opus/enginetest/assets/env/asteroids.json")]:
		if p != "" and FileAccess.file_exists(p):
			var af := FileAccess.open("res://gen/asteroids.json", FileAccess.WRITE)
			af.store_string(FileAccess.get_file_as_string(p))
			af.close()
			manifest["field"] = "res://gen/asteroids.json"
			break
	manifest["version"] = GEN_VERSION
	if out_of_time:
		print("[assets] time budget reached: run again to finish (progress kept)")
	else:
		var vf := FileAccess.open("res://gen/v%d.txt" % GEN_VERSION, FileAccess.WRITE)
		vf.store_string("built")
		vf.close()
	var f := FileAccess.open("res://gen/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "  "))
	f.close()
	print("[assets] done in %.1f s: %d hulls, %d max-detail, %d rocks, sky %s" % [(Time.get_ticks_msec() - t0) / 1000.0,
		manifest["hulls"].size(), manifest["hi"].size(), manifest["rocks"].size(), manifest["sky"] != ""])
	quit(0)


# an item is current when it was built by this generator version and its file is there; past the time budget nothing new
# is started (it counts as current for now, and the version marker is not written, so the next run carries on)
func _current(table: Dictionary, code: String, out: String) -> bool:
	if not force and table.has(code) and FileAccess.file_exists(out) and int(table[code].get("v", 0)) >= GEN_VERSION:
		return true
	if max_s > 0.0 and (Time.get_ticks_msec() - t_start) / 1000.0 > max_s:
		out_of_time = true
		return true
	_save_manifest()
	return false


func _save_manifest() -> void:
	var f := FileAccess.open("res://gen/manifest.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(manifest, "  "))


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _find(name: String) -> String:
	for d in ["hulls_hi", "hulls"]:
		var p := repo.path_join(d).path_join(name)
		if FileAccess.file_exists(p):
			return p
	return ""


# ---------------------------------------------------------------- textures

func _tex(path: String, normal := false, srgb := true) -> Texture2D:
	if path == "" or not FileAccess.file_exists(path):
		return null
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(path)
	var err := ERR_FILE_UNRECOGNIZED
	if path.ends_with(".webp"):
		err = img.load_webp_from_buffer(bytes)
	elif path.ends_with(".png"):
		err = img.load_png_from_buffer(bytes)
	elif path.ends_with(".jpg"):
		err = img.load_jpg_from_buffer(bytes)
	if err != OK:
		push_warning("texture not loaded: " + path)
		return null
	return _compress(img, normal, srgb)


func _compress(img: Image, normal := false, _srgb := true) -> Texture2D:
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8 and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGBA8 if img.detect_alpha() != Image.ALPHA_NONE else Image.FORMAT_RGB8)
	img.generate_mipmaps()
	# the ship texture rule (godot/assets/ships/README.md, A4): BC7 high quality for colour, ORM and emissive; BC5 for
	# normal maps (RGTC from the normal source); mipmaps on; nothing HDR. Falls back to S3TC where BC7 is unavailable.
	if normal:
		img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL)
	elif img.compress(Image.COMPRESS_BPTC, Image.COMPRESS_SOURCE_GENERIC) != OK:
		img.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_GENERIC)
	return ImageTexture.create_from_image(img)


# ---------------------------------------------------------------- the game's hull format (ships3d.js decodeAIHull)

func _decode(j: Dictionary) -> Dictionary:
	var ext: Array = j["ext"]
	var p := Marshalls.base64_to_raw(j["p"])
	var q := Marshalls.base64_to_raw(j["q"])
	var ib := Marshalls.base64_to_raw(j["i"])
	var n := p.size() / 6
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	pos.resize(n)
	nor.resize(n)
	var ex := float(ext[0]) / 32767.0
	var ey := float(ext[1]) / 32767.0
	var ez := float(ext[2]) / 32767.0
	for v in n:
		pos[v] = Vector3(p.decode_s16(v * 6) * ex, p.decode_s16(v * 6 + 2) * ey, p.decode_s16(v * 6 + 4) * ez)
		nor[v] = Vector3(q.decode_s8(v * 3), q.decode_s8(v * 3 + 1), q.decode_s8(v * 3 + 2)).normalized()
	var idx := PackedInt32Array()
	if bool(j.get("i32", false)):
		idx = ib.to_int32_array()
	else:
		idx.resize(ib.size() / 2)
		for k in idx.size():
			idx[k] = ib.decode_u16(k * 2)
	# Godot's winding is the reverse of glTF's and Babylon's: swap two corners of every triangle
	for k in range(0, idx.size() - 2, 3):
		var t := idx[k + 1]
		idx[k + 1] = idx[k + 2]
		idx[k + 2] = t
	var out := {"pos": pos, "nor": nor, "idx": idx}
	if j.has("u"):
		var u := Marshalls.base64_to_raw(j["u"])
		var uv := PackedVector2Array()
		uv.resize(n)
		for v in n:
			uv[v] = Vector2(u.decode_u16(v * 4) / 65535.0, 1.0 - u.decode_u16(v * 4 + 2) / 65535.0)
		out["uv"] = uv
	if j.has("a"):
		var a := Marshalls.base64_to_raw(j["a"])
		var col := PackedColorArray()
		col.resize(n)
		for v in n:
			var k := a[v] / 255.0
			col[v] = Color(k, k, k, 1.0)
		out["col"] = col
	return out


func _mesh(d: Dictionary, mat: Material) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = d["pos"]
	arr[Mesh.ARRAY_NORMAL] = d["nor"]
	if d.has("uv"):
		arr[Mesh.ARRAY_TEX_UV] = d["uv"]
	if d.has("col"):
		arr[Mesh.ARRAY_COLOR] = d["col"]
	arr[Mesh.ARRAY_INDEX] = d["idx"]
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	if d.has("uv"):
		# tangents for the normal map
		var st := SurfaceTool.new()
		st.create_from(am, 0)
		st.generate_tangents()
		am = st.commit()
	am.surface_set_material(0, mat)
	return am


func _fac_of(code: String) -> String:
	for k in HT.AI_HULLS:
		if HT.AI_HULLS[k] == code:
			var f: String = k.split("|")[0]
			return f if HT.FINISH.has(f) else "hegemony"
	return "hegemony"


func _build_hull(code: String) -> void:
	var out := "res://gen/hulls/%s.res" % code
	if _current(manifest["hulls"], code, out):
		return
	var jp := _find(code + ".json")
	if jp == "":
		push_warning("hull missing: " + code)
		return
	var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(jp))
	var d := _decode(j)
	var fac := _fac_of(code)
	var fin: Array = HT.FINISH[fac]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(fin[0])
	m.metallic = fin[1]
	m.roughness = fin[2]
	m.vertex_color_use_as_albedo = d.has("col")  # the baked cavity and occlusion, per vertex
	var dir := jp.get_base_dir()
	if d.has("uv"):
		var nt := _tex(dir.path_join(code + "_n.webp"), true, false)
		if nt != null:
			m.normal_enabled = true
			m.normal_texture = nt
		var mt := _tex(dir.path_join(code + "_m.webp"), false, false)
		if mt != null:
			m.ao_enabled = true
			m.ao_texture = mt
			m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
			m.ao_light_affect = 0.9
	var mesh := _mesh(d, m)
	ResourceSaver.save(mesh, out, ResourceSaver.FLAG_COMPRESS)
	var aabb := mesh.get_aabb()
	manifest["hulls"][code] = {"v": GEN_VERSION, "res": out, "fac": fac, "tris": idx_tris(d), "aabb": [aabb.position.x, aabb.position.y, aabb.position.z, aabb.size.x, aabb.size.y, aabb.size.z]}
	print("[assets] hull %s (%s) %d tris" % [code, jp.get_base_dir().get_file(), idx_tris(d)])


func idx_tris(d: Dictionary) -> int:
	return (d["idx"] as PackedInt32Array).size() / 3


# ---------------------------------------------------------------- the 8K flagships

func _build_hi(code: String) -> void:
	var out := "res://gen/hi/%s.scn" % code
	if _current(manifest["hi"], code, out):
		return
	var files: Array = HT.HI_FILES[code]
	var root := Node3D.new()
	root.name = code
	for fname in files:
		var path := hi_dir.path_join(fname)
		if not FileAccess.file_exists(path):
			root.free()
			return
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		st.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
		if doc.append_from_file(path, st) != OK:
			push_warning("glTF not loaded: " + path)
			root.free()
			return
		var jm: Array = st.json.get("materials", [])
		var mats := st.get_materials()
		for mi in mini(jm.size(), mats.size()):
			var bm := mats[mi] as BaseMaterial3D
			if bm == null:
				continue
			if (jm[mi] as Dictionary).has("emissiveTexture") and not ((jm[mi] as Dictionary).get("extensions", {}) as Dictionary).has("KHR_materials_emissive_strength"):
				bm.emission_energy_multiplier = 4.0   # as the A2 max mode: windows and running lights reach bloom
			_compress_material(bm)
		var scene := doc.generate_scene(st)
		root.add_child(scene)
	_own(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, out, ResourceSaver.FLAG_COMPRESS)
	root.free()
	manifest["hi"][code] = {"v": GEN_VERSION, "res": out}
	print("[assets] max-detail %s" % code)


# ---------------------------------------------------------------- A4 kit ships (godot/assets/ships/<CODE>/)

# A4's ships: the ship scene with every child kept by name (skin_<n> and skin_<n>_heavy hull patches that a breach hole
# replaces, hp_* hard points with their metadata), plus the breach parts (<CODE>_damage.glb, for G4) and the wreck chunks.
# True chirality (+Z starboard), so the battle does not mirror these. fx/API.md section 14; godot/assets/ships/README.md.
func _build_a4_ships() -> void:
	if not manifest.has("ships"):
		manifest["ships"] = {}
	for d in ["res://gen/ships", "res://gen/damage", "res://gen/wreck"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))
	var base := "res://assets/ships"
	var da := DirAccess.open(base)
	if da == null:
		return
	for code in da.get_directories():
		var src := base.path_join(code).path_join(code + ".glb")
		if not FileAccess.file_exists(src):
			continue
		var out := "res://gen/ships/%s.scn" % code
		# A4 re-exports ships under the same names: a changed source (time or size of the ship, damage or wreck glb)
		# rebuilds that ship even when the generator version is current
		var stamp := ""
		var newest := 0
		for suf in ["", "_damage", "_wreck"]:
			var sp0 := base.path_join(code).path_join(code + suf + ".glb")
			if FileAccess.file_exists(sp0):
				var fa := FileAccess.open(sp0, FileAccess.READ)
				var mt := FileAccess.get_modified_time(sp0)
				newest = maxi(newest, mt)
				stamp += "%d:%d;" % [mt, fa.get_length() if fa != null else 0]
		if manifest["ships"].has(code):
			var me: Dictionary = manifest["ships"][code]
			if not me.has("src") and FileAccess.file_exists(out) and FileAccess.get_modified_time(out) >= newest:
				me["src"] = stamp  # built before stamps were kept, from these same files
			if str(me.get("src", "")) != stamp:
				me["v"] = 0
		if _current(manifest["ships"], code, out):
			continue
		var e := {"v": GEN_VERSION, "res": out, "mirror": false, "src": stamp}
		if _glb_to_scene(src, out, code):
			for extra in [["_damage", "res://gen/damage/%s_damage.scn"], ["_wreck", "res://gen/wreck/%s_wreck.scn"]]:
				var sp := base.path_join(code).path_join(code + extra[0] + ".glb")
				if FileAccess.file_exists(sp) and _glb_to_scene(sp, extra[1] % code, code + extra[0]):
					e[extra[0].substr(1)] = extra[1] % code
			manifest["ships"][code] = e
			print("[assets] A4 ship %s%s" % [code, " (+ breach parts)" if e.has("damage") else ""])
	_check_a4_ships()


# one line per A4 ship as the game will load it: skins, heavy skins, hard points, breach holes and heavies, wreck chunks
func _check_a4_ships() -> void:
	var n := 0
	for code in manifest.get("ships", {}):
		var e: Dictionary = manifest["ships"][code]
		var c := {"skin": 0, "heavy": 0, "hp": 0, "hole": 0, "hvy": 0, "chunks": 0, "mesh": 0}
		var parts := [[str(e.get("res", "")), "ship"], [str(e.get("damage", "")), "damage"], [str(e.get("wreck", "")), "wreck"]]
		var ok := true
		for pr in parts:
			if pr[0] == "":
				continue
			var ps = load(pr[0])
			if not (ps is PackedScene):
				ok = false
				continue
			var root: Node = (ps as PackedScene).instantiate()
			for nd in root.find_children("*", "", true, false):
				var nm := str(nd.name)
				if pr[1] == "ship":
					if nm.begins_with("skin_"):
						c["heavy" if nm.ends_with("_heavy") else "skin"] += 1
					elif nm.begins_with("hp_"):
						c["hp"] += 1
					elif nd is MeshInstance3D:
						c["mesh"] += 1
				elif pr[1] == "damage":
					if nm.ends_with("_hole"):
						c["hole"] += 1
					elif nm.ends_with("_heavy"):
						c["hvy"] += 1
				elif nd is MeshInstance3D:
					c["chunks"] += 1
			root.free()
		n += 1
		print("[assets] check %s loads=%s skins=%d heavy_skins=%d hardpoints=%d hull_meshes=%d holes=%d heavies=%d wreck_chunks=%d" % [code, str(ok), c["skin"], c["heavy"], c["hp"], c["mesh"], c["hole"], c["hvy"], c["chunks"]])
	print("[assets] check: %d A4 ships in the manifest" % n)


func _glb_to_scene(path: String, out: String, name: String) -> bool:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	st.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_EMBED_AS_UNCOMPRESSED
	st.base_path = path.get_base_dir()
	if doc.append_from_file(path, st) != OK:
		push_warning("glTF not loaded: " + path)
		return false
	for m in st.get_materials():
		if m is BaseMaterial3D:
			_compress_material(m as BaseMaterial3D)
	var scene := doc.generate_scene(st)
	scene.name = name
	_own(scene, scene)
	var ps := PackedScene.new()
	ps.pack(scene)
	var ok := ResourceSaver.save(ps, out, ResourceSaver.FLAG_COMPRESS) == OK
	scene.free()
	return ok


func _compress_material(bm: BaseMaterial3D) -> void:
	for prop in ["albedo_texture", "normal_texture", "orm_texture", "roughness_texture", "metallic_texture", "emission_texture", "ao_texture"]:
		var t = bm.get(prop)
		if t is Texture2D and not (t is CompressedTexture2D):
			var img: Image = (t as Texture2D).get_image()
			if img != null and not img.is_empty():
				bm.set(prop, _compress(img, prop == "normal_texture"))


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


# ---------------------------------------------------------------- rocks and the backdrop

func _build_rocks() -> void:
	var idxp := repo.path_join("rocks_hi/index.json")
	var dir := "rocks_hi"
	if not FileAccess.file_exists(idxp):
		idxp = repo.path_join("rocks/index.json")
		dir = "rocks"
	if not FileAccess.file_exists(idxp):
		return
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(idxp))
	for set_name in index:
		if not HT.ROCK_TINT.has(set_name):
			continue
		for k in int(index[set_name]):
			var code := "%s%02d" % [set_name, k]
			var out := "res://gen/rocks/%s.res" % code
			if _current(manifest["rocks"], code, out):
				continue
			var jp := repo.path_join(dir).path_join(code + ".json")
			if not FileAccess.file_exists(jp):
				continue
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(jp))
			var d := _decode(j)
			var m := StandardMaterial3D.new()
			m.albedo_color = HT.ROCK_TINT[set_name]
			m.roughness = 0.9 if set_name != "RIC" else 0.55
			m.metallic = 0.0
			if d.has("uv"):
				var nt := _tex(repo.path_join(dir).path_join(code + "_n.webp"), true, false)
				if nt != null:
					m.normal_enabled = true
					m.normal_texture = nt
				var mt := _tex(repo.path_join(dir).path_join(code + "_m.webp"), false, false)
				if mt != null:
					m.ao_enabled = true
					m.ao_texture = mt
			var mesh := _mesh(d, m)
			ResourceSaver.save(mesh, out, ResourceSaver.FLAG_COMPRESS)
			manifest["rocks"][code] = {"v": GEN_VERSION, "res": out, "set": set_name}


func _build_sky() -> void:
	var out := "res://gen/sky.res"
	if not force and manifest["sky"] != "" and FileAccess.file_exists(out) and int(manifest.get("sky_v", 0)) >= GEN_VERSION:
		return
	var cands := [env_dir.path_join("sky_deadstar_8k.png"), repo.path_join("contrib/opus/enginetest/assets/env/sky_deadstar_8k.png"),
		repo.path_join("contrib/opus/enginetest/starfield_4k.png")]
	for p in cands:
		if p != "" and FileAccess.file_exists(p):
			var t := _tex(p)
			if t != null:
				ResourceSaver.save(t, out, ResourceSaver.FLAG_COMPRESS)
				manifest["sky"] = out
				manifest["sky_v"] = GEN_VERSION
				print("[assets] sky from " + p)
				return
