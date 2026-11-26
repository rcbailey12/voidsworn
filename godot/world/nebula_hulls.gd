extends Node
# R82: the volume shades the sky, never a hull. Cover intact, damaged and detached hulls,
# including ships added after battle warmup. No assets or saved resources are rewritten.
const RIM := preload("res://render/look_rim.gd")
const MESH_WATCH := preload("res://render/mesh_watch.gd")
const HULL := preload("res://fx/fx_hull.gd")

var _fog_variants: Dictionary[Shader, Shader] = {}


func _ready() -> void:
	# issue 1204: the one shared new-mesh watcher calls _protect at the end of the frame a mesh enters (the game
	# assigns materials right after adding it) and again when a hull material is set later (MeshWatch.touch)
	MESH_WATCH.listen(get_tree(), _protect)
	for node in get_parent().find_children("*", "GeometryInstance3D", true, false):
		_protect(node)


func _protect(node) -> void:
	if not is_instance_valid(node) or not get_parent().is_ancestor_of(node): return
	if not RIM._is_hull(node): return
	_material(node.material_override)
	_material(node.material_overlay)
	if node is MeshInstance3D and node.mesh != null:
		for surface in node.mesh.get_surface_count():
			_material(node.get_active_material(surface))


func _material(mat: Material) -> void:
	if mat == null: return
	if mat is BaseMaterial3D:
		if not mat.disable_fog:
			mat.disable_fog = true
	elif mat is ShaderMaterial and mat.shader != null:
		# Fallback for custom hulls and overlays. Generated damage shaders take
		# the mode from the source material when they are constructed.
		var source: Shader = mat.shader
		if not source.code.contains("fog_disabled") and source.code.contains("shader_type spatial;"):
			if not _fog_variants.has(source):
				var variant := source.duplicate() as Shader
				variant.code = source.code.replace("shader_type spatial;", "shader_type spatial;\nrender_mode fog_disabled;")
				_fog_variants[source] = variant
			mat.shader = _fog_variants[source]
	if mat.next_pass != null: _material(mat.next_pass)
