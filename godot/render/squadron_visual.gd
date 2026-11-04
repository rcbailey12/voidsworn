extends Node3D
# A wing owns each craft's pose and exhaust. Nothing here moves the rules unit,
# changes its facing, or adds combatants. Trails keep their samples in world space.
const MODELS := preload("res://render/squadron_models.gd")
const HT := preload("res://render/hull_table.gd")
const EXHAUST := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
varying vec4 trail_color;
void vertex() { trail_color = COLOR; }
void fragment() {
	float soft = pow(max(0.0, 1.0 - abs(UV.y * 2.0 - 1.0)), 1.7);
	ALBEDO = trail_color.rgb;
	ALPHA = trail_color.a * soft;
}
"""
var craft: Array = []
var trails: MeshInstance3D
var history: Array = []
var emitters: Array = []
var faction := "hegemony"
var kind := "fighter"
var length := 3.84
var clock := 0.0
var sample_clock := 0.0
var last_pos := Vector3.ZERO
var last_yaw := 0.0
var launch_time := 10.0
var launch_origin := Vector3.ZERO

func setup(fac: String, tpl: String, craft_length: float, phase: float) -> void:
	faction = fac
	kind = MODELS.kind_for(fac, tpl)
	length = craft_length
	clock = phase
	var count := 7 if kind == "spore" else 5
	var mesh := MODELS.mesh_for(fac, kind)
	for i in count:
		var n := MeshInstance3D.new()
		n.name = "craft_%d" % i
		n.mesh = mesh
		add_child(n)
		var row := (i + 1) / 2
		var side := -1.0 if i % 2 == 0 else 1.0
		var rest := Vector3(0.65 - row * 0.87, (i % 3 - 1) * 0.1, 0 if i == 0 else side * (0.65 + row * 0.14)) * length
		if kind == "spore": rest *= 0.82
		n.position = rest
		n.scale = Vector3.ONE * length * (0.7 if kind == "spore" else 1.0)
		craft.append({"node": n, "rest": rest, "phase": i * 1.73, "scale": n.scale})
		for nozzle in MODELS.nozzles(kind):
			emitters.append({"node": n, "at": nozzle})
			history.append([])
	trails = MeshInstance3D.new()
	trails.name = "fx_wing_trails"
	trails.top_level = true
	trails.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	trails.extra_cull_margin = 64.0
	var shader := Shader.new()
	shader.code = EXHAUST
	var mat := ShaderMaterial.new()
	mat.shader = shader
	trails.material_override = mat
	add_child(trails)
	trails.global_transform = Transform3D.IDENTITY
	last_pos = global_position
	last_yaw = global_rotation.y

func launch_from(origin: Vector3) -> void:
	launch_origin = origin
	launch_time = 0.0
	for hist in history: hist.clear()
	step(0.0, false)

func step(dt: float, stopped: bool) -> void:
	clock += dt
	launch_time += dt
	var speed := global_position.distance_to(last_pos) / maxf(dt, 0.001)
	var yaw := global_rotation.y
	var turn := clampf(angle_difference(last_yaw, yaw) / maxf(dt, 0.001), -1.5, 1.5)
	last_pos = global_position
	last_yaw = yaw
	if stopped:
		for hist in history: hist.clear()
		trails.mesh = null
		return
	var moving := clampf(speed / 26.0, 0.0, 1.0)
	var loose := 1.5 if kind == "spore" else (0.65 if faction == "hegemony" else 1.0)
	for i in craft.size():
		var c: Dictionary = craft[i]
		var n: Node3D = c.node
		var t := clock * (1.4 if kind == "spore" else 1.0) + float(c.phase)
		var weave := Vector3(sin(t * 0.73) * 0.13, sin(t * 1.27) * 0.12, sin(t) * 0.16) * length * loose
		var rest: Vector3 = c.rest
		rest.x -= moving * length * (i * 0.11)
		var destination := rest + weave
		var progress := smoothstep(0.0, 1.45, launch_time - i * 0.11)
		if progress < 1.0:
			var origin := to_local(launch_origin)
			destination = origin.lerp(destination, progress) + Vector3.UP * sin(progress * PI) * length * 0.7
		n.position = destination
		# Roll about the bow (+X). Phase differences break the rigid clone look.
		n.rotation = Vector3(clampf(-turn * 0.27 + cos(t) * 0.24 * loose, -0.58, 0.58), cos(t) * 0.13 * loose, cos(t * 1.27) * 0.07)
		n.scale = c.scale
		if kind == "spore": n.scale *= 1.0 + sin(t * 2.0) * 0.035
		# Craft stay inside the bay until their own staggered departure.
		n.visible = launch_time >= i * 0.11
	sample_clock += dt
	if sample_clock >= 0.045:
		sample_clock = fmod(sample_clock, 0.045)
		for i in emitters.size():
			var n: Node3D = emitters[i].node
			if not n.visible: continue
			var nozzle: Vector3 = emitters[i].at
			var aft := -n.global_basis.x.normalized()
			(history[i] as Array).push_front({"p": n.to_global(nozzle), "t": clock, "aft": aft})
	_draw_trails()

func _draw_trails() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := 0
	var camera := get_viewport().get_camera_3d()
	var color: Color = HT.FAC3D[faction]["eng"]
	for hist in history:
		while not hist.is_empty() and (clock - float(hist.back().t) > 0.65 or hist.size() > 16): hist.pop_back()
		for j in range(1, hist.size()):
			var a: Dictionary = hist[j - 1]
			var b: Dictionary = hist[j]
			var age_a := clock - float(a.t)
			var age_b := clock - float(b.t)
			var pa: Vector3 = a.p + a.aft * age_a * length * 3.0
			var pb: Vector3 = b.p + b.aft * age_b * length * 3.0
			var view_dir := (camera.global_position - pa).normalized() if camera != null else Vector3.UP
			var side := (pb - pa).normalized().cross(view_dir).normalized()
			var wa := length * 0.034 * (1.0 - age_a / 0.65)
			var wb := length * 0.034 * (1.0 - age_b / 0.65)
			var ca := Color(color, 0.48 * pow(1.0 - age_a / 0.65, 1.5))
			var cb := Color(color, 0.48 * pow(1.0 - age_b / 0.65, 1.5))
			for v in [[pa - side * wa, ca, Vector2(0, 0)], [pa + side * wa, ca, Vector2(0, 1)], [pb + side * wb, cb, Vector2(1, 1)], [pa - side * wa, ca, Vector2(0, 0)], [pb + side * wb, cb, Vector2(1, 1)], [pb - side * wb, cb, Vector2(1, 0)]]:
				st.set_color(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])
				vertices += 1
	trails.mesh = st.commit() if vertices > 0 else null
