shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled, world_vertex_coords;
uniform sampler2D noise : filter_linear_mipmap, repeat_enable;
uniform vec3 tail_col = vec3(0.55, 0.7, 0.9);
uniform float gain = 0.22;
varying vec2 vQ;
varying float vSeed;
varying float vFade;
void vertex() {
	// INSTANCE_CUSTOM: x tail length, y width at the root, z width at the end, w seed. The instance's Y axis is the tail.
	vec3 head = MODEL_MATRIX[3].xyz;
	vec3 axis = normalize(MODEL_MATRIX[1].xyz);
	// world_vertex_coords: VERTEX arrives already in world space, so the quad's own corners come from its UV
	float t = 1.0 - UV.y;
	vec3 along = head + axis * t * INSTANCE_CUSTOM.x;
	vec3 eye = INV_VIEW_MATRIX[3].xyz;
	// Artoo on PR 1782: seen straight down the tail the cross product is zero; fall back to a fixed side (the card is
	// faded out there anyway, below) so the corners never get an undefined direction
	vec3 c = cross(axis, along - eye);
	vec3 side = dot(c, c) > 1e-8 ? normalize(c) : normalize(cross(axis, abs(axis.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
	vec3 to_head = head - eye;
	vFade = 1.0 - smoothstep(0.82, 0.97, abs(dot(axis, to_head)) / max(length(to_head), 1e-3));
	VERTEX = along + side * (UV.x - 0.5) * mix(INSTANCE_CUSTOM.y, INSTANCE_CUSTOM.z, sqrt(t));
	vQ = vec2(UV.x * 2.0 - 1.0, t);
	vSeed = INSTANCE_CUSTOM.w;
}
void fragment() {
	float u = abs(vQ.x);
	float t = vQ.y;
	// streamers along the tail: noise stretched along its length, drifting slowly outward
	vec2 uv = vec2(vQ.x * 0.9 + vSeed * 5.0, t * 0.18 - TIME * 0.002 + vSeed * 3.0);
	float n = texture(noise, uv).r;
	float m = texture(noise, uv * vec2(2.7, 1.3) + n * 0.2 + 0.4).r;
	float streak = 0.55 + 0.75 * smoothstep(0.35, 0.8, n * 0.6 + m * 0.4);
	float across = 1.0 - smoothstep(0.15, 1.0, u);
	float along = smoothstep(0.0, 0.04, t) * exp(-t * 2.6) * (1.0 + 0.6 * exp(-t * 18.0));
	ALBEDO = tail_col * across * along * streak * gain * vFade;
}
