extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Regression checks with loaded stand-in hull scenes, no GLB files required.
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const HD := preload("res://world/hull_debris.gd")
const BAKE := preload("res://world/world_bake.gd")
var failures := 0
var fx
var world: Node3D
class StandIn extends Node3D:
	var fac := "hegemony"
	var meshes: Array = []
func _init() -> void:
	GUARD.arm(self, "playtest_batch1_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func ship(id: String, faction: String, pos := Vector3.ZERO):
	var node := StandIn.new()
	node.fac = faction
	world.add_child(node)
	node.position = pos
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 4.5, 7)
	box.subdivide_width = 17; box.subdivide_height = 4; box.subdivide_depth = 6
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.41, 0.5) if faction != "chorus" else Color(0.18, 0.23, 0.055)
	mat.metallic = 0.5 if faction != "chorus" else 0.0
	mi.material_override = mat
	node.add_child(mi); node.meshes = [mi]
	fx.add_ship(id, node, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": [mi]})
	var s = fx.ship(id)
	s._anchors["a1"] = {"p": Vector3(0, 2.25, 0), "n": Vector3.UP, "t": {}}
	return s
func state(mid: float, hp := 100.0) -> Dictionary:
	return {"hp": hp, "maxHp": 100.0, "sec": {"eng": {"hp": 100, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": 100, "max": 100}}}
func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0: s.flush_damage(fx)
		fx.step(0.01)
func _run() -> void:
	if OS.get_environment("FB1_SHOTS") != "":
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280, 720)
	world = Node3D.new(); root.add_child(world)
	fx = FX.new(); world.add_child(fx); fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	var s = ship("small_hit", "hegemony", Vector3(-22, 0, 0))
	s.sync(fx, state(90.0, 25.0))
	check(s.stage[1] == 0, "90 percent midsection is intact despite low overall HP")
	s.add_mark(fx, "torp", 4, Vector3(0, 2.25, 0), Vector3.UP, Vector3.DOWN)
	flush(s)
	check(s._marks[0].R < s.hull.L * 0.02, "light section damage limits heavy weapon puncture radius")
	var small_radius: float = s._marks[0].R
	s.sync(fx, state(15.0))
	flush(s)
	check(s.stage[1] == 4 and s._marks[0].R > small_radius * 2.0, "heavy section damage opens the large breach")
	s.sync(fx, state(90.0)); flush(s)
	check(s.stage[1] == 0 and not s._marks.is_empty(), "repair restores the section and keeps survivor scars")
	s.sync(fx, state(90.0)); s.add_mark(fx, "torp", 4, Vector3(0, 2.25, 0), Vector3.UP, Vector3.DOWN); flush(s)
	var wounded = ship("heavy_hit", "hegemony", Vector3(12, 0, 0))
	wounded.sync(fx, state(15.0)); flush(wounded)
	var organic = ship("organic", "chorus", Vector3(12, 0, -22))
	organic.sync(fx, state(15.0)); flush(organic)
	check(organic._dmg_job.organic, "Chorus geometry job uses membranes")
	var crystal = ship("crystal", "ithar", Vector3(-22, 0, -22))
	crystal.sync(fx, state(15.0)); flush(crystal)
	# Loaded, mirrored source scenes retain texture coordinates and their own paint.
	var sources := HD.gather([s.root, organic.root])
	check(sources.size() == 2, "chunks gather each faction from loaded hulls")
	var chunks := HD.cut(sources)
	check(chunks.size() >= 4, "stand-in ship scenes cut into multiple hull chunks")
	var meshes := HD.meshes(chunks)
	check(not meshes.is_empty(), "cut chunks build real meshes")
	for chunk in chunks:
		check(chunk.has("cap") and not chunk.cap[Mesh.ARRAY_VERTEX].is_empty(), "chunk has a sealed torn face")
		check(chunk.surfs[0].arrays[Mesh.ARRAY_TEX_UV] != null, "chunk preserves source UV paint")
	var painted: Material = meshes[0].surface_get_material(0)
	check(painted.has_meta("fx_hull_source"), "cut keeps the source hull material")
	# Cache really survives clearing the in-memory cache, and invalidates settings/code.
	var image := Image.create_empty(8, 4, false, Image.FORMAT_RGBA8); image.fill(Color(0.2, 0.4, 0.6, 0.7))
	var key := BAKE.cache_key("test", "shader-v1", {"seed": 7, "quality": "high"}, Vector2i(8, 4))
	# Issue 80 moved disk I/O out of remember/cached and onto the bake worker.
	# Keep this regression on that API so it can reach the damage/death checks.
	var scratch := OS.get_environment("TEMP") if OS.has_environment("TEMP") else "/tmp"
	OS.set_environment("VS_WORLD_CACHE", scratch.path_join("voidsworn-fb1-cache"))
	var writer := Thread.new()
	writer.start(BAKE._finish_image.bind(key, image))
	while writer.is_alive(): await process_frame
	writer.wait_to_finish()
	BAKE._cache.clear()
	var reader := Thread.new()
	reader.start(BAKE._work.bind(key, {"size": Vector2i(8, 4), "compute": false}))
	while reader.is_alive(): await process_frame
	var loaded: Dictionary = reader.wait_to_finish()
	var disk: Image = loaded.image
	check(disk != null and disk.get_size() == Vector2i(8, 4), "persistent RGBA cache loads after memory is cleared")
	check(BAKE.cache_key("test", "shader-v2", {"seed": 7, "quality": "high"}, Vector2i(8, 4)) != key, "cache invalidates shader changes")
	check(BAKE.cache_key("test", "shader-v1", {"seed": 8, "quality": "high"}, Vector2i(8, 4)) != key, "cache invalidates seeds")
	check(BAKE.cache_key("test", "shader-v1", {"quality": "high", "seed": 7}, Vector2i(8, 4)) == key, "cache settings order does not cause rebakes")
	check(BAKE.cache_key("test", "shader-v1", {"seed": 7, "quality": "high"}, Vector2i(16, 8)) != key, "cache invalidates dimensions")
	check(absf(disk.get_pixel(0, 0).a - image.get_pixel(0, 0).a) < 0.01, "persistent cache retains sky transmittance alpha")
	WEAP.torp_lane(fx, "friendly", "small_hit", Vector3(38, 0, 20), 1)
	WEAP.torp_lane(fx, "enemy", "organic", Vector3(-38, 0, 20), 1)
	for lane in fx.dstate.lanes.values():
		var strip: MeshInstance3D = lane.root.get_child(0)
		var a: Array = strip.mesh.surface_get_arrays(0)
		var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
		check(uv[0].x == 0.0 and uv[1].x == 1.0, "lane UV increases from shooter toward target for both teams")
	check(WEAP.LANE.contains("s + x * 2.5"), "chevron point leads its wings toward positive lane distance")
	if OS.get_environment("FB1_SHOTS") != "" and DisplayServer.get_name() != "headless":
		for i in 480: fx.step(1.0 / 60.0)
		await captures(s, wounded, organic, crystal, meshes)
	var before: Vector3 = organic.meshes[0].scale
	fx.death("organic", "big")
	for i in 12: fx.step(1.0 / 60.0)
	check(organic.meshes[0].scale.is_equal_approx(before), "Chorus keeps its volume before rupture")
	for i in 180:
		fx.step(1.0 / 60.0)
		await process_frame
		if organic.has_meta("death_hidden"): break
	if OS.get_environment("FB1_SHOTS") != "" and DisplayServer.get_name() != "headless":
		for i in 8: await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png(OS.get_environment("FB1_SHOTS").path_join("chorus_rupture.png"))
	check(organic.has_meta("death_hidden"), "Chorus live skin is replaced at rupture")
	for i in 60: fx.step(1.0 / 60.0)
	var remains: Array = fx.dstate.wrecks.filter(func(w): return w.id == "organic")
	check(remains.size() == 1, "ruptured organic pieces persist as one wreck record")
	if not remains.is_empty():
		check(remains[0].nodes.size() >= 4, "Chorus ruptures into several membrane pieces")
		check(remains[0].lights.is_empty(), "organic spill has no metal fire lights")
		var body: Node3D = remains[0].nodes[0]
		var piece := body.get_child(body.get_child_count() - 1) as MeshInstance3D
		check(piece != null and piece.mesh.get_surface_count() > 1, "organic wreck retains painted skin and sealed torn faces")
		fx.remove_ship("organic")
		check(is_instance_valid(body) and is_instance_valid(piece), "organic pieces survive removing the live ship")
	print("PLAYTEST_BATCH1 failures=%d chunks=%d" % [failures, meshes.size()])
	fx.queue_free(); await process_frame
	world.queue_free(); await process_frame
	FX.clear_static()
	quit(1 if failures else 0)

func captures(s, wounded, organic, crystal, chunks: Array) -> void:
	var out := OS.get_environment("FB1_SHOTS")
	DirAccess.make_dir_recursive_absolute(out)
	var camera := Camera3D.new(); world.add_child(camera); camera.current = true; camera.fov = 45
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.012, 0.015, 0.025)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.55, 0.62, 0.75)
	env.environment.ambient_light_energy = 0.65
	world.add_child(env)
	var key := DirectionalLight3D.new(); world.add_child(key); key.rotation_degrees = Vector3(-55, -25, 0); key.light_energy = 2.2
	for pair in [[s, "light_hit_90pct"], [wounded, "heavy_section"], [organic, "chorus_wound"], [crystal, "crystal_wound"]]:
		var target: Vector3 = pair[0].to_world(Vector3(0, 1.5, 0))
		camera.position = target + Vector3(7, 17, 19); camera.look_at(target)
		for i in 12: await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png(out.path_join(pair[1] + ".png"))
	camera.position = Vector3(0, 88, 50); camera.look_at(Vector3(0, 0, 0))
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join("lanes_both_teams.png"))
	for lane in fx.dstate.lanes.keys(): WEAP.torp_lane_clear(fx, lane, false)
	var holder := Node3D.new(); world.add_child(holder); holder.position = Vector3(0, 0, 32)
	for i in mini(4, chunks.size()):
		var mi := MeshInstance3D.new(); mi.mesh = chunks[i]; holder.add_child(mi)
		var box := mi.mesh.get_aabb(); mi.position = Vector3((i - 1.5) * 14, 0, 0) - box.get_center(); mi.rotation = Vector3(0.2, 0.2 * i, 0.5)
	camera.position = Vector3(0, 45, 70); camera.look_at(holder.position)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(out.path_join("loaded_hull_chunks.png"))
	camera.position = organic.to_world(Vector3(7, 17, 19)); camera.look_at(organic.to_world(Vector3(0, 1.5, 0)))
