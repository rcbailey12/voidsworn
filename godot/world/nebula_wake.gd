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
const RISE_S := 0.6         # and the disturbance eases in over this long behind the hull (Ryan, Nov 20: it was sudden)
const R_PER_L := 0.9        # disturbance radius per unit of hull length
const R_MIN := 9.0          # a frigate (hull 10.4 long) is about 9.4
const R_MAX := 26.0         # a capital (hull 30 to 43 long)
const PUSH := 1.35          # push at full strength, world units, times sqrt(radius x PUSH_REF): a frigate about 12.6
const PUSH_REF := 9.36      # (a capital about 21, so it stirs more than a frigate but not three times as much)
const PAUSE_S := 0.1        # a ship still for longer than this starts a new trail when it moves again
const NEAR := 3.0           # a point takes its ship's trail at the nearest place on it, blended over about this many units

var points := HIGH_POINTS
# Each slot: a, b (ends, world), ta, tb (clock when the ship was at each end), r, m (push, sign = swirl side), ship (the
# ship that left it), owner (ship key while it is that ship's growing newest segment, else -1).
var _ring: Array = []
var _head := {}             # ship key -> slot index of its newest segment
var clock := 0.0
var held := false           # benches only (hold_full): every segment stays at full strength
var _laid := 0              # benches only: trails laid by lay_trail, each its own ship


func _init(quality: String) -> void:
	points = LOW_POINTS if quality == "low" else HIGH_POINTS
	for i in points:
		_ring.append(_empty())


func _empty() -> Dictionary:
	return {"a": Vector3.ZERO, "b": Vector3.ZERO, "ta": -100.0, "tb": -100.0, "r": 0.0, "m": 0.0, "ship": -1, "owner": -1}


# The GLSL both gas shaders share. wake_at(w) returns xyz: how far the gas at w is pushed (world units),
# w: how much it is thinned (0 to 1).
static func glsl(n: int) -> String:
	return """
// 12 floats a segment: end a xyz, end b xyz, radius, ship group, (spare), age at a, age at b (seconds), push (its sign
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
		float s = smoothstep(0.0, %.3f, age) * (1.0 - smoothstep(0.0, %.3f, age));
		float d2 = dot(d.xz, d.xz) + d.y * d.y / 2.25;
		// Round across the path, taller than the hull: the gas layers sit from below the board to well above it.
		float f = exp(-d2 / (r * r)) * s;
		float m = wake_d[k + 11];
		vec2 out_dir = d.xz / (length(d.xz) + 0.75);
		vec2 side = vec2(-out_dir.y, out_dir.x) * sign(m);
		vec2 along = e.xz / max(length(e.xz), 0.0001);
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
""" % [n * FLOATS, n, FADE_S, RISE_S, FADE_S, NEAR * NEAR, NEAR * NEAR, FADE_S * 0.4, FADE_S]


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


# Called every frame with the battle's ship views; stretches each moving ship's newest segment to it.
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
		var length := float(sv.get("L")) if sv.get("L") != null else 10.0
		var r := clampf(length * R_PER_L, R_MIN, R_MAX)
		var h: int = _head.get(key, -1)
		if h < 0 or int(_ring[h].owner) != key:
			_head[key] = _start(key, at, r, -1.0)
			continue
		var e: Dictionary = _ring[h]
		var step := Vector2(at.x - e.b.x, at.z - e.b.z)
		if step.length() > 40.0:   # a snap or a revive, not a move
			_close(key)
			_head[key] = _start(key, at, r, -1.0)
			continue
		if step.length() < 0.01:   # still: the trail behind it fades on its own
			continue
		if clock - float(e.tb) > PAUSE_S:
			# Moving again after a stop: a fresh trail from here, starting at zero strength.
			_close(key)
			h = _start(key, e.b, r, clock - dt)
			_head[key] = h
			e = _ring[h]
		e.b = at
		e.tb = clock
		var run := Vector2(e.b.x - e.a.x, e.b.z - e.a.z)
		if run.length() >= SEG:
			_close(key)
			_head[key] = _start(key, at, r, clock)
	for key in _head.keys():
		if not seen.has(key):
			_close(key)


# A new newest segment for a ship, starting (and for now ending) at `at`. t < 0: not yet moving.
func _start(key: int, at: Vector3, r: float, t: float) -> int:
	var i := _free_slot()
	var side := 1.0 if key % 2 == 0 else -1.0   # one swirl side per ship
	_ring[i] = {"a": at, "b": at, "ta": t if t >= 0.0 else clock, "tb": t if t >= 0.0 else -100.0, "r": r,
		"m": side * push(r), "ship": key, "owner": key}
	return i


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
		_head.erase(was)
	return best


static func push(r: float) -> float:
	return PUSH * sqrt(r * PUSH_REF)


# Benches only: forget every segment and every ship's trail (after a bench moves ships into place).
func forget() -> void:
	held = false
	_head.clear()
	for i in points:
		_ring[i] = _empty()


# Benches only: the worst case, every segment live at full strength at these places, for as long as the bench runs.
func hold_full(at: Array, r := R_MAX, dir := Vector2(1.0, 0.0)) -> void:
	forget()
	held = true
	for i in points:
		var p: Vector3 = at[i % at.size()]
		_ring[i] = {"a": p, "b": p + Vector3(dir.x, 0.0, dir.y) * SEG, "ta": clock, "tb": clock, "r": r,
			"m": push(r) * (1.0 if i % 2 == 0 else -1.0), "ship": i, "owner": -1}


# Benches only: lay a finished trail behind a ship at `at`, heading `dir`, the newest end `age_b` seconds old and each
# segment further back `per_seg` seconds older.
func lay_trail(at: Vector3, dir: Vector2, r: float, count: int, age_b: float, per_seg: float, side := 1.0) -> void:
	var trail_id := -2 - _laid
	_laid += 1
	var back := Vector3(-dir.x, 0.0, -dir.y)
	for k in count:
		var i := _free_slot()
		_ring[i] = {"a": at + back * SEG * float(k + 1), "b": at + back * SEG * float(k), "ta": clock - age_b - per_seg * float(k + 1),
			"tb": clock - age_b - per_seg * float(k), "r": r, "m": side * push(r), "ship": trail_id, "owner": -1}


func uniforms() -> PackedFloat32Array:
	# Sorted by ship, so the shader can take each ship's trail as one line; a ship's group is its place in this order.
	var order := range(points)
	order.sort_custom(func(x, y): return int(_ring[x].ship) < int(_ring[y].ship))
	var groups := {}
	var out := PackedFloat32Array()
	for i in order:
		var e: Dictionary = _ring[i]
		var a: Vector3 = e.a
		var bb: Vector3 = e.b
		var age_a := clock - float(e.ta)
		var age_b := clock - float(e.tb)
		if held:
			age_a = RISE_S * 2.0
			age_b = RISE_S * 2.0
		elif a.distance_to(bb) < 0.01:
			age_a = FADE_S + 1.0   # a ship's segment that has not grown yet adds nothing
			age_b = FADE_S + 1.0
		if not groups.has(e.ship):
			groups[e.ship] = float(groups.size())
		out.append_array([a.x, a.y, a.z, bb.x, bb.y, bb.z, maxf(float(e.r), 0.001), groups[e.ship], 0.0, age_a, age_b, float(e.m)])
	return out


func apply(mats: Array) -> void:
	var u := uniforms()
	for m in mats:
		(m as ShaderMaterial).set_shader_parameter("wake_d", u)
