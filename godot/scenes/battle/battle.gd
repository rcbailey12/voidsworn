extends Node3D
# The battle scene: the game's board, ships, camera, HUD and sound around the rules API (godot/rules/API.md).
# The scene never writes rules state. It sends commands (move, fire, ability, order, end activation), plays back the
# event stream with animation at the game's pace (B2: tables PACE, Enter or Space hurries the enemy), and draws from
# view() snapshots: each batch of events carries the view taken right after it, and the picture is synced to that view
# once the batch has played (hull and shield bars change as the shots land, not before).
#
# Command line (after --): --scenario s1 | --seed N | --fac hegemony|corsair | --map belt | --bot (both sides on AI)
#   --shots <folder> (screenshot job: saves PNGs at fixed moments and quits) | --quit-after N (seconds)
#
# Controls as today's game (index_test.html): click your ship, click a gold hex to move, click an enemy to fire every gun
# that bears (1-6 pick one), Q/E turn in place, B brace, X ram, G board, Tab next ship, Enter end activation (or hurry the
# enemy), Space hurry, Esc cancel, R threat map, V arcs, T top-down, F focus, Home reset view; right-drag orbit,
# left-drag or WASD pan, wheel zoom.

signal finished(result: Dictionary)

const API := preload("res://rules/battle_api.gd")
const Board := preload("res://render/board.gd")
const ShipView := preload("res://render/ship_view.gd")
const CamRig := preload("res://render/camera_rig.gd")
const HT := preload("res://render/hull_table.gd")
const HUD := preload("res://ui/battle/hud.gd")
const Fx := preload("res://scenes/battle/fx_stub.gd")
const Sfx := preload("res://audio/sfx.gd")
const Backdrop := preload("res://render/backdrop.gd")

const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const FILL_DIR := Vector3(0.6, -0.2, 0.75)
const FILL_COL := Color(0.55, 0.65, 0.85)
const REACH_C := Color(0.82, 0.65, 0.29, 0.16)
const REACH_RING := Color(0.95, 0.75, 0.35, 0.55)
const REACH_HOT := Color(1.0, 0.8, 0.35, 0.55)
const TARGET_RING := Color(1.0, 0.25, 0.2, 0.95)
const QUAD_NAME := ["prow", "starboard", "rear", "port"]
const SEC_NAME := {"prow": "prow", "mid": "midships", "eng": "engines"}
const MOVE_PER := {"voidsworn": 1.25, "hegemony": 0.75, "corsair": 0.85, "chorus": 1.1, "ithar": 1.0, "deathless": 0.6}
const TIPS := [
	["start", "Your fleet", "Select one of your ships: it has a green ring underneath. Gold hexes show where it can move, and the fans show its firing arcs."],
	["turns", "Turns alternate", "You and the enemy take turns one ship at a time: activate one of yours, then the enemy activates one of theirs, until every ship has acted. Then a new round starts."],
	["select", "Moving and facing", "Hover a gold hex to preview the move: the arrow shows where you will end up and which way you will face. Q and E turn in place. Moving matters: a ship that ends its activation in the same hex is easier to hit (enemies get +10), and turning in place does not count. Moving 3 or more hexes makes it harder to hit (−5). Bracing cancels the sitting-still penalty."],
	["move", "Shields and hull", "The cyan bars on the ship panel are its shields: four facings that soak hits and recharge each turn. Amber is hull: damage that stays. Keep your strongest shield facing the enemy."],
	["target", "Firing", "Enemies you can hit have a red ring. Hover one for hit odds and expected damage, then click to fire every weapon that bears. Keys 1 to 6 pick a single weapon."],
	["fired", "Alternating activations", "Each ship acts once per round. When this ship is done, press End activation (Enter) and the enemy moves one of theirs."],
	["resolve", "Admiral's Command", "Your admiral's signature move is ready: it glows gold in the top bar. You get it once per battle. It grows each round you wait and when you lose a ship, so pick your moment."],
	["close", "Close action", "Ramming speed (X) charges the first enemy dead ahead. Boarding (G) sends crews into an adjacent enemy; win and the ship is yours."],
	["threat", "Threat map", "Before you end a move, check where the enemy can reach. Press R, or Threat in the top bar, to shade every hex their guns can hit next turn: the darker the hex, the more damage is waiting there."],
	["objective", "Objectives", "Not every fight is a slugging match. The top bar shows this fight's goal."],
]

var args := {}
var api
var TBL := {}               # the rules tables (FACTIONS, ADMIRALS, ABILITIES, ORDERS, COMMANDS, ARC_NAME, PACE ...), read only
var PACE := {}
var V := {}                # the view the picture is synced to
var VU := {}               # id -> unit in V
var disp := {}             # id -> {hp, sh} as drawn (changes as hits land)
var views := {}            # id -> ShipView
var wrecked := {}
var board: Node3D
var cam: Camera3D
var hud: CanvasLayer
var fx: Node3D
var sfx: Node
var env: Environment
var batches: Array = []
var busy := false
var think_task := -1
var think_out = null
var thinking := false
var speed := 1.0           # the game's SPEED (duration multiplier)
var user_speed := 1.0      # Speed: normal (1) or fast (0.45)
var movement := "cinematic"  # Movement: cinematic (heavy ships, R50) or brisk (the earlier motion)
var move_frames := ""        # --move-frames <dir>: a frame per rendered frame while ships burn (before and after captures)
var game_t := 0.0             # game-clock seconds since the battle scene started (scaled by --fast like every animation)
var pace_kind := {}           # event kind -> game seconds spent playing it in enemy batches (where the wait goes)
var pace_enemy := {}          # round -> game seconds spent playing the enemy's activations (the player's wait, B2 target 12 s, limit 15 s)
var skip := false
var sel := ""              # selected ship id
var inspect := ""          # enemy shown in the panel
var armed := -1
var mode := ""             # "board" while picking a boarding target
var reach_states: Array = []
var reach_map := {}        # "q,r" -> state (best facing)
var reach_alt := {}        # "q,r" -> [states] (all facings, for Q/E on a hovered hex)
var hover := Vector2i(99999, 99999)
var hover_pick := {}       # "q,r" -> chosen facing index into reach_alt
var threat_on := false
var arcs_on := true
var floats: Array = []
var ended := false
var fired_in_act := {}     # unit id -> weapons fired this activation (volley pace)
var tips := {}
var tips_off := false
var bot := false
var bot_t := 0.0
var bot_moved := {}
var bot_ab := {}
var bot_cmd_used := false
var wing_sel := ""          # one of your squadrons picked for a standing order
var cmd_armed_t := -9.0
var cine := "key"          # cut-ins: "key" moments, "all" attacks, "off" (settings)
var cine_saved := {}
var follow := true          # follow enemy activations with the camera (settings)
var cam_saved := {}
var shots_dir := ""
var t_start := 0.0
var marker_root: Node3D
var backdrop: Node3D
var gfx = null            # G4 fx (res://fx/fx.gd) when present
var music: Node = null    # the music player when the game shell gave one
var world = null          # G4 world (res://world/world.gd) when present
var key_light: DirectionalLight3D
var fill_light: DirectionalLight3D
var arrow: MeshInstance3D
var path_dots: MultiMeshInstance3D
var errors: Array = []
var result := {}
var battle_cfg := {}
var ai_level := ""         # "veteran" or "standard" (settings); empty keeps the rules default
var in_campaign := false   # a campaign battle (no quit to title: the run decides what a battle ends as)
var can_retreat := false   # campaign battles (not against a sector flagship): the top bar offers Retreat
var showcase := false     # the title screen's decorative battle (campaign3d.js setupShowcase): no HUD, no turns, no input, slow orbit
var boss_fight := false    # a sector flagship fight or the finale (battle kind "boss"): boss music and the champion fanfare
var external := false      # run by godot/main (campaign or quick battle): no own restart, the end card says Continue
var last_progress := 0.0   # real time of the last event batch (softlock watchdog for bot runs)
var softlock_s := 60.0


func _ready() -> void:
	_args()
	t_start = Time.get_ticks_msec() / 1000.0
	bot = bot or args.has("bot")
	shots_dir = str(args.get("shots", ""))
	if args.has("breach-shots"):
		shots_dir = str(args["breach-shots"])
	if args.has("move-frames"):
		shots_dir = str(args["move-frames"])
	_load_opts()
	if shots_dir != "" or args.has("sheet-check"):
		tips_off = true   # screenshot jobs: no onboarding tip card covering the top of the screen
	if args.has("movement"):
		movement = str(args["movement"])
	_build_world()
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.cam = cam
	hud = HUD.new()
	add_child(hud)
	hud.action.connect(_on_action)
	if showcase:
		hud.visible = false
		cam.input_enabled = false
		set_process_unhandled_input(false)
		tips_off = true
	if not external:
		start_default()
	if args.has("breach-shots"):
		_breach_shots()
	elif args.has("move-frames"):
		_move_frames()
	elif args.has("sheet-check"):
		_sheet_check()
	elif args.has("planet-shot"):
		_planet_shot()
	elif shots_dir != "":
		_shots()


func _args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		var k := a[i]
		if k.begins_with("--"):
			k = k.substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				args[k] = a[i + 1]
				i += 1
			else:
				args[k] = true
		i += 1


# ---------------------------------------------------------------- setup

func _build_world() -> void:
	env = Environment.new()
	var man := ShipView.manifest()
	var sky_res := str(man.get("sky", ""))
	if sky_res != "" and ResourceLoader.exists(sky_res):
		var sh := Shader.new()
		# the dead-star sky (A3), mipmapped so the 8K star field does not alias into speckle, and kept dim and subtle
		sh.code = "shader_type sky;\nuniform sampler2D pano : source_color, filter_linear_mipmap_anisotropic, repeat_enable;\nvoid sky() {\n\tvec3 c = texture(pano, SKY_COORDS).rgb;\n\tCOLOR = min(c * 0.8, vec3(0.6));\n}\n"
		var pano := ShaderMaterial.new()
		pano.shader = sh
		pano.set_shader_parameter("pano", load(sky_res))
		var sky := Sky.new()
		sky.sky_material = pano
		sky.radiance_size = Sky.RADIANCE_SIZE_256
		env.background_mode = Environment.BG_SKY
		env.sky = sky
		env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	else:
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.01, 0.012, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_intensity = 0.6
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for lv in 7:
		env.set_glow_level(lv, [0.0, 0.6, 1.0, 0.5, 0.0, 0.0, 0.0][lv])
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key_light = key
	key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = KEY_COL
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key.directional_shadow_max_distance = 600.0
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill_light = fill
	fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = FILL_COL
	fill.light_energy = 0.5
	add_child(fill)
	_apply_quality(str(args.get("quality", "max")))
	# G4's look (tonemap, exposure, glow, ambient, key and fill) when it is in the build
	if ResourceLoader.exists("res://render/look.gd"):
		load("res://render/look.gd").apply(env, key, fill, {"quality": str(args.get("quality", "max"))})
		key.directional_shadow_max_distance = 600.0
	board = Board.new()
	board.name = "Board"
	add_child(board)
	backdrop = Backdrop.new()
	backdrop.name = "Backdrop"
	add_child(backdrop)
	marker_root = Node3D.new()
	marker_root.name = "Markers"
	add_child(marker_root)
	fx = Fx.new()
	fx.name = "Fx"
	add_child(fx)
	# the G4 effects system (godot/fx/API.md) when it is in the build; the placeholder stays for anything it lacks
	if ResourceLoader.exists("res://fx/fx.gd") and not args.has("nofx"):
		gfx = load("res://fx/fx.gd").new()
		gfx.name = "GFx"
		add_child(gfx)
	cam = CamRig.new()
	cam.name = "Camera"
	add_child(cam)
	cam.current = true
	if gfx != null and gfx.has_method("setup"):
		gfx.setup({"camera": cam, "quality": str(args.get("quality", "max")), "reduce_flashing": reduce_flashing, "shake": shake_scale, "unit": 1.0})
	_build_arrow()


# the Graphics setting: max (everything), high (no SSIL, smaller shadows), low (no MSAA, SSAO or volumetric haze)
func _apply_quality(q: String) -> void:
	var vp := get_viewport()
	match q:
		"low":
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
			RenderingServer.directional_shadow_atlas_set_size(2048, true)
		"high":
			vp.msaa_3d = Viewport.MSAA_2X
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
		_:
			vp.msaa_3d = Viewport.MSAA_4X
			RenderingServer.directional_shadow_atlas_set_size(4096, true)
	# Temporal AA (settings, off by default as in the browser): Max and High only
	vp.use_taa = _jt(args.get("taa", false)) and q != "low"


func _post_quality(q: String) -> void:
	if q == "low":
		env.ssao_enabled = false
		env.ssil_enabled = false
		env.volumetric_fog_enabled = false
		env.glow_enabled = true
	elif q == "high":
		env.ssil_enabled = false


func _build_arrow() -> void:
	# the facing arrow shown on a hovered gold hex (where the ship will end up and which way it will face)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in [Vector3(7.5, 0, 0), Vector3(-2.5, 0, 4.2), Vector3(0.5, 0, 0), Vector3(7.5, 0, 0), Vector3(0.5, 0, 0), Vector3(-2.5, 0, -4.2)]:
		st.add_vertex(v)
	arrow = MeshInstance3D.new()
	arrow.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.4, 1.1, 0.5, 0.9)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = true
	arrow.material_override = m
	arrow.visible = false
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arrow)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sp := SphereMesh.new()
	sp.radius = 0.7
	sp.height = 1.4
	sp.radial_segments = 8
	sp.rings = 4
	mm.mesh = sp
	mm.instance_count = 0
	path_dots = MultiMeshInstance3D.new()
	path_dots.multimesh = mm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(1.2, 0.95, 0.45)
	path_dots.material_override = dm
	path_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(path_dots)


# A sector 1 fight like the campaign's first battles (Vex's starting fleet against a sector 1 Hegemony or Corsair group),
# or a fixed test battle with --scenario. The campaign (godot/main) calls start_battle instead.
func start_default() -> void:
	var seed := int(args.get("seed", randi() % 1000000 + 1))
	if args.has("scenario") and not FileAccess.file_exists("res://rules/test/scenarios.json"):
		# an exported build has no test folders: play the default battle instead of halting
		push_warning("--scenario needs res://rules/test/scenarios.json (not in an exported build); playing the default battle")
		args.erase("scenario")
	if args.has("scenario"):
		var a = API.new()
		var e: String = a.load_rules()
		if e != "":
			push_error(e)
		a.new_battle_scenario(str(args["scenario"]), seed if args.has("seed") else -1)
		_begin(a)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var fac := str(args.get("fac", ["hegemony", "corsair"][rng.randi() % 2]))
	var groups := {"hegemony": [["h_interdictor", "h_picket", "h_picket"], ["h_interdictor", "h_picket", "h_picket", "h_picket"], ["h_interdictor", "h_interdictor", "h_picket"]],
		"corsair": [["c_marauder", "c_raider", "c_raider"], ["c_reaver", "c_reaver", "c_raider"], ["c_reaver", "c_raider", "c_raider", "c_raider"]]}
	var maps := ["open", "belt", "station", "planet", "storm", "graveyard"]
	var g: Array = groups.get(fac, groups["hegemony"])[rng.randi() % 3]
	var sc := {"seed": seed, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden"], "fac": fac,
		"obj": "rout", "shape": "open", "map": str(args.get("map", maps[rng.randi() % maps.size()])), "dep": "line", "kind": "battle"}
	# the game's own sector 1 fleet generation when the rules have it, else a fixed sector 1 group
	start_scenario(sc)


func start_scenario(sc: Dictionary) -> void:
	var a = API.new()
	var e: String = a.load_rules()
	if e != "":
		push_error(e)
	a.new_battle_scenario(sc, int(sc.get("seed", 1)))
	battle_cfg = sc
	_begin(a)


# From the campaign: run = the campaign run dictionary, cfg = the battle config (API.md new_battle).
func start_battle(run: Dictionary, cfg: Dictionary) -> void:
	var a = API.new()
	var e: String = a.load_rules()
	if e != "":
		push_error(e)
	a.new_battle(run, cfg)
	battle_cfg = cfg
	_begin(a)


# a battle the campaign has already set up (main.play_api)
func begin_with(a) -> void:
	_begin(a)


func _begin(a) -> void:
	api = a
	TBL = _api_tables()
	if ai_level != "":
		_api_set_ai(ai_level)
	PACE = TBL.get("PACE", {})
	boss_fight = _api_battle_kind() == "boss"
	ended = false
	result = {}
	errors.clear()
	bot_ab.clear()
	bot_moved.clear()
	bot_tried.clear()
	bot_cmd_used = false
	t_start = Time.get_ticks_msec() / 1000.0
	last_progress = t_start
	for id in views:
		(views[id] as Node).queue_free()
	views.clear()
	wrecked.clear()
	disp.clear()
	batches.clear()
	fx.clear()
	hud.hide_end()
	sel = ""
	inspect = ""
	armed = -1
	board.props_world = ResourceLoader.exists("res://world/world.gd") and not args.has("noworld")
	if key_light != null:
		board.sun_dir = key_light.global_transform.basis.z   # a directional light shines along its -Z: the sun is +Z
	board.build(api)
	cam.bounds = board.bounds()
	_post_quality(str(args.get("quality", "max")))
	if world != null:
		world.queue_free()
		world = null
	if board.props_world:
		# G4's world: sky and nebula per enemy faction, planet, dead star, asteroid blockers, debris, nebula, dressing
		world = load("res://world/world.gd").new()
		world.name = "World"
		add_child(world)
		var pano = null
		if env.sky != null and env.sky.sky_material is ShaderMaterial:
			pano = (env.sky.sky_material as ShaderMaterial).get_shader_parameter("pano")
		var vb: Dictionary = api.view()
		var wi: Dictionary = api.world_info()
		world.build(vb, {"biome": wi.get("biome", {}) if wi.get("biome") is Dictionary else {}, "fac": _enemy_fac_of(vb), "hex_world": board.hex_world, "camera": cam, "environment": env,
			"quality": str(args.get("quality", "max")), "pano": pano, "seed": int(wi.get("seed", 1)) if wi.get("seed") != null else 1})
		for c in backdrop.get_children():
			c.queue_free()
	else:
		backdrop.build(cam.bounds, env)
	V = api.view()
	_index_view()
	for u in V["units"]:
		_make_view(u)
	_sync(V)
	# open on your fleet, looking toward the enemy (the browser game's camera starts over the player's side)
	var pc := Vector3.ZERO
	var ec := Vector3.ZERO
	var np := 0
	var ne2 := 0
	for u in V["units"]:
		if u["side"] == "player":
			pc += board.hex_world(u["q"], u["r"])
			np += 1
		else:
			ec += board.hex_world(u["q"], u["r"])
			ne2 += 1
	pc /= maxf(1.0, np)
	ec = ec / maxf(1.0, ne2) if ne2 > 0 else pc
	cam.home = pc.lerp(ec, 0.3)
	cam.home.y = 0.0
	cam.reset_view()
	cam.home_r = clampf(pc.distance_to(ec) * 0.75, 130.0, 210.0)
	cam.r = cam.home_r
	cam.snap()
	hud.log_text.clear()
	var F = {}
	var ne := 0
	for u in V["units"]:
		if u["side"] == "enemy" and not u["squadron"]:
			ne += 1
	_log("Contact: %s. %d ship%s on the scanners." % [str(F.get("n", _enemy_fac())), ne, "s" if ne > 1 else ""], "s")
	var well = api.world_info().get("well")
	if well is Dictionary or (well is bool and well):
		_log("The Hollow Sun warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.", "s")
	batches.append({"events": api.take_events(), "view": api.view()})
	if not showcase:
		sfx.ambient_start()
	_refresh_ui()
	_legend()
	# story hook (story stream, godot/story/README.md): admiral, enemy flagship and Nemesis lines in the battle log
	voice = null
	if not bot and not showcase and ResourceLoader.exists("res://story/battle_voice.gd"):
		voice = load("res://story/battle_voice.gd").new()
		if voice.has_method("setup_from_api"):
			voice.setup_from_api(api, V)
		else:
			voice.setup_from_rules(api.R, V)  # until the story layer reads battle_api.gd (setup_from_api)
		for l in voice.opening():
			hud.add_log(l["text"], l["kind"])
	var adm := _api_admiral()
	if ResourceLoader.exists("res://portraits/portraits.gd") and adm != "":
		var A = TBL.get("ADMIRALS", {}).get(adm, {})
		hud.set_crest(load("res://portraits/portraits.gd").crest(adm), str(A.get("n", adm)) if A is Dictionary else adm)
	await _warmup()
	if music != null:
		var pf := "voidsworn"
		for u in V["units"]:
			if u["side"] == "player":
				pf = str(u["fac"])
				break
		music.play_battle(pf, _enemy_fac(), boss_fight)
	if showcase:
		# the fleets hold their line; the camera drifts round the board from high up, as the browser's title does
		# no board grid behind the menu (the hex fills and outlines), only the ships, rocks and sky; framed low and close
		# on your line with the enemy beyond it
		board.fills.visible = false
		board.rings.visible = false
		cam.reset_view()
		cam.t = cam.home
		cam.r = clampf(cam.home_r * 0.95, 120.0, 210.0)
		cam.b = 1.05
		for id in views:
			for n in [views[id].ring, views[id].marker]:
				if n != null:
					n.visible = false
		showcase_ready = true
		return
	if not busy:
		_runner()


# Loading-screen warm-up (Muse shipping review): compile every pipeline the battle will use before play starts, so the
# first lance or explosion never hitches: every hull in view for a few frames (camera pulled back over the whole
# board), then G4's fx.warmup draws each effect material once in this battle's own environment. The pipeline
# compilations that still happen during play are counted (Performance PIPELINE_COMPILATIONS_DRAW) and reported.
var pipe_base := -1


func _pipe_count() -> int:
	var n := 0
	for m in ["PIPELINE_COMPILATIONS_DRAW", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if ClassDB.class_has_integer_constant("Performance", m):
			n += int(Performance.get_monitor(ClassDB.class_get_integer_constant("Performance", m)))
	return n


var warming := false


func _warmup() -> void:
	warming = true
	hud.loading(true)
	var keep := {"a": cam.a, "b": cam.b, "r": cam.r, "t": cam.t}
	cam.b = 0.6
	cam.r = maxf(cam.bounds.x, cam.bounds.y) * 2.4
	cam.t = Vector3.ZERO
	cam.snap()
	for i in 3:
		await get_tree().process_frame
	if gfx != null and gfx.has_method("warmup") and DisplayServer.get_name() != "headless":
		# at most 4 s: a warm-up that never returns must never hold the battle
		var done := [false]
		var run := func() -> void:
			await gfx.warmup(cam)
			done[0] = true
		run.call()
		var t0 := Time.get_ticks_msec()
		while not done[0] and Time.get_ticks_msec() - t0 < 4000:
			await get_tree().process_frame
	for i in 2:
		await get_tree().process_frame
	cam.a = keep["a"]
	cam.b = keep["b"]
	cam.r = keep["r"]
	cam.t = keep["t"]
	cam.snap()
	await get_tree().process_frame
	pipe_base = _pipe_count()
	hud.loading(false)
	warming = false


func _enemy_fac_of(v: Dictionary) -> String:
	for u in v.get("units", []):
		if u["side"] == "enemy":
			return str(u["fac"])
	return "hegemony"


func _enemy_fac() -> String:
	for u in V.get("units", []):
		if u["side"] == "enemy":
			return str(u["fac"])
	return "hegemony"


func _index_view() -> void:
	VU.clear()
	for u in V["units"]:
		VU[u["id"]] = u


func _make_view(u: Dictionary) -> void:
	if views.has(u["id"]):
		return
	var sv = ShipView.new()
	sv.name = "ship_" + str(u["id"])
	add_child(sv)
	sv.setup(u, board.hex_world(u["q"], u["r"]), true)
	sv.set_marker(u["side"] == "player")
	views[u["id"]] = sv
	disp[u["id"]] = {"hp": float(u["hp"]), "sh": (u["sh"] as Array).duplicate()}
	if gfx != null and gfx.has_method("add_ship"):
		var info := {"faction": str(u["fac"]), "cls": str(u["cls"]), "size": float(u["size"]), "squadron": bool(u["squadron"]), "flagship": bool(u["flagship"]), "code": sv.code}
		if not sv.a4:
			info["meshes"] = sv.meshes   # A4 ships: fx finds the hull and its skin_<n> patches itself
		gfx.add_ship(str(u["id"]), sv, info)
		sv.fx_engines = true   # G4 draws the engines at the hull's real nozzles: hide ShipView's guessed glows
		if movement != "brisk" and gfx.has_method("set_engine"):
			gfx.set_engine(str(u["id"]), ENGINE_IDLE)


func _music_feed() -> void:
	if music == null or V.is_empty():
		return
	var mine := 0
	var foes := 0
	var hp := 0.0
	var mhp := 0.0
	var flag := 1.0
	var close := 0
	var boss := false
	for u in V["units"]:
		if u["dead"] or u["squadron"]:
			continue
		if u["side"] == "player":
			mine += 1
			hp += float(u["hp"])
			mhp += float(u["maxHp"])
			if u["flagship"]:
				flag = float(u["hp"]) / maxf(1.0, float(u["maxHp"]))
		else:
			foes += 1
			# the boss lift only in a real boss fight while its flagship lives (most fights have an enemy flagship)
			if u["flagship"] and boss_fight:
				boss = true
			for m in V["units"]:
				if m["side"] == "player" and not m["dead"] and absi(int(m["q"]) - int(u["q"])) + absi(int(m["r"]) - int(u["r"])) <= 4:
					close += 1
					break
	music.feed({"close": close, "hull": hp / maxf(1.0, mhp), "flagship": flag, "mine": mine, "enemy": foes, "boss": boss})


func _sync(v: Dictionary) -> void:
	V = v
	_index_view()
	_music_feed()
	if gfx == null or not gfx.has_method("torp_lane"):
		var live := {}
		for tp in V.get("torps", []):
			live[str(tp["id"])] = true
			if not torp_marks.has(str(tp["id"])):
				var by: Dictionary = VU.get(tp.get("by"), {})
				var a: Vector3 = board.hex_world(int(tp["from"]["q"]), int(tp["from"]["r"]), 1.5) if tp.get("from") != null else Vector3.ZERO
				_torp_marker(str(tp["id"]), a, board.hex_world(int(tp["aim"]["q"]), int(tp["aim"]["r"]), 1.5), str(by.get("fac", "hegemony")))
		for k in torp_marks.keys():
			if not live.has(k):
				_torp_clear(k)
	for u in V["units"]:
		if not views.has(u["id"]):
			_make_view(u)
		var sv = views[u["id"]]
		disp[u["id"]] = {"hp": float(u["hp"]), "sh": (u["sh"] as Array).duplicate()}
		sv.set_marker(u["side"] == "player")
		if gfx != null and gfx.has_method("sync_ship"):
			var su: Dictionary = u.duplicate()
			if su.get("sec") == null:
				su["sec"] = {}
			gfx.sync_ship(str(u["id"]), su)
		if u["dead"]:
			if not sv.dead and not wrecked.has(u["id"]):
				sv.die(false)
			continue
		if not sv.busy():  # busy covers the settle: leave it to finish instead of snapping it
			var want: Vector3 = board.hex_world(u["q"], u["r"])
			if Vector2(sv.position.x - want.x, sv.position.z - want.z).length() > 0.5 or absf(angle_difference(sv.cur_yaw, ShipView.yaw_of(u["facing"]))) > 0.05:
				sv.snap_to(want, ShipView.yaw_of(u["facing"]))


# ---------------------------------------------------------------- the player loop: play batches, let the enemy think

func _runner() -> void:
	busy = true
	while true:
		if not is_inside_tree():
			return
		while hold and is_inside_tree():
			await get_tree().process_frame
		if batches.is_empty():
			if api.phase == "enemy" and not ended:
				while _threat_busy:
					await get_tree().process_frame
				var b = await _think()
				if b != null:
					batches.append(b)
				continue
			busy = false
			if api.phase == "over" and not ended:
				await _end_flow()
			_refresh_ui()
			return
		var bt: Dictionary = batches.pop_front()
		# only a batch with events is progress: a bot looping on commands that change nothing must still trip the watchdog
		if not (bt.get("events", []) as Array).is_empty():
			last_progress = Time.get_ticks_msec() / 1000.0
		await _play_batch(bt)
		_sync(bt["view"])
		_refresh_ui()


func _think():
	# the enemy's activation runs on a worker thread, so the frame never stalls while it decides
	think_out = null
	thinking = true
	var tid := WorkerThreadPool.add_task(func() -> void:
		var ev = api.step()
		think_out = {"events": ev, "view": api.view()})
	_think_tid = tid
	while not WorkerThreadPool.is_task_completed(tid):
		await get_tree().process_frame
	if _think_tid == tid:
		WorkerThreadPool.wait_for_task_completion(tid)
		_think_tid = -1
	thinking = false
	var np := _api_not_ported()
	if np != "":
		_error("NOT PORTED: " + np)
	return think_out


func _cmd(f: Callable) -> bool:
	# a player command: the rules act at once, the picture follows
	if not _api_join() or busy or ended or api.phase != "player":
		return false
	var ok = f.call()
	var ev: Array = api.take_events()
	var np := _api_not_ported()
	if np != "":
		_error("NOT PORTED: " + np)
	if ev.is_empty() and not ok:
		return false
	batches.append({"events": ev, "view": api.view()})
	_clear_overlay()
	_runner()
	return bool(ok)


# Threads (the scene enforces this; the rules API locks only step()): the rules are never used by two threads at once.
# The enemy's step() and the threat map run on worker threads. Every main-thread path that reads or changes the rules
# first calls _api_join(): it finishes a running threat map at once (its result is kept) and answers false while the enemy
# is thinking, so the caller skips the rules and draws from the last view instead. _exit_tree drains both tasks.
var _think_tid := -1
var _threat_tid := -1


# The rules only through battle_api.gd (the verifier's rule, Oct 26): the wrappers below are the API's; until each lands
# in battle_api.gd the marked fallback reads api.R in this one place only.
func _api_battle_kind() -> String:
	if api.has_method("battle_kind"):
		return str(api.battle_kind())
	# fallback until battle_api exposes it: read once in _begin, before any worker task runs
	var B = api.R.B
	if B is Dictionary and B.get("cfg") is Dictionary:
		return str(B["cfg"].get("kind", ""))
	return ""


func _api_tables() -> Dictionary:
	if api.has_method("tables"):
		return api.tables()
	return api.R.TB  # fallback until battle_api.tables() lands


func _api_admiral() -> String:
	if api == null:
		return ""
	if api.has_method("run_info"):
		return str(api.run_info().get("admiral", ""))
	return str(api.R.RUN.get("admiral", "")) if api.R.RUN is Dictionary else ""  # fallback until battle_api.run_info() lands


func _api_set_ai(level: String) -> void:
	if api.has_method("set_ai_level"):
		api.set_ai_level(level)
	else:
		api.R.AI_LEVEL = level  # fallback until battle_api.set_ai_level() lands


func _api_not_ported() -> String:
	if api.has_method("take_not_ported"):
		return api.take_not_ported()
	var np: String = api.R.not_ported  # fallback until battle_api.take_not_ported() lands
	api.R.not_ported = ""
	return np


static func _jt(x) -> bool:  # JS truthiness, as the rules' jt
	if x == null:
		return false
	match typeof(x):
		TYPE_BOOL: return x
		TYPE_INT: return x != 0
		TYPE_FLOAT: return x != 0.0 and not is_nan(x)
		TYPE_STRING: return x != ""
	return true


func _api_join() -> bool:
	if api == null:
		return false
	if _threat_tid >= 0:
		WorkerThreadPool.wait_for_task_completion(_threat_tid)
		_threat_tid = -1
		_threat_done()
	return not thinking


func _exit_tree() -> void:
	if _threat_tid >= 0:
		WorkerThreadPool.wait_for_task_completion(_threat_tid)
		_threat_tid = -1
	if _think_tid >= 0:
		WorkerThreadPool.wait_for_task_completion(_think_tid)
		_think_tid = -1


# Reduce flashing and Screen shake (settings, and the battle menu): reach G4's fx live
var reduce_flashing := false
var shake_scale := 1.0


func set_fx_opts(rf: bool, sh: float) -> void:
	reduce_flashing = rf
	shake_scale = sh
	if gfx != null:
		if "reduce_flashing" in gfx:
			gfx.reduce_flashing = rf
		if "shake_scale" in gfx:
			gfx.shake_scale = sh


# Every bright flash the scene itself asks for (boarding, ramming, blink, risen wrecks, nova, launches) goes through G4's
# fx budget (3 counted flashes per rolling second, none in reduce mode: fx.pop draws a ring and a glow instead). The old
# placeholder sprite only draws when G4's fx is missing, under the same rules.
var _stub_flashes: Array = []


func _flash(p: Vector3, size: float, col: Color, dur := 0.35, delay := 0.0, light := true) -> void:
	if gfx != null and gfx.has_method("pop"):
		var T: float = float(gfx.now) + delay
		gfx.pop(p, T, col, size * 0.5, 3.0, Vector3.UP, clampf(dur * 0.5, 0.1, 0.4))
		if light and gfx.has_method("light"):
			gfx.light(p, T, dur, 2.0, col, 0)
		return
	if reduce_flashing:
		return
	var now := Time.get_ticks_msec() / 1000.0 + delay
	_stub_flashes = _stub_flashes.filter(func(t): return now - float(t) < 1.0)
	if _stub_flashes.size() >= 3:
		return
	_stub_flashes.append(now)
	fx.flash(p, size, col, dur, delay, light)


func _error(m: String) -> void:
	errors.append(m)
	push_warning(m)


func wait(ms: float) -> void:
	await get_tree().create_timer(maxf(ms, 1.0) / 1000.0 * speed).timeout


# The round budget (B2: a round's enemy time under 15 s at worst): once the enemy has used 8 s of a round, everything it
# still plays speeds up smoothly, reaching 0.35 of its pace by 13 s, like an automatic hurry at the end of a long round.
static func _round_budget_k(used: float) -> float:
	if used <= 8.0:
		return 1.0
	return lerpf(1.0, 0.35, clampf((used - 8.0) / 5.0, 0.0, 1.0))


func _enemy_pace_k() -> float:
	var n := 0
	for u in V["units"]:
		if u["side"] == "enemy" and not u["squadron"] and not u["dead"]:
			n += 1
	return minf(1.0, maxf(float(PACE["bigMin"]), sqrt(float(PACE["bigRef"]) / maxf(1.0, n))))


func _player_pending() -> int:
	var n := 0
	for u in V["units"]:
		if u["side"] == "player" and not u["squadron"] and not u["dead"] and not u["activated"] and not u["active"]:
			n += 1
	return n


var dying := {}               # units that die in the batch being played (their killing volley waits for its impacts)


func _play_batch(bt: Dictionary) -> void:
	var evs: Array = bt["events"]
	var enemy := false
	dying.clear()
	for e in evs:
		if e["t"] == "activation" and e["side"] == "enemy":
			enemy = true
		if e["t"] == "death" and e.get("unit") != null:
			dying[str(e["unit"])] = true
	speed = user_speed
	var t_batch := game_t
	if enemy:
		speed = minf(speed, float(PACE["skip"]) if skip else (float(PACE["enemy"]) if _player_pending() > 0 else float(PACE["tail"])) * _enemy_pace_k())
	var base_speed := speed
	var i := 0
	while i < evs.size():
		var e: Dictionary = evs[i]
		if e["t"] == "fire":
			var grp: Array = []
			var j := i + 1
			while j < evs.size() and evs[j]["t"] in ["hit", "system", "shield_down", "burning"] and str(evs[j].get("target", evs[j].get("unit"))) == str(e["target"]):
				grp.append(evs[j])
				j += 1
			var tf := game_t
			await _play_fire(e, grp)
			if enemy:
				pace_kind["fire"] = float(pace_kind.get("fire", 0.0)) + game_t - tf
				speed = base_speed * _round_budget_k(float(pace_enemy.get(int(V.get("round", 0)), 0.0)) + game_t - t_batch)
				if skip:
					speed = minf(speed, float(PACE["skip"]))
			i = j
			continue
		var te := game_t
		await _play_event(e)
		if enemy:
			pace_kind[str(e["t"])] = float(pace_kind.get(str(e["t"]), 0.0)) + game_t - te
			speed = base_speed * _round_budget_k(float(pace_enemy.get(int(V.get("round", 0)), 0.0)) + game_t - t_batch)
		if skip and enemy:
			speed = minf(speed, float(PACE["skip"]))
		i += 1
	if enemy:
		var ta := game_t
		await wait(float(PACE["aiEnd"]))
		pace_kind["aiEnd"] = float(pace_kind.get("aiEnd", 0.0)) + game_t - ta
		if not cam_saved.is_empty():
			cam.t = cam_saved["t"]
			cam_saved = {}
		hud.set_chip("")
		skip = false
		var rk := int(V.get("round", 0))
		pace_enemy[rk] = float(pace_enemy.get(rk, 0.0)) + game_t - t_batch
		if args.has("pace-trace"):
			var kinds_b := {}
			for e2 in evs:
				kinds_b[str(e2["t"])] = int(kinds_b.get(str(e2["t"]), 0)) + 1
			print("[pace] round %d batch %.2f s speed %.2f events %s" % [rk, game_t - t_batch, speed, JSON.stringify(kinds_b)])
	speed = user_speed


func _pos(id) -> Vector3:
	if views.has(id):
		return (views[id] as Node3D).position
	return Vector3.ZERO


func _name(id) -> String:
	return str(VU[id]["name"]) if VU.has(id) else "?"


func _side(id) -> String:
	return str(VU[id]["side"]) if VU.has(id) else "enemy"


func _who(id) -> String:
	return "p" if _side(id) == "player" else "e"


var voice = null   # story hook: godot/story/battle_voice.gd (null when the story folder is missing)


func _play_event(e: Dictionary) -> void:
	if voice != null:   # story hook
		for l in voice.on_event(e):
			hud.add_log(l["text"], l["kind"])
	match e["t"]:
		"round":
			_log("Round %d." % int(e["round"]), "x")
			fired_in_act.clear()
			if int(e["round"]) > 1 or not bot:
				sfx.turn("round")
				hud.banner("Round %d" % int(e["round"]))
				await wait(float(PACE["banner"]) + 140.0)
		"log":
			hud.add_log(str(e.get("text", "")), str(e.get("kind", "")) if e.get("kind") != null else "")
		"wing":
			# a squadron appears beside its carrier: draw it now (the view after the batch fills in the rest)
			if not views.has(e["unit"]):
				var par: Dictionary = VU.get(e.get("parent"), {})
				var wu := {"id": e["unit"], "side": par.get("side", "enemy"), "fac": par.get("fac", "hegemony"), "cls": "Squadron", "tpl": str(e.get("kind", "fighter")),
					"q": int(e["q"]), "r": int(e["r"]), "facing": int(par.get("facing", 0)), "hp": 1, "maxHp": 1, "sh": [0, 0, 0, 0], "shMax": 0, "size": 0.2, "squadron": true, "flagship": false, "name": ""}
				_make_view(wu)
				if gfx != null and gfx.has_method("launch") and e.get("parent") != null:
					gfx.launch(str(e["parent"]), str(e["unit"]))
				else:
					_flash(board.hex_world(int(e["q"]), int(e["r"]), 2.0), 10.0, Color(1, 0.8, 0.5), 0.4)
				sfx.play("launch", {"pos": board.hex_world(int(e["q"]), int(e["r"]))})
			await wait(220.0)
		"torpedo":
			# a salvo launches into its lane and parks short of the aim hex until the firing side's next turn
			var aim: Vector3 = board.hex_world(int(e["aim"]["q"]), int(e["aim"]["r"]), 1.5)
			var fac := str(VU.get(e["unit"], {}).get("fac", "hegemony"))
			sfx.torp(fac, _pos(e["unit"]))
			if gfx != null and gfx.has_method("torp_lane"):
				gfx.torp_lane(str(e["id"]), str(e["unit"]), aim, 1)
				gfx.torp_launch(str(e["id"]))
			else:
				_torp_marker(str(e["id"]), _pos(e["unit"]), aim, fac)
			_float(e["unit"], "Torpedoes away", Color("#f0b35a"), -24)
			await wait(700.0)
		"torpedo_miss":
			if gfx != null and gfx.has_method("torp_lane_clear"):
				gfx.torp_lane_clear(str(e["id"]))
			_torp_clear(str(e["id"]))
			await wait(300.0)
		"risen":
			# a Deathless wreck reassembles: the ship stands up again where it lay
			var sv = views.get(e["unit"])
			if sv != null:
				sv.revive()
				sv.position = board.hex_world(int(e["q"]), int(e["r"]))
				if gfx != null and gfx.has_method("remove_ship"):
					gfx.remove_ship(str(e["unit"]))
					var ru: Dictionary = VU.get(e["unit"], {})
					gfx.add_ship(str(e["unit"]), sv, {"faction": str(ru.get("fac", "deathless")), "meshes": sv.meshes, "cls": str(ru.get("cls", "")), "size": float(ru.get("size", 0.5)), "squadron": false, "flagship": bool(ru.get("flagship", false))})
					sv.fx_engines = true
				wrecked.erase(e["unit"])
				_flash(sv.position + Vector3(0, 2, 0), 16.0, Color(0.2, 1.0, 0.4), 0.8)
			_float(e["unit"], "Risen", Color("#7dff9b"), -30)
			await wait(600.0)
		"stance":
			_float(e["unit"], "Wings: %s" % str(e["stance"]), Color("#9fd4ff"), -24)
		"blink":
			var sv = views.get(e["unit"])
			if sv != null:
				var c: Color = HT.FAC3D.get(str(VU.get(e["unit"], {}).get("fac", "ithar")), HT.FAC3D["ithar"])["eng"]
				_flash(sv.position + Vector3(0, 2, 0), 18.0, c, 0.5)
				sfx.play("phase", {"pos": sv.position})
				await wait(250.0)
				sv.position = board.hex_world(int(e["to"]["q"]), int(e["to"]["r"]))
				_flash(sv.position + Vector3(0, 2, 0), 18.0, c, 0.5)
				await wait(250.0)
		"side":
			if e["side"] == "player":
				hud.set_chip("")
		"activation":
			fired_in_act.erase(e["unit"])
			if e["side"] == "enemy":
				hud.set_chip("▼ Enemy acting: %s (Enter to hurry)" % _name(e["unit"]))
				if views.has(e["unit"]):
					for sv in views.values():
						sv.set_selected(false)
					views[e["unit"]].set_selected(true, Color(0.79, 0.64, 1.0))
					# follow activations (the browser's G.follow): ease the camera toward the acting enemy, back after
					if follow and not bot:
						if cam_saved.is_empty():
							cam_saved = {"t": cam.t, "r": cam.r}
						cam.t = cam.t.lerp(Vector3(_pos(e["unit"]).x, 0, _pos(e["unit"]).z), 0.6)
				await wait(float(PACE["aiGap"]))
		"move":
			await _play_move(e["unit"], e["path"], false)
		"pulled":
			await _play_move(e["unit"], [{"q": e["to"]["q"], "r": e["to"]["r"], "f": VU[e["unit"]]["facing"] if VU.has(e["unit"]) else 0}], false)
			_float(e["unit"], "Pulled in", Color("#c79bff"))
		"hit":
			_apply_hit(e)
			if e.get("target") != null:
				_impact(e["target"], e, Color(1, 0.6, 0.3))
				_float_hit(e["target"], float(e["shield"]), float(e["hull"]), e["crit"])
			await wait(160.0)
		"shield_down":
			var d: Dictionary = disp.get(e["unit"], {})
			if d.has("sh"):
				d["sh"][int(e["quad"])] = 0
			_float(e["unit"], "Shields down", Color("#9fe2ff"), -40)
			sfx.shield(_pos(e["unit"]), true)
		"section_down":
			var sec := str(e["section"])
			_log("%s: %s destroyed. %s" % [_name(e["unit"]), SEC_NAME.get(sec, sec), "Forward weapons silenced." if sec == "prow" else "Broadsides and shield generator gone." if sec == "mid" else "Engines crippled."], "e" if _side(e["unit"]) == "player" else "p")
		"system":
			_log("%s: %s." % [_name(e["unit"]), str(e["text"])], "e" if _side(e["unit"]) == "player" else "p")
		"burning":
			_float(e["unit"], "Fire on deck", Color("#f08a4b"), -24)
		"tick":
			var d: Dictionary = disp.get(e["unit"], {})
			if d.has("hp"):
				d["hp"] = float(d["hp"]) - float(e["hull"])
			var lbl := {"fire": ["Fire", "#f08a4b"], "acid": ["Acid", "#c8e04a"], "tidal": ["Tidal stress", "#c79bff"], "storm": ["Ion storm", "#9fd4ff"]}.get(str(e["kind"]), ["", "#ffffff"])
			_float(e["unit"], "%s −%d" % [lbl[0], int(e["hull"])] if float(e["hull"]) > 0 else str(lbl[0]), Color(lbl[1]))
			if gfx != null and gfx.has_method("tick"):
				gfx.tick(str(e["unit"]), str(e["kind"]))
			await wait(120.0)
		"ability":
			var ab := str(e["ab"])
			var A = TBL.get("ABILITIES", {}).get(ab, {})
			if ab != "launch":
				_log("%s: %s." % [_name(e["unit"]), str(A.get("n", ab))], _who(e["unit"]))
			var c: Color = HT.FAC3D.get(str(VU.get(e["unit"], {}).get("fac", "hegemony")), HT.FAC3D["hegemony"])["eng"]
			if gfx != null and gfx.has_method("ability"):
				gfx.ability(str(e["unit"]), ab)
			else:
				_flash(_pos(e["unit"]) + Vector3(0, 2, 0), 18.0, c, 0.5)
			if ab == "blink" and e.get("hex") != null:
				sfx.play("phase", {"pos": _pos(e["unit"])})
				var sv = views.get(e["unit"])
				if sv != null:
					sv.position = board.hex_world(e["hex"]["q"], e["hex"]["r"])
					_flash(sv.position + Vector3(0, 2, 0), 18.0, c, 0.5)
			elif ab == "nova" and e.get("hex") != null:
				sfx.play("charge", {"pos": _pos(e["unit"])})
				await wait(500.0)
				var p: Vector3 = board.hex_world(e["hex"]["q"], e["hex"]["r"], 2.0)
				fx.bolt(_pos(e["unit"]) + Vector3(0, 2, 0), p, Color(1, 0.8, 0.5), 0.35 * speed, 0.0, 3.0)
				await wait(350.0)
				_flash(p, 60.0, Color(1, 0.7, 0.4), 0.8)
				sfx.boom(1.0, p)
			await wait(300.0)
		"order":
			var O = TBL.get("ORDERS", {}).get(str(e["order"]), {})
			_log("%s: %s." % [_name(e["unit"]), str(O.get("n", e["order"]))], _who(e["unit"]))
			if e["order"] == "brace":
				_float(e["unit"], "Braced", Color("#9fd4ff"), -24)
			await wait(200.0)
		"ram":
			await _play_move(e["unit"], e["path"], true)
			sfx.boom(0.8, _pos(e["target"]))
			_flash(_pos(e["target"]) + Vector3(0, 2, 0), 30.0, Color(1, 0.7, 0.4), 0.6)
			_log("%s rams %s at full speed: %d to its %s, %d back to the ram." % [_name(e["unit"]), _name(e["target"]), int(e["dmg"]), SEC_NAME.get(str(e["section"]), str(e["section"])), int(e["recoil"])], _who(e["unit"]))
			var d: Dictionary = disp.get(e["target"], {})
			if d.has("hp"):
				d["hp"] = float(d["hp"]) - float(e["dmg"])
			var d2: Dictionary = disp.get(e["unit"], {})
			if d2.has("hp"):
				d2["hp"] = float(d2["hp"]) - float(e["recoil"])
			await wait(500.0)
		"board":
			var res := str(e["result"])
			var who := _who(e["unit"])
			if res == "capture":
				_log("Boarding parties from %s take %s. It now fights for %s." % [_name(e["unit"]), _name(e["target"]), "you" if _side(e["unit"]) == "player" else "the enemy"], who)
				_float(e["target"], "Captured", Color("#f0b35a"), -30)
			elif res == "overrun":
				_log("%s's boarders overrun %s, but the last of its crew hold the bridge." % [_name(e["unit"]), _name(e["target"])], who)
			else:
				_log("%s boards %s: %d defenders killed, %d boarders lost." % [_name(e["unit"]), _name(e["target"]), int(e["kill"]), int(e["loss"])], who)
			_flash(_pos(e["target"]) + Vector3(0, 2, 0), 14.0, Color(1, 0.8, 0.5), 0.5)
			await wait(600.0)
		"command_warning":
			var C = _command(str(e["id"]))
			_log("%s is preparing %s. It strikes next round." % [_name(e["unit"]), str(C.get("n", e["id"]))], "e")
			hud.banner("%s next round" % str(C.get("n", e["id"])), Color("#ff8a6a"))
			sfx.play("ui_alert")
			await wait(float(PACE["banner"]) + 140.0)
		"command":
			var C = _command(str(e["id"]))
			_log("%s: %s!" % [_name(e["unit"]), str(C.get("n", e["id"]))], "e" if e["side"] == "enemy" else "p")
			hud.banner(str(C.get("n", e["id"])), Color("#ff8a6a") if e["side"] == "enemy" else Color("#d0a64b"))
			await wait(float(PACE["banner"]) + 140.0)
		"wreck":
			wrecked[e["unit"]] = true
			_log("The wreck of %s drifts in place, blocking movement and fire." % _name(e["unit"]), "x")
		"death":
			await _play_death(e)
		"fled":
			var sv = views.get(e["unit"])
			if gfx != null and gfx.has_method("jump_out"):
				gfx.jump_out(str(e["unit"]))
				if sv != null:
					sv.dead = true
			elif sv != null:
				sv.flee()
			_log("%s leaves the battle." % _name(e["unit"]), "e" if _side(e["unit"]) == "player" else "s")
			await wait(300.0)
		"end":
			pass


# the battle log: the rules' own log lines (G1 log events, word for word as the game); the scene's own lines are kept
# only as a fallback for a rules build without log events
var rules_log := true


func _log(m: String, c: String) -> void:
	if not rules_log:
		hud.add_log(m, c)


func _command(id: String) -> Dictionary:
	for c in (TBL.get("COMMANDS", {}).values() if TBL.get("COMMANDS") is Dictionary else TBL.get("COMMANDS", [])):
		if c is Dictionary and str(c.get("id", "")) == id:
			return c
	return {"n": id}


# a burn along a path (fx3d.js animPath timing, with the B2 PACE.move factor)
func _play_move(id, path: Array, charge: bool) -> void:
	var sv = views.get(id)
	if sv == null or path.is_empty():
		return
	var u: Dictionary = VU.get(id, {})
	var keys: Array = [{"s": 0.0, "pos": Vector3(sv.position.x, 0, sv.position.z)}]
	var yaws: Array = [{"s": 0.0, "yaw": sv.cur_yaw}]
	var alts: Array = [{"s": 0.0, "y": 0.0}]
	var s := 0.0
	var la: float = sv.cur_yaw
	var size := float(u.get("size", 0.5))
	var mass := 0.0 if bool(u.get("squadron", false)) else clampf((size - 0.3) / 0.6, 0.0, 1.0)
	var cin := movement != "brisk" and not bool(u.get("squadron", false))
	for st in path:
		var a: float = la + angle_difference(la, ShipView.yaw_of(st["f"]))
		if _jt(st.get("rot")):
			s += float(PACE["rot"])
			yaws.append({"s": s, "yaw": a})
		else:
			s += 1.0
			keys.append({"s": s, "pos": board.hex_world(st["q"], st["r"])})
			yaws.append({"s": s, "yaw": a})
			var ov := float(st.get("over", 0)) if st.get("over") != null else 0.0
			alts.append({"s": s, "y": (9.0 if ov > 0 else -7.5) if ov != 0.0 else 0.0})
		la = a
	if float(keys[-1]["s"]) < s:
		keys.append({"s": s, "pos": keys[-1]["pos"]})
	var per := (430.0 if size > 0.8 else 350.0 if size > 0.6 else 280.0) * float(MOVE_PER.get(str(u.get("fac", "")), 1.0))
	var dur := minf((per * maxf(s, 0.001) + 260.0) * (0.72 if charge else 1.0) * float(PACE["move"]), 3600.0) / 1000.0
	sv.speed_k = 1.0
	if cin:
		sv.play_moves(_move_segments(sv, path, mass, args.has("flip-burn") and str(u.get("cls", "")) in FLIP_CLASSES), dur * speed, {"mass": mass})
	else:
		sv.play_path(keys, yaws, alts, s, dur * speed, {"mass": mass})
	if size > 0.3:
		sfx.play("engine", {"pos": sv.position, "gain": minf(1.0, 0.55 + size * 0.6)})
	var eng_on: bool = gfx != null and gfx.has_method("set_engine")
	while sv.burning() and not sv.dead:
		if skip:
			sv.speed_k = float(PACE["skip"])
		if eng_on:
			# the main drive glows only while it pushes the ship ahead (G4 fx engine level: idle, 2 full burn)
			gfx.set_engine(str(id), lerpf(ENGINE_IDLE, 2.0, float(sv.thrust)) if cin else clampf(1.0 + float(sv.thrust), 0.5, 2.2))
		if move_frames != "":
			await _snap("f")
		else:
			await get_tree().process_frame
	if eng_on:
		gfx.set_engine(str(id), ENGINE_IDLE if cin else 1.0)


# Cinematic moves as segments from rest to rest (ship_view.gd play_moves): consecutive turn steps make one turn about
# the centre; consecutive translation steps (ahead, sidestep, back off: the heading never changes in them) make one run.
# Weights share the move's time (the B2 pace is unchanged): a turn step weighs PACE.rot, a heavier hull spending a little
# more of its time on a turn; a run weighs its steps plus a little for its thrust-up and thrust-down.
const ENGINE_IDLE := 0.35     # the main drive at rest or coasting: a pilot glow, the full plume only when it pushes


# hulls big enough for the flip-and-burn test (R55, --flip-burn): cruisers and up
const FLIP_CLASSES := ["Cruiser", "Carrier", "Battleship", "Dreadnought", "Super-dreadnought", "Battle-barge", "Bio-titan", "Ark", "Tomb-ark"]


func _move_segments(sv, path: Array, mass: float, flip_ok := false) -> Array:
	var out: Array = []
	var la: float = sv.cur_yaw
	var pos := Vector3(sv.position.x, 0, sv.position.z)
	for st in path:
		var a: float = la + angle_difference(la, ShipView.yaw_of(st["f"]))
		if _jt(st.get("rot")):
			if out.is_empty() or out[-1]["kind"] != "turn":
				out.append({"kind": "turn", "a0": la, "a1": a, "w": 0.0})
			out[-1]["a1"] = a
			out[-1]["w"] = float(out[-1]["w"]) + float(PACE["rot"]) * lerpf(0.9, 1.25, mass)
		else:
			if out.is_empty() or out[-1]["kind"] != "run":
				out.append({"kind": "run", "pts": [pos], "yaw": la, "w": 0.35, "fwd": 0, "other": 0})
			if _jt(st.get("slip")) or _jt(st.get("rev")) or (st.get("over") != null and float(st.get("over")) != 0.0):
				out[-1]["other"] = int(out[-1]["other"]) + 1
			else:
				out[-1]["fwd"] = int(out[-1]["fwd"]) + 1
			var ov := float(st.get("over", 0)) if st.get("over") != null else 0.0
			var p: Vector3 = board.hex_world(st["q"], st["r"])
			p.y = (9.0 if ov > 0 else -7.5) if ov != 0.0 else 0.0
			out[-1]["pts"].append(p)
			out[-1]["w"] = float(out[-1]["w"]) + 1.0
			pos = Vector3(p.x, 0, p.z)
		la = a
	# flip and burn (test): a straight run of 3 hexes or more on a cruiser or bigger
	if flip_ok:
		for g in out:
			if g["kind"] == "run" and int(g["other"]) == 0 and int(g["fwd"]) >= 3:
				g["flip"] = true
	# a run that ends over or under an obstacle still comes back to the board plane
	for g in out:
		if g["kind"] == "run":
			var last: Vector3 = g["pts"][-1]
			if absf(last.y) > 0.01:
				g["pts"].append(Vector3(last.x, 0, last.z))
	return out


# How long a G4 volley holds the battle, as `total` (the caller waits total * sp): the effect's own length scaled by the
# B2 pace like every other animation (enemy 0.5, tail 0.38, the big-fleet ramp, hurry 0.18, later volleys 0.5), so its
# tail overlaps the next volley (its hits still land on their own timers). A volley that kills waits for its last
# impact, so the death never plays before the blow lands. (Before: done / sp, so the pace cancelled out and every enemy
# volley played at full length.)
# At a paced speed (k < 1) the hold is the browser's own volley length (cap) when G4's effect runs longer, as the browser
# paced it; at full speed (your own first volley) the effect plays out in full.
func _fx_wait(done: float, impacts: Array, sp: float, kills := false, cap := INF) -> float:
	var last := 0.0
	for t in impacts:
		last = maxf(last, float(t))
	var k := maxf(sp, 0.01)
	if k >= 1.0:
		return maxf(done, (last + 0.08) if kills else 0.0)
	# deep in the round budget (very low speed) a killing volley lets go halfway to its last impact: the death starts as
	# the final hits land
	var floor_t := ((last + 0.08) * (0.5 if k < 0.12 else 1.0)) if kills else 0.0
	return maxf(minf(done, cap) * k, floor_t) / k


func _wfam(u: Dictionary, w: Dictionary) -> String:
	var k := str(w["kind"])
	if u.get("squadron", false):
		return "sq"
	if k == "flak":
		return "flak"
	if k == "torp":
		return "torp"
	if k == "lance":
		return "ion" if str(w.get("weapon_id", "")) == "ion" else "lance"
	if k == "gauss":
		return "rail"
	if k == "bio":
		return "spine" if str(w.get("weapon_id", "")) == "bioplasma" else "glob"
	return {"voidsworn": "las", "hegemony": "plasma", "corsair": "tracer", "chorus": "spine", "ithar": "needle", "deathless": "rail"}.get(str(u.get("fac", "")), "shell")


# fx3d.js cineWants and cineFrame: a side-on shot of the big moments (lances, torpedoes and novas on bosses or a nearly
# dead target, capital volleys on them, kills of bigger ships), letterboxed, back to the board after
func _cine_wants(kind: String, a_id, t_id) -> bool:
	if cine == "off" or bot or shots_dir != "":
		return false
	if cine == "all":
		return true
	var a: Dictionary = VU.get(a_id, {})
	var t: Dictionary = VU.get(t_id, {})
	var big: bool = bool(a.get("flagship", false)) or bool(t.get("flagship", false))
	var low: bool = not t.is_empty() and float(disp.get(t_id, {}).get("hp", t.get("hp", 1))) <= float(t.get("maxHp", 1)) * 0.35
	match kind:
		"kill":
			return not t.is_empty() and not t.get("squadron", false) and (float(t.get("size", 0)) >= 0.6 or big)
		"lance", "torp", "nova":
			return true
		"volley":
			return float(a.get("size", 0)) >= 0.7 and (big or low)
	return false


func _cine_frame(a_id, t_id) -> void:
	var pa := _pos(a_id)
	var pt := _pos(t_id)
	var mid := (pa + pt) * 0.5
	mid.y = 0
	var dist := Vector2(pt.x - pa.x, pt.z - pa.z).length()
	# Godot camera azimuth: side-on to the line of fire, the side nearer the current view
	var base := atan2(-(pt.z - pa.z), pt.x - pa.x)
	var al := base + PI / 2.0
	var al2 := base - PI / 2.0
	var cur: float = cam.a
	al = cur + angle_difference(cur, al)
	al2 = cur + angle_difference(cur, al2)
	if cine_saved.is_empty():
		cine_saved = {"a": cam.a, "b": cam.b, "r": cam.r, "t": cam.t}
	cam.a = al if absf(al - cur) < absf(al2 - cur) else al2
	cam.b = 1.02
	cam.r = clampf(dist * 1.25 + 34.0, 60.0, 200.0)
	cam.t = mid
	hud.letterbox(true)


func _cine_release() -> void:
	if cine_saved.is_empty():
		return
	cam.a = cine_saved["a"]
	cam.b = cine_saved["b"]
	cam.r = cine_saved["r"]
	cam.t = cine_saved["t"]
	cine_saved = {}
	hud.letterbox(false)


func _play_fire(e: Dictionary, grp: Array) -> void:
	var a_id = e["unit"]
	var t_id = e["target"]
	var ckind := "lance" if str(e["kind"]) == "lance" else "torp" if str(e["kind"]) == "torp" else "volley"
	var cined := _cine_wants(ckind, a_id, t_id)
	if cined:
		_cine_frame(a_id, t_id)
		await wait(320.0)
	var u: Dictionary = VU.get(a_id, {})
	var fac := str(u.get("fac", "hegemony"))
	var P: Dictionary = HT.FAC3D.get(fac, HT.FAC3D["hegemony"])
	var fam := _wfam(u, e)
	var shots: Array = e["shots"]
	var n := shots.size()
	var from := _pos(a_id) + Vector3(0, 1.6, 0)
	var to := _pos(t_id) + Vector3(0, 1.2, 0)
	var vk := 1.0
	var nf := int(fired_in_act.get(a_id, 0))
	if nf > 0:
		vk = float(PACE["volley"])
	fired_in_act[a_id] = nf + 1
	var sp := speed * vk
	var hits: Array = []
	var sys_txt := ""
	for g in grp:
		if g["t"] == "hit":
			hits.append(g)
		elif g["t"] == "system":
			sys_txt = str(g["text"])
	var col: Color = P["beam"] if fam in ["lance", "ion"] else P["bolt"]
	if fam == "ion":
		col = Color(0.45, 0.75, 1.0)
	var tsv = views.get(t_id)
	var L: float = tsv.L if tsv != null else 10.0
	var shield_col: Color = HT.FAC3D.get(str(VU.get(t_id, {}).get("fac", "hegemony")), P)["shield"]
	var total := 0.0
	var hi := 0
	# the browser's own length for this volley (fx3d.js timing), the cap for a paced wait
	var btot := (0.32 + n * 0.25 + 0.15) if fam in ["lance", "ion"] else ((0.32 + n * 0.12 + 0.84) if fam == "torp" else (n * 0.07 + 0.49))
	if e.has("torpedo") and e.get("from") != null:
		from = board.hex_world(int(e["from"]["q"]), int(e["from"]["r"]), 1.5)
		_torp_clear(str(e["torpedo"]))
	if e.has("torpedo") and gfx != null and gfx.has_method("torp_strike"):
		var hit0 := {}
		if not hits.is_empty():
			hit0 = {"shield": hits[0]["shield"], "hull": hits[0]["hull"], "section": hits[0].get("section", ""), "crit": hits[0]["crit"]}
		var r: Dictionary = gfx.torp_strike(str(e["torpedo"]), str(t_id), hit0)
		var imp: Array = r.get("impacts", [])
		for k in hits.size():
			var at: float = float(imp[mini(k, imp.size() - 1)]) if not imp.is_empty() else 0.8
			var h: Dictionary = hits[k]
			get_tree().create_timer(maxf(at, 0.001)).timeout.connect(func() -> void:
				_apply_hit(h)
				sfx.boom(0.8, _pos(t_id)))
		total = _fx_wait(float(r.get("done", 1.2)), imp, sp, dying.has(str(t_id)), btot)
	elif gfx != null and gfx.has_method("volley"):
		var hl: Array = []
		for h in hits:
			hl.append({"shield": h["shield"], "hull": h["hull"], "section": h.get("section", ""), "crit": h["crit"]})
		var r: Dictionary = gfx.volley(str(a_id), str(e["kind"]), str(t_id), {"weapon_id": str(e.get("weapon_id", "")), "shots": shots, "hits": hl, "quad": int(e["quad"]), "pd": int(e.get("pd", 0))})
		if fam in ["lance", "ion"]:
			sfx.lance(fam == "ion", fac, from)
		elif fam == "torp":
			sfx.torp(fac, from)
		else:
			sfx.gun(str(e["kind"]), fam == "sq", null if fam == "sq" else fam if fam in ["spine", "glob", "plasma", "las", "tracer", "needle", "rail"] else "shell", from)
		var imp: Array = r.get("impacts", [])
		for k in hits.size():
			var at: float = float(imp[k]) if k < imp.size() else 0.3
			var h: Dictionary = hits[k]
			get_tree().create_timer(maxf(at, 0.001)).timeout.connect(func() -> void:
				_apply_hit(h)
				if float(h["shield"]) > 0 and float(h["hull"]) <= 0:
					sfx.shield(_pos(t_id))
				else:
					sfx.hit(_pos(t_id), h["crit"]))
		total = _fx_wait(float(r.get("done", 0.6)), imp, sp, dying.has(str(t_id)), btot)
	elif fam in ["lance", "ion"]:
		sfx.lance(fam == "ion", fac, from)
		total = 0.32 + n * 0.25 + 0.15
		for i in n:
			var dl := (0.32 + i * 0.25) * sp
			var hit: bool = shots[i]
			var end := to if hit else to + (to - from).normalized() * 30.0 + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
			fx.beam(from, end, col, 0.22 * sp, dl, 1.0 if fam == "lance" else 1.3)
			if hit and hi < hits.size():
				_schedule_impact(t_id, hits[hi], dl + 0.05 * sp, L, shield_col, fam)
				hi += 1
	elif fam == "torp":
		sfx.torp(fac, from)
		total = 0.32 + n * 0.12 + 0.84
		for i in n:
			var dl := (0.32 + i * 0.12) * sp
			fx.bolt(from, to, col, 0.8 * sp, dl, 2.2, not shots[i])
			if shots[i] and hi < hits.size():
				_schedule_impact(t_id, hits[hi], dl + 0.8 * sp, L, shield_col, fam)
				hi += 1
	else:
		total = n * 0.07 + 0.49
		var style = null if fam == "sq" else fam if fam in ["spine", "glob", "plasma", "las", "tracer", "needle", "rail"] else "shell"
		sfx.gun(str(e["kind"]), fam == "sq", style, from)
		for i in n:
			var dl := i * 0.07 * sp
			var off := Vector3(randf_range(-1, 1), randf_range(-0.3, 0.6), randf_range(-1, 1)) * 0.25 * float(VU.get(a_id, {}).get("size", 0.5)) * 10.0
			fx.bolt(from + off, to, col, 0.24 * sp, dl, 1.1 if fam != "rail" else 1.5, not shots[i])
			if i % 2 == 1:
				sfx.gun(str(e["kind"]), fam == "sq", style, from)
			if shots[i] and hi < hits.size():
				_schedule_impact(t_id, hits[hi], dl + 0.24 * sp, L, shield_col, fam)
				hi += 1
	if shots_dir != "" and fire_shots < 4 and bot:
		fire_shots += 1
		await get_tree().create_timer(total * sp * 0.55).timeout
		_snap("fire_%d" % fire_shots)
		await get_tree().create_timer(total * sp * 0.45).timeout
	else:
		await get_tree().create_timer(total * sp).timeout
	# the log line and the floating numbers (battle.js fireWeapon)
	var sh_sum := 0.0
	var hull_sum := 0.0
	var crits := 0
	for h in hits:
		sh_sum += float(h["shield"])
		hull_sum += float(h["hull"])
		if h["crit"]:
			crits += 1
	var parts: Array = []
	if int(e.get("pd", 0)) > 0:
		parts.append("%d shot down by point defense" % int(e["pd"]))
	if hits.is_empty():
		parts.append("all shots miss")
		_float(t_id, "Miss", Color("#9a9384"))
	else:
		if sh_sum > 0:
			parts.append("%d to %s shields" % [int(sh_sum), QUAD_NAME[int(e["quad"])]])
		if hull_sum > 0:
			parts.append("%d hull" % int(hull_sum))
		if sh_sum <= 0 and hull_sum <= 0:
			parts.append("no damage")
		_float_hit(t_id, sh_sum, hull_sum, crits > 0)
	if crits > 0:
		parts.append("%d criticals" % crits if crits > 1 else "critical")
	_log("%s fires %s at %s: %s.%s" % [_name(a_id), str(e["name"]), _name(t_id), ", ".join(parts), " " + sys_txt + "!" if sys_txt != "" else ""], _who(a_id))
	for g in grp:
		if g["t"] == "shield_down":
			var d: Dictionary = disp.get(g["unit"], {})
			if d.has("sh"):
				d["sh"][int(g["quad"])] = 0
			_float(g["unit"], "Shields down", Color("#9fe2ff"), -40)
			sfx.shield(_pos(g["unit"]), true)
			if gfx != null and gfx.has_method("shield_break"):
				gfx.shield_break(str(g["unit"]), int(g["quad"]))
			elif tsv != null:
				fx.shield(tsv, L, int(g["quad"]), shield_col, 0.0, true)
		elif g["t"] == "burning":
			_float(g["unit"], "Fire on deck", Color("#f08a4b"), -24)
	await wait(80.0)
	if cined:
		await wait(900.0)
		_cine_release()


var torp_marks := {}      # salvo id -> placeholder marker (when G4's lanes are not in the build)


func _torp_marker(id: String, a: Vector3, aim: Vector3, fac: String) -> void:
	var col: Color = HT.FAC3D.get(fac, HT.FAC3D["hegemony"])["bolt"]
	var root := Node3D.new()
	add_child(root)
	var dir := (aim - a)
	var park := a + dir * 0.75
	var dot := Sprite3D.new()
	dot.texture = Fx.glow_tex()
	dot.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	dot.modulate = Color(col.r * 3, col.g * 3, col.b * 3)
	dot.pixel_size = 4.0 / 64.0
	dot.position = park
	root.add_child(dot)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 5.0
	tm.outer_radius = 5.6
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col.r, col.g, col.b, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = m
	ring.position = Vector3(aim.x, 0.2, aim.z)
	root.add_child(ring)
	torp_marks[id] = root


func _torp_clear(id: String) -> void:
	if torp_marks.has(id):
		(torp_marks[id] as Node).queue_free()
		torp_marks.erase(id)


func _schedule_impact(t_id, h: Dictionary, delay: float, L: float, shield_col: Color, fam: String) -> void:
	get_tree().create_timer(maxf(delay, 0.001)).timeout.connect(func() -> void:
		_apply_hit(h)
		var sv = views.get(t_id)
		if sv == null:
			return
		var p: Vector3 = sv.position + Vector3(randf_range(-0.3, 0.3) * L, 1.0, randf_range(-0.12, 0.12) * L)
		if float(h["shield"]) > 0 and float(h["hull"]) <= 0:
			fx.shield(sv, L, int(h["quad"]), shield_col)
			_flash(p, 4.0 + L * 0.25, shield_col, 0.25, 0.0, false)
			sfx.shield(p)
		else:
			_flash(p, 5.0 + L * 0.3 + (8.0 if fam == "torp" else 0.0), Color(1.0, 0.62, 0.3), 0.3)
			if fam == "torp":
				sfx.boom(0.8, p)
			elif fam in ["lance", "ion"]:
				sfx.hit(p, true)
			else:
				sfx.hit(p, h["crit"]))


func _apply_hit(h: Dictionary) -> void:
	var t_id = h.get("target")
	if t_id == null or not disp.has(t_id):
		return
	var d: Dictionary = disp[t_id]
	d["hp"] = maxf(0.0, float(d["hp"]) - float(h["hull"]))
	var q := int(h.get("quad", 0))
	if d["sh"] is Array and q < (d["sh"] as Array).size():
		d["sh"][q] = maxf(0.0, float(d["sh"][q]) - float(h["shield"]))


func _impact(t_id, h: Dictionary, col: Color) -> void:
	var sv = views.get(t_id)
	if sv == null:
		return
	_flash(sv.position + Vector3(0, 1.5, 0), 6.0 + sv.L * 0.3, col, 0.3)
	sfx.hit(sv.position, h.get("crit", false))


func _play_death(e: Dictionary) -> void:
	var id = e["unit"]
	var sv = views.get(id)
	if sv != null and _cine_wants("kill", e.get("by"), id) and cine_saved.is_empty():
		var by = e.get("by") if e.get("by") != null and views.has(e.get("by")) else id
		_cine_frame(by, id)
		get_tree().create_timer(1.6 * speed).timeout.connect(_cine_release)
	var cause := str(e.get("cause", "blast"))
	var friend := _side(id) == "player"
	var sq := bool(VU.get(id, {}).get("squadron", false))
	_log("%s %s." % [_name(id), "is shot down" if sq else "is destroyed"], "e" if friend else "p")
	if sv == null:
		return
	var L: float = sv.L
	var p: Vector3 = sv.position + Vector3(0, 2, 0)
	var big := L >= 14.0
	if gfx != null and gfx.has_method("death"):
		var t: float = float(gfx.death(str(id), cause))
		sfx.boom(0.22 + minf(0.3, L / 90.0) if sq else (1.2 if big else 0.6), p)
		sv.dead = true
		if sv.marker != null:
			sv.marker.visible = false
		sv.ring.visible = false
		hud.remove_plate(str(id))
		# a death is a key moment: it follows the pace only gently (half its hold at most on the enemy's turn, a quarter on
		# hurry) and a big hull always gets 0.8 s; G4's effect plays on either way
		var pk := clampf(speed, 0.25 if skip else 0.5, 1.0)
		var floor_k := clampf(speed / 0.35, 0.35, 1.0)   # under the round budget a big hull's hold shrinks too
		await get_tree().create_timer(maxf((0.8 if big else 0.3) * floor_k, t * 0.6 * minf(pk, floor_k))).timeout
		return
	_flash(p, 14.0 + L * 1.6, Color(1.0, 0.65, 0.3), 0.9)
	_flash(p + Vector3(L * 0.25, 1, 0), 8.0 + L * 0.8, Color(1.0, 0.85, 0.6), 0.5, 0.15 * speed)
	_flash(p - Vector3(L * 0.25, 0, 1), 8.0 + L * 0.8, Color(1.0, 0.5, 0.2), 0.6, 0.3 * speed)
	sfx.boom(0.22 + minf(0.3, L / 90.0) if sq else (1.2 if big else 0.6), p)
	sv.die(wrecked.has(id))
	hud.remove_plate(str(id))
	var dk := _enemy_pace_k() if not friend else 1.0
	await wait((0.68 if not sq else 0.25) * 1000.0 * maxf(0.4, dk))


# ---------------------------------------------------------------- end of battle

func _end_flow() -> void:
	ended = true
	var over = V.get("over")
	var win := str(over) == "win"
	await wait(500.0)
	sfx.sting(win)
	if music != null:
		if win:
			music.victory(boss_fight)
		else:
			music.defeat()
	hud.banner("Victory" if win else "Defeat", Color("#d0a64b") if win else Color("#e27f74"), 1.6)
	await get_tree().create_timer(1.2).timeout
	var lost := 0
	var killed := 0
	for u in V["units"]:
		if u["dead"] and not u["fled"]:
			if u["side"] == "player":
				lost += 1
			else:
				killed += 1
	result = {"result": "win" if win else "loss", "rounds": int(V["round"]), "killed": killed, "lost": lost, "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V,
		"pipeline_compiles": _pipe_count() - pipe_base if pipe_base >= 0 else -1, "pace": pace_stats()}
	var body := "%d enemy ship%s destroyed, %d of yours lost, in %d round%s." % [killed, "" if killed == 1 else "s", lost, int(V["round"]), "" if int(V["round"]) == 1 else "s"]
	if args.has("pace-report"):
		# --pace-report (with --bot): the battle's report with the enemy's time per round by event kind, then quit
		_quit_report()
		return
	if bot or args.has("bot-runs"):
		finished.emit(result)
		return
	if voice != null:   # story hook: your admiral's last word (or the Nemesis's gloat) on the end card
		var vl: String = voice.closing(win)
		if vl != "":
			body += "\n\n" + vl
	hud.show_end("Victory" if win else "Defeat", body, win, external)


# ---------------------------------------------------------------- selection, overlays, tips

# the rules' read-only UI facts for one ship (G1 ui_info: orders, ram, boarding, ability target hexes, every gun against
# every enemy), cached until the picture changes
var _ui_cache := {}


func _ui(id: String) -> Dictionary:
	if id == "" or not _api_join():
		return {}
	var k := "%s|%d|%d" % [id, batches.size(), hud.log_text.get_line_count()]
	if not _ui_cache.has(k):
		if _ui_cache.size() > 16:
			_ui_cache.clear()
		_ui_cache[k] = api.ui_info(id) if api.has_method("ui_info") else {}
	return _ui_cache[k]


func _wtarget(id: String, wi: int, tid: String) -> Dictionary:
	var ui := _ui(id)
	for w in ui.get("weapons", []):
		if int(w["i"]) == wi:
			for t in w["targets"]:
				if t["id"] == tid:
					return t
	return {}


func _vweapon_ready(id: String, wi: int) -> bool:
	var u: Dictionary = VU.get(id, {})
	for w in u.get("weapons", []):
		if int(w["i"]) == wi:
			return bool(w["ready"])
	return false


func _sel_unit() -> Dictionary:
	return VU.get(sel, {})


func _can_act() -> bool:
	return not busy and not warming and not _threat_busy and not ended and api != null and api.phase == "player"


func _usable(u: Dictionary) -> bool:
	# ui3d.js canUse: a ship that has not acted, while no other ship is mid-activation
	if u.is_empty() or u["side"] != "player" or u["dead"] or u["activated"] or u.get("squadron", false):
		return false
	for x in V["units"]:
		if x["active"] and x["id"] != u["id"]:
			return false
	return true


func select(id: String) -> void:
	sel = id
	inspect = ""
	armed = -1
	mode = ""
	hover_pick.clear()
	_update_reach()
	sfx.play("ui_select")
	_refresh_ui()


func _update_reach() -> void:
	reach_states = []
	reach_map.clear()
	reach_alt.clear()
	var u := _sel_unit()
	if not _can_act() or not _usable(u):
		return
	reach_states = api.reach(sel)
	_best_facing(u)


# ui3d.js bestFacingReach: on each hex, end on the facing that brings the most ready guns onto an enemy (cheapest on ties)
func _best_facing(u: Dictionary) -> void:
	var ru = api.unit(sel)
	var foes: Array = []
	for t in V["units"]:
		if t["side"] == "enemy" and not t["dead"]:
			foes.append(t["id"])
	var ready: Array = []
	for w in VU[sel]["weapons"]:
		if w["ready"] and w["kind"] != "flak":
			ready.append(int(w["i"]))
	var best := {}
	for st in reach_states:
		var k: String = board.key(st.q, st.r)
		if not reach_alt.has(k):
			reach_alt[k] = []
		reach_alt[k].append(st)
		var n := 0
		var sc := -float(st.cost) * 10.0 - float(st.get("t", 0))
		for wi in ready:
			for tid in foes:
				if api.in_reach(sel, wi, tid, st):
					n += 1
					break
		sc += n * 1000.0
		if not best.has(k) or sc > float(best[k]["sc"]):
			best[k] = {"st": st, "sc": sc, "n": n}
	for k in best:
		var st = best[k]["st"]
		st["guns"] = best[k]["n"]
		st["gunsOf"] = ready.size()
		reach_map[k] = st


func _firing_set(t_id: String) -> Array:
	var out: Array = []
	if not _api_join():
		return out
	var ru = api.unit(sel)
	if ru == null:
		return out
	var idx: Array = [armed] if armed >= 0 else range(ru["weapons"].size())
	for i in idx:
		if api.can_fire(sel, i, t_id):
			out.append(i)
	return out


func _attack_move(t_id: String):
	# v51 attack-move (the rules' attack_plan): an enemy your guns can't reach yet; burn to the best hex and fire on the way
	if not _api_join():
		return null
	var am = api.attack_plan(sel, t_id, [armed] if armed >= 0 else null)
	if am == null:
		return null
	return {"st": am["state"], "n": int(am["guns"]), "of": int(am["of"])}


# firing arcs as fans on the board under the selected ship (the game's arc fans): one per ready gun, its range and arc
var fan_root: Node3D
var fan_for := ""
var fan_key := ""
const ARC_SPAN := {"F": [-60.5, 60.5], "R": [119.5, 240.5], "S": [29.5, 150.5], "P": [-150.5, -29.5]}


func _fans(id: String) -> void:
	var ru = VU.get(id) if id != "" else null
	var k := ""
	if ru != null:
		k = "%s|%d|%d|%d" % [id, int(ru["q"]), int(ru["r"]), int(ru["facing"])]
		for w in ru["weapons"]:
			k += "1" if w["ready"] else "0"
	if k == fan_key:
		return
	fan_key = k
	if fan_root != null:
		fan_root.queue_free()
		fan_root = null
	if ru == null or not views.has(id):
		return
	fan_root = Node3D.new()
	views[id].add_child(fan_root)
	fan_root.position.y = -0.35
	var done := {}
	for w in ru["weapons"]:
		var arc := str(w["arc"])
		if not w["ready"] or w["kind"] == "flak" or not ARC_SPAN.has(arc):
			continue
		var rad: float = float(w["range"]) * board.HW + board.HS * 0.5
		var dk := "%s%d" % [arc, int(rad)]
		if done.has(dk):
			continue
		done[dk] = true
		var col: Color = {"lance": Color(1.0, 0.45, 0.3), "torp": Color(1.0, 0.75, 0.3), "gauss": Color(0.5, 1.0, 0.6)}.get(str(w["kind"]), Color(1.0, 0.62, 0.3))
		fan_root.add_child(_fan_mesh(ARC_SPAN[arc][0], ARC_SPAN[arc][1], rad, col))


func _fan_mesh(a0: float, a1: float, rad: float, col: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		var t0 := deg_to_rad(lerpf(a0, a1, float(i) / n))
		var t1 := deg_to_rad(lerpf(a0, a1, float(i + 1) / n))
		# ship frame: bow +X, starboard +Z (relAng > 0 is starboard)
		var p0 := Vector3(cos(t0), 0, sin(t0)) * rad
		var p1 := Vector3(cos(t1), 0, sin(t1)) * rad
		st.set_color(Color(col.r, col.g, col.b, 0.0))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(col.r, col.g, col.b, 0.16))
		st.add_vertex(p0)
		st.add_vertex(p1)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _clear_overlay() -> void:
	_fans("")
	board.set_overlay({}, {})
	arrow.visible = false
	path_dots.multimesh.instance_count = 0


func _overlay() -> void:
	if not _can_act():
		_clear_overlay()
		if threat_on:
			board.set_overlay(_threat_fills(), {})
		return
	var fills := {}
	var rings := {}
	if threat_on:
		fills = _threat_fills()
	var u := _sel_unit()
	if _usable(u):
		for k in reach_map:
			if not fills.has(k):
				fills[k] = REACH_C
			rings[k] = REACH_RING
		for e in V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not _firing_set(e["id"]).is_empty():
				rings[board.key(e["q"], e["r"])] = TARGET_RING
	_fans(sel if (arcs_on and _usable(u)) else "")
	if mode in ["nova", "blink", "launch"]:
		for h in _ability_hexes():
			fills[board.key(h["q"], h["r"])] = Color(0.55, 0.8, 1.0, 0.3)
			rings[board.key(h["q"], h["r"])] = Color(0.6, 0.85, 1.0, 0.8)
	if mode == "board" and not u.is_empty():
		for b in _ui(sel).get("board", []):
			var tu: Dictionary = VU.get(b["target"], {})
			if not tu.is_empty():
				rings[board.key(tu["q"], tu["r"])] = Color(1, 0.75, 0.3, 1)
	var hk: String = board.key(hover.x, hover.y)
	arrow.visible = false
	path_dots.multimesh.instance_count = 0
	if reach_map.has(hk) and _unit_at(hover.x, hover.y).is_empty():
		var st = _hover_state(hk)
		fills[hk] = REACH_HOT
		arrow.visible = true
		arrow.position = board.hex_world(st.q, st.r, 0.6)
		arrow.rotation.y = ShipView.yaw_of(st.f)
		var pts: Array = []
		var prev: Vector3 = board.hex_world(u["q"], u["r"], 0.5)
		for p in st.path:
			if _jt(p.get("rot")):
				continue
			var c: Vector3 = board.hex_world(p["q"], p["r"], 0.5)
			for j in 3:
				pts.append(prev.lerp(c, (j + 1) / 3.0))
			prev = c
		var mm := path_dots.multimesh
		mm.instance_count = pts.size()
		for j in pts.size():
			mm.set_instance_transform(j, Transform3D(Basis(), pts[j]))
	board.set_overlay(fills, rings)


func _hover_state(k: String):
	var st = reach_map[k]
	if hover_pick.has(k) and reach_alt.has(k):
		var alts: Array = reach_alt[k]
		st = alts[int(hover_pick[k]) % alts.size()]
	return st


var _threat_cache := {}
var _threat_key := ""


# ui3d.js computeThreat: for every enemy ship, every hex it can end its move on and every facing there, the guns that bear
# on each hex (range, arc, line of sight); the best end state counts per enemy, summed over enemies. Darker = more damage.
func _threat_fills() -> Dictionary:
	var key := "%d|%d|%d" % [int(V.get("round", 0)), batches.size(), hud.log_text.get_line_count()]
	if key != _threat_key and not _threat_busy and not busy and not thinking and api.phase == "player":
		_threat_key = key
		_threat_busy = true
		if api.has_method("threat_map"):
			# the rules' computeThreat (G1), off the main thread: nothing else calls the API while the player phase is idle
			var tid := WorkerThreadPool.add_task(func() -> void:
				_threat_next = api.threat_map())
			_threat_tid = tid
			_threat_wait(tid)
		else:
			_threat_busy = false
	var out := {}
	var mx := 1.0
	for k in _threat_cache:
		mx = maxf(mx, float(_threat_cache[k]))
	for k in _threat_cache:
		var f := float(_threat_cache[k]) / mx
		if f > 0.0:
			out[k] = Color(0.95, 0.18, 0.12, 0.08 + 0.4 * f)
	return out


var _threat_busy := false
var _threat_next := {}


func _threat_wait(tid: int) -> void:
	while _threat_tid == tid and not WorkerThreadPool.is_task_completed(tid):
		await get_tree().process_frame
	if _threat_tid != tid:
		return  # _api_join already finished it
	WorkerThreadPool.wait_for_task_completion(tid)
	_threat_tid = -1
	_threat_done()


func _threat_done() -> void:
	_threat_cache = _threat_next
	_threat_busy = false
	_overlay.call_deferred()


# target hexes for nova, blink and launch
func _ability_hexes() -> Array:
	if sel == "" or not (mode in ["nova", "blink", "launch"]):
		return []
	var out: Array = []
	for h in _ui(sel).get("ability", {}).get("hexes", []):
		out.append({"q": int(h["q"]), "r": int(h["r"])})
	return out


func _unit_at(q: int, r: int) -> Dictionary:
	for u in V.get("units", []):
		if not u["dead"] and int(u["q"]) == q and int(u["r"]) == r:
			return u
	return {}


# ---------------------------------------------------------------- input

func _unhandled_input(e: InputEvent) -> void:
	if api == null:
		return
	if e is InputEventMouseButton or e is InputEventMouseMotion:
		if e is InputEventMouseButton and hud.over_ui((e as InputEventMouseButton).position) and (e as InputEventMouseButton).pressed:
			return
		var dragged: bool = cam.handle_input(e)
		if e is InputEventMouseMotion:
			_on_hover((e as InputEventMouseMotion).position)
		elif e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and not dragged:
				_on_click()
		return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		_on_key((e as InputEventKey).keycode)


func _on_key(k: int) -> void:
	if k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and (busy or api.phase == "enemy") and not ended:
		# B2: Enter or Space hurries the rest of the enemy's turn (presentation only)
		skip = true
		speed = minf(speed, float(PACE["skip"]))
		return
	match k:
		KEY_ESCAPE:
			if hud.menu != null:
				hud.hide_menu()
				return
			if mode == "" and armed < 0 and sel == "" and inspect == "":
				_open_menu()
				return
			if mode != "":
				mode = ""
			elif armed >= 0:
				armed = -1
			else:
				sel = ""
				inspect = ""
				reach_map.clear()
			sfx.play("ui_cancel")
			_refresh_ui()
		KEY_TAB:
			_next_ship()
		KEY_ENTER, KEY_KP_ENTER:
			_end_activation()
		KEY_T:
			cam.toggle_top()
		KEY_HOME:
			cam.reset_view()
		KEY_F:
			if sel != "":
				cam.focus(_pos(sel))
		KEY_R:
			threat_on = not threat_on
			_refresh_ui()
		KEY_V:
			arcs_on = not arcs_on
			_refresh_ui()
		KEY_Q:
			_rotate(-1)
		KEY_E:
			_rotate(1)
		KEY_B:
			_order("brace")
		KEY_X:
			if sel != "" and _can_act():
				_cmd(func(): return api.ram(sel))
		KEY_G:
			if sel != "" and _can_act():
				mode = "" if mode == "board" else "board"
				_refresh_ui()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			_arm(k - KEY_1)


func _arm(i: int) -> void:
	var u := _sel_unit()
	if u.is_empty() or i >= (u["weapons"] as Array).size():
		return
	armed = -1 if armed == i else i
	sfx.play("ui_click")
	_refresh_ui()


func _rotate(d: int) -> void:
	var u := _sel_unit()
	if not _can_act() or u.is_empty():
		return
	var hk: String = board.key(hover.x, hover.y)
	if reach_alt.has(hk) and hk != board.key(u["q"], u["r"]):
		# turning the preview on a hovered hex: pick the next facing that hex can be reached in
		hover_pick[hk] = int(hover_pick.get(hk, _alt_index(hk))) + (1 if d > 0 else -1 + reach_alt[hk].size())
		_overlay()
		return
	# turning in place: the rules' own rotate (G1) when present
	if api.has_method("rotate"):
		var rid := sel
		if not _cmd(func(): return api.rotate(rid, d)):
			hud.toast("No turn left this activation.")
		return
	var want := posmod(int(u["facing"]) + d, 6)
	var best = null
	for st in reach_states:
		if int(st.q) == int(u["q"]) and int(st.r) == int(u["r"]) and int(st.f) == want:
			if best == null or float(st.cost) < float(best.cost):
				best = st
	if best != null:
		var id := sel
		_cmd(func(): return api.move(id, best))
	else:
		hud.toast("No turn left this activation.")


func _alt_index(hk: String) -> int:
	var st = reach_map[hk]
	var alts: Array = reach_alt[hk]
	return maxi(0, alts.find(st))


func _order(o: String) -> void:
	if sel == "" or not _can_act():
		return
	var id := sel
	if not bool(_ui(id).get("orders", {}).get(o, false)):
		hud.toast("Can't brace after firing.")
		return
	_cmd(func(): return api.order(id, o))


func _next_ship() -> void:
	var mine: Array = []
	for u in V["units"]:
		if _usable(u) and not u["squadron"]:
			mine.append(u["id"])
	if mine.is_empty():
		return
	var i := mine.find(sel)
	select(mine[(i + 1) % mine.size()])
	cam.focus(_pos(sel))


func _end_activation() -> void:
	if not _can_act():
		return
	var active := ""
	for u in V["units"]:
		if u["active"]:
			active = u["id"]
	var id := sel
	if _classic():
		_cmd(func(): api.end_turn(); return true)
	elif active == "" and sel != "" and _usable(_sel_unit()):
		_cmd(func(): api.end_activation(id); return true)
	else:
		_cmd(func(): api.end_activation(); return true)
	sfx.play("ui_confirm")
	sel = ""
	armed = -1


func _classic() -> bool:
	return api != null and api.get("_alt") == false


func _ray_hex(p: Vector2) -> Vector2i:
	var o: Vector3 = cam.project_ray_origin(p)
	var d: Vector3 = cam.project_ray_normal(p)
	if absf(d.y) < 1e-4:
		return Vector2i(99999, 99999)
	var t := -o.y / d.y
	if t < 0:
		return Vector2i(99999, 99999)
	var h: Vector2i = board.world_hex(o + d * t)
	return h if board.on_board(h.x, h.y) else Vector2i(99999, 99999)


func _on_hover(p: Vector2) -> void:
	var h := _ray_hex(p)
	if h != hover:
		hover = h
		board.set_hover(h.x, h.y)
		_overlay()
	hud.show_tip(_tip(), p)


func _on_click() -> void:
	if not _can_act() or hover.x == 99999 or not _api_join():
		return
	var u := _unit_at(hover.x, hover.y)
	var s := _sel_unit()
	if mode in ["nova", "blink", "launch"] and not s.is_empty():
		var m := mode
		mode = ""
		var ok := false
		for h in _ability_hexes():
			if int(h["q"]) == hover.x and int(h["r"]) == hover.y:
				ok = true
		if ok:
			var id := sel
			var hx := {"q": hover.x, "r": hover.y}
			_cmd(func(): return api.ability(id, {"hex": hx}))
		else:
			_refresh_ui()
		return
	if mode == "board" and not s.is_empty():
		mode = ""
		if not u.is_empty() and u["side"] == "enemy":
			var id := sel
			var tid: String = u["id"]
			_cmd(func(): return api.board(id, tid))
		_refresh_ui()
		return
	if wing_sel != "":
		var w := wing_sel
		wing_sel = ""
		if not u.is_empty() and u["id"] != w and not (u["side"] == "player" and u.get("squadron", false)):
			var tid: String = u["id"]
			if api.wing_order(w, tid):
				hud.toast(("%s will strike %s until it is destroyed." if u["side"] == "enemy" else "%s will guard %s, hitting anything that comes near it.") % [_name(w), _name(tid)])
		_refresh_ui()
		return
	if not u.is_empty() and u["side"] == "player" and u.get("squadron", false):
		if api.has_method("wing_order"):
			wing_sel = u["id"]
			hud.toast("Wing selected. Click an enemy ship to strike it, or one of your ships to guard it.")
		return
	if not u.is_empty() and u["side"] == "player":
		select(u["id"])
		return
	if not u.is_empty() and u["side"] == "enemy":
		if _usable(s):
			var set := _firing_set(u["id"])
			if not set.is_empty():
				var id := sel
				var tid: String = u["id"]
				_cmd(func():
					var any := false
					for i in set:
						if api.fire(id, i, tid):
							any = true
						var tu = api.unit(tid)
						if tu == null or _jt(tu.get("dead")) or api.phase != "player":
							break
					return any)
				armed = -1
				return
			var am = _attack_move(u["id"])
			if am != null:
				var id := sel
				var tid: String = u["id"]
				var wsel = [armed] if armed >= 0 else null
				_cmd(func(): return api.attack_move(id, tid, wsel))
				armed = -1
				return
			hud.toast(_cant_fire_reason(u["id"]))
			return
		inspect = u["id"]
		sel = ""
		reach_map.clear()
		_refresh_ui()
		return
	var hk: String = board.key(hover.x, hover.y)
	if not s.is_empty() and reach_map.has(hk):
		var st = _hover_state(hk)
		var id := sel
		_cmd(func(): return api.move(id, st))
		return
	if inspect != "":
		inspect = ""
		_refresh_ui()


func _cant_fire_reason(t_id: String) -> String:
	var u: Dictionary = VU.get(sel, {})
	if u.is_empty():
		return ""
	if u["braced"]:
		return "This ship is braced and can't fire."
	var any_ready := false
	var in_range := false
	var in_arc := false
	for w in u["weapons"]:
		if w["kind"] == "flak" or not w["ready"]:
			continue
		any_ready = true
		var t := _wtarget(sel, int(w["i"]), t_id)
		if t.get("inRange", false):
			in_range = true
			if t.get("inArc", false):
				in_arc = true
	if not any_ready:
		return "Every gun has already fired or is reloading."
	if not in_range:
		return "Out of range."
	if not in_arc:
		return "No ready gun points at it. Turn the ship (Q/E) or move."
	return "Line of sight is blocked."


func _tip() -> String:
	if hover.x == 99999 or busy or not _api_join() or api.phase != "player":
		return ""
	var u := _unit_at(hover.x, hover.y)
	var s := _sel_unit()
	if not u.is_empty() and u["side"] == "enemy" and _usable(s):
		return _attack_tip(u["id"])
	if not u.is_empty():
		return _ship_tip(u)
	var hk: String = board.key(hover.x, hover.y)
	if reach_map.has(hk):
		var st = _hover_state(hk)
		var t := "[b][color=#d0a64b]Move here[/color][/b]\n%d movement%s." % [int(st.cost), (", %d turn%s" % [int(st.get("t", 0)), "" if int(st.get("t", 0)) == 1 else "s"]) if int(st.get("t", 0)) > 0 else ""]
		if int(st.get("gunsOf", 0)) > 0:
			t += "\n%d of %d guns bear on an enemy from here." % [int(st.get("guns", 0)), int(st.get("gunsOf", 0))]
		t += "\n[color=#7d7768]Q/E change the facing. Click to move.[/color]"
		return t
	if board.zone_of.has(hk):
		var zi := {"exit": ["Exit", "A ship that ends its move here jumps clear of the battle."], "texit": ["Transport exit", "An enemy transport that reaches this edge gets through."],
			"guard": ["Station perimeter", "Every enemy ship this close to the station at the start of a round knocks out 1 integrity."]}.get(board.zone_of[hk], ["", ""])
		return "[b]%s[/b]\n%s" % [zi[0], zi[1]]
	var terr := str(V["terrain"].get(hk, ""))
	if terr != "":
		var info = TBL.get("TERRAIN_INFO", {}).get(terr, {})
		if info is Dictionary and not info.is_empty():
			return "[b]%s[/b]\n%s" % [str(info.get("n", terr)), str(info.get("fx", info.get("d", "")))]
		return "[b]%s[/b]" % terr.capitalize()
	return ""


# the terrain legend (ui3d.js refreshLegend): the encounter, the zones and the terrain kinds on this board; blockers share
# one row ("Asteroids, Station: Blocks movement and line of fire.")
func _legend() -> void:
	var TI: Dictionary = TBL.get("TERRAIN_INFO", {})
	var BL: Dictionary = TBL.get("BLOCKING", {})
	var present := {}
	for k in V["terrain"].values():
		present[str(k)] = true
	var rows: Array = []
	for z in ["exit", "texit", "guard"]:
		if z in board.zone_of.values():
			var zi: Array = {"exit": ["Exit", "#7dff9b", "A ship that ends its move here jumps clear of the battle."],
				"texit": ["Transport exit", "#e07a70", "An enemy transport that reaches this edge gets through."],
				"guard": ["Station perimeter", "#e07a70", "Every enemy ship this close to the station at the start of a round knocks out 1 integrity."]}[z]
			rows.append(zi)
	var blockers: Array = []
	var block_col := ""
	for k in TI.keys():
		if not present.has(k):
			continue
		var info: Dictionary = TI[k]
		if BL.has(k):
			blockers.append(str(info.get("n", k)))
			if block_col == "":
				block_col = str(info.get("col", "#bda088"))
			continue
		rows.append([str(info.get("n", k)), str(info.get("col", "#888888")), str(info.get("fx", ""))])
	if not blockers.is_empty():
		rows.insert(rows.size(), [", ".join(blockers), block_col, "Blocks movement and line of fire."])
	var o = V.get("obj")
	var E = TBL.get("ENCOUNTERS", {}).get(str(o.get("type")) if o is Dictionary else "rout", null)
	var title := str(E.get("n", "")) if E is Dictionary else ""
	var desc := str(E.get("d", "")) if E is Dictionary else ""
	var shape = api.world_info().get("shape")
	if shape != null and str(shape) != "open" and TBL.get("SHAPES", {}).has(str(shape)):
		desc += " Board: %s." % str(TBL["SHAPES"][str(shape)]).to_lower()
	hud.set_legend(title, desc.strip_edges(), rows)


func _ship_tip(u: Dictionary) -> String:
	var col := "#8ff0a0" if u["side"] == "player" else "#c9a3ff"
	var d: Dictionary = disp.get(u["id"], {"hp": u["hp"], "sh": u["sh"]})
	var t := "[b][color=%s]%s%s[/color][/b]\n[color=#b3aa95]%s[/color]\nHull [color=#ffae42]%d/%d[/color]" % [col, "★ " if u["flagship"] else "", str(u["name"]), str(u["cls"]), int(d["hp"]), int(u["maxHp"])]
	if float(u["shMax"]) > 0:
		var parts: Array = []
		for i in 4:
			parts.append(str(int(d["sh"][i])))
		t += "   Shields [color=#62ccff]%s[/color] / %d" % [" ".join(parts), int(u["shMax"])]
	if u["side"] == "player" and u["activated"]:
		t += "\n[color=#7d7768]Already acted this round.[/color]"
	return t


func _attack_tip(t_id: String) -> String:
	var ru = api.unit(sel)
	var tu = api.unit(t_id)
	var su: Dictionary = VU[sel]
	var tv: Dictionary = VU[t_id]
	var quad := 0
	var rear := false
	var rows := ""
	var hull := 0.0
	var sh := 0.0
	var n := 0
	var idx: Array = [armed] if armed >= 0 else range(su["weapons"].size())
	for i in idx:
		var vw: Dictionary = su["weapons"][i]
		var w = ru["weapons"][i]
		var tg := _wtarget(sel, i, t_id)
		quad = int(tg.get("quad", quad))
		rear = bool(tg.get("rear", rear))
		var right := ""
		if float(_z0(vw.get("off"))) > 0:
			right = "[color=#e27f74]offline[/color]"
		elif float(_z0(vw.get("cd"))) > 0:
			right = "[color=#7d7768]reloading[/color]"
		elif not vw["ready"]:
			right = "[color=#7d7768]fired[/color]"
		elif su["braced"]:
			right = "[color=#7d7768]braced[/color]"
		elif not tg.get("inRange", false):
			right = "[color=#7d7768]out of range (%d/%d)[/color]" % [int(tg.get("range", 0)), int(vw["range"])]
		elif not tg.get("inArc", false):
			right = "[color=#7d7768]out of arc[/color]"
		elif not tg.get("los", false):
			right = "[color=#7d7768]blocked[/color]"
		else:
			hull += float(tg.get("hull", 0))
			sh += float(tg.get("shield", 0))
			n += 1
			right = "[b][color=#f0b35a]%d%%[/color][/b] [color=#7d7768]%d\u00d7%d[/color]" % [int(tg.get("hit", 0)), int(w["shots"]), int(round(float(tg.get("dmgMult", 0))))]
		rows += "%s  %s\n" % [str(vw["name"]), right]
	var t := "[b][color=#e27f74]%s[/color][/b]\n[color=#b3aa95]Hull %d/%d, armor %d%%, evasion %d[/color]\n" % [str(tv["name"]), int(tv["hp"]), int(tv["maxHp"]), int(round(float(tu.get("armor", 0)) * 100.0)), int(_z0(tu.get("ev"))) + int(_z0(tu.get("evBuff")))]
	if float(tv["shMax"]) > 0:
		t += "Hits the [color=#62ccff][b]%s shield[/b] (%d/%d)[/color]%s." % [QUAD_NAME[quad], int(tv["sh"][quad]), int(tv["shMax"]), " [color=#ffae42]down, straight to hull[/color]" if float(tv["sh"][quad]) < 1 else ""]
	else:
		t += "Target is unshielded: [color=#ffae42]every hit lands on the hull[/color]."
	if rear:
		t += " [color=#f0b35a]Rear arc: armor halved, +15% crit.[/color]"
	t += "\n" + rows
	if n > 0:
		t += "Expected: about [color=#62ccff]%d shield[/color] and [color=#ffae42]%d hull[/color] damage.%s\n[color=#d0a64b]Click to fire %d weapon%s.[/color]" % [int(round(sh)), int(round(hull)), " [color=#f0b35a]Likely kill.[/color]" if hull >= float(tv["hp"]) else "", n, "s" if n > 1 else ""]
	else:
		var am = _attack_move(t_id)
		if am != null:
			t += "[color=#d0a64b]Click to burn %d movement into position and fire %d weapon%s on the way.[/color]" % [int(am["st"].cost), int(am["n"]), "s" if int(am["n"]) > 1 else ""]
		else:
			t += "[color=#7d7768]No ready weapon can reach this target.[/color]"
	return t


func _on_action(name: String, arg) -> void:
	sfx.play("ui_click")
	match name:
		"end":
			_end_activation()
		"pick":
			if _can_act() or true:
				var u: Dictionary = VU.get(arg, {})
				if not u.is_empty():
					select(arg)
					cam.focus(_pos(arg))
		"arm":
			_arm(int(arg))
		"brace":
			_order("brace")
		"ability":
			if sel != "" and _can_act():
				var id := sel
				var ab := str(_sel_unit().get("ab", ""))
				if ab in ["nova", "blink", "launch"]:
					mode = "" if mode == ab else ab
					hud.toast({"nova": "Click a hex 3 to 9 ahead for the nova shell.", "blink": "Click an open hex within 3 to jump to.", "launch": "Click an open hex next to the carrier."}[ab])
					_refresh_ui()
				else:
					_cmd(func(): return api.ability(id))
		"ram":
			if sel != "" and _can_act():
				var id := sel
				_cmd(func(): return api.ram(id))
		"board":
			mode = "" if mode == "board" else "board"
			_refresh_ui()
		"rotl":
			_rotate(-1)
		"rotr":
			_rotate(1)
		"threat":
			threat_on = not threat_on
			_refresh_ui()
		"top":
			cam.toggle_top()
		"speed":
			user_speed = 0.45 if user_speed >= 1.0 else 1.0
			_save_opts()
			_refresh_ui()
		"tip_ok":
			tips[str(arg)] = true
			hud.hide_tipcard()
			_save_opts()
			_tutorial()
		"tip_off":
			tips_off = true
			hud.hide_tipcard()
			_save_opts()
		"command":
			# the game asks for a second tap to confirm the once-per-battle Command
			var now := Time.get_ticks_msec() / 1000.0
			if now - cmd_armed_t > 3.0:
				cmd_armed_t = now
				hud.toast("Click Command again to give the order: %s" % _command_label())
			else:
				cmd_armed_t = -9.0
				_cmd(func(): return api.command())
		"stance":
			var sid := sel
			var stn := str(arg)
			_cmd(func(): return api.stance(sid, stn))
		"menu":
			_open_menu()
		"menu_close":
			hud.hide_menu()
		"report":
			# the browser's Report a problem: the battle's facts, the errors and the log, ready to paste
			var lines: Array = Array(hud.log_text.get_parsed_text().split("\n"))
			var rep := {"version": ProjectSettings.get_setting("application/config/version", "dev"), "round": V.get("round"), "phase": api.phase if api != null else "",
				"seed": api.world_info().get("seed") if api != null and api.has_method("world_info") else null, "errors": errors, "log": lines.slice(maxi(0, lines.size() - 60))}
			DisplayServer.clipboard_set(JSON.stringify(rep, "  "))
			hud.toast("Problem report copied. Paste it into a message to Ryan's helpers.")
		"opt":
			_toggle_opt(str(arg))
		"to_title":
			hud.hide_menu()
			ended = true
			result = {"result": "quit", "rounds": int(V.get("round", 0)), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
			finished.emit(result)
		"continue":
			hud.hide_end()
			finished.emit(result)
		"retreat":
			if can_retreat and _can_act():
				ended = true
				result = {"result": "retreat", "rounds": int(V["round"]), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
				finished.emit(result)
		"restart":
			hud.hide_end()
			hud.hide_menu()
			args.erase("seed")
			start_default()
		"quit":
			_quit()


# ---------------------------------------------------------------- in-battle menu (the browser's settings menu in the top bar)

signal option_changed(key: String, value: Variant)


func _open_menu() -> void:
	var items: Array = [["Resume", "menu_close"]]
	items.append(["Sound: %s" % ("on" if sfx.on else "off"), "opt", "sound"])
	items.append(["Speed: %s" % ("fast" if user_speed < 1.0 else "normal"), "opt", "speed"])
	items.append(["Movement: %s" % movement, "opt", "movement"])
	items.append(["Follow enemy activations: %s" % ("on" if follow else "off"), "opt", "follow"])
	items.append(["Cut-ins: %s" % {"key": "key moments", "all": "every attack", "off": "off"}.get(cine, cine), "opt", "cine"])
	items.append(["Battle tips: %s" % ("off" if tips_off else "on"), "opt", "tips"])
	items.append(["Reduce flashing: %s" % ("on" if reduce_flashing else "off"), "opt", "flash"])
	items.append(["Screen shake: %s" % ("full" if shake_scale >= 1.0 else ("reduced" if shake_scale > 0.0 else "off")), "opt", "shake"])
	items.append(["Threat map: %s" % ("on" if threat_on else "off"), "opt", "threat"])
	items.append(["Firing arcs: %s" % ("on" if arcs_on else "off"), "opt", "arcs"])
	if external and not in_campaign:
		items.append(["Quit to title", "to_title"])
	elif not external:
		items.append(["Fight again", "restart"])
	items.append(["Copy a problem report", "report"])
	items.append(["Quit the game", "quit"])
	hud.show_menu("Menu", items)


func _toggle_opt(k: String) -> void:
	match k:
		"sound":
			sfx.set_on(not sfx.on)
			option_changed.emit("sound", sfx.on)
		"speed":
			user_speed = 0.45 if user_speed >= 1.0 else 1.0
			option_changed.emit("speed", user_speed)
		"movement":
			movement = "brisk" if movement == "cinematic" else "cinematic"
			option_changed.emit("movement", movement)
		"follow":
			follow = not follow
			option_changed.emit("follow", follow)
		"cine":
			cine = {"key": "all", "all": "off", "off": "key"}.get(cine, "key")
			option_changed.emit("cine", cine)
		"tips":
			tips_off = not tips_off
			option_changed.emit("tips", not tips_off)
		"flash":
			set_fx_opts(not reduce_flashing, shake_scale)
			option_changed.emit("reduce_flashing", reduce_flashing)
		"shake":
			set_fx_opts(reduce_flashing, 0.5 if shake_scale >= 1.0 else (0.0 if shake_scale > 0.0 else 1.0))
			option_changed.emit("shake", shake_scale)
		"threat":
			threat_on = not threat_on
		"arcs":
			arcs_on = not arcs_on
	_save_opts()
	_refresh_ui()
	_open_menu()


# ---------------------------------------------------------------- HUD refresh

func _refresh_ui() -> void:
	if api == null or V.is_empty():
		return
	if sel != "" and (not VU.has(sel) or VU[sel]["dead"]):
		sel = ""
	if sel != "" and reach_map.is_empty() and _can_act() and _usable(_sel_unit()):
		_update_reach()
	if not _can_act():
		reach_map.clear()
	var pend := _player_pending()
	var active := ""
	for u in V["units"]:
		if u["active"]:
			active = u["id"]
	var mine: bool = api.phase == "player" and not ended
	var turn := "Battle over" if ended or api.phase == "over" else ("Your activation (%d ready)" % pend if mine else "Enemy activation")
	var end_text := "End activation" if active != "" else ("Pass" if pend > 0 else "Continue")
	if _classic():
		end_text = "End turn"
		turn = "Battle over" if ended or api.phase == "over" else ("Your turn" if mine else "Enemy turn")
	hud.set_command(_command_label(), api.has_method("can_command") and mine and not busy and api.can_command())
	hud.set_top(int(V["round"]), turn, _objective(), end_text, mine and not busy, user_speed < 1.0, threat_on)
	hud.retreat_btn.visible = can_retreat and not ended
	hud.retreat_btn.disabled = not (mine and not busy)
	var rows: Array = []
	for u in V["units"]:
		if u["side"] != "player" or u["squadron"] or (u["dead"] and not views.has(u["id"])):
			continue
		var d: Dictionary = disp.get(u["id"], {"hp": u["hp"], "sh": u["sh"]})
		var status := "Lost" if u["dead"] else ("Active" if u["active"] else ("Done" if u["activated"] else "Ready"))
		rows.append({"id": u["id"], "name": u["name"], "cls": u["cls"], "hp": d["hp"], "maxHp": u["maxHp"], "sh": d["sh"], "shMax": u["shMax"], "status": status, "sel": u["id"] == sel, "done": u["activated"] or u["dead"], "flag": u["flagship"]})
	hud.set_roster(rows)
	hud.set_panel(_panel_info())
	for id in views:
		var sv = views[id]
		sv.set_selected(id == sel, Color(0.82, 0.65, 0.29))
	_overlay()
	_tutorial()


func _command_label() -> String:
	if api == null or _api_admiral() == "":
		return "Command"
	var A = TBL.get("ADMIRALS", {}).get(_api_admiral(), {})
	var c = A.get("cmd") if A is Dictionary else null
	return str(c.get("n", "Command")) if c is Dictionary else "Command"


func _objective() -> String:
	var o = V.get("obj")
	if o == null or o.get("type") in ["rout", "ambush"]:
		return "Objective: break their fleet"
	match str(o["type"]):
		"flagship":
			for u in V["units"]:
				if u["flagship"] and u["side"] == "enemy":
					return "Objective: destroy the flagship %s" % u["name"]
		"hunt":
			return "Objective: catch the flagship before it jumps (round %d/%d)" % [mini(int(V["round"]), int(o.get("rounds", 0))), int(o.get("rounds", 0))]
		"defend":
			return "Objective: hold the station (round %d/%d), integrity %d/%d" % [mini(int(V["round"]), int(o.get("rounds", 0))), int(o.get("rounds", 0)), int(o.get("hp", 0)), int(o.get("hpMax", 0))]
		"intercept":
			return "Objective: destroy %d of %d transports (%d/%d)" % [int(o.get("need", 0)), int(o.get("total", 0)), int(o.get("kill", 0)), int(o.get("need", 0))]
		"break":
			return "Objective: get %d ships off the far edge (%d/%d)" % [int(o.get("need", 0)), int(o.get("out", 0)), int(o.get("need", 0))]
		"hold":
			return "Objective: hold the relay %d/3 (them %d/3)" % [int(o.get("score", 0)), int(o.get("escore", 0))]
	return "Objective: break their fleet"


func _panel_info() -> Dictionary:
	var id := sel if sel != "" else inspect
	if id == "" or not VU.has(id):
		return {}
	var u: Dictionary = VU[id]
	if not _api_join():
		return {}
	var ru = api.unit(id)
	var d: Dictionary = disp.get(id, {"hp": u["hp"], "sh": u["sh"]})
	var info := {"name": u["name"], "cls": u["cls"], "side": u["side"], "flag": u["flagship"], "hp": d["hp"], "maxHp": u["maxHp"], "sh": d["sh"], "shMax": u["shMax"]}
	var mleft := int(u.get("moveLeft", u["mp"])) if u.get("moveLeft") != null else int(u["mp"])
	var stats := "Hull [color=#ffae42]%d/%d[/color]   Armor %d%%   Evasion %d\nMovement %d of %d   Turns %d" % [int(d["hp"]), int(u["maxHp"]), int(round(float(ru.get("armor", 0)) * 100.0)), int(_z0(ru.get("ev"))), mleft, int(_z0(ru.get("speed"))), int(u["turnsLeft"])]
	if u.get("fired", false) and mleft < int(u["mp"]):
		stats += "\n[color=#7d7768]Fired: ships move, then fire.%s[/color]" % (" Half the movement left to slip away." if mleft > 0 else "")
	if u.get("crew") != null:
		stats += "   Crew %d/%d" % [int(u["crew"]), int(u["crewMax"])]
	if u["braced"]:
		stats += "\n[color=#9fd4ff]Braced: hull damage −40% until its next turn.[/color]"
	if u["burning"]:
		stats += "\n[color=#f08a4b]On fire.[/color]"
	info["stats"] = stats
	var ws: Array = []
	var tgt := ""
	var hu := _unit_at(hover.x, hover.y)
	if not hu.is_empty() and hu["side"] != u["side"]:
		tgt = hu["id"]
	for w in u["weapons"]:
		var rw = ru["weapons"][int(w["i"])]
		var right := ""
		if float(_z0(w["off"])) > 0:
			right = "offline"
		elif float(_z0(w["cd"])) > 0:
			right = "reloading %d" % int(w["cd"])
		elif not w["ready"]:
			right = "fired"
		elif tgt != "" and u["side"] == "player" and api.can_fire(id, int(w["i"]), tgt):
			right = "%d%%" % int(api.preview_fire(id, int(w["i"]), tgt)["hit"])
		else:
			right = "ready"
		var arc_name = TBL.get("ARC_NAME", {}).get(str(w["arc"]), str(w["arc"]))
		ws.append({"i": w["i"], "name": str(w["name"]), "desc": _weapon_desc(ru, rw, str(arc_name)), "right": right, "ready": w["ready"], "armed": int(w["i"]) == armed and id == sel})
	info["weapons"] = ws
	_panel_sheet(u, ru, info)
	if u["side"] == "player" and not u["dead"]:
		var can := _can_act() and _usable(u)
		var orders: Array = []
		var ui := _ui(id)
		orders.append({"text": "Brace (B)", "act": "brace", "on": can and bool(ui.get("orders", {}).get("brace", false)), "tip": str(TBL.get("ORDERS", {}).get("brace", {}).get("d", ""))})
		if u.get("ab") != null:
			var A = TBL.get("ABILITIES", {}).get(str(u["ab"]), {})
			orders.append({"text": str(A.get("n", u["ab"])) + ("" if u["abReady"] else " (%d)" % int(u["abCd"])), "act": "ability", "on": can and u["abReady"], "tip": str(A.get("d", ""))})
		orders.append({"text": "Ram (X)", "act": "ram", "on": can and ui.get("ram") != null, "tip": "Charge the first enemy dead ahead (needs a run-up)."})
		orders.append({"text": "Board (G)", "act": "board", "on": can and not (ui.get("board", []) as Array).is_empty(), "tip": "Send boarding crews into an adjacent enemy."})
		if str(u.get("ab", "")) == "launch" and str(u.get("stance", "")) != "":
			for stn in ["strike", "screen", "hunt"]:
				orders.append({"text": "Wings: %s%s" % [stn, " (now)" if str(u.get("stance")) == stn else ""], "act": "stance", "arg": stn, "on": bool(u.get("canStance")) and str(u.get("stance")) != stn and _can_act(),
					"tip": {"strike": "Wings range out and strike.", "screen": "Wings stay within 2 hexes, hunt craft first and shoot down torpedoes aimed at ships beside them.", "hunt": "Wings range 4 hexes further, +20% against crippled ships, easier to hit."}[stn]})
		orders.append({"text": "Turn left (Q)", "act": "rotl", "on": can})
		orders.append({"text": "Turn right (E)", "act": "rotr", "on": can})
		info["orders"] = orders
	return info


# ---------------------------------------------------------------- the full ship sheet (ui3d.js refreshPanel)
const SEC_LBL := {"prow": "Prow", "mid": "Midships", "eng": "Engines"}
static var _boon_d = null   # campaign_tables.json BOON_D: boon id -> description per rarity


# a number as the browser prints it (2, not 2.0)
static func _n(x) -> String:
	if (x is float) and is_equal_approx(x, roundf(x)):
		return str(int(x))
	return str(x)


func _weapon_desc(ru, rw, arc_name: String) -> String:
	var mul := float(ru.get("dmg", 1.0)) if _jt(ru.get("dmg")) else 1.0
	var t := "%s, %d×%d damage, range %d" % ["Turret" if str(rw.get("arc")) == "T" else arc_name, int(rw["shots"]), int(round(float(rw["dmg"]) * mul)), int(rw["r"])]
	if _jt(rw.get("pierce")):
		t += ", %d%% through shields" % int(round(float(rw["pierce"]) * 100.0))
	if _jt(rw.get("ion")):
		t += ", shreds shields"
	if float(_z0(rw.get("vsSq"))) > 1.0:
		t += ", anti-squadron"
	if _jt(rw.get("cd")):
		t += ", reload %d" % int(rw["cd"])
	if float(_z0(rw.get("evMult"))) > 1.0:
		t += " (slow)"
	var wt = TBL.get("WTRAITS", {}).get(str(rw.get("trait", "")))
	if _jt(rw.get("trait")) and wt is Dictionary:
		t += "\n" + str(wt.get("d", "")).capitalize().left(1) + str(wt.get("d", "")).substr(1) + "."
	return t


func _panel_sheet(u: Dictionary, ru, info: Dictionary) -> void:
	var R = api.R
	var Bs = R.B
	var T: Dictionary = ru.get("t", {}) if ru.get("t") is Dictionary else {}
	# class line: the template name, elite captain; then the captain and perks
	if not _jt(ru.get("isSq")):
		info["cls"] = str(T.get("n", u["cls"])) + (", elite captain" if _jt(ru.get("elite")) else "")
	var cap = ru.get("ship", {}).get("cap") if ru.get("ship") is Dictionary else null
	if cap is Dictionary:
		var ranks: Array = TBL.get("CAPTAINS", {}).get(str(cap.get("fac", "voidsworn")), TBL.get("CAPTAINS", {}).get("voidsworn", {})).get("ranks", [])
		var rk := str(ranks[clampi(int(_z0(cap.get("rank"))), 0, ranks.size() - 1)]) if not ranks.is_empty() else ""
		var line := "%s %s" % [rk, str(cap.get("name", ""))]
		for pk in cap.get("perks", []):
			var P = TBL.get("PERKS", {}).get(str(pk))
			if P is Dictionary:
				line += "  [color=#d0a64b]%s[/color] [color=#7d7768](%s)[/color]" % [str(P.get("n", pk)), str(P.get("d", "")).trim_suffix(".")]
		info["captain"] = line.strip_edges()
	# hull by section
	if ru.get("sec") is Dictionary:
		var secs: Array = []
		for k in ["prow", "mid", "eng"]:
			var sc = ru["sec"].get(k)
			if sc is Dictionary:
				secs.append([SEC_LBL[k] + (" (out)" if float(sc.get("hp", 0)) <= 0.0 else ""), float(sc.get("hp", 0)), float(sc.get("max", 1))])
		info["secs"] = secs
	# shields in words
	if float(u["shMax"]) > 0.0:
		var sh: Array = disp.get(u["id"], {"sh": u["sh"]})["sh"]
		info["stats"] = str(info.get("stats", "")) + "\n[color=#62ccff]Shields[/color] of %d each, +%d a turn: prow %d, port %d, starboard %d, rear %d" % [int(u["shMax"]), int(_z0(ru.get("regen"))), int(sh[0]), int(sh[3]), int(sh[1]), int(sh[2])]
	# state and faction lines (refreshPanel tr[] and battle.js factionTraitLines)
	var tr: Array = []
	if _jt(ru.get("hullRegen")):
		tr.append("Repairs %d hull each turn." % int(ru["hullRegen"]))
	var st: Dictionary = ru.get("st", {}) if ru.get("st") is Dictionary else {}
	if _jt(st.get("engine")):
		tr.append("Engines damaged (−%d speed)." % int(st["engine"]))
	if _jt(st.get("shieldOff")):
		tr.append("Shield generator offline.")
	if _jt(ru.get("evBuff")):
		tr.append("Evasive: +%d evasion." % int(ru["evBuff"]))
	if _jt(ru.get("lockOn")):
		tr.append("Locked on: +15 aim, +10% crit.")
	if _jt(ru.get("focus")):
		tr.append("Concentrated fire: +30% damage.")
	if Bs.get("aiFocus") is Dictionary and Bs["aiFocus"].get("id") == ru.get("id") and not u["dead"]:
		tr.append("[color=#e27f74]The enemy fleet is focusing its fire on this ship.[/color]")
	if not _jt(ru.get("isSq")):
		var fac := str(ru.get("fac", ""))
		if fac == "hegemony":
			var anc = R.syncAnchor(ru["side"])
			var sr := int(TBL.get("SYNC_R", 3))
			tr.append("Synchronized fire lost: the flagship is gone." if not _jt(anc) else ("Sync anchor: Hegemony ships within %d hexes fire as one." % sr if _jt(ru.get("anchor")) else ("In sync with the flagship." if R.inSync(ru) else "Out of sync: more than %d hexes from the flagship." % sr)))
		if fac == "ithar" and float(u["shMax"]) > 0.0:
			tr.append("Prism charge: facings not hit since its last turn refill to full; hit facings recharge twice.")
		if fac == "chorus":
			tr.append("Feeds on kills nearby (up to %d%% hull a round)." % int(round(float(TBL.get("FEED_CAP", 0.0)) * 100.0)))
		if fac == "deathless" and _jt(T.get("reanimate")):
			var L = Bs.get("legion", {}).get(ru["side"]) if Bs.get("legion") is Dictionary else null
			tr.append("Reassembled this battle." if _jt(ru.get("risen")) else ("Archive restore: the first to fall reassembles next round." if L is Dictionary and float(L.get("used", 0)) < float(L.get("max", 0)) and not _jt(ru.get("pflag")) and not _jt(ru.get("flagship")) and not _jt(ru.get("boss")) else "Archive restore spent."))
		for ts in (Bs["torps"] if Bs.get("torps") is Array else []):
			if ts.get("tid") == ru.get("id") and ts.get("side") != ru.get("side"):
				tr.append("[color=#e27f74]Torpedoes inbound: they strike its marked hex next turn. Move 3 or more hexes from it to dodge.[/color]")
		if ru.get("ab") == "launch" or (ru.get("fx") is Dictionary and _jt(ru["fx"].get("hive"))):
			var WS = TBL.get("WING_STANCES", {}).get(str(ru.get("stance", "strike")) if _jt(ru.get("stance")) else "strike", {})
			tr.append("Wing stance: %s. %s%s" % [str(WS.get("n", "")), str(WS.get("d", "")), ((" One free change this round." if R.canStance(ru) else " Changed this round.") if ru["side"] == "player" else "")])
			var pks: Array = R.wingPerks(ru)
			if not pks.is_empty():
				var parts: Array = []
				for k in pks:
					var WP = TBL.get("WING_PERKS", {}).get(str(k), {})
					parts.append("%s (%s)" % [str(WP.get("n", k)), str(WP.get("d", "")).trim_suffix(".")])
				tr.append("Wing veterans: " + ", ".join(parts) + ".")
		if _jt(ru.get("nem")) and _jt(Bs.get("nem")) and _jt(ru.get("nemFlag")):
			tr.append("[color=#e27f74]Your Nemesis commands from this ship.[/color]")
			var kn: Array = []
			var weak: Array = Bs["nem"]["weak"] if Bs["nem"].get("weak") is Array else []
			for w in (Bs["nem"]["revealed"] if Bs["nem"].get("revealed") is Array else []):
				if w in weak:
					var NW = TBL.get("NEM_WEAK", {}).get(str(w), {})
					kn.append("%s (%s)" % [str(NW.get("n", w)), str(NW.get("d", "")).trim_suffix(".")])
			if not kn.is_empty():
				tr.append("Known weaknesses: " + "; ".join(kn) + ".")
		# helm: thrusters and the faction drive (ui3d.js driveLine)
		if ru["side"] == "player":
			var MR: Dictionary = R.moveRules(ru)
			var M = TBL.get("MOVE_RULES", {}).get(fac)
			var dl := "Thrusters: sideslip %s, back off %s, pass over or under %s." % [_n(MR.get("slip")), _n(MR.get("rev")), ("+" + _n(MR.get("over"))) if _jt(MR.get("over")) else "free"]
			if M is Dictionary:
				dl += " [color=#d0a64b]%s[/color]: %s" % [str(M.get("n", "")), str(M.get("d", ""))]
			if ru.get("hexMoved") != null:
				if int(ru["hexMoved"]) == 0:
					dl += " [color=#e27f74]Has not moved: enemies get +%s to hit.[/color]" % _n(MR.get("still"))
				elif int(ru["hexMoved"]) >= int(_z0(MR.get("evadeAt"))):
					dl += " [color=#5fb3a6]Evasive: enemies get −%s to hit.[/color]" % _n(MR.get("evade"))
			tr.append("[color=#7d7768]%s[/color]" % dl)
	if not tr.is_empty():
		info["note"] = "[font_size=%d]%s[/font_size]" % [hud.s(13), " ".join(tr)]
	# extra sections
	var extra: Array = []
	if ru["side"] == "enemy" and _jt(T.get("boss")) and TBL.get("BOSS_CMD", {}).has(str(ru.get("fac"))):
		var c = TBL["BOSS_CMD"][str(ru["fac"])]
		var when := "used" if _jt(Bs.get("cmdEUsed")) else ("strikes next round" if Bs.get("cmdENext") != null else "not yet")
		var col := "#e27f74" if Bs.get("cmdENext") != null and not _jt(Bs.get("cmdEUsed")) else "#b3aa95"
		extra.append(["Flagship Command (%s)" % when, "[color=%s][b]%s.[/b] %s[/color]" % [col, str(c.get("n", "")), str(R.bossCmdText(c, ru["fac"]))]])
	var RUN = R.RUN
	if ru["side"] == "player" and not _jt(ru.get("isSq")) and RUN is Dictionary and ((RUN.get("boons", []) as Array).size() > 0 or (_jt(RUN.get("aspect")) and _jt(ru.get("pflag")))):
		if _boon_d == null:
			_boon_d = {}
			if FileAccess.file_exists("res://campaign/data/campaign_tables.json"):
				var J = JSON.parse_string(FileAccess.get_file_as_string("res://campaign/data/campaign_tables.json"))
				if J is Dictionary:
					var tt = J.get("tables", J)
					if tt is Dictionary and tt.get("BOON_D") is Dictionary:
						_boon_d = tt["BOON_D"]
		var bb := ""
		if _jt(ru.get("pflag")) and _jt(RUN.get("aspect")):
			var AS = TBL.get("ASPECTS", {}).get(str(RUN["aspect"]))
			if AS is Dictionary:
				bb += "[b][color=#d0a64b]%s[/color][/b] [color=#b3aa95]%s[/color]\n" % [str(AS.get("n", "")), str(AS.get("d", ""))]
		var stats: Dictionary = Bs.get("boonStats", {}) if Bs.get("boonStats") is Dictionary else {}
		for b in RUN.get("boons", []):
			var B0 = TBL.get("BOONS", {}).get(str(b.get("id")))
			if not B0 is Dictionary:
				continue
			var pat = B0.get("p") if _jt(B0.get("p")) else (B0.get("duo", [""])[0] if B0.get("duo") is Array else "")
			var pcol := str(TBL.get("PATRONS", {}).get(str(pat), {}).get("col", "#d0a64b"))
			var dl: Array = _boon_d.get(str(b.get("id")), [])
			var d := str(dl[clampi(int(_z0(b.get("r"))), 0, dl.size() - 1)]) if not dl.is_empty() else ""
			bb += "[color=%s]▌[/color][b]%s[/b]%s [color=#b3aa95]%s[/color]\n" % [pcol, str(B0.get("n", "")), (" [color=#d0a64b]×%d this battle[/color]" % int(stats[b["id"]])) if _jt(stats.get(b.get("id"))) else "", d]
		if bb != "":
			extra.append(["Fleet protocols", bb.strip_edges()])
	if ru["side"] == "enemy":
		var F = TBL.get("FACTIONS", {}).get(str(ru.get("fac")), {})
		if F is Dictionary and str(F.get("blurb", "")) != "":
			extra.append([str(F.get("n", "")), "[color=#b3aa95]%s[/color]" % str(F["blurb"])])
	info["extra"] = extra


# ---------------------------------------------------------------- per frame: nameplates, floats, bot

var showcase_ready := false


func _process(dt: float) -> void:
	game_t += dt
	if showcase_ready:
		cam.a += dt * 0.035
	if world != null and world.has_method("step"):
		world.step(dt)
	if api == null:
		return
	var vs := get_viewport().get_visible_rect().size
	for id in views:
		var sv = views[id]
		var u: Dictionary = VU.get(id, {})
		if u.is_empty() or sv.dead or not sv.visible or not cine_saved.is_empty():
			hud.set_plate(str(id), Vector2.ZERO, false, "", true, false, 0, 1, 0, 0)
			continue
		var wp: Vector3 = sv.position + Vector3(0, 3.0 + sv.L * 0.18, 0)
		var on := not cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		on = on and sp.x > -50 and sp.y > -50 and sp.x < vs.x + 50 and sp.y < vs.y + 50
		var d: Dictionary = disp.get(id, {"hp": u["hp"], "sh": u["sh"]})
		var shs := 0.0
		for x in d["sh"]:
			shs += float(x)
		hud.set_plate(str(id), sp, on, str(u["name"]), u["side"] == "player", u["flagship"], float(d["hp"]), float(u["maxHp"]), shs, float(u["shMax"]) * 4.0)
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f.t += dt
		var lbl: Label = f.lbl
		var wp: Vector3 = (f.pos as Vector3) + Vector3(0, 4.0 + f.t * 6.0, 0)
		lbl.visible = not cam.is_position_behind(wp)
		lbl.position = cam.unproject_position(wp) - lbl.size * 0.5 + Vector2(0, f.dy)
		lbl.modulate.a = clampf(1.6 - f.t, 0.0, 1.0)
		if f.t > 1.6:
			lbl.queue_free()
			floats.remove_at(i)
	if bot and not busy and not warming and not _threat_busy and not ended and api.phase == "player" and Engine.get_process_frames() % 2 == 0:
		bot_t += dt
		if bot_t > 0.05:
			bot_t = 0.0
			_bot_step()
	if args.has("trace-bot") and Engine.get_process_frames() % 120 == 0 and api != null:
		var act := ""
		for u in V.get("units", []):
			if u["active"]:
				act = "%s(%s %s)" % [u["id"], u["side"], u.get("tpl", "")]
		print("[trace] round %s phase %s side %s busy %s warming %s threat %s ended %s active %s sel %s last %.1f" % [str(V.get("round")), str(api.phase), str(V.get("side")), str(busy), str(warming), str(_threat_busy), str(ended), act, sel, Time.get_ticks_msec() / 1000.0 - last_progress])
	if args.has("quit-after") and Time.get_ticks_msec() / 1000.0 - t_start > float(args["quit-after"]):
		_quit_report()
	# softlock watchdog (bot runs): nothing happened for softlock_s seconds of real time while the battle is not over
	if bot and not ended and last_progress > 0.0 and Time.get_ticks_msec() / 1000.0 - last_progress > softlock_s:
		_error("softlock: no progress for %d s (phase %s, busy %s, round %s)" % [int(softlock_s), str(api.phase), str(busy), str(V.get("round"))])
		ended = true
		result = {"result": "softlock", "rounds": int(V.get("round", 0)), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start}
		finished.emit(result)


func _float(id, text: String, col: Color, dy := 0.0) -> void:
	if not views.has(id):
		return
	var lbl: Label = hud.make_float(text, col)
	floats.append({"lbl": lbl, "pos": _pos(id), "t": 0.0, "dy": dy * hud.k})


func _float_hit(id, sh: float, hull: float, crit) -> void:
	if sh > 0:
		_float(id, "−%d shield" % int(sh), Color("#62ccff"), -18)
	if hull > 0:
		_float(id, "−%d hull" % int(hull), Color("#ffd27a") if crit else Color("#ffae42"), 0)
	if crit:
		_float(id, "Critical", Color("#f0b35a"), 18)


# ---------------------------------------------------------------- onboarding (ui3d.js tutorialCheck)

func _tutorial() -> void:
	if tips_off or bot or ended or hud.tipcard != null or V.is_empty() or not _api_join():
		return
	var s := _sel_unit()
	var moved := false
	var fired := false
	var targets := false
	for u in V["units"]:
		if u["side"] == "player" and not u["dead"]:
			var ru = api.unit(u["id"])
			if ru != null and float(ru["mp"]) < float(_z0(ru.get("speed"))):
				moved = true
			for w in ru["weapons"]:
				if _jt(w.get("fired")):
					fired = true
	if not s.is_empty() and _usable(s):
		for e in V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not _firing_set(e["id"]).is_empty():
				targets = true
	var close := false
	if not s.is_empty() and api.unit(sel) != null:
		var cu := _ui(sel)
		close = cu.get("ram") != null or not (cu.get("board", []) as Array).is_empty()
	var cond := {"start": true, "turns": true, "threat": int(V["round"]) >= 2, "select": not s.is_empty(), "move": moved, "target": targets, "fired": fired, "close": close,
		"resolve": api.has_method("can_command") and api.can_command(),
		"objective": V.get("obj") != null and str(V["obj"].get("type", "rout")) != "rout"}
	for t in TIPS:
		if not tips.has(t[0]) and cond.get(t[0], false):
			hud.show_tipcard(t[0], t[1], t[2])
			return


func _load_opts() -> void:
	var p := "user://battle_opts.json"
	if FileAccess.file_exists(p):
		var o = JSON.parse_string(FileAccess.get_file_as_string(p))
		if o is Dictionary:
			tips = o.get("tips", {})
			tips_off = bool(o.get("tipsOff", false))
			user_speed = float(o.get("speed", 1.0))
	if args.has("no-tips") or args.has("shots") or args.has("breach-shots"):
		tips_off = true


func _save_opts() -> void:
	var f := FileAccess.open("user://battle_opts.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"tips": tips, "tipsOff": tips_off, "speed": user_speed}))


# ---------------------------------------------------------------- the bot (both sides on AI, for test runs)

# A simple player for test runs through the same commands a person uses: each ship takes the move that brings the most
# guns onto the weakest enemy in reach, fires everything that bears, braces when nothing can, and ends its activation.
var bot_tried := {}          # ship id -> round the bot last handed it to the AI (a ship the AI leaves idle is not picked again)


func _bot_step() -> void:
	var u_id := ""
	for u in V["units"]:
		if u["active"]:
			u_id = u["id"]
	if u_id == "":
		for u in V["units"]:
			if _usable(u) and not u["squadron"] and bot_tried.get(u["id"], -1) != V.get("round"):
				u_id = u["id"]
				break
	if u_id == "":
		if _classic():
			_cmd(func(): api.end_turn(); return true)
		else:
			_cmd(func(): api.end_activation(); return true)
		return
	sel = u_id
	var ru = api.unit(u_id)
	# the game's own player-side AI (sim3d.js botUnit, G1 ai_activate) when the rules have it
	if api.has_method("ai_activate"):
		var aid := u_id
		bot_tried[aid] = V.get("round")
		_cmd(func():
			api.ai_activate(aid)
			# a ship the AI leaves idle (nothing in reach, nothing to launch) never starts its activation: pass it, as the
			# player's Pass does, or the bot would pick it forever (a Corsair carrier fleet softlocked the battle at round 1)
			if api.phase == "player" and api.unit(aid) != null and _jt(api.unit(aid).get("activated")) == false:
				api.end_activation(aid)
			return true)
		return
	# (rules without ai_activate: just end the activation)
	_cmd(func(): api.end_activation(); return true)


static func _z0(x) -> Variant:
	if x == null or (x is bool and not x) or ((x is int or x is float) and x == 0):
		return 0
	return x


func _alive_active(id: String) -> bool:
	var v: Dictionary = api.view()
	for u in v["units"]:
		if u["id"] == id:
			return bool(u["active"])
	return false


# ---------------------------------------------------------------- screenshot job (--shots <folder>)

var shot_n := 0
var fire_shots := 0


func _snap(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		if move_frames == "":
			print("[shots] (headless, not saved) ", name)
		else:
			shot_n += 1
		await get_tree().process_frame
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if move_frames != "":
		# move captures: small JPGs per frame in a folder per ship
		DirAccess.make_dir_recursive_absolute(move_frames)
		shot_n += 1
		img.save_jpg(move_frames.path_join("%04d.jpg" % shot_n), 0.85)
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	shot_n += 1
	var p := shots_dir.path_join("%02d_%s.png" % [shot_n, name])
	img.save_png(p)
	print("[shots] ", p)


func _hover_unit(id: String) -> void:
	var p: Vector2 = cam.unproject_position(_pos(id))
	get_viewport().warp_mouse(p)
	_on_hover(p)


func _shots() -> void:
	# fixed moments for the screenshot-verdict skill: the opening board, a selected ship with its move range, the move
	# preview, the attack tip on an enemy, the threat map, top-down, mid-battle fire, and the end card
	while busy or warming or api == null:
		await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	await _snap("start")
	var mine := ""
	var foe := ""
	for u in V["units"]:
		if u["side"] == "player" and mine == "":
			mine = u["id"]
		if u["side"] == "enemy" and foe == "":
			foe = u["id"]
	select(mine)
	cam.focus(_pos(mine), 170.0)
	await get_tree().create_timer(1.2).timeout
	var far = null
	for k in reach_map:
		var st = reach_map[k]
		if far == null or float(st.cost) > float(far.cost):
			far = st
	if far != null:
		var p: Vector2 = cam.unproject_position(board.hex_world(far.q, far.r))
		get_viewport().warp_mouse(p)
		_on_hover(p)
	await get_tree().create_timer(0.4).timeout
	await _snap("move_preview")
	_hover_unit(foe)
	await get_tree().create_timer(0.4).timeout
	await _snap("attack_tip")
	threat_on = true
	_refresh_ui()
	cam.toggle_top()
	await get_tree().create_timer(1.5).timeout
	await _snap("threat_topdown")
	threat_on = false
	cam.toggle_top()
	cam.reset_view()
	if args.has("quick"):
		_quit_report()
		return
	hud.show_tip("", Vector2.ZERO)
	_refresh_ui()
	await get_tree().create_timer(1.0).timeout
	bot = true
	while not ended:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	await _snap("end")
	_quit_report()


# --breach-shots <dir>: close-ups of real hull damage in play. Both sides on AI; whenever a ship (an A4 kit ship first)
# reaches a holed section (stage 3 or 4 by the fx thresholds), the battle holds, the camera closes in from both sides and
# above, then play goes on; up to three ships. After the battle, survivors are shown forced to stages 3 and 4 (file
# names say "forced"). Also prints the A4 ship check: skins, heavy skins, hard points per ship on the board.
var hold := false


func _breach_shots() -> void:
	while busy or warming or api == null:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	for id in views:
		var sv = views[id]
		var c := {"skin": 0, "heavy": 0, "hp": 0}
		for n in (sv as Node).find_children("*", "", true, false):
			var nm := str(n.name)
			if nm.begins_with("skin_"):
				c["heavy" if nm.ends_with("_heavy") else "skin"] += 1
			elif nm.begins_with("hp_"):
				c["hp"] += 1
		print("[breach] ship %s %s a4=%s L=%.1f skins=%d heavy=%d hardpoints=%d" % [id, str(VU.get(id, {}).get("cls", "?")), str(sv.a4), float(sv.L), c["skin"], c["heavy"], c["hp"]])
	await _snap("board_start")
	user_speed = 0.45  # the game's Fast speed: the job fits its time and the pictures are the same
	bot = true
	var done := {}
	while not ended and done.size() < 3:
		await get_tree().process_frame
		if hold:
			continue
		var pick := ""
		for u in V.get("units", []):
			if u["dead"] or u["squadron"] or done.has(u["id"]) or not views.has(u["id"]):
				continue
			if _sec_stage(u) >= 3 and (pick == "" or (views[u["id"]].a4 and not views[pick].a4)):
				pick = u["id"]
		if pick != "":
			hold = true
			done[pick] = true
			await get_tree().create_timer(2.5).timeout  # the shots in flight land and the hole opens
			if VU.has(pick) and not VU[pick]["dead"]:
				await _closeups(pick, "inplay")
			hold = false
	while not ended:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	var forced := 0
	for u in V.get("units", []):
		if forced >= 2 or u["dead"] or u["squadron"] or done.has(u["id"]) or not views.has(u["id"]) or not views[u["id"]].a4:
			continue
		forced += 1
		for st in [[0.3, "forced3"], [0.1, "forced4"]]:
			var su: Dictionary = u.duplicate(true)
			if su.get("sec") is Dictionary:
				for k in su["sec"]:
					su["sec"][k]["hp"] = float(su["sec"][k].get("max", 1.0)) * float(st[0])
			su["hp"] = float(su["maxHp"]) * float(st[0])
			if gfx != null and gfx.has_method("sync_ship"):
				gfx.sync_ship(str(u["id"]), su)
			await get_tree().create_timer(3.5).timeout  # the hull rebuild runs on a worker (section 14)
			await _closeups(u["id"], st[1])
	print("[breach] in play: %d ships, forced: %d ships" % [done.size(), forced])
	_quit_report()


# --move-frames <dir> [--movement cinematic|brisk]: the player's biggest and smallest ship each make a long burn with a
# turn, from a fixed camera; a JPG per rendered frame (run with --fixed-fps 30 for even timing), through the settle
func _move_frames() -> void:
	while busy or warming or api == null:
		await get_tree().process_frame
	await get_tree().create_timer(1.5).timeout
	var mine: Array = []
	for u in V["units"]:
		if u["side"] == "player" and not u["dead"] and not u["squadron"]:
			mine.append(u)
	mine.sort_custom(func(a, b): return float(a["size"]) > float(b["size"]))
	var picks: Array = []
	if args.has("cls"):
		# --cls Dreadnought,Cruiser: the first of your ships of each class, in that order
		for c in str(args["cls"]).split(","):
			for u2 in mine:
				if str(u2["cls"]) == c and not (u2["id"] in picks):
					picks.append(u2["id"])
					break
	elif not mine.is_empty():
		picks.append(mine[0]["id"])
		if mine.size() > 1:
			picks.append(mine[-1]["id"])
	follow = false  # the camera stays on the burn
	tips_off = true
	hud.hide_tipcard()
	print("[moves] movement %s, ships %s" % [movement, str(picks)])
	for id in picks:
		while not _can_act():
			await get_tree().process_frame
		var states: Array = api.reach(id)
		var u: Dictionary = VU[id]
		var best = null
		var bsc := -1e9
		var want := str(args.get("maneuver", ""))
		for st in states:
			var turn := absf(angle_difference(ShipView.yaw_of(u["facing"]), ShipView.yaw_of(st.f)))
			var sc := float(st.cost) * 1.0 + (3.0 if turn > 1.0 else (1.5 if turn > 0.5 else 0.0))
			if want != "":
				sc = _maneuver_score(st.path, want)
			if sc > bsc:
				bsc = sc
				best = st
		if want != "" and bsc <= -1e8:
			print("[moves] %s: no %s move in reach" % [str(id), want])
			best = null
		elif best != null:
			print("[moves] %s (%s) path: %d steps, score %.1f" % [str(id), str(u["cls"]), (best.path as Array).size(), bsc])
		if best == null:
			continue
		var a: Vector3 = views[id].position
		var b: Vector3 = board.hex_world(best.q, best.r)
		cam.a = -PI / 2.0
		cam.b = 0.85
		cam.r = maxf(float(views[id].L) * 3.0, a.distance_to(b) * 2.4)
		cam.t = (a + b) * 0.5
		cam.snap()
		await get_tree().create_timer(0.4).timeout
		move_frames = shots_dir.path_join(str(id))
		var n0 := shot_n
		var sid: String = id
		var st0 = best
		_cmd(func(): return api.move(sid, st0))
		while busy or views[id].burning():
			await get_tree().process_frame
		for k in 42:  # the settle, 1.4 s at 30 frames a second
			await _snap("f")
		move_frames = ""
		print("[moves] %s done: %d frames" % [str(id), shot_n - n0])
		if _can_act():
			if _classic():
				_cmd(func(): api.end_turn(); return true)
			else:
				_cmd(func(): api.end_activation(); return true)
		while busy:
			await get_tree().process_frame
	_quit_report()


# --planet-shot <png> (with --map planet): the board planet framed from the battle camera's height, then quit
func _planet_shot() -> void:
	while busy or warming or api == null:
		await get_tree().process_frame
	hud.visible = false
	if board.planet_node == null:
		print("[planet] no planet on this board")
		_quit_report()
		return
	var p: Vector3 = board.planet_node.position
	var rad: float = (board.planet_node.mesh as SphereMesh).radius
	cam.t = Vector3(p.x, 0, p.z)
	cam.r = rad * 3.2
	cam.b = 1.15
	cam.snap()
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(str(args["planet-shot"]))
	print("[planet] shot saved ", args["planet-shot"])
	_quit_report()


# --sheet-check: build the ship sheet for every ship on the board (yours selected, theirs inspected), print a summary
func _sheet_check() -> void:
	while busy or warming or api == null:
		await get_tree().process_frame
	var n := 0
	var lines := 0
	for u in V["units"]:
		if u["dead"]:
			continue
		sel = u["id"] if u["side"] == "player" else ""
		inspect = "" if u["side"] == "player" else u["id"]
		var info := _panel_info()
		n += 1
		lines += (info.get("extra", []) as Array).size() + (1 if info.has("note") else 0) + (1 if info.has("captain") else 0)
		hud.set_panel(info)
	sel = ""
	inspect = ""
	print("[sheet] %d ships, %d extra parts" % [n, lines])
	_quit_report()


# --maneuver straight|turn|side|back (with --move-frames): how well a path shows one maneuver; -1e9 when it does not
#   straight: ahead only, the longer the better; turn: turns in place then ahead (rotate, then burn);
#   side: sidesteps only; back: backing off only
func _maneuver_score(path: Array, want: String) -> float:
	var n_rot := 0
	var n_slip := 0
	var n_rev := 0
	var n_fwd := 0
	var rot_after_move := false
	for st in path:
		if _jt(st.get("rot")):
			n_rot += 1
			if n_fwd + n_slip + n_rev > 0:
				rot_after_move = true
		elif _jt(st.get("slip")):
			n_slip += 1
		elif _jt(st.get("rev")):
			n_rev += 1
		else:
			n_fwd += 1
		if st.get("over") != null and float(st.get("over")) != 0.0:
			return -1e9
	match want:
		"straight":
			return float(n_fwd) if n_fwd > 0 and n_rot + n_slip + n_rev == 0 else -1e9
		"turn":
			return float(n_rot) * 2.0 + float(n_fwd) if n_rot > 0 and n_fwd > 0 and n_slip + n_rev == 0 and not rot_after_move else -1e9
		"side":
			return float(n_slip) if n_slip > 0 and n_rot + n_fwd + n_rev == 0 else -1e9
		"back":
			return float(n_rev) if n_rev > 0 and n_rot + n_fwd + n_slip == 0 else -1e9
	return -1e9


func _sec_stage(u: Dictionary) -> int:
	# the fx ladder (fx/API.md section 2): the worst section's stage
	var best := 0
	var sec = u.get("sec")
	if sec is Dictionary:
		for k in sec:
			var sd = sec[k]
			if sd is Dictionary:
				var f := float(sd.get("hp", 1.0) if sd.get("hp") != null else 1.0) / maxf(float(sd.get("max", 1.0) if sd.get("max") != null else 1.0), 1.0)
				var st := 0 if f > 0.8 else (1 if f > 0.6 else (2 if f > 0.4 else (3 if f > 0.2 else 4)))
				if sd.get("broken") == true:
					st = 4
				best = maxi(best, st)
	return best


func _closeups(id: String, tag: String) -> void:
	var sv = views[id]
	var save := [cam.a, cam.b, cam.r, cam.t]
	var yaw: float = sv.rotation.y
	var rr := clampf(float(sv.L) * 1.5, cam.min_r, 140.0)
	var nm := "%s_%s_%s" % [tag, str(VU.get(id, {}).get("cls", "ship")).replace(" ", ""), id]
	for v in [[yaw + PI / 2.0, 0.35, "port"], [yaw - PI / 2.0, 0.35, "starboard"], [yaw + PI * 0.75, 0.9, "above"]]:
		cam.a = float(v[0]); cam.b = float(v[1]); cam.r = rr; cam.t = Vector3(sv.position.x, 0, sv.position.z)
		cam.snap()
		await get_tree().create_timer(0.5).timeout
		await _snap(nm + "_" + str(v[2]))
	cam.a = save[0]; cam.b = save[1]; cam.r = save[2]; cam.t = save[3]
	cam.snap()


# the enemy's share of each round in game seconds (what the player waits through at the B2 pace; hurry not pressed)
func pace_stats() -> Dictionary:
	var vals: Array = pace_enemy.values()
	if vals.is_empty():
		return {"rounds": 0}
	var tot := 0.0
	var mx := 0.0
	for v in vals:
		tot += float(v)
		mx = maxf(mx, float(v))
	var kinds := {}
	for k in pace_kind:
		if float(pace_kind[k]) >= 0.05:
			kinds[k] = snappedf(float(pace_kind[k]) / vals.size(), 0.01)
	var by_round: Array = []
	for r in pace_enemy.keys():
		by_round.append(snappedf(float(pace_enemy[r]), 0.1))
	return {"rounds": vals.size(), "enemy_s_mean": snappedf(tot / vals.size(), 0.01), "enemy_s_max": snappedf(mx, 0.01), "movement": movement, "per_round_by_kind": kinds, "by_round": by_round}


func _quit_report() -> void:
	print("[battle] report: ", JSON.stringify({"result": result.get("result", "unfinished"), "round": V.get("round"), "errors": errors, "secs": Time.get_ticks_msec() / 1000.0 - t_start,
		"pipeline_compiles_in_play": _pipe_count() - pipe_base if pipe_base >= 0 else -1, "pace": pace_stats()}))
	_quit()


func _quit(code := 0) -> void:
	var m = get_node_or_null("/root/Main")
	if m != null and m.has_method("quit_clean"):
		m.quit_clean(code)
		return
	set_process(false)
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	ShipView.clear_static()
	Fx.clear_static()
	# other streams' statics (G4 fx and world, G3 screens): a clear_static() there is called too when it exists
	for sp in ["res://fx/fx.gd", "res://world/world.gd", "res://render/look.gd", "res://ui/campaign/campaign_ui.gd", "res://portraits/portraits.gd"]:
		if ResourceLoader.exists(sp):
			var sc = load(sp)
			if sc != null and sc.has_method("clear_static"):
				sc.clear_static()
	get_tree().quit(code)
