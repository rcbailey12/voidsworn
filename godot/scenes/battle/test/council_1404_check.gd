extends SceneTree
# Council 5, 11 and 31: exercise the camera against the real shelf and both Logs, then play an enemy activation.
const BattleScene := preload("res://scenes/battle/battle.tscn")
const CamRig := preload("res://render/camera_rig.gd")
const Guard := preload("res://tools/ci/check_guard.gd")
const Ledger := preload("res://ui/battle/ledger.gd")

var b
var fails := 0


func _init() -> void:
	Guard.arm(self, "council_1404_check", 60.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		fails += 1


func _regions() -> Array[Rect2]:
	var frame: Dictionary = b.hud.battle_frame(true)
	return CamRig.clear_regions(frame.area, frame.covers)


func _text(role: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	b.hud.ledger.ensure_layout()
	for it in b.hud.ledger.items:
		if it.role == role:
			items.append(it)
	return items


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	b = BattleScene.instantiate()
	b.external = true
	b.tips_off = true
	b.args.merge({"scenario": "s1", "seed": 1404, "quality": "low", "noworld": true})
	root.add_child(b)
	b.start_default()
	while b.warming or b.busy:
		await process_frame
	var hud = b.hud
	var cam = b.cam
	var player: String = b.sel
	var enemies: Array = b.V["units"].filter(func(u): return u["side"] == "enemy" and not u["squadron"])
	if player == "" or enemies.is_empty():
		_check(false, "battle has a selected player ship and an enemy fleet")
		quit(1)
		return
	var enemy: Dictionary = enemies[0]
	var enemy_id := str(enemy.id)
	_check(b.opening_framed, "opening fits the fleets inside the live margin")
	# With no ship needing a rescue pan, the opening should come to rest between the fleets.
	b.opening = true
	b.sel = ""
	b._end_opening()
	_check(cam.t.is_equal_approx(b._fleet_midpoint()) and not cam.t.is_equal_approx(cam.home), "opening glides to the fleet midpoint")
	b.sel = player
	hud.toggle_log()
	await process_frame
	cam.snap()
	var regions := _regions()
	var log: Rect2 = hud.log_panel.get_global_rect()
	var shelf: Rect2 = hud.ledger.sheet_r
	var in_log: Vector3 = cam.project_position(log.get_center(), cam.r)
	var in_shelf: Vector3 = cam.project_position(shelf.get_center(), cam.r)
	_check(not cam.sees_clear(in_shelf, regions) and not cam.sees_clear(in_log, regions), "shelf and full Log both occlude the board")
	var zoom: float = cam.r
	cam.keep_clear(in_shelf, in_log, regions)
	cam.snap()
	_check(cam.sees_clear(in_shelf, regions) and cam.sees_clear(in_log, regions) and is_equal_approx(cam.r, zoom), "one pan clears both subjects without pulling back")

	var original_pose: Vector3 = cam.t
	var log_height: float = hud.ledger.log_r.size.y
	b.speed = 0.01
	b.busy = true
	hud.set_playing(true)
	b.follow = true
	await b._play_event({"t": "activation", "unit": enemy_id, "side": "enemy"})
	hud.ledger.ensure_layout()
	_check(b._follow_ship == enemy_id and hud.log_open and not hud.log_panel.visible and not hud.log_collapsed
		and hud.ledger.log_r.size.y < log_height, "enemy follow folds the ticker and full Log without changing preferences")
	cam.snap()
	_check(cam.sees_clear(b._pos(enemy_id), _regions()), "the enemy actor is framed above the shelf and clear of the folded Log")
	_check(hud.ledger.ship.id == player and b.sel == player, "enemy turn keeps the selected player ship on the card")
	var title := _text("enemy_actor_heading")
	var classes := _text("enemy_actor_class")
	var weapons := _text("enemy_actor_weapons")
	_check(not title.is_empty() and title[0].t == "Enemy turn: %s is acting" % enemy.name and title[0].face == "BigShoulders"
		and title[0].x > shelf.get_center().x and not classes.is_empty() and classes[0].t == b._class_label(enemy.cls)
		and classes[0].face == "Barlow" and not weapons.is_empty() and weapons[0].t.contains(enemy.weapons[0].name),
		"right half names the actor, class and weapons in the Council faces")
	var guns := _text("enemy_paused_gun")
	var orders := _text("enemy_paused_order")
	_check(not guns.is_empty() and not orders.is_empty() and guns[0].col == Ledger.TEXT3 and orders[0].col == Ledger.TEXT3
		and not hud.ledger.hits.any(func(hit): return hit.act in ["arm", "brace", "confirm", "end", "next", "pick"]),
		"player guns and orders are grey and cannot act")
	hud.set_enemy_fire(enemy_id, str(enemy.weapons[0].name))
	var shot := _text("enemy_actor_firing")
	_check(not shot.is_empty() and shot[0].t == "Last fired: " + str(enemy.weapons[0].name), "the acting ship's latest weapon is shown")
	var hp0 := float(b.disp[player].hp)
	b._apply_hit({"target": player, "hull": 1.0, "shield": 0.0})
	_check(is_equal_approx(float(hud.ledger.ship.hp), hp0 - 1.0), "the retained hull takes enemy damage as it lands")

	# Item 3 is already in main. A cut-in also must not unfold the Log early or paint new edge guides.
	hud.show_tip("Board tooltip", Vector2(750, 440))
	hud._show_dtip()
	hud.show_tipcard("council_3", "Teaching tip", "A tip that was open before the cut.")
	_check(hud.tip.visible and hud.dtip.visible and hud.tipcard.visible, "all three tooltips start visible")
	hud.letterbox(true)
	hud.show_tip("Board tooltip refresh", Vector2(750, 440))
	hud._show_dtip()
	_check(not hud.tip.visible and not hud.dtip.visible and not hud.tipcard.visible, "item 3: a cut hides all three tips and suppresses hover refresh")
	hud.letterbox(false)
	_check(hud.tipcard.visible and not hud.log_panel.visible, "leaving a cut restores the teaching tip without unfolding the Log")
	hud.hide_tipcard()
	b._end_enemy_follow()
	hud.ledger.ensure_layout()
	_check(cam.t.is_equal_approx(original_pose) and hud.log_panel.visible and not hud.ledger.log_collapsed,
		"ending follow restores the original view and both Log states")
	b.follow = false
	await b._play_event({"t": "activation", "unit": enemy_id, "side": "enemy"})
	_check(hud.log_panel.visible and not _text("enemy_actor_heading").is_empty(), "follow off leaves the Log alone but still shows the actor")
	await b._play_event({"t": "side", "side": "player"})
	hud.ledger.ensure_layout()
	_check(_text("enemy_actor_heading").is_empty() and not hud.ledger.blockers.has(hud.ledger.sheet_r),
		"player playback still hides the sheet and clears the enemy actor")
	b.busy = false
	hud.set_playing(false)
	hud.toggle_log()
	cam.snap()

	# Pull one enemy just beyond each side, while the objective sits beyond the left side.
	var vs: Vector2 = root.get_visible_rect().size
	var on_board: Vector3 = cam.project_position(vs * Vector2(0.50, 0.39), cam.r)
	var just_inside: Vector3 = cam.project_position(Vector2(vs.x - 10, vs.y * 0.48), cam.r)
	var off_right: Vector3 = cam.project_position(Vector2(vs.x + 300, vs.y * 0.43), cam.r)
	var off_left: Vector3 = cam.project_position(Vector2(-300, vs.y * 0.40), cam.r)
	for u in enemies:
		b.views[u.id].snap_to(on_board, 0.0)
	var actor = b.views[enemy_id]
	actor.snap_to(just_inside, 0.0)
	b._fixed_objective = off_left
	b._step_battle_framing()
	_check(hud._edge_guides.size() == 1 and hud._edge_guides[0].get("objective", false), "on-screen contacts, even near the edge, get no marker")
	actor.snap_to(off_right, 0.0)
	b._step_battle_framing()
	var guides: Array[Dictionary] = hud._edge_guides
	_check(guides.size() == 2 and guides[0].get("objective", false) and guides[0].dir.x < 0.0 and guides[1].dir.x > 0.0
		and not hud.over_ui(guides[0].at) and not hud.over_ui(guides[1].at)
		and hud._edge_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "off-screen objective and enemy point to opposite edges without taking clicks")
	b.cine_saved = cam.cut_pose()
	b._step_battle_framing()
	_check(hud._edge_guides.is_empty(), "edge guides stay out of cut-ins")
	b.cine_saved = {}
	b.queue_free()
	await process_frame
	quit(1 if fails > 0 else 0)
