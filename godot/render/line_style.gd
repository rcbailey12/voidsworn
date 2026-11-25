extends RefCounted
const SKEEP := preload("res://render/shader_keep.gd")
# Issue 1374 (Ryan, Nov 20 2026, R362; docs/playbooks/scale.md section 6): one line style for everything drawn as a line
# on or over the battle board. Callers name a role, and its colour comes from ROLE below. The line_style shader include
# owns the shared width, glow and fade. The strip mesh uses the matching world widths below.
#
# The rule, in plain words:
# - width: a line is CORE_W world units wide up close, and never thinner than CORE_PX screen pixels further out;
# - fade: when the pixel floor widens a line, it dims in step (WIDEN_DIM), so zooming out never makes lines heavier;
# - glow: a soft band GLOW_W wide on one side (edges) or both (path lines), starting at GLOW_K of the core's strength;
#   the grid and the target rings are core only (no glow), so the board stays quiet (RULEBOOK 10.1);
# - breath: terrain and hazard edges shimmer slowly (BREATH deep), everything the player acts on stays steady.

const SHADER_CACHE := preload("res://render/shader_cache.gd")
const CORE_W := 0.32
const GLOW_W := 1.9

# the colour list (rgb) and each role's strength (a). Picks kept as they were made: the neutral grid (F1), the move blue
# (F1: no terrain uses it), the hovered hex ember (issue 271, R191), bone for threat (R174), the hazard and terrain edge
# colours (issue 1267), the amber solid ground rim (issue 1359, R361), the storm corona cool cyan-white (issue 1269).
const ROLE := {
	# the hex grid, per board look ("grid" is the normal view's)
	"grid": Color(0.66, 0.70, 0.78, 0.075),
	"grid_holo": Color(0.55, 0.85, 1.0, 0.2),
	"grid_ghost": Color(0.6, 0.82, 1.0, 0.16),
	"grid_tactical": Color(0.6, 0.8, 0.95, 0.13),
	# a ship's move hexes and its path
	"move": Color(0.25, 0.55, 1.0, 0.22),
	"move_fill": Color(0.10, 0.45, 1.0, 0.36),
	"move_hot": Color(0.30, 0.70, 1.0, 0.55),
	"move_rim": Color(0.30, 0.62, 0.85, 1.0),
	"move_rim_hot": Color(0.64, 0.88, 1.0, 1.0),
	"move_edge": Color(0.45, 0.85, 1.0, 1.0),
	"path": Color(0.45, 0.78, 1.0, 0.55),
	"hover": Color(1.0, 0.541, 0.227, 0.9),
	"threat": Color(0.941, 0.918, 0.871, 1.0),
	# targets: in reach now (red), in reach from the planned hex (orange), the one picked (white-hot), boarding, abilities
	"target": Color(1.0, 0.25, 0.2, 0.95),
	"target_plan": Color(1.0, 0.62, 0.22, 0.9),
	"target_on": Color(1.0, 0.85, 0.75, 1.0),
	"board": Color(1.0, 0.75, 0.3, 1.0),
	"ability": Color(1.0, 1.0, 1.0, 0.85),
	# issue 1444 forecasts: the armed ram's run, the nova shell's blast, and a friendly ship that would be hit (fills are
	# the see-through hex tint under the edge)
	"ram": Color(1.0, 0.55, 0.2, 0.95),
	"ram_fill": Color(1.0, 0.45, 0.15, 0.28),
	"blast": Color(1.0, 0.82, 0.45, 0.9),
	"blast_fill": Color(1.0, 0.7, 0.3, 0.3),
	"danger": Color(1.0, 0.12, 0.18, 1.0),
	"blocker": Color(1.0, 0.38, 0.08, 1.0),
	# terrain, hazard and objective edges, by kind
	"edge_neb": Color(0.72, 0.52, 1.0, 0.75),
	"edge_storm": Color(1.0, 0.88, 0.45, 0.7),
	"edge_debris": Color(0.86, 0.77, 0.56, 0.6),
	"edge_rock": Color(0.72, 0.76, 0.84, 0.45),
	"edge_solid": Color(0.95, 0.56, 0.24, 0.8),
	"edge_exit": Color(0.49, 1.0, 0.61, 0.85),
	"edge_texit": Color(0.95, 0.5, 0.45, 0.85),
	"edge_guard": Color(0.95, 0.5, 0.45, 0.8),
	"edge_hold": Color(1.0, 0.78, 0.35, 0.9),
	"edge_rim": Color(0.8, 0.55, 1.0, 0.8),
	"edge_pull": Color(0.62, 0.48, 0.95, 0.45),
	# issue 1446: where the next reinforcements come in (enemy coral, yours mint, as their ship rings), and an inspected
	# enemy's gun arcs (bone, the threat colour, kept quiet under your own ship's fans)
	"edge_arrive_enemy": Color(1.0, 0.54, 0.42, 0.9),
	"edge_arrive_ally": Color(0.32, 0.94, 0.77, 0.9),
	"arc_enemy": Color(0.941, 0.918, 0.871, 0.42),
	"edge_reach_enemy": Color(0.941, 0.918, 0.871, 0.6),   # issue 1446: the outline of where an inspected enemy can reach next turn
	# issue 1582: the drop-line from an off-plane hull to its hex, in its footprint's colour (yours mint, the enemy's violet)
	"drop_ally": Color(0.32, 0.94, 0.77, 0.75),
	"drop_enemy": Color(0.62, 0.22, 1.0, 0.75),
	"drop_neutral": Color(0.8, 0.85, 0.9, 0.75),
	# storm lightning (issue 1360 colours its baked bolts with these; the old ribbon too): hot channel, cyan skirt, cool
	# cyan-white corona (HDR values)
	"bolt_core": Color(2.2, 2.1, 2.4, 1.0),
	"bolt_skirt": Color(0.005, 0.8, 2.0, 1.0),
	"bolt_corona": Color(0.40, 0.72, 1.10, 1.0),
}

# roles drawn as a core line only (no glow band)
const NO_GLOW := ["grid", "grid_holo", "grid_ghost", "grid_tactical", "target", "target_plan", "target_on", "board",
	"ability", "hover", "ram", "blast", "danger"]


static func col(role: String) -> Color:
	return ROLE.get(role, Color(1, 1, 1, 1))


static func glow(role: String) -> float:
	return 0.0 if NO_GLOW.has(role) else 1.0


# the shared line material for strips built by strip_into(): COLOR is the role's colour and strength, UV.x the distance
# into the line, UV.y 1 for a glow band (plus 2 for one half of a centred line, which starts at the line's middle); gain is how strong the whole mesh shows (the board look's edge gains), breath 1
# for the slow shimmer of terrain and hazard edges
const SHADER := preload("res://shaders/board_line.gdshader")

# issue 1582: a straight line drawn on its own quad (the drop-line under an off-plane hull). UV.x runs across the quad,
# qw world units wide; the line sits in the middle at the shared core width with its pixel floor and widen-dim, so it
# never breaks up when zoomed out. col is the role's colour and strength, wide a hover widening (1 = normal).
const QUAD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec4 col = vec4(1.0);
uniform float qw = 3.0;
uniform float wide = 1.0;
""" + GLSL + """
void fragment() {
	float x = abs(UV.x - 0.5) * qw;
	float fw = max(fwidth(x), 0.0001);
	float w = ls_core_w(fw) * wide;
	float l = (1.0 - smoothstep(0.5 * w - 0.5 * fw, 0.5 * w + 0.5 * fw, x)) * ls_dim(w / wide);
	ALBEDO = col.rgb * col.a * l;
}
"""


static func quad_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = QUAD_SHADER
	m.shader = sh
	return m


# how far past the outer edge a strip starts (room for the anti-aliased edge) and how deep it runs (the widest core the
# pixel floor gives when zoomed far out, plus the glow band)
const STRIP_OUT := 0.25
const STRIP_IN := 4.4


static func material(breath := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_CACHE.for_code(SHADER)
	m.set_shader_parameter("breath", 1.0 if breath else 0.0)
	return m


# one line segment into a SurfaceTool (PRIMITIVE_TRIANGLES): a0 to b0 is the line's outer edge, inward points from it
# toward the glow side, in the board plane, scaled so one unit along it is one unit away from the line. c overrides the
# role's colour (a terrain kind's edge, a faction tint). centred: a0 to b0 is the middle of a line seen from both sides
# (a path); call it once per side, with opposite inward directions.
static func strip_into(st: SurfaceTool, a0: Vector3, b0: Vector3, inward_a: Vector3, inward_b: Vector3, role: String, c := Color(0, 0, 0, -1), centred := false) -> void:
	var cc: Color = col(role) if c.a < 0.0 else c
	var g := glow(role)
	var depth := STRIP_IN if g > 0.0 else 1.6
	var out := 0.0 if centred else STRIP_OUT
	var p0 := a0 - inward_a * out
	var p1 := b0 - inward_b * out
	var p2 := b0 + inward_b * depth
	var p3 := a0 + inward_a * depth
	var u := g + (2.0 if centred else 0.0)
	for v in [[p0, -out], [p1, -out], [p2, depth], [p0, -out], [p2, depth], [p3, depth]]:
		st.set_color(cc)
		st.set_uv(Vector2(v[1], u))
		st.add_vertex(v[0])
