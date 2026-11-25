extends RefCounted
# F4 sky: the battle's setting (which region of space the sector is in, its palette, its planet) and the sky itself.
#
# The sky is two parts:
#   1. a nebula picture baked once per setting on the GPU (world_bake.gd): a ray-marched volume of glowing gas lit by a
#      few embedded stars, with dark dust lanes that also swallow the stars behind them, the galaxy's band with its dark
#      rift, and a few far galaxies. Stored as a linear half-float panorama (alpha = how much
#      starlight gets through), so the per-frame cost is one texture read.
#   2. the per-frame sky shader: the baked picture plus pinpoint stars from a sparse direction catalogue (colour by
#      temperature, denser along the galactic band, occluded by dust), and the sun where the key light comes from.
#
# Coherence (Ryan, Nov 1: maps vary fight to fight but stay coherent within a run): the setting comes from the sector's
# biome (one per sector, campaign.gd rollBiome by region) and the enemy faction, so every battle of a sector shares one
# sky and one planet; the battle's own seed only turns the view a little (a different spot in the same system).

const NOISE := preload("res://world/world_shaders.gd")
const BAKER := preload("res://world/world_bake.gd")

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
	"frontier": {"neb": 0.25, "cover": 0.28, "dust": 0.75, "band": 0.6, "stars": 1.0, "warm": 0.6, "rocks": 1.0, "tint": Vector3(0.75, 0.64, 0.55)},
	"nebula": {"neb": 0.42, "cover": 0.36, "dust": 0.6, "band": 0.54, "stars": 0.9, "warm": 0.2, "rocks": 0.8, "tint": Vector3(0.72, 0.85, 0.9)},
	"world": {"neb": 0.22, "cover": 0.24, "dust": 0.5, "band": 0.8, "stars": 1.0, "warm": 0.3, "rocks": 0.7, "tint": Vector3(0.7, 0.8, 1.0)},
	"boneyard": {"neb": 0.2, "cover": 0.28, "dust": 1.0, "band": 0.57, "stars": 0.8, "warm": 0.8, "rocks": 0.9, "tint": Vector3(0.85, 0.68, 0.6)},
	"deep": {"neb": 0.1, "cover": 0.2, "dust": 0.6, "band": 1.0, "stars": 0.65, "warm": 0.1, "rocks": 0.5, "tint": Vector3(0.6, 0.7, 0.85)},
	"deadstar": {"neb": 0.16, "cover": 0.24, "dust": 0.9, "band": 0.7, "stars": 0.75, "warm": 1.0, "rocks": 0.7, "tint": Vector3(1.0, 0.55, 0.35)},
}

# The system's planet per biome planet index (0..7, the game's eight backdrop looks): kind for the planet bake
# (0 gas giant, 1 ice giant, 2 terran, 3 desert and volcanic, 4 barren cratered, 5 ice world), palette, atmosphere,
# rings, how many moons.
const PLANETS := [
	{"kind": 0, "a": Vector3(0.78, 0.62, 0.42), "b": Vector3(0.42, 0.28, 0.17), "c": Vector3(0.95, 0.88, 0.74), "atmo": Vector3(0.95, 0.78, 0.55), "rings": true, "moons": 3},
	{"kind": 1, "a": Vector3(0.36, 0.55, 0.85), "b": Vector3(0.16, 0.3, 0.6), "c": Vector3(0.7, 0.85, 1.0), "atmo": Vector3(0.45, 0.7, 1.0), "rings": false, "moons": 2},
	# issue 1765: the old purple-lavender giant, re-paletted to dusty slate, umber-bronze belts and cream zones (RULEBOOK 10.9)
	{"kind": 0, "a": Vector3(0.56, 0.54, 0.5), "b": Vector3(0.3, 0.22, 0.15), "c": Vector3(0.88, 0.83, 0.71), "atmo": Vector3(0.72, 0.72, 0.7), "rings": false, "moons": 2},
	{"kind": 2, "a": Vector3(0.3, 0.36, 0.2), "b": Vector3(0.025, 0.07, 0.15), "c": Vector3(0.62, 0.55, 0.42), "atmo": Vector3(0.38, 0.62, 1.0), "rings": false, "moons": 1},
	# issue 1765: lifted into R420's band 2 (it sat at 0.027 on the day side; lifted again for the Wave 0 scorched fissures)
	{"kind": 3, "a": Vector3(0.76, 0.45, 0.26), "b": Vector3(0.46, 0.24, 0.15), "c": Vector3(0.88, 0.66, 0.46), "atmo": Vector3(1.0, 0.55, 0.32), "rings": false, "moons": 2},
	{"kind": 4, "a": Vector3(0.54, 0.51, 0.47), "b": Vector3(0.15, 0.14, 0.13), "c": Vector3(0.78, 0.75, 0.7), "atmo": Vector3(0.0, 0.0, 0.0), "rings": false, "moons": 0},
	{"kind": 5, "a": Vector3(0.86, 0.89, 0.92), "b": Vector3(0.46, 0.27, 0.16), "c": Vector3(0.42, 0.6, 0.8), "atmo": Vector3(0.55, 0.75, 1.0), "rings": false, "moons": 1},
	{"kind": 0, "a": Vector3(0.38, 0.66, 0.62), "b": Vector3(0.12, 0.3, 0.32), "c": Vector3(0.82, 0.95, 0.9), "atmo": Vector3(0.4, 0.95, 0.85), "rings": true, "moons": 2},
]

const FLOOK := preload("res://fx/faction_look.gd")


# Issue 1272 (R352): remixed planet looks, one per base look, picked per campaign sector so a run shows more than the three
# planets its biomes name. Same kinds, new palettes, remixed past recognition (RULEBOOK 10.3). Index i + 8 remixes PLANETS[i].
const PLANETS_ALT := [
	{"kind": 0, "a": Vector3(0.62, 0.66, 0.58), "b": Vector3(0.28, 0.3, 0.22), "c": Vector3(0.9, 0.92, 0.82), "atmo": Vector3(0.75, 0.88, 0.7), "rings": false, "moons": 2},
	{"kind": 1, "a": Vector3(0.3, 0.62, 0.66), "b": Vector3(0.12, 0.34, 0.4), "c": Vector3(0.75, 0.95, 0.95), "atmo": Vector3(0.45, 0.9, 0.95), "rings": true, "moons": 1},
	{"kind": 0, "a": Vector3(0.74, 0.5, 0.46), "b": Vector3(0.36, 0.18, 0.16), "c": Vector3(0.96, 0.84, 0.76), "atmo": Vector3(1.0, 0.7, 0.6), "rings": true, "moons": 3},
	{"kind": 2, "a": Vector3(0.42, 0.34, 0.22), "b": Vector3(0.05, 0.08, 0.12), "c": Vector3(0.82, 0.76, 0.66), "atmo": Vector3(0.5, 0.7, 0.95), "rings": false, "moons": 2},
	{"kind": 3, "a": Vector3(0.6, 0.54, 0.5), "b": Vector3(0.42, 0.31, 0.25), "c": Vector3(0.95, 0.42, 0.18), "atmo": Vector3(0.9, 0.42, 0.25), "rings": false, "moons": 1},
	{"kind": 4, "a": Vector3(0.52, 0.44, 0.36), "b": Vector3(0.22, 0.17, 0.13), "c": Vector3(0.7, 0.62, 0.52), "atmo": Vector3(0.0, 0.0, 0.0), "rings": true, "moons": 1},
	{"kind": 5, "a": Vector3(0.84, 0.85, 0.86), "b": Vector3(0.36, 0.4, 0.46), "c": Vector3(0.7, 0.86, 1.0), "atmo": Vector3(0.7, 0.8, 1.0), "rings": false, "moons": 0},
	{"kind": 0, "a": Vector3(0.66, 0.6, 0.38), "b": Vector3(0.3, 0.24, 0.12), "c": Vector3(0.95, 0.92, 0.7), "atmo": Vector3(0.9, 0.85, 0.5), "rings": false, "moons": 2},
]

# Issue 1272 (R352): each fight stop keeps the sector's sky and anchor planet but frames and colours it for the stop. One table.
#   rival: a fight against another faction than the sector's own: some of that faction's nebula colours seep into the sky.
#   boss: brighter, harder sky and the planet brought nearer. salvage: a fight on a wreck-field map: heavy dust, dimmer glow.
# The keys scale the setting's own values; "mix" blends c1/c3 toward the rival faction's nebula colours.
const STOP_MOOD := {
	"rival": {"mix": 0.45, "mix3": 0.4},
	"boss": {"neb": 1.6, "cover": 1.25, "c3": 1.3, "frame": 1.5},
	"salvage": {"dust": 2.6, "neb": 0.6, "band": 0.6},
}
# Per-stop framing of the anchor planet (seeded by the stop): how big it sits in the sky and how far round it turns.
const STOP_FRAMES := [{"scale": 1.0, "az": 0.0}, {"scale": 1.3, "az": -0.1}, {"scale": 0.8, "az": 0.22}, {"scale": 1.12, "az": 0.12}]


# Which mood a fight stop gets. stop: {kind, fac, sector_fac}; map_kind from world.gd map_kind (graveyard = wreck field).
static func stop_kind(stop: Dictionary, map_kind: String) -> String:
	if str(stop.get("kind", "")) == "boss": return "boss"
	var fac := str(stop.get("fac", ""))
	if fac != "" and str(stop.get("sector_fac", fac)) != fac: return "rival"
	if map_kind == "graveyard": return "salvage"
	return "plain"


# The sector setting for one stop: the same sky seed and anchor planet, with the stop's mood and framing laid on.
static func stop_mood(s0: Dictionary, stop: Dictionary, map_kind: String) -> Dictionary:
	var s := s0.duplicate(true)
	var mood := stop_kind(stop, map_kind)
	s["mood"] = mood
	# The sky picture stays the sector's own bake (its inputs are kept here); the mood rides on cheap sky uniforms, so a
	# mood stop loads like a plain one (1332 timing on the 5080: a rebake per mood cost 3.7 to 6.1 s).
	var bake := {}
	for k in ["c1", "c2", "c3", "neb", "cover", "dust", "band"]: bake[k] = s0[k]
	s["bake"] = bake
	var m: Dictionary = STOP_MOOD.get(mood, {})
	for k in ["neb", "cover", "dust", "band"]:
		if m.has(k): s[k] = float(s[k]) * float(m[k])
	s["cover"] = minf(float(s["cover"]), 1.0)
	if m.has("c3"): s["c3"] = (s["c3"] as Vector3) * float(m["c3"])
	if m.has("mix"):
		var rv: Array = FLOOK.of(str(stop["fac"])).get("nebula", FLOOK.of("voidsworn")["nebula"])
		s["c1"] = _gas_mix(s["c1"], (rv[1] as Vector3) * 1.3, float(m["mix"]))
		s["c3"] = _gas_mix(s["c3"], rv[2], float(m["mix3"]))
		var t: Vector3 = rv[1]
		s["mood_tint"] = t / maxf(t.length(), 0.001)
		s["mood_mix"] = float(m["mix"])
	# the baked gas brightness follows neb; dust darkens the gas and swallows more stars
	s["mood_gain"] = float(m.get("neb", 1.0))
	s["mood_dim"] = clampf((float(m.get("dust", 1.0)) - 1.0) * 0.25, 0.0, 0.6)
	var h := absi(hash(str(stop.get("node", "")) + "|" + str(stop.get("kind", ""))))
	var f: Dictionary = STOP_FRAMES[h % STOP_FRAMES.size()] if stop.has("node") else STOP_FRAMES[0]
	s["frame_scale"] = float(m.get("frame", f["scale"]))
	s["frame_az"] = float(f["az"])
	s["haze"] = _gas_mix(s["c1"], s["c2"], 0.5) * (0.05 + 0.06 * float(s["neb"]))
	return s


# A sector's anchor planet: the biome's look or its remix, picked by the sector's own map (stable across save and load).
static func planet_variant(s0: Dictionary, sector_key: String) -> Dictionary:
	var s := s0.duplicate(true)
	if absi(hash(sector_key)) % 2 == 1:
		var i := int(s["planet_i"]) % PLANETS_ALT.size()
		s["planet_base_i"] = int(s["planet_i"])
		s["planet_i"] = i + PLANETS.size()
		s["planet"] = PLANETS_ALT[i]
	return s


# The setting with the sector's own bake inputs (no stop mood): what the sky picture is baked from.
static func bake_view(s0: Dictionary) -> Dictionary:
	if not s0.has("bake"): return s0
	var s := s0.duplicate(true)
	for k in s0["bake"]: s[k] = s0["bake"][k]
	return s


# The sector's own base planet look (undoes planet_variant), for boards that keep today's look.
static func base_planet(s0: Dictionary) -> Dictionary:
	if not s0.has("planet_base_i"): return s0
	var s := s0.duplicate(true)
	s["planet_i"] = int(s["planet_base_i"])
	s["planet"] = PLANETS[s["planet_i"]]
	s.erase("planet_base_i")
	return s


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


# A warm and a cool gas meet through slate, not indigo or magenta.
const GAS_MIX := """
vec3 gas_hue(vec3 c) {
	c.g = max(c.g, min(c.r, c.b) + 0.10 * max(c.b - c.r, 0.0));
	return c;
}
vec3 gas_mix(vec3 a, vec3 b, float amount) {
	return gas_hue(mix(a, b, amount));
}
"""

static func _gas_mix(a: Vector3, b: Vector3, amount: float) -> Vector3:
	var c := a.lerp(b, amount)
	c.y = maxf(c.y, minf(c.x, c.z) + 0.10 * maxf(c.z - c.x, 0.0))
	return c


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
	# Keep the faction's gas colour, with a darker slate recess instead of a rotated hue.
	var c1 := _gas_mix(neb[1], (neb[1] as Vector3) * tint, 0.25)
	var c2 := _gas_mix(neb[0], Vector3(0.095, 0.12, 0.145), 0.5)
	var c3 := _gas_mix(neb[2], Vector3(0.85, 0.85, 0.85), 0.3)
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
		"band_n": Vector3(rng.randf_range(-0.4, 0.4), 1.0, rng.randf_range(-0.4, -0.22)).normalized(),
		# Put bright gas toward an upper corner, away from the default camera's 34-degree down angle.
		"feature": Vector3(rng.randf_range(0.55, 0.9) * (-1.0 if sseed % 2 == 0 else 1.0), 0.16, -0.8).normalized(),
	}
	var pi := int(biome.get("planet", sseed % 8)) if biome.has("planet") else sseed % 8
	s["planet_i"] = posmod(pi, PLANETS.size())
	s["planet"] = PLANETS[s["planet_i"]]
	# the haze far rocks fade into: the sky's own dim colour
	s["haze"] = _gas_mix(c1, c2, 0.5) * (0.05 + 0.06 * float(R["neb"]))
	return s


# ---------------------------------------------------------------- the bake shader (canvas_item, one strip at a time)

static func bake_code() -> String:
	return BAKE_HEAD + NOISE.NOISE + GAS_MIX + BAKE_BODY


const BAKE_HEAD := """
shader_type canvas_item;
render_mode unshaded, blend_disabled;
"""
const BAKE_BODY := """
uniform vec2 full_size = vec2(2048.0, 1024.0);
uniform float strip_y0 = 0.0;
uniform float strip_h = 1024.0;
uniform float seed = 0.0;
uniform vec3 c1 = vec3(0.18, 0.31, 0.39);
uniform vec3 c2 = vec3(0.095, 0.12, 0.145);
uniform vec3 c3 = vec3(1.0, 0.7, 0.5);
uniform float neb = 0.6;
uniform float cover = 0.5;
uniform float dust = 0.7;
uniform float band = 0.6;
uniform vec3 band_n = vec3(0.0, 1.0, 0.0);
uniform vec3 feature = vec3(0.65, 0.16, -0.8);
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
	float m = fbm3n(q * 0.55, 4) + 0.34 * smoothstep(0.35, 0.96, f) - 0.24 * (1.0 - cover);
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
	// y is signed (negative on one side of the band); GLSL leaves pow() undefined for a negative base, so square by hand
	float yc = y / 0.105;
	float yw = y / 0.25;
	float core = exp(-yc * yc);
	float wide = exp(-yw * yw);
	// the galactic centre is warmer and brighter on one side of the band
	vec3 cdir = normalize(cross(band_n, vec3(0.31, 0.0, 0.95)));
	float cen = 0.5 + 0.5 * dot(d, cdir);
	float clump = fbm3n(d * 9.0 + seed * 0.7, 5);
	float lum = (core * (0.4 + 0.9 * smoothstep(0.35, 0.75, clump)) + wide * 0.18) * (0.6 + 0.9 * cen * cen);
	vec3 rp = d * 10.0 + vec3(5.0, seed, 1.0);
	float rn = fbm3n(rp, 5);
	float yr = (y + (wvn3(rp * 0.55) - 0.5) * 0.13) / 0.055;
	float column = exp(-yr * yr) * (0.65 + 0.65 * smoothstep(0.29, 0.62, rn)) + core * smoothstep(0.42, 0.68, rn) * 0.4;
	rift = 1.0 - smoothstep(0.18, 0.8, column);
	vec3 col = mix(vec3(0.55, 0.62, 0.8), vec3(1.0, 0.82, 0.6), cen * cen);
	return col * lum * band * 0.078;
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
		c += vec3(0.95, 0.88, 0.8) * (exp(-r * r * 30.0) * 0.55 + exp(-r * 3.2) * arms * 0.35) * 0.025;
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
		vec3 ec = gas_mix(c2, c1, smoothstep(0.32, 0.68, hue));
		ec = gas_mix(ec, c3, smoothstep(0.62, 0.9, gas) * 0.35);
		vec3 em = (ec * lit + hot) * gas * neb;
		float sig = gas * 2.2 + dst * 9.0;
		float a = 1.0 - exp(-sig * dt * 3.0);
		// dust dims what it covers and reflects a little dull light itself
		col += T * (em * dt * 3.0 + mix(c2, vec3(0.05), 0.5) * dst * dt * 0.05);
		T *= 1.0 - a * mix(0.35, 1.0, clamp(dst * 3.0, 0.0, 1.0));
	}
	// V2 saves RGB in linear half-float. Compatibility's 8-bit raster path alone uses gamma and dither.
	col += T * rift * bg;
	col = gas_hue(col);
#ifdef SKY_COMPAT_8BIT
	col = pow(clamp(col, 0.0, 1.0), vec3(1.0 / 2.2));
	col += (h3(vec3(px * 1.37, seed + 7.0)) - h3(vec3(px * 1.13, seed + 13.0))) / 255.0;
#endif
	COLOR = vec4(col, clamp(T * rift, 0.0, 1.0));
}
"""


# ---------------------------------------------------------------- the per-frame sky shader

# Issue 1679, SG option. Broad, subdued lobes in linear light. The sun side is warmer and brighter than the back-bounce.
const FLEET_REFLECTIONS := """
uniform bool fleet_reflections = false;
// Issue 1777 (Ship Look V2): more lobes on top of the 1679 gradient, seen only by the reflection probe (cubemap pass):
// a tight warm sun lobe for a real specular highlight on metal plates, a cool bounce band low on the far side (the
// nebula and planet light), and dark-space troughs straight up and straight down so curved armor keeps deep contrast.
uniform bool fleet_reflections_v2 = false;

vec3 fleet_reflection_gradient(vec3 direction, vec3 sun_direction) {
	float sun_side = dot(direction, sun_direction);
	float warm = smoothstep(0.0, 1.0, sun_side);
	float cool = smoothstep(0.0, 1.0, -sun_side);
	vec3 c = vec3(0.12, 0.10, 0.075) * warm + vec3(0.025, 0.036, 0.05) * cool;
	if (fleet_reflections_v2) {
		float fr_lobe = pow(max(sun_side, 0.0), 24.0);   // neutral warm-white (Ryan, Nov 22: the orange lobe browned Eclipse)
		float fr_bd = (direction.y + 0.18) / 0.22;   // Artoo on PR 1786: square by multiplying (pow of a negative base is undefined)
		float fr_band = exp(-fr_bd * fr_bd) * (1.0 - smoothstep(-0.6, 0.2, sun_side));   // and smoothstep edges in order
		float fr_trough = smoothstep(0.55, 0.95, abs(direction.y));
		c = c * (1.0 - 0.75 * fr_trough) + vec3(0.86, 0.83, 0.78) * fr_lobe + vec3(0.045, 0.07, 0.11) * fr_band;
	}
	return c;
}
"""

const PANORAMA_SKY := """
shader_type sky;
uniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sun_dir;
""" + FLEET_REFLECTIONS + """
void sky() {
	vec3 c = texture(pano, SKY_COORDS).rgb;
	COLOR = min(c * 0.8, vec3(0.6));
	if (AT_CUBEMAP_PASS && fleet_reflections) {
		COLOR += fleet_reflection_gradient(EYEDIR, sun_dir);
	}
}
"""

# The angle of one pixel at 45 degrees vertical FOV and 1080 lines, shared by stars and dust.
# A fixed angle already covers twice as many pixels when the viewport height doubles.
const ANGULAR_PIXEL_1080 := "0.000727220521664304"

const STAR_FLOOR := "0.0"
const STAR_GRID := 64
const STAR_MAG_POWER := "4.5"
# A subpixel centre still lights adjacent pixels at 1080p, without making a wide halo.
const STAR_SIGMA_MIN := "0.74"
const STAR_SIGMA_MAX := "0.92"
const BAKE_SIZE := Vector2i(2048, 1024)
static var _star_image: Image


# Six cube faces in a 3x2 atlas. Each texel holds at most one star: XY jitter, magnitude, temperature.
# The atlas stores directions, not light. Analytic Gaussian pinpoints stay sharp as the view moves or scales.
static func star_direction(face: int, p: Vector2) -> Vector3:
	var side := 1.0 if face % 2 == 0 else -1.0
	if face < 2: return Vector3(side, p.x, p.y).normalized()
	if face < 4: return Vector3(p.x, side, p.y).normalized()
	return Vector3(p.x, p.y, side).normalized()


static func star_catalog() -> Texture2D:
	if _star_image == null: _star_image = star_catalog_image()
	# The bake service already shares textures and releases them before the renderer shuts down.
	return BAKER.texture(_star_image)


static func star_catalog_image() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1766
	var img := Image.create_empty(3 * STAR_GRID, 2 * STAR_GRID, false, Image.FORMAT_RGBA8)
	for face in 6:
		var offset := Vector2i(face % 3, face / 3) * STAR_GRID
		for y in STAR_GRID:
			for x in STAR_GRID:
				# Adjacent cells are sampled together. At a face edge there is no neighbour, so inset the star far
				# enough for its Gaussian to reach zero before crossing that edge, even at a corner.
				var j := Vector2(rng.randf_range(0.05, 0.95), rng.randf_range(0.05, 0.95))
				if x == 0: j.x = maxf(j.x, 0.22)
				if x == STAR_GRID - 1: j.x = minf(j.x, 0.78)
				if y == 0: j.y = maxf(j.y, 0.22)
				if y == STAR_GRID - 1: j.y = minf(j.y, 0.78)
				var p := (Vector2(x, y) + j) * (2.0 / STAR_GRID) - Vector2.ONE
				var s := star_direction(face, p)
				# Correct for the cube's solid angle, then pack faint stars into a band in catalogue space.
				var bd := s.y / 0.19
				var chance := (0.41 + 0.65 * exp(-bd * bd)) / pow(1.0 + p.length_squared(), 1.5)
				if rng.randf() >= chance: continue
				img.set_pixelv(offset + Vector2i(x, y), Color(j.x, j.y, rng.randf(), rng.randf()))
	return img


static func star_frame(s: Dictionary) -> Basis:
	var to_band := Basis(Quaternion(s["band_n"] as Vector3, Vector3.UP))
	return Basis(Vector3.UP, TAU * float(int(s["seed"]) % 997) / 997.0) * to_band


static func set_star_uniforms(m: ShaderMaterial, s: Dictionary) -> void:
	m.set_shader_parameter("star_catalog", star_catalog())
	m.set_shader_parameter("star_frame", star_frame(s))
	m.set_shader_parameter("star_k", float(s["stars"]))
	var sf := OS.get_environment("VS_STAR_FLOOR")
	m.set_shader_parameter("star_floor", float(sf) if sf != "" else float(STAR_FLOOR))


const SKY := """
shader_type sky;
uniform sampler2D neb_tex : filter_linear, repeat_enable;   // no mips: a sky has no smooth derivative at the longitude wrap
uniform float has_neb = 0.0;
uniform bool neb_gamma = false;    // only the 8-bit Compatibility raster fallback
uniform float neb_gain = 1.0;
uniform vec3 mood_tint = vec3(1.0);   // issue 1272: a stop's mood on the sector's baked gas (defaults change nothing)
uniform float mood_mix = 0.0;
uniform float mood_gain = 1.0;
uniform float mood_dim = 0.0;
uniform sampler2D star_catalog : filter_nearest, repeat_disable;
uniform mat3 star_frame = mat3(1.0);
uniform float star_k = 1.0;
uniform float star_floor = """ + STAR_FLOOR + """;   // dense molecular dust blocks all background stars
uniform vec3 sun_dir = vec3(0.45, 0.7, 0.55);
uniform vec3 sun_col = vec3(1.0, 0.93, 0.82);
uniform float px = """ + ANGULAR_PIXEL_1080 + """;   // 1080-line angular size; the sky shader has no VIEWPORT_SIZE
uniform mat3 turn = mat3(1.0); // the battle's small turn of the whole sky
// the dead-star board's painted sky (R2: its backdrop; A3's 8K dead-star panorama, with its dim red dead sun where the
// key light comes from), under the gas; and how bright this sky's own sun is (none on the dead-star board)
uniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float has_pano = 0.0;
uniform float sun_k = 1.0;
uniform float dawn = 0.0;
uniform vec3 dawn_dir = vec3(-0.6, 0.7, -0.2);
""" + FLEET_REFLECTIONS + GAS_MIX + """

vec3 temp_col(float h) {
	// blue-white to white to yellow to orange-red, most stars white to yellow
	vec3 a = vec3(0.68, 0.78, 1.0);
	vec3 b = vec3(1.0, 0.97, 0.92);
	vec3 c = vec3(1.0, 0.82, 0.58);
	vec3 e = vec3(1.0, 0.6, 0.42);
	return h < 0.25 ? mix(a, b, h / 0.25) : (h < 0.75 ? mix(b, c, (h - 0.25) / 0.5) : mix(c, e, (h - 0.75) / 0.25));
}

vec3 star_direction(int face, vec2 p) {
	float side = (face % 2 == 0) ? 1.0 : -1.0;
	if (face < 2) return normalize(vec3(side, p));
	if (face < 4) return normalize(vec3(p.x, side, p.y));
	return normalize(vec3(p, side));
}

vec3 stars(vec3 d) {
	vec3 a = abs(d);
	int face;
	vec2 p;
	if (a.x >= max(a.y, a.z)) { face = d.x >= 0.0 ? 0 : 1; p = d.yz / a.x; }
	else if (a.y >= a.z) { face = d.y >= 0.0 ? 2 : 3; p = d.xz / a.y; }
	else { face = d.z >= 0.0 ? 4 : 5; p = d.xy / a.z; }
	int n = textureSize(star_catalog, 0).x / 3;
	ivec2 offset = ivec2(face % 3, face / 3) * n;
	ivec2 base = ivec2(floor((p * 0.5 + 0.5) * float(n) - 0.5));
	vec3 acc = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		ivec2 cell = base + ivec2(i & 1, i >> 1);
		if (any(lessThan(cell, ivec2(0))) || any(greaterThanEqual(cell, ivec2(n)))) continue;
		vec4 s = texelFetch(star_catalog, offset + cell, 0);
		if (s.b <= 0.0) continue;
		vec3 sp = star_direction(face, (vec2(cell) + s.rg) * (2.0 / float(n)) - 1.0);
		float m = s.b;
		float sig = px * mix(""" + STAR_SIGMA_MIN + """, """ + STAR_SIGMA_MAX + """, m);
		vec3 delta = sp - d;
		float rsq = dot(delta, delta) / (sig * sig);
		if (rsq >= 7.5) continue;
		float lum = 0.36 * pow(m, """ + STAR_MAG_POWER + """) + 0.55 * pow(m, 24.0);
		acc += temp_col(s.a) * lum * exp(-rsq) * (1.0 - smoothstep(5.0, 7.5, rsq));
	}
	return acc;
}

void sky() {
	vec3 d = turn * EYEDIR;
	vec3 col = vec3(0.0);
	float T = 1.0;
	if (has_pano > 0.5) {
		// the painting as the old battle sky drew it (battle.gd: x0.8, capped), the gas over it
		// read from a blurred level: the painting's colour, clouds and dim dead sun, without its soft blobby stars (they
		// showed as speckle through the board on the PC; this sky's own stars are drawn per pixel below)
		col = min(textureLod(pano, SKY_COORDS, 4.5).rgb * 0.35, vec3(0.12));
	}
	if (has_neb > 0.5) {
		vec2 uv = vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
		vec4 t = texture(neb_tex, uv);
		vec3 g = (neb_gamma ? pow(t.rgb, vec3(2.2)) : t.rgb) * neb_gain * mood_gain;
		g = gas_mix(g, mood_tint * dot(g, vec3(0.3, 0.59, 0.11)) * 1.7, mood_mix) * (1.0 - mood_dim);
		// Soft shoulder for the sky alone, including boss and rival boosts. Never compete with the board.
		float peak = max(g.r, max(g.g, g.b));
		if (peak > 0.10) g *= (0.18 - 0.08 * exp(-(peak - 0.10) / 0.08)) / peak;
		col += g;
		T = t.a * (1.0 - mood_dim * 0.6);
	}
	if (!AT_CUBEMAP_PASS) {
		float through = mix(star_floor, 1.0, T);
		if (through > 0.0) col += stars(star_frame * d) * star_k * through * (1.0 - 0.6 * has_pano);
		// the sun the key light comes from
		float sa = acos(clamp(dot(EYEDIR, normalize(sun_dir)), -1.0, 1.0));
		col += sun_k * sun_col * ((1.0 - smoothstep(0.009, 0.012, sa)) * 30.0 + exp(-sa * sa / 0.0012) * 1.2 + 0.002 / (0.001 + sa * sa) * 0.12);
	}
	// A broad warm halo in the new sun's direction. Zero keeps every normal battle exactly as before.
	float catch_light = pow(max(0.0, 0.5 + 0.5 * dot(EYEDIR, normalize(dawn_dir))), 2.0);
	col = mix(col, col * vec3(1.18, 1.03, 0.84), dawn * 0.55);
	col += vec3(0.10, 0.047, 0.016) * catch_light * dawn;
	if (AT_CUBEMAP_PASS && fleet_reflections) {
		col += fleet_reflection_gradient(EYEDIR, normalize(sun_dir));
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
		out.append(Vector4(d.x, d.y, d.z, rng.randf_range(0.003, 0.007)))
	return out


static func bake_params(s: Dictionary, steps := 40) -> Dictionary:
	var bs := bake_view(s)
	return {"seed": float(int(bs["seed"]) % 997) * 0.37, "c1": bs["c1"], "c2": bs["c2"], "c3": bs["c3"],
		"neb": float(bs["neb"]), "cover": float(bs["cover"]), "dust": float(bs["dust"]), "band": float(bs["band"]),
		"band_n": bs["band_n"], "feature": bs["feature"], "steps": steps,
		"lamp": PackedVector4Array(lamps(bs)), "gal": PackedVector4Array(galaxies(bs))}
