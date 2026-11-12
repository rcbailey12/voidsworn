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
# Damaged hulls keep all of these: fx/fx_hull.gd _exterior copies albedo, rim, metallic, specular and emission energy.
const READ := {
	"voidsworn": {"lift": 2.6, "rim": 0.12, "rim_tint": 0.3, "emit": 1.0, "metal": 1.0, "spec": 0.5},
	"hegemony": {"lift": 0.85, "rim": 0.08, "rim_tint": 0.2, "emit": 1.0, "metal": 1.0, "spec": 0.5},
	"corsair": {"lift": 1.5, "rim": 0.15, "rim_tint": 0.3, "emit": 1.0, "metal": 1.0, "spec": 0.5},
	"chorus": {"lift": 1.9, "rim": 0.45, "rim_tint": 0.55, "emit": 1.0, "metal": 1.0, "spec": 0.5},
	"ithar": {"lift": 0.7, "rim": 0.1, "rim_tint": 0.25, "emit": 0.3, "metal": 0.6, "spec": 0.35},
	"deathless": {"lift": 3.0, "rim": 0.4, "rim_tint": 0.5, "emit": 1.0, "metal": 1.0, "spec": 0.5},
}
# The rim light (render/look_rim.gd): energy is its diffuse strength, spec multiplies its specular on top (Light3D
# light_specular), tilt is how far below level it shines (degrees), toward the camera from behind the ships.
const RIM := {"energy": 0.35, "spec": 8.0, "tilt": 12.0, "color": Color(0.85, 0.9, 1.0)}
# Render layer 16: only hull surfaces join it (look_rim.gd marks them), so the rim light lights nothing else. The campaign
# map uses layers 2 to 4 (ui/campaign/map3d.gd); nothing else sets layers.
const RIM_LAYER := 1 << 15
const RIM_SCRIPT := "res://render/look_rim.gd"
# Bench probes only (contrib/opus/reviews/readability_362/): numbers laid over READ and RIM for one run, never saved. The game
# never sets this.
static var tune := {}


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
	r.merge(tune.get("rim", {}), true)
	return r


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
	env.ambient_light_energy = 0.25 * key_e
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
	if q == "max":
		env.ssao_enabled = true
		env.ssao_radius = 1.2
		env.ssao_intensity = 1.6
		env.ssil_enabled = true
		env.ssr_enabled = false
		env.sdfgi_enabled = false
	if key != null:
		key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
		key.light_color = KEY_COL
		key.light_energy = key_e
		key.shadow_enabled = true
		# Smooth the stippled self-shadows on the densely plated painted hulls.
		key.shadow_normal_bias = 2.0
		RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_SOFT_HIGH)
		key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
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
	var r := read_of(faction)
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
	m.metallic *= float(r.get("metal", 1.0))
	m.metallic_specular = float(r.get("spec", m.metallic_specular))
	return m
