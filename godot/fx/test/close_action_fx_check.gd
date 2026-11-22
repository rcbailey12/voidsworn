extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1524 (fx/API.md section 11): the battle plays the approved close-action looks, not a generic pop. A rules "ram"
# event calls volley(unit, "torp", target, {weapon_id: "ram"}) (the crumple on the target, a smaller one on the rammer,
# the biggest shove and the zoom punch); a "board" event calls board(unit, target, result) (pried hatch, venting, inside
# light, then a dark gash); a "command" event calls command(ship, id), on the unit it names or, for the player's command
# (no unit), on that side's living flagship. The fallback pop plays only when the fx layer drew nothing. Headless.
#   godot --headless --path godot --script res://fx/test/close_action_fx_check.gd
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
var failures := 0

class BattleFixture extends "res://scenes/battle/battle.gd":
	func _ready() -> void:
		set_process(false)

class TestHud extends CanvasLayer:
	var k := 1.0
	var banners: Array = []
	func letterbox(_on: bool) -> void:
		pass
	func add_log(_m: String, _c: String) -> void:
		pass
	func banner(t: String, _c: Color) -> void:
		banners.append(t)
	func make_float(_t: String, _c: Color) -> Label:
		var l := Label.new()
		add_child(l)
		return l
	func col_of(c: Color) -> Color:
		return c

class TestSfx extends Node:
	func play(_n: String, _o := {}) -> void:
		pass
	func boom(_k: float, _p: Vector3) -> void:
		pass

# The real fx layer, with each close-action call and each fallback pop written down.
class RecFX extends "res://fx/fx.gd":
	var calls: Array = []
	func volley(a: String, kind: String, t: String, opts := {}) -> Dictionary:
		var r: Dictionary = super.volley(a, kind, t, opts)
		calls.append(["volley", a, kind, t, str(opts.get("weapon_id", "")), (r.get("impacts", []) as Array).size()])
		return r
	func board(a: String, t: String, res := "", pace := 1.0) -> float:
		var r: float = super.board(a, t, res, pace)
		calls.append(["board", a, t, res, r])
		return r
	func command(id: String, cmd := "") -> void:
		calls.append(["command", id, cmd])
		super.command(id, cmd)
	func pop(p: Vector3, T: float, col: Color, size: float, i: float, n := Vector3.UP, life := 0.14, px := 0.0) -> void:
		calls.append(["pop"])
		super.pop(p, T, col, size, i, n, life, px)


func _init() -> void:
	GUARD.arm(self, "close_action_fx_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1
		push_error(message)


func _named(fx: RecFX, what: String) -> Array:
	return fx.calls.filter(func(c): return c[0] == what)


func _run() -> void:
	var battle := BattleFixture.new()
	root.add_child(battle)
	battle.cam = battle.CamRig.new()
	battle.add_child(battle.cam)
	var hud := TestHud.new()
	battle.hud = hud
	battle.add_child(hud)
	battle.sfx = TestSfx.new()
	battle.add_child(battle.sfx)
	battle.speed = 0.05
	battle.PACE = {"banner": 100.0}
	var fx := RecFX.new()
	battle.gfx = fx
	battle.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low"})
	# two hulls side by side, bows facing: the rammer "a" (the player's flagship) and the target "b"
	for i in 2:
		var id: String = ["a", "b"][i]
		var sv := SV.new()
		battle.add_child(sv)
		sv.set_process(false)
		sv.ring = MeshInstance3D.new()
		sv.add_child(sv.ring)
		sv.L = 24.0
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(24, 4, 6)
		bm.subdivide_width = 11
		bm.subdivide_height = 2
		bm.subdivide_depth = 3
		mi.mesh = bm
		sv.add_child(mi)
		sv.position = Vector3(0, 0, i * 14.0)
		fx.add_ship(id, sv, {"faction": "voidsworn" if i == 0 else "hegemony", "cls": "Cruiser", "size": 0.8, "meshes": [mi]})
		battle.views[id] = sv
		battle.VU[id] = {"name": "Ship " + id, "side": "player" if i == 0 else "enemy", "size": 0.8, "flagship": i == 0, "fac": "voidsworn" if i == 0 else "hegemony"}
		battle.disp[id] = {"hp": 40.0}

	print("-- ram")
	await battle._play_event({"t": "ram", "unit": "a", "target": "b", "path": [], "dmg": 9, "recoil": 3, "soak": 0, "section": "mid"})
	var v := _named(fx, "volley")
	_check(v.size() == 1, "a ram makes one volley call (%d)" % v.size())
	if v.size() == 1:
		_check(v[0][1] == "a" and v[0][2] == "torp" and v[0][3] == "b" and v[0][4] == "ram", "the ram volley is a -> torp -> b with weapon_id ram (%s)" % str(v[0]))
		_check(int(v[0][5]) > 0, "the ram volley drew its impact (%d)" % int(v[0][5]))
	_check(_named(fx, "pop").is_empty(), "no generic pop when the ram look played")
	_check(is_equal_approx(float(battle.disp["b"]["hp"]), 31.0) and is_equal_approx(float(battle.disp["a"]["hp"]), 37.0), "the ram still takes its damage and recoil off the drawn hulls")
	fx.calls.clear()

	print("-- board")
	await battle._play_event({"t": "board", "unit": "a", "target": "b", "result": "fight", "kill": 2, "loss": 1})
	var b := _named(fx, "board")
	_check(b.size() == 1, "a boarding makes one board call (%d)" % b.size())
	if b.size() == 1:
		_check(b[0][1] == "a" and b[0][2] == "b" and b[0][3] == "fight", "board(a, b, result) (%s)" % str(b[0]))
		_check(float(b[0][4]) > 0.0, "the breach played (%.2f s)" % float(b[0][4]))
	_check(_named(fx, "pop").is_empty(), "no generic pop when the breach played")
	# issue 1547 (Artoo, PR 1549): the boarding lines end with the battle's hold, at normal and fast pace
	for pace in [1.0, 0.25]:
		fx.board_lines_s = 0.0
		fx.board("a", "b", "fight", pace)
		var want: float = fx.board_hold_ms() / 1000.0 * pace
		_check(fx.board_lines_s > 0.0 and fx.board_lines_s <= want + 0.001, "the boarding lines end with the hold at pace %.2f (%.2f s, hold %.2f s)" % [pace, fx.board_lines_s, want])
	# look C's inside flashes are staggered over the hold and end inside it, at normal and fast pace
	var was: String = fx.board_look
	fx.board_look = "C"
	for pace in [1.0, 0.25]:
		fx.board("a", "b", "fight", pace)
		var want: float = fx.board_hold_ms() / 1000.0 * pace
		_check(fx.board_inside_s > 0.0 and fx.board_inside_s <= want + 0.001, "look C's inside flashes end with the hold at pace %.2f (%.2f s, hold %.2f s)" % [pace, fx.board_inside_s, want])
	# Sol review: with the fx clock slowed (kill slow-mo), each pop's fx-time life shrinks with it, so it still ends
	# inside the battle's scene-timer hold
	await create_timer(fx.board_hold_ms() / 1000.0 + 0.1).timeout   # the pace checks' pops start first
	fx._speed = 0.35
	fx._death_slow_left = 30.0
	fx.board_pop_lives.clear()
	fx.board("a", "b", "fight", 1.0)
	await create_timer(fx.board_hold_ms() / 1000.0 + 0.1).timeout
	var lives: Array = fx.board_pop_lives.duplicate()
	var life_max: float = minf(0.35, fx.board_hold_ms() / 1000.0 * 0.2)
	_check(lives.size() == 9 and lives.all(func(v): return float(v) <= life_max * 0.35 + 0.001), "look C's pops take a slowed fx clock's speed (%s, want 9 at most %.3f)" % [str(lives), life_max * 0.35])
	fx._death_slow_left = 0.0
	fx._speed = 1.0
	# Sol review: each hatch mark keeps the width it was made with, so a regrade made while another look is active (a
	# second boarding on the same spot grows the old mark) never swaps an r0 hatch to B's width
	var widths := []
	for lk in ["r0", "B"]:
		fx.board_look = lk
		fx.board("b", "a", "fight", 1.0)
		var hk := -1.0
		for m in (fx.ships["a"] as Object).get("_marks"):
			if m.look == "board":
				hk = m.hatch_k
		widths.append(hk)
	fx.board_look = was
	_check(widths == [1.0, 1.0], "an r0 hatch regrown while look B is active keeps its own width (%s, want [1, 1])" % str(widths))
	fx.board_look = was
	fx.calls.clear()
	# no boarding point to draw at (an unknown target): the pop stands in
	await battle._play_event({"t": "board", "unit": "a", "target": "nobody", "result": "fight", "kill": 0, "loss": 0})
	_check(_named(fx, "pop").size() == 1, "the generic pop stands in when the fx layer drew no breach")
	fx.calls.clear()

	print("-- command")
	await battle._play_event({"t": "command", "side": "player", "id": "vex", "tier": 0, "unit": null})
	var c := _named(fx, "command")
	_check(c.size() == 1 and c[0][1] == "a" and c[0][2] == "vex", "the player's command pulses its flagship (%s)" % str(c))
	_check(hud.banners.size() == 1, "the command banner still shows")
	fx.calls.clear()
	await battle._play_event({"t": "command", "side": "enemy", "id": "doom", "tier": 1, "unit": "b"})
	c = _named(fx, "command")
	_check(c.size() == 1 and c[0][1] == "b", "an enemy boss's command pulses the boss (%s)" % str(c))
	fx.calls.clear()
	battle.VU["a"]["dead"] = true
	await battle._play_event({"t": "command", "side": "player", "id": "vex", "tier": 0, "unit": null})
	_check(_named(fx, "command").is_empty(), "no pulse when the side has no living flagship")

	fx.release()
	battle.queue_free()
	await process_frame
	print("CLOSE_ACTION_FX %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
