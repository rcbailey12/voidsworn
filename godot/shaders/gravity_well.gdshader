shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform vec3 well = vec3(0.0);
uniform float r_in = 60.0;
uniform float r_out = 120.0;
uniform float k = 1.0;
uniform float chroma_px = 1.5;
varying vec3 vW;
varying vec4 vWell;
void vertex() {
	vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vWell = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(well, 1.0));
}
// Test the destination AND all three source samples. A ship must neither bend nor be copied into the background.
bool foreground(vec2 uv, mat4 inv_projection, mat4 inv_view) {
	float depth = texture(depth_tex, uv).r;
	vec4 v = inv_projection * vec4(uv * 2.0 - 1.0, depth, 1.0);
	vec3 world = (inv_view * vec4(v.xyz / v.w, 1.0)).xyz;
	return depth > 0.000001 && world.y > -20.0;
}
void fragment() {
	float d = distance(vW.xz, well.xz);
	float w = smoothstep(r_in, r_in + 22.0, d) * (1.0 - smoothstep(r_out - 34.0, r_out, d));
	float rim = 1.0 - smoothstep(0.25, 0.65, abs(d - r_in - 2.0));
	float age = mod(TIME, 3.5);
	float travel = clamp(age / 2.0, 0.0, 1.0);
	float ripple = (1.0 - smoothstep(0.4, 1.15, abs(d - mix(r_out, r_in, travel)))) * (1.0 - travel);
	vec2 radial = vW.xz - well.xz;
	float angle = atan(radial.y, radial.x) - TIME * 0.13962634; // 45 s per turn
	float acc = smoothstep(22.0, 28.0, d) * (1.0 - smoothstep(54.0, r_in, d));
	acc *= 0.55 + 0.45 * sin(angle * 3.0 + d * 0.16);
	if (max(w, max(rim, max(ripple, acc))) <= 0.001 || foreground(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX)) { discard; }
	vec2 cs = vWell.xy / vWell.w * 0.5 + 0.5;
	vec2 dv = SCREEN_UV - cs;
	// pushed outward like a lens, and dragged slowly round
	float s = 0.075 * w * (r_in + 22.0) / max(d, 1.0);
	float an = 0.06 * w + 0.04 * w * sin(TIME * 0.20943951); // 30 s slow twist
	mat2 R = mat2(vec2(cos(an), sin(an)), vec2(-sin(an), cos(an)));
	vec2 suv = clamp(cs + R * dv * (1.0 - s), vec2(0.001), vec2(0.999));
	float fr = VIEWPORT_SIZE.y / 1080.0;
	vec2 shift = normalize(dv + vec2(0.000001)) / vec2(textureSize(screen_tex, 0)) * chroma_px * rim * fr;
	vec2 red_uv = clamp(suv + shift, vec2(0.001), vec2(0.999));
	vec2 blue_uv = clamp(suv - shift, vec2(0.001), vec2(0.999));
	if (foreground(suv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) || foreground(red_uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) || foreground(blue_uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX)) {
		suv = SCREEN_UV; red_uv = SCREEN_UV; blue_uv = SCREEN_UV;
	}
	vec3 c = vec3(textureLod(screen_tex, red_uv, 0.0).r, textureLod(screen_tex, suv, 0.0).g, textureLod(screen_tex, blue_uv, 0.0).b);
	vec3 warm = mix(vec3(0.15, 0.012, 0.005), vec3(0.55, 0.25, 0.10), 1.0 - smoothstep(24.0, r_in, d));
	c += warm * acc * 0.15;
	c += vec3(0.18, 0.085, 0.045) * ripple * 0.12;
	c += vec3(0.32, 0.40, 0.48) * rim;
	ALBEDO = c;
	ALPHA = max(w, max(rim * 0.35, max(ripple * 0.12, acc * 0.15))) * k;
}
