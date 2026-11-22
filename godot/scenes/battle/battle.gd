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
# that bears (1-6 pick one), Q/E turn in place, Backspace steps back through the plan, then undoes a move (issues 1589, 1450), B brace, X ram, G board, Tab next ship, Enter end activation (or hurry the
# enemy), Space hurry, Esc cancel, R threat map, V arcs, T top-down, F focus, Home reset view; right-drag orbit,
# left-drag or WASD pan, wheel zoom.

signal finished(result: Dictionary)
signal storm_drained(pos: Vector3)
signal arrival(units: Array)   # F1: reinforcements are arriving (the acceptance trace films it)
signal wings_together(n: int)   # F1: your strike craft just started their moves together (the trace films it)
signal recording_cue(kind: String, text: String)

const API := preload("res://rules/battle_api.gd")
const JSM := preload("res://rules/jsm.gd")
const Campaign := preload("res://campaign/campaign.gd")
const Board := preload("res://render/board.gd")
const ShipView := preload("res://render/ship_view.gd")
const CamRig := preload("res://render/camera_rig.gd")
const HT := preload("res://render/hull_table.gd")
const FLOOK := preload("res://fx/faction_look.gd")   # issue 1205: faction colours come from fx/faction_looks.json only
const WEAPON_FX := preload("res://fx/fx_weapons.gd")
const HUD := preload("res://ui/battle/hud.gd")
const UiScale := preload("res://ui/ui_scale.gd")
const Fx := preload("res://scenes/battle/fx_stub.gd")
const Sfx := preload("res://audio/sfx.gd")
const DeathAudio := preload("res://audio/death_audio.gd")
const Backdrop := preload("res://render/backdrop.gd")
const PG := preload("res://render/placeholder_guard.gd")
const LOOK := preload("res://render/look.gd")
const WORLD_SKY := preload("res://world/world_sky.gd")
const LIVING := preload("res://world/world_living.gd")

const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const KEY_COL := Color(1.0, 0.96, 0.90)
const FILL_DIR := Vector3(0.6, -0.2, 0.75)
const FILL_COL := Color(0.55, 0.65, 0.85)
const Teaching := preload("res://ui/campaign/campaign_tips.gd")
const PlayLog := preload("res://scenes/battle/play_log.gd")
# F1: move hexes are blue (board.gd REACH_*: a colour no terrain uses); targets red; a target that would bear from the
# planned hex orange; the targeted enemy white-hot
const REACH_C := Board.REACH_FILL
const EMBER_3D := ShipView.EMBER   # the ring under the ship that is up (issue 271: ember, lime retired R191)
const REACH_RING := Board.REACH_RING
const REACH_HOT := Board.REACH_HOT
# issue 1374 (R362): every ring and line colour comes from the one line style's role table (render/line_style.gd)
const TARGET_RING: Color = Board.LS.ROLE["target"]
const TARGET_PLAN: Color = Board.LS.ROLE["target_plan"]
const TARGET_ON: Color = Board.LS.ROLE["target_on"]
const QUAD_NAME := ["prow", "starboard", "rear", "port"]
const SEC_NAME := {"prow": "fore", "mid": "core", "eng": "engines"}
const MOVE_PER := {"voidsworn": 1.25, "hegemony": 0.75, "corsair": 0.85, "chorus": 1.1, "ithar": 1.0, "deathless": 0.6}
# F2 move pace (R64, Nov 1: about twice as slow, one ship at a time): ms per hex for an escort and for a battleship or
# bigger (in between by size; the faction factor above enters as its square root), the build-and-bleed allowance, the cap
# on one move, the weight of a 60 degree turn in hexes (escort, battleship), strike craft against a hull their size
const MOVE_HEX := [560.0, 860.0]
const MOVE_LEAD := [250.0, 450.0]
const MOVE_CAP := 7000.0
const MOVE_ROT := [0.6, 1.1]
const MOVE_SQUAD := 0.35
const MOVE_SK_MAX := 1.4     # the size scale runs past battleship at half slope (dreadnought 1.25, bosses up to 1.4), by eye
const MOVE_CRUISE := 0.8      # a hull cruises a hex in this share of its hex time; building and bleeding speed fill the rest
# Issue 1581 (Nov 21 outside motion audit: frigates "snappy and weightless beside capitals"): an escort flies a little
# firmer. Its hex time grows by up to 14 percent (a frigate's peak burn about 36 to 31 units a second) and its turn
# weight by up to 30 percent (about 123 to 95 degrees a second), easing to nothing at battleship size, so nothing from a
# battleship up changes. Cinematic flown moves only.
const MOVE_ESCORT_PACE := 1.14
const MOVE_ESCORT_TURN := 1.3
const NO_READY_GUN_IN_RANGE := "No ready gun can reach it."
const TIPS := [
	["select", "Moving and facing", "Click a blue hex to plan a move. Turn with Q and E before you confirm. Staying in place gives enemies +10 to hit; moving 3 or more hexes normally gives them -5. Most ships can Brace instead of firing: this cuts hull damage and removes the +10, but ends the ship's turn. Glasswright ships cannot Brace."],
	["target", "Firing", "The red ring means this enemy can be hit from where your ship sits. Click it once to see the hit chance and the damage expected. Click again to fire every gun that bears. Keys 1 to 6 fire one gun at a time."],
	["fired", "Taking turns", "Sides take turns, one ship at a time, until every ship has acted. That is one round. Press Space to end this ship early, or Tab for the next ship. A ship with nothing left to do ends itself."],
	["move", "Shields and hull", "The blue bar shows your shield pool. All four sides share it. Sides with more coverage block more damage while shields hold. Shields recharge each round. The pale bar shows hull. Hull damage needs repairs."],
	["threat", "Threat map", "Press R for the threat map. It shades every hex enemy guns can reach next turn. Darker means more damage waiting there."],
	["reinforce_warn", "More ships are coming", "Reinforcements arrive at the map edge. A glowing strip on the edge marks where they will enter, and a toast names the ship when they do. A new arrival acts in the turn order like any other ship."],
	["close", "Close action", "Up close you have two more attacks. Press X to ram an enemy dead ahead. Press G to board an enemy next to your ship. Win a boarding and the ship is yours for the rest of the fight."],
	["resolve", "Admiral's Command", "Your admiral's Command is ready. Hover over it to see what it does now and what waiting adds. You can give it once per battle. The icon turns orange after the first press; press again to give the order."],
	["objective", "Objectives", "Look beside the round counter at the top left for this fight's goal. Completing that goal can win the battle even with enemy ships still on the board."],
]

var args := {}
var api
var TBL := {}               # the rules tables (FACTIONS, ADMIRALS, ABILITIES, ORDERS, COMMANDS, ARC_NAME, PACE ...), read only
var PACE := {}
var V := {}                # the view the picture is synced to
var VU := {}               # id -> unit in V
var disp := {}             # id -> {hp, sh} as drawn (changes as hits land)
var regen_unlocks := {}    # id -> number of lock expiries played, so a late hit cannot restore an expired lock
var views := {}            # id -> ShipView
var wrecked := {}
var board: Node3D
var cam: Camera3D
var hud: CanvasLayer
var fx: Node3D
var sfx: Node
var death_audio: Node
var adaptation_heard := false
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
var burns_live := 0          # moves under way (F2 pace check: ships move one at a time)
var move_s_round := {}       # round -> game seconds of enemy moves (F2: moves play at their own pace, outside the round budget)
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
var danger_on := true         # #271: the reach hatching on the board in your turn (how many enemies can reach each hex)
var arcs_on := true
var floats: Array = []
var ended := false
var fired_in_act := {}     # unit id -> weapons fired this activation (volley pace)
var aim := {}              # issue 1211: the enemy volley playing now, {"a": attacker id, "t": target id}; its target is ringed and named
const AIM_RING := Color("#ff4433")
const FLOAT_LANE_SHIELD := -26.0   # a ship's shield number sits one line above its hull number (issue 1211)   # the target ring under an enemy volley (glass_shell ALERT: danger)
var tips := {}
var tips_off := false
var tip_pending := ""
var tip_current := ""
var tip_dismissed := {}
var tip_slot := ""
var tip_shown_slots := {}
var tip_handed := false
var tip_enemy_done := false
var tip_shot := false
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
var torp_snapped := 0      # issue 1531: torpedo salvos captured so far (--torp-max)
var torp_ft := {}          # issue 1379: frame times through one torpedo salvo (--torp-shots DIR --torp-ft)
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
var path_line: MeshInstance3D
var errors: Array = []
var result := {}
var battle_cfg := {}
var ai_level := ""         # "veteran" or "standard" (settings); empty keeps the rules default
var in_campaign := false   # a campaign battle (no quit to title: the run decides what a battle ends as)
var can_retreat := false   # campaign battles (not against a sector flagship): the top bar offers Retreat
var round_save_cb: Callable = Callable()   # issue 1451: campaign battles save each round start once it has settled (main.play_api)
var round_saved := 0                       # the newest round handed to round_save_cb
var round_on_disk := 0                     # the newest round round_save_cb reported written (0: only the pre-fight save)
var showcase := false     # the title screen's decorative battle (campaign3d.js setupShowcase): no HUD, no turns, no input, slow orbit
var music_hits := 0        # issue 1448: hits landed this round by either side, fed to the music as `shots`
var boss_fight := false    # a sector flagship fight or the finale (battle kind "boss"): boss music and the champion fanfare
var finale_fight := false  # R78 Q18: the run's final battle lights the new sun over the board, sector by sector
var external := false      # run by godot/main (campaign or quick battle): no own restart, the end card says Continue
var last_progress := 0.0   # real time of the last event batch (softlock watchdog for bot runs)
var softlock_s := 60.0
# ---- F1 activation layer (UI only; the rules are untouched): the ship that is up, a rehearsed move, a target
var plan = null               # a rehearsed move: the reach state the ghost shows; nothing goes to the rules until it is confirmed
var plan_k := ""              # its hex
var target := ""              # the enemy the ship that is up has targeted: the odds show; a second click, Enter or Fire commits
var atk = null                # a rehearsed attack-move on that target: {st, n, of} (the target is out of reach from here)
# Issue 1589 (Ryan, Nov 22 2026): the whole turn is planned on the ghost, then one commit plays it as one event. aims are the
# planned volleys from the ghost ({tid, guns}); plan_steps holds what the plan looked like before each step, so Backspace
# takes one step back. Nothing here reaches the rules until the commit.
var aims: Array = []
var plan_steps: Array = []
var up_idx := -1              # fleet-list index of the last ship handed over (the next hand-over goes on from there)
var handed_t := -9.0          # real time of the last hand-over: Space cannot end a ship in its first half second
var ghost: Node3D             # the planned position: a see-through copy of the hull
var ghost_for := ""
var ending := false           # the game is ending a ship that has nothing left to do
var arrived := {}             # reinforcements: id -> round they arrived (NEW in the fleet list, a pulse on the board)
var plog = PlayLog.new()
var tail_round := -1          # the round whose enemy tail (every one of your ships done) got its "Enemy turn" banner
var chime_round := -1         # the round whose first hand-over played the "your turn" cue


func _ready() -> void:
	_args()
	t_start = Time.get_ticks_msec() / 1000.0
	bot = bot or args.has("bot")
	shots_dir = str(args.get("shots", ""))
	if args.has("breach-shots"):
		shots_dir = str(args["breach-shots"])
	if args.has("move-frames"):
		shots_dir = str(args["move-frames"])
	if args.has("f1-trace"):
		shots_dir = str(args["f1-trace"])
	if args.has("ui-shots"):
		shots_dir = str(args["ui-shots"])
	if args.has("tree-shots"):
		shots_dir = str(args["tree-shots"])
	if args.has("torp-shots"):
		shots_dir = str(args["torp-shots"])   # issue 1379: eight frames of every torpedo and rocket volley, close (torp-cam, default 34)
	_load_opts()
	if shots_dir != "" or args.has("sheet-check"):
		tips_off = true   # screenshot jobs: no onboarding tip card covering the top of the screen
	if args.has("movement"):
		movement = str(args["movement"])
	if args.has("reduce-motion"):
		reduce_motion = true
	_build_world()
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.cam = cam
	death_audio = DeathAudio.new()
	death_audio.sfx = sfx
	add_child(death_audio)
	hud = HUD.new()
	add_child(hud)
	hud.action.connect(_on_action)
	hud.rescaled.connect(_refresh_ui)   # UI pass: the HUD was rebuilt for a new window size
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
	elif args.has("tree-shots"):
		_tree_shots(str(args.get("tree-shot", "role")))
	elif args.has("ui-shots"):
		# UI pass layout check (ui/battle/ui_shots.gd): five moments, a still and an overlap check each
		var us: Node = load("res://ui/battle/ui_shots.gd").new()
		us.name = "UiShots"
		add_child(us)
		us.run(self)
	elif args.has("f1-trace"):
		# F1 acceptance trace (scenes/battle/f1_trace.gd): the phased-activation checklist through the real input handlers
		var tr: Node = load("res://scenes/battle/f1_trace.gd").new()
		tr.name = "F1Trace"
		add_child(tr)
		tr.run(self)
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
		sh.code = WORLD_SKY.PANORAMA_SKY
		var pano := ShaderMaterial.new()
		pano.shader = sh
		pano.set_shader_parameter("pano", load(sky_res))
		if LOOK.fleet_lighting_enabled():
			pano.set_shader_parameter("sun_dir", -LOOK.KEY_DIR.normalized())
			pano.set_shader_parameter("fleet_reflections", true)
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
	LOOK.apply(env, key, fill, {"quality": str(args.get("quality", "max"))})
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


# the Graphics setting: max (everything but SSIL since issue 1262), high (no SSIL, smaller shadows), low (no MSAA, SSAO or volumetric haze)
func _apply_quality(q: String) -> void:
	apply_quality_to(get_viewport(), q, _jt(args.get("taa", false)))


static func apply_quality_to(vp: Viewport, q: String, taa: bool) -> void:
	vp.msaa_3d = LOOK.msaa_for_quality(q)
	# issue 1437 (item 8): the whole AA state every time (the viewport is the game's own, shared by every later screen
	# and battle), so Low then Max no longer leaves FXAA on
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if q == "low" else Viewport.SCREEN_SPACE_AA_DISABLED
	RenderingServer.directional_shadow_atlas_set_size(2048 if q == "low" else 4096, true)
	# Temporal AA (settings, off by default as in the browser): Max and High only
	vp.use_taa = taa and q != "low"


func _post_quality(q: String) -> void:
	LIVING.apply_fog(self, env, cam.r, q)
	if q == "low":
		env.ssao_enabled = false
		env.ssil_enabled = false
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
	path_line = MeshInstance3D.new()
	path_line.material_override = Board.LS.material()   # issue 1374: the shared line style
	path_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(path_line)


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
		a.set_undo(true)   # issue 1450: a test battle played in the scene can take moves back like any other
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
	# #271 HUD captures (docs/shots/ui_redesign/build/CAPTURES.md): --fleet-size N repeats the default trio to N ships (the
	# 20-ship fleet list); --ui-demo adds a Nemesis (Hegemony, built like test scenario s38 with current names) and Heat 3 (Hunted, Vengeful
	# flagships), so every block of the shell has real rules state to show
	if args.has("fleet-size"):
		var base_f: Array = sc["fleet"]
		var nf: Array = []
		for i in clampi(int(args["fleet-size"]), 1, 24):
			nf.append(base_f[i % base_f.size()])
		sc["fleet"] = nf
	if args.has("fleet"):
		sc["fleet"] = Array(str(args["fleet"]).split(","))   # issue 1589 captures: e.g. a Glasswright fleet (with --admiral aelith)
	if args.has("admiral"):
		sc["admiral"] = str(args["admiral"])
	if args.has("obj"):
		sc["obj"] = str(args["obj"])   # e.g. ambush: the fleets start inside gun reach (the Fire odds show in round 1)
		if sc["obj"] == "ambush":
			sc["dep"] = "ambush"
	if args.has("ui-demo"):
		sc["fac"] = "hegemony"
		sc["nemesis"] = {"name": "Petra Valk", "title": "Fleet Marshal", "fac": "hegemony", "weak": ["anchor", "flank"], "adapt": ["formation", "pd"], "scars": 0,
			"persona": "methodical", "traits": ["artillery", "gunnery"], "g": "f", "revealed": ["flank"]}
		sc["heat"] = ["h_hunted", "h_flag"]
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
	_gen += 1   # issue 1433: work still awaiting from the last battle on this node is stale now
	_api_join()
	retiring = false
	_click_q = {}
	_threat_version = -1
	_threat_one_ver = -1
	api = a
	warming = true
	hud.loading(true)
	var obj0 = api.view().get("obj")
	if obj0 is Dictionary and str(obj0.get("type", "")) == "hold":
		A4P.prefetch_beacon()   # issue 1536 (PR 1561 review): the relay beacon reads on a worker while the cover shows
	if gfx != null:
		gfx.defer_initial_cuts = DisplayServer.get_name() != "headless"
	if DisplayServer.get_name() != "headless":
		await get_tree().process_frame
		await get_tree().process_frame
	TBL = _api_tables()
	if ai_level != "":
		_api_set_ai(ai_level)
	PACE = TBL.get("PACE", {})
	boss_fight = _api_battle_kind() == "boss"
	finale_fight = _api_battle_finale()
	ended = false
	result = {}
	errors.clear()
	bot_ab.clear()
	bot_moved.clear()
	bot_tried.clear()
	bot_cmd_used = false
	roles_opened = false
	round_saved = 0
	round_on_disk = 0
	t_start = Time.get_ticks_msec() / 1000.0
	last_progress = t_start
	for id in views:
		(views[id] as Node).queue_free()
	views.clear()
	wrecked.clear()
	disp.clear()
	regen_unlocks.clear()
	batches.clear()
	fx.clear()
	hud.hide_end()
	sel = ""
	inspect = ""
	armed = -1
	_plan_clear()
	up_idx = -1
	ending = false
	arrived.clear()
	tail_round = -1
	chime_round = -1
	plog = PlayLog.new()
	tip_pending = ""
	tip_current = ""
	tip_dismissed.clear()
	tip_slot = ""
	tip_shown_slots.clear()
	tip_handed = false
	tip_enemy_done = false
	tip_shot = false
	hud.hide_tipcard()
	adaptation_heard = false
	_ghost_clear()
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
		var world_opts := {"biome": wi.get("biome", {}) if wi.get("biome") is Dictionary else {}, "fac": _enemy_fac_of(vb), "hex_world": board.hex_world, "camera": cam, "environment": env,
			"quality": str(args.get("quality", "max")), "pano": pano, "seed": int(wi.get("seed", 1)) if wi.get("seed") != null else 1, "finale": finale_fight,
			"nebula_wake": args.has("nebula-wake") or str(args.get("nebula_wake", "false")) == "true"}
		if args.has("sector_setting"): world_opts["sector_setting"] = args["sector_setting"]
		if args.get("stop") is Dictionary: world_opts["stop"] = args["stop"]   # issue 1272: the stop's sky mood
		world.build(vb, world_opts)
		for c in backdrop.get_children():
			c.queue_free()
	else:
		backdrop.build(cam.bounds, env)
	V = api.view()
	_index_view()
	for u in V["units"]:
		_make_view(u)
	_sync(V)
	if world != null: world.use_ship_debris(views.values())
	# open on your fleet, looking toward the enemy (the browser game's camera starts over the player's side)
	var hv: Dictionary = board.home_view(V["units"])   # shared with the Hold relay beacon's placement (issue 1536)
	cam.home = hv["target"]
	cam.reset_view()
	cam.home_r = hv["r"]
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
			recording_cue.emit("voice", l["text"])
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
	if not bot and not args.has("shots") and not args.has("breach-shots"):
		_start_opening()
	var story_lines: Array = api.R.storyModifierLines()
	if not story_lines.is_empty(): hud.toast(" ".join(PackedStringArray(story_lines)))
	if not busy:
		_runner()


# F1 (R62, battles start zoomed out): the opening beat. After the warm-up the camera frames both fleets and the objective
# inside the part of the screen the panels leave clear, holds about 1.75 s (or until the first key or click), then glides to
# the ship that is up (or back to the home view if the enemy moves first). The first hand-over happens underneath; only its
# camera glide waits for the beat to end.
# the clear part of the screen: right of the fleet list, left of the info panel, under the top bar, above the card
const OPEN_FRAME := [0.16, 0.13, 0.80, 0.80]
const OPEN_HOLD := 1.75
var opening := false
var opening_framed := false   # every ship and objective hex fitted in the clear part of the screen (for the trace)


func _opening_points() -> Array:
	var pts: Array = []
	for u in V["units"]:
		if not u["dead"]:
			pts.append(board.hex_world(u["q"], u["r"]))
	var keys: Array = board.zone_of.keys()
	for k in V.get("terrain", {}):
		if str(V["terrain"][k]) == "station":
			keys.append(k)
	for k in keys:
		var qr: PackedStringArray = str(k).split(",")
		if qr.size() == 2:
			pts.append(board.hex_world(float(qr[0]), float(qr[1])))
	return pts


func _fits_open(pts: Array) -> bool:
	for p in pts:
		if not cam.sees_in(p, OPEN_FRAME[0], OPEN_FRAME[1], OPEN_FRAME[2], OPEN_FRAME[3]):
			return false
	return true


func _start_opening() -> void:
	var pts := _opening_points()
	if pts.is_empty():
		return
	var lo: Vector3 = pts[0]
	var hi: Vector3 = pts[0]
	for p in pts:
		lo = Vector3(minf(lo.x, p.x), 0, minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), 0, maxf(hi.z, p.z))
	cam.reset_view()
	cam.t = (lo + hi) * 0.5
	cam.r = cam.home_r
	cam.snap()
	var cap := maxf(cam.bounds.x, cam.bounds.y) * 3.0
	for i in 30:
		if _fits_open(pts) or cam.r >= cap:
			break
		cam.r = minf(cam.r * 1.08, cap)
		cam.snap()
	opening_framed = _fits_open(pts)
	opening = true
	var tm := get_tree().create_timer(OPEN_HOLD)
	while opening and tm.time_left > 0.0 and is_inside_tree():
		await get_tree().process_frame
	_end_opening()


func _end_opening() -> void:
	if not opening:
		return
	opening = false
	if api != null and api.phase == "player" and sel != "" and views.has(sel):
		cam.glide(_pos(sel), 1.4, cam.home_r)
	else:
		cam.glide(cam.home, 1.4, cam.home_r)


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
const ArrivalWarm := preload("res://render/arrival_warm.gd")
const A4P := preload("res://assets/ships/a4_props.gd")   # issue 1536: the Hold relay beacon prefetch
var arrival_warm = null   # issue 1289: the hidden copies of the hulls that arrive mid-battle (render/arrival_warm.gd)


func _warmup() -> void:
	warming = true
	hud.loading(true)
	if world != null: await world.wait_ready()
	var keep := {"a": cam.a, "b": cam.b, "r": cam.r, "t": cam.t}
	cam.b = 0.6
	cam.r = maxf(cam.bounds.x, cam.bounds.y) * 2.4
	cam.t = Vector3.ZERO
	cam.snap()
	for i in 3:
		await get_tree().process_frame
	if gfx != null and gfx.has_method("warmup") and DisplayServer.get_name() != "headless":
		# issue 1289: the reinforcement's hull is built, cut and drawn here with the others, then hidden until it arrives
		if api != null and api.has_method("arrival_previews"):
			arrival_warm = ArrivalWarm.new()
			arrival_warm.prepare(self, gfx, api.arrival_previews(), Vector3.ZERO)
			for i in 2:
				await get_tree().process_frame
		await gfx.prepare_battle_hulls()
		# at most 20 s: a warm-up that never returns must never hold the battle (Opus review, Nov 3)
		var done := [false]
		var run := func() -> void:
			await gfx.warmup(cam)
			done[0] = true
		run.call()
		var t0 := Time.get_ticks_msec()
		while not done[0] and Time.get_ticks_msec() - t0 < 20000:
			await get_tree().process_frame
		if arrival_warm != null:
			arrival_warm.park()
	for i in 2:
		await get_tree().process_frame
	cam.a = keep["a"]
	cam.b = keep["b"]
	cam.r = keep["r"]
	cam.t = keep["t"]
	cam.snap()
	await get_tree().process_frame
	await load("res://main/load_screen.gd").settle(get_tree())
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
	sv.calm = reduce_motion   # issue 1581: Reduce motion per view (no drift, bob or nod; half the ignition beat)
	disp[u["id"]] = {"hp": float(u["hp"]), "sh": (u["sh"] as Array).duplicate(), "regenLock": bool(u.get("regenLock", false))}
	_register_fx_ship(u, sv)


func _register_fx_ship(u: Dictionary, sv: ShipView) -> void:
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
				if m["side"] == "player" and not m["dead"] and hex_distance(m, u) <= 3:
					close += 1
					break
	music.feed({"close": close, "shots": music_hits, "hull": hp / maxf(1.0, mhp), "flagship": flag, "mine": mine, "enemy": foes, "boss": boss})


# True hex steps between two units on the axial grid (rules.gd hdist); the music counts an enemy within 3 as close.
static func hex_distance(a: Dictionary, b: Dictionary) -> int:
	var dq := int(a["q"]) - int(b["q"])
	var dr := int(a["r"]) - int(b["r"])
	return int((absi(dq) + absi(dr) + absi(dq + dr)) / 2.0)


func _sync(v: Dictionary) -> void:
	V = v
	_index_view()
	_music_feed()
	for u in V["units"]:
		if not views.has(u["id"]):
			_make_view(u)
		var sv = views[u["id"]]
		disp[u["id"]] = {"hp": float(u["hp"]), "sh": (u["sh"] as Array).duplicate(), "regenLock": bool(u.get("regenLock", false))}
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
	var g := _gen
	while true:
		if _stale(g):
			return
		while hold and is_inside_tree():
			await get_tree().process_frame
		if _stale(g):
			return
		if batches.is_empty():
			if api.phase == "enemy" and not ended:
				while _threat_busy and not _stale(g):
					_worker_owns_rules()
					await get_tree().process_frame
				if _stale(g):
					return
				var b = await _think()
				if _stale(g):
					return
				if b != null:
					batches.append(b)
				continue
			busy = false
			if api.phase == "over" and not ended:
				await _end_flow()
				if _stale(g):
					return
			_after_batches()
			_refresh_ui()
			return
		var bt: Dictionary = batches.pop_front()
		# only a batch with events is progress: a bot looping on commands that change nothing must still trip the watchdog
		if not (bt.get("events", []) as Array).is_empty():
			last_progress = Time.get_ticks_msec() / 1000.0
		await _play_batch(bt)
		if _stale(g):
			return
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
	_click_q = {}
	var ok = f.call()
	var ev: Array = api.take_events()
	var np := _api_not_ported()
	if np != "":
		_error("NOT PORTED: " + np)
	if ev.is_empty() and not ok:
		return false
	_plan_clear()   # issue 1589: once the rules have acted, a plan made before is stale
	batches.append({"events": ev, "view": api.view()})
	_clear_overlay()
	_runner()
	_refresh_ui()   # issue 1589 (Ryan, Nov 22): the runner is now busy, so the card leaves while the event plays
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


# R78 Q18: the campaign marks its fifth run in scene args, without adding a rule or save field. Only that run's
# sector 3 boss gets dawn. A scenario may also ask for it outright (cfg.finale), for captures and fixtures.
func _api_battle_finale() -> bool:
	var B = api.R.B
	if B is Dictionary and B.get("cfg") is Dictionary:
		var c: Dictionary = B["cfg"]
		if bool(c.get("finale", false)):
			return true
		var run = api.R.RUN
		if str(c.get("kind", "")) == "boss" and run is Dictionary:
			return bool(args.get("finale", false)) and int(run.get("sector", 0)) == 3
	return false


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


# ---------------------------------------------------------------- the rules client (issue 1433)
# This block alone owns the two worker task ids. The rules API locks _enter/_leave around threat_both and every read
# (can_command too), so a read while the threat worker runs waits on the worker either way: a join or the mutex.
# - Pointer handlers (_on_hover, _on_click) set _ptr_depth. Inside them _api_join never waits: it answers false while the
#   worker runs, the reads answer from the last published result or "pending", and _ptr_stale asks the publish to refresh
#   the pointer (tip, panel, target) once the result lands.
# - _refresh_ui waits for the publish instead of reading the live API (its reads all lock the rules).
# - A click while the worker runs is queued once and revalidated before it is played (_click_replay).
# - _gen and retiring: a battle that has emitted finished (or been begun again) rejects its stale post-await work.
# Commands, keys and the HUD still call the blocking _api_join, which finishes the worker first (its result is kept).
var _ptr_depth := 0
var _ptr_stale := false
var _ptr_pos := Vector2.ZERO
var _click_q := {}
var _gen := 0
var _threat_gen := -1
var retiring := false


# true while a threat task is still running; a finished one is reaped (and published) here, without waiting
func _worker_owns_rules() -> bool:
	if _threat_tid < 0:
		return false
	if not WorkerThreadPool.is_task_completed(_threat_tid):
		_ptr_stale = true
		return true
	_threat_reap()
	return false


# reap the threat task once; publish only for this battle (the version check is in _threat_done)
func _threat_reap() -> void:
	WorkerThreadPool.wait_for_task_completion(_threat_tid)
	_threat_tid = -1
	if retiring or _threat_gen != _gen:
		_threat_busy = false
		return
	_threat_done()


# the non-blocking gate: may the main thread read the rules right now?
func _api_free() -> bool:
	if api == null or _worker_owns_rules():
		return false
	return not thinking


func _api_join() -> bool:
	if api == null:
		return false
	if _ptr_depth > 0:
		return _api_free()
	if _threat_tid >= 0:
		_threat_reap()
	return not thinking


func _stale(g: int) -> bool:
	return retiring or g != _gen or not is_inside_tree()


# mark the battle retired before finished goes out: post-await work from it is rejected from here on
func _retire() -> void:
	retiring = true
	_gen += 1
	_click_q = {}


func _finish(r: Dictionary) -> void:
	_retire()
	finished.emit(r)


func _exit_tree() -> void:
	# exit synchronisation stays: drain both tasks, then clear the flags they own
	retiring = true
	_gen += 1
	if _threat_tid >= 0:
		WorkerThreadPool.wait_for_task_completion(_threat_tid)
		_threat_tid = -1
	_threat_busy = false
	if _think_tid >= 0:
		WorkerThreadPool.wait_for_task_completion(_think_tid)
		_think_tid = -1
	thinking = false
	# issue 1204: the per-hull look copies are keyed by this battle's materials; drop them so a run does not grow them
	ShipView.clear_look_cache()


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


# The round budget (presentation only, outcomes unchanged): past 5 s of a round's enemy time the rest of its turn speeds
# up smoothly, to 0.3 of the pace by 9 s. Stream B (806233f): the sector 3 excess is the enemy phase of 12 to 14 ships,
# so the 20-ship sector 3 fight's worst round comes down toward 12 s (was 8 s to 0.35 by 13 s: 14.3 s worst).
const BUDGET_FROM := 5.0
const BUDGET_FULL := 9.0
const BUDGET_FLOOR := 0.3


static func _round_budget_k(used: float) -> float:
	if used <= BUDGET_FROM:
		return 1.0
	return lerpf(1.0, BUDGET_FLOOR, clampf((used - BUDGET_FROM) / (BUDGET_FULL - BUDGET_FROM), 0.0, 1.0))


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
var _deaths_left := 0         # issue 1238: death events still to play in this batch, so several kills overlap


func _play_batch(bt: Dictionary) -> void:
	var evs: Array = bt["events"]
	var enemy := false
	dying.clear()
	_deaths_left = 0
	var wings := {}
	for e in evs:
		if e["t"] == "activation" and e["side"] == "enemy":
			enemy = true
		if e["t"] == "death" and e.get("unit") != null:
			dying[str(e["unit"])] = true
			_deaths_left += 1
		if e["t"] == "wing":
			wings[str(e["unit"])] = true
	# F1: reinforcements are ships that appear in the next view without a launch (the rules' mid-battle event, R42's
	# Nemesis reinforcements): they get a banner, a camera nudge and a pulse when their round begins
	var arrivals: Array = []
	if not VU.is_empty() and not showcase:
		for u in (bt["view"] as Dictionary).get("units", []):
			if not VU.has(u["id"]) and not views.has(u["id"]) and not u["squadron"] and not wings.has(str(u["id"])) and not u["dead"]:
				arrivals.append(u)
	speed = user_speed
	var t_batch := game_t
	if enemy and not bot and not showcase and _player_pending() == 0 and tail_round != int(V.get("round", 0)):
		# F1: every one of your ships has acted and the enemy plays out the rest of the round: say so once, big
		tail_round = int(V.get("round", 0))
		hud.banner("Enemy turn", Color("#c4a4ff"), 0.8)
	if enemy:
		speed = minf(speed, float(PACE["skip"]) if skip else (float(PACE["enemy"]) if _player_pending() > 0 else float(PACE["tail"])) * _enemy_pace_k())
	var base_speed := speed
	var i := 0
	var pre := {}   # F1: event indexes already played (your wings' moves, flown together)
	while i < evs.size():
		var e: Dictionary = evs[i]
		if pre.has(i):
			i += 1
			continue
		if e["t"] == "activation" and str(e.get("side", "")) == "player" and _is_wing(e["unit"]) and not args.has("wings-apart"):
			await _wings_together(evs, i, pre)
		if e["t"] == "fire":
			var j := volley_end(evs, i)
			var grp: Array = evs.slice(i + 1, j)
			var tf := game_t
			# issue 1448 (Artoo): a volley's hits are grouped here and never reach _play_event, so they are counted for the
			# music now, in batch order, before any delayed impact can land after the next round's reset
			for g in grp:
				if g["t"] == "hit":
					music_hits += 1
			_voice_event(e)
			for g in grp:
				_voice_event(g)
			await _play_fire(e, grp)
			_tip_completed(e)
			if enemy:
				pace_kind["fire"] = float(pace_kind.get("fire", 0.0)) + game_t - tf
				speed = base_speed * _round_budget_k(float(pace_enemy.get(int(V.get("round", 0)), 0.0)) + game_t - t_batch - float(move_s_round.get(int(V.get("round", 0)), 0.0)))
				if skip:
					speed = minf(speed, float(PACE["skip"]))
			i = j
			continue
		var te := game_t
		if e["t"] == "move":
			# issue 1581: a Burn and fire (the move, then its volley) hands the volley's target to the move, so the guns
			# turn while the hull brakes
			for j2 in range(i + 1, evs.size()):
				var e2: Dictionary = evs[j2]
				if e2["t"] in ["move", "activation", "undo", "round"]:
					break
				if e2["t"] == "fire" and str(e2.get("unit", "")) == str(e["unit"]):
					move_aim[str(e["unit"])] = {"target": str(e2["target"]), "slot": int(e2["weapon"]) if e2.get("weapon") != null else -1,
						"wid": str(e2.get("weapon_id", "")), "n": maxi((e2.get("shots", []) as Array).size(), 1)}
					break
		await _play_event(e, bt["view"])
		_tip_completed(e)
		if e["t"] == "round" and not arrivals.is_empty():
			await _arrive(arrivals)
			arrivals = []
		if enemy:
			pace_kind[str(e["t"])] = float(pace_kind.get(str(e["t"]), 0.0)) + game_t - te
			speed = base_speed * _round_budget_k(float(pace_enemy.get(int(V.get("round", 0)), 0.0)) + game_t - t_batch - float(move_s_round.get(int(V.get("round", 0)), 0.0)))
		if skip and enemy:
			speed = minf(speed, float(PACE["skip"]))
		i += 1
	if not arrivals.is_empty():
		await _arrive(arrivals)
	if enemy:
		tip_enemy_done = true
		var ta := game_t
		await wait(float(PACE["aiEnd"]))
		pace_kind["aiEnd"] = float(pace_kind.get("aiEnd", 0.0)) + game_t - ta
		if not cam_saved.is_empty():
			cam.t = cam_saved["t"]
			cam_saved = {}
		hud.set_chip("")
		if skip:
			plog.hurries += 1
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
		return (views[id] as ShipView).visual_position()
	return Vector3.ZERO


func _name(id) -> String:
	return str(VU[id]["name"]) if VU.has(id) else "?"


# issue 1524: the ship a "command" event pulses: the unit it names (an enemy boss), else that side's living flagship.
# The player's flagship is the rules' pflag (the run's flagUid; the view's "flagship" marks enemy objectives and bosses),
# read through api.unit (no rules state is written); a view flagship of that side stands in when none is flagged.
func _command_ship(e: Dictionary) -> String:
	if e.get("unit") != null and VU.has(e["unit"]):
		return str(e["unit"])
	var side := str(e.get("side", ""))
	var spare := ""
	for id in VU:
		var u: Dictionary = VU[id]
		if str(u.get("side", "")) != side or bool(u.get("dead", false)) or bool(u.get("squadron", false)):
			continue
		var ru = api.unit(str(id)) if api != null and api.has_method("unit") else null
		if ru is Dictionary and _jt(ru.get("pflag")):
			return str(id)
		if spare == "" and bool(u.get("flagship", false)):
			spare = str(id)
	return spare


func _side(id) -> String:
	return str(VU[id]["side"]) if VU.has(id) else "enemy"


func _who(id) -> String:
	return "p" if _side(id) == "player" else "e"


var voice = null   # story hook: godot/story/battle_voice.gd (null when the story folder is missing)


# story hook: every rules event reaches battle voice exactly once, including a volley's fire and its grouped hits,
# which _play_batch plays through _play_fire and never hands to _play_event (Artoo on PR 1552, issue 1551)
func _voice_event(e: Dictionary) -> void:
	if voice == null:
		return
	for l in voice.on_event(e):
		hud.add_log(l["text"], l["kind"])
		recording_cue.emit("voice", l["text"])


func _play_event(e: Dictionary, batch_view := {}) -> void:
	_voice_event(e)
	match e["t"]:
		"adaptation":
			if not adaptation_heard:
				adaptation_heard = true
				sfx.play("adapt_shift")
		"round":
			music_hits = 0
			_log("Round %d." % int(e["round"]), "x")
			if finale_fight and world != null and world.has_method("finale_for_round"):
				world.finale_for_round(int(e["round"]))   # R78 Q18: one more sector catches the new sun
			if not bot and not showcase:
				hud.set_phase("", "")
			fired_in_act.clear()
			if int(e["round"]) > 1 or not bot:
				sfx.turn("round")
				hud.banner("Round %d" % int(e["round"]))
				await wait(float(PACE["banner"]) + 140.0)
		"regen_unlock":
			if disp.has(e["unit"]):
				disp[e["unit"]]["regenLock"] = false
				regen_unlocks[e["unit"]] = int(regen_unlocks.get(e["unit"], 0)) + 1
		"log":
			hud.add_log(str(e.get("text", "")), str(e.get("kind", "")) if e.get("kind") != null else "")
		"float":
			# rules.gd flt(): the boon and lineage callout over a ship (issue #305)
			var dyv = e.get("dy")
			_float(e.get("unit"), str(e.get("text", "")), Color(str(e.get("color", "#d0a64b"))), float(dyv) if dyv != null else 0.0)
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
		"risen":
			_reassemble(e, batch_view)
			_float(e["unit"], "Risen", Color("#ddc4ff"), -30)   # only Eclipse ships rise (legionCan); Eclipse violet, never green (issue 1641)
			await wait(600.0)
		"stance":
			_float(e["unit"], "Wings: %s" % str(e["stance"]), Color("#9fd4ff"), -24)
		"blink":
			var sv = views.get(e["unit"])
			if sv != null:
				var c: Color = FLOOK.engine(str(VU.get(e["unit"], {}).get("fac", "ithar")))
				_flash(sv.visual_position() + Vector3(0, 2, 0), 18.0, c, 0.5)
				sfx.play("phase", {"pos": sv.visual_position()})
				await wait(250.0)
				sv.position = board.hex_world(int(e["to"]["q"]), int(e["to"]["r"]))
				_flash(sv.visual_position() + Vector3(0, 2, 0), 18.0, c, 0.5)
				await wait(250.0)
		"side":
			if e["side"] == "player":
				hud.set_chip("")
			elif not bot and not showcase:
				_enemy_phase("")
		"activation":
			fired_in_act.erase(e["unit"])
			if e["side"] == "enemy":
				if not bot and not showcase:
					_enemy_phase(str(e["unit"]))
				if views.has(e["unit"]):
					for sv in views.values():
						sv.set_selected(false)
					views[e["unit"]].set_selected(true, Color(0.79, 0.64, 1.0))
					# follow activations (the browser's G.follow): ease the camera toward the acting enemy, back after
					if follow and not bot:
						if cam_saved.is_empty():
							cam_saved = {"t": cam.t, "r": cam.r}
						cam.t = cam.t.lerp(_pos(e["unit"]), 0.6)
				await wait(float(PACE["aiGap"]))
		"move":
			await _play_move(e["unit"], e["path"], false)
		"undo":
			# issue 1450: the ship's last move or turn was taken back; it stands at once on the hex and facing the rules give
			# (no burn back along the path), and the reach overlay is rebuilt from there on the next refresh
			if views.has(e["unit"]) and not views[e["unit"]].dead:
				views[e["unit"]].snap_to(board.hex_world(int(e["q"]), int(e["r"])), ShipView.yaw_of(int(e["f"])))
			reach_map.clear()
		"pulled":
			await _play_move(e["unit"], [{"q": e["to"]["q"], "r": e["to"]["r"], "f": VU[e["unit"]]["facing"] if VU.has(e["unit"]) else 0}], false)
			_float(e["unit"], "Pulled in", Color("#c79bff"))
		"hit":
			_apply_hit(e)
			music_hits += 1
			if e.get("target") != null:
				_impact(e["target"], e, Color(1, 0.6, 0.3))
				if e.get("float", true):   # issue 1481: counter-fire, ram shockwave and reactor hits already float their boon number
					_float_hit(e["target"], float(e["shield"]), float(e["hull"]), e["crit"])
			await wait(160.0)
		"shield_down":
			var d: Dictionary = disp.get(e["unit"], {})
			if d.get("sh") is Array:
				for qi in range((d["sh"] as Array).size()):
					d["sh"][qi] = 0   # R246: an empty pool drops every side at once (issue 1481)
			_float(e["unit"], "Shields down", Color("#9fe2ff"), -40)
			sfx.shield(_pos(e["unit"]), true)
			# issue 1239 (F2.5): a shield that drops with no volley to carry it (a storm, a special) still plays its failure
			if gfx != null and gfx.has_method("shield_break"):
				gfx.shield_break(str(e["unit"]), int(e["quad"]))
		"section_down":
			var sec := str(e["section"])
			_log("%s: %s destroyed. %s" % [_name(e["unit"]), SEC_NAME.get(sec, sec), "Forward weapons silenced." if sec == "prow" else "Flank guns and shield generator gone." if sec == "mid" else "Engines crippled."], "e" if _side(e["unit"]) == "player" else "p")
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
			if e["kind"] == "storm" and views.has(e["unit"]):
				storm_drained.emit(_pos(e["unit"]))
			if gfx != null and gfx.has_method("tick"):
				gfx.tick(str(e["unit"]), str(e["kind"]))
			await wait(120.0)
		"ability":
			var ab := str(e["ab"])
			var A = TBL.get("ABILITIES", {}).get(ab, {})
			if ab != "launch":
				_log("%s: %s." % [_name(e["unit"]), str(A.get("n", ab))], _who(e["unit"]))
			var c: Color = FLOOK.engine(str(VU.get(e["unit"], {}).get("fac", "hegemony")))
			if gfx != null and gfx.has_method("ability"):
				gfx.ability(str(e["unit"]), ab)
			else:
				_flash(_pos(e["unit"]) + Vector3(0, 2, 0), 18.0, c, 0.5)
			if ab == "blink" and e.get("hex") != null:
				sfx.play("phase", {"pos": _pos(e["unit"])})
				var sv = views.get(e["unit"])
				if sv != null:
					sv.position = board.hex_world(e["hex"]["q"], e["hex"]["r"])
					_flash(sv.visual_position() + Vector3(0, 2, 0), 18.0, c, 0.5)
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
				sfx.play("brace_lock", {"pos": _pos(e["unit"])})
				_float(e["unit"], "Braced", Color("#9fd4ff"), -24)
			await wait(200.0)
		"ram":
			await _play_move(e["unit"], e["path"], true)
			sfx.boom(0.8, _pos(e["target"]))
			# issue 1524 (fx/API.md 11): the approved ram look: the crumple on the target's struck section, a smaller one on
			# the rammer's bow, the biggest shove and the zoom punch. The generic pop stays only when the fx layer drew nothing.
			var rammed := false
			if gfx != null and gfx.has_method("volley"):
				var rr: Dictionary = gfx.volley(str(e["unit"]), "torp", str(e["target"]), {"weapon_id": "ram", "shots": [true],
					"hits": [{"shield": 0, "hull": int(e["dmg"]), "section": str(e["section"]), "crit": false}]})
				rammed = not (rr.get("impacts", []) as Array).is_empty()
			if not rammed:
				_flash(_pos(e["target"]) + Vector3(0, 2, 0), 30.0, Color(1, 0.7, 0.4), 0.6)
			_log("%s rams %s at full speed: %d to its %s, %d back to the ram." % [_name(e["unit"]), _name(e["target"]), int(e["dmg"]), SEC_NAME.get(str(e["section"]), str(e["section"])), int(e["recoil"])], _who(e["unit"]))
			var d: Dictionary = disp.get(e["target"], {})
			if d.has("hp"):
				d["hp"] = float(d["hp"]) - float(e["dmg"])
			if e.get("sh") is Array and d.has("sh"):
				d["sh"] = (e["sh"] as Array).duplicate()   # issue 1481: the ram's soak shows on the shield readout too
			var d2: Dictionary = disp.get(e["unit"], {})
			if d2.has("hp"):
				d2["hp"] = float(d2["hp"]) - float(e["recoil"])
			await wait(500.0)
		"board":
			sfx.play("board_grapple", {"pos": _pos(e["target"]), "variant": str(VU.get(e["unit"], {}).get("fac", ""))})
			var res := str(e["result"])
			var who := _who(e["unit"])
			if res == "capture":
				_log("Boarding parties from %s take %s. It now fights for %s." % [_name(e["unit"]), _name(e["target"]), "you" if _side(e["unit"]) == "player" else "the enemy"], who)
				_float(e["target"], "Captured", Color("#ffb23e"), -30)
			elif res == "overrun":
				_log("%s's boarders overrun %s, but the last of its crew hold the bridge." % [_name(e["unit"]), _name(e["target"])], who)
			elif res == "scuttle":   # R383 (issue 1479): the Nemesis flagship, a hunt target or a convoy transport is destroyed, never captured
				_log("Boarding parties from %s overrun %s and scuttle it." % [_name(e["unit"]), _name(e["target"])], who)
			else:
				_log("%s boards %s: %d defenders killed, %d boarders lost." % [_name(e["unit"]), _name(e["target"]), int(e["kill"]), int(e["loss"])], who)
			# issue 1524 (fx/API.md 11): the approved boarding breach (pried hatch, venting gas, light from inside, then a
			# dark gash); the generic pop stays only when the fx layer found no boarding point to draw it at
			var boarded := 0.0
			# issue 1581 item 4: the boarding ship trims its height toward the target's hull before the breach, and
			# eases back after it (a look only; the rules' hexes are unchanged)
			var bsv = views.get(e["unit"])
			var btv = views.get(e["target"])
			if bsv != null and btv != null and not bsv.dead and not reduce_motion:
				bsv.elev_target = clampf(float(btv.hull_lift) - float(bsv.hull_lift), -4.0, 4.0)
				if absf(float(bsv.elev_target)) > 0.2:
					await wait(450.0)
			if gfx != null and gfx.has_method("board"):
				boarded = float(gfx.board(str(e["unit"]), str(e["target"]), res, speed))
			if boarded <= 0.0:
				_flash(_pos(e["target"]) + Vector3(0, 2, 0), 14.0, Color(1, 0.8, 0.5), 0.5)
			# issue 1547: hold on the breach long enough to read it before the next event (the enemy turn)
			await wait(float(gfx.board_hold_ms()) if boarded > 0.0 and gfx.has_method("board_hold_ms") else 600.0)
			if bsv != null and is_instance_valid(bsv):
				bsv.elev_target = 0.0
		"command_warning":
			var C = _command(str(e["id"]))
			_log("%s is preparing %s. It strikes next round." % [_name(e["unit"]), str(C.get("n", e["id"]))], "e")
			hud.banner("%s next round" % str(C.get("n", e["id"])), Color("#ff8a6a"))
			sfx.play("ui_alert")
			await wait(float(PACE["banner"]) + 140.0)
		"command":
			var C = _command(str(e["id"]))
			_log("%s: %s!" % [_name(e["unit"]), str(C.get("n", e["id"]))], "e" if e["side"] == "enemy" else "p")
			hud.banner(str(C.get("n", e["id"])), Color("#ff8a6a") if e["side"] == "enemy" else Color("#ff8a3a"))
			# issue 1524 (fx/API.md 11): the flagship's command pulse under the banner
			# (the player's command names no unit: it pulses that side's living flagship)
			var cmd_ship := _command_ship(e)
			if cmd_ship != "" and gfx != null and gfx.has_method("command"):
				gfx.command(cmd_ship, str(e["id"]))
			await wait(float(PACE["banner"]) + 140.0)
		"wreck":
			# issue 1236: the wreck sits in the hex it blocks. Its death pieces are kept inside that hex from the start;
			# the board marks the hex once the death has played ("death" below).
			wrecked[e["unit"]] = Vector2i(int(e["q"]), int(e["r"]))
			if gfx != null and gfx.has_method("anchor_wreck"):
				gfx.anchor_wreck(str(e["unit"]), board.hex_world(int(e["q"]), int(e["r"])), board.HS * WRECK_LEASH_K)
			_log("The wreck of %s breaks into tumbling wreckage, blocking movement and line of fire." % _name(e["unit"]), "x")
		"death":
			await _play_death(e)
			if wrecked.has(e["unit"]):
				_lay_wreck(e["unit"])
		"fled":
			var sv = views.get(e["unit"])
			if gfx != null and gfx.has_method("jump_out"):
				gfx.jump_out(str(e["unit"]))
				if sv != null:
					sv.dead = true
					if sv.marker != null:
						sv.marker.visible = false
					sv.ring.visible = false
			elif sv != null:
				sv.flee()
			_log("%s leaves the battle." % _name(e["unit"]), "e" if _side(e["unit"]) == "player" else "s")
			await wait(300.0)
		"end":
			pass
		_:
			# Issue 359: an event kind with no branch above is logged once per kind instead of being dropped silently, so a
			# new rules event the screen does not draw shows up in the log and fails GitHub's bot battle check.
			# nem_signature is read by the story voice above and draws nothing here, so it is not reported.
			var kind := str(e["t"])
			var seen: Dictionary = get_meta("unknown_events", {})
			if kind != "nem_signature" and not seen.has(kind):
				seen[kind] = true
				set_meta("unknown_events", seen)
				push_warning("battle: unknown event kind \"%s\" (no branch in battle.gd _play_event)" % kind)


const WRECK_LEASH_K := 0.8      # issue 1236: a blocking wreck's pieces rest within this share of the hex radius
const WRECK_CHECK_S := 4.0      # seconds after a wreck's death plays: no pieces on the board by then lays the burnt hulk


# issue 1236: the board marks a wreck's hex, and lays the burnt hulk there if the death left nothing to see
func _lay_wreck(unit) -> void:
	var at: Vector2i = wrecked[unit]
	var id := str(unit)
	var fx_pieces: bool = gfx != null and gfx.has_method("wreck_pieces")
	board.add_wreck(id, at.x, at.y)
	if not fx_pieces:
		return   # no effects: the ship view keeps its own darkened hull in place (ShipView.die)
	var gen: int = board.built
	get_tree().create_timer(WRECK_CHECK_S).timeout.connect(func() -> void:
		if not is_instance_valid(board) or board.built != gen or board.wrecks.get(id, "") != board.key(at.x, at.y): return
		if gfx == null or int(gfx.wreck_pieces(id)) > 0: return
		board.add_wreck(id, at.x, at.y, true))


func _reassemble(e: Dictionary, batch_view: Dictionary) -> void:
	var id: String = str(e["unit"])
	var sv: ShipView = views.get(id)
	if sv == null:
		return
	# Use the batch view for ship identity, not for damage that has yet to play.
	var prior: Dictionary = VU.get(id, {})
	var ru := prior
	for unit in batch_view.get("units", []):
		if unit["id"] == id:
			ru = unit
			break
	if gfx != null and gfx.has_method("remove_ship"):
		gfx.clear_wreck(id)
		gfx.remove_ship(id)
	wrecked.erase(id)
	sv.revive()
	var yaw := ShipView.yaw_of(ru["facing"]) if ru.has("facing") else sv.cur_yaw
	sv.snap_to(board.hex_world(int(e["q"]), int(e["r"])), yaw)
	if not ru.is_empty():
		_register_fx_ship(ru, sv)
		# The rise restores hull and sections and clears fire. It leaves shields as they were;
		# the rest of the turn (including any tidal tick) has not happened in playback yet.
		var frac := float(TBL["LEGION_HP"])
		var hp := maxf(1.0, JSM.jsround(float(ru["maxHp"]) * frac))
		var sh: Array = disp.get(id, {}).get("sh", prior.get("sh", ru["sh"]))
		disp[id] = {"hp": hp, "sh": sh.duplicate()}
		if gfx != null and gfx.has_method("sync_ship"):
			var sec := {}
			if ru.get("sec") is Dictionary:
				for key in ru["sec"]:
					var cap := float(ru["sec"][key]["max"])
					sec[key] = {"hp": maxf(1.0, JSM.jsround(cap * frac)), "max": cap, "broken": false}
			gfx.sync_ship(id, {"hp": hp, "maxHp": ru["maxHp"], "sec": sec, "sh": sh, "burning": false})
	# issue 1460: the revival flash is the faction's own colour from fx/faction_looks.json (Eclipse is all violet, R372),
	# not the old lime green
	_flash(sv.visual_position() + Vector3(0, 2, 0), 16.0, FLOOK.engine(str(ru.get("fac", "deathless"))), 0.8)


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
	var t_move := game_t
	burns_live += 1
	if burns_live > 1 and args.has("move-trace"):
		print("[move] overlap: %s starts while %d other move(s) burn" % [str(id), burns_live - 1])
	# escort 0, battleship 1, and on past it at half the slope (issue 505: a dreadnought about 1.25, a titan or an ark up
	# to 1.4): speed, spin and ramps by size, so the biggest hulls are the slowest to start, turn and stop, while their
	# moves grow by about a second rather than two (the first strips' full slope made a dreadnought's move 40% longer)
	var sk := (size - 0.5) / 0.45
	sk = clampf(sk if sk <= 1.0 else 1.0 + (sk - 1.0) * 0.5, 0.0, MOVE_SK_MAX)
	var fk := pow(float(MOVE_PER.get(str(u.get("fac", "")), 1.0)), 0.35)   # a faction flavour, kept inside the ruled range
	# F2 (R64, Ryan Nov 1): about twice as slow, every ship at its own true pace on both sides; only Enter or Space (or the
	# Speed: fast setting) hurries a move. The old B2 timing stays behind --movement segments for before and after shots.
	var per := lerpf(MOVE_HEX[0], MOVE_HEX[1], sk) * fk * (MOVE_SQUAD if bool(u.get("squadron", false)) else 1.0)
	if cin:
		per *= _escort_k(sk, MOVE_ESCORT_PACE)
	var gsteps: Array = _glide_steps(sv, path, sk) if cin else []
	var mv_s := s
	if cin:
		mv_s = 0.0
		for g in gsteps:
			mv_s += float(g["w"])
	var dur := minf((per * maxf(mv_s, 0.001) + lerpf(MOVE_LEAD[0], MOVE_LEAD[1], sk)) * (0.72 if charge else 1.0), MOVE_CAP) / 1000.0
	var mv_speed := minf(user_speed, float(PACE["skip"])) if skip else user_speed
	if movement == "segments":
		per = (430.0 if size > 0.8 else 350.0 if size > 0.6 else 280.0) * float(MOVE_PER.get(str(u.get("fac", "")), 1.0))
		dur = minf((per * maxf(s, 0.001) + 260.0) * (0.72 if charge else 1.0) * float(PACE["move"]), 3600.0) / 1000.0
		mv_speed = speed
	sv.speed_k = 1.0
	if movement == "segments" and not bool(u.get("squadron", false)):
		sv.play_moves(_move_segments(sv, path, mass, args.has("flip-burn") and str(u.get("cls", "")) in FLIP_CLASSES), dur * mv_speed, {"mass": mass})
	elif cin:
		# the glide sets its own length from its physics at this pace (cruise MOVE_CRUISE of the hex time; ramps, corners
		# and spins add to it), capped
		# issue 521: a move flown only on thrusters (a one-hex slide, a straight back-off) is slower and gentler than a burn
		var jets_only: bool = not gsteps.is_empty() and bool((gsteps[-1] as Dictionary).get("thrusters", false))
		# issue 1581: the glide is told which moves are flown on thrusters (the drive stays cold) and which nose first (it
		# rests at each corner to turn); NF_POINT and NF_TRAIL, which overlapped the turns with the burn, are gone
		var gopts := {"mass": sk, "cap": MOVE_CAP / 1000.0 * mv_speed, "thrusters": jets_only,
			"nose_first": not gsteps.is_empty() and bool((gsteps[-1] as Dictionary).get("nose_first", false))}
		sv.calm = reduce_motion
		sv.play_glide(gsteps, per * MOVE_CRUISE * (_slide_pace(sk) if jets_only else 1.0) * (0.72 if charge else 1.0) * mv_speed / 1000.0, gopts)
		dur = sv.path_dur / maxf(mv_speed, 1e-3)
	else:
		sv.play_path(keys, yaws, alts, s, dur * mv_speed, {"mass": mass})
	if args.has("move-trace"):
		var n_rot := 0
		for st in path:
			n_rot += 1 if _jt(st.get("rot")) else 0
		print("[move] %s %s %s size %.2f hexes %d turns %d dur %.2f s, %.0f ms a hex, speed %.2f" % [str(id), _side(id), str(u.get("cls", "")), size, path.size() - n_rot, n_rot, dur * mv_speed, per * mv_speed, mv_speed])
	if size > 0.3:
		sfx.play("engine", {"pos": sv.visual_position(), "gain": minf(1.0, 0.55 + size * 0.6)})
	var eng_on: bool = gfx != null and gfx.has_method("set_engine")
	# issue 1581 item 5: Burn and fire. The guns that will fire when the hull settles start turning toward the target
	# while it brakes, so the opening volley leaves on the beat the hull stops (the fire still follows the move: RULEBOOK
	# 7.9, nothing moves after it fires)
	# OpenAI review F1/F3: the volley's own mounts and aim point, started at the last brake or earlier when the slowest of
	# those turrets needs more time than is left in the move, so they bear when the hull settles
	var pa: Dictionary = move_aim.get(str(id), {})
	move_aim.erase(str(id))
	var aimed: bool = pa.is_empty() or not cin or gfx == null or not gfx.has_method("pre_aim") or not sv.glide
	var xf_end := Transform3D.IDENTITY
	var aim_need := 0.0
	var aim_at := 1.0
	if not aimed:
		var fin: Array = sv._gl_pose(1.0)
		var par: Node3D = sv.get_parent_node_3d()
		xf_end = Transform3D(Basis(Vector3.UP, float(fin[1])), fin[0] as Vector3)
		if par != null:
			xf_end = par.global_transform * xf_end
		aim_need = float(gfx.pre_aim(str(id), str(pa["target"]), xf_end, int(pa["slot"]), str(pa["wid"]), int(pa["n"]), false))
		aim_at = _pre_aim_at(sv)
	while is_instance_valid(sv) and sv.burning() and not sv.dead:   # issue 1559 item 8: Fight again frees the old ships mid-move
		# seconds left in the move as it plays now (a hurried move runs faster)
		var left := (1.0 - float(sv.gl_p)) * float(sv.path_dur) * float(sv.speed_k)
		if not aimed and (float(sv.gl_p) >= aim_at or left <= aim_need + 0.25):
			aimed = true
			gfx.pre_aim(str(id), str(pa["target"]), xf_end, int(pa["slot"]), str(pa["wid"]), int(pa["n"]))
		if skip:
			sv.speed_k = float(PACE["skip"])
		if eng_on:
			# The main drive follows the forward push (issue 505: a burn to gain speed, a hot low glow while coasting;
			# G4 fx engine level: idle, 2 full burn)
			# issue 1581: a cold drive (a slide, a back-off, braking) is fed below fx_ship's trail threshold, so no bright
			# core or exhaust ribbon is laid while the thrusters do the work
			gfx.set_engine(str(id), (ENGINE_COLD if bool(sv.drive_cold) else _drive_level(float(sv.thrust))) if cin else clampf(1.0 + float(sv.thrust), 0.5, 2.2))
		if args.has("speed-trace"):   # the hull's speed (hexes a second), spin (degrees a second), drive and jets
			print("[speed] %s %.3f %.2f %.0f %.2f retro %.2f side %.2f aft %.2f turn %.2f" % [str(id), game_t - t_move, sv._vel.length() / board.HW, rad_to_deg(sv._yaw_v), float(sv.thrust), sv.jet_retro, sv.jet_side, sv.jet_aft, sv.jet_turn])
		if move_frames != "":
			await _snap("f")
		else:
			await get_tree().process_frame
	if not is_instance_valid(sv):
		return   # a new battle owns the board and the counters now
	if eng_on:
		gfx.set_engine(str(id), ENGINE_IDLE if cin else 1.0)
	burns_live -= 1
	if _side(id) == "enemy" and movement != "segments":
		move_s_round[int(V.get("round", 0))] = float(move_s_round.get(int(V.get("round", 0)), 0.0)) + game_t - t_move


# Cinematic moves as segments from rest to rest (ship_view.gd play_moves): consecutive turn steps make one turn about
# the centre; consecutive translation steps (ahead, sidestep, back off: the heading never changes in them) make one run.
# Weights share the move's time (the B2 pace is unchanged): a turn step weighs PACE.rot, a heavier hull spending a little
# more of its time on a turn; a run weighs its steps plus a little for its thrust-up and thrust-down.
const ENGINE_IDLE := 0.35     # the main drive at rest or coasting: a pilot glow, the full plume only when it pushes
const ENGINE_COLD := 0.06     # issue 1581: the drive in a flown move while it is off (under fx_ship's 0.12 trail threshold)


# issue 1581: an escort's pace factor k at size 0, easing to 1 at battleship size (the size scale sk)
func _escort_k(sk: float, k: float) -> float:
	return lerpf(k, 1.0, clampf(sk, 0.0, 1.0))


# issue 1581: a move flown on thrusters is this many times slower than a burn: 1.6 for an escort (a frigate's two-hex
# back-off about 25 to 19 units a second) to issue 521's 1.45 from battleship up
func _slide_pace(sk: float) -> float:
	return lerpf(SLIDE_PACE_ESCORT, SLIDE_PACE, clampf(sk, 0.0, 1.0))


# issue 1581: where in a flown move the guns of a Burn and fire start to turn: once the hull is braking for its last
# stop (from the speed profile: the last time it runs over half its cruise), or at 70 percent of the move when unclear
func _pre_aim_at(sv) -> float:
	var ds: PackedFloat32Array = sv.gl_ds
	if ds.size() < 3 or float(sv.gl_T) <= 0.0:
		return 0.7
	var hexd := float(sv.gl_hexd)
	for i in range(ds.size() - 2, -1, -1):
		if (ds[i + 1] - ds[i]) / float(sv.gl_dtg) > 0.5 * hexd:
			return clampf((float(sv.gl_tm0) + float(i) * float(sv.gl_dtg)) / float(sv.gl_T), 0.3, 0.95)
	return 0.7


# the battle's drive level for a flown move. fx_ship.gd reads a level within 0.05 of 1.0 as "moving, no level given"
# and jumps it to 1.6 (audit finding 14); a continuous level passes that band twice a move, so it steps over it.
func _drive_level(thrust: float) -> float:
	var l := lerpf(ENGINE_IDLE, 2.0, thrust)
	if absf(l - 1.0) <= 0.05:
		l = 0.94 if l < 1.0 else 1.06
	return l


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


# F2: the path as glide steps for ship_view.gd play_glide (one continuous motion): each turn step a target heading and
# its weight (a 60 degree turn weighs MOVE_ROT hexes, more for a bigger hull, so it spins slower), each translation step
# its hex (with the height of a climb over a rock or a dive under a ship) and a weight of one hex.
# Issue 521 (R195, Ryan: "engines should be clearly stronger and more used for movement than the thrusters... for one tile
# over, it tracks but not when they're going like 3-10 tiles down just almost skating on thrusters"): a move of more than
# one hex is flown nose first on the main engine (_nose_first), and only a one-hex slide stays on the side or retro jets.
# Presentation only: the hexes passed, the end hex and the final facing are the rules' own.
func _glide_steps(sv, path: Array, sk: float) -> Array:
	var out: Array = []
	var la: float = sv.cur_yaw
	for st in path:
		var a: float = la + angle_difference(la, ShipView.yaw_of(st["f"]))
		if _jt(st.get("rot")):
			out.append({"kind": "turn", "yaw": a, "w": _turn_w(la, a, sk)})
		else:
			var ov := float(st.get("over", 0)) if st.get("over") != null else 0.0
			var p: Vector3 = board.hex_world(st["q"], st["r"])
			p.y = _clearance(ov, sk, int(st["q"]), int(st["r"])) if ov != 0.0 else 0.0
			out.append({"kind": "move", "p": p, "w": 1.0, "slide": _jt(st.get("slip")) or _jt(st.get("rev"))})
		la = a
	var n_hex := 0
	for g in out:
		n_hex += 1 if g["kind"] == "move" else 0
	if n_hex <= 1:
		if n_hex == 1:
			for g in out:
				if g["kind"] == "move" and bool(g["slide"]):
					out[-1]["thrusters"] = true
		return out
	return _nose_first(out, sv.position, float(sv.cur_yaw), la, sk)


func _turn_w(a0: float, a1: float, sk: float) -> float:
	return lerpf(MOVE_ROT[0], MOVE_ROT[1], sk) * _escort_k(sk, MOVE_ESCORT_TURN) * maxf(absf(angle_difference(a0, a1)) / (PI / 3.0), 0.5)


# Issue 1581 item 4: the height a flown move passes over a rock (over > 0) or under an enemy hull (over < 0), scaled by
# both hulls: a frigate swoops low over a rock, a dreadnought heaves just clear of it with its bigger keel, and a dive
# goes deeper under a bigger ship. Was a flat 9 up and 7.5 down for every hull. Presentation only (the rules' "over").
func _clearance(ov: float, sk: float, q: int, r: int) -> float:
	var own := clampf(sk / 1.25, 0.0, 1.0)
	if ov > 0.0:
		return lerpf(7.5, 10.5, own)
	var other := 0.5
	for uu in V.get("units", []):
		if int(uu.get("q", -99)) == q and int(uu.get("r", -99)) == r and not bool(uu.get("dead", false)):
			other = clampf((float(uu.get("size", 0.5)) - 0.3) / 0.9, 0.0, 1.0)
	return -(lerpf(5.5, 8.0, own) + lerpf(0.0, 3.0, other))


# Issue 521 tuning values (judged by eye on the issue 521 strips; movement_spec.md section 1):
const LEG_TOL := 0.55        # hex centres within this share of a hex of a straight line fly as one leg (a zigzag of two
                             # hex directions is one straight diagonal run, not a heading change every hex)
const LEG_PULL := 0.85       # inside a leg the hull is drawn this share of the way onto the straight line, so it still
                             # passes inside every hex of the ruled route (issue 1581: was 0.6; the hull came within
                             # 0.3 hex of each centre and wove 0.2 hex about its line, a 23 degree skid off a held nose;
                             # now 0.43 from a centre, 0.08 off the line, and play_glide's _gl_crab follows the rest)
const ASTERN := 2.1          # radians: a run this far behind both the heading and the final facing is backed on retro jets
const SLIDE_PACE := 1.45     # a move flown only on thrusters (a one-hex slide, a straight back-off) takes this many times
                             # the burn's time per hex: visibly slower and gentler than the main engine (battleship up)
const SLIDE_PACE_ESCORT := 1.6   # issue 1581: an escort's thruster moves, slower still (see _slide_pace)
# (issue 1581: NF_POINT 0.75 and NF_TRAIL 0.7 overlapped a nose-first move's turns with its burn by up to 43 degrees and
# skidded the hull sideways, Nov 21 audit; play_glide now flies turn, burn, turn: GL_LEAD, GL_REST, GL_DWELL_NF)


# A move of two hexes or more as the ship would fly it: the route's hex centres are split into straight legs; the nose
# comes round onto each leg before the burn (a turn before the run, or at a corner), the main engine does the travelling,
# and the ship turns to the rules' final facing while it brakes (play_glide's trailing turn). A one-hex leg that the
# rules flew as a sidestep or back-off stays a slide on the heading of the leg before it (the dogleg drift); a run
# straight astern of both the heading and the final facing is backed on retro jets.
# Returns the glide steps; "thrusters" in the last step's dict says the whole move is flown on thrusters.
func _nose_first(rsteps: Array, p0: Vector3, yaw0: float, yaw_end: float, sk: float) -> Array:
	var pts: Array = [Vector3(p0.x, 0.0, p0.z)]
	var slide: Array = []
	for g in rsteps:
		if g["kind"] == "move":
			pts.append(g["p"])
			slide.append(bool(g.get("slide", false)))
	var flat: Array = []
	for q in pts:
		flat.append(Vector2((q as Vector3).x, (q as Vector3).z))
	var hexd := 0.0
	for i in flat.size() - 1:
		hexd += ((flat[i + 1] as Vector2) - (flat[i] as Vector2)).length()
	hexd = maxf(hexd / maxf(flat.size() - 1, 1), 1.0)
	var keep := {0: true, flat.size() - 1: true}
	_rdp(flat, 0, flat.size() - 1, LEG_TOL * hexd, keep)
	var idx: Array = keep.keys()
	idx.sort()
	var out: Array = []
	var h := yaw0
	var engine := false
	for li in idx.size() - 1:
		var i0 := int(idx[li])
		var i1 := int(idx[li + 1])
		var d: Vector2 = (flat[i1] as Vector2) - (flat[i0] as Vector2)
		var head := h
		if d.length() > 1e-3 and not (i1 - i0 == 1 and bool(slide[i0])):
			var tgt := atan2(-d.y, d.x)   # ShipView's yaw: the bow is (cos yaw, 0, -sin yaw)
			if not (absf(angle_difference(h, tgt)) > ASTERN and absf(angle_difference(yaw_end, tgt)) > ASTERN):
				head = h + angle_difference(h, tgt)
				engine = true
		if absf(angle_difference(h, head)) > 0.02:
			out.append({"kind": "turn", "yaw": head, "w": _turn_w(h, head, sk)})
		h = head
		var ln := d.normalized() if d.length() > 1e-3 else Vector2.ZERO
		for i in range(i0 + 1, i1 + 1):
			var q: Vector3 = pts[i]
			if i < i1:
				var rel: Vector2 = (flat[i] as Vector2) - (flat[i0] as Vector2)
				var on: Vector2 = (flat[i0] as Vector2) + ln * rel.dot(ln)
				var pulled: Vector2 = (flat[i] as Vector2).lerp(on, LEG_PULL)
				q = Vector3(pulled.x, q.y, pulled.y)
			out.append({"kind": "move", "p": q, "w": 1.0})
	if absf(angle_difference(h, yaw_end)) > 0.02:
		out.append({"kind": "turn", "yaw": h + angle_difference(h, yaw_end), "w": _turn_w(h, yaw_end, sk)})
	if not out.is_empty():
		out[-1]["thrusters"] = not engine
		out[-1]["nose_first"] = true
	return out


# Ramer-Douglas-Peucker: keep the points that stand more than tol off the straight line between kept points
func _rdp(flat: Array, i0: int, i1: int, tol: float, keep: Dictionary) -> void:
	if i1 - i0 < 2:
		return
	var a: Vector2 = flat[i0]
	var b: Vector2 = flat[i1]
	var ab := b - a
	var worst := -1.0
	var wi := -1
	for i in range(i0 + 1, i1):
		var p: Vector2 = flat[i]
		var dev := (p - a).length() if ab.length() < 1e-3 else absf(ab.cross(p - a)) / ab.length()
		if dev > worst:
			worst = dev
			wi = i
	if worst > tol:
		keep[wi] = true
		_rdp(flat, i0, wi, tol, keep)
		_rdp(flat, wi, i1, tol, keep)


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
	var wid := str(w.get("weapon_id", ""))
	var faction := str(u.get("fac", ""))
	if u.get("squadron", false):
		return "sq"
	match WEAPON_FX.look_of(k, wid, faction):
		"macro":
			if faction == "voidsworn":
				return "shell"
		"junk":
			return "tracer"
		"nlance":
			return "lance"
	if k == "flak":
		return "flak"
	if k == "torp":
		return "torp"
	if k == "lance":
		return "ion" if wid == "ion" else "lance"
	if k == "gauss":
		return "rail"
	if k == "bio":
		return "spine" if wid == "bioplasma" else "glob"
	return {"voidsworn": "las", "hegemony": "plasma", "corsair": "tracer", "chorus": "spine", "ithar": "needle", "deathless": "rail"}.get(faction, "shell")


# fx3d.js cineWants and cineFrame: a side-on shot of the big moments (lances, torpedoes and novas on bosses or a nearly
# dead target, capital volleys on them, kills of bigger ships), letterboxed, back to the board after
func _cine_wants(kind: String, a_id, t_id) -> bool:
	if cine == "off" or bot or (shots_dir != "" and not args.has("torp-cine")):   # --torp-cine: captures keep the cut-in (issue 1379)
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
	recording_cue.emit("cut_end", "")


func _play_fire(e: Dictionary, grp: Array) -> void:
	var a_id = e["unit"]
	var t_id = e["target"]
	var ckind := "lance" if str(e["kind"]) == "lance" else "torp" if str(e["kind"]) == "torp" else "volley"
	var cined := _cine_wants(ckind, a_id, t_id)
	if cined:
		_cine_frame(a_id, t_id)
		recording_cue.emit("cut_start", "%s: %s to %s" % [ckind, _name(a_id), _name(t_id)])
		await wait(320.0)
	var u: Dictionary = VU.get(a_id, {})
	var fac := str(u.get("fac", "hegemony"))
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
	var col: Color = FLOOK.weapon(fac)
	var tsv = views.get(t_id)
	var L: float = tsv.L if tsv != null else 10.0
	var shield_col: Color = FLOOK.shield(str(VU.get(t_id, {}).get("fac", "hegemony")))
	var total := 0.0
	var hi := 0
	# the browser's own length for this volley (fx3d.js timing), the cap for a paced wait
	var btot := (0.32 + n * 0.25 + 0.15) if fam in ["lance", "ion"] else ((0.32 + n * 0.12 + 0.84) if fam == "torp" else (n * 0.07 + 0.49))
	# issue 1211: what each landing hit does: its number, and the shield break with
	# "Shields down" on the hit that empties the shield (the last hit the shield absorbed), not after the volley
	var land := {"t_id": str(t_id), "numbers": true, "sh": 0.0, "hull": 0.0, "crit": false, "break_k": shield_break_hit(hits),
		"downs": [], "tsv": tsv, "L": L, "shield_col": shield_col, "left": hits.size(), "ended": false,
		"regen_unlocks": int(regen_unlocks.get(t_id, 0))}
	land["break_k"] = section_break_hit(grp, int(land["break_k"]))
	for g in grp:
		if g["t"] == "shield_down":
			land["downs"].append(g)
	_aim_on(a_id, t_id, land)
	if args.has("torp-shots") and fam == "torp":   # issue 1379 capture: the flight and the hit, close on the pair
		var tag := "r%s_%s" % [str(V.get("round", 1)), str(a_id)]
		print("TORP_FIRE %s weapon=%s shots=%d pd=%d" % [tag, str(e.get("kind", "")), (e.get("shots", []) as Array).size(), int(e.get("pd", 0))])
		if args.has("torp-ft"):
			# frame time through the whole salvo and its wake (Artoo on PR 1416), at the battle camera and with no
			# picture taken, so the reading is the game's own
			torp_ft = {"tag": tag, "until": game_t + 3.5, "ms": []}
		else:
			var launch := args.has("torp-launch")   # the launch itself: close on the firing ship, dense frames (a clip)
			torp_snapped += 1
			if args.has("torp-max") and torp_snapped > int(args["torp-max"]):   # --torp-max N: only the first N salvos
				launch = false
			if float(args.get("torp-cam", 34)) > 0.0:     # --torp-cam 0: the battle camera as the player has it
				cam.focus(from if launch else _pos(t_id).lerp(from, 0.35), float(args.get("torp-cam", 34)))
			if launch:
				var fdt := float(args.get("torp-dt", 0.05))
				for fi in int(1.8 / fdt):     # 0 to 1.8 s: hatch, push out, ignition, the turn and the run in
					_at_fx(fi * fdt, func() -> void: _snap("tl_%s_%03d" % [tag, fi]))
			elif not args.has("torp-max") or torp_snapped <= int(args["torp-max"]):
				for fi in 12:     # 0.5 to 2.7 s: launch, flight, hit or interception, and the wake cooling after it
					var at := 0.5 + fi * 0.2
					_at_fx(at, func() -> void: _snap("tp_%s_%02d" % [tag, fi]))
	if gfx != null and gfx.has_method("volley"):
		var hl: Array = []
		for h in hits:
			hl.append({"shield": h["shield"], "hull": h["hull"], "section": h.get("section", ""), "crit": h["crit"]})
		var r: Dictionary = gfx.volley(str(a_id), str(e["kind"]), str(t_id), {"weapon_id": str(e.get("weapon_id", "")), "slot": int(e["weapon"]) if e.get("weapon") != null else -1, "shots": shots, "hits": hl, "quad": int(e["quad"]), "pd": int(e.get("pd", 0)),
			"break_k": int(land["break_k"]) if not (land["downs"] as Array).is_empty() else -1})
		land["pts"] = r.get("hit_pts", [])   # issue 1239: each hit's shield point, so the failure aims at the breaking shot
		# issue 1211: lance and torpedo cues on the effect's own fire times, on the effect clock (they played at 0 before)
		var fires: Array = r.get("fires", [])
		land["fires"] = fires   # (the effect's own fire times, one per shot; the timing check reads them)
		var fire0 := float(fires.min()) if not fires.is_empty() else -1.0
		if fire0 >= 0.0:
			shot_at[str(a_id)] = float(gfx.now) + fire0   # issue 1581: the first muzzle of this volley, on the effect clock
		if fam in ["lance", "ion"]:
			if str(e.get("weapon_id", "")) == "nlance" and not fires.is_empty():
				sfx.lance(false, fac, from, -1.0, _at_fx, fires)
			elif str(e.get("weapon_id", "")) != "nlance":
				sfx.lance(fam == "ion", fac, from, fire0, _at_fx)
		elif fam == "torp":
			sfx.torp(fac, from, fire0, _at_fx)
		else:
			# issue 506: one gun cue per shot, on the fire times the fx layer used for its muzzle effects
			var style = null if fam == "sq" else fam if fam in ["spine", "glob", "plasma", "las", "tracer", "needle", "rail"] else "shell"
			for i in mini(fires.size(), n):
				sfx.gun(str(e["kind"]), fam == "sq", style, from, float(fires[i]))
		var imp: Array = r.get("impacts", [])
		var tfac := str(VU.get(t_id, {}).get("fac", ""))
		# issue 1211: the fx gives one arrival per SHOT (misses too); each hit lands on its own shot's arrival, on the
		# effect clock (hit pause slows it), with its sound, its HP drop, its number and any shield break it causes
		var arr := hit_arrivals(shots, imp, hits.size())
		for k in hits.size():
			var at: float = float(arr[k])
			var h: Dictionary = hits[k]
			var kk := k
			_at_fx(at, func() -> void:
				_land_hit(t_id, h, kk, land)
				if float(h["shield"]) > 0 and float(h["hull"]) <= 0:
					sfx.shield(_pos(t_id))
				else:
					sfx.impact(fam, tfac, _pos(t_id), bool(h["crit"]), _at_fx))
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
				_schedule_impact(t_id, hits[hi], dl + 0.05 * sp, L, shield_col, fam, hi, land)
				hi += 1
	elif fam == "torp":
		sfx.torp(fac, from)
		total = 0.32 + n * 0.12 + 0.84
		for i in n:
			var dl := (0.32 + i * 0.12) * sp
			fx.bolt(from, to, col, 0.8 * sp, dl, 2.2, not shots[i])
			if shots[i] and hi < hits.size():
				_schedule_impact(t_id, hits[hi], dl + 0.8 * sp, L, shield_col, fam, hi, land)
				hi += 1
	else:
		total = n * 0.07 + 0.49
		var style = null if fam == "sq" else fam if fam in ["spine", "glob", "plasma", "las", "tracer", "needle", "rail"] else "shell"
		for i in n:
			var dl := i * 0.07 * sp
			var off := Vector3(randf_range(-1, 1), randf_range(-0.3, 0.6), randf_range(-1, 1)) * 0.25 * float(VU.get(a_id, {}).get("size", 0.5)) * 10.0
			fx.bolt(from + off, to, col, 0.24 * sp, dl, 1.1 if fam != "rail" else 1.5, not shots[i])
			sfx.gun(str(e["kind"]), fam == "sq", style, from, dl)
			if shots[i] and hi < hits.size():
				_schedule_impact(t_id, hits[hi], dl + 0.24 * sp, L, shield_col, fam, hi, land)
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
		# (issue 1211: the numbers rose on each hit as it landed, _land_hit)
	if crits > 0:
		parts.append("%d criticals" % crits if crits > 1 else "critical")
	_log("%s fires %s at %s: %s.%s" % [_name(a_id), str(e["name"]), _name(t_id), ", ".join(parts), " " + sys_txt + "!" if sys_txt != "" else ""], _who(a_id))
	if hits.is_empty():
		_shield_downs(land)   # (a break with no hit to carry it: as before, at the end)
	for g in grp:
		if g["t"] == "burning":
			_float(g["unit"], "Fire on deck", Color("#f08a4b"), -24)
		elif g["t"] == "log":
			hud.add_log(str(g.get("text", "")), str(g.get("kind", "")) if g.get("kind") != null else "")
		elif g["t"] == "float":
			var gdy = g.get("dy")
			_float(g.get("unit"), str(g.get("text", "")), Color(str(g.get("color", "#d0a64b"))), float(gdy) if gdy != null else 0.0)
		elif g["t"] == "section_down":   # issue 1481 review: the section loss rides in its volley now, so its log line plays here
			var sec := str(g["section"])
			_log("%s: %s destroyed. %s" % [_name(g["unit"]), SEC_NAME.get(sec, sec), "Forward weapons silenced." if sec == "prow" else "Flank guns and shield generator gone." if sec == "mid" else "Engines crippled."], "e" if _side(g["unit"]) == "player" else "p")
	await wait(80.0)
	if cined:
		await wait(900.0)
		_cine_release()
	# the marker stays until the volley is over and its last hit has landed (a paced volley lets go before its tail)
	land["ended"] = true
	if int(land["left"]) <= 0:
		_aim_off(land)


# Issue 1211: the arrival time of each hit. The fx returns one time per shot, misses included; the k-th hit rides the
# k-th shot that hit. A hit with no shot of its own (more hits than true shots) takes the last arrival, or 0.3 s.
static func hit_arrivals(shots: Array, impacts: Array, n_hits: int) -> Array:
	var out: Array = []
	for i in shots.size():
		if bool(shots[i]) and out.size() < n_hits:
			out.append(float(impacts[i]) if i < impacts.size() else 0.3)
	while out.size() < n_hits:
		out.append(float(out[-1]) if not out.is_empty() else 0.3)
	return out


# Issue 1211: the hit that empties the shield. The rules drain one pool (R246) hit by hit, so once it is empty no later
# hit is absorbed: the last hit with shield damage is the one that broke it (the last hit when none was absorbed).
# Issue 1481 review: a generator lost mid-volley (section_down, then shield_down, then more hits) breaks the shield on
# the hit that destroyed it, not on the last hit the shield absorbed. Otherwise the usual pick stands.
# Issue 1481 review: the notes a mid-volley section loss sends between two hits (its callout over the target, its log line)
# The volley a fire event at i carries: its hits, systems, fires, section losses and breaks on the target, and the notes a
# section loss sends between two of its hits (issue 1481 review: so the later hits keep their own impacts). Returns the
# index after the last one.
static func volley_end(evs: Array, i: int) -> int:
	var tgt := str(evs[i]["target"])
	var j := i + 1
	while j < evs.size():
		if evs[j]["t"] in ["hit", "system", "shield_down", "burning", "section_down"] and str(evs[j].get("target", evs[j].get("unit"))) == tgt:
			j += 1
			continue
		var k := j
		while k < evs.size() and volley_note(evs[k], tgt):
			k += 1
		if k > j and k < evs.size() and evs[k]["t"] in ["hit", "shield_down"] and str(evs[k].get("target", evs[k].get("unit"))) == tgt:
			j = k
			continue
		break
	return j


static func volley_note(g: Dictionary, target) -> bool:
	return g["t"] == "log" or (g["t"] == "float" and str(g.get("unit")) == str(target))


static func section_break_hit(grp: Array, k: int) -> int:
	var seen := 0
	for i in grp.size():
		var g: Dictionary = grp[i]
		if g["t"] == "hit":
			seen += 1
		elif g["t"] == "section_down" and str(g.get("section")) == "mid" and seen > 0 and i + 1 < grp.size() \
				and grp[i + 1]["t"] == "shield_down" and str(grp[i + 1].get("unit")) == str(g.get("unit")):
			return seen - 1   # only the break the generator loss itself sent (Artoo at 458f09e8: a prow or engine loss is not one)
	return k


static func shield_break_hit(hits: Array) -> int:
	var k := hits.size() - 1
	for i in hits.size():
		if float(hits[i]["shield"]) > 0:
			k = i
	return k


# Issue 1211: run f after `at` seconds of the effect clock (the clock the impacts were planned on, which hit pause and
# the kill beat slow); the scene timer when the G4 effects are not in the build.
func _torp_ft_step(dt: float) -> void:
	var ms: Array = torp_ft["ms"]
	ms.append(dt * 1000.0)
	if game_t < float(torp_ft["until"]):
		return
	var sorted := ms.duplicate(); sorted.sort()
	var total := 0.0
	for x in sorted: total += float(x)
	var n := sorted.size()
	var rep := {"tag": torp_ft["tag"], "frames": n, "mean_ms": total / maxf(n, 1), "p95_ms": sorted[int(n * 0.95)] if n > 0 else 0.0,
		"max_ms": sorted.back() if n > 0 else 0.0, "over_16_7": sorted.filter(func(x): return x > 1000.0 / 60.0).size(),
		"fps_cap": Engine.max_fps, "vsync": DisplayServer.window_get_vsync_mode()}
	print("TORP_FT %s" % JSON.stringify(rep))
	if not shots_dir.is_empty():
		var f := FileAccess.open(shots_dir.path_join("ft_%s.json" % torp_ft["tag"]), FileAccess.WRITE)
		if f != null: f.store_string(JSON.stringify(rep, "  "))
	torp_ft = {}


func _at_fx(at: float, f: Callable) -> void:
	if gfx != null and gfx.has_method("later"):
		gfx.later(float(gfx.now) + maxf(at, 0.0), f)
	else:
		get_tree().create_timer(maxf(at, 0.001)).timeout.connect(f)


# Issue 1211: one hit lands. Its HP and shield drop, its number rises (one running total per volley for shield, one for
# hull, so a broadside reads as a count, not a pile), and the hit that empties the shield breaks it there and then.
func _land_hit(t_id, h: Dictionary, k: int, land: Dictionary) -> void:
	_apply_hit(h, int(land["regen_unlocks"]) == int(regen_unlocks.get(t_id, 0)))
	land["left"] = int(land.get("left", 0)) - 1
	if bool(land.get("ended", false)) and int(land["left"]) <= 0:
		_aim_off(land)
	if bool(land["numbers"]) and views.has(t_id):
		land["sh"] = float(land["sh"]) + float(h["shield"])
		land["hull"] = float(land["hull"]) + float(h["hull"])
		if float(h["shield"]) > 0:
			land["sh_f"] = _float_tally(land.get("sh_f"), t_id, _shield_text(land), Color("#92b8e8"), FLOAT_LANE_SHIELD)
		if bool(h["crit"]):
			land["crit"] = true
		if float(h["hull"]) > 0 or bool(h["crit"]):
			# one hull label per volley: a critical reads in it ("Critical −8 hull"); a critical the armour absorbed shows
			# "Critical" there, and a later hull hit rewrites that same label (Artoo, PR 1256: never two critical labels)
			var txt := "−%d hull" % int(land["hull"]) if float(land["hull"]) > 0 else ""
			if bool(land["crit"]):
				txt = ("Critical " + txt).strip_edges()
			land["hull_f"] = _float_tally(land.get("hull_f"), t_id, txt, Color("#ffd27a") if bool(land["crit"]) else Color("#ffad3b"), 0)
	if k == int(land["break_k"]):
		_shield_downs(land)


# A float that counts: the first hit makes it, later hits rewrite it and keep it up a little longer.
func _float_tally(f, id, text: String, col: Color, dy: float):
	if f is Dictionary and is_instance_valid((f as Dictionary)["lbl"]) and not ((f as Dictionary)["lbl"] as Node).is_queued_for_deletion():
		var lbl: Label = f["lbl"]
		lbl.text = text
		lbl.add_theme_color_override("font_color", hud.col_of(col))
		lbl.reset_size()
		f["end"] = maxf(float(f.get("end", 1.6)), float(f["t"]) + 1.2)
		return f
	_float(id, text, col, dy)
	return floats[-1] if not floats.is_empty() else null


func _shield_text(land: Dictionary) -> String:
	return ("Shields down\n−%d shield" if bool(land.get("broke", false)) else "−%d shield") % int(land["sh"])


# The volley's shield breaks (each shield_down event once): the shield shatters, "Shields down" and the break sound.
func _shield_downs(land: Dictionary) -> void:
	if bool(land.get("downs_played", false)):
		return
	land["downs_played"] = true
	for g in land["downs"]:
		var d: Dictionary = disp.get(g["unit"], {})
		if d.get("sh") is Array:
			for qi in range((d["sh"] as Array).size()):
				d["sh"][qi] = 0   # R246: an empty pool drops every side at once (issue 1481)
		var sf = land.get("sh_f")
		if str(g["unit"]) == str(land.get("t_id", "")) and sf is Dictionary and is_instance_valid((sf as Dictionary)["lbl"]):
			# one label, two lines: "Shields down" over the volley's shield count, never a second label on top of it
			land["broke"] = true
			land["sh_f"] = _float_tally(sf, g["unit"], _shield_text(land), Color("#9fe2ff"), FLOAT_LANE_SHIELD)
		else:
			_float(g["unit"], "Shields down", Color("#9fe2ff"), FLOAT_LANE_SHIELD)
		sfx.shield(_pos(g["unit"]), true)
		if gfx != null and gfx.has_method("shield_break"):
			# issue 1239 (F2.1): the failure closes where the breaking shot struck (the quadrant's middle without one)
			var pts: Array = land.get("pts", [])
			var bk := int(land["break_k"])
			var lp: Vector3 = pts[bk] if str(g["unit"]) == str(land.get("t_id", "")) and bk >= 0 and bk < pts.size() else Vector3.INF
			gfx.shield_break(str(g["unit"]), int(g["quad"]), lp)
		elif land["tsv"] != null:
			fx.shield(land["tsv"], float(land["L"]), int(g["quad"]), land["shield_col"], 0.0, true)


# Issue 1211: who is being shot. For every enemy volley the target gets the danger ring (the shared ship ring) and keeps
# its name, also through a cut-in; the attacker keeps its purple activation ring. Cleared when the volley ends.
func _aim_on(a_id, t_id, land: Dictionary) -> void:
	if str(VU.get(a_id, {}).get("side", "")) != "enemy" or bot or showcase or str(a_id) == str(t_id):
		return
	if not aim.is_empty():
		_aim_off(aim["land"])   # the last volley's tail is still landing: it lets go now
	aim = {"a": str(a_id), "t": str(t_id), "land": land}
	if views.has(t_id):
		views[t_id].set_selected(true, AIM_RING)


# Only the volley that set the marker clears it (an earlier volley's late hit on the same ship leaves it alone).
func _aim_off(land: Dictionary) -> void:
	if aim.is_empty() or not is_same(aim.get("land"), land):
		return
	var t_id = aim["t"]
	aim = {}
	if views.has(t_id):
		views[t_id].set_selected(str(t_id) == sel and api != null and api.phase == "player", EMBER_3D)




func _schedule_impact(t_id, h: Dictionary, delay: float, L: float, shield_col: Color, fam: String, k := -1, land := {}) -> void:
	var tfac := str(VU.get(t_id, {}).get("fac", ""))
	get_tree().create_timer(maxf(delay, 0.001)).timeout.connect(func() -> void:
		if land.is_empty():
			_apply_hit(h)
		else:
			_land_hit(t_id, h, k, land)
		var sv = views.get(t_id)
		if sv == null:
			return
		var p: Vector3 = sv.visual_position() + Vector3(randf_range(-0.3, 0.3) * L, 1.0, randf_range(-0.12, 0.12) * L)
		if float(h["shield"]) > 0 and float(h["hull"]) <= 0:
			fx.shield(sv, L, int(h["quad"]), shield_col)
			_flash(p, 4.0 + L * 0.25, shield_col, 0.25, 0.0, false)
			sfx.shield(p)
		else:
			_flash(p, 5.0 + L * 0.3 + (8.0 if fam == "torp" else 0.0), Color(1.0, 0.62, 0.3), 0.3)
			if fam == "torp":
				sfx.boom(0.8, p)
			else:
				sfx.impact(fam, tfac, p, bool(h["crit"]), _at_fx))


func _apply_hit(h: Dictionary, show_regen_lock := true) -> void:
	var t_id = h.get("target")
	if t_id == null or not disp.has(t_id):
		return
	var d: Dictionary = disp[t_id]
	if show_regen_lock and bool(h.get("regenLock", false)):
		d["regenLock"] = true
	d["hp"] = maxf(0.0, float(d["hp"]) - float(h["hull"]))
	var q := int(h.get("quad", 0))
	if d["sh"] is Array and q < (d["sh"] as Array).size():
		d["sh"][q] = maxf(0.0, float(d["sh"][q]) - float(h["shield"]))


func _impact(t_id, h: Dictionary, col: Color) -> void:
	var sv = views.get(t_id)
	if sv == null:
		return
	_flash(sv.visual_position() + Vector3(0, 1.5, 0), 6.0 + sv.L * 0.3, col, 0.3)
	sfx.hit(sv.visual_position(), h.get("crit", false))


# Issue 521 (audit item 7; R193, Ryan's pick "Hold and slow", which replaces the Board's R123): the cut-in for a kill
# holds until just after the actual core flash and the slow-motion beat plays
# at the flash (fx.gd kill_slowmo, R73). A key or a click lets both go; under reduce motion the beat is off and the hold
# ends just after the flash. Hurried (Enter or Space) or with no core flash, the old 1.6 s at the battle's pace stays.
const KILL_AFTER := 0.35      # seconds the cut-in stays on the wreck after the flash (and after the beat, when it plays)
var move_aim := {}            # issue 1581: unit id -> its next volley's target, slot, weapon id and shots (Burn and fire)
var shot_at := {}             # issue 1581: unit id -> effect-clock time of its last volley's first muzzle (captures read it)
var reduce_motion := false    # settings key reduce_motion (ui_spec.md 7.6; the switch sits in Settings and this menu)
var kill_hold_until := -1.0   # game_t when the kill cut-in lets go; -1 when none holds
var _kill_hold_n := 0


# Issue 521 (Board review of PR 525): while a kill cut-in holds, the camera frames the DYING ship, not the attacker and
# target pair (that wide shot left a dreadnought's death a speck): a low three-quarter view on the target, close enough
# that the hull fills about KILL_FILL of the screen height (a capital more), on whichever quarter is nearest the current
# view so the camera never whips round, eased in over the first beat (the rig's slow easing). _cine_release eases back.
const KILL_FILL := [0.85, 1.0]    # the hull's length against the screen height before the three-quarter view shortens it
                                  # (on screen about 0.4 of the height for a cruiser, about half for a capital): cruiser, capital
const KILL_BETA := 1.12           # the camera's angle down from straight up (64 degrees: low, still above the board)


func _kill_frame(id) -> void:
	var sv = views.get(id)
	if sv == null:
		return
	if cine_saved.is_empty():
		cine_saved = {"a": cam.a, "b": cam.b, "r": cam.r, "t": cam.t}
	var cap: bool = float(VU.get(id, {}).get("size", 0.6)) > 0.8 or bool(VU.get(id, {}).get("flagship", false))
	var fill: float = KILL_FILL[1] if cap else KILL_FILL[0]
	var span := 2.0 * tan(deg_to_rad(cam.fov) * 0.5)   # screen height per unit of distance
	var rr := clampf(maxf(float(sv.L), 6.0) / (fill * span), cam.min_r, 200.0)
	var tp: Vector3 = sv.visual_position()
	# the four three-quarter views (bow and stern quarters, either side): one with no other hull between the camera and
	# the dying ship, nearest the current view (so the camera never swings far)
	var cur: float = cam.a
	var best := cur
	var score := INF
	for q in [PI / 4.0, 3.0 * PI / 4.0, -PI / 4.0, -3.0 * PI / 4.0]:
		var cand: float = cur + angle_difference(cur, float(sv.cur_yaw) + q)
		var eye := tp + Vector3(cos(cand) * sin(KILL_BETA), cos(KILL_BETA), -sin(cand) * sin(KILL_BETA)) * rr
		var blocked := 0.0
		for oid in views:
			var ov = views[oid]
			if oid == id or ov == null or ov.dead or not ov.visible:
				continue
			var o: Vector3 = ov.visual_position()
			var seg := tp - eye
			var k := clampf((o - eye).dot(seg) / maxf(seg.length_squared(), 1e-4), 0.0, 1.0)
			if (eye + seg * k).distance_to(o) < float(ov.L) * 0.6 + float(sv.L) * 0.15 and k < 0.92:
				blocked += 1.0
		var sc := blocked * 10.0 + absf(cand - cur)
		if sc < score:
			score = sc
			best = cand
	cam.a = best
	cam.b = KILL_BETA
	cam.r = rr
	cam.t = tp
	cam.slow_until = cam._clock + 1.2
	hud.letterbox(true)


func _kill_hold(core_id := "") -> void:
	var hold := 1.6 * speed
	_kill_hold_n += 1
	var n := _kill_hold_n
	if core_id != "" and not skip:
		var dying_ship = gfx.ship(core_id)
		if dying_ship != null and dying_ship.death_core_pending:
			# Wait on the FX clock, including any cut delay, then keep the same real-time tail.
			kill_hold_until = INF
			while is_inside_tree() and n == _kill_hold_n and gfx.ship(core_id) == dying_ship and dying_ship.death_core_pending:
				await get_tree().process_frame
			if not is_inside_tree() or n != _kill_hold_n:
				return
			if gfx.ship(core_id) != dying_ship or gfx.death_core_at(core_id) < 0.0:
				_kill_let_go()
				return
			hold = KILL_AFTER + (0.0 if reduce_motion else float(gfx.DEATH_SLOW_S))
	kill_hold_until = game_t + hold
	get_tree().create_timer(hold).timeout.connect(func() -> void:
		if n == _kill_hold_n:
			_kill_let_go())


func _kill_let_go() -> void:
	kill_hold_until = -1.0
	_kill_hold_n += 1
	if not cine_saved.is_empty():
		cam.slow_until = cam._clock + 0.9   # back to the board view on the slow easing, not a snap out of the close-up
	_cine_release()


# a key or a click while a kill cut-in holds: the camera comes back and the slow-motion beat ends now
func _kill_skip() -> void:
	if kill_hold_until < 0.0:
		return
	if gfx != null and gfx.has_method("skip_death_slowmo"):
		gfx.skip_death_slowmo()
	_kill_let_go()


func _play_death(e: Dictionary) -> void:
	var id = e["unit"]
	var sv = views.get(id)
	_deaths_left = maxi(_deaths_left - 1, 0)
	var cined := false
	if sv != null and _cine_wants("kill", e.get("by"), id) and cine_saved.is_empty():
		_kill_frame(id)
		recording_cue.emit("cut_start", "kill: %s" % _name(id))
		cined = true
	var cause := str(e.get("cause", "blast"))
	var friend := _side(id) == "player"
	var sq := bool(VU.get(id, {}).get("squadron", false))
	_log("%s %s." % [_name(id), "is shot down" if sq else "is destroyed"], "e" if friend else "p")
	if sv == null:
		return
	var L: float = sv.L
	var p: Vector3 = sv.visual_position() + Vector3(0, 2, 0)
	var big := L >= 14.0
	if gfx != null and gfx.has_method("death"):
		if "kill_slowmo" in gfx:
			gfx.kill_slowmo = not reduce_motion
		var t: float = float(gfx.death(str(id), cause))
		if skip and gfx.has_method("hurry_death"):
			gfx.hurry_death()
		if cined:
			_kill_hold(str(id))
		death_audio.fx = gfx
		death_audio.watch(str(id), p)
		sv.dead = true
		if sv.marker != null:
			sv.marker.visible = false
		sv.ring.visible = false
		hud.remove_plate(str(id))
		# a death is a key moment: it follows the pace only gently (half its hold at most on the enemy's turn, a quarter on
		# hurry) and a big hull always gets 0.8 s; G4's effect plays on either way
		var pk := clampf(speed, 0.25 if skip else 0.5, 1.0)
		var floor_k := clampf(speed / 0.35, 0.35, 1.0)   # under the round budget a big hull's hold shrinks too
		# Issue 1238 (Board): when more kills follow in the same batch, this one waits only its floor and the next death
		# starts while it plays, so three capitals dying in one volley overlap instead of stacking their full holds;
		# the last death of the batch keeps its whole hold.
		var hold := (0.8 if big else 0.3) * floor_k
		if _deaths_left == 0:
			hold = maxf(hold, t * 0.6 * minf(pk, floor_k))
		await get_tree().create_timer(hold).timeout
		# issue 521: the next event waits while a kill cut-in still holds (a key or a click lets it go)
		while kill_hold_until > 0.0 and game_t < kill_hold_until and not ended:
			await get_tree().process_frame
		return
	if cined:
		_kill_hold()
	_flash(p, 14.0 + L * 1.6, Color(1.0, 0.65, 0.3), 0.9)
	_flash(p + Vector3(L * 0.25, 1, 0), 8.0 + L * 0.8, Color(1.0, 0.85, 0.6), 0.5, 0.15 * speed)
	_flash(p - Vector3(L * 0.25, 0, 1), 8.0 + L * 0.8, Color(1.0, 0.5, 0.2), 0.6, 0.3 * speed)
	# The fallback has no staged run. Dark/hulk outcomes still never get a boom.
	if cause in ["dark", "hulk"]:
		sfx.play("hulk_vent", {"pos": p})
	else:
		sfx.boom(0.22 + minf(0.3, L / 90.0) if sq else (1.2 if big else 0.6), p)
	sv.die(wrecked.has(id))
	hud.remove_plate(str(id))
	var dk := _enemy_pace_k() if not friend else 1.0
	await wait((0.68 if not sq else 0.25) * 1000.0 * maxf(0.4, dk))


# ---------------------------------------------------------------- end of battle

# The end banner's [ships of yours lost, enemy ships destroyed]. Issue 1481: wings are not ships (the campaign card
# skips them too), and a ship that fled is not lost.
static func end_tally(view: Dictionary) -> Array:
	var lost := 0
	var killed := 0
	for u in view.get("units", []):
		if u["dead"] and not u["fled"] and not u.get("squadron", false):
			if u["side"] == "player":
				lost += 1
			else:
				killed += 1
	return [lost, killed]

# One end sound (issue 1448): the music's fanfare, or the synth sting only when the music cannot play one (music off,
# volume at zero or no track). Both used to start in the same moment. Returns which one played: "music" or "sting".
func _end_sound(win: bool) -> String:
	if music != null and (music.victory(boss_fight) if win else music.defeat()):
		return "music"
	sfx.sting(win)
	return "sting"


func _end_flow() -> void:
	ended = true
	# issue 1559 item 8: Fight again (the menu) during the victory beat starts a new battle while this one still waits; its
	# end card must not land in the new fight
	var g := _gen
	var outcome: String = api.battle_result()
	var win := outcome == "win"
	var withdrawal := outcome == "retreat"
	var heading := "Withdrawal" if withdrawal else ("Victory" if win else "Defeat")
	await wait(500.0)
	if _stale(g):
		return
	if not withdrawal:
		_end_sound(win)
	hud.banner(heading, Color("#ff8a3a") if win else Color("#ff8a72"), 1.6)
	await get_tree().create_timer(1.2).timeout
	if _stale(g):
		return
	var tally := end_tally(V)
	var lost: int = tally[0]
	var killed: int = tally[1]
	result = {"result": outcome, "rounds": int(V["round"]), "killed": killed, "lost": lost, "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V,
		"pipeline_compiles": _pipe_count() - pipe_base if pipe_base >= 0 else -1, "pace": pace_stats()}
	var body := "%d enemy ship%s destroyed, %d of yours lost, in %d round%s." % [killed, "" if killed == 1 else "s", lost, int(V["round"]), "" if int(V["round"]) == 1 else "s"]
	_play_log_out(outcome)
	if args.has("pace-report"):
		# --pace-report (with --bot): the battle's report with the enemy's time per round by event kind, then quit
		_quit_report()
		return
	if bot or args.has("bot-runs"):
		_finish(result)
		return
	if voice != null and not withdrawal:   # story hook: your admiral's last word (or the Nemesis's gloat) on the end card
		var vl: String = voice.closing(win)
		if vl != "":
			body += "\n\n" + vl
			recording_cue.emit("voice", vl)
	hud.show_end(heading, body, win, external)


# ---------------------------------------------------------------- selection, overlays, tips

# the rules' read-only UI facts for one ship (G1 ui_info: orders, ram, boarding, ability target hexes, every gun against
# every enemy), cached until the picture changes
var _ui_cache := {}


func _ui(id: String) -> Dictionary:
	if id == "" or api == null:
		return {}
	# Rules facts change on moves and turns, even when the log and batch count do not.
	var k := "%s|%d" % [id, api.version]
	if _ui_cache.has(k):
		return _ui_cache[k]   # issue 1433: a published answer needs no rules read, even while a worker runs
	if not _api_join():
		return {}
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


func select(id: String, how := "pick") -> void:
	if id != sel:
		tip_slot = "%s:player:%s" % [str(V.get("round", 1)), id]
	var su: Dictionary = VU.get(id, {})
	if api != null and api.phase == "player" and _usable(su):
		tip_handed = true
		plog.open(su, int(V.get("round", 0)), how)   # a different ship picked before acting closes the last entry as "switched"
	sel = id
	inspect = ""
	armed = -1
	mode = ""
	wing_sel = ""
	_plan_clear()
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


# The guns that would fire on t_id: from the ghost when a move is planned (issue 1589), else from where the ship sits. With
# free_only, guns already aimed at another pick in the plan are left out. pick overrides the armed gun ([-1] = all guns).
func _firing_set(t_id: String, free_only := true, pick = null) -> Array:
	var out: Array = []
	if not _api_join():
		return out
	var ru = api.unit(sel)
	var tu = api.unit(t_id)
	if ru == null or tu == null:
		return out
	var arm: int = armed if pick == null else int(pick[0])
	var idx: Array = [arm] if arm >= 0 else range(ru["weapons"].size())
	var taken := {}
	if free_only:
		for a in aims:
			for i in a["guns"]:
				taken[int(i)] = true
	var src = api.R.stateView(ru, plan) if plan != null else null
	for i in idx:
		if taken.has(int(i)):
			continue
		if src == null:
			if api.can_fire(sel, i, t_id):
				out.append(i)
		elif api.R.canFire(src, ru["weapons"][i], tu):
			out.append(i)
	return out


# the guns the card and odds show for an enemy: its pick's guns when it is aimed, else the free guns that bear
func _shown_set(t_id: String) -> Array:
	for a in aims:
		if str(a["tid"]) == t_id:
			return (a["guns"] as Array).duplicate()
	return _firing_set(t_id)


func _attack_move(t_id: String):
	# v51 attack-move (the rules' attack_plan): an enemy your guns can't reach yet; burn to the best hex and fire on the way
	if not _api_join():
		return null
	var weapons = [armed] if armed >= 0 else null
	var am = api.attack_plan(sel, t_id, weapons)
	if am == null:
		return null
	return {"st": am["state"], "n": int(am["guns"]), "of": int(am["of"]), "weapons": weapons}


# firing arcs as fans on the board under the selected ship (the game's arc fans): one per ready gun, its range and arc
var fan_root: Node3D
var fan_for := ""
var fan_key := ""
const ARC_SPAN := {"F": [-60.5, 60.5], "R": [119.5, 240.5], "S": [29.5, 150.5], "P": [-150.5, -29.5]}


func _fans(id: String, host: Node3D = null) -> void:
	var ru = VU.get(id) if id != "" else null
	var k := ""
	if ru != null:
		k = "%s|%d|%d|%d|%s" % [id, int(ru["q"]), int(ru["r"]), int(ru["facing"]), str(host.get_instance_id()) + str(host.position) + str(host.rotation.y) if host != null else ""]
		for w in ru["weapons"]:
			k += "1" if w["ready"] else "0"
	if k == fan_key:
		return
	fan_key = k
	if fan_root != null:
		if is_instance_valid(fan_root):
			fan_root.queue_free()
		fan_root = null
	if ru == null or not views.has(id):
		return
	fan_root = Node3D.new()
	(host if host != null else views[id]).add_child(fan_root)
	fan_root.position.y = -0.35
	var done := {}
	for w in ru["weapons"]:
		var arc := str(w["arc"])
		if not w["ready"] or w["kind"] == "flak" or not ARC_SPAN.has(arc):
			continue
		var rad: float = float(w["range"]) * board.HW + 0.5
		var dk := "%s%d" % [arc, int(rad)]
		if done.has(dk):
			continue
		done[dk] = true
		var col: Color = {"lance": Color(1.0, 0.45, 0.3), "torp": Color(1.0, 0.75, 0.3), "gauss": Color(0.5, 1.0, 0.6)}.get(str(w["kind"]), Color(1.0, 0.62, 0.3))
		# F1: the edge only. Even a 4.5% fill washed half the board tan: it blends in linear light over a near-black board,
		# which the tonemapper lifts to about a quarter brightness. --arc-fill brings the fill back for comparisons.
		if args.has("arc-fill"):
			fan_root.add_child(_fan_mesh(ARC_SPAN[arc][0], ARC_SPAN[arc][1], rad, col))
		fan_root.add_child(_fan_edge(ARC_SPAN[arc][0], ARC_SPAN[arc][1], rad, col))


# Issue 1446: the inspected enemy's gun arcs, one quiet bone outline per arc and range (line_style "arc_enemy", R362),
# under the enemy ship, so you can see which of its sides you would be standing in. A gun counts when it will be ready in
# the enemy's next turn (the rules clear "fired" and take one off reload and offline when that turn starts), which is
# what you are planning against. Flak never shows (as your own).
var efan_root: Node3D
var efan_key := ""


func _enemy_fans(id: String) -> void:
	var ru = VU.get(id) if id != "" else null
	var k := ""
	if ru != null and views.has(id):
		k = "%s|%d|%d|%d|" % [id, int(ru["q"]), int(ru["r"]), int(ru["facing"])]
		for w in ru["weapons"]:
			k += "1" if _ready_next(w) else "0"
	if k == efan_key:
		return
	efan_key = k
	if efan_root != null:
		if is_instance_valid(efan_root):
			efan_root.queue_free()
		efan_root = null
	if k == "":
		return
	efan_root = Node3D.new()
	efan_root.name = "EnemyArcs"
	views[id].add_child(efan_root)
	efan_root.position.y = -0.36
	var col: Color = Board.LS.ROLE["arc_enemy"]
	var done := {}
	# the fans stop at the board edge (a long gun's range ran out over open space in the PC pictures)
	var xf := efan_root.global_transform
	var keep := func(v: Vector3) -> bool:
		var h: Vector2i = board.world_hex(xf * v)
		return board.on_board(h.x, h.y)
	for w in ru["weapons"]:
		var arc := str(w["arc"])
		if not _ready_next(w) or w["kind"] == "flak" or not ARC_SPAN.has(arc):
			continue
		var rad: float = float(w["range"]) * board.HW + 0.5
		var dk := "%s%d" % [arc, int(rad)]
		if done.has(dk):
			continue
		done[dk] = true
		efan_root.add_child(_fan_edge(ARC_SPAN[arc][0], ARC_SPAN[arc][1], rad, col, 0.4, col.a, keep))


# Issue 1446 (R246): the sides the rules have routed this ship's shield power to (a side that was struck since its own
# turn began, while the pool holds). A routed side covers 0.20 more of each hit (SHIELD_ROUTE_BOOST), and hits there drain the pool 30%
# faster. Quad order prow, starboard, rear, port.
static func _routed_sides(u: Dictionary) -> Array:
	var out: Array = []
	var r = u.get("route")
	if not (r is Array) or float(u.get("shMax", 0) if u.get("shMax") != null else 0) <= 0.0 or float(u.get("shp", 0) if u.get("shp") != null else 0) < 1.0:
		return out
	for i in mini((r as Array).size(), 4):
		if r[i] != null and float(r[i]) > 0.0:
			out.append(i)
	return out


static func _route_line(sides: Array) -> String:
	var names := PackedStringArray()
	for q in sides:
		names.append(QUAD_NAME[int(q)])
	var which := " and ".join(names)
	return "Shields routed to the %s side%s: %s catch more of each hit, but hits there drain the pool 30%% faster. It clears at the ship's next turn." % [which, "s" if sides.size() > 1 else "", "they" if sides.size() > 1 else "it"]


static func _ready_next(w: Dictionary) -> bool:
	return float(w["cd"] if w.get("cd") != null else 0) <= 1.0 and float(w["off"] if w.get("off") != null else 0) <= 1.0


func _fan_mesh(a0: float, a1: float, rad: float, col: Color) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	if a1 - a0 < 300.0:   # the same range line as _fan_edge: half a hex past the arc's line at full range (issue 1589)
		var da := rad_to_deg(asin(clampf(board.HW * 0.5 / rad, 0.0, 1.0)))
		a0 -= da
		a1 += da
	for i in n:
		var t0 := deg_to_rad(lerpf(a0, a1, float(i) / n))
		var t1 := deg_to_rad(lerpf(a0, a1, float(i + 1) / n))
		# ship frame: bow +X, starboard +Z (relAng > 0 is starboard)
		var p0 := Vector3(cos(t0), 0, sin(t0)) * rad
		var p1 := Vector3(cos(t1), 0, sin(t1)) * rad
		# F1: a faint fill (the old 0.16 washed half the board tan over the move hexes); the bright edge carries the shape
		st.set_color(Color(col.r, col.g, col.b, 0.0))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(col.r, col.g, col.b, 0.045))
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


# F1: the outline of a firing fan: a bright line along its range and its two sides, so arc and range read at a glance
func _fan_edge(a0: float, a1: float, rad: float, col: Color, w := 0.55, alpha := 0.75, keep = null) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	var c := Color(col.r, col.g, col.b, alpha)
	var sides := [a0, a1]
	if a1 - a0 < 300.0:   # the range line meets the sides half a hex outside the arc's line (below)
		var da := rad_to_deg(asin(clampf(board.HW * 0.5 / rad, 0.0, 1.0)))
		a0 -= da
		a1 += da
	for i in n:
		var t0 := deg_to_rad(lerpf(a0, a1, float(i) / n))
		var t1 := deg_to_rad(lerpf(a0, a1, float(i + 1) / n))
		var o0 := Vector3(cos(t0), 0, sin(t0))
		var o1 := Vector3(cos(t1), 0, sin(t1))
		if keep != null and not bool(keep.call((o0 + o1) * 0.5 * rad)):
			continue   # issue 1446: this stretch of the rim lies off the board
		for v in [o0 * rad, o1 * rad, o1 * (rad - w), o0 * rad, o1 * (rad - w), o0 * (rad - w)]:
			st.set_color(c)
			st.add_vertex(v)
	if sides[1] - sides[0] < 300.0:
		for a in sides:
			var d := Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a)))
			var sd := Vector3(-d.z, 0, d.x) * (w * 0.5)
			# issue 1589 (Ryan, Nov 22): a ship whose hex sits on the arc's line is in the arc (rules inArc), so each side
			# runs half a hex outside that line, along the far edge of the hexes on it, never through their middles
			var out: Vector3 = Vector3(d.z, 0, -d.x) * (board.HW * 0.5) * (1.0 if a == sides[0] else -1.0)
			var near: Vector3 = d * 6.0 + out
			var reach_r := sqrt(maxf(rad * rad - board.HW * board.HW * 0.25, 1.0))
			if keep != null:   # issue 1446: stop the side where it leaves the board
				var full := reach_r
				reach_r = 6.0
				while reach_r + 1.0 <= full and bool(keep.call(d * (reach_r + 1.0) + out)):
					reach_r += 1.0
			var far: Vector3 = d * reach_r + out
			for v in [[near - sd, 0.0], [far - sd, 0.5], [far + sd, 0.5], [near - sd, 0.0], [far + sd, 0.5], [near + sd, 0.0]]:
				st.set_color(Color(col.r, col.g, col.b, v[1] * alpha / 0.75))
				st.add_vertex(v[0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


func _clear_overlay() -> void:
	_fans("")
	_enemy_fans("")
	board.set_overlay({}, {})
	board.show_blockers([])
	board.set_outline({})
	arrow.visible = false
	path_dots.multimesh.instance_count = 0
	path_line.visible = false
	if ghost != null:
		ghost.visible = false


func _overlay() -> void:
	if quitting or board == null or not is_instance_valid(board):
		return
	if _threat_wanted() and _threat_idle() and not _threat_busy:
		# Start after this UI pass, so its own rule reads do not immediately join the worker.
		_threat_request.call_deferred()
	if board != null and board.has_method("set_danger"):
		board.set_danger(_danger_bands())
	if _threat_busy and _worker_owns_rules():
		return   # issue 1433: keep the last drawing; the publish redraws it (no blank reach area while the map computes)
	if not _can_act():
		_clear_overlay()
		if threat_on:
			board.set_overlay(_threat_fills(), {})
		return
	var fills := {}
	var rings := {}
	var styles := {}
	if threat_on:
		fills = _threat_fills()
	var u := _sel_unit()
	var ability_mode := mode in ["nova", "blink", "ram"]
	if _usable(u) and not ability_mode:
		# F1: every reachable hex blue with a lit edge (style 1) and one bright line around the whole area
		for k in reach_map:
			if not fills.has(k):
				fills[k] = REACH_C
			rings[k] = REACH_RING
			styles[k] = 1
		var out := reach_map.duplicate()
		out[board.key(u["q"], u["r"])] = true
		board.set_outline(out if reach_map.size() > 0 else {})
		for e in V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not _firing_set(e["id"]).is_empty():
				rings[board.key(e["q"], e["r"])] = TARGET_RING
	else:
		board.set_outline({})
	if ability_mode:
		for h in _ability_hexes():
			fills[board.key(h["q"], h["r"])] = Color(0.92, 0.92, 1.0, 0.26)
			rings[board.key(h["q"], h["r"])] = Board.LS.ROLE["ability"]
	if mode == "board" and not u.is_empty():
		for b in _ui(sel).get("board", []):
			var tu: Dictionary = VU.get(b["target"], {})
			if not tu.is_empty():
				rings[board.key(tu["q"], tu["r"])] = Board.LS.ROLE["board"]
	# issue 1444: the armed ram's run (each hex it crosses) and the ship it hits; the nova shell's 7-hex blast under the
	# hovered target hex, with every friendly ship inside it ringed red
	if mode == "ram" and not u.is_empty():
		var rm = _ui(sel).get("ram")
		if rm is Dictionary:
			for p in rm["path"]:
				var pk0: String = board.key(int(p["q"]), int(p["r"]))
				fills[pk0] = Board.LS.ROLE["ram_fill"]
				rings[pk0] = Board.LS.ROLE["ram"]
			var rt: Dictionary = VU.get(rm["target"], {})
			if not rt.is_empty():
				rings[board.key(rt["q"], rt["r"])] = Board.LS.ROLE["danger"]
	if mode == "nova" and not u.is_empty():
		var blast := _nova_blast(hover.x, hover.y)
		for h in blast["hexes"]:
			var bk: String = board.key(h.x, h.y)
			fills[bk] = Board.LS.ROLE["blast_fill"]
			rings[bk] = Board.LS.ROLE["blast"]
		for f in blast["friends"]:
			rings[board.key(f["q"], f["r"])] = Board.LS.ROLE["danger"]
	# the rehearsed position (a planned move, or the attack-move's stopping hex): the ghost, its path, arcs from there,
	# and orange rings on enemies its guns would reach from there
	var pst = plan if plan != null else (atk["st"] if atk != null else null)
	var mm := path_dots.multimesh
	arrow.visible = false
	mm.instance_count = 0
	path_line.visible = false
	if pst != null and _usable(u):
		var pk: String = board.key(pst.q, pst.r)
		fills[pk] = REACH_HOT
		styles[pk] = 2
		_ghost_show(u, pst)
		_path_dots(u, pst)
		for e in V["units"]:
			if e["side"] != "enemy" or e["dead"]:
				continue
			var ek: String = board.key(e["q"], e["r"])
			if rings.get(ek) == TARGET_RING:
				continue
			if plan != null:
				continue   # issue 1589: a plain plan's red rings come from _firing_set (the guns a click would aim)
			for w in u["weapons"]:
				if atk["weapons"] != null and int(w["i"]) not in atk["weapons"]:
					continue
				if w["ready"] and w["kind"] != "flak" and api.in_reach(sel, int(w["i"]), e["id"], pst):
					rings[ek] = TARGET_PLAN
					break
	elif ghost != null:
		ghost.visible = false
	if mode == "ram" and not u.is_empty() and views.has(sel):
		var rm2 = _ui(sel).get("ram")
		if rm2 is Dictionary:
			_path_dots(u, {"path": rm2["path"]})   # issue 1444: the ram's run as the shared path line
	if target != "" and VU.has(target) and not VU[target]["dead"]:
		rings[board.key(VU[target]["q"], VU[target]["r"])] = TARGET_ON
	for a in aims:   # issue 1589: every enemy picked in the plan shows the lock ring
		var at: Dictionary = VU.get(str(a["tid"]), {})
		if not at.is_empty() and not at["dead"]:
			rings[board.key(at["q"], at["r"])] = TARGET_ON
	_fans(sel if (arcs_on and _usable(u)) else "", ghost if (pst != null and ghost != null and ghost.visible) else null)
	_enemy_fans(_inspected_enemy() if arcs_on else "")
	var hk: String = board.key(hover.x, hover.y)
	if reach_map.has(hk) and _unit_at(hover.x, hover.y).is_empty() and _usable(u) and not ability_mode and hk != plan_k:
		var st = _hover_state(hk)
		fills[hk] = REACH_HOT
		styles[hk] = 2
		arrow.visible = true
		arrow.position = board.hex_world(st.q, st.r, 0.6)
		arrow.rotation.y = ShipView.yaw_of(st.f)
		if pst == null:
			_path_dots(u, st)
	var shot_target := _unit_at(hover.x, hover.y)
	if shot_target.is_empty() and target != "": shot_target = VU.get(target, {})
	if not shot_target.is_empty() and shot_target.get("side") == "enemy":
		board.show_blockers(_shot_blockers(shot_target))
	else:
		board.show_blockers([])
	# issue 1446: an inspected enemy you are not aiming at shows every hex its guns can reach next turn, faintly, under
	# whatever else the board shows (the threat map's own bone, at a quarter of its full strength)
	var reach := {}
	if _one_current() and _one_want() != "":
		for k in _threat_one:
			if float(_threat_one[k]) > 0.0:
				reach[k] = true
	board.set_reach(reach)   # an outline round the area, not a fill (PC pictures, Nov 22)
	board.set_overlay(fills, rings, styles)
	board.set_focus(_pos(sel) if sel != "" and views.has(sel) else cam.t)


func _path_dots(u: Dictionary, st) -> void:
	var run := {"pts": [board.hex_world(u["q"], u["r"], 0.5)]}
	for p in st.path:
		if not _jt(p.get("rot")):
			run["pts"].append(board.hex_world(p["q"], p["r"], 0.5))
	if run["pts"].size() < 2:
		return
	views[u["id"]]._prep_run(run)
	var line := SurfaceTool.new()
	line.begin(Mesh.PRIMITIVE_TRIANGLES)
	var samples: Array = run["smp"]
	for i in samples.size() - 1:
		var a: Vector3 = samples[i]
		var b: Vector3 = samples[i + 1]
		# issue 1374: a centred line in the shared style, half on each side of the path
		var side := (b - a).cross(Vector3.UP).normalized()
		Board.LS.strip_into(line, a, b, side, side, "path", Color(0, 0, 0, -1), true)
		Board.LS.strip_into(line, a, b, -side, -side, "path", Color(0, 0, 0, -1), true)
	path_line.mesh = line.commit()
	path_line.visible = true

# the planned position: a see-through blue copy of the ship's hull standing on the planned hex, facing the planned way.
# Issue 1589 (Ryan's pick 3b): a bright outline around it, so the plan reads as the ship's stand-in from the battle camera.
const GHOST_COL := Color(0.45, 0.78, 1.0, 0.30)
const GHOST_EDGE := Color(0.72, 0.92, 1.0, 0.95)


func _ghost_show(u: Dictionary, st) -> void:
	var sv = views.get(u["id"])
	if sv == null:
		return
	if ghost == null or ghost_for != str(u["id"]) or not is_instance_valid(ghost):
		_ghost_clear()
		ghost = Node3D.new()
		ghost.name = "PlanGhost"
		add_child(ghost)
		ghost_for = str(u["id"])
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = GHOST_COL
		m.cull_mode = BaseMaterial3D.CULL_BACK
		m.no_depth_test = false
		# the outline: the same hull pushed out a little along its normals, drawn back faces only (an inverted shell)
		var edge := StandardMaterial3D.new()
		edge.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		edge.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		edge.albedo_color = GHOST_EDGE
		edge.cull_mode = BaseMaterial3D.CULL_FRONT
		edge.grow = true
		edge.grow_amount = clampf(float(sv.L) * 0.012, 0.18, 0.6)
		m.next_pass = edge
		if sv.hull != null:
			var h: Node3D = sv.hull.duplicate(0)
			ghost.add_child(h)
			for n in h.find_children("*", "", true, false):
				if n is GeometryInstance3D and not (n is MeshInstance3D):
					n.queue_free()
				elif n is MeshInstance3D:
					(n as MeshInstance3D).material_override = m
					(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					for i in (n as MeshInstance3D).get_surface_override_material_count():
						(n as MeshInstance3D).set_surface_override_material(i, null)
				elif n is Light3D or n is GPUParticles3D or n is CPUParticles3D or n is Decal:
					n.queue_free()
		# a footprint ring under the ghost in the same blue
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		var rr := maxf(8.0, float(sv.L) * 0.52)
		tm.inner_radius = rr
		tm.outer_radius = rr + 0.5
		tm.rings = 48
		tm.ring_segments = 4
		ring.mesh = tm
		var rm := StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.albedo_color = Color(0.6, 0.85, 1.0)
		ring.material_override = rm
		ring.position.y = -0.3
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost.add_child(ring)
	ghost.visible = true
	ghost.position = board.hex_world(st.q, st.r)
	ghost.rotation.y = ShipView.yaw_of(st.f)


func _ghost_clear() -> void:
	if ghost != null and is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null
	ghost_for = ""


func _hover_state(k: String):
	var st = reach_map[k]
	if hover_pick.has(k) and reach_alt.has(k):
		var alts: Array = reach_alt[k]
		st = alts[int(hover_pick[k]) % alts.size()]
	return st


var _threat_cache := {}
var _threat_version := -1
var _threat_pending_version := -1


# ui3d.js computeThreat: for every enemy ship, every hex it can end its move on and every facing there, the guns that bear
# on each hex (range, arc, line of sight); the best end state counts per enemy, summed over enemies. Darker = more damage.
func _threat_fills() -> Dictionary:
	var out := {}
	if not _threat_current():
		return out
	var mx := 1.0
	for k in _threat_cache:
		mx = maxf(mx, float(_threat_cache[k]))
	for k in _threat_cache:
		var f := float(_threat_cache[k]) / mx
		if f > 0.0:
			# issue 271 step 2: bone (Board.THREAT), not red (the Nemesis alarm's alone) and not lavender (R174's list)
			out[k] = Color(Board.THREAT, 0.05 + 0.27 * f)
	return out


# Only compute once the displayed view has caught up with the rules. At that point the API's version describes both.
func _threat_idle() -> bool:
	return api != null and not warming and not busy and not thinking and batches.is_empty() and api.phase == "player"


func _threat_current() -> bool:
	return _threat_version >= 0 and _threat_idle() and _threat_version == int(api.version)


# Issue 1446: the one enemy whose own reach the board shows: the enemy you inspect (clicked, or the one the panel shows)
# while you are not aiming at it. Its map rides the same worker as the threat map (only_id), never the main thread.
var _threat_one := {}
var _threat_one_for := ""
var _threat_one_pending := ""
var _threat_one_ver := -1


func _inspected_enemy() -> String:
	if inspect == "" or not VU.has(inspect) or VU[inspect]["dead"] or VU[inspect]["side"] != "enemy" or bool(VU[inspect].get("squadron", false)):
		return ""
	return inspect


func _one_want() -> String:
	var id := _inspected_enemy()
	return id if (id != "" and target != id and not bot and not showcase and not ended) else ""


func _one_current() -> bool:
	return _threat_one_ver >= 0 and _threat_idle() and _threat_one_ver == int(api.version) and _threat_one_for == _one_want()


func _threat_wanted() -> bool:
	if (threat_on or _danger_shown()) and not _threat_current():
		return true
	return _one_want() != "" and not _one_current()


# The damage map and reach counts share the API's versioned result, computed off the main thread.
func _threat_request() -> void:
	if quitting or not _threat_idle() or _threat_busy or not _threat_wanted():
		return
	_threat_pending_version = int(api.version)
	_threat_gen = _gen
	_threat_busy = true
	# issue 1446: the fleet map only when an overlay needs it, the one enemy's map only when one is inspected; each has
	# its own version, so inspecting an enemy with both fleet overlays off never pays for every enemy's reach
	var all := (threat_on or _danger_shown()) and not _threat_current()
	var one := _one_want() if not _one_current() else ""
	_threat_one_pending = one
	var tid := WorkerThreadPool.add_task(func() -> void:
		var r: Dictionary = api.threat_both() if all else {}
		if one != "":
			r["one"] = api.threat_map(one)
		_threat_next = r)
	_threat_tid = tid
	_threat_wait(tid)


# #271: how many enemies can bring guns on each hex next turn, as hatching bands on the board (1, 2, 3 or more), in your
# turn only. "q,r" -> band. The same counts give the danger badges on the fleet list and the ship that is up.
var _danger := {}


func _danger_shown() -> bool:
	return danger_on and not bot and not showcase and not ended and api != null and api.phase == "player" and not V.is_empty()


func _danger_bands() -> Dictionary:
	if not _danger_shown() or not _threat_current():
		return {}
	# R148: the board hatching shows only in the Move step, as in the mockup (a ship up that can still move, nothing
	# targeted, not braced). The counts stay live for the danger badges on the fleet list and the shell either way.
	if not _move_step():
		return {}
	var out := {}
	for k in _danger:
		var n := int(_danger[k])
		if n > 0:
			out[k] = mini(n, 3)
	return out


# the Move step: a usable ship is up (or selected) with movement left, not braced, with no enemy targeted
func _move_step() -> bool:
	var id := _active_id()
	if id == "":
		id = sel
	if id == "" or not VU.has(id) or not _usable(VU[id]) or target != "":
		return false
	var u: Dictionary = VU[id]
	return not bool(u.get("braced", false)) and int(u.get("moveLeft", u.get("mp", 0))) > 0


# enemies that can bring guns on a ship's hex next turn (0 when the counts are not in yet)
func _danger_at(u: Dictionary) -> int:
	if not _danger_shown() or not _threat_current() or board == null:
		return 0
	return int(_danger.get(board.key(int(u["q"]), int(u["r"])), 0))


var _threat_busy := false
var _threat_next := {}


# polls completion each frame; whoever sees it finished first reaps it once (_threat_reap)
func _threat_wait(tid: int) -> void:
	while _threat_tid == tid and not WorkerThreadPool.is_task_completed(tid):
		if not is_inside_tree():
			return   # _exit_tree drains it
		await get_tree().process_frame
	if _threat_tid != tid:
		return  # already reaped
	_threat_reap()


func _threat_done() -> void:
	_threat_busy = false
	if not _threat_idle() or _threat_pending_version != int(api.version):
		_threat_request.call_deferred()
		return
	if _threat_next.has("dmg"):
		_threat_version = _threat_pending_version
		_threat_cache = _threat_next["dmg"]
		_danger = _threat_next["n"]
	if _threat_next.has("one"):
		_threat_one = _threat_next["one"]
		_threat_one_for = _threat_one_pending
		_threat_one_ver = _threat_pending_version
	# the danger badges on the fleet list and the shell, and any UI pass that waited for this publish
	_refresh_ui.call_deferred()
	_overlay.call_deferred()
	_ptr_refresh.call_deferred()   # the stationary pointer: tip, panel and target as of this result
	_click_replay.call_deferred()


# issue 1433: after a publish, the pointer reads that answered "pending" are redone where the pointer stands
func _ptr_refresh() -> void:
	if quitting or retiring or not is_inside_tree() or api == null or board == null or not is_instance_valid(hud):
		return
	var was := _ptr_stale
	_ptr_stale = false
	if not was or hover.x == 99999:
		return
	_ptr_depth += 1
	if api.phase == "player" and not busy and target == "" and sel != "":
		hud.set_panel(_panel_info())
		hud.set_target(_target_info())
	hud.show_tip(_tip(), _ptr_pos)
	_ptr_depth -= 1


# issue 1433: a click made while the threat worker ran, played once now if nothing it depended on has changed
func _click_replay() -> void:
	var q := _click_q
	_click_q = {}
	if q.is_empty() or quitting or _stale(int(q["gen"])) or api == null or int(q["v"]) != int(api.version):
		return
	if str(q["sel"]) != sel or str(q["mode"]) != mode or str(q["plan_k"]) != plan_k or str(q["target"]) != target or not _can_act():
		return
	var at: Vector2i = q["hex"]
	if at != hover:
		hover = at
		board.set_hover(at.x, at.y)
	_on_click()
	# the pointer may have moved on since the click: put the hover back where it stands now
	if is_inside_tree() and not retiring and _ray_hex(_ptr_pos) != hover:
		_on_hover(_ptr_pos)


# target hexes for nova and blink
func _ability_hexes() -> Array:
	if sel == "" or not (mode in ["nova", "blink"]):
		return []
	var out: Array = []
	for h in _ui(sel).get("ability", {}).get("hexes", []):
		out.append({"q": int(h["q"]), "r": int(h["r"])})
	return out


# ---------------------------------------------------------------- issue 1444: forecasts before Ram, Board and Nova

const _HEX_DIRS := [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]


static func _hex_d(aq: int, ar: int, bq: int, br: int) -> int:
	return int((absi(aq - bq) + absi(aq + ar - bq - br) + absi(ar - br)) / 2)


# Ram is two presses: the first (X or the Ram button) arms it and shows the run, the target, the damage and the recoil;
# the second (X or the button again, Enter, or a click on the rammed ship) commits. Esc or Cancel drops it.
static var _bb_re: RegEx = null   # not GPU: a compiled text pattern, built once (issue 1437 item 9)


static func _strip_bb(t: String) -> String:
	if _bb_re == null:
		_bb_re = RegEx.create_from_string("\\[/?[a-z]+(=[^\\]]*)?\\]")
	return _bb_re.sub(t, "", true)


func _ram_press() -> void:
	if sel == "" or not _can_act() or not _usable(_sel_unit()):
		return
	if mode == "ram":
		_ram_commit()
		return
	var rm = _ui(sel).get("ram")
	if not rm is Dictionary:
		return
	mode = "ram"
	_plan_clear()
	plog.note("arms ram")
	_refresh_ui()


func _ram_commit() -> void:
	mode = ""
	if sel == "" or not _can_act() or not _api_join() or not (_ui(sel).get("ram") is Dictionary):
		_refresh_ui()
		return
	var id := sel
	plog.act("ram")
	sfx.play("ui_confirm")
	_cmd(func(): return api.ram(id))


# the ram forecast in plain words (BBCode); short drops the second line of how to commit
func _ram_forecast(id: String, short := false) -> String:
	var rm = _ui(id).get("ram")
	if not rm is Dictionary:
		return ""
	var su: Dictionary = VU.get(id, {})
	var tu: Dictionary = VU.get(rm["target"], {})
	var sec := str(SEC_LBL.get(str(rm["section"]), str(rm["section"]))).to_lower()
	var run := (rm["path"] as Array).size()
	var t := "[b][color=#ffb23e]Ram %s[/color][/b]: a %d-hex run into it. About [color=#ffad3b]%d hull[/color] to its %s" % [_name(rm["target"]), run, int(rm["dmg"]), sec]
	if int(rm["soak"]) > 0:
		t += " (its shield soaks %d)" % int(rm["soak"])
	t += "; [color=#ff8a72]%d recoil[/color] to your prow." % int(rm["recoil"])
	if not tu.is_empty() and float(rm["dmg"]) >= float(tu["hp"]):
		t += " [color=#ffad3b]That should destroy it.[/color]"
	if not su.is_empty() and float(rm["recoil"]) >= float(su["hp"]):
		t += "\n[color=#ff4a4a][b]Warning: the recoil will destroy your own ship (hull %s).[/b][/color]" % Campaign.hull_text(su["hp"])
	t += " The ship stops there for the round."
	if not short:
		t += "\n[b]Press X again, click the target or press Enter to ram.[/b] Esc cancels. A ram can't be taken back."
	return t


# one boarding target's odds in plain words (BBCode)
func _board_odds_text(id: String, b: Dictionary) -> String:
	var ru = api.unit(id)
	var crew := int(_z0(ru.get("crew"))) if ru != null else 0
	var loss := mini(int(b["loss"]), maxi(0, crew - 1))
	var cap := int(b["chance"])
	var tr = api.unit(str(b["target"]))
	var word := "scuttle" if (tr != null and api.R.boardScuttles(tr)) else "capture"   # R383 (issue 1479): these are destroyed, never taken
	var cap_t := ("[color=#7dff9b]%s likely[/color]" % word if bool(b["capture"]) else "[color=#ffd27a]%s possible[/color]" % word) if cap > 0 else "[color=#a7b09d]no %s: a raid only[/color]" % word
	return "[b]%s[/b]: [color=#ffb23e]%d%% %s chance[/color], %s. Kills about %d defenders; you lose about %d of %d crew." % [_name(b["target"]), cap, word, cap_t, int(b["kill"]), loss, crew]


func _board_tip(id: String, tid: String) -> String:
	for b in _ui(id).get("board", []):
		if str(b["target"]) == tid:
			return "[b][color=#ffc04d]Board[/color][/b]\n%s\n[color=#ff8a3a]Click to send the boarders. Esc cancels.[/color]" % _board_odds_text(id, b)
	return "[b][color=#ffc04d]Board[/color][/b]\n[color=#a7b09d]Out of reach: boarding needs an enemy ship next to yours.[/color]"


# the nova shell's blast around a centre hex: the 7 hexes, every ship inside, and the friendly ones (empty unless the
# hex is one the shell can be aimed at)
func _nova_blast(q: int, r: int) -> Dictionary:
	var out := {"hexes": [], "hit": [], "friends": []}
	if mode != "nova" or q == 99999:
		return out
	var ok := false
	for h in _ability_hexes():
		if int(h["q"]) == q and int(h["r"]) == r:
			ok = true
			break
	if not ok:
		return out
	var on := {}
	for h in V.get("hexes", []):
		on[Vector2i(int(h["q"]), int(h["r"]))] = true
	var c := Vector2i(q, r)
	for hv in [c] + _HEX_DIRS.map(func(d): return c + d):
		if on.is_empty() or on.has(hv):
			out["hexes"].append(hv)
	for x in V.get("units", []):
		if x["dead"] or _hex_d(int(x["q"]), int(x["r"]), q, r) > 1:
			continue
		out["hit"].append(x)
		if x["side"] == "player":
			out["friends"].append(x)
	return out


func _nova_tip(q: int, r: int) -> String:
	# issue 1433: nova_preview takes the rules lock; never call it while the threat worker owns the rules (a pointer
	# handler gets "pending" here and the publish redraws the tip)
	if not _api_join():
		return ""
	var blast := _nova_blast(q, r)
	if (blast["hexes"] as Array).is_empty():
		return "[b]Spinal shell[/b]\n[color=#a7b09d]Out of the shell's reach: pick a white hex 3 to 9 ahead.[/color]"
	# the raw damage per ship comes from the rules (rules.gd novaDamage, the same call the hit makes)
	var t := "[b][color=#ffd27a]Spinal shell[/color][/b]\nBlasts this hex and the 6 around it, 30% through shields. Damage before shields and armor:"
	var foes: Array = []
	var mine: Array = []
	for p in api.nova_preview(sel, q, r):
		var x: Dictionary = VU.get(p["id"], {})
		if x.is_empty():
			continue
		(mine if x["side"] == "player" else foes).append("%s (%s, %d)" % [str(x["name"]), "centre" if bool(p["centre"]) else "ring", int(round(float(p["dmg"])))])
	if not foes.is_empty():
		t += "\nHits: %s." % ", ".join(PackedStringArray(foes))
	if not mine.is_empty():
		t += "\n[color=#ff4a4a][b]Friendly fire: %s.[/b][/color]" % ", ".join(PackedStringArray(mine))
	if foes.is_empty() and mine.is_empty():
		t += "\n[color=#a7b09d]No ship inside the blast.[/color]"
	t += "\n[color=#ff8a3a]Click to fire. Esc cancels.[/color]"
	return t


# the Hollow Sun's pull on a hex, as one line for the move tip ("" away from it or on a board without it)
func _well_line(q: int, r: int) -> String:
	var W = api.world_info().get("well") if api != null else null
	if not W is Dictionary:
		return ""
	var R = api.R
	var d := _hex_d(q, r, int(W["q"]), int(W["r"]))
	if d <= int(R.WELL_RIM):
		return "[color=#ff8a72]Hollow Sun rim: %d hull damage to a ship here at each round start (it still gets +1 movement).[/color]" % int(R.WELL_DMG)
	if d <= int(R.WELL_PULL):
		return "[color=#c79bff]Hollow Sun pull: a ship here is dragged 1 hex inward at each round start, with +1 movement.[/color]"
	if d <= int(R.WELL_ASSIST):
		return "[color=#9fd4ff]Hollow Sun slingshot: +1 movement at each round start, no pull.[/color]"
	return ""


func _unit_at(q: int, r: int) -> Dictionary:
	for u in V.get("units", []):
		if not u["dead"] and int(u["q"]) == q and int(u["r"]) == r:
			return u
	return {}


# ---------------------------------------------------------------- input

var _board_press := false
var _board_release := false


func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		# End the camera gesture even if the GUI consumes this release. Only an unhandled press can start one.
		_board_release = not e.pressed and _board_press and not cam.handle_input(e)
		_board_press = false


func _unhandled_input(e: InputEvent) -> void:
	if api == null:
		return
	if opening and ((e is InputEventMouseButton and (e as InputEventMouseButton).pressed) or (e is InputEventKey and (e as InputEventKey).pressed)):
		_end_opening()
	if kill_hold_until > 0.0 and ((e is InputEventMouseButton and (e as InputEventMouseButton).pressed and (e as InputEventMouseButton).button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]) or (e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo)):
		_kill_skip()
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			if _board_release and not hud.over_ui(e.position):
				_on_hover(e.position)
				_on_click()
			_board_release = false
			return
		if e.pressed and hud.over_ui(e.position):
			return
		if e.button_index == MOUSE_BUTTON_LEFT:
			_board_press = true
		cam.handle_input(e)
		return
	if e is InputEventMouseMotion:
		cam.handle_input(e)
		_on_hover(e.position)
		return
	if e is InputEventKey and CamRig.is_pan_key(e):
		# A physical pan key can have Q/E/B on a different layout. Never also issue an order.
		get_viewport().set_input_as_handled()
		return
	if e is InputEventKey and (e as InputEventKey).pressed and not (e as InputEventKey).echo:
		_on_key((e as InputEventKey).keycode)


func _on_key(k: int) -> void:
	if hud.menu != null and is_instance_valid(hud.menu):
		# issue 1559 item 1: the menu is modal. Its own buttons take Enter, Space and the arrows; only Esc reaches the
		# battle (it closes the menu). No order key (B, X, G, C, Q, E, 1 to 6, Backspace) acts behind it.
		if k == KEY_ESCAPE:
			hud.hide_menu()
		return
	if hud.ask_panel != null and is_instance_valid(hud.ask_panel):
		# issue 529: a tree prompt is open; 1 to 3 answer it, nothing else acts until it is answered
		var a: Dictionary = V.get("ask") if V.get("ask") is Dictionary else {}
		var opts: Array = a.get("opts", [])
		var i := [KEY_1, KEY_2, KEY_3].find(k)
		if i < 0: i = [KEY_KP_1, KEY_KP_2, KEY_KP_3].find(k)
		if i >= 0 and i < opts.size():
			_on_action("ask", str(opts[i].get("id", "")))
		return
	if k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and (busy or api.phase == "enemy") and not ended:
		# B2: Enter or Space hurries the rest of the enemy's turn (presentation only)
		skip = true
		speed = minf(speed, float(PACE["skip"]))
		if gfx != null and gfx.has_method("hurry_death"):
			gfx.hurry_death()
		return
	match k:
		KEY_ESCAPE:
			if hud.menu != null:
				hud.hide_menu()
				return
			# F1: Esc drops the newest thing first (an ability or boarding pick, a wing pick, the plan or target, the armed
			# weapon, the ship you were looking at); the ship that is up stays up. With nothing to drop it opens the menu.
			if mode != "":
				mode = ""
			elif wing_sel != "":
				wing_sel = ""
				hud.toast("Wing order cancelled.")
			elif plan != null or target != "" or not aims.is_empty():
				_cancel("esc")
				return
			elif armed >= 0:
				armed = -1
			elif inspect != "":
				inspect = ""
			else:
				_open_menu()
				return
			sfx.play("ui_cancel")
			_refresh_ui()
		KEY_TAB:
			_next_ship()
		KEY_ENTER, KEY_KP_ENTER:
			# F1: Enter confirms what is planned (the move, the fire, the attack-move, an armed ram); it never ends a ship
			if mode == "ram":
				_ram_commit()
			elif plan != null or target != "" or not aims.is_empty():
				_confirm()
			elif _can_act():
				hud.toast("Nothing planned. Click a blue hex to plan a move, or an enemy to target it. Space ends the ship.")
		KEY_SPACE:
			# F1 (Ryan, Nov 1): Space ends the ship. Not in its first half second, so a Space pressed to hurry the enemy
			# never ends the ship handed over right after.
			if Time.get_ticks_msec() / 1000.0 - handed_t > 0.5:
				_end_ship("space")
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
		KEY_L:
			hud.toggle_log()
		KEY_C:
			if api.has_method("can_command") and api.phase == "player" and not busy and _api_join() and api.can_command():
				_on_action("command", null)   # #271 (ui_spec.md follow-up G): Command gets its key
		KEY_BACKSPACE:
			_undo("backspace")   # issue 1450: take the last move or turn back, until the ship fires
		KEY_Q:
			_rotate(-1)
		KEY_E:
			_rotate(1)
		KEY_B:
			_order("brace")
		KEY_X:
			_ram_press()
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
	if atk != null and target != "":
		_update_target_plan(target)   # the Burn and fire stop depends on which guns go
	sfx.play("ui_click")
	_refresh_ui()


func _rotate(d: int) -> void:
	var u := _sel_unit()
	if not _can_act() or u.is_empty():
		return
	if not _usable(u):
		return
	# Issue 1589: a turn in place is planned too. The ghost turns on the ship's own hex; nothing reaches the rules until the
	# commit, which turns the ship with the rules' own rotate (as Q/E always did: a skill's free turn and a free pivot are
	# spent there, not here), then fires.
	var own: String = board.key(u["q"], u["r"])
	var hk0: String = board.key(hover.x, hover.y)
	if _usable(u) and atk == null and ((plan != null and plan.has("rot")) or (plan == null and not (reach_alt.has(hk0) and hk0 != own))):
		var rot: int = (int(plan["rot"]) if plan != null else 0) + d
		if rot > 3: rot -= 6
		if rot < -3: rot += 6
		if rot != 0 and not _turns_ok(rot):
			hud.toast("No turn left this activation." if absi(rot) == 1 else "It cannot turn that far in place this activation (it would stop at the middle heading).")
			return
		_plan_step()
		plan = null if rot == 0 else {"q": int(u["q"]), "r": int(u["r"]), "f": posmod(int(u["facing"]) + rot, 6), "cost": 0, "t": absi(rot), "path": [], "rot": rot}
		plan_k = "" if rot == 0 else own
		_aims_check()
		plog.note("plans")
		sfx.play("ui_click")
		_refresh_ui()
		return
	if plan != null and reach_alt.has(plan_k):
		# F1: turning a planned move: the next facing the planned hex can be reached in (nothing is sent to the rules)
		var alts: Array = reach_alt[plan_k]
		var i := maxi(0, alts.find(plan))
		_plan_step()
		plan = alts[posmod(i + (1 if d > 0 else -1), alts.size())]
		_aims_check()
		_refresh_ui()
		return
	var hk: String = board.key(hover.x, hover.y)
	if reach_alt.has(hk) and hk != board.key(u["q"], u["r"]):
		# turning the preview on a hovered hex: pick the next facing that hex can be reached in
		hover_pick[hk] = int(hover_pick.get(hk, _alt_index(hk))) + (1 if d > 0 else -1 + reach_alt[hk].size())
		_overlay()
		return
	# Issue 1589 (Codex on PR 1643, run 2): Q/E never send anything to the rules. With a Burn and fire planned the rules
	# pick its stop and facing, so the ghost stays as it is.
	if atk != null:
		hud.toast("Burn and fire picks its own stop and facing. Click a blue hex to plan the move yourself, or Backspace.")


# Issue 1589: can the ship that is up turn in place by rot steps now (sign = way)? Read on a copy of the rules' own unit with
# canRotate, spending what _rotateUnit_raw spends for each turn (a skill's free turn, then a free pivot, then movement and a
# turn charge). Each step is its own rotate at the commit, and the rules end the activation after a step that leaves the
# ship with no movement and no gun on an enemy (battle_api _done_raw), so a middle heading like that cannot be planned
# through (Codex on PR 1643, run 2). Read only: the copy is thrown away.
func _turns_ok(rot: int) -> bool:
	var n := absi(rot)
	if not _api_join():
		return false
	var ru = api.unit(sel)
	if ru == null:
		return false
	var R = api.R
	var v = R.dup(ru)
	for k in n:
		if not R.canRotate(v):
			return false
		if float(_z0(v.get("treeFreeTurn"))) > 0.0:
			v["treeFreeTurn"] = 0   # a skill's free turn: no movement, no turn charge (Artoo on PR 1643: still checked below)
		else:
			if R.freePivot(v):
				v["pivotUsed"] = true
			else:
				v["mp"] = v["mp"] - 1
				if R.jt(v.get("postFire")):
					v["postMp"] = maxi(0, int(_z0(v.get("postMp"))) - 1)
			v["turnsLeft"] = v["turnsLeft"] - 1
		v["facing"] = posmod(int(v["facing"]) + signi(rot), 6)
		if k < n - 1 and v["mp"] <= 0 and not _any_shot(v):
			return false
	return true


func _any_shot(v) -> bool:
	for w in v["weapons"]:
		if api.R.weaponReady(w):
			for t in api.R.alive("enemy"):
				if api.R.canFire(v, w, t):
					return true
	return false


func _alt_index(hk: String) -> int:
	var st = reach_map[hk]
	var alts: Array = reach_alt[hk]
	return maxi(0, alts.find(st))


func _order(o: String) -> void:
	if sel == "" or not _can_act():
		return
	var id := sel
	if not bool(_ui(id).get("orders", {}).get(o, false)):
		hud.toast("Can't brace after firing." if _sel_unit().get("fired", false) else "This ship can't brace now.")
		return
	_plan_clear()
	plog.act(o)
	if o == "brace":
		plog.close("brace")
	_cmd(func(): return api.order(id, o))


func _next_ship(how := "tab") -> void:
	var act := _active_id()
	if act != "":
		hud.toast("The %s has already started its turn: finish it first (Space ends the ship)." % _name(act))
		return
	var mine := _ready_ships()
	if mine.is_empty():
		return
	var i := mine.find(sel)
	var nid: String = mine[(i + 1) % mine.size()]
	if nid == sel:
		hud.toast("No other ship is ready this round.")
		return
	_tip_retire("fired", "next_ship")
	select(nid, how)
	up_idx = _fleet_index(nid)
	handed_t = Time.get_ticks_msec() / 1000.0
	if not cam.sees(_pos(nid)):
		cam.glide(_pos(nid))


# your ships that can still act this round, in fleet-list order
func _ready_ships() -> Array:
	var out: Array = []
	for u in V.get("units", []):
		if _usable(u) and not u["squadron"]:
			out.append(u["id"])
	return out


func _fleet_index(id: String) -> int:
	var n := 0
	for u in V.get("units", []):
		if u["side"] == "player" and not u["squadron"]:
			if u["id"] == id:
				return n
			n += 1
	return -1


func _active_id() -> String:
	for u in V.get("units", []):
		if u["active"]:
			return str(u["id"])
	return ""


# End ship (Space, the card's button, the top bar): the ship that is up stops (it holds position if it did nothing)
func _end_ship(how: String) -> void:
	if not _can_act():
		return
	var active := _active_id()
	var id := sel
	_tip_retire("fired", "end_ship")
	if _classic():
		_cmd(func(): api.end_turn(); return true)
	elif active == "" and sel != "" and _usable(_sel_unit()):
		plog.close(how if plog.has_acted() else how + "_pass")
		_cmd(func(): api.end_activation(id); return true)
	else:
		plog.close(how)
		_cmd(func(): api.end_activation(); return true)
	sfx.play("ui_confirm")
	sel = ""
	armed = -1
	_plan_clear()


func _end_activation() -> void:
	_end_ship("button")


# Issue 1450 (Ryan, Nov 21 2026, R376): Backspace or the Undo move button takes the ship's last move or turn back. The rules
# allow it only while nothing else has happened since (no shot, ram, boarding, ability, order, Command or dice: view undo).
# Each press takes back one; after the first move is undone the ship is free again and another may go first.
func _undo(how: String) -> void:
	if not _can_act():
		return
	# issue 1589: while a plan is open, Backspace takes back its last step (a target, a turn or a move); nothing reaches the
	# rules. With no plan open it takes back a move the rules already made, as R376 says.
	if not plan_steps.is_empty():
		_plan_back(how)
		return
	if not api.has_method("undo"):
		return
	var id := _active_id()
	if id == "":
		id = sel
	var u: Dictionary = VU.get(id, {})
	if u.is_empty() or not bool(u.get("undo", false)):
		if how == "backspace" and not u.is_empty() and u["side"] == "player":
			hud.toast("Nothing to undo. A move can be taken back only until the ship fires, rams, boards or uses an ability.")
		return
	_plan_clear()
	armed = -1
	mode = ""
	if _cmd(func(): return api.undo(id)):
		plog.act("undo", {"how": how})
		sfx.play("ui_cancel")
		sel = id
		reach_map.clear()   # rebuilt from the restored hex on the next refresh


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
	return h if board.on_board(h.x, h.y) or (board.blocker_visuals != null and board.blocker_visuals.visuals.has(board.key(h.x, h.y))) else Vector2i(99999, 99999)


var _hover_uid := ""


func _on_hover(p: Vector2) -> void:
	# issue 1433: a pointer handler never waits on a worker (see the rules client above)
	_ptr_depth += 1
	_ptr_pos = p
	var h := _ray_hex(p)
	if h != hover:
		hover = h
		board.set_hover(h.x, h.y)
		_overlay()
		# #271: an enemy under the pointer fills the Target block and the Fire odds (they read the hovered enemy)
		var hu := _unit_at(h.x, h.y)
		var hid := str(hu["id"]) if not hu.is_empty() else ""
		if hid != _hover_uid:
			_hover_uid = hid
			if api != null and api.phase == "player" and not busy and target == "" and sel != "":
				if _api_free():
					hud.set_panel(_panel_info())
					hud.set_target(_target_info())
				else:
					_ptr_stale = true   # pending: the publish fills them
	hud.show_tip(_tip(), p)
	_ptr_depth -= 1


func _on_click() -> void:
	if hud.ask_panel != null and is_instance_valid(hud.ask_panel):
		return   # issue 529: a tree prompt is open; answer it first
	if _threat_busy and not busy and not warming and not ended and not retiring and api != null and api.phase == "player" \
			and hover.x != 99999 and _worker_owns_rules():
		# issue 1433: the threat map is still computing; keep this click (once) and play it when the result lands
		if _click_q.is_empty():
			_click_q = {"hex": hover, "gen": _gen, "v": int(api.version), "sel": sel, "mode": mode, "plan_k": plan_k, "target": target}
		return
	if not _can_act() or hover.x == 99999 or not _api_join():
		return
	var u := _unit_at(hover.x, hover.y)
	var s := _sel_unit()
	if mode in ["nova", "blink"] and not s.is_empty():
		var m := mode
		var ok := false
		for h in _ability_hexes():
			if int(h["q"]) == hover.x and int(h["r"]) == hover.y:
				ok = true
				break
		mode = ""
		if ok:
			var id := sel
			var hx := {"q": hover.x, "r": hover.y}
			plog.act("ability", {"ab": m})
			_cmd(func(): return api.ability(id, {"hex": hx}))
		else:
			_refresh_ui()
		return
	if mode == "ram":
		# issue 1444: a click on the rammed ship commits the armed ram; any other click drops it and acts as normal
		mode = ""
		var rm = _ui(sel).get("ram")
		if rm is Dictionary and not u.is_empty() and str(u["id"]) == str(rm["target"]):
			_ram_commit()
			return
	if mode == "board" and not s.is_empty():
		mode = ""
		if not u.is_empty() and u["side"] == "enemy":
			var id := sel
			var tid: String = u["id"]
			plog.act("board", {"target": str(u.get("cls", ""))})
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
		if u["id"] == sel:
			if plan != null and plan_k == board.key(int(u["q"]), int(u["r"])):
				_confirm()   # issue 1589: the ghost turned on the ship's own hex; a click on it commits, as on any planned hex
			elif plan != null or target != "" or not aims.is_empty():
				_cancel("click")
			return
		var act := _active_id()
		if act != "" and act != u["id"]:
			# the rules keep the acting ship up until it ends: show the other ship, and say how to finish this one
			inspect = u["id"]
			plog.note("inspects")
			hud.toast("The %s is mid-turn: finish it first (Space ends the ship)." % _name(act))
			_refresh_ui()
			return
		if not _usable(u):
			inspect = u["id"]
			_refresh_ui()
			return
		select(u["id"], "pick")
		up_idx = _fleet_index(u["id"])
		handed_t = Time.get_ticks_msec() / 1000.0
		return
	if not u.is_empty() and u["side"] == "enemy":
		# F1 (R63, Ryan Nov 1): clicking an enemy never fires. The first click targets it (or only inspects it when the
		# ship that is up cannot reach it); a second click on the same enemy, Enter, or the card's Fire button commits.
		if _usable(s):
			if (atk != null and target == u["id"]) or _aimed(str(u["id"])):
				_confirm()
				return
			_target(u["id"])
			return
		inspect = u["id"]
		plog.note("inspects")
		_refresh_ui()
		return
	var hk: String = board.key(hover.x, hover.y)
	if not s.is_empty() and reach_map.has(hk) and _usable(s):
		# F1: the first click plans the move (the ghost); a second click on the same hex, Enter or Move here commits it
		if plan != null and plan_k == hk:
			_confirm()
			return
		_plan_step()
		plan = _hover_state(hk)
		plan_k = hk
		if atk != null:
			target = ""   # Codex on PR 1643: the Burn and fire target is no pick of the new plan
		atk = null
		_aims_check()   # issue 1589: picks that still bear from the new ghost stay
		plog.note("plans")
		sfx.play("ui_click")
		_refresh_ui()
		return
	if plan != null or target != "" or not aims.is_empty():
		_cancel("click")
		return
	if inspect != "":
		inspect = ""
		_refresh_ui()


# F1: target an enemy with the ship that is up (no rules call that changes anything)
# Issue 1589: the guns that bear go into the plan as one pick, fired from the ghost when a move is planned. A second enemy
# takes the guns still free. An enemy no gun reaches from here, with nothing planned yet, plans a Burn and fire instead.
func _target(tid: String) -> void:
	inspect = tid
	plog.note("targets")
	var guns := _firing_set(tid)
	if not guns.is_empty():
		_plan_step()
		atk = null
		aims.append({"tid": tid, "guns": guns})
		target = tid
		armed = -1
		sfx.play("ui_confirm", {"gain": 0.707946})
	elif aims.is_empty():
		# Burn and fire, also over a planned move (Artoo on PR 1643): the ghost goes to the stop the rules pick for this
		# target, as one more step that Backspace takes back
		_plan_step()
		var had = plan
		var had_k := plan_k
		plan = null
		plan_k = ""
		_update_target_plan(tid)
		if target != "":
			sfx.play("ui_confirm", {"gain": 0.707946})
		else:
			plan_steps.pop_back()
			plan = had
			plan_k = had_k
			hud.toast(("No ready gun bears on %s from the planned hex, and no stop on the way reaches it." % _name(tid)) if had != null else _cant_fire_reason(tid))
	elif _firing_set(tid, false).is_empty():
		hud.toast(("No ready gun bears on %s from the planned hex." % _name(tid)) if plan != null else _cant_fire_reason(tid))
	else:
		hud.toast("Every gun that bears on %s is already aimed. Backspace takes the last pick back." % _name(tid))
	_refresh_ui()


func _gun_aimed(i: int) -> bool:
	for a in aims:
		if int(i) in (a["guns"] as Array):
			return true
	return false


func _aimed(tid: String) -> bool:
	for a in aims:
		if str(a["tid"]) == tid:
			return true
	return false


# what the plan looked like before this step (Backspace goes back to it)
func _plan_step() -> void:
	plan_steps.append({"plan": plan, "k": plan_k, "target": target, "atk": atk, "aims": aims.duplicate(true), "armed": armed})


func _plan_back(how: String) -> void:
	var s: Dictionary = plan_steps.pop_back()
	plan = s["plan"]
	plan_k = s["k"]
	target = s["target"]
	atk = s["atk"]
	aims = s["aims"]
	armed = int(s["armed"])
	plog.note("steps back")
	if how == "backspace":
		sfx.play("ui_cancel")
	_refresh_ui()


func _plan_clear() -> void:
	plan = null
	plan_k = ""
	target = ""
	atk = null
	aims = []
	plan_steps = []


# after the ghost moves or turns: keep each pick's guns that still bear from it, and say which picks fell away
func _aims_check() -> void:
	if aims.is_empty():
		return
	var keep: Array = []
	var lost := PackedStringArray()
	var taken: Array = []
	for a in aims:
		var ok: Array = []
		for i in _firing_set(str(a["tid"]), false, [-1]):
			if i in a["guns"] and i not in taken:
				ok.append(i)
		taken.append_array(ok)
		if ok.is_empty():
			lost.append(_name(str(a["tid"])))
		else:
			keep.append({"tid": a["tid"], "guns": ok})
	aims = keep
	if not _aimed(target):
		target = "" if aims.is_empty() else str(aims[-1]["tid"])
	if not lost.is_empty():
		hud.toast("No gun bears on %s from here: that pick is dropped." % ", ".join(lost))


func _update_target_plan(tid: String) -> void:
	atk = null
	if not _firing_set(tid).is_empty():
		target = tid
		return
	# Out of reach from here: show the stop and path only if the current guns can fire on the way.
	atk = _attack_move(tid) if int(_sel_unit().get("moveLeft", 0)) > 0 else null
	target = tid if atk != null else ""


# F1: drop the plan or the target; nothing was sent to the rules, so nothing changes
func _cancel(why: String) -> void:
	if plan != null or target != "" or not aims.is_empty():
		plog.note("cancels")
	if mode == "ram":
		mode = ""
	_plan_clear()
	wing_sel = ""
	sfx.play("ui_cancel")
	_refresh_ui()


# F1: commit what is planned, once: the move, the attack-move, or the fire on the target
func _confirm() -> void:
	if not _can_act() or not _usable(_sel_unit()) or not _api_join():
		return
	if mode == "ram":
		_ram_commit()   # issue 1444: the armed ram's second step
		return
	var id := sel
	var tid := target
	if atk != null and tid != "":
		var wsel = atk["weapons"]
		plog.act("attack_move", {"cost": int(atk["st"].cost), "guns": int(atk["n"]), "target": str(VU.get(tid, {}).get("cls", "")), "tid": tid})
		_plan_clear()
		armed = -1
		sfx.play("ui_confirm")
		_cmd(func(): return api.attack_move(id, tid, wsel))
		return
	# Issue 1589 (Ryan, Nov 22 2026): the commit. The planned move and every planned volley go to the rules in one command,
	# so they come back as one batch and play as one event (issue 1581's hand-off turns the guns onto the first target while
	# the hull brakes). A pick the move made impossible (damage on the way, the ship lost) is dropped and the toast says so.
	var st = plan
	var rot := 0
	if st != null and st.has("rot"):
		rot = int(st["rot"])   # a turn in place: the rules' rotate, once per step, as Q/E always did
		st = null
	elif st != null and int(st.cost) == 0 and int(st.q) == int(_sel_unit()["q"]) and int(st.r) == int(_sel_unit()["r"]) and int(st.f) == int(_sel_unit()["facing"]):
		st = null   # the ghost is where the ship already sits: nothing to move
	var picks: Array = aims.duplicate(true)
	if st == null and rot == 0 and picks.is_empty():
		return
	_plan_clear()
	armed = -1
	if st != null:
		plog.act("move", {"cost": int(st.cost), "to": "%d,%d" % [int(st.q), int(st.r)], "f": int(st.f)})
	if rot != 0:
		plog.act("rotate", {"d": rot})
	for pk in picks:
		plog.act("fire", {"guns": (pk["guns"] as Array).size(), "target": str(VU.get(str(pk["tid"]), {}).get("cls", "")), "tid": str(pk["tid"]), "planned": st != null})
	sfx.play("ui_confirm", {"gain": 0.707946} if picks.is_empty() else {})
	var dropped: Array = []   # an Array, not a packed one: the lambda below must add to this same list
	var moved_ok := [true]
	_cmd(func():
		var any := false
		if st != null:
			if not api.move(id, st):
				moved_ok[0] = false
				return false
			any = true
		for k in absi(rot):
			if not api.rotate(id, signi(rot)):
				moved_ok[0] = any
				break
			any = true
		for pk in picks:
			var t_id := str(pk["tid"])
			var shot := false
			var lost := false
			for i in pk["guns"]:
				var me = api.unit(id)
				var tu = api.unit(t_id)
				if me == null or _jt(me.get("dead")) or api.phase != "player":
					lost = true
					break
				if tu == null or _jt(tu.get("dead")):
					break
				if api.can_fire(id, int(i), t_id) and api.fire(id, int(i), t_id):
					shot = true
					any = true
				else:
					lost = true
			if lost or not shot:
				dropped.append(_name(t_id))
		return any)
	if not moved_ok[0]:
		hud.toast("That move or turn can no longer be made from here. Plan it again.")
	elif not dropped.is_empty():
		hud.toast("Not every planned shot could fire after the move (%s). The card shows what is left." % ", ".join(PackedStringArray(dropped)))


# F1: after the picture has caught up with the rules in the player's phase: keep the acting ship up, end a ship that has
# nothing left to do, or hand over the next ready ship (the camera glides to it when it is not already in view)
func _after_batches() -> void:
	if bot or showcase or ended or api == null or warming or api.phase != "player":
		return
	var active := _active_id()
	# the play log: an entry whose ship stopped without our End (the rules ended it, or it died)
	if plog.is_open() and plog.open_for() != active:
		var lu: Dictionary = VU.get(plog.open_for(), {})
		if lu.is_empty() or lu.get("dead", false):
			plog.close("died")
		elif lu.get("activated", false):
			_tip_retire("fired", "activation_complete")
			plog.close("rules")
	if target != "" and (not VU.has(target) or VU[target]["dead"]):
		target = ""
		atk = null
	if active != "":
		if sel != active:
			sel = active
			_update_reach()
		if _nothing_left(active):
			_auto_end(active)
		return
	if sel != "" and _usable(_sel_unit()):
		return
	_hand_over()


func _hand_over() -> void:
	var ready := _ready_ships()
	if ready.is_empty():
		return
	var pick: String = ready[0]
	for id in ready:
		if _fleet_index(id) > up_idx:
			pick = id
			break
	tip_handed = true
	select(pick, "auto")
	up_idx = _fleet_index(pick)
	handed_t = Time.get_ticks_msec() / 1000.0
	if chime_round != int(V.get("round", 0)):
		chime_round = int(V.get("round", 0))
		sfx.turn("player")
	if not opening and not cam.sees(_pos(pick)):
		cam.glide(_pos(pick))


# true when the acting ship cannot do anything more this round: no movement left, no gun that can fire at any enemy,
# no ability, boarding or ram, and no brace (turning in place is not counted: see docs/shots/f1 README, vetoable)
func _nothing_left(id: String) -> bool:
	var u: Dictionary = VU.get(id, {})
	if u.is_empty() or u["dead"] or not u["active"]:
		return false
	if int(u.get("moveLeft", 0)) > 0:
		return false
	var ui := _ui(id)
	if ui.is_empty():
		return false
	for w in ui.get("weapons", []):
		for t in w.get("targets", []):
			if t.get("can", false):
				return false
	if bool(ui.get("ability", {}).get("ready", false)):
		return false
	if not (ui.get("board", []) as Array).is_empty() or ui.get("ram") != null:
		return false
	if bool(ui.get("orders", {}).get("brace", false)):
		return false
	return true


func _auto_end(id: String) -> void:
	if ending:
		return
	ending = true
	hud.toast("The %s has nothing left to do this round: next ship." % _name(id))
	_refresh_ui()
	await get_tree().create_timer(0.8).timeout
	ending = false
	if is_inside_tree() and not ended and _can_act() and _active_id() == id and _nothing_left(id):
		_end_ship("nothing_left")


# F1 (Opus, Nov 1, vetoable): in a swarm phase your strike craft fly together. From a run of your squadrons'
# activations, every wing's first move starts at once; their shots then play in the rules' order. Presentation only:
# the events and their order in the rules are unchanged, the picture just overlaps the burns.
func _is_wing(id) -> bool:
	var u: Dictionary = VU.get(id, {})
	if u.is_empty() and views.has(id):
		u = views[id].u
	return bool(u.get("squadron", false))


func _wings_together(evs: Array, i: int, pre: Dictionary) -> void:
	var picks: Array = []
	var seen := {}
	var j := i
	while j < evs.size():
		var x: Dictionary = evs[j]
		if x["t"] in ["round", "side", "end"]:
			break
		if x["t"] == "activation" and not (str(x.get("side", "")) == "player" and _is_wing(x["unit"])):
			break
		if x["t"] == "move" and not pre.has(j) and _is_wing(x["unit"]) and _side(x["unit"]) == "player" and not seen.has(str(x["unit"])):
			seen[str(x["unit"])] = true
			picks.append(j)
		j += 1
	if picks.size() < 2:
		return
	var ids: Array = []
	for k in picks:
		pre[k] = true
		ids.append(evs[k]["unit"])
		_play_move(evs[k]["unit"], evs[k]["path"], false)   # not awaited: the burns overlap
	wings_together.emit(ids.size())
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 12000:
		await get_tree().process_frame
		var any := false
		for id in ids:
			var sv = views.get(id)
			if sv != null and not sv.dead and sv.busy():
				any = true
		if not any:
			break


# F1: the enemy's turn strip: whose ship is acting and how far through their ships this round the enemy is
func _enemy_phase(uid: String) -> void:
	_clear_fire_feedback()
	var total := 0
	var done := 0
	for u in V.get("units", []):
		if u["side"] == "enemy" and not u["squadron"] and not u["dead"]:
			total += 1
			if u["activated"]:
				done += 1
	var F = TBL.get("FACTIONS", {}).get(_enemy_fac(), {})
	var fname := str(F.get("n", "Enemy")) if F is Dictionary else "Enemy"
	var who := ""
	if uid != "" and VU.has(uid):
		if VU[uid]["squadron"]:
			who = "  ·  their wings attack"
		else:
			done = mini(done + 1, maxi(total, 1))
			who = "  ·  [color=#e2d2ff]%s[/color]  ·  ship %d of %d" % [_name(uid), done, total]
	hud.set_phase("enemy", "[b][color=#c4a4ff]ENEMY TURN[/color][/b]  ·  %s%s  ·  [color=#8d86a0]Enter hurries[/color]" % [fname, who], float(done) / maxf(1.0, float(total)))


# F1: reinforcements arrive with a flash, a banner, a toast naming them and a camera nudge.
func _arrive(list: Array) -> void:
	for u in list:
		_make_view(u)
		arrived[str(u["id"])] = int(V.get("round", 0))
	if bot:
		return
	arrival.emit(list)
	var mine: Array = list.filter(func(x): return x["side"] == "player")
	var c := Vector3.ZERO
	var arrival_index := 0
	for u in list:
		var p: Vector3 = board.hex_world(int(u["q"]), int(u["r"]))
		sfx.play("arrive_jump", {"pos": p, "rate": 0.92 if u["side"] == "enemy" else 1.0, "delay": arrival_index * 0.14})
		arrival_index += 1
		c += p
		_flash(p + Vector3(0, 2, 0), 24.0, Color(0.6, 0.9, 1.0) if u["side"] == "player" else Color(1.0, 0.5, 0.4), 0.6)
		_float(u["id"], "Arrived", Color("#52f0c4") if u["side"] == "player" else Color("#ff8a72"), -30)
	c /= float(list.size())
	var names := " and ".join(PackedStringArray(list.map(func(x): return Campaign.ship_with_article(str(x["name"])))))
	if not mine.is_empty():
		hud.banner("Reinforcements", Color("#52f0c4"), 1.4)
		hud.toast("Reinforcements: %s %s your fleet." % [names, "joins" if list.size() == 1 else "join"])
	else:
		hud.banner("Enemy reinforcements", Color("#ff8a6a"), 1.4)
		hud.toast("Enemy reinforcements: %s %s arrived." % [names, "has" if list.size() == 1 else "have"])
	var keep := {"t": cam.t}
	cam.glide(c, 1.0)
	await get_tree().create_timer(1.6).timeout
	if follow or mine.is_empty():
		cam.glide(keep["t"], 0.9)


func _clear_fire_feedback() -> void:
	hud.show_tip("", Vector2.ZERO)
	if hud.toast_lbl.text == NO_READY_GUN_IN_RANGE:
		hud.toast("")


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
		return NO_READY_GUN_IN_RANGE
	if not in_arc:
		return "No ready gun points at it. Turn the ship (Q/E) or move."
	return _blocker_text(VU.get(t_id, {}))


func _shot_blockers(t: Dictionary) -> Array:
	var u := _sel_unit()
	if u.is_empty() or t.is_empty(): return []
	return api.line_blockers(u, t)

func _blocker_text(t: Dictionary) -> String:
	var names := PackedStringArray()
	for h in _shot_blockers(t):
		var label: String = {"rock": "asteroid", "hulk": "wreck", "deadstar": "Hollow Sun"}.get(h.kind, h.kind)
		names.append("the %s at %d,%d" % [label, h.q, h.r])
	return "Blocked by %s." % ", ".join(names) if not names.is_empty() else "Line of sight is blocked."


func _tip() -> String:
	if hover.x == 99999 or busy or not _api_join() or api.phase != "player":
		return ""
	var u := _unit_at(hover.x, hover.y)
	var s := _sel_unit()
	# issue 1444: an armed ram, a boarding pick or a nova aim shows its own forecast first
	if mode == "nova" and _usable(s):
		return _nova_tip(hover.x, hover.y)
	var rm0 = _ui(sel).get("ram") if mode == "ram" else null
	if rm0 is Dictionary and _usable(s) and not u.is_empty() and str(u["id"]) == str(rm0["target"]):
		return _ram_forecast(sel)
	if mode == "board" and _usable(s) and not u.is_empty() and u["side"] == "enemy":
		return _board_tip(sel, str(u["id"]))
	if not u.is_empty() and u["side"] == "enemy" and _usable(s):
		return _attack_tip(u["id"])
	if not u.is_empty():
		return _ship_tip(u) + ("\n" + api.entry_reason(sel, hover.x, hover.y) if not s.is_empty() and u.id != s.id else "")
	var hk: String = board.key(hover.x, hover.y)
	if reach_map.has(hk):
		var st = plan if (plan != null and hk == plan_k) else _hover_state(hk)
		var t := "[b][color=#7fc4ff]%s[/color][/b]\n%d movement%s." % ["Planned move" if hk == plan_k else "Move here", int(st.cost), (", %d turn%s" % [int(st.get("t", 0)), "" if int(st.get("t", 0)) == 1 else "s"]) if int(st.get("t", 0)) > 0 else ""]
		if int(st.get("gunsOf", 0)) > 0:
			t += "\n%d of %d guns bear on an enemy from here." % [int(st.get("guns", 0)), int(st.get("gunsOf", 0))]
		if _danger_shown() and _threat_current() and not s.is_empty():
			var nh := int(_danger.get(hk, 0))
			var nn := int(_danger.get(board.key(int(s["q"]), int(s["r"])), 0))
			if nh > 0 or nn > 0:
				t += "\n[color=#c4a4ff]%d enem%s can reach this hex[/color] [color=#7c8674]now %d[/color]" % [nh, "y" if nh == 1 else "ies", nn]
		var wl := _well_line(hover.x, hover.y)
		if wl != "":
			t += "\n" + wl
		t += "\n[color=#7c8674]Q/E change the facing. %s[/color]" % ("Click again or Enter to go. Esc cancels." if hk == plan_k else "Click to plan the move (nothing moves yet).")
		return t
	if board.zone_of.has(hk):
		var zi := {"exit": ["Exit", "A ship that ends its move here jumps clear of the battle."], "texit": ["Transport exit", "An enemy transport that reaches this edge gets through."],
			"guard": ["Station perimeter", "Every enemy ship this close to the station at the start of a round knocks out 1 integrity."]}.get(board.zone_of[hk], ["", ""])
		return "[b]%s[/b]\n%s" % [zi[0], zi[1]]
	var terr := str(V["terrain"].get(hk, ""))
	if terr != "":
		var info = TBL.get("TERRAIN_INFO", {}).get(terr, {})
		if info is Dictionary and not info.is_empty():
			var text := "[b]%s[/b]\n%s" % [str(info.get("n", terr)), str(info.get("fx", info.get("d", "")))]
			if TBL.get("BLOCKING", {}).get(terr, false) or not s.is_empty():
				text += "\n" + api.entry_reason(sel, hover.x, hover.y)
			return text
		return "[b]%s[/b]" % terr.capitalize()
	return api.entry_reason(sel, hover.x, hover.y) if not s.is_empty() else ""


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
	var mods: Array = api.R.storyModifierLines()
	if not mods.is_empty(): desc += "\n" + " ".join(PackedStringArray(mods))
	hud.set_legend(title, desc.strip_edges(), rows)


func _ship_tip(u: Dictionary) -> String:
	var col := "#52f0c4" if u["side"] == "player" else "#c4a4ff"
	var d: Dictionary = disp.get(u["id"], {"hp": u["hp"], "sh": u["sh"]})
	var t := "[b][color=%s]%s%s[/color][/b]\n[color=#a7b09d]%s[/color]\nHull [color=#ffad3b]%s/%s[/color]" % [col, "\u2605 " if u["flagship"] else "", str(u["name"]), _class_label(u["cls"]), Campaign.hull_text(d["hp"]), Campaign.hull_text(u["maxHp"])]
	if float(u["shMax"]) > 0:
		var parts: Array = []
		for i in 4:
			parts.append(str(int(d["sh"][i])))
		t += "   Shield pool [color=#92b8e8]%d[/color]/%d; sides [color=#92b8e8]%s[/color]" % [int(_z0(u.get("shp"))), int(u["shMax"]), " ".join(parts)]
	if u["side"] == "player" and u["activated"]:
		t += "\n[color=#7c8674]Already acted this round.[/color]"
	return t


func _target_defenses(u: Dictionary) -> String:
	return "armor %d%%, evasion %d" % [int(round(float(u.get("armor", 0)) * 100.0)), int(_z0(u.get("ev"))) + int(_z0(u.get("evBuff")))]


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
	# The same weapon set as the activation card: from the ghost when a move is planned (issue 1589).
	var firing := _shown_set(t_id)
	var volley := _volley_preview(sel, firing, t_id, plan)
	var idx: Array = [armed] if armed >= 0 else range(su["weapons"].size())
	for i in idx:
		var vw: Dictionary = su["weapons"][i]
		var w = ru["weapons"][i]
		var tg := _wtarget(sel, i, t_id)
		if plan == null:
			quad = int(tg.get("quad", quad))
			rear = bool(tg.get("rear", rear))
		var right := ""
		if i in firing:
			tg = tg.duplicate()
			tg.merge(volley[i], true)
			hull += float(tg.get("hull", 0))
			sh += float(tg.get("shield", 0))
			n += 1
			right = "[b][color=#ffb23e]%d%%[/color][/b] [color=#7c8674]%d\u00d7%d[/color]" % [int(tg.get("hit", 0)), int(w["shots"]), int(round(float(tg.get("dmgMult", 0))))]
		elif float(_z0(vw.get("off"))) > 0:
			right = "[color=#ff8a72]offline[/color]"
		elif float(_z0(vw.get("cd"))) > 0:
			right = "[color=#7c8674]reloading[/color]"
		elif not vw["ready"]:
			right = "[color=#7c8674]fired[/color]"
		elif vw["kind"] == "flak":
			right = "[color=#7c8674]point defense[/color]"
		elif su["braced"]:
			right = "[color=#7c8674]braced[/color]"
		elif plan != null:
			right = "[color=#7c8674]%s[/color]" % ("aimed at another target" if _gun_aimed(i) else "no shot from the ghost")
		elif not tg.get("inRange", false):
			right = "[color=#7c8674]out of range (%d/%d)[/color]" % [int(tg.get("range", 0)), int(vw["range"])]
		elif not tg.get("inArc", false):
			right = "[color=#7c8674]out of arc[/color]"
		elif not tg.get("los", false):
			right = "[color=#7c8674]blocked[/color]"
		rows += "%s  %s\n" % [str(vw["name"]), right]
	if plan != null:
		# Codex on PR 1643: the side it hits and the rear arc are read from the ghost, as the damage is
		var gsrc = api.R.stateView(ru, plan)
		quad = int(api.R.shieldQuad(tu, gsrc))
		rear = bool(api.R.treeIsRear(gsrc, tu, quad))
	var t := "[b][color=#ff8a72]%s[/color][/b]\n[color=#a7b09d]Hull %s/%s, %s[/color]\n" % [str(tv["name"]), Campaign.hull_text(tv["hp"]), Campaign.hull_text(tv["maxHp"]), _target_defenses(tu)]
	if float(tv["shMax"]) > 0:
		t += "Hits the [color=#92b8e8][b]%s shield[/b][/color] (pool [color=#92b8e8]%d[/color]/%d, this side catches %d)%s." % [QUAD_NAME[quad], int(_z0(tu.get("shp"))), int(tv["shMax"]), int(tv["sh"][quad]), " [color=#ffad3b]down, straight to hull[/color]" if float(_z0(tu.get("shp"))) < 1 else ""]
		if quad in _routed_sides(tv) and float(_z0(tu.get("shp"))) >= 1:
			t += " [color=#9fd4ff]Its power is routed to this side: it catches more, but each hit drains the pool 30% faster.[/color]"   # issue 1446 (R246)
	else:
		t += "Target is unshielded: [color=#ffad3b]every hit lands on the hull[/color]."
	if rear:
		t += " [color=#ffb23e]Rear arc: armor halved, +15% crit.[/color]"
	if plan != null:
		t += "\n[color=#7fc4ff]From the ghost (nothing has moved yet).[/color]"
	t += "\n" + rows
	if not _shot_blockers(tv).is_empty(): t += "[color=#ffb875]%s[/color]\n" % _blocker_text(tv)
	if n > 0:
		t += "Expected: about [color=#92b8e8]%d shield[/color] and [color=#ffad3b]%d hull[/color] damage.\n[color=#ff8a3a]%s[/color]" % [int(round(sh)), int(round(hull)),
			("Aimed. Click again or Enter to play the plan (%d weapon%s here)." % [n, "s" if n > 1 else ""]) if _aimed(t_id) else "Click to aim (nothing fires yet)."]
	else:
		var am = (atk if (target == t_id and atk != null) else (_attack_move(t_id) if int(su.get("moveLeft", 0)) > 0 else null))
		if am != null:
			t += "[color=#ff8a3a]Out of reach from here. %s[/color]" % (("Planned: burn %d movement to the ghost and fire %d weapon%s on the way. Click again or Enter to go." % [int(am["st"].cost), int(am["n"]), "s" if int(am["n"]) > 1 else ""]) if target == t_id else "Click to see the attack-move: where the ship would stop and what would fire.")
		else:
			t += "[color=#7c8674]No ready weapon can reach this target.[/color]"
	return t


func _on_action(name: String, arg) -> void:
	sfx.play("ui_click")
	match name:
		"end":
			_end_ship("button")
		"undo":
			_undo("button")
		"next":
			_next_ship("next_button")
		"confirm":
			_confirm()
		"cancel":
			_cancel("button")
		"pick":
			var u: Dictionary = VU.get(arg, {})
			if not u.is_empty():
				var act := _active_id()
				if act != "" and act != str(arg):
					inspect = str(arg)
					hud.toast("The %s is mid-turn: finish it first (Space ends the ship)." % _name(act))
					_refresh_ui()
				else:
					select(arg, "roster")
					if _usable(u):
						up_idx = _fleet_index(str(arg))
						handed_t = Time.get_ticks_msec() / 1000.0
				cam.glide(_pos(arg), 0.8)
		"arm":
			_arm(int(arg))
		"brace":
			_order("brace")
		"ability":
			if sel != "" and _can_act():
				var id := sel
				var ab := str(_sel_unit().get("ab", ""))
				if ab in ["nova", "blink"]:
					mode = "" if mode == ab else ab
					hud.toast({"nova": "Click a hex 3 to 9 ahead for the spinal shell.", "blink": "Click an open hex within 3 to jump to."}[ab])
					_refresh_ui()
				else:
					plog.act("ability", {"ab": ab})
					_cmd(func(): return api.ability(id))
		"ram":
			_ram_press()
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
			_tip_dismiss("got_it")
		"tip_off":
			_tip_dismiss("off")
			tips_off = true
			_save_opts()
		"command":
			# the game asks for a second tap to confirm the once-per-battle Command
			var now := Time.get_ticks_msec() / 1000.0
			if now - cmd_armed_t > 3.0:
				cmd_armed_t = now
				hud.toast("Click Command again to give the order: %s" % _command_label())
				_refresh_ui()
				get_tree().create_timer(3.05, true, false, true).timeout.connect(func() -> void:
					if cmd_armed_t == now:
						_refresh_ui(), CONNECT_ONE_SHOT)
			else:
				cmd_armed_t = -9.0
				plog.act("command")
				# issue 529: a picked "you may" skill asks yes or no first (the rules hold the prompt; answering gives the Command)
				if api.has_method("command_or_ask"):
					_cmd(func(): return api.command_or_ask() != "")
				else:
					_cmd(func(): return api.command())
		"ask":
			var opt := str(arg)
			plog.act("ask " + opt)
			hud.hide_ask()
			_cmd(func(): return api.answer(opt))
		"role":
			var rid := sel
			_cmd(func(): return api.change_role(rid))
		"stance":
			var sid := sel
			var stn := str(arg)
			_cmd(func(): return api.stance(sid, stn))
		"menu":
			_open_menu()
		"keys":
			_open_controls()
		"log_setting":
			hud.set_log_preferences(not hud.log_enabled, hud.log_collapsed)
			option_changed.emit("battle_log_enabled", hud.log_enabled)
			_open_controls()
		"log_collapse":
			hud.set_log_preferences(hud.log_enabled, not hud.log_collapsed)
			option_changed.emit("battle_log_collapsed", hud.log_collapsed)
		"grid":
			var gb = board.get("_look_btn") if board != null else null
			if gb is Button and (gb as Button).visible:
				(gb as Button).button_pressed = not (gb as Button).button_pressed
			_open_menu()
		"log":
			hud.toggle_log()
		"menu_close":
			hud.hide_menu()
		"report":
			# the browser's Report a problem: the battle's facts, the errors and the log, ready to paste
			var lines: Array = Array(hud.log_text.get_parsed_text().split("\n"))
			var rep := {"version": ProjectSettings.get_setting("application/config/version", "dev"), "round": V.get("round"), "phase": api.phase if api != null else "",
				"seed": api.world_info().get("seed") if api != null and api.has_method("world_info") else null, "errors": errors, "log": lines.slice(maxi(0, lines.size() - 60))}
			DisplayServer.clipboard_set(JSON.stringify(rep, "  "))
			hud.toast("Problem report copied to the clipboard. Paste it wherever you report bugs.")
		"opt":
			_toggle_opt(str(arg))
		"to_title":
			hud.hide_menu()
			ended = true
			result = {"result": "quit", "rounds": int(V.get("round", 0)), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
			_play_log_out("quit")
			_finish(result)
		"save_quit", "save_quit_older":
			if ended or not round_save_cb.is_valid():
				return
			# Save and quit is offered only while this round's save is on disk (a failed write offers the older start instead,
			# by name), so leaving never promises more than Continue will load; the host still tries to write a newer round
			if name == "save_quit" and round_on_disk != round_saved:
				_open_menu()
				return
			hud.hide_menu()
			ended = true
			result = {"result": "save_quit", "rounds": int(V.get("round", 0)), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
			_play_log_out("quit")
			_finish(result)
		"continue":
			hud.hide_end()
			_finish(result)
		"retreat":
			if can_retreat and _can_act():
				ended = true
				result = {"result": "retreat", "rounds": int(V["round"]), "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
				_play_log_out("retreat")
				_finish(result)
		"restart":
			hud.hide_end()
			hud.hide_menu()
			args.erase("seed")
			start_default()
		"quit":
			_quit()


# ---------------------------------------------------------------- issue 529: the tree prompts

var roles_opened := false


func _sync_ask() -> void:
	var a = V.get("ask")
	if a is Dictionary and not ended:
		hud.show_ask(a)
	elif hud.ask_panel != null:
		hud.hide_ask()
	# the Chorus role prompt opens once, when the player first has the battle (never for the bot or a showcase)
	if not roles_opened and not bot and not showcase and not opening and not warming and not ended and api.phase == "player" and not busy and api.has_method("roles_open"):
		roles_opened = true
		_open_roles.call_deferred()


func _open_roles() -> void:
	_cmd(func(): return api.roles_open())


# --tree-shots <dir> --tree-shot role|may|callout (issue 529 pictures, with --scenario): "role" the Chorus role prompt at
# battle start and then a ship's role order; "may" Vex's Debt Comes Due yes or no prompt after the Command (C, C);
# "callout" the bot plays until a Roles callout floats over a ship, then the log and the ship's lineage count.
func _tree_shots(kind: String) -> void:
	while busy or warming or api == null:
		await get_tree().process_frame
	await get_tree().create_timer(2.0).timeout
	_end_opening()
	await get_tree().create_timer(1.6).timeout
	_refresh_ui()
	await get_tree().create_timer(0.8).timeout
	if kind == "role":
		for i in 120:
			if hud.ask_panel != null: break
			await get_tree().process_frame
		await _snap("tree_role_prompt")
		while hud.ask_panel != null and is_instance_valid(hud.ask_panel):
			var a: Dictionary = V.get("ask") if V.get("ask") is Dictionary else {}
			_on_action("ask", "strike" if str(a.get("id", "")) != _first_player() else "screen")
			await get_tree().create_timer(0.6).timeout
		select(_first_player())
		cam.focus(_pos(_first_player()), 170.0)
		await get_tree().create_timer(1.2).timeout
		await _snap("tree_role_order")
	elif kind == "may":
		select(_first_player())
		await get_tree().create_timer(0.6).timeout
		_on_action("command", null)
		await get_tree().create_timer(0.3).timeout
		_on_action("command", null)
		for i in 120:
			if hud.ask_panel != null: break
			await get_tree().process_frame
		await get_tree().create_timer(0.6).timeout
		await _snap("tree_may_prompt")
	else:
		for i in 120:
			if hud.ask_panel != null: break
			await get_tree().process_frame
		while hud.ask_panel != null and is_instance_valid(hud.ask_panel):
			_on_action("ask", "strike")
			for i in 30:
				var shown := false
				for f in floats:
					var l: Label = f["lbl"]
					if is_instance_valid(l) and l.text.begins_with("Roles Assigned") and f["t"] > 0.3:
						shown = true
				if shown: break
				await get_tree().process_frame
			if hud.ask_panel == null or not is_instance_valid(hud.ask_panel):
				break
		await _snap("tree_role_callout")   # the callout over the ship and the log line (bottom left)
		await get_tree().create_timer(1.5).timeout
		select(_first_player())
		await get_tree().create_timer(1.0).timeout
		hud._show_dtip()   # the "more on hover" layer: the Admiral lineage block counts each skill this battle
		await get_tree().create_timer(0.5).timeout
		await _snap("tree_role_count")
	_quit_report()


func _first_player() -> String:
	for u in V.get("units", []):
		if u["side"] == "player" and not u["squadron"] and not u["dead"]:
			return str(u["id"])
	return ""


# ---------------------------------------------------------------- in-battle menu (the browser's settings menu in the top bar)

signal option_changed(key: String, value: Variant)


func _open_menu(row := -1) -> void:
	var items: Array = [["Resume", "menu_close"]]
	items.append(["Sound: %s" % ("on" if sfx.on else "off"), "opt", "sound"])
	items.append(["Speed: %s" % ("fast" if user_speed < 1.0 else "normal"), "opt", "speed"])
	items.append(["Movement: %s" % movement, "opt", "movement"])
	items.append(["Follow enemy activations: %s" % ("on" if follow else "off"), "opt", "follow"])
	items.append(["Cut-ins: %s" % {"key": "key moments", "all": "every attack", "off": "off"}.get(cine, cine), "opt", "cine"])
	items.append(["Teaching tips: %s" % ("off" if tips_off else "on"), "opt", "tips"])
	items.append(["Reduce flashing: %s" % ("on" if reduce_flashing else "off"), "opt", "flash"])
	items.append(["Reduce motion: %s" % ("on" if reduce_motion else "off"), "opt", "motion"])
	items.append(["UI scale: %s" % _ui_scale_name(), "opt", "uiscale"])
	items.append(["Screen shake: %s" % ("full" if shake_scale >= 1.0 else ("reduced" if shake_scale > 0.0 else "off")), "opt", "shake"])
	items.append(["Threat map: %s" % ("on" if threat_on else "off"), "opt", "threat"])
	items.append(["Reach hatching: %s" % ("on" if danger_on else "off"), "opt", "danger"])
	items.append(["Firing arcs: %s" % ("on" if arcs_on else "off"), "opt", "arcs"])
	# issue 271 (E1): the view keys that left the screen are listed here (they still work: T, Z, R, Esc)
	items.append(["Top-down view (T)", "top"])
	if board != null and board.get("_look_btn") != null and (board.get("_look_btn") as Button).visible:
		items.append(["Tactical grid: %s (Z)" % ("on" if (board.get("_look_btn") as Button).button_pressed else "off"), "grid"])
	items.append(["Controls", "keys"])
	if external and not in_campaign:
		items.append(["Quit to title", "to_title"])
	elif in_campaign and round_save_cb.is_valid() and round_saved > 0:
		# issue 1451: back here at the start of this round. Artoo on PR 1486: when this round's save did not reach the disk, say
		# what Continue will really load instead of promising this round
		if round_on_disk == round_saved:
			items.append(["Save and quit to title", "save_quit"])
		else:
			items.append(["Quit to title (Continue starts %s)" % (("at round %d" % round_on_disk) if round_on_disk > 0 else "from the last checkpoint"), "save_quit_older"])
	elif not external:
		items.append(["Fight again", "restart"])
	items.append(["Copy a problem report", "report"])
	items.append(["Quit the game", "quit"])
	hud.show_menu("Menu", items, row)


func _open_controls() -> void:
	hud.show_menu("Controls", [["Back", "menu"], ["Floating battle log: %s" % ("On" if hud.log_enabled else "Off"), "log_setting"]], -1, hud.keys_text())


const UI_SCALES := [[0.9, "Small"], [1.0, "Normal"], [1.15, "Large"], [1.3, "Larger"]]


func _ui_scale_name() -> String:
	for o in UI_SCALES:
		if is_equal_approx(float(o[0]), UiScale.player):
			return str(o[1])
	return "Normal"


func _toggle_opt(k: String) -> void:
	# issue 1559 item 18: the menu comes back on the row that was toggled, even after a UI scale rebuild threw it away
	var keep_row: int = hud.menu_row() if hud != null and is_instance_valid(hud) else -1
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
			if tips_off: _tip_dismiss("off")
			option_changed.emit("tips", not tips_off)
		"flash":
			set_fx_opts(not reduce_flashing, shake_scale)
			option_changed.emit("reduce_flashing", reduce_flashing)
		"motion":
			reduce_motion = not reduce_motion
			for vv in views.values():   # issue 1581: no idle drift, bob or trim nod with Reduce motion
				if is_instance_valid(vv):
					vv.calm = reduce_motion
			option_changed.emit("reduce_motion", reduce_motion)
		"uiscale":
			var i := 0
			for j in UI_SCALES.size():
				if is_equal_approx(float(UI_SCALES[j][0]), UiScale.player):
					i = j
			var v := float(UI_SCALES[(i + 1) % UI_SCALES.size()][0])
			UiScale.set_player(v)
			option_changed.emit("ui_scale", v)
			if hud != null and is_instance_valid(hud):
				hud._rebuild()
		"shake":
			set_fx_opts(reduce_flashing, 0.5 if shake_scale >= 1.0 else (0.0 if shake_scale > 0.0 else 1.0))
			option_changed.emit("shake", shake_scale)
		"threat":
			threat_on = not threat_on
		"danger":
			danger_on = not danger_on
		"arcs":
			arcs_on = not arcs_on
	_save_opts()
	_refresh_ui()
	_open_menu(keep_row)


# ---------------------------------------------------------------- HUD refresh

# Issue 1446: the strip at the board edge where the warned reinforcements will come in, from the warning round until
# they land; asked again whenever the rules move on (the arrival hex follows that side's fleet, as the rules pick it)
var _arrival_ver := -1


func _sync_arrival() -> void:
	if board == null or not board.has_method("set_arrival"):
		return
	if ended or showcase or not api.has_method("arrival_strip"):
		board.set_arrival({})
		return
	if _arrival_ver == int(api.version):
		return
	_arrival_ver = int(api.version)
	var a: Dictionary = api.arrival_strip()
	var keys := {}
	for h in a.get("hexes", []):
		keys[board.key(int(h["q"]), int(h["r"]))] = true
	board.set_arrival(keys, str(a.get("side", "enemy")))


func _refresh_ui() -> void:
	if api == null or V.is_empty() or quitting or not is_instance_valid(hud):
		return
	if _worker_owns_rules():
		return   # issue 1433: every read below locks the rules; the publish runs this pass (_threat_done)
	_sync_ask()
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
	if not mine:
		_clear_fire_feedback()
	var turn := "Battle over" if ended or api.phase == "over" else ("Your turn (%d ready)" % pend if mine else "Enemy turn")
	var end_text := "End ship (Space)"
	if _classic():
		end_text = "End turn"
		turn = "Battle over" if ended or api.phase == "over" else ("Your turn" if mine else "Enemy turn")
	var command_ready: bool = api.has_method("can_command") and mine and not busy and api.can_command()
	var command: Dictionary = api.command_info() if mine and api.has_method("command_info") else {}
	hud.set_command(str(command.get("label", "Command")), command_ready, mine and _api_admiral() != "",
		command_ready and Time.get_ticks_msec() / 1000.0 - cmd_armed_t <= 3.0, _command_tip(command))
	if board != null and board.get("_look_btn") != null:
		hud.adopt_grid(board.get("_look_btn"))   # UI pass: board look C's Grid (Z) button goes in the top bar
	_sync_arrival()
	hud.set_info(_battle_info())
	hud.set_top(int(V["round"]), turn, _objective(), end_text, mine and not busy, user_speed < 1.0, threat_on)
	hud.set_nemesis(_nem_info())
	hud.set_retreat(can_retreat and not ended, not (mine and not busy))
	var rows: Array = []
	for u in V["units"]:
		if u["side"] != "player" or u["squadron"] or (u["dead"] and not views.has(u["id"])):
			continue
		var d: Dictionary = disp.get(u["id"], {"hp": u["hp"], "sh": u["sh"]})
		var status := "Lost" if u["dead"] else ("Acting" if u["active"] else ("Done" if u["activated"] else ("Up" if u["id"] == sel and mine else "Ready")))
		var view: ShipView = views.get(u["id"])
		rows.append({"id": u["id"], "name": u["name"], "cls": _class_label(u["cls"]), "code": view.code if is_instance_valid(view) else "", "hp": d["hp"], "maxHp": u["maxHp"], "sh": d["sh"], "shMax": u["shMax"], "shp": _z0(u.get("shp")), "status": status, "sel": u["id"] == sel, "done": u["activated"] or u["dead"], "flag": u["flagship"],
			"new": arrived.has(str(u["id"])) and int(arrived[str(u["id"])]) >= int(V.get("round", 0)) - 1, "danger": 0 if u["dead"] else _danger_at(u)})
	hud.set_roster(rows)
	hud.set_panel(_panel_info())
	hud.set_target(_target_info())
	# F1: the activation card (the ship that is up and how to finish it) and the phase strip
	hud.set_card(_card_info() if mine and not busy and not bot and not showcase else {})
	if showcase or bot or ended or api.phase == "over":
		hud.set_phase("", "")
	elif mine and not busy:
		var up := sel if sel != "" else ""
		hud.set_phase("player", "[b][color=#ff8a3a]YOUR TURN[/color][/b]  ·  Round %d%s  ·  [color=#a7b09d]%d more ready[/color]" % [int(V["round"]),
			("  ·  [color=#e8eee0]%s[/color] is up" % _name(up)) if up != "" else "", maxi(0, pend - (1 if up != "" and not VU.get(up, {}).get("active", false) else 0))])
	for id in views:
		var sv = views[id]
		# the ship that is up: the Hollow Sun's ember (issue 271, R191 retires lime); an enemy volley's target keeps its
		# danger ring through a refresh (issue 1211)
		var aimed := not aim.is_empty() and str(id) == str(aim["t"])
		sv.set_selected(id == sel or aimed, AIM_RING if aimed else EMBER_3D)
	_overlay()
	_tutorial()
	# F1: a click changes what the hovered thing means (targeted, planned): refresh its tip without waiting for the mouse
	if hud.tip.visible and DisplayServer.get_name() != "headless":
		hud.show_tip(_tip(), get_viewport().get_mouse_position())


# F1: the activation card. Which ship is up, its three steps (move, fire, end) with what is left of each, one plain
# sentence on what to do next (never "done" while something is left: the same test as the automatic end), and the buttons.
# Issue 1589: the card's words for the open plan: the move, each pick with its expected damage from the ghost, what is still
# free, and the button that commits it all.
func _plan_text(id: String) -> Dictionary:
	var rows := PackedStringArray()
	var says := PackedStringArray()
	var u := _sel_unit()
	var moves := plan != null and not (int(plan.cost) == 0 and int(plan.q) == int(u["q"]) and int(plan.r) == int(u["r"]) and int(plan.f) == int(u["facing"]))
	if moves:
		var tn := int(plan.get("t", 0))
		var turns := (", %d turn%s" % [tn, "" if tn == 1 else "s"]) if tn > 0 else ""
		if int(plan.q) == int(u["q"]) and int(plan.r) == int(u["r"]):
			rows.append("[color=#7fc4ff]Turn in place[/color]%s (Q/E turn the ghost)." % turns)
			says.append("Turn in place.")
		else:
			rows.append("[color=#7fc4ff]Move:[/color] %d movement%s. The ghost shows where it ends and which way it faces (Q/E turn it)." % [int(plan.cost), turns])
			says.append("Move %d%s." % [int(plan.cost), turns])
	var guns := 0
	for a in aims:
		var set: Array = a["guns"]
		guns += set.size()
		var volley := _volley_preview(id, set, str(a["tid"]), plan)
		var sh := 0.0
		var hl := 0.0
		for i in set:
			sh += float((volley.get(i, {}) as Dictionary).get("shield", 0))
			hl += float((volley.get(i, {}) as Dictionary).get("hull", 0))
		rows.append("[color=#ff8a6a]%d gun%s at %s:[/color] about [color=#92b8e8]%d shield[/color] and [color=#ffad3b]%d hull[/color] damage." % [set.size(), "" if set.size() == 1 else "s", _name(str(a["tid"])), int(round(sh)), int(round(hl))])
		says.append("%d gun%s at %s." % [set.size(), "" if set.size() == 1 else "s", _name(str(a["tid"]))])
	var free := 0
	var seen := {}
	for e in V["units"]:
		if e["side"] == "enemy" and not e["dead"]:
			for i in _firing_set(str(e["id"])):
				seen[int(i)] = true
	free = seen.size()
	if free > 0:
		rows.append("%d more gun%s bear%s %s: click an enemy with a red ring to aim %s." % [free, "" if free == 1 else "s", "s" if free == 1 else "", "from the ghost" if plan != null else "from here", "it" if free == 1 else "them"])
	elif aims.is_empty():
		rows.append("No gun bears from the ghost yet. Move or turn it until an enemy gets a red ring.")
	rows.append("[b]Enter, or click the hex or a target again, plays it all out.[/b] Backspace steps back, Esc clears the plan.")
	var turn_only: bool = plan != null and plan.has("rot")
	var go := ("Turn and fire (Enter)" if turn_only else "Move and fire (Enter)") if moves and guns > 0 else ("Fire %d gun%s (Enter)" % [guns, "" if guns == 1 else "s"] if guns > 0 else ("Turn here (Enter)" if plan != null and int(plan.q) == int(u["q"]) and int(plan.r) == int(u["r"]) else "Move here (Enter)"))
	return {"hint": "\n".join(rows), "say": " ".join(says) if not says.is_empty() else "Planning.", "go": go}


func _card_info() -> Dictionary:
	if _classic() or api == null or api.phase != "player" or ended:
		return {}
	var id := _active_id()
	if id == "":
		id = sel
	if id == "" or not VU.has(id) or not _usable(VU[id]):
		var pend0 := _player_pending()
		if pend0 == 0:
			return {}
		return {"name": "Pick a ship", "tag": "YOUR TURN", "cls": "", "more": "%d ready" % pend0, "steps": [], "hint": "Click one of your ships (green ring) or press Tab.",
			"say": "Pick a ship: click one of yours or press Tab.",
			"buttons": [{"text": "Next ship (Tab)", "act": "next", "on": true, "big": true}]}
	var u: Dictionary = VU[id]
	var ui := _ui(id)
	var ru = api.unit(id)
	var mleft := int(u.get("moveLeft", u["mp"]))
	var speed_v := int(_z0(ru.get("speed"))) if ru != null else mleft
	var moved := ru != null and (int(_z0(ru.get("hexMoved"))) > 0 or float(ru.get("mp", 0)) < float(speed_v))
	var fired := bool(u.get("fired", false))
	var guns := 0
	var ready := 0
	var bear := 0
	for w in u["weapons"]:
		if w["kind"] == "flak":
			continue
		guns += 1
		if w["ready"]:
			ready += 1
	for w in ui.get("weapons", []):
		for t in w.get("targets", []):
			if t.get("can", false):
				bear += 1
				break
	var nothing := _nothing_left(id)
	var braced: bool = u["braced"]
	var can_brace := bool(ui.get("orders", {}).get("brace", false))
	var mv_st := "now"
	var fi_st := "todo"
	var en_st := "todo"
	if braced:
		mv_st = "done" if moved else "off"
		fi_st = "off"
		en_st = "now"
	elif target != "":
		mv_st = "done" if moved else ("todo" if mleft > 0 else "off")
		fi_st = "now"
	elif plan != null:
		mv_st = "now"
	elif fired:
		mv_st = "now" if mleft > 0 else ("done" if moved else "off")
		fi_st = "now" if bear > 0 else "done"
		en_st = "now" if bear == 0 and mleft == 0 else "todo"
	elif mleft <= 0:
		mv_st = "done" if moved else "off"
		fi_st = "now" if bear > 0 else "off"
		en_st = "now" if bear == 0 else "todo"
	var steps := [
		{"n": 1, "label": "Move", "detail": "%d of %d left" % [maxi(mleft, 0), maxi(speed_v, mleft)] if not fired or mleft > 0 else ("moved" if moved else "held"), "st": mv_st},
		{"n": 2, "label": "Fire", "detail": ("braced" if braced else ("%d of %d guns ready" % [ready, guns] + (", %d can fire now" % bear if ready > 0 else ""))), "st": fi_st},
		{"n": 3, "label": "End ship", "detail": "Space", "st": en_st}]
	var hint := ""
	var say := ""   # issue 271: the sheet's one short sentence for what to do now (the full hint is on the action's hover)
	var keys := ""   # issue 1589 (Ryan, Nov 22): the keys of an open plan, always on screen beside what it does
	var btns: Array = []
	if nothing or ending:
		hint = "[color=#a7b09d]Nothing left to do this round: handing over to the next ship.[/color]"
		say = "Nothing left to do: handing over."
	elif braced:
		hint = "Braced: hull damage −40% until its next turn. End the ship (Space)."
		say = "Braced: hull damage -40% until its next turn."
	elif mode == "ram" and ui.get("ram") is Dictionary:
		# issue 1444: the armed ram's forecast; nothing happens until the second press
		hint = _ram_forecast(id)
		var rm: Dictionary = ui["ram"]
		say = "Ram %s: about %d hull to it, %d recoil to you." % [_name(rm["target"]), int(rm["dmg"]), int(rm["recoil"])]
		if float(rm["recoil"]) >= float(u["hp"]):
			say += " The recoil will destroy your ship."
		btns.append({"text": "Ram (Enter)", "act": "confirm", "on": true, "primary": true})
		btns.append({"text": "Cancel (Esc)", "act": "cancel", "on": true})
	elif mode == "board" and not (ui.get("board", []) as Array).is_empty():
		var rows := PackedStringArray()
		for b in ui["board"]:
			rows.append(_board_odds_text(id, b))
		hint = "[color=#ffc04d]Board:[/color] click a gold-ringed enemy to send the boarders. Esc cancels.\n" + "\n".join(rows)
		say = "Board: click a gold-ringed enemy."
		btns.append({"text": "Cancel (Esc)", "act": "cancel", "on": true})
	elif target != "" and atk != null:
		hint = "[color=#ffb23e]%s is out of reach from here.[/color] The ghost shows where the ship would stop: it burns %d movement and fires %d of %d guns on the way. [b]Click it again or press Enter to go.[/b] Esc cancels." % [_name(target), int(atk["st"].cost), int(atk["n"]), int(atk["of"])]
		say = "Out of reach: it burns %d movement and fires %d of %d guns on the way." % [int(atk["st"].cost), int(atk["n"]), int(atk["of"])]
		btns.append({"text": "Burn and fire (Enter)", "act": "confirm", "on": true, "primary": true})
		btns.append({"text": "Cancel (Esc)", "act": "cancel", "on": true})
		keys = "Enter goes · Backspace undoes · Esc cancels"
	elif plan != null or not aims.is_empty():
		# issue 1589: the open plan, step by step; the commit plays all of it as one event
		var pt := _plan_text(id)
		hint = pt["hint"]
		say = pt["say"]
		btns.append({"text": pt["go"], "act": "confirm", "on": true, "primary": true})
		btns.append({"text": "Clear plan (Esc)", "act": "cancel", "on": true})
		keys = "Enter plays · Backspace undoes · Esc clears"
	elif fired and bear > 0:
		hint = "%d gun%s still ready. Click an enemy with a red ring to target it, or end the ship (Space)." % [bear, "" if bear == 1 else "s"]
		say = "%d gun%s still ready: pick another target, or end the ship." % [bear, "" if bear == 1 else "s"]
	elif fired:
		hint = "Fired. %s or end the ship (Space)." % ("It can still slip %d hex%s: click a blue hex," % [mleft, "" if mleft == 1 else "es"] if mleft > 0 else "Use its ability, board, ram")
		say = ("Fired. It can still slip %d hex%s." % [mleft, "" if mleft == 1 else "es"]) if mleft > 0 else "Fired."
	elif bear > 0 and mleft > 0:
		hint = "Click a blue hex to plan a move, or an enemy with a red ring to target it (ships move, then fire)." + (" B braces instead." if can_brace else "")
		say = "Click a blue hex to move, or an enemy with a red ring to target it."
	elif bear > 0:
		hint = "No movement left. Click an enemy with a red ring to target it, " + ("brace (B), " if can_brace else "") + "or end the ship (Space)."
		say = "No movement left. Click an enemy with a red ring to target it."
	elif mleft > 0:
		hint = "Click a blue hex to plan a move. No gun bears from here yet: an orange ring on an enemy means it would from the planned hex." + (" B braces instead." if can_brace else "")
		say = "Click a blue hex to move. No gun bears from here yet."
	else:
		hint = "No movement left and no gun bears. Turn with Q/E" + (", brace (B)" if can_brace else "") + " or end the ship (Space)."
		say = "No movement left and no gun bears. Turn" + (", brace" if can_brace else "") + " or end the ship."
	if not braced and can_brace:
		btns.append({"text": "Brace (B)", "act": "brace", "on": true, "tip": _brace_tip(ru)})
	if u.get("ab") != null and bool(u.get("abReady", false)) and bool(ui.get("ability", {}).get("ready", false)):
		var A = TBL.get("ABILITIES", {}).get(str(u["ab"]), {})
		btns.append({"text": str(A.get("n", u["ab"])), "act": "ability", "on": true, "tip": str(A.get("d", ""))})
	var pend := _player_pending()
	var more := pend - (0 if u["active"] else 1)
	btns.append({"text": "Next ship (Tab)", "act": "next", "on": not u["active"] and more > 0, "big": true,
		"tip": "Switch to another ready ship. Once a ship has moved or fired it stays up until it ends."})
	btns.append({"text": "End ship (Space)", "act": "end", "on": true, "big": true, "primary": plan == null and target == "",
		"tip": "This ship is done for the round%s; the enemy moves one of theirs." % ("" if u["active"] else " (it holds position)")})
	if not plan_steps.is_empty():
		btns.append({"text": "Step back (Backspace)", "act": "undo", "on": true,
			"tip": "Take back the last step of the plan: a target, a turn or a move. Nothing has happened yet."})
	elif bool(u.get("undo", false)):
		btns.append({"text": "Undo move (Backspace)", "act": "undo", "on": true,
			"tip": "Take back the last move or turn. Allowed until the ship fires, rams, boards or uses an ability."})
	return {"name": str(u["name"]), "cls": _class_label(u["cls"]), "flag": u["flagship"], "tag": "ACTING" if u["active"] else "UP",
		"more": ("%d more ready" % more) if more > 0 else "last ship this round", "steps": steps, "hint": hint, "say": say, "keys": keys, "buttons": btns, "aim": target != "" and plan == null}


# F1: the play log goes three places: the battle result (campaign_host hands results to the campaign), the campaign's
# run log through tel (campaign.gd tel_battle, kept in the save), and a file per battle in user://play_logs/ for helpers
func _play_log_out(res: String) -> void:
	if showcase:
		return
	_tip_dismiss("battle_end")
	var pl: Dictionary = plog.summary(res, int(V.get("round", 0)), pace_enemy)
	result["play"] = pl
	if bot:
		return
	var host = get_parent().get("campaign") if get_parent() != null else null
	var C = host.get("C") if host != null and is_instance_valid(host) else null
	if C != null and C.has_method("tel_battle"):
		C.tel_battle(pl)
	DirAccess.make_dir_recursive_absolute("user://play_logs")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var f := FileAccess.open("user://play_logs/battle_%s.json" % stamp, FileAccess.WRITE)
	if f != null:
		var meta := {"seed": api.world_info().get("seed") if api != null else null, "obj": (V.get("obj") as Dictionary).get("type") if V.get("obj") is Dictionary else "rout",
			"enemy": _enemy_fac(), "campaign": in_campaign}
		pl["battle"] = meta
		f.store_string(JSON.stringify(pl, " "))


func _command_label() -> String:
	return str(api.command_info().get("label", "Command")) if api != null and api.has_method("command_info") else "Command"


static func _command_tip(command: Dictionary) -> String:
	if command.is_empty(): return ""
	if command["used"]: return "Already used this battle."
	var power := int(command["power"])
	var tip := "Power %d of 3: %s" % [power, command["effect"]]
	if command["next"] != "": return tip + "\nWait one round for power %d: %s" % [power + 1, command["next"]]
	return tip + ("\nAlready at full power." if power == 3 else "\nOne more round does not raise the power.")


func _brace_tip(u: Dictionary) -> String:
	if _jt(TBL.get("FAC_GATES", {}).get(u["fac"], {}).get("noBrace")):
		return "Glasswright ships cannot Brace."
	var tip := str(TBL.get("ORDERS", {}).get("brace", {}).get("d", ""))
	if _jt(u.get("fx", {}).get("wallBrace")):
		return tip + " Shield Wall covers every adjacent allied ship, even if it faces a different way."
	if u["fac"] == "voidsworn":
		return tip + " Also covers the most damaged adjacent ally facing the same way."
	return tip


func _class_label(cls) -> String:
	return str(TBL.get("CLS_NAME", {}).get(str(cls), cls))


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
	var view: ShipView = views.get(id)
	var info := {"name": u["name"], "cls": _class_label(u["cls"]), "side": u["side"], "flag": u["flagship"], "code": view.code if is_instance_valid(view) else "", "hp": d["hp"], "maxHp": u["maxHp"], "sh": d["sh"], "shMax": u["shMax"], "shp": _z0(u.get("shp")),
		"routed": _routed_sides(u)}
	var mleft := int(u.get("moveLeft", u["mp"])) if u.get("moveLeft") != null else int(u["mp"])
	var stats := "Hull [color=#ffad3b]%s/%s[/color]   Armor %d%%   Evasion %d\nMovement %d of %d   Turns %d" % [Campaign.hull_text(d["hp"]), Campaign.hull_text(u["maxHp"]), int(round(float(ru.get("armor", 0)) * 100.0)), int(_z0(ru.get("ev"))), mleft, int(_z0(ru.get("speed"))), int(u["turnsLeft"])]
	if u.get("fired", false) and mleft < int(u["mp"]):
		stats += "\n[color=#7c8674]Fired.%s[/color]" % (" Movement left: %d." % mleft if mleft > 0 else "")
	if u.get("crew") != null:
		stats += "   Crew %d/%d" % [int(u["crew"]), int(u["crewMax"])]
	if u["braced"]:
		stats += "\n[color=#9fd4ff]Braced: hull damage −40% until its next turn.[/color]"
	if u["burning"]:
		stats += "\n[color=#f08a4b]On fire.[/color]"
	if not (info["routed"] as Array).is_empty():
		stats += "\n[color=#9fd4ff]%s[/color]" % _route_line(info["routed"])
	if u.get("ab") == "launch":
		stats += "\nWings launch and fight automatically. Replacements use spares and fight next round."
	info["stats"] = stats
	var ws: Array = []
	var tgt := target
	var hu := _unit_at(hover.x, hover.y)
	if tgt == "" and not hu.is_empty() and hu["side"] != u["side"]:
		tgt = hu["id"]
	# #271: odds from the planned hex when a move is planned (the rules' own preview at that state), else from here
	var mine_up: bool = u["side"] == "player" and id == sel and api.phase == "player"
	var pst = plan if (plan != null and mine_up) else null
	var distance := int(api.R.hdist(pst if pst != null else u, VU[tgt])) if VU.has(tgt) else -1
	for w in u["weapons"]:
		var wi := int(w["i"])
		var rw = ru["weapons"][wi]
		var right := ""
		var hit := -1
		var dmg := -1
		var why := ""
		if float(_z0(w["off"])) > 0:
			right = "offline"
		elif float(_z0(w["cd"])) > 0:
			right = "reloading %d" % int(w["cd"])
		elif not w["ready"]:
			right = "fired"
		elif tgt != "" and u["side"] == "player" and pst == null and api.can_fire(id, wi, tgt):
			var pv := _fire_preview(id, wi, tgt)
			right = "%d%%" % int(pv["hit"])
			hit = int(pv["hit"])
			dmg = int(round(float(pv.get("shield", 0)) + float(pv.get("hull", 0))))
		elif tgt != "" and pst != null:
			var pa := _fire_preview_at(id, wi, tgt, pst)
			if bool(pa.get("bears", false)):
				right = "%d%%" % int(pa["hit"])
				hit = int(pa["hit"])
				dmg = int(round(float(pa.get("shield", 0)) + float(pa.get("hull", 0))))
			else:
				right = "ready"
				why = "won't bear"
		elif tgt != "" and u["side"] == "player" and mine_up:
			right = "ready"
			var wt := _wtarget(id, wi, tgt)
			# view() weapons carry the rules' "k" as "kind" (battle_api.gd _i_view), so this reads the right key
			if w["kind"] == "flak" and bool(wt.get("inRange", false)) and bool(wt.get("inArc", false)):
				why = "wings only"
			elif not bool(wt.get("inRange", false)):
				why = "out of range"
			elif not bool(wt.get("inArc", false)):
				why = "no enemy in arc"
			else:
				why = "line blocked"
		else:
			right = "ready"
		if why == "":
			why = right
		var arc_name = TBL.get("ARC_NAME", {}).get(str(w["arc"]), str(w["arc"]))
		var cdv := int(_z0(rw.get("cd")))
		ws.append({"i": w["i"], "name": str(w["name"]), "kind": w["kind"], "range": int(rw["r"]), "distance": distance, "desc": _weapon_desc(ru, rw, str(arc_name)), "right": right, "ready": w["ready"], "armed": wi == armed and id == sel,
			"arc": str(w["arc"]), "rng": "1-%d" % int(rw["r"]), "arc_tip": "%s, range 1 to %d hexes. Turn with Q / E to bring it to bear." % [str(arc_name), int(rw["r"])],
			"hit": hit, "dmg": dmg, "why": why, "cost": ("CD %d" % cdv) if cdv > 0 else "free"})
	info["weapons"] = ws
	# #271: the numbers the Up block and the Fire block head show
	info["arm"] = int(round(float(ru.get("armor", 0)) * 100.0))
	info["move"] = [mleft, int(_z0(ru.get("speed")))]
	info["turns"] = int(u["turnsLeft"])
	if u["side"] == "player":
		info["tag"] = "ACTING" if u["active"] else ("UP" if mine_up and not ended else "FLEET")
		info["danger"] = 0 if u["dead"] else _danger_at(u)
	else:
		info["tag"] = "ENEMY"
	if mine_up and tgt != "":
		info["fire_at"] = _name(tgt)
		info["fire_from"] = "from the planned hex" if pst != null else "from here"
	elif mine_up and pst != null and int(pst.get("gunsOf", 0)) > 0:
		info["fire_from"] = "planned hex: %d of %d guns bear" % [int(pst.get("guns", 0)), int(pst.get("gunsOf", 0))]
	var fl := PackedStringArray()
	if u["braced"]:
		fl.append("[color=#9fd4ff]Braced: hull damage −40% until its next turn.[/color]")
	if u["burning"]:
		fl.append("[color=#f08a4b]On fire.[/color]")
	if u.get("fired", false) and mleft < int(u["mp"]):
		fl.append("[color=#7c8674]Fired.%s[/color]" % (" Movement left: %d." % mleft if mleft > 0 else ""))
	var Bs0 = api.R.B
	if Bs0.get("aiFocus") is Dictionary and Bs0["aiFocus"].get("id") == ru.get("id") and not u["dead"]:
		fl.append("[color=#ff8a72]The enemy fleet is focusing its fire on this ship.[/color]")
	info["flags"] = " ".join(fl)
	_panel_sheet(u, ru, info)
	if u["side"] == "player" and not u["dead"]:
		var can := _can_act() and _usable(u)
		var orders: Array = []
		var ui := _ui(id)
		orders.append({"text": "Brace (B)", "act": "brace", "on": can and bool(ui.get("orders", {}).get("brace", false)), "active": u["braced"], "tip": _brace_tip(ru)})
		if u.get("ab") != null and u.get("ab") != "launch":
			var A = TBL.get("ABILITIES", {}).get(str(u["ab"]), {})
			orders.append({"text": str(A.get("n", u["ab"])), "act": "ability", "ability": str(u["ab"]), "cooldown": int(_z0(u.get("abCd"))), "active": mode == u["ab"], "on": can and u["abReady"], "tip": str(A.get("d", ""))})
		# issue 1444: the Ram and Board tips carry the forecast; Ram arms on the first press and rams on the second
		var ram_tip := "Charge the first enemy dead ahead (needs a run-up)."
		if ui.get("ram") is Dictionary:
			ram_tip = _strip_bb(_ram_forecast(id, true)) + " Press once to see the run, again to ram."
		orders.append({"text": "Ram (X)", "act": "ram", "on": can and ui.get("ram") != null, "active": mode == "ram", "tip": ram_tip})
		var board_tip := "Send boarding crews into an adjacent enemy."
		for b in ui.get("board", []):
			board_tip += "\n" + _strip_bb(_board_odds_text(id, b))
		orders.append({"text": "Board (G)", "act": "board", "on": can and not (ui.get("board", []) as Array).is_empty(), "active": mode == "board", "tip": board_tip})
		# issue 1444: every ship the rules give a wing stance (carriers and Aspect of the Brood flagships) gets the buttons
		if u.get("stance") != null:
			for stn in ["strike", "screen", "hunt"]:
				orders.append({"text": "Wings: %s" % stn, "act": "stance", "arg": stn, "active": str(u.get("stance")) == stn, "on": bool(u.get("canStance")) and str(u.get("stance")) != stn and _can_act(),
					"tip": {"strike": "Wings range out and strike.", "screen": "Wings stay within 3 hexes, hunt enemy craft first, and intercept torpedoes aimed within 2 hexes.", "hunt": "Wings range 4 hexes further, +20% against crippled ships, easier to hit."}[stn]})
		if str(u.get("role", "")) != "" and u.get("role") != null:   # issue 529: Roles Assigned at Hatching, one change per battle
			var rn := str(u["role"]).capitalize()
			orders.append({"text": "Role: %s" % rn, "act": "role", "on": _can_act() and bool(u.get("canRole")),
				"tip": "This ship's role: strike +10 aim, screen +10 evasion, mend 10% stronger repair and regrowth. A ship may change its role once per battle."})
		orders.append({"text": "Turn left (Q)", "act": "rotl", "on": can})
		orders.append({"text": "Turn right (E)", "act": "rotr", "on": can})
		info["orders"] = orders
	return info


# ---------------------------------------------------------------- the full ship sheet (ui3d.js refreshPanel)
const SEC_LBL := {"prow": "Fore", "mid": "Core", "eng": "Engines"}
static var _boon_d = null   # not GPU: campaign_tables.json BOON_D: boon id -> description per rarity


# a number as the browser prints it (2, not 2.0)
static func _n(x) -> String:
	if (x is float) and is_equal_approx(x, roundf(x)):
		return str(int(x))
	return str(x)

# issue #305: a lineage pick key (admiral:branch:tier:choice or admiral:cap:n) as its skill name
func _tree_name(key: String) -> String:
	var p = key.split(":")
	if p.size() < 3: return key
	var tree = TBL.get("LINEAGE_TREES", {}).get(p[0])
	if not tree is Dictionary: return key
	if p[1] == "cap":
		var c = int(p[2]); var caps = tree.get("capstones", [])
		return str(caps[c]["n"]) if c < caps.size() else key
	var t = int(p[2]); var c2 = int(p[3]) if p.size() > 3 else 0
	var br = tree.get("branches", {}).get(p[1])
	if not br is Dictionary: return key
	var tiers = br.get("tiers", [])
	if t >= tiers.size(): return key
	var pair = tiers[t]
	return str(pair[c2]["n"]) if c2 < pair.size() else key


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
		info["cls"] = str(T.get("n", _class_label(u["cls"]))) + (", elite captain" if _jt(ru.get("elite")) else "")
	var cap = ru.get("ship", {}).get("cap") if ru.get("ship") is Dictionary else null
	if cap is Dictionary:
		var ranks: Array = TBL.get("CAPTAINS", {}).get(str(cap.get("fac", "voidsworn")), TBL.get("CAPTAINS", {}).get("voidsworn", {})).get("ranks", [])
		var rk := str(ranks[clampi(int(_z0(cap.get("rank"))), 0, ranks.size() - 1)]) if not ranks.is_empty() else ""
		var line := "%s %s" % [rk, str(cap.get("name", ""))]
		info["cap_name"] = line.strip_edges()
		for pk in cap.get("perks", []):
			var P = TBL.get("PERKS", {}).get(str(pk))
			if P is Dictionary:
				line += "  [b]%s[/b] [color=#7c8674](%s)[/color]" % [str(P.get("n", pk)), str(P.get("d", "")).trim_suffix(".")]
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
		info["stats"] = str(info.get("stats", "")) + "\n[color=#92b8e8]Shields[/color]: pool %d of %d, +%d a turn; sides catch prow %d, port %d, starboard %d, rear %d" % [int(_z0(ru.get("shp"))), int(u["shMax"]), int(_z0(ru.get("regen"))), int(sh[0]), int(sh[3]), int(sh[1]), int(sh[2])]
	# state and faction lines (refreshPanel tr[] and battle.js factionTraitLines)
	var tr: Array = R.storyModifierLines(ru)
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
		tr.append("[color=#ff8a72]The enemy fleet is focusing its fire on this ship.[/color]")
	if not _jt(ru.get("isSq")):
		var fac := str(ru.get("fac", ""))
		if fac == "hegemony":
			if _jt(ru.get("ripped")):
				tr.append("Links ripped out: it answers no Directorate net, no synchronized fire.")
			else:
				var anc = R.syncAnchor(ru["side"])
				var sr := int(TBL.get("SYNC_R", 3))
				if not (ru["side"] == "player" and Bs["round"] == 1 and _jt(Bs.get("cfg", {}).get("storyMods", {}).get("syncDown"))):
					tr.append("Synchronized fire lost: the flagship is gone." if not _jt(anc) else ("Sync anchor: Directorate ships within %d hexes fire as one." % sr if _jt(ru.get("anchor")) else ("In sync with the flagship." if R.inSync(ru) else "Out of sync: more than %d hexes from the flagship." % sr)))
		if fac == "ithar" and float(u["shMax"]) > 0.0:
			tr.append("Prism charge: an untouched pool snaps back to full; a pool struck since its last turn recharges twice.")
		if fac == "chorus":
			tr.append("Feeds on kills nearby (up to %d%% hull a round)." % int(round(float(TBL.get("FEED_CAP", 0.0)) * 100.0)))
		if fac == "deathless" and _jt(T.get("reanimate")):
			if _jt(ru.get("ripped")):
				tr.append("Links ripped out: the Archive does not answer, no restore.")
			else:
				var L = Bs.get("legion", {}).get(ru["side"]) if Bs.get("legion") is Dictionary else null
				tr.append("Reassembled this battle." if _jt(ru.get("risen")) else ("Archive restore: the first to fall reassembles next round." if L is Dictionary and float(L.get("used", 0)) < float(L.get("max", 0)) and not _jt(ru.get("pflag")) and not _jt(ru.get("flagship")) and not _jt(ru.get("boss")) else "Archive restore spent."))
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
		if _jt(ru.get("nem")) and _jt(ru.get("nemFlag")):
			# Issue 364: ask the campaign for the current commander instead of trusting the battle's copy, when a campaign is here.
			var host = get_parent().get("campaign") if get_parent() != null else null
			var CN = host.get("C") if host != null and is_instance_valid(host) else null
			var nem_now = CN.nemRead() if (CN != null and CN.has_method("nemRead")) else null
			if not _jt(nem_now):
				nem_now = Bs.get("nem")   # no campaign run (showcase or quick battle): the battle's own copy is the only source
			if _jt(nem_now):
				tr.append("[color=#ff8a72]Your Nemesis commands from this ship.[/color]")
				var kn: Array = []
				var weak: Array = nem_now["weak"] if nem_now.get("weak") is Array else []
				for w in (nem_now.get("revealed") if nem_now.get("revealed") is Array else []):
					if w in weak:
						var NW = API.nem_entry(TBL.get("NEM_WEAK", {}), str(w), nem_now.get("fac"))
						if NW == null: NW = {}
						kn.append("%s (%s)" % [str(NW.get("n", w)), str(NW.get("d", "")).trim_suffix(".")])
				if not kn.is_empty():
					tr.append("Known weaknesses: " + "; ".join(kn) + ".")
		# helm: thrusters and the faction drive (ui3d.js driveLine)
		if ru["side"] == "player":
			var MR: Dictionary = R.moveRules(ru)
			var M = TBL.get("MOVE_RULES", {}).get(fac)
			var dl := "Thrusters: sideslip %s, back off %s, pass over or under %s." % [_n(MR.get("slip")), _n(MR.get("rev")), ("+" + _n(MR.get("over"))) if _jt(MR.get("over")) else "free"]
			if M is Dictionary:
				dl += " [b]%s[/b]: %s" % [str(M.get("n", "")), str(M.get("d", ""))]
			if ru.get("hexMoved") != null:
				if int(ru["hexMoved"]) == 0:
					dl += " [color=#ff8a72]Has not moved: enemies get +%s to hit.[/color]" % _n(MR.get("still"))
				elif int(ru["hexMoved"]) >= int(_z0(MR.get("evadeAt"))):
					dl += " [color=#59d6a8]Evasive: enemies get −%s to hit.[/color]" % _n(MR.get("evade"))
			tr.append("[color=#7c8674]%s[/color]" % dl)
	if not tr.is_empty():
		info["note"] = "[font_size=%d]%s[/font_size]" % [hud.s(13), " ".join(tr)]
	# extra sections
	var extra: Array = []
	if ru["side"] == "enemy" and _jt(T.get("boss")) and TBL.get("BOSS_CMD", {}).has(str(ru.get("fac"))):
		var c = TBL["BOSS_CMD"][str(ru["fac"])]
		var when := "used" if _jt(Bs.get("cmdEUsed")) else ("strikes next round" if Bs.get("cmdENext") != null else "not yet")
		var col := "#ff8a72" if Bs.get("cmdENext") != null and not _jt(Bs.get("cmdEUsed")) else "#a7b09d"
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
				bb += "[b]%s[/b] [color=#a7b09d]%s[/color]\n" % [str(AS.get("n", "")), str(AS.get("d", ""))]
		var stats: Dictionary = Bs.get("boonStats", {}) if Bs.get("boonStats") is Dictionary else {}
		for b in RUN.get("boons", []):
			var B0 = TBL.get("BOONS", {}).get(str(b.get("id")))
			if not B0 is Dictionary:
				continue
			var pat = B0.get("p") if _jt(B0.get("p")) else (B0.get("duo", [""])[0] if B0.get("duo") is Array else "")
			var pcol := str(TBL.get("PATRONS", {}).get(str(pat), {}).get("col", "#ff8a3a"))
			var dl: Array = _boon_d.get(str(b.get("id")), [])
			var d := str(dl[clampi(int(_z0(b.get("r"))), 0, dl.size() - 1)]) if not dl.is_empty() else ""
			bb += "[color=%s]▌[/color][b]%s[/b]%s [color=#a7b09d]%s[/color]\n" % [pcol, str(B0.get("n", "")), (" [b]×%d this battle[/b]" % int(stats[b["id"]])) if _jt(stats.get(b.get("id"))) else "", d]
		if bb != "":
			extra.append(["Fleet protocols", bb.strip_edges()])
	if ru["side"] == "player" and not _jt(ru.get("isSq")):
		var ts: Dictionary = Bs.get("treeStats", {}) if Bs.get("treeStats") is Dictionary else {}
		if not ts.is_empty():
			var keys = ts.keys(); keys.sort(); var tb := ""
			for key in keys:
				tb += "[b]%s[/b] [color=#d0a64b]×%d this battle[/color]\n" % [_tree_name(str(key)), int(ts[key])]
			extra.append(["Admiral lineage", tb.strip_edges()])
	if ru["side"] == "enemy":
		var F = TBL.get("FACTIONS", {}).get(str(ru.get("fac")), {})
		if F is Dictionary and str(F.get("blurb", "")) != "":
			extra.append([str(F.get("n", "")), "[color=#a7b09d]%s[/color]" % str(F["blurb"])])
	info["extra"] = extra


# ---------------------------------------------------------------- per frame: nameplates, floats, bot

var showcase_ready := false


func _process(dt: float) -> void:
	game_t += dt
	if not torp_ft.is_empty():
		_torp_ft_step(dt)
	cam.keyboard_enabled = not warming and (hud == null or hud.menu == null)
	if showcase_ready:
		cam.a += dt * 0.035
	if world != null and world.has_method("step"):
		world.step(dt)
	if api == null:
		return
	# issue 1451: the rules packed this round's start; save it once its animations have played and the player has the turn
	if round_save_cb.is_valid() and int(api.round_snap_round) > round_saved and _can_act():
		round_saved = int(api.round_snap_round)
		if bool(round_save_cb.call()):
			round_on_disk = round_saved
	var vs := get_viewport().get_visible_rect().size
	# issue 1437 (item 9): with the HUD hidden or behind the title (showcase) no plate shows, so the plate, priority and
	# declutter work is skipped; the gold ring still breathes
	var plates_on := not showcase and hud != null and hud.visible
	for id in views:
		var sv = views[id]
		var u: Dictionary = VU.get(id, {})
		if not plates_on:
			_breathe_ring(sv, not u.is_empty() and str(id) == sel and api.phase == "player" and not ended and not bot and u["side"] == "player")
			continue
		# a cut-in hides the names, except the attacker and the target of the enemy volley playing (issue 1211)
		var aimed := not aim.is_empty() and (str(id) == str(aim["t"]) or str(id) == str(aim["a"]))
		if u.is_empty() or sv.dead or not sv.visible or (not cine_saved.is_empty() and not aimed):
			hud.set_plate(str(id), Vector2.ZERO, false, "", true, false, 0, 1, 0, 0)
			continue
		var wp: Vector3 = sv.visual_position() + Vector3(0, 3.0 + sv.L * 0.18, 0)
		var on := not cam.is_position_behind(wp)
		var sp := cam.unproject_position(wp)
		on = on and sp.x > -50 and sp.y > -50 and sp.x < vs.x + 50 and sp.y < vs.y + 50
		var d: Dictionary = disp.get(id, {"hp": u["hp"], "sh": u["sh"]})
		var shs := 0.0
		for x in d["sh"]:
			shs += float(x)
		var is_up: bool = str(id) == sel and api.phase == "player" and not ended and not bot and u["side"] == "player"
		var px := {"nem": bool(u.get("nemesis", false)) and u["side"] == "enemy", "target": str(id) == target or aimed,
			"regenLock": bool(d.get("regenLock", false))}
		if _tgt_plate.has(str(id)):
			px["odds"] = _tgt_plate[str(id)]["odds"]
			px["ghost"] = _tgt_plate[str(id)]["ghost"]
		hud.set_plate(str(id), sp, on, str(u["name"]), u["side"] == "player", u["flagship"], float(d["hp"]), float(u["maxHp"]), shs, float(u["shMax"]) * 4.0, is_up, px)
		_breathe_ring(sv, is_up)
	if plates_on:
		_declutter()
	_float_step(dt)


# the gold ring under the ship that is up breathes, so the eye finds it; a reinforcement's ring flashes on arrival
func _breathe_ring(sv, is_up: bool) -> void:
	if sv.ring == null:
		return
	if is_up:
		var k := 1.0 + 0.07 * sin(game_t * 4.0)
		sv.ring.scale = Vector3(k, 1.0, k)
	elif sv.ring.scale.x != 1.0:
		sv.ring.scale = Vector3.ONE


func _declutter() -> void:
	# F1: names never pile up. The ship that is up and the target keep theirs, then the ship under the mouse and the enemy
	# acting now, then the flagship; any other name that would overlap one already shown is hidden (hover shows it).
	var prio := {}
	for u in V.get("units", []):
		if u["dead"]:
			continue
		var pr := 1 if u.get("flagship", false) else 0
		if u["active"] and u["side"] == "enemy":
			pr = 2
		prio[str(u["id"])] = pr
	var hu := _unit_at(hover.x, hover.y)
	if not hu.is_empty():
		prio[str(hu["id"])] = 2
	if sel != "":
		prio[sel] = 3
	if target != "":
		prio[target] = 3
	if not aim.is_empty():
		prio[str(aim["t"])] = 3
	hud.declutter_plates(prio)


# floating numbers, the bot's turn and its trace: every frame, plates or not
func _float_step(dt: float) -> void:
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f.t += dt
		var lbl: Label = f.lbl
		var wp: Vector3 = (f.pos as Vector3) + Vector3(0, 4.0 + f.t * 6.0, 0)
		lbl.visible = not cam.is_position_behind(wp)
		var fp := cam.unproject_position(wp)
		var pc = hud.plates.get(str(f.get("id", ""))) if f.has("id") else null
		if pc != null and is_instance_valid(pc) and (pc as Control).visible:
			# a ship's numbers start above its name plate and rise from there, never across it (run 2 pictures)
			var base := minf(fp.y + lbl.size.y * 0.5, (pc as Control).position.y - 4.0 * hud.k)
			lbl.position = Vector2(fp.x - lbl.size.x * 0.5, base - lbl.size.y + f.dy)
		else:
			lbl.position = fp - lbl.size * 0.5 + Vector2(0, f.dy)
		var f_end := float(f.get("end", 1.6))
		lbl.modulate.a = clampf(f_end - f.t, 0.0, 1.0)
		if f.t > f_end:
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
		_finish(result)


func _float(id, text: String, col: Color, dy := 0.0) -> void:
	if not views.has(id):
		return
	_float_at(_pos(id), text, col, dy)
	floats[-1]["id"] = str(id)


func _float_at(pos: Vector3, text: String, col: Color, dy := 0.0) -> void:
	var lbl: Label = hud.make_float(text, col)
	floats.append({"lbl": lbl, "pos": pos, "t": 0.0, "dy": dy * hud.k})


# Presentation queries after _api_join. Each gun tooltip estimates that gun alone.
func _volley_preview(id: String, guns: Array, tid: String, st = null) -> Dictionary:
	if guns.is_empty(): return {}
	var u = api.unit(id)
	var source = u if st == null else api.R.stateView(u, st)
	return api.R.previewVolley(source, guns, api.unit(tid))


func _fire_preview(id: String, wi: int, tid: String) -> Dictionary:
	return _volley_preview(id, [wi], tid)[wi]


# The same single-gun preview from a planned hex, if the gun can fire there.
func _fire_preview_at(id: String, wi: int, tid: String, st: Dictionary) -> Dictionary:
	var u = api.unit(id)
	var t = api.unit(tid)
	if u == null or t == null or wi < 0 or wi >= u["weapons"].size(): return {}
	var source = api.R.stateView(u, st)
	if not api.R.canFire(source, u["weapons"][wi], t): return {}
	var preview: Dictionary = api.R.previewVolley(source, [wi], t)[wi]
	preview["bears"] = true
	return preview


# ---------------------------------------------------------------- #271 Glass Shell: what the new HUD blocks read
# All read from the rules' own state (no numbers made up in the HUD); each keeps its last answer while the enemy's step
# or the threat map holds the rules on another thread.

var _crests := {}
var _info_last := {}
var _nem_last := {}
var _tgt_plate := {}          # target id -> {odds, ghost}: the target's nameplate tags, read every frame


func _fac_crest(fac: String) -> Texture2D:
	if fac == "":
		return null
	if not _crests.has(fac):
		_crests[fac] = load("res://portraits/portraits.gd").faction_crest(fac)
	return _crests[fac]


# the top bar: the enemy's faction (its crest is the accent, its name plain), its ships, the run's Heat level
func _battle_info() -> Dictionary:
	if api == null or not _api_join():
		return _info_last
	var fac := _enemy_fac()
	var F = TBL.get("FACTIONS", {}).get(fac, {})
	var foes := 0
	for u in V.get("units", []):
		if u["side"] == "enemy" and not u["dead"] and not u["squadron"]:
			foes += 1
	var heat := -1
	var tip := ""
	var RUN = api.R.RUN
	if RUN is Dictionary and RUN.get("heat") is Array:
		heat = 0
		var parts := PackedStringArray()
		for h in (RUN.get("heat") if RUN.get("heat") is Array else []):
			var H = TBL.get("HEAT", {}).get(str(h))
			if H is Dictionary:
				heat += int(_z0(H.get("w")))
				parts.append(str(H.get("n", h)))
		tip = "Threat %d of 9: the run's difficulty level, from the optional rules chosen when the run began%s" % [heat, (": " + ", ".join(parts) + ".") if not parts.is_empty() else " (none)."]
	_info_last = {"foe_name": str(F.get("n", "")) if F is Dictionary else "", "foe_crest": _fac_crest(fac), "foe_ships": foes, "heat": heat, "heat_tip": tip}
	return _info_last


# the Nemesis block: who leads the enemy, aboard what, when he runs, what he adapted to and the weaknesses you found
func _nem_info() -> Dictionary:
	if api == null or not _api_join():
		return _nem_last
	var Bs = api.R.B
	var N = Bs.get("nem") if Bs is Dictionary else null
	if not N is Dictionary:
		_nem_last = {}
		return _nem_last
	var fl = null
	for u in Bs["units"]:
		if _jt(u.get("nemFlag")):
			fl = u
			break
	var ship := ""
	var state := ""
	if fl != null:
		var T = fl.get("t")
		ship = str(T.get("n", "")) if T is Dictionary else ""
		if ship == "":
			ship = str(fl.get("cls", ""))
		if _jt(fl.get("dead")):
			state = "fled" if _jt(fl.get("fled")) else "destroyed"
	var flee := ""
	var Rf = Bs.get("nemFlee")
	if Rf is Dictionary and _jt(Rf.get("hull")):
		flee = "flees below %d%% hull%s" % [int(round(float(Rf["hull"]) * 100.0)), " with shields down" if _jt(Rf.get("shields")) else ""]
	var ad: Array = []
	var FA = TBL.get("NEM_ADAPT_FAC", {}).get(str(N.get("fac", "")), {})
	for a in (N.get("adapt") if N.get("adapt") is Array else []):
		var A = TBL.get("NEM_ADAPT", {}).get(str(a))
		var an := ""
		if A is Dictionary:
			an = str(FA.get(str(a), A.get("n", a))) if FA is Dictionary else str(A.get("n", a))
		elif FA is Dictionary and FA.get("special") is Dictionary and str(FA["special"].get("id", "")) == str(a):
			A = FA["special"]
			an = str(A.get("n", a))
		if A is Dictionary:
			ad.append([an, str(A.get("d", "")), str(A.get("why", ""))])
	var wk: Array = []
	var weak: Array = N["weak"] if N.get("weak") is Array else []
	for w in (N.get("revealed") if N.get("revealed") is Array else []):
		if w in weak:
			var W = API.nem_entry(TBL.get("NEM_WEAK", {}), str(w), N.get("fac"))
			if W is Dictionary:
				wk.append([str(W.get("n", w)), str(W.get("d", ""))])
	_nem_last = {"name": ("%s %s" % [str(N.get("title", "")), str(N.get("name", ""))]).strip_edges(), "ship": ship, "flee": flee,
		"adapted": ad, "weak": wk, "state": state, "tex": _fac_crest(str(N.get("fac", "")))}
	return _nem_last


# The enemy aimed at (or under the pointer) and what the bearing guns are expected to take from its shield pool and hull.
func _target_info() -> Dictionary:
	_tgt_plate = {}
	if api == null or api.phase != "player" or ended or bot or showcase or sel == "" or not VU.has(sel) or VU[sel]["side"] != "player":
		return {}
	var tid := target
	if tid == "":
		var hu := _unit_at(hover.x, hover.y)
		if not hu.is_empty() and hu["side"] == "enemy":
			tid = str(hu["id"])
	if tid == "" or not VU.has(tid) or VU[tid]["dead"] or not _api_join():
		return {}
	var tu: Dictionary = VU[tid]
	var ru = api.unit(sel)
	var foe = api.unit(tid)
	if ru == null or foe == null: return {}
	var d: Dictionary = disp.get(tid, {"hp": tu["hp"], "sh": tu["sh"]})
	# with a move planned, the odds are read as the ship would stand at the planned hex (the Fire block does the same)
	var set: Array = _shown_set(tid)
	var volley := _volley_preview(sel, set, tid, plan)
	var es := 0.0
	var eh := 0.0
	var best := -1
	var best_index := -1
	var gun := ""
	var kind := ""
	for i in set:
		var p: Dictionary = volley[i]
		es += float(p.get("shield", 0))
		eh += float(p.get("hull", 0))
		var weapon: Dictionary = VU[sel]["weapons"][i]
		if int(p.get("hit", 0)) > best:
			best = int(p.get("hit", 0))
			best_index = int(i)
			gun = str(weapon["name"])
			kind = str(weapon["kind"])
	var shields := int(round(es))
	var hull := int(round(eh))
	var total := shields + hull
	# issue 1446: the side this volley strikes (the best gun's), and whether the rules have routed power to it
	var quad := int(volley[best_index].get("quad", -1)) if best_index >= 0 and volley.has(best_index) else -1
	var routed := _routed_sides(tu)
	var line := ""
	if set.is_empty():
		line = "[color=#a7b09d]%s[/color]" % ("No ready gun bears on it from the planned hex." if plan != null else _cant_fire_reason(tid))
	else:
		var who := ("Both bearing guns" if set.size() == 2 else ("%d bearing guns" % set.size() if set.size() > 2 else "The bearing gun"))
		line = "%s%s: about %d damage" % [who, " from the planned hex" if plan != null else "", total]
		line += ": %d to shields, %d to hull." % [shields, hull] if shields > 0 else ", all to hull."
		# no kill prediction (ui_spec S1 board ruling on the #314 check): the expected value only; the hatched ghost on the
		# target's hull bar already shows the hull reaching zero
		_tgt_plate[tid] = {"odds": "%d%% %d gun%s" % [best, set.size(), "" if set.size() == 1 else "s"], "ghost": maxf(0.0, float(d["hp"]) - eh)}
	return {"name": str(tu["name"]), "flag": tu["flagship"], "nem": bool(tu.get("nemesis", false)), "hp": float(d["hp"]), "maxHp": float(tu["maxHp"]), "sh": d["sh"], "shMax": float(tu["shMax"]), "shp": float(_z0(tu.get("shp"))),
		"defenses": _target_defenses(foe), "exp_hull": hull, "exp_shields": shields, "line": line, "bearing": set.size(), "hit": best, "gun_index": best_index, "gun": gun, "kind": kind,
		"quad": quad, "routed": routed, "struck_routed": quad >= 0 and quad in routed}


func _float_hit(id, sh: float, hull: float, crit) -> void:
	if sh > 0:
		_float(id, "−%d shield" % int(sh), Color("#92b8e8"), FLOAT_LANE_SHIELD)
	if hull > 0:
		_float(id, ("Critical −%d hull" if crit else "−%d hull") % int(hull), Color("#ffd27a") if crit else Color("#ffad3b"), 0)
	elif crit:
		_float(id, "Critical", Color("#ffb23e"), FLOAT_LANE_SHIELD * 2.0)


# ---------------------------------------------------------------- onboarding (ui3d.js tutorialCheck)

func _tip_log(kind: String, id: String, why := "") -> void:
	plog.teaching(kind, id, int(V.get("round", 0)), tip_slot, why)


func _tip_retire(id: String, why: String) -> void:
	if bot or showcase or tips.has(id): return
	tips[id] = true
	if tip_pending == id: tip_pending = ""
	_tip_log("retire", id, why)
	_save_opts()


func _tip_dismiss(why: String) -> void:
	if tip_current == "": return
	var id := tip_current
	_tip_log("dismiss", id, why)
	tip_dismissed[id] = true
	if why == "got_it" and id not in Teaching.ACTION_IDS: tips[id] = true
	tip_current = ""
	hud.hide_tipcard()
	_save_opts()


# Only completed rules events count, never a click, a preview, or a rejected command.
func _tip_completed(e: Dictionary) -> void:
	var kind := str(e.get("t", ""))
	if kind == "activation":
		tip_slot = "%s:%s:%s" % [str(V.get("round", 1)), str(e.get("side", "")), str(e.get("unit", ""))]
	var id := str(e.get("unit", ""))
	if _side(id) != "player" or _is_wing(id): return
	if kind == "move" or (kind == "order" and e.get("order") == "brace"):
		_tip_retire("select", kind)
	if kind == "fire":
		tip_shot = true
		_tip_retire("target", "shot_resolved")
	if kind in ["ram", "board"]: _tip_retire("close", kind)


func _tutorial() -> void:
	if tips_off or bot or showcase or ended or not tip_handed or hud.tipcard != null or V.is_empty() or not _api_join(): return
	var info: Dictionary = api.teaching_info()
	var battle_n := int(info.get("battle", 1))
	var targets := false
	for u in V.get("units", []):
		if u["side"] != "player" or u["dead"] or u.get("squadron", false) or u["activated"]: continue
		for w in _ui(str(u["id"])).get("weapons", []):
			for t in w.get("targets", []):
				if t.get("can", false): targets = true
	var close := false
	if sel != "" and not _sel_unit().is_empty():
		var cu := _ui(sel)
		close = cu.get("ram") != null or not (cu.get("board", []) as Array).is_empty()
	var ev = info.get("event")
	var round_n := int(V["round"])
	var warn: bool = ev is Dictionary and ev.get("k") in ["reinf_enemy", "reinf_ally"] and not ev.get("done", false) and int(ev.get("warnR", round_n + 1)) <= round_n and round_n < int(ev.get("r", 0)) and not info.get("arrived", false)
	if tip_pending == "reinforce_warn" and not warn: tip_pending = ""
	var cond := {"select": tip_handed, "target": targets, "fired": tip_shot, "move": tip_enemy_done,
		"threat": int(V["round"]) >= 2, "reinforce_warn": battle_n >= 2 and warn, "close": battle_n >= 2 and close,
		"resolve": battle_n >= 3 and api.has_method("can_command") and api.can_command(),
		"objective": battle_n >= 2 and V.get("obj") != null and str(V["obj"].get("type", "rout")) not in ["rout", "ambush"]}
	# One waiting condition only. It keeps its place until the next available activation.
	if tip_pending == "":
		for t in TIPS:
			if not tips.has(t[0]) and not tip_dismissed.has(t[0]) and cond.get(t[0], false):
				tip_pending = t[0]
				break
	if tip_pending == "" or busy or warming or opening or tip_slot == "" or tip_shown_slots.has(tip_slot): return
	for t in TIPS:
		if t[0] == tip_pending:
			tip_current = tip_pending
			tip_pending = ""
			tip_shown_slots[tip_slot] = true
			hud.show_tipcard(t[0], t[1], t[2])
			_tip_log("show", t[0])
			return


func _load_opts() -> void:
	var o := Teaching.load_opts()
	tips = o["tips"]
	tips_off = bool(o.get("tipsOff", false))
	var sp = o.get("speed", 1.0)
	user_speed = float(sp) if (sp is int or sp is float) and is_finite(float(sp)) and float(sp) > 0.0 else 1.0
	Teaching.save_opts({})
	_sync_teaching_switch()


func _sync_teaching_switch() -> void:
	tips_off = Teaching.is_off()
	if args.has("no-tips") or args.has("shots") or args.has("breach-shots") or args.has("f1-trace") or args.has("ui-shots") or args.has("tree-shots"):
		tips_off = true


func _save_opts() -> void:
	Teaching.save_opts({"tips": tips, "tipsOff": tips_off, "speed": user_speed})


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
			var r0 = api.R.B["round"]
			api.ai_activate(aid)
			# a ship the AI leaves idle (nothing in reach, nothing to launch) never starts its activation: pass it, as the
			# player's Pass does, or the bot would pick it forever (a Corsair carrier fleet softlocked the battle at round 1).
			# Only in the same round: if the AI's action ended the round, the rules reset every activation flag and gave the
			# turn back to the player, so a pass now would spend this ship's first move of the new round (issue 1499)
			if api.R.B["round"] == r0 and api.phase == "player" and api.unit(aid) != null and _jt(api.unit(aid).get("activated")) == false:
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
	if shots_dir != "" and PG.stop_if_any():
		return
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
		preload("res://tools/picture_provenance.gd").save_jpg(img, move_frames.path_join("%04d.jpg" % shot_n), 0.85, preload("res://tools/picture_provenance.gd").capture_stage())
		return
	DirAccess.make_dir_recursive_absolute(shots_dir)
	shot_n += 1
	var p := shots_dir.path_join("%02d_%s.png" % [shot_n, name])
	preload("res://tools/picture_provenance.gd").save_png(img, p, preload("res://tools/picture_provenance.gd").capture_stage())
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
	hud.visible = false  # the panels and the battle log covered ships at the frame's edges (R55 A/B)
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
		# frame the whole burn: every hex on the path plus the hull's length, with a wide margin (R55: wider framing)
		var a: Vector3 = views[id].position
		var lo := Vector2(a.x, a.z)
		var hi := lo
		for st in best.path:
			var pp: Vector3 = board.hex_world(st["q"], st["r"])
			lo = Vector2(minf(lo.x, pp.x), minf(lo.y, pp.z))
			hi = Vector2(maxf(hi.x, pp.x), maxf(hi.y, pp.z))
		var hl := float(views[id].L)
		var ext := (hi - lo) + Vector2(hl, hl) * 1.2
		cam.a = -PI / 2.0
		cam.b = 0.85
		# about 1.47 r of board shows across a 16:9 frame and 1.26 r deep at this pitch; keep the burn in the middle 60%
		cam.r = clampf(maxf(ext.x / 1.47, ext.y / 1.26) / 0.6, 50.0, 320.0)
		var mid2 := (lo + hi) * 0.5
		cam.t = Vector3(mid2.x, 0, mid2.y)
		cam.snap()
		await get_tree().create_timer(0.4).timeout
		var b: Vector3 = board.hex_world(best.q, best.r)
		var vs := get_viewport().get_visible_rect().size
		print("[moves] %s frame r %.0f, start on screen %s, end %s (of %s)" % [str(id), cam.r, str(cam.unproject_position(a).round()), str(cam.unproject_position(b).round()), str(vs)])
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
		print("[moves] %s done: %d frames, at rest on screen %s, camera target %s r %.0f" % [str(id), shot_n - n0, str(cam.unproject_position(views[id].position).round()), str(cam.t.round()), cam.r])
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
	if PG.stop_if_any():
		return
	preload("res://tools/picture_provenance.gd").save_png(get_viewport().get_texture().get_image(), str(args["planet-shot"]), preload("res://tools/picture_provenance.gd").capture_stage())
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


# --maneuver straight|turn|side|back|long (with --move-frames): how well a path shows one maneuver; -1e9 when it does not
#   straight: ahead only, the longer the better; turn: turns in place then ahead (rotate, then burn);
#   side: sidesteps only; back: backing off only
func _maneuver_score(path: Array, want: String) -> float:
	var n_rot := 0
	var n_slip := 0
	var n_rev := 0
	var n_fwd := 0
	var rot_after_move := false
	var mid_turn := false        # a turn with runs both before and after it
	for st in path:
		if _jt(st.get("rot")):
			n_rot += 1
			if n_fwd + n_slip + n_rev > 0:
				rot_after_move = true
		elif rot_after_move:
			mid_turn = true
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
		"long":
			# F2: the longest move with turns, a turn between two runs counting most (a straight run when the ship has
			# no turn to spare)
			if n_rev > 0 or n_fwd + n_slip == 0:
				return -1e9
			return float(n_fwd) + float(n_slip) * 0.8 + float(n_rot) * 1.5 + (6.0 if mid_turn else 0.0)
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
		cam.a = float(v[0]); cam.b = float(v[1]); cam.r = rr; cam.t = sv.visual_position()
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


# Issue 521 (carried item 4 of the issue 505 report): _quit frees the scene's children and waits two frames; a command
# still awaiting (the capture's end_activation) then resumed into _refresh_ui and _overlay on the freed HUD and board, a
# script error and then a crash on shutdown. Once quitting, neither draws.
var quitting := false


func _quit(code := 0) -> void:
	quitting = true
	if code == 0 and shots_dir != "" and PG.stop_if_any():
		code = 1
	var m = get_node_or_null("/root/Main")
	if m != null and m.has_method("quit_clean"):
		m.quit_clean(code)
		return
	set_process(false)
	for c in get_children():
		c.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# issue 1204: every script with a GPU-holding static is on one list (render/static_caches.gd)
	load("res://render/static_caches.gd").clear_all()
	get_tree().quit(code)
