extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const STATUS := preload("res://fx/fx_status_tick.gd")
const SH := preload("res://fx/fx_shaders.gd")
const FACTIONS := {"voidsworn": "assault", "hegemony": "precision", "corsair": "salvage",
	"deathless": "phase", "ithar": "prism", "chorus": "umbilical"}

var fails := 0
var fx: FX
var stage: Node3D


func _init() -> void:
	GUARD.arm(self, "event_layers_2046_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		fails += 1
		printerr("FAIL: ", message)


func _reset(reduced := false) -> void:
	if is_instance_valid(stage):
		stage.free()
	stage = Node3D.new()
	root.add_child(stage)
	fx = FX.new()
	stage.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "shake": 0.0, "reduce_flashing": reduced, "seed": 2046})
	fx.spr_kinds = {}


func _ship(id: String, faction: String, p := Vector3.ZERO):
	var body := Node3D.new()
	stage.add_child(body)
	body.position = p
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 8)
	mi.mesh = box
	body.add_child(mi)
	fx.add_ship(id, body, {"faction": faction, "cls": "Cruiser", "meshes": [mi]})
	return fx.ship(id)


func _rows(tag: String) -> Array[Dictionary]:
	return fx.event_paths.live.filter(func(row: Dictionary) -> bool: return row.tag == tag)


func _statuses() -> void:
	for faction in FACTIONS:
		_reset()
		var ship = _ship("T", faction)
		var sooty: bool = faction not in ["ithar", "chorus"]
		fx.tick("T", "fire")
		var flame := fx.get_node_or_null("fx_tick_flame") as MeshInstance3D
		_check(flame != null, "%s: the fire tick takes a baked picture" % faction)
		if flame != null:
			var m := flame.material_override as ShaderMaterial
			var root_at: Vector3 = ship.xf().affine_inverse() * flame.get_meta("gas_root")
			_check(m.get_shader_parameter("atlas") != null and float(m.get_shader_parameter("lifetime")) <= 0.70
				and absf(root_at.y) <= 2.01 and ship.hull.box.grow(0.05).has_point(root_at),
				"%s: the flame is baked, capped and attached" % faction)
			var tint: Color = m.get_shader_parameter("fac_mid")
			_check(tint == (ship.fac.weapon if faction == "hegemony" else ship.fac.damage_glow),
				"%s: fire takes its faction colour" % faction)
			_check((float(m.get_shader_parameter("fac_smoke")) > 0.0) == sooty,
				"%s: baked plume keeps only its allowed soot" % faction)
			_check(float(m.get_shader_parameter("fac_prism")) == (1.0 if faction == "ithar" else 0.0),
				"%s: only the Glasswright plume has a prismatic edge" % faction)
		_check(fx.spr_kinds.has(8) == sooty and fx.spr_kinds.has(SH.TICK_EMBER) and not fx._lev.is_empty(),
			"%s: the plume has faction-appropriate smoke, colour-locked embers and light" % faction)

	_reset()
	var ship = _ship("T", "deathless")
	ship.set_meta("acid_spots", [[Vector3(0, 2, 0), 0.0, Vector3.UP]])
	var rings: int = fx.pools.rng.emitted
	fx.tick("T", "acid")
	_check(fx.spr_kinds.has(SH.TICK_DROPLET) and fx.spr_kinds.has(20) and fx.pools.rng.emitted > rings,
		"acid has wet droplets, vapour and a separate plating etch")
	_check(ship._acid_mist == null and not ship._acid_active
		and fx._lev.back()[0].is_equal_approx(Vector3(0, 2.0 + 0.9 * ship.scale_k(), 0)),
		"acid uses recorded plating without waking the persistent mist")
	_check(fx._lev.back()[4] == ship.fac.damage_glow, "Eclipse acid keeps its violet tint")

	_reset()
	ship = _ship("T", "chorus")
	fx.well = Vector3(60, -4, 30)
	fx.tick("T", "tidal")
	var streams := _rows("tidal_stream")
	_check(streams.size() == 3 and fx.spr_kinds.has(SH.TICK_EMBER) and fx.pools.rng.emitted == 1
		and fx.pools.stk.emitted == 0, "tidal has three streams, rim stress and biological motes on Chorus")
	for row in streams:
		var points: PackedVector3Array = row.path
		_check(points[-1].distance_to(fx.well) < points[0].distance_to(fx.well) and points[0].x > 0.0,
			"tidal stream pulls from the well-facing plating toward the actual well")
	fx.step(0.90)
	_check(fx.event_paths.live.is_empty(), "the tidal stream clears on the effect clock")


func _storm() -> void:
	for spec in [["hegemony", 30.0, 60.0], ["hegemony", null, null], ["hegemony", 0.0, 60.0],
		["deathless", 0.0, 0.0], ["chorus", 0.0, 0.0]]:
		var unsynced: bool = spec[1] == null
		var live_shield: bool = unsynced or float(spec[1]) > 0.0
		_reset(not live_shield)
		var ship = _ship("T", spec[0])
		if not unsynced:
			fx.sync_ship("T", {"shp": spec[1], "shMax": spec[2], "sh": [0, 0, 0, 0]})
		else:
			_check(ship.shielded and ship._shield_fraction < 0.0, "unsynced fixture has a shield but no pool snapshot")
		fx.tick("T", "storm")
		var arcs := _rows("storm_arc")
		_check(arcs.size() == 1 and _rows("storm_fork").size() == 2 and fx.spr_kinds.has(18),
			"%s at %s: arc, two forks and soft contact" % [spec[0], "unsynced" if unsynced else str(spec[1])])
		if not arcs.is_empty():
			var row: Dictionary = arcs[0]
			var pts: PackedVector3Array = row.path
			_check(pts[0].y >= 12.0 and pts[-1].y < 6.0 and pts[0].distance_to(pts[-1]) > 7.0,
				"the bolt spans the upper cloud bank to the ship")
			if not live_shield:
				_check(ship.hull.box.grow(0.05).has_point(ship.xf().affine_inverse() * pts[-1]),
					"zero shield reaches true plating")
			else:
				_check(pts[-1].distance_to(ship.shield_point(pts[0]).p) < 0.01 and ship._shield_until > fx.now,
					"live shield catches the arc and ripples, even before pool sync")
			fx.step(0.08)
			_check(row.node.visible and fx._flashes.is_empty(), "arc is live and doesn't book an extra flash")
		fx.step(STATUS.STORM_LIFE)
		_check(fx.event_paths.live.is_empty(), "cloud-to-ship arc and forks expire")
		if not live_shield and ship._shield_mi != null:
			_check(ship._shield_until <= 0.0 and not ship._shield_mi.visible, "zero pool never brings the shield back")


func _boarding() -> void:
	for faction in FACTIONS:
		_reset()
		var attacker = _ship("A", faction, Vector3(-8, 0, 20))
		var target = _ship("T", "hegemony")
		var pace := 0.55 if faction == "corsair" else 1.0
		var hold := fx.board_hold_ms() / 1000.0 * pace
		fx.board("A", "T", "", pace)
		var look: String = FACTIONS[faction]
		var ways := _rows("board_" + look)
		var cuts := _rows("board_cutter")
		_check(ways.size() == (2 if faction in ["deathless", "chorus"] else 3) and cuts.size() == 1,
			"%s boards with its own crossing and local cutter" % faction)
		if ways.is_empty() or cuts.is_empty():
			continue
		var row := ways[0]
		var mat := row.node.material_override as ShaderMaterial
		var tint: Color = mat.get_shader_parameter("tint")
		var pods: bool = faction in ["voidsworn", "hegemony", "corsair"]
		_check(is_instance_valid(row.pod) == pods, "%s has the right boarding carrier" % faction)
		_check(row.start == 0.0 and row.end == hold and cuts[0].start > row.start,
			"the cutter starts after launch and the crossing ends on the paced hold")
		_check((cuts[0].node.material_override as ShaderMaterial).get_shader_parameter("tint") == tint,
			"the boarding party and cut use one palette")
		if faction == "deathless":
			_check(tint.b > tint.r and tint.r > tint.g and fx.pools.stk.emitted == 0,
				"Eclipse boarding uses violet without warm target sparks")
		if faction == "ithar":
			_check(tint.b > 0.9 and tint.r > 0.9 and float(mat.get_shader_parameter("pattern")) == 2.0,
				"Glasswright phase lock keeps a pale core and a prismatic sleeve")
		if faction == "chorus":
			_check(fx.pools.stk.emitted == 0 and fx.spr_kinds.has(20), "Chorus boards without any metal sparks")
		var old_end: Vector3 = row.last.call()
		attacker.root.position += Vector3(1, 0, 0)
		target.root.position += Vector3(0, 0, -2)
		fx.step(hold * 0.30)
		_check(row.last.call().is_equal_approx(old_end + Vector3(0, 0, -2)) and mat.get_shader_parameter("first_shift") == Vector3.RIGHT,
			"crossing follows both hull attachments")
		if pods:
			var at_launch: Vector3 = row.pod.position
			fx.step(hold * 0.23)
			_check(row.pod.visible and row.pod.position.distance_to(at_launch) > 1.0, "the pod visibly crosses the gap")
		fx.step(hold)
		_check(_rows("board_" + look).is_empty(), "the crossing is gone once the battle can resume")
		fx.release()
		_check(fx.event_paths.live.is_empty(), "release clears all outstanding event paths")


func _run() -> void:
	_check(SH.TICK_EMBER == 38 and SH.TICK_DROPLET == 39, "status sprites use the shared 38 and 39 slots")
	_statuses()
	_storm()
	_boarding()
	stage.free()
	print("event_layers_2046_check: %d failures" % fails)
	quit(1 if fails else 0)
