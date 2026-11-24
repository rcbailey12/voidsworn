extends Node3D
const SKEEP := preload("res://render/shader_keep.gd")
# B "living terrain" for the board look trial (world/board_look.gd): each kind of special hex becomes a thing in space
# rather than a tinted hex (the board draws only a faint edge round it).
#   nebula      soft gas: billboards that sample one continuous 3D noise field in world space, so neighbouring puffs read
#               as one body; lit on the sun's side, dense cores glowing, soft where they meet hulls and rocks. Step 2:
#               shaped by a soft footprint of its own hexes (_mask) worn by the noise, so it has no hex outline and no
#               hex-shaped blobs, and spills softly beyond the marked hexes
#   ion storm   steel-blue gas with pale cyan charge gathering in its cloud masses; raised, forked lightning
#               now and then, with a faint light on ships inside and scattering in the max-tier fog (R282)
#   debris      dense rock and wreck clusters: many more rocks of mixed size, wreckage (torn hull plates with their
#               frames, snapped hull frames, broken truss spars, gutted hull sections; some torn edges still hot, every
#               piece tumbling slowly), and a haze of fine dust
#   gravity well  the space round the dead star bends: a ring of lensing and slow twist out to the pull range, with faint
#               ripples running inward
# Built once, the first time a look needs it; the world shows or hides it. Nothing here changes the rules.

const WR := preload("res://world/world_rocks.gd")
const WS := preload("res://world/world_shaders.gd")
const ION := preload("res://world/ion_storm.gd")
const NEBULA_HULLS := preload("res://world/nebula_hulls.gd")
const WAKE := preload("res://world/nebula_wake.gd")
const LS := preload("res://render/line_style.gd")   # issue 1374: the one line style (storm bolt colours)
const LOOK := preload("res://render/look.gd")
const SHADER_CACHE := preload("res://render/shader_cache.gd")
const STORM_TICK_LIFE := 0.45

const HD := preload("res://world/hull_debris.gd")
var _chunk_task := -1
var _chunk_job := {}
var _wreck_slots: Array = []  # one replaceable kit slot per hex for issue 49's painted hull chunks
var _hull_spin: Array = []
var _legacy_debris_mats: Array[ShaderMaterial] = []
var W = null                 # the world (world.gd)
var rng := RandomNumberGenerator.new()
var gas_mats: Array = []     # [ShaderMaterial, base alpha gain]
var storm_mats: Array[ShaderMaterial] = []
var _storm_patches: Array = []
var _tick_presenter: Node = null
var bolts: Array = []        # {mi, light, pos, next, start}
var _storm_bursts: Array = []
var clock := 0.0
# Issue 1079 prototype (off by default): ships disturb the calm nebula as they pass. Storm gas is never touched.
var _wake = null
var _wake_mats: Array[ShaderMaterial] = []

# Issue 368, R270: route A is the default. today is retained only for historical bench pairs.
var gas_route := selected_route()


static func selected_route() -> String:
	var route := OS.get_environment("VS_NEBULA_ROUTE")
	return "today" if route == "today" else "fog"


static func apply_fog(parent: Node, env: Environment, camera_radius: float, quality: String) -> void:
	env.volumetric_fog_enabled = quality == "max" and selected_route() == "fog"
	if not env.volumetric_fog_enabled:
		return
	RenderingServer.environment_set_volumetric_fog_volume_size(128, 128)
	env.volumetric_fog_density = 0.0001
	env.volumetric_fog_length = maxf(250.0, camera_radius + 200.0)
	# Short electrical flashes must not leave temporal ghosts.
	env.volumetric_fog_temporal_reprojection_enabled = false
	if not parent.has_node("NebulaHulls"):
		var policy := NEBULA_HULLS.new()
		policy.name = "NebulaHulls"
		parent.add_child(policy)

var fog_mats: Array[ShaderMaterial] = []
var _fog_noise: ImageTexture3D = null
const GAS_LATTICE_PATH := "res://world/gas_hash_lattice.res"
var _gas_lattice: ImageTexture3D
var _gas_lattice_origin: Vector3
const GAS_HEIGHT := 1.75
const GAS_CLOUD_SCALE := 3.0
# Issue 1263: the cloud footprint (_mask) must reach zero smoothly inside its texture, or the cloud ends in a straight
# line. The round field (channel r, a Gaussian per hex) eases to zero between GAS_FIELD_FADE and GAS_FIELD_REACH; the
# edge feather (channel g) is zero past GAS_FEATHER_END hex radii (scaled), which is GAS_FEATHER_REACH units at a hex
# corner direction. GAS_SHADER samples r up to GAS_WARP units off on each axis (its `wv`), so the field reach must cover
# the feather reach plus that warp on a diagonal, and the texture margin adds one texel for linear filtering.
const GAS_FIELD_SIG2 := 84.0 * GAS_CLOUD_SCALE * GAS_CLOUD_SCALE
const GAS_FIELD_FADE := 14.0 * GAS_CLOUD_SCALE   # the old hard reach: inside it the field is unchanged
const GAS_FIELD_REACH := 56.0
const GAS_FEATHER_END := 1.6
const GAS_FEATHER_REACH := GAS_FEATHER_END * 8.660254 * GAS_CLOUD_SCALE / 0.8660254   # 48 units
const GAS_WARP := 4.5                            # GAS_SHADER: wv = (noise - 0.5) * 9.0
const GAS_CLOUD_MARGIN := GAS_FIELD_REACH + 2.0
const FOG_SHADER := """
shader_type fog;
uniform sampler3D noise_tex : filter_linear, repeat_enable;
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box;
uniform vec3 c_dark;
uniform vec3 c_shadow;
uniform vec3 c_lit;
uniform vec3 c_glow;
uniform float gas_time = 0.0;
uniform float gain_a = 1.0;
uniform float storm = 0.0;
void fog() {
	vec3 p = WORLD_POSITION * 0.012 + vec3(0.0006, 0.0002, 0.00035) * gas_time;
	// WAKE_SHIFT: issue 1079, world/nebula_wake.gd puts the wake's push here when it is on
	float warp = texture(noise_tex, p * 0.55 + 0.31).r;
	float n = texture(noise_tex, p + vec3(warp * 0.12)).r;
	n = mix(n, texture(noise_tex, p * 3.1 - vec3(warp * 0.18)).r, 0.18);
	vec2 uv = (WORLD_POSITION.xz - mask_box.xy) * mask_box.zw;
	vec2 foot = texture(mask_tex, uv).rg;
	foot *= step(vec2(0.0), uv).x * step(vec2(0.0), uv).y * step(uv, vec2(1.0)).x * step(uv, vec2(1.0)).y;
	float height = smoothstep(-7.0, -2.0, WORLD_POSITION.y) * (1.0 - smoothstep(23.0, 31.5, WORLD_POSITION.y));
	float shape = foot.g * smoothstep(0.08, 0.65, foot.r) * height;
	DENSITY = smoothstep(0.32, 0.68, n) * shape * 0.045 * gain_a;
	// WAKE_THIN: issue 1079, the wake's thinning goes here when it is on
	ALBEDO = mix(c_lit, c_glow, smoothstep(0.58, 0.85, n));
	EMISSION = mix(c_dark, c_shadow, n) * 0.65;
	EMISSION += c_glow * smoothstep(0.7, 0.9, n) * (0.2 + storm * 0.25);
}
"""

# Issue 1268 (Ryan, Nov 20 2026, replaces R82's violet): one rose nebula in every region and against every faction, the
# hydrogen pink of real glowing gas, so it reads apart from the teal ion storm. Linear RGB, from the NEB1268 r1 sheet (E).
const NEBULA_LIT := Vector3(0.50, 0.12, 0.20)
const NEBULA_GLOW := Vector3(1.0, 0.72, 0.76)
const NEBULA_SHADOW := Vector3(0.09, 0.015, 0.04)
const NEBULA_DARK := Vector3(0.014, 0.002, 0.006)
# The one scale table's terrain sizes (issue 710, R247; docs/playbooks/scale.md), world units, HEX_S = 10.
const GAS_PUFF_MIN := 24.0       # a nebula or storm puff's width
const GAS_PUFF_MAX := 34.0
const GAS_PUFF_REACH := 6.0      # how far a puff's centre sits off its hex centre
const GAS_VEIL_MIN := 36.0       # the faint high tying veil
const GAS_VEIL_MAX := 46.0
const GAS_MASK_MARGIN := 24.0    # the gas footprint reaches this far past its outermost hex centre
const DEBRIS_ROCK_MIN := 0.3     # a debris field's own rock, at scale 1 a library rock is 2 units long
const DEBRIS_ROCK_MAX := 2.8
# Issue 232 E17/NB5 sheet: the live weight, overridable for the three-weight capture (default is the shipped 0.25).

const GAS_CARD_SUPPORT := """
const float MIN_GAS_DENSITY = 0.002;
// Leave room for rounding when an upper bound drops an empty fragment early.
const float GAS_DENSITY_BOUND = MIN_GAS_DENSITY * 0.95;
// Issue 1263 run 2: every bottom-band card was cut by the same thin fade at one height, so the cloud was a slab with a
// flat floor; seen from the battle camera its near-bottom edge drew one straight line across every patch on the row.
// The bottom band now starts lower and fades in over 5 band units (half density at -4.0 instead of -3.25).
const float GAS_FLOOR_FADE = 5.0;
vec2 gas_band(float band) {
	return band < 0.5 ? vec2(-6.5, 2.0) : (band < 1.5 ? vec2(1.0, 8.0) : (band < 2.5 ? vec2(6.0, 14.0) : vec2(12.0, 18.0)));
}
float gas_layer(float band, float y) {
	vec2 limits = gas_band(band);
	float lower = band < 0.5 ? GAS_FLOOR_FADE : 1.5;
	return smoothstep(limits.x, limits.x + lower, y) * (1.0 - smoothstep(limits.y - 1.5, limits.y, y));
}
vec2 gas_card_offset(inout vec2 vertex, vec4 card, vec4 centre, mat4 inv_view, float height_scale) {
	float angle = card.y * 6.2831;
	mat2 spin = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
#ifdef HIGH_GAS_CARDS
	// The radial falloff fits inside a disc. Bound that disc by its nonzero
	// height band in the billboard plane before rasterizing the quad.
	vec2 up = vec2(inv_view[0].y, inv_view[1].y);
	float height_per_unit = length(up);
	if (height_per_unit > 0.0001) {
		up /= height_per_unit;
		vec2 across = vec2(up.y, -up.x);
		float centre_y = (inv_view * centre).y;
		vec2 limits = (gas_band(floor(card.w)) * height_scale - centre_y) / (height_per_unit * card.x);
		// Add a small margin for rounding at the height edges. The fragment
		// shader still applies the original radial and height fades.
		limits = clamp(limits + vec2(-0.0001, 0.0001), -0.5, 0.5);
		vec2 offset = across * vertex.x + up * mix(limits.x, limits.y, vertex.y + 0.5);
		// The soft intersection uses Godot's interpolated VERTEX.z. Keep its
		// original quad coordinate even though POSITION draws a clipped quad.
		vertex = transpose(spin) * offset;
		return offset;
	}
#endif
	return spin * vertex;
}
"""

const GAS_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
%NOISE%
%CARD_SUPPORT%
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
// r: the round field, g: inward feather of the union boundary, zero outside.
uniform sampler2D mask_tex : filter_linear, repeat_disable;
uniform vec4 mask_box = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec3 c_dark = vec3(0.006, 0.002, 0.014);
uniform vec3 c_shadow = vec3(0.055, 0.012, 0.14);
uniform vec3 c_lit = vec3(0.43, 0.20, 0.80);
uniform vec3 c_glow = vec3(0.88, 0.72, 1.0);
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform float dens = 0.5;
uniform float gas_time = 0.0;
uniform float height_scale = 1.0;
uniform float glow_from = 0.56;
uniform float gain_a = 1.0;
uniform float flat_rates = 0.0;   // #230 NB8 capture variant (VS_GAS_FLAT=1): every layer at the base rate; 0 shipped
varying vec4 vI;
varying vec2 vQ;
varying vec3 vW;
void vertex() {
	vI = INSTANCE_CUSTOM; // x size, y spin, z density, floor(w) layer, fract(w) phase
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	vec2 q = gas_card_offset(VERTEX.xy, vI, c, INV_VIEW_MATRIX, height_scale);
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	vW = (INV_VIEW_MATRIX * c).xyz;
	POSITION = PROJECTION_MATRIX * c;
}
vec2 foot_at(vec2 xz) { return texture(mask_tex, (xz - mask_box.xy) * mask_box.zw).rg; }
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 mask = foot_at(vW.xz);
	if (mask.g <= 0.001) { discard; }
	float band = floor(vI.w);
	float layer = gas_layer(band, vW.y / height_scale);
	float shape = 1.0 - smoothstep(0.4, 1.0, r);
#ifdef HIGH_GAS_CARDS
	if (shape * mask.g * layer * vI.z < GAS_DENSITY_BOUND) { discard; }
#else
	if (shape * mask.g * layer * vI.z <= 0.0) { discard; }
#endif
	float dz = texture(depth_tex, SCREEN_UV).r;
	vec4 vv = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, dz, 1.0);
	vec3 opaque_world = (INV_VIEW_MATRIX * vec4(vv.xyz / vv.w, 1.0)).xyz;
	// All gas layers leave opaque hulls intact, even a veil in front of a ship.
	if (dz > 0.000001 && opaque_world.y > -20.0) { discard; }
	float phase = fract(vI.w);
	// Layer rates and the base drift: contrib/opus/briefs/nebula_motion_spec.md (issue #230, NB8).
	float rate = band < 0.5 ? 0.6 : (band < 1.5 ? 1.0 : (band < 2.5 ? 1.6 : 0.4));
	if (flat_rates > 0.5) { rate = 1.0; }
	vec3 drift = vec3(0.012, 0.004, 0.007) * gas_time * rate;
	vec3 p = vW * 0.075 + drift;
	// WAKE_SHIFT: issue 1079, world/nebula_wake.gd puts the wake's push here when it is on
	float w = wfbm3(p * 0.55 + 4.0);
	float n = wfbm3(p + vec3(w) * 0.9);
	float breath = band > 0.5 && band < 1.5 ? sin(gas_time * 0.785398 + phase) * 0.025 : 0.0;
	float field = smoothstep(0.27 + breath, 0.70 + breath, n);
#ifdef HIGH_GAS_CARDS
	// The warped footprint can only lower mask.g, and contact can only soften it.
	if (shape * mask.g * layer * field * vI.z < GAS_DENSITY_BOUND) { discard; }
#endif
	vec2 wv = vec2(w - 0.5, wfbm3(p * 0.4 - 7.0) - 0.5) * 9.0;
	float fw = foot_at(vW.xz + wv).r;
	float bar = 0.62 - 0.55 * smoothstep(0.3, 0.75, n);
	float foot = smoothstep(bar, bar + 0.3, fw) * mask.g;
	float d = shape * foot * layer * field * vI.z;
	// Soften contact with distant geometry below the playing surface.
	d *= clamp((-vv.z / vv.w + VERTEX.z) / 5.0, 0.0, 1.0);
	// WAKE_THIN: issue 1079, the wake's thinning goes here when it is on
	if (d <= MIN_GAS_DENSITY) { discard; }
	float n2 = wfbm3(p + normalize(sun_v) * 0.22 + vec3(w) * 0.9);
	float lit = clamp(0.5 + (n - n2) * 5.0, 0.0, 1.0);
	float density = clamp((n - 0.18) / 0.72, 0.0, 1.0);
	vec3 col = mix(c_dark, c_shadow, smoothstep(0.0, 0.3, density));
	col = mix(col, c_lit, smoothstep(0.3, 0.6, density));
	col = mix(col, c_glow, smoothstep(0.6, 0.9, density));
	col *= 0.25 + 0.75 * lit;
	// R289: calm gas has broad soft radiance, never fine isocontours or electrical veins.
	vec3 energy = c_glow * smoothstep(0.67, 0.85, n) * 0.22;
	float layer_gain = band < 0.5 ? 0.50 : (band < 1.5 ? 1.0 : (band < 2.5 ? 0.55 : 0.10));
	// Optical depth accumulates across overlapping puffs rather than a flat tint.
	float a = 1.0 - exp(-d * dens * layer_gain * 3.6);
	float ship_band = 1.0 - smoothstep(3.0, 4.5, vW.y);
	a = min(a, mix(0.7, 0.39, ship_band));
	// Unshaded gas carries its internal light in the final radiance.
	ALBEDO = col + energy;
	ALPHA = clamp(a * gain_a, 0.0, 0.7);
}
"""

const BOLT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
instance uniform float flash = 0.0;
instance uniform float branch_flash = 0.0;
""" + LS.GLSL + """
varying vec4 vc;
void vertex() { vc = COLOR; }
void fragment() {
	// Red marks branches, green the hot tube, blue the outer corona.
	// Issue 1269 (Ryan's pick 4, Nov 20): the corona is cool cyan-white, not violet,
	// so storm lightning (danger) never shares the nebula's violet (cover).
	// Keep the halo blue-led before the existing weapon bloom integrates it.
	if (vc.g > 0.5 && !FRONT_FACING) { discard; }
	float pulse = mix(flash, branch_flash, vc.r);
	// Issue 1374 (R362): the colours come from the one line style's role table (render/line_style.gd bolt_*)
	vec3 halo = mix(LS_BOLT_SKIRT, LS_BOLT_CORONA, vc.b);
	vec3 radiance = mix(halo, LS_BOLT_CORE, vc.g);
	// The cyan-white corona peaks outside the cyan skirt, never on the hot tube.
	// Stacking it on the core at the center turned the bloom pale white.
	float weight = vc.a;
	if (vc.b > 0.5) { weight = sin(clamp(vc.a / 0.16, 0.0, 1.0) * 3.14159265) * 0.22; }
	ALBEDO = radiance * weight * pulse;
}
"""

const DUST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// Linear #d4bf86, with actual alpha rather than the old grey additive specks.
uniform vec3 col = vec3(0.658, 0.521, 0.238);
varying vec2 vQ;
varying vec3 vW;
varying flat vec2 vHex;
varying flat float vA;
void vertex() {
	vHex = INSTANCE_CUSTOM.zw;
	vec3 origin = MODEL_MATRIX[3].xyz;
	// 20 percent of the recorded gas drift (0.193 u/s). Wrap only behind a faded footprint edge.
	origin.xz = vHex + mod(origin.xz - vHex + vec2(0.032, 0.018667) * TIME + 10.0, 20.0) - 10.0;
	origin.y = mod(origin.y + 0.010667 * TIME + 5.0, 7.0) - 5.0;
	vec4 c = VIEW_MATRIX * vec4(origin, 1.0);
	vA = INSTANCE_CUSTOM.y;
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * INSTANCE_CUSTOM.x;
	vW = (INV_VIEW_MATRIX * c).xyz;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 p = abs(vW.xz - vHex);
	float edge = 8.660254 - max(p.x, p.x * 0.5 + p.y * 0.8660254);
	if (edge <= 0.0) { discard; }
	float high = smoothstep(-4.0, 2.0, vW.y);
	ALBEDO = col * mix(0.38, 0.85, high);
	ALPHA = vA * exp(-r * r * 4.0) * smoothstep(0.0, 0.9, edge) * mix(1.0, 0.25, high);
}
"""

const WELL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 well = vec3(0.0);
uniform float r_in = 60.0;
uniform float r_out = 120.0;
uniform float k = 1.0;
uniform float chroma_px = 1.5;
varying vec3 vW;
varying vec4 vWell;
void vertex() {
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vWell = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(well, 1.0));
}
// Test the destination AND all three source samples. A ship must neither bend nor be copied into the background.
bool foreground(vec2 uv, mat4 inv_projection, mat4 inv_view) {
	float depth = texture(depth_tex, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 world = (inv_view * vec4(v.xyz / v.w, 1.0)).xyz;
	return depth > 0.000001 && world.y > -20.0;
}
void fragment() {
	float d = distance(vW.xz, well.xz);
	float w = smoothstep(r_in, r_in + 22.0, d) * (1.0 - smoothstep(r_out - 34.0, r_out, d));
	float rim = 1.0 - smoothstep(0.25, 0.65, abs(d - r_in - 2.0));
	float age = mod(TIME, 3.5);
	float travel = clamp(age / 2.0, 0.0, 1.0);
	float ripple = (1.0 - smoothstep(0.4, 1.15, abs(d - mix(r_out, r_in, travel)))) * (1.0 - travel);
	vec2 radial = vW.xz - well.xz;
	float angle = atan(radial.y, radial.x) - TIME * 0.13962634; // 45 s per turn
	float acc = smoothstep(22.0, 28.0, d) * (1.0 - smoothstep(54.0, r_in, d));
	acc *= 0.55 + 0.45 * sin(angle * 3.0 + d * 0.16);
	if (max(w, max(rim, max(ripple, acc))) <= 0.001 || foreground(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX)) { discard; }
	vec2 cs = vWell.xy / vWell.w * 0.5 + 0.5;
	vec2 dv = SCREEN_UV - cs;
	// pushed outward like a lens, and dragged slowly round
	float s = 0.075 * w * (r_in + 22.0) / max(d, 1.0);
	float an = 0.06 * w + 0.04 * w * sin(TIME * 0.20943951); // 30 s slow twist
	mat2 R = mat2(vec2(cos(an), sin(an)), vec2(-sin(an), cos(an)));
	vec2 suv = clamp(cs + R * dv * (1.0 - s), vec2(0.001), vec2(0.999));
	vec2 shift = normalize(dv + vec2(0.000001)) / vec2(textureSize(screen_tex, 0)) * chroma_px * rim;
	vec2 red_uv = clamp(suv + shift, vec2(0.001), vec2(0.999));
	vec2 blue_uv = clamp(suv - shift, vec2(0.001), vec2(0.999));
	if (foreground(suv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) || foreground(red_uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) || foreground(blue_uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX)) {
		suv = SCREEN_UV; red_uv = SCREEN_UV; blue_uv = SCREEN_UV;
	}
	vec3 c = vec3(textureLod(screen_tex, red_uv, 0.0).r, textureLod(screen_tex, suv, 0.0).g, textureLod(screen_tex, blue_uv, 0.0).b);
	vec3 warm = mix(vec3(0.15, 0.012, 0.005), vec3(0.55, 0.25, 0.10), 1.0 - smoothstep(24.0, r_in, d));
	c += warm * acc * 0.15;
	c += vec3(0.18, 0.085, 0.045) * ripple * 0.12;
	c += vec3(0.32, 0.40, 0.48) * rim;
	ALBEDO = c;
	ALPHA = max(w, max(rim * 0.35, max(ripple * 0.12, acc * 0.15))) * k;
}
"""

const INFALL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 well = vec3(0.0);
uniform float r_out = 87.0;
varying vec2 vQ;
varying float fade;
void vertex() {
	float inner = 20.0;
	float cycle = r_out * 0.5 * log((3.0 * r_out - 2.0 * inner) / r_out);
	float phase = fract(TIME / cycle + INSTANCE_CUSTOM.y);
	float radius = r_out * 1.5 - r_out * 0.5 * exp(2.0 * phase * cycle / r_out);
	// dr/dt = -(3 - 2r/R); the tangential speed is one fifth of the inward speed.
	float angle = INSTANCE_CUSTOM.z * 6.2831853 + 0.2 * log(r_out / radius);
	vec3 p = well + vec3(cos(angle) * radius, 9.0 + INSTANCE_CUSTOM.w * 3.0, sin(angle) * radius);
	vec4 c = VIEW_MATRIX * vec4(p, 1.0);
	vQ = VERTEX.xy * 2.0;
	c.xy += VERTEX.xy * INSTANCE_CUSTOM.x;
	POSITION = PROJECTION_MATRIX * c;
	fade = smoothstep(0.0, 0.08, phase) * (1.0 - smoothstep(0.85, 1.0, phase));
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	ALBEDO = vec3(0.32, 0.17, 0.12);
	ALPHA = 0.15 * fade * exp(-r * r * 4.0);
}
"""


func build(world) -> void:
	W = world
	var presenter: Node = W.get_parent()
	if presenter != null and presenter.has_signal("storm_drained"):
		_tick_presenter = presenter
		presenter.connect("storm_drained", _queue_storm_tick)
	rng.seed = int(W.setting.get("seed", 7)) * 31 + 991
	if bool(W.get("nebula_wake")):
		_wake = WAKE.new(W.quality)
	var pts: Dictionary = W._terr_pts
	# Background specks originally drew after gas at priority 0. Put them behind it.
	for child in W.get_children():
		if child is MultiMeshInstance3D and child.material_override is ShaderMaterial:
			var mat: ShaderMaterial = child.material_override
			if mat.shader.code == W.DUST_SHADER:
				mat.render_priority = -6
	for kind in ["neb", "storm"]:
		var patches := _patches(pts[kind])
		var broad_left := (pts[kind] as Array).size() / 3
		for j in patches.size():
			var broad := (patches[j] as Array).size() / 3 if j < patches.size() - 1 else broad_left
			_gas(patches[j], kind == "storm", broad)
			broad_left -= broad
			# issue 1434 (LOAD25 warm title: every gas patch in one 650 ms frame, 463 ms of it before the draw): a sliced
			# load builds one patch a frame
			if bool(W.get("slice_yield")):
				await get_tree().process_frame
				if not is_inside_tree():
					return   # issue 1519: a battle left mid-build waits out of the tree for its free; the build stops
	if bool(W.get("slice_yield")):
		await get_tree().process_frame
		if not is_inside_tree():
			return   # issue 1519: a battle left mid-build waits out of the tree for its free; the build stops
	if not (pts["storm"] as Array).is_empty():
		_bolts(pts["storm"])
	if bool(W.get("slice_yield")):
		await get_tree().process_frame
		if not is_inside_tree():
			return   # issue 1519: a battle left mid-build waits out of the tree for its free; the build stops
	if not (pts["debris"] as Array).is_empty():
		_debris(pts["debris"])
	if bool(W.get("slice_yield")):
		await get_tree().process_frame
		if not is_inside_tree():
			return   # issue 1519: a battle left mid-build waits out of the tree for its free; the build stops
	if W._well != Vector3.INF:
		_well(W._well)


func set_gas_k(k: float) -> void:
	for g in gas_mats:
		(g[0] as ShaderMaterial).set_shader_parameter("gain_a", float(g[1]) * k)
	for m in fog_mats:
		m.set_shader_parameter("gain_a", k)


func _quad_mm(n: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(1, 1)
	mm.mesh = qm
	mm.instance_count = n
	return mm


# ---------------------------------------------------------------- nebula and storm gas

# Connected components keep broad veils and materials local to each cloud.
func _patches(ps: Array) -> Array:
	var remaining := ps.duplicate()
	var patches: Array = []
	while not remaining.is_empty():
		var patch: Array = [remaining.pop_back()]
		var i := 0
		while i < patch.size():
			for j in range(remaining.size() - 1, -1, -1):
				if (patch[i] as Vector3).distance_squared_to(remaining[j]) < 18.0 * 18.0:
					patch.append(remaining[j])
					remaining.remove_at(j)
			i += 1
		patches.append(patch)
	return patches


static func _gas_card_shader(storm: bool, high: bool, cached_noise: bool) -> String:
	var code: String = ION.CARDS if storm else GAS_SHADER
	var noise: String = WS.NOISE_LATTICE if cached_noise else WS.NOISE
	if high:
		noise = "#define HIGH_GAS_CARDS\n" + noise
	return code.replace("%CARD_SUPPORT%", GAS_CARD_SUPPORT).replace("%NOISE%", noise)


func _gas(ps: Array, storm: bool, broad_count := -1) -> void:
	var low: bool = W.quality == "low"
	var expanded := gas_route != "today"
	var volume: bool = gas_route == "fog" and W.quality == "max"
	# step 2: fewer, broader, softer puffs; their shape comes from one noise field and the patch's footprint (_mask), so
	# the patch reads as one body of gas, not a row of cotton balls on hex tiles
	var per := 3 if low else 5
	if expanded:
		per = 2 if volume or low else 5
	var n_big := ps.size() / 3 if broad_count < 0 else broad_count
	var mm := _quad_mm(ps.size() * per + n_big)
	var i := 0
	for p in ps:
		for k in per:
			var a := rng.randf() * TAU
			var rr := sqrt(rng.randf()) * GAS_PUFF_REACH
			# Preserve the count and size; split the existing puffs into height bands.
			var layer: int = [0, 1, 2, 1, 2][k % 5]
			# Low drops the dim bottom puff, retaining the core and upper layer.
			if expanded and low:
				layer = k + 1
			var y := rng.randf_range(-2.5, 0.5) if layer == 0 else (rng.randf_range(2.5, 6.5) if layer == 1 else rng.randf_range(8.0, 12.0))
			if expanded:
				y *= GAS_HEIGHT
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, (p as Vector3) + Vector3(cos(a) * rr, y, sin(a) * rr)))
			mm.set_instance_custom_data(i, Color(rng.randf_range(GAS_PUFF_MIN, GAS_PUFF_MAX), rng.randf(), rng.randf_range(0.55, 0.85), layer + rng.randf() * 0.9))
			if expanded:
				var cd := mm.get_instance_custom_data(i)
				cd.r *= GAS_CLOUD_SCALE
				cd.b *= 0.55 if volume else 1.0
				mm.set_instance_custom_data(i, cd)
			i += 1
	# One or two existing broad puffs become a very faint high tying veil.
	for k in n_big:
		var p: Vector3 = ps[rng.randi() % ps.size()]
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p + Vector3(rng.randf_range(-4, 4), rng.randf_range(13.5, 16.5) if k < 2 else rng.randf_range(2.5, 6.5), rng.randf_range(-4, 4))))
		mm.set_instance_custom_data(i, Color(rng.randf_range(GAS_VEIL_MIN, GAS_VEIL_MAX), rng.randf(), rng.randf_range(0.3, 0.4), (3 if k < 2 else 1) + rng.randf() * 0.9))
		if expanded:
			var transform := mm.get_instance_transform(i)
			transform.origin.y *= GAS_HEIGHT
			mm.set_instance_transform(i, transform)
			var custom := mm.get_instance_custom_data(i)
			custom.r *= GAS_CLOUD_SCALE
			custom.b *= 0.55 if volume else 1.0
			mm.set_instance_custom_data(i, custom)
		i += 1
	var mi := MultiMeshInstance3D.new()
	mi.name = "Storm" if storm else "Nebula"
	mi.multimesh = mm
	var m := ShaderMaterial.new()
	# Issue 1262: Max uses the same bounded cards and baked lattice as High (1070's masking saved 2.2 ms on Max in its
	# run 1); VS_1262_OLD=cards restores Max's unbounded cards for the before and after timing.
	var high: bool = expanded and (W.quality == "high" or (W.quality == "max" and not LOOK.perf_old("cards")))
	if high and _gas_lattice == null and ResourceLoader.exists(GAS_LATTICE_PATH):
		var source = load(GAS_LATTICE_PATH)
		_gas_lattice = source.texture()
		_gas_lattice_origin = source.origin
	var cached_noise := high and _gas_lattice != null
	var code := _gas_card_shader(storm, high, cached_noise)
	if _wake != null and not storm:
		code = WAKE.into_cards(code, _wake.points)
		_wake_mats.append(m)
	m.shader = SHADER_CACHE.for_code(code)
	if cached_noise:
		m.set_shader_parameter("gas_hash_lattice", _gas_lattice)
		m.set_shader_parameter("gas_hash_origin", _gas_lattice_origin)
	if expanded:
		m.set_shader_parameter("height_scale", GAS_HEIGHT)
	m.set_shader_parameter("sun_v", Vector3(0.45, 0.70, 0.55))   # world.gd SUN
	if OS.get_environment("VS_GAS_FLAT") == "1":
		m.set_shader_parameter("flat_rates", 1.0)   # capture variant only (#230 NB8); never set in play
	var mk: Array = _mask(ps, 1.5 if storm else 2.0)
	m.set_shader_parameter("mask_tex", mk[0])
	m.set_shader_parameter("mask_box", mk[1])
	var g := 1.0
	if storm:
		# R282: the cloud carries broad cool charge, not the old warm contour veins.
		storm_mats.append(m)
		_storm_patches.append({"mat": m, "points": ps, "pending": [], "flares": []})
		_set_flashes([])
	else:
		m.set_shader_parameter("c_dark", NEBULA_DARK)
		m.set_shader_parameter("c_shadow", NEBULA_SHADOW)
		m.set_shader_parameter("c_lit", NEBULA_LIT)
		m.set_shader_parameter("c_glow", NEBULA_GLOW)
		m.set_shader_parameter("dens", 0.5)
		_sheet_colour_override(m)
	# drawn before the board's own fills, so a move hex inside the gas still shows on top
	m.render_priority = -5
	gas_mats.append([m, g])
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Vertex-expanded cards need bounds that include their scaled visible radius.
	mi.extra_cull_margin = GAS_VEIL_MAX * GAS_CLOUD_SCALE * 0.5 + GAS_PUFF_REACH if expanded else 30.0
	add_child(mi)
	if volume:
		_fog_patch(ps, m, mk, storm)


func _fog_patch(ps: Array, card: ShaderMaterial, mk: Array, storm: bool) -> void:
	const NOISE_PATH := "res://world/nebula_noise.res"
	if not ResourceLoader.exists(NOISE_PATH):
		push_error("Issue 368: bake world/nebula_noise_bake.gd before the fog bench")
		return
	var lo: Vector3 = ps[0]
	var hi := lo
	for point in ps:
		lo = lo.min(point)
		hi = hi.max(point)
	var volume := FogVolume.new()
	volume.name = "StormFog368" if storm else "NebulaFog368"
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	volume.size = Vector3(hi.x - lo.x + GAS_FEATHER_REACH * 2.0, 38.5, hi.z - lo.z + GAS_FEATHER_REACH * 2.0)
	volume.position = Vector3((hi.x + lo.x) * 0.5, 12.25, (hi.z + lo.z) * 0.5)
	var mat := ShaderMaterial.new()
	var code: String = ION.FOG if storm else FOG_SHADER
	if _wake != null and not storm:
		code = WAKE.into_fog(code, _wake.points)
		_wake_mats.append(mat)
	mat.shader = SHADER_CACHE.for_code(code)
	if _fog_noise == null:
		_fog_noise = load(NOISE_PATH).texture()
	mat.set_shader_parameter("noise_tex", _fog_noise)
	mat.set_shader_parameter("mask_tex", mk[0])
	mat.set_shader_parameter("mask_box", mk[1])
	for key in ["c_dark", "c_shadow", "c_lit", "c_glow"]:
		if storm: continue
		# Shader defaults are not returned by get_shader_parameter until set.
		var value = card.get_shader_parameter(key)
		if value == null:
			value = Vector3(0.055, 0.012, 0.14) if key == "c_shadow" else Vector3(0.006, 0.002, 0.014)
		mat.set_shader_parameter(key, value)
	if storm:
		storm_mats.append(mat)
		_storm_patches.back()["fog_mat"] = mat
	else:
		mat.set_shader_parameter("storm", 0.0)
	volume.material = mat
	fog_mats.append(mat)
	add_child(volume)


# the patch's footprint as a small two-channel float texture over its hexes (one texel per world unit): r the soft
# round field (a Gaussian round each hex centre, summed), g the inward feather of the external boundary; returns [texture, Vector4(x0, z0, 1/w, 1/h)]
func _mask(ps: Array, feather := 2.0) -> Array:
	const HIN := 8.660254          # a hex's inner radius (corner radius 10, board.gd HS)
	const STEP := 1.0
	const SIG2 := 42.0             # the round field's spread (squared): about a fifth of a hex centre's strength at its edge
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for p in ps:
		lo = lo.min(Vector2((p as Vector3).x, (p as Vector3).z))
		hi = hi.max(Vector2((p as Vector3).x, (p as Vector3).z))
	var expanded := gas_route != "today"
	var margin := GAS_CLOUD_MARGIN if expanded else GAS_MASK_MARGIN
	lo -= Vector2(margin, margin)
	hi += Vector2(margin, margin)
	var w := int(ceil((hi.x - lo.x) / STEP)) + 1
	var h := int(ceil((hi.y - lo.y) / STEP)) + 1
	var f := PackedFloat32Array()
	f.resize(w * h * 2)
	for j in w * h:
		f[j * 2] = 0.0
		f[j * 2 + 1] = 2.0
	for p in ps:
		var c := Vector2((p as Vector3).x, (p as Vector3).z)
		var reach := GAS_FIELD_REACH if expanded else 14.0
		var x0 := int((c.x - reach - lo.x) / STEP)
		var z0 := int((c.y - reach - lo.y) / STEP)
		for zi in range(maxi(z0, 0), mini(z0 + int(reach * 2.0 / STEP) + 2, h)):
			var dz := absf(lo.y + zi * STEP - c.y)
			for xi in range(maxi(x0, 0), mini(x0 + int(reach * 2.0 / STEP) + 2, w)):
				var dx := absf(lo.x + xi * STEP - c.x)
				var j := (zi * w + xi) * 2
				var q := dx * dx + dz * dz
				if expanded:
					# Issue 1263: a round window, so the field reaches zero smoothly instead of at a square's side.
					f[j] += exp(-q / GAS_FIELD_SIG2) * (1.0 - smoothstep(GAS_FIELD_FADE, GAS_FIELD_REACH, sqrt(q)))
				else:
					f[j] += exp(-q / SIG2)
				var d := maxf(dx, 0.5 * dx + 0.8660254 * dz) / HIN
				if expanded: d /= GAS_CLOUD_SCALE
				if d < f[j + 1]:
					f[j + 1] = d
	# Shared edges are not boundaries. Feather inward from only the union's outside.
	var edges: Array = []
	for p in ps:
		var c := Vector2((p as Vector3).x, (p as Vector3).z)
		for k in 6:
			var normal := Vector2(cos(k * TAU / 6.0), sin(k * TAU / 6.0))
			var neighbor := c + normal * HIN * 2.0
			var shared := false
			for q in ps:
				if neighbor.distance_squared_to(Vector2((q as Vector3).x, (q as Vector3).z)) < 0.1:
					shared = true
					break
			if not shared:
				var tangent := Vector2(-normal.y, normal.x) * 5.0
				edges.append([c + normal * HIN - tangent, c + normal * HIN + tangent])
	for zi in h:
		for xi in w:
			var j := (zi * w + xi) * 2 + 1
			if gas_route != "today":
				# The marked hex samples a larger cloud. Feather past the union, including its outside.
				f[j] = 1.0 - smoothstep(0.65, GAS_FEATHER_END, f[j])
				continue
			if f[j] >= 1.0:
				f[j] = 0.0
				continue
			var point := lo + Vector2(xi, zi) * STEP
			var distance_to_edge := feather
			for edge in edges:
				var a: Vector2 = edge[0]
				var ab: Vector2 = edge[1] - a
				var near := a + ab * clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
				distance_to_edge = minf(distance_to_edge, point.distance_to(near))
			f[j] = smoothstep(0.0, feather, distance_to_edge)
	var img := Image.create_from_data(w, h, false, Image.FORMAT_RGF, f.to_byte_array())
	return [ImageTexture.create_from_image(img), Vector4(lo.x - 0.5 * STEP, lo.y - 0.5 * STEP, 1.0 / (w * STEP), 1.0 / (h * STEP)), img]


func cloud_span() -> float:
	var mask: Array = _mask([Vector3.ZERO])
	var image: Image = mask[2]
	var first := image.get_width()
	var last := -1
	for x in image.get_width():
		if image.get_pixel(x, image.get_height() / 2).g > 0.001:
			first = mini(first, x)
			last = maxi(last, x)
	return float(last - first + 1) / (mask[1].z * image.get_width())


func _set_flashes(fs: Array) -> void:
	fs.sort_custom(func(a, z): return a.w > z.w)
	var arr: Array = []
	for k in 8:
		arr.append(fs[k] if k < fs.size() else Vector4.ZERO)
	for mat in storm_mats:
		mat.set_shader_parameter("flashes", arr)


# Run 6: every patch has several channels, each with clearly separated forks.
# Reuse the accepted cloud and scene bloom. Geometry lives inside the gas.
func _bolts(ps: Array) -> void:
	var bm := ShaderMaterial.new()
	bm.shader = SHADER_CACHE.for_code(BOLT_SHADER)
	var lit := 0
	for patch in _patches(ps):
		var center := Vector3.ZERO
		for point in patch: center += point
		var burst := {"center": center / float(patch.size()), "bolts": [], "next": rng.randf_range(0.3, 3.5)}
		_storm_bursts.append(burst)
		var count := clampi(ceili(float(patch.size()) / 2.0), 2, 4)
		var anchors: Array = []
		for index in count:
			# Farthest unused cloud mass first, with local spread for a one-hex patch.
			var anchor: Vector3 = patch[rng.randi() % patch.size()]
			var best := -1.0
			for point in patch:
				var nearest := INF
				for used in anchors: nearest = minf(nearest, point.distance_squared_to(used))
				if nearest > best:
					best = nearest
					anchor = point
			anchors.append(anchor)
			var angle := float(index) * TAU / float(count) + rng.randf_range(-0.25, 0.25)
			var a := anchor + Vector3(cos(angle) * 5.0, rng.randf_range(12.0, 22.0), sin(angle) * 5.0)
			var z := a + Vector3(cos(angle + 1.0) * 10.0, rng.randf_range(-10.0, -5.0), sin(angle + 1.0) * 10.0)
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var path := _jag(a, z, 9, 0.09)
			_ribbon(st, path, 0.20, 1.15)
			var forks := rng.randi_range(2, 4)
			var fork_paths: Array = []
			for k in forks:
				var j := 2 + k * (path.size() - 4) / forks
				var start: Vector3 = path[j]
				# Alternating wide angles keep forks separate in the battle camera.
				var turn := (0.85 + float(k) * 0.18) * (1.0 if k % 2 == 0 else -1.0)
				var direction := (z - a).normalized().rotated(Vector3.UP, turn)
				var tip := start + direction * rng.randf_range(7.0, 11.0) + Vector3(0, rng.randf_range(0.0, 5.0), 0)
				var fork := _jag(start, tip, 6, 0.11)
				_ribbon(st, fork, 0.115, 0.85, true)
				fork_paths.append(fork)
			var mi := MeshInstance3D.new()
			mi.mesh = st.commit()
			mi.material_override = bm
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			var light: OmniLight3D = null
			if lit < 4:
				light = OmniLight3D.new()
				light.light_color = Color(0.52, 0.74, 1.0)
				light.omni_range = 40.0
				light.omni_attenuation = 1.4
				light.shadow_enabled = false
				light.light_volumetric_fog_energy = 1.4 if gas_route == "fog" and W.quality == "max" and lit < 2 else 0.0
				light.light_energy = 0.0
				light.position = (a + z) * 0.5
				add_child(light)
				lit += 1
			var bolt := {"mi": mi, "light": light, "pos": (a + z) * 0.5,
				"next": burst.next, "start": -10.0, "soft": false, "fork_paths": fork_paths, "path": path}
			bolts.append(bolt)
			burst.bolts.append(bolt)


func _jag(a: Vector3, z: Vector3, n: int, amp: float) -> Array:
	var out: Array = [a]
	var len := a.distance_to(z)
	for i in range(1, n):
		var t := float(i) / n
		out.append(a.lerp(z, t) + Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * len * amp)
	out.append(z)
	return out


# A continuous six-sided hot channel, with two joined soft skirts around it.
# Shared rings avoid the bright rectangular wedges of separate segment quads.
func _ribbon(st: SurfaceTool, path: Array, w_core: float, w_glow: float, branch := false) -> void:
	var frames: Array = []
	for i in path.size():
		var tangent: Vector3 = (path[mini(i + 1, path.size() - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := tangent.cross(Vector3.UP)
		if side.length() < 0.1: side = tangent.cross(Vector3.RIGHT)
		side = side.normalized()
		if i > 0 and side.dot(frames.back()[0]) < 0.0: side = -side
		frames.append([side, tangent.cross(side).normalized()])
	for i in path.size() - 1:
		var p0: Vector3 = path[i]
		var p1: Vector3 = path[i + 1]
		var taper0 := lerpf(1.0, 0.06, float(i) / float(path.size() - 1)) if branch else _main_taper(i, path.size())
		var taper1 := lerpf(1.0, 0.06, float(i + 1) / float(path.size() - 1)) if branch else _main_taper(i + 1, path.size())
		for ring in 6:
			var a := float(ring) * TAU / 6.0
			var z := float(ring + 1) * TAU / 6.0
			var u0: Vector3 = p0 + (frames[i][0] * cos(a) + frames[i][1] * sin(a)) * w_core * taper0
			var u1: Vector3 = p0 + (frames[i][0] * cos(z) + frames[i][1] * sin(z)) * w_core * taper0
			var v0: Vector3 = p1 + (frames[i+1][0] * cos(a) + frames[i+1][1] * sin(a)) * w_core * taper1
			var v1: Vector3 = p1 + (frames[i+1][0] * cos(z) + frames[i+1][1] * sin(z)) * w_core * taper1
			for vertex in [u0, v0, v1, u0, v1, u1]:
				st.set_color(Color(1.0 if branch else 0.0, 1.0, 0.0, 1.0))
				st.add_vertex(vertex)
		for axis in 2:
			_quad(st, p0, p1, frames[i][axis] * w_glow * taper0, frames[i+1][axis] * w_glow * taper1, 0.30, branch, false)
			_quad(st, p0, p1, frames[i][axis] * w_glow * 1.3 * taper0, frames[i+1][axis] * w_glow * 1.3 * taper1, 0.16, branch, true)


# Issue 1269: the main channel narrows over its last two rings at both ends,
# so a close (c26) bolt ends in a point instead of a flat cut.
static func _main_taper(ring: int, count: int) -> float:
	var from_end := mini(ring, count - 1 - ring)
	return 0.12 if from_end == 0 else (0.55 if from_end == 1 else 1.0)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, side0: Vector3, side1: Vector3, alpha: float, branch: bool, corona: bool) -> void:
	var cm := Color(1.0 if branch else 0.0, 0.0, 1.0 if corona else 0.0, alpha)
	var ce := Color(cm.r, cm.g, cm.b, 0.0)
	for sgn in [1.0, -1.0]:
		var e0: Vector3 = p0 + side0 * sgn
		var e1: Vector3 = p1 + side1 * sgn
		for v in [[p0, cm], [p1, cm], [e1, ce], [p0, cm], [e1, ce], [e0, ce]]:
			st.set_color(v[1])
			st.add_vertex(v[0])


# One rise and a cooling tail per strike. No second full-field flash on a dip.
# Reduced or refused flashes keep their geometry and ease through a lower peak.
static func _flash(t: float, soft := false) -> float:
	if t < 0.0: return 0.0
	if soft:
		return smoothstep(0.0, 0.20, t) * (1.0 - smoothstep(0.28, 0.9, t)) * 0.22
	return smoothstep(0.0, 0.018, t) * (1.0 - smoothstep(0.055, 0.52, t)) * exp(-t * 1.8)


func _start_storm_burst(burst: Dictionary) -> void:
	var effects = _tick_presenter.get("gfx") if is_instance_valid(_tick_presenter) else null
	for index in burst.bolts.size():
		var bolt: Dictionary = burst.bolts[index]
		var delay := float(index) * 0.075
		bolt.start = clock + delay
		bolt.soft = false
		if is_instance_valid(effects):
			# Book the lit gas and bloom as a conservative 48-unit disc. Storms
			# share the real fight's area counter, including other weapon effects.
			bolt.soft = not effects.flash_at(bolt.pos, effects.now + delay, 48.0, 0.0, 0.52)
	burst.next = clock + rng.randf_range(2.2, 6.5)


static func _instance_shader_ready(mi: MeshInstance3D) -> bool:
	return DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "dummy" and is_instance_valid(mi) and mi.material_override != null


func _queue_storm_tick(pos: Vector3) -> void:
	if not visible:
		return
	for patch in _storm_patches:
		for p in patch.points:
			if Vector2(pos.x - p.x, pos.z - p.z).length_squared() <= 100.0:
				patch.pending.append(pos)
				return


func _present_storm_ticks(reduced: bool) -> void:
	for patch in _storm_patches:
		var pending: Array = patch.pending
		var flares: Array = patch.flares
		if pending.is_empty() and flares.is_empty():
			continue
		while not flares.is_empty() and clock - float(flares.front().start) >= STORM_TICK_LIFE:
			flares.pop_front()
		var effects = _tick_presenter.get("gfx") if is_instance_valid(_tick_presenter) else null
		# An unusually large batch waits for free shader slots. Book each cue
		# when it starts so the counter sees weapon and lightning overlap.
		while not pending.is_empty() and flares.size() < ION.TICK_FLARE_SLOTS:
			var pos: Vector3 = pending.pop_front()
			var soft: bool = is_instance_valid(effects) and not effects.flash_at(pos, effects.now, 36.0, 0.0, STORM_TICK_LIFE)
			flares.append({"pos": pos, "start": clock, "soft": soft})
		var values := PackedVector4Array()
		if not flares.is_empty():
			values.resize(ION.TICK_FLARE_SLOTS)
			for i in flares.size():
				var flare: Dictionary = flares[i]
				var soft: bool = reduced or flare.soft
				var envelope := 0.9 if soft else 0.52
				var age := (clock - float(flare.start)) / STORM_TICK_LIFE
				var pos: Vector3 = flare.pos
				values[i] = Vector4(pos.x, pos.y, pos.z, _flash(age * envelope, soft))
		_set_storm_tick_uniforms(patch.mat, values, flares.size())
		if patch.has("fog_mat"):
			_set_storm_tick_uniforms(patch.fog_mat, values, flares.size())


func _set_storm_tick_uniforms(mat: ShaderMaterial, values: PackedVector4Array, count: int) -> void:
	if count > 0:
		mat.set_shader_parameter("tick_flares", values)
	mat.set_shader_parameter("tick_flare_count", count)


func _process(dt: float) -> void:
	if not visible:
		return
	clock += dt
	for spin in _hull_spin:
		(spin[0] as Node3D).rotate(spin[1], float(spin[2]) * dt)
	for g in gas_mats:
		(g[0] as ShaderMaterial).set_shader_parameter("gas_time", clock)
	for m in fog_mats:
		m.set_shader_parameter("gas_time", clock)
	if _wake != null and not _wake_mats.is_empty():
		var views = W.get_parent().get("views") if W.get_parent() != null else null
		_wake.update(dt, (views as Dictionary).values() if views is Dictionary else [])
		_wake.apply(_wake_mats)
	var reduced := is_instance_valid(_tick_presenter) and bool(_tick_presenter.get("reduce_flashing"))
	_present_storm_ticks(reduced)
	for burst in _storm_bursts:
		if clock >= float(burst.next): _start_storm_burst(burst)
	var fs: Array = []
	for b in bolts:
		var v := _flash(clock - float(b["start"]), bool(b.get("soft", false)) or reduced)
		var mi := b["mi"] as MeshInstance3D
		if _instance_shader_ready(mi):
			mi.set_instance_shader_parameter("flash", v)
			mi.set_instance_shader_parameter("branch_flash", _flash((clock - float(b["start"])) * 1.6, bool(b.get("soft", false)) or reduced))
		if b["light"] != null:
			(b["light"] as OmniLight3D).light_energy = v * 1.2
		if v > 0.0:
			var p: Vector3 = b["pos"]
			fs.append(Vector4(p.x, p.y, p.z, v))
	_set_flashes(fs)


# ---------------------------------------------------------------- debris: dense rock and wreck clusters

static var _piece_radii := {}   # not GPU: piece radii (numbers)

static func _piece_radius(mesh: Mesh) -> float:
	var id := mesh.get_instance_id()
	if not _piece_radii.has(id):
		var radius := 0.0
		for surface in mesh.get_surface_count():
			for vertex in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				radius = maxf(radius, (vertex as Vector3).length())
		_piece_radii[id] = radius
	return float(_piece_radii[id])


# Reserve every hex centre, including the six neighbours. A ship entering a debris hex
# gets the same four-unit gap as a ship already there, without moving any scenery.
static func _clear_of_hexes(offset: Vector3, radius: float) -> bool:
	var point := Vector2(offset.x, offset.z)
	if point.length() < 4.0 + radius: return false
	for k in 6:
		var neighbour := Vector2(cos(k * TAU / 6.0), sin(k * TAU / 6.0)) * 17.320508
		if point.distance_to(neighbour) < 4.0 + radius: return false
	return true


func _clump_pose(p: Vector3, clump: Vector3, radius: float, raised: bool) -> Vector3:
	var offset := Vector3.ZERO
	for attempt in 64:
		var angle := atan2(clump.z, clump.x) + rng.randf_range(-0.20, 0.20)
		var reach := clampf(clump.length() + rng.randf_range(-1.0, 1.0), 4.15 + radius, maxf(8.6, 4.15 + radius))
		offset = Vector3(cos(angle) * reach, 0.0, sin(angle) * reach)
		if _clear_of_hexes(offset, radius): break
	assert(_clear_of_hexes(offset, radius), "Debris could not preserve the ship clear zone")
	# A sphere bounds the complete tumble. Only one anchor per patch can rise above the midline.
	offset.y = -radius * 0.3 if raised else -radius - rng.randf_range(0.25, 1.4)
	return p + offset


func _debris(ps: Array) -> void:
	# world.gd also built the old scatter through add_debris_rocks. Its own material
	# flag lets the two looks share meshes without leaving hidden rocks in the ship gaps.
	for child in W.get_children():
		if child is MultiMeshInstance3D and child.material_override is ShaderMaterial:
			var old: ShaderMaterial = child.material_override
			if old.get_shader_parameter("legacy_debris") == true and old not in _legacy_debris_mats:
				_legacy_debris_mats.append(old)
	_sync_legacy_debris()
	var kind: String = W._rock_kind
	var mat: ShaderMaterial = W._mat(kind).duplicate()
	mat.set_shader_parameter("debris_glint", 1.0)
	mat.set_shader_parameter("sun_v", W.SUN)
	var batch = WR.Batch.new()
	var low: bool = W.quality == "low"
	var shard_meshes := _shard_meshes()
	var metal := ShaderMaterial.new()
	metal.shader = SHADER_CACHE.for_code(WRECK_SHADER.replace("%NOISE%", WS.NOISE))
	var hot := ShaderMaterial.new()
	hot.shader = metal.shader
	hot.set_shader_parameter("hot", 1.0)
	for wm in [metal, hot]:
		(wm as ShaderMaterial).set_shader_parameter("tumble_k", TUMBLE_K if tumble_mode == "cap" else 1000.0)
		(wm as ShaderMaterial).set_shader_parameter("sun_v", W.SUN)
		(wm as ShaderMaterial).set_shader_parameter("detail_k", 0.0 if low else 1.0)
	var hot_materials := {}
	for mk in shard_meshes.size():
		var hm := hot.duplicate() as ShaderMaterial
		var points := _hot_points(shard_meshes[mk])
		for i in 3: hm.set_shader_parameter("hot_p%d" % i, points[i])
		hot_materials[mk] = hm
	var shards := {}     # "mesh|mat" -> [{xf, cd}]
	var slots: Array = []
	var dust: Array = []
	var raised := {}
	for patch in _patches(ps): raised[patch[0]] = true
	for p in ps:
		var clumps: Array[Vector3] = []
		var phase := rng.randf() * TAU
		var count := rng.randi_range(2, 3)
		for j in count:
			var angle := phase + j * TAU / count + rng.randf_range(-0.15, 0.15)
			clumps.append(Vector3(cos(angle), 0, sin(angle)) * rng.randf_range(6.5, 7.8))
		var orbiting := false
		if W._well != Vector3.INF:
			var dr := roundi(((p as Vector3).z - W._well.z) / 15.0)
			var dq := roundi(((p as Vector3).x - W._well.x) / 17.320508 - dr * 0.5)
			var ring := (absi(dq) + absi(dr) + absi(dq + dr)) / 2
			orbiting = ring >= 3 and ring <= 4
		var tangent := Vector3.ZERO
		if orbiting:
			var radial: Vector3 = (p as Vector3) - W._well
			tangent = Vector3(-radial.z, 0, radial.x).normalized()
		var rocks: Array = []
		for i in (rng.randi_range(8, 12) if low else rng.randi_range(15, 22)):
			var s := DEBRIS_ROCK_MIN + (DEBRIS_ROCK_MAX - DEBRIS_ROCK_MIN) * pow(rng.randf(), 2.4)
			var nm: String = W._pick(kind, rng)
			if nm == "":
				break
			var radius := _piece_radius(WR.mesh(nm)) * s
			var basis: Basis = W._rand_basis(rng)
			if orbiting: basis = Basis.from_euler(Vector3(rng.randf_range(-0.2, 0.2), atan2(-tangent.z, tangent.x), rng.randf_range(-0.2, 0.2)))
			rocks.append({"mesh": nm, "shadow": s > 1.8,
				"xf": Transform3D(basis.scaled(Vector3.ONE * s), _clump_pose(p, clumps[i % count], radius, false)),
				"axis": basis.inverse() * Vector3.UP if orbiting else W._rand_axis(rng), "rate": rng.randf_range(0.05, 0.3), "seed": rng.randf()})
		add_debris_rocks(batch, rocks, mat)
		# step 2: wreckage that reads as wreckage: mostly mid-size pieces, and often one big one that carries the patch's
		# silhouette at battle distance
		var last_slot := {}
		for i in rng.randi_range(3, 5) + (1 if rng.randf() < 0.55 else 0):
			var mk := rng.randi() % shard_meshes.size()
			var mt := 1 if rng.randf() < 0.22 else 0
			var key := "%d|%d" % [mk, mt]
			if not shards.has(key):
				shards[key] = []
			var sc := rng.randf_range(1.3, 2.6) if i > 0 else rng.randf_range(2.6, 3.8)
			if i == 0:
				var size_v: Vector3 = (shard_meshes[mk] as Mesh).get_aabb().size
				sc = maxf(sc, 4.0 / maxf(size_v.x, maxf(size_v.y, size_v.z)))
			var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * sc)
			if orbiting:
				b = Basis.from_euler(Vector3(rng.randf_range(-0.25, 0.25), atan2(-tangent.z, tangent.x), rng.randf_range(-0.25, 0.25))).scaled(Vector3.ONE * sc)
			var radius := _piece_radius(shard_meshes[mk]) * sc
			var xf := Transform3D(b, _clump_pose(p, clumps[i % count], radius, i == 0 and raised.has(p)))
			# Derive the animation from the pose, without changing the seeded layout.
			var spin := wreck_tumble(sc, xf.origin)
			var axis := (b.orthonormalized().inverse() * Vector3.UP if orbiting else b.x.normalized()) * spin
			last_slot = {"key": key, "index": shards[key].size(), "xf": xf, "scale": sc, "axis": axis, "rate": spin, "orbiting": orbiting}
			shards[key].append({"xf": xf, "cd": Color(axis.x, axis.y, axis.z, 0.0 if orbiting else float(mk) / 6.0)})
		slots.append(last_slot)
		for j in (16 if low else 48):
			var clump: Vector3 = clumps[j % count]
			var at: Vector3 = p + clump + Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(-4.0, 1.0), rng.randf_range(-1.5, 1.5))
			dust.append({"at": at, "size": rng.randf_range(0.15, 0.42), "alpha": rng.randf_range(0.06, 0.10), "hex": p})
		# The same sparse tan haze on both tiers. Particle count is reduced before presence.
		for clump in clumps:
			dust.append({"at": p + clump + Vector3(0, -2.5, 0), "size": 4.5, "alpha": 0.06, "hex": p})
	var n := batch.build(self, Callable(WR, "mesh"))
	var instances := {}
	for key in shards:
		var parts: PackedStringArray = str(key).split("|")
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = shard_meshes[int(parts[0])]
		var xs: Array = shards[key]
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i].xf)
			mm.set_instance_custom_data(i, xs[i].cd)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "WreckKit_%s_%s" % [WRECK_NAMES[int(parts[0])], parts[1]]
		mmi.set_meta("wreck_piece", WRECK_NAMES[int(parts[0])])
		mmi.multimesh = mm
		mmi.material_override = hot_materials[int(parts[0])] if parts[1] == "1" else metal
		mmi.extra_cull_margin = 8.0     # the shader tumbles each piece about its middle
		add_child(mmi)
		instances[key] = mmi
		n += xs.size()
	for slot in slots:
		slot["mmi"] = instances[slot.key]
		_wreck_slots.append(slot)
	if not dust.is_empty():
		var mm := _quad_mm(dust.size())
		for i in dust.size():
			var particle: Dictionary = dust[i]
			mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, particle.at))
			mm.set_instance_custom_data(i, Color(particle.size, particle.alpha, particle.hex.x, particle.hex.z))
		var mi := MultiMeshInstance3D.new()
		mi.name = "DebrisDust"
		mi.multimesh = mm
		var m := ShaderMaterial.new()
		m.shader = SHADER_CACHE.for_code(DUST_SHADER)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 10.0
		add_child(mi)
	W.notes.append("living debris: %d rocks and wreck pieces on %d hexes" % [n, ps.size()])
	W.notes.append("debris: 2 to 3 sub-clumps, four-unit ship gaps, tan dust %d, sun glints, three hot points per heated kit piece" % dust.size())
	W.notes.append("legacy debris: %d materials hidden in living/cine and restored in today/holo" % _legacy_debris_mats.size())


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_legacy_debris()


func _sync_legacy_debris() -> void:
	for mat in _legacy_debris_mats:
		mat.set_shader_parameter("living_terrain", is_visible_in_tree())


# Pick three separated points on the kit's authored torn edges, once per mesh.
# The shader intersects these small disjoint spheres with vertex alpha, never lights an entire edge.
static func _hot_points(mesh: Mesh) -> Array[Vector3]:
	var candidates: Array[Vector3] = []
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		for i in vertices.size():
			if colors.size() > i and colors[i].a > 0.5: candidates.append(vertices[i])
	var points: Array[Vector3] = []
	for i in 3:
		var best := -1.0
		var picked := Vector3(100, 100, 100)
		for candidate in candidates:
			var nearest := candidate.length_squared() if points.is_empty() else INF
			for point in points: nearest = minf(nearest, point.distance_squared_to(candidate))
			if nearest > best:
				best = nearest
				picked = candidate
		points.append(picked)
	return points


# Six Blender ship-kit pieces. RGB stores paint; alpha marks hot torn edges.
const WRECK_SHADER := """
shader_type spatial;
render_mode cull_disabled;
""" + "%NOISE%" + """
uniform float hot = 0.0;
uniform vec3 hot_col = vec3(1.0, 0.42, 0.12);
uniform float tumble_k = 0.10;   // TUMBLE_K, the #230 figure of record; the periods capture variant lifts it
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform float detail_k = 1.0;
uniform vec3 hot_p0 = vec3(100.0);
uniform vec3 hot_p1 = vec3(100.0);
uniform vec3 hot_p2 = vec3(100.0);
varying vec3 lp;

void vertex() {
	// a slow tumble, each piece its own axis and speed, about the piece's own middle
	float h = INSTANCE_CUSTOM.w;
	float rate = length(INSTANCE_CUSTOM.xyz);
	vec3 ax = INSTANCE_CUSTOM.xyz / max(rate, 0.000001);
	float scale_v = length(MODEL_MATRIX[0].xyz);
	float an = TIME * min(rate, tumble_k / max(1.0, scale_v)) + h * 6.2831;
	float c = cos(an);
	float s = sin(an);
	mat3 R = mat3(vec3(c + ax.x * ax.x * (1.0 - c), ax.y * ax.x * (1.0 - c) + ax.z * s, ax.z * ax.x * (1.0 - c) - ax.y * s),
		vec3(ax.x * ax.y * (1.0 - c) - ax.z * s, c + ax.y * ax.y * (1.0 - c), ax.z * ax.y * (1.0 - c) + ax.x * s),
		vec3(ax.x * ax.z * (1.0 - c) + ax.y * s, ax.y * ax.z * (1.0 - c) - ax.x * s, c + ax.z * ax.z * (1.0 - c)));
	lp = VERTEX;
	VERTEX = R * VERTEX;
	NORMAL = R * NORMAL;
}
void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
	float g = wfbm3(lp * 2.3);
	float dirt = wfbm3(lp * 19.0 + 7.1);
	float pits = detail_k > 0.5 ? wfbm3(lp * 83.0) : 0.5;
	// panel seams on the plates, and grime and wear
	vec3 q = abs(fract(lp * vec3(1.6, 1.25, 1.6)) - 0.5);
	float seam = 1.0 - 0.38 * (1.0 - smoothstep(0.0, 0.035, 0.5 - max(max(q.x, q.y), q.z)));
	ALBEDO = COLOR.rgb * mix(0.38, 1.05, g) * mix(0.65, 1.15, dirt) * seam;
	// Local pitting stays attached to the metal during tumble. Fade the finest
	// layer below a pixel rather than letting it shimmer at battle distance.
	float fine_k = 1.0 - smoothstep(0.3, 1.2, length(fwidth(lp * 83.0)));
	float height = dirt * 0.006 + pits * 0.002 * fine_k;
	vec3 dx = dFdx(VERTEX);
	vec3 dy = dFdy(VERTEX);
	vec3 rx = cross(dy, NORMAL);
	vec3 ry = cross(NORMAL, dx);
	float det = dot(dx, rx);
	vec3 bumped = abs(det) * NORMAL - sign(det) * (dFdx(height) * rx + dFdy(height) * ry);
	if (dot(bumped, bumped) > 0.000000000001) { NORMAL = normalize(bumped); }
	METALLIC = 0.6;
	float worn = smoothstep(0.52, 0.78, dirt);
	ROUGHNESS = mix(0.68, 0.24, worn);
	float hot_radius = min(0.12, min(distance(hot_p0, hot_p1), min(distance(hot_p1, hot_p2), distance(hot_p2, hot_p0))) * 0.3);
	float near_hot = min(distance(lp, hot_p0), min(distance(lp, hot_p1), distance(lp, hot_p2)));
	float points = 1.0 - smoothstep(hot_radius * 0.4, max(hot_radius, 0.0001), near_hot);
	vec3 sun = normalize((VIEW_MATRIX * vec4(sun_v, 0.0)).xyz);
	float glint = pow(max(dot(NORMAL, normalize(sun + VIEW)), 0.0), 96.0) * max(dot(NORMAL, sun), 0.0);
	EMISSION = hot_col * COLOR.a * hot * points * (0.5 + 0.9 * g) * 2.2;
	EMISSION += vec3(0.65, 0.52, 0.35) * glint * worn;
}
"""

const WRECK_NAMES := ["hull_fragment", "broken_frame", "truss", "hull_section", "engine_bell", "weapon_sponson"]
const WRECK_DIR := "res://world/wreckage/"
static var _wreck_mesh_cache: Array = []


# Issue 1204: drop what this script's statics hold before the engine shuts down (render/static_caches.gd calls it at quit)
static func clear_static() -> void:
	_wreck_mesh_cache = []
	_piece_radii.clear()   # keyed by those meshes' instance ids


# Issue #230 AS14: the one tumble figure of record (contrib/opus/briefs/environment_reconciliation.md section 1). A
# piece of debris turns at most TUMBLE_K / max(1, scale) rad per second (scale 1 is a 2-unit rock or a radius-1 wreck
# piece). Provisional: it binds once the board's motion capture (world_shots.gd --motion) has sheeted it against the
# terrain synthesis periods and Ryan has judged the sheet.
const TUMBLE_K := 0.10
# Capture variant only: VS_TUMBLE=periods turns debris at the terrain synthesis 2.4 periods instead (small rocks 20 to
# 40 s a turn, large rocks 60 to 90 s, wreck pieces 80 to 120 s). Unset (or "cap") is the shipped law.
static var tumble_mode: String = "periods" if OS.get_environment("VS_TUMBLE") == "periods" else "cap"


static func tumble_rate(scale_v: float) -> float:
	return TUMBLE_K / maxf(1.0, scale_v)


# A rock's tumble in rad per second. "cap": the seeded raw rate held under the cap (the shipped law). "periods": the
# terrain synthesis period for its size band, picked by the piece's own seed so the seeded layout does not change.
static func rock_tumble(raw_rate: float, scale_v: float, seed_v: float) -> float:
	if tumble_mode != "periods":
		return minf(raw_rate, tumble_rate(scale_v))
	# library rocks are 2 units long at scale 1 (rocks.json ext), so 3 units and up is scale 1.5 and up
	var period := lerpf(60.0, 90.0, seed_v) if scale_v >= 1.5 else lerpf(20.0, 40.0, seed_v)
	return TAU / period


# A wreck piece's tumble in rad per second. "cap": exactly the cap for its scale (the shipped law). "periods": 80 to
# 120 s a turn, the period picked from the piece's position so no extra random number is drawn.
static func wreck_tumble(scale_v: float, at: Vector3) -> float:
	if tumble_mode != "periods":
		return tumble_rate(scale_v)
	var u := fposmod(sin(at.x * 12.9898 + at.z * 78.233 + at.y * 37.719) * 43758.5453, 1.0)
	return TAU / lerpf(80.0, 120.0, u)


# Rank each hex by its full mesh's actual long axis, not spawn order or a size
# threshold. Keep the three largest at blocker detail even on the low setting.
static func add_debris_rocks(batch, pieces: Array, mat: Material) -> void:
	# Both paths already use this helper. Split only the legacy material, so far
	# rocks sharing the world's original material never disappear with the scatter.
	if mat is ShaderMaterial and mat.get_shader_parameter("debris_glint") != 1.0:
		var id := mat.get_instance_id()
		if not batch.legacy_debris_materials.has(id):
			var legacy := mat.duplicate() as ShaderMaterial
			legacy.set_shader_parameter("legacy_debris", true)
			batch.legacy_debris_materials[id] = legacy
		mat = batch.legacy_debris_materials[id]
	for piece in pieces:
		var size_v := WR.mesh(piece.mesh).get_aabb().size
		piece["span"] = maxf(size_v.x, maxf(size_v.y, size_v.z)) * piece.xf.basis.get_scale().x
	var ranked := pieces.duplicate()
	ranked.sort_custom(func(a, b): return float(a.span) > float(b.span))
	for i in ranked.size():
		var piece: Dictionary = ranked[i]
		var mesh_name := str(piece.mesh) if i < 3 else str(piece.mesh) + "_lo"
		var scale_v: float = piece.xf.basis.get_scale().x
		batch.add(mesh_name, mat, piece.shadow, piece.xf, piece.axis,
			rock_tumble(float(piece.rate), scale_v, float(piece.seed)), piece.seed)


static func _shard_meshes() -> Array:
	if _wreck_mesh_cache.is_empty():
		_wreck_mesh_cache = _load_wreck_kit(WRECK_DIR)
	return _wreck_mesh_cache


static func _load_wreck_kit(directory: String) -> Array:
	var meshes: Array = []
	for piece in WRECK_NAMES:
		var path := directory.path_join(piece + ".glb")
		var node: Node = null
		if ResourceLoader.exists(path, "PackedScene"):
			var scene := ResourceLoader.load(path, "PackedScene") as PackedScene
			if scene != null:
				node = scene.instantiate()
		if node == null and FileAccess.file_exists(path):
			# Also work in the runner's fresh checkout before editor import.
			var doc := GLTFDocument.new()
			var state := GLTFState.new()
			if doc.append_from_buffer(FileAccess.get_file_as_bytes(path), "", state) == OK:
				node = doc.generate_scene(state)
		var mi := WR._find_mesh(node) if node != null else null
		var mesh: Mesh = mi.mesh if mi != null else null
		if node != null:
			node.free()
		if mesh == null or mesh.get_faces().size() < 3 or not mesh.get_aabb().has_surface():
			push_warning("Wreck kit is missing or empty at %s. Using a solid fragment." % path)
			var fragment := BoxMesh.new()
			fragment.size = Vector3(1.8, 0.65, 1.1)
			return [fragment]
		meshes.append(mesh)
	return meshes

# ---------------------------------------------------------------- the gravity well

func _well(c: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(250, 250)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = SHADER_CACHE.for_code(WELL_SHADER)
	m.set_shader_parameter("well", c)
	# the pull reaches five hexes (about 87 units); the dead star's own lens and disc fill the middle
	m.set_shader_parameter("r_in", 58.0)
	m.set_shader_parameter("r_out", 118.0)
	# after the dead star's lens (-30), before the dark floor (-20) and the disc, so the disc stays on top
	m.render_priority = -25
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, -1.5, c.z)
	add_child(mi)
	# Low keeps the same rim, warm hint and ripples. Reduce independent dust first.
	var count := 91 * (1 if W.quality == "low" else 2)
	var mm := _quad_mm(count)
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3.ZERO))
		mm.set_instance_custom_data(i, Color(rng.randf_range(0.5, 1.0), rng.randf(), rng.randf(), rng.randf()))
	var dust := MultiMeshInstance3D.new()
	dust.name = "WellInfall"
	dust.multimesh = mm
	var dm := ShaderMaterial.new()
	dm.shader = SHADER_CACHE.for_code(INFALL_SHADER)
	dm.set_shader_parameter("well", c)
	dm.render_priority = -24
	dust.material_override = dm
	dust.custom_aabb = AABB(Vector3(c.x - 90, -4, c.z - 90), Vector3(180, 12, 180))
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)
	W.notes.append("well: background-only lens, 3.5 s inward ripples, cold inner rim, 45 s warm hint, %d infall motes" % count)


func use_ship_debris(ships: Array) -> void:
	if W._terr_pts.debris.is_empty() or _chunk_task >= 0 or has_node("HullDebris"): return
	var sources := HD.gather(ships)
	if sources.is_empty(): return  # keep current debris when assets are absent
	_chunk_job = {"sources": sources, "chunks": []}
	var job := _chunk_job
	_chunk_task = WorkerThreadPool.add_task(func() -> void: job.chunks = HD.cut(job.sources))
	_install_chunks()

# issue 1434 (LOAD29 cold s25: the 7 chunk meshes landed in one prepare_hulls draw, 83 pipelines and 7 s): true while the
# chunks are still being cut on the worker, so the battle's load waits and stages them in with the rest
func debris_pending() -> bool:
	return _chunk_task >= 0 or _installing


# issue 1434 (LOAD30d cold s25: the 7 chunks added in one frame compiled 59 surface pipelines in its draw, 5.7 s; a
# mesh's surface pipelines are made when it joins the scene, whatever layer it draws on): while a battle is loading
# the chunks join one a frame
var _installing := false


func _install_chunks() -> void:
	while not WorkerThreadPool.is_task_completed(_chunk_task):
		await get_tree().process_frame
		if not is_inside_tree() or _chunk_task < 0: return
	WorkerThreadPool.wait_for_task_completion(_chunk_task)
	_chunk_task = -1
	var meshes := HD.meshes(_chunk_job.chunks)
	# These are old, weathered board wrecks, not fresh deaths. Keep their cut caps
	# cold; only the kit's three bounded torn-edge points carry residual heat.
	for chunk in _chunk_job.chunks:
		if chunk.get("cap_mat") is ShaderMaterial:
			(chunk.cap_mat as ShaderMaterial).set_shader_parameter("heat", 0.0)
	_chunk_job = {}
	if meshes.is_empty(): return
	var holder := Node3D.new()
	holder.name = "HullDebris"
	add_child(holder)
	# issue 1434 (LOAD32): one chunk alone still made 59 surface pipelines in a 5.9 s frame (cold and warm), all of its
	# materials' shaders at once. While a battle loads, its first mesh joins once per surface, the other surfaces on a
	# plain material, so each shader's pipelines land in a frame of their own.
	if not _wreck_slots.is_empty() and not get_tree().get_nodes_in_group("battle_loading").is_empty():
		if not await _warm_surfaces(holder, meshes[0], (_wreck_slots[0].xf as Transform3D).origin):
			return
	var index := 0
	var replaced := {}
	var radii := {}
	# Replace one existing kit slot per hex, preserving its size, pose and total
	# count. Keep the other kit shapes visible alongside the painted fleet chunks.
	for slot in _wreck_slots.duplicate():   # issue 1434: the loop may span frames
		var mi := MeshInstance3D.new()
		mi.mesh = meshes[index % meshes.size()]
		index += 1
		var box := mi.mesh.get_aabb()
		var mesh_id := mi.mesh.get_instance_id()
		if not radii.has(mesh_id):
			var radius := 0.0
			for surface in mi.mesh.get_surface_count():
				for v in mi.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
					radius = maxf(radius, (v as Vector3).distance_to(box.get_center()))
			radii[mesh_id] = radius
		var scale_v := float(slot.scale) / maxf(float(radii[mesh_id]), 0.01)
		var pivot := Node3D.new()
		pivot.transform = Transform3D((slot.xf as Transform3D).basis.orthonormalized(), slot.xf.origin)
		holder.add_child(pivot)
		mi.scale = Vector3.ONE * scale_v
		mi.position = -box.get_center() * scale_v
		pivot.add_child(mi)
		var id: int = slot.mmi.get_instance_id()
		if not replaced.has(id): replaced[id] = {"mmi": slot.mmi, "indices": []}
		replaced[id].indices.append(int(slot.index))
		_hull_spin.append([pivot, Vector3.UP if slot.get("orbiting", false) else (slot.axis as Vector3).normalized(), float(slot.get("rate", tumble_rate(float(slot.scale))))])
		if not get_tree().get_nodes_in_group("battle_loading").is_empty():
			_installing = true
			await get_tree().process_frame
			if not is_inside_tree() or not is_instance_valid(holder):
				_installing = false
				return
	_installing = false
	# Compact each affected draw once. Do not hide a replaced slot with a zero
	# scale: a singular normal matrix can feed NaNs into lighting and bloom.
	for group in replaced.values():
		var old: MultiMesh = group.mmi.multimesh
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = old.mesh
		mm.instance_count = old.instance_count - group.indices.size()
		var dst := 0
		for src in old.instance_count:
			if group.indices.has(src): continue
			mm.set_instance_transform(dst, old.get_instance_transform(src))
			mm.set_instance_custom_data(dst, old.get_instance_custom_data(src))
			dst += 1
		group.mmi.multimesh = mm
	_wreck_slots.clear()
	W.notes.append("painted hull debris: %d cached chunks, %d instances" % [meshes.size(), index])

# Joins `mesh` once per surface at `at`, a speck the size of a dust grain, the other surfaces on one plain material,
# a frame apart; false when the world left the tree meanwhile.
func _warm_surfaces(holder: Node3D, mesh: Mesh, at: Vector3) -> bool:
	var plain := StandardMaterial3D.new()
	var mi := MeshInstance3D.new()
	mi.name = "SurfaceWarm"
	mi.mesh = mesh
	mi.scale = Vector3.ONE * 0.001
	mi.position = at   # it casts shadows as the real chunks do, so their shadow pipelines come early too
	for s in mesh.get_surface_count():
		mi.set_surface_override_material(s, plain)
	holder.add_child(mi)
	_installing = true
	for k in mesh.get_surface_count():
		await get_tree().process_frame
		if not is_inside_tree() or not is_instance_valid(mi):
			_installing = false
			return false
		if k > 0: mi.set_surface_override_material(k - 1, plain)
		mi.set_surface_override_material(k, null)
	await get_tree().process_frame
	_installing = false
	if not is_inside_tree() or not is_instance_valid(mi): return false
	mi.queue_free()
	return true

func _exit_tree() -> void:
	for mat in _legacy_debris_mats:
		mat.set_shader_parameter("living_terrain", false)
	if _chunk_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_chunk_task)
		_chunk_task = -1


# Issue 1268: capture-only colour options for Ryan's sky sheet. Off unless a capture sets the env vars;
# the game never sets them, so defaults and faction_looks.json stay as they are.
static func _sheet_colour(name: String) -> Variant:
	var raw := OS.get_environment(name)
	if raw == "": return null
	var parts := raw.split(",")
	if parts.size() != 3: return null
	return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))


func _sheet_colour_override(m: ShaderMaterial) -> void:
	for pair in [["VS_NEBULA_LIT", "c_lit"], ["VS_NEBULA_GLOW", "c_glow"], ["VS_NEBULA_SHADOW", "c_shadow"]]:
		var c = _sheet_colour(pair[0])
		if c != null: m.set_shader_parameter(pair[1], c)
