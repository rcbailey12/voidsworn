extends Node3D
# Local flight stays inside the wing's hex. Only ShipView moves the rules unit.
# Each ribbon samples its own craft's stern in world space, including turns.
const CRAFT := preload("res://render/squadron_craft.gd")
const LOOK := preload("res://fx/faction_look.gd")
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
		var off := Vector3.ZERO
		if i > 0:
			off = Vector3(-0.95 * (1 + (i - 1) / 2), (0.12 if i % 2 else -0.09), (0.95 if i % 2 else -1.02) * (1 + (i - 1) / 2)) * size
		rests.append(off)
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
	step(0.0)

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
			var sway := 0.24 if faction == "chorus" else 0.14
			n.position = rests[i] + length * Vector3(sin(t * 0.77) * 0.12, sin(t * 1.19) * 0.09, sin(t) * sway)
			# Bow follows the weave; roll anticipates the next turn.
			n.rotation = Vector3(-cos(t) * (0.29 if faction == "chorus" else 0.22), -cos(t) * 0.12, cos(t * 1.19) * 0.065)
			if faction == "chorus":
				n.scale = Vector3.ONE * length * (0.83 if i % 2 else 1.0) * (1.0 + 0.025 * sin(t * 2.0))
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
