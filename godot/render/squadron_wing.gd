extends Node3D
# Local flight stays around the wing's anchor. Only ShipView moves the rules unit.
# Each ribbon samples its own craft's stern in world space, including turns.
const CRAFT := preload("res://render/squadron_craft.gd")
const LOOK := preload("res://fx/faction_look.gd")
# Local flight amplitudes, in craft lengths and radians. Formation clearance
# includes the whole weave, bank and (for spores) breathing cycle.
const WEAVE := Vector3(0.12, 0.09, 0.14)
const SPORE_SWAY := 0.24
const BANK := Vector3(0.22, 0.12, 0.065)
const SPORE_BANK := 0.29
const BREATH := 0.025
const CLEARANCE := 0.04 # visible air between swept hull bounds, in craft lengths
var craft: Array = []
var trails: Array = []
var rests: Array = []
var clock := 0.0
var phase := 0.0
var length := 3.84
var faction := "hegemony"
var active := true
var sample_t := 0.0
var trail_mat: ShaderMaterial
# issue 221: the ribbon's ageing (drift back along the craft's wake, widening, fading) runs in the vertex shader from
# each sample's birth time (UV2.x) and the wing's clock, so the mesh is rebuilt only when a sample is added or dropped,
# not every frame. Same maths as the old per-frame GDScript build.
const TRAIL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform float clock_now = 0.0;
uniform float trail_len = 1.0;
uniform float width_k = 0.026;
uniform float alpha_k = 0.56;
void vertex() {
    float age = clock_now - UV2.x;
    vec3 back = NORMAL;
    vec3 c = cross(back, vec3(0.0, 1.0, 0.0));
    float cl = length(c);
    vec3 side = cl > 1e-6 ? c / cl : vec3(0.0);
    float width = trail_len * width_k * (1.0 + age);
    VERTEX += back * age * trail_len * 1.2 + side * width * (1.0 - 2.0 * UV.y);
    COLOR.a = max(0.0, 1.0 - age / 0.65) * alpha_k;
    UV.x = age / 0.65;
}
void fragment() {
    float edge = smoothstep(0.0, 0.38, UV.y) * (1.0 - smoothstep(0.62, 1.0, UV.y));
    ALBEDO = COLOR.rgb;
    ALPHA = COLOR.a * edge;
}
"""

func setup(fac: String, kind: String, size: float, count := 4, seed_value := 0.0) -> void:
	faction = fac
	length = size
	phase = seed_value
	trail_mat = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = TRAIL
	trail_mat.shader = shader
	trail_mat.set_shader_parameter("trail_len", size)
	trail_mat.set_shader_parameter("width_k", 0.065 if fac == "chorus" else 0.026)
	trail_mat.set_shader_parameter("alpha_k", 0.22 if fac == "chorus" else 0.56)
	var lead := CRAFT.make(fac, kind)
	for i in count:
		var n: Node3D = lead if i == 0 else lead.duplicate()
		add_child(n)
		n.scale = Vector3.ONE * size * (0.83 if fac == "chorus" and i % 2 else 1.0)
		craft.append(n)
		var ribbon := MeshInstance3D.new()
		ribbon.name = "fx_craft_trail_%d" % i
		ribbon.top_level = true
		ribbon.mesh = ImmediateMesh.new()
		ribbon.material_override = trail_mat
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ribbon.extra_cull_margin = 20.0
		add_child(ribbon)
		ribbon.global_transform = Transform3D.IDENTITY
		trails.append({"node": ribbon, "hist": []})
	fit_formation()
	step(0.0)

# Measure in each craft's local frame, including nested mesh transforms and
# off-centre hulls. Never measure the ribbons or the current animated root.
func _mesh_bounds(n: Node3D, xf := Transform3D.IDENTITY) -> AABB:
	var box := AABB()
	if n is MeshInstance3D and n.mesh != null:
		box = xf * n.get_aabb()
	for child in n.get_children():
		if child is Node3D and not String(child.name).begins_with("fx_"):
			var other := _mesh_bounds(child, xf * child.transform)
			if other.size != Vector3.ZERO:
				box = box.merge(other) if box.size != Vector3.ZERO else other
	return box

func _flight_extent(r: Vector3) -> Vector3:
	# Godot's YXZ Euler order applies Z, then X, then Y. Absolute sine
	# bounds cover every rotation in step(), with cosines bounded by one.
	var z := sin(BANK.z)
	var x := sin(SPORE_BANK if faction == "chorus" else BANK.x)
	var y := sin(BANK.y)
	var rz := Vector3(r.x + r.y * z, r.y + r.x * z, r.z)
	var rx := Vector3(rz.x, rz.y + rz.z * x, rz.z + rz.y * x)
	return Vector3(rx.x + rx.z * y, rx.y, rx.z + rx.x * y)

func _side_reach(a: Vector3, b: Vector3, delta: float) -> float:
	var bank_x := SPORE_BANK if faction == "chorus" else BANK.x
	var sway := length * (SPORE_SWAY if faction == "chorus" else WEAVE.z)
	var ca := a.y * bank_x + a.x * BANK.y
	var cb := b.y * bank_x + b.x * BANK.y
	# Bank and sway share t. Maximise their combined sinusoid for each sign
	# of the absolute cosine terms, rather than adding impossible extremes.
	# This keeps slim craft (including SB4) at their original offsets.
	var peak := 0.0
	for sa in [-1.0, 1.0]:
		for sb in [-1.0, 1.0]:
			for sw in [-1.0, 1.0]:
				var c: float = ca * sa + cb * sb * cos(delta) - sway * sw * sin(delta)
				var s: float = -cb * sb * sin(delta) + sway * sw * (1.0 - cos(delta))
				peak = maxf(peak, Vector2(c, s).length())
	# sin(angle) <= abs(angle); cos(angle) <= 1. The two small product
	# terms cover roll feeding into pitch and yaw, at every flight phase.
	return a.z + b.z + peak + ((a.x + b.x) * bank_x + (a.y + b.y) * BANK.y) * BANK.z

# Also callable after replacing a preview's craft meshes. Normal play measures
# CRAFT.make's actual geometry once at setup, without per-frame mesh walks.
func fit_formation() -> void:
	rests.clear()
	var extents: Array[Vector3] = []
	var radii: Array[Vector3] = []
	var row_length := length
	for i in craft.size():
		var box := _mesh_bounds(craft[i])
		row_length = maxf(row_length, box.size.x * length)
		var scale_k := length * (0.83 if faction == "chorus" and i % 2 else 1.0)
		var r := box.position.abs().max(box.end.abs()) * scale_k * (1.0 + BREATH if faction == "chorus" else 1.0)
		radii.append(r)
		extents.append(_flight_extent(r))
	# A symmetric arrowhead (R280): the leader at the origin, then row 1 holds
	# two craft, row 2 three, and so on, every row centred on the leader's line
	# and spread by the same lateral step. Counts 3 and 6 read as a clean
	# triangle; any other count fills the rows in order (setup accepts any).
	rests.resize(craft.size())
	rests.fill(Vector3.ZERO)
	var idx := 1
	var row := 1
	while idx < craft.size():
		var in_row := row + 1
		for k in in_row:
			if idx >= craft.size():
				break
			var lateral := (float(in_row - 1) * 0.5 - float(k)) * 1.9 * length
			rests[idx] = Vector3(-0.95 * float(row) * row_length,
				(0.12 if idx % 2 else -0.09) * length, lateral)
			idx += 1
		row += 1
	var width_k := 1.0
	var depth_k := 1.0
	for i in craft.size():
		for j in i:
			var apart: Vector3 = (rests[i] - rests[j]).abs()
			var need_x: float = extents[i].x + extents[j].x + (2.0 * WEAVE.x + CLEARANCE) * length
			if is_zero_approx(apart.z):
				# Same lateral line: the leader against an even row's centre
				# craft (R280's wedge). Only more depth can separate them.
				if apart.x > 1e-6:
					depth_k = maxf(depth_k, need_x / apart.x)
			elif apart.x < need_x:
				var reach := _side_reach(radii[i], radii[j], (j - i) * 1.73)
				width_k = maxf(width_k, (reach + CLEARANCE * length) / apart.z)
	for i in rests.size():
		rests[i].z *= width_k
		rests[i].x *= depth_k

func _process(dt: float) -> void:
	step(dt)

func step(dt: float) -> void:
	clock += dt
	sample_t += dt
	var sample := sample_t >= 1.0 / 30.0
	if sample: sample_t = 0.0
	trail_mat.set_shader_parameter("clock_now", clock)
	for i in craft.size():
		var n: Node3D = craft[i]
		if active:
			var t := clock * (1.8 if faction == "chorus" else 1.25) + phase + i * 1.73
			var sway := SPORE_SWAY if faction == "chorus" else WEAVE.z
			n.position = rests[i] + length * Vector3(sin(t * 0.77) * WEAVE.x, sin(t * 1.19) * WEAVE.y, sin(t) * sway)
			# Bow follows the weave; roll anticipates the next turn.
			n.rotation = Vector3(-cos(t) * (SPORE_BANK if faction == "chorus" else BANK.x), -cos(t) * BANK.y, cos(t * 1.19) * BANK.z)
			if faction == "chorus":
				n.scale = Vector3.ONE * length * (0.83 if i % 2 else 1.0) * (1.0 + BREATH * sin(t * 2.0))
		var tr: Dictionary = trails[i]
		var hist: Array = tr.hist
		var stern := n.to_global(Vector3(-0.47, 0.0, 0.0))
		var changed := false
		if not hist.is_empty() and stern.distance_to(hist[0][0]) > length * 8.0:
			hist.clear()
			changed = true
		if active and sample:
			hist.push_front([stern, clock, -n.global_basis.x.normalized()])
			changed = true
		while not hist.is_empty() and (clock - float(hist[-1][1]) > 0.65 or hist.size() > 20):
			hist.pop_back()
			changed = true
		# issue 221: the shader ages the ribbon; the mesh only changes with its samples
		if changed or not tr.get("built", false):
			_draw_trail(tr)

func _draw_trail(tr: Dictionary) -> void:
	tr["built"] = true
	var mesh: ImmediateMesh = tr.node.mesh
	mesh.clear_surfaces()
	var hist: Array = tr.hist
	if hist.size() < 2: return
	var col: Color = LOOK.of(faction).engine
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for j in hist.size():
		# the sample's stern point, its wake direction and birth time; the vertex shader drifts, widens and fades it
		var p: Vector3 = hist[j][0]
		var back: Vector3 = hist[j][2]
		var born := float(hist[j][1])
		mesh.surface_set_color(Color(col.r, col.g, col.b, 1.0))
		mesh.surface_set_normal(back)
		mesh.surface_set_uv(Vector2(0, 0))
		mesh.surface_set_uv2(Vector2(born, 0))
		mesh.surface_add_vertex(p)
		mesh.surface_set_color(Color(col.r, col.g, col.b, 1.0))
		mesh.surface_set_normal(back)
		mesh.surface_set_uv(Vector2(0, 1))
		mesh.surface_set_uv2(Vector2(born, 0))
		mesh.surface_add_vertex(p)
	mesh.surface_end()
