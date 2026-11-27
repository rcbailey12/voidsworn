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
# 3b. Relief height is one exact 32-bit float channel. R01 keeps roughness and cloud coverage in a separate RG8 map.
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
	# 0. issue 1434 (LOAD32): the title menu's backdrop never makes the run's first 8K R01 upload; a rocky or barren seed
	# takes the next baked look there until a battle has put R01 on screen
	BAKER._trim(0)   # nothing of R01 held yet
	for title_seed in [20, 24]:
		var tr := StubRules.new()
		tr.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
		tr.w = {"seed": title_seed}
		var tb: Node3D = BOARD.new()
		tb.title_backdrop = true
		root.add_child(tb)
		tb.build(tr)
		var tl := int(tb.planet_node.get_meta("planet_look", -1)) if tb.planet_node != null else -1
		_check(tl >= 0 and not PL.uses_r01(tl), "title board seed %d: look %d draws the 8K R01 maps behind the title" % [title_seed, tl])
		await tb.wait_planet()
		tb.queue_free()
		await process_frame
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
		# the stand-in first; or, now that the maps are queued without a frame wait, the final R01 surface at once when
		# its authored maps are already in memory (an earlier look loaded them)
		# never on the first look (i 0): R01 is not in memory yet, so a final surface there would be a main-thread load
		var at_once: bool = i > 0 and (want == 0 or want == 5) and first == PL.ROCKY_SURFACE and not board.planet_pending
		if at_once:
			_check((mi.material_override as ShaderMaterial).shader == PL.shader(PL.ROCKY_SURFACE), "board look %d: the at-once surface compiled its own shader" % want)
		_check(first == PL.BOARD_SURFACE or at_once, "board look %d: the first material is not world_planet.gd's stand-in" % want)
		var stand := mi.material_override as ShaderMaterial
		if stand != null and not at_once:
			var ca: Vector3 = stand.get_shader_parameter("col_a")
			var cb: Vector3 = stand.get_shader_parameter("col_b")
			_check(ca.distance_to(cb) > 0.05, "board look %d: the stand-in has one flat colour" % want)
			_check(stand.shader == PL.shader(PL.BOARD_SURFACE), "board look %d: the stand-in compiled its own shader" % want)
		_check(board.planet_pending or at_once, "board look %d: the board does not hold the loading cover for its planet" % want)
		await board.wait_planet()
		_check(not board.planet_pending, "board look %d: wait_planet returned with the maps still pending" % want)
		var code := _code(mi)
		_check(code == (PL.ROCKY_SURFACE if want == 0 or want == 5 else PL.BOARD_SURFACE), "board look %d: wrong surface after the cover" % want)
		_check(not code.contains("map3d") and not first.contains("map3d"), "board look %d: the campaign map's icon shader" % want)
		_check(not bool(mi.get_meta("planet_frozen", false)), "board look %d: frozen although its maps arrived in time" % want)
		board.queue_free()
		await process_frame
	# once a battle has drawn R01 this run, the title may show a rocky world again (its maps are already uploaded)
	_check(PL.r01_uploaded(), "R01 drawn on a battle board but not remembered as uploaded")
	var relief_key := BAKER.authored_key(PL.R01_DIR + "relief.json", PL.R01_SIZE, true)
	var relief := BAKER._cache.get(relief_key) as BAKER.RockyRelief
	_check(relief != null, "authored R01 relief was not cached as a pair")
	var relief_ids: Array[int] = []
	if relief != null:
		_check(relief.height.get_format() == Image.FORMAT_RF and relief.height.get_size() == PL.R01_SIZE and relief.height.has_mipmaps(),
			"the cached R01 height is not a full-size mipmapped RF image")
		_check(relief.masks.get_format() == Image.FORMAT_RG8 and relief.masks.get_size() == PL.R01_SIZE and relief.masks.has_mipmaps(),
			"the cached R01 masks are not a full-size mipmapped RG8 image")
		relief_ids.assign([relief.height.get_instance_id(), relief.masks.get_instance_id()])
		relief = null
	var again := StubRules.new()
	again.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
	again.w = {"seed": 20}
	var ab: Node3D = BOARD.new()
	ab.title_backdrop = true
	root.add_child(ab)
	ab.build(again)
	_check(ab.planet_node != null and int(ab.planet_node.get_meta("planet_look", -1)) == 0, "title board after a battle: the rocky look was not kept")
	await ab.wait_planet()
	ab.queue_free()
	await process_frame
	# Artoo on 002e143f: once the cache evicts the R01 maps (a trim drops each image with its texture), the title takes
	# the baked look again
	BAKER._trim(0)
	_check(not PL.r01_uploaded(), "R01 still counted as uploaded after the bake cache evicted it")
	for id in relief_ids:
		_check(not BAKER._textures.has(id), "a split R01 texture stayed cached after eviction")
	var ev := BOARD.new()
	ev.title_backdrop = true
	root.add_child(ev)
	ev.build(again)
	var evl := int(ev.planet_node.get_meta("planet_look", -1)) if ev.planet_node != null else -1
	_check(evl >= 0 and not PL.uses_r01(evl), "title board after an eviction: look %d draws the 8K R01 maps again" % evl)
	await ev.wait_planet()
	ev.queue_free()
	await process_frame
	# a board whose maps miss the 20 s deadline freezes on the stand-in (counted from the planet's own start)
	var slow := StubRules.new()
	slow.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
	slow.w = {"seed": 20}   # rocky: R01 is dropped from memory first, so its maps really arrive after the deadline
	BAKER._cache.clear()   # (Neon item 4: a baked look returns no maps in headless and never reached the guard)
	var sb: Node3D = BOARD.new()
	root.add_child(sb)
	sb.build(slow)
	sb.planet_t0 -= 21000
	await sb.wait_planet()
	_check(bool(sb.planet_node.get_meta("planet_frozen", false)), "a board planet 21 s late was not frozen on its stand-in")
	_check(sb.planet_pending, "the late planet's maps were already in before the freeze test ran")
	while sb.planet_pending:
		await process_frame
	_check(BAKER._cache.size() >= 2, "the late planet's R01 maps never arrived, so the freeze guard was not reached")
	var has_tex = (sb.planet_node.material_override as ShaderMaterial).get_shader_parameter("has_tex")
	_check(_code(sb.planet_node) == PL.BOARD_SURFACE and (has_tex == null or float(has_tex) < 0.5),
		"a frozen board planet still swapped its maps in (%s)" % str(sb.planet_node.get_meta("planet_code", "")))
	sb.queue_free()
	await process_frame
	# Seed the real board cache entry on disk. Even a complete set arriving after
	# the deadline must not replace the frozen stand-in.
	var fdir := OS.get_user_data_dir().path_join("planet_v2_check_freeze")
	OS.set_environment("VS_WORLD_CACHE", fdir)
	OS.set_environment("VS_WORLD_PREVIEW", "1")
	var fj: Dictionary = PL.board_job(4, 33)   # volcanic, seed 33 (posmod(33, 5) = 3: PLANET_LOOKS[3] is 4)
	var fk := BAKER.board_key(fj.key, fj.code, fj.params, fj.size)
	var maps: Array[Image] = []
	for format in BAKER.BOARD_FORMATS:
		var dummy := Image.create(fj.size.x, fj.size.y, false, format)
		dummy.fill(Color(0.5, 0.4, 0.3, 1.0))
		dummy.generate_mipmaps()
		maps.append(dummy)
	_check(BAKER._save(fk, maps, {}, {}, fdir), "could not seed the baked board cache")
	var fslow := StubRules.new()
	fslow.v = slow.v
	fslow.w = {"seed": 33}
	var fb: Node3D = BOARD.new()
	root.add_child(fb)
	fb.build(fslow)
	fb.planet_t0 -= 21000
	await fb.wait_planet()
	_check(bool(fb.planet_node.get_meta("planet_frozen", false)), "a baked board planet 21 s late was not frozen on its stand-in")
	while fb.planet_pending:
		await process_frame
	_check(BAKER._cache.get(fk, []).size() == 3, "the seeded baked maps never loaded, so the baked freeze guard was not reached")
	var ftex = (fb.planet_node.material_override as ShaderMaterial).get_shader_parameter("has_tex")
	_check(ftex == null or float(ftex) < 0.5, "a frozen baked board planet still swapped its maps in")
	fb.queue_free()
	DirAccess.remove_absolute(fdir.path_join(fk + BAKER.BOARD_SUFFIX))
	OS.unset_environment("VS_WORLD_PREVIEW")
	OS.unset_environment("VS_WORLD_CACHE")
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
			# rocky and barren show their final surface at once when the R01 maps are already in memory (no frame wait)
			var sh: Shader = mi.material_override.shader
			_check(sh == PL.shader(PL.BOARD_SURFACE) or ((k == 0 or k == 5) and sh == PL.shader(PL.ROCKY_SURFACE)), "look %d: a new stand-in shader per planet" % k)
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
	with_planet.w = {"seed": 26}   # terran: in headless its bakes return at once with no maps
	var slow_planet := StubRules.new()
	slow_planet.v = with_planet.v
	slow_planet.w = {"seed": 20}   # rocky, with R01 dropped from memory: its maps arrive well after the terran set
	var no_planet := StubRules.new()
	no_planet.v = {"hexes": hexes, "terrain": {}}
	rb.build(with_planet)
	rb.build(no_planet)
	_check(not rb.planet_pending, "a rebuild onto a map with no planet still waits for the old planet")
	BAKER._cache.clear()
	rb.build(with_planet)
	var gen_before: int = rb.built
	rb.build(slow_planet)
	_check(rb.planet_pending and rb.built == gen_before + 1, "a second planet build is not waiting")
	# let the first (terran) build's install finish while the newer rocky build is still loading R01: its finish must
	# not clear the newer build's wait (Neon item 4: this needs two builds that finish at different times)
	var rsvc = BAKER.service(self)
	var rjob := PL.board_job(1, 26)
	var rkey := BAKER.board_key(rjob.key, rjob.code, rjob.params, rjob.size)
	for f in 600:
		if not rsvc._jobs.has(rkey): break
		await process_frame
	for f in 3: await process_frame
	_check(rb.planet_ready_ms < 0, "the rocky build finished before the terran one, so the rebuild case tests nothing")
	_check(rb.planet_pending, "an older build's install cleared the newer build's planet wait")
	await rb.wait_planet()
	_check(not bool(rb.planet_node.get_meta("planet_frozen", false)) and str(rb.planet_node.get_meta("planet_code", "")) == "R01",
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
	# Build the real board and request a far map in the same frame as world.build
	# does. No process tick should be needed to enqueue the one urgent board job.
	var svc = BAKER.service(self)
	await process_frame
	var qb: Node3D = BOARD.new()
	root.add_child(qb)
	var qrules := StubRules.new()
	qrules.v = {"hexes": hexes, "terrain": {}, "map": {"planet": {"q": 0, "r": 0, "R": 2}}}
	qrules.w = {"seed": 31}   # terran, seed 31: a map set nothing above asked for
	var existing: Array = svc._jobs.keys()
	qb.build(qrules)
	var bjob := PL.board_job(1, 31)
	var bkey := BAKER.board_key(bjob.key, bjob.code, bjob.params, bjob.size)
	_check(svc._jobs.keys() == existing + [bkey], "building the board did not enqueue exactly one job in the same frame")
	var far: String = svc.request_bake("far_z", bjob.code, bjob.params, Vector2i(8, 4), 32)
	_check(svc._jobs.keys() == existing + [bkey, far], "the board job did not precede the world's first bake")
	await qb.wait_planet()
	await svc.result(far)
	qb.queue_free()
	# item 2: a map asked for and not yet collected is never evicted, however many maps finish meanwhile
	var pin_img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	BAKER.remember("pin_probe", pin_img)
	BAKER._pin("pin_probe")
	for e in BAKER.CACHE_MAX + 4:
		BAKER.remember("evict_probe_%d" % e, Image.create(2, 2, false, Image.FORMAT_RGBA8))
	_check(BAKER._cache.has("pin_probe"), "a map waiting to be collected was evicted from the cache")
	_check(await svc.result("pin_probe") == pin_img and not BAKER._pins.has("pin_probe"), "result() did not return and release a pinned map")
	# item 2 follow-on (Artoo): with every slot pinned the cache may run over CACHE_MAX, and comes back once pins go
	BAKER._cache.clear()
	for e in BAKER.CACHE_MAX + 3:
		BAKER.remember("full_pin_%d" % e, Image.create(2, 2, false, Image.FORMAT_RGBA8))
		BAKER._pin("full_pin_%d" % e)
	_check(BAKER._cache.size() == BAKER.CACHE_MAX + 3, "a pinned map was evicted while every slot was in use")
	for e in BAKER.CACHE_MAX + 3:
		var got: Image = await svc.result("full_pin_%d" % e)
		_check(got != null, "result() lost a map the cap trim dropped while it was being collected (full_pin_%d)" % e)
	_check(BAKER._cache.size() <= BAKER.CACHE_MAX and BAKER._pins.is_empty(), "the cache stayed over its cap after every pin was released (%d)" % BAKER._cache.size())
	BAKER._cache.clear()
	_check(FileAccess.get_file_as_string("res://scenes/battle/battle.gd").contains(".drop_waiting(get_tree())"), "battle.gd no longer drops the old maps before its board builds")
	# A shader change invalidates both the single-map and new board cache entries.
	var code_now: String = PL.bake_code()
	var code_old := code_now + "\n// an older recipe"
	var bp := {"seed": 1.0, "kind": 5, "ca": Vector3.ONE, "cb": Vector3.ZERO, "cc": Vector3.ONE, "pass_id": 0}
	var csize := Vector2i(8, 4)
	var k_old := BAKER.cache_key("cache_probe", code_old, bp, csize)
	var k_new := BAKER.cache_key("cache_probe", code_now, bp, csize)
	_check(k_old != k_new, "a recipe change keeps the old bake cache key")
	_check(BAKER.board_key("board_probe", code_old, bp, csize) != BAKER.board_key("board_probe", code_now, bp, csize),
		"a recipe change keeps the old board cache key")
	var cdir := OS.get_user_data_dir().path_join("planet_v2_cache_paths")
	OS.set_environment("VS_WORLD_CACHE", cdir)
	var stale := Image.create(8, 4, false, Image.FORMAT_RGBA8)
	stale.fill(Color(1, 0, 0))
	_check(BAKER._save(k_old, stale, {}, {}, cdir), "the single-map save path did not write under its cache key")
	var hit: Image = await svc.bake("cache_probe", code_old, bp, csize, 32)
	_check(hit != null and hit.get_pixel(0, 0).r > 0.9, "the load path did not return the saved map")
	if DisplayServer.get_name() == "headless":
		var miss: Image = await svc.bake("cache_probe", code_now, bp, csize, 32)
		_check(miss == null, "a changed recipe loaded the old recipe's map from disk")
	DirAccess.remove_absolute(cdir.path_join(k_old + ".png"))
	OS.unset_environment("VS_WORLD_CACHE")
	# relief: one exact 32-bit float channel (Fable, PR 1776 M4)
	var packed := Image.create(4, 2, false, Image.FORMAT_RGBA8)
	packed.set_pixel(1, 0, Color8(0x9c, 0x41, 40, 200))
	var hf := BAKER.height_float(packed.duplicate())
	_check(hf.get_format() == Image.FORMAT_RF, "the relief is not one 32-bit float channel (format %d)" % hf.get_format())
	_check(absf(hf.get_pixel(1, 0).r - float(0x9c41) / 65535.0) < 1e-6, "the relief float is not the exact 16-bit height")
	# The first mip spans a low-byte carry. It must average the decoded heights, not rounded high and low bytes.
	for y in 2:
		packed.set_pixel(0, y, Color8(0x7f, 0xff, 40, 200))
		packed.set_pixel(1, y, Color8(0x80, 0x00, 80, 120))
	var split := BAKER.split_rocky_relief(packed)
	var base_mask := split.masks.get_pixel(0, 0)
	_check(absf(base_mask.r - 40.0 / 255.0) < 1e-6 and absf(base_mask.g - 200.0 / 255.0) < 1e-6,
		"R01 roughness and cloud coverage did not survive the split")
	var hs := split.height.get_data()
	var ms := split.masks.get_data()
	var m1 := split.masks.get_mipmap_offset(1)
	_check(absf(hs.decode_float(split.height.get_mipmap_offset(1)) - 0.5) < 1e-6, "R01 height mip rounded a packed byte")
	_check(ms[m1] == 60 and ms[m1 + 1] == 160, "R01 mask mip did not average roughness and cloud coverage separately")
	_check(PL.ROCKY_SURFACE.count("r01_sample(relief_height,") == 1, "ROCKY_SURFACE must sample relief height once")
	_check(BAKER.MOON_SIZE.x >= 2048, "moons bake below 2K (%s)" % str(BAKER.MOON_SIZE))
	# GLSL leaves smoothstep undefined when edge0 >= edge1 (Artoo, PR 1776): no literal pair in the planet shaders runs
	# high edge first; a falling edge is written 1.0 - smoothstep(lo, hi, x)
	var rx := RegEx.create_from_string("smoothstep\\(\\s*(-?[0-9.]+)\\s*,\\s*(-?[0-9.]+)\\s*,")
	for m in rx.search_all(FileAccess.get_file_as_string("res://world/world_planet.gd")):
		_check(float(m.get_string(1)) < float(m.get_string(2)), "world_planet.gd has a smoothstep with its edges reversed: " + m.get_string(0))
	# Issue 1939 (Neon): the noise hashes each lattice corner from a whole-number sum, so the GPU cannot fuse the corner's
	# offset into the hash's multiply and cut straight seams; no corner is hashed from "i + vec3(...)" any more
	var noise_src: String = preload("res://world/world_shaders.gd").NOISE
	_check(noise_src.contains("ivec3 ic = ivec3(i);") and not noise_src.contains("wh31(i + vec3("), "wvn3 hashes a corner from a float sum again (the RTX 5080 seam)")
	_check(not noise_src.contains("wh21(i + vec2("), "wvn hashes a corner from a float sum again (the RTX 5080 seam)")
	_check(not PL.BAKE_BODY.contains("vec3 c = b + vec3("), "craters_r hashes a corner from a float sum again")
	# the baked board planets lean their equator toward the camera, as the R01 worlds do (terran's ice cap sat mid-disc)
	_check(PL.BOARD_SURFACE.contains("bp_spin(bp_tilt(normalize(local_direction)), turn)"), "the baked board surface no longer tilts its equator toward the camera")
	# the cloud's lit side compares the map's own thickness with the sunward sample, both on the same scale (Artoo, PR 1983)
	_check(PL.BOARD_SURFACE.contains("(c_raw - c_sun)") and not PL.BOARD_SURFACE.contains("(cloud - c_sun)"), "cloud self-shading compares a reshaped cloud with a raw sunward sample")
	for lk in [1, 3, 4]:
		_check(float(PL.BOARD_LOOKS[lk].get("detail", 0.0)) > 0.0, "baked look %d draws no live fine detail" % lk)
	print("planet_v2_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
