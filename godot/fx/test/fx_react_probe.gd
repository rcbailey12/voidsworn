extends SceneTree
# Probe (R50): how a frigate and a capital ship take a hit, per weapon weight. Each weapon fires one hull hit at each
# ship from the side; the probe records the peak roll, pitch and yaw (degrees), the peak drift (share of the ship's
# length) and how long the thrusters take to settle it, and saves a strip of stills per hit (just before, the impact,
# then 0.15, 0.4 and 0.9 s after) so the shudder, the kick and the thruster puffs can be seen.
# PROBE_OUT (a folder; no stills if empty), PROBE_W, PROBE_H. Prints REACT lines.

const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")

const SHOTS := [["lance", "lance", "lance"], ["laser", "battery", "plasma"], ["hbattery", "battery", "macro"],
	["gauss", "gauss", "gauss"], ["torp", "torp", "torp"], ["ram", "torp", "ram"]]
const SHIPS := [["F", "voidsworn", "Frigate", 0.55], ["K", "hegemony", "Super-dreadnought", 1.3]]


func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _env(k: String, d: String) -> String:
	var v := OS.get_environment(k)
	return v if v != "" else d


func _run() -> void:
	var out := _env("PROBE_OUT", "")
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
	key.light_energy = 2.2
	world.add_child(key)
	key.look_at_from_position(Vector3.ZERO, Vector3(-0.45, -0.7, -0.55))
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"camera": null, "quality": "max"})
	var views := {}
	for i in SHIPS.size():
		var sd: Array = SHIPS[i]
		var sv: Node3D = SV.new()
		world.add_child(sv)
		sv.setup({"id": sd[0], "fac": sd[1], "cls": sd[2], "facing": 0}, Vector3(0, 0, i * 120.0))
		fx.add_ship(sd[0], sv, {"faction": sd[1], "cls": sd[2], "size": sd[3], "meshes": sv.meshes, "shielded": false})
		views[sd[0]] = sv
		# the shooter, off to starboard
		var a: Node3D = SV.new()
		world.add_child(a)
		a.setup({"id": "A" + sd[0], "fac": "voidsworn", "cls": "Cruiser", "facing": 3}, Vector3(0, 0, i * 120.0 + 60.0))
		fx.add_ship("A" + sd[0], a, {"faction": "voidsworn", "cls": "Cruiser", "size": 0.8, "meshes": a.meshes})
		a.visible = false
	for i in 30:
		fx.step(1.0 / 60.0)
		await process_frame
	for sd in SHIPS:
		var id: String = sd[0]
		var sv: Node3D = views[id]
		var s = fx.ship(id)
		var L: float = s.hull.L
		for sh in SHOTS:
			var r: Dictionary = fx.volley("A" + id, sh[1], id, {"weapon_id": sh[0], "shots": [true], "hits": [{"shield": 0, "hull": 6, "section": "mid", "crit": false}], "quad": 1})
			var t_imp: float = fx.now + float((r["impacts"] as Array)[0]) if not (r["impacts"] as Array).is_empty() else fx.now
			var base_pos: Vector3 = sv.position
			var base_yaw: float = sv.rotation.y
			var peak := Vector3.ZERO
			var drift := 0.0
			var settle := -1.0
			var marks := [-0.05, 0.02, 0.15, 0.4, 0.9]
			var mi := 0
			var cen: Vector3 = sv.to_global(s.hull.c)
			cam.look_at_from_position(cen + Vector3(-0.35 * L, 0.45 * L, 1.15 * L), cen)
			var t_end: float = t_imp + 4.0
			while fx.now < t_end:
				fx.step(1.0 / 60.0)
				var a := Vector3(rad_to_deg(sv.rotation.x), rad_to_deg(sv.rotation.y - base_yaw), rad_to_deg(sv.rotation.z))
				peak = Vector3(maxf(peak.x, absf(a.x)), maxf(peak.y, absf(a.y)), maxf(peak.z, absf(a.z)))
				drift = maxf(drift, sv.position.distance_to(base_pos) / L)
				if fx.now > t_imp + 0.1 and settle < 0.0 and not s._reacting:
					settle = fx.now - t_imp
				if out != "" and mi < marks.size() and fx.now >= t_imp + float(marks[mi]):
					await RenderingServer.frame_post_draw
					vp.get_texture().get_image().save_png("%s/%s_%s_%d.png" % [out, id, sh[2], mi])
					mi += 1
				else:
					await process_frame
			print("REACT %s %s roll=%.2f yaw=%.2f pitch=%.2f deg drift=%.2f%% of length settle=%.2f s" % [sd[2], sh[2], peak.x, peak.y, peak.z, drift * 100.0, settle])
	quit()
