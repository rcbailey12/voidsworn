shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/world_noise.gdshaderinc"

uniform vec3 c_dark = vec3(0.006, 0.002, 0.014);
uniform vec3 c_shadow = vec3(0.055, 0.012, 0.14);
uniform vec3 c_lit = vec3(0.43, 0.20, 0.80);
uniform vec3 c_glow = vec3(0.88, 0.72, 1.0);
uniform float gain = 0.3;
uniform float storm = 0.0;
uniform vec3 bolt = vec3(1.0, 0.82, 0.27);
varying vec4 vI;
varying vec2 vQ;
void vertex() {
	vI = INSTANCE_CUSTOM;
	vec4 c = MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
	float a = vI.y * 6.2831;
	vec2 q = mat2(vec2(cos(a), sin(a)), vec2(-sin(a), cos(a))) * VERTEX.xy;
	vQ = VERTEX.xy * 2.0;
	c.xy += q * vI.x;
	POSITION = PROJECTION_MATRIX * c;
}
void fragment() {
	float r = length(vQ);
	if (r > 1.0) { discard; }
	vec2 p = vQ * 1.6 + vI.y * 37.0 + vec2(TIME * 0.015, TIME * 0.008);
	float n = wfbm(p * 1.3 + wfbm(p * 0.8 + 3.0) * 1.5);
	float a = smoothstep(1.0, 0.15, r) * smoothstep(0.3, 0.75, n) * vI.z;
	float density = clamp((n - 0.18) / 0.72, 0.0, 1.0);
	vec3 c = mix(c_dark, c_shadow, smoothstep(0.0, 0.3, density));
	c = mix(c, c_lit, smoothstep(0.3, 0.6, density));
	c = mix(c, c_glow, smoothstep(0.6, 0.9, density));
	c += c_glow * smoothstep(0.67, 0.85, n) * 0.22;
	vec3 col = c * a * gain;
	if (storm > 0.5) {
		// ion storm: now and then a cloud lights from inside, a branching flash
		float ph = fract(TIME * (0.11 + vI.w * 0.07) + vI.w * 13.0);
		float fl = smoothstep(0.0, 0.01, ph) * smoothstep(0.08, 0.02, ph) * (0.6 + 0.4 * sin(TIME * 41.0 + vI.w * 9.0));
		// r2: the cloud lights from inside as one soft glow, with only faint brighter folds where it is densest (r1's
		// sharp veins drew white wire scribbles over the hexes)
		float vein = smoothstep(0.8, 0.97, 1.0 - abs(wfbm(p * 1.6 + vI.w * 5.0) * 2.0 - 1.0));
		col += bolt * a * (1.1 + vein * 0.5) * fl * smoothstep(1.0, 0.2, r);
	}
	ALBEDO = col;
}
