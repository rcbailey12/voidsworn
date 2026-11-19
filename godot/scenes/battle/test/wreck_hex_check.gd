extends SceneTree
# Issue 1236: a dead cruiser or capital's hex blocks movement and fire in the rules ("wreck" event); the wreck has to
# sit in that hex. A real battle (scenario s1 against a Vanguard cruiser and a Dominion dreadnought) plays both kills
# through battle.gd, then the effects run on for SETTLE seconds. Checks, at quality low (kinematic pieces) and max
# (physics pieces):
#   every rules "wreck" event gets a board wreck: board.wrecks names the hex, the board's own terrain has a hulk there,
#     the edge mesh (the hex marker the grid shows, Z) was rebuilt with it, and the death is anchored in the effects;
#   something of the wreck is on the board: its own pieces, or the burnt hulk the board lays when a death left none;
#   no death piece leaves its hex: every main piece, fragment and thrown plate rests within its leash (the hex's radius
#     times WRECK_LEASH_K, or a fifth of that past where it was born when a long hull already overhangs the hex).
#   a death that left no pieces gets the burnt hulk the map's own wrecks use, in its hex.
# Prints each wreck's farthest piece in hex radii. With "-- shot <png>" on a windowed run (the PC), also saves the
# top-down c170 picture at +8 s, 720 px tall, with its code name on it.
const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const DEATH := preload("res://fx/fx_death.gd")
const STEP := 1.0 / 60.0
const SETTLE := 8.0
const SEED := 1236

class Playback extends "res://scenes/battle/battle.gd":
	pass

var failures := 0
var shot := ""


func _init() -> void:
	GUARD.arm(self, "wreck_hex_check")
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "shot":
		shot = args[1]
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _play(quality: String) -> void:
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	var scenario: Dictionary = scenarios["s1"]
	scenario["enemies"] = ["h_vanguard", "h_dominion"]
	api.new_battle_scenario(scenario, SEED)
	api.R.B["terrain"].clear()
	var battle := Playback.new()
	battle.external = true
	battle.showcase = true
	battle.args["quality"] = quality
	root.add_child(battle)
	await battle._begin(api)
	_check(battle.gfx != null, "%s: the effects are on" % quality)
	if battle.gfx == null:
		battle.free()
		return
	# the deaths play on the game's own clocks (the kill cut-in waits on the effects clock); the settle after is stepped
	battle.cine = "off"
	battle.user_speed = 1.0
	# both enemy ships die where they stand
	api._enter()
	for u in api.R.alive("enemy"):
		u["hp"] = 0
		api.R.killUnit(u, null)
	api._leave(true)
	var events := api.take_events()
	var want := {}
	for e in events:
		if e["t"] == "wreck":
			want[str(e["unit"])] = Vector2i(int(e["q"]), int(e["r"]))
	_check(want.size() == 2, "%s: the rules lay two wrecks (got %d)" % [quality, want.size()])
	await battle._play_batch({"events": events, "view": api.view()})
	battle.gfx.manual = true
	for i in roundi(SETTLE / STEP):
		battle.gfx.step(STEP)
		# the physics pieces (max) move on the physics clock; the kinematic ones (low) only on the effects clock
		if quality == "low": await process_frame
		else: await physics_frame
	# the board's late check for a death that left no pieces runs WRECK_CHECK_S after the death
	var spare: float = battle.WRECK_CHECK_S - SETTLE
	if spare > 0.0:
		await create_timer(spare + 0.2).timeout
	var board = battle.board
	var anchors: Dictionary = battle.gfx.dstate.get("anchors", {})
	var radius: float = board.HS * battle.WRECK_LEASH_K
	for id in want:
		var at: Vector2i = want[id]
		var k: String = board.key(at.x, at.y)
		_check(board.wrecks.get(id, "") == k, "%s %s: the board has a wreck at %s" % [quality, id, k])
		_check(str(board.VW.get("terrain", {}).get(k, "")) == "hulk", "%s %s: the board's terrain blocks %s" % [quality, id, k])
		_check(board.gas_edges != null and board.gas_edges.mesh != null, "%s %s: the blocked-hex edge was rebuilt" % [quality, id])
		_check(anchors.has(id), "%s %s: its death pieces are anchored to the hex" % [quality, id])
		var nodes: Array = DEATH.leashed_nodes(battle.gfx, id)
		var hull_laid: bool = board.wreck_hulls.has(id)
		var pieces: int = battle.gfx.wreck_pieces(id)
		_check(pieces > 0 or hull_laid, "%s %s: something of the wreck is on the board (pieces %d)" % [quality, id, pieces])
		var c: Vector3 = board.hex_world(at.x, at.y)
		var worst := 0.0
		var over := 0
		for nd in nodes:
			var off: Vector3 = (nd as Node3D).global_position - c
			off.y = 0.0
			var lim: float = float(nd.get_meta("leash_r", radius))
			worst = maxf(worst, off.length() / board.HS)
			if off.length() > lim + 0.05:
				over += 1
		_check(over == 0, "%s %s: every death piece rests inside its leash (%d of %d outside)" % [quality, id, over, nodes.size()])
		print("WRECK_HEX %s %s hex=%s pieces=%d leashed=%d farthest=%.2f hex radii hull_laid=%s" % [
			quality, id, k, pieces, nodes.size(), worst, str(hull_laid)])
	if quality == "low" and not want.is_empty():
		# a death that left no pieces (the cold-kill fallback PR 1231 found): the board lays the burnt hulk in the hex
		var id: String = want.keys()[0]
		battle.gfx.clear_wreck(id)
		await process_frame
		battle._lay_wreck(id)
		await create_timer(battle.WRECK_CHECK_S + 0.3).timeout
		_check(board.wreck_hulls.has(id), "%s %s: with no pieces left the board lays the burnt hulk in its hex" % [quality, id])
		print("WRECK_HEX %s %s no pieces: burnt hulk laid=%s" % [quality, id, str(board.wreck_hulls.has(id))])
	if shot != "" and quality == "max" and DisplayServer.get_name() != "headless":
		await _shot(battle, want)
	battle.free()


func _shot(battle: Playback, want: Dictionary) -> void:
	# top down at the battle's c170 distance, over the middle of the two wrecks; the game's look first, then the grid (Z)
	var mid := Vector3.ZERO
	for id in want:
		mid += battle.board.hex_world(want[id].x, want[id].y)
	mid /= maxf(want.size(), 1)
	if not battle.cam.topdown: battle.cam.toggle_top()
	battle.cam.t = mid
	battle.cam.r = 170.0
	battle.cam.snap()
	var layer := CanvasLayer.new()
	layer.layer = 50
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_constant_override("outline_size", 6)
	label.position = Vector2(24, 18)
	layer.add_child(label)
	battle.add_child(layer)
	var rev := OS.get_environment("WH_REV")
	for grid in [false, true]:
		LOOK.tactical = grid
		battle.board.apply_look(false)
		label.text = "WH1236%s  wrecks in their blocking hex  c170 top down  +%d s after the kills%s" % [
			"_GRID" if grid else "", int(SETTLE), ("  rev " + rev) if rev != "" else ""]
		for i in 6:
			await process_frame
		var img := root.get_texture().get_image()
		if img.get_height() > 720:
			img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
		var path := shot if not grid else shot.get_basename() + "_grid.png"
		preload("res://tools/picture_provenance.gd").save_png(img, path)
		print("WRECK_HEX shot ", path)
	LOOK.tactical = false


func _run() -> void:
	LOOK.set_look("cine", false)
	for quality in ["low", "max"]:
		await _play(quality)
	print("WRECK_HEX failures=%d" % failures)
	quit(0 if failures == 0 else 1)
