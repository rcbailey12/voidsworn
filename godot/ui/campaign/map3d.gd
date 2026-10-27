extends Control
# The 3D sector map (G3; R36 first pass, R38 round 2, R51 star system): the sector as a star system round the Hollow Sun.
# Presentation only: it reads the campaign state and calls campaign.act("enterNode", id) like any button, so the bot, the
# parity test and the rules never see it. Its own randomness uses a local generator, never the rules' random numbers.
#
# R51 look (Sins of a Solar Empire 2 star system, map3d_system.gd and map3d_shaders.gd):
# - The Hollow Sun sits at the centre, always in view: a dead black star ringed in slow fire, its glow the system's light,
#   a battlefield debris ring round it. The sector's seven jumps sweep round it from left to right: each column of stops
#   is a bearing from the sun, each stop sits on its own orbit (inner stops nearer the sun), orbit lines drawn faintly.
# - Each stop is a real place: a planet with an atmosphere rim and a moon, a station, an asteroid field along its orbit,
#   a nebula pocket, a wreck field; shipyards, drydocks and repair tenders are built structures; the sector flagship is
#   the enemy flagship hull.
# - Jump lanes are glowing ribbons; the lanes you can take pulse toward the destination; route lanes take the route's colour.
# - A rich sky (three star layers, the galaxy's band, nebula and dust in the sector's colours), near stars and nebula
#   sheets at depth for parallax; smooth zoom (wheel, + and -) and pan (right or middle drag, WASD), Home resets.
# - Faction looks from lore round 3 (colours only, R51): rival halos, threat markers, patrols, the flagship.
# - Quality: "high" or "low" (fewer debris pieces, stars, cloud octaves); ui.map_quality, toggled on the map screen.
#
# Useful (unchanged): the route planner on hover (safest and richest routes to the flagship with running totals), danger
# bands per fight for your fleet as it is now, fight type and board shape, rewards, the hover card, keyboard focus.
# Hull models come from G2's render/ship_view.gd (the PC's gen/ assets); without them a simple shape stands in.

const Intel := preload("res://ui/campaign/map_intel.gd")
const System := preload("res://ui/campaign/map3d_system.gd")
const SHIP_VIEW := "res://render/ship_view.gd"
const HT_PATH := "res://render/hull_table.gd"

# the layout round the sun: column c of n sits at bearing ANG0 - ANG_SPAN * c / (n - 1) (degrees; 90 = far side),
# a stop's orbit radius runs from R_OUT (y = 0) to R_IN (y = 1)
const ANG0 := 190.0
const ANG_SPAN := 200.0
const R_IN := 21.0
const R_OUT := 52.0
const RING_R := 2.4          # the ring round each stop
const SUN_R := 6.0           # the Hollow Sun's core
const CAM_DIR := Vector3(0.0, 0.79, 0.62)

var ui                        # campaign_ui.gd
var intel
var sys                       # map3d_system.gd
var vpc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var env: Environment
var root3: Node3D
var token: Node3D
var overlay: Control
var card: PanelContainer
var card_text: RichTextLabel
var quality := "high"         # "high" or "low" (ui.map_quality)
var _sig := ""
var _nodes := {}              # id -> {n, pos, obj, ring, rmat, mats, top, rival, theta, r}
var _lanes := {}              # "a>b" -> {a, b, mi, mat, hazard}
var _patrols: Array = []      # [node, center, radius, speed, phase, light, fac]
var _sync_lights: Array = []  # lights that pulse in step (the Hegemony look)
var _debris: Node3D = null
var _hot := ""
var _routes: Array = []       # routes through the hovered node (map_intel.routes_through)
var _danger := {}             # id -> danger dict (cached per refresh)
var _focus := 0
var _t := 0.0
var _flying := false
var _side_w := 380.0
var _rng := RandomNumberGenerator.new()
var _cam_focus := Vector3.ZERO   # where the camera leans (eased); zero = the whole chart
var _cam_zoom := 1.0             # 1 = the whole chart; smaller = closer (arrival and jump moves)
var _uz := 1.0                   # the player's zoom (eased toward _uz_t)
var _uz_t := 1.0
var _pan := Vector3.ZERO         # the player's pan on the chart plane (eased toward _pan_t)
var _pan_t := Vector3.ZERO
var _drag := false
var _drag_at := Vector2.ZERO
var _arrive_t := 0.0
var _last_pos = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	vpc = SubViewportContainer.new(); vpc.stretch = true; vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(vpc)
	vp = SubViewport.new(); vp.own_world_3d = true; vpc.add_child(vp)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0.004, 0.006, 0.012)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = 1.0; env.tonemap_white = 6.0
	env.glow_enabled = true; env.glow_intensity = 0.55; env.glow_strength = 0.9; env.glow_bloom = 0.0; env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE   # tight glow only: wide levels would wash light over the Hollow Sun's black core
	for lv in 7: env.set_glow_level(lv, lv >= 1 and lv <= 4)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(0.32, 0.36, 0.48); env.ambient_light_energy = 0.32
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.08
	var we = WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var fill = DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-38, 150, 0); fill.light_energy = 0.32; fill.light_color = Color(0.62, 0.72, 1.0); vp.add_child(fill)
	cam = Camera3D.new(); cam.fov = 36.0; cam.near = 0.5; cam.far = 4000.0; vp.add_child(cam)
	overlay = Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; overlay.draw.connect(_draw_overlay); add_child(overlay)
	card = PanelContainer.new(); card.visible = false; card.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(card)
	card_text = RichTextLabel.new(); card_text.bbcode_enabled = true; card_text.fit_content = true; card_text.scroll_active = false; card_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_text)

func _C(): return ui.C
func _apply_quality() -> void:
	var hi = quality != "low"
	vp.msaa_3d = Viewport.MSAA_4X if hi else Viewport.MSAA_2X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	env.set_glow_level(4, hi)
func set_quality(qv: String) -> void:
	if qv == quality: return
	quality = qv; _sig = ""   # rebuild with the new detail
	if visible: sync()
# where a stop sits: [bearing (radians), orbit radius]
func _polar(n: Dictionary) -> Vector2:
	var ncols = 7
	if _C() != null and _C().RUN != null: ncols = max(2, _C().RUN["map"]["cols"].size())
	var th = deg_to_rad(ANG0 - ANG_SPAN * float(n["col"]) / float(ncols - 1))
	return Vector2(th, R_IN + (1.0 - float(n["y"])) * (R_OUT - R_IN))
func _at(th: float, r: float) -> Vector3: return Vector3(cos(th) * r, 0.0, -sin(th) * r)
func _pos(n: Dictionary) -> Vector3:
	var p = _polar(n); return _at(p.x, p.y)

# ---------------- building the sector ----------------
func sync() -> void:
	var C = _C()
	if C == null or C.RUN == null: return
	if intel == null or intel.C != C: intel = Intel.new(C)
	intel.ai_level = ui.ai_level
	if ui.get("map_quality") != null and str(ui.map_quality) != quality:
		quality = str(ui.map_quality); _sig = ""
	var m = C.RUN["map"]
	var sig = str(C.RUN["sector"]) + "|" + str(m.get("fac")) + "|" + str(m["edges"].hash()) + "|" + quality
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
	_apply_quality()
	var C = _C(); var m = C.RUN["map"]; var fac = m.get("fac", "hegemony")
	if root3 != null: root3.queue_free()
	root3 = Node3D.new(); vp.add_child(root3)
	_nodes.clear(); _lanes.clear(); _patrols.clear(); _sync_lights.clear()
	_rng.seed = hash(sig)
	sys = System.new(); sys.rng = _rng; sys.q = 1.0 if quality != "low" else 0.0
	sys.sky(env, fac, int(C.RUN["sector"]) * 13 + str(m.get("region", "")).length())
	sys.backdrop(root3, fac, max(1.0, ui.k))
	var hs = sys.hollow_sun(root3, SUN_R); _debris = hs["debris"]
	for col in m["cols"]:
		for n in col: _add_node(n)
	_add_orbits()
	# the enemy's light over the far end of the system, where its flagship waits
	var L = System.look(fac); var bpos = _pos(m["cols"][m["cols"].size() - 1][0])
	root3.add_child(sys.mi(sys.flat(44, 44), sys.mat("TERR", {"col": Color(L["main"], 0.18)}), bpos + Vector3(0, -0.3, 0)))
	for e in m["edges"]: _add_lane(e[0], e[1])
	_add_patrols()
	token = _make_token(); root3.add_child(token); _token_sig = _fleet_sig()
	token.position = _token_home()
	_focus = 0
	_fit_key = ""

# faint orbit lines round the sun through every stop, brighter arcs near the stops
func _add_orbits() -> void:
	var radii = {}
	for id in _nodes: radii[snappedf(_nodes[id]["r"], 0.01)] = true
	for r in radii.keys(): sys.orbit(root3, r, Color(0.55, 0.66, 0.88, 0.16), 0.28)
	for id in _nodes:
		var d = _nodes[id]; var span = 7.5 / d["r"]
		sys.orbit_arc(root3, d["r"], d["theta"] - span, d["theta"] + span, Color(0.7, 0.8, 1.0, 0.45), 0.36)
	sys.orbit(root3, SUN_R * 3.6, Color(1.0, 0.5, 0.25, 0.12), 0.25, 90.0)   # the edge of the debris ring

# ---------------- stop scenes ----------------
func _place_scene(obj: Node3D, place: String, d: Dictionary) -> float:   # the setting of the stop; returns the height of its top
	var pal = System.PLANETS[_rng.randi() % System.PLANETS.size()]
	match place:
		"planet":
			var body = sys.planet(obj, pal, 2.1, Vector3(0.0, 1.9, -0.3))
			sys.moon(obj, body.position, 3.6, 0.42)
			return 4.3
		"station":
			var pb = sys.planet(obj, [5, Color(0.5, 0.48, 0.46), Color(0.24, 0.23, 0.22), Color(0.6, 0.6, 0.65)], 1.0, Vector3(-1.5, 1.2, -1.0), false)
			var h = _hull("hegemony", "", 3.6, "O1_37")
			var st = Node3D.new(); st.name = "spin"; st.position = Vector3(0.6, 1.7, 0.4); obj.add_child(st)
			if h != null: st.add_child(h)
			else:
				var r = sys.mi(TorusMesh.new(), sys.std(Color(0.55, 0.55, 0.58), 0.0, 0.7, 0.35)); r.scale = Vector3.ONE * 1.1; r.rotation_degrees = Vector3(20, 0, 0); st.add_child(r)
			sys.glow(st, Color(1.0, 0.3, 0.25, 1.0), 0.7, Vector3(1.4, 0.2, 0), 2.0, 1.4, 1.0)
			sys.glow(st, Color(0.4, 1.0, 0.5, 1.0), 0.7, Vector3(-1.4, 0.2, 0), 2.0, 1.4, 1.0)
			return 3.4
		"belt":
			sys.belt(obj, d["theta"], d["r"], d["pos"], _rng.randi() % 3)
			return 2.6
		"graveyard":
			var wf = ["voidsworn", "hegemony", "corsair", "deathless"][_rng.randi() % 4]
			var hk = _hull(wf, "Cruiser", 4.2)
			if hk != null:
				hk.position = Vector3(0, 1.3, 0); hk.rotation_degrees = Vector3(18, _rng.randf() * 360.0, 32); obj.add_child(hk)
			else:
				var bx = BoxMesh.new(); bx.size = Vector3(3.2, 0.6, 0.9)
				var hb = sys.mi(bx, sys.std(Color(0.2, 0.19, 0.18), 0.0, 0.6, 0.6), Vector3(0, 1.3, 0)); hb.rotation_degrees = Vector3(15, 30, 25); obj.add_child(hb)
			sys.wreck_scraps(obj, 46 if quality != "low" else 16, 1.6)
			sys.glow(obj, Color(1.0, 0.42, 0.14, 1.0), 2.2, Vector3(0.7, 1.4, 0.2), 2.4, 0.9, 1.0)
			var lt = OmniLight3D.new(); lt.light_color = Color(1.0, 0.4, 0.15); lt.light_energy = 1.2; lt.omni_range = 4.0; lt.position = Vector3(0.6, 1.5, 0); obj.add_child(lt)
			return 3.0
		"storm":
			sys.clouds(obj, Color(0.3, 0.55, 1.0), Color(0.7, 0.35, 1.0), 7 if quality != "low" else 4, 1.3, Vector3(0, 1.8, 0), 0.75, 1.0)
			var lt2 = OmniLight3D.new(); lt2.light_color = Color(0.5, 0.65, 1.0); lt2.light_energy = 1.0; lt2.omni_range = 5.0; lt2.position = Vector3(0, 1.8, 0); obj.add_child(lt2)
			return 3.6
	# open space: a small planet far behind the stop so the place still reads
	sys.planet(obj, pal, 1.2, Vector3(-1.4, 1.3, -1.6))
	return 2.6
func _add_node(n: Dictionary) -> void:
	var C = _C(); var pp = _polar(n); var p = _at(pp.x, pp.y); var obj = Node3D.new(); obj.position = p; root3.add_child(obj)
	var t = n["type"]; var mats = []; var top = 2.0
	var gold = Color("#d0a64b"); var teal = Color("#5fb3a6"); var cyan = Color("#62ccff")
	var fight = t in ["battle", "elite", "boss"]
	var d = {"n": n, "pos": p, "theta": pp.x, "r": pp.y}
	var nfac = C.nodeFaction(n) if fight else ""
	if fight and t != "boss":
		top = _place_scene(obj, str(n.get("map", "")), d)
		var gem = sys.marker(obj, Vector3(0, top + 0.9, 0), 0.48 if t == "battle" else 0.62, nfac, t == "elite"); mats.append(gem.material_override)
		if t == "elite":
			var gm = _mat(gold, 2.2); mats.append(gm)
			var cr = sys.mi(_torus(0.85, 0.94), gm, Vector3(0, top + 0.9, 0)); cr.rotation_degrees = Vector3(80, 0, 0); cr.name = "spin2"; obj.add_child(cr)
		top += 1.6
	elif t == "boss":
		var fac = C.RUN["map"]["fac"]; var btpl = C.FACTIONS[fac].get("boss"); var cls = str(C.HULLS[btpl].get("cls", "Battleship")) if btpl != null and C.HULLS.has(btpl) else "Battleship"
		var L = System.look(fac)
		var bh = _hull(fac, cls, 8.0)
		if bh != null:
			bh.position = Vector3(0, 2.2, 0); bh.rotation_degrees = Vector3(0, 180, 0); obj.add_child(bh)   # it faces back down the sector, at you
		else:
			var m3 = _mat(L["base"], 0.0, 0.8, 0.3); mats.append(m3); obj.add_child(sys.mi(sys.sphere(2.2), m3, Vector3(0, 2.4, 0)))
		sys.halo(obj, fac, RING_R * 1.75)
		sys.glow(obj, L["light"], 9.0, Vector3(0, 2.4, 0), 3.0, 0.35, 1.0 if int(L["look"]) == 1 else 0.0)
		var l = OmniLight3D.new(); l.light_color = L["light"]; l.light_energy = 2.0; l.omni_range = 12.0; l.position = Vector3(0, 3.5, 0); obj.add_child(l)
		if int(L["look"]) == 1: _sync_lights.append([l, 2.0])
		top = 4.6
	else:
		match t:
			"shipyard":
				sys.planet(obj, System.PLANETS[1], 1.5, Vector3(-1.8, 1.4, -1.6))
				var sh = _hull("voidsworn", "", 3.4, "O1_37")
				var st = Node3D.new(); st.name = "spin"; st.position = Vector3(0.5, 1.6, 0.3); obj.add_child(st)
				if sh != null: st.add_child(sh)
				else:
					var ring = sys.mi(_torus(0.9, 1.25), sys.std(Color(0.55, 0.52, 0.48), 0.0, 0.7, 0.35)); ring.rotation_degrees = Vector3(25, 0, 0); st.add_child(ring)
				var gm4 = _mat(gold, 2.4); mats.append(gm4)
				var beam = BoxMesh.new(); beam.size = Vector3(0.12, 0.12, 3.4)
				for sx in [-1.0, 1.0]: obj.add_child(sys.mi(beam, sys.std(Color(0.42, 0.4, 0.38), 0.0, 0.8, 0.4), Vector3(sx * 1.6, 1.0, 0.3)))
				for i in 4: obj.add_child(sys.mi(sys.sphere(0.09, 8, 4), gm4, Vector3(cos(i * TAU / 4.0) * 1.7, 1.6, sin(i * TAU / 4.0) * 1.7)))
				sys.glow(obj, Color(1.0, 0.8, 0.4, 1.0), 3.0, Vector3(0.5, 1.6, 0.3), 2.5, 0.5)
				top = 3.4
			"drydock":
				sys.planet(obj, System.PLANETS[4], 1.1, Vector3(-1.7, 1.1, -1.4))
				var m5 = sys.std(Color(0.46, 0.48, 0.52), 0.0, 0.8, 0.4); var m5b = _mat(teal, 2.0); mats.append(m5b)
				var bx = BoxMesh.new(); bx.size = Vector3(0.22, 1.8, 2.6)
				obj.add_child(sys.mi(bx, m5, Vector3(-0.9, 1.4, 0))); obj.add_child(sys.mi(bx, m5, Vector3(0.9, 1.4, 0)))
				var bar = BoxMesh.new(); bar.size = Vector3(2.0, 0.14, 0.14)
				for z in [-1.1, 0.0, 1.1]: obj.add_child(sys.mi(bar, m5b, Vector3(0, 2.3, z)))
				var hk = _hull(C.RUN["fac"], "Frigate", 1.9)
				if hk != null: hk.position = Vector3(0, 1.3, 0); obj.add_child(hk)
				sys.glow(obj, teal, 3.2, Vector3(0, 1.6, 0), 2.5, 0.45)
				top = 3.0
			"field":
				var tend = _hull(C.RUN["fac"], "Frigate", 1.8)
				if tend != null: tend.position = Vector3(0, 1.4, 0); obj.add_child(tend)
				var m6 = _mat(Color("#7ddc6a"), 2.2); mats.append(m6)
				var sw = Node3D.new(); sw.name = "spin"; sw.position = Vector3(0, 1.5, 0); obj.add_child(sw)
				for i in 4:
					var bx2 = BoxMesh.new(); bx2.size = Vector3(0.26, 0.14, 0.4)
					var dp = Vector3(cos(i * TAU / 4.0), 0.15 * sin(i * 2.0), sin(i * TAU / 4.0)) * 1.4
					sw.add_child(sys.mi(bx2, m6, dp)); sys.glow(sw, Color("#7ddc6a"), 0.9, dp, 2.0, 1.0)
				top = 2.6
			"event":
				sys.clouds(obj, Color(0.25, 0.75, 1.0), Color(0.55, 0.3, 1.0), 6 if quality != "low" else 3, 1.2, Vector3(0, 1.8, 0), 0.6)
				var m7 = _mat(cyan, 3.0, 0.0, 0.2); mats.append(m7)
				obj.add_child(sys.mi(sys.sphere(0.32, 16, 8), m7, Vector3(0, 1.8, 0)))
				sys.glow(obj, cyan, 3.4, Vector3(0, 1.8, 0), 2.2, 0.8, 1.0)
				top = 3.2
	# the ring round the stop (its colour says what you can do there) and, for a rival raider, a halo in the rival's look
	var big = RING_R * (1.55 if t == "boss" else 1.0)
	var rmat = sys.mat("RING", {"col": Color(1, 1, 1, 0.25), "r": 0.8})
	var ring2 = sys.mi(sys.flat(big * 2.5, big * 2.5), rmat, Vector3(0, 0.06, 0)); ring2.extra_cull_margin = big; obj.add_child(ring2)
	var rival = null
	if t == "battle" and C.RUN.get("foes") != null:
		var f = C.nodeFaction(n)
		if f != C.RUN["map"]["fac"] and C.FACTIONS.has(f): rival = f
	if rival != null: sys.halo(obj, rival, big * 1.22)
	d.merge({"obj": obj, "ring": ring2, "rmat": rmat, "mats": mats, "top": top, "rival": rival, "ring_r": big})
	_nodes[n["id"]] = d
func _torus(r0: float, r1: float) -> TorusMesh:
	var t = TorusMesh.new(); t.inner_radius = r0; t.outer_radius = r1; t.rings = 48; t.ring_segments = 8; return t
func _add_lane(a: String, b: String) -> void:
	var A = _nodes[a]["pos"]; var B = _nodes[b]["pos"]; var dv = B - A; var L = dv.length()
	var trim_a = _nodes[a]["ring_r"] * 1.05; var trim_b = _nodes[b]["ring_r"] * 1.05
	var a2 = A + dv.normalized() * trim_a; var b2 = B - dv.normalized() * trim_b
	var tb = _nodes[b]["n"]["type"]
	var hazard = 1.0 if tb in ["elite", "boss"] else 0.0
	var mat = sys.mat("LANE", {"col": Color(0.8, 0.85, 1.0, 0.35), "flow": 0.0, "hazard": hazard, "len": (b2 - a2).length(), "glow": 1.0})
	var mi = sys.mi(sys.ribbon(a2, b2, 1.3), mat, Vector3(0, 0.12, 0)); mi.extra_cull_margin = L
	root3.add_child(mi)
	_lanes[a + ">" + b] = {"a": a, "b": b, "mi": mi, "mat": mat, "hazard": hazard}
func _add_patrols() -> void:   # enemy patrols: one round each rival raider stop, two of the sector's own fleet in the far half
	var C = _C(); var fac = C.RUN["map"]["fac"]
	for id in _nodes:
		var d = _nodes[id]
		if d["rival"] != null and not C.jt(d["n"].get("done")):
			_patrol(d["rival"], d["pos"], 4.2, 0.35)
	var far = []
	for id in _nodes:
		if float(_nodes[id]["n"]["col"]) >= 4 and _nodes[id]["n"]["type"] != "boss": far.append(_nodes[id]["pos"])
	for i in min(2, far.size()): _patrol(fac, far[_rng.randi() % far.size()] + Vector3(0, 0, _rng.randf_range(-4, 4)), _rng.randf_range(5.5, 7.5), _rng.randf_range(0.15, 0.25))
func _patrol(fac: String, c: Vector3, r: float, sp: float) -> void:
	var L = System.look(fac)
	var node = _hull(fac, "Frigate", 1.8)
	if node == null:
		var pm = PrismMesh.new(); pm.size = Vector3(0.5, 1.2, 0.2)
		node = Node3D.new(); var m = sys.mi(pm, _mat(L["main"], 1.0)); m.rotation_degrees = Vector3(0, 0, -90); node.add_child(m)
	var lt = OmniLight3D.new(); lt.light_color = L["light"]; lt.light_energy = 0.9; lt.omni_range = 3.0; node.add_child(lt)
	sys.glow(node, L["light"], 1.4, Vector3(-0.9, 0, 0), 2.2, 0.9, 1.0 if int(L["look"]) == 1 else 0.0)
	if int(L["look"]) == 1: _sync_lights.append([lt, 0.9])
	root3.add_child(node)
	_patrols.append([node, c + Vector3(0, 2.6, 0), r, sp, _rng.randf() * TAU])
func _make_token() -> Node3D:   # your fleet at map scale: the flagship's real hull (A4's kit ship when it is in the build) and up to two escorts
	var C = _C(); var t = Node3D.new(); var L = System.look(C.RUN["fac"])
	var fs = C.flagshipOf()
	var h = null
	if fs != null: h = _hull(C.RUN["fac"], str(C.HULLS[fs["tpl"]].get("cls", "Cruiser")), 5.5)
	if h != null: t.add_child(h)
	else:
		var hull = PrismMesh.new(); hull.size = Vector3(1.4, 3.4, 0.5)
		var hm = sys.mi(hull, sys.std(Color(0.82, 0.74, 0.58), 0.4, 0.8, 0.3)); hm.rotation_degrees = Vector3(0, 0, -90); t.add_child(hm)
	var esc = C.RUN["fleet"].filter(func(x): return fs == null or x["uid"] != fs["uid"])
	esc = C.ssort(esc, func(a, b): return float(C.or_(C.HULLS[b["tpl"]].get("cp"), 1)) - float(C.or_(C.HULLS[a["tpl"]].get("cp"), 1)))
	for i in range(min(2, esc.size())):
		var e = _hull(C.RUN["fac"], str(C.HULLS[esc[i]["tpl"]].get("cls", "Frigate")), 3.0)
		if e != null:
			e.position = Vector3(-2.6, -0.3, 2.2 if i == 0 else -2.2); t.add_child(e)
	sys.glow(t, L["light"], 2.6, Vector3(-2.9, 0, 0), 2.0, 1.4)
	var l = OmniLight3D.new(); l.light_color = L["light"]; l.light_energy = 2.0; l.omni_range = 6.0; l.position = Vector3(-2.9, 0, 0); t.add_child(l)
	return t
func _token_home() -> Vector3:
	var C = _C(); var pos = C.RUN.get("pos")
	if pos != null and _nodes.has(pos): return _nodes[pos]["pos"] + Vector3(0, _nodes[pos]["top"] + 1.0, 1.6)
	var n0 = C.RUN["map"]["cols"][0][0]; var pp = _polar(n0)
	return _at(pp.x + deg_to_rad(9.0), R_OUT + 3.0) + Vector3(0, 3.0, 0)   # just before the first jump, outside the outer orbit

# ---------------- state ----------------
func _avail() -> Array:
	var C = _C()
	return C.page["data"]["avail"] if C.page["kind"] == "map" else []
func _refresh() -> void:
	var C = _C(); var av = _avail(); _card_key = ""
	_danger.clear()
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		for m in d["mats"]:   # a passed stop's lights go dark
			if m is ShaderMaterial: m.set_shader_parameter("dim", 0.12 if done else 1.0); continue
			var c0: Color = m.get_meta("c0"); var e0: float = m.get_meta("e0")
			m.albedo_color = c0.lerp(Color(0.28, 0.28, 0.3), 0.75) if done else c0
			if m.emission_enabled: m.emission_energy_multiplier = e0 * (0.08 if done else 1.0)
		if not done: _danger[id] = intel.danger(n)
		# the ring says what you can do with the stop: gilt where you can jump now, bright where the fleet is, faint ahead, grey behind
		var rc = Color(0.75, 0.82, 1.0, 0.32); var dash = 0.0; var fill = 0.0
		if done: rc = Color(0.5, 0.5, 0.55, 0.16)
		if av.has(id): rc = Color(1.0, 0.76, 0.34, 0.95); dash = 1.0; fill = 1.0
		if C.RUN.get("pos") == id: rc = Color(1.0, 0.88, 0.55, 1.0); fill = 0.6
		d["rmat"].set_shader_parameter("col", rc); d["rmat"].set_shader_parameter("dash", dash); d["rmat"].set_shader_parameter("fill", fill)
	if _hot != "": _routes = intel.routes_through(_hot)
	_paint_lanes()
	var fsig = _fleet_sig()
	if token != null and fsig != _token_sig and not _flying:   # the fleet changed (a hull bought, sold or lost): redraw the token
		_token_sig = fsig; var p0 = token.position; token.queue_free(); token = _make_token(); root3.add_child(token); token.position = p0
	if not _flying and token != null: token.position = _token_home()
	overlay.queue_redraw()
var _token_sig := ""
func _fleet_sig() -> String: return str(_C().RUN["fleet"].map(func(x): return str(x["uid"]) + str(x["tpl"]))) + str(_C().RUN.get("flagUid"))
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
		if R.get("pos") == null and av.has(L["b"]): nxt = false
		var col = Color(0.95, 0.72, 0.32, 0.8) if trav else (Color(1.0, 0.78, 0.38, 1.0) if nxt else Color(0.7, 0.8, 1.0, 0.32))
		var past = C.jt(A.get("done")) and not trav   # a lane you can no longer take
		if past: col = Color(0.5, 0.52, 0.58, 0.12)
		var flow = 1.0 if nxt else 0.0
		if lit.has(k): col = Color(lit[k], 1.0); flow = 1.0
		L["mat"].set_shader_parameter("col", col); L["mat"].set_shader_parameter("flow", flow)
		L["mat"].set_shader_parameter("glow", 1.4 if (flow > 0.0 or trav) else 0.8)
		L["mat"].set_shader_parameter("hazard", 0.0 if trav or past or C.jt(Bn.get("done")) else L["hazard"])

func _arrive(new_sector: bool) -> void:   # the camera starts leaning on where the fleet is and settles back over the chart
	var C = _C(); var pos = C.RUN.get("pos")
	var at = _nodes[pos]["pos"] if pos != null and _nodes.has(pos) else _token_home()
	_cam_focus = at; _cam_zoom = 0.62 if new_sector else 0.8; _arrive_t = 0.0
	_uz_t = 1.0; _pan_t = Vector3.ZERO
	var tw = create_tween(); tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam_zoom", 1.0, 1.6 if new_sector else 1.1)
	tw.parallel().tween_property(self, "_cam_focus", Vector3.ZERO, 1.6 if new_sector else 1.1)

func _process(delta: float) -> void:
	if not visible or _C() == null or _C().RUN == null or root3 == null: return
	_t += delta
	var mp = get_local_mouse_position() / size.max(Vector2.ONE) - Vector2(0.5, 0.5)
	var fr = _free_rect(); var fk = str(size) + "|" + _sig + "|" + str(fr.position.round()) + str(fr.size.round())
	if fk != _fit_key: _fit_key = fk; _fit(fr)
	# the player's zoom and pan ease in; the arrival and jump moves layer on top
	var ke = 1.0 - exp(-delta * 7.0)
	_uz = lerp(_uz, _uz_t, ke); _pan = _pan.lerp(_pan_t, ke)
	var dist = _fit_dist * _cam_zoom * _uz
	var drift = Vector3(sin(_t * 0.05) * 1.0, sin(_t * 0.037) * 0.4, cos(_t * 0.043) * 0.7)   # small: the fitted frame must hold
	var base_t = _fit_target + _pan
	var target = base_t.lerp(_cam_focus, clamp((1.0 - _cam_zoom) / 0.4, 0.0, 1.0)) if _cam_focus != Vector3.ZERO else base_t
	cam.position = target + CAM_DIR * dist + drift * _cam_zoom * _uz + Vector3(mp.x * 1.4, -mp.y * 0.9, 0) * _uz
	cam.look_at(target, Vector3.UP)
	if _debris != null: _debris.rotate_y(delta * 0.012)
	var sync_k = 0.7 + 0.5 * sin(_t * 2.4)   # the Hegemony lights keep one beat
	for sl in _sync_lights:
		if is_instance_valid(sl[0]): sl[0].light_energy = sl[1] * sync_k
	for id in _nodes:
		var o = _nodes[id]["obj"]
		for ch in o.get_children():
			if ch.name == "body":
				var s = ch.get_node_or_null("spin")
				if s != null: s.rotate_y(delta * 0.08)
			elif ch.name == "moon": ch.rotate_y(delta * 0.22)
		var sp = o.get_node_or_null("spin")
		if sp != null: sp.rotate_y(delta * 0.3)
		var sp2 = o.get_node_or_null("spin2")
		if sp2 != null: sp2.rotate_y(delta * 0.8)
		var bob = o.get_node_or_null("bob")
		if bob != null:
			bob.rotate_y(delta * 1.2); bob.position.y = _nodes[id]["top"] - 0.7 + sin(_t * 1.6 + _nodes[id]["theta"] * 3.0) * 0.12
		var av = _avail().has(id)
		var k = 1.0 + (0.05 * sin(_t * 2.6) if av else 0.0) + (0.1 if id == _hot else 0.0)
		_nodes[id]["ring"].scale = Vector3(k, 1, k)
		_nodes[id]["rmat"].set_shader_parameter("hot", 1.0 if id == _hot else 0.0)
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
# ---------------- framing: every node, its scene and its labels inside the part of the screen the map really has ----------------
var _fit_key := ""
var _fit_target := Vector3(0, 0, 0.5)
var _fit_dist := 100.0
func _free_rect() -> Rect2:   # left of the side panel, below the title and intel strip, above the legend and the fight previews
	var L = float(ui.px(28)); var Rr = size.x - float(ui.px(_side_w)) - float(ui.px(28)); var T = float(ui.px(170)); var Bt = size.y - float(ui.px(170))
	if ui.has_method("map_free_y"):
		var fy: Vector2 = ui.map_free_y()
		if fy.x > 0.0: T = fy.x + float(ui.px(12))
		if fy.y > 0.0: Bt = fy.y - float(ui.px(8))
	return Rect2(L, T, max(100.0, Rr - L), max(100.0, Bt - T))
func _ground(sp: Vector2) -> Vector3:
	var o = cam.project_ray_origin(sp); var d = cam.project_ray_normal(sp)
	return o + d * (-o.y / d.y) if abs(d.y) > 0.0001 else o
func _fit(fr: Rect2) -> void:
	if _nodes.is_empty(): return
	var pts = []
	for id in _nodes:   # the node's scene and its labels: a little wider than the ring, up to the region name, down to the chips
		var p = _nodes[id]["pos"]
		for d in [Vector3(-5.0, 0, 0), Vector3(5.0, 0, 0), Vector3(0, _nodes[id]["top"] + 2.6, -1.0), Vector3(0, 0, 5.0)]: pts.append(p + d)
	for d in [Vector3(-SUN_R * 2.2, 0, 0), Vector3(SUN_R * 2.2, 0, 0), Vector3(0, 0, SUN_R * 2.4), Vector3(0, SUN_R * 1.2, 0)]: pts.append(d)   # the Hollow Sun and its fire stay in frame
	var lo = Vector3(INF, 0, INF); var hi = Vector3(-INF, 0, -INF)
	for id in _nodes:
		var p = _nodes[id]["pos"]; lo = Vector3(min(lo.x, p.x), 0, min(lo.z, p.z)); hi = Vector3(max(hi.x, p.x), 0, max(hi.z, p.z))
	var tgt = (lo + hi) * 0.5; var dist = 100.0
	for it in 10:
		cam.position = tgt + CAM_DIR * dist; cam.look_at(tgt, Vector3.UP)
		var a = Vector2(INF, INF); var b = Vector2(-INF, -INF)
		for q in pts:
			var sp = cam.unproject_position(q); a = Vector2(min(a.x, sp.x), min(a.y, sp.y)); b = Vector2(max(b.x, sp.x), max(b.y, sp.y))
		var k = max((b.x - a.x) / fr.size.x, (b.y - a.y) / fr.size.y)
		var off = _ground((a + b) * 0.5) - _ground(fr.get_center())
		tgt += Vector3(off.x, 0, off.z); dist *= clamp(lerp(1.0, k, 0.8), 0.6, 1.6)
	_fit_target = tgt; _fit_dist = dist
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
		if fight and C.jt(n.get("map")) and C.MAP_NAME.has(n["map"]) and not done: _text(str(C.MAP_NAME[n["map"]]).to_upper(), top + Vector2(0, -20.0 * s), int(10 * s), Color(0.62, 0.7, 0.82), ui.font_caps)

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
	var o = Vector2(at.x - w * 0.5, at.y)
	overlay.draw_string(f, o + Vector2(0, max(1.0, size / 10.0)), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.55))   # a soft drop shadow
	overlay.draw_string_outline(f, o, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, max(3, int(size / 3.5)), Color(0.0, 0.005, 0.015, 0.82))   # a dark outline keeps labels legible
	overlay.draw_string(f, o, t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
var _chip_sb: StyleBoxFlat = null
func _chip(t: String, at: Vector2, size: int, col: Color, outline: bool = false) -> void:   # a small rounded coloured tag
	var f = ui.font_caps if ui.font_caps != null else ui.font_semi; var w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x; var h = size * 1.45
	var r = Rect2(at.x - w * 0.5 - size * 0.55, at.y - h * 0.78, w + size * 1.1, h)
	if _chip_sb == null: _chip_sb = StyleBoxFlat.new(); _chip_sb.anti_aliasing = true
	_chip_sb.bg_color = Color(col.darkened(0.78), 0.9); _chip_sb.border_color = Color(col, 0.95 if outline else 0.7)
	_chip_sb.set_border_width_all(max(1, int(round(1.5 if outline else 1.0)))); _chip_sb.set_corner_radius_all(int(h * 0.5))
	overlay.draw_style_box(_chip_sb, r)
	overlay.draw_string(f, Vector2(at.x - w * 0.5, at.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col.lightened(0.12))
func _node_at(sp: Vector2) -> String:
	var best = ""; var bd = 1e9
	for id in _nodes:
		var d = _nodes[id]
		if cam.is_position_behind(d["pos"]): continue
		var c = _screen(d["pos"] + Vector3(0, d["top"] * 0.4, 0))
		var r = max(34.0 * ui.k, _screen(d["pos"]).distance_to(_screen(d["pos"] + cam.global_transform.basis.x * d["ring_r"] * 1.15)))
		var dd = sp.distance_to(c)
		if dd < r and dd < bd:
			bd = dd; best = id
	return best
var _card_key := ""
var _hot_by_key := false
func _update_card() -> void:
	if _hot == "" or _flying:
		card.visible = false; return
	var C = _C(); var n = C.findNode(_hot)
	if n == null:
		card.visible = false; return
	var csb = ui._glass(Color(0.022, 0.033, 0.06, 0.95), Color(ui.GILT, 0.85), "top", 2, 4, 13, 16); csb.shadow_color = Color(0, 0, 0, 0.6)
	card.add_theme_stylebox_override("panel", csb)
	card_text.add_theme_font_size_override("normal_font_size", ui.px(15)); card_text.add_theme_font_size_override("bold_font_size", ui.px(15))
	card_text.custom_minimum_size.x = ui.px(380)
	var ck = _hot + "|" + str(_routes.size()) + "|" + str(_danger.get(_hot, {}).get("ratio", 0))
	if ck != _card_key:   # the text only changes with the node, its routes or its danger
		_card_key = ck; card_text.text = _card_bb(n)
	card.visible = true; card.reset_size()
	var anchor = get_local_mouse_position() if not _hot_by_key else _screen(_nodes[_hot]["pos"]) if _nodes.has(_hot) else get_local_mouse_position()   # keyboard focus: beside the node
	var mp = anchor + Vector2(ui.px(24), ui.px(16))
	if mp.x + card.size.x > size.x - ui.px(_side_w): mp.x = anchor.x - card.size.x - ui.px(18)
	mp.y = clamp(mp.y, 8, size.y - card.size.y - 8)
	card.position = mp
# The Nemesis on his fight's card (the fields the war-room card carries, short): persona, strengths with their effect,
# scars, what feeds or enriches him, adaptations with their effect, weaknesses you have found with their effect,
# what he remembers beating him with, and what this win will do to him.
func _nem_card(N: Dictionary) -> String:
	var C = _C(); var t = ""; var red = Color("#ff6b5a")
	var P = C.NEM_PERSONA.get(N.get("persona")) if N.get("persona") != null else null
	if P != null: t += "\n" + _cc(ui.esc(P["n"]) + ":", ui.GILT) + " " + _cc(ui.esc(P["d"]), ui.BONE2)
	if N.get("traits") is Array and N["traits"].size() > 0:
		var ts = []
		for tr in N["traits"]:
			if C.NEM_TRAITS.has(tr): ts.append(_cc(ui.esc(C.NEM_TRAITS[tr]["n"]), red) + _cc(" (" + ui.esc(str(C.NEM_TRAITS[tr]["d"]).trim_suffix(".")) + ")", ui.BONE3))
		if not ts.is_empty(): t += "\n" + _cc("Strengths: ", ui.BONE2) + "; ".join(PackedStringArray(ts))
	var extra = []
	if C.jt(N.get("scars")): extra.append("scarred %dx" % int(N["scars"]))
	if C.jt(N.get("fed")): extra.append("fed %d of 8 (+%d%% hull)" % [int(N["fed"]), min(32, 4 * int(N["fed"]))])
	if C.jt(N.get("riches")): extra.append("%d extra ship%s from riches" % [int(N["riches"]), "" if int(N["riches"]) == 1 else "s"])
	if C.jt(N.get("honed")): extra.append("honed %d of 3" % min(3, int(N["honed"])))
	if C.jt(N.get("gloat")): extra.append("gloating after his last win")
	if not extra.is_empty(): t += "\n" + _cc(ui.esc(", ".join(PackedStringArray(extra))), ui.BONE3)
	if N.get("adapt") is Array and N["adapt"].size() > 0:
		var ad = []
		for a in N["adapt"]: ad.append(_cc(ui.esc(C.nemAdaptName(a, N["fac"])), red) + _cc(" (" + ui.esc(C.nemAdaptDesc(a, N["fac"]).trim_suffix(".")) + ")", ui.BONE3))
		t += "\n" + _cc("Adapted: ", ui.BONE2) + "; ".join(PackedStringArray(ad))
	var ws = []; var unknown = 0
	for w in N.get("weak", []):
		if N.get("revealed", []).has(w) and C.NEM_WEAK.has(w): ws.append(_cc(ui.esc(C.NEM_WEAK[w]["n"]), ui.GILT) + _cc(" (" + ui.esc(str(C.NEM_WEAK[w].get("d", "")).trim_suffix(".")) + ")", ui.BONE3))
		else: unknown += 1
	if unknown > 0: ws.append(_cc("%d unknown (beat him to learn one)" % unknown, ui.BONE3))
	if not ws.is_empty(): t += "\n" + _cc("Weaknesses: ", ui.BONE2) + "; ".join(PackedStringArray(ws))
	if C.jt(N.get("last_beat")): t += "\n" + _cc(C.nemPr(N)["He"] + " remembers losing to your " + str(C.NEM_BEAT_WORD.get(N["last_beat"], N["last_beat"])) + ".", ui.BONE3)
	var warn = C.nemWarnLine(N)
	if warn != "": t += "\n" + _cc(ui.esc(warn), red)
	return t
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
		t += _nem_card(N)
	elif fight:
		var fac = C.nodeFaction(n)
		if C.FACTIONS.has(fac): t += "\n" + _cc(ui.esc(C.FACTIONS[fac]["n"]), Color(C.FACTIONS[fac].get("glow", "#e07a70"))) + ((" " + _cc("(rival raiders)", ui.BONE3)) if fac != C.RUN["map"]["fac"] else "")
	if fight:
		var dg = _danger.get(n["id"], {})
		if not dg.is_empty():
			t += "\n[b]" + _cc("Danger: " + dg["band"], dg["col"]) + "[/b] " + _cc("(their strength about %d%% of your fleet's)" % int(round(dg["ratio"] * 100.0)), ui.BONE3)
			var wy = dg.get("why", [])
			if not wy.is_empty():   # what moved the number
				var ps = []
				for w in wy: ps.append("%s %s%d%%" % [w[0], "+" if w[1] >= 1.0 else "", int(round((w[1] - 1.0) * 100.0))])
				t += "\n   " + _cc("Includes: " + ", ".join(PackedStringArray(ps)) + ".", ui.BONE3)
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
		t += "\n" + _cc("Safest: the mildest worst fight, then the least danger in all (repair stops count in its favour). Richest: the most rewards (relic 4, boon 3, refit 2, shipyard 2, credits 1, event 1).", ui.BONE3)
		var fc = intel.fleet_condition()
		for r in _routes:
			var st = r["st"]
			t += "\n[b]" + _cc(r["name"], r["col"]) + "[/b]  " + "%d fight%s%s, %d repair stop%s, %d shipyard%s" % [st["fights"], "" if st["fights"] == 1 else "s", (" (%d elite)" % st["elites"]) if st["elites"] > 0 else "", st["repairs"], "" if st["repairs"] == 1 else "s", st["shops"], "" if st["shops"] == 1 else "s"]
			t += "\n   " + _cc("%d boon%s, %d refit%s, %d relic%s, %d credit reward%s, %d event%s · worst fight: " % [st["boons"], "" if st["boons"] == 1 else "s", st["refits"], "" if st["refits"] == 1 else "s", st["relics"], "" if st["relics"] == 1 else "s", st["credits"], "" if st["credits"] == 1 else "s", st["events"], "" if st["events"] == 1 else "s"], ui.BONE3) + _cc(st["worst_name"], Intel.BANDS[st["worst"]][2])
			if fc["hurt"] and not st["repair_before_boss"]: t += "\n   " + _cc("Your fleet is hurt and this route has no repair stop before the flagship.", ui.BLOOD)
	if _avail().has(n["id"]): t += "\n" + _cc("Click to jump here.", ui.BONE3)
	return t

# ---------------- input: hover, click (the camera leans in, the fleet flies, then the jump), zoom and pan, keys ----------------
func _set_hot(h: String) -> void:
	if h == _hot: return
	_hot = h
	_routes = intel.routes_through(h) if (h != "" and intel != null) else []
	_paint_lanes()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _avail().has(h) else Control.CURSOR_ARROW
const ZOOM_MIN := 0.38
const ZOOM_MAX := 1.2
func zoom_by(f: float, at: Vector2 = Vector2(-1, -1)) -> void:   # f < 1 zooms in; toward the point under the cursor
	var nz = clamp(_uz_t * f, ZOOM_MIN, ZOOM_MAX)
	if at.x >= 0.0 and nz != _uz_t:
		var g = _ground(at); var c = _fit_target + _pan_t
		_pan_t += Vector3(g.x - c.x, 0, g.z - c.z) * (1.0 - nz / _uz_t)
	_uz_t = nz; _clamp_pan()
func pan_by(v: Vector3) -> void:
	_pan_t += Vector3(v.x, 0, v.z); _clamp_pan()
func reset_view() -> void:
	_uz_t = 1.0; _pan_t = Vector3.ZERO
func _clamp_pan() -> void:
	var lim = (R_OUT + 6.0) * (1.25 - _uz_t * 0.6)
	if _pan_t.length() > lim: _pan_t = _pan_t.normalized() * lim
	if _uz_t >= 0.999: _pan_t = _pan_t.limit_length(R_OUT * 0.5)
func _gui_input(e: InputEvent) -> void:
	if _flying: return
	if e is InputEventMouseMotion:
		if _drag:
			var a = _ground(_drag_at); var b = _ground(e.position); _drag_at = e.position
			pan_by(a - b); accept_event(); return
		_hot_by_key = false; _set_hot(_node_at(e.position))
	elif e is InputEventMouseButton:
		if e.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_drag = e.pressed; _drag_at = e.position; accept_event()
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(0.88, e.position); accept_event()
		elif e.pressed and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(1.0 / 0.88, e.position); accept_event()
		elif e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			var id = _node_at(e.position)
			if id != "" and _avail().has(id):
				accept_event(); fly_to(id)
			elif e.double_click: reset_view()
	elif e is InputEventKey and e.pressed:
		var step = 4.0 * _uz_t
		match e.keycode:
			KEY_HOME: reset_view(); accept_event(); return
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: zoom_by(0.88); accept_event(); return
			KEY_MINUS, KEY_KP_SUBTRACT: zoom_by(1.0 / 0.88); accept_event(); return
			KEY_W: pan_by(Vector3(0, 0, -step)); accept_event(); return
			KEY_S: pan_by(Vector3(0, 0, step)); accept_event(); return
			KEY_A: pan_by(Vector3(-step, 0, 0)); accept_event(); return
			KEY_D: pan_by(Vector3(step, 0, 0)); accept_event(); return
		var av = _avail()
		if av.is_empty(): return
		if e.keycode in [KEY_RIGHT, KEY_DOWN, KEY_TAB]:
			_focus = (_focus + 1) % av.size(); _hot_by_key = true; _set_hot(av[_focus]); accept_event()
		elif e.keycode in [KEY_LEFT, KEY_UP]:
			_focus = (_focus - 1 + av.size()) % av.size(); _hot_by_key = true; _set_hot(av[_focus]); accept_event()
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			accept_event(); fly_to(av[_focus % av.size()])
func fly_to(id: String) -> void:
	if _flying or not _nodes.has(id): return
	_flying = true; card.visible = false; _drag = false
	var a = token.position; var b = _nodes[id]["pos"] + Vector3(0, _nodes[id]["top"] + 1.0, 1.6)
	token.look_at(token.position + (b - a).normalized(), Vector3.UP); token.rotate_object_local(Vector3.UP, PI * 0.5)
	_uz_t = 1.0; _pan_t = Vector3.ZERO
	var tw = create_tween(); tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam_zoom", 0.7, 0.35); tw.parallel().tween_property(self, "_cam_focus", (a + b) * 0.5, 0.35)
	tw.tween_method(func(f): token.position = a.lerp(b, f) + Vector3(0, sin(f * PI) * 2.0, 0); _cam_focus = token.position, 0.0, 1.0, 1.0)
	tw.tween_callback(func(): _flying = false; token.rotation = Vector3.ZERO; _last_pos = id; _C().act("enterNode", id))
