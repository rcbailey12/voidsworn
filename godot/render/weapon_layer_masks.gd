extends RefCounted
## Analytic weapon silhouettes. Each mask keeps its core separate from its wider sheath.

const STREAK := """
vec2 bolt_streak(vec2 uv, int profile, float age) {
	float x = uv.x;
	float nose = profile == 10 ? 0.74 : 0.70;
	float taper = max(min(x / nose, (1.0 - x) / (1.0 - nose)), 0.0);
	float centre = 0.0;
	if (profile == 12) {
		centre = sin(x * 11.0 + age * 16.0) * 0.065 * taper;
		taper *= 0.80 + 0.20 * cos(x * 19.0 - age * 19.0);
	}
	float y = abs(uv.y - centre);
	float shape = profile == 11 ? taper : sqrt(taper);
	float edge = shape * (profile == 10 ? 0.28 : 0.43);
	float ends = smoothstep(0.0, 0.10, x) * (1.0 - smoothstep(0.91, 1.0, x));
	float aa = clamp(fwidth(uv.y) * 0.42, 0.015, 0.21);
	float sheath = (1.0 - smoothstep(max(edge - aa, 0.0), edge + aa, y)) * ends;
	float front = profile == 10 ? smoothstep(0.14, 0.49, x) : smoothstep(0.29, 0.73, x);
	float core = (1.0 - smoothstep(0.02, max(0.03, edge * 0.44 + aa * 0.5), y)) * front * ends;
	return vec2(core, sheath);
}
"""

const SPRITE := """
vec2 bolt_sprite(vec2 p, int profile, float age, float seed) {
	// x points along flight. The core leads, leaving room for a tapered wake.
	float front = profile == 32 ? 0.28 : 0.31;
	float phase = age * 13.0 + seed * 6.2831853;
	float ripple = profile == 30 ? sin(p.x * 8.0 - phase) * 0.09 : sin(p.x * 5.0 - phase) * 0.06;
	float x = p.x - front;
	float y = p.y - ripple * (1.0 - smoothstep(-0.75, front, p.x));
	float rad = length(vec2(x / 0.39, y / 0.56));
	float body = 1.0 - smoothstep(0.70, 1.0, rad);
	float tail = smoothstep(-0.94, front, p.x);
	float wake = (1.0 - smoothstep(0.12, 0.55, abs(y) / max(tail, 0.10))) * tail;
	float core = 1.0 - smoothstep(0.20, 0.87, length(vec2((x - 0.08) / 0.27, y / 0.30)));
	if (profile == 32) {
		// A bomb is an opaque, short capsule with a hot nose and trailing wake, not a craft icon.
		core *= smoothstep(0.15, 0.48, p.x);
		wake *= 0.65;
	}
	return vec2(core, max(body * (0.74 + ripple * 2.0), wake));
}

float muzzle_sheath(vec2 p, int profile, float t, float seed) {
	if (profile == 33) {
		// Cartridge gas expands straight down the barrel and curls at the edge.
		float x = clamp(p.x * 0.5 + 0.5, 0.0, 1.0);
		float n = vnoise(p * 4.0 + vec2(seed * 7.0 - t, t));
		return (1.0 - smoothstep(0.16, 0.40, abs(p.y) / max(x, 0.12))) * x * (0.55 + 0.45 * n);
	}
	float r = length(p);
	if (profile == 34) {
		// An expanding aperture around the energy discharge. No gas.
		return 1.0 - smoothstep(0.04, 0.19, abs(r - mix(0.22, 0.78, t)));
	}
	if (profile == 35) {
		// Cut crystal facets, not powder or metal particles.
		float diamond = abs(p.x) + abs(p.y) * 1.35;
		float edge = 1.0 - smoothstep(0.03, 0.18, abs(diamond - mix(0.34, 0.94, t)));
		return edge * (0.5 + 0.5 * abs(p.x - p.y));
	}
	float wet = vnoise(p * 7.0 + vec2(seed * 8.0 - t * 2.0, 0.0));
	return smoothstep(0.34, 0.66, wet - r * 0.17) * smoothstep(-0.7, 0.5, p.x);
}
"""

const SOLAR := """
float solar_wisps(vec2 p, float age, float seed) {
	float r = length(p);
	vec2 q = r > 1e-4 ? p : vec2(1.0, 0.0);
	float ray = spow(abs(cos(atan(q.y, q.x) * 6.0 + age * 1.5 + seed * 4.0 + r * 2.0)), 8.0);
	return smoothstep(0.23, 0.42, r) * (1.0 - smoothstep(0.45, 0.98, r)) * (0.25 + 0.75 * ray);
}
"""
