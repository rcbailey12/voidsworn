extends Node3D
# Voidsworn effects library (G4). The public calls are documented in API.md; this file is the hub:
#   the effect clock (global shader parameter scene_t) and its hit pause; the GPU particle pools; the emit helpers the
#   recipes use; the event-light pool; the flash budget (WCAG 2.3.2, at most 3 counted flashes a second) and the
#   reduce-flashing mode; the trauma shake; a scheduler for things that must happen when a shot lands; and the ship
#   registry. The looks themselves live in fx_weapons.gd (weapons, impacts), fx_ship.gd (engines, shields, staged
#   damage) and fx_death.gd (deaths, wrecks, physics).

const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")

# Faction colours: linear RGB from ships3d.js FAC3D (A5 sheets 2.1). Styles are Claude's calls (vetoable):
# shield 0 gold veil, 1 hex lattice, 2 patchy, 3 prismatic; trail 0 clean, 1 sooty sputter, 2 spore puffs, 3 guttering.
const FAC := {
	"voidsworn": {"weapon": Color(1.0, 0.45, 0.15), "shield": Color(1.0, 0.46, 0.16), "engine": Color(1.0, 0.50, 0.16), "shield_style": 0, "trail": 0, "shielded": true},
	"hegemony": {"weapon": Color(0.55, 0.82, 1.0), "shield": Color(0.38, 0.68, 1.0), "engine": Color(0.45, 0.72, 1.0), "shield_style": 1, "trail": 0, "shielded": true},
	"corsair": {"weapon": Color(0.95, 0.22, 0.10), "shield": Color(0.85, 0.16, 0.10), "engine": Color(1.0, 0.38, 0.16), "shield_style": 2, "trail": 1, "shielded": true},
	"chorus": {"weapon": Color(0.85, 0.90, 0.30), "shield": null, "engine": Color(0.80, 0.90, 0.28), "shield_style": 0, "trail": 2, "shielded": false},
	"ithar": {"weapon": Color(0.75, 1.0, 0.88), "shield": Color(0.72, 1.0, 0.86), "engine": Color(0.62, 1.0, 0.84), "shield_style": 3, "trail": 0, "shielded": true},
	"deathless": {"weapon": Color(0.20, 1.0, 0.38), "shield": null, "engine": Color(0.15, 1.0, 0.35), "shield_style": 0, "trail": 3, "shielded": false},
}
const KEY_DIR := Vector3(-0.45, -0.70, -0.55)
const LIGHT_K := 0.9
const FLASH_WINDOW := 0.12   # flashes this close are one event (a salvo landing together)
const FLASH_CAP := 3

# --- settings (API.md 1, 8)
var quality = "max"
var reduce_flashing = false:
	set(v):
		reduce_flashing = v
		RenderingServer.global_shader_parameter_set(&"fx_calm", 1.0 if v else 0.0)
var shake_scale = 1.0
var unit = 1.0
var starboard_z = 1
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
var _later: Array = []      # [t, callable]
var _shake_off = Vector2.ZERO

static var _globals_added := false


static func register_globals() -> void:
	if _globals_added:
		return
	_globals_added = true
	for g in [[&"scene_t", 0.0], [&"fx_gain", 0.5556], [&"fx_calm", 0.0]]:
		if not ProjectSettings.has_setting("shader_globals/" + String(g[0])):
			RenderingServer.global_shader_parameter_add(g[0], RenderingServer.GLOBAL_VAR_TYPE_FLOAT, g[1])


func _ready() -> void:
	register_globals()


func setup(opts := {}) -> void:
	register_globals()
	rng.seed = int(opts.get("seed", 20261026))
	quality = String(opts.get("quality", "max"))
	camera = opts.get("camera", null)
	apply_shake = camera != null
	shake_scale = float(opts.get("shake", 1.0))
	unit = float(opts.get("unit", 1.0))
	starboard_z = 1 if int(opts.get("starboard_z", 1)) >= 0 else -1
	reduce_flashing = bool(opts.get("reduce_flashing", false))
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
	pools["shd"] = POOLS.Pool.new(3072 if big else 1536, _mat(SH.SHARD, 0), self, "fx_chips", POOLS.shard_shape(srng), func() -> Array: return POOLS.shard_shape(srng))
	if big:
		pools["dst"] = POOLS.Pool.new(256, _mat(SH.DISTORT, 3), self, "fx_distort", POOLS.quad_shape())
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
		s = Shader.new()
		if defines != "":
			var nl = code.find("\n", code.find("render_mode"))
			code = code.substr(0, nl + 1) + defines + code.substr(nl + 1)
		s.code = code
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
	_speed = lerpf(_speed, spd, 0.6)
	var dt = delta * _speed
	now += dt
	RenderingServer.global_shader_parameter_set(&"scene_t", now)
	_run_later()
	_update_feel(delta)
	for id in ships:
		(ships[id] as SHIP).update(self, dt)
	WEAP.update(self, dt)
	DEATH.update(self, dt)
	_update_lights()
	for k in pools:
		(pools[k] as POOLS.Pool).flush()


func anim_speed() -> float:
	return _speed


func later(t: float, f: Callable) -> void:
	if t <= now:
		f.call()
		return
	_later.append([t, f])


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
		(e[1] as Callable).call()


# ---------------------------------------------------------------- emit helpers (t = absolute effect-clock time)

func _p(a0: Vector4, a1: Vector4, a2: Vector4, a3: Vector4, a4: Vector4) -> PackedFloat32Array:
	return POOLS.pack(a0, a1, a2, a3, a4)


const SMOKY := {3: true, 7: true, 8: true, 15: true, 20: true, 23: true}


func spr(p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int, vel := Vector3.ZERO,
		drag := 0.0, spin := 0.0, acc := 0.0) -> void:
	var pool: POOLS.Pool = pools["smk"] if SMOKY.has(kind) else pools["spr"]
	pool.emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life), Vector4(col.r, col.g, col.b, i),
		Vector4(s0 * unit, s1 * unit, kind, rng.randf()), Vector4(0.0, acc, drag, spin)))


func stk(p: Vector3, t: float, life: float, col: Color, i: float, length: float, w: float, kind: int, vel: Vector3,
		drag := 0.0, acc := 0.0) -> void:
	(pools["stk"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(vel.x, vel.y, vel.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(length, w * unit, drag, kind), Vector4(0.0, acc, 0.0, 0.0)))


func ring(p: Vector3, n: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, kind: int,
		speed := 0.0, drag := 0.0) -> void:
	(pools["rng"] as POOLS.Pool).emit(POOLS.pack(Vector4(p.x, p.y, p.z, t), Vector4(n.x, n.y, n.z, life),
		Vector4(col.r, col.g, col.b, i), Vector4(s0 * unit, s1 * unit, kind, rng.randf()), Vector4(0.0, speed, drag, 0.0)))


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
# calm version (ring, soft lift, sparks). Flashes inside 0.33 s of a counted one merge into it (free).
func flash_ok(T: float) -> bool:
	if reduce_flashing:
		return false
	var near = 0
	for f in _flashes:
		if absf(f - T) < FLASH_WINDOW:
			return true
		if absf(f - T) < 1.0:
			near += 1
	if near >= FLASH_CAP:
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


# A bright pop (impact flash, explosion core) through the budget: the full flash, or a ring and a gentle lift.
func pop(p: Vector3, T: float, col: Color, size: float, i: float, n := Vector3.UP, life := 0.14) -> void:
	if flash_ok(T):
		spr(p, T, life, col, i, size * 0.6, size, 0)
	else:
		spr(p, T, maxf(life * 3.0, 0.4), col, minf(i, 3.0) * 0.4, size * 0.5, size * 1.2, 18)
		ring(p, n, T, 0.5, col, 1.2, size * 0.3, size * 1.4, 2)


# ---------------------------------------------------------------- lights

# shape 0 decay, 1 sustain (fades in and out), 2 ramp up (charge)
func light(p: Vector3, t: float, life: float, peak: float, col: Color, shape := 0) -> void:
	if reduce_flashing and shape == 0:
		peak *= 0.45
		life *= 1.8
	_lev.append([p, t, life, peak, col, shape])


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
			1: I = smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.85, 1.0, u)) * (0.88 + 0.12 * sin(now * 50.0))
			2: I = u * u
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


func shake_offset() -> Vector2:
	return _shake_off


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
	# trauma decays in about 0.3 s from a normal hit, about 0.45 s from the heaviest (A5 ranges)
	_trauma = maxf(0.0, _trauma - delta * 2.4)
	var k = _trauma * _trauma * shake_scale * (0.5 if reduce_flashing else 1.0)
	var T = Time.get_ticks_msec() / 1000.0 if not manual else now
	var amp = 0.06 * k
	_shake_off = Vector2(amp * (sin(T * 37.0) * 0.6 + sin(T * 61.0 + 1.0) * 0.4), amp * (sin(T * 43.0 + 2.0) * 0.6 + sin(T * 71.0) * 0.4))
	if apply_shake and camera != null and is_instance_valid(camera):
		camera.h_offset = _shake_off.x * unit * 10.0
		camera.v_offset = _shake_off.y * unit * 10.0


# ---------------------------------------------------------------- ships (API.md 2)

func add_ship(id: String, root: Node3D, info := {}) -> void:
	if ships.has(id):
		remove_ship(id)
	var s = SHIP.new()
	s.setup(self, id, root, info)
	ships[id] = s
	DEATH.add_collider(self, s)
	# cut the hull for its death on a worker thread, staggered so a battle start does not stall
	var n = ships.size()
	later(now + 0.4 + 0.25 * n, func() -> void:
		if ships.get(id) == s and not s.dead:
			DEATH.precompute(self, s))


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
	return FAC.get(f, FAC["voidsworn"])


func ship(id: String) -> SHIP:
	return ships.get(id, null)


# ---------------------------------------------------------------- weapons, shields, deaths (API.md 3 to 6)

func volley(attacker_id: String, kind: String, target_id: String, opts := {}) -> Dictionary:
	stats["volleys"] += 1
	return WEAP.volley(self, attacker_id, kind, target_id, opts)


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
	return DEATH.death(self, ships[id], cause)


func clear_wreck(id: String) -> void:
	DEATH.clear_wreck(self, id)


func jump_out(id: String) -> void:
	if ships.has(id):
		(ships[id] as SHIP).jump_out(self)


func ability(id: String, _ab := "") -> void:
	if ships.has(id):
		(ships[id] as SHIP).pulse(self, 1.0)


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
