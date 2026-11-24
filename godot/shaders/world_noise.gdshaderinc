float wh21(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float wvn(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(wh21(i), wh21(i + vec2(1.0, 0.0)), f.x), mix(wh21(i + vec2(0.0, 1.0)), wh21(i + vec2(1.0, 1.0)), f.x), f.y);
}
float wfbm(vec2 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn(p); p = p * 2.03 + vec2(1.7, 9.2); a *= 0.5; } return s; }
// r6: Hoskins' hash13 (the old product hash drew diagonal lattice lines once a shader amplified the noise)
float wh31(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float wvn3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);

	return mix(mix(mix(wh31(i), wh31(i + vec3(1.0, 0.0, 0.0)), f.x), mix(wh31(i + vec3(0.0, 1.0, 0.0)), wh31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(wh31(i + vec3(0.0, 0.0, 1.0)), wh31(i + vec3(1.0, 0.0, 1.0)), f.x), mix(wh31(i + vec3(0.0, 1.0, 1.0)), wh31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float wfbm3(vec3 p) { float a = 0.5; float s = 0.0; for (int k = 0; k < 5; k++) { s += a * wvn3(p); p = p * 2.03 + 3.1; a *= 0.5; } return s; }
