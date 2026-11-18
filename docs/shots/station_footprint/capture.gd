# Issue 983: a top-down picture of the big map station and its 19-hex footprint.
# Needs a game build with the installed ship and gen assets. Copy this script to res://tools/ in that build, then run:
#   godot --path godot --script res://tools/capture_station_983.gd -- <out dir> --map station --obj defend --seed 983
# The script instantiates the battle scene itself; it focuses the defend objective hex (the station centre),
# swings the camera top-down and saves one PNG.
extends SceneTree
const PG := preload("res://render/placeholder_guard.gd")

var dir := ""


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	dir = a[0] if a.size() > 0 else "user://station_footprint"
	DirAccess.make_dir_recursive_absolute(dir)
	var b = load("res://scenes/battle/battle.tscn").instantiate()
	root.add_child(b)
	_run(b)


func _frames(n: int) -> void:
	for i in range(n):
		await process_frame


func _run(b) -> void:
	var t0 := Time.get_ticks_msec()
	while (b.api == null or b.board == null or b.busy or b.warming) and Time.get_ticks_msec() - t0 < 120000:
		await process_frame
	await _frames(10)
	var o = b.V.get("obj")
	if o is Dictionary and o.get("hex") is Dictionary:
		var c = o["hex"]
		b.cam.focus(b.board.hex_world(c.q, c.r), 270.0)
	if not b.cam.topdown:
		b.cam.toggle_top()
	b.cam.snap()
	await _frames(30)
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png(dir.path_join("station_topdown.png"))
	print("shot station_topdown")
	PG.finish(0)
