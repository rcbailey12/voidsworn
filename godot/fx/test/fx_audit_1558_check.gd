extends SceneTree
# godot --headless --path godot --script res://fx/test/fx_audit_1558_check.gd
# Issue 1558 (effects audit, items 1 to 4 and 8 to 10) and issue 1528 (first torpedo salvo stall), headless:
#  1. the weapon gas shader stretches its quad by `aspect` (the old replace target no longer existed: round puffs)
#  2. the big-death gas veil is born when it appears (no frame 0 held over the core flash, no early return to the pool)
#  3. slag seams, debris plate rims, tear sparks and strike craft trails ignore fog like every other effect
#  4. the hit pause lasts the same real time at 60 and 144 fps and actually drops the clock
#  8. a kit torpedo trail keeps one shared strip mesh while it flies and fades (no new ArrayMesh per frame)
#  9. strike craft trails change their mesh only on the 30 Hz sample step
# 10. hull heat spots reuse one ring per hull; non-kit rounds share one quad
# 1528. warm_munitions loads every body the fleets can fire before the fight, so the first round reads no file

const FX := preload("res://fx/fx.gd")
const GUARD := preload("res://tools/ci/check_guard.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")
const WING := preload("res://render/squadron_wing.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "fx_audit_1558_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok:
		failures += 1


func _fx() -> Node:
	var fx = FX.new()
	root.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	return fx


func _ship(fx, id: String, faction := "voidsworn") -> Node3D:
	var target := Node3D.new()
	root.add_child(target)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 2, 3)
	mi.mesh = box
	target.add_child(mi)
	fx.add_ship(id, target, {"meshes": [mi], "shielded": false, "faction": faction})
	return target


func _run() -> void:
	_aspect()
	_veil()
	_fog()
	_hit_pause()
	_kit_trail()
	_craft_trail()
	_per_hit()
	_munitions()
	print("fx_audit_1558_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)


func _aspect() -> void:
	var fx = _fx()
	var code: String = WEAP._weapon_shader(fx).code
	_check(code.contains("up * local.y * aspect"), "1: the weapon gas quad is stretched by aspect")
	fx.free()


func _veil() -> void:
	var fx = _fx()
	fx.now = 5.0
	var target := _ship(fx, "veil")
	var piece := Node3D.new()
	fx.add_child(piece)
	fx.later(fx.now + DEATH.CORE_VEIL_DELAY, DEATH._core_gas_veil.bind(fx, fx.ships["veil"], weakref(piece), Vector3(1, 0, 0), true, Vector3.ZERO))
	_check(_veils(fx).is_empty(), "2: no veil while the core is at full heat")
	piece.position = Vector3(2, 0, 0)   # the wreck drifts after the flash
	var born_at := 0.0
	for i in 40:
		fx.step(1.0 / 60.0)
		if born_at == 0.0 and not _veils(fx).is_empty(): born_at = fx.now
	var vs := _veils(fx)
	_check(vs.size() == 1, "2: the core gas veil spawns once, after the delay")
	if vs.size() == 1:
		var veil: MeshInstance3D = vs[0]
		var born := float((veil.material_override as ShaderMaterial).get_shader_parameter("born"))
		_check(born >= 5.0 + DEATH.CORE_VEIL_DELAY - 1e-3 and absf(born - born_at) <= 1.0 / 60.0 + 1e-3, "2: the veil is born when it spawns, not moved ahead (born %.3f)" % born)
		_check(veil.global_position.distance_to(Vector3(3, 0, 0)) < 0.5, "2: the veil sits on the wreck where it is now, not where it broke (%s)" % str(veil.global_position))
	# a piece that is gone by then gets no veil
	var gone := Node3D.new()
	fx.add_child(gone)
	fx.later(fx.now + DEATH.CORE_VEIL_DELAY, DEATH._core_gas_veil.bind(fx, fx.ships["veil"], weakref(gone), Vector3.ZERO, true, Vector3.ZERO))
	gone.free()
	for i in 40: fx.step(1.0 / 60.0)
	_check(_veils(fx).size() == vs.size(), "2: a wreck piece freed before the delay gets no veil")
	var src_text := FileAccess.get_file_as_string("res://fx/fx_death.gd")
	_check(not src_text.contains("set_shader_parameter(\"born\", fx.now + 0.45)"), "2: no picture is moved ahead of its pool timer")
	_check(src_text.contains("fx.later(fx.now + CORE_VEIL_DELAY, _core_gas_veil.bind(fx, s, node_ref, local"), "2: the core's veil is scheduled with the live piece")
	fx.remove_ship("veil")
	fx.free()
	target.free()


func _veils(fx) -> Array:
	var out := []
	for c in fx.find_children("*", "MeshInstance3D", true, false):
		if String(c.get_meta("fx_picture_kind", "")) == "cool" and (c as MeshInstance3D).visible:
			out.append(c)
	return out


func _fog() -> void:
	_check(DEATH.SLAG.contains("fog_disabled"), "3: slag wreck seams ignore fog")
	_check(DEATH.DEBRIS_BODY.contains("fog_disabled"), "3: debris plate rims ignore fog")
	_check(WING.TRAIL.contains("fog_disabled"), "3: strike craft trails ignore fog")
	# tear_particles draws nothing headless, so read its material block: the unshaded quad sets disable_fog
	var text := FileAccess.get_file_as_string("res://fx/fx_death.gd")
	var at := text.find("static func tear_particles(")
	var block := text.substr(at, text.find("\nstatic func ", at + 10) - at)
	_check(block.contains("mat.disable_fog = true"), "3: tear sparks and vents ignore fog")


# Real seconds the clock spends under half speed, and effect seconds lost, after a 3-frame hit pause.
func _pause_at(fps: int) -> Array:
	var fx = _fx()
	fx.step(1.0 / fps)
	fx.hit_pause(fx.now, 3)
	var slow := 0.0
	var lost := 0.0
	var dt := 1.0 / float(fps)
	var lowest := 1.0
	for i in int(fps * 0.4):
		var t0: float = fx.now
		fx.step(dt)
		var spd: float = (fx.now - t0) / dt
		lowest = minf(lowest, spd)
		if spd < 0.5: slow += dt
		lost += dt - (fx.now - t0)
	fx.free()
	return [slow, lost, lowest]


func _hit_pause() -> void:
	var a := _pause_at(60)
	var b := _pause_at(144)
	print("     hit pause 60 fps: %.3f s slow, %.3f s lost, lowest %.2f; 144 fps: %.3f s slow, %.3f s lost, lowest %.2f" % [a[0], a[1], a[2], b[0], b[1], b[2]])
	_check(float(a[2]) < 0.2 and float(b[2]) < 0.2, "4: a hit pause drops the clock to a crawl at 60 and 144 fps")
	_check(absf(float(a[0]) - 0.05) <= 1.0 / 60.0 + 1e-4 and absf(float(b[0]) - 0.05) <= 1.0 / 60.0 + 1e-4, "4: a 3-frame pause lasts 0.05 s of real time at 60 and 144 fps")
	_check(absf(float(a[1]) - float(b[1])) < 0.012, "4: the effect time lost matches across frame rates")
	# a long frame that ends the pause crawls only for what was left of it (Artoo and the OpenAI review on PR 1593:
	# a 50 ms pause crawled 66.7 ms at 30 fps and 100 ms in a hitch)
	var c := _lost_over([1.0 / 30.0])
	var h := _lost_over([0.1, 1.0 / 60.0])
	var ref := _lost_over([1.0 / 144.0])
	print("     effect time lost: 144 fps %.4f s, 30 fps %.4f s, a 100 ms hitch %.4f s" % [ref, c, h])
	_check(absf(c - ref) < 0.004 and absf(h - ref) < 0.004, "4: a 30 fps frame or a 100 ms hitch ends the pause on time (lost %.4f and %.4f against %.4f)" % [c, h, ref])


# Effect seconds lost to a 3-frame hit pause over 0.5 s of real time, the frames cycling through `frames`.
func _lost_over(frames: Array) -> float:
	var fx = _fx()
	fx.step(1.0 / 60.0)
	fx.hit_pause(fx.now, 3)
	var real := 0.0
	var start: float = fx.now
	var i := 0
	while real < 0.5:
		var dt := float(frames[i % frames.size()])
		fx.step(dt)
		real += dt
		i += 1
	var lost: float = real - (fx.now - start)
	fx.free()
	return lost


func _kit_trail() -> void:
	var fx = _fx()
	var body := Node3D.new()
	fx.add_child(body)
	var p := {"k": 1.0, "lk": "torp", "eng": Color(1, 0.6, 0.3), "seed": 0.3, "mesh": body}
	WEAP._kit_trail_start(fx, p, {"trail": 0})
	fx.dstate["proj"] = [p]
	var mi: MeshInstance3D = p["trail"]["mi"]
	var strip: Mesh = mi.mesh
	var same := true
	for i in 30:
		fx.now += 1.0 / 60.0
		body.global_position = Vector3(i * 0.5, 0, 0)
		WEAP._kit_trail_push(fx, p)
		WEAP._kit_trails_update(fx)
		same = same and mi.mesh == strip
	var m := mi.material_override as ShaderMaterial
	var n := int(m.get_shader_parameter("count"))
	_check(same and mi.visible, "8: a flying kit trail keeps the one shared strip mesh")
	_check(n >= 2 and n <= WEAP.KIT_TRAIL_PTS, "8: its samples go to the material (%d of %d)" % [n, WEAP.KIT_TRAIL_PTS])
	var shader: String = m.shader.code
	_check(shader.contains("uniform vec4 pts[%d]" % WEAP.KIT_TRAIL_PTS) and shader.contains("fog_disabled"), "8: the kit trail shader reads its samples and ignores fog")
	# the round hits: its trail fades out on the same strip, then frees
	fx.dstate["proj"] = []
	fx.dstate["ptrails"] = [p["trail"]]
	p.erase("trail")
	var gone := false
	for i in 40:
		fx.now += 1.0 / 60.0
		WEAP._kit_trails_update(fx)
		same = same and (not is_instance_valid(mi) or mi.is_queued_for_deletion() or mi.mesh == strip)
		if not is_instance_valid(mi) or mi.is_queued_for_deletion():
			gone = true
	_check(same and gone and (fx.dstate["ptrails"] as Array).is_empty(), "8: a fading trail keeps the strip, then frees once its samples cool")
	fx.free()


func _craft_trail() -> void:
	var wing = WING.new()
	root.add_child(wing)
	wing.setup("hegemony", "fighter", 1.0, 2, 0.0)
	wing.set_process(false)
	var tr: Dictionary = wing.trails[0]
	var last := []
	var changes := 0
	var frames := 120
	for i in frames:
		wing.step(1.0 / 60.0)
		var hist: Array = tr.hist
		var now_state := [hist.size(), hist[0][1] if not hist.is_empty() else -1.0, hist[-1][1] if not hist.is_empty() else -1.0]
		if now_state != last:
			changes += 1
		last = now_state
	print("     craft trail: %d sample changes in %d frames at 60 fps" % [changes, frames])
	_check(changes <= frames / 2 + 2, "9: a strike craft trail changes only on its 30 Hz sample step")
	wing.free()


func _per_hit() -> void:
	var fx = _fx()
	var target := _ship(fx, "hull")
	var s = fx.ships["hull"]
	for i in 6:
		WEAP._heat_spot(fx, target.global_position + Vector3(i, 0, 0), fx.now, 1.0, 1.0, "shell", 6.0, 2.0, s)
	for i in 3:
		fx.step(1.0 / 60.0)
	var spots := 0
	for c in s._dmg_root.get_children():
		if String(c.name).begins_with("fx_hit_heat"):
			spots += 1
	_check(spots == 1, "10: six metal hits share one heat ring on the hull (%d nodes)" % spots)
	var a: Node3D = WEAP._projectile_body(fx, "torp", 1.0, Color(1, 0.6, 0.3), "")
	var b: Node3D = WEAP._projectile_body(fx, "torp", 1.0, Color(0.3, 0.6, 1.0), "")
	var qa: Array = []
	for n in [a, b]:
		for c in n.find_children("*", "MeshInstance3D", true, false):
			if (c as MeshInstance3D).mesh is QuadMesh: qa.append((c as MeshInstance3D).mesh)
	var shared := qa.size() >= 4
	for q in qa: shared = shared and q == qa[0]
	_check(shared, "10: non-kit rounds share one quad (%d quads)" % qa.size())
	var ea: ShaderMaterial = a.get_meta("exhaust")
	var eb: ShaderMaterial = b.get_meta("exhaust")
	_check(ea != eb and ea.shader == eb.shader and ea.shader.code.contains("up * local.y * aspect"), "10: each round has its own exhaust values on the shared weapon gas shader")
	var ma: ShaderMaterial = a.get_meta("motor")
	var mb: ShaderMaterial = b.get_meta("motor")
	_check(ma != mb and Vector3(ma.get_shader_parameter("tint")) != Vector3(mb.get_shader_parameter("tint")), "10: each round keeps its own drive colour")
	a.free(); b.free()
	fx.remove_ship("hull")
	fx.free()
	target.free()


func _munitions() -> void:
	var fx = _fx()
	var t1 := _ship(fx, "sunward", "voidsworn")
	var t2 := _ship(fx, "hullbreaker", "corsair")
	var tmp := Node3D.new()
	fx.add_child(tmp)
	var t0 := Time.get_ticks_usec()
	var n: int = WEAP.warm_munitions(fx, tmp)
	var warm_ms := (Time.get_ticks_usec() - t0) / 1000.0
	_check(n == 2 and fx.dstate.has("munition_voidsworn_torp") and fx.dstate.has("munition_corsair_rockets"), "1528: warm-up loads both kit bodies the fleets can fire (%d, %.1f ms)" % [n, warm_ms])
	var strips := 0
	for c in tmp.find_children("*", "MeshInstance3D", true, false):
		if (c as MeshInstance3D).mesh == WEAP.kit_trail_strip(fx): strips += 1
	_check(strips == 1, "1528: the warm-up holds one kit trail strip in its own vertex format (structure only; the PC timing run proves the draw)")
	t0 = Time.get_ticks_usec()
	var r: Node3D = WEAP._projectile_body(fx, "torp", 1.0, Color(1, 0.6, 0.3), "voidsworn")
	var first_ms := (Time.get_ticks_usec() - t0) / 1000.0
	_check(r.has_meta("kit"), "1528: the first round after warm-up is the kit body")
	print("     first kit round after warm-up: %.2f ms (warm-up took %.1f ms)" % [first_ms, warm_ms])
	r.free()
	# a battle with no kit-body faction warms nothing and does not fail
	var fx2 = _fx()
	var t3 := _ship(fx2, "glass", "ithar")
	var tmp2 := Node3D.new()
	fx2.add_child(tmp2)
	_check(WEAP.warm_munitions(fx2, tmp2) == 0, "1528: a fleet with no kit bodies warms only the trail")
	fx.remove_ship("sunward"); fx.remove_ship("hullbreaker"); fx2.remove_ship("glass")
	fx.free(); fx2.free()
	t1.free(); t2.free(); t3.free()
