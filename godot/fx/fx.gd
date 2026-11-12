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
const HULL := preload("res://fx/fx_hull.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")

# Faction colours and styles come from data (fx/faction_looks.json via fx/faction_look.gd; API.md 15), so a faction's
# palette can change without touching code. Styles are Claude's calls (vetoable).
const FLOOK := preload("res://fx/faction_look.gd")
const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const LIGHT_K := 0.9
const FLASH_WINDOW := 0.12   # flashes this close are one event (a salvo landing together)
const FLASH_CAP := 3         # counted flashes in any rolling second (WCAG 2.3.1 general flash threshold)
const FLASH_I := 4.0         # sprite intensity from which a short flash-like sprite counts (dimmer pops are free)
const FLASH_SCREEN := 0.06   # ... and only when it covers at least this share of the screen height (small sparks are free)
const FLASH_LIGHT := 8.0     # light peak from which a decaying event light counts (it lights a big patch of hull)
const FLASH_KINDS := [0, 2, 12, 13, 24]   # includes the distance-readable death core

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
var reduce_flashing = false:
	set(v):
		reduce_flashing = v
		RenderingServer.global_shader_parameter_set(&"fx_calm", 1.0 if v else 0.0)
var shake_scale = 1.0
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
# Optional comparison folder (VS_FX_ATLAS). The production macro, torpedo and death cores load the picked B atlases
# directly from fx/atlases/rebake; they require no environment switch.
var fx_atlas := ""
# Issue 281 stray-puff guard: when a test sets check_radius, every weapon/vent/thruster gas spawn records its world
# position and its source ship (fx_weapons.gd and fx_ship.gd call record_spawn), and stray_spawns() reports any that
# landed more than a small share of that ship's hull length from its real plating (see record_spawn).
var check_radius := false
var effect_spawns: Array = []
var well = Vector3.INF     # the dead star, when the board has one (world.gd sets it): tidal deaths fall toward it
var dstate = {}
var manual = false
var camera: Camera3D = null
var apply_shake = true

# --- clock
var now = 0.0
var _speed = 1.0
var _pause_until = -1.0
var _pause_depth = 1.0
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
var _lev: Array = []        # [pos, t0, life, peak, col, shape]
var _lsrc: Array = []       # persistent: {node, off, col, base, flick, seed}

# --- feel
var _trauma = 0.0
var _shakes: Array = []     # [t, amount, pos]
var _pauses: Array = []     # [t, frames]
var _flashes: PackedFloat64Array = []
var flash_log: PackedFloat64Array = []   # every counted flash (tests check the 3-a-second cap)
var _refused: PackedFloat64Array = []    # flashes the budget turned down (their lights stay dark)
var _later: Array = []      # [t, callable]
var _shake_off = Vector2.ZERO
var _punches: Array = []    # [t, amount] (F3 zoom punch)
var _kick = 0.0             # the zoom punch now (share of the field of view taken off)
var _fov_base = -1.0        # the camera's own field of view, under the punch
var _fov_set = -1.0         # what the punch last wrote
# Issue 462, a Board proposal for Ryan's eye (deaths_and_hits.md, capital row): straight after a capital's core flash the
# whole scene dims a little for a fifth of a second. Off by default (setup option "scene_dim" or VS_DEATH_DIM=1) and
# never under reduce flashing.
var scene_dim := false
const DIM_LIFE := 0.20
const DIM_DEPTH := 0.35
var _dim_veil: MeshInstance3D = null
var _dim_t0 := -1.0

static var _globals_added := false
static var _live_ids: Array = []    # instance ids of live fx nodes (ids, not references, so nothing is kept alive)


static func register_globals() -> void:
	if _globals_added:
		return
	_globals_added = true
	for g in [[&"scene_t", 0.0], [&"fx_gain", 0.5556], [&"fx_calm", 0.0], [&"fx_px", 1.0]]:
		if not ProjectSettings.has_setting("shader_globals/" + String(g[0])):
			RenderingServer.global_shader_parameter_add(g[0], RenderingServer.GLOBAL_VAR_TYPE_FLOAT, g[1])


func _ready() -> void:
	register_globals()
	_live_ids.append(get_instance_id())


func _exit_tree() -> void:
	release()


# Drop everything that holds GPU resources, so it is freed while the rendering server still exists. Background cut
# tasks are waited for first: an unawaited WorkerThreadPool task keeps its job (hull materials and textures) alive
# until the process ends, after the rendering server is gone (G2: "RenderingServer is null" at exit, a crash risk).
func release() -> void:
	_end_dim()
	for id in ships:
		var s = ships[id]
		s.wait_damage()
		if s.has_meta("cut_task"):
			WorkerThreadPool.wait_for_task_completion(int(s.get_meta("cut_task")))
			s.remove_meta("cut_task")
		if s.has_meta("cut_job"):
			s.remove_meta("cut_job")
	for w in dstate.get("wrecks", []):
		for l in w.get("lights", []):
			l["on"] = false
	ships.clear()
	_later.clear()
	_lev.clear()
	_lsrc.clear()
	_shaders.clear()
	dstate.clear()
	pools.clear()
	_live_ids.erase(get_instance_id())
	if _live_ids.is_empty():
		HULL.clear_shader_cache()


# For a clean quit (G2's main.quit_clean calls it): release every live fx node's resources now.
static func clear_static() -> void:
	for iid in _live_ids.duplicate():
		var n = instance_from_id(iid)
		if n != null and is_instance_valid(n):
			n.release()
	_live_ids.clear()


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
	scene_dim = bool(opts.get("scene_dim", OS.get_environment("VS_DEATH_DIM") == "1"))
	var rich = quality != "low"
	var soft = "#define SOFT\n" if rich else ""
	var big = quality == "max"
	pools["smk"] = POOLS.Pool.new(12288 if big else 6144, _mat(SH.SPRITE, -1, soft), self, "fx_smoke", POOLS.quad_shape())
	pools["spr"] = POOLS.Pool.new(16384 if big else 8192, _mat(SH.SPRITE, 1, soft), self, "fx_glow", POOLS.quad_shape())
	pools["stk"] = POOLS.Pool.new(16384 if big else 8192, _mat(SH.STREAK, 1), self, "fx_streaks", POOLS.streak_shape())
	pools["rng"] = POOLS.Pool.new(2048, _mat(SH.RING, 0), self, "fx_rings", POOLS.quad_shape())
	pools["rib"] = POOLS.Pool.new(192, _mat(SH.RIBBON, 1), self, "fx_ribbons", POOLS.ribbon_shape(32))
	var srng = RandomNumberGenerator.new()
	srng.seed = 991
	pools["shd"] = POOLS.Pool.new(768 if big else 384, _mat(SH.SHARD, 0), self, "fx_chips", POOLS.shard_shape(srng), func() -> Array: return POOLS.shard_shape(srng))
	if big:
		pools["dst"] = POOLS.Pool.new(256, _mat(SH.DISTORT, -20), self, "fx_distort", POOLS.quad_shape())
	for k in (64 if big else (24 if rich else 8)):
		var l = OmniLight3D.new()
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.visible = false
		l.omni_range = 30.0 * unit
		l.omni_attenuation = 1.2
		add_child(l)
		_lpool.append(l)
	phys_root = Node3D.new()
	phys_root.name = "fx_physics"
	add_child(phys_root)
	DEATH.setup_physics(self)
	notes.append("fx: quality %s, %d lights in the event pool" % [quality, _lpool.size()])


# One Shader per distinct source (materials share it): identical shaders compile once, not once per material.
var _shaders := {}


func _mat(code: String, prio := 0, defines := "") -> ShaderMaterial:
	var key := str(code.hash()) + "|" + defines
	var s: Shader = _shaders.get(key)
	if s == null:
		if defines != "":
			var nl = code.find("\n", code.find("render_mode"))
			code = code.substr(0, nl + 1) + defines + code.substr(nl + 1)
		s = HULL.shared_shader(code)
		_shaders[key] = s
	var m = ShaderMaterial.new()
	m.shader = s
	m.render_priority = prio
	return m


func mat(code: String, prio := 0, defines := "") -> ShaderMaterial:
	return _mat(code, prio, defines)


# ---------------------------------------------------------------- clock

func _process(delta: float) -> void:
	if not manual:
		step(delta)


func step(delta: float) -> void:
	# hit pause: the effect clock slows to a crawl for a few frames, then eases back (input is never blocked)
	var spd = 1.0
	if now < _pause_until:
		spd = _pause_depth
	if _death_slow_left > 0.0:
		_death_slow_left = maxf(0.0, _death_slow_left - delta)
		spd = minf(spd, 0.35) if _death_slow_left > 0.0 else spd
	_speed = lerpf(_speed, spd, 0.6)
	var dt = delta * _speed
	now += dt
	RenderingServer.global_shader_parameter_set(&"scene_t", now)
	var t0 := Time.get_ticks_usec()
	_run_later()
	t0 = pend("later", t0)
	_update_feel(delta)
	_update_dim()
	for id in ships:
		(ships[id] as SHIP).update(self, dt)
	t0 = pend("ships", t0)
	WEAP.update(self, dt)
	DEATH.update(self, dt)
	t0 = pend("weap_death", t0)
	_update_lights()
	for k in pools:
		(pools[k] as POOLS.Pool).flush()
	pend("lights_pools", t0)


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
	_later.append([t, f])


func free_effect(ref: WeakRef) -> void:
	var node = ref.get_ref()
	if is_instance_valid(node): node.queue_free()


func _run_later() -> void:
	if _later.is_empty():
		return
	var keep: Array = []
	var due: Array = []
	for e in _later:
		if float(e[0]) <= now:
			due.append(e)
		else:
			keep.append(e)
	_later = keep
	due.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for e in due:
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


const SMOKY := {3: true, 7: true, 8: true, 15: true, 20: true, 23: true}


# `px` (F3 round 2): this sprite's own minimum size on screen, in pixels on a 1080-line screen (0: the kind's floor).
# Used for the moments that must read from the battle camera: impact, muzzle, shield and kill flashes.
func spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
		drag := 0.0, spin := 0.0, acc := 0.0, px := 0.0) -> void:
	# every bright, short, flash-like sprite goes through the flash budget here, whoever calls it (muzzle cores, beam
	# contact, secondary pops, death flames): refused or in reduce-flashing mode it becomes a soft lift with no peak
	# Issue 504: the counter adds this sprite's lit area to the bright ones around it (flash_at).
	if i >= FLASH_I and life <= 0.6 and FLASH_KINDS.has(kind) and (reduce_flashing or not flash_at(p, t, maxf(s0, s1), px, life)):
		kind = 18
		i = minf(i, 3.0) * 0.4
		life = maxf(life * 3.0, 0.4)
	_emit_spr(p, t, life, col, i, s0, s1, kind, vel, drag, spin, acc, px)


# The sprite itself, after the flash decision (pop books its own, so it must not be booked twice).
func _emit_spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
		drag := 0.0, spin := 0.0, acc := 0.0, px := 0.0) -> void:
	var pool: POOLS.Pool = pools["smk"] if SMOKY.has(kind) else pools["spr"]
	pool.emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life), Vector4(col.r, col.g, col.b, i),
		Vector4(s0 * unit, s1 * unit, kind, minf(rng.randf(), 0.999) + floorf(clampf(px, 0.0, 4000.0))), Vector4(0.0, acc, drag, spin)))


# A sprite with its own pixel floor (the same as spr with px; shorter to call).
func sprx(px: float, p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
		vel := Vector3.ZERO, drag := 0.0) -> void:
	spr(p, t, life, col, i, s0, s1, kind, vel, drag, 0.0, 0.0, px)


# `wpx`, `lpx` (F3 round 2): this streak's own minimum width and length on screen (pixels at 1080 lines; 0: the kind's).
func stk(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
		drag := 0.0, acc := 0.0, wpx := 0.0, lpx := 0.0) -> void:
	(pools["stk"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(length, w * unit, drag, kind), Vector4(0.0, acc, wpx, lpx)))


# `px` (F3 round 2): the ring's own final size on screen in pixels (shock rings and ripples, kinds 1 to 3); the floor
# grows with the ring, so a far ring still expands.
func ring(p: Vector3, n: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
		speed := 0.0, drag := 0.0, px := 0.0) -> void:
	(pools["rng"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(n.x, n.y, n.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(s0 * unit, s1 * unit, kind, rng.randf()), Vector4(0.0, speed, drag, px)))


func rib(p: Vector3, dir: Vector3, length: float, t: float, life: float, col: Color, i: float, w0: float, w1: float, kind: int) -> void:
	(pools["rib"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, kind), Vector4(dir.x, dir.y, dir.z, length),
		Vector4(col.r, col.g, col.b, i), Vector4(w0 * unit, w1 * unit, rng.randf(), 0.0), Vector4(t, life, 0.0, 0.0)))


func shd(p: Vector3, t: float, life: float, vel: Vector3, size: float, heat: float, spin := 4.0, drag := 0.3, tint := 0.0) -> void:
	var ax = rdir()
	(pools["shd"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(ax.x, ax.y, ax.z, spin), Vector4(size * unit, 0.0, tint, drag), Vector4(heat, rng.randf(), 0.0, 0.0)))


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
func flash_at(p: Vector3, T: float, size: float, px := 0.0, life := FLASH_WINDOW) -> bool:
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
		bright = _flash_count(T)
		counted = 1 if bright else 0
	if bright:
		_flash_remember(T, life, c)
	_flash_note(T, c, lit, counted, 1 if bright else 0, life)
	pend("flash", t0)
	return bright


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


# Where a flash sits on screen and how wide it is drawn: [x, y, d] in viewport pixels, or empty when behind the camera.
func _flash_disc(p: Vector3, size: float, px: float) -> PackedFloat64Array:
	if camera == null or not is_instance_valid(camera) or not camera.is_inside_tree() or camera.is_position_behind(p):
		return PackedFloat64Array()
	var d := maxf(camera.global_position.distance_to(p), 0.01)
	var h := 2.0 * d * tan(deg_to_rad(camera.fov) * 0.5)
	var shown := maxf(size * unit / h, maxf(px, 14.0) * min_px / 1080.0)   # the same drawn size _flash_sized uses
	var sp := camera.unproject_position(p)
	return PackedFloat64Array([sp.x, sp.y, ceilf(shown * _flash_vh())])


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
# F3 round 2: a pop smaller on screen than the WCAG area threshold (6% of the screen height, `_flash_sized`, the same
# rule spr uses) is not a counted flash and never waits on the budget; before, every pop booked a flash, so in a busy
# fight most hits (and a dying ship's cook-off) used up the 3 a second and drew as faint lifts, and the kill's own blast
# was refused. `px` is the pop's own pixel floor (see spr).
func pop(p: Vector3, T: float, col: Color, size: float, i: float, n := Vector3.UP, life := 0.14, px := 0.0) -> void:
	# Issue 504: one booking by area (flash_at), whatever its brightness (as on main: every pop is a candidate); the
	# bright sprite is then drawn without a second booking.
	if not reduce_flashing and flash_at(p, T, size, px, life):
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
# refused flash are still lit without a sharp step. Reduce flashing is untouched (its own path below).
func light(p: Vector3, t: float, life: float, peak: float, col: Color, shape := 0) -> void:
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
	_lev.append([p, t, life, peak, col, shape])


# Whether a sprite of this size at p is big enough on screen to count as a flash (WCAG counts flashes by area; small
# muzzle flashes and sparks at battle zoom are below it). With no camera every bright sprite counts.
func _flash_sized(p: Vector3, size: float, px := 0.0) -> bool:
	if camera == null or not is_instance_valid(camera):
		return true
	var d := maxf(camera.global_position.distance_to(p), 0.01)
	var h := 2.0 * d * tan(deg_to_rad(camera.fov) * 0.5)
	# the shaders' pixel floors grow a sprite on screen: count the size it is drawn at (round 2)
	var shown := maxf(size * unit / h, maxf(px, 14.0) * min_px / 1080.0)
	return shown >= FLASH_SCREEN


func light_source(node: Node3D, off: Vector3, col: Color, base: float, flick := 0.3) -> Dictionary:
	var s = {"node": node, "off": off, "col": col, "base": base, "flick": flick, "seed": rng.randf() * 10.0, "on": true}
	_lsrc.append(s)
	return s


func _update_lights() -> void:
	var ev: Array = []
	var keep: Array = []
	var cp = camera.global_position if camera != null else Vector3.ZERO
	for e in _lev:
		var a: float = now - float(e[1])
		var life: float = e[2]
		if a > life:
			continue
		keep.append(e)
		if a < 0.0:
			continue
		var u = a / life
		var I = 0.0
		match int(e[5]):
			0: I = pow(1.0 - u, 2.0)
			1: I = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.85, 1.0, u)) * (1.0 if reduce_flashing else 0.88 + 0.12 * sin(now * 50.0))
			2: I = u * u
			3: I = smoothstep(0.0, 0.25, u) if u < 0.25 else pow(1.0 - (u - 0.25) / 0.75, 2.0)   # issue 504: soft rise
		ev.append([e[0], I * float(e[3]), e[4]])
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
		ev.append([n.global_transform * (s["off"] as Vector3), float(s["base"]) * fl, s["col"]])
	_lsrc = ks
	# brightest first, nearer lights count more when the pool is short
	for e in ev:
		e.append(float(e[1]) / (1.0 + (e[0] as Vector3).distance_to(cp) / (200.0 * unit)))
	ev.sort_custom(func(a: Array, b: Array) -> bool: return float(a[3]) > float(b[3]))
	for k in _lpool.size():
		var l: OmniLight3D = _lpool[k]
		if k < ev.size() and float(ev[k][1]) > 0.03:
			l.position = ev[k][0]
			l.light_energy = float(ev[k][1]) * LIGHT_K
			l.light_color = ev[k][2]
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
var _core_at := {}            # ship id -> the effect clock time of its core flash (big hulls broken by the timeline)


# The effect clock time of a dying ship's core flash, read from its death timeline; -1 when it has none (small hulls,
# the Chorus rupture, a burnt-out hulk).
func death_core_at(id: String) -> float:
	return float(_core_at.get(id, -1.0))


# A key or a click during the beat: back to full speed now, and no new beat from a death already under way.
func skip_death_slowmo() -> void:
	_death_slow_left = 0.0
	_death_hurry_until = maxf(_death_hurry_until, now + 0.1)
	for id in _core_at.keys():
		if float(_core_at[id]) > now - 0.5:
			_core_at[id] = -1.0


# Same presentation hurry as the battle. Also suppress a beat scheduled later in this death.
func hurry_death() -> void:
	_death_slow_left = 0.0
	_death_hurry_until = now + 3.0
	_pause_until = -1.0
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


func _update_feel(delta: float) -> void:
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
			_pause_until = maxf(_pause_until, now + dur * 0.08)
			_pause_depth = 0.08
		else:
			keep.append(p)
	_pauses = keep
	_update_punch()
	# trauma decays in about 0.3 s from a normal hit, about 0.45 s from the heaviest (A5 ranges)
	_trauma = maxf(0.0, _trauma - delta * 2.4)
	var k = _trauma * _trauma * shake_scale * (0.5 if reduce_flashing else 1.0)
	var T = Time.get_ticks_msec() / 1000.0 if not manual else now
	var amp = 0.06 * k
	_shake_off = Vector2(amp * (sin(T * 37.0) * 0.6 + sin(T * 61.0 + 1.0) * 0.4), amp * (sin(T * 43.0 + 2.0) * 0.6 + sin(T * 71.0) * 0.4))
	if apply_shake and camera != null and is_instance_valid(camera):
		camera.h_offset = _shake_off.x * unit * 10.0
		camera.v_offset = _shake_off.y * unit * 10.0


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


# Issue 462: the scene dim after a capital's core flash (see scene_dim). A black veil a hair in front of the camera fades
# in over a quarter of the dip and out over the rest, so the whole frame (sky, ships, effects) loses a little light
# whatever environment the scene uses. A second dip during one is ignored.
func dim_scene(t: float) -> void:
	if not scene_dim or reduce_flashing or _dim_t0 >= 0.0:
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

func add_ship(id: String, root: Node3D, info := {}) -> void:
	if ships.has(id):
		remove_ship(id)
	var s = SHIP.new()
	s.setup(self, id, root, info)
	# Issue 462 (deaths_and_hits.md): a cruiser parts into two halves, a capital into three pieces.
	s.set_meta("death_cut_count", 2 if s.death_tier == "capital" else 1)
	ships[id] = s
	DEATH.add_collider(self, s)
	# cut the hull for its death on a worker thread, staggered so a battle start does not stall
	var n = ships.size()
	later(now + 0.4 + 0.25 * n, func l_cut_first() -> void:
		if ships.get(id) == s and not s.dead:
			var t_c := Time.get_ticks_usec()
			DEATH.precompute(self, s)
			pend("cut_first", t_c))


func remove_ship(id: String) -> void:
	if not ships.has(id):
		return
	(ships[id] as SHIP).teardown(self)
	ships.erase(id)


func set_engine(id: String, level: float) -> void:
	if ships.has(id):
		(ships[id] as SHIP).engine_level = level


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
func volley_at(from: Vector3, kind: String, to: Vector3, opts := {}) -> Dictionary:
	return WEAP.volley_points(self, from, kind, to, opts)


func shield_break(id: String, quad: int) -> void:
	if ships.has(id):
		(ships[id] as SHIP).shield_break(self, quad)


func death(id: String, cause := "blast") -> float:
	if not ships.has(id):
		return 0.0
	stats["deaths"] += 1
	var t0 := Time.get_ticks_usec()
	var tl_before = (ships[id] as SHIP).get_meta("death_timeline", null)
	var r: float = DEATH.death(self, ships[id], cause)
	pend("death", t0)
	var s: SHIP = ships[id]
	_core_at.erase(id)
	# only a timeline this death made (a burnt-out hulk or the Chorus rupture makes none and has no core flash)
	if s.death_big and s.has_meta("death_timeline") and s.get_meta("death_timeline") != tl_before and s.has_meta("death_start"):
		var tl = s.get_meta("death_timeline")
		var core := float(s.get_meta("death_start")) + float(tl.cut) + float(tl.core_delay)
		_core_at[id] = core
		if kill_slowmo:
			later(core, func l_kill_slowmo() -> void:
				if float(_core_at.get(id, -1.0)) >= 0.0:
					death_slowmo())
	return r


func clear_wreck(id: String) -> void:
	DEATH.clear_wreck(self, id)


func jump_out(id: String) -> void:
	if ships.has(id):
		(ships[id] as SHIP).jump_out(self)


func ability(id: String, _ab := "") -> void:
	if ships.has(id):
		(ships[id] as SHIP).pulse(self, 1.0)


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


# The rules' "board" event (API.md 11): the boarding party's breach in the target's hull at a plausible boarding point
# (the side facing the attacker, mid section, near the waterline of the hull's side, never on top or below), venting
# gas and lit from inside while the fight goes on (about 3 s), then a dark gash. Returns seconds until it has played.
func board(attacker_id: String, target_id: String, _result := "") -> float:
	if not ships.has(target_id):
		return 0.0
	var s: SHIP = ships[target_id]
	var toward: Vector3 = ships[attacker_id].to_world(ships[attacker_id].hull.c) if ships.has(attacker_id) else s.to_world(s.hull.c + Vector3(0, 0, s.hull.W * 3.0))
	var inv: Transform3D = s.xf().affine_inverse()
	var tl: Vector3 = inv * toward
	var side := Vector3(0, 0, signf(tl.z - s.hull.c.z) if absf(tl.z - s.hull.c.z) > 1e-3 else 1.0)
	var from: Vector3 = s.hull.c + side * (s.hull.W * 2.0 + s.hull.L * 0.2) + Vector3(s.hull.L * 0.05, 0, 0)
	var h: Dictionary = s.hull.ray(from, -side)
	if h.is_empty():
		return 0.0
	var lp: Vector3 = h["p"]
	var ln: Vector3 = h["n"]
	s.add_mark(self, "board", 2, lp, ln, -ln)
	var wp: Vector3 = s.to_world(lp)
	var wn: Vector3 = s.dir_world(ln)
	var k: float = s.scale_k()
	var T: float = now + 0.1
	# a pried-open hatch: a short, dull blast (not a counted flash), then gas venting and sparks from inside
	spr(wp + wn * 0.3 * k, T, 0.4, Color(1, 0.65, 0.35), 2.5, 0.6 * k, 1.8 * k, 2)
	for j in 14:
		spr(wp + wn * 0.2 * k, T + 0.15 + j * 0.2, 1.4, Color(0.62, 0.66, 0.74), 0.25, 0.3 * k, 2.2 * k, 7, (wn + rdir() * 0.25).normalized() * 4.0 * k, 0.8)
	for j in 18:
		stk(wp, T + 0.3 + randf() * 2.6, 0.3 + randf() * 0.3, Color(1, 0.7, 0.4), 4.0, 0.05, 0.08 * k, 1, (wn + rdir() * 0.6).normalized() * (5 + randf() * 8) * k, 2.0)
	light(wp + wn * 0.6 * k, T, 3.0, 2.5, Color(1, 0.6, 0.3), 1)
	shake(T, 0.06, wp)
	return 3.2


func command(id: String, _cmd := "") -> void:
	if ships.has(id):
		(ships[id] as SHIP).pulse(self, 1.6)


# Travelling torpedoes (B3): a lane during the player's turn, the torpedo parked in it, the strike next turn.
func torp_lane(lane_id: String, attacker_id: String, to_point: Vector3, turns := 1) -> void:
	WEAP.torp_lane(self, lane_id, attacker_id, to_point, turns)


func torp_launch(lane_id: String) -> void:
	WEAP.torp_launch(self, lane_id)


func torp_strike(lane_id: String, target_id: String, hit := {}) -> Dictionary:
	return WEAP.torp_strike(self, lane_id, target_id, hit)


func torp_lane_clear(lane_id: String) -> void:
	WEAP.torp_lane_clear(self, lane_id, true)


func launch(carrier_id: String, squadron_id := "") -> void:
	WEAP.launch(self, carrier_id, squadron_id)


func tick(id: String, kind := "fire") -> void:
	if ships.has(id):
		(ships[id] as SHIP).tick_flare(self, kind)


func particles_emitted() -> int:
	var n = 0
	for k in pools:
		n += (pools[k] as POOLS.Pool).emitted
	return n


# ---------------------------------------------------------------- shader warm-up (API.md 1)

# Draws every effect material once in front of the camera, in the battle's own environment and lights, so no shader
# pipeline compiles for the first time in the middle of a fight (the first lance, shield ripple or death). Await it on
# the loading screen after the ships, lights and world are built: `await fx.warmup(cam)`. Takes a few frames.
func warmup(cam: Camera3D, frames := 4) -> void:
	if cam == null:
		return
	# The temporary PBR adapter is queried for uniforms at death too. Keep its
	# shader alive so that query never recompiles it for each new ship.
	_shaders["hull_exterior"] = HULL.shared_shader(HULL.EXTERIOR)
	var at = cam.global_transform * Vector3(0, 0, -30.0 * unit)
	var T = now
	var c = Color(1, 0.6, 0.3)
	for k in [0, 1, 2, 3, 4, 5, 7, 8, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23]:
		spr(at + rdir(), T, 0.5, c, 0.02, 0.5, 0.5, k)
	for k in [0, 1, 3, 4, 5, 6, 7]:
		stk(at, T, 0.5, c, 0.02, 1.0, 0.1, k, Vector3(1, 0, 0))
	for k in [0, 1, 2, 3, 4]:
		ring(at, Vector3.UP, T, 0.5, c, 0.02, 0.5, 1.0, k)
	for k in [0, 1, 2, 3, 5, 6, 7, 8, 9]:
		rib(at, Vector3(1, 0, 0), 2.0, T, 0.5, c, 0.02, 0.2, 0.2, k)
	shd(at, T, 0.5, Vector3.ZERO, 0.2, 1.0)
	dst(at, T, 0.5, 0.5, 1.0, 0, 0.1)
	dst(at, T, 0.5, 0.5, 1.0, 1, 0.1)
	var tmp = Node3D.new()
	tmp.name = "fx_warmup"
	add_child(tmp)
	tmp.global_position = at
	var box = BoxMesh.new()
	box.size = Vector3.ONE * 2.0
	var mats: Array = [mat(SH.SHIELD, 2), mat(SH.SHARD, 0), mat(SH.SPRITE, 1), mat(SH.STREAK, 1),
		mat(SH.RIBBON, 1), mat(SH.TRAIL, 1), mat(WEAP.LANE, 1), mat(DEATH.SLAG, 0),
		HULL.damage_material(StandardMaterial3D.new(), Transform3D.IDENTITY, {}, 1.0)]
	if not compat:
		mats.append_array([mat(SH.VOL, 2), mat(SH.SPRITE, 1, "#define SOFT\n")])
	for band in ["small", "cruiser", "capital"]:
		for kind in ["flash", "vent", "cool"]:
			var baked := DEATH.flipbook_material(self, kind, band)
			baked.set_shader_parameter("born", now)
			baked.set_shader_parameter("intensity", 0.01)
			mats.append(baked)
	mats.append(DEATH.power_material(HULL.damage_material(StandardMaterial3D.new(), Transform3D.IDENTITY, {}, 1.0)))
	mats.append(mat(SH.TEAR, 1))   # issue 462: the dying hull's tear overlay
	# issue 220: the torpedo and rocket bodies (drive glow, star torpedo body, exhaust plume) and the weapon bursts' atlas
	# shader: their first launch or hit compiled them mid-fight (a 53 ms frame with 3 surface pipelines at the gate scene)
	mats.append_array([mat(WEAP.DRIVE, 1), mat(WEAP.STAR_BODY)])
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
	for rel in ["weapons/impact/impact_", "weapons/impact/flash_", "weapons/macro/impact_", "weapons/macro/flash_", "death/small/flash_", "death/cruiser/flash_", "death/capital/flash_"]:
		for variant in 3:
			var production := DEATH.route_material(self, SH.DEATH_FLIPBOOK, rel, true, variant)
			production.set_shader_parameter("born", now)
			production.set_shader_parameter("intensity", 0.01)
			mats.append(production)
	DEATH.tear_particles(self, at, Vector3.UP, 0.1, Vector3.ZERO)
	for i in mats.size():
		# Pin generated hull shaders until release, even after the temporary warmup meshes go away.
		_shaders["warm:" + str(mats[i].shader.code.hash())] = mats[i].shader
		var mi = MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = mats[i]
		mi.position = Vector3((i % 4 - 1.5) * 2.5, (i / 4 - 1.0) * 2.5, 0) * unit
		tmp.add_child(mi)
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
	# opaque pass and CHUNK overlay in that exact format before the first death.
	var cap_arr: Array = harr.duplicate()
	var cap_mesh := ArrayMesh.new()
	cap_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cap_arr)
	var cap_mi := MeshInstance3D.new()
	cap_mi.mesh = cap_mesh
	cap_mi.material_override = mat(DEATH.SLAG, 0)
	cap_mi.material_overlay = mat(SH.CHUNK, 1)
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
	# overlays (death pieces and cracks) over a plain lit material, and a debris body
	var base = StandardMaterial3D.new()
	for ov in [mat(SH.CHUNK, 1), mat(SH.CRACKS, 1), mat(SH.HULLIN, 1)]:
		var mi = MeshInstance3D.new()
		mi.mesh = box
		mi.material_override = base
		mi.material_overlay = ov
		tmp.add_child(mi)
	# every hull as it is drawn, with the death overlays on top: the overlay pipelines are per vertex format, so warming
	# them on a box (above) does not cover the hulls, and the first break-up would compile them
	var seen := {}
	var hk := 0
	for sid in ships:
		var sh: SHIP = ships[sid]
		for m in sh.meshes:
			var smi := m as MeshInstance3D
			if smi == null or smi.mesh == null or seen.has(smi.mesh.get_instance_id()):
				continue
			seen[smi.mesh.get_instance_id()] = true
			for ov in [mat(SH.CHUNK, 1), mat(SH.CRACKS, 1), mat(SH.HULLIN, 1)]:
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
			dm.mesh = smi.mesh
			for si in smi.mesh.get_surface_count():
				dm.set_surface_override_material(si, HULL.damage_material(smi.get_active_material(si), Transform3D.IDENTITY, {}, 1.0))
				var hs: Shader = (dm.get_surface_override_material(si) as ShaderMaterial).shader
				_shaders["warm:" + str(hs.code.hash())] = hs
			var dext := maxf(smi.mesh.get_aabb().get_longest_axis_size(), 1e-3)
			dm.scale = Vector3.ONE * (0.6 * unit / dext)
			dm.position = Vector3(0, -2, 1) * unit
			tmp.add_child(dm)
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
		phys_root.add_child(rb)
		rb.global_position = deep
		rb.linear_velocity = Vector3(0.1, 0, 0)
		DEATH.spawn_debris(self, deep + Vector3(10, 0, 0), Vector3.ZERO, 3, 0.2 * unit)
		get_tree().create_timer(0.5).timeout.connect(free_effect.bind(weakref(rb)))
	for i in frames:
		await RenderingServer.frame_post_draw
	tmp.queue_free()
