extends SceneTree
# Issue 2048 item 2: small hull deaths replace the round white bow vent puff with a layered directional rupture jet
# rooted on the hull plating, faction-coloured from faction_looks.json, respecting R186 (flame <= 0.70 s, core <= 0.25 s),
# R193 (flash counter & reduce flashing), Glasswright zero-smoke crystal look, Eclipse violet-only, and R398 acid melt.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const DEATH := preload("res://fx/fx_death.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "small_death_vent_2048_check")
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)
	else:
		print("  ok: " + msg)


func _ship(world: Node3D, fx, sid: String, faction: String, cls: String):
	var body := Node3D.new()
	body.name = sid
	world.add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12.0, 2.8, 4.0)
	bm.subdivide_width = 9
	bm.subdivide_height = 2
	bm.subdivide_depth = 3
	mi.mesh = bm
	body.add_child(mi)
	fx.add_ship(sid, body, {"faction": faction, "cls": cls, "size": 0.55, "meshes": [mi], "shielded": false})
	return fx.ship(sid)


func _advance(fx, secs: float) -> void:
	var target: float = fx.now + secs
	while fx.now < target:
		fx.step(1.0 / 60.0)
		await process_frame


func _run() -> void:
	# 1. Shader check: SH.SPRITE keeps main kinds 30..39 intact and implements VENT_JET (kind 40) directional hull-rupture vent jet.
	_check(SH.VENT_JET == 40, "SH.VENT_JET uses free sprite kind 40 (clear of main kinds 30..39)")
	_check(SH.TICK_EMBER == 38 and SH.TICK_DROPLET == 39, "SH.TICK_EMBER (38) and SH.TICK_DROPLET (39) remain intact")
	_check(SH.SPRITE.contains("else if (k == 40)"), "SH.SPRITE implements kind 40 directional vent jet")
	_check(SH.SPRITE.contains("else if (k >= 30 && k <= 32)"), "SH.SPRITE keeps main bolt_sprite route for kinds 30..32")
	_check(SH.SPRITE.contains("if (k != 40 && r > 1.0) { discard; }"), "kind 40 is not clipped by circular r > 1.0 disc")
	_check(SH.SPRITE.contains("q = dx * (VERTEX.x + 0.45) * 2.3 + dy * VERTEX.y * 0.50;"), "kind 40 roots on breach and stretches outward")

	# 2. Kill small hulls across factions in normal and reduce-flashing modes.
	var factions := ["voidsworn", "hegemony", "corsair", "ithar", "deathless"]
	for calm in [false, true]:
		for fac in factions:
			var world := Node3D.new()
			root.add_child(world)
			var cam := Camera3D.new()
			cam.fov = 45.0
			world.add_child(cam)
			cam.look_at_from_position(Vector3(0, 120, 120), Vector3.ZERO)
			cam.current = true
			var fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"quality": "high", "reduce_flashing": calm, "shake": 0.0})
			fx.check_radius = true
			fx.flash_area_logging = true
			var s = _ship(world, fx, "fr_" + fac, fac, "Frigate")
			DEATH.precompute(fx, s)
			await _advance(fx, 0.35)
			var flashes_before: int = fx.flash_log.size()
			var req_before: int = fx.flash_area_log.size()
			fx.death("fr_" + fac, "blast")
			await _advance(fx, 0.25)
			var baked_vents := 0
			for child in fx.get_children():
				if child is MeshInstance3D and str(child.get_meta("fx_picture_kind", "")) == "vent":
					baked_vents += 1
			_check(baked_vents == 0, "%s (calm=%s): no legacy round white fx_baked_vent spawned" % [fac, str(calm)])
			_check(str(s.get_meta("death_vent_style", "")) == "directional_jet", "%s (calm=%s): directional_jet vent played" % [fac, str(calm)])
			_check(fx.stray_spawns().is_empty(), "%s (calm=%s): vent rooted on plating with zero stray spawns" % [fac, str(calm)])
			if calm:
				_check(fx.flash_log.size() == flashes_before, "%s (calm): zero counted flashes on vent" % fac)
			else:
				_check(fx.flash_area_log.size() - req_before == 1, "%s (normal): exactly one vent flash booking before split" % fac)
			if fac == "deathless":
				var dc: Color = DEATH.dcol(s, "fire_mid", s.fac.damage_glow)
				_check(dc.b > dc.r and dc.r > dc.g, "Eclipse small death vent uses violet (no orange or green)")
			if fac == "ithar":
				_check(DEATH.dsmoke(s) <= 0.01, "Glasswright small death vent stays zero-smoke")
			fx.release()
			world.queue_free()
			await process_frame

	# 3. Acid melt kill skips the vent completely (R398).
	var world_m := Node3D.new()
	root.add_child(world_m)
	var fx_m = FX.new()
	world_m.add_child(fx_m)
	fx_m.manual = true
	fx_m.setup({"quality": "high", "shake": 0.0})
	var sm = _ship(world_m, fx_m, "melt_fr", "voidsworn", "Frigate")
	DEATH.precompute(fx_m, sm)
	await _advance(fx_m, 0.35)
	fx_m.death("melt_fr", "melt")
	await _advance(fx_m, 0.25)
	_check(not sm.has_meta("death_vent_style"), "R398 acid melt small hull skips bow vent")
	fx_m.release()
	world_m.queue_free()
	await process_frame
	FX.clear_static()
	print("small_death_vent_2048_check: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
