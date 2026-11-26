extends Node3D
# Voidsworn effects library (G4). The public calls are documented in API.md; this file is the hub:
#   the effect clock (global shader parameter scene_t) and its hit pause; the GPU particle pools; the emit helpers the
#   recipes use; the event-light pool; the flash budget (WCAG 2.3.2, at most 3 counted flashes a second) and the
#   reduce-flashing mode; the trauma shake; a scheduler for things that must happen when a shot lands; and the ship
#   registry. The looks themselves live in fx_weapons.gd (weapons, impacts), fx_ship.gd (engines, shields, staged
#   damage) and fx_death.gd (deaths, wrecks, physics).

const BREACH := preload("res://fx/fx_breach.gd")
const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")
const BOARDING := preload("res://fx/fx_boarding.gd")
const EVENT_PATHS := preload("res://fx/fx_event_paths.gd")
const DAMAGE_PLUME := preload("res://fx/fx_damage_plume.gd")
const SHIP_VIEW := preload("res://render/ship_view.gd")

signal torpedo_shot_down(pos: Vector3)

# Faction colours and styles come from data (fx/faction_looks.json via fx/faction_look.gd; API.md 15), so a faction's
# palette can change without touching code. Styles are Claude's calls (vetoable).
const FLOOK := preload("res://fx/faction_look.gd")
const SPECIAL := preload("res://fx/fx_special.gd")
const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const LIGHT_K := 0.9
const LIGHT_REACH := 30.0   # an event light's standing reach in world units (hexes are 17.3 across)
# Issue 461: a light given its own reach also falls off more slowly (Godot's omni light dims as distance to the power of
# its attenuation). Bench round 1: at the standing 1.2 a torpedo's light changed a cruiser parked 15 units away by under
# 1 percent, so the reach alone lit nothing; at 0.6 the neighbour is lit about five times as much.
const LIGHT_ATTEN := 1.2
const REACH_ATTEN := 0.6
const FLASH_WINDOW := 0.12   # flashes this close are one event (a salvo landing together)
const FLASH_CAP := 3         # counted flashes in any rolling second (WCAG 2.3.1 general flash threshold)
const FLASH_I := 4.0         # sprite intensity from which a short flash-like sprite counts (dimmer pops are free)
const FLASH_LIGHT := 8.0     # light peak from which a decaying event light counts (it lights a big patch of hull)

# --- the flash counter's assumptions, all in one place (issue 504; W3C Understanding SC 2.3.1)
# W3C counts a general flash only when "the combined area of flashes occurring concurrently" passes ".006 steradians
# within any 10 degree visual field on the screen (25% of any 10 degree visual field on the screen) at typical viewing
# distance". That is a viewing angle, so it depends on the screen and how far away the player sits, not on pixels.
# The defaults are the cautious end of a desk set-up: a 32 inch 16:9 screen seen from 24 inches. A bigger screen or a
# closer seat makes the 10 degree box smaller on screen, so set these to the real set-up (setup opts "screen_in",
# "view_in") only when it is known; smaller numbers here are never safer than the truth.
var flash_screen_in := 32.0         # screen diagonal, inches
var flash_aspect := 16.0 / 9.0      # screen width over height
var flash_view_in := 24.0           # eye to screen, inches
const FLASH_FIELD_DEG := 10.0       # W3C's visual field
# The limit itself (flash_limit_px2): the smaller of two readings of the guideline, so the stricter one always holds:
#  - its own number, ".006 steradians", turned into screen pixels through the screen size and distance above (one
#    pixel at the screen centre spans pixel pitch / distance radians, so 0.006 sr is 0.006 / (that)^2 pixels);
#  - a quarter of its own rectangle estimate of the field ("a 341 x 256 pixel rectangle" at 1024 x 768, so 10 degrees
#    wide and 256/341 of that tall), at the same scale.
# Default set-up at 1080 lines: 16,376 px2 by the steradians, 15,606 px2 by the rectangle; the rectangle's is used.
# (A quarter of a 10 by 10 degree square, 20,880 px2, would be 27 to 34 percent too generous: never use it.)
const FLASH_SR := 0.006             # W3C: the combined flashing area allowed in any 10 degree field
const FLASH_W3C_BOX := Vector2(341.0, 256.0)   # W3C's rectangle estimate of a 10 degree field at 1024 x 768
const FLASH_W3C_SHARE := 0.25       # W3C: "25% of any 10 degree visual field"
# Where flashes are gathered: a 10 by 10 degree square tested on a lattice with steps of a quarter of its side, each
# tested square one step wider than that (so any real field, wherever it sits, lies inside a tested one). A bigger
# window only gathers more flash area against the same limit, which is the safe direction.
const FLASH_GRID_DIV := 4
var flash_cands: Array = []         # bright sprites drawn recently: [T, life, x, y, d] (viewport pixels)
var flash_area_log: Array = []      # tests: every bright-flash request [T, x, y, d, lit_max, counted 0/1, drawn bright 0/1, life]
# (x, y, d are -1 when unknown, lit_max -1 when not measured). The staging of death beats is tested on these requests;
# flash_log stays the record of counted flashes, the safety events.
var flash_area_logging := false

# --- settings (API.md 1, 8)
var quality = "max"
var _sfx: Node
# Issue 1077 (on since Ryan's yes on pass 6, Nov 20 2026): a big hull strains along one ragged crack before it splits, and
# its wreck stays grouped where it broke. rendering/effects/death_story="off" or VS_DEATH_STORY=off turns it off.
var death_story := false
var reduce_flashing = false:
	set(v):
		reduce_flashing = v
		RenderingServer.global_shader_parameter_set(&"fx_calm", 1.0 if v else 0.0)
var shake_scale = 1.0
# issue 1582: Reduce motion (the battle sets it): wing attack passes dive gently and never bank
var reduce_motion := false
# F3: scale of every effect's minimum on-screen size (fx_shaders px_world): 1 on (default), 0 off (the r19 look)
var min_px = 1.0:
	set(v):
		min_px = maxf(0.0, v)
		RenderingServer.global_shader_parameter_set(&"fx_px", min_px)
var unit = 1.0
var starboard_z = 1
var compat := false
# Issue 232 damage stress: a multiplier on the shipped damage caps (marks, section marks and persistent fire/smoke/vent
# emitters). 1.0 is the shipped game; the stress bench sets 2 and 4 to find where the frame budget binds.
var cap_k := 1.0
# Issue 232 weapon timing sheet (E31): the effect-loop pins. These are the shipped values; the sheet bench sets a second
# set (one alternate) without touching the game's defaults.
var timing := {"ripple": 0.08, "shell_speed": 160.0, "lance": 0.7, "charge": 0.25, "shield": 0.6}
# Issue 281 vent gas: the shipped look is Cone B, a tight forward cone of gas and sparks along the barrel. "today" draws
# the pre-Cone-B baked gas cell and is only set by the review capture to shoot the before stills; the game leaves it "".
var vent_look := ""
# Bench options only. An unset or unknown name keeps the pre-pick Nova look.
var nova_look := ""
# Optional comparison folder (VS_FX_ATLAS). The production macro, torpedo and death cores load the picked B atlases
# directly from fx/atlases/rebake; they require no environment switch.
var fx_atlas := ""
# Issue 281 stray-puff guard: when a test sets check_radius, every weapon/vent/thruster gas spawn records its world
# position and its source ship (fx_weapons.gd and fx_ship.gd call record_spawn), and stray_spawns() reports any that
# landed more than a small share of that ship's hull length from its real plating (see record_spawn).
var check_radius := false
var effect_spawns: Array = []
var well = Vector3.INF     # the dead star, when the board has one (world.gd sets it): tidal deaths fall toward it
var event_paths := EVENT_PATHS.new()
var dstate = {}
var manual = false
var camera: Camera3D = null
var apply_shake = true

# --- clock
var now = 0.0
var dt := 0.0          # effect seconds advanced by the most recent step
var _speed = 1.0
var _pause_until = -1.0   # effect time; checks hold a pause open with it
var _pause_left = 0.0      # issue 1558 item 4: the hit pause in real seconds, so it lasts the same at any frame rate
var _pause_depth = 1.0
const SPEED_EASE := 55.0  # 1 - exp(-k / 60) = 0.6: the old per-frame lerp at 60 fps, now the same at every frame rate
var _death_slow_left = 0.0  # real seconds, never Engine.time_scale
var _death_hurry_until = -1.0

# --- storage
var pools = {}
var ships = {}
var wrecks: Array = []
var phys_root: Node3D
var notes: PackedStringArray = []
var stats = {"volleys": 0, "deaths": 0}
var rng = RandomNumberGenerator.new()

# --- lights
var _lpool: Array = []
var _lev: Array = []        # [pos, t0, life, peak, col, shape, reach, started]
var _lsrc: Array = []       # persistent: {node, off, col, base, flick, seed}

# --- feel
var _trauma = 0.0
var _shakes: Array = []     # [t, amount, pos]
var _pauses: Array = []     # [t, frames]
var _flashes: PackedFloat64Array = []
var flash_log: PackedFloat64Array = []   # every counted flash (tests check the 3-a-second cap)
var _refused: PackedFloat64Array = []    # flashes the budget turned down (their lights stay dark)
# opus_check_524b (issue 558): a yielded gun flash still draws a soft flash, which is one flash under WCAG 2.3.1. These are
# remembered per field so the soft ones are bounded too: [T, screen x, screen y]. flash_lift is true after a flash_at call
# that refused a flash in a field already holding FLASH_CAP flashes in the last second; the caller then draws no peak at all.
var _soft_mem: Array = []
var flash_lift := false
var _later: Array = []      # min-heap of [t, callable, insertion order]
var _later_serial := 0
var _shake_off = Vector2.ZERO
var _punches: Array = []    # [t, amount] (F3 zoom punch)
var _kick = 0.0             # the zoom punch now (share of the field of view taken off)
var _fov_base = -1.0        # the camera's own field of view, under the punch
var _fov_set = -1.0         # what the punch last wrote
# R367 (issue 1399): straight after an Eclipse core flash the whole scene dims a little for a fifth of a second (never
# under reduce flashing). Eclipse only: the general capital dim option of issue 462 is gone (R389, issue 1509).
const DIM_LIFE := 0.20
const DIM_DEPTH := 0.35
var _dim_veil: MeshInstance3D = null
var _dim_t0 := -1.0

static var _globals_added := false
static var _live_ids: Array = []    # instance ids of live fx nodes (ids, not references, so nothing is kept alive)
var hull_arrays := {}
var _damage_templates := {}
var _power_templates := {}
var _dark_interiors := {}
var _wreck_interiors := {}
const WRECK_SOOT := 0.33   # issue 1077: a strained wreck's insides, a third as bright
var defer_initial_cuts := false
var cut_abort := DEATH.CutAbort.new()
# issue 1434 (LOAD13: the title backdrop built hull damage and death piece shaders in one 7.7 s frame): the title backdrop
# never fights, so a passive fx cuts no hull for a death and builds no damage surfaces
var passive := false
# issue 1434: with defer_initial_cuts, add_ship leaves each shield for prepare_battle_hulls (battle.gd sets it for its load)
var defer_shields := false
var warmup_batch := 0   # issue 1434: warm meshes revealed this many per frame (0: all at once); battle.gd sets 2
var _piece_builds: Array = []
var _shield_jobs := {}
const LOAD_PIECE_BUDGET := 16000  # microseconds per frame while the cover is up
const LOAD_CUT_LIMIT := 8


static func register_globals() -> void:
	_globals_added = true
	SH.ensure_globals()


func _ready() -> void:
	register_globals()
	_live_ids.append(get_instance_id())


func _enter_tree() -> void:
	if closed:
		cut_abort = DEATH.CutAbort.new()
	closed = false


# issue 1434: the warm-up's root while it fills out of the tree, and its meshes waiting to enter (Artoo on PR 1445: a
# battle closed mid warm-up must not leave them orphaned, the coroutine may never resume)
var _warm_off_tree: Node = null
var _warm_parked: Array = []   # [mesh, its parent]


func _free_warm_parked() -> void:
	for pk in _warm_parked:
		if is_instance_valid(pk[0]) and not (pk[0] as Node).is_inside_tree():
			(pk[0] as Node).free()
	_warm_parked = []
	if is_instance_valid(_warm_off_tree) and not _warm_off_tree.is_inside_tree():
		_warm_off_tree.free()
	_warm_off_tree = null


func _exit_tree() -> void:
	_free_warm_parked()
	_set_physics_awake(true)   # the world can outlive this fx (look bench battles share the root world)
	# Issue 1435: leaving a battle no longer waits here for the death cut, shield and damage jobs (5.7 to 6.5 s on the
	# caller with one A16 cut out). The jobs still running are retired with their inputs held and reaped over the
	# next frames; quit drains them all before the rendering server goes (clear_static, and the root's exit as a backstop).
	release(false)


# Issue 1435: once released, this fx takes no new background jobs (death cuts, shield skins, hull damage rebuilds).
var closed := false
# Jobs of released fx nodes still running: one entry per release, {"tids": [task ids], "keep": [what their inputs need]}.
# Each tid is waited for once it is complete (an unawaited task keeps its job alive to the end of the process).
static var _retired: Array = []
static var _reaping := false
static var _exit_hooked := false


# Drop everything that holds GPU resources, so it is freed while the rendering server still exists. Background cut
# tasks are waited for first: an unawaited WorkerThreadPool task keeps its job (hull materials and textures) alive
# until the process ends, after the rendering server is gone (G2: "RenderingServer is null" at exit, a crash risk).
# wait false (issue 1435, the scene change): finished jobs are reaped now, the rest are retired and reaped later.
func release(wait := true) -> void:
	var t_rel := Time.get_ticks_usec()
	closed = true
	cut_abort.cancel()
	attach_report(true)
	_end_dim()
	var tids: Array = []
	var keep: Array = []
	for tid in _death_cut_tasks.keys():
		if wait or WorkerThreadPool.is_task_completed(tid):
			join_death_cut(tid)
		else:
			tids.append(tid)
	_death_cut_tasks.clear()
	for job in _shield_jobs.values():
		if wait or WorkerThreadPool.is_task_completed(job["task"]):
			WorkerThreadPool.wait_for_task_completion(job["task"])
		else:
			tids.append(job["task"])
			keep.append(job)
	_shield_jobs.clear()
	for id in ships:
		var s = ships[id]
		_clear_thrust_spark_sink(s.root)
		s.clear_rift_pose()
		s.end_brownout()
		if not wait and s._dmg_task >= 0 and not WorkerThreadPool.is_task_completed(s._dmg_task):
			tids.append(s._dmg_task)
			keep.append(s._dmg_job)
			s._dmg_task = -1
		else:
			s.wait_damage()
		if s.has_meta("cut_job"):
			keep.append(s.get_meta("cut_job"))
		if s.has_meta("cut_prev"):
			keep.append(s.get_meta("cut_prev"))
		s.remove_meta("cut_task")
		s.remove_meta("cut_work")
		s.remove_meta("cut_job")
		s.remove_meta("cut_prev")
	if not tids.is_empty():
		_retire(tids, keep)
		print("[fx] left with %d jobs still running: retired, not waited for (%.1f ms)" % [tids.size(), float(Time.get_ticks_usec() - t_rel) / 1000.0])
	for w in dstate.get("wrecks", []):
		for l in w.get("lights", []):
			l["on"] = false
	ships.clear()
	hull_arrays.clear()
	_damage_templates.clear()
	_power_templates.clear()
	shield_poses.clear()
	shield_keys.clear()
	_dark_interiors.clear()
	_wreck_interiors.clear()
	_piece_builds.clear()
	_later.clear()
	event_paths.clear()
	_core_at.clear()
	_lev.clear()
	_lsrc.clear()
	_shaders.clear()
	dstate.clear()
	pools.clear()
	_live_ids.erase(get_instance_id())
	if _live_ids.is_empty():
		HULL.clear_shader_cache()


static func _retire(tids: Array, keep: Array) -> void:
	_retired.append({"tids": tids, "keep": keep})
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		drain_retired()
		return
	if not _reaping:
		_reaping = true
		tree.process_frame.connect(reap_retired)
	# the backstop: a quit that skips clear_static still drains before the rendering server is finished (the root leaves
	# the tree after every node under it, so this runs after the last fx has retired its jobs)
	if not _exit_hooked and tree.root != null:
		_exit_hooked = true
		tree.root.tree_exiting.connect(drain_retired)


# Each frame while any are retired: wait for the finished ones (no wait: they are done), keep the rest.
static func reap_retired() -> void:
	for e in _retired.duplicate():
		var left: Array = []
		for tid in e["tids"]:
			if WorkerThreadPool.is_task_completed(tid):
				WorkerThreadPool.wait_for_task_completion(tid)
			else:
				left.append(tid)
		e["tids"] = left
		if left.is_empty():
			_retired.erase(e)
	if _retired.is_empty() and _reaping:
		_reaping = false
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.process_frame.is_connected(reap_retired):
			tree.process_frame.disconnect(reap_retired)


# Wait for every retired job now (quit: before the rendering server goes).
static func drain_retired() -> void:
	var n := retired_count()
	var t0 := Time.get_ticks_usec()
	for e in _retired:
		for tid in e["tids"]:
			WorkerThreadPool.wait_for_task_completion(tid)
	_retired.clear()
	if n > 0:
		print("[fx] drained %d retired jobs before quit in %.0f ms" % [n, float(Time.get_ticks_usec() - t0) / 1000.0])
	if _reaping:
		_reaping = false
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null and tree.process_frame.is_connected(reap_retired):
			tree.process_frame.disconnect(reap_retired)


static func retired_count() -> int:
	var n := 0
	for e in _retired:
		n += (e["tids"] as Array).size()
	return n


# For a clean quit (G2's main.quit_clean calls it): release every live fx node's resources now.
static func clear_static() -> void:
	drain_retired()   # issue 1435: every retired job ends here, before the rendering server goes
	_retired.clear()
	for iid in _live_ids.duplicate():
		var n = instance_from_id(iid)
		if n != null and is_instance_valid(n):
			n.release()
	_live_ids.clear()
	HULL.clear_static()   # look bench and standalone FX checks also call this quit path


func setup(opts := {}) -> void:
	register_globals()
	rng.seed = int(opts.get("seed", 20261026))
	quality = String(opts.get("quality", "max"))
	# safe mode (G2's play_godot_safe.bat, the Compatibility renderer): no Decals, volumes, distortion or depth-reading
	# shaders; effects still play, plainer, and never error
	compat = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	if compat:
		quality = "low"
	camera = opts.get("camera", null)
	var host := get_parent()
	_sfx = opts.get("sfx", host.get("sfx") if host != null and "sfx" in host else null)
	apply_shake = camera != null
	shake_scale = float(opts.get("shake", 1.0))
	unit = float(opts.get("unit", 1.0))
	starboard_z = 1 if int(opts.get("starboard_z", 1)) >= 0 else -1
	reduce_flashing = bool(opts.get("reduce_flashing", false))
	flash_screen_in = float(opts.get("screen_in", flash_screen_in))
	flash_view_in = float(opts.get("view_in", flash_view_in))
	min_px = float(opts.get("min_px", 1.0))
	# Issue 281: the review capture can ask for the pre-Cone-B look to shoot the before stills; the game's default is the
	# shipped Cone B (see fx_weapons._vent).
	vent_look = String(opts.get("vent_look", OS.get_environment("VS_VENT_LOOK")))
	fx_atlas = String(opts.get("fx_atlas", OS.get_environment("VS_FX_ATLAS")))
	var story := String(opts.get("death_story", OS.get_environment("VS_DEATH_STORY")))
	if story.is_empty():
		story = str(ProjectSettings.get_setting("rendering/effects/death_story", "strain"))
	death_story = story == "strain"
	var rich = quality != "low"
	var soft = "#define SOFT\n" if rich else ""
	var big = quality == "max"
	pools["smk"] = POOLS.Pool.new(12288 if big else 6144, _mat(SH.SPRITE, -1, soft), self, "fx_smoke", POOLS.quad_shape())
	pools["spr"] = POOLS.Pool.new(16384 if big else 8192, _mat(SH.SPRITE, 1, soft), self, "fx_glow", POOLS.quad_shape())
	pools["stk"] = POOLS.Pool.new(16384 if big else 8192, _mat(SH.STREAK, 1), self, "fx_streaks", POOLS.streak_shape())
	pools["rng"] = POOLS.Pool.new(2048, _mat(SH.RING, 0), self, "fx_rings", POOLS.quad_shape())
	pools["rib"] = POOLS.Pool.new(192, _mat(SH.RIBBON, 1), self, "fx_ribbons", POOLS.ribbon_shape(32))
	pools["arc"] = POOLS.Pool.new(64, _mat(SH.ECLIPSE_ARC, 0), self, "fx_eclipse_arcs", POOLS.ribbon_shape(96))
	pools["nlance"] = POOLS.Pool.new(96, _mat(SH.null_lance_code(), 1, "#define NULL_LANCE\n", "null lance"), self, "fx_null_lances", POOLS.ribbon_shape(32))
	pools["null"] = POOLS.Pool.new(192, _mat(SH.NULL_SLUG, 1), self, "fx_null_slugs", POOLS.streak_shape())
	var srng = RandomNumberGenerator.new()
	srng.seed = 991
	pools["shd"] = POOLS.Pool.new(768 if big else 384, _mat(SH.SHARD, 0), self, "fx_chips", POOLS.shard_shape(srng), func() -> Array: return POOLS.shard_shape(srng))
	var finish_slots := FRAGMENTS.COMPAT_FINISH_SLOTS if compat else FRAGMENTS.FINISH_SLOTS
	var fragment_mat := _mat(SH.hit_fragment_code(finish_slots), 0, "", "hit fragments")
	pools["plate"] = FRAGMENTS.Pool.new(384 if big else 192, fragment_mat, finish_slots, self, FRAGMENTS.templates()[0], FRAGMENTS.atlas())
	if big:
		pools["dst"] = POOLS.Pool.new(256, _mat(SH.DISTORT, -20), self, "fx_distort", POOLS.quad_shape())
	for k in (64 if big else (24 if rich else 8)):
		var l = OmniLight3D.new()
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.visible = false
		l.omni_range = LIGHT_REACH * unit
		l.omni_attenuation = LIGHT_ATTEN
		add_child(l)
		_lpool.append(l)
	phys_root = Node3D.new()
	phys_root.name = "fx_physics"
	add_child(phys_root)
	_phys_check_ms = 0
	DEATH.setup_physics(self)
	notes.append("fx: quality %s, %d lights in the event pool" % [quality, _lpool.size()])


# One Shader per distinct source (materials share it): identical shaders compile once, not once per material.
var _shaders := {}

# Issue 376: names for the shader sources that are constants in fx_shaders.gd, so a late shader's log line says
# "mat SPRITE" instead of a hash. Built once on the first late shader.
var _shader_names := {}


func _shader_name(code: String) -> String:
	if _shader_names.is_empty():
		var scr: Script = load("res://fx/fx_shaders.gd")
		var consts: Dictionary = scr.get_script_constant_map()
		for k in consts:
			if consts[k] is String:
				_shader_names[consts[k]] = k
	return str(_shader_names.get(code, "code " + str(code.hash())))


func _mat(code: String, prio := 0, defines := "", label := "") -> ShaderMaterial:
	var key := str(code.hash()) + "|" + defines
	var s: Shader = _shaders.get(key)
	if s == null:
		var name := label
		if name == "":
			name = "mat " + _shader_name(code) + ("" if defines == "" else " " + defines.strip_edges())
		if defines != "":
			var nl = code.find("\n", code.find("render_mode"))
			code = code.substr(0, nl + 1) + defines + code.substr(nl + 1)
		s = HULL.shared_shader(code, name)
		_shaders[key] = s
	var m = ShaderMaterial.new()
	m.shader = s
	m.render_priority = prio
	var eclipse_uniforms := not code.contains("#ifdef NULL_LANCE") or defines.contains("NULL_LANCE")
	if eclipse_uniforms and code.contains("uniform vec3 eclipse_sheath"):
		var shade: Color = faction_info("deathless")["weapon_sheath"]
		m.set_shader_parameter("eclipse_sheath", Vector3(shade.r, shade.g, shade.b))
	if eclipse_uniforms and code.contains("uniform vec3 eclipse_core"):
		var core: Color = faction_info("deathless")["weapon_core"]
		m.set_shader_parameter("eclipse_core", Vector3(core.r, core.g, core.b))
	# Shared materials reuse the same imported masks, including attached
	# engine batches. No textures are created per shot.
	if code.contains("uniform sampler2D kit_flow"):
		m.set_shader_parameter("kit_flow", load("res://fx/textures/beam_flow.png"))
	if code.contains("uniform sampler2D kit_tail"):
		m.set_shader_parameter("kit_tail", load("res://fx/textures/hot_tail.png"))
	if code.contains("uniform sampler2D kit_flake"):
		m.set_shader_parameter("kit_flake", load("res://fx/textures/lit_flake.png"))
	return m


func mat(code: String, prio := 0, defines := "", label := "") -> ShaderMaterial:
	return _mat(code, prio, defines, label)


# Issue 376: how many distinct shaders were first built after the warm-up ended, and their names with frame and time.
func late_shader_count() -> int:
	return HULL.late_shader_count()


func late_shader_names() -> Array:
	return HULL.late_shader_names()


# ---------------------------------------------------------------- clock

func _process(delta: float) -> void:
	if not manual:
		step(delta)


var step_count := 0   # fx steps taken (issue 1237: the shared power-down budget is per step, manual tests included)


# Effect seconds over `t` real seconds while the clock eases from speed `a` to `b` (the exact integral of the ease, so the
# time a hit pause costs is the same at any frame rate)
static func _eased(a: float, b: float, t: float) -> float:
	return b * t - (b - a) * (1.0 - exp(-t * SPEED_EASE)) / SPEED_EASE


func step(delta: float) -> void:
	step_count += 1
	# hit pause: the effect clock slows to a crawl for a few frames, then eases back (input is never blocked)
	var base := 1.0
	if _death_slow_left > 0.0:
		_death_slow_left = maxf(0.0, _death_slow_left - delta)
		base = 0.35 if _death_slow_left > 0.0 else 1.0
	var crawl_spd: float = minf(float(_pause_depth), base)
	# issue 1558 item 4: the hit pause is real seconds. The clock drops into it at once (so a 3-frame pause lands) and
	# crawls only for the time left in it: a long frame (30 fps, a hitch) that ends the pause is split at the boundary
	# and eases back by real time for the rest, so a 50 ms pause crawls 50 ms at any frame rate.
	var real := maxf(delta, 0.0)
	var hold: bool = now < _pause_until
	var crawl: float = 0.0 if hold else minf(real, float(_pause_left))
	_pause_left = maxf(0.0, _pause_left - real)
	if hold or (crawl > 1e-6 and crawl >= real - 1e-9):
		_speed = crawl_spd
		dt = real * _speed
	elif crawl > 1e-6:
		var rest := real - crawl
		dt = crawl * crawl_spd + _eased(crawl_spd, base, rest)
		_speed = lerpf(crawl_spd, base, 1.0 - exp(-rest * SPEED_EASE))
	else:
		dt = _eased(float(_speed), base, real)
		_speed = lerpf(_speed, base, 1.0 - exp(-real * SPEED_EASE))
	now += dt
	RenderingServer.global_shader_parameter_set(&"scene_t", now)
	var t0 := Time.get_ticks_usec()
	_run_later()
	_build_death_pieces()
	_gate_physics()
	t0 = pend("later", t0)
	_update_feel()
	_update_dim()
	for id in ships:
		(ships[id] as SHIP).update(self, dt)
	event_paths.step(now)
	t0 = pend("ships", t0)
	WEAP.update(self, dt)
	DEATH.update(self, dt)
	t0 = pend("weap_death", t0)
	_update_lights()
	for k in pools:
		if k == "plate":
			(pools[k] as FRAGMENTS.Pool).flush(now)
		else:
			(pools[k] as POOLS.Pool).flush()
	pend("lights_pools", t0)


# Issue 1279: Jolt runs its step jobs on the shared worker lanes and keeps each job in a fixed table (2048) until a
# lane has run it. While any body moves (every live ship's hull collider rides its ship, so all battle long), a second
# or more of long work holding every high-priority lane (shader and pipeline compiles on a capital's arrival, a death
# cut's side-by-side lanes) filled that table: "Jolt Physics job system exceeded the maximum number of jobs", and the
# physics step waited on the main thread. The colliders only matter to loose debris and wreck pieces, so the space
# steps only while one of those is awake; with nothing awake Jolt makes no jobs at all.
var _phys_awake := true
var _phys_check_ms := 0
const PHYS_CHECK_MS := 250


func _set_physics_awake(on: bool) -> void:
	if on == _phys_awake or phys_root == null or not phys_root.is_inside_tree():
		return
	PhysicsServer3D.space_set_active(phys_root.get_world_3d().space, on)
	_phys_awake = on


# Called by anything that puts a body into motion under phys_root, before it moves.
func wake_physics() -> void:
	_set_physics_awake(true)
	_phys_check_ms = Time.get_ticks_msec() + PHYS_CHECK_MS


func _gate_physics() -> void:
	if phys_root == null:
		return
	var t := Time.get_ticks_msec()
	if t < _phys_check_ms:
		return
	_phys_check_ms = t + PHYS_CHECK_MS
	var awake := false
	for n in phys_root.get_children():
		var rb := n as RigidBody3D
		if rb != null and not rb.freeze and not rb.sleeping and not rb.is_queued_for_deletion():
			awake = true
			break
	# Issue 1466 (Astra pass 2, finding 3): a hull is not a rigid body, so with every plate at rest the space slept and a
	# ship crossing settled plates passed straight through them. A hull that moved since the last look and whose path
	# (where it was, where it is, and as far again ahead) comes near a resting body keeps the space awake; Jolt then
	# knocks the plate and _settle_debris puts it back to rest. An empty board, or hulls far from any debris, still sleeps.
	var near := _hull_near_debris()
	if near: _phys_check_ms = t + PHYS_CHECK_MOVING_MS
	_set_physics_awake(awake or near)


const PHYS_CHECK_MOVING_MS := 100   # the next look comes sooner while a moving hull is near debris


func _hull_near_debris() -> bool:
	var movers: Array = []
	for h in get_tree().get_nodes_in_group(DEATH.HULL_GROUP):
		var hb := h as Node3D
		if hb == null or not hb.is_inside_tree(): continue
		var p := hb.global_position
		var prev: Vector3 = hb.get_meta("gate_prev", p)
		hb.set_meta("gate_prev", p)
		var moved := p - prev
		if moved.length_squared() < 1e-6 * unit * unit: continue
		var reach: float = float(hb.get_meta("fx_reach", -1.0))
		if reach < 0.0:
			reach = DEATH.body_reach(hb)
			hb.set_meta("fx_reach", reach)
		movers.append([prev, p + moved, reach + 1.5 * unit])
	if movers.is_empty(): return false
	for n in phys_root.get_children():
		var rb := n as RigidBody3D
		if rb == null or rb.freeze or rb.process_mode == Node.PROCESS_MODE_DISABLED or not rb.visible or rb.is_queued_for_deletion(): continue
		var q := rb.global_position
		for m in movers:
			var a: Vector3 = m[0]
			var ab: Vector3 = (m[1] as Vector3) - a
			var k := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
			if q.distance_squared_to(a + ab * k) < float(m[2]) * float(m[2]):
				return true
	return false


# F3 profiling (the 20-ship bench's hitch frames): microseconds of main-thread fx work per named section since the last
# prof_take(). pend adds the time since t0 to `name` and returns now (chain it). Cheap enough to leave on.
var prof := {}


func pend(name: String, t0: int) -> int:
	var t1 := Time.get_ticks_usec()
	prof[name] = int(prof.get(name, 0)) + (t1 - t0)
	return t1


func prof_take() -> Dictionary:
	var p := prof
	prof = {}
	return p


# issue 1434 (LOAD17: 83 pipelines in one hull-prep draw): what hull prep put into the scene since the bench last read
# it, by kind (shield built, shield skin, cut finished, death pieces), so a long draw names the installs before it
var installs := {}


func count_install(kind: String) -> void:
	installs[kind] = int(installs.get(kind, 0)) + 1


func installs_take() -> Dictionary:
	var d := installs
	installs = {}
	return d


# Persistent damage is continuous emission and never calls flash(). Report its
# real allocation alongside prof_take(), including faction equivalents of fire.
func damage_counts() -> Dictionary:
	var out := {"fire": 0, "smoke": 0, "vent": 0, "particles": 0}
	for sid in ships:
		var s = ships[sid]
		if s.dead or s.gone: continue
		var counts: Dictionary = s.damage_counts()
		for key in out: out[key] += counts[key]
	return out


func anim_speed() -> float:
	return _speed


func later(t: float, f: Callable) -> void:
	if t <= now:
		f.call()
		return
	var entry := [t, f, _later_serial]
	_later_serial += 1
	var i := _later.size()
	_later.append(entry)
	while i > 0:
		var parent := (i - 1) >> 1
		if not _later_before(entry, _later[parent]):
			break
		_later[i] = _later[parent]
		i = parent
	_later[i] = entry


static func _later_before(a: Array, b: Array) -> bool:
	return int(a[2]) < int(b[2]) if a[0] == b[0] else float(a[0]) < float(b[0])


func _pop_later() -> Array:
	var first: Array = _later[0]
	var last: Array = _later.pop_back()
	var size := _later.size()
	if size == 0:
		return first
	var i := 0
	var child := 1
	while child < size:
		if child + 1 < size and _later_before(_later[child + 1], _later[child]):
			child += 1
		if not _later_before(_later[child], last):
			break
		_later[i] = _later[child]
		i = child
		child = 2 * i + 1
	_later[i] = last
	return first


func free_effect(ref: WeakRef) -> void:
	var node = ref.get_ref()
	if is_instance_valid(node): node.queue_free()


# Issue 1237: one-shot pictures (death flipbooks, staged flashes and smoke, hull hit pictures) come from a reused pool
# instead of a new node, quad and material each (fx_pool.gd Pictures). `make` builds the material only when the pool has
# none free for `key`. Return it with free_picture, bound with the picture's pic_gen, never with free_effect.
func picture(key: String, make: Callable, node_name: String) -> MeshInstance3D:
	return pictures().take(self, key, make, node_name)


func pictures() -> POOLS.Pictures:
	if not dstate.has("pics"): dstate["pics"] = POOLS.Pictures.new()
	return dstate["pics"]


func free_picture(ref: WeakRef, gen: int) -> void:
	var node = ref.get_ref()
	if not is_instance_valid(node): return
	if dstate.has("pics") and node.has_meta("pic_key"):
		(dstate["pics"] as POOLS.Pictures).give(node, gen)
	else:
		node.queue_free()


func _run_later() -> void:
	var cutoff: float = now
	while not _later.is_empty() and float(_later[0][0]) <= cutoff:
		var e := _pop_later()
		var t0 := Time.get_ticks_usec()
		(e[1] as Callable).call()
		# issue 220: which deferred step a long frame spent its time in (named lambdas and bound functions)
		var us := Time.get_ticks_usec() - t0
		if us > 300:
			var key := "L:" + String((e[1] as Callable).get_method())
			prof[key] = int(prof.get(key, 0)) + us


# ---------------------------------------------------------------- emit helpers (t = absolute effect-clock time)

func _p(a0: Vector4, a1: Vector4, a2: Vector4, a3: Vector4, a4: Vector4) -> PackedFloat32Array:
	return POOLS.pack(a0, a1, a2, a3, a4)


const SMOKY := {3: true, 7: true, 8: true, 15: true, 20: true, 23: true, 27: true, SH.TICK_DROPLET: true}


# `px` (F3 round 2): this sprite's own minimum size on screen, in pixels on a 1080-line screen (0: the kind's floor).
# Used for the moments that must read from the battle camera: impact, muzzle, shield and kill flashes.
func spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
		drag := 0.0, spin := 0.0, acc := 0.0, px := 0.0) -> void:
	# every bright, short, flash-like sprite goes through the flash budget here, whoever calls it (muzzle cores, beam
	# contact, secondary pops, death flames): refused or in reduce-flashing mode it becomes a soft lift with no peak
	# Issue 504: the counter adds this sprite's lit area to the bright ones around it (flash_at).
	if i >= FLASH_I and life <= 0.6 and SH.FLASH_SPRITE_FLOORS.has(kind):
		var size := s0 if kind == 13 else maxf(s0, s1) # The crackle does not grow.
		if not flash_at(p, t, size, SH.flash_sprite_floor(kind, px), life):
			kind = 18
			i = minf(i, 3.0) * 0.4
			life = maxf(life * 3.0, 0.4)
	_emit_spr(p, t, life, col, i, s0, s1, kind, vel, drag, spin, acc, px)


# The sprite itself, after the flash decision. Pop and shield crackle book their own pictures.
var spr_kinds = null   # checks only (issue 1586): a Dictionary here counts every sprite emitted, by kind
var rib_log = null     # checks only (issue 1586): an Array here logs every ribbon emitted as [start time, colour]


func _emit_spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
		drag := 0.0, spin := 0.0, acc := 0.0, px := 0.0) -> void:
	if spr_kinds != null:
		spr_kinds[kind] = int(spr_kinds.get(kind, 0)) + 1
	var smoke := kind == SH.ROCKET_SMOKE or SMOKY.has(kind)
	var pool: POOLS.Pool = pools["smk"] if smoke else pools["spr"]
	pool.emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life), Vector4(col.r, col.g, col.b, i),
		Vector4(s0 * unit, s1 * unit, kind, minf(rng.randf(), 0.999) + floorf(clampf(px, 0.0, 4000.0))), Vector4(0.0, acc, drag, spin)))


# A sprite with its own pixel floor (the same as spr with px; shorter to call).
func sprx(px: float, p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
		vel := Vector3.ZERO, drag := 0.0) -> void:
	spr(p, t, life, col, i, s0, s1, kind, vel, drag, 0.0, 0.0, px)


# `wpx`, `lpx` (F3 round 2): this streak's own minimum width and length on screen (pixels at 1080 lines; 0: the kind's).
func flight_streak(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
		drag := 0.0, acc := 0.0, wpx := 0.0, lpx := 0.0) -> void:
	assert(kind not in [1, 7, SPARK_KIND], "Sparks must use fx.spark")
	var pool: POOLS.Pool = pools["null"] if kind == 5 else pools["stk"]
	pool.emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(length, w * unit, drag, kind), Vector4(0.0, acc, wpx, lpx)))


# All thrown sparks use the analytic streak, including crystal glints. This enum selects the
# colour source within the faction palette, not a different renderer.
enum SparkRole { HULL, DEATH, SHIELD, ENGINE, WEAPON }

const SPARK_KIND := 8
# Reserved sprite for cooling coals and stationary glow, not thrown sparks.
const HOT_FLECK_SPRITE := 19


# Keep older callers working. Flight kinds keep their own path, but retired spark
# kinds use the shared spark mask with the caller's original tint and blur time.
func stk(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
		drag := 0.0, acc := 0.0, wpx := 0.0, lpx := 0.0) -> void:
	if kind in [1, 7, SPARK_KIND]:
		spark(p, t, life, FLOOK.FALLBACK, i, length, w, vel, drag, wpx, lpx, SparkRole.HULL, col)
	else:
		flight_streak(p, t, life, col, i, length, w, kind, vel, drag, acc, wpx, lpx)


static func spark_colour(faction: String, role := SparkRole.HULL) -> Color:
	var look := FLOOK.of(faction)
	match int(look.get("wound_kind", 0)):
		1: return Color.TRANSPARENT # Living tissue throws droplets and spores, never sparks.
		3:
			return look.get("accent", look["damage_glow"]) if role == SparkRole.ENGINE else look["damage_glow"]
		2: return FLOOK.death_spark(faction)
	match role:
		SparkRole.DEATH: return FLOOK.death_spark(faction)
		SparkRole.SHIELD: return FLOOK.shield(faction)
		SparkRole.ENGINE: return FLOOK.engine(faction)
		SparkRole.WEAPON: return FLOOK.weapon(faction)
	return look["damage_glow"]


# Shutter is a length of motion history in effect seconds. Velocity is in world units/s.
# Pixel floors describe the whole soft mask, not the hot core.
func spark(p: Vector3, t: float, life: float, faction: String, intensity: float, shutter: float, width: float,
		vel: Vector3, drag := 0.0, wpx := 0.0, lpx := 0.0, role := SparkRole.HULL, tint := Color.TRANSPARENT) -> void:
	if closed or not p.is_finite() or not vel.is_finite() or life <= 0.0 or intensity <= 0.0:
		return
	var data := spark_particle(p, t, life, faction, intensity, shutter, width * unit, vel, drag, wpx, lpx, role, 0.0, tint)
	if not data.is_empty():
		(pools["stk"] as POOLS.Pool).emit(data)


# The idle drive uses these same attributes in a looping hull-local batch.
static func spark_particle(p: Vector3, t: float, life: float, faction: String, intensity: float, shutter: float,
		width: float, vel: Vector3, drag: float, wpx: float, lpx: float, role: int, period := 0.0,
		tint := Color.TRANSPARENT) -> PackedFloat32Array:
	var col := spark_colour(faction, role)
	if col.a <= 0.0:
		return PackedFloat32Array()
	if tint.a > 0.0:
		col = tint
	var glass := 1.0 if int(FLOOK.of(faction).get("wound_kind", 0)) == 2 else 0.0
	return POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(col.r, col.g, col.b, intensity), Vector4(clampf(shutter, 0.015, 0.20), width, maxf(drag, 0.0), SPARK_KIND),
		Vector4(period, glass, wpx, lpx))


# ShipView supplies the existing movement scatter, on this same battle clock and pool.
func _thrust_spark(p: Vector3, life: float, faction: String, world_width: float, vel: Vector3) -> void:
	spark(p, now, life, faction, 2.0, 0.045, world_width / maxf(unit, 1e-4), vel, 2.0, 0.0, 0.0, SparkRole.ENGINE)


func shot_pass_by(at: float, p: Vector3) -> void:
	if sound() != null:
		later(at, func play_pass_by() -> void:
			var sx = sound()
			if sx != null:
				sx.play("shot_pass_by", {"pos": p}))


# The battle's sound node, looked up when a cue plays (Artoo on PR 1699): the battle builds the effects (setup) before
# its Sfx node, so the node handed to setup is null there; the host's sfx field is read again until one exists.
func sound():
	if not is_instance_valid(_sfx):
		var host := get_parent()
		_sfx = host.get("sfx") if host != null and "sfx" in host else null
	return _sfx if is_instance_valid(_sfx) else null


# One head follows the real gauss flight; its deposited light cools for 0.70 s.
# Unlike ordinary capped streaks, this history is measured against shot length.
func null_trace(from: Vector3, to: Vector3, t: float, flight: float, col: Color, k: float) -> void:
	var dv := to - from
	var axis := dv.normalized()
	(pools["null"] as POOLS.Pool).emit(POOLS.pack(Vector4(from.x, from.y, from.z, t),
		Vector4(axis.x, axis.y, axis.z, flight + 0.70), Vector4(col.r, col.g, col.b, 5.0),
		Vector4(dv.length(), 0.4 * k * unit, flight, 5.0), Vector4.ZERO))


# `px` (F3 round 2): the ring's own final size on screen in pixels (shock rings and ripples, kinds 1 to 3); the floor
# grows with the ring, so a far ring still expands.
func ring(p: Vector3, n: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
		speed := 0.0, drag := 0.0, px := 0.0, seed_override := -1.0) -> void:
	var seed_value: float = rng.randf() if seed_override < 0.0 else seed_override
	(pools["rng"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(n.x, n.y, n.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(s0 * unit, s1 * unit, kind, seed_value), Vector4(0.0, speed, drag, px)))


func rib(p: Vector3, dir: Vector3, length: float, t: float, life: float, col: Color, i: float, w0: float, w1: float, kind: int) -> void:
	if rib_log != null:
		rib_log.append([t, col])
	var pool_key := "arc" if kind == 10 else ("nlance" if kind == SH.RIB_NULL_LANCE else "rib")
	var pool: POOLS.Pool = pools[pool_key]
	pool.emit(POOLS.pack(Vector4(p.x, p.y, p.z, kind), Vector4(dir.x, dir.y, dir.z, length),
		Vector4(col.r, col.g, col.b, i), Vector4(w0 * unit, w1 * unit, rng.randf(), 0.0), Vector4(t, life, 0.0, 0.0)))


func shd(p: Vector3, t: float, life: float, vel: Vector3, size: float, heat: float, spin := 4.0, drag := 0.3, tint := 0.0) -> void:
	var ax = rdir()
	(pools["shd"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(ax.x, ax.y, ax.z, spin), Vector4(size * unit, 0.0, tint, drag), Vector4(heat, rng.randf(), 0.0, 0.0)))


# Hull ejecta shares one bounded ring. A negative profile key gives a lead piece the full screen-size floor.
func hit_fragment(p: Vector3, t: float, life: float, vel: Vector3, size: float, heat: float, spin: float, drag: float,
		paint: Color, profile: int, lead: bool, finish := {}) -> void:
	var ax := rdir()
	var particle := POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(ax.x, ax.y, ax.z, spin), Vector4(size * unit, rng.randf(), -1 - profile if lead else profile, drag),
		Vector4(paint.r, paint.g, paint.b, heat))
	(pools["plate"] as FRAGMENTS.Pool).emit(particle, finish)


func dst(p: Vector3, t: float, life: float, s0: float, s1: float, kind: int, strength: float) -> void:
	if not pools.has("dst"):
		return
	(pools["dst"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(0, 1, 0, life), Vector4(1, 1, 1, 1),
		Vector4(s0 * unit, s1 * unit, kind, strength), Vector4.ZERO))


func rdir() -> Vector3:
	var z = rng.randf() * 2.0 - 1.0
	var an = rng.randf() * TAU
	var r = sqrt(1.0 - z * z)
	return Vector3(r * cos(an), r * sin(an), z)


func rcone(axis: Vector3, spread: float) -> Vector3:
	return (axis.normalized() + rdir() * spread).normalized()


# ---------------------------------------------------------------- flash budget (API.md 8)

# Ask to put a counted flash on screen at time T. Returns true when it may draw as a bright flash; false means draw the
# calm version (soft lift, ring, sparks) and no light. Flashes inside FLASH_WINDOW (0.12 s) of a counted one merge
# into it (free). The budget is a trailing window: the second up to T may hold at most FLASH_CAP counted flashes,
# this one included. Volleys book impacts ahead of time, so a flash already booked later than T must also keep its own
# trailing second within the cap once T is in it; that is the second loop (without it a late booking could break the
# cap for a flash booked earlier).
#
# Issue 504: flash_ok(T) still counts unconditionally (a flash whose area is unknown always counts: the vent ignition,
# the death core, a big light). Given where it is (p, its world size, its pixel floor, its life) a counted flash is also
# remembered for the area sums of flash_at, so a small flash beside it adds up with it.
func flash_ok(T: float, p := Vector3.INF, size := 0.0, px := 0.0, life := FLASH_WINDOW) -> bool:
	if reduce_flashing:
		return false
	var ok := _flash_count(T)
	var c := PackedFloat64Array([-1.0, -1.0, -1.0])
	if p != Vector3.INF:
		var cd := _flash_disc(p, size, px)
		if not cd.is_empty():
			c = cd
			if ok:
				_flash_remember(T, life, c)
	_flash_note(T, c, -1.0, 1 if ok else 0, 1 if ok else 0, life)
	return ok


func _flash_count(T: float) -> bool:
	var near := PackedFloat64Array()
	for f in _flashes:
		if absf(f - T) < FLASH_WINDOW:
			return true
		if absf(f - T) < 1.0:
			near.append(f)
	# the trailing second (T - 1, T]
	var c := 1
	for f in near:
		if f <= T:
			c += 1
	var ok := c <= FLASH_CAP
	# flashes booked after T: their trailing seconds (f - 1, f] now hold T too
	if ok:
		for f2 in near:
			if f2 > T:
				var c2 := 1
				for f in near:
					if f > f2 - 1.0 and f <= f2:
						c2 += 1
				if c2 > FLASH_CAP:
					ok = false
					break
	if not ok:
		_refused.append(T)
		if _refused.size() > 64:
			_refused = _refused.slice(32)
		return false
	_flashes.append(T)
	flash_log.append(T)
	if _flashes.size() > 64:
		var keep = PackedFloat64Array()
		for f in _flashes:
			if f > now - 2.0:
				keep.append(f)
		_flashes = keep
	return true


# Issue 504: the flash counter by area, as W3C counts it. Ask to draw one bright, short flash (world size `size`, pixel
# floor `px` at 1080 lines, bright for `life` seconds) at p at time T. True: draw it bright. False: draw the calm
# version (same size and colour, slower rise, lower peak; its light rises softly too, see light()).
# How it decides:
#  1. Its lit area is a disc as wide as the sprite is drawn (the pixel floor counts), rounded up to whole pixels. The
#     baked flashes' sizes are their widest lit extent with bloom, so the disc is larger than the real fireball.
#  2. A flash within FLASH_WINDOW of a counted flash is part of that flash (free), as before.
#  3. Otherwise every bright flash whose bright time overlaps this one's is added up inside each 10 degree box that
#     could hold this one. Each flash adds the smaller of its disc area and its bounding square's overlap with the box,
#     which is never less than the real overlap. If any box holds more than flash_limit_px2 (the guideline's 0.006 sr), this is a
#     general flash: it is counted against FLASH_CAP (three in any rolling second) like any other, or refused.
#  4. Small flashes far apart never add up; small flashes close together do.
# Reduce flashing: false at once, as on main (nothing is booked or remembered).
# Issue 461: `yield_last` (gun hits and muzzles, not torpedoes): a flash that would have to be counted is drawn soft
# instead, so gun fire never spends the three flashes a second that deaths' core flashes need. In the 20-ship storm gate
# salvos of shell hits stacked past the limit, were counted (often booked ahead, at the volley's fire time) and a frigate's
# and a cruiser's core flash were then turned soft. The limit, the window and the cap are unchanged; a hit only ever asks
# for less. Its log row is marked as yielded (flash_area_log column 9).
func flash_at(p: Vector3, T: float, size: float, px := 0.0, life := FLASH_WINDOW, yield_last := false) -> bool:
	flash_lift = false
	if reduce_flashing:
		return false
	if camera == null or not is_instance_valid(camera):
		return flash_ok(T)   # no camera: every bright flash counts, as on main
	var t0 := Time.get_ticks_usec()
	var c := _flash_disc(p, size, px)
	if c.is_empty():
		pend("flash", t0)
		return true   # behind the camera: not on screen
	for f in _flashes:
		if absf(f - T) < FLASH_WINDOW:
			_flash_remember(T, life, c)
			_flash_note(T, c, -1.0, 0, 1, life)
			pend("flash", t0)
			return true
	var lit := _flash_lit_max(T, life, c)
	var bright := true
	var counted := 0
	if lit > flash_limit_px2():
		if yield_last:
			bright = false
			flash_lift = _soft_full(T, c)
			if not flash_lift:
				_soft_mem.append([T, c[0], c[1]])
			_refused.append(T)
			if _refused.size() > 64:
				_refused = _refused.slice(32)
			if flash_area_logging:
				flash_area_log.append([T, c[0], c[1], c[2], lit, 0, 0, maxf(life, FLASH_WINDOW), 1])
			pend("flash", t0)
			return false
		else:
			bright = _flash_count(T)
			counted = 1 if bright else 0
	if bright:
		_flash_remember(T, life, c)
	_flash_note(T, c, lit, counted, 1 if bright else 0, life)
	pend("flash", t0)
	return bright


# opus_check_524b: how many flashes (counted bright ones anywhere, conservatively, plus remembered soft ones inside this
# 10 degree field) fall in the second before T. At FLASH_CAP or more the field is full: the next gun flash gets no peak.
func _soft_full(T: float, c: PackedFloat64Array) -> bool:
	var box := flash_box_px()
	var n := 0
	for f in _flashes:
		if f <= T and T - f < 1.0:
			n += 1
	var keep: Array = []
	for e in _soft_mem:
		if T - float(e[0]) < 1.0:
			keep.append(e)
			if float(e[0]) <= T and absf(float(e[1]) - c[0]) < box and absf(float(e[2]) - c[1]) < box:
				n += 1
	_soft_mem = keep
	return n >= FLASH_CAP


# The side of a 10 degree box in viewport pixels (rounded down, so the box and the limit are never overstated).
# Assumes the game fills the screen's height; in a smaller window the real box is bigger, so this stays cautious.
func flash_box_px() -> float:
	var vh := _flash_vh()
	var screen_h := flash_screen_in / sqrt(1.0 + flash_aspect * flash_aspect)
	var side_in := 2.0 * flash_view_in * tan(deg_to_rad(FLASH_FIELD_DEG) * 0.5)
	return floorf(vh * side_in / screen_h)


# The most flash area allowed at once in any 10 degree field, in viewport pixels (see FLASH_SR above): the smaller of the
# guideline's steradian figure and a quarter of its rectangle estimate. Both are rounded down.
func flash_limit_px2() -> float:
	var vh := _flash_vh()
	var screen_h := flash_screen_in / sqrt(1.0 + flash_aspect * flash_aspect)
	var rad_per_px := (screen_h / vh) / flash_view_in
	var by_sr := floorf(FLASH_SR / (rad_per_px * rad_per_px))
	var w := flash_box_px()
	var h := floorf(w * FLASH_W3C_BOX.y / FLASH_W3C_BOX.x)
	var by_box := floorf(FLASH_W3C_SHARE * w * h)
	return minf(by_sr, by_box)


func _flash_vh() -> float:
	if camera != null and is_instance_valid(camera) and camera.is_inside_tree():
		return maxf(camera.get_viewport().get_visible_rect().size.y, 1.0)
	return 1080.0


# [Screen x, y, diameter]. Like the billboard shaders, project a camera-facing extent at its view-space Z.
# Match px_world in fx_shaders.gd for the floor, including orthographic cameras and the near-depth clamp.
func _flash_disc(p: Vector3, size: float, px: float) -> PackedFloat64Array:
	if camera == null or not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_position_behind(p):
		return PackedFloat64Array()
	var projection := camera.get_camera_projection()
	var depth := -(camera.get_camera_transform().affine_inverse() * p).z
	var ortho := projection.w.w > 0.5
	var p11 := absf(projection.y.y)
	var clip_w := 1.0 if ortho else depth
	if clip_w <= 0.0:
		return PackedFloat64Array()
	var floor_depth := 1.0 if ortho else maxf(depth, 0.01)
	var vh := _flash_vh()
	var world_px := size * float(unit) * p11 * vh / (2.0 * clip_w)
	var floor_px := px * float(min_px) * (vh / 1080.0) * (floor_depth / clip_w) * (p11 / maxf(p11, 0.0001))
	var sp := camera.unproject_position(p)
	return PackedFloat64Array([sp.x, sp.y, ceilf(maxf(world_px, floor_px))])


func _flash_remember(T: float, life: float, c: PackedFloat64Array) -> void:
	flash_cands.append(PackedFloat64Array([T, maxf(life, FLASH_WINDOW), c[0], c[1], c[2]]))
	if flash_cands.size() > 48:
		var keep: Array = []
		for e in flash_cands:
			if float(e[0]) + float(e[1]) > now - 1.0:
				keep.append(e)
		flash_cands = keep


func _flash_note(T: float, c: PackedFloat64Array, lit: float, counted: int, bright: int, life := FLASH_WINDOW) -> void:
	if flash_area_logging:
		flash_area_log.append([T, c[0], c[1], c[2], lit, counted, bright, maxf(life, FLASH_WINDOW)])


# The most lit area any 10 degree box around c can hold from the bright flashes that overlap c in time (c included).
func _flash_lit_max(T: float, life: float, c: PackedFloat64Array) -> float:
	var l := maxf(life, FLASH_WINDOW)
	var S := flash_box_px()
	var g := maxf(floorf(S / FLASH_GRID_DIV), 1.0)
	var B := S + g
	var r := float(c[2]) * 0.5
	# the bright flashes that overlap c in time and could share a tested box with it, as rectangles (c included)
	var rx0 := PackedFloat64Array([c[0] - r])
	var rx1 := PackedFloat64Array([c[0] + r])
	var ry0 := PackedFloat64Array([c[1] - r])
	var ry1 := PackedFloat64Array([c[1] + r])
	var cap := PackedFloat64Array([PI * 0.25 * c[2] * c[2]])
	var reach := r + B
	for e in flash_cands:
		if float(e[0]) < T + l and T < float(e[0]) + float(e[1]):
			var er := float(e[4]) * 0.5
			if absf(float(e[2]) - c[0]) < reach + er and absf(float(e[3]) - c[1]) < reach + er:
				rx0.append(float(e[2]) - er)
				rx1.append(float(e[2]) + er)
				ry0.append(float(e[3]) - er)
				ry1.append(float(e[3]) + er)
				cap.append(PI * 0.25 * float(e[4]) * float(e[4]))
	var n := cap.size()
	# cheap case: all of them together are under the limit, so no box can be over it (still an upper bound)
	var total := 0.0
	for j in n:
		total += cap[j]
	if total <= flash_limit_px2():
		return total
	var best := 0.0
	var kx0 := floori((c[0] - r - B) / g)
	var kx1 := floori((c[0] + r) / g)
	var ky0 := floori((c[1] - r - B) / g)
	var ky1 := floori((c[1] + r) / g)
	# per column of boxes, each flash's x overlap once; then each row adds its y overlap
	var wx := PackedFloat64Array()
	wx.resize(n)
	for kx in range(kx0, kx1 + 1):
		var ox := kx * g
		for j in n:
			wx[j] = minf(ox + B, rx1[j]) - maxf(ox, rx0[j])
		for ky in range(ky0, ky1 + 1):
			var oy := ky * g
			var sum := 0.0
			for j in n:
				if wx[j] > 0.0:
					var wy := minf(oy + B, ry1[j]) - maxf(oy, ry0[j])
					if wy > 0.0:
						sum += minf(wx[j] * wy, cap[j])
			if sum > best:
				best = sum
	return best


# A bright pop (impact flash, explosion core) through the budget: the full flash, or a ring and a gentle lift.
# `px` is the pop's own pixel floor (see spr); a pop only spends a slot if the combined area calls for it.
func pop(p: Vector3, T: float, col: Color, size: float, i: float, n := Vector3.UP, life := 0.14, px := 0.0) -> void:
	# Issue 504: one booking by area (flash_at), whatever its brightness (as on main: every pop is a candidate); the
	# bright sprite is then drawn without a second booking.
	if flash_at(p, T, size, SH.flash_sprite_floor(0, px), life):
		_emit_spr(p, T, life, col, i, size * 0.6, size, 0, Vector3.ZERO, 0.0, 0.0, 0.0, px)
	else:
		spr(p, T, maxf(life * 3.0, 0.4), col, minf(i, 3.0) * 0.4, size * 0.5, size * 1.2, 18, Vector3.ZERO, 0.0, 0.0, 0.0, px * 0.8)
		ring(p, n, T, 0.5, col, 1.2, size * 0.3, size * 1.4, 2, 0.0, 0.0, px)


# ---------------------------------------------------------------- lights

# shape 0 decay, 1 sustain (fades in and out), 2 ramp up (charge)
# A big decaying light is a flash on the hulls it lights: it goes through the budget like a sprite (merging with the
# pop it comes with). A refused flash draws no light at all: a light that goes with a flash the budget turned down
# (within FLASH_WINDOW of it) is dropped, whatever its size. In reduce-flashing mode decay lights rise lower and slower.
#
# Issue 504: a light that goes with a refused flash is no longer dropped. It keeps its colour and place and rises softly
# (shape 3: a 0.1 s or longer rise, then the same fall) at most just under the peak that counts, so the hulls around a
# refused flash are still lit without a sharp step. Reduce Flashing also softens queued or already visible lights.
# Issue 461 (audit item 11): `reach` is how far the light carries, in world units (0: the pool's standing 30, about 1.7
# hexes). A torpedo hit and a death's core flash pass two to three hexes, so the hulls round them are lit for the length
# of the flash. Reach changes only how far the light falls off, never its peak, so the flash counter's rules are the same.
func light(p: Vector3, t: float, life: float, peak: float, col: Color, shape := 0, reach := 0.0) -> void:
	if shape == 0 and not reduce_flashing:
		var refused := false
		for f in _refused:
			if absf(f - t) < FLASH_WINDOW:
				refused = true
				break
		if not refused and peak >= FLASH_LIGHT and not flash_ok(t):
			refused = true
		if refused:
			shape = 3
			peak = minf(peak, FLASH_LIGHT * 0.9)
			life = maxf(life * 1.8, 0.4)
	if reduce_flashing and shape == 0:
		peak *= 0.45
		life *= 1.8
		shape = 3
	_lev.append([p, t, life, peak, col, shape, reach, false])


# Reach is in world units over unit (0 uses LIGHT_REACH). Keep cavity falloff and fog unless the caller opts out.
func light_source(node: Node3D, off: Vector3, col: Color, base: float, flick := 0.3, reach := 0.0,
		phase := -1.0, local_only := false) -> Dictionary:
	var s = {"node": node, "off": off, "col": col, "base": base, "flick": flick, "on": true,
		"seed": rng.randf() * 10.0 if phase < 0.0 else phase, "reach": reach, "local_only": local_only}
	_lsrc.append(s)
	return s


func _update_lights() -> void:
	var ev: Array = []
	var keep: Array = []
	var cp = camera.global_position if camera != null else Vector3.ZERO
	for e in _lev:
		var a: float = now - float(e[1])
		if a < 0.0:
			keep.append(e)
			continue
		var life: float = e[2]
		if a > life:
			continue
		if int(e[5]) == 0:
			if reduce_flashing:
				# A light scheduled while normal gets the same soft rise as a light scheduled in calm mode.
				e[3] *= 0.45
				e[2] *= 1.8
				e[5] = 3
			elif not bool(e[7]):
				# Baked pictures book when they appear, after some of their lights were queued.
				for f in _refused:
					if absf(f - float(e[1])) < FLASH_WINDOW:
						e[3] = minf(float(e[3]), FLASH_LIGHT * 0.9)
						e[2] = maxf(life * 1.8, 0.4)
						e[5] = 3
						break
		e[7] = true
		keep.append(e)
		var u = a / float(e[2])
		var I = 0.0
		match int(e[5]):
			0: I = pow(1.0 - u, 2.0)
			1: I = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.85, 1.0, u)) * (1.0 if reduce_flashing else 0.88 + 0.12 * sin(now * 50.0))
			2: I = u * u
			3: I = smoothstep(0.0, 0.25, u) if u < 0.25 else pow(1.0 - (u - 0.25) / 0.75, 2.0)   # issue 504: soft rise
		ev.append([e[0], I * float(e[3]), e[4], float(e[6]) if e.size() > 6 else 0.0, false])
	_lev = keep
	var ks: Array = []
	for s in _lsrc:
		if not bool(s["on"]) or not is_instance_valid(s["node"]):
			continue
		ks.append(s)
		var n: Node3D = s["node"]
		if not n.is_visible_in_tree():
			continue
		var fl = 1.0 - float(s["flick"]) * (0.5 + 0.5 * sin(now * 23.0 + float(s["seed"])) * sin(now * 7.1 + float(s["seed"]) * 2.0))
		if reduce_flashing:
			fl = 1.0 - float(s["flick"]) * 0.3 * (0.5 + 0.5 * sin(now * 2.0 + float(s["seed"])))
		ev.append([n.global_transform * (s["off"] as Vector3), float(s["base"]) * fl, s["col"], s["reach"], s["local_only"]])
	_lsrc = ks
	# brightest first, nearer lights count more when the pool is short
	for e in ev:
		e.append(float(e[1]) / (1.0 + (e[0] as Vector3).distance_to(cp) / (200.0 * unit)))
	ev.sort_custom(func(a: Array, b: Array) -> bool: return float(a[5]) > float(b[5]))
	var fog_rank := 0
	for k in _lpool.size():
		var scatters := false
		if k < ev.size() and not ev[k][4]:
			scatters = fog_rank < 2
			fog_rank += 1
		var l: OmniLight3D = _lpool[k]
		if k < ev.size() and float(ev[k][1]) > 0.03:
			l.position = ev[k][0]
			l.light_energy = float(ev[k][1]) * LIGHT_K
			l.light_color = ev[k][2]
			l.omni_range = (float(ev[k][3]) if float(ev[k][3]) > 0.0 else LIGHT_REACH) * unit
			l.omni_attenuation = REACH_ATTEN if float(ev[k][3]) > 0.0 and not ev[k][4] else LIGHT_ATTEN
			# Issue 1237 (Neon F7.4): only the two strongest event lights scatter into volumetric fog (all 64 did,
			# each one a pass over the fog froxels); the rest light hulls only.
			l.light_volumetric_fog_energy = 1.0 if scatters else 0.0
			l.visible = true
		else:
			l.visible = false


func active_lights() -> int:
	var n = 0
	for l in _lpool:
		if (l as OmniLight3D).visible:
			n += 1
	return n


# ---------------------------------------------------------------- feel: shake and hit pause (API.md 7)

func shake(t: float, amount: float, pos: Vector3) -> void:
	_shakes.append([t, amount, pos])


func hit_pause(t: float, frames: int) -> void:
	_pauses.append([t, frames])


func death_slowmo() -> void:
	if now >= _death_hurry_until and _death_slow_left <= 0.0:
		_death_slow_left = DEATH_SLOW_S


# Issue 521 (R193, Ryan's pick "Hold and slow"; R73): the slow-motion beat at the core flash of every cruiser, capital
# and flagship kill (fx_ship.death_big). The battle turns it on (off by default, so the effect checks keep their own
# timing) and leaves it off under reduce motion. A key or a click during it calls skip_death_slowmo.
var kill_slowmo := false
const DEATH_SLOW_S := 0.48    # real seconds at about a third of speed (R73), then the clock eases back
var _core_at := {}            # ship id -> planned core time, replaced by its actual birth time


# For probes and captures: the estimate before the flash, then its actual FX time. No staged core returns -1.
func death_core_at(id: String) -> float:
	return float(_core_at.get(id, -1.0))


func resolve_death_core(s: SHIP, flashed: bool) -> void:
	if not s.death_core_pending:
		return
	s.death_core_pending = false
	if ships.get(s.id) != s:
		return
	if flashed:
		_core_at[s.id] = now
		if kill_slowmo and s.slow_core:
			death_slowmo()
	else:
		_core_at.erase(s.id)
	s.slow_core = false


# A key or a click during the beat: back to full speed now, and no new beat from a death already under way.
func skip_death_slowmo() -> void:
	_death_slow_left = 0.0
	_death_hurry_until = maxf(_death_hurry_until, now + 0.1)
	for s in ships.values():
		s.slow_core = false


# Same presentation hurry as the battle. Also suppress a beat scheduled later in this death.
func hurry_death() -> void:
	skip_death_slowmo()
	_death_hurry_until = now + 3.0
	_pause_until = -1.0
	_pause_left = 0.0
	_pauses.clear()
	_speed = 1.0


func shake_offset() -> Vector2:
	return _shake_off


# F3: a short zoom punch for the moments that should land (heavy hits, kills): the view narrows by `amount` (a share of
# the field of view, 0.01 is 1%) in about 0.05 s and eases back over about 0.4 s. Motion, not light: no flash budget,
# halved with reduce flashing, scaled by the shake setting (off with shake off), smaller far from the camera, and never
# more than 6% at once. Applied to camera.fov (fx owns only the punch; it puts the camera's own value back after).
func punch(t: float, amount: float, pos := Vector3.INF) -> void:
	var a := amount
	if pos != Vector3.INF and camera != null and is_instance_valid(camera):
		a /= 1.0 + pos.distance_to(camera.global_position) / (400.0 * unit)
	_punches.append([t, a])


func punch_now() -> float:
	return _kick


func _update_feel() -> void:
	var cp = camera.global_position if camera != null else Vector3.ZERO
	var keep: Array = []
	for s in _shakes:
		if float(s[0]) <= now:
			var d = (s[2] as Vector3).distance_to(cp)
			_trauma = minf(1.0, _trauma + float(s[1]) / (1.0 + d / (120.0 * unit)))
		else:
			keep.append(s)
	_shakes = keep
	keep = []
	for p in _pauses:
		if float(p[0]) <= now:
			var dur = float(p[1]) / 60.0
			_pause_left = maxf(_pause_left, dur)
			_pause_depth = 0.08
		else:
			keep.append(p)
	_pauses = keep
	_update_punch()
	# trauma decays in about 0.3 s from a normal hit, about 0.45 s from the heaviest (A5 ranges)
	_trauma = maxf(0.0, _trauma - dt * 2.4)
	var k = _trauma * _trauma * shake_scale * (0.5 if reduce_flashing else 1.0)
	var T = now
	var amp = 0.06 * k
	_shake_off = Vector2(amp * (sin(T * 37.0) * 0.6 + sin(T * 61.0 + 1.0) * 0.4), amp * (sin(T * 43.0 + 2.0) * 0.6 + sin(T * 71.0) * 0.4))
	if apply_shake and camera != null and is_instance_valid(camera):
		var off: Vector2 = Vector2(_shake_off.x, _shake_off.y) * unit * 10.0
		# issue 1460: the battle camera rig owns h_offset (screen_shift), so hand it the shake and let it add both; a plain
		# Camera3D (test rigs) still takes the offsets directly
		if "shake_offset" in camera:
			camera.shake_offset = off
		else:
			camera.h_offset = off.x
			camera.v_offset = off.y


func _update_punch() -> void:
	var k := 0.0
	var keep: Array = []
	for p in _punches:
		var a: float = now - float(p[0])
		if a > 0.6:
			continue
		keep.append(p)
		if a < 0.0:
			continue
		var env: float = smoothstep(0.0, 0.05, a) * (1.0 - smoothstep(0.05, 0.6, a))
		k += float(p[1]) * env
	_punches = keep
	k = minf(k * shake_scale * (0.5 if reduce_flashing else 1.0), 0.06)
	_kick = k
	if not apply_shake or camera == null or not is_instance_valid(camera):
		return
	if _fov_set >= 0.0 and absf(camera.fov - _fov_set) > 1e-3:
		# someone else set the field of view while a punch was on: theirs is the new base
		_fov_base = camera.fov
		_fov_set = -1.0
	if k > 1e-4:
		if _fov_set < 0.0:
			_fov_base = camera.fov
		_fov_set = clampf(_fov_base * (1.0 - k), 1.0, 179.0)
		camera.fov = _fov_set
	elif _fov_set >= 0.0:
		camera.fov = _fov_base
		_fov_set = -1.0


# R367: the scene dim after an Eclipse core flash (fx_death.gd calls it for the peel death style only, R389). A black
# veil a hair in front of the camera fades in over a quarter of the dip and out over the rest, so the whole frame (sky,
# ships, effects) loses a little light whatever environment the scene uses. A second dip during one is ignored.
func dim_scene(t: float) -> void:
	if reduce_flashing or _dim_t0 >= 0.0:
		return
	if camera == null or not is_instance_valid(camera):
		return
	if _dim_veil == null or not is_instance_valid(_dim_veil):
		_dim_veil = MeshInstance3D.new()
		_dim_veil.name = "fx_scene_dim"
		var q := QuadMesh.new()
		var d: float = maxf(camera.near * 2.0, 0.06)
		var h: float = 2.0 * d * tan(deg_to_rad(camera.fov) * 0.5) * 1.3
		q.size = Vector2(h * 3.0, h)
		_dim_veil.mesh = q
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.render_priority = 127
		m.albedo_color = Color(0, 0, 0, 0)
		_dim_veil.material_override = m
		_dim_veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		camera.add_child(_dim_veil)
		_dim_veil.position = Vector3(0, 0, -d)
	_dim_veil.visible = true
	_dim_t0 = t


func _update_dim() -> void:
	if _dim_t0 < 0.0:
		return
	if _dim_veil == null or not is_instance_valid(_dim_veil) or reduce_flashing:
		_end_dim()
		return
	var u: float = (now - _dim_t0) / DIM_LIFE
	if u >= 1.0:
		_end_dim()
		return
	if u < 0.0:
		return
	var k: float = u / 0.25 if u < 0.25 else 1.0 - (u - 0.25) / 0.75
	(_dim_veil.material_override as StandardMaterial3D).albedo_color = Color(0, 0, 0, DIM_DEPTH * clampf(k, 0.0, 1.0))


func _end_dim() -> void:
	if _dim_veil != null and is_instance_valid(_dim_veil):
		(_dim_veil.material_override as StandardMaterial3D).albedo_color = Color(0, 0, 0, 0)
		_dim_veil.visible = false
	_dim_t0 = -1.0


# ---------------------------------------------------------------- ships (API.md 2)

func hull_damage_template(source: Material, length: float, organic: bool, power := false) -> ShaderMaterial:
	if source != null and source.has_meta("fx_hull_source"):
		source = source.get_meta("fx_hull_source")
	# The deferred nebula policy can set disable_fog after this material was first seen.
	var key := [source, maxf(length * 0.05, 0.001), organic, source is BaseMaterial3D and source.disable_fog]
	if not _damage_templates.has(key):
		_damage_templates[key] = HULL.damage_material(source, Transform3D.IDENTITY, {}, length, organic)
	if not power:
		return _damage_templates[key]
	if not _power_templates.has(key):
		_power_templates[key] = DEATH.power_material(_damage_templates[key].duplicate(), death_story)
	return _power_templates[key]


func dark_interior(source: Material) -> Material:
	if not _dark_interiors.has(source):
		var dark: Material = source.duplicate()
		if dark is BaseMaterial3D:
			dark.emission_enabled = false
		_dark_interiors[source] = dark
	return _dark_interiors[source]


# Issue 1077 (prototype): a strained wreck's insides, powered down and sooted (the dark copy, its colour a third as bright
# and fully rough), so torn decks read as burnt metal in the gap, not as flat grey panels. One copy per source material.
# R416 5.3 (issue 1741, Wounds V2 on): instead, the faction's own interior shader settled into its wreck look (sooted iron
# for the metal factions, pale bone and wet tissue for the Chorus, frosted glass for the Glasswrights, cold obsidian for
# Eclipse), the same shader the live breach used, so the inside reads the same from the live hole into the wreck.
func wreck_interior(source: Material, faction := "", L := 1.0) -> Material:
	if source == null: return source
	if faction != "" and BREACH.v2_on():
		# Fable review M2: the wreck look settles in over WRECK_SETTLE seconds from the death, not in one step, so the
		# material is kept per death moment (a tenth of a second) as well as per surface, faction and length
		var t0 := snappedf(now, 0.1)
		var key := [source, faction, snappedf(L, 0.01), t0]
		if not _wreck_interiors.has(key):
			var m := HULL.interior_material_v2(source, Transform3D.IDENTITY, {}, BREACH.wound_of(faction), L, 1.0)
			m.set_shader_parameter("fx_wreck_t0", t0)
			_wreck_interiors[key] = m
		return _wreck_interiors[key]
	if not _wreck_interiors.has(source):
		var dark: Material = (dark_interior(source) as Material).duplicate()
		if dark is BaseMaterial3D:
			var b := dark as BaseMaterial3D
			b.albedo_color = Color(b.albedo_color.r * WRECK_SOOT, b.albedo_color.g * WRECK_SOOT, b.albedo_color.b * WRECK_SOOT, b.albedo_color.a)
			b.roughness = 1.0
			b.metallic_specular = 0.2
		_wreck_interiors[source] = dark
	return _wreck_interiors[source]


func queue_death_pieces(ship: SHIP, job: Dictionary) -> void:
	if ship.dead:
		_piece_builds.push_front([ship, job])
	else:
		_piece_builds.append([ship, job])


func queue_shield_skin(ship: SHIP, key: String, box: AABB, faces: PackedVector3Array, bob: Vector3) -> void:
	# Only the triangle field runs on the worker. Normal generation, uploads
	# and the posed hit collider stay on the main thread under the cover.
	if closed:
		return
	if not _shield_jobs.has(key):
		var result := []
		var task := WorkerThreadPool.add_task(_shield_work(box, faces, result))
		_shield_jobs[key] = {"task": task, "result": result, "ships": []}
	_shield_jobs[key]["ships"].append([ship, bob])


# A static lambda: it holds no reference to this fx, so a job retired by release(false) runs the same after the fx is gone.
static func _shield_work(box: AABB, faces: PackedVector3Array, result: Array) -> Callable:
	return func() -> void: result.append(SHIP.bake_shield_geometry(box, faces))


func _finish_shield_skins() -> void:
	var deadline := Time.get_ticks_usec() + LOAD_PIECE_BUDGET
	for key in _shield_jobs.keys():
		var job: Dictionary = _shield_jobs[key]
		var task: int = job["task"]
		if not WorkerThreadPool.is_task_completed(task):
			continue
		WorkerThreadPool.wait_for_task_completion(task)
		_shield_jobs.erase(key)
		var arrays := SHIP.finish_shield_geometry(job["result"][0])
		if not arrays.is_empty():
			SHIP.save_shield_skin(key, arrays)
			for entry in job["ships"]:
				entry[0].install_shield_skin(arrays, entry[1], self, key)
				count_install("shield skin")
		if Time.get_ticks_usec() >= deadline:
			return


func _build_death_pieces() -> void:
	if _piece_builds.is_empty():
		return
	var deadline := Time.get_ticks_usec() + (LOAD_PIECE_BUDGET if defer_initial_cuts else DEATH.PREBUILD_BUDGET)
	# issue 1434 (LOAD22 cold s25: 83 pipelines in one 6.9 s draw): each piece's new materials make its pipelines, so under
	# the load cover a frame builds a few pieces (a call past its deadline builds one), not a time budget's worth
	var calls := warmup_batch * 2 if defer_initial_cuts and warmup_batch > 0 else -1
	while not _piece_builds.is_empty():
		var entry: Array = _piece_builds[0]
		if calls == 0:
			return
		if calls > 0:
			calls -= 1
			deadline = 0
		if not DEATH.build_pieces(self, entry[0], entry[1], deadline):
			if calls > 0:
				continue
			return
		_piece_builds.pop_front()
		count_install("death pieces")
		if Time.get_ticks_usec() >= deadline:
			return


# issue 1434 (LOAD15: one 3 to 6 s draw inside prepare_hulls, 83 pipelines): the step under way, read by the load bench
var prep_step := ""


# issue 1519: a left battle stays in the tree, switched off (PROCESS_MODE_DISABLED), while main.gd frees it in slices
# behind the title. Its awaits still wake there, so the load's warm-up stops at its next step instead of building on.
func _parked() -> bool:
	return closed or not is_inside_tree() or not can_process()


func prepare_battle_hulls() -> void:
	if _parked():
		return
	HULL.pause_late_watch()
	_warm_hull_adapters()
	var pending: Array[SHIP] = []
	var deadline := Time.get_ticks_usec() + LOAD_PIECE_BUDGET
	# issue 1434: the shields the load put off (fx_ship.setup with defer_shields), one ship at a time between frames
	for value in ships.values():
		var ship_s: SHIP = value
		if ship_s.shield_later:
			var t_s := Time.get_ticks_usec()
			prep_step = "shield " + str(ship_s.id)
			ship_s.build_shield_later(self)
			count_install("shield built")
			pend("prep:shield", t_s)
			if Time.get_ticks_usec() >= deadline:
				await get_tree().process_frame
				if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
				deadline = Time.get_ticks_usec() + LOAD_PIECE_BUDGET
	for value in ships.values():
		var ship: SHIP = value
		prep_step = "surfaces " + str(ship.id)
		FRAGMENTS.warm_source(ship)
		if ship.weight <= 0:
			continue
		for mesh in ship.meshes:
			var mi := mesh as MeshInstance3D
			if not is_instance_valid(mi) or mi.mesh == null:
				continue
			for si in mi.mesh.get_surface_count():
				var source := mi.get_active_material(si)
				var original := mi.mesh.surface_get_material(si)
				var inside := ship.hull.authored and HULL.interior_material(original)
				if inside:
					dark_interior(source)
				if not inside:
					hull_damage_template(source, ship.hull.L, ship.faction == "chorus", true)
				if not inside or original.resource_name.ends_with("_inside_skin"):
					ship.damage_surface(self, mi, si, source)
		pending.append(ship)
		if Time.get_ticks_usec() >= deadline:
			await get_tree().process_frame
			if _parked():
				return
			deadline = Time.get_ticks_usec() + LOAD_PIECE_BUDGET
	# Limit simultaneous cuts so the hull workers and renderer can make progress
	# together while the loading cover is up.
	var cut_limit := clampi(OS.get_processor_count() / 2, 1, LOAD_CUT_LIMIT)
	var active: Array[SHIP] = []
	var shared_cuts := {}
	prep_step = "cuts"
	while not pending.is_empty() or not active.is_empty():
		while active.size() < cut_limit and not pending.is_empty():
			var ship: SHIP = pending.pop_front()
			DEATH.precompute(self, ship, "blast", true, shared_cuts)
			active.append(ship)
		for i in range(active.size() - 1, -1, -1):
			if DEATH.finish_precompute(self, active[i]):
				active.remove_at(i)
				count_install("cut finished")
				# issue 1434 (LOAD22 cold s25: 83 pipelines and 6.9 s in one draw): under the load cover one finished cut
				# installs its pieces per frame, the others wait for the next
				if warmup_batch > 0:
					break
		_finish_shield_skins()
		await get_tree().process_frame
		if _parked():
			return
	shared_cuts.clear()
	prep_step = "shield skins and pieces"
	while not _piece_builds.is_empty() or not _shield_jobs.is_empty():
		_finish_shield_skins()
		await get_tree().process_frame
		if _parked():
			return
	defer_initial_cuts = false
	prep_step = ""


# A cut belongs to this session until joined, even after it loses its ship or its result is discarded.
var _death_cut_tasks := {}
# Issue 1289: each fitted shield pose this battle built (fx_ship._posed_skin), shared by later ships of the same hull.
var shield_poses := {}
var shield_keys := {}   # issue 1289: each fitted shield skin's cache key by mesh set (fx_ship._shield_skin)


func submit_death_cut(work: Callable) -> int:
	var tid := WorkerThreadPool.add_task(work)
	_death_cut_tasks[tid] = true
	return tid


func join_death_cut(tid: int) -> void:
	if _death_cut_tasks.has(tid) and WorkerThreadPool.wait_for_task_completion(tid) == OK:
		_death_cut_tasks.erase(tid)


func finish_death_cut(tid: int) -> bool:
	# A ship that shares the cut may already have joined it.
	if not _death_cut_tasks.has(tid):
		return true
	if not WorkerThreadPool.is_task_completed(tid):
		return false
	join_death_cut(tid)
	return true


func collect_death_cut(tid: int) -> void:
	if not _death_cut_tasks.has(tid):
		return
	if WorkerThreadPool.is_task_completed(tid):
		join_death_cut(tid)
	else:
		later(now + 0.25, collect_death_cut.bind(tid))


func discard_ship_cut(s: SHIP) -> void:
	if s.has_meta("cut_task"):
		var tid := int(s.get_meta("cut_task"))
		s.remove_meta("cut_task")
		collect_death_cut(tid)
	s.remove_meta("cut_work")
	s.remove_meta("cut_job")
	s.remove_meta("cut_prev")


func add_ship(id: String, root: Node3D, info := {}) -> void:
	if ships.has(id):
		remove_ship(id)
	var s = SHIP.new()
	s.setup(self, id, root, info)
	if root.has_method("set_thrust_spark_sink"):
		root.set_thrust_spark_sink(_thrust_spark)
	s.set_meta("cut_class", String(info.get("cls", "")))
	# Issue 462 (deaths_and_hits.md): a cruiser parts into two halves, a capital into three pieces.
	s.set_meta("death_cut_count", 2 if s.death_tier == "capital" else 1)
	ships[id] = s
	var t_col := Time.get_ticks_usec()
	DEATH.add_collider(self, s)
	if s.hull_pivot != null and s.has_meta("collider"):
		(s.get_meta("collider") as Node3D).reparent(s.hull_pivot)
	pend("add:collider", t_col)
	if defer_initial_cuts:
		return
	# Issue 2087: a scripted look bench row knows which ship will die. Battles still prepare every arrival.
	if bool(info.get("cut_on_arrival", true)):
		# Issue 1232: stagger only the cuts still waiting to start, so a late arrival is ready sooner.
		var n := _arrival_cuts
		_arrival_cuts += 1
		later(now + 0.1 + 0.25 * n, func l_cut_first() -> void:
			_arrival_cuts = maxi(_arrival_cuts - 1, 0)
			if ships.get(id) == s and not s.dead and not s.gone:
				var t_c := Time.get_ticks_usec()
				DEATH.precompute(self, s)
				pend("cut_first", t_c))
	if warmed and DisplayServer.get_name() != "headless":
		warm_arrival.call_deferred(s)


# Issue 1232: a ship that arrives after the battle's warm-up (a reinforcement) draws its hull once with the death
# overlays and its cuttable surface, so its first death never builds them in the kill frame. A hull already warmed this
# battle costs nothing. Drawn a thousandth of its size in front of the camera for two frames: never seen.
var warmed := false
var _warm_seen := {}
var _arrival_cuts := 0


func warm_arrival(s: SHIP) -> void:
	if closed or s == null or s.gone or s.dead:
		return
	var fresh := false
	for m in s.meshes:
		if not is_instance_valid(m): continue   # a ship part freed under a live ship (1204 bot runs)
		var mi := m as MeshInstance3D
		if mi != null and mi.mesh != null and not _warm_seen.has(mi.mesh.get_instance_id()):
			fresh = true
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if not fresh or cam == null:
		return
	var tmp := Node3D.new()
	tmp.name = "fx_warm_arrival"
	add_child(tmp)
	tmp.global_transform = Transform3D(cam.global_basis, cam.global_transform * Vector3(0, 0, -30.0 * unit))
	tmp.scale = Vector3.ONE * 0.001
	var paused := HULL.late_watch
	HULL.pause_late_watch()
	var t0 := Time.get_ticks_usec()
	_warm_hull_meshes(tmp, s, _warm_seen.duplicate(), 0)
	pend("warm_arrival", t0)
	for i in 2:
		await RenderingServer.frame_post_draw
		if closed or not is_inside_tree() or not is_instance_valid(tmp):
			break
	if is_instance_valid(tmp):
		tmp.queue_free()
	if paused and not closed and is_inside_tree():
		HULL.start_late_watch()


# Issue 370: what the attach point service answered for each ship this battle (per point type: authored "hp", surface
# "ray", "centre" for a core worked out from the triangles, "skip" for an effect not drawn). With say, one line per ship.
func attach_report(say := false, only := "") -> Dictionary:
	var out := {}
	for id in ships:
		if only != "" and id != only:
			continue
		var h = (ships[id] as SHIP).hull
		if h == null:
			continue
		out[id] = {"code": h.code, "counts": h.attach_counts.duplicate(true), "skipped": h.skipped()}
		if say and not h.attach_counts.is_empty():
			var parts: Array = []
			for k in h.attach_counts:
				var c: Dictionary = h.attach_counts[k]
				parts.append("%s hp %d ray %d centre %d skip %d" % [k, c.get("hp", 0), c.get("ray", 0), c.get("centre", 0), c.get("skip", 0)])
			print("[attach] battle %s %s: skipped %d; %s" % [id, h.code, h.skipped(), "; ".join(parts)])
	return out


func remove_ship(id: String) -> void:
	if not ships.has(id):
		return
	attach_report(true, id)
	_clear_thrust_spark_sink(ships[id].root)
	(ships[id] as SHIP).teardown(self)
	ships.erase(id)


func _clear_thrust_spark_sink(ship_root) -> void:
	if is_instance_valid(ship_root) and ship_root.has_method("set_thrust_spark_sink"):
		ship_root.set_thrust_spark_sink(Callable())


func set_engine(id: String, level: float) -> void:
	if ships.has(id):
		(ships[id] as SHIP).engine_level = level


# Issue 1581 (Burn and fire): before a volley that follows a move, the battle asks the guns that volley will use to start
# turning while the hull still brakes, so the first shot leaves without waiting for the swing. The mounts are the
# volley's own pick (fx_hull.gun_turrets: slot, weapon id, shot count) and the aim point is the volley's (the target
# hull's centre), from the attacker's settled pose xf_end (the ship root's world transform when it stops). commit false
# only measures: the seconds the slowest of those turrets needs to bear (the battle starts the swing that early).
# Fixed guns have nothing to do (0). The volley itself still aims, waits for any turret not yet there, and releases.
func pre_aim(id: String, target_id: String, xf_end: Transform3D, slot: int, weapon_id: String, n: int, commit := true) -> float:
	if not ships.has(id) or not ships.has(target_id):
		return 0.0
	var sh = ships[id]
	var tg = ships[target_id]
	if sh.dead or sh.hull == null or (sh.hull.turrets as Array).is_empty():
		return 0.0
	var tl: Vector3 = xf_end.affine_inverse() * tg.to_world(tg.hull.c)
	var need := 0.0
	for k in sh.hull.gun_turrets(slot, weapon_id, tl, n):
		need = maxf(need, sh.hull.turret_need(k, tl, now))
		if commit:
			sh.hull.turret_aim(k, tl, now)
	return need


func sync_ship(id: String, u: Dictionary) -> void:
	if ships.has(id):
		(ships[id] as SHIP).sync(self, u)


func hull_point(id: String, section: String, toward: Vector3) -> Dictionary:
	if not ships.has(id):
		return {}
	var s: SHIP = ships[id]
	var xf = s.root.global_transform
	var h = s.hull.hit_point(xf.affine_inverse() * toward, HULL.SEC_NAMES.get(section, -1))
	return {"p": xf * (h["p"] as Vector3), "n": (xf.basis * (h["n"] as Vector3)).normalized()}


func faction_info(f: String) -> Dictionary:
	return FLOOK.of(f)


func ship(id: String) -> SHIP:
	return ships.get(id, null)


# Issue 281 stray-puff guard (fx/test/fx_smoke.gd and vent_look_probe.gd): a weapon, vent or thruster gas effect is
# born on its source ship, so a spawn farther than a small share of that ship's hull length from its real plating is a
# stray puff and fails the test. The distance is measured to the source hull's nearest surface sample (hull.sp, moved to
# world space) at spawn time, so a source ship that later dies or leaves does not turn a valid earlier spawn stray.
# `wide` is the wider limit for real muzzle and impact gas points, which sit off the barrel or along the hit normal past
# the plating; the thruster gas (_rcs) uses the tight limit.
# `frame` (issue 462): for a picture born on a drifting wreck piece, the transform from the ship's own space to that
# piece's place in the world now; the hull samples are moved with the piece.
func record_spawn(src: SHIP, p: Vector3, wide := false, frame = null) -> void:
	if not check_radius or src == null:
		return
	var h: HULL = src.hull
	var limit: float = (0.30 if wide else 0.08) * float(h.L)
	var nearest := INF
	for i in h.sp.size():
		var wp: Vector3 = (frame as Transform3D) * h.sp[i] if frame is Transform3D else src.to_world(h.sp[i])
		var d: float = p.distance_to(wp)
		if d < nearest:
			nearest = d
	effect_spawns.append([p, nearest, limit])


func stray_spawns() -> Array:
	var out: Array = []
	for e in effect_spawns:
		if float(e[1]) > float(e[2]):
			out.append(e[0])
	return out


# ---------------------------------------------------------------- weapons, shields, deaths (API.md 3 to 6)

func volley(attacker_id: String, kind: String, target_id: String, opts := {}) -> Dictionary:
	stats["volleys"] += 1
	var t0 := Time.get_ticks_usec()
	var r: Dictionary = WEAP.volley(self, attacker_id, kind, target_id, opts)
	pend("volley", t0)
	return r


# Fire at a point in space (gallery, misses, station guns with no attacker ship): from and to in world space.
func pd_flak(ship_id: String, toward: Vector3) -> void:
	var defender = ship(ship_id)
	if defender == null or defender.dead or not is_instance_valid(defender.root):
		return
	var muzzle := WEAP._pd_origin(defender, toward)
	if muzzle.is_finite():
		WEAP.pd_flak(self, muzzle, toward, now, defender.faction)


func volley_at(from: Vector3, kind: String, to: Vector3, opts := {}) -> Dictionary:
	return WEAP.volley_points(self, from, kind, to, opts)


# hit_lp (issue 1239): the breaking hit's point on the shield, in the shield's frame (a volley's "hit_pts"); INF aims
# at the middle of the quadrant.
func shield_break(id: String, quad: int, hit_lp := Vector3.INF) -> void:
	if ships.has(id):
		(ships[id] as SHIP).shield_break(self, quad, hit_lp)


func death(id: String, cause := "blast") -> float:
	var s: SHIP = ships.get(id)
	if s == null or s.dead or s.gone:
		return 0.0
	# Death must sample the real hull, never the transient rift stretch.
	s.clear_rift_pose()
	s.end_brownout()
	stats["deaths"] += 1
	var t0 := Time.get_ticks_usec()
	var r: float = DEATH.death(self, s, cause)
	pend("death", t0)
	_core_at.erase(id)
	# A burnt-out hulk or a small hull has no staged core; a big Chorus rupture has one (issue 1238: its kill beat comes
	# just after the skin bursts, with no fireball).
	if s.death_big and s.has_meta("death_timeline"):
		var tl = s.get_meta("death_timeline")
		_core_at[id] = float(s.get_meta("death_start")) + float(tl.cut) + float(tl.core_delay)
		s.death_core_pending = true
		s.slow_core = kill_slowmo
	return r


func clear_wreck(id: String) -> void:
	DEATH.clear_wreck(self, id)
	_core_at.erase(id)


# issue 1236: the rules made this ship's hex a wreck that blocks; its death pieces stay inside that hex
func anchor_wreck(id: String, centre: Vector3, radius: float) -> void:
	DEATH.anchor_wreck(self, id, centre, radius)


func wreck_pieces(id: String) -> int:
	return DEATH.wreck_pieces(self, id)


# A late cut keeps the live hull visible until the split, hulk copy or no-pieces pop has run.
func wreck_settled(id: String) -> bool:
	var s: SHIP = ships.get(id)
	return s == null or s.has_meta("death_hidden") or not is_instance_valid(s.root)


func _special_ship(id: String) -> SHIP:
	var s: SHIP = ships.get(id)
	return s if s != null and not s.dead and not s.gone and is_instance_valid(s.root) else null


func nova(id: String, target: Vector3, pace := 1.0) -> float:
	var s := _special_ship(id)
	return SPECIAL.nova(self, s, target, maxf(pace, 0.01), nova_look) if s != null else -1.0


func rift_in(id: String, pace := 1.0, delay := 0.0, risen := false) -> float:
	var s := _special_ship(id)
	return SPECIAL.arrive(self, s, maxf(pace, 0.01), delay, risen) if s != null else -1.0


func fold(id: String, pace := 1.0, transfer := Callable()) -> float:
	var s := _special_ship(id)
	return SPECIAL.fold(self, s, maxf(pace, 0.01), transfer) if s != null else -1.0


func jump_out(id: String, pace := 1.0) -> float:
	var s := _special_ship(id)
	return SPECIAL.jump(self, s, maxf(pace, 0.01)) if s != null else -1.0


func ability(id: String, _ab := "") -> void:
	var s := _special_ship(id)
	if s != null:
		SPECIAL.pulse(self, s, false)


# A weapon mark on a ship's hull without a volley (API.md 14): look as in volley's looks plus "board" (a blown boarding
# hatch) and "ram"; at a hull point (world) or, with none, a visible point of the struck section (sec 0 eng, 1 mid, 2 prow).
func hull_mark(id: String, look: String, w := 2, world_p := Vector3.INF, dir := Vector3.ZERO, sec := 1) -> void:
	if not ships.has(id):
		return
	var s: SHIP = ships[id]
	var lp: Vector3
	var ln: Vector3
	if world_p == Vector3.INF:
		var h: Dictionary = s.hull.random_sample(sec, 1.5) if look != "ram" else {"p": s.hull.bow, "n": Vector3(1, 0, 0)}
		lp = h["p"]
		ln = h["n"]
	else:
		var inv: Transform3D = s.xf().affine_inverse()
		var hp: Dictionary = s.hull.ray(inv * world_p + (inv.basis * dir).normalized() * -s.hull.L, (inv.basis * dir).normalized()) if dir != Vector3.ZERO else {}
		lp = hp["p"] if not hp.is_empty() else inv * world_p
		ln = hp["n"] if not hp.is_empty() else (lp - s.hull.c).normalized()
	var ld: Vector3 = (s.xf().basis.inverse() * dir).normalized() if dir != Vector3.ZERO else -ln
	s.add_mark(self, look, w, lp, ln, ld)


# The rules' "board" event. Keep the wider hatch and the original 1.6 s playback hold (R401).
const BOARD := {"hatch": 4.0, "burst": 2.2, "spark_px": 3.0, "hold": 1600.0}
var board_lines_s := 0.0


# how long the battle holds on a boarding before the next event (ms at speed 1; issue 1547)
func board_hold_ms() -> float:
	return float(BOARD["hold"])


# pace: the battle's wait() scale, used for the lines' hold on the effect clock (Artoo, PR 1549)
func board(attacker_id: String, target_id: String, _result := "", pace := 1.0) -> float:
	if not ships.has(target_id):
		return 0.0
	var s: SHIP = ships[target_id]
	var bl: Dictionary = BOARD
	# issue 370: the party leaves the attacker from its boarding hatch (hp_board on the side facing the target, else the
	# side plating facing it through its core) and breaks in through the target's side plating facing that hatch, on
	# the line through the target's core. Either missing: nothing to show (logged and counted by the hull).
	var toward: Vector3
	var a: SHIP = ships.get(attacker_id)
	var launch := Vector3.ZERO
	if a != null:
		var o: Dictionary = a.hull.board_origin(a.xf().affine_inverse() * s.to_world(s.hull.core))
		if o.is_empty():
			return 0.0
		launch = o["p"]
		toward = a.to_world(launch)
	else:
		toward = s.to_world(s.hull.core + Vector3(0, 0, s.hull.W * 3.0))
	var inv: Transform3D = s.xf().affine_inverse()
	var tl: Vector3 = inv * toward
	var side := Vector3(0, 0, signf(tl.z - s.hull.core.z) if absf(tl.z - s.hull.core.z) > 1e-3 else 1.0)
	# issue 1547: a party coming from dead ahead or astern (no clear side) breaks in on the side the camera sees; the
	# first cloud shots put it on the far side, hidden by the hull
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if absf(tl.z - s.hull.core.z) < s.hull.W * 0.75 and cam != null:
		var cl: Vector3 = inv * cam.global_position
		side = Vector3(0, 0, 1.0 if cl.z >= s.hull.core.z else -1.0)
	var h: Dictionary = s.hull.surface(s.hull.core + Vector3(s.hull.L * 0.05, 0, 0), side)
	if h.is_empty():
		s.hull._took("board", "skip")
		return 0.0
	var lp: Vector3 = h["p"]
	var ln: Vector3 = h["n"]
	s.add_mark(self, "board", 2, lp, ln, -ln, float(bl["hatch"]))
	var wp: Vector3 = s.to_world(lp)
	var wn: Vector3 = s.dir_world(ln)
	var k: float = s.scale_k()
	var hold: float = float(bl["hold"]) / 1000.0 * pace
	var T: float = now + hold * 0.67 if a != null else now + 0.1
	var recipe := BOARDING.skin(a if a != null else s)
	BOARDING.breach(self, s, h, T, recipe)
	var bk: float = float(bl["burst"])
	var metal_sparks: bool = recipe.style == 0 and s.faction != "chorus"
	for j in (int(18 * sqrt(bk)) if metal_sparks else 0):
		spark(wp, T + 0.3 + rng.randf() * 2.6, 0.3 + rng.randf() * 0.3, s.faction, 4.0, 0.05 * bk, 0.08 * k * bk,
			(wn + rdir() * 0.6).normalized() * (5 + rng.randf() * 8) * k * bk, 2.0, 0.0, float(bl["spark_px"]))
	shake(T, 0.06, wp)
	board_lines_s = 0.0
	if a != null and hold > 0.0:
		var ends: Array[Vector3] = []
		var nl: int = recipe.lines
		for i in nl:
			var dx: float = (float(i) - float(nl - 1) * 0.5) * s.hull.L * 0.12
			var hi: Dictionary = s.hull.surface(s.hull.core + Vector3(s.hull.L * 0.05 + dx, 0, 0), side) if dx != 0.0 else h
			ends.append(hi["p"] if not hi.is_empty() else lp)
		BOARDING.crossing(self, a, launch, s, ends, hold, recipe)
		var launch_col: Color = recipe.core
		sprx(18.0, toward, now + hold * 0.12, minf(0.3, hold * 0.2), launch_col, 2.0, 0.3 * k, 0.8 * k, 18)
		board_lines_s = hold
	return maxf(3.2, hold)


func command(id: String, _cmd := "") -> void:
	var s := _special_ship(id)
	if s != null:
		SPECIAL.pulse(self, s, true)


func launch(carrier_id: String, squadron_id := "") -> void:
	WEAP.launch(self, carrier_id, squadron_id)


func tick(id: String, kind := "fire") -> void:
	if ships.has(id):
		(ships[id] as SHIP).tick_flare(self, kind)


func particles_emitted() -> int:
	var n = 0
	for k in pools:
		n += pools[k].emitted
	return n


# ---------------------------------------------------------------- shader warm-up (API.md 1)

func _warm_hull_adapters() -> void:
	# The temporary PBR adapter is queried for uniforms at death too. Keep its
	# shader alive so that query never recompiles it for each new ship.
	_shaders["hull_exterior"] = HULL.shared_shader(HULL.EXTERIOR)
	_shaders["hull_exterior_alpha"] = HULL.shared_shader(HULL.exterior_alpha_code(), "exterior_alpha")


func _warm_fragment_finish(at: Vector3, t: float, color: Color) -> void:
	var pool: FRAGMENTS.Pool = pools["plate"]
	var finish := {}
	for ship: SHIP in ships.values():
		for row in ship.hull.bvh_ranges:
			var paint: BaseMaterial3D = row["paint"]
			if paint != null and paint.albedo_texture != null:
				var maps := FRAGMENTS.finish_maps(paint)
				finish = {"maps": maps, "uv": Vector2(0.5, 0.5), "finish": Vector4(1, 0, 0, float(maps[1] != null)),
					"normal_scale": paint.normal_scale if paint.normal_enabled else 0.0}
				break
		if not finish.is_empty():
			break
	pool.bind_finish(finish, t, t + 0.5)
	hit_fragment(at, t, 0.5, Vector3.ZERO, 0.2, 1.0, 4.0, 0.1, color, FRAGMENTS.PLATE, false, finish)
	pool.flush(t)


# Draw the effect materials under the loading cover so their pipelines are ready for battle.
func warmup(cam: Camera3D, frames := 4) -> void:
	if _parked() or not is_instance_valid(cam) or not cam.is_inside_tree():
		return
	# Issue 376: rebuilds under the load cover are expected. Start the late watch
	# once the warm objects have drawn.
	HULL.pause_late_watch()
	# ShipView sets its paint just after adding the meshes. Let the deferred mesh
	# watcher apply the nebula's fog policy before deriving shaders from that paint.
	await get_tree().process_frame
	if _parked() or not is_instance_valid(cam) or not cam.is_inside_tree():
		return
	_warm_hull_adapters()
	if warmup_batch > 0:   # issue 1434: the sliced load spreads the warm-up's setup
		await get_tree().process_frame
		if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	var at = cam.global_transform * Vector3(0, 0, -30.0 * unit)
	var T = now
	var c = Color(1, 0.6, 0.3)
	for k in [0, 1, 2, 3, 4, 5, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]:
		spr(at + rdir(), T, 0.5, c, 0.02, 0.5, 0.5, k)
	for k in [0, 3, 4, 5, 6, WEAP.BOLT_SHELL, WEAP.BOLT_ENERGY, WEAP.BOLT_CRYSTAL, WEAP.BOLT_SCRAP]:
		flight_streak(at, T, 0.5, c, 0.02, 1.0, 0.1, k, Vector3(1, 0, 0))
	spark(at, T, 0.5, "voidsworn", 0.02, 0.06, 0.1, Vector3.RIGHT)
	spark(at, T, 0.5, "ithar", 0.02, 0.06, 0.1, Vector3.RIGHT)
	for k in [0, 1, 2, 3, 4, SH.RING_HARMONIC]:
		ring(at, Vector3.UP, T, 0.5, c, 0.02, 0.5, 1.0, k)
	for k in [0, 1, 2, 3, 5, 6, 7, 8, 9, 10, SH.RIB_NULL_LANCE]:
		rib(at, Vector3(1, 0, 0), 2.0, T, 0.5, c, 0.02, 0.2, 0.2, k)
	shd(at, T, 0.5, Vector3.ZERO, 0.2, 1.0)
	_warm_fragment_finish(at, T, c)
	dst(at, T, 0.5, 0.5, 1.0, 0, 0.1)
	dst(at, T, 0.5, 0.5, 1.0, 1, 0.1)
	if warmup_batch > 0:   # issue 1434: the sliced load spreads the warm-up's setup
		await get_tree().process_frame
		if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	var tmp = Node3D.new()
	tmp.name = "fx_warmup"
	tmp.position = global_transform.affine_inverse() * at
	if warmup_batch > 0:
		# issue 1434 (LOAD20, cloud trace: 64 warm meshes entering the scene in one frame compiled 173 pipelines in one
		# draw, hidden or not): the warm root stays out of the tree while it fills, and its meshes enter a few a frame
		# below. Until they are all in, _exit_tree frees whatever is still out of the tree (_free_warm_parked).
		_warm_off_tree = tmp
	else:
		add_child(tmp)
	var box = BoxMesh.new()
	box.size = Vector3.ONE * 2.0
	var mats: Array = [mat(SH.SHIELD, 2), mat(SH.SHARD, 0), mat(SH.SPRITE, 1), mat(SH.STREAK, 1),
		mat(SH.RIBBON, 1), mat(SH.ECLIPSE_ARC, 0), pools["nlance"].mi.material_override,
		mat(SH.NULL_SLUG, 1), mat(SH.TRAIL, 1), mat(DEATH.SLAG, 0)]
	mats.append(mat(SPECIAL.GHOST, -2))
	mats.append(DAMAGE_PLUME.material(self))
	# Warm the PBR fallbacks for late arrivals and generated pieces as well as the
	# actual hull formats below. Glasswright sails blend, and nebula hulls ignore fog.
	for fog_disabled in [false, true]:
		for alpha in [false, true]:
			var source := StandardMaterial3D.new()
			source.disable_fog = fog_disabled
			if alpha:
				source.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				source.albedo_color = Color(1, 1, 1, 0.55)
			var damage := HULL.damage_material(source, Transform3D.IDENTITY, {}, 1.0)
			mats.append(damage)
			mats.append(DEATH.power_material(damage.duplicate(), death_story))
	if warmup_batch > 0:   # issue 1434: the sliced load spreads the warm-up's setup
		await get_tree().process_frame
		if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	if not compat:
		mats.append(mat(SH.SPRITE, 1, "#define SOFT\n"))
	for band in ["small", "cruiser", "capital"]:
		for kind in ["flash", "vent", "cool"]:
			var baked := DEATH.flipbook_material(self, kind, band)
			baked.set_shader_parameter("born", now)
			baked.set_shader_parameter("intensity", 0.01)
			mats.append(baked)
		if warmup_batch > 0:
			await get_tree().process_frame
			if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	mats.append(mat(SH.TEAR, 1))   # issue 462: the dying hull's tear overlay
	# issue 220: the torpedo and rocket bodies (drive glow, star torpedo body, exhaust plume) and the weapon bursts' atlas
	# shader: their first launch or hit compiled them mid-fight (a 53 ms frame with 3 surface pipelines at the gate scene)
	mats.append_array([mat(WEAP.DRIVE, 1), mat(WEAP.STAR_BODY), mat(SH.ORDNANCE_CORONA, 1, "", "star corona")])
	var wburst: ShaderMaterial = DEATH.flipbook_material(self, "vent", "small")
	wburst.shader = WEAP._weapon_shader(self)
	wburst.set_shader_parameter("born", now)
	wburst.set_shader_parameter("intensity", 0.01)
	mats.append(wburst)
	# issue 281: the baked muzzle and impact gas atlases, warmed so the first macro muzzle or hull hit never compiles
	# its pipeline mid-fight.
	for wkind in ["muzzle", "impact"]:
		var wgas: ShaderMaterial = WEAP._weapon_gas_material(self, wkind)
		wgas.set_shader_parameter("born", now)
		wgas.set_shader_parameter("intensity", 0.01)
		mats.append(wgas)
		if warmup_batch > 0:
			await get_tree().process_frame
			if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	for rel in ["weapons/impact/impact_", "weapons/impact/flash_", "weapons/macro/impact_", "weapons/macro/flash_", "death/small/flash_", "death/cruiser/flash_", "death/capital/flash_"]:
		if rel.begins_with("weapons/"):
			var hit := WEAP.hull_impact_material(self, rel)
			hit.set_shader_parameter("born", now)
			hit.set_shader_parameter("intensity", 0.01)
			mats.append(hit)
		for variant in 3:
			var production := DEATH.route_material(self, SH.DEATH_FLIPBOOK, rel, true, variant)
			production.set_shader_parameter("born", now)
			production.set_shader_parameter("intensity", 0.01)
			mats.append(production)
		if warmup_batch > 0:
			await get_tree().process_frame
			if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	DEATH.tear_particles(self, at, Vector3.UP, 0.1, Vector3.ZERO)
	if warmup_batch > 0:   # issue 1434: the sliced load spreads the warm-up's setup
		await get_tree().process_frame
		if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	for i in mats.size():
		# Pin generated hull shaders until release, even after the temporary warmup meshes go away.
		_shaders["warm:" + str(mats[i].shader.code.hash())] = mats[i].shader
		var mi = MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = mats[i]
		mi.position = Vector3((i % 4 - 1.5) * 2.5, (i / 4 - 1.0) * 2.5, 0) * unit
		tmp.add_child(mi)
	# Use the same indexed strip and material setup as the live thrusters, not the box vertex format.
	var jet := SHIP_VIEW.build_rcs_jet("voidsworn", Vector3.RIGHT, 1.0, 0.2, 0.5, 0.01, 0.5)
	tmp.add_child(jet)
	# Warm the boarding and tick current shader in its indexed tube format, not the primitive box format.
	var conduit := EVENT_PATHS.TUBE.make(self, PackedVector3Array([Vector3.LEFT, Vector3.RIGHT]),
		PackedFloat32Array([0.1, 0.1]), Color.WHITE, Color.WHITE, 0, 0.0)
	tmp.add_child(conduit)
	# the torpedo and rocket casings, in their own vertex format (position, normal, colour) and lit material
	for rocket in [false, true]:
		var cm := MeshInstance3D.new()
		cm.mesh = WEAP._casing(self, rocket)
		cm.position = Vector3(3.5 if rocket else -3.5, 3.0, 0) * unit
		tmp.add_child(cm)
	# a breach interior (its own vertex format: position, normal, colour)
	var harr = []
	harr.resize(Mesh.ARRAY_MAX)
	harr[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 0, 0)])
	harr[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	harr[Mesh.ARRAY_COLOR] = PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE])
	# A cap has position/normal/colour only, unlike the textured hull. Warm its
	# opaque pass in that exact format before the first death.
	var cap_arr: Array = harr.duplicate()
	var cap_mesh := ArrayMesh.new()
	cap_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cap_arr)
	var cap_mi := MeshInstance3D.new()
	cap_mi.mesh = cap_mesh
	cap_mi.material_override = mat(DEATH.SLAG, 0)
	tmp.add_child(cap_mi)
	var c4 = PackedFloat32Array([0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1])
	for ci in [Mesh.ARRAY_CUSTOM0, Mesh.ARRAY_CUSTOM1, Mesh.ARRAY_CUSTOM2, Mesh.ARRAY_CUSTOM3]:
		harr[ci] = c4
	var hm = ArrayMesh.new()
	hm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, harr, [], {}, BREACH.custom_flags())
	for sd in [Vector3.BACK, Vector3.FORWARD, Vector3.UP]:
		var hmi = MeshInstance3D.new()
		hmi.mesh = hm
		hmi.material_override = mat(SH.HOLE, 0) if sd != Vector3.UP else mat(SH.MARK, 1)
		hmi.position = sd * unit * 0.5
		hmi.rotation.y = 0.0 if sd == Vector3.BACK else PI
		hmi.scale = Vector3.ONE * unit * 2.0
		tmp.add_child(hmi)
	# every hull as it is drawn, with the death tear overlay on top: the overlay pipelines are per vertex format, so warming
	# it on a box (above) does not cover the hulls, and the first death would compile them. Issue 1232 (Neon's death audit
	# F8.1): this drew three overlays no game path uses (CHUNK, CRACKS, HULLIN, now deleted with VOL) and not the tear the
	# tell puts on every dying hull.
	var seen := {}
	var hk := 0
	for sid in ships.keys():
		if not ships.has(sid):
			continue
		hk = _warm_hull_meshes(tmp, ships[sid], seen, hk)
		if warmup_batch > 0:
			await get_tree().process_frame
			if _parked(): return   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
	if dstate.has("debris_meshes"):
		var db = MeshInstance3D.new()
		db.mesh = dstate["debris_meshes"][0][0]
		db.material_override = dstate["debris_mat"]
		tmp.add_child(db)
	# F3 perf (first-use stalls): an omni light over all of the above, so every material here also draws once lit by a
	# point light (on the Compatibility renderer each lit material compiles its omni-light pass the first time a light
	# touches it: the first big death light did that mid-fight); and the physics a death first uses, a wreck piece's
	# convex body and pooled debris bodies (Jolt's first bodies and shapes), far below the board and out of view
	var wl := OmniLight3D.new()
	wl.shadow_enabled = false
	wl.light_energy = 2.0
	wl.omni_range = 20.0 * unit
	tmp.add_child(wl)
	var deep: Vector3 = at + Vector3(0, -2000.0 * unit, 0)
	if bool(dstate.get("physics_on", false)) and phys_root != null:
		var rb := RigidBody3D.new()
		rb.name = "fx_warmup_body"
		rb.gravity_scale = 0.0
		var cs := CollisionShape3D.new()
		cs.shape = DEATH.safe_convex(PackedVector3Array([Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1),
			Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(-1, 1, 1), Vector3(0.8, 1.1, 0.9)]))
		rb.add_child(cs)
		wake_physics()
		phys_root.add_child(rb)
		rb.global_position = deep
		rb.linear_velocity = Vector3(0.1, 0, 0)
		DEATH.spawn_debris(self, deep + Vector3(10, 0, 0), Vector3.ZERO, 3, 0.2 * unit)
		get_tree().create_timer(0.5).timeout.connect(_settle_warm_debris.bind(weakref(rb), deep.y * 0.5))
	if warmup_batch <= 0:
		WEAP.warm_craft_trail(self, tmp)
		dstate["warm_munitions"] = WEAP.warm_munitions(self, tmp)   # issue 1528: the first salvo's body, materials and trail
	# Issue 1434 (PC run 1: cover frames of 2 to 9 s): every warm mesh drew its first frame together, so all their
	# pipelines compiled in one frame. They now appear WARM_BATCH at a time, a frame apart, and all of them stay up for
	# the closing frames as before (outside the load cover, warmup_batch 0 keeps the old one-frame reveal).
	if warmup_batch > 0:
		# issue 1434 (LOAD20 and a cloud trace: 64 warm meshes added in one frame compiled 173 pipelines in one draw,
		# hidden or not): the renderer makes a mesh's pipelines when the mesh enters the scene, not when it shows. So
		# the warm root (out of the tree until now) goes in empty, and its meshes follow warmup_batch at a time, a frame apart;
		# all of them stay up for the closing frames as before. Only the outermost meshes move (a nested one travels
		# with its parent); Artoo on PR 1445: nested ones under a plain Node3D (issue 1528's munition bodies) are
		# outermost meshes too. Outside the load cover, warmup_batch 0 keeps the old one-frame reveal.
		var parked: Array = _warm_parked   # [mesh, its parent]
		for wc in tmp.find_children("*", "GeometryInstance3D", true, false):
			var up: Node = wc.get_parent()
			var nested := false
			while up != null and up != tmp:
				if up is GeometryInstance3D:
					nested = true
					break
				up = up.get_parent()
			if not nested:
				parked.append([wc, wc.get_parent()])
		for pk in parked:
			(pk[1] as Node).remove_child(pk[0])
		add_child(tmp)
		_warm_off_tree = null
		# these two read the warm root's place in the world, so they come once it is in the tree (a few meshes)
		WEAP.warm_craft_trail(self, tmp)
		dstate["warm_munitions"] = WEAP.warm_munitions(self, tmp)   # issue 1528: the first salvo's body, materials and trail
		for i in parked.size():
			if is_instance_valid(parked[i][0]) and is_instance_valid(parked[i][1]):
				(parked[i][1] as Node).add_child(parked[i][0])
			if (i + 1) % warmup_batch == 0:
				await RenderingServer.frame_post_draw
				if _parked():   # issues 1434 and 1519: a left battle stops here (parked in the tree, or out of it)
					_free_warm_parked()
					if is_instance_valid(tmp):
						tmp.queue_free()
					return
		_free_warm_parked()   # a parent gone meanwhile left its mesh out of the tree: free it here
	for i in frames:
		await RenderingServer.frame_post_draw
		if _parked():
			if is_instance_valid(tmp):
				tmp.queue_free()
			return
	if not is_instance_valid(tmp):
		HULL.start_late_watch()
		return
	warmed = true
	tmp.queue_free()
	HULL.start_late_watch()


func _settle_warm_debris(rb_ref: WeakRef, below: float) -> void:
	free_effect(rb_ref)
	if closed or not is_inside_tree():
		return
	# Issue 1279: stop the warm debris below the board so Jolt can sleep until a death reuses it.
	for body in dstate.get("debris", []):
		if not is_instance_valid(body) or not body.is_inside_tree() or body.global_position.y >= below:
			continue
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.sleeping = true


# Every hull as it is drawn, with the death overlays on top, and its cuttable PBR surface (from warmup, shared with the
# arrival warm-up, issue 1232). Returns the next free slot in the warm grid.
func _warm_hull_meshes(tmp: Node3D, sh: SHIP, seen: Dictionary, hk: int) -> int:
	for m in sh.meshes:
		if not is_instance_valid(m): continue   # a ship part freed under a live ship (1204 bot runs)
		var smi := m as MeshInstance3D
		if smi == null or smi.mesh == null or seen.has(smi.mesh.get_instance_id()):
			continue
		seen[smi.mesh.get_instance_id()] = true
		_warm_seen[smi.mesh.get_instance_id()] = true
		var overlays := [dstate["tear_mat"] if dstate.has("tear_mat") else mat(SH.TEAR, 1)]
		if death_story and dstate.has("tear_strain_mat"): overlays.append(dstate["tear_strain_mat"])
		# R398: the acid death's glow, compiled before the first acid kill. The overlay's pipeline depends only on the
		# mesh's vertex format, so one draw per format a battle has (Artoo on PR 1583: not one per hull mesh)
		var fmt_key := "melt_warm_%d" % smi.mesh.surface_get_format(0) if smi.mesh.get_surface_count() > 0 else "melt_warm_none"
		if not _warm_seen.has(fmt_key):
			_warm_seen[fmt_key] = true
			overlays.append(mat(SH.MELT_GLOW, 1))
			stats["melt_warm_draws"] = int(stats.get("melt_warm_draws", 0)) + 1
		for ov in overlays:
			var wm := MeshInstance3D.new()
			wm.mesh = smi.mesh
			for si in smi.mesh.get_surface_count():
				var am: Material = smi.get_active_material(si)
				if am != null:
					wm.set_surface_override_material(si, am)
			wm.material_overlay = ov
			var ext: float = maxf(smi.mesh.get_aabb().get_longest_axis_size(), 1e-3)
			wm.scale = Vector3.ONE * (0.6 * unit / ext)
			wm.position = Vector3((hk % 6 - 2.5) * 1.0, -2.0 - (hk / 6) * 1.0, 1.0) * unit
			tmp.add_child(wm)
			hk += 1
		# Warm the actual cuttable PBR surface in this hull's vertex format too.
		var dm := MeshInstance3D.new()
		var pm := MeshInstance3D.new()
		dm.mesh = smi.mesh
		pm.mesh = smi.mesh
		for si in smi.mesh.get_surface_count():
			var source := smi.get_active_material(si)
			dm.set_surface_override_material(si, hull_damage_template(source, sh.hull.L, sh.faction == "chorus"))
			pm.set_surface_override_material(si, hull_damage_template(source, sh.hull.L, sh.faction == "chorus", true))
		var dext := maxf(smi.mesh.get_aabb().get_longest_axis_size(), 1e-3)
		dm.scale = Vector3.ONE * (0.6 * unit / dext)
		dm.position = Vector3(0, -2, 1) * unit
		pm.scale = dm.scale
		pm.position = dm.position + Vector3.RIGHT * unit
		tmp.add_child(dm)
		tmp.add_child(pm)
		# R416 (Wounds V2): the interior shader in this hull's vertex format, once per format, before the first breach
		var ikey := "interior_warm_%d" % smi.mesh.surface_get_format(0) if smi.mesh.get_surface_count() > 0 else "interior_warm_none"
		if BREACH.v2_on() and sh.hull.authored and not _warm_seen.has(ikey):
			_warm_seen[ikey] = true
			var im := MeshInstance3D.new()
			im.mesh = smi.mesh
			im.material_override = HULL.interior_material_v2(null, Transform3D.IDENTITY, {"count": -1}, BREACH.wound_of(sh.faction), sh.hull.L)
			# kept for the battle (the shader cache is weak): freed with the stand-in, the shader was made again on the
			# first breach and compiled late (V2B PC run, Nov 22: "late shader: interior v2")
			_damage_templates["interior_v2_" + ikey] = im.material_override
			im.scale = dm.scale
			im.position = dm.position + Vector3.LEFT * unit
			tmp.add_child(im)
			stats["interior_warm_draws"] = int(stats.get("interior_warm_draws", 0)) + 1
	return hk
