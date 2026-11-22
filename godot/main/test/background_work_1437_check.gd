extends SceneTree
# godot --headless --path godot --script res://main/test/background_work_1437_check.gd
# Issue 1437 (Astra W1, items 8 and 9), headless:
#  1. the campaign map counts as live only while it is visible in the tree (the host hides its UI parent for a battle)
#  2. the battle viewport's AA state is written whole each time: Low turns FXAA on, Max and High turn it back off
#  3. Low lights the key with two shadow splits; Max and High keep four
#  4. the new Display settings default to today's game (full render scale, no frame cap, V-Sync on) and are listed
#  5. (review on PR 1607) the real map _process holds its arrival tween and its animation while hidden and resumes both
#  6. (review on PR 1607) the three rows press, save and reload; job launches never apply them; render scale covers a
#     viewport the way the map's is set; Graphics and TAA rebuild the title's battle at once

const Map = preload("res://ui/campaign/map3d.gd")
const BATTLE := preload("res://scenes/battle/battle.gd")
const LOOK := preload("res://render/look.gd")
const MAIN := preload("res://main/main.gd")
const TITLE := preload("res://main/title.gd")

class CampaignProbe extends RefCounted:
	var RUN = {"pos": "a"}
	var modal_d = null

class UIProbe extends RefCounted:
	var C = CampaignProbe.new()
	var k := 1.0
	func px(v): return int(v * k)

class MapProbe extends Map:
	var frames := 0
	func _ready(): pass
	func _live_frame(_delta): frames += 1

class TestMain extends MAIN:
	var restarts := 0
	var starts := 0
	func _ready() -> void: pass
	func restart_showcase() -> void:
		restarts += 1
		super.restart_showcase()
	# headless has no backdrop; stand in for a windowed run so the rebuild timers are armed
	func _showcase_wanted() -> bool: return str(settings.get("quality", "max")) != "low"
	func _start_showcase() -> void: starts += 1

var failures := 0


# wait for the newest backdrop timer main armed, then one frame for its callback
func _timer_fired(tm) -> void:
	var t: SceneTreeTimer = tm._showcase_timer
	if t != null and t.time_left > 0.0:
		await t.timeout
	await process_frame


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# 1 and 5. hidden map: the real _process gates the animation and holds the arrival tween
	var host := Control.new()
	root.add_child(host)
	var m = MapProbe.new()
	m.ui = UIProbe.new()
	m.root3 = Node3D.new()
	host.add_child(m)
	_check(m.map_live(), "1: the map animates while the campaign UI shows")
	var prog := [0.0]
	m._arrival_tween = m.create_tween()
	m._arrival_tween.tween_method(func(v: float) -> void: prog[0] = v, 0.0, 1.0, 2.0)
	for i in 3: await process_frame
	var f0: int = m.frames
	_check(f0 > 0 and prog[0] > 0.0, "5: shown, the map steps each frame and its arrival move runs (%d frames, %.3f)" % [f0, prog[0]])
	host.visible = false
	m._process(0.016)
	var held: float = prog[0]
	for i in 10: await process_frame
	_check(m.visible and not m.map_live(), "1: with the host UI hidden for a battle the map is still (its own visible flag stays true)")
	_check(m.frames == f0 and not m._arrival_tween.is_running() and absf(prog[0] - held) < 1e-6, "5: hidden, the real _process runs no map frame and holds the arrival move (%d frames, %.3f then %.3f)" % [m.frames - f0, held, prog[0]])
	host.visible = true
	for i in 3: await process_frame
	_check(m.map_live() and m.frames > f0 and m._arrival_tween.is_running() and prog[0] > held, "1 and 5: shown again, the map and its arrival move go on from where they stopped (%.3f)" % prog[0])
	m._arrival_tween.kill()
	m.root3.free()
	host.free()
	# 2. AA state
	var vp := SubViewport.new()
	root.add_child(vp)
	BATTLE.apply_quality_to(vp, "low", false)
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA and vp.msaa_3d == Viewport.MSAA_DISABLED, "2: Low uses FXAA and no MSAA")
	BATTLE.apply_quality_to(vp, "max", false)
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED and vp.msaa_3d == Viewport.MSAA_4X, "2: Low then Max leaves FXAA off (MSAA 4x)")
	BATTLE.apply_quality_to(vp, "low", true)
	BATTLE.apply_quality_to(vp, "high", true)
	_check(vp.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED and vp.use_taa, "2: Low then High: FXAA off, the player's TAA back on")
	vp.free()
	# 3. shadow splits
	var env := Environment.new()
	var key := DirectionalLight3D.new()
	var fill := DirectionalLight3D.new()
	root.add_child(key)
	root.add_child(fill)
	LOOK.apply(env, key, fill, {"quality": "low", "rim": false})
	_check(key.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS, "3: Low lights the key with two shadow splits")
	LOOK.apply(env, key, fill, {"quality": "max", "rim": false})
	_check(key.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "3: Max keeps four")
	key.free(); fill.free()
	# 4. new Display settings default to today's game
	var main = MAIN.new()
	_check(float(main.settings["render_scale"]) == 1.0 and float(main.settings["fps_cap"]) == 0.0 and bool(main.settings["vsync"]), "4: Render scale 100%, no frame cap and V-Sync on by default")
	var listed := []
	for sec in TITLE.SETTINGS_LAYOUT:
		for item in sec[2]:
			listed.append(str(item[2]))
	_check("render_scale" in listed and "fps_cap" in listed and "vsync" in listed, "4: the three are in the Display settings")
	_check(float(TITLE.SETTINGS_CHOICES["render_scale"][0][0]) == 1.0 and float(TITLE.SETTINGS_CHOICES["fps_cap"][0][0]) == 0.0, "4: each list starts on today's value")
	main.free()
	# 6. launch modes, press save reload, render scale on a viewport
	if not ProjectSettings.globalize_path("user://").replace("\\", "/").contains("/godot_checks/xdg/"):
		_check(false, "6: runs only in the game check sandbox (it writes the settings file)")
	else:
		var tm := TestMain.new()
		root.add_child(tm)
		tm._load_settings()
		_check(not tm.player_launch(), "6: a headless run never applies the player's display settings")
		for flags in [{"bot": true}, {"torp-shots": "x", "torp-ft": true}, {"battle": true}, {"ui-shots": "x"}, {"bot-runs": "4"}]:
			tm.args = flags
			_check(not tm.player_launch(), "6: a job launch (%s) keeps the engine's display defaults" % str(flags.keys()))
		tm.args = {}
		tm.settings["fps_cap"] = 60.0
		tm._apply_settings()
		_check(Engine.max_fps == 0, "6: a check run with a saved 60 fps cap leaves the frame cap off (%d)" % Engine.max_fps)
		tm.settings["fps_cap"] = 0.0
		tm.show_title()
		tm.title._settings()
		for i in 3: await process_frame
		var rows := {}
		for r in tm.title.settings_panel.find_children("*", "Button", true, false):
			if r.has_meta("setting_key"): rows[str(r.get_meta("setting_key"))] = r
		var have: bool = rows.has("render_scale") and rows.has("fps_cap") and rows.has("vsync")
		_check(have and rows["render_scale"].text == "100%" and rows["fps_cap"].text == "Off" and rows["vsync"].text == "On", "6: the rows read 100%, Off and On")
		if have:
			rows["render_scale"].pressed.emit()
			rows["fps_cap"].pressed.emit()
			rows["vsync"].pressed.emit()
			_check(rows["render_scale"].text == "85%" and rows["fps_cap"].text == "60" and rows["vsync"].text == "Off", "6: one press each moves to 85%, 60 and Off")
			var back := MAIN.new()
			back._load_settings()
			_check(is_equal_approx(float(back.settings["render_scale"]), 0.85) and is_equal_approx(float(back.settings["fps_cap"]), 60.0) and not bool(back.settings["vsync"]), "6: the three survive a restart (%s, %s, %s)" % [back.settings["render_scale"], back.settings["fps_cap"], back.settings["vsync"]])
			back.free()
		var have_q: bool = rows.has("quality") and rows.has("taa")
		if have_q:
			await _timer_fired(tm)   # the title's own first backdrop timer
			tm.starts = 0
			rows["quality"].pressed.emit()   # Max to High
			await _timer_fired(tm)
			var one: int = tm.starts
			rows["taa"].pressed.emit()
			await _timer_fired(tm)
			var two: int = tm.starts
			rows["quality"].pressed.emit()   # High to Low
			rows["taa"].pressed.emit()
			rows["quality"].pressed.emit()   # quickly: back to Max ...
			rows["quality"].pressed.emit()   # ... and on to High
			rows["quality"].pressed.emit()   # ... then Low before any timer fires
			await _timer_fired(tm)   # the newest pending rebuild (from High) has fired, so every earlier one has too
			var low_starts: int = tm.starts - two
			rows["quality"].pressed.emit()   # Low to Max
			await _timer_fired(tm)
			_check(one == 1 and two == 2, "6: a new Graphics or TAA setting rebuilds the battle behind the menu (%d, %d)" % [one, two])
			_check(low_starts == 0 and str(tm.settings["quality"]) == "max" and tm.starts == two + 1, "6: a quick switch to Low cancels every pending rebuild; Max again builds one (%d during Low, %d after)" % [low_starts, tm.starts - two])
		else:
			_check(false, "6: the Graphics and TAA rows are on the panel")
		tm.free()
		var sv := SubViewport.new()
		MAIN.apply_render_scale(sv, 0.7)
		_check(is_equal_approx(sv.scaling_3d_scale, 0.7) and sv.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR, "6: 70% draws a viewport at 0.7 with FSR")
		MAIN.apply_render_scale(sv, 1.0)
		_check(is_equal_approx(sv.scaling_3d_scale, 1.0) and sv.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR, "6: 100% is full scale, plain bilinear")
		sv.free()
	print("background_work_1437_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
