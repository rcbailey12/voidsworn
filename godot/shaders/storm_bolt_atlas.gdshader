shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform sampler2D atlas : filter_linear_mipmap, repeat_disable, hint_default_black;
instance uniform float frame = -1.0;
instance uniform float gain = 0.0;
instance uniform float mirror = 0.0;
#include "res://shaders/line_style.gdshaderinc"
void vertex() {
	// A card turned about the bolt's own axis to face the camera: MODEL_MATRIX's y column runs from the bolt's end to
	// its start (the tile's height), x carries the width, the origin is the tile's centre.
	vec3 centre = MODEL_MATRIX[3].xyz;
	vec3 up = MODEL_MATRIX[1].xyz;
	float width = length(MODEL_MATRIX[0].xyz);
	vec3 side = cross(up, CAMERA_POSITION_WORLD - centre);
	side = length(side) > 0.0001 ? normalize(side) : normalize(MODEL_MATRIX[0].xyz);
	vec3 world = centre + side * VERTEX.x * width + up * VERTEX.y;
	POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(world, 1.0));
}
void fragment() {
	if (gain <= 0.0 || frame < 0.0) { discard; }
	float f = floor(frame);
	vec2 uv = vec2(mix(UV.x, 1.0 - UV.x, mirror), UV.y);
	vec2 cell = vec2(mod(f, 4.0), floor(f / 4.0));
	vec4 s = texture(atlas, (cell + clamp(uv, 0.004, 0.996)) / 4.0);
	// Issue 1374 (R362): colours from the one line style (render/line_style.gd bolt_*). The hot channel is the core
	// colour, the near glow the cyan skirt, and the cyan-white corona sits outside the skirt, never on the hot tube.
	float core = max(s.r, s.g * 0.85);
	float corona = max(s.a - s.b * 0.5, 0.0);
	vec3 col = LS_BOLT_CORE * core + LS_BOLT_SKIRT * s.b * 0.30 + LS_BOLT_CORONA * corona * 0.22;
	ALBEDO = col * gain;
}
