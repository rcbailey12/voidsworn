extends SceneTree
## Issue 1394 (R398, Ryan's acid death pick B). Look bench stills of acid (melt) kills on the new hulls, adapted from
## contrib/opus/faction_death_1399/capture.gd: each target at stage 4 damage, hit by acid at two points on its top plating
## (recorded as fx_weapons records them, "acid_spots"), then killed with cause "melt", at the battle camera (radius 170)
## and a close camera (0.62 of the ship's length). The same script runs on main (tag before: today's melt) and on the
## PR (tag after). Arguments after --: scratch directory, then a comma list of hull ids (default below), then the tag.
## Output per target and radius: <scratch>/<tag>_<id>_c<r>/<moment>.png and <moment>_sheet.jpg (960x540), and
## <scratch>/<tag>_capture.json. Nothing outside <scratch> is written. Run with --fixed-fps 60 at 1920x1080, Forward+.

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
const TARGETS := "warden,penitent,d_harvester,c_raider,h_dominion"   # new hulls: Sunward frigate and cruiser, Eclipse cruiser, Hullbreaker frigate, Navy battleship

var bench: Bench
var out: String
var tag: String
var failed := false
var hulls: Dictionary
var info: Dictionary
var burst := false
var drift := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 1:
		push_error("CAPTURE1394 usage: -- <scratch> [ids] [tag]")
		quit(2)
		return
	out = args[0]
	var ids := (args[1] if args.size() > 1 else TARGETS).split(",", false)
	tag = args[2] if args.size() > 2 else "before"
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
	print("CAPTURE1394 ", JSON.stringify(info))
	for id in ids:
		if not hulls.has(id):
			_fail("no hull " + id)
			continue
		for r in ([0] if burst else ([-1] if drift else [170, 0, -2])):
			await _clip(id, r)
	_write(tag + "_capture.json", info, out)
	bench._clear()
	bench.queue_free()
	await process_frame
	Bench.FX.clear_static()
	Bench.SV.clear_static()
	print("CAPTURE1394 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _commit() -> String:
	var f := FileAccess.get_file_as_string("res://build_info.json")
	var j = JSON.parse_string(f) if not f.is_empty() else null
	return str(j.get("commit", "")) if j is Dictionary else ""


func _fail(message: String) -> void:
	failed = true
	push_error("CAPTURE1394 " + message)


# radius 0: the close camera, 0.62 of the ship's length (A16's 26 in issue 1077). Radius -2 (Wave 0, Fable and Astra Nov 23):
# a grazing camera, 0.9 of the length away and about 10 degrees above the top plating, a few frames through the tell, so
# the acid patch is seen etched into the armour and moving with it, not floating over it.
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
	var grazing := radius == -2
	var r: float = float(radius) if radius > 0 else (maxf(L * 0.9, 8.0) if grazing else (maxf(L * 4.0, 24.0) if radius < 0 else maxf(L * 0.62, 6.0)))
	bench._cam(Vector3.ZERO, r)
	if grazing:
		bench.cam.b = 0.18
		bench.cam.snap()
	var view := "%s_%s_%s%d" % [tag, id, "g" if grazing else "c", int(round(r))]
	var folder := out.path_join(view)
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
	# the acid hits: two points on the top plating, a third and two thirds along, where the battle camera sees them
	var spots := []
	for u in [0.33, 0.66]:
		var x: float = s.hull.box.position.x + u * L
		var hit: Dictionary = s.hull.ray(Vector3(x, s.hull.c.y + L, s.hull.c.z), Vector3.DOWN)
		if not hit.is_empty(): spots.append([hit["p"], bench.fx.now])
	s.set_meta("acid_spots", spots)
	var start: float = bench.fx.now
	bench.fx.death("T", "melt")
	var split: float = float(s.get_meta("death_split", start + 0.72))
	var core: float = bench.fx.death_core_at("T") if bench.fx.has_method("death_core_at") else split
	var marks := {"tell": lerpf(start, split, 0.6), "split": split + 0.05, "core": maxf(core, split) + 0.08,
		"wreck": split + 1.5, "settled": split + 4.0}
	if grazing:
		marks = {"tell1": lerpf(start, split, 0.2), "tell2": lerpf(start, split, 0.45), "tell3": lerpf(start, split, 0.7),
			"tell4": lerpf(start, split, 0.95), "split": split + 0.3, "settled": split + 1.5}
	if burst:
		marks = {}
		var k := 0
		while start + float(k) / 15.0 <= split + 0.5:
			marks["f%03d" % k] = start + float(k) / 15.0
			k += 1
		marks["settled"] = split + 0.55
	if drift:
		marks = {}
		var k := 0
		while float(k) / 6.0 <= 9.0:
			marks["f%03d" % k] = start + float(k) / 6.0
			k += 1
		marks["settled"] = start + 9.05
	var row := {"id": id, "fac": spec.fac, "cls": spec.cls, "code": v.code, "L": L, "radius": r, "kill_at": start, "split_at": split,
		"core_at": core, "stills": {}}
	while bench.fx.now < float(marks.settled) + 0.05:
		await bench._step()
		for key in marks:
			if not row.stills.has(key) and bench.fx.now >= float(marks[key]):
				var img: Image = bench._grab()
				if img == null or (not burst and not drift and CAP.save_png(img, folder.path_join(key + ".png"), _stage()) != OK):
					_fail("could not save %s %s" % [id, key])
					continue
				var small: Image = bench._crop(img, Vector2i(960, 540), Vector2i(960, 540)) if radius == 170 else img.duplicate()
				if radius != 170: small.resize(960, 540, Image.INTERPOLATE_LANCZOS)
				# Artoo on PR 1522: a sheet that could not be written fails the run, never a capture JSON naming a missing image
				if small.save_jpg(folder.path_join(key + "_sheet.jpg"), 0.9) != OK or not FileAccess.file_exists(folder.path_join(key + "_sheet.jpg")):
					_fail("could not save %s %s sheet" % [id, key])
					continue
				row.stills[key] = bench.fx.now - start
	info.targets[view.trim_prefix(tag + "_")] = row
	print("CAPTURE1394 ", id, " ", spec.fac, " ", spec.cls, " code=", v.code, " r=", r, " split=%.2f" % (split - start))


func _write(file: String, data: Variant, directory: String) -> void:
	var output := FileAccess.open(directory.path_join(file), FileAccess.WRITE)
	if output == null:
		_fail("Could not write " + file)
		return
	output.store_string(JSON.stringify(data, "  ") + "\n")


# Artoo on PR 1583: the stage comes from the shared renderer check (issue 1567). The old pin (b1addd66) predates
# capture_stage(), so there the same check is made here: only a forward_plus render on a real adapter is "installed in
# game"; anything else is a "cloud direction check".
func _stage() -> String:
	var pp: Script = CAP
	for m in pp.get_script_method_list():
		if str(m.get("name", "")) == "capture_stage":
			return str(pp.call("capture_stage"))
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		return "cloud direction check"
	var adapter := (RenderingServer.get_video_adapter_name() + " " + RenderingServer.get_video_adapter_vendor()).to_lower()
	for soft in ["llvmpipe", "lavapipe", "swiftshader", "software", "mesa offscreen"]:
		if adapter.contains(soft):
			return "cloud direction check"
	return "installed in game"
