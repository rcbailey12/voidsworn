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
	stand_in.shader = BOARD_SURFACE
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
	# No frame wait here (PC_F and PC_I, Nov 23): the board builds inside the battle's _ready, and the bake service now
	# joins the tree deferred (world_bake.gd service), so the board's maps are queued at once, ahead of the sky and the
	# backdrops the world asks for right after. Waiting a frame let the sky take the idle worker first, and the board's
	# whole map set then waited behind a 4K sky bake: the volcanic board planet missed the loading cover.
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
	var job := board_job(look_kind, seed_v)
	var params: Dictionary = job.params
	var key: String = job.key
	var size: Vector2i = job.size
	var code: String = job.code
	# urgent: ahead of the far backdrop bakes, so a cold cache still makes the loading cover (PC proof, PR 1776)
	# all three are queued before any is awaited, so no backdrop runs between them (Artoo, PR 1776)
	var ka: String = baker.request_bake(key + "|a", code, params, size, 32, false, true, true)
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


# The board planet's bake request for a baked look (terran, ice, volcanic): one place for install_board and the check
# that seeds its cache (Neon, PR 1776 item 4). pass_id is 0 here; the b and h maps ask with 1 and 2.
static func board_job(look_kind: int, seed_v: int) -> Dictionary:
	var L: Dictionary = BOARD_LOOKS.get(look_kind, BOARD_LOOKS[0])
	var size := BOARD_SIZE
	if OS.has_environment("VS_WORLD_PREVIEW"): size = Vector2i(1024, 512)
	return {"key": "board_planet|%d|%d" % [look_kind, posmod(seed_v, 997)], "code": bake_code(), "size": size,
		"params": {"seed": float(posmod(seed_v * 31 + look_kind * 7, 997)) * 0.71, "kind": int(L["bake"]), "ca": L["a"], "cb": L["b"], "cc": L["c"], "pass_id": 0}}


static func _board_air(air: MeshInstance3D, L: Dictionary, light_dir: Vector3) -> void:
	if not is_instance_valid(air): return
	if float(L["atmo_k"]) <= 0.0:
		air.visible = false
		return
	var atmosphere := ShaderMaterial.new()
	atmosphere.shader = ATMO
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
	var kc: String = baker.request_authored(R01_DIR + "colour.json", R01_SIZE, false, urgent, true)
	var kd: String = baker.request_authored(R01_DIR + "relief.json", R01_SIZE, true, urgent)
	var colour: Image = await baker.result(kc)
	var data: Image = await baker.result(kd)
	if not is_instance_valid(planet) or colour == null or data == null: return
	if planet.get_meta("planet_frozen", false): return   # the loading cover already lifted (board.gd wait_planet)
	var light_dir := (sun_position - planet.global_position).normalized()
	var clouds := bool(opts.get("clouds", true))
	var ground := ShaderMaterial.new()
	ground.shader = ROCKY_SURFACE
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
			atmosphere.shader = ATMO
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
	cloud_material.shader = ROCKY_CLOUDS
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

const ROCKY_SURFACE := preload("res://shaders/planet_rocky_surface.gdshader")

const ROCKY_CLOUDS := preload("res://shaders/planet_rocky_clouds.gdshader")

# Issue 1765: the baked board planet (terran, ice, volcanic). The surface comes from this file's recipes at 4K, with a
# 16-bit height map for the relief; light, mips and the longitude wrap work as the R01 surface does. Clouds drift over
# the ground and cast shadows toward the night side; water and ice catch the sun; cities and lava glow on the night side.
const BOARD_SURFACE := preload("res://shaders/planet_board_surface.gdshader")

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

// Ryan (Nov 23): coastlines and flow edges ran in straight lines. The lattice noise lines up with the grid axes, and
// every octave used to share those axes; each finer octave is now turned (OCT_ROT, a fixed rotation), so edges break
// up at every scale. The first octave stays put, so the big shapes keep their places.
const mat3 OCT_ROT = mat3(vec3(0.00, 0.80, 0.60), vec3(-0.80, 0.36, -0.48), vec3(-0.60, -0.48, 0.64));
float fb(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 8; k++) { if (k >= oct) break; s += a * wvn3(p); p = OCT_ROT * p * 2.03 + 1.7; a *= 0.5; } return s; }
float rg(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 6; k++) { if (k >= oct) break; float v = 1.0 - abs(wvn3(p) * 2.0 - 1.0); s += a * v * v; p = OCT_ROT * p * 2.1 + 3.3; a *= 0.5; } return s; }
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
		h += (fb(q * 22.0 + w * 4.0, 4) - 0.5) * 0.035;   // fine bays, capes and islands along every coast
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
		float flow = smoothstep(0.535, 0.55, fb(q * 3.5 + w * 1.5 + 40.0, 7) + (fb(q * 30.0, 3) - 0.5) * 0.04);   // ragged lobe edges
		alb = mix(alb, cb * 0.8, flow * 0.85);
		alb *= mix(0.62, 1.0, (1.0 - smoothstep(0.6, 0.85, can)));
		alb *= (0.85 + 0.25 * grit) * (1.0 - smoothstep(0.7, 0.95, fine) * 0.3);
		// Ryan (Nov 23): no crack lines. The glow is shaped by the land: lava lakes in the lowest basins, short channels
		// feeding them along the canyon floors just above, and dark cooled crust around both
		float low = 1.0 - smoothstep(0.31, 0.41, h);
		float lake = 1.0 - smoothstep(0.27, 0.32, h);
		float chan = smoothstep(0.8, 0.93, can) * (1.0 - smoothstep(0.33, 0.43, h));
		alb *= 1.0 - low * 0.45;
		alb = mix(alb, cb * 0.4, lake * 0.85);
		// a lake glows brightest at its deepest point, under a broken skin of cooling crust
		float deep = 1.0 - smoothstep(0.2, 0.32, h);
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
const SPHERE := preload("res://shaders/planet_sphere.gdshader")

# The atmosphere's outer glow: a slightly larger shell, added, brightest just outside the limb on the lit side.
const ATMO := preload("res://shaders/planet_atmo.gdshader")

const RING := preload("res://shaders/planet_ring.gdshader")
