extends SceneTree
# Refs #863. Measure loaded meshes, live cells and fitted ships, not typed bounds.
const API = preload("res://rules/battle_api.gd")
const BOARD = preload("res://render/board.gd")
const BV = preload("res://world/blocker_visuals.gd")
const PROPS = preload("res://assets/ships/a4_props.gd")
const SV = preload("res://render/ship_view.gd")
const PG = preload("res://render/placeholder_guard.gd")
const PROBE = preload("inspect.gd")
var failures: Array = []

func require(ok: bool, message: String) -> void:
	if not ok: failures.append(message); printerr(message)

func _init() -> void:
	process_frame.connect(_run,CONNECT_ONE_SHOT)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1: quit(1); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0].get_base_dir().path_join("debris_manifest.json")))
	var generator := get_script().resource_path.get_base_dir().path_join("debris.py")
	require(manifest.get("generator_sha256","") == FileAccess.get_sha256(generator),"Debris cache source is stale")
	require(manifest.get("material_source_sha256","") == FileAccess.get_sha256("res://assets/ships/station_T2/station_T2.glb"),
		"Debris material source differs from painted T2")
	var api = API.new()
	require(api.load_rules() == "","Rules load")
	api.new_battle_scenario({"seed":863,"sector":3,"admiral":"vex","fleet":["harrow"],
		"enemies":["c_marauder"],"fac":"corsair","obj":"rout","shape":"open",
		"map":"station","dep":"line","kind":"battle"},863)
	var board := BOARD.new()
	root.add_child(board)
	var footprint := BV.station_review_footprint(api.view(),board.hex_world)
	require(footprint.get("cells",[]).size() == 7,"Expected live seven-cell station")
	var before := JSON.stringify(api.view())
	var station := PROPS.station(46.0)
	if station == null: printerr("Missing painted T2 cache"); quit(1); return
	root.add_child(station)
	var debris := station.get_node_or_null("station_T2_debris")
	if debris == null: printerr("Missing debris cache"); quit(1); return
	debris.set_process(false)
	require(debris.get_meta("debris_export_sha256","") == FileAccess.get_sha256(args[0].get_base_dir().path_join("station_T2_debris.glb")),
		"Loaded debris cache differs from current export")
	require(JSON.stringify(api.view()) == before,"Art changed rules view")
	var base_triangles := 0
	for mi in station.find_children("*","MeshInstance3D",true,false):
		if debris.is_ancestor_of(mi): continue
		for s in mi.mesh.get_surface_count():
			base_triangles += mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX].size()/3
	var outside_radius := 0.0
	var centre := Vector3(footprint.centre[0],0,footprint.centre[2])
	for cell in footprint.cells:
		outside_radius = maxf(outside_radius,Vector3(cell.x,0,cell.z).distance_to(centre)+float(footprint.hex_radius))
	var floor_y := INF
	var lowest_ship := ""
	var ships: Array = []
	var seen := {}
	for faction in api.R.FACTIONS:
		var roster: Array = api.R.FACTIONS[faction].get("roster",[]).duplicate()
		var boss: String = str(api.R.FACTIONS[faction].get("boss",""))
		if boss != "" and not roster.has(boss): roster.append(boss)
		api.new_battle_scenario({"seed":863,"sector":3,"admiral":"vex","fleet":["harrow"],
			"enemies":roster,"fac":faction,"obj":"rout","shape":"open","map":"station",
			"dep":"line","kind":"battle"},863)
		for unit in api.view().units:
			if unit.get("squadron",false): continue
			var sv := SV.new()
			root.add_child(sv)
			sv.setup(unit,Vector3.ZERO)
			if PG.stop_if_any(): return
			if not seen.has(sv.code):
				seen[sv.code] = true
				var box := PROBE.mesh_bounds(sv.hull,sv)
				ships.append({"code":sv.code,"min_y":box.position.y})
				if box.position.y < floor_y: floor_y = box.position.y; lowest_ship = sv.code
			sv.free()
	var rows: Array = []
	var total := 0
	var min_clearance := INF
	var top := -INF
	var surfaces := 0
	for mi in debris.find_children("T2_debris_*","MeshInstance3D",true,false):
		var xf: Transform3D = debris.global_transform.affine_inverse() * mi.global_transform
		var radius := 0.0
		var count := 0
		for s in mi.mesh.get_surface_count():
			surfaces += 1
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			for vertex in arrays[Mesh.ARRAY_VERTEX]: radius = maxf(radius,(xf.basis*vertex).length())
			count += arrays[Mesh.ARRAY_INDEX].size()/3
			var mat := mi.get_active_material(s) as BaseMaterial3D
			require(mat != null and mat.albedo_texture != null and mat.normal_texture != null,
				"Missing inherited PBR paint: " + str(mi.name))
		var p: Vector3 = xf.origin
		var radial := Vector2(p.x,p.z).length()-radius-outside_radius
		# Board._station lifts the complete station root by 3, including debris.
		var maximum_y := p.y+radius+3.0
		require(radial > 0,"Tumble envelope enters blocked-cell circumcircle: " + str(mi.name))
		require(maximum_y < floor_y-2.0,"Debris enters fitted ship flight space: " + str(mi.name))
		require(absf(radius-float(mi.get_meta("debris_radius"))) < .001,"Export lost radius/scale: " + str(mi.name))
		var nearest: Array = []
		for cell in footprint.cells:
			# Worst station bearing: distance between concentric radial rings.
			var cell_r := Vector3(cell.x,0,cell.z).distance_to(centre)
			nearest.append({"q":cell.q,"r":cell.r,
				"all_bearings_clearance":Vector2(p.x,p.z).length()-radius-cell_r-float(footprint.hex_radius)})
		rows.append({"name":mi.name,"kind":mi.get_meta("debris_kind"),"triangles":count,
			"position":[p.x,p.y,p.z],"tumble_radius":radius,"blocked_cell_clearance":radial,
			"all_cells":nearest,"maximum_world_y":maximum_y,
			"rate_deg_per_second":rad_to_deg(float(mi.get_meta("debris_rate")))})
		total += count
		min_clearance = minf(min_clearance,radial)
		top = maxf(top,maximum_y)
	require(not rows.is_empty(),"Empty debris field")
	require(total == int(manifest.get("triangles",0)),"Exported triangles differ from generated parts")
	for i in rows.size():
		for j in range(i+1,rows.size()):
			var a: Array = rows[i].position
			var b: Array = rows[j].position
			var separation := Vector3(a[0],a[1],a[2]).distance_to(Vector3(b[0],b[1],b[2]))
			require(separation > float(rows[i].tumble_radius)+float(rows[j].tumble_radius),
				"Overlapping tumble envelopes: " + str(rows[i].name) + " / " + str(rows[j].name))
	var first := PROBE.mesh_bounds(debris,station)
	debris.pose_at(60.0)
	var later := PROBE.mesh_bounds(debris,station)
	require(not first.is_equal_approx(later),"Debris does not tumble")
	for node in station.find_children("*","CollisionObject3D",true,false):
		require(false,"Unexpected collision object " + str(node.name))
	var report := {"pass":failures.is_empty(),"failures":failures,"pieces":rows,"triangles":total,
		"base_station_triangles":base_triangles,"combined_triangles":base_triangles+total,
		"base_glb_sha256":FileAccess.get_sha256("res://assets/ships/station_T2/station_T2.glb"),
		"surfaces":surfaces,"footprint":footprint,"all_bearings_blocked_radius":outside_radius,
		"minimum_blocked_clearance":min_clearance,"maximum_debris_world_y":top,
		"lowest_fitted_ship_y":floor_y,"lowest_ship":lowest_ship,"measured_ships":ships,
		"clearance_proof":"Full vertex-radius spheres cover every tumble angle continuously; radial bound covers every station bearing. Visual debris has no collision or terrain entry.",
		"motion_check":"Loaded script changes actual mesh bounds after 60 seconds; 0.12 to 0.38 degrees/second, continuous axis rotation"}
	var file := FileAccess.open(args[0],FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	print("T2 DEBRIS CHECK ","PASS" if failures.is_empty() else "FAIL",": ",rows.size()," pieces; ",total,
		" triangles; cell clearance ",min_clearance,"; flight clearance ",floor_y-top)
	station.free()
	board.free()
	quit(0 if failures.is_empty() else 1)
