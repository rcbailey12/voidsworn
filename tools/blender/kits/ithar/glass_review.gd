extends RefCounted
# Loaded by the isolated review project after ShipView has read the installed GLB.
# The baked PBR materials are the fallback when the preview is not applied.

const GLASS := preload("blown_glass.gdshader")
const ShipView := preload("res://render/ship_view.gd")
const FACTION_LOOK := preload("res://fx/faction_look.gd")
const VARIANTS := {
	"A": Vector3(0.0, 0.0, 0.0),
	"B": Vector3(0.78, 0.0, 0.0),
	"C": Vector3(0.04, 1.0, 0.0),
	"R4": Vector3(0.78, 0.23, 0.0),
	"D": Vector3(0.34, 0.23, 0.13),
	"E": Vector3(0.14, 0.23, 0.36),
}


static func apply(ship: ShipView, environment: Environment, variant := "A") -> int:
	if ship.code != "I8_37" or environment.sky == null or not VARIANTS.has(variant):
		return 0
	var sky := environment.sky.sky_material as ShaderMaterial
	if sky == null:
		return 0
	var finish: Vector3 = VARIANTS[variant]
	var core := ship.hull.find_child("hp_core", true, false) as Node3D if finish.z > 0.0 else null
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
			if core != null:
				instance.set_instance_shader_parameter("core_origin", instance.to_local(core.global_position))
				instance.set_instance_shader_parameter("core_falloff", 9.0 / ship.L)
			count += 1
	return count


static func reference_material(environment: Environment, variant: String) -> ShaderMaterial:
	var material := _material(environment.sky.sky_material as ShaderMaterial, variant)
	material.set_shader_parameter("reference_glass", true)
	return material


static func _material(sky: ShaderMaterial, variant: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GLASS
	var finish: Vector3 = VARIANTS[variant]
	var clear := finish.z > 0.0
	material.set_shader_parameter("smoke", finish.x)
	material.set_shader_parameter("neutral_glass", variant == "R4" or clear)
	material.set_shader_parameter("dispersion", finish.y)
	material.set_shader_parameter("clear_glass", clear)
	material.set_shader_parameter("inner_glow", finish.z)
	var palette := FACTION_LOOK.of("ithar")
	var engine: Color = palette["engine"]
	var shield: Color = palette["shield"]
	var tint := engine.lerp(shield, 0.5)
	material.set_shader_parameter("core_light", Vector3(tint.r, tint.g, tint.b))
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
