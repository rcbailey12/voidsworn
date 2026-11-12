extends SceneTree
# Issue 559 (read-only trace): one ship as the game shows it today (main's ShipView, look.gd, fx), at the battle camera
# (rig home angle, r 170) and zoomed in (r 60), plus the authored hard points and the places the game really uses,
# projected to the screen, written as JSON for the overlay sheet. Changes no game file.
# Env: P559_OUT (folder), P559_SHIPS ("CODE:fac:cls,..."), P559_W, P559_H.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const LOOK := preload("res://render/look.gd")
const CAMRIG := preload("res://render/camera_rig.gd")

var vp: SubViewport
var world: Node3D
var rig: Camera3D
var fx
var env: Environment
var key: DirectionalLight3D
var fill: DirectionalLight3D
var out := "/tmp/p559"
var W := 1920
var H := 1080
var info_all := {}


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	W = int(_env("P559_W", "1920"))
	H = int(_env("P559_H", "1080"))
	out = _env("P559_OUT", "/tmp/p559")
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	key = DirectionalLight3D.new()
	world.add_child(key)
	fill = DirectionalLight3D.new()
	world.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "max"})
	rig = CAMRIG.new()
	world.add_child(rig)
	rig.input_enabled = false
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": rig, "quality": "max", "shake": 0.0, "unit": 1.0})
	print("[559] renderer=%s adapter=%s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	# two far targets (out of frame): one off the starboard beam, one dead ahead
	_box("TS", Vector3(0, 0, 300))
	_box("TF", Vector3(400, 0, 0))
	var warmed := false
	for spec in _env("P559_SHIPS", "C19_51:corsair:Battle-barge").split(","):
		var p := spec.split(":")
		var code := p[0]
		var sv := _ship(code, p[1], p[2])
		if not warmed:
			await fx.warmup(rig)
			warmed = true
		var s = fx.ship("C")
		fx.set_engine("C", 1.0)
		for i in 90:
			await _step()
		var rec := {"code": code, "a4": sv.a4, "L": sv.L, "half_w": sv.half_w, "half_h": sv.half_h,
			"nozzles_from_kit": s.hull.nozzles_from_kit, "n_nozzles": s.hull.nozzles.size(), "tri_count": s.hull.tri_count,
			"hull_box": [s.hull.box.position.x, s.hull.box.position.y, s.hull.box.position.z, s.hull.box.size.x, s.hull.box.size.y, s.hull.box.size.z],
			"shots": {}}
		rec["materials"] = _materials(sv)
		await _pair(sv, s, code, "clean", rec)
		# hull lights only: key, fill and ambient off (engines stay at cruise)
		key.light_energy = 0.0
		fill.light_energy = 0.0
		var amb := env.ambient_light_energy
		env.ambient_light_energy = 0.0
		await _pair(sv, s, code, "lights", rec)
		LOOK.apply(env, key, fill, {"quality": "max"})
		env.ambient_light_energy = amb
		# braking and side jets exactly as a flown move fires them (ShipView's own puff functions)
		sv.glide = true
		sv._retro_puffs(1.0)
		sv._side_puffs(1.0, 1.0)
		sv._aft_puffs(1.0)
		for i in 3:
			await _step()
		await _shot(sv, s, code, "puffs", 60.0, rec)
		sv.glide = false
		for i in 60:
			await _step()
		# guns: one broadside volley at the starboard target and one heavy torpedo at the bow target, captured at the
		# first muzzle time
		for v in [["scatter", "TS", "fire_side"], ["htorp", "TF", "fire_bow"]]:
			var r: Dictionary = fx.volley("C", v[0], v[1], {"shots": [true, true, true, true], "debug": true})
			var t_fire: float = fx.now + (float((r["fires"] as Array).min()) if not (r["fires"] as Array).is_empty() else 0.0)
			while fx.now < t_fire + 0.04:
				await _step()
			await _shot(sv, s, code, v[2], 60.0, rec)
			for i in 150:
				await _step()
		# shield: one hit on the camera side, captured at its peak
		if s._shield_mat != null:
			var sp: Dictionary = s.shield_point(sv.to_global(s.hull.c) + Vector3(0, 40, 80))
			s.shield_hit(fx, sp["local"], fx.now, 1.0, 0.8, 2.0)
			for i in 8:
				await _step()
			await _shot(sv, s, code, "shield170", 170.0, rec)
			await _shot(sv, s, code, "shield60", 60.0, rec)
			rec["shield_radii"] = [s.hull.shield_radii().x, s.hull.shield_radii().y, s.hull.shield_radii().z]
			for i in 90:
				await _step()
		# damage: every section at stage 3 to 4, as the inside probe drives it
		fx.sync_ship("C", {"hp": 12.0, "maxHp": 100.0, "sh": [0, 0, 0, 0],
			"sec": {"prow": {"hp": 3.6, "max": 30.0}, "mid": {"hp": 4.8, "max": 40.0}, "eng": {"hp": 3.6, "max": 30.0}}})
		var frames := 0
		while frames < 3000 and (s._dmg_task >= 0 or frames < 150 or (s._hole_nodes.is_empty() and frames < 900)):
			await _step()
			frames += 1
		await _pair(sv, s, code, "damage", rec)
		info_all[code] = rec
		fx.remove_ship("C")
		sv.queue_free()
		for i in 60:
			await _step()
	var f := FileAccess.open(out.path_join("probe559.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(info_all, "  "))
	f.close()
	print("[559] done")
	quit(0)


func _materials(sv) -> Array:
	var outm: Array = []
	for m in sv.meshes:
		var mi := m as MeshInstance3D
		if mi == null or mi.mesh == null or String(mi.name).begins_with("skin_"):
			continue
		for i in mi.mesh.get_surface_count():
			var mat = mi.get_active_material(i)
			var d := {"mesh": String(mi.name), "surface": i, "class": mat.get_class() if mat else "none"}
			if mat is BaseMaterial3D:
				var bm := mat as BaseMaterial3D
				d["emission"] = bm.emission_enabled
				d["emission_energy"] = bm.emission_energy_multiplier
				d["normal"] = bm.normal_enabled
				d["ao"] = bm.ao_enabled
				d["rim"] = bm.rim
				d["cull"] = bm.cull_mode
				for prop in ["albedo_texture", "normal_texture", "roughness_texture", "metallic_texture", "emission_texture", "ao_texture"]:
					var t = bm.get(prop)
					if t is Texture2D:
						var img: Image = (t as Texture2D).get_image()
						d[prop] = [t.get_class(), (t as Texture2D).get_width(), (t as Texture2D).get_height(), img.get_format() if img else -1, img.get_mipmap_count() if img else 0, (t as Resource).resource_path]
			elif mat is ShaderMaterial:
				d["shader"] = "ShaderMaterial"
			outm.append(d)
	return outm


func _ship(code: String, fac: String, cls: String) -> Node3D:
	var sv: Node3D = SV.new()
	sv.name = "ship_C"
	world.add_child(sv)
	sv.setup({"id": "C", "fac": fac, "cls": cls, "facing": 0, "hp": 100, "maxHp": 100, "size": 1.22, "code": code}, Vector3.ZERO, true)
	var info := {"faction": fac, "cls": cls, "size": 1.22, "squadron": false, "flagship": false, "code": sv.code, "meshes": sv.meshes}
	fx.add_ship("C", sv, info)
	sv.fx_engines = true
	return sv


func _box(id: String, at: Vector3) -> void:
	var r := Node3D.new()
	r.name = "ship_" + id
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(20, 4, 6)
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	am.surface_set_material(0, StandardMaterial3D.new())
	r.add_child(mi)
	world.add_child(r)
	r.position = at
	fx.add_ship(id, r, {"faction": "hegemony", "cls": "Cruiser", "size": 0.8, "meshes": [mi], "shielded": false})


func _step() -> void:
	fx.step(1.0 / 60.0)
	await RenderingServer.frame_post_draw


func _pair(sv, s, code: String, tag: String, rec: Dictionary) -> void:
	await _shot(sv, s, code, tag + "170", 170.0, rec)
	await _shot(sv, s, code, tag + "60", 60.0, rec)


# the rig at its home angle (a -90 deg, b 0.98), centred on the ship, at radius r
func _shot(sv, s, code: String, tag: String, r: float, rec: Dictionary) -> void:
	rig.a = -PI / 2.0
	rig.b = 0.98
	rig.r = r
	rig.t = sv.global_position
	rig.snap()
	rig.current = true
	fx.camera = rig
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var name := "%s_%s" % [code, tag]
	vp.get_texture().get_image().save_jpg(out.path_join(name + ".jpg"), 0.92)
	rec["shots"][tag] = _points(sv, s)
	print("[559] wrote ", name)


func _px(p: Vector3) -> Array:
	var q: Vector2 = rig.unproject_position(p)
	return [snappedf(q.x, 0.1), snappedf(q.y, 0.1)]


func _points(sv, s) -> Dictionary:
	var d := {"hp": {}, "mounts": [], "bow": [], "nozzles": [], "anchors": {}, "puffs": {}, "core_game": [], "box": []}
	for n in sv.hull.find_children("hp_*", "Node3D", true, false):
		d["hp"][String(n.name)] = _px((n as Node3D).global_position)
	for side in ["port", "stb", "top"]:
		for m in s.hull.mounts[side]:
			d["mounts"].append([side, _px(s.to_world(m["p"]))])
	d["bow"] = _px(s.to_world(s.hull.bow))
	for nz in s.hull.nozzles:
		d["nozzles"].append(_px(s.to_world(nz["p"])))
	for k in s._anchors:
		d["anchors"][k] = _px(s.to_world(s._anchors[k]["p"]))
	d["core_game"] = _px(s.to_world(s.hull.c))
	var L: float = sv.L
	var hw: float = sv.half_w
	var hh: float = sv.half_h
	var pf := {"retro": [Vector3(L * 0.5, 0.2, hw * 0.45), Vector3(L * 0.5, 0.2, -hw * 0.45)],
		"side": [Vector3(L * 0.36, 0.2, -hw), Vector3(-L * 0.36, 0.2, -hw), Vector3(L * 0.36, 0.2, hw), Vector3(-L * 0.36, 0.2, hw)],
		"couple": [Vector3(L * 0.4, 0.2, hw), Vector3(-L * 0.4, 0.2, -hw)],
		"aft": [Vector3(-L * 0.48, hh * 0.6, hw * 0.7), Vector3(-L * 0.48, hh * 0.6, -hw * 0.7)]}
	for k in pf:
		var arr: Array = []
		for v in pf[k]:
			arr.append(_px(sv.to_global(v)))
		d["puffs"][k] = arr
	var b: AABB = s.hull.box
	for i in 8:
		d["box"].append(_px(s.to_world(b.get_endpoint(i))))
	return d
