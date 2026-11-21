extends SceneTree
## Issue 1399 (R367, full faction deaths). Look bench stills of ship deaths per faction, on the shipped look bench
## (read-only, as contrib/opus/flagship_death_1077/capture.gd): each target at stage 4 damage, then killed, at the
## battle camera (radius 170) and a close camera (0.62 of the ship's length). The game's own settings: the strained
## one-crack death on (rendering/effects/death_story default), quality max, Forward+.
## Arguments after --: scratch directory, then a comma list of hull ids (default below), then a tag (before|after), then
## optionally "burst": the close camera only, a frame every 1/15 s from the kill to half a second after the split (f000.jpg
## on), for the moves that fall between the five stills (the Sunward magazine row in the tell, the Hegemony arcs at the split).
## Output per target and radius: <scratch>/<tag>_<id>_c<r>/<moment>.png (stamped) and <moment>_sheet.jpg (960x540), and
## <scratch>/<tag>_capture.json with the commit, renderer and every still's fx time. Nothing outside <scratch> is written.
## Run with --fixed-fps 60 at 1920x1080, Forward+, through the canonical watchdog tmo.bat.

class Bench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func death_ship(id: String, spec: Dictionary, pos: Vector3):
		var view = SV.new()
		view.name = "ship_" + id
		world.add_child(view)
		view.setup({"id": id, "fac": spec.fac, "cls": spec.cls, "size": spec.size, "facing": 0,
			"hp": spec.hp, "maxHp": spec.hp}, pos, true)
		view.set_process(false)
		if not view.a4 or _is_block(view):
			return null
		fx.add_ship(id, view, {"faction": spec.fac, "cls": spec.cls, "code": view.code,
			"size": spec.size, "flagship": spec.get("boss", false)})
		view.fx_engines = true
		fx.set_engine(id, 0.3)
		fx.sync_ship(id, _unit(1.0, 0))
		return view

const API := preload("res://rules/battle_api.gd")
const CAP := preload("res://tools/picture_provenance.gd")
# Glasswrights and Eclipse (round 1 of R367), small, cruiser and capital; A16 as the shared-fire reference
const TARGETS := "i_wisp,i_song,i_boss,d_scythe,d_harvester,d_boss,c_boss"

var bench: Bench
var out: String
var tag: String
var failed := false
var hulls: Dictionary
var info: Dictionary
var burst := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		push_error("CAPTURE1399 usage: -- <scratch> [ids] [tag]")
		quit(2)
		return
	out = args[0]
	var ids := (args[1] if args.size() > 1 else TARGETS).split(",", false)
	tag = args[2] if args.size() > 2 else "before"
	burst = args.size() > 3 and args[3] == "burst"
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Bench.BL.set_look("cine", false)
	var api = API.new()
	if api.load_rules() != "":
		_fail("Could not read shipped hull rules")
		quit(2)
		return
	hulls = api.R.HULLS
	bench = Bench.new()
	root.add_child(bench)
	bench.out = out
	bench._setup_view()
	bench._cam(Vector3.ZERO, 170.0)
	await bench._world({"rock": "stone", "planet": 4}, {}, [])
	info = {"tag": tag, "commit": _commit(), "ship_manifest_sha256": FileAccess.get_sha256("res://assets/ships/manifest.json"),
		"adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"godot": Engine.get_version_info().string, "targets": {}}
	print("CAPTURE1399 ", JSON.stringify(info))
	for id in ids:
		if not hulls.has(id):
			_fail("no hull " + id)
			continue
		for r in ([0] if burst else [170, 0]):
			await _clip(id, r)
	_write(tag + "_capture.json", info, out)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1399 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _commit() -> String:
	var f := FileAccess.get_file_as_string("res://build_info.json")
	var j = JSON.parse_string(f) if not f.is_empty() else null
	return str(j.get("commit", "")) if j is Dictionary else ""


func _fail(message: String) -> void:
	failed = true
	push_error("CAPTURE1399 " + message)


# radius 0: the close camera, 0.62 of the ship's length (A16's 26 in issue 1077)
func _clip(id: String, radius: int) -> void:
	bench._clear()
	bench._make_fx()
	bench._cam(Vector3.ZERO, 170.0)
	bench.fx.rng.seed = 11
	seed(2070)
	var spec: Dictionary = hulls[id]
	var v = bench.death_ship("T", spec, Vector3.ZERO)
	if v == null:
		_fail("%s drew a block or no installed hull" % id)
		return
	var s = bench.fx.ship("T")
	var L: float = s.hull.L
	var r: float = float(radius) if radius > 0 else maxf(L * 0.62, 6.0)
	bench._cam(Vector3.ZERO, r)
	var folder := out.path_join("%s_%s_c%d" % [tag, id, int(round(r))])
	DirAccess.make_dir_recursive_absolute(folder)
	await bench.fx.warmup(bench.cam)
	bench.fx.sync_ship("T", bench._unit(0.199, 0))
	var t_wait := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t_wait < 120000:
		await bench._step()
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	for i in 60: await bench._step()
	bench.fx.rng.seed = 11
	seed(2070)
	var start: float = bench.fx.now
	bench.fx.death("T", "blast")
	var split: float = float(s.get_meta("death_split", start + 0.72))
	var core: float = bench.fx.death_core_at("T") if bench.fx.has_method("death_core_at") else split
	var marks := {"tell": lerpf(start, split, 0.6), "split": split + 0.05, "core": maxf(core, split) + 0.08,
		"wreck": split + 1.5, "settled": split + 4.0}
	if burst:
		marks = {}
		var k := 0
		while start + float(k) / 15.0 <= split + 0.5:
			marks["f%03d" % k] = start + float(k) / 15.0
			k += 1
		marks["settled"] = split + 0.55
	var row := {"id": id, "fac": spec.fac, "cls": spec.cls, "code": v.code, "L": L, "radius": r, "kill_at": start, "split_at": split,
		"core_at": core, "stills": {}}
	while bench.fx.now < float(marks.settled) + 0.05:
		await bench._step()
		for key in marks:
			if not row.stills.has(key) and bench.fx.now >= float(marks[key]):
				var img: Image = bench._grab()
				if img == null or (not burst and CAP.save_png(img, folder.path_join(key + ".png")) != OK):
					_fail("could not save %s %s" % [id, key])
					continue
				var small: Image = bench._crop(img, Vector2i(960, 540), Vector2i(960, 540)) if radius == 170 else img.duplicate()
				if radius != 170: small.resize(960, 540, Image.INTERPOLATE_LANCZOS)
				small.save_jpg(folder.path_join(key + "_sheet.jpg"), 0.9)
				row.stills[key] = bench.fx.now - start
	info.targets["%s_c%d" % [id, int(round(r))]] = row
	print("CAPTURE1399 ", id, " ", spec.fac, " ", spec.cls, " code=", v.code, " r=", r, " split=%.2f" % (split - start))


func _write(file: String, data: Variant, directory: String) -> void:
	var output := FileAccess.open(directory.path_join(file), FileAccess.WRITE)
	if output == null:
		_fail("Could not write " + file)
		return
	output.store_string(JSON.stringify(data, "  ") + "\n")
