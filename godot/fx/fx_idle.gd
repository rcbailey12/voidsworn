extends RefCounted
# Issue 1685 (R411, Priority 3) & Issue 2048: layered faction idle motion pieces, behind a flag, default off until Ryan picks.
#   Hegemony    radar sweep: sensor beacon + rotating directional radar sweep wedge on top plating
#   Crusade     furnace-vent ember breath: glowing louver grate + rising warm thermal ember shimmer
#   Hullbreaker smelter flicker: rough smelter slag core + billowing heat haze & ash flecks
#   Glasswright optic shimmer: faceted crystal star + sweeping pale rainbow prism halo
#   Eclipse     corona pulse: all-violet null ring + twisting concentric violet corona arcs (R372)
#   Chorus      spore-sac swell: pulsing bioluminescent sac + branching vein glow & spore motes (no metal sparks)
# How it is built: no new geometry and no per-frame CPU work. One batch (one draw call, SH.IDLE_MOTION) per ship,
# hung under the ship's damage root so it rides the hull, at points the hull already has (hp_breach_* hard points,
# else plating found by a ray from the core; RULEBOOK 6.7). Each scheduled spot packs LAYERS_PER_SPOT (2) synchronized
# layered pieces (core anchor + outer animated faction motion) sharing one smooth sin(pi t) pulse window.
# Comfort (RULEBOOK 6.2, checked by fx/test/idle_motion_check.gd and idle_layers_2048_check.gd): every sprite sits
# under the flash counter's brightness line, none lasts under MIN_LIFE, one ship starts at most MAX_STARTS_PER_S of
# them a second, and the whole thing spends no counted flash. Reduce flashing softens it (longer, dimmer, same size);
# Reduce motion stops the radar sweep (one steady ring) and nothing else, because a swell is not movement.
# Colours come from fx/faction_looks.json (fac["damage_glow"], Hegemony fac["weapon"]), the one faction colour file.

const POOLS := preload("res://fx/fx_pool.gd")
const SH := preload("res://fx/fx_shaders.gd")

const KIND := 18                 # comfort class: soft lift, sin(pi t) envelope, never a peak
const LAYERS_PER_SPOT := 2       # core emitter anchor (layer 0) + faction animated motion piece (layer 1)
const FLASH_I_LINE := 4.0        # fx.gd FLASH_I: the intensity a short sprite would have to reach to count as a flash
const MAX_I := 3.0               # the brightest idle sprite (well under the counter's line)
const MIN_LIFE := 0.5            # no pulse is shorter than this many seconds (the sin envelope rises for half of it)
const MAX_STARTS_PER_S := 2.0    # most pulses one ship starts in a second (the W3C limit is three flashes a second)
const SOFT_LIFE := 1.6           # Reduce flashing: every life is this many times longer ...
const SOFT_I := 0.6              # ... and every brightness this share, sizes kept
const SOFT_PERIOD := 1.4         # ... and every gap this many times longer, so the start rate falls
const MAX_SPRITES := 8           # most scheduled spots one ship carries (the batch is one draw call)

const STYLE_ID := {
	"hegemony": 0,
	"voidsworn": 1,
	"corsair": 2,
	"ithar": 3,
	"deathless": 4,
	"chorus": 5,
}

# from: where the sprites sit ("top" plating rays, "breach" hard points with a top fallback). count: how many spots.
# life and period in seconds. size: Vector2 of start and end sprite size as a share of the hull length. i: brightness.
# per: sprites at each spot, scattered unevenly across the period when scatter is true.
const MOTIONS := {
	"hegemony": {"name": "radar_sweep", "label": "radar sweep", "from": "ring", "count": 4, "per": 1,
		"life": 0.9, "period": 3.6, "size": Vector2(0.03, 0.06), "i": 3.0, "scatter": false, "ring": 0.06},
	"voidsworn": {"name": "furnace_breath", "label": "furnace-vent ember breath", "from": "breach", "count": 3, "per": 1,
		"life": 3.6, "period": 4.4, "size": Vector2(0.03, 0.075), "i": 2.4, "scatter": false, "ring": 0.0},
	"corsair": {"name": "smelter_flicker", "label": "smelter flicker", "from": "breach", "count": 2, "per": 3,
		"life": 0.8, "period": 3.7, "size": Vector2(0.03, 0.06), "i": 3.0, "scatter": true, "ring": 0.0},
	"ithar": {"name": "optic_shimmer", "label": "optic shimmer", "from": "breach", "count": 4, "per": 1,
		"life": 1.2, "period": 5.3, "size": Vector2(0.025, 0.06), "i": 3.0, "scatter": false, "ring": 0.0},
	"deathless": {"name": "corona_pulse", "label": "violet corona pulse", "from": "corona", "count": 3, "per": 1,
		"life": 4.4, "period": 5.2, "size": Vector2(0.04, 0.09), "i": 2.0, "scatter": false, "ring": 0.0},
	"chorus": {"name": "sac_swell", "label": "spore-sac swell", "from": "breach", "count": 4, "per": 1,
		"life": 4.0, "period": 4.8, "size": Vector2(0.026, 0.07), "i": 2.0, "scatter": false, "ring": 0.0},
}


# The one switch. VS_IDLE_MOTION=1 (or true) turns it on for a run, 0 or false forces it off; otherwise the project
# setting rendering/effects/idle_motion (default false until Ryan picks from the Pick Sheet).
static func enabled() -> bool:
	var v := OS.get_environment("VS_IDLE_MOTION")
	if not v.is_empty():
		return v == "1" or v.to_lower() == "true"
	return bool(ProjectSettings.get_setting("rendering/effects/idle_motion", false))


static func motion_of(faction: String) -> Dictionary:
	return MOTIONS.get(faction, {})


# A plating point: a ray straight down onto the top of the hull at a share of its length ahead of (+) or behind (-) the
# middle, and a share of its width to starboard. {} when the ray misses.
static func _top(h, along: float, across := 0.0) -> Dictionary:
	var x: float = h.box.position.x + h.L * (0.5 + along)
	var z: float = h.c.z + h.W * across
	return h.surface(Vector3(x, h.c.y, z), Vector3.UP)


# Up to `want` hard points of the breach kind on the upper half of the hull, spread along it; else top plating rays.
static func _breach_spots(h, want: int) -> Array:
	var cand: Array = []
	for pt in h.points.get("breach", []):
		if (pt["n"] as Vector3).y > 0.2:
			cand.append({"p": pt["p"], "n": pt["n"]})
	var out: Array = []
	if cand.size() > want:
		# an even pick along the ship, bow to stern, so the spots are spread and the same on every build
		cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["p"] as Vector3).x < (b["p"] as Vector3).x)
		for j in want:
			out.append(cand[int(floor((float(j) + 0.5) * cand.size() / want))])
	else:
		out = cand
	var fallback := [[0.0, 0.0], [0.22, -0.12], [-0.22, 0.12], [0.36, 0.1], [-0.36, -0.1]]
	var k := 0
	while out.size() < want and k < fallback.size():
		var t := _top(h, fallback[k][0], fallback[k][1])
		if not t.is_empty():
			out.append(t)
		k += 1
	return out


# The spots for a motion, each {p, n} in the hull frame. May be fewer than the table asks for (a hull with no plating
# found); empty means the ship has no idle motion (nothing is drawn, nothing is faked at a box corner).
static func spots(h, m: Dictionary, still: bool) -> Array:
	var out: Array = []
	match String(m["from"]):
		"ring":
			var t := _top(h, 0.12)
			if t.is_empty():
				return out
			var n: Vector3 = t["n"]
			var a: Vector3 = n.cross(Vector3(1, 0, 0))
			if a.length() < 0.2:
				a = n.cross(Vector3(0, 0, 1))
			a = a.normalized()
			var b: Vector3 = n.cross(a).normalized()
			var r: float = h.L * float(m["ring"])
			var c := 1 if still else int(m["count"])
			for j in c:
				var ang := TAU * float(j) / float(c)
				out.append({"p": (t["p"] as Vector3) + (a * cos(ang) + b * sin(ang)) * (r if c > 1 else 0.0), "n": n})
		"corona":
			var t := _top(h, 0.0)
			if not t.is_empty():
				out.append(t)
			var more := _breach_spots(h, int(m["count"]) - 1)
			out.append_array(more)
		_:
			out = _breach_spots(h, int(m["count"]))
	return out


# Every scheduled pulse spot of a ship, as rows {p, n, t (start offset, 0 to period), life, period, i, s0, s1, col, kind,
# style, layers, still}: the table and the comfort check both read these. `seed_v` is the ship's own hash (its phase,
# so a fleet does not pulse together); `softened` is Reduce flashing, `still` is Reduce motion.
static func rows(h, faction: String, fac: Dictionary, seed_v: int, softened: bool, still: bool) -> Array:
	var m := motion_of(faction)
	if m.is_empty() or h == null:
		return []
	var sp := spots(h, m, still)
	var out: Array = []
	var life: float = float(m["life"]) * (SOFT_LIFE if softened else 1.0)
	var period: float = float(m["period"]) * (SOFT_PERIOD if softened else 1.0)
	var bright: float = minf(float(m["i"]) * (SOFT_I if softened else 1.0), MAX_I)
	var col: Color = fac["weapon"] if faction == "hegemony" else fac["damage_glow"]
	var style_id: int = int(STYLE_ID.get(faction, 0))
	var per := int(m["per"])
	var phase0 := float(posmod(seed_v, 997)) / 997.0 * period
	var n := mini(sp.size() * per, MAX_SPRITES)
	var j := 0
	for si in sp.size():
		for q in per:
			if j >= n:
				break
			var off: float
			var l := life
			if bool(m["scatter"]):
				# an uneven flicker: each spot's sprites at hashed offsets, each its own length from 0.7 to 1.0 of the life
				var hs := float(posmod(hash("%d|%d|%d" % [seed_v, si, q]), 1000)) / 1000.0
				off = fmod(phase0 + (float(q) + hs * 0.8) * period / float(per) + float(si) * period * 0.37, period)
				l = life * (0.7 + 0.3 * float(posmod(hash("l%d|%d|%d" % [seed_v, si, q]), 1000)) / 1000.0)
			else:
				off = fmod(phase0 + float(j) * period / float(maxi(n, 1)), period)
			var tint := col
			if faction == "ithar":
				# a faint rainbow on the glints (the Glasswrights' rainbow edge), kept pale
				tint = col.lerp(Color.from_hsv(fmod(0.52 + 0.13 * float(si), 1.0), 0.45, 1.0), 0.5)
			var s0: float = h.L * float((m["size"] as Vector2).x)
			var s1: float = h.L * float((m["size"] as Vector2).y)
			var normal: Vector3 = (sp[si]["n"] as Vector3).normalized()
			# set a little off the plating along its normal, so the glow is not cut by the hull it sits on
			var pos: Vector3 = (sp[si]["p"] as Vector3) + normal * s1 * 0.2
			out.append({"p": pos, "n": normal, "t": off, "life": minf(l, period * 0.95), "period": period, "i": bright,
				"s0": s0, "s1": s1, "col": tint, "kind": KIND, "style": style_id, "layers": LAYERS_PER_SPOT, "still": still})
			j += 1
	return out


# What the comfort check measures from rows: the most pulses one ship starts inside any one-second window, the brightest and the shortest.
# Issue 2025 (Artoo 7125579753): this is the worst case of simultaneous starts, not the average rate (the sum of 1 / period),
# which hides sprites that start together. A window is worst when it opens on a start, so each start is tried as the opening.
# Every row of a ship shares one period, so a horizon of the longest period sees the whole pattern; rows with different periods
# are scanned for WORST_WINDOW_HORIZON seconds.
const WORST_WINDOW_HORIZON := 120.0
const WINDOW_EPS := 1e-9

static func _starts_in_window(r: Array, open: float) -> int:
	# starts t + k * period, for every whole k, that fall in [open, open + 1)
	var n := 0
	for row in r:
		var period := float(row["period"])
		var t := float(row["t"])
		n += int(ceil((open + 1.0 - t) / period - WINDOW_EPS)) - int(ceil((open - t) / period - WINDOW_EPS))
	return n


static func worst_starts_per_s(r: Array) -> int:
	var longest := 0.0
	for row in r:
		longest = maxf(longest, float(row["period"]))
	if longest <= 0.0:
		return 0
	var horizon := longest if _same_period(r) else WORST_WINDOW_HORIZON
	var worst := 0
	for row in r:
		var period := float(row["period"])
		var k := 0
		while float(row["t"]) + float(k) * period < horizon:
			worst = maxi(worst, _starts_in_window(r, float(row["t"]) + float(k) * period))
			k += 1
	return worst


static func _same_period(r: Array) -> bool:
	for row in r:
		if not is_equal_approx(float(row["period"]), float(r[0]["period"])):
			return false
	return true


static func stats(r: Array) -> Dictionary:
	var max_i := 0.0
	var min_life := INF
	for row in r:
		max_i = maxf(max_i, float(row["i"]))
		min_life = minf(min_life, float(row["life"]))
	return {"sprites": r.size(), "starts_per_s": float(worst_starts_per_s(r)), "max_i": max_i, "min_life": min_life}


# Build the ship's layered batch under `parent` (its damage root). Returns {} (nothing built) when the ship has no motion;
# else {node, mat, rows, motion, layers, particles}. `fx` supplies the shared IDLE_MOTION material and the clock.
static func build(fx, parent: Node3D, h, faction: String, fac: Dictionary, seed_v: int, softened: bool, still: bool) -> Dictionary:
	var r := rows(h, faction, fac, seed_v, softened, still)
	if r.is_empty():
		return {}
	var b := POOLS.Batch.new()
	var total := maxf(float(r.size()), 1.0)
	var j := 0
	for row in r:
		var p: Vector3 = row["p"]
		var n: Vector3 = row["n"]
		var c: Color = row["col"]
		var life := float(row["life"])
		var period := float(row["period"])
		var t: float = fx.now - period + float(row["t"])
		var style_f := float(row["style"])
		var still_f := 1.0 if bool(row["still"]) else 0.0
		var slot_f := float(j) / total
		var s0 := float(row["s0"])
		var s1 := float(row["s1"])
		var bright := float(row["i"])
		# Layer 0: emitter anchor / core piece.
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, t),
			Vector4(n.x, n.y, n.z, life), Vector4(c.r, c.g, c.b, bright),
			Vector4(s0, s1, 0.0, fmod(float(j) * 0.137, 0.99)),
			Vector4(period, style_f, still_f, slot_f)))
		# Layer 1: animated faction motion piece, synchronized to the same pulse window (zero extra flash starts).
		b.add(POOLS.quad_shape(), POOLS.pack(Vector4(p.x, p.y, p.z, t),
			Vector4(n.x, n.y, n.z, life), Vector4(c.r, c.g, c.b, bright * 0.62),
			Vector4(s0 * 1.35, s1 * 1.55, 1.0, fmod(float(j) * 0.137 + 0.5, 0.99)),
			Vector4(period, style_f, still_f, slot_f)))
		j += 1
	var holder := Node3D.new()
	holder.name = "fx_idle"
	parent.add_child(holder)
	var material: ShaderMaterial = fx.mat(SH.IDLE_MOTION, 1)
	b.build(material, holder, "fx_idle_sprites")
	return {"node": holder, "mat": material, "rows": r, "motion": String(motion_of(faction)["name"]),
		"layers": LAYERS_PER_SPOT, "particles": b.particle_count}
