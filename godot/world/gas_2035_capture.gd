extends "res://world/nebula_capture.gd"
# Issue 2035 (AAA item 9): before/after PC capture rows of a nebula hex and an ion storm hex
# with real built ships inside at cameras 170 and 26, calm and during a weapon flash + explosion
# passing through. Designed to run cleanly on both main (before) and neon/issue-2035 (after).

const SHOT_CAMS := [170.0, 26.0]


func _capture_routes() -> void:
	if not await _build("base", 4207) or PG.stop_if_any():
		return
	volleys_on = false
	b.hud.visible = false
	b.set_process(false)
	b.gfx.manual = true
	b.cam.screen_shift = 0.0
	var kind := "neb" if map_case == "nebula" else "storm"
	var living = b.world._living
	b.world.set_process(false)
	living.set_process(false)
	living.clock = 1.4
	for i in living.bolts.size():
		living.bolts[i]["next"] = 1000.0
		living.bolts[i]["start"] = 1.32 if (map_case == "storm" and i == 0) else -10.0
	living._process(0.0)

	var patches: Array = living._patches(b.world._terr_pts[kind])
	patches.sort_custom(func(a, z): return a.size() > z.size())
	var patch: Array = patches[0]
	var center := Vector3.ZERO
	for p in patch:
		center += p
	center /= float(patch.size())
	_capture_center = center
	# Pick two real ships inside the patch (a Cruiser at center, a Frigate one hex off-center).
	var cruiser = null
	var escort = null
	for view in _views():
		view.set_process(false)
		var cls := str(view.u.cls)
		if cls == "Cruiser" and cruiser == null:
			cruiser = view
		elif cls == "Frigate" and escort == null:
			escort = view
	if cruiser == null:
		cruiser = _views()[0]
	for view in _views():
		view.visible = (view == cruiser or view == escort)
	cruiser.position = center
	var escort_pos := center + Vector3(17.32, 0.0, -7.5)
	if patch.size() > 1:
		for p in patch:
			if (p as Vector3).distance_to(center) > 10.0:
				escort_pos = p
				break
	if escort != null:
		escort.position = escort_pos

	var shots: Array = []
	for radius in SHOT_CAMS:
		# 1. Calm state (on storm, one ambient lightning bolt stays visible to verify PR 1986 lightning is untouched).
		_clear_combat_fx()
		living._process(0.0)
		var calm_name := "gas2035_%s_c%d_calm.png" % [map_case, int(radius)]
		await _snap_at(center, radius, calm_name)
		shots.append(calm_name)

		# 2. Weapon flash + explosion passing through the cloud beside the ships.
		_trigger_combat_fx(center, escort_pos, map_case == "storm")
		living._process(0.0)
		var flash_name := "gas2035_%s_c%d_flash.png" % [map_case, int(radius)]
		await _snap_at(center, radius, flash_name)
		shots.append(flash_name)

	_clear_combat_fx()
	var meta := {
		"issue": 2035,
		"map_case": map_case,
		"route": route,
		"cameras": SHOT_CAMS,
		"center": [center.x, center.y, center.z],
		"ships": [
			{"cls": str(cruiser.u.cls), "code": str(cruiser.code)},
			{"cls": str(escort.u.cls), "code": str(escort.code)} if escort != null else null,
		],
		"shots": shots,
	}
	var f := FileAccess.open(out.path_join("capture_2035_%s.json" % map_case), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(meta, "  ") + "\n")
		f.close()
	b.queue_free()
	b = null


func _snap_at(center: Vector3, radius: float, filename: String) -> void:
	b.set_process(false)
	b.cam.set_process(false)
	b.cam.t = center
	b.cam.r = radius
	b.cam.a = -PI / 2.0
	b.cam.b = 0.98
	b.cam.screen_shift = 0.0
	b.cam.snap()
	if route == "fog":
		b.env.volumetric_fog_length = maxf(250.0, radius + 200.0)
	for frame in 30:
		b.cam.snap()
		await get_tree().process_frame
	await super._shot(filename)


func _clear_combat_fx() -> void:
	b.gfx._lev.clear()
	b.gfx.step(0.016)
	if b.world._living != null and b.world._living.has_method("set_combat_lights"):
		b.world._living.set_combat_lights([])


func _trigger_combat_fx(center: Vector3, escort_pos: Vector3, is_storm: bool) -> void:
	b.gfx._lev.clear()
	var t0: float = b.gfx.now
	if is_storm:
		# Warm amber/orange macro-torpedo blast + bright muzzle flash inside the cool teal ion storm.
		var blast_pos := center + Vector3(-11.0, 2.0, -5.0)
		var muzzle_pos := escort_pos + Vector3(-4.0, 1.5, 4.0)
		b.gfx.light(blast_pos, t0, 0.55, 9.0, Color(1.0, 0.56, 0.16), 0, 52.0)
		b.gfx.light(muzzle_pos, t0, 0.35, 7.2, Color(1.0, 0.84, 0.42), 0, 34.0)
		b.gfx.pop(blast_pos, t0, Color(1.0, 0.62, 0.22), 7.5, 5.5, Vector3.UP, 0.20, 26.0)
	else:
		# Cool plasma-blue weapon volley + warm golden explosion passing through the rose nebula.
		var plasma_pos := center + Vector3(-10.5, 2.0, -4.5)
		var blast_pos := escort_pos + Vector3(3.0, 1.8, -4.0)
		b.gfx.light(plasma_pos, t0, 0.45, 8.2, Color(0.32, 0.82, 1.0), 0, 42.0)
		b.gfx.light(blast_pos, t0, 0.55, 9.0, Color(1.0, 0.64, 0.24), 0, 52.0)
		b.gfx.pop(plasma_pos, t0, Color(0.45, 0.88, 1.0), 6.2, 5.0, Vector3.UP, 0.20, 22.0)
		b.gfx.pop(blast_pos, t0, Color(1.0, 0.68, 0.28), 7.5, 5.5, Vector3.UP, 0.20, 26.0)
	b.gfx.step(0.03)
