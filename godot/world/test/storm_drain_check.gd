extends SceneTree

const GUARD := preload("res://tools/ci/check_guard.gd")
const API := preload("res://rules/battle_api.gd")
const LOOK := preload("res://world/board_look.gd")
const STEP := 1.0 / 60.0
const SEED := 4103

class Playback extends "res://scenes/battle/battle.gd":
	var advance_frame: Callable

	func wait(ms: float) -> void:
		if not advance_frame.is_valid():
			await super.wait(ms)
			return
		for frame in ceili(ms * speed / (1000.0 * STEP)):
			advance_frame.call()

var failures := 0
var samples: Array = []


func _init() -> void:
	GUARD.arm(self, "storm_drain_check")
	_run.call_deferred()


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func _sample(battle: Playback, patch: Dictionary) -> void:
	var living = battle.world._living
	battle.gfx.now = living.clock + STEP
	living._process(STEP)
	var card := _uniform_flares(patch.mat)
	var fog := _uniform_flares(patch.fog_mat)
	_check(card == fog, "storm cards and fog receive the same positions and weights")
	samples.append(card)


func _uniform_flares(mat: ShaderMaterial) -> PackedVector4Array:
	var count = mat.get_shader_parameter("tick_flare_count")
	if count is int and count > 0:
		var values: PackedVector4Array = mat.get_shader_parameter("tick_flares")
		return values.slice(0, count)
	return PackedVector4Array()


func _check_cues(tag: String, positions: Array[Vector3], reduced: bool, together: bool) -> void:
	var first := [-1, -1]
	var last := [-1, -1]
	var peak := [0.0, 0.0]
	for frame in samples.size():
		var seen := [false, false]
		for flare: Vector4 in samples[frame]:
			var index := positions.find(Vector3(flare.x, flare.y, flare.z))
			_check(index >= 0, "%s: the shader cue is centred on a drained ship" % tag)
			if index < 0:
				continue
			_check(not seen[index], "%s: each drain gets one cue, including its HUD callout" % tag)
			seen[index] = true
			if first[index] < 0:
				first[index] = frame
			_check(last[index] < 0 or last[index] == frame - 1, "%s: a cue has no gaps or restarts" % tag)
			last[index] = frame
			peak[index] = maxf(peak[index], flare.w)
	for index in positions.size():
		_check(first[index] >= 0 and last[index] - first[index] >= 26 and last[index] - first[index] <= 27,
			"%s: ship %d gets its full 0.45 s cue (frames %d to %d)" % [tag, index, first[index], last[index]])
		_check(is_equal_approx(peak[index], 0.22) if reduced else peak[index] > 0.8,
			"%s: ship %d gets the expected brightness (%.3f)" % [tag, index, peak[index]])
		# A surviving slot must still carry visible light near the end of its tail.
		if first[index] >= 0 and first[index] + 24 < samples.size():
			var late: PackedVector4Array = samples[first[index] + 24]
			var position := positions[index]
			_check(_has_tail(late, position), "%s: ship %d keeps its late fade" % [tag, index])
	_check(first[0] == first[1] if together else first[0] < first[1] and first[1] < last[0],
		"%s: both cues overlap at the expected playback spacing" % tag)
	_check(samples.back().is_empty(), "%s: both shader cues expire" % tag)


func _has_tail(values: PackedVector4Array, pos: Vector3) -> bool:
	for value in values:
		if Vector3(value.x, value.y, value.z) == pos:
			return value.w > 0.0
	return false


func _play(reduced: bool, together: bool) -> void:
	var tag := "%s/%s" % ["Reduced Flashing" if reduced else "Standard", "same frame" if together else "staggered"]
	var api := API.new()
	var error := api.load_rules()
	if error != "":
		_check(false, error)
		return
	var scenarios: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rules/test/scenarios.json"))
	var scenario: Dictionary = scenarios["s1"]
	scenario["alt"] = false
	scenario["enemies"] = ["h_interdictor", "h_interdictor"]
	api.new_battle_scenario(scenario, SEED)
	# Put only these two ships in a connected five-hex cloud, four hexes apart.
	var terrain: Dictionary = api.R.B["terrain"]
	terrain.clear()
	for q in range(-2, 3):
		terrain["%d,0" % q] = "storm"
	var enemies: Array = api.R.alive("enemy")
	var before := {}
	for i in enemies.size():
		var ship: Dictionary = enemies[i]
		ship["q"] = -2 + 4 * i
		ship["r"] = 0
		before[ship["id"]] = [ship["shp"], ship["hp"]]

	var battle := Playback.new()
	battle.external = true
	battle.showcase = true
	battle.args["quality"] = "max"
	root.add_child(battle)
	await battle._begin(api)
	battle.reduce_flashing = reduced
	battle.gfx.reduce_flashing = reduced
	battle.gfx.flash_area_logging = true
	battle.cam.t = Vector3.ZERO
	battle.cam.r = 170.0
	battle.cam.snap()
	var living = battle.world._living
	_check(living != null and living._storm_patches.size() == 1, "%s: one connected storm patch" % tag)
	if living == null or living._storm_patches.size() != 1:
		battle.free()
		return
	var patch: Dictionary = living._storm_patches[0]
	_check(patch.has("fog_mat"), "%s: Max uses both shader paths" % tag)
	if not patch.has("fog_mat"):
		battle.free()
		return
	# Keep random lightning out of the deterministic drain playback.
	for burst in living._storm_bursts:
		burst.next = INF
	battle.gfx.flash_area_log.clear()
	battle.gfx._flashes.clear()
	battle.gfx.flash_cands.clear()
	samples.clear()
	battle.advance_frame = _sample.bind(battle, patch)
	battle.user_speed = 0.0 if together else 1.0
	api.end_turn()
	var events := api.take_events()
	var positions: Array[Vector3] = []
	for event in events:
		if event["t"] != "tick" or event.get("kind") != "storm":
			continue
		var id: String = event["unit"]
		var ship: Dictionary = api.unit(id)
		_check(before.has(id) and ship["shp"] == before[id][0] - 10 and ship["hp"] == before[id][1],
			"%s: the turn drains ten shields and no hull on %s" % [tag, id])
		positions.append(battle._pos(id))
	_check(positions.size() == 2, "%s: the real turn emits two shield drains" % tag)
	if positions.size() == 2:
		await battle._play_batch({"events": events, "view": api.view()})
		for frame in 30:
			_sample(battle, patch)
		_check_cues(tag, positions, reduced, together)
		var bookings: Array = battle.gfx.flash_area_log
		_check(bookings.size() == (0 if reduced else 2), "%s: each cue follows the shared flash budget" % tag)
	battle.free()


func _run() -> void:
	OS.set_environment("VS_NEBULA_ROUTE", "fog")
	LOOK.set_look("cine", false)
	for reduced in [false, true]:
		for together in [false, true]:
			await _play(reduced, together)
	if failures == 0:
		print("storm drain: PASS (same-frame and staggered, Standard and Reduced Flashing, cards and fog)")
	quit(0 if failures == 0 else 1)
