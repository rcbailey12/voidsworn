shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/board_hull_mask.gdshaderinc"

varying vec4 vcol;
void vertex() { vcol = COLOR; }
void fragment() {
	under_hulls(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	ALBEDO = vcol.rgb * vcol.a;
	ALPHA = 1.0;
}
