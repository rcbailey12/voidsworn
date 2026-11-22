extends SceneTree
const GUARD = preload("res://tools/ci/check_guard.gd")
# Exercise ShipView and FX together, as battle.gd does when it marks a view dead.
const FX := preload("res://fx/fx.gd")
const SV := preload("res://render/ship_view.gd")
const DEATH := preload("res://fx/fx_death.gd")
const API := preload("res://rules/battle_api.gd")
var rules_api := API.new()
var failures := 0

class LogFixture extends CanvasLayer:
	func add_log(_text: String, _kind: String) -> void:
		pass

class BattleFixture extends "res://scenes/battle/battle.gd":
	var trace_id := ""
	var hull_trace: Array[float] = []
	var rise_sections: Array = []

	func _ready() -> void:
		set_process(false)

	func _float(_id, _text: String, _col: Color, _dy := 0.0) -> void:
		pass

	func _tip_completed(e: Dictionary) -> void:
		super._tip_completed(e)
		if trace_id.is_empty() or e.get("unit") != trace_id or e["t"] not in ["risen", "tick"]:
			return
		hull_trace.append(float(disp[trace_id]["hp"]))
		if e["t"] == "risen":
			rise_sections = gfx.ship(trace_id).section_fraction.duplicate()

func _init() -> void:
	GUARD.arm(self, "death_plane_check")  # issue 632: a SCRIPT ERROR or a stuck run ends the check, never waits
	process_frame.connect(_run, CONNECT_ONE_SHOT)

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _verdict(before: int, name: String) -> void:
	print("%s %s" % ["PASS" if before == failures else "FAIL", name])

func _lifetime_battle() -> BattleFixture:
	var battle := BattleFixture.new()
	root.add_child(battle)
	battle.TBL = rules_api.R.TB
	battle.board = battle.Board.new()
	battle.add_child(battle.board)
	battle.gfx = FX.new()
	battle.add_child(battle.gfx)
	battle.gfx.manual = true
	battle.gfx.setup({"quality": "high"})
	# The headless renderer can pick Compatibility. Exercise the real hull collision layer anyway.
	battle.gfx.dstate["physics_on"] = true
	return battle

func _lifetime_ship(battle: BattleFixture, id: String) -> MeshInstance3D:
	var sv := SV.new()
	battle.add_child(sv)
	sv.set_process(false)
	sv.hull = Node3D.new()
	sv.add_child(sv.hull)
	sv.ring = MeshInstance3D.new()
	sv.add_child(sv.ring)
	sv.hull_base = Vector3(0, 0.5, 0)
	sv.hull_basis = Basis(Vector3.UP, 0.3)
	sv.hull.transform = Transform3D(sv.hull_basis, sv.hull_base)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(12, 3, 4)
	box.subdivide_width = 11
	box.subdivide_height = 2
	box.subdivide_depth = 3
	mesh.mesh = box
	mesh.position.x = 0.2
	mesh.set_surface_override_material(0, StandardMaterial3D.new())
	sv.hull.add_child(mesh)
	sv.meshes = [mesh]
	if sv.has_method("_remember_live_hull"):
		sv.call("_remember_live_hull")
	battle.views[id] = sv
	battle.VU[id] = {"id": id, "fac": "deathless", "cls": "Cruiser", "size": 0.76, "name": id, "side": "enemy",
		"hp": 35.0, "maxHp": 100.0, "sh": [0.0, 0.0, 0.0, 0.0], "squadron": false, "flagship": false}
	battle.gfx.add_ship(id, sv, {"faction": "deathless", "cls": "Cruiser", "size": 0.76, "meshes": sv.meshes})
	return mesh

func _exit_with_cut() -> void:
	var before := failures
	var battle := _lifetime_battle()
	_lifetime_ship(battle, "exit")
	_lifetime_ship(battle, "removed")
	var fx = battle.gfx
	var s = fx.ship("exit")
	var gate := Semaphore.new()
	var work := func() -> void: gate.wait()
	var tasks: Array[int] = []
	for id in ["exit", "removed"]:
		var tid: int = fx.call("submit_death_cut", work) if fx.has_method("submit_death_cut") else WorkerThreadPool.add_task(work)
		fx.ship(id).set_meta("cut_task", tid)
		tasks.append(tid)
	fx.death("exit", "cut")  # the lance cut detaches the blocked task and submits a real cut
	tasks.append(int(s.get_meta("cut_task")))
	fx.remove_ship("removed")
	_check(not WorkerThreadPool.is_task_completed(tasks[0]), "detached cut is unfinished before scene exit")
	var unblock := Thread.new()
	unblock.start(func() -> void:
		OS.delay_msec(100)
		gate.post()
		gate.post())
	# Issue 1435: scene exit no longer waits for running cuts on the caller; it retires them (none lost) and quit drains
	# them (FX.clear_static, from static_caches clear_all), so every task is joined before the rendering server goes.
	battle.free()
	_check(FX.retired_count() >= 1, "scene exit retired the running cuts instead of dropping them (%d)" % FX.retired_count())
	unblock.wait_to_finish()
	FX.clear_static()
	_check(FX.retired_count() == 0, "quit drained every retired cut")
	for tid in tasks:
		# Godot reports an invalid ID here if the FX session already joined it. Silence that deliberate probe.
		Engine.print_error_messages = false
		var result := WorkerThreadPool.wait_for_task_completion(tid)
		Engine.print_error_messages = true
		_check(result == ERR_INVALID_PARAMETER, "scene exit left worker task %d unjoined" % tid)
	_verdict(before, "death-cut workers retired on battle exit and joined by quit")

func _risen_takes_wreck() -> void:
	var before := failures
	var battle := _lifetime_battle()
	var mesh := _lifetime_ship(battle, "risen")
	var sv = battle.views["risen"]
	var paint := mesh.get_surface_override_material(0)
	var live_mesh := mesh.mesh
	var rest := mesh.transform
	var fx = battle.gfx
	var s = fx.ship("risen")
	mesh.mesh = live_mesh.duplicate()  # a damage rebuild replaces the mesh resource
	DEATH.precompute(fx, s)
	while not DEATH.finish_precompute(fx, s):
		await process_frame
	fx.death("risen", "blast")
	sv.dead = true
	for i in 85:
		fx.step(1.0 / 60.0)
		await process_frame
	_check(mesh.material_overlay != null and mesh.get_surface_override_material(0) != paint and not mesh.visible,
		"setup: the death painted and hid the original hull")
	var pieces: Array = fx.dstate.wrecks[0].nodes.duplicate() if not fx.dstate.wrecks.is_empty() else []
	_check(not pieces.is_empty(), "setup: there is a wreck to take back")
	mesh.position.y += 2.0  # stand in for a jolt left on the mesh at the split
	battle.wrecked["risen"] = true
	var restored: Dictionary = battle.VU["risen"].duplicate()
	battle.VU["risen"]["dead"] = true
	battle.VU["risen"]["hp"] = 0.0
	await battle._play_event({"t": "risen", "unit": "risen", "q": 1, "r": 2}, {"units": [restored]})
	_check(fx.dstate.wrecks.is_empty() and not battle.wrecked.has("risen"), "rise removes both wreck records")
	for piece in pieces:
		_check(not is_instance_valid(piece), "rise frees the old wreck piece")
	_check(mesh.mesh == live_mesh and mesh.visible and not sv.dead and mesh.material_overlay == null and mesh.get_surface_override_material(0) == paint,
		"rise shows the live surface paint without the death overlay")
	_check(mesh.transform.is_equal_approx(rest) and sv.hull.basis.is_equal_approx(sv.hull_basis), "rise restores the fitted hull pose")
	_check(is_equal_approx(fx.ship("risen").section_fraction[1], 0.35), "new FX ship uses the risen health")
	var flashes: int = fx.flash_log.size()
	for i in 100:
		fx.step(1.0 / 60.0)
	_check(fx.flash_log.size() == flashes and fx.dstate.wrecks.is_empty(), "old core and secondaries stay cancelled after rise")
	battle.free()
	_verdict(before, "Eclipse takes back its wreck and live paint")

func _rise_then_tidal_tick() -> void:
	var before := failures
	rules_api.new_battle_scenario({"seed": 7, "admiral": "vex", "fleet": ["warden"], "fac": "deathless", "enemies": ["d_jackal"],
		"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
	var rules = rules_api.R
	var ship: Dictionary = rules.alive("enemy")[0]
	var id := str(ship["id"])
	# Place a ship due to rise in the tidal ring. Disable passive repair to isolate the one hull change.
	rules.B["terrain"] = {}
	var hex: Dictionary = rules.boardHexes().filter(func(h): return rules.unitAt(h.q, h.r) == null)[0]
	rules.B["well"] = {"q": hex.q + 1, "r": hex.r}
	ship.merge({"q": hex.q, "r": hex.r, "dead": true, "hp": 0, "riseAt": rules.B["round"], "hullRegen": 0}, true)
	rules_api.take_events()
	var view_before := rules_api.view()
	view_before["units"] = view_before["units"].filter(func(u): return u["id"] == id)
	rules.startSideTurn("enemy")
	var events := rules_api.take_events()
	var view_after := rules_api.view()
	view_after["units"] = view_after["units"].filter(func(u): return u["id"] == id)
	var final_ship: Dictionary = view_after["units"][0]
	var ticks := events.filter(func(e): return e["t"] == "tick" and e.get("unit") == id and e["kind"] == "tidal")
	var final_hp := float(final_ship["hp"])
	_check(ticks.size() == 1 and final_hp > 0.0 and not final_ship["dead"],
		"setup: expected one tidal tick and surviving hull, got %d ticks and %s hull, events %s, over %s, round %s, rising %s"
		% [ticks.size(), final_hp, events, view_after["over"], view_after["round"], final_ship["rising"]])
	if before != failures:
		_verdict(before, "rise and tidal damage play in order")
		return
	var rise_hp := final_hp + float(ticks[0]["hull"])
	var battle := _lifetime_battle()
	_lifetime_ship(battle, id)
	battle.hud = LogFixture.new()
	battle.add_child(battle.hud)
	battle._sync(view_before)
	battle.trace_id = id
	await battle._play_batch({"events": events, "view": view_after})
	_check(battle.hull_trace == [rise_hp, final_hp],
		"expected hull %s at rise and %s after tidal damage, got %s" % [rise_hp, final_hp, battle.hull_trace])
	var mid: Dictionary = final_ship["sec"]["mid"]
	_check(battle.rise_sections.size() == 3 and is_equal_approx(battle.rise_sections[1], float(mid["hp"]) / float(mid["max"])),
		"rise uses the restored section damage effects")
	battle._sync(view_after)
	_check(battle.disp[id]["hp"] == final_hp and not battle.views[id].dead, "final sync agrees with the surviving hull")
	battle.free()
	_verdict(before, "rise and tidal damage play in order")

func _jump_drops_collider() -> void:
	var before := failures
	var battle := _lifetime_battle()
	var mesh := _lifetime_ship(battle, "jump")
	var fx = battle.gfx
	var s = fx.ship("jump")
	var body: Node = s.get_meta("collider")
	_check(is_instance_valid(body) and body.collision_layer == DEATH.HULL_LAYER, "setup: the live ship has a debris collider")
	await battle._play_event({"t": "fled", "unit": "jump"})
	fx.step(0.39)
	_check(mesh.visible and is_instance_valid(body), "jump keeps the collider while the hull is still there")
	fx.step(0.02)
	await process_frame
	await process_frame
	_check(s.gone and not mesh.visible and is_instance_valid(s.root), "jump hides the hull but keeps its view root")
	_check(not is_instance_valid(body), "jump leaves no hull collider for debris to hit")
	battle.free()
	_verdict(before, "jump removes the collider as the hull leaves")

func _run() -> void:
	var error := rules_api.load_rules()
	if not error.is_empty():
		push_error(error)
		quit(1)
		return
	_exit_with_cut()
	await _risen_takes_wreck()
	await _rise_then_tidal_tick()
	await _jump_drops_collider()
	for quality in ["high", "low"]:
		for spec in [["voidsworn", "Cruiser", 0.8, "blast"], ["voidsworn", "Frigate", 0.55, "big"],
			["voidsworn", "Squadron", 0.1, "big"], ["chorus", "Bio-titan", 1.25, "big"],
			["chorus", "Frigate", 0.55, "blast"], ["voidsworn", "Cruiser", 0.8, "dark"]]:
			var world := Node3D.new()
			root.add_child(world)
			var sv := SV.new()
			world.add_child(sv)
			sv.set_process(false)
			sv.hull = Node3D.new()
			sv.add_child(sv.hull)
			sv.ring = MeshInstance3D.new()
			sv.add_child(sv.ring)
			var mesh := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(12, 3, 4)
			box.subdivide_width = 15
			box.subdivide_height = 3
			box.subdivide_depth = 4
			mesh.mesh = box
			sv.hull.add_child(mesh)
			sv.meshes = [mesh]
			sv.position = Vector3(3, 0, 4)
			var fx = FX.new()
			world.add_child(fx)
			fx.manual = true
			fx.setup({"quality": quality, "shake": 0.0})
			fx.add_ship("plane", sv, {"faction": spec[0], "cls": spec[1], "size": spec[2], "meshes": [mesh]})
			var s = fx.ship("plane")
			DEATH.precompute(fx, s)
			for frame in 30:
				fx.step(1.0 / 60.0)
				await process_frame
			fx.death("plane", spec[3])
			sv.dead = true
			# Cover death during the older movement path as well as a parked ship.
			sv.path_dur = 2.0
			var heights := {}
			for frame in 240:
				sv._process(1.0 / 60.0)
				fx.step(1.0 / 60.0)
				await process_frame
				_check(sv.position.is_equal_approx(Vector3(3, 0, 4)), "dying view stays at its battle position")
				_check(mesh.transparency == 0.0 and sv.visible, "view never fades ahead of FX replacement")
				if spec[0] == "chorus" and not s.has_meta("death_hidden"):
					_check(mesh.scale.is_equal_approx(Vector3.ONE), "Chorus skin does not deflate")
				for wreck in fx.dstate.wrecks:
					for node in wreck.nodes:
						if not heights.has(node): heights[node] = node.global_position.y
						_check(absf(node.global_position.y - float(heights[node])) < 0.01, "wreck centre stays at its split altitude")
						if node is RigidBody3D:
							_check(node.axis_lock_linear_y, "physics cannot push wrecks below the board")
			_check(s.has_meta("death_hidden"), "FX replaces the live hull")
			_check(fx.dstate.wrecks.size() == (0 if s.squadron else 1), "ships leave an independent wreck; wings leave none")
			if s.squadron:
				_check(fx.dstate.debris.is_empty(), "a wing spark leaves no physical shards")
			if not fx.dstate.wrecks.is_empty():
				var w: Dictionary = fx.dstate.wrecks[0]
				if spec[0] == "chorus":
					_check(w.nodes.size() >= 4 and w.get("organic", false), "Chorus spills several real skin fragments")
					_check(w.lights.is_empty() and fx.flash_log.is_empty() and fx.dstate.debris.is_empty(), "Chorus spill has no metal fire, core flash or plates")
				elif spec[1] == "Cruiser" and spec[3] == "blast":
					# issue 462 (deaths_and_hits.md): a cruiser parts into two capped halves
					_check(w.nodes.size() == 2, "ordinary cruiser blast has two sealed halves")
				fx.remove_ship("plane")
				sv.die(false)
				_check(not sv.visible and sv.position.y == 0.0, "fallback death hides in place")
				sv.revive()
				_check(sv.visible and not sv.dead and mesh.visible, "revive restores the view after death")
				sv.die(true)
				_check(sv.visible and sv.wreck and sv.position.y == 0.0, "blocking wreck remains on the board")
				sv.queue_free()
				await process_frame
				for node in w.nodes: _check(is_instance_valid(node), "wreck survives removal of its live view")
			print("DEATH_PLANE quality=%s faction=%s class=%s cause=%s" % [quality, spec[0], spec[1], spec[3]])
			fx.release()
			world.queue_free()
			await process_frame
	SV.clear_static()
	FX.clear_static()
	print("DEATH_PLANE failures=%d" % failures)
	quit(1 if failures else 0)
