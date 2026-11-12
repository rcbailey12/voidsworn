extends DirectionalLight3D
# Issue 362 (battle camera readability): the hulls' rim light. render/look.gd rim_light() puts one beside the key light.
#
# What it does: a back light that shines from behind the ships as the camera sees them, toward the camera and a little
# down, so the grazing faces along a hull's outline catch a bright edge (Fresnel makes a surface's specular strongest
# there). A dark hull (Sunward black iron, Eclipse violet-black) then keeps an outline against the darkest sky. Its
# diffuse share is kept low and its specular share high (Light3D light_specular), so it draws an edge and adds little
# flat light. It follows the camera's heading every frame, so the edge stays on the outline wherever the player turns.
#
# What it lights: only surfaces on render layer LOOK.RIM_LAYER. This node puts every hull surface on that layer when it
# enters the scene: a surface whose material came from LOOK.hull (meta "look_hull"), or a damaged or dying hull material
# made from one (meta "fx_hull_source"). Rocks, the planet, the board and every effect keep their light as before (the
# effects are unshaded and never see lights anyway). No shadows, no new shader: a directional light is a uniform in the
# shaders the scene already has.

const LOOK := preload("res://render/look.gd")

var _cfg := {}


func _ready() -> void:
	configure()
	get_tree().node_added.connect(_on_added)
	_mark_tree(get_parent())
	_follow()


func configure() -> void:
	_cfg = LOOK.rim_of()
	light_color = _cfg.get("color", Color(0.85, 0.9, 1.0))
	light_energy = float(_cfg.get("energy", 0.35))
	light_specular = float(_cfg.get("spec", 8.0))
	light_cull_mask = LOOK.RIM_LAYER
	shadow_enabled = false
	visible = light_energy > 0.0


func _process(_dt: float) -> void:
	_follow()


# The light travels toward the camera (its heading only), tilted down by `tilt` degrees.
func _follow() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return
	var f := -cam.global_transform.basis.z
	var h := Vector3(f.x, 0.0, f.z)
	if h.length() < 0.001:
		h = Vector3(0, 0, -1)   # straight down (top-down view): any heading draws an edge
	h = h.normalized()
	var t := deg_to_rad(float(_cfg.get("tilt", 12.0)))
	var d := -h * cos(t) + Vector3.DOWN * sin(t)
	global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), global_transform.origin)


func _on_added(n: Node) -> void:
	if n is GeometryInstance3D:
		_mark.call_deferred(n)


func _mark_tree(n: Node) -> void:
	if n == null:
		return
	for g in n.find_children("*", "GeometryInstance3D", true, false):
		_mark(g)


# A ship's materials are set right after its mesh enters the scene, so this runs deferred, at the end of the frame.
func _mark(n) -> void:
	if not is_instance_valid(n) or not (n is GeometryInstance3D):
		return
	var g := n as GeometryInstance3D
	if g.layers & LOOK.RIM_LAYER:
		return
	if _is_hull(g):
		g.layers |= LOOK.RIM_LAYER


static func _hull_mat(m: Material) -> bool:
	if m == null:
		return false
	if m.has_meta("look_hull"):
		return true
	if m.has_meta("fx_hull_source"):
		var src = m.get_meta("fx_hull_source")
		return src is Material and (src as Material).has_meta("look_hull")
	return false


static func _is_hull(g: GeometryInstance3D) -> bool:
	if _hull_mat(g.material_override):
		return true
	var mi := g as MeshInstance3D
	if mi == null or mi.mesh == null:
		return false
	for i in mi.get_surface_override_material_count():
		if _hull_mat(mi.get_surface_override_material(i)):
			return true
	return false
