extends "res://fx/test/vent_look_probe.gd"
# Issue 209 round 7, step 5: one battle capture of a recipe ship firing its broadside guns at a target, so the guns and the
# gun smoke are judged together. It reuses the issue 281 gas probe (the real battle pieces, a fixed effect clock, raw frames
# and stills) and changes only who stands where and what fires. No effect code is touched.
#
# It also measures where the smoke starts: every weapon hard point of the fired slot (hp_w<slot>_*, the barrel muzzles the
# ship recipe wrote) against the points the effects fire from today (fx_hull's side mounts, found by a ray on the hull box:
# outside audit pass 1, finding 6). One [fire] line per muzzle with the distance to the nearest effect mount.
#
# Run (Ryan's PC; needs godot/gen with the ship built from its recipe export):
#   godot --path godot --fixed-fps 60 --resolution 960x540 --script res://fx/test/ship_fire_probe.gd
# Env: everything vent_look_probe.gd reads (VENT_OUT, VENT_ONLY=after, VENT_RANGE, VENT_W, VENT_H, VENT_FPS), plus
#      FIRE_FAC (corsair), FIRE_CLS (Cruiser), FIRE_KIND (the effect kind, scatter), FIRE_WEAPON (the data.js weapon, scatter),
#      FIRE_SLOT (0: the port battery), FIRE_SHOTS (4), FIRE_TFAC, FIRE_TCLS (the target).
# Prints [fire] lines, the parent's [vent] lines and VENT_DONE.

var side := 1.0     # +1: the target stands off the attacker's port side (ship frame of fx_hull: port is +Z)


func _ship_reset() -> void:
	for id in ["A", "T"]:
		if fx.ships.has(id):
			fx.remove_ship(id)
	for n in world.get_children():
		if n is Node3D and String(n.name).begins_with("ship_"):
			n.queue_free()
	A = _ship("A", _env("FIRE_FAC", "corsair"), _env("FIRE_CLS", "Cruiser"), Vector3(0, 0, 0), 0, false)
	# which world side is the attacker's port: ask the ship itself (a port weapon hard point), so the target is never
	# placed on a guess
	var slot := int(_env("FIRE_SLOT", "0"))
	var hps := A.find_children("hp_w%d_*" % slot, "Node3D", true, false)
	var z := 0.0
	for h in hps:
		z += ((h as Node3D).global_position - A.global_position).z
	side = 1.0 if z >= 0.0 else -1.0
	T = _ship("T", _env("FIRE_TFAC", "hegemony"), _env("FIRE_TCLS", "Destroyer"), Vector3(2, 0, side * 30.0), 3, false)
	_report(slot, hps)


# where the smoke starts today against where the barrels are
func _report(slot: int, hps: Array) -> void:
	var sh = fx.ship("A")
	print("[fire] ship code=%s a4=%s weapon hard points for slot %d: %d" % [str(A.code), str(A.a4), slot, hps.size()])
	if sh == null or hps.is_empty():
		print("[fire] NO_HARD_POINTS the ship in gen/ has no hp_w%d nodes (was it built from the recipe export?)" % slot)
		return
	var tl: Vector3 = sh.xf().affine_inverse() * T.global_position
	var mounts: Array = []
	for m in sh.hull.mounts_for(tl, 4):
		mounts.append(sh.to_world(m["p"]))
	var worst := 0.0
	var sum := 0.0
	for h in hps:
		var p: Vector3 = (h as Node3D).global_position
		var best := 1e9
		for m in mounts:
			best = minf(best, p.distance_to(m))
		worst = maxf(worst, best)
		sum += best
		print("[fire] %s muzzle at %s, nearest effect mount %.2f world units away (%.3f ship lengths)" % [h.name, str(p.snapped(Vector3(0.01, 0.01, 0.01))), best, best / maxf(float(sh.hull.L), 0.001)])
	print("[fire] SMOKE_OFFSET mean %.2f worst %.2f world units; ship length %.2f; effect mounts %s" % [sum / hps.size(), worst, float(sh.hull.L), str(mounts)])


func _pass(label: String, range_name: String) -> void:
	cur_label = label
	cur_range = range_name
	rec_dir = out.path_join("raw_%s_%s" % [label, range_name])
	DirAccess.make_dir_recursive_absolute(rec_dir)
	frame_i = 0
	step_i = 0
	stills = []
	var kind := _env("FIRE_KIND", "scatter")
	var shots: Array = []
	for i in int(_env("FIRE_SHOTS", "4")):
		shots.append(true)
	var meta := {"label": label, "look": fx.vent_look, "range": range_name, "w": W, "h": H, "fps": fps, "frames": 0, "kind": kind}
	# two broadsides, a beat apart, so the clip shows the smoke of the first hanging while the second fires
	var t0: float = fx.now + 0.25
	rec_on = true
	for n in 2:
		_reseed(11 + n)
		await _wait_capture(t0)
		var r: Dictionary = fx.volley("A", kind, "T", {"weapon_id": _env("FIRE_WEAPON", "scatter"), "shots": shots, "hits": _hits(shots.size())})
		var m0: float = t0 + float(r["impacts"][0])
		_still_at(t0 + 0.10, "fire%d_flash" % n)
		_still_at(t0 + 0.36, "fire%d_smoke" % n)
		_still_at(m0 + 0.09, "fire%d_hit" % n)
		await _wait_capture(t0 + 1.6)
		t0 = fx.now + 0.3
	rec_on = false
	meta["frames"] = frame_i
	var mf := FileAccess.open(rec_dir.path_join("clip.json"), FileAccess.WRITE)
	mf.store_string(JSON.stringify(meta, "  ") + "\n")
	mf.close()
	print("[vent] %s %s frames=%d" % [label, range_name, frame_i])


# battle distance: both ships; the camera sits off the attacker's bow quarter on the firing side, as the concept is drawn
func _battle() -> void:
	cam.a = -PI / 2.0 + side * 0.9
	cam.b = 0.98
	cam.r = 62.0
	cam.t = Vector3(1, 0, side * 13.0)
	cam.snap()


func _close_cam() -> void:
	cam.a = -PI / 2.0 + side * 0.9
	cam.b = 1.08
	cam.r = 22.0
	cam.t = A.global_position + Vector3(2.0, 0.5, side * 3.0)
	cam.snap()


func _crop_cam(kind: String) -> void:
	cam.a = -PI / 2.0 + side * 0.9
	cam.b = 1.12
	if kind.ends_with("_hit"):
		cam.t = T.global_position + Vector3(0, 1.0, -side * 4.0)
		cam.r = 14.0
	else:
		cam.t = A.global_position + Vector3(2.5, 0.3, side * 2.5)
		cam.r = 11.0
	cam.snap()
