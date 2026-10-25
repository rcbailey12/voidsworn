extends Node
# The game slice (--board, SPEC.md "Game slice" as trimmed): the battle seen as Voidsworn plays it. A top-down tactical
# camera (pitch 55 degrees) over a hex board at the game's scale (flat-topped hexes 20 units across, 20 by 14, in the
# plane y = -6 under the formation), one movement-range highlight on the selected ship, a hover outline on the ship under
# the mouse, a selection ring on click, and native Control UI (name labels, hull and shield bars) drawn inside the
# render target so it is sharp at 4K and 1440p. The ships, effects and physics run underneath.

const PITCH := 55.0
const BOARD_Y := -6.0
const COLS := 20
const ROWS := 14
const MOVE_RANGE := 3

const BOARD_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float R = 10.0;
uniform vec2 origin;
uniform vec2 sel_hex = vec2(-100.0);
uniform int range = 3;
uniform vec2 hover_hex = vec2(-100.0);
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
// flat-topped axial coordinates
vec2 to_axial(vec2 p) {
	float q = (2.0 / 3.0 * p.x) / R;
	float r = (-1.0 / 3.0 * p.x + sqrt(3.0) / 3.0 * p.y) / R;
	return vec2(q, r);
}
vec2 axial_round(vec2 a) {
	vec3 c = vec3(a.x, a.y, -a.x - a.y);
	vec3 rc = round(c);
	vec3 d = abs(rc - c);
	if (d.x > d.y && d.x > d.z) { rc.x = -rc.y - rc.z; } else if (d.y > d.z) { rc.y = -rc.x - rc.z; }
	return rc.xy;
}
vec2 axial_center(vec2 h) { return vec2(R * 1.5 * h.x, R * sqrt(3.0) * (h.y + h.x * 0.5)); }
float hex_dist(vec2 a, vec2 b) { vec2 d = a - b; return (abs(d.x) + abs(d.y) + abs(-d.x - d.y)) * 0.5; }
void fragment() {
	vec2 p = wp.xz - origin;
	vec2 h = axial_round(to_axial(p));
	// offset coordinates (odd columns shifted) to clip the board to 20 by 14
	float col = h.x;
	float row = h.y + (h.x - mod(h.x, 2.0)) * 0.5;
	if (col < 0.0 || col > 19.0 || row < 0.0 || row > 13.0) { discard; }
	vec2 c = axial_center(h);
	vec2 d = abs(p - c);
	// distance to the flat-topped hex edge (0 at the edge, R*sqrt(3)/2 at the centre)
	float edge = R * sqrt(3.0) * 0.5 - max(d.y, d.x * sqrt(3.0) * 0.5 + d.y * 0.5);
	float w = fwidth(edge) * 1.2;
	float line = 1.0 - smoothstep(0.25 - w, 0.25 + w, edge);
	vec3 col3 = vec3(0.45, 0.7, 0.85);
	float a = line * 0.55;
	float sd = hex_dist(h, sel_hex);
	if (sd <= float(range)) {
		col3 = mix(col3, vec3(0.35, 0.6, 1.0), 0.6);
		a = max(a, 0.16 + line * 0.5);
	}
	if (hex_dist(h, hover_hex) < 0.5) {
		a = max(a, 0.1 + line * 0.8);
		col3 = vec3(0.9, 0.95, 1.0);
	}
	ALBEDO = col3;
	ALPHA = clamp(a, 0.0, 1.0);
}
"""

# Hover outline: an overlay pass that adds a bright gold rim where the hull turns away from the camera.
const OUTLINE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
uniform vec3 col = vec3(1.0, 0.8, 0.3);
void fragment() {
	float rim = pow(clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0), 3.0);
	ALBEDO = col * rim * 3.0;
	ALPHA = 1.0;
}
"""

var click_frames := -1
var vp: SubViewport
var cam: Camera3D
var ships: Array = []
var res := Vector2i(1920, 1080)
var R := 10.0
var origin := Vector2.ZERO
var board_mat: ShaderMaterial
var outline: ShaderMaterial
var hovered := -1
var selected := 1
var ring: MeshInstance3D
var ui: Control
var labels: Array = []
var scripted := false
var _pending_click := -1


func setup(_vp: SubViewport, world: Node3D, _cam: Camera3D, _ships: Array, _res: Vector2i, hex: float, _scripted: bool) -> void:
	vp = _vp
	cam = _cam
	ships = _ships
	res = _res
	R = hex * 0.5
	scripted = _scripted
	# board plane, centred on the formation
	var w := (COLS - 1) * 1.5 * R + 2.0 * R
	var h := (ROWS + 0.5) * sqrt(3.0) * R
	origin = Vector2(-w * 0.5 + R, -h * 0.5 + sqrt(3.0) * R * 0.5)
	var pm := PlaneMesh.new()
	pm.size = Vector2(w + 4.0 * R, h + 4.0 * R)
	board_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = BOARD_SHADER
	board_mat.shader = sh
	board_mat.set_shader_parameter("R", R)
	board_mat.set_shader_parameter("origin", origin)
	board_mat.set_shader_parameter("range", MOVE_RANGE)
	var plane := MeshInstance3D.new()
	plane.mesh = pm
	plane.material_override = board_mat
	plane.position = Vector3(0, BOARD_Y, 0)
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(plane)
	outline = ShaderMaterial.new()
	var osh := Shader.new()
	osh.code = OUTLINE_SHADER
	outline.shader = osh
	# selection ring
	var tm := TorusMesh.new()
	tm.inner_radius = R * 1.15
	tm.outer_radius = R * 1.3
	tm.rings = 64
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color(1.0, 0.8, 0.3)
	rm.emission_enabled = true
	rm.emission = Color(1.0, 0.75, 0.25)
	rm.emission_energy_multiplier = 2.0
	ring = MeshInstance3D.new()
	ring.mesh = tm
	ring.material_override = rm
	ring.scale = Vector3(1, 0.15, 1)
	ring.visible = false
	world.add_child(ring)
	_build_ui()


func _build_ui() -> void:
	var k := res.y / 1080.0
	var layer := CanvasLayer.new()
	vp.add_child(layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var theme := Theme.new()
	theme.default_font_size = int(round(17.0 * k))
	ui.theme = theme
	for i in mini(ships.size(), 6):
		var s: Dictionary = ships[i]
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", int(3 * k))
		var name := Label.new()
		name.text = s["name"]
		name.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
		name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		name.add_theme_constant_override("outline_size", int(4 * k))
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(name)
		var hull := _bar(Color(0.35, 0.9, 0.45), 0.55 + 0.4 * fposmod(i * 0.37, 1.0), k)
		box.add_child(hull)
		if s["shield"] != null:
			box.add_child(_bar(Color(0.35, 0.7, 1.0), 0.4 + 0.5 * fposmod(i * 0.61, 1.0), k))
		box.custom_minimum_size = Vector2(140, 0) * k
		ui.add_child(box)
		labels.append(box)


func _bar(col: Color, v: float, k: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.min_value = 0.0
	b.max_value = 1.0
	b.value = v
	b.custom_minimum_size = Vector2(140, 9) * k
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(int(2 * k))
	var fg := StyleBoxFlat.new()
	fg.bg_color = col
	fg.set_corner_radius_all(int(2 * k))
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	return b


func camera_pose() -> Transform3D:
	# frame the whole board from the -z side at 55 degrees pitch
	var span := (COLS - 1) * 1.5 * R + 2.0 * R
	var dist := span * 0.5 / tan(deg_to_rad(33.0)) * 1.05
	var p := Vector3(0, BOARD_Y, 0) + Vector3(0, sin(deg_to_rad(PITCH)), -cos(deg_to_rad(PITCH))) * dist
	return Transform3D(Basis.looking_at(Vector3(0, BOARD_Y, 0) - p, Vector3.UP), p)


func mouse_from_window(p: Vector2, win: Vector2i) -> Vector2:
	var sc := minf(float(win.x) / res.x, float(win.y) / res.y)
	var off := (Vector2(win) - Vector2(res) * sc) * 0.5
	return (p - off) / sc


# Scripted pointer for the benchmark and stills: hover over the Hegemony from 0.5 s, click the barge at 2.0 s.
func scripted_mouse(t: float) -> Vector2:
	if t >= 2.0 and _pending_click == -1 and click_frames == -1:
		_pending_click = 2
	var target := 2 if t >= 2.0 else 1
	if t < 0.5 or target >= ships.size():
		return Vector2(-1, -1)
	return cam.unproject_position((ships[target]["root"] as Node3D).position)


func click(mouse: Vector2) -> void:
	var i := _pick(mouse)
	if i < 0:
		return
	selected = i
	ring.visible = true
	_place_ring()
	var f0 := Engine.get_frames_drawn()
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	click_frames = Engine.get_frames_drawn() - f0
	print("[enginetest] board: click to visible ring %d frame(s)" % click_frames)


func _place_ring() -> void:
	var sp: Vector3 = (ships[selected]["root"] as Node3D).position
	ring.position = Vector3(sp.x, BOARD_Y + 0.3, sp.z)


func update(_t: float, mouse: Vector2) -> void:
	if _pending_click >= 0:
		_pending_click = -2
		click(mouse)
	# hover outline
	var h := _pick(mouse) if mouse.x >= 0.0 else -1
	if h != hovered:
		if hovered >= 0:
			for m in ships[hovered]["meshes"]:
				(m as GeometryInstance3D).material_overlay = null
		hovered = h
		if hovered >= 0:
			for m in ships[hovered]["meshes"]:
				(m as GeometryInstance3D).material_overlay = outline
	# board highlights follow the ships as they drift
	if selected < ships.size():
		board_mat.set_shader_parameter("sel_hex", _hex_of((ships[selected]["root"] as Node3D).position))
	board_mat.set_shader_parameter("hover_hex", _hex_of((ships[hovered]["root"] as Node3D).position) if hovered >= 0 else Vector2(-100, -100))
	if ring.visible:
		_place_ring()
	# labels and bars over each flagship
	for i in labels.size():
		var s: Dictionary = ships[i]
		var top: Vector3 = (s["root"] as Node3D).position + Vector3(0, (s["half"] as Vector3).y + 3.0, 0)
		var box: Control = labels[i]
		box.visible = not cam.is_position_behind(top)
		box.position = cam.unproject_position(top) - Vector2(box.size.x * 0.5, box.size.y)


func _hex_of(p: Vector3) -> Vector2:
	var q := (2.0 / 3.0 * (p.x - origin.x)) / R
	var r := (-1.0 / 3.0 * (p.x - origin.x) + sqrt(3.0) / 3.0 * (p.z - origin.y)) / R
	var x := q
	var z := r
	var y := -x - z
	var rx := roundf(x)
	var ry := roundf(y)
	var rz := roundf(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2(rx, rz)


# Picking: the ray under the pointer against each ship's box (ships do not rotate, so their boxes stay axis-aligned).
func _pick(mouse: Vector2) -> int:
	if mouse.x < 0.0:
		return -1
	var o := cam.project_ray_origin(mouse)
	var d := cam.project_ray_normal(mouse)
	var best := -1
	var best_t := 1e9
	for i in ships.size():
		var s: Dictionary = ships[i]
		var c: Vector3 = (s["root"] as Node3D).position
		var hv: Vector3 = s["half"]
		var box := AABB(c - hv, hv * 2.0)
		var hit = box.intersects_ray(o, d)
		if hit != null:
			var tt := o.distance_to(hit)
			if tt < best_t:
				best_t = tt
				best = i
	return best
