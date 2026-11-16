extends SubViewportContainer
# A portrait of the installed game hull, through the same renderer as battle.
const Ship = preload("res://render/ship_view.gd")
const HT = preload("res://render/hull_table.gd")
var code := ""
var installed := false

func setup(C, ship: Dictionary) -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	var hull = C.HULLS[ship["tpl"]]
	var fac = str(hull.get("fac", "voidsworn"))
	var cls = str(hull.get("cls", "Frigate"))
	code = HT.code_for(fac, cls)
	var manifest = Ship.manifest()
	for kind in ["ships", "hi", "hulls"]:
		if manifest.get(kind, {}).has(code) and ResourceLoader.exists(manifest[kind][code]["res"]): installed = true
	if not installed: return # Never substitute a block or concept art.
	var vp = SubViewport.new(); vp.size = Vector2i(640, 300); vp.own_world_3d = true
	vp.transparent_bg = true; vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(vp)
	var world = Node3D.new(); vp.add_child(world)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color.TRANSPARENT
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.65
	env.environment = e; world.add_child(env)
	var light = DirectionalLight3D.new(); light.rotation_degrees = Vector3(-48, -30, 0); light.light_energy = 2.5; world.add_child(light)
	var view = Ship.new(); world.add_child(view)
	view.setup({"id": ship.get("uid", "ledger"), "fac": fac, "cls": cls, "facing": 0}, Vector3.ZERO)
	if view.ring != null: view.ring.visible = false
	var camera = Camera3D.new(); world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.keep_aspect = Camera3D.KEEP_WIDTH; camera.size = view.L * 1.1
	camera.look_at_from_position(Vector3(view.L * 0.35, view.L * 0.9, view.L * 0.9), Vector3.ZERO); camera.current = true
	# A still camera; the installed model renders live while the portrait is visible.
