extends RefCounted
# Acid Thorns (issue 1877, R437): the Chorus close-in weapon (rules id `tendril`: range 1, 2 shots, acid) is one heavy bone
# thorn grown in a gland and snapped out at the target. Ryan, Nov 24 2026: "Yes bone bolts but we should make sure we actually
# build those not with code and improve the quality" and the name "Acid Thorns". It replaced the old tendril lash (R437:
# "scrap tendrils, that doesn't make sense as a space weapon") and Muse's three other options.
#
# The thorn is a built body, never a code shape: tools/blender/build_sheets/munitions/munitions.py chorus_bolt builds it from
# the Chorus part kit and bakes it with the Chorus paint stack into fx/munition_bodies/chorus_bolt.glb (a pale ridged bone
# point, barbs, dark horn splints round a bile core that shows only in the cracks, sinew wraps, a knuckled butt). The game
# loads it like the torpedoes (fx_weapons._kit_body) with the hull finish (R362).
#
# The gland swells, then the thorn snaps out point first with a slow roll and a trail of bile. On contact the
# intact thorn is gone, with bone and horn shards and an acid splash at the shield or hull. The hull keeps its
# etched mark and acid spot (R398), not the thorn. A miss flies on past and fades.
#
# Palette (factions.md, The Chorus): bone to horn, olive-brown tissue, the faction's bile light from inside only; no lime
# surfaces, no eyes, no metal.

const BONE := Color(0.66, 0.55, 0.38)       # pale bone chips
const ACID := Color(0.30, 0.32, 0.07)       # the acid on the plate: a dark bile wet, never a flat lime glow (Ryan, Nov 24)
const SPEED := 52.0      # world units a second, times fx.unit
const WIND := 0.30       # the gland's swell before the shot
const GAP := 0.35        # spacing of the two shots, times the volley beat
const SCALE := 0.75      # the body against the munition frame (2.3 long). Ryan, Nov 24: "The scale is wrong, similar to past
#                          torpedoes. It looks gigantic": a thorn is smaller than a torpedo (torpedoes draw at 1.0 of the frame)
const TIP := 1.15        # the point's distance from the body's origin, in the munition frame
const MISS_FADE := 0.6


static func _body(fx, k: float) -> Node3D:
	var FXW = load("res://fx/fx_weapons.gd")
	var node := Node3D.new()
	node.name = "fx_acid_thorn"
	var kit: Node3D = FXW._kit_body(fx, "bolt", "chorus")
	if kit != null:
		node.add_child(kit)
	node.scale = Vector3.ONE * k * SCALE * fx.unit
	node.visible = false
	fx.add_child(node)
	return node


# One shot. Returns [fire time, impact time, end time] like fx_weapons._shot's arms.
static func shot(fx, from: Vector3, mn: Vector3, to: Vector3, T0: float, beat: float, col: Color, ka: float, A,
		tg: Dictionary, hull_delay := 0.0) -> Array:
	var dv := to - from
	var dist := maxf(dv.length(), 0.01)
	var dir := dv / dist
	var tf: float = T0 + WIND + beat * GAP
	var bk: float = ka * 1.1
	var ft: float = dist / (SPEED * fx.unit) + hull_delay
	var ti: float = tf + ft
	var out: Vector3 = (mn if mn.length_squared() > 0.01 else dir).normalized()
	# the gland swells and glows from inside, then a ring of wet tissue snaps open as the thorn leaves (nothing burns)
	fx.spr(from, tf - WIND, WIND, col, 0.9, 0.4 * bk, 1.0 * bk, 15)
	fx.ring(from + dir * 0.4 * bk, dir, tf, 0.35, BONE.lerp(col, 0.3), 1.2, 0.4 * bk, 2.6 * bk, 3, 0.0, 0.0, 22.0)
	# no spark lines anywhere on this weapon (Ryan, Nov 24: "random low quality sparks"): a few heavy wet drops leave
	# the gland with it and fall away
	for s in 3:
		fx.spr(from, tf + s * 0.02, 0.9, ACID, 0.9, 0.16 * bk, 0.08 * bk, 15, (dir + fx.rdir() * 0.5).normalized() * 3.0 * bk, 0.6)
	fx.light(from + out * 1.2 * bk, tf - WIND * 0.5, WIND * 0.5 + 0.25, 3.5, col, 1)
	if A != null and A.hull_pivot != null:
		# the ship shudders once with the effort (a muscle squeeze, not a gun's recoil)
		var inv: Transform3D = A.xf().affine_inverse()
		var lp: Vector3 = inv * from
		var back: Vector3 = (inv.basis * (-dir)).normalized()
		fx.later(tf, func l_squeeze() -> void: A.hit_react(fx, 0.3, lp, back, "recoil"))
	var miss := bool(tg.get("miss", false))
	var node := _body(fx, bk)
	var list: Array = fx.dstate.get("thorn_proj", [])
	list.append({"node": node, "t0": tf, "t1": ti, "a": from + out * 0.3 * bk, "b": to, "dir": dir, "seed": fx.rng.randf() * TAU,
		"k": bk, "miss": miss, "spd": dist / maxf(ft, 0.001)})
	fx.dstate["thorn_proj"] = list
	# The contact hides the travelling light with the body. A miss keeps its old fly-by lighting.
	if miss:
		fx.light(from + dir * dist * 0.5, tf, ft, 1.4, col, 1)
	else:
		fx.light_source(node, Vector3.ZERO, col, 1.4)
	for s in 3:
		var u := (s + 0.5) / 3.0
		var v: Vector3 = Vector3(0, -1.5, 0) + fx.rdir() * 0.6
		if not miss:
			v = v.slide(dir) - dir * 0.15
		fx.spr(from + dir * dist * u, tf + ft * u, 0.8, ACID, 0.7, 0.1 * bk, 0.05 * bk, 15, v, 0.5)
	return [tf, ti, ti + 0.4]


# Reuse the shared shard pool, with the thorn's bone/horn finish and no metal plate ejecta.
static func impact(fx, tg: Dictionary, T: float, col: Color, k: float) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var shield := bool(tg.get("shield", false))
	var FXW = load("res://fx/fx_weapons.gd")
	fx.spr(p, T, 0.10, BONE.lerp(col, 0.3), 1.9, 0.6 * k, 1.4 * k, 0)
	for j in (3 if shield else 4):
		var v: Vector3 = FXW._outward(n, fx.rcone(n, 1.1), 0.25)
		var speed: float = fx.rng.randf_range(2.6, 6.0) * k
		fx.shd(p + n * 0.1 * k, T, 0.55 + 0.08 * j, v * speed, (0.18 if shield else 0.26) * k, 0.0, 6.0 + j, 0.45, 5.0 + j % 2)
		fx.spr(p, T, 0.42, ACID.lerp(col, 0.28), 0.9, 0.25 * k, 0.12 * k, 15, v * speed * 0.7, 0.6)
	if not shield:
		var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		_pool(fx, p, n, t1, n.cross(t1).normalized(), T + 0.2, col, k, 1.1, 5)


# The acid at work: small bubbles popping on the etched mark for a while, with thin grey fumes. The shared acid mark
# (fx_breach S_ACID, a dark etched burn) is the acid itself.
static func _pool(fx, p: Vector3, n: Vector3, t1: Vector3, t2: Vector3, T: float, col: Color, k: float, size: float, bubbles: int) -> void:
	for j in bubbles:
		var off: Vector3 = (t1 * fx.rng.randf_range(-1.0, 1.0) + t2 * fx.rng.randf_range(-1.0, 1.0)) * size * 0.6 * k
		var at: float = T + fx.rng.randf_range(0.1, 2.6)
		fx.spr(p + off + n * 0.15 * k, at, 0.35, ACID.lerp(col, 0.3), 0.6, 0.06 * k, 0.2 * k, 15, n * 0.6 * k, 0.5)
	for j in 3:
		fx.spr(p + n * 0.5 * k, T + 0.3 + j * 0.7, 1.6, Color(0.34, 0.33, 0.3), 0.35, 0.4 * k, 1.4 * k, 20, n * 1.2 * k, 0.4)


static func update(fx, _dt: float) -> void:
	var list: Array = fx.dstate.get("thorn_proj", [])
	if list.is_empty():
		return
	var keep: Array = []
	for p in list:
		var node = p["node"]
		if not is_instance_valid(node):
			continue
		var n3 := node as Node3D
		var now: float = fx.now
		if now < float(p["t0"]):
			keep.append(p)
			continue
		var t1: float = p["t1"]
		var miss: bool = p["miss"]
		var age := now - t1
		if miss and age >= MISS_FADE:
			n3.hide()
			n3.queue_free()
			continue
		var d: Vector3 = p["dir"]
		var z := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD).normalized()
		var along := Basis(d, z.cross(d).normalized(), z)
		var s: float = float(p["k"]) * SCALE * fx.unit
		var finish: Vector3 = (p["b"] as Vector3) - d * TIP * s
		var u := clampf((now - float(p["t0"])) / maxf(t1 - float(p["t0"]), 0.001), 0.0, 1.0)
		var pos: Vector3 = (p["a"] as Vector3).lerp(finish, u)
		var roll: float = ((now if miss else minf(now, t1)) - float(p["t0"])) * 6.0 + float(p["seed"])
		if miss and age > 0.0:
			pos += d * float(p["spd"]) * age
			s *= 1.0 - smoothstep(0.0, MISS_FADE, age)
		n3.global_transform = Transform3D((along * Basis(Vector3.RIGHT, roll)).scaled(Vector3.ONE * s), pos)
		if not miss and age >= 0.0:
			n3.hide()
			n3.queue_free()
			continue
		n3.show()
		keep.append(p)
	fx.dstate["thorn_proj"] = keep
