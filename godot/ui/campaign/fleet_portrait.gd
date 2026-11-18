extends RefCounted
# One still render per template, shared by the manifest strips and the workspace.
const Ship = preload("res://render/ship_view.gd")
const HT = preload("res://render/hull_table.gd")

static func make(parent: Node, C, ship: Dictionary, pixels: Vector2i) -> Dictionary:
	var hull = C.HULLS[ship["tpl"]]
	var fac = C.factionOfTpl(ship["tpl"]); var cls = str(hull["cls"])
	var code = HT.code_for(fac, cls); var manifest = Ship.manifest()
	if manifest.get("ships", {}).has(ship["tpl"]): code = str(ship["tpl"])
	var installed: bool = cls == "Squadron"
	for kind in ["ships", "hi", "hulls"]:
		if manifest.get(kind, {}).has(code) and ResourceLoader.exists(manifest[kind][code]["res"]):
			# Existence alone is not enough: missing texture dependencies can make a scene unloadable.
			installed = load(manifest[kind][code]["res"]) != null
			if installed: break
	if not installed: return {"code": code, "installed": false, "texture": null}
	var vp = SubViewport.new(); vp.size = pixels; vp.own_world_3d = true
	vp.transparent_bg = true; vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(vp)
	var world = Node3D.new(); vp.add_child(world)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color.TRANSPARENT
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.65
	env.environment = e; world.add_child(env)
	var light = DirectionalLight3D.new(); light.rotation_degrees = Vector3(-48, -30, 0); light.light_energy = 2.5; world.add_child(light)
	var view = Ship.new(); world.add_child(view)
	view.setup({"id": ship["uid"], "fac": fac, "cls": cls, "tpl": ship["tpl"], "facing": 0}, Vector3.ZERO)
	if view.ring != null: view.ring.visible = false
	var camera = Camera3D.new(); world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.keep_aspect = Camera3D.KEEP_WIDTH; camera.size = view.L * 1.15
	camera.look_at_from_position(Vector3(view.L * 0.35, view.L * 0.9, view.L * 0.9), Vector3.ZERO); camera.current = true
	return {"code": code, "installed": true, "texture": vp.get_texture(), "viewport": vp}
