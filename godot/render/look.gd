extends RefCounted
# The battle look (G4): tonemapper, exposure, glow limits, ambient and key/fill balance, and the per-faction hull fix for
# the dark hulls. G2's scene calls LOOK.apply once after building its Environment and lights, and LOOK.hull on each
# hull material; the effects library reads fx_gain from here so effect brightness stays right under the chosen curve.
#
# Calls (vetoable, measured in godot/fx/gallery/README.md "Look"):
#   - Tonemapper: see TONEMAP below and the README for the colour-faithfulness numbers behind the pick.
#   - Exposure fixed (effects add light, they never change exposure: A5 SPEC grammar). No auto exposure.
#   - Glow: threshold 0.8, a tight kernel (levels 2 to 4), so bright effects bloom without turning into white blobs.
#   - Dark hulls (Chorus, Deathless): a Fresnel rim in the faction tint plus a small albedo lift, instead of more key light,
#     so they read against black space without washing the others out (A2: "too dark in Godot"; R31 fixed most of it by
#     turning SDFGI off).

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
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.25 * key_e
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_hdr_scale = 2.0
	env.glow_intensity = 0.6
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for lv in 7:
		env.set_glow_level(lv, [0.0, 0.6, 1.0, 0.5, 0.0, 0.0, 0.0][lv])
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
		key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if fill != null:
		fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
		fill.light_color = FILL_COL
		fill.light_energy = 0.25 * key_e
		fill.shadow_enabled = false


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
	var f: Array = FLOOK.of(faction).get("hull_fix", [0.1, 0.25, 1.0])
	m.rim_enabled = true
	m.rim = float(f[0])
	m.rim_tint = float(f[1])
	if float(f[2]) != 1.0:
		m.albedo_color = Color(m.albedo_color.r * float(f[2]), m.albedo_color.g * float(f[2]), m.albedo_color.b * float(f[2]), m.albedo_color.a)
	return m
