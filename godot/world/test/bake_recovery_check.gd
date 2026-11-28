extends SceneTree
# Headless cannot draw a SubViewport. Supply pixels at that boundary only.
# The normal-renderer request, worker, null-device branch, queue and disk I/O are real.

const BAKE := preload("res://world/world_bake.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const SKY := preload("res://world/world_sky.gd")
const SIZE := Vector2i(16, 8)
const SAMPLE := Color8(24, 36, 48, 96)

class FailedDeviceBake extends BAKE:
	var device_attempts := 0
	var raster_calls := 0
	var gamma := false
	var fail_raster := false
	var fail_finalizer := false
	var renderer := "forward_plus"

	func _display_renderer() -> String:
		return renderer

	func _create_local_device() -> RenderingDevice:
		device_attempts += 1
		return null

	func _canvas(_code: String, _params: Dictionary, size: Vector2i, sky_gamma := false) -> Image:
		raster_calls += 1
		gamma = sky_gamma
		await get_tree().process_frame
		if fail_raster: return null
		var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		img.fill(SAMPLE)
		return img

	func _start_finalizer(task: Callable) -> Error:
		return ERR_CANT_CREATE if fail_finalizer else super(task)

class Warnings extends Logger:
	var device := 0
	var finalizer := 0
	var shader := 0

	func _log_error(_fn: String, _file: String, _line: int, code: String, why: String, _notify: bool,
			kind: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if kind != ERROR_TYPE_WARNING: return
		var message := code + why
		if message.contains("Local RenderingDevice is unavailable"): device += 1
		if message.contains("Could not start world bake finalizer"): finalizer += 1
		if message.contains("fixture shader failure"): shader += 1

var _failures := 0

func _init() -> void:
	GUARD.arm(self, "bake_recovery_check", 20.0)
	_run.call_deferred()

func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)

func _run() -> void:
	var folder := OS.get_temp_dir().path_join("bake-recovery-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()])
	var old := OS.get_environment("VS_WORLD_CACHE")
	var had_override := OS.has_environment("VS_WORLD_CACHE")
	OS.set_environment("VS_WORLD_CACHE", folder)
	var warnings := Warnings.new()
	OS.add_logger(warnings)
	var svc := FailedDeviceBake.new()
	svc.name = "WorldBakes"
	root.add_child(svc)
	var s := SKY.setting({"rock": "deep", "planet": "rocky"}, "voidsworn", "open", false, 1436)
	var params := SKY.bake_params(s, 32)
	var code := SKY.bake_code()
	# A shader failure skips that source only. The unmodified sky below must still try the local device.
	var bad_code := code + "\n// another shader variant"
	var shader_failure := {"failure": "shader", "error": "fixture shader failure"}
	var shader_job := {"code": bad_code, "sky_half": true}
	svc._compute_failure(shader_failure, shader_job)
	svc._compute_failure(shader_failure, shader_job)
	var same_variant := await svc.bake_sky("same-variant", bad_code, params, SIZE)
	_check(same_variant != null and svc.device_attempts == 0 and svc.raster_calls == 1 and warnings.shader == 1,
		"only the failed shader variant is suppressed and logged once")

	var key := svc.request_bake("cold", code, params, SIZE, 32, false, false, true)
	var same := svc.request_bake("cold", code, params, SIZE, 32, false, false, true)
	_check(key == BAKE.cache_key("cold|half-sky", code, params, SIZE) and same == key,
		"normal-renderer sky keeps the half-sky key regardless of recovery")
	var also := ["waiting"]
	var wait := func() -> void: also[0] = await svc.result(same)
	wait.call()
	var first := await svc.result(key)
	await process_frame
	_check(first != null and also[0] == first, "both waiters got the same recovered image")
	_check(first != null and first.get_format() == Image.FORMAT_RGBA8 and not first.has_mipmaps()
		and first.get_pixel(0, 0).is_equal_approx(SAMPLE), "raster keeps the gamma RGB and transmittance without mips")
	_check(svc.device_attempts == 1 and svc.raster_calls == 2 and svc.gamma and warnings.device == 1,
		"a different shader tries the device and recovers with one warning and one gamma raster")
	_check(FileAccess.file_exists(folder.path_join(key + ".png")), "raster was saved to disk")
	BAKE._cache.erase(key)
	var from_disk := await svc.bake_sky("cold", code, params, SIZE)
	_check(from_disk != null and first != null and from_disk != first and from_disk.get_data() == first.get_data(),
		"second load comes back from disk with the same pixels")
	_check(svc.device_attempts == 1 and svc.raster_calls == 2, "disk load did not run either bake path")

	var half_float := Image.create_empty(SIZE.x, SIZE.y, false, Image.FORMAT_RGBAH)
	half_float.fill(Color(0.0004, 0.0006, 0.0007, 0.25))
	_check(BAKE._save(key, half_float, {}, {}, folder), "write the normal renderer's half-float cache")
	BAKE._cache.erase(key)
	var preferred := await svc.bake_sky("cold", code, params, SIZE)
	_check(preferred != null and preferred.get_format() == Image.FORMAT_RGBAH
		and preferred.get_data() == half_float.get_data(), "the half-float sky wins when both formats exist")

	svc.fail_finalizer = true
	var failed := await svc.bake_sky("finalizer-failure", code, params, SIZE)
	_check(failed == null and svc._active == "" and svc._thread == null and svc._jobs.is_empty(),
		"failed finalizer start returned to the waiter and released the queue")
	_check(svc.raster_calls == 3 and warnings.finalizer == 1, "failed finalizer was reported and was not retried")
	svc.fail_finalizer = false
	var next := await svc.bake_sky("next-miss", code, params, SIZE)
	_check(next != null and svc.raster_calls == 4 and svc.device_attempts == 1 and warnings.device == 1,
		"a new miss recovered without trying or logging the unavailable device again")

	svc.fail_raster = true
	var blank := await svc.bake_sky("raster-failure", code, params, SIZE)
	_check(blank == null and svc.raster_calls == 5, "an unsuccessful raster is not retried")
	svc.renderer = ""
	var headless := await svc.bake_sky("headless-miss", code, params, SIZE)
	_check(headless == null and svc.raster_calls == 5, "a headless miss did not call raster")
	svc.free()
	OS.remove_logger(warnings)
	if had_override: OS.set_environment("VS_WORLD_CACHE", old)
	else: OS.unset_environment("VS_WORLD_CACHE")
	for file in DirAccess.get_files_at(folder): DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	if _failures == 0: print("PASS: bake_recovery_check")
	quit(1 if _failures else 0)
