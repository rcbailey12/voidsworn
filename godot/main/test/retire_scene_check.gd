extends SceneTree
# godot --headless --path godot --script res://main/test/retire_scene_check.gd
# Issue 1519: leaving a battle no longer frees it whole in the leave frame. main.retire_scene switches the old scene off
# and hides it at once (no processing, no camera, no environment, no sound), keeps it in the tree for its awaiting work,
# and frees it children first in small slices after the next screen has drawn; quit frees whatever is left.

const MAIN := preload("res://main/main.gd")
var failures := 0


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _scene() -> Node3D:
	var b := Node3D.new()
	b.name = "OldBattle"
	root.add_child(b)
	var cam := Camera3D.new()
	b.add_child(cam)
	cam.current = true
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	b.add_child(we)
	var hud := CanvasLayer.new()
	b.add_child(hud)
	hud.add_child(Control.new())
	for i in 40:
		var group := Node3D.new()
		b.add_child(group)
		for j in 5:
			group.add_child(MeshInstance3D.new())
	return b


func _run() -> void:
	var m = MAIN.new()   # never added to the tree: only its retire helpers run here
	var b := _scene()
	var cam: Camera3D = b.get_child(0)
	var we: WorldEnvironment = b.get_child(1)
	var hud: CanvasLayer = b.get_child(2)
	var total := 1 + 3 + 1 + 40 * 6
	m.retire_scene(b)
	_check(m.retire_pending() == total, "every node of the old scene is queued (%d of %d)" % [m.retire_pending(), total])
	_check(is_instance_valid(b) and b.is_inside_tree(), "the old scene stays in the tree for its awaiting work")
	_check(b.process_mode == Node.PROCESS_MODE_DISABLED, "it stops processing at once")
	_check(not b.visible and not hud.visible and not cam.current and we.environment == null, "it draws nothing: hidden, no camera, no environment")
	# the first two frames are held so the new screen draws before any free
	m._process(0.016)
	m._process(0.016)
	_check(m.retire_pending() == total, "nothing is freed in the two frames the new screen needs")
	# one slice with a tiny budget frees children before their parents
	m._free_retired(1)
	_check(is_instance_valid(b) and m.retire_pending() < total, "a slice frees leaves first; the scene root goes last")
	var frames := 0
	while m.retire_pending() > 0 and frames < 1000:
		m._process(0.016)
		frames += 1
	_check(not is_instance_valid(b), "the old scene is gone after %d slices" % frames)
	# quit: whatever is still waiting is freed at once
	var b2 := _scene()
	m.retire_scene(b2)
	m._free_retired(1 << 40)
	_check(not is_instance_valid(b2) and m.retire_pending() == 0, "quit frees a waiting scene at once")
	# bot runs keep the old immediate free
	var b3 := _scene()
	m.bot_mode = true
	m.retire_scene(b3)
	_check(m.retire_pending() == 0 and b3.is_queued_for_deletion(), "bot runs free at once, as before")
	m.free()
	print("retire_scene_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
