extends SceneTree
## Real battle proof: --script res://ui/battle/keel_shots.gd --
## --seed 7 --ui-demo --obj ambush --no-tips --keel-out DIR [--keel-baseline]

const Battle := preload("res://scenes/battle/battle.tscn")
const Guard := preload("res://render/placeholder_guard.gd")
const RES := Vector2i(1920, 1080)

var b
var out := ""
var raw := ""
var baseline := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--keel-out")
	if i < 0 or i + 1 >= args.size() or DisplayServer.get_name() == "headless":
		_fail("a renderer and --keel-out DIR are required")
		return
	out = args[i + 1]
	i = args.find("--keel-raw")
	if i >= 0 and i + 1 < args.size():
		raw = args[i + 1]
		DirAccess.make_dir_recursive_absolute(raw)
	baseline = "--keel-baseline" in args
	seed(1021)
	AudioServer.set_bus_mute(0, true)
	b = Battle.instantiate()
	root.add_child(b)
	current_scene = b
	for frame in 5:
		root.mode = Window.MODE_WINDOWED
		root.size = RES
		await process_frame
	b.cine = "off"
	b.follow = false
	if not await _idle():
		return
	if Guard.stop_if_any():
		return
	await create_timer(0.4).timeout
	# Move through the same click handler as a player if no gun bears at the start.
	var foe := _bearing_enemy()
	if foe == "":
		b._update_reach()
		var best := {}
		for move: Dictionary in b.reach_map.values():
			if int(move.get("guns", 0)) > int(best.get("guns", 0)) and b._unit_at(int(move.q), int(move.r)).is_empty():
				best = move
		if best.is_empty():
			_fail("there is no reachable firing hex")
			return
		for tap in 2:
			b.hover = Vector2i(int(best.q), int(best.r))
			b._on_click()
			if not await _idle():
				return
		foe = _bearing_enemy()
	if foe == "" or b.sel == "":
		_fail("no selected ship with a bearing target")
		return
	var friend: String = b.sel
	# Arm a real bearing gun so the fire label and damage both describe that gun.
	var best_gun := -1
	var chance := -1
	for id in b._firing_set(foe):
		var odds: int = int(b._fire_preview(friend, id, foe).get("hit", 0))
		if odds > chance:
			best_gun = int(id)
			chance = odds
	b._arm(best_gun)
	b.hover = Vector2i(int(b.VU[foe].q), int(b.VU[foe].r))
	b._on_click()
	if not await _idle():
		return
	if b.target != foe:
		_fail("target click failed")
		return
	_quiet_pointer()
	# Use the playing zoom, with room for the target's full model above the shelf.
	b.cam.focus(b._pos(friend).lerp(b._pos(foe), 0.62), 170.0)
	await create_timer(0.7).timeout
	b.hud.ledger.layout()
	if not baseline:
		var projected: Vector2 = b.cam.unproject_position(b._pos(friend))
		if not Rect2(Vector2.ZERO, RES).has_point(projected) or b.hud.ledger.sheet_r.has_point(projected):
			_fail("the selected ship is outside the clear board at camera 170")
			return
		print("PASS capture: selected ship clear of shelf at camera 170; shot %d%%, target %s" % [chance, b._name(foe)])
	if not await _snap("main_target" if baseline else "keel_target"):
		return
	if baseline:
		Guard.finish()
		return
	b._on_action("log_collapse", null)
	if not await _snap("keel_log_collapsed"):
		return
	b._confirm()
	if not await _idle():
		return
	_quiet_pointer()
	b._on_action("log_collapse", null)
	if not await _snap("keel_log_open"):
		return
	# End a ship and capture the actual enemy-activation phase.
	var deadline := Time.get_ticks_msec() + 20000
	while not b.hud.ledger.enemy_turn() and Time.get_ticks_msec() < deadline and not b.ended:
		if b.api.phase == "player" and not b.busy and not b.ending:
			b.handed_t = -9.0
			b._on_key(KEY_SPACE)
		await process_frame
	if not b.hud.ledger.enemy_turn():
		_fail("enemy turn was never reached")
		return
	await create_timer(0.35).timeout
	if not await _snap("keel_enemy_turn"):
		return
	b._on_action("keys", null)
	b._on_action("log_setting", null)
	b.hud.ledger.ensure_layout()
	if b.hud.ledger.log_r.has_area() or b.hud.menu == null:
		_fail("Controls did not turn the floating log off")
		return
	print("PASS capture: battle Controls turn the floating log off")
	Guard.finish()


func _bearing_enemy() -> String:
	var fallback := ""
	for e: Dictionary in b.V.get("units", []):
		if e.side != "enemy" or e.dead or e.squadron or b._firing_set(e.id).is_empty():
			continue
		if e.get("nemesis", false):
			return e.id
		fallback = e.id
	return fallback


func _quiet_pointer() -> void:
	root.warp_mouse(Vector2(RES.x - 4, RES.y - 4))
	b.hover = Vector2i(9999, 9999)
	b._hover_uid = ""
	b.board.set_hover(9999, 9999)
	b.hud.show_tip("", Vector2.ZERO)
	b._refresh_ui()


func _idle() -> bool:
	var deadline := Time.get_ticks_msec() + 90000
	while (b.api == null or b.opening or b.warming or b.busy or b.ending or b.thinking) and not b.ended:
		await process_frame
		if Time.get_ticks_msec() > deadline:
			_fail("battle did not settle")
			return false
	return true


func _snap(name: String) -> bool:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	if frame.get_size() != RES:
		_fail("window capture was not 1920x1080: %s" % str(frame.get_size()))
		return false
	if raw != "" and preload("res://tools/picture_provenance.gd").save_png(frame, raw.path_join(name + "_1080.png")) != OK:
		_fail("native frame could not be saved")
		return false
	# Review canvas reserves space for the provenance strip below the actual game frame.
	frame.resize(1088, 612, Image.INTERPOLATE_LANCZOS)
	frame.convert(Image.FORMAT_RGB8)
	var review := Image.create(1280, 720, false, Image.FORMAT_RGB8)
	review.fill(Color("#11151b"))
	review.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(96, 0))
	if preload("res://tools/picture_provenance.gd").save_png(review, out.path_join(name + ".png")) != OK:
		_fail("stamped frame could not be saved")
		return false
	print("PASS capture: ", name, " (1920x1080 source)")
	return true


func _fail(reason: String) -> void:
	printerr("FAIL capture: " + reason)
	Guard.finish(1)
