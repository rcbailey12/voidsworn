extends "res://bench/look_bench.gd"
# Issue 1361 (World V2, R419; R420 band 3): the asteroid and crystal captures on the live world (world/world.gd draws the
# blockers, debris and edge fields exactly as a battle does), on the look bench's own view, lights and frame grid.
#
#   godot --path godot --rendering-method forward_plus --fixed-fps 60 --disable-vsync --resolution 1920x1080 \
#         res://bench/rock_bench.tscn -- --out DIR [--commit SHA] [--frames 300]
#
# Stills, each 1280x720 at 1 to 1 (a centre crop of the 1920x1080 frame), stamped by tools/picture_provenance.gd. The
# old-look switch (VS_1361_OLD) that drew main's rocks for the before/after captures was removed after Ryan's yes on the
# ROCKS_J sheets (Nov 23); a before picture now comes from an older commit's own bench.
#   rocks/RK_<kind>_c170.png and rocks/RK_<kind>_c26.png for stone, iron, carbon, ice, crystal (a rock blocker cluster and
#   debris hexes around the camera focus, the region's sky behind)
#   rocks/RK_crystal_comets_c420.png (aimed at the comets beyond the far edge and looking along their tails; the name is kept)
#   rocks/RK_crystal_cluster_c26.png (camera 26 tipped low onto a crystal blocker: the crystal kind is ice comets since
#   Ryan scrapped the clusters, Nov 22)
# and one frame-time row: rocks/frame_time.json (a full crystal belt, 37 rock hexes, at camera 170: mean and p95 GPU and
# CPU milliseconds over --frames frames, measured by the rendering server). A missing still or row writes
# ROCKS_FAILED.txt and exits 4; LOOK_BENCH_DONE prints only when everything is there. Before any picture the run proves
# its rock set (scan count, no crystal clusters, no retired scan, every mesh from its file) and records the
# manifest hashes in bench.json; any fallback rock, there or later, fails the run.

const WR := preload("res://world/world_rocks.gd")
const KINDS := ["stone", "iron", "carbon", "ice", "crystal"]
const PLANET := {"stone": 4, "iron": 5, "carbon": 6, "ice": 7, "crystal": 2}
const STILL := Vector2i(1280, 720)

var expected: Array = []
var missing: Array = []


func _run() -> void:
	report["commit"] = str(args.get("commit", ""))
	report["godot"] = Engine.get_version_info().get("string", "")
	report["adapter"] = RenderingServer.get_video_adapter_name()
	headless = DisplayServer.get_name() == "headless"
	# Artoo on PR 1782: prove which rock set this run draws before any picture, every mesh loaded from its file, never a
	# fallback
	var why := _preflight()
	if why != "":
		_fail(why)
		return
	_setup_view()
	var d := out.path_join("rocks")
	DirAccess.make_dir_recursive_absolute(d)
	for kind in KINDS:
		await _world({"rock": kind, "planet": PLANET[kind]}, _terrain(false), [])
		report["parts"]["rocks_" + kind] = {"region": str(wld.setting.get("region", "")), "start_frame": Engine.get_process_frames()}
		for r in [170.0, 26.0]:
			_cam(_hex(0, 0), r)
			await _hold(8)
			_save(d, "RK_%s_c%d.png" % [kind, int(r)], kind, r)
		if kind == "crystal":
			_cam(_hex(0, 0), 26.0)
			cam.b = 0.45
			cam.snap()
			await _hold(8)
			_save(d, "RK_crystal_cluster_c26.png", kind, 26.0)
			# the comets and their tails sit beyond the board's far edge, seen zoomed out (Ryan, Nov 22). Wave 0 (Nov 23): the
			# board-centred c420 frame cropped them off its top edge, so aim at the comets themselves and look lower, along
			# the tails against the sky
			_cam(_hex(0, 0), 420.0)
			if not wld.comet_spots.is_empty():
				var mid := Vector3.ZERO
				for p in wld.comet_spots:
					mid += p
				cam.t = mid / float(wld.comet_spots.size())
				cam.r = 520.0
				cam.b = 0.45
				cam.snap()
			else:
				_log("no comets were placed in the crystal field, so the wide comet frame has nothing to aim at")
				missing.append("RK_crystal_comets_c420.png (no comets)")
			await _hold(8)
			# Artoo on PR 1782: report the live radius and which frame this is (the file name keeps c420)
			_save(d, "RK_crystal_comets_c420.png", kind, cam.r, "board" if wld.comet_spots.is_empty() else "aimed at comets")
	# frame time: a full crystal belt at the battle camera
	await _world({"rock": "crystal", "planet": 2}, _terrain(true), [])
	_cam(_hex(0, 0), 170.0)
	await _hold(30)
	var row := await _frame_time(int(args.get("frames", 300)))
	expected.append("frame_time.json")
	if row.is_empty():
		missing.append("frame_time.json")
	else:
		var f := FileAccess.open(d.path_join("frame_time.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(row, " "))
		f.close()
		_log("frame time: gpu mean %.3f p95 %.3f ms, cpu mean %.3f ms over %d frames" % [
			row.gpu_mean, row.gpu_p95, row.cpu_mean, row.frames])
	if not WR.fallbacks.is_empty():
		missing.append("fallback rocks drawn: " + ", ".join(WR.fallbacks))
	_save_report()
	if not missing.is_empty():
		_fail("missing: " + ", ".join(missing))
		return
	_log("stills: %d" % report["stills"].size())
	print("LOOK_BENCH_DONE")
	_clear()
	await get_tree().process_frame
	get_tree().quit(0)


func _preflight() -> String:
	var scans: Array = WR.scan_names()
	var crystals: Array = WR.lib().get("crystals", [])
	if scans.size() != WR.SCAN_COUNT:
		return "%d scans in %s (want %d)" % [scans.size(), WR.lib_dir, WR.SCAN_COUNT]
	for retired in ["scan_00", "scan_06", "scan_07"]:
		if scans.has(retired):
			return "retired %s is in %s" % [retired, WR.lib_dir]
	if not crystals.is_empty():   # Ryan scrapped the crystal clusters (Nov 22)
		return "%d crystal clusters in %s rocks.json (want 0)" % [crystals.size(), WR.lib_dir]
	for nm in scans:
		for suffix in ["", "_lo"]:
			WR.mesh(str(nm) + suffix)
	for nm in crystals:
		WR.mesh(str(nm))
	if not WR.fallbacks.is_empty():
		return "rock files did not load from %s: %s" % [WR.lib_dir, ", ".join(WR.fallbacks)]
	report["rock_dir"] = WR.lib_dir
	report["scans_json_sha256"] = FileAccess.get_sha256(WR.lib_dir + "scans.json")
	report["rocks_json_sha256"] = FileAccess.get_sha256(WR.lib_dir + "rocks.json")
	report["scans"] = scans
	report["crystals"] = crystals
	_log("rock set: %s, %d scans, %d crystals, scans.json %s" % [WR.lib_dir, scans.size(), crystals.size(), str(report["scans_json_sha256"]).substr(0, 12)])
	return ""


# Rock hexes round the focus (a blocker on each, crystal clusters on the crystal kind) and debris hexes between; the full
# belt fills the whole three-ring hexagon with rock.
func _terrain(full: bool) -> Dictionary:
	var t := {}
	for q in range(-3, 4):
		for r in range(-3, 4):
			if absi(q + r) > 3:
				continue
			if full:
				t["%d,%d" % [q, r]] = "rock"
			elif (q == 0 and r == 0) or (q == 1 and r == 0) or (q == -1 and r == 1) or (q == 2 and r == -2):
				t["%d,%d" % [q, r]] = "rock"
			elif (q == 0 and r == 1) or (q == 1 and r == -1) or (q == -2 and r == 1):
				t["%d,%d" % [q, r]] = "debris"
	return t


func _hold(n: int) -> void:
	for k in n:
		await _step()


func _save(d: String, name: String, kind: String, r: float, frame := "board") -> void:
	expected.append(name)
	if headless:
		return
	var img := _grab()
	if img == null:
		missing.append(name)
		return
	var still := _crop(img, STILL, STILL)
	if preload("res://tools/picture_provenance.gd").save_png(still, d.path_join(name), preload("res://tools/picture_provenance.gd").capture_stage()) != OK:
		missing.append(name)
		return
	report["stills"].append({"part": "rocks", "file": "rocks/" + name, "kind": kind, "cam": int(r), "frame": frame, "step": steps})


func _frame_time(frames: int) -> Dictionary:
	if headless:
		return {"frames": 0, "gpu_mean": 0.0, "gpu_p95": 0.0, "cpu_mean": 0.0, "headless": true}
	var rid := vp.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for k in 30:
		await RenderingServer.frame_post_draw
	var gpu: Array = []
	var cpu: Array = []
	for k in frames:
		await RenderingServer.frame_post_draw
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
	RenderingServer.viewport_set_measure_render_time(rid, false)
	if gpu.is_empty():
		return {}
	gpu.sort()
	var gm := 0.0
	var cm := 0.0
	for v in gpu: gm += float(v)
	for v in cpu: cm += float(v)
	return {"frames": frames, "gpu_mean": gm / gpu.size(), "gpu_p95": float(gpu[int(gpu.size() * 0.95)]),
		"cpu_mean": cm / cpu.size(), "belt_hexes": 37, "camera": 170,
		"adapter": report["adapter"], "commit": report["commit"]}


func _fail(why: String) -> void:
	_log("ROCKS_FAILED " + why)
	var f := FileAccess.open(out.path_join("ROCKS_FAILED.txt"), FileAccess.WRITE)
	if f != null:
		f.store_string(why + "\n")
		f.close()
	get_tree().quit(4)
