extends SceneTree
# godot --headless --path godot --script res://main/test/background_work_1437_check.gd
# Issue 1437 (Astra W1, items 8 and 9), headless:
#  1. the campaign map counts as live only while it is visible in the tree (the host hides its UI parent for a battle)
#  2. the battle viewport's AA state is written whole each time: Low turns FXAA on, Max and High turn it back off
#  3. Low lights the key with two shadow splits; Max and High keep four
#  4. the new Display settings default to today's game (full render scale, no frame cap, V-Sync on) and are listed

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
	func _ready(): pass
	func _process(_delta): pass

var failures := 0


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# 1. hidden map
	var host := Control.new()
	root.add_child(host)
	var m = MapProbe.new()
	m.ui = UIProbe.new()
	m.root3 = Node3D.new()
	host.add_child(m)
	_check(m.map_live(), "1: the map animates while the campaign UI shows")
	host.visible = false
	_check(m.visible and not m.map_live(), "1: with the host UI hidden for a battle the map is still (its own visible flag stays true)")
	host.visible = true
	_check(m.map_live(), "1: it runs again once the UI is back")
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
	print("background_work_1437_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
