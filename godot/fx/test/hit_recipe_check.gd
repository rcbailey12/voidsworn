extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 461: the hits, upgraded (docs/playbooks/deaths_and_hits.md "The hits, upgraded"; cinematic audit items 1, 4, 11).
# Box ships at the battle camera, headless. Asserts:
#   1. the ladder: las, macro, lance, torpedo on a hull, torpedo on a shield are each plainly bigger than the step before
#      (flash, then the shield ripple, the biggest body of any hit), and a hit is sized by the gun as well as the target;
#   2. each weapon family has its own recipe (shell chips and a skipping spark cone, an energy splash that runs along the
#      plate, a lance burn that crawls, torpedo gas and debris, an ion burn with no molten spray);
#   3. thrown matter lives longer than flame: no hit flash lives past the 0.70 s flame cap, sparks use their own cooling life (issue 538),
#      debris and gas live past a second (R193, "Flame only");
#   4. direction: every spark, chip, puff and ember leaves along the plate's outward side (nothing sprays into the ship);
#   5. light on neighbours: a torpedo hit's light reaches about two hexes;
#   6. reduce flashing: the same hits book and count no flash at all;
#   7. a lance kill on a big hull breaks on the beam's own line, clean (no kink, almost no teeth);
#  10. a torpedo on a shield draws and books at its row's size;
#   9. gun hits never spend the three flashes a second that deaths' core flashes need (fx.flash_at yield_last);
#   8. the engine core flickers 0.95 to 1.0 only (issue 504's finding), and wounds are kept past the old cap of 12.
#   godot --headless --path godot --script res://fx/test/hit_recipe_check.gd

const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const DEATH := preload("res://fx/fx_death.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const FRAGMENTS := preload("res://fx/fx_fragments.gd")
const POOLS := preload("res://fx/fx_pool.gd")
const SH := preload("res://fx/fx_shaders.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "hit_recipe_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
	else:
		print("  ok  ", message)


func _ship(world: Node3D, fx, id: String, cls: String, size: float, at: Vector3, faction := "deathless") -> void:
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
	fx.add_ship(id, r, {"faction": faction, "cls": cls, "size": size, "meshes": [mi]})


func _advance(fx, seconds: float) -> void:
	var end: float = fx.now + seconds
	while fx.now < end:
		fx.step(1.0 / 60.0)
		await process_frame


func _midflight_calm_check() -> void:
	for calm in [false, true]:
		var wf := _world(false)
		var world: Node3D = wf[0]
		var fx = wf[1]
		var p := Vector3.ZERO
		# Schedule at the same future times used by the volley helpers, then change the setting before either appears.
		WEAP._staged_hit(fx, null, p, 0.30, true)
		WEAP._burst(fx, p + Vector3.LEFT * 75.0, Vector3.UP, 0.25, 2.6, "flash", 0.18, Color.WHITE, 4.5, 28.0)
		fx.light(p, 0.30, 0.42, 7.9, Color.WHITE)
		await _advance(fx, 0.12)
		fx.reduce_flashing = calm
		await _advance(fx, 0.22)
		var flash := fx.get_node_or_null("fx_staged_flash") as MeshInstance3D
		var body := fx.get_node_or_null("fx_staged_body") as MeshInstance3D
		var burst := fx.get_node_or_null("fx_weapon_flash") as MeshInstance3D
		var mode := "reduced" if calm else "normal"
		_check_picture(flash, 1.25 if calm else 5.2, 0.50 if calm else 0.16, mode + " torpedo flash")
		_check_picture(body, 1.0 if calm else 3.8, 0.65, mode + " torpedo body")
		_check_picture(burst, 1.25 if calm else 4.5, 0.40 if calm else 0.18, mode + " muzzle flash")
		var lamp: OmniLight3D = fx._lpool[0]
		_check(lamp.visible and (lamp.light_energy < 3.2 if calm else lamp.light_energy > 5.0),
			"in-flight %s event light at arrival: %.2f power" % [mode, lamp.light_energy])
		if calm:
			_check(fx.flash_area_log.is_empty() and fx.flash_log.is_empty(), "Reduce Flashing switched on in flight: no baked flash booked")
		fx.release()
		world.queue_free()
		await process_frame


func _check_picture(picture: MeshInstance3D, power: float, duration: float, label: String) -> void:
	if picture == null:
		_check(false, "in-flight %s missing at arrival" % label)
		return
	var mat := picture.material_override as ShaderMaterial
	var actual_power := float(mat.get_shader_parameter("intensity"))
	var actual_duration := float(mat.get_shader_parameter("lifetime"))
	_check(is_equal_approx(actual_power, power) and is_equal_approx(actual_duration, duration),
		"in-flight %s at arrival: %.2f power, %.2f s" % [label, actual_power, actual_duration])


func _world(calm: bool) -> Array:
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
	fx.setup({"camera": cam, "quality": "max", "reduce_flashing": calm, "shake": 0.0, "unit": 1.0})
	fx.flash_area_logging = true
	return [world, fx]


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	_ladder()
	var looks := [["battery", "turret", "voidsworn"], ["battery", "hbattery", "voidsworn"], ["lance", "lance", "voidsworn"],
		["torp", "torp", "voidsworn"], ["bio", "bioplasma", "chorus"], ["gauss", "gauss", "deathless"], ["lance", "ion", "hegemony"],
		["battery", "hturbo", "hegemony"], ["battery", "shard", "ithar"], ["torp", "htorp", "corsair"], ["torp", "startorp", "ithar"],
		["lance", "doom", "deathless"], ["battery", "autocannon", "hegemony"], ["battery", "scatter", "corsair"],
		["battery", "turret", "ithar"], ["lance", "pulsar", "ithar"], ["flak", "flak", "voidsworn"]]
	var seen := {}
	for calm in [false, true]:
		var wf: Array = _world(calm)
		var world: Node3D = wf[0]
		var fx = wf[1]
		var x := -60.0
		for lk in looks:
			_ship(world, fx, "A" + str(lk[1]) + str(lk[2]), "Cruiser", 1.0, Vector3(x, 0, 30), str(lk[2]))
			_ship(world, fx, "T" + str(lk[1]) + str(lk[2]), "Cruiser", 1.0, Vector3(x, 0, -30), "hegemony")
			x += 15.0
		await _advance(fx, 0.8)
		for lk in looks:
			fx.dstate["hit_logging"] = true
			fx.dstate["hit_log"] = []
			var t0: float = fx.now
			fx.volley("A" + str(lk[1]) + str(lk[2]), str(lk[0]), "T" + str(lk[1]) + str(lk[2]), {"weapon_id": str(lk[1]), "shots": [true],
				"hits": [{"shield": 0, "hull": 9, "section": "mid", "crit": false}]})
			await _advance(fx, 2.5)
			var log: Array = fx.dstate["hit_log"]
			if calm:
				continue
			seen["needle" if lk[1] == "turret" and lk[2] == "ithar" else str(lk[1])] = log.duplicate()
			_matter(str(lk[1]), log, fx, t0)
		if calm:
			_check(fx.flash_log.is_empty() and fx.flash_area_log.is_empty(), "reduce flashing: the new hits count and book no flash")
		else:
			# 5. light on neighbours: the torpedo's light reaches about two hexes (hexes are 17.3 across)
			var reach := 0.0
			fx.dstate["hit_logging"] = false
			fx.volley("Atorpvoidsworn", "torp", "Ttorpvoidsworn", {"weapon_id": "torp", "shots": [true], "hits": [{"shield": 0, "hull": 9, "section": "mid", "crit": false}]})
			for i in 240:
				fx.step(1.0 / 60.0)
				for e in fx._lev:
					if e.size() > 6:
						reach = maxf(reach, float(e[6]))
				await process_frame
			_check(reach >= 30.0, "a torpedo hit lights the hulls about two hexes round it (reach %.0f units)" % reach)
		fx.release()
		world.queue_free()
		await process_frame
	_recipes(seen)
	await _substance_hits()
	await _midflight_calm_check()
	await _yield_check()
	await _shield_torp_check()
	await _lance_kill()
	# issue 2161: the ember shader mixes its warm yellow-white start in only when the sprite does not keep its tint
	var at19: int = SH.SPRITE.find("} else if (k == 19) {")
	var body19: String = SH.SPRITE.substr(at19, SH.SPRITE.find("} else if (k == 21) {") - at19) if at19 >= 0 else ""
	_check(body19.contains("vKeep > 0.5 ? keep : vec3(1.0, 0.85, 0.5)") and not body19.contains("mix(vec3(1.0, 0.85, 0.5), vCol.rgb, t)"),
		"the ember shader keeps the warm start for metal only; a keep-tint ember starts violet-white")
	# 8. the engine core flicker and the scar cap
	_check(SH.SPRITE.find("flick(0.95 + 0.05 * vnoise(vec2(scene_t * 31.0") >= 0, "engine cores flicker 0.95 to 1.0 only")
	_check(SH.SPRITE.find("flick(0.85 + 0.15 * vnoise(vec2(scene_t * 31.0") < 0, "the old 0.85 to 1.0 engine flicker is gone")
	_check(BREACH.MARK_CAP >= 24 and BREACH.SEC_MARK_CAP >= 8, "wounds stay: %d marks a ship, %d a section" % [BREACH.MARK_CAP, BREACH.SEC_MARK_CAP])
	print("HIT_RECIPE failures=%d" % failures)
	quit(1 if failures > 0 else 0)


# Run each contact recipe on the same box with four different hull materials.
func _substance_hits() -> void:
	for look in ["macro", "torp", "gauss", "lance", "plasma", "crit"]:
		for faction in ["voidsworn", "ithar", "chorus", "deathless"]:
			var wf := _world(false)
			var world: Node3D = wf[0]
			var fx: FX = wf[1]
			_ship(world, fx, "impact_target", "Cruiser", 1.0, Vector3.ZERO, faction)
			var target = fx.ship("impact_target")
			var hit := {"shield": 0, "hull": 9, "section": "mid"}
			var from := Vector3(0, 0, 50)
			var tg := WEAP._target(fx, target, target.to_world(target.hull.c), from, true, hit, 1, 1.0)
			var weapon_tint := Color(1.0, 0.35, 0.08)
			fx.spr_kinds = {}
			if look == "crit":
				WEAP._crit(fx, target, tg, fx.now, 1.0, weapon_tint, 3)
			else:
				WEAP._impact(fx, look, 3, target, tg, fx.now, weapon_tint, Vector3.FORWARD, hit, 1.0, 0.4)
			var label := "%s on %s" % [look, faction]
			var plate: FRAGMENTS.Pool = fx.pools["plate"]
			var kinds: Dictionary = fx.spr_kinds
			var lamp: Color = fx._lev[-1][4] if not fx._lev.is_empty() else Color.BLACK
			if faction == "ithar":
				var glass_light: bool = lamp.is_equal_approx(target.fac.damage_glow) if look == "crit" \
					else lamp.r >= lamp.g and lamp.g > 0.9 and lamp.b > 0.7
				_check(glass_light and not kinds.has(27) and not kinds.has(19) and _glass_shards(plate),
					label + ": glass light and unheated crystal shards")
			elif faction == "chorus":
				_check(plate.emitted == 0 and kinds.has(15) and kinds.has(20) and not kinds.has(27) and not kinds.has(19)
					and lamp.g > lamp.r and lamp.r > lamp.b,
					label + ": bile, mist and amber-green light")
			elif faction == "deathless":
				var glow: Color = target.fac.damage_glow
				_check(lamp.is_equal_approx(glow) and not kinds.has(27) and _eclipse_ejecta(fx, glow),
					label + ": impact sparks and embers take the Eclipse damage glow with no soot")
			else:
				_check(plate.emitted > 0 and (look == "crit" or (kinds.has(27) and kinds.has(19))),
					label + ": metal keeps its plates, soot and embers")
				_check(_ember_spins(fx, 0.0), label + ": metal embers keep their hot yellow-white start (no keep-tint flag)")
			# The fire body starts on the second beat. Inspect the live pooled pictures after it would arrive.
			fx.now += 0.03
			fx._run_later()
			var flash := fx.get_node_or_null("fx_staged_flash") as MeshInstance3D
			var body := fx.get_node_or_null("fx_staged_body") as MeshInstance3D
			if faction == "ithar" or faction == "chorus" or faction == "deathless":
				var mat := flash.material_override as ShaderMaterial if flash != null else null
				var tint := Vector3(lamp.r, lamp.g, lamp.b)
				var prism := 1.0 if faction == "ithar" else 0.0
				_check(mat != null and mat.get_shader_parameter("impact_tinted") == 1.0 and mat.get_shader_parameter("impact_clean") == 1.0
					and mat.get_shader_parameter("impact_prism") == prism
					and (mat.get_shader_parameter("impact_tint") as Vector3).is_equal_approx(tint),
					label + ": flash renders with the same material tint as its light")
			var expect_body: bool = faction in ["voidsworn", "deathless"] and look in ["macro", "torp", "plasma"]
			_check((body != null) == expect_body, label + ": correct staged fire body")
			fx.release()
			world.queue_free()
			await process_frame


func _glass_shards(plate: FRAGMENTS.Pool) -> bool:
	if plate.emitted == 0:
		return false
	for j in plate.emitted:
		var particle: PackedFloat32Array = plate.particles[j]
		var key := int(particle[18])
		var profile := -1 - key if key < 0 else key
		if profile < FRAGMENTS.GLASS or particle[3] != 0.0:
			return false
	return true


# Every ember sprite (kind 19) booked so far carries this spin value.
func _ember_spins(fx: FX, want: float) -> bool:
	var sprites: POOLS.Pool = fx.pools["spr"]
	for i in range(0, sprites.pending.size(), POOLS.STRIDE * sprites.vpp):
		if int(sprites.pending[i + 18]) == 19 and not is_equal_approx(float(sprites.pending[i + 3]), want):
			return false
	return true


func _eclipse_ejecta(fx: FX, glow: Color) -> bool:
	var streaks: POOLS.Pool = fx.pools["stk"]
	var sprites: POOLS.Pool = fx.pools["spr"]
	var expected := Vector3(glow.r, glow.g, glow.b)
	if streaks.emitted == 0:
		return false
	for pool in [streaks, sprites]:
		for i in range(0, pool.pending.size(), POOLS.STRIDE * pool.vpp):
			if pool == sprites and int(pool.pending[i + 18]) != 19:
				continue
			# issue 2161 (Artoo on PR 1736): every Eclipse ember and spark keeps its tint from its first frame, never the
			# warm yellow-white a metal ember starts with (the sprite's spin channel, 3 floats into the particle)
			if pool == sprites and not is_equal_approx(float(pool.pending[i + 3]), WEAP.EMBER_KEEP):
				return false
			var tint := Vector3(pool.pending[i + 12], pool.pending[i + 13], pool.pending[i + 14])
			if not tint.is_equal_approx(expected) and not tint.is_equal_approx(expected * 0.35):
				return false
	return true


# 1. the ladder, from the sizing rule itself
func _ladder() -> void:
	var tg := {"gk": 1.0, "tk": 1.0}
	var las: float = WEAP.ladder_px("las", 1, tg)
	var macro: float = WEAP.ladder_px("macro", 2, tg)
	var lance: float = WEAP.ladder_px("lance", 3, tg)
	var torp: float = WEAP.ladder_px("torp", 3, tg)
	var shield_body: float = float(WEAP.LADDER_PX["torp_ripple"])
	var hull_body := 140.0
	print("ladder px: las %.0f macro %.0f lance %.0f torpedo %.0f (body %.0f) torpedo on a shield ripple %.0f" % [las, macro, lance, torp, hull_body, shield_body])
	_check(las * 1.2 <= macro and macro * 1.2 <= lance and lance * 1.5 <= torp, "the ladder steps up plainly: las < macro < lance < torpedo")
	_check(shield_body > hull_body, "a torpedo on a shield has the biggest body of any hit")
	var frig: float = WEAP.ladder_px("macro", 2, {"gk": WEAP.GUN_K["small"], "tk": 1.0})
	var bship: float = WEAP.ladder_px("macro", 2, {"gk": WEAP.GUN_K["capital"], "tk": 1.0})
	_check(frig < macro and macro < bship, "the gun sizes the hit: frigate %.0f, cruiser %.0f, capital %.0f px" % [frig, macro, bship])
	var on_small: float = WEAP.ladder_px("macro", 2, {"gk": 1.0, "tk": WEAP.TARGET_K["small"]})
	var on_cap: float = WEAP.ladder_px("macro", 2, {"gk": 1.0, "tk": WEAP.TARGET_K["capital"]})
	_check(on_small < macro and macro < on_cap, "the target sizes the hit too")


# 3 and 4: lives and directions of one hit's matter
func _matter(wid: String, log: Array, fx, t0: float) -> void:
	var bad_dir := 0
	var flash_long := 0
	var spark_long := 0
	var longest := {}
	for e in log:
		var what: String = e["what"]
		var life: float = float(e["life"])
		longest[what] = maxf(float(longest.get(what, 0.0)), life)
		if what == "flash" and life > WEAP.FLAME_CAP:
			flash_long += 1
		if what == "spark" and (life < WEAP.SPARK_LIFE.x or life > WEAP.SPARK_LIFE.y):
			spark_long += 1
		if what in ["spark", "debris", "gas", "ember", "drop"]:
			var v: Vector3 = e["v"]
			var n: Vector3 = e["n"]
			if v.length() > 1e-4 and v.normalized().dot(n.normalized()) <= 0.0:
				bad_dir += 1
	_check(not log.is_empty(), "%s: the hit made its recipe" % wid)
	_check(flash_long == 0, "%s: no flash outlives the 0.70 s flame cap" % wid)
	_check(spark_long == 0, "%s: cooling sparks stay within their own lifetime, separate from flame" % wid)
	_check(bad_dir == 0, "%s: everything thrown leaves the plate outward (%d inward)" % [wid, bad_dir])
	print("  %s lives: %s" % [wid, str(longest)])


# 2. a recipe per family, and thrown matter that lingers
func _recipes(seen: Dictionary) -> void:
	var kinds := {}
	for wid in seen:
		var k := {}
		var life := {}
		for e in seen[wid]:
			k[e["what"]] = int(k.get(e["what"], 0)) + 1
			life[e["what"]] = maxf(float(life.get(e["what"], 0.0)), float(e["life"]))
		kinds[wid] = [k, life]
	var sh: Dictionary = kinds.get("hbattery", [{}, {}])[0]
	var en: Dictionary = kinds.get("turret", [{}, {}])[0]
	var la: Dictionary = kinds.get("lance", [{}, {}])[0]
	var to: Dictionary = kinds.get("torp", [{}, {}])[0]
	var io: Dictionary = kinds.get("ion", [{}, {}])[0]
	_check(int(sh.get("debris", 0)) > 0 and int(sh.get("spark", 0)) >= 8, "shell: a spark cone and torn chips")
	_check(int(en.get("debris", 0)) == 0 and int(en.get("spark", 0)) > 0, "energy (las): a splash of drops, no torn plate")
	_check(int(la.get("heat", 0)) >= 4, "lance: the burn crawls (%d glowing points along its line)" % int(la.get("heat", 0)))
	_check(int(to.get("gas", 0)) >= 2 and int(to.get("debris", 0)) >= 6, "torpedo: gas and thrown debris")
	_check(int(io.get("spark", 0)) == 0, "ion: a lance burn with arcs and no molten spray")
	var to_life: Dictionary = kinds.get("torp", [{}, {}])[1]
	_check(float(to_life.get("debris", 0.0)) > 1.0 and float(to_life.get("gas", 0.0)) >= 2.0 and float(to_life.get("heat", 0.0)) >= 3.0,
		"torpedo: debris, gas and the wound's glow outlive the flame (%s)" % str(to_life))
	# the shell's sparks skip up off the plate in a cone; the energy splash skates along it
	var up_shell := _mean_up(seen.get("hbattery", []))
	var up_las := _mean_up(seen.get("turret", []))
	_check(up_las < 0.45 and up_shell > up_las + 0.15, "shell sparks skip off the plate (mean outward share %.2f), the energy splash runs along it (%.2f)" % [up_shell, up_las])


func _mean_up(log: Array) -> float:
	var sum := 0.0
	var n := 0
	for e in log:
		if e["what"] == "spark" and (e["v"] as Vector3).length() > 1e-4:
			sum += (e["v"] as Vector3).normalized().dot((e["n"] as Vector3).normalized())
			n += 1
	return sum / maxf(1.0, float(n))


# 7. a lance kill cuts clean on the beam's line
func _lance_kill() -> void:
	var wf: Array = _world(false)
	var world: Node3D = wf[0]
	var fx = wf[1]
	_ship(world, fx, "T", "Cruiser", 0.4, Vector3.ZERO, "voidsworn")
	var s = fx.ship("T")
	if not s.death_big:
		_check(false, "the lance kill check needs a big hull")
		return
	# the ship's own first cut is still on its worker (or not yet collected) when the lance kills it, as in a battle
	DEATH.precompute(fx, s)
	await _advance(fx, 0.1)
	var lp: Vector3 = s.hull.c + Vector3(s.hull.L * 0.2, 0.0, s.hull.W * 0.5)
	s.set_meta("last_hit", [lp, Vector3(0, 0, -1), fx.now])
	fx.death("T", "cut")
	var job: Dictionary = s.get_meta("cut_job", {})
	var plan: Dictionary = job.get("plan", {})
	_check(not plan.is_empty() and s.has_meta("lance_line"), "a lance kill re-plans its cut on the beam's line")
	if not plan.is_empty():
		var b: Dictionary = plan["breaks"][0]
		_check(absf(float(b["k"])) < 1e-6, "the lance cut has no kink")
		_check(absf((b["at"] as Vector3).x - lp.x) < s.hull.L * 0.06, "the lance cut lies on the beam's point (%.2f from it)" % absf((b["at"] as Vector3).x - lp.x))
		_check(absf((b["n"] as Vector3).y) < 1e-3, "the lance cut is not pitched")
	await _advance(fx, 5.0)
	_check(fx.dstate.has("wrecks") and not (fx.dstate["wrecks"] as Array).is_empty(), "the lance kill breaks up")
	fx.release()
	world.queue_free()
	await process_frame


# 9. a gun hit that would need counting is drawn soft; deaths keep the budget
func _yield_check() -> void:
	var wf: Array = _world(false)
	var world: Node3D = wf[0]
	var fx = wf[1]
	await _advance(fx, 0.2)
	var T: float = fx.now
	fx.flash_ok(T)
	var big: float = 200.0   # px: over the limit on its own
	var hit_ok: bool = fx.flash_at(Vector3.ZERO, T + 0.3, 0.0, big, 0.16, true)
	var hit2_ok: bool = fx.flash_at(Vector3.ZERO, T + 0.5, 0.0, big, 0.16, true)
	var core_ok: bool = fx.flash_at(Vector3.ZERO, T + 0.62, 0.0, big, 0.16)
	var core2_ok: bool = fx.flash_at(Vector3.ZERO, T + 0.8, 0.0, big, 0.16)
	_check(not hit_ok and not hit2_ok, "gun hit flashes that would need counting are drawn soft")
	_check(core_ok and core2_ok, "the second's slots stay free for deaths' core flashes")
	var small_ok: bool = fx.flash_at(Vector3(40, 0, 0), T + 0.9, 0.0, 40.0, 0.16, true)
	_check(small_ok, "a gun hit under the limit stays bright")
	var worst := 0
	for a in fx.flash_log:
		var n := 0
		for b in fx.flash_log:
			if float(b) > float(a) - 1.0 and float(b) <= float(a):
				n += 1
		worst = maxi(worst, n)
	_check(worst <= 3, "still never more than three counted flashes in a second")
	# opus_check_524b: soft flashes are bounded too. In one field, the flashes of the last second (counted and soft) fill
	# the cap, so the next yielded gun flash is told to draw no peak (fx.flash_lift); a second later the field is free again.
	var T2: float = T + 3.0
	var lifts: Array = []
	for i in 6:
		fx.flash_at(Vector3.ZERO, T2 + 0.1 * i, 0.0, big, 0.16, true)
		lifts.append(fx.flash_lift)
	_check(not lifts[0] and not lifts[1] and not lifts[2], "the first three soft gun flashes in a field keep their soft rise")
	_check(lifts[3] and lifts[4] and lifts[5], "the fourth and later in the same second lose their peak (a slow, dim lift)")
	fx.flash_at(Vector3.ZERO, T2 + 1.7, 0.0, big, 0.16, true)
	_check(not fx.flash_lift, "a second later the field takes soft flashes again")
	fx.release()
	world.queue_free()
	await process_frame


# 10. a torpedo on a shield draws and books at its row (110 px times the gun and the target), not half again bigger
func _shield_torp_check() -> void:
	var wf: Array = _world(false)
	var world: Node3D = wf[0]
	var fx = wf[1]
	_ship(world, fx, "A", "Cruiser", 1.0, Vector3(0, 0, 30), "voidsworn")
	_ship(world, fx, "T", "Cruiser", 1.0, Vector3(0, 0, -30), "hegemony")
	await _advance(fx, 0.8)
	var Tg = fx.ship("T")
	_check(Tg.shielded and Tg._shield_mat != null, "the Hegemony box ship has its shield up")
	fx.dstate["hit_logging"] = true
	fx.dstate["hit_log"] = []
	var n0: int = fx.flash_area_log.size()
	fx.volley("A", "torp", "T", {"weapon_id": "torp", "shots": [true], "hits": [{"shield": 8, "hull": 0, "section": "mid", "crit": false}]})
	await _advance(fx, 2.5)
	var row_px := 0.0
	for e in fx.dstate["hit_log"]:
		if e["what"] == "flash" and e["fam"] == "shield":
			row_px = float(e["px"])
	var booked := 0.0
	for r in fx.flash_area_log.slice(n0):
		booked = maxf(booked, float(r[3]))
	print("  shield torpedo: row %.0f px, booked %.0f px, limit disc %.0f px" % [row_px, booked, 2.0 * sqrt(fx.flash_limit_px2() / PI)])
	_check(row_px > 0.0 and booked > 0.0 and booked <= row_px * 1.05 + 1.0, "a torpedo on a shield books at its row's size, not bigger")
	fx.release()
	world.queue_free()
	await process_frame
