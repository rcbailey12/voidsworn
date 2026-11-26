shader_type sky;
uniform sampler2D neb_tex : filter_linear, repeat_enable;
uniform float has_neb = 0.0;

uniform float neb_gain = 1.0;
uniform vec3 map_sun_dir = vec3(0.0, 0.0, -1.0);
uniform float map_saturation = 1.0;
uniform float map_heat = 0.0;
uniform float map_star_void = 0.0;

uniform vec3 mood_tint = vec3(1.0);   // issue 1272: a stop's mood on the sector's baked gas (defaults change nothing)
uniform float mood_mix = 0.0;
uniform float mood_gain = 1.0;
uniform float mood_dim = 0.0;
uniform float seed = 0.0;
uniform float star_k = 1.0;
uniform float star_floor = 0.15;   // E18/BD8: brightness of a star seen through the nebula body
uniform vec3 band_n = vec3(0.0, 1.0, 0.0);
uniform float band = 0.6;
uniform vec4 lamp[6];
uniform vec3 lamp_col[6];
uniform vec3 sun_dir = vec3(0.45, 0.7, 0.55);
uniform vec3 sun_col = vec3(1.0, 0.93, 0.82);
uniform float px = 0.0008;   // one screen pixel in radians (fov / height)
uniform mat3 turn = mat3(1.0); // the battle's small turn of the whole sky
// the dead-star board's painted sky (R2: its backdrop; A3's 8K dead-star panorama, with its dim red dead sun where the
// key light comes from), under the gas; and how bright this sky's own sun is (none on the dead-star board)
uniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float has_pano = 0.0;
uniform float sun_k = 1.0;
uniform float dawn = 0.0;
uniform vec3 dawn_dir = vec3(-0.6, 0.7, -0.2);

#include "res://shaders/sky_fleet_reflections.gdshaderinc"


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
	if (has_pano > 0.5) {
		// the painting as the old battle sky drew it (battle.gd: x0.8, capped), the gas over it
		// read from a blurred level: the painting's colour, clouds and dim dead sun, without its soft blobby stars (they
		// showed as speckle through the board on the PC; this sky's own stars are drawn per pixel below)
		col = min(textureLod(pano, SKY_COORDS, 4.5).rgb * 0.9, vec3(0.6));
	}
	if (has_neb > 0.5) {
		vec2 uv = vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359);
		vec4 t = texture(neb_tex, uv);
		vec3 g = pow(t.rgb, vec3(2.2)) * neb_gain * mood_gain;
		g = mix(g, mood_tint * dot(g, vec3(0.3, 0.59, 0.11)) * 1.7, mood_mix);
		col += g * (1.0 - mood_dim);
		T = t.a * (1.0 - mood_dim * 0.6);
	}
	
float near_sun = pow(max(dot(EYEDIR, map_sun_dir), 0.0), 20.0);
col = mix(vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), col, map_saturation);
col *= mix(1.0, near_sun, map_heat);
col += vec3(0.018, 0.004, 0.001) * near_sun * map_heat;
if (!AT_CUBEMAP_PASS) {

		float y = dot(d, band_n);
		float yb = y / 0.25;   // signed: square by hand, never pow() (undefined for a negative base)
		float bd = exp(-yb * yb) * band;
		vec3 st = star_layer(d, 120.0, 0.955, 1.0, bd * 0.03) + star_layer(d, 300.0, 0.985, 0.55, bd * 0.012) + star_layer(d, 650.0, 0.994, 0.35, bd * 0.004);
		col += st * (1.0 - map_star_void * near_sun) * star_k * mix(star_floor, 1.0, T) * (1.0 - 0.6 * has_pano);
		// the stars inside the gas, with halos
		for (int k = 0; k < 6; k++) {
			if (lamp[k].w <= 0.0) continue;
			float a = acos(clamp(dot(d, normalize(lamp[k].xyz)), -1.0, 1.0));
			col += lamp_col[k] * lamp[k].w * (exp(-a * a / (px * px * 2.2)) * 5.0 + exp(-a * a / 0.00006) * 0.25 + 0.0006 / (0.0004 + a * a) * 0.08);
		}
		// the sun the key light comes from
		float sa = acos(clamp(dot(EYEDIR, normalize(sun_dir)), -1.0, 1.0));
		col += sun_k * sun_col * (smoothstep(0.012, 0.009, sa) * 30.0 + exp(-sa * sa / 0.0012) * 1.2 + 0.002 / (0.001 + sa * sa) * 0.12);
	}
	// A broad warm halo in the new sun's direction. Zero keeps every normal battle exactly as before.
	float catch_light = ((max(0.0, 0.5 + 0.5 * dot(EYEDIR, normalize(dawn_dir)))) * (max(0.0, 0.5 + 0.5 * dot(EYEDIR, normalize(dawn_dir)))));
	col = mix(col, col * vec3(1.18, 1.03, 0.84), dawn * 0.55);
	col += vec3(0.10, 0.047, 0.016) * catch_light * dawn;
	if (AT_CUBEMAP_PASS && fleet_reflections) {
		col += fleet_reflection_gradient(EYEDIR, normalize(sun_dir));
	}
	COLOR = col;
}
