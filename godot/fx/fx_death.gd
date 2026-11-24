extends RefCounted
# Ship deaths, drifting wrecks and the physics behind them, plus the shared hull decorations (scorch decals, breach
# holes, bent plates, venting plumes, debris bodies). Static functions; the state lives in fx.dstate.
#
# Four death beats: power loss, directional vent, staged cuts, drift and cooling.
# Mantaflow flipbooks replace fire volumes. Small hulls spin with a short hot trail before their pop; wings leave only a spark and puff.
# Triangle buckets and recessed boundary caps are prepared on a worker before death;
# the wrecks drift, tumble and cool. No worker wait blocks a death frame.

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SKEEP := preload("res://render/shader_keep.gd")   # issue 1434: one Shader per code for the session
const BEATS := preload("res://fx/fx_death_beats.gd")   # issue 1586: cause, faction, archetype and afterlife beats

const HULL_LAYER := 1
const DEBRIS_LAYER := 2
const HULL_GROUP := &"fx_hull_collider"   # the live hull colliders (add_collider); fx._gate_physics watches them (issue 1466)
const DEBRIS_CAP := 360
# Issue 1237 (Neon F7.1): a debris plate flies as before for DEBRIS_FREE_S, then takes DEBRIS_SETTLE_DAMP and slows to a
# stop, and Jolt puts it to sleep; anything still moving at DEBRIS_REST_S is stopped and put to sleep there. A sleeping
# plate stays where it came to rest and costs Jolt nothing until a hull knocks it. Plates no longer test each other
# (hull and wreck contacts only), and a wreck section leaves Jolt WRECK_PHYS_S after its release: it keeps its drift and turn
# on the effect clock, the way the kinematic tiers already drift. Seconds are effect-clock seconds.
const DEBRIS_FREE_S := 2.0
const DEBRIS_SETTLE_DAMP := 1.4
const DEBRIS_SETTLE_ADAMP := 1.2
const DEBRIS_REST_S := 5.5
const WRECK_PHYS_S := 4.0
const DEBRIS_WOKEN_S := 1.5   # a plate a wreck section knocks awake is at rest again this long after
const DEBRIS_VARIANTS := 4
const WRECK_COOL := 14.0

# Issue 462 (docs/playbooks/deaths_and_hits.md, "A death in three beats"): times are seconds from the killing blow.
# A cruiser: the tell to 1.38 (lights die, engines flare and go black, a tear opens from the hit side with three chain
# blasts walking along it), the break at 1.38, the core flash 0.28 later at the torn face, then ten secondaries on the
# two halves and cooling faces. A capital: the tell to 2.0 with five chain blasts and a shudder, three pieces, a bigger
# core, ten secondaries and 14 s of coals. Small hulls pop at 0.72 s and cool one chunk for six seconds (issue 463).
class DeathTimeline:
	var vent: float
	var cut: float
	var end: float
	var cuts: int
	var spacing: float
	var beats: Array
	var tier := ""
	var chain: Array = []     # chain blast times along the tear
	var tear_open := 0.3
	var tear_full := 0.0
	var core_delay := 0.0     # the core flash, after the break
	var secondaries := 0
	var sec_from := 0.0       # the secondaries' window, after the break
	var sec_to := 0.0
	var cool := 14.0          # how long the torn faces take to go dark
	func _init(big: bool, cut_count: int, tier_name := "", cause := "blast", organic := false) -> void:
		tier = tier_name
		cuts = cut_count if big else 1
		if not big:
			vent = 0.0
			cut = 0.72
			end = 0.96
			cool = 6.0
			spacing = 0.0
		elif tier == "capital":
			vent = 0.46
			cut = 2.0
			chain = [0.5, 0.85, 1.2, 1.55, 1.9]
			spacing = 0.30
			core_delay = 0.28
			secondaries = 10
			sec_from = 0.75
			sec_to = 4.2
			cool = 14.0
		else:
			vent = 0.46
			cut = 1.38
			chain = [0.5, 0.8, 1.1]
			spacing = 0.0
			core_delay = 0.28
			secondaries = 10
			sec_from = 0.72
			sec_to = 3.52
			cool = 8.6
		if big:
			end = cut + 0.67
			# A lance cut: the tear is the beam's straight line, drawn fast; its faces glow longest.
			tear_full = 0.62 if cause == "cut" else cut - 0.05
			if cause == "cut": cool *= 1.4
		beats = [{"name": "power_loss", "at": 0.0}, {"name": "vent", "at": vent}]
		for t in chain: beats.append({"name": "chain_blast", "at": t})
		beats.append({"name": "structural_break", "at": cut})
		if big:
			beats.append({"name": "core_flash", "at": cut + core_delay})
			beats.append({"name": "secondaries", "at": cut + sec_from})
		beats.append({"name": "drift_and_cool", "at": cut + (sec_from if big else 0.3)})
		if big and organic:
			# Issue 1238 (F5.1): a big Chorus hull keeps its class's length of death (cruiser 1.38 s, capital 2.0 s to the
			# rupture) but none of the metal beats: no vent, no chain blasts along a tear, no core fireball, no secondaries.
			# The slow-motion beat lands just after the skin bursts.
			chain = []
			secondaries = 0
			core_delay = 0.1
			beats = [{"name": "power_loss", "at": 0.0}, {"name": "rupture", "at": cut}, {"name": "core_flash", "at": cut + core_delay},
				{"name": "drift_and_cool", "at": cut + 0.6}]

const ATLAS_DIR := "res://fx/atlases/death/"
# One pixel at the staging camera (r 170, vertical FOV 45, 1080 lines). The floor holds distant events readable;
# the world extent lets them grow naturally as the player zooms in.
const STAGING_UNITS_PER_PIXEL := 2.0 * 170.0 * tan(PI / 8.0) / 1080.0
# The one scale table's death core flash (issue 710, R247; docs/playbooks/scale.md), pixels at the staging camera.
const CORE_FLASH_PX := {"small": 216.0, "destroyer": 255.0, "cruiser": 302.0, "capital": 423.0}

# Issue 354: where the visible gas starts inside the baked vent picture. Measured on today's pictures
# (godot/fx/atlases/death/{small,cruiser,capital}/vent_color.png): in frame 0 the gas runs down to row 0.90 of the crop,
# and the crop is rows 0.40 to 0.84 of the cell, so its lower edge (the root the gas vents from) sits 0.40 of the crop
# height from the picture centre. The directional flip puts that lower edge at the +up end of the quad, so a picture
# whose root is on the plating has its centre 0.40 of its height along the surface normal from that plating. The old
# fixed share of the ship's length (0.42 of 0.85 L) offset the picture centre, and the gas root was another 0.40 of the
# picture height further out, so the gas floated off the hull. P3-16 (issue 365) rebakes these pictures and must redo
# this number.
const VENT_ROOT_FRAC := 0.40

const SLAG := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, fog_disabled;
global uniform float fx_gain;
uniform float heat = 1.0;
uniform bool organic = false;
uniform float section_scale = 1.0;
uniform float face_glow = 0.0;
// R367 (issue 1399): the torn face's heat in the faction's death colours (defaults: today's metal, red to orange to white)
uniform vec3 heat_cool = vec3(0.38, 0.035, 0.018);
uniform vec3 heat_hot = vec3(0.95, 0.40, 0.09);
uniform vec3 heat_white = vec3(0.94, 0.84, 0.64);
varying vec3 slag_p;
varying vec2 slag_band;
void vertex() { slag_p = VERTEX; slag_band = COLOR.rg; }
float grain(vec3 p) { return fract(sin(dot(floor(p), vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
void fragment() {
	vec3 p = slag_p / max(section_scale, 0.001);
	float n = grain(p * 160.0);
	float coarse = 0.5 + 0.25 * sin(dot(p, vec3(38.7, 13.1, 26.3))) * sin(dot(p, vec3(12.3, 52.1, 24.7)));
	float band = clamp(slag_band.x, 0.0, 1.0);
	bool rib = band > 0.4 && band < 0.6;
	vec3 base = mix(vec3(0.045, 0.032, 0.026), vec3(0.014, 0.011, 0.012), band);
	if (rib) { base = vec3(0.068, 0.056, 0.048); }
	if (organic) {
		float fibre = pow(abs(sin(dot(p, vec3(41.0, 67.0, 29.0)) + coarse * 8.0)), 6.0);
		base = mix(vec3(0.025, 0.005, 0.013), vec3(0.085, 0.018, 0.031), coarse * 0.7 + fibre * 0.3);
		if (rib) { base = vec3(0.20, 0.15, 0.085) * (0.65 + coarse * 0.35); }
	}
	base *= 0.65 + coarse * 0.55 + n * 0.2;
	float rim = clamp(slag_band.y, 0.0, 1.0) * smoothstep(0.25, 0.75, n);
	float hot = clamp(heat, 0.0, 1.0);
	float temperature = hot * hot;
	vec3 metal = mix(heat_cool, heat_hot, smoothstep(0.2, 0.65, temperature));
	metal = mix(metal, heat_white, smoothstep(0.65, 1.0, temperature));
	// Issue 462: with face_glow on (a big hull's death) the torn face glows as it cools: white, orange, dull red, dark.
	// Issue 484 (the Board, Nov 11: a capital's middle piece showed a big flat tan grid face, a clean slab again): the face
	// is charred black and the heat sits in its cracks and seams, never as an even bright panel.
	float vein = pow(1.0 - abs(sin(dot(p, vec3(23.1, 9.7, 17.3)) + coarse * 7.0)), 10.0)
		+ pow(1.0 - abs(sin(dot(p, vec3(-7.9, 29.3, 11.1)) + n * 1.5)), 14.0) * 0.6;
	float face = face_glow * (rib ? 0.45 : vein * 1.4) * smoothstep(0.0, 0.08, temperature);
	ALBEDO = base + (organic ? vec3(0.0) : metal * (rim * 3.2 + face) * temperature * fx_gain);
}
"""

const DEBRIS_BODY := """
shader_type spatial;
render_mode cull_disabled, fog_disabled;
global uniform float scene_t;
global uniform float fx_gain;
instance uniform float spawn_t = -100.0;
instance uniform vec3 rim_col = vec3(1.0, 0.34, 0.05);   // R367: the torn rim in the faction's death colour
varying vec3 lp;
float eh(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float en(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(eh(i), eh(i + vec3(1.0, 0.0, 0.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 0.0)), eh(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(eh(i + vec3(0.0, 0.0, 1.0)), eh(i + vec3(1.0, 0.0, 1.0)), f.x), mix(eh(i + vec3(0.0, 1.0, 1.0)), eh(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
varying float rim;
void vertex() { lp = VERTEX; rim = COLOR.r; }
void fragment() {
	// torn plate: sooty bare metal with a little grain; only parts of its torn rim glow, briefly (r3 verdict: no ember
	// speckle over the whole face; r5: a rim glowing all the way round outlined every plate like a cartoon, and a
	// mirror-smooth face caught the sky, so the glow now breaks along the edge and the face is rough and sooty)
	float g = en(lp * 9.0);
	float soot = smoothstep(0.3, 0.7, en(lp * 3.0 + 7.0));
	ALBEDO = mix(vec3(0.11, 0.105, 0.1), vec3(0.025, 0.023, 0.021), soot) * (0.8 + 0.4 * g);
	METALLIC = mix(0.5, 0.2, soot);
	ROUGHNESS = mix(0.62, 0.92, soot);
	float warm = exp(-max(scene_t - spawn_t, 0.0) / 0.55);
	float seg = smoothstep(0.5, 0.7, en(lp * 5.0 + 3.0));
	float edge = smoothstep(0.85, 1.0, rim) * seg * (0.6 + 0.4 * g);
	EMISSION = rim_col * edge * warm * 1.3 * fx_gain;
}
"""


# ---------------------------------------------------------------- setup

static func setup_physics(fx) -> void:
	var st: Dictionary = fx.dstate
	st["bounce"] = PhysicsMaterial.new()
	(st["bounce"] as PhysicsMaterial).bounce = 0.4
	(st["bounce"] as PhysicsMaterial).friction = 0.4
	# issue 1434 (LOAD17: made again at every title backdrop): one Shader for the session
	var fresh: bool = not SKEEP.has(DEBRIS_BODY)
	var sh: Shader = SKEEP.of(DEBRIS_BODY)
	if fresh: HULL.note_late("death debris body")
	var m = ShaderMaterial.new()
	m.shader = sh
	st["debris_mat"] = m
	# Issue 462: the tear's shader is made here, at battle load, not on the first death frame (a 63 ms first death on
	# the fleet probe before this).
	st["tear_mat"] = fx.mat(SH.TEAR, 1)
	if fx.death_story:
		st["tear_strain_mat"] = fx.mat(SH.tear_strain_code(), 1, "", "death strain tear")
	st["debris_shapes"] = []
	st["debris_meshes"] = []
	var r = RandomNumberGenerator.new()
	r.seed = 77
	# three sizes, four torn shapes each (r5: three meshes in all made every plate the same hexagon)
	for sz in [0.45, 0.8, 1.2]:
		var shapes: Array = []
		var meshes: Array = []
		for v in DEBRIS_VARIANTS:
			var sm = shard_mesh(r, sz)
			shapes.append(safe_convex(sm[1]))
			meshes.append(sm[0])
		st["debris_shapes"].append(shapes)
		st["debris_meshes"].append(meshes)
	st["debris"] = []
	st["debris_next"] = 0
	st["wrecks"] = []
	st["anchors"] = {}
	st["physics_on"] = fx.quality != "low"


# ---------------------------------------------------------------- hull decorations

static func atlas_band(length: float) -> String:
	return "small" if length < 18.0 else ("cruiser" if length < 30.0 else "capital")


# Load once per FX session. No image decode or shader compilation on a death frame.
static func flipbook_material(fx, kind: String, band := "capital") -> ShaderMaterial:
	var rel := "death/" + band + "/" + kind + "_"
	if route_texture(fx, rel + "color.png") != null:
		return route_material(fx, SH.DEATH_FLIPBOOK, rel)
	var m: ShaderMaterial = fx.mat(SH.DEATH_FLIPBOOK, 2, "#define COMPAT\n" if fx.compat else "", "flipbook " + band + "/" + kind)
	for key in ["color", "flow", "thickness"]:
		var path: String = ATLAS_DIR + band + "/" + kind + "_" + key + ".png"
		var textures: Dictionary = fx.dstate.get("death_atlases", {})
		if not textures.has(path): textures[path] = load(path)
		fx.dstate["death_atlases"] = textures
		m.set_shader_parameter({"color": "atlas", "flow": "motion", "thickness": "thickness"}[key], textures[path])
	return m


# Production seeds load imported resources. The optional comparison folder loads external PNGs and returns null
# for missing kinds. Production callers never depend on VS_FX_ATLAS.
static func route_texture(fx, rel: String, seed_index := -1) -> Texture2D:
	if seed_index >= 0:
		var path := "res://fx/atlases/rebake/s%d/" % seed_index + rel
		var textures: Dictionary = fx.dstate.get("production_atlases", {})
		if not textures.has(path): textures[path] = load(path)
		fx.dstate["production_atlases"] = textures
		return textures[path]
	if String(fx.fx_atlas) == "":
		return null
	var path := String(fx.fx_atlas).path_join(rel)
	var cache: Dictionary = fx.dstate.get("route_atlases", {})
	if not cache.has(path):
		var img: Image = Image.load_from_file(path) if FileAccess.file_exists(path) else null
		cache[path] = ImageTexture.create_from_image(img) if img != null else null
		fx.dstate["route_atlases"] = cache
	return cache[path]


# Three maps with baked colour and heat. The meta tells callers to sample the whole cell and keep the shader define.
static func route_material(fx, code: String, rel: String, production := false, seed_index := -1) -> ShaderMaterial:
	var m: ShaderMaterial = fx.mat(code, 2, ("#define COMPAT\n" if fx.compat else "") + "#define ROUTE_BAKED\n", "route " + rel)
	if production and seed_index < 0: seed_index = fx.rng.randi_range(0, 2)
	for key in ["color", "flow", "thickness"]:
		m.set_shader_parameter({"color": "atlas", "flow": "motion", "thickness": "thickness"}[key], route_texture(fx, rel + key + ".png", seed_index))
	m.set_meta("route", true)
	return m


# ---------------------------------------------------------------- R367 (issue 1399): a faction's own death
# A faction's death style comes from faction_looks.json ("death"), the one file the ships, engines, shields and damage
# already take their colours from. A faction without one keeps today's shared orange fire. Colours are linear RGB.
static var _styles: Dictionary = {}   # not GPU: per-faction death colours and numbers only
# R398 (issue 1394, Ryan Nov 21, option B: "B but why is there smoke and haze?", then "No vapour. The whole hull shouldn't
# glow green either. Just specific affected areas"): a metal hull killed by acid or spines (rules killCause "melt") dies
# in the acid's colour whatever its faction: no tear, no strain crack, no faction break, the green only where the acid
# hit (MELT_GLOW), a soft pale bloom (never the hard white core), no fire, no smoke, no vapour. Chorus hulls keep their
# own rupture.
const MELT_STYLE := {"style": "melt", "fire": Color(0.80, 0.95, 0.55), "fire_mid": Color(0.45, 0.70, 0.12),
	"rim": Color(0.45, 0.62, 0.10), "spark": Color(0.55, 0.65, 0.12), "light": Color(0.70, 0.85, 0.45), "smoke": 0.0, "prism": 0.0}


# Ryan, Nov 22 2026 5:39 AM CT, on the 1394D sheets: "I like everything about it except I think it might still be good
# to have the faction specific explosion when it breaks off. Like the engines and weapons are cooking off." While a
# cook-off blast is drawn (_core_flash, _blast, _fac_pop) an acid kill reads its faction's own colours; the green glow,
# the green wreck heat and the missing smoke, haze and vapour stay.
static var _boom := 0


# A cook-off colour looked up outside a blast (Artoo on PR 1646: a secondary's light and sparks took the melt tint).
static func boom_col(src, key: String, fallback: Color) -> Color:
	_boom += 1
	var c := dcol(src, key, fallback)
	_boom -= 1
	return c


static func melting(src) -> bool:
	return src is Object and is_instance_valid(src) and src.has_meta("death_melt")

static func dstyle(src) -> Dictionary:
	if not (src is Object) or not is_instance_valid(src): return {}
	if src.has_meta("death_melt") and _boom == 0: return MELT_STYLE
	if not ("fac" in src) or not ("faction" in src) or not (src.fac is Dictionary): return {}
	var key := str(src.faction)
	if _styles.has(key): return _styles[key]
	var raw = (src.fac as Dictionary).get("death")
	var st := {}
	if raw is Dictionary:
		for k in raw:
			var v = raw[k]
			st[k] = Color(float(v[0]), float(v[1]), float(v[2])) if v is Array and (v as Array).size() >= 3 else v
	_styles[key] = st
	return st


# A colour of the dying ship's own death, or today's.
static func dcol(src, key: String, today: Color) -> Color:
	var v = dstyle(src).get(key)
	return v if v is Color else today


# The share of a death's smoke this faction keeps (1 today).
static func dsmoke(src) -> float:
	if melting(src): return 0.0   # R398: an acid kill has no smoke, even in its faction's cook-off blasts
	return float(dstyle(src).get("smoke", 1.0))


# The cap (slag) shader's heat colours from a death style: the rim colour hot, a darker cool and a whiter white.
static func _style_heat(m: ShaderMaterial, st: Dictionary, prefix: String) -> void:
	var rim = st.get("rim")
	if not (rim is Color): return
	m.set_shader_parameter(prefix + "cool", (rim as Color) * 0.32)
	m.set_shader_parameter(prefix + "hot", rim)
	m.set_shader_parameter(prefix + "white", (rim as Color).lerp(Color(1, 1, 1), 0.7))


# Every death picture is pooled: set (or reset) the faction's colours each time one is taken.
static func _style_pic(m: ShaderMaterial, src) -> void:
	var st := dstyle(src)
	var fire = st.get("fire")
	if fire is Color:
		m.set_shader_parameter("fac_fire", Color(fire.r, fire.g, fire.b, 1.0))
		m.set_shader_parameter("fac_mid", st.get("fire_mid", fire))
		m.set_shader_parameter("fac_prism", float(st.get("prism", 0.0)))
		m.set_shader_parameter("fac_smoke", float(st.get("smoke", 1.0)))
	else:
		m.set_shader_parameter("fac_fire", Color(1, 1, 1, 0))
		m.set_shader_parameter("fac_prism", 0.0)
		m.set_shader_parameter("fac_smoke", 1.0)


# `pool_tag` keeps a caller that changes the material's shader (the weapon bursts) in a pool of its own (issue 1237).
static func flipbook(fx, p: Vector3, n: Vector3, size: float, kind: String, life: float, velocity := Vector3.ZERO, strength := 1.0, band := "capital", src = null, root_on_surface := false, staged := false, frame = null, pool_tag := "") -> Node3D:
	var b: String = "small" if band == "destroyer" else band
	var key: String = ("fbs|" + b) if staged else ("fb|" + b + "|" + kind + "|" + pool_tag)
	# Issue 461 (carried from issue 484, Board comment on 507): the core flash always uses the lopsided baked seed
	# (s0), turned at random. Two of the three seeds are the round "flower" of equal puffs, which read as a ring of
	# identical puffs at about 2.3 s on a capital death ("a little too even and weird", Ryan, Nov 11).
	var make := (func() -> ShaderMaterial: return route_material(fx, SH.DEATH_FLIPBOOK, "death/" + b + "/flash_", true, 0)) if staged \
		else (func() -> ShaderMaterial: return flipbook_material(fx, kind, b))
	var mi: MeshInstance3D = fx.picture(key, make, "fx_baked_" + kind)
	mi.set_meta("fx_picture_kind", kind)
	mi.extra_cull_margin = size * 3.0 + velocity.length() * life
	var m := mi.material_override as ShaderMaterial
	if staged:
		m.set_shader_parameter("pic_spin", fx.rng.randf() * TAU)
		m.set_shader_parameter("size_divisor", 0.80)
		mi.extra_cull_margin = 100.0
	_style_pic(m, src)
	m.set_shader_parameter("born", fx.now)
	m.set_shader_parameter("lifetime", life)
	m.set_shader_parameter("extent", size)
	m.set_shader_parameter("intensity", strength)
	m.set_shader_parameter("plasma", 1.0 if kind == "flash" else 0.0)
	m.set_shader_parameter("directional", 1.0 if kind == "vent" else 0.0)
	# The simulation occupies only about a fifth of each baked cell. Sampling
	# its padded cell made a nominal 70-pixel core just 13 pixels wide.
	m.set_shader_parameter("atlas_rect", Vector4(0.36, 0.40, 0.28, 0.44) if kind == "vent" else Vector4(0.38, 0.38, 0.24, 0.24))
	if m.has_meta("route"):
		m.set_shader_parameter("atlas_rect", Vector4(0.0, 0.0, 1.0, 1.0))
	# A death vent is rooted on the real plating: the gas leaves the ship outward, so the picture is turned to put its
	# measured root on the hull and its plume along +n. Weapons keep the old tip-on-the-surface offset.
	var up: Vector3 = -n if (root_on_surface and kind == "vent") else n
	m.set_shader_parameter("tear_normal", up)
	m.set_shader_parameter("velocity", velocity)
	m.set_shader_parameter("min_pixels", 70.0 if kind == "flash" else 0.0)
	if root_on_surface and kind == "vent":
		mi.global_position = p + n * size * VENT_ROOT_FRAC
		mi.set_meta("gas_root", p)
	else:
		mi.global_position = p + (n * size * 0.42 if kind == "vent" else Vector3.ZERO)
		mi.set_meta("gas_root", mi.global_position)
	fx.later(fx.now + life + 0.1, fx.free_picture.bind(weakref(mi), int(mi.get_meta("pic_gen"))))
	# Every picture the death spawns is entered in the stray puff guard. The root is the point the gas leaves, not the
	# picture centre, so a floating picture cannot pass just because its frame happens to be near the hull.
	if frame is Transform3D: mi.set_meta("spawn_frame", frame)
	if src != null and frame is Transform3D:
		fx.record_spawn(src, mi.get_meta("gas_root"), false, frame)
	elif src != null:
		fx.record_spawn(src, mi.get_meta("gas_root"))
	return mi


# The thermal tear throws shared sparks off its normal. The GPU emitter below is only gas.
static func tear_particles(fx, p: Vector3, n: Vector3, L: float, inherited: Vector3, sparks_only := false, src = null) -> void:
	if fx.quality == "low":
		return
	var faction: String = src.faction if src != null else "voidsworn"
	# Separate seeded stream, so the visual scatter does not move subsequent death beats.
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector4(p.x, p.y, p.z, fx.now))
	var tangent := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var bitangent := n.cross(tangent)
	for j in (32 if fx.quality == "max" else 16):
		var ang := r.randf() * TAU
		var spread := r.randf_range(0.0, 0.38)
		var d := (n + (tangent * cos(ang) + bitangent * sin(ang)) * spread).normalized()
		fx.spark(p, fx.now + r.randf_range(0.0, 0.04), r.randf_range(0.36, 0.65), faction, 2.6, 0.045,
			L * 0.003, inherited + d * L * r.randf_range(0.36, 0.60), 0.6, 0.0, 0.0, fx.SparkRole.DEATH)
	if sparks_only or DisplayServer.get_name() == "headless":
		return
	var emitter := GPUParticles3D.new()
	emitter.name = "fx_vent_cone"
	emitter.amount = 12
	emitter.lifetime = 0.45
	emitter.one_shot = true
	emitter.explosiveness = 0.95
	emitter.local_coords = false
	emitter.visibility_aabb = AABB(Vector3.ONE * -L, Vector3.ONE * L * 2.0)
	var proc: ShaderMaterial = fx.mat(SH.DEATH_PARTICLES)
	proc.set_shader_parameter("axis", n)
	proc.set_shader_parameter("seed_value", fx.rng.randf() * 100.0)
	proc.set_shader_parameter("inherited", inherited)
	proc.set_shader_parameter("spread", 0.20)
	proc.set_shader_parameter("speed", L * 0.25)
	proc.set_shader_parameter("size", L * 0.009)
	proc.set_shader_parameter("tint", Color(0.53, 0.46, 0.64, 0.2 * clampf(dsmoke(src), 0.0, 1.0)))
	emitter.process_material = proc
	var styled := not dstyle(src).is_empty()
	var mesh_key: String = "death_cone_mesh" + ("_styled" if styled else "")
	if not fx.dstate.has(mesh_key):
		var mesh := QuadMesh.new(); mesh.size = Vector2.ONE
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.disable_fog = true   # issue 1558 item 3: a nebula never dulls a blast (effects.md section 1)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.vertex_color_use_as_albedo = true
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		if not fx.dstate.has("tear_falloff"):
			var gradient := Gradient.new()
			gradient.set_color(0, Color(0.95, 0.95, 0.95, 0.95))
			gradient.set_color(1, Color(0.95, 0.95, 0.95, 0.0))
			var texture := GradientTexture2D.new()
			texture.gradient = gradient
			texture.fill = GradientTexture2D.FILL_RADIAL
			texture.fill_from = Vector2(0.5, 0.5)
			texture.fill_to = Vector2(0.5, 1.0)
			fx.dstate["tear_falloff"] = texture
		mat.albedo_texture = fx.dstate["tear_falloff"]
		mat.albedo_color = Color(0.45, 0.45, 0.45, 0.3) if styled else Color(0.4, 0.34, 0.5, 0.3)
		mesh.material = mat
		fx.dstate[mesh_key] = mesh
	emitter.draw_pass_1 = fx.dstate[mesh_key]
	fx.add_child(emitter); emitter.global_position = p
	fx.later(fx.now + 0.9, fx.free_effect.bind(weakref(emitter)))


# ---------------------------------------------------------------- debris bodies (Jolt)

static func shard_mesh(rng: RandomNumberGenerator, size: float) -> Array:
	# a torn plate: a ragged outline (notches and teeth, stretched along one axis), creased once so it reads bent
	var n = rng.randi_range(9, 13)
	var ring_pts: Array = []
	var angs: Array = []
	for i in n:
		angs.append(TAU * (i + rng.randf_range(-0.35, 0.35)) / n)
	angs.sort()
	var stretch := rng.randf_range(1.2, 1.9)
	for i in angs.size():
		var a: float = angs[i]
		var r = size * rng.randf_range(0.3, 0.6) * (0.62 if (i % 3 == 1 and rng.randf() < 0.7) else 1.0)
		ring_pts.append(Vector2(cos(a) * r * stretch, sin(a) * r))
	var th = size * rng.randf_range(0.05, 0.1)
	var crease := rng.randf_range(-0.2, 0.25) * size
	var bend := rng.randf_range(0.3, 0.9) * (1.0 if rng.randf() < 0.5 else -1.0)
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts = PackedVector3Array()
	for side in [1.0, -1.0]:
		var y: float = th * 0.5 * side
		for i in n:
			var a2: Vector2 = ring_pts[i]
			var b2: Vector2 = ring_pts[(i + 1) % n]
			var tri = [Vector3(0, y, 0), Vector3(a2.x, y, a2.y), Vector3(b2.x, y, b2.y)]
			if side < 0.0:
				tri = [tri[0], tri[2], tri[1]]
			for k in 3:
				# vertex colour: 0 at the plate's middle, 1 on its torn rim (the debris shader glows only the rim)
				st.set_color(Color.BLACK if tri[k].x == 0.0 and tri[k].z == 0.0 else Color.WHITE)
				st.add_vertex(_fold(tri[k], crease, bend))
		for v in ring_pts:
			pts.append(_fold(Vector3(v.x, y, v.y), crease, bend))
	for i in n:
		var a3: Vector2 = ring_pts[i]
		var b3: Vector2 = ring_pts[(i + 1) % n]
		var q = [Vector3(a3.x, th * 0.5, a3.y), Vector3(b3.x, th * 0.5, b3.y), Vector3(b3.x, -th * 0.5, b3.y), Vector3(a3.x, -th * 0.5, a3.y)]
		for tri in [[q[0], q[2], q[1]], [q[0], q[3], q[2]]]:
			for v in tri:
				st.set_color(Color.WHITE)
				st.add_vertex(_fold(v, crease, bend))
	st.generate_normals()
	return [st.commit(), pts]


# Bend a plate along the line x = crease (the part past it lifts by `bend` per unit), as torn plating folds.
static func _fold(v: Vector3, crease: float, bend: float) -> Vector3:
	var d := v.x - crease
	if d <= 0.0:
		return v
	var c := cos(bend)
	var s := sin(bend)
	return Vector3(crease + d * c - v.y * s, d * s + v.y * c, v.z)


# `damp` (issue 1077's prototype): the plates slow and settle instead of drifting off for good; 0, the default, is today's
# constant drift. A pooled plate takes the damping of the death that last threw it.
static func spawn_debris(fx, pos: Vector3, vel: Vector3, count: int, size: float, damp := 0.0, piece := {}) -> void:
	var t0 := Time.get_ticks_usec()
	_spawn_debris_inner(fx, pos, vel, count, size, damp, piece)
	fx.pend("debris", t0)


static func _spawn_ship_debris(fx, s, pos: Vector3, vel: Vector3, count: int, size: float, damp: float) -> void:
	spawn_debris(fx, pos, vel, count, size, damp, _debris_spec(s))


static func _debris_spec(s) -> Dictionary:
	if not s.has_meta("death_debris"):
		s.set_meta("death_debris", {"leash": s.id, "dstyle": dstyle(s)})
	return s.get_meta("death_debris")


static func _debris_rim(piece: Dictionary) -> Color:
	var rim = piece.get("dstyle", {}).get("rim")
	return rim if rim is Color else Color(1.0, 0.34, 0.05)


static func _spawn_debris_inner(fx, pos: Vector3, vel: Vector3, count: int, size: float, damp: float, piece: Dictionary) -> void:
	var st: Dictionary = fx.dstate
	if not bool(st.get("physics_on", false)) or count <= 0:
		return
	var pool: Array = st["debris"]
	fx.wake_physics()
	var awake: Dictionary = st.get("debris_awake", {})
	st["debris_awake"] = awake
	var sc = 0 if size < 0.3 * fx.unit else (1 if size < 0.6 * fx.unit else 2)
	for i in count:
		var b: RigidBody3D
		if pool.size() < DEBRIS_CAP:
			b = RigidBody3D.new()
			b.gravity_scale = 0.0
			b.axis_lock_linear_y = true
			b.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			b.mass = 0.3 + 0.4 * sc
			b.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			b.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			b.angular_damp = 0.0
			b.linear_damp = 0.0
			b.can_sleep = true
			b.collision_layer = DEBRIS_LAYER
			b.collision_mask = HULL_LAYER   # issue 1237: plates never test each other (hulls and wreck sections still knock them)
			b.physics_material_override = st["bounce"]
			var vi: int = fx.rng.randi() % DEBRIS_VARIANTS
			var cs = CollisionShape3D.new()
			cs.name = "shape"
			cs.shape = st["debris_shapes"][sc][vi]
			b.add_child(cs)
			var mi = MeshInstance3D.new()
			mi.name = "mesh"
			mi.mesh = st["debris_meshes"][sc][vi]
			mi.material_override = st["debris_mat"]
			b.add_child(mi)
			b.set_meta("debris_sc", sc)
			fx.phys_root.add_child(b)
			pool.append(b)
		else:
			var slot := int(st["debris_next"])
			b = pool[slot]
			st["debris_next"] = (slot + 1) % DEBRIS_CAP
			# Issue 1237 (Neon F7.1): a recycled plate takes this throw's size (it kept the last one's, so a frigate
			# could throw a capital's plate).
			if int(b.get_meta("debris_sc", -1)) != sc:
				var vi: int = slot % DEBRIS_VARIANTS   # no random draw: the effect seed's sequence is unchanged
				(b.get_node("shape") as CollisionShape3D).shape = st["debris_shapes"][sc][vi]
				(b.get_node("mesh") as MeshInstance3D).mesh = st["debris_meshes"][sc][vi]
				b.mass = 0.3 + 0.4 * sc
				b.set_meta("debris_sc", sc)
		var d: Vector3 = fx.rdir()
		d.y = 0.0
		d = d.normalized()
		b.global_transform = Transform3D(Basis(d, fx.rng.randf() * TAU), pos + d * 0.3 * fx.unit)
		# issue 1466 (Astra pass 2, finding 2): thrown at the effect clock's speed, as wreck sections are (_release_section),
		# so the kill slow motion slows the plates too; _debris_speed follows later speed changes
		var spd: float = maxf(fx.anim_speed(), 0.01)
		b.set_meta("debris_spd", spd)   # the clock speed this plate's motion is at (_debris_speed)
		b.linear_velocity = (vel + d * (2.0 + fx.rng.randf() * 4.0) * fx.unit) * spd
		b.linear_velocity.y = 0.0
		b.angular_velocity = Vector3(fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6), fx.rng.randf_range(-6, 6)) * spd
		b.linear_damp = damp
		b.angular_damp = damp * 0.5
		# A reused plate takes this throw's leash and rim, even after the live hull is gone.
		b.set_meta("debris_piece", piece)
		b.remove_meta("leash_born")
		b.sleeping = false
		b.visible = true
		awake[b] = fx.now
		var mesh := b.get_node("mesh") as MeshInstance3D
		# Headless uses the dummy server even though the configured method still says forward_plus.
		if DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "dummy" and mesh.material_override != null:
			mesh.set_instance_shader_parameter("spawn_t", fx.now)
			mesh.set_instance_shader_parameter("rim_col", _debris_rim(piece))


# Issue 1237: the plates still flying. Past DEBRIS_FREE_S a plate takes the settle damping (or keeps a stronger one it was
# thrown with); once Jolt has put it to sleep it leaves the list, and at DEBRIS_REST_S it is stopped and put to sleep. A
# hull or wreck section that knocks a sleeping plate wakes it in Jolt; it is back at rest DEBRIS_WOKEN_S later.
static func _settle_debris(fx) -> void:
	var awake: Dictionary = fx.dstate.get("debris_awake", {})
	# A sleeping plate a wreck section knocks wakes in Jolt: four times a second the pool is looked over for those.
	if fx.now >= float(fx.dstate.get("debris_scan", -INF)):
		fx.dstate["debris_scan"] = fx.now + 0.25
		for b in fx.dstate.get("debris", []):
			if is_instance_valid(b) and not awake.has(b) and not (b as RigidBody3D).sleeping:
				awake[b] = fx.now - (DEBRIS_REST_S - DEBRIS_WOKEN_S)
				(b as Node).set_meta("debris_spd", maxf(fx.anim_speed(), 0.01))   # knocked at today's clock (_debris_speed)
		fx.dstate["debris_awake"] = awake
	if awake.is_empty(): return
	var done: Array = []
	for b in awake:
		if not is_instance_valid(b):
			done.append(b)
			continue
		var age: float = fx.now - float(awake[b])
		if age < DEBRIS_FREE_S: continue
		var rb := b as RigidBody3D
		if rb.linear_damp < DEBRIS_SETTLE_DAMP:
			rb.linear_damp = DEBRIS_SETTLE_DAMP
			rb.angular_damp = DEBRIS_SETTLE_ADAMP
		if age >= DEBRIS_REST_S:
			rb.linear_velocity = Vector3.ZERO
			rb.angular_velocity = Vector3.ZERO
			rb.sleeping = true
			done.append(b)
		elif rb.sleeping:
			done.append(b)
	for b in done: awake.erase(b)


# Issue 1466 (Astra pass 2, finding 2): a plate in flight keeps pace with the effect clock, as wreck sections do in update():
# when the clock slows for a kill (or eases back), its speed and spin change by the same ratio. Only the plates in flight.
# Each plate keeps the clock speed its motion is at (debris_spd), so one thrown on a speed-change step at the new speed
# is not scaled a second time (Artoo on PR 1476); a plate a hull knocked awake starts at the speed it was knocked at.
static func _debris_speed(fx) -> void:
	var speed: float = maxf(fx.anim_speed(), 0.01)
	# Most frames the clock holds still: every plate thrown or knocked since stored this same speed, so nothing to do
	# (PC run 3 on 1a8daa75: the per-plate pass every frame cost about 0.07 ms on the 20-kill fleet probe)
	var last: float = float(fx.dstate.get("debris_speed", -1.0))
	fx.dstate["debris_speed"] = speed
	if absf(speed - last) < 1e-6: return
	for b in fx.dstate.get("debris_awake", {}):
		if not is_instance_valid(b): continue
		var rb := b as RigidBody3D
		var was: float = float(rb.get_meta("debris_spd", speed))
		rb.set_meta("debris_spd", speed)
		if rb.sleeping or absf(speed - was) < 1e-6: continue
		rb.linear_velocity *= speed / was
		rb.angular_velocity *= speed / was


# The plates Jolt is still moving (the frame-time check's count; 0 once every plate has come to rest).
static func debris_awake(fx) -> int:
	var n := 0
	for b in fx.dstate.get("debris", []):
		if is_instance_valid(b) and not (b as RigidBody3D).sleeping: n += 1
	return n


# A convex collider Jolt can always build (G2 bot runs: a 900-point hull failed and logged an error). The point cloud is
# cleaned (no NaN or infinite points), cut down to the extreme points along 50 fixed directions (at most 50 points, the
# hull's shape kept), and checked for flat or tiny input; anything degenerate gets its (thickened) bounding box instead.
const _HULL_DIRS := 50
static var _dirs: PackedVector3Array = PackedVector3Array()


# F3 perf: each piece's centre and its collider points (at most _HULL_DIRS extreme points), worked out on the cut's
# worker thread; the break-up used to do this in GDScript on the main thread for every vertex of every piece.
static func _piece_hulls(pieces: Array, abort: CutAbort = null) -> void:
	for pc in pieces:
		if abort != null and abort.cancelled():
			return
		var pts: PackedVector3Array = pc["pts"]
		var cen := Vector3.ZERO
		for p in pts:
			cen += p
		cen /= maxf(pts.size(), 1)
		pc["cen"] = cen
		var hp := _extreme_points(pts)
		for i in hp.size():
			hp[i] -= cen
		pc["hull"] = hp
		var tr := Time.get_ticks_usec()
		pc["reach"] = _piece_reach(pc, abort)
		pc["reach_usec"] = Time.get_ticks_usec() - tr   # issue 1395: the worker's share, printed by fx/test/death_cost_check.gd


# Issue 1395 (Neon F9): the piece's reach for the leash (see _measure_reach), worked out here on the cut's worker from
# the very vertex arrays its mesh is built from, so the wreck's draw-in reads no faces on the main thread. The middle is
# the middle of the mesh's box (every surface and the cap), the reach the farthest vertex from it on the board plane.
static func _piece_reach(pc: Dictionary, abort: CutAbort = null) -> float:
	var lists: Array = []
	for sd in pc["surfs"]:
		var v = (sd["arrays"] as Array)[Mesh.ARRAY_VERTEX]
		if v is PackedVector3Array and not (v as PackedVector3Array).is_empty(): lists.append(v)
	if pc.has("cap"):
		var v = (pc["cap"] as Array)[Mesh.ARRAY_VERTEX]
		if v is PackedVector3Array and not (v as PackedVector3Array).is_empty(): lists.append(v)
	if lists.is_empty(): return -1.0
	var lo := Vector3.INF
	var hi := -Vector3.INF
	for verts: PackedVector3Array in lists:
		for i in verts.size():
			if (i & 1023) == 0 and abort != null and abort.cancelled(): return -1.0
			var v := verts[i]
			lo = lo.min(v)
			hi = hi.max(v)
	var mid := (lo + hi) * 0.5
	var far := 0.0
	for verts: PackedVector3Array in lists:
		for i in verts.size():
			if (i & 1023) == 0 and abort != null and abort.cancelled(): return -1.0
			var v := verts[i]
			far = maxf(far, (v.x - mid.x) * (v.x - mid.x) + (v.z - mid.z) * (v.z - mid.z))
	return sqrt(far)


static func _init_dirs() -> void:
	if not _dirs.is_empty():
		return
	# Fibonacci sphere: evenly spread directions
	var d := PackedVector3Array()
	for i in _HULL_DIRS:
		var y := 1.0 - 2.0 * (float(i) + 0.5) / _HULL_DIRS
		var rr := sqrt(maxf(0.0, 1.0 - y * y))
		var a := float(i) * 2.399963
		d.append(Vector3(cos(a) * rr, y, sin(a) * rr))
	_dirs = d


# The finite points of src that are extreme along any of the fixed directions (thread-safe once _init_dirs has run).
static func _extreme_points(src: PackedVector3Array) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for p in src:
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			pts.append(p)
	if pts.size() <= 4:
		return pts
	var keep := {}
	for d in _dirs:
		var bi := 0
		var bd := -INF
		for i in pts.size():
			var k := pts[i].dot(d)
			if k > bd:
				bd = k
				bi = i
		keep[bi] = true
	var out := PackedVector3Array()
	for i in keep:
		out.append(pts[i])
	return out


static func safe_convex(src: PackedVector3Array) -> Shape3D:
	_init_dirs()
	var out := _extreme_points(src)
	if out.is_empty():
		var b0 := BoxShape3D.new()
		b0.size = Vector3.ONE * 0.1
		return b0
	var lo := out[0]
	var hi := out[0]
	for p in out:
		lo = lo.min(p)
		hi = hi.max(p)
	var ext := hi - lo
	var size := maxf(ext.x, maxf(ext.y, ext.z))
	# degenerate (a point, a line or a flat sheet): a box from the bounds, never thinner than 2% of the largest side
	var flat := out.size() < 4 or size < 1e-4
	if not flat:
		var a0 := out[0]
		var a1 := a0
		for p in out:
			if p.distance_squared_to(a0) > a1.distance_squared_to(a0):
				a1 = p
		var ax := (a1 - a0).normalized()
		var a2 := a0
		var bd2 := 0.0
		for p in out:
			var w := p - a0
			var dl := (w - ax * w.dot(ax)).length_squared()
			if dl > bd2:
				bd2 = dl
				a2 = p
		var nrm := (a1 - a0).cross(a2 - a0)
		if nrm.length_squared() < 1e-12 or sqrt(bd2) < size * 0.01:
			flat = true
		else:
			nrm = nrm.normalized()
			var off := 0.0
			for p in out:
				off = maxf(off, absf((p - a0).dot(nrm)))
			flat = off < size * 0.01
	if flat:
		# the bounds as an eight-corner hull, so it sits where the points are (a BoxShape3D is centred on the origin)
		var t := (ext.max(Vector3.ONE * maxf(size * 0.02, 0.05)) - ext) * 0.5
		var l2 := lo - t
		var h2 := hi + t
		var bx := ConvexPolygonShape3D.new()
		bx.points = PackedVector3Array([Vector3(l2.x, l2.y, l2.z), Vector3(h2.x, l2.y, l2.z), Vector3(l2.x, h2.y, l2.z), Vector3(h2.x, h2.y, l2.z),
			Vector3(l2.x, l2.y, h2.z), Vector3(h2.x, l2.y, h2.z), Vector3(l2.x, h2.y, h2.z), Vector3(h2.x, h2.y, h2.z)])
		return bx
	var cs := ConvexPolygonShape3D.new()
	cs.points = out
	return cs


# One convex collider per live ship (from its visible hull samples) riding the root, so debris bounces off hulls.
static func add_collider(fx, s) -> void:
	if not bool(fx.dstate.get("physics_on", false)) or s.hull.sp.size() < 8:
		return
	var shape: Shape3D = safe_convex(s.hull.sp)
	var body = AnimatableBody3D.new()
	body.name = "fx_collider"
	body.sync_to_physics = false
	body.collision_layer = HULL_LAYER
	body.collision_mask = 0
	body.physics_material_override = fx.dstate["bounce"]
	var cs = CollisionShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	body.set_meta("fx_reach", body_reach(body))
	body.add_to_group(HULL_GROUP)   # issue 1466: fx._gate_physics wakes the space when this hull moves near debris
	s.root.add_child(body)
	s.set_meta("collider", body)


# How far a body's colliders reach from its origin (fx._gate_physics, issue 1466): the farthest hull point, else the box.
static func body_reach(body: Node) -> float:
	var r := 0.0
	for ch in body.get_children():
		var cs := ch as CollisionShape3D
		if cs == null or cs.shape == null: continue
		var k: float = cs.transform.basis.get_scale().x
		var o: float = cs.transform.origin.length()
		if cs.shape is ConvexPolygonShape3D:
			for v in (cs.shape as ConvexPolygonShape3D).points: r = maxf(r, o + v.length() * k)
		elif cs.shape is BoxShape3D:
			r = maxf(r, o + (cs.shape as BoxShape3D).size.length() * 0.5 * k)
		elif cs.shape is SphereShape3D:
			r = maxf(r, o + (cs.shape as SphereShape3D).radius * k)
		else:
			r = maxf(r, o + 1.0)
	return r


# ---------------------------------------------------------------- cutting the hull (worker thread)

# Seeds along the length (ship frame); cut: two pieces either side of a slanted plane.
static func seeds_for(s, cause: String, r: RandomNumberGenerator) -> PackedVector3Array:
	var h = s.hull
	var n = [1, 2, 3, 4, 5][clampi(s.weight, 0, 4)]
	if cause == "rupture":
		n = maxi(4, s.weight + 2)
	if cause == "big" or cause == "ram" or cause == "flay":   # a ram kill is the rules' "big" (Fable audit of PR 1666)
		n = mini(n + 1, 7)
	if cause == "melt" or cause == "dark":
		n = maxi(2, n - 1)
	if not s.death_big and s.faction != "chorus": n = clampi(n, 2, 4)
	var out = PackedVector3Array()
	if cause == "cut":
		var count: int = int(s.get_meta("death_cut_count", 2)) + 1
		var axis := Vector3(1.0, r.randf_range(-0.12, 0.12), r.randf_range(-0.15, 0.15))
		for i in count:
			out.append(h.c + axis * ((float(i) + 0.5) / count - 0.5) * h.L)
		return out
	for i in n:
		var u = (i + 0.5) / n + (r.randf() - 0.5) * 0.5 / n
		out.append(Vector3(h.box.position.x + u * h.L, h.c.y + (r.randf() - 0.5) * h.H * 0.6, h.c.z + (r.randf() - 0.5) * h.W * 0.6))
	return out


# ---------------------------------------------------------------- issue 484: blown apart, not sliced
# Owner, Nov 11: "the wreckage comes out looking too clean at the end. It's like straight lines and even halves." The
# old cut gave each triangle to its nearest seed, so a cruiser broke on one flat plane square to its length into two
# near-equal halves that would fit back together. The fracture plan below replaces that for big hulls:
# - uneven pieces: a cruiser parts about a third from one end, a capital into roughly a half, a third and a fifth, in a
#   per-ship order (seeded by the ship's id, so a replay breaks the same way);
# - no straight line: each break is tilted well off square (yaw and pitch), kinked into a V across the beam (two planes
#   meeting at an angle) and torn by a sum of waves (teeth about a twentieth of the length deep);
# - a bite: where the core goes off (on the break, on the side last hit), an ellipsoid of hull, its rim torn by waves,
#   is cut out as four to six separate fragments that the core flash throws out tumbling;
# - chips: a few small wedges along each break, thrown out with the bite.
# Everything is a plain function of a point, so the worker labels each triangle by its centre. On an older hull that is
# all (no triangle splitting: the raggedness comes from the waves and the hull's own triangles); on an authored hull
# (issue 600) the triangles across a tear are split along it first (_refine), and the tear follows the seams' paths.

# A few random plane waves: [direction * wave number, phase, amplitude]. Mostly across the hull (small x part), so the
# teeth run along the break.
static func _waves(r: RandomNumberGenerator, L: float, amp: float, count: int) -> Array:
	var out: Array = []
	var lam := L * 0.16
	var a := amp
	for i in count:
		var d := Vector3(r.randf_range(-0.35, 0.35), r.randf_range(-1.0, 1.0), r.randf_range(-1.0, 1.0)).normalized()
		out.append([d * (TAU / maxf(lam, 0.0001)), r.randf() * TAU, a])
		lam *= 0.5
		a *= 0.55
	return out


static func _wave_sum(waves: Array, q: Vector3) -> float:
	var v := 0.0
	for w in waves:
		v += sin((w[0] as Vector3).dot(q) + float(w[1])) * float(w[2])
	return v


# The signed distance (roughly) to one break: positive on its +x side.
static func _break_f(b: Dictionary, q: Vector3) -> float:
	if b.has("path"):
		# far from the path its waves (at most 0.022 of the length) cannot change the side: skip them
		if q.x < float(b["xmin"]) - float(b["near"]): return q.x - float(b["xmin"])
		if q.x > float(b["xmax"]) + float(b["near"]): return q.x - float(b["xmax"])
		# the waves tear the plating raggedly in side view near the flanks and in plan over the deck, and the insides with
		# it: the height only counts near the flanks (s near 1), so a deck tears where the plating above it tears
		var s := clampf(absf(q.z - float(b["cz"])) / float(b["hw"]), 0.0, 1.0)
		s *= s
		var qw := Vector3(q.x, float(b["cy"]) + (q.y - float(b["cy"])) * s * s, q.z)
		return _path_f(b, q) + _wave_sum(b["waves"], qw)
	var d: Vector3 = q - (b["at"] as Vector3)
	return d.dot(b["n"]) - float(b["k"]) * absf(d.dot(b["side"]) - float(b["zk"])) + _wave_sum(b["waves"], q)


# Issue 600 (R226, RULEBOOK 5.17): a seam's authored plan path, read from the export (its one home, R225). The path runs
# across the beam as (x, z) points from -z to +z and on past both ends at its end x; the sign comes from how many times a
# line from the point toward +x crosses it (even: the +x side), the size from the nearest crossing along x, or the
# nearest path segment when the point is close. Far from the path only the side matters, so it answers from its x range.
static func _path_f(b: Dictionary, q: Vector3) -> float:
	var near: float = b["near"]
	if q.x < float(b["xmin"]) - near: return q.x - float(b["xmin"])
	if q.x > float(b["xmax"]) + near: return q.x - float(b["xmax"])
	var pp: PackedVector2Array = b["path"]
	var n := pp.size()
	var crossings := 0
	var hx := INF
	# the two ends run on along z at their own x
	if q.z < pp[0].y:
		hx = absf(pp[0].x - q.x)
		if pp[0].x > q.x: crossings += 1
	if q.z >= pp[n - 1].y:
		hx = minf(hx, absf(pp[n - 1].x - q.x))
		if pp[n - 1].x > q.x: crossings += 1
	for i in n - 1:
		var a := pp[i]
		var c := pp[i + 1]
		if (a.y > q.z) == (c.y > q.z): continue
		var xi := a.x + (q.z - a.y) * (c.x - a.x) / (c.y - a.y)
		hx = minf(hx, absf(xi - q.x))
		if xi > q.x: crossings += 1
	var d := hx
	if d < near:
		var p2 := Vector2(q.x, q.z)
		if q.z < pp[0].y: d = minf(d, p2.distance_to(pp[0]))
		if q.z > pp[n - 1].y: d = minf(d, p2.distance_to(pp[n - 1]))
		for i in n - 1:
			d = minf(d, p2.distance_to(Geometry2D.get_closest_point_to_segment(p2, pp[i], pp[i + 1])))
	return -d if crossings % 2 == 1 else d


# The x of a seam at a point across the beam: on its path where it has one (the nearest crossing to `at`), else its plane.
static func _break_x(b: Dictionary, z: float) -> float:
	if not b.has("path"): return float((b["at"] as Vector3).x)
	var pp: PackedVector2Array = b["path"]
	if z <= pp[0].y: return pp[0].x
	if z >= pp[pp.size() - 1].y: return pp[pp.size() - 1].x
	var best := float((b["at"] as Vector3).x)
	var bd := INF
	for i in pp.size() - 1:
		var a := pp[i]
		var c := pp[i + 1]
		if (a.y > z) == (c.y > z): continue
		var xi := a.x + (z - a.y) * (c.x - a.x) / (c.y - a.y)
		if absf(xi - float((b["at"] as Vector3).x)) < bd:
			bd = absf(xi - float((b["at"] as Vector3).x))
			best = xi
	return best


# Issue 600 (R226): the machine (gun, turret ring, engine, claw, mast...) whose box from the export holds a point, or -1.
# Where boxes overlap, the one whose centre is nearest in its own size wins.
static func _machine_at(plan: Dictionary, q: Vector3) -> int:
	var mach: Dictionary = plan.get("mach", {})
	if mach.is_empty() or not (mach["all"] as AABB).has_point(q): return -1
	var bins: Array = mach["bins"]
	var bi := int(floor((q.x - float(mach["x0"])) / float(mach["bw"])))
	if bi < 0 or bi >= bins.size(): return -1
	var boxes: Array = mach["boxes"]
	var best := -1
	var bd := INF
	for k in (bins[bi] as PackedInt32Array):
		var bb: AABB = boxes[k]
		if not bb.has_point(q): continue
		var d := (q - bb.get_center()).abs() / (bb.size * 0.5).max(Vector3.ONE * 1e-6)
		var dn := maxf(d.x, maxf(d.y, d.z))
		if dn < bd:
			bd = dn
			best = k
	return best


# The piece a point goes to: a machine's own piece wherever its box holds the point (it never tears), else the plan.
static func _piece_at(plan: Dictionary, q: Vector3) -> int:
	var m := _machine_at(plan, q)
	if m >= 0: return int((plan["mach"]["piece"] as PackedInt32Array)[m])
	return _plan_assign(plan, q)


# The main piece a point belongs to (0 at the hull's low x end), ignoring the bite and the chips.
static func _plan_main(plan: Dictionary, q: Vector3) -> int:
	var i := 0
	for b in plan["breaks"]:
		if b.has("parent"): continue
		if _break_f(b, q) > 0.0: i += 1
	for b in plan["breaks"]:
		if b.has("parent") and i == int(b["parent"]) and _break_f(b, q) > 0.0: i = int(b["piece"])
	return i


# The piece a triangle centre belongs to: a bite fragment, a chip, or a main piece.
static func _plan_assign(plan: Dictionary, q: Vector3) -> int:
	var bite: Dictionary = plan["bite"]
	if not bite.is_empty():
		var d: Vector3 = q - (bite["c"] as Vector3)
		var e := Vector2(d.x / float(bite["rx"]), Vector2(d.y, d.z).length() / float(bite["ry"])).length_squared()
		if bite.has("drill"):
			# issue 600: on an authored hull the bite is a short shaft into the hull from the hit side, so the plating, its
			# liner and the decks under it go together (an ellipsoid took the plating and left the liner over the hole)
			var out: Vector3 = bite["out"]
			var tdep := d.dot(out)
			var dp := d - out * tdep
			e = Vector2(dp.x / float(bite["rx"]), Vector2(dp.y, dp.z).length() / float(bite["ry"])).length_squared()
			if tdep < -float(bite["drill"]): e = INF
			elif e < 1.35 and e + _wave_sum(bite["waves"], (bite["c"] as Vector3) + dp) < 1.0: e = -1.0   # walls along the shaft
			else: e = INF
		if e < 1.35 and e + _wave_sum(bite["waves"], q) < 1.0:   # the two waves add at most 0.34
			var subs: PackedVector3Array = bite["subs"]
			var best := 0
			var bd := INF
			for j in subs.size():
				var dd := q.distance_squared_to(subs[j])
				if dd < bd:
					bd = dd
					best = j
			return int(bite["first"]) + best
	var chips: Dictionary = plan["chips"]
	var breaks: Array = plan["breaks"]
	var main := 0
	for bi in breaks.size():
		var f := _break_f(breaks[bi], q)
		if f > 0.0 and not breaks[bi].has("parent"): main += 1
		if not chips.is_empty() and absf(f) < float(chips["band"]):
			var seeds: PackedVector3Array = chips["seeds"]
			var best := -1
			var bd := INF
			for j in range(bi * int(chips["per"]), (bi + 1) * int(chips["per"])):
				var dd := q.distance_squared_to(seeds[j])
				if dd < bd:
					bd = dd
					best = j
			if best >= 0 and bd < float(chips["reach"]) * float(chips["reach"]): return int(chips["first"]) + best
	if bool(plan.get("authored", false)):
		for b in breaks:
			if b.has("parent") and main == int(b["parent"]) and _break_f(b, q) > 0.0: main = int(b["piece"])
	return main


static func fracture_plan(fx, s, r: RandomNumberGenerator) -> Dictionary:
	var h = s.hull
	var L: float = h.L
	var W: float = maxf(h.W, L * 0.06)
	var H: float = maxf(h.H, L * 0.04)
	var x0: float = h.box.position.x
	var capital: bool = s.death_tier == "capital" or int(s.get_meta("death_cut_count", 1)) >= 2
	# 1. uneven pieces, in order along x
	var sizes: Array = []
	# issue 1077 (prototype): Ryan on pass 5, one crack: a strained death breaks once, so a capital splits in two like a cruiser
	var story: bool = fx != null and "death_story" in fx and fx.death_story
	if capital and not story:
		sizes = [0.50 + r.randf_range(-0.02, 0.02), 0.30 + r.randf_range(-0.02, 0.02)]
		sizes.append(1.0 - float(sizes[0]) - float(sizes[1]))
		for i in range(sizes.size() - 1, 0, -1):
			var j := r.randi_range(0, i)
			var t = sizes[i]
			sizes[i] = sizes[j]
			sizes[j] = t
	else:
		var small := r.randf_range(0.31, 0.37)
		sizes = [small, 1.0 - small] if r.randf() < 0.5 else [1.0 - small, small]
	var seam_data = h.get("seams")
	var authored: Array = seam_data if seam_data is Array else []
	var transverse: Array = authored.filter(func(b): return not b.has("span"))
	transverse.sort_custom(func(a, b): return a["at"].x < b["at"].x)
	# Issue 461 (carried from 484): a lance kill cuts clean on the beam's own line (deaths_and_hits.md, "What killed it":
	# the tear is the cut, two clean halves). The beam's point and direction (hull space) are set by _lance_recut on the
	# death frame; the break nearest the beam lies on it, square-ish to the beam, with no kink and almost no teeth.
	var lance = s.get_meta("lance_line", [])
	var lance_on: bool = lance is Array and lance.size() >= 2
	var primary_b := 0
	var breakup_ok := false
	# only a big metal hull breaks up (audit: a small hull's pop and a Chorus rupture keep one crack); a lance cuts in two
	var big_metal: bool = story and not lance_on and s.death_big and s.faction != "chorus"
	if story and (transverse.size() > 1 or big_metal):
		# one crack: on a lance kill, the joint nearest the beam (issue 1385: the recut then picks the crack, rather than
		# being thrown away). Issue 1236 round 4 (Ryan, Nov 23: "every ship is breaking at the same spot"): otherwise the
		# joint nearest where the hull was last hit, or a per-ship pick when it has not been hit, no longer always the
		# joint nearest the core.
		var near: Vector3 = lance[0] if lance_on else _crack_near(s, x0, L, r, h.c.z)
		if big_metal:
			# and a second joint, so the wreck can break in three (Ryan's "break up a bit more into 3 pieces"). Whether it
			# parts at the death, a beat later or never is the death's breakup (_pick_breakup).
			var pick: Array = _breakup_joints(s, transverse, near, x0, L)
			if not pick.is_empty():
				transverse = [pick[0], pick[1]]
				primary_b = transverse.find(pick[2])
				breakup_ok = true
		if not breakup_ok and transverse.size() > 1:
			var keep = transverse[0]
			for t in transverse:
				if _joint_gap(t, near) < _joint_gap(keep, near): keep = t
			transverse = [keep]
			primary_b = 0
	if not transverse.is_empty():
		sizes.clear()
		var prev := x0
		for b in transverse:
			sizes.append((float(b["at"].x) - prev) / L)
			prev = b["at"].x
		sizes.append((x0 + L - prev) / L)
	# the side that was hit (the bite and the scorch sit there); with no recent hit, a per-ship side
	var zs := 1.0 if r.randf() < 0.5 else -1.0
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 6.0:
		var lz: float = ((last[0] as Vector3) - h.c).z
		if absf(lz) > W * 0.05: zs = signf(lz)
	var lance_b := -1
	if lance_on:
		var lx: float = ((lance[0] as Vector3).x - x0) / L
		if not transverse.is_empty():
			# issue 1385 (Neon, PR 1383 F5): an authored hull breaks only on its joints (RULEBOOK 5.17: a machine never
			# crosses a seam), so the beam picks the joint nearest it and the tear there runs clean: the seam's own plane
			# and path, with the lance's fine teeth. The pieces keep the joints' sizes.
			var bd := INF
			for i in transverse.size():
				var tx: float = (float(transverse[i]["at"].x) - x0) / L
				if absf(tx - lx) < bd:
					bd = absf(tx - lx)
					lance_b = i
		elif sizes.size() == 2:
			var lu := clampf(lx, 0.3, 0.7)
			sizes = [lu, 1.0 - lu]
			lance_b = 0
		else:
			var acc := 0.0
			var bd := INF
			for i in sizes.size() - 1:
				acc += float(sizes[i])
				if absf(acc - lx) < bd:
					bd = absf(acc - lx)
					lance_b = i
	# 2. the breaks: tilted, kinked, torn
	var breaks: Array = []
	var u := 0.0
	var seeds := PackedVector3Array()
	for i in sizes.size():
		seeds.append(Vector3(x0 + (u + float(sizes[i]) * 0.5) * L, h.c.y, h.c.z))
		u += float(sizes[i])
		if i == sizes.size() - 1: break
		var room: float = 0.45 * minf(float(sizes[i]), float(sizes[i + 1])) * L
		var yaw := deg_to_rad(r.randf_range(20.0, 34.0)) * (1.0 if r.randf() < 0.5 else -1.0)
		var pitch := deg_to_rad(r.randf_range(10.0, 22.0)) * (1.0 if r.randf() < 0.5 else -1.0)
		var k := r.randf_range(0.45, 0.8) * (1.0 if r.randf() < 0.5 else -1.0)
		var amp := L * 0.03
		if i == lance_b:
			# the plane holds the beam's line: its normal is across the beam, kept within 34 degrees of square to the hull
			var pn: Vector3 = (lance[1] as Vector3).cross(Vector3.UP)
			pn = pn.normalized() if pn.length() > 0.05 else Vector3.RIGHT
			if pn.x < 0.0: pn = -pn
			yaw = clampf(atan2(pn.z, pn.x), -deg_to_rad(34.0), deg_to_rad(34.0))
			pitch = 0.0
			k = 0.0
			amp = L * 0.004
		# keep each break inside its two pieces: the tilt, the kink and the teeth together reach at most `room`
		var reach: float = absf(tan(yaw)) * W * 0.5 + absf(tan(pitch)) * H * 0.5 + absf(k) * W * 0.5 + amp * 1.6
		var fit := minf(1.0, room / maxf(reach, 0.0001))
		yaw = atan(tan(yaw) * fit)
		pitch = atan(tan(pitch) * fit)
		k *= fit
		amp *= maxf(fit, 0.5)
		var n := Vector3(cos(yaw), 0.0, sin(yaw)).rotated(Vector3(-sin(yaw), 0.0, cos(yaw)), pitch).normalized()
		var side := Vector3(-n.z, 0.0, n.x).normalized()
		var zk := r.randf_range(-0.25, 0.25) * W
		# the V kink moves the break's mean line along the hull by k times the mean distance from its crease; move the
		# break back by that much so the pieces keep their planned sizes
		var mean_off := k * (W * 0.25 + zk * zk / W) / maxf(n.x, 0.2)
		breaks.append({"at": Vector3(x0 + u * L - mean_off, h.c.y, h.c.z), "n": n, "side": side,
			"zk": zk, "k": k, "waves": _waves(r, L, amp, 3)})
		if not transverse.is_empty():
			# Authored joints are weaknesses, with an irregular tear close to the authored plane. An added joint
			# (_breakup_joints) is a plain plane turned a little, kept clear of the machines by its own margin.
			breaks[-1]["at"] = transverse[i]["at"]
			breaks[-1]["n"] = transverse[i]["n"]
			breaks[-1]["k"] = k * 0.25
			breaks[-1]["waves"] = _waves(r, L, L * (0.004 if i == lance_b else 0.012), 3)
			if transverse[i].has("path"):
				# issue 600 (R226): the tear follows the seam's authored plan path (it kinks round the machines), torn by the
				# waves; the path is the kink, so no extra V
				var pp: PackedVector2Array = transverse[i]["path"]
				var xs := pp[0].x
				var xl := pp[0].x
				for q in pp:
					xs = minf(xs, q.x)
					xl = maxf(xl, q.x)
				breaks[-1]["path"] = pp
				breaks[-1]["xmin"] = xs
				breaks[-1]["xmax"] = xl
				breaks[-1]["near"] = L * 0.06
				breaks[-1]["cy"] = h.c.y
				breaks[-1]["cz"] = h.c.z
				breaks[-1]["hw"] = maxf(maxf(absf(pp[0].y - h.c.z), absf(pp[pp.size() - 1].y - h.c.z)), W * 0.1)
				breaks[-1]["k"] = 0.0
				breaks[-1]["at"] = Vector3(_break_x(breaks[-1], h.c.z), h.c.y, h.c.z)
	for b in authored:
		if not b.has("span"): continue
		# one crack (issue 1077): a strained death keeps no lengthwise joint either. A lengthwise break's plane splits its
		# whole parent piece, and once a crosswise joint is dropped that parent runs past the joint's own span, so the plane
		# would cut plating and insides where no joint was built (S8 and S9: insides outside their piece's hull)
		if story: continue
		var parent := 0
		var mid: float = (float(b["span"][0]) + float(b["span"][1])) * 0.5
		for t in transverse:
			if mid > float(t["at"].x): parent += 1
		var piece := seeds.size()
		var normal: Vector3 = b["n"]
		var at: Vector3 = b["at"]
		at.x = mid
		seeds[parent] = seeds[parent] - normal * H * 0.2
		seeds.append(Vector3(mid, h.c.y, h.c.z) + normal * H * 0.2)
		sizes.append(float(sizes[parent]) * 0.5)
		breaks.append({"at": at, "n": normal, "side": Vector3.FORWARD, "zk": 0.0, "k": 0.08,
			"waves": _waves(r, L, L * 0.008, 3), "parent": parent, "piece": piece})
	# 3. the bite: on the core's break (a capital: the break beside its biggest piece), on the side that was hit
	var bi := 0
	if breakup_ok:
		bi = mini(primary_b, breaks.size() - 1)   # issue 1236 round 4: the core goes off on the first crack
	elif breaks.size() > 1 and authored.is_empty():
		bi = 0 if float(sizes[0]) + float(sizes[1]) >= float(sizes[1]) + float(sizes[2]) else 1
	elif story and not authored.is_empty():
		bi = mini(primary_b, breaks.size() - 1)   # issue 1236 round 4: the core goes off on the first crack
	var rx: float = L * (0.09 if capital else 0.12) * (0.6 if lance_on else 1.0)
	# centred a little into the bigger of the two pieces, so the bite eats mostly into it and the small one stays small
	var bat: Vector3 = (breaks[bi]["at"] as Vector3) + Vector3.RIGHT * rx * 0.5 * (-1.0 if float(sizes[bi]) > float(sizes[bi + 1]) else 1.0)
	bat.x += _break_x(breaks[bi], h.c.z + zs * W * 0.4) - float((breaks[bi]["at"] as Vector3).x)   # on the path's hit side
	var out_dir := Vector3(0.0, 0.3, zs).normalized()
	# the bite's centre is a real hull sample: the one furthest out to the hit side near the break (bench round 3: a ray
	# toward the hull could hit a mast tip with no plating round it, and the core flash then floated off the hull)
	var bc: Vector3 = bat + Vector3(0.0, H * 0.3, zs * W * 0.4)
	var best := -INF
	for i in h.sp.size():
		var q: Vector3 = h.sp[i]
		if absf(q.x - bat.x) > rx * 0.6: continue
		var score: float = (q - bat).dot(out_dir) - absf(q.x - bat.x) * 0.5
		if score > best:
			best = score
			bc = q
	if best == -INF:
		var hit: Dictionary = h.ray(bat + out_dir * L * 2.0, -out_dir)
		bc = hit.get("p", bc)
	var ry: float = maxf(W, H) * (0.48 if capital else 0.55)
	var subs := PackedVector3Array()
	# R367 (issue 1399): a Glasswright shatters: whole panes shear off, so the bite and the breaks give more, smaller pieces
	var shatter: bool = str(dstyle(s).get("style", "")) == "shatter"
	var nsub := (9 if capital else 7) if shatter else (6 if capital else 4)
	for j in nsub:
		var a := TAU * (float(j) + r.randf_range(-0.3, 0.3)) / float(nsub)
		subs.append(bc + Vector3(cos(a) * rx * 0.6, 0.0, 0.0) + (Vector3(0.0, sin(a), 0.0) - out_dir * r.randf_range(0.1, 0.6)) * ry * 0.6)
	var n_main := sizes.size()
	# a torn rim, but one bite: two long waves (round 1's three waves holed a capital's deck like lace)
	var bite := {"c": bc, "rx": rx, "ry": ry, "waves": _waves(r, L, 0.22, 2), "subs": subs, "first": n_main,
		"out": out_dir}
	if not authored.is_empty(): bite["drill"] = ry * 0.8
	# 4. chips along each break
	var per := 4 if shatter else 2
	var chip_seeds := PackedVector3Array()
	for b in breaks:
		for j in per:
			var cs: Vector3 = (b["at"] as Vector3) + (b["side"] as Vector3) * W * r.randf_range(-0.5, 0.5) * (-zs if j == 0 else zs) + Vector3.UP * H * r.randf_range(-0.4, 0.4)
			if b.has("path"): cs.x = _break_x(b, cs.z)
			chip_seeds.append(cs)
	var chips := {"seeds": chip_seeds, "per": per, "band": L * 0.03, "reach": minf(maxf(W, H) * 0.25, L * 0.05), "first": n_main + nsub}
	# 5. scorch on the plating round the wound: the bite and both sides of each break, fading over about a hull width
	var scorch: Array = [Vector4(bc.x, bc.y, bc.z, rx + minf(W, L * 0.12) * 0.6)]
	for b in breaks:
		for side in [-1.0, 1.0]:
			var p: Vector3 = (b["at"] as Vector3) + (b["side"] as Vector3) * W * 0.3 * side + Vector3.UP * H * 0.2
			if b.has("path"): p.x = _break_x(b, p.z)
			scorch.append(Vector4(p.x, p.y, p.z, minf(W, L * 0.12) * 0.5))
	var n_frag: int = nsub + chip_seeds.size()
	if not s.death_big or s.faction == "chorus":
		# issue 1385 (Neon, PR 1383 F2, F3): only a big metal hull throws the bite and the chips (_make_frags and
		# _throw_frags at its core flash). An authored small hull (its pop) or an authored Chorus hull (its rupture) never
		# throws them, so carving them left a hole in the wreck: their hull stays on the main pieces instead.
		bite = {}
		chips = {}
		n_frag = 0
	var plan := {"L": L, "seeds": seeds, "sizes": sizes, "breaks": breaks, "bite": bite, "chips": chips, "n_main": n_main,
		"n_frag": n_frag, "bite_break": bi, "scorch": scorch, "authored": not authored.is_empty(),
		"breakup": breakup_ok}
	# 6. issue 600 (R226, RULEBOOK 5.17): the machines ride whole, each with the main piece its box centre lies in. Their boxes
	# come from the export (fx_hull machines); bins along the length keep the lookup short.
	var mlist: Array = h.get("machines") if h.get("machines") is Array else []
	if not mlist.is_empty():
		var boxes: Array = []
		var mpiece := PackedInt32Array()
		var x0m := INF
		var x1m := -INF
		for m in mlist:
			var bb: AABB = (m["box"] as AABB).grow(L * 0.002)
			boxes.append(bb)
			mpiece.append(_plan_main(plan, bb.get_center()))
			x0m = minf(x0m, bb.position.x)
			x1m = maxf(x1m, bb.end.x)
		var nb := 64
		var bw := maxf((x1m - x0m) / nb, 0.0001)
		var bins: Array = []
		for i in nb:
			var row := PackedInt32Array()
			for k in boxes.size():
				var bb: AABB = boxes[k]
				if bb.end.x >= x0m + i * bw and bb.position.x <= x0m + (i + 1) * bw: row.append(k)
			bins.append(row)
		var all: AABB = boxes[0]
		for bb in boxes: all = all.merge(bb)
		plan["mach"] = {"boxes": boxes, "piece": mpiece, "bins": bins, "x0": x0m, "bw": bw, "all": all}
	return plan


# Issue 1236 round 4: where a strained hull's first crack runs. The joint nearest the hull's last hit (hull space, as
# fracture_plan reads it), or with no hit on record a per-ship point along the middle of the hull.
# Issue 1236 round 4 (WRECK5c, Nov 24: most real hulls kept two pieces; SEAMS1 read their joints): the two joints a big
# metal hull breaks on, and which of them cracks first (the one nearest the hit), as [low x, high x, first]; [] for none.
# Authored joints first, any pair leaving every piece at least BREAKUP_MIN of the length, preferring a pair with the
# joint nearest the hit. Where the authored joints cannot (too few, or too near an end: H4_11 0.13, V16_37 0.08, V15_37
# 0.83) an added plain joint stands in, never through a machine (RULEBOOK 5.17) nor beside an authored one; a hull
# with no joints at all (H9_23, V17_37, V18_51) gets two.
static func _breakup_joints(s, transverse: Array, near: Vector3, x0: float, L: float) -> Array:
	var h = s.hull
	var lo := x0 + L * BREAKUP_MIN
	var hi := x0 + L * (1.0 - BREAKUP_MIN)
	var auth: Array = transverse.filter(func(t): return float(t["at"].x) >= lo and float(t["at"].x) <= hi)
	var nearest = null
	for t in auth:
		if nearest == null or _joint_gap(t, near) < _joint_gap(nearest, near): nearest = t
	var best: Array = []
	var best_score := -INF
	for i in auth.size():
		for j in range(i + 1, auth.size()):
			var sc := _pair_score(auth[i], auth[j], nearest, near, x0, L)
			if sc > best_score:
				best_score = sc
				best = [auth[i], auth[j]]
	if best.is_empty():
		# a plain joint between the authored ones: off every machine, a tenth of the length clear of an authored joint,
		# jittered per ship so a fleet of one class does not all break alike
		var jit := (float(posmod(hash(str(s.id)), 1000)) / 1000.0 - 0.5) * 0.06
		var cands: Array = []
		var f := BREAKUP_MIN
		while f <= 1.0 - BREAKUP_MIN + 1e-4:
			var x := x0 + L * clampf(f + jit, BREAKUP_MIN, 1.0 - BREAKUP_MIN)
			var ok := true
			var clear: float = tan(deg_to_rad(SYNTH_YAW)) * maxf(h.W, L * 0.06) * 0.5 + L * 0.03
			for m in h.machines:
				var bb: AABB = m["box"]
				if x > bb.position.x - clear and x < bb.end.x + clear: ok = false
			for t in transverse:
				if absf(float(t["at"].x) - x) < L * 0.1: ok = false
			if ok:
				var yw := deg_to_rad(SYNTH_YAW) * (1.0 if posmod(hash(str(s.id)) + int(f * 40.0), 2) == 0 else -1.0)
				cands.append({"at": Vector3(x, h.c.y, h.c.z), "n": Vector3(cos(yw), 0.0, sin(yw)), "synthetic": true})
			f += 0.025
		var pool: Array = auth + cands
		for i in pool.size():
			for j in range(i + 1, pool.size()):
				if bool(pool[i].get("synthetic", false)) and bool(pool[j].get("synthetic", false)) and not auth.is_empty(): continue
				var sc := _pair_score(pool[i], pool[j], nearest, near, x0, L)
				if sc > best_score:
					best_score = sc
					best = [pool[i], pool[j]]
	if best.is_empty(): return []
	if float(best[0]["at"].x) > float(best[1]["at"].x): best = [best[1], best[0]]
	var first = best[0] if _joint_gap(best[0], near) <= _joint_gap(best[1], near) else best[1]
	return [best[0], best[1], first]


# a pair's worth: -INF when a piece would be under BREAKUP_MIN; otherwise the smallest piece, plus a bonus for holding
# the authored joint nearest the hit, less how far its own nearer joint is from the hit
static func _pair_score(a: Dictionary, b: Dictionary, nearest, near: Vector3, x0: float, L: float) -> float:
	var xa := float(a["at"].x)
	var xb := float(b["at"].x)
	if xa > xb:
		var t := xa
		xa = xb
		xb = t
	var small: float = minf(minf(xa - x0, xb - xa), x0 + L - xb)
	if small < BREAKUP_MIN * L - 1e-4: return -INF
	var sc: float = small / L
	if nearest != null and (a == nearest or b == nearest): sc += 1.0
	sc -= 0.5 * minf(_joint_gap(a, near), _joint_gap(b, near)) / L
	return sc


static func _crack_near(s, x0: float, L: float, r: RandomNumberGenerator, cz: float) -> Vector3:
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 1 and last[0] is Vector3:
		return last[0]
	return Vector3(x0 + L * r.randf_range(0.25, 0.75), 0.0, cz)


# How far a hull-space point is from a joint along the length, measured on the struck side: a seam that kinks round a
# machine is read at the point's own z (Artoo on fbceb98a: at the centre line a side hit near a kink could pick the
# other joint).
static func _joint_gap(b: Dictionary, p: Vector3) -> float:
	return absf(_break_x(b, p.z) - p.x)


# Issue 461 (carried from 484: "the cut is prepared before the killing weapon is known"). A lance kill re-cuts the hull on
# the death frame along the beam's line (fracture_plan reads "lance_line"). The cut runs on a worker during the tell
# (1.38 s on a cruiser, 2.0 s on a capital); if it is not done by the break, the ship breaks along the cut it already had
# (cut_prev), never stalls. Only big hulls killed by a lance pay for it.
static func _lance_recut(fx, s) -> void:
	if not is_instance_valid(s.root):
		return
	if s.has_meta("cut_task"):
		# a damage refresh of the cut is still running (bench round 1: a damaged ship nearly always has one): leave it to
		# finish on its own and start the lance cut beside it. If the refresh had not finished, the ship breaks along the
		# last finished cut (cut_prev) only if the lance cut is late; otherwise it waits for the lance cut.
		var tid: int = s.get_meta("cut_task")
		if not finish_precompute(fx, s):
			s.remove_meta("cut_job")  # the detached worker still owns this result
			s.remove_meta("cut_work")
			fx.collect_death_cut(tid)
			s.remove_meta("cut_task")
	var h = s.hull
	# with no recent hit on record, a per-ship point a little off the middle (an even split reads as sliced, Ryan, Nov 11)
	var lp: Vector3 = h.c + Vector3(h.L * (0.12 if hash(str(s.id)) % 2 == 0 else -0.12), 0.0, 0.0)
	var ld: Vector3 = Vector3(0.0, 0.0, -float(h.stb_z))
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 2.0:
		lp = last[0]
		ld = last[1]
	s.set_meta("lance_line", [lp, ld])
	if s.has_meta("cut_job"):
		var old: Dictionary = s.get_meta("cut_job")
		if old.get("out") != null:
			s.set_meta("cut_prev", old)
		s.remove_meta("cut_job")
	var t0 := Time.get_ticks_usec()
	precompute(fx, s, "cut")
	fx.notes.append("lance recut %s" % str(s.id))
	fx.pend("lance_recut", t0)


# Gather the hull's surfaces on the main thread (mesh arrays come from the rendering server), then cut on a worker.
static func precompute(fx, s, cause := "blast", under_cover := false, shared_cuts: Variant = null) -> void:
	if fx.get("closed") == true:   # issue 1435: a released fx takes no new cuts
		return
	if fx.get("passive") == true:   # issue 1434: the title backdrop never dies
		return
	if s.weight <= 0 or s.gone or s.has_meta("cut_task") or s.has_meta("cut_job"):
		return
	if not is_instance_valid(s.root) or not s.root.is_inside_tree():
		return   # F3: the ship's node was freed before its staggered cut came round
	if s.faction == "chorus":
		cause = "rupture"
	elif s.death_big:
		cause = "cut"  # two prepared halves, and the vents/crack use this same bisector
	var r = RandomNumberGenerator.new()
	r.seed = hash(s.id) + 3
	var seeds = seeds_for(s, cause, r)
	# Issue 484: a big hull is blown apart, not sliced. Its pieces follow a fracture plan (uneven pieces, kinked and
	# torn breaks, a bite of hull gone where the core goes off, chips along the break); the seeds stay one per main
	# piece for the older readers.
	var plan := {}
	if (s.death_big and s.faction != "chorus") or s.hull.authored:
		plan = fracture_plan(fx, s, r)
		seeds = plan["seeds"]
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	var surfs: Array = []
	if s.hull.authored:
		# Seams and damage entries live in the analysis pose; ShipView may since have bobbed or banked the mesh.
		inv = s.hull_motion().affine_inverse() * inv
	for m in s.meshes:
		if not is_instance_valid(m): continue   # a ship part freed under a live ship (1204 bot runs)
		var mi = m as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var xf = inv * mi.global_transform
		for si in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(si)
			var src_mat: Material = mi.mesh.surface_get_material(si)
			var sd := {"arrays": s.current_arrays(mi, si), "xf": xf, "mat": mat, "interior": s.hull.authored and HULL.interior_material(src_mat), "fmt": (mi.mesh as ArrayMesh).surface_get_format(si) if mi.mesh is ArrayMesh else 0}
			# issue 600: the hull plating surface (<code>_hull, RECIPE.md stage 7) tears with the insides under it; only the
			# parts surfaces carry machines
			if s.hull.authored and src_mat != null and String(src_mat.resource_name).ends_with("_hull"): sd["skin"] = true
			# issue 600 (R226): a turret's turning mesh is a machine on its own node: it rides whole with the piece under its
			# pivot (the ring's machine box holds the pivot)
			var tk: int = s.hull._turret_above(mi, s.root)
			if tk >= 0:
				sd["tur"] = tk
				sd["anchor"] = inv * (s.hull.turrets[tk]["node"] as Node3D).global_transform.origin
			surfs.append(sd)
	var inputs := {"seeds": seeds, "surfs": surfs, "cause": cause, "organic": s.faction == "chorus",
		"mesh_on_worker": DisplayServer.get_name() != "headless", "plan": plan, "authored": s.hull.authored,
		"ragged": s.death_big, "warp": _waves(r, s.hull.L, s.hull.L * 0.05, 3) if s.faction == "chorus" else [],
		"sites": s.death_big and s.faction != "chorus", "sp": s.hull.sp, "sn": s.hull.sn}
	var cut: CutWork
	var matches: Array = []
	if shared_cuts != null:
		# Ship IDs still seed the break. Same class and seeds narrow the search, and every input must still match.
		var key := [s.faction, s.get_meta("cut_class", ""), seeds]
		matches = shared_cuts.get_or_add(key, [])
		for candidate: CutWork in matches:
			if inputs == candidate.inputs:
				cut = candidate
				break
	if cut == null:
		cut = CutWork.new()
		cut.inputs = inputs
		_init_dirs()
		var share_lanes: bool = under_cover and fx.ships.size() > 1
		cut.task = fx.submit_death_cut(_run_cut.bind(cut, fx.cut_abort, share_lanes))
		if shared_cuts != null:
			matches.append(cut)
	var job := inputs.duplicate()
	job["out"] = null
	s.set_meta("cut_job", job)
	s.set_meta("cut_work", cut)
	s.set_meta("cut_task", cut.task)
	if not under_cover:
		fx.later(fx.now + 0.5, func l_prebuild() -> void: _prebuild(fx, s))


class CutWork extends RefCounted:
	var task := -1
	var inputs: Dictionary
	# Read the worker's results only after joining the task.
	var pieces: Array
	var geo: Array
	var cut_usec := 0
	var hulls_usec := 0


class CutAbort extends RefCounted:
	var _lock := Mutex.new()
	var _cancelled := false

	func cancel() -> void:
		_lock.lock()
		_cancelled = true
		_lock.unlock()

	func cancelled() -> bool:
		_lock.lock()
		var stopped := _cancelled
		_lock.unlock()
		return stopped


static func _run_cut(work: CutWork, abort: CutAbort, share_lanes: bool) -> void:
	var job := work.inputs
	var tc := Time.get_ticks_usec()
	var pieces := _cut(job, abort, share_lanes)
	if abort.cancelled():
		return
	work.cut_usec = Time.get_ticks_usec() - tc
	var th := Time.get_ticks_usec()
	_piece_hulls(pieces, abort)
	if abort.cancelled():
		return
	work.hulls_usec = Time.get_ticks_usec() - th   # issue 1395: includes each piece's reach (_piece_reach)
	if bool(job["sites"]):
		var n_main: int = int(job["plan"]["n_main"]) if not (job["plan"] as Dictionary).is_empty() else pieces.size()
		for i in mini(n_main, pieces.size()):
			if abort.cancelled():
				return
			pieces[i]["sec_sites"] = _piece_sites_in(job["sp"], job["sn"], job["seeds"], pieces[i]["cen"], 5, job["plan"], i)
	# Issue 220: upload geometry on the worker; the piece's materials are set on the main thread.
	if bool(job["mesh_on_worker"]):
		for pc in pieces:
			if abort.cancelled():
				return
			work.geo.append(_piece_geometry(pc))
	work.pieces = pieces


# When the cut is done, upload the pieces' meshes while the battle is quiet, so the break-up itself only shows them
# (the first break-up cost a 35 ms frame when it built them on the spot).
static func _prebuild(fx, s) -> void:
	if not finish_precompute(fx, s):
		fx.later(fx.now + 0.5, func l_prebuild() -> void: _prebuild(fx, s))


static func finish_precompute(fx, s) -> bool:
	if not s.has_meta("cut_task") or s.has_meta("death_hidden"):
		return true
	var tid: int = s.get_meta("cut_task")
	if not fx.finish_death_cut(tid):
		return false
	s.remove_meta("cut_task")
	var job: Dictionary = s.get_meta("cut_job", {})
	if s.has_meta("cut_work"):
		var cut: CutWork = s.get_meta("cut_work")
		s.remove_meta("cut_work")
		# Each wreck's materials, shapes and motion are set independently. The cut arrays stay shared.
		var pieces: Array = []
		for piece: Dictionary in cut.pieces:
			pieces.append(piece.duplicate())
		job["out"] = pieces
		job["cut_usec"] = cut.cut_usec
		job["hulls_usec"] = cut.hulls_usec
		job["geo"] = cut.geo
		cut.geo = []  # ArrayMesh receives this ship's materials, so only one ship takes the worker's upload.
	if not job.has("meshes"):
		job["meshes"] = []
		fx.queue_death_pieces(s, job)
	return true


# Issue 600 (R118): the pieces' materials and colliders are built a few at a time, PREBUILD_BUDGET of main-thread time a
# frame, never all in one frame (on A16, 16 pieces cost 40 to 60 ms together). A cut is ready for the split only
# once its meshes, materials and shapes are built.
const PREBUILD_BUDGET := 4000   # microseconds a frame; a tuning value

static func build_pieces(fx, s, job: Dictionary, deadline: int) -> bool:
	if s.has_meta("death_hidden") or fx.ships.get(s.id) != s:
		return true
	var t0 := Time.get_ticks_usec()
	var meshes: Array = job["meshes"]
	var geo: Array = job.get("geo", [])
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	while meshes.size() < pieces.size():
		var i := meshes.size()
		var pc: Dictionary = pieces[i]
		pc["dstyle"] = dstyle(s)
		meshes.append(_piece_materials(geo[i], pc, false, fx) if i < geo.size() else _piece_mesh(pc, false, fx))
		if pc.has("hull"): pc["shape"] = safe_convex(pc["hull"])
		if Time.get_ticks_usec() >= deadline: break
	job["build_max_usec"] = maxi(int(job.get("build_max_usec", 0)), Time.get_ticks_usec() - t0)
	fx.pend("piece_meshes", t0)
	job["built"] = meshes.size() == pieces.size()
	return job["built"]


# Hull attributes keep their vertex format; private damage materials add burnt backs.
# The opaque slag surface is built here with the piece, before death when possible.
static func _piece_mesh(pc: Dictionary, weathered := false, fx = null) -> ArrayMesh:
	return _piece_materials(_piece_geometry(pc), pc, weathered, fx)


# The piece's surfaces, no materials (safe on a worker thread: no shaders or static caches are touched).
static func _piece_geometry(pc: Dictionary) -> ArrayMesh:
	var am = ArrayMesh.new()
	for sd in pc["surfs"]:
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, sd["arrays"], [], {}, int(sd.get("fmt", 0)) & Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)
	if pc.has("cap"):
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, pc["cap"])
	return am


# The piece's materials, in surface order (main thread).
static func _piece_materials(am: ArrayMesh, pc: Dictionary, weathered := false, fx = null) -> ArrayMesh:
	var si := 0
	for sd in pc["surfs"]:
		if bool(sd.get("interior", false)):
			# issue 1077 (prototype): the grouped wreck keeps its torn insides in view up close, and the live inside paint read
			# as flat grey slabs there (pass 3, c26), so a strained wreck's insides are powered down and sooted
			am.surface_set_material(si, fx.wreck_interior(sd["mat"]) if fx != null and fx.death_story else sd["mat"])
			si += 1
			continue
		var length := float(pc.get("section_scale", 1.0))
		var organic := bool(pc.get("organic", false))
		var base: ShaderMaterial = fx.hull_damage_template(sd["mat"], 1.0, organic) if fx != null else null
		var hull_mat: ShaderMaterial = base.duplicate() if base != null else HULL.damage_material(sd["mat"], Transform3D.IDENTITY, {}, length, organic)
		if base != null:
			hull_mat.set_shader_parameter("fx_burnt_cell", Vector3.ONE * maxf(length * 0.05, 0.001))
		hull_mat.set_shader_parameter("fx_power", 0.0)
		hull_mat.set_shader_parameter("fx_weather", 0.8 if weathered else 0.0)
		var rim = (pc.get("dstyle", {}) as Dictionary).get("rim")
		if rim is Color: hull_mat.set_shader_parameter("fx_scorch_col", rim)
		# issue 484: blackened, heat-stained plating round the wound (fx_hull.gd DAMAGE_UNIFORMS, fx_scorch)
		var scorch: Array = pc.get("scorch", [])
		if not scorch.is_empty():
			hull_mat.set_shader_parameter("fx_scorch_count", mini(scorch.size(), 8))
			hull_mat.set_shader_parameter("fx_scorch", scorch.slice(0, 8))
			hull_mat.set_shader_parameter("fx_scorch_heat", 0.0)
			var hm: Array = pc.get("hull_mats", [])
			hm.append(hull_mat)
			pc["hull_mats"] = hm
		if si < am.get_surface_count():
			am.surface_set_material(si, hull_mat)
		si += 1
	if pc.has("cap"):
		var mat := ShaderMaterial.new()
		mat.shader = HULL.shared_shader(SLAG, "death piece slag")
		mat.set_shader_parameter("organic", pc.get("organic", false))
		mat.set_shader_parameter("section_scale", pc.get("section_scale", 1.0))
		_style_heat(mat, pc.get("dstyle", {}), "heat_")
		am.surface_set_material(mini(si, am.get_surface_count() - 1), mat)
		pc["cap_mat"] = mat
	return am


# Issue 600 (R186, RULEBOOK 5.17): an authored hull's insides were whole slabs (an A16 deck is a few triangles up to half
# the ship long), and each triangle went whole to the piece its centre lay in, so decks and bulkheads stuck out of the
# broken hull as big flat squares. Every triangle that crosses a tear (the seam paths with their waves, the bite, the
# chips) is now split along it until its edges are shorter than REFINE_EPS of the length (about a pixel at camera 170),
# then each small triangle goes to its own piece: the insides and the plating tear at the same ragged line.
# An edge is split by a rule of its two end points alone (they lie on different pieces, or a point between them does),
# so two triangles that share an edge split it the same way and the outer skin stays sealed for _seal_piece. A machine's
# box never splits (every point in it is the machine's piece). A large inside triangle whose middle lies on another piece
# is also split (insides are not sealed, so it may leave a T-junction).
const REFINE_EPS := 0.012
const REFINE_EPS_SKIN := 0.02
const REFINE_CAP := 200000   # new points per surface at most (a guard; A16 needs a few thousand)


static func _refine(plan: Dictionary, vl_in: PackedVector3Array, arr: Array, idx: PackedInt32Array, eps: float, interior: bool, abort: CutAbort = null) -> Dictionary:
	var vl := vl_in.duplicate()   # the source arrays are shared with the live ship: never grown in place
	var n0 := vl.size()
	var nrm := PackedVector3Array()
	if arr[Mesh.ARRAY_NORMAL] != null and (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == n0: nrm = (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).duplicate()
	var tng := PackedFloat32Array()
	if arr[Mesh.ARRAY_TANGENT] != null and (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size() == n0 * 4: tng = (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).duplicate()
	var uv := PackedVector2Array()
	if arr[Mesh.ARRAY_TEX_UV] != null and (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size() == n0: uv = (arr[Mesh.ARRAY_TEX_UV] as PackedVector2Array).duplicate()
	var uv2 := PackedVector2Array()
	if arr[Mesh.ARRAY_TEX_UV2] != null and (arr[Mesh.ARRAY_TEX_UV2] as PackedVector2Array).size() == n0: uv2 = (arr[Mesh.ARRAY_TEX_UV2] as PackedVector2Array).duplicate()
	var col := PackedColorArray()
	if arr[Mesh.ARRAY_COLOR] != null and (arr[Mesh.ARRAY_COLOR] as PackedColorArray).size() == n0: col = (arr[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate()
	var vp := PackedInt32Array()
	vp.resize(n0)
	vp.fill(-9)
	var mids := {}
	var eps2 := eps * eps
	var sample := float(plan["L"]) * 0.03
	var out_idx := PackedInt32Array()
	var out_piece := PackedInt32Array()
	var stack := PackedInt32Array()
	var m := PackedInt32Array([-1, -1, -1])
	var refined := 0
	for t in range(0, idx.size() - 2, 3):
		if (t & 255) == 0 and abort != null and abort.cancelled(): return {}
		var a0 := idx[t]
		var b0 := idx[t + 1]
		var c0 := idx[t + 2]
		var p0 := vl[a0]
		var p1 := vl[b0]
		var p2 := vl[c0]
		if maxf(p0.distance_squared_to(p1), maxf(p1.distance_squared_to(p2), p2.distance_squared_to(p0))) < eps2:
			if interior and _torn(plan, vl, vp, a0, b0, c0): continue
			out_idx.append(a0)
			out_idx.append(b0)
			out_idx.append(c0)
			out_piece.append(_piece_at(plan, (p0 + p1 + p2) / 3.0))
			continue
		# bisection can cycle on slivers at the tear (a split that leaves a child as long as its parent), so each triangle
		# splits at most twice per halving of its longest edge down to eps; a triangle stopped there stays whole (a
		# T-junction at most, and only on a piece boundary, where the two sides are sealed apart anyway)
		var dmax := mini(30, 3 * int(ceil(log(sqrt(maxf(p0.distance_squared_to(p1), maxf(p1.distance_squared_to(p2), p2.distance_squared_to(p0)))) / eps) / log(2.0))) + 4)
		stack.append(a0)
		stack.append(b0)
		stack.append(c0)
		stack.append(0)
		while not stack.is_empty():
			refined += 1
			if (refined & 255) == 0 and abort != null and abort.cancelled(): return {}
			var n := stack.size()
			var a := stack[n - 4]
			var b := stack[n - 3]
			var c := stack[n - 2]
			var depth := stack[n - 1]
			stack.resize(n - 4)
			if depth >= dmax:
				if interior and _torn(plan, vl, vp, a, b, c): continue
				out_idx.append(a)
				out_idx.append(b)
				out_idx.append(c)
				out_piece.append(_piece_at(plan, (vl[a] + vl[b] + vl[c]) / 3.0))
				continue
			var marks := 0
			var longest := 0.0
			for ei in 3:
				var ia: int = a if ei == 0 else (b if ei == 1 else c)
				var ib: int = b if ei == 0 else (c if ei == 1 else a)
				var qa := vl[ia]
				var qb := vl[ib]
				var l2 := qa.distance_squared_to(qb)
				longest = maxf(longest, l2)
				var key: int = mini(ia, ib) * 16777216 + maxi(ia, ib)
				var got: int = int(mids.get(key, -2))
				if got == -2:
					got = -1
					if l2 >= eps2 and vl.size() - n0 < REFINE_CAP:
						if vp[ia] == -9: vp[ia] = _piece_at(plan, qa)
						if vp[ib] == -9: vp[ib] = _piece_at(plan, qb)
						var cut := vp[ia] != vp[ib]
						if not cut and l2 > sample * sample:
							# a long edge can pass a tooth, a chip or the bite with both ends on one piece: look between
							var k := clampi(int(ceil(sqrt(l2) / sample)), 2, 12)
							for j in range(1, k):
								if _piece_at(plan, qa.lerp(qb, float(j) / k)) != vp[ia]:
									cut = true
									break
						if cut:
							got = vl.size()
							vl.append((qa + qb) * 0.5)
							vp.append(-9)
							if not nrm.is_empty():
								var nn := nrm[ia] + nrm[ib]
								nrm.append(nn.normalized() if nn.length_squared() > 1e-12 else nrm[ia])
							if not tng.is_empty():
								var tv := Vector3(tng[ia * 4] + tng[ib * 4], tng[ia * 4 + 1] + tng[ib * 4 + 1], tng[ia * 4 + 2] + tng[ib * 4 + 2])
								tv = tv.normalized() if tv.length_squared() > 1e-12 else Vector3(tng[ia * 4], tng[ia * 4 + 1], tng[ia * 4 + 2])
								tng.append_array(PackedFloat32Array([tv.x, tv.y, tv.z, tng[ia * 4 + 3]]))
							if not uv.is_empty(): uv.append((uv[ia] + uv[ib]) * 0.5)
							if not uv2.is_empty(): uv2.append((uv2[ia] + uv2[ib]) * 0.5)
							if not col.is_empty(): col.append(col[ia].lerp(col[ib], 0.5))
					mids[key] = got
				m[ei] = got
				if got >= 0: marks += 1
			if marks == 0 and interior and longest >= eps2 and vl.size() - n0 < REFINE_CAP:
				# a big inside panel whose middle lies on another piece (the bite, a chip): split it anyway
				if vp[a] == -9: vp[a] = _piece_at(plan, vl[a])
				if _piece_at(plan, (vl[a] + vl[b] + vl[c]) / 3.0) != vp[a]:
					for ei in 3:
						var ia: int = a if ei == 0 else (b if ei == 1 else c)
						var ib: int = b if ei == 0 else (c if ei == 1 else a)
						var key: int = mini(ia, ib) * 16777216 + maxi(ia, ib)
						var got := vl.size()
						vl.append((vl[ia] + vl[ib]) * 0.5)
						vp.append(-9)
						if not nrm.is_empty():
							var nn := nrm[ia] + nrm[ib]
							nrm.append(nn.normalized() if nn.length_squared() > 1e-12 else nrm[ia])
						if not tng.is_empty(): tng.append_array(tng.slice(ia * 4, ia * 4 + 4))
						if not uv.is_empty(): uv.append((uv[ia] + uv[ib]) * 0.5)
						if not uv2.is_empty(): uv2.append((uv2[ia] + uv2[ib]) * 0.5)
						if not col.is_empty(): col.append(col[ia].lerp(col[ib], 0.5))
						mids[key] = got
						m[ei] = got
					marks = 3
			if marks == 0:
				if interior and _torn(plan, vl, vp, a, b, c): continue
				out_idx.append(a)
				out_idx.append(b)
				out_idx.append(c)
				out_piece.append(_piece_at(plan, (vl[a] + vl[b] + vl[c]) / 3.0))
				continue
			var mab := m[0]
			var mbc := m[1]
			var mca := m[2]
			var kids: Array
			if marks == 3:
				kids = [a, mab, mca, mab, b, mbc, mca, mbc, c, mab, mbc, mca]
			elif marks == 1:
				if mab >= 0: kids = [a, mab, c, mab, b, c]
				elif mbc >= 0: kids = [a, b, mbc, a, mbc, c]
				else: kids = [a, b, mca, mca, b, c]
			elif mca < 0: kids = [mab, b, mbc, a, mab, mbc, a, mbc, c]
			elif mab < 0: kids = [mbc, c, mca, b, mbc, mca, b, mca, a]
			else: kids = [mca, a, mab, c, mca, mab, c, mab, b]
			for i in kids.size():
				stack.append(int(kids[i]))
				if i % 3 == 2: stack.append(depth + 1)
	var out := arr.duplicate()
	if not nrm.is_empty(): out[Mesh.ARRAY_NORMAL] = nrm
	if not tng.is_empty(): out[Mesh.ARRAY_TANGENT] = tng
	if not uv.is_empty(): out[Mesh.ARRAY_TEX_UV] = uv
	if not uv2.is_empty(): out[Mesh.ARRAY_TEX_UV2] = uv2
	if not col.is_empty(): out[Mesh.ARRAY_COLOR] = col
	return {"vl": vl, "arr": out, "idx": out_idx, "piece": out_piece}


# An inside triangle still across the tear at the finest split (its corners on different pieces): the strip the tear
# runs through is blown away, so no corner of an inside panel stands past its own piece's torn line.
static func _torn(plan: Dictionary, vl: PackedVector3Array, vp: PackedInt32Array, a: int, b: int, c: int) -> bool:
	for i in [a, b, c]:
		if vp[i] == -9: vp[i] = _piece_at(plan, vl[i])
	return vp[a] != vp[b] or vp[b] != vp[c]


static var cut_serial := false   # issue 1232: the one-thread cut, for fx/test/cold_kill_check.gd to compare against

# Issue 1279: Jolt's physics jobs use the same high-priority lanes. Reserve two beyond the low-priority cap across
# all cuts, including cuts from another battle. The mutex only guards the count. A cut that finds no room works
# on its own low-priority worker, which the budget already accounts for.
static var _lane_budget_lock := Mutex.new()
static var _lanes_in_use := 0


static func _cut_lane_budget() -> int:
	var threads := int(ProjectSettings.get_setting("threading/worker_pool/max_threads", -1))
	if threads < 0:
		threads = OS.get_processor_count()
	var ratio := float(ProjectSettings.get_setting("threading/worker_pool/low_priority_thread_ratio", 0.3))
	var low := clampi(int(threads * ratio), 1, maxi(threads - 1, 1))
	return maxi(threads - 2 - low, 0)


static func cut_lanes(work: int) -> int:
	return mini(_cut_lane_budget(), work)


static func _reserve_cut_lanes(work: int, share_lanes: bool) -> int:
	var total := _cut_lane_budget()
	var limit := mini(work, (total + 1) / 2 if share_lanes else total)
	_lane_budget_lock.lock()
	var lanes := mini(limit, maxi(total - _lanes_in_use, 0))
	_lanes_in_use += lanes
	_lane_budget_lock.unlock()
	return lanes


static func _run_cut_group(work: Callable, count: int, lanes: int, label: String) -> void:
	var group := WorkerThreadPool.add_group_task(work, count, lanes, true, label)
	WorkerThreadPool.wait_for_group_task_completion(group)
	_lane_budget_lock.lock()
	_lanes_in_use -= lanes
	_lane_budget_lock.unlock()


static func _cut(job: Dictionary, abort: CutAbort = null, share_lanes := false) -> Array:
	if abort != null and abort.cancelled(): return []
	var seeds: PackedVector3Array = job["seeds"]
	var plan: Dictionary = job.get("plan", {})
	var warp: Array = job.get("warp", [])
	var ns = seeds.size()
	var n_main = ns
	if not plan.is_empty():
		n_main = int(plan["n_main"])
		ns = n_main + int(plan["n_frag"])
	var pieces: Array = _blank_pieces(job, plan, ns, n_main)
	# Issue 1232: each surface is cut on its own worker, then merged in surface order, so the pieces match a one-thread
	# cut. A16's headless cut was 2.8 s, about 1 s of it one plating surface cut after all the others; on the PC it was
	# 5.4 s, longer than a capital's 2.67 s death, so a kill before the cut was ready lost its pieces.
	var surfs: Array = job["surfs"]
	var lanes := 0 if plan.is_empty() or surfs.size() < 2 or cut_serial else _reserve_cut_lanes(surfs.size(), share_lanes)
	if lanes == 0:
		for sd in surfs:
			if abort != null and abort.cancelled(): return []
			_cut_surface(job, sd, pieces, ns, plan, warp, seeds, abort)
	else:
		var parts: Array = []
		for i in surfs.size():
			parts.append({"pieces": _blank_pieces(job, plan, ns, n_main)})
		_run_cut_group(func(i: int) -> void:
			_cut_surface(job, surfs[i], (parts[i] as Dictionary)["pieces"], ns, plan, warp, seeds, abort),
			surfs.size(), lanes, "death cut surfaces")
		for part in parts:
			if abort != null and abort.cancelled(): return []
			var own: Array = part["pieces"]
			for c in ns:
				var src: Dictionary = own[c]
				if (src["surfs"] as Array).is_empty(): continue
				var pc: Dictionary = pieces[c]
				(pc["surfs"] as Array).append_array(src["surfs"])
				pc["n"] = int(pc["n"]) + int(src["n"])
				var pts: PackedVector3Array = pc["pts"]
				pts.append_array(src["pts"])
				pc["pts"] = pts
	# each piece seals its own boundary loops (no shared state), so the pieces seal side by side too
	if abort != null and abort.cancelled(): return []
	lanes = 0 if pieces.size() < 2 or cut_serial else _reserve_cut_lanes(pieces.size(), share_lanes)
	if lanes == 0:
		for pc in pieces:
			if abort != null and abort.cancelled(): return []
			_seal_piece(pc, abort)
	else:
		_run_cut_group(func(i: int) -> void: _seal_piece(pieces[i], abort), pieces.size(), lanes, "death cut seals")
	return pieces


static func _blank_pieces(job: Dictionary, plan: Dictionary, ns: int, n_main: int) -> Array:
	var pieces: Array = []
	for c in ns:
		pieces.append({"surfs": [], "pts": PackedVector3Array(), "edge": PackedVector3Array(), "n": 0, "organic": job.get("organic", false),
			"ragged": bool(job.get("ragged", false)), "frag": c >= n_main, "scorch": plan.get("scorch", []), "plan": plan, "authored": job.get("authored", false)})
	return pieces


# One surface of the hull, cut into the given pieces (issue 1232: on its own worker when the cut has a plan).
static func _cut_surface(job: Dictionary, sd: Dictionary, pieces: Array, ns: int, plan: Dictionary, warp: Array, seeds: PackedVector3Array, abort: CutAbort) -> void:
	if abort != null and abort.cancelled(): return
	var arr: Array = sd["arrays"]
	var xf: Transform3D = sd["xf"]
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var vl = xf * v
	# a mirrored hull (negative determinant) turns its triangles inside out: flip the winding back
	var flip = xf.basis.determinant() < 0.0
	var idx = PackedInt32Array()
	if arr[Mesh.ARRAY_INDEX] != null and (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() > 0:
		idx = arr[Mesh.ARRAY_INDEX]
	else:
		idx.resize(v.size())
		for i in v.size():
			idx[i] = i
	# issue 600: where each triangle goes. A turret's turning mesh rides whole with the piece under its pivot; an
	# authored hull's triangles that cross a tear are split along it first (_refine), so no deck, bulkhead or plate is
	# left whole across a break; a machine's triangles go with its own piece (_piece_at).
	var tri_piece := PackedInt32Array()
	var nv: int = v.size()
	if not plan.is_empty():
		if sd.has("anchor"):
			tri_piece.resize(idx.size() / 3)
			tri_piece.fill(_piece_at(plan, sd["anchor"]))
		elif bool(job.get("authored", false)):
			var inside := bool(sd.get("interior", false))
			# the plating and the insides follow the tear; a machine's box holds only on the parts surfaces
			var sp: Dictionary = plan
			if (inside or bool(sd.get("skin", false))) and plan.has("mach"):
				sp = plan.duplicate()
				sp.erase("mach")
			var rf := _refine(sp, vl, arr, idx, float(plan["L"]) * (REFINE_EPS if inside else REFINE_EPS_SKIN), inside, abort)
			if rf.is_empty(): return
			vl = rf["vl"]
			arr = rf["arr"]
			idx = rf["idx"]
			tri_piece = rf["piece"]
			nv = vl.size()
	var buckets: Array = []
	for c in ns:
		buckets.append(PackedInt32Array())
	for t in range(0, idx.size() - 2, 3):
		if (t & 1023) == 0 and abort != null and abort.cancelled(): return
		var a = idx[t]
		var b = idx[t + 1]
		var cc = idx[t + 2]
		var q = (vl[a] + vl[b] + vl[cc]) / 3.0
		var best = 0
		var bd = 1e18
		var bd2 = 1e18
		if not tri_piece.is_empty():
			best = tri_piece[t / 3]
		elif not plan.is_empty():
			best = _piece_at(plan, q)
		else:
			# issue 484: a Chorus rupture tears along warped lines, not flat Voronoi planes
			var qw: Vector3 = q
			if not warp.is_empty(): qw = q + Vector3(1.0, 0.4, 0.6) * _wave_sum(warp, q)
			for c in ns:
				var dd = qw.distance_squared_to(seeds[c])
				if dd < bd:
					bd2 = bd
					bd = dd
					best = c
				elif dd < bd2:
					bd2 = dd
		buckets[best].append(a)
		buckets[best].append(cc if flip else b)
		buckets[best].append(b if flip else cc)
		var pc: Dictionary = pieces[best]
		if plan.is_empty() and (pc["edge"] as PackedVector3Array).size() < 64 and sqrt(bd2) - sqrt(bd) < 0.6:
			var edge: PackedVector3Array = pc["edge"]
			edge.append(q)
			pc["edge"] = edge
	for c in ns:
		if abort != null and abort.cancelled(): return
		var tri: PackedInt32Array = buckets[c]
		if tri.is_empty():
			continue
		var remap = PackedInt32Array()
		remap.resize(nv)
		remap.fill(-1)
		var order = PackedInt32Array()
		var nidx = PackedInt32Array()
		nidx.resize(tri.size())
		for i in tri.size():
			var o = tri[i]
			var m = remap[o]
			if m < 0:
				m = order.size()
				remap[o] = m
				order.append(o)
			nidx[i] = m
		var na = []
		na.resize(Mesh.ARRAY_MAX)
		var pv = PackedVector3Array()
		pv.resize(order.size())
		for i in order.size():
			pv[i] = vl[order[i]]
		na[Mesh.ARRAY_VERTEX] = pv
		if arr[Mesh.ARRAY_NORMAL] != null and (arr[Mesh.ARRAY_NORMAL] as PackedVector3Array).size() == nv:
			var src: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			var dn = PackedVector3Array()
			dn.resize(order.size())
			for i in order.size():
				dn[i] = (xf.basis * src[order[i]]).normalized()
			na[Mesh.ARRAY_NORMAL] = dn
		if arr[Mesh.ARRAY_TANGENT] != null and (arr[Mesh.ARRAY_TANGENT] as PackedFloat32Array).size() == nv * 4:
			var src4: PackedFloat32Array = arr[Mesh.ARRAY_TANGENT]
			var dt = PackedFloat32Array()
			dt.resize(order.size() * 4)
			for i in order.size():
				var o4 = order[i] * 4
				var tv = (xf.basis * Vector3(src4[o4], src4[o4 + 1], src4[o4 + 2])).normalized()
				dt[i * 4] = tv.x
				dt[i * 4 + 1] = tv.y
				dt[i * 4 + 2] = tv.z
				dt[i * 4 + 3] = src4[o4 + 3]
			na[Mesh.ARRAY_TANGENT] = dt
		for key in [Mesh.ARRAY_TEX_UV, Mesh.ARRAY_TEX_UV2]:
			if arr[key] != null and (arr[key] as PackedVector2Array).size() == nv:
				var s2: PackedVector2Array = arr[key]
				var d2 = PackedVector2Array()
				d2.resize(order.size())
				for i in order.size():
					d2[i] = s2[order[i]]
				na[key] = d2
		if arr[Mesh.ARRAY_COLOR] != null and (arr[Mesh.ARRAY_COLOR] as PackedColorArray).size() == nv:
			var sc: PackedColorArray = arr[Mesh.ARRAY_COLOR]
			var dc = PackedColorArray()
			dc.resize(order.size())
			for i in order.size():
				dc[i] = sc[order[i]]
			na[Mesh.ARRAY_COLOR] = dc
		na[Mesh.ARRAY_INDEX] = nidx
		var pc: Dictionary = pieces[c]
		pc["surfs"].append({"arrays": na, "mat": sd["mat"], "interior": sd.get("interior", false), "fmt": int(sd.get("fmt", 0)), "tur": int(sd.get("tur", -1)), "skin": bool(sd.get("skin", false))})
		pc["n"] = int(pc["n"]) + order.size()
		var step = maxi(1, order.size() / 120)
		var points: PackedVector3Array = pc["pts"]
		for i in range(0, order.size(), step):
			points.append(pv[i])
		pc["pts"] = points



# Trace the actual welded boundary loops. Ear clipping uses boundary vertices only:
# no centre vertex, radial bands or centre-point ribs can show through as spokes.
static func _seal_piece(pc: Dictionary, abort: CutAbort = null) -> void:
	var all_edges := {}
	var welds := {}
	var positions := PackedVector3Array()
	var bounds := AABB()
	var first := true
	for sd in pc["surfs"]:
		var verts: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
		for i in verts.size():
			if (i & 1023) == 0 and abort != null and abort.cancelled(): return
			var p := verts[i]
			if not p.is_finite(): continue
			if first:
				bounds = AABB(p, Vector3.ZERO)
				first = false
			else: bounds = bounds.expand(p)
	if first: return
	pc["section_scale"] = bounds.size.length()
	var quantum := maxf(bounds.size.length() * 0.000001, 0.000001)
	for sd in pc["surfs"]:
		# Authored decks and machinery have their own thickness and paint. Only the exterior gets a procedural torn rim.
		if bool(pc.get("authored", false)) and bool(sd.get("interior", false)): continue
		var pts: PackedVector3Array = sd["arrays"][Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = sd["arrays"][Mesh.ARRAY_INDEX]
		var ids := PackedInt32Array()
		ids.resize(pts.size())
		ids.fill(-1)
		for i in pts.size():
			if (i & 1023) == 0 and abort != null and abort.cancelled(): return
			if not pts[i].is_finite(): continue
			var key := Vector3i((pts[i] / quantum).round())
			if not welds.has(key):
				welds[key] = positions.size()
				positions.append(pts[i])
			ids[i] = int(welds[key])
		for t in range(0, idx.size() - 2, 3):
			if (t & 1023) == 0 and abort != null and abort.cancelled(): return
			for j in 3:
				var ka := ids[idx[t + j]]
				var kb := ids[idx[t + (j + 1) % 3]]
				if ka < 0 or kb < 0 or ka == kb: continue
				var key := Vector2i(mini(ka, kb), maxi(ka, kb))
				if all_edges.has(key): all_edges.erase(key)
				else: all_edges[key] = true
	pc["boundary_edges"] = all_edges.size()
	var adj := {}
	var edge_count := 0
	for key in all_edges:
		if (edge_count & 255) == 0 and abort != null and abort.cancelled(): return
		edge_count += 1
		for j in 2:
			if not adj.has(key[j]): adj[key[j]] = []
			adj[key[j]].append(key[1 - j])
	var remaining := all_edges.duplicate()
	var cap := {"v": PackedVector3Array(), "n": PackedVector3Array(), "c": PackedColorArray()}
	pc["cap_loops"] = 0
	pc["cap_fallbacks"] = 0
	var walked := 0
	for start in adj:
		if abort != null and abort.cancelled(): return
		var walk: Array = [start]
		while not walk.is_empty():
			if (walked & 255) == 0 and abort != null and abort.cancelled(): return
			walked += 1
			var at: int = walk.back()
			var next := -1
			for other in adj[at]:
				var edge := Vector2i(mini(at, other), maxi(at, other))
				if remaining.has(edge):
					remaining.erase(edge)
					next = other
					break
			if next < 0:
				walk.pop_back()
				continue
			var seen := walk.find(next)
			if seen >= 0:
				var outline := PackedVector3Array()
				for j in range(seen, walk.size()): outline.append(positions[walk[j]])
				if outline.size() >= 3:
					_cap_outline(cap, outline, bounds, quantum, pc, abort)
				walk.resize(seen + 1)
			else: walk.append(next)
	if not (cap["v"] as PackedVector3Array).is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = cap["v"]
		arr[Mesh.ARRAY_NORMAL] = cap["n"]
		arr[Mesh.ARRAY_COLOR] = cap["c"]
		pc["cap"] = arr


static func _cap_outline(cap: Dictionary, outline: PackedVector3Array, bounds: AABB, quantum: float, pc: Dictionary, abort: CutAbort = null) -> void:
	if abort != null and abort.cancelled(): return
	var centre := Vector3.ZERO
	for p in outline: centre += p
	centre /= outline.size()
	var normal := Vector3.ZERO
	var radius := 0.0
	for i in outline.size():
		normal += (outline[i] - centre).cross(outline[(i + 1) % outline.size()] - centre)
		radius = maxf(radius, outline[i].distance_to(centre))
	if normal.length_squared() < 1e-16:
		for i in range(1, outline.size() - 1):
			var n := (outline[i] - outline[0]).cross(outline[i + 1] - outline[0])
			if n.length_squared() > normal.length_squared(): normal = n
	if normal.length_squared() < 1e-20: return
	normal = normal.normalized()
	var inward := normal if normal.dot(bounds.get_center() - centre) >= 0.0 else -normal
	var x := normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	var y := normal.cross(x)
	var polygon := PackedVector2Array()
	var inset := PackedVector3Array()
	var depth := minf(radius * 0.075, bounds.size.length() * 0.035)
	for p in outline:
		polygon.append(Vector2((p - centre).dot(x), (p - centre).dot(y)))
		# Only the narrow torn lip slopes. The whole face has one material band.
		var rough := sin(p.dot(Vector3(3.1, 5.7, 2.3))) * sin(p.dot(Vector3(8.3, 2.1, 4.7)))
		inset.append(p + (centre - p) * 0.018 + inward * depth * (1.0 + rough * 0.12))
	var indices := Geometry2D.triangulate_polygon(polygon)
	if abort != null and abort.cancelled(): return
	if indices.is_empty():
		# Imported non-planar/self-overlapping loops can fail 2D ear clipping.
		# A boundary-only zipper still seals them without a hub or radial spokes.
		pc["cap_fallbacks"] = int(pc["cap_fallbacks"]) + 1
		var lo := 0
		var hi := outline.size() - 1
		while hi - lo > 1:
			indices.append_array(PackedInt32Array([lo, lo + 1, hi]))
			lo += 1
			if hi - lo > 1:
				indices.append_array(PackedInt32Array([lo, hi - 1, hi]))
				hi -= 1
	if not bool(pc.get("authored", false)):
		for i in range(0, indices.size(), 3):
			_cap_tri(cap, inset[indices[i]], inset[indices[i + 1]], inset[indices[i + 2]], Color(0.9, 0.015, 0, 1))
	for i in outline.size():
		var j := (i + 1) % outline.size()
		_cap_tri(cap, outline[i], outline[j], inset[j], Color(0.25, 1.0, 0, 1))
		_cap_tri(cap, outline[i], inset[j], inset[i], Color(0.25, 1.0, 0, 1))
		# Sparse short, offset spars. Never connect them all to a common centre.
		if i % maxi(1, outline.size() / 4) == 0 and outline[i].distance_to(outline[j]) > quantum * 3.0:
			var a := outline[i].lerp(outline[j], 0.42) + inward * depth * 0.45
			var tangent := (outline[j] - outline[i]).normalized()
			_cap_rib(cap, a, a + tangent * radius * 0.12 + inward * depth * 0.35, -inward, maxf(radius * 0.012, quantum * 2.0))
	# Short cross members sit on the solid face. Clip each one to the real
	# outline so decks and bone ribs cannot stick outside a narrow fragment.
	# Bench round 2: the hull's own open edges (kit parts, old holes) are capped too; only loops on the new break or the
	# bite get the torn rim, or every kit seam sprouted petals.
	var ragged := bool(pc.get("ragged", false)) and _loop_torn(pc.get("plan", {}), outline)
	if ragged:
		# issue 484: the real torn rim, for the flash and fire sites (the cap also holds petals and long ribs that stick
		# out past the hull, and a site there floats beside the wreck)
		var lip: PackedVector3Array = pc.get("lip", PackedVector3Array())
		for i in range(0, outline.size(), maxi(1, outline.size() / 48)):
			if lip.size() < 512: lip.append(inset[i])
		pc["lip"] = lip
		if not bool(pc.get("authored", false)):
			_section_structure(cap, polygon, centre, x, y, inward, depth, radius, bool(pc.get("organic", false)), ragged)
	# Issue 484: a torn rim, not a clean outline: plating peeled outward in bent petals, some still glowing.
	if ragged and outline.size() >= 6 and radius > bounds.size.length() * 0.05:
		_cap_petals(cap, outline, centre, inward, radius, quantum, bool(pc.get("organic", false)), bounds.size.length())
	pc["cap_loops"] = int(pc["cap_loops"]) + 1


# True when a cap loop lies on the fracture plan's breaks or bite (a quarter of its points or more); with no plan
# (a Chorus rupture) every loop is a tear.
static func _loop_torn(plan: Dictionary, outline: PackedVector3Array) -> bool:
	if plan.is_empty(): return true
	var L: float = float(plan.get("L", 1.0))
	var bite: Dictionary = plan["bite"]
	var hits := 0
	var tried := 0
	for i in range(0, outline.size(), maxi(1, outline.size() / 16)):
		var q := outline[i]
		tried += 1
		var on := false
		for b in plan["breaks"]:
			if absf(_break_f(b, q)) < L * 0.06: on = true
		if not on and not bite.is_empty():
			var d: Vector3 = q - (bite["c"] as Vector3)
			on = Vector2(d.x / float(bite["rx"]), Vector2(d.y, d.z).length() / float(bite["ry"])).length_squared() < 2.2
		if on: hits += 1
	return hits * 4 >= tried


# A repeatable 0..1 value for a point (the same hull breaks the same way in a replay).
static func _rand01(p: Vector3, k: float) -> float:
	return fposmod(sin(p.dot(Vector3(12.9898, 78.233, 37.719)) + k * 17.31) * 43758.5453, 1.0)


# Bent plates peeled out from the torn rim: each spans a stretch of the outline, leans out of the face and away from
# its middle, and ends in a torn tooth. Half keep a hot rim (the slag rim glow), half are scorched dark plate. A Chorus
# rim gets torn flaps of skin instead (the organic slag colour).
static func _cap_petals(cap: Dictionary, outline: PackedVector3Array, centre: Vector3, inward: Vector3, radius: float, quantum: float, organic: bool, span_len: float) -> void:
	var m := outline.size()
	var step := maxi(1, m / 26)
	var i := 0
	var made := 0
	while i < m and made < 28:
		var span := step * (1 + int(_rand01(outline[i], 1.0) * 2.0))
		var j := (i + span) % m
		var a := outline[i]
		var b := outline[j]
		if a.distance_to(b) > quantum * 3.0 and _rand01(a, 2.0) < 0.62:
			var mid := (a + b) * 0.5
			var radial := mid - centre
			radial -= inward * radial.dot(inward)
			radial = radial.normalized() if radial.length() > 1e-6 else Vector3.ZERO
			var out := (radial * lerpf(0.4, 0.9, _rand01(mid, 3.0)) - inward * lerpf(0.5, 1.0, _rand01(mid, 4.0))).normalized()
			# bench round 1: long petals on a capital's big faces read as white lace; keep them short plates
			var reach := minf(minf(radius * lerpf(0.06, 0.18, _rand01(b, 5.0)), a.distance_to(b) * 1.6 + radius * 0.03), span_len * 0.025)
			# under a pixel and a half at the battle camera nobody sees it: skip the geometry
			if reach < STAGING_UNITS_PER_PIXEL * 1.5:
				i += maxi(span, 1)
				continue
			var along := b - a
			var a2 := a + out * reach * lerpf(0.55, 1.0, _rand01(a, 6.0)) + along * 0.12
			var b2 := b + out * reach * lerpf(0.35, 0.85, _rand01(b, 7.0)) - along * 0.18
			var tooth := (a2 + b2) * 0.5 + out * reach * lerpf(0.15, 0.45, _rand01(mid, 8.0)) + along * (_rand01(mid, 9.0) - 0.5) * 0.4
			var col := Color(0.3, 1.0 if _rand01(mid, 10.0) < 0.3 else 0.2, 0, 1)
			if organic: col = Color(0.3, 0.0, 0, 1)
			_cap_tri(cap, a, b, b2, col)
			_cap_tri(cap, a, b2, a2, col)
			_cap_tri(cap, a2, b2, tooth, col)
			made += 1
		i += maxi(span, 1)


static func _section_structure(cap: Dictionary, polygon: PackedVector2Array, centre: Vector3, x: Vector3, y: Vector3, inward: Vector3, depth: float, radius: float, organic: bool, ragged := false) -> void:
	var lo := polygon[0]
	var hi := lo
	for p in polygon:
		lo = lo.min(p); hi = hi.max(p)
	for vertical in ([false] if organic else [false, true]):
		for row in 3:
			var level := lerpf(lo.x if vertical else lo.y, hi.x if vertical else hi.y, float(row + 1) / 4.0)
			var hits: Array[float] = []
			for i in polygon.size():
				var a := polygon[i]
				var b := polygon[(i + 1) % polygon.size()]
				var av := a.x if vertical else a.y
				var bv := b.x if vertical else b.y
				if (av <= level and bv > level) or (bv <= level and av > level):
					var p := a.lerp(b, (level - av) / (bv - av))
					hits.append(p.y if vertical else p.x)
			hits.sort()
			for i in range(0, hits.size() - 1, 2):
				var a := Vector2(level, hits[i]) if vertical else Vector2(hits[i], level)
				var b := Vector2(level, hits[i + 1]) if vertical else Vector2(hits[i + 1], level)
				a = a.lerp(b, 0.08); b = b.lerp(a, 0.08)
				var pa := centre + x * a.x * 0.982 + y * a.y * 0.982 + inward * depth * 0.72
				var pb := centre + x * b.x * 0.982 + y * b.y * 0.982 + inward * depth * 0.72
				var width := minf(radius * 0.018, a.distance_to(b) * 0.045)
				if ragged:
					# issue 484: some decks and ribs run long, bent out past the torn skin
					var r1 := _rand01(pa, 11.0)
					if r1 < 0.55:
						var dir := (pb - pa).normalized()
						var ext := radius * lerpf(0.10, 0.28, _rand01(pb, 12.0))
						if ext < STAGING_UNITS_PER_PIXEL * 1.5: ext = 0.0
						if r1 < 0.27: pb += dir * ext - inward * ext * 0.55
						else: pa += -dir * ext - inward * ext * 0.55
				if organic:
					var mid := pa.lerp(pb, 0.5) - inward * radius * 0.035
					_cap_bone(cap, pa, mid, -inward, width, width * 1.3)
					_cap_bone(cap, mid, pb, -inward, width * 1.3, width * 0.65)
				else: _cap_rib(cap, pa, pb, -inward, width)


static func _cap_tri(cap: Dictionary, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var n := (b - a).cross(c - a)
	if not a.is_finite() or not b.is_finite() or not c.is_finite() or n.length_squared() < 1e-20: return
	n = n.normalized()
	cap["v"].append_array(PackedVector3Array([a, b, c]))
	cap["n"].append_array(PackedVector3Array([n, n, n]))
	cap["c"].append_array(PackedColorArray([color, color, color]))


static func _cap_rib(cap: Dictionary, a: Vector3, b: Vector3, n: Vector3, width: float) -> void:
	var along := b - a
	if along.length_squared() < 1e-12: return
	var side := along.normalized().cross(n) * width
	var lift := n * width * 1.8
	var p := [a - side, a + side, b + side, b - side, a - side + lift, a + side + lift, b + side + lift, b - side + lift]
	for f in [[0, 1, 2, 3], [4, 7, 6, 5], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]]:
		_cap_tri(cap, p[f[0]], p[f[1]], p[f[2]], Color(0.45, 0.1, 0, 1))
		_cap_tri(cap, p[f[0]], p[f[2]], p[f[3]], Color(0.45, 0.1, 0, 1))


static func _cap_bone(cap: Dictionary, a: Vector3, b: Vector3, n: Vector3, wa: float, wb: float) -> void:
	if a.distance_squared_to(b) < 1e-12: return
	var side := (b - a).normalized().cross(n).normalized()
	var up := side.cross((b - a).normalized())
	var ra := PackedVector3Array()
	var rb := PackedVector3Array()
	var col := Color(0.45, 0.0, 0.0, 1.0)
	for i in 6:
		var radial := side * cos(TAU * i / 6.0) + up * sin(TAU * i / 6.0)
		ra.append(a + radial * wa)
		rb.append(b + radial * wb)
	for i in 6:
		var j := (i + 1) % 6
		_cap_tri(cap, ra[i], ra[j], rb[j], col)
		_cap_tri(cap, ra[i], rb[j], rb[i], col)
	for i in range(1, 5):
		_cap_tri(cap, ra[0], ra[i + 1], ra[i], col)
		_cap_tri(cap, rb[0], rb[i], rb[i + 1], col)


# ---------------------------------------------------------------- the death

# fx.death books this under prof "death" (issue 616: it was booked here as well, so the profile showed twice the time).
static func death(fx, s, cause: String) -> float:
	return _death_inner(fx, s, cause)


static func _death_inner(fx, s, cause: String) -> float:
	if s.dead or s.gone: return 0.0
	s.dead = true
	var T: float = fx.now
	s.set_meta("death_wall_usec", Time.get_ticks_usec())   # issue 1232: the break's wait for a late cut is in real time
	s.remove_collider()
	if cause == "melt" and s.faction != "chorus": s.set_meta("death_melt", true)
	_debris_spec(s)
	s.set_meta("death_cause", cause)   # issue 1586 (fx_death_beats.gd)
	if s.squadron:
		return _wing_death(fx, s)
	# a metal acid kill's break and cook-off spark in its faction's colours (Neon on PR 1646); a Chorus acid kill stays green
	var tint := dcol(s, "spark", Color(0.95, 0.34, 0.08)) if cause != "melt" else (boom_col(s, "spark", Color(0.95, 0.34, 0.08)) if melting(s) else Color(0.55, 0.65, 0.12))
	_power_down(fx, s)
	s.set_meta("death_start", T)
	s.set_meta("death_hull_motion", s.hull_motion())
	s.engine_level = 0.0
	if not s.death_big: s._eng_cur = 0.0
	if s.death_big:
		# The tell starts inside the ship: the drive flares about a third brighter for two frames, then goes black.
		s._eng_cur = maxf(s._eng_cur, 1.0) * 1.33
		s.set_meta("death_flare_until", T + 2.0 / 60.0)
	if s.faction == "chorus" and cause != "board":
		# The skin ruptures under pressure and spills real hull fragments and spores. (issue 1586: a boarding scuttle
		# leaves a dead hulk instead, as for every faction: Codex review of PR 1666)
		s.set_meta("death_organic", true)
		s.set_meta("death_hulk", false)
		s.set_meta("death_spore_next", T)
		if "_vel" in s.root: s.set_meta("death_velocity", s.root.get("_vel"))
		if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
			precompute(fx, s, "rupture")
		if not s.death_big:
			s.set_meta("death_split", T + 0.35)
			fx.later(T + 0.35, func l_break_up() -> void: _break_up_when_ready(fx, s, "rupture", s.fac.damage_glow, T + 2.85))
			BEATS.cause_cues(fx, s, cause, T, 0.35)   # issue 1586: a ram or the star's pull still shows on the rupture
			return 0.95
		# Issue 1238 (F5.1): a Chorus cruiser, capital or Bio-Titan swells and bleeds spores for its class's length before
		# the skin gives, so it no longer pops like a drone; its timeline also gives it the kill slow-motion beat (fx.death).
		var otl := DeathTimeline.new(true, 1, s.death_tier, "rupture", true)
		s.set_meta("death_timeline", otl)
		s.set_meta("death_split", T + otl.cut)
		fx.later(T + otl.cut, func l_break_up() -> void: _break_up_when_ready(fx, s, "rupture", s.fac.damage_glow, T + otl.cut + 2.5))
		BEATS.cause_cues(fx, s, cause, T, otl.cut)
		return otl.end
	# Explicit burn-outs retain their cold hulk. Ordinary kills always break up.
	# issue 1586: a scuttled hull (boarding, the battle's view cause "board") also stays a dark hulk, never a reactor blast
	var hulk := cause == "dark" or cause == "hulk" or cause == "board"
	s.set_meta("death_hulk", hulk)
	if hulk:
		s.set_meta("death_split", T + 0.72)
		fx.later(T + 0.72, func l_hulk() -> void: _hulk(fx, s))
		return 1.32
	var timeline := DeathTimeline.new(s.death_big, int(s.get_meta("death_cut_count", 2)), s.death_tier, cause)
	s.set_meta("death_timeline", timeline)
	s.set_meta("death_split", T + timeline.cut)
	var inherited := Vector3.ZERO
	if "_vel" in s.root: inherited = s.root.get("_vel")
	s.set_meta("death_velocity", inherited)
	if cause == "cut" and s.death_big and s.faction != "chorus":
		_lance_recut(fx, s)
	if not s.has_meta("cut_task") and not s.has_meta("cut_job"):
		precompute(fx, s, cause)
	var job: Dictionary = s.get_meta("cut_job", {})
	var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
	var at: Vector3 = (seeds[0] + seeds[1]) * 0.5 if seeds.size() >= 2 else s.hull.core   # issue 370: the core, never the box centre
	var axis: Vector3 = (seeds[1] - seeds[0]).normalized() if seeds.size() >= 2 else Vector3.RIGHT
	# issue 1236 round 4 (Ryan, Nov 23: "we want variety"): a big strained hull breaks in two, in three, or in two and
	# then again a beat later. Only the joints that part at the death strain and tear.
	s.remove_meta("death_crack")
	s.remove_meta("death_glued_break")   # Neon's audit (PR 1902): set only by this death's layout, never carried over
	s.remove_meta("death_gap")           # Fable on 33561155: likewise
	var breakup := _pick_breakup(fx, s, cause, job)
	s.set_meta("death_breakup", breakup)
	var lines := _break_lines(job, _first_crack(s, job.get("plan", {})))
	if breakup in ["two", "late"]: lines = lines.slice(0, 1)
	if not lines.is_empty():
		at = lines[0][0]
		axis = lines[0][1]
	var melt := melting(s)
	if s.death_big and fx.death_story and not melt:
		_strain_begin(fx, s, T, timeline, seeds, lines)
	match str(dstyle(s).get("style", "")):
		"peel": _peel(fx, s, T, timeline)
		"drumbeat": _drumbeat(fx, s, T, timeline)
		"patch": _patch_tear(fx, s, T, timeline)
		"melt": _melt_glow(fx, s, T, timeline)
		# "arc" strikes from _break_up_inner, once the wreck really exists (a cold cut can split late: Artoo on 1399)
	if s.death_big and not melt:
		_tell(fx, s, T, timeline, cause, seeds, lines)
	var hit: Dictionary = s.hull.ray(at + Vector3.UP * s.hull.L, Vector3.DOWN) if s.death_big else _small_hit(fx, s)
	var lp: Vector3 = hit.get("p", at)
	var ln: Vector3 = hit.get("n", Vector3.UP)
	s.set_meta("death_tear", [lp, ln])
	fx.later(T + timeline.vent, func l_split_vent() -> void: _split_vent(fx, s, lp, ln))
	fx.later(T + timeline.cut, func l_break_up() -> void: _break_up_when_ready(fx, s, cause, tint, T + timeline.end))
	BEATS.on_death(fx, s, cause, T, timeline.cut)
	return timeline.end


# Issue 463: all small-death starts are real surface points, including a wing formation's gaps.
static func _small_hit(fx, s) -> Dictionary:
	var last: Array = s.get_meta("last_hit", [])
	if last.size() >= 3 and fx.now - float(last[2]) < 2.0:
		var dir: Vector3 = (last[1] as Vector3).normalized()
		var hit: Dictionary = s.hull.ray((last[0] as Vector3) - dir * s.hull.L, dir)
		if not hit.is_empty(): return hit
	return s.hull.surface_sample(-1, 2.0, "death")


static func _wing_death(fx, s) -> float:
	var hit := _small_hit(fx, s)
	s.engine_level = 0.0
	s._eng_cur = 0.0
	s.set_meta("death_split", fx.now)
	if not hit.is_empty():
		var p: Vector3 = s.to_world(hit["p"])
		# Birth on the next FX step: a one-frame picture born between steps could expire before its first draw.
		fx.later(fx.now + 0.000001, _wing_flash.bind(fx, s, p, s.xf()))
		BEATS.corkscrew(fx, s, p, s.xf())   # issue 1586
	_hide_ship(s)
	return 1.0 / 60.0


static func _wing_flash(fx, s, p: Vector3, frame: Transform3D) -> void:
	var soft: bool = fx.reduce_flashing or not fx.flash_at(p, fx.now, 28.0 * STAGING_UNITS_PER_PIXEL, 28.0, 1.0 / 60.0)
	_pic(fx, s, p, "weapons/impact/flash_", 28.0, 0.20 if soft else 1.0 / 60.0, 3.2, 1.25 if soft else 5.2, soft, "flash", frame, Vector3.ZERO, {"seed": 0})
	if not melting(s):
		fx.later(fx.now + 1.0 / 60.0, _smoke_one.bind(fx, s, p, 24.0, 0.22, frame, Vector3.ZERO, {"seed": 0}))


# Samples leave the spinning hit point in world space. Each new normal turns with the hull, curling the trail.
# Flame ends before 0.70 s from the hit; the final samples are dark gas. No trail pulse bypasses the flash counter.
static func _small_pose(s, motion: Transform3D) -> Transform3D:
	# The meshes already carry the spin. Apply it once to the analysis frame, never again through s.xf().
	return s.root.global_transform * motion * s.get_meta("death_hull_motion", Transform3D.IDENTITY)


static func _small_trail(fx, s, age: float, motion: Transform3D) -> void:
	if fx.quality == "low" or age >= 0.70 or age < float(s.get_meta("death_trail_next", 0.10)) or melting(s): return
	s.set_meta("death_trail_next", age + 0.10)
	var site: Array = s.get_meta("death_tear", [])
	if site.size() != 2: return
	var pose := _small_pose(s, motion)
	var p: Vector3 = pose * (site[0] as Vector3)
	var n: Vector3 = (pose.basis * (site[1] as Vector3)).normalized()
	var vel: Vector3 = s.get_meta("death_velocity", Vector3.ZERO) + n * s.hull.L * 0.35
	if age < 0.45:
		_pic(fx, s, p, "weapons/impact/impact_", 44.0, minf(0.30, 0.70 - age), 0.8, 1.0, false, "impact", pose, vel, {"seed": 0, "spin": age * 4.0, "shape": Vector2(0.65, 1.3)})
	else:
		flipbook(fx, p, n, s.hull.L * 0.25, "cool", 0.50, vel, 0.4, "small", s, false, false, pose)


# Death-only variation of the existing surface adapter. No R80 surface state changes.
# The running lights go out band by band: death_axis and death_span pick the direction (a cruiser bow to stern, a
# capital deck by deck from the top), death_steps holds (bands, delay per band, fade).
static func power_material(mat: ShaderMaterial, strain := false) -> ShaderMaterial:
	var code: String = mat.shader.code
	code = SH.patch(code, "uniform float fx_power = 1.0;", "uniform float fx_power = 1.0;\nuniform float death_age = 0.0;\nuniform float death_start = 0.0;\nuniform vec2 death_span = vec2(0.0, 1.0);\nuniform vec3 death_axis = vec3(1.0, 0.0, 0.0);\nuniform vec3 death_steps = vec3(3.0, 0.055, 0.18);\nuniform float death_hold = 0.0;" + (SH.STRAIN_FN if strain else ""))
	if strain:
		# Issue 1077 (prototype): the plating along the break lines bulges as the hull strains (death_age is the shader's
		# clock here, the same instant as the tear overlay's scene_t); fx_hull_p stays the unmoved point for the wounds.
		code = HULL._inject(code, "vertex", "", "\nVERTEX += inverse(mat3(fx_hull_frame)) * fx_strain_offset(fx_hull_p, normalize(mat3(fx_hull_frame) * NORMAL), death_age);\n")
	var band := "floor(clamp((dot(fx_hull_p, death_axis) - death_span.x) / death_span.y, 0.0, 0.999) * death_steps.x) * death_steps.y"
	# issue 1586 (Neon on PR 1666): death_hold hands the lights to fx_power (the Navy blackout) while death_age keeps
	# running the plating strain
	code = SH.patch(code, "clamp(fx_power, 0.0, 1.0)", "mix(1.0 - smoothstep(" + band + ", " + band + " + death_steps.z, death_age), clamp(fx_power, 0.0, 1.0), death_hold)")
	mat.shader = HULL.shared_shader(code, "death power down " + str(code.hash()))
	return mat


# Issue 616 (R118): the power-down materials (one damage material per hull surface, about 0.7 ms each on A16) were all
# built on the kill frame, 11 to 12 ms of it. The kill frame now builds them for POWER_BUDGET of main-thread time and
# the rest follow on the next fx steps, the same budget-and-carry-on pattern as the piece build (issue
# 600). The poses (the shudder and the spin) are all taken on the kill frame. A surface still waiting keeps its live
# material for a frame or two, while the first band's 0.15 s fade has barely begun; _update_dying sets death_age on each
# new material before it is drawn, so it starts at the same point of the fade it would have reached.
const POWER_BUDGET := 4000   # microseconds a frame; a tuning value, the same as PREBUILD_BUDGET
# Issue 1237 (Neon F7.3): POWER_BUDGET is one budget for the frame, shared by every dying ship (three capitals killed
# together spent 4 ms each, 12 ms in one frame). A ship whose turn finds the frame's budget spent waits for the next step;
# its live materials stay a frame longer, the same carry-on as before. Unchanged for a single death.
static func _power_left(fx) -> int:
	var frame: int = fx.step_count
	if int(fx.dstate.get("power_frame", -1)) != frame:
		fx.dstate["power_frame"] = frame
		fx.dstate["power_spent"] = 0
	return POWER_BUDGET - int(fx.dstate["power_spent"])

static func _power_down(fx, s) -> void:
	var mats: Array = []
	var poses: Array = []
	var queue: Array = []
	var inv: Transform3D = s.root.global_transform.affine_inverse()
	for mesh in s.meshes:
		if not is_instance_valid(mesh): continue   # a ship part freed under a live ship (1204 bot runs)
		var mi := mesh as MeshInstance3D
		if not is_instance_valid(mi) or mi.mesh == null: continue
		var pose: Transform3D = inv * mi.global_transform
		poses.append({"mi": mi, "pose": pose})
		queue.append({"mi": mi, "pose": pose, "prepared": []})
	s.set_meta("death_power", mats)
	s.set_meta("death_poses", poses)
	s.set_meta("death_power_queue", queue)
	s._reacting = false
	# issue 1239 (F2.3): a shield failure still playing (the volley that broke the shield also killed the ship) runs to
	# its end on the dying hull instead of vanishing on the kill frame; any other shield glow goes now
	s._shield_until = minf(s._shield_until, s._brk_until) if fx.now < s._brk_until else -1.0
	_power_down_step(fx, s, POWER_BUDGET)


# Build power-down materials from the queue for up to budget microseconds (a negative budget: all of them), then hand
# the rest to the next fx step. A mesh gets its materials all at once when its last surface is built.
static func _power_down_step(fx, s, budget: int) -> void:
	if not s.has_meta("death_power_queue"): return
	if s.has_meta("death_hidden") or not is_instance_valid(s.root) or fx.ships.get(s.id) != s:
		s.remove_meta("death_power_queue")
		return
	if budget >= 0:
		budget = mini(budget, _power_left(fx))
		if budget <= 0:
			fx.later(fx.now + 0.000001, func l_power_down_wait() -> void: _power_down_step(fx, s, POWER_BUDGET))
			return
	var t0 := Time.get_ticks_usec()
	var queue: Array = s.get_meta("death_power_queue")
	var mats: Array = s.get_meta("death_power", [])
	while not queue.is_empty():
		var q: Dictionary = queue[0]
		var mi := q["mi"] as MeshInstance3D
		if not is_instance_valid(mi) or mi.mesh == null:
			queue.pop_front()
			continue
		var prepared: Array = q["prepared"]
		var i: int = prepared.size()
		if i < mi.mesh.get_surface_count():
			var inside: bool = s.hull.authored and HULL.interior_material(mi.mesh.surface_get_material(i))
			var mat := _power_surface(fx, s, mi, i, q["pose"])
			prepared.append(mat)
			if not inside: mats.append(mat)
		if prepared.size() >= mi.mesh.get_surface_count():
			mi.material_override = null
			for k in prepared.size(): mi.set_surface_override_material(k, prepared[k])
			queue.pop_front()
		if budget >= 0 and Time.get_ticks_usec() - t0 > budget: break
	s.set_meta("death_power_max_usec", maxi(int(s.get_meta("death_power_max_usec", 0)), Time.get_ticks_usec() - t0))
	if budget >= 0:
		_power_left(fx)
		fx.dstate["power_spent"] = int(fx.dstate["power_spent"]) + Time.get_ticks_usec() - t0
	fx.pend("power_down", t0)
	if queue.is_empty():
		s.remove_meta("death_power_queue")
	else:
		# the next fx step, however slow the effect clock runs (a hit pause): a step always moves it on a little
		fx.later(fx.now + 0.000001, func l_power_down_step() -> void: _power_down_step(fx, s, POWER_BUDGET))


# One surface's power-down material (an inside surface of an authored hull: a dark copy of its own material).
static func _power_surface(fx, s, mi: MeshInstance3D, i: int, pose: Transform3D) -> Material:
	var source: Material = mi.get_active_material(i)
	if s.hull.authored and HULL.interior_material(mi.mesh.surface_get_material(i)):
		return fx.dark_interior(source)
	var template: ShaderMaterial = fx.hull_damage_template(source, s.hull.L, s.faction == "chorus", true)
	var mat: ShaderMaterial
	if source is ShaderMaterial and source.has_meta("fx_hull_source"):
		mat = source.duplicate()
		mat.shader = template.shader
		# Fable audit Nov 22, finding 1: the live surface may hold a hit brownout or the wound flicker (fx_flick); the death
		# copy starts at full light so the power-down beat, not a frozen dip, darkens the hull
		mat.set_shader_parameter("fx_flick", 1.0)
	else:
		mat = template.duplicate()
		HULL.set_damage_pose(mat, pose, {})
	var box: AABB = s.hull.box
	if s.death_tier == "capital":
		# deck by deck, top to bottom
		mat.set_shader_parameter("death_axis", Vector3.DOWN)
		mat.set_shader_parameter("death_span", Vector2(-(box.position.y + box.size.y), maxf(box.size.y, 0.01)))
		mat.set_shader_parameter("death_steps", Vector3(5.0, 0.12, 0.15))
	elif s.death_tier == "cruiser":
		# bow (+X) to stern
		mat.set_shader_parameter("death_axis", Vector3.LEFT)
		mat.set_shader_parameter("death_span", Vector2(-(box.position.x + box.size.x), maxf(box.size.x, 0.01)))
		mat.set_shader_parameter("death_steps", Vector3(4.0, 0.06, 0.12))
	else:
		mat.set_shader_parameter("death_span", Vector2(box.position.x, s.hull.L))
		mat.set_shader_parameter("death_steps", Vector3(1.0, 0.0, 0.001))
		mat.set_shader_parameter("death_age", 1.0)
		mat.set_shader_parameter("fx_power", 0.0)
	# issue 1077 (prototype): after the tier's own lights-out bands, never between them and their else (Fable on PR 1171)
	if s.death_big and s.has_meta("death_strain"):
		_strain_uniforms(mat, s.get_meta("death_strain"), 0.0)
	return mat


static func _split_vent(fx, s, lp: Vector3, ln: Vector3) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s or s.has_meta("death_hidden") or fx.quality == "low": return
	if melting(s): return   # R398: no vent jet, no ignition, no vapour
	# Issue 354: the gas root is the real plating, found the same way as the braking puffs since PR 327: cast from
	# outside, a further L along the tear normal, back toward the hull. A ray that misses has no plating behind it, so
	# skip the vent rather than float it beside the ship.
	var hit: Dictionary = s.hull.ray(lp + ln * s.hull.L, -ln)
	if hit.is_empty(): return
	if s.death_big:
		# issue 484: no pale vent puff beside a big hull (the issue 462 report); its first chain blast follows at once
		# and the tear's sparks stay.
		var pose_b: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
		tear_particles(fx, pose_b * (hit["p"] as Vector3), (pose_b.basis * (hit["n"] as Vector3)).normalized(), s.hull.L, s.get_meta("death_velocity", Vector3.ZERO), true, s)
		return
	var pose: Transform3D = _small_pose(s, s.get_meta("death_motion", Transform3D.IDENTITY))
	var p: Vector3 = pose * (hit["p"] as Vector3)
	var n: Vector3 = (pose.basis * (hit["n"] as Vector3)).normalized()
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var jet := flipbook(fx, p, n, s.hull.L * (0.35 if s.death_big else 0.85), "vent", 0.65 if s.death_big else 0.30, inherited + n * s.hull.L * 0.12, 1.3, atlas_band(s.hull.L), s, true)
	# The ignition and its light share one booking. Calm mode keeps dark gas. On a big hull the vent opens 0.04 s
	# before the first chain blast, so the two are one counted flash (FLASH_WINDOW).
	if fx.flash_at(p, fx.now, s.hull.L * 0.85, 44.0, 0.10):
		(jet.material_override as ShaderMaterial).set_shader_parameter("ignition", 1.0)
		fx.light(p, fx.now, 0.10, 5.0, Color(0.7, 0.81, 1.0), 0)
	tear_particles(fx, p, n, s.hull.L, inherited, false, s)


static func _update_dying(fx, s) -> void:
	if not s.dead or s.has_meta("death_hidden") or not s.has_meta("death_start") or not is_instance_valid(s.root): return
	var age: float = maxf(fx.now - float(s.get_meta("death_start")), 0.0)
	var mats: Array = s.get_meta("death_power", [])
	# issue 1586: a Navy hull keeps every light on through its tell, then all die on one frame (a tripped breaker)
	var black_at: float = float(s.get_meta("death_blackout_at", -1.0))
	for i in mats.size():
		var delay := float(i % 3) * 0.055
		if black_at >= 0.0:
			var lit: bool = fx.now < black_at
			(mats[i] as ShaderMaterial).set_shader_parameter("fx_power", 1.0 if lit else 0.0)
			(mats[i] as ShaderMaterial).set_shader_parameter("death_hold", 1.0)
			(mats[i] as ShaderMaterial).set_shader_parameter("death_age", age)
			continue
		(mats[i] as ShaderMaterial).set_shader_parameter("fx_power", 1.0 - smoothstep(delay, delay + 0.18, age) if s.death_big else 0.0)
		(mats[i] as ShaderMaterial).set_shader_parameter("death_age", age if s.death_big else 1.0)
	if bool(s.get_meta("death_organic", false)):
		if fx.now >= float(s.get_meta("death_spore_next", INF)):
			# Issue 1238: a big Chorus hull bleeds spores faster as it nears the rupture (0.06 s apart down to 0.03 s).
			var gap := 0.06
			if s.death_big and s.has_meta("death_timeline"):
				var otl: DeathTimeline = s.get_meta("death_timeline")
				gap = lerpf(0.06, 0.03, clampf(age / maxf(otl.cut, 0.01), 0.0, 1.0))
			s.set_meta("death_spore_next", fx.now + gap)
			var point: Dictionary = s.hull.random_sample(-1, 2.0)
			fx.spr(s.to_world(point.p), fx.now, 2.5, s.fac.damage_glow * Color(0.4, 0.5, 0.3), 0.35,
				s.hull.L * 0.015, s.hull.L * 0.13, 20, s.dir_world(point.n) * s.hull.L * 0.1, 0.65)
		if not s.death_big:
			return
	if bool(s.get_meta("death_hulk", false)): return
	var velocity: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var rot := Basis.IDENTITY if s.death_big else Basis.from_euler(Vector3(age * 0.65, age * 0.38, age * 0.54))
	var push := Vector3.ZERO
	match int(s.get_meta("death_arch", -1)):
		BEATS.ARCH_TORCH:
			# issue 1586: the over-flaring drive shoves the hull forward into an arcing spiral
			rot = Basis.from_euler(Vector3(age * 0.4, age * 2.4, age * 0.3))
			push = rot * Vector3(1, 0, 0) * s.hull.L * 0.9 * age * age
		BEATS.ARCH_ROLL:
			# a hard roll about the long axis, then a dead tumble
			rot = Basis.from_euler(Vector3(age * 3.4, age * 0.15, age * 0.12))
	var motion := Transform3D(rot, s.root.global_basis.inverse() * velocity * age + s.hull.c - rot * s.hull.c + push)
	if s.death_tier == "capital":
		# The capital's hull shudders through its tell (the ship itself, never the camera), harder after each blast.
		var tl: DeathTimeline = s.get_meta("death_timeline", null)
		if tl != null and age < tl.cut:
			var jolt: float = exp(-maxf(fx.now - float(s.get_meta("death_jolt", -10.0)), 0.0) / 0.12)
			var amp: float = s.hull.L * (0.0016 * smoothstep(0.2, 1.8, age) + 0.0035 * jolt)
			motion.origin += Vector3(sin(age * 57.0), sin(age * 71.0 + 1.3) * 0.5, sin(age * 63.0 + 2.1)) * amp
	s.set_meta("death_motion", motion)
	if not s.death_big: _small_trail(fx, s, age, motion)
	for pose in s.get_meta("death_poses", []):
		if is_instance_valid(pose["mi"]): (pose["mi"] as Node3D).global_transform = s.root.global_transform * motion * (pose["pose"] as Transform3D)


# A worker or budgeted piece build never blocks the split frame. Use a built previous cut if the worker is still
# running. With none, the hull holds its tell until its own cut is ready: issue 1232, a capital
# killed before its first cut was ready (A16's cut ran 5.4 s on the PC against a 2.67 s death) popped with no pieces.
# The wait is capped: a cut still running cold_cut_wall seconds of real time after the death ends in the no-pieces pop, so
# the kill camera and the turn (both wait for the core flash) never hold longer than that (Board on PR 1240: well under the
# first 12 s). A capital's death is 2.67 s, so a late cut adds at most about 2.3 s. Checked in fx/test/cold_kill_check.gd.
static var cold_cut_wall := 5.0   # a tuning value; fx/test/kill_slowmo_check.gd lowers it to test the pop

static func _break_up_when_ready(fx, s, cause: String, tint: Color, deadline: float) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s:
		fx.resolve_death_core(s, false)
		return
	var worker_done := finish_precompute(fx, s)
	var job: Dictionary = s.get_meta("cut_job", {})
	var prev: Dictionary = s.get_meta("cut_prev", {})
	if worker_done and job.get("built", false):
		_break_up(fx, s, cause, tint, job)
		return
	if not worker_done and prev.get("built", false):
		fx.discard_ship_cut(s)
		_break_up(fx, s, cause, tint, prev)
		return
	if not job.is_empty():
		var waited := float(Time.get_ticks_usec() - int(s.get_meta("death_wall_usec", Time.get_ticks_usec()))) / 1e6
		if fx.now < deadline or waited < cold_cut_wall:
			if fx.now >= deadline and not s.has_meta("death_cut_wait"):
				s.set_meta("death_cut_wait", fx.now)
				fx.notes.append("cut wait %s" % str(s.id))
			var step := 0.000001 if worker_done else 0.05
			fx.later(minf(fx.now + step, deadline) if fx.now < deadline else fx.now + step, func l_break_up() -> void: _break_up_when_ready(fx, s, cause, tint, deadline))
			return
	fx.discard_ship_cut(s)
	_break_up(fx, s, cause, tint, prev if prev.get("built", false) else {})


# ---------------------------------------------------------------- issue 462: the tell, chain blasts, the aftermath

# The direction the tear grows in (hull space, across the break plane): from the side that was hit to the far side.
# The last hit is read from fx_ship.hit_react; with none (or an old one) it grows from starboard.
static func _grow_dir(fx, s, axis: Vector3) -> Vector3:
	var h = s.hull
	var side := Vector3(0.0, 0.0, float(h.stb_z))
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 2.0:
		side = (last[0] as Vector3) - h.c
	side -= axis * side.dot(axis)
	side.y *= 0.35   # the tear runs across the beam more than over the top
	if side.length() < 1e-3: side = Vector3(0.0, 0.0, 1.0)
	return -side.normalized()


# Beat 1. A glowing tear on the hull's break line(s), growing from the hit side, white-hot at its tip and ember behind;
# chain blasts walk along it behind the tip; a capital shudders. Older hulls have no authored break lines, so the line
# is the game's own cut plane (the bisector of the prepared pieces, issue 167's fallback).
static func _tell(fx, s, T: float, tl: DeathTimeline, cause: String, seeds: PackedVector3Array, lines: Array = []) -> void:
	var h = s.hull
	var at: Vector3 = (seeds[0] + seeds[1]) * 0.5 if seeds.size() >= 2 else h.core   # opus_check_570 condition 1: the core, never the box centre
	var axis: Vector3 = (seeds[1] - seeds[0]).normalized() if seeds.size() >= 2 else Vector3.RIGHT
	if not lines.is_empty():
		# issue 484: the tear runs on the fracture plan's tilted breaks (the bite's break first)
		at = lines[0][0]
		axis = lines[0][1]
	var g := _grow_dir(fx, s, axis)
	var half: float = absf(g.y) * h.H * 0.5 + absf(g.z) * h.W * 0.5 + absf(g.x) * h.L * 0.5 + 0.05
	s.set_meta("death_grow", [g, half, at, axis])
	var m: ShaderMaterial = (fx.dstate["tear_mat"] as ShaderMaterial).duplicate() if fx.dstate.has("tear_mat") else fx.mat(SH.TEAR, 1)
	var strain: Dictionary = s.get_meta("death_strain", {})
	if not strain.is_empty() and fx.dstate.has("tear_strain_mat"):
		m = (fx.dstate["tear_strain_mat"] as ShaderMaterial).duplicate()
		_strain_uniforms(m, strain, T)
		m.set_shader_parameter("fx_hair", strain["hair"])
		m.set_shader_parameter("fx_jag", strain["jag"])
	m.set_shader_parameter("open_a", Vector2(T + tl.tear_open, T + tl.tear_full))
	m.set_shader_parameter("cut_at", at)
	m.set_shader_parameter("cut_axis", axis)
	s.remove_meta("death_line_b")
	# Fable on 33561155: a two or late breakup tears only its first joint, so the second line (and the chain blasts sent
	# to it) is drawn only when that joint parts at the death too, or on an old seed cut with no plan lines
	if seeds.size() >= 3 and (lines.is_empty() or lines.size() >= 2):
		# the second line of a capital opens a little later and finishes with the first
		var at_b: Vector3 = (seeds[1] + seeds[2]) * 0.5
		var axis_b: Vector3 = (seeds[2] - seeds[1]).normalized()
		if lines.size() >= 2:
			at_b = lines[1][0]
			axis_b = lines[1][1]
		m.set_shader_parameter("open_b", Vector2(T + tl.tear_open + 0.35, T + tl.tear_full))
		m.set_shader_parameter("cut_at_b", at_b)
		m.set_shader_parameter("cut_axis_b", axis_b)
		s.set_meta("death_line_b", [at_b, axis_b])
	m.set_shader_parameter("grow", g)
	m.set_shader_parameter("half_span", half)
	m.set_shader_parameter("width", maxf(h.L * 0.010, 0.02))
	if cause == "cut":
		m.set_shader_parameter("straight", 1.0)
		m.set_shader_parameter("ember", Vector3(1.0, 0.72, 0.45))
	elif cause == "melt":
		m.set_shader_parameter("tip", Vector3(0.62, 0.85, 0.18))
		m.set_shader_parameter("ember", Vector3(0.45, 0.62, 0.10))
	elif not dstyle(s).is_empty():
		# R367: the tear and its hairlines glow in the faction's death colour, white at the running tip
		var rim := dcol(s, "rim", Color(1.0, 0.36, 0.07))
		var tip := dcol(s, "fire", Color(1.0, 0.94, 0.82))
		m.set_shader_parameter("ember", Vector3(rim.r, rim.g, rim.b))
		m.set_shader_parameter("tip", Vector3(tip.r, tip.g, tip.b))
	for mm in s.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = m.duplicate()
			local.set_shader_parameter("frame", s.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local
	for i in tl.chain.size():
		fx.later(T + float(tl.chain[i]), _chain_blast.bind(fx, s, i, tl, cause, T))
	if not strain.is_empty():
		var groans: Array = strain["groans"]
		for i in groans.size():
			fx.later(T + float(groans[i]), _groan.bind(fx, s, i))


# The fracture plan's breaks as [at, normal] lines, the bite's break first; empty for the old seed cut.
static func _break_lines(job: Dictionary, first := -1) -> Array:
	var plan: Dictionary = job.get("plan", {})
	if plan.is_empty(): return []
	var brs: Array = plan["breaks"]
	var out: Array = []
	if first < 0: first = int(plan["bite_break"])
	if first < brs.size(): out.append([brs[first]["at"], brs[first]["n"]])
	for i in brs.size():
		if i != first: out.append([brs[i]["at"], brs[i]["n"]])
	return out


# ---------------------------------------------------------------- issue 1077: strain before the split (prototype)
# Off by default (fx.death_story; rendering/effects/death_story="strain"). Every big hull that breaks up (cruiser,
# capital, carrier, barge; every faction but the Chorus, whose rupture has its own story, and never a burnt-out hulk)
# strains along the same break lines its tear and its pieces use: the fracture plan's breaks, which follow the authored
# seams on a new-build hull and the game's own cut plane on an older one. Nothing new is cut or built: the plating in a
# narrow band round each line bulges and ripples (in the power-down material and the tear overlay, the same function),
# hairline cracks light along the lines, and between the chain blasts the hull groans: a spit of sparks, a breath of
# gas and now and then one small plate from a point on a line, with a jolt to the shudder. Then the existing split.
const STRAIN_AMP := 0.010      # of the length: the bulge at full strain (0.0045 did not read in the PC clip at 1236bbc3)
const STRAIN_BAND := 0.05      # of the length: half the width of the buckled band each side of a line
const STRAIN_RIPPLE := 0.06    # of the length: the ripple's wavelength
const STRAIN_JAG := 0.03       # of the length: how far the tear wanders off its straight cut (Ryan on pass 4B)
const STRAIN_PLATE := 0.045    # of the length: the plate size it steps across
const STRAIN_GROANS := {"capital": [0.28, 0.68, 1.02, 1.38, 1.72], "cruiser": [0.30, 0.62, 0.92, 1.20]}
# After the split: the main pieces part by about STORY_TRAVEL of the length and slow (STORY_DAMP a second), the thrown
# fragments slow faster, and the plate cloud is smaller and settles; a warm light sits in each gap for a few seconds so the
# torn decks read. Today's path drifts every piece at a constant speed for good.
const STORY_TRAVEL := 0.22
const STORY_DAMP := 0.5
const STORY_FRAG_DAMP := 0.9
const STORY_DEBRIS_DAMP := 0.8

# One warm light in each break's gap, riding the piece nearest it; the wreck fades it with its fires (update: 0.7 of the
# fire gate) and frees it with the wreck.
static func _gap_lights(fx, s, wreck: Dictionary, plan: Dictionary, xf: Transform3D, only := -1) -> void:
	if fx.quality == "low" or wreck["nodes"].is_empty(): return
	var spots: Array = []
	if not plan.is_empty():
		for bi in (plan["breaks"] as Array).size():
			if only < 0 or bi == only: spots.append(plan["breaks"][bi]["at"])   # issue 1236: only a joint that parted
	elif s.has_meta("death_strain"):
		for line in s.get_meta("death_strain")["lines"]: spots.append(line[0])
	for at in spots.slice(0, 3):
		var best: Node3D = null
		var bd := INF
		for nd in wreck["nodes"]:
			var dd: float = (nd.get_meta("piece_cen", Vector3.ZERO) as Vector3).distance_to(at)
			if dd < bd:
				bd = dd
				best = nd
		if best == null: continue
		var off: Vector3 = (at as Vector3) - (best.get_meta("piece_cen", Vector3.ZERO) as Vector3)
		wreck["lights"].append(fx.light_source(best, off, dcol(s, "rim", Color(1.0, 0.52, 0.22)), 0.7, 0.35))

static func _strain_begin(fx, s, T: float, tl: DeathTimeline, seeds: PackedVector3Array, lines: Array) -> void:
	var L: float = s.hull.L
	var use: Array = lines.duplicate()
	if use.is_empty():
		for i in maxi(seeds.size() - 1, 0):
			use.append([(seeds[i] + seeds[i + 1]) * 0.5, (seeds[i + 1] - seeds[i]).normalized()])
	if use.is_empty(): use.append([s.hull.core, Vector3.RIGHT])
	var at := PackedVector4Array()
	var nn := PackedVector4Array()
	for i in 3:
		if i < use.size():
			var a: Vector3 = use[i][0]
			var n: Vector3 = (use[i][1] as Vector3).normalized()
			at.append(Vector4(a.x, a.y, a.z, 1.0))
			nn.append(Vector4(n.x, n.y, n.z, L * STRAIN_BAND))
		else:
			at.append(Vector4.ZERO)
			nn.append(Vector4(1.0, 0.0, 0.0, 1.0))
	var full: float = maxf(tl.cut - 0.3, 0.5)
	var strain := {"at": at, "n": nn, "lines": use.slice(0, 3), "k": Vector3(L * STRAIN_AMP, TAU / maxf(L * STRAIN_RIPPLE, 0.001), 0.0),
		"t": Vector2(0.10, full), "hair": Vector3(maxf(L * 0.005, 0.005), TAU / maxf(L * 0.03, 0.001), 3.0),
		"jag": Vector2(L * STRAIN_JAG, L * STRAIN_PLATE),
		"groans": STRAIN_GROANS.get(s.death_tier, STRAIN_GROANS["cruiser"])}
	s.set_meta("death_strain", strain)
	# the power-down materials built on the kill frame so far; the rest pick it up as they are built (_power_surface)
	for m in s.get_meta("death_power", []):
		_strain_uniforms(m, strain, 0.0)


# The strain's uniforms on one material; `t0` is where its clock starts (0 for death_age, the death's start for scene_t).
static func _strain_uniforms(m: ShaderMaterial, strain: Dictionary, t0: float) -> void:
	m.set_shader_parameter("fx_strain_at", strain["at"])
	m.set_shader_parameter("fx_strain_n", strain["n"])
	m.set_shader_parameter("fx_strain_k", strain["k"])
	var t: Vector2 = strain["t"]
	m.set_shader_parameter("fx_strain_t", Vector2(t0 + t.x, t0 + t.y))


# One groan of the straining hull, at a point on one of its break lines (the plating found from outside, as the chain
# blasts find theirs). Dim on purpose: the chain blasts stay the loud beats.
static func _groan(fx, s, i: int) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var strain: Dictionary = s.get_meta("death_strain", {})
	if strain.is_empty(): return
	var h = s.hull
	var L: float = h.L
	var line: Array = strain["lines"][i % (strain["lines"] as Array).size()]
	var at: Vector3 = line[0]
	var n: Vector3 = line[1]
	var r := _death_rng(s)
	for k in i: r.randf()
	var across := n.cross(Vector3.UP)
	if across.length() < 0.1: across = n.cross(Vector3.FORWARD)
	across = across.normalized()
	var reach: float = absf(across.x) * h.L * 0.5 + absf(across.y) * h.H * 0.5 + absf(across.z) * h.W * 0.5
	var hit := {}
	for attempt in 3:
		var q: Vector3 = at + across * reach * r.randf_range(-0.8, 0.8)
		hit = h.ray(q + Vector3.UP * L, Vector3.DOWN) if attempt < 2 else h.ray(q + across * L, -across)
		if not hit.is_empty() and absf(((hit["p"] as Vector3) - at).dot(n)) <= L * STRAIN_BAND: break
		hit = {}
	if hit.is_empty(): return
	var pose: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
	var p: Vector3 = pose * (hit["p"] as Vector3)
	var nw: Vector3 = (pose.basis * (hit["n"] as Vector3)).normalized()
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	if fx.quality != "low":
		for k in 5:
			var d: Vector3 = (nw + fx.rdir() * 0.6).normalized()
			fx.spark(p, fx.now, 0.32 + 0.1 * fx.rng.randf(), s.faction, 2.6, L * 0.018, 0.035, inherited + d * L * fx.rng.randf_range(0.25, 0.45), 1.6, 1.5, 6.0, fx.SparkRole.DEATH)
		# (Ryan on pass 4B, "way too much smoke": the groans keep their sparks, the breath of gas is gone)
	if i % 2 == 1:
		_spawn_ship_debris(fx, s, p + nw * L * 0.015, inherited + nw * L * 0.05, 1, L * 0.008, 0.9)
	if s.death_tier == "capital":
		s.set_meta("death_jolt", fx.now)


# Where a point of the tear sits on the plating: on line A (or B for a capital's odd blasts), at s_frac across.
static func _tear_point(s, s_frac: float, line_b: bool) -> Dictionary:
	var gm: Array = s.get_meta("death_grow", [])
	if gm.size() < 4: return {}
	var g: Vector3 = gm[0]
	var half: float = gm[1]
	var at: Vector3 = gm[2]
	var axis: Vector3 = gm[3]
	if line_b and s.has_meta("death_line_b"):
		at = s.get_meta("death_line_b")[0]
		axis = s.get_meta("death_line_b")[1]
	var q: Vector3 = at + g * half * s_frac
	var L: float = s.hull.L
	var hit: Dictionary = s.hull.ray(q + Vector3.UP * L, Vector3.DOWN)
	if hit.is_empty():
		hit = s.hull.ray(q - g * L, g)
	if hit.is_empty(): return {}
	# keep it on the line even where the ray met a tower to one side of it
	if absf(((hit["p"] as Vector3) - at).dot(axis)) > L * 0.08: return {}
	return hit


static func _chain_blast(fx, s, i: int, tl: DeathTimeline, cause: String, T: float) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var n_chain := tl.chain.size()
	var line_b: bool = s.has_meta("death_line_b") and i % 2 == 1
	# Behind the tear's tip (it moves from -1.15 to 1.15 of the half span between tear_open and tear_full); a lance cut
	# is drawn at once, so its blasts simply walk the line.
	var u: float = (float(tl.chain[i]) - tl.tear_open) / maxf(tl.tear_full - tl.tear_open, 0.01)
	var frac: float = clampf(-1.15 + 2.3 * u - 0.2, -0.85, 0.85)
	if cause == "cut" or line_b:
		frac = lerpf(-0.7, 0.7, (float(i) + 0.5) / float(n_chain))
	var hit := _tear_point(s, frac, line_b)
	if hit.is_empty():
		hit = _tear_point(s, frac * 0.5, line_b)
	if hit.is_empty(): return
	var pose: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY)
	var p: Vector3 = pose * (hit["p"] as Vector3)
	var n: Vector3 = (pose.basis * (hit["n"] as Vector3)).normalized()
	# issue 484: the cruiser's chain blasts measured 24 to 57 px on the strip against a 75 px floor; drawn at 100 now
	# (an acid kill draws no chain; if one ever does, it is a cook-off in the faction's colours, Neon on PR 1646)
	_blast(fx, s, p, n, 100.0 if s.death_tier == "cruiser" else 84.0, boom_col(s, "spark", Color(1.0, 0.62, 0.28)), pose)
	# a narrow jet of fire, then gas, from the opened plating
	if fx.quality != "low":
		var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
		fx.spr(p + n * s.hull.L * 0.02, fx.now, 0.55, boom_col(s, "spark", Color(0.95, 0.5, 0.18)), 2.5, s.hull.L * 0.012, s.hull.L * 0.06, 20, inherited + n * s.hull.L * 0.25, 1.2)
	if s.death_tier == "capital":
		s.set_meta("death_jolt", fx.now)


# One staged picture from the route B pictures (the rebake of issue 426), sized in pixels at the battle camera. `frame`
# maps the source ship's own space to the world where the picture is born (a drifting wreck piece), for the stray guard.
static func _pic(fx, src, p: Vector3, rel: String, px: float, life: float, divisor: float, intensity: float, soft: bool, kind: String, frame = null, velocity := Vector3.ZERO, look := {}) -> MeshInstance3D:
	# The seed is picked here, as route_material picks it (the same random draw), so the pool key names the textures.
	var seed_i: int = int(look.get("seed", -1))
	if seed_i < 0: seed_i = fx.rng.randi_range(0, 2)
	var mi: MeshInstance3D = fx.picture("pic|" + rel + "|" + str(seed_i),
		func() -> ShaderMaterial: return route_material(fx, SH.DEATH_FLIPBOOK, rel, true, seed_i), "fx_beat_" + kind)
	mi.set_meta("fx_picture_kind", kind)
	mi.set_meta("gas_root", p)
	if frame is Transform3D: mi.set_meta("spawn_frame", frame)
	mi.extra_cull_margin = 100.0
	var mat := mi.material_override as ShaderMaterial
	mat.set_shader_parameter("pic_spin", float(look.get("spin", 0.0)))
	mat.set_shader_parameter("pic_shape", look.get("shape", Vector2.ONE))
	mat.set_shader_parameter("smoke_tone", float(look.get("tone", 1.0)))
	_style_pic(mat, src)
	mat.set_shader_parameter("born", fx.now)
	mat.set_shader_parameter("lifetime", life)
	mat.set_shader_parameter("extent", px * STAGING_UNITS_PER_PIXEL)
	mat.set_shader_parameter("min_pixels", px)
	mat.set_shader_parameter("size_divisor", divisor)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("soft_flash", 1.0 if soft else 0.0)
	mat.set_shader_parameter("velocity", velocity)
	mi.global_position = p
	fx.record_spawn(src, p, false, frame)
	fx.later(fx.now + life + 0.1, fx.free_picture.bind(weakref(mi), int(mi.get_meta("pic_gen"))))
	return mi


# A chain blast or a secondary: a flash with a hot core (the torpedo flash picture, scaled to its row), fire seen through
# gas behind it, a light on the hull it sits on and a few sparks off the plating. A refused or reduce-flashing flash
# draws its softened twin at the same size (0.50 s rise and fall, no full-heat hold). `pale`: the melt look, no hard
# white (always the softened picture).
static func _blast(fx, src, p: Vector3, n: Vector3, px: float, tint: Color, frame = null, pale := false) -> void:
	_boom += 1
	_blast_inner(fx, src, p, n, px, tint, frame, pale)
	_boom -= 1


static func _blast_inner(fx, src, p: Vector3, n: Vector3, px: float, tint: Color, frame = null, pale := false) -> void:
	if not p.is_finite(): return
	var soft: bool = pale or fx.reduce_flashing or not fx.flash_at(p, fx.now, px * STAGING_UNITS_PER_PIXEL, px, 0.16)
	_pic(fx, src, p, "weapons/impact/flash_", px, 0.50 if soft else 0.16, 0.97 if soft else 3.0, 1.25 if soft else 5.2, soft, "flash", frame)
	# issue 1077 (prototype): Ryan on pass 4B, "way too much smoke": a strained death's blasts keep one smaller puff
	if fx.death_story: _smoke_clump(fx, src, p, n, px * 0.6, 0.55, frame, 0.06, 1, 1)
	else: _smoke_clump(fx, src, p, n, px * 0.9, 0.70, frame, 0.06, 2, 3)
	fx.light(p + n * 0.6, fx.now, 0.40 if soft else 0.25, 5.0, tint, 0)
	if fx.quality != "low":
		var k: float = px * STAGING_UNITS_PER_PIXEL / 10.0
		for j in 5:
			fx.spark(p + n * 0.1, fx.now, 0.35 + fx.rng.randf() * 0.25, src.faction, 5.0, 0.05, 0.10, fx.rcone(n, 0.7) * (8.0 + fx.rng.randf() * 10.0) * k, 2.0, 0.0, 0.0, fx.SparkRole.DEATH)


# Issue 484 (owner, Nov 11, on the secondaries: "the secondary explosion smoke looks a little too even and weird"). One
# body picture per blast drew the same round puff, the same size, born together round the hull. Now each blast's smoke
# is a small clump: two to four pictures, one large and the rest a third to two thirds of it, born at staggered times,
# all on the blast point (rule 4: it starts on the ship) but drifting at different speeds into one side of the blast,
# turned and stretched differently, some darker. The asymmetric baked seed (s0, "shards") is preferred; the round seeds
# are stretched when used. Seeded per ship, so a replay matches. Fire stays inside the cap: lives only shrink.
const CORE_VEIL_DELAY := 0.45


# Issue 1558 item 2: the big-death gas veil, born after the core's full-heat window, so it never sits over the flash.
static func _core_gas_veil(fx, s, node_ref: WeakRef, local: Vector3, capital: bool, vel: Vector3) -> void:
	# born 0.45 s after the flash: read the piece where it is now (it drifts), and skip the veil if it is already gone
	var node := node_ref.get_ref() as Node3D
	if not is_instance_valid(node) or node.is_queued_for_deletion() or not node.is_inside_tree():
		return
	var p: Vector3 = node.to_global(local)
	var frame: Transform3D = node.global_transform * Transform3D(Basis.IDENTITY, -(node.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var gas := flipbook(fx, p, Vector3.UP, s.hull.L * (0.8 if capital else 0.7), "cool", 3.6 if capital else 3.0, vel, 0.38, atlas_band(s.hull.L), null)
	gas.set_meta("spawn_frame", frame)
	fx.record_spawn(s, p, false, frame)


static func _death_rng(s) -> RandomNumberGenerator:
	if s == null or not (s is Object) or not s.has_method("set_meta"):
		return RandomNumberGenerator.new()
	if not s.has_meta("death_rng"):
		var r := RandomNumberGenerator.new()
		r.seed = hash(str(s.id)) + 101
		s.set_meta("death_rng", r)
	return s.get_meta("death_rng")


static func _smoke_clump(fx, src, p: Vector3, n: Vector3, px: float, life: float, frame, delay: float, lo: int, hi: int) -> void:
	if dsmoke(src) < 0.02: return   # R367: a faction whose death has no smoke (the Glasswrights)
	if not p.is_finite(): return
	var r := _death_rng(src)
	var count := r.randi_range(lo, hi)
	var side := Vector3(r.randf_range(-1.0, 1.0), 0.0, r.randf_range(-1.0, 1.0))
	if side.length() < 0.1: side = Vector3.RIGHT
	side = (side - n * side.dot(n)).normalized()
	var units: float = px * STAGING_UNITS_PER_PIXEL
	for j in count:
		var size: float = px * (r.randf_range(0.85, 1.05) if j == 0 else r.randf_range(0.32, 0.68))
		var dir: Vector3 = (n * r.randf_range(0.3, 1.0) + side * r.randf_range(0.2, 1.1) + fx.rdir() * 0.25).normalized()
		var vel: Vector3 = dir * units * r.randf_range(0.10, 0.45) / maxf(life, 0.3)
		# the round baked seeds (s1, s2) read as a flower of equal puffs: the big picture is always the lopsided s0, and
		# only a small one may use a round seed, stretched
		var seed_i: int = 0 if (j == 0 or r.randf() < 0.75) else r.randi_range(1, 2)
		var look := {"seed": seed_i, "spin": r.randf() * TAU, "tone": r.randf_range(0.5, 1.3),
			"shape": Vector2(r.randf_range(1.2, 1.6), r.randf_range(0.6, 0.85)) if seed_i != 0 else Vector2(r.randf_range(0.85, 1.25), r.randf_range(0.85, 1.25))}
		var t: float = delay + (0.0 if j == 0 else r.randf_range(0.04, 0.32))
		var l: float = life * r.randf_range(0.75, 1.0)
		fx.later(fx.now + t, _smoke_one.bind(fx, src, p, size, l, frame, vel, look))


static func _smoke_one(fx, src, p: Vector3, px: float, life: float, frame, vel: Vector3, look: Dictionary) -> void:
	if dsmoke(src) < 0.02: return   # a death with no smoke (the Glasswrights, R398 acid)
	_pic(fx, src, p, "weapons/impact/impact_", px, life, 0.80, 2.0, false, "impact", frame, vel, look)


# Beat 2's flash: 0.28 s after the break, on the lip of the torn face. The core (route B, the tier's own row), the body
# (fire seen through gas, at most 0.70 s of fire, then gas that thins and drifts), shrapnel streamers along the plane of
# the break (a torpedo or ram: in a cone away from the impact) and, for an Eclipse death, the scene dim (R367).
static func _big_core(fx, s, node_ref: WeakRef, local: Vector3, R: float, tint: Color, cause: String, tl: DeathTimeline) -> void:
	var node := node_ref.get_ref() as Node3D
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		fx.resolve_death_core(s, false)
		return
	var p: Vector3 = node.to_global(local)
	var frame: Transform3D = node.global_transform * Transform3D(Basis.IDENTITY, -(node.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var capital := tl.tier == "capital"
	_core_flash(fx, p, R, 70.0, tint, null, Vector3.ZERO, s, tl.tier, frame)
	fx.resolve_death_core(s, true)
	var body_px := 380.0 if capital else 260.0
	# light first, then matter: the body is born as the core's full heat ends, so its smoke never covers the flash
	var away_l: Vector3 = (s.get_meta("death_grow", [Vector3.UP])[0] as Vector3)
	var away_w: Vector3 = (s.xf().basis * away_l).normalized() if away_l.length() > 0.01 else Vector3.UP
	# issue 1077 (prototype): Ryan on pass 4B, "way too much smoke". The strained wreck stays where it broke, so the core's
	# body and the gas over it sat on the wreck: no body puff and no gas veil
	var story: bool = fx.death_story
	# pass 5 (Ryan: no haze at the split): no body puff either; the chain blasts' small puffs are the smoke
	if not story and not melting(s): _smoke_clump(fx, s, p, (away_w + Vector3.UP * 0.5).normalized(), body_px, 2.0 if capital else 1.6, frame, 0.12, 3, 3)
	if fx.quality != "low":
		# pass 5: no gas veil on a strained death (Ryan: no haze at the split); the sparks below stay
		if not story and not melting(s):
			# Issue 1558 item 2: the veil is spawned 0.45 s late (light first, then matter). Moving `born` ahead after the
			# picture was made drew frame 0 at full alpha over the core flash, then the pool took it back while still visible.
			fx.later(fx.now + CORE_VEIL_DELAY, _core_gas_veil.bind(fx, s, node_ref, local, capital, s.get_meta("death_velocity", Vector3.ZERO) * 0.5))
		var gm: Array = s.get_meta("death_grow", [])
		var axis_w: Vector3 = (s.xf().basis * (gm[3] as Vector3)).normalized() if gm.size() >= 4 else s.xf().basis.x
		var away: Vector3 = (s.xf().basis * (gm[0] as Vector3)).normalized() if gm.size() >= 4 else Vector3.FORWARD
		var L: float = s.hull.L
		for j in (22 if capital else 16):
			var d: Vector3
			if cause == "big" or cause == "ram":   # shrapnel in a cone away from the impact (deaths_and_hits.md)
				d = fx.rcone(away, 0.55)
			else:
				d = fx.rdir()
				d = (d - axis_w * d.dot(axis_w)).normalized()
			fx.spark(p, fx.now + fx.rng.randf() * 0.05, 0.6 + fx.rng.randf() * 0.5, s.faction, 6.0, 0.06, maxf(L * 0.004, 0.05), d * L * fx.rng.randf_range(0.6, 1.3), 0.8, 2.0, 10.0, fx.SparkRole.DEATH)
	# R367 (issue 1399): a Glasswright's stored light spills as glittering dust; Eclipse's core gutters out and the scene
	# dims for an instant on every big Eclipse death (Eclipse only, R389: no other faction dims the scene)
	var style := str(dstyle(s).get("style", ""))
	if style == "shatter": _glitter(fx, s, p, s.hull.L)
	if style == "peel": fx.dim_scene(fx.now + 0.20)


# R367 (issue 1399): the Glasswrights' stored light spills from the core as glittering dust that drifts and fades slowly
# (deaths_and_hits.md, "How each faction dies": no fire and no smoke, glittering dust).
static func _glitter(fx, s, p: Vector3, L: float) -> void:
	if fx.quality == "low": return
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	for j in 36:
		var d: Vector3 = fx.rdir()
		d.y *= 0.4
		fx.spark(p + d * L * 0.04, fx.now + fx.rng.randf() * 0.35, 1.4 + fx.rng.randf() * 1.6, s.faction, 4.0, 0.02, maxf(L * 0.002, 0.03),
			inherited + d.normalized() * L * fx.rng.randf_range(0.04, 0.22), 0.7, 1.5, 3.0, fx.SparkRole.DEATH)


# R367 (issue 1399, Ryan's look pass): a styled faction's small hull has no smoke body, so its pop needs its own light: a
# short flash in the faction's light colour with a white star, and a ring of sparks in its spark colour. Its intensity
# (2.4) is under fx.FLASH_I, so fx.spr would not book it: it books itself (Artoo on PR 1400), and with reduce flashing or
# a full flash budget it becomes the same soft lift fx.spr gives a refused flash.
# R398: the acid's tell. Only where the acid hit (fx_weapons keeps the last MELT_SPOTS hull hits as "acid_spots"; the
# last hit, then a surface point, when none is recent), the plating glows sick green in a ragged patch that spreads until
# the hull parts. One overlay per mesh (the tear is not drawn on a melt death, so the overlay slot is free).
static func _melt_glow(fx, s, T: float, tl: DeathTimeline) -> void:
	var spots: Array = []
	var stored: Array = s.get_meta("acid_spots", [])
	for sp in stored:
		if T - float(sp[1]) <= 6.0: spots.append(sp[0])
	# Neon on PR 1646: an acid burn tick can kill a turn or more after the volley. Its stored hits are still where the
	# acid is, so the last three of them win over a later non-acid hit.
	if spots.is_empty():
		for sp in stored.slice(maxi(stored.size() - 3, 0)): spots.append(sp[0])
	if spots.is_empty():
		var last: Array = s.get_meta("last_hit", [])
		if last.size() >= 1: spots.append(last[0])
	if spots.is_empty():
		var hit := _small_hit(fx, s)
		if not hit.is_empty(): spots.append(hit["p"])
	var rad: float = s.hull.L * (0.10 if s.death_big else 0.24)
	var arr := PackedVector4Array()
	for i in 6:
		var v: Vector3 = spots[spots.size() - 1 - i] if i < spots.size() else Vector3.ZERO
		arr.append(Vector4(v.x, v.y, v.z, rad * (1.0 if i == 0 else 0.8)))
	var m: ShaderMaterial = fx.mat(SH.MELT_GLOW, 1)
	m.set_shader_parameter("spots", arr)
	m.set_shader_parameter("n_spots", mini(spots.size(), 6))
	m.set_shader_parameter("rise", Vector2(T - 0.05, T + maxf(tl.cut, 0.3)))
	s.set_meta("death_melt_spots", spots)
	for mm in s.meshes:
		if is_instance_valid(mm):
			var mi := mm as MeshInstance3D
			var local: ShaderMaterial = m.duplicate()
			local.set_shader_parameter("frame", s.root.global_transform.affine_inverse() * mi.global_transform)
			mi.material_overlay = local


static func _fac_pop(fx, s, p: Vector3, L: float) -> void:
	_boom += 1
	_fac_pop_inner(fx, s, p, L)
	_boom -= 1


static func _fac_pop_inner(fx, s, p: Vector3, L: float) -> void:
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var life := 0.32
	var kind := 0
	var i := 2.4
	if fx.reduce_flashing or not fx.flash_at(p, fx.now, L * 1.1, 64.0, life):
		kind = 18
		i *= 0.4
		life = 0.96
	fx._emit_spr(p, fx.now, life, dcol(s, "light", Color(0.9, 0.9, 1.0)), i, L * 0.25, L * 1.1, kind, inherited, 0.0, 0.0, 0.0, 64.0)
	if fx.quality == "low": return
	for j in 18:
		var d: Vector3 = fx.rdir()
		d.y *= 0.5
		fx.spark(p, fx.now + fx.rng.randf() * 0.04, 0.45 + fx.rng.randf() * 0.35, s.faction, 5.0, 0.03, maxf(L * 0.004, 0.04),
			inherited + d.normalized() * L * fx.rng.randf_range(0.5, 1.1), 0.9, 1.5, 5.0, fx.SparkRole.DEATH)


# R367 round 2 (issue 1399): the Sunward Crusade's magazines go off as an even row down the broadside during the tell, a
# drumbeat a quarter second apart (deaths_and_hits.md, "How each faction dies"): each a small ember pop on the plating with
# a spray of sparks. Small pops (under fx.FLASH_I), so they never spend the flash budget the core flash needs.
static func _drumbeat(fx, s, T: float, tl: DeathTimeline) -> void:
	var n := 7 if s.death_tier == "capital" else (5 if s.death_big else 3)
	var step: float = minf(0.25, maxf(float(tl.cut) * 0.9, 0.3) / float(n))
	# the broadside that faces the camera, so the row reads (Ryan's clip review, round 2)
	var side := 1.0
	if is_instance_valid(fx.camera): side = 1.0 if (s.xf().affine_inverse() * fx.camera.global_position).z >= s.hull.c.z else -1.0
	for b in n:
		fx.later(T + step * float(b), _drum_pop.bind(fx, s, b, n, side))


static func _drum_pop(fx, s, b: int, n: int, side: float) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var h = s.hull
	var x: float = h.box.position.x + h.L * (0.08 + 0.84 * (float(b) + 0.5) / float(n))
	var hit: Dictionary = h.ray(Vector3(x, h.c.y, h.c.z + side * h.W * 2.0), Vector3(0.0, 0.0, -side))
	if hit.is_empty(): return
	var pw: Vector3 = s.to_world(hit["p"])
	var nw: Vector3 = (s.xf().basis * (hit.get("n", Vector3(0.0, 0.0, side)) as Vector3)).normalized()
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	# issue 1752: one magazine pulse per accepted pop (a hidden hull or a missed ray above plays nothing)
	var sx = fx.sound() if fx.has_method("sound") else null
	if sx != null:
		sx.play("death_magazine", {"pos": pw, "death": true})
	fx.spr(pw + nw * h.L * 0.015, fx.now, 0.3, dcol(s, "light", Color(1.0, 0.78, 0.5)), 3.6, h.L * 0.04, h.L * 0.13, 0, inherited, 0.0, 0.0, 0.0, 24.0)
	for j in 8:
		fx.spark(pw, fx.now, 0.5, s.faction, 4.0, 0.05, maxf(h.L * 0.004, 0.04), inherited + (nw + fx.rdir() * 0.6).normalized() * h.L * 0.3, 0.8, 1.5, 6.0, fx.SparkRole.DEATH)


# R367 round 2: the Hullbreakers' patch plates tear loose during the tell, four to six of them spinning off from scattered
# spots on the hull (a frigate two), each a torn plate from the shared pool with its rim in the faction's colour.
static func _patch_tear(fx, s, T: float, tl: DeathTimeline) -> void:
	var n := 6 if s.death_tier == "capital" else (4 if s.death_big else 2)
	var span: float = maxf(float(tl.cut) * 0.85, 0.3)
	for b in n:
		fx.later(T + span * (float(b) + fx.rng.randf() * 0.6) / float(n), _patch_plate.bind(fx, s))


static func _patch_plate(fx, s) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var h = s.hull
	var x: float = h.box.position.x + h.L * fx.rng.randf_range(0.1, 0.9)
	var z: float = h.c.z + h.W * fx.rng.randf_range(-0.4, 0.4)
	var hit: Dictionary = h.ray(Vector3(x, h.c.y + h.L, z), Vector3.DOWN)
	if hit.is_empty(): return
	var pw: Vector3 = s.to_world(hit["p"])
	var nw: Vector3 = (s.xf().basis * (hit.get("n", Vector3.UP) as Vector3)).normalized()
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	_spawn_ship_debris(fx, s, pw + nw * h.L * 0.01, inherited + (nw + fx.rdir() * 0.4).normalized() * h.L * 0.09, 1, h.L * 0.035, STORY_DEBRIS_DAMP)
	fx.spark(pw, fx.now, 0.35, s.faction, 3.0, 0.04, maxf(h.L * 0.003, 0.03), nw * h.L * 0.15, 0.8, 1.5, 5.0, fx.SparkRole.DEATH)


# R367 round 2: the Hegemony Navy breaks with no fire in the gap: blue-white arcs jump it for a third of a second as the
# pieces part. Each arc runs from a point on one main piece's torn face to the nearest point on the next piece's torn face
# (their arc_sites, read at the strike, so the arc follows the pieces as they move), the shared lightning ribbon pinned at
# both ends. Called by _break_up_inner as the wreck is made, so a late cold cut still gets its arcs.
static func _arcs(fx, s) -> void:
	if fx.ships.get(s.id) != s or fx.quality == "low": return
	var wreck: Dictionary = {}
	for w in fx.dstate.get("wrecks", []):
		if w.get("id", "") == s.id and not w.get("hulk", false): wreck = w
	var nodes: Array = []
	for nd in wreck.get("nodes", []):
		if is_instance_valid(nd) and (nd as Node3D).has_meta("arc_sites"): nodes.append(nd)
	if nodes.size() < 2: return
	if s.has_meta("death_gap"):
		# issue 1236 round 4 (audit): across the crack that opened, not the joint a breakup keeps glued
		var gap: Array = s.get_meta("death_gap")
		var pair: Array = []
		for k in gap:
			for nd in nodes:
				if int(nd.get_meta("piece_i", -1)) == int(k): pair.append(nd)
		if pair.size() == 2: nodes = pair
	var n := 14 if s.death_tier == "capital" else (10 if s.death_big else 4)
	s.set_meta("death_arcs", [])
	for j in n:
		fx.later(fx.now + 0.36 * float(j) / float(n), _arc_strike.bind(fx, s, weakref(nodes[0]), weakref(nodes[1])))


static func _arc_strike(fx, s, ra: WeakRef, rb: WeakRef) -> void:
	var na = ra.get_ref()
	var nb = rb.get_ref()
	if not is_instance_valid(na) or not is_instance_valid(nb): return
	var sa: PackedVector3Array = (na as Node3D).get_meta("arc_sites")
	var sb: PackedVector3Array = (nb as Node3D).get_meta("arc_sites")
	if sa.is_empty() or sb.is_empty(): return
	# from a point on one face to one of the other face's points (not always the nearest), so the bolts cross the gap at
	# angles and read as lightning, not as cracks along the seam (Ryan's clip review, round 2)
	var a: Vector3 = (na as Node3D).to_global(sa[fx.rng.randi() % sa.size()])
	var b: Vector3 = (nb as Node3D).to_global(sb[fx.rng.randi() % sb.size()])
	var d: float = a.distance_to(b)
	if d < 1e-3: return
	var L: float = s.hull.L
	var col := dcol(s, "spark", Color(0.7, 0.88, 1.0))
	fx.rib(a, (b - a) / d, d, fx.now, 0.2, col, 3.4, maxf(L * 0.008, 0.08), maxf(L * 0.006, 0.06), 6)
	fx.spr(a, fx.now, 0.12, col, 2.4, L * 0.01, L * 0.03, 0, Vector3.ZERO, 0.0, 0.0, 0.0, 8.0)
	(s.get_meta("death_arcs", []) as Array).append([a, b, na, nb])


# R367 (issue 1399): an Eclipse hull peels during the tell: shade plates lift away band by band, a beat apart, from the
# stern forward (deaths_and_hits.md, "How each faction dies"). Each band throws two torn plates (the shared plate pool, its
# rim in the faction's colour) and a short spark off the plating.
static func _peel(fx, s, T: float, tl: DeathTimeline) -> void:
	var bands := 6 if s.death_tier == "capital" else (4 if s.death_big else 2)
	var span: float = maxf(float(tl.cut) * 0.85, 0.3)
	for b in bands:
		fx.later(T + span * float(b) / float(bands), _peel_band.bind(fx, s, b, bands))


static func _peel_band(fx, s, b: int, bands: int) -> void:
	if not is_instance_valid(s.root) or s.has_meta("death_hidden") or fx.ships.get(s.id) != s: return
	var h = s.hull
	var x: float = h.box.position.x + h.L * (float(b) + 0.5) / float(bands)
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	for k in 2:
		var z: float = h.c.z + (1.0 if k == 0 else -1.0) * h.W * fx.rng.randf_range(0.1, 0.4)
		var hit: Dictionary = h.ray(Vector3(x, h.c.y + h.L, z), Vector3.DOWN)
		if hit.is_empty(): continue
		var pw: Vector3 = s.to_world(hit["p"])
		var nw: Vector3 = (s.xf().basis * (hit.get("n", Vector3.UP) as Vector3)).normalized()
		_spawn_ship_debris(fx, s, pw + nw * h.L * 0.01, inherited + nw * h.L * 0.06, 1, h.L * 0.03, STORY_DEBRIS_DAMP)
		fx.spark(pw, fx.now, 0.35, s.faction, 3.0, 0.04, maxf(h.L * 0.003, 0.03), nw * h.L * 0.15, 0.8, 1.5, 5.0, fx.SparkRole.DEATH)


# Beat 3: secondaries on each piece, each lighting its own piece. They go off in groups, one per piece, 0.05 s apart,
# so a group counts as one flash (FLASH_WINDOW) and the budget keeps them bright; any the budget turns down draw soft.
static func _schedule_secondaries(fx, s, wreck: Dictionary, pieces: Array, seeds: PackedVector3Array, T: float, tl: DeathTimeline) -> void:
	var nodes: Array = wreck["nodes"]
	if nodes.is_empty() or tl.secondaries <= 0: return
	var h = s.hull
	var per: int = ceili(float(tl.secondaries) / float(nodes.size()))
	var groups: int = maxi(per, 1)
	var made := 0
	for j in nodes.size():
		var node: Node3D = nodes[j]
		var sites: PackedVector3Array = node.get_meta("sec_sites", PackedVector3Array())
		if sites.is_empty(): continue
		for k in groups:
			if made >= tl.secondaries: break
			# issue 484: not an even beat; each group lands up to 40 percent of a step early or late (seeded per ship)
			var step_t: float = (tl.sec_to - tl.sec_from) / maxf(groups - 1, 1)
			var jit: float = _death_rng(s).randf_range(-0.4, 0.4) * step_t if k > 0 else _death_rng(s).randf_range(0.0, 0.3) * step_t
			var t := T + tl.sec_from + step_t * k + jit + j * 0.05
			fx.later(t, _secondary_on.bind(fx, s, weakref(node), sites[k % sites.size()]))
			made += 1


# Up to five sites on one piece's own plating, facing up toward the battle camera, spread apart.
static func _piece_sites(h, seeds: PackedVector3Array, cen: Vector3, count: int, plan := {}, index := -1) -> PackedVector3Array:
	return _piece_sites_in(h.sp, h.sn, seeds, cen, count, plan, index)


# The same on plain arrays, so the worker cut can do it ahead of the death (issue 484 profiling: 2.4 ms per big break on
# the death frame in the sandbox).
static func _piece_sites_in(sp: PackedVector3Array, sn: PackedVector3Array, seeds: PackedVector3Array, cen: Vector3, count: int, plan := {}, index := -1) -> PackedVector3Array:
	var own := 0
	var best := INF
	for i in seeds.size():
		var d := cen.distance_to(seeds[i])
		if d < best:
			best = d
			own = i
	if not plan.is_empty() and index >= 0: own = index
	var cand := PackedVector3Array()
	for i in range(0, sp.size(), maxi(1, sp.size() / 400)):
		var q: Vector3 = sp[i]
		if sn[i].y < 0.25: continue
		var mine := 0
		if not plan.is_empty():
			# issue 484: the plan's own pieces; never a site in the bite (that plating is gone)
			if _plan_assign(plan, q) != _plan_main(plan, q): continue
			mine = _plan_main(plan, q)
		else:
			var bd := INF
			for k in seeds.size():
				var d := q.distance_to(seeds[k])
				if d < bd:
					bd = d
					mine = k
		if mine == own or seeds.size() < 2: cand.append(q)
	var out := PackedVector3Array()
	if cand.is_empty(): return out
	if plan.is_empty():
		out.append(cand[cand.size() / 2])
		while out.size() < count and out.size() < cand.size():
			var far := cand[0]
			var fd := -1.0
			for q in cand:
				var nd := INF
				for o in out: nd = minf(nd, q.distance_to(o))
				if nd > fd:
					fd = nd
					far = q
			out.append(far)
		return out
	# issue 484: not spread as far apart as possible (that made an even ring of blasts); random plating, seeded by the
	# piece, so blasts come in clumps and gaps
	var r := RandomNumberGenerator.new()
	r.seed = hash(Vector3i((cen * 100.0).round())) + index
	while out.size() < count:
		out.append(cand[r.randi_range(0, cand.size() - 1)])
	return out


static func _secondary_on(fx, s, node_ref: WeakRef, ship_p: Vector3) -> void:
	var node := node_ref.get_ref() as Node3D
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	var frame: Transform3D = node.global_transform * Transform3D(Basis.IDENTITY, -(node.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var p: Vector3 = frame * ship_p
	# issue 484: secondaries vary plainly in size (the playbook floor is 75 px)
	_blast(fx, s, p, frame.basis.y.normalized(), _death_rng(s).randf_range(76.0, 140.0), boom_col(s, "spark", Color(1.0, 0.6, 0.26)), frame)


static func _hide_ship(s) -> void:
	s.set_meta("death_hidden", true)
	s.remove_meta("death_power")
	s.remove_meta("death_poses")
	s.hide_live_hull()


# One independent copy of the damaged hull, no fracture upload, fire or lights.
# G2 may release its live ship root as soon as death()'s returned time expires.
static func _hulk(fx, s) -> void:
	if not is_instance_valid(s.root) or fx.ships.get(s.id) != s or s.has_meta("death_hidden"): return
	_power_down_step(fx, s, -1)   # issue 616: the copy takes the power-down materials, all of them (done long before, as a rule)
	var node := Node3D.new()
	node.name = "fx_hulk_" + s.id
	fx.phys_root.add_child(node)
	node.global_transform = s.xf()
	for source in s.meshes:
		if not is_instance_valid(source): continue   # a ship part freed under a live ship (1204 bot runs)
		var original := source as MeshInstance3D
		if not is_instance_valid(original) or original.mesh == null: continue
		var copy := MeshInstance3D.new()
		copy.mesh = original.mesh
		node.add_child(copy)
		copy.global_transform = original.global_transform
		for i in original.mesh.get_surface_count():
			var mat: Material = original.get_active_material(i).duplicate()
			if mat is ShaderMaterial: mat.set_shader_parameter("fx_power", 0.0)
			copy.set_surface_override_material(i, mat)
	# Keep the opaque wound backs and rims after the live ship is released.
	# Do not copy pooled lights, sparks or the live ship's other emitters.
	for child in s._dmg_root.get_children():
		if child is MeshInstance3D and child.name in ["fx_damage_inside", "fx_damage_marks"]:
			var copy := MeshInstance3D.new()
			copy.name = child.name
			copy.mesh = child.mesh
			copy.material_override = child.material_override
			copy.cast_shadow = child.cast_shadow
			node.add_child(copy)
			copy.global_transform = child.global_transform
	_hide_ship(s)
	var drift := node.basis.x * 0.45
	drift.y = 0.0
	# issue 1586: a burnout drifts dead with a gentle pitch and roll
	var dead_drift: bool = str(s.get_meta("death_cause", "dark")) == "dark"
	var wreck := {"id": s.id, "t0": fx.now, "nodes": [node], "mats": [], "lights": [],
		"fires": [{"node": node, "vel": drift, "ang": Vector3(0.05, 0.035, 0.04) if dead_drift else Vector3(0.01, 0.035, 0.015)}], "speed": 1.0, "hulk": true}
	var hit: Dictionary = s.hull.ray(s.hull.c + Vector3.UP * maxf(s.hull.L, 1.0), Vector3.DOWN)
	var p: Vector3 = hit.get("p", s.hull.core)   # issue 370: a missed ray falls back to the core, never a box point
	var n: Vector3 = hit.get("n", Vector3.UP)
	var b := POOLS.Batch.new()
	var size: float = maxf(s.hull.L * 0.025, 0.06)
	for j in 9:
		var v := n * size * 8.0
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, fx.now + j * 0.13),
			Vector4(v.x, v.y, v.z, 1.7), Vector4(0.22, 0.32, 0.06, 0.3) if s.faction == "chorus" else Vector4(0.42, 0.46, 0.5, 0.5),
			Vector4(size * 0.4, size * 3.2, 20 if s.faction == "chorus" else 7, 16.3), Vector4(0, 0, 0.5, 0)))
	b.build(fx.mat(SH.SPRITE, 1), node, "fx_hulk_vent")
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)
	BEATS.on_hulk(fx, s, node, str(s.get_meta("death_cause", "dark")))


static func _break_up(fx, s, cause: String, tint: Color, job := {}) -> void:
	var t0 := Time.get_ticks_usec()
	_break_up_inner(fx, s, cause, tint, job)
	fx.pend("break_up", t0)


static func _break_up_inner(fx, s, cause: String, tint: Color, job: Dictionary) -> void:
	var T: float = fx.now
	var h = s.hull
	var w: int = s.weight
	var k: float = s.scale_k()
	var organic: bool = s.faction == "chorus"
	var center: Vector3 = s.to_world(h.c)
	var pieces: Array = job.get("out", []) if job.get("out") != null else []
	var meshes: Array = job.get("meshes", [])
	var seeds: PackedVector3Array = job.get("seeds", PackedVector3Array())
	var plan: Dictionary = job.get("plan", {})
	var n_main: int = int(plan["n_main"]) if not plan.is_empty() else pieces.size()
	n_main = mini(n_main, pieces.size())
	var xf: Transform3D = s.xf() * s.get_meta("death_motion", Transform3D.IDENTITY) if s.death_big else _small_pose(s, s.get_meta("death_motion", Transform3D.IDENTITY))
	center = xf * h.c
	_hide_ship(s)
	var R: float = h.L * 0.16
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	if int(s.get_meta("death_arch", -1)) == BEATS.ARCH_TORCH and s.has_meta("death_start"):
		# issue 1586 (Neon on PR 1666): the torch's pieces keep the spiral's forward speed (the push's rate), capped
		var ta: float = maxf(fx.now - float(s.get_meta("death_start")), 0.0)
		var rot_t := Basis.from_euler(Vector3(ta * 0.4, ta * 2.4, ta * 0.3))
		inherited += (s.root.global_basis * (rot_t * Vector3(1, 0, 0) * h.L * 1.8 * ta)).limit_length(h.L * 1.2)
	# issue 1077 (prototype): the strained hull's wreck stays grouped where it broke
	var story: bool = fx.death_story and s.death_big and not organic
	# Ryan, Nov 21 2026 (in game): frigates and destroyers still broke apart wildly and their pieces spun off very far.
	# With the strained death on, a small metal hull's pieces part the same calm way as a big one's: slow, damped to rest
	# about a fifth of a length apart, turning mostly about the vertical, no shoving from each other
	var calm: bool = fx.death_story and not organic
	if organic:
		_organic_spill(fx, center, h.L, tint)
	elif calm:
		_spawn_ship_debris(fx, s, center, inherited, 2 + w * 2, h.L * 0.025, STORY_DEBRIS_DAMP)
	else:
		_spawn_ship_debris(fx, s, center, inherited, 4 + w * 3, h.L * 0.025, 0.0)
	fx.punch(T, 0.018 if s.death_big else 0.006, center)
	fx.shake(T, 0.45 if s.death_big else 0.18, center)
	# the pieces: real parts of the hull, as rigid bodies that drift and burn
	var wreck = {"id": s.id, "t0": T, "nodes": [], "mats": [], "lights": [], "fires": [], "speed": 1.0, "organic": organic, "heat_births": {}, "cut_events": []}
	var main_i = -1
	var main_n = -1
	for i in n_main:
		if int(pieces[i]["n"]) > main_n:
			main_n = int(pieces[i]["n"])
			main_i = i
	var phys = bool(fx.dstate.get("physics_on", false))
	# issue 1236 round 4: how this wreck breaks up (two, three or a late snap) and where each piece comes to rest
	var bu := _breakup_layout(fx, s, plan, pieces, n_main, xf, cause, inherited) if story else {}
	wreck["frags"] = []
	wreck["scorch_mats"] = []
	if melting(s):
		# R398 (1394 PC run): the main pieces' torn faces and scorched plating were built before the kill in the
		# faction's fire colours and showed orange embers where the acid hit. An acid wreck keeps the acid's green there.
		for i in n_main:
			var mp: Dictionary = pieces[i]
			if mp.has("cap_mat"): _style_heat(mp["cap_mat"], MELT_STYLE, "heat_")
			for hm in mp.get("hull_mats", []): (hm as ShaderMaterial).set_shader_parameter("fx_scorch_col", MELT_STYLE["rim"])
	for i in n_main:
		var pc: Dictionary = pieces[i]
		if (pc["surfs"] as Array).is_empty():
			continue
		var am: ArrayMesh = meshes[i]
		var cen: Vector3 = pc["cen"] if pc.has("cen") else Vector3.ZERO
		if not pc.has("cen"):
			for p in (pc["pts"] as PackedVector3Array):
				cen += p
			cen /= maxf((pc["pts"] as PackedVector3Array).size(), 1)
		var node: Node3D
		var is_main = i == main_i
		if phys:
			fx.wake_physics()
			var rb = RigidBody3D.new()
			rb.gravity_scale = 0.0
			rb.axis_lock_linear_y = true
			# Lock altitude at the chosen piece centre while its uneven shape tumbles.
			rb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			rb.mass = maxf(float(pc["n"]) / 400.0, 5.0)
			rb.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			rb.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
			# no engine damping: under Jolt it did not slow the pieces (PC clip at 1236bbc3: the strained pieces kept their
			# speed and drifted 1.9 L apart), so update() slows a strained piece itself, as it does the kinematic tiers
			rb.linear_damp = 0.0
			rb.angular_damp = 0.0
			rb.freeze = s.death_big and not organic
			rb.collision_layer = DEBRIS_LAYER
			# a strained wreck's slow pieces part along their break lines; touching neighbours shoved them a further 0.13 L apart
			rb.collision_mask = HULL_LAYER if calm else HULL_LAYER | DEBRIS_LAYER
			rb.physics_material_override = fx.dstate["bounce"]
			var pts: PackedVector3Array = pc["hull"] if pc.has("hull") else PackedVector3Array()
			if not pc.has("hull"):
				for p in (pc["pts"] as PackedVector3Array):
					pts.append(p - cen)
			if pts.size() >= 4:
				var cs = CollisionShape3D.new()
				cs.shape = pc["shape"] if pc.has("shape") else safe_convex(pts)
				rb.add_child(cs)
			node = rb
		else:
			node = Node3D.new()
		node.name = "fx_wreck_%s_%d" % [s.id, i]
		fx.phys_root.add_child(node)
		node.global_transform = Transform3D(xf.basis, xf * cen)
		node.set_meta("piece_cen", cen)
		node.set_meta("piece_i", i)   # issue 1236 round 4: the plan's piece, whatever pieces were skipped (audit)
		if float(pc.get("reach", -1.0)) >= 0.0: node.set_meta("reach_pre", float(pc["reach"]))   # issue 1395, _measure_reach
		if s.death_big and not organic:
			node.set_meta("sec_sites", pc["sec_sites"] if pc.has("sec_sites") else _piece_sites(h, seeds, cen, 5, plan, i))
		if s.death_big or is_main: wreck["scorch_mats"].append_array(pc.get("hull_mats", []))
		if not plan.is_empty() and not (plan["breaks"] as Array).is_empty():
			# issue 484: the seam this piece's torn face belongs to (the bite's break where it has one)
			var brs: Array = plan["breaks"]
			var fc := _first_crack(s, plan)
			var seam_b: int = clampi(fc if i in [fc, fc + 1] else mini(i, brs.size() - 1), 0, brs.size() - 1)
			pc["split_at"] = brs[seam_b]["at"]
			pc["split_axis"] = brs[seam_b]["n"]
			pc["split_width"] = h.L * 0.12
		elif s.death_big and not organic and seeds.size() >= 2:
			var seam := mini(i, seeds.size() - 2)
			pc["split_at"] = (seeds[seam] + seeds[seam + 1]) * 0.5
			pc["split_axis"] = (seeds[seam + 1] - seeds[seam]).normalized()
			pc["split_width"] = h.L * 0.04
		var mi = MeshInstance3D.new()
		mi.mesh = am
		mi.position = -cen
		node.add_child(mi)
		var piece_mats: Array = []
		if pc.has("cap_mat"):
			(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("heat", 0.0)
			# Issue 462: a big hull's torn face shows its decks glowing, not only the rim.
			(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("face_glow", 1.0 if not organic and (s.death_big or is_main) else 0.0)
			if fx.quality != "low" and not organic and (s.death_big or is_main): piece_mats.append(pc["cap_mat"])
		wreck["mats"].append_array(piece_mats)
		wreck["nodes"].append(node)
		var face_view := Vector3(0, 1, 1).normalized()
		if is_instance_valid(fx.camera): face_view = node.to_local(fx.camera.global_position).normalized()
		node.set_meta("tear_site", _edge_sites(pc, cen, face_view, 1)[0] + face_view * h.L * 0.02)
		# R367 round 2: a Hegemony break's arcs are pinned to points on each piece's own torn face (Artoo on PR 1418)
		if str(dstyle(s).get("style", "")) == "arc": node.set_meta("arc_sites", _edge_sites(pc, cen, face_view, 8))
		# Separate on the board plane while allowing each piece to tumble freely.
		var out: Vector3 = cen - h.c
		out.y = 0.0
		out = out.normalized() if out.length() > 0.01 else Vector3.RIGHT
		if organic:
			# Alternating lateral jets open the body as well as separating its length.
			out = (out + Vector3(0, 0, 0.9 if i % 2 == 0 else -0.9)).normalized()
		var spd: float = (3.5 if organic else ((1.6 if s.death_tier == "capital" else 2.8) if s.death_big else (0.7 if is_main else 2.1))) * maxf(k, 0.5)
		if calm:
			# each main piece parts by about STORY_TRAVEL of the length in all, most of it in the first two seconds
			spd = h.L * STORY_TRAVEL * STORY_DAMP * (0.8 if is_main else 1.0)
			node.set_meta("story_damp", STORY_DAMP)
		var vel: Vector3 = inherited + xf.basis * (out * spd) + fx.rdir() * (0.3 * k if not calm else h.L * 0.004)
		if cause == "tidal" and fx.well != Vector3.INF:
			vel += (fx.well - center).normalized() * 3.0 * k
		vel.y = 0.0
		# issue 484: the biggest piece of a big hull turns slowly, so it stays readable as the ship's main wreck
		var ang: Vector3 = fx.rdir() * ((0.14 if is_main else 0.35) if s.death_big or calm else (1.1 if is_main else 1.6))
		if (s.death_big or calm) and not organic:
			# Issue 461 (Board, on 484's cruiser at 6.0 s: "the big bow piece reads dim"): the main pieces tumbled on a
			# random axis and by 6 s showed the key light their dark bellies. They now turn mostly about the vertical, with
			# a slight roll and pitch, so their plated tops stay lit while they drift and turn.
			ang = Vector3(ang.x * 0.25, signf(ang.y + 0.001) * maxf(absf(ang.y), 0.08), ang.z * 0.25)
		if s.has_meta("death_spin"):
			# issue 1586: a ram kill spins its pieces hard and off centre, all the same way
			var sp: float = float(s.get_meta("death_spin"))
			ang += Vector3(0.25 * sp, (0.9 if is_main else 1.4) * sp, 0.15)
		var release_delay := 0.0
		if s.death_big and not organic:
			var timeline: DeathTimeline = s.get_meta("death_timeline")
			release_delay = mini(i, n_main - 2) * timeline.spacing
		if not bu.is_empty():
			# issue 1236 round 4: each piece is sent just hard enough that the brakes stop it on its planned rest spot,
			# turned to its planned angle (some lie diagonal), so the pieces spread across the hex and never run together
			# Fable on 33561155: the dying hull's own drift carries on and dies away with the rest (capped at a tenth of
			# the length, so a ship killed mid-move still settles in its hex)
			var disp_i: Vector3 = bu["disp"][i]   # the drift is in it (_breakup_layout), so the hex bound holds for it too
			vel = disp_i * BREAKUP_K_LIN
			# a pure turn on the board plane: any roll or pitch would lift a glued piece's end off the wreck's altitude
			ang = Vector3(0.0, float(bu["yaw"][i]) * BREAKUP_K_ANG, 0.0)
			release_delay = 0.0
			if i != int(bu["child"]): _set_rest(node, disp_i, float(bu["yaw"][i]))
			if i == int(bu["child"]):
				# glued to its neighbour across the joint that has not broken: it rides on that piece (two) until it
				# snaps (late); nothing is released for it here
				bu["child_node"] = node
				bu["child_mats"] = piece_mats
				continue
		var release_t := T + release_delay
		if node is RigidBody3D:
			if release_delay <= 0.0:
				_release_section(fx, wreck, node, vel, ang, piece_mats, h.L, s.death_big, i, s)
			else:
				wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": release_t})
				fx.later(release_t, _release_section.bind(fx, wreck, node, vel, ang, piece_mats, h.L, true, i, s))
		else:
			wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": release_t})
			fx.later(release_t, _release_section.bind(fx, wreck, node, vel, ang, piece_mats, h.L, s.death_big, i, s))
		if organic:
			if pc.has("cap_mat"):
				(pc["cap_mat"] as ShaderMaterial).set_shader_parameter("heat", 0.0)
			# Spores spill from the torn faces without metal sparks or burning plates.
			var sites := _edge_sites(pc, cen, Vector3(0, 1, 1).normalized(), 2)
			for site in sites:
				_organic_spill(fx, node.to_global(site), h.L * 0.35, tint)

	if not organic and s.has_meta("death_timeline"):
		wreck["cool"] = (s.get_meta("death_timeline") as DeathTimeline).cool
	if not bu.is_empty() and bu.has("child_node"):
		_glue(fx, s, wreck, bu)
	if story:
		_gap_lights(fx, s, wreck, plan, xf, -1 if bu.is_empty() or bu["kind"] == "three" else _first_crack(s, plan))
	fx.dstate["wrecks"].append(wreck)
	_cap_wrecks(fx)
	BEATS.on_break(fx, s, wreck, cause, center, xf)
	# R367 (issue 1399): Hegemony lightning jumps the gap the moment the pieces part, however late a cold cut split them
	# (Artoo on 1399: a timer from the nominal cut gave up after a second); a no-pieces pop has no gap and gets none
	if str(dstyle(s).get("style", "")) == "arc" and not organic: _arcs(fx, s)
	if organic:
		# Issue 1238: a big Chorus rupture is its kill beat. No fireball: the beat (and the death sound's low end) lands
		# just after the skin bursts.
		if s.death_big and s.has_meta("death_timeline"):
			fx.later(T + (s.get_meta("death_timeline") as DeathTimeline).core_delay, func l_rupture_beat() -> void:
				fx.resolve_death_core(s, fx.ships.get(s.id) == s))
		return
	if s.death_big and s.has_meta("death_timeline") and not wreck["nodes"].is_empty():
		# Beat 2: the core flash comes 0.28 s after the halves part, at the lip of the torn face; then beat 3.
		var tl: DeathTimeline = s.get_meta("death_timeline")
		var lip: Node3D = wreck["nodes"][0]
		var local: Vector3 = lip.get_meta("tear_site", Vector3.ZERO)
		if not plan.is_empty():
			# issue 484: the core goes off in the bite, on the piece nearest it; the bite's fragments and a cloud of
			# plates fly out from there.
			var bc: Vector3 = plan["bite"]["c"]
			var bd := INF
			for nd in wreck["nodes"]:
				var dd: float = (nd.get_meta("piece_cen", Vector3.ZERO) as Vector3).distance_to(bc)
				if dd < bd:
					bd = dd
					lip = nd
			local = bc - (lip.get_meta("piece_cen", Vector3.ZERO) as Vector3)
			_make_frags(fx, s, wreck, job, pieces, n_main, xf, inherited, T, T + tl.core_delay)
			fx.later(T + tl.core_delay, _throw_frags.bind(fx, s, wreck, plan, weakref(lip), tl))
		fx.later(T + tl.core_delay, _big_core.bind(fx, s, weakref(lip), local, R, tint, cause, tl))
		_schedule_secondaries(fx, s, wreck, pieces, seeds, T, tl)
		return
	var flash_site := center
	if not wreck["nodes"].is_empty():
		var lip: Node3D = wreck["nodes"][0]
		flash_site = lip.to_global(lip.get_meta("tear_site", Vector3.ZERO))
	if int(s.get_meta("death_arch", -1)) == BEATS.ARCH_ROLL:
		# issue 1586 (Neon on PR 1666): the roll dies without the big fireball: a small spark burst off the vent, no smoke
		BEATS.roll_end(fx, s, flash_site, inherited)
		fx.resolve_death_core(s, true)
		if pieces.is_empty():
			_spawn_ship_debris(fx, s, center, xf.basis.x * 2.0, 1, maxf(h.L * 0.15, 0.3), 0.0)
		return
	_core_flash(fx, flash_site, R, 70.0, tint, null, Vector3.ZERO, s, s.death_tier, xf)
	if str(dstyle(s).get("style", "")) == "shatter": _glitter(fx, s, flash_site, h.L * 0.6)
	if not dstyle(s).is_empty(): _fac_pop(fx, s, flash_site, h.L)
	fx.resolve_death_core(s, true)
	# The pop is light first, then a short body. The 384 px cells cover both small rows without a rebake.
	var body_px := 218.0 if s.death_tier == "destroyer" else 180.0
	fx.later(T + 0.12, _smoke_one.bind(fx, s, flash_site, body_px, 1.0, xf, inherited * 0.5, {"seed": 0}))
	if pieces.is_empty():
		# Restored by the Board (Muse opus_check_701 condition 1): a hull with no pre-cut pieces at the kill frame (a class
		# without buckets, or a cut job not ready) still throws one pooled physical shard and a visible ember, never light
		# and smoke alone.
		_spawn_ship_debris(fx, s, center, xf.basis.x * 2.0, 1, maxf(h.L * 0.15, 0.3), 0.0)
		fx.spr(center, T, 5.0, tint, 1.2, R * 0.3, R * 0.05, 19, xf.basis.x * 2.0, 0.25, 0.0, 0.0, 12.0)


# Issue 484: the bite's fragments and the chips along the break, as real pieces of the hull (capped, glowing faces,
# scorched plating). They ride with the wreck until the core flash, then fly out from the bite, tumbling fast. They
# are kinematic (no physics bodies): the 20-death fleet probe keeps its collider count.
static func _make_frags(fx, s, wreck: Dictionary, job: Dictionary, pieces: Array, n_main: int, xf: Transform3D, inherited: Vector3, T: float, hold_until: float) -> void:
	var meshes: Array = job["meshes"]
	for i in range(n_main, pieces.size()):
		var pc: Dictionary = pieces[i]
		if (pc["surfs"] as Array).is_empty(): continue
		var am: ArrayMesh = meshes[i]
		var cen: Vector3 = pc["cen"] if pc.has("cen") else Vector3.ZERO
		var node := Node3D.new()
		node.name = "fx_wreck_frag_%s_%d" % [s.id, i]
		fx.phys_root.add_child(node)
		node.global_transform = Transform3D(xf.basis, xf * cen)
		node.set_meta("piece_cen", cen)
		node.set_meta("chip", i >= n_main + int(job.get("plan", {}).get("bite", {}).get("subs", PackedVector3Array()).size()))
		var chips_d: Dictionary = job.get("plan", {}).get("chips", {})
		if bool(node.get_meta("chip")) and not chips_d.is_empty():
			node.set_meta("chip_break", (i - int(chips_d["first"])) / maxi(int(chips_d["per"]), 1))
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.position = -cen
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mi)
		if pc.has("cap_mat"):
			var cm := pc["cap_mat"] as ShaderMaterial
			cm.set_shader_parameter("heat", 0.0)
			cm.set_shader_parameter("face_glow", 0.5)
			if fx.quality != "low":
				wreck["mats"].append(cm)
				# small fragments start past white heat and go dark in about half the big pieces' time
				wreck["heat_births"][cm] = T - float(wreck.get("cool", WRECK_COOL)) * 0.35
		wreck["scorch_mats"].append_array(pc.get("hull_mats", []))
		wreck["frags"].append(node)
		wreck["fires"].append({"node": node, "vel": inherited, "ang": Vector3.ZERO, "until": hold_until})


static func _hold_chip(fx, wreck: Dictionary, nd: Node3D) -> void:
	var best: Node3D = null
	var bd := INF
	for m in wreck["nodes"]:
		if not is_instance_valid(m): continue
		var dd: float = (m as Node3D).global_position.distance_to(nd.global_position)
		if dd < bd:
			bd = dd
			best = m
	if best == null: return
	for f in wreck["fires"]:
		if f.get("node") == nd: f["until"] = fx.now
	wreck["frags"].erase(nd)
	nd.reparent(best, true)
	nd.set_meta("glued", true)
	if not wreck.has("held_chips"): wreck["held_chips"] = []
	wreck["held_chips"].append(nd)


static func _throw_frags(fx, s, wreck: Dictionary, plan: Dictionary, lip_ref: WeakRef, tl: DeathTimeline) -> void:
	var lip := lip_ref.get_ref() as Node3D
	if not is_instance_valid(lip) or lip.is_queued_for_deletion(): return
	var frame: Transform3D = lip.global_transform * Transform3D(Basis.IDENTITY, -(lip.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	var bite: Dictionary = plan["bite"]
	var bc: Vector3 = bite["c"]
	var out_l: Vector3 = bite["out"]
	var L: float = s.hull.L
	var inherited: Vector3 = s.get_meta("death_velocity", Vector3.ZERO)
	var held := int(s.get_meta("death_glued_break", -1))
	for nd in (wreck["frags"] as Array).duplicate():
		if not is_instance_valid(nd): continue
		if held >= 0 and int(nd.get_meta("chip_break", -1)) == held:
			# issue 1236 round 4 (audit): a chip on the joint that held stays in its notch, riding on the nearest main piece
			_hold_chip(fx, wreck, nd)
			continue
		var cen: Vector3 = nd.get_meta("piece_cen", Vector3.ZERO)
		var chip: bool = nd.get_meta("chip", false)
		var d: Vector3 = (cen - bc).normalized() * 0.6 + out_l * (0.5 if chip else 1.0)
		d += Vector3(fx.rng.randf_range(-0.3, 0.3), 0.0, fx.rng.randf_range(-0.3, 0.3))
		var dw: Vector3 = (frame.basis * d).normalized()
		dw.y *= 0.25
		if fx.death_story:
			# issue 1077 (prototype): thrown slower and slowed, so they settle round the break (about a fifth of the
			# length out at most) instead of crossing hexes
			var vs: Vector3 = inherited + dw.normalized() * L * fx.rng.randf_range(0.10, 0.20) * (0.7 if chip else 1.0)
			wreck["fires"].append({"node": nd, "vel": vs, "ang": fx.rdir() * fx.rng.randf_range(1.0, 2.4), "until": fx.now + 8.0, "frag": true,
				"damp": STORY_FRAG_DAMP, "adamp": 0.35})
			continue
		var v: Vector3 = inherited + dw.normalized() * L * fx.rng.randf_range(0.16, 0.34) * (0.7 if chip else 1.0)
		# they fly for 8 s (a few hull lengths, well spread), then rest, so a long battle does not move them forever
		wreck["fires"].append({"node": nd, "vel": v, "ang": fx.rdir() * fx.rng.randf_range(1.2, 3.0), "until": fx.now + 8.0, "frag": true})
	# a cloud of torn plates of several sizes, spreading and thinning between the pieces; born just outside the bite, so
	# the plates (physics bodies) never start inside a wreck piece's collider and kick it into a spin
	var p: Vector3 = frame * (bc + out_l * float(bite["ry"]) * 1.2)
	var big := tl.tier == "capital"
	if fx.death_story:
		_spawn_ship_debris(fx, s, p, inherited, 6 if big else 4, L * 0.012, STORY_DEBRIS_DAMP)
		_spawn_ship_debris(fx, s, p, inherited, 2, L * 0.03, STORY_DEBRIS_DAMP)
		return
	# Issue 484 profiling: each plate is a physics body; keep the cloud lean (it adds to the plates at the break)
	_spawn_ship_debris(fx, s, p, inherited, 10 if big else 7, L * 0.012, 0.0)
	_spawn_ship_debris(fx, s, p, inherited, 4 if big else 3, L * 0.03, 0.0)


# A fast radial spill of luminous spores and darker membrane clots, near the board.
static func _organic_spill(fx, p: Vector3, L: float, tint: Color) -> void:
	for i in 16:
		var angle: float = TAU * (i + fx.rng.randf() * 0.5) / 16.0
		var dir := Vector3(cos(angle), fx.rng.randf_range(0.0, 0.12), sin(angle))
		var speed: float = L * fx.rng.randf_range(0.2, 0.45)
		fx.spr(p, fx.now, 1.0 + fx.rng.randf() * 0.8, tint, 1.5,
			L * 0.018, L * 0.006, 19, dir * speed, 0.5, 0.0, 0.0, 6.0)
		if i % 2 == 0:
			fx.spr(p, fx.now, 1.4, tint * Color(0.24, 0.3, 0.18), 0.65,
				L * 0.025, L * 0.06, 20, dir * speed * 0.65, 0.7)
	fx.spr(p, fx.now, 0.45, tint, 1.8, L * 0.025, L * 0.16, 20, Vector3.ZERO, 0.0, 0.0, 0.0, 28.0)


# Issue 461: how far a death's core flash lights the hulls round it (world units; hexes are 17.3 across).
const CORE_LIGHT_REACH := {"small": 26.0, "destroyer": 30.0, "cruiser": 35.0, "capital": 52.0}


static func _core_flash(fx, p: Vector3, R: float, px: float, tint: Color, node: Node3D = null, local_p := Vector3.ZERO, src = null, band_override := "", frame = null) -> void:
	_boom += 1
	_core_flash_inner(fx, p, R, px, tint, node, local_p, src, band_override, frame)
	_boom -= 1


static func _core_flash_inner(fx, p: Vector3, R: float, px: float, tint: Color, node: Node3D = null, local_p := Vector3.ZERO, src = null, band_override := "", frame = null) -> void:
	if is_instance_valid(node): p = node.to_global(local_p)
	if not p.is_finite() or R <= 0.0: return
	# Main core flashes use the approved row. Issue 462: a cruiser or capital death uses its class's row
	# (band_override), whatever its drawn length.
	var staged: bool = px >= 70.0 and (src == null or not src.squadron)
	var band := atlas_band(float(src.hull.L) if src != null else R / 0.16)
	if src != null and not src.squadron: band = src.death_tier
	if band_override != "": band = band_override
	# Pixel targets, normal/soft life, then normal/soft size calibration including the battle look's bloom.
	var row: Array = {"small": [CORE_FLASH_PX["small"], 0.18, 0.55, 2.45, 0.884], "destroyer": [CORE_FLASH_PX["destroyer"], 0.19, 0.575, 2.31, 0.9175], "cruiser": [CORE_FLASH_PX["cruiser"], 0.20, 0.60, 1.97, 0.96], "capital": [CORE_FLASH_PX["capital"], 0.22, 0.65, 1.37, 0.96]}[band]
	if staged: px = float(row[0])
	var allowed: bool = fx.flash_ok(fx.now, p, px * STAGING_UNITS_PER_PIXEL if staged else R * 3.0, px, float(row[1]))
	if staged:
		var soft: bool = fx.reduce_flashing or not allowed
		var life: float = float(row[2] if soft else row[1])
		var flash := flipbook(fx, p, Vector3.UP, 0.0, "flash", life, Vector3.ZERO, 1.25 if soft else 6.0, band, src, false, true, frame)
		var mat := flash.material_override as ShaderMaterial
		mat.set_shader_parameter("min_pixels", px)
		mat.set_shader_parameter("extent", px * STAGING_UNITS_PER_PIXEL)
		mat.set_shader_parameter("size_divisor", float(row[4] if soft else row[3]))
		mat.set_shader_parameter("soft_flash", 1.0 if soft else 0.0)
		# Issue 461 (audit item 11): the core flash lights the hulls round it, about two hexes for a cruiser and three for
		# a capital, for the length of the flash (deaths_and_hits.md, beat 2)
		if not fx.reduce_flashing: fx.light(p, fx.now, float(row[1]), 9.0, dcol(src, "light", Color(0.65, 0.75, 0.91)), 0, CORE_LIGHT_REACH[band])
		return
	# Only this booking can produce a bright baked flash or its event light.
	if allowed:
		var flash := flipbook(fx, p, Vector3.UP, R * 3.0, "flash", 0.20, Vector3.ZERO, 6.0, atlas_band(R / 0.16), src)
		(flash.material_override as ShaderMaterial).set_shader_parameter("min_pixels", px)
		fx.light(p, fx.now, 0.12, 9.0, dcol(src, "light", Color(0.65, 0.75, 0.91)), 0, CORE_LIGHT_REACH[band])
	elif not melting(src):
		flipbook(fx, p, Vector3.UP, R * 2.8, "cool", 0.65, Vector3.ZERO, 0.5, atlas_band(R / 0.16), src)


# A released section has its own cooling clock. Neighbouring sections remain
# attached until their cut beat. The last cut releases the final pair together.
# ---------------------------------------------------------------- issue 1236 round 4: breakups (Ryan, Nov 23)
# "have the hulks break up a bit more into 3 pieces and spread them across the hex a bit, so some go more horizontal and
# diagonal to use the hex space more"; "it shouldn't always be the same 'scene' or event. we want variety". A strained big
# hull cut on two joints (fracture_plan) breaks one of three ways, picked from the ship, the cause and where it was hit, so
# a replay breaks the same way:
#   two:   one crack; the piece across the other joint stays glued on, a clean break in two
#   three: both joints part at the death
#   late:  one crack at the death, then the glued pair snaps BREAKUP_SNAP_S later with sparks at the joint
# Each released piece is sent so that the brakes (story damping plus MAIN_BRAKE) stop it on a planned rest spot: the end
# pieces out along the hull's line and to one side, the middle one sideways, each turned to its own angle, so the wreck
# fills the hex instead of sitting in one line, and the gaps open before the turns can swing a corner into a neighbour.
const BREAKUP_MIN_PART := 0.6   # the least share of its parting a planned piece keeps in a tight hex
const BREAKUP_HEX_REACH := 1.75  # rest radii: the farthest a planned piece's middle rests from its anchored hex
const SYNTH_YAW := 12.0         # degrees: how far an added breakup joint is turned off square
const BREAKUP_MIN := 0.15       # of the length: the smallest piece a breakup may leave (0.2 left most real hulls in two)
const BREAKUP_SNAP_S := 0.95    # seconds after the split: a late snap
const BREAKUP_K_LIN := STORY_DAMP + MAIN_BRAKE          # per second, how fast a planned piece's drift dies away
const BREAKUP_K_ANG := (STORY_DAMP + MAIN_BRAKE) * 0.5  # ... and its turn
const BREAKUP_WEIGHTS := {"cruiser": [0.35, 0.30, 0.35], "capital": [0.20, 0.40, 0.40]}   # two, three, late


static func _pick_breakup(fx, s, cause: String, job: Dictionary) -> String:
	var plan: Dictionary = job.get("plan", {})
	if not (fx.death_story and s.death_big and s.faction != "chorus") or plan.is_empty(): return ""
	if int(plan.get("n_main", 0)) != 3 or not bool(plan.get("breakup", false)): return ""
	# Artoo on PR 1737: the cut is made ahead (on load, then at most every CUT_REFRESH seconds as the hull takes damage),
	# so its bite follows an earlier hit. When the killing hit is nearer the other cut joint, that joint cracks first
	# (death_crack) and the bite's joint is the one that holds; no death-frame cut is ever added for it. The Board on
	# e26dab6c: forcing three there would have made three the most common breakup in a real fight.
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 1 and last[0] is Vector3:
		var brs: Array = plan["breaks"]
		var nb := 0
		for bi in brs.size():
			if _joint_gap(brs[bi], last[0]) < _joint_gap(brs[nb], last[0]): nb = bi
		if nb != int(plan["bite_break"]): s.set_meta("death_crack", nb)
	if s.has_meta("breakup_force"): return str(s.get_meta("breakup_force"))   # breakup_check and the look bench only
	# a ram's spin and the dead star's pull part all three at once (Fable on 33561155: the layout bails for both, so a
	# rolled two would strain one joint and part at both); a lance recut and a burnt-out hulk never get here
	if cause == "ram" or cause == "tidal": return "three"
	var kind := _pick_breakup_for(str(s.id), str(s.death_tier), s.get_meta("last_hit", []), cause)
	# Fable on 33561155: when the crack moved off the bite, the bite (its core flash, thrown fragments and plates) is on
	# the joint that holds, so that joint must give way too: a moved crack breaks late or in three, never in two
	if kind == "two" and s.has_meta("death_crack"): kind = "late"
	return kind


# The joint that cracks first: the bite's, or the joint nearest a killing hit that came after the cut (death_crack).
static func _first_crack(s, plan: Dictionary) -> int:
	if plan.is_empty(): return 0
	var c := int(s.get_meta("death_crack", -1))
	if c >= 0 and c < (plan["breaks"] as Array).size() and int(plan.get("n_main", 0)) == 3: return c
	return int(plan["bite_break"])


# the seeded pick itself: the ship, the cause and where it was last hit (a quarter-unit grid), so a replay matches
static func _pick_breakup_for(id: String, tier: String, last, cause: String) -> String:
	var r := RandomNumberGenerator.new()
	var hx := 0
	if last is Array and last.size() >= 1 and last[0] is Vector3:
		hx = int(round((last[0] as Vector3).x * 4.0)) * 131 + int(round((last[0] as Vector3).z * 4.0))
	r.seed = hash(id + "|" + cause + "|" + str(hx))
	var w: Array = BREAKUP_WEIGHTS["capital" if tier == "capital" else "cruiser"]
	var u := r.randf()
	return "two" if u < float(w[0]) else ("three" if u < float(w[0]) + float(w[1]) else "late")


# The rest spots, as displacements on the board plane from where each piece broke, and the turn about the vertical each
# piece makes on the way. disp and yaw are per main piece (x order); child is the piece glued across the unbroken joint.
static func _breakup_layout(fx, s, plan: Dictionary, pieces: Array, n_main: int, xf: Transform3D, cause := "blast", inherited := Vector3.ZERO) -> Dictionary:
	if n_main != 3 or plan.is_empty() or not bool(plan.get("breakup", false)): return {}
	# a ram's hard spin and the dead star's pull keep their own motion (audit: the plan overwrote them); three pieces part
	if s.has_meta("death_spin") or cause == "tidal": return {}
	var kind := str(s.get_meta("death_breakup", ""))
	# a late lance recut breaks on the cut it already had (cut_prev), which may hold three pieces: they part at once
	if kind == "": kind = "three"
	var L: float = s.hull.L
	var ax: Vector3 = xf.basis.x
	ax.y = 0.0
	ax = ax.normalized() if ax.length() > 0.01 else Vector3.RIGHT
	var lat := Vector3.UP.cross(ax).normalized()
	var r := RandomNumberGenerator.new()
	r.seed = hash(str(s.id) + "|layout|" + kind)
	var side := 1.0 if r.randf() < 0.5 else -1.0
	var d_ax := L * r.randf_range(0.09, 0.13)
	var d_lat := L * r.randf_range(0.07, 0.11)
	var disp: Array = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var yaw: Array = [0.0, 0.0, 0.0]
	var p := _first_crack(s, plan)                # the first crack: between pieces p and p + 1
	var lone := 0 if p == 0 else 2                # the piece the first crack frees
	var pair: Array = [1, 2] if p == 0 else [0, 1]
	var sizes: Array = plan["sizes"]
	var parent: int = pair[0] if float(sizes[pair[0]]) >= float(sizes[pair[1]]) else pair[1]
	var child: int = pair[1] if parent == pair[0] else pair[0]
	var out_lone := -ax if lone == 0 else ax
	if kind == "three":
		disp[0] = -ax * d_ax * 1.2 + lat * d_lat * side
		disp[2] = ax * d_ax * 1.2 + lat * d_lat * side * 0.6
		disp[1] = -lat * d_lat * 1.3 * side
		yaw[0] = r.randf_range(0.25, 0.45) * side
		yaw[1] = -r.randf_range(0.45, 0.70) * side
		yaw[2] = r.randf_range(0.20, 0.40) * -side
		child = -1
	else:
		# the lone piece goes out along the line and to one side; the glued pair backs off the other way and turns less
		disp[lone] = out_lone * d_ax * 1.3 + lat * d_lat * side
		yaw[lone] = r.randf_range(0.35, 0.60) * side
		disp[parent] = -out_lone * d_ax * 0.5 - lat * d_lat * 0.5 * side
		yaw[parent] = -r.randf_range(0.15, 0.30) * side
	var glued_b := 1 - p   # the joint that holds (two) or holds a beat (late)
	s.set_meta("death_gap", [p, p + 1])   # the pieces either side of the first crack (the Navy arcs jump that gap)
	if kind != "three": s.set_meta("death_glued_break", glued_b)
	var out := {"kind": kind, "disp": disp, "yaw": yaw, "child": child, "parent": parent, "lone": lone, "side": side,
		"glued_at": plan["breaks"][glued_b]["at"],
		"snap_disp": Vector3.ZERO,
		"snap_yaw": r.randf_range(0.30, 0.55) * -side, "d_ax": d_ax}
	if kind == "late" and child >= 0:
		# the snapped piece leaves the pair away from its parent, along the line
		var away := ax if child > parent else -ax
		out["snap_disp"] = away * d_ax * 1.1 + lat * d_lat * 0.7 * -side
	# Fable on 33561155: the dying hull's own drift carries on and dies away with the rest (capped at a twentieth of the
	# length, so a ship killed mid-move still settles in its hex). It is the same for every piece, so it never parts them.
	var drift: Vector3 = inherited / BREAKUP_K_LIN
	drift.y = 0.0
	drift = drift.limit_length(L * 0.05)
	# a long hull's end pieces already start far out of an anchored hex: their parting is shortened so no piece's middle
	# rests more than BREAKUP_HEX_REACH rest radii from the hex (wreck_hex_check, a dreadnought in a real battle)
	var an = (fx.dstate.get("anchors", {}) as Dictionary).get(s.id)
	if an != null:
		var reach: float = float(an["r"]) * BREAKUP_HEX_REACH
		var c0: Vector3 = an["c"]
		var bases: Array = []
		for i in n_main: bases.append(xf * _piece_cen(pieces[i]) - c0 + drift)
		# one shrink for every piece, turns included: shortening one piece's parting while it still turns in full swung
		# it into its neighbour (breakup_check, tight hex)
		var k := 1.0
		for i in n_main:
			if i != child: k = minf(k, _within_k(bases[i], disp[i], reach))
		if k < 1.0:
			for i in n_main:
				disp[i] = (disp[i] as Vector3) * k
				yaw[i] = float(yaw[i]) * k
		# Artoo on db791b40: where even the least parting leaves a middle out of reach (a piece starting near the edge,
		# the drift, or a late snap), the whole wreck's rest spots move in together, which keeps every gap between pieces.
		# Artoo on 951623ce: the move is found from the smallest circle round the rest spots, so it always fits when the
		# spots can fit at all: the least share of the way to that circle's centre on the hex; a wreck too long to fit
		# at all ends centred on its hex, as far out at each end.
		var spots: Array = []
		for i in n_main:
			var at: Vector3 = bases[i]
			if i == child:
				# it rides its parent, turning with it, then (late) snaps on from there
				var off: Vector3 = (bases[i] as Vector3) - (bases[parent] as Vector3)
				at = (bases[parent] as Vector3) + (disp[parent] as Vector3) + Basis(Vector3.UP, float(yaw[parent])) * off
				if kind == "late": at += out["snap_disp"]
			else: at += disp[i]
			spots.append(Vector2(at.x, at.z))
		var fit: Vector2 = _hex_fit(spots, reach)
		var shift := Vector3(fit.x, 0.0, fit.y)
		if shift != Vector3.ZERO: out["hex_shift"] = shift
		drift += shift
	for i in n_main: disp[i] = (disp[i] as Vector3) + drift
	return out


static func _piece_cen(pc: Dictionary) -> Vector3:
	if pc.has("cen"): return pc["cen"]
	var c := Vector3.ZERO
	var pts: PackedVector3Array = pc.get("pts", PackedVector3Array())
	for p in pts: c += p
	return c / maxf(pts.size(), 1)


# the share of the displacement d from base (BREAKUP_MIN_PART at least, so the pieces still clear each other) that keeps base + d within reach on the board plane
# the one move on the board plane that brings every spot within reach of the hex centre (the origin): none when they
# already are, else the least share of the way to the centre of the smallest circle round them; centred when they cannot fit
static func _hex_fit(spots: Array, reach: float) -> Vector2:
	if _farthest(spots, Vector2.ZERO) <= reach: return Vector2.ZERO
	var circ: Vector3 = _enclosing_circle(spots)   # x, y: the centre; z: the radius
	var to := -Vector2(circ.x, circ.y)
	if circ.z > reach: return to
	var lo := 0.0
	var t := 1.0
	for it in 24:
		var m := (lo + t) * 0.5
		if _farthest(spots, to * m) <= reach: t = m
		else: lo = m
	return to * t


# the farthest of the spots, each moved by d, from the hex centre (the origin)
static func _farthest(spots: Array, d: Vector2) -> float:
	var f := 0.0
	for p in spots: f = maxf(f, ((p as Vector2) + d).length())
	return f


# the smallest circle round two or three spots, as Vector3(centre x, centre y, radius)
static func _enclosing_circle(spots: Array) -> Vector3:
	var best := Vector3(0.0, 0.0, INF)
	for a in spots.size():
		for b in range(a + 1, spots.size()):
			var c: Vector2 = ((spots[a] as Vector2) + (spots[b] as Vector2)) * 0.5
			var r: float = ((spots[a] as Vector2) - c).length()
			if r < best.z and _farthest(spots, -c) <= r + 0.0001: best = Vector3(c.x, c.y, r)
	if spots.size() == 3:
		var A: Vector2 = spots[0]
		var B: Vector2 = spots[1]
		var C: Vector2 = spots[2]
		var dd := 2.0 * (A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y))
		if absf(dd) > 0.000001:
			var ux := (A.length_squared() * (B.y - C.y) + B.length_squared() * (C.y - A.y) + C.length_squared() * (A.y - B.y)) / dd
			var uy := (A.length_squared() * (C.x - B.x) + B.length_squared() * (A.x - C.x) + C.length_squared() * (B.x - A.x)) / dd
			var r := (A - Vector2(ux, uy)).length()
			if r < best.z: best = Vector3(ux, uy, r)
	if best.z == INF and not spots.is_empty(): best = Vector3((spots[0] as Vector2).x, (spots[0] as Vector2).y, 0.0)
	return best


static func _within_k(base: Vector3, d: Vector3, reach: float) -> float:
	var b2 := Vector2(base.x, base.z)
	var d2 := Vector2(d.x, d.z)
	if (b2 + d2).length() <= reach: return 1.0
	var lo := BREAKUP_MIN_PART
	var hi := 1.0
	if (b2 + d2 * lo).length() > reach: return lo
	for k in 12:
		var m := (lo + hi) * 0.5
		if (b2 + d2 * m).length() <= reach: lo = m
		else: hi = m
	return lo


# A planned piece's rest spot (board plane) and heading. _leash steers it there every frame: it moves at BREAKUP_K_LIN
# times what it has still to go and turns at BREAKUP_K_ANG times what it has still to turn, the same ease-out a drifting
# piece with drag has, but it ends on its spot whatever the slow motion, the physics step or the quality tier.
static func _set_rest(node: Node3D, disp: Vector3, yaw: float) -> void:
	var at: Vector3 = node.global_position + disp
	node.set_meta("rest_at", Vector2(at.x, at.z))
	node.set_meta("rest_yaw", heading(node) + yaw)


static func heading(node: Node3D) -> float:
	var x := node.global_basis.x
	return atan2(-x.z, x.x)


# The piece across the joint that did not break rides on its neighbour: a child of that piece's node, still frozen, so it
# moves and turns with it. A late breakup lets it go BREAKUP_SNAP_S later.
static func _glue(fx, s, wreck: Dictionary, bu: Dictionary) -> void:
	var child: Node3D = bu["child_node"]
	var parent: Node3D = null
	for nd in wreck["nodes"]:
		if is_instance_valid(nd) and int(nd.get_meta("piece_i", -1)) == int(bu["parent"]): parent = nd
	if not is_instance_valid(child) or not is_instance_valid(parent) or parent == child: return
	child.reparent(parent, true)
	child.set_meta("glued", true)
	# its torn face on the open crack heats with the rest (audit: it stayed dark and kept the wreck warm for good)
	for m in bu.get("child_mats", []): wreck["heat_births"][m] = fx.now
	# the snap spits from the joint that held, not the open crack's lip (audit)
	child.set_meta("snap_site", (bu["glued_at"] as Vector3) - (child.get_meta("piece_cen", Vector3.ZERO) as Vector3))
	if bu["kind"] != "late": return
	fx.later(fx.now + BREAKUP_SNAP_S, _snap.bind(fx, s, wreck, child, bu))


static func _snap(fx, s, wreck: Dictionary, child, bu: Dictionary) -> void:
	if not is_instance_valid(child) or child.is_queued_for_deletion() or not child.has_meta("glued"): return
	if not fx.dstate["wrecks"].has(wreck): return
	# Artoo on db791b40: the parent may still be on its way when the joint lets go (a long move in to the hex), so the
	# snapped piece's rest is taken from where it would ride to with its parent, not from where it is at the snap
	var disp: Vector3 = bu["snap_disp"]
	var yaw := float(bu["snap_yaw"])
	var pn = child.get_parent()
	if pn is Node3D and (pn as Node3D).has_meta("rest_at"):
		var ra: Vector2 = pn.get_meta("rest_at")
		var rem := wrapf(float(pn.get_meta("rest_yaw")) - heading(pn), -PI, PI)
		var off: Vector3 = child.global_position - (pn as Node3D).global_position
		off.y = 0.0
		var planned: Vector3 = Vector3(ra.x, 0.0, ra.y) + Basis(Vector3.UP, rem) * off
		disp += planned - Vector3(child.global_position.x, 0.0, child.global_position.z)
		yaw += rem
	child.reparent(fx.phys_root, true)
	child.remove_meta("glued")
	var L: float = s.hull.L
	var vel: Vector3 = disp * BREAKUP_K_LIN
	var ang := Vector3(0.0, yaw * BREAKUP_K_ANG, 0.0)
	_set_rest(child, disp, yaw)
	_release_section(fx, wreck, child, vel, ang, bu.get("child_mats", []), L, true, int(bu["child"]), s)
	# Neon's audit (PR 1902, item 12): the chips held in the joint's notch let go with it, thrown slow and settling round
	# the snap like the death's own chips (the leash keeps them in the hex), instead of riding a piece for good
	var site: Vector3 = child.to_global(child.get_meta("snap_site", child.get_meta("tear_site", Vector3.ZERO)))
	for nd in wreck.get("held_chips", []):
		if not is_instance_valid(nd) or nd.is_queued_for_deletion(): continue
		nd.reparent(fx.phys_root, true)
		nd.remove_meta("glued")
		var dw: Vector3 = (nd.global_position - site)
		dw.y = 0.0
		dw = (dw.normalized() if dw.length() > 0.01 else fx.rdir()) * 0.6 + vel.normalized() * 0.4
		dw.y *= 0.25
		wreck["frags"].append(nd)
		wreck["fires"].append({"node": nd, "vel": dw.normalized() * L * fx.rng.randf_range(0.06, 0.12), "ang": fx.rdir() * fx.rng.randf_range(0.8, 1.8),
			"until": fx.now + 8.0, "frag": true, "damp": STORY_FRAG_DAMP, "adamp": 0.35})
	wreck["held_chips"] = []
	# the joint lets go: a spit of sparks in the faction's colour and a short warm light at the torn face, no smoke
	var p: Vector3 = child.to_global(child.get_meta("snap_site", child.get_meta("tear_site", Vector3.ZERO)))
	if fx.quality != "low":
		for j in 10:
			fx.spark(p, fx.now + fx.rng.randf() * 0.06, 0.5 + fx.rng.randf() * 0.4, s.faction, 5.0, 0.05, maxf(L * 0.004, 0.05), fx.rdir() * L * fx.rng.randf_range(0.3, 0.8), 0.8, 2.0, 10.0, fx.SparkRole.DEATH)
	wreck["lights"].append(fx.light_source(child, child.get_meta("snap_site", child.get_meta("tear_site", Vector3.ZERO)), boom_col(s, "rim", Color(1.0, 0.52, 0.22)), 0.6, 0.3))   # one lookup with the sparks (Fable)
	fx.shake(fx.now, 0.12, p)


static func _release_section(fx, wreck: Dictionary, node: Node3D, vel: Vector3, ang: Vector3, mats: Array, L: float, big: bool, index: int, src = null) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion(): return
	if node is RigidBody3D:
		fx.wake_physics()
		node.freeze = false
		node.linear_velocity = vel * fx.anim_speed()
		node.angular_velocity = ang * fx.anim_speed()
		fx.later(fx.now + WRECK_PHYS_S, _wreck_leave_physics.bind(fx, wreck, node))
	elif node.has_meta("story_damp"):
		var dmp: float = node.get_meta("story_damp")
		wreck["fires"].append({"node": node, "vel": vel, "ang": ang, "damp": dmp, "adamp": dmp * 0.5})
	else:
		wreck["fires"].append({"node": node, "vel": vel, "ang": ang})
	for mat in mats: wreck["heat_births"][mat] = fx.now
	wreck["cut_events"].append({"section": index, "t": fx.now})
	if wreck.get("organic", false): return
	# issue 1077 (prototype): Ryan on pass 5, no haze at the split: a strained big hull's pieces part without the cool puff
	if fx.quality != "low" and not (big and fx.death_story) and not melting(src):
		flipbook(fx, node.to_global(node.get_meta("tear_site", Vector3.ZERO)), vel.normalized(), L * (0.35 if big else 0.5), "cool", 1.1, vel * 0.65, 0.4 if big else 0.7, atlas_band(L), src)
	if not big and src != null and fx.quality != "low":
		var p: Vector3 = node.to_global(node.get_meta("tear_site", Vector3.ZERO))
		fx.spark(p, fx.now, 0.65, src.faction, 4.0, 0.05, 0.08, vel + fx.rdir() * L * 0.55, 0.8, 2.0, 8.0, fx.SparkRole.DEATH)
	# Big hulls' secondaries are scheduled once per kill (_schedule_secondaries), never a per-piece fire loop.


# Issue 1237 (Neon F7.1): WRECK_PHYS_S after its release a wreck section leaves Jolt (it never slept: no damping) and
# drifts on with the velocity and turn it had, on the effect clock, as the kinematic tiers do. A strained wreck's pieces
# keep their damping. It no longer bounces off a hull it drifts into after that.
static func _wreck_leave_physics(fx, wreck: Dictionary, node) -> void:   # untyped: a piece may be freed before its timer
	if not is_instance_valid(node) or node.is_queued_for_deletion() or not (node is RigidBody3D): return
	var rb := node as RigidBody3D
	if rb.process_mode == Node.PROCESS_MODE_DISABLED: return
	var spd: float = maxf(fx.anim_speed(), 0.01)
	var entry := {"node": rb, "vel": rb.linear_velocity / spd, "ang": rb.angular_velocity / spd}
	# issue 1385 (Neon, PR 1383 F4): a strained piece's damping lives in its story_damp meta (Jolt damping is 0 on it,
	# see _break_up_inner), so it keeps slowing on the effect clock instead of drifting and turning forever
	if rb.has_meta("story_damp"):
		var dmp: float = rb.get_meta("story_damp")
		entry["damp"] = dmp
		entry["adamp"] = dmp * 0.5
	elif rb.linear_damp > 0.0:
		entry["damp"] = rb.linear_damp
		entry["adamp"] = rb.angular_damp
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.freeze = true
	rb.disable_mode = CollisionObject3D.DISABLE_MODE_REMOVE
	rb.process_mode = Node.PROCESS_MODE_DISABLED
	wreck["fires"].append(entry)


# Bounded samples from the actual cut, biased to its visible lip. No geometry work
# or unbounded hull scan is added to a death frame.
static func _edge_sites(pc: Dictionary, cen: Vector3, view: Vector3, count: int) -> PackedVector3Array:
	var src: PackedVector3Array = pc.get("edge", PackedVector3Array())
	if pc.has("lip"): src = pc["lip"]
	elif pc.has("cap"): src = pc["cap"][Mesh.ARRAY_VERTEX]
	if src.is_empty(): src = pc.get("pts", PackedVector3Array())
	var candidates := PackedVector3Array()
	for i in range(0, src.size(), maxi(1, src.size() / 128)):
		if src[i].is_finite(): candidates.append(src[i] - cen)
	if pc.has("split_at") and not candidates.is_empty():
		# A damaged hull's cap also contains old breach outlines. Keep only the
		# new split's band, or a top-facing breach can steal the core/fire sites.
		var axis: Vector3 = pc["split_axis"]
		var at: Vector3 = pc["split_at"] - cen
		var nearest := INF
		for p in candidates: nearest = minf(nearest, absf((p - at).dot(axis)))
		var seam := PackedVector3Array()
		for p in candidates:
			if absf((p - at).dot(axis)) <= nearest + maxf(float(pc["split_width"]), 0.001): seam.append(p)
		candidates = seam
	var sites := PackedVector3Array()
	if candidates.is_empty():
		sites.resize(count)
		return sites
	for j in count:
		var best := candidates[0]
		var score := -INF
		for p in candidates:
			var spread := INF
			for other in sites: spread = minf(spread, p.distance_to(other))
			var rank := p.dot(view) * (1.0 if j == 0 else 0.35) + (0.0 if j == 0 else spread)
			if rank > score:
				score = rank
				best = p
		sites.append(best)
	return sites


static func _cap_wrecks(fx) -> void:
	var ws: Array = fx.dstate["wrecks"]
	var anchors: Dictionary = fx.dstate.get("anchors", {})
	while ws.size() > 24:
		# issue 1236: the oldest wreck goes first, but a wreck that blocks its hex stays while any other can go
		var at := 0
		for i in ws.size():
			if not anchors.has(ws[i]["id"]):
				at = i
				break
		var w: Dictionary = ws.pop_at(at)
		_free_wreck(w)


static func _free_wreck(w: Dictionary) -> void:
	for l in w["lights"]:
		l["on"] = false
	for n in w.get("frags", []):
		if is_instance_valid(n):
			(n as Node).queue_free()
	for n in w["nodes"]:
		if is_instance_valid(n):
			(n as Node).queue_free()


static func clear_wreck(fx, id: String) -> void:
	fx.dstate.get("anchors", {}).erase(id)
	var ws: Array = fx.dstate["wrecks"]
	var keep: Array = []
	for w in ws:
		if w["id"] == id:
			_free_wreck(w)
		else:
			keep.append(w)
	fx.dstate["wrecks"] = keep


static func update(fx, dt: float) -> void:
	if not fx.dstate.has("wrecks"):
		return
	# issue 1236: a blocking wreck's new pieces are measured where they were made, before anything below moves them
	_leash_mark(fx)
	for ship in fx.ships.values(): _update_dying(fx, ship)
	_settle_debris(fx)
	_debris_speed(fx)
	for w in fx.dstate["wrecks"]:
		var speed: float = maxf(fx.anim_speed(), 0.01)
		var prev: float = float(w.get("speed", 1.0))
		for nd in w["nodes"]:
			if is_instance_valid(nd) and nd is RigidBody3D:
				var f := speed / prev
				var fa := f
				if nd.has_meta("story_damp") and not (nd as RigidBody3D).freeze:
					# issue 1077 (prototype): a strained wreck's physics pieces slow and settle where it broke
					var dmp: float = nd.get_meta("story_damp")
					f *= exp(-dmp * dt)
					fa *= exp(-dmp * 0.5 * dt)
				(nd as RigidBody3D).linear_velocity *= f
				(nd as RigidBody3D).angular_velocity *= fa
		w["speed"] = speed
		var age: float = fx.now - float(w["t0"])
		# Heat fades over a few seconds. The cold opaque cap remains.
		# Issue 484 profiling: a wreck now has up to a dozen glowing faces and its scorched plating. Heat falls by about a
		# tenth a second, so faces are set 15 times a second, not every frame, and a wreck that has gone cold is never
		# visited again (material updates also cost the renderer).
		var cool_t: float = float(w.get("cool", WRECK_COOL))
		if not bool(w.get("cold", false)) and fx.now >= float(w.get("heat_next", -INF)):
			w["heat_next"] = fx.now + 1.0 / 15.0
			var births: Dictionary = w.get("heat_births", {})
			var any_warm := false
			for m in w["mats"]:
				var birth: float = births.get(m, INF)
				var heat := 0.0 if birth == INF else clampf(1.0 - (fx.now - birth) / cool_t, 0.0, 1.0)
				(m as ShaderMaterial).set_shader_parameter("heat", heat)
				if heat > 0.0 or birth == INF: any_warm = true
			var scorch_heat := clampf(1.0 - age / cool_t, 0.0, 1.0)
			for m in w.get("scorch_mats", []):
				(m as ShaderMaterial).set_shader_parameter("fx_scorch_heat", scorch_heat)
			# cold for good once every face has cooled and nothing is still waiting for its release
			if not any_warm and scorch_heat == 0.0 and age > 1.0: w["cold"] = true
		var gate = exp(-maxf(age, 0.0) / 3.5)
		for f in w["fires"]:
			if f.has("mat"):
				(f["mat"] as ShaderMaterial).set_shader_parameter("gate", exp(-maxf(age, 0.0) / maxf(float(f.get("cool", 3.5)), 0.01)))
			elif f.has("node") and is_instance_valid(f["node"]) and fx.now < float(f.get("until", INF)):
				# Kinematic tiers retain the same constant momentum as physics tiers.
				var n: Node3D = f["node"]
				if f.has("damp"):
					# issue 1077 (prototype): a strained wreck's pieces slow and settle where it broke
					f["vel"] = (f["vel"] as Vector3) * exp(-float(f["damp"]) * dt)
					f["ang"] = (f["ang"] as Vector3) * exp(-float(f["adamp"]) * dt)
				var v: Vector3 = f["vel"]
				n.global_position += v * dt
				var a: Vector3 = f["ang"]
				if a.length() > 1e-5:
					n.global_rotate(a.normalized(), a.length() * dt)
		for l in w["lights"]:
			l["base"] = 0.7 * gate
	# issue 1236: a wreck that blocks its hex stays in it
	_leash(fx, dt)


# ---------------------------------------------------------------- wrecks that block their hex (issue 1236)
# The rules turn a dead cruiser or capital's hex into a wreck that blocks movement and fire (rules "wreck" event). The
# battle anchors that death here, so its pieces, fragments and plates come to rest inside the hex instead of drifting
# across the board. A piece's middle brakes from LEASH_SOFT of its rest limit and never drifts past it; a piece past it
# (a long hull overhangs its hex) is drawn back in, and nothing is ever farther out than where it was born or the rest
# radius. The rest radius (0.8 of the hex radius) is inside the hex's flat edges (0.87).
# Ryan, Nov 20 00:45 UTC (option 1 on 1236): a dreadnought's wreck sits inside its one hex, done by shrinking the wreck.
# Nov 22 he saw it and called it bad, then saw the next try (the biggest piece drawn to the hex centre, the rest
# crumbling) fold one half into the other and called that cheesy and broken. Now the hull's main pieces are never pulled,
# shrunk or removed: they part as they broke and MAIN_BRAKE brings them to rest close together, as in the approved
# one-crack death (issue 1077); on a cruiser or capital they overlap the next hexes, which the rules do not block. The
# small fragments and thrown plates still settle inside the hex (LEASH_*).
const LEASH_SOFT := 0.6        # share of the rest limit where a piece's brake starts
const LEASH_BRAKE := 4.0       # per second, the brake at the rest limit (it ramps up from zero at LEASH_SOFT)
const LEASH_PULL := 1.5        # per second: a piece past its rest limit comes back in at this share of the gap
const LEASH_SHRINK_FROM := 1.5 # seconds after the break: the fragments start to draw in
const MAIN_BRAKE := 1.2        # per second: the hull's main pieces slow to rest where they parted (a part speed of v stops in about v / 1.2)
const LEASH_SETTLED := 5.5     # seconds after the break: each fragment is held hard inside the rest radius


# The battle calls this on the rules "wreck" event, before the death plays. radius: the hex's rest radius in world units.
static func anchor_wreck(fx, id: String, centre: Vector3, radius: float) -> void:
	if not fx.dstate.has("anchors"): fx.dstate["anchors"] = {}
	fx.dstate["anchors"][id] = {"c": centre, "r": radius}


# how many pieces of a ship's wreck are still on the board (the battle's fallback hull when a death left none)
static func wreck_pieces(fx, id: String) -> int:
	var n := 0
	for w in fx.dstate.get("wrecks", []):
		if w["id"] != id: continue
		for nd in w["nodes"]:
			if is_instance_valid(nd) and not nd.is_queued_for_deletion(): n += 1
	return n


# every piece of an anchored wreck: its main pieces, its fragments and the plates it threw
static func leashed_nodes(fx, id: String, main_only := false) -> Array:
	var out: Array = []
	for w in fx.dstate.get("wrecks", []):
		if w["id"] != id: continue
		for nd in w["nodes"] + ([] if main_only else w.get("frags", [])):
			if is_instance_valid(nd): out.append(nd)
	if main_only: return out
	for b in fx.dstate.get("debris", []):
		if is_instance_valid(b) and b.visible and _debris_leash(b) == id: out.append(b)
	return out


static func _debris_leash(body: RigidBody3D) -> String:
	return body.get_meta("debris_piece", {}).get("leash", "")


static func _leash_mark(fx) -> void:
	var anchors: Dictionary = fx.dstate.get("anchors", {})
	if anchors.is_empty(): return
	for w in fx.dstate["wrecks"]:
		var an = anchors.get(w["id"])
		if an == null: continue
		for nd in w["nodes"] + w.get("frags", []):
			if is_instance_valid(nd): _born(nd, an)
	for b in fx.dstate.get("debris", []):
		if not is_instance_valid(b) or not b.visible: continue
		var an = anchors.get(_debris_leash(b))
		if an != null: _born(b, an)


static func _leash(fx, dt: float) -> void:
	if dt <= 0.0: return
	var anchors: Dictionary = fx.dstate.get("anchors", {})
	# Ryan, Nov 22 (third look): the hull's main pieces are never pulled, shrunk or removed. They part as they broke and a
	# brake brings them to rest close together where they are (MAIN_BRAKE), so nothing slides into anything. Issue 1236
	# round 4: a planned breakup's pieces are steered to their rest spots (_steer) anchored or not; any other main piece
	# brakes only on an anchored wreck, so an unanchored small hull's approved calm parting is unchanged.
	var brake := exp(-MAIN_BRAKE * dt)
	var abrake := exp(-MAIN_BRAKE * 0.5 * dt)   # Artoo on PR 1737: the halves stop turning too, a little slower
	for w in fx.dstate["wrecks"]:
		var an = anchors.get(w["id"])
		var drawing: bool = fx.now >= float(w["t0"]) + LEASH_SHRINK_FROM
		for f in w["fires"]:
			if not (f.has("vel") and f.has("node") and is_instance_valid(f["node"]) and fx.now < float(f.get("until", INF))): continue
			if (f["node"] as Node).has_meta("rest_at"):
				var st := _steer(f["node"])
				f["vel"] = st[0]
				var fa: Vector3 = f.get("ang", Vector3.ZERO)
				f["ang"] = Vector3(fa.x * abrake, st[1], fa.z * abrake)
				continue
			if w["nodes"].has(f["node"]):
				if an == null: continue   # an unanchored wreck without a planned breakup drifts as before (audit)
				f["vel"] = (f["vel"] as Vector3) * brake
				if f.has("ang"): f["ang"] = (f["ang"] as Vector3) * abrake
			elif an != null:
				f["vel"] = _leash_vel(f["node"], f["vel"], an, dt, drawing)
		for nd in w["nodes"]:
			if is_instance_valid(nd) and nd is RigidBody3D and not (nd as RigidBody3D).freeze:
				var rb := nd as RigidBody3D
				if rb.has_meta("rest_at"):
					var st := _steer(rb)
					var spd: float = fx.anim_speed()
					rb.linear_velocity = (st[0] as Vector3) * spd
					rb.angular_velocity = Vector3(rb.angular_velocity.x * abrake, float(st[1]) * spd, rb.angular_velocity.z * abrake)
				elif an != null:
					rb.linear_velocity *= brake
					rb.angular_velocity *= abrake
		if an == null: continue
		# the small fragments still settle inside the hex, as the thrown plates do
		var settled: bool = fx.now >= float(w["t0"]) + LEASH_SETTLED
		for nd in w.get("frags", []):
			if not is_instance_valid(nd): continue
			if nd is RigidBody3D and not (nd as RigidBody3D).freeze:
				var body := nd as RigidBody3D
				if body.sleeping: continue
				body.linear_velocity = _leash_vel(body, body.linear_velocity, an, dt, drawing)
			_leash_clamp(nd, an, _rest_limit(nd, an, true) if settled else -1.0)
	for b in fx.dstate.get("debris", []):
		if not is_instance_valid(b) or not b.visible or b.sleeping: continue
		var an = anchors.get(_debris_leash(b))
		if an == null: continue
		b.linear_velocity = _leash_vel(b, b.linear_velocity, an, dt)
		_leash_clamp(b, an)


# issue 1236 round 4: a planned piece's drift and turn rate toward its rest spot and heading (_set_rest)
static func _steer(nd: Node3D) -> Array:
	var to: Vector2 = (nd.get_meta("rest_at") as Vector2) - Vector2(nd.global_position.x, nd.global_position.z)
	var dyaw := wrapf(float(nd.get_meta("rest_yaw")) - heading(nd), -PI, PI)
	return [Vector3(to.x, 0.0, to.y) * BREAKUP_K_LIN, dyaw * BREAKUP_K_ANG]


# where a piece is, for the leash: the middle of its mesh's box (a piece's origin is the mean of its points, which on a
# lopsided chunk of hull can sit far from what the eye reads as the piece), else its origin
static func leash_centre(nd: Node3D) -> Vector3:
	for ch in nd.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
			return nd.global_transform * ((ch as MeshInstance3D).transform * (ch as MeshInstance3D).mesh.get_aabb().get_center())
	return nd.global_position


# how far the piece reaches from its middle as drawn now, as it turns about the vertical: the farthest point of its real
# mesh from its box middle on the board plane (measured once, unscaled, and kept on the piece; the drift brake uses half the box's longest side until then)
static func leash_half(nd: Node3D) -> float:
	for ch in nd.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
			var mi := ch as MeshInstance3D
			var k: float = mi.transform.basis.get_scale().x
			if nd.has_meta("leash_rad"): return float(nd.get_meta("leash_rad")) * k
			var sz: Vector3 = mi.mesh.get_aabb().size
			return 0.5 * maxf(sz.x, maxf(sz.y, sz.z)) * k
	return 0.0


# measure a piece's real reach once (leash_half); a big piece's faces are read only when its wreck starts to draw in
static func _measure_reach(nd: Node3D) -> void:
	if nd.has_meta("leash_rad"): return
	# issue 1395: the cut's worker already measured it from the piece's own vertex arrays (_piece_reach)
	if nd.has_meta("reach_pre"):
		nd.set_meta("leash_rad", float(nd.get_meta("reach_pre")))
		return
	for ch in nd.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
			var mi := ch as MeshInstance3D
			var mid: Vector3 = mi.mesh.get_aabb().get_center()
			var far := 0.0
			# on the board plane: a big hull's pieces turn mostly about the vertical (issue 461), so their height does not
			# reach across the hex
			for v in mi.mesh.get_faces(): far = maxf(far, (v.x - mid.x) * (v.x - mid.x) + (v.z - mid.z) * (v.z - mid.z))
			nd.set_meta("leash_rad", sqrt(far))   # in the mesh's own units; leash_half scales it as drawn
			return
	nd.set_meta("leash_rad", 0.0)


# how far from the hex centre a piece may ever be: where it was born when that is past the rest radius, else the radius
static func _born(nd: Node3D, an: Dictionary) -> float:
	if nd.has_meta("leash_born"): return float(nd.get_meta("leash_born"))
	var off: Vector3 = leash_centre(nd) - (an["c"] as Vector3)
	off.y = 0.0
	var lim := maxf(float(an["r"]), off.length())
	nd.set_meta("leash_born", lim)
	nd.set_meta("leash_off0", off.length())
	return lim


# where a piece's middle rests: its whole footprint inside the rest radius (whole), or for the drift brake no nearer
# the centre than half the radius, so a big piece still too large for it is not dragged onto its neighbours (drawing
# the wreck together makes it fit)
static func _rest_limit(nd: Node3D, an: Dictionary, whole := false) -> float:
	var lim := float(an["r"]) - leash_half(nd)
	return maxf(0.0, lim) if whole else maxf(float(an["r"]) * 0.5, lim)


static func _leash_vel(nd: Node3D, v: Vector3, an: Dictionary, dt: float, whole := false) -> Vector3:
	var off: Vector3 = leash_centre(nd) - (an["c"] as Vector3)
	off.y = 0.0
	_born(nd, an)
	var lim := _rest_limit(nd, an, whole)
	var d := off.length()
	var soft := lim * LEASH_SOFT
	if d <= soft: return v
	v *= exp(-LEASH_BRAKE * clampf((d - soft) / maxf(lim - soft, 0.001), 0.0, 1.0) * dt)
	if d >= lim:
		var n := off / d
		var out := v.x * n.x + v.z * n.z
		# no outward drift at the rest radius; past it, back in at LEASH_PULL of the gap a second
		v -= n * (out + (d - lim) * LEASH_PULL)
	return v


static func _leash_clamp(nd: Node3D, an: Dictionary, hard := -1.0) -> void:
	var c: Vector3 = an["c"]
	var off: Vector3 = leash_centre(nd) - c
	off.y = 0.0
	var lim := _born(nd, an) if hard < 0.0 else hard
	if off.length() > lim:
		var back := off - off.normalized() * lim
		nd.global_position -= back
