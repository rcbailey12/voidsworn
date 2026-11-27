extends SceneTree
# Issue 1955: damage emitter skips, surface-only wreck materials, point-defense pops and a live quality downgrade.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
const RULES := preload("res://rules/rules.gd")
const LOOK := preload("res://render/look.gd")
const RIM := preload("res://render/look_rim.gd")
const NEBULA_HULLS := preload("res://world/nebula_hulls.gd")
const LINE_STYLE := preload("res://render/line_style.gd")
const STATIC_CACHES := preload("res://render/static_caches.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "graphics_correctness_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if ok:
		print("  ok: ", message)
	else:
		failures += 1
		printerr("FAIL: ", message)


func _damage_emitters(world: Node3D, fx) -> void:
	var body := Node3D.new()
	world.add_child(body)
	var core := Marker3D.new()
	core.name = "hp_core"
	body.add_child(core)
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	part.mesh = box
	body.add_child(part)
	fx.add_ship("damage", body, {"faction": "voidsworn", "cls": "Cruiser", "size": 0.8, "meshes": [part], "shielded": false})
	var ship = fx.ship("damage")
	# Seed the same anchor cache used when the hull lookup cannot find a point in a section.
	ship._anchors["a0"] = {}
	ship._anchors["a1"] = {"p": Vector3(0, 2.5, 0), "n": Vector3.UP, "t": {}}
	ship.stage = [3, 2, 0]
	ship._refresh_damage_emitters(fx)
	var ids: Array = ship._damage_emitters.map(func(e): return e.id)
	_check(ids == ["smoke1"], "a missing anchor allocates nothing while the supported section emits smoke")
	var counts: Dictionary = ship.damage_counts()
	_check(counts.smoke == 1 and counts.fire == 0 and counts.particles > 0, "counts include only built emitters")
	ship.dead = true
	ship._update_damage_emitters(fx)
	ship.dead = false
	ship.stage = [0, 0, 0]
	ship._refresh_damage_emitters(fx)
	fx.now += 0.81
	ship._update_damage_emitters(fx)
	_check(ship._fading_emitters.is_empty() and ship.damage_counts().particles == 0, "repair fades and frees the live emitter")
	fx.remove_ship("damage")


func _surface_part(world: Node3D, mat: Material) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BoxMesh.new().get_mesh_arrays())
	mesh.surface_set_material(0, mat)
	var part := MeshInstance3D.new()
	part.mesh = mesh
	world.add_child(part)
	return part


func _wreck_materials(world: Node3D) -> void:
	var paint := StandardMaterial3D.new()
	paint.set_meta("look_hull", true)
	var base_shader := Shader.new()
	base_shader.code = "shader_type spatial;\nuniform float heat = 0.0;\nvoid fragment() { ALBEDO = vec3(heat); }"
	var wreck := ShaderMaterial.new()
	wreck.shader = base_shader
	wreck.set_shader_parameter("heat", 0.25)
	wreck.set_meta("fx_hull_source", paint)
	var debris := wreck.duplicate() as ShaderMaterial
	var half := _surface_part(world, wreck)
	var fragment := _surface_part(world, debris)
	var rim := RIM.new()
	world.add_child(rim)
	world.add_child(NEBULA_HULLS.new())
	_check((half.layers & LOOK.RIM_LAYER) != 0 and (fragment.layers & LOOK.RIM_LAYER) != 0, "surface-only wreck materials receive rim light")
	_check(wreck.shader.code.contains("fog_disabled") and wreck.shader == debris.shader, "wreck surfaces reuse the fog-disabled variant")
	_check(not base_shader.code.contains("fog_disabled") and is_equal_approx(float(wreck.get_shader_parameter("heat")), 0.25),
		"fog protection preserves the shared source shader and the hull's uniform")


func _flak_pops(world: Node3D, fx) -> void:
	var start: float = fx.now
	WEAP._shot_down(fx, {"a": Vector3.ZERO, "b": Vector3(5, 0, 0), "c": Vector3(10, 0, 0),
		"t0": start - 0.5, "dead_at": start, "t1": start + 0.5, "k": 1.0, "mesh": null})
	var seen := {}
	for i in 41:
		for pop in world.find_children("*", "MeshInstance3D", true, false):
			if pop.get_meta("fx_picture_kind", "") != "flash" or not pop.visible:
				continue
			var mat: ShaderMaterial = pop.material_override
			var born: float = mat.get_shader_parameter("born")
			var life: float = mat.get_shader_parameter("lifetime")
			if fx.now >= born and fx.now < born + life:
				seen[roundi((born - start) * 1000.0)] = true
		fx.step(0.005)
	var starts := seen.keys()
	starts.sort()
	_check(starts == [0, 45, 90, 135, 180], "all five point-defense pops are alive on cue: %s ms" % str(starts))


func _add_flak_escort(world: Node3D, fx, id: String, at: Vector3) -> void:
	var body := Node3D.new()
	world.add_child(body)
	body.position = at
	var part := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(24, 5, 8)
	part.mesh = box
	body.add_child(part)
	var core := Marker3D.new()
	core.name = "hp_core"
	body.add_child(core)
	fx.add_ship(id, body, {"faction": "voidsworn", "cls": "Frigate", "meshes": [part], "shielded": false})


func _indexed_intercepts() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	fx.compat = false
	var rules := RULES.new()
	var first := {"id": "first", "side": "player", "intercepts": 1, "weapons": [{"k": "flak", "r": 3}], "q": 0, "r": 1}
	var second := {"id": "second", "side": "player", "intercepts": 1, "weapons": first.weapons, "q": 1, "r": 0}
	var target := {"id": "target", "side": "player", "intercepts": 0, "q": 0, "r": 0}
	rules.B = {"units": [first, second, target]}
	# Seed 1 makes the first escort fail at index 1 and stop index 2, then the second stops index 1.
	var shots := [false, true, true, true]
	var res := {}
	rules.rng.rnd_seed(1)
	rules.rocketDefense({"rockets": true}, target, shots, res)
	var pd_by_shot: Dictionary = res.get("pd_by_shot", {})
	_check(shots == [false, false, false, true] and res.get("pd") == 2 and first.intercepts == 0 and second.intercepts == 0,
		"ship defence keeps the same roll results, intercept count and charges")
	_check(pd_by_shot == {2: "first", 1: "second"}, "rules attach each flak ship to the shot it stopped")
	_add_flak_escort(world, fx, "first", Vector3(15, 0, 30))
	_add_flak_escort(world, fx, "second", Vector3(15, 0, -30))
	fx.volley_at(Vector3(-85, 0, 4), "torp", Vector3(85, 5, 18),
		{"weapon_id": "torp", "shots": shots, "pd": res.get("pd", 0), "pd_by_shot": pd_by_shot})
	var projectiles: Array = fx.dstate.get("proj", [])
	var intercepted := projectiles.map(func(p): return is_finite(float(p.dead_at)))
	_check(intercepted == [false, true, true, false], "the ordinary miss and the hit both fly past the PD intercept beat")
	var cue_ends: Array = fx.dstate.get("pd_puff_ends", [])
	_check(cue_ends.size() == 6, "each defender adds one three-puff cue")
	var matched := {}
	for i in 180:
		fx.step(0.02)
		for node in world.find_children("*", "MeshInstance3D", true, false):
			if node.get_meta("fx_picture_kind", "") != "cool":
				continue
			var mat := node.material_override as ShaderMaterial
			if not is_equal_approx(float(mat.get_shader_parameter("lifetime")), WEAP.PD_PUFF_LIFE):
				continue
			var end := float(mat.get_shader_parameter("born")) + WEAP.PD_PUFF_LIFE
			for j in cue_ends.size():
				var correct_side: bool = node.global_position.z < -20.0 if j < 3 else node.global_position.z > 20.0
				if correct_side and absf(end - float(cue_ends[j])) < 0.001:
					matched[j] = true
		if matched.size() == 6:
			break
	_check(matched.size() == 6, "shot 1 cues the second escort and shot 2 cues the first, despite reverse interception order")
	world.free()


func _defender_flak(world: Node3D, fx) -> void:
	var toward := Vector3(85, 5, 18)
	_add_flak_escort(world, fx, "escort", Vector3.ZERO)
	var defender = fx.ship("escort")
	var muzzle := WEAP._pd_origin(defender, Vector3(-85, 0, 4))
	_check(muzzle.is_finite(), "the firing ship gives PD a real surface point")
	# A salvo's many visible rocket bodies must not each spawn a cue. The defender is not the target.
	var shots := [false, false]
	var opts := {"weapon_id": "htorp", "shots": shots, "pd": 2}
	fx.volley_at(Vector3(-85, 0, 4), "torp", toward, opts)
	_check(fx.dstate.get("pd_puff_ends", []).is_empty(), "an interception with no ship attributed adds no near-ship puffs")
	opts["pd_by_shot"] = {0: "escort", 1: "escort"}
	fx.volley_at(Vector3(-85, 0, 4), "torp", toward, opts)
	var ends: Array = fx.dstate.get("pd_puff_ends", [])
	_check(ends.size() == 3, "two intercepted rocket groups make only one three-puff cue at their defender")
	var seen := 0
	var near := true
	for i in 150:
		fx.step(0.02)
		for node in world.find_children("*", "MeshInstance3D", true, false):
			if node.get_meta("fx_picture_kind", "") != "cool" or node.has_meta("seen_2249"):
				continue
			var mat := node.material_override as ShaderMaterial
			if not is_equal_approx(float(mat.get_shader_parameter("lifetime")), WEAP.PD_PUFF_LIFE):
				continue
			node.set_meta("seen_2249", true)
			seen += 1
			near = near and node.global_position.distance_to(muzzle) < 8.0
		if seen >= 3:
			break
	_check(seen == 3 and near, "the PD-C puffs appear at the firing ship, away from the incoming target (%d seen, near: %s)" % [seen, near])
	fx.step(WEAP.PD_PUFF_LIFE + 0.2)
	var stress_start: float = fx.now
	var rng_before: int = fx.rng.state
	for i in 30:
		fx.pd_flak("escort", toward)
	_check(fx.rng.state == rng_before, "extra puffs leave the seeded paths of later rounds alone")
	fx.step(0.1)
	var live := 0
	for node in world.find_children("*", "MeshInstance3D", true, false):
		if node.get_meta("fx_picture_kind", "") != "cool":
			continue
		var mat := node.material_override as ShaderMaterial
		if is_equal_approx(float(mat.get_shader_parameter("lifetime")), WEAP.PD_PUFF_LIFE) and float(mat.get_shader_parameter("born")) >= stress_start - 0.001:
			live += 1
	_check(ends.size() == 12 and live == 12, "overlapping point-defence cues cap live and pending puffs at twelve")
	fx.step(WEAP.PD_PUFF_LIFE + 0.2)
	fx.pd_flak("escort", toward)
	_check(ends.size() == 3, "the cap gives the slots back after the puffs expire")


func _quality_downgrade() -> void:
	var env := Environment.new()
	# Enable the old Max SSIL option so the downgrade must turn off both passes.
	var old := OS.get_environment("VS_1262_OLD")
	OS.set_environment("VS_1262_OLD", "ssil")
	for quality in ["high", "low"]:
		LOOK.apply(env, null, null, {"quality": "max"})
		_check(env.ssao_enabled and env.ssil_enabled, "Max starts with both passes in the SSIL test mode")
		LOOK.apply(env, null, null, {"quality": quality})
		_check(not env.ssao_enabled and not env.ssil_enabled, "Max to %s turns off both passes" % quality)
	OS.set_environment("VS_1262_OLD", old)


func _shader_cache() -> void:
	var steady := LINE_STYLE.material()
	var breathing := LINE_STYLE.material(true)
	_check(steady != breathing and steady.shader == breathing.shader, "line materials share shader code and own their uniforms")
	_check(steady.get_shader_parameter("breath") != breathing.get_shader_parameter("breath"), "sharing keeps each line's breath setting")
	STATIC_CACHES.clear_all()
	_check(LINE_STYLE.material().shader != steady.shader, "the shutdown registry clears the shader cache")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high"})
	fx.compat = false
	_damage_emitters(world, fx)
	_wreck_materials(world)
	_flak_pops(world, fx)
	_defender_flak(world, fx)
	_quality_downgrade()
	world.free()
	_indexed_intercepts()
	_shader_cache()
	STATIC_CACHES.clear_all()
	print("GRAPHICS_CORRECTNESS failures=", failures)
	quit(1 if failures else 0)
