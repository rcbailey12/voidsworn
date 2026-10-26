extends Control
# The 3D sector map (G3, first pass; FINDINGS R36): the sector as a star chart in depth instead of flat icons.
# Presentation only: it reads the campaign state and calls campaign.act("enterNode", id) like any button, so the bot,
# the parity test and the rules never see it.
#
# - A camera looking down the sector at an angle, drifting slowly; the enemy faction's nebula sky and the sector's dead star
#   behind it (G4's world.gd: sky() and dead_star()).
# - Nodes as small 3D objects by type (battle, elite, shipyard, drydock, field repairs, unknown signal, sector flagship),
#   dimmed once passed; lanes that glow and flow when you can jump along them, gold where you have flown.
# - Your fleet as a token that flies along the lane when you jump (the jump happens when it arrives).
# - Hover a node for a card with the encounter detail; the faction's territory tints the far end of the sector, and
#   rival raider nodes carry their own faction's ring.
# - Labels (encounter, field, patron sigil) are drawn in 2D over the 3D view, so they stay crisp.

const World := preload("res://world/world.gd")

var ui                        # campaign_ui.gd
var vpc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var env: Environment
var world: Node3D
var root3: Node3D             # rebuilt when the sector changes
var token: Node3D
var overlay: Control
var card: PanelContainer
var card_text: RichTextLabel
var _sig := ""                # which sector map is built
var _nodes := {}              # id -> {n, pos, obj, ring, mats}
var _lanes: Array = []        # [a, b, mesh, mat]
var _hot := ""
var _focus := 0
var _t := 0.0
var _flying := false
var _side_w := 380.0
var _lane_shader: Shader
var _terr_shader: Shader

const LANE_SH := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 col : source_color = vec4(1.0);
uniform float flow = 0.0;
void fragment() {
	float d = step(0.5, fract(UV.y * 9.0 - TIME * 1.4));
	ALBEDO = col.rgb;
	ALPHA = col.a * mix(1.0, 0.35 + 0.65 * d, flow);
}
"""
const TERR_SH := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 col : source_color = vec4(1.0);
uniform vec2 focus = vec2(0.8, 0.5);
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p) { vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	vec2 uv = UV;
	float r = distance(uv * vec2(1.6, 1.0), focus * vec2(1.6, 1.0));
	float g = smoothstep(0.95, 0.0, r);
	float c = n(uv * 6.0 + TIME * 0.01) * 0.6 + n(uv * 15.0 - TIME * 0.015) * 0.4;
	float edge = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x) * smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
	ALBEDO = col.rgb;
	ALPHA = col.a * g * (0.45 + 0.55 * c) * edge;
}
"""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	vpc = SubViewportContainer.new(); vpc.stretch = true; vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(vpc)
	vp = SubViewport.new(); vp.own_world_3d = true; vp.msaa_3d = Viewport.MSAA_4X; vpc.add_child(vp)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.02, 0.03, 0.05)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_bloom = 0.04; env.glow_hdr_threshold = 1.1
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.35, 0.4, 0.5); env.ambient_light_energy = 0.6
	var we = WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_energy = 1.1; vp.add_child(sun)
	cam = Camera3D.new(); cam.fov = 38.0; cam.far = 4000.0; vp.add_child(cam)
	world = World.new(); vp.add_child(world)
	_lane_shader = Shader.new(); _lane_shader.code = LANE_SH
	_terr_shader = Shader.new(); _terr_shader.code = TERR_SH
	overlay = Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; overlay.draw.connect(_draw_overlay); add_child(overlay)
	card = PanelContainer.new(); card.visible = false; card.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(card)
	card_text = RichTextLabel.new(); card_text.bbcode_enabled = true; card_text.fit_content = true; card_text.scroll_active = false; card_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_text)

# ---------------- building the sector ----------------
func _C(): return ui.C
func _pos(n: Dictionary) -> Vector3:
	return Vector3((float(n["col"]) - 3.0) * 10.5, 0.0, (float(n["y"]) - 0.5) * 30.0)
func sync() -> void:
	var C = _C()
	if C == null or C.RUN == null: return
	var m = C.RUN["map"]
	var sig = str(C.RUN["sector"]) + "|" + str(m.get("fac")) + "|" + str(m["edges"].hash())
	if sig != _sig: _build(sig)
	_refresh()
func _mat(col: Color, emit: float, metal: float = 0.3, rough: float = 0.5) -> StandardMaterial3D:
	var mt = StandardMaterial3D.new(); mt.albedo_color = col; mt.metallic = metal; mt.roughness = rough
	if emit > 0: mt.emission_enabled = true; mt.emission = col; mt.emission_energy_multiplier = emit
	mt.set_meta("e0", emit); mt.set_meta("c0", col)
	return mt
func _mi(mesh: Mesh, mat: Material, at: Vector3 = Vector3.ZERO, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = at; mi.scale = sc
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; return mi
func _sphere(r: float, seg: int = 24, rings: int = 12) -> SphereMesh:
	var s = SphereMesh.new(); s.radius = r; s.height = r * 2.0; s.radial_segments = seg; s.rings = rings; return s
func _torus(r0: float, r1: float) -> TorusMesh:
	var t = TorusMesh.new(); t.inner_radius = r0; t.outer_radius = r1; t.rings = 48; t.ring_segments = 8; return t
func _build(sig: String) -> void:
	_sig = sig
	var C = _C(); var m = C.RUN["map"]; var fac = m.get("fac", "hegemony")
	if root3 != null: root3.queue_free()
	for ch in world.get_children(): ch.queue_free()
	root3 = Node3D.new(); vp.add_child(root3)
	_nodes.clear(); _lanes.clear()
	# backdrop: the enemy faction's nebula, the sector's dead star far behind the chart (G4 world.gd)
	world.quality = "low"   # no lens: it bends the chart in front of the star too
	world.sky(env, fac, null, int(C.RUN["sector"]) * 13 + str(m.get("region", "")).length())
	world.dead_star(Vector3(-40.0, -125.0, -310.0), 1.1)
	# faction territory: a soft tint over the far end of the sector, round the flagship
	var glow = Color(C.FACTIONS[fac].get("glow", "#e07a70")) if C.FACTIONS.has(fac) else Color("#e07a70")
	var terr = _mi(_plane(110, 60), _shader_mat(_terr_shader, {"col": Color(glow, 0.55), "focus": Vector2(0.86, 0.5)}), Vector3(0, -0.6, 0))
	root3.add_child(terr)
	# a faint chart grid under the lanes
	var grid = _mi(_plane(110, 60), _grid_mat(), Vector3(0, -0.7, 0)); root3.add_child(grid)
	for col in m["cols"]:
		for n in col: _add_node(n)
	for e in m["edges"]: _add_lane(e[0], e[1])
	token = _make_token(); root3.add_child(token)
	var C2 = _C()
	token.position = _token_home()
	_focus = 0
func _plane(w: float, d: float) -> PlaneMesh:
	var p = PlaneMesh.new(); p.size = Vector2(w, d); return p
func _shader_mat(sh: Shader, params: Dictionary) -> ShaderMaterial:
	var m = ShaderMaterial.new(); m.shader = sh
	for k in params: m.set_shader_parameter(k, params[k])
	return m
func _grid_mat() -> ShaderMaterial:
	var sh = Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	vec2 g = abs(fract(UV * vec2(22.0, 12.0)) - 0.5);
	float l = smoothstep(0.47, 0.5, max(g.x, g.y));
	float e = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x) * smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);
	ALBEDO = vec3(0.55, 0.62, 0.8);
	ALPHA = l * e * 0.07;
}
"""
	var m = ShaderMaterial.new(); m.shader = sh; return m
func _add_node(n: Dictionary) -> void:
	var C = _C(); var p = _pos(n); var obj = Node3D.new(); obj.position = p; root3.add_child(obj)
	var t = n["type"]; var mats = []
	var red = Color("#e05a4a"); var gold = Color("#d0a64b"); var teal = Color("#5fb3a6"); var cyan = Color("#62ccff")
	match t:
		"battle":
			var m1 = _mat(red, 1.1, 0.2, 0.4); mats.append(m1)
			obj.add_child(_mi(_sphere(0.85, 4, 2), m1, Vector3(0, 1.2, 0)))
		"elite":
			var m2 = _mat(Color("#ff4a3a"), 1.5, 0.2, 0.4); mats.append(m2)
			obj.add_child(_mi(_sphere(1.15, 4, 2), m2, Vector3(0, 1.5, 0)))
			var m2b = _mat(gold, 1.4); mats.append(m2b)
			var rr = _mi(_torus(1.55, 1.7), m2b, Vector3(0, 1.5, 0)); rr.rotation_degrees = Vector3(70, 0, 20); rr.name = "spin"; obj.add_child(rr)
		"boss":
			var m3 = _mat(Color(0.06, 0.03, 0.03), 0.0, 0.8, 0.3); mats.append(m3)
			obj.add_child(_mi(_sphere(2.1), m3, Vector3(0, 2.3, 0)))
			var m3b = _mat(Color("#ff3a2a"), 2.2); mats.append(m3b)
			var cr = _mi(_torus(2.6, 2.9), m3b, Vector3(0, 2.3, 0)); cr.rotation_degrees = Vector3(78, 0, 0); cr.name = "spin"; obj.add_child(cr)
			var l = OmniLight3D.new(); l.light_color = Color("#ff4a2a"); l.light_energy = 2.0; l.omni_range = 9.0; l.position = Vector3(0, 2.3, 0); obj.add_child(l)
		"shipyard":
			var m4 = _mat(Color(0.55, 0.52, 0.48), 0.0, 0.7, 0.35); var m4b = _mat(gold, 1.6); mats.append(m4); mats.append(m4b)
			var ring = _mi(_torus(0.9, 1.25), m4, Vector3(0, 1.2, 0)); ring.rotation_degrees = Vector3(25, 0, 0); ring.name = "spin"; obj.add_child(ring)
			var hub = CylinderMesh.new(); hub.top_radius = 0.25; hub.bottom_radius = 0.25; hub.height = 1.6
			obj.add_child(_mi(hub, m4b, Vector3(0, 1.2, 0)))
		"drydock":
			var m5 = _mat(Color(0.5, 0.52, 0.55), 0.0, 0.7, 0.4); var m5b = _mat(teal, 1.6); mats.append(m5); mats.append(m5b)
			var bx = BoxMesh.new(); bx.size = Vector3(0.25, 1.6, 1.8)
			obj.add_child(_mi(bx, m5, Vector3(-0.7, 1.2, 0))); obj.add_child(_mi(bx, m5, Vector3(0.7, 1.2, 0)))
			var bar = BoxMesh.new(); bar.size = Vector3(1.6, 0.18, 0.18)
			obj.add_child(_mi(bar, m5b, Vector3(0, 2.0, 0.7))); obj.add_child(_mi(bar, m5b, Vector3(0, 2.0, -0.7)))
		"field":
			var m6 = _mat(Color("#7ddc6a"), 1.3); mats.append(m6)
			var sw = Node3D.new(); sw.name = "spin"; sw.position = Vector3(0, 1.2, 0); obj.add_child(sw)
			for i in 3:
				var bx2 = BoxMesh.new(); bx2.size = Vector3(0.36, 0.36, 0.36)
				sw.add_child(_mi(bx2, m6, Vector3(cos(i * TAU / 3.0), 0, sin(i * TAU / 3.0)) * 0.7))
		"event":
			var m7 = _mat(cyan, 1.4, 0.0, 0.2); mats.append(m7)
			obj.add_child(_mi(_sphere(0.6), m7, Vector3(0, 1.3, 0)))
			var m7b = _mat(cyan, 0.9); mats.append(m7b)
			var er = _mi(_torus(0.95, 1.02), m7b, Vector3(0, 1.3, 0)); er.name = "spin"; er.rotation_degrees = Vector3(60, 0, 30); obj.add_child(er)
	# the ring on the chart: gold when you can jump there, the rival's colour on a raider node
	var rmat = StandardMaterial3D.new(); rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; rmat.albedo_color = Color(1, 1, 1, 0.2)
	var big = 2.6 if t == "boss" else (1.9 if t == "elite" else 1.5)
	var ring2 = _mi(_torus(big, big + 0.18), rmat, Vector3(0, 0.05, 0)); obj.add_child(ring2)
	var rival = null
	if t == "battle" and C.RUN.get("foes") != null:
		var f = C.nodeFaction(n)
		if f != C.RUN["map"]["fac"] and C.FACTIONS.has(f): rival = Color(C.FACTIONS[f].get("glow", "#ffffff"))
	if rival != null:
		var rm = StandardMaterial3D.new(); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rm.albedo_color = rival
		obj.add_child(_mi(_torus(big + 0.35, big + 0.45), rm, Vector3(0, 0.05, 0)))
	_nodes[n["id"]] = {"n": n, "pos": p, "obj": obj, "ring": ring2, "rmat": rmat, "mats": mats, "top": 2.6 if t == "boss" else 1.6}
func _add_lane(a: String, b: String) -> void:
	var A = _nodes[a]["pos"]; var B = _nodes[b]["pos"]; var d = B - A
	var cyl = CylinderMesh.new(); cyl.top_radius = 0.09; cyl.bottom_radius = 0.09; cyl.height = d.length(); cyl.radial_segments = 6; cyl.rings = 1
	var mat = _shader_mat(_lane_shader, {"col": Color(0.9, 0.86, 0.77, 0.12), "flow": 0.0})
	var mi = _mi(cyl, mat, (A + B) * 0.5 + Vector3(0, 0.15, 0))
	mi.look_at_from_position(mi.position, B + Vector3(0, 0.15, 0), Vector3.UP); mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	root3.add_child(mi)
	_lanes.append([a, b, mi, mat])
func _make_token() -> Node3D:
	var t = Node3D.new()
	var hull = PrismMesh.new(); hull.size = Vector3(0.9, 2.2, 0.35)
	var hm = _mat(Color(0.82, 0.74, 0.58), 0.4, 0.8, 0.3)
	var h = _mi(hull, hm); h.rotation_degrees = Vector3(0, 0, -90); t.add_child(h)   # the bow points along +x, toward the flagship
	var eng = _mi(_sphere(0.28), _mat(Color("#ffa24a"), 6.0), Vector3(-1.15, 0, 0)); t.add_child(eng)
	var l = OmniLight3D.new(); l.light_color = Color("#ffb060"); l.light_energy = 1.5; l.omni_range = 4.0; l.position = Vector3(-1.2, 0, 0); t.add_child(l)
	return t
func _token_home() -> Vector3:
	var C = _C(); var pos = C.RUN.get("pos")
	if pos != null and _nodes.has(pos): return _nodes[pos]["pos"] + Vector3(0, _nodes[pos]["top"] + 1.4, 0)
	var first = C.RUN["map"]["cols"][0][0]
	return _pos(first) + Vector3(-5.5, 2.6, 0)

# ---------------- state ----------------
func _avail() -> Array:
	var C = _C()
	return C.page["data"]["avail"] if C.page["kind"] == "map" else []
func _refresh() -> void:
	var C = _C(); var R = C.RUN; var av = _avail()
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		for m in d["mats"]:   # a passed node goes dark and grey
			var c0: Color = m.get_meta("c0"); var e0: float = m.get_meta("e0")
			m.albedo_color = c0.lerp(Color(0.28, 0.28, 0.3), 0.75) if done else c0
			if m.emission_enabled: m.emission_energy_multiplier = e0 * (0.08 if done else 1.0)
		var cur = R.get("pos") == id
		d["rmat"].albedo_color = Color("#d0a64b") if cur else (Color(0.82, 0.65, 0.29, 0.85) if av.has(id) else Color(0.9, 0.86, 0.77, 0.1 if done else 0.18))
	for L in _lanes:
		var A = _nodes[L[0]]["n"]; var Bn = _nodes[L[1]]["n"]
		var trav = C.jt(A.get("done")) and (C.jt(Bn.get("done")) or R.get("pos") == L[1])
		var nxt = (R.get("pos") == L[0] or (R.get("pos") == null and false)) and av.has(L[1])
		L[3].set_shader_parameter("col", Color(0.82, 0.65, 0.29, 0.9) if trav else (Color(0.95, 0.75, 0.35, 0.95) if nxt else Color(0.9, 0.86, 0.77, 0.12)))
		L[3].set_shader_parameter("flow", 1.0 if nxt else 0.0)
	if not _flying and token != null: token.position = _token_home()
	overlay.queue_redraw()

func _process(delta: float) -> void:
	if not visible or _C() == null or _C().RUN == null or root3 == null: return
	_t += delta
	# a slow drift, and a little parallax from the mouse
	var mp = get_local_mouse_position() / size.max(Vector2.ONE) - Vector2(0.5, 0.5)
	# fit the whole chart (about 78 units wide with its labels) into the space left of the side panel, and centre it there
	var aspect = size.x / max(1.0, size.y); var free = clamp((size.x - ui.px(_side_w)) / max(1.0, size.x), 0.4, 1.0)
	var tanh = tan(deg_to_rad(cam.fov * 0.5)); var dist = max(60.0, 80.0 / free / (2.0 * tanh * aspect))
	var shift = (1.0 - free) * 0.5 * (2.0 * dist * tanh * aspect)
	var drift = Vector3(sin(_t * 0.05) * 2.5, sin(_t * 0.037) * 0.8, cos(_t * 0.043) * 1.5)
	var target = Vector3(shift, 0, 0.5)
	cam.position = target + Vector3(0, dist * 0.62, dist * 0.78) + drift + Vector3(mp.x * 2.5, -mp.y * 1.5, 0)
	cam.look_at(target, Vector3.UP)
	for id in _nodes:
		var o = _nodes[id]["obj"]
		var sp = o.get_node_or_null("spin")
		if sp != null: sp.rotate_y(delta * 0.6)
		var av = _avail().has(id)
		var ring = _nodes[id]["ring"]
		var k = 1.0 + (0.08 * sin(_t * 2.6) if av else 0.0) + (0.12 if id == _hot else 0.0)
		ring.scale = Vector3(k, 1, k)
	if token != null and not _flying: token.position.y = _token_home().y + sin(_t * 1.4) * 0.25
	overlay.queue_redraw()
	_update_card()

# ---------------- labels and the hover card ----------------
func _screen(p: Vector3) -> Vector2: return cam.unproject_position(p)
func _draw_overlay() -> void:
	var C = _C()
	if C == null or C.RUN == null or root3 == null: return
	var av = _avail(); var f = ui.font
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		if cam.is_position_behind(d["pos"]): continue
		var base = _screen(d["pos"]); var top = _screen(d["pos"] + Vector3(0, d["top"] + 1.2, 0))
		var s = clamp(ui.k * 1.0, 0.6, 2.0); var fs = int(14 * s)
		var fight = n["type"] == "battle" or n["type"] == "elite" or n["type"] == "boss"
		var col = ui.BONE if av.has(id) else Color(0.62, 0.6, 0.55)
		if done: col = Color(0.45, 0.44, 0.42)
		var y = base.y + 26.0 * s
		var name = ""
		if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]) and not done:
			name = str(C.ENCOUNTERS[n["enc"]]["n"]) + ((" · " + str(C.NODE_MODS[n["mod"]]["short"])) if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]) else "")
		elif not fight: name = str(C.NODE_INFO[n["type"]]["n"])
		elif n["type"] == "boss": name = "Sector flagship"
		if name != "": _text(name, Vector2(base.x, y), fs, col); y += 16.0 * s
		if fight and C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]) and not done: _text(str(C.MAP_NAME[n["map"]]).to_upper(), top + Vector2(0, -4), int(10 * s), Color(0.5, 0.58, 0.68))
		var rw = n.get("rw")
		if rw is Dictionary and not done:
			if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")):
				var P = C.PATRONS[rw["p"]]; var pc = Color(P["col"]); var bp = top + Vector2(18.0 * s, 10.0 * s)
				overlay.draw_circle(bp, 9.0 * s, pc); overlay.draw_arc(bp, 9.0 * s, 0, TAU, 24, ui.INK, 2.0 * s, true)
				_text(str(P["glyph"]), bp + Vector2(0, 4.5 * s), int(12 * s), ui.INK, ui.font_semi)
				_text(str(P["short"]) + (" ★" if C.jt(rw.get("min")) else ""), Vector2(base.x, y), int(12 * s), pc if av.has(id) else Color(0.5, 0.48, 0.44))
			else:
				var lab = ui._reward_label(rw)
				if lab != "": _text(lab, Vector2(base.x, y), int(12 * s), Color("#bfb6a0") if av.has(id) else Color("#6f6a5e"))
	if has_focus() and av.size() > 0:
		var fid = av[_focus % av.size()]
		var fp = _screen(_nodes[fid]["pos"]); overlay.draw_arc(fp, 30.0 * ui.k, 0, TAU, 40, ui.GILT, 2.0, true)
func _text(t: String, at: Vector2, size: int, col: Color, fnt: Font = null) -> void:
	var f = fnt if fnt != null else ui.font
	var w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	overlay.draw_string(f, Vector2(at.x - w * 0.5 + 1, at.y + 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.7))
	overlay.draw_string(f, Vector2(at.x - w * 0.5, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
func _node_at(sp: Vector2) -> String:
	var best = ""; var bd = 1e9
	for id in _nodes:
		var d = _nodes[id]
		if cam.is_position_behind(d["pos"]): continue
		var c = _screen(d["pos"] + Vector3(0, d["top"] * 0.6, 0)); var r = 34.0 * ui.k * (1.4 if d["n"]["type"] == "boss" else 1.0)
		var dd = sp.distance_to(c)
		if dd < r and dd < bd: bd = dd; best = id
	return best
func _update_card() -> void:
	if _hot == "" or _flying:
		card.visible = false; return
	var C = _C(); var n = C.findNode(_hot)
	if n == null: card.visible = false; return
	card.add_theme_stylebox_override("panel", ui._sb(Color(0.04, 0.06, 0.1, 0.94), Color(ui.GILT, 0.55), 1, 3, 10))
	card_text.add_theme_font_size_override("normal_font_size", ui.px(15)); card_text.add_theme_font_size_override("bold_font_size", ui.px(15))
	card_text.custom_minimum_size.x = ui.px(330)
	card_text.text = _card_bb(n)
	card.visible = true; card.reset_size()
	var mp = get_local_mouse_position() + Vector2(ui.px(22), ui.px(14))
	if mp.x + card.size.x > size.x - ui.px(_side_w): mp.x = get_local_mouse_position().x - card.size.x - ui.px(16)
	mp.y = min(mp.y, size.y - card.size.y - 8)
	card.position = mp
func _card_bb(n: Dictionary) -> String:
	var C = _C(); var I = C.NODE_INFO[n["type"]]; var c = func(t, col): return "[color=" + ui.hexs(col) + "]" + t + "[/color]"
	var fight = n["type"] == "battle" or n["type"] == "elite" or n["type"] == "boss"
	var t = "[b]" + c.call(str(I["n"]).to_upper(), ui.BLOOD if n["type"] in ["elite", "boss"] else ui.GILT) + "[/b]"
	if fight and C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]): t += "  " + c.call(str(C.MAP_NAME[n["map"]]), ui.BONE3)
	if C.jt(n.get("done")): t += "  " + c.call("(passed)", ui.BONE3)
	if fight:
		var fac = C.nodeFaction(n)
		if C.FACTIONS.has(fac): t += "\n" + c.call(ui.esc(C.FACTIONS[fac]["n"]), Color(C.FACTIONS[fac].get("glow", "#e07a70")))
	if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]):
		var E = C.ENCOUNTERS[n["enc"]]
		t += "\n[b]" + ui.esc(E["n"]) + "[/b]" + ((" " + c.call("· " + str(C.SHAPES[n["shape"]]).to_lower(), ui.BONE3)) if C.jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]) else "")
		t += "\n" + c.call(ui.esc(E["d"]), ui.BONE2)
	elif n["type"] == "boss": t += "\n" + c.call("The sector’s command ship and its escort.", ui.BONE2)
	else: t += "\n" + c.call(ui.esc(I["d"]), ui.BONE2)
	if fight:
		var al = ui._arch_label(n, C.nodeFaction(n))
		if al != "": t += "\n" + c.call(ui.esc(al) + ": " + ui.esc(C.ARCHETYPES[C.effArch(n["arch"], C.nodeFaction(n))]["d"]), ui.BLOOD)
	if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): t += "\n" + c.call(ui.esc(C.NODE_MODS[n["mod"]]["n"]) + ": " + ui.esc(C.NODE_MODS[n["mod"]]["d"]), ui.GILT)
	var rw = n.get("rw")
	if rw is Dictionary and not C.jt(n.get("done")):
		var rc = Color(C.PATRONS[rw["p"]]["col"]) if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")) else ui.BONE2
		t += "\n" + c.call("Reward: " + ui._reward_label(rw) + (" (rare or better)" if C.jt(rw.get("min")) else ""), rc)
	if _avail().has(n["id"]): t += "\n" + c.call("Click to jump here.", ui.BONE3)
	return t

# ---------------- input: hover, click (the fleet flies, then the jump), keys ----------------
func _gui_input(e: InputEvent) -> void:
	if _flying: return
	if e is InputEventMouseMotion:
		var h = _node_at(e.position)
		if h != _hot:
			_hot = h; mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _avail().has(h) else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id = _node_at(e.position)
		if id != "" and _avail().has(id): accept_event(); fly_to(id)
	elif e is InputEventKey and e.pressed:
		var av = _avail()
		if av.is_empty(): return
		if e.keycode in [KEY_RIGHT, KEY_DOWN, KEY_TAB]: _focus = (_focus + 1) % av.size(); accept_event()
		elif e.keycode in [KEY_LEFT, KEY_UP]: _focus = (_focus - 1 + av.size()) % av.size(); accept_event()
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]: accept_event(); fly_to(av[_focus % av.size()])
func fly_to(id: String) -> void:
	if _flying or not _nodes.has(id): return
	_flying = true; card.visible = false
	var a = token.position; var b = _nodes[id]["pos"] + Vector3(0, _nodes[id]["top"] + 1.4, 0)
	token.look_at(token.position + (b - a).normalized(), Vector3.UP); token.rotate_object_local(Vector3.UP, PI * 0.5)
	var tw = create_tween(); tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(f): token.position = a.lerp(b, f) + Vector3(0, sin(f * PI) * 2.0, 0), 0.0, 1.0, 0.85)
	tw.tween_callback(func(): _flying = false; token.rotation = Vector3.ZERO; _C().act("enterNode", id))
