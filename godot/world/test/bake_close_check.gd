extends SceneTree
# Issues 1434 and 1765 (Artoo, cross-PR note on PR 1445 and PR 1776): the world bake service's two shutdown paths
# together. clear_static() runs on every close (main.gd quit_clean, render/static_caches.gd). Case 1: the close comes
# before the service's deferred add lands, so 1776's path frees the unattached service and its queued add does
# nothing. Case 2: the close comes while the attached service's worker is inside a job, so 1445's path stops and joins
# the worker first, ends the job without an image (its waiter returns) and leaves the service idle.

const GUARD := preload("res://tools/ci/check_guard.gd")
const BAKE := preload("res://world/world_bake.gd")
const PLANET := preload("res://world/world_planet.gd")

var failures := 0


func _expect(ok: bool, what: String) -> void:
	if ok: print("  ok: " + what)
	else:
		failures += 1
		printerr("  FAIL: " + what)


func _init() -> void:
	GUARD.arm(self, "bake_close_check")
	_run.call_deferred()


func _run() -> void:
	# 1. close before the service attaches
	var early = BAKE.service(self)
	_expect(is_instance_valid(early) and not early.is_inside_tree(), "a new service waits on its deferred add")
	BAKE.clear_static()
	_expect(not is_instance_valid(early), "the close freed the service that never attached")
	for i in 3:
		await process_frame
	_expect(root.get_node_or_null("WorldBakes") == null, "the freed service's queued add did nothing")
	# 2. close during an active job
	var svc = BAKE.service(self)
	for i in 3:
		await process_frame
	_expect(svc.is_inside_tree(), "a second service attached")
	var key: String = svc.request_authored(PLANET.R01_DIR + "relief.json", PLANET.R01_SIZE, true, true)
	var got := ["waiting"]
	var wait := func() -> void: got[0] = await svc.result(key)
	wait.call()
	var t0 := Time.get_ticks_msec()
	var taken := false
	# Do not give _process a chance to drain the hand-back while observing the worker.
	while not taken and Time.get_ticks_msec() - t0 < 10000:
		svc._mutex.lock()
		taken = svc._active == key or not svc._finished.is_empty()
		svc._mutex.unlock()
		if not taken: OS.delay_msec(1)
	_expect(taken and svc._thread != null, "the worker took the job (the case under test)")
	var tc := Time.get_ticks_msec()
	BAKE.clear_static()
	print("  clear_static with the worker inside the job: %d ms" % (Time.get_ticks_msec() - tc))
	_expect(svc._thread == null and svc._active == "" and not svc._jobs.has(key), "the close stopped and joined the worker and ended its job")
	_expect(is_instance_valid(svc) and svc.is_inside_tree(), "the attached service was only forgotten, never freed")
	await process_frame
	await process_frame
	_expect(got[0] == null, "the job's waiter returned without an image")
	svc.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: bake_close_check")
		quit(0)
	else:
		printerr("FAIL: bake_close_check (%d)" % failures)
		quit(1)
