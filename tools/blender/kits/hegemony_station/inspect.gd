extends SceneTree
# Review measurements, not a shipped game test. Run headless with the real game
# as --path and this absolute script path. Every unit and terrain cell comes
# from BattleAPI.new_battle_scenario. No typed unit or saved battle fixtures.
const API = preload("res://rules/battle_api.gd")
const BOARD = preload("res://render/board.gd")
const BV = preload("res://world/blocker_visuals.gd")
const SV = preload("res://render/ship_view.gd")
const PG = preload("res://render/placeholder_guard.gd")
const CAM = preload("res://render/camera_rig.gd")

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

static func imports_ready() -> bool:
	# A PackedScene can load with missing textures without triggering the block guard.
	# Refuse that incomplete import too, before measuring or saving a picture.
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ships/manifest.json"))
	for code in manifest.get("ships", {}):
		for filename in manifest.ships[code].get("files", {}):
			if not str(filename).get_extension().to_lower() in ["jpg", "jpeg", "png"]: continue
			var path: String = "res://assets/ships/" + str(code) + "/" + str(filename)
			var config := ConfigFile.new()
			if config.load(path + ".import") != OK:
				printerr("T2 missing texture import: ", path); return false
			var have := false
			for key in config.get_section_keys("remap"):
				if str(key).begins_with("path"):
					have = true
					if not FileAccess.file_exists(str(config.get_value("remap", key))):
						printerr("T2 incomplete texture cache: ", path); return false
			if not have: printerr("T2 texture import has no remap: ", path); return false
	return true

static func mesh_bounds(node: Node3D, relative: Node3D) -> AABB:
	var result := AABB()
	var have := false
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null: continue
		var box: AABB = relative.global_transform.affine_inverse() * mi.global_transform * mi.mesh.get_aabb()
		result = result.merge(box) if have else box
		have = true
	return result

func cruiser_mesh(node: Node3D, relative: Node3D, path: String) -> bool:
	# Transfer the actual fitted ShipView geometry to the CPU studio. OBJ axes
	# are converted here to Blender Z up. No substitute cruiser is modelled.
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_line("# Real ShipView cruiser, world units, Blender Z up")
	var offset := 1
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null: continue
		var xf := relative.global_transform.affine_inverse() * mi.global_transform
		var faces := mi.mesh.get_faces()
		for v in faces:
			var p: Vector3 = xf * v
			file.store_line("v %.7f %.7f %.7f" % [p.x, -p.z, p.y])
		for i in range(0, faces.size(), 3):
			# Godot clockwise -> OBJ counterclockwise.
			file.store_line("f %d %d %d" % [offset+i, offset+i+2, offset+i+1])
		offset += faces.size()
	file.close()
	return offset > 1

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): printerr("Expected output JSON path"); quit(1); return
	if not imports_ready(): quit(1); return
	var api = API.new()
	var error: String = api.load_rules()
	if error != "": printerr(error); quit(1); return
	api.new_battle_scenario({"seed": 373, "sector": 3, "admiral": "vex", "fleet": ["harrow"],
		"enemies": ["h_interdictor"], "fac": "hegemony", "obj": "rout", "shape": "open",
		"map": "station", "dep": "line", "kind": "battle"}, 373)
	var board := BOARD.new()
	root.add_child(board)
	var footprint := BV.station_review_footprint(api.view(), board.hex_world)
	if footprint.is_empty(): printerr("No station in the real scenario"); quit(1); return
	var cam := CAM.new()
	root.add_child(cam)
	var report := {"scenario_seed": 373, "footprint": footprint, "ships": [], "max_ship_height": 0.0,
		"comparisons": [],
		"camera": {"radius": cam.r, "beta": cam.b, "fov": cam.fov, "min_radius": cam.min_r},
		"cruiser_mesh": "cruiser.obj", "cruiser_source": "corsair|Cruiser; real ShipView geometry, studio material"}
	cam.free()
	var seen := {}
	var classes := {}
	for fac in api.R.FACTIONS:
		var roster: Array = api.R.FACTIONS[fac].get("roster", []).duplicate()
		var boss: String = str(api.R.FACTIONS[fac].get("boss", ""))
		if boss != "" and not roster.has(boss): roster.append(boss)
		if roster.is_empty(): continue
		api.new_battle_scenario({"seed": 373, "sector": 3, "admiral": "vex", "fleet": ["harrow"],
			"enemies": roster.duplicate(), "fac": fac, "obj": "rout", "shape": "open",
			"map": "station", "dep": "line", "kind": "battle"}, 373)
		for unit in api.view().get("units", []):
			if bool(unit.get("squadron", false)): continue
			var id := str(unit.get("fac")) + "|" + str(unit.get("cls"))
			if seen.has(id): continue
			seen[id] = true
			var sv := SV.new()
			root.add_child(sv)
			sv.setup(unit, Vector3.ZERO)
			if PG.stop_if_any(): return
			var box := mesh_bounds(sv.hull, sv)
			report.ships.append({"code": sv.code, "faction_class": id, "height": box.size.y, "length": sv.L})
			var cls := str(unit.get("cls"))
			if not classes.has(cls):
				classes[cls] = true
				report.comparisons.append({"code": sv.code, "class": cls, "length": sv.L, "unit": unit.duplicate(true)})
			report.max_ship_height = maxf(float(report.max_ship_height), box.size.y)
			if id == "corsair|Cruiser":
				if not cruiser_mesh(sv.hull, sv, args[0].get_base_dir().path_join("cruiser.obj")):
					printerr("Cannot write the real comparison cruiser"); quit(1); return
			sv.free()
	var f := FileAccess.open(args[0], FileAccess.WRITE)
	if f == null: printerr("Cannot write measurements"); quit(1); return
	f.store_string(JSON.stringify(report, "\t") + "\n"); f.close()
	print("T2 REAL INPUTS ", report.ships.size(), " hulls; max height ", report.max_ship_height,
		"; station cells ", footprint.cells.size())
	quit(0)
