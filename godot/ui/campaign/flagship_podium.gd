extends Control
# C37 A: the live flagship in three-quarter light with the battle's Hollow Sun behind it.
# With no installed hull, keep the KEEL silhouette and the real star. Reduce motion holds the hull still.
const Ship = preload("res://render/ship_view.gd")
const HT = preload("res://render/hull_table.gd")
const Kit = preload("res://ui/theme/orders_kit.gd")
const GS = preload("res://ui/theme/glass_shell.gd")
const World = preload("res://world/world.gd")
const Look = preload("res://render/look.gd")
const CameraRig = preload("res://render/camera_rig.gd")
const TURN_DEG_PER_S := 4.0
const START_YAW := 40.0
const DRIVE_LEVEL := 0.82
var code := ""
var installed := false
var spin := true
var _pivot: Node3D
var _vp: SubViewport
var _camera: Camera3D
var _fit_horizontal := 0.0
var _fit_vertical := 0.0


func setup(C, ship: Dictionary, accent: Color, still := false) -> void:
	# CampaignUI assembles the page off-tree. Wait before using camera or nozzle world transforms.
	if is_node_ready():
		_build(C, ship, accent, still)
	else:
		ready.connect(_build.bind(C, ship, accent, still), CONNECT_ONE_SHOT)


func _build(C, ship: Dictionary, accent: Color, still: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	spin = not still
	var tpl := str(ship["tpl"])
	var fac := str(C.factionOfTpl(tpl))
	var cls := str(C.HULLS[tpl].get("cls", "Frigate"))
	var unit := {"id": ship.get("uid", "podium"), "fac": fac, "cls": cls, "tpl": tpl, "facing": 0}
	var path := Ship.hull_path(unit)
	var model: Resource = load(path) if not path.is_empty() and ResourceLoader.exists(path) else null
	installed = model is PackedScene or model is Mesh
	code = HT.code_for(fac, cls)
	if Ship.manifest().get("ships", {}).has(tpl):
		code = tpl
	var length := HT.length_for(code, cls) * HT.SHIP_K

	var box := SubViewportContainer.new()
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	box.add_child(_vp)
	var world := World.new()
	_vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.86)
	e.ambient_light_energy = 0.32
	e.ambient_light_sky_contribution = 0.0
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.name = "ThreeQuarterKey"
	key.rotation_degrees = Vector3(-36, 42, 0)
	key.light_color = Color(1.0, 0.91, 0.80)
	key.light_energy = 2.6
	world.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, -145, 0)
	rim.light_energy = 0.75
	rim.light_color = Color.WHITE.lerp(accent, 0.42)
	world.add_child(rim)

	_pivot = Node3D.new()
	_pivot.name = "FlagshipTurn"
	world.add_child(_pivot)
	var center := Vector3.ZERO
	var footprint := length * 0.52
	var half_height := length * 0.10
	if installed:
		var view := Ship.new()
		_pivot.add_child(view)
		view.setup(unit, Vector3.ZERO)
		# The podium turns as a whole. Battle idle drift and vent puffs do not run here.
		view.set_process(false)
		_light_engines(view)
		center = view.visual_position()
		footprint = Vector2(length * 0.52, view.half_w).length()
		half_height = view.half_h
	else:
		_show_silhouette(HT.code_for(fac, cls), accent)
	_pivot.rotation_degrees.y = START_YAW

	_camera = Camera3D.new()
	world.add_child(_camera)
	# See more of the deck as well as the flank. The old shallow view gains little
	# from filling the stage horizontally once it must leave room for a full turn.
	var eye := center + length * Vector3(0.0, 1.10, 1.45)
	_camera.look_at_from_position(eye, center - Vector3.UP * length * 0.105)
	_camera.current = true
	# Fit the whole turn once. The camera only reframes on resize, so there's no zoom as the ship rolls past.
	var local_center := _camera.to_local(center)
	# The turning footprint sweeps a circle. Fit its projected tangent at the
	# closest height band, rather than leaving room for a sphere around the hull.
	var camera_depth_axis := _camera.basis.z
	var band_depth := -local_center.z - absf(camera_depth_axis.y) * half_height
	var turn_depth := absf(camera_depth_axis.z) * footprint
	_fit_horizontal = footprint / sqrt(band_depth * band_depth - turn_depth * turn_depth) / 0.94
	_fit_vertical = tan(deg_to_rad(13.0))
	for y in [-half_height, half_height]:
		for z in [-footprint, footprint]:
			var extent := _camera.to_local(center + Vector3(0.0, y, z))
			_fit_vertical = maxf(_fit_vertical, absf(extent.y / extent.z) / 0.94)
	resized.connect(_fit_camera)
	_fit_camera()
	# Frame the hole above and past the ship. Its disc may bleed out of the stage, but not into the refit column.
	var star_center := _camera.to_global(length * Vector3(0.69, 0.93, -8.0))
	world.build_hollow_sun_backdrop(e, star_center, length * 0.52 / 15.0)
	if installed and Look.post_fx_enabled("DOF"):
		# Keep the whole turning hull sharp. The live star is the distant subject of the optional blur.
		var lens := CameraRig.far_dof(-local_center.z, Vector2(footprint, half_height).length())
		lens.dof_blur_far_enabled = true
		_camera.attributes = lens
		if still:
			lens.dof_blur_amount = CameraRig.DOF_AMOUNT
		else:
			create_tween().tween_property(lens, "dof_blur_amount", CameraRig.DOF_AMOUNT, CameraRig.DOF_ENTER_S)
	set_process(installed and spin)


func _fit_camera() -> void:
	if size.x > 0.0 and size.y > 0.0:
		var aspect := size.x / size.y
		_camera.fov = rad_to_deg(2.0 * atan(maxf(_fit_vertical, _fit_horizontal / aspect)))


func _light_engines(view: Ship) -> void:
	# A4 glows sit at the authored engine exits, never on a fin or on an edited hull material.
	# Legacy hulls keep the battle renderer's stern glows.
	view.set_fallback_drive(DRIVE_LEVEL)
	var nozzles := view.hull.find_children("hp_eng*", "Node3D", true, false)
	if nozzles.is_empty() or view.engines.is_empty():
		return
	var template: Sprite3D = view.engines[0]
	for node in nozzles:
		var nozzle := node as Node3D
		var glow := template.duplicate() as Sprite3D
		glow.name = "EngineGlow_" + str(nozzle.name)
		var out := -nozzle.global_basis.z
		var extras: Dictionary = nozzle.get_meta("extras", {})
		var radius := float(extras.get("radius", nozzle.get_meta("radius", 0.0))) * out.length()
		var diameter := clampf(radius * 2.8, view.L * 0.032, view.L * 0.09)
		glow.pixel_size = diameter / float(glow.texture.get_width())
		view.add_child(glow)
		glow.global_position = nozzle.global_position + out.normalized() * diameter * 0.10
	for engine: Sprite3D in view.engines:
		engine.hide()


func _show_silhouette(hull_code: String, accent: Color) -> void:
	var tex := Kit.silhouette(hull_code)
	if tex == null:
		return
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.modulate = Color(accent.lerp(GS.TEXT3, 0.45), 0.6)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tr.anchor_top = 0.30
	tr.anchor_bottom = 0.93
	tr.offset_left = 24
	tr.offset_right = -24


func _process(dt: float) -> void:
	if spin and _pivot != null and is_visible_in_tree():
		_pivot.rotation_degrees.y = wrapf(_pivot.rotation_degrees.y + TURN_DEG_PER_S * dt, -180.0, 180.0)
