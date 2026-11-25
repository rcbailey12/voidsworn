extends RefCounted
# Issue 1586 (Neon's Nov 21-22 death and hull FX audit): more death variety without per-ship bakes. A death is now
# faction tell x kill cause x hull tier archetype x what stays after. fx_death.gd keeps the break itself; this file adds the
# one-shot beats on top, all from the shared pools (fx.spr, fx.spark, fx.rib, fx.shd, fx.light), so no
# death adds a node, a material or a per-frame mesh. View only: the rules never see any of it.
#
#   kill cause (on the death frame, fx_death._death_inner and _hulk):
#     flay   gauss or doom: gas jets punch out along the shot line, spall at the entry and the exit, extra shreds at the break
#     ram    the ram's crush: metal sparks at the struck point, the pieces spin hard off centre (fx_death reads death_spin)
#     board  a scuttled hull: it goes dark as a hulk, airlock vents along the mid hull, no reactor blast
#     tidal  the Hollow Sun's pull: a white-gold flare on the sunward edge and spall drawn toward the star
#     dark   a burnout: corridor lights stutter out over about 2 s, one emergency beacon blinks, a slow dead drift
#   faction beat (at the break, big hulls): Sunward ember ticks on the hot seams for 4 to 6 s, Navy blackout on one frame,
#     Hullbreaker tether snap with scrap and late cook-offs, Glasswright fracture web in the tell and light shafts at the
#     split, Eclipse inward snap, Chorus twitches
#   small hulls (frigates, destroyers): one of four seeded archetypes, see ARCH_*
#   strike craft: a 0.35 s smoky corkscrew and two faction flecks
#   afterlife: a big wreck gives 2 or 3 quiet micro pops (ember or vent) over the 10 s after it settles (from issue 1587)
#
# Each beat that fires is noted on the ship (meta "death_beats"; a few short strings a death) for the checks.

const ARCH_TORCH := 0      # about 25%: the drive over-flares for 0.6 s and drives the hull into an arcing spiral
const ARCH_SNAP := 1       # about 30%: a sharp mid-hull flash and 2 or 3 spinning pieces thrown clean apart
const ARCH_ROLL := 2       # about 25%: a hard roll, a bright flank vent jet, a dead tumble, no big fireball
const ARCH_POP := 3        # about 20%: a compact faction pop
const ARCH_NAMES := ["torch", "snap", "roll", "pop"]
const AFTER_FROM := 3.0    # the afterlife's quiet pops: from this many seconds after the break...
const AFTER_TO := 10.0     # ...to this


static func note(s, beat: String) -> void:
	var b: Array = s.get_meta("death_beats", [])
	b.append(beat)
	s.set_meta("death_beats", b)


static func beats(s) -> Array:
	return s.get_meta("death_beats", [])


static func _col(s, key: String, fallback: Color) -> Color:
	return _death().dcol(s, key, fallback)


# fx_death.gd, loaded on use (it preloads this file).
static func _death() -> GDScript:
	return load("res://fx/fx_death.gd")


# The last hull hit (hull space): [point, direction], or the core and the starboard line when there is none.
static func _shot(fx, s) -> Array:
	var last = s.get_meta("last_hit", [])
	if last is Array and last.size() >= 3 and fx.now - float(last[2]) < 2.5:
		return [last[0], (last[1] as Vector3).normalized()]
	return [s.hull.core, Vector3(0, 0, -float(s.hull.stb_z)).normalized()]


# Which archetype a small hull dies with: seeded by its id and the battle's death count, so a replay dies the same way.
static func pick_arch(fx, s) -> int:
	if s is Object and s.has_meta("death_arch_force"):   # the look bench shows each archetype on purpose
		return int(s.get_meta("death_arch_force"))
	var h := posmod(hash(str(s.id)) + int(fx.stats.get("deaths", 0)) * 7919, 100)
	return ARCH_TORCH if h < 25 else (ARCH_SNAP if h < 55 else (ARCH_ROLL if h < 80 else ARCH_POP))


# ---------------------------------------------------------------- the death frame

# Called by fx_death._death_inner on a breaking (not hulk, not Chorus) death, after its timeline is set.
static func on_death(fx, s, cause: String, T: float, cut_at: float) -> void:
	if _death().melting(s):
		note(s, "melt")   # R398: an acid melt keeps its own clean look: no faction tell, no archetype, no smoke or vapour
		return
	match cause:
		"flay": _flay(fx, s, T, cut_at)
		"ram": _ram(fx, s, T)
		"tidal": _tidal(fx, s, T, cut_at)
	if not s.death_big and not s.squadron and s.faction != "chorus":
		var a := pick_arch(fx, s)
		s.set_meta("death_arch", a)
		note(s, "arch_" + ARCH_NAMES[a])
		if a == ARCH_TORCH:
			# the drive flares for 0.6 s (fx_ship.update keeps the flare while death_flare_until runs)
			s._eng_cur = 1.7
			s.set_meta("death_flare_until", T + 0.6)
		elif a == ARCH_ROLL:
			for j in 5:
				fx.later(T + 0.08 + j * 0.11, _roll_vent.bind(fx, s))
	if s.death_big and s.faction == "ithar":
		_web(fx, s, T, cut_at)
	if s.death_big and s.faction == "hegemony":
		_blackout(s, T + maxf(cut_at - 0.05, 0.0))   # all dark a few frames before the pieces part


# A Chorus rupture keeps its own approved look; a ram or the star's pull adds its cue on top (Codex review of PR 1666).
static func cause_cues(fx, s, cause: String, T: float, cut_at: float) -> void:
	if _death().melting(s):
		return
	match cause:
		"ram": _ram(fx, s, T)
		"tidal": _tidal(fx, s, T, cut_at)


# Called by fx_death._hulk once the cold hulk exists (cause dark, hulk or board).
static func on_hulk(fx, s, node: Node3D, cause: String) -> void:
	var ref := weakref(node)
	if cause == "board":
		note(s, "board")
		for j in 4:
			fx.later(fx.now + 0.15 + j * 0.28, _airlock.bind(fx, s, ref, j))
	else:
		note(s, "burnout")
		_corridors(fx, s, ref)
		for j in 5:
			fx.later(fx.now + 0.6 + j * 1.25, _beacon.bind(fx, s, ref))


# gauss or doom: three or four punctures along the shot line, each a fast vapour jet along the shot, with spall at the entry
# and the exit, through the tell
static func _flay(fx, s, T: float, cut_at: float) -> void:
	note(s, "flay")
	var sh := _shot(fx, s)
	var lp: Vector3 = sh[0]
	var ld: Vector3 = sh[1]
	var h = s.hull
	var L: float = h.L
	var exit_hit: Dictionary = h.ray(lp + ld * (L + h.W + 2.0), -ld)
	var lx: Vector3 = exit_hit.get("p", lp + ld * h.W)
	var pts: Array = [lp, lx]
	for u in [0.33, 0.66]:
		var q: Vector3 = lp.lerp(lx, u) + Vector3(L * 0.08 * (u - 0.5), 0.0, 0.0)
		var up: Dictionary = h.ray(q + Vector3.UP * (h.H + L * 0.2), Vector3.DOWN)
		if not up.is_empty():
			pts.append(up["p"])
	var span: float = maxf(cut_at, 0.4)
	var dw: Vector3 = s.dir_world(ld)
	var glow: Color = _col(s, "light", Color(0.9, 0.92, 1.0))
	for i in pts.size():
		var t := T + span * (0.15 + 0.7 * float(i) / float(maxi(pts.size() - 1, 1)))
		fx.later(t, _jet.bind(fx, s, pts[i], dw, glow, i == 0))
	note(s, "flay_jets_%d" % pts.size())


static func _jet(fx, s, lp: Vector3, dw: Vector3, glow: Color, entry: bool) -> void:
	if not is_instance_valid(s.root):
		return
	var p: Vector3 = s.to_world(lp)
	var L: float = s.hull.L
	var vap := glow.lerp(Color.WHITE, 0.6)
	for j in 5:
		_wisp(fx, s, p, fx.now + j * 0.03, 0.55, vap, 0.5, L * 0.006, L * 0.045, fx.rcone(dw, 0.12) * L * (0.9 - j * 0.1), 2.2)
	var away: Vector3 = -dw if entry else dw
	for j in 8:
		fx.spark(p, fx.now + fx.rng.randf() * 0.04, 0.3 + fx.rng.randf() * 0.2, s.faction, 4.0, 0.05, maxf(L * 0.003, 0.03),
			fx.rcone(away, 0.5) * L * fx.rng.randf_range(0.5, 1.0), 1.2, 0.0, 0.0, fx.SparkRole.DEATH)


# A vapour wisp (the smoke pool's kind 7), or on a Glasswright hull, which never smokes (clean collapse, Codex review of
# PR 1666), a soft light glow and a few glass glints along the same line.
static func _wisp(fx, s, p: Vector3, t: float, life: float, col: Color, i: float, s0: float, s1: float, vel: Vector3, drag: float) -> void:
	if s.faction != "ithar":
		fx.spr(p, t, life, col, i, s0, s1, 7, vel, drag)
		return
	fx.spr(p, t, life * 0.6, Color(0.92, 0.96, 1.0), i * 0.8, s0, s1 * 0.5, 18, vel * 0.5, drag)
	for k in 2:
		fx.spark(p, t + k * 0.03, life * 0.5, s.faction, 2.0, 0.03, maxf(s1 * 0.05, 0.02), vel + fx.rdir() * s1, drag, 0.0, 0.0, fx.SparkRole.DEATH)


# R367 and R402 (Fable audit of PRs 1631 and 1666): loose hull debris is the faction's own matter, read from its wound_kind
# (fx/faction_looks.json). Metal hulls throw dark hot metal shards; Glasswrights throw glass shards (shard tint 2) with
# their cold light; the Chorus throws wet bile flecks, never plate; Eclipse throws its own dark machine shards, never
# orange hot. tint is the metal look's shard tint, kept for metal hulls only.
static func debris(fx, s, p: Vector3, t: float, life: float, vel: Vector3, size: float, heat: float, spin := 4.0, drag := 0.3, tint := 0.0) -> void:
	match int(s.fac.get("wound_kind", 0)):
		1:
			fx.spr(p, t, life * 0.5, (s.fac.damage_glow as Color) * 0.6, 0.3, size * 0.6, size * 2.0, 20, vel * 0.6, 1.2)
		2:
			fx.shd(p, t, life, vel, size, heat, spin, drag, 2.0)
		3:
			fx.shd(p, t, life, vel, size, 0.0, spin, drag, 0.0)
		_:
			fx.shd(p, t, life, vel, size, heat, spin, drag, tint)


# a ram kill: the crush at the struck point throws sparks along the plating, and the pieces will spin off centre
static func _ram(fx, s, T: float) -> void:
	note(s, "ram")
	var sh := _shot(fx, s)
	if bool(s.get_meta("death_ram_prow", false)):
		# the rammer dies of its own recoil: the crush is at its prow, never at some earlier hit (Codex review of PR 1666)
		var h = s.hull
		var pr: Dictionary = h.ray(h.c + Vector3(h.L, 0, 0), Vector3(-1, 0, 0))
		sh = [pr.get("p", h.c + Vector3(h.L * 0.5, 0, 0)), Vector3(-1, 0, 0)]
		note(s, "ram_prow")
	var p: Vector3 = s.to_world(sh[0])
	var dw: Vector3 = s.dir_world(sh[1])
	var L: float = s.hull.L
	s.set_meta("death_spin", 1.0 if posmod(hash(str(s.id)), 2) == 0 else -1.0)
	var wet: bool = int(s.fac.get("wound_kind", 0)) == 1
	var col: Color = s.fac.damage_glow if wet else fx.spark_colour(s.faction, fx.SparkRole.DEATH)
	for j in 26:
		var d: Vector3 = fx.rdir()
		d = (d - dw * d.dot(dw) * 0.8).normalized()
		if wet:   # the Chorus tears, it does not spark: wet flecks along the hide
			if j % 2 == 0:
				fx.spr(p, T + fx.rng.randf() * 0.12, 0.5, col * 0.7, 0.3, L * 0.004, L * 0.018, 20, d * L * fx.rng.randf_range(0.2, 0.5), 1.2)
			continue
		fx.spark(p, T + fx.rng.randf() * 0.12, 0.25 + fx.rng.randf() * 0.3, s.faction, 5.0, 0.06, maxf(L * 0.003, 0.03),
			d * L * fx.rng.randf_range(0.4, 1.0), 1.5, 0.0, 0.0, fx.SparkRole.DEATH)
	for j in 3:
		debris(fx, s, p, T + j * 0.04, 1.8, fx.rcone(-dw, 0.7) * L * 0.12, L * 0.006, 0.6)
	fx.light(p, T, 0.25, 2.5, col, 1)


# the Hollow Sun pulls: a white-gold flare on the hull's sunward edge and spall streaming toward the star
static func _tidal(fx, s, T: float, cut_at: float) -> void:
	if fx.well == Vector3.INF:
		return
	note(s, "tidal")
	var h = s.hull
	var dl: Vector3 = (s.root.global_transform.affine_inverse().basis * (fx.well - s.to_world(h.c))).normalized()
	var edge: Dictionary = h.ray(h.c + dl * (h.L + 2.0), -dl)
	var p: Vector3 = s.to_world(edge.get("p", h.c + dl * h.L * 0.5))
	var to_sun: Vector3 = (fx.well - p).normalized()
	var gold := Color(1.0, 0.86, 0.55)
	var L: float = h.L
	fx.light(p, T + 0.1, maxf(cut_at, 0.6), 3.0, gold, 1)
	fx.spr(p, T + 0.1, maxf(cut_at, 0.6), gold, 1.2, L * 0.05, L * 0.12, 18)
	for j in 14:
		fx.spark(p, T + 0.1 + j * maxf(cut_at, 0.6) / 14.0, 0.6, s.faction, 3.0, 0.08, maxf(L * 0.003, 0.03),
			fx.rcone(to_sun, 0.35) * L * 0.6, 0.2, 0.0, 0.0, fx.SparkRole.DEATH)


# A small hull rolling over vents hard from one flank.
static func _roll_vent(fx, s) -> void:
	if not is_instance_valid(s.root):
		return
	var pose: Transform3D = s.get_meta("death_motion", Transform3D.IDENTITY)
	var xf: Transform3D = s.root.global_transform * pose
	var p: Vector3 = xf * (s.hull.c + Vector3(0, 0, s.hull.W * 0.5))
	var n: Vector3 = (xf.basis * Vector3(0, 0, 1)).normalized()
	var glow: Color = s.fac.damage_glow
	_wisp(fx, s, p, fx.now, 0.45, glow.lerp(Color.WHITE, 0.7), 0.6, s.hull.L * 0.02, s.hull.L * 0.12, n * s.hull.L * 0.9, 2.0)


# The Glasswrights' white fracture web races across the panels through the tell (no fire, no smoke).
static func _web(fx, s, T: float, cut_at: float) -> void:
	note(s, "web")
	var n := 10 if s.death_tier == "capital" else 7
	var L: float = s.hull.L
	for j in n:
		var at := T + maxf(cut_at, 0.5) * (0.1 + 0.8 * float(j) / float(n))
		fx.later(at, func l_web() -> void:
			if not is_instance_valid(s.root): return
			var c: Dictionary = s.hull.random_sample(-1, 2.0)
			if c.is_empty(): return
			var p: Vector3 = s.to_world(c["p"])
			var nw: Vector3 = s.dir_world(c["n"])
			var t: Vector3 = fx.rdir()
			t = (t - nw * t.dot(nw)).normalized()
			fx.rib(p + nw * L * 0.004, t, L * fx.rng.randf_range(0.08, 0.18), fx.now, 0.5, Color(0.95, 0.97, 1.0), 1.4, L * 0.0015 / maxf(fx.unit, 1e-4), L * 0.0006 / maxf(fx.unit, 1e-4), 6))


# A scuttled hull vents through its airlocks along the mid hull, one after another.
static func _airlock(fx, s, ref: WeakRef, j: int) -> void:
	var node := ref.get_ref() as Node3D
	if not is_instance_valid(node):
		return
	var h = s.hull
	var x: float = h.box.position.x + h.L * (0.35 + 0.1 * j)
	var side := 1.0 if j % 2 == 0 else -1.0
	var hit: Dictionary = h.ray(Vector3(x, h.c.y, h.c.z + side * (h.W + 2.0)), Vector3(0, 0, -side))
	if hit.is_empty():
		return
	var p: Vector3 = node.global_transform * (hit["p"] as Vector3)
	var n: Vector3 = (node.global_transform.basis * (hit["n"] as Vector3)).normalized()
	for k in 4:
		_wisp(fx, s, p, fx.now + k * 0.05, 1.1, Color(0.82, 0.86, 0.9), 0.45, h.L * 0.006, h.L * 0.05, n * h.L * 0.35, 1.8)
	note(s, "airlock")


# A burnt-out hull's corridor lights stutter out over about 2 s: a few warm points on its plating flicker, then die.
static func _corridors(fx, s, ref: WeakRef) -> void:
	var node := ref.get_ref() as Node3D
	if not is_instance_valid(node):
		return
	var h = s.hull
	var col: Color = _col(s, "light", Color(1.0, 0.85, 0.6))
	for i in 6:
		var c: Dictionary = h.random_sample(-1, 1.0)
		if c.is_empty():
			continue
		var lp: Vector3 = (c["p"] as Vector3) + (c["n"] as Vector3) * h.L * 0.004
		var last := 0.6 + 1.4 * float(i) / 5.0
		if fx.reduce_flashing:
			# Reduced Flashing (Neon on PR 1666): no 5 to 11 Hz stutter; each light holds, then fades once over 1.5 s
			fx.spr(node.global_transform * lp, fx.now, last + 1.5, col, 0.7, h.L * 0.006, h.L * 0.006, 18)
			continue
		var t := 0.0
		while t < last:
			var on: float = 0.05 + fx.rng.randf() * 0.12
			fx.later(fx.now + t, func l_corridor() -> void:
				var nd := ref.get_ref() as Node3D
				if is_instance_valid(nd):
					fx.spr(nd.global_transform * lp, fx.now, on, col, 0.9, h.L * 0.006, h.L * 0.006, 18))
			t += on + 0.04 + fx.rng.randf() * 0.18
	note(s, "corridors")


static func _beacon(fx, s, ref: WeakRef) -> void:
	var node := ref.get_ref() as Node3D
	if not is_instance_valid(node):
		return
	var h = s.hull
	var top: Dictionary = h.ray(h.c + Vector3.UP * (h.H + h.L * 0.2), Vector3.DOWN)
	var p: Vector3 = node.global_transform * (top.get("p", h.c) as Vector3)
	if fx.reduce_flashing:
		fx.spr(p, fx.now, 0.9, Color(1.0, 0.25, 0.12), 0.6, h.L * 0.008, h.L * 0.010, 18)   # a slow soft pulse
	else:
		fx.spr(p, fx.now, 0.22, Color(1.0, 0.25, 0.12), 1.4, h.L * 0.008, h.L * 0.012, 18)
	note(s, "beacon")


# A strike craft's loss: a 0.35 s smoky corkscrew from where it was hit and two small faction flecks.
static func corkscrew(fx, s, p: Vector3, frame: Transform3D) -> void:
	if _death().melting(s):
		return   # R398: no smoke on an acid melt
	note(s, "corkscrew")
	var L: float = maxf(s.hull.L, 0.5)
	var fwd: Vector3 = frame.basis.x.normalized()
	var side: Vector3 = frame.basis.z.normalized()
	var up: Vector3 = frame.basis.y.normalized()
	for j in 6:
		var u := float(j) / 5.0
		var a := u * TAU * 1.5
		var q: Vector3 = p + fwd * L * 0.6 * u - up * L * 0.5 * u * u + (side * cos(a) + up * sin(a)) * L * 0.12
		if s.faction != "ithar":   # a Glasswright craft never smokes: the flecks alone
			fx.spr(q, fx.now + u * 0.35, 0.6, Color(0.12, 0.11, 0.1), 0.4, L * 0.04, L * 0.14, 3, Vector3.ZERO, 0.5)
	for j in 2:
		debris(fx, s, p, fx.now, 1.2, (fwd + fx.rdir() * 0.6).normalized() * L * 0.8, L * 0.04, 0.4, 6.0, 0.3, 0.6)
		fx.spark(p, fx.now, 0.35, s.faction, 2.0, 0.04, L * 0.02, fx.rdir() * L * 0.7, 1.0, 0.0, 0.0, fx.SparkRole.DEATH)


# ---------------------------------------------------------------- the break

# Called by fx_death._break_up_inner once the wreck exists. center: where the hull broke (world).
static func on_break(fx, s, wreck: Dictionary, cause: String, center: Vector3, xf: Transform3D) -> void:
	if _death().melting(s):
		return   # R398, as on_death
	var nodes: Array = wreck.get("nodes", [])
	var L: float = s.hull.L
	var T: float = fx.now
	if cause == "flay":
		var sh := _shot(fx, s)
		spawn_shreds(fx, s, center, (xf.basis * (sh[1] as Vector3)).normalized() * L * 0.35, 5 if s.death_big else 2)
	if s.death_big:
		match s.faction:
			"voidsworn": _embers(fx, s, nodes, T)
			"corsair": _tether(fx, s, wreck, nodes, T)
			"ithar": _shafts(fx, s, center, T)
			"deathless": _implode(fx, s, center, T)
			"chorus": _twitch(fx, s, nodes, T)
		if s.faction != "chorus":
			_afterlife(fx, s, nodes, T)
		return
	match int(s.get_meta("death_arch", -1)):
		ARCH_SNAP:
			spawn_shreds(fx, s, center, Vector3.ZERO, 3)
			fx.light(center, T, 0.12, 3.5, _col(s, "light", Color(1.0, 0.9, 0.7)), 1)
		ARCH_POP:
			_mini_pop(fx, s, center, T)


# ARCH_ROLL's end (fx_death._break_up_inner skips the core flash, the faction pop and the smoke body): a small spark
# burst and a short light, the hull's own spark colour
static func roll_end(fx, s, p: Vector3, inherited: Vector3) -> void:
	var L: float = s.hull.L
	var col: Color = _col(s, "spark", Color(1.0, 0.75, 0.4))
	for k in 10:
		fx.spark(p, fx.now, 0.4, s.faction, 3.0, 0.04, maxf(L * 0.004, 0.03), inherited * 0.5 + fx.rdir() * L * 0.6, 1.2, 0.0, 0.0, fx.SparkRole.DEATH)
	# a short counted flash (the staging rule's core beat, small), refused in calm mode like every other
	if fx.flash_at(p, fx.now, L * 0.45, 40.0, 0.10):
		fx.light(p, fx.now, 0.10, 2.5, col, 1)
		fx.spr(p, fx.now, 0.12, col.lerp(Color.WHITE, 0.5), 2.0, L * 0.05, L * 0.12, fx.HOT_FLECK_SPRITE)
	note(s, "roll_end")


# Extra cosmetic shreds from the shared shard pool (fx.shd): no physics body, no new node, the same at every quality
# (Codex review of PR 1666: physical debris could allocate bodies on the break frame and showed nothing on Low).
static func spawn_shreds(fx, s, p: Vector3, vel: Vector3, n: int) -> void:
	var L: float = s.hull.L
	var base: Vector3 = vel + s.get_meta("death_velocity", Vector3.ZERO)
	for j in n:
		debris(fx, s, p, fx.now, 2.4, base + fx.rdir() * L * fx.rng.randf_range(0.25, 0.6), L * fx.rng.randf_range(0.015, 0.03), 0.5, 3.0, 0.25, 0.5)
	note(s, "shreds_%d" % n)


# Sunward: the hot iron seams tick and spit embers for 4 to 6 s after the split.
static func _embers(fx, s, nodes: Array, T: float) -> void:
	note(s, "embers")
	var n := 6
	for j in n:
		if nodes.is_empty():
			break
		var ref := weakref(nodes[j % nodes.size()])
		fx.later(T + 0.6 + fx.rng.randf_range(0.0, 5.0), func l_ember() -> void:
			var nd := ref.get_ref() as Node3D
			if not is_instance_valid(nd): return
			var p: Vector3 = nd.to_global(nd.get_meta("tear_site", Vector3.ZERO))
			for k in 3:
				fx.spark(p, fx.now + k * 0.03, 0.4, s.faction, 3.0, 0.03, maxf(s.hull.L * 0.002, 0.02), fx.rdir() * s.hull.L * 0.12, 1.5, 0.0, 0.0, fx.SparkRole.DEATH))


# Navy: every window and light stays on through the tell, then all die on one frame as the hull breaks, like a tripped breaker
# (fx_death._update_dying reads death_blackout_at), a few frames before the pieces part.
static func _blackout(s, at: float) -> void:
	note(s, "blackout")
	s.set_meta("death_blackout_at", at)


# Hullbreakers: the two biggest pieces tug on two glowing cables for 0.45 s, the cables snap with a jolt of sparks, scrap
# canisters scatter, and two uneven cook-offs go off later.
static func _tether(fx, s, wreck: Dictionary, nodes: Array, T: float) -> void:
	note(s, "tether")
	if nodes.size() >= 2:
		var ra := weakref(nodes[0])
		var rb := weakref(nodes[1])
		var col: Color = _col(s, "rim", Color(1.0, 0.3, 0.08))
		for j in 9:
			fx.later(T + j * 0.05, _cables.bind(fx, s, wreck, ra, rb, col, j == 8))
	spawn_shreds(fx, s, s.to_world(s.hull.c), Vector3.ZERO, 3)
	for t in [2.4 + fx.rng.randf() * 0.6, 4.0 + fx.rng.randf() * 1.2]:
		fx.later(T + t, func l_cookoff() -> void:
			if nodes.is_empty(): return
			var nd = nodes[posmod(int(t * 10.0), nodes.size())]
			if not is_instance_valid(nd): return
			var p: Vector3 = (nd as Node3D).global_position
			fx.spr(p, fx.now, 0.35, _col(s, "fire_mid", Color(0.95, 0.2, 0.06)), 1.4, s.hull.L * 0.02, s.hull.L * 0.07, 25)
			fx.spr(p, fx.now + 0.12, 1.4, Color(0.08, 0.07, 0.06), 0.4, s.hull.L * 0.03, s.hull.L * 0.12, 3, Vector3.UP * s.hull.L * 0.05)
			note(s, "cookoff"))


static func _cables(fx, s, wreck: Dictionary, ra: WeakRef, rb: WeakRef, col: Color, snap: bool) -> void:
	var a := ra.get_ref() as Node3D
	var b := rb.get_ref() as Node3D
	if not is_instance_valid(a) or not is_instance_valid(b):
		return
	# Neon on PR 1666: the cables hold the two pieces back (their parting speed damped to 35%), and the snap lets them go
	_hold(wreck, a, not snap)
	_hold(wreck, b, not snap)
	var L: float = s.hull.L
	for side in [-1.0, 1.0]:
		var off := Vector3(0, L * 0.02, side * s.hull.W * 0.3)
		var pa: Vector3 = a.to_global(a.get_meta("tear_site", Vector3.ZERO) + off)
		var pb: Vector3 = b.to_global(b.get_meta("tear_site", Vector3.ZERO) + off)
		var d: Vector3 = pb - pa
		if d.length() < 0.01:
			continue
		if snap:
			var mid: Vector3 = pa + d * 0.5
			for k in 8:
				fx.spark(mid, fx.now, 0.3, s.faction, 4.0, 0.05, maxf(L * 0.003, 0.03), fx.rdir() * L * 0.5, 1.5, 0.0, 0.0, fx.SparkRole.DEATH)
		else:
			fx.rib(pa, d.normalized(), d.length(), fx.now, 0.07, col, 1.2, L * 0.002 / maxf(fx.unit, 1e-4), L * 0.002 / maxf(fx.unit, 1e-4), 0)
	if snap:
		note(s, "tether_snap")


# A tethered piece's parting speed: held at 35% of what it had (kept in meta "tether_v"), then given back on the snap.
# Works on a physics piece (RigidBody3D) and on a kinematic one (its wreck "fires" entry).
static func _hold(wreck: Dictionary, nd: Node3D, held: bool) -> void:
	var rb := nd as RigidBody3D
	var entry: Dictionary = {}
	for f in wreck.get("fires", []):
		if f.get("node") == nd and f.has("vel"):
			entry = f
			break
	var v: Vector3 = rb.linear_velocity if rb != null else (entry.get("vel", Vector3.ZERO) as Vector3)
	if not nd.has_meta("tether_v"):
		if not held: return
		nd.set_meta("tether_v", v)
	var free_v: Vector3 = nd.get_meta("tether_v")
	var out: Vector3 = free_v * 0.35 if held else free_v
	if not held: nd.remove_meta("tether_v")
	if rb != null: rb.linear_velocity = out
	elif not entry.is_empty(): entry["vel"] = out


# Glasswrights: soft prismatic shafts of light out of the split, no fire and no smoke.
static func _shafts(fx, s, center: Vector3, T: float) -> void:
	note(s, "shafts")
	var L: float = s.hull.L
	var cols := [Color(1.0, 0.75, 0.8), Color(0.75, 1.0, 0.85), Color(0.75, 0.82, 1.0), Color(1.0, 0.95, 0.75)]
	for j in 4:
		var d: Vector3 = (fx.rdir() + Vector3.UP * 0.8).normalized()
		fx.rib(center, d, L * 0.5, T + j * 0.05, 0.9, cols[j], 0.6, L * 0.02 / maxf(fx.unit, 1e-4), L * 0.002 / maxf(fx.unit, 1e-4), 0)


# Eclipse: the violet core gutters and snaps inward, a tight dark implosion (the scene dim stays in fx_death, Eclipse only).
static func _implode(fx, s, center: Vector3, T: float) -> void:
	note(s, "implode")
	var L: float = s.hull.L
	var vi := Color(0.55, 0.3, 1.0)
	var at := T + 0.25
	for j in 10:
		var d: Vector3 = fx.rdir()
		d.y *= 0.4
		d = d.normalized()
		var p0: Vector3 = center + d * L * 0.25
		fx.spr(p0, at, 0.28, vi, 1.1, L * 0.02, L * 0.004, 18, -d * L * 0.9, 0.0)
	fx.spr(center, at + 0.25, 0.4, Color(0.02, 0.0, 0.04), 0.9, L * 0.12, L * 0.02, 3)


# Chorus: two or three slow chitin twitches after the break (a piece jerks a little about a random axis), with a wet puff.
static func _twitch(fx, s, nodes: Array, T: float) -> void:
	note(s, "twitch")
	var n := 2 + posmod(hash(str(s.id)), 2)
	for j in n:
		if nodes.is_empty():
			break
		var ref := weakref(nodes[j % nodes.size()])
		var axis: Vector3 = fx.rdir()
		fx.later(T + 1.2 + j * 1.3 + fx.rng.randf() * 0.4, func l_twitch() -> void:
			var nd := ref.get_ref() as Node3D
			if not is_instance_valid(nd): return
			# eased over about 0.25 s (Neon on PR 1666): a slow organic spasm, never a one-frame snap
			for k in 8:
				var w := smoothstep(0.0, 1.0, float(k + 1) / 8.0) - smoothstep(0.0, 1.0, float(k) / 8.0)
				fx.later(fx.now + k * 0.032, func l_twitch_step() -> void:
					var nd2 := ref.get_ref() as Node3D
					if is_instance_valid(nd2):
						nd2.rotate(axis, 0.07 * w)
						note(s, "twitch_step"))
			fx.spr(nd.global_position, fx.now, 1.6, s.fac.damage_glow * Color(0.4, 0.5, 0.3), 0.3, s.hull.L * 0.02, s.hull.L * 0.1, 20, Vector3.UP * s.hull.L * 0.04, 0.6))


# The cooling battlefield (issue 1587 section 4): 2 or 3 quiet pops on the wreck between AFTER_FROM and AFTER_TO seconds
# after the break: a tiny ember burst or a faint short vent wisp. Pool sprites only.
static func _afterlife(fx, s, nodes: Array, T: float) -> void:
	var n := 2 + posmod(hash(str(s.id)) >> 3, 2)
	var glow: Color = s.fac.damage_glow
	var ember: bool = s.faction not in ["ithar", "chorus"]
	for j in n:
		if nodes.is_empty():
			break
		var ref := weakref(nodes[(j * 3) % nodes.size()])
		var at := T + lerpf(AFTER_FROM, AFTER_TO, (float(j) + fx.rng.randf() * 0.8) / float(n))
		fx.later(at, func l_after() -> void:
			var nd := ref.get_ref() as Node3D
			if not is_instance_valid(nd): return
			var p: Vector3 = nd.to_global(nd.get_meta("tear_site", Vector3.ZERO))
			var L: float = s.hull.L
			if ember and j % 2 == 0:
				for k in 3:
					fx.spark(p, fx.now + k * 0.04, 0.35, s.faction, 2.0, 0.02, maxf(L * 0.002, 0.02), fx.rdir() * L * 0.06, 1.5, 0.0, 0.0, fx.SparkRole.DEATH)
			else:
				_wisp(fx, s, p, fx.now, 0.9, glow.lerp(Color.WHITE, 0.6), 0.22, L * 0.004, L * 0.025, Vector3.UP * L * 0.04, 1.0)
			note(s, "after"))
	note(s, "after_%d" % n)


# A small hull's compact faction pop (ARCH_POP).
static func _mini_pop(fx, s, p: Vector3, T: float) -> void:
	var L: float = s.hull.L
	note(s, "mini_" + str(s.faction))
	match s.faction:
		"hegemony":
			for j in 2:
				fx.rib(p, fx.rdir(), L * 0.4, T + j * 0.06, 0.18, Color(0.62, 0.8, 1.0), 1.4, L * 0.004 / maxf(fx.unit, 1e-4), L * 0.0015 / maxf(fx.unit, 1e-4), 6)
		"ithar":
			for j in 10:
				fx.spark(p, T, 0.5, s.faction, 4.0, 0.04, maxf(L * 0.004, 0.03), fx.rdir() * L * 0.8, 1.0, 0.0, 0.0, fx.SparkRole.DEATH)
		"chorus":
			fx.spr(p, T, 0.9, s.fac.damage_glow * 0.6, 0.6, L * 0.08, L * 0.3, 20, Vector3.ZERO, 0.5)
		"voidsworn":
			fx.spark(p, T, 0.4, s.faction, 1.3, 0.055, L * 0.006, Vector3.UP * L * 0.15,
				1.0, 0.0, 0.0, fx.SparkRole.DEATH)
		"corsair":
			spawn_shreds(fx, s, p, Vector3.ZERO, 1)
		"deathless":
			_implode(fx, s, p, T - 0.25)
