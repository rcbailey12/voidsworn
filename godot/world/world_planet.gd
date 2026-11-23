extends RefCounted
# F4 planets: the system's planet (gas giant, ice giant, terran, volcanic, barren or ice world, from the sector's biome),
# its rings and its moons, far beyond the board.
#
# Each surface is baked once on the GPU (world_bake.gd) into two equirectangular pictures:
#   A: albedo (rgb, sRGB) and ocean (a)        B: clouds (r), city lights (g), relief (b), lava glow (a)
# and drawn by a sphere shader that lights it from the battle's key light: a soft terminator, cloud shadows, the sun's
# glint on oceans, city lights and lava on the night side, the atmosphere's blue or amber haze on the lit limb, and the
# rings' shadow. Rings are lit, see-through and shadowed by the planet. Moons share one baked cratered surface, each
# tinted and turned its own way (never two that look alike).

const NOISE := preload("res://world/world_shaders.gd")
const R01_DIR := "res://world/rocks/r01/"
const R01_SIZE := Vector2i(8192, 4096)

# Issue 1765 (R419, Planets V2): the board planet. Rocky and barren board worlds draw the authored 8K R01 maps (real
# relief, remixed per battle: turned, tilted and re-tinted so no two battles show the same face, RULEBOOK 10.3); terran,
# ice and volcanic board worlds bake their own 4K surface with this file's recipes plus a 16-bit relief map, and draw it
# with the same high-relief lighting. Nothing on the board uses the campaign map's icon shader any more.
static func rocky_available() -> bool:
	return OS.get_environment("VS_PLANET_REMIX") != "0" and FileAccess.file_exists(R01_DIR + "colour.json") and FileAccess.file_exists(R01_DIR + "relief.json")

# The board planet's five looks, by board look kind (board.gd PLANET_LOOKS[i]): 0 rocky, 1 terran, 3 ice, 4 volcanic,
# 5 barren. "bake" is this file's recipe kind for the baked looks (-1: drawn from R01). Palettes stay in the grounded range
# (no indigo to purple, RULEBOOK 10.9) and inside R420's band 2 (lit disc mean 0.03 to 0.25 linear, RULEBOOK 3.14; the ice
# world is held down from snow white to stay inside it). "bump" scales the relief shading; "glint" the sun's sheen on water or ice.
const BOARD_LOOKS := {
	0: {"bake": -1, "flat": Vector3(0.42, 0.33, 0.25), "clouds": true, "atmo": Vector3(0.72, 0.39, 0.19), "atmo_k": 0.32, "tints": [Vector3(1.0, 0.97, 0.93), Vector3(1.06, 0.95, 0.84), Vector3(0.96, 0.96, 0.98)], "gain": 1.5, "stand_gain": 0.3, "stand_clouds": 0.25},
	1: {"bake": 2, "flat": Vector3(0.12, 0.2, 0.22), "a": Vector3(0.3, 0.36, 0.2), "b": Vector3(0.03, 0.09, 0.18), "c": Vector3(0.66, 0.58, 0.44), "atmo": Vector3(0.38, 0.62, 1.0), "atmo_k": 0.55, "bump": 0.03, "glint": 1.0, "stand_gain": 0.65},
	3: {"bake": 5, "flat": Vector3(0.52, 0.54, 0.56), "a": Vector3(0.6, 0.63, 0.66), "b": Vector3(0.46, 0.27, 0.16), "c": Vector3(0.42, 0.6, 0.8), "atmo": Vector3(0.6, 0.8, 1.0), "atmo_k": 0.22, "bump": 0.034, "glint": 0.5, "stand_gain": 0.58, "stand_clouds": 0.2, "stand_b": Vector3(0.4, 0.47, 0.54)},
	4: {"bake": 3, "flat": Vector3(0.3, 0.26, 0.23), "a": Vector3(0.56, 0.47, 0.4), "b": Vector3(0.15, 0.135, 0.125), "c": Vector3(0.8, 0.66, 0.42), "atmo": Vector3(1.0, 0.45, 0.2), "atmo_k": 0.3, "bump": 0.05, "glint": 0.0, "cloud_col": Vector3(0.5, 0.43, 0.37), "stand_gain": 0.3, "stand_clouds": 0.25},
	5: {"bake": -1, "flat": Vector3(0.36, 0.35, 0.34), "clouds": false, "desat": 0.65, "atmo": Vector3(0.6, 0.62, 0.7), "atmo_k": 0.0, "tints": [Vector3(0.9, 0.9, 0.92), Vector3(0.98, 0.9, 0.82), Vector3(0.82, 0.84, 0.88)], "gain": 1.35, "stand_gain": 0.33},
}
const BOARD_SIZE := Vector2i(4096, 2048)
# R01 longitudes (u) whose equator band is clean of remix swirls, judged on the colour map (issue 1765)
const R01_CLEAN := [[0.05, 0.28]]


# Issue 1765 (Fable, PR 1776 M4): one compiled shader per source text for the whole run, not a new one per battle.
static var _shaders := {}

static func clear_static() -> void:
	_shaders.clear()

static func shader(code: String) -> Shader:
	var sh: Shader = _shaders.get(code)
	if sh == null:
		sh = Shader.new()
		sh.code = code
		_shaders[code] = sh
	return sh


# Dresses the board's planet sphere and its air shell for one battle. Waits for the maps (the battle's loading cover is
# still up, board.gd wait_planet); until then, and wherever maps cannot be made or miss the cover, the sphere draws a
# procedural stand-in in the look's own palette (noise land, seas on a terran world, weather), never a plain ball.
static func install_board(planet: MeshInstance3D, air: MeshInstance3D, look_kind: int, seed_v: int, sun_position: Vector3) -> void:
	var L: Dictionary = BOARD_LOOKS.get(look_kind, BOARD_LOOKS[0])
	var r := RandomNumberGenerator.new()
	r.seed = hash(["board_planet", seed_v, look_kind])
	var centre := planet.global_position if planet.is_inside_tree() else planet.position
	var light_dir := (sun_position - centre).normalized()
	_board_air(air, L, light_dir)
	# the lit stand-in, until the maps arrive (or for good, where they cannot be made)
	var stand_in := ShaderMaterial.new()
	stand_in.shader = shader(BOARD_SURFACE)
	var flat: Vector3 = L["flat"]
	stand_in.set_shader_parameter("flat_col", flat)
	# its gain holds the stand-in near the finished look's band 2 brightness (planet_v2_shots.gd --only standin)
	var g := float(L.get("stand_gain", 1.0))
	stand_in.set_shader_parameter("col_a", L.get("a", flat * 1.3) * g)
	# stand_b: a stand-in's own low colour where the bake's (ice's rust lineae) would smear into rusty mud (Wave 0)
	stand_in.set_shader_parameter("col_b", L.get("stand_b", L.get("b", flat * 0.5)) * g)
	stand_in.set_shader_parameter("col_c", L.get("c", flat * 1.6) * g)
	stand_in.set_shader_parameter("stand_sea", 1.0 if int(L["bake"]) == 2 else 0.0)
	stand_in.set_shader_parameter("stand_clouds", 0.0 if not bool(L.get("clouds", true)) or float(L["atmo_k"]) <= 0.0 else float(L.get("stand_clouds", 0.4)))
	stand_in.set_shader_parameter("stand_seed", float(posmod(seed_v * 13 + look_kind * 5, 97)) * 1.37)
	stand_in.set_shader_parameter("sun", light_dir)
	stand_in.set_shader_parameter("atmo", L["atmo"])
	stand_in.set_shader_parameter("atmo_k", float(L["atmo_k"]))
	stand_in.set_shader_parameter("bump", float(L.get("bump", 0.03)))
	stand_in.set_shader_parameter("glint", float(L.get("glint", 0.0)))
	stand_in.set_shader_parameter("turn", r.randf() * TAU)
	stand_in.set_shader_parameter("cloud_col", L.get("cloud_col", Vector3.ONE))
	planet.material_override = stand_in
	if not planet.is_inside_tree(): return
	# The board builds inside the battle's _ready, while the root is still adding children: the shared bake service
	# could not join the tree then (its add_child is refused) and every map request failed. Start on the next frame.
	await planet.get_tree().process_frame
	if not is_instance_valid(planet) or not planet.is_inside_tree(): return
	if int(L["bake"]) < 0:
		var tints: Array = L["tints"]
		# the battle camera looks down on the planet's cap: tip the data's equator up toward it, so the cap never shows
		# the smeared poles, and centre it on R01's cleanest longitudes (the remix left swirled, stretched patches
		# over most other longitudes); turned and leaned a little differently every battle. With this tilt
		# the cap's centre sits at u = 1 - turn / TAU.
		var windows: Array = R01_CLEAN[r.randi() % R01_CLEAN.size()]
		var u := r.randf_range(float(windows[0]), float(windows[1]))
		var opts := {"turn": TAU * (1.0 - u), "tilt": PI * 0.5 + r.randf_range(-0.25, 0.25), "tint": tints[r.randi() % tints.size()],
			"clouds": bool(L["clouds"]), "atmo": L["atmo"], "atmo_k": float(L["atmo_k"]), "seed": r.randf() * 50.0,
			"desat": float(L.get("desat", 0.0)), "gain": float(L.get("gain", 1.0)), "urgent": true}
		# Fable (PR 1776 H11) asked for more clean windows. Tried in cloud renders (issue 1765): turning the strip end
		# over end, or mirroring it, carries the swirled longitudes beside the window onto the close-up limb, so neither
		# ships. More ground needs a cleaner remix of the data itself (a follow-up job).
		await install_rocky(planet, air, sun_position, opts)
		return
	planet.set_meta("planet_code", "BAKE%d" % int(L["bake"]))
	var baker = preload("res://world/world_bake.gd").service(planet.get_tree())
	var params := {"seed": float(posmod(seed_v * 31 + look_kind * 7, 997)) * 0.71, "kind": int(L["bake"]), "ca": L["a"], "cb": L["b"], "cc": L["c"], "pass_id": 0}
	var key := "board_planet|%d|%d" % [look_kind, posmod(seed_v, 997)]
	var size := BOARD_SIZE
	if OS.has_environment("VS_WORLD_PREVIEW"): size = Vector2i(1024, 512)
	var code := bake_code()
	# urgent: ahead of the far backdrop bakes, so a cold cache still makes the loading cover (PC proof, PR 1776)
	# all three are queued before any is awaited, so no backdrop runs between them (Artoo, PR 1776)
	var ka: String = baker.request_bake(key + "|a", code, params, size, 32, false, true)
	params["pass_id"] = 1
	var kb: String = baker.request_bake(key + "|b", code, params, size, 32, false, true)
	params["pass_id"] = 2
	var kh: String = baker.request_bake(key + "|h", code, params, size, 32, true, true)
	var a: Image = await baker.result(ka)
	var b: Image = await baker.result(kb)
	var h: Image = await baker.result(kh)   # one 32-bit float height channel
	if not is_instance_valid(planet) or a == null or b == null or h == null: return
	if planet.get_meta("planet_frozen", false): return   # the loading cover already lifted (board.gd wait_planet)
	stand_in.set_shader_parameter("tex_a", baker.texture(a))
	stand_in.set_shader_parameter("tex_b", baker.texture(b))
	stand_in.set_shader_parameter("tex_h", baker.texture(h))
	stand_in.set_shader_parameter("map_scale", float(size.x) / TAU)
	stand_in.set_shader_parameter("has_tex", 1.0)


static func _board_air(air: MeshInstance3D, L: Dictionary, light_dir: Vector3) -> void:
	if not is_instance_valid(air): return
	if float(L["atmo_k"]) <= 0.0:
		air.visible = false
		return
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader = shader(ATMO)
	atmosphere.set_shader_parameter("atmo", L["atmo"])
	atmosphere.set_shader_parameter("sun", light_dir)
	atmosphere.set_shader_parameter("shell", 1.03)
	atmosphere.set_shader_parameter("k", float(L["atmo_k"]))
	air.material_override = atmosphere


# opts (issue 1765, all optional): turn and tilt (radians, the remix: which face of the data the battle sees), tint (a
# mineral cast over the whole world), seed (where the province tints fall), clouds (false for an airless world), atmo and
# atmo_k (the air shell; atmo_k 0 hides it).
static func install_rocky(planet: MeshInstance3D, air: MeshInstance3D, sun_position: Vector3, opts := {}) -> void:
	if not rocky_available(): return
	var started := Time.get_ticks_msec()
	var baker = preload("res://world/world_bake.gd").service(planet.get_tree())
	var urgent := bool(opts.get("urgent", false))
	var kc: String = baker.request_authored(R01_DIR + "colour.json", R01_SIZE, false, urgent)
	var kd: String = baker.request_authored(R01_DIR + "relief.json", R01_SIZE, true, urgent)
	var colour: Image = await baker.result(kc)
	var data: Image = await baker.result(kd)
	if not is_instance_valid(planet) or colour == null or data == null: return
	if planet.get_meta("planet_frozen", false): return   # the loading cover already lifted (board.gd wait_planet)
	var light_dir := (sun_position - planet.global_position).normalized()
	var clouds := bool(opts.get("clouds", true))
	var ground := ShaderMaterial.new()
	ground.shader = shader(ROCKY_SURFACE)
	ground.set_shader_parameter("colour_map", baker.texture(colour))
	ground.set_shader_parameter("surface_data", baker.texture(data))
	ground.set_shader_parameter("sun", light_dir)
	_remix(ground, opts)
	if not clouds: ground.set_shader_parameter("shadow_strength", 0.0)
	planet.material_override = ground
	planet.set_meta("planet_code", "R01")
	var atmo_k := float(opts.get("atmo_k", 0.32))
	if is_instance_valid(air):
		if atmo_k <= 0.0:
			air.visible = false
		else:
			var atmosphere := ShaderMaterial.new()
			atmosphere.shader = shader(ATMO)
			atmosphere.set_shader_parameter("atmo", opts.get("atmo", Vector3(0.72, 0.39, 0.19)))
			atmosphere.set_shader_parameter("sun", light_dir)
			atmosphere.set_shader_parameter("shell", 1.03)
			atmosphere.set_shader_parameter("k", atmo_k)
			air.material_override = atmosphere
	if not clouds:
		print("[R01] material install including map readiness: %d ms; two shared 8K maps, no clouds" % (Time.get_ticks_msec() - started))
		return
	var cloud := MeshInstance3D.new()
	cloud.name = "R01Clouds"
	var cloud_mesh := (planet.mesh as SphereMesh).duplicate() as SphereMesh
	cloud_mesh.radius *= 1.012
	cloud_mesh.height *= 1.012
	cloud.mesh = cloud_mesh
	var cloud_material := ShaderMaterial.new()
	cloud_material.shader = shader(ROCKY_CLOUDS)
	cloud_material.set_shader_parameter("surface_data", baker.texture(data))
	cloud_material.set_shader_parameter("sun", light_dir)
	_remix(cloud_material, opts)
	cloud.material_override = cloud_material
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	planet.add_child(cloud)
	print("[R01] material install including map readiness: %d ms; two shared 8K maps" % (Time.get_ticks_msec() - started))


static func _remix(m: ShaderMaterial, opts: Dictionary) -> void:
	m.set_shader_parameter("remix_turn", float(opts.get("turn", 0.0)))
	m.set_shader_parameter("remix_tilt", float(opts.get("tilt", 0.0)))
	m.set_shader_parameter("remix_tint", opts.get("tint", Vector3.ONE))
	m.set_shader_parameter("remix_seed", float(opts.get("seed", 0.0)))
	m.set_shader_parameter("remix_desat", float(opts.get("desat", 0.0)))
	m.set_shader_parameter("remix_gain", float(opts.get("gain", 1.0)))


# Shared by the R01 and the baked board surfaces: the remix turn, explicit mip levels from the direction's own footprint
# (UV derivatives jump at the longitude wrap and at the poles; this never does), and the 16-bit height.
const ROCKY_FUNCTIONS := """
uniform float remix_turn = 0.0;
uniform float remix_tilt = 0.0;
uniform vec3 remix_tint = vec3(1.0);
uniform float remix_seed = 0.0;
uniform float remix_desat = 0.0;   // an airless barren world drains the data's iron red toward grey rock
uniform float remix_gain = 1.0;    // the look's lift into band 2 (RULEBOOK 3.14) on every face and tint
vec2 r01_uv(vec3 d) {
	return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
}
vec3 r01_spin(vec3 d, float a) {
	return vec3(cos(a)*d.x + sin(a)*d.z, d.y, -sin(a)*d.x + cos(a)*d.z);
}
// the battle's face of the data: tipped about X, then turned about the pole
vec3 r01_remix(vec3 d) {
	float c = cos(remix_tilt);
	float s = sin(remix_tilt);
	return r01_spin(vec3(d.x, c*d.y - s*d.z, s*d.y + c*d.z), remix_turn);
}
vec4 r01_sample(sampler2D map, vec3 d, float lod) {
	vec2 uv = r01_uv(d);
	// Longitude wraps. Latitude must never blend the opposite hemisphere.
	float pole_pad = exp2(lod) / 8192.0;
	uv.y = clamp(uv.y, pole_pad, 1.0-pole_pad);
	return textureLod(map, uv, lod);
}
float r01_height(vec3 d, sampler2D data_map, float lod) {
	vec2 h = r01_sample(data_map, d, lod).rg;
	return dot(h, vec2(65280.0, 255.0)) / 65535.0;
}
""" + NOISE.NOISE + """
// Issue 1765: the R01 cloud field broken into fine wisps. The authored coverage says where weather is; flow-warped noise,
// stretched along the latitude, carves it into thin cyclonic streaks with clear gaps, fading out where the planet is too
// small on screen for the detail to hold still.
float r01_cloud(sampler2D data_map, vec3 s, float lod) {
	float base = r01_sample(data_map, s, lod).a;
	vec3 q = s * 3.1 + remix_seed;
	vec3 w = vec3(wvn3(q), wvn3(q + 5.2), wvn3(q + 9.1)) - 0.5;
	float ang = (w.x + w.y) * 2.4;
	vec3 sw = r01_spin(s, ang * 0.35);
	vec3 p = vec3(sw.x * 11.0, sw.y * 34.0, sw.z * 11.0) + w * 3.0 + remix_seed;
	float f = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) { f += a * wvn3(p); p = p * 2.07 + 1.3; a *= 0.5; }
	float detail = 1.0 - smoothstep(2.5, 6.0, lod);
	float c = mix(base, smoothstep(0.3, 0.72, base + (f - 0.47) * 1.15), detail);
	return c * smoothstep(0.03, 0.22, base);
}
"""

const ROCKY_SURFACE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D colour_map : source_color, filter_linear_mipmap, repeat_enable;
// Linear data: RG = 16-bit height, B = roughness, A = cloud coverage.
uniform sampler2D surface_data : filter_linear_mipmap, repeat_enable;
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform float cloud_rate = 0.009;
uniform float shadow_strength = 0.64;
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;
varying vec3 local_light;
""" + ROCKY_FUNCTIONS + """
void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
	local_light = normalize((inverse(MODEL_MATRIX) * vec4(sun, 0.0)).xyz);
}
void fragment() {
	vec3 d = r01_remix(normalize(local_direction));
	// Angular footprint stays finite at poles and the longitude seam. UV
	// derivatives there chose coarse levels in radial bands across the terrain.
	float lod = clamp(log2(max(length(dFdx(d)),length(dFdy(d)))*1303.7973),0.0,11.0);
	vec4 data = r01_sample(surface_data, d, lod);
	vec3 n = normalize(world_point-world_centre);
	vec3 v = normalize(CAMERA_POSITION_WORLD-world_point);
	vec3 l = normalize(sun);
	// Use surface derivatives for relief. This remains stable at the poles and
	// after a board transform, unlike a fixed world-X normal offset.
	float h = r01_height(d, surface_data, lod);
	vec3 dpdx = dFdx(world_point);
	vec3 dpdy = dFdy(world_point);
	vec3 r1 = cross(dpdy,n);
	vec3 r2 = cross(n,dpdx);
	float det = dot(dpdx,r1);
	float radius = length(world_point-world_centre);
	vec3 grad = sign(det)*(dFdx(h)*r1+dFdy(h)*r2);
	vec3 bv = abs(det)*n-grad*radius*0.028;
	vec3 bumped = dot(bv, bv) > 1e-20 ? normalize(bv) : n;   // grazing limb: no NaN into the glow (audit, PR 1776)
	float lambert = max(dot(bumped,l),0.0);
	float day = smoothstep(-0.06,0.18,dot(n,l));
	// The cloud sphere samples this same field, at this same angular rate.
	// A ray from the ground toward the sun reaches the higher cloud layer
	// ahead of the surface sample, separating shadows from the cloud itself.
	vec3 toward_light = r01_remix(normalize(normalize(local_direction) + normalize(local_light)*0.012));
	float shadow = shadow_strength > 0.0 ? r01_cloud(surface_data,r01_spin(toward_light,TIME*cloud_rate),lod) : 0.0;
	vec3 albedo = r01_sample(colour_map,d,lod).rgb;
	albedo = mix(albedo, vec3(dot(albedo, vec3(0.3, 0.55, 0.15))) * 1.5, remix_desat);
	// mineral provinces: broad patches of the battle's tint, so a turned face also reads as a new world
	float prov = smoothstep(0.35, 0.75, wvn3(d * 2.3 + remix_seed));
	albedo *= mix(vec3(1.0), remix_tint, 0.55 + 0.45 * prov) * remix_gain;
	vec3 colour = albedo*(0.022 + lambert*0.88*day)*(1.0-shadow*shadow_strength);
	float spec_power = mix(90.0,7.0,data.b);
	float sheen = pow(max(dot(bumped,normalize(l+v)),0.0),spec_power)*(1.0-data.b)*0.055*day;
	colour += vec3(1.0,0.87,0.72)*sheen;
	float rim = pow(1.0-max(dot(n,v),0.0),4.0)*day;
	colour += vec3(0.32,0.13,0.045)*rim*0.16*step(0.001, shadow_strength);
	ALBEDO = colour;
}
"""

const ROCKY_CLOUDS := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D surface_data : filter_linear_mipmap, repeat_enable;
uniform vec3 sun = vec3(0.45,0.7,0.55);
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;
""" + ROCKY_FUNCTIONS + """
void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
}
void fragment() {
	vec3 n = normalize(world_point-world_centre);
	vec3 d = r01_remix(normalize(local_direction));
	float lod = clamp(log2(max(length(dFdx(d)),length(dFdy(d)))*1303.7973),0.0,11.0);
	float coverage = r01_cloud(surface_data,r01_spin(d,TIME*0.009),lod);
	float day = smoothstep(-0.12,0.3,dot(n,normalize(sun)));
	// thick cores whiter, thin wisps take the dust colour
	vec3 tone = mix(vec3(0.5,0.43,0.33), vec3(0.66,0.6,0.5), smoothstep(0.4, 0.9, coverage));
	ALBEDO = tone*(0.045+day*0.72);
	ALPHA = coverage*0.78;
}
"""

# Issue 1765: the baked board planet (terran, ice, volcanic). The surface comes from this file's recipes at 4K, with a
# 16-bit height map for the relief; light, mips and the longitude wrap work as the R01 surface does. Clouds drift over
# the ground and cast shadows toward the night side; water and ice catch the sun; cities and lava glow on the night side.
const BOARD_SURFACE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D tex_a : source_color, filter_linear_mipmap, repeat_enable;   // albedo, ocean or ice sheen (a)
uniform sampler2D tex_b : filter_linear_mipmap, repeat_enable;                 // clouds, city lights, relief, lava
uniform sampler2D tex_h : filter_linear_mipmap, repeat_enable;                 // relief, one 32-bit float channel
uniform float has_tex = 0.0;
uniform vec3 flat_col = vec3(0.3);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float atmo_k = 0.5;
uniform float bump = 0.03;
uniform float glint = 1.0;
uniform float map_scale = 651.8986;   // map width / TAU
uniform float cloud_rate = 0.006;
uniform float turn = 0.0;
uniform vec3 cloud_col = vec3(1.0);   // ash on a volcanic world, white weather elsewhere
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
// the procedural stand-in (cold cache, a bake that missed the loading cover, no bake possible): the look's own palette
uniform vec3 col_a = vec3(0.4);
uniform vec3 col_b = vec3(0.15);
uniform vec3 col_c = vec3(0.6);
uniform float stand_sea = 0.0;
uniform float stand_clouds = 0.0;
uniform float stand_seed = 0.0;
varying vec3 local_direction;
varying vec3 world_point;
varying vec3 world_centre;
varying vec3 local_light;
""" + NOISE.NOISE + """
vec2 bp_uv(vec3 d) { return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359); }
vec3 bp_spin(vec3 d, float a) { return vec3(cos(a)*d.x + sin(a)*d.z, d.y, -sin(a)*d.x + cos(a)*d.z); }
vec4 bp_sample(sampler2D map, vec3 d, float lod) {
	vec2 uv = bp_uv(d);
	float pole_pad = exp2(lod) / (map_scale * 6.28318530718);
	uv.y = clamp(uv.y, pole_pad, 1.0 - pole_pad);
	return textureLod(map, uv, lod);
}
void vertex() {
	local_direction = normalize(VERTEX);
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_centre = MODEL_MATRIX[3].xyz;
	local_light = normalize((inverse(MODEL_MATRIX) * vec4(sun, 0.0)).xyz);
}
void fragment() {
	vec3 d = bp_spin(normalize(local_direction), turn);
	float lod = clamp(log2(max(length(dFdx(d)), length(dFdy(d))) * map_scale), 0.0, 10.0);
	vec3 n = normalize(world_point - world_centre);
	vec3 v = normalize(CAMERA_POSITION_WORLD - world_point);
	vec3 l = normalize(sun);
	vec3 alb = flat_col;
	float ocean = 0.0;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float h = 0.5;
	float cloud = 0.0;
	float shadow = 0.0;
	if (has_tex > 0.5) {
		vec4 a = bp_sample(tex_a, d, lod);
		alb = a.rgb;
		ocean = a.a;
		b = bp_sample(tex_b, d, lod);
		h = bp_sample(tex_h, d, lod).r;
		cloud = bp_sample(tex_b, bp_spin(d, TIME * cloud_rate), lod).r;
		vec3 toward_light = bp_spin(normalize(normalize(local_direction) + normalize(local_light) * 0.012), turn);
		shadow = bp_sample(tex_b, bp_spin(toward_light, TIME * cloud_rate), lod).r;
	} else {
		// warped noise continents, a second field for highlands or ice, detail fading where the sphere is small on screen
		vec3 p = d * 2.2 + stand_seed;
		vec3 w = vec3(wfbm3(p), wfbm3(p + 4.7), wfbm3(p + 9.3)) - 0.5;
		float fine = 1.0 - smoothstep(1.5, 5.0, lod);
		float t = wfbm3(p * 1.6 + w * 1.8) + (wfbm3(d * 26.0 + stand_seed) - 0.5) * 0.25 * fine;
		float t2 = wfbm3(d * 5.3 + w * 1.2 + stand_seed + 17.0);
		float land = smoothstep(0.44, 0.52, t);
		alb = mix(col_b, col_a, mix(smoothstep(0.3, 0.7, t), land, stand_sea));
		alb = mix(alb, col_c, smoothstep(0.55, 0.72, t2) * (stand_sea > 0.5 ? land : 1.0) * 0.8);
		ocean = stand_sea * (1.0 - land);
		h = mix(t, max(t, 0.48), stand_sea);
		vec3 q = bp_spin(d, TIME * cloud_rate);
		float cf = wfbm3(vec3(q.x * 4.0, q.y * 11.0, q.z * 4.0) + w * 2.5 + stand_seed + 31.0);
		cloud = smoothstep(0.52, 0.72, cf) * stand_clouds;
	}
	// relief from the surface derivatives (stable at the poles and across the wrap); seas stay flat
	vec3 dpdx = dFdx(world_point);
	vec3 dpdy = dFdy(world_point);
	vec3 r1 = cross(dpdy, n);
	vec3 r2 = cross(n, dpdx);
	float det = dot(dpdx, r1);
	float radius = length(world_point - world_centre);
	vec3 grad = sign(det) * (dFdx(h) * r1 + dFdy(h) * r2);
	vec3 bv = abs(det) * n - grad * radius * bump * (1.0 - ocean * 0.85);
	vec3 nb = dot(bv, bv) > 1e-20 ? normalize(bv) : n;   // grazing limb: no NaN into the glow (audit, PR 1776)
	float ndl = dot(n, l);
	float lambert = max(dot(nb, l), 0.0);
	float day = atmo_k > 0.0 ? smoothstep(-0.1, 0.22, ndl) : smoothstep(-0.04, 0.14, ndl);
	vec3 ground = alb * (1.0 - shadow * 0.5);
	vec3 col = ground * (0.02 + lambert * 0.92 * day);
	// clouds: lit tops over the ground, a cool grey toward the terminator
	vec3 ctone = mix(vec3(0.6, 0.63, 0.67), vec3(0.93, 0.94, 0.95), smoothstep(-0.05, 0.4, ndl));
	col = mix(col, ctone * cloud_col * (0.03 + max(ndl, 0.0) * 0.95) * day, cloud * 0.92);
	// the sun on water or ice: a tight glint with a soft halo
	vec3 hv = normalize(l + v);
	float sp = max(dot(mix(n, nb, 0.35), hv), 0.0);
	col += vec3(1.0, 0.95, 0.86) * glint * ocean * (1.0 - cloud) * (pow(sp, 260.0) * 1.1 + pow(sp, 60.0) * 0.05) * day;
	// night side: city lights and lava
	float night = (1.0 - smoothstep(-0.2, 0.06, ndl));
	col += city * b.g * night * 0.85 * (1.0 - cloud * 0.7);
	col += lava_col * b.a * (0.45 + night * 1.2) * (1.0 - cloud * 0.5);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(n, v), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.8;
	ALBEDO = col;
}
"""

static func bake_code() -> String:
	return BAKE_HEAD + NOISE.NOISE + BAKE_BODY


const BAKE_HEAD := """
shader_type canvas_item;
render_mode unshaded, blend_disabled;
"""
const BAKE_BODY := """
uniform vec2 full_size = vec2(2048.0, 1024.0);
uniform float strip_y0 = 0.0;
uniform float strip_h = 1024.0;
uniform float seed = 0.0;
uniform int kind = 0;       // 0 gas giant, 1 ice giant, 2 terran, 3 volcanic desert, 4 barren cratered, 5 ice world
uniform int pass_id = 0;    // 0: albedo + ocean, 1: clouds, lights, relief, lava, 2: relief as 16 bits in R and G
uniform vec3 ca = vec3(0.7, 0.6, 0.4);
uniform vec3 cb = vec3(0.4, 0.3, 0.2);
uniform vec3 cc = vec3(0.9, 0.85, 0.7);

float fb(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 8; k++) { if (k >= oct) break; s += a * wvn3(p); p = p * 2.03 + 1.7; a *= 0.5; } return s; }
float rg(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 6; k++) { if (k >= oct) break; float v = 1.0 - abs(wvn3(p) * 2.0 - 1.0); s += a * v * v; p = p * 2.1 + 3.3; a *= 0.5; } return s; }
float hh(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }

vec3 dir_of(vec2 uv) {
	float phi = (uv.x - 0.5) * 6.28318530718;
	float th = uv.y * 3.14159265359;
	return vec3(sin(th) * sin(phi), cos(th), -sin(th) * cos(phi));
}

// a crater field on the sphere: bowls with rims, many sizes (cells of a 3D grid at three scales). Issue 1765: big
// craters raise a central peak, and a few young ones throw bright rays (ray adds their brightness, fading before the
// edge of the cells this looks through so no ray ends in a straight line).
float craters_r(vec3 d, float scale, float dens, inout float ray) {
	vec3 p = d * scale;
	vec3 b = floor(p - 0.5);
	float h = 0.0;
	for (int i = 0; i < 8; i++) {
		vec3 c = b + vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		float k = hh(c + seed);
		if (k > dens) continue;
		vec3 cp = normalize(c + 0.25 + 0.5 * vec3(hh(c + 1.3), hh(c + 2.9), hh(c + 5.1)));
		float size = hh(c + 7.7);
		float r = (0.18 + 0.3 * size) / scale;
		float u = acos(clamp(dot(d, cp), -1.0, 1.0)) / r;
		h += (u < 1.0 ? -(1.0 - u * u) : 0.0) * 0.6 + exp(-pow((u - 1.0) / 0.2, 2.0)) * 0.25;
		h += exp(-pow(u / 0.16, 2.0)) * 0.3 * smoothstep(0.5, 0.9, size);
		if (hh(c + 9.3) < 0.18 && u > 0.9 && u < 2.4) {
			vec3 e1 = normalize(cross(abs(cp.y) > 0.95 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0), cp));
			vec3 e2 = cross(cp, e1);
			float ang = atan(dot(d, e2), dot(d, e1));
			float streak = smoothstep(0.62, 0.92, wvn3(vec3(cos(ang) * 5.0, sin(ang) * 5.0, hh(c + 3.7) * 40.0)));
			ray += streak * exp(-pow((u - 1.0) / 0.55, 2.0)) * smoothstep(0.9, 1.1, u);
		}
	}
	return h;
}
float craters(vec3 d, float scale, float dens) {
	float unused = 0.0;
	return craters_r(d, scale, dens, unused);
}
// turn v about the unit axis k by a (Rodrigues)
vec3 about(vec3 v, vec3 k, float a) { return v * cos(a) + cross(k, v) * sin(a) + k * dot(k, v) * (1.0 - cos(a)); }

void fragment() {
	vec2 px = vec2(UV.x * full_size.x, strip_y0 + UV.y * strip_h);
	vec3 d = dir_of(px / full_size);
	vec3 q = d + seed * 0.37;
	vec3 alb = ca;
	float ocean = 0.0;
	float cloud = 0.0;
	float lights = 0.0;
	float relief = 0.5;
	float lava = 0.0;
	if (kind == 0 || kind == 1) {
		// banded giants: belts and zones bent by turbulence at two scales, festoons and long streaks along the flow,
		// eddies at the band edges, one great storm and a few white ovals
		float g = kind == 0 ? 1.0 : 0.45;
		vec3 w1 = vec3(fb(q * 2.2, 4), fb(q * 2.2 + 7.0, 4), 0.0) - 0.5;
		vec3 w2 = vec3(fb(vec3(d.x * 6.0, d.y * 18.0, d.z * 6.0) + 11.0, 4), 0.0, 0.0) - 0.5;
		float latw = d.y + (w1.x * 0.09 + w2.x * 0.035) * g;
		float belts = 0.5 + 0.5 * sin(latw * (kind == 0 ? 15.0 : 8.0) + fb(vec3(latw * 3.0, seed, 0.0), 3) * 5.0);
		float stream = fb(vec3(d.x * 3.0, latw * 55.0, d.z * 3.0) + w1 * 2.0 + seed, 5);
		float fest = fb(vec3(d.x * 9.0, latw * 120.0, d.z * 9.0) + w2 * 3.0, 3);
		float t = clamp(belts * 0.75 + (stream - 0.5) * 0.55 * g + (fest - 0.5) * 0.25 * g + 0.1, 0.0, 1.0);
		alb = t < 0.5 ? mix(cb, ca, t * 2.0) : mix(ca, cc, (t - 0.5) * 2.0);
		alb *= 0.9 + 0.2 * fb(q * 5.0 + 3.0, 3);
		for (int i = 0; i < 5; i++) {
			vec3 sc = normalize(vec3(hh(vec3(float(i), seed, 1.0)) - 0.5, (hh(vec3(float(i), seed, 2.0)) - 0.5) * 1.1, hh(vec3(float(i), seed, 3.0)) - 0.5));
			float sr = i == 0 ? 0.13 : 0.025 + 0.03 * hh(vec3(float(i), seed, 4.0));
			vec3 e1 = normalize(cross(vec3(0.0, 1.0, 0.0), sc));
			vec3 e2 = cross(sc, e1);
			vec2 sq = vec2(dot(d, e1) / 2.0, dot(d, e2)) / sr;
			float sd = length(sq);
			if (dot(d, sc) > 0.0 && sd < 1.8) {
				float sw = atan(sq.y, sq.x) + sd * 2.5;
				float curl = fb(vec3(cos(sw) * sd, sin(sw) * sd, float(i)) * 3.0, 4);
				vec3 scol = i == 0 ? mix(cb * 1.3, vec3(0.78, 0.38, 0.22), 0.6) : mix(cc, vec3(0.86, 0.88, 0.90), 0.5);
				float inside = (1.0 - smoothstep(0.75, 1.15, sd));
				alb = mix(alb, min(scol * (0.8 + 0.2 * curl), vec3(0.90)), inside * (kind == 0 ? 0.9 : 0.55));
				alb = mix(alb, mix(cb, ca, 0.35), (1.0 - smoothstep(1.1, 1.6, sd)) * (1.0 - inside) * 0.35 * curl);
			}
		}
		relief = 0.5 + (stream - 0.5) * 0.4;
	} else if (kind == 2) {
		// terran (issue 1765): continents from warped noise with ridged mountain chains, shelf seas that step from a lit
		// teal coast to a deep blue (never black) ocean, ice caps, deserts by latitude, and cloud bands wound into
		// cyclones with fine wisps at their edges
		vec3 w = vec3(fb(q * 1.2, 4), fb(q * 1.2 + 5.0, 4), fb(q * 1.2 + 9.0, 4)) - 0.5;
		float h = fb(q * 1.5 + w * 1.4, 7) + rg(q * 3.0 + w, 4) * 0.12 - 0.06;
		float sea = 0.5;
		float lat = abs(d.y);
		if (h < sea) {
			float dep = clamp((sea - h) * 5.0, 0.0, 1.0);
			vec3 shelf = vec3(0.07, 0.22, 0.25);
			vec3 mid = vec3(0.035, 0.11, 0.19);
			vec3 deep = max(cb, vec3(0.018, 0.05, 0.11));
			alb = mix(shelf, mid, smoothstep(0.0, 0.14, dep));
			alb = mix(alb, deep, smoothstep(0.14, 0.65, dep));
			alb *= 0.9 + 0.2 * fb(q * 16.0 + w * 2.0, 3);
			ocean = 1.0;
			relief = 0.42 - dep * 0.12;
		} else {
			float e = clamp((h - sea) * 4.0, 0.0, 1.0);
			float dry = smoothstep(0.48, 0.66, fb(q * 2.2 + 3.0 + w, 4)) * (1.0 - smoothstep(0.55, 0.8, lat));
			vec3 green = ca * (0.75 + 0.5 * fb(q * 7.0 + 1.0, 3));
			vec3 sand = cc * (0.85 + 0.3 * fb(q * 9.0, 3));
			alb = mix(green, sand, dry);
			// mountain chains: sharp ridges that rise with the land, rock then snow on the highest crests
			float ridge = rg(q * 6.0 + w * 2.5, 5) * smoothstep(0.04, 0.45, e);
			alb = mix(alb, vec3(0.31, 0.28, 0.25), smoothstep(0.3, 0.8, e) * 0.75);
			alb *= 1.0 - ridge * 0.28;
			alb = mix(alb, vec3(0.86, 0.87, 0.88), smoothstep(0.62, 0.85, e * 0.55 + ridge * 0.6) * 0.85);
			// a pale rim of beach and shallows along every coast
			alb = mix(alb, cc * 1.05, (1.0 - smoothstep(0.0, 0.012, h - sea)) * 0.5);
			relief = 0.45 + e * 0.3 + ridge * 0.25;
			// cities: hive sprawl along coasts and in clusters (a contested, crowded world)
			float coast = (1.0 - smoothstep(0.0, 0.08, h - sea));
			float cl = smoothstep(0.55, 0.8, fb(q * 18.0 + 2.0, 4)) * (0.4 + coast);
			lights = clamp(cl * (1.0 - smoothstep(0.6, 0.75, lat)) * (0.6 + 0.6 * hh(floor(d * 900.0))), 0.0, 1.0);
		}
		// Latitude in radians keeps the cap's edge soft instead of pinching at the poles.
		float ice = smoothstep(1.05, 1.40, asin(clamp(lat, 0.0, 1.0)) + (fb(q * 6.0, 3) - 0.5) * 0.1);
		alb = mix(alb, vec3(0.8, 0.83, 0.86), ice);
		ocean *= 1.0 - ice;
		// clouds: a few cyclones wind the band field round their eyes; fine streaks fray the edges
		vec3 dc = d;
		for (int i = 0; i < 4; i++) {
			vec3 cp = normalize(vec3(hh(vec3(float(i), seed, 11.0)) - 0.5, (hh(vec3(float(i), seed, 12.0)) - 0.5) * 1.2, hh(vec3(float(i), seed, 13.0)) - 0.5));
			float cr = 0.12 + 0.1 * hh(vec3(float(i), seed, 14.0));
			float dd = acos(clamp(dot(d, cp), -1.0, 1.0)) / cr;
			float turn = (cp.y >= 0.0 ? 1.0 : -1.0) * 3.2 * exp(-dd * dd) * smoothstep(0.0, 0.3, dd);
			dc = about(dc, cp, turn);
		}
		vec3 cw = vec3(fb(q * 2.0 + 13.0, 3), fb(q * 2.0 + 17.0, 3), 0.0) - 0.5;
		float big = fb(vec3(dc.x * 3.0, dc.y * 10.0, dc.z * 3.0) + cw * 2.5 + 19.0, 6);
		float fine = fb(vec3(dc.x * 12.0, dc.y * 40.0, dc.z * 12.0) + cw * 4.0 + 23.0, 5);
		cloud = smoothstep(0.5, 0.72, big + (fine - 0.5) * 0.6) * 0.85;
		cloud *= smoothstep(0.3, 0.55, fine + 0.12);
		cloud = max(cloud, smoothstep(0.62, 0.8, fine) * 0.3 * smoothstep(0.36, 0.5, big));
	} else if (kind == 3) {
		// volcanic desert (issue 1765): ash plains, dark basalt flow lobes, canyon networks with fine ridged grit, and
		// lava lakes in the low basins
		vec3 w = vec3(fb(q * 1.5, 4), fb(q * 1.5 + 5.0, 4), 0.0) - 0.5;
		float h = fb(q * 2.0 + w, 7);
		float can = rg(q * 4.0 + w * 2.0, 6);
		float fine = rg(q * 18.0 + w * 3.0, 4);
		float grit = fb(q * 40.0, 3);
		alb = mix(cb, ca, smoothstep(0.35, 0.65, h));
		alb = mix(alb, cc, smoothstep(0.7, 0.9, fb(q * 6.0 + 2.0, 3)) * 0.5);
		// Wave 0 (Nov 23): basalt flows with crisp edges (they blurred into a haze at the battle camera)
		float flow = smoothstep(0.5, 0.515, fb(q * 3.5 + w * 1.5 + 40.0, 5));
		alb = mix(alb, cb * 0.8, flow * 0.85);
		alb *= mix(0.62, 1.0, (1.0 - smoothstep(0.6, 0.85, can)));
		alb *= (0.85 + 0.25 * grit) * (1.0 - smoothstep(0.7, 0.95, fine) * 0.3);
		// Ryan (Nov 23): no crack lines. The glow is shaped by the land: lava lakes in the lowest basins, short channels
		// feeding them along the canyon floors just above, and dark cooled crust around both
		float low = 1.0 - smoothstep(0.36, 0.46, h);
		float lake = 1.0 - smoothstep(0.33, 0.38, h);
		float chan = smoothstep(0.8, 0.93, can) * (1.0 - smoothstep(0.38, 0.48, h));
		alb *= 1.0 - low * 0.45;
		alb = mix(alb, cb * 0.4, lake * 0.85);
		// a lake glows brightest at its deepest point, under a broken skin of cooling crust
		float deep = 1.0 - smoothstep(0.26, 0.38, h);
		float crust = smoothstep(0.42, 0.62, fb(q * 34.0 + 3.0, 4));
		relief = clamp(h * 0.6 + (1.0 - can) * 0.25 + fine * 0.15 - flow * 0.01 - lake * 0.05, 0.0, 1.0);
		lava = max(lake * deep * (1.0 - crust * 0.75), chan * 0.45);
		cloud = smoothstep(0.7, 0.86, fb(q * 3.0 + 9.0 + w, 4)) * 0.15;
	} else if (kind == 4) {
		// barren cratered (issue 1765): highlands and dark maria, four sizes of crater with central peaks, bright young
		// rays and strong tone breaks, so it reads as hard rock in raking light rather than a grey ball
		float m = smoothstep(0.45, 0.6, fb(q * 1.3, 4));
		float ray = 0.0;
		float cr = craters_r(d, 5.0, 0.5, ray) + craters_r(d, 13.0, 0.6, ray) * 0.6 + craters(d, 34.0, 0.65) * 0.35 + craters(d, 90.0, 0.7) * 0.18;
		alb = mix(ca, cb, m * 0.85) * (0.8 + 0.35 * fb(q * 12.0, 4));
		alb *= 1.0 + cr * 0.35;
		alb = mix(alb, cc * 1.05, clamp(ray, 0.0, 1.0) * 0.45);
		relief = 0.5 + cr * 0.3 - m * 0.05;
	} else {
		// ice world (issue 1765): bright glacial plains with faint wide bands of older ice, blue-grey chaos terrain of broken blocks, fine fractures, a few craters, and a glossy
		// sheen for the sun to catch
		float base = fb(q * 3.0, 5);
		alb = ca * (0.88 + 0.16 * base);
		alb = mix(alb, mix(ca, cb, 0.3), smoothstep(0.42, 0.7, fb(q * 1.6 + 21.0, 4)) * 0.55);
		// Ryan (Nov 23): no crack lines. Faint wide bands of bluer, older ice instead, soft edged and much broader
		// than a line, over frosted ground
		float band = smoothstep(0.6, 0.85, 1.0 - abs(fb(q * 0.9 + 13.0, 4) * 2.0 - 1.0));
		alb *= 0.94 + 0.1 * fb(q * 26.0, 3);
		alb = mix(alb, mix(ca, cc, 0.4), band * 0.5);
		float chaos = smoothstep(0.6, 0.7, fb(q * 2.2 + 31.0, 4));
		float blocks = rg(q * 22.0, 3);
		alb = mix(alb, mix(cc * 0.85, cb * 0.85, smoothstep(0.55, 0.85, blocks)), chaos * 0.7);
		float frac = rg(q * 9.0 + 4.0, 4);
		alb = mix(alb, cc, smoothstep(0.86, 0.96, frac) * 0.45);
		float cr = craters(d, 10.0, 0.25) * 0.3;
		alb *= 1.0 + cr * 0.2;
		relief = 0.5 - band * 0.03 + (base - 0.5) * 0.2 - chaos * 0.1 + blocks * chaos * 0.12 + cr * 0.2;
		ocean = 0.55 * (1.0 - band * 0.3) * (1.0 - chaos * 0.5);   // the glossy sheen on clean ice
	}
	vec4 o;
	if (pass_id == 2) {
		// the board planet's height: 16 bits, high byte in R, low in G (read as dot(rg, (65280, 255)) / 65535)
		float v = floor(clamp(relief, 0.0, 1.0) * 65535.0 + 0.5);
		float hi = floor(v / 256.0);
		COLOR = vec4(hi / 255.0, (v - hi * 256.0) / 255.0, 0.0, 1.0);
		return;
	}
	if (pass_id == 0) {
		// Recipes already describe sRGB albedo. The sphere's source_color sampler decodes it once.
		o = vec4(clamp(alb, 0.0, 1.0), ocean);
	} else {
		o = vec4(cloud, lights, clamp(relief, 0.0, 1.0), lava);
	}
	o.rgb += (hh(vec3(px, seed)) - 0.5) / 255.0;
	COLOR = o;
}
"""

# The planet sphere, unshaded with its own lighting from the key light, so it sits in the scene's light without the
# scene's shadows or fog. Drawn far beyond the board.
const SPHERE := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D tex_a : source_color, filter_linear, repeat_enable;
// Packed masks and relief are linear data, including the ocean mask in tex_a.a.
uniform sampler2D tex_b : filter_linear, repeat_enable;
uniform float has_tex = 0.0;
uniform vec3 flat_col = vec3(0.3);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);     // toward the sun, world space
uniform vec3 sun_col = vec3(1.0, 0.95, 0.88);
uniform float light = 1.0;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float atmo_k = 1.0;
uniform float spin = 0.004;
uniform vec3 tint = vec3(1.0);
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
uniform vec4 ring = vec4(0.0);           // xyz ring normal (world), w on
uniform vec2 ring_r = vec2(1.3, 2.3);    // in planet radii
uniform float rough = 1.0;
varying vec3 vObj;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vObj = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
vec2 uv_of(vec3 d) { return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359); }
vec3 spun(vec3 d, float a) { float c = cos(a); float s = sin(a); return vec3(c * d.x + s * d.z, d.y, -s * d.x + c * d.z); }
void fragment() {
	vec3 n0 = normalize(vObj);
	vec3 N = normalize(vW - vC);
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	vec3 ds = spun(n0, TIME * spin);
	vec3 alb = flat_col;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float ocean = 0.0;
	if (has_tex > 0.5) {
		vec4 a = texture(tex_a, uv_of(ds));
		alb = a.rgb;
		ocean = a.a;
		b = texture(tex_b, uv_of(ds));
	}
	alb *= tint;
	float ndl = dot(N, L);
	// relief: a cheap bump from the baked height, along the surface. The two height samples step along the local
	// tangent and bitangent (object space, before the texture spin), and the bumped normal tilts along the same two
	// directions taken to world space, so ridges light from the sun's side all round the planet (issue 1468; fixed
	// object X and Y steps flipped on the far half and vanished at the X poles)
	vec3 up_o = abs(n0.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 t_o = normalize(cross(up_o, n0));
	vec3 b_o = cross(n0, t_o);
	vec3 dsx = spun(normalize(n0 + t_o * 0.003), TIME * spin);
	vec3 dsy = spun(normalize(n0 + b_o * 0.003), TIME * spin);
	float hx = has_tex > 0.5 ? texture(tex_b, uv_of(dsx)).b - b.b : 0.0;
	float hy = has_tex > 0.5 ? texture(tex_b, uv_of(dsy)).b - b.b : 0.0;
	mat3 m3 = mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
	vec3 tx = normalize(m3 * t_o);
	tx = normalize(tx - N * dot(tx, N));
	vec3 ty = normalize(m3 * b_o);
	ty = normalize(ty - N * dot(ty, N) - tx * dot(ty, tx));
	vec3 Nb = normalize(N - (tx * hx + ty * hy) * 2.5 * rough * (1.0 - b.r));
	float lam = max(dot(Nb, L), 0.0);
	// the terminator softened by the atmosphere
	float wrap = atmo_k > 0.0 ? smoothstep(-0.12, 0.3, ndl) : smoothstep(-0.02, 0.12, ndl);
	float diff = mix(lam, wrap * lam + wrap * 0.04, 0.5);
	// cloud shadows on the ground: the clouds a little toward the sun
	float cs = 0.0;
	if (has_tex > 0.5 && b.r > 0.0) {
		vec3 dl = spun(normalize(n0 + (transpose(mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz)) * L) / vR * 0.012), TIME * spin);
		cs = texture(tex_b, uv_of(dl)).r;
	}
	vec3 ground = alb * (1.0 - cs * 0.55);
	vec3 col = mix(ground, vec3(0.82, 0.85, 0.88), b.r) * diff * sun_col;
	// the sun's glint on water
	vec3 H = normalize(L + V);
	// issue 1765: a tight glint with a faint halo (the broad lobe read as a white blob on the sea)
	float gl = max(dot(N, H), 0.0);
	col += sun_col * ocean * (1.0 - b.r) * (pow(gl, 260.0) * 1.3 + pow(gl, 50.0) * 0.06) * smoothstep(0.0, 0.1, ndl);
	// ring shadow on the planet
	if (ring.w > 0.5) {
		vec3 rn = normalize(ring.xyz);
		float den = dot(L, rn);
		if (abs(den) > 1e-3) {
			float t = dot(vC - vW, rn) / den;
			if (t > 0.0) {
				float rr = length(vW + L * t - vC) / vR;
				float band = smoothstep(ring_r.x, ring_r.x + 0.08, rr) * (1.0 - smoothstep(ring_r.y - 0.15, ring_r.y, rr));
				col *= 1.0 - band * 0.6;
			}
		}
	}
	// night side: city lights and lava
	float night = (1.0 - smoothstep(-0.18, 0.08, ndl));
	col += city * b.g * night * 0.9 * (1.0 - b.r * 0.7);
	col += lava_col * b.a * (0.25 + night * 1.2);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.9;
	col = mix(col, atmo * diff * 0.6, atmo_k * rim * 0.35);
	ALBEDO = col * light;
}
"""

# The atmosphere's outer glow: a slightly larger shell, added, brightest just outside the limb on the lit side.
const ATMO := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_front, shadows_disabled, fog_disabled;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform float k = 1.0;
uniform float shell = 1.04;
varying vec3 vW;
varying vec3 vC;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz; }
void fragment() {
	vec3 N = normalize(vW - vC);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// back faces of the shell: the ray's closest approach to the centre, in shell radii, says how much air it crossed
	vec3 ro = CAMERA_POSITION_WORLD - vC;
	vec3 rd = -V;
	float R = length(vW - vC);
	float tc = -dot(ro, rd);
	float dmin = length(ro + rd * tc) / R;
	float inner = 1.0 / shell;
	float a = (1.0 - smoothstep(inner, 1.0, dmin));
	a = a * a * smoothstep(inner * 0.985, inner + 0.004, dmin);
	vec3 P = normalize(ro + rd * tc);
	float lit = smoothstep(-0.35, 0.5, dot(P, normalize(sun)));
	ALBEDO = atmo * a * lit * k * 1.4;
}
"""

const RING := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform vec3 col_a = vec3(0.85, 0.78, 0.66);
uniform vec3 col_b = vec3(0.5, 0.42, 0.34);
uniform vec2 ring_r = vec2(1.3, 2.3);
uniform float seed = 0.0;
uniform float light = 1.0;
varying vec3 vL;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vL = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
float h1(float x) { return fract(sin(x * 127.1 + seed) * 43758.5453); }
float n1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f); return mix(h1(i), h1(i + 1.0), f); }
void fragment() {
	float r = length(vL.xz);
	float u = (r - ring_r.x) / (ring_r.y - ring_r.x);
	if (u < 0.0 || u > 1.0) { discard; }
	float dens = 0.0;
	float a = 1.0;
	float f = 4.0;
	for (int k = 0; k < 5; k++) { dens += n1(u * f + float(k) * 3.1) * a; a *= 0.55; f *= 2.3; }
	dens = clamp(dens / 1.9, 0.0, 1.0);
	dens *= smoothstep(0.0, 0.04, u) * (1.0 - smoothstep(0.94, 1.0, u));
	// a dark gap two thirds of the way out (Cassini-like) and a thin faint inner ring
	dens *= 1.0 - 0.9 * exp(-pow((u - 0.66) / 0.018, 2.0));
	dens *= mix(0.35, 1.0, smoothstep(0.08, 0.2, u));
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// Closest point on the ray toward the sun, in planet radii. On the lit
	// side the closest point is the ring itself, already outside the sphere.
	vec3 rel = vW - vC;
	float t = max(dot(-rel, L), 0.0);
	float dperp = length(rel + L * t) / vR;
	// Widen the penumbra downsun and keep some light in the umbra so the
	// shadow reads across the bands without looking like a cut in the ring.
	float penumbra = mix(0.23, 0.48, smoothstep(0.0, 2.0, t / vR));
	float sh = mix(0.38, 1.0, smoothstep(1.0 - penumbra, 1.0 + penumbra, dperp));
	vec3 c = mix(col_b, col_a, n1(u * 23.0 + 5.0));
	// lit from either side; brighter seen against the light (forward scattering)
	float fwd = pow(max(dot(-V, L), 0.0), 6.0);
	vec3 lit = c * (0.55 + 0.6 * fwd) * sh;
	ALBEDO = lit * light;
	ALPHA = dens * 0.85;
}
"""
