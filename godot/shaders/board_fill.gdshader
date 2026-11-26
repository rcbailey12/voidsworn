shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

#include "res://shaders/board_hull_mask.gdshaderinc"

#include "res://shaders/line_style.gdshaderinc"

varying vec4 vcol;
varying vec2 vp;
varying float style;
varying float band;
varying vec2 wpos;
// Ryan (Nov 20, issue 1359 thread, picked "Only with Z"): the reach hatching covered the whole board and read as random
// far-off grid lines. hatch_hidden 1 (the normal view) draws none; Z and the other looks keep it board-wide.
uniform float hatch_hidden = 0.0;
void vertex() { vcol = COLOR; vp = VERTEX.xz; style = INSTANCE_CUSTOM.r; band = INSTANCE_CUSTOM.g; wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	under_hulls(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	// soft inner falloff so a lit hex reads as a glow, not a flat plate
	float r = length(vp) / 10.0;
	float k = mix(0.75, 1.0, smoothstep(0.2, 0.95, r));
	vec3 c = vcol.rgb;
	float a = vcol.a * k;
	if (style > 0.5) {
		// F1: a hex the ship can move to. Terrain tints are flat; a reach hex has a lit inner edge and breathes slowly,
		// so it never reads as terrain (style 2: the hovered or planned hex, brighter and steady)
		vec2 q = abs(vp);
		float d = max(q.x, 0.5 * q.x + 0.8660254 * q.y) / 8.53;
		float hot = style > 1.5 ? 1.0 : 0.0;
		// Every board look: a narrow lit edge and barely tinted space, no scanning blue plate. Issue 1374: the edge is the
		// shared line (render/line_style.gd), a core just inside the hex edge and its glow band inward
		float e = (1.0 - d) * 8.53 - 0.12;
		float rim = ls_line(e, max(fwidth(e), 0.0001), 1.0);
		a = mix(0.012, 0.032, hot) + rim * mix(0.24, 0.5, hot);
		c = mix(LS_MOVE_RIM, LS_MOVE_RIM_HOT, hot);
	}
	if (band > 0.5) {
		// #271 reach hatching, in the threat colour (bone, issue 271 step 2: not red, which is the Nemesis alarm, and not
		// lavender or purple, an AI tell on Ryan's list, R174): how many enemies can bring guns on this hex next turn,
		// carried by the pattern as well as the colour (ui_spec.md 5.2): sparse lines for 1, closer for 2, crossed for 3+.
		// Drawn in board space so the lines run on across hexes.
		// line width: about one pixel at any zoom (screen-space), never thicker than a tenth of the gap between lines
		// R148 (calmer, as the mockup): about three lines across a hex for 1, four for 2 and 3+, and light
		float per = band > 1.5 ? 5.7 : 8.5;
		float d1 = abs(fract((wpos.x + wpos.y) / per) - 0.5) * per;
		float w1 = fwidth(wpos.x + wpos.y);
		float hw1 = min(0.55 * w1, 0.1 * per);
		float l = 1.0 - smoothstep(hw1, hw1 + w1, d1);
		if (band > 2.5) {
			float d2 = abs(fract((wpos.x - wpos.y) / per) - 0.5) * per;
			float w2 = fwidth(wpos.x - wpos.y);
			float hw2 = min(0.55 * w2, 0.1 * per);
			l = max(l, 1.0 - smoothstep(hw2, hw2 + w2, d2));
		}
		// alphas are blended in linear light, so a small number already reads clearly on the dark board (0.03 shows
		// about as bright as 0.2 would in screen colour)
		float h = l * (band > 2.5 ? 0.034 : (band > 1.5 ? 0.028 : 0.022));
		h *= 1.0 - hatch_hidden;
		float A = h + a * (1.0 - h);
		c = (LS_THREAT * h + c * a * (1.0 - h)) / max(A, 0.0001);
		a = A;
	}
	ALBEDO = c;
	ALPHA = clamp(a, 0.0, 1.0);
}
