shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
// F1: the plain grid (style 0) fades with distance from the ship that is up, so the board is quiet away from the action
// board look trial: mode 0 today, 1 holo (corner ticks and faint edges near the ship that is up and the cursor, nothing
// far away), 2 ghost (only round the cursor), 3 tactical (the whole grid, even)
uniform int mode = 0;
uniform vec3 focus = vec3(0.0);
uniform vec3 cursor = vec3(100000.0);
uniform float near_r = 70.0;
uniform float far_r = 190.0;
// the gravity well: xyz its centre, w how deep the holo grid dips toward it (0: flat)
uniform vec4 well = vec4(0.0);

#include "res://shaders/board_hull_mask.gdshaderinc"

#include "res://shaders/line_style.gdshaderinc"

varying vec4 vcol;
varying float style;
varying vec3 wp;
varying vec2 vuv;
varying float thin;
void vertex() {
	vcol = COLOR;
	style = INSTANCE_CUSTOM.r;
	vuv = UV;
	// step 2: a line never thinner than the shared pixel floor (render/line_style.gd, issue 1374), so the tactical grid
	// stays whole and crisp when zoomed out (it broke up into dashes); the inner edge (UV.y 1) moves in toward the hex
	// centre, and the line dims to match (the shared fade law)
	thin = 1.0;
	if (UV.y > 0.5) {
		vec3 wv = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		float dist = length((VIEW_MATRIX * vec4(wv, 1.0)).xyz);
		float px = 2.0 * dist / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
		float w = ls_core_w(px);
		vec2 dir = normalize(VERTEX.xz);
		VERTEX.xz -= dir * (w - LS_CORE_W) * 1.1547;
		thin = ls_dim(w);
	}
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (well.w > 0.0 && style < 0.5) {
		float d = distance(wp.xz, well.xz);
		float f = 1.0 - smoothstep(10.0, 105.0, d);
		float dy = -well.w * f * f;
		VERTEX.y += dy;
		wp.y += dy;
	}
}
void fragment() {
	float k = 1.0;
	if (style < 0.5) {
		if (mode == 0) {
			k = 1.0 - smoothstep(near_r, far_r, distance(wp.xz, focus.xz));
		} else if (mode == 1) {
			// Look C lights the action, not the whole camera view. Panning or
			// zooming out should not make distant hexes light up again.
			float kf = 1.0 - smoothstep(28.0, 118.0, distance(wp.xz, focus.xz));
			float kc = 1.0 - smoothstep(12.0, 52.0, distance(wp.xz, cursor.xz));
			float e = min(vuv.x, 1.0 - vuv.x);
			float tick = 1.0 - smoothstep(0.07, 0.2, e);
			k = max(kf, 0.85 * kc) * mix(0.3, 1.0, tick);
			k *= 1.0 + 0.9 * smoothstep(0.95, 1.0, sin(dot(wp.xz, vec2(0.018, 0.03)) - TIME * 0.9));
		} else if (mode == 2) {
			k = (1.0 - smoothstep(9.0, 30.0, distance(wp.xz, cursor.xz))) * 0.9;
		}
		if (k <= 0.0) { discard; }
	}
	under_hulls(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	ALBEDO = vcol.rgb * vcol.a * k * thin;
	ALPHA = 1.0; // Draw after opaque hulls, with depth testing, just like the fill.
}
