extends SceneTree
# Issue 1767 (Artoo on PR 1772, 9a65776c): fresh-process cost of a dense graveyard on the live board. Copied by
# OPUS1767_LOAD.bat into godot/bench/ of each pinned checkout (old main and the PR head); works on both, since it only
# calls render/board.gd build(). One run = one fresh process: a 1920x1080 window with a camera, then a 31-hulk-hex board
# built once (first touch of every hulk scene, texture and, on the new head, its texture mean). Prints one line:
#   GRAVEYARD_LOAD build_ms=<board.build> first_frame_ms=<to the first drawn frame after> process_ms=<since start>
#     static_peak_mb=<Godot static peak> video_mb=<video memory in use> peak_ws_mb=<Windows peak working set> hulks=<n>
const BOARD := preload("res://render/board.gd")

class Rules extends RefCounted:
	var v := {}
	var w := {}
	func view() -> Dictionary:
		return v
	func world_info() -> Dictionary:
		return w


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0, 150, 90)
	cam.look_at(Vector3.ZERO)
	cam.current = true
	var light := DirectionalLight3D.new()
	root.add_child(light)
	for k in 10:
		await process_frame
	var hexes := []
	var field := {}
	for q in range(-7, 8):
		for r in range(-7, 8):
			if absi(q + r) <= 7:
				hexes.append({"q": q, "r": r})
				if absi(q + r) <= 6 and absi(q) <= 6 and absi(r) <= 6 and (q * 7 + r * 3) % 4 == 0:
					field["%d,%d" % [q, r]] = "hulk"
	var rules := Rules.new()
	rules.v = {"hexes": hexes, "terrain": field, "units": [], "map": {"holes": []}}
	rules.w = {"seed": 11, "biome": {"rock": "iron", "planet": 5, "station": "spire"}}
	var board: Node3D = BOARD.new()
	root.add_child(board)
	var t0 := Time.get_ticks_usec()
	board.build(rules)
	var t1 := Time.get_ticks_usec()
	if DisplayServer.get_name() == "headless":
		await process_frame   # no draw signal without a renderer (a cloud parse run)
	else:
		await RenderingServer.frame_post_draw
	var t2 := Time.get_ticks_usec()
	for k in 30:
		await process_frame
	var hulks := 0
	for n in board.find_children("*", "MeshInstance3D", true, false):
		if n.get_parent() != null and n.get_parent().get_parent() != null and String(n.get_parent().get_parent().name) == "Terrain":
			hulks += 1
	var ws := -1.0
	if OS.get_name() == "Windows":
		var out: Array = []
		var code := OS.execute("powershell", ["-NoProfile", "-Command", "(Get-Process -Id %d).PeakWorkingSet64" % OS.get_process_id()], out, true)
		if code == 0 and not out.is_empty():
			ws = float(str(out[0]).strip_edges()) / 1048576.0
	print("GRAVEYARD_LOAD build_ms=%.1f first_frame_ms=%.1f process_ms=%d static_peak_mb=%.1f video_mb=%.1f peak_ws_mb=%.1f hulk_meshes=%d adapter=%s" % [
		(t1 - t0) / 1000.0, (t2 - t1) / 1000.0, Time.get_ticks_msec(), OS.get_static_memory_peak_usage() / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, ws, hulks, RenderingServer.get_video_adapter_name()])
	quit(0)
