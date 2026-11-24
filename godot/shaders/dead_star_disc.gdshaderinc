global uniform float scene_t;

#include "res://shaders/world_noise.gdshaderinc"

uniform float r_in = 1.0;
uniform float r_out = 3.0;
uniform float spin = 0.25;
uniform float gain = 1.0;
uniform vec3 hot = vec3(1.0, 0.92, 0.8);
uniform vec3 warm = vec3(1.0, 0.55, 0.2);
uniform vec3 cool = vec3(0.55, 0.12, 0.04);
uniform float front_only = 0.0;
uniform vec3 hole_center = vec3(0.0);
uniform float inner = 0.0;     // 1: draw only the inner, dense part (the outer part is DISC_SOFT)
varying vec3 vL;
varying vec3 vW;
void vertex() { vL = VERTEX; vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
vec3 disc_col(vec2 q, out float dens) {
	float r = length(q);
	float u = clamp((r - r_in) / (r_out - r_in), 0.0, 1.0);
	float ang = atan(q.y, q.x);
	float w = spin / pow(max(r / r_in, 1.0), 1.5);
	float a2 = ang + scene_t * w;
	float sp = wfbm(vec2(a2 * 3.0 + log(r) * 6.0, r * 1.5));
	float sp2 = wfbm(vec2(a2 * 7.0 - log(r) * 4.0, r * 4.0 + 3.0));
	dens = smoothstep(0.0, 0.06, u) * (1.0 - smoothstep(0.7, 1.0, u)) * (0.55 + 0.7 * sp) * (0.75 + 0.45 * sp2);
	vec3 c = mix(hot, warm, smoothstep(0.0, 0.3, u));
	c = mix(c, cool, smoothstep(0.3, 1.0, u));
	return c * (2.6 - 2.0 * u);
}
void fragment() {
	vec2 q = vL.xz;
	float dens;
	vec3 c = disc_col(q, dens);
	// Doppler beaming: the gas moving toward the camera brightens and blues
	vec3 tang = normalize((MODEL_MATRIX * vec4(-q.y, 0.0, q.x, 0.0)).xyz);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	float dop = dot(tang, V);
	c *= 1.0 + 0.85 * dop;
	c = mix(c, c * vec3(0.8, 0.95, 1.25), clamp(dop, 0.0, 1.0) * 0.4);
	if (front_only > 0.5) {
		// the overlay: only the half of the disc between the camera and the hole
		vec3 toHole = hole_center - CAMERA_POSITION_WORLD;
		vec3 toFrag = vW - CAMERA_POSITION_WORLD;
		if (length(toFrag) > length(toHole)) { discard; }
	}
	// r18 (Muse audit B4.5, flat in close-up): fine filaments wound along the flow and dark dust lanes break the disc
	// up, and the gas looks thicker where it is seen edge-on (a slab of glowing gas, not a painted plate)
	float rr = length(q);
	float aa = atan(q.y, q.x) + scene_t * spin / pow(max(rr / r_in, 1.0), 1.5);
	float fil = wfbm(vec2(aa * 22.0 + log(rr) * 30.0, rr * 9.0));
	float lane = smoothstep(0.62, 0.8, wfbm(vec2(aa * 4.0 - log(rr) * 9.0, rr * 2.2 + 7.0)));
	c *= (0.85 + 0.3 * fil) * (1.0 - 0.5 * lane);
	vec3 Nw = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	float graz = 1.0 - abs(dot(Nw, V));
	c *= 1.0 + 0.6 * graz * graz;
	// F4: the disc in two parts. The inner, dense part is opaque (the lens copies it); the outer, thinning gas is
	// see-through and fades by thinning, not by darkening (r1's opaque fade drew a near-black lip round the disc)
	float u0 = clamp((rr - r_in) / (r_out - r_in), 0.0, 1.0);
	float ramp = smoothstep(0.0, 0.06, u0) * (1.0 - smoothstep(0.7, 1.0, u0));
#ifdef DISC_SOFT
	if (u0 < 0.6) { discard; }
	float body = dens / max(ramp, 1e-3);
	ALBEDO = c * body * gain;
	ALPHA = clamp(ramp * smoothstep(0.04, 0.5, body), 0.0, 1.0);
#else
	if (inner > 0.5 && u0 > 0.64) { discard; }
	if (dens < 0.035) { discard; }
	ALBEDO = c * dens * gain;
#endif
}
