extends SceneTree
# Issue 44: the real battle, its shipped hulls and board, at camera_rig.gd radius 170.
# godot --path godot --resolution 1280x720 --script res://world/finale_shots.gd -- --out DIR
# Run twice, retaining the second set. No placeholder ships or substitute board are permitted.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const PG := preload("res://render/placeholder_guard.gd")
const BL := preload("res://world/board_look.gd")
var out := "user://finale_shots"
var caption: Label

class CaptureLog extends Logger:
	var errors := 0
	var mutex := Mutex.new()
	func _log_error(_fn: String, _file: String, _line: int, _code: String, _why: String, _notify: bool, kind: int, _bt: Array) -> void:
		if kind == Logger.ERROR_TYPE_WARNING: return
		mutex.lock()
		errors += 1
		mutex.unlock()

var capture_log := CaptureLog.new()
var started := 0

func _init() -> void:
	OS.add_logger(capture_log)
	started = Time.get_ticks_msec()
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _process(_delta: float) -> bool:
	if capture_log.errors > 0 or Time.get_ticks_msec() - started > 120000:
		printerr("finale shots: stopped on a rendering error or capture timeout")
		OS.remove_logger(capture_log)
		quit(1)
	return false

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var argv := OS.get_cmdline_user_args()
	for i in argv.size() - 1:
		if argv[i] == "--out": out = argv[i + 1]
	DirAccess.make_dir_recursive_absolute(out)
	BL.set_look("cine", false)
	var b = BATTLE.instantiate()
	b.external = true
	b.args["no-tips"] = true
	b.args["quality"] = "max"
	root.add_child(b)
	b.tips_off = true
	var api = API.new()
	if api.load_rules() != "":
		quit(1)
		return
	var sc := {"seed": 4110, "sector": 3, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"enemies": ["d_boss", "d_harvester", "d_jackal", "d_scythe"], "fac": "deathless", "obj": "rout",
		"shape": "deadstar", "map": "graveyard", "dep": "line", "kind": "boss"}
	api.new_battle_scenario(sc, 4110)
	api.R.B["biome"] = {"rock": "carbon", "planet": 5, "station": "spire"}
	# A mid-battle fixture: bring the real ships across the near side of the generated well,
	# so the camera Ryan uses can see light reaching successive hulls without zooming out.
	var slots := [[10, 16], [11, 14], [13, 17], [14, 15], [16, 14], [18, 17], [20, 15], [21, 16]]
	var occupied := {}
	for i in api.R.B["units"].size():
		var unit: Dictionary = api.R.B["units"][i]
		var slot: Array = slots[i % slots.size()]
		var target: Dictionary = api.R.offToAx(slot[0], slot[1])
		var h := {}
		var nearest := 1e9
		for cell in api.R.boardHexes():
			var key: String = api.R.hkey(cell["q"], cell["r"])
			if occupied.has(key) or api.R.BLOCKING.has(api.R.B["terrain"].get(key, "")): continue
			var distance: float = api.R.hdist(cell, target)
			if distance < nearest:
				h = cell
				nearest = distance
		assert(not h.is_empty(), "finale fixture needs a free hex")
		unit["q"] = h["q"]
		unit["r"] = h["r"]
		occupied[api.R.hkey(h["q"], h["r"])] = true
	b.battle_cfg = sc
	b.begin_with(api)
	var started := Time.get_ticks_msec()
	while b.warming or b.busy:
		if Time.get_ticks_msec() - started > 90000:
			printerr("finale shots: battle warm-up timed out")
			quit(1)
			return
		await process_frame
	if PG.stop_if_any(): return
	Engine.time_scale = 0.0
	b.hud.visible = false
	b.cam.r = 170.0
	var focus := Vector3.ZERO
	for ship in b.views.values(): focus += ship.position
	focus /= float(b.views.size())
	focus.y = 0.0
	b.cam.t = focus
	b.cam.screen_shift = 0.0
	b.cam.input_enabled = false
	b.cam.snap()
	b.world.set_process(false)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 18)
	caption.add_theme_font_size_override("font_size", 22)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(caption)
	caption.text = "FINALE DAWN | 1/6 | camera 170"
	await _settle()
	var normal := await _image()
	preload("res://tools/picture_provenance.gd").save_png(normal, out.path_join("normal_deadstar_camera170.png"), preload("res://tools/picture_provenance.gd").capture_stage())
	b.world.finale = true
	b.world._build_dawn(b.env)
	await _settle()
	var dark := await _image()
	var error := _difference(normal, dark)
	var report := {"camera_radius": b.cam.r, "ships": b.views.size(), "normal_vs_stage1_mean_error": error,
		"render_size": str(root.size), "fixture": "mid-battle ship placements on the generated dead-star board",
		"stages": [], "notes": Array(b.world.notes)}
	for i in 6:
		b.world.finale_for_round(i + 1)
		caption.text = "FINALE DAWN | %d/6 | camera 170" % [i + 1]
		await _settle()
		var img := await _image()
		var name := "finale_dawn_%d_of_6_camera170.png" % [i + 1]
		preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(name), preload("res://tools/picture_provenance.gd").capture_stage())
		report["stages"].append({"round": i + 1, "light_energy": b.world._finale_sun.light_energy, "file": name})
		print("finale shots: ", name)
	# Companion overviews show the whole sweep. The six primary pictures above remain at the played camera.
	b.cam.r = 520.0
	b.cam.t = b.world._center
	b.cam.snap()
	for i in 6:
		b.world.finale_for_round(i + 1)
		caption.text = "FINALE DAWN | %d/6 | board overview, radius 520" % [i + 1]
		await _settle()
		var img := await _image()
		var name := "finale_dawn_%d_of_6_overview520.png" % [i + 1]
		preload("res://tools/picture_provenance.gd").save_png(img, out.path_join(name), preload("res://tools/picture_provenance.gd").capture_stage())
		report["stages"][i]["overview"] = name
	b.cam.r = 170.0
	b.cam.t = focus
	b.cam.snap()
	report["render_errors"] = capture_log.errors
	var file := FileAccess.open(out.path_join("evidence.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("finale shots: normal vs round 1 mean error = ", error)
	OS.remove_logger(capture_log)
	# Allow less than one 8-bit colour step on average for the normal scene's ticking temporal shaders.
	PG.finish(0 if error < 0.002 else 1)

func _settle() -> void:
	for i in 45: await process_frame

func _image() -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img.get_width() != 1280 or img.get_height() != 720:
		img.resize(1280, 720, Image.INTERPOLATE_LANCZOS)
	return img

func _difference(a: Image, b: Image) -> float:
	var error := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			error += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
	return error / float(a.get_width() * a.get_height() * 3)
