extends RefCounted
# The battle look (G4): tonemapper, exposure, glow limits, ambient and key/fill balance, and the per-faction hull fix for
# the dark hulls. G2's scene calls LOOK.apply once after building its Environment and lights, and LOOK.hull on each
# hull material; the effects library reads fx_gain from here so effect brightness stays right under the chosen curve.
#
# Calls (vetoable, measured in godot/fx/gallery/README.md "Look"):
#   - Tonemapper: see TONEMAP below and the README for the colour-faithfulness numbers behind the pick.
#   - Exposure fixed (effects add light, they never change exposure: A5 SPEC grammar). No auto exposure.
#   - Glow: threshold 0.8, a tight kernel (levels 1 to 3) plus a little of level 4 (F3), so bright effects bloom and
#     small far ones get a halo, without turning into white blobs.
#   - Dark hulls (Chorus, Deathless): a Fresnel rim in the faction tint plus a small albedo lift, instead of more key light,
#     so they read against black space without washing the others out (A2: "too dark in Godot"; R31 fixed most of it by
#     turning SDFGI off).
#   - Issue 362 (battle camera readability, R157 finding 4): judged at camera 170 at true pixel size on the look bench
#     fleet sheet. Two parts, both on the hulls only (effects and shields are unshaded and never see them):
#     1. READ below: per faction hull material numbers so every faction's lit side sits in one brightness band
#        (docs/shots/look_bench/readability/README.md states the band and the per-ship numbers). The Glasswright hull's
#        burn-out was its own baked glow (emissive map over about a quarter of the hull at strength 4.0, so 1.2 to 2.4
#        linear, above the glow threshold) plus a near-mirror finish; it is capped here in Godot, no rebake.
#     2. A rim light (render/look_rim.gd): a back light from behind the ships as the camera sees them, specular only in
#        effect, on its own render layer that only hull surfaces join, so a dark hull keeps a bright edge against the
#        darkest sky while rocks, planet and board keep their light. Godot's material rim cannot do this on a dark hull:
#        it is multiplied by the albedo (scene_forward_clustered.glsl "diffuse_light *= albedo").
#     KEY_ENERGY and the glow threshold are unchanged: raising either moves every accepted look at once (issue 362 risk).

const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const FILL_DIR := Vector3(0.6, -0.2, 0.75)
const FILL_COL := Color(0.55, 0.65, 0.85)
const KEY_ENERGY := 2.0

# "aces" (the A3 proof's curve), "agx" (Godot 4.7's AgX). See the README for why the default is what it is.
const TONEMAP := "agx"

# effect brightness per curve (fx_gain): ACES in Godot applies an exposure bias of 1.8, so effects are scaled by 1/1.8;
# AgX keeps highlights further from white, so effects need a little more push to read as hot
const FX_GAIN := {"aces": 0.5556, "agx": 0.75}

# Dark-hull fix per faction: [rim amount, rim tint, albedo lift], from the faction look data (fx/faction_looks.json,
# field hull_fix), so a repaint is a data edit
const FLOOK := preload("res://fx/faction_look.gd")

# Issue 362: per faction hull numbers at the battle camera (tuning values judged by eye on the fleet sheet, RULEBOOK 0.4;
# measured in docs/shots/look_bench/readability/README.md). Where a faction is here, these replace its hull_fix:
#   lift      multiplies the albedo in linear light (hull_fix's lift multiplied the sRGB colour: 1.35 there is about 1.9 here)
#   rim       Godot's material rim and rim tint (it scales with the albedo, so it only helps the mid and pale hulls)
#   emit      multiplies the hull's own baked glow (the glTF emissive strength, 4.0 on every A4 hull)
#   metal     multiplies the metallic map; spec is Godot's specular (0.5 is the default)
#   ao_light  how much baked AO affects direct light under fleet lighting (#1679, on by default since R433)
#   rim_light 0 keeps the faction's hulls off the rim light pair below (issue 1315, Glasswrights; leave it out for 1)
# Damaged hulls keep all of these: fx/fx_hull.gd _exterior copies albedo, rim, metallic, specular and emission energy.
# The dark factions (Sunward black iron, Hullbreaker rust, Eclipse violet-black) sit near the band's low end and the pale
# ones (Hegemony, Glasswrights) below its top, so each keeps its own value and colour; the rim light gives the dark ones
# their outline (a first pass that lifted them to the middle turned the rust pink and the Eclipse lavender). Ryan, Nov 12
# (R227): Eclipse darker and Hullbreakers slightly down (4.5 to 2.2, 1.5 to 1.25); 2.2 is the darkest Eclipse lift that keeps
# every Eclipse ship at 100 or more lit on the darkest sky (job F, contrib/opus/reviews/readability_362.md).
const READ := {
	"voidsworn": {"lift": 1.45, "rim": 0.12, "rim_tint": 0.3, "emit": 1.0, "metal": 1.0, "spec": 0.5, "ao_light": 0.5},
	"hegemony": {"lift": 0.4, "rim": 0.08, "rim_tint": 0.2, "emit": 1.0, "metal": 1.0, "spec": 0.5, "ao_light": 0.55},
	"corsair": {"lift": 1.25, "rim": 0.15, "rim_tint": 0.3, "emit": 1.0, "metal": 1.0, "spec": 0.5, "ao_light": 0.45},
	"chorus": {"lift": 1.9, "rim": 0.45, "rim_tint": 0.55, "emit": 1.0, "metal": 1.0, "spec": 0.5, "ao_light": 0.35},
	"ithar": {"lift": 0.4, "rim": 0.1, "rim_tint": 0.25, "emit": 0.15, "metal": 0.4, "spec": 0.3, "rim_light": 0.0, "ao_light": 0.2},
	"deathless": {"lift": 2.2, "rim": 0.4, "rim_tint": 0.5, "emit": 1.0, "metal": 0.7, "spec": 0.5, "ao_light": 0.4},
}
# The rim light (render/look_rim.gd): energy is its diffuse strength, spec multiplies its specular on top (Light3D
# light_specular), alpha is how far (degrees) it is tipped up from the camera's line of sight, behind the ships. Calibration 2
# (contrib/opus/reviews/readability_362.md): alpha 20 keeps every outline lit (edge 0.93 or more on the darkest sky) while
# the Eclipse fans and the Glasswright Ark stay below the band's top; 30 and 45 lit their flat faces too.
const RIM := {"energy": 0.35, "spec": 8.0, "alpha": 20.0, "color": Color(0.85, 0.9, 1.0), "soft": 0.25}
# soft (issue 601): the share of the rim light's specular a surface painted by a sheet ship's paint stack takes. Those surfaces
# carry real roughness (the stack's roughness floor), and the full spec of 8 flared white on their lips and top edges at the
# close cameras (A16 and A17, PC run out3: rack tops, bell lips, flank streaks); at camera 170 their outline barely changes
# (sandbox probe: edge 37.0 at spec 8, 35.3 at spec 2, 34.1 with no rim light). Such surfaces say so in their glTF material
# extras ("rim_soft", written by the paint stack) and join their own layer, lit by a second rim light with this share of the
# specular; every other hull keeps the full rim light exactly as before.
# Render layer 16: only hull surfaces join it (look_rim.gd marks them), so the rim light lights nothing else. The campaign
# map uses layers 2 to 4 (ui/campaign/map3d.gd); nothing else sets layers.
const RIM_LAYER := 1 << 15
const RIM_SOFT_LAYER := 1 << 14      # issue 601: the stack-painted surfaces (RIM soft); nothing else uses layer 15
const RIM_SCRIPT := "res://render/look_rim.gd"
# Bench probes only (contrib/opus/reviews/readability_362/): numbers laid over READ and RIM for one run, never saved. The game
# never sets this.
static var tune := {}   # not GPU: look numbers read from json


# Issue 1679 (R433, Ryan Nov 23): fleet lighting (AO light on every hull, sky reflection gradient) is on by default.
# VS_FLEET_LIGHTING=0 turns it off, only for before/after comparisons. Set before any hull materials are cached.
# Ship Look V2 (issue 1777) needs it, so a check that forces V2 on forces it on too.
static func fleet_lighting_enabled() -> bool:
	return OS.get_environment("VS_FLEET_LIGHTING") != "0" or v2_force == 1


# Issue 1777 (Ship Exteriors V2, RULEBOOK 3.14 law 6): the one switch for the whole V2 ship look. On by default since Ryan
# approved the before and after sheets (Nov 23 2026, R426); VS_SHIP_LOOK_V2=0 turns it off (the old look, for A/B
# captures and a quick way back). The bench and the checks may set `v2_force`. Set before any hull materials are cached.
static var v2_force := -1   # -1 follows the launch option, 0 off, 1 on (checks and bench only)
static func ship_look_v2_enabled() -> bool:
	if v2_force >= 0:
		return v2_force == 1
	return OS.get_environment("VS_SHIP_LOOK_V2") != "0"


# What V2 changes, in one place (tuning values judged by eye on the six-faction sheets, RULEBOOK 0.4):
#   ambient       flat ambient share of the key (was 0.25: 0.50 at key 2.0); the space reflections (world.gd, the #1679 sky
#                 lobes) now carry the shadow sides' readability, so the flat fill can drop and shadows deepen
#   normal_bias   the key light's shadow normal bias (was 2.0, which floated every turret and rib shadow off its deck)
#   bias          the key light's depth bias, raised a little with the lower normal bias to keep acne off the plated hulls
#   rim_spec      the rim light's specular (was 8.0: the wet white streaks on beveled decks, S8, S9, S10)
#   emit          per faction, multiplies the baked hull glow on top of READ emit, so the hot accents (Sunward ember spires,
#                 engine bells, core slits, Directorate bays, Eclipse corona) clear the 0.8 glow threshold; Glasswrights
#                 stay at READ (their glow is capped on purpose, issue 362)
#   detail        per faction micro-detail layer (godot/assets/ships/detail/, made by
#                 contrib/opus/tools/issue1777/make_detail_maps.py): normal relief plus a colour grain, on object-space
#                 triplanar UVs so every hull gets the same grain size whatever its atlas; tiles is grain tiles per game unit
const V2 := {
	"ambient": 0.095, "normal_bias": 0.3, "bias": 0.06, "rim_spec": 3.0,
	"emit": {"voidsworn": 1.6, "hegemony": 1.35, "corsair": 1.3, "chorus": 1.25, "ithar": 1.0, "deathless": 1.45},
	"tiles": 0.9,
	# the key light's shadow reach (battle.gd, each frame): the camera's distance to its focus plus the farthest board hex
	# from that focus plus a margin, at least the floor. Fable's review of the standard (H12): a plain clamp of cam_r x 1.8
	# at 420 dropped shadows off the far board once the camera pulled past r 233
	"reach": [120.0, 12.0],   # [floor, margin]
	# Godot 4.7 material channels per faction (Ryan's engine audit, PR 1781), judged on the sheets; damaged hulls keep them
	# (fx_hull.gd EXTERIOR). aniso: anisotropy (along the glTF tangents); coat/coat_rough: clearcoat; sss: subsurface
	# scattering strength; back: backlight colour (light through thin membranes). Refraction is
	# never used: it moves the hull into the transparent pass, where beams and shields are not in the screen copy (they
	# would not bend) and sorting against effects and wounds breaks (Fable's review, H12); the Glasswrights are dark glass
	# with clearcoat and the rim's fresnel instead. Chorus has no SSS: a screen-space pass for nothing visible at camera
	# 170 (same review); backlight and coat carry it. Anisotropy is wired but
	# 0 for Sunward and the Directorate: with no flow map it follows the glTF tangents, which run every way across a baked
	# atlas, and the cloud probe (contrib/opus/tools/issue1777/README.md) showed blotchy smeared highlights instead of a
	# brushed sheen. It needs a direction the hull's look carries (an authored flow map, #1778) before it goes on.
	"pbr": {
		"voidsworn": {"aniso": 0.0},
		"hegemony": {"aniso": 0.0},
		"corsair": {},
		"chorus": {"coat": 0.35, "coat_rough": 0.35, "back": [0.30, 0.10, 0.08]},
		"ithar": {"coat": 0.6, "coat_rough": 0.08},
		"deathless": {"coat": 0.25, "coat_rough": 0.2},
	},
}


static func shadow_reach(cam_r: float, board_far: float) -> float:
	var k: Array = v2_of("reach")
	return maxf(cam_r + board_far + float(k[1]), float(k[0]))


# Issue 1777: the faction's native Godot material channels (V2 "pbr").
static func _pbr_channels(m: BaseMaterial3D, faction: String) -> void:
	var p: Dictionary = (v2_of("pbr") as Dictionary).get(faction, {})
	if float(p.get("aniso", 0.0)) > 0.0:
		m.anisotropy_enabled = true
		m.anisotropy = float(p["aniso"])
	if float(p.get("coat", 0.0)) > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = float(p["coat"])
		m.clearcoat_roughness = float(p.get("coat_rough", 0.3))
	if float(p.get("sss", 0.0)) > 0.0:
		m.subsurf_scatter_enabled = true
		m.subsurf_scatter_strength = float(p["sss"])
	var back: Array = p.get("back", [])
	if back.size() >= 3:
		m.backlight_enabled = true
		m.backlight = Color(float(back[0]), float(back[1]), float(back[2]))

const DETAIL_DIR := "res://assets/ships/detail/"
const MM_DETAIL_DIR := DETAIL_DIR + "mm_trial/"
const DETAIL_FACTIONS := ["voidsworn", "hegemony", "corsair", "chorus", "ithar", "deathless"]
const MM_TRIAL := preload("res://render/mm_trial.gd")
static var _detail := {}   # grain path -> [grain texture, normal texture, detail share]


# Issue 1204: the detail maps and fitted hull materials are GPU resources held in statics; dropped before quit
# (render/static_caches.gd).
static func clear_static() -> void:
	_detail.clear()
	_fit_cache.clear()


# The fitted copies are keyed by one battle's look materials; ShipView.clear_look_cache drops them with its own cache at
# the end of each battle, so a run does not pin old battles' materials (Antigravity audit, PR 1786).
static func clear_fit_cache() -> void:
	_fit_cache.clear()


static func v2_of(key: String):
	var t: Dictionary = tune.get("v2", {})
	return t.get(key, V2[key])


# The faction's grain, normal and blend share, or [] when the faction has none.
static func detail_maps(faction: String) -> Array:
	if not faction in DETAIL_FACTIONS:
		return []
	if MM_TRIAL.enabled():
		return _load_detail_pair(MM_DETAIL_DIR + faction, faction)
	return _load_detail_pair(DETAIL_DIR + faction)


static func _load_detail_pair(prefix: String, trial_faction := "") -> Array:
	if not _detail.has(prefix):
		var g := prefix + "_grain.png"
		var n := prefix + "_n.png"
		var grain: Texture2D
		var normal: Texture2D
		if trial_faction.is_empty():
			grain = load(g) as Texture2D if ResourceLoader.exists(g) else null
			normal = load(n) as Texture2D if ResourceLoader.exists(n) else null
		else:
			grain = MM_TRIAL.load_tile(trial_faction, g)
			normal = MM_TRIAL.load_tile(trial_faction, n)
		_detail[prefix] = [grain, normal, _alpha_of(grain)] if grain != null and normal != null else []
	return _detail[prefix]


# The grain's alpha (the layer's share), read once per faction.
static func _alpha_of(t: Texture2D) -> float:
	var img := t.get_image() if t != null else null
	if img == null:
		return 0.0
	if img.is_compressed():
		img.decompress()
	return img.get_pixel(0, 0).a


# Issue 1777: lay the faction's micro-detail on a hull material. Godot's detail layer mixes the detail normal in by the
# grain's alpha (a), which would flatten the baked relief by that share; the normal scale is raised by 1 / (1 - a) so the
# baked relief keeps its full depth and the micro relief rides on top. Tiles are per object-space unit here; ShipView
# rescales them per hull once it knows the hull's fitted scale (detail_fit).
static func _detail_layer(m: BaseMaterial3D, faction: String) -> void:
	var maps := detail_maps(faction)
	if maps.is_empty():
		return
	var grain := maps[0] as Texture2D
	var a := float(maps[2])   # one constant alpha per grain map stores the detail layer's share
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_albedo = grain
	m.detail_normal = maps[1]
	m.uv2_triplanar = true
	m.uv2_world_triplanar = false
	m.uv2_triplanar_sharpness = 4.0
	m.uv2_scale = Vector3.ONE * float(v2_of("tiles"))
	if not m.normal_enabled:
		m.normal_enabled = true   # no baked normal map: Godot's flat default sits under the detail
	m.normal_scale = m.normal_scale / maxf(1.0 - a, 0.2)
	m.set_meta("look_detail", faction)


# Issue 1777: the hull material for one fitted scale. ShipView's look cache shares one material per glb material and
# faction, but two ships from one glb can be fitted at different lengths, and the grain scale lives on the material; so
# each fitted scale gets its own copy (cached, so ships of one size still share). A material with no detail layer is
# returned as it is. The Board audit of PR 1786 found the clash.
static var _fit_cache := {}   # "material id|k" -> material (cleared in clear_static)
static func fitted(m: Material, k: float) -> Material:
	var b := m as BaseMaterial3D
	if b == null or not b.detail_enabled or not b.has_meta("look_detail"):
		return m
	var key := "%d|%.3f" % [m.get_instance_id(), absf(k)]
	if not _fit_cache.has(key):
		var c := b.duplicate() as BaseMaterial3D
		for meta in b.get_meta_list():
			c.set_meta(meta, b.get_meta(meta))
		detail_fit(c, k)
		_fit_cache[key] = c
	return _fit_cache[key]


# Issue 1777: after ShipView fits a hull (scale k from object space to game units), keep the grain the same size in game
# units on every hull. Only materials that carry the detail layer change.
static func detail_fit(m: Material, k: float) -> void:
	var b := m as BaseMaterial3D
	if b == null or not b.detail_enabled or not b.has_meta("look_detail"):
		return
	b.uv2_scale = Vector3.ONE * float(v2_of("tiles")) * absf(k)


static func read_of(faction: String) -> Dictionary:
	var r: Dictionary = (READ.get(faction, {}) as Dictionary).duplicate()
	var t: Dictionary = tune.get("read", {})
	if t.has(faction):
		r.merge(t[faction], true)
	if t.has("*") and not r.is_empty():
		var g: Dictionary = t["*"]
		if g.has("lift_k"):
			r["lift"] = float(r.get("lift", 1.0)) * float(g["lift_k"])
	return r


static func rim_of() -> Dictionary:
	var r := RIM.duplicate()
	if ship_look_v2_enabled():
		r["spec"] = float(v2_of("rim_spec"))   # issue 1777: no wet white glare on beveled decks
	r.merge(tune.get("rim", {}), true)
	return r


# Issue 1262: the cheaper 4K Max items (ssil, underlay, cards) can be switched back to the old way for the
# before and after timing and pictures: VS_1262_OLD=all or a comma list. Capture only; never set in play.
static func perf_old(item: String) -> bool:
	var v := OS.get_environment("VS_1262_OLD")
	return v != "" and (v == "all" or item in v.split(","))


static func msaa_for_quality(quality: String) -> Viewport.MSAA:
	match quality:
		"low": return Viewport.MSAA_DISABLED
		"high": return Viewport.MSAA_2X
		_: return Viewport.MSAA_4X


static func post_fx_enabled(flag: String) -> bool:
	return OS.get_environment("VS_BATTLE_" + flag) == "1" \
		and DisplayServer.get_name() != "headless" \
		and RenderingServer.get_current_rendering_method() == "forward_plus"


const BATTLE_LUTS := {
	"frontier": "res://assets/luts/frontier.png",
	"nebula": "res://assets/luts/nebula.png",
	"world": "res://assets/luts/world.png",
	"boneyard": "res://assets/luts/boneyard.png",
	"deep": "res://assets/luts/deep.png",
	"deadstar": "res://assets/luts/deadstar.png",
}
const SSR_HULLS := ["ithar", "deathless", "chorus"]
const MAX_SSR_STEPS := 32


static func battle_lut(region: String) -> Texture3D:
	return load(BATTLE_LUTS.get(region, BATTLE_LUTS["frontier"])) as Texture3D


static func battle_grade(env: Environment, region: String) -> void:
	env.adjustment_color_correction = battle_lut(region) if post_fx_enabled("LUT") else null
	env.adjustment_enabled = env.adjustment_color_correction != null


static func battle_ssr(env: Environment, quality: String, units: Array) -> void:
	if env == null:
		return
	var use_ssr: bool = post_fx_enabled("SSR") and ssr_candidate(quality, units) \
		and ProjectSettings.get_setting("rendering/environment/screen_space_reflection/half_size", true)
	if use_ssr != env.ssr_enabled:
		env.ssr_enabled = use_ssr
	if use_ssr and env.ssr_max_steps != MAX_SSR_STEPS:
		env.ssr_max_steps = MAX_SSR_STEPS


static func ssr_candidate(quality: String, units: Array) -> bool:
	if quality != "max":
		return false
	for unit in units:
		if unit.get("fac") in SSR_HULLS and not (unit.get("squadron", false) or unit.get("dead", false) or unit.get("fled", false)):
			return true
	return false


static func apply(env: Environment, key: DirectionalLight3D, fill: DirectionalLight3D, opts := {}) -> void:
	var tm := String(opts.get("tonemap", TONEMAP))
	var q := String(opts.get("quality", "max"))
	var key_e := float(opts.get("key", KEY_ENERGY))
	if tm == "agx":
		env.tonemap_mode = Environment.TONE_MAPPER_AGX
		env.tonemap_exposure = 1.0
		env.tonemap_agx_white = 12.0
		env.tonemap_agx_contrast = 1.25
	else:
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.0
		env.tonemap_white = 8.0
	_fx_gain(FX_GAIN.get(tm, 0.5556))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	# r10 lighting pass: a slightly cool ambient against the warm key, so shadow sides read as depth, not flat grey
	env.ambient_light_color = Color(0.86, 0.9, 1.0)
	env.ambient_light_energy = (float(v2_of("ambient")) if ship_look_v2_enabled() else 0.25) * key_e
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_hdr_scale = 2.0
	env.glow_intensity = 0.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	# F3 (effects at distance): a little of the wider level 4 (and a touch more of level 3), so a small bright effect far
	# out gets a soft halo a few pixels wider than itself and reads; the tight levels 1 and 2 still carry the shape
	for lv in 7:
		env.set_glow_level(lv, [0.0, 0.6, 1.0, 0.6, 0.25, 0.0, 0.0][lv])
	env.ssao_enabled = q == "max"
	# Issue 1262: SSIL (screen-space bounce light) is a second full-screen pass over a frame that is mostly empty
	# space, and the hulls carry baked AO; Max now matches High here. SSAO stays (already half size by default).
	env.ssil_enabled = q == "max" and perf_old("ssil")
	if q == "max":
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.6
		env.ssr_enabled = false
		env.sdfgi_enabled = false
	if key != null:
		key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
		key.light_color = KEY_COL
		key.light_energy = key_e
		key.shadow_enabled = true
		# Smooth the stippled self-shadows on the densely plated painted hulls.
		key.shadow_normal_bias = 2.0
		# Issue 1777: V2 tightens it so turrets, spires and ribs cast real contact shadows onto the decks
		if ship_look_v2_enabled():
			key.shadow_normal_bias = float(v2_of("normal_bias"))
			key.shadow_bias = float(v2_of("bias"))
		# issue 1437 (item 8): Low takes the cheaper soft filter and two splits; Max and High keep today's
		var low := q == "low"
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_LOW if low else RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if low else DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if fill != null:
		fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
		fill.light_color = FILL_COL
		fill.light_energy = 0.25 * key_e
		fill.shadow_enabled = false
	if key != null and bool(opts.get("rim", true)):
		rim_light(key)


# Issue 362: the hulls' rim light, a sibling of the key light (one per scene, reused when apply runs again). Returns it,
# or null when the key light is not in a scene yet.
static func rim_light(key: DirectionalLight3D) -> DirectionalLight3D:
	var parent := key.get_parent()
	if parent == null:
		return null
	var l := parent.get_node_or_null("LookRim") as DirectionalLight3D
	if l == null:
		l = DirectionalLight3D.new()
		l.set_script(load(RIM_SCRIPT))
		l.name = "LookRim"
		parent.add_child(l)
	l.call("configure")
	# issue 601: the soft rim light for stack-painted surfaces (dark until one of them is in the scene)
	var s := parent.get_node_or_null("LookRimSoft") as DirectionalLight3D
	if s == null:
		s = DirectionalLight3D.new()
		s.set_script(load(RIM_SCRIPT))
		s.set("soft", true)
		s.name = "LookRimSoft"
		parent.add_child(s)
	s.call("configure")
	return l


static func _fx_gain(v: float) -> void:
	if ProjectSettings.has_setting("shader_globals/fx_gain"):
		RenderingServer.global_shader_parameter_set(&"fx_gain", v)
		return
	var FX = load("res://fx/fx.gd")
	FX.register_globals()
	RenderingServer.global_shader_parameter_set(&"fx_gain", v)


# Per-faction hull material fix (StandardMaterial3D or ORMMaterial3D). Returns the material it changed (a copy when
# `copy` is true, so shared materials are not changed for every ship).
static func hull(mat: Material, faction: String, copy := false) -> Material:
	var m := mat as BaseMaterial3D
	if m == null:
		return mat
	if copy:
		m = m.duplicate()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# the rim light (look_rim.gd) finds hull surfaces by this mark; death pieces and damaged hulls carry it on
	m.set_meta("look_hull", faction)
	# issue 601: a surface the paint stack painted says so in its glTF extras; it takes the soft rim light (RIM soft)
	var extras = m.get_meta("extras", {})
	var ex: Dictionary = extras if extras is Dictionary else {}
	if ex.has("rim_soft"):
		m.set_meta("look_rim_soft", true)
	# issue 1315: READ rim_light 0 keeps a faction's hulls off both rim lights (render/look_rim.gd). The Glasswright pearl is pale
	# and near mirror: the rim's specular 8 flared white on its lips and glow spread it over the stern (PC probe 4: 1290 white
	# stern pixels with the rim, 118 without, 655 with the soft rim). Pale hulls read on black without it.
	var r := read_of(faction)
	if float(r.get("rim_light", 1.0)) <= 0.0:
		m.set_meta("look_rim_none", true)
	var authored: bool = ex.get("authored_look", 0) == 1
	if fleet_lighting_enabled():
		var ao_light: float = r.get("ao_light", m.ao_light_affect)
		if authored:
			ao_light = float(ex.get("ao_light", ao_light))
		m.ao_light_affect = ao_light
	var v2 := ship_look_v2_enabled()
	if v2:
		_detail_layer(m, faction)
		_pbr_channels(m, faction)
	if authored:
		m.rim_enabled = true
		m.rim = float(ex.get("rim", 0.08))
		m.rim_tint = float(ex.get("rim_tint", 0.15))
		if v2:
			m.emission_energy_multiplier *= float((v2_of("emit") as Dictionary).get(faction, 1.0))
		return m
	if r.is_empty():
		var f: Array = FLOOK.of(faction).get("hull_fix", [0.1, 0.25, 1.0])
		m.rim_enabled = true
		m.rim = float(f[0])
		m.rim_tint = float(f[1])
		if float(f[2]) != 1.0:
			m.albedo_color = Color(m.albedo_color.r * float(f[2]), m.albedo_color.g * float(f[2]), m.albedo_color.b * float(f[2]), m.albedo_color.a)
		return m
	m.rim_enabled = true
	m.rim = float(r.get("rim", 0.1))
	m.rim_tint = float(r.get("rim_tint", 0.25))
	var lift := float(r.get("lift", 1.0))
	if lift != 1.0:
		var a := m.albedo_color.a
		var c := m.albedo_color.srgb_to_linear()
		c = Color(c.r * lift, c.g * lift, c.b * lift).linear_to_srgb()
		c.a = a
		m.albedo_color = c
	m.emission_energy_multiplier *= float(r.get("emit", 1.0))
	if v2:
		m.emission_energy_multiplier *= float((v2_of("emit") as Dictionary).get(faction, 1.0))
	m.metallic *= float(r.get("metal", 1.0))
	m.metallic_specular = float(r.get("spec", m.metallic_specular))
	return m
