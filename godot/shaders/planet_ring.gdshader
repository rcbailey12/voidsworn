shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 sun = vec3(0.45, 0.7, 0.55);
uniform vec3 col_a = vec3(0.85, 0.78, 0.66);
uniform vec3 col_b = vec3(0.5, 0.42, 0.34);
uniform vec2 ring_r = vec2(1.3, 2.3);
uniform float seed = 0.0;
uniform float light = 1.0;
varying vec3 vL;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vL = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
float h1(float x) { return fract(sin(x * 127.1 + seed) * 43758.5453); }
float n1(float x) { float i = floor(x); float f = fract(x); f = f * f * (3.0 - 2.0 * f); return mix(h1(i), h1(i + 1.0), f); }
void fragment() {
	float r = length(vL.xz);
	float u = (r - ring_r.x) / (ring_r.y - ring_r.x);
	if (u < 0.0 || u > 1.0) { discard; }
	float dens = 0.0;
	float a = 1.0;
	float f = 4.0;
	for (int k = 0; k < 5; k++) { dens += n1(u * f + float(k) * 3.1) * a; a *= 0.55; f *= 2.3; }
	dens = clamp(dens / 1.9, 0.0, 1.0);
	dens *= smoothstep(0.0, 0.04, u) * (1.0 - smoothstep(0.94, 1.0, u));
	// a dark gap two thirds of the way out (Cassini-like) and a thin faint inner ring
	dens *= 1.0 - 0.9 * exp(-pow((u - 0.66) / 0.018, 2.0));
	dens *= mix(0.35, 1.0, smoothstep(0.08, 0.2, u));
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	// Closest point on the ray toward the sun, in planet radii. On the lit
	// side the closest point is the ring itself, already outside the sphere.
	vec3 rel = vW - vC;
	float t = max(dot(-rel, L), 0.0);
	float dperp = length(rel + L * t) / vR;
	// Widen the penumbra downsun and keep some light in the umbra so the
	// shadow reads across the bands without looking like a cut in the ring.
	float penumbra = mix(0.23, 0.48, smoothstep(0.0, 2.0, t / vR));
	float sh = mix(0.38, 1.0, smoothstep(1.0 - penumbra, 1.0 + penumbra, dperp));
	vec3 c = mix(col_b, col_a, n1(u * 23.0 + 5.0));
	// lit from either side; brighter seen against the light (forward scattering)
	float fwd = pow(max(dot(-V, L), 0.0), 6.0);
	vec3 lit = c * (0.55 + 0.6 * fwd) * sh;
	ALBEDO = lit * light;
	ALPHA = dens * 0.85;
}
