extends RefCounted
# F4 sky: the battle's setting (which region of space the sector is in, its palette, its planet) and the sky itself.
#
# The sky is two parts:
#   1. a nebula picture baked once per setting on the GPU (world_bake.gd): a ray-marched volume of glowing gas lit by a
#      few embedded stars, with dark dust lanes that also swallow the stars behind them, the galaxy's band with its dark
#      rift, and a few far galaxies. Stored as an equirectangular image (rgb gamma-encoded light, alpha = how much
#      starlight gets through), so the per-frame cost is one texture read.
#   2. the per-frame sky shader: the baked picture plus the stars, drawn per screen pixel so they stay pin sharp at any
#      resolution (three layers by brightness, colour by temperature, denser along the galactic band, dimmed behind
#      dust), the bright stars that light the gas (with soft halos), and the system's sun where the key light comes from.
#
# Coherence (Ryan, Nov 1: maps vary fight to fight but stay coherent within a run): the setting comes from the sector's
# biome (one per sector, campaign.gd rollBiome by region) and the enemy faction, so every battle of a sector shares one
# sky and one planet; the battle's own seed only turns the view a little (a different spot in the same system).

const NOISE := preload("res://world/world_shaders.gd")

# Regions of the campaign (rules REGION_BIOME): rock kinds and planet indices each region rolls from. A biome is matched
# to the region that explains it best; a quick battle's random biome lands somewhere sensible.
const REGION_OF := {
	"frontier": {"rock": ["stone", "iron"], "planet": [4, 5, 0]},
	"nebula": {"rock": ["ice", "crystal"], "planet": [2, 6, 7]},
	"world": {"rock": ["stone", "ice"], "planet": [3, 4, 1]},
	"boneyard": {"rock": ["carbon", "iron"], "planet": [5, 0, 6]},
	"deep": {"rock": ["carbon", "ice"], "planet": [6, 7, 2]},
}

# Per region: nebula brightness, how much of the sky it covers, dust, galactic band brightness, star density, warm or cold
# light, haze colour bias, and how many rocks the maps put round the board.
const REGION := {
	"frontier": {"neb": 0.55, "cover": 0.5, "dust": 0.75, "band": 0.6, "stars": 1.0, "warm": 0.6, "rocks": 1.0, "tint": Vector3(0.75, 0.55, 0.38)},
	"nebula": {"neb": 1.0, "cover": 0.72, "dust": 0.6, "band": 0.4, "stars": 0.9, "warm": 0.2, "rocks": 0.8, "tint": Vector3(1.0, 1.0, 1.0)},
	"world": {"neb": 0.5, "cover": 0.45, "dust": 0.5, "band": 0.8, "stars": 1.0, "warm": 0.3, "rocks": 0.7, "tint": Vector3(0.7, 0.8, 1.0)},
	"boneyard": {"neb": 0.45, "cover": 0.55, "dust": 1.0, "band": 0.45, "stars": 0.8, "warm": 0.8, "rocks": 0.9, "tint": Vector3(0.9, 0.55, 0.45)},
	"deep": {"neb": 0.22, "cover": 0.3, "dust": 0.6, "band": 1.0, "stars": 0.65, "warm": 0.1, "rocks": 0.5, "tint": Vector3(0.6, 0.65, 0.85)},
	"deadstar": {"neb": 0.35, "cover": 0.45, "dust": 0.9, "band": 0.7, "stars": 0.75, "warm": 1.0, "rocks": 0.7, "tint": Vector3(1.0, 0.55, 0.35)},
}

# The system's planet per biome planet index (0..7, the game's eight backdrop looks): kind for the planet bake
# (0 gas giant, 1 ice giant, 2 terran, 3 desert and volcanic, 4 barren cratered, 5 ice world), palette, atmosphere,
# rings, how many moons.
const PLANETS := [
	{"kind": 0, "a": Vector3(0.78, 0.62, 0.42), "b": Vector3(0.42, 0.28, 0.17), "c": Vector3(0.95, 0.88, 0.74), "atmo": Vector3(0.95, 0.78, 0.55), "rings": true, "moons": 3},
	{"kind": 1, "a": Vector3(0.36, 0.55, 0.85), "b": Vector3(0.16, 0.3, 0.6), "c": Vector3(0.7, 0.85, 1.0), "atmo": Vector3(0.45, 0.7, 1.0), "rings": false, "moons": 2},
	{"kind": 0, "a": Vector3(0.58, 0.44, 0.7), "b": Vector3(0.24, 0.14, 0.34), "c": Vector3(0.92, 0.8, 0.9), "atmo": Vector3(0.75, 0.55, 1.0), "rings": false, "moons": 2},
	{"kind": 2, "a": Vector3(0.3, 0.36, 0.2), "b": Vector3(0.02, 0.06, 0.14), "c": Vector3(0.62, 0.55, 0.42), "atmo": Vector3(0.38, 0.62, 1.0), "rings": false, "moons": 1},
	{"kind": 3, "a": Vector3(0.62, 0.32, 0.17), "b": Vector3(0.24, 0.1, 0.06), "c": Vector3(0.85, 0.6, 0.4), "atmo": Vector3(1.0, 0.55, 0.32), "rings": false, "moons": 2},
	{"kind": 4, "a": Vector3(0.42, 0.4, 0.38), "b": Vector3(0.17, 0.16, 0.16), "c": Vector3(0.6, 0.58, 0.55), "atmo": Vector3(0.0, 0.0, 0.0), "rings": false, "moons": 0},
	{"kind": 5, "a": Vector3(0.82, 0.86, 0.9), "b": Vector3(0.48, 0.38, 0.3), "c": Vector3(0.6, 0.78, 0.95), "atmo": Vector3(0.55, 0.75, 1.0), "rings": false, "moons": 1},
	{"kind": 0, "a": Vector3(0.38, 0.66, 0.62), "b": Vector3(0.12, 0.3, 0.32), "c": Vector3(0.82, 0.95, 0.9), "atmo": Vector3(0.4, 0.95, 0.85), "rings": true, "moons": 2},
]

const FLOOK := preload("res://fx/faction_look.gd")


static func region_for(biome: Dictionary) -> String:
	var rock := str(biome.get("rock", ""))
	var pl := int(biome.get("planet", -1))
	var best := "frontier"
	var bs := -1
	for k in ["frontier", "nebula", "world", "boneyard", "deep"]:
		var s := 0
		if (REGION_OF[k]["rock"] as Array).has(rock):
			s += 2
		if (REGION_OF[k]["planet"] as Array).has(pl):
			s += 2
			# the first planet of a region's list is its most typical
			if REGION_OF[k]["planet"][0] == pl:
				s += 1
		if s > bs:
			bs = s
			best = k
	return best


# The setting of one battle. map_kind: open, belt, station, planet, storm, graveyard (worked out from the terrain).
static func setting(biome: Dictionary, fac: String, map_kind: String, deadstar: bool, battle_seed: int) -> Dictionary:
	var region := "deadstar" if deadstar else region_for(biome)
	var R: Dictionary = REGION[region]
	var key := "%s|%s|%s|%s" % [str(biome.get("rock", "")), str(biome.get("planet", "")), fac, region]
	var sseed := absi(hash(key)) % 100000
	var rng := RandomNumberGenerator.new()
	rng.seed = sseed
	var neb: Array = FLOOK.of(fac).get("nebula", FLOOK.of("voidsworn")["nebula"])
	var tint: Vector3 = R["tint"]
	# the gas: the faction's three colours, pulled toward the region's light; a cold second colour for depth
	var c1: Vector3 = (neb[1] as Vector3) * tint
	var c2: Vector3 = (neb[0] as Vector3).lerp(Vector3(0.12, 0.22, 0.42), 0.35)
	# two gases that differ: if the faction's colours are close in hue, the second turns toward the complement
	if (c1.normalized() - c2.normalized()).length() < 0.25:
		c2 = c2.lerp(Vector3(c1.z, c1.x * 0.8, c1.y) * 0.6, 0.55)
	var c3: Vector3 = (neb[2] as Vector3).lerp(Vector3(1.0, 0.82, 0.62), 0.3)
	if region == "deadstar":
		c1 = Vector3(0.62, 0.22, 0.08)
		c2 = Vector3(0.2, 0.06, 0.05)
		c3 = Vector3(1.0, 0.62, 0.3)
	# the battle turns the view a little inside the same system
	var brng := RandomNumberGenerator.new()
	brng.seed = battle_seed
	var yaw := brng.randf_range(-0.35, 0.35)
	var s := {
		"region": region, "seed": sseed, "map": map_kind, "deadstar": deadstar, "fac": fac,
		"c1": c1, "c2": c2, "c3": c3, "neb": float(R["neb"]), "cover": float(R["cover"]), "dust": float(R["dust"]),
		"band": float(R["band"]), "stars": float(R["stars"]), "warm": float(R["warm"]), "rocks": float(R["rocks"]),
		"rock": str(biome.get("rock", "stone")) if biome.has("rock") else ["stone", "iron", "carbon", "ice"][sseed % 4],
		"yaw": yaw,
		# the galactic band's plane (its normal), tilted per setting
		"band_n": Vector3(rng.randf_range(-0.5, 0.5), 1.0, rng.randf_range(-0.6, 0.6)).normalized(),
		# the brightest part of the nebula sits in the default view's sky (below the board, ahead), turned a little
		"feature": Basis(Vector3.UP, yaw + rng.randf_range(-0.5, 0.5)) * Vector3(rng.randf_range(-0.35, 0.35), -0.42, -0.85).normalized(),
	}
	var pi := int(biome.get("planet", sseed % 8)) if biome.has("planet") else sseed % 8
	s["planet_i"] = posmod(pi, PLANETS.size())
	s["planet"] = PLANETS[s["planet_i"]]
	# the haze far rocks fade into: the sky's own dim colour
	s["haze"] = (c1 * 0.5 + c2 * 0.5) * (0.05 + 0.06 * float(R["neb"]))
	return s


# ---------------------------------------------------------------- the bake shader (canvas_item, one strip at a time)

static func bake_code() -> String:
	return BAKE_HEAD + NOISE.NOISE + BAKE_BODY


const BAKE_HEAD := """
shader_type canvas_item;
render_mode unshaded, blend_disabled;
"""
const BAKE_BODY := """
uniform vec2 full_size = vec2(4096.0, 2048.0);
uniform float strip_y0 = 0.0;
uniform float strip_h = 2048.0;
uniform float seed = 0.0;
uniform vec3 c1 = vec3(0.5, 0.2, 0.4);
uniform vec3 c2 = vec3(0.1, 0.2, 0.4);
uniform vec3 c3 = vec3(1.0, 0.7, 0.5);
uniform float neb = 0.6;
uniform float cover = 0.5;
uniform float dust = 0.7;
uniform float band = 0.6;
uniform vec3 band_n = vec3(0.0, 1.0, 0.0);
uniform vec3 feature = vec3(0.0, -0.4, -0.9);
uniform int steps = 40;
uniform vec4 lamp[6];      // embedded stars lighting the gas: xyz direction, w strength
uniform vec4 gal[5];       // far galaxies: xyz direction, w size (radians)

float fbm3n(vec3 p, int oct) { float a = 0.5; float s = 0.0; for (int k = 0; k < 6; k++) { if (k >= oct) break; s += a * wvn3(p); p = p * 2.07 + 3.1; a *= 0.5; } return s; }
float ridge3(vec3 p) { float s = 0.0; float a = 0.5; for (int k = 0; k < 4; k++) { float v = 1.0 - abs(wvn3(p) * 2.0 - 1.0); s += a * v * v; p = p * 2.13 + 1.7; a *= 0.5; } return s; }
float h3(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }

vec3 dir_of(vec2 uv) {
	float phi = (uv.x - 0.5) * 6.28318530718;
	float th = uv.y * 3.14159265359;
	return vec3(sin(th) * sin(phi), cos(th), -sin(th) * cos(phi));
}

// gas density and dust at a point of the nebula's space (the shell between radius 0.55 and 1.6 round the viewer)
void field(vec3 p, out float gas, out float dst, out float hue) {
	vec3 q = p * 1.6 + seed;
	// where the clouds are: a broad mask, strongest toward the feature direction
	float f = dot(normalize(p), feature);
	float m = fbm3n(q * 0.55, 4) + 0.38 * smoothstep(0.2, 0.95, f) - 0.2 * (1.0 - cover);
	if (m < 0.2) { gas = 0.0; dst = 0.0; hue = 0.5; return; }
	float mask = smoothstep(0.42, 0.68, m);
	// domain warp: billows and folds
	vec3 w = vec3(fbm3n(q * 1.1 + 4.0, 3), fbm3n(q * 1.1 + 9.0, 3), fbm3n(q * 1.1 + 15.0, 3)) - 0.5;
	vec3 r = q * 1.9 + w * 2.4;
	float n = fbm3n(r, 6);
	float fil = ridge3(r * 1.6 + 2.0);
	gas = mask * (smoothstep(0.38, 0.85, n) * 0.85 + fil * fil * fil * 0.9 * smoothstep(0.3, 0.6, n));
	// dust: its own folds, a little offset, sharp edged
	float dn = fbm3n(r * 1.3 + w * 1.5 + 21.0, 5);
	dst = smoothstep(0.5, 0.72, dn) * smoothstep(0.3, 0.6, m + 0.1) * dust;
	hue = fbm3n(q * 0.9 + w + 31.0, 3);
}

vec3 galaxy_band(vec3 d, out float rift) {
	float y = dot(d, band_n);
	float core = exp(-pow(y / 0.17, 2.0));
	float wide = exp(-pow(y / 0.42, 2.0));
	// the galactic centre is warmer and brighter on one side of the band
	vec3 cdir = normalize(cross(band_n, vec3(0.31, 0.0, 0.95)));
	float cen = 0.5 + 0.5 * dot(normalize(d - band_n * y), cdir);
	float clump = fbm3n(d * 9.0 + seed * 0.7, 5);
	float lum = (core * (0.4 + 0.9 * smoothstep(0.35, 0.75, clump)) + wide * 0.18) * (0.6 + 0.9 * cen * cen);
	float rn = fbm3n(d * 6.0 + vec3(5.0, seed, 1.0), 5);
	rift = 1.0 - exp(-pow(y / 0.06, 2.0)) * smoothstep(0.35, 0.6, rn) * 0.85 - core * smoothstep(0.55, 0.75, rn) * 0.4;
	vec3 col = mix(vec3(0.55, 0.62, 0.8), vec3(1.0, 0.82, 0.6), cen * cen);
	return col * lum * band * 0.06;
}

vec3 far_galaxies(vec3 d) {
	vec3 c = vec3(0.0);
	for (int i = 0; i < 5; i++) {
		if (gal[i].w <= 0.0) continue;
		vec3 g = normalize(gal[i].xyz);
		vec3 u = normalize(cross(g, vec3(0.0, 1.0, 0.13)));
		vec3 v = cross(g, u);
		vec2 q = vec2(dot(d, u), dot(d, v)) / gal[i].w;
		if (dot(d, g) < 0.0 || dot(q, q) > 9.0) continue;
		float a = h3(g * 91.0) * 6.28;
		q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * q;
		q.y /= 0.25 + 0.6 * h3(g * 13.0);
		float r = length(q);
		float th = atan(q.y, q.x);
		float arms = 0.6 + 0.4 * sin(th * 2.0 - log(r + 0.05) * 5.0);
		c += vec3(0.95, 0.88, 0.8) * (exp(-r * r * 30.0) * 1.4 + exp(-r * 3.2) * arms * 0.35) * 0.08;
	}
	return c;
}

void fragment() {
	vec2 px = vec2(UV.x * full_size.x, strip_y0 + UV.y * strip_h);
	vec2 uv = px / full_size;
	vec3 d = dir_of(uv);
	float rift;
	vec3 bg = galaxy_band(d, rift) + far_galaxies(d);
	// march the gas front to back from the viewer outward
	vec3 col = vec3(0.0);
	float T = 1.0;
	float t0 = 0.55;
	float t1 = 1.6;
	float dt = (t1 - t0) / float(steps);
	float jit = h3(vec3(px, seed)) * dt;
	for (int i = 0; i < 64; i++) {
		if (i >= steps || T < 0.01) break;
		float t = t0 + jit + dt * float(i);
		vec3 p = d * t;
		float gas;
		float dst;
		float hue;
		field(p, gas, dst, hue);
		if (gas + dst < 0.002) continue;
		// light from the embedded stars: brighter, hotter gas round them
		float lit = 0.35;
		vec3 hot = vec3(0.0);
		for (int k = 0; k < 6; k++) {
			if (lamp[k].w <= 0.0) continue;
			vec3 lp = normalize(lamp[k].xyz) * 1.0;
			float q = distance(p, lp);
			float e = lamp[k].w / (1.0 + q * q * 26.0);
			lit += e;
			hot += c3 * e * exp(-q * q * 40.0) * 0.6;
		}
		vec3 ec = mix(c2, c1, smoothstep(0.32, 0.68, hue));
		ec = mix(ec, c3, smoothstep(0.62, 0.9, gas) * 0.35);
		vec3 em = (ec * lit + hot) * gas * neb;
		float sig = gas * 2.2 + dst * 9.0;
		float a = 1.0 - exp(-sig * dt * 3.0);
		// dust dims what it covers and reflects a little dull light itself
		col += T * (em * dt * 3.0 + mix(c2, vec3(0.05), 0.5) * dst * dt * 0.05);
		T *= 1.0 - a * mix(0.35, 1.0, clamp(dst * 3.0, 0.0, 1.0));
	}
	// richer colour: push the gas away from grey (the palettes are close to grey in places), deepen the voids
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = max(mix(vec3(lum), col, 1.45), vec3(0.0));
	col = col * (0.6 + 0.8 * smoothstep(0.0, 0.25, lum));
	vec3 c = col + T * rift * bg;
	// gamma-encoded with a dither against banding in the dark gradients
	vec3 g = pow(clamp(c, 0.0, 1.0), vec3(1.0 / 2.2));
	g += (h3(vec3(px * 1.37, seed + 7.0)) - 0.5) / 255.0;
	COLOR = vec4(g, clamp(T * rift, 0.0, 1.0));
}
"""


# ---------------------------------------------------------------- the per-frame sky shader

const SKY := """
shader_type sky;
uniform sampler2D neb_tex : filter_linear, repeat_enable;
uniform float has_neb = 0.0;
uniform float neb_gain = 1.0;
uniform float seed = 0.0;
uniform float star_k = 1.0;
uniform vec3 band_n = vec3(0.0, 1.0, 0.0);
uniform float band = 0.6;
uniform vec4 lamp[6];
uniform vec3 lamp_col[6];
uniform vec3 sun_dir = vec3(0.45, 0.7, 0.55);
uniform vec3 sun_col = vec3(1.0, 0.93, 0.82);
uniform float px = 0.0008;   // one screen pixel in radians (fov / height)
uniform mat3 turn = mat3(1.0); // the battle's small turn of the whole sky

float sh31(vec3 p) { p = fract(p * 0.1031); p += dot(p, p.zyx + 31.32); return fract((p.x + p.y) * p.z); }
vec3 sh33(vec3 p) { p = fract(p * vec3(0.1031, 0.103, 0.0973)); p += dot(p, p.yxz + 33.33); return fract((p.xxy + p.yxx) * p.zyx); }

vec3 temp_col(float h) {
	// blue-white to white to yellow to orange-red, most stars white to yellow
	vec3 a = vec3(0.68, 0.78, 1.0);
	vec3 b = vec3(1.0, 0.97, 0.92);
	vec3 c = vec3(1.0, 0.82, 0.58);
	vec3 e = vec3(1.0, 0.6, 0.42);
	return h < 0.25 ? mix(a, b, h / 0.25) : (h < 0.75 ? mix(b, c, (h - 0.25) / 0.5) : mix(c, e, (h - 0.75) / 0.25));
}

// one layer of stars: one candidate per cell of a 3D grid laid over the sphere; a star is kept if its hash clears thr
vec3 star_layer(vec3 d, float scale, float thr, float gain, float dens) {
	vec3 p = d * scale;
	vec3 base = floor(p - 0.5);
	vec3 acc = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		vec3 cell = base + vec3(float(i & 1), float((i >> 1) & 1), float((i >> 2) & 1));
		vec3 h = sh33(cell + seed);
		if (h.x < thr - dens) continue;
		vec3 sp = normalize(cell + 0.25 + h.zyx * 0.5);
		float ang = acos(clamp(dot(sp, d), -1.0, 1.0));
		float m = pow((h.x - (thr - dens)) / (1.0 - thr + dens), 3.0);
		float sig = px * (0.65 + 0.9 * m);
		acc += temp_col(sh31(cell * 1.7 + 3.0)) * exp(-ang * ang / (sig * sig)) * gain * (0.15 + 2.6 * m);
	}
	return acc;
}

void sky() {
	vec3 d = turn * EYEDIR;
	vec3 col = vec3(0.0);
	float T = 1.0;
	if (has_neb > 0.5) {
		vec2 uv = vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
		vec4 t = texture(neb_tex, uv);
		col = pow(t.rgb, vec3(2.2)) * neb_gain;
		T = t.a;
	}
	if (!AT_CUBEMAP_PASS) {
		float y = dot(d, band_n);
		float bd = exp(-pow(y / 0.25, 2.0)) * band;
		vec3 st = star_layer(d, 120.0, 0.955, 1.0, bd * 0.03) + star_layer(d, 300.0, 0.985, 0.55, bd * 0.012) + star_layer(d, 650.0, 0.994, 0.35, bd * 0.004);
		col += st * star_k * mix(0.15, 1.0, T);
		// the stars inside the gas, with halos
		for (int k = 0; k < 6; k++) {
			if (lamp[k].w <= 0.0) continue;
			float a = acos(clamp(dot(d, normalize(lamp[k].xyz)), -1.0, 1.0));
			col += lamp_col[k] * lamp[k].w * (exp(-a * a / (px * px * 2.2)) * 5.0 + exp(-a * a / 0.00006) * 0.25 + 0.0006 / (0.0004 + a * a) * 0.08);
		}
		// the sun the key light comes from
		float sa = acos(clamp(dot(EYEDIR, normalize(sun_dir)), -1.0, 1.0));
		col += sun_col * (smoothstep(0.012, 0.009, sa) * 30.0 + exp(-sa * sa / 0.0012) * 1.2 + 0.002 / (0.001 + sa * sa) * 0.12);
	}
	COLOR = col;
}
"""


# The sky's per-battle values beyond the bake: the lamps (embedded stars) and galaxies, from the setting's seed.
static func lamps(s: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(s["seed"]) * 3 + 1
	var out: Array = []
	var f: Vector3 = s["feature"]
	for k in 6:
		if k >= 2 + int(round(float(s["neb"]) * 4.0)):
			out.append(Vector4(0, 1, 0, 0))
			continue
		var d := (f + Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.35, 0.35), rng.randf_range(-0.5, 0.5))).normalized()
		out.append(Vector4(d.x, d.y, d.z, rng.randf_range(0.25, 0.9) * (1.3 if k == 0 else 1.0)))
	return out


static func galaxies(s: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(s["seed"]) * 5 + 2
	var out: Array = []
	var n := 2 + int(round((1.0 - float(s["neb"])) * 3.0))
	for k in 5:
		if k >= n:
			out.append(Vector4(0, 1, 0, 0))
			continue
		var d := Vector3(rng.randfn(), rng.randfn() - 0.6, rng.randfn()).normalized()
		out.append(Vector4(d.x, d.y, d.z, rng.randf_range(0.004, 0.012)))
	return out
