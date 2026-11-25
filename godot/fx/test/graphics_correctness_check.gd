extends SceneTree
# Issue 1955: damage emitter skips, surface-only wreck materials, point-defense pops and a live quality downgrade.
const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const WEAP := preload("res://fx/fx_weapons.gd")
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
	_quality_downgrade()
	world.free()
	_shader_cache()
	STATIC_CACHES.clear_all()
	print("GRAPHICS_CORRECTNESS failures=", failures)
	quit(1 if failures else 0)
