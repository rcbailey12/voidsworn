extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1460: three small graphics bugs from the Nov 21 graphics audit, checked on the live battle tree. Headless.
#   godot --headless --path godot --script res://render/test/camera_shake_check.gd
# 1. The trauma shake keeps its sideways part. The battle adds its effects (fx.gd) before its camera rig, so the rig
#    processed after fx and set h_offset from screen_shift alone, wiping the sideways shake every frame. Now fx hands the
#    shake to the rig (shake_offset) and the rig adds it. While trauma is active cam.h_offset leaves its screen_shift
#    value; once trauma has decayed it is back on it, and v_offset is back at 0.
# 2. The Eclipse revival flash (legionRise, battle.gd _reassemble) uses the Eclipse colour from fx/faction_looks.json
#    (all violet, R372), and the battle scene has no lime Color(0.2, 1.0, 0.4) left.
# 3. Debanding is on in project.godot, so dark skies do not show banding steps.
const BattleScene := preload("res://scenes/battle/battle.tscn")
const FLOOK := preload("res://fx/faction_look.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "camera_shake_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("ok   " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _run() -> void:
	# 3. debanding
	_check(bool(ProjectSettings.get_setting("rendering/anti_aliasing/quality/use_debanding", false)),
		"project.godot turns debanding on")
	# 2. the revival flash colour
	var src := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	_check(not src.contains("Color(0.2, 1.0, 0.4)"), "battle.gd has no lime Color(0.2, 1.0, 0.4)")
	var rx := RegEx.create_from_string("func _reassemble[\\s\\S]*?\\n\\t_flash\\([^\\n]*FLOOK\\.engine\\(")
	_check(rx.search(src) != null, "_reassemble's revival flash takes its colour from FLOOK (faction_looks.json)")
	var ecl: Color = FLOOK.engine("deathless")
	_check(ecl.b > ecl.g and ecl.r > ecl.g, "the Eclipse colour it uses is violet (%s), not green" % str(ecl))
	# 1. the live battle tree: the rig is added after the effects, as in the game
	var b = BattleScene.instantiate()
	b.args["quality"] = "low"
	root.add_child(b)
	var deadline := Time.get_ticks_msec() + 90000
	while (b.get("warming") == true or b.cam == null or b.gfx == null) and Time.get_ticks_msec() < deadline:
		await process_frame
	var cam = b.cam
	var gfx = b.gfx
	_check(cam != null and gfx != null, "the battle built its camera rig and effects")
	if cam == null or gfx == null:
		_end()
		return
	_check(gfx.get_index() < cam.get_index(), "the effects run before the camera rig (the order that lost the shake)")
	cam.screen_shift = 180.0
	for i in range(6):
		await process_frame
	# the rig's own screen_shift value of h_offset at its live zoom (camera_rig.gd _apply); the camera may still be
	# gliding in, so it is worked out again each frame
	_check(absf(_shift_value(cam)) > 0.01, "screen_shift alone moves h_offset (%.3f)" % _shift_value(cam))
	_check(absf(cam.h_offset - _shift_value(cam)) < 1e-3, "before the hit h_offset sits on its screen_shift value")
	_check(absf(cam.v_offset) < 1e-6, "v_offset rests at 0")
	gfx.shake(gfx.now, 1.0, cam.global_position)
	var max_dx := 0.0
	var max_dy := 0.0
	for i in range(12):
		await process_frame
		max_dx = maxf(max_dx, absf(cam.h_offset - _shift_value(cam)))
		max_dy = maxf(max_dy, absf(cam.v_offset))
	print("     during trauma: largest sideways move %.4f, largest vertical move %.4f" % [max_dx, max_dy])
	_check(max_dx > 0.01, "while trauma is active h_offset moves away from its screen_shift value")
	_check(max_dy > 0.01, "while trauma is active v_offset moves")
	var t_end := Time.get_ticks_msec() + 3000
	while Time.get_ticks_msec() < t_end:
		await process_frame
	var left := absf(cam.h_offset - _shift_value(cam))
	_check(left < 1e-3, "once trauma decays h_offset is back on its screen_shift value (off by %.5f)" % left)
	_check(absf(cam.v_offset) < 1e-4, "once trauma decays v_offset is back at 0")
	_end()


func _shift_value(cam) -> float:
	var vh: float = cam.get_viewport().get_visible_rect().size.y
	return -cam.screen_shift / maxf(vh * 0.5, 1.0) * cam._cr * tan(deg_to_rad(cam.fov) * 0.5)


func _end() -> void:
	print("camera_shake_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)
