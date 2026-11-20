extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Issue 1289: the arrival warm kit (render/arrival_warm.gd) that battle._warmup uses for its reinforcement's hull. The kit
# builds the hull as an arriving ship is built (ShipView.setup, fx.add_ship), so the load's prepare_battle_hulls and
# warm-up treat it as one of the battle's ships; park() takes it out of the effects and hides it without freeing it (its
# model and paint stay loaded); release() frees it. Headless: the hull may be a placeholder block, the steps are the same.
const FX := preload("res://fx/fx.gd")
const KIT := preload("res://render/arrival_warm.gd")
var failures := 0


func _init() -> void:
	GUARD.arm(self, "arrival_warm_check")
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func check(ok: bool, why: String) -> void:
	if not ok:
		failures += 1
		push_error("ARRIVAL_WARM " + why)


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var fx = FX.new()
	world.add_child(fx)
	fx.manual = true
	fx.setup({"quality": "low", "camera": null, "shake": 0.0})
	fx.defer_initial_cuts = true
	var kit = KIT.new()
	kit.prepare(world, fx, [{"id": "arrival_warm_0", "side": "enemy", "tpl": "h_picket", "fac": "hegemony", "cls": "Frigate",
		"size": 1.0, "facing": 3, "squadron": false, "flagship": false, "hp": 10, "maxHp": 10}], Vector3.ZERO)
	check(kit.views.size() == 1, "one preview expected, got %d" % kit.views.size())
	var sv = kit.views[0]["sv"] if kit.views.size() == 1 else null
	check(sv != null and sv.get_parent() == world and sv.visible, "the preview is in the scene and drawn for the warm-up")
	check(fx.ships.has("arrival_warm_0"), "the preview is one of the effects' ships, so the load cuts and warms it")
	kit.park()
	check(not fx.ships.has("arrival_warm_0"), "after the warm-up the preview has left the effects")
	check(is_instance_valid(sv) and not sv.visible and sv.process_mode == Node.PROCESS_MODE_DISABLED, "the parked preview is hidden and not processed")
	check(is_instance_valid(sv) and sv.is_inside_tree(), "the parked preview stays in the scene, so its hull stays loaded")
	kit.release()
	await process_frame
	check(not is_instance_valid(sv), "release frees the preview")
	world.queue_free()
	await process_frame
	print("ARRIVAL_WARM ", "PASS" if failures == 0 else "FAIL %d" % failures)
	quit(0 if failures == 0 else 1)
