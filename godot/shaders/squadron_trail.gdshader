shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform float clock_now = 0.0;
uniform float trail_len = 1.0;
uniform float width_k = 0.026;
uniform float alpha_k = 0.56;
uniform float life = 0.65;
void vertex() {
    float age = clock_now - UV2.x;
    vec3 back = NORMAL;
    vec3 c = cross(back, vec3(0.0, 1.0, 0.0));
    float cl = length(c);
    vec3 side = cl > 1e-6 ? c / cl : vec3(0.0);
    float width = trail_len * width_k * (1.0 + age);
    VERTEX += back * age * trail_len * 1.2 + side * width * (1.0 - 2.0 * UV.y);
    COLOR.a = max(0.0, 1.0 - age / life) * alpha_k;
    UV.x = age / life;
}
void fragment() {
    float edge = smoothstep(0.0, 0.38, UV.y) * (1.0 - smoothstep(0.62, 1.0, UV.y));
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a * edge;
}
