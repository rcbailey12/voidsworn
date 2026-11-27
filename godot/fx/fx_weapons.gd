extends RefCounted
# Weapon effects: every rules weapon kind (battery, flak, lance, torp, bio, gauss, sq) with its fire, travel and impact on
# shields and hulls by weight, and a faction look per weapon id (data.js FAC_WNAMES): the five cheap axes from the
# BattleTech study (colour, trail, count, smoke, timing) plus shape. Built to the A5 sheets (contrib/muse/reviews/
# a5_effects_sheets_synthesis.md); every number below is a starting value inside the sheets' testing ranges.
#
# Looks (Claude's calls, vetoable):
#   battery: macro (battery, hbattery: ripple broadside, muzzle blast, smoke ring, white-core shell tracer)
#            auto (autocannon: rapid small tracers), junk (Corsair turret: slow, irregular shell kicks)
#            las (Voidsworn las-turret and las-repeater: short hard-cored laser bolts)
#            plasma_cannon (fast cyan-white pulses), plasma (turbo and heavy turbo: slow, churning bolts and slag)
#            scatter (Corsair scrap scatter gun: a spray of junk tracers)   prism (Ithar shard: glassy prismatic needles)
#            needle (Ithar needle beam turret: a thin prismatic beam)
#   lance:   lance (Voidsworn penance lance)   ion (Hegemony: beam with crawling arcs, blue static wash)
#            pulsar (Ithar: the beam in travelling pulses), nlance (Eclipse: three compression beams)
#            doom (Eclipse corona arc: re-striking violet lightning)
#   torp:    torp (Voidsworn hellfire: armoured bodies, short plumes)   rockets (Corsair rattle-rocket pods: swarms of
#            small sooty rockets)   star (Ithar star torpedo: a little sun)
#   flak:    airbursts in the faction's style (Hegemony picket lasers, Chorus spores, Ithar mirror glints, Deathless
#            gauss shredder streaks, Corsair chaff)
#   bio:     spine (bioplasma: wobbling globs that splash and corrode)   tendril (Acid Thorns: a built bone thorn that sticks, then crumbles)
#   gauss:   coil charge, a visible null slug, a punch-through with an exit spray
#   sq:      guns, bombs, sporeb: craft on a strafing run

const POOLS := preload("res://fx/fx_pool.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const HULL := preload("res://fx/fx_hull.gd")
const SH := preload("res://fx/fx_shaders.gd")
const DEATH := preload("res://fx/fx_death.gd")
const WING := preload("res://render/squadron_wing.gd")
const CRAFT := preload("res://render/squadron_craft.gd")
const FLOOK := preload("res://fx/faction_look.gd")
const THORN := preload("res://fx/fx_acid_thorn.gd")   # issue 1877: Acid Thorns, the Chorus close-in weapon
const SPECIAL := preload("res://fx/fx_special.gd")

const LOOK_BY_ID := {
	"battery": "macro", "hbattery": "macro", "autocannon": "auto", "turret": "las", "laser": "plasma_cannon", "turbo": "plasma",
	"hturbo": "plasma", "scatter": "scatter", "shard": "prism", "lance": "lance", "ion": "ion", "pulsar": "pulsar",
	"doom": "doom", "torp": "torp", "htorp": "rockets", "startorp": "star", "flak": "flak", "spores": "spores",
	"gsentry": "gsentry", "bioplasma": "spine", "tendril": "tendril", "gauss": "gauss", "nlance": "nlance", "guns": "guns", "bombs": "bombs",
	"sporeb": "sporeb", "ram": "ram",
}
const DEFAULT_LOOK := {"battery": "macro", "flak": "flak", "lance": "lance", "torp": "torp", "bio": "spine", "gauss": "gauss", "sq": "guns"}
# weight 1 light, 2 medium, 3 heavy
const WEIGHT_BY_ID := {
	"autocannon": 1, "flak": 1, "scatter": 1, "guns": 1, "turret": 1, "spores": 1, "gsentry": 1,
	"battery": 2, "laser": 2, "turbo": 2, "bioplasma": 2, "shard": 2, "gauss": 2, "ion": 2, "pulsar": 2, "sporeb": 2, "bombs": 2,
	"hbattery": 3, "hturbo": 3, "lance": 3, "nlance": 3, "torp": 3, "htorp": 3, "startorp": 3, "doom": 3, "tendril": 3, "ram": 3,
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
	"pulsar": 0.05, "ion": 0.03, "doom": 0.1, "nlance": 0.12, "gsentry": 0.25, "junk": 0.45, "plasma_cannon": 0.28}
const SHOOTER_RECOIL := {"macro": 0.22, "gauss": 0.20, "torp": 0.25, "rockets": 0.18, "star": 0.25}
const ABSORBED_IMPULSE := 0.12
const PLASMA_HOT := Color(0.86, 0.95, 1.0)
# Projectile and muzzle profiles consumed by the shared STREAK and SPRITE masks.
const BOLT_SHELL := 9
const BOLT_ENERGY := 10
const BOLT_CRYSTAL := 11
const BOLT_SCRAP := 12
const BOLT_PLASMA := 30
const BOLT_BIO := 31
const BOLT_BOMB := 32
const MUZZLE_BALLISTIC := 33
const MUZZLE_ENERGY := 34
const MUZZLE_CRYSTAL := 35
const MUZZLE_BIO := 36
const MELT_SPOTS := 6   # R398: the acid hits a ship remembers for its melt death (fx_shaders MELT_GLOW holds six)
const CRIT_BEAT := 0.12
# Issue 1239 (F2.2): the shot that breaks a shield and still hurts the hull lands its hull fire this much after the
# shield failure's flash, so the two read as two beats instead of one orange smear
const BREAK_HULL_BEAT := 0.08
# F3 (feel pass, Ryan Nov 1: "effects looked very weak, especially at a distance and for smaller ships"): the size every
# effect is drawn at follows the ship (scale_k, a frigate 0.43, a super-dreadnought 2.07), which left a frigate's fire
# and the hits on it a fifth of a capital's. Fire and impact visuals now use at least these scales (geometry such as
# gun mounts and hull marks keeps the true one); the shader floors (fx_shaders px_world) then keep them readable at
# distance. Claude's calls, vetoable.
const VIS_K_FIRE := 0.75
const VIS_K_HIT := 0.85
# F3 round 2 set these under the old 65 px flash count so no hit ever waited on the budget (R186's root cause A). Issue
# 461 replaces them for hull hits with the ladder below; MUZ_PX still sizes muzzle flashes. HIT_PX is kept as the floor
# of the light, flak and bio hits that have no ladder row of their own.
const HIT_PX := [0.0, 34.0, 46.0, 56.0]     # impact flash by weight (light, medium, heavy): rows with no ladder step
const MUZ_PX := [0.0, 20.0, 26.0, 32.0]     # muzzle flash by weight
const HULL_LIGHT := 7.9                    # a hit's light on the plate (just under the 8 that counts as a flash)
# Issue 461, the hit ladder (docs/playbooks/deaths_and_hits.md "The hits, upgraded"): the flash of each family's hit, in
# pixels at 1080 at the battle camera, for a cruiser's gun on a cruiser. Starting points judged by eye in a moving fight,
# not gates (R187, R193). Every bright hit flash books the flash counter by area (fx.flash_at); a refused one keeps its
# size and colour with a slower rise.
# The torpedo's flash is 140 px, not the playbook's 154: a single 154 px flash is over the flash counter's limit on its
# own (15,606 px2 at 1080, a disc about 141 px across), so every torpedo took one of the three flashes a second, and in
# the 20-ship storm gate deaths' core flashes were then turned soft behind them (bench round 2). At 140 px a lone
# torpedo on a cruiser is under the limit and stays bright without spending the budget; a capital's gun or a capital
# target still makes it bigger (and counted).
# The needle (the Glasswright light beam turret) is drawn as a lance burn (family "lance") but sized from the energy row:
# it is a light gun, and a lance-sized burn on it would outrank the macro on the ladder.
const LADDER_PX := {"energy": [0.0, 40.0, 46.0, 52.0], "shell": [0.0, 44.0, 56.0, 64.0], "lance": [0.0, 70.0, 74.0, 78.0],
	"torp": 140.0, "torp_shield": 110.0, "torp_ripple": 156.0}
# ... scaled by the gun that fired (the firing hull's band) and by the ship hit (its band): a frigate's battery on a
# capital is a small bright bite, a battleship's on a frigate a big one.
const GUN_K := {"small": 0.85, "cruiser": 1.0, "capital": 1.2}
const TARGET_K := {"small": 0.8, "cruiser": 1.0, "capital": 1.2}
# Issue 538 (R193, "Flame only"; R208, "push harder"): flame still snuffs out within 0.70 s; thrown matter has its own
# longer life so it reads at camera 170. Seconds, low and high (each piece picks inside its range).
const SPARK_LIFE := Vector2(0.6, 1.6)      # cooling points and trails, independent of flame
const DEBRIS_LIFE := Vector2(3.5, 6.0)     # torn plates tumble and drift well past the flash
const GAS_LIFE := Vector2(2.0, 2.6)        # compact soot clears quickly
const EMBER_LIFE := Vector2(3.5, 7.0)      # cooling coals, no flicker
# How long the hot spot on the plate glows and cools before the mark (fx_breach) is all that is left, by family.
const HEAT_LIFE := {"energy": 1.5, "shell": 2.5, "lance": 3.0, "torp": 4.0, "bio": 2.0}
const FLAME_CAP := 0.70                    # owner ruling: no flame lives longer (deaths_and_hits.md rule 2)
# How far a torpedo hit's light carries (world units; hexes are 17.3 across): about two hexes, so the hulls near it are
# lit for the length of the flash (audit item 11).
const TORP_LIGHT_REACH := 36.0
# R303: only a brief distortion travels beyond the fireball. No visible disc stands off the hull.
const HIT_DISTORT_REACH := 7.0
# The standing scale probe reads this public name. It now measures the brief distortion, not a visible ring.
const BIG_HIT_RING := HIT_DISTORT_REACH
# The baked flash a _burst draws blooms past its pixel floor by about half again at the battle camera (bench round 1:
# a 40 px floor drew about 60 px of lit area), so ladder sizes are asked of it at this share.
const BURST_PX_K := 0.65
const SOFT_FLASH_POWER := 1.25
const FLASH_LIFT_POWER := 0.6
# Issue 281 run 6 (R150): the baked muzzle and impact gas read better about 1.5x bigger than run 5 shipped them.
const WEAPON_GAS_SCALE := 1.5

# Comparison switches are fixed for the process, including the launch timing used by both shot and flight.
static var _old_launch := OS.get_environment("VS_1379_LAUNCH") == "old"
static var _old_casing := OS.get_environment("VS_1379_OLD") == "1"
static var _warned_looks := {}   # not GPU: weapon kinds and ids already reported


static func look_of(kind: String, wid: String, faction: String) -> String:
	var lk: String = LOOK_BY_ID.get(wid, "")
	var fallback := lk.is_empty()
	if fallback:
		lk = DEFAULT_LOOK.get(kind, "macro")
	if lk == "las":
		lk = {"ithar": "needle", "corsair": "junk"}.get(faction, lk)
	if lk == "auto" and faction == "voidsworn":
		lk = "las"
	if kind == "torp" and wid == "torp" and faction == "corsair":
		lk = "rockets"
	if lk == "flak":
		lk = {"hegemony": "pflak", "chorus": "spores", "ithar": "mflak", "deathless": "gflak"}.get(faction, "flak")
	if fallback and (not wid.is_empty() or not DEFAULT_LOOK.has(kind)):
		var key := [kind, wid]
		if not _warned_looks.has(key):
			_warned_looks[key] = true
			push_warning("FX weapon '%s' of kind '%s' is unknown. Using '%s'." % [wid, kind, lk])
	return lk


static func default_shots(lk: String) -> int:
	return {"macro": 4, "auto": 3, "las": 2, "plasma_cannon": 2, "plasma": 2, "scatter": 5, "prism": 3, "needle": 2, "lance": 1, "ion": 1,
		"pulsar": 2, "doom": 1, "torp": 1, "rockets": 2, "star": 1, "spine": 2, "tendril": 2, "gauss": 3, "guns": 3,
		"bombs": 2, "sporeb": 2, "nlance": 3, "junk": 3, "flak": 3, "ram": 1}.get(lk, 2)


# ---------------------------------------------------------------- the volley

# The cosmetic stream is independent of particle counts, frame steps and rules RNG.
# Each weapon keeps its cadence, with a small start delay and clumps and gaps.
static func _volley_rng(fx) -> RandomNumberGenerator:
	var serial: int = int(fx.dstate.get("volley_serial", 0))
	fx.dstate["volley_serial"] = serial + 1
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:volley:%d" % [fx.rng.seed, serial])
	return rng


static func _volley_pattern(rng: RandomNumberGenerator, count: int) -> Array:
	var pattern: Array = []
	var gaps: Array = []
	var span := 0.0
	var gap := rng.randi_range(0, maxi(count - 2, 0))
	for j in maxi(count - 1, 0):
		var step := rng.randf_range(1.65, 2.15) if j == gap else rng.randf_range(0.28, 0.75)
		gaps.append(step)
		span += step
	var accent := rng.randi_range(0, maxi(count - 1, 0)) if rng.randf() < 0.55 else -1
	# In a full salvo, one random gun stands out. One- and two-shot weapons
	# get that accent only sometimes, so a lone heavy stroke stays occasional.
	if accent < 0 and count >= 3:
		accent = gap
	var phase := rng.randf_range(0.0, 0.25)
	var cadence := rng.randf_range(0.85, 1.15)
	for j in count:
		pattern.append({"phase": phase, "size": rng.randf_range(0.82, 1.12) if j != accent else 1.6,
			"power": rng.randf_range(0.72, 1.08) if j != accent else 1.22,
			"spread": rng.randf_range(0.65, 1.5),
			"clump": j > 0 and phase - float(pattern[j - 1]["phase"]) < 0.8})
		if j < gaps.size():
			phase += float(gaps[j]) * float(count - 1) * cadence / span
	return pattern


static func volley(fx, aid: String, kind: String, tid: String, opts: Dictionary) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var r = _volley_entry(fx, aid, kind, tid, opts)
	fx.pend("volley", t0)
	return r


static func _volley_entry(fx, aid: String, kind: String, tid: String, opts: Dictionary) -> Dictionary:
	var A = fx.ship(aid)
	var Tg = fx.ship(tid)
	if A == null or Tg == null:
		var warned: Dictionary = fx.dstate.get_or_add("missing_volley_ships", {})
		for id in [aid, tid]:
			if fx.ship(id) == null and not warned.has(id):
				warned[id] = true
				push_warning("FX volley skipped because ship '%s' is missing" % id)
		var shots: Array = opts.get("shots", [])
		var skipped := shots.size()
		if skipped == 0:
			var faction: String = A.faction if A != null else String(opts.get("faction", "voidsworn"))
			skipped = default_shots(look_of(kind, String(opts.get("weapon_id", "")), faction))
		return {"impacts": [], "fires": [], "done": 0.0, "skipped": skipped}
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
	# R46: both plasma weapons keep the same light blue from muzzle to impact.
	var col: Color = PLASMA_COL if lk in ["plasma", "plasma_cannon"] else fac["weapon"]
	# Doom uses its own deep violet core (issue 1503, was R263 green); the R271 null tracer uses the faction's violet-white.
	if lk == "doom" and fac.has("weapon_core"):
		col = fac["weapon_core"]
	# Issue 461: a hit is sized by the gun that fired it as well as by the ship it lands on
	var gk: float = float(GUN_K.get(DEATH.atlas_band(float(A.hull.L)), 1.0)) if A != null else 1.0
	var tk: float = float(TARGET_K.get(DEATH.atlas_band(float(Tg.hull.L)), 1.0)) if Tg != null else 1.0
	# mounts: the guns that can bear (never backward), from the attach point service (issue 370): the slot's authored
	# muzzles, else the plating the station rays found, else none (the volley's effects are skipped and counted)
	# issue 560 (RULEBOOK 6.17): a muzzle on a turret comes back where the turned barrel will put it, with the time the turret
	# arrives; that shot waits for it ("lead"), so the flash and the tracer start at the turned barrel. Fixed guns have no lead.
	var mounts: Array = []
	if A != null:
		var tl: Vector3 = A.xf().affine_inverse() * to_c
		var heavy: bool = lk in ["lance", "ion", "pulsar", "doom", "nlance", "torp", "star", "gauss"]
		A.hull.turret_clock = T0
		for m in A.hull.guns(int(opts.get("slot", -1)), wid, tl, maxi(shots.size(), 1), heavy):
			if m.is_empty():
				continue
			var mp: Vector3 = m["p"]
			if m["src"] == "ray":
				mp += (m["n"] as Vector3) * 0.15 * ka_geo   # a station ray's hit: the flash sits just off the plate
			elif m["src"] == "bow":
				mp += Vector3(0.3 * ka_geo, 0, 0)           # the bow tube's mouth, just ahead of the plating
			mounts.append({"p": A.to_world(mp), "n": A.dir_world(m["n"]), "tur": int(m.get("tur", -1)),
				"lead": maxf(0.0, float(m.get("arrive", T0)) - T0)})
		if mounts.is_empty():
			# no muzzle on this hull for this weapon and no plating that bears: nothing to draw (logged and counted by
			# the hull); the battle keeps its own timing for the hits (battle.gd: 0.3 s with no impact times)
			return {"impacts": [], "fires": [], "done": 0.0, "skipped": shots.size()}
	else:
		for i in maxi(shots.size(), 1):
			mounts.append({"p": from_c, "n": (to_c - from_c).normalized()})
	var impacts: Array = []
	var fires: Array = []
	var done = 0.0
	var hj = 0
	var total = shots.size()
	var rhythm := _volley_rng(fx)
	var pattern := _volley_pattern(rhythm, total)
	var clusters := {}   # hit section -> last real surface point in this volley
	# Battle events carry an aggregate PD count, while intercepted entries
	# remain false in shots. Never turn a rolled hit into an interception.
	var pd_left := maxi(int(opts.get("pd", 0)), 0)
	var tur_last := {}    # turret -> its last shot's fire time: it holds its aim through that, then trains back to rest
	var froms: Array = []   # each shot's muzzle (world) and turret (-1 for a fixed gun), for the checks
	# issue 1239: each hit's point on the target's shield (shield frame; INF when it never touched the shield), so the
	# battle can aim the shield failure at the shot that broke it; break_k is that hit (-1: none breaks the shield)
	var hit_pts: Array = []
	var shot_pts: Array = []   # each shot's aim point (world), so the checks can follow every projectile to its own shot
	var break_k := int(opts.get("break_k", -1))
	for i in total:
		var hit: bool = bool(shots[i])
		var hd: Dictionary = {}
		var hk := -1
		if hit:
			hd = hits[hj] if hj < hits.size() else {"shield": 0, "hull": 1, "section": "mid", "crit": false}
			hk = hj
			hj += 1
		elif pd_left > 0 and lk in ["torp", "rockets", "star"]:
			hd = {"pd": true}
			pd_left -= 1
		var m: Dictionary = mounts[i % mounts.size()]
		var from: Vector3 = m["p"]
		var tgt = _target(fx, Tg, to_c, from, hit, hd, quad, kt, pattern[i], rhythm, clusters)
		tgt["gk"] = gk
		tgt["tk"] = tk
		shot_pts.append(tgt["p"])
		if hk >= 0:
			hit_pts.append(_shield_lp(tgt))
			if hk == break_k:
				tgt["breaking"] = true
		if bool(opts.get("debug", false)):
			# (tests: where each shot strikes, in world space and relative to the target's centre)
			var tp: Vector3 = Tg.root.global_position if Tg != null else to_c
			print("[fx] shot %d %s from %s hit %s (rel %s) n %s shield %s miss %s sec %s" % [i, lk, str(from), str(tgt["p"]),
				str((tgt["p"] as Vector3) - tp), str(tgt["n"]), str(tgt.get("shield", false)), str(tgt.get("miss", false)),
				str(hd.get("section", ""))])
		var r = _shot(fx, lk, kind, w, i, total, from, m["n"], tgt, T0 + float(m.get("lead", 0.0)), col, fac, A, Tg, hd, ka, kt, faction, pattern[i], rhythm)
		var gun := int(m.get("tur", -1))
		var fire_at := float(r[2])
		if A != null and SHOOTER_RECOIL.has(lk):
			if A.hull_pivot != null:
				var inv: Transform3D = A.xf().affine_inverse()
				var lp := inv * from
				var back := (inv.basis * (from - (tgt["p"] as Vector3))).normalized()
				var recoil: float = _hit_impulse(lk, w, false) * float(SHOOTER_RECOIL[lk])
				fx.later(fire_at, func l_recoil() -> void: A.hit_react(fx, recoil, lp, back, "recoil"))
			if gun >= 0:
				A.hull.turret_fire(gun, fire_at, (0.42 if w >= 3 else 0.30) * ka_geo)
		elif A != null and gun >= 0 and A.hull != null:
			# R412 recoil (Neon on PR 1699): every turreted gun kicks back; the light guns with a shorter stroke
			A.hull.turret_fire(gun, fire_at, TURRET_LIGHT_KICK * ka_geo, false)
		if gun >= 0:
			tur_last[gun] = maxf(float(tur_last.get(gun, -INF)), fire_at)
		froms.append({"p": from, "tur": int(m.get("tur", -1))})
		impacts.append(float(r[0]) - T0)
		fires.append(float(r[2]) - T0)
		done = maxf(done, float(r[1]) - T0)
		if Tg != null and hit:
			Tg.busy_until = maxf(Tg.busy_until, float(r[0]))
	for k in tur_last:
		A.hull.turret_release(int(k), float(tur_last[k]))
	return {"impacts": impacts, "fires": fires, "done": done, "muzzles": froms, "hit_pts": hit_pts, "points": shot_pts}


# Issue 1239: where a shot met the target's shield, in the shield's frame (INF when it never touched it).
static func _shield_lp(tg: Dictionary) -> Vector3:
	if bool(tg.get("shield", false)) and tg.has("local"):
		return tg["local"]
	if tg.has("through"):
		return (tg["through"] as Dictionary)["local"]
	return Vector3.INF


# Where a shot ends: the shield bubble, the hull (section, facing), or past the target for a miss.
static func _target(fx, Tg, to_c: Vector3, from: Vector3, hit: bool, hd: Dictionary, quad: int, kt: float,
		variation: Dictionary = {}, rhythm: RandomNumberGenerator = null, clusters: Dictionary = {}) -> Dictionary:
	if Tg == null:
		var d = (to_c - from).normalized()
		return {"p": to_c, "n": -d, "shield": false, "miss": not hit}
	if not hit:
		var forward := (to_c - from).normalized()
		var side := forward.cross(Vector3.UP).normalized()
		if side == Vector3.ZERO:
			side = Vector3.RIGHT
		var across: Vector3 = side * signf(fx.rng.randf() - 0.5)
		var frame: Transform3D = Tg.xf()
		var inv := frame.affine_inverse()
		var half: Vector3 = Tg.hull.box.size * 0.5
		var support := (inv.basis * across).abs().dot(half)
		var offset: Vector3 = across * (support * fx.rng.randf_range(0.85, 1.65) + 0.25)
		offset.y += fx.rng.randf_range(-0.55, 0.85) * half.y
		var pass_point := to_c + offset
		var local_from := inv * from
		# A rotated or deep hull can cross the line before the target plane. Keep it a clear miss.
		if not Tg.hull.ray(local_from, inv * pass_point - local_from).is_empty():
			var range_to_plane := maxf(from.distance_to(to_c), 0.001)
			var depth := (inv.basis * forward).abs().dot(half)
			var near_scale := maxf(0.25, 1.0 - depth / range_to_plane)
			pass_point = to_c + across * (support + 0.5) / near_scale + Vector3.UP * offset.y
		var path := (pass_point - from).normalized()
		var exit: Vector3 = pass_point + path * Tg.hull.L * fx.rng.randf_range(0.4, 1.2)
		return {"p": exit, "n": -path, "shield": false, "miss": true, "pass": pass_point}
	var on_shield: bool = Tg.shielded and Tg._shield_mat != null and float(hd.get("shield", 0)) > 0.0 and float(hd.get("hull", 0)) <= 0.0
	var sec: int = {"eng": 0, "mid": 1, "prow": 2}.get(String(hd.get("section", "")), -1)
	var inv: Transform3D = Tg.xf().affine_inverse()
	var view := Vector3.ZERO
	if fx.camera != null and is_instance_valid(fx.camera):
		view = (inv.basis * (fx.camera.global_position - to_c)).normalized()
	var hp: Dictionary = Tg.hull.hit_point(inv * from, sec, quad, view)
	if rhythm != null:
		# Scatter on real plating, clustered by the rolled section. A ray that
		# misses or crosses a section boundary keeps the original valid point.
		var anchor: Dictionary = clusters.get(sec, hp) if bool(variation.get("clump", false)) else hp
		var offset := Vector3(rhythm.randf_range(-0.06, 0.06) * Tg.hull.L,
			rhythm.randf_range(-0.16, 0.16) * Tg.hull.H, rhythm.randf_range(-0.06, 0.06) * Tg.hull.W)
		var normal: Vector3 = anchor["n"]
		offset = (offset - normal * offset.dot(normal)) * float(variation.get("spread", 1.0))
		var aimed: Dictionary = Tg.hull.ray(inv * from, (anchor["p"] as Vector3) + offset - inv * from)
		if not aimed.is_empty() and Tg.hull.section_of(aimed["p"].x) == Tg.hull.section_of(hp["p"].x):
			hp = aimed
		clusters[sec] = hp
	if on_shield:
		var sp: Dictionary = Tg.shield_point(from, hp["p"])
		return {"p": sp["p"], "n": sp["n"], "shield": true, "local": sp["local"], "miss": false}
	# shots that went through a shield and still hurt the hull also light the bubble on the way in
	var out = {"p": Tg.to_world(hp["p"]), "n": Tg.dir_world(hp["n"]), "lp": hp["p"], "ln": hp["n"], "shield": false, "miss": false}
	if Tg.shielded and Tg._shield_mat != null and float(hd.get("shield", 0)) > 0.0:
		var sp2: Dictionary = Tg.shield_point(from, hp["p"])
		out["through"] = sp2
	return out


# One shot: fire, travel, impact. Returns [impact time, end time, fire time] on the effect clock.
static func _shot(fx, lk: String, kind: String, w: int, i: int, n: int, from: Vector3, mn: Vector3, tg: Dictionary, T0: float,
		col: Color, fac: Dictionary, A, Tg, hd: Dictionary, ka: float, kt: float, faction := "voidsworn",
		variation: Dictionary = {}, rhythm: RandomNumberGenerator = null) -> Array:
	if rhythm == null:
		rhythm = _volley_rng(fx)
	var beat: float = float(variation.get("phase", i))
	var size: float = float(variation.get("size", 1.0))
	var power: float = float(variation.get("power", 1.0))
	var spread: float = float(variation.get("spread", 1.0))
	ka *= size
	col = Color(col.r * power, col.g * power, col.b * power, col.a)
	var to: Vector3 = tg["p"]
	var dv = to - from
	var dist = maxf(dv.length(), 0.01)
	var dir = dv / dist
	var tf = T0
	var ti = T0
	var tend = T0
	match lk:
		"macro":
			tf = T0 + 0.2 + beat * float(fx.timing.get("ripple", 0.08))
			_muzzle(fx, from, dir, tf, col, ka * (1.25 if w >= 3 else 1.0), (MUZ_PX[clampi(w, 1, 3)] + 4.0) * size, MUZZLE_BALLISTIC, A, true, w)
			if w >= 3:
				# Hot gas bleeds from the barrel mouth after the muzzle flash.
				_weapon_gas(fx, from, dir, tf + 0.19, 2.2 * ka, "muzzle", 0.36, col, 0.85,
					dir * 1.4 * ka, 0.5, 1.0, 14.0 * size, A)
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * fx.unit
			ti = tf + dist / spd
			fx.flight_streak(from, tf, dist / spd, col, 8.0 * power, 3.2 * ka, 0.60 * ka * (1.2 if w >= 3 else 1.0), BOLT_SHELL, dir * spd, 0.0, 0.0, (4.0 if w >= 3 else 3.4) * size, 26.0 * size)
			fx.light(from + mn * 1.5 * ka, tf, 0.22, 7.8, col.lerp(Color.WHITE, 0.4), 0)
			fx.shake(tf, 0.03, from)
		"auto":
			tf = T0 + 0.05 + beat * 0.22
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 1.3 * fx.unit
			var burst := _volley_pattern(rhythm, 4)
			for b in 4:
				var pulse: Dictionary = burst[b]
				var bk: float = ka * float(pulse["size"])
				var tb = tf + float(pulse["phase"]) * 0.05
				var jit = fx.rdir() * 0.3 * kt * spread
				# Four short tracers in a tight line give the autocannon its chatter.
				_muzzle(fx, from, dir, tb, col, bk, 14.0 * size * float(pulse["size"]), MUZZLE_BALLISTIC, A)
				fx.flight_streak(from, tb, dist / spd, col, 9.0 * power * float(pulse["power"]), 4.0 * bk, 0.4 * bk, BOLT_SHELL, (dir + jit / dist) * spd, 0.0, 0.0, 3.6 * size * float(pulse["size"]), 18.0 * size * float(pulse["size"]))
				if faction == "corsair":
					_burst(fx, from + dir * 0.8 * ka, dir, tb + 0.02, 2.0 * ka, "cool", 0.4, col, 0.5, 0.0, dir * 2.0, 0.4)
			fx.light(from + mn * 1.2 * ka, tf, 0.25, 5.5, col, 1)
			ti = tf + dist / spd
		"junk":
			tf = T0 + 0.10 + beat * 0.19
			var spd: float = 145.0 * fx.unit
			_muzzle(fx, from, dir, tf, col, ka, 21.0 * size, MUZZLE_BALLISTIC, A, true, w)
			_burst(fx, from + dir * ka, dir, tf + 0.035, 2.6 * ka, "cool", 0.52, col.darkened(0.65), 0.65, 0.0, dir * 2.0)
			fx.flight_streak(from, tf, dist / spd, col, 9.0, 2.1 * ka, 0.65 * ka, BOLT_SCRAP, dir * spd, 0.0, 0.0, 4.8 * size, 13.0 * size)
			ti = tf + dist / spd
		"las":
			tf = T0 + 0.05 + beat * 0.12
			var spd = 280.0 * fx.unit
			# round 2: a hard, faction-coloured bolt with a white core, long and fat enough to read as a laser at battle zoom
			_muzzle(fx, from, dir, tf, col, ka, (MUZ_PX[1] + 2.0) * size, MUZZLE_ENERGY, A)
			fx.flight_streak(from, tf, dist / spd, col, 11.0, 5.5 * ka, 0.7 * ka, BOLT_ENERGY, dir * spd, 0.0, 0.0, 4.6 * size, 30.0 * size)
			ti = tf + dist / spd
		"plasma_cannon":
			tf = T0 + 0.06 + beat * 0.085
			var spd: float = 230.0 * fx.unit
			_muzzle(fx, from, dir, tf, col, ka, 19.0 * size, MUZZLE_ENERGY, A)
			_sprite_bolt(fx, from, tf, dist / spd, col, 2.65, 1.45 * ka, BOLT_PLASMA, dir * spd, 16.0 * size)
			ti = tf + dist / spd
		"plasma":
			tf = T0 + 0.12 + beat * 0.24
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 0.55 * fx.unit
			var sz = (1.9 if w >= 3 else 1.5) * ka
			_muzzle(fx, from, dir, tf, col, sz, (30.0 if w >= 3 else 24.0) * size, MUZZLE_ENERGY, A)
			_sprite_bolt(fx, from, tf, dist / spd, col, 2.8, sz * 1.4, BOLT_PLASMA, dir * spd, (24.0 if w >= 3 else 19.0) * size)
			# heat shimmer trailing the bolt
			for s in 3:
				fx.spr(from + dir * dist * (0.25 + s * 0.25), tf + dist / spd * (0.25 + s * 0.25), 0.4, col, 0.3, sz * 0.6, sz * 1.4, 18)
			fx.light(from + dir * 2.0, tf, dist / spd, 3.0, col, 1)
			ti = tf + dist / spd
		"scatter":
			tf = T0 + 0.1 + beat * 0.1
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 1.2 * fx.unit
			_muzzle(fx, from, dir, tf, col, ka * 0.7, MUZ_PX[2] * size, MUZZLE_BALLISTIC, A, true, w)
			fx.light(from + mn * 1.2 * ka, tf, 0.18, 6.5, col, 0)
			var burst := _volley_pattern(rhythm, 6)
			for b in 6:
				var pulse: Dictionary = burst[b]
				var bk: float = ka * float(pulse["size"])
				var d2 = (dir + fx.rdir() * 0.06 * spread).normalized()
				fx.flight_streak(from, tf + float(pulse["phase"]) * 0.006, dist / spd, col, 9.0 * power * float(pulse["power"]), 3.0 * bk, 0.38 * bk, BOLT_SCRAP, d2 * spd, 0.0, 0.0, 2.8 * size * float(pulse["size"]), 12.0 * size * float(pulse["size"]))
			ti = tf + dist / spd
		"prism":
			tf = T0 + 0.08 + beat * 0.1
			var spd = 220.0 * fx.unit
			_muzzle(fx, from, dir, tf, col, ka, MUZ_PX[2] * size, MUZZLE_CRYSTAL, A)
			var burst := _volley_pattern(rhythm, 3)
			for b in 3:
				var pulse: Dictionary = burst[b]
				var bk: float = ka * float(pulse["size"])
				var d2 = (dir + fx.rdir() * 0.02 * spread).normalized()
				fx.flight_streak(from, tf + float(pulse["phase"]) * 0.03, dist / spd, col, 8.5 * float(pulse["power"]), 3.5 * bk, 0.32 * bk, BOLT_CRYSTAL, d2 * spd, 0.0, 0.0, 3.2 * size * float(pulse["size"]), 24.0 * size * float(pulse["size"]))
			ti = tf + dist / spd
		"needle":
			tf = T0 + 0.1 + beat * 0.25
			_beam_charge(fx, from, dir, tf, minf(0.10, tf - T0), col, ka, lk)
			fx.rib(from, dir, dist, tf, 0.35, col, 1.6, 0.35 * ka, 0.3 * ka, SH.RIB_NEEDLE)
			fx.spr(from, tf, 0.15, col, 2.6, 0.65 * ka, 0.8 * ka, 16, Vector3.ZERO, 0.0, 0.0, 0.0, 16.0)
			_beam_ends(fx, from, to, tf, 0.35, col, ka)
			fx.light(from + mn * 1.2 * ka, tf, 0.35, 5.0, col, 1)
			ti = tf + 0.03
			tend = tf + 0.35
		"nlance":
			var charge := 0.29
			var dur := 0.32
			tf = T0 + charge + beat * 0.36
			_beam_charge(fx, from, dir, tf, charge, col, ka, lk)
			fx.rib(from, dir, dist, tf, dur, col, 1.8, 3.5 * ka, 1.5 * ka, SH.RIB_NULL_LANCE)
			_beam_ends(fx, from, to, tf, dur, col, ka)
			_beam_lenses(fx, from, dir, dist, tf, dur, ka, true)
			fx.light(from + mn * ka, tf, dur, 6.0, col, 1)
			ti = tf + 0.03
			tend = tf + dur
		"lance", "ion", "pulsar", "doom":
			var charge = float(fx.timing.get("charge", 0.25)) if lk != "doom" else 0.35
			tf = T0 + charge + beat * 0.45
			var dur = float(fx.timing.get("lance", 0.7)) if lk != "pulsar" else 0.45
			var wd = (2.4 if lk != "doom" else 1.6) * ka * (1.15 if w >= 3 else 1.0)
			if lk == "doom":
				# A visible charging corona stays rooted on the actual emitter.
				fx.spr(from, tf - charge, charge, col.lerp(Color.WHITE, 0.2), 9.0, 0.6 * ka, 5.0 * ka, 12, Vector3.ZERO, 0.0, 0.0, 0.0, 30.0)
				fx.light(from + dir + mn * ka, tf - charge, charge, 6.0, col, 2)
				fx.ring(from, dir, tf - charge, charge, col, 1.8, 0.5 * ka, 1.8 * ka, 3, 0.0, 0.0, 32.0)
				fx.spr(from, tf - charge * 0.55, charge * 0.55, col, 2.5, 0.6 * ka, 1.6 * ka, 12, Vector3.ZERO, 0.0, 0.0, 0.0, 26.0)
			else:
				_beam_charge(fx, from, dir, tf, charge, col, ka, lk)
				fx.light(from + dir + mn * ka, tf - charge, charge, 6.0, col, 2)
			var rk: int = {"lance": SH.RIB_LANCE, "ion": SH.RIB_ION, "pulsar": SH.RIB_PULSAR, "doom": 10}[lk]
			_burst(fx, from, dir, tf, 4.5 * ka, "flash", 0.28, col, 3.6, 22.0)
			fx.rib(from, dir, dist, tf, dur, col, 2.4 if lk == "doom" else 1.65, wd, wd * 0.85, rk)
			_beam_ends(fx, from, to, tf, dur, col, ka, lk == "doom")
			fx.light(from + dir * 1.5 + mn * ka, tf, dur, 6.0, col, 1)
			if lk == "doom":
				_doom_shed(fx, from, to, tf, dur, faction, ka)
			elif lk == "pulsar":
				_harmonics(fx, from, dir, dist, tf, dur, col, ka)
			else:
				_beam_lenses(fx, from, dir, dist, tf, dur, ka, false)
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
				var slide_room := 0.30 if lk == "torp" and not _old_launch else 0.0   # torp: room for the 0.7 s slide after the order (the old arm keeps main's timing)
				var vent = 0.45 + slide_room + beat * (0.35 if lk == "torp" else 0.12)
				tf = T0 + vent
				var spd = (62.0 if lk == "torp" else (85.0 if lk == "rockets" else 55.0)) * fx.unit
				var tt = dist / spd + 0.25
				ti = tf + tt
				ti = _launch(fx, lk, from, mn, to, tf, ti, col, fac, ka, i, bool(hd.get("pd", false)), A, rhythm, spread, faction)
				tend = ti
		"flak", "pflak", "spores", "mflak", "gflak", "gsentry":
			var cadence := 0.19 if lk == "gsentry" else 0.12 if lk == "flak" else 0.07
			tf = T0 + 0.03 + beat * cadence
			ti = _flak(fx, lk, from, dir, to, tf, col, ka, kt, rhythm, spread, A)
			tend = ti + 0.4
		"spine":
			var wind = 0.3
			tf = T0 + wind + beat * 0.145
			var spd = float(fx.timing.get("shell_speed", SHELL_SPEED)) * 0.5 * fx.unit
			fx.spr(from, tf - wind, wind, col, 1.4, 0.4 * ka, 1.6 * ka, 22)
			_muzzle(fx, from, dir, tf, col, ka, 22.0, MUZZLE_BIO, A)
			for s in 5:
				fx.flight_streak(from, tf, 0.4, col, 2.0, 0.08, 0.12 * ka, 6, (dir + fx.rdir() * 0.4).normalized() * 8.0 * ka, 1.5)
			var gsz = 1.5 * ka
			var ft = dist / spd
			_sprite_bolt(fx, from, tf, ft, col, 2.35, gsz, BOLT_BIO, dir * spd, 15.0)
			# dripping trail
			for s in 8:
				var u = (s + 0.5) / 8.0
				fx.flight_streak(from + dir * dist * u, tf + ft * u, 0.6, col, 1.6, 0.06, 0.1 * ka, 6, Vector3(0, -3, 0) + fx.rdir() * 1.5, 1.0)
			fx.light(from + dir, tf, ft, 1.6, col, 1)
			ti = tf + ft
		"tendril":
			# Acid Thorns (issue 1877, R437): one built bone thorn a shot (fx_acid_thorn.gd); the old tendril lash is gone
			tg["mark_look"] = "thorn"  # the etched burn, no drawn spines: the built thorn is the spine (issue 1877)
			var cr: Array = THORN.shot(fx, from, mn, to, T0, beat, col, ka, A, tg, Tg)
			tf = cr[0]
			ti = cr[1]
			tend = cr[2]
		"gauss":
			var heavy = w >= 3
			var wind = 0.75 if heavy else 0.25
			tf = T0 + wind + beat * 0.18
			# capacitor coils light breech to muzzle in steps
			for s in 4:
				fx.spr(from - dir * (1.6 - s * 0.5) * ka, tf - wind + s * wind / 4.0, wind - s * wind / 4.0, col, 2.2, 0.5 * ka, 0.9 * ka, 22)
			fx.light(from, tf - wind, wind, 2.0, col, 2)
			# A hard muzzle flash and displaced-gas ring precede one long tracer.
			fx.spr(from, tf, 0.07, Color(0.85, 0.95, 1.0), 12.0, 1.2 * ka, 2.2 * ka, 0, Vector3.ZERO, 0.0, 0.0, 0.0, MUZ_PX[3] * size)
			fx.ring(from + dir * 0.5 * ka, dir, tf, 0.4, Color(0.8, 0.95, 1.0), 1.8, 0.5 * ka, 4.0 * ka, 3, 0.0, 0.0, 44.0 if heavy else 34.0)
			fx.dst(from + dir, tf, 0.3, 1.0 * ka, 6.0 * ka, 0, 1.2)
			_gauss_wake(fx, from, to, tf, col, ka)
			fx.light(from + mn * 1.2 * ka, tf, 0.18, 7.8, Color(0.85, 0.95, 1.0), 0)
			fx.shake(tf, 0.08, from)
			ti = tf + dist / (650.0 * fx.unit)
		"guns", "bombs", "sporeb":
			tf = T0 + beat * 0.15
			ti = _strafe(fx, lk, from, to, tf, col, fac, ka, kt, i, faction, rhythm, spread, tg.get("pass", null))
		_:
			tf = T0 + 0.3
			ti = T0 + 0.3
	if tend < ti:
		tend = ti
	if not bool(hd.get("pd", false)):
		if not bool(tg.get("miss", false)):
			_impact(fx, lk, w, Tg, tg, ti, col, dir, hd, kt, tend - ti)
		else:
			tend = maxf(tend, _miss_fade(fx, lk, Tg, tg, from, tf, ti, col, dir, kt))
	return [ti, tend + 0.3, tf]


# Shared pre-fire beat. Focus just in front of the authored muzzle so the rings
# never charge from inside the barrel. The bright focus still goes through fx.spr's flash budget.
static func _beam_charge(fx, from: Vector3, dir: Vector3, fire: float, charge: float, col: Color, k: float, look: String) -> void:
	if charge <= 0.0:
		return
	var focus := from + dir * 0.22 * k
	var needle := look == "needle"
	var ring_count := 1 if needle or look == "ion" else (3 if look == "nlance" else 2)
	var ring_kind := SH.RING_HARMONIC if look in ["pulsar", "needle"] else 3
	for j in ring_count:
		var life := charge * (1.0 - float(j) * 0.19)
		var col_k := 0.84 + float(j) * 0.14
		fx.ring(focus + dir * float(j) * 0.42 * k, dir, fire - life, life, col, col_k,
			(1.75 if needle else 3.6) * k, 0.45 * k, ring_kind, -1.0 * k, 0.0, 0.0)
	var gather := charge * (0.9 if needle else 0.72)
	fx.spr(focus, fire - gather, gather, col, 3.2 if needle else 5.4, 0.45 * k,
		(1.4 if needle else 2.7) * k, 12, Vector3.ZERO, 0.0, 0.0, 0.0, 15.0 if needle else 26.0)


# Cost is bounded and fx.dst honors the existing distortion and comfort settings.
# Glasswrights use emitted spectral edges instead of sampling or bending the scene (R421).
static func _beam_lenses(fx, from: Vector3, dir: Vector3, length: float, fire: float, life: float, k: float, null_lance: bool) -> void:
	var count := 5 if null_lance else 3
	for j in count:
		var u := (float(j) + 0.5) / float(count)
		var lag := u * 0.03
		var span := maxf(5.0 * k, length / float(count) * 1.3)
		fx.dst(from + dir * length * u, fire + lag, life - lag, span * 0.8, span, SH.DISTORT_BEAM, 0.23 if null_lance else 0.13)


static func _harmonics(fx, from: Vector3, dir: Vector3, length: float, fire: float, life: float, col: Color, k: float) -> void:
	var travel := life * 0.62
	for j in 3:
		# Three staggered wavefronts never travel past the beam's own contact.
		fx.ring(from, dir, fire + life * 0.16 * float(j), travel, col, 1.25,
			3.8 * k, 5.2 * k, SH.RING_HARMONIC, length / travel)


# R271 replaces the two-frame/26 px null shot. One head moves at the original
# ballistic speed. Its bright history fades over 0.52 s; ionisation over 0.70 s.
static func _gauss_wake(fx, from: Vector3, to: Vector3, t: float, col: Color, k: float, flight_override := -1.0) -> void:
	var dv := to - from
	var dist := maxf(dv.length(), 0.01)
	var flight: float = flight_override if flight_override > 0.0 else dist / (650.0 * fx.unit)
	fx.null_trace(from, to, t, flight, col, k)
	if fx.quality == "max":
		for j in 4:
			var u := (float(j) + 0.5) / 4.0
			fx.dst(from + dv * u, t + flight * u, 0.18, 0.45 * k, 1.8 * k, 1, 0.18)


# Small drifting motes and local heat lenses follow the discharge downstream.
# The heavy contact flare and the actual hull scorch remain in _beam_burn.
static func _doom_shed(fx, from: Vector3, to: Vector3, t: float, life: float, faction: String, k: float) -> void:
	var dv := to - from
	for j in 8:
		var u := (float(j) + 0.5) / 8.0
		var p: Vector3 = from + dv * u
		fx.dst(p, t + u * 0.03, life, 8.0 * k, 10.0 * k, 1, 0.08)
		for beat in (3 if fx.quality == "max" else 1):
			var at: float = t + u * 0.03 + beat * life / 3.0
			var vel: Vector3 = dv.normalized() * 3.0 + fx.rdir() * 2.0
			fx.spark(p, at, 0.4 + u * 0.2, faction, 1.5, 0.04, 0.07 * k, vel, 1.2, 4.0, 0.0, fx.SparkRole.WEAPON)


# End flares and a quiet cooling glow belong to the beam itself. The real
# impact recipe still owns the flash, wound and thrown matter at the target.
static func _beam_ends(fx, from: Vector3, to: Vector3, t: float, life: float, col: Color, k: float, eclipse := false) -> void:
	if eclipse:
		for j in 2:
			var p: Vector3 = from if j == 0 else to
			var px := 24.0 if j == 0 else 42.0
			var lead := 0.0 if j == 0 else 0.03
			fx.spr(p, t + lead, life - lead, col, 2.0 if j == 0 else 3.0, 1.2 * k, 1.8 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, px)
			fx.spr(p, t + life - 0.05, 0.45, col, 1.5, 2.0 * k, 0.4 * k, 18, Vector3.ZERO, 0.0, 0.0, 0.0, px)
		return
	for p in [from, to]:
		_beam_end(fx, p, t, life, col, k)


static func _beam_end(fx, p: Vector3, t: float, life: float, col: Color, k: float) -> void:
	fx.spr(p, t, life, col, 2.8, 1.2 * k, 1.5 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, 16.0)
	fx.spr(p, t + life - 0.05, 0.30, col, 1.4, 1.8 * k, 0.4 * k, 18, Vector3.ZERO, 0.0, 0.0, 0.0, 16.0)


# Weapon bursts use leap 1's atlas, flow interpolation, thickness lighting and
# soft intersections. Only the palette and aspect differ from the death recipe.
# Keep one derived shader per FX session, with the same three cached atlas maps.
static func _weapon_shader(fx, routed := false) -> Shader:
	if not fx.dstate.has("weapon_flipbook_shader"):
		var code: String = SH.patch(SH.DEATH_FLIPBOOK, "uniform float intensity = 1.0;",
			"uniform float intensity = 1.0;\nuniform vec3 weapon_tint = vec3(0.9, 0.6, 0.3);\nuniform float opacity = 1.0;\nuniform float aspect = 1.0;\nuniform float spin = 0.0;\nuniform float vent = 0.0;\nuniform float vent_cone = 1.0;\nuniform float hot = 0.0;\nuniform float looping = 0.0;")
		code = SH.patch(code, "vec2 up = mix(vec2(0.0, 1.0), axis, directional);",
			"vec2 up = mix(vec2(sin(spin), cos(spin)), axis, directional);")
		# Issue 1558 item 1: DEATH_FLIPBOOK builds the quad from `local` (pic_shape, pic_spin) since Nov 17, so the old
		# "up * VERTEX.y" target matched nothing and every vent jet, muzzle jet and torpedo plume drew as a round puff.
		code = SH.patch(code, "+ up * local.y)", "+ up * local.y * aspect)")
		# Issue 281 run 5: the baked muzzle/impact gas plays all 16 frames in order (bright core at birth, then it cools
		# and thins) instead of the death flash's skip-the-first-three-frames ramp.
		code = SH.patch(code, "float frame = mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);",
			"float frame = hot > 0.5 ? age * 15.0 : mix(age * 15.0, 3.0 + sqrt(age) * 12.0, plasma);")
		code = SH.patch(code, "vec3 core = mix(vec3(0.65, 0.76, 0.93), vec3(0.9, 0.83, 0.68), age);",
			"vec3 core = mix(weapon_tint, vec3(0.9), age * 0.45);")
		# Issue 281 Cone B: the vent gas cools toward the weapon colour and darkens with age, so the cone reads as hot
		# exhaust instead of a flat pale blob. The flash keeps its own palette (vent is 0 for every other kind).
		code = SH.patch(code, "vec3 smoke = mix(vec3(0.12, 0.085, 0.18), vec3(0.42, 0.36, 0.50), lit);",
			"vec3 smoke = mix(vec3(0.12, 0.085, 0.18), vec3(0.42, 0.36, 0.50), lit);\n\tif (vent > 0.5 && vent_cone > 0.5) {\n\t\tvec3 tinted = smoke * clamp(0.35 + 1.25 * weapon_tint, 0.0, 1.10);\n\t\tsmoke = mix(smoke, tinted, 0.65) * mix(0.85, 0.50, age);\n\t}")
		code = SH.patch(code, "ALPHA = gas.a * fade * soft", "ALPHA = gas.a * fade * soft * opacity * mix(1.0, 0.55, fx_calm)")
		# The atlas_rect above already frames the gas inside the baked cell. An extra UV crop (0.36 x 0.48) sampled only
		# the gas CORE, so every muzzle and impact burst lost its soft edge and drew as a pale translucent square (#232).
		# Sample the whole framed cell instead and grow the quad by the same 1/0.46, so the gas keeps the on-screen size
		# the F3 pixel floor was tuned for.
		code = SH.patch(code, "float size = max(extent, px_world(min_pixels, -view_c.z, PROJECTION_MATRIX));",
			"float size = max(extent, px_world(min_pixels, -view_c.z, PROJECTION_MATRIX)) * 1.45;")
		code = SH.patch(code, "float age = clamp(elapsed / max(lifetime, 0.001), 0.0, 1.0);",
			"float age = looping > 0.5 ? 0.15 + 0.55 * (0.5 + 0.5 * sin(elapsed * 9.0 * mix(1.0, 0.35, fx_calm) + spin)) : clamp(elapsed / max(lifetime, 0.001), 0.0, 1.0);")
		code = SH.patch(code, "float fade = 1.0 - smoothstep(0.70, 1.0, age);", "float fade = mix(1.0 - smoothstep(0.70, 1.0, age), pow(clamp(UV.y, 0.0, 1.0), 0.7), looping);")
		code = SH.patch(code, "(elapsed < lifetime ? 1.0 : 0.0)", "(elapsed < lifetime || looping > 0.5 ? 1.0 : 0.0)")

		fx.dstate["weapon_flipbook_shader"] = fx.mat(code, 2, "#define COMPAT\n" if fx.compat else "").shader
		fx.dstate["weapon_flipbook_code"] = code
	if routed:   # issue 353, bench only: a candidate bake (fx_death.route_material) keeps its baked colour
		return fx.mat(fx.dstate["weapon_flipbook_code"], 2, ("#define COMPAT\n" if fx.compat else "") + "#define ROUTE_BAKED\n").shader
	return fx.dstate["weapon_flipbook_shader"]


static func _burst(fx, p: Vector3, axis: Vector3, T: float, size: float, kind: String, life: float, col: Color,
		strength := 3.0, px := 0.0, velocity := Vector3.ZERO, opacity := 1.0, aspect := 1.0, gun := true,
		book := true) -> void:
	var seed: float = fx.rng.randf()
	fx.later(T, func l_burst() -> void:
		var power := strength
		var duration := life
		var is_flash: bool = kind == "flash" and strength >= fx.FLASH_I
		# Book the drawn envelope with bloom, at the camera the player has when the burst appears.
		var refused := false
		if is_flash:
			if book:
				refused = not fx.flash_at(p, T, size / BURST_PX_K, px / BURST_PX_K, life, gun)
			else:
				# issue 2194: a pulse kept out of the budget still softens under Reduce Flashing
				fx.flash_lift = false
				refused = fx.reduce_flashing
		if refused:
			power = FLASH_LIFT_POWER if fx.flash_lift else SOFT_FLASH_POWER
			duration = maxf(life, 1.2 if fx.flash_lift else 0.4)
		var node := DEATH.flipbook(fx, p, axis, size * fx.unit, kind, duration, velocity, power, "small", null, false, false, null, "weapon") as MeshInstance3D
		node.name = "fx_weapon_" + kind
		# The vent helper offsets its atlas to put the tip on the sampled surface.
		var mat: ShaderMaterial = node.material_override
		mat.shader = _weapon_shader(fx, mat.has_meta("route"))
		mat.set_shader_parameter("born", T)
		if is_flash:
			mat.set_shader_parameter("calm_intensity", SOFT_FLASH_POWER)
			mat.set_shader_parameter("soft_flash", 1.0 if fx.reduce_flashing else 0.0)
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
	var rel := "weapons/" + kind + "/" + kind + "_"
	if DEATH.route_texture(fx, rel + "color.png") != null:
		var r: ShaderMaterial = DEATH.route_material(fx, SH.DEATH_FLIPBOOK, rel)
		r.shader = _weapon_shader(fx, true)
		return r
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
		var mi: MeshInstance3D = fx.picture("wgas|" + kind, func() -> ShaderMaterial: return _weapon_gas_material(fx, kind), "fx_weapon_" + kind)
		mi.extra_cull_margin = size * 3.0 + velocity.length() * life
		var m := mi.material_override as ShaderMaterial
		m.set_shader_parameter("born", T)
		m.set_shader_parameter("lifetime", life)
		m.set_shader_parameter("extent", size * fx.unit)
		if m.has_meta("route"):
			# Issue 353, bench only: today's impact gas fills 52 of its 256 pixel cell, a candidate about four fifths, so
			# the quad shrinks by the same share and the gas keeps today's size on screen (size is #352's call).
			m.set_shader_parameter("extent", size * fx.unit * 0.25)
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
		mi.global_position = p + axis * size * 0.42 * directional
		fx.later(T + life + 0.1, fx.free_picture.bind(weakref(mi), int(mi.get_meta("pic_gen"))))
	)


# The review capture draws the pre-Cone-B look ("today") for its before stills. The game never sets this.
static func _old_look(fx) -> bool:
	return String(fx.vent_look) == "today"


# Issue 281 Cone B (Ryan's pick, R145): one place for every weapon vent puff (muzzle, hull hit, launch), so
# the look reads the same everywhere. The shipped look is a tight forward jet of hot gas and sparks along the barrel,
# so it never reads as a flat pale blob. "today" draws the pre-Cone-B baked gas cell and is only used to shoot the
# review's before stills.
# Run 4 (Ryan, Nov 9): the first cone still left a pale ball four times the old puff. Each step is now about a third of
# today's width at the barrel and thins to nothing down the barrel, with a shorter life and lower opacity, so the muzzle
# keeps a bright forward flash and a few sparks with almost no ball, and a hull hit is a tight jet on the surface normal.
# w is the weapon weight (1 light, 2 medium, 3 heavy), kept so the muzzle callers pass one shape.
static func _vent(fx, p: Vector3, axis: Vector3, T: float, size: float, life: float, col: Color, strength := 0.8,
		velocity := Vector3.ZERO, opacity := 0.55, aspect := 1.0, w := 2, src = null, hull_contact := false, with_sparks := true) -> void:
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
	if with_sparks:
		_impact_sparks(fx, p, axis, T + 0.02, size * 0.35, _spark_faction(src), 10, 18.0,
			fx.SparkRole.HULL if hull_contact else fx.SparkRole.WEAPON)


# Without a ship (for example a bench world-point impact), use the default faction palette.
static func _spark_faction(ship) -> String:
	return ship.faction if ship != null else FLOOK.FALLBACK


static func _spark_size(k: float) -> float:
	return clampf(sqrt(maxf(k, 0.0)), 0.7, 1.35)


static func _impact_sparks(fx, p: Vector3, axis: Vector3, T: float, k: float, faction: String,
		count := 10, speed := 14.0, role := 0) -> void:
	if fx.quality == "low": return
	var scale := _spark_size(k)
	var n := maxi(1, roundi(count * scale))
	var amount: int = n if fx.quality == "max" else maxi(3, n / 2)
	for j in amount:
		var v: Vector3 = fx.rcone(axis, 0.8) * fx.rng.randf_range(speed * 0.35, speed) * k * fx.unit
		var drag: float = fx.rng.randf_range(2.0, 5.0)
		var life: float = fx.rng.randf_range(0.25, 0.60) * scale
		var t: float = T + fx.rng.randf() * 0.035
		# Keep the old point's variation draw in the stream, now for shutter instead of a second sprite.
		var shutter: float = lerpf(0.05, 0.105, fx.rng.randf()) * scale
		fx.spark(p, t, life, faction, 2.1, shutter, 0.04 * k, v, drag, 0.0, 0.0, role)


# ---------------------------------------------------------------- fire

static func _sprite_bolt(fx, p: Vector3, t: float, life: float, col: Color, power: float,
		size: float, profile: int, vel: Vector3, px: float) -> void:
	fx.spr(p, t, life, col, power, size, size, profile, vel, 0.0, 0.0, 0.0, px)


# One muzzle kit. Actual cartridge blasts keep the approved gas. Light guns and
# smoke-free emitters share a counted core and a dimmer material-specific sheath.
static func _muzzle(fx, p: Vector3, dir: Vector3, t: float, col: Color, k: float, px: float,
		profile: int, src = null, heavy_gas := false, w := 2) -> void:
	if heavy_gas:
		_muzzle_blast(fx, p, dir, t, col, k, px, w, src)
		return
	var organic := profile == MUZZLE_BIO
	var forward := profile == MUZZLE_BALLISTIC or organic
	var offset: Vector3 = dir * k * (0.65 if forward else 0.22) * fx.unit
	var lifetime := 0.23 if organic else 0.16
	var core_life := 0.12 if forward else 0.15
	fx.record_spawn(src, p, true)
	# issue 2194: keep the bright core, but a light gun's muzzle pulse must not spend the flash budget that the
	# impact and death cores need (autocannon and flak fired four to six pulses a volley against a cap of three)
	_burst(fx, p + dir * k * 0.28 * fx.unit, dir, t, 1.55 * k, "flash", core_life, col,
		2.5 if organic else 4.2, px, Vector3.ZERO, 1.0, 1.0, true, false)
	fx.spr(p + offset, t, lifetime, col, 1.15, 1.65 * k, 2.55 * k, profile,
		dir * (2.0 * k * fx.unit if forward else 0.0), 0.0, 0.0, 0.0, px)
	if profile != MUZZLE_BALLISTIC:
		fx.light(p + offset, t, lifetime, 4.0 if organic else 5.5, col, 1)


static func _muzzle_blast(fx, p: Vector3, dir: Vector3, t: float, col: Color, k: float, px := 24.0, w := 2, src = null) -> void:
	# Run 5: a compact hot core at the muzzle plus the baked muzzle jet (a forward cone that cools and thins). The shell
	# tracer carries the bright streak, so the flash only lights the barrel mouth and stays inside the gun mount.
	var core := 4.0 if _old_look(fx) else 1.8
	var core_life := 0.20
	var core_at := 0.6 if _old_look(fx) else 0.5
	var core_power := 5.0 if _old_look(fx) else 5.5
	_burst(fx, p + dir * core_at * k, dir, t, core * k, "flash", core_life, col.lerp(Color.WHITE, 0.22), core_power, px)
	if _old_look(fx):
		_vent(fx, p + dir * k, dir, t + 0.025, 3.6 * k, 0.35, col, 0.8, dir * 4.0 * k, 0.55, 1.0, w, src)
	else:
		_weapon_gas(fx, p + dir * 0.4 * k, dir, t + 0.02, 1.9 * k * WEAPON_GAS_SCALE, "muzzle", 0.30, col, 1.5, dir * 4.0 * k, 0.8, 1.0, 0.0, src)
	_impact_sparks(fx, p, dir, t, k, _spark_faction(src), 4, 9.0, fx.SparkRole.WEAPON)


# Issue 1379 launch (Ryan, Nov 21: "the torpedo just seems to shoot straight up super fast and it doesn't really seem like
# it comes from the ship but more appears out of thin air"). A round leaves its tube the way a ship would fire it:
#   1. the hatch: a small cold gas puff and a faint flash at the mount, the round already sitting in the mouth;
#   2. the push out: it slides clear along the tube, slowing, drive dark (LAUNCH_EJECT s; rockets kick out quicker);
#   3. ignition at tf (the old release time, so impact times and the battle's timing do not move): a flash at the nozzle,
#      the drive lights and the wake starts;
#   4. the turn: the flight leaves along the tube's own line and bends onto the target with only a low lift, never a
#      climb. A deck tube that points up is tipped toward the target so the round does not stand on its tail.
const LAUNCH_EJECT := {"torp": 0.7, "rockets": 0.14, "star": 0.22}   # torp: a long slow slide so it plainly leaves the hull (Ryan, Nov 21)
const LAUNCH_MAX_RISE := 0.34   # issue 1713: sine of the steepest slide out of a deck tube (about 20 degrees)
const LAUNCH_PUSH := {"torp": 3.5, "rockets": 1.4, "star": 1.6}   # push-out length, in round lengths (pk)
# Ryan, Nov 21 ("the size of the torpedoes looks odd ... too large"): the round itself is drawn smaller than its old size
# against the ships. Its trail, flashes and shoot-down follow the smaller body; the push-out distance does not shrink.
const ROUND_SIZE := {"torp": 0.5, "rockets": 0.7, "star": 1.0}


static func _launch_dir(mn: Vector3, from: Vector3, to: Vector3) -> Vector3:
	var flat := to - from
	flat.y = 0.0
	flat = flat.normalized() if flat.length() > 1e-4 else Vector3.RIGHT
	var d := mn.normalized() if mn.length() > 1e-4 else flat
	if d.dot(flat) < 0.0:
		d = (d - flat * d.dot(flat) * 1.2).normalized()   # never back toward the firing ship's own far side
	if d.y > 0.55:
		d = (d + flat * 1.1).normalized()                  # a deck tube: tipped toward the target
	if d.y > LAUNCH_MAX_RISE:   # issue 1713: a deck tube slides out low, about 20 degrees up at most, never a climb
		var h := Vector3(d.x, 0.0, d.z)
		h = h.normalized() if h.length() > 1e-4 else flat
		d = (h * sqrt(1.0 - LAUNCH_MAX_RISE * LAUNCH_MAX_RISE) + Vector3.UP * LAUNCH_MAX_RISE).normalized()
	return d


static func _launch(fx, lk: String, from: Vector3, mn: Vector3, to: Vector3, tf: float, ti: float, col: Color, fac: Dictionary, k: float, i: int, intercept: bool, src = null, rhythm: RandomNumberGenerator = null, spread := 1.0, faction := "") -> float:
	var eng: Color = fac["engine"]
	var old := _old_launch   # the launch before this change, for before shots only
	var ed := _launch_dir(mn, from, to)
	var ej: float = 0.0 if old else float(LAUNCH_EJECT.get(lk, 0.2))
	var tl := tf - ej   # the hatch opens (the vent delay before tf, 0.75 s for torpedoes and 0.45 s for the rest, is longer than the slide, so this stays after the order)
	# the hatch: cold grey gas and a faint flash at the mount (not the engine colour: nothing burns yet)
	if old:
		_vent(fx, from + mn * 0.6 * k, mn, tf, 3.2 * k, 0.35, eng, 0.8, mn * 4.0 * k, 0.7, 1.0, 2, src)
	else:
		_vent(fx, from + mn * 0.3 * k, mn, tl, 2.0 * k, 0.5, Color(0.55, 0.56, 0.58), 0.5, ed * 2.0 * k, 0.45, 1.0, 1, src)
		_burst(fx, from, mn, tl, 0.6 * k, "flash", 0.08, Color(0.85, 0.9, 1.0), 1.4, 6.0)
	var n: int = 4 if lk == "rockets" else 1
	if rhythm == null:
		rhythm = _volley_rng(fx)
	var burst := _volley_pattern(rhythm, n)
	var last := ti
	var dist := from.distance_to(to)
	for j in n:
		var pulse: Dictionary = burst[j]
		var t0 = tf + float(pulse["phase"]) * 0.07
		var pk: float = k * float(pulse["size"])
		var rk: float = pk * (1.0 if old else float(ROUND_SIZE.get(lk, 1.0)))   # the drawn round (ROUND_SIZE)
		# rockets leave a rack: each one from its own cell, a little apart
		var cell: Vector3 = Vector3.ZERO if old else fx.rdir() * (0.35 * k if lk == "rockets" else 0.0)   # old: no extra draw, main's seeded paths
		cell -= ed * cell.dot(ed)
		var l0: Vector3 = from + cell
		var e0: Vector3 = l0 + ed * float(LAUNCH_PUSH.get(lk, 1.6)) * pk * fx.unit
		var lead := clampf(dist * 0.32, 3.0 * k, 14.0 * k)
		var mid: Vector3
		if old:   # main's draws in main's order, so the before clip keeps main's seeded flight paths
			e0 = from
			var side_old = mn * (6.0 + fx.rng.randf() * 4.0) * k + fx.rdir() * (3.0 if lk == "rockets" else 1.0) * k * spread
			mid = from.lerp(to, 0.45) + side_old + Vector3(0, (3.0 + fx.rng.randf() * 3.0) * k, 0)
		else:
			# Issue 1713 (Ryan, Nov 22: "torpedoes all seem to go up and then down ... I'd think we'd keep it flat"): the middle
			# point sits on the straight line from ignition to the target, with sideways scatter only, so the round levels off
			# at ignition and flies flat instead of carrying the tube's climb a third of the way and diving.
			var side: Vector3 = fx.rdir() * (3.0 if lk == "rockets" else 1.0) * k * spread
			side.y = 0.0
			var reach := maxf(e0.distance_to(to), 0.001)
			mid = e0.lerp(to, clampf(lead / reach, 0.0, 0.9)) + side
		var end = to + (fx.rdir() * 0.6 * (k if old else rk) if lk == "rockets" else Vector3.ZERO)   # the warheads scatter by the drawn round size
		var p = {"lk": lk, "t0": t0, "t1": ti + float(pulse["phase"]) * 0.03, "a": e0, "b": mid, "c": end, "col": col, "eng": eng * float(pulse["power"]), "k": rk,
			"seed": fx.rng.randf(), "last": t0, "mesh": _projectile_body(fx, lk, rk, eng * float(pulse["power"]), faction), "dead_at": INF,
			"l0": l0, "lt": t0 - ej, "ed": ed, "fac": fac, "faction": faction}
		if not old:
			_kit_nozzle_dark(p["mesh"], true)
		if old:
			p.erase("lt")
			if lk != "star":
				_kit_trail_start(fx, p, fac)
		if intercept:
			p["dead_at"] = lerpf(t0, float(p["t1"]), 0.62)
			_pd_fire(fx, p)
		var list: Array = fx.dstate.get("proj", [])
		list.append(p)
		fx.dstate["proj"] = list
		last = maxf(last, float(p["t1"]))
	return last


# The push out (launch steps 1 and 2): the round slides from the tube mouth to its ignition point, slowing, drive dark.
static func _launch_step(fx, p: Dictionary, now: float) -> void:
	var node = p["mesh"]
	if not is_instance_valid(node):
		return
	var n3 := node as Node3D
	var u := clampf((now - float(p["lt"])) / maxf(float(p["t0"]) - float(p["lt"]), 0.001), 0.0, 1.0)
	var e := 1.0 - (1.0 - u) * (1.0 - u)
	var d: Vector3 = p["ed"]
	var pos: Vector3 = (p["l0"] as Vector3).lerp(p["a"], e)
	var z := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD).normalized()
	n3.global_transform = Transform3D(Basis(d, z.cross(d).normalized(), z).scaled(n3.scale), pos)
	n3.visible = true
	(n3.get_meta("motor") as ShaderMaterial).set_shader_parameter("throttle", 0.0)
	_ordnance_layers(n3, false)
	p["pos"] = pos


# Ignition (launch step 3): a short hot flash at the nozzle, then the drive and the wake take over.
static func _ignite(fx, p: Dictionary, fac_engine: Color) -> void:
	_kit_nozzle_dark(p["mesh"], false)
	_ordnance_layers(p["mesh"], true)
	var d: Vector3 = p["ed"]
	var k: float = p["k"]
	var nozzle: Vector3 = (p["a"] as Vector3) - d * 1.2 * k * fx.unit * (0.55 if String(p["lk"]) == "rockets" else 1.0)
	_burst(fx, nozzle, -d, float(p["t0"]), 1.1 * k, "flash", 0.10, fac_engine, 2.4, 8.0)
	_burst(fx, nozzle - d * 0.4 * k, -d, float(p["t0"]) + 0.02, 1.4 * k, "cool", 0.45, Color(0.4, 0.4, 0.42), 0.5, 0.0, -d * 3.0 * k, 0.35)


static func _ordnance_layers(node, enabled: bool) -> void:
	if not is_instance_valid(node):
		return
	for name in ["exhaust", "corona"]:
		var layer := (node as Node3D).get_node_or_null(name) as MeshInstance3D
		if layer != null:
			layer.visible = enabled


# Compact, lit casings with a closed nose, a recessed motor and rear fins.
# The casing has no emission: the drive is bright, the body remains readable.
const DRIVE := """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
global uniform float scene_t;
global uniform float fx_gain;
global uniform float fx_calm;
uniform vec3 tint = vec3(0.95, 0.55, 0.2);
uniform float extent = 1.0;
uniform float seed = 0.0;
uniform float throttle = 1.0;
void vertex() {
	vec3 centre = (VIEW_MATRIX * MODEL_MATRIX[3]).xyz;
	float size = extent * length(MODEL_MATRIX[0].xyz);
	// Motor core plus sheath stay resolved on small rockets at battle range (1080-line pixels, issue 1211: the same at 4K).
	float pixel = 2.0 * max(-centre.z, 0.01) / (max(abs(PROJECTION_MATRIX[1][1]), 0.0001) * 1080.0);
	size = max(size, pixel * 12.0);
	POSITION = PROJECTION_MATRIX * vec4(centre + vec3(VERTEX.xy * size, 0.0), 1.0);
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float pulse = 0.86 + (0.10 * sin(scene_t * 23.0 + seed) + 0.04 * sin(scene_t * 37.0 + seed)) * (1.0 - fx_calm);
	float core = exp(-r * r * 14.0);
	float halo = exp(-r * r * 3.0) * (1.0 - smoothstep(0.65, 1.0, r));
	ALBEDO = (mix(tint, vec3(0.94, 0.87, 0.72), 0.75) * core * 3.0 + tint * halo * 1.4) * pulse * throttle * fx_gain;
}
"""

const STAR_BODY := """
shader_type spatial;
render_mode unshaded, fog_disabled;
global uniform float scene_t;
global uniform float fx_gain;
uniform vec3 tint = vec3(1.0);
void fragment() {
	float lobes = 0.7 + 0.15 * sin(UV.x * 18.0 + scene_t * 2.0) * sin(UV.y * 12.0 - scene_t * 3.0);
	float face = smoothstep(0.0, 0.9, max(dot(NORMAL, VIEW), 0.0));
	ALBEDO = mix(tint * 0.55, vec3(1.0), face * lobes) * 2.2 * fx_gain;
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


# R362 (docs/playbooks/ships.md section 9): a torpedo or rocket is a solid object beside the ships, so it is built from its
# faction's part kit (tools/blender/build_sheets/munitions/munitions.py writes fx/munition_bodies/<faction>_<look>.glb, the same
# frame and length as the code casing: +X the nose, x -1.15 to 1.15) and takes the hull finish (LOOK.hull: the faction's
# brightness band, the material rim and the "look_hull" mark the rim light reads). A faction with no body file keeps the
# code casing. Loaded once per body and faction; every shot shares the finished meshes.
const MUNITIONS_DIR := "res://fx/munition_bodies/"


static func _kit_body(fx, lk: String, faction: String) -> Node3D:
	if faction.is_empty() or lk == "star" or _old_casing:   # the code casing, for before shots
		return null
	var key := "munition_%s_%s" % [faction, lk]
	if not fx.dstate.has(key):
		fx.dstate[key] = _load_munition(MUNITIONS_DIR + "%s_%s.glb" % [faction, lk], faction)
	return _build_munition(fx.dstate[key])


# The cache holds only refcounted data (meshes, finished materials, transforms), never a Node: fx.release() clears dstate and
# that frees it all (Artoo on PR 1416: an unattached template node would outlive every battle). Each shot builds its own nodes,
# which its projectile owns and frees.
static func _build_munition(parts) -> Node3D:
	if not parts is Array or (parts as Array).is_empty():
		return null
	var root := Node3D.new()
	root.name = "kit_body"
	var nozzles: Array = []
	for part in parts:
		var mi := MeshInstance3D.new()
		mi.name = str(part["name"])
		mi.mesh = part["mesh"]
		mi.transform = part["xf"]
		var mats: Array = part["mats"]
		var dark: Array = part.get("dark", [])
		for i in mats.size():
			mi.set_surface_override_material(i, mats[i])
			if i < dark.size() and dark[i] != null:
				nozzles.append([mi, i, mats[i], dark[i]])
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	if not nozzles.is_empty():
		root.set_meta("nozzles", nozzles)
	return root


static func _load_munition(path: String, faction: String) -> Array:
	var n: Node = null
	if ResourceLoader.exists(path):
		var ps = load(path)
		if ps is PackedScene:
			n = (ps as PackedScene).instantiate()
	elif FileAccess.file_exists(path):
		# not imported (a partial install, or a cloud run): read the glTF file itself at run time, as world_rocks.gd does
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		if doc.append_from_buffer(FileAccess.get_file_as_bytes(path), "", st) == OK:
			n = doc.generate_scene(st)
	if n == null:
		return []
	var parts: Array = []
	var LOOK = load("res://render/look.gd") if ResourceLoader.exists("res://render/look.gd") else null
	for m in n.find_children("*", "MeshInstance3D", true, false):
		var src := m as MeshInstance3D
		if src.mesh == null:
			continue
		var mats: Array = []
		var dark: Array = []
		for i in src.mesh.get_surface_count():
			var mat: Material = src.get_active_material(i)
			if mat != null and LOOK != null:
				mat = LOOK.hull(mat, faction, true)
			mats.append(mat)
			dark.append(_dark_nozzle(mat))
		parts.append({"name": String(src.name), "mesh": src.mesh, "xf": _to_root(n, src), "mats": mats, "dark": dark})
	n.free()
	return parts


# Issue 1531 (Artoo on PR 1532): the nozzle's baked glow (the engine emission map) stays dark until ignition. A nozzle
# surface gets its own unlit copy in the cache, so a shot swaps its own surface and no shared material changes; marker
# lights (Sunward frost band, window, vent ember) keep their glow. Returns null for any other surface.
static func _dark_nozzle(mat: Material) -> Material:
	var m := mat as BaseMaterial3D
	if m == null or not m.emission_enabled or m.emission_texture == null:
		return null
	var t := m.emission_texture
	# the runtime glTF read names the map; an imported glb keeps it in the extracted file's path; the paint stack names the
	# nozzle material p3_glow either way
	if not ("engine_emission" in t.resource_name or "engine_emission" in t.resource_path or m.resource_name == "p3_glow"):
		return null
	var d := m.duplicate() as BaseMaterial3D
	d.emission_enabled = false
	return d


# A kit body's nozzle glow off (true: the push out) or on (ignition), on this shot's own surfaces only.
static func _kit_nozzle_dark(node, dark: bool) -> void:
	if not is_instance_valid(node):
		return
	var kit := (node as Node).get_node_or_null("kit_body")
	if kit == null or not kit.has_meta("nozzles"):
		return
	for row in kit.get_meta("nozzles"):
		var mi := row[0] as MeshInstance3D
		mi.set_surface_override_material(int(row[1]), row[3] if dark else row[2])


static func _to_root(root: Node, n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


static func _projectile_body(fx, lk: String, k: float, eng: Color, faction := "") -> Node3D:
	var node := Node3D.new()
	node.name = "fx_projectile_" + lk
	var body := MeshInstance3D.new()
	var kit := _kit_body(fx, lk, faction)
	if kit != null:
		node.add_child(kit)
	elif lk == "star":
		var sphere := SphereMesh.new()
		sphere.radius = 0.65; sphere.height = 1.3; sphere.radial_segments = 16; sphere.rings = 8
		body.mesh = sphere
		body.material_override = fx.mat(STAR_BODY)
		body.material_override.set_shader_parameter("tint", Vector3(eng.r, eng.g, eng.b))
	else:
		body.mesh = _casing(fx, lk == "rockets")
	if kit == null:
		body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(body)
	else:
		body.free()
	var drive := MeshInstance3D.new()
	var quad := _unit_quad(fx)
	drive.mesh = quad
	drive.position.x = -1.14 if lk != "star" else -0.2
	var mat: ShaderMaterial = _fresh(fx, "proj_drive_mat", func() -> ShaderMaterial: return fx.mat(DRIVE, 1))
	mat.set_shader_parameter("tint", Vector3(eng.r, eng.g, eng.b))
	mat.set_shader_parameter("extent", 2.5 if lk == "star" else 1.8)
	if kit != null:
		# Ryan, Nov 20 ("the trails/engine effects look super basic and weird"): a kit body drives like a ship. Its own
		# nozzle glows (the baked engine map); the core is the ship's size for that nozzle (fx_ship: r x 2.8), not a halo
		# twice the body's width, and the trail is the ships' engine trail (_kit_trail_*), not a flame card and puffs.
		drive.position.x = -1.28
		mat.set_shader_parameter("extent", KIT_CORE)
		node.set_meta("kit", true)
	mat.set_shader_parameter("seed", fx.rng.randf() * TAU)
	drive.material_override = mat
	node.set_meta("motor", mat)
	node.set_meta("wake_nozzle", drive.position.x - 0.02)
	drive.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drive.extra_cull_margin = 3.0
	node.add_child(drive)
	if kit != null:
		node.scale = Vector3.ONE * k * fx.unit * (0.55 if lk == "rockets" else 1.0)
		node.visible = false
		fx.add_child(node)
		return node
	if lk == "star":
		# The transparent rays sit at the centre of the existing star body. Depth
		# testing lets that body occlude the corona's middle and leaves its rim intact.
		var corona := MeshInstance3D.new()
		corona.name = "corona"
		corona.mesh = quad
		corona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corona.extra_cull_margin = 5.0
		var solar := _fresh(fx, "star_corona_mat", func() -> ShaderMaterial: return fx.mat(SH.ORDNANCE_CORONA, 1, "", "star corona"))
		var palette := FLOOK.weapon(faction if not faction.is_empty() else "ithar")
		solar.set_shader_parameter("tint", Vector3(palette.r, palette.g, palette.b))
		solar.set_shader_parameter("seed", mat.get_shader_parameter("seed"))
		corona.material_override = solar
		node.add_child(corona)
	var plume := MeshInstance3D.new()
	plume.name = "exhaust"
	plume.mesh = quad
	plume.position.x = -2.0
	var exhaust: ShaderMaterial = _fresh(fx, "proj_exhaust_mat", func() -> ShaderMaterial:
		var m: ShaderMaterial = DEATH.flipbook_material(fx, "vent", "small")
		m.shader = _weapon_shader(fx)
		return m)
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


# Issue 1558 item 10: every non-kit round made its own QuadMesh, and its drive and exhaust materials through fx.mat
# (hashing the whole shader text) and flipbook_material each shot. One shared quad, and each round's materials are
# copies of one cached template (a copy keeps the shader and the atlas maps; the round then sets its own values).
static func _unit_quad(fx) -> QuadMesh:
	if not fx.dstate.has("proj_quad"):
		var q := QuadMesh.new(); q.size = Vector2.ONE
		fx.dstate["proj_quad"] = q
	return fx.dstate["proj_quad"]


static func _fresh(fx, key: String, make: Callable) -> ShaderMaterial:
	if not fx.dstate.has(key):
		fx.dstate[key] = make.call()
	return (fx.dstate[key] as ShaderMaterial).duplicate() as ShaderMaterial


static func _bez(a: Vector3, b: Vector3, c: Vector3, u: float) -> Vector3:
	return a.lerp(b, u).lerp(b.lerp(c, u), u)


static func update(fx, dt: float) -> void:
	_craft_update(fx, dt)
	THORN.update(fx, dt)
	for ship in fx.ships.values():
		if is_instance_valid(ship.root):
			var squad = ship.root.get("squad_kind")
			if squad != null and not String(squad).is_empty():
				_wing_trail_update(fx, ship.root.get("hull"))
	var list: Array = fx.dstate.get("proj", [])
	var keep: Array = []
	for p in list:
		var t0: float = p["t0"]
		var t1: float = p["t1"]
		var now: float = fx.now
		if now < t0:
			if p.has("lt") and now >= float(p["lt"]):
				_launch_step(fx, p, now)
			keep.append(p)
			continue
		if p.has("lt") and not p.has("lit"):
			p["lit"] = true
			_ignite(fx, p, p["eng"])
			if is_instance_valid(p["mesh"]) and p["lk"] != "star" and now < minf(t1, float(p["dead_at"])):
				_kit_trail_start(fx, p, p["fac"])
		if now >= float(p["dead_at"]) and float(p["dead_at"]) < t1:
			# shot down short of the hull (issue 1379 round 5: Ryan could not tell this from a hull hit)
			if not p.has("down"):
				p["down"] = now
				_shot_down(fx, p)
			if _shot_down_step(fx, p, now, dt):
				keep.append(p)
				continue
			_projectile_free(fx, p)
			continue
		if now >= t1:
			_projectile_free(fx, p)
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
			if node.has_meta("exhaust"):
				(node.get_meta("exhaust") as ShaderMaterial).set_shader_parameter("tear_normal",-d)
			var fade := smoothstep(0.0, 0.06, now - t0) * (1.0 - smoothstep(t1 - 0.08, t1, now))
			(node.get_meta("motor") as ShaderMaterial).set_shader_parameter("throttle", fade)
		if p.has("trail"):
			_kit_trail_push(fx, p)
		if not p.has("trail") or p["lk"] == "rockets":
			_projectile_exhaust(fx, p, d)
	fx.dstate["proj"] = keep
	_kit_trails_update(fx)
# Sample the actual curved path at fixed intervals. Cap catch-up after a hitch,
# and let each short puff cool independently. There is no persistent hot ribbon.
# Issue 1467: "last" walks the fixed puff grid, so the part of an interval a frame leaves over carries to the next
# frame. After a hitch, intervals past the 3-puff cap are dropped, not
# banked, so no burst repeats; the fraction still carries. Returns the puffs emitted (the frame-rate check counts them).
static func _projectile_exhaust(fx, p: Dictionary, dir: Vector3) -> int:
	var lk: String = p["lk"]
	var k: float = p["k"]
	var last: float = p["last"]
	var rate := 24.0 if lk == "rockets" else 14.0
	if fx.quality == "low": rate *= 0.6
	var due := int((fx.now-last) * rate + 1e-6)
	if due <= 0: return 0
	var count := mini(3, due)
	last += float(due) / rate
	p["last"] = last
	var eng: Color = p["eng"]
	for i in count:
		var tt: float = last - float(count-i-1)/rate
		var e := _ease(clampf((tt-float(p["t0"])) / maxf(float(p["t1"])-float(p["t0"]),0.001),0.0,1.0))
		var at := _bez(p["a"],p["b"],p["c"],e)
		var d: Vector3 = ((p["b"] as Vector3)-(p["a"] as Vector3)).lerp((p["c"] as Vector3)-(p["b"] as Vector3),e).normalized()
		if d.length_squared() < 0.01: d = dir
		if lk == "rockets":
			var tail: Vector3 = at - d * (0.72 * k * fx.unit)
			var smoke := Color(0.30, 0.27, 0.25) if p.get("faction", "") == "corsair" else Color(0.31, 0.33, 0.36)
			# Premultiplied smoke, not light or flame. Stretch along the real nozzle path.
			fx.spr(tail, tt, ROCKET_SMOKE_LIFE, smoke, 0.62, k * 1.6, k * 4.0, SH.ROCKET_SMOKE,
				-d * (2.5 * k * fx.unit), 0.8, 0.0, 0.0, 13.0)
			continue
		var size: float = k
		var tail: Vector3 = at - d * size * 1.2 * fx.unit
		_burst(fx, tail-d*size, -d, tt+0.04, 1.7 * size, "cool", 0.22,
			eng, 0.5, 0.0, -d*size*2.0, 0.12)
		if fx.quality == "max":
			for j in 3:
				var f := float(j) / 3.0
				fx.dst(tail-d*size*(0.5+f*4.0), tt, 0.16, size*(0.4+f*0.5), size*(1.1+f), 1, 0.12*(1.0-f)*(1.0-f))
	return count


# Issue 1379 r4: a kit-built torpedo or rocket leaves the ships' own engine trail (fx_ship _update_trails, SH.TRAIL): a
# world-space strip through the nozzle's recent positions in the faction's engine colour and trail style (Hullbreakers
# sooty). It is short because the round is small and fast; it keeps fading after the hit until its last sample cools.
const KIT_CORE := 0.62          # the drive core billboard on a kit body (body units; the nozzle exit radius is about 0.17)
const ROCKET_SMOKE_LIFE := 0.30  # a short cold second layer, independent of the luminous kit wake
const KIT_TRAIL_LIFE := 0.38    # seconds a trail sample lives (a short wake: longer read as ruler lines at rocket speed)
const KIT_TRAIL_PTS := 28
static var _kit_trail_code := ""


static func _kit_trail_start(fx, p: Dictionary, fac: Dictionary) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "fx_kit_trail"
	mi.top_level = true
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var style: int = 1 if String(fac.get("engine_extra", "")) == "soot" else int(fac.get("trail", 0))
	var key := "kit_trail|%s|%d" % [p.get("faction", ""), style]
	var mat := _fresh(fx, key, func() -> ShaderMaterial:
		var template: ShaderMaterial = fx.mat(kit_trail_shader_code(), 1, "", "kit trail")
		template.set_shader_parameter("trail_style", float(style))
		template.set_shader_parameter("life", KIT_TRAIL_LIFE)
		return template)
	var r: float = 0.17 * float(p["k"]) * fx.unit * (0.55 if String(p["lk"]) == "rockets" else 1.0)
	var eng: Color = p["eng"]
	mat.set_shader_parameter("eng", Vector4(eng.r, eng.g, eng.b, 0.55))
	mat.set_shader_parameter("widths", Vector3(r * 1.8, r * 4.0, float(p["seed"])))
	mat.set_shader_parameter("count", 0)
	mi.material_override = mat
	mi.mesh = kit_trail_strip(fx)
	mi.extra_cull_margin = 16384.0
	mi.visible = false
	fx.add_child(mi)
	mi.global_transform = Transform3D.IDENTITY
	p["trail"] = {"mi": mi, "hist": [], "r": r, "eng": eng, "seed": float(p["seed"]), "fading": false}


static func kit_trail_shader_code() -> String:
	if _kit_trail_code.is_empty():
		_kit_trail_code = SH.kit_trail_code(KIT_TRAIL_PTS)
	return _kit_trail_code


# One strip for every kit trail, built once: point i at VERTEX.x = i, its two sides at UV.y -0.5 and +0.5.
static func kit_trail_strip(fx) -> ArrayMesh:
	if fx.dstate.has("kit_trail_strip"):
		return fx.dstate["kit_trail_strip"]
	var verts := PackedVector3Array(); var uv := PackedVector2Array(); var idx := PackedInt32Array()
	for i in KIT_TRAIL_PTS:
		for sd in [-0.5, 0.5]:
			verts.append(Vector3(float(i), 0.0, 0.0)); uv.append(Vector2(0.0, sd))
	for i in KIT_TRAIL_PTS - 1:
		var q := i * 2
		idx.append_array(PackedInt32Array([q, q + 1, q + 3, q, q + 3, q + 2]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts; arr[Mesh.ARRAY_TEX_UV] = uv; arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.custom_aabb = POOLS.BIG
	fx.dstate["kit_trail_strip"] = mesh
	return mesh


static func _kit_trail_push(fx, p: Dictionary) -> void:
	var node = p["mesh"]
	if not is_instance_valid(node) or not (node as Node3D).visible:
		return
	var t: Dictionary = p["trail"]
	var hist: Array = t["hist"]
	var at: Vector3 = (node as Node3D).global_transform * Vector3(float(node.get_meta("wake_nozzle", -1.3)), 0, 0)
	if hist.is_empty() or (hist[0][0] as Vector3).distance_to(at) > 0.02 * fx.unit:
		hist.push_front([at, fx.now])
		t["dirty"] = true


static func _kit_trails_update(fx) -> void:
	var all: Array = []
	for p in fx.dstate.get("proj", []):
		if p.has("trail"):
			all.append(p["trail"])
	var fading: Array = fx.dstate.get("ptrails", [])
	for t in fading:
		t["fading"] = true   # issue 1558 item 8: a flag, not `t in fading` (that compared whole dictionaries by content)
	all.append_array(fading)
	var keep: Array = []
	for t in all:
		var hist: Array = t["hist"]
		while not hist.is_empty() and (hist.size() > KIT_TRAIL_PTS or fx.now - float(hist.back()[1]) >= KIT_TRAIL_LIFE):
			hist.pop_back()
			t["dirty"] = true
		var mi: MeshInstance3D = t["mi"]
		if not is_instance_valid(mi):
			continue
		var is_fading: bool = t.get("fading", false)
		if is_fading and hist.size() < 2:
			mi.queue_free()
			continue
		if is_fading:
			keep.append(t)
		mi.visible = hist.size() >= 2
		if not mi.visible:
			continue
		if t.get("dirty", false):
			t["dirty"] = false
			_kit_trail_upload(t)
	fx.dstate["ptrails"] = keep


# The samples go to the material as a small uniform array; the strip mesh never changes (issue 1558 item 8).
static func _kit_trail_upload(t: Dictionary) -> void:
	var hist: Array = t["hist"]
	var pts := PackedVector4Array()
	pts.resize(KIT_TRAIL_PTS)
	var n := mini(hist.size(), KIT_TRAIL_PTS)
	for i in KIT_TRAIL_PTS:
		var h: Array = hist[mini(i, n - 1)]
		var at: Vector3 = h[0]
		pts[i] = Vector4(at.x, at.y, at.z, float(h[1]))
	var m := (t["mi"] as MeshInstance3D).material_override as ShaderMaterial
	m.set_shader_parameter("pts", pts)
	m.set_shader_parameter("count", n)


# ---------------------------------------------------------------- shot down (issue 1379 round 5)
# Ryan, Nov 21: "it's hard to distinguish whats a hull hit vs explosion before due to turrets". A round shot down never
# burns: no fire, no flash on the hull. Ryan picked PD-C on Nov 21 (options sheet board/torpedo_rework/tp_pd_*.jpg): the
# target's point defence fires pale tracer dashes at the round, dark flak puffs bracket it, cold sparks where it is holed,
# and the round goes dead (drive out) and tumbles away trailing grey smoke.
const PD_TRACER := Color(0.72, 0.88, 1.0)
const PD_TUMBLE_S := 0.9


static func _down_point(p: Dictionary) -> Vector3:
	var u0 := clampf((float(p["dead_at"]) - float(p["t0"])) / maxf(float(p["t1"]) - float(p["t0"]), 0.001), 0.0, 1.0)
	return _bez(p["a"], p["b"], p["c"], _ease(u0))


static func _pd_fire(fx, p: Dictionary) -> void:
	var pp := _down_point(p)
	var c: Vector3 = p["c"]
	var k: float = p["k"]
	# four short dashes from the target's side, a little spread, the last one arriving as the round dies
	for j in 4:
		var src: Vector3 = c + fx.rdir() * 0.8 * k + (pp - c).normalized() * 0.6 * k
		var aim: Vector3 = pp + fx.rdir() * (0.5 if j < 3 else 0.05) * k
		var ft := maxf(src.distance_to(aim) / (260.0 * fx.unit), 0.05)
		var tb := float(p["dead_at"]) - ft - (3 - j) * 0.07
		fx.flight_streak(src, tb, ft, PD_TRACER, 7.0, 5.0 * k, 0.22 * k, BOLT_ENERGY, (aim - src) / ft, 0.0, 0.0, 3.0, 18.0)


static func _shot_down(fx, p: Dictionary) -> void:
	var pp := _down_point(p)
	fx.torpedo_shot_down.emit(pp)
	var now: float = fx.now
	var k: float = p["k"]
	var d: Vector3 = ((p["c"] as Vector3) - (p["a"] as Vector3)).normalized()
	_burst(fx, pp, -d, now, 0.9 * k, "flash", 0.10, PD_TRACER, 4.2, 11.0)
	fx.ring(pp, -d if d.length_squared() > 0.01 else Vector3.UP, now, 0.23, PD_TRACER, 0.8, 0.4 * k, 3.6 * k, 3, 0.0, 0.0, 22.0)
	# Small sparks off the intercepted round, in the round's faction colour.
	_impact_sparks(fx, pp, -d, now, k * 0.7, str(p.get("faction", FLOOK.FALLBACK)), 5, 14.0, fx.SparkRole.WEAPON)
	for j in 5:
		var off: Vector3 = fx.rdir() * (0.9 + fx.rng.randf() * 0.9) * k
		var tj := now + j * 0.045
		_burst(fx, pp + off, Vector3.UP, tj, 0.35 * k, "flash", 0.06, PD_TRACER, 2.0, 4.0)
		_burst(fx, pp + off, Vector3.UP, tj + 0.02, 1.1 * k, "cool", 0.9, Color(0.16, 0.15, 0.14), 0.5, 0.0, Vector3.ZERO, 0.6)
	# the round goes dead. Drive out, it tumbles on along its path, slowing, trailing grey smoke
	var node = p["mesh"]
	if is_instance_valid(node) and (node as Node3D).has_meta("motor"):
		((node as Node3D).get_meta("motor") as ShaderMaterial).set_shader_parameter("throttle", 0.0)
		_ordnance_layers(node, false)
	var e := _ease(clampf((now - float(p["t0"])) / maxf(float(p["t1"]) - float(p["t0"]), 0.001), 0.0, 1.0))
	var vd: Vector3 = ((p["b"] as Vector3) - (p["a"] as Vector3)).lerp((p["c"] as Vector3) - (p["b"] as Vector3), e)
	p["down_v"] = vd.normalized() * minf(vd.length(), 40.0 * k * fx.unit) * 0.35 + Vector3(0, -0.8 * k * fx.unit, 0)
	p["down_p"] = pp
	p["down_spin"] = fx.rdir() * (5.0 + fx.rng.randf() * 4.0)
	if p.has("trail"):
		var fading: Array = fx.dstate.get("ptrails", [])
		fading.append(p["trail"])
		fx.dstate["ptrails"] = fading
		p.erase("trail")


static func _shot_down_step(fx, p: Dictionary, now: float, dt: float) -> bool:
	if not p.has("down_p"):
		return false
	var age := now - float(p["down"])
	if age >= PD_TUMBLE_S:
		return false
	var node = p["mesh"]
	if not is_instance_valid(node):
		return false
	var n3 := node as Node3D
	var drift := (1.0 - exp(-age * 2.0)) / 2.0
	n3.global_position = (p["down_p"] as Vector3) + (p["down_v"] as Vector3) * drift
	var spin: Vector3 = p["down_spin"]
	if spin.length() > 0.0:
		n3.rotate(spin.normalized(), spin.length() * clampf(dt, 0.0, 0.1))
	if not p.has("down_scale"):
		p["down_scale"] = n3.basis.get_scale().x
	var fade := 1.0 - smoothstep(PD_TUMBLE_S * 0.6, PD_TUMBLE_S, age)
	n3.basis = n3.basis.orthonormalized().scaled(Vector3.ONE * float(p["down_scale"]) * maxf(fade, 0.01))
	if now - float(p.get("down_smoke", -1.0)) > 0.08:
		p["down_smoke"] = now
		_burst(fx, n3.global_position, Vector3.UP, now, 0.7 * float(p["k"]), "cool", 0.8, Color(0.22, 0.21, 0.2), 0.5, 0.0, Vector3(0, 0.4 * fx.unit, 0), 0.45 * fade)
	return true


static func _projectile_free(fx, p: Dictionary) -> void:
	if is_instance_valid(p["mesh"]): (p["mesh"] as Node).queue_free()
	if p.has("trail"):
		var fading: Array = fx.dstate.get("ptrails", [])
		fading.append(p["trail"])
		fx.dstate["ptrails"] = fading
		p.erase("trail")


static func _ease(u: float) -> float:
	# boost phase: slow off the rail, then the motor takes over
	return u * u * (1.6 - 0.6 * u) if u < 1.0 else 1.0


# Flak: proximity-fused shells bursting around the target; returns the last burst time.
static func _flak(fx, lk: String, from: Vector3, dir: Vector3, to: Vector3, tf: float, col: Color, ka: float, kt: float, rhythm: RandomNumberGenerator, spread: float, src) -> float:
	var faction := _spark_faction(src)
	var spd = 220.0 * fx.unit
	var last = tf
	var nb := 2 if lk == "gsentry" else 3 if lk == "flak" else 4
	var burst := _volley_pattern(rhythm, nb)
	var muzzle_profile: int = {"mflak": MUZZLE_CRYSTAL, "spores": MUZZLE_BIO, "flak": MUZZLE_BALLISTIC}.get(lk, MUZZLE_ENERGY)
	for b in nb:
		var pulse: Dictionary = burst[b]
		var bk: float = ka * float(pulse["size"])
		var pk: float = float(pulse["power"])
		var tb = tf + float(pulse["phase"]) * (0.025 if lk == "gsentry" else 0.06)
		var fan := 1.5 if lk == "flak" else 0.55 if lk == "gsentry" else 1.0
		var off = fx.rdir() * (2.0 + fx.rng.randf() * 3.0) * kt * spread * fan
		var bp = to + off - dir * (1.0 + fx.rng.randf() * 2.0) * kt
		var ft = from.distance_to(bp) / spd
		_muzzle(fx, from, dir, tb, col, bk, 12.0 * float(pulse["size"]), muzzle_profile, src)
		match lk:
			"pflak":
				fx.flight_streak(from, tb, ft, col, 9.0 * pk, 3.5 * bk, 0.32 * bk, BOLT_ENERGY, (bp - from).normalized() * spd, 0.0, 0.0, 3.2 * float(pulse["size"]), 18.0 * float(pulse["size"]))
			"gflak":
				_gauss_wake(fx, from, bp, tb, col * pk, bk, 0.02)
				ft = 0.02
			"gsentry":
				ft = 0.055
				fx.flight_streak(from, tb, ft, col, 7.0 * pk, 7.0 * bk, 0.18 * bk, BOLT_ENERGY, (bp - from) / ft, 0.0, 0.0, 2.0, 32.0)
			"spores":
				ft *= 2.2
				_sprite_bolt(fx, from, tb, ft, col, 1.8 * pk, 0.85 * bk, BOLT_BIO, (bp - from) / ft, 11.0)
			"mflak":
				fx.flight_streak(from, tb, ft, col, 8.0 * pk, 4.5 * bk, 0.24 * bk, BOLT_CRYSTAL, (bp - from) / ft, 0.0, 0.0, 2.4, 22.0)
			_:
				fx.flight_streak(from, tb, ft, col, 8.0 * pk, 1.5 * bk, 0.55 * bk, BOLT_SHELL, (bp - from) / ft, 0.0, 0.0, 4.0, 9.0)
		var t_b = tb + ft
		last = maxf(last, t_b)
		if lk == "mflak" or lk == "gsentry":
			# A mirror catches light in a broad glint. The null spire snaps into a narrow cross.
			var mirror := lk == "mflak"
			fx.spr(bp, t_b, 0.24 if mirror else 0.15, col, 2.6 * pk, 1.6 * kt, 0.7 * kt if mirror else 0.26 * kt,
				16 if mirror else 13, Vector3.ZERO, 0.0, 0.0, 0.0, 23.0 if mirror else 16.0)
			_impact_sparks(fx, bp, -dir, t_b, kt, faction, 4, 10.0, fx.SparkRole.WEAPON)
			continue
		_burst(fx, bp, -dir, t_b, 3.2 * kt * float(pulse["size"]), "flash", 0.28, col, (1.4 if lk == "spores" else 3.4) * pk, 22.0 * float(pulse["size"]))
		_burst(fx, bp, -dir, t_b + 0.04, 3.6 * kt, "cool", 0.55, col, 0.65, 0.0, -dir * 1.5 * kt, 0.5)
		_impact_sparks(fx, bp, -dir, t_b, kt, faction, 10 if lk == "flak" else 7,
			15.0 if lk == "flak" else 10.0, fx.SparkRole.WEAPON)

	return last


# Strike craft: a loose formation flies a strafing run past the target, firing as it goes.
# fly_to: where the run flies over (a miss passes beside the hull, tg["pass"]); to: where the craft aim. A miss's
# aim point runs on past the hull and, from wing height, ends below the plane, so the dive never bottoms out on it
# (Fable review of PR 1874, finding 1).
static func _strafe(fx, lk: String, from: Vector3, to: Vector3, t0: float, col: Color, fac: Dictionary, ka: float, kt: float, i: int, faction := "voidsworn", rhythm: RandomNumberGenerator = null, spread := 1.0, fly_to: Variant = null) -> float:
	var aim: Vector3 = to
	if fly_to is Vector3:
		to = fly_to
	var d = (to - from)
	var dist = maxf(d.length(), 1.0)
	var dir = d / dist
	var side = dir.cross(Vector3.UP).normalized()
	var spd = 140.0 * fx.unit
	var eng: Color = fac["engine"]
	# issue 1582: wings patrol high above the ships; an attack pass dives steeply from patrol height onto the target's
	# height, fires on the low pass and climbs back out to patrol height past it (a wing level with its target keeps the
	# old shallow run: start 3 up, end 6 up)
	var start = from - dir * 3.0 + side * (i - 1) * 2.0 + Vector3(0, 3.0, 0)
	var end = to + dir * 25.0 + side * (i - 1) * 4.0 + Vector3(0, 6.0, 0)
	var high: float = maxf(start.y, to.y + 3.0)
	end.y = maxf(end.y, high)
	var low_y: float = to.y + 1.6 * kt
	var flat_d: float = Vector2(to.x - start.x, to.z - start.z).length()
	var run_d: float = maxf(Vector2(end.x - start.x, end.z - start.z).length(), 1.0)
	var pi_u := clampf((flat_d - 3.0) / run_d, 0.2, 0.8)
	# level at patrol height until DIVE_RUN short of the target, then a steep dive; the pull-out climbs over CLIMB_RUN
	# Reduce motion: the dive and climb stretch over three times the ground (a gentle slope) and the craft never bank
	var calm := bool(fx.get("reduce_motion")) if "reduce_motion" in fx else false
	var dk := 3.0 if calm else 1.0
	var dive := {"ya": float(start.y), "yl": low_y, "yb": float(end.y), "pi": pi_u, "calm": calm,
		"pd": maxf(pi_u - DIVE_RUN * dk / run_d, 0.0), "pc": minf(pi_u + CLIMB_RUN * dk / run_d, 1.0)}
	var life = _dive_len(start, end, dive) / spd
	var timp = t0 + life * float(dive["pi"]) - 6.0 / spd
	if rhythm == null:
		rhythm = _volley_rng(fx)
	var formation := _volley_pattern(rhythm, 3)
	for c in 3:
		var delay: float = float(formation[c]["phase"]) * 0.04
		var off = side * (c - 1) * 1.2 * spread + Vector3(0, (c % 2) * 0.6, 0)
		var kind := "spore" if faction == "chorus" or lk == "sporeb" else ("bomber" if lk == "bombs" else "fighter")
		_craft_run(fx, faction, kind, start + off, end + off, t0 + delay, life, 2.4, dive)
		# craft fire: miniature tracers, bombs or spore sacs
		var burst := _volley_pattern(rhythm, 3)
		for s in 3:
			var pulse: Dictionary = burst[s]
			var tsh = timp - 0.35 + float(pulse["phase"]) * 0.08 + delay
			var ps = _dive_pos(start + off, end + off, dive, clampf((tsh - t0 - delay) / life, 0.0, 1.0))
			var dd = (aim - ps).normalized()
			match lk:
				"bombs":
					if s == 0:
						_sprite_bolt(fx, ps, tsh, (aim - ps).length() / 50.0, col, 1.7, 0.65, BOLT_BOMB, dd * 50.0, 9.0)
				"sporeb":
					if s == 0:
						_sprite_bolt(fx, ps, tsh, (aim - ps).length() / 45.0, col, 1.8, 0.7, BOLT_BIO, dd * 45.0, 10.0)
				_:
					fx.flight_streak(ps, tsh, (aim - ps).length() / 260.0, col, 8.0 * float(pulse["power"]), 3.5 * ka, 0.35 * ka * float(pulse["size"]), BOLT_SHELL, dd * 260.0)
	return timp + (0.3 if lk == "bombs" else 0.1)


# Launch and attack passes use the same faction geometry as the parked wing.
# fx.now owns these runs, including accelerated playback and deterministic probes.
# issue 1582: the attack pass's line. Across the ground it runs straight from a to b; in height it dives from patrol
# height (ya) to the low pass (yl) at share pi of the run, steepest in the middle of the dive, then pulls out and climbs
# back to yb. An empty dive is the old straight run.
const DIVE_RUN := 14.0    # issue 1582: ground covered by the dive itself (world units): short, so the dive is steep
const CLIMB_RUN := 24.0   # ground covered by the climb back out to patrol height


static func _dive_pos(a: Vector3, b: Vector3, dive: Dictionary, u: float) -> Vector3:
	var p := a.lerp(b, u)
	if dive.is_empty():
		return p
	var off := a.y - float(dive["ya"])   # a carries its own formation offset; keep it through the dive
	var pi_u := float(dive["pi"])
	var pd := float(dive.get("pd", 0.0))
	var pc := float(dive.get("pc", 1.0))
	if u <= pd:
		p.y = a.y
	elif u <= pi_u:
		var k := (1.0 - cos(PI * (u - pd) / maxf(pi_u - pd, 1e-3))) * 0.5
		p.y = lerpf(a.y, float(dive["yl"]) + off, k)
	elif u <= pc:
		var k2 := (1.0 - cos(PI * (u - pi_u) / maxf(pc - pi_u, 1e-3))) * 0.5
		p.y = lerpf(float(dive["yl"]) + off, float(dive["yb"]) + off, k2)
	else:
		p.y = float(dive["yb"]) + off
	return p


static func _dive_len(a: Vector3, b: Vector3, dive: Dictionary) -> float:
	var n := 16
	var d := 0.0
	var prev := _dive_pos(a, b, dive, 0.0)
	for k in range(1, n + 1):
		var q := _dive_pos(a, b, dive, float(k) / n)
		d += prev.distance_to(q)
		prev = q
	return d


static func _craft_run(fx, faction: String, kind: String, from: Vector3, to: Vector3, t0: float, life: float, size: float, dive := {}) -> void:
	var node := WING.new()
	node.name = "fx_strike_craft"
	fx.add_child(node)
	node.setup(faction, kind, size, 1, t0 * 3.0)
	node.set_process(false)
	node.visible = false
	var runs: Array = fx.dstate.get("craft_runs", [])
	runs.append({"node": node, "a": from, "b": to, "t0": t0, "life": maxf(life, 0.05), "dive": dive})
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
		var dive: Dictionary = r.get("dive", {})
		node.visible = true
		node.active = age < float(r.life)
		for c in node.craft: c.visible = node.active
		node.position = _dive_pos(r.a, r.b, dive, progress)
		# issue 1582: the craft's nose follows its flown line, so it pitches down into the dive and up out of it, and
		# banks a little into the pull-out (strike craft only: warships never bank, RULEBOOK 7.5)
		var ahead := _dive_pos(r.a, r.b, dive, minf(progress + 0.02, 1.0))
		var behind := _dive_pos(r.a, r.b, dive, maxf(progress - 0.02, 0.0))
		var fwd := ahead - behind
		if fwd.length() < 1e-4:
			fwd = (r.b - r.a)
		fwd = fwd.normalized()
		var flat := Vector3(fwd.x, 0.0, fwd.z)
		if flat.length() < 1e-4:
			flat = Vector3(1, 0, 0)
		var yaw_b := Basis(Vector3.UP, atan2(-flat.z, flat.x))
		var pitch := asin(clampf(fwd.y, -1.0, 1.0))
		var bank := 0.0
		if not dive.is_empty() and not bool(dive.get("calm", false)):
			var pi_u := float(dive["pi"])
			var pc := float(dive.get("pc", 1.0))
			bank = 0.35 * sin(PI * clampf((progress - pi_u) / maxf(pc - pi_u, 1e-3), 0.0, 1.0))
		node.basis = yaw_b * Basis(Vector3(0, 0, 1), pitch) * Basis(Vector3(1, 0, 0), bank)
		node.step(dt)
		_wing_trail_update(fx, node)


# Issue 2042 item 4: squadron_wing.gd now natively owns SH.CRAFT_TRAIL and updates its uniforms in step().
# Keep this hook for kit_trails discovery and any non-native fallback without duplicating per-step uniform writes.
static func _wing_trail_update(fx, wing) -> void:
	if wing == null or not is_instance_valid(wing):
		return
	if not wing.has_meta("kit_trails"):
		var materials: Array = []
		var fallback := false
		for trail in wing.trails:
			var material: ShaderMaterial = trail.get("mat") as ShaderMaterial
			if material == null:
				fallback = true
				material = fx.mat(SH.CRAFT_TRAIL, 1)
				material.set_shader_parameter("trail_len", wing.length)
				material.set_shader_parameter("width_k", 0.048 if wing.faction == "chorus" else 0.026)
				material.set_shader_parameter("alpha_k", 0.22 if wing.faction == "chorus" else 0.56)
				material.set_shader_parameter("life", wing.trail_life)
				material.set_shader_parameter("trail_style", 1.0 if wing.faction == "chorus" else (2.0 if wing.faction == "ithar" else 0.0))
				trail.node.material_override = material
				trail["mat"] = material
			materials.append(material)
		wing.set_meta("kit_trails", materials)
		wing.set_meta("kit_trails_fallback", fallback)
	if not bool(wing.get_meta("kit_trails_fallback", false)):
		return
	var materials: Array = wing.get_meta("kit_trails")
	for i in mini(materials.size(), wing.craft.size()):
		var material: ShaderMaterial = materials[i]
		material.set_shader_parameter("clock_now", wing.clock)
		var stern: Vector3 = wing.craft[i].to_global(wing._stern)
		material.set_shader_parameter("head_world", stern)
		var history: Array = wing.trails[i].hist
		if not history.is_empty():
			material.set_shader_parameter("newest_birth", float(history[0][1]))
			material.set_shader_parameter("anchor_ready", 1.0)
		else:
			material.set_shader_parameter("anchor_ready", 0.0)


# Issue 1528: the first torpedo or rocket salvo of a battle stalled 135 to 145 ms on the PC (1379 RUN8). Its first round
# read the kit body glb from disk, built its hull-finish materials and nozzle copies, and compiled their pipelines and the
# kit trail's, all in the fight. Load every body the fleets on the board can fire and draw it once in the warm-up grid
# (lit and nozzle-dark surfaces both), with a kit trail strip in its own vertex format. Returns the bodies warmed.
static func warm_munitions(fx, parent: Node3D) -> int:
	var factions := {}
	for s in fx.ships.values():
		factions[String(s.faction)] = true
	var warmed := 0
	var slot := 0
	for faction in factions:
		for lk in ["torp", "rockets"]:
			var path: String = MUNITIONS_DIR + "%s_%s.glb" % [faction, lk]
			if not (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
				continue
			var key := "munition_%s_%s" % [faction, lk]
			if not fx.dstate.has(key):
				fx.dstate[key] = _load_munition(path, faction)
			var parts: Array = fx.dstate[key]
			if parts.is_empty():
				continue
			warmed += 1
			for dark in [false, true]:
				var body := _build_munition(parts)
				if dark:
					for row in body.get_meta("nozzles", []):
						(row[0] as MeshInstance3D).set_surface_override_material(int(row[1]), row[3])
				body.position = Vector3(-6.0 + slot * 1.5, -3.0, 0.0) * fx.unit
				body.scale = Vector3.ONE * fx.unit
				parent.add_child(body)
				slot += 1
	# the kit trail: its strip has its own vertex format (position and UV only), so a box does not warm it
	var trail := MeshInstance3D.new()
	trail.mesh = kit_trail_strip(fx)
	var tm: ShaderMaterial = fx.mat(kit_trail_shader_code(), 1, "", "kit trail")
	var at: Vector3 = parent.global_position if parent.is_inside_tree() else Vector3.ZERO
	var pts := PackedVector4Array()
	pts.resize(KIT_TRAIL_PTS)
	for i in KIT_TRAIL_PTS:
		pts[i] = Vector4(at.x + float(i) * 0.1 * fx.unit, at.y, at.z, fx.now)
	tm.set_shader_parameter("pts", pts)
	tm.set_shader_parameter("count", KIT_TRAIL_PTS)
	tm.set_shader_parameter("eng", Vector4(0.01, 0.01, 0.01, 0.01))
	trail.material_override = tm
	trail.extra_cull_margin = 16384.0
	parent.add_child(trail)
	return warmed


static func warm_craft_trail(fx, parent: Node3D) -> void:
	# Warm the real ImmediateMesh format, not a box with different attributes.
	var wing := WING.new()
	parent.add_child(wing)
	wing.setup("hegemony", "fighter", 1.0, 1, 0.0)
	wing.set_process(false)
	wing.step(0.04)
	wing.step(0.04)
	_wing_trail_update(fx, wing)


# ---------------------------------------------------------------- impacts

# The weapon sets the size, timing and direction. The target sets what comes off the hull (R412).
const IMPACT_RESPONSE := {
	"metal": {"fire_body": true, "gas_kind": 7, "debris": "plate", "hot_plate": true},
	"hegemony": {"fire_body": true, "gas_kind": 7, "debris": "plate", "faction_glow": true},
	"glass": {"fire_body": false, "gas_kind": 0, "debris": "glass", "faction_glow": true, "prism": 1.0},
	"bio": {"fire_body": false, "gas_kind": 20, "debris": "drop", "tint": Color(0.72, 0.86, 0.27),
		"mist": Color(0.32, 0.38, 0.15)},
	"obsidian": {"fire_body": true, "gas_kind": 0, "debris": "plate", "faction_glow": true},
}
const METAL_EMBER := Color(0.42, 0.07, 0.02)


static func _impact_response(target) -> Dictionary:
	return _response_for(target.faction) if target != null else IMPACT_RESPONSE["metal"]


static func _response_for(faction: String) -> Dictionary:
	return IMPACT_RESPONSE[faction if faction == "hegemony" else HULL.target_substance(faction)]


static func _impact_color(response: Dictionary, target, fallback: Color) -> Color:
	if response.get("faction_glow", false):
		return target.fac.damage_glow
	return response.get("tint", fallback)


static func _impact_flash(fx, target, p: Vector3, n: Vector3, T: float, k: float, size: float, life: float,
		col: Color, px: float, response: Dictionary, lift: float, strength := 4.5) -> void:
	if response.get("hot_plate", false):
		_burst(fx, p + n * lift, n, T, size, "flash", life, col, strength, px)
	else:
		_staged_hit(fx, target, p, T, false, k, n, px / BURST_PX_K, col, true, life, lift)


static func _impact_gas(fx, p: Vector3, n: Vector3, T: float, k: float, col: Color, count: int,
		size: float, fam: String, alpha: float, response: Dictionary, axis := Vector3.ZERO) -> void:
	var kind: int = response.gas_kind
	if kind != 0:
		_gas_cloud(fx, p, n, T, k, response.get("mist", col), count, size, fam, alpha, kind, axis)


static func _impact_embers(fx, p: Vector3, n: Vector3, T: float, k: float, count: int, fam: String,
		response: Dictionary, target, col := METAL_EMBER) -> void:
	if response.fire_body:
		var ember: Color = target.fac.damage_glow * 0.35 if response.get("faction_glow", false) else col
		_embers(fx, p, n, T, k, count, fam, ember, SH.TICK_EMBER if response.get("faction_glow", false) else fx.HOT_FLECK_SPRITE)


# Issue 461: the weapon family whose hit recipe a look uses (deaths_and_hits.md "The hits, upgraded"). Shell: a spark
# cone that skips off the plate. Energy: a splash that runs along the plate and a short scorch. Lance: a contact burn that
# crawls while the beam dwells. Torpedo: fire seen through gas with thrown debris. Faction weapons take the nearest row:
# the prism is energy with a rainbow fringe, the ion beam a lance burn in blue-white with arcs and no molten debris, the
# Chorus bile its own wet splash with a lingering fume.
static func family_of(lk: String) -> String:
	if lk in ["lance", "ion", "pulsar", "doom", "needle", "nlance"]:
		return "lance"
	if lk in ["torp", "rockets", "star", "ram"]:
		return "torp"
	if lk in ["las", "plasma", "plasma_cannon", "prism"]:
		return "energy"
	if lk in ["spine", "tendril", "sporeb", "spores"]:
		return "bio"
	if lk in ["flak", "pflak", "mflak", "gflak", "gsentry"]:
		return "flak"
	return "shell"   # macro, auto, scatter, guns, bombs, gauss


# The hit's flash on screen (pixels at 1080) from its ladder row, the gun that fired and the ship hit.
static func ladder_px(lk: String, w: int, tg: Dictionary) -> float:
	var fam := family_of(lk)
	var base: float = HIT_PX[clampi(w, 1, 3)]
	if lk == "needle":
		base = float(LADDER_PX["energy"][clampi(w, 1, 3)])
	elif fam in ["energy", "shell", "lance"]:
		base = float(LADDER_PX[fam][clampi(w, 1, 3)])
	elif fam == "torp":
		base = float(LADDER_PX["torp"]) * (0.65 if lk == "rockets" else 1.0)
	return base * float(tg.get("gk", 1.0)) * float(tg.get("tk", 1.0))


# Rule 5 (direction): everything thrown leaves along the surface's outward side. Lifts a direction off the plate so its
# outward share is at least `min_up`; nothing sprays into the ship.
static func _outward(n: Vector3, v: Vector3, min_up := 0.2) -> Vector3:
	var d: Vector3 = v.normalized() if v.length() > 1e-5 else n
	var up: float = d.dot(n)
	if up < min_up:
		d = (d + n * (min_up - up + 0.05)).normalized()
	return d


# Tests (hit_recipe_check.gd): what each recipe throws, when fx.dstate["hit_logging"] is on.
static func _note(fx, what: String, fam: String, v: Vector3, n: Vector3, life: float, px := 0.0) -> void:
	if bool(fx.dstate.get("hit_logging", false)):
		if not fx.dstate.has("hit_log"):
			fx.dstate["hit_log"] = []
		(fx.dstate["hit_log"] as Array).append({"what": what, "fam": fam, "v": v, "n": n, "life": life, "px": px, "t": fx.now})


static func _amount(fx, count: int) -> int:
	if fx.quality == "max":
		return count
	return maxi(1, count / (2 if fx.quality != "low" else 4))


# Issue 538: larger cooling points and trails, with a longer ballistic tail. No added flash or light.
static func _throw_sparks(fx, p: Vector3, n: Vector3, axis: Vector3, T: float, k: float, faction: String, count: int, speed: float,
		spread: float, fam: String) -> void:
	var shield := fam == "shield"
	var scale := _spark_size(k)
	var role: int = fx.SparkRole.SHIELD if shield else fx.SparkRole.HULL
	for j in _amount(fx, int(ceil(count * 1.5 * scale))):
		# Hull ejecta is faster, finer and fans across the struck face.
		var d := _outward(n, fx.rcone(axis, spread if shield else maxf(spread, 0.95)), 0.15)
		var v: Vector3 = d * fx.rng.randf_range(speed * (0.35 if shield else 0.55), speed) * k * fx.unit
		var drag: float = fx.rng.randf_range(0.45, 1.4) if shield else fx.rng.randf_range(0.25, 0.75)
		var life: float = clampf(fx.rng.randf_range(SPARK_LIFE.x, SPARK_LIFE.y) * scale, SPARK_LIFE.x, SPARK_LIFE.y)
		var t: float = T + fx.rng.randf() * 0.04
		var form: float = fx.rng.randf()
		fx.spark(p, t, life, faction, lerpf(1.55, 2.75, form), lerpf(0.040, 0.125, form) * scale,
			lerpf(0.023, 0.041, form) * k, v, drag, 0.0, 0.0, role)
		_note(fx, "spark", fam, v, n, life)


# Solid ejecta leaves the same contact as the sparks. The tips of the plume are small and fast;
# the larger pieces peel off slowly along the surface, with a few loose pieces between them.
static func _throw_debris(fx, p: Vector3, n: Vector3, axis: Vector3, T: float, k: float, count: int, speed: float, size: float,
		heat: float, fam: String, faction := "metal", macro := false, target = null) -> void:
	var response := _response_for(faction)
	if response.debris == "drop":
		var tissue: Color = response.tint
		for j in _amount(fx, count):
			var d := _outward(n, fx.rcone(axis, 0.8), 0.2)
			var v: Vector3 = d * fx.rng.randf_range(speed * 0.25, speed * 0.65) * k
			var life: float = fx.rng.randf_range(1.0, 2.0)
			fx.spr(p, T + j * 0.015, life, tissue, 0.8, size * k * 1.5, size * k, 15, v, 0.5)
			_note(fx, "drop", fam, v, n, life)
		return
	var paint: Color = fx.faction_info(faction).fragment_paint
	# The fragment shader's heated edge is always orange. Glass already has spectral glints.
	var fragment_heat := heat if response.get("hot_plate", false) else 0.0
	var original := _amount(fx, int(ceil(count * 1.75))) if fx.quality != "low" else mini(count, 3)
	var extra := ceili(original * 0.3) if macro and fx.quality != "low" else 0
	var pieces := original + extra
	if pieces <= 0:
		return
	var finish := FRAGMENTS.source(target, p, n)
	(fx.pools["plate"] as FRAGMENTS.Pool).bind_finish(finish, fx.now, T + DEBRIS_LIFE.y + 0.025)
	var shared_state: int = 0
	for j in pieces:
		# Extra fragments use a separate sequence. Soot, embers and later hits keep the original draw order.
		if j == original:
			shared_state = fx.rng.state
			fx.rng.state = shared_state ^ 0x459dbad1
		var jitter: Vector3 = fx.rdir()
		var motion: float = fx.rng.randf()
		var life: float = fx.rng.randf_range(DEBRIS_LIFE.x, DEBRIS_LIFE.y)
		var born: float = T + fx.rng.randf() * 0.025
		var shape: float = fx.rng.randf()
		var variant := mini(FRAGMENTS.VARIANTS - 1, int(shape * FRAGMENTS.VARIANTS))
		var turn: float = fx.rng.randf()
		var lead := j == 0 or (j == 1 and pieces >= 6)
		var quick := j >= 2 and j % 3 != 0
		var rib := j == 1 or (j >= 2 and j % 2 == 0)
		var profile := FRAGMENTS.RIB if rib else FRAGMENTS.PLATE
		if response.debris == "glass":
			profile = FRAGMENTS.GLASS
		var scale := lerpf(1.85, 2.8, shape) if quick else lerpf(2.85, 3.5, shape)
		if lead:
			scale = lerpf(4.4, 5.0, shape) if j == 0 else lerpf(3.7, 4.2, shape)
		var tangent := jitter.slide(n)
		var aim := axis + jitter * 0.60
		var speed_share := lerpf(0.72, 1.0, motion)
		var drag := 0.09
		var spin := lerpf(4.8, 9.0, absf(turn * 2.0 - 1.0))
		if not quick:
			aim = axis * 0.42 + tangent * 0.67 + n * 0.40
			speed_share = lerpf(0.14, 0.25, motion) if lead else lerpf(0.29, 0.51, motion)
			drag = 0.58 if lead else 0.24
			spin = lerpf(0.75, 2.35, absf(turn * 2.0 - 1.0))
		var v: Vector3 = _outward(n, aim, 0.34) * speed * speed_share * k
		var origin := p + (n * 0.18 + tangent * (0.26 if lead else 0.11)) * k
		fx.hit_fragment(origin, born, life, v, scale * size * k, fragment_heat,
			spin if turn >= 0.5 else -spin, drag, paint, profile + variant, lead, finish)
		_note(fx, "debris", fam, v, n, life)
	if extra > 0:
		fx.rng.state = shared_state


# R303: compact soot peels away from the blast. It never grows into a long-lived pale cloud.
# Chorus fumes keep kind 20; physical smoke uses the unlit, torn kind 27.
static func _gas_cloud(fx, p: Vector3, n: Vector3, T: float, k: float, col: Color, count: int, size: float, fam: String,
		alpha := 0.3, kind := 7, axis := Vector3.ZERO) -> void:
	if fx.quality == "low":
		return
	var aim: Vector3 = n if axis.length_squared() < 0.01 else _outward(n, axis)
	for j in _amount(fx, count + 1):
		var d := _outward(n, fx.rcone(aim, 0.65), 0.2)
		var v: Vector3 = d * fx.rng.randf_range(1.8, 4.2) * k * fx.unit
		var life: float = fx.rng.randf_range(GAS_LIFE.x, GAS_LIFE.y)
		var s0: float = size * k * fx.rng.randf_range(0.6, 1.0)
		var organic: bool = kind == 20
		var soot: Color = col if organic else col * 0.20
		fx.spr(p + d * size * fx.rng.randf_range(0.02, 0.10) * k, T + 0.035 + j * 0.025, life,
			soot, alpha if organic else minf(alpha * 2.2, 0.85), s0 * 0.65, s0 * fx.rng.randf_range(1.15, 1.65),
			20 if organic else (27 if kind == 7 else kind), v, 0.7)
		_note(fx, "gas", fam, v, n, life)


# Embers: slow cooling flecks that hang near the plate and cool yellow-white to dark red, with no flicker.
static func _embers(fx, p: Vector3, n: Vector3, T: float, k: float, count: int, fam: String, col: Color, kind: int) -> void:
	for j in _amount(fx, int(ceil(count * 1.5))):
		var d := _outward(n, fx.rcone(n, 0.85), 0.2)
		var v: Vector3 = d * fx.rng.randf_range(0.6, 3.2) * k * fx.unit
		var life: float = fx.rng.randf_range(EMBER_LIFE.x, EMBER_LIFE.y)
		fx.spr(p, T + fx.rng.randf() * 0.12, life, col, 1.6, 0.18 * k, 0.09 * k, kind, v, 0.5, 0.0, 0.0, 6.0)
		_note(fx, "ember", fam, v, n, life)


# The hot spot on the plate: white-hot, then orange, red and out over the family's time (no flicker). The mark the hit
# cut into the hull (fx_breach, R43) stays after it as the scar.
static func _heat_spot(fx, p: Vector3, T: float, k: float, size: float, fam: String, px := 6.0, i := 2.0, src = null) -> void:
	var life: float = float(HEAT_LIFE.get(fam, 2.0))
	_note(fx, "heat", fam, Vector3.ZERO, Vector3.UP, life, px)
	# The persistent torn mark already has the target material and its own heat. Never put molten metal over glass,
	# tissue or the blue plasma scar. Metal afterglow is attached to the hull, including its recoil and turns.
	if src != null and (not _impact_response(src).get("hot_plate", false) or fam == "energy"):
		return
	if src == null:
		fx.spr(p, T + 0.04, life, Color(1, 0.5, 0.15), i, size * k, size * k * 0.8, 21, Vector3.ZERO, 0.0, 0.0, 0.0, px)
		return
	var lp: Vector3 = src.xf().affine_inverse() * p
	var faction_glow: bool = _impact_response(src).get("faction_glow", false)
	var col: Color = src.fac.damage_glow if faction_glow else Color(1, 0.5, 0.15)
	var kind := SH.TICK_EMBER if faction_glow else 21
	fx.later(T + 0.04, func l_hull_heat() -> void:
		if src.dead or src.gone or not is_instance_valid(src._dmg_root): return
		# Issue 1558 item 10: a small ring of heat spots on each hull (fx_pool Pool), written in place, instead of a new
		# Batch, ArrayMesh and MeshInstance3D for every metal hit. The oldest spot is reused when the ring wraps.
		var pool = _heat_pool(fx, src)
		pool.emit(POOLS.pack(Vector4(lp.x, lp.y, lp.z, T + 0.04), Vector4(0, 0, 0, life),
			Vector4(col.r, col.g, col.b, i), Vector4(size * k * fx.unit, size * k * fx.unit * 0.8, kind, px + 0.31), Vector4.ZERO))
		pool.flush())


const HEAT_RING := 48   # spots kept per hull: lance and torpedo spots live 3 to 4 s, so this holds a dozen hits a second before the oldest is reused


static func _heat_pool(fx, src):
	var pools: Dictionary = fx.dstate.get("heat_pools", {})
	var pool = pools.get(src.id)
	if pool == null or not is_instance_valid(pool.mi) or pool.mi.get_parent() != src._dmg_root:
		# Issue 1237 (Neon F7.2): one shared sprite material for every hull heat spot (the data is in the vertices).
		if not fx.dstate.has("heat_spot_mat"): fx.dstate["heat_spot_mat"] = fx.mat(SH.SPRITE, 1)
		pool = POOLS.Pool.new(HEAT_RING, fx.dstate["heat_spot_mat"], src._dmg_root, "fx_hit_heat", POOLS.quad_shape())
		pools[src.id] = pool
		fx.dstate["heat_pools"] = pools
	return pool


static func _hit_impulse(lk: String, weight: int, critical: bool) -> float:
	return float(REACT_IMPULSE.get(lk, 0.5)) * [0.7, 0.85, 1.0, 1.3, 1.6][clampi(weight, 0, 4)] * (1.6 if critical else 1.0)


static func _impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, hd: Dictionary, k: float, sustain: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var crit = bool(hd.get("crit", false))
	var torp = lk in ["torp", "rockets", "star", "ram"]
	var beam = family_of(lk) == "lance"
	var bio = lk in ["spine", "tendril", "sporeb", "spores"]
	var light = lk in ["auto", "junk", "las", "scatter", "guns", "flak", "pflak", "mflak", "gflak", "gsentry", "prism"]
	var shield_only: bool = bool(tg.get("shield", false))
	var hull_damage := float(hd.get("hull", 0)) > 0.0
	var breaking: bool = bool(tg.get("breaking", false))
	if tg.has("through") and breaking:
		# Let the shield failure read before the hull catches the rest of the shot.
		T += BREAK_HULL_BEAT
	# Momentum and the ship's electrical response have separate inputs.
	if Tg != null:
		var absorbed := shield_only or (float(hd.get("shield", 0)) > 0.0 and not hull_damage)
		var imp := _hit_impulse(lk, w, crit) * (ABSORBED_IMPULSE if absorbed else 1.0)
		var lhp: Vector3 = tg["lp"] if tg.has("lp") else Tg.xf().affine_inverse() * p
		var ldr: Vector3 = (Tg.xf().basis.inverse() * dir).normalized()
		var ion := lk == "ion"
		# R412 rule 4 (Neon on PR 1699): a shield block is quiet: no brownout and no engine stutter for an absorbed lance,
		# ion or crit; only real hull damage, a shield break, a crit or an ion hit that reaches the hull
		var felt: bool = not absorbed or breaking
		var brownout := felt and (crit or ion or (beam and lk != "needle") or (hull_damage and (w >= 3 or lk == "gauss")))
		var dip := (0.70 if crit else (0.62 if ion or w >= 3 else 0.48)) if brownout else 0.0
		var duration := 0.38 + (dip - 0.40) * 0.85
		fx.later(T, func l_hit_react() -> void:
			Tg.hit_react(fx, imp, lhp, ldr, "shield" if absorbed and not breaking else "hull")
			Tg.hit_power(fx, felt and (hull_damage or breaking or crit or ion), dip, duration))
		if bio and not shield_only:
			# R398 (issue 1394): where acid ate into the hull, so an acid kill glows green only there
			var normal: Vector3 = tg.get("ln", Vector3.UP)
			fx.later(T, func l_acid_spot() -> void:
				var sp: Array = Tg.get_meta("acid_spots", [])
				sp.append([lhp, fx.now, normal])
				while sp.size() > MELT_SPOTS: sp.pop_front()
				Tg.set_meta("acid_spots", sp))
	var fraction := 0.0 if breaking else float(hd.get("shieldFraction", -1.0))
	if shield_only:
		_shield_impact(fx, lk, w, Tg, tg, T, dir, k, sustain, torp, beam, bio, light, col, fraction)
		return
	if tg.has("through") and Tg != null and not breaking:
		var th: Dictionary = tg["through"]
		if lk == "ion":
			_shield_impact(fx, lk, w, Tg, th, T - 0.02, dir, k, sustain, false, true, false, false, col, fraction)
		else:
			Tg.shield_hit(fx, th["local"], T - 0.02, 0.5, 8.0 * k, 0.4, fraction)
	# every weapon leaves its own mark in the hull itself (R43; fx_breach.marks_for): burn-throughs, craters, punctures,
	# blast holes, pockmarks, acid pits, electrical burns
	if Tg != null and tg.has("lp"):
		var ld: Vector3 = (Tg.xf().basis.inverse() * dir).normalized()
		var lp0: Vector3 = tg["lp"]
		var ln0: Vector3 = tg["ln"]
		# Send the null lance's own look in both modes. marks_for keeps R416's three cuts with V2 on
		# and makes Build F's single sealed trench with V2 off. Explicit mark overrides still win.
		var wound_look: String = tg.get("mark_look", {"plasma_cannon": "plasma", "gsentry": "gflak", "junk": "auto"}.get(lk, lk))
		fx.later(T, func l_mark() -> void: Tg.add_mark(fx, wound_look, w, lp0, ln0, ld))
	var matter_k: float = k * sqrt(float(tg.get("gk", 1.0)))
	if beam:
		_beam_burn(fx, lk, Tg, tg, T, sustain, col, matter_k, w, dir)
	elif bio:
		_bio_splat(fx, Tg, tg, T, col, matter_k, lk == "tendril", w)
	elif lk == "gauss":
		_gauss_punch(fx, Tg, tg, T, dir, col, matter_k, w)
	elif torp:
		_big_hit(fx, Tg, tg, T, matter_k * (1.5 if lk == "ram" else (0.65 if lk == "rockets" else 1.0)), col, lk == "star", lk)
	elif _old_look(fx):
		_impact_old(fx, lk, w, Tg, tg, T, col, dir, k, light)
	elif lk in ["mflak", "gsentry"] or family_of(lk) == "energy":
		_energy_hit(fx, lk, w, Tg, tg, T, col, dir, matter_k)
	else:
		_shell_hit(fx, lk, w, Tg, tg, T, col, dir, matter_k)
	if crit: _crit(fx, Tg, tg, T + CRIT_BEAT, k, col, w, not bio)


# Issue 461, the shell row (macro, autocannon, scatter, strike craft guns, flak): a short white bite on the plate, then a
# cone of sparks that skips off it (the shell's own direction reflected off the plate), torn chips, a puff of dust that
# hangs for a few seconds, embers, and a dent that glows and cools.
static func _shell_hit(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, k: float) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var fam := family_of(lk)
	var px := ladder_px(lk, w, tg)
	var gk: float = float(tg.get("gk", 1.0))
	var faction: String = Tg.faction if Tg != null else "metal"
	var response := _impact_response(Tg)
	var tint := _impact_color(response, Tg, Color(0.94, 0.67, 0.33))
	# Every physical gun gets the same finished sequence, at its own rung of the weapon ladder.
	_staged_hit(fx, Tg, p, T, false, gk, n, px)
	_note(fx, "flash", fam, Vector3.ZERO, n, 0.12, px)
	var skip: Vector3 = _outward(n, (dir - n * 2.0 * dir.dot(n)) * 0.8 + n * 0.35, 0.25)
	var heavy: float = [0.0, 0.7, 1.0, 1.35][clampi(w, 1, 3)] * gk
	if fam == "flak":
		heavy *= 0.5
	if response.debris != "drop":
		_throw_sparks(fx, p + n * 0.15 * k, n, skip, T, k, _spark_faction(Tg), int(round(17.0 * heavy)), 32.0, 0.45, fam)
	if fam != "flak" or not response.fire_body:
		_throw_debris(fx, p, n, skip, T, k, int(round(4.0 * heavy)), 11.0, 0.16, 0.7, fam, faction, lk == "macro", Tg)
	_impact_gas(fx, p + n * 0.3 * k, n, T, k, Color(0.40, 0.38, 0.36), 1 if heavy < 0.9 else 2,
		1.6 * heavy + 0.6, fam, 0.34, response, skip)
	_impact_embers(fx, p + n * 0.1 * k, n, T + 0.05, k, int(round(6.0 * heavy)), fam, response, Tg)
	_heat_spot(fx, p + n * 0.15 * k, T, k, 0.9 * (1.0 + 0.3 * float(w - 1)), fam, 5.0 + 2.0 * float(w), 2.0, Tg)
	fx.light(p + n * 0.8 * k, T, 0.30, HULL_LIGHT if w >= 2 else 5.5, tint, 0)
	fx.shake(T, 0.04 if w <= 1 else 0.08, p)


# Issue 461, the energy row (las, plasma, prism): a sharp white touch of one or two frames, then a splash that runs out
# along the plate in its own colour (molten drops skating over it), a little vapour,
# and a short scorch that glows about a second and a half. The prism adds a rainbow glint; plasma throws blue slag.
static func _energy_hit(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, k: float) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var px := ladder_px(lk, w, tg)
	var response := _impact_response(Tg)
	var contact := _impact_color(response, Tg, col)
	_staged_hit(fx, Tg, p, T, false, float(tg.get("gk", 1.0)), n, px, col, true)
	_note(fx, "flash", "energy", Vector3.ZERO, n, 0.08, px)
	# R303: the hot contact and skating drops carry the splash, without a visible disc in space.
	# drops that skate along the plate (tangent to it, a little off it), slowing as they cool
	var t1: Vector3 = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2: Vector3 = n.cross(t1)
	var run: Vector3 = (dir - n * dir.dot(n))
	run = run.normalized() if run.length() > 0.05 else t1
	if response.fire_body or response.debris == "glass":
		# Plasma leaves blue slag on metal. Obsidian and glass keep their own response.
		var slag_tint := Color.TRANSPARENT
		if response.get("hot_plate", false):
			if lk == "plasma": slag_tint = PLASMA_HOT
			elif lk == "plasma_cannon": slag_tint = col
		var scale := _spark_size(k)
		for j in _amount(fx, roundi((9 + 4 * w) * scale)):
			var a: float = fx.rng.randf() * TAU
			var tang: Vector3 = (t1 * cos(a) + t2 * sin(a) + run * 0.8).normalized()
			var d := _outward(n, tang + n * 0.12, 0.08)
			var v: Vector3 = d * fx.rng.randf_range(5.0, 13.0) * k * fx.unit
			var life: float = clampf(fx.rng.randf_range(SPARK_LIFE.x, SPARK_LIFE.y) * scale, SPARK_LIFE.x, SPARK_LIFE.y)
			fx.spark(p + n * 0.05 * k, T + fx.rng.randf() * 0.03, life, _spark_faction(Tg),
				2.0, 0.12 * scale, 0.045 * k, v, 1.8, 2.0, 5.0, fx.SparkRole.HULL, slag_tint)
			_note(fx, "spark", "energy", v, n, life)
	_impact_embers(fx, p + n * 0.1 * k, n, T + 0.08, k, 4 + w, "energy", response, Tg, col * 0.35)
	if lk in ["prism", "mflak"] and response.debris != "drop":
		for j in 3:
			fx.spr(p + n * 0.2 * k, T + j * 0.04, 0.35, contact, 2.6, 0.5 * k, 0.9 * k, 16, Vector3.ZERO, 0.0, 0.0, 0.0, px * 0.6)
	if lk == "plasma" or not response.fire_body:
		_throw_debris(fx, p, n, n, T, k, 2 + w, 5.0, 0.12, 1.0, "energy", Tg.faction if Tg != null else "metal", false, Tg)
	if lk == "plasma" or response.debris == "drop":
		# a little slag vapour; las and prism leave no smoke (playbook: "A tiny hot spark. No smoke.")
		_impact_gas(fx, p + n * 0.2 * k, n, T, k, Color(0.36, 0.40, 0.46), 1, 1.4, "energy", 0.2, response)
	_heat_spot(fx, p + n * 0.12 * k, T, k, 0.7 * (1.0 + 0.3 * float(w - 1)), "energy", 5.0 + 1.5 * float(w), 2.0, Tg)
	fx.light(p + n * 0.7 * k, T, 0.26, 6.5 if w <= 1 else HULL_LIGHT, contact, 0)
	fx.shake(T, 0.03 if w <= 1 else 0.06, p)


# The pre-Cone-B look ("today"), only for the review capture's before stills.
static func _impact_old(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, col: Color, dir: Vector3, k: float, light: bool) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var size := (3.8 if light else (5.6 if w <= 2 else 7.0)) * k
	var tint: Color = col if lk in ["las", "prism", "plasma", "pflak", "mflak", "gflak"] else Color(0.94, 0.67, 0.33)
	tint = _impact_color(_impact_response(Tg), Tg, tint)
	_burst(fx, p+n*0.35*k, n, T, size, "flash", 0.24 if light else 0.32, tint, 4.2, HIT_PX[clampi(w,1,3)])
	_vent(fx, p+n*0.5*k, n, T+0.025, size*0.85, 0.38, tint, 0.9, n*4.0*k, 0.55, 1.0, w, Tg, true)
	_impact_sparks(fx, p + n * 0.15 * k, (n - dir * 0.25).normalized(), T, k, _spark_faction(Tg), 7 if light else 12)
	_afterglow(fx,p+n*0.25*k,T,tint,size*0.45,light)
	fx.light(p+n*2.0*k,T,0.22,5.0 if light else HULL_LIGHT,tint,0)


# A short cooling atlas over the contact point and a dim hot spot on the plate.
static func _afterglow(fx, p: Vector3, T: float, col: Color, sz: float, light: bool, px := 0.0) -> void:
	_burst(fx,p,Vector3.UP,T+0.08,sz*0.9,"cool",0.42 if light else 0.50,col,0.55,0.0,Vector3.ZERO,0.40)
	fx.spr(p,T,0.7 if light else 1.0,col,1.0,sz*0.18,sz*0.13,21)


static func _shield_impact(fx, lk: String, w: int, Tg, tg: Dictionary, T: float, dir: Vector3, k: float, sustain: float, torp: bool, beam: bool, bio: bool, light: bool, col := Color.WHITE, fraction := -1.0) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var sc: Color = Tg.fac["shield"] if Tg != null else FLOOK.shield("hegemony")
	var strength = 0.6 if light else (1.0 if w <= 2 else 1.4)
	var spread = (9.0 if light else 14.0) * k
	var life = float(fx.timing.get("shield", 0.6))
	if torp:
		strength = 2.2
		spread = 26.0 * k
		life = 1.1
	elif lk == "ion":
		strength = 1.5
		life = maxf(sustain, 0.3) + 0.55
		spread = 22.0 * k
	elif beam:
		life = maxf(sustain, 0.3) + 0.5
		spread = 16.0 * k
	elif lk == "gauss":
		strength = 1.6
		spread = 7.0 * k
		life = 0.45
	elif lk in ["flak", "pflak", "gflak", "gsentry", "mflak", "spores", "guns"]:
		strength = 0.35
		spread = 4.0 * k
		life = 0.3
	strength *= 1.3
	if Tg != null:
		Tg.shield_hit(fx, tg["local"], T, strength, spread, life, fraction)
		if beam and sustain > 0.3:
			# slow rings while the beam holds (one per 0.35 s), not counted flashes
			var t = T + 0.35
			while t < T + sustain:
				Tg.shield_hit(fx, tg["local"], t, 0.6, spread * 0.8, 0.6, 0.0)
				t += 0.35
	# F3 round 2: the bubble flashes in its faction's colour where it was struck: a ripple ring racing out along the
	# bubble's surface and a soft coloured glow, each with its own size on screen, so a shield hit reads from the
	# battle camera as that ship's shield. Issue 461: a torpedo on a shield is the ladder's torpedo-on-a-shield row (a
	# 110 px flash and the biggest body of any hit, the 156 px ripple), sized by the gun and the ship as every hit is.
	var gt: float = float(tg.get("gk", 1.0)) * float(tg.get("tk", 1.0))
	var spx: float = 36.0 if light else (46.0 if w <= 2 else 56.0)
	var rpx: float = spx * 1.3
	if torp:
		spx = float(LADDER_PX["torp_shield"]) * gt * (0.65 if lk == "rockets" else 1.0)
		rpx = float(LADDER_PX["torp_ripple"]) * gt * (0.65 if lk == "rockets" else 1.0)
	# The crackle uses the ladder width as its pixel floor for both drawing and booking.
	_shield_crackle(fx, p, n, T, k, sc, spx, 3 if light else (8 if torp else 5), torp)
	_note(fx, "flash", "shield", Vector3.ZERO, n, 0.30, spx)
	# R303: hits[] draws the travelling ripple on the shield, without a flat disc.
	_note(fx, "ripple", "shield", Vector3.ZERO, n, 0.9, rpx)
	# An ordinary block keeps its ripple and local arc, never a spray.
	if bool(tg.get("breaking", false)):
		_throw_sparks(fx, p, n, n, T, k, _spark_faction(Tg), 6 if light else (16 if torp else 10), 12.0, 0.8, "shield")
	if lk == "ion":
		# Low-power forks crawl across the contact while a broader ripple races on the shield.
		var across := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		var up := n.cross(across)
		for j in _amount(fx, 6):
			var angle := TAU * float(j) / 6.0
			var tangent := across * cos(angle) + up * sin(angle)
			fx.rib(p + n * 0.10 * k, tangent, (3.2 + float(j % 2) * 1.8) * k, T + 0.025 * j,
				0.30, col, 1.25, 0.16 * k, 0.03 * k, 6)
	elif beam:
		for j in int(sustain/0.25):
			_shield_crackle(fx, p, n, T+0.2+j*0.25, k, sc, 32.0, 3, false)
	if torp:
		fx.dst(p,T,0.4,2.0*k,14.0*k,0,0.5)
		fx.shake(T, 0.12, p)
	fx.light(p+n*2.0*k,T,0.3 if not beam else sustain+0.2,HULL_LIGHT,sc,0 if not beam else 1, TORP_LIGHT_REACH if torp else 0.0)


# Shields scatter energy, never the baked gas used by hull/muzzle flash atlases.
# Keep the same flash-area booking and reduce-flashing fallback as _burst.
static func _shield_crackle(fx, p: Vector3, n: Vector3, t: float, k: float, col: Color, px: float, count: int, torp: bool) -> void:
	var power := 4.2 if torp else 3.2
	var life := 0.30
	var centre := p + n * 0.15 * k
	var size := 2.0 * k
	if not fx.flash_at(centre, t, size, SH.flash_sprite_floor(13, px), life, not torp):
		power = FLASH_LIFT_POWER if fx.flash_lift else SOFT_FLASH_POWER
		life = 0.4
	fx._emit_spr(centre, t, life, col, power, size, 0.5 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, px)
	for j in _amount(fx, count):
		var tangent: Vector3 = fx.rdir()
		tangent = (tangent - n * tangent.dot(n)).normalized()
		fx.rib(p + n * 0.08*k, tangent, fx.rng.randf_range(1.2, 2.8)*k, t + j*0.008, 0.075,
			col, 0.9, 0.08*k, 0.02*k, 6)


# Issue 461, the lance row: a contact burn that stays lit and crawls along the hull while the beam dwells (pulses at the
# ladder's lance size), spraying molten metal off the plate; a third of a second of tail when it lifts; the line it
# crawled glows for about three seconds, and the slot it cut (fx_breach) stays. The ion beam burns blue-white with
# crawling arcs and throws no molten metal; the needle is a light beam with a short crawl.
static func _beam_burn(fx, lk: String, Tg, tg: Dictionary, T: float, sustain: float, col: Color, k: float, w := 3, dir := Vector3.ZERO) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var dur := maxf(sustain,0.25)
	var steps := maxi(2,int(ceil(dur/0.09)))
	var px := ladder_px(lk, w, tg)
	var ion := lk == "ion"
	var null_lance := lk == "nlance"
	var spectral := lk in ["ion", "nlance", "doom", "needle", "pulsar"]
	var response := _impact_response(Tg)
	var contact := col if null_lance else _impact_color(response, Tg, col)
	var flash := col if null_lance else _impact_color(response, Tg, col if spectral else col.lerp(Color(1.0, 0.72, 0.38), 0.55))
	var molten := _impact_color(response, Tg, col.lerp(Color.WHITE, 0.22) if spectral else col.lerp(Color(0.97, 0.66, 0.30), 0.6))
	# the crawl: along the plate, the way the beam was sweeping (its own direction laid onto the plate)
	var run: Vector3 = dir - n * dir.dot(n)
	if run.length() < 0.05:
		run = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT)
	run = run.normalized()
	var reach: float = (clampf(Tg.hull.L * 0.10, 1.0, 4.0) if Tg != null else 2.0) * (0.5 if lk == "needle" else 1.0)
	var start: Vector3 = p - run * reach * 0.35
	var last := p
	for j in steps:
		var u := float(j) / float(steps - 1)
		var at := T + u * dur
		var pj: Vector3 = start + run * reach * u
		var nj: Vector3 = n
		if Tg != null:
			var inv: Transform3D = Tg.xf().affine_inverse()
			var ln: Vector3 = (inv.basis * n).normalized()
			var hit: Dictionary = Tg.hull.ray(inv * pj + ln * Tg.hull.W, -ln)
			if not hit.is_empty() and Tg.to_world(hit["p"]).distance_to(pj) < reach:
				pj = Tg.to_world(hit["p"])
				nj = Tg.dir_world(hit["n"])
		last = pj
		if j % 2 == 0:
			if null_lance and not response.get("hot_plate", false):
				# A clean, budgeted flare. Do not borrow the struck material's green or warm tint.
				fx.spr(pj + nj * 0.3 * k, at, 0.16, flash, 4.2, 2.0 * k, 2.0 * k, 13,
					Vector3.ZERO, 0.0, 0.0, 0.0, px * BURST_PX_K)
			else:
				_impact_flash(fx, Tg, pj, nj, at, k, 4.0 * k, 0.16, flash, px * BURST_PX_K, response, 0.3 * k, 4.2)
			_note(fx, "flash", "lance", Vector3.ZERO, nj, 0.16, px)
		fx.spr(pj + nj * 0.2 * k, at, 0.18, contact, 3.0, 1.2 * k, 1.6 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, px * 0.45)
		# The null trench carries its own violet heat, with no orange plate spot or molten metal.
		if not null_lance:
			_heat_spot(fx, pj + nj * 0.1 * k, at, k, 0.55, "lance", 5.0, 1.5, Tg)
		if not ion and not null_lance and (response.fire_body or response.debris == "glass"):
			# molten metal sprays off the plate: drips with a short trail, and sparks
			var scale := _spark_size(k)
			for s in _amount(fx, roundi(5.0 * scale)):
				var d := _outward(nj, fx.rcone((nj + run * 0.6).normalized(), 0.55), 0.2)
				var v: Vector3 = d * fx.rng.randf_range(4.0, 11.0) * k
				var life: float = clampf(fx.rng.randf_range(SPARK_LIFE.x, SPARK_LIFE.y) * scale, SPARK_LIFE.x, SPARK_LIFE.y)
				fx.spark(pj, at + fx.rng.randf() * 0.05, life, _spark_faction(Tg), 2.0, 0.12 * scale, 0.10 * k, v, 0.7, 3.0, 8.0)
				_note(fx, "spark", "lance", v, nj, life)
		elif ion and j % 2 == 0:
			fx.rib(pj, _outward(nj, fx.rdir(), 0.3), 1.8 * k, at, 0.09, molten, 1.2, 0.12 * k, 0.04 * k, 6)
	if not ion and not null_lance:
		_impact_embers(fx, p, n, T + dur * 0.3, k, 6, "lance", response, Tg, col * 0.28)
		_throw_debris(fx, last, n, (n + run * 0.5).normalized(), T + dur * 0.6, k, 2, 5.0, 0.12, 1.0, "lance", Tg.faction if Tg != null else "metal", false, Tg)
	if ion:
		_impact_embers(fx, last, n, T + dur, k, 5, "lance", response, Tg, col * 0.28)
		_ion_crawl(fx, Tg, p, n, T, contact, k)
	# the tail when the beam lifts: the contact glow fades over a third of a second
	fx.spr(last + n * 0.2 * k, T + dur, 0.33, contact, 2.6, 1.6 * k, 1.0 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, px * 0.4)
	if not null_lance:
		_impact_gas(fx, p + n * 0.3 * k, n, T + 0.2, k, molten.lerp(Color(0.38, 0.37, 0.36), 0.75),
			3, 2.2, "lance", 0.28, response, (n + run * 0.7).normalized())
	if lk == "doom":
		for j in 3: fx.rib(p,fx.rcone(n,0.8),2.5*k,T+j*0.12,0.1,contact,1.0,0.15*k,0.05*k,6)
	# Doom lights only the struck plating. The existing mark cools into a scar.
	fx.light(p+n*0.6*k if lk == "doom" else p+n*2.0*k,T,dur+0.15,6.5,contact,1,4.5*k if lk == "doom" else 0.0)
	fx.shake(T,0.1,p)


# Issue 1587: an ion hull hit crawls. 2 or 3 short (0.4 s) lightning threads jump from the contact across nearby plating
# (each lands on the hull where a ray finds it), and the struck ship's lights brown out for half a second (power_dip).
static func _ion_crawl(fx, Tg, p: Vector3, n: Vector3, T: float, col: Color, k: float) -> void:
	var hot: Color = col.lerp(Color.WHITE, 0.35)
	var reach: float = clampf(Tg.hull.L * 0.12, 1.2, 5.0) if Tg != null else 2.0
	var inv: Transform3D = Tg.xf().affine_inverse() if Tg != null else Transform3D.IDENTITY
	for j in 2 + (1 if fx.rng.randf() < 0.5 else 0):
		var tang: Vector3 = fx.rdir()
		tang = (tang - n * tang.dot(n)).normalized()
		if tang.length() < 0.1:
			tang = n.cross(Vector3.UP).normalized()
		var q: Vector3 = p + tang * reach * fx.rng.randf_range(0.5, 1.0)
		if Tg != null:
			var ln: Vector3 = (inv.basis * n).normalized()
			var hit: Dictionary = Tg.hull.ray(inv * q + ln * Tg.hull.W, -ln)
			if not hit.is_empty() and Tg.to_world(hit["p"]).distance_to(q) < reach:
				q = Tg.to_world(hit["p"])
		var d: Vector3 = q - p
		if d.length() < 0.05:
			continue
		var at := T + 0.05 + j * 0.11
		fx.rib(p + n * 0.1 * k, d.normalized(), d.length(), at, 0.4, hot, 1.3, 0.10 * k, 0.03 * k, 6)
		fx.spr(q + n * 0.1 * k, at + 0.05, 0.25, col, 1.6, 0.5 * k, 0.9 * k, 13)
	# The crawl's own half-second power_dip is gone (Artoo on PR 1699): the hit's brownout (hit_power, issue 1690) is the
	# one transient dip for an ion hit, so the two never multiply on the hull's lights.


# The Chorus row: a dim pressure burst and drifting bile droplets (no metal fireball), and an acid fume that hangs over
# the wound for a few seconds while the acid keeps eating (fx_breach style 8).
static func _bio_splat(fx, Tg, tg: Dictionary, T: float, col: Color, k: float, lash: bool, w := 2) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var px: float = 28.0 * float(tg.get("gk", 1.0)) * float(tg.get("tk", 1.0))
	_burst(fx,p+n*0.3*k,n,T,4.5*k,"flash",0.35,col,1.4,px)
	_vent(fx,p+n*0.4*k,n,T,5.0*k,0.65,col,0.8,n*3.0*k,0.65,1.0,w,Tg,true,false)
	for j in 8:
		var d := _outward(n, fx.rcone(n,0.9), 0.2)
		var v: Vector3 = d*fx.rng.randf_range(3.0,7.0)*k
		var life: float = fx.rng.randf_range(1.8, 3.6)
		fx.spr(p,T+j*0.015,life,col,1.2,0.42*k,0.22*k,15,v,0.35)
		_note(fx, "drop", "bio", v, n, life)
	_burst(fx,p+n*k,n,T+0.12,4.5*k,"cool",0.8,col,0.5,0.0,n*k,0.45)
	_gas_cloud(fx, p + n * 0.4 * k, n, T + 0.1, k, col.lerp(Color(0.3, 0.32, 0.18), 0.5), 2, 2.4, "bio", 0.30, 20)
	_heat_spot(fx, p + n * 0.1 * k, T, k, 0.7, "bio", 5.0, 0.6, Tg)
	fx.light(p+n*2.0*k,T,0.55,3.0,col,1)
	fx.shake(T,0.1 if lash else 0.05,p)


static func _gauss_punch(fx, Tg, tg: Dictionary, T: float, dir: Vector3, col: Color, k: float, w: int) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var response := _impact_response(Tg)
	var tint := _impact_color(response, Tg, col.lerp(Color.WHITE, 0.25))
	var px: float = float(LADDER_PX["shell"][clampi(w, 1, 3)]) * float(tg.get("gk", 1.0)) * float(tg.get("tk", 1.0))
	_impact_flash(fx, Tg, p, n, T, k, 4.5 * k, 0.14, tint, px * BURST_PX_K, response, 0.35 * k)
	_note(fx, "flash", "shell", Vector3.ZERO, n, 0.14, px)
	if response.debris != "drop":
		_throw_sparks(fx, p, n, n, T, k, _spark_faction(Tg), 12, 20.0, 0.6, "shell")
	if Tg != null:
		if not response.fire_body:
			_throw_debris(fx, p, n, n, T, k, 3, 8.0, 0.16, 0.0, "shell", Tg.faction, false, Tg)
			_impact_gas(fx, p, n, T, k, Color.BLACK, 1, 1.5, "shell", 0.26, response)
		var inv: Transform3D = Tg.xf().affine_inverse()
		var lp: Vector3 = inv*p
		var ld: Vector3 = (inv.basis*dir).normalized()
		var far: Dictionary = Tg.hull.ray(lp+ld*(Tg.hull.L+Tg.hull.W)*2.0,-ld)
		if not far.is_empty():
			var xp: Vector3 = Tg.to_world(far["p"]); var xn: Vector3 = Tg.dir_world(far["n"])
			if response.get("hot_plate", false):
				_vent(fx,xp+xn*0.3*k,xn,T+0.04,5.5*k,0.42,tint,1.2,dir*6.0*k,0.7,1.0,w,Tg,true)
			# the exit spray leaves along the slug's own line, out of the far side
			if response.debris != "drop":
				_throw_sparks(fx, xp, xn, (dir + xn).normalized(), T + 0.04, k,
					_spark_faction(Tg), 10, 22.0, 0.4, "shell")
			_throw_debris(fx, xp, xn, dir, T + 0.04, k, 3, 10.0, 0.2, 0.6, "shell", Tg.faction, false, Tg)
			_impact_gas(fx, xp + xn * 0.3 * k, xn, T + 0.08, k, Color(0.40, 0.39, 0.38), 1, 2.0, "shell", 0.26, response)
			_impact_embers(fx, xp, xn, T + 0.05, k, 4, "shell", response, Tg)
	_heat_spot(fx, p + n * 0.15 * k, T, k, 0.8, "shell", 6.0, 2.0, Tg)
	fx.light(p+n*2.0*k,T,0.22,HULL_LIGHT,tint,0)
	fx.shake(T,0.2 if w>=3 else 0.12,p)
	if w>=3: fx.hit_pause(T,3)


# The impact primitive samples the existing baked fire and flow. Its heat map rejects the cold outer lobes, so smoke
# can be a short directional plume instead of three opaque balls. No extra screen pass or new texture is involved.
static func hull_impact_material(fx, rel: String) -> ShaderMaterial:
	# Issue 1237 (Neon F7.2): the shader text is put together once per fx node, not with five replaces on every hit.
	if fx.dstate.has("hull_impact_code"):
		return DEATH.route_material(fx, fx.dstate["hull_impact_code"], rel, true, 0)
	var code: String = SH.patch(SH.DEATH_FLIPBOOK, "uniform float smoke_tone = 1.0;", """uniform float smoke_tone = 1.0;
uniform float impact_body = 0.0;
uniform float impact_tinted = 0.0;
uniform float impact_clean = 0.0;
uniform float impact_prism = 0.0;
uniform vec3 impact_tint = vec3(1.0);""")
	code = SH.patch(code, "float a = floor(frame);", """// The first hot cells unfold before the cool cells. Full white heat ends well before 0.25 s.
	float body_frame = age < 0.68 ? age * (3.5 / 0.68) : 3.5 + (age - 0.68) * (11.5 / 0.32);
	float flash_frame = mix(age, max(0.0, (age - 0.5) * 2.0), softened) * 3.5;
	frame = mix(flash_frame, body_frame, impact_body);
	float a = floor(frame);""")
	code = SH.patch(code, "max(extent * 0.1, 0.05)", "max(extent * 0.015, 0.035)")
	code = SH.patch(code, "float fade = 1.0 - smoothstep(0.70, 1.0, age);", """float luminance = dot(gas.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 fringe = impact_tint;
	if (impact_prism > 0.0) {
		vec2 c = UV - 0.5;
		float phase = atan(c.y, c.x + 0.00001);
		vec3 bow = 0.55 + 0.45 * cos(phase + vec3(0.0, 2.0943951, 4.1887902));
		fringe = mix(fringe, bow, impact_prism * smoothstep(0.12, 0.42, length(c)) * 0.55);
	}
	vec3 coloured = mix(fringe, vec3(0.95, 0.97, 1.0), smoothstep(0.65, 1.0, luminance)) * luminance * power * fx_gain * 1.8;
	coloured *= mix(1.0, sin(age * 3.14159265), softened);
	ALBEDO = mix(ALBEDO, coloured, impact_tinted);
	float fade = 1.0 - smoothstep(0.70, 1.0, age);""")
	# Keep the lit core and strip out the atlas's dim smoke lobes for non-metal hits.
	code = SH.patch(code, "ALPHA = gas.a * fade * soft",
		"ALPHA = gas.a * smoothstep(0.035, 0.18, thick.b) * mix(1.0, smoothstep(0.1, 0.4, luminance), impact_clean) * fade * soft")
	fx.dstate["hull_impact_code"] = code
	return DEATH.route_material(fx, code, rel, true, 0)


# Flash and body have separate clocks. The weapon ladder sizes both, and a softened flash softens the body too.
# The resolved weapon rung includes gun and target bands. The target band also places the fire just off its hull. Both pictures use the lopsided baked seed (s0) turned at random: the round seeds (s1, s2) drew
# the "flower" of equal puffs Ryan called "too even and weird" on the deaths (issue 484), and they did the same here.
static func _staged_hit(fx, src, p: Vector3, T: float, torpedo: bool, ks := 1.0, n := Vector3.UP, rung := 0.0,
		tint := Color(1, 0.55, 0.15), energy := false, flash_life := 0.0, flash_lift := 0.0,
		use_contact_tint := false) -> void:
	var response := _impact_response(src)
	var contact := tint if use_contact_tint else _impact_color(response, src, tint)
	var clean: bool = not response.get("hot_plate", false)
	var tinted := energy or clean
	var flash_only := flash_life > 0.0
	var band := DEATH.atlas_band(float(src.hull.L)) if src != null else "cruiser"
	var target_scale: float = {"small": 0.8, "cruiser": 1.0, "capital": 1.2}[band]
	var flash_px: float = (float(LADDER_PX["torp"]) if torpedo else float(LADDER_PX["shell"][2])) * target_scale * ks
	flash_px = rung if rung > 0.0 else flash_px
	var body_px: float = flash_px * (0.72 if energy else (0.86 if torpedo else 0.94))
	var life := flash_life if flash_only else (0.16 if torpedo else (0.08 if energy else 0.12))
	if response.debris == "glass":
		life = minf(life, 0.12)
	var lift_from_plate := flash_lift
	if not flash_only:
		lift_from_plate = minf(float(src.hull.L) * 0.045, 1.1 * target_scale * ks) if src != null else 0.85
	var centre := p + n * lift_from_plate
	var extent: float = flash_px * DEATH.STAGING_UNITS_PER_PIXEL
	# The flash callback goes first. Its one permit also sets the look of the later fire body.
	var permit := {"soft": false, "lift": false}
	var spin: float = fx.rng.randf() * TAU
	var shape := Vector2(fx.rng.randf_range(0.9, 1.25), fx.rng.randf_range(0.85, 1.1))
	for body in [false, true]:
		if body and (flash_only or not response.fire_body):
			continue
		var rel: String = ("weapons/impact/" if torpedo else "weapons/macro/") + ("impact_" if body else "flash_")
		var at: float = T + (0.012 if body else 0.0)
		fx.later(at, func l_staged_hit() -> void:
			if not body:
				# The envelope includes the bloom beyond the quad. The body stays inside that footprint.
				permit.soft = not fx.flash_at(centre, T, extent / fx.unit, flash_px, life, src != null and not torpedo)
				permit.lift = permit.soft and fx.flash_lift
			var soft: bool = permit.soft or fx.reduce_flashing
			var lift: bool = permit.lift
			var duration: float = (0.30 if energy else (0.65 if torpedo else 0.46)) if body else (1.2 if lift else ((0.50 if torpedo else 0.42) if soft else life))
			var mi: MeshInstance3D = fx.picture("impact|" + rel, func() -> ShaderMaterial: return hull_impact_material(fx, rel),
				"fx_staged_body" if body else "fx_staged_flash")
			mi.set_meta("fx_picture_kind", "impact" if body else "flash")
			mi.set_meta("gas_root", p)
			mi.extra_cull_margin = 100.0
			var mat := mi.material_override as ShaderMaterial
			mat.set_shader_parameter("pic_spin", spin + (0.7 if body else 0.0))
			mat.set_shader_parameter("pic_shape", shape if body else Vector2.ONE)
			mat.set_shader_parameter("born", at)
			mat.set_shader_parameter("lifetime", duration)
			mat.set_shader_parameter("extent", (body_px if body else flash_px) * DEATH.STAGING_UNITS_PER_PIXEL)
			mat.set_shader_parameter("min_pixels", body_px if body else flash_px)
			mat.set_shader_parameter("impact_body", 1.0 if body else 0.0)
			mat.set_shader_parameter("impact_tinted", 1.0 if tinted else 0.0)
			mat.set_shader_parameter("impact_clean", 1.0 if clean else 0.0)
			mat.set_shader_parameter("impact_prism", response.get("prism", 0.0))
			mat.set_shader_parameter("impact_tint", Vector3(contact.r, contact.g, contact.b))
			# Include the bloom in the flash booking; the body stays inside that footprint.
			mat.set_shader_parameter("size_divisor", 1.0 if body else (0.98 if soft else 1.35))
			# Crop to the baked fireball, rather than stretching its three outer smoke lobes over the ship.
			if body:
				mat.set_shader_parameter("atlas_rect", Vector4(0.22, 0.24, 0.56, 0.52))
				mat.set_shader_parameter("smoke_tone", 0.14)
			var calm_power := 1.0 if body else SOFT_FLASH_POWER
			mat.set_shader_parameter("calm_intensity", calm_power)
			mat.set_shader_parameter("intensity", (FLASH_LIFT_POWER if lift and not body else calm_power) if soft else (3.8 if body else 5.2))
			mat.set_shader_parameter("soft_flash", 1.0 if soft else 0.0)
			# The fire expands out of the actual impact face. Keep its recorded root on that face.
			mi.global_position = centre
			fx.record_spawn(src, p)
			fx.later(at + duration + 0.1, fx.free_picture.bind(weakref(mi), int(mi.get_meta("pic_gen"))))
		)


# Issue 461, the torpedo row: the baked flash and the fire seen through gas (route B, flame inside its 0.70 s), then the
# matter: torn plates and slag thrown off the plate in a cone, sparks, compact soot that clears in a couple of
# seconds, embers, a wound that glows and cools over about four seconds (the crater, fx_breach, stays), and a light that
# reaches the hulls about two hexes round it for the length of the flash.
static func _big_hit(fx, Tg, tg: Dictionary, T: float, k: float, col: Color, star: bool, lk := "torp") -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var response := _impact_response(Tg)
	var tint := _impact_color(response, Tg, col)
	var gk: float = float(tg.get("gk", 1.0))
	var rk: float = 0.65 if lk == "rockets" else 1.0
	_staged_hit(fx, Tg, p, T, true, gk * rk, n, 0.0, tint, star)
	_note(fx, "flash", "torp", Vector3.ZERO, n, 0.16, ladder_px(lk, 3, tg))
	var m: float = gk * rk
	if response.debris != "drop":
		_throw_sparks(fx, p + n * 0.2 * k, n, n, T, k, _spark_faction(Tg), int(round(28.0 * m)), 38.0, 0.75, "torp")
	_throw_debris(fx, p, n, n, T, k, int(round(9.0 * m)), 18.0, 0.28, 0.9, "torp", Tg.faction if Tg != null else "metal", false, Tg)
	if not star:
		_impact_embers(fx, p + n * 0.2 * k, n, T + 0.1, k, int(round(10.0 * m)), "torp", response, Tg)
	if star and response.debris != "drop":
		# The little sun breaks into glinting glass and light after the core flash.
		for j in _amount(fx, 8):
			var ray := _outward(n, fx.rcone(n, 1.0), 0.2)
			fx.spr(p + n * 0.3 * k, T + 0.04 + j * 0.014, 0.55, tint, 2.6, 0.78 * k, 0.24 * k,
				16, ray * fx.rng.randf_range(16.0, 30.0) * k, 0.75, 0.0, 0.0, 15.0)
		fx.spr(p + n * 0.4 * k, T + 0.12, 0.50, tint, 1.6, 1.8 * k, 0.5 * k, 13, Vector3.ZERO, 0.0, 0.0, 0.0, 23.0)
	else:
		_impact_gas(fx, p + n * 0.3 * k, n, T + 0.08, k, Color(0.36, 0.34, 0.33), 3, 4.5 * m, "torp", 0.30, response)
		_heat_spot(fx, p + n * 0.3 * k, T + 0.1, k, 1.6 * m, "torp", 12.0 * m, 1.8, Tg)
	fx.dst(p, T, 0.18, k, HIT_DISTORT_REACH * k, 0, 0.28)
	fx.light(p+n*0.9*k,T,0.42,HULL_LIGHT,tint,0, TORP_LIGHT_REACH * m)
	fx.shake(T,0.4,p); fx.hit_pause(T,4); fx.punch(T,0.012,p)


static func _crit(fx, Tg, tg: Dictionary, T: float, k: float, col: Color, w := 2, with_sparks := true) -> void:
	var p: Vector3 = tg["p"]; var n: Vector3 = tg["n"]
	var response := _impact_response(Tg)
	# This extra beat belongs to the opened target, not the incoming round. Non-metal crits only use the clean,
	# tinted contact pass, never the raw orange bake, the warm glass ricochet tint, or the heated metal vent.
	var glow: Color = Tg.fac.damage_glow if Tg != null else col
	if response.get("hot_plate", false):
		_impact_flash(fx, Tg, p, n, T, k, 6.0 * k, 0.25, glow, 40.0, response, 0.5 * k)
		_vent(fx,p+n*k,n,T+0.05,6.0*k,0.45,glow,0.8,n*5.0*k,0.6,1.0,w,Tg,true,with_sparks)
	else:
		_staged_hit(fx, Tg, p, T, false, k, n, 40.0 / BURST_PX_K, glow, true, 0.25, 0.5 * k, true)
		if response.debris == "drop":
			_impact_gas(fx, p + n * k, n, T + 0.05, k, Color.BLACK, 2, 2.4, "shell", 0.3, response)
	fx.spr(p + n * 0.75 * k, T + 0.04, 0.34, glow, 2.1, 2.0 * k, 0.7 * k, 13, n * 2.0 * k, 0.0, 0.0, 0.0, 25.0)
	if with_sparks and response.debris != "drop":
		_throw_sparks(fx, p, n, n, T, k * 1.2, _spark_faction(Tg), 10, 18.0, 0.8, "shell")
	_throw_debris(fx,p,n,n,T,k,3,8.0,0.2,0.8,"shell",Tg.faction if Tg != null else "metal",false,Tg)
	fx.light(p+n*2.0*k,T,0.3,7.5,glow,0)
	fx.shake(T,0.15,p); fx.hit_pause(T,2); fx.punch(T,0.006,p)


const TURRET_LIGHT_KICK := 0.14   # a turreted gun outside SHOOTER_RECOIL: its barrel stroke (heavy guns 0.30 to 0.42)


static func _miss_fade(fx, lk: String, Tg, tg: Dictionary, from: Vector3, fire_at: float, T: float, col: Color, dir: Vector3, k: float) -> float:
	var exit: Vector3 = tg["p"]
	if family_of(lk) == "lance":
		if lk != "needle":
			fx.spr(exit, T, 0.4, col, 2.0, 2.0 * k, 3.0 * k, 18)
		return T
	if lk == "ram":
		return T
	var flight := maxf(T - fire_at, 0.001)
	if tg.has("pass"):
		var point: Vector3 = tg["pass"]
		var pass_at := lerpf(fire_at, T, from.distance_to(point) / maxf(from.distance_to(exit), 0.001))
		fx.shot_pass_by(pass_at, point)
		if Tg != null and Tg.shielded:
			fx.later(pass_at, func l_graze() -> void: _shield_graze(fx, Tg, from, dir, fx.now, k))
	# Gauss has its own cooling wake. Guided rounds and craft leave persistent exhaust, and flak bursts in the air.
	# The Acid Thorn draws its own built body flying on past (fx_acid_thorn.gd), so no streak over it (Artoo on PR 1904).
	if lk in ["gauss", "torp", "star", "rockets", "guns", "bombs", "sporeb", "tendril"] or family_of(lk) == "flak":
		return T
	var speed := from.distance_to(exit) / flight
	var life := clampf(14.0 * k / maxf(speed, 1.0), 0.08, 0.18)
	if lk == "plasma_cannon":
		fx.spr(exit, T, life, col, 1.6, 1.4 * k, 0.2 * k, 18, dir * speed, 0.0, 0.0, 0.0, 13.0)
		return T + life
	# a world-length streak (Neon on PR 1699: the length was divided by the speed, so every miss drew the same pixel-floor
	# stub) in the firing weapon's own streak kind (4 for the laser family, 0 for shells and bolts)
	var skind := 4 if lk in ["las", "prism"] else 0
	fx.flight_streak(exit, T, life, col.lerp(Color.WHITE, 0.25), 5.0, 4.0 * k,
		0.32 * k, skind, dir * speed, 0.0, 0.0, 3.0, 19.0)
	return T + life


static func _shield_graze(fx, Tg, from: Vector3, dir: Vector3, at: float, k: float) -> void:
	if Tg.dead or Tg.gone or Tg._shield_mat == null or Tg._last_sh == 0.0:
		return
	var centre: Vector3 = Tg.to_world(Tg.hull.shield_centre())
	var along := (centre - from).dot(dir)
	if along <= 0.0:
		return
	var closest := from + dir * along
	var outward := (closest - centre).normalized()
	if outward == Vector3.ZERO:
		return
	var radii: Vector3 = Tg.hull.shield_radii()
	var rim: Dictionary = Tg.shield_point(centre + outward * radii.length() * 2.0)
	var p: Vector3 = rim["p"]
	if closest.distance_to(p) <= maxf(0.35, minf(radii.y, radii.z) * 0.25):
		# A close miss only catches the edge. One small glint, with no shield reaction.
		fx.spark(p, at, 0.13, Tg.faction, 1.7, 0.04, 0.036 * k, dir * 1.5, 0.7, 0.0, 0.0, fx.SparkRole.SHIELD)


# ---------------------------------------------------------------- carriers

static func launch(fx, cid: String, sid: String) -> void:
	var C = fx.ship(cid)
	if C == null:
		return
	var S = fx.ship(sid)
	var T: float = fx.now
	# issue 370: craft leave from a hangar mouth (hp_bay), else from the plating facing up and toward the wing, and fly
	# to the wing's core; a hull with neither has nothing to launch from on screen (logged and counted)
	var toward: Vector3 = C.xf().affine_inverse() * (S.to_world(S.hull.core) if S != null else C.to_world(C.hull.core + Vector3(20, 0, 0)))
	var bay: Dictionary = C.hull.bay(int(C.get_meta("launches", 0)), toward)
	C.set_meta("launches", int(C.get_meta("launches", 0)) + 1)
	if bay.is_empty():
		return
	# issue 1543: the mouth's flesh door eases open before the first craft leaves (T + 0.3), holds while the six leave, and
	# shuts once the last is clear of the lip
	if bay.has("bay"):
		C.hull.door_cycle(int(bay["bay"]), T, T + 0.3 + 5 * 0.25 + 0.35)
	var from: Vector3 = C.to_world(bay["p"])
	var to: Vector3 = S.to_world(S.hull.core) if S != null else from + C.dir_world(Vector3(1, 0, 0)) * 20.0
	var k: float = C.scale_k()
	var axis := (to - from).normalized()
	var normal: Vector3 = C.dir_world(bay["n"])
	if axis == Vector3.ZERO:
		axis = normal
	SPECIAL.bay(fx, C, from, normal, axis, T)
	for i in 6:
		var t0 = T + 0.3 + i * 0.25
		var d = (to - from)
		var life = maxf(d.length() / 60.0, 0.05)
		var kind: String = str(S.root.get("squad_kind")) if S != null and S.root.get("squad_kind") != null else CRAFT.DEFAULT_KIND.get(C.faction, "fighter")
		var off := Vector3(0, (i % 2) * 0.3, (i % 3 - 1) * 0.65)
		SPECIAL.bay_ignite(fx, C.faction, from + off, axis, t0, k)
		_craft_run(fx, C.faction, kind, from + off, to + off, t0, life, 2.4)


