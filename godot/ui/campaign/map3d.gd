extends Control
# The 3D sector map (G3; R36 first pass, R38 round 2, R51 star system): the sector as a star system round the Hollow Sun.
# Presentation only: it reads the campaign state and calls campaign.act("enterNode", id) like any button, so the bot, the
# parity test and the rules never see it. Its own randomness uses a local generator, never the rules' random numbers.
#
# Briefing map, R165/R170/R174: one fall inward across the three sectors, with routes as the only chart lines.
# Fight stops show the enemy's real hulls; services and events keep their models. Every stop ahead has a sage type icon.
# Next jumps have full models and lime routes; ahead is 85% size and 75% light, cut off is half of each.
# The rail, captions, hover cards and controls retain the Briefing layout.
#
# Useful (unchanged in what it knows): the route planner on hover (safest and richest routes to the flagship with running totals), danger
# bands per fight for your fleet as it is now, fight type and board shape, rewards, the hover card, keyboard focus.
# Hull models come from G2's render/ship_view.gd (the PC's gen/ assets); without them a simple shape stands in.

const Intel := preload("res://ui/campaign/map_intel.gd")
const System := preload("res://ui/campaign/map3d_system.gd")
const Props := preload("res://ui/campaign/map3d_props.gd")
const World := preload("res://world/world.gd")
const Loading := preload("res://main/load_screen.gd")
const SHIP_VIEW := "res://render/ship_view.gd"
const HT_PATH := "res://render/hull_table.gd"
const CamRig := preload("res://render/camera_rig.gd")

# Sector framing lives in System.APPROACH; the route graph stays in RUN.
const RING_R := 2.4          # the ring round each stop
const SUN_R := 5.0           # the Hollow Sun's shadow (the black hole)
const CAM_DIR := Vector3(0.0, 0.79, 0.62)
const TOKEN_OFF := Vector3(0.0, 1.8, 3.0)   # where the fleet holds over a stop (above it, toward the camera)

const GS = preload("res://ui/theme/glass_shell.gd")   # Lime Tactical pieces for the map words (issue #344)
const View = preload("res://campaign/campaign_view.gd")   # the stop's words and the Nemesis, read only
const COL_W := 540.0          # the briefing column over the left of the chart (campaign_ui.gd)
const BACKDROP_K := 0.5       # the backdrop's strength in the Briefing build ("dimmed about half")
const LAYER_AHEAD := 2        # render layer of the stops further on (lit by the Hollow Sun at TIER_LIGHT[1])
const LAYER_BEHIND := 4       # render layer of the stops behind you or cut off (TIER_LIGHT[2])
const LAYER_SCENERY := 8
var region_scenery: Node3D
const TIER_LIGHT := [1.0, 0.75, 0.375]   # cut-off stops have half the ahead brightness
const TIER_SCALE := [1.0, 0.85, 0.425]
var ui                        # campaign_ui.gd
var intel
var sys                       # map3d_system.gd
var props                     # map3d_props.gd (stations, gantries, dock frames, drones, asteroids at full finish)
var _spinners: Array = []     # [node, axis, rate] parts that turn (station rings, the station itself)
var _drones: Array = []       # [node, center, radius, speed, phase, height]
var vpc: SubViewportContainer
var vp: SubViewport
var cam: Camera3D
var env: Environment
var root3: Node3D
var token: Node3D
var sheet_veil: TextureRect
var overlay: Control
var card: PanelContainer      # the hover tip: the only box on the map
var card_box: VBoxContainer
var quality := "high"         # "high" or "low" (ui.map_quality)
var backdrop := false         # true: drawn behind another page (no labels, no hover, no input)
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
var _kb := -1                 # the stop the arrow keys are on (an index into _kb_order)
var _t := 0.0
var _flying := false
const FLIGHT_SECONDS := 2.4
var _reachable := {}          # all descendants of the choices allowed by the campaign
var _flight_id := ""
var _flight_curve: Curve3D
var _flight_time := 0.0
var _flight_rotation := Quaternion.IDENTITY
var _flight_heights := Vector2.ZERO
var _arrival_tween: Tween
var _engine_mounts: Array[Vector3] = []
var _wake_samples: Array = []
var _wake_mesh: ImmediateMesh
var _wake_node: MeshInstance3D
var _wake_material: StandardMaterial3D
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
var loading := false
var sector_world: Node3D
var _fill: DirectionalLight3D

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
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY   # metal plating picks up the nebula and the stars
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.08
	var we = WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	_fill = DirectionalLight3D.new(); _fill.rotation_degrees = Vector3(-38, 150, 0); _fill.light_color = Color(0.62, 0.72, 1.0); vp.add_child(_fill)
	cam = Camera3D.new(); cam.fov = 36.0; cam.near = 0.5; cam.far = 4000.0; vp.add_child(cam)
	sheet_veil = TextureRect.new(); sheet_veil.texture = GS.sheet_veil(); sheet_veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sheet_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); sheet_veil.anchor_right = 0.43; sheet_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(sheet_veil)
	overlay = Control.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; overlay.draw.connect(_draw_overlay); add_child(overlay)
	card = PanelContainer.new(); card.visible = false; card.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(card)
	card_box = VBoxContainer.new(); card_box.add_theme_constant_override("separation", 0); card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(card_box)
	mouse_exited.connect(func():   # the pointer left the chart (onto the briefing column, say): no stop is pointed at
		if not _hot_by_key and not _flying and intel != null: _set_hot(""))

func _C(): return ui.C
func _apply_quality() -> void:
	var hi = quality != "low"
	vp.msaa_3d = Viewport.MSAA_4X if hi else Viewport.MSAA_2X
	vp.positional_shadow_atlas_size = 4096 if hi else 0   # High: the Hollow Sun's light casts soft shadows
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	env.set_glow_level(4, hi)
func set_quality(qv: String) -> void:
	if qv == quality: return
	quality = qv; _sig = ""   # rebuild with the new detail
	if visible: sync()
# Presentation coordinates only. The route graph, node records and random streams stay in the campaign.
func _polar(n: Dictionary) -> Vector2:
	var p = _pos(n)
	return Vector2(atan2(-p.z, p.x), Vector2(p.x, p.z).length())
func _outer_radius() -> float:
	return System.sector_look(int(_C().RUN.get("sector", 1)))["extent"]
func _pos(n: Dictionary) -> Vector3:
	return System.stop_position(n, _C().RUN["map"]["cols"].size(), int(_C().RUN.get("sector", 1)))
func _entry_pos() -> Vector3:
	var first = _pos({"col": 0, "y": 0.5})
	var next = _pos({"col": 1, "y": 0.5})
	return first - (next - first).normalized() * 16.0

# ---------------- building the sector ----------------
func sync() -> void:
	sheet_veil.visible = not backdrop
	var C = _C()
	if C == null or C.RUN == null: return
	if intel == null or intel.C != C: intel = Intel.new(C)
	intel.ai_level = ui.ai_level
	if ui.get("map_quality") != null and str(ui.map_quality) != quality:
		quality = str(ui.map_quality); _sig = ""
	var m = C.RUN["map"]
	var sig = str(C.RUN["sector"]) + "|" + str(m.get("fac")) + "|" + str(m["edges"].hash()) + "|" + str(m.get("region")) + "|" + quality
	if sig != _sig:
		if not loading: _load_sector(sig)
		return
	elif token != null and C.RUN.get("pos") != _last_pos and not _flying:
		_last_pos = C.RUN.get("pos"); _arrive(false)
	_refresh()

func _load_sector(sig: String) -> void:
	loading = true
	var cover := Loading.new()
	add_child(cover)
	# Paint the cover before building models or uploading textures.
	await get_tree().process_frame
	await get_tree().process_frame
	_build(sig)
	_last_pos = _C().RUN.get("pos")
	_refresh()
	await sector_world.wait_ready()
	await Loading.settle(get_tree())
	_arrive(true)
	cover.queue_free()
	loading = false
	# Changes made during loading get their own covered rebuild.
	sync()
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
# A wreck from A4's real death pieces (gen/wreck/<CODE>_wreck.scn, G2's asset build): the chunks of the ship drifted
# apart and turned, smouldering at the torn edges. null when the build has no wreck pieces (the cloud sandbox).
func _wreck(fac: String, cls: String, length: float) -> Node3D:
	var code = _code_for(fac, cls)
	if code == "": return null
	var path = "res://gen/wreck/%s_wreck.scn" % code
	if not ResourceLoader.exists(path): return null
	var ps = load(path)
	if not (ps is PackedScene): return null
	var inst: Node3D = ps.instantiate()
	var root = Node3D.new(); root.add_child(inst); root.scale = Vector3.ONE * length
	var chunks = inst.find_children("*", "MeshInstance3D", true, false)
	for ch in chunks:
		var c: MeshInstance3D = ch
		var ctr = c.get_aabb().get_center()
		var out = Vector3(ctr.x, ctr.y * 0.5, ctr.z).normalized() if ctr.length() > 0.001 else Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)).normalized()
		c.position += out * _rng.randf_range(0.05, 0.16) + Vector3(0, _rng.randf_range(-0.04, 0.04), 0)
		c.rotate_object_local(Vector3(_rng.randf(), _rng.randf(), _rng.randf()).normalized(), _rng.randf_range(0.1, 0.45))
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if quality != "low" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# the torn edge still burns: a hot glow and a little light at the break
		var gp = c.position + ctr * 0.6
		var g = sys.glow(inst, Color(1.0, 0.45, 0.12, 1.0), 0.28, gp, 2.2, 1.2, 1.0); g.scale = Vector3.ONE * 0.28
	var lt = OmniLight3D.new(); lt.light_color = Color(1.0, 0.42, 0.15); lt.light_energy = 1.4; lt.omni_range = 0.9; inst.add_child(lt)
	return root
# a soft cool fill from the camera's side onto a real hull whose far side the Hollow Sun leaves black
func _hull_fill(parent: Node3D, at: Vector3, rng: float) -> void:
	var l = OmniLight3D.new(); l.light_color = Color(0.75, 0.82, 1.0); l.light_energy = 1.6; l.omni_range = rng; l.omni_attenuation = 1.2
	l.position = at; l.shadow_enabled = false; parent.add_child(l)
func _code_for(fac: String, cls: String) -> String:
	if not ResourceLoader.exists(HT_PATH): return ""
	return load(HT_PATH).code_for(fac, cls)
func _build(sig: String) -> void:
	_sig = sig
	if _arrival_tween != null: _arrival_tween.kill()
	_flying = false; _flight_id = ""; _wake_samples.clear()
	_apply_quality()
	var C = _C(); var m = C.RUN["map"]; var fac = m.get("fac", "hegemony")
	if root3 != null: root3.queue_free()
	root3 = Node3D.new(); vp.add_child(root3)
	_nodes.clear(); _lanes.clear(); _patrols.clear(); _sync_lights.clear()
	var base_sig = str(C.RUN["sector"]) + "|" + str(fac) + "|" + str(m["edges"].hash())   # preserve each stop's existing seed
	_base_sig = base_sig; _rng.seed = hash(base_sig)
	sys = System.new(); sys.rng = _rng; sys.q = 1.0 if quality != "low" else 0.0; sys.backdrop_k = BACKDROP_K
	sys.set_sector(int(C.RUN["sector"]))
	sys.region = str(m.get("region", ""))
	env.ambient_light_energy = sys.approach["ambient"]; _fill.light_energy = sys.approach["fill"]
	props = Props.new(sys); _spinners.clear(); _drones.clear()
	sector_world = World.new(); root3.add_child(sector_world)
	var shell := get_tree().root.get_node_or_null("Main")
	var bake_quality := str(shell.settings.get("quality", "max")) if shell != null else "max"
	sector_world.prepare_sector(env, C.RUN, bake_quality)
	env.background_energy_multiplier = BACKDROP_K   # the sky (nebula, stars, its sun) at about half: it stops fighting the routes and the words
	# The baked nebula's broad red haze still competed with the routes in the first capture. Quiet just the gas again.
	sys.approach_sky(env)
	sys.sector_world = sector_world
	sys.backdrop(root3, fac, max(1.0, ui.k))
	var hs = sys.hollow_sun(root3, SUN_R); _debris = hs["debris"]
	_tier_lights(hs.get("light"))
	_rng.seed = hash(base_sig) + 7
	for col in m["cols"]:
		for n in col: _add_node(n)
	# the enemy's light over the far end of the system, where its flagship waits
	var L = System.look(fac); var bpos = _pos(m["cols"][m["cols"].size() - 1][0])
	root3.add_child(sys.mi(sys.flat(44, 44), sys.mat("TERR", {"col": Color(L["main"], 0.18 * BACKDROP_K)}), bpos + Vector3(0, -0.3, 0)))
	for e in m["edges"]: _add_lane(e[0], e[1])
	_add_entry_lanes()
	_add_patrols()
	_build_region()
	token = _make_token(); root3.add_child(token); _token_sig = _fleet_sig()
	token.position = _token_home()
	_make_wake()
	_focus = 0; _kb = -1
	_fit_key = ""

# The Hollow Sun lights the stops in three tiers. A light cannot be dimmer for one model than for the next, so each tier has
# its own render layer and its own copy of the sun's light: the full one (with the shadows) for your stop and the next jumps,
# two weaker ones for the stops further on and the stops behind you.
func _tier_lights(sun) -> void:
	if not (sun is OmniLight3D): return
	sun.light_cull_mask = 0xFFFFF & ~(LAYER_AHEAD | LAYER_BEHIND | LAYER_SCENERY)
	for i in [1, 2]:
		var l = OmniLight3D.new(); l.light_color = sun.light_color; l.light_energy = sun.light_energy * TIER_LIGHT[i]
		l.omni_range = sun.omni_range; l.omni_attenuation = sun.omni_attenuation; l.shadow_enabled = sun.shadow_enabled and float(sys.approach["infall"]) > 0.0
		l.light_cull_mask = LAYER_AHEAD if i == 1 else LAYER_BEHIND
		sun.get_parent().add_child(l); l.position = sun.position
	var scenery_light = OmniLight3D.new(); scenery_light.light_color = sun.light_color; scenery_light.light_energy = sun.light_energy * 0.5
	scenery_light.omni_range = sun.omni_range; scenery_light.omni_attenuation = sun.omni_attenuation
	scenery_light.light_cull_mask = LAYER_SCENERY; sun.get_parent().add_child(scenery_light); scenery_light.position = sun.position

# The place belongs to the whole map. Its own seed cannot perturb stop models or the rules stream.
# Both sides of the route band stay open; all dressing sits below and outside its full lane width.
func _region_point(t: float, side: float = 1.0, gap: float = 12.0) -> Vector3:
	var columns = _C().RUN["map"]["cols"].size()
	return System.stop_position({"col": t * (columns - 1), "y": 1.0 if side > 0 else 0.0}, columns, int(_C().RUN["sector"])) + Vector3(0, -5, side * gap)

func _dead_hull(parent: Node3D, length: float, split: bool = false) -> Node3D:
	var body = Node3D.new(); parent.add_child(body)
	for half in ([-1.0, 1.0] if split else [0.0]):
		var hull = _hull("hegemony", "Battleship", length)
		if hull == null: continue
		body.add_child(hull); hull.position.x = half * 1.4
		var shader = Shader.new(); shader.code = System.SH.dead_hull(split)
		var material = ShaderMaterial.new(); material.shader = shader
		material.set_shader_parameter("base", Color(0.24, 0.25, 0.27)); material.set_shader_parameter("accent", Color(0.28, 0.29, 0.3))
		material.set_shader_parameter("windows", 0.0); material.set_shader_parameter("gain", 0.18)
		material.set_shader_parameter("cut_side", half); material.set_shader_parameter("cut_x", parent.global_position.x + half * 1.4)
		var stack = [hull]
		while not stack.is_empty():
			var node = stack.pop_back(); stack.append_array(node.get_children())
			if node is MeshInstance3D: node.material_override = material
			elif node is Sprite3D or node is Light3D: node.visible = false
		# A solid torn bulkhead seals each half. Decks and ribs read through the break.
		if split:
			props.part(body, props.box(0.18, length * 0.11, length * 0.23), props.hull_mat(Color(0.13, 0.12, 0.11), Color(0.22, 0.19, 0.16), 5, 0), Vector3(half * 1.4, 0, 0))
			for deck in 3:
				props.beam(body, Vector3(half * 1.55, (deck - 1) * length * 0.035, -length * 0.11), Vector3(half * 1.55, (deck - 1) * length * 0.035, length * 0.11), 0.16, material)
	return body

func _build_region() -> void:
	region_scenery = Node3D.new(); region_scenery.name = "RegionScenery"; root3.add_child(region_scenery)
	region_scenery.set_meta("region", sys.region)
	if not System.REGION_SCENERY.has(sys.region): return
	region_scenery.set_meta("scenery", System.REGION_SCENERY[sys.region])
	_rng.seed = hash(_base_sig + "|region|" + sys.region)
	var landmark = Node3D.new(); landmark.name = "Landmark"; region_scenery.add_child(landmark)
	landmark.position = _region_point(0.53, 1, 14)
	var grey = Color(0.28, 0.3, 0.33); var lamp = Color(0.55, 0.65, 0.72)
	match sys.region:
		"boneyard":
			_dead_hull(landmark, 29, true)
			for i in 4: sys.glow(landmark, Color(0.8, 0.24, 0.05), 1.0, Vector3(_rng.randf_range(-1.1, 1.1), 0.6, _rng.randf_range(-2.5, 2.5)), 3.0, 0.28, 0.25)
			for i in 15:
				var field = Node3D.new(); region_scenery.add_child(field); field.position = _region_point(float(i) / 14.0, 1.0 if i % 3 != 0 else -1.0, _rng.randf_range(10, 19))
				sys.wreck_scraps(field, 12 if quality != "low" else 5, 3.5)
				if i % 3 == 0: _dead_hull(field, _rng.randf_range(3, 6))
				_spinners.append([field, Vector3(0.3, 0.8, 0.2).normalized(), _rng.randf_range(0.008, 0.018)])
		"nebula":
			for i in 11:
				var bank = sys.clouds(region_scenery, Color(0.32, 0.16, 0.65), Color(0.08, 0.32, 0.65), 3 if quality != "low" else 2, 10.0, _region_point(float(i) / 10.0, 1, 4), 0.55, 0.12)
				bank.position.y = -13
				for cloud in bank.get_children(): cloud.material_override.set_shader_parameter("storm_rate", 0.45)
			sys.clouds(landmark, Color(0.3, 0.2, 0.7), Color(0.12, 0.42, 0.8), 8 if quality != "low" else 4, 5.0, Vector3.ZERO, 0.6, 0.22)
			sys.glow(landmark, Color(0.28, 0.45, 0.85), 13, Vector3.ZERO, 3.5, 0.38, 0.1)
			props.storm_core(landmark)
		"world":
			landmark.position.x += 22; landmark.position.z -= 2
			var planet = sys.planet(landmark, System.PLANETS[1], 10.5, Vector3.ZERO)
			# The contested planet uses the shared procedural surface with visible night settlements.
			planet.get_node("spin").material_override = sys.mat("PLANET", {"a": Color(0.25, 0.3, 0.23), "b": Color(0.045, 0.09, 0.16), "atmo": Color(0.25, 0.38, 0.52), "kind": 1.0, "seed": 17.0, "sun_pos": sys.sun_pos, "night": 0.12})
			var surface = planet.get_node("spin").material_override
			var shader = Shader.new(); shader.code = System.SH.PLANET.replace("vec3(0.92)", "vec3(0.32, 0.36, 0.4)").replace("ALBEDO = col;", "ALBEDO = col * 0.55;")
			surface.shader = shader
			for cloud in planet.get_node("spin").get_children():
				var cloud_shader = Shader.new(); cloud_shader.code = System.SH.CLOUDS.replace("vec3(0.95)", "vec3(0.22, 0.25, 0.28)")
				cloud.material_override.shader = cloud_shader
			for i in 3:
				var station = props.station(landmark, grey, lamp); station.scale = Vector3.ONE * 0.36
				station.position = Vector3(-15 + i * 13, -1, 9 if i == 1 else -9)
		"frontier":
			props.hollow_asteroid(landmark)
			for i in 14:
				var field = Node3D.new(); region_scenery.add_child(field); field.position = _region_point(float(i) / 13.0, 1.0 if i % 3 != 0 else -1.0, 14)
				props.region_rocks(field, 22 if quality != "low" else 8, 3.5 if i % 3 == 0 else 2.0)
				if i in [2, 6, 10]: props.mining_rig(field, 1.1)
		"deep":
			landmark.visible = false
			for i in 3:
				var dead = Node3D.new(); region_scenery.add_child(dead); dead.position = _region_point(0.2 + i * 0.28, 1, 20)
				_dead_hull(dead, 3.5)
				if i == 1:
					var beacon = props.light(dead, Vector3(0, 0.6, 0), lamp, 0.6, true)
					props.blinkers.back()[2] = 7.0
	var parts = _parts(region_scenery)
	var fill = DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-48, -28, 0); fill.light_color = Color(0.65, 0.72, 0.8)
	fill.light_energy = 0.8; fill.light_cull_mask = LAYER_SCENERY; region_scenery.add_child(fill)
	for visual in parts["vis"]: visual.layers = LAYER_SCENERY
	for light in parts["lights"]: light[0].light_energy *= 0.4; light[0].light_cull_mask = LAYER_SCENERY
	for gain in parts["gains"]: gain[0].set_shader_parameter(gain[1], gain[2] * 0.4); gain[0].set_meta("dimk", 0.4)
	for material in parts["std"]: material[0].emission_energy_multiplier *= 0.4

# ---------------- stop scenes ----------------
# Bows point toward the preceding leg, where the player approaches from. ShipView's bow is local +X.
func _enemy_fleet(obj: Node3D, n: Dictionary, fac: String) -> float:
	var t = str(n["type"])
	var before = _pos({"col": maxf(-1.0, float(n["col"]) - 1.0), "y": 0.5})
	var toward = (before - _pos(n)).normalized()
	var heading = atan2(-toward.z, toward.x)
	var formation = Node3D.new(); formation.name = "EnemyFleet"; formation.rotation.y = heading
	obj.add_child(formation)
	formation.scale = Vector3.ONE * 1.25
	var cls = "Cruiser" if t == "elite" else "Destroyer"
	var length = 6.6 if t == "elite" else 5.8
	if t == "boss":
		var tpl = _C().FACTIONS[fac].get("boss")
		cls = str(_C().HULLS[tpl]["cls"]); length = 12.0
	var lead = _hull(fac, cls, length)
	if lead != null:
		lead.name = "Leader"; lead.position = Vector3(0, 1.8, 0); formation.add_child(lead)
		_map_ship_rim(lead)
	if t != "boss":
		for i in 2:
			var escort = _hull(fac, "Frigate", 3.8)
			if escort == null: continue
			escort.name = "Escort%d" % i
			escort.position = Vector3(-2.0 - float(i) * 0.5, 1.5, -2.4 if i == 0 else 2.4)
			escort.rotation.y = -0.08 if i == 0 else 0.12
			formation.add_child(escort)
			_map_ship_rim(escort)
	# A local neutral key keeps dark hulls readable even in the well. The normal stop tiers dim it too.
	var fill = OmniLight3D.new(); fill.light_color = Color(0.82, 0.87, 1.0)
	fill.light_energy = 8.0; fill.omni_range = 16.0; fill.omni_attenuation = 0.5
	fill.position = Vector3(-2, 5, 6); fill.shadow_enabled = false; obj.add_child(fill)
	return (4.6 if t == "boss" else 3.6) * 1.25

func _map_ship_rim(hull: Node3D) -> void:
	for mesh in hull.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		for surface in mesh.mesh.get_surface_count():
			var source = mesh.get_active_material(surface)
			if source is BaseMaterial3D:
				var material = source.duplicate(); material.rim_enabled = true; material.rim = maxf(material.rim, 0.28); material.rim_tint = 0.15
				mesh.set_surface_override_material(surface, material)

var _base_sig := ""
func _add_node(n: Dictionary) -> void:
	_rng.seed = hash(_base_sig + "|" + str(n["id"]))
	var C = _C(); var pp = _polar(n); var p = _pos(n); var obj = Node3D.new(); obj.position = p; root3.add_child(obj)
	var t = n["type"]; var mats = []; var top = 2.0
	var gold = Color("#d0a64b"); var teal = Color("#5fb3a6"); var cyan = Color("#62ccff")
	var fight = t in ["battle", "elite", "boss"]
	var nfac = C.nodeFaction(n) if fight else ""
	var d = {"n": n, "pos": p, "theta": pp.x, "r": pp.y, "fac": nfac if nfac != "" else str(C.RUN["map"]["fac"])}
	if fight:
		top = _enemy_fleet(obj, n, d["fac"])
	else:
		match t:
			"shipyard":
				# a construction gantry round a hull being built, floodlit, welding sparks on the work
				var PL = System.look(C.RUN["fac"])   # the gantry alone (no planet jammed in behind it)
				var gy = props.gantry(obj, 6.4, 2.8, 3.0, Color(0.46, 0.47, 0.5), PL["main"]); gy.position = Vector3(0, 0.6, 0); gy.rotation_degrees = Vector3(0, -25, 0)
				var hb = _hull(C.RUN["fac"], "Cruiser", 5.2)
				if hb != null: hb.position = Vector3(0, 1.8, 0); gy.add_child(hb)
				else: props.part(gy, props.box(4.6, 0.8, 1.2), props.hull_mat(Color(0.4, 0.4, 0.42), PL["main"]), Vector3(0, 1.2, 0))
				props.sparks(gy, Vector3(0, 1.5, 0), 1.8, 6 if quality != "low" else 3)
				top = 3.8
			"drydock":
				# a dock frame round a docked hull, work lights on it, drones at the plates
				var DL = System.look(C.RUN["fac"])   # the dock alone
				var df = props.dock_frame(obj, 5.2, 2.2, 2.6, Color(0.44, 0.46, 0.5), teal); df.position = Vector3(0, 1.8, 0); df.rotation_degrees = Vector3(0, -20, 0)
				var hk = _hull(C.RUN["fac"], "Frigate", 4.0)
				_hull_fill(df, Vector3(0, 1.4, 2.2), 6.0)   # light the docked hull's shadow side
				if hk != null: df.add_child(hk)
				else: props.part(df, props.box(3.6, 0.6, 0.9), props.hull_mat(Color(0.4, 0.4, 0.42), DL["main"]))
				for i in (4 if quality != "low" else 2): _drones.append([props.drone(obj, teal, Color(0.5, 0.52, 0.56)), Vector3(0, 1.8, 0), _rng.randf_range(1.4, 2.2), _rng.randf_range(0.3, 0.6) * (1 if i % 2 == 0 else -1), _rng.randf() * TAU, _rng.randf_range(-0.6, 0.8)])
				top = 3.4
			"field":
				# a repair tender: the hull, two lattice crane arms with floodlights, a swarm of drones, welding sparks
				var green = Color("#7ddc6a"); var FL = System.look(C.RUN["fac"])
				var tn = Node3D.new(); tn.position = Vector3(0, 1.8, 0); tn.rotation_degrees = Vector3(0, -30, 0); obj.add_child(tn)
				var tend = _hull(C.RUN["fac"], "Frigate", 3.6)
				_hull_fill(tn, Vector3(0, 1.2, 2.4), 6.0)
				if tend != null: tn.add_child(tend)
				else: props.part(tn, props.box(3.0, 0.6, 0.8), props.hull_mat(Color(0.42, 0.43, 0.46), FL["main"]))
				var am = props.hull_mat(Color(0.45, 0.46, 0.48), green, 8.0, 0.0, 0.8)
				for sz in [-1.0, 1.0]:
					props.truss(tn, Vector3(0.2, 0.3, sz * 0.4), Vector3(1.4, 0.9, sz * 1.5), 0.26, am, 3)
					props.truss(tn, Vector3(1.4, 0.9, sz * 1.5), Vector3(2.4, 0.4, sz * 1.1), 0.22, am, 2)
					props.spot(tn, Vector3(2.4, 0.4, sz * 1.1), Vector3(2.6, -0.6, 0), Color(0.8, 1.0, 0.8), 2.4, 5.0)
				props.sparks(tn, Vector3(2.4, -0.1, 0), 0.6, 4 if quality != "low" else 2)
				for i in (6 if quality != "low" else 3): _drones.append([props.drone(obj, green, Color(0.5, 0.52, 0.55)), Vector3(0, 1.8, 0), _rng.randf_range(1.6, 2.8), _rng.randf_range(0.35, 0.7) * (1 if i % 2 == 0 else -1), _rng.randf() * TAU, _rng.randf_range(-0.7, 0.9)])
				top = 3.0
			"event":
				sys.clouds(obj, Color(0.25, 0.75, 1.0), Color(0.55, 0.3, 1.0), 6 if quality != "low" else 3, 1.0, Vector3(0, 1.8, 0), 0.6)
				var m7 = _mat(cyan, 3.0, 0.0, 0.2); mats.append(m7)
				obj.add_child(sys.mi(sys.sphere(0.32, 16, 8), m7, Vector3(0, 1.8, 0)))
				sys.glow(obj, cyan, 3.4, Vector3(0, 1.8, 0), 2.2, 0.8, 1.0)
				top = 3.2
	# a soft cool fill over built stops, so their plating reads on the side away from the Hollow Sun
	if t in ["shipyard", "drydock", "field"]:
		var fl = OmniLight3D.new(); fl.light_color = Color(0.7, 0.78, 1.0); fl.light_energy = 2.4; fl.omni_range = 16.0; fl.omni_attenuation = 1.1
		fl.position = Vector3(3.0, 5.0, 4.5); fl.shadow_enabled = false; obj.add_child(fl)
		var ky = OmniLight3D.new(); ky.light_color = Color(1.0, 0.9, 0.78); ky.light_energy = 1.1; ky.omni_range = 15.0; ky.omni_attenuation = 1.0   # a faint key from the camera's side
		ky.position = Vector3(-2.0, 7.0, 8.0); ky.shadow_enabled = false; obj.add_child(ky)
		fl.light_energy *= float(sys.approach["local_fill"]); ky.light_energy *= float(sys.approach["local_fill"])
	# no ring, halo or hover glow under a stop (the Briefing build): the list and the map's words say what you can do there
	var big = RING_R * (1.55 if t == "boss" else 1.0)
	var rival = null
	if t == "battle" and C.RUN.get("foes") != null:
		var f = C.nodeFaction(n)
		if f != C.RUN["map"]["fac"] and C.FACTIONS.has(f): rival = f
	d.merge({"obj": obj, "mats": mats, "top": top, "rival": rival, "ring_r": big, "tier": -1, "sc": 1.0, "nem": false})
	_nodes[n["id"]] = d
func _torus(r0: float, r1: float) -> TorusMesh:
	var t = TorusMesh.new(); t.inner_radius = r0; t.outer_radius = r1; t.rings = 48; t.ring_segments = 8; return t
# The chart is tone mapped (ACES, then the contrast and saturation set in _ready), which washes a saturated colour toward
# white: lime drawn as lime comes out a pale yellow, and no longer matches the lime of the marker and the button. This
# finds the colour to draw so that the screen shows the colour asked for, as near as the tone map can reach, and never
# brighter than 1.0 in any channel (so a route cannot bloom). One search per colour, then cached.
static var _shown_cache := {}
static func _lin(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
static func _srgb(v: float) -> float:
	v = clampf(v, 0.0, 1.0)
	return v * 12.92 if v <= 0.0031308 else 1.055 * pow(v, 1.0 / 2.4) - 0.055
static func _aces_curve(x: float) -> float: return (x * (x + 0.0245786) - 0.000090537) / (x * (0.983729 * x + 0.432951) + 0.238081)
static func _shown(lin: Vector3, exposure: float, white: float, contrast: float, sat: float) -> Vector3:   # linear in, what the screen shows (sRGB 0..1)
	var c = lin * exposure * 1.8
	var v = Vector3(_aces_curve(0.59719 * c.x + 0.35458 * c.y + 0.04823 * c.z), _aces_curve(0.07600 * c.x + 0.90834 * c.y + 0.01566 * c.z), _aces_curve(0.02840 * c.x + 0.13383 * c.y + 0.83777 * c.z))
	var o = Vector3(1.60475 * v.x - 0.53108 * v.y - 0.07367 * v.z, -0.10208 * v.x + 1.10813 * v.y - 0.00605 * v.z, -0.00327 * v.x - 0.07276 * v.y + 1.07602 * v.z) / _aces_curve(white * 1.8)
	var sr = Vector3(_srgb(o.x), _srgb(o.y), _srgb(o.z))
	sr = (sr - Vector3.ONE * 0.5) * contrast + Vector3.ONE * 0.5
	var g = (sr.x + sr.y + sr.z) / 3.0
	sr = Vector3(g, g, g) + (sr - Vector3(g, g, g)) * sat
	return Vector3(clampf(sr.x, 0.0, 1.0), clampf(sr.y, 0.0, 1.0), clampf(sr.z, 0.0, 1.0))
func for_screen(want: Color) -> Color:
	var key = want.to_html(false)
	if _shown_cache.has(key): return Color(_shown_cache[key], want.a)
	var ex = env.tonemap_exposure if env != null else 1.0; var wh = env.tonemap_white if env != null else 6.0
	var co = env.adjustment_contrast if env != null else 1.0; var sa = env.adjustment_saturation if env != null else 1.0
	var target = Vector3(want.r, want.g, want.b)
	var best = Vector3(_lin(want.r), _lin(want.g), _lin(want.b)); var bd = 1e9
	var lo = Vector3.ZERO; var hi = Vector3.ONE
	for stage in 3:   # a coarse grid, then twice finer round the best
		var n = 12; var at = best
		for i in n + 1:
			for j in n + 1:
				for l in n + 1:
					var x = Vector3(lerpf(lo.x, hi.x, float(i) / n), lerpf(lo.y, hi.y, float(j) / n), lerpf(lo.z, hi.z, float(l) / n))
					var d = _shown(x, ex, wh, co, sa).distance_squared_to(target)
					if d < bd: bd = d; at = x
		best = at
		var span = (hi - lo) / float(n)
		lo = Vector3(maxf(0.0, best.x - span.x), maxf(0.0, best.y - span.y), maxf(0.0, best.z - span.z))
		hi = Vector3(minf(1.0, best.x + span.x), minf(1.0, best.y + span.y), minf(1.0, best.z + span.z))
	var out = Color(_srgb(best.x), _srgb(best.y), _srgb(best.z))   # the shader reads the colour as sRGB (source_color)
	_shown_cache[key] = out
	return Color(out, want.a)
# A pale line: the sage at a share of its strength as the eye reads it on the dark chart. The line blends in linear light,
# where an alpha of 0.2 shows as about half strength (the first PC capture did), so the alpha is found from the tone map.
static var _pale_cache := {}
func pale(share: float) -> Color:
	var base = for_screen(Color(GS.BONE, 1.0))
	if _pale_cache.has(share): return Color(base, _pale_cache[share])
	var ex = env.tonemap_exposure if env != null else 1.0; var wh = env.tonemap_white if env != null else 6.0
	var co = env.adjustment_contrast if env != null else 1.0; var sa = env.adjustment_saturation if env != null else 1.0
	var lin = Vector3(_lin(base.r), _lin(base.g), _lin(base.b))
	var zero = _shown(Vector3.ZERO, ex, wh, co, sa)   # what black shows as (the contrast setting moves it a little)
	var want = (GS.BONE.r + GS.BONE.g + GS.BONE.b) / 3.0 * share
	var lo = 0.0; var hi = 1.0
	for i in 24:
		var mid = (lo + hi) * 0.5; var o = _shown(lin * mid, ex, wh, co, sa) - zero
		if (o.x + o.y + o.z) / 3.0 < want: lo = mid
		else: hi = mid
	_pale_cache[share] = (lo + hi) * 0.5
	return Color(base, _pale_cache[share])
# A route: one flat line in the chart plane along the curve the fleet flies. Lime and solid to a next jump, thin and pale
# otherwise (_paint_lanes). No bloom, no halo, no flow, no hazard chevrons.
func _add_lane(a: String, b: String) -> void:
	var A = _nodes[a]["pos"]; var B = _nodes[b]["pos"]
	var curve: Curve3D = sys.lane_curve(A, B); var L := curve.get_baked_length()
	var trim_a = _nodes[a]["ring_r"] * 1.05; var trim_b = _nodes[b]["ring_r"] * 1.05
	var mat = sys.mat("LANE_FLAT", {"col": Color(GS.BONE, GS.PALE), "px": 0.6})
	var mi = sys.mi(sys.route_ribbon(curve, 1.6, trim_a, trim_b), mat, Vector3(0, 0.12, 0)); mi.extra_cull_margin = L
	root3.add_child(mi)
	_lanes[a + ">" + b] = {"a": a, "b": b, "mi": mi, "mat": mat}
# the way in: before a sector's first jump the fleet waits off the chart's edge, and a lime line runs from it to each first stop
func _add_entry_lanes() -> void:
	var C = _C(); var from = _entry_pos()
	for n in C.RUN["map"]["cols"][0]:
		if not _nodes.has(n["id"]): continue
		var curve: Curve3D = sys.lane_curve(from, _nodes[n["id"]]["pos"]); var L := curve.get_baked_length()
		var mat = sys.mat("LANE_FLAT", {"col": Color(GS.MAP_EMBER, 1.0), "px": 1.25})
		var mi = sys.mi(sys.route_ribbon(curve, 1.6, 2.0, _nodes[n["id"]]["ring_r"] * 1.05), mat, Vector3(0, 0.12, 0)); mi.extra_cull_margin = L
		root3.add_child(mi)
		_lanes["@>" + str(n["id"])] = {"a": "@", "b": str(n["id"]), "mi": mi, "mat": mat}
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
	var node = _hull(fac, "Frigate", 3.0)
	if node == null:
		var pm = PrismMesh.new(); pm.size = Vector3(0.5, 1.2, 0.2)
		node = Node3D.new(); var m = sys.mi(pm, _mat(L["main"], 1.0)); m.rotation_degrees = Vector3(0, 0, -90); node.add_child(m)
	# a patrol is scenery, not a stop: it sits in the dim light tier so it never reads as part of your fleet or as a place to go
	for v in node.find_children("*", "VisualInstance3D", true, false):
		if not (v is Light3D): v.layers = LAYER_AHEAD
		if v is Sprite3D: v.modulate = Color(v.modulate.r * 0.45, v.modulate.g * 0.45, v.modulate.b * 0.45, v.modulate.a)
	node.scale *= 0.8
	var lt = OmniLight3D.new(); lt.light_color = L["light"]; lt.light_energy = 0.3; lt.omni_range = 3.0; lt.light_cull_mask = LAYER_AHEAD; node.add_child(lt)
	if int(L["look"]) == 1: _sync_lights.append([lt, 0.3])
	root3.add_child(node)
	_patrols.append([node, c + Vector3(0, 2.6, 0), r, sp, _rng.randf() * TAU])
func _make_token() -> Node3D:   # your fleet at map scale: the flagship's real hull (A4's kit ship when it is in the build) and up to two escorts
	var C = _C(); var t = Node3D.new(); var L = System.look(C.RUN["fac"])
	_wake_samples.clear()
	_engine_mounts.clear()
	var fs = C.flagshipOf()
	var h = null
	if fs != null: h = _hull(C.RUN["fac"], str(C.HULLS[fs["tpl"]].get("cls", "Cruiser")), 8.5)
	if h != null:
		t.add_child(h)
		_add_engine_mounts(h)
	else:
		var hull = PrismMesh.new(); hull.size = Vector3(1.4, 3.4, 0.5)
		var hm = sys.mi(hull, sys.std(Color(0.82, 0.74, 0.58), 0.4, 0.8, 0.3)); hm.rotation_degrees = Vector3(0, 0, -90); t.add_child(hm)
		_engine_mounts.append(Vector3(-1.7, 0, 0))
	var stern := Vector3.ZERO
	for mount in _engine_mounts: stern += mount
	stern /= max(1, _engine_mounts.size())
	var esc = C.RUN["fleet"].filter(func(x): return fs == null or x["uid"] != fs["uid"])
	esc = C.ssort(esc, func(a, b): return float(C.or_(C.HULLS[b["tpl"]].get("cp"), 1)) - float(C.or_(C.HULLS[a["tpl"]].get("cp"), 1)))
	for i in range(min(2, esc.size())):
		var e = _hull(C.RUN["fac"], str(C.HULLS[esc[i]["tpl"]].get("cls", "Frigate")), 4.6)
		if e != null:
			e.position = Vector3(-3.8, -0.4, 3.0 if i == 0 else -3.0); t.add_child(e)
			_add_engine_mounts(e)
	sys.glow(t, L["light"], 3.6, stern, 2.0, 0.6)
	var l = OmniLight3D.new(); l.light_color = L["light"]; l.light_energy = 2.4; l.omni_range = 9.0; l.position = stern; t.add_child(l)
	return t

func _add_engine_mounts(h: Node3D) -> void:
	# _hull wraps the ship view at map scale. Read its actual engine sprites
	# through both transforms, including the escort's formation offset.
	var sv = h.get_child(0)
	for engine in sv.engines:
		_engine_mounts.append(h.transform * sv.transform * engine.position)

func _engine_positions() -> Array:
	var positions: Array = []
	# The token and wake are siblings, so keep history in their parent's space.
	for mount in _engine_mounts: positions.append(token.transform * mount)
	return positions
func _token_home() -> Vector3:
	var C = _C(); var pos = C.RUN.get("pos")
	if pos != null and _nodes.has(pos): return _nodes[pos]["pos"] + TOKEN_OFF + Vector3(0, _nodes[pos]["top"], 0)
	return _entry_pos() + Vector3(0, 3.0, 0)   # just before the first jump, clear of the first stop

# ---------------- state ----------------
func _avail() -> Array:
	var C = _C()
	return C.page["data"]["avail"] if C.page["kind"] == "map" else []
func _find_reachable() -> void:
	_reachable.clear()
	var pending: Array = _C().availableNodes().duplicate()
	var next := {}
	for edge in _C().RUN["map"]["edges"]:
		if not next.has(edge[0]): next[edge[0]] = []
		next[edge[0]].append(edge[1])
	while not pending.is_empty():
		var id = pending.pop_back()
		if _reachable.has(id): continue
		_reachable[id] = true
		pending.append_array(next.get(id, []))
func _refresh() -> void:
	var C = _C(); var av = _avail(); _card_key = ""
	_find_reachable()
	_danger.clear()
	_kb_order.clear()
	for id in _nodes:
		var d = _nodes[id]; var n = d["n"]; var done = C.jt(n.get("done"))
		if n["type"] in ["battle", "elite", "boss"] and d["fac"] != C.nodeFaction(n):
			root3.remove_child(d["obj"]); d["obj"].queue_free()
			_add_node(n); d = _nodes[id]
		var current = C.RUN.get("pos") == id
		var bypassed = not current and not done and not _reachable.has(id)
		# your stop and the next jumps keep full models; stops further on are smaller and darker; behind you or cut off, dimmer still
		_set_tier(d, 0 if (current or av.has(id)) else (2 if (done or bypassed) else 1))
		if not done: _danger[id] = intel.danger(n)
		d["nem"] = not done and n["type"] in ["battle", "elite"] and View.nem_node_is(C, n)
		if not done or current: _kb_order.append(id)
	_kb_order.sort_custom(func(a, b):
		var na = _nodes[a]["n"]; var nb = _nodes[b]["n"]
		return float(na["col"]) < float(nb["col"]) if float(na["col"]) != float(nb["col"]) else float(na["y"]) < float(nb["y"]))
	if _hot != "" and not av.has(_hot): _routes = intel.routes_through(_hot)
	_paint_lanes()
	var fsig = _fleet_sig()
	if token != null and fsig != _token_sig and not _flying:   # the fleet changed (a hull bought, sold or lost): redraw the token
		_token_sig = fsig; var p0 = token.position; token.queue_free(); token = _make_token(); root3.add_child(token); token.position = p0
	if not _flying and token != null: token.position = _token_home()
	overlay.queue_redraw()
var _kb_order: Array = []     # the stops the arrow keys walk, by column then height
# One stop's tier: its render layer (which copy of the sun's light reaches it), its own lights, glows and lit windows, and the
# size it eases to (_process). The parts are gathered once per stop.
func _set_tier(d: Dictionary, tier: int) -> void:
	if int(d.get("tier", -1)) == tier: return
	var first = int(d.get("tier", -1)) < 0
	d["tier"] = tier
	if not d.has("parts"): d["parts"] = _parts(d["obj"])
	var f: float = TIER_LIGHT[tier]; var layer = [1, LAYER_AHEAD, LAYER_BEHIND][tier]
	var P = d["parts"]
	# A model that changes its render layer while it is in the scene leaves the engine's light pairing out of step (it
	# logged "indexing did not unpair geometries from light" when the sector was torn down). So the stop steps out of the
	# scene, takes its new layer, and steps back in.
	var obj: Node3D = d["obj"]; var par = obj.get_parent() if int(d.get("layer", 1)) != layer else null
	if par != null: par.remove_child(obj)
	d["layer"] = layer
	for v in P["vis"]:
		if is_instance_valid(v): v.layers = layer
	if par != null: par.add_child(obj)
	for l in P["lights"]:
		if is_instance_valid(l[0]):
			l[0].light_energy = l[1] * f
			l[0].light_cull_mask = layer
	for g in P["gains"]:
		g[0].set_shader_parameter(g[1], g[2] * f); g[0].set_meta("dimk", f)
	for sp in P["sprites"]:
		if is_instance_valid(sp[0]): sp[0].modulate = Color(sp[1].r * f, sp[1].g * f, sp[1].b * f, sp[1].a)
	for m in P["std"]: m[0].emission_energy_multiplier = m[1] * f
	if first:   # the map opens with every stop already at its size
		d["sc"] = TIER_SCALE[tier]; d["obj"].scale = Vector3.ONE * float(d["sc"])
func _parts(root: Node) -> Dictionary:
	var out = {"vis": [], "lights": [], "gains": [], "sprites": [], "std": [], "aabb": AABB()}
	var stack = [root]; var seen = {}; var inv = root.global_transform.affine_inverse() if root.is_inside_tree() else Transform3D.IDENTITY
	while not stack.is_empty():
		var nd = stack.pop_back()
		for ch in nd.get_children(): stack.append(ch)
		if nd is Light3D: out["lights"].append([nd, nd.light_energy]); continue
		if nd is Sprite3D: out["sprites"].append([nd, nd.modulate])
		if nd is VisualInstance3D: out["vis"].append(nd)
		var m = nd.material_override if nd is GeometryInstance3D else null
		# the model's own bounds, in the stop's space: solid meshes only (no glow, cloud or orbit sheets, no scattered rocks)
		if nd is MeshInstance3D and nd.mesh != null and root.is_inside_tree() and not (m is ShaderMaterial and m.shader != null and m.shader.code.contains("blend_add")):
			var bb: AABB = inv * nd.global_transform * nd.get_aabb()
			if bb.size.length() < 16.0: out["aabb"] = bb if out["aabb"].size == Vector3.ZERO else out["aabb"].merge(bb)
		if m == null or seen.has(m): continue
		seen[m] = true
		if m is ShaderMaterial and m.has_meta("map_mat") and m.shader != null:   # the map's own shaders: their brightness is "gain", "light" or "ember"
			for u in m.shader.get_shader_uniform_list():
				if not (str(u["name"]) in ["gain", "light", "ember"]): continue
				var b = m.get_shader_parameter(u["name"])
				if b == null: b = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), u["name"])
				if b is float or b is int: out["gains"].append([m, str(u["name"]), float(b)])
		elif m is StandardMaterial3D and m.emission_enabled: out["std"].append([m, m.emission_energy_multiplier])
	return out
var _token_sig := ""
func _fleet_sig() -> String: return str(_C().RUN["fleet"].map(func(x): return str(x["uid"]) + str(x["tpl"]))) + str(_C().RUN.get("flagUid"))
func _route_lanes() -> Dictionary:   # the lanes of the safest way on through the stop you point at (they read a little brighter)
	var out = {}
	if _routes.is_empty(): return out
	var r = _routes[0]
	var p = [_C().RUN.get("pos")] + r["path"] if _C().RUN.get("pos") != null else r["path"]
	for i in range(p.size() - 1): out[str(p[i]) + ">" + str(p[i + 1])] = true
	return out
# The routes: lime and solid to a next jump (the one line you can fly now), one thin pale line for every other route, fainter
# when it is cut off. Routes behind the fleet are hidden. Two channels, colour and width (ui_spec.md 5.2). No blue routes.
func _paint_lanes() -> void:
	var C = _C(); var R = C.RUN; var av = _avail(); var lit = _route_lanes(); var kk = float(ui.k) if ui != null and ui.get("k") != null else 1.0
	var current_col = int(_nodes[R["pos"]]["n"]["col"]) if R.get("pos") != null and _nodes.has(R["pos"]) else -1
	for k in _lanes:
		var L = _lanes[k]
		if L["a"] == "@":
			if L.has("mi"): L["mi"].visible = R.get("pos") == null and av.has(L["b"])
			L["mat"].set_shader_parameter("col", for_screen(Color(GS.MAP_EMBER, 1.0))); L["mat"].set_shader_parameter("px", 1.25 * kk)
			continue
		var A = _nodes[L["a"]]["n"]; var Bn = _nodes[L["b"]]["n"]
		var behind = int(A["col"]) < current_col
		if L.has("mi"): L["mi"].visible = not behind
		var trav = C.jt(A.get("done")) and (C.jt(Bn.get("done")) or R.get("pos") == L["b"])
		var nxt = R.get("pos") == L["a"] and av.has(L["b"])
		var ahead = _reachable.has(L["a"]) and _reachable.has(L["b"])
		var past = not trav and not nxt and not ahead
		var col = pale(GS.PALE); var w = 0.6
		if trav or past: col = pale(GS.PALE_CUT)
		elif lit.has(k): col = pale(0.5)
		if nxt: col = for_screen(Color(GS.MAP_EMBER, 1.0)); w = 1.25
		if _flying and k == str(R.get("pos")) + ">" + _flight_id: col = for_screen(Color(GS.MAP_EMBER, 1.0)); w = 1.25
		L["mat"].set_shader_parameter("col", col); L["mat"].set_shader_parameter("px", w * kk)

func _arrive(new_sector: bool) -> void:   # the camera starts leaning on where the fleet is and settles back over the chart
	var C = _C(); var pos = C.RUN.get("pos")
	var at = _nodes[pos]["pos"] if pos != null and _nodes.has(pos) else _token_home()
	if new_sector:
		_fit(_free_rect())
		_cam_focus = _fit_target.lerp(sys.sun_pos, float(sys.approach["arrival_lean"]))
		_cam_zoom = sys.approach["arrival_zoom"]
	_arrive_t = 0.0
	_uz_t = 1.0; _pan_t = Vector3.ZERO
	if _arrival_tween != null: _arrival_tween.kill()
	var tw = create_tween(); _arrival_tween = tw; tw.set_trans(Tween.TRANS_SINE); tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "_cam_zoom", 1.0, float(sys.approach["arrival_seconds"]) if new_sector else 1.1)
	tw.parallel().tween_property(self, "_cam_focus", Vector3.ZERO, float(sys.approach["arrival_seconds"]) if new_sector else 1.1)

func _process(delta: float) -> void:
	if not visible or _C() == null or _C().RUN == null or root3 == null: return
	_t += delta
	var mp = get_local_mouse_position() / size.max(Vector2.ONE) - Vector2(0.5, 0.5)
	mp = mp.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	# the frame is fitted again when the fleet leaves the sector's edge (the waiting fleet no longer has to be in it)
	var fr = _free_rect(); var fk0 = str(size) + "|" + _sig + "|" + str(fr.position.round()) + str(fr.size.round()); var fk = fk0 + "|" + str(_C().RUN.get("pos") == null)
	if fk != _fit_key:
		var snap = not _fit_key.begins_with(fk0)   # a new sector or window: no easing
		_fit_key = fk; _fit(fr)
		if snap or _fit_dist_now <= 0.0: _fit_target_now = _fit_target; _fit_dist_now = _fit_dist
	var fe = 1.0 - exp(-delta * 2.5)
	_fit_target_now = _fit_target_now.lerp(_fit_target, fe); _fit_dist_now = lerpf(_fit_dist_now, _fit_dist, fe)
	_pan_keyboard(delta)
	if _flying: _advance_flight(delta)
	# the player's zoom and pan ease in; the arrival and jump moves layer on top
	var ke = 1.0 - exp(-delta * 7.0)
	_uz = lerp(_uz, _uz_t, ke); _pan = _pan.lerp(_pan_t, ke)
	var dist = _fit_dist_now * _cam_zoom * _uz
	var drift = Vector3(sin(_t * 0.05) * 1.0, sin(_t * 0.037) * 0.4, cos(_t * 0.043) * 0.7)   # small: the fitted frame must hold
	var base_t = _fit_target_now + _pan
	var target = base_t.lerp(_cam_focus, clamp((1.0 - _cam_zoom) / 0.4, 0.0, 1.0)) if _cam_focus != Vector3.ZERO else base_t
	cam.position = target + CAM_DIR * dist + drift * _cam_zoom * _uz + Vector3(mp.x * 1.4, -mp.y * 0.9, 0) * _uz
	cam.look_at(target, Vector3.UP)
	if _debris != null: _debris.rotate_y(delta * 0.012)
	for sp in _spinners:
		if is_instance_valid(sp[0]): sp[0].rotate_object_local(sp[1], delta * sp[2])
	for dr in _drones:   # repair drones working round the hull
		var a = dr[4] + _t * dr[3]
		dr[0].position = dr[1] + Vector3(cos(a) * dr[2], dr[5] + sin(_t * 1.3 + dr[4]) * 0.15, sin(a) * dr[2] * 0.7)
		dr[0].rotation.y = -a + (PI if dr[3] < 0 else 0.0)
	if props != null:
		for b in props.blinkers:   # running lights and welding sparks
			if is_instance_valid(b[0]):
				var ph = fmod(_t + b[1], b[2]) / b[2]
				b[0].material_override.set_shader_parameter("gain", (0.25 + 1.6 * exp(-ph * 9.0)) * float(b[0].material_override.get_meta("dimk", 1.0)))
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
		var ts: float = TIER_SCALE[clampi(int(_nodes[id]["tier"]), 0, 2)]   # a stop eases to its tier's size when you jump
		if absf(float(_nodes[id]["sc"]) - ts) > 0.001:
			_nodes[id]["sc"] = lerpf(float(_nodes[id]["sc"]), ts, 1.0 - exp(-delta * 6.0)); o.scale = Vector3.ONE * float(_nodes[id]["sc"])
	for pt in _patrols:
		var a = pt[4] + _t * pt[3]
		var p = pt[1] + Vector3(cos(a) * pt[2], sin(_t * 0.7 + pt[4]) * 0.3, sin(a) * pt[2] * 0.6)
		var nxt = pt[1] + Vector3(cos(a + 0.05) * pt[2], 0, sin(a + 0.05) * pt[2] * 0.6)
		pt[0].position = p
		if p.distance_to(nxt) > 0.001: pt[0].look_at(nxt, Vector3.UP); pt[0].rotate_object_local(Vector3.UP, PI * 0.5)
	if token != null and not _flying: token.position.y = _token_home().y + sin(_t * 1.4) * 0.2
	_update_wake()
	overlay.visible = not backdrop
	if backdrop:
		card.visible = false; return
	overlay.queue_redraw()
	_update_card()

# ---------------- labels, intel chips, route totals and the hover card ----------------
func _screen(p: Vector3) -> Vector2: return cam.unproject_position(p)
# ---------------- framing: every node, its scene and its labels inside the part of the screen the map really has ----------------
var _fit_key := ""
var _fit_target := Vector3(0, 0, 0.5)
var _fit_dist := 100.0
var _fit_target_now := Vector3(0, 0, 0.5)   # the frame in use, eased toward the fitted one
var _fit_dist_now := -1.0
func _free_rect() -> Rect2:   # right of the briefing column, clear of the text buttons (top right) and the purse (bottom right)
	var L = float(ui.px(COL_W + 96.0)); var Rr = size.x - float(ui.px(72)); var T = float(ui.px(104)); var Bt = size.y - float(ui.px(128))
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
	if bool(sys.approach["fit_sun"]):
		var sr = SUN_R * float(sys.approach["sun_scale"])
		for d in [Vector3(-sr * 3.0, 0, 0), Vector3(sr * 3.0, 0, 0), Vector3(0, sr * 1.9, sr * 2.3), Vector3(0, 0, sr * 3.9)]: pts.append(sys.sun_pos + d)
	if _C().RUN.get("pos") == null:   # the fleet waiting before the first jump, its escorts and its words
		for d in [Vector3(-8.0, 0, 0), Vector3(6.0, 0, 0), Vector3(0, 0, 9.0), Vector3(0, 4.0, 0)]: pts.append(_token_home() + d)
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
	cam.position = tgt + CAM_DIR * dist; cam.look_at(tgt, Vector3.UP)
	sys.sky_direction(cam, env)
# The words on the map (the Briefing build). Plain text with a dark halo, no strip or tag behind it (GS.halo_text; the
# campaign map exception to ui_style.md 3). Current and next stops keep their captions. Every other stop has a type glyph;
# a Nemesis meeting adds its red diamond above it. The tip card shows on hover or keyboard focus (_update_card).
func _draw_overlay() -> void:
	var C = _C()
	if C == null or C.RUN == null or root3 == null or cam.position.length_squared() < 1.0: return
	var av = _avail(); var s: float = ui.k; var pos = C.RUN.get("pos")
	var left = float(ui.px(COL_W)) + 8.0 * s
	_words.clear()
	var taken: Array = []   # icons, star, models and captions all share the same exclusion list
	var sun_rect := _sun_rect()
	taken.append(sun_rect); _words.append(sun_rect)
	for id in _nodes:   # type glyphs over each model; the Nemesis stays above its glyph
		var d = _nodes[id]
		if cam.is_position_behind(d["pos"]): continue
		var tp = _screen(d["pos"] + Vector3(0, (float(d["top"]) + 0.6) * float(d["sc"]), 0))
		tp.y -= (GS.STOP_ICON_PX * 0.5 + GS.STOP_ICON_GAP) * s
		var faded = int(d["tier"]) == 2
		var icon_scale = s * (GS.STOP_ICON_FADED if faded else 1.0)
		if tp.x > left:
			if id != pos:
				GS.stop_icon(overlay, tp, str(d["n"]["type"]), icon_scale, GS.STOP_ICON_FADED if faded else 1.0)
				var icon_box = Rect2(tp - Vector2.ONE * 12.0 * icon_scale, Vector2.ONE * 24.0 * icon_scale)
				taken.append(icon_box); _words.append(icon_box)
			if d["nem"]: GS.diamond(overlay, tp + Vector2(0, -20.0 * s), 5.0 * s, GS.NEM)
	var bodies = _nodes.keys()   # larger enemy groups also keep captions off models farther on
	for id in bodies:
		if _nodes.has(id) and not cam.is_position_behind(_nodes[id]["pos"]): taken.append(_body_rect(id, s))
	# where your fleet is
	var f18: Font = GS.sheet_medium(); var f14: Font = GS.sheet_body()
	if not _flying:
		var here = Vector2.ZERO; var nm = ""
		if pos != null and _nodes.has(pos): here = _screen(_nodes[pos]["pos"]); nm = View.here_name(C)
		elif pos == null and token != null: here = _screen(Vector3(token.position.x, 0.0, token.position.z))
		if here != Vector2.ZERO and here.x > left:
			var y = here.y + 44.0 * s
			if token != null:   # under the fleet's hulls: the flagship and the two escorts off its quarters
				for off in [Vector3.ZERO, Vector3(-3.8, -0.4, 3.0), Vector3(-3.8, -0.4, -3.0)]: y = max(y, _screen(token.position + off).y + 34.0 * s)
				here.x = lerp(here.x, _screen(token.position).x, 0.5)
				taken.append(Rect2(_screen(token.position) - Vector2(60.0, 40.0) * s, Vector2(120.0, 80.0) * s))
			if nm != "":
				var w = f18.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(21 * s)).x
				if Rect2(here.x - w * 0.5, y - 18.0 * s, w, 46.0 * s).intersects(sun_rect): y = sun_rect.end.y + 24.0 * s
				GS.halo_text(overlay, f18, Vector2(here.x - w * 0.5, y), nm, int(21 * s), GS.TEXT, s)
				taken.append(Rect2(here.x - w * 0.5, y - 18.0 * s, w, 24.0 * s)); _words.append(taken.back()); y += 22.0 * s
			var sub = "Your fleet is here"; var w2 = f14.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * s)).x
			GS.halo_text(overlay, f14, Vector2(here.x - w2 * 0.5, y), sub, int(17 * s), GS.TEXT2, s)
			taken.append(Rect2(here.x - w2 * 0.5, y - 14.0 * s, w2, 18.0 * s))
	# the next jumps: marker and name as one caption, under the model unless something is in the way
	var f20: Font = GS.sheet_medium(); var fs = int(21 * s); var m = 34.0 * s; var gp = 14.0 * s
	var lane_pts: Array = []   # points along the lime routes: a caption sits off them when it can
	var from = _nodes[pos]["pos"] if (pos != null and _nodes.has(pos)) else (Vector3(token.position.x, 0.0, token.position.z) if token != null else Vector3.ZERO)
	for id in av:
		if not _nodes.has(id): continue
		var cv: Curve3D = sys.lane_curve(from, _nodes[id]["pos"]); var cl = cv.get_baked_length()
		for j in 25: lane_pts.append(_screen(cv.sample_baked(cl * float(j) / 24.0)))
	for i in av.size():
		var id = av[i]
		if not _nodes.has(id) or cam.is_position_behind(_nodes[id]["pos"]): continue
		var base = _screen(_nodes[id]["pos"])
		if base.x < left: continue   # panned under the briefing column: its row still names it
		var nm = View.stop_name(C, _nodes[id]["n"])
		var tw = f20.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var cw = m + gp + tw
		var body = _body_rect(id, s)
		var cy = body.get_center().y - m * 0.5
		# beside the model first (as the mockup sets a name beside its marker), then under it, over it, and the four corners
		var cands = [Vector2(body.end.x + 8.0 * s, cy), Vector2(body.position.x - 8.0 * s - cw, cy),
			Vector2(base.x - cw * 0.5, body.end.y + 6.0 * s), Vector2(base.x - cw * 0.5, body.position.y - 6.0 * s - m),
			Vector2(body.end.x + 4.0 * s, body.end.y + 2.0 * s), Vector2(body.position.x - 4.0 * s - cw, body.end.y + 2.0 * s),
			Vector2(body.end.x + 4.0 * s, body.position.y - 2.0 * s - m), Vector2(body.position.x - 4.0 * s - cw, body.position.y - 2.0 * s - m)]
		# Full-size fleets can fill all eight nearby slots. Search farther before covering an icon or another model.
		for dy in [-64.0, 64.0, -128.0, 128.0]:
			cands.append(Vector2(body.end.x + 8.0 * s, cy + dy * s))
			cands.append(Vector2(body.position.x - 8.0 * s - cw, cy + dy * s))
		var at: Vector2 = cands[0]; var best = 1e9
		for ci in cands.size():
			var r = Rect2(cands[ci], Vector2(cw, m)); var cost = float(ci)
			if r.intersects(sun_rect): cost += 1000000.0
			if r.position.x < left or r.end.x > size.x - 8.0 * s or r.position.y < 8.0 * s or r.end.y > size.y - 8.0 * s: cost += 1000.0
			for t in taken:
				if r.intersects(t): cost += 200.0   # another model, or words already placed
			var rg = r.grow(5.0 * s)
			for lp in lane_pts:
				if rg.has_point(lp): cost += 12.0   # a lime route under the words
			if cost < best: best = cost; at = cands[ci]
		# A zoomed view can leave every nearby candidate on the disc. Place the caption in clear map space instead.
		if Rect2(at, Vector2(cw, m)).intersects(sun_rect):
			at.x = maxf(left, sun_rect.position.x - cw - 12.0 * s)
			if Rect2(at, Vector2(cw, m)).intersects(sun_rect): at.y = sun_rect.end.y + 12.0 * s
		taken.append(Rect2(at, Vector2(cw, m))); _words.append(taken.back())
		var num = int(ui.route_num(id)) if ui.has_method("route_num") else i + 1   # the same number as its row
		GS.marker(overlay, at + Vector2(m, m) * 0.5, s, str(num if num > 0 else i + 1), ui.font_num_b, id == str(ui.picked))
		GS.halo_text(overlay, f20, Vector2(at.x + m + gp, at.y + m * 0.5 + (f20.get_ascent(fs) - f20.get_descent(fs)) * 0.5), nm, fs, GS.TEXT, s)
	if _flying:
		var t2 = "In flight. Click or press Space to skip."; var fr = _free_rect()
		var w3 = f14.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * s)).x
		GS.halo_text(overlay, f14, Vector2(fr.get_center().x - w3 * 0.5, fr.end.y + 40.0 * s), t2, int(17 * s), GS.TEXT2, s)
	if has_focus() and _hot_by_key and _hot != "" and _nodes.has(_hot) and not _flying:   # keyboard focus: the sage ring (ui_spec.md 6)
		var br = _body_rect(_hot, s).grow(3.0 * s)
		overlay.draw_rect(br, GS.TEXT, false, max(2.0, 2.0 * s))

func _sun_rect() -> Rect2:
	var r = SUN_R * float(sys.approach["sun_scale"]) * float(sys.approach["disc_outer"])
	var centre = _screen(sys.sun_pos)
	var rx = absf(_screen(sys.sun_pos + Vector3(r, 0, 0)).x - centre.x)
	var ry = absf(_screen(sys.sun_pos + Vector3(0, 0, r)).y - centre.y)
	return Rect2(centre - Vector2(rx, ry), Vector2(rx, ry) * 2.0).grow(ui.px(12))
# the screen box a stop's model takes, near enough for words to keep off it and for the focus ring to frame it
func _body_rect(id: String, s: float) -> Rect2:
	var d = _nodes[id]; var sc = float(d["sc"])
	var bb: AABB = d["parts"]["aabb"] if d.has("parts") else AABB()
	if bb.size != Vector3.ZERO and is_instance_valid(d["obj"]):   # the model's real bounds, projected
		var xf: Transform3D = d["obj"].global_transform; var lo = Vector2(INF, INF); var hi = Vector2(-INF, -INF)
		for i in 8:
			var q = _screen(xf * bb.get_endpoint(i)); lo = Vector2(min(lo.x, q.x), min(lo.y, q.y)); hi = Vector2(max(hi.x, q.x), max(hi.y, q.y))
		return Rect2(lo, hi - lo).grow(2.0 * s)
	var c = _screen(d["pos"] + Vector3(0, float(d["top"]) * 0.45 * sc, 0))
	var rx = max(26.0 * s, _screen(d["pos"]).distance_to(_screen(d["pos"] + cam.global_transform.basis.x * float(d["ring_r"]) * 1.1 * sc)))
	var top = _screen(d["pos"] + Vector3(0, float(d["top"]) * sc, 0)); var bot = _screen(d["pos"])
	var y0 = min(top.y, c.y - rx * 0.6); var y1 = max(bot.y + 10.0 * s, c.y + rx * 0.6)
	return Rect2(c.x - rx, y0, rx * 2.0, y1 - y0)
func _node_at(sp: Vector2) -> String:
	var best = ""; var bd = 1e9
	for id in _nodes:
		var d = _nodes[id]
		if cam.is_position_behind(d["pos"]): continue
		var sc = float(d["sc"])
		var c = _screen(d["pos"] + Vector3(0, d["top"] * 0.4 * sc, 0))
		var r = max(30.0 * ui.k, _screen(d["pos"]).distance_to(_screen(d["pos"] + cam.global_transform.basis.x * d["ring_r"] * 1.15 * sc)))
		var dd = sp.distance_to(c)
		if dd < r and dd < bd:
			bd = dd; best = id
	return best
var _card_key := ""
var _hot_by_key := false
var _words: Array = []        # where the map's words were drawn last frame: the tip card keeps off them when it can
# The tip card: the one box on the map. It shows for a stop that is not your stop or a next jump (the route list already says
# everything about those), on hover or when the arrow keys reach it: the name, what it is and against whom, the danger as
# four pips and a word (or the stop's one-line note), a modifier or an unusual board, the reward, the Nemesis line in red
# where true, and the safest and the richest way on from it to the flagship (the old hover card's route planner).
func _update_card() -> void:
	var C = _C()
	if _hot == "" or _flying or not _nodes.has(_hot) or _avail().has(_hot) or C.RUN.get("pos") == _hot or C.modal_d != null:
		card.visible = false; return
	var ck = _hot + "|" + str(_routes.size()) + "|" + str(_danger.get(_hot, {}).get("ratio", 0)) + "|" + str(ui.k)
	if ck != _card_key:   # the words only change with the stop, its routes or its danger
		_card_key = ck; _fill_card(_nodes[_hot]["n"])
	card.visible = true; card.reset_size()
	# beside the stop: right and below it first (as the mockup's), else whichever corner covers the least of the map's words
	var base = _screen(_nodes[_hot]["pos"]); var dx = float(ui.px(24)); var dy = float(ui.px(20)); var cs = card.size
	var at = base + Vector2(dx, dy); var best = 1e12
	for c in [base + Vector2(dx, dy), base + Vector2(dx, -dy - cs.y), base + Vector2(-dx - cs.x, dy), base + Vector2(-dx - cs.x, -dy - cs.y)]:
		var r = Rect2(c, cs); var cost = 0.0
		if r.position.x < float(ui.px(COL_W + 8.0)) or r.end.x > size.x - ui.px(16) or r.position.y < ui.px(8) or r.end.y > size.y - ui.px(8): cost += 1e9
		for w in _words:
			var ov = r.intersection(w); cost += ov.size.x * ov.size.y
		if cost < best: best = cost; at = c
	at.x = clamp(at.x, float(ui.px(COL_W + 8.0)), size.x - cs.x - float(ui.px(8)))
	at.y = clamp(at.y, float(ui.px(8)), size.y - cs.y - float(ui.px(8)))
	card.position = at.round()
func _fill_card(n: Dictionary) -> void:
	var C = _C(); var S = View.stop(C, n)
	for ch in card_box.get_children(): card_box.remove_child(ch); ch.queue_free()
	card.add_theme_stylebox_override("panel", GS.tip(ui.k))
	var tw = 320.0   # the tip's text width at 1080: a small card, long lines wrap
	card_box.custom_minimum_size.x = ui.px(tw)
	var add = func(t: String, col: Color, f: Font = null, size: float = 17):
		var pr = ui.para(t, size, 24, col, tw, 3, f); card_box.add_child(pr[0])
	var done = C.jt(n.get("done")); var cut_off = not done and not _reachable.has(str(n["id"]))
	add.call(S["name"], GS.TEXT, GS.sheet_medium(), 21)
	add.call(str(S.get("what_tip", S["what"])) + (" (passed)" if done else ""), GS.TEXT2)
	var dg: Dictionary = _danger.get(str(n["id"]), {})
	if S["fight"] and not done and not dg.is_empty():
		var h = HBoxContainer.new(); h.add_theme_constant_override("separation", ui.px(8)); h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(GS.pips(ui.k, float(dg["level"]))); h.add_child(ui.tl(str(dg["band"]), 17, 24, GS.TEXT)); card_box.add_child(h)
	var extra: Array = []
	if S["mod"] != "": extra.append(S["mod"])
	if S["shape"] != "": extra.append(S["shape"] + " board")
	if S["place"] != "": extra.append(S["place"])
	if not extra.is_empty() and not done: add.call(", ".join(PackedStringArray(extra)), GS.TEXT2)
	if S["reward"] != "": add.call("Reward " + S["reward"], GS.TEXT2)
	if S["nemesis"]: add.call("The Nemesis meets you here", GS.NEM)
	if cut_off: add.call("Cut off: no route leads here now", GS.TEXT2)
	if not _routes.is_empty() and not done and not cut_off:
		var fc = intel.fleet_condition()
		for r in _routes:
			var st = r["st"]
			var t = "%s way on: %d fight%s%s, %d repair stop%s, %d shipyard%s" % [r["name"], st["fights"], "" if st["fights"] == 1 else "s", (" (%d elite)" % st["elites"]) if st["elites"] > 0 else "", st["repairs"], "" if st["repairs"] == 1 else "s", st["shops"], "" if st["shops"] == 1 else "s"]
			if r["name"] == "Richest":   # what it pays, the counts that are not zero
				var pay: Array = ["%d fight%s" % [st["fights"], "" if st["fights"] == 1 else "s"]]
				if st["boons"] > 0: pay.append("%d %s" % [st["boons"], ui.term("boon") if st["boons"] == 1 else ui.term("boons")])
				if st["refits"] > 0: pay.append("%d refit%s" % [st["refits"], "" if st["refits"] == 1 else "s"])
				if st["relics"] > 0: pay.append("%d %s" % [st["relics"], ui.term("relic")])
				if st["shops"] > 0: pay.append("%d shipyard%s" % [st["shops"], "" if st["shops"] == 1 else "s"])
				t = "Richest way on: " + ", ".join(PackedStringArray(pay))
			t += ", worst " + str(st["worst_name"])
			add.call(t, GS.TEXT2)
			if fc["hurt"] and not st["repair_before_boss"]: add.call("Your fleet is hurt and this way has no repair stop before the flagship.", GS.TEXT2)

# ---------------- input: hover and click pick a route, a double click or Enter flies it; zoom and pan; keys ----------------
func _set_hot(h: String) -> void:
	if h == _hot: return
	_hot = h
	var next = h != "" and _avail().has(h)
	_routes = intel.routes_through(h) if (h != "" and intel != null and not next) else []
	_paint_lanes()
	if next and ui != null and ui.has_method("pick_route"): ui.pick_route(h)   # pointing at a next jump picks its row
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if next else Control.CURSOR_ARROW
const ZOOM_MIN := 0.38
const ZOOM_MAX := 1.2
func _pan_keyboard(delta: float) -> void:
	if not is_visible_in_tree() or loading or _flying or backdrop or _C().modal_d != null: return
	# Arrow keys still choose routes. WASD pans even while a side-panel button has focus.
	var p := CamRig.keyboard_pan(get_viewport(), false)
	if p != Vector2.ZERO: pan_by(Vector3(p.x, 0, -p.y) * delta * 45.0 * _uz_t)
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
	var lim = (_outer_radius() + 6.0) * (1.25 - _uz_t * 0.6)
	if _pan_t.length() > lim: _pan_t = _pan_t.normalized() * lim
	if _uz_t >= 0.999: _pan_t = _pan_t.limit_length(_outer_radius() * 0.5)
func _gui_input(e: InputEvent) -> void:
	if loading or _flying or backdrop: return
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
			if id != "" and _avail().has(id):   # a click picks the route; a double click flies it (so does Enter or the lime button)
				accept_event()
				if ui.has_method("pick_route"): ui.pick_route(id)
				if e.double_click: fly_to(id)
			elif e.double_click: reset_view()
	elif e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_HOME: reset_view(); accept_event(); return
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: zoom_by(0.88); accept_event(); return
			KEY_MINUS, KEY_KP_SUBTRACT: zoom_by(1.0 / 0.88); accept_event(); return
		if e.keycode in [KEY_RIGHT, KEY_DOWN, KEY_LEFT, KEY_UP]:   # the arrow keys walk every stop still ahead: a next jump is picked, any other shows its tip
			if _kb_order.is_empty(): return
			var cur = _kb_order.find(_hot) if _hot != "" else -1
			if cur < 0:
				var p0 = str(ui.picked) if ui.get("picked") != null else ""
				cur = _kb_order.find(p0)
				_kb = max(0, cur)
			else: _kb = (cur + (1 if e.keycode in [KEY_RIGHT, KEY_DOWN] else -1) + _kb_order.size()) % _kb_order.size()
			_hot_by_key = true; _set_hot(_kb_order[_kb]); accept_event()
		elif e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			var pk = str(ui.picked) if ui.get("picked") != null else ""
			if not e.echo and pk != "": accept_event(); fly_to(pk)
func _input(e: InputEvent) -> void:
	# Consume the skip before a side-panel button can start another action.
	if not _flying or not is_visible_in_tree(): return
	var click = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	var key = e is InputEventKey and e.pressed and not e.echo and e.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if click or key:
		get_viewport().set_input_as_handled()
		_finish_flight()

func fly_to(id: String) -> void:
	if _flying or loading or backdrop or token == null or not _avail().has(id) or not _nodes.has(id) or _C().modal_d != null: return
	if _arrival_tween != null: _arrival_tween.kill()
	_flying = true; card.visible = false; _drag = false
	_flight_id = id; _flight_time = 0.0; _flight_rotation = token.quaternion
	var a = token.position; var b = _nodes[id]["pos"] + TOKEN_OFF + Vector3(0, _nodes[id]["top"], 0)
	var from = a - TOKEN_OFF; from.y = 0.0
	_flight_curve = sys.lane_curve(from, _nodes[id]["pos"])
	_flight_heights = Vector2(a.y - TOKEN_OFF.y, b.y - TOKEN_OFF.y)
	_wake_samples.clear(); _set_hot(""); _paint_lanes()
	_uz_t = 1.0; _pan_t = Vector3.ZERO
	grab_focus()

# Cosine acceleration, constant-speed cruise, then matching braking. The
# integral is continuous in speed and acceleration, including both endpoints.
static func _flight_distance(t: float) -> float:
	const RAMP := 0.24
	if t > 1.0 - RAMP: return 1.0 - _flight_distance(1.0 - t)
	if t < RAMP: return (t - sin(PI * t / RAMP) * RAMP / PI) * 0.5 / (1.0 - RAMP)
	return (t - RAMP * 0.5) / (1.0 - RAMP)

func _flight_point(distance: float) -> Vector3:
	var p := _flight_curve.sample_baked(_flight_curve.get_baked_length() * distance) + TOKEN_OFF
	p.y += lerpf(_flight_heights.x, _flight_heights.y, distance) + pow(sin(PI * distance), 2.0) * 1.2
	return p

func _advance_flight(delta: float) -> void:
	_flight_time = minf(_flight_time + delta, FLIGHT_SECONDS)
	var t := _flight_time / FLIGHT_SECONDS
	var distance := _flight_distance(t)
	var p := _flight_point(distance)
	var forward := (_flight_point(minf(1.0, distance + 0.005)) - _flight_point(maxf(0.0, distance - 0.005))).normalized()
	var next_forward := (_flight_point(minf(1.0, distance + 0.04)) - p).normalized()
	var bank := clampf(-forward.signed_angle_to(next_forward, Vector3.UP) * 4.0, -0.24, 0.24) * sin(PI * t)
	var heading := (Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.UP, PI * 0.5) * Basis(Vector3.RIGHT, bank)).get_rotation_quaternion()
	token.position = p
	token.quaternion = _flight_rotation.slerp(heading, smoothstep(0.0, 0.22, t))
	var lead := forward * 3.5 * sin(PI * t)
	var follow := 1.0 - exp(-delta * 4.0)
	# Keep the sun and the fleet in the fitted view while bodies at different
	# depths pass naturally. Avoid the old close zoom that lost the whole sun.
	_cam_focus = _cam_focus.lerp(p + lead, follow)
	_cam_zoom = lerpf(_cam_zoom, 0.86, follow)
	# Sample every presented frame so the head never lags behind the engines.
	_wake_samples.append({"time": _t, "engines": _engine_positions()})
	if t >= 1.0: _finish_flight()

func _finish_flight() -> void:
	if not _flying: return
	var id := _flight_id
	# A skipped hop teleports to the stop; do not stretch its old wake across it.
	if _flight_time < FLIGHT_SECONDS: _wake_samples.clear()
	token.position = _flight_point(1.0)
	# Keep the arrival heading; banking settles without a rotation reset.
	var forward := (token.position - _flight_point(0.995)).normalized()
	token.basis = Basis.looking_at(forward, Vector3.UP) * Basis(Vector3.UP, PI * 0.5)
	_flying = false; _flight_id = ""
	_C().act("enterNode", id)
	_last_pos = _C().RUN.get("pos")
	_arrive(false)
	_refresh()

func _make_wake() -> void:
	_wake_mesh = ImmediateMesh.new()
	_wake_material = StandardMaterial3D.new()
	_wake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_wake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_wake_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_wake_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wake_material.vertex_color_use_as_albedo = true
	_wake_material.albedo_color = System.look(_C().RUN["fac"])["light"]
	_wake_node = sys.mi(_wake_mesh, _wake_material)
	_wake_node.extra_cull_margin = _outer_radius() * 3.0
	root3.add_child(_wake_node)

func _update_wake() -> void:
	if _wake_mesh == null: return
	while not _wake_samples.is_empty() and _t - _wake_samples[0]["time"] > 0.65: _wake_samples.pop_front()
	_wake_mesh.clear_surfaces()
	if _wake_samples.size() < 2: return
	# Keep the fading arrival tip on the engines as the idle bob resumes.
	_wake_samples.back()["engines"] = _engine_positions()
	for engine in _engine_mounts.size():
		_wake_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in _wake_samples.size():
			var p: Vector3 = _wake_samples[i]["engines"][engine]
			var before: Vector3 = _wake_samples[maxi(0, i - 1)]["engines"][engine]
			var after: Vector3 = _wake_samples[mini(_wake_samples.size() - 1, i + 1)]["engines"][engine]
			var side := (after - before).cross(cam.position - p).normalized()
			var life := clampf(1.0 - (_t - float(_wake_samples[i]["time"])) / 0.65, 0.0, 1.0)
			_wake_mesh.surface_set_color(Color(1.5, 1.5, 1.5, life * life * 0.85))
			_wake_mesh.surface_add_vertex(p - side * life * 0.26)
			_wake_mesh.surface_add_vertex(p + side * life * 0.26)
		_wake_mesh.surface_end()
