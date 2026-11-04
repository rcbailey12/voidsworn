extends SceneTree
# Close, reverse, battle-camera and motion evidence, using the live renderer.
const SV := preload("res://render/ship_view.gd")
const FX := preload("res://fx/fx.gd")
const CASES := [["voidsworn", "Sunward Crusade", "bomber", "Carrier"], ["hegemony", "Hegemony Navy", "fighter", "Battleship"], ["corsair", "Ashfall Hullbreakers", "bomber", "Carrier"], ["chorus", "The Chorus", "spore", "Carrier"], ["ithar", "The Glasswrights", "fighter", "Carrier"], ["deathless", "Eclipse", "", "Tomb-ark"]]
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var fx
var out := ""
var title: Label
var detail: Label

func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _run() -> void:
	out = OS.get_environment("SQUADRON_OUT")
	if out.is_empty():
		push_error("Set SQUADRON_OUT")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	vp = SubViewport.new()
	vp.size = Vector2i(2560, 1440)
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.009, 0.015, 0.029)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.68, 0.85)
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	for angles in [Vector3(-45, -25, 0), Vector3(-15, 145, 0)]:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = angles
		sun.light_energy = 2.5 if angles.y < 0 else 1.2
		world.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	world.add_child(cam)
	var overlay := CanvasLayer.new()
	vp.add_child(overlay)
	title = Label.new()
	title.position = Vector2(64, 44)
	title.add_theme_font_size_override("font_size", 44)
	overlay.add_child(title)
	detail = Label.new()
	detail.position = Vector2(66, 104)
	detail.add_theme_font_size_override("font_size", 26)
	detail.modulate = Color(0.65, 0.75, 0.88)
	overlay.add_child(detail)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "low", "shake": 0.0})
	for c in CASES: await _capture(c)
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	print("SQUADRON_CAPTURE_COMPLETE " + out)
	quit()

func _view(fac: String, cls: String, kind: String, at: Vector3):
	var sv := SV.new()
	world.add_child(sv)
	sv.setup({"id": fac + cls + kind, "fac": fac, "cls": cls, "tpl": kind, "facing": 0}, at)
	sv.set_process(false)
	if cls == "Squadron": sv.hull.set_process(false)
	return sv

func _still(name: String) -> void:
	for frame in 3: await RenderingServer.frame_post_draw
	var err := vp.get_texture().get_image().save_png(out.path_join(name + ".png"))
	if err != OK:
		push_error("Capture failed: " + name)
		quit(2)

func _capture(c: Array) -> void:
	var fac: String = c[0]
	title.text = c[1]
	var carrier = _view(fac, c[3], "", Vector3(24, 0, 5))
	if not carrier.a4:
		push_error("Real carrier asset missing: " + fac)
		quit(3)
		return
	fx.add_ship(fac + "_carrier", carrier, {"faction": fac, "cls": c[3], "meshes": carrier.meshes, "shielded": false})
	fx._later.clear()
	fx.step(0.1)
	if fac == "deathless":
		detail.text = "No squadron craft: FACTIONS.sq = null; no Eclipse hull has a hangar"
		for zoom in ["close", "battle"]:
			var target := Vector3(24, 0, 5)
			cam.look_at_from_position(target + Vector3(-0.45, 0.7, 0.6).normalized() * (85.0 if zoom == "close" else 170.0), target)
			await _still(fac + "_" + zoom)
		fx.remove_ship(fac + "_carrier")
		carrier.queue_free()
		await process_frame
		return
	var wing = _view(fac, "Squadron", c[2], Vector3(-7, 2, -6))
	fx.add_ship(fac + "_wing", wing, {"faction": fac, "squadron": true, "meshes": wing.meshes})
	fx._later.clear()
	var lead := Vector3(-9, 2, -6)
	for i in 90: wing.hull.step(1.0 / 60.0)
	carrier.visible = false
	for angle in ["close", "reverse"]:
		detail.text = "%s | %d craft | %s view | faction geometry and stern trails" % [c[2], wing.hull.craft.size(), angle]
		var dir := Vector3(0.4, 0.85, 0.65) if angle == "close" else Vector3(-0.55, 0.3, -0.8)
		cam.look_at_from_position(lead + dir.normalized() * 26.0, lead)
		await _still(fac + "_" + angle)
	carrier.visible = true
	detail.text = "Battle camera | 170 units | unchanged craft scale | launch hull for context"
	cam.look_at_from_position(Vector3(5, 0, 0) + Vector3(0.0, 0.557, 0.831) * 170.0, Vector3(5, 0, 0))
	await _still(fac + "_battle")
	# Both adaptive roles get a close capture for the factions that can use them.
	if fac in ["voidsworn", "hegemony", "ithar"]:
		var alt: String = "fighter" if c[2] == "bomber" else "bomber"
		var extra = _view(fac, "Squadron", alt, wing.position)
		wing.visible = false
		carrier.visible = false
		detail.text = alt + " | alternate rules template | same faction fittings"
		cam.look_at_from_position(lead + Vector3(0.4, 0.85, 0.65).normalized() * 26.0, lead)
		await _still(fac + "_" + alt)
		extra.queue_free()
		wing.visible = true
	carrier.visible = false
	detail.text = "Flight sequence | banking, weaving and separate stern trails | 12 fps"
	cam.look_at_from_position(lead + Vector3(0.4, 0.85, 0.65).normalized() * 26.0, lead)
	for frame in 36:
		wing.hull.step(1.0 / 12.0)
		await _still("%s_motion_%02d" % [fac, frame])
	# Capture the real launch and weapon entry points as well as parked wings.
	carrier.visible = true
	detail.text = c[2] + " | actual carrier launch event | faction craft leaving the bay"
	cam.look_at_from_position(Vector3(5, 0, 0) + Vector3(0, 0.557, 0.831) * 170.0, Vector3(5, 0, 0))
	fx.launch(fac + "_carrier", fac + "_wing")
	fx.step(0.65)
	await _still(fac + "_launch")
	fx.step(3.0)
	wing.visible = false
	carrier.visible = false
	detail.text = c[2] + " | launch / attack effect model at battle distance"
	cam.look_at_from_position(Vector3(0, 55, 80), Vector3.ZERO)
	var weapon: String = "sporeb" if fac == "chorus" else ("bombs" if c[2] == "bomber" else "guns")
	fx.volley_at(Vector3(-25, 0, 0), "sq", Vector3(25, 0, 0), {"faction": fac, "weapon_id": weapon, "shots": [false]})
	fx.step(0.25)
	await _still(fac + "_pass")
	fx.step(2.0)
	fx.remove_ship(fac + "_carrier")
	fx.remove_ship(fac + "_wing")
	carrier.queue_free()
	wing.queue_free()
	await process_frame
