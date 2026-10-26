extends Node3D
# PLACEHOLDER battle effects, until the G4 effects system lands (godot/fx/, its API in godot/fx/API.md).
# Only the simplest readable cues, so a battle can be played and judged for flow: bolts, beams, torpedoes, impact flashes,
# a shield flash on the facing that was hit, and a ship-death flash. Every call takes world positions and colours and
# returns nothing the rules depend on. When godot/fx/API.md exists, battle.gd calls that instead and this file goes.

var items: Array = []        # [{node, t, dur, kind, a, b, ...}]
static var _glow: Texture2D = null


static func clear_static() -> void:
	_glow = null


static func glow_tex() -> Texture2D:
	if _glow != null:
		return _glow
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 31.5
			var a := clampf(exp(-d * d * 4.0) * 0.7 + exp(-d * d * 24.0) * 0.6, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_glow = ImageTexture.create_from_image(img)
	return _glow


func _add_mat(col: Color, k := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(col.r * k, col.g * k, col.b * k, 1.0)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


func _sprite(pos: Vector3, size: float, col: Color, k := 3.0) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = glow_tex()
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.transparent = true
	s.pixel_size = size / 64.0
	s.modulate = Color(col.r * k, col.g * k, col.b * k, 1.0)
	s.position = pos
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	add_child(s)
	return s


# a bolt (or rocket, or torpedo) flying from a to b over dur seconds, after a delay
func bolt(a: Vector3, b: Vector3, col: Color, dur: float, delay := 0.0, size := 1.4, miss := false) -> void:
	var s := _sprite(a, size * 2.2, col, 4.0)
	s.visible = delay <= 0.0
	var end := b
	if miss:
		var side := (b - a).cross(Vector3.UP).normalized()
		end = b + side * randf_range(-9.0, 9.0) + (b - a).normalized() * randf_range(8.0, 24.0)
	items.append({"node": s, "t": -delay, "dur": dur, "kind": "bolt", "a": a, "b": end})


# a beam from a to b, held for dur seconds
func beam(a: Vector3, b: Vector3, col: Color, dur: float, delay := 0.0, width := 0.9) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = width * 0.5
	cm.bottom_radius = width * 0.5
	cm.height = 1.0
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _add_mat(col, 5.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var L := a.distance_to(b)
	var mid := (a + b) * 0.5
	var dir := (b - a).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var basis := Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, PI / 2.0)
	mi.transform = Transform3D(basis.scaled(Vector3(1, L, 1)), mid)
	mi.visible = delay <= 0.0
	add_child(mi)
	items.append({"node": mi, "t": -delay, "dur": dur, "kind": "beam"})


# a flash of light: a glow sprite that swells and fades, with a short point light
func flash(p: Vector3, size: float, col: Color, dur := 0.35, delay := 0.0, light := true) -> void:
	var s := _sprite(p, size, col, 3.0)
	s.visible = delay <= 0.0
	var it := {"node": s, "t": -delay, "dur": dur, "kind": "flash", "size": size}
	if light:
		var l := OmniLight3D.new()
		l.light_color = col
		l.omni_range = size * 2.5
		l.light_energy = 0.0
		l.shadow_enabled = false
		l.position = p
		add_child(l)
		it["light"] = l
	items.append(it)


# a shield shimmer: a faint ellipsoid round the ship, brighter on the facing that was hit
func shield(ship: Node3D, L: float, quad: int, col: Color, delay := 0.0, broke := false) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 32
	sm.rings = 16
	mi.mesh = sm
	var m := _add_mat(col, 1.2 if not broke else 2.4)
	m.albedo_color.a = 0.0
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3(L * 1.3, L * 0.45, L * 0.75)
	# quad: 0 prow (+x local), 1 starboard, 2 rear, 3 port; nudge the bubble toward the hit facing
	var off: Vector3 = [Vector3(L * 0.12, 0, 0), Vector3(0, 0, L * 0.08), Vector3(-L * 0.12, 0, 0), Vector3(0, 0, -L * 0.08)][clampi(quad, 0, 3)]
	mi.position = off
	mi.visible = delay <= 0.0
	ship.add_child(mi)
	items.append({"node": mi, "t": -delay, "dur": 0.45 if not broke else 0.8, "kind": "shield", "mat": m})


func _process(dt: float) -> void:
	var i := items.size() - 1
	while i >= 0:
		var it: Dictionary = items[i]
		it.t += dt
		var n: Node3D = it.node
		if it.t < 0.0:
			i -= 1
			continue
		n.visible = true
		var k := clampf(it.t / maxf(it.dur, 0.001), 0.0, 1.0)
		match it.kind:
			"bolt":
				n.position = (it.a as Vector3).lerp(it.b, k)
			"beam":
				var f := 1.0 - smoothstep(0.6, 1.0, k)
				n.scale = Vector3(f, n.scale.y, f)
			"flash":
				var sz: float = it.size * (0.6 + 0.8 * k)
				(n as Sprite3D).pixel_size = sz / 64.0
				(n as Sprite3D).modulate.a = 1.0 - k
				if it.has("light"):
					(it.light as OmniLight3D).light_energy = 6.0 * (1.0 - k)
			"shield":
				(it.mat as StandardMaterial3D).albedo_color.a = 0.55 * sin(PI * k)
		if it.t >= it.dur:
			n.queue_free()
			if it.has("light"):
				(it.light as Node).queue_free()
			items.remove_at(i)
		i -= 1


func clear() -> void:
	for it in items:
		(it.node as Node).queue_free()
		if it.has("light"):
			(it.light as Node).queue_free()
	items.clear()
