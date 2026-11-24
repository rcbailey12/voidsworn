extends RefCounted
# Issue 1438: the export check for ship files. main.gd --check-export runs it on the exported build (the PC export job,
# tools/pc/jobs/g2_export.bat, gates on that exit code). The preset (godot/export_presets.cfg) leaves the source ship GLBs
# (assets/ships/<CODE>/*.glb) out of the package, because the game loads only the generated scenes the manifest names
# (render/build_assets.gd writes them). This check proves the package still holds everything the game reads:
#   - every row of res://gen/manifest.json loads: ship, damage and wreck scenes, max-detail scenes, hull and rock meshes,
#     the sky and the asteroid field (the old check only looked for the gen folder);
#   - every file those resources depend on is in the package (the generated C19_51 scene, the A16 Hullbreaker barge,
#     names its seven source JPG maps: drop one and its paint goes);
#   - every ship scene still has painted materials (an albedo texture on at least one surface);
#   - the squadron wing selector (render/squadron_wing.gd) still reads res://assets/ships/manifest.json and every wing
#     model it picks is a loadable scene;
#   - no source ship GLB went into the package (the size win this issue made stays).
# Static functions only; nothing here changes an asset. check() returns {"fails": [...], "notes": [...]}.

const GEN_MANIFEST := "res://gen/manifest.json"
const SHIP_SOURCES := "res://assets/ships"
const WING := preload("res://render/squadron_wing.gd")


static func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))


# The path part of a ResourceLoader.get_dependencies entry ("uid://...::Type::res://path", or a plain path).
static func dep_path(dep: String) -> String:
	if not dep.contains("::"):
		return dep
	var p := dep.get_slice("::", 2)
	if p == "":
		p = ResourceUID.ensure_path(dep.get_slice("::", 0))
	return p


# Every dependency of `path` that the package cannot provide.
static func missing_deps(path: String) -> Array:
	var out: Array = []
	for d in ResourceLoader.get_dependencies(path):
		var p := dep_path(str(d))
		if p == "" or not ResourceLoader.exists(p):
			out.append(p if p != "" else str(d))
	return out


static func _painted(root: Node) -> bool:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i) as BaseMaterial3D
			if m != null and m.albedo_texture != null:
				return true
	return false


# Loads one manifest file reference. kind: "scene", "mesh" or "texture". Returns "" or the reason it fails.
static func _load_one(path: String, kind: String, want_paint := false) -> String:
	if path == "":
		return "empty path"
	if not ResourceLoader.exists(path):
		return "not in the package"
	var gone := missing_deps(path)
	if not gone.is_empty():
		return "missing dependencies " + JSON.stringify(gone)
	var r = ResourceLoader.load(path)
	match kind:
		"scene":
			if not (r is PackedScene):
				return "not a scene"
			var root: Node = (r as PackedScene).instantiate()
			if root == null:
				return "does not instantiate"
			var painted := _painted(root)
			root.free()
			if want_paint and not painted:
				return "no painted surface (no albedo texture)"
		"mesh":
			if not (r is Mesh):
				return "not a mesh"
		"texture":
			if not (r is Texture2D):
				return "not a texture"
	return ""


# gen_manifest and sources move the cache and the ship folders for the fixture test (main/test/export_ship_check_test.gd); the
# wing part reads WING.ship_manifest_path and WING.ship_cache_dir, the same statics the selector reads.
static func check(gen_manifest := GEN_MANIFEST, sources := SHIP_SOURCES) -> Dictionary:
	var fails: Array = []
	var notes: Array = []
	var m = _read(gen_manifest)
	if not (m is Dictionary):
		fails.append("missing or unreadable: " + gen_manifest)
		return {"fails": fails, "notes": notes}
	var n := {"ships": 0, "damage": 0, "wreck": 0, "hi": 0, "hulls": 0, "rocks": 0}
	var ships: Dictionary = m.get("ships", {}) if m.get("ships") is Dictionary else {}
	for code in ships:
		var row = ships[code]
		if not (row is Dictionary):
			fails.append("ships/%s: row is not an object" % code)
			continue
		for part in ["res", "damage", "wreck"]:
			if part != "res" and not row.has(part):
				continue
			var why := _load_one(str(row.get(part, "")), "scene", part == "res")
			if why != "":
				fails.append("ships/%s %s %s: %s" % [code, part, str(row.get(part, "")), why])
				continue
			n["ships" if part == "res" else part] += 1
		# the source files the build read: not shipped (they are build input, never loaded by the game)
		for suf in ["", "_damage", "_wreck"]:
			var glb := sources.path_join(str(code)).path_join(str(code) + suf + ".glb")
			if ResourceLoader.exists(glb) or FileAccess.file_exists(glb):
				fails.append("source ship glb shipped: " + glb)
	for sec in [["hi", "scene"], ["hulls", "mesh"], ["rocks", "mesh"]]:
		var t = m.get(sec[0], {})
		if not (t is Dictionary):
			continue
		for code in t:
			var p := str(t[code].get("res", "")) if t[code] is Dictionary else ""
			var why := _load_one(p, sec[1])
			if why != "":
				fails.append("%s/%s %s: %s" % [sec[0], code, p, why])
			else:
				n[sec[0]] += 1
	if str(m.get("sky", "")) != "":
		var why := _load_one(str(m["sky"]), "texture")
		if why != "":
			fails.append("sky %s: %s" % [m["sky"], why])
	if str(m.get("field", "")) != "" and not FileAccess.file_exists(str(m["field"])):
		fails.append("field %s: not in the package" % m["field"])
	# the squadron wing selector reads the tracked ship manifest, then loads gen/ships/<code>.scn for each wing it picks
	var ship_manifest := WING.ship_manifest_path
	var sm = _read(ship_manifest)
	if not (sm is Dictionary) or not (sm.get("ships") is Dictionary):
		fails.append("missing or unreadable: " + ship_manifest + " (the wing selector reads it)")
	else:
		var wings := 0
		var seen := {}
		for code in sm["ships"]:
			var row = sm["ships"][code]
			if not (row is Dictionary) or row.get("cls") != "Squadron" or not row.has("wing_role"):
				continue
			var key := "%s|%s" % [row.get("faction", ""), row["wing_role"]]
			if seen.has(key):
				continue
			seen[key] = true
			var pick: String = WING._model_code(str(row.get("faction", "")), str(row["wing_role"]))
			if pick == "":
				continue   # an ambiguous pair: the wing draws the code-built craft on purpose
			var p := WING.ship_cache_dir.path_join(pick + ".scn")
			if not ships.has(pick):
				notes.append("note: wing %s picks %s, which this build has not generated (code-built craft)" % [key, pick])
				continue
			var why := _load_one(p, "scene")
			if why != "":
				fails.append("wing %s model %s: %s" % [key, p, why])
			else:
				wings += 1
		notes.append("wing models loaded: %d" % wings)
	notes.append("loaded: ships %d (each painted), damage %d, wreck %d, hi %d, hulls %d, rocks %d" % [n["ships"], n["damage"],
		n["wreck"], n["hi"], n["hulls"], n["rocks"]])
	return {"fails": fails, "notes": notes}
