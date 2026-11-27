extends Control
# The flagship on its podium (issue 1217 phase 4, Ryan: its own screen with a big live 3D ship). The installed hull renders
# live through the battle renderer, turning slowly under a key light and a rim light in its faction's engine colour, over
# a soft floor glow. Reduce motion holds it still at a three-quarter view. Never a stand-in model: without an installed
# hull it shows the KEEL silhouette (the cloud has no built ships), the same rule as the ledger portrait.
const Ship = preload("res://render/ship_view.gd")
const HT = preload("res://render/hull_table.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const Look := preload("res://render/look.gd")
const CameraRig := preload("res://render/camera_rig.gd")
const Fx := preload("res://fx/fx.gd")
const TURN_DEG_PER_S := 5.0
const START_YAW := -35.0
const GANTRY_YAW := -23.0
const GANTRY_TURN := 6.0
const ORBIT_REST := 2.5
var code := ""
var installed := false
var spin := true
var _pivot: Node3D = null
var _vp: SubViewport = null
var _gantry := false
var _camera: Camera3D
var _bounds := AABB()
var _pitch := 18.0
var _dragging := false
var _rest := 0.0
var _fx: Node3D
var _ship_key := ""
var _damage := {}


func setup(C, ship: Dictionary, accent: Color, still := false, gantry := false) -> void:
	_gantry = gantry
	mouse_filter = Control.MOUSE_FILTER_STOP if gantry else Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	spin = not still
	var hull = C.HULLS[ship["tpl"]]
	var fac = C.factionOfTpl(ship["tpl"]); var cls = str(hull.get("cls", "Frigate"))
	code = HT.code_for(fac, cls)
	var manifest = Ship.manifest()
	if manifest.get("ships", {}).has(ship["tpl"]): code = str(ship["tpl"])
	for kind in ["ships", "hi", "hulls"]:
		if manifest.get(kind, {}).has(code) and ResourceLoader.exists(manifest[kind][code]["res"]):
			var asset = load(manifest[kind][code]["res"])
			installed = asset is Mesh if kind == "hulls" else asset is PackedScene
			if installed: break
	if not installed:
		_add_outline(fac, cls, accent)
		return
	var box = SubViewportContainer.new(); box.stretch = true; box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(box)
	_vp = SubViewport.new(); _vp.own_world_3d = true; _vp.transparent_bg = not gantry; _vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	box.add_child(_vp)
	var world = Node3D.new(); _vp.add_child(world)
	var env = WorldEnvironment.new(); var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("#0c1016") if gantry else Color.TRANSPARENT
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.75, 0.78, 0.86); e.ambient_light_energy = 0.45
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e; world.add_child(env)
	var key = DirectionalLight3D.new(); key.rotation_degrees = Vector3(-42, -35, 0); key.light_energy = 2.4; world.add_child(key)
	var rim = DirectionalLight3D.new(); rim.rotation_degrees = Vector3(-18, 150, 0); rim.light_energy = 1.6; rim.light_color = accent.lerp(Color.WHITE, 0.25)
	world.add_child(rim)
	if gantry:
		e.ambient_light_energy = 0.32
		key.light_color = Color("#ffc58f")
		rim.light_color = Color("#9bc0ef")
	_pivot = Node3D.new(); world.add_child(_pivot)
	var view = Ship.new(); _pivot.add_child(view)
	view.setup({"id": ship.get("uid", "podium"), "fac": fac, "cls": cls, "tpl": ship["tpl"], "facing": 0}, Vector3.ZERO)
	if view.ring != null: view.ring.visible = false
	if gantry and view.hull_source.is_empty():
		installed = false
		remove_child(box)
		box.queue_free()
		_vp = null
		_pivot = null
		_add_outline(fac, cls, accent)
		return
	if gantry:
		mouse_default_cursor_shape = CURSOR_DRAG
		view.calm = true  # The gantry owns movement and holds the ship steady while dragged.
		view.set_process(false)
		_bounds = _mesh_bounds(view)
	_pivot.rotation_degrees.y = GANTRY_YAW if gantry else START_YAW
	var L = float(view.L)
	var camera = Camera3D.new(); world.add_child(camera)
	camera.fov = 30.0; camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.look_at_from_position(Vector3(0, L * 0.55, L * 1.9), Vector3(0, -L * 0.04, 0)); camera.current = true
	if gantry:
		_camera = camera
		_build_gantry(world)
		_frame()
		resized.connect(_frame)
		if ship.has("hp"):
			_install_damage(world, view, ship, float(C.derive(ship)["maxHp"]))
	elif Look.post_fx_enabled("DOF"):
		_podium_lens(camera, L, accent, still)
	set_process(spin or _fx != null)


func _add_outline(fac: String, cls: String, accent: Color) -> void:
	var tex := Kit.silhouette(HT.code_for(fac, cls))
	if tex == null: return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color(accent.lerp(GS.TEXT3, 0.45), 0.6)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.offset_left = 24; tr.offset_right = -24; tr.offset_top = 40; tr.offset_bottom = -40
	add_child(tr)


func _mesh_bounds(view) -> AABB:
	var bounds := AABB()
	var first := true
	for m: MeshInstance3D in view.meshes:
		var xf: Transform3D = view.global_transform.affine_inverse() * m.global_transform
		var box := xf * m.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return AABB(Vector3.ONE * -view.L * 0.5, Vector3.ONE * view.L) if first else bounds


static func framing_distance(bounds: AABB, aspect: float, fov: float, pitch := 18.0) -> float:
	# Fit the yaw envelope, a cylinder around the mesh's horizontal span. Account for
	# the near edge as well as the width and height so the camera does not breathe as it turns.
	var radius := Vector2(bounds.size.x, bounds.size.z).length() * 0.5
	var half_h := bounds.size.y * 0.5
	var sy := sin(deg_to_rad(pitch))
	var cz := cos(deg_to_rad(pitch))
	var slope_y := tan(deg_to_rad(fov) * 0.5) * 0.92
	var slope_x := slope_y * maxf(aspect, 0.1)
	var distance := half_h * sy + radius * Vector2(1.0 / slope_x, cz).length()
	for edge: float in [-1.0, 1.0]:
		distance = maxf(distance, half_h * absf(sy + edge * cz / slope_y) + radius * absf(cz - edge * sy / slope_y))
	return maxf(distance, bounds.get_longest_axis_size() * 0.6)


func _frame() -> void:
	if not is_instance_valid(_camera): return
	var distance := framing_distance(_bounds, size.x / maxf(size.y, 1.0), _camera.fov, _pitch)
	var tilt := deg_to_rad(_pitch)
	_camera.near = distance * 0.01
	_camera.far = distance * 12.0
	_camera.look_at_from_position(_bounds.get_center() + Vector3(0, sin(tilt), cos(tilt)) * distance, _bounds.get_center())


func _build_gantry(world: Node3D) -> void:
	var span := _bounds.get_longest_axis_size()
	var center := _bounds.get_center()
	var floor_y := _bounds.position.y - span * 0.21
	var ceiling := _bounds.end.y + span * 0.67
	var deck := _finish(Color("#1f2429"), 0.55)
	var steel := _finish(Color("#292e33"), 0.62)
	var rail := _finish(Color("#515258"), 0.44)
	var service := _finish(Color("#835434"), 0.26)
	_slab(world, Vector3(center.x, floor_y, center.z), Vector3(span * 18.0, span * 0.05, span * 16.0), deck)
	for i in range(-5, 6):
		var z := center.z + i * span * 0.34
		_slab(world, Vector3(center.x, floor_y + span * 0.027, z), Vector3(span * 9.0, span * 0.004, span * 0.013), rail)
	for side in [-1.0, 1.0]:
		var x: float = center.x + span * 1.24 * side
		_slab(world, Vector3(x, floor_y + span * 0.028, center.z), Vector3(span * 0.013, span * 0.004, span * 8.0), service)
		for i in range(5):
			var z := center.z - span * (0.58 + i * 0.7)
			_slab(world, Vector3(x, (ceiling + floor_y) * 0.5, z), Vector3(span * 0.09, ceiling - floor_y, span * 0.09), steel)
			_slab(world, Vector3(x * 0.55 + center.x * 0.45, ceiling - span * 0.05, z), Vector3(span * 0.42, span * 0.018, span * 0.065), rail)
		_slab(world, Vector3(x, ceiling, center.z - span), Vector3(span * 0.14, span * 0.10, span * 6.0), steel)
	for i in range(5):
		var z := center.z - span * (0.58 + i * 0.7)
		_slab(world, Vector3(center.x, ceiling, z), Vector3(span * 2.6, span * 0.10, span * 0.09), steel)
	var wash := OmniLight3D.new()
	wash.position = Vector3(center.x - span * 0.4, floor_y + span * 0.24, center.z - span * 0.72)
	wash.light_color = Color("#db9462")
	wash.light_energy = 1.4
	wash.omni_range = span * 2.2
	world.add_child(wash)


static func _finish(tint: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = metal
	material.roughness = 0.74
	return material


static func _slab(world: Node3D, pos: Vector3, dims: Vector3, material: Material) -> void:
	var box := BoxMesh.new()
	box.size = dims
	box.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.position = pos
	world.add_child(mesh)


func _install_damage(world: Node3D, view, ship: Dictionary, full: float) -> void:
	if float(ship["hp"]) >= full: return
	_ship_key = str(ship["uid"])
	_damage = damage_snapshot(ship, full)
	_fx = Fx.new()
	_fx.manual = true
	_fx.defer_initial_cuts = true
	world.add_child(_fx)
	_fx.setup({"quality": "high", "reduce_flashing": true})
	_fx.add_ship(_ship_key, view, {"faction": view.fac, "cls": view.u["cls"], "shielded": false, "meshes": view.meshes})
	_fx.sync_ship(_ship_key, _damage)


static func damage_snapshot(ship: Dictionary, full: float) -> Dictionary:
	# Older saves and non-combat hull loss have no section history. Show real hull wear without cutting invented holes.
	var sections := {"prow": {}, "mid": {}, "eng": {}}
	var saved = ship.get("yard_sections")
	if saved is Dictionary:
		for key in sections:
			var part = saved.get(key)
			if part is Dictionary and part.get("broken") == true:
				sections[key] = part
	return {"hp": ship["hp"], "maxHp": full, "sec": sections}


func preview_repair(projected: Dictionary = {}) -> void:
	if is_instance_valid(_fx):
		var damage := _damage if projected.is_empty() else damage_snapshot(projected, _damage["maxHp"])
		_fx.sync_ship(_ship_key, damage)


func _gui_input(event: InputEvent) -> void:
	if not _gantry or not installed: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		_rest = ORBIT_REST
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_pivot.rotation_degrees.y -= event.relative.x * 0.35
		_pitch = clampf(_pitch + event.relative.y * 0.27, 4.0, 44.0)
		_frame()
		accept_event()


func _podium_lens(camera: Camera3D, length: float, accent: Color, still: bool) -> void:
	var lens := CameraRig.far_dof(camera.position.length(), length * 1.15)
	lens.dof_blur_far_enabled = true
	camera.attributes = lens
	# The podium is transparent over a 2D glow. Small distant lights give its own 3D lens something to blur.
	var lamp := SphereMesh.new()
	lamp.radius = length * 0.019
	lamp.height = lamp.radius * 2.0
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.23, 0.25, 0.28).lerp(accent, 0.22)
	for offset in [Vector2(-0.21, 0.07), Vector2(-0.17, 0.10), Vector2(0.15, -0.10), Vector2(0.20, -0.08)]:
		var point := MeshInstance3D.new()
		point.mesh = lamp
		point.material_override = material
		point.position = 6.0 * length * Vector3(offset.x, offset.y, -1.0)
		camera.add_child(point)
	if still:
		lens.dof_blur_amount = CameraRig.DOF_AMOUNT
	else:
		create_tween().tween_property(lens, "dof_blur_amount", CameraRig.DOF_AMOUNT, CameraRig.DOF_ENTER_S)


func _process(dt: float) -> void:
	if not is_visible_in_tree(): return
	if _dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_dragging = false
		_rest = ORBIT_REST
	if _fx != null: _fx.step(dt)
	_rest = maxf(0.0, _rest - dt)
	if _pivot != null and spin and not _dragging and _rest == 0.0:
		_pivot.rotation_degrees.y = fposmod(_pivot.rotation_degrees.y + (GANTRY_TURN if _gantry else TURN_DEG_PER_S) * dt, 360.0)
