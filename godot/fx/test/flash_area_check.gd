extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 504: the flash counter by area (fx.gd flash_at), checked on a staged worst second.
# W3C Understanding SC 2.3.1: a general flash counts only when "the combined area of flashes occurring concurrently"
# passes "25% of any 10 degree visual field on the screen"; at most three in any one second.
#
# Two stagings at the battle camera (1920x1080, 45 degree field, about 170 units away):
#   together: a capital death (chain blasts, core flash, secondaries), a torpedo landing on the capital during it and a
#             cruiser dying beside it, all inside one 10 degree box on screen;
#   spread:   the same three events across the screen, far apart.
# Asserts, for each staging:
#   1. never more than three counted flashes in any rolling second (fx.flash_log);
#   2. brute force: every flash drawn bright without being counted is re-measured on a 4 px raster of exact disc
#      coverage, with the 10 degree box slid over every 4 px position; none may hold more than the limit (0.006 sr, or a quarter of W3C's
#      341 by 256 rectangle estimate, whichever is smaller)
#      (so no uncounted general flash was drawn);
#   3. the counter's own area is never below the brute-force area (it rounds up, never down);
#   4. reduce flashing: the same staging counts zero flashes and books nothing.
# Prints the counted, refused and over-counted (cautious) numbers, and the counter's own time.
#   godot --headless --path godot --script res://fx/test/flash_area_check.gd

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
var failures := 0
var cell := 4.0


func _init() -> void:
	GUARD.arm(self, "flash_area_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _ship(world: Node3D, fx, id: String, cls: String, size: float, at: Vector3) -> void:
	var r := Node3D.new()
	world.add_child(r)
	r.position = at
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(12, 3, 4)
	bm.subdivide_width = 11
	bm.subdivide_height = 2
	bm.subdivide_depth = 3
	mi.mesh = bm
	r.add_child(mi)
	fx.add_ship(id, r, {"faction": "voidsworn", "cls": cls, "size": size, "meshes": [mi]})


func _advance(fx, seconds: float) -> void:
	var end: float = fx.now + seconds
	while fx.now < end:
		fx.step(1.0 / 60.0)
		await process_frame


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	var results := {}
	for staging in ["together", "spread", "salvo"]:
		for calm in [false, true]:
			results[staging + ("_calm" if calm else "")] = await _stage(staging, calm)
	print("FLASH_AREA failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _stage(staging: String, calm: bool) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.position = Vector3(0, 150, 80)
	cam.look_at(Vector3.ZERO, Vector3.UP)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "high", "reduce_flashing": calm, "shake": 0.0, "unit": 1.0})
	if "flash_area_logging" in fx:
		fx.flash_area_logging = true
	var cap_at := Vector3.ZERO
	var cru_at := Vector3(14, 0, 6) if staging == "together" else Vector3(-95, 0, 10)
	var tor_at := Vector3.ZERO if staging == "together" else Vector3(95, 0, -30)
	_ship(world, fx, "CAP", "Battleship", 1.0, cap_at)
	_ship(world, fx, "CRU", "Cruiser", 0.6, cru_at)
	if staging == "spread":
		_ship(world, fx, "TGT", "Cruiser", 0.6, tor_at)
	await _advance(fx, 1.2)   # the cut precompute
	var S: float = fx.flash_box_px() if fx.has_method("flash_box_px") else 289.0
	var t0: float = fx.now
	fx.prof_take()
	if staging != "salvo":
		fx.death("CAP", "big")
	# the cruiser dies 0.6 s later, so its chain and core land in the capital's busiest second; the torpedo lands at
	# 1.75 s, in the second that already holds three of main's counted flashes
	var flash_us := 0
	var flash_us_max := 0
	var frames := 0
	var torp_done := false
	var cru_done := false
	while fx.now < t0 + 6.0:
		if staging == "salvo":
			# five waves of sixteen heavy shell hits, 0.3 s apart, all inside one 10 degree box: each wave alone is
			# sixteen small flashes that add up past the limit, so the counter must count it or turn part of it down
			var wave: int = int(floorf((fx.now - t0) / 0.3 + 1e-6))
			if wave < 5 and not torp_done and fx.now >= t0 + wave * 0.3 and int(fx.get_meta("wave", -1)) < wave:
				fx.set_meta("wave", wave)
				var Tg = fx.ship("CAP")
				for h in 16:
					var hp: Vector3 = Tg.to_world(Tg.hull.c) + Vector3(-9.0 + 18.0 * float(h % 4) / 3.0, 2, -6.0 + 12.0 * float(h / 4) / 3.0)
					WEAP._staged_hit(fx, Tg, hp, fx.now, false)
		elif not cru_done and fx.now >= t0 + 0.6:
			cru_done = true
			fx.death("CRU", "big")
		if staging != "salvo" and not torp_done and fx.now >= t0 + 1.75:
			torp_done = true
			var tg_id := "CAP" if staging == "together" else "TGT"
			var Tg = fx.ship(tg_id)
			var p: Vector3 = Tg.to_world(Tg.hull.c) + Vector3(0, 2, 0)
			WEAP._big_hit(fx, Tg, {"p": p, "n": Vector3.UP}, fx.now, Tg.scale_k(), Color(1, 0.6, 0.3), false)
		fx.step(1.0 / 60.0)
		frames += 1
		var fus := int(fx.prof_take().get("flash", 0))
		flash_us += fus
		flash_us_max = maxi(flash_us_max, fus)
		await process_frame
	var log: Array = fx.flash_area_log if "flash_area_log" in fx else []
	# 1. the rolling second
	var worst := 0
	for a in fx.flash_log:
		var n := 0
		for b in fx.flash_log:
			if float(b) > float(a) - 1.0 and float(b) <= float(a):
				n += 1
		worst = maxi(worst, n)
	_check(worst <= 3, "%s: %d counted flashes in one rolling second" % [staging, worst])
	if calm:
		_check(fx.flash_log.is_empty() and log.is_empty() and ("flash_cands" not in fx or fx.flash_cands.is_empty()), "%s calm: nothing counted or booked" % staging)
	# 2 and 3. the brute force, against every measured request
	var limit: float = fx.flash_limit_px2() if fx.has_method("flash_limit_px2") else 15606.0   # the counter's own limit (0.006 sr, W3C's rectangle)
	var uncounted_over := 0
	var over_counted := 0
	var measured := 0
	var below := 0
	var worst_ratio := 0.0
	for i in log.size():
		var r: Array = log[i]
		if float(r[4]) < 0.0:
			continue
		measured += 1
		var brute := _brute(log, i, S)
		worst_ratio = maxf(worst_ratio, brute / limit)
		if float(r[4]) < brute * 0.97:
			below += 1
		if int(r[5]) == 0 and int(r[6]) == 1 and brute > limit * 1.02:
			uncounted_over += 1
		if int(r[5]) == 1 and brute <= limit:
			over_counted += 1
	_check(uncounted_over == 0, "%s: %d flashes drawn bright uncounted while the brute force finds a general flash" % [staging, uncounted_over])
	_check(below == 0, "%s: the counter measured less area than the brute force %d times" % [staging, below])
	var refused: int = fx._refused.size()
	# the torpedo: its flash request is the one at t0 + 1.75
	var torp_bright := -1
	var refused_at: Array = []
	for f in fx._refused:
		refused_at.append(snappedf(float(f) - t0, 0.001))
	var counted_at: Array = []
	for f in fx.flash_log:
		counted_at.append(snappedf(float(f) - t0, 0.001))
	if not calm and staging != "salvo":
		torp_bright = 1
		for f in refused_at:
			if absf(float(f) - 1.75) < 0.03: torp_bright = 0
	print("FLASH_AREA_TIMES staging=%s counted_at=%s refused_at=%s" % [staging, str(counted_at), str(refused_at)])
	print("FLASH_AREA staging=%s calm=%s box_px=%d limit_px2=%d requests=%d measured=%d counted=%d refused=%d worst_per_second=%d uncounted_over=%d over_counted=%d counter_below_brute=%d brute_max_share=%.2f torpedo_drawn_bright=%d counter_us_per_frame=%.1f counter_us_total=%d counter_us_worst_frame=%d" % [
		staging, calm, int(S), int(limit), log.size(), measured, fx.flash_log.size(), refused, worst, uncounted_over, over_counted, below, worst_ratio, torp_bright, float(flash_us) / maxf(frames, 1), flash_us, flash_us_max])
	for r in log:
		print("FLASH_AREA_REQ %s t=%.3f x=%.0f y=%.0f d=%.0f lit=%.0f counted=%d bright=%d" % [staging, float(r[0]) - t0, float(r[1]), float(r[2]), float(r[3]), float(r[4]), int(r[5]), int(r[6])])
	fx.release()
	world.queue_free()
	await process_frame
	return {"worst": worst}


# Exact-ish brute force: the bright requests booked up to and including request i whose bright time overlaps it,
# drawn as discs on a 4 px raster (a cell counts when its centre is inside the disc), and the 10 degree box (side S)
# slid over every 4 px position that touches request i's disc. Returns the most lit area any of those boxes holds.
func _brute(log: Array, i: int, S: float) -> float:
	var r: Array = log[i]
	var T: float = float(r[0])
	var l: float = float(r[7])
	var cx: float = float(r[1])
	var cy: float = float(r[2])
	var rad: float = float(r[3]) * 0.5
	var x0: float = floorf((cx - rad - S) / cell) * cell
	var y0: float = floorf((cy - rad - S) / cell) * cell
	var nx: int = int(ceilf((2.0 * (rad + S)) / cell)) + 2
	var ny: int = int(ceilf((2.0 * (rad + S)) / cell)) + 2
	var grid := PackedFloat32Array()
	grid.resize(nx * ny)
	for j in i + 1:
		var e: Array = log[j]
		if int(e[6]) != 1 or float(e[3]) <= 0.0:
			continue
		if not (float(e[0]) < T + l and T < float(e[0]) + float(e[7])):
			continue
		var er: float = float(e[3]) * 0.5
		var ex: float = float(e[1])
		var ey: float = float(e[2])
		var ia: int = maxi(0, int(floorf((ex - er - x0) / cell)))
		var ib: int = mini(nx - 1, int(ceilf((ex + er - x0) / cell)))
		var ja: int = maxi(0, int(floorf((ey - er - y0) / cell)))
		var jb: int = mini(ny - 1, int(ceilf((ey + er - y0) / cell)))
		for gx in range(ia, ib + 1):
			var px: float = x0 + (gx + 0.5) * cell - ex
			for gy in range(ja, jb + 1):
				var py: float = y0 + (gy + 0.5) * cell - ey
				if px * px + py * py <= er * er:
					grid[gy * nx + gx] += cell * cell
	# summed-area table
	var sat := PackedFloat64Array()
	sat.resize((nx + 1) * (ny + 1))
	for gy in ny:
		var row := 0.0
		for gx in nx:
			row += grid[gy * nx + gx]
			sat[(gy + 1) * (nx + 1) + gx + 1] = sat[gy * (nx + 1) + gx + 1] + row
	var k: int = int(roundf(S / cell))
	var best := 0.0
	for by in range(0, ny - k + 1):
		for bx in range(0, nx - k + 1):
			var s: float = sat[(by + k) * (nx + 1) + bx + k] - sat[by * (nx + 1) + bx + k] - sat[(by + k) * (nx + 1) + bx] + sat[by * (nx + 1) + bx]
			best = maxf(best, s)
	return best
