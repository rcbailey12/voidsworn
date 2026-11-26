extends SceneTree

const RIG := preload("res://render/camera_rig.gd")
const BATTLE := preload("res://scenes/battle/battle.tscn")
const SHIP := preload("res://render/ship_view.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SH := preload("res://fx/fx_shaders.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var failures := 0


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
	if failures == 0:
		print("PASS: shot framing, eased return, overlay restoration and counted death readability at camera 170")
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
		_check(cam.sees(source, 0.08) and cam.sees(target, 0.08), "keep both shot subjects inside the letterbox")
		var eye: Vector3 = cam.position - cam.t
		var shoulder := Vector3(eye.x, 0, eye.z).normalized().dot(shot_dir)
		_check(shoulder < (-0.75 if pose == chase else -0.30), "look from the attacker's shoulder")
	cam.return_from_cut(board_pose)
	var cut_radius: float = cam._cr
	var cut_target: Vector3 = cam._ct
	_check(cam._cr == cut_radius and cam.t == board_pose["t"], "return changes the desired pose before changing the drawn pose")
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
	for band in DEATH.CORE_READ_PX:
		fx.now += 1.0
		var first: int = fx.flash_area_log.size()
		DEATH._core_flash(fx, p, 2.0, 70.0, tint, null, Vector3.ZERO, null, band)
		var mat := _core_cards(fx).back() as ShaderMaterial
		var px := float(mat.get_shader_parameter("min_pixels"))
		var extent := float(mat.get_shader_parameter("extent"))
		var read_px := float(mat.get_shader_parameter("read_pixels"))
		var divisor := float(mat.get_shader_parameter("size_divisor"))
		var expected: float = fx._flash_disc(p, extent, maxf(px, read_px * divisor))[2]
		_check(fx.flash_area_log[first][6] == 1 and is_equal_approx(float(fx.flash_area_log[first][3]), expected),
			"M1: the %s bright core books its full screen diameter, including bloom on the read floor" % band)
	# One instance uses five packed vec4s. Verify the new ring is the sub-flash, bounded kind with a screen floor.
	_check(rings.pending.size() >= 20 and is_equal_approx(rings.pending[11], DEATH.CORE_RING_S)
		and rings.pending[15] <= 0.30 and rings.pending[18] == SH.RING_DEATH_FRONT
		and rings.pending[3] > float(DEATH.CORE_READ_PX["small"]),
		"the core emits a short, low-contrast screen-sized front")
	fx.reduce_flashing = true
	fx.now += 1.0
	var counted := fx.flash_log.size()
	var ring_count: int = rings.emitted
	DEATH._core_flash(fx, p, 2.0, 70.0, tint, null, Vector3.ZERO, null, "capital")
	cards = _core_cards(fx)
	_check(fx.flash_log.size() == counted and rings.emitted == ring_count + 1 and cards.back().get_shader_parameter("soft_flash") == 1.0,
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
