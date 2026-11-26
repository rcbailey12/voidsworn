#include "res://shaders/world_noise.gdshaderinc"
uniform float hot = 0.0;
uniform vec3 hot_col = vec3(1.0, 0.42, 0.12);
uniform float tumble_k = 0.10;   // TUMBLE_K, the #230 figure of record; the periods capture variant lifts it
uniform vec3 sun_v = vec3(0.45, 0.70, 0.55);
uniform float detail_k = 1.0;
uniform vec3 hot_p0 = vec3(100.0);
uniform vec3 hot_p1 = vec3(100.0);
uniform vec3 hot_p2 = vec3(100.0);
varying vec3 lp;

void vertex() {
	// a slow tumble, each piece its own axis and speed, about the piece's own middle
	float h = INSTANCE_CUSTOM.w;
	float rate = length(INSTANCE_CUSTOM.xyz);
	vec3 ax = INSTANCE_CUSTOM.xyz / max(rate, 0.000001);
	float scale_v = length(MODEL_MATRIX[0].xyz);
	float an = TERRAIN_WRECK_TIME * min(rate, tumble_k / max(1.0, scale_v)) + h * 6.2831;
	float c = cos(an);
	float s = sin(an);
	mat3 R = mat3(vec3(c + ax.x * ax.x * (1.0 - c), ax.y * ax.x * (1.0 - c) + ax.z * s, ax.z * ax.x * (1.0 - c) - ax.y * s),
		vec3(ax.x * ax.y * (1.0 - c) - ax.z * s, c + ax.y * ax.y * (1.0 - c), ax.z * ax.y * (1.0 - c) + ax.x * s),
		vec3(ax.x * ax.z * (1.0 - c) + ax.y * s, ax.y * ax.z * (1.0 - c) - ax.x * s, c + ax.z * ax.z * (1.0 - c)));
	lp = VERTEX;
	VERTEX = R * VERTEX;
	NORMAL = R * NORMAL;
}
void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
	float g = wfbm3(lp * 2.3);
	float dirt = wfbm3(lp * 19.0 + 7.1);
	float pits = detail_k > 0.5 ? wfbm3(lp * 83.0) : 0.5;
	// panel seams on the plates, and grime and wear
	vec3 q = abs(fract(lp * vec3(1.6, 1.25, 1.6)) - 0.5);
	float seam = 1.0 - 0.38 * (1.0 - smoothstep(0.0, 0.035, 0.5 - max(max(q.x, q.y), q.z)));
	ALBEDO = COLOR.rgb * mix(0.38, 1.05, g) * mix(0.65, 1.15, dirt) * seam;
	// Local pitting stays attached to the metal during tumble. Fade the finest
	// layer below a pixel rather than letting it shimmer at battle distance.
	float fine_k = 1.0 - smoothstep(0.3, 1.2, length(fwidth(lp * 83.0)));
	float height = dirt * 0.006 + pits * 0.002 * fine_k;
	vec3 dx = dFdx(VERTEX);
	vec3 dy = dFdy(VERTEX);
	vec3 rx = cross(dy, NORMAL);
	vec3 ry = cross(NORMAL, dx);
	float det = dot(dx, rx);
	vec3 bumped = abs(det) * NORMAL - sign(det) * (dFdx(height) * rx + dFdy(height) * ry);
	if (dot(bumped, bumped) > 0.000000000001) { NORMAL = normalize(bumped); }
	METALLIC = 0.6;
	float worn = smoothstep(0.52, 0.78, dirt);
	ROUGHNESS = mix(0.68, 0.24, worn);
	float hot_radius = min(0.12, min(distance(hot_p0, hot_p1), min(distance(hot_p1, hot_p2), distance(hot_p2, hot_p0))) * 0.3);
	float near_hot = min(distance(lp, hot_p0), min(distance(lp, hot_p1), distance(lp, hot_p2)));
	float points = 1.0 - smoothstep(hot_radius * 0.4, max(hot_radius, 0.0001), near_hot);
	vec3 sun = normalize((VIEW_MATRIX * vec4(sun_v, 0.0)).xyz);
	float glint = pow(max(dot(NORMAL, normalize(sun + VIEW)), 0.0), 96.0) * max(dot(NORMAL, sun), 0.0);
	EMISSION = hot_col * COLOR.a * hot * points * (0.5 + 0.9 * g) * 2.2;
	EMISSION += vec3(0.65, 0.52, 0.35) * glint * worn;
}
