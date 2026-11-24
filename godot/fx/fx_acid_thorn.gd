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
# The shot: the gland swells and glows from inside, the thorn snaps out point first with a slow roll, bile drips off it in
# flight; it drives into the plating and sticks (the barbs hold it), acid sheets down the hull and pools; then the thorn
# crumbles, its own built pieces breaking apart and drifting off. A miss flies on past and fades; a shield hit shatters it at
# the shield. The hull mark, the acid spot (R398) and the shared bio splat still come from fx_weapons._impact (R362: one hit
# language).
#
# Palette (factions.md, The Chorus): bone to horn, olive-brown tissue, the faction's bile light from inside only; no lime
# surfaces, no eyes, no metal.

const BONE := Color(0.66, 0.55, 0.38)       # pale bone chips
const HORN := Color(0.22, 0.16, 0.10)       # dark horn chips (the splints)
const ACID := Color(0.30, 0.32, 0.07)       # the acid on the plate: a dark bile wet, never a flat lime glow (Ryan, Nov 24)
const SPEED := 52.0      # world units a second, times fx.unit
const WIND := 0.30       # the gland's swell before the shot
const GAP := 0.35        # spacing of the two shots, times the volley beat
const SCALE := 0.75      # the body against the munition frame (2.3 long). Ryan, Nov 24: "The scale is wrong, similar to past
#                          torpedoes. It looks gigantic": a thorn is smaller than a torpedo (torpedoes draw at 1.0 of the frame)
const STICK := 1.15      # seconds the thorn stays stuck in the plating before it crumbles
const CRUMBLE := 0.7     # seconds the crumble takes
const TIP := 1.15        # the point's distance from the body's origin, in the munition frame
const BITE := 0.75       # how deep the point drives into the plate, in the same frame (most of the head)
const SLAM := 0.05       # seconds the point takes to drive in once it strikes: a hard stop, never a slow push


static func _body(fx, k: float) -> Node3D:
	var FXW = load("res://fx/fx_weapons.gd")
	var node := Node3D.new()
	node.name = "fx_acid_thorn"
	var kit: Node3D = FXW._kit_body(fx, "bolt", "chorus")
	if kit != null:
		node.add_child(kit)
		# each built piece gets its own drift for the crumble (the pieces are the glb's own parts: head, splints, core,
		# sinew, barbs, butt)
		for c in kit.get_children():
			if c is Node3D:
				var p := c as Node3D
				p.set_meta("home", p.transform)
				p.set_meta("drift", (fx.rdir() + Vector3(0.0, 0.3, 0.0)).normalized() * fx.rng.randf_range(0.6, 1.6))
				p.set_meta("spin", fx.rdir())
	node.scale = Vector3.ONE * k * SCALE * fx.unit
	node.visible = false
	fx.add_child(node)
	return node


# One shot. Returns [fire time, impact time, end time] like fx_weapons._shot's arms.
static func shot(fx, from: Vector3, mn: Vector3, to: Vector3, T0: float, beat: float, col: Color, ka: float, A,
		tg: Dictionary, Tg = null) -> Array:
	var dv := to - from
	var dist := maxf(dv.length(), 0.01)
	var dir := dv / dist
	var tf: float = T0 + WIND + beat * GAP
	var bk: float = ka * 1.1
	var ft: float = dist / (SPEED * fx.unit)
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
	var shield := bool(tg.get("shield", false))
	var stuck := not miss and not shield
	var end: float = ti + (STICK + CRUMBLE if stuck else (0.6 if miss else 0.0))
	var node := _body(fx, bk)
	var list: Array = fx.dstate.get("thorn_proj", [])
	list.append({"node": node, "t0": tf, "t1": ti, "a": from + out * 0.3 * bk, "b": to, "dir": dir, "seed": fx.rng.randf() * TAU,
		"k": bk, "end": end, "stuck": stuck, "miss": miss, "spd": dist / maxf(ft, 0.001), "ship": Tg})
	fx.dstate["thorn_proj"] = list
	# a faint bile light rides with the thorn, so it reads at the battle camera as well as close up; bile drips off it
	fx.light(from + dir * dist * 0.5, tf, ft, 1.4, col, 1)
	for s in 3:
		var u := (s + 0.5) / 3.0
		fx.spr(from + dir * dist * u, tf + ft * u, 0.8, ACID, 0.7, 0.1 * bk, 0.05 * bk, 15, Vector3(0, -1.5, 0) + fx.rdir() * 0.6, 0.5)
	if shield:
		_shatter(fx, to, -dir, ti, bk, 10)
	elif stuck:
		_hit_matter(fx, tg, ti, col, ka, Tg)
		# the crumble's dust and chips start where the thorn is then (it rides the ship it is stuck in)
		fx.later(ti + STICK, func l_crumble() -> void:
			if is_instance_valid(node) and node.visible:
				_crumble_matter(fx, node.global_position, -node.global_transform.basis.x.normalized(), fx.now, col, bk))
	return [tf, ti, ti + 0.4]


# What the thorn leaves on the plating, on top of the shared bio splat (fx_weapons._bio_splat): a spray of bone chips as the
# point bites, then acid sheeting down the plate from the wound and pooling.
static func _hit_matter(fx, tg: Dictionary, T: float, col: Color, k: float, Tg = null) -> void:
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := n.cross(t1).normalized()
	# the strike: a short hard crack where bone meets plate, a few real torn plate pieces (the shared 3D fragments in the
	# struck hull's own finish, fx_weapons._throw_debris) and a ring and puff of bone dust. No spark lines (Ryan, Nov 24:
	# "random low quality sparks that shoot out that don't fit the quality bar"). The flash takes the struck hull's own hit
	# palette (fx_weapons._impact_response and _impact_color; Artoo on PR 1904, issue 1991).
	var FXW = load("res://fx/fx_weapons.gd")
	var response = FXW._impact_response(Tg)
	fx.spr(p + n * 0.15 * k, T, 0.08, FXW._impact_color(response, Tg, Color(1.0, 0.95, 0.82)), 6.0, 0.5 * k, 1.4 * k, 0)
	if Tg != null and response.debris != "drop" and not response.fire_body:
		FXW._throw_debris(fx, p, n, n, T, k, 2, 6.0, 0.14, 0.0, "shell", Tg.faction, false, Tg)
	fx.ring(p + n * 0.1 * k, n, T, 0.4, Color(0.62, 0.55, 0.42), 0.9, 0.3 * k, 2.2 * k, 3, 0.0, 0.0, 18.0)
	fx.spr(p + n * 0.3 * k, T, 1.1, Color(0.5, 0.44, 0.34), 0.5, 0.4 * k, 1.6 * k, 20, n * 1.2 * k, 0.6)
	fx.shake(T, 0.06, p)
	var down := (Vector3.DOWN - n * Vector3.DOWN.dot(n))
	down = down.normalized() if down.length_squared() > 0.01 else t1
	for j in 10:
		var off: Vector3 = (t1 * fx.rng.randf_range(-0.6, 0.6)) * k
		fx.spr(p + off + n * 0.1 * k, T + 0.05 + j * 0.08, 1.8, ACID, 0.6, 0.22 * k, 0.12 * k, 15, down * fx.rng.randf_range(1.0, 2.2) * k, 0.4)
	_pool(fx, p, n, t1, t2, T + 0.2, col, k, 1.1, 7)


# The crumble: a puff of bone dust and a few chips, horn and bone, as the built pieces break apart (update() moves them).
static func _crumble_matter(fx, p: Vector3, n: Vector3, T: float, col: Color, k: float) -> void:
	fx.spr(p, T, 1.4, Color(0.48, 0.42, 0.32), 0.45, 0.6 * k, 2.4 * k, 20, n * 0.8 * k, 0.5)
	_shatter(fx, p, n, T, k, 8)
	fx.spr(p, T + 0.05, 0.8, ACID, 0.6, 0.3 * k, 0.9 * k, 15)


# Bone and horn grit: soft dust puffs that drift and settle, no spark lines (Ryan, Nov 24). The real breaking pieces are
# the thorn's own built parts (update() and _crumble).
static func _shatter(fx, p: Vector3, n: Vector3, T: float, k: float, count: int) -> void:
	for j in mini(count, 4):
		var v: Vector3 = (n * 0.5 + fx.rdir()).normalized() * fx.rng.randf_range(1.0, 2.6) * k
		var c: Color = BONE if j % 2 == 0 else HORN
		fx.spr(p, T + j * 0.03, fx.rng.randf_range(0.9, 1.4), c, 0.45, 0.25 * k, 0.9 * k, 20, v, 0.7)


# The acid pool: soft bile glow lying on the plate and small bubbles popping in it for a while, with thin fumes. Sprites
# only; the shared acid pit mark stays on the hull after it.
static func _pool(fx, p: Vector3, n: Vector3, t1: Vector3, t2: Vector3, T: float, col: Color, k: float, size: float, bubbles: int) -> void:
	fx.spr(p + n * 0.12 * k, T, 2.2, ACID, 0.35, size * 0.7 * k, size * 1.1 * k, 18)
	for j in bubbles:
		var off: Vector3 = (t1 * fx.rng.randf_range(-1.0, 1.0) + t2 * fx.rng.randf_range(-1.0, 1.0)) * size * 0.6 * k
		var at: float = T + fx.rng.randf_range(0.1, 2.6)
		fx.spr(p + off + n * 0.15 * k, at, 0.35, ACID.lerp(col, 0.4), 0.8, 0.08 * k, 0.28 * k, 15, n * 0.6 * k, 0.5)
	for j in 3:
		fx.spr(p + n * 0.5 * k, T + 0.3 + j * 0.7, 2.0, Color(0.42, 0.42, 0.24), 0.5, 0.6 * k, 2.2 * k, 20, n * 1.2 * k, 0.4)


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
		if now >= float(p["end"]):
			n3.queue_free()
			continue
		keep.append(p)
		var t1: float = p["t1"]
		var d: Vector3 = p["dir"]
		var z := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD).normalized()
		var along := Basis(d, z.cross(d).normalized(), z)
		var s: float = float(p["k"]) * SCALE * fx.unit
		var pos: Vector3
		var roll: float
		if now < t1:
			# point first, a slow roll (it flies straight: the tail never tumbles)
			var u := clampf((now - float(p["t0"])) / maxf(t1 - float(p["t0"]), 0.001), 0.0, 1.0)
			pos = (p["a"] as Vector3).lerp((p["b"] as Vector3) - d * TIP * s, u)
			roll = (now - float(p["t0"])) * 6.0 + float(p["seed"])
		elif bool(p["miss"]):
			# flies on past and fades
			pos = (p["b"] as Vector3) - d * TIP * s + d * float(p["spd"]) * (now - t1)   # on from where the flight ended
			roll = (now - float(p["t0"])) * 6.0 + float(p["seed"])
			s *= 1.0 - smoothstep(0.0, 0.6, now - t1)
		elif not bool(p["stuck"]):
			n3.visible = false
			continue
		else:
			# stuck: the point sunk into the plate, the body at the angle it struck, a small shiver as it bites. It rides the
			# ship it is stuck in (its pose kept in the ship's frame, Artoo on PR 1904) and goes when that ship dies or leaves.
			var ship = p["ship"]
			if ship != null and (not is_instance_valid(ship) or bool(ship.dead) or bool(ship.gone)):
				n3.visible = false
				p["end"] = now
				continue
			var age := now - t1
			roll = (t1 - float(p["t0"])) * 6.0 + float(p["seed"])
			if not p.has("local"):
				var at := (p["b"] as Vector3) - d * (TIP - BITE) * s
				var w := Transform3D((along * Basis(Vector3.RIGHT, roll)).scaled(Vector3.ONE * s), at)
				p["local"] = (ship.xf().affine_inverse() * w) if ship != null else w
			var wx: Transform3D = (ship.xf() * (p["local"] as Transform3D)) if ship != null else (p["local"] as Transform3D)
			# the slam: the point drives the last of the way in at once, then the shaft quivers (a hard, decaying wobble
			# about the buried point), so the strike reads as a blow, not a push
			var fwd: Vector3 = wx.basis.x.normalized()
			wx.origin -= fwd * BITE * s * (1.0 - smoothstep(0.0, SLAM, age))
			var q := 0.16 * sin(age * 62.0) * exp(-age * 7.0)
			var tip_at: Vector3 = wx.origin + fwd * TIP * s
			var side: Vector3 = wx.basis.z.normalized()
			wx.basis = Basis(side, q) * wx.basis
			wx.origin = tip_at - (Basis(side, q) * fwd) * TIP * s
			_crumble(n3, clampf((age - STICK) / CRUMBLE, 0.0, 1.0))
			n3.global_transform = wx
			n3.visible = true
			continue
		n3.global_transform = Transform3D((along * Basis(Vector3.RIGHT, roll)).scaled(Vector3.ONE * s), pos)
		n3.visible = true
	fx.dstate["thorn_proj"] = keep


# The built pieces break apart: each drifts off its own way, turns and shrinks to dust.
static func _crumble(n3: Node3D, c: float) -> void:
	var kit := n3.get_node_or_null("kit_body") as Node3D
	if kit == null:
		return
	for child in kit.get_children():
		var piece := child as Node3D
		if piece == null or not piece.has_meta("home"):
			continue
		var home: Transform3D = piece.get_meta("home")
		if c <= 0.0:
			piece.transform = home
			continue
		var e := c * c
		var drift: Vector3 = piece.get_meta("drift")
		var spin: Vector3 = piece.get_meta("spin")
		var b := home.basis.rotated(spin, e * 2.2).scaled(Vector3.ONE * maxf(1.0 - c, 0.02))
		piece.transform = Transform3D(b, home.origin + drift * e)
