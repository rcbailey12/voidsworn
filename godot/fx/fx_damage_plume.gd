extends RefCounted
# Issue 2044: one anchored card composites a short core and a longer sheath from the shipped Mantaflow vent bake.
# No sprite stream, world-clock flicker, new bake or per-frame node allocation. The parent supplies the attachment pose.

const SH := preload("res://fx/fx_shaders.gd")
const ATLAS := "res://fx/atlases/death/cruiser/vent_"
const SCORCH_LIFE := 1.0
const CORE_LIFE := 0.62
const HULK_DENSITY := 0.75
const HULK_WISP_DENSITY := 0.11
const HULK_SETTLE_S := 60.0

enum Form { SCORCH, DENT, WOUND, VENT, WISP, WING, HULK }
enum Profile { BASE, ELECTRIC, VIOLET }


static func material(fx) -> ShaderMaterial:
	var m: ShaderMaterial = fx.mat(SH.DAMAGE_PLUME, 1, "#define COMPAT\n" if fx.compat else "", "damage plume")
	m.set_shader_parameter("colour_atlas", load(ATLAS + "color.png"))
	m.set_shader_parameter("heat_atlas", load(ATLAS + "thickness.png"))
	return m


static func build(fx, parent: Node3D, p: Vector3, axis: Vector3, length: float, form: Form,
		fac: Dictionary, phase: float, name: String, tint := Color.TRANSPARENT,
		profile: Profile = Profile.BASE) -> MeshInstance3D:
	var glow: Color = fac.damage_glow if tint == Color.TRANSPARENT else tint
	var substance: int = fac.wound_kind
	var width := 0.52
	var density := 0.75
	var power := 0.0
	var period := 1.8
	var life := 0.0
	match form:
		Form.SCORCH:
			density = 0.34
			life = SCORCH_LIFE
		Form.DENT:
			density = 0.66
		Form.WOUND:
			power = 1.35
		Form.VENT:
			width = 0.40
			density = 0.42
			period = 2.7
		Form.WISP:
			width = 0.35
			power = 0.42
		Form.WING:
			width = 0.28
			power = 0.65
			period = 1.25
		Form.HULK:
			width = 0.43
			period = 3.4
			density = HULK_DENSITY
	var cold := form in [Form.SCORCH, Form.VENT, Form.HULK]
	var sheath := Color(0.075, 0.085, 0.10) if cold else Color(0.030, 0.026, 0.025)
	match substance:
		1: # Living tissue vents organic mist and a low bioluminescent pulse, never metal fire.
			sheath = glow * (0.25 if cold else 0.17)
			power *= 0.42
		2: # Clean pale vapour, with no soot or thermal core.
			sheath = glow * 0.30
			power = 0.0
		3: # Violet ionisation, including in the colder vent.
			sheath = glow * (0.20 if cold else 0.095)
	match profile:
		Profile.ELECTRIC:
			# Wounds V2's cold electric vent (old sprite kind 26), with no thermal ramp or soot.
			sheath = glow * 0.18
			power *= 0.38
		Profile.VIOLET:
			# The Eclipse wound lights its own buses, without a bright plume over the opening.
			power *= 0.35
	var m := material(fx)
	m.set_shader_parameter("colour_core", Vector3(glow.r, glow.g, glow.b))
	m.set_shader_parameter("colour_sheath", Vector3(sheath.r, sheath.g, sheath.b))
	m.set_shader_parameter("core_clip", CORE_LIFE)
	m.set_shader_parameter("core_power", power)
	m.set_shader_parameter("density", density)
	m.set_shader_parameter("dimensions", Vector2(length * width, length))
	m.set_shader_parameter("axis_local", axis.normalized() if axis.length_squared() > 0.0001 else Vector3.UP)
	m.set_shader_parameter("period", period)
	m.set_shader_parameter("phase", phase)
	m.set_shader_parameter("born", fx.now)
	m.set_shader_parameter("life_s", life)
	var plume := MeshInstance3D.new()
	plume.name = name
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	plume.mesh = quad
	plume.material_override = m
	plume.position = p
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plume.extra_cull_margin = length * 2.0
	parent.add_child(plume)
	if life > 0.0:
		fx.later(fx.now + life, _expire.bind(weakref(plume)))
	return plume


# R458: retire the density updates after a minute, but leave a thin vent attached until the wreck is cleared.
static func thin_hulk(m: ShaderMaterial, age: float) -> bool:
	var done := age >= HULK_SETTLE_S
	var density := HULK_WISP_DENSITY if done else lerpf(HULK_DENSITY, HULK_WISP_DENSITY, smoothstep(0.0, HULK_SETTLE_S, age))
	m.set_shader_parameter("density", density)
	return done


static func _expire(ref: WeakRef) -> void:
	var plume := ref.get_ref() as MeshInstance3D
	if is_instance_valid(plume):
		plume.queue_free()
