extends SceneTree
const W = preload("res://world/world.gd")
const L = preload("res://world/world_living.gd")
const WR = preload("res://world/world_rocks.gd")
class BoxShip extends Node3D:
	var fac = "corsair"
	var meshes = []
var failures = 0
var tested = 0
func _initialize(): run.call_deferred()
func check(ok, why):
	tested += 1
	if not ok: failures += 1; printerr("FAIL ", why)
func run():
	for pair in [["scene_t",0.0],["fx_gain",0.5556],["fx_calm",0.0],["fx_px",1.0]]:
		RenderingServer.global_shader_parameter_add(pair[0],RenderingServer.GLOBAL_VAR_TYPE_FLOAT,pair[1])
	for tier in ["low", "max"]:
		for kind in ["stone", "iron", "carbon", "ice", "crystal"]:
			var world = W.new()
			root.add_child(world)
			world.quality = tier
			world._rock_kind = kind
			world._well = Vector3(0,-10,0)
			var live = L.new()
			world.add_child(live)
			live.W = world
			live.rng.seed = 100
			# Exercise the real legacy builder before building the living layer.
			world._batch = WR.Batch.new()
			world._rng.seed = 100
			world.debris_field(Vector3(69.282032,0,0),kind)
			world._batch.build(world,Callable(WR,"mesh"))
			var ps = [Vector3(69.282032,0,0), Vector3(60.621778,0,15), Vector3(51.961524,0,30)]
			world._terr_pts["debris"] = ps
			live._debris(ps)
			live._well(world._well)
			check(not live._legacy_debris_mats.is_empty(), "legacy scatter is identified separately")
			for mat in live._legacy_debris_mats: check(mat.get_shader_parameter("living_terrain") == true, "legacy hidden while living visible")
			live.visible = false
			for mat in live._legacy_debris_mats: check(mat.get_shader_parameter("living_terrain") == false, "legacy restored for old looks")
			live.visible = true
			for mat in live._legacy_debris_mats: check(mat.get_shader_parameter("living_terrain") == true, "legacy hidden after return to cine")
			check(world._mat(kind).get_shader_parameter("legacy_debris") != true, "original far-rock material unaffected")
			var rocks = 0; var wrecks = 0
			var heroes = [false, false, false]
			for child in live.get_children():
				if not child is MultiMeshInstance3D: continue
				var mm = child.multimesh
				if child.name == "DebrisDust":
					check(mm.instance_count >= ps.size()*16, "dust stays present at "+tier)
					continue
				if child.name == "WellInfall":
					check(mm.instance_count == (91 if tier=="low" else 182), "well tier count")
					continue
				var is_wreck = str(child.name).begins_with("WreckKit")
				for i in mm.instance_count:
					var xf = mm.get_instance_transform(i)
					var radius = L._piece_radius(mm.mesh)*xf.basis.get_scale().x
					var nearest = 0
					for j in ps.size():
						if xf.origin.distance_squared_to(ps[j]) < xf.origin.distance_squared_to(ps[nearest]): nearest=j
					check(L._clear_of_hexes(xf.origin-ps[nearest],radius), "complete tumble sphere clears ship hexes")
					var size = mm.mesh.get_aabb().size * xf.basis.get_scale().x
					var span = max(size.x,max(size.y,size.z))
					check(span <= 8.6601, "actual debris span cap")
					if is_wreck:
						wrecks+=1
						if span >= 3.999 and span <= 7.601: heroes[nearest]=true
						var rate = Vector3(mm.get_instance_custom_data(i).r,mm.get_instance_custom_data(i).g,mm.get_instance_custom_data(i).b).length()
						check(rate <= L.tumble_rate(xf.basis.get_scale().x)+0.0001, "tumble cap")
						check((xf.basis.orthonormalized()*Vector3(mm.get_instance_custom_data(i).r,mm.get_instance_custom_data(i).g,mm.get_instance_custom_data(i).b).normalized()).dot(Vector3.UP)>0.999, "ring shares orbital direction")
					else: rocks+=1
			check(rocks >= ps.size()*(8 if tier=="low" else 15) and rocks <= ps.size()*(12 if tier=="low" else 22), "recorded rock count")
			check(wrecks>=ps.size()*3 and wrecks<=ps.size()*6, "recorded wreck count")
			check(heroes.all(func(v): return v), "hero span 4 to 7.6 in every hex")
			if kind == "stone" and tier == "max":
				var ship = BoxShip.new()
				world.add_child(ship)
				var mi = MeshInstance3D.new()
				var am = ArrayMesh.new()
				am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,BoxMesh.new().get_mesh_arrays())
				mi.mesh = am
				mi.material_override = StandardMaterial3D.new()
				ship.add_child(mi)
				ship.meshes.append(mi)
				live.use_ship_debris([ship])
				while live._chunk_task >= 0: await process_frame
				check(live.has_node("HullDebris"), "painted hull replacement installed")
				var caps = 0
				for pivot in (live.get_node("HullDebris").get_children() if live.has_node("HullDebris") else []):
					var drawn = pivot.get_child(0)
					for index in drawn.mesh.get_surface_count():
						var material = drawn.mesh.surface_get_material(index)
						if material is ShaderMaterial and "varying vec3 slag_p;" in material.shader.code:
							caps += 1
							check(material.get_shader_parameter("heat") == 0.0, "weathered painted cut face stays cold")
				check(caps > 0, "cut-cap integration exercised real generated faces")
			world.free()
	for mesh in L._shard_meshes():
		var points = L._hot_points(mesh)
		check(points.size()==3, "three authored hot points")
		for i in 3:
			check(points[i].length()<1.01, "hot points lie on source mesh")
	print("FX100 geometry: ", tested, " checks, ", failures, " failures")
	quit(1 if failures else 0)
