extends SceneTree
# Issue 1685 (R411, R407): frame cost of the faction idle motions at 20 real hulls, flag off against flag on, and the
# labelled per-faction sheets for Ryan's Pick Sheet. Needs a window and the built ship files, so the Board queues it solo:
#   set PC_GPU_MODE=solo, IDLE_OUT=<scratch folder>, then tools\pc\tmo.bat 900 <godot.exe> --path godot --script res://fx/test/idle_motion_probe.gd
# IDLE_MODE=fleet (default): four rounds off, on, off, on (alternating so a warm-up or drift cannot favour one side); each
#   round 90 warm-up frames, then 240 timed frames. Writes fleet.json (avg_ms, p99_ms, fx_cpu_p99_ms per round, the
#   mean cost of on over off, the draw call and sprite counts) and a fleet still per mode.
# IDLE_MODE=sheets: one 2x2 sheet per faction (four frames a second apart, close on the hull, the motion's name and the
#   faction's display name on it), saved with a .provenance.json sidecar. Each frame is 640x360, so a sheet is 1280x720.
# The flag is read when a ship is added, so this script flips VS_IDLE_MOTION between rounds. Output stays outside the checkout.
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const PG := preload("res://render/placeholder_guard.gd")
const IDLE := preload("res://fx/fx_idle.gd")
const PP := preload("res://tools/picture_provenance.gd")
const FACS := ["hegemony", "voidsworn", "corsair", "ithar", "deathless", "chorus"]
const SHOW := {"hegemony": "Meridian Directorate (Navy)", "voidsworn": "Sunward Crusade", "corsair": "Ashfall Hullbreakers",
	"ithar": "Glasswrights", "deathless": "Eclipse", "chorus": "Chorus"}
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var fx
var out := ""


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	out = OS.get_environment("IDLE_OUT")
	if out == "":
		push_error("Set IDLE_OUT to a scratch folder")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	seed(1685)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	vp = SubViewport.new()
	var sheets := OS.get_environment("IDLE_MODE") == "sheets"
	vp.size = Vector2i(640, 360) if sheets else Vector2i(3840, 2160)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.03, 0.045)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.7)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var light := DirectionalLight3D.new()
	light.light_energy = 2.2
	light.rotation_degrees = Vector3(-55, -30, 0)
	world.add_child(light)
	cam = Camera3D.new()
	cam.fov = 45.0
	cam.current = true
	world.add_child(cam)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "shake": 0.0, "seed": 1685})
	if sheets:
		await _sheets()
	else:
		await _fleet()
	OS.set_environment("VS_IDLE_MOTION", "")
	fx.release()
	world.queue_free()
	await process_frame
	SV.clear_static()
	FX.clear_static()
	PG.finish(0)


func _ship(sid: String, fac: String, cls: String, size: float, pos: Vector3):
	var sv := SV.new()
	world.add_child(sv)
	sv.setup({"id": sid, "fac": fac, "cls": cls, "facing": 0}, pos)
	if not sv.a4:
		push_error("Real A4 hull missing: " + sid)
		quit(2)
	fx.add_ship(sid, sv, {"faction": fac, "cls": cls, "size": size, "meshes": sv.meshes, "shielded": false})
	fx._later.clear()
	return fx.ship(sid)


func _clear(ships: Array) -> void:
	for s in ships:
		fx.remove_ship(s.id)
		s.root.queue_free()


func _round(on: bool, tag: String) -> Dictionary:
	OS.set_environment("VS_IDLE_MOTION", "1" if on else "0")
	var ships: Array = []
	for i in 20:
		var fac: String = FACS[i % FACS.size()]
		var cls := "Frigate" if i < 10 else ("Cruiser" if i < 16 else "Carrier")
		ships.append(_ship("%s_%d" % [tag, i], fac, cls, 0.55 if i < 10 else (0.8 if i < 16 else 1.0), Vector3((i % 5 - 2) * 29, 0, (i / 5 - 1.5) * 24)))
	cam.look_at_from_position(Vector3(0, 115, 125), Vector3.ZERO)
	for i in 90:
		fx.step(1.0 / 60.0)
		await RenderingServer.frame_post_draw
	fx.prof_take()
	var times: Array = []
	var cpu: Array = []
	var prev := Time.get_ticks_usec()
	for i in 240:
		var t := Time.get_ticks_usec()
		fx.step(1.0 / 60.0)
		cpu.append((Time.get_ticks_usec() - t) / 1000.0)
		await RenderingServer.frame_post_draw
		var stamp := Time.get_ticks_usec()
		times.append((stamp - prev) / 1000.0)
		prev = stamp
	var total := 0.0
	for t in times:
		total += t
	times.sort()
	cpu.sort()
	var built := 0
	var sprites := 0
	for s in ships:
		if not s._idle.is_empty():
			built += 1
			sprites += (s._idle["rows"] as Array).size()
	var row := {"idle": on, "avg_ms": total / times.size(), "p99_ms": times[237], "fx_cpu_p99_ms": cpu[237],
		"ships_with_motion": built, "sprites": sprites, "prof": fx.prof_take()}
	print("IDLE_FLEET %s %s" % [tag, JSON.stringify(row)])
	if PG.stop_if_any():
		return row
	for i in 4:
		await RenderingServer.frame_post_draw
	load("res://tools/picture_provenance.gd").save_png(vp.get_texture().get_image(), out.path_join("fleet_%s.png" % tag), PP.capture_stage())
	_clear(ships)
	await process_frame
	return row


func _fleet() -> void:
	var rounds: Array = []
	for r in [[false, "off1"], [true, "on1"], [false, "off2"], [true, "on2"]]:
		rounds.append(await _round(r[0], r[1]))
	var off_avg := (float(rounds[0]["avg_ms"]) + float(rounds[2]["avg_ms"])) / 2.0
	var on_avg := (float(rounds[1]["avg_ms"]) + float(rounds[3]["avg_ms"])) / 2.0
	var res := {"rounds": rounds, "off_avg_ms": off_avg, "on_avg_ms": on_avg, "cost_ms": on_avg - off_avg,
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name()}
	print("IDLE_COST on-off = %.4f ms per frame (off %.3f, on %.3f)" % [on_avg - off_avg, off_avg, on_avg])
	FileAccess.open(out.path_join("fleet.json"), FileAccess.WRITE).store_string(JSON.stringify(res, "\t"))


func _sheets() -> void:
	OS.set_environment("VS_IDLE_MOTION", "1")
	var only := OS.get_environment("IDLE_FACTIONS")
	for fac in FACS:
		if only != "" and not fac in only.split(","):
			continue
		var s = _ship("sheet_" + fac, fac, "Cruiser", 0.8, Vector3.ZERO)
		var m: Dictionary = IDLE.motion_of(fac)
		var label := Label.new()
		label.text = "%s: %s (%s)" % [SHOW[fac], m["label"], m["name"]]
		label.add_theme_font_size_override("font_size", 16)
		label.position = Vector2(10, 8)
		vp.add_child(label)
		var sheet := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		var center: Vector3 = s.to_world(s.hull.c)
		var dist: float = s.hull.L * 1.3
		cam.look_at_from_position(center + Vector3(0.25, 0.8, 0.6).normalized() * dist, center)
		fx.step(0.5)
		for k in 4:
			# four frames a second apart: the first at the start of the motion, so the sheet shows it swelling and fading
			label.text = "%s: %s (%s)  t = %d s" % [SHOW[fac], m["label"], m["name"], k]
			for i in 4:
				await RenderingServer.frame_post_draw
			var img: Image = vp.get_texture().get_image()
			img.convert(Image.FORMAT_RGBA8)
			sheet.blit_rect(img, Rect2i(0, 0, 640, 360), Vector2i((k % 2) * 640, (k / 2) * 360))
			fx.step(1.0)
		if PG.stop_if_any():
			return
		load("res://tools/picture_provenance.gd").save_png(sheet, out.path_join("idle_%s.png" % fac), PP.capture_stage())
		label.queue_free()
		fx.remove_ship("sheet_" + fac)
		s.root.queue_free()
		await process_frame
	print("IDLE_SHEETS_COMPLETE " + out)
