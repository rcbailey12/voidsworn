extends RefCounted
# Weapon effects: every rules weapon kind (battery, flak, lance, torp, bio, gauss, sq) with its fire, travel and impact on
# shields and hulls by weight, and a faction look per weapon id (data.js FAC_WNAMES): the five cheap axes from the
# BattleTech study (colour, trail, count, smoke, timing) plus shape. Built to the A5 sheets (contrib/muse/reviews/
# a5_effects_sheets_synthesis.md); every number below is a starting value inside the sheets' testing ranges.
#
# Looks (Claude's calls, vetoable):
#   battery: macro (battery, hbattery: ripple broadside, muzzle blast, smoke ring, white-core shell tracer)
#            auto (autocannon, Corsair junk turret: rapid small tracers, brass flicker, sooty for Corsair)
#            las (Voidsworn las-turret and las-repeater: short hard-cored laser bolts)
#            plasma (Hegemony laser, turbo, hturbo: slow fat churning bolts with a corona, splashing slag)
#            scatter (Corsair scrap scatter gun: a spray of junk tracers)   prism (Ithar shard: glassy prismatic needles)
#            needle (Ithar needle beam turret: a thin prismatic beam)
#   lance:   lance (Voidsworn penance lance)   ion (Hegemony: beam with crawling arcs, blue static wash)
#            pulsar (Ithar: the beam in travelling pulses)   doom (Deathless doom arc: re-striking green lightning)
#   torp:    torp (Voidsworn hellfire: armoured bodies, short plumes)   rockets (Corsair rattle-rocket pods: swarms of
#            small sooty rockets)   star (Ithar star torpedo: a little sun)
#   flak:    airbursts in the faction's style (Hegemony picket lasers, Chorus spores, Ithar mirror glints, Deathless
#            gauss shredder streaks, Corsair chaff)
#   bio:     spine (bioplasma: wobbling globs that splash and corrode)   tendril (boarding tendrils: an organic lash)
#   gauss:   coil charge, a near invisible slug, a punch-through with an exit spray
#   sq:      guns, bombs, sporeb: craft on a strafing run

const POOLS := preload("res://fx/fx_pool.gd")
const SH := preload("res://fx/fx_shaders.gd")
const DEATH := preload("res://fx/fx_death.gd")
const WING := preload("res://render/squadron_wing.gd")
const CRAFT := preload("res://render/squadron_craft.gd")

const LOOK_BY_ID := {
	"battery": "macro", "hbattery": "macro", "autocannon": "auto", "turret": "las", "laser": "plasma", "turbo": "plasma",
	"hturbo": "plasma", "scatter": "scatter", "shard": "prism", "lance": "lance", "ion": "ion", "pulsar": "pulsar",
	"doom": "doom", "torp": "torp", "htorp": "rockets", "startorp": "star", "flak": "flak", "spores": "spores",
	"gsentry": "gflak", "bioplasma": "spine", "tendril": "tendril", "gauss": "gauss", "guns": "guns", "bombs": "bombs",
	"sporeb": "sporeb", "ram": "ram",
}
const DEFAULT_LOOK := {"battery": "macro", "flak": "flak", "lance": "lance", "torp": "torp", "bio": "spine", "gauss": "gauss", "sq": "guns"}
# weight 1 light, 2 medium, 3 heavy
const WEIGHT_BY_ID := {
	"autocannon": 1, "flak": 1, "scatter": 1, "guns": 1, "turret": 1, "spores": 1, "gsentry": 1,
	"battery": 2, "laser": 2, "turbo": 2, "bioplasma": 2, "shard": 2, "gauss": 2, "ion": 2, "pulsar": 2, "sporeb": 2, "bombs": 2,
	"hbattery": 3, "hturbo": 3, "lance": 3, "torp": 3, "htorp": 3, "startorp": 3, "doom": 3, "tendril": 3, "ram": 3,
}
const SHELL_SPEED := 160.0
# Plasma is light blue whoever fires it (Ryan, Oct 26): the bolt, its splash and the crater it leaves; the shape (a fat
# churning bolt, a splash crater with a droplet fan) carries the identity next to blue shields and the cyan interface
const PLASMA_COL := Color(0.52, 0.82, 1.0)
# A hit's momentum for the target's physical reaction (R50, fx_ship.hit_react): torpedoes and rams shove, slugs and
# shells kick, light guns tap, lances and ions are energy and barely move a ship at all
const REACT_IMPULSE := {"torp": 6.0, "star": 6.5, "ram": 8.0, "rockets": 2.0, "macro": 1.0, "plasma": 0.7, "gauss": 1.6,
	"auto": 0.3, "scatter": 0.35, "guns": 0.25, "las": 0.08, "prism": 0.12, "flak": 0.2, "pflak": 0.2, "mflak": 0.2,
	"gflak": 0.25, "spores": 0.1, "spine": 0.45, "tendril": 0.7, "sporeb": 0.2, "bombs": 0.8, "lance": 0.08, "needle": 0.05,
	"pulsar": 0.05, "ion": 0.03, "doom": 0.1}
const PLASMA_HOT := Color(0.86, 0.95, 1.0)
# F3 (feel pass, Ryan Nov 1: "effects looked very weak, especially at a distance and for smaller ships"): the size every
# effect is drawn at follows the ship (scale_k, a frigate 0.43, a super-dreadnought 2.07), which left a frigate's fire
# and the hits on it a fifth of a capital's. Fire and impact visuals now use at least these scales (geometry such as
# gun mounts and hull marks keeps the true one); the shader floors (fx_shaders px_world) then keep them readable at
# distance. Claude's calls, vetoable.
const VIS_K_FIRE := 0.75
const VIS_K_HIT := 0.85
# F3 round 2 (Opus's read of round 1: at the default battle camera most weapons were still "a thin line and a small
# dot"): the moments that must land get their own size on screen, in pixels on a 1080-line screen (fx.spr px), by the
# weapon's weight: the impact flash, the muzzle flash, the hull light. All stay under the 65 px (6% of the screen
# height) that would make them counted flashes at the battle camera, so they never wait on the flash budget there.
# Claude's calls, vetoable.
const HIT_PX := [0.0, 34.0, 46.0, 56.0]     # impact flash by weight (light, medium, heavy)
const MUZ_PX := [0.0, 20.0, 26.0, 32.0]     # muzzle flash by weight
const HULL_LIGHT := 7.9                    # a hit's light on the plate (just under the 8 that counts as a flash)
# Issue 281 run 6 (R150): the baked muzzle and impact gas read better about 1.5x bigger than run 5 shipped them.
const WEAPON_GAS_SCALE := 1.5


static func look_of(kind: String, wid: String, faction: String) -> String:
	var lk: String = LOOK_BY_ID.get(wid, DEFAULT_LOOK.get(kind, "macro"))
	if lk == "las" and faction == "ithar":
		lk = "needle"
	if lk == "auto" and faction == "voidsworn":
		lk = "las"
	if kind == "torp" and wid == "torp" and faction == "corsair":
		lk = "rockets"
	if lk == "flak":
		lk = {"hegemony": "pflak", "chorus": "spores", "ithar": "mflak", "deathless": "gflak"}.get(faction, "flak")
	return lk


static func default_shots(lk: String) -> int:
	return {"macro": 4, "auto": 3, "las": 2, "plasma": 2, "scatter": 5, "prism": 3, "needle": 2, "lance": 1, "ion": 1,
		"pulsar": 2, "doom": 1, "torp": 1, "rockets": 2, "star": 1, "spine": 2, "tendril": 2, "gauss": 3, "guns": 3,
		"bombs": 2, "sporeb": 2}.get(lk, 2)


# ---------------------------------------------------------------- the volley

static func volley(fx, aid: String, kind: String, tid: String, opts: Dictionary) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var r = _volley_entry(fx, aid, kind, tid, opts)
	fx.pend("volley", t0)
	return r


static func _volley_entry(fx, aid: String, kind: String, tid: String, opts: Dictionary) -> Dictionary:
	var A = fx.ship(aid)
	var Tg = fx.ship(tid)
	if A == null or Tg == null:
		return {"impacts": [], "done": 0.0}
	var from_c: Vector3 = A.to_world(A.hull.c)
	return _volley(fx, A, from_c, kind, Tg, Tg.to_world(Tg.hull.c), opts)


static func volley_points(fx, from: Vector3, kind: String, to: Vector3, opts: Dictionary) -> Dictionary:
	return _volley(fx, null, from, kind, null, to, opts)


static func _volley(fx, A, from_c: Vector3, kind: String, Tg, to_c: Vector3, opts: Dictionary) -> Dictionary:
	var wid = String(opts.get("weapon_id", ""))
	var faction: String = A.faction if A != null else String(opts.get("faction", "voidsworn"))
	var fac: Dictionary = fx.faction_info(faction)
	var lk = look_of(kind, wid, faction)
	var w: int = WEIGHT_BY_ID.get(wid, 3 if lk in ["lance", "doom", "torp", "star"] else 2)
	var shots: Array = opts.get("shots", [])
	if shots.is_empty():
		for i in default_shots(lk):
			shots.append(true)
	var hits: Array = opts.get("hits", [])
	var quad = int(opts.get("quad", -1))
	var T0: float = fx.now
	var ka_geo: float = A.scale_k() if A != null else 1.0
	var ka: float = maxf(ka_geo, VIS_K_FIRE)
	var kt: float = maxf(Tg.scale_k() if Tg != null else 1.0, VIS_K_HIT)
	var col: Color = fac["weapon"] if lk != "plasma" else PLASMA_COL
	# mounts: the guns that can bear (never backward)
	var mounts: Array = []
	if A != null:
		var tl: Vector3 = A.xf().affine_inverse() * to_c
		for m in A.hull.mounts_for(tl, maxi(shots.size(), 1)):
			mounts.append({"p": A.to_world((m["p"] as Vector3) + (m["n"] as Vector3) * 0.15 * ka_geo), "n": A.dir_world(m["n"])})
		if lk in ["lance", "ion", "pulsar", "doom", "torp", "star", "gauss"] and (A.xf().affine_inverse() * to_c - A.hull.c).normalized().x > 0.5:
			for i in mounts.size():
				mounts[i] = {"p": A.to_world(A.hull.bow + Vector3(0.3 * ka_geo, 0, 0)), "n": A.dir_world(Vector3(1, 0, 0))}
	else:
		for i in maxi(shots.size(), 1):
			mounts.append({"p": from_c, "n": (to_c - from_c).normalized()})
	var impacts: Array = []
	var done = 0.0
	var hj = 0
	var total = shots.size()
	for i in total:
		var hit: bool = bool(shots[i])
		var hd: Dictionary = {}
		if hit:
			hd = hits[hj] if hj < hits.size() else {"shield": 0, "hull": 1, "section": "mid", "crit": false}
			hj += 1
		var m: Dictionary = mounts[i % mounts.size()]
		var from: Vector3 = m["p"]
		var tgt = _target(fx, Tg, to_c, from, hit, hd, quad, kt)
		if bool(opts.get("debug", false)):
			# (tests: where each shot strikes, in world space and relative to the target's centre)
			var tp: Vector3 = Tg.root.global_position if Tg != null else to_c
			print("[fx] shot %d %s from %s hit %s (rel %s) n %s shield %s miss %s sec %s" % [i, lk, str(from), str(tgt["p"]),
				str((tgt["p"] as Vector3) - tp), str(tgt["n"]), str(tgt.get("shield", false)), str(tgt.get("miss", false)),
				str(hd.get("section", ""))])
		var r = _shot(fx, lk, kind, w, i, total, from, m["n"], tgt, T0, col, fac, A, Tg, hd, ka, kt, faction)
		impacts.append(float(r[0]) - T0)
		done = maxf(done, float(r[1]) - T0)
		if Tg != null and hit:
			Tg.busy_until = maxf(Tg.busy_until, float(r[0]))
	return {"impacts": impacts, "done": done}


# Where a shot ends: the shield bubble, the hull (section, facing), or past the target for a miss.
static func _target(fx, Tg, to_c: Vector3, from: Vector3, hit: bool, hd: Dictionary, quad: int, kt: float) -> Dictionary:
	if Tg == null:
		var d = (to_c - from).normalized()
		return {"p": to_c, "n": -d, "shield": false, "miss": not hit}
	if not hit:
		var d = (to_c - from).normalized()
		var side = d.cross(Vector3.UP).normalized()
		var p = to_c + side * (fx.rng.randf_range(-1.0, 1.0) * Tg.hull.W * 1.5 + signf(fx.rng.randf() - 0.5) * Tg.hull.W) \
			+ Vector3(0, fx.rng.randf_range(-0.5, 1.0) * Tg.hull.H * 1.5, 0) + d * Tg.hull.L * fx.rng.randf_range(0.4, 1.2)
		return {"p": p, "n": -d, "shield": false, "miss": true}
	var on_shield: bool = Tg.shielded and Tg._shield_mat != null and float(hd.get("shield", 0)) > 0.0 and float(hd.get("hull", 0)) <= 0.0
	var sec: int = {"eng": 0, "mid": 1, "prow": 2}.get(String(hd.get("section", "")), -1)
	var inv: Transform3D = Tg.xf().affine_inverse()
	var view := Vector3.ZERO
	if fx.camera != null and is_instance_valid(fx.camera):
		view = (inv.basis * (fx.camera.global_position - to_c)).normalized()
	var hp: Dictionary = Tg.hull.hit_point(inv * from, sec, quad, view)
	if on_shield:
		var sp: Dictionary = Tg.shield_point(from, hp["p"])
		return {"p": sp["p"], "n": sp["n"], "shield": true, "local": sp["local"], "miss": false}
	# shots that went through a shield and still hurt the hull also light the bubble on the way in
	var out = {"p": Tg.to_world(hp["p"]), "n": Tg.dir_world(hp["n"]), "lp": hp["p"], "ln": hp["n"], "shield": false, "miss": false}
	if Tg.shielded and Tg._shield_mat != null and float(hd.get("shield", 0)) > 0.0:
		var sp2: Dictionary = Tg.shield_point(from, hp["p"])
		out["through"] = sp2
	return out


# One shot: fire, travel, impact. Returns [impact time, end time] on the effect clock.
static func _shot(fx, lk: String, kind: String, w: int, i: int, n: int, from: Vector3, mn: Vector3, tg: Dictionary, T0: float,
		col: Color, fac: Dictionary, A, Tg, hd: Dictionary, ka: float, kt: float, faction := "voidsworn") -> Array:
	var to: Vector3 = tg["p"]
	var dv = to - from
	var dist = maxf(dv.length(), 0.01)
	var dir = dv / dist
	var tf = T0
	var ti = T0
	var tend = T0
	match lk:
		"macro":
			tf = T0 + 0.2 + i * float(fx.timing.get("ripple", 0.08))
			_muzzle_blast(fx, from, dir, tf, col, ka * (1.25 if w >= 3 else 1.0), MUZ_PX[clampi(w, 1, 3)] + 4.0, w, A)
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * fx.unit
			ti = tf + dist / spd
			fx.stk(from, tf, dist / spd, col.lerp(Color.WHITE, 0.3), 18.0, 9.0 * ka, 0.75 * ka * (1.2 if w >= 3 else 1.0), 0, dir * spd, 0.0, 0.0, 4.0 if w >= 3 else 3.4, 26.0)
			fx.light(from + mn * 1.5 * ka, tf, 0.22, 7.8, col.lerp(Color.WHITE, 0.4), 0)
			fx.shake(tf, 0.03, from)
		"auto":
			tf = T0 + 0.05 + i * 0.22
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 1.3 * fx.unit
			for b in 4:
				var tb = tf + b * 0.05
				var jit = fx.rdir() * 0.3 * kt
				# round 2: a stuttering brass muzzle flicker and fat short tracers (four to a burst: the chatter is its signature)
				_burst(fx, from + dir * 0.4 * ka, dir, tb, 1.8 * ka, "flash", 0.12, Color(0.94, 0.73, 0.4), 3.8, 14.0)
				fx.stk(from, tb, dist / spd, Color(1, 0.78, 0.4), 13.0, 4.0 * ka, 0.4 * ka, 0, (dir + jit / dist) * spd, 0.0, 0.0, 3.6, 18.0)
				if A != null and A.faction == "corsair":
					_burst(fx, from + dir * 0.8 * ka, dir, tb + 0.02, 2.0 * ka, "cool", 0.4, col, 0.5, 0.0, dir * 2.0, 0.4)
			fx.light(from + mn * 1.2 * ka, tf, 0.25, 5.5, Color(1, 0.75, 0.4), 1)
			ti = tf + dist / spd
		"las":
			tf = T0 + 0.05 + i * 0.12
			var spd = 280.0 * fx.unit
			# round 2: a hard, faction-coloured bolt with a white core, long and fat enough to read as a laser at battle zoom
			_muzzle(fx, from, dir, mn, tf, col, ka, MUZ_PX[1] + 2.0, 0, 6.5, 0.16, w, A)
			fx.stk(from, tf, dist / spd, col, 16.0, 5.5 * ka, 0.7 * ka, 4, dir * spd, 0.0, 0.0, 4.6, 30.0)
			ti = tf + dist / spd
		"plasma":
			tf = T0 + 0.12 + i * 0.16
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 0.55 * fx.unit
			var sz = (1.9 if w >= 3 else 1.5) * ka
			_burst(fx, from + dir * 0.6 * ka, dir, tf, sz * 2.4, "flash", 0.22, col, 4.0, 30.0 if w >= 3 else 24.0)
			fx.spr(from, tf, dist / spd, col, 2.0, sz * 1.6, sz * 1.6, 14, dir * spd, 0.0, 0.0, 0.0, 24.0 if w >= 3 else 19.0)
			fx.stk(from, tf, dist / spd, col, 3.0, 4.0 * ka, sz * 0.7, 0, dir * spd)
			# heat shimmer trailing the bolt
			for s in 3:
				fx.spr(from + dir * dist * (0.25 + s * 0.25), tf + dist / spd * (0.25 + s * 0.25), 0.4, col, 0.3, sz * 0.6, sz * 1.4, 18)
			fx.light(from + dir * 2.0, tf, dist / spd, 3.0, col, 1)
			fx.light(from + mn * 1.2 * ka, tf, 0.3, 7.5, col, 0)
			ti = tf + dist / spd
		"scatter":
			tf = T0 + 0.1 + i * 0.1
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 1.2 * fx.unit
			_muzzle_blast(fx, from, dir, tf, Color(1, 0.6, 0.3), ka * 0.7, MUZ_PX[2], w, A)
			fx.light(from + mn * 1.2 * ka, tf, 0.18, 6.5, Color(1, 0.65, 0.35), 0)
			for b in 6:
				var d2 = (dir + fx.rdir() * 0.06).normalized()
				fx.stk(from, tf + fx.rng.randf() * 0.03, dist / spd, Color(1, 0.65, 0.35), 10.0, 3.0 * ka, 0.38 * ka, 0, d2 * spd, 0.0, 0.0, 2.8, 12.0)
			ti = tf + dist / spd
		"prism":
			tf = T0 + 0.08 + i * 0.1
			var spd = 220.0 * fx.unit
			# round 2: a glassy glint at the emitter and three needles, each riding a slow-turning spectral glint
			_muzzle(fx, from, dir, mn, tf, col, ka, MUZ_PX[2], 16, 5.5, 0.25, w, A)
			for b in 3:
				var d2 = (dir + fx.rdir() * 0.02).normalized()
				fx.stk(from, tf + b * 0.03, dist / spd, col.lerp(Color.WHITE, 0.4), 12.0, 3.5 * ka, 0.32 * ka, 4, d2 * spd, 0.0, 0.0, 3.2, 24.0)
				fx.spr(from, tf + b * 0.03, dist / spd, col, 2.2, 0.7 * ka, 0.7 * ka, 16, d2 * spd, 0.0, 0.0, 0.0, 12.0)
			ti = tf + dist / spd
		"needle":
			tf = T0 + 0.1 + i * 0.25
			fx.spr(from, tf - 0.12, 0.12, col, 4.0, 0.3 * ka, 1.6 * ka, 12, Vector3.ZERO, 0.0, 0.0, 0.0, 16.0)
			fx.rib(from, dir, dist, tf, 0.35, col, 1.6, 0.35 * ka, 0.3 * ka, 8)
			fx.light(from + mn * 1.2 * ka, tf, 0.35, 5.0, col, 1)
			ti = tf + 0.03
			tend = tf + 0.35
		"lance", "ion", "pulsar", "doom":
			var charge = float(fx.timing.get("charge", 0.25)) if lk != "doom" else 0.35
			tf = T0 + charge + i * 0.45
			var dur = float(fx.timing.get("lance", 0.7)) if lk != "pulsar" else 0.45
			var wd = (2.4 if lk != "doom" else 1.6) * ka * (1.15 if w >= 3 else 1.0)
			fx.spr(from, tf - charge, charge, col.lerp(Color.WHITE, 0.2), 9.0, 0.6 * ka, 5.0 * ka, 12, Vector3.ZERO, 0.0, 0.0, 0.0, 30.0)
			fx.light(from + dir + mn * ka, tf - charge, charge, 6.0, col, 2)
			if lk == "doom":
				# the arc gathers: little crawling arcs on the emitter before it strikes
				for s in 6:
					fx.rib(from + fx.rdir() * 1.2 * ka, fx.rdir(), 2.5 * ka, tf - charge + s * 0.05, 0.12, col, 1.4, 0.3 * ka, 0.2 * ka, 6)
			var rk: int = {"lance": 2, "ion": 5, "pulsar": 7, "doom": 6}[lk]
			_burst(fx, from, dir, tf, 4.5 * ka, "flash", 0.28, col, 3.6, 22.0)
			fx.rib(from, dir, dist, tf, dur, col, 2.4, wd, wd * 0.85, rk)
			fx.light(from + dir * 1.5 + mn * ka, tf, dur, 6.0, col, 1)
			fx.dst(from + dir * dist * 0.5, tf, dur, dist * 0.3, dist * 0.35, 1, 0.6)
			fx.shake(tf, 0.08, from)
			ti = tf + 0.03
			tend = tf + dur
		"torp", "rockets", "star", "ram":
			if lk == "ram":
				ti = T0
				tend = T0
				# the rammer's own bow folds as well (a smaller crumple, no glow)
				if A != null and hd.size() > 0:
					fx.later(T0, func l_ram_mark() -> void: A.add_mark(fx, "ram_self", 2, A.hull.bow, Vector3(1, 0, 0), Vector3(-1, 0, 0)))
			else:
				var vent = 0.45 + i * (0.35 if lk == "torp" else 0.12)
				tf = T0 + vent
				var spd = (62.0 if lk == "torp" else (85.0 if lk == "rockets" else 55.0)) * fx.unit
				var tt = dist / spd + 0.25
				ti = tf + tt
				_launch(fx, lk, from, mn, to, tf, ti, col, fac, ka, i, bool(hd.get("pd", false)), A)
				tend = ti
		"flak", "pflak", "spores", "mflak", "gflak":
			tf = T0 + 0.03 + i * 0.07
			ti = _flak(fx, lk, from, dir, dist, to, tf, col, ka, kt, i, tg)
			tend = ti + 0.4
		"spine":
			var wind = 0.3
			tf = T0 + wind + i * (0.12 + fx.rng.randf() * 0.05)
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 0.5 * fx.unit
			fx.spr(from, tf - wind, wind, col, 1.4, 0.4 * ka, 1.6 * ka, 22)
			fx.spr(from + dir * 0.5 * ka, tf, 0.25, col, 2.4, 0.8 * ka, 2.0 * ka, 18, Vector3.ZERO, 0.0, 0.0, 0.0, 22.0)
			fx.light(from + mn * 1.2 * ka, tf, 0.3, 4.5, col, 1)
			for s in 5:
				fx.stk(from, tf, 0.4, col, 2.0, 0.08, 0.12 * ka, 6, (dir + fx.rdir() * 0.4).normalized() * 8.0 * ka, 1.5)
			var gsz = 1.5 * ka
			var ft = dist / spd
			fx.spr(from, tf, ft, col, 2.0, gsz, gsz, 15, dir * spd, 0.0, 0.0, 0.0, 15.0)
			# dripping trail
			for s in 8:
				var u = (s + 0.5) / 8.0
				fx.stk(from + dir * dist * u, tf + ft * u, 0.6, col, 1.6, 0.06, 0.1 * ka, 6, Vector3(0, -3, 0) + fx.rdir() * 1.5, 1.0)
			fx.light(from + dir, tf, ft, 1.6, col, 1)
			ti = tf + ft
		"tendril":
			tf = T0 + 0.2 + i * 0.2
			fx.rib(from, dir, dist, tf, 0.9, col, 1.4, 1.2 * ka, 0.5 * ka, 9)
			ti = tf + 0.25
			tend = tf + 0.9
		"gauss":
			var heavy = w >= 3
			var wind = 0.75 if heavy else 0.25
			tf = T0 + wind + i * 0.18
			# capacitor coils light breech to muzzle in steps
			for s in 4:
				fx.spr(from - dir * (1.6 - s * 0.5) * ka, tf - wind + s * wind / 4.0, wind - s * wind / 4.0, col, 2.2, 0.5 * ka, 0.9 * ka, 22)
			fx.light(from, tf - wind, wind, 2.0, col, 2)
			# round 2: the discharge is a hard white muzzle flash and a fat pale shock ring; the slug's wake is a bright
			# instant line (the gauss signature: everything at once, no travelling bolt)
			fx.spr(from, tf, 0.07, Color(0.85, 0.95, 1.0), 12.0, 1.2 * ka, 2.2 * ka, 0, Vector3.ZERO, 0.0, 0.0, 0.0, MUZ_PX[3])
			fx.ring(from + dir * 0.5 * ka, dir, tf, 0.4, Color(0.8, 0.95, 1.0), 1.8, 0.5 * ka, 4.0 * ka, 3, 0.0, 0.0, 44.0 if heavy else 34.0)
			fx.dst(from + dir, tf, 0.3, 1.0 * ka, 6.0 * ka, 0, 1.2)
			fx.stk(from, tf, 0.4, col.lerp(Color.WHITE, 0.5), 4.5, dist, 0.1 * ka, 5, dir, 0.0, 0.0, 3.4 if heavy else 2.8, 0.0)
			fx.ring(from + dir * dist * 0.5, dir, tf + 0.05, 0.45, Color(0.8, 0.9, 1.0), 0.8, 0.5 * ka, 3.0 * ka, 3, 0.0, 0.0, 26.0)
			fx.light(from + mn * 1.2 * ka, tf, 0.18, 7.8, Color(0.85, 0.95, 1.0), 0)
			fx.shake(tf, 0.08, from)
			ti = tf + dist / (650.0 * fx.unit)
		"guns", "bombs", "sporeb":
			ti = _strafe(fx, lk, from, to, T0 + i * 0.15, col, fac, ka, kt, i, faction)
		_:
			ti = T0 + 0.3
	if tend < ti:
		tend = ti
	if not bool(tg.get("miss", false)):
		_impact(fx, lk, w, Tg, tg, ti, col, dir, hd, kt, tend - ti)
	else:
		_miss_fade(fx, lk, tg, ti, col, dir, kt)
	return [ti, tend + 0.3]


# Weapon bursts use leap 1's atlas, flow interpolation, thickness lighting and
# soft intersections. Only the palette and aspect differ from the death recipe.
# Keep one derived shader per FX session, with the same three cached atlas maps.
static func _weapon_shader(fx) -> Shader:
	if not fx.dstate.has("weapon_flipbook_shader"):
		var code: String = SH.DEATH_FLIPBOOK.replace("uniform float intensity = 1.0;",
			"uniform float intensity = 1.0;\nuniform vec3 weapon_tint = vec3(0.9, 0.6, 0.3);\nuniform float opacity = 1.0;\nuniform float aspect = 1.0;\nuniform float spin = 0.0;\nuniform float vent = 0.0;\nuniform float vent_cone = 1.0;\nuniform float hot = 0.0;\nuniform float looping = 0.0;")
		code = code.replace("vec2 up = mix(vec2(0.0, 1.0), axis, directional);",
			"vec2 up = mix(vec2(sin(spin), cos(spin)), axis, directional);")
		code = code.replace("up * VERTEX.y", "up * VERTEX.y * aspect")
		# Issue 281 run 5: the baked muzzle/impact gas plays all 16 frames in order (bright core at birth, then it cools
		# and thins) instead of the death flash's skip-the-first-three-frames ramp.
		code = code.replace("float frame = mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);",
			"float frame = hot > 0.5 ? age * 15.0 : mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);")
		code = code.replace("vec3 core = mix(vec3(0.65, 0.76, 0.93), vec3(0.9, 0.83, 0.68), age);",
			"vec3 core = mix(weapon_tint, vec3(0.9, 0.83, 0.68), age * 0.45);")
		# Issue 281 Cone B: the vent gas cools toward the weapon colour and darkens with age, so the cone reads as hot
		# exhaust instead of a flat pale blob. The flash keeps its own palette (vent is 0 for every other kind).
		code = code.replace("vec3 smoke = mix(vec3(0.12, 0.085, 0.18), vec3(0.42, 0.36, 0.50), lit);",
			"vec3 smoke = mix(vec3(0.12, 0.085, 0.18), vec3(0.42, 0.36, 0.50), lit);\n\tif (vent > 0.5 && vent_cone > 0.5) {\n\t\tvec3 tinted = smoke * clamp(0.35 + 1.25 * weapon_tint, 0.0, 1.10);\n\t\tsmoke = mix(smoke, tinted, 0.65) * mix(0.85, 0.50, age);\n\t}")
		code = code.replace("ALPHA = gas.a * fade * soft", "ALPHA = gas.a * fade * soft * opacity * mix(1.0, 0.55, fx_calm)")
		# The atlas_rect above already frames the gas inside the baked cell. An extra UV crop (0.36 x 0.48) sampled only
		# the gas CORE, so every muzzle and impact burst lost its soft edge and drew as a pale translucent square (#232).
		# Sample the whole framed cell instead and grow the quad by the same 1/0.46, so the gas keeps the on-screen size
		# the F3 pixel floor was tuned for.
		code = code.replace("float size = max(extent, px_world(min_pixels, -view_c.z, PROJECTION_MATRIX));",
			"float size = max(extent, px_world(min_pixels, -view_c.z, PROJECTION_MATRIX)) * 1.45;")
		code = code.replace("float age = clamp(elapsed / max(lifetime, 0.001), 0.0, 1.0);",
			"float age = looping > 0.5 ? 0.15 + 0.55 * (0.5 + 0.5 * sin(elapsed * 9.0 * mix(1.0, 0.35, fx_calm) + spin)) : clamp(elapsed / max(lifetime, 0.001), 0.0, 1.0);")
		code = code.replace("float fade = 1.0 - smoothstep(0.70, 1.0, age);", "float fade = mix(1.0 - smoothstep(0.70, 1.0, age), pow(clamp(UV.y, 0.0, 1.0), 0.7), looping);")
		code = code.replace("(elapsed < lifetime ? 1.0 : 0.0)", "(elapsed < lifetime || looping > 0.5 ? 1.0 : 0.0)")

		fx.dstate["weapon_flipbook_shader"] = fx.mat(code, 2, "#define COMPAT\n" if fx.compat else "").shader
	return fx.dstate["weapon_flipbook_shader"]


static func _burst(fx, p: Vector3, axis: Vector3, T: float, size: float, kind: String, life: float, col: Color,
		strength := 3.0, px := 0.0, velocity := Vector3.ZERO, opacity := 1.0, aspect := 1.0) -> void:
	var power: float = strength
	var duration: float = life
	if kind == "flash" and strength >= fx.FLASH_I:
		if fx.reduce_flashing or (fx._flash_sized(p, size, px) and not fx.flash_ok(T)):
			power = 1.25
			duration = maxf(life, 0.4)
	var seed: float = fx.rng.randf()
	fx.later(T, func l_burst() -> void:
		var node := DEATH.flipbook(fx, p, axis, size * fx.unit, kind, duration, velocity, power, "small") as MeshInstance3D
		node.name = "fx_weapon_" + kind
		# The vent helper offsets its atlas to put the tip on the sampled surface.
		var mat: ShaderMaterial = node.material_override
		mat.shader = _weapon_shader(fx)
		mat.set_shader_parameter("born", T)
		mat.set_shader_parameter("weapon_tint", Vector3(col.r, col.g, col.b))
		mat.set_shader_parameter("opacity", opacity)
		mat.set_shader_parameter("aspect", aspect)
		mat.set_shader_parameter("vent", 1.0 if kind == "vent" else 0.0)
		mat.set_shader_parameter("vent_cone", 0.0 if String(fx.vent_look) == "today" else 1.0)
		mat.set_shader_parameter("spin", seed * TAU)
		mat.set_shader_parameter("min_pixels", px)
	)


const WATLAS_DIR := "res://fx/atlases/weapons/"


# Issue 281 run 5: the weapon vent gas is now a baked Mantaflow flipbook (muzzle jet, impact burst), loaded and shaded
# like the ship-death atlases so it reads at the same quality bar instead of a pale puff. The bake renders in the same
# cell layout and channel names as the deaths, so the existing flow interpolation and thickness lighting apply unchanged.
static func _weapon_gas_material(fx, kind: String) -> ShaderMaterial:
	var m: ShaderMaterial = fx.mat(SH.DEATH_FLIPBOOK, 2, "#define COMPAT\n" if fx.compat else "")
	for key in ["color", "flow", "thickness"]:
		var path: String = WATLAS_DIR + kind + "/" + kind + "_" + key + ".png"
		var textures: Dictionary = fx.dstate.get("weapon_atlases", {})
		if not textures.has(path):
			textures[path] = load(path)
		fx.dstate["weapon_atlases"] = textures
		m.set_shader_parameter({"color": "atlas", "flow": "motion", "thickness": "thickness"}[key], textures[path])
	m.shader = _weapon_shader(fx)
	return m


# One baked weapon gas flipbook, drawn as a hot core (plasma path) with the full 16-frame life, weapon-tinted, oriented
# along `axis` when directional. `kind` is "muzzle" (forward cone) or "impact" (surface-normal burst).
static func _weapon_gas(fx, p: Vector3, axis: Vector3, T: float, size: float, kind: String, life: float, col: Color,
		strength := 1.0, velocity := Vector3.ZERO, opacity := 1.0, directional := 1.0, px := 0.0, src = null) -> void:
	var seed: float = fx.rng.randf()
	fx.record_spawn(src, p, true)
	fx.later(T, func l_wgas() -> void:
		var mi := MeshInstance3D.new()
		mi.name = "fx_weapon_" + kind
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		mi.mesh = quad
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = size * 3.0 + velocity.length() * life
		var m := _weapon_gas_material(fx, kind)
		m.set_shader_parameter("born", T)
		m.set_shader_parameter("lifetime", life)
		m.set_shader_parameter("extent", size * fx.unit)
		m.set_shader_parameter("intensity", strength)
		m.set_shader_parameter("plasma", 1.0)
		m.set_shader_parameter("hot", 1.0)
		m.set_shader_parameter("directional", directional)
		m.set_shader_parameter("tear_normal", axis)
		m.set_shader_parameter("velocity", velocity)
		m.set_shader_parameter("min_pixels", px)
		m.set_shader_parameter("weapon_tint", Vector3(col.r, col.g, col.b))
		m.set_shader_parameter("opacity", opacity)
		m.set_shader_parameter("spin", seed * TAU)
		mi.material_override = m
		fx.add_child(mi)
		mi.global_position = p + axis * size * 0.42 * directional
		fx.later(T + life + 0.1, fx.free_effect.bind(weakref(mi)))
	)


# The review capture draws the pre-Cone-B look ("today") for its before stills. The game never sets this.
static func _old_look(fx) -> bool:
	return String(fx.vent_look) == "today"


# Issue 281 Cone B (Ryan's pick, R145): one place for every weapon vent puff (muzzle, hull hit, shield hit, launch), so
# the look reads the same everywhere. The shipped look is a tight forward jet of hot gas and sparks along the barrel,
# so it never reads as a flat pale blob. "today" draws the pre-Cone-B baked gas cell and is only used to shoot the
# review's before stills.
# Run 4 (Ryan, Nov 9): the first cone still left a pale ball four times the old puff. Each step is now about a third of
# today's width at the barrel and thins to nothing down the barrel, with a shorter life and lower opacity, so the muzzle
# keeps a bright forward flash and a few sparks with almost no ball, and a hull hit is a tight jet on the surface normal.
# w is the weapon weight (1 light, 2 medium, 3 heavy), kept so the muzzle callers pass one shape.
static func _vent(fx, p: Vector3, axis: Vector3, T: float, size: float, life: float, col: Color, strength := 0.8,
		velocity := Vector3.ZERO, opacity := 0.55, aspect := 1.0, w := 2, src = null) -> void:
	fx.record_spawn(src, p, true)
	if String(fx.vent_look) == "today":
		_burst(fx, p, axis, T, size, "vent", life, col, strength, 0.0, velocity, opacity, aspect)
		return
	# Cone B: a narrow forward jet, widest at the barrel and thinning to nothing along it.
	var n := 4
	var reach := size * 0.95
	for j in n:
		var u := float(j) / maxf(1.0, float(n - 1))
		var taper := 1.0 - u          # full at the barrel, nothing at the tip
		_burst(fx, p + axis * reach * u, axis, T + u * 0.02, size * (0.06 + 0.27 * taper), "vent",
			life * (0.45 + 0.20 * u), col, strength * (0.80 - 0.25 * u), 0.0, velocity * (1.0 + 0.5 * u),
			opacity * (0.45 - 0.25 * u), 2.0 + u * 2.0)
	_impact_sparks(fx, p, axis, T + 0.02, size * 0.35, col, 10, 18.0)


# Issue 281 run 5: sparks are a few small, soft glowing points with short trails that slow down (drag) and fade, hot
# white to orange to gone. The old flat straight spark lines read as Microsoft paint, so they are gone.
static func _impact_sparks(fx, p: Vector3, axis: Vector3, T: float, k: float, col: Color, count := 10, speed := 14.0) -> void:
	if fx.quality == "low": return
	var amount: int = count if fx.quality == "max" else maxi(3, count / 2)
	for j in amount:
		var v: Vector3 = fx.rcone(axis, 0.8) * fx.rng.randf_range(speed * 0.35, speed) * k * fx.unit
		var drag: float = fx.rng.randf_range(2.0, 5.0)
		var life: float = fx.rng.randf_range(0.25, 0.60)
		var t: float = T + fx.rng.randf() * 0.035
		# a soft glowing point that cools white to the weapon colour as it slows (additive, no line)
		fx.spr(p, t, life, col, 2.0, 0.07 * k, 0.035 * k, 19, v, drag)
		# a short soft trail behind it, shrinking as it slows so it never reads as a straight ruler line
		fx.stk(p, t, life * 0.7, col, 1.8, 0.14 * k, 0.03 * k, 1, v, drag, 0.0, 0.0, 3.0)


# ---------------------------------------------------------------- fire

# A small baked muzzle burst and a short light identify the firing ship.
# The pixel floor keeps it readable at battle distance; close flashes use the budget.
static func _muzzle(fx, p: Vector3, dir: Vector3, mn: Vector3, t: float, col: Color, k: float, px: float, kind := 0, lpk := 6.0, llife := 0.2, w := 2, src = null) -> void:
	_burst(fx, p + dir * 0.5 * k, dir, t, 2.6 * k, "flash", 0.18, col, 4.5, px)
	_vent(fx, p + dir * k, dir, t + 0.035, 2.2 * k, 0.28, col, 0.7, dir * 3.0 * k, 0.45, 1.0, w, src)
	fx.light(p + mn * 1.2 * k + dir * 0.6 * k, t, llife, lpk, col.lerp(Color(0.94, 0.87, 0.73), 0.3), 0)


static func _muzzle_blast(fx, p: Vector3, dir: Vector3, t: float, col: Color, k: float, px := 24.0, w := 2, src = null) -> void:
	# Run 5: a compact hot core at the muzzle plus the baked muzzle jet (a forward cone that cools and thins). The shell
	# tracer carries the bright streak, so the flash only lights the barrel mouth and stays inside the gun mount.
	var core := 4.0 if _old_look(fx) else 1.8
	var core_life := 0.20
	var core_at := 0.6 if _old_look(fx) else 0.5
	var core_power := 5.0 if _old_look(fx) else 5.5
	_burst(fx, p + dir * core_at * k, dir, t, core * k, "flash", core_life, Color(0.94, 0.72, 0.42), core_power, px)
	if _old_look(fx):
		_vent(fx, p + dir * k, dir, t + 0.025, 3.6 * k, 0.35, col, 0.8, dir * 4.0 * k, 0.55, 1.0, w, src)
	else:
		_weapon_gas(fx, p + dir * 0.4 * k, dir, t + 0.02, 1.9 * k * WEAPON_GAS_SCALE, "muzzle", 0.30, col, 1.5, dir * 4.0 * k, 0.8, 1.0, 0.0, src)
	_impact_sparks(fx, p, dir, t, k, Color(0.91, 0.57, 0.27), 4, 9.0)


static func _launch(fx, lk: String, from: Vector3, mn: Vector3, to: Vector3, tf: float, ti: float, col: Color, fac: Dictionary, k: float, i: int, intercept: bool, src = null) -> void:
	var eng: Color = fac["engine"]
	_vent(fx, from + mn * 0.6 * k, mn, tf, 3.2 * k, 0.35, eng, 0.8, mn * 4.0 * k, 0.7, 1.0, 2, src)
	var n: int = 4 if lk == "rockets" else 1
	for j in n:
		var t0 = tf + j * 0.07
		var side = mn * (6.0 + fx.rng.randf() * 4.0) * k + fx.rdir() * (3.0 if lk == "rockets" else 1.0) * k
		var mid = from.lerp(to, 0.45) + side + Vector3(0, (3.0 + fx.rng.randf() * 3.0) * k, 0)
		var end = to + (fx.rdir() * 0.6 * k if lk == "rockets" else Vector3.ZERO)
		var p = {"lk": lk, "t0": t0, "t1": ti + j * 0.03, "a": from, "b": mid, "c": end, "col": col, "eng": eng, "k": k,
			"seed": fx.rng.randf(), "last": t0, "mesh": _projectile_body(fx, lk, k, eng), "dead_at": INF}
		if intercept and j == 0: p["dead_at"] = lerpf(t0, ti, 0.62)
		var list: Array = fx.dstate.get("proj", [])
		list.append(p)
		fx.dstate["proj"] = list


# Compact, lit casings with a closed nose, a recessed motor and rear fins.
# The casing has no emission: the drive is bright, the body remains readable.
const DRIVE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
global uniform float scene_t;
global uniform float fx_gain;
global uniform float fx_calm;
uniform vec3 tint = vec3(0.95, 0.55, 0.2);
uniform float extent = 1.0;
uniform float seed = 0.0;
void vertex() {
	vec3 centre = (VIEW_MATRIX * MODEL_MATRIX[3]).xyz;
	float size = extent * length(MODEL_MATRIX[0].xyz);
	POSITION = PROJECTION_MATRIX * vec4(centre + vec3(VERTEX.xy * size, 0.0), 1.0);
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float pulse = 0.86 + (0.10 * sin(scene_t * 23.0 + seed) + 0.04 * sin(scene_t * 37.0 + seed)) * (1.0 - fx_calm);
	float core = exp(-r * r * 26.0);
	float halo = exp(-r * r * 5.0) * (1.0 - smoothstep(0.65, 1.0, r));
	ALBEDO = (mix(tint, vec3(0.94, 0.87, 0.72), 0.75) * core * 5.0 + tint * halo * 1.4) * pulse * fx_gain;
}
"""

const STAR_BODY := """
shader_type spatial;
render_mode unshaded;
global uniform float scene_t;
global uniform float fx_gain;
void fragment() {
	float lobes = 0.7 + 0.15 * sin(UV.x * 18.0 + scene_t * 2.0) * sin(UV.y * 12.0 - scene_t * 3.0);
	float face = smoothstep(0.0, 0.9, max(dot(NORMAL, VIEW), 0.0));
	ALBEDO = mix(vec3(0.95, 0.48, 0.16), vec3(0.88, 0.92, 0.95), face * lobes) * 2.2 * fx_gain;
}
"""

static func _casing(fx, rocket: bool) -> ArrayMesh:
	var key := "weapon_rocket_casing" if rocket else "weapon_torp_casing"
	if fx.dstate.has(key): return fx.dstate[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile := [[-1.15, 0.12], [-1.02, 0.24], [-0.75, 0.29], [0.38, 0.29], [0.70, 0.21], [1.12, 0.025], [1.15, 0.0]]
	var segments := 8
	for j in profile.size() - 1:
		for i in segments:
			var a := TAU * i / segments
			var b := TAU * (i + 1) / segments
			var x: float = profile[j][0]; var r: float = profile[j][1]
			var y: float = profile[j+1][0]; var t: float = profile[j+1][1]
			var panel := Color(0.19, 0.16, 0.15) if rocket else Color(0.14, 0.13, 0.12)
			if j == 0: panel = Color(0.08, 0.065, 0.10)
			elif j == 2 and i % 3 == 0: panel = Color(0.30, 0.19, 0.13) if rocket else Color(0.34, 0.29, 0.21)
			st.set_color(panel)
			for v in [Vector3(x,cos(a)*r,sin(a)*r),Vector3(y,cos(b)*t,sin(b)*t),Vector3(y,cos(a)*t,sin(a)*t),
				Vector3(x,cos(a)*r,sin(a)*r),Vector3(x,cos(b)*r,sin(b)*r),Vector3(y,cos(b)*t,sin(b)*t)]: st.add_vertex(v)
	for i in 4:
		var radial := Vector3(0, cos(i * PI / 2), sin(i * PI / 2))
		st.set_color(Color(0.20, 0.17, 0.16) if rocket else Color(0.40, 0.36, 0.29))
		for v in [Vector3(-0.95,0,0)+radial*0.23, Vector3(-0.90,0,0)+radial*0.63, Vector3(-0.20,0,0)+radial*0.23]:
			st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.metallic = 0.45; mat.roughness = 0.72
	mesh.surface_set_material(0, mat)
	fx.dstate[key] = mesh
	return mesh


static func _projectile_body(fx, lk: String, k: float, eng: Color) -> Node3D:
	var node := Node3D.new()
	node.name = "fx_projectile_" + lk
	var body := MeshInstance3D.new()
	if lk == "star":
		var sphere := SphereMesh.new()
		sphere.radius = 0.65; sphere.height = 1.3; sphere.radial_segments = 16; sphere.rings = 8
		body.mesh = sphere
		body.material_override = fx.mat(STAR_BODY)
	else:
		body.mesh = _casing(fx, lk == "rockets")
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(body)
	var drive := MeshInstance3D.new()
	var quad := QuadMesh.new(); quad.size = Vector2.ONE
	drive.mesh = quad
	drive.position.x = -1.14 if lk != "star" else -0.2
	var mat: ShaderMaterial = fx.mat(DRIVE, 1)
	mat.set_shader_parameter("tint", Vector3(eng.r, eng.g, eng.b))
	mat.set_shader_parameter("extent", 2.5 if lk == "star" else 1.8)
	mat.set_shader_parameter("seed", fx.rng.randf() * TAU)
	drive.material_override = mat
	drive.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drive.extra_cull_margin = 3.0
	node.add_child(drive)
	var plume := MeshInstance3D.new()
	plume.name = "exhaust"
	plume.mesh = quad
	plume.position.x = -2.0
	var exhaust: ShaderMaterial = DEATH.flipbook_material(fx,"vent","small")
	exhaust.shader = _weapon_shader(fx)
	exhaust.set_shader_parameter("born",fx.now)
	exhaust.set_shader_parameter("looping",1.0)
	exhaust.set_shader_parameter("vent",1.0)
	exhaust.set_shader_parameter("extent",2.4*k*fx.unit*(0.55 if lk=="rockets" else 1.0))
	exhaust.set_shader_parameter("aspect",3.0)
	exhaust.set_shader_parameter("directional",1.0)
	exhaust.set_shader_parameter("min_pixels",0.0)
	exhaust.set_shader_parameter("intensity",2.0)
	exhaust.set_shader_parameter("plasma",0.8)
	exhaust.set_shader_parameter("opacity",0.75)
	exhaust.set_shader_parameter("spin",fx.rng.randf()*TAU)
	exhaust.set_shader_parameter("weapon_tint",Vector3(eng.r,eng.g,eng.b))
	plume.material_override = exhaust
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.extra_cull_margin = 10.0
	node.add_child(plume)
	node.set_meta("exhaust",exhaust)
	node.scale = Vector3.ONE * k * fx.unit * (0.55 if lk == "rockets" else 1.0)
	node.visible = false
	fx.add_child(node)
	return node


static func _bez(a: Vector3, b: Vector3, c: Vector3, u: float) -> Vector3:
	return a.lerp(b, u).lerp(b.lerp(c, u), u)


static func update(fx, dt: float) -> void:
	_lanes_update(fx)
	_craft_update(fx, dt)
	var list: Array = fx.dstate.get("proj", [])
	var keep: Array = []
	for p in list:
		var t0: float = p["t0"]
		var t1: float = p["t1"]
		var now: float = fx.now
		if now < t0:
			keep.append(p)
			continue
		var parked: bool = p.get("park", false) and now >= t1
		if (now >= t1 and not parked) or now >= float(p["dead_at"]):
			if now >= float(p["dead_at"]) and float(p["dead_at"]) < t1:
				var u0 := clampf((float(p["dead_at"]) - t0) / maxf(t1-t0, 0.001), 0.0, 1.0)
				var pp := _bez(p["a"], p["b"], p["c"], _ease(u0))
				_burst(fx, pp, Vector3.UP, now, 4.0 * float(p["k"]), "flash", 0.24, p["col"], 3.2, 24.0)
				_impact_sparks(fx, pp, ((p["c"] as Vector3)-(p["a"] as Vector3)).normalized(), now, p["k"], Color(0.9,0.62,0.32), 6)
			if is_instance_valid(p["mesh"]): (p["mesh"] as Node).queue_free()
			continue
		keep.append(p)
		var u := clampf((now-t0) / maxf(t1-t0, 0.001), 0.0, 1.0)
		var e := _ease(u)
		var pos := _bez(p["a"],p["b"],p["c"],e)
		var d: Vector3 = ((p["b"] as Vector3)-(p["a"] as Vector3)).lerp((p["c"] as Vector3)-(p["b"] as Vector3),e).normalized()
		if d.length_squared() < 0.01: d = Vector3.RIGHT
		p["pos"] = pos
		if is_instance_valid(p["mesh"]):
			var node: Node3D = p["mesh"]
			var z := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD).normalized()
			var scale: Vector3 = node.scale
			node.global_transform = Transform3D(Basis(d, z.cross(d).normalized(), z).scaled(scale), pos)
			node.visible = true
			(node.get_meta("exhaust") as ShaderMaterial).set_shader_parameter("tear_normal",-d)
		_projectile_exhaust(fx, p, d)
	fx.dstate["proj"] = keep
# Sample the actual curved path at fixed intervals. Cap catch-up after a hitch,
# and let each short puff cool independently. There is no persistent hot ribbon.
static func _projectile_exhaust(fx, p: Dictionary, dir: Vector3) -> void:
	var lk: String = p["lk"]
	var k: float = p["k"]
	var last: float = p["last"]
	var rate := 10.0 if lk == "rockets" else 14.0
	if fx.quality == "low": rate *= 0.6
	var count := mini(3, int((fx.now-last) * rate))
	if count <= 0: return
	p["last"] = fx.now
	var eng: Color = p["eng"]
	for i in count:
		var tt: float = fx.now - float(count-i-1)/rate
		var e := _ease(clampf((tt-float(p["t0"])) / maxf(float(p["t1"])-float(p["t0"]),0.001),0.0,1.0))
		var at := _bez(p["a"],p["b"],p["c"],e)
		var d: Vector3 = ((p["b"] as Vector3)-(p["a"] as Vector3)).lerp((p["c"] as Vector3)-(p["b"] as Vector3),e).normalized()
		if d.length_squared() < 0.01: d = dir
		var size: float = k * (0.65 if lk == "rockets" else 1.0)
		var tail: Vector3 = at - d * size * 1.2 * fx.unit
		_burst(fx, tail-d*size, -d, tt+0.04, 1.7 * size, "cool", 0.30 if lk == "rockets" else 0.22,
			eng, 0.5, 0.0, -d*size*2.0, 0.30 if lk == "rockets" else 0.12)
		if fx.quality == "max":
			for j in 3:
				var f := float(j) / 3.0
				fx.dst(tail-d*size*(0.5+f*4.0), tt, 0.16, size*(0.4+f*0.5), size*(1.1+f), 1, 0.12*(1.0-f)*(1.0-f))


static func _ease(u: float) -> float:
	# boost phase: slow off the rail, then the motor takes over
	return u * u * (1.6 - 0.6 * u) if u < 1.0 else 1.0


# Flak: proximity-fused shells bursting around the target; returns the last burst time.
static func _flak(fx, lk: String, from: Vector3, dir: Vector3, dist: float, to: Vector3, tf: float, col: Color, ka: float, kt: float, i: int, tg: Dictionary) -> float:
	var spd = 220.0 * fx.unit
	var last = tf
	var nb = 4
	for b in nb:
		var tb = tf + b * 0.06
		var off = fx.rdir() * (2.0 + fx.rng.randf() * 3.0) * kt
		var bp = to + off - dir * (1.0 + fx.rng.randf() * 2.0) * kt
		var ft = from.distance_to(bp) / spd
		var c2 = col
		match lk:
			"pflak":
				fx.stk(from, tb, ft, col.lerp(Color.WHITE, 0.4), 9.0, 3.5 * ka, 0.32 * ka, 4, (bp - from).normalized() * spd, 0.0, 0.0, 3.2, 18.0)
			"gflak":
				fx.stk(from, tb, 0.15, col.lerp(Color.WHITE, 0.3), 2.0, from.distance_to(bp), 0.06 * ka, 5, (bp - from).normalized())
				ft = 0.02
			"spores":
				ft *= 2.2
				fx.spr(from, tb, ft, col, 1.4, 0.7 * ka, 0.7 * ka, 15, (bp - from) / ft)
			_:
				_burst(fx,from+dir*0.4*ka,dir,tb,1.8*ka,"flash",0.14,Color(0.94,0.74,0.42),3.4,12.0)
				fx.stk(from, tb, ft, Color(1, 0.8, 0.5), 8.0, 3.0 * ka, 0.32 * ka, 0, (bp - from).normalized() * spd, 0.0, 0.0, 3.0, 16.0)
		var t_b = tb + ft
		last = maxf(last, t_b)
		var tint: Color = col if lk != "flak" else Color(0.94, 0.69, 0.37)
		_burst(fx,bp,-dir,t_b,3.2*kt,"flash",0.28,tint,1.4 if lk=="spores" else 3.4,22.0)
		_burst(fx,bp,-dir,t_b+0.04,3.6*kt,"cool",0.55,tint,0.65,0.0,-dir*1.5*kt,0.5)
		_impact_sparks(fx,bp,-dir,t_b,kt,tint,4 if lk in ["spores","mflak"] else 7,10.0)

	return last


# Strike craft: a loose formation flies a strafing run past the target, firing as it goes.
static func _strafe(fx, lk: String, from: Vector3, to: Vector3, t0: float, col: Color, fac: Dictionary, ka: float, kt: float, i: int, faction := "voidsworn") -> float:
	var d = (to - from)
	var dist = maxf(d.length(), 1.0)
	var dir = d / dist
	var side = dir.cross(Vector3.UP).normalized()
	var spd = 140.0 * fx.unit
	var eng: Color = fac["engine"]
	var start = from - dir * 3.0 + side * (i - 1) * 2.0 + Vector3(0, 3.0, 0)
	var end = to + dir * 25.0 + side * (i - 1) * 4.0 + Vector3(0, 6.0, 0)
	var life = start.distance_to(end) / spd
	var vel = (end - start) / life
	var timp = t0 + (to.distance_to(start) - 6.0) / spd
	for c in 3:
		var off = side * (c - 1) * 1.2 + Vector3(0, (c % 2) * 0.6, 0)
		var kind := "spore" if faction == "chorus" or lk == "sporeb" else ("bomber" if lk == "bombs" else "fighter")
		_craft_run(fx, faction, kind, start + off, end + off, t0 + c * 0.04, life, 2.4)
		# craft fire: miniature tracers, bombs or spore sacs
		for s in 3:
			var tsh = timp - 0.35 + s * 0.08 + c * 0.03
			var ps = start + off + vel * (tsh - t0 - c * 0.04)
			var dd = (to - ps).normalized()
			match lk:
				"bombs":
					if s == 0:
						fx.spr(ps, tsh, (to - ps).length() / 50.0, Color(0.15, 0.14, 0.13), 1.0, 0.5, 0.5, 23, dd * 50.0)
				"sporeb":
					if s == 0:
						fx.spr(ps, tsh, (to - ps).length() / 45.0, col, 1.4, 0.7, 0.7, 15, dd * 45.0)
				_:
					fx.stk(ps, tsh, (to - ps).length() / 260.0, col.lerp(Color.WHITE, 0.3), 10.0, 3.5, 0.35, 0, dd * 260.0)
	return timp + (0.3 if lk == "bombs" else 0.1)


# Launch and attack passes use the same faction geometry as the parked wing.
# fx.now owns these runs, including accelerated playback and deterministic probes.
static func _craft_run(fx, faction: String, kind: String, from: Vector3, to: Vector3, t0: float, life: float, size: float) -> void:
	var node := WING.new()
	node.name = "fx_strike_craft"
	fx.add_child(node)
	node.setup(faction, kind, size, 1, t0 * 3.0)
	node.set_process(false)
	node.visible = false
	var runs: Array = fx.dstate.get("craft_runs", [])
	runs.append({"node": node, "a": from, "b": to, "t0": t0, "life": maxf(life, 0.05)})
	fx.dstate["craft_runs"] = runs

static func _craft_update(fx, dt: float) -> void:
	var runs: Array = fx.dstate.get("craft_runs", [])
	for i in range(runs.size() - 1, -1, -1):
		var r: Dictionary = runs[i]
		var age: float = fx.now - float(r.t0)
		var node: Node3D = r.node
		if age > float(r.life) + 0.65:
			node.queue_free()
			runs.remove_at(i)
			continue
		if age < 0.0: continue
		var progress := clampf(age / float(r.life), 0.0, 1.0)
		var dir: Vector3 = (r.b - r.a).normalized()
		node.visible = true
		node.active = age < float(r.life)
		for c in node.craft: c.visible = node.active
		node.position = (r.a as Vector3).lerp(r.b, progress)
		node.rotation.y = atan2(-dir.z, dir.x)
		node.step(dt)


# ---------------------------------------------------------------- impacts

static func _impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, hd: Dictionary, k: float, sustain: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var crit = bool(hd.get("crit", false))
	var torp = lk in ["torp", "rockets", "star", "ram"]
	var beam = lk in ["lance", "ion", "pulsar", "doom", "needle"]
	var bio = lk in ["spine", "tendril", "sporeb", "spores"]
	var light = lk in ["auto", "las", "scatter", "guns", "flak", "pflak", "mflak", "gflak", "prism"]
	# the target's physical reaction, by the weapon's momentum and its weight (a shield takes most of the shove)
	if Tg != null:
		var imp: float = float(REACT_IMPULSE.get(lk, 0.5)) * [0.7, 0.85, 1.0, 1.3, 1.6][clampi(w, 0, 4)] * (1.6 if crit else 1.0)
		if bool(tg.get("shield", false)):
			imp *= 0.35
		var lhp: Vector3 = tg["lp"] if tg.has("lp") else Tg.xf().affine_inverse() * p
		var ldr: Vector3 = (Tg.xf().basis.inverse() * dir).normalized()
		fx.later(T, func l_hit_react() -> void: Tg.hit_react(fx, imp, lhp, ldr))
	if bool(tg.get("shield", false)):
		_shield_impact(fx, lk, w, Tg, tg, T, dir, k, sustain, torp, beam, bio, light)
		return
	if tg.has("through") and Tg != null:
		var th: Dictionary = tg["through"]
		Tg.shield_hit(fx, th["local"], T - 0.02, 0.5, 8.0 * k, 0.4)
	# every weapon leaves its own mark in the hull itself (R43; fx_breach.marks_for): burn-throughs, craters, punctures,
	# blast holes, pockmarks, acid pits, electrical burns
	if Tg != null and tg.has("lp"):
		var ld: Vector3 = (Tg.xf().basis.inverse() * dir).normalized()
		var lp0: Vector3 = tg["lp"]
		var ln0: Vector3 = tg["ln"]
		var wound_look: String = tg.get("mark_look", lk)
		fx.later(T, func l_mark() -> void: Tg.add_mark(fx, wound_look, w, lp0, ln0, ld))
	# Material changes the ejecta; the incoming weapon still owns its burst shape.
	var substance: String = Tg.faction if Tg != null else "metal"
	if beam:
		_beam_burn(fx, lk, Tg, tg, T, sustain, col, k, w)
	elif bio:
		_bio_splat(fx, Tg, tg, T, col, k, lk == "tendril", w)
	elif lk == "gauss":
		_gauss_punch(fx, Tg, tg, T, dir, col, k, w)
	elif torp:
		_big_hit(fx, Tg, tg, T, k * (1.5 if lk == "ram" else (0.65 if lk == "rockets" else 1.0)), col, lk == "star")
	else:
		# Run 5: a tight hot core on the plate plus the baked impact burst along the surface normal. The gas jet and
		# sparks carry the impact, so the flash must stay inside the hit area instead of blooming into a smoke cloud.
		var old := _old_look(fx)
		var size := ((3.8 if light else (5.6 if w <= 2 else 7.0)) if old else
			(1.4 if light else (1.6 if w <= 2 else 1.8))) * k
		var tint: Color = col if lk in ["las", "prism", "plasma", "pflak", "mflak", "gflak"] else Color(0.94, 0.67, 0.33)
		_burst(fx, p+n*0.35*k, n, T, size, "flash", 0.24 if light else 0.32,
			tint, 4.2 if old else 3.6, HIT_PX[clampi(w,1,3)])
		# The gas keeps the old call size so the before stills match; the baked impact is a tight normal burst.
		var gas_size := (3.8 if light else (5.6 if w <= 2 else 7.0)) * k
		if old:
			_vent(fx, p+n*0.5*k, n, T+0.025, gas_size*0.85, 0.38, tint, 0.9, n*4.0*k, 0.55, 1.0, w, Tg)
		else:
			_weapon_gas(fx, p+n*0.4*k, n, T+0.025, size * 1.4 * WEAPON_GAS_SCALE, "impact", 0.34, tint, 1.6, n*3.0*k, 0.8, 0.0, 0.0, Tg)
		var ejecta := tint if substance == "ithar" else Color(0.91,0.56,0.25)
		if substance == "chorus": ejecta = Tg.fac.damage_glow
		_impact_sparks(fx,p+n*0.15*k,(n-dir*0.25).normalized(),T,k,ejecta,7 if light else 12)
		_afterglow(fx,p+n*0.25*k,T,tint,size*0.45,light)
		if not light and substance not in ["chorus","ithar"]:
			for j in 3:
				fx.shd(p,T,1.4,fx.rcone(n,0.6)*fx.rng.randf_range(3.0,7.0)*k,0.16*k,0.55,3.0,0.0)
		fx.light(p+n*2.0*k,T,0.22,5.0 if light else HULL_LIGHT,tint,0)
		fx.shake(T,0.04 if light else 0.08,p)
	if crit: _crit(fx,Tg,tg,T+0.12,k,w)


# A short cooling atlas over the contact point and a dim hot spot on the plate.
static func _afterglow(fx, p: Vector3, T: float, col: Color, sz: float, light: bool, px := 0.0) -> void:
	_burst(fx,p,Vector3.UP,T+0.08,sz*1.3,"cool",0.50 if light else 0.70,col,0.65,0.0,Vector3.ZERO,0.45)
	fx.spr(p,T,0.7 if light else 1.0,col,1.0,sz*0.18,sz*0.13,21)


static func _shield_impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, dir: Vector3, k: float, sustain: float, torp: bool, beam: bool, bio: bool, light: bool) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var sc: Color = Tg.fac["shield"] if Tg != null else Color(0.4, 0.7, 1.0)
	var strength = 0.6 if light else (1.0 if w <= 2 else 1.4)
	var spread = (9.0 if light else 14.0) * k
	var life = float(fx.timing.get("shield", 0.6))
	if torp:
		strength = 2.2
		spread = 26.0 * k
		life = 1.1
	elif beam:
		life = maxf(sustain, 0.3) + 0.5
		spread = 16.0 * k
	elif lk == "gauss":
		strength = 1.6
		spread = 7.0 * k
		life = 0.45
	elif lk in ["flak", "pflak", "gflak", "mflak", "spores", "guns"]:
		strength = 0.35
		spread = 4.0 * k
		life = 0.3
	strength *= 1.3
	if Tg != null:
		Tg.shield_hit(fx, tg["local"], T, strength, spread, life)
		if beam and sustain > 0.3:
			# slow rings while the beam holds (one per 0.35 s), not counted flashes
			var t = T + 0.35
			while t < T + sustain:
				Tg.shield_hit(fx, tg["local"], t, 0.6, spread * 0.8, 0.6)
				t += 0.35
	# F3 round 2: the bubble flashes in its faction's colour where it was struck: a ripple ring racing out along the
	# bubble's surface and a soft coloured glow, each with its own size on screen, so a shield hit reads from the
	# battle camera as that ship's shield
	var spx: float = 36.0 if light else (46.0 if w <= 2 else 56.0)
	if torp:
		spx = 64.0
	_burst(fx,p+n*0.25*k,n,T,(3.2 if light else (9.0 if torp else 5.0))*k,"flash",0.30,sc,3.2,spx)
	fx.ring(p,n,T,0.55 if not torp else 0.8,sc,1.4,0.5*k,(5.0 if not torp else 12.0)*k,2,0.0,0.0,spx*1.3)
	_impact_sparks(fx,p,n,T,k,sc,6 if light else (16 if torp else 10),12.0)
	if beam:
		for j in int(sustain/0.25):
			_burst(fx,p+n*0.25*k,n,T+0.2+j*0.25,4.5*k,"flash",0.25,sc,2.4,32.0)
	if torp:
		_vent(fx,p+n*k,n,T+0.04,9.0*k,0.45,sc,1.0,n*5.0*k,0.65,1.0,w,Tg)
		fx.dst(p,T,0.4,2.0*k,14.0*k,0,0.5)
		fx.shake(T,0.35,p); fx.hit_pause(T,3)
	fx.light(p+n*2.0*k,T,0.3 if not beam else sustain+0.2,HULL_LIGHT,sc,0 if not beam else 1)



static func _beam_burn(fx, lk: String, Tg, tg: Dictionary, T: float, sustain: float, col: Color, k: float, w := 3) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var dur := maxf(sustain,0.25)
	var steps := maxi(1,int(ceil(dur/0.22)))
	for j in steps:
		var at := T+float(j)*dur/steps
		_burst(fx,p+n*0.35*k,n,at,5.0*k,"flash",0.25,col,3.4,34.0)
		_impact_sparks(fx,p,n,at,k,col.lerp(Color(0.94,0.65,0.32),0.45),5,12.0)
	_vent(fx,p+n*0.5*k,n,T+0.1,5.0*k,dur+0.25,col,0.8,n*3.0*k,0.55,1.0,w,Tg)
	_afterglow(fx,p+n*0.2*k,T+dur*0.5,col,2.2*k,false)
	if lk == "doom":
		for j in 3: fx.rib(p,fx.rcone(n,0.8),2.5*k,T+j*0.12,0.1,col,1.0,0.15*k,0.05*k,6)
	fx.light(p+n*2.0*k,T,dur+0.15,6.5,col,1)
	fx.shake(T,0.1,p)


static func _bio_splat(fx, Tg, tg: Dictionary, T: float, col: Color, k: float, lash: bool, w := 2) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	# A dim pressure burst and drifting bile droplets, without a metal fireball.
	_burst(fx,p+n*0.3*k,n,T,4.5*k,"flash",0.35,col,1.4,28.0)
	_vent(fx,p+n*0.4*k,n,T,5.0*k,0.65,col,0.8,n*3.0*k,0.65,1.0,w,Tg)
	for j in 6:
		var v: Vector3 = fx.rcone(n,0.9)*fx.rng.randf_range(3.0,7.0)*k
		fx.spr(p,T+j*0.015,0.55,col,1.2,0.25*k,0.14*k,15,v,0.0)
	_burst(fx,p+n*k,n,T+0.12,4.5*k,"cool",0.8,col,0.5,0.0,n*k,0.45)
	fx.light(p+n*2.0*k,T,0.55,3.0,col,1)
	fx.shake(T,0.1 if lash else 0.05,p)


static func _gauss_punch(fx, Tg, tg: Dictionary, T: float, dir: Vector3, col: Color, k: float, w: int) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var tint := Color(0.78,0.86,0.94)
	_burst(fx,p+n*0.35*k,n,T,4.5*k,"flash",0.22,tint,4.5,38.0)
	_impact_sparks(fx,p,n,T,k,Color(0.93,0.66,0.35),12,20.0)
	if Tg != null:
		var inv: Transform3D = Tg.xf().affine_inverse()
		var lp: Vector3 = inv*p
		var ld: Vector3 = (inv.basis*dir).normalized()
		var far: Dictionary = Tg.hull.ray(lp+ld*(Tg.hull.L+Tg.hull.W)*2.0,-ld)
		if not far.is_empty():
			var xp: Vector3 = Tg.to_world(far["p"]); var xn: Vector3 = Tg.dir_world(far["n"])
			_vent(fx,xp+xn*0.3*k,xn,T+0.04,5.5*k,0.42,tint,1.2,dir*6.0*k,0.7,1.0,w,Tg)
			_impact_sparks(fx,xp,(dir+xn).normalized(),T+0.04,k,Color(0.93,0.64,0.3),10,22.0)
			for j in 3: fx.shd(xp,T+0.04,1.8,fx.rcone(dir,0.4)*10.0*k,0.2*k,0.6,3.0,0.0)
	_afterglow(fx,p+n*0.2*k,T,tint,2.2*k,false)
	fx.light(p+n*2.0*k,T,0.22,HULL_LIGHT,tint,0)
	fx.shake(T,0.2 if w>=3 else 0.12,p)
	if w>=3: fx.hit_pause(T,3)


static func _big_hit(fx, Tg, tg: Dictionary, T: float, k: float, col: Color, star: bool) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var tint: Color = Color(0.88,0.90,0.94) if star else Color(0.94,0.62,0.25)
	_burst(fx,p+n*k,n,T,12.0*k,"flash",0.32,tint,5.2,60.0)
	if _old_look(fx):
		_vent(fx,p+n*k,n,T+0.04,10.0*k,0.55,tint,1.1,n*7.0*k,0.8,1.0,3,Tg)
	else:
		_weapon_gas(fx,p+n*0.5*k,n,T+0.04,4.6*k*WEAPON_GAS_SCALE,"impact",0.42,tint,2.0,n*5.0*k,0.85,0.0,0.0,Tg)
	_burst(fx,p+n*1.5*k,n,T+0.20,12.0*k,"cool",0.8,tint,0.75,0.0,n*3.0*k,0.5)
	var organic: bool = Tg != null and Tg.faction == "chorus"
	var debris_col: Color = Tg.fac.damage_glow if organic else tint.lerp(Color(0.93,0.48,0.20),0.5)
	_impact_sparks(fx,p+n*0.2*k,n,T,k,debris_col,18,24.0)
	if not organic:
		for j in 6: fx.shd(p,T,2.2,fx.rcone(n,0.8)*fx.rng.randf_range(5.0,12.0)*k,fx.rng.randf_range(0.16,0.35)*k,0.7,3.0,0.0)
	fx.ring(p,n,T+0.03,0.45,tint,0.65,k,12.0*k,2,0.0,0.0,70.0)
	fx.dst(p,T,0.4,k,12.0*k,0,0.45)
	_afterglow(fx,p+n*0.4*k,T,tint,3.5*k,false)
	fx.light(p+n*2.5*k,T,0.35,HULL_LIGHT,tint,0)
	fx.shake(T,0.4,p); fx.hit_pause(T,4); fx.punch(T,0.012,p)


static func _crit(fx, Tg, tg: Dictionary, T: float, k: float, w := 2) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	_burst(fx,p+n*0.5*k,n,T,6.0*k,"flash",0.25,Color(0.94,0.71,0.4),4.5,40.0)
	_vent(fx,p+n*k,n,T+0.05,6.0*k,0.45,Color(0.85,0.51,0.26),0.8,n*5.0*k,0.6,1.0,w,Tg)
	_impact_sparks(fx,p,n,T,k,Color(0.92,0.6,0.3),10,18.0)
	fx.light(p+n*2.0*k,T,0.3,7.5,Color(0.94,0.68,0.36),0)
	fx.shake(T,0.15,p); fx.hit_pause(T,2); fx.punch(T,0.006,p)


static func _miss_fade(fx, lk: String, tg: Dictionary, T: float, col: Color, dir: Vector3, k: float) -> void:
	# misses fly on and fade; a lance or arc sears empty space with a short flare
	if lk in ["lance", "ion", "pulsar", "doom"]:
		fx.spr(tg["p"], T, 0.4, col, 2.0, 2.0 * k, 3.0 * k, 18)


# ---------------------------------------------------------------- carriers

static func launch(fx, cid: String, sid: String) -> void:
	var C = fx.ship(cid)
	if C == null:
		return
	var S = fx.ship(sid)
	var T: float = fx.now
	var from: Vector3 = C.to_world(C.hull.c + Vector3(0, C.hull.H * 0.3, 0))
	var to: Vector3 = S.to_world(S.hull.c) if S != null else from + C.dir_world(Vector3(1, 0, 0)) * 20.0
	var eng: Color = C.fac["engine"]
	var k: float = C.scale_k()
	fx.spr(from, T, 0.8, eng, 1.5, 1.0 * k, 2.5 * k, 18)
	fx.light(from, T, 1.0, 3.0, eng, 1)
	for i in 6:
		var t0 = T + 0.3 + i * 0.25
		var d = (to - from)
		var life = maxf(d.length() / 60.0, 0.05)
		var kind: String = str(S.root.get("squad_kind")) if S != null and S.root.get("squad_kind") != null else CRAFT.DEFAULT_KIND.get(C.faction, "fighter")
		var off := Vector3(0, (i % 2) * 0.3, (i % 3 - 1) * 0.65)
		_craft_run(fx, C.faction, kind, from + off, to + off, t0, life, 2.4)


# ---------------------------------------------------------------- travelling torpedoes (B3, API.md 3 "coming")

const LANE := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
global uniform float scene_t;
global uniform float fx_gain;
global uniform float fx_calm;
uniform vec3 col = vec3(1.0, 0.5, 0.2);
uniform float warn = 0.0;
uniform float len = 50.0;
uniform float marker = 0.0;
void fragment() {
	vec3 c = mix(col, vec3(1.0), warn);
	if (marker > 0.5) {
		// the impact marker: a ring and a crosshair that pulse (slowly; faster and whiter in the warning)
		vec2 p = UV * 2.0 - 1.0;
		float r = length(p);
		float rate = mix(1.2, 2.5, warn) * mix(1.0, 0.5, fx_calm);
		float pulse = 0.6 + 0.4 * sin(scene_t * 6.2831 * rate);
		float ring = exp(-pow((r - 0.85) / 0.05, 2.0)) + exp(-pow((r - 0.55 + 0.1 * pulse) / 0.04, 2.0)) * 0.6;
		float crs = (exp(-abs(p.x) * 60.0) + exp(-abs(p.y) * 60.0)) * step(r, 0.4) * step(0.12, r);
		ALBEDO = c * (ring + crs) * (0.6 + 0.6 * pulse + 1.5 * warn) * fx_gain * 2.0;
	} else {
		// the lane: chevrons running toward the target, edges faint
		float s = UV.x * len;
		float x = abs(UV.y * 2.0 - 1.0);
		float chev = fract((s + x * 2.5) / 6.0 - scene_t * mix(0.6, 1.4, warn));
		float band = smoothstep(0.0, 0.15, chev) * (1.0 - smoothstep(0.35, 0.5, chev));
		float edge = exp(-pow((x - 0.92) / 0.05, 2.0)) * 0.35;
		float fade = smoothstep(0.0, 0.05, UV.x) * (1.0 - smoothstep(0.92, 1.0, UV.x) * 0.4);
		ALBEDO = c * (band * 0.55 + edge) * fade * (0.8 + 1.8 * warn) * fx_gain * 1.6;
	}
}
"""


static func torp_lane(fx, lane_id: String, aid: String, to: Vector3, turns: int) -> void:
	torp_lane_clear(fx, lane_id, false)
	var A = fx.ship(aid)
	if A == null:
		return
	var fac: Dictionary = A.fac
	var from: Vector3 = A.to_world(A.hull.bow)
	var y = minf(from.y, to.y) - 0.5
	var a = Vector3(from.x, y, from.z)
	var b = Vector3(to.x, y, to.z)
	var d: Vector3 = b - a
	var L = d.length()
	if L < 0.5:
		return
	var root = Node3D.new()
	root.name = "fx_lane_" + lane_id
	fx.add_child(root)
	var wc: Color = fac["weapon"]
	var strip = MeshInstance3D.new()
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side: Vector3 = d.normalized().cross(Vector3.UP).normalized()
	var w = 3.2 * A.scale_k() * fx.unit
	var c0 = a - side * w * 0.5
	var c1 = b - side * w * 0.5
	var c2 = b + side * w * 0.5
	var c3 = a + side * w * 0.5
	for q in [[c0, Vector2(0, 0)], [c1, Vector2(1, 0)], [c2, Vector2(1, 1)], [c0, Vector2(0, 0)], [c2, Vector2(1, 1)], [c3, Vector2(0, 1)]]:
		st.set_uv(q[1])
		st.add_vertex(q[0])
	strip.mesh = st.commit()
	var m: ShaderMaterial = fx.mat(LANE, 1)
	m.set_shader_parameter("col", Vector3(wc.r, wc.g, wc.b))
	m.set_shader_parameter("len", L)
	strip.material_override = m
	strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(strip)
	var mk = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(1, 1)
	mk.mesh = pm
	var mm: ShaderMaterial = fx.mat(LANE, 1)
	mm.set_shader_parameter("col", Vector3(wc.r, wc.g, wc.b))
	mm.set_shader_parameter("marker", 1.0)
	mk.material_override = mm
	mk.transform = Transform3D(Basis().scaled(Vector3.ONE * 9.0 * fx.unit), b + Vector3(0, 0.1, 0))
	mk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mk)
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	lanes[lane_id] = {"root": root, "mats": [m, mm], "from": from, "to": to, "aid": aid, "turns": turns, "torp": null, "projectiles": [], "look": look_of("torp", "startorp" if A.faction == "ithar" else "torp", A.faction), "fac": fac, "k": A.scale_k()}
	fx.dstate["lanes"] = lanes


# The torpedo leaves the tube and runs out along its lane, then holds there (engine burning) until the next turn.
static func torp_launch(fx, lane_id: String) -> void:
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	if not lanes.has(lane_id):
		return
	var ln: Dictionary = lanes[lane_id]
	var A = fx.ship(ln["aid"])
	var k: float = ln["k"]
	var from: Vector3 = ln["from"]
	var to: Vector3 = ln["to"]
	var park = from.lerp(to, 0.42) + Vector3(0, 2.0 * k, 0)
	var T: float = fx.now
	var mn: Vector3 = A.dir_world(Vector3(1, 0, 0)) if A != null else (to - from).normalized()
	var before: int = fx.dstate.get("proj", []).size()
	_launch(fx, ln["look"], from, mn, park, T + 0.15, T + 1.15, ln["fac"]["weapon"], ln["fac"], k, 0, false, A)
	var list: Array = fx.dstate.get("proj", [])
	var group: Array = list.slice(before)
	for p in group: p["park"] = true
	ln["projectiles"] = group
	ln["torp"] = group[0]



# Next turn: the lane ramps to white (two-stage warning, about 0.8 s), the torpedo closes and strikes.
static func torp_strike(fx, lane_id: String, tid: String, hit: Dictionary) -> Dictionary:
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	if not lanes.has(lane_id):
		return {"impacts": [], "done": 0.0}
	var ln: Dictionary = lanes[lane_id]
	var Tg = fx.ship(tid)
	var T: float = fx.now
	var warn_t = 0.8
	ln["warn_t0"] = T
	ln["warn_len"] = warn_t
	var p: Dictionary = ln["torp"] if ln["torp"] != null else {}
	var start: Vector3 = (ln["from"] as Vector3).lerp(ln["to"], 0.42)
	if not p.is_empty():
		start = p.get("pos", start)
	var hd = hit if not hit.is_empty() else {"shield": 0, "hull": 1, "section": "mid", "crit": false}
	var to_c: Vector3 = Tg.to_world(Tg.hull.c) if Tg != null else ln["to"]
	var kt: float = Tg.scale_k() if Tg != null else 1.0
	var tg = _target(fx, Tg, to_c, start, not hit.is_empty(), hd, -1, kt)
	var k: float = ln["k"]
	var dist = start.distance_to(tg["p"])
	var ti = T + warn_t + clampf(dist / (70.0 * fx.unit), 0.85, 1.25)
	for projectile in ln.get("projectiles", []):
		var at: Vector3 = projectile.get("pos", start)
		projectile["park"] = false
		projectile["a"] = at
		projectile["b"] = at.lerp(tg["p"], 0.5) + Vector3(0, 1.5 * k, 0)
		projectile["c"] = tg["p"]
		projectile["t0"] = T + warn_t
		projectile["t1"] = ti
		projectile["last"] = T + warn_t

	if not bool(tg.get("miss", false)):
		# Faction lane visuals change here; the existing R80 lane wound stays torp.
		tg["mark_look"] = "torp"
		_impact(fx, ln["look"], 3, Tg, tg, ti, ln["fac"]["weapon"], (tg["p"] - start).normalized(), hd, kt, 0.0)
		if Tg != null:
			Tg.busy_until = maxf(Tg.busy_until, ti)
	fx.later(ti + 0.2, func l_lane_clear() -> void: torp_lane_clear(fx, lane_id, false))
	return {"impacts": [ti - T], "done": ti - T + 0.5, "at": tg["p"]}


static func torp_lane_clear(fx, lane_id: String, dodged := true) -> void:
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	if not lanes.has(lane_id):
		return
	var ln: Dictionary = lanes[lane_id]
	if is_instance_valid(ln["root"]):
		(ln["root"] as Node).queue_free()
	for p in ln.get("projectiles", []):
		if dodged and p.get("park", false):
			# The whole swarm keeps its vector when a target clears the lane.
			var T: float = fx.now
			var dir: Vector3 = ((ln["to"] as Vector3) - (ln["from"] as Vector3)).normalized()
			p["park"] = false
			p["a"] = p.get("pos", ln["from"])
			p["c"] = (p["a"] as Vector3) + dir * 120.0 * fx.unit
			p["b"] = (p["a"] as Vector3).lerp(p["c"], 0.5)
			p["t0"] = T
			p["t1"] = T + 2.2
			p["last"] = T

	lanes.erase(lane_id)


# the lanes' warning ramp (two stages: a dim pulse to 0.35, then up to white), run from update()
static func _lanes_update(fx) -> void:
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	for id in lanes:
		var ln: Dictionary = lanes[id]
		if not ln.has("warn_t0"):
			continue
		var u = clampf((fx.now - float(ln["warn_t0"])) / float(ln["warn_len"]), 0.0, 1.0)
		var wv = 0.35 * smoothstep(0.0, 0.5, u) + 0.65 * smoothstep(0.5, 1.0, u)
		for m in ln["mats"]:
			(m as ShaderMaterial).set_shader_parameter("warn", wv)
