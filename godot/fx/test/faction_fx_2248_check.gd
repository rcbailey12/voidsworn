extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const SPECIAL := preload("res://fx/fx_special.gd")
const SH := preload("res://fx/fx_shaders.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const ROOT := preload("res://tools/ci/world_root.gd")
const A16_FIXTURE := "res://fx/test/fixtures/C19_51_unbaked.glb.gz"

# The cold face pigments on main at 061f6268. The seam's heat is a separate input.
const MAIN_CAP := {"deathless": Vector3(0.16, 0.12, 0.21), "corsair": Vector3(0.35, 0.105, 0.065)}
const LUMA := Vector3(0.2126, 0.7152, 0.0722)

var failures := 0
var world: Node3D
var fx: FX


func _init() -> void:
	GUARD.arm(self, "faction_fx_2248_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	print(("  PASS " if ok else "  FAIL ") + message)
	if not ok:
		failures += 1


func _setup() -> void:
	world = Node3D.new()
	root.add_child(world)
	fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "death_story": "on", "shake": 0.0})


func _end() -> void:
	fx.release()
	world.free()


func _ship(faction: String, cls: String):
	var body := Node3D.new()
	world.add_child(body)
	var core := Marker3D.new()
	core.name = "hp_core"
	body.add_child(core)
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 6)
	box.subdivide_width = 19
	box.subdivide_height = 3
	box.subdivide_depth = 5
	part.mesh = box
	part.material_override = StandardMaterial3D.new()
	body.add_child(part)
	fx.add_ship("T", body, {"faction": faction, "cls": cls, "meshes": [part], "shielded": false})
	var ship = fx.ship("T")
	ship.wounds_v2 = true
	return ship


func _rgb(col) -> Vector3:
	return Vector3(col.r, col.g, col.b) if col is Color else col


func _sprite_count(pool_name: String, kind: int, colour: Color) -> int:
	var pool: POOLS.Pool = fx.pools[pool_name]
	var found := 0
	for i in range(0, pool.pending.size(), POOLS.STRIDE * pool.vpp):
		var rgb := Vector3(pool.pending[i + 12], pool.pending[i + 13], pool.pending[i + 14])
		if int(pool.pending[i + 18]) == kind and rgb.is_equal_approx(_rgb(colour)):
			found += 1
	return found


func _check_split_vent() -> void:
	_setup()
	var ship = _ship("ithar", "Frigate")
	fx.reduce_flashing = true # No ignition to mask the opaque grey cone on main.
	fx.spr_kinds = {}
	DEATH._split_vent(fx, ship, ship.hull.c, Vector3.UP)
	_check(ship.has_meta("death_vent_style") and not fx.spr_kinds.has(SH.VENT_JET)
		and not fx.spr_kinds.has(27) and _sprite_count("spr", 16, ship.fac.damage_glow) >= 4,
		"Glasswright split vents stored-light glints without the soot jet, even with ignition refused")
	_end()


func _check_bay() -> void:
	_setup()
	var ship = _ship("ithar", "Carrier")
	fx.spr_kinds = {}
	SPECIAL.bay(fx, ship, Vector3.ZERO, Vector3.UP, Vector3.RIGHT, fx.now)
	_check(_sprite_count("spr", 16, ship.fac.damage_glow) == 2 and not fx.spr_kinds.has(27),
		"Glasswright bay releases stored-light glints from both rails instead of smoke")
	_end()


func _matches_plume(node: MeshInstance3D, ship, cold: bool) -> bool:
	if node == null or not node.material_override is ShaderMaterial:
		return false
	var mat := node.material_override as ShaderMaterial
	var glow := _rgb(BREACH.wound_col(ship.fac.wound, "interior_accent", ship.fac.damage_glow))
	var sheath: Vector3
	var power := 0.0 if cold else 0.65
	match ship.faction:
		"chorus":
			sheath = glow * (0.25 if cold else 0.17)
			power *= 0.42
		"hegemony":
			sheath = glow * 0.18
			power *= 0.38
		"deathless":
			sheath = glow * (0.20 if cold else 0.095)
			power *= 0.35
	return glow.is_equal_approx(mat.get_shader_parameter("colour_core")) \
		and sheath.is_equal_approx(mat.get_shader_parameter("colour_sheath")) \
		and is_equal_approx(power, mat.get_shader_parameter("core_power"))


func _check_hulk(faction: String) -> void:
	_setup()
	var ship = _ship(faction, "Cruiser")
	fx.death("T", "board" if faction == "chorus" else "dark")
	fx.step(0.80)
	var vent := (fx.phys_root.find_child("fx_hulk_vent", true, false) as MeshInstance3D)
	_check(_matches_plume(vent, ship, true), faction + " hulk uses its wound tint and sheath but stays cold")
	_end()


func _check_wing(faction: String) -> void:
	_setup()
	var ship = _ship(faction, "Squadron")
	ship.sync(fx, {"hp": 49, "maxHp": 100})
	fx.step(0.20)
	_check(_matches_plume(ship._wing_smoke, ship, false), faction + " damaged wing uses its wound tint, sheath and core profile")
	_end()


func _check_api() -> void:
	var api := FileAccess.get_file_as_string("res://fx/API.md")
	_check(api.contains("`tint = Color.TRANSPARENT`") and api.contains("`fac.damage_glow`")
		and api.contains("`profile = Profile.BASE`") and api.contains("wounds, wings and hulks"),
		"FX API documents the optional plume tint, its fallback, its profile and the shared callers")


func _barge() -> Node3D:
	# Pass the installed C19_51 GLB after -- to exercise its painted export too.
	var args := OS.get_cmdline_user_args()
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var result: Error
	if args.is_empty():
		var bytes := FileAccess.get_file_as_bytes(A16_FIXTURE).decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		if bytes.is_empty():
			return null
		result = doc.append_from_buffer(bytes, A16_FIXTURE.get_base_dir(), state)
	else:
		result = doc.append_from_file(args[0], state)
	if result != OK:
		return null
	var hull: Node3D = doc.generate_scene(state)
	if hull == null:
		return null
	var holder := ROOT.hold(world, hull)
	fx.add_ship("T", holder, {"faction": "corsair", "cls": "Battle-barge", "code": "C19_51", "shielded": false})
	return holder


func _check_cap(faction: String) -> void:
	_setup()
	var is_barge := faction == "corsair"
	if is_barge:
		var holder := _barge()
		if holder == null:
			_check(false, "C19_51 loads")
			_end()
			return
		var ship = fx.ship("T")
		_check(ship.hull.authored and ROOT.at_game_size(ship, ROOT.held_length(holder)),
			"C19_51 uses its authored hull at game size")
		# Let the real export finish cutting before starting the death clock, as the look bench does.
		DEATH.precompute(fx, ship, "blast", true)
		var deadline := Time.get_ticks_msec() + 120000
		while not DEATH.finish_precompute(fx, ship) and Time.get_ticks_msec() < deadline:
			await process_frame
			OS.delay_msec(1)
	else:
		_ship(faction, "Cruiser")
	fx.death("T", "blast")
	# Give the actual cut worker time to finish. Then look after the seam has cooled, not at a stand-alone material.
	var cap_count := 0
	var cold_count := 0
	var soot_count := 0
	var darkest_ratio := 1.0
	var brightest_ratio := 0.0
	var deadline := Time.get_ticks_msec() + 10000
	while not bool((fx.ship("T").get_meta("cut_job", {}) as Dictionary).get("built", false)) and fx.dstate.wrecks.is_empty() and Time.get_ticks_msec() < deadline:
		fx.step(1.0 / 60.0)
		await process_frame
		OS.delay_msec(1)
	for i in 9 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
	for wreck in fx.dstate.wrecks:
		for piece: Node3D in wreck.nodes:
			for mesh: MeshInstance3D in piece.find_children("*", "MeshInstance3D", false, false):
				for i in mesh.mesh.get_surface_count():
					var mat := mesh.get_active_material(i) as ShaderMaterial
					if mat == null or mat.shader.code != DEATH.SLAG:
						continue
					cap_count += 1
					if is_zero_approx(mat.get_shader_parameter("heat")):
						cold_count += 1
					if mat.get_shader_parameter("cold_soot") == true:
						soot_count += 1
					var paint := _rgb(mat.get_shader_parameter("scorch_tint"))
					var ratio := paint.dot(LUMA) / (MAIN_CAP[faction] as Vector3).dot(LUMA)
					darkest_ratio = minf(darkest_ratio, ratio)
					brightest_ratio = maxf(brightest_ratio, ratio)
	_check(cap_count >= 2 and cold_count == cap_count and darkest_ratio > 0.0 and brightest_ratio <= 0.75,
		"%s cold cap pigment is darker than main on all %d released pieces (%.3f to %.3f of main)" %
		[faction, cap_count, darkest_ratio, brightest_ratio])
	_check(cap_count >= 2 and soot_count == (cap_count if is_barge else 0),
		"%s uses the expected cold cap finish (%d of %d active caps with matte soot)" %
		["C19_51" if is_barge else "Eclipse", soot_count, cap_count])
	_end()


func _run() -> void:
	_check_split_vent()
	_check_bay()
	for faction in ["chorus", "hegemony", "deathless"]:
		_check_hulk(faction)
		_check_wing(faction)
	_check_api()
	for faction in MAIN_CAP:
		await _check_cap(faction)
	FX.clear_static()
	print("FACTION_FX_2248 failures=", failures)
	quit(1 if failures else 0)
