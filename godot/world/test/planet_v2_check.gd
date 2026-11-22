extends SceneTree
# Issue 1765 (R419, Planets V2): the board planet is really wired, and the planet palettes keep the rules.
# 1. board.gd draws its planet through world_planet.gd install_board and never through the campaign map's icon shader;
#    battle.gd waits for it behind the loading cover (silent-regression trap 1 of the World V2 plan: an asset only a
#    shot script ever loads).
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
	# 1. wiring
	var board_src := FileAccess.get_file_as_string("res://render/board.gd")
	_check(board_src.contains("PL.install_board("), "board.gd _planet() does not call world_planet.gd install_board")
	_check(not board_src.contains("map3d_shaders"), "board.gd still loads the campaign map's icon shader for its planet")
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
		for key in ["flat", "a", "b", "c", "atmo"]:
			if L.has(key):
				_check(not _purple(L[key]), "board look %d %s leans indigo to purple" % [k, key])
	for i in WORLD.MOON_LOOKS.size():
		for key in ["a", "b", "c"]:
			_check(not _purple(WORLD.MOON_LOOKS[i][key]), "moon look %d %s leans indigo to purple" % [i, key])
	_check(BAKER.MOON_SIZE.x >= 2048, "moons bake below 2K (%s)" % str(BAKER.MOON_SIZE))
	print("planet_v2_check: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
