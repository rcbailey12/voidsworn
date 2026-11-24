shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec2 half_ext = vec2(150.0, 100.0);
uniform vec3 centre = vec3(0.0);
uniform float fade = 90.0;
uniform float k = 0.76;
uniform vec3 col = vec3(0.008, 0.011, 0.018);
uniform vec3 well = vec3(0.0);
uniform float well_r = 0.0;
uniform vec4 planet = vec4(0.0);    // xyz centre, w radius (0: none)
uniform vec3 ring_n = vec3(0.0);
uniform float vis = 1.0;    // the board look trial: 0 hides the floor (looks A, B, C), a part of it in C's tactical grid
varying vec3 vW;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 q = abs(vW.xz - centre.xz) - half_ext;
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	// thicker at grazing angles, like smoked glass seen edge on: when the camera tips low, the far half of the board
	// would otherwise show the planet and far rocks below the horizon right through the hexes
	float graze = 1.0 - abs(dot(normalize(CAMERA_POSITION_WORLD - vW), vec3(0.0, 1.0, 0.0)));
	float a = mix(k, 0.94, graze * graze);
	// where the view ray goes on to the system's planet or its rings, the board is all but opaque: the planet shows past
	// the board's edges, never through the hexes (it lies below the board's plane, beyond its far side)
	if (planet.w > 0.0) {
		vec3 ro = CAMERA_POSITION_WORLD;
		vec3 rd = normalize(vW - ro);
		vec3 oc = planet.xyz - ro;
		float tc = dot(oc, rd);
		float dperp = length(oc - rd * tc) / planet.w;
		float hit = (tc > 0.0) ? smoothstep(1.12, 0.98, dperp) : 0.0;
		if (dot(ring_n, ring_n) > 0.5) {
			float den = dot(rd, ring_n);
			if (abs(den) > 1e-4) {
				float t = dot(oc, ring_n) / den;
				float rr = length(ro + rd * t - planet.xyz) / planet.w;
				hit = max(hit, (t > 0.0 ? smoothstep(1.2, 1.32, rr) * smoothstep(2.42, 2.28, rr) : 0.0));
			}
		}
		a = mix(a, 0.97, hit);
	}
	a *= 1.0 - smoothstep(-fade * 0.25, fade, sd);
	if (well_r > 0.0) {
		a *= smoothstep(well_r, well_r * 1.5, length(vW.xz - well.xz));
	}
	ALBEDO = col;
	ALPHA = a * vis;
}
