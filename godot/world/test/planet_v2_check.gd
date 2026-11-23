extends SceneTree
# Issue 1765 (R419, Planets V2): the board planet is really wired, and the planet palettes keep the rules. This is the
# planet share of R420's Godot headless anti-drift gates (RULEBOOK 3.14, global_cohesion_standard.md 6.2: the unwired
# asset gate for all five PLANET_LOOKS and the zero-purple gate on PLANETS and PLANETS_ALT). Band 2 brightness needs a
# render: world/planet_v2_shots.gd measures it and fails an after run outside 0.03 to 0.25.
# 1. The real board (board.gd built from a planet map, Fable on PR 1776: not a source search) draws its planet through
#    world_planet.gd for each of its five looks, never the campaign map's icon shader; wait_planet holds until the maps
#    are in, and a planet that misses its 20 s deadline is frozen on its stand-in; battle.gd waits for it behind the
#    loading cover (silent-regression trap 1 of the World V2 plan: an asset only a shot script ever loads).
# 1b. The stand-in is the look's own procedural surface, never a plain ball, and every material shares one shader.
# 3b. The relief is one exact 32-bit float channel.
# 2. Every board look gets a lit surface at once: rocky (0) and barren (5) then switch to the authored 8K R01 relief,
#    rocky with its cloud layer and air, barren with neither; terran (1), ice (3) and volcanic (4) keep the baked board
#    surface (headless has no GPU bake, so it stays the lit stand-in here; the PC shots show the baked maps).
# 3. Two battles with different seeds see different faces of R01 (the remix turn, RULEBOOK 10.3).
# 4. No planet, alternate planet or moon palette leans indigo to purple (RULEBOOK 10.9), and moons bake at 2K.

const GUARD := preload("res://tools/ci/check_guard.gd")
const PL := preload("res://world/world_planet.gd")
const SKY := preload("res://world/world_sky.gd")
const BAKER := preload("res://world/world_bake.gd")
const WORLD := preload("res://world/world.gd")
const BOARD := preload("res://render/board.gd")

class StubRules extends RefCounted:
	var v := {}
	var w := {}
	func view() -> Dictionary:
		return v
	func world_info() -> Dictionary:
		return w

var failures := 0


func _init() -> void:
	GUARD.arm(self, "planet_v2_check", 300.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _purple(v: Vector3) -> bool:
	# blue and red both clearly above green: violet, lavender, indigo
	return v.z > v.y + 0.06 and v.x > v.y + 0.04


func _planet() -> Array:
	var sp := SphereMesh.new()
	sp.radius = 50.0
	sp.height = 100.0
	var mi := MeshInstance3D.new()
	mi.mesh = sp
	root.add_child(mi)
	var shell := MeshInstance3D.new()
	root.add_child(shell)
	return [mi, shell]


var _done := false


func _install(mi: MeshInstance3D, shell: MeshInstance3D, k: int, seed_v: int, sun: Vector3) -> void:
	await PL.install_board(mi, shell, k, seed_v, sun)
	_done = true


func _code(mi: MeshInstance3D) -> String:
	var m := mi.material_override as ShaderMaterial
	return m.shader.code if m != null and m.shader != null else ""


func _run() -> void:
	# 1. wiring, through the real board
	var hexes: Array = []
	for r in range(-3, 4):
		for q in range(-4, 5):
			hexes.append({"q": q, "r": r})
	_check(BOARD.PLANET_LOOKS == [0, 1, 3, 4, 5], "board.gd PLANET_LOOKS is not the five kinds (%s)" % str(BOARD.PLANET_LOOKS))
	for i in BOARD.PLANET_LOOKS.size():
		var rules := StubRules.new()
		rules.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
		rules.w = {"seed": 20 + i}
		var board: Node3D = BOARD.new()
		root.add_child(board)
		board.build(rules)
		var mi: MeshInstance3D = board.planet_node
		var want: int = BOARD.PLANET_LOOKS[posmod(20 + i, 5)]
		_check(mi != null, "board seed %d: no planet built from a planet map" % (20 + i))
		if mi == null:
			board.queue_free()
			continue
		_check(int(mi.get_meta("planet_look", -1)) == want, "board seed %d: look %s, want %d" % [20 + i, str(mi.get_meta("planet_look", -1)), want])
		var first := _code(mi)
		_check(first == PL.BOARD_SURFACE, "board look %d: the first material is not world_planet.gd's stand-in" % want)
		var stand := mi.material_override as ShaderMaterial
		if stand != null:
			var ca: Vector3 = stand.get_shader_parameter("col_a")
			var cb: Vector3 = stand.get_shader_parameter("col_b")
			_check(ca.distance_to(cb) > 0.05, "board look %d: the stand-in has one flat colour" % want)
			_check(stand.shader == PL.shader(PL.BOARD_SURFACE), "board look %d: the stand-in compiled its own shader" % want)
		_check(board.planet_pending, "board look %d: the board does not hold the loading cover for its planet" % want)
		await board.wait_planet()
		_check(not board.planet_pending, "board look %d: wait_planet returned with the maps still pending" % want)
		var code := _code(mi)
		_check(code == (PL.ROCKY_SURFACE if want == 0 or want == 5 else PL.BOARD_SURFACE), "board look %d: wrong surface after the cover" % want)
		_check(not code.contains("map3d") and not first.contains("map3d"), "board look %d: the campaign map's icon shader" % want)
		_check(not bool(mi.get_meta("planet_frozen", false)), "board look %d: frozen although its maps arrived in time" % want)
		board.queue_free()
		await process_frame
	# a board whose maps miss the 20 s deadline freezes on the stand-in (counted from the planet's own start)
	var slow := StubRules.new()
	slow.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
	slow.w = {"seed": 20}   # rocky: R01 is already in memory, so only the freeze keeps it out
	var sb: Node3D = BOARD.new()
	root.add_child(sb)
	sb.build(slow)
	sb.planet_t0 -= 21000
	await sb.wait_planet()
	_check(bool(sb.planet_node.get_meta("planet_frozen", false)), "a board planet 21 s late was not frozen on its stand-in")
	while sb.planet_pending:
		await process_frame
	var has_tex = (sb.planet_node.material_override as ShaderMaterial).get_shader_parameter("has_tex")
	_check(_code(sb.planet_node) == PL.BOARD_SURFACE and (has_tex == null or float(has_tex) < 0.5),
		"a frozen board planet still swapped its maps in (%s)" % str(sb.planet_node.get_meta("planet_code", "")))
	sb.queue_free()
	await process_frame
	var battle_src := FileAccess.get_file_as_string("res://scenes/battle/battle.gd")
	_check(battle_src.contains("board.wait_planet()"), "battle.gd does not wait for the board planet behind the loading cover")
	_check(PL.rocky_available(), "the R01 maps are missing from godot/world/rocks/r01")
	# 2. every look
	var turns := {}
	for k in [0, 1, 3, 4, 5]:
		for seed_v in [3, 11]:
			var pair := _planet()
			var mi: MeshInstance3D = pair[0]
			var shell: MeshInstance3D = pair[1]
			var sun := mi.global_position + Vector3(0.4, 0.6, 0.7) * 100000.0
			_done = false
			_install(mi, shell, k, seed_v, sun)
			_check(_code(mi) != "", "look %d: no surface material before its maps arrive" % k)
			_check(mi.material_override.shader == PL.shader(PL.BOARD_SURFACE), "look %d: a new stand-in shader per planet" % k)
			while not _done:
				await process_frame
			var code := _code(mi)
			if k == 0 or k == 5:
				_check(code == PL.ROCKY_SURFACE, "look %d does not draw the R01 surface" % k)
				_check(str(mi.get_meta("planet_code", "")) == "R01", "look %d: planet_code is not R01" % k)
				var clouds := mi.get_node_or_null("R01Clouds")
				_check((clouds != null) == (k == 0), "look %d: R01 cloud layer %s" % [k, "missing" if k == 0 else "on an airless world"])
				_check(shell.visible == (k == 0), "look %d: air shell %s" % [k, "hidden" if k == 0 else "shown on an airless world"])
				var m := mi.material_override as ShaderMaterial
				if m != null:
					turns["%d|%d" % [k, seed_v]] = float(m.get_shader_parameter("remix_turn"))
			else:
				_check(code == PL.BOARD_SURFACE, "look %d does not draw the baked board surface" % k)
				_check(str(mi.get_meta("planet_code", "")).begins_with("BAKE"), "look %d: planet_code is not a board bake" % k)
			mi.queue_free()
			shell.queue_free()
			await process_frame
	# 2b. maps that miss the loading cover never swap in mid-battle (Artoo, PR 1776)
	var late := _planet()
	(late[0] as MeshInstance3D).set_meta("planet_frozen", true)
	_done = false
	_install(late[0], late[1], 0, 5, Vector3(0.4, 0.6, 0.7) * 100000.0)
	while not _done:
		await process_frame
	_check(_code(late[0]) == PL.BOARD_SURFACE, "a frozen planet still swapped to R01 after the cover lifted")
	(late[0] as Node).queue_free()
	(late[1] as Node).queue_free()
	# 2b2. a rebuild never inherits or loses a planet wait (audit, PR 1776): rebuilt onto a map with no planet, nothing
	# waits; rebuilt twice onto planets, the first build's install finishing cannot clear the second's wait
	var rb: Node3D = BOARD.new()
	root.add_child(rb)
	var with_planet := StubRules.new()
	with_planet.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
	with_planet.w = {"seed": 20}
	var no_planet := StubRules.new()
	no_planet.v = {"hexes": hexes, "terrain": {}}
	rb.build(with_planet)
	rb.build(no_planet)
	_check(not rb.planet_pending, "a rebuild onto a map with no planet still waits for the old planet")
	rb.build(with_planet)
	var gen_before: int = rb.built
	rb.build(with_planet)
	_check(rb.planet_pending and rb.built == gen_before + 1, "a second planet build is not waiting")
	await rb.wait_planet()
	_check(not bool(rb.planet_node.get_meta("planet_frozen", false)) and _code(rb.planet_node) == PL.ROCKY_SURFACE,
		"the newest build's planet did not finish after a rebuild")
	rb.queue_free()
	await process_frame
	# 2c. VS_PLANET_REMIX=0 (R01 switched off, Astra via Ryan item 4): rocky and barren boards keep the procedural
	# stand-in in their own palette, and the loading cover still lifts at once
	OS.set_environment("VS_PLANET_REMIX", "0")
	_check(not PL.rocky_available(), "VS_PLANET_REMIX=0 does not switch R01 off")
	for sv in [20, 24]:   # looks 0 (rocky) and 5 (barren)
		var off := StubRules.new()
		off.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
		off.w = {"seed": sv}
		var ob: Node3D = BOARD.new()
		root.add_child(ob)
		ob.build(off)
		var t0 := Time.get_ticks_msec()
		await ob.wait_planet()
		var om: MeshInstance3D = ob.planet_node
		var mat := om.material_override as ShaderMaterial
		_check(_code(om) == PL.BOARD_SURFACE, "VS_PLANET_REMIX=0 seed %d: no procedural fallback surface" % sv)
		_check(mat != null and (mat.get_shader_parameter("col_a") as Vector3).distance_to(mat.get_shader_parameter("col_b")) > 0.02,
			"VS_PLANET_REMIX=0 seed %d: the fallback is one flat colour" % sv)
		_check(not bool(om.get_meta("planet_frozen", false)) and Time.get_ticks_msec() - t0 < 5000,
			"VS_PLANET_REMIX=0 seed %d: the cover waited for maps that will never come" % sv)
		ob.queue_free()
		await process_frame
	OS.unset_environment("VS_PLANET_REMIX")
	# 3. the remix differs per battle
	for k in [0, 5]:
		var a := float(turns.get("%d|3" % k, 0.0))
		var b := float(turns.get("%d|11" % k, 0.0))
		_check(absf(a - b) > 0.1, "look %d: two seeds show the same face of R01 (turn %.3f and %.3f)" % [k, a, b])
	# 4. palettes
	for table in [SKY.PLANETS, SKY.PLANETS_ALT]:
		for i in table.size():
			var P: Dictionary = table[i]
			for key in ["a", "b", "c", "atmo"]:
				_check(not _purple(P[key]), "planet %d %s %s leans indigo to purple" % [i, key, str(P[key])])
	for k in PL.BOARD_LOOKS:
		var L: Dictionary = PL.BOARD_LOOKS[k]
		for key in ["flat", "a", "b", "c", "atmo", "stand_b"]:
			if L.has(key):
				_check(not _purple(L[key]), "board look %d %s leans indigo to purple" % [k, key])
	for i in WORLD.MOON_LOOKS.size():
		for key in ["a", "b", "c"]:
			_check(not _purple(WORLD.MOON_LOOKS[i][key]), "moon look %d %s leans indigo to purple" % [i, key])
	# the board planet's maps jump the bake queue (PC proof OPUS1765_PC_C: behind the backdrops a cold cache missed the
	# 20 s cover); a job the worker already took is never queued twice
	var q = BAKER.new()
	for k in ["far1", "far2"]:
		q._jobs[k] = {}
		q._enqueue(k, false)
	for k in ["board_a", "board_b", "board_h"]:
		q._jobs[k] = {}
		q._enqueue(k, true)
	_check(q._queue == ["board_a", "board_b", "board_h", "far1", "far2"], "the board planet's map set does not jump the bake queue in order (%s)" % str(q._queue))
	q._queue.pop_front()
	q._enqueue("board_a", true)
	_check(q._queue == ["board_b", "board_h", "far1", "far2"], "a bake the worker already took was queued again (%s)" % str(q._queue))
	q.free()
	# Artoo (PR 1776): install_board queues its whole map set before awaiting any, so no backdrop can start between two
	# of its maps. Watch the live service while a cold terran board installs behind two queued backdrop jobs.
	var cache_dir := OS.get_user_data_dir().path_join("planet_v2_check_cache")
	OS.set_environment("VS_WORLD_CACHE", cache_dir)
	var svc = BAKER.service(self)
	await process_frame
	svc._jobs["far_x"] = {"path": "res://nope_x.json", "size": Vector2i(8, 8), "done": false, "image": null, "started": 0, "compute": false}
	svc._jobs["far_y"] = {"path": "res://nope_y.json", "size": Vector2i(8, 8), "done": false, "image": null, "started": 0, "compute": false}
	svc._enqueue("far_x", false)
	svc._enqueue("far_y", false)
	var tp := _planet()
	var seen: Array = []
	_done = false
	_install(tp[0], tp[1], 1, 77, Vector3(0.4, 0.6, 0.7) * 100000.0)
	while not _done:
		if svc._active != "" and (seen.is_empty() or seen[-1] != svc._active): seen.append(svc._active)
		await process_frame
	# a backdrop already running may finish first; after the first board map, the other two follow with nothing between
	var board_at: Array = []
	for i in seen.size():
		if not str(seen[i]).begins_with("far_"): board_at.append(i)
	_check(board_at.size() == 3 and board_at[2] - board_at[0] == 2, "a backdrop bake ran between the board planet's maps (%s)" % str(seen))
	OS.unset_environment("VS_WORLD_CACHE")
	(tp[0] as Node).queue_free()
	(tp[1] as Node).queue_free()
	q = BAKER.new()
	q.free()
	# Wave 0 (Fable): a changed recipe must never draw old maps from a PC's disk cache. The key holds the whole shader
	# text, and both save paths (the GPU compute bake in _work, the raster bake in _finish_image) and the load path use
	# <key>.png, so a stale file under the old key is never read for the new recipe.
	var code_now: String = PL.bake_code()
	var bp := {"seed": 1.0, "kind": 5, "ca": Vector3.ONE, "cb": Vector3.ZERO, "cc": Vector3.ONE, "pass_id": 0}
	var k_old: String = BAKER.cache_key("board_planet|3|1|a", code_now + "\n// an older recipe", bp, Vector2i(8, 4))
	var k_new: String = BAKER.cache_key("board_planet|3|1|a", code_now, bp, Vector2i(8, 4))
	_check(k_old != k_new, "a recipe change keeps the old bake cache key")
	var cdir := OS.get_user_data_dir().path_join("planet_v2_cache_paths")
	DirAccess.make_dir_recursive_absolute(cdir)
	OS.set_environment("VS_WORLD_CACHE", cdir)
	var stale := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	stale.fill(Color(1, 0, 0))
	var saved: Dictionary = BAKER._finish_image(k_old, stale.duplicate())   # the raster path saves <key>.png
	_check(saved.get("image") != null and FileAccess.file_exists(cdir.path_join(k_old + ".png")), "the raster bake path did not save under its cache key")
	var hit: Dictionary = BAKER._work(k_old, {"size": Vector2i(8, 4), "compute": false})
	_check(hit.get("source", "") == "loaded", "the load path did not read a map saved under its own key")
	var miss: Dictionary = BAKER._work(k_new, {"size": Vector2i(8, 4), "compute": false})
	_check(miss.get("image") == null, "a changed recipe loaded the old recipe's map from disk")
	_check(hit.get("image") != null and (hit.get("image") as Image).get_pixel(0, 0).r > 0.9, "the load path did not return the saved map")
	_check(FileAccess.get_file_as_string("res://world/world_bake.gd").contains('var path := folder.path_join(key + ".png")'), "the compute bake path no longer saves under <key>.png")
	DirAccess.remove_absolute(cdir.path_join(k_old + ".png"))
	OS.unset_environment("VS_WORLD_CACHE")
	# relief: one exact 32-bit float channel (Fable, PR 1776 M4)
	var packed := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	packed.set_pixel(1, 0, Color8(0x9c, 0x41, 0, 255))
	var hf := BAKER.height_float(packed)
	_check(hf.get_format() == Image.FORMAT_RF, "the relief is not one 32-bit float channel (format %d)" % hf.get_format())
	_check(absf(hf.get_pixel(1, 0).r - float(0x9c41) / 65535.0) < 1e-6, "the relief float is not the exact 16-bit height")
	_check(BAKER.MOON_SIZE.x >= 2048, "moons bake below 2K (%s)" % str(BAKER.MOON_SIZE))
	# GLSL leaves smoothstep undefined when edge0 >= edge1 (Artoo, PR 1776): no literal pair in the planet shaders runs
	# high edge first; a falling edge is written 1.0 - smoothstep(lo, hi, x)
	var rx := RegEx.create_from_string("smoothstep\\(\\s*(-?[0-9.]+)\\s*,\\s*(-?[0-9.]+)\\s*,")
	for m in rx.search_all(FileAccess.get_file_as_string("res://world/world_planet.gd")):
		_check(float(m.get_string(1)) < float(m.get_string(2)), "world_planet.gd has a smoothstep with its edges reversed: " + m.get_string(0))
	print("planet_v2_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
