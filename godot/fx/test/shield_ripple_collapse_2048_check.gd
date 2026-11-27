extends SceneTree
# Issue 2048 item 1: shield hits tighten the local ripple so heavy hits do not wash the whole bubble at camera 170,
# and clean collapse adds a travelling edge wave while preserving ONE shield pool (R450), the 1.225 s close timing
# (COLLAPSE_CLOSE), Glasswright pale prismatic look, and flash comfort limits (R193).
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const SH := preload("res://fx/fx_shaders.gd")
const SHIP := preload("res://fx/fx_ship.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "shield_ripple_collapse_2048_check")
	_run.call_deferred()


func _check(ok: bool, msg: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + msg)
	else:
		print("  ok: " + msg)


func _smoothstep(e0: float, e1: float, x: float) -> float:
	var t := clampf((x - e0) / (e1 - e0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _eval_hit_intensity(d: float, dot_hemi: float, S: float, hit_spread: float, max_r: float, age: float, life: float, wpx: float, calm: float) -> Dictionary:
	var f := age / life
	var fade := (1.0 - f) * (1.0 - f) * _smoothstep(0.0, 0.025, age)
	var s_cap := minf(S, 1.8)
	var max_local := maxf(max_r * 0.72, wpx * 18.0)
	var spread := clampf(hit_spread, wpx * 14.0, max_local)
	var mask := 1.0 - _smoothstep(spread * 0.28, spread * 0.92, d)
	var hd := d / maxf(0.65 + s_cap * 0.22, wpx * 3.2)
	var core := exp(-hd * hd) * 3.2 * (1.0 - f) * lerpf(1.0, 0.25, calm)
	var rg := 0.0
	for j in 3:
		var aj := age - float(j) * 0.08
		if aj > 0.0:
			var rd := (d - aj / life * spread) / maxf(0.22 + aj * 0.32, wpx * 1.15)
			rg += exp(-rd * rd) * (2.1 if j == 0 else (1.15 if j == 1 else 0.65))
	var ga := clampf(age / minf(life, 0.55), 0.0, 1.0)
	var far := _smoothstep(0.08, 0.45, wpx)
	var hemi := _smoothstep(-0.35, 0.65, dot_hemi)
	var glow_all := (1.0 - ga) * (1.0 - ga) * _smoothstep(0.0, 0.04, age) * (0.025 + 0.045 * far) * (0.35 + 0.65 * hemi) * lerpf(1.0, 0.5, calm)
	var ripple_fade := pow(1.0 - f, 1.3) * _smoothstep(0.0, 0.025, age)
	var local_rg := rg * mask * (0.65 + 0.35 * s_cap) * ripple_fade * s_cap
	var total := core * fade * s_cap + local_rg + glow_all * minf(S, 1.3)
	return {"total": total, "core": core * fade * s_cap, "rg": local_rg, "glow_all": glow_all * minf(S, 1.3), "spread": spread}


func _box_ship(world: Node3D, fx, sid: String, faction: String, pos: Vector3):
	var body := Node3D.new()
	body.name = sid
	world.add_child(body)
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(22.0, 4.5, 7.5)
	mi.mesh = bm
	body.add_child(mi)
	fx.add_ship(sid, body, {"faction": faction, "cls": "Cruiser", "size": 0.85, "meshes": [mi], "shielded": true})
	return fx.ship(sid)


func _run() -> void:
	# 1. Verify shader structure, ONE pool, 1.225 s collapse timing, and collapse edge wave symbols.
	var code: String = SH.SHIELD
	_check(code.contains("float max_local = max(maxR * 0.72, wpx * 18.0);"), "SHIELD caps local ripple spread relative to shield radius")
	_check(code.contains("float hemi = smoothstep(-0.35, 0.65,"), "SHIELD weights broad glow to struck hemisphere")
	_check(code.contains("float bp_w = clamp(bp + wave_n * wave_amp, 0.0, 1.0);"), "SHIELD clean collapse carries travelling edge wave perturbation")
	_check(code.contains("float edge_wave = exp(-lead_d * lead_d)"), "SHIELD clean collapse carries secondary leading edge wave")
	_check(code.contains("float rim_tear = exp(-bd * bd * 4.5)"), "SHIELD clean collapse carries sharp receding rim tear")
	_check(code.contains("1.0 - smoothstep(0.85, 1.0, bp)") and code.contains("1.0 - smoothstep(bp_w - bw * 0.85, bp_w + bw * 0.85, dist)"),
		"SHIELD collapse uses ascending smoothstep edges (no GLSL undefined reversed bounds)")
	_check(code.contains("hot += (band * 0.25 + rim_tear * 0.35 + edge_wave * 0.15 + knot * 0.5) * (1.0 - gw);"), "Glasswright collapse keeps prismatic colour without burning white")
	_check(is_equal_approx(SHIP.COLLAPSE_CLOSE, 1.225), "clean collapse close timing stays 1.225 s (1.23 s)")
	_check(is_equal_approx(SHIP.collapse_close_setting(), 1.225), "default collapse_close_setting stays 1.225 s")

	# 2. Verify c170 local ripple vs far-side wash for a heavy torpedo hit (S=2.86, spread=26.0 on cruiser maxR=12.0).
	var wpx_170 := 2.0 * 170.0 * tan(deg_to_rad(22.5)) / 1080.0
	var wpx_26 := 2.0 * 26.0 * tan(deg_to_rad(22.5)) / 1080.0
	var age := 0.22
	var life := 1.1
	var max_r := 12.0
	var spread_used := minf(26.0, maxf(max_r * 0.72, wpx_170 * 18.0))
	var r_ring0 := (age / life) * spread_used
	var at_ring := _eval_hit_intensity(r_ring0, 0.9, 2.86, 26.0, max_r, age, life, wpx_170, 0.0)
	var at_far := _eval_hit_intensity(max_r * 1.4, -0.85, 2.86, 26.0, max_r, age, life, wpx_170, 0.0)
	var at_far_calm := _eval_hit_intensity(max_r * 1.4, -0.85, 2.86, 26.0, max_r, age, life, wpx_170, 1.0)
	var at_ring_26 := _eval_hit_intensity(r_ring0, 0.9, 2.86, 26.0, max_r, age, life, wpx_26, 0.0)
	_check(at_ring["rg"] > 1.5, "c170 heavy hit keeps strong local ripple on struck side (rg=%.3f)" % at_ring["rg"])
	_check(at_far["total"] < 0.06, "c170 heavy hit far-side wash stays under 0.06 (got %.4f)" % at_far["total"])
	_check(at_far["total"] < at_ring["rg"] * 0.04, "c170 far-side intensity is <4%% of local ripple peak")
	_check(at_far_calm["total"] < at_far["total"], "reduce flashing further softens shield wash")
	_check(at_ring_26["rg"] > 1.5 and at_ring_26["spread"] < max_r * 0.75, "c26 heavy hit keeps tight local ripple")

	# 3. Runtime simulation across all four shielded factions: single shield pool, hit + clean collapse, zero flash violations.
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	cam.fov = 45.0
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0, 130, 110), Vector3.ZERO)
	cam.current = true
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "high", "shake": 0.0})
	var shielded_factions := ["voidsworn", "hegemony", "corsair", "ithar"]
	for i in shielded_factions.size():
		var fac: String = shielded_factions[i]
		var s = _box_ship(world, fx, "sh_" + fac, fac, Vector3((i - 1.5) * 30.0, 0.0, 0.0))
		_check(s != null and s._shield_mat != null, "%s: single shield material exists" % fac)
		_check(s._fail_look == 2, "%s: default shield failure is clean collapse (2)" % fac)
		var pt: Dictionary = s.shield_point(s.root.global_position + Vector3(30.0, 2.0, 10.0))
		s.shield_hit(fx, pt["local"], fx.now, 2.86, 26.0, 1.1, 0.6)
		fx.step(0.15)
		s.shield_break(fx, 0, pt["local"])
		var brk_close := float(s._shield_mat.get_shader_parameter("brk_close"))
		_check(is_equal_approx(brk_close, 1.225), "%s: brk_close stays 1.225 s (got %.3f)" % [fac, brk_close])
		for k in 20:
			fx.step(0.1)
	# Verify no more than 3 flashes per rolling second.
	var max_per_sec := 0
	for a in fx.flash_log:
		var count := 0
		for b in fx.flash_log:
			if b >= a and b < a + 1.0:
				count += 1
		max_per_sec = maxi(max_per_sec, count)
	_check(max_per_sec <= 3, "shield hits and collapses stay within flash counter cap (max %d/s)" % max_per_sec)
	fx.release()
	world.queue_free()
	await process_frame
	FX.clear_static()
	print("shield_ripple_collapse_2048_check: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
