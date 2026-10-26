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
#   torp:    torp (Voidsworn hellfire: trackable bodies, long plumes)   rockets (Corsair rattle-rocket pods: swarms of
#            small sooty rockets)   star (Ithar star torpedo: a little sun)
#   flak:    airbursts in the faction's style (Hegemony picket lasers, Chorus spores, Ithar mirror glints, Deathless
#            gauss shredder streaks, Corsair chaff)
#   bio:     spine (bioplasma: wobbling globs that splash and corrode)   tendril (boarding tendrils: an organic lash)
#   gauss:   coil charge, a near invisible slug, a punch-through with an exit spray
#   sq:      guns, bombs, sporeb: craft on a strafing run

const POOLS := preload("res://fx/fx_pool.gd")
const DEATH := preload("res://fx/fx_death.gd")

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
	var ka: float = A.scale_k() if A != null else 1.0
	var kt: float = Tg.scale_k() if Tg != null else 1.0
	var col: Color = fac["weapon"]
	# mounts: the guns that can bear (never backward)
	var mounts: Array = []
	if A != null:
		var tl: Vector3 = A.xf().affine_inverse() * to_c
		for m in A.hull.mounts_for(tl, maxi(shots.size(), 1)):
			mounts.append({"p": A.to_world((m["p"] as Vector3) + (m["n"] as Vector3) * 0.15 * ka), "n": A.dir_world(m["n"])})
		if lk in ["lance", "ion", "pulsar", "doom", "torp", "star", "gauss"] and (A.xf().affine_inverse() * to_c - A.hull.c).normalized().x > 0.5:
			for i in mounts.size():
				mounts[i] = {"p": A.to_world(A.hull.bow + Vector3(0.3 * ka, 0, 0)), "n": A.dir_world(Vector3(1, 0, 0))}
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
		var r = _shot(fx, lk, kind, w, i, total, from, m["n"], tgt, T0, col, fac, A, Tg, hd, ka, kt)
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
	var hp: Dictionary = Tg.hull.hit_point(inv * from, sec, quad)
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
		col: Color, fac: Dictionary, A, Tg, hd: Dictionary, ka: float, kt: float) -> Array:
	var to: Vector3 = tg["p"]
	var dv = to - from
	var dist = maxf(dv.length(), 0.01)
	var dir = dv / dist
	var tf = T0
	var ti = T0
	var tend = T0
	match lk:
		"macro":
			tf = T0 + 0.2 + i * 0.08
			_muzzle_blast(fx, from, dir, tf, col, ka * (1.25 if w >= 3 else 1.0))
			var spd = SHELL_SPEED * fx.unit
			ti = tf + dist / spd
			fx.stk(from, tf, dist / spd, col.lerp(Color.WHITE, 0.3), 16.0, 9.0 * ka, 0.6 * ka * (1.2 if w >= 3 else 1.0), 0, dir * spd)
			fx.light(from + mn * 1.5 * ka, tf, 0.14, 7.0, col.lerp(Color.WHITE, 0.4), 0)
			fx.shake(tf, 0.03, from)
		"auto":
			tf = T0 + 0.05 + i * 0.22
			var spd = SHELL_SPEED * 1.3 * fx.unit
			for b in 4:
				var tb = tf + b * 0.05
				var jit = fx.rdir() * 0.3 * kt
				fx.spr(from + dir * 0.4 * ka, tb, 0.05, Color(1, 0.8, 0.45), 6.0, 0.8 * ka, 1.4 * ka, 0)
				fx.stk(from, tb, dist / spd, Color(1, 0.78, 0.4), 9.0, 3.5 * ka, 0.3 * ka, 0, (dir + jit / dist) * spd)
				if A != null and A.faction == "corsair":
					fx.spr(from + dir * 0.8 * ka, tb + 0.02, 0.9, Color(0.07, 0.06, 0.05), 0.4, 0.5 * ka, 1.8 * ka, 8, dir * 2.0, 0.8)
			fx.light(from + mn * 1.2 * ka, tf, 0.25, 3.5, Color(1, 0.75, 0.4), 1)
			ti = tf + dist / spd
		"las":
			tf = T0 + 0.05 + i * 0.12
			var spd = 280.0 * fx.unit
			fx.spr(from + dir * 0.3 * ka, tf, 0.06, col.lerp(Color.WHITE, 0.5), 7.0, 0.8 * ka, 1.6 * ka, 0)
			fx.stk(from, tf, dist / spd, col, 10.0, 5.0 * ka, 0.55 * ka, 4, dir * spd)
			fx.light(from, tf, 0.1, 4.0, col, 0)
			ti = tf + dist / spd
		"plasma":
			tf = T0 + 0.12 + i * 0.16
			var spd = SHELL_SPEED * 0.55 * fx.unit
			var sz = (2.6 if w >= 3 else 2.0) * ka
			fx.spr(from + dir * 0.6 * ka, tf, 0.18, col.lerp(Color.WHITE, 0.3), 4.0, sz * 1.2, sz * 2.4, 2)
			fx.spr(from, tf, dist / spd, col, 3.0, sz * 1.6, sz * 1.6, 14, dir * spd)
			fx.stk(from, tf, dist / spd, col, 3.0, 4.0 * ka, sz * 0.7, 0, dir * spd)
			# heat shimmer trailing the bolt
			for s in 3:
				fx.spr(from + dir * dist * (0.25 + s * 0.25), tf + dist / spd * (0.25 + s * 0.25), 0.4, col, 0.3, sz * 0.6, sz * 1.4, 18)
			fx.light(from + dir * 2.0, tf, dist / spd, 3.0, col, 1)
			fx.light(from, tf, 0.2, 4.0, col, 0)
			ti = tf + dist / spd
		"scatter":
			tf = T0 + 0.1 + i * 0.1
			var spd = SHELL_SPEED * 1.2 * fx.unit
			_muzzle_blast(fx, from, dir, tf, Color(1, 0.6, 0.3), ka * 0.7)
			for b in 6:
				var d2 = (dir + fx.rdir() * 0.06).normalized()
				fx.stk(from, tf + fx.rng.randf() * 0.03, dist / spd, Color(1, 0.65, 0.35), 8.0, 2.5 * ka, 0.3 * ka, 0, d2 * spd)
			ti = tf + dist / spd
		"prism":
			tf = T0 + 0.08 + i * 0.1
			var spd = 220.0 * fx.unit
			fx.spr(from, tf, 0.25, col, 3.0, 0.6 * ka, 1.8 * ka, 16)
			for b in 3:
				var d2 = (dir + fx.rdir() * 0.02).normalized()
				fx.stk(from, tf + b * 0.03, dist / spd, col.lerp(Color.WHITE, 0.4), 8.0, 3.0 * ka, 0.25 * ka, 4, d2 * spd)
				fx.spr(from, tf + b * 0.03, dist / spd, col, 1.6, 0.7 * ka, 0.7 * ka, 16, d2 * spd)
			ti = tf + dist / spd
		"needle":
			tf = T0 + 0.1 + i * 0.25
			fx.spr(from, tf - 0.12, 0.12, col, 4.0, 0.3 * ka, 1.6 * ka, 12)
			fx.rib(from, dir, dist, tf, 0.35, col, 1.6, 0.35 * ka, 0.3 * ka, 8)
			fx.light(from, tf, 0.35, 3.0, col, 1)
			ti = tf + 0.03
			tend = tf + 0.35
		"lance", "ion", "pulsar", "doom":
			var charge = 0.25 if lk != "doom" else 0.35
			tf = T0 + charge + i * 0.45
			var dur = 0.7 if lk != "pulsar" else 0.45
			var wd = (2.4 if lk != "doom" else 1.6) * ka * (1.15 if w >= 3 else 1.0)
			fx.spr(from, tf - charge, charge, col.lerp(Color.WHITE, 0.2), 9.0, 0.6 * ka, 5.0 * ka, 12)
			fx.light(from + dir, tf - charge, charge, 3.0, col, 2)
			if lk == "doom":
				# the arc gathers: little crawling arcs on the emitter before it strikes
				for s in 6:
					fx.rib(from + fx.rdir() * 1.2 * ka, fx.rdir(), 2.5 * ka, tf - charge + s * 0.05, 0.12, col, 1.4, 0.3 * ka, 0.2 * ka, 6)
			var rk: int = {"lance": 2, "ion": 5, "pulsar": 7, "doom": 6}[lk]
			fx.spr(from, tf, dur, col.lerp(Color.WHITE, 0.3), 7.0, 4.5 * ka, 4.5 * ka, 13)
			fx.rib(from, dir, dist, tf, dur, col, 2.4, wd, wd * 0.85, rk)
			fx.light(from + dir * 1.5, tf, dur, 4.0, col, 1)
			fx.dst(from + dir * dist * 0.5, tf, dur, dist * 0.3, dist * 0.35, 1, 0.6)
			fx.shake(tf, 0.08, from)
			ti = tf + 0.03
			tend = tf + dur
		"torp", "rockets", "star", "ram":
			if lk == "ram":
				ti = T0
				tend = T0
			else:
				var vent = 0.45 + i * (0.35 if lk == "torp" else 0.12)
				tf = T0 + vent
				var spd = (62.0 if lk == "torp" else (85.0 if lk == "rockets" else 55.0)) * fx.unit
				var tt = dist / spd + 0.25
				ti = tf + tt
				_launch(fx, lk, from, mn, to, tf, ti, col, fac, ka, i, bool(hd.get("pd", false)))
				tend = ti
		"flak", "pflak", "spores", "mflak", "gflak":
			tf = T0 + 0.03 + i * 0.07
			ti = _flak(fx, lk, from, dir, dist, to, tf, col, ka, kt, i, tg)
			tend = ti + 0.4
		"spine":
			var wind = 0.3
			tf = T0 + wind + i * (0.12 + fx.rng.randf() * 0.05)
			var spd = SHELL_SPEED * 0.5 * fx.unit
			fx.spr(from, tf - wind, wind, col, 1.4, 0.4 * ka, 1.6 * ka, 22)
			fx.spr(from + dir * 0.5 * ka, tf, 0.12, col, 2.0, 0.8 * ka, 2.0 * ka, 18)
			for s in 5:
				fx.stk(from, tf, 0.4, col, 2.0, 0.08, 0.12 * ka, 6, (dir + fx.rdir() * 0.4).normalized() * 8.0 * ka, 1.5)
			var gsz = 1.5 * ka
			var ft = dist / spd
			fx.spr(from, tf, ft, col, 2.0, gsz, gsz, 15, dir * spd)
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
			if fx.flash_ok(tf):
				fx.spr(from, tf, 0.05, Color(0.85, 0.95, 1.0), 12.0, 1.2 * ka, 2.2 * ka, 0)
			fx.ring(from + dir * 0.5 * ka, dir, tf, 0.35, Color(0.8, 0.95, 1.0), 1.2, 0.5 * ka, 4.0 * ka, 3)
			fx.dst(from + dir, tf, 0.3, 1.0 * ka, 6.0 * ka, 0, 1.2)
			fx.stk(from, tf, 0.3, col.lerp(Color.WHITE, 0.5), 3.0, dist, 0.1 * ka, 5, dir)
			fx.ring(from + dir * dist * 0.5, dir, tf + 0.05, 0.45, Color(0.8, 0.9, 1.0), 0.5, 0.5 * ka, 3.0 * ka, 3)
			fx.light(from, tf, 0.12, 6.0, Color(0.85, 0.95, 1.0), 0)
			fx.shake(tf, 0.08, from)
			ti = tf + dist / (650.0 * fx.unit)
		"guns", "bombs", "sporeb":
			ti = _strafe(fx, lk, from, to, T0 + i * 0.15, col, fac, ka, kt, i)
		_:
			ti = T0 + 0.3
	if tend < ti:
		tend = ti
	if not bool(tg.get("miss", false)):
		_impact(fx, lk, w, Tg, tg, ti, col, dir, hd, kt, tend - ti)
	else:
		_miss_fade(fx, lk, tg, ti, col, dir, kt)
	return [ti, tend + 0.3]


# ---------------------------------------------------------------- fire

static func _muzzle_blast(fx, p: Vector3, dir: Vector3, t: float, col: Color, k: float) -> void:
	var calm: bool = fx.reduce_flashing
	if not calm:
		fx.spr(p + dir * 0.6 * k, t, 0.09, col.lerp(Color.WHITE, 0.25), 11.0, 3.2 * k, 5.0 * k, 0)
	else:
		fx.spr(p + dir * 0.6 * k, t, 0.3, col, 1.5, 2.0 * k, 4.0 * k, 18)
	fx.spr(p + dir * 1.2 * k, t, 0.16, Color(1, 0.7, 0.4), 5.0 if not calm else 2.0, 1.6 * k, 3.2 * k, 2)
	fx.stk(p, t, 0.13, col.lerp(Color.WHITE, 0.35), 5.0, 4.5 * k, 1.5 * k, 3, dir)
	fx.ring(p + dir * 1.0 * k, dir, t + 0.02, 2.0, Color(0.24, 0.23, 0.22), 0.55, 1.0 * k, 5.5 * k, 0, 5.0 * k, 1.4)
	for s in 3:
		fx.spr(p + dir * (1.0 + s) * k, t + 0.03 + s * 0.03, 1.6 + fx.rng.randf() * 0.4, Color(0.20, 0.19, 0.18), 0.4, 1.2 * k,
			(4.0 + fx.rng.randf() * 2.0) * k, 3, fx.rcone(dir, 0.5) * (2 + fx.rng.randf() * 2) * k, 1.0)
	for s in 4:
		fx.stk(p, t, 0.3 + fx.rng.randf() * 0.2, Color(1, 0.6, 0.25), 6.0, 0.05, 0.1 * k, 1, fx.rcone(dir, 0.5) * (10 + fx.rng.randf() * 10) * k, 2.0)


# Torpedoes, rockets and star torpedoes: CPU-steered bodies on a curving path, with their exhaust drawn behind them.
static func _launch(fx, lk: String, from: Vector3, mn: Vector3, to: Vector3, tf: float, ti: float, col: Color, fac: Dictionary, k: float, i: int, intercept: bool) -> void:
	var eng: Color = fac["engine"]
	# cold launch: gas shove, vapour ring, dim flash (no counted flash)
	fx.spr(from + mn * 0.5 * k, tf, 0.15, eng, 2.5, 1.2 * k, 2.4 * k, 2)
	fx.ring(from + mn * 0.6 * k, mn, tf, 1.2, Color(0.5, 0.52, 0.56), 0.5, 0.6 * k, 3.5 * k, 0, 3.0 * k, 1.6)
	for s in 4:
		fx.spr(from + mn * 0.8 * k, tf + s * 0.04, 1.5, Color(0.55, 0.57, 0.6), 0.3, 0.8 * k, 3.0 * k, 7, fx.rcone(mn, 0.6) * 4.0 * k, 1.2)
	var n = 1
	if lk == "rockets":
		n = 4
	for j in n:
		var t0 = tf + j * 0.07
		var side = mn * (6.0 + fx.rng.randf() * 4.0) * k + fx.rdir() * 2.0 * k
		var mid = from.lerp(to, 0.45) + side + Vector3(0, (3.0 + fx.rng.randf() * 3.0) * k, 0)
		var end = to + (fx.rdir() * 0.6 * k if lk == "rockets" else Vector3.ZERO)
		var p = {"lk": lk, "t0": t0, "t1": ti + j * 0.03, "a": from, "b": mid, "c": end, "col": col, "eng": eng, "k": k,
			"seed": fx.rng.randf(), "last": t0, "mesh": null, "dead_at": INF}
		if intercept and j == 0:
			p["dead_at"] = lerpf(t0, ti, 0.62)
		if lk == "torp":
			p["mesh"] = _torp_mesh(fx, k, fac)
		elif lk == "rockets":
			p["mesh"] = _rocket_mesh(fx, k)
		var list: Array = fx.dstate.get("proj", [])
		list.append(p)
		fx.dstate["proj"] = list


static func _torp_mesh(fx, k: float, fac: Dictionary) -> MeshInstance3D:
	if not fx.dstate.has("torp_mesh"):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var seg = 10
		var prof = [[-1.0, 0.18], [-0.85, 0.26], [0.55, 0.26], [0.85, 0.16], [1.0, 0.0]]
		for s in seg:
			var a0 = TAU * s / seg
			var a1 = TAU * (s + 1) / seg
			for j in prof.size() - 1:
				var x0: float = prof[j][0]
				var r0: float = prof[j][1]
				var x1: float = prof[j + 1][0]
				var r1: float = prof[j + 1][1]
				var v00 = Vector3(x0, cos(a0) * r0, sin(a0) * r0)
				var v01 = Vector3(x0, cos(a1) * r0, sin(a1) * r0)
				var v10 = Vector3(x1, cos(a0) * r1, sin(a0) * r1)
				var v11 = Vector3(x1, cos(a1) * r1, sin(a1) * r1)
				for v in [v00, v10, v11, v00, v11, v01]:
					st.set_uv(Vector2((v.x + 1.0) * 0.5, 0))
					st.add_vertex(v)
		st.generate_normals()
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(0.12, 0.11, 0.1)
		m.metallic = 0.7
		m.roughness = 0.45
		m.emission_enabled = true
		m.emission = Color(1, 0.4, 0.1)
		m.emission_energy_multiplier = 0.3
		var mesh = st.commit()
		mesh.surface_set_material(0, m)
		fx.dstate["torp_mesh"] = mesh
	var mi = MeshInstance3D.new()
	mi.mesh = fx.dstate["torp_mesh"]
	mi.scale = Vector3(1.6, 1.0, 1.0) * 1.2 * k * fx.unit
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(mi)
	return mi


static func _rocket_mesh(fx, k: float) -> MeshInstance3D:
	var mi = _torp_mesh(fx, k, {})
	mi.scale = Vector3(1.4, 0.55, 0.55) * 1.0 * k * fx.unit
	return mi


static func _bez(a: Vector3, b: Vector3, c: Vector3, u: float) -> Vector3:
	return a.lerp(b, u).lerp(b.lerp(c, u), u)


static func update(fx, dt: float) -> void:
	_lanes_update(fx)
	var list: Array = fx.dstate.get("proj", [])
	if list.is_empty():
		return
	var keep: Array = []
	for p in list:
		var t0: float = p["t0"]
		var t1: float = p["t1"]
		var now: float = fx.now
		if now < t0:
			keep.append(p)
			continue
		if p.get("park", false) and now >= t1:
			# a torpedo holding in its lane: it idles at the end of its run, engine burning
			now = t1 - 0.001
		var dead: bool = now >= t1 or now >= float(p["dead_at"])
		if dead:
			if now >= float(p["dead_at"]) and float(p["dead_at"]) < t1 and not p.has("popped"):
				# intercepted short of the target: an airburst
				p["popped"] = true
				var u0 = clampf((float(p["dead_at"]) - t0) / (t1 - t0), 0.0, 1.0)
				var pp = _bez(p["a"], p["b"], p["c"], _ease(u0))
				fx.pop(pp, now, Color(1, 0.75, 0.45), 4.0 * float(p["k"]), 6.0)
				fx.spr(pp, now, 0.8, Color(1, 0.6, 0.25), 3.0, 1.0 * float(p["k"]), 4.0 * float(p["k"]), 2)
				for s in 10:
					fx.stk(pp, now, 0.4, Color(1, 0.6, 0.25), 6.0, 0.05, 0.12, 1, fx.rdir() * 12.0 * float(p["k"]), 2.0)
				for s in 6:
					fx.shd(pp, now, 2.0, fx.rdir() * 6.0 * float(p["k"]), 0.25 * float(p["k"]), 1.0)
			if p["mesh"] != null and is_instance_valid(p["mesh"]):
				(p["mesh"] as Node).queue_free()
			continue
		keep.append(p)
		var u = clampf((now - t0) / (t1 - t0), 0.0, 1.0)
		var e = _ease(u)
		var pos = _bez(p["a"], p["b"], p["c"], e)
		p["pos"] = pos
		var ahead = _bez(p["a"], p["b"], p["c"], minf(e + 0.02, 1.0))
		var d = (ahead - pos)
		d = d.normalized() if d.length() > 1e-4 else Vector3(1, 0, 0)
		var k: float = p["k"]
		var lk: String = p["lk"]
		var eng: Color = p["eng"]
		if p["mesh"] != null and is_instance_valid(p["mesh"]):
			var mi: MeshInstance3D = p["mesh"]
			var wob = Vector3(sin(now * 9.0 + float(p["seed"]) * 10.0), cos(now * 7.0), 0) * 0.15 * k
			mi.global_transform = Transform3D(Basis.looking_at(-d, Vector3.UP).rotated(d, now * 4.0) * Basis(Vector3.UP, -PI / 2).scaled(mi.scale), pos + wob)
		# exhaust: emitted along the swept segment since last frame (no spotty gaps at speed)
		var last: float = p["last"]
		var rate = 90.0 if lk == "torp" else (40.0 if lk == "rockets" else 60.0)
		var nemit = int((now - last) * rate)
		if nemit > 0:
			p["last"] = last + nemit / rate
			var tail = pos - d * 1.0 * k
			for s in nemit:
				var f = (s + 1.0) / nemit
				var ps = tail - d * (1.0 - f) * maxf((now - last) * 60.0 * k, 0.0) * 0.1
				var tt: float = last + f * (now - last)
				if lk == "star":
					fx.spr(ps, tt, 0.25, eng, 2.0, 2.4 * k, 1.2 * k, 17)
					fx.spr(ps, tt, 0.6, eng, 0.6, 1.0 * k, 2.2 * k, 18)
				else:
					fx.spr(ps, tt, 0.14, eng, 5.0 if lk == "torp" else 4.0, (2.2 if lk == "torp" else 1.6) * k, 0.6 * k, 2)
					if lk == "torp":
						# the long persistent plume: the signature that keeps every torpedo trackable
						fx.spr(ps, tt, 3.6, Color(0.62, 0.64, 0.7), 0.12, 1.0 * k, 3.8 * k, 7, fx.rdir() * 0.5 * k, 0.6, 0.3)
						fx.spr(ps, tt, 0.9, eng, 0.7, 1.2 * k, 2.4 * k, 18)
					else:
						# rattle-rockets: a hot streak and a dirty grey smoke trail each, so the swarm reads at a glance
						fx.spr(ps, tt, 1.8, Color(0.34, 0.31, 0.28), 0.45, 0.6 * k, 2.8 * k, 8, fx.rdir() * 0.8 * k, 0.8, 0.5)
						if s == nemit - 1:
							fx.stk(pos, tt, 0.08, eng.lerp(Color(1, 0.85, 0.5), 0.4), 6.0, 0.06, 0.35 * k, 1, -d * 40.0 * k, 0.0)
		if lk != "star":
			fx.light(pos - d * k, now, 0.05, 1.5 if lk == "torp" else 0.8, eng, 1)
		else:
			fx.light(pos, now, 0.05, 3.0, eng, 1)
	fx.dstate["proj"] = keep


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
				fx.stk(from, tb, ft, col.lerp(Color.WHITE, 0.4), 7.0, 3.0 * ka, 0.25 * ka, 4, (bp - from).normalized() * spd)
			"gflak":
				fx.stk(from, tb, 0.25, col.lerp(Color.WHITE, 0.5), 5.0, from.distance_to(bp), 0.1 * ka, 5, (bp - from).normalized())
				ft = 0.02
			"spores":
				ft *= 2.2
				fx.spr(from, tb, ft, col, 1.4, 0.7 * ka, 0.7 * ka, 15, (bp - from) / ft)
			_:
				fx.spr(from + dir * 0.4 * ka, tb, 0.04, Color(1, 0.85, 0.5), 3.0, 0.6 * ka, 1.0 * ka, 0)
				fx.stk(from, tb, ft, Color(1, 0.8, 0.5), 5.0, 2.5 * ka, 0.25 * ka, 0, (bp - from).normalized() * spd)
		var t_b = tb + ft
		last = maxf(last, t_b)
		match lk:
			"spores":
				for s in 3:
					fx.spr(bp + fx.rdir() * 0.6 * kt, t_b + s * 0.05, 2.5, col * Color(0.5, 0.6, 0.35), 0.45, 0.8 * kt, 3.2 * kt, 20, fx.rdir() * 0.8, 0.6)
				fx.spr(bp, t_b, 0.4, col, 1.4, 0.5 * kt, 2.0 * kt, 18)
			"mflak":
				for s in 5:
					fx.spr(bp + fx.rdir() * 1.0 * kt, t_b + s * 0.03, 0.7, col, 2.2, 0.5 * kt, 0.2 * kt, 16, fx.rdir() * 2.0 * kt, 1.0)
			_:
				# a dirty airburst: core pop (merged against the flash budget), shrapnel, a smoke ball that hangs
				if fx.flash_ok(t_b):
					fx.spr(bp, t_b, 0.12, Color(1, 0.92, 0.7), 5.0, 0.8 * kt, 2.4 * kt, 0)
				fx.spr(bp, t_b, 0.3, Color(1, 0.65, 0.3), 2.5, 0.6 * kt, 2.0 * kt, 2)
				for s in 10:
					fx.stk(bp, t_b + fx.rng.randf() * 0.02, 0.25 + fx.rng.randf() * 0.25, Color(1, 0.75, 0.4), 6.0, 0.05, 0.09 * kt, 1, fx.rdir() * (10 + fx.rng.randf() * 14) * kt, 2.5)
				var smoke = Color(0.14, 0.13, 0.12) if lk != "gflak" else Color(0.08, 0.12, 0.09)
				fx.spr(bp, t_b + 0.03, 2.6 + fx.rng.randf(), smoke, 0.5, 0.8 * kt, 2.8 * kt, 3, fx.rdir() * 0.6, 0.8)
	return last


# Strike craft: a loose formation flies a strafing run past the target, firing as it goes.
static func _strafe(fx, lk: String, from: Vector3, to: Vector3, t0: float, col: Color, fac: Dictionary, ka: float, kt: float, i: int) -> float:
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
		fx.spr(start + off, t0 + c * 0.04, life, eng, 1.6, 1.4, 1.4, 23, vel)
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
					fx.stk(ps, tsh, (to - ps).length() / 260.0, col.lerp(Color.WHITE, 0.3), 5.0, 2.0, 0.15, 0, dd * 260.0)
	return timp + (0.3 if lk == "bombs" else 0.1)


# ---------------------------------------------------------------- impacts

static func _impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, hd: Dictionary, k: float, sustain: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var crit = bool(hd.get("crit", false))
	var torp = lk in ["torp", "rockets", "star", "ram"]
	var beam = lk in ["lance", "ion", "pulsar", "doom", "needle"]
	var bio = lk in ["spine", "tendril", "sporeb", "spores"]
	var light = lk in ["auto", "las", "scatter", "guns", "flak", "pflak", "mflak", "gflak", "prism"]
	if bool(tg.get("shield", false)):
		_shield_impact(fx, lk, w, Tg, tg, T, dir, k, sustain, torp, beam, bio, light)
		return
	if tg.has("through") and Tg != null:
		var th: Dictionary = tg["through"]
		Tg.shield_hit(fx, th["local"], T - 0.02, 0.5, 8.0 * k, 0.4)
	var hc = Color(1, 0.62, 0.28)
	# --- by family
	if beam:
		_beam_burn(fx, lk, Tg, tg, T, sustain, col, k)
	elif bio:
		_bio_splat(fx, Tg, tg, T, col, k, lk == "tendril")
	elif lk == "gauss":
		_gauss_punch(fx, Tg, tg, T, dir, col, k, w)
	elif torp:
		_big_hit(fx, Tg, tg, T, k * (1.5 if lk == "ram" else (0.7 if lk == "rockets" else 1.0)), col, lk == "star")
	else:
		# shells and bolts by weight: light pings, medium chips and a dent, heavy debris spray and a fire lick
		var sz = (1.4 if light else (2.5 if w <= 2 else 3.4)) * k
		if lk == "plasma":
			sz *= 1.3
			hc = col.lerp(Color(1, 0.8, 0.5), 0.4)
		fx.pop(p + n * 0.2 * k, T, hc.lerp(Color.WHITE, 0.3), sz * 1.6, 9.0 if not light else 5.0, n, 0.12)
		var ns = 8 if light else (14 if w <= 2 else 22)
		for s in ns:
			fx.stk(p, T + fx.rng.randf() * 0.03, 0.25 + fx.rng.randf() * 0.35, Color(1, 0.6, 0.25), 7.0, 0.04, 0.12 * k, 1,
				fx.rcone(n + dir * -0.3, 0.9) * (9 + fx.rng.randf() * 16) * k, 2.2)
		if not light:
			for s in (4 if w <= 2 else 10):
				fx.shd(p, T, 2.4, fx.rcone(n, 0.8) * (3 + fx.rng.randf() * 7) * k, (0.12 + fx.rng.randf() * 0.18) * k, 1.0)
			fx.spr(p + n * 0.4 * k, T, 0.3, Color(1, 0.7, 0.4), 4.0, sz * 0.4, sz * 1.2, 2)
			fx.spr(p + n * 0.6 * k, T + 0.08, 1.6, Color(0.12, 0.11, 0.1), 0.5, sz * 0.5, sz * 1.8, 3, n * 2.0 * k, 0.6)
		if w >= 3:
			for s in 3:
				fx.spr(p + n * 0.5 * k, T + 0.03 * s, 0.6 + fx.rng.randf() * 0.4, Color(1, 0.5, 0.15), 3.0, sz * 0.3, sz * 0.9, 1, n * 2.0 * k + fx.rdir() * 0.6)
			DEATH.spawn_debris(fx, p + n * 0.5 * k, n * 4.0 * k, 2, 0.3 * k)
		if lk == "plasma":
			# glowing slag left on the plate, dripping
			for s in 4:
				fx.spr(p + fx.rdir() * 0.4 * k, T + 0.05, 2.0 + fx.rng.randf(), col, 1.2, 0.4 * k, 0.3 * k, 21)
				fx.stk(p, T + 0.1 + s * 0.15, 0.7, col.lerp(Color(1, 0.6, 0.2), 0.5), 2.0, 0.1, 0.1 * k, 7, (n + Vector3(0, -1, 0)).normalized() * 2.5 * k, 0.8)
		fx.light(p + n * 1.5 * k, T, 0.2, 6.0 if not light else 2.5, hc, 0)
		fx.shake(T, 0.04 if light else (0.08 if w <= 2 else 0.14), p)
		if Tg != null and not light and tg.has("lp"):
			fx.later(T, func() -> void: Tg.add_hit_scorch(fx, tg["lp"], tg["ln"], (0.9 if w <= 2 else 1.4) * k))
	if crit:
		_crit(fx, Tg, tg, T + 0.12, k)


static func _shield_impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, dir: Vector3, k: float, sustain: float, torp: bool, beam: bool, bio: bool, light: bool) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var sc: Color = Tg.fac["shield"] if Tg != null else Color(0.4, 0.7, 1.0)
	var strength = 0.6 if light else (1.0 if w <= 2 else 1.4)
	var spread = (9.0 if light else 14.0) * k
	var life = 0.6
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
	if Tg != null:
		Tg.shield_hit(fx, tg["local"], T, strength, spread, life)
		if beam and sustain > 0.3:
			# slow rings while the beam holds (one per 0.35 s), not counted flashes
			var t = T + 0.35
			while t < T + sustain:
				Tg.shield_hit(fx, tg["local"], t, 0.6, spread * 0.8, 0.6)
				t += 0.35
	if lk in ["flak", "pflak", "gflak", "mflak", "spores", "guns"]:
		fx.spr(p, T, 0.18, sc, 1.6, 0.6 * k, 1.6 * k, 18)
		return
	fx.pop(p, T, sc.lerp(Color.WHITE, 0.25), (3.2 if not torp else 10.0) * k, 3.5 if not torp else 9.0, n, 0.14 if not torp else 0.28)
	var ns = 10 if not torp else 60
	if beam:
		ns = int(30 * maxf(sustain, 0.4))
	for s in ns:
		var ts = T + (fx.rng.randf() * maxf(sustain, 0.03) if beam else fx.rng.randf() * 0.03)
		var tang = (fx.rdir() - n * fx.rdir().dot(n)).normalized()
		var v = (tang * 0.8 + n * 0.4).normalized() if beam else fx.rcone(n, 0.9)
		if lk == "gauss":
			v = (dir * (1.0 if s % 2 == 0 else -1.0) + fx.rdir() * 0.25).normalized()
		fx.stk(p, ts, 0.25 + fx.rng.randf() * 0.3, sc.lerp(Color.WHITE, 0.5), 6.0, 0.04, 0.12 * k, 1, v * (10 + fx.rng.randf() * 14) * k, 2.5)
	if bio:
		for s in 5:
			fx.spr(p + fx.rdir() * 0.5 * k, T + s * 0.04, 0.9, Tg.fac["weapon"] if false else Color(0.6, 0.9, 0.25), 1.2, 0.6 * k, 2.2 * k, 15, n * 0.5 + Vector3(0, -2, 0), 0.6)
	if torp:
		fx.ring(p, n, T, 1.0, sc, 1.2, 2.0 * k, 26.0 * k, 1)
		fx.dst(p, T, 0.7, 2.0 * k, 22.0 * k, 0, 1.0)
		fx.shake(T, 0.35, p)
		fx.hit_pause(T, 3)
	elif lk == "gauss":
		fx.shake(T, 0.12, p)
	fx.light(p + n * 2.0 * k, T, 0.35 if not beam else sustain + 0.2, 6.0, sc, 0 if not beam else 1)


static func _beam_burn(fx, lk: String, Tg, tg: Dictionary, T: float, sustain: float, col: Color, k: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var dur = maxf(sustain, 0.3)
	fx.spr(p + n * 0.2 * k, T, dur, col.lerp(Color.WHITE, 0.4), 9.0, 7.0 * k, 7.0 * k, 13)
	if fx.flash_ok(T):
		fx.spr(p, T, 0.08, Color(1, 0.95, 0.85), 9.0, 2.0 * k, 4.0 * k, 0)
	# the molten trench: a white-hot contact point dragging across the plate, cooling white to orange to char
	var tang = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var steps = 8
	for s in steps:
		var u = float(s) / steps
		var pp = p + tang * (u - 0.5) * 2.2 * k
		fx.spr(pp + n * 0.05, T + u * dur, 2.5 + fx.rng.randf(), Color(1, 0.6, 0.2), 1.6, 0.9 * k, 0.6 * k, 21)
	for s in int(44 * dur):
		var ts = T + fx.rng.randf() * dur
		var sd = fx.rcone(n + Vector3(0, 0.2, 0), 1.1)
		fx.stk(p, ts, 0.35 + fx.rng.randf() * 0.5, col.lerp(Color(1, 0.8, 0.5), 0.5), 7.0, 0.05, 0.14 * k, 1, sd * (14 + fx.rng.randf() * 22) * k, 1.6)
	for s in int(6 * dur):
		fx.stk(p, T + fx.rng.randf() * dur, 0.9, Color(1, 0.55, 0.15), 3.0, 0.12, 0.12 * k, 7, (n * 0.6 + Vector3(0, -1, 0) + fx.rdir() * 0.3).normalized() * 4.0 * k, 0.6)
	for s in 4:
		fx.spr(p + n * 0.6 * k, T + 0.1 + s * 0.15, 1.2, Color(0.2, 0.19, 0.18), 0.35, 2.0 * k, 6.0 * k, 3, fx.rdir() * 2.5, 0.8)
	if lk == "ion" and Tg != null and Tg._shield_mat != null:
		# ion leaves a blue static wash on the shield facing
		Tg.shield_hit(fx, Tg.shield_point(p + n * 20.0)["local"], T + dur, 0.5, 18.0 * k, 1.2)
	if lk == "doom":
		for s in 10:
			fx.rib(p, fx.rcone(n, 1.2), (2.0 + fx.rng.randf() * 3.0) * k, T + fx.rng.randf() * dur, 0.1, col, 1.2, 0.25 * k, 0.15 * k, 6)
	fx.light(p + n * 1.5 * k, T, dur, 5.0, col, 1)
	fx.shake(T, 0.12, p)
	DEATH.spawn_debris(fx, p + n * 0.5 * k, n * 3.0 * k, 2, 0.3 * k)
	if Tg != null and tg.has("lp"):
		fx.later(T + dur, func() -> void: Tg.add_hit_scorch(fx, tg["lp"], tg["ln"], 1.8 * k))


static func _bio_splat(fx, Tg, tg: Dictionary, T: float, col: Color, k: float, lash: bool) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	# no bright flash by design: a wet splash, clinging acid, fumes, corrosion that keeps spreading
	for s in 8:
		fx.spr(p + fx.rdir() * 0.3 * k, T + fx.rng.randf() * 0.05, 0.6 + fx.rng.randf() * 0.4, col, 1.6, 0.5 * k, 1.4 * k, 15, (fx.rcone(n, 1.0) * 4.0 + Vector3(0, -1, 0)) * k, 1.2)
	for s in 12:
		fx.stk(p, T, 0.6, col, 2.0, 0.08, 0.1 * k, 6, (fx.rcone(n, 1.0) * 6.0 + Vector3(0, -2, 0)) * k, 1.2)
	for s in 5:
		fx.spr(p + n * 0.3 * k + fx.rdir() * 0.6 * k, T + 0.1 + s * 0.25, 2.5, Color(0.35, 0.55, 0.15), 0.45, 0.8 * k, 3.0 * k, 20, n * 1.0 * k + Vector3(0, 0.5, 0), 0.5)
	for s in 6:
		fx.spr(p + fx.rdir() * 0.8 * k, T + 0.2 + s * 0.2, 1.8, Color(0.5, 1.0, 0.25), 1.0, 0.5 * k, 0.4 * k, 21)
	fx.light(p + n * 1.5 * k, T, 0.6, 2.0, col, 1)
	fx.shake(T, 0.05 if not lash else 0.1, p)
	if Tg != null and tg.has("lp"):
		var r = RandomNumberGenerator.new()
		r.seed = int(T * 1000.0)
		fx.later(T + 0.3, func() -> void:
			var d: Node3D = DEATH.hole_decal(fx, Tg._dmg_root, tg["lp"], tg["ln"], 0.9 * k, 0.28, 0.5, r, true)
			Tg._hit_decals.append(d))


static func _gauss_punch(fx, Tg, tg: Dictionary, T: float, dir: Vector3, col: Color, k: float, w: int) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	fx.pop(p, T, Color(0.85, 0.95, 1.0), 3.0 * k, 10.0, n, 0.08)
	for s in 14:
		fx.stk(p, T, 0.3 + fx.rng.randf() * 0.3, Color(1, 0.75, 0.45), 7.0, 0.04, 0.1 * k, 1, fx.rcone(n, 0.4) * (14 + fx.rng.randf() * 18) * k, 2.0)
	# the slug goes through: an exit crater on the far side, blown outward, with hot debris contrails
	if Tg != null:
		var inv: Transform3D = Tg.xf().affine_inverse()
		var lp = inv * p
		var ld: Vector3 = (Tg.xf().basis.inverse() * dir).normalized()
		var far: Dictionary = Tg.hull.ray(lp + ld * (Tg.hull.L + Tg.hull.W) * 2.0, -ld)
		if not far.is_empty():
			var xp: Vector3 = Tg.to_world(far["p"])
			var xn: Vector3 = Tg.dir_world(far["n"])
			var tx = T + 0.04
			fx.spr(xp + xn * 0.3 * k, tx, 0.4, Color(1, 0.7, 0.4), 5.0, 1.0 * k, 3.5 * k, 2)
			for s in (20 if w >= 3 else 12):
				var v = fx.rcone(dir * 0.7 + xn * 0.3, 0.5) * (12 + fx.rng.randf() * 20) * k
				fx.stk(xp, tx + fx.rng.randf() * 0.04, 0.4 + fx.rng.randf() * 0.4, Color(1, 0.6, 0.25), 7.0, 0.06, 0.14 * k, 1, v, 1.2)
			for s in (8 if w >= 3 else 4):
				fx.shd(xp, tx, 3.0, fx.rcone(dir, 0.5) * (6 + fx.rng.randf() * 10) * k, (0.15 + fx.rng.randf() * 0.25) * k, 1.0)
			fx.spr(xp + xn * 0.8 * k, tx + 0.05, 2.0, Color(0.6, 0.65, 0.72), 0.3, 0.6 * k, 3.0 * k, 7, xn * 6.0 * k, 0.6)
			DEATH.spawn_debris(fx, xp + xn * 0.5 * k, dir * 8.0 * k, 3, 0.35 * k)
			var r = RandomNumberGenerator.new()
			r.seed = int(T * 997.0)
			fx.later(tx, func() -> void:
				Tg._hit_decals.append(DEATH.hole_decal(fx, Tg._dmg_root, far["p"], far["n"], 0.9 * k, 0.35, 1.0, r)))
		if tg.has("lp"):
			var r2 = RandomNumberGenerator.new()
			r2.seed = int(T * 991.0)
			fx.later(T, func() -> void:
				Tg._hit_decals.append(DEATH.hole_decal(fx, Tg._dmg_root, tg["lp"], tg["ln"], 0.6 * k, 0.3, 1.0, r2)))
	fx.light(p + n * 1.5 * k, T, 0.25, 7.0, Color(0.85, 0.95, 1.0), 0)
	fx.shake(T, 0.2 if w >= 3 else 0.12, p)
	if w >= 3:
		fx.hit_pause(T, 3)


static func _big_hit(fx, Tg, tg: Dictionary, T: float, k: float, col: Color, star: bool) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var R = 4.0 * k
	var hot = Color(1, 0.6, 0.25) if not star else col.lerp(Color(1, 0.95, 0.8), 0.4)
	fx.pop(p + n * 0.5 * k, T, Color(1, 0.88, 0.7), R * 2.5, 14.0, n, 0.22)
	fx.spr(p + n * 0.8 * k, T, 0.7, hot, 7.0, R * 0.4, R * 1.4, 2)
	# two-stage: a sympathetic pop a moment later
	fx.spr(p + n * 0.6 * k + fx.rdir() * R * 0.3, T + 0.3, 0.5, hot, 5.0, R * 0.3, R * 1.0, 2)
	DEATH.fireball(fx, p + n * R * 0.4, R * 2.0, T, 3.0, hot)
	fx.ring(p, n, T, 0.9, Color(0.5, 0.6, 1.0) if not star else col, 0.9, R * 0.2, R * 4.0, 1)
	fx.dst(p, T, 0.7, R * 0.3, R * 4.0, 0, 1.0)
	for s in 8:
		fx.spr(p + n * 0.5 * k, T + fx.rng.randf() * 0.1, 1.0 + fx.rng.randf() * 0.6, hot, 2.6, R * 0.3, R * 0.9, 1, fx.rcone(n, 0.8) * (2 + fx.rng.randf() * 4) * k)
	for s in 40:
		fx.stk(p, T + fx.rng.randf() * 0.05, 0.4 + fx.rng.randf() * 0.6, Color(1, 0.6, 0.25), 7.0, 0.05, 0.15 * k, 1, fx.rcone(n, 1.0) * (12 + fx.rng.randf() * 24) * k, 1.4)
	for s in 14:
		fx.shd(p, T, 3.5, fx.rcone(n, 0.9) * (3 + fx.rng.randf() * 9) * k, (0.2 + fx.rng.randf() * 0.4) * k, 1.0)
	for s in 20:
		fx.spr(p + fx.rdir() * 0.5 * k, T + fx.rng.randf() * 0.2, 1.5 + fx.rng.randf() * 1.5, Color(1, 0.5, 0.15), 1.8, 0.25 * k, 0.1 * k, 19, fx.rcone(n, 1.0) * (3 + fx.rng.randf() * 6) * k, 0.4)
	if fx.quality != "max":
		for s in 4:
			fx.spr(p + n * k, T + 0.15 + s * 0.1, 3.0, Color(0.08, 0.075, 0.07), 0.6, R * 0.5, R * 1.8, 3, n * 2.0 * k, 0.5)
	DEATH.spawn_debris(fx, p + n * k, n * 5.0 * k, 6, 0.5 * k)
	fx.light(p + n * 2.5 * k, T, 0.7, 14.0, Color(1, 0.75, 0.45), 0)
	fx.shake(T, 0.45, p)
	fx.hit_pause(T, 4)
	if Tg != null and tg.has("lp"):
		fx.later(T, func() -> void: Tg.add_hit_scorch(fx, tg["lp"], tg["ln"], 2.6 * k))


static func _crit(fx, Tg, tg: Dictionary, T: float, k: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	fx.pop(p + n * 0.6 * k, T, Color(1, 0.8, 0.5), 5.0 * k, 8.0, n, 0.14)
	fx.spr(p + n * 0.8 * k, T, 0.5, Color(1, 0.6, 0.25), 5.0, 1.0 * k, 3.5 * k, 2)
	for s in 18:
		fx.stk(p, T, 0.4 + fx.rng.randf() * 0.4, Color(1, 0.6, 0.25), 7.0, 0.05, 0.13 * k, 1, fx.rcone(n, 1.0) * (10 + fx.rng.randf() * 16) * k, 1.6)
	for s in 6:
		fx.shd(p, T, 3.0, fx.rcone(n, 0.8) * (3 + fx.rng.randf() * 7) * k, (0.15 + fx.rng.randf() * 0.3) * k, 1.0)
	fx.light(p + n * 2.0 * k, T, 0.4, 8.0, Color(1, 0.65, 0.3), 0)
	fx.shake(T, 0.15, p)
	fx.hit_pause(T, 2)
	DEATH.spawn_debris(fx, p + n * 0.6 * k, n * 4.0 * k, 3, 0.35 * k)


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
		var life = d.length() / 60.0
		fx.spr(from, t0, life, eng, 1.6, 1.2, 1.2, 23, d / life)
		fx.stk(from, t0, life, eng, 2.0, 3.0, 0.15, 0, d.normalized() * 60.0)


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
		float chev = fract((s - x * 2.5) / 6.0 - scene_t * mix(0.6, 1.4, warn));
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
	lanes[lane_id] = {"root": root, "mats": [m, mm], "from": from, "to": to, "aid": aid, "turns": turns, "torp": null, "fac": fac, "k": A.scale_k()}
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
	_launch(fx, "torp", from, mn, park, T + 0.45, T + 2.0, ln["fac"]["weapon"], ln["fac"], k, 0, false)
	var list: Array = fx.dstate.get("proj", [])
	var p: Dictionary = list[list.size() - 1]
	p["park"] = true            # holds at the end of its run instead of vanishing
	ln["torp"] = p


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
	var ti = T + warn_t + dist / (70.0 * fx.unit)
	if not p.is_empty():
		p["park"] = false
		p["a"] = start
		p["b"] = start.lerp(tg["p"], 0.5) + Vector3(0, 1.5 * k, 0)
		p["c"] = tg["p"]
		p["t0"] = T + warn_t
		p["t1"] = ti
		p["last"] = T + warn_t
	if not bool(tg.get("miss", false)):
		_impact(fx, "torp", 3, Tg, tg, ti, ln["fac"]["weapon"], (tg["p"] - start).normalized(), hd, kt, 0.0)
		if Tg != null:
			Tg.busy_until = maxf(Tg.busy_until, ti)
	fx.later(ti + 0.2, func() -> void: torp_lane_clear(fx, lane_id, false))
	return {"impacts": [ti - T], "done": ti - T + 0.5}


static func torp_lane_clear(fx, lane_id: String, dodged := true) -> void:
	var lanes: Dictionary = fx.dstate.get("lanes", {})
	if not lanes.has(lane_id):
		return
	var ln: Dictionary = lanes[lane_id]
	if is_instance_valid(ln["root"]):
		(ln["root"] as Node).queue_free()
	if ln["torp"] != null:
		var p: Dictionary = ln["torp"]
		if dodged and p.get("park", false):
			# the target got out of the lane: the torpedo runs on past the marker and burns out
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
