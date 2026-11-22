extends SceneTree
## Issue 1076. Read-only adapter for the shipped look bench and battle effects.
## Arguments after --: ships.json, scratch directory, close radius, [ship id|storm], [probe|close].

class Bench extends "res://bench/look_bench.gd":
	func _ready() -> void:
		pass

	func story_ship(id: String, spec: Dictionary, pos: Vector3):
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
		fx.sync_ship(id, _unit(1.0, 5 if spec.sh > 0 else 0))
		return view

const API := preload("res://rules/battle_api.gd")
const CAP := preload("res://tools/picture_provenance.gd")
const STORM_SCENE := preload("res://scenes/battle/battle.tscn")
const GUARD := preload("res://render/placeholder_guard.gd")

var bench: Bench
var out: String
var folder: String
var frame_number: int
var row: Dictionary
var failed := false
var probe_only := false
var installed_scenes: Array[PackedScene] = []
var rules_hulls: Dictionary


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		quit(2)
		return
	var list: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://build_info.json"))
	if info.commit != list.source_commit or FileAccess.get_sha256("res://assets/ships/manifest.json") != list.manifest_sha256:
		_fail("The project revision or ship manifest differs from issue 1070")
		quit(2)
		return
	out = args[1]
	DirAccess.make_dir_recursive_absolute(out)
	Engine.max_fps = 0
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Bench.BL.set_look("cine", false)
	var only := args[3] if args.size() > 3 else ""
	var mode := args[4] if args.size() > 4 else ""
	probe_only = mode == "probe"
	var api = API.new()
	if api.load_rules() != "":
		_fail("Could not read shipped hull rules")
		quit(2)
		return
	rules_hulls = api.R.HULLS
	if only == "storm":
		if _use_installed_scene(list.subjects[0]):
			await _storm(list.subjects[0])
	else:
		bench = Bench.new()
		root.add_child(bench)
		bench.out = out
		bench._setup_view()
		bench._cam(Vector3.ZERO, 170.0)
		await bench._world({"rock": "stone", "planet": 4}, {}, [])
		for subject in list.subjects:
			if only not in ["", "all"] and not only.split(",").has(subject.id):
				continue
			if not _use_installed_scene(subject):
				break
			for radius in ([int(args[2])] if mode == "close" else [170, int(args[2])]):
				for reduced in ([false] if probe_only else [false, true]):
					await _story(subject, radius, reduced)
					if failed:
						break
				if failed:
					break
			if failed:
				break
		bench._clear()
		bench.queue_free()
		await process_frame
		Bench.FX.clear_static()
		Bench.SV.clear_static()
	print("BATTLE_BASELINE1076 ", "FAILED" if failed else "DONE")
	quit(1 if failed else 0)


func _fail(message: String) -> void:
	failed = true
	push_error("BATTLE_BASELINE1076 " + message)


func _use_installed_scene(subject: Dictionary) -> bool:
	var path: String = Bench.SV.manifest().get("ships", {}).get(subject.code, {}).get("res", "")
	if path.is_empty():
		_fail("No packed ship scene for " + str(subject.id))
		return false
	if FileAccess.get_sha256(path) == subject.scene_sha256:
		return true
	# The performance snapshot predates the Eclipse paint cache refresh.
	# Load the shared scene without writing to either project or changing ShipView's lookup.
	var shared := OS.get_environment("BATTLE1076_INSTALLED_PROJECT")
	if shared.is_empty():
		shared = OS.get_environment("USERPROFILE").path_join("Downloads/voidsworn_test/build/godot")
	var external := shared.path_join(path.trim_prefix("res://"))
	if FileAccess.get_sha256(external) != subject.scene_sha256:
		_fail("Installed packed scene SHA256 mismatch for " + str(subject.id))
		return false
	var scene := ResourceLoader.load(external) as PackedScene
	if scene == null:
		_fail("Cannot open installed packed scene for " + str(subject.id))
		return false
	scene.take_over_path(path)
	installed_scenes.append(scene)
	print("BATTLE_BASELINE1076 shared installed scene ", subject.code, " ", subject.scene_sha256)
	return true


func _story(subject: Dictionary, radius: int, reduced: bool) -> void:
	var variant := "reduced" if reduced else "standard"
	folder = out.path_join("%s_c%d_%s" % [subject.id, radius, variant])
	DirAccess.make_dir_recursive_absolute(folder)
	frame_number = 0
	row = {"subject": subject, "radius": radius, "reduced": reduced, "stills": {}, "chapters": [], "stages": []}
	if not probe_only:
		await _set_scene(subject, radius, reduced, "egg")
		if failed:
			return
		await _shot("egg", "battery", subject.shielded, 0.75, 0.06)
	await _set_scene(subject, radius, reduced, "fitted")
	if failed:
		return
	await _shot("fitted", "battery", subject.shielded, 0.52, 0.06)
	_chapter("failure")
	if subject.shielded:
		bench.fx.shield_break("T", 3)
	bench.fx.sync_ship("T", bench._unit(1.0, 0))
	await _hold(1.4, "failure", 0.18)
	await _shot("macro", "battery", false, 0.9, 0.05)
	await _shot("lance", "lance", false, 1.2, 0.09)
	var target = bench.fx.ship("T")
	for stage in range(1, 5):
		var key := "stage%d" % stage
		_chapter(key)
		bench.fx.sync_ship("T", bench._unit(1.0 - 0.2 * stage - 0.001, 0))
		await _hold(0.85 if stage < 4 else 1.7, key, 0.6)
		row.stages.append(target.stage.duplicate())
		if target.stage != [stage, stage, stage]:
			_fail("Wrong hull damage stage: %s" % str(target.stage))
			return
	row["stage4_breaches"] = _probe_breaches(target)
	if probe_only:
		_write("breach_probe.json", row, folder)
		return
	await _shot("fatal", "torp", false, 0.14, 0.04)
	_chapter("tell")
	var start: float = bench.fx.now
	bench.fx.death("T", "big")
	var core: float = bench.fx.death_core_at("T")
	var split: float = float(target.get_meta("death_split", start + 2.0))
	var duration: float = float(target.get_meta("death_timeline").cool) if target.has_meta("death_timeline") else 14.0
	var marks := {"tell": start + 1.22, "split": split + 0.18, "core": core + 0.08, "wreck": split + 3.8, "cold": split + duration}
	while bench.fx.now < float(marks.cold) + 0.12:
		await _step(bench.fx.now < split + 4.3 or bench.fx.now >= float(marks.cold) - 0.9)
		for key in marks:
			if not row.stills.has(key) and bench.fx.now >= float(marks[key]):
				if key in ["split", "wreck", "cold"]:
					_chapter(key)
				_still(key)
	row["frames"] = frame_number
	_write("timeline.json", row, folder)
	print("BATTLE_BASELINE1076 ", subject.id, " r", radius, " ", variant, " frames=", frame_number)


func _set_scene(subject: Dictionary, radius: int, reduced: bool, shape: String) -> void:
	bench._clear()
	OS.set_environment("VS_SHIELD_SHAPE", shape)
	bench._make_fx()
	bench.fx.reduce_flashing = reduced
	var focus_x := 0.0 if radius == 170 else float(subject.get("close_focus_x", 0.0))
	bench._cam(Vector3(focus_x, 0, 0), radius)
	bench.fx.rng.seed = 11
	seed(2070)
	bench.A = bench.story_ship("A", rules_hulls["penitent"], Vector3(-35.0, 0, 18.0))
	bench.T = bench.story_ship("T", rules_hulls[subject.rules_id], Vector3.ZERO)
	if bench.A == null or bench.T == null or not bench.T.a4 or bench.T.code != subject.code:
		_fail("Wrong ship or placeholder for %s" % subject.id)
		return
	var sh = bench.fx.ship("T")
	if sh.shielded != subject.shielded or (sh._shield_tm != null) != (subject.shielded and shape == "fitted"):
		_fail("%s did not build the requested %s shield" % [subject.id, shape])
		return
	if not subject.shielded:
		bench.fx.sync_ship("T", bench._unit(1.0, 0))
	if not sh.hull.authored:
		_fail("%s did not load authored seams" % subject.id)
		return
	await bench.fx.warmup(bench.cam)
	for i in 60:
		await bench._step()
	# Approaching from the visible broadside keeps the contact on the side facing the camera.
	bench.fx.rng.seed = 11
	seed(2070)


func _shot(key: String, weapon: String, shielded: bool, life: float, still_offset: float) -> void:
	_chapter(key)
	var at: float = bench.fx.now
	var kind := "battery" if weapon == "battery" else weapon
	var result: Dictionary = bench.fx.volley("A", kind, "T", {"weapon_id": weapon, "shots": [true], "quad": 3,
		"hits": [{"shield": 8 if shielded else 0, "hull": 0 if shielded else (40 if key == "fatal" else 9), "section": "mid"}]})
	if result.impacts.is_empty():
		_fail("Volley had no impact: " + key)
		return
	var until: float = at + float(result.impacts[0]) - bench.fx.now
	await _hold(until + life, key, until + still_offset)


func _hold(seconds: float, key: String, still_offset: float) -> void:
	var start: float = bench.fx.now
	while bench.fx.now < start + seconds:
		await _step(true)
		if not row.stills.has(key) and bench.fx.now >= start + still_offset:
			_still(key)


func _step(record: bool) -> void:
	await bench._step()
	if record and not probe_only and bench.steps % 2 == 0:
		var img: Image = bench._grab()
		if img == null:
			_fail("GPU produced an empty frame")
			return
		if row.radius == 170:
			img = bench._crop(img, Vector2i(1280, 720), Vector2i(1280, 720))
		else:
			img.resize(1280, 720, Image.INTERPOLATE_BILINEAR)
		if img.save_jpg(folder.path_join("frame_%04d.jpg" % frame_number), 0.92) != OK:
			_fail("Could not save a clip frame")
		frame_number += 1


func _chapter(key: String) -> void:
	row.chapters.append({"name": key, "frame": frame_number, "fx_time": bench.fx.now})


func _still(key: String) -> void:
	if probe_only:
		row.stills[key] = {"fx_time": bench.fx.now}
		return
	var image: Image = bench._grab()
	if image == null or CAP.save_png(image, folder.path_join(key + ".png"), CAP.capture_stage()) != OK:
		_fail("Could not stamp the " + key + " still")
		return
	row.stills[key] = {"frame": frame_number, "fx_time": bench.fx.now}


func _probe_breaches(sh) -> Array:
	# Count visible authored triangles through each opening from this camera.
	# Compare first hits on the damaged and original plating to rule out exposed edges.
	var faces := {"inside": PackedVector3Array(), "skin": PackedVector3Array(), "original": PackedVector3Array()}
	for surface in sh._orig:
		var mesh: MeshInstance3D = surface["mi"]
		var si: int = surface["si"]
		var key := "inside" if surface.interior else "skin"
		_append_faces(faces[key], mesh.mesh.surface_get_arrays(si), mesh.global_transform)
		if key == "skin":
			_append_faces(faces.original, surface.arrays, mesh.global_transform)
	var inside := TriangleMesh.new()
	var skin := TriangleMesh.new()
	var original := TriangleMesh.new()
	if faces.inside.is_empty() or faces.skin.is_empty() or faces.original.is_empty():
		_fail("Stage 4 interior ray test could not build a mesh")
		return []
	inside.create_from_faces(faces.inside)
	skin.create_from_faces(faces.skin)
	original.create_from_faces(faces.original)
	var verdict := []
	for entries in sh._ents:
		for e in entries:
			if e.kind != Bench.FX.BREACH.K_HOLE:
				continue
			var point: Vector3 = sh.to_world(e.c)
			var screen: Vector2 = bench.cam.unproject_position(point)
			var edge: Vector2 = bench.cam.unproject_position(point + sh.dir_world(e.t1) * e.R)
			if bench.cam.is_position_behind(point):
				continue
			var span := maxf(3.0, screen.distance_to(edge) * 1.3)
			var exposed := 0
			for y in range(-8, 9):
				for x in range(-8, 9):
					var pixel := screen + Vector2(x, y) * span / 8.0
					if not bench.vp.get_visible_rect().has_point(pixel):
						continue
					var origin: Vector3 = bench.cam.project_ray_origin(pixel)
					var dir: Vector3 = bench.cam.project_ray_normal(pixel)
					var i: Dictionary = inside.intersect_ray(origin, dir)
					if i.is_empty():
						continue
					var s: Dictionary = skin.intersect_ray(origin, dir)
					var o: Dictionary = original.intersect_ray(origin, dir)
					var d: float = origin.distance_squared_to(i.position)
					if not o.is_empty() and d > origin.distance_squared_to(o.position) and (s.is_empty() or d < origin.distance_squared_to(s.position)):
						exposed += 1
			verdict.append({"section": e.sec, "screen": [screen.x, screen.y], "visible_rays": exposed})
	return verdict


func _append_faces(faces: PackedVector3Array, arrays: Array, xf: Transform3D) -> void:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	if indices == null or indices.is_empty():
		for vertex in vertices:
			faces.append(xf * vertex)
	else:
		for index in indices:
			faces.append(xf * vertices[index])


func _write(file: String, data: Variant, directory: String) -> void:
	var output := FileAccess.open(directory.path_join(file), FileAccess.WRITE)
	if output == null:
		_fail("Could not write " + file)
		return
	output.store_string(JSON.stringify(data, "  ") + "\n")


func _storm(subject: Dictionary) -> void:
	# Issue 982 and issue 1070 use this real seed and nebula condition.
	var scenario := {"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["penitent", "harrow", "warden", "warden"],
		"fac": "ithar", "obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}
	var api = API.new()
	if api.load_rules() != "":
		_fail("Storm rules did not load")
		return
	api.new_battle_scenario(scenario, 4103)
	api.R.B.terrain = api.R.genTerrain("storm", "open", {"cond": {"terr": "neb"}})
	api.R.B.map = api.R.TERRAIN_META.duplicate(true)
	api.R.B.biome = {"rock": "ice", "planet": 7, "station": "ring"}
	var battle = STORM_SCENE.instantiate()
	battle.external = true
	battle.args["quality"] = "max"
	battle.args["no-tips"] = true
	root.add_child(battle)
	battle.args["shots"] = true
	battle.tips_off = true
	battle.battle_cfg = scenario
	battle.begin_with(api)
	var deadline := Time.get_ticks_msec() + 120000
	while battle.warming or battle.busy:
		if Time.get_ticks_msec() > deadline:
			_fail("Storm warm-up timed out")
			return
		await process_frame
	if GUARD.stop_if_any():
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i.ZERO
	root.scaling_3d_scale = 1.0
	battle.hud.visible = false
	battle.set_process(false)
	battle.gfx.manual = true
	battle._make_view({"id": "reference", "fac": subject.fac, "cls": subject.cls, "facing": 0,
		"q": 0, "r": 0, "side": "enemy", "hp": 100.0, "maxHp": 100.0, "sh": [5, 5, 5, 5],
		"size": rules_hulls[subject.rules_id].size, "squadron": false, "flagship": true})
	var reference = battle.views["reference"]
	if not reference.a4 or reference.code != subject.code:
		_fail("Storm reference ship did not load its installed hull")
		return
	for ship in battle.views.values():
		ship.set_process(false)
		if ship.squad_kind.is_empty():
			ship.hull.position = ship.hull_base
	battle.cam.screen_shift = 0.0
	battle.cam.set_process(false)
	battle.world.set_process(false)
	var living = battle.world._living
	living.set_process(false)
	for burst in living._storm_bursts:
		burst.next = INF
	var centers := []
	for patch in living._storm_patches:
		var center := Vector3.ZERO
		for point in patch.points:
			center += point
		center /= float(patch.points.size())
		var focus: Vector3 = patch.points[0]
		for point in patch.points:
			if point.distance_squared_to(center) < focus.distance_squared_to(center):
				focus = point
		var closest: Dictionary = living.bolts[0]
		for bolt in living.bolts:
			if bolt.pos.distance_squared_to(focus) < closest.pos.distance_squared_to(focus):
				closest = bolt
		centers.append({"hexes": patch.points.size(), "focus": [focus.x, focus.z]})
		reference.position = focus
		battle.cam.a = -PI / 2.0
		battle.cam.b = 0.98
		battle.cam.r = 170.0
		battle.cam.t = focus.lerp(closest.pos, 0.5)
		battle.cam.snap()
		for state in ["calm", "lightning", "tick", "reduced"]:
			battle.set_fx_opts(state == "reduced", 0.0)
			living.clock = 0.08
			for record in battle.floats:
				record.lbl.queue_free()
			battle.floats.clear()
			for bolt in living.bolts:
				bolt.start = -10.0
				bolt.soft = false
			for p in living._storm_patches:
				p.tick = 0.0
			if state == "lightning" or state == "reduced":
				closest.start = living.clock - (0.24 if state == "reduced" else 0.025)
			elif state == "tick":
				battle._float_at(focus, "Ion storm", Color("#9fd4ff"), -24.0)
			living._process(0.0)
			if state == "tick" and float(patch.tick) <= 0.0:
				_fail("Storm tick did not reach the gas in patch %d" % centers.size())
			for i in 20:
				await process_frame
			await RenderingServer.frame_post_draw
			var name := "storm_%02d_%s.png" % [centers.size(), state]
			if CAP.save_png(root.get_texture().get_image(), out.path_join(name), CAP.capture_stage()) != OK:
				_fail("Could not stamp " + name)
	_write("storm.json", {"seed": 4103, "subject": subject, "storm_hexes": battle.world._terr_pts.storm.size(),
		"nebula_hexes": battle.world._terr_pts.neb.size(), "patches": centers}, out)
	battle.queue_free()
	await process_frame
