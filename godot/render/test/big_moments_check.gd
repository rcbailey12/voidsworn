extends SceneTree

const RIG := preload("res://render/camera_rig.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const SHIP := preload("res://render/ship_view.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SH := preload("res://fx/fx_shaders.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var failures := 0


class ApiStub extends RefCounted:
	var phase := "player"
	var round_snap_round := -1


func _initialize() -> void:
	GUARD.arm(self, "big_moments_check")
	_run.call_deferred()


func _check(ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + detail)


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	root.add_child(viewport)
	var cam := RIG.new()
	viewport.add_child(cam)
	cam.set_process(false)
	cam.input_enabled = false
	cam.snap()
	_camera_checks(cam)
	_flash_checks(viewport, cam)
	viewport.free()
	await _overlay_checks()
	await _cut_plate_checks()
	if failures == 0:
		print("PASS: shot framing, eased return, overlay restoration, counted death readability and cut-in plates at camera 170")
	quit(0 if failures == 0 else 1)


func _camera_checks(cam: Camera3D) -> void:
	var source := Vector3(-34, 2, 0)
	var target := Vector3(34, 3, 12)
	var board_pose: Dictionary = cam.cut_pose()
	var shot_dir := (Vector3(target.x, 0, target.z) - Vector3(source.x, 0, source.z)).normalized()
	var chase: Dictionary = cam.shot_cut("lance", source, target, 14.5, 14.5, false)
	var torp: Dictionary = cam.shot_cut("torp", source, target, 14.5, 14.5, false)
	var broad: Dictionary = cam.shot_cut("volley", source, target, 21.0, 14.5, false)
	var impact: Dictionary = cam.impact_cut(target, 27.0, true, [], false)
	_check(chase == torp and chase != broad and broad != impact, "three distinct shot presets")
	_check(chase["r"] < source.distance_to(target) * 1.25 + 34.0 and impact["r"] < chase["r"], "close in on the hit and the death")
	_check(impact["t"] == target, "impact holds the victim instead of the midpoint")
	for pose in [chase, broad]:
		cam.enter_cut(pose)
		cam.snap()
		# the letterbox bars cover the top and bottom 9 percent of the screen
		_check(cam.sees(source, 0.09) and cam.sees(target, 0.09), "keep both shot subjects inside the letterbox")
		var eye: Vector3 = cam.position - cam.t
		var shoulder := Vector3(eye.x, 0, eye.z).normalized().dot(shot_dir)
		_check(shoulder < (-0.75 if pose == chase else -0.30), "look from the attacker's shoulder")
	# issue 2194: the drawn radius must be read before the return starts, or the check compares the value with itself
	var cut_radius: float = cam._cr
	var cut_target: Vector3 = cam._ct
	cam.return_from_cut(board_pose)
	_check(cam._cr == cut_radius and cam._ct == cut_target and cam.t == board_pose["t"], "return changes the desired pose before changing the drawn pose")
	cam._process(RIG.CUT_RETURN_S * 0.25)
	var early: float = cam._cr
	cam._process(RIG.CUT_RETURN_S * 0.5)
	var late: float = cam._cr
	_check(cut_radius < early and early < late and late < float(board_pose["r"]) and cam._ct != cut_target, "return stays continuous")
	cam._process(RIG.CUT_RETURN_S * 0.25)
	_check(is_equal_approx(cam._cr, board_pose["r"]) and cam._ct == board_pose["t"] and cam.cut_pose() == board_pose, "return restores the board exactly")
	var wrapped := chase.duplicate()
	wrapped["a"] = float(board_pose["a"]) + TAU - 0.3
	for input in ["orbit", "pan", "zoom"]:
		cam.enter_cut(wrapped)
		cam.snap()
		cam.return_from_cut(board_pose)
		match input:
			"orbit": cam.orbit(12.0, 3.0)
			"pan": cam.pan_by(24.0, 12.0)
			"zoom": cam.zoom_at(Vector2(960, 540), 0.9)
		_check(cam._cut_return_elapsed == RIG.CUT_RETURN_S and cam.cut_pose() != board_pose,
			"%s interrupts the return and changes the board pose" % input)
		var azimuth: float = cam._ca
		cam._process(1.0 / 60.0)
		_check(absf(cam._ca - azimuth) < 0.1, "%s takes the short route from a wrapped cut heading" % input)
	cam.enter_cut(board_pose)
	cam.snap()
	var calm: Dictionary = cam.shot_cut("torp", source, target, 14.5, 14.5, true)
	_check(calm["a"] == cam._ca and calm["b"] == cam._cb, "reduce motion keeps the current orbit")
	var quarter: Dictionary = cam.impact_cut(target, 27.0, true, [], false)
	cam.enter_cut(quarter)
	cam.snap()
	var blocked_at: Vector3 = cam.position.lerp(target, 0.62)
	var clear_quarter: Dictionary = cam.impact_cut(target, 27.0, true, [[blocked_at, 10.0]], false)
	_check(not is_equal_approx(quarter["a"], clear_quarter["a"]), "choose a quarter with a clear line to the dying ship")
	cam.enter_cut(board_pose)
	cam.snap()


func _flash_checks(viewport: SubViewport, cam: Camera3D) -> void:
	var fx := FX.new()
	fx.manual = true
	viewport.add_child(fx)
	fx.setup({"camera": cam, "quality": "low", "reduce_flashing": false, "shake": 0.0, "unit": 1.0, "seed": 11})
	fx.flash_area_logging = true
	var rings = fx.pools["rng"]
	var p := Vector3.ZERO
	var tint := Color(0.9, 0.7, 0.6)
	for i in 4:
		fx.now = 0.20 * i
		DEATH._core_flash(fx, p, 2.0, 70.0, tint, null, Vector3.ZERO, null, "small")
	_check(fx.flash_log.size() == 3, "three bright cores per second, not four")
	_check(rings.emitted == 4, "one soft front per core even if the bright request is refused")
	var cards := _core_cards(fx)
	_check(cards.size() == 4, "the fourth core has a soft picture")
	for i in cards.size():
		var mat := cards[i]
		var floor_px := float(mat.get_shader_parameter("read_pixels"))
		var life := float(mat.get_shader_parameter("lifetime"))
		var bright := float(mat.get_shader_parameter("soft_flash")) == 0.0
		_check(floor_px >= float(DEATH.CORE_READ_PX["small"]) - 0.01 and life <= 0.70, "post-calibration core floor and flame cap")
		_check(bright == (i < 3) and (not bright or life <= 0.25), "refusal softens the core, bright phase stays short")
	_check(float(fx.flash_area_log[0][3]) >= float(DEATH.CORE_READ_PX["small"]), "the flash counter accounts for the enlarged core")
	# One instance uses five packed vec4s. Verify the new ring is the sub-flash, bounded kind with a screen floor.
	_check(rings.pending.size() >= 20 and is_equal_approx(rings.pending[11], DEATH.CORE_RING_S)
		and rings.pending[15] <= 0.30 and rings.pending[18] == SH.RING_DEATH_FRONT
		and rings.pending[3] > float(DEATH.CORE_READ_PX["small"]),
		"the core emits a short, low-contrast screen-sized front")
	fx.reduce_flashing = true
	fx.now = 2.0
	DEATH._core_flash(fx, p, 2.0, 70.0, tint, null, Vector3.ZERO, null, "capital")
	cards = _core_cards(fx)
	_check(fx.flash_log.size() == 3 and rings.emitted == 5 and cards.back().get_shader_parameter("soft_flash") == 1.0,
		"reduce flashing keeps the soft read without counting an extra flash")
	FX.clear_static()


func _core_cards(fx: Node) -> Array[ShaderMaterial]:
	var mats: Array[ShaderMaterial] = []
	for node in fx.get_children():
		if node is MeshInstance3D and node.get_meta("fx_picture_kind", "") == "flash":
			mats.append(node.material_override)
	return mats


func _overlay_checks() -> void:
	var battle = BATTLE.instantiate()
	battle.external = true
	root.add_child(battle)
	battle.set_process(false)
	var ship := SHIP.new()
	battle.add_child(ship)
	ship.set_process(false)
	ship._ring()
	ship.set_marker(true)
	ship.set_selected(true)
	ship.set_band(3.0)
	var drop_alpha := (ship.drop_dot.material_override as StandardMaterial3D).albedo_color.a
	var ring_mat := ship.ring.material_override as StandardMaterial3D
	_check(ring_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and ship.drop.visible, "the board starts with alpha rings and a visible drop-line")
	var blockers := Node3D.new()
	battle.board.add_child(blockers)
	battle.board.blocker_highlights = blockers
	battle.board.show_blockers([{"q": 0, "r": 0}])
	battle.views["probe"] = ship
	battle._cine_frame("probe", "probe")
	battle._step_cut_overlays(0.08)
	_check(is_equal_approx(battle.hud.plates_root.modulate.a, 0.5), "ship names fade during the cut")
	var drop_col: Color = ship.drop.material_override.get_shader_parameter("col")
	_check(ship.drop.visible and ship.drop_dot.visible and is_equal_approx(drop_col.a, drop_alpha * 0.5)
		and is_equal_approx(ship.drop_dot.material_override.albedo_color.a, drop_alpha * 0.5), "drop-line and dot fade together")
	battle._step_cut_overlays(0.10)
	battle.hud.show_tip("blocked", Vector2.ZERO)
	_check(battle.board.cut_overlay_alpha == 0.0 and not battle.hud.tip.visible, "grid and hover text stay out during the cut")
	_check(ship.ring.material_override.albedo_color.a == 0.0 and ship.marker.material_override.albedo_color.a == 0.0, "rings fade to zero")
	_check(not ship.drop.visible and not ship.drop_dot.visible and not blockers.visible, "the cut hides altitude and blocker overlays")
	_check(ring_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "fading does not change the ring pipeline")
	ship.ring.visible = false   # a death while the cut is holding must not resurrect the selection ring on return
	battle._cine_release()
	battle._step_cut_overlays(0.70)
	_check(battle.board.cut_overlay_alpha == 1.0 and battle.hud.plates_root.modulate.a == 1.0 and not ship.ring.visible
		and is_equal_approx(ship.marker.material_override.albedo_color.a, 0.85), "board state restores without reviving dead rings")
	_check(ship.drop.visible and ship.drop_dot.visible and blockers.visible
		and is_equal_approx(ship.drop_dot.material_override.albedo_color.a, drop_alpha), "the board brings back the live drop and blocker overlays")
	_check(ring_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "the ring stays on the same pipeline after the cut")
	battle.queue_free()
	await process_frame


# issue 2194: the cut-in's two ships keep readable plates at the settled fade, a killed target keeps its plate until
# the hold ends, every other plate hides, hit numbers stay out of the fade, and a skip click starts no orbit drag.
func _cut_plate_checks() -> void:
	var battle = BATTLE.instantiate()
	battle.external = true
	root.add_child(battle)
	battle.set_process(false)
	var ships := {}
	for id in ["att", "tgt", "oth"]:
		var ship := SHIP.new()
		battle.add_child(ship)
		ship.set_process(false)
		ship._ring()
		ships[id] = ship
	battle.views = ships
	battle.VU = {
		"att": {"name": "Attacker", "side": "player", "flagship": false, "hp": 80.0, "maxHp": 100.0,
			"sh": [10.0, 10.0, 10.0, 10.0], "shMax": 10.0, "size": 0.6},
		"tgt": {"name": "Target", "side": "enemy", "flagship": false, "hp": 60.0, "maxHp": 90.0,
			"sh": [8.0, 8.0, 8.0, 8.0], "shMax": 8.0, "size": 0.6},
		"oth": {"name": "Other", "side": "enemy", "flagship": false, "hp": 40.0, "maxHp": 60.0,
			"sh": [4.0, 4.0, 4.0, 4.0], "shMax": 4.0, "size": 0.6},
	}
	battle.disp = {
		"att": {"hp": 80.0, "sh": [10.0, 10.0, 10.0, 10.0]},
		"tgt": {"hp": 60.0, "sh": [8.0, 8.0, 8.0, 8.0]},
		"oth": {"hp": 40.0, "sh": [4.0, 4.0, 4.0, 4.0]},
	}
	battle.V = {"units": [
		{"id": "att", "side": "player", "active": false, "dead": false, "q": 0, "r": 0},
		{"id": "tgt", "side": "enemy", "active": false, "dead": false, "q": 1, "r": 0},
		{"id": "oth", "side": "enemy", "active": false, "dead": false, "q": 2, "r": 0}]}
	battle.api = ApiStub.new()
	battle.sel = "att"
	battle.target = "tgt"
	battle.cam.snap()
	battle._cine_frame("att", "tgt", "lance")
	battle._step_cut_overlays(0.20)
	battle._process(0.0)
	battle._process(0.0)
	_check(battle.hud.plates_root.modulate.a == 0.0, "the shared plate root settles at zero during the cut")
	_check(battle.hud.plates.has("att") and battle.hud.plates["att"].visible
		and battle.hud.plates["att"].get_parent() == battle.hud.cut_plates_root,
		"the attacker's plate stays up above the cut fade")
	_check(battle.hud.plates.has("tgt") and battle.hud.plates["tgt"].visible
		and battle.hud.plates["tgt"].get_parent() == battle.hud.cut_plates_root,
		"the target's plate stays up above the cut fade")
	_check(not battle.hud.plates["oth"].visible, "every other plate hides during the cut")
	battle._float("tgt", "Miss", Color(1.0, 1.0, 1.0))
	var lbl: Label = battle.floats[-1]["lbl"]
	battle._float_step(0.0)
	_check(lbl.get_parent() == battle.hud.floats_root and lbl.visible and lbl.modulate.a > 0.9,
		"a hit number stays readable at the settled cut fade")
	battle._cine_frame("att", "tgt", "torp")
	battle._step_cut_overlays(0.20)
	battle._float("tgt", "Critical", Color(1.0, 1.0, 1.0))
	var crit: Label = battle.floats[-1]["lbl"]
	battle._float_step(0.0)
	_check(crit.get_parent() == battle.hud.floats_root and crit.visible and crit.modulate.a > 0.9,
		"a critical stays readable during a torpedo cut-in")
	# the killing shot: the target is dead and the death path retires its plate, but the cut must finish first
	ships["tgt"].dead = true
	battle._retire_dead_plate("tgt")
	battle._process(0.0)
	_check(battle.hud.plates.has("tgt") and battle.hud.plates["tgt"].visible,
		"the killed target keeps its plate through the kill cut-in")
	ships["oth"].dead = true
	battle._retire_dead_plate("oth")
	_check(not battle.hud.plates.has("oth"), "a dead ship outside the cut retires its plate at once")
	battle._cine_release()
	battle._step_cut_overlays(0.70)
	battle._process(0.0)
	_check(not battle.hud.plates.has("tgt"), "the dead target's plate retires when the cut-in ends")
	_check(battle.hud.plates["att"].get_parent() == battle.hud.plates_root and battle.hud.plates_root.modulate.a == 1.0,
		"the attacker returns to the normal plate layer after the cut")
	# issue 2194 item 3: the skip click ends the hold and must not also start a drag that cancels the smooth return
	battle._cine_frame("att", "tgt", "lance")
	battle.cam.snap()
	battle.cam.input_enabled = true
	battle.kill_hold_until = battle.game_t + 5.0
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(760, 500)
	battle._unhandled_input(press)
	_check(battle.kill_hold_until < 0.0, "the skip click ends the kill hold")
	_check(battle.cam._drag == 0, "the skip click starts no orbit drag")
	var held_a: float = battle.cam.a
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(20, 4)
	battle.cam.handle_input(motion)
	_check(battle.cam._drag == 0 and battle.cam.a == held_a and battle.cam._cut_return_elapsed < RIG.CUT_RETURN_S,
		"the skip click leaves the smooth return running")
	battle.queue_free()
	await process_frame
