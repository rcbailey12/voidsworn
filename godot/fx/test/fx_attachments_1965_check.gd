extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const FX := preload("res://fx/fx.gd")
const BREACH := preload("res://fx/fx_breach.gd")
const DEATH := preload("res://fx/fx_death.gd")

var failures := 0


func _init() -> void:
	GUARD.arm(self, "fx_attachments_1965_check", 15.0)
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _pivot(parent: Node3D, label: String) -> Node3D:
	var node := Node3D.new()
	node.name = label
	parent.add_child(node)
	return node


func _box(parent: Node3D, label: String, size: Vector3, at: Vector3) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = StandardMaterial3D.new()
	part.position = at
	parent.add_child(part)
	return part


func _check_attachments(fx: FX, world: Node3D) -> void:
	var view := _pivot(world, "attachment_fixture")
	view.position = Vector3(8, 2, -6)
	view.rotation.y = 0.7
	var pivot := _pivot(view, "hull_pivot")
	var skin := _box(pivot, "plating", Vector3(14, 3, 5), Vector3(2, 0.4, 0))
	skin.scale = Vector3.ONE * 1.25
	var turret_pivot := _pivot(pivot, "turret_0")
	var turret := _box(turret_pivot, "gun", Vector3.ONE, Vector3(3, 2, 0))
	var door_pivot := _pivot(pivot, "door_0")
	var lobe := _box(door_pivot, "door_0_lobe_0", Vector3.ONE, Vector3(0, 0, 3))
	var door := _box(pivot, "door_1", Vector3.ONE, Vector3(0, 0, -3))
	var moving := [turret, lobe, door]
	var originals := moving.map(func(part: MeshInstance3D) -> Material: return part.material_override)
	fx.add_ship("attachments", view, {"faction": "voidsworn", "meshes": moving + [skin]})
	var ship := fx.ship("attachments")
	ship.ensure_damage_surfaces(fx)
	_check(skin.get_surface_override_material(0) is ShaderMaterial, "static plating gets the early damage material")
	for i in moving.size():
		var part: MeshInstance3D = moving[i]
		_check(part.material_override == originals[i] and part.get_surface_override_material(0) == null,
			"%s keeps its original material" % part.name)
	turret_pivot.rotation.y = 0.65
	lobe.rotation.x = 1.0
	door.rotation.x = -0.75
	var surfaces := BREACH.gather(ship).map(func(surface: Dictionary) -> MeshInstance3D: return surface["mi"])
	_check(surfaces == [skin], "breach gather includes plating and excludes the turned turret and bay doors")

	var shield := ship._shield_mi
	_check(shield.get_parent() == ship._dmg_root.get_parent(), "shield and damage use the same hull attachment")
	_check(shield.global_transform.is_equal_approx(ship.xf() * ship._shield_pose), "shield keeps its build pose")
	pivot.transform = Transform3D(Basis(Vector3.FORWARD, 0.2), Vector3.UP * 0.25)
	_check(shield.global_transform.is_equal_approx(ship.xf() * ship._shield_pose), "shield follows hull motion before any FX step")
	ship.install_shield_skin(skin.mesh.surface_get_arrays(0), Vector3.ZERO)
	_check(shield.global_transform.is_equal_approx(ship.xf() * ship._shield_pose), "fitted skin keeps the shield in the hull frame")
	var before_hide := shield.global_transform
	ship.hide_live_hull()
	shield.show()
	_check(shield.is_visible_in_tree() and shield.global_transform.is_equal_approx(before_hide),
		"an active shield collapse can still draw in place after the hull hides")
	fx.remove_ship("attachments")


func _check_late_debris(fx: FX, world: Node3D) -> void:
	var view := _pivot(world, "death_fixture")
	_box(view, "plating", Vector3(20, 4, 6), Vector3.ZERO)
	fx.add_ship("eclipse", view, {"faction": "deathless", "cls": "Cruiser", "size": 1.0})
	var ship := fx.ship("eclipse")
	var rgb: Array = ship.fac["death"]["rim"]
	var expected := Color(rgb[0], rgb[1], rgb[2])
	fx.death("eclipse")
	for frame in 360:
		fx.step(1.0 / 60.0)
		if ship.has_meta("death_hidden"):
			break
		await process_frame
	_check(fx.wreck_pieces("eclipse") >= 2, "the cruiser split into real wreck pieces")
	var debris: Array = fx.dstate["debris"]
	var before := debris.size()
	fx.remove_ship("eclipse")
	_check(fx.ship("eclipse") == null and ship.gone, "the live hull record is gone before the core throws its debris")
	for frame in 30:
		fx.step(1.0 / 60.0)
		if debris.size() > before:
			break
		await process_frame
	_check(debris.size() > before, "the delayed core threw debris after teardown")
	for i in range(before, debris.size()):
		var piece: Dictionary = debris[i].get_meta("debris_piece", {})
		_check(piece.get("leash") == "eclipse" and DEATH._debris_rim(piece).is_equal_approx(expected),
			"delayed debris keeps Eclipse's rim and wreck leash")


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx := FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "high", "shake": 0.0})
	fx.defer_initial_cuts = true
	fx.dstate["physics_on"] = true
	_check_attachments(fx, world)
	await _check_late_debris(fx, world)
	fx.release()
	world.queue_free()
	await process_frame
	print("FX_ATTACHMENTS_1965 %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
