extends Control
# The 3D sector map (G3; R36 first pass, R38 round 2): the sector as a star chart in depth, useful first.
# Presentation only: it reads the campaign state and calls campaign.act("enterNode", id) like any button, so the bot, the
# parity test and the rules never see it. Its own randomness (patrol drift, rock shapes) uses a local generator, never the
# rules' random numbers.
#
# Useful:
# - Route planner: hover a node and the safest and the richest routes through it to the sector flagship light up, with a
#   running total at each stop (fights so far, repair stops) and the totals in the card (map_intel.gd).
# - Node intel: each fight shows a danger band for your fleet as it is now (Easy, Even, Hard, Deadly; map_intel.gd uses the
#   game's own fleet budget numbers), its fight type and board shape, and its reward.
# - A warning in the card when your fleet is hurt and the route has no repair stop before the flagship.
# Detailed:
# - Nodes are small scenes by place: a planet with an orbit for a planet edge, a station for an orbital station, an asteroid
#   cluster for a belt, a derelict hulk for a graveyard, a nebula wisp for an ion storm or an unknown signal; the sector
#   flagship node is the enemy flagship hull at small scale; shipyards are a station, drydocks a gantry, repairs drones.
# - Enemy patrols drift where rival raiders can strike; lanes carry travel pulses and hazard marks into elites and the
#   flagship; your fleet token is your flagship hull; the camera leans in when you pick a node and settles on arrival.
# Hull models come from G2's render/ship_view.gd (the PC's gen/ assets); without them a simple shape stands in.

const World := preload("res://world/world.gd")
const Intel := preload("res://ui/campaign/map_intel.gd")
const SHIP_VIEW := "res://render/ship_view.gd"
const HT_PATH := "res://render/hull_table.gd"

var ui                        # campaign_ui.gd
var intel
var vpc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var env: Environment
var world: Node3D
var root3: Node3D
var token: Node3D
var overlay: Control
var card: PanelContainer
var card_text: RichTextLabel
var _sig := ""
var _nodes := {}              # id -> {n, pos, obj, ring, rmat, mats, top}
var _lanes := {}              # "a>b" -> {a, b, mi, mat, hazard}
var _patrols: Array = []      # [node, center, radius, speed, phase]
var _hot := ""
var _routes: Array = []       # routes through the hovered node (map_intel.routes_through)
var _danger := {}             # id -> danger dict (cached per refresh)
var _focus := 0
var _t := 0.0
var _flying := false
var _side_w := 380.0
var _lane_shader: Shader
var _terr_shader: Shader
var _rng := RandomNumberGenerator.new()
var _cam_focus := Vector3.ZERO   # where the camera leans (eased); zero = the whole chart
var _cam_zoom := 1.0             # 1 = the whole chart; smaller = closer
var _arrive_t := 0.0
var _last_pos = null

const LANE_SH := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 col : source_color = vec4(1.0);
uniform float flow = 0.0;
uniform float hazard = 0.0;
uniform float pulse = 0.0;
void fragment() {
	float d = step(0.5, fract(UV.y * 9.0 - TIME * 1.4));
	float a = col.a * mix(1.0, 0.35 + 0.65 * d, flow);
	// a travel pulse running along every lane, slowly
	float p = smoothstep(0.06, 0.0, abs(fract(UV.y * 1.0 - TIME * 0.18) - 0.5)) * pulse;
	vec3 c = col.rgb + vec3(1.0, 0.85, 0.6) * p * 0.6;
	// hazard: red chevron stripes near the far end
	float hz = hazard * step(0.6, UV.y) * step(0.5, fract(UV.y * 22.0 + UV.x * 0.0 - TIME * 0.5));
	c = mix(c, vec3(1.0, 0.25, 0.18), hz * 0.85);
	ALBEDO = c;
	ALPHA = clamp(a + p * 0.35 + hz * 0.4, 0.0, 1.0);
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
	float g = smoothstep(0.75, 0.0, r);
	float c = n(uv * 6.0 + TIME * 0.01) * 0.6 + n(uv * 15.0 - TIME * 0.015) * 0.4;
	float edge = smoothstep(0.0, 0.12, uv.x) * smoothstep(1.0, 0.88, uv.x) * smoothstep(0.0, 0.15, uv.y) * smoothstep(1.0, 0.85, uv.y);
	ALBEDO = col.rgb;
	ALPHA = col.a * g * (0.45 + 0.55 * c) * edge;
}
"""
const GRID_SH := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	vec2 g = abs(fract(UV * vec2(22.0, 12.0)) - 0.5);
	float l = smoothstep(0.485, 0.5, max(g.x, g.y));
	float e = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x) * smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.75, UV.y);
	ALBEDO = vec3(0.45, 0.52, 0.68);
	ALPHA = l * e * 0.022;
}
"""
const PLANET_SH := """
shader_type spatial;
uniform vec3 a : source_color = vec3(0.5, 0.4, 0.3);
uniform vec3 b : source_color = vec3(0.2, 0.15, 0.1);
uniform vec3 atmo : source_color = vec3(0.5, 0.7, 1.0);
float h(vec3 p) { return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453); }
float n(vec3 p) { vec3 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h(i), h(i + vec3(1,0,0)), f.x), mix(h(i + vec3(0,1,0)), h(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h(i + vec3(0,0,1)), h(i + vec3(1,0,1)), f.x), mix(h(i + vec3(0,1,1)), h(i + vec3(1,1,1)), f.x), f.y), f.z); }
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float v = n(lp * 3.0) * 0.6 + n(lp * 7.0) * 0.3 + n(vec3(lp.y * 9.0)) * 0.1;
	ALBEDO = mix(b, a, smoothstep(0.3, 0.7, v));
	ROUGHNESS = 0.8;
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = atmo * fr * 0.8;
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
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.glow_enabled = true; env.glow_intensity = 0.5; env.glow_bloom = 0.03; env.glow_hdr_threshold = 1.15
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.35, 0.4, 0.5); env.ambient_light_energy = 0.7
	var we = WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-50, -30, 0); sun.light_energy = 1.2; vp.add_child(sun)
	cam = Camera3D.new(); cam.fov = 38.0; cam.far = 4000.0; vp.add_child(cam)
	world = World.new(); vp.add_child(world)
	_lane_shader = Shader.new(); _lane_shader.code = LANE_SH
	_terr_shader = Shader.new(); _terr_shader.code = TERR_SH
	overlay = Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; overlay.draw.connect(_draw_overlay); add_child(overlay)
	card = PanelContainer.new(); card.visible = false; card.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(card)
	card_text = RichTextLabel.new(); card_text.bbcode_enabled = true; card_text.fit_content = true; card_text.scroll_active = false; card_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_text)

func _C(): return ui.C
func _pos(n: Dictionary) -> Vector3: return Vector3((float(n["col"]) - 3.0) * 10.5, 0.0, (float(n["y"]) - 0.5) * 30.0)

# ---------------- building the sector ----------------
func sync() -> void:
	var C = _C()
	if C == null or C.RUN == null: return
	if intel == null or intel.C != C: intel = Intel.new(C)
	intel.ai_level = ui.ai_level
	var m = C.RUN["map"]
	var sig = str(C.RUN["sector"]) + "|" + str(m.get("fac")) + "|" + str(m["edges"].hash())
	if sig != _sig:
		_build(sig); _last_pos = C.RUN.get("pos")
		_arrive(true)
	elif token != null and C.RUN.get("pos") != _last_pos and not _flying:
		_last_pos = C.RUN.get("pos"); _arrive(false)
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
func _plane(w: float, d: float) -> PlaneMesh:
	var p = PlaneMesh.new(); p.size = Vector2(w, d); return p
func _shader_mat(code_or_shader, params: Dictionary) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	if code_or_shader is Shader: m.shader = code_or_shader
	else:
		var sh = Shader.new(); sh.code = code_or_shader; m.shader = sh
	for k in params: m.set_shader_parameter(k, params[k])
	return m
# a hull from G2's ship view (the game's mesh for the faction and class), at map scale; null when the renderer is not in the build
func _hull(fac: String, cls: String, length: float, code: String = "") -> Node3D:
	if not ResourceLoader.exists(SHIP_VIEW): return null
	var SV = load(SHIP_VIEW)
	var sv = SV.new()
	var u = {"fac": fac, "cls": cls, "facing": 0, "tpl": "", "id": "map"}
	if code != "": u["code"] = code
	sv.setup(u, Vector3.ZERO, false)
	var wrap = Node3D.new(); wrap.add_child(sv)
	if sv.ring != null: sv.ring.visible = false
	var k = length / max(0.1, float(sv.L)); wrap.scale = Vector3.ONE * k
	sv.set_process(false)
	return wrap
func _code_for(fac: String, cls: String) -> String:
	if not ResourceLoader.exists(HT_PATH): return ""
	return load(HT_PATH).code_for(fac, cls)
func _build(sig: String) -> void:
	_sig = sig
	var C = _C(); var m = C.RUN["map"]; var fac = m.get("fac", "hegemony")
	if root3 != null: root3.queue_free()
	for ch in world.get_children(): ch.queue_free()
	root3 = Node3D.new(); vp.add_child(root3)
	_nodes.clear(); _lanes.clear(); _patrols.clear()
	_rng.seed = hash(sig)
	world.quality = "low"   # no lens: it bends the chart in front of the star too
	world.sky(env, fac, null, int(C.RUN["sector"]) * 13 + str(m.get("region", "")).length())
	world.dead_star(Vector3(-40.0, -125.0, -310.0), 1.1)
	var glow = Color(C.FACTIONS[fac].get("glow", "#e07a70")) if C.FACTIONS.has(fac) else Color("#e07a70")
	root3.add_child(_mi(_plane(110, 60), _shader_mat(_terr_shader, {"col": Color(glow, 0.16), "focus": Vector2(0.86, 0.5)}), Vector3(0, -0.6, 0)))
	root3.add_child(_mi(_plane(110, 60), _shader_mat(GRID_SH, {}), Vector3(0, -0.7, 0)))
	for col in m["cols"]:
		for n in col: _add_node(n)
	for e in m["edges"]: _add_lane(e[0], e[1])
	_add_patrols()
	token = _make_token(); root3.add_child(token)
	token.position = _token_home()
	_focus = 0

# ---------------- node scenes ----------------
func _rock(kind: String, sz: float) -> MeshInstance3D:
	var mesh = world.rock_mesh(_rng, Vector3(_rng.randf_range(0.8, 1.3), _rng.randf_range(0.6, 1.0), _rng.randf_range(0.8, 1.2)), _rng.randi_range(6, 10))
	var mi = MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = world._rock_mat(kind, _rng.randf() * 10.0); mi.scale = Vector3.ONE * sz
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; return mi
func _wisp(col: Color, n: int, spread: float) -> Node3D:
	var w = Node3D.new(); w.name = "spin"
	var tex = world._soft_tex()
	for i in n:
		var q = MeshInstance3D.new(); var qm = QuadMesh.new(); qm.size = Vector2(1, 1); q.mesh = qm
		var m = StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.albedo_texture = tex
		m.albedo_color = Color(col.lerp(Color(0.7, 0.4, 1.0), _rng.randf() * 0.5), 0.35); m.no_depth_test = false
		q.material_override = m; q.scale = Vector3.ONE * _rng.randf_range(1.6, 2.8) * spread
		q.position = Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-0.3, 0.4), _rng.randf_range(-1, 1)) * spread
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; w.add_child(q)
	return w
func _place_scene(obj: Node3D, place: String, mats: Array) -> float:   # the setting of the node; returns the height of its top
	match place:
		"planet":
			var pal = [[Vector3(0.55, 0.42, 0.3), Vector3(0.22, 0.15, 0.1), Vector3(1.0, 0.6, 0.35)], [Vector3(0.3, 0.45, 0.6), Vector3(0.1, 0.18, 0.3), Vector3(0.4, 0.65, 1.0)], [Vector3(0.25, 0.4, 0.22), Vector3(0.12, 0.18, 0.28), Vector3(0.45, 0.7, 1.0)]][_rng.randi() % 3]
			var pm = _shader_mat(PLANET_SH, {"a": Color(pal[0].x, pal[0].y, pal[0].z), "b": Color(pal[1].x, pal[1].y, pal[1].z), "atmo": Color(pal[2].x, pal[2].y, pal[2].z)})
			var pl = _mi(_sphere(1.15, 32, 16), pm, Vector3(0.0, 1.3, -0.4)); pl.name = "spin"; obj.add_child(pl)
			var om = StandardMaterial3D.new(); om.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; om.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; om.albedo_color = Color(0.8, 0.85, 1.0, 0.35)
			var orb = _mi(_torus(1.9, 1.95), om, Vector3(0.0, 1.3, -0.4)); orb.rotation_degrees = Vector3(72, 0, 14); obj.add_child(orb)
			var moon = _mi(_sphere(0.22), _mat(Color(0.7, 0.7, 0.72), 0.0), Vector3(1.9, 1.3, -0.4)); obj.add_child(moon)
			return 2.6
		"station":
			var h = _hull("hegemony", "", 3.2, "O1_37")
			if h != null: h.position = Vector3(0, 1.2, 0); h.name = "spin"; obj.add_child(h)
			else:
				var r = _mi(_torus(0.9, 1.2), _mat(Color(0.55, 0.55, 0.58), 0.0, 0.7, 0.35), Vector3(0, 1.2, 0)); r.rotation_degrees = Vector3(20, 0, 0); r.name = "spin"; obj.add_child(r)
			return 2.3
		"belt":
			var cl = Node3D.new(); cl.name = "spin"; cl.position = Vector3(0, 1.0, 0); obj.add_child(cl)
			var kind = ["stone", "iron", "ice"][_rng.randi() % 3]
			for i in 6:
				var a = float(i) / 6.0 * TAU + _rng.randf() * 0.6
				var rk = _rock(kind, _rng.randf_range(0.25, 0.55)); rk.position = Vector3(cos(a) * 1.3, _rng.randf_range(-0.3, 0.3), sin(a) * 1.0); rk.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, 0)
				cl.add_child(rk)
			return 2.0
		"graveyard":
			var fac = ["voidsworn", "hegemony", "corsair", "deathless"][_rng.randi() % 4]
			var hk = _hull(fac, "Cruiser", 3.4)
			if hk != null:
				hk.position = Vector3(0, 0.9, 0); hk.rotation_degrees = Vector3(18, _rng.randf() * 360.0, 32); obj.add_child(hk)
				var dark = OmniLight3D.new(); dark.light_color = Color(1.0, 0.35, 0.15); dark.light_energy = 0.8; dark.omni_range = 2.5; dark.position = Vector3(0.6, 1.2, 0); obj.add_child(dark)
			else:
				var bx = BoxMesh.new(); bx.size = Vector3(2.6, 0.5, 0.7)
				var hb = _mi(bx, _mat(Color(0.2, 0.19, 0.18), 0.0, 0.6, 0.6), Vector3(0, 0.9, 0)); hb.rotation_degrees = Vector3(15, 30, 25); obj.add_child(hb)
			for i in 3:
				var dr = _rock("carbon", 0.18); dr.position = Vector3(_rng.randf_range(-1.5, 1.5), _rng.randf_range(0.4, 1.4), _rng.randf_range(-1, 1)); obj.add_child(dr)
			return 2.0
		"storm":
			var w = _wisp(Color(0.35, 0.6, 1.0), 5, 1.0); w.position = Vector3(0, 1.2, 0); obj.add_child(w)
			return 2.2
	return 1.6
func _add_node(n: Dictionary) -> void:
	var C = _C(); var p = _pos(n); var obj = Node3D.new(); obj.position = p; root3.add_child(obj)
	var t = n["type"]; var mats = []; var top = 1.6
	var red = Color("#e05a4a"); var gold = Color("#d0a64b"); var teal = Color("#5fb3a6"); var cyan = Color("#62ccff")
	var fight = t in ["battle", "elite", "boss"]
	if fight and t != "boss":
		top = _place_scene(obj, str(n.get("map", "")), mats)
		# the enemy marker over the setting: a red diamond (an elite adds a gold crown ring)
		var dm = _mat(red if t == "battle" else Color("#ff3a2a"), 1.2, 0.2, 0.4); mats.append(dm)
		var dia = _mi(_sphere(0.42 if t == "battle" else 0.55, 4, 2), dm, Vector3(0, top + 0.7, 0)); dia.name = "bob"; obj.add_child(dia)
		if t == "elite":
			var gm = _mat(gold, 1.4); mats.append(gm)
			var cr = _mi(_torus(0.7, 0.78), gm, Vector3(0, top + 0.7, 0)); cr.rotation_degrees = Vector3(80, 0, 0); cr.name = "spin2"; obj.add_child(cr)
		top += 1.1
	elif t == "boss":
		var fac = C.RUN["map"]["fac"]; var btpl = C.FACTIONS[fac].get("boss"); var cls = str(C.HULLS[btpl].get("cls", "Battleship")) if btpl != null and C.HULLS.has(btpl) else "Battleship"
		var bh = _hull(fac, cls, 6.5)
		if bh != null:
			bh.position = Vector3(0, 1.8, 0); bh.rotation_degrees = Vector3(0, 180, 0); obj.add_child(bh)   # it faces back down the sector, at you
		else:
			var m3 = _mat(Color(0.06, 0.03, 0.03), 0.0, 0.8, 0.3); mats.append(m3); obj.add_child(_mi(_sphere(2.1), m3, Vector3(0, 2.3, 0)))
		var m3b = _mat(Color("#ff3a2a"), 1.8); mats.append(m3b)
		var crn = _mi(_torus(3.2, 3.35), m3b, Vector3(0, 0.4, 0)); crn.name = "spin"; obj.add_child(crn)
		var l = OmniLight3D.new(); l.light_color = Color("#ff4a2a"); l.light_energy = 1.6; l.omni_range = 10.0; l.position = Vector3(0, 3.0, 0); obj.add_child(l)
		top = 3.4
	else:
		match t:
			"shipyard":
				var sh = _hull("voidsworn", "", 3.0, "O1_37")
				if sh != null: sh.position = Vector3(0, 1.2, 0); sh.name = "spin"; obj.add_child(sh)
				else:
					var ring = _mi(_torus(0.9, 1.25), _mat(Color(0.55, 0.52, 0.48), 0.0, 0.7, 0.35), Vector3(0, 1.2, 0)); ring.rotation_degrees = Vector3(25, 0, 0); ring.name = "spin"; obj.add_child(ring)
				var m4b = _mat(gold, 1.6); mats.append(m4b)
				for i in 4: obj.add_child(_mi(_sphere(0.09, 8, 4), m4b, Vector3(cos(i * TAU / 4.0) * 1.5, 1.2, sin(i * TAU / 4.0) * 1.5)))
				top = 2.4
			"drydock":
				var m5 = _mat(Color(0.5, 0.52, 0.55), 0.0, 0.7, 0.4); var m5b = _mat(teal, 1.6); mats.append(m5); mats.append(m5b)
				var bx = BoxMesh.new(); bx.size = Vector3(0.25, 1.6, 2.2)
				obj.add_child(_mi(bx, m5, Vector3(-0.8, 1.2, 0))); obj.add_child(_mi(bx, m5, Vector3(0.8, 1.2, 0)))
				var bar = BoxMesh.new(); bar.size = Vector3(1.8, 0.16, 0.16)
				for z in [-0.9, 0.0, 0.9]: obj.add_child(_mi(bar, m5b, Vector3(0, 2.0, z)))
				var hk = _hull(C.RUN["fac"], "Frigate", 1.6)
				if hk != null: hk.position = Vector3(0, 1.1, 0); obj.add_child(hk)
				top = 2.4
			"field":
				var m6 = _mat(Color("#7ddc6a"), 1.3); mats.append(m6)
				var sw = Node3D.new(); sw.name = "spin"; sw.position = Vector3(0, 1.2, 0); obj.add_child(sw)
				for i in 3:
					var bx2 = BoxMesh.new(); bx2.size = Vector3(0.32, 0.18, 0.5)
					sw.add_child(_mi(bx2, m6, Vector3(cos(i * TAU / 3.0), 0, sin(i * TAU / 3.0)) * 0.8))
				top = 1.8
			"event":
				var w = _wisp(cyan, 6, 1.1); w.position = Vector3(0, 1.3, 0); obj.add_child(w)
				var m7 = _mat(cyan, 1.4, 0.0, 0.2); mats.append(m7)
				obj.add_child(_mi(_sphere(0.3), m7, Vector3(0, 1.3, 0)))
				top = 2.2
	var rmat = StandardMaterial3D.new(); rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; rmat.albedo_color = Color(1, 1, 1, 0.2)
	var big = 3.6 if t == "boss" else 1.9
	var ring2 = _mi(_torus(big, big + 0.16), rmat, Vector3(0, 0.05, 0)); obj.add_child(ring2)
	var rival = null
	if t == "battle" and C.RUN.get("foes") != null:
		var f = C.nodeFaction(n)
		if f != C.RUN["map"]["fac"] and C.FACTIONS.has(f): rival = Color(C.FACTIONS[f].get("glow", "#ffffff"))
	if rival != null:
		var rm = StandardMaterial3D.new(); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rm.albedo_color = rival
		obj.add_child(_mi(_torus(big + 0.3, big + 0.4), rm, Vector3(0, 0.05, 0)))
	_nodes[n["id"]] = {"n": n, "pos": p, "obj": obj, "ring": ring2, "rmat": rmat, "mats": mats, "top": top, "rival": rival}
func _add_lane(a: String, b: String) -> void:
	var A = _nodes[a]["pos"]; var B = _nodes[b]["pos"]; var d = B - A
	var cyl = CylinderMesh.new(); cyl.top_radius = 0.08; cyl.bottom_radius = 0.08; cyl.height = d.length(); cyl.radial_segments = 6; cyl.rings = 1
	var tb = _nodes[b]["n"]["type"]
	var hazard = 1.0 if tb in ["elite", "boss"] else 0.0
	var mat = _shader_mat(_lane_shader, {"col": Color(0.9, 0.86, 0.77, 0.12), "flow": 0.0, "hazard": hazard, "pulse": 1.0})
	var mi = _mi(cyl, mat, (A + B) * 0.5 + Vector3(0, 0.15, 0))
	mi.look_at_from_position(mi.position, B + Vector3(0, 0.15, 0), Vector3.UP); mi.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	root3.add_child(mi)
	_lanes[a + ">" + b] = {"a": a, "b": b, "mi": mi, "mat": mat, "hazard": hazard}
func _add_patrols() -> void:   # enemy patrols: one round each rival raider node, two of the sector's own fleet in the far half
	var C = _C(); var fac = C.RUN["map"]["fac"]
	for id in _nodes:
		var d = _nodes[id]
		if d["rival"] != null and not C.jt(d["n"].get("done")):
			var rf = C.nodeFaction(d["n"])
			_patrol(rf, d["pos"], 3.6, 0.35)
	var far = []
	for id in _nodes:
		if float(_nodes[id]["n"]["col"]) >= 4 and _nodes[id]["n"]["type"] != "boss": far.append(_nodes[id]["pos"])
	for i in min(2, far.size()): _patrol(fac, far[_rng.randi() % far.size()] + Vector3(0, 0, _rng.randf_range(-4, 4)), _rng.randf_range(5.0, 7.0), _rng.randf_range(0.15, 0.25))
func _patrol(fac: String, c: Vector3, r: float, sp: float) -> void:
	var node = _hull(fac, "Frigate", 1.5)
	if node == null:
		var pm = PrismMesh.new(); pm.size = Vector3(0.5, 1.2, 0.2)
		node = Node3D.new(); var mi = _mi(pm, _mat(Color(_C().FACTIONS[fac].get("glow", "#e07a70")), 1.0)); mi.rotation_degrees = Vector3(0, 0, -90); node.add_child(mi)
	var lt = OmniLight3D.new(); lt.light_color = Color(_C().FACTIONS[fac].get("glow", "#e07a70")) if _C().FACTIONS.has(fac) else Color.RED; lt.light_energy = 0.7; lt.omni_range = 2.5; node.add_child(lt)
	root3.add_child(node)
	_patrols.append([node, c + Vector3(0, 2.2, 0), r, sp, _rng.randf() * TAU])
func _make_token() -> Node3D:   # your flagship, at map scale
	var C = _C(); var t = Node3D.new()
	var fs = C.flagshipOf()
	var h = null
	if fs != null: h = _hull(C.RUN["fac"], str(C.HULLS[fs["tpl"]].get("cls", "Cruiser")), 3.0)
	if h != null: t.add_child(h)
	else:
		var hull = PrismMesh.new(); hull.size = Vector3(0.9, 2.2, 0.35)
		var hm = _mi(hull, _mat(Color(0.82, 0.74, 0.58), 0.4, 0.8, 0.3)); hm.rotation_degrees = Vector3(0, 0, -90); t.add_child(hm)
	var eng = _mi(_sphere(0.22), _mat(Color("#ffa24a"), 4.0), Vector3(-1.6, 0, 0)); t.add_child(eng)
	var l = OmniLight3D.new(); l.light_color = Color("#ffb060"); l.light_energy = 1.4; l.omni_range = 4.0; l.position = Vector3(-1.6, 0, 0); t.add_child(l)
	return t
func _token_home() -> Vector3:
	var C = _C(); var pos = C.RUN.get("pos")
	if pos != null and _nodes.has(pos): return _nodes[pos]["pos"] + Vector3(0, _nodes[pos]["top"] + 1.0, 1.6)
	return _pos(C.RUN["map"]["cols"][0][0]) + Vector3(-5.5, 2.6, 0)

# ---------------- state ----------------
func _avail() -> Array:
	var C = _C()
	return C.page["data"]["avail"] if C.page["kind"] == "map" else []
func _refresh() -> void:
	var C = _C(); var av = _avail()
	_danger.clear()
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		for m in d["mats"]:   # a passed node goes dark and grey
			var c0: Color = m.get_meta("c0"); var e0: float = m.get_meta("e0")
			m.albedo_color = c0.lerp(Color(0.28, 0.28, 0.3), 0.75) if done else c0
			if m.emission_enabled: m.emission_energy_multiplier = e0 * (0.08 if done else 1.0)
		if not done: _danger[id] = intel.danger(n)
	if _hot != "": _routes = intel.routes_through(_hot)
	_paint_lanes()
	if not _flying and token != null: token.position = _token_home()
	overlay.queue_redraw()
func _route_lanes() -> Dictionary:   # lane key -> route colour (the first route wins a shared lane)
	var out = {}
	for r in _routes:
		var p = [_C().RUN.get("pos")] + r["path"] if _C().RUN.get("pos") != null else r["path"]
		for i in range(p.size() - 1):
			var k = str(p[i]) + ">" + str(p[i + 1])
			if not out.has(k): out[k] = r["col"]
	return out
func _paint_lanes() -> void:
	var C = _C(); var R = C.RUN; var av = _avail(); var lit = _route_lanes()
	for k in _lanes:
		var L = _lanes[k]; var A = _nodes[L["a"]]["n"]; var Bn = _nodes[L["b"]]["n"]
		var trav = C.jt(A.get("done")) and (C.jt(Bn.get("done")) or R.get("pos") == L["b"])
		var nxt = R.get("pos") == L["a"] and av.has(L["b"])
		var col = Color(0.82, 0.65, 0.29, 0.9) if trav else (Color(0.95, 0.75, 0.35, 0.95) if nxt else Color(0.9, 0.86, 0.77, 0.12))
		var flow = 1.0 if nxt else 0.0
		if lit.has(k): col = Color(lit[k], 1.0); flow = 1.0
		L["mat"].set_shader_parameter("col", col); L["mat"].set_shader_parameter("flow", flow)
		L["mat"].set_shader_parameter("hazard", 0.0 if trav or C.jt(Bn.get("done")) else L["hazard"])

func _arrive(new_sector: bool) -> void:   # the camera starts leaning on where the fleet is and settles back over the chart
	var C = _C(); var pos = C.RUN.get("pos")
	var at = _nodes[pos]["pos"] if pos != null and _nodes.has(pos) else _token_home()
	_cam_focus = at; _cam_zoom = 0.62 if new_sector else 0.8; _arrive_t = 0.0
	var tw = create_tween(); tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam_zoom", 1.0, 1.6 if new_sector else 1.1)
	tw.parallel().tween_property(self, "_cam_focus", Vector3.ZERO, 1.6 if new_sector else 1.1)

func _process(delta: float) -> void:
	if not visible or _C() == null or _C().RUN == null or root3 == null: return
	_t += delta
	var mp = get_local_mouse_position() / size.max(Vector2.ONE) - Vector2(0.5, 0.5)
	var aspect = size.x / max(1.0, size.y); var free = clamp((size.x - ui.px(_side_w)) / max(1.0, size.x), 0.4, 1.0)
	var tanh = tan(deg_to_rad(cam.fov * 0.5)); var dist = max(60.0, 80.0 / free / (2.0 * tanh * aspect)) * _cam_zoom
	var shift = (1.0 - free) * 0.5 * (2.0 * dist * tanh * aspect)
	var drift = Vector3(sin(_t * 0.05) * 2.5, sin(_t * 0.037) * 0.8, cos(_t * 0.043) * 1.5)
	var target = Vector3(shift, 0, 0.5).lerp(_cam_focus + Vector3(shift, 0, 0), clamp((1.0 - _cam_zoom) / 0.4, 0.0, 1.0))
	cam.position = target + Vector3(0, dist * 0.62, dist * 0.78) + drift * _cam_zoom + Vector3(mp.x * 2.5, -mp.y * 1.5, 0)
	cam.look_at(target, Vector3.UP)
	for id in _nodes:
		var o = _nodes[id]["obj"]
		var sp = o.get_node_or_null("spin")
		if sp != null: sp.rotate_y(delta * 0.35)
		var sp2 = o.get_node_or_null("spin2")
		if sp2 != null: sp2.rotate_y(delta * 0.8)
		var bob = o.get_node_or_null("bob")
		if bob != null: bob.rotate_y(delta * 1.2)
		var av = _avail().has(id)
		var k = 1.0 + (0.08 * sin(_t * 2.6) if av else 0.0) + (0.12 if id == _hot else 0.0)
		_nodes[id]["ring"].scale = Vector3(k, 1, k)
	for pt in _patrols:
		var a = pt[4] + _t * pt[3]
		var p = pt[1] + Vector3(cos(a) * pt[2], sin(_t * 0.7 + pt[4]) * 0.3, sin(a) * pt[2] * 0.6)
		var nxt = pt[1] + Vector3(cos(a + 0.05) * pt[2], 0, sin(a + 0.05) * pt[2] * 0.6)
		pt[0].position = p
		if p.distance_to(nxt) > 0.001: pt[0].look_at(nxt, Vector3.UP); pt[0].rotate_object_local(Vector3.UP, PI * 0.5)
	if token != null and not _flying: token.position.y = _token_home().y + sin(_t * 1.4) * 0.2
	overlay.queue_redraw()
	_update_card()

# ---------------- labels, intel chips, route totals and the hover card ----------------
func _screen(p: Vector3) -> Vector2: return cam.unproject_position(p)
func _draw_overlay() -> void:
	var C = _C()
	if C == null or C.RUN == null or root3 == null: return
	var av = _avail(); var s = clamp(ui.k, 0.6, 2.2)
	var on_route = {}
	for r in _routes:
		for st in r["st"]["running"]: on_route[st["id"]] = [r, st]
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		if cam.is_position_behind(d["pos"]): continue
		var base = _screen(d["pos"]); var top = _screen(d["pos"] + Vector3(0, d["top"] + 0.6, 0))
		var fight = n["type"] in ["battle", "elite", "boss"]
		var col = ui.BONE if av.has(id) else Color(0.66, 0.64, 0.6)
		if done: col = Color(0.45, 0.44, 0.42)
		var y = base.y + 30.0 * s
		var name = ""
		if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]) and not done: name = str(C.ENCOUNTERS[n["enc"]]["n"])
		elif not fight: name = str(C.NODE_INFO[n["type"]]["n"])
		elif n["type"] == "boss": name = "Sector flagship"
		if name != "": _text(name, Vector2(base.x, y), int(15 * s), col, ui.font_semi); y += 17.0 * s
		if fight and not done and C.nemNodeIs(n):   # B4: his fight is marked before you commit
			var nt = ui.nem_portrait()   # his framed face beside his fight's tags (godot/portraits, R42), when the painting exists
			if nt != null:
				var ps = 38.0 * s; var pr = Rect2(base.x - 42.0 * s - ps, y - 12.0 * s, ps, ps)
				overlay.draw_rect(pr.grow(2.0 * s), Color(0.02, 0.02, 0.03, 0.9)); overlay.draw_texture_rect(nt, pr, false)
				overlay.draw_rect(pr.grow(2.0 * s), Color("#ff6b5a"), false, 1.5 * s)
			_chip("NEMESIS", Vector2(base.x, y + 2.0 * s), int(12 * s), Color("#ff6b5a"), true); y += 18.0 * s
		# intel line: danger band chip, board shape, reward
		if fight and not done and _danger.has(id) and not _danger[id].is_empty():
			var dg = _danger[id]; var sub = ""
			if C.jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]): sub = str(C.SHAPES[n["shape"]]).to_lower()
			if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): sub = (sub + " · " if sub != "" else "") + str(C.NODE_MODS[n["mod"]]["short"]).to_lower()
			_chip(dg["band"].to_upper(), Vector2(base.x, y + 2.0 * s), int(11 * s), dg["col"]); y += 17.0 * s
			if sub != "": _text(sub, Vector2(base.x, y), int(12 * s), Color(0.6, 0.66, 0.75)); y += 14.0 * s
		var rw = n.get("rw")
		if rw is Dictionary and not done:
			if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")):
				var P = C.PATRONS[rw["p"]]; var pc = Color(P["col"]); var bp = top + Vector2(0, -6.0 * s)
				overlay.draw_circle(bp, 9.5 * s, pc); overlay.draw_arc(bp, 9.5 * s, 0, TAU, 24, ui.INK, 2.0 * s, true)
				_text(str(P["glyph"]), bp + Vector2(0, 4.5 * s), int(12 * s), ui.INK, ui.font_semi)
				_text(str(P["short"]) + (" ★" if C.jt(rw.get("min")) else ""), Vector2(base.x, y), int(12 * s), pc if av.has(id) else Color(0.55, 0.53, 0.5))
			else:
				var lab = ui._reward_label(rw)
				if lab != "": _text(lab, Vector2(base.x, y), int(12 * s), Color("#bfb6a0") if av.has(id) else Color("#7f7a6e"))
		if fight and C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]) and not done: _text(str(C.MAP_NAME[n["map"]]).to_upper(), top + Vector2(0, -20.0 * s), int(10 * s), Color(0.55, 0.62, 0.72))

		# running totals along the lit routes
		if on_route.has(id):
			var rr = on_route[id]; var st = rr[1]
			var t = "%d fight%s · %d repair%s" % [st["fights"], "" if st["fights"] == 1 else "s", st["repairs"], "" if st["repairs"] == 1 else "s"]
			_chip(t, top + Vector2(0, -36.0 * s), int(11 * s), rr[0]["col"], true)
	if has_focus() and av.size() > 0:
		var fid = av[_focus % av.size()]
		var fp = _screen(_nodes[fid]["pos"]); overlay.draw_arc(fp, 30.0 * ui.k, 0, TAU, 40, ui.GILT, 2.0, true)
func _text(t: String, at: Vector2, size: int, col: Color, fnt: Font = null) -> void:
	var f = fnt if fnt != null else ui.font
	var w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	for o in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(0, 2)]:   # a dark halo keeps labels legible
		overlay.draw_string(f, Vector2(at.x - w * 0.5, at.y) + o * max(1.0, size / 14.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.75))
	overlay.draw_string(f, Vector2(at.x - w * 0.5, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
func _chip(t: String, at: Vector2, size: int, col: Color, outline: bool = false) -> void:   # a small coloured tag
	var f = ui.font_semi; var w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x; var h = size * 1.35
	var r = Rect2(at.x - w * 0.5 - size * 0.5, at.y - h * 0.8, w + size, h)
	overlay.draw_rect(r, Color(0.02, 0.03, 0.05, 0.85)); overlay.draw_rect(r, col, false, 1.5 if outline else 1.0)
	overlay.draw_string(f, Vector2(at.x - w * 0.5, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
func _node_at(sp: Vector2) -> String:
	var best = ""; var bd = 1e9
	for id in _nodes:
		var d = _nodes[id]
		if cam.is_position_behind(d["pos"]): continue
		var c = _screen(d["pos"] + Vector3(0, d["top"] * 0.5, 0)); var r = 38.0 * ui.k * (1.5 if d["n"]["type"] == "boss" else 1.0)
		var dd = sp.distance_to(c)
		if dd < r and dd < bd:
			bd = dd; best = id
	return best
func _update_card() -> void:
	if _hot == "" or _flying:
		card.visible = false; return
	var C = _C(); var n = C.findNode(_hot)
	if n == null:
		card.visible = false; return
	card.add_theme_stylebox_override("panel", ui._sb(Color(0.03, 0.045, 0.08, 0.95), Color(ui.GILT, 0.6), 1, 3, 12))
	card_text.add_theme_font_size_override("normal_font_size", ui.px(15)); card_text.add_theme_font_size_override("bold_font_size", ui.px(15))
	card_text.custom_minimum_size.x = ui.px(380)
	card_text.text = _card_bb(n)
	card.visible = true; card.reset_size()
	var mp = get_local_mouse_position() + Vector2(ui.px(24), ui.px(16))
	if mp.x + card.size.x > size.x - ui.px(_side_w): mp.x = get_local_mouse_position().x - card.size.x - ui.px(18)
	mp.y = clamp(mp.y, 8, size.y - card.size.y - 8)
	card.position = mp
func _cc(t, col) -> String: return "[color=" + ui.hexs(col) + "]" + str(t) + "[/color]"
func _card_bb(n: Dictionary) -> String:
	var C = _C(); var I = C.NODE_INFO[n["type"]]
	var fight = n["type"] in ["battle", "elite", "boss"]
	var t = "[b]" + _cc(str(I["n"]).to_upper(), ui.BLOOD if n["type"] in ["elite", "boss"] else ui.GILT) + "[/b]"
	if fight and C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]): t += "  " + _cc(str(C.MAP_NAME[n["map"]]), ui.BONE3)
	if C.jt(n.get("done")): t += "  " + _cc("(passed)", ui.BONE3)
	var nem = fight and not C.jt(n.get("done")) and C.nemNodeIs(n)
	if nem:
		var N = C.RUN["nem"]
		t += "\n[b]" + _cc("Nemesis: " + ui.esc(C.nemFull()) + "'s fleet", Color("#ff6b5a")) + "[/b] " + _cc("(" + ui.esc(C.FACTIONS[N["fac"]]["n"]) + ", an elite fight)", ui.BONE3)
	elif fight:
		var fac = C.nodeFaction(n)
		if C.FACTIONS.has(fac): t += "\n" + _cc(ui.esc(C.FACTIONS[fac]["n"]), Color(C.FACTIONS[fac].get("glow", "#e07a70"))) + ((" " + _cc("(rival raiders)", ui.BONE3)) if fac != C.RUN["map"]["fac"] else "")
	if fight:
		var dg = _danger.get(n["id"], {})
		if not dg.is_empty():
			t += "\n[b]" + _cc("Danger: " + dg["band"], dg["col"]) + "[/b] " + _cc("(their strength about %d%% of your fleet's)" % int(round(dg["ratio"] * 100.0)), ui.BONE3)
	if C.jt(n.get("enc")) and C.ENCOUNTERS.has(n["enc"]):
		var E = C.ENCOUNTERS[n["enc"]]
		t += "\n[b]" + ui.esc(E["n"]) + "[/b]" + ((" " + _cc("· " + str(C.SHAPES[n["shape"]]).to_lower(), ui.BONE3)) if C.jt(n.get("shape")) and n["shape"] != "open" and C.SHAPES.has(n["shape"]) else "")
		t += "\n" + _cc(ui.esc(E["d"]), ui.BONE2)
	elif n["type"] == "boss": t += "\n" + _cc("The sector’s command ship and its escort.", ui.BONE2)
	else: t += "\n" + _cc(ui.esc(I["d"]), ui.BONE2)
	if fight:
		var al = ui._arch_label(n, C.nodeFaction(n))
		if al != "": t += "\n" + _cc(ui.esc(al) + ": " + ui.esc(C.ARCHETYPES[C.effArch(n["arch"], C.nodeFaction(n))]["d"]), ui.BLOOD)
	if C.jt(n.get("mod")) and C.NODE_MODS.has(n["mod"]): t += "\n" + _cc(ui.esc(C.NODE_MODS[n["mod"]]["n"]) + ": " + ui.esc(C.NODE_MODS[n["mod"]]["d"]), ui.GILT)
	var rw = n.get("rw")
	if rw is Dictionary and not C.jt(n.get("done")):
		var rc = Color(C.PATRONS[rw["p"]]["col"]) if rw.get("k") == "boon" and C.PATRONS.has(rw.get("p")) else ui.BONE2
		t += "\n" + _cc("Reward: " + ui._reward_label(rw) + (" (rare or better)" if C.jt(rw.get("min")) else ""), rc)
	# the routes through this node to the flagship
	if not _routes.is_empty() and not C.jt(n.get("done")):
		t += "\n\n[b]" + _cc("ROUTES TO THE FLAGSHIP", ui.GILT) + "[/b]"
		var fc = intel.fleet_condition()
		for r in _routes:
			var st = r["st"]
			t += "\n[b]" + _cc(r["name"], r["col"]) + "[/b]  " + "%d fight%s%s, %d repair stop%s, %d shipyard%s" % [st["fights"], "" if st["fights"] == 1 else "s", (" (%d elite)" % st["elites"]) if st["elites"] > 0 else "", st["repairs"], "" if st["repairs"] == 1 else "s", st["shops"], "" if st["shops"] == 1 else "s"]
			t += "\n   " + _cc("%d boon%s, %d refit%s, %d relic%s · worst fight: " % [st["boons"], "" if st["boons"] == 1 else "s", st["refits"], "" if st["refits"] == 1 else "s", st["relics"], "" if st["relics"] == 1 else "s"], ui.BONE3) + _cc(st["worst_name"], Intel.BANDS[st["worst"]][2])
			if fc["hurt"] and not st["repair_before_boss"]: t += "\n   " + _cc("Your fleet is hurt and this route has no repair stop before the flagship.", ui.BLOOD)
	if _avail().has(n["id"]): t += "\n" + _cc("Click to jump here.", ui.BONE3)
	return t

# ---------------- input: hover, click (the camera leans in, the fleet flies, then the jump), keys ----------------
func _set_hot(h: String) -> void:
	if h == _hot: return
	_hot = h
	_routes = intel.routes_through(h) if (h != "" and intel != null) else []
	_paint_lanes()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _avail().has(h) else Control.CURSOR_ARROW
func _gui_input(e: InputEvent) -> void:
	if _flying: return
	if e is InputEventMouseMotion:
		_set_hot(_node_at(e.position))
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id = _node_at(e.position)
		if id != "" and _avail().has(id):
			accept_event(); fly_to(id)
	elif e is InputEventKey and e.pressed:
		var av = _avail()
		if av.is_empty(): return
		if e.keycode in [KEY_RIGHT, KEY_DOWN, KEY_TAB]:
			_focus = (_focus + 1) % av.size(); _set_hot(av[_focus]); accept_event()
		elif e.keycode in [KEY_LEFT, KEY_UP]:
			_focus = (_focus - 1 + av.size()) % av.size(); _set_hot(av[_focus]); accept_event()
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			accept_event(); fly_to(av[_focus % av.size()])
func fly_to(id: String) -> void:
	if _flying or not _nodes.has(id): return
	_flying = true; card.visible = false
	var a = token.position; var b = _nodes[id]["pos"] + Vector3(0, _nodes[id]["top"] + 1.0, 1.6)
	token.look_at(token.position + (b - a).normalized(), Vector3.UP); token.rotate_object_local(Vector3.UP, PI * 0.5)
	var tw = create_tween(); tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam_zoom", 0.7, 0.35); tw.parallel().tween_property(self, "_cam_focus", (a + b) * 0.5, 0.35)
	tw.tween_method(func(f): token.position = a.lerp(b, f) + Vector3(0, sin(f * PI) * 2.0, 0); _cam_focus = token.position, 0.0, 1.0, 0.9)
	tw.tween_callback(func(): _flying = false; token.rotation = Vector3.ZERO; _last_pos = id; _C().act("enterNode", id))
