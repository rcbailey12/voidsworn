extends SceneTree
# godot --headless --path godot --script res://fx/test/frame_rate_steady_check.gd
# Issue 1467 (Astra pass 2, findings 4, 5 and 8): effects keep the same timeline at 15, 30 and 144 fps.
# 1. Hull recoil integrates the whole effect second (1.00 s) and lands in the same pose at every frame rate.
# 2. The fallback torpedo exhaust (_projectile_exhaust, used when a round has no kit trail) gives 14 puffs a second
#    (10 for rockets) within 1, and a hitch drops the overdue puffs instead of repeating bursts.
# 3. The hit-fragment pool uploads its texture only when pieces are added, never on an expiry, and nothing once all
#    pieces are gone. Prints the upload count for one staggered salvo.

const FX := preload("res://fx/fx.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const RATES := [15, 30, 144]
var failures := 0


func _init() -> void:
	GUARD.arm(self, "frame_rate_steady_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _fx() -> Node:
	var fx = FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	return fx


func _ship(fx) -> Node3D:
	var target := Node3D.new()
	root.add_child(target)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 2, 3)
	mi.mesh = box
	target.add_child(mi)
	fx.add_ship("hull", target, {"meshes": [mi], "shielded": false})
	return target


func _recoil(fps: int) -> Array:
	var fx = _fx()
	var target := _ship(fx)
	var ship = fx.ships["hull"]
	ship.weight = 4    # a capital: its reaction lasts past one second, so the whole second is integrated
	fx.step(1.0 / 60.0)
	var clock0: float = ship.react_clock
	ship.hit_react(fx, 6.0, Vector3(4.5, 0.8, 1.5), Vector3(0, 0, -1))
	var frames := fps
	for i in frames:
		fx.step(1.0 / float(fps))
	var out := [float(ship.react_clock) - clock0, target.rotation, target.position]
	fx.remove_ship("hull")
	fx.free()
	target.free()
	return out


func _puffs(fps: int, lk: String, hitch := 0.0, span := 1.0) -> int:
	var fx = _fx()
	var p := {"lk": lk, "k": 1.0, "last": 0.0, "eng": Color(1, 0.6, 0.3), "t0": 0.0, "t1": 1.0,
		"a": Vector3.ZERO, "b": Vector3(20, 0, 0), "c": Vector3(40, 0, 0)}
	fx.now = 0.0
	var n := 0
	var t := 0.0
	var dt := 1.0 / float(fps)
	var hitched := false
	while t < span - 1e-9:
		t = minf(t + dt, span)
		if hitch > 0.0 and not hitched and t >= 0.5:
			t += hitch
			hitched = true
		fx.now = t
		n += WEAP._projectile_exhaust(fx, p, Vector3.RIGHT)
	fx.free()
	return n


func _fragments() -> void:
	var fx = _fx()
	var pool: FRAGMENTS.Pool = fx.pools["plate"]
	var before: int = pool.uploads
	# one staggered salvo: three volleys 0.1 s apart, each with pieces living 0.4 to 1.3 s
	var now := 0.0
	for frame in 120:
		now = frame / 60.0
		fx.now = now
		if frame == 0 or frame == 6 or frame == 12:
			for j in 8:
				fx.hit_fragment(Vector3(j, 0, 0), now, 0.4 + 0.12 * j, Vector3.UP, 0.2, 1.0, 4.0, 0.1, Color.GRAY,
					FRAGMENTS.PLATE, false, {})
		pool.flush(now)
	var salvo: int = pool.uploads - before
	print("INFO staggered salvo of 24 pieces over 2 s at 60 fps: %d texture uploads of %d bytes each" % [salvo,
		pool.cap * FRAGMENTS.DATA_COLUMNS * 16])
	_check(salvo == 3, "fragment texture uploads once per volley (3), not on each expiry (got %d)" % salvo)
	_check(pool.particles.is_empty() and pool.mi.multimesh.visible_instance_count == 0,
		"every piece gone leaves the draw empty")
	var idle: int = pool.uploads
	for frame in 60:
		pool.flush(2.0 + frame / 60.0)
	_check(pool.uploads == idle, "an empty pool uploads nothing")
	fx.free()


func _run() -> void:
	var poses := []
	for fps in RATES:
		var r := _recoil(fps)
		poses.append(r)
		_check(absf(float(r[0]) - 1.0) < 0.005, "%d fps: recoil integrates %.3f s of one effect second" % [fps, r[0]])
	for i in range(1, poses.size()):
		var drot: float = (poses[i][1] as Vector3).distance_to(poses[0][1])
		var dpos: float = (poses[i][2] as Vector3).distance_to(poses[0][2])
		_check(drot < 0.004 and dpos < 0.02, "%d fps ends in the 15 fps pose (rotation off %.5f rad, position off %.4f)"
			% [RATES[i], drot, dpos])
	for fps in RATES:
		var torp := _puffs(fps, "torp")
		var rock := _puffs(fps, "rockets")
		_check(absi(torp - 14) <= 1, "%d fps: %d torpedo puffs in one second (14)" % [fps, torp])
		_check(absi(rock - 10) <= 1, "%d fps: %d rocket puffs in one second (10)" % [fps, rock])
	# 1.5 s with a 0.5 s stall at 0.5 s: 7 puffs, 3 at the stall (cap), 7 after = 17. Banking the 4 overdue puffs
	# would add them as extra bursts after the stall (21).
	var hitched := _puffs(60, "torp", 0.5, 1.5)
	_check(absi(hitched - 17) <= 1, "a 0.5 s hitch drops the overdue puffs (%d puffs, 17 expected)" % hitched)
	_fragments()
	print("PASS frame-rate steady effects" if failures == 0 else "FAIL frame-rate steady effects: %d" % failures)
	quit(0 if failures == 0 else 1)
