extends RefCounted

const GLASS := preload("glass1058/glass_review.gd")
const LOOK := preload("res://render/look.gd")
const SETUPS := ["today", "bright_sky", "nebula_map", "edge_light", "light_strip"]

# The same added light goes to the Godot radiance map and the run 4 glass.
# The glass computes its own reflection, so it cannot see Godot's radiance map.
const REFLECTION := """
uniform int probe_setup = 0;
uniform vec3 probe_star_a = vec3(1.0, 0.0, 0.0);
uniform vec3 probe_star_b = vec3(-1.0, 0.0, 0.0);
uniform vec3 probe_edge_dir = vec3(0.0, 1.0, 0.0);

vec3 probe_extra(vec3 ray, vec3 base, vec3 gas) {
	if (probe_setup == 1) {
		return 2.5 * base;
	}
	if (probe_setup == 2) {
		float a = pow(max(dot(ray, probe_star_a), 0.0), 75.0);
		float b = pow(max(dot(ray, probe_star_b), 0.0), 100.0);
		return gas * 5.0 + a * vec3(1.8, 1.55, 1.25) + b * vec3(0.85, 1.25, 1.8);
	}
	if (probe_setup == 3) {
		return vec3(1.9, 2.25, 2.7) * pow(max(dot(ray, probe_edge_dir), 0.0), 48.0);
	}
	if (probe_setup == 4) {
		// A long pale band gives curved glass a continuous reflection to bend.
		float distance_to_band = abs(dot(ray, normalize(vec3(0.76, 0.29, -0.58))));
		float strip = 1.0 - smoothstep(0.045, 0.18, distance_to_band);
		return vec3(1.55, 1.67, 1.75) * strip * smoothstep(-0.33, 0.56, ray.y);
	}
	return vec3(0.0);
}
"""

var environment: Environment
var original_sky: Sky
var camera: Camera3D
var rim: DirectionalLight3D
var setup := 0
var star_a := Vector3.RIGHT
var star_b := Vector3.LEFT
var glass_shader: Shader
var sky_shader: Shader


func prepare(owner: Node3D, battle_env: Environment, view: Camera3D) -> bool:
	environment = battle_env
	camera = view
	original_sky = environment.sky
	if original_sky == null or not original_sky.sky_material is ShaderMaterial:
		return false
	var original := original_sky.sky_material as ShaderMaterial
	var code := original.shader.code
	var gas_line := "col += pow(t.rgb, vec3(2.2)) * neb_gain;"
	var glass_line := "return pow(gas, vec3(2.2)) * nebula_gain + stars * panorama_gain;"
	if not code.contains(gas_line) or not GLASS.GLASS.code.contains(glass_line):
		push_error("Probe needs the production world sky and the run 4 glass shader")
		return false
	code = code.replace("void sky() {", REFLECTION + "\nvoid sky() {\n\tvec3 probe_gas = vec3(0.0);")
	code = code.replace(gas_line, "probe_gas = pow(t.rgb, vec3(2.2));\n\t\t" + gas_line)
	code = code.replace("COLOR = col;", "if (AT_CUBEMAP_PASS) { col += probe_extra(EYEDIR, col, probe_gas); }\n\tCOLOR = col;")
	sky_shader = Shader.new()
	sky_shader.code = code
	glass_shader = Shader.new()
	glass_shader.code = GLASS.GLASS.code.replace("vec2 sky_uv(", REFLECTION + "\nvec2 sky_uv(")
	glass_shader.code = glass_shader.code.replace(glass_line,
		"vec3 linear_gas = pow(gas, vec3(2.2));\n\tvec3 base = linear_gas * nebula_gain + stars * panorama_gain;\n\treturn base + probe_extra(ray, base, linear_gas);")
	var lamps: PackedVector4Array = original.get_shader_parameter("lamp")
	var turn: Basis = original.get_shader_parameter("turn")
	if lamps.size() < 2 or lamps[0].w <= 0.0 or lamps[1].w <= 0.0:
		push_error("Probe needs two live stars in the nebula map")
		return false
	star_a = (turn.inverse() * Vector3(lamps[0].x, lamps[0].y, lamps[0].z)).normalized()
	star_b = (turn.inverse() * Vector3(lamps[1].x, lamps[1].y, lamps[1].z)).normalized()
	rim = DirectionalLight3D.new()
	rim.light_color = Color(0.80, 0.88, 1.0)
	rim.light_energy = 0.45
	rim.light_specular = 3.0
	rim.light_cull_mask = LOOK.RIM_LAYER | LOOK.RIM_SOFT_LAYER
	rim.shadow_enabled = false
	rim.hide()
	owner.add_child(rim)
	return true


func apply(case_name: String) -> bool:
	setup = SETUPS.find(case_name)
	if setup < 0:
		return false
	rim.visible = setup == 3
	environment.sky = original_sky
	if setup in [1, 2, 4]:
		var mat := _copy_parameters(original_sky.sky_material, sky_shader)
		_set_light(mat)
		var sky := original_sky.duplicate() as Sky
		sky.sky_material = mat
		sky.radiance_size = Sky.RADIANCE_SIZE_512 if setup == 1 else Sky.RADIANCE_SIZE_256
		environment.sky = sky
	return true


func apply_glass(ship: Node3D) -> Array[ShaderMaterial]:
	var result: Array[ShaderMaterial] = []
	if GLASS.apply(ship, environment, "R4") == 0:
		return result
	var copies := {}
	for instance: MeshInstance3D in ship.meshes:
		for surface in instance.mesh.get_surface_count():
			var mat := instance.get_active_material(surface) as ShaderMaterial
			if mat == null or mat.shader != GLASS.GLASS:
				continue
			if not copies.has(mat):
				copies[mat] = _glass_material(mat)
			instance.set_surface_override_material(surface, copies[mat])
			result.append(copies[mat])
	return result


func reference_glass() -> ShaderMaterial:
	return _glass_material(GLASS.reference_material(environment, "R4"))


func active_glass_count(ship: Node3D) -> int:
	var count := 0
	for mesh: MeshInstance3D in ship.meshes:
		for surface in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(surface) as ShaderMaterial
			if mat != null and mat.has_meta("fx_hull_source"):
				mat = mat.get_meta("fx_hull_source") as ShaderMaterial
			if mat != null and mat.shader in [GLASS.GLASS, glass_shader]:
				count += 1
	return count


func aim(materials: Array[ShaderMaterial]) -> void:
	if setup != 3:
		return
	var basis := camera.global_transform.basis
	var direction := (-basis.z).rotated(basis.x.normalized(), deg_to_rad(29.0)).normalized()
	rim.global_basis = Basis.looking_at(-direction, Vector3.UP)
	for mat in materials:
		mat.set_shader_parameter("probe_edge_dir", direction)


func _glass_material(source: ShaderMaterial) -> ShaderMaterial:
	if setup == 0:
		return source
	var mat := _copy_parameters(source, glass_shader)
	_set_light(mat)
	return mat


func _set_light(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("probe_setup", setup)
	mat.set_shader_parameter("probe_star_a", star_a)
	mat.set_shader_parameter("probe_star_b", star_b)


static func _copy_parameters(source: ShaderMaterial, shader: Shader) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = shader
	for uniform_info in source.shader.get_shader_uniform_list():
		var parameter := str(uniform_info.name)
		result.set_shader_parameter(parameter, source.get_shader_parameter(parameter))
	return result
