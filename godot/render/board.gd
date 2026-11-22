extends Node3D
# The hex board at the game's scale: pointy-top hexes of corner radius 10 (HEX_S), laid out as scene3d.js hexWorld does,
# with the world's z mirrored for Godot. One MultiMesh for the hex fills and one for the outlines (two draws for the
# whole board); overlays (move range, targets, hover, zones) only change instance colours.

const HT := preload("res://render/hull_table.gd")
const BL := preload("res://world/board_look.gd")   # the board look trial (today, A holo, B living, C cinematic + tactical)
const A4P := preload("res://assets/ships/a4_props.gd")  # A4's painted station and derelicts (null when not built)
const BV := preload("res://world/blocker_visuals.gd")
const LS := preload("res://render/line_style.gd")   # issue 1374 (R362): the one line style (width, glow, fade, role colours)
const HS := 10.0
var HW := HS * sqrt(3.0)
# The one scale table's board-side sizes (issue 710, R247; docs/playbooks/scale.md). All in world units, HEX_S = 10.
const STATION_BASE_LEN := 22.0     # a small station cluster: 22, then 4 more per hex
const STATION_PER_HEX := 4.0
const STATION_BIG_LEN := A4P.LARGE_STATION_SIZE  # a cluster of 5 or more station hexes
const STATION_BIG_HEXES := 5
const HULK_SCALE := 11.0           # a board wreck: the A4 hull scaled to this length
const PLANET_R_DEFAULT := 3.0      # the map's planet radius in hexes when it names none
const PLANET_EDGE_K := 1.5         # planetEdge: R * 1.5 * HEX_S + HEX_S / 2

var api = null               # the rules API (godot/rules/battle_api.gd): read through view() and world_info()
var VW := {}                 # the view the board was built from
var WI := {}                 # world_info()
var planet_node: MeshInstance3D = null   # the board planet, when the map has one
var sun_dir := Vector3(0.4, 0.6, 0.7)   # toward the battle's key light (battle.gd sets it before build)
# the board planet's look per battle: [kind (G3 map shader: 0 rock, 1 terran, 3 ice, 4 lava, 5 barren), colour a, b, atmosphere]
const PLANET_LOOKS := [
	[0, Color(0.55, 0.42, 0.3), Color(0.22, 0.15, 0.1), Color(0.9, 0.65, 0.4)],
	[1, Color(0.36, 0.42, 0.24), Color(0.07, 0.15, 0.3), Color(0.45, 0.7, 1.0)],
	[3, Color(0.82, 0.88, 0.94), Color(0.42, 0.52, 0.62), Color(0.6, 0.8, 1.0)],
	[4, Color(0.28, 0.2, 0.16), Color(0.08, 0.06, 0.05), Color(1.0, 0.45, 0.2)],
	[5, Color(0.5, 0.48, 0.46), Color(0.2, 0.19, 0.19), Color(0.6, 0.62, 0.7)],
]
var ox := 0.0
var oz := 0.0
var cells: Array = []        # [{q, r}]
var index := {}              # "q,r" -> instance index
var fills: MultiMeshInstance3D
var rings: MultiMeshInstance3D
var base_fill := {}          # "q,r" -> Color (terrain zone tints)
var overlay := {}            # "q,r" -> Color
var ring_over := {}          # "q,r" -> Color
var style_over := {}         # "q,r" -> 1 move hex, 2 hovered or planned move hex (F1: drawn with a lit edge, never a terrain look)
var danger_over := {}        # "q,r" -> 1, 2 or 3: how many enemies can reach the hex next turn (#271 hatching; 3 means 3 or more)
var hover_key := ""
var blocker_visuals: Node3D
var blocker_highlights: Node3D
var props: Node3D
var rock_meshes: Array = []
var wrecks := {}             # issue 1236: unit id -> "q,r" of each wreck the rules laid down during this battle
var wreck_hulls := {}        # issue 1236: unit id -> true where the board laid the burnt hulk (the death left no pieces)
var built := 0               # how many times build() ran (a late wreck check knows its battle is gone)
var props_world := false     # G4 world draws the rocks, debris and nebula; the board keeps hulks, stations and the planet

# The board plane passes through the lower half of tall hulls. Depth-test alone
# cannot protect those pixels, so mask opaque ship/terrain surfaces near the board.
const HULL_MASK := """
uniform sampler2D board_depth : hint_depth_texture, filter_nearest, repeat_disable;
void under_hulls(vec2 screen_uv, mat4 inv_projection, mat4 inv_view) {
	float z = texture(board_depth, screen_uv).r;
	if (z <= 0.000001) { return; }
	vec4 p = inv_projection * vec4(screen_uv * 2.0 - 1.0, z, 1.0);
	vec3 world = (inv_view * vec4(p.xyz / p.w, 1.0)).xyz;
	if (world.y > -20.0) { discard; }
}
"""

const FILL_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + HULL_MASK + LS.GLSL + """
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
"""
const RING_SHADER := """
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
""" + HULL_MASK + LS.GLSL + """
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
"""
const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
""" + HULL_MASK + """
varying vec4 vcol;
void vertex() { vcol = COLOR; }
void fragment() {
	under_hulls(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	ALBEDO = vcol.rgb * vcol.a;
	ALPHA = 1.0;
}
"""
# board look trial: the edge round each patch of terrain (nebula, storm, debris, rock, zones, the well's rim and pull);
# issue 1374: the shared line shader (render/line_style.gd), its slow shimmer on (LS.material(true))
const EDGE_SHADER := LS.SHADER


func hex_world(q: float, r: float, y := 0.0) -> Vector3:
	return Vector3(HW * (q + r / 2.0) + ox, y, 1.5 * HS * r + oz)


func world_hex(p: Vector3) -> Vector2i:
	var x := p.x - ox
	var z := p.z - oz
	var rr := z / (1.5 * HS)
	var qq := x / HW - rr / 2.0
	# cube rounding
	var cx := qq
	var cz := rr
	var cy := -cx - cz
	var rx := roundf(cx)
	var ry := roundf(cy)
	var rz := roundf(cz)
	var dx := absf(rx - cx)
	var dy := absf(ry - cy)
	var dz := absf(rz - cz)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2i(int(rx), int(rz))


func key(q, r) -> String:
	return str(int(q)) + "," + str(int(r))


func build(rules) -> void:
	api = rules
	VW = api.view()
	wrecks.clear()
	wreck_hulls.clear()
	built += 1
	WI = api.world_info() if api.has_method("world_info") else {}
	for c in get_children():
		c.queue_free()
	cells = []
	for h in VW.get("hexes", []):
		cells.append({"q": int(h["q"]) if h is Dictionary else int(h.q), "r": int(h["r"]) if h is Dictionary else int(h.r)})
	# centre the board on the world origin (the game offsets by G.ox, G.oz the same way)
	var lo := Vector2(1e9, 1e9)
	var hi := Vector2(-1e9, -1e9)
	for h in cells:
		var p := Vector2(HW * (float(h.q) + float(h.r) / 2.0), 1.5 * HS * float(h.r))
		lo = lo.min(p)
		hi = hi.max(p)
	ox = -(lo.x + hi.x) * 0.5
	oz = -(lo.y + hi.y) * 0.5
	index.clear()
	for i in cells.size():
		index[key(cells[i].q, cells[i].r)] = i
	fills = _mm(_hex_mesh(HS * 0.985, false), FILL_SHADER)
	rings = _mm(_hex_mesh(HS, true), RING_SHADER)
	outline = MeshInstance3D.new()
	outline.name = "ReachOutline"
	var om := ShaderMaterial.new()
	var osh := Shader.new()
	osh.code = OUTLINE_SHADER
	om.shader = osh
	outline.material_override = om
	outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(outline)
	outline_key = ""
	props = Node3D.new()
	props.name = "Terrain"
	add_child(props)
	_terrain()
	blocker_visuals = BV.new()
	props.add_child(blocker_visuals)
	blocker_visuals.build(VW, hex_world)
	blocker_highlights = Node3D.new()
	add_child(blocker_highlights)
	_zones()
	_well_info()
	_terrain_edges()
	apply_look(false)


func bounds() -> Vector2:
	var m := Vector2.ZERO
	for h in cells:
		var p := hex_world(h.q, h.r)
		m = m.max(Vector2(absf(p.x), absf(p.z)))
	return m + Vector2(HS, HS)


func _mm(mesh: Mesh, code: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = cells.size()
	for i in cells.size():
		mm.set_instance_transform(i, Transform3D(Basis(), hex_world(cells[i].q, cells[i].r, -0.4)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


# a pointy-top hexagon in the xz plane: a filled disc, or a thin ring (the outline)
func _hex_mesh(rad: float, ring: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	for i in 6:
		var an := deg_to_rad(60.0 * i + 30.0)
		pts.append(Vector2(cos(an), sin(an)))
	if ring:
		var w := LS.CORE_W
		for i in 6:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 6]
			var a0 := Vector3(a.x * rad, 0, a.y * rad)
			var b0 := Vector3(b.x * rad, 0, b.y * rad)
			var a1 := Vector3(a.x * (rad - w), 0, a.y * (rad - w))
			var b1 := Vector3(b.x * (rad - w), 0, b.y * (rad - w))
			# UV.x runs 0 to 1 along each edge (the holo grid brightens the corners)
			# UV.y is 1 on the inner edge (the ring shader widens the line from there when it would draw thinner than a pixel)
			for v in [[a0, 0.0, 0.0], [b0, 1.0, 0.0], [b1, 1.0, 1.0], [a0, 0.0, 0.0], [b1, 1.0, 1.0], [a1, 0.0, 1.0]]:
				st.set_uv(Vector2(v[1], v[2]))
				st.add_vertex(v[0])
	else:
		for i in 6:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 6]
			for v in [Vector3.ZERO, Vector3(a.x * rad, 0, a.y * rad), Vector3(b.x * rad, 0, b.y * rad)]:
				st.add_vertex(v)
	return st.commit()


const ZONE_TINT := {"neb": Color(0.69, 0.49, 1.0, 0.075), "debris": Color(0.83, 0.75, 0.53, 0.065), "storm": Color(1.0, 0.91, 0.4, 0.065)}
const BASE_FILL := Color(0.04, 0.06, 0.09, 0.18)
# F1: a neutral grey grid (was a pale blue that blended with the move hexes); it fades away from the ship that is up
const BASE_RING: Color = LS.ROLE["grid"]
# F1: the hexes a ship can move to are blue, a colour no terrain, zone or marker uses (nebula violet, debris sand, storm
# yellow, exits green, perimeters red, the relay gold, your ships mint, enemies violet, the hovered hex ember)
const REACH_FILL: Color = LS.ROLE["move_fill"]
const REACH_HOT: Color = LS.ROLE["move_hot"]
const REACH_RING: Color = LS.ROLE["move"]
const REACH_EDGE: Color = LS.ROLE["move_edge"]
# the hovered hex's outline: the battle screen's ember (#ff8a3a; issue 271 step 2, lime retired by R191)
const HOVER_RING: Color = LS.ROLE["hover"]
# the threat map (R) and the reach hatching: bone, the sheet's TEXT (#f0eade) as a wash on the board. Red is the Nemesis
# alarm's alone, lavender and purple are on Ryan's AI-tell list (R174), blue is the reach, ember the next action.
const THREAT: Color = LS.ROLE["threat"]


# objective zones (ui3d.js ZONE_INFO): the exit edge green, the transports' exit and the station perimeter red; the relay
# hex for hold gold
const ZONE_C := {"exit": Color(0.49, 1.0, 0.61, 0.16), "texit": Color(0.88, 0.48, 0.44, 0.16), "guard": Color(0.88, 0.48, 0.44, 0.14)}
var zone_of := {}


func _zones() -> void:
	zone_of.clear()
	var zones: Dictionary = VW.get("zones", {}) if VW.get("zones") is Dictionary else {}
	for h in cells:
		var z = zones.get(key(h.q, h.r))
		if z != null and ZONE_C.has(str(z)):
			var k := key(h.q, h.r)
			zone_of[k] = str(z)
			base_fill[k] = ZONE_C[str(z)]
	var o = VW.get("obj")
	if o is Dictionary and str(o.get("type", "")) == "hold" and o.get("hex") is Dictionary:
		base_fill[key(o["hex"]["q"], o["hex"]["r"])] = Color(0.82, 0.65, 0.29, 0.3)


func refresh() -> void:
	var fm := fills.multimesh
	var rm := rings.multimesh
	var sp := BL.spec()
	var base_ring: Color = LOOK_RING.get(str(sp["grid"]), BASE_RING)
	for i in cells.size():
		var k := key(cells[i].q, cells[i].r)
		var c: Color
		if overlay.has(k):
			c = overlay[k]
		elif sp["fills"]:
			c = base_fill.get(k, BASE_FILL if sp["plate"] else Color(0, 0, 0, 0))
		else:
			c = Color(0, 0, 0, 0)
		fm.set_instance_color(i, c)
		var stl := float(style_over.get(k, 0))
		fm.set_instance_custom_data(i, Color(stl, float(danger_over.get(k, 0)), 0, 0))
		var rc: Color = ring_over.get(k, base_ring)
		# the holo and living looks: the reach hexes' own outlines quieter (the footprint and its one outline carry them)
		if ring_over.has(k) and style_over.has(k):
			rc.a *= 0.5
		if k == hover_key:
			rc = HOVER_RING   # the hovered hex: the ember, the next action (issue 271; lime retired, R191)
		rm.set_instance_color(i, rc)
		rm.set_instance_custom_data(i, Color(1.0 if (ring_over.has(k) or k == hover_key) else 0.0, 0, 0, 0))


# fills and rings per hex ("q,r" -> Color); styles "q,r" -> 1 (a move hex) or 2 (the hovered or planned move hex)
func set_overlay(o: Dictionary, rings_o := {}, styles := {}) -> void:
	overlay = o
	ring_over = rings_o
	style_over = styles
	refresh()


# #271: the reach hatching bands ("q,r" -> 1, 2 or 3); an empty dictionary clears them
func set_danger(d: Dictionary) -> void:
	if d == danger_over:
		return
	danger_over = d
	refresh()


var _hover_raw := ""   # the hex under the cursor even off the board's cells (a set-piece hole), for the 1359 rims


func set_hover(q: int, r: int) -> void:
	_hover_raw = key(q, r)
	_show_hover_edge(_hover_raw)
	var k := key(q, r) if index.has(key(q, r)) else ""
	if k != hover_key:
		hover_key = k
		if rings != null and rings.material_override is ShaderMaterial:
			(rings.material_override as ShaderMaterial).set_shader_parameter("cursor", hex_world(q, r) if k != "" else Vector3(100000, 0, 100000))
		refresh()


# where the plain grid is brightest (the ship that is up, or the camera target)
func set_focus(p: Vector3) -> void:
	if rings != null and rings.material_override is ShaderMaterial:
		(rings.material_override as ShaderMaterial).set_shader_parameter("focus", p)


# F1: one bright line around the whole area a ship can reach (keys: "q,r" -> anything), drawn on the board just inside
# the outer hex edges, with a soft glow band; an empty dictionary clears it
var outline: MeshInstance3D
var outline_key := ""


func set_outline(keys: Dictionary, col := REACH_EDGE) -> void:
	# The per-hex soft rims carry the reachable area in every look.
	if outline != null:
		outline.mesh = null


func on_board(q: int, r: int) -> bool:
	return index.has(key(q, r))


# ---------------------------------------------------------------- board look trial (world/board_look.gd)
# Ryan, Nov 1 16:12: "it almost ends up just looking like a board game on top of a cool background with the gray and 2d
# plane aspect". Four looks, switchable while playing: F8 cycles them, Z (or the Grid button) brings up the tactical grid
# in look C. Default stays today's board until Ryan picks. None of this changes the rules or which hexes a ship can reach.

# the plain grid's colour per look (alpha is its strength where it shows)
const LOOK_RING := {"today": BASE_RING, "holo": LS.ROLE["grid_holo"], "ghost": LS.ROLE["grid_ghost"], "tactical": LS.ROLE["grid_tactical"]}
# the terrain edge colours (rgb) and strength (a)
const EDGE_C := {"neb": LS.ROLE["edge_neb"], "storm": LS.ROLE["edge_storm"], "debris": LS.ROLE["edge_debris"],
	"rock": LS.ROLE["edge_rock"], "exit": LS.ROLE["edge_exit"], "texit": LS.ROLE["edge_texit"],
	"guard": LS.ROLE["edge_guard"], "hold": LS.ROLE["edge_hold"], "rim": LS.ROLE["edge_rim"], "pull": LS.ROLE["edge_pull"]}
var edges: MeshInstance3D
var well_c := Vector3.INF      # the gravity well's centre on the board (the dead star), INF when none
var _look_btn: Button = null
var _look_layer: CanvasLayer = null
var _toast: Label = null
var _toast_t := 0.0
var _edge_gain := 0.0
var gas_edges: MeshInstance3D
var _gas_edge_gain := 0.0
# Issue 1267 (Ryan's pick 1, Nov 20): the normal (cine) view keeps its big soft clouds but adds a faint line on the
# outer edge of nebula (cover) and ion storm (shield drain) patches, so where they stop reads without Z
var hazard_edges: MeshInstance3D
var _hazard_edge_gain := 0.0
const HAZARD_EDGE := ["neb", "storm"]
# Issue 1359 (Neon backdrop audit H4; Ryan picked B on Nov 20 11:30 CT, "only show up when you hover over it in
# cinematic mode and then when you have the full grid ... it shows by default"): an amber rim round solid ground (rock,
# hulk, station and the map's set-piece holes; the colour of the planet and station exclusion rims) and a softer tan
# one round debris cover. Z draws every patch (solid_edge, cover_edge); the normal view draws only the patch under the
# cursor (edge_hover, at hover_solid and hover_cover). Z's gas edges leave rock and debris to these two.
const SOLID_EDGE_C: Color = LS.ROLE["edge_solid"]
var solid_edges: MeshInstance3D
var cover_edges: MeshInstance3D
var _solid_edge_gain := 0.0
var _cover_edge_gain := 0.0
var hover_edges: Node3D            # one child mesh per solid or debris patch, named by kind
var _hover_patch := {}             # "q,r" -> that hex's patch mesh under hover_edges
var _edge_hover := false
var _hover_gain := {"solid": 0.0, "cover": 0.0}
var _hover_shown: MeshInstance3D = null


func _well_info() -> void:
	well_c = Vector3.INF
	var meta = VW.get("map")
	if meta is Dictionary and meta.get("deadstar") is Dictionary:
		well_c = hex_world(int(meta["deadstar"]["q"]), int(meta["deadstar"]["r"]))


static func _hdist(q0: int, r0: int, q1: int, r1: int) -> int:
	var dq := q0 - q1
	var dr := r0 - r1
	return int((absi(dq) + absi(dq + dr) + absi(dr)) / 2)


# one mesh with the outer edge of every patch of terrain, objective zone and the well's rim and pull rings: a thin line
# and a soft band fading inward, coloured by kind; how strong it shows is the look's terrain_edge
func _terrain_edges() -> void:
	edges = MeshInstance3D.new()
	edges.name = "TerrainEdges"
	var em := LS.material(true)
	edges.material_override = em
	edges.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(edges)
	var groups := {}
	var T: Dictionary = VW.get("terrain", {})
	for k in T:
		var t := str(T[k])
		if t == "hulk" or t == "station":
			t = "rock"
		if EDGE_C.has(t) and index.has(k):
			if not groups.has(t):
				groups[t] = {}
			groups[t][k] = true
	for k in zone_of:
		var z := str(zone_of[k])
		if not groups.has(z):
			groups[z] = {}
		groups[z][k] = true
	var o = VW.get("obj")
	if o is Dictionary and str(o.get("type", "")) == "hold" and o.get("hex") is Dictionary:
		groups["hold"] = {key(o["hex"]["q"], o["hex"]["r"]): true}
	var meta = VW.get("map")
	if well_c != Vector3.INF and meta is Dictionary:
		var wq := int(meta["deadstar"]["q"])
		var wr := int(meta["deadstar"]["r"])
		groups["rim"] = {}
		groups["pull"] = {}
		for h in cells:
			var d := _hdist(h.q, h.r, wq, wr)
			if d <= 3:
				groups["rim"][key(h.q, h.r)] = true
			if d <= 5:
				groups["pull"][key(h.q, h.r)] = true
	# step 2: the natural terrain (nebula, ion storm, debris, rock) gets its own edge mesh, so look C can drop those hex
	# outlines (the gas, wrecks and rocks themselves show where they are) and the tactical grid still brings them back;
	# objective zones and the dead star's rings keep theirs
	gas_edges = MeshInstance3D.new()
	gas_edges.name = "GasEdges"
	gas_edges.material_override = em.duplicate()
	gas_edges.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(gas_edges)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sg := SurfaceTool.new()
	sg.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 0
	var ng := 0
	for g in groups:
		if g == "debris" or g == "rock":
			continue   # issue 1359: solid_edges and cover_edges draw these, in Z and on hover
		if g == "neb" or g == "storm":
			ng += _edge_into(sg, groups[g], EDGE_C[g])
		else:
			n += _edge_into(st, groups[g], EDGE_C[g])
	edges.mesh = st.commit() if n > 0 else null
	gas_edges.mesh = sg.commit() if ng > 0 else null
	hazard_edges = MeshInstance3D.new()
	hazard_edges.name = "HazardEdges"
	hazard_edges.material_override = em.duplicate()
	hazard_edges.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hazard_edges)
	var sz := SurfaceTool.new()
	sz.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nz := 0
	for g in HAZARD_EDGE:
		if groups.has(g):
			nz += _edge_into(sz, groups[g], EDGE_C[g])
	hazard_edges.mesh = sz.commit() if nz > 0 else null
	# Issue 1359: solid ground includes the map's set-piece holes, which are never board cells
	var solid: Dictionary = (groups.get("rock", {}) as Dictionary).duplicate()
	if meta is Dictionary:
		for hole in meta.get("holes", []):
			if str(hole.get("kind", "")) == "deadstar": continue
			for cell in hole.get("cells", []): solid[key(int(cell[0]), int(cell[1]))] = true
	var cover: Dictionary = groups.get("debris", {})
	solid_edges = _edge_mesh(self, "SolidEdges", em, solid, SOLID_EDGE_C)
	cover_edges = _edge_mesh(self, "CoverEdges", em, cover, EDGE_C["debris"])
	hover_edges = Node3D.new()
	hover_edges.name = "HoverEdges"
	add_child(hover_edges)
	_hover_patch = {}
	_hover_shown = null
	for kind in ["solid", "cover"]:
		var keys: Dictionary = solid if kind == "solid" else cover
		for patch in _patches_of(keys):
			var mi := _edge_mesh(hover_edges, kind, em, patch, SOLID_EDGE_C if kind == "solid" else EDGE_C["debris"])
			mi.visible = false
			for k in patch: _hover_patch[k] = mi


# connected groups of hex keys (six neighbours)
func _patches_of(keys: Dictionary) -> Array:
	var out: Array = []
	var seen := {}
	for k0 in keys:
		if seen.has(k0): continue
		var patch := {}
		var todo: Array = [k0]
		seen[k0] = true
		while not todo.is_empty():
			var k: String = str(todo.pop_back())
			patch[k] = true
			var qr: PackedStringArray = k.split(",")
			for d in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, -1], [-1, 1]]:
				var nk := key(int(qr[0]) + int(d[0]), int(qr[1]) + int(d[1]))
				if keys.has(nk) and not seen.has(nk):
					seen[nk] = true
					todo.append(nk)
		out.append(patch)
	return out


# issue 1359: the normal view shows the rim of the solid or debris patch under the cursor only
func _show_hover_edge(raw: String) -> void:
	var mi: MeshInstance3D = _hover_patch.get(raw) if _edge_hover else null
	if mi == _hover_shown: return
	if is_instance_valid(_hover_shown): _hover_shown.visible = false
	_hover_shown = mi
	if mi != null:
		(mi.material_override as ShaderMaterial).set_shader_parameter("gain", float(_hover_gain.get(str(mi.get_meta("edge_kind")), 0.0)))
		mi.visible = fills == null or fills.visible


func _edge_mesh(parent: Node, nm: String, em: ShaderMaterial, keys: Dictionary, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.set_meta("edge_kind", nm)
	mi.material_override = em.duplicate()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	mi.mesh = st.commit() if _edge_into(st, keys, col) > 0 else null
	return mi


# the outer edges of a set of hexes into a SurfaceTool, drawn with the shared line style (render/line_style.gd, issue
# 1374): the line sits just inside the outer hex edge and its glow band runs inward; col is the role's colour and strength
func _edge_into(st: SurfaceTool, keys: Dictionary, col: Color, y := -0.36) -> int:
	var corners: Array = []
	for i in 6:
		var an := deg_to_rad(60.0 * i + 30.0)
		corners.append(Vector3(cos(an), 0, sin(an)))
	var n := 0
	var r0 := HS * 0.97
	for k in keys:
		var qr: PackedStringArray = str(k).split(",")
		var c := hex_world(int(qr[0]), int(qr[1]), y)
		for i in 6:
			var a: Vector3 = corners[i]
			var b: Vector3 = corners[(i + 1) % 6]
			var nb := world_hex(c + (a + b) * 0.5 * HS * 2.0)
			if keys.has(key(nb.x, nb.y)):
				continue
			n += 1
			# toward the centre along the corner spokes, scaled so one unit along them is one unit in from the edge
			LS.strip_into(st, c + a * r0, c + b * r0, -a / 0.8660254, -b / 0.8660254, "edge", col)
	return n


# push the current look into the board's shaders, its colours and the world (gas, debris, the well, the dark floor)
func apply_look(toast := true) -> void:
	if fills == null:
		return
	var sp := BL.spec()
	var g := str(sp["grid"])
	var rm := rings.material_override as ShaderMaterial
	rm.set_shader_parameter("mode", {"today": 0, "holo": 1, "ghost": 2, "tactical": 3}.get(g, 0))
	rm.set_shader_parameter("well", Vector4(well_c.x, well_c.y, well_c.z, 9.0) if (sp["funnel"] and well_c != Vector3.INF) else Vector4.ZERO)
	_edge_gains(sp)
	refresh()
	if is_inside_tree():
		get_tree().call_group("vs_world", "set_look")
	_look_ui(toast)


func _edge_gains(sp: Dictionary) -> void:
	if edges != null:
		_edge_gain = float(sp["terrain_edge"])
		(edges.material_override as ShaderMaterial).set_shader_parameter("gain", _edge_gain)
		edges.visible = _edge_gain > 0.0
	if gas_edges != null:
		_gas_edge_gain = float(sp.get("gas_edge", sp["terrain_edge"]))
		(gas_edges.material_override as ShaderMaterial).set_shader_parameter("gain", _gas_edge_gain)
		gas_edges.visible = _gas_edge_gain > 0.0
	if hazard_edges != null:
		_hazard_edge_gain = float(sp.get("hazard_edge", 0.0))
		(hazard_edges.material_override as ShaderMaterial).set_shader_parameter("gain", _hazard_edge_gain)
		hazard_edges.visible = _hazard_edge_gain > 0.0
	if solid_edges != null:
		_solid_edge_gain = float(sp.get("solid_edge", sp.get("gas_edge", sp["terrain_edge"])))
		(solid_edges.material_override as ShaderMaterial).set_shader_parameter("gain", _solid_edge_gain)
		solid_edges.visible = _solid_edge_gain > 0.0
	if cover_edges != null:
		_cover_edge_gain = float(sp.get("cover_edge", sp.get("gas_edge", sp["terrain_edge"])))
		(cover_edges.material_override as ShaderMaterial).set_shader_parameter("gain", _cover_edge_gain)
		cover_edges.visible = _cover_edge_gain > 0.0
	if fills != null and fills.material_override is ShaderMaterial:
		(fills.material_override as ShaderMaterial).set_shader_parameter("hatch_hidden", 1.0 if bool(sp.get("hatch_hidden", false)) else 0.0)
	_edge_hover = bool(sp.get("edge_hover", false))
	_hover_gain = {"solid": float(sp.get("hover_solid", 0.0)), "cover": float(sp.get("hover_cover", 0.0))}
	if is_instance_valid(_hover_shown): _hover_shown.visible = false
	_hover_shown = null
	_show_hover_edge(_hover_raw)


func _look_ui(toast: bool) -> void:
	if not is_inside_tree():
		return
	if _look_layer == null:
		_look_layer = CanvasLayer.new()
		_look_layer.layer = 5
		add_child(_look_layer)
		_look_btn = Button.new()
		_look_btn.text = "Grid  (Z)"
		_look_btn.toggle_mode = true
		_look_btn.focus_mode = Control.FOCUS_NONE
		_look_btn.tooltip_text = "Show the full tactical grid"
		_look_btn.add_theme_font_size_override("font_size", 18)
		_look_btn.anchor_left = 1.0
		_look_btn.anchor_right = 1.0
		_look_btn.offset_left = -150.0
		_look_btn.offset_right = -18.0
		_look_btn.offset_top = 120.0
		_look_btn.offset_bottom = 160.0
		_look_btn.toggled.connect(func(on: bool) -> void:
			if BL.tactical != on:
				BL.tactical = on
				apply_look(false))
		_look_layer.add_child(_look_btn)
		_toast = Label.new()
		_toast.add_theme_font_size_override("font_size", 26)
		_toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_toast.add_theme_constant_override("outline_size", 6)
		_toast.anchor_left = 0.5
		_toast.anchor_right = 0.5
		_toast.offset_left = -400.0
		_toast.offset_right = 400.0
		_toast.offset_top = 90.0
		_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_toast.visible = false
		_look_layer.add_child(_toast)
	_look_btn.set_pressed_no_signal(BL.tactical)
	_look_btn.visible = BL.current() == "cine"
	if toast:
		_toast.text = "Board look: " + str(BL.NAMES.get(BL.current(), BL.current())) + ("  (F8: next look)" if BL.current() != "cine" else "  (Z: tactical grid, F8: next look)")
		_toast.visible = true
		_toast_t = 3.0


func _process(dt: float) -> void:
	if _toast != null and _toast.visible:
		_toast_t -= dt
		if _toast_t <= 0.0:
			_toast.visible = false
	# the title screen's showcase hides the grid: the edges and the button go with it
	if fills != null:
		if edges != null:
			edges.visible = fills.visible and _edge_gain > 0.0
		if gas_edges != null:
			gas_edges.visible = fills.visible and _gas_edge_gain > 0.0
		if hazard_edges != null:
			hazard_edges.visible = fills.visible and _hazard_edge_gain > 0.0
		if solid_edges != null:
			solid_edges.visible = fills.visible and _solid_edge_gain > 0.0
		if cover_edges != null:
			cover_edges.visible = fills.visible and _cover_edge_gain > 0.0
		if is_instance_valid(_hover_shown):
			_hover_shown.visible = fills.visible
		if _look_layer != null:
			_look_layer.visible = fills.visible


func _unhandled_input(e: InputEvent) -> void:
	if fills == null or not fills.visible:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).keycode
		if k == KEY_F8:
			BL.next()
			apply_look(true)
			get_viewport().set_input_as_handled()
		elif k == KEY_Z and BL.current() == "cine":
			BL.tactical = not BL.tactical
			apply_look(false)
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- terrain props

func _rock_lib() -> Array:
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://gen/manifest.json")) if FileAccess.file_exists("res://gen/manifest.json") else null
	var set_name := "RST"
	var biome = WI.get("biome")
	if biome is Dictionary and HT.ROCK_SET.has(biome.get("rock", "")):
		set_name = HT.ROCK_SET[biome["rock"]]
	var out: Array = []
	if man is Dictionary:
		for code in man["rocks"]:
			if man["rocks"][code]["set"] == set_name:
				out.append(load(man["rocks"][code]["res"]))
	return out


func _terrain() -> void:
	base_fill.clear()
	rock_meshes = _rock_lib()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(WI.get("seed", 1)) if WI.get("seed") != null else 1
	var T: Dictionary = VW.get("terrain", {})
	for k in T:
		var typ: String = T[k]
		var qr: PackedStringArray = k.split(",")
		var q := int(qr[0])
		var r := int(qr[1])
		var c := hex_world(q, r)
		if ZONE_TINT.has(typ):
			base_fill[k] = ZONE_TINT[typ]
		match typ:
			"rock":
				if not props_world:
					_rocks(c, rng, 3 + rng.randi() % 3, 2.5, 6.5)
			"hulk":
				_rocks(c, rng, 2, 1.5, 3.0)
				_hulk(c, rng)
			"debris":
				if not props_world:
					_rocks(c, rng, 5, 0.5, 1.4)
			"station":
				pass
	_planet()
	_beacon()
	# one station structure per cluster of station hexes (the game builds one across the cluster)
	var seen := {}
	for k in T:
		if T[k] != "station" or seen.has(k):
			continue
		var stack := [k]
		var cl: Array = []
		seen[k] = true
		while not stack.is_empty():
			var cur: String = stack.pop_back()
			cl.append(cur)
			var qr: PackedStringArray = cur.split(",")
			for d in [[1, 0], [0, 1], [-1, 1], [-1, 0], [0, -1], [1, -1]]:
				var nk := key(int(qr[0]) + d[0], int(qr[1]) + d[1])
				if T.get(nk, "") == "station" and not seen.has(nk):
					seen[nk] = true
					stack.append(nk)
		var cen := Vector3.ZERO
		var centres: Array[Vector3] = []
		for ck in cl:
			var qr2: PackedStringArray = ck.split(",")
			var p := hex_world(int(qr2[0]), int(qr2[1]))
			centres.append(p)
			cen += p
		cen /= float(cl.size())
		var clearance := HS
		for p in centres:
			clearance = maxf(clearance, cen.distance_to(p) + HS)
		var size := STATION_BIG_LEN if cl.size() >= STATION_BIG_HEXES else STATION_BASE_LEN + STATION_PER_HEX * cl.size()
		var teaching: bool = cl.size() == 3 and VW.get("map", {}).get("stationR", 0) == 1
		_station(cen, rng, size, teaching, clearance)


func _rocks(c: Vector3, rng: RandomNumberGenerator, n: int, s0: float, s1: float) -> void:
	if rock_meshes.is_empty():
		var mi := MeshInstance3D.new()
		mi.mesh = BV.WR.fallback_mesh("board_rock")
		mi.scale = Vector3.ONE * minf(s1, 7.5)
		mi.position = c + Vector3.UP
		props.add_child(mi)
		return
	for i in n:
		var mi := MeshInstance3D.new()
		mi.mesh = rock_meshes[rng.randi() % rock_meshes.size()]
		var s := rng.randf_range(s0, s1)
		var off := Vector3(rng.randf_range(-5.5, 5.5), rng.randf_range(-2.5, 2.5), rng.randf_range(-5.5, 5.5))
		mi.transform = Transform3D(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)).scaled(Vector3.ONE * s), c + off)
		props.add_child(mi)


func _hulk(c: Vector3, rng: RandomNumberGenerator) -> void:
	var codes := ["H8_23", "V15_37", "C14s_23", "D20_23"]
	var code: String = codes[rng.randi() % codes.size()]
	# A4's painted hull, burnt (same random draws as the old path, so the rest of the board does not shift)
	var a4 := A4P.hulk(code)
	if a4 != null:
		a4.transform = Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))).scaled(Vector3.ONE * HULK_SCALE), c)
		props.add_child(a4)
		BV.fit_hulk(a4, c)
		return
	var p := "res://gen/hulls/%s.res" % code
	if not ResourceLoader.exists(p):
		BV.hulk_fallback(props, c, rng)
		return
	var mi := MeshInstance3D.new()
	mi.mesh = load(p)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.09, 0.08, 0.075)
	m.roughness = 0.85
	m.metallic = 0.3
	mi.material_override = m
	mi.transform = Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.6, 0.6))).scaled(Vector3(HULK_SCALE, HULK_SCALE, -HULK_SCALE)), c)
	props.add_child(mi)
	BV.fit_hulk(mi, c)


func _station(c: Vector3, rng: RandomNumberGenerator, size := STATION_BIG_LEN, teaching := false, clearance := 0.0) -> void:
	# The painted station for this cluster size, with the original hull below as a fallback.
	var a4 := A4P.station(size, clearance)
	if a4 != null:
		var bearing := rng.randf() * 6.0
		var attitude := Vector3(0, bearing, 0) if a4.has_meta("station_T2") else Vector3(0.06, bearing, 0.04)
		var offset := Vector3(0, 3, 0)
		if teaching:
			# Bank O1_37 into the triangular cluster at full scale and lift its low edge above the grid.
			attitude = Vector3(deg_to_rad(-63.0), deg_to_rad(65.0), 0.0)
			offset = Vector3(2.0, 13.0, 1.5)
		a4.transform = Transform3D(Basis.from_euler(attitude), c + offset)
		props.add_child(a4)
		return
	var p := "res://gen/hulls/O1_37.res"
	if not ResourceLoader.exists(p):
		return
	# the game's station (ships3d.js buildMeshStation): one structure across the station hexes, 46 long, lifted 3
	var mi := MeshInstance3D.new()
	mi.mesh = load(p)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.36, 0.38, 0.42)
	m.metallic = 0.55
	m.roughness = 0.5
	var src = (mi.mesh as Mesh).surface_get_material(0)
	if src is StandardMaterial3D:
		m.normal_enabled = (src as StandardMaterial3D).normal_enabled
		m.normal_texture = (src as StandardMaterial3D).normal_texture
		m.ao_enabled = (src as StandardMaterial3D).ao_enabled
		m.ao_texture = (src as StandardMaterial3D).ao_texture
		m.ao_texture_channel = (src as StandardMaterial3D).ao_texture_channel
	mi.material_override = m
	mi.transform = Transform3D(Basis.from_euler(Vector3(0.06, rng.randf() * 6.0, 0.04)).scaled(Vector3(size, size, -size)), c + Vector3(0, 3, 0))
	props.add_child(mi)


# Issue 1536 (Ryan, Nov 22 2026, "Yes"): in a Hold battle the Navy relay beacon O3_11 stands under the hold hex, so the gold hex
# reads as the relay the fleets fight over. Picture only: the rules place nothing there and ships still end their moves on
# the hex above it. It sits below the board plane (its top under the grid), so a ship holding the hex floats over it, and its
# lens is turned toward the player's side of the board and tipped up, so the blue rings read from the battle camera.
const BEACON_LEN := 12.0      # O3's length_world 7.5 times the board's ship scale (hull_table SHIP_K 1.6)
const BEACON_TOP := -0.6      # the highest point of the beacon, just under the grid
const BEACON_TILT := 35.0     # degrees the lens is tipped up from level
var beacon_node: Node3D = null


func _beacon() -> void:
	beacon_node = null
	var o = VW.get("obj")
	if not (o is Dictionary and str(o.get("type", "")) == "hold" and o.get("hex") is Dictionary):
		return
	var n := A4P.beacon(BEACON_LEN)
	if n == null:
		return
	# lens (+x) toward +z (the player's side, where the battle camera starts), then tipped up by BEACON_TILT
	var basis := Basis(Vector3.RIGHT, -deg_to_rad(BEACON_TILT)) * Basis(Vector3.UP, -PI / 2.0)
	var top := 0.0
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D(basis, Vector3.ZERO) * _rel_to(mi as Node3D, n)
		var bb: AABB = xf * (mi as MeshInstance3D).get_aabb()
		top = maxf(top, bb.end.y)
	n.transform = Transform3D(basis, hex_world(float(o["hex"]["q"]), float(o["hex"]["r"]), BEACON_TOP - top))
	props.add_child(n)
	beacon_node = n


# a node's transform relative to an ancestor (before either is in the tree)
static func _rel_to(node: Node3D, ancestor: Node) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var p: Node = node
	while p != null and p != ancestor:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


func _planet() -> void:
	var meta = VW.get("map")
	if not (meta is Dictionary) or not meta.has("planet"):
		return
	var pl = meta["planet"]
	if not (pl is Dictionary) or not pl.has("q"):
		return
	# battle.js planetEdge: R * 1.5 * HEX_S + HEX_S / 2
	var rad: float = float(pl.get("R", PLANET_R_DEFAULT)) * PLANET_EDGE_K * HS + HS * 0.5 if pl.has("R") else 40.0
	var sp := SphereMesh.new()
	sp.radius = rad
	sp.height = rad * 2.0
	sp.radial_segments = 96
	sp.rings = 48
	var mi := MeshInstance3D.new()
	mi.mesh = sp
	# Keep the map's radius and sink 78% of it. At radius 50: centre -39, cap 11, board-plane chord about 63.
	mi.position = hex_world(pl.q, pl.r, -rad * 0.78)
	props.add_child(mi)
	planet_node = mi
	# the campaign map's planet look (G3's map3d_shaders.gd PLANET and ATMO, which Ryan has seen on the map): surface
	# detail per kind, a night side away from the battle's key light, a thin lit limb; the flat matte ball only if the
	# shaders are missing from the build
	var MS = load("res://ui/campaign/map3d_shaders.gd") if ResourceLoader.exists("res://ui/campaign/map3d_shaders.gd") else null
	if MS == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.33, 0.29, 0.27)
		m.roughness = 0.95
		mi.material_override = m
		return
	var seed_v := int(WI.get("seed", 1)) if WI.get("seed") != null else 1
	var look: Array = PLANET_LOOKS[posmod(seed_v, PLANET_LOOKS.size())]
	var sun := mi.position + sun_dir.normalized() * 100000.0
	var pm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = MS.PLANET
	pm.shader = sh
	pm.set_shader_parameter("kind", float(look[0]))
	pm.set_shader_parameter("a", look[1])
	pm.set_shader_parameter("b", look[2])
	pm.set_shader_parameter("atmo", look[3])
	pm.set_shader_parameter("seed", float(posmod(seed_v, 97)) * 1.37)
	pm.set_shader_parameter("sun_pos", sun)
	pm.set_shader_parameter("q", 1.0)
	mi.material_override = pm
	var shell := MeshInstance3D.new()
	var ss := SphereMesh.new()
	ss.radius = rad * 1.03
	ss.height = rad * 2.06
	ss.radial_segments = 96
	ss.rings = 48
	shell.mesh = ss
	var am := ShaderMaterial.new()
	var ash := Shader.new()
	ash.code = MS.ATMO
	am.shader = ash
	am.set_shader_parameter("atmo", look[3])
	am.set_shader_parameter("sun_pos", sun)
	am.set_shader_parameter("gain", 1.0)
	shell.material_override = am
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shell.position = mi.position
	props.add_child(shell)


# issue 1236: a dead cruiser or capital's hex became a wreck in the rules ("wreck" event). The board marks it as it marks
# a wreck the map started with: the hex joins the blocked terrain (its edge shows with the grid, Z, as every rock and
# hulk hex does), with the same scatter of torn rock and plate, and the ship's own pieces settle inside it (fx_death
# _leash). hull: also lay the map's burnt hulk there, for a death that left no pieces (or a battle without the effects).
func add_wreck(id: String, q: int, r: int, hull := false) -> void:
	var k := key(q, r)
	if not index.has(k):
		return
	var T: Dictionary = VW.get("terrain", {}) if VW.get("terrain") is Dictionary else {}
	VW["terrain"] = T
	var fresh := not wrecks.has(id)
	wrecks[id] = k
	T[k] = "hulk"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("wreck|%s|%s" % [id, k])
	var c := hex_world(q, r)
	if fresh:
		_rocks(c, rng, 2, 1.5, 3.0)
	if hull and not wreck_hulls.has(id):
		wreck_hulls[id] = true
		_hulk(c, rng)
	if fresh:
		_rebuild_edges()


func _rebuild_edges() -> void:
	for n in [edges, gas_edges, hazard_edges, solid_edges, cover_edges, hover_edges]:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_terrain_edges()
	_edge_gains(BL.spec())


func show_blockers(hexes: Array) -> void:
	if not is_instance_valid(blocker_highlights): return
	for child in blocker_highlights.get_children():
		blocker_highlights.remove_child(child)
		child.queue_free()
	for h in hexes:
		BV.outline(blocker_highlights, hex_world(h.q, h.r), LS.ROLE["blocker"], 0.9)
