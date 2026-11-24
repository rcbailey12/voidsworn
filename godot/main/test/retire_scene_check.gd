extends SceneTree
# godot --headless --path godot --script res://main/test/retire_scene_check.gd
# Issue 1519: leaving a battle no longer frees it whole in the leave frame. main.retire_scene switches the old scene off
# and hides it at once (no processing, no camera, no environment, no sound), keeps it in the tree for its awaiting work,
# and frees it children first in small slices after the next screen has drawn; quit frees whatever is left.

const MAIN := preload("res://main/main.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
var failures := 0


class TestMain extends MAIN:
	var backdrop_wanted := false
	var backdrop_starts := 0
	var pending_at_start := -1

	func _ready() -> void:
		pass

	func _showcase_wanted() -> bool:
		return backdrop_wanted

	func _start_showcase() -> void:
		backdrop_starts += 1
		pending_at_start = retire_pending()
		backdrop_wanted = false


class SlowLeaf extends Node:
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			OS.delay_msec(7)  # one leaf costs more than the regular slice budget


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _init() -> void:
	GUARD.arm(self, "retire_scene_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _scene() -> Node3D:
	var b := Node3D.new()
	b.name = "OldBattle"
	var cam := Camera3D.new()
	b.add_child(cam)
	var we := WorldEnvironment.new()
	we.environment = Environment.new()
	b.add_child(we)
	var hud := CanvasLayer.new()
	b.add_child(hud)
	hud.add_child(Control.new())
	var audio := AudioStreamPlayer2D.new()
	audio.stream = AudioStreamGenerator.new()
	b.add_child(audio)
	for i in 40:
		var group := Node3D.new()
		b.add_child(group)
		for j in 5:
			group.add_child(MeshInstance3D.new())
	for i in 4:
		b.add_child(SlowLeaf.new())
	root.add_child(b)
	cam.make_current()
	audio.play()
	return b


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var m := TestMain.new()
	root.add_child(m)
	var b := _scene()
	var cam: Camera3D = b.get_child(0)
	var we: WorldEnvironment = b.get_child(1)
	var hud: CanvasLayer = b.get_child(2)
	var audio: AudioStreamPlayer2D = b.get_child(3)
	var total := 1 + 4 + 1 + 40 * 6 + 4
	_check(audio.playing, "the old battle starts with live audio")
	m.retire_scene(b)
	_check(m.retire_pending() == total, "every node of the old scene is queued (%d of %d)" % [m.retire_pending(), total])
	_check(is_instance_valid(b) and b.is_inside_tree(), "the old scene stays in the tree for its awaiting work")
	_check(b.process_mode == Node.PROCESS_MODE_DISABLED, "it stops processing at once")
	_check(not b.visible and not hud.visible and not cam.current and we.environment == null, "it draws nothing: hidden, no camera, no environment")
	_check(not audio.playing, "it stops the old battle's audio immediately")
	m.backdrop_wanted = true
	m.show_title()
	# Force the backdrop timer due before the first frame to check both gates.
	m._rebuild_due(m._showcase_gen)
	for i in 3:
		m._process(0.016)
	_check(m.title.menu != null and m.retire_pending() == total and m.backdrop_starts == 0,
		"the title menu exists before any scene free or backdrop build")
	await process_frame
	_check(not m._title_draw_pending and m.retire_pending() == total and m.backdrop_starts == 0,
		"the first title frame releases the draw gate while the old scene and backdrop still wait")
	var frames := 0
	while m.retire_pending() == total and frames < 10:
		await process_frame
		frames += 1
	_check(is_instance_valid(b) and m.retire_pending() < total and m.backdrop_starts == 0,
		"the first slice frees leaves and leaves the scene root and backdrop waiting")
	while m.retire_pending() > 0 and frames < 100:
		await process_frame
		frames += 1
	_check(not is_instance_valid(b) and m._retire_frames > 1, "the old scene is gone after %d slices" % m._retire_frames)
	await process_frame
	_check(m.backdrop_starts == 1 and m.pending_at_start == 0, "the backdrop starts once the entire old scene is gone")
	# The old title's pending timer cannot start a backdrop after a new title takes over.
	var stale_gen := m._showcase_gen
	m.backdrop_wanted = true
	m.show_title()
	m._rebuild_due(stale_gen)
	_check(m.backdrop_starts == 1, "an older title's timer cannot start the new title's backdrop")
	m.backdrop_wanted = false
	# quit: whatever is still waiting is freed at once
	var b2 := _scene()
	m.retire_scene(b2)
	_check(m._retire_free_n == 0 and m._retire_frames == 0, "a second scene starts with fresh slice counts")
	m._free_retired(1 << 40)
	_check(not is_instance_valid(b2) and m.retire_pending() == 0, "quit frees a waiting scene at once")
	# bot runs keep the old immediate free
	var b3 := _scene()
	m.bot_mode = true
	m.retire_scene(b3)
	_check(m.retire_pending() == 0 and b3.is_queued_for_deletion(), "bot runs free at once, as before")
	for i in 3:
		await process_frame
	m.free()
	print("retire_scene_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
