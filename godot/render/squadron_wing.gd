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
const TRAIL := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
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
		if not hist.is_empty() and stern.distance_to(hist[0][0]) > length * 8.0: hist.clear()
		if active and sample:
			hist.push_front([stern, clock, -n.global_basis.x.normalized()])
		while not hist.is_empty() and (clock - float(hist[-1][1]) > 0.65 or hist.size() > 20): hist.pop_back()
		_draw_trail(tr)

func _draw_trail(tr: Dictionary) -> void:
	var mesh: ImmediateMesh = tr.node.mesh
	mesh.clear_surfaces()
	var hist: Array = tr.hist
	if hist.size() < 2: return
	var col: Color = LOOK.of(faction).engine
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for j in hist.size():
		var age := clock - float(hist[j][1])
		var p: Vector3 = hist[j][0] + hist[j][2] * age * length * 1.2
		var back: Vector3 = hist[j][2]
		var side := back.cross(Vector3.UP).normalized()
		var width := length * (0.065 if faction == "chorus" else 0.026) * (1.0 + age)
		var alpha := maxf(0.0, 1.0 - age / 0.65) * (0.22 if faction == "chorus" else 0.56)
		mesh.surface_set_color(Color(col.r, col.g, col.b, alpha))
		mesh.surface_set_uv(Vector2(age / 0.65, 0))
		mesh.surface_add_vertex(p + side * width)
		mesh.surface_set_color(Color(col.r, col.g, col.b, alpha))
		mesh.surface_set_uv(Vector2(age / 0.65, 1))
		mesh.surface_add_vertex(p - side * width)
	mesh.surface_end()
