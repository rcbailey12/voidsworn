extends SceneTree

const Scene = preload("res://scenes/battle/battle.tscn")
const API = preload("res://rules/battle_api.gd")
const BoardLook = preload("res://world/board_look.gd")
const Ships = preload("res://render/placeholder_guard.gd")
const Provenance = preload("res://tools/picture_provenance.gd")
const CROP := Rect2i(490, 235, 980, 700)
const PANEL := Vector2i(640, 457)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or DisplayServer.get_name() == "headless":
		printerr("Pass one output directory after -- and use the game renderer.")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	await process_frame
	BoardLook.set_look("cine", false)
	var api := API.new()
	var error: String = api.load_rules()
	if error != "":
		printerr(error)
		quit(1)
		return
	var cfg := {"seed": 4101, "sector": 1, "admiral": "vex", "fleet": ["h_vanguard"],
		"enemies": ["c_raider"], "fac": "corsair", "obj": "rout", "shape": "open",
		"map": "belt", "dep": "line", "kind": "battle"}
	api.new_battle_scenario(cfg, cfg.seed)
	var battle = Scene.instantiate()
	battle.external = true
	battle.args["quality"] = "max"
	battle.args["shots"] = true
	battle.args["nofx"] = true
	battle.tips_off = true
	root.add_child(battle)
	battle.battle_cfg = cfg
	battle.begin_with(api)
	var deadline := Time.get_ticks_msec() + 90000
	while (battle.warming or battle.busy) and Time.get_ticks_msec() < deadline:
		await process_frame
	if battle.warming or battle.busy:
		printerr("Battle warm-up timed out.")
		quit(1)
		return
	if Ships.stop_if_any(): return
	battle.hud.hide()
	battle.set_process(false)
	battle.set_process_unhandled_input(false)
	battle.cam.input_enabled = false
	battle.cam.keyboard_enabled = false
	battle.cam.screen_shift = 0.0

	var id: String = battle._first_player()
	var host: Node3D = battle.views[id]
	for other: Node3D in battle.views.values():
		if other != host: other.hide()
	var q := 9
	var r := 7
	host.position = battle.board.hex_world(q, r)
	host.rotation.y = 0.0
	var cell: Vector3 = battle.board.hex_world(q + 4, r + 3) - Vector3.UP * 0.35
	battle.cam.focus(host.position.lerp(cell, 0.5), 170.0)
	battle.cam.snap()
	battle.cam.set_process(false)
	battle.VU[id] = battle.VU[id].duplicate()
	battle.VU[id]["weapons"] = [{"arc": "F", "range": 6, "ready": true, "kind": "macro"}]
	battle.fan_key = ""
	battle._fans(id)
	var after: MeshInstance3D = battle.fan_root.get_child(0)
	var span: Array = battle.ARC_SPAN["F"]
	var previous_radius: float = 6.0 * battle.board.HW + battle.board.HS * 0.5
	var before: MeshInstance3D = battle._fan_edge(span[0], span[1], previous_radius, Color(1.0, 0.62, 0.3))
	battle.fan_root.add_child(before)

	var layer := CanvasLayer.new()
	layer.layer = 50
	root.add_child(layer)
	var annotation := Control.new()
	layer.add_child(annotation)
	var scale := root.get_visible_rect().size / Vector2(1920, 1080)
	annotation.scale = scale
	var crop := Rect2i(Vector2(CROP.position) * scale, Vector2(CROP.size) * scale)
	var point: Vector2 = battle.cam.unproject_position(cell) / scale
	var projected_hull: Vector2 = battle.cam.unproject_position(host.position) / scale
	if not CROP.grow(-24).has_point(Vector2i(point)) or not CROP.grow(-24).has_point(Vector2i(projected_hull)):
		printerr("Fan example outside the capture crop. Hull: ", projected_hull, "; marked centre: ", point)
		quit(1)
		return
	var font := ThemeDB.fallback_font
	annotation.draw.connect(func():
		var top := Vector2(CROP.position)
		var title := "BEFORE  /  108.9 units" if before.visible else "AFTER  /  104.4 units"
		annotation.draw_rect(Rect2(top, Vector2(CROP.size.x, 48)), Color("#10151e"))
		annotation.draw_string(font, top + Vector2(20, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f1e8d9"))
		var guide := point + Vector2(-16, 40)
		annotation.draw_line(point + Vector2(-3, 8), guide, Color("#cde7ff"), 2.0, true)
		annotation.draw_arc(point, 7.0, 0.0, TAU, 24, Color("#cde7ff"), 2.0, true)
		annotation.draw_rect(Rect2(guide + Vector2(-180, -2), Vector2(180, 35)), Color("#10151e"))
		annotation.draw_string(font, guide + Vector2(-169, 23), "7 hexes away", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#cde7ff"))
	)
	var sheet := Image.create(1280, 640, false, Image.FORMAT_RGB8)
	sheet.fill(Color("#10151e"))
	for i in 2:
		# The first pair warms both material variants before the saved pass.
		for column in 2:
			before.visible = column == 0
			after.visible = column == 1
			annotation.queue_redraw()
			for frame in 12: await RenderingServer.frame_post_draw
			if i == 0: continue
			var panel := root.get_texture().get_image().get_region(crop)
			panel.convert(Image.FORMAT_RGB8)
			panel.resize(PANEL.x, PANEL.y, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(panel, Rect2i(Vector2i.ZERO, PANEL), Vector2i(column * PANEL.x, 0))
	var out := args[0].path_join("F6_fan_c170.png")
	quit(0 if Provenance.save_png(sheet, out, Provenance.capture_stage()) == OK else 1)
