extends SceneTree
# Issue 1434 (Artoo on PR 1445, head 31bb5117): the sliced board's terrain file loads are collected once or handed on.
# A board that leaves the tree during its terrain wait (a close or a leave) never waits on a load still running: the
# request goes to ShipView.retire_build, which collects it over the next frames. A finished one is collected at once.
# Headless; uses a real project resource as the stand-in terrain file.

const Board := preload("res://render/board.gd")
const SV := preload("res://render/ship_view.gd")

var fails := 0


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var path := "res://render/test/fixtures/board_terrain_stub.tres"
	# 1. leaving the tree mid-wait: the board's requests are all handed on or collected, none left with the board
	var b = Board.new()
	root.add_child(b)
	_check(ResourceLoader.load_threaded_request(path) == OK, "the stand-in terrain file starts a threaded load")
	b._terrain_loads.append(path)
	var t0 := Time.get_ticks_usec()
	root.remove_child(b)   # _exit_tree: collect or hand on, without waiting
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	_check(b._terrain_loads.is_empty(), "the board keeps no request after leaving the tree")
	_check(ms < 100.0, "leaving the tree took %.1f ms (limit 100)" % ms)
	var handed: bool = SV._retired_loads.has(path)
	var done := ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS
	_check(handed or done, "a load still running was handed to ShipView.retire_build (handed %s)" % handed)
	b.free()
	var f0 := Time.get_ticks_msec()
	while SV._retired_loads.has(path) and Time.get_ticks_msec() - f0 < 5000:
		await process_frame
	_check(not SV._retired_loads.has(path), "the handed load is collected within 5 s")
	# 2. a finished load is collected at once (wait true)
	var b2 = Board.new()
	root.add_child(b2)
	ResourceLoader.load_threaded_request(path)
	b2._terrain_loads.append(path)
	b2._drop_terrain_loads(true)
	_check(b2._terrain_loads.is_empty() and not SV._retired_loads.has(path), "a wait drop collects its own load")
	b2.queue_free()
	await process_frame
	print("board_terrain_load_check: %s" % ("PASS" if fails == 0 else "FAIL (%d)" % fails))
	quit(1 if fails else 0)
