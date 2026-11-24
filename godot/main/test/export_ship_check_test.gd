extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1438: main/export_ship_check.gd, the ship part of main.gd --check-export, on fixtures in user:// (GitHub has no
# gen folder and no export). It must pass a painted, complete row and fail each way a package can lose ship files:
# a missing damage scene, a scene whose texture file is gone, an unpainted ship, a mesh row that is not a mesh, and a
# source ship GLB left in the package.
#   godot --headless --path godot --script res://main/test/export_ship_check_test.gd
# Prints EXPORT_SHIP_CHECK PASS or FAIL; exit 0 only on PASS.

const CHECK := preload("res://main/export_ship_check.gd")

var fails := 0


func _init() -> void:
	GUARD.arm(self, "export_ship_check_test")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1


func _scene(path: String, tex_path: String) -> void:
	var root := Node3D.new()
	root.name = "Ship"
	var mi := MeshInstance3D.new()
	mi.name = "Hull"
	mi.mesh = BoxMesh.new()
	if tex_path != "":
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(tex_path)
		mi.mesh.surface_set_material(0, mat)
	root.add_child(mi)
	mi.owner = root
	var ps := PackedScene.new()
	ps.pack(root)
	root.free()
	check(ResourceSaver.save(ps, path) == OK, "fixture written: " + path.get_file())


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _has(arr: Array, part: String) -> bool:
	for s in arr:
		if str(s).contains(part):
			return true
	return false


func _run() -> void:
	check(CHECK.dep_path("uid://abc::Texture2D::res://assets/ships/A16_23/A16_23_base.jpg") ==
		"res://assets/ships/A16_23/A16_23_base.jpg", "dep_path reads the path out of a uid dependency")
	check(CHECK.dep_path("res://a.jpg") == "res://a.jpg", "dep_path keeps a plain path")

	var dir := "user://export_ship_check_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(dir + "/ships/ZZA")
	var img := Image.create(4, 4, false, Image.FORMAT_RGB8)
	img.fill(Color(0.8, 0.4, 0.1))
	var tex := dir + "/paint.res"
	var gone_tex := dir + "/gone.res"
	check(ResourceSaver.save(ImageTexture.create_from_image(img), tex) == OK, "fixture texture written")
	check(ResourceSaver.save(ImageTexture.create_from_image(img), gone_tex) == OK, "fixture texture 2 written")
	_scene(dir + "/zza.scn", tex)
	_scene(dir + "/zza_wreck.scn", tex)
	_scene(dir + "/plain.scn", "")
	_scene(dir + "/lost.scn", gone_tex)
	DirAccess.remove_absolute(gone_tex)
	var mesh := dir + "/box.tres"
	check(ResourceSaver.save(BoxMesh.new(), mesh) == OK, "fixture mesh written")

	# 1. a complete package: painted ship and wreck, a hull mesh, no source GLB
	var good := {"ships": {"ZZA": {"res": dir + "/zza.scn", "wreck": dir + "/zza_wreck.scn"}}, "hulls": {"ZZA": {"res": mesh}}}
	_write(dir + "/good.json", JSON.stringify(good))
	var r: Dictionary = CHECK.check(dir + "/good.json", dir + "/ships")
	check(r["fails"].is_empty(), "a complete package passes: " + str(r["fails"]))
	check(_has(r["notes"], "ships 1 (each painted), damage 0, wreck 1") and _has(r["notes"], "hulls 1"),
		"the counts note names what loaded: " + str(r["notes"]))

	# 2. the same package with a source GLB left in it
	_write(dir + "/ships/ZZA/ZZA_wreck.glb", "glTF")
	r = CHECK.check(dir + "/good.json", dir + "/ships")
	check(_has(r["fails"], "source ship glb shipped: " + dir + "/ships/ZZA/ZZA_wreck.glb"), "a shipped source GLB fails: " + str(r["fails"]))
	DirAccess.remove_absolute(dir + "/ships/ZZA/ZZA_wreck.glb")

	# 3. each way a row can break
	var bad := {
		"ships": {
			"ZZA": {"res": dir + "/zza.scn", "damage": dir + "/no_such_damage.scn"},
			"ZZB": {"res": dir + "/plain.scn"},
			"ZZC": {"res": dir + "/lost.scn"},
		},
		"rocks": {"ZZR": {"res": dir + "/zza.scn"}},
		"sky": dir + "/no_sky.png",
		"field": dir + "/no_field.json",
	}
	_write(dir + "/bad.json", JSON.stringify(bad))
	r = CHECK.check(dir + "/bad.json", dir + "/ships")
	var f: Array = r["fails"]
	check(_has(f, "ships/ZZA damage") and _has(f, "not in the package"), "a missing damage scene fails")
	check(_has(f, "ships/ZZB res") and _has(f, "no painted surface"), "an unpainted ship fails")
	check(_has(f, "ships/ZZC res") and _has(f, "missing dependencies") and _has(f, "gone.res"), "a scene whose texture is gone fails")
	check(_has(f, "rocks/ZZR") and _has(f, "not a mesh"), "a rock row that is not a mesh fails")
	check(_has(f, "sky ") and _has(f, "field "), "a missing sky and field fail")
	check(f.size() == 6, "exactly six fails, one per break: " + str(f))

	# 4. no manifest at all
	r = CHECK.check(dir + "/none.json", dir + "/ships")
	check(_has(r["fails"], "missing or unreadable"), "a missing gen manifest fails")

	print("EXPORT_SHIP_CHECK " + ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(0 if fails == 0 else 1)
