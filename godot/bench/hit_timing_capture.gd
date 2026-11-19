extends SceneTree
# Issue 1211 pictures (PC only, needs a window and the PC-built hulls). One enemy volley at your ship, in a nebula or in
# clear space, at whatever --resolution the run was started with (1920x1080 or 3840x2160). It stamps each still with its
# revision (tools/picture_provenance.gd), so a main run and a branch run are told apart on the picture itself.
#   godot --path godot --rendering-method forward_plus --fixed-fps 60 --disable-vsync --windowed --resolution 1920x1080
#         --script res://bench/hit_timing_capture.gd -- --out DIR [--case nebula|clear] [--frames]
# --frames also saves every frame of the volley (frame_###.png) for a short clip; with Godot's --write-movie the same
# run records the clip directly. Stills: <case>_<height>p_<n>.png at fixed effect times after the volley starts.
# Uses only battle.gd entry points main already has (_begin, _play_fire), so the same file runs on main for "before".

const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const Battle := preload("res://scenes/battle/battle.gd")
const PROV := preload("res://tools/picture_provenance.gd")
const AT := [0.15, 0.3, 0.45, 0.6, 0.8, 1.05, 1.4]   # effect seconds after the volley starts

var args := {}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		if a[i].begins_with("--"):
			var k := a[i].substr(2)
			if i + 1 < a.size() and not a[i + 1].begins_with("--"):
				args[k] = a[i + 1]
				i += 1
			else:
				args[k] = true
		i += 1
	_run.call_deferred()


func _run() -> void:
	OS.set_environment("VS_NEBULA_ROUTE", "fog")
	LOOK.set_look("cine", false)
	var out := str(args.get("out", "user://hit_timing_capture"))
	DirAccess.make_dir_recursive_absolute(out)
	var kase := str(args.get("case", "nebula"))
	var api := API.new()
	var err := api.load_rules()
	if err != "":
		printerr("HIT_CAPTURE failed: ", err)
		quit(1)
		return
	api.new_battle_scenario("s1", 1211)
	var terrain: Dictionary = api.R.B["terrain"]
	terrain.clear()
	var me: Dictionary = api.R.alive("player")[0]
	var foe: Dictionary = api.R.alive("enemy")[0]
	me.merge({"q": 2, "r": 6, "facing": 0}, true)
	foe.merge({"q": 5, "r": 6, "facing": 3}, true)
	if kase == "nebula":
		for q in range(0, 8):
			for r in range(4, 9):
				terrain["%d,%d" % [q, r]] = "neb"
	var b: Battle = Battle.new()
	b.args["quality"] = "max"
	b.cine = "off"
	b.follow = false
	root.add_child(b)
	await b._begin(api)
	var a_id := str(foe["id"])
	var t_id := str(me["id"])
	var mid: Vector3 = (b._pos(a_id) + b._pos(t_id)) * 0.5
	b.cam.t = mid
	b.cam.r = 60.0
	b.cam.snap()
	for f in 120:
		await process_frame
	# the enemy's real first gun, three shots: miss, miss, hit (the case the old timing got wrong)
	var w: Dictionary = (api.unit(a_id)["weapons"] as Array)[0]
	var e := {"t": "fire", "unit": a_id, "target": t_id, "kind": str(w.get("k", "battery")), "name": str(w.get("name", "gun")),
		"weapon": 0, "weapon_id": str(w.get("id", "")), "shots": [false, false, true], "quad": 0, "pd": 0}
	var grp := [{"t": "hit", "unit": a_id, "target": t_id, "quad": 0, "section": "mid", "shield": 0, "hull": 7, "crit": false}]
	# the enemy's activation ring, as the battle draws it
	if b.views.has(a_id):
		b.views[a_id].set_selected(true, Color(0.79, 0.64, 1.0))
	var t0 := float(b.gfx.now) if b.gfx != null else 0.0
	b._play_fire(e, grp)
	var h := get_root().size.y
	var n := 0
	var frame := 0
	var stills := 0
	var frames_ok := 0
	var failed := 0
	while n < AT.size() and frame < 900:
		await process_frame
		frame += 1
		var now := (float(b.gfx.now) if b.gfx != null else float(frame) / 60.0) - t0
		var due := now >= float(AT[n])
		if not args.has("frames") and not due:
			continue
		var img: Image = get_root().get_texture().get_image()
		if img == null or img.is_empty():
			continue   # (no picture this frame: a due still waits for the next drawn frame, it is never skipped)
		if args.has("frames"):
			if PROV.save_png(img, out.path_join("%s_%dp_frame_%03d.png" % [kase, h, frame])) == OK:
				frames_ok += 1
			else:
				failed += 1
		if due:
			if PROV.save_png(img, out.path_join("%s_%dp_%d_t%03d.png" % [kase, h, n, int(round(float(AT[n]) * 100.0))])) == OK:
				stills += 1
			else:
				failed += 1
			n += 1
	# Artoo (PR 1220): only real, written stills count; a missing or failed still fails the run
	if stills == AT.size() and failed == 0:
		print("HIT_CAPTURE_DONE case %s height %d stills %d of %d frames %d" % [kase, h, stills, AT.size(), frames_ok])
		quit(0)
	else:
		printerr("HIT_CAPTURE_FAILED case %s height %d stills %d of %d, failed writes %d (headless draws no pictures)" % [kase, h, stills, AT.size(), failed])
		quit(1)
