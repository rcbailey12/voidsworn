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
	["close", "Close action", "Ramming speed (X) charges the first enemy dead ahead. Boarding (G) sends crews into an adjacent enemy; win and the ship is yours."],
	["threat", "Threat map", "Before you end a move, check where the enemy can reach. Press R, or Threat in the top bar, to shade every hex their guns can hit next turn: the darker the hex, the more damage is waiting there."],
	["objective", "Objectives", "Not every fight is a slugging match. The top bar shows this fight's goal."],
]

var args := {}
var api
var R                      # api.R, read only (previews and tips)
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
var speed := 1.0           # the game's SPEED (duration multiplier)
var user_speed := 1.0      # Speed: normal (1) or fast (0.45)
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
var arcs_on := false
var floats: Array = []
var ended := false
var fired_in_act := {}     # unit id -> weapons fired this activation (volley pace)
var tips := {}
var tips_off := false
var bot := false
var bot_t := 0.0
var bot_moved := {}
var shots_dir := ""
var t_start := 0.0
var marker_root: Node3D
var backdrop: Node3D
var gfx = null            # G4 fx (res://fx/fx.gd) when present
var arrow: MeshInstance3D
var path_dots: MultiMeshInstance3D
var errors: Array = []
var result := {}
var battle_cfg := {}
var ai_level := ""         # "veteran" or "standard" (settings); empty keeps the rules default
var can_retreat := false   # campaign battles (not against a sector flagship): the top bar offers Retreat
var external := false      # run by godot/main (campaign or quick battle): no own restart, the end card says Continue
var last_progress := 0.0   # real time of the last event batch (softlock watchdog for bot runs)
var softlock_s := 60.0


func _ready() -> void:
	_args()
	t_start = Time.get_ticks_msec() / 1000.0
	bot = bot or args.has("bot")
	shots_dir = str(args.get("shots", ""))
	_load_opts()
	_build_world()
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	sfx.cam = cam
	hud = HUD.new()
	add_child(hud)
	hud.action.connect(_on_action)
	if not external:
		start_default()
	if shots_dir != "":
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
	key.transform = Transform3D(Basis.looking_at(KEY_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = KEY_COL
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	key.directional_shadow_max_distance = 600.0
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.transform = Transform3D(Basis.looking_at(FILL_DIR.normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = FILL_COL
	fill.light_energy = 0.5
	add_child(fill)
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
	if ResourceLoader.exists("res://fx/fx.gd"):
		gfx = load("res://fx/fx.gd").new()
		gfx.name = "GFx"
		add_child(gfx)
	cam = CamRig.new()
	cam.name = "Camera"
	add_child(cam)
	cam.current = true
	if gfx != null and gfx.has_method("setup"):
		gfx.setup({"camera": cam, "quality": str(args.get("quality", "max")), "reduce_flashing": false, "shake": 1.0, "unit": 1.0})
	_build_arrow()


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
	start_scenario({"seed": seed, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden"], "fac": fac, "enemies": g,
		"obj": "rout", "shape": "open", "map": str(args.get("map", maps[rng.randi() % maps.size()])), "dep": "line", "kind": "battle"})


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
	R = a.R
	if ai_level != "":
		R.AI_LEVEL = ai_level
	PACE = R.PACE
	ended = false
	result = {}
	errors.clear()
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
	board.build(R)
	cam.bounds = board.bounds()
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
	var F = R.FACTIONS.get(_enemy_fac(), {})
	var ne := 0
	for u in V["units"]:
		if u["side"] == "enemy" and not u["squadron"]:
			ne += 1
	hud.add_log("Contact: %s. %d ship%s on the auspex." % [str(F.get("n", _enemy_fac())), ne, "s" if ne > 1 else ""], "s")
	if R.jt(R.B.get("well")):
		hud.add_log("A dead star warps this field. Ships that start a turn near it get +1 movement from the slingshot, but it drags close ships inward and tears at any hull on its rim.", "s")
	batches.append({"events": api.take_events(), "view": api.view()})
	sfx.ambient_start()
	_refresh_ui()
	if not busy:
		_runner()


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
		gfx.add_ship(str(u["id"]), sv, {"faction": str(u["fac"]), "meshes": sv.meshes, "cls": str(u["cls"]), "size": float(u["size"]), "squadron": bool(u["squadron"]), "flagship": bool(u["flagship"])})


func _sync(v: Dictionary) -> void:
	V = v
	_index_view()
	for u in V["units"]:
		if not views.has(u["id"]):
			_make_view(u)
		var sv = views[u["id"]]
		disp[u["id"]] = {"hp": float(u["hp"]), "sh": (u["sh"] as Array).duplicate()}
		sv.set_marker(u["side"] == "player")
		if gfx != null and gfx.has_method("sync_ship"):
			gfx.sync_ship(str(u["id"]), u)
		if u["dead"]:
			if not sv.dead and not wrecked.has(u["id"]):
				sv.die(false)
			continue
		if not sv.busy():
			var want: Vector3 = board.hex_world(u["q"], u["r"])
			if Vector2(sv.position.x - want.x, sv.position.z - want.z).length() > 0.5 or absf(angle_difference(sv.cur_yaw, ShipView.yaw_of(u["facing"]))) > 0.05:
				sv.position = want
				sv.cur_yaw = ShipView.yaw_of(u["facing"])
				sv.rotation.y = sv.cur_yaw


# ---------------------------------------------------------------- the player loop: play batches, let the enemy think

func _runner() -> void:
	busy = true
	while true:
		if not is_inside_tree():
			return
		if batches.is_empty():
			if api.phase == "enemy" and not ended:
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
		last_progress = Time.get_ticks_msec() / 1000.0
		await _play_batch(bt)
		_sync(bt["view"])
		_refresh_ui()


func _think():
	# the enemy's activation runs on a worker thread, so the frame never stalls while it decides
	think_out = null
	var tid := WorkerThreadPool.add_task(func() -> void:
		var ev = api.step()
		think_out = {"events": ev, "view": api.view()})
	while not WorkerThreadPool.is_task_completed(tid):
		await get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(tid)
	if R.not_ported != "":
		_error("NOT PORTED: " + R.not_ported)
		R.not_ported = ""
	return think_out


func _cmd(f: Callable) -> bool:
	# a player command: the rules act at once, the picture follows
	if busy or ended or api.phase != "player":
		return false
	var ok = f.call()
	var ev: Array = api.take_events()
	if R.not_ported != "":
		_error("NOT PORTED: " + R.not_ported)
		R.not_ported = ""
	if ev.is_empty() and not ok:
		return false
	batches.append({"events": ev, "view": api.view()})
	_clear_overlay()
	_runner()
	return bool(ok)


func _error(m: String) -> void:
	errors.append(m)
	push_warning(m)


func wait(ms: float) -> void:
	await get_tree().create_timer(maxf(ms, 1.0) / 1000.0 * speed).timeout


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


func _play_batch(bt: Dictionary) -> void:
	var evs: Array = bt["events"]
	var enemy := false
	for e in evs:
		if e["t"] == "activation" and e["side"] == "enemy":
			enemy = true
	speed = user_speed
	if enemy:
		speed = minf(speed, float(PACE["skip"]) if skip else (float(PACE["enemy"]) if _player_pending() > 0 else float(PACE["tail"])) * _enemy_pace_k())
	var i := 0
	while i < evs.size():
		var e: Dictionary = evs[i]
		if e["t"] == "fire":
			var grp: Array = []
			var j := i + 1
			while j < evs.size() and evs[j]["t"] in ["hit", "system", "shield_down", "burning"] and str(evs[j].get("target", evs[j].get("unit"))) == str(e["target"]):
				grp.append(evs[j])
				j += 1
			await _play_fire(e, grp)
			i = j
			continue
		await _play_event(e)
		if skip and enemy:
			speed = minf(speed, float(PACE["skip"]))
		i += 1
	if enemy:
		await wait(float(PACE["aiEnd"]))
		hud.set_chip("")
		skip = false
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


func _play_event(e: Dictionary) -> void:
	match e["t"]:
		"round":
			hud.add_log("Round %d." % int(e["round"]), "x")
			fired_in_act.clear()
			if int(e["round"]) > 1 or not bot:
				sfx.turn("round")
				hud.banner("Round %d" % int(e["round"]))
				await wait(float(PACE["banner"]) + 140.0)
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
			hud.add_log("%s: %s destroyed. %s" % [_name(e["unit"]), SEC_NAME.get(sec, sec), "Forward weapons silenced." if sec == "prow" else "Broadsides and shield generator gone." if sec == "mid" else "Engines crippled."], "e" if _side(e["unit"]) == "player" else "p")
		"system":
			hud.add_log("%s: %s." % [_name(e["unit"]), str(e["text"])], "e" if _side(e["unit"]) == "player" else "p")
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
			var A = R.ABILITIES.get(ab, {})
			if ab != "launch":
				hud.add_log("%s: %s." % [_name(e["unit"]), str(A.get("n", ab))], _who(e["unit"]))
			var c: Color = HT.FAC3D.get(str(VU.get(e["unit"], {}).get("fac", "hegemony")), HT.FAC3D["hegemony"])["eng"]
			if gfx != null and gfx.has_method("ability"):
				gfx.ability(str(e["unit"]), ab)
			else:
				fx.flash(_pos(e["unit"]) + Vector3(0, 2, 0), 18.0, c, 0.5)
			if ab == "blink" and e.get("hex") != null:
				sfx.play("phase", {"pos": _pos(e["unit"])})
				var sv = views.get(e["unit"])
				if sv != null:
					sv.position = board.hex_world(e["hex"]["q"], e["hex"]["r"])
					fx.flash(sv.position + Vector3(0, 2, 0), 18.0, c, 0.5)
			elif ab == "nova" and e.get("hex") != null:
				sfx.play("charge", {"pos": _pos(e["unit"])})
				await wait(500.0)
				var p: Vector3 = board.hex_world(e["hex"]["q"], e["hex"]["r"], 2.0)
				fx.bolt(_pos(e["unit"]) + Vector3(0, 2, 0), p, Color(1, 0.8, 0.5), 0.35 * speed, 0.0, 3.0)
				await wait(350.0)
				fx.flash(p, 60.0, Color(1, 0.7, 0.4), 0.8)
				sfx.boom(1.0, p)
			await wait(300.0)
		"order":
			var O = R.ORDERS.get(str(e["order"]), {})
			hud.add_log("%s: %s." % [_name(e["unit"]), str(O.get("n", e["order"]))], _who(e["unit"]))
			if e["order"] == "brace":
				_float(e["unit"], "Braced", Color("#9fd4ff"), -24)
			await wait(200.0)
		"ram":
			await _play_move(e["unit"], e["path"], true)
			sfx.boom(0.8, _pos(e["target"]))
			fx.flash(_pos(e["target"]) + Vector3(0, 2, 0), 30.0, Color(1, 0.7, 0.4), 0.6)
			hud.add_log("%s rams %s at full speed: %d to its %s, %d back to the ram." % [_name(e["unit"]), _name(e["target"]), int(e["dmg"]), SEC_NAME.get(str(e["section"]), str(e["section"])), int(e["recoil"])], _who(e["unit"]))
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
				hud.add_log("Boarding parties from %s take %s. It now fights for %s." % [_name(e["unit"]), _name(e["target"]), "you" if _side(e["unit"]) == "player" else "the enemy"], who)
				_float(e["target"], "Captured", Color("#f0b35a"), -30)
			elif res == "overrun":
				hud.add_log("%s's boarders overrun %s, but the last of its crew hold the bridge." % [_name(e["unit"]), _name(e["target"])], who)
			else:
				hud.add_log("%s boards %s: %d defenders killed, %d boarders lost." % [_name(e["unit"]), _name(e["target"]), int(e["kill"]), int(e["loss"])], who)
			fx.flash(_pos(e["target"]) + Vector3(0, 2, 0), 14.0, Color(1, 0.8, 0.5), 0.5)
			await wait(600.0)
		"command_warning":
			var C = _command(str(e["id"]))
			hud.add_log("%s is preparing %s. It strikes next round." % [_name(e["unit"]), str(C.get("n", e["id"]))], "e")
			hud.banner("%s next round" % str(C.get("n", e["id"])), Color("#ff8a6a"))
			sfx.play("ui_alert")
			await wait(float(PACE["banner"]) + 140.0)
		"command":
			var C = _command(str(e["id"]))
			hud.add_log("%s: %s!" % [_name(e["unit"]), str(C.get("n", e["id"]))], "e" if e["side"] == "enemy" else "p")
			hud.banner(str(C.get("n", e["id"])), Color("#ff8a6a") if e["side"] == "enemy" else Color("#d0a64b"))
			await wait(float(PACE["banner"]) + 140.0)
		"wreck":
			wrecked[e["unit"]] = true
			hud.add_log("The wreck of %s drifts in place, blocking movement and fire." % _name(e["unit"]), "x")
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
			hud.add_log("%s leaves the battle." % _name(e["unit"]), "e" if _side(e["unit"]) == "player" else "s")
			await wait(300.0)
		"end":
			pass


func _command(id: String) -> Dictionary:
	for c in R.COMMANDS.values() if R.COMMANDS is Dictionary else R.COMMANDS:
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
	for st in path:
		var a: float = la + angle_difference(la, ShipView.yaw_of(st["f"]))
		if R.jt(st.get("rot")):
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
	var size := float(u.get("size", 0.5))
	var per := (430.0 if size > 0.8 else 350.0 if size > 0.6 else 280.0) * float(MOVE_PER.get(str(u.get("fac", "")), 1.0))
	var dur := minf((per * maxf(s, 0.001) + 260.0) * (0.72 if charge else 1.0) * float(PACE["move"]), 3600.0) / 1000.0
	sv.speed_k = 1.0
	sv.play_path(keys, yaws, alts, s, dur * speed)
	if size > 0.3:
		sfx.play("engine", {"pos": sv.position, "gain": minf(1.0, 0.55 + size * 0.6)})
	while sv.busy() and not sv.dead:
		if skip:
			sv.speed_k = float(PACE["skip"])
		await get_tree().process_frame


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


func _play_fire(e: Dictionary, grp: Array) -> void:
	var a_id = e["unit"]
	var t_id = e["target"]
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
	if gfx != null and gfx.has_method("volley"):
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
		total = float(r.get("done", 0.6)) / maxf(sp, 0.01)
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
	hud.add_log("%s fires %s at %s: %s.%s" % [_name(a_id), str(e["name"]), _name(t_id), ", ".join(parts), " " + sys_txt + "!" if sys_txt != "" else ""], _who(a_id))
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


func _schedule_impact(t_id, h: Dictionary, delay: float, L: float, shield_col: Color, fam: String) -> void:
	get_tree().create_timer(maxf(delay, 0.001)).timeout.connect(func() -> void:
		_apply_hit(h)
		var sv = views.get(t_id)
		if sv == null:
			return
		var p: Vector3 = sv.position + Vector3(randf_range(-0.3, 0.3) * L, 1.0, randf_range(-0.12, 0.12) * L)
		if float(h["shield"]) > 0 and float(h["hull"]) <= 0:
			fx.shield(sv, L, int(h["quad"]), shield_col)
			fx.flash(p, 4.0 + L * 0.25, shield_col, 0.25, 0.0, false)
			sfx.shield(p)
		else:
			fx.flash(p, 5.0 + L * 0.3 + (8.0 if fam == "torp" else 0.0), Color(1.0, 0.62, 0.3), 0.3)
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
	fx.flash(sv.position + Vector3(0, 1.5, 0), 6.0 + sv.L * 0.3, col, 0.3)
	sfx.hit(sv.position, h.get("crit", false))


func _play_death(e: Dictionary) -> void:
	var id = e["unit"]
	var sv = views.get(id)
	var cause := str(e.get("cause", "blast"))
	var friend := _side(id) == "player"
	var sq := bool(VU.get(id, {}).get("squadron", false))
	hud.add_log("%s %s." % [_name(id), "is shot down" if sq else "is destroyed"], "e" if friend else "p")
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
		await get_tree().create_timer(maxf(0.3, t * 0.6)).timeout
		return
	fx.flash(p, 14.0 + L * 1.6, Color(1.0, 0.65, 0.3), 0.9)
	fx.flash(p + Vector3(L * 0.25, 1, 0), 8.0 + L * 0.8, Color(1.0, 0.85, 0.6), 0.5, 0.15 * speed)
	fx.flash(p - Vector3(L * 0.25, 0, 1), 8.0 + L * 0.8, Color(1.0, 0.5, 0.2), 0.6, 0.3 * speed)
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
	result = {"result": "win" if win else "loss", "rounds": int(V["round"]), "killed": killed, "lost": lost, "errors": errors.duplicate(), "secs": Time.get_ticks_msec() / 1000.0 - t_start, "view": V}
	var body := "%d enemy ship%s destroyed, %d of yours lost, in %d round%s." % [killed, "" if killed == 1 else "s", lost, int(V["round"]), "" if int(V["round"]) == 1 else "s"]
	if bot or args.has("bot-runs"):
		finished.emit(result)
		return
	hud.show_end("Victory" if win else "Defeat", body, win, external)


# ---------------------------------------------------------------- selection, overlays, tips

func _sel_unit() -> Dictionary:
	return VU.get(sel, {})


func _can_act() -> bool:
	return not busy and not ended and api != null and api.phase == "player"


func _usable(u: Dictionary) -> bool:
	# ui3d.js canUse: a ship that has not acted, while no other ship is mid-activation
	if u.is_empty() or u["side"] != "player" or u["dead"] or u["activated"]:
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
	var foes: Array = R.alive("enemy")
	var ready: Array = []
	for w in ru["weapons"]:
		if R.weaponReady(w) and w["k"] != "flak":
			ready.append(w)
	var best := {}
	for st in reach_states:
		var k: String = board.key(st.q, st.r)
		if not reach_alt.has(k):
			reach_alt[k] = []
		reach_alt[k].append(st)
		var n := 0
		var sc := -float(st.cost) * 10.0 - float(st.get("t", 0))
		if not ready.is_empty() and not foes.is_empty():
			var v = R.stateView(ru, st)
			for w in ready:
				for t in foes:
					if R.inReach(v, w, t):
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
	var ru = api.unit(sel)
	var out: Array = []
	if ru == null:
		return out
	var idx: Array = [armed] if armed >= 0 else range(ru["weapons"].size())
	for i in idx:
		if api.can_fire(sel, i, t_id):
			out.append(i)
	return out


func _attack_move(t_id: String):
	# v51 attack-move: an enemy your guns can't reach yet; burn to the best hex for that shot and fire
	var ru = api.unit(sel)
	var tu = api.unit(t_id)
	if ru == null or tu == null or R.jt(ru.get("braced")):
		return null
	var idx: Array = []
	for i in ([armed] if armed >= 0 else range(ru["weapons"].size())):
		var w = ru["weapons"][i]
		if w["k"] != "flak" and R.weaponReady(w):
			idx.append(i)
	if idx.is_empty():
		return null
	var best = null
	for st in reach_states:
		if int(st.q) == int(ru["q"]) and int(st.r) == int(ru["r"]):
			continue
		var v = R.stateView(ru, st)
		var n := 0
		for i in idx:
			if R.inReach(v, ru["weapons"][i], tu):
				n += 1
		if n == 0:
			continue
		var hx := 0
		for p in st.path:
			if not R.jt(p.get("rot")):
				hx += 1
		var sc := n * 100.0 - float(st.cost) * 3.0 - float(st.get("t", 0)) + (4.0 if hx >= 2 else 0.0)
		if best == null or sc > float(best["sc"]):
			best = {"st": st, "n": n, "sc": sc, "of": idx.size()}
	return best


func _clear_overlay() -> void:
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
	if arcs_on and _usable(u):
		var ar := _arc_rings()
		for k in ar:
			if not rings.has(k):
				rings[k] = ar[k]
	if mode in ["nova", "blink", "launch"]:
		for h in _ability_hexes():
			fills[board.key(h.q, h.r)] = Color(0.55, 0.8, 1.0, 0.3)
			rings[board.key(h.q, h.r)] = Color(0.6, 0.85, 1.0, 0.8)
	if mode == "board" and not u.is_empty():
		for t in R.boardTargets(api.unit(sel)):
			rings[board.key(t["q"], t["r"])] = Color(1, 0.75, 0.3, 1)
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
			if R.jt(p.get("rot")):
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
	if key != _threat_key:
		_threat_key = key
		var t0 := Time.get_ticks_msec()
		_threat_cache = _compute_threat()
		print("[battle] threat map %d ms" % (Time.get_ticks_msec() - t0))
	var out := {}
	var mx := 1.0
	for k in _threat_cache:
		mx = maxf(mx, float(_threat_cache[k]))
	for k in _threat_cache:
		var f := float(_threat_cache[k]) / mx
		out[k] = Color(0.95, 0.18, 0.12, 0.08 + 0.4 * f)
	return out


func _compute_threat() -> Dictionary:
	var map := {}
	var hexes: Array = board.cells
	for e in R.alive("enemy"):
		var ws: Array = []
		for w in e["weapons"]:
			if float(R.z0(w.get("off"))) <= 1 and float(R.z0(w.get("cdLeft"))) <= 1 and w["k"] != "flak":
				ws.append(w)
		if ws.is_empty():
			continue
		var seen := {}
		var states: Array = [{"q": e["q"], "r": e["r"], "f": e["facing"], "cost": 0, "path": []}]
		if not R.jt(e.get("isSq")):
			states.append_array(R.computeReach(e).states)
		var maxr := 0
		for w in ws:
			maxr = maxi(maxr, int(w["r"]))
		var mul := float(e.get("dmg", 1)) if e.get("dmg") != null else 1.0
		var per := {}
		var near_c := {}
		for st in states:
			var sk := "%d,%d,%d" % [int(st["q"]), int(st["r"]), int(st["f"])]
			if seen.has(sk):
				continue
			seen[sk] = true
			var v = R.stateView(e, st)
			var pk := "%d,%d" % [int(st["q"]), int(st["r"])]
			if not near_c.has(pk):
				var nl: Array = []
				for h in hexes:
					var hh0 := {"q": h.q, "r": h.r}
					var d0: int = R.hdist(v, hh0)
					if d0 <= maxr:
						nl.append([hh0, d0])
				near_c[pk] = nl
			for nd in near_c[pk]:
				var hh: Dictionary = nd[0]
				var d: int = nd[1]
				var h := hh
				var val := 0.0
				for w in ws:
					if d <= int(w["r"]) and R.inArc(v, hh, w["arc"]):
						val += float(w["shots"]) * float(w["dmg"]) * mul
				if val <= 0.0:
					continue
				var k: String = board.key(h.q, h.r)
				if val > float(per.get(k, 0.0)) and R.los(v, hh):
					per[k] = val
		for k in per:
			map[k] = float(map.get(k, 0.0)) + float(per[k])
	return map


# the selected ship's firing arcs (V): every hex a ready gun reaches from where it stands
func _arc_rings() -> Dictionary:
	var out := {}
	var ru = api.unit(sel) if sel != "" else null
	if ru == null:
		return out
	for h in board.cells:
		var hh := {"q": h.q, "r": h.r}
		var d: int = R.hdist(ru, hh)
		if d < 1:
			continue
		for w in ru["weapons"]:
			if w["k"] != "flak" and R.weaponReady(w) and d <= int(w["r"]) and R.inArc(ru, hh, w["arc"]):
				out[board.key(h.q, h.r)] = Color(1.0, 0.55, 0.25, 0.35)
				break
	return out


# target hexes for nova, blink and launch
func _ability_hexes() -> Array:
	var ru = api.unit(sel) if sel != "" else null
	if ru == null:
		return []
	match mode:
		"nova":
			return R.novaTargets(ru)
		"blink":
			return R.blinkHexes(ru)
		"launch":
			return R.launchHexes(ru)
	return []


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
	# turning in place: the reach state on the ship's own hex with the next facing (rotate in place is not in the rules API yet)
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
	if not R.canOrder(api.unit(id), o):
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
	if active == "" and sel != "" and _usable(_sel_unit()):
		_cmd(func(): api.end_activation(id); return true)
	else:
		_cmd(func(): api.end_activation(); return true)
	sfx.play("ui_confirm")
	sel = ""
	armed = -1


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
	if not _can_act() or hover.x == 99999:
		return
	var u := _unit_at(hover.x, hover.y)
	var s := _sel_unit()
	if mode in ["nova", "blink", "launch"] and not s.is_empty():
		var m := mode
		mode = ""
		var ok := false
		for h in _ability_hexes():
			if int(h.q) == hover.x and int(h.r) == hover.y:
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
						if tu == null or R.jt(tu.get("dead")) or api.phase != "player":
							break
					return any)
				armed = -1
				return
			var am = _attack_move(u["id"])
			if am != null:
				var id := sel
				var tid: String = u["id"]
				var st = am["st"]
				_cmd(func():
					if not api.move(id, st):
						return false
					for i in range(api.unit(id)["weapons"].size()):
						if armed >= 0 and i != armed:
							continue
						if api.can_fire(id, i, tid):
							api.fire(id, i, tid)
						var tu = api.unit(tid)
						if tu == null or R.jt(tu.get("dead")) or api.phase != "player":
							break
					return true)
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
	var ru = api.unit(sel)
	var tu = api.unit(t_id)
	if ru == null or tu == null:
		return ""
	if R.jt(ru.get("braced")):
		return "This ship is braced and can't fire."
	var d: int = R.hdist(ru, tu)
	var any_ready := false
	var in_range := false
	var in_arc := false
	for w in ru["weapons"]:
		if w["k"] == "flak" or not R.weaponReady(w):
			continue
		any_ready = true
		if d <= int(w["r"]):
			in_range = true
			if R.inArc(ru, tu, w["arc"]):
				in_arc = true
	if not any_ready:
		return "Every gun has already fired or is reloading."
	if not in_range:
		return "Out of range."
	if not in_arc:
		return "No ready gun points at it. Turn the ship (Q/E) or move."
	return "Line of sight is blocked."


func _tip() -> String:
	if hover.x == 99999 or busy or api == null or api.phase != "player":
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
	var terr := str(V["terrain"].get(hk, ""))
	if terr != "":
		var info = R.TB.get("TERRAIN_INFO", {}).get(terr, {}) if R.TB is Dictionary else {}
		if info is Dictionary and not info.is_empty():
			return "[b]%s[/b]\n%s" % [str(info.get("n", terr)), str(info.get("fx", info.get("d", "")))]
		return "[b]%s[/b]" % terr.capitalize()
	return ""


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
	var tv: Dictionary = VU[t_id]
	var quad: int = R.shieldQuad(tu, ru)
	var rear := quad == 2
	var rows := ""
	var hull := 0.0
	var sh := 0.0
	var n := 0
	var idx: Array = [armed] if armed >= 0 else range(ru["weapons"].size())
	for i in idx:
		var w = ru["weapons"][i]
		var right := ""
		if R.z0(w.get("off")) > 0:
			right = "[color=#e27f74]offline[/color]"
		elif R.z0(w.get("cdLeft")) > 0:
			right = "[color=#7d7768]reloading[/color]"
		elif R.jt(w.get("fired")):
			right = "[color=#7d7768]fired[/color]"
		elif R.jt(ru.get("braced")):
			right = "[color=#7d7768]braced[/color]"
		else:
			var d: int = R.hdist(ru, tu)
			if d > int(w["r"]):
				right = "[color=#7d7768]out of range (%d/%d)[/color]" % [d, int(w["r"])]
			elif not R.inArc(ru, tu, w["arc"]):
				right = "[color=#7d7768]out of arc[/color]"
			elif not R.los(ru, tu):
				right = "[color=#7d7768]blocked[/color]"
			else:
				var pv: Dictionary = api.preview_fire(sel, i, t_id)
				hull += float(pv["hull"])
				sh += float(pv["shield"])
				n += 1
				right = "[b][color=#f0b35a]%d%%[/color][/b] [color=#7d7768]%d×%d[/color]" % [int(pv["hit"]), int(w["shots"]), int(round(R.dmgMult(ru, w, tu, rear)))]
		rows += "%s  %s\n" % [str(w["n"]), right]
	var t := "[b][color=#e27f74]%s[/color][/b]\n[color=#b3aa95]Hull %d/%d, armor %d%%, evasion %d[/color]\n" % [str(tv["name"]), int(tv["hp"]), int(tv["maxHp"]), int(round(float(tu.get("armor", 0)) * 100.0)), int(R.z0(tu.get("ev"))) + int(R.z0(tu.get("evBuff")))]
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
			args.erase("seed")
			start_default()
		"quit":
			get_tree().quit()


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
	var ru = api.unit(id)
	var d: Dictionary = disp.get(id, {"hp": u["hp"], "sh": u["sh"]})
	var info := {"name": u["name"], "cls": u["cls"], "side": u["side"], "flag": u["flagship"], "hp": d["hp"], "maxHp": u["maxHp"], "sh": d["sh"], "shMax": u["shMax"]}
	var stats := "Hull [color=#ffae42]%d/%d[/color]   Armor %d%%   Evasion %d\nMovement %d of %d   Turns %d" % [int(d["hp"]), int(u["maxHp"]), int(round(float(ru.get("armor", 0)) * 100.0)), int(R.z0(ru.get("ev"))), int(u["mp"]), int(R.z0(ru.get("speed"))), int(u["turnsLeft"])]
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
		if float(R.z0(w["off"])) > 0:
			right = "offline"
		elif float(R.z0(w["cd"])) > 0:
			right = "reloading %d" % int(w["cd"])
		elif not w["ready"]:
			right = "fired"
		elif tgt != "" and u["side"] == "player" and api.can_fire(id, int(w["i"]), tgt):
			right = "%d%%" % int(api.preview_fire(id, int(w["i"]), tgt)["hit"])
		else:
			right = "ready"
		var arc_name = R.ARC_NAME.get(str(w["arc"]), str(w["arc"])) if R.ARC_NAME is Dictionary else str(w["arc"])
		ws.append({"i": w["i"], "name": str(w["name"]), "desc": "%s, range %d, %d×%d" % [str(arc_name), int(w["range"]), int(rw["shots"]), int(round(float(rw["dmg"])))], "right": right, "ready": w["ready"], "armed": int(w["i"]) == armed and id == sel})
	info["weapons"] = ws
	if u["side"] == "player" and not u["dead"]:
		var can := _can_act() and _usable(u)
		var orders: Array = []
		orders.append({"text": "Brace (B)", "act": "brace", "on": can and R.canOrder(ru, "brace"), "tip": str(R.ORDERS["brace"]["d"])})
		if u.get("ab") != null:
			var A = R.ABILITIES.get(str(u["ab"]), {})
			orders.append({"text": str(A.get("n", u["ab"])) + ("" if u["abReady"] else " (%d)" % int(u["abCd"])), "act": "ability", "on": can and u["abReady"], "tip": str(A.get("d", ""))})
		orders.append({"text": "Ram (X)", "act": "ram", "on": can and R.ramInfo(ru) != null, "tip": "Charge the first enemy dead ahead (needs a run-up)."})
		orders.append({"text": "Board (G)", "act": "board", "on": can and not R.boardTargets(ru).is_empty(), "tip": "Send boarding crews into an adjacent enemy."})
		orders.append({"text": "Turn left (Q)", "act": "rotl", "on": can})
		orders.append({"text": "Turn right (E)", "act": "rotr", "on": can})
		info["orders"] = orders
	return info


# ---------------------------------------------------------------- per frame: nameplates, floats, bot

func _process(dt: float) -> void:
	if api == null:
		return
	var vs := get_viewport().get_visible_rect().size
	for id in views:
		var sv = views[id]
		var u: Dictionary = VU.get(id, {})
		if u.is_empty() or sv.dead or not sv.visible:
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
	if bot and not busy and not ended and api.phase == "player" and Engine.get_process_frames() % 2 == 0:
		bot_t += dt
		if bot_t > 0.05:
			bot_t = 0.0
			_bot_step()
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
	if tips_off or bot or ended or hud.tipcard != null or api == null or V.is_empty():
		return
	var s := _sel_unit()
	var moved := false
	var fired := false
	var targets := false
	for u in V["units"]:
		if u["side"] == "player" and not u["dead"]:
			var ru = api.unit(u["id"])
			if ru != null and float(ru["mp"]) < float(R.z0(ru.get("speed"))):
				moved = true
			for w in ru["weapons"]:
				if R.jt(w.get("fired")):
					fired = true
	if not s.is_empty() and _usable(s):
		for e in V["units"]:
			if e["side"] == "enemy" and not e["dead"] and not _firing_set(e["id"]).is_empty():
				targets = true
	var close := false
	if not s.is_empty() and api.unit(sel) != null:
		close = R.ramInfo(api.unit(sel)) != null or not R.boardTargets(api.unit(sel)).is_empty()
	var cond := {"start": true, "turns": true, "threat": int(V["round"]) >= 2, "select": not s.is_empty(), "move": moved, "target": targets, "fired": fired, "close": close,
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
	if args.has("no-tips") or args.has("shots"):
		tips_off = true


func _save_opts() -> void:
	var f := FileAccess.open("user://battle_opts.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"tips": tips, "tipsOff": tips_off, "speed": user_speed}))


# ---------------------------------------------------------------- the bot (both sides on AI, for test runs)

# A simple player for test runs through the same commands a person uses: each ship takes the move that brings the most
# guns onto the weakest enemy in reach, fires everything that bears, braces when nothing can, and ends its activation.
func _bot_step() -> void:
	var u_id := ""
	for u in V["units"]:
		if u["active"]:
			u_id = u["id"]
	if u_id == "":
		for u in V["units"]:
			if _usable(u) and not u["squadron"]:
				u_id = u["id"]
				break
	if u_id == "":
		_cmd(func(): api.end_activation(); return true)
		return
	sel = u_id
	var ru = api.unit(u_id)
	# fire first if anything bears
	var tgt := _bot_target(ru)
	if tgt != "":
		var id := u_id
		_cmd(func():
			var any := false
			for i in range(api.unit(id)["weapons"].size()):
				if api.can_fire(id, i, tgt) and api.fire(id, i, tgt):
					any = true
				var tu = api.unit(tgt)
				if tu == null or R.jt(tu.get("dead")) or api.phase != "player":
					break
			return any)
		return
	if float(ru["mp"]) > 0 and bot_moved.get(u_id, -1) != int(V["round"]):
		# the move that deals the most expected damage from where it ends, minus what the enemy can send back there;
		# with nothing in reach, close on the nearest enemy
		var states: Array = api.reach(u_id)
		var best = null
		var bs := -1e9
		var foes: Array = R.alive("enemy")
		for st in states:
			var v = R.stateView(ru, st)
			var out := 0.0
			for w in ru["weapons"]:
				if w["k"] == "flak" or not R.weaponReady(w):
					continue
				var bw := 0.0
				for t in foes:
					if R.inReach(v, w, t):
						var ev = R.expectedVs(v, w, t)
						bw = maxf(bw, float(ev.hull) + float(ev.shield) * 0.4)
				out += bw
			var threat := 0.0
			var near := 1e9
			for t in foes:
				near = minf(near, float(R.hdist(v, t)))
				for w in t["weapons"]:
					if w["k"] != "flak" and R.inReach(t, w, v):
						threat += float(w["dmg"]) * float(w["shots"]) * 0.5
			var sc := out * 3.0 - threat * 0.6 - (near * 4.0 if out <= 0.0 else 0.0) - float(st.cost) * 0.2
			if sc > bs:
				bs = sc
				best = st
		bot_moved[u_id] = int(V["round"])
		if best != null and not (int(best.q) == int(ru["q"]) and int(best.r) == int(ru["r"]) and int(best.f) == int(ru["facing"])):
			var id := u_id
			if _cmd(func(): return api.move(id, best)):
				return
	var id2 := u_id
	if R.canOrder(ru, "brace") and not _any_fired(ru):
		_cmd(func(): return api.order(id2, "brace"))
		return
	_cmd(func(): api.end_activation(); return true)


func _any_fired(ru) -> bool:
	for w in ru["weapons"]:
		if R.jt(w.get("fired")):
			return true
	return false


func _bot_target(ru) -> String:
	var best := ""
	var bs := -1.0
	for i in range(ru["weapons"].size()):
		for t in R.alive("enemy"):
			if api.can_fire(ru["id"], i, t["id"]):
				var pv: Dictionary = api.preview_fire(ru["id"], i, t["id"])
				var sc := float(pv["hull"]) + float(pv["shield"]) * 0.5 + (50.0 if float(pv["hull"]) >= float(t["hp"]) else 0.0)
				if sc > bs:
					bs = sc
					best = t["id"]
	return best


# ---------------------------------------------------------------- screenshot job (--shots <folder>)

var shot_n := 0
var fire_shots := 0


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
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
	while busy or api == null:
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


func _quit_report() -> void:
	print("[battle] report: ", JSON.stringify({"result": result.get("result", "unfinished"), "round": V.get("round"), "errors": errors, "secs": Time.get_ticks_msec() / 1000.0 - t_start}))
	get_tree().quit()
