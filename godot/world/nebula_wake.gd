extends RefCounted
# Issue 1079 prototype: ships disturb the calm nebula as they pass. Visual only, nothing here reads or changes a rule.
# Bounded: a fixed set of short line segments along each ship's recent path goes to the gas shaders as uniforms. There
# is no fluid simulation. The newest segment of each ship stretches with it every frame and the age runs smoothly along
# the trail, so the wake is one continuous strip with no steps (Ryan, Nov 19: the point version showed stages).
# Off by default (settings key nebula_wake, battle flag --nebula-wake). Off, the shaders are byte for byte today's.
# Shared: every ShipView the battle shows feeds it (every faction and class, squadrons included), sized by hull length.

const HIGH_POINTS := 12     # trail segments at Max and High
const LOW_POINTS := 6       # Low quality: fewer segments, cards only (Low has no fog volume)
const FLOATS := 12          # floats per segment in the uniform
const SEG := 12.0           # a ship's newest segment is closed off at this length and a new one starts at its end
const FADE_S := 3.0         # the gas is calm again this long after the ship left it
const RAMP := 8.0           # a trail eases in over its first this-many units of travel, so a ship starting off never pops
const BOW := 0.4            # the trail runs to the bow: this many hull lengths ahead of the ship's centre
const BOW_MIN := 0.35       # at the bow the gas is already stirred this much, building to full by about mid-hull
const CAP := 0.35           # ahead of the bow the stir reaches this fraction of the radius (a short bow wave, not a cloud)
# Ryan, Nov 20 (run 8): the trail seemed to come from the middle or back of the ship and to catch up after it stopped. It
# used to ease in with age, so it was weak at the hull and grew behind it. Now it is at full strength at the bow the
# moment the ship is there, eases in only over a trail's first RAMP units, and only fades with age.
const R_PER_L := 0.9        # disturbance radius per unit of hull length
const R_MIN := 9.0          # a frigate (hull 10.4 long) is about 9.4
const R_MAX := 26.0         # a capital (hull 30 to 43 long)
const PUSH := 1.35          # push at full strength, world units, times sqrt(radius x PUSH_REF): a frigate about 12.6
const PUSH_REF := 9.36      # (a capital about 21, so it stirs more than a frigate but not three times as much)
const PAUSE_S := 0.1        # a ship still for longer than this starts a new trail when it moves again
const NEAR := 3.0           # a point takes its ship's trail at the nearest place on it, blended over about this many units

var points := HIGH_POINTS
# Each slot: a, b (ends, world), ta, tb (clock when the bow was at each end), r, m (push, sign = swirl side), from (how far
# along its trail end a is), trail (which trail of its ship), ramp (its trail's ease-in when it was closed), ship (the
# ship that left it), owner (ship key while it is that ship's growing newest segment, else -1).
var _ring: Array = []
var _head := {}             # ship key -> slot index of its newest segment (moving ships only)
var _last := {}             # ship key -> {p: its centre last frame, t: clock when it last moved, dir: heading on the board}
var _trails := {}           # ship key -> number of its current trail
var clock := 0.0
var held := false           # benches only (hold_full): every segment stays at full strength
var _laid := 0              # benches only: trails laid by lay_trail, each its own ship


func _init(quality: String) -> void:
	points = LOW_POINTS if quality == "low" else HIGH_POINTS
	for i in points:
		_ring.append(_empty())


func _empty() -> Dictionary:
	return {"a": Vector3.ZERO, "b": Vector3.ZERO, "ta": -100.0, "tb": -100.0, "r": 0.0, "m": 0.0, "from": 0.0, "trail": -1, "ramp": 1.0, "tipend": 1000.0, "ship": -1, "owner": -1}


# The GLSL both gas shaders share. wake_at(w) returns xyz: how far the gas at w is pushed (world units),
# w: how much it is thinned (0 to 1).
static func glsl(n: int) -> String:
	return """
// 12 floats a segment: end a xyz, end b xyz, radius, ship group, distance behind the bow at a, age at a, age at b, push (its sign
// is the swirl side). Segments come sorted by ship. Plain floats: a Color array would be read as sRGB and converted.
uniform float wake_d[%d];
vec4 wake_at(vec3 w) {
	// Ryan, Nov 20 ("sudden and jerky"): each ship's trail acts as one smooth line. A point takes that ship's trail at the
	// nearest place on it (blended over a few units, so there is no seam), never at the rounded end of an older segment
	// beside it; different ships' trails add up. Strength eases in and out with age.
	vec2 tot = vec2(0.0);
	float tthin = 0.0;
	float g = -1.0;
	vec2 acc = vec2(0.0);
	float thin = 0.0;
	float ws = 0.0;
	float dmin = 0.0;
	for (int i = 0; i < %d; i++) {
		int k = i * 12;
		float age_a = wake_d[k + 9];
		float age_b = wake_d[k + 10];
		if (min(age_a, age_b) >= %.3f) { continue; }
		vec3 a = vec3(wake_d[k], wake_d[k + 1], wake_d[k + 2]);
		vec3 e = vec3(wake_d[k + 3], wake_d[k + 4], wake_d[k + 5]) - a;
		float t = clamp(dot(w - a, e) / max(dot(e, e), 0.0001), 0.0, 1.0);
		vec3 d = w - (a + e * t);
		float r = wake_d[k + 6];
		float age = mix(age_a, age_b, t);
		// Already stirred at the bow, full by about mid-hull, then fading with age.
		float behind = wake_d[k + 8] - t * length(e.xz);
		float s = mix(%.3f, 1.0, smoothstep(0.0, 0.6 * r, behind)) * (1.0 - smoothstep(0.0, %.3f, age));
		vec2 along = e.xz / max(length(e.xz), 0.0001);
		// Past either end of the line (ahead of the bow, behind the trail's start) the stir reaches only a short way.
		float da = dot(d.xz, along);
		float d2 = dot(d.xz, d.xz) - da * da + da * da / (%.3f * %.3f) + d.y * d.y / 2.25;
		// Beyond 3 radii a piece's pull is under 1 in 10,000 and it can never be the nearest that matters: skip its maths.
		if (d2 > 9.0 * r * r) { continue; }
		// Round across the path, taller than the hull: the gas layers sit from below the board to well above it.
		float f = exp(-d2 / (r * r)) * s;
		float m = wake_d[k + 11];
		vec2 out_dir = d.xz / (length(d.xz) + 0.75);
		vec2 side = vec2(-out_dir.y, out_dir.x) * sign(m);
		vec2 v = (out_dir * 0.55 + side * 0.3 + along * 0.35) * f * abs(m);
		float gi = wake_d[k + 7];
		if (gi != g) {
			if (ws > 0.0) { tot += acc / ws; tthin = max(tthin, thin / ws); }
			g = gi; acc = vec2(0.0); thin = 0.0; ws = 0.0; dmin = d2;
		}
		if (d2 < dmin) {
			float sc = exp((d2 - dmin) / (2.0 * %.3f));
			acc *= sc; thin *= sc; ws *= sc; dmin = d2;
		}
		// A faded old stretch gives way smoothly to a newer trail of another ship close by.
		float wt = exp((dmin - d2) / (2.0 * %.3f)) * (1.0 - smoothstep(%.3f, %.3f, age)) + 1e-20;
		acc += v * wt;
		thin += f * wt;
		ws += wt;
	}
	if (ws > 0.0) { tot += acc / ws; tthin = max(tthin, thin / ws); }
	return vec4(tot.x, 0.0, tot.y, tthin);
}
""" % [n * FLOATS, n, FADE_S, BOW_MIN, FADE_S, CAP, CAP, NEAR * NEAR, NEAR * NEAR, FADE_S * 0.4, FADE_S]


const SHIFT := "// WAKE_SHIFT"
const THIN := "// WAKE_THIN"


# Adds the wake at the marker comments world_living.gd keeps in its calm gas shaders (Board, PR 1181: markers, not
# copied code lines, so a shader rewrite cannot silently drop it). A missing marker is an error and the shader stays
# as it was; world/test/nebula_wake_check.gd fails on it.
static func _inject(code: String, n: int, entry: String, at: String, thin: String) -> String:
	if code.count(SHIFT) != 1 or code.count(THIN) != 1 or code.count(entry) != 1:
		push_error("Issue 1079: the nebula wake markers are missing from a calm gas shader; wake not applied")
		return code
	code = code.replace(entry, glsl(n) + entry)
	var lines := code.split("\n")
	for i in lines.size():
		if lines[i].strip_edges().begins_with(SHIFT):
			lines[i] = "\tvec4 wk = wake_at(%s);\n\tp -= wk.xyz * %s;" % Array(at.split("|"))
		elif lines[i].strip_edges().begins_with(THIN):
			lines[i] = thin
	return "\n".join(lines)


static func into_cards(code: String, n: int) -> String:
	return _inject(code, n, "void fragment() {", "vW|0.075", "\td *= 1.0 - 0.7 * wk.w;")


static func into_fog(code: String, n: int) -> String:
	return _inject(code, n, "void fog() {", "WORLD_POSITION|0.012", "\tDENSITY *= 1.0 - 0.7 * wk.w;")


# Called every frame with the battle's ship views; stretches each moving ship's newest segment to its bow. A ship only
# takes a trail slot once it moves (Artoo on PR 1181: a parked fleet used to fill every slot, so a moving ship got no
# trail); where every ship was is kept apart from the slots.
func update(dt: float, ships: Array) -> void:
	clock += dt
	var seen := {}
	for sv in ships:
		if not is_instance_valid(sv) or not (sv is Node3D) or not (sv as Node3D).is_visible_in_tree():
			continue
		if bool(sv.get("dead")):
			continue
		var at: Vector3 = sv.visual_position() if sv.has_method("visual_position") else (sv as Node3D).position
		var key: int = sv.get_instance_id()
		seen[key] = true
		if not _last.has(key):
			_last[key] = {"p": at, "t": -100.0, "dir": Vector2.ZERO}
			continue
		var last: Dictionary = _last[key]
		var was: Vector3 = last.p
		var step := Vector2(at.x - was.x, at.z - was.z)
		if step.length() > 40.0:   # a snap or a revive, not a move
			_freeze(key)
			_close(key)
			_last[key] = {"p": at, "t": -100.0, "dir": Vector2.ZERO}
			continue
		if step.length() < 0.01:   # still: the trail behind it fades on its own
			# Stopped for good: give the newest piece back, so ships that moved once and parked never hold every
			# slot (Fable on PR 1181: a later mover's trail was then cut to one 12 unit piece at every seam).
			if _head.has(key) and clock - float(last.t) > PAUSE_S:
				_freeze(key)
				_close(key)
			continue
		var length := float(sv.get("L")) if sv.get("L") != null else 10.0
		var r := clampf(length * R_PER_L, R_MIN, R_MAX)
		var dir := step.normalized()
		var reach := Vector3(dir.x, 0.0, dir.y) * length * BOW
		var bow := at + reach
		var h: int = _head.get(key, -1)
		# The pause counts only frames the ship stood still, so one long frame (a hitch) never restarts a moving
		# ship's trail (Fable on PR 1181).
		if h < 0 or int(_ring[h].owner) != key or clock - dt - float(last.t) > PAUSE_S:
			# Starting to move, or moving again after a stop: a fresh trail from where the bow was, easing in.
			_freeze(key)   # before _close, which forgets the head the freeze reads (Artoo on PR 1181)
			_close(key)
			_trails[key] = int(_trails.get(key, 0)) + 1
			h = _start(key, was + reach, r, clock - dt, 0.0)
			_head[key] = h
		var e: Dictionary = _ring[h]
		e.b = bow
		e.tb = clock
		_last[key] = {"p": at, "t": clock, "dir": dir}
		var run := Vector2(e.b.x - e.a.x, e.b.z - e.a.z)
		if run.length() >= SEG:
			_close(key)
			_head[key] = _start(key, bow, r, clock, float(e.from) + run.length())
	for key in _last.keys():
		if not seen.has(key):
			_freeze(key)
			_close(key)
			_last.erase(key)
			_trails.erase(key)


# A new newest segment for a ship, starting (and for now ending) at `at`, the bow there at time t, `from` units along
# its trail.
func _start(key: int, at: Vector3, r: float, t: float, from: float) -> int:
	var i := _free_slot()
	var side := 1.0 if key % 2 == 0 else -1.0   # one swirl side per ship
	_ring[i] = {"a": at, "b": at, "ta": t, "tb": t, "r": r, "m": side * push(r), "from": from, "trail": int(_trails.get(key, 0)),
		"ramp": 1.0, "tipend": 1000.0, "ship": key, "owner": key}
	return i


# A ship's current trail is finished (it stopped and moves off again, snapped, or left the board): every piece keeps the
# bow distance and ease-in it had at that moment, so nothing on it changes when the ship starts a new one.
func _freeze(key: int) -> void:
	var h: int = _head.get(key, -1)
	if h < 0 or int(_ring[h].owner) != key:
		return
	var hd: Dictionary = _ring[h]
	var tip := float(hd.from) + Vector2(hd.b.x - hd.a.x, hd.b.z - hd.a.z).length()
	for e in _ring:
		if int(e.ship) == key and int(e.trail) == int(hd.trail):
			e.tipend = tip
			e.ramp = _ramp(tip)


# A trail eases in over its first RAMP units of travel, all of it together, so a ship starting off never pops.
static func _ramp(length: float) -> float:
	return smoothstep(0.0, RAMP, length)


func _close(key: int) -> void:
	var h: int = _head.get(key, -1)
	if h >= 0 and int(_ring[h].owner) == key:
		_ring[h].owner = -1
	_head.erase(key)


# The slot whose newer end is oldest (the most faded), never a ship's growing segment unless every slot is one.
func _free_slot() -> int:
	var best := -1
	for pass_i in 2:
		for i in points:
			if pass_i == 0 and int(_ring[i].owner) >= 0:
				continue
			if best < 0 or float(_ring[i].tb) < float(_ring[best].tb):
				best = i
		if best >= 0:
			break
	var was := int(_ring[best].owner)
	if was >= 0:
		_freeze(was)   # the trail it cuts keeps its values (Fable on PR 1181)
		_head.erase(was)
	return best


static func push(r: float) -> float:
	return PUSH * sqrt(r * PUSH_REF)


# Benches only: forget every segment and every ship's trail (after a bench moves ships into place).
func forget() -> void:
	held = false
	_head.clear()
	_last.clear()
	_trails.clear()
	for i in points:
		_ring[i] = _empty()


# Benches only: the worst case, every segment live at full strength at these places, for as long as the bench runs.
func hold_full(at: Array, r := R_MAX, dir := Vector2(1.0, 0.0)) -> void:
	forget()
	held = true
	for i in points:
		var p: Vector3 = at[i % at.size()]
		_ring[i] = {"a": p, "b": p + Vector3(dir.x, 0.0, dir.y) * SEG, "ta": clock, "tb": clock, "r": r,
			"m": push(r) * (1.0 if i % 2 == 0 else -1.0), "from": 0.0, "trail": -1, "ramp": 1.0, "tipend": 1000.0, "ship": i, "owner": -1}


# Benches only: lay a finished trail behind a ship at `at`, heading `dir`, the newest end `age_b` seconds old and each
# segment further back `per_seg` seconds older.
func lay_trail(at: Vector3, dir: Vector2, r: float, count: int, age_b: float, per_seg: float, side := 1.0) -> void:
	var trail_id := -2 - _laid
	_laid += 1
	var back := Vector3(-dir.x, 0.0, -dir.y)
	for k in count:
		var i := _free_slot()
		_ring[i] = {"a": at + back * SEG * float(k + 1), "b": at + back * SEG * float(k), "ta": clock - age_b - per_seg * float(k + 1),
			"tb": clock - age_b - per_seg * float(k), "r": r, "m": side * push(r), "from": -SEG * float(k + 1), "trail": -1, "ramp": 1.0, "tipend": 0.0, "ship": trail_id, "owner": -1}


func uniforms() -> PackedFloat32Array:
	# Sorted by ship, so the shader can take each ship's trail as one line; a ship's group is its place in this order.
	var order := range(points)
	order.sort_custom(func(x, y): return int(_ring[x].ship) < int(_ring[y].ship))
	# Each moving ship's current trail: how long it is to the bow, so every piece knows how far behind the bow it is.
	var tip := {}
	for key in _head:
		var hd: Dictionary = _ring[_head[key]]
		tip[key] = [int(hd.trail), float(hd.from) + Vector2(hd.b.x - hd.a.x, hd.b.z - hd.a.z).length()]
	var groups := {}
	var out := PackedFloat32Array()
	for i in order:
		var e: Dictionary = _ring[i]
		var a: Vector3 = e.a
		var bb: Vector3 = e.b
		var age_a := clock - float(e.ta)
		var age_b := clock - float(e.tb)
		if held:
			age_a = 0.5
			age_b = 0.5
		elif a.distance_to(bb) < 0.01:
			age_a = FADE_S + 1.0   # a ship's segment that has not grown yet adds nothing
			age_b = FADE_S + 1.0
		var behind := float(e.tipend) - float(e.from)   # a finished trail keeps what it had when it was finished
		var ramp := float(e.ramp)
		if tip.has(e.ship) and int(tip[e.ship][0]) == int(e.trail):
			behind = float(tip[e.ship][1]) - float(e.from)
			ramp = _ramp(float(tip[e.ship][1]))
		if not groups.has(e.ship):
			groups[e.ship] = float(groups.size())
		out.append_array([a.x, a.y, a.z, bb.x, bb.y, bb.z, maxf(float(e.r), 0.001), groups[e.ship], behind, age_a, age_b, float(e.m) * ramp])
	return out


func apply(mats: Array) -> void:
	var u := uniforms()
	for m in mats:
		(m as ShaderMaterial).set_shader_parameter("wake_d", u)
