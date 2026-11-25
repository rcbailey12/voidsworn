extends SceneTree
# Run with the same script against the pinned base and candidate. The fixture
# is scene gate #207 with its real battle, loading cover, fleets and FX.
const GATE := preload("res://bench/scene_gate.gd")
const BAKES := preload("res://world/world_bake.gd")
const STATIC_CACHES := preload("res://render/static_caches.gd")
const PICTURES := preload("res://tools/picture_provenance.gd")
const MODES := ["default", "fsr2_native", "fsr2_quality"]
const BC7_MODES := ["off", "on"]
const SIZE_4K := Vector2i(3840, 2160)
const SIZE_1080P := Vector2i(1920, 1080)
const WARM_FRAMES := 160
const DEATH_FRAME := 360
const DEATH_TRACE_USEC := 12_000_000


class Fixture extends GATE:
	var aa := "default"

	func _ready() -> void:
		pass

	func _configure_battle(_api) -> void:
		b.args["battle_aa"] = aa
		b.args["nebula_wake"] = "true"
		if args["map"] == "belt":
			# Keep the dense asteroid belt and remove gas for the empty-fog comparison.
			var terrain: Dictionary = _api.R.B["terrain"]
			for hex in terrain.keys():
				if terrain[hex] in ["neb", "storm"]:
					terrain.erase(hex)


var fixture: Fixture
var view: SubViewport
var peak_vram := 0
var peak_texture := 0


func _initialize() -> void:
	_run.call_deferred()


func _sample_memory() -> void:
	peak_vram = maxi(peak_vram, int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
	peak_texture = maxi(peak_texture, int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)))


func _argument(name: String, fallback: String) -> String:
	var opt := OS.get_cmdline_user_args()
	var i := opt.find(name)
	return opt[i + 1] if i >= 0 and i + 1 < opt.size() else fallback


func _run() -> void:
	var out := _argument("--out", "")
	var bc7 := _argument("--bc7", "off")
	if bc7 not in BC7_MODES:
		_fail("Pass --bc7 off or --bc7 on.")
		return
	if bc7 == "on":
		# The same bench script must parse when run against a baseline without this setting.
		var bake_script: Script = BAKES
		if not bake_script.has_method("set_bc7_enabled"):
			_fail("BC7 is not available on this revision.")
			return
		bake_script.call("set_bc7_enabled", true)
	if OS.get_cmdline_user_args().has("--dry-run"):
		print("1780 benchmark loaded (", RenderingServer.get_current_rendering_method(), ")")
		quit(0)
		return
	if out.is_empty():
		_fail("Pass --out with a run directory.")
		return
	if OS.get_cmdline_user_args().has("--sheet"):
		if _sheet(out, _argument("--shots", out), MODES, "MSAA_FSR2-Native_FSR2-Quality"):
			quit(0)
		return
	if OS.get_cmdline_user_args().has("--bc7-sheet"):
		if _sheet(out, _argument("--shots", out), BC7_MODES, "BC7-Off_BC7-On"):
			quit(0)
		return
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus" \
			or not RenderingServer.get_video_adapter_name().contains("5080"):
		_fail("Use the RTX 5080 in Forward+ through the solo PC launcher.")
		return
	var aa := _argument("--aa", "default")
	var resolution := _argument("--resolution", "1080")
	var map := _argument("--map", "storm")
	if aa not in MODES or resolution not in ["1080", "2160"] or map not in ["storm", "belt", "planet"]:
		_fail("Unknown AA mode, resolution or map.")
		return
	var expected_size := SIZE_4K if resolution == "2160" else SIZE_1080P
	OS.low_processor_usage_mode = false
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	AudioServer.set_bus_mute(0, true)
	GATE.BL.set_look("cine", false)
	view = SubViewport.new()
	view.size = expected_size
	view.own_world_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var rid := view.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	fixture = Fixture.new()
	fixture.aa = aa
	fixture.args["map"] = map
	fixture.build_wait_usec = 180_000_000
	view.add_child(fixture)
	process_frame.connect(_sample_memory)
	fixture.rng.seed = 2070
	var seed := 4210 if map == "planet" else 4207   # seed 4210 selects the rocky R01 surface
	if not await fixture._build("base", seed) or GATE.PG.stop_if_any():
		return
	var b = fixture.b
	var requested_fsr := aa != "default"
	var actual_size := Vector2i(view.get_visible_rect().size)
	var actual_fsr := view.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2
	var expected_scale := 0.8 if aa == "fsr2_quality" else 1.0
	var expected_msaa := Viewport.MSAA_DISABLED if requested_fsr else Viewport.MSAA_4X
	if actual_size != expected_size or actual_fsr != requested_fsr or view.msaa_3d != expected_msaa \
			or not is_equal_approx(view.scaling_3d_scale, expected_scale):
		_fail("Viewport did not use the requested resolution and AA.")
		return
	var deadline := Time.get_ticks_msec() + 180_000
	while b.world.pending_bakes > 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	if b.world.pending_bakes > 0:
		_fail("World bakes timed out.")
		return
	var kill_id := _capital(b)
	if kill_id.is_empty():
		_fail("The fixture has no capital with a live FX ship.")
		return
	var shots: Array[Image] = []
	var camera_angle: float = b.cam.a
	# Capture before firing so each mode shows the same ships. Readback stays outside frame timing.
	if resolution == "2160" and OS.get_cmdline_user_args().has("--pictures"):
		process_frame.disconnect(_sample_memory)
		for i in 120:
			await process_frame
			b.cam.a = camera_angle + 0.12 * sin(float(i) / 52.0)
			b.cam.snap()
			await RenderingServer.frame_post_draw
			if i in [106, 107, 108]:
				shots.append(view.get_texture().get_image())
		b.cam.a = camera_angle
		b.cam.snap()
		process_frame.connect(_sample_memory)
	for i in WARM_FRAMES:
		await process_frame
		await RenderingServer.frame_post_draw

	var frames := PackedFloat64Array()
	var gpu_frames := PackedFloat64Array()
	var trace := []
	var kill_ms := 0.0
	var last := Time.get_ticks_usec()
	var death_trace_end := 0
	var frame_index := 0
	# Follow the fracture and wreck as well as the kill call, even on a run with very short frames.
	while frame_index <= DEATH_FRAME or Time.get_ticks_usec() < death_trace_end:
		var pipe_before: Dictionary = fixture._pipes() if frame_index >= DEATH_FRAME else {}
		await process_frame
		# A repeatable orbit shows both metal highlights and the board's thin edges in motion.
		b.cam.a = camera_angle + 0.12 * sin(float(frame_index) / 52.0)
		b.cam.snap()
		if frame_index % 23 == 0:
			fixture._volley()
		if frame_index == DEATH_FRAME:
			var kill_start := Time.get_ticks_usec()
			death_trace_end = kill_start + DEATH_TRACE_USEC
			b.gfx.death(kill_id, "big")
			kill_ms = (Time.get_ticks_usec() - kill_start) / 1000.0
			fixture.side_ids["player"].erase(kill_id)
			fixture.side_ids["enemy"].erase(kill_id)
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var ms := (now - last) / 1000.0
		var gpu_ms := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		if frame_index < DEATH_FRAME:
			frames.append(ms)
			gpu_frames.append(gpu_ms)
		else:
			var pipes: Dictionary = fixture._pipes()
			for key in pipes:
				pipes[key] -= int(pipe_before.get(key, 0))
			trace.append({"frame_since_kill": frame_index - DEATH_FRAME, "frame_ms": ms, "gpu_ms": gpu_ms, "pipeline_compiles": pipes})
		last = now
		frame_index += 1

	var fogs: Array[Node] = b.world.find_children("*", "FogVolume", true, false)
	var planet_code := ""
	if is_instance_valid(b.board.planet_node):
		planet_code = str(b.board.planet_node.get_meta("planet_code", ""))
	var bake_stats := _world_bakes()
	var result := {
		"engine": Engine.get_version_info(), "gpu": RenderingServer.get_video_adapter_name(),
		"driver": OS.get_video_adapter_driver_info(), "resolution": [actual_size.x, actual_size.y],
		"aa": aa, "msaa": view.msaa_3d, "scale": view.scaling_3d_scale, "map": map,
		"ship_manifest_sha256": FileAccess.get_sha256(GATE.SV.manifest_path),
		"battle_load_ms": fixture.build_ms, "frame_ms": _summary(frames), "gpu_ms": _summary(gpu_frames),
		"peak_vram_bytes": peak_vram, "peak_texture_bytes": peak_texture, "world_bakes": bake_stats,
		"bc7": bc7,
		"fog_enabled": b.env.volumetric_fog_enabled, "fog_volumes": fogs.size(), "planet_code": planet_code,
		"first_death_ship": kill_id, "kill_call_ms": kill_ms, "first_death_trace": trace,
		"late_shader_names": GATE.HULL.late_shader_names(),
	}
	var file := FileAccess.open(out.path_join("timing.json"), FileAccess.WRITE)
	if file == null:
		_fail("Cannot write timing.json to " + out)
		return
	file.store_string(JSON.stringify(result, "\t") + "\n")
	file.close()
	if (map == "planet" and planet_code != "R01") or (map == "belt" and not fogs.is_empty()) \
			or (map == "storm" and (fogs.is_empty() or not b.env.volumetric_fog_enabled)):
		_fail("The fixture did not draw its expected terrain. See timing.json.")
		return
	var compressed: int = bake_stats.images.filter(func(row): return row.format == Image.FORMAT_BPTC_RGBA).size()
	if (compressed > 0) != (bc7 == "on"):
		_fail("World bakes did not use the requested BC7 setting. See timing.json.")
		return
	if map == "planet":
		var mat := b.board.planet_node.material_override as ShaderMaterial
		var albedo := mat.get_shader_parameter("colour_map") as ImageTexture
		var relief := mat.get_shader_parameter("surface_data") as ImageTexture
		if albedo == null or relief == null or (albedo.get_format() == Image.FORMAT_BPTC_RGBA) != (bc7 == "on") \
				or relief.get_format() != Image.FORMAT_RGBAF:
			_fail("The R01 albedo or relief did not use the expected format. See timing.json.")
			return
	for i in shots.size():
		if preload("res://tools/picture_provenance.gd").save_png(shots[i], out.path_join("frame_%d.png" % i), PICTURES.capture_stage()) != OK:
			_fail("Cannot save the native 4K comparison frame.")
			return
	view.free()
	STATIC_CACHES.clear_all()
	print("1780 benchmark complete: ", out)
	quit(0)


func _capital(b) -> String:
	for u: Dictionary in b.V.get("units", []):
		var id := str(u.get("id", ""))
		if GATE.TIER.get(u.get("cls", "")) == "capital" and b.gfx.ships.has(id):
			return id
	return ""


func _summary(samples: PackedFloat64Array) -> Dictionary:
	samples.sort()
	return {"median": samples[samples.size() / 2], "p99": samples[int(samples.size() * 0.99)], "max": samples[-1]}


func _world_bakes() -> Dictionary:
	var rows := []
	var bytes := 0
	for key in BAKES._cache:
		var image: Image = BAKES._cache[key]
		var count := image.get_data().size()
		bytes += count
		rows.append({"key": key, "width": image.get_width(), "height": image.get_height(),
			"format": image.get_format(), "bytes": count})
	return {"bytes": bytes, "images": rows}


func _sheet(out: String, shots: String, modes: Array, label: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(shots) != OK:
		_fail("Cannot create " + shots)
		return false
	var width := 420 if modes.size() == 3 else 630
	var preview_height := roundi(width * 9.0 / 16.0)
	var crop_height := 300
	for frame in 3:
		var sheet := Image.create_empty(1280, preview_height + crop_height + 44, false, Image.FORMAT_RGB8)
		sheet.fill(Color("#10151e"))
		for column in modes.size():
			var path := out.path_join(modes[column]).path_join("warm").path_join("frame_%d.png" % frame)
			var img := Image.load_from_file(path)
			if img == null or img.get_size() != SIZE_4K or not FileAccess.file_exists(path + ".provenance.json"):
				_fail("Missing native 4K frame or its sidecar: " + path)
				return false
			img.convert(Image.FORMAT_RGB8)
			var native_crop := img.get_region(Rect2i((SIZE_4K.x - width) / 2, 930, width, crop_height))
			img.resize(width, preview_height, Image.INTERPOLATE_LANCZOS)
			var left := (1280 - (width + 6) * modes.size() + 6) / 2 + column * (width + 6)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(left, 14))
			sheet.blit_rect(native_crop, Rect2i(Vector2i.ZERO, native_crop.get_size()), Vector2i(left, preview_height + 20))
		var name := "1780-frame-%d-4K-%s.png" % [frame + 1, label]
		if preload("res://tools/picture_provenance.gd").save_png(sheet, shots.path_join(name), "sheet built", true) != OK:
			_fail("Cannot write " + name)
			return false
	return true


func _fail(message: String) -> void:
	printerr("1780: ", message)
	quit(1)
