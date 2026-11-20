extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1237 (Neon ship destruction audit, F7.1 to F7.3): three capitals killed on the same frame, then three more.
# Death pictures come from the reused pool (the second wave builds almost none), every debris plate is at rest by 8 s
# after its kill, every wreck section has left Jolt after its physics window, every power-down finishes, and the shared
# power-down budget holds for the frame. Headless, so it counts nodes and bodies; frame times are the PC capture's job.
const FX := preload("res://fx/fx.gd")
const DEATH := preload("res://fx/fx_death.gd")
var failures := 0

func _init() -> void:
	GUARD.arm(self, "multi_death_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _hull(world: Node3D, fx, id: String, at: Vector3) -> void:
	var r := Node3D.new()
	world.add_child(r)
	r.position = at
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(40, 5, 8)
	box.subdivide_width = 23; box.subdivide_height = 3; box.subdivide_depth = 5
	mi.mesh = box
	r.add_child(mi)
	fx.add_ship(id, r, {"faction": "voidsworn", "cls": "Battleship", "size": 1.0, "meshes": [mi]})

func _wave(world: Node3D, fx, tag: String) -> Dictionary:
	var ids: Array = []
	for k in 3:
		var id := "%s%d" % [tag, k]
		_hull(world, fx, id, Vector3(-60 + k * 60, 0, 0))
		ids.append(id)
	for i in 30:
		fx.step(1.0 / 60.0)
		await process_frame
	var t0: float = fx.now
	for id in ids: fx.death(id, "blast")
	var rest_at := -1.0
	var queues_done_at := -1.0
	var peak_awake := 0
	var power_frames: Array = []
	while fx.now - t0 < 12.0:
		var spent_before := int(fx.dstate.get("power_spent", 0))
		fx.step(1.0 / 60.0)
		await process_frame
		if int(fx.dstate.get("power_frame", -1)) == fx.step_count:
			power_frames.append(int(fx.dstate.get("power_spent", 0)))
		var awake := DEATH.debris_awake(fx)
		peak_awake = maxi(peak_awake, awake)
		if awake == 0 and rest_at < 0.0 and fx.now - t0 > 3.0: rest_at = fx.now - t0
		if awake > 0: rest_at = -1.0
		var queued := false
		for id in ids:
			var s = fx.ship(id)
			if s != null and s.has_meta("death_power_queue"): queued = true
		if not queued and queues_done_at < 0.0: queues_done_at = fx.now - t0
	var in_jolt := 0
	var sections := 0
	for w in fx.dstate.get("wrecks", []):
		for nd in w["nodes"]:
			if nd is RigidBody3D:
				sections += 1
				if nd.process_mode != Node.PROCESS_MODE_DISABLED: in_jolt += 1
	return {"rest_at": rest_at, "peak_awake": peak_awake, "queues_done_at": queues_done_at, "in_jolt": in_jolt,
		"sections": sections, "power_max": power_frames.max() if not power_frames.is_empty() else 0, "ids": ids}

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "max", "shake": 0.0})
	var a: Dictionary = await _wave(world, fx, "A")
	var pics = fx.pictures()
	var made_a: int = pics.made
	check(made_a > 0, "the deaths drew pictures from the pool")
	check(a.peak_awake > 0, "the deaths threw debris plates (%d at the peak)" % a.peak_awake)
	check(a.rest_at >= 0.0 and a.rest_at <= 8.0, "every plate at rest within 8 s (%.2f s)" % a.rest_at)
	check(a.sections >= 6, "three capitals left their wreck sections (%d)" % a.sections)
	check(a.in_jolt == 0, "every wreck section has left Jolt after its window (%d still in)" % a.in_jolt)
	check(a.queues_done_at >= 0.0 and a.queues_done_at < 1.0, "every power-down finished inside 1 s (%.2f s)" % a.queues_done_at)
	# one surface may finish past the line; three ships each at 4 ms was the old worst case
	check(int(a.power_max) <= DEATH.POWER_BUDGET * 2, "the power-down budget is shared by the frame (%d us at most)" % int(a.power_max))
	for id in a.ids: fx.clear_wreck(id)
	var b: Dictionary = await _wave(world, fx, "B")
	var made_b: int = pics.made - made_a
	check(pics.reused > 0, "the second wave reused pooled pictures (%d)" % pics.reused)
	check(made_b * 4 <= made_a, "the second wave built at most a quarter as many pictures (%d against %d)" % [made_b, made_a])
	check(b.rest_at >= 0.0 and b.rest_at <= 8.0, "second wave: every plate at rest within 8 s (%.2f s)" % b.rest_at)
	for i in 600: fx.step(1.0 / 60.0)
	var stray := 0
	for node in fx.get_children():
		if node is MeshInstance3D and node.has_meta("pic_key") and not bool(node.get_meta("pic_live", false)):
			if node.visible or node.has_meta("fx_picture_kind"): stray += 1
	check(stray == 0, "a returned picture is hidden and stripped (%d not)" % stray)
	check(pics.live == 0, "every picture went back to the pool (%d still out)" % pics.live)
	print("MULTI_DEATH made=%d then %d reused=%d free=%d rest=%.2f/%.2f s peak_plates=%d sections=%d power_max=%d us" % [
		made_a, made_b, pics.reused, pics.free_count(), a.rest_at, b.rest_at, a.peak_awake, a.sections, int(a.power_max)])
	world.queue_free()
	await process_frame
	print("multi_death_check: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
