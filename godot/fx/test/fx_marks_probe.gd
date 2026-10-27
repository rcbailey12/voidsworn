extends SceneTree
# Probe: every weapon's mark on one real ship (G2 ShipView), each added on its own and timed (worker and upload), then a
# close-up of each mark about a second after it lands, and a pass 9 s later when they have cooled.
# Each mark is also shot from the battle camera's distance (170 units, fov 45, as render/camera_rig.gd), the view the
# marks must read at (r4 review: most were invisible there). Stills: NN_<mark>.png (close, fresh), NN_<mark>_cooled.png,
# NN_<mark>_tac.png (battle distance, cooled).
# PROBE_FAC, PROBE_CLS, PROBE_OUT (a folder), PROBE_W, PROBE_H, PROBE_LOOKS (optional: lance,plasma,... only those),
# PROBE_SIZE (draw scale, default 1.3). Prints MARKS_COST lines and the hull length.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const BREACH := preload("res://fx/fx_breach.gd")

const LOOKS := [["lance", 3], ["plasma", 2], ["macro", 3], ["gauss", 3], ["torp", 3], ["flak", 2], ["spine", 2], ["ion", 2], ["board", 2], ["ram", 3], ["auto", 2]]
const KEY := Vector3(-0.45, -0.7, -0.55)
const STYLE_NAME := {0: "breach", 1: "lance_burn", 2: "shell_crater", 3: "plasma_crater", 4: "gauss_entry", 5: "gauss_exit", 6: "torpedo_blast",
	7: "flak_pocks", 8: "acid_spines", 9: "ion_burn", 10: "ram_crumple", 11: "boarding_hatch", 12: "dent", 13: "scorch"}


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(_env("PROBE_W", "640")), int(_env("PROBE_H", "360")))
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.current = true
	cam.fov = 38.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.36, 0.4)
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	key.shadow_enabled = true
	key.light_energy = 2.2
	world.add_child(key)
	key.look_at_from_position(Vector3.ZERO, KEY)
	var sv: Node3D = SV.new()
	world.add_child(sv)
	var pf := _env("PROBE_FAC", "corsair")
	var pc := _env("PROBE_CLS", "Battle-barge")
	sv.setup({"id": "C", "fac": pf, "cls": pc, "facing": 0}, Vector3.ZERO)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": cam, "quality": "max"})
	fx.add_ship("C", sv, {"faction": pf, "cls": pc, "size": float(_env("PROBE_SIZE", "1.3")), "meshes": sv.meshes, "shielded": false})
	var s = fx.ship("C")
	var h = s.hull
	print("MARKS_HULL %s %s L=%.2f W=%.2f H=%.2f tris=%d" % [pf, pc, h.L, h.W, h.H, h.tri_count])
	var only := _env("PROBE_LOOKS", "")
	# spread the marks over the visible hull: farthest-point picks among upward and sideways samples
	var cands: Array = []
	for i in h.sp.size():
		var sn: Vector3 = h.sn[i]
		var sp: Vector3 = h.sp[i]
		if sn.y < 0.2:
			continue
		# lit by the key light (r5: several r4 and r5 marks sat in shadow, where nothing reads)
		if sn.dot(-KEY.normalized()) < 0.25:
			continue
		# keep points the close-up camera can see from where it will stand: nothing of the hull in between
		var eye: Vector3 = sp + (sn + Vector3(0, 0.25, 0)).normalized() * h.L * 0.3
		var hit: Dictionary = h.ray(eye, sp - eye)
		if hit.is_empty() or (hit["p"] as Vector3).distance_to(sp) > h.L * 0.01:
			continue
		# on a broad surface, not a gun barrel or a lamp: rays a little to each side land at about the same height
		var t1: Vector3 = sn.cross(Vector3.UP if absf(sn.y) < 0.9 else Vector3.RIGHT).normalized()
		var t2: Vector3 = sn.cross(t1)
		var flat := true
		for off in [t1, -t1, t2, -t2]:
			var q: Vector3 = sp + (off as Vector3) * h.L * 0.025
			var hq: Dictionary = h.ray(q + sn * h.L * 0.1, -sn)
			if hq.is_empty() or absf(((hq["p"] as Vector3) - sp).dot(sn)) > h.L * 0.008:
				flat = false
				break
		if not flat:
			continue
		cands.append(i)
	if cands.is_empty():
		push_error("marks probe: no lit, open, flat samples")
		quit(1)
		return
	var picks: Array = [cands[0]]
	while picks.size() < LOOKS.size() and picks.size() < cands.size():
		var best := -1
		var bd := -1.0
		for c in cands:
			var dmin := 1e9
			for p in picks:
				dmin = minf(dmin, (h.sp[c] as Vector3).distance_to(h.sp[p]))
			if dmin > bd:
				bd = dmin
				best = c
		picks.append(best)
	for i in 30:
		fx.step(1.0 / 60.0)
		await process_frame
	var out := _env("PROBE_OUT", "/tmp")
	# the clean hull from the battle camera, before any mark (a reference for the _tac stills)
	cam.fov = 45.0
	cam.look_at_from_position(sv.to_global(h.c + Vector3(0.0, 0.75, 0.6).normalized() * 170.0), sv.to_global(h.c))
	for i in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("%s/clean_tac.png" % out)
	var L: float = h.L
	var total_ms := 0.0
	# one mark at a time on the clean hull (each one's own cost, and nothing evicted by the section budget): a close-up
	# a second after it lands and another 9 s later when it has cooled
	for j in LOOKS.size():
		var look: String = LOOKS[j][0]
		var w: int = LOOKS[j][1]
		if only != "" and not (look in only.split(",")):
			continue
		var p: Vector3 = h.sp[picks[j]]
		var n: Vector3 = h.sn[picks[j]]
		if look == "ram":
			p = h.bow
			n = Vector3(1, 0, 0)
		var t1: Vector3 = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
		var d: Vector3 = (-n * 0.8 + t1 * 0.6).normalized()
		s._marks.clear()
		var t := Time.get_ticks_usec()
		s.add_mark(fx, look, w, p, n, d)
		s.flush_damage(fx)
		var ms := (Time.get_ticks_usec() - t) / 1000.0
		total_ms += ms
		var last: Array = s.mark_ms[s.mark_ms.size() - 1] if not s.mark_ms.is_empty() else [0, -1, -1]
		var ovt := 0
		for nd in s._hole_nodes:
			if nd is MeshInstance3D and String((nd as MeshInstance3D).name).contains("damage_marks") and (nd as MeshInstance3D).mesh != null:
				ovt = (nd as MeshInstance3D).mesh.surface_get_array_len(0) / 3
		print("MARKS_COST %s entries=%d wall=%.1f ms worker=%d ms main-thread apply=%.1f ms overlay tris=%d" % [look, last[0], ms, last[1], last[2], ovt])
		var T0: float = fx.now
		for pass_i in 2:
			var at: float = T0 + (1.0 if pass_i == 0 else 9.0)
			# no drawing while the clock runs on (only the stills need frames drawn)
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
			while fx.now < at:
				fx.step(1.0 / 60.0)
				await process_frame
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			for k in s._marks.size():
				var E = s._marks[k]
				var R: float = maxf(E.R + E.hl * 0.6, L * 0.012)
				var dist: float = maxf(R * 7.0, L * 0.08)
				var nn: Vector3 = E.n
				var tt: Vector3 = E.t1
				var nm := "%02d_%s%s%s" % [j, STYLE_NAME.get(E.style, "mark"), "" if k == 0 else "_%d" % k, "" if pass_i == 0 else "_cooled"]
				var eye: Vector3 = E.c + (nn * 1.0 + Vector3(0, 0.25, 0) + tt * 0.2).normalized() * dist
				if E.style == BREACH.S_RAM:
					eye = E.c + Vector3(0.22, 0.12, 0.16) * L
				cam.fov = 38.0
				cam.look_at_from_position(sv.to_global(eye), sv.to_global(E.c))
				for i in 3:
					await RenderingServer.frame_post_draw
				vp.get_texture().get_image().save_png("%s/%s.png" % [out, nm])
				print("wrote ", nm)
				if true:
					# the battle camera's distance, looking at the ship from the mark's side and from above (r8: a second
					# after the hit too, _tacf, with the scorch still glowing; _tac is the cooled mark 9 s on)
					var vd: Vector3 = (nn + Vector3(0, 0.7, 0)).normalized()
					if E.style == BREACH.S_RAM:
						vd = Vector3(0.6, 0.6, 0.5).normalized()
					cam.fov = 45.0
					cam.look_at_from_position(sv.to_global(h.c + vd * 170.0), sv.to_global(h.c))
					for i in 3:
						await RenderingServer.frame_post_draw
					vp.get_texture().get_image().save_png("%s/%s_%s.png" % [out, nm.replace("_cooled", ""), "tac" if pass_i == 1 else "tacf"])
	print("MARKS_COST total %.1f ms for %d marks one at a time; hull tris %d" % [total_ms, LOOKS.size(), h.tri_count])
	if only != "":
		quit()
		return
	# then all of them at once (the section budget decides what stays), seen from above
	s._marks.clear()
	for j in LOOKS.size():
		var p2: Vector3 = h.sp[picks[j]] if LOOKS[j][0] != "ram" else h.bow
		var n2: Vector3 = h.sn[picks[j]] if LOOKS[j][0] != "ram" else Vector3(1, 0, 0)
		s.add_mark(fx, LOOKS[j][0], LOOKS[j][1], p2, n2, -n2)
	s.flush_damage(fx)
	var last2: Array = s.mark_ms[s.mark_ms.size() - 1]
	print("MARKS_COST all %d kept of %d: worker %d ms, main-thread apply %.1f ms" % [s._marks.size(), LOOKS.size(), last2[1], last2[2]])
	for i in 60:
		fx.step(1.0 / 60.0)
		await process_frame
	cam.look_at_from_position(sv.to_global(h.c + Vector3(-0.15 * L, 0.55 * L, 0.75 * L)), sv.to_global(h.c))
	for i in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("%s/all_overview.png" % out)
	cam.fov = 45.0
	cam.look_at_from_position(sv.to_global(h.c + Vector3(-0.3, 0.75, 0.6).normalized() * 170.0), sv.to_global(h.c))
	for i in 3:
		await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("%s/all_tac.png" % out)
	quit()
