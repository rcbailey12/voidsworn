extends SceneTree
## Install the PC hulls and import first. Run with the watchdog, Forward+, 1920x1080
## and --fixed-fps 60. User args: absolute output JPG path, BEFORE or AFTER.
const BATTLE := preload("res://scenes/battle/battle.tscn")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const GUARD := preload("res://render/placeholder_guard.gd")
const PICTURE := preload("res://tools/picture_provenance.gd")
const TILE := Vector2i(314, 222)
const FRAMES := [60, 102, 123, 144, 180, 228, 282, 345]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(1)
		return
	seed(1005)
	AudioServer.set_bus_mute(0, true)
	LOOK.set_look("cine", false)
	LOOK.tactical = false
	var battle = BATTLE.instantiate()
	battle.external = true
	battle.args["quality"] = "max"
	battle.args["no-tips"] = true
	root.add_child(battle)
	battle.tips_off = true
	battle.args["shots"] = true
	var api = API.new()
	var sc := {"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden"],
		"enemies": ["h_interdictor", "h_picket"], "fac": "hegemony", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	assert(api.load_rules().is_empty())
	api.new_battle_scenario(sc, 4103)
	api.R.B["biome"] = {"rock": "ice", "planet": 7, "station": "ring"}
	battle.battle_cfg = sc
	battle.begin_with(api)
	while battle.warming or battle.busy or battle.world == null or battle.world.pending_bakes > 0:
		await process_frame
	if GUARD.stop_if_any(): return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	for i in 4: await process_frame
	battle.hud.visible = false
	battle.set_process(false)
	battle.cam.set_process(false)
	battle.cam.screen_shift = 0.0
	battle.cam.reset_view()
	battle.cam.r = 170.0
	battle.cam.b = 0.98
	for ship in battle.views.values(): ship.set_process(false)
	var wings: Array[Node3D] = []
	var target := Vector3.ZERO
	for slot in [["proof_bomber", "voidsworn", "bomber", Vector3(-33, 0, 65)],
		["proof_fighter", "hegemony", "fighter", Vector3(-15, 0, 65)]]:
		var qr: Vector2i = battle.board.world_hex(slot[3])
		assert(battle.board.on_board(qr.x, qr.y))
		var u := {"id": slot[0], "fac": slot[1], "tpl": slot[2], "q": qr.x, "r": qr.y, "cls": "Squadron", "size": 0.35,
			"side": "player", "facing": 0, "hp": 10, "sh": [0, 0, 0, 0], "squadron": true, "flagship": false}
		battle._make_view(u)
		var ship: Node3D = battle.views[u.id]
		ship.set_process(false)
		ship.hull.set_process(false)
		wings.append(ship.hull)
		target += ship.position * 0.5
	battle.cam.t = target
	battle.cam.snap()
	battle._clear_overlay()
	battle.board.set_danger({})
	battle.board.set_focus(target)
	battle.board.set_hover(999, 999)
	var crop := Rect2i((root.size - TILE) / 2, TILE)
	var overlay := CanvasLayer.new()
	root.add_child(overlay)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = Vector2(crop.position + Vector2i(6, 4))
	overlay.add_child(label)
	var sheet := Image.create(1280, 540, false, Image.FORMAT_RGB8)
	sheet.fill(Color("#10151e"))
	var panel := 0
	for frame in range(1, FRAMES[-1] + 1):
		for wing in wings: wing.step(1.0 / 60.0)
		if frame != FRAMES[panel]: continue
		label.text = "SQ3B / %s / %.2f s" % [args[1], frame / 60.0]
		await process_frame
		await RenderingServer.frame_post_draw
		var pixels := root.get_texture().get_image().get_region(crop)
		pixels.convert(Image.FORMAT_RGB8)
		var tile := Vector2i(5 + (panel % 4) * 319, 5 + (panel / 4) * 227)
		sheet.blit_rect(pixels, Rect2i(Vector2i.ZERO, TILE), tile)
		panel += 1
	var result := PICTURE.save_jpg(sheet, args[0], 0.96, PICTURE.capture_stage())
	print("%s: SQ3B %s, eight matched battle-camera frames" % ["PASS" if result == OK else "FAIL", args[1]])
	GUARD.finish(0 if result == OK else 1)
