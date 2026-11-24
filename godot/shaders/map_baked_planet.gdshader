shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform sampler2D tex_a : source_color, filter_linear, repeat_enable;
// Packed masks and relief are linear data, including the ocean mask in tex_a.a.
uniform sampler2D tex_b : filter_linear, repeat_enable;
uniform float has_tex = 0.0;
uniform vec3 flat_col = vec3(0.3);
uniform vec3 sun = vec3(0.45, 0.7, 0.55);     // toward the sun, world space
uniform vec3 sun_col = vec3(1.0, 0.95, 0.88);
uniform float light = 1.0;
uniform float map_floor = 0.0;
uniform vec3 atmo = vec3(0.4, 0.6, 1.0);
uniform float atmo_k = 1.0;
uniform float spin = 0.004;
uniform vec3 tint = vec3(1.0);
uniform vec3 city = vec3(1.0, 0.72, 0.38);
uniform vec3 lava_col = vec3(1.0, 0.36, 0.08);
uniform vec4 ring = vec4(0.0);           // xyz ring normal (world), w on
uniform vec2 ring_r = vec2(1.3, 2.3);    // in planet radii
uniform float rough = 1.0;
varying vec3 vObj;
varying vec3 vW;
varying vec3 vC;
varying float vR;
void vertex() {
	vObj = VERTEX;
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vC = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vR = length(MODEL_MATRIX[0].xyz);
}
vec2 uv_of(vec3 d) { return vec2(atan(d.x, -d.z) / 6.28318530718 + 0.5, acos(clamp(d.y, -1.0, 1.0)) / 3.14159265359); }
vec3 spun(vec3 d, float a) { float c = cos(a); float s = sin(a); return vec3(c * d.x + s * d.z, d.y, -s * d.x + c * d.z); }
void fragment() {
	vec3 n0 = normalize(vObj);
	vec3 N = normalize(vW - vC);
	vec3 L = normalize(sun);
	vec3 V = normalize(CAMERA_POSITION_WORLD - vW);
	vec3 ds = spun(n0, TIME * spin);
	vec3 alb = flat_col;
	vec4 b = vec4(0.0, 0.0, 0.5, 0.0);
	float ocean = 0.0;
	if (has_tex > 0.5) {
		vec4 a = texture(tex_a, uv_of(ds));
		alb = a.rgb;
		ocean = a.a;
		b = texture(tex_b, uv_of(ds));
	}
	alb *= tint;
	float ndl = dot(N, L);
	// relief: a cheap bump from the baked height, along the surface. The two height samples step along the local
	// tangent and bitangent (object space, before the texture spin), and the bumped normal tilts along the same two
	// directions taken to world space, so ridges light from the sun's side all round the planet (issue 1468; fixed
	// object X and Y steps flipped on the far half and vanished at the X poles)
	vec3 up_o = abs(n0.y) > 0.99 ? vec3(1.0, 0.0, 0.0) : vec3(0.0, 1.0, 0.0);
	vec3 t_o = normalize(cross(up_o, n0));
	vec3 b_o = cross(n0, t_o);
	vec3 dsx = spun(normalize(n0 + t_o * 0.003), TIME * spin);
	vec3 dsy = spun(normalize(n0 + b_o * 0.003), TIME * spin);
	float hx = has_tex > 0.5 ? texture(tex_b, uv_of(dsx)).b - b.b : 0.0;
	float hy = has_tex > 0.5 ? texture(tex_b, uv_of(dsy)).b - b.b : 0.0;
	mat3 m3 = mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz);
	vec3 tx = normalize(m3 * t_o);
	tx = normalize(tx - N * dot(tx, N));
	vec3 ty = normalize(m3 * b_o);
	ty = normalize(ty - N * dot(ty, N) - tx * dot(ty, tx));
	vec3 Nb = normalize(N - (tx * hx + ty * hy) * 2.5 * rough * (1.0 - b.r));
	float lam = max(dot(Nb, L), 0.0);
	// the terminator softened by the atmosphere
	float wrap = atmo_k > 0.0 ? smoothstep(-0.12, 0.3, ndl) : smoothstep(-0.02, 0.12, ndl);
	float diff = mix(lam, wrap * lam + wrap * 0.04, 0.5);
	// cloud shadows on the ground: the clouds a little toward the sun
	float cs = 0.0;
	if (has_tex > 0.5 && b.r > 0.0) {
		vec3 dl = spun(normalize(n0 + (transpose(mat3(MODEL_MATRIX[0].xyz, MODEL_MATRIX[1].xyz, MODEL_MATRIX[2].xyz)) * L) / vR * 0.012), TIME * spin);
		cs = texture(tex_b, uv_of(dl)).r;
	}
	vec3 ground = alb * (1.0 - cs * 0.55);
	vec3 col = mix(ground, vec3(0.82, 0.85, 0.88), b.r) * diff * sun_col;
	// the sun's glint on water
	vec3 H = normalize(L + V);
	// issue 1765: a tight glint with a faint halo (the broad lobe read as a white blob on the sea)
	float gl = max(dot(N, H), 0.0);
	col += sun_col * ocean * (1.0 - b.r) * (pow(gl, 260.0) * 1.3 + pow(gl, 50.0) * 0.06) * smoothstep(0.0, 0.1, ndl);
	// ring shadow on the planet
	if (ring.w > 0.5) {
		vec3 rn = normalize(ring.xyz);
		float den = dot(L, rn);
		if (abs(den) > 1e-3) {
			float t = dot(vC - vW, rn) / den;
			if (t > 0.0) {
				float rr = length(vW + L * t - vC) / vR;
				float band = smoothstep(ring_r.x, ring_r.x + 0.08, rr) * (1.0 - smoothstep(ring_r.y - 0.15, ring_r.y, rr));
				col *= 1.0 - band * 0.6;
			}
		}
	}
	// night side: city lights and lava
	float night = (1.0 - smoothstep(-0.18, 0.08, ndl));
	col += city * b.g * night * 0.9 * (1.0 - b.r * 0.7);
	col += lava_col * b.a * (0.25 + night * 1.2);
	// the lit limb glows with the atmosphere
	float rim = pow(1.0 - clamp(dot(N, V), 0.0, 1.0), 3.0);
	col += atmo * atmo_k * rim * smoothstep(-0.25, 0.4, ndl) * 0.9;
	col = mix(col, atmo * diff * 0.6, atmo_k * rim * 0.35);
	ALBEDO = (col + ground * map_floor) * light;
}
