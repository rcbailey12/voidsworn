extends RefCounted
# Loaded by the isolated review project after ShipView has read the installed GLB.
# The baked PBR materials are the fallback when the preview is not applied.

const GLASS := preload("blown_glass.gdshader")
const ShipView := preload("res://render/ship_view.gd")
const VARIANTS := {
	"A": Vector2(0.0, 0.0),
	"B": Vector2(0.78, 0.0),
	"C": Vector2(0.04, 1.0),
	"R4": Vector2(0.78, 0.23),
}


static func apply(ship: ShipView, environment: Environment, variant := "A") -> int:
	if ship.code != "I8_37" or environment.sky == null or not VARIANTS.has(variant):
		return 0
	var sky := environment.sky.sky_material as ShaderMaterial
	if sky == null:
		return 0
	var count := 0
	var materials := {}
	for mesh in ship.meshes:
		var instance := mesh as MeshInstance3D
		for surface in instance.mesh.get_surface_count():
			var source := instance.get_active_material(surface) as BaseMaterial3D
			if source == null or source.albedo_color.a >= 0.99 or source.albedo_texture == null:
				continue
			if not materials.has(source):
				var material := _material(sky, variant)
				material.set_shader_parameter("glass_tint", source.albedo_texture)
				materials[source] = material
			instance.set_surface_override_material(surface, materials[source])
			count += 1
	return count


static func reference_material(environment: Environment, variant: String) -> ShaderMaterial:
	var material := _material(environment.sky.sky_material as ShaderMaterial, variant)
	material.set_shader_parameter("reference_glass", true)
	return material


static func _material(sky: ShaderMaterial, variant: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GLASS
	var finish: Vector2 = VARIANTS[variant]
	material.set_shader_parameter("smoke", finish.x)
	material.set_shader_parameter("neutral_glass", variant == "R4")
	material.set_shader_parameter("dispersion", finish.y)
	var nebula = sky.get_shader_parameter("neb_tex")
	if nebula is Texture2D:
		material.set_shader_parameter("nebula", nebula)
		material.set_shader_parameter("nebula_gain", sky.get_shader_parameter("neb_gain"))
		material.set_shader_parameter("sky_turn", sky.get_shader_parameter("turn"))
	var panorama = sky.get_shader_parameter("pano")
	var has_panorama = sky.get_shader_parameter("has_pano")
	if panorama is Texture2D and has_panorama is float and has_panorama > 0.0:
		material.set_shader_parameter("panorama", panorama)
		material.set_shader_parameter("panorama_gain", 0.9)
	var sun_direction = sky.get_shader_parameter("sun_dir")
	if sun_direction is Vector3:
		material.set_shader_parameter("sun_direction", sun_direction)
		material.set_shader_parameter("sun_gain", sky.get_shader_parameter("sun_k"))
	return material
