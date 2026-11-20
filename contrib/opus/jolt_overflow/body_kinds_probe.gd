extends SceneTree
var t0 := 0
var gid := -1
var frames := 0
var kind := ""
var bodies: Array = []
func _initialize() -> void:
	kind = OS.get_environment("KIND")
	var n := OS.get_processor_count()
	for i in 6:
		var b: PhysicsBody3D
		match kind:
			"static": b = StaticBody3D.new()
			"anim_still": b = AnimatableBody3D.new()
			"anim_moving": b = AnimatableBody3D.new(); (b as AnimatableBody3D).sync_to_physics = false
			"rigid_sleep": b = RigidBody3D.new(); (b as RigidBody3D).gravity_scale = 0; (b as RigidBody3D).sleeping = true
			"rigid_still": b = RigidBody3D.new(); (b as RigidBody3D).gravity_scale = 0
			"rigid_freeze": b = RigidBody3D.new(); (b as RigidBody3D).freeze = true; (b as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		var cs := CollisionShape3D.new(); cs.shape = BoxShape3D.new(); b.add_child(cs)
		b.position = Vector3(i * 3, 0, 0); root.add_child.call_deferred(b); bodies.append(b)
	await create_timer(2.0).timeout
	gid = WorkerThreadPool.add_group_task(func(_i: int) -> void:
		var e := Time.get_ticks_msec() + 2000
		while Time.get_ticks_msec() < e: pass, n * 2, n, true, "saturate")
	t0 = Time.get_ticks_msec()
func _process(_d: float) -> bool:
	if kind == "anim_moving":
		for b in bodies: if b.is_inside_tree(): b.position.z += 0.01
	return false
func _physics_process(_d: float) -> bool:
	if gid < 0: return false
	frames += 1
	if Time.get_ticks_msec() - t0 > 6000:
		WorkerThreadPool.wait_for_group_task_completion(gid)
		print(kind, " frames=", frames)
		return true
	return false
