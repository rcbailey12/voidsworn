shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/map_noise.gdshaderinc"

uniform float r_shadow = 0.25;
uniform float gain = 1.0;
uniform float exposure_gain = 1.0;
uniform float spin = 0.3;
uniform float tilt_dir = 0.0;   // screen angle of the disc's long axis (radians); arcs sit across it
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	p.y = -p.y;
	float th = length(p) / r_shadow;          // in shadow radii
	float ang = atan(p.y, p.x) - tilt_dir;
	float across = abs(sin(ang));               // 1 above and below the disc's line, 0 along it
	// the upper arc is the big lensed image of the far side, the lower one a thinner secondary image
	float up = step(0.0, sin(ang));
	float w_out = mix(1.32, 1.44, up);   // a defined band, not a halo (NASA Goddard 2019: thin arcs hugging the shadow)
	float band = smoothstep(1.035, 1.06, th) * (1.0 - smoothstep(w_out - 0.06, w_out, th));
	float u = clamp((th - 1.05) / (w_out - 1.05), 0.0, 1.0);
	float a2 = ang * 3.0 + TIME * spin * 2.0;
	float sp = mfbm2(vec2(a2 * 4.0 + log(max(th, 1.0)) * 8.0, th * 7.0), 4);   // streaks along the arc, like the disc's own
	vec3 c = mix(vec3(1.0, 0.92, 0.8), vec3(1.0, 0.55, 0.2), smoothstep(0.0, 0.35, u));
	c = mix(c, vec3(0.55, 0.12, 0.04), smoothstep(0.35, 1.0, u)) * (2.2 - 1.6 * u);
	// the lower arc (the far side seen under the shadow) is thinner and a little fainter than the upper one
	float arc = band * pow(across, 0.8) * (0.45 + 0.8 * sp) * mix(1.0, 1.0, up) * 0.95;   // the lower arc as strong as the upper, so it reads at full-map zoom
	// Doppler beaming: the side of the disc turning toward the camera (screen right) brighter and whiter-blue, the
	// receding side dimmer and redder; kept subtle so the look stays on brand
	float beam = cos(ang + tilt_dir);
	c *= 1.0 + 0.45 * beam;
	c = mix(c, c * vec3(0.85, 0.97, 1.2), clamp(beam, 0.0, 1.0) * 0.35);
	c = mix(c, c * vec3(1.1, 0.8, 0.65), clamp(-beam, 0.0, 1.0) * 0.35);
	// the photon ring: thin, sharp, hugging the shadow, a little brighter on the approaching side
	float ring = exp(-(((th - 1.02) / 0.011) * ((th - 1.02) / 0.011))) * 3.2 * (1.0 + 0.25 * beam) + exp(-(((th - 1.06) / 0.05) * ((th - 1.06) / 0.05))) * 0.35;
	ALBEDO = (c * arc + vec3(1.0, 0.88, 0.68) * ring) * gain;
	ALBEDO *= exposure_gain;
}
