extends "res://bench/look_bench.gd"
# Issue 362 readability probe: the look bench's own fleet part (render/hull_table.gd AI_HULLS, the bench's skies, ship set
# up and camera 170 at 1 to 1 pixels, 400x240 cells), plus, for every still, a mask of the hull's own pixels, so the hull's
# brightness can be measured from the sheet itself (contrib/opus/reviews/readability_362/measure.py).
#
# Kept in the repo here; the PC run copies it (and readability_probe.tscn) into the checkout's godot/bench/ for the run
# only. It extends the bench script, so the colour stills are drawn exactly as the bench draws them (same world builds,
# same seeds, 8 steps after the ship is set up); after each colour still one more frame is drawn with every hull surface
# unshaded white and everything else hidden or black: that frame is the mask (the engine clock moves one frame for it, so
# a storm cell is not pixel-equal to the bench's own still, only equivalent; before and after are both made this way).
#
# godot --path godot --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080 ^
#       res://bench/readability_probe.tscn -- --out DIR [--skies world,frontier,storm] [--variants FILE.json] [--commit SHA]
# Variants (branch only): a JSON list of {"name": ..., "tune": {...}}; "tune" is laid over render/look.gd READ and RIM for
# that variant (look.gd `tune`, bench probes only). Without --variants: one variant "cur" (the commit as it is).
# Writes DIR/<variant>/<sky>/<nn>_<code>.png and <nn>_<code>_mask.png, DIR/materials.json (the hull materials as the
# battle sets them up, first variant), DIR/probe.json, and prints READ_PROBE_DONE.

const PSKIES := {"world": 2, "frontier": 0, "storm": 5}   # indexes into the bench's SKIES (darkest, brightest, storm)

var _white: StandardMaterial3D


func _run() -> void:
	headless = DisplayServer.get_name() == "headless"
	var bad: Array = []
	for key in HT.AI_HULLS:
		if not _hull_file_ok(str(HT.AI_HULLS[key])):
			bad.append(str(HT.AI_HULLS[key]))
	if not bad.is_empty() and not args.has("allow-blocks"):
		_placeholder("no built hull file for " + ", ".join(bad))
		return
	_white = StandardMaterial3D.new()
	_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_white.albedo_color = Color.WHITE
	_setup_view()
	var variants: Array = [{"name": "cur"}]
	if args.has("variants"):
		var v = JSON.parse_string(FileAccess.get_file_as_string(str(args["variants"])))
		if v is Array and not (v as Array).is_empty():
			variants = v
	var skies := String(args.get("skies", "world,frontier,storm")).split(",", false)
	var LK = load("res://render/look.gd")
	var probe := {"commit": str(args.get("commit", "")), "godot": Engine.get_version_info().get("string", ""),
		"adapter": RenderingServer.get_video_adapter_name(), "variants": variants, "skies": skies, "stills": [],
		"warnings": report["warnings"]}
	var mats := {}
	for vi in variants.size():
		var v: Dictionary = variants[vi]
		if v.has("tune"):
			LK.tune = v["tune"]
		SV.clear_static()   # the per-hull material cache, so the variant's numbers are used
		if not headless:
			LK.apply(env, _light(0), _light(1), {"quality": "max"})
			_light(0).directional_shadow_max_distance = 600.0
		for sky_name in skies:
			var sky: Array = SKIES[int(PSKIES[sky_name])]
			var terrain := {}
			if bool(sky[2]):
				for k in STORM_HEXES:
					terrain[k] = "storm"
			await _world(sky[1], terrain, [{"q": 0, "r": 0}])
			var d := out.path_join(str(v["name"])).path_join(sky_name)
			DirAccess.make_dir_recursive_absolute(d)
			var n := 0
			for key in HT.AI_HULLS:
				var code := str(HT.AI_HULLS[key])
				_clear()
				seed(2070)
				fx.rng.seed = 11
				var parts := String(key).split("|")
				var sv
				if parts[0] in ["craft", "obj"]:
					sv = _ship("A", "hegemony", "Frigate", Vector3.ZERO, 0, code)
				else:
					sv = _ship("A", parts[0], parts[1], Vector3.ZERO, 0)
				if sv == null:
					return
				if vi == 0 and sky_name == skies[0]:
					mats[code] = _materials(sv)
				_cam(Vector3.ZERO, 170.0)
				for k in 8:
					await _step()
				var img := _grab()
				if img == null:
					_warn("empty frame %s %s" % [sky_name, code])
					continue
				var base := "%02d_%s" % [n, code]
				_crop(img, FLEET_CELL, FLEET_CELL).save_png(d.path_join(base + ".png"))
				var mk = await _mask(sv)
				if mk != null:
					_crop(mk, FLEET_CELL, FLEET_CELL).save_png(d.path_join(base + "_mask.png"))
				probe["stills"].append({"variant": v["name"], "sky": sky_name, "file": "%s/%s/%s.png" % [v["name"], sky_name, base],
					"code": code, "what": key, "length": float(sv.L)})
				n += 1
			_log("probe %s %s: %d hulls" % [v["name"], sky_name, n])
		if v.has("tune"):
			LK.tune = {}
	_clear()
	var f := FileAccess.open(out.path_join("materials.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(mats, " "))
		f.close()
	f = FileAccess.open(out.path_join("probe.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(probe, " "))
		f.close()
	print("READ_PROBE_DONE")
	if fx != null and is_instance_valid(fx):
		world.remove_child(fx)
		fx.queue_free()
	FX.clear_static()
	SV.clear_static()
	await get_tree().process_frame
	get_tree().quit(0)


# the bench makes its key and fill lights first in its world (look_bench.gd _setup_view)
func _light(i: int) -> DirectionalLight3D:
	var ls: Array = []
	for c in world.get_children():
		if c is DirectionalLight3D and String(c.name) != "LookRim":
			ls.append(c)
	return ls[i] if i < ls.size() else null


# One frame with the hull surfaces unshaded white, everything else hidden, the sky black, no glow and no fog.
func _mask(sv) -> Image:
	if headless:
		return null
	var saved: Array = []
	for g in sv.find_children("*", "GeometryInstance3D", true, false):
		saved.append([g, g.visible, g.material_override])
		if g in sv.meshes:
			g.material_override = _white
		else:
			g.visible = false
	var others: Array = []
	for c in world.get_children():
		if c is Node3D and c != sv and c != cam and (c as Node3D).visible and not (c is Light3D):
			others.append(c)
			(c as Node3D).visible = false
	var e := [env.background_mode, env.background_color, env.glow_enabled, env.fog_enabled, env.volumetric_fog_enabled]
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.glow_enabled = false
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := _grab()
	for s in saved:
		(s[0] as GeometryInstance3D).visible = s[1]
		(s[0] as GeometryInstance3D).material_override = s[2]
	for c in others:
		(c as Node3D).visible = true
	env.background_mode = e[0]
	env.background_color = e[1]
	env.glow_enabled = e[2]
	env.fog_enabled = e[3]
	env.volumetric_fog_enabled = e[4]
	return img


func _materials(sv) -> Array:
	var rows: Array = []
	for m in sv.meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(i)
			var row := {"mesh": String(mi.name), "surface": i, "class": mat.get_class() if mat != null else "none"}
			var b := mat as BaseMaterial3D
			if b != null:
				row.merge({"albedo": [b.albedo_color.r, b.albedo_color.g, b.albedo_color.b, b.albedo_color.a],
					"albedo_tex": b.albedo_texture != null, "metallic": b.metallic, "roughness": b.roughness,
					"metal_tex": b.metallic_texture != null, "rough_tex": b.roughness_texture != null,
					"specular": b.metallic_specular, "emission": b.emission_enabled, "emission_energy": b.emission_energy_multiplier,
					"emission_tex": b.emission_texture != null, "rim": b.rim if b.rim_enabled else 0.0, "rim_tint": b.rim_tint,
					"transparency": b.transparency, "cull": b.cull_mode, "layers": mi.layers})
			rows.append(row)
	return rows
