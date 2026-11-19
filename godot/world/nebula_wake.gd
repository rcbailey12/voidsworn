extends RefCounted
# Issue 1079 prototype: ships disturb the calm nebula as they pass. Visual only, nothing here reads or changes a rule.
# Bounded: a fixed ring of recent ship positions goes to the gas shaders as uniforms. There is no fluid simulation;
# each point pushes and thins the gas round it, then fades out within FADE_S seconds.
# Off by default (settings key nebula_wake, battle flag --nebula-wake). Off, the shaders are byte for byte today's.
# Shared: every ShipView the battle shows feeds it (every faction and class, squadrons included), sized by hull length.

const HIGH_POINTS := 8      # Max and High quality
const LOW_POINTS := 4       # Low quality: fewer points, cards only (Low has no fog volume)
const DROP_EVERY := 0.8     # travel between dropped points, in disturbance radii (a hex is 17.3 units across)
const FADE_S := 3.0         # a point is gone this long after the ship left it
const RISE_S := 0.25        # and comes in over this long, so a new point never pops
const R_PER_L := 0.9        # disturbance radius per unit of hull length
const R_MIN := 9.0          # a frigate (hull 10.4 long) is about 9.4
const R_MAX := 26.0         # a capital (hull 30 to 43 long)

var points := 8
var _ring: Array = []       # {p: Vector3, r: float, dir: Vector2, born: float, spin: float}
var _next := 0
var _last := {}             # ShipView instance id -> last dropped position
var clock := 0.0
var held := false           # benches only (hold_full): every point stays at full strength


func _init(quality: String) -> void:
	points = LOW_POINTS if quality == "low" else HIGH_POINTS
	for i in points:
		_ring.append({"p": Vector3.ZERO, "r": 0.0, "dir": Vector2.ZERO, "born": -100.0, "spin": 1.0})


# The GLSL both gas shaders share. wake_at(w) returns xyz: how far the gas at w is pushed (world units),
# w: how much it is thinned (0 to 1).
static func glsl(n: int) -> String:
	return """
// 8 floats a point: centre xyz, radius, travel direction (board xz), strength 0..1, swirl side.
// Plain floats: a Color array would be read as sRGB and converted.
uniform float wake_d[%d];
vec4 wake_at(vec3 w) {
	vec4 o = vec4(0.0);
	for (int i = 0; i < %d; i++) {
		int k = i * 8;
		float s = wake_d[k + 6];
		if (s <= 0.0) { continue; }
		vec3 d = w - vec3(wake_d[k], wake_d[k + 1], wake_d[k + 2]);
		float r = wake_d[k + 3];
		// Round in plan, taller than the hull: the gas layers sit from below the board to well above it.
		float f = exp(-dot(d.xz, d.xz) / (r * r) - d.y * d.y / (r * r * 2.25)) * s;
		vec2 out_dir = d.xz / (length(d.xz) + 0.75);
		vec2 side = vec2(-out_dir.y, out_dir.x) * wake_d[k + 7];
		// Pushed aside and curled, and dragged a little along the ship's path.
		o.xz += (out_dir * 0.55 + side * 0.45 + vec2(wake_d[k + 4], wake_d[k + 5]) * 0.35) * f * r * 0.9;
		o.w = max(o.w, f);
	}
	return o;
}
""" % [n * 8, n]


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


# Called every frame with the battle's ship views; drops points behind any ship that is moving.
func update(dt: float, ships: Array) -> void:
	clock += dt
	for sv in ships:
		if not is_instance_valid(sv) or not (sv is Node3D) or not (sv as Node3D).is_visible_in_tree():
			continue
		if bool(sv.get("dead")):
			continue
		var at: Vector3 = sv.visual_position() if sv.has_method("visual_position") else (sv as Node3D).position
		var key: int = sv.get_instance_id()
		if not _last.has(key):
			_last[key] = at
			continue
		var was: Vector3 = _last[key]
		var step := Vector2(at.x - was.x, at.z - was.z)
		if step.length() > 40.0:   # a snap or a revive, not a move
			_last[key] = at
			continue
		var length := float(sv.get("L")) if sv.get("L") != null else 10.0
		var r := clampf(length * R_PER_L, R_MIN, R_MAX)
		if step.length() < DROP_EVERY * r:
			continue
		_drop(at, r, step.normalized())
		_last[key] = at


func _drop(at: Vector3, r: float, dir: Vector2) -> void:
	var spin := 1.0 if (_next % 2) == 0 else -1.0
	_ring[_next] = {"p": at, "r": r, "dir": dir, "born": clock, "spin": spin}
	_next = (_next + 1) % points


# Benches only: forget every point and every ship's last place (after a bench moves ships into place).
func forget() -> void:
	held = false
	_last.clear()
	for e in _ring: e.born = -100.0


# Benches only: the worst case, every point live at full strength at these places, for as long as the bench runs.
func hold_full(at: Array, r := R_MAX, dir := Vector2(1.0, 0.0)) -> void:
	held = true
	for i in points:
		var p: Vector3 = at[i % at.size()]
		_ring[i] = {"p": p, "r": r, "dir": dir, "born": clock, "spin": 1.0 if i % 2 == 0 else -1.0}


func strength(age: float) -> float:
	if held:
		return 1.0
	if age < 0.0 or age >= FADE_S:
		return 0.0
	var rise := clampf(age / RISE_S, 0.0, 1.0)
	var fall := 1.0 - age / FADE_S
	return rise * fall * fall


func uniforms() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for e in _ring:
		var p: Vector3 = e.p
		var dir: Vector2 = e.dir
		out.append_array([p.x, p.y, p.z, maxf(float(e.r), 0.001), dir.x, dir.y, strength(clock - float(e.born)), float(e.spin)])
	return out


func apply(mats: Array) -> void:
	var u := uniforms()
	for m in mats:
		(m as ShaderMaterial).set_shader_parameter("wake_d", u)
