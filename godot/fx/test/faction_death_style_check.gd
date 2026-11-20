extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1399 (R367, Ryan's "Full faction deaths"): every metal faction dies in its own colours and break, from
# faction_looks.json "death". A box cruiser of each is killed with the strained death on (the game's default), at quality
# high with physics plates, against a plain control (corsair's look with its death entry removed: today's shared fire):
#   plain: its death pictures keep the baked colours (fac_fire off), it smokes, its torn faces glow orange;
#   ithar (shatter): white and rainbow fire, no smoke picture, more and smaller fragments, glittering dust, stored-light faces;
#   deathless (peel): violet-white fire, plates peel off band by band before the split, the scene dims at its core flash;
#   voidsworn (drumbeat, round 2): ember fire, a row of magazine pops down the broadside before the split;
#   hegemony (arc, round 2): blue-white fire, lightning ribbons jump the gap as the pieces part;
#   corsair (patch, round 2): red fire, patch plates tear loose before the split.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
const LOOK := preload("res://fx/faction_look.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "faction_death_style_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + why)
	if not ok:
		failures += 1
		push_error(why)


func _run() -> void:
	var plain_look: Dictionary = (LOOK.of("corsair") as Dictionary).duplicate()
	plain_look.erase("death")
	LOOK.table()["test_plain"] = plain_look
	var today := await _kill("test_plain")
	var glass := await _kill("ithar")
	var ecl := await _kill("deathless")
	var sun := await _kill("voidsworn")
	var heg := await _kill("hegemony")
	var ash := await _kill("corsair")
	LOOK.reload()
	# today's (no death entry)
	check(today["styled"] == 0 and today["pics"] > 0, "plain: its %d death pictures keep the baked orange (%d styled)" % [today["pics"], today["styled"]])
	check(today["smoke"] > 0, "plain: it still smokes (%d smoke pictures)" % today["smoke"])
	check(today["heat"] == "today", "plain: torn faces glow today's orange (%s)" % today["heat"])
	check(today.get("ember") == null or (today["ember"] as Vector3).is_equal_approx(Vector3(1.0, 0.36, 0.07)), "plain: its tear keeps today's ember (%s)" % str(today.get("ember")))
	# every styled faction
	for r in [glass, ecl, sun, heg, ash]:
		check(r["pics"] > 0 and r["styled"] == r["pics"], "%s: all %d death pictures take its own fire (%d styled)" % [r["fac"], r["pics"], r["styled"]])
		check(r["heat"] == "styled", "%s: torn faces glow its own colour (%s)" % [r["fac"], r["heat"]])
		check(r.get("ember") is Vector3, "%s: its tear glows its own colour (%s)" % [r["fac"], str(r.get("ember"))])
	# Glasswrights
	check(glass["prism"], "ithar: its fire has the rainbow edge")
	check(glass["smoke"] == 0, "ithar: no smoke picture (%d)" % glass["smoke"])
	check(int(glass["n_frag"]) > int(today["n_frag"]), "ithar: shatters into more fragments than the plain hull (%d against %d)" % [glass["n_frag"], today["n_frag"]])
	check(int(glass["streaks"]) > int(today["streaks"]) + 30, "ithar: glittering dust after the core (%d streaks against plain %d)" % [glass["streaks"], today["streaks"]])
	check((glass["ember"] as Vector3).z > 0.9 if glass.get("ember") is Vector3 else false, "ithar: its tear is its stored light")
	# Eclipse
	check(not ecl["prism"], "deathless: no rainbow edge")
	check(int(ecl["plates_before_split"]) > int(today["plates_before_split"]), "deathless: plates peel off before the split (%d against plain %d)" % [ecl["plates_before_split"], today["plates_before_split"]])
	check(ecl["dimmed"], "deathless: the scene dims at its core flash")
	check((ecl["ember"] as Vector3).z > 0.9 if ecl.get("ember") is Vector3 else false, "deathless: its tear is violet")
	# Sunward Crusade
	check(int(sun["sprites_before_split"]) >= int(today["sprites_before_split"]) + 5, "voidsworn: a row of magazine pops before the split (%d sprites against plain %d)" % [sun["sprites_before_split"], today["sprites_before_split"]])
	# Hegemony
	check(int(heg["ribbons"]) >= int(today["ribbons"]) + 6, "hegemony: arcs jump the gap (%d ribbons against plain %d)" % [heg["ribbons"], today["ribbons"]])
	check((heg["ember"] as Vector3).z > 0.9 if heg.get("ember") is Vector3 else false, "hegemony: its tear is blue-white")
	# Hullbreakers
	check(int(ash["plates_before_split"]) > int(today["plates_before_split"]), "corsair: patch plates tear loose before the split (%d against plain %d)" % [ash["plates_before_split"], today["plates_before_split"]])
	print("FACTION_DEATH failures=%d" % failures)
	quit(1 if failures else 0)


func _kill(fac: String) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.position = Vector3(0, 30, 40)
	var holder := Node3D.new()
	world.add_child(holder)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(20, 4, 6)
	box.subdivide_width = 19
	box.subdivide_height = 3
	box.subdivide_depth = 5
	mi.mesh = box
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	holder.add_child(mi)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "camera": cam, "shake": 0.0})
	fx.dstate["physics_on"] = true
	fx.add_ship("k", holder, {"faction": fac, "cls": "Cruiser", "size": 1.0})
	var s = fx.ship("k")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 60000:
		fx.step(1.0 / 60.0)
		await process_frame
		if (s.get_meta("cut_job", {}) as Dictionary).get("built", false): break
	var plan: Dictionary = (s.get_meta("cut_job", {}) as Dictionary).get("plan", {})
	var streaks0: int = _emitted(fx, "stk")
	var spr0: int = _emitted(fx, "spr")
	var rib0: int = _emitted(fx, "rib")
	fx.death("k", "blast")
	var seen := {}
	var res := {"fac": fac, "pics": 0, "styled": 0, "prism": false, "smoke": 0, "n_frag": int(plan.get("n_frag", 0)),
		"plates_before_split": 0, "dimmed": false, "heat": "none", "streaks": 0, "sprites_before_split": 0, "ribbons": 0}
	var split_seen := false
	for i in 7 * 60:
		fx.step(1.0 / 60.0)
		await process_frame
		if fx.get("_dim_t0") != null and float(fx.get("_dim_t0")) >= 0.0: res["dimmed"] = true
		if res.get("ember") == null:
			for mm in s.meshes:
				if is_instance_valid(mm) and (mm as MeshInstance3D).material_overlay is ShaderMaterial:
					var e = ((mm as MeshInstance3D).material_overlay as ShaderMaterial).get_shader_parameter("ember")
					if e is Vector3: res["ember"] = e
					break
		if not split_seen:
			res["plates_before_split"] = (fx.dstate.get("debris_awake", {}) as Dictionary).size()
			res["sprites_before_split"] = _emitted(fx, "spr") - spr0
			split_seen = s.has_meta("death_hidden")
		for n in fx.get_children():
			if not (n is MeshInstance3D) or not n.visible or seen.has(n.get_instance_id() * 1000 + int(n.get_meta("pic_gen", 0))): continue
			var nm := String(n.name)
			if not (nm.begins_with("fx_beat_") or nm.begins_with("fx_baked_")): continue
			seen[n.get_instance_id() * 1000 + int(n.get_meta("pic_gen", 0))] = true
			var m := (n as MeshInstance3D).material_override as ShaderMaterial
			if m == null: continue
			res["pics"] += 1
			var ff = m.get_shader_parameter("fac_fire")
			if ff is Color and (ff as Color).a > 0.5: res["styled"] += 1
			if float(m.get_shader_parameter("fac_prism") if m.get_shader_parameter("fac_prism") != null else 0.0) > 0.5: res["prism"] = true
			if nm == "fx_beat_impact": res["smoke"] += 1
	res["streaks"] = _emitted(fx, "stk") - streaks0
	res["ribbons"] = _emitted(fx, "rib") - rib0
	for w in fx.dstate.get("wrecks", []):
		if w["id"] != "k": continue
		for nd in w["nodes"]:
			for c in (nd as Node).find_children("*", "MeshInstance3D", true, false):
				var am: Mesh = (c as MeshInstance3D).mesh
				for k in (am.get_surface_count() if am != null else 0):
					var sm = am.surface_get_material(k)
					if sm is ShaderMaterial and (sm as ShaderMaterial).shader != null and (sm as ShaderMaterial).shader.code.contains("heat_hot"):
						var hh = (sm as ShaderMaterial).get_shader_parameter("heat_hot")
						res["heat"] = "styled" if hh is Vector3 or (hh is Color and not (hh as Color).is_equal_approx(Color(0.95, 0.40, 0.09))) else "today"
	print("FACTION_DEATH ", JSON.stringify(res))
	world.queue_free()
	await process_frame
	return res


# sprites, streaks or ribbons drawn so far (a pool's emitted count)
func _emitted(fx, key: String) -> int:
	var pool = fx.pools.get(key) if "pools" in fx else null
	if pool == null: return 0
	return int(pool.get("emitted"))
