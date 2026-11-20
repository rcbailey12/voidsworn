extends Control
# The flagship on its podium (issue 1217 phase 4, Ryan: its own screen with a big live 3D ship). The installed hull renders
# live through the battle renderer, turning slowly under a key light and a rim light in its faction's engine colour, over
# a soft floor glow. Reduce motion holds it still at a three-quarter view. Never a stand-in model: without an installed
# hull it shows the KEEL silhouette (the cloud has no built ships), the same rule as the ledger portrait.
const Ship = preload("res://render/ship_view.gd")
const HT = preload("res://render/hull_table.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const TURN_DEG_PER_S := 5.0
const START_YAW := -35.0
var code := ""
var installed := false
var spin := true
var _pivot: Node3D = null
var _vp: SubViewport = null


func setup(C, ship: Dictionary, accent: Color, still := false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	spin = not still
	var hull = C.HULLS[ship["tpl"]]
	var fac = C.factionOfTpl(ship["tpl"]); var cls = str(hull.get("cls", "Frigate"))
	code = HT.code_for(fac, cls)
	var manifest = Ship.manifest()
	if manifest.get("ships", {}).has(ship["tpl"]): code = str(ship["tpl"])
	for kind in ["ships", "hi", "hulls"]:
		if manifest.get(kind, {}).has(code) and ResourceLoader.exists(manifest[kind][code]["res"]):
			installed = load(manifest[kind][code]["res"]) != null   # existence alone is not enough (fleet_portrait.gd)
			if installed: break
	if not installed:
		var tex = Kit.silhouette(HT.code_for(fac, cls))
		if tex != null:
			var tr = TextureRect.new(); tr.texture = tex; tr.set_anchors_preset(Control.PRESET_FULL_RECT)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.modulate = Color(accent.lerp(GS.TEXT3, 0.45), 0.6); tr.mouse_filter = Control.MOUSE_FILTER_IGNORE   # a stand-in outline, quieter than a ship
			tr.offset_left = 24; tr.offset_right = -24; tr.offset_top = 40; tr.offset_bottom = -40
			add_child(tr)
		return
	var box = SubViewportContainer.new(); box.stretch = true; box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(box)
	_vp = SubViewport.new(); _vp.own_world_3d = true; _vp.transparent_bg = true; _vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	box.add_child(_vp)
	var world = Node3D.new(); _vp.add_child(world)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color.TRANSPARENT
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.78, 0.86); e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e; world.add_child(env)
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-42, -35, 0); key.light_energy = 2.4; world.add_child(key)
	var rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-18, 150, 0); rim.light_energy = 1.6; rim.light_color = accent.lerp(Color.WHITE, 0.25)
	world.add_child(rim)
	_pivot = Node3D.new(); world.add_child(_pivot)
	var view = Ship.new(); _pivot.add_child(view)
	view.setup({"id": ship.get("uid", "podium"), "fac": fac, "cls": cls, "tpl": ship["tpl"], "facing": 0}, Vector3.ZERO)
	if view.ring != null: view.ring.visible = false
	_pivot.rotation_degrees.y = START_YAW
	var L = float(view.L)
	var camera = Camera3D.new(); world.add_child(camera)
	camera.fov = 30.0; camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.look_at_from_position(Vector3(0, L * 0.55, L * 1.9), Vector3(0, -L * 0.04, 0)); camera.current = true
	set_process(spin)


func _process(dt: float) -> void:
	if _pivot != null and spin and is_visible_in_tree(): _pivot.rotation_degrees.y += TURN_DEG_PER_S * dt
