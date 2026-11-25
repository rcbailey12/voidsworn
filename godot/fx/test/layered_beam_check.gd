extends SceneTree
## Issue 2047: exercise the live volley route and inspect the GPU payloads before they upload.

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const SOURCE := Vector3(-26, 0, 0)
const TARGET := Vector3(26, 0, 0)

var failures := 0
var world: Node3D
var fx: FX


func _init() -> void:
	GUARD.arm(self, "layered_beam_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)


func _setup(calm: bool) -> void:
	world = Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 140, 96)
	cam.look_at(Vector3.ZERO)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": calm, "seed": 2047})
	fx.flash_area_logging = true


# off is the index of the particle field in fx_pool.pack, not a readback of the dummy renderer.
func _rows(key: String, off: int, kind: int) -> Array[PackedFloat32Array]:
	var pool: POOLS.Pool = fx.pools[key]
	var rows: Array[PackedFloat32Array] = []
	for i in pool.n_pending:
		var start: int = i * pool.vpp * POOLS.STRIDE
		if is_equal_approx(pool.pending[start + off], float(kind)):
			rows.append(pool.pending.slice(start, start + POOLS.STRIDE))
	return rows


func _position(row: PackedFloat32Array) -> Vector3:
	return Vector3(row[4], row[5], row[6])


func _advance(seconds: float) -> void:
	for i in ceili(seconds * 60):
		fx.step(1.0 / 60.0)
		await process_frame


func _release() -> void:
	fx.release()
	world.queue_free()
	await process_frame


func _beam(weapon: String, faction: String, kind: int, expected_lenses: int, calm: bool) -> void:
	_setup(calm)
	var label := "%s/%s%s" % [faction, weapon, " calm" if calm else ""]
	var opts := {"weapon_id": weapon, "faction": faction, "shots": [false]}
	var volley := fx.volley_at(SOURCE, "battery" if weapon == "turret" else "lance", TARGET, opts)
	if (volley.get("fires", []) as Array).size() != 1:
		_check(false, label + " fired no shot")
		await _release()
		return
	var fire: float = volley.fires[0]
	var beam_key := "nlance" if weapon == "nlance" else "rib"
	var shaft := _rows(beam_key, 7, kind)
	_check(shaft.size() == 1, label + " emits one layered shaft in the expected pool")
	if not shaft.is_empty():
		var p := shaft[0]
		var dir := Vector3(p[8], p[9], p[10])
		_check(_position(p).is_equal_approx(SOURCE) and (SOURCE + dir * p[11]).is_equal_approx(TARGET),
			label + " stays pinned to muzzle and aim")
		_check(is_equal_approx(p[0], fire) and is_equal_approx(float(volley.impacts[0]) - fire, 0.03),
			label + " uses the shot and contact clocks")
		if weapon == "lance":
			_check(p[16] > p[17], label + " tapers toward the contact")
			var faction_col: Color = fx.faction_info(faction).weapon
			_check(Vector3(p[12], p[13], p[14]).normalized().is_equal_approx(Vector3(faction_col.r, faction_col.g, faction_col.b).normalized()),
				label + " uses the firing faction palette")
	var glass := faction == "ithar"
	var rings := _rows("rng", 18, SH.RING_HARMONIC if glass else 3)
	var charge := 0
	var travel := 0
	for ring in rings:
		if ring[7] < fire - 0.0001 and _position(ring).distance_to(SOURCE) < 2.0 and ring[1] < 0.0:
			charge += 1
		elif ring[7] >= fire - 0.0001 and ring[1] > 0.0:
			travel += 1
			_check(is_equal_approx(ring[1] * ring[11], SOURCE.distance_to(TARGET)),
				label + " harmonic does not overshoot the contact")
	_check(charge > 0, label + " gathers at the emitter before firing")
	_check(travel == (3 if weapon == "pulsar" else 0), label + " only Pulsar sends three faceted wavefronts down the beam")
	var lenses := _rows("dst", 18, SH.DISTORT_BEAM)
	_check(lenses.size() == expected_lenses, label + " lens count matches beam profile")
	var last := SOURCE.x
	for lens in lenses:
		var at := _position(lens)
		_check(at.x > last and at.x < TARGET.x and is_zero_approx(at.y) and is_zero_approx(at.z) and lens[7] >= fire,
			label + " lenses run down the shaft instead of a broad screen wash")
		last = at.x
	if glass:
		_check(fx.pools["dst"].n_pending == 0 and not SH.RIBBON.contains("hint_screen_texture") and not SH.RING.contains("hint_screen_texture"),
			label + " dispersion and shimmer emit light without screen refraction")
	await _advance(fire + 0.70)
	if calm:
		_check(fx.flash_area_log.is_empty() and fx.flash_log.is_empty(), label + " books no hard flashes in Reduce Flashing")
	print("  checked ", label)
	await _release()


func _null_contact(absorbed: bool, faction := "hegemony", v2 := false) -> void:
	var old_v2 := OS.get_environment("VS_WOUNDS_V2")
	OS.set_environment("VS_WOUNDS_V2", "1" if v2 else "0")
	_setup(false)
	for a in [["A", SOURCE, "deathless"], ["T", TARGET, faction]]:
		var ship := Node3D.new()
		world.add_child(ship)
		ship.position = a[1]
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(12, 3, 4)
		box.subdivide_width = 11
		box.subdivide_depth = 3
		mesh.mesh = box
		ship.add_child(mesh)
		fx.add_ship(a[0], ship, {"faction": a[2], "cls": "Cruiser", "size": 1.0,
			"meshes": [mesh], "shielded": a[0] == "T" and absorbed})
	var target = fx.ship("T")
	var result := fx.volley("A", "lance", "T", {"weapon_id": "nlance", "shots": [true],
		"hits": [{"shield": 5 if absorbed else 0, "hull": 0 if absorbed else 9, "section": "mid"}]})
	_check((result.get("impacts", []) as Array).size() == 1, "real null lance volley reaches the target")
	if faction == "chorus" and not absorbed:
		var flares := _rows("spr", 18, 13)
		_check(not flares.is_empty() and fx.pools["smk"].n_pending == 0,
			"null lance hits tissue without adding green mist")
		for flare in flares:
			_check(flare[14] > flare[12] and flare[14] > flare[13], "null lance contact flares stay violet on tissue")
	await _advance(1.3)
	var label := "%s Null Lance on %s" % ["V2" if v2 else "legacy", faction]
	var parts := {}
	for mark: BREACH.Ent in target._marks:
		_check(mark.look == "nlance" and mark.style == BREACH.S_NLANCE and mark.kind == BREACH.K_SLOT and not mark.has_cut(),
			label + " uses the shared sealed Null Lance style")
		_check((mark.v2 >= 0) == v2, label + " keeps the Wounds V2 gate")
		parts[mark.part_i] = true
	var count := 0 if absorbed else (3 if v2 else 1)
	_check(target._marks.size() == count and parts.size() == count,
		label + " leaves %d distinct cuts (got %d)" % [count, target._marks.size()])
	if not absorbed:
		_check(not fx.dstate.has("heat_spot_mat"), "null lance does not apply the orange heat overlay")
	await _release()
	if old_v2.is_empty():
		OS.unset_environment("VS_WOUNDS_V2")
	else:
		OS.set_environment("VS_WOUNDS_V2", old_v2)


func _run() -> void:
	_check(SH.RING_HARMONIC == 6 and SH.RIB_NULL_LANCE == 11 and SH.DISTORT_BEAM == 2,
		"Build F uses its assigned ring, ribbon and distortion IDs")
	_check(BREACH.S_PRISM == 16 and BREACH.S_STAR == 17 and BREACH.S_NLANCE == 18,
		"Wounds V2 styles stay on their assigned IDs")
	var ring_vertex: String = SH.RING.get_slice("void vertex()", 1).get_slice("void fragment()", 0)
	var ring_fragment: String = SH.RING.get_slice("void fragment()", 1)
	_check(ring_vertex.contains("if (rk == 6)") and ring_fragment.contains("if (k == 6)"),
		"both ring shader stages use the harmonic ID")
	_check(ring_vertex.contains("px_world(36.0, dv, PROJECTION_MATRIX)"),
		"the harmonic ring floor follows fx_px and turns off with the other floors")
	for calm in [false, true]:
		await _beam("lance", "voidsworn", SH.RIB_LANCE, 3, calm)
		await _beam("lance", "corsair", SH.RIB_LANCE, 3, calm)
		await _beam("nlance", "deathless", SH.RIB_NULL_LANCE, 5, calm)
		await _beam("ion", "hegemony", SH.RIB_ION, 3, calm)
		await _beam("pulsar", "ithar", SH.RIB_PULSAR, 0, calm)
		await _beam("turret", "ithar", SH.RIB_NEEDLE, 0, calm)
	await _null_contact(false)
	await _null_contact(true)
	await _null_contact(false, "chorus")
	await _null_contact(false, "hegemony", true)
	await _null_contact(true, "hegemony", true)
	if failures == 0:
		print("PASS: layered beam routing, charge, timing, harmonics, lenses, Glasswright no-refraction and null contact")
	quit(1 if failures else 0)
