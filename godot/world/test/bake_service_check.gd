extends SceneTree
# Issue 2024. Run headless for queue, disk and close checks. Run with the
# Forward+ renderer and -- --require-compute for GPU readback parity as well.
# A Compatibility window exercises the actual canvas fallback instead.

const GUARD := preload("res://tools/ci/check_guard.gd")
const BAKE := preload("res://world/world_bake.gd")
const PLANET := preload("res://world/world_planet.gd")
const SMALL := Vector2i(16, 8)
const PARITY_SIZE := Vector2i(256, 128)

class GateBake extends BAKE:
	var gate_key := ""
	var mock_board_key := ""
	var gate := Semaphore.new()
	var entered := Semaphore.new()
	var interrupt_strip := false
	var strips := 0

	func _work(work: Dictionary) -> Dictionary:
		if work.key == gate_key:
			entered.post()
			while not _should_stop() and not gate.try_wait(): OS.delay_msec(1)
			if _should_stop(): return {}
		if work.key == mock_board_key:
			return _mip_result(bake_fixture(work.size), "baked", {}, false)
		return super._work(work)

	func _dispatch_strip(pipeline: RID, uniforms: RID, y: int, size: Vector2i) -> int:
		var elapsed := super._dispatch_strip(pipeline, uniforms, y, size)
		strips += 1
		if interrupt_strip:
			entered.post()
			while not _should_stop(): OS.delay_msec(1)
		return elapsed

	static func bake_fixture(size: Vector2i) -> Array[Image]:
		var maps: Array[Image] = []
		for format in BOARD_FORMATS:
			var img := Image.create(size.x, size.y, false, format)
			img.fill(Color(0.42, 0.5, 0.1, 0.8))
			img.generate_mipmaps()
			maps.append(img)
		return maps

var failures := 0
var folder := OS.get_temp_dir().path_join("bake_service_check_%d_%d" % [OS.get_process_id(), Time.get_ticks_usec()])


func _init() -> void:
	GUARD.arm(self, "bake_service_check", 90.0)
	_run.call_deferred()


func _check(ok: bool, what: String) -> void:
	if ok: print("  ok: " + what)
	else:
		failures += 1
		printerr("  FAIL: " + what)


# Block only in the harness. _process and deferred attachment cannot run while
# these completions accumulate, and neither is needed by the worker.
func _finished(svc: Node, count: int, limit_ms := 5000) -> Array:
	var until := Time.get_ticks_msec() + limit_ms
	while Time.get_ticks_msec() < until:
		svc._mutex.lock()
		var results: Array = svc._finished.duplicate()
		svc._mutex.unlock()
		if results.size() >= count: return results
		OS.delay_msec(1)
	return []


func _entered(svc: GateBake) -> bool:
	var until := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < until:
		if svc.entered.try_wait(): return true
		OS.delay_msec(1)
	return false


func _save_png(name: String) -> void:
	var key := BAKE.cache_key(name, "", {}, SMALL)
	_check(BAKE._save(key, GateBake.bake_fixture(SMALL)[0], {}, {}, folder), "seeded " + name)


func _start_board(svc: Node, spec: Dictionary, size: Vector2i, got: Array) -> void:
	got.append(await svc.board_maps(spec.key, spec.code, spec.params, size))


func _early() -> void:
	var svc := BAKE.service(self)
	_check(not svc.is_inside_tree(), "service is pending on the first enqueue")
	var a: String = svc.request_bake("a", "", {}, SMALL, 32)
	var worker: Thread = svc._thread
	var b: String = svc.request_bake("b", "", {}, SMALL, 32)
	var replies := _finished(svc, 2)
	_check(replies.size() == 2 and not svc.is_inside_tree(), "both jobs finish before the first frame tick")
	if replies.size() == 2:
		_check(replies[0].work.key == a and replies[1].work.key == b, "queued jobs ran back to back in order")
		_check(replies[0].thread_id == replies[1].thread_id and replies[0].thread_id != OS.get_thread_caller_id(),
			"both jobs ran on the same worker thread")
	_check(await svc.result(a) != null and await svc.result(b) != null, "main-thread callers get both results after attach")
	BAKE._stop_worker()
	_check(worker != null and not worker.is_started() and svc._thread == null, "stop joined the idle worker")
	svc.queue_free()
	await process_frame
	await process_frame


func _queue_and_close() -> void:
	var pending := BAKE.service(self)
	pending.request_bake("a", "", {}, SMALL, 32)
	var pending_worker: Thread = pending._thread
	BAKE.clear_static()
	await process_frame
	_check(not pending_worker.is_started() and not is_instance_valid(pending) and root.get_node_or_null("WorldBakes") == null,
		"close joins and frees a worker whose service has not attached")

	var svc := GateBake.new()
	svc.name = "WorldBakes"
	root.add_child(svc)
	svc.gate_key = BAKE.cache_key("a", "", {}, SMALL)
	var active := svc.request_bake("a", "", {}, SMALL, 32)
	_check(_entered(svc), "first job is active")
	var far := svc.request_bake("b", "", {}, SMALL, 32)
	var urgent := svc.request_bake("urgent", "", {}, SMALL, 32, false, true)
	var promoted := svc.request_bake("promoted", "", {}, SMALL, 32)
	svc.request_bake("promoted", "", {}, SMALL, 32, false, true)
	svc.request_bake("a", "", {}, SMALL, 32, false, true)
	svc._mutex.lock()
	var order := svc._queue.map(func(job: Dictionary) -> String: return job.key)
	svc._mutex.unlock()
	_check(order == [urgent, promoted, far], "urgent jobs keep order, promote, and never duplicate an active job")
	var cancelled: Array = []
	_collect(svc, far, cancelled)
	_check(BAKE.drop_waiting(self) == 3 and not BAKE._pins.has(far) and BAKE._pins.has(active),
		"drop_waiting clears waiting jobs and pins, keeping the active job")
	svc.request_bake("b", "", {}, SMALL, 32)
	await process_frame
	await process_frame
	_check(cancelled == [null] and BAKE._pins.has(far), "a dropped waiter cannot unpin a fresh request for the same key")
	var interrupted: Array = []
	_collect(svc, active, interrupted)
	var worker: Thread = svc._thread
	BAKE.clear_static()
	await process_frame
	await process_frame
	_check(not worker.is_started() and svc._thread == null and interrupted == [null], "clear_static joins an active worker and releases its waiter")
	svc.queue_free()
	await process_frame
	await process_frame


func _collect(svc: Node, key: String, got: Array) -> void:
	got.append(await svc.result(key))


func _disk() -> void:
	var svc := GateBake.new()
	svc.name = "WorldBakes"
	root.add_child(svc)
	svc.add_to_group("battle_loading")
	var spec := PLANET.board_job(1, 6)
	var key := BAKE.board_key(spec.key, spec.code, spec.params, SMALL)
	var path := folder.path_join(key + BAKE.BOARD_SUFFIX)
	svc.mock_board_key = key
	var maps: Array = await svc.board_maps(spec.key, spec.code, spec.params, SMALL)
	_check(maps.size() == 3 and not FileAccess.file_exists(path) and svc.written == 0, "all maps arrive without writing during loading")
	svc.remove_from_group("battle_loading")
	var until := Time.get_ticks_msec() + 5000
	while svc.written == 0 and Time.get_ticks_msec() < until: await process_frame
	_check(svc.written == 1 and FileAccess.file_exists(path), "the worker writes one board entry after loading")
	_check(not FileAccess.file_exists(folder.path_join(key + ".png")), "the board never writes PNG")
	BAKE.clear_static()
	svc.mock_board_key = ""
	var warm: Array = await svc.board_maps(spec.key, spec.code, spec.params, SMALL)
	_check(warm.size() == 3 and maps.size() == 3, "the warm worker loads the complete board entry")
	if warm.size() == 3 and maps.size() == 3:
		for i in 3:
			_check(warm[i].get_format() == BAKE.BOARD_FORMATS[i] and warm[i].has_mipmaps() and warm[i].get_data() == maps[i].get_data(),
				"warm map %d preserves format, pixels and mips" % i)
	BAKE.prune(folder, 1, {key: true}, "")
	_check(FileAccess.file_exists(path), "a held board entry survives the cache cap")
	BAKE.prune(folder, 1, {}, "")
	_check(not FileAccess.file_exists(path), "the cap counts and prunes an unheld board entry")
	BAKE.clear_static()
	svc.queue_free()
	await process_frame
	await process_frame


func _gpu() -> void:
	var svc := GateBake.new()
	svc.name = "WorldBakes"
	root.add_child(svc)
	svc.add_to_group("battle_loading")
	# Let the engine's rendering server tick, but hold all results in the worker mailbox.
	svc.set_process(false)
	var parity: Array = []
	for look in [[1, 6], [4, 8], [3, 7]]:
		var spec := PLANET.board_job(look[0], look[1])
		var holder: Array = []
		_start_board(svc, spec, PARITY_SIZE, holder)
		var legacy: Array[String] = []
		for pass_id in 3:
			var params: Dictionary = spec.params.duplicate()
			params["pass_id"] = pass_id
			legacy.append(svc.request_bake("legacy|" + spec.key + "|" + str(pass_id), spec.code, params, PARITY_SIZE, 32, pass_id == 2))
		parity.append({"holder": holder, "legacy": legacy, "key": BAKE.board_key(spec.key, spec.code, spec.params, PARITY_SIZE)})
	var replies: Array = []
	var until := Time.get_ticks_msec() + 20000
	while replies.size() < 12 and Time.get_ticks_msec() < until:
		await process_frame
		svc._mutex.lock()
		replies = svc._finished.duplicate()
		svc._mutex.unlock()
	svc.set_process(true)
	_check(replies.size() == 12, "three board jobs and nine independent legacy passes completed")
	var devices := 0
	var pipelines := 0
	var boards := 0
	for reply in replies:
		var stages: Dictionary = reply.value.get("stages", {})
		if stages.has("device"): devices += 1
		if stages.has("pipeline"): pipelines += 1
		if reply.work.board:
			boards += 1
			_check(int(stages.get("strips", 0)) == 1, "board %s has one dispatch for all three maps" % reply.work.key.left(12))
	_check(devices == 1 and pipelines == 2 and boards == 3, "one device and two shader pipelines serve all twelve bakes")
	for row in parity:
		var old: Array[Image] = []
		for key in row.legacy: old.append(await svc.result(key))
		var maps: Array = row.holder.front() if not row.holder.is_empty() else []
		_check(maps.size() == 3 and not old.has(null), "both paths returned three images for " + row.key.left(12))
		if maps.size() != 3 or old.has(null): continue
		_check(maps[0].get_data() == old[0].get_data() and maps[1].get_data() == old[1].get_data(), "a and b match byte for byte")
		var h: Image = maps[2]
		var now := h.get_data().to_float32_array()
		var was := old[2].get_data().to_float32_array()
		var worst := 0.0
		if now.size() == was.size():
			for i in now.size(): worst = maxf(worst, absf(now[i] - was[i]))
		_check(h.get_format() == Image.FORMAT_RF and now.size() == was.size() and worst <= 1.0 / 65535.0,
			"float relief matches within 1/65535 (max %g)" % worst)
	BAKE.clear_static()
	svc.strips = 0
	svc.interrupt_strip = true
	var spec := PLANET.board_job(4, 8)
	var interrupted: Array = []
	_start_board(svc, spec, Vector2i(512, 512), interrupted)
	until = Time.get_ticks_msec() + 5000
	var began := svc.entered.try_wait()
	while not began and Time.get_ticks_msec() < until:
		await process_frame
		began = svc.entered.try_wait()
	_check(began, "the active compute bake reached the end of its first strip")
	var worker: Thread = svc._thread
	BAKE.clear_static()
	await process_frame
	await process_frame
	_check(not worker.is_started() and svc._rd == null and svc._pipelines.is_empty() and svc.strips == 1 and interrupted == [[]],
		"shutdown stops at the next strip and frees the worker device and pipelines")
	svc.queue_free()
	await process_frame
	await process_frame


func _compatibility() -> void:
	var svc := BAKE.service(self)
	var spec := PLANET.board_job(1, 6)
	var size := Vector2i(64, 32)
	var single: Image = await svc.bake("compat_single", spec.code, spec.params, size, 32)
	var maps: Array = await svc.board_maps(spec.key, spec.code, spec.params, size)
	_check(single != null and maps.size() == 3, "Compatibility returns both a single map and the three-map board")
	if single != null and maps.size() == 3:
		_check(not BAKE._blank(single) and single.get_data() == maps[0].get_data(), "Compatibility preserves the single-map albedo")
		_check(maps[2].get_format() == Image.FORMAT_RF, "Compatibility's third pass still returns float relief")


func _run() -> void:
	var had_override := OS.has_environment("VS_WORLD_CACHE")
	var override := OS.get_environment("VS_WORLD_CACHE")
	OS.set_environment("VS_WORLD_CACHE", folder)
	_save_png("a")
	_save_png("b")
	await _early()
	await _queue_and_close()
	await _disk()
	if DisplayServer.get_name() != "headless" and RenderingServer.get_current_rendering_method() != "gl_compatibility":
		await _gpu()
	elif "--require-compute" in OS.get_cmdline_user_args():
		_check(false, "compute parity requires a Forward+ or Mobile window")
	elif DisplayServer.get_name() != "headless":
		await _compatibility()
	else:
		print("  SKIP: GPU parity and canvas fallback need a window")
	BAKE.clear_static()
	if had_override: OS.set_environment("VS_WORLD_CACHE", override)
	else: OS.unset_environment("VS_WORLD_CACHE")
	for name in DirAccess.get_files_at(folder):
		if BAKE._bake_name(name): DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	if failures == 0: print("PASS: bake_service_check")
	else: printerr("FAIL: bake_service_check (%d)" % failures)
	quit(1 if failures else 0)
