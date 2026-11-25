extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1777 (Ship Exteriors V2, RULEBOOK 3.14 law 6; the global cohesion standard's exterior gate, section 6.2 item 2):
#   1. Off (the default today): the hull material, the key light, the ambient and the rim light are exactly as before.
#   2. On: the space reflections and per-faction ao_light_affect are on (graduating #1679), key.shadow_normal_bias <= 0.5,
#      the ambient is lower, the rim light's specular is tamed, and the hot accents gain glow.
#   3. On: all six faction micro-detail maps load (normal map plus grain), import with mipmaps (normal maps as normal
#      maps), tile with no seam, and every faction's hull material carries its own pair on object-space triplanar UVs.
#   4. On: a damaged hull keeps the layer (fx_hull.gd damage material), and the fitted grain size follows the hull scale.
#   godot --headless --path godot --script res://render/test/ship_look_v2_check.gd
# Prints SHIP LOOK V2 PASS or FAIL lines; exit 0 only on PASS.

const LOOK := preload("res://render/look.gd")
const HULL := preload("res://fx/fx_hull.gd")

var fails: Array = []


# Shader compile errors print, but never stop a headless run; this counts them (the V2 sky lobes once redefined the sky
# shader's own "band" uniform and broke every battle sky, flag on or off, with every headless check still green).
class _ShaderErrors extends Logger:
	var _lock := Mutex.new()
	var count := 0
	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SHADER or (code + rationale).contains("Shader compilation failed"):
			_lock.lock()
			count += 1
			_lock.unlock()
var _shader_errors := _ShaderErrors.new()


func _init() -> void:
	GUARD.arm(self, "ship_look_v2_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("SHIP LOOK V2 FAIL: " + what)


func _lights() -> Array:
	var root := Node3D.new()
	get_root().add_child(root)
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	root.add_child(key)
	root.add_child(fill)
	var env := Environment.new()
	LOOK.apply(env, key, fill, {"quality": "max"})
	return [root, env, key]


func _hull(faction: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.emission_enabled = true
	m.emission_energy_multiplier = 4.0
	m.metallic = 0.5
	return LOOK.hull(m, faction, true) as StandardMaterial3D


func _import_param(path: String, key: String) -> String:
	var f := FileAccess.open(path + ".import", FileAccess.READ)
	if f == null:
		return ""
	for line in f.get_as_text().split("\n"):
		if line.begins_with(key + "="):
			return line.substr(key.length() + 1)
	return ""


func _seam(img: Image) -> float:
	# the step across the wrap edge against the largest step between any two neighbouring columns inside the image (a
	# sparse map has big steps wherever a crack crosses, so only a step bigger than every inside one is a seam)
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var steps := PackedFloat32Array()
	steps.resize(w)
	for y in range(0, h, 2):
		for x in w:
			var a := img.get_pixel(x, y)
			var b := img.get_pixel((x + 1) % w, y)
			steps[x] += absf(a.r - b.r) + absf(a.g - b.g)
	var inner := 0.0
	for x in w - 1:
		inner = maxf(inner, steps[x])
	return steps[w - 1] / maxf(inner, 0.0001)


func _compiles(code: String) -> bool:
	var before := _shader_errors.count
	var sh := Shader.new()
	sh.code = code
	sh.get_shader_uniform_list()
	return _shader_errors.count == before


func _run() -> void:
	OS.add_logger(_shader_errors)
	# 0. every shader V2 touches compiles (the battle sky, the dead-star panorama, the hull exterior and its alpha twin)
	var SKY = load("res://world/world_sky.gd")
	check(_compiles(SKY.SKY.code), "the battle sky shader compiles")
	check(_compiles(SKY.PANORAMA_SKY.code), "the panorama sky shader compiles")
	check(_compiles(HULL.EXTERIOR), "the hull exterior shader compiles")
	check(_compiles(HULL.exterior_alpha_code()), "the see-through hull exterior shader compiles")
	# 1. off
	LOOK.v2_force = 0
	var off := _lights()
	check(is_equal_approx((off[2] as DirectionalLight3D).shadow_normal_bias, 2.0), "off: normal bias left at 2.0")
	check(is_equal_approx((off[1] as Environment).ambient_light_energy, 0.5), "off: ambient left at 0.5")
	check(is_equal_approx(float(LOOK.rim_of()["spec"]), 8.0), "off: rim spec left at 8")
	var m0 := _hull("voidsworn")
	check(not m0.detail_enabled and not m0.has_meta("look_detail"), "off: no detail layer")
	check(is_equal_approx(m0.emission_energy_multiplier, 4.0 * float(LOOK.READ["voidsworn"]["emit"])), "off: glow unchanged")
	check(LOOK.fleet_lighting_enabled() == (OS.get_environment("VS_FLEET_LIGHTING") != "0"), "off: fleet lighting follows its own option (on by default, R433)")
	(off[0] as Node).queue_free()

	# 2. on: lights
	LOOK.v2_force = 1
	check(LOOK.fleet_lighting_enabled(), "on: the 1679 space reflections and ao light are on")
	var on := _lights()
	var key := on[2] as DirectionalLight3D
	check(key.shadow_normal_bias <= 0.5, "on: key.shadow_normal_bias <= 0.5 (is %.2f)" % key.shadow_normal_bias)
	var amb := (on[1] as Environment).ambient_light_energy
	check(amb >= 0.16 - 0.001 and amb <= 0.22 + 0.001, "on: ambient in 0.16 to 0.22 (is %.3f)" % amb)
	check(float(LOOK.rim_of()["spec"]) < 8.0, "on: rim spec tamed")
	var rim := (on[0] as Node).get_node_or_null("LookRim") as DirectionalLight3D
	check(rim != null and rim.light_specular < 8.0, "on: the live LookRim takes the tamed spec")
	(on[0] as Node).queue_free()

	# 3. on: maps and every faction's layer
	for fac in LOOK.DETAIL_FACTIONS:
		var maps := LOOK.detail_maps(fac)
		check(maps.size() == 3 and maps[0] is Texture2D and maps[1] is Texture2D, fac + ": both maps load")
		if maps.size() != 3:
			continue
		check(float(maps[2]) > 0.05 and float(maps[2]) < 0.6, fac + ": grain share between 0.05 and 0.6")
		var n_path: String = LOOK.DETAIL_DIR + fac + "_n.png"
		var g_path: String = LOOK.DETAIL_DIR + fac + "_grain.png"
		check(_import_param(n_path, "compress/normal_map") == "1", fac + ": normal map imports as a normal map")
		check((maps[1] as Texture2D).get_image().get_format() == Image.FORMAT_RGTC_RG, fac + ": normal map is BC5 (RGTC_RG) in the game")
		check(_import_param(n_path, "mipmaps/generate") == "true" and _import_param(g_path, "mipmaps/generate") == "true",
			fac + ": mipmaps on (no shimmer at camera 170)")
		check(_seam((maps[0] as Texture2D).get_image()) <= 1.05 and _seam((maps[1] as Texture2D).get_image()) <= 1.05, fac + ": tiles with no seam")
		var m := _hull(fac)
		check(m.detail_enabled and m.uv2_triplanar and not m.uv2_world_triplanar, fac + ": object-space triplanar detail layer")
		check(m.detail_albedo == maps[0] and m.detail_normal == maps[1], fac + ": its own maps")
		check(m.normal_enabled and m.normal_scale > 1.0, fac + ": baked relief kept at full depth under the mix")
		check(is_equal_approx(m.ao_light_affect, float(LOOK.READ[fac]["ao_light"])), fac + ": per-faction ao_light_affect")
		var glow := 4.0 * float(LOOK.READ[fac]["emit"]) * float(LOOK.V2["emit"][fac])
		check(is_equal_approx(m.emission_energy_multiplier, glow), fac + ": V2 glow")
		# 4. a damaged hull keeps it; the fitted scale follows the hull
		var dmg := HULL.damage_material(m, Transform3D.IDENTITY, {}, 10.0)
		check(dmg.get_shader_parameter("hull_detail") == true and dmg.get_shader_parameter("hull_detail_normal") == maps[1],
			fac + ": damaged hull keeps the detail layer")
		LOOK.detail_fit(m, -2.5)
		check(m.uv2_scale.is_equal_approx(Vector3.ONE * float(LOOK.V2["tiles"]) * 2.5), fac + ": grain size follows the hull scale")
	# 5. the ship normal maps build_assets.gd compresses are true BC5 (RGTC_RG), not BC3 (engine audit, PR 1781)
	var nimg := Image.create(64, 64, true, Image.FORMAT_RGB8)
	nimg.fill(Color(0.5, 0.5, 1.0))
	nimg.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL)
	check(nimg.get_format() == Image.FORMAT_RGTC_RG, "ship normal maps compress to BC5 RGTC_RG (format %d)" % nimg.get_format())
	var ba := FileAccess.get_file_as_string("res://render/build_assets.gd")
	check(ba.contains("Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_NORMAL"), "build_assets.gd compresses normals from the normal source")
	# 6. zoom-tracked shadow reach: camera 26 and 170 inside the clamp, never the old fixed 600
	check(is_equal_approx(LOOK.shadow_reach(26.0, 40.0), 120.0) and is_equal_approx(LOOK.shadow_reach(170.0, 150.0), 332.0)
		and LOOK.shadow_reach(900.0, 150.0) >= 1050.0, "shadow reach covers camera distance plus the far board at every zoom")
	# 7. faction material channels, and a damaged hull keeps them
	var ch := _hull("chorus")
	check(ch.clearcoat_enabled and ch.backlight_enabled and not ch.subsurf_scatter_enabled, "chorus: coat and backlight, no SSS pass")
	check(HULL.damage_material(ch, Transform3D.IDENTITY, {}, 10.0).get_shader_parameter("hull_coat") > 0.0, "chorus: damaged hull keeps the coat")
	check(not _hull("hegemony").anisotropy_enabled, "hegemony: anisotropy off until it has a flow direction")
	var pbr: Dictionary = (LOOK.V2["pbr"] as Dictionary).duplicate(true)
	pbr["hegemony"] = {"aniso": 0.5}
	LOOK.tune = {"v2": {"pbr": pbr}}
	var hg := _hull("hegemony")
	check(hg.anisotropy_enabled and HULL.damage_material(hg, Transform3D.IDENTITY, {}, 10.0).get_shader_parameter("hull_aniso") > 0.0, "tuned anisotropy is kept when damaged")
	LOOK.tune = {}
	check(not _hull("ithar").refraction_enabled, "ithar: never refraction (transparent pass; Fable H12)")
	check(_hull("ithar").clearcoat_enabled and _hull("deathless").clearcoat_enabled, "ithar and deathless: clearcoat")
	# 7b. every faction's hull just before and just after its first hit (damage_material copies what _exterior sets): the
	# detail layer, coat, backlight and glow all carry over (Astra via the Board, PR 1786)
	for fac in LOOK.DETAIL_FACTIONS:
		var before := _hull(fac)
		before.emission = Color(1.0, 0.4, 0.1)
		var after := HULL.damage_material(before, Transform3D.IDENTITY, {}, 10.0)
		var p := after.get_shader_parameter
		check(p.call("hull_detail") == true and p.call("hull_detail_albedo") == before.detail_albedo
			and p.call("hull_detail_normal") == before.detail_normal and Vector3(p.call("hull_detail_scale")).is_equal_approx(before.uv2_scale),
			fac + ": first hit keeps the detail layer")
		# an unset uniform reads null and takes the shader default (coat 0, coat roughness 0.3, backlight black)
		var coat = p.call("hull_coat")
		var coat_r = p.call("hull_coat_rough")
		check(is_equal_approx(0.0 if coat == null else float(coat), before.clearcoat if before.clearcoat_enabled else 0.0)
			and (not before.clearcoat_enabled or is_equal_approx(0.3 if coat_r == null else float(coat_r), before.clearcoat_roughness)),
			fac + ": first hit keeps the coat")
		var bv = p.call("hull_back")
		var back: Color = Color(0, 0, 0, 0) if bv == null else bv
		check(back.is_equal_approx(before.backlight if before.backlight_enabled else Color(0, 0, 0, 0)), fac + ": first hit keeps the backlight")
		check(is_equal_approx(float(p.call("hull_emission_energy")), before.emission_energy_multiplier)
			and Color(p.call("hull_emission_color")).is_equal_approx(before.emission), fac + ": first hit keeps the V2 glow")
	# 8. two hulls from one glb fitted at different lengths get their own grain scale (ShipView look cache, Board audit)
	var shared := _hull("corsair")
	var f1 := LOOK.fitted(shared, 1.5) as BaseMaterial3D
	var f2 := LOOK.fitted(shared, 3.0) as BaseMaterial3D
	check(f1 != f2 and LOOK.fitted(shared, 1.5) == f1, "one copy per fitted scale, shared within a scale")
	check(f1.uv2_scale.is_equal_approx(Vector3.ONE * float(LOOK.V2["tiles"]) * 1.5) and f2.uv2_scale.is_equal_approx(Vector3.ONE * float(LOOK.V2["tiles"]) * 3.0),
		"each copy keeps its own grain scale")
	check(f1.get_meta("look_hull", "") == "corsair" and f1.has_meta("look_detail"), "copies keep the hull marks (rim light, detail)")
	load("res://render/ship_view.gd").clear_look_cache()
	check(LOOK.fitted(shared, 1.5) != f1, "the end of a battle drops the fitted copies with the look cache")
	var plain := StandardMaterial3D.new()
	check(LOOK.fitted(plain, 2.0) == plain, "a material with no detail layer is left as it is")
	var none := _hull("not_a_faction")
	check(not none.detail_enabled, "unknown faction: no layer, no error")
	LOOK.v2_force = -1
	check(LOOK.ship_look_v2_enabled() == (OS.get_environment("VS_SHIP_LOOK_V2") != "0"),
		"V2 is the default look (Ryan, Nov 23 2026, R426); only VS_SHIP_LOOK_V2=0 turns it off")
	check(_shader_errors.count == 0, "no shader compile error anywhere in the run (damage and death shaders included): %d" % _shader_errors.count)

	if fails.is_empty():
		print("SHIP LOOK V2 PASS")
		quit(0)
	else:
		print("SHIP LOOK V2 FAIL: %d" % fails.size())
		quit(1)
