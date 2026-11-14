extends SceneTree
# R78 Q18 capture harness: the run 5 finale board brightening sector by sector as the new sun catches. Builds the battle
# world on its own (no ships, so a checkout without godot/gen still captures the board and lights), saves one PNG per
# stage of the dawn sweep, and quits.
#
#   godot --path godot --resolution 1280x720 --script res://world/finale_shots.gd -- --out DIR
#
# The battle itself drives the stages from its round events (godot/world/world.gd finale_for_round); this harness calls
# finale_stage() directly so every stage can be seen.

const WORLD := preload("res://world/world.gd")

# The battle's own board is a separate mesh from the world, so this harness has none. A dim hex grid under the dawn
# stands in for it, so a dark stage still reads as the war table and every stage shows the light crossing it.
const BASE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 centre = vec3(0.0);
uniform vec2 half_ext = vec2(200.0, 130.0);
uniform vec2 hex_origin = vec2(0.0);
uniform vec3 hole = vec3(0.0);
uniform float hole_r = 0.0;
varying vec3 vW;
void vertex() { vW = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float hex_edge(vec2 p) {
	float r = p.y / 15.0;
	vec2 a = vec2(p.x / 17.3205 - r * 0.5, r);
	vec3 c = vec3(a.x, a.y, -a.x - a.y);
	vec3 rc = floor(c + 0.5);
	vec3 d = abs(rc - c);
	if (d.x > d.y && d.x > d.z) rc.x = -rc.y - rc.z;
	else if (d.y > d.z) rc.y = -rc.x - rc.z;
	else rc.z = -rc.x - rc.y;
	vec2 loc = a - vec2(rc.x, rc.y);
	return 0.5 - max(abs(loc.x), max(abs(loc.y), abs(loc.x + loc.y)));
}
void fragment() {
	vec2 q = abs(vW.xz - centre.xz) - half_ext;
	float sd = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
	float feather = 1.0 - smoothstep(0.0, 22.0, sd);
	float line = 1.0 - smoothstep(0.0, 0.045, hex_edge(vW.xz - hex_origin));
	ALBEDO = (vec3(0.045, 0.042, 0.038) + vec3(0.085, 0.072, 0.052) * line);
	// leave the dead-star hex open, as the battle board does, so the Hollow Sun still shows under the board
	float hd = length(vW.xz - hole.xz);
	ALPHA = feather * smoothstep(hole_r - 6.0, hole_r + 6.0, hd);
}
"""

var out := "user://finale_shots"


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i] == "--out" and i + 1 < a.size():
			out = a[i + 1]
			i += 2
		else:
			i += 1
	DirAccess.make_dir_recursive_absolute(out)

	var stage_root := Node3D.new()
	stage_root.name = "FinaleStage"
	root.add_child(stage_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 8.0
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.8
	env.glow_intensity = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	stage_root.add_child(we)

	var key := DirectionalLight3D.new()
	key.transform = Transform3D(Basis.looking_at(Vector3(-0.45, -0.70, -0.55).normalized(), Vector3.UP), Vector3.ZERO)
	key.light_color = Color(1.0, 0.96, 0.90)
	key.light_energy = 2.0
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 600.0
	stage_root.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.transform = Transform3D(Basis.looking_at(Vector3(0.6, -0.2, 0.75).normalized(), Vector3.UP), Vector3.ZERO)
	fill.light_color = Color(0.55, 0.65, 0.85)
	fill.light_energy = 0.5
	stage_root.add_child(fill)

	var cam := Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.5
	cam.far = 4000.0
	stage_root.add_child(cam)
	cam.look_at_from_position(Vector3(0, 235, 370), Vector3(0, -6, 0), Vector3.UP)
	cam.current = true

	var hs := 10.0
	var hw := func(q: int, r: int) -> Vector3: return Vector3(hs * sqrt(3.0) * (q + r * 0.5), 0.0, 1.5 * hs * r)
	var terrain := {}
	for q in range(-8, 9):
		for r in range(-6, 7):
			terrain["%d,%d" % [q, r]] = ""
	var rocks := [[-7, -4], [-6, -4], [-7, -3], [-6, -3], [7, -4], [6, -4], [7, -3], [6, -3], [-8, 3], [8, 3], [-2, -5], [2, -5]]
	for k in rocks:
		terrain["%d,%d" % [k[0], k[1]]] = "rock"
	for k in [[-5, 2], [5, 2], [0, 4], [-1, 5], [1, 5], [-3, -1], [3, -1]]:
		terrain["%d,%d" % [k[0], k[1]]] = "debris"

	var w = WORLD.new()
	stage_root.add_child(w)
	w.build({"terrain": terrain, "map": {"deadstar": {"q": -6, "r": -5}}, "units": []},
		{"biome": {"rock": "ice", "planet": 7}, "fac": "deathless", "hex_world": hw, "environment": env,
		"quality": "max", "finale": true})
	_board_base(stage_root, w)
	await w.wait_ready()
	print("[finale_shots] finale=", w.finale, " children=", w.get_child_count(), " dawnie=", w._dawn_mat != null, " notes=", "; ".join(w.notes))
	for k in 30:
		await process_frame

	for s in 6:
		w.finale_stage(s)
		for k in 24:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		var p := out.path_join("finale_board_%d_of_6.png" % [s + 1])
		_save(img, p)
		print("[finale_shots] ", p)

	# a wide view at full dawn, framed on the board and the Hollow Sun
	cam.look_at_from_position(Vector3(0, 420, 700), Vector3(-40, 0, -20), Vector3.UP)
	for k in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	var wide := out.path_join("finale_board_wide.png")
	_save(root.get_texture().get_image(), wide)
	print("[finale_shots] ", wide)
	print("[finale_shots] done")
	quit(0)


# The owner's picture rule: no taller than 720 px. The window opens at the project's 4K size, so shrink before saving.
func _save(img: Image, p: String) -> void:
	var s := minf(1280.0 / float(img.get_width()), 720.0 / float(img.get_height()))
	img.resize(int(round(float(img.get_width()) * s)), int(round(float(img.get_height()) * s)), Image.INTERPOLATE_LANCZOS)
	img.save_png(p)


func _board_base(parent: Node3D, w) -> void:
	var ext: Vector3 = (w._hi - w._lo) * 0.5
	var mi := MeshInstance3D.new()
	mi.name = "FinaleBoardBase"
	var pm := PlaneMesh.new()
	pm.size = Vector2(ext.x * 2.0 + 20.0, ext.z * 2.0 + 20.0)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = BASE_SHADER
	m.shader = sh
	m.set_shader_parameter("centre", w._center)
	m.set_shader_parameter("half_ext", Vector2(ext.x + 10.0, ext.z + 10.0))
	m.set_shader_parameter("hex_origin", w._hex_origin)
	m.render_priority = -20   # under the dawn plane (-15), which adds its light on top
	if w._well != Vector3.INF:
		m.set_shader_parameter("hole", w._well)
		m.set_shader_parameter("hole_r", 38.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(w._center.x, w._center.y - 3.5, w._center.z)
	parent.add_child(mi)
