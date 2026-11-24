float mh3(vec3 p) { p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float mn3(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(mh3(i), mh3(i + vec3(1.0, 0.0, 0.0)), f.x), mix(mh3(i + vec3(0.0, 1.0, 0.0)), mh3(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
		mix(mix(mh3(i + vec3(0.0, 0.0, 1.0)), mh3(i + vec3(1.0, 0.0, 1.0)), f.x), mix(mh3(i + vec3(0.0, 1.0, 1.0)), mh3(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}
float mfbm(vec3 p, int octs) { float amp = 0.5; float sum = 0.0; for (int k = 0; k < 6; k++) { if (k >= octs) break; sum += amp * mn3(p); p = p * 2.03 + 3.1; amp *= 0.5; } return sum; }
float mh2(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float mn2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mh2(i), mh2(i + vec2(1.0, 0.0)), f.x), mix(mh2(i + vec2(0.0, 1.0)), mh2(i + vec2(1.0, 1.0)), f.x), f.y); }
float mfbm2(vec2 p, int octs) { float amp = 0.5; float sum = 0.0; for (int k = 0; k < 6; k++) { if (k >= octs) break; sum += amp * mn2(p); p = p * 2.03 + vec2(1.7, 9.2); amp *= 0.5; } return sum; }
vec3 hue(float h) { return clamp(abs(fract(h + vec3(0.0, 0.6667, 0.3333)) * 6.0 - 3.0) - 1.0, 0.0, 1.0); }
