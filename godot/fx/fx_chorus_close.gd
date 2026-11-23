extends RefCounted
# Issue 1877 (R437, Ryan Nov 23 2026: "scrap tendrils, that doesn't make sense as a space weapon"): the four replacement
# looks Muse designed for the Chorus close-in weapon (contrib/muse/reviews/chorus_tendril_replacement.md), built so Ryan can
# pick one from look-bench clips. Same rules weapon (W.tendril: range 1, 2 shots, acid); only the picture changes.
#
#   sac    Acid sacs: a sloshing bile sac in a thin bone shell, squeezed out of a flank pore, tumbling slowly; the shell
#          cracks on the plating and the acid splashes wide and pools.
#   bolt   Bone bolts: one heavy bone bolt with an acid core, snapped out straight and fast, trailing bile drops; the head
#          shatters and acid sheets down the hull.
#   torp   Gut torps: a finned flesh sac that swims the gap with rippling fins; it slaps on, splits, pours acid, and the
#          husk flakes away.
#   mite   Burst mites: a hand-sized chitin mite on blurred wings; it hits, curls and pops in a flat fan of acid.
#
# Off by default: the game still draws the old tendril until Ryan picks. A test run picks an option with the effects
# system's `chorus_close` field (the look bench sets it per row) or VS_CHORUS_CLOSE. The hull mark, the acid spot (R398)
# and the shared bio splat still come from fx_weapons._impact, so every option keeps the shared hit language (R362); this
# file adds only the body in flight and the matter that body leaves on the hit.
#
# Palette (factions.md, The Chorus): bone to horn chitin, muddy olive membrane, bile yellow-green light from inside only
# (the faction's own weapon colour from faction_looks.json); no eyes, no metal, no flat lime surfaces.

const OPTIONS := ["sac", "bolt", "torp", "mite"]
const BONE := Color(0.66, 0.55, 0.38)       # ochre bone / horn
const BONE_DARK := Color(0.40, 0.31, 0.20)
const MEMBRANE := Color(0.33, 0.33, 0.17)   # muddy olive membrane
const HIDE := Color(0.27, 0.21, 0.14)       # olive-brown hide
const VEIN := Color(0.36, 0.10, 0.08)       # dark red vein
# flight speed (world units a second) and the launch wind-up (seconds), per option
const SPEED := {"sac": 13.0, "bolt": 52.0, "torp": 9.5, "mite": 26.0}
const WIND := {"sac": 0.42, "bolt": 0.30, "torp": 0.55, "mite": 0.12}
const GAP := {"sac": 0.55, "bolt": 0.35, "torp": 0.7, "mite": 0.22}


static func option(fx) -> String:
	var o := ""
	if "chorus_close" in fx:
		o = str(fx.get("chorus_close"))
	if o == "":
		o = OS.get_environment("VS_CHORUS_CLOSE")
	return o if o in OPTIONS else ""


static func _mat(fx, key: String, make: Callable) -> Material:
	if not fx.dstate.has("cc_" + key):
		var m: Material = make.call()
		if m is BaseMaterial3D:
			(m as BaseMaterial3D).disable_fog = true   # like every effect shader (issue 1211): a nebula never dulls it
		fx.dstate["cc_" + key] = m
	return fx.dstate["cc_" + key]


static func _std(albedo: Color, rough: float, emit := Color.BLACK, emit_k := 0.0, alpha := 1.0, rim := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(albedo.r, albedo.g, albedo.b, alpha)
	m.roughness = rough
	m.metallic = 0.0
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit_k > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = emit_k
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.6
	return m


static func _mi(parent: Node3D, mesh: Mesh, mat: Material, pos := Vector3.ZERO, scl := Vector3.ONE, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


static func _sphere(r: float, seg := 16, rings := 10) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r; s.height = r * 2.0; s.radial_segments = seg; s.rings = rings
	return s


# A bone spike along +X: a long cone with a blunt collar, lumpy enough not to read as a machined dart.
static func _spike(length: float, r: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0; c.bottom_radius = r; c.height = length; c.radial_segments = 7; c.rings = 3
	return c


static func _body(fx, opt: String, col: Color, k: float) -> Node3D:
	var node := Node3D.new()
	node.name = "fx_chorus_" + opt
	var glow := _mat(fx, "glow_" + str(col.to_html()), func() -> Material: return _std(col * 0.5, 0.5, col, 2.6))
	var bone := _mat(fx, "bone", func() -> Material: return _std(BONE, 0.62))
	var bone_d := _mat(fx, "bone_d", func() -> Material: return _std(BONE_DARK, 0.7))
	var memb := _mat(fx, "memb", func() -> Material: return _std(MEMBRANE, 0.55, col, 0.35, 0.62, 0.5))
	var hide := _mat(fx, "hide", func() -> Material: return _std(HIDE, 0.75))
	var vein := _mat(fx, "vein", func() -> Material: return _std(VEIN, 0.6))
	match opt:
		"sac":
			# the sloshing core, its translucent sac, and three cracked shell plates of thin bone over it
			_mi(node, _sphere(0.42), glow, Vector3(0.05, -0.04, 0.0))
			_mi(node, _sphere(0.62, 18, 12), memb, Vector3.ZERO, Vector3(1.12, 0.92, 0.96))
			for j in 3:
				var a: float = TAU * float(j) / 3.0 + 0.4
				var d := Vector3(cos(a) * 0.3, sin(a) * 0.55, cos(a + 1.3) * 0.45).normalized()
				_mi(node, _sphere(0.42, 10, 6), bone, d * 0.42, Vector3(1.0, 0.35, 0.85), Vector3(a, a * 0.7, 0.3))
			_mi(node, _sphere(0.3, 8, 5), vein, Vector3(-0.42, 0.18, 0.12), Vector3(0.9, 0.3, 0.5))
		"bolt":
			# head forward (+X): a bone spike, a lumpy collar, an acid-lit core seam behind the collar, a ridged tail
			var sp := _mi(node, _spike(2.2, 0.32), bone, Vector3(0.55, 0, 0), Vector3.ONE, Vector3(0, 0, -PI / 2.0))
			sp.name = "head"
			_mi(node, _sphere(0.36, 10, 6), bone_d, Vector3(-0.45, 0, 0), Vector3(1.3, 0.95, 1.05))
			_mi(node, _sphere(0.2, 8, 5), glow, Vector3(-0.78, 0, 0), Vector3(1.6, 0.8, 0.8))
			_mi(node, _spike(1.1, 0.24), bone_d, Vector3(-1.25, 0, 0), Vector3.ONE, Vector3(0, 0, PI / 2.0))
		"torp":
			# a long flesh sac (nose +X), lit from inside, two membrane fins on its flanks and a tail fin; the fins flap
			_mi(node, _sphere(0.48), glow, Vector3(0.1, 0, 0), Vector3(1.6, 0.8, 0.8))
			_mi(node, _sphere(0.62, 18, 12), memb, Vector3.ZERO, Vector3(1.9, 0.82, 0.9))
			_mi(node, _sphere(0.4, 10, 6), hide, Vector3(0.95, 0.05, 0), Vector3(0.8, 0.9, 1.0))
			for s in [-1.0, 1.0]:
				var fin := Node3D.new()
				fin.name = "fin_l" if s < 0.0 else "fin_r"
				fin.position = Vector3(0.0, 0.0, s * 0.5)
				node.add_child(fin)
				_mi(fin, _sphere(0.5, 10, 4), memb, Vector3(-0.15, 0, s * 0.45), Vector3(1.2, 0.08, 0.9))
				_mi(fin, _sphere(0.08, 6, 4), bone, Vector3(-0.15, 0.03, s * 0.45), Vector3(9.0, 0.6, 0.8))
			var tail := Node3D.new()
			tail.name = "tail"
			tail.position = Vector3(-1.15, 0, 0)
			node.add_child(tail)
			_mi(tail, _sphere(0.45, 10, 4), memb, Vector3(-0.3, 0, 0), Vector3(1.0, 1.2, 0.08))
		"mite":
			# a small horn-plated body, abdomen sac glinting, legs tucked; two wing blurs
			var wing_m := _mat(fx, "wing", func() -> Material: return _std(Color(0.62, 0.58, 0.42), 0.4, Color.BLACK, 0.0, 0.32, 0.8))
			_mi(node, _sphere(0.34, 12, 8), bone_d, Vector3(0.25, 0, 0), Vector3(1.3, 0.8, 0.95))
			_mi(node, _sphere(0.3, 12, 8), bone, Vector3(0.28, 0.12, 0), Vector3(1.2, 0.45, 0.85))
			_mi(node, _sphere(0.32, 12, 8), glow, Vector3(-0.32, -0.02, 0), Vector3(1.2, 0.9, 0.9))
			_mi(node, _sphere(0.34, 12, 8), memb, Vector3(-0.32, 0, 0), Vector3(1.3, 1.0, 1.0))
			for s in [-1.0, 1.0]:
				_mi(node, _spike(0.55, 0.05), bone_d, Vector3(0.05, -0.18, s * 0.18), Vector3.ONE, Vector3(0, s * 0.5, PI / 2.0 + 0.4))
				var wing := _mi(node, _sphere(0.55, 10, 4), wing_m, Vector3(0.0, 0.22, s * 0.55), Vector3(0.7, 0.04, 1.0))
				wing.name = "wing_l" if s < 0.0 else "wing_r"
	node.scale = Vector3.ONE * k * fx.unit
	node.visible = false
	fx.add_child(node)
	return node


# One shot of the chosen option. Returns [fire time, impact time, end time] like fx_weapons._shot's arms.
static func shot(fx, opt: String, from: Vector3, mn: Vector3, to: Vector3, T0: float, beat: float, col: Color, ka: float,
		A, tg: Dictionary) -> Array:
	var dv := to - from
	var dist := maxf(dv.length(), 0.01)
	var dir := dv / dist
	var wind: float = WIND[opt]
	var tf: float = T0 + wind + beat * float(GAP[opt])
	var bk: float = ka * {"sac": 1.25, "bolt": 1.1, "torp": 1.15, "mite": 0.9}[opt]
	var spd: float = float(SPEED[opt]) * fx.unit
	var ft := dist / spd
	var ti := tf + ft
	var out: Vector3 = (mn if mn.length_squared() > 0.01 else dir).normalized()
	# the organ works before the shot leaves: the pore swells and glows from inside (no muzzle flash: nothing burns)
	match opt:
		"sac":
			fx.spr(from, tf - wind, wind, col, 1.1, 0.5 * bk, 1.7 * bk, 15)
			fx.spr(from + out * 0.4 * bk, tf - 0.08, 0.5, MEMBRANE.lerp(col, 0.25), 1.0, 1.2 * bk, 3.2 * bk, 27, out * 2.5 * bk, 0.6)
		"bolt":
			fx.spr(from, tf - wind, wind, col, 0.9, 0.4 * bk, 1.0 * bk, 15)
			fx.ring(from + dir * 0.4 * bk, dir, tf, 0.35, BONE.lerp(col, 0.3), 1.2, 0.4 * bk, 2.6 * bk, 3, 0.0, 0.0, 22.0)
			for s in 6:
				fx.stk(from, tf, 0.5, col, 1.6, 0.06, 0.1 * bk, 6, (dir + fx.rdir() * 0.5).normalized() * 6.0 * bk, 1.5)
		"torp":
			fx.spr(from, tf - wind, wind, col, 0.9, 0.6 * bk, 1.6 * bk, 15)
			fx.spr(from + out * 0.5 * bk, tf - 0.1, 0.8, HIDE.lerp(col, 0.2), 0.8, 1.4 * bk, 3.6 * bk, 27, out * 1.8 * bk, 0.7)
			for s in 5:
				fx.stk(from, tf, 0.7, col, 1.4, 0.06, 0.1 * bk, 6, (out + fx.rdir() * 0.6).normalized() * 3.5 * bk, 1.2)
		"mite":
			fx.spr(from + out * 0.3 * bk, tf - 0.02, 0.35, MEMBRANE.lerp(col, 0.3), 0.9, 0.6 * bk, 1.6 * bk, 27, out * 3.0 * bk, 0.8)
	fx.light(from + out * 1.2 * bk, tf - wind * 0.5, wind * 0.5 + 0.25, 3.5, col, 1)
	if A != null and A.hull_pivot != null:
		# the ship shudders once with the effort (a muscle squeeze, not a gun's recoil)
		var inv: Transform3D = A.xf().affine_inverse()
		var lp: Vector3 = inv * from
		var back: Vector3 = (inv.basis * (-dir)).normalized()
		var kick: float = {"sac": 0.18, "bolt": 0.3, "torp": 0.14, "mite": 0.05}[opt]
		fx.later(tf, func l_squeeze() -> void: A.hit_react(fx, kick, lp, back, "recoil"))
	var node := _body(fx, opt, col, bk)
	var spin: Vector3 = fx.rdir()
	var side := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
	var list: Array = fx.dstate.get("cc_proj", [])
	list.append({"opt": opt, "node": node, "t0": tf, "t1": ti, "a": from + out * 0.3 * bk, "b": to, "dir": dir, "spin": spin,
		"side": side, "seed": fx.rng.randf() * TAU, "k": bk, "end": ti})
	fx.dstate["cc_proj"] = list
	# a faint bile light rides with the shot, so it reads at the battle camera as well as close up
	fx.light(from + dir * dist * 0.5, tf, ft, 1.4, col, 1)
	match opt:
		"bolt":
			for s in 7:
				var u := (s + 0.5) / 7.0
				fx.stk(from + dir * dist * u, tf + ft * u, 0.7, col, 1.5, 0.06, 0.09 * bk, 6, Vector3(0, -2.0, 0) + fx.rdir() * 1.0, 1.0)
		"sac":
			for s in 4:
				var u := (s + 0.5) / 4.0
				fx.stk(from + dir * dist * u, tf + ft * u, 0.9, col, 1.2, 0.05, 0.08 * bk, 6, fx.rdir() * 0.8, 1.0)
	_hit_matter(fx, opt, tg, ti, col, ka)
	return [tf, ti, ti + 0.4]


# What the body itself leaves on the plating, on top of the shared bio splat (fx_weapons._bio_splat).
static func _hit_matter(fx, opt: String, tg: Dictionary, T: float, col: Color, k: float) -> void:
	if bool(tg.get("miss", false)) or bool(tg.get("shield", false)):
		return
	var p: Vector3 = tg["p"]
	var n: Vector3 = tg["n"]
	var t1 := n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var t2 := n.cross(t1).normalized()
	match opt:
		"sac":
			# the shell cracks: pale shards scatter, then the load splashes wide and pools, bubbling for the acid turns
			for j in 9:
				var v: Vector3 = (n * 0.6 + fx.rdir()).normalized() * fx.rng.randf_range(4.0, 9.0) * k
				fx.stk(p + n * 0.2 * k, T, fx.rng.randf_range(0.6, 1.1), BONE, 1.2, 0.18, 0.12 * k, 1, v, 1.5)
			for j in 14:
				var a: float = TAU * float(j) / 14.0 + fx.rng.randf() * 0.3
				var v: Vector3 = (t1 * cos(a) + t2 * sin(a) + n * 0.25).normalized() * fx.rng.randf_range(2.0, 5.0) * k
				fx.spr(p + n * 0.15 * k, T + 0.02, fx.rng.randf_range(0.9, 1.6), col, 1.1, 0.35 * k, 0.2 * k, 15, v, 1.6)
			_pool(fx, p, n, t1, t2, T + 0.15, col, k, 1.6, 9)
		"bolt":
			for j in 12:
				var v: Vector3 = (n * 0.8 + fx.rdir() * 0.9).normalized() * fx.rng.randf_range(6.0, 13.0) * k
				fx.stk(p + n * 0.2 * k, T, fx.rng.randf_range(0.5, 1.0), BONE, 1.3, 0.25, 0.13 * k, 1, v, 1.2)
			# acid sheets down the plate: drops sliding along the surface, downhill in screen terms
			var down := (Vector3.DOWN - n * Vector3.DOWN.dot(n))
			down = down.normalized() if down.length_squared() > 0.01 else t1
			for j in 8:
				var off: Vector3 = (t1 * fx.rng.randf_range(-0.6, 0.6)) * k
				fx.spr(p + off + n * 0.1 * k, T + 0.05 + j * 0.06, 1.8, col, 0.9, 0.22 * k, 0.12 * k, 15, down * fx.rng.randf_range(1.0, 2.2) * k, 0.4)
			_pool(fx, p, n, t1, t2, T + 0.2, col, k, 0.9, 6)
		"torp":
			# a soft slap, the belly splits, acid pours and spreads, the husk flakes away in two halves
			for j in 12:
				var a: float = TAU * float(j) / 12.0
				var v: Vector3 = (t1 * cos(a) + t2 * sin(a) * 0.5 + n * 0.15).normalized() * fx.rng.randf_range(1.5, 3.5) * k
				fx.spr(p + n * 0.2 * k, T + 0.08 + fx.rng.randf() * 0.12, fx.rng.randf_range(1.2, 2.0), col, 1.0, 0.4 * k, 0.25 * k, 15, v, 1.4)
			_pool(fx, p, n, t1, t2, T + 0.2, col, k, 1.8, 10)
			_husk(fx, p + n * 0.4 * k, n, t1, T + 0.12, k)
		"mite":
			# curl and pop: a flat fan of acid across the plating, nothing stays stuck on
			fx.spr(p + n * 0.3 * k, T, 0.18, col.lerp(Color.WHITE, 0.2), 2.2, 0.5 * k, 1.3 * k, 15)
			var fan := t1
			for j in 16:
				var a: float = (float(j) / 15.0 - 0.5) * 2.4
				var v: Vector3 = (fan * cos(a) + t2 * sin(a) + n * 0.12).normalized() * fx.rng.randf_range(5.0, 9.0) * k
				fx.spr(p + n * 0.15 * k, T + 0.01, fx.rng.randf_range(0.5, 0.9), col, 1.2, 0.22 * k, 0.12 * k, 15, v, 2.4)
			for j in 4:
				fx.stk(p + n * 0.2 * k, T, 0.7, BONE_DARK, 1.0, 0.12, 0.1 * k, 1, (n + fx.rdir()).normalized() * 4.0 * k, 1.5)
			_pool(fx, p, n, t1, t2, T + 0.1, col, k, 1.0, 5)


# The acid pool: soft bile glow lying on the plate and small bubbles popping in it for a while (the acid trait's two turns,
# shortened for the clip), with thin fumes. Sprites only; the shared acid pit mark stays on the hull after it.
static func _pool(fx, p: Vector3, n: Vector3, t1: Vector3, t2: Vector3, T: float, col: Color, k: float, size: float, bubbles: int) -> void:
	fx.spr(p + n * 0.12 * k, T, 3.2, col * 0.8, 0.55, size * 0.9 * k, size * 1.5 * k, 18)
	for j in bubbles:
		var off: Vector3 = (t1 * fx.rng.randf_range(-1.0, 1.0) + t2 * fx.rng.randf_range(-1.0, 1.0)) * size * 0.6 * k
		var at: float = T + fx.rng.randf_range(0.1, 2.6)
		fx.spr(p + off + n * 0.15 * k, at, 0.35, col, 1.3, 0.08 * k, 0.32 * k, 15, n * 0.6 * k, 0.5)
	for j in 3:
		fx.spr(p + n * 0.5 * k, T + 0.3 + j * 0.7, 2.0, Color(0.42, 0.42, 0.24), 0.5, 0.6 * k, 2.2 * k, 20, n * 1.2 * k, 0.4)


static func _husk(fx, p: Vector3, n: Vector3, t1: Vector3, T: float, k: float) -> void:
	var memb := _mat(fx, "husk", func() -> Material: return _std(MEMBRANE.darkened(0.2), 0.7, Color.BLACK, 0.0, 0.85))
	var list: Array = fx.dstate.get("cc_proj", [])
	for s in [-1.0, 1.0]:
		var node := Node3D.new()
		node.name = "fx_chorus_husk"
		_mi(node, _sphere(0.6, 12, 6), memb, Vector3.ZERO, Vector3(1.6, 0.3, 0.8))
		node.scale = Vector3.ONE * k * fx.unit
		node.visible = false
		fx.add_child(node)
		var v: Vector3 = (n * 0.8 + t1 * s * 0.9).normalized() * 2.2 * k
		list.append({"opt": "husk", "node": node, "t0": T, "t1": T + 2.4, "a": p, "vel": v, "spin": fx.rdir(), "seed": 0.0,
			"k": k, "end": T + 2.4})
	fx.dstate["cc_proj"] = list


static func update(fx, _dt: float) -> void:
	var list: Array = fx.dstate.get("cc_proj", [])
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
		var age: float = now - float(p["t0"])
		var u := clampf(age / maxf(float(p["t1"]) - float(p["t0"]), 0.001), 0.0, 1.0)
		var sd: float = p["seed"]
		var opt: String = p["opt"]
		var basis := Basis.IDENTITY
		var pos: Vector3
		if opt == "husk":
			pos = (p["a"] as Vector3) + (p["vel"] as Vector3) * age
			basis = Basis(p["spin"], age * 1.6)
			var f := 1.0 - smoothstep(0.6, 1.0, u)
			n3.global_transform = Transform3D(basis.scaled(Vector3.ONE * float(p["k"]) * fx.unit * maxf(f, 0.05)), pos)
			n3.visible = true
			continue
		var d: Vector3 = p["dir"]
		pos = (p["a"] as Vector3).lerp(p["b"], u)
		var z := d.cross(Vector3.UP if absf(d.y) < 0.95 else Vector3.FORWARD).normalized()
		var along := Basis(d, z.cross(d).normalized(), z)
		var k: float = p["k"]
		match opt:
			"sac":
				# tumbles slowly end over end, and the sac sloshes (a slow squash)
				basis = Basis(p["spin"], age * 2.2 + sd)
				var sq := 1.0 + 0.08 * sin(age * 9.0 + sd)
				basis = basis.scaled(Vector3(sq, 1.0 / sq, 1.0))
			"bolt":
				basis = along * Basis(Vector3.RIGHT, age * 6.0)
			"torp":
				# swims: a side-to-side wave along its path, the fins and the tail rippling
				pos += (p["side"] as Vector3) * sin(age * 7.0 + sd) * 0.35 * k * (1.0 - u * 0.5)
				basis = along * Basis(Vector3.UP, cos(age * 7.0 + sd) * 0.25)
				for fname in ["fin_l", "fin_r"]:
					var fin := n3.get_node_or_null(fname) as Node3D
					if fin != null:
						fin.rotation = Vector3(sin(age * 11.0 + sd + (0.0 if fname == "fin_l" else PI)) * 0.55, 0, 0)
				var tail := n3.get_node_or_null("tail") as Node3D
				if tail != null:
					tail.rotation = Vector3(0, sin(age * 7.0 + sd + 1.2) * 0.6, 0)
			"mite":
				pos += (p["side"] as Vector3) * sin(age * 13.0 + sd) * 0.18 * k + Vector3.UP * sin(age * 17.0) * 0.08 * k
				basis = along
				for wname in ["wing_l", "wing_r"]:
					var wing := n3.get_node_or_null(wname) as Node3D
					if wing != null:
						# a blur: the wing flickers through its stroke every frame
						wing.rotation = Vector3(sin(now * 260.0 + (0.0 if wname == "wing_l" else PI)) * 0.7, 0, 0)
		if now >= float(p["t1"]):
			n3.visible = false
			continue
		n3.global_transform = Transform3D(basis.scaled(Vector3.ONE * k * fx.unit), pos)
		n3.visible = true
	fx.dstate["cc_proj"] = keep
