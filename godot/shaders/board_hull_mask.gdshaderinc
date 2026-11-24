uniform sampler2D board_depth : hint_depth_texture, filter_nearest, repeat_disable;
void under_hulls(vec2 screen_uv, mat4 inv_projection, mat4 inv_view) {
	float z = texture(board_depth, screen_uv).r;
	if (z <= 0.000001) { return; }
	vec4 p = inv_projection * vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec3 world = (inv_view * vec4(p.xyz / p.w, 1.0)).xyz;
	if (world.y > -20.0) { discard; }
}
