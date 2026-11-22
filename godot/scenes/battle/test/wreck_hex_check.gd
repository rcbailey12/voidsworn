extends SceneTree
# Issue 1236: a dead cruiser or capital's hex blocks movement and fire in the rules ("wreck" event); the wreck has to
# sit in that hex. A real battle (scenario s1 against a Vanguard cruiser and a Dominion dreadnought) plays both kills
# through battle.gd, then the effects run on for SETTLE seconds. Checks, at quality low (kinematic pieces) and max
# (physics pieces):
#   every rules "wreck" event gets a board wreck: board.wrecks names the hex, the board's own terrain has a hulk there,
#     the edge mesh (the hex marker the grid shows, Z) was rebuilt with it, and the death is anchored in the effects;
#   something of the wreck is on the board: its own pieces, or the burnt hulk the board lays when a death left none;
#   no death piece leaves its hex: no main piece, fragment or thrown plate is farther out than the hex's rest radius
#     (radius times WRECK_LEASH_K) or where it was born; the main pieces rest inside the rest radius. Nothing shrinks
#     (Ryan, Nov 22, "ends crumble away"): pieces that cannot rest in the hex crumble, and the biggest piece is kept at
#     real size, centred on the hex.
#   (Artoo) a piece's limit is read where it was made, before its first move: a hand-made piece born inside and thrown
#     out stays inside, one born past the radius on purpose is drawn back;
#   every kept piece but the biggest sits inside its hex's six edges (at most PAST_MAX past one); the biggest, wider
#     than a hex on a cruiser or dreadnought, rests centred;
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
const PAST_MAX := 0.1     # world units: the settled wreck's real hull may sit at most this far past any of its hex's six edges

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
		_check(board.solid_edges != null and board.solid_edges.mesh != null, "%s %s: the blocked-hex edge was rebuilt" % [quality, id])
		_check(anchors.has(id), "%s %s: its death pieces are anchored to the hex" % [quality, id])
		var nodes: Array = DEATH.leashed_nodes(battle.gfx, id)
		var hull_laid: bool = board.wreck_hulls.has(id)
		var pieces: int = battle.gfx.wreck_pieces(id)
		_check(pieces > 0 or hull_laid, "%s %s: something of the wreck is on the board (pieces %d)" % [quality, id, pieces])
		var c: Vector3 = board.hex_world(at.x, at.y)
		var apothem: float = board.HS * cos(PI / 6.0)   # centre to the middle of an edge (the board's hexes have corners at 30 + 60 n degrees)
		var worst := 0.0
		var over := 0
		for nd in nodes:
			var off: Vector3 = DEATH.leash_centre(nd) - c
			off.y = 0.0
			worst = maxf(worst, off.length() / board.HS)
			# a physics plate can sit a frame's push past its limit (the leash runs before the physics step)
			if off.length() > float(nd.get_meta("leash_born", radius)) + radius * 0.1:
				over += 1
		_check(over == 0, "%s %s: no death piece is farther out than it was born or the hex (%d of %d)" % [quality, id, over, nodes.size()])
		# the main pieces: centres at rest inside the hex, and the whole settled wreck about the hex across (option 1)
		var main_far := 0.0
		var reach := 0.0
		var past := -INF   # the farthest any hull point sits past one of the hex's six edges (negative: inside)
		# Ryan, Nov 22 ("ends crumble away"): nothing shrinks; the biggest piece is kept at real size and centred, so it
		# alone may reach past the edges; every other kept piece rests inside them
		var mains: Array = DEATH.leashed_nodes(battle.gfx, id, true)
		var big_nd: Node3D = null
		for nd in mains:
			if big_nd == null or DEATH.leash_half(nd) > DEATH.leash_half(big_nd): big_nd = nd
		var shrunk := 0
		for nd in mains:
			for mi in (nd as Node).find_children("*", "MeshInstance3D", true, false):
				if absf((mi as MeshInstance3D).transform.basis.get_scale().x - 1.0) > 0.01: shrunk += 1
		_check(shrunk == 0, "%s %s: no wreck piece is shrunk (%d meshes scaled)" % [quality, id, shrunk])
		if big_nd != null:
			var boff: Vector3 = DEATH.leash_centre(big_nd) - c
			boff.y = 0.0
			_check(boff.length() <= radius * 0.15, "%s %s: the biggest piece rests centred on its hex (%.2f off)" % [quality, id, boff.length()])
		for nd in mains:
			var off: Vector3 = DEATH.leash_centre(nd) - c
			off.y = 0.0
			main_far = maxf(main_far, off.length())
			if nd == big_nd: continue
			for mi in (nd as Node).find_children("*", "MeshInstance3D", true, false):
				if (mi as MeshInstance3D).mesh == null: continue
				# the real geometry, not its box: a tumbled long piece's box runs well past its corners
				var xf: Transform3D = (mi as MeshInstance3D).global_transform
				for v in (mi as MeshInstance3D).mesh.get_faces():
					var q: Vector3 = xf * v - c
					reach = maxf(reach, Vector2(q.x, q.z).length())
					for e in 6:
						var a := deg_to_rad(60.0 * e)
						past = maxf(past, q.x * cos(a) + q.z * sin(a) - apothem)
		_check(main_far <= radius * 1.05, "%s %s: main pieces rest within the hex (%.2f, rest radius %.2f)" % [quality, id, main_far, radius])
		_check(past <= PAST_MAX, "%s %s: every kept piece but the biggest stays inside its hex's six edges (%.2f units past one)" % [quality, id, past])
		var crumbled := 0
		for w in battle.gfx.dstate["wrecks"]:
			if w["id"] == id: crumbled = int(w.get("crumbled", 0))
		var big_reach: float = DEATH.leash_half(big_nd) / board.HS if big_nd != null else 0.0
		print("WRECK_HEX %s %s hex=%s pieces=%d leashed=%d farthest=%.2f main=%.2f reach=%.2f hex radii (biggest piece %.2f) past_edge=%.2f units crumbled=%d hull_laid=%s" % [
			quality, id, k, pieces, nodes.size(), worst, main_far / board.HS, reach / board.HS, big_reach, past, crumbled, str(hull_laid)])
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
	# top down over the middle of the two wrecks
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
	# the check plays as the title screen's showcase (no HUD or turns), which hides the board grid; a battle shows it
	battle.board.fills.visible = true
	# the game's look and the grid (Z) at the battle's c170, then the grid closer in (c80) on the dreadnought's hex
	var close_on: Vector3 = mid
	for id in want:
		close_on = battle.board.hex_world(want[id].x, want[id].y)   # the last wreck: the dreadnought in this scenario
	for row in [["", false, 170.0, mid], ["_grid", true, 170.0, mid], ["_grid_c80", true, 80.0, close_on]]:
		LOOK.tactical = row[1]
		battle.board.apply_look(false)
		battle.cam.t = row[3]
		battle.cam.r = row[2]
		battle.cam.snap()
		label.text = "WH1236%s  wrecks in their blocking hex  c%d top down  +%d s after the kills%s" % [
			str(row[0]).to_upper(), int(row[2]), int(SETTLE), ("  rev " + rev) if rev != "" else ""]
		for i in 6:
			await process_frame
		var img := root.get_texture().get_image()
		if img.get_height() > 720:
			img.resize(roundi(img.get_width() * 720.0 / img.get_height()), 720, Image.INTERPOLATE_LANCZOS)
		var path := shot.get_basename() + str(row[0]) + ".png"
		preload("res://tools/picture_provenance.gd").save_png(img, path, preload("res://tools/picture_provenance.gd").capture_stage())
		print("WRECK_HEX shot ", path)
	LOOK.tactical = false


# Artoo on 52f0022c: a piece's limit was read after its first move, so a first step over the edge could pass as a hull
# born past it. Two hand-made pieces on a bare effects node: one born just inside the rest radius and thrown outward
# fast (its limit stays the rest radius and it ends inside), and one born past it on purpose, as a long hull's end is
# (its limit is where it was born, and it is drawn back inside).
func _first_step() -> void:
	var holder := Node3D.new()
	root.add_child(holder)
	var fx = load("res://fx/fx.gd").new()
	holder.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	var c := Vector3(50, 0, 50)
	var r := 8.0
	DEATH.anchor_wreck(fx, "t1", c, r)
	var cases := {"inside_thrown_out": [Vector3(r - 0.2, 0, 0), Vector3(400, 0, 0)], "born_past_on_purpose": [Vector3(r * 1.5, 0, 0), Vector3.ZERO]}
	var nodes := {}
	var wreck := {"id": "t1", "t0": fx.now, "nodes": [], "mats": [], "lights": [], "fires": [], "speed": 1.0}
	for name in cases:
		var nd := Node3D.new()
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1, 1, 1)
		mi.mesh = box
		nd.add_child(mi)
		fx.phys_root.add_child(nd)
		nd.global_position = c + cases[name][0]
		wreck["nodes"].append(nd)
		wreck["fires"].append({"node": nd, "vel": cases[name][1], "ang": Vector3.ZERO})
		nodes[name] = nd
	fx.dstate["wrecks"].append(wreck)
	var born := {}
	for i in 240:
		fx.step(STEP)
		if i == 0:
			for name in nodes: born[name] = float(nodes[name].get_meta("leash_born", -1.0))
	for name in nodes:
		var off: Vector3 = DEATH.leash_centre(nodes[name]) - c
		off.y = 0.0
		print("WRECK_HEX first step %s born_limit=%.2f end=%.2f (rest radius %.1f)" % [name, born[name], off.length(), r])
	_check(is_equal_approx(born["inside_thrown_out"], r), "a piece born inside and thrown out keeps the rest radius as its limit (%.2f)" % born["inside_thrown_out"])
	_check((DEATH.leash_centre(nodes["inside_thrown_out"]) - c).length() <= r + 0.01, "the thrown piece never crosses the rest radius")
	_check(is_equal_approx(born["born_past_on_purpose"], r * 1.5), "a piece born past the radius is limited to where it was born (%.2f)" % born["born_past_on_purpose"])
	_check((DEATH.leash_centre(nodes["born_past_on_purpose"]) - c).length() <= r, "a piece born past the radius is drawn back inside")
	holder.queue_free()
	await process_frame


func _run() -> void:
	LOOK.set_look("cine", false)
	await _first_step()
	for quality in ["low", "max"]:
		await _play(quality)
	print("WRECK_HEX failures=%d" % failures)
	quit(0 if failures == 0 else 1)
