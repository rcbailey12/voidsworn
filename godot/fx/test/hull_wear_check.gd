extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1235 run 2 (Neon's damage audit F1.2, the rest): a ship looks more worn as its hull HP falls, on box stand-ins.
# 1. hull_wear is 0 above fx_ship.WEAR_FROM of max HP and 1 at WEAR_FULL; it reaches the live damage surfaces through
#    the damage shader's own uniforms (fx_weather, fx_power) with scorch heat 0 (no orange embers on any faction)
# 2. soot patches sit where the ship was hit (each patch centre is a drawn mark's centre), worst section first, at most 8
# 3. below LIST_FROM of max HP the hull lists LIST_MIN to LIST_MAX degrees toward the side last hit, settles there, and
#    comes back level when repaired; nothing of this reaches the rules (fx only)
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const SHIP := preload("res://fx/fx_ship.gd")
const HULL := preload("res://fx/fx_hull.gd")
var failures := 0
var fx
var world: Node3D


func _init() -> void:
	GUARD.arm(self, "hull_wear_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("  ok: ", message)


func _ship(sid: String, faction: String, pos: Vector3):
	var body := Node3D.new()
	world.add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(24, 5, 8)
	bm.subdivide_width = 17
	bm.subdivide_depth = 5
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, bm.get_mesh_arrays())
	mi.mesh = am
	body.add_child(mi)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.8, "meshes": [mi], "shielded": false})
	fx._later.clear()
	var s = fx.ship(sid)
	for i in 3:
		s._anchors["a%d" % i] = {"p": Vector3((i - 1) * 7, 2.5, 0), "n": Vector3.UP, "t": {}}
	return s


func _state(hp: float, eng: float, mid: float, prow: float) -> Dictionary:
	return {"hp": hp, "maxHp": 100.0, "sec": {"eng": {"hp": eng, "max": 100}, "mid": {"hp": mid, "max": 100}, "prow": {"hp": prow, "max": 100}}}


func flush(s) -> void:
	for i in 5:
		if s._dmg_task >= 0:
			s.flush_damage(fx)
		fx.step(0.01)


func settle(secs: float) -> void:
	for i in int(secs / 0.05):
		fx.step(0.05)


func _mats(s) -> Array:
	var out: Array = []
	for key in s._damage_surfaces:
		var e: Array = s._damage_surfaces[key]
		if e.size() > 1 and e[1] is ShaderMaterial:
			out.append(e[1])
	return out


func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	var x := 0.0
	for faction in ["voidsworn", "ithar", "chorus", "hegemony"]:
		var s = _ship("wear_" + faction, faction, Vector3(x, 0, 0))
		x += 40.0
		s.sync(fx, _state(100.0, 100, 100, 100))
		check(s.hull_wear == 0.0 and s.list_target == 0.0, "%s: a healthy ship has no wear and no list" % faction)
		# hits on the port side of the mid and prow sections
		s.add_mark(fx, "torp", 4, Vector3(0, 2.5, -2), Vector3.UP, Vector3.DOWN)
		s.add_mark(fx, "macro", 2, Vector3(8, 2.5, -1), Vector3.UP, Vector3.DOWN)
		s.sync(fx, _state(50.0, 90, 40, 60))
		flush(s)
		check(absf(s.hull_wear - 0.5) < 1e-4, "%s: half HP is half wear (%.3f)" % [faction, s.hull_wear])
		var mats := _mats(s)
		check(not mats.is_empty(), "%s: the hurt ship has live damage surfaces" % faction)
		var ok_u := true
		for m in mats:
			var mm: ShaderMaterial = m
			ok_u = ok_u and absf(float(mm.get_shader_parameter("fx_weather")) - 0.5 * HULL.WEAR_WEATHER) < 1e-4
			ok_u = ok_u and absf(float(mm.get_shader_parameter("fx_power")) - (1.0 - 0.5 * HULL.WEAR_POWER)) < 1e-4
			ok_u = ok_u and float(mm.get_shader_parameter("fx_scorch_heat")) == 0.0
		check(ok_u, "%s: every damage surface carries the wear (darker plating, dimmer lights) with no ember heat" % faction)
		var patches: Array = s.wear_patches()
		check(patches.size() >= 2 and patches.size() <= 8, "%s: soot patches on the hit sides (%d)" % [faction, patches.size()])
		var on_marks := true
		for q in patches:
			var hit := false
			for e in s._marks:
				if Vector3(q.x, q.y, q.z).is_equal_approx(e.c):
					hit = true
			on_marks = on_marks and hit
		check(on_marks, "%s: every soot patch sits on a place the ship was hit" % faction)
		check(patches.size() > 0 and s._marks.size() > 0 and s.hull.section_of(Vector3(patches[0].x, 0, 0).x) == 1, "%s: the worst section's patch comes first" % faction)
		var n_count := 0
		for m in mats:
			n_count = maxi(n_count, int((m as ShaderMaterial).get_shader_parameter("fx_scorch_count")))
		check(n_count == patches.size(), "%s: the shader gets every patch (%d)" % [faction, n_count])
		check(s.list_target == 0.0, "%s: no list at half HP" % faction)
		# below 35%: the list
		s.sync(fx, _state(20.0, 60, 15, 30))
		var deg := rad_to_deg(absf(s.list_target))
		check(deg >= SHIP.LIST_MIN - 1e-3 and deg <= SHIP.LIST_MAX + 1e-3, "%s: a crippled ship lists %.2f degrees" % [faction, deg])
		check(s.list_target < 0.0, "%s: it lists toward the side last hit (port)" % faction)
		# Sol review of PR 1570: a shield-only hit on the other side (hit_react, no mark) does not turn the list round,
		# and neither does a later hull hit on the other side while it already lists
		s.hit_react(fx, 1.0, Vector3(4, 0, 4), Vector3(0, 0, -1))
		s.sync(fx, _state(19.0, 60, 14, 30))
		check(s.list_target < 0.0, "%s: a shield hit on the far side leaves the list where it was" % faction)
		s.add_mark(fx, "macro", 2, Vector3(-6, 0.5, 4), Vector3(0, 0, 1), Vector3(0, 0, -1))
		s.sync(fx, _state(18.0, 60, 13, 30))
		check(s.list_target < 0.0, "%s: a later hull hit on the far side does not flip a list already set" % faction)
		settle(SHIP.LIST_T * 3.0)
		check(absf(s.root.rotation.x - s.list_target) < deg_to_rad(0.15), "%s: the hull settles at its list (%.2f against %.2f degrees)" % [faction, rad_to_deg(s.root.rotation.x), rad_to_deg(s.list_target)])
		# a hit while listing: the reaction rides on the list and comes back to it
		s.hit_react(fx, 2.0, Vector3(-6, 0, -4), Vector3(0, 0, 1))
		settle(6.0)
		check(absf(s.root.rotation.x - s.list_target) < deg_to_rad(0.15), "%s: after a hit reaction it comes back to the list, not level" % faction)
		# repaired: no wear, back to level
		s.sync(fx, _state(95.0, 95, 95, 95))
		settle(SHIP.LIST_T * 3.0)
		check(s.hull_wear == 0.0 and s.list_target == 0.0 and absf(s.root.rotation.x) < deg_to_rad(0.15), "%s: a repaired ship is unworn and level again" % faction)
		# Sol review: a small last repair (wear 0.0167 to 0) must still clear the shader
		s.sync(fx, _state(79.0, 79, 79, 79))
		check(s.hull_wear > 0.0 and s.hull_wear < 0.02, "%s: a nearly repaired ship has a trace of wear (%.4f)" % [faction, s.hull_wear])
		s.sync(fx, _state(95.0, 95, 95, 95))
		var clean := true
		for m in _mats(s):
			clean = clean and float((m as ShaderMaterial).get_shader_parameter("fx_weather")) == 0.0 and float((m as ShaderMaterial).get_shader_parameter("fx_power")) == 1.0
		check(clean, "%s: the repaired ship's surfaces lose the wear" % faction)
	# a view rebuilt after Continue: no hull hit known, so the side comes from the ship's id, the same every time
	var sides: Array = []
	for n in 2:
		var r = _ship("rebuilt", "voidsworn", Vector3(0, 0, 60 + 40 * n))
		r.sync(fx, _state(20.0, 60, 15, 30))
		check(r.list_target != 0.0, "a rebuilt crippled ship still lists (try %d)" % n)
		sides.append(signf(r.list_target))
		fx.remove_ship("rebuilt")
		settle(0.2)
	check(sides.size() == 2 and sides[0] == sides[1], "a rebuilt ship with no known hit side leans the same way every time")
	print("hull_wear_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
