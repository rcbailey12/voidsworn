extends SceneTree
# Issue 1466 (PC, windowed): a frigate crossing a dead frigate's settled plates at the c60 battle camera, the picture
# for Ryan. Box stand-ins (no ship files needed). A box frigate dies ("blast"); the effects run until every plate is
# at rest (the physics space then sleeps, issue 1279); a second box frigate drives through the nearest plate at
# 12 units a second. Before the fix the plates stay put and the hull passes through them; after it they are shoved.
#   -- <out folder> <arm label>
# Writes <out>/frames/f_###.jpg (every second frame, 1280x720), <out>/sheet.png (six frames cropped to the middle
# half, 1278x560: 3 by 2 with a band below for the revision stamp) and <out>/crossing.json (plates near the path and
# how many moved; written last, only when every picture saved). Exit 1 if the folder is not fresh, any frame, sheet or
# stamp save fails, no plate settled near the path, or the scene drew a placeholder.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const PG := preload("res://render/placeholder_guard.gd")
const SPEED := 12.0
const RUN := 24.0   # units before and after the target plate

var out := ""
var arm := ""
var label: Label


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0] if a.size() > 0 else "user://wreck_crossing"
	arm = a[1] if a.size() > 1 else "?"
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _box_ship(fx, world: Node3D, id: String, at: Vector3) -> Node3D:
	var ship := Node3D.new()
	world.add_child(ship)
	ship.position = at
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(8, 2.5, 3)
	bm.subdivide_width = 16
	bm.subdivide_height = 4
	bm.subdivide_depth = 6
	mi.mesh = bm
	ship.add_child(mi)
	fx.add_ship(id, ship, {"faction": "corsair", "cls": "Frigate", "size": 0.55, "meshes": [mi]})
	return ship


func _plates(fx) -> Array:
	var out_p: Array = []
	for b in fx.dstate.get("debris", []):
		if is_instance_valid(b) and (b as Node3D).visible and (b as Node3D).global_position.y > -100.0: out_p.append(b)
	return out_p


func _frames(fx, n: int) -> void:
	for i in n:
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw


func _run() -> void:
	# a fresh output folder only (Artoo on PR 1476): stale frames or a stale sheet must never pass as this run's
	for old in ["frames", "sheet.png", "crossing.json"]:
		if FileAccess.file_exists(out.path_join(old)) or DirAccess.dir_exists_absolute(out.path_join(old)):
			printerr("WRECK_CROSSING output folder not fresh: %s exists" % out.path_join(old))
			quit(1)
			return
	DirAccess.make_dir_recursive_absolute(out.path_join("frames"))
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.5
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -30, 0)
	world.add_child(light)
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	# c60: the battle camera's slant (y:z = 0.557:0.83) at 60 units from what it looks at
	var slant := Vector3(0, 0.557, 0.83).normalized() * 60.0
	cam.look_at_from_position(slant, Vector3.ZERO)
	cam.current = true
	var hud := CanvasLayer.new()
	vp.add_child(hud)
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_font_size_override("font_size", 22)
	hud.add_child(label)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0})
	# a cloud preview on the Compatibility renderer (no Vulkan there) runs the effects at low, with no physics; the PC never
	# sets this. WX_PREVIEW_PHYSICS=1 turns the physics back on so the preview shows the same crossing.
	if OS.get_environment("WX_PREVIEW_PHYSICS") == "1": fx.dstate["physics_on"] = true
	_box_ship(fx, world, "victim", Vector3.ZERO)
	var crosser := _box_ship(fx, world, "crosser", Vector3(-60, 0, 0))
	await fx.warmup(cam)
	if PG.stop_if_any(): return
	label.text = "WX1466 %s c60 | box frigates | plates settling" % arm
	await _frames(fx, 300)
	fx.death("victim", "blast")
	# the break comes when its cut is ready (a worker thread); then every plate comes to rest (DEBRIS_REST_S), plus a margin
	var plates: Array = []
	for i in 60 * 30:
		await _frames(fx, 1)
		plates = _plates(fx)
		if not plates.is_empty(): break
	for i in 60 * 15:
		await _frames(fx, 1)
		if DEATH.debris_awake(fx) == 0: break
	await _frames(fx, 90)
	plates = _plates(fx)
	var resting := DEATH.debris_awake(fx) == 0
	var asleep := not bool(fx._phys_awake)
	if plates.is_empty():
		printerr("WRECK_CROSSING no plates on the board (physics %s, pool %d, wrecks %d, now %.1f)" % [fx.dstate.get("physics_on"), fx.dstate.get("debris", []).size(), fx.dstate.get("wrecks", []).size(), fx.now])
		quit(1)
		return
	var target: Node3D = plates[0]
	for b in plates:
		if (b as Node3D).global_position.length() < target.global_position.length(): target = b
	var t: Vector3 = target.global_position
	t.y = 0.0
	cam.look_at_from_position(t + slant, t)
	var start := Vector3(t.x - RUN, 0, t.z)
	crosser.position = start
	var before := {}
	for b in plates: before[b] = (b as Node3D).global_position
	await _frames(fx, 30)
	var n := int(2.0 * RUN / SPEED * 60.0)
	var saved: Array = []
	var save_errors: Array = []
	for i in n + 60:
		if i < n: crosser.position = start + Vector3(SPEED * (i + 1) / 60.0, 0, 0)
		label.text = "WX1466 %s c60 | box frigates | crossing settled plates | t %.2f s" % [arm, i / 60.0]
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw
		if i % 2 == 0:
			var p := out.path_join("frames/f_%03d.jpg" % (i / 2))
			var err: Error = preload("res://tools/picture_provenance.gd").save_jpg(vp.get_texture().get_image(), p, 0.88, preload("res://tools/picture_provenance.gd").capture_stage())
			if err != OK or not FileAccess.file_exists(p): save_errors.append("%s: %s" % [p.get_file(), error_string(err)])
			else: saved.append(p)
	# the plates the hull's path reached (within 4 units of its centre line) and how far each was pushed
	var near := 0
	var moved := 0
	var most := 0.0
	for b in plates:
		var p0: Vector3 = before[b]
		if absf(p0.z - t.z) > 4.0 or p0.x < start.x or p0.x > start.x + 2.0 * RUN: continue
		near += 1
		var d := (b as Node3D).global_position.distance_to(p0)
		most = maxf(most, d)
		if d > 0.5: moved += 1
	# six frames across the crossing, 3 by 2 at 426x240
	var sheet := Image.create(1278, 560, false, Image.FORMAT_RGB8)
	for k in 6:
		if saved.is_empty(): break
		var idx := int(float(k) / 5.0 * float(saved.size() - 1))
		var im := Image.load_from_file(ProjectSettings.globalize_path(saved[idx]))
		if im == null or im.is_empty():
			save_errors.append("sheet frame %s did not load" % saved[idx].get_file())
			continue
		im.convert(Image.FORMAT_RGB8)
		# the middle half of the frame at 2x less shrink, so the plates (a few pixels at c60) still read on the sheet
		im = im.get_region(Rect2i(320, 180, 640, 360))
		im.resize(426, 240, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(im, Rect2i(0, 0, 426, 240), Vector2i((k % 3) * 426, (k / 3) * 240))
	var sheet_err: Error = preload("res://tools/picture_provenance.gd").save_png(sheet, out.path_join("sheet.png"), preload("res://tools/picture_provenance.gd").capture_stage())
	if sheet_err != OK or not FileAccess.file_exists(out.path_join("sheet.png")): save_errors.append("sheet.png: %s" % error_string(sheet_err))
	if saved.size() != (n + 60 + 1) / 2: save_errors.append("frames saved %d of %d" % [saved.size(), (n + 60 + 1) / 2])
	# written last, so crossing.json exists only when every picture did; moved may be 0 (the before arm reports that)
	var res := {"arm": arm, "plates": plates.size(), "resting_before": resting, "space_asleep_before": asleep,
		"near_path": near, "moved": moved, "most_moved": snappedf(most, 0.01), "frames": saved.size(), "save_errors": save_errors}
	print("WRECK_CROSSING %s" % JSON.stringify(res))
	fx.release()
	if not save_errors.is_empty():
		printerr("WRECK_CROSSING capture failed: %s" % ", ".join(save_errors))
		PG.finish(1)
		return
	var f := FileAccess.open(out.path_join("crossing.json"), FileAccess.WRITE)
	if f == null:
		printerr("WRECK_CROSSING could not write crossing.json")
		PG.finish(1)
		return
	f.store_string(JSON.stringify(res, "  "))
	f.close()
	PG.finish(0 if near > 0 else 1)
