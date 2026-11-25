extends SceneTree
# Issue 2035 (AAA item 9): verifies multi-height drifting nebula and ion storm layers,
# organic non-hexagonal footprint masks, faction-neutral colours, and dynamic combat-flash
# illumination (with WCAG reduce-flashing attenuation and distant-flash culling).

const GUARD := preload("res://tools/ci/check_guard.gd")
const WORLD := preload("res://world/world.gd")
const LIVING := preload("res://world/world_living.gd")
const ION := preload("res://world/ion_storm.gd")
const FX := preload("res://fx/fx.gd")
const API := preload("res://rules/battle_api.gd")
const BL := preload("res://world/board_look.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "gas_depth_light_check")
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", msg)


func _build_fixture(quality: String, fac: String, with_fx: bool) -> Dictionary:
	var api := API.new()
	_check(api.load_rules() == "", "rules load")
	api.new_battle_scenario({"seed": 4103, "sector": 1, "admiral": "vex", "fleet": ["warden"], "fac": fac,
		"obj": "rout", "shape": "open", "map": "storm", "dep": "line", "kind": "battle"}, 4103)
	var terrain: Dictionary = api.R.B["terrain"]
	terrain.clear()
	# Separate nebula patch on the left (-6,0..-4,0) and ion storm patch on the right (4,0..6,0)
	for q in range(-6, -3):
		terrain["%d,0" % q] = "neb"
	for q in range(4, 7):
		terrain["%d,0" % q] = "storm"
	var host := Node3D.new()
	root.add_child(host)
	var fx: Node3D = null
	if with_fx:
		fx = FX.new()
		host.add_child(fx)
		fx.manual = true
		fx.setup({"quality": quality, "reduce_flashing": false, "shake": 0.0, "unit": 1.0, "seed": 2035})
	var world = WORLD.new()
	host.add_child(world)
	var hw := func(q: int, r: int, _y := 0.0) -> Vector3:
		return Vector3(q * 17.320508 + r * 8.660254, 0.0, r * 15.0)
	var opts := {"hex_world": hw, "quality": quality, "seed": 4103, "fac": fac}
	if fx != null:
		opts["fx"] = fx
	BL.set_look("cine", false)
	world.build(api.view(), opts)
	world.set_look()
	return {"host": host, "world": world, "living": world._living, "fx": fx, "hw": hw}


func _check_layers(living, quality: String) -> void:
	for is_storm in [false, true]:
		var node_name := "Storm" if is_storm else "Nebula"
		var mmis: Array = living.find_children(node_name, "MultiMeshInstance3D", false, false)
		_check(not mmis.is_empty(), "%s/%s: MultiMeshInstance3D exists" % [quality, node_name])
		var matching: Array = []
		for patch in living._gas_patches:
			if bool(patch.storm) == is_storm:
				matching.append(patch)
		_check(not matching.is_empty(), "%s/%s: gas patch record exists" % [quality, node_name])
		if matching.is_empty():
			continue
		var bands := {}
		var min_y := INF
		var max_y := -INF
		for patch in matching:
			for b in patch.bands:
				bands[b] = int(bands.get(b, 0)) + int(patch.bands[b])
			min_y = minf(min_y, float(patch.y_min))
			max_y = maxf(max_y, float(patch.y_max))
			var mat: ShaderMaterial = patch.mat
			var code := mat.shader.code
			_check(not code.contains("%NOISE%") and not code.contains("%CARD_SUPPORT%") and not code.contains("%COMBAT_LIGHTS%"),
				"%s/%s: all shader placeholders substituted" % [quality, node_name])
			_check(code.contains("combat_scatter(") and code.contains("gas_layer_style(") and code.contains("gas_cloud3("),
				"%s/%s: upgraded multi-layer smooth shader with combat scatter active" % [quality, node_name])
			_check(code.contains("gas_rot0(") and code.contains("gas_oct_step("),
				"%s/%s: rotated multi-octave noise active (no axis-aligned square tiles)" % [quality, node_name])
			_check(code.contains("span * 0.44") and code.contains("near_cam = smoothstep("),
				"%s/%s: smooth vertical bell rolloff and near-camera lens fade active" % [quality, node_name])
			if not is_storm:
				_check(not code.contains("flashes["), "%s/Nebula: calm gas has no storm lightning array" % quality)
			if quality == "max":
				_check(patch.fog_mat != null, "%s/%s: Max patch has FogVolume material" % [quality, node_name])
				if patch.fog_mat != null:
					var fcode: String = (patch.fog_mat as ShaderMaterial).shader.code
					_check(not fcode.contains("%COMBAT_LIGHTS%") and fcode.contains("combat_scatter("),
						"%s/%s: fog shader carries combat scatter" % [quality, node_name])
		if quality == "max":
			var mm_cards := 0
			for mmi in mmis:
				mm_cards += (mmi as MultiMeshInstance3D).multimesh.instance_count
			_check(mm_cards <= 7, "%s/%s: Max card count stays lean (got %d for 3 hexes)" % [quality, node_name, mm_cards])
			var fog_name := "StormFog368" if is_storm else "NebulaFog368"
			var fogs: Array = living.find_children(fog_name, "FogVolume", false, false)
			_check(not fogs.is_empty() and (fogs[0] as FogVolume).size.x >= LIVING.GAS_FIELD_REACH * 2.0,
				"%s/%s: FogVolume margin covers full warped field" % [quality, node_name])
		if quality == "max" or quality == "high":
			for b in [0, 1, 2, 3]:
				_check(int(bands.get(b, 0)) > 0, "%s/%s: height band %d populated (got %s)" % [quality, node_name, b, str(bands)])
			_check(min_y < 1.5 and max_y > 16.0, "%s/%s: strata span below and above ships (y=%.1f..%.1f)" % [quality, node_name, min_y, max_y])
		else:
			_check(int(bands.get(1, 0)) > 0 and int(bands.get(2, 0)) > 0, "%s/%s: low tier keeps body and upper wisps" % [quality, node_name])


func _check_organic_mask() -> void:
	var gas := LIVING.new()
	gas.gas_route = "fog"
	var mk: Array = gas._mask([Vector3.ZERO], 2.0)
	var box: Vector4 = mk[1]
	var img: Image = mk[2]
	# Sample at equal radius r=30 along hex-edge normal (0 deg) and hex-corner direction (30 deg).
	# The old hex SDF gave visibly different values; circular Euclidean base is isotropic before shader warp.
	var r := 30.0
	var p_edge := Vector2(r, 0.0)
	var p_corner := Vector2(r * cos(PI / 6.0), r * sin(PI / 6.0))
	var g_edge := _sample_g(img, box, p_edge)
	var g_corner := _sample_g(img, box, p_corner)
	_check(g_edge > 0.1 and absf(g_edge - g_corner) < 0.03,
		"organic mask base is isotropic (edge=%.4f corner=%.4f)" % [g_edge, g_corner])
	_check(LIVING.GAS_SHADER.contains("foot_at(vW.xz + wv"), "nebula card shader warps footprint mask")
	_check(LIVING.FOG_SHADER.contains("WORLD_POSITION.xz + wv"), "nebula fog shader warps footprint mask")
	_check(ION.CARDS.contains("storm_foot(world.xz + wv)"), "storm card shader warps footprint mask")
	_check(ION.FOG.contains("WORLD_POSITION.xz + wv"), "storm fog shader warps footprint mask")
	gas.free()


func _sample_g(img: Image, box: Vector4, p: Vector2) -> float:
	var fx := (p.x - box.x) * box.z * float(img.get_width()) - 0.5
	var fz := (p.y - box.y) * box.w * float(img.get_height()) - 0.5
	var x0 := clampi(int(floor(fx)), 0, img.get_width() - 2)
	var z0 := clampi(int(floor(fz)), 0, img.get_height() - 2)
	var tx := clampf(fx - float(x0), 0.0, 1.0)
	var tz := clampf(fz - float(z0), 0.0, 1.0)
	var a := lerpf(img.get_pixel(x0, z0).g, img.get_pixel(x0 + 1, z0).g, tx)
	var b := lerpf(img.get_pixel(x0, z0 + 1).g, img.get_pixel(x0 + 1, z0 + 1).g, tx)
	return lerpf(a, b, tz)


func _check_faction_neutral() -> void:
	var a := _build_fixture("max", "voidsworn", false)
	var b := _build_fixture("max", "chorus", false)
	var pa: Dictionary = a.living._gas_patches[0]
	var pb: Dictionary = b.living._gas_patches[0]
	for key in ["c_dark", "c_shadow", "c_lit", "c_glow"]:
		_check(pa.mat.get_shader_parameter(key) == pb.mat.get_shader_parameter(key),
			"nebula colour %s stays faction-neutral across voidsworn and chorus" % key)
		_check(pa.fog_mat.get_shader_parameter(key) == pb.fog_mat.get_shader_parameter(key),
			"nebula fog colour %s stays faction-neutral across voidsworn and chorus" % key)
	a.host.free()
	b.host.free()


func _check_combat_lights() -> void:
	var f := _build_fixture("max", "corsair", true)
	var living = f.living
	var fx = f.fx
	var hw: Callable = f.hw
	var neb_patch: Dictionary = {}
	var storm_patch: Dictionary = {}
	for p in living._gas_patches:
		if p.storm:
			storm_patch = p
		else:
			neb_patch = p
	_check(not neb_patch.is_empty() and not storm_patch.is_empty(), "both nebula and storm patches tracked")
	_check(neb_patch.fog_mat != null and storm_patch.fog_mat != null, "Max patches track both card and fog materials")
	if neb_patch.is_empty() or storm_patch.is_empty():
		f.host.free()
		return
	# 1. Idle frame: zero combat lights everywhere.
	fx.step(0.016)
	living._process(0.016)
	_check(int(neb_patch.mat.get_shader_parameter("combat_light_count")) == 0, "idle nebula cards have 0 combat lights")
	_check(int(neb_patch.fog_mat.get_shader_parameter("combat_light_count")) == 0, "idle nebula fog has 0 combat lights")
	_check(int(storm_patch.mat.get_shader_parameter("combat_light_count")) == 0, "idle storm cards have 0 combat lights")
	_check(int(storm_patch.fog_mat.get_shader_parameter("combat_light_count")) == 0, "idle storm fog has 0 combat lights")

	# 2. Far flash (far off board): culled from both patches.
	fx.light(Vector3(600.0, 0.0, 600.0), fx.now, 0.3, 7.0, Color(1.0, 0.5, 0.2), 0)
	fx.step(0.02)
	living._process(0.02)
	_check(int(neb_patch.mat.get_shader_parameter("combat_light_count")) == 0, "distant flash does not wake nebula patch")
	_check(int(storm_patch.mat.get_shader_parameter("combat_light_count")) == 0, "distant flash does not wake storm patch")

	# 3. Weapon flash inside nebula patch: lights nebula cards & fog, stays out of distant storm patch.
	var neb_pos: Vector3 = hw.call(-5, 0) + Vector3(0.0, 1.5, 0.0)
	fx.light(neb_pos, fx.now, 0.35, 7.5, Color(0.35, 0.80, 1.0), 0, 32.0)
	fx.step(0.02)
	living._process(0.02)
	_check(int(neb_patch.mat.get_shader_parameter("combat_light_count")) == 1, "nebula cards receive weapon flash")
	_check(int(neb_patch.fog_mat.get_shader_parameter("combat_light_count")) == 1, "nebula fog receives weapon flash")
	_check(int(storm_patch.mat.get_shader_parameter("combat_light_count")) == 0, "nebula flash does not leak to far storm patch")
	var neb_cols: PackedVector4Array = neb_patch.mat.get_shader_parameter("combat_col")
	var std_intensity := neb_cols[0].w
	_check(std_intensity > 0.1 and std_intensity <= 0.80, "weapon flash scatter intensity bounded (%.3f)" % std_intensity)

	# 4. Reduce flashing lowers scatter intensity cleanly (RULEBOOK 6.2 comfort).
	fx.reduce_flashing = true
	living._process(0.0)
	var calm_cols: PackedVector4Array = neb_patch.mat.get_shader_parameter("combat_col")
	_check(calm_cols[0].w > 0.0 and calm_cols[0].w < std_intensity * 0.65,
		"reduce_flashing lowers combat scatter (std=%.3f calm=%.3f)" % [std_intensity, calm_cols[0].w])
	fx.reduce_flashing = false

	# 5. Explosion flash inside storm patch: lights storm cards & fog with wider reach.
	var storm_pos: Vector3 = hw.call(5, 0) + Vector3(0.0, 2.0, 0.0)
	fx.light(storm_pos, fx.now, 0.45, 9.0, Color(1.0, 0.55, 0.15), 0, 56.0)
	fx.step(0.02)
	living._process(0.02)
	_check(int(storm_patch.mat.get_shader_parameter("combat_light_count")) == 1, "storm cards receive explosion flash")
	_check(int(storm_patch.fog_mat.get_shader_parameter("combat_light_count")) == 1, "storm fog receives explosion flash")
	var storm_pos_u: PackedVector4Array = storm_patch.mat.get_shader_parameter("combat_pos")
	var neb_pos_u: PackedVector4Array = neb_patch.mat.get_shader_parameter("combat_pos")
	_check(storm_pos_u[0].w > 0.0 and storm_pos_u[0].w < neb_pos_u[0].w,
		"explosion flash uses wider scatter radius than standard gunfire (inv_r2 %.5f < %.5f)" % [storm_pos_u[0].w, neb_pos_u[0].w])

	# 6. Expiry clears combat lights cleanly back to 0.
	fx.step(0.65)
	living._process(0.65)
	_check(int(neb_patch.mat.get_shader_parameter("combat_light_count")) == 0, "expired flash clears nebula cards")
	_check(int(neb_patch.fog_mat.get_shader_parameter("combat_light_count")) == 0, "expired flash clears nebula fog")
	_check(int(storm_patch.mat.get_shader_parameter("combat_light_count")) == 0, "expired flash clears storm cards")
	_check(int(storm_patch.fog_mat.get_shader_parameter("combat_light_count")) == 0, "expired flash clears storm fog")
	f.host.free()


func _run() -> void:
	OS.set_environment("VS_NEBULA_ROUTE", "fog")
	for quality in ["max", "high", "low"]:
		var f := _build_fixture(quality, "corsair", false)
		_check_layers(f.living, quality)
		f.host.free()
	_check_organic_mask()
	_check_faction_neutral()
	_check_combat_lights()
	print("gas_depth_light_check: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
