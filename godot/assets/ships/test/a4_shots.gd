extends Node3D
# A4 in-game ship check (feel pass, Nov 1): every faction's ships drawn exactly as the battle draws them (ShipView.setup,
# the battle's sky, lights and G4 look at quality max, MSAA 4x), so the paint is judged in the game, not in the Blender studio.
#   godot --path godot --resolution 1920x1080 res://assets/ships/test/a4_shots.tscn -- --out <folder> [--facs hegemony,corsair]
#       [--sets diag,battle,close,bare] [--codes H4_11,V1b_r_23] [--tag before]
# Writes JPGs into <folder>:
#   <fac>_battle.jpg       the faction's line at the default battle camera (the camera rig at its home angle and distance)
#   <fac>_battle_near.jpg  the same line zoomed in the way a player zooms to look at a ship
#   <code>_q.jpg, <code>_s.jpg, <code>_b.jpg  one ship close: three-quarter from above the bow, side, three-quarter from below
#   <code>_bare.jpg        (set bare) the same three-quarter view with every texture map taken off: if it looks the same as
#                          <code>_q.jpg, the maps are not reaching the screen
# and prints one "[a4diag]" line per ship: each material's maps (class, size, format, mipmaps, path), metal, roughness.
# Lives under test/ so the export leaves it out (export_presets.cfg excludes */test/*).

const HT := preload("res://render/hull_table.gd")
const ShipView := preload("res://render/ship_view.gd")
const CamRig := preload("res://render/camera_rig.gd")

const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const FILL_DIR := Vector3(0.6, -0.2, 0.75)
const FILL_COL := Color(0.55, 0.65, 0.85)
const ORDER := ["hegemony", "voidsworn", "corsair", "chorus", "ithar", "deathless", "craft", "obj"]

var out := ""
var facs: Array = []
var sets: Array = ["diag", "battle", "close", "bare"]
var codes_only: Array = []
var tag := ""
var rig: Camera3D
var cam: Camera3D
var env: Environment


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		match a[i]:
			"--out": out = a[i + 1]; i += 1
			"--facs": facs = Array(a[i + 1].split(",")); i += 1
			"--sets": sets = Array(a[i + 1].split(",")); i += 1
			"--codes": codes_only = Array(a[i + 1].split(",")); i += 1
			"--tag": tag = a[i + 1]; i += 1
		i += 1
	if facs.is_empty():
		facs = ORDER.duplicate()
	if out == "":
		out = OS.get_user_data_dir().path_join("a4_shots")
	DirAccess.make_dir_recursive_absolute(out)
	if DisplayServer.get_name() != "headless":
		# the project starts maximised: hold an exact 1920x1080 window so every shot is one size (as main.gd --window)
		for k in 4:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1920, 1080))
			await get_tree().process_frame
	print("[a4shots] window ", DisplayServer.window_get_size(), " viewport ", get_viewport().get_visible_rect().size)
	_world()
	print("[a4shots] out ", out, " facs ", facs, " sets ", sets)
	await _run()
	print("[a4shots] done")
	ShipView.clear_static()
	get_tree().quit(0)


# the battle's world (battle.gd _build_world and _apply_quality "max", then G4's look.apply), without the board
func _world() -> void:
	env = Environment.new()
	var man := ShipView.manifest()
	var sky_res := str(man.get("sky", ""))
	if sky_res != "" and ResourceLoader.exists(sky_res):
		var sh := Shader.new()
		sh.code = "shader_type sky;\nuniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\nvoid sky() {\n\tvec3 c = texture(pano, SKY_COORDS).rgb;\n\tCOLOR = min(c * 0.8, vec3(0.6));\n}\n"
		var pano := ShaderMaterial.new()
		pano.shader = sh
		pano.set_shader_parameter("pano", load(sky_res))
		var sky := Sky.new()
		sky.sky_material = pano
		sky.radiance_size = Sky.RADIANCE_SIZE_256
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = KEY_COL
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key.directional_shadow_max_distance = 600.0
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = FILL_COL
	fill.light_energy = 0.5
	add_child(fill)
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_4X
	RenderingServer.directional_shadow_atlas_set_size(4096, true)
	if ResourceLoader.exists("res://render/look.gd"):
		load("res://render/look.gd").apply(env, key, fill, {"quality": "max"})
		key.directional_shadow_max_distance = 600.0
	rig = CamRig.new()
	rig.input_enabled = false
	add_child(rig)
	cam = Camera3D.new()
	cam.fov = 30.0
	cam.near = 0.2
	cam.far = 5000.0
	add_child(cam)


func _ships_of(fac: String) -> Array:
	var r: Array = []
	for k in HT.AI_HULLS:
		var p: PackedStringArray = k.split("|")
		if p[0] == fac:
			var code: String = HT.AI_HULLS[k]
			if codes_only.is_empty() or codes_only.has(code):
				r.append([code, p[1]])
	return r


func _len_of(fac: String, cls: String) -> float:
	if fac == "obj":
		return 46.0
	if fac == "craft":
		return HT.CLS_LEN["Squadron"] * HT.SHIP_K * 4.0
	return HT.CLS_LEN.get(cls, 10.0) * HT.SHIP_K


func _spawn(code: String, fac: String, cls: String, pos: Vector3, facing := 0) -> Node3D:
	var f2 := fac if HT.FAC3D.has(fac) else "hegemony"
	var L := _len_of(fac, cls)
	var sv = ShipView.new()
	add_child(sv)
	sv.setup({"id": code, "fac": f2, "cls": cls, "facing": facing, "code": code, "L": L}, pos, true)
	sv.set_process(false)
	if "fx_engines" in sv:
		sv.fx_engines = true
	for e in sv.engines:
		(e as Node3D).visible = false
	return sv


func _run() -> void:
	for f in facs:
		var ships := _ships_of(f)
		if ships.is_empty():
			continue
		if sets.has("diag"):
			for e in ships:
				var sv := _spawn(e[0], f, e[1], Vector3.ZERO)
				_diag(sv, e[0])
				sv.free()
		if sets.has("battle") and f != "obj" and f != "craft":
			await _battle_line(f, ships)
		if sets.has("close") or sets.has("bare"):
			for e in ships:
				var L := _len_of(f, e[1])
				var sv := _spawn(e[0], f, e[1], Vector3.ZERO)
				if sets.has("close"):
					await _close(e[0], L, "q", 0.45, -0.62)
					await _close(e[0], L, "s", 0.12, -1.5708)
					await _close(e[0], L, "b", -0.40, -2.2)
				if sets.has("bare"):
					_strip(sv)
					await _close(e[0], L, "bare", 0.45, -0.62)
				sv.free()
				await get_tree().process_frame


# the faction's ships in a loose battle group, as on the board (bows to screen right), seen from the battle camera's home
# angle and distance, then zoomed in
func _battle_line(fac: String, ships: Array) -> void:
	var nodes: Array = []
	var z := -36.0
	var x := -60.0
	for k in ships.size():
		var e: Array = ships[k]
		var L := _len_of(fac, e[1])
		nodes.append(_spawn(e[0], fac, e[1], Vector3(x + L * 0.5, 0.0, z + (k % 2) * 30.0), 0))
		x += L + 8.0
	rig.current = true
	rig.a = -PI / 2.0
	rig.b = 0.98
	rig.r = 170.0
	rig.t = Vector3((-60.0 + x - 8.0) * 0.5, 0.0, -21.0)
	rig.snap()
	await _settle()
	await _snap("%s_battle" % fac)
	rig.r = 70.0
	rig.b = 1.05
	rig.snap()
	await _settle()
	await _snap("%s_battle_near" % fac)
	for n in nodes:
		(n as Node).free()
	cam.current = true
	await get_tree().process_frame


# one ship alone, framed to fill most of the screen: el = camera elevation (radians, + above), az = azimuth around the ship
# (0 = looking from the bow, -PI/2 = from port)
func _close(code: String, L: float, view: String, el: float, az: float) -> void:
	cam.current = true
	var d := L * 0.62 / tan(deg_to_rad(cam.fov * 0.5)) * 0.62
	var dir := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az))
	cam.look_at_from_position(dir * d, Vector3.ZERO, Vector3.UP)
	await _settle()
	await _snap("%s_%s" % [code, view])


func _settle() -> void:
	for k in 10:
		await get_tree().process_frame


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := out.path_join(("%s_%s.jpg" % [tag, name]) if tag != "" else ("%s.jpg" % name))
	img.save_jpg(p, 0.9)
	print("[a4shots] ", p)


func _meshes(n: Node, acc: Array) -> Array:
	for c in n.get_children():
		if c is MeshInstance3D and not str(c.name).begins_with("fx_"):
			acc.append(c)
		_meshes(c, acc)
	return acc


func _tex_info(t) -> String:
	if t == null:
		return "-"
	var tx := t as Texture2D
	var s := "%s %dx%d" % [tx.get_class(), tx.get_width(), tx.get_height()]
	var img: Image = tx.get_image()
	if img != null:
		s += " fmt=%d mips=%d" % [img.get_format(), img.get_mipmap_count()]
	if tx.resource_path != "":
		s += " " + tx.resource_path.get_file()
	return s


func _diag(sv: Node3D, code: String) -> void:
	var ms := _meshes(sv, [])
	var shown := {}
	var verts := 0
	for m in ms:
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.visible:
			continue
		for s in mi.mesh.get_surface_count():
			verts += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if mi == ms[0] else 0
			var mat := mi.get_active_material(s) as BaseMaterial3D
			if mat == null or shown.has(mat.resource_name + str(mat.get_instance_id())):
				continue
			shown[mat.resource_name + str(mat.get_instance_id())] = true
			var fm: int = mi.mesh.surface_get_format(s)
			print("[a4diag] %s mesh=%s surf=%d mat=%s tangents=%s albedo_col=%s metal=%.2f rough=%.2f normal_on=%s ao_on=%s emis_on=%s emis_x=%.1f rim=%s" % [
				code, mi.name, s, mat.resource_name, str((fm & Mesh.ARRAY_FORMAT_TANGENT) != 0), mat.albedo_color.to_html(false),
				mat.metallic, mat.roughness, str(mat.normal_enabled), str(mat.ao_enabled), str(mat.emission_enabled),
				mat.emission_energy_multiplier, str(mat.rim_enabled)])
			print("[a4diag] %s   albedo  %s" % [code, _tex_info(mat.albedo_texture)])
			print("[a4diag] %s   normal  %s" % [code, _tex_info(mat.normal_texture)])
			print("[a4diag] %s   metal   %s ch=%d" % [code, _tex_info(mat.metallic_texture), mat.metallic_texture_channel])
			print("[a4diag] %s   rough   %s ch=%d" % [code, _tex_info(mat.roughness_texture), mat.roughness_texture_channel])
			print("[a4diag] %s   ao      %s ch=%d" % [code, _tex_info(mat.ao_texture), mat.ao_texture_channel])
			print("[a4diag] %s   emis    %s" % [code, _tex_info(mat.emission_texture)])
	print("[a4diag] %s meshes=%d hull_verts=%d" % [code, ms.size(), verts])


# every texture map off (the shapes and flat material values only), for the bare comparison shot
func _strip(sv: Node3D) -> void:
	for m in _meshes(sv, []):
		var mi := m as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var src := mi.get_active_material(s) as BaseMaterial3D
			if src == null:
				continue
			var b := src.duplicate() as BaseMaterial3D
			b.albedo_texture = null
			b.normal_enabled = false
			b.metallic_texture = null
			b.roughness_texture = null
			b.ao_enabled = false
			b.emission_enabled = false
			mi.set_surface_override_material(s, b)
