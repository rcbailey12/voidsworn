extends SceneTree
# godot --headless --path godot --script res://main/test/retire_scene_check.gd
# Issue 1519: leaving a battle for the title no longer frees the parked battle whole (LOAD36: its detach alone took
# 440 ms). After the title has drawn, main.gd _free_in_slices frees it children first, a few milliseconds of work a
# frame, while it stays in the tree switched off; the battle node goes last. This checks, through the real Main code:
#   1. the slices: children before parents, the battle node last, more than one frame, no slice far over its budget,
#      and the old battle stays in the tree, switched off, until its own turn;
#   2. the title's battle backdrop waits until the old battle is gone before it is built;
#   3. leaving the title meanwhile frees the rest at once; a close (quit_clean's hand-off) stops the slices;
#   4. a second leave while an older battle is still parked frees the older one, and gives back the first 3D setting;
#   5. the awaiting load steps of a parked battle stop at their next step in the tree too (the _parked guards in
#      world.gd, board.gd and fx.gd), where before they stopped only once the battle was out of the tree.
# The window's draw wait before the slices (_free_after_title_draws) needs a window, so the PC CLOSE5 run covers it.

const MAIN := preload("res://main/main.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const WORLD := preload("res://world/world.gd")
const BOARD := preload("res://render/board.gd")
const FX := preload("res://fx/fx.gd")

var failures := 0


class TestMain extends MAIN:
	var backdrop_wanted := false
	var hold_title_parts := false
	var stub: PackedScene

	func _ready() -> void:
		pass

	func _showcase_wanted() -> bool:
		return backdrop_wanted

	func _battle_packed() -> PackedScene:
		return stub

	func battle_parts_ready() -> bool:
		if not hold_title_parts:
			return await super.battle_parts_ready()
		while hold_title_parts:
			await get_tree().process_frame
		return true


# stands in for the backdrop battle: notes whether the old battle was still waiting when it was built
class StubShow extends Node3D:
	static var built_while_pending := -1
	var showcase := false
	var title_backdrop := false
	var args := {}
	var showcase_ready := false

	func _ready() -> void:
		var m = get_parent()
		built_while_pending = 1 if m.retire_pending() else 0
		showcase_ready = true


# every node of the old battle: notes the free order and whether its children went first
class Rec extends Node3D:
	static var log: Array = []
	var slow_ms := 0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			log.append([str(name), get_child_count(), is_inside_tree(), can_process() if is_inside_tree() else false])
			if slow_ms > 0:
				OS.delay_msec(slow_ms)   # one node's free that costs more than a whole slice


class FakeHud extends CanvasLayer:
	pass


func _check(ok: bool, message: String) -> void:
	print(("  ok: " if ok else "  FAIL: ") + message)
	if not ok:
		failures += 1


func _init() -> void:
	GUARD.arm(self, "retire_scene_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _old_battle(m: Node, tag: String) -> Rec:
	var b := Rec.new()
	b.name = "Battle" + tag
	for i in 40:
		var g := Rec.new()
		g.name = "G%d" % i
		b.add_child(g)
		for j in 5:
			var leaf := Rec.new()
			leaf.name = "L%d_%d" % [i, j]
			g.add_child(leaf)
	for i in 3:
		var slow := Rec.new()
		slow.name = "Slow%d" % i
		slow.slow_ms = 8
		b.add_child(slow)
	m.add_child(b)
	b.process_mode = Node.PROCESS_MODE_DISABLED   # as _retire_battle parks it
	return b


func _title(m: TestMain) -> void:
	var t := FakeHud.new()
	m.add_child(t)
	m.title = t


func _run() -> void:
	var m := TestMain.new()
	var show := StubShow.new()
	var ps := PackedScene.new()
	ps.pack(show)
	show.free()
	m.stub = ps
	root.add_child(m)
	_title(m)

	# 1. the slices
	Rec.log.clear()
	var b := _old_battle(m, "A")
	var total := 1 + 40 * 6 + 3
	m._retired = b
	var res := [null]
	var parts := {}
	var run := func() -> void: res[0] = await m._free_in_slices(b, parts)
	run.call()
	_check(int(m.retire_stats.get("nodes", 0)) == total, "every node of the old battle is listed (%d of %d)" % [m.retire_stats.get("nodes", 0), total])
	_check(is_instance_valid(b) and b.is_inside_tree() and Rec.log.size() > 0 and Rec.log.size() < total,
		"the first slice frees part of the battle in the leave's frame and leaves the rest (%d freed)" % Rec.log.size())
	# 2. the backdrop asked for now waits for the old battle
	m.backdrop_wanted = true
	StubShow.built_while_pending = -1
	m._start_showcase()
	_check(m.showcase == null, "the backdrop is not built while the old battle is being freed")
	var frames := 0
	while res[0] == null and frames < 200:
		await process_frame
		frames += 1
	_check(res[0] == true and not is_instance_valid(b), "the old battle is gone after %d slices" % int(m.retire_stats.get("slices", 0)))
	_check(int(m.retire_stats.get("slices", 0)) > 2, "the freeing is spread over frames, not one")
	var worst_ms := int(m.retire_stats.get("worst_us", 0)) / 1000.0
	_check(worst_ms < 40.0, "no slice runs far past its budget: longest %.1f ms (budget %.1f ms plus one 8 ms node)" % [worst_ms, MAIN.RETIRE_BUDGET_US / 1000.0])
	var children_first := true
	var in_tree_disabled := true
	for e in Rec.log:
		if int(e[1]) != 0:
			children_first = false
		if not bool(e[2]) or bool(e[3]):
			in_tree_disabled = false
	_check(children_first, "every node is freed after its children (none had a child left at its free)")
	_check(in_tree_disabled, "the battle stays in the tree, switched off, until each node's own free")
	_check(Rec.log.size() == total and str(Rec.log.back()[0]) == "BattleA", "the battle node goes last")
	_check(parts.has("battle_walk") and parts.has("battle_free"), "the [main] parts line gets the walk and the free time")
	m._retired = null   # _free_after_title_draws clears it after the slices
	for i in 3:
		await process_frame
	_check(m.showcase != null and StubShow.built_while_pending == 0, "the backdrop is built once the old battle is gone")
	m.backdrop_wanted = false
	if m.showcase != null:
		m.showcase.free()
		m.showcase = null
	m.backdrop_wanted = true
	m._fx_reading = true
	m.hold_title_parts = true
	m._start_showcase()
	m.backdrop_wanted = false   # like switching to Low while the title is still open
	m._fx_reading = false
	m.hold_title_parts = false
	await process_frame
	_check(m.showcase == null, "C32 selecting Low during prefetch cancels the pending title backdrop")

	# 3a. the title is left during the slices: the rest goes at once
	var b2 := _old_battle(m, "B")
	m._retired = b2
	res[0] = null
	var run2 := func() -> void: res[0] = await m._free_in_slices(b2, {})
	run2.call()
	_check(is_instance_valid(b2), "a second battle is being freed in slices")
	m.title.free()
	m.title = null
	await process_frame
	_check(res[0] == true and not is_instance_valid(b2) and bool(m.retire_stats.get("flushed", false)),
		"leaving the title frees the rest of the old battle at once")
	m._retired = null
	_title(m)
	# 3b. a close: quit_clean frees the parked battle and drops it, the slices stop
	var b3 := _old_battle(m, "C")
	m._retired = b3
	res[0] = null
	var run3 := func() -> void: res[0] = await m._free_in_slices(b3, {})
	run3.call()
	b3.queue_free()   # as quit_clean does
	m._retired = null
	await process_frame
	await process_frame
	_check(res[0] == false and not is_instance_valid(b3), "a close hands the rest to quit_clean and the slices stop")

	# 4. a second leave while an older battle is still parked (its title left before it drew); headless takes the
	# no-window branch of _retire_battle, so this calls its park step directly
	var old := _old_battle(m, "D")
	m._retired = old
	m._retire_3d = false        # 3D was on before the first park
	var restore: bool = m._take_parked(true)   # the second park sees 3D off (the first park turned it off)
	_check(not is_instance_valid(old) and not m.retire_pending(), "an older parked battle is freed at the second leave")
	_check(restore == false and m._retire_3d == false, "the first park's 3D setting is the one given back")
	_check(m._take_parked(false) == false and m._take_parked(true) == true, "with nothing parked the current setting is kept")

	# 5. a parked battle's awaiting load steps stop in the tree
	var parked := Node3D.new()
	parked.process_mode = Node.PROCESS_MODE_DISABLED
	m.add_child(parked)
	var w = WORLD.new()
	parked.add_child(w)
	w.pending_bakes = 1
	var bd = BOARD.new()
	parked.add_child(bd)
	bd.planet_pending = true
	bd.planet_t0 = Time.get_ticks_msec()
	var fxn = FX.new()
	parked.add_child(fxn)
	var done := [false, false]
	var wait_w := func() -> void:
		await w.wait_ready()
		done[0] = true
	var wait_b := func() -> void:
		await bd.wait_planet()
		done[1] = true
	wait_w.call()
	wait_b.call()
	for i in 3:
		await process_frame
	_check(done[0], "a parked world stops waiting on its bakes (else up to 20 s)")
	_check(done[1], "a parked board stops waiting on its planet maps (else up to 20 s)")
	_check(fxn._parked() and w._parked() and bd._parked(), "fx, world and board count as parked under a switched-off battle")
	parked.process_mode = Node.PROCESS_MODE_INHERIT
	_check(not fxn._parked() and not w._parked() and not bd._parked(), "and not parked in a live battle")
	w.pending_bakes = 0
	bd.planet_pending = false
	parked.queue_free()
	for i in 3:
		await process_frame
	m.free()
	print("%s: retire_scene_check" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
