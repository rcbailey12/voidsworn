extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Hud := preload("res://ui/battle/hud.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestBattle extends Battle:
	var commands := 0
	var exhausted := false
	var play_commands := false
	var run_rules := false
	var enemy_acted := false

	func _ready() -> void:
		set_process(false)

	func _refresh_ui() -> void:
		pass

	func _overlay() -> void:
		pass

	func _clear_overlay() -> void:
		pass

	func _ui(_id: String) -> Dictionary:
		return {"orders": {"brace": true}, "ram": {"target": "enemy"}}

	func _nothing_left(_id: String) -> bool:
		return exhausted

	func _cmd(f: Callable) -> bool:
		commands += 1
		if run_rules:
			return super._cmd(f)
		if play_commands:
			busy = true
		return true

	func _play_batch(bt: Dictionary) -> void:
		for event: Dictionary in bt["events"]:
			if event["t"] == "activation" and event["side"] == "enemy":
				enemy_acted = true
		await get_tree().process_frame

	func _sync(view: Dictionary) -> void:
		V = view
		_index_view()

	func select(id: String, _how := "pick") -> void:
		sel = id


var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)


func _battle() -> TestBattle:
	var b := TestBattle.new()
	b.api = API.new()
	var err: String = b.api.load_rules()
	if err != "":
		printerr("FAIL: ", err)
		b.free()
		quit(1)
		return null
	b.api.new_battle_scenario("s1")
	b.PACE = b._api_tables()["PACE"]
	b.V = b.api.view()
	b._index_view()
	b.sel = b.api.R.alive("player")[1]["id"]
	b.handed_t = -1.0
	b.hud = Hud.new()
	b.sfx = Sfx.new()
	b.board = Battle.Board.new()
	b.cam = Battle.CamRig.new()
	b.add_child(b.hud)
	b.add_child(b.board)
	b.add_child(b.cam)
	root.add_child(b)
	return b


func _hold_threat_worker(b: TestBattle) -> Semaphore:
	var gate := Semaphore.new()
	b._threat_tid = WorkerThreadPool.add_task(gate.wait)
	b._threat_busy = true
	b._threat_gen = b._gen
	b._threat_pending_version = int(b.api.version)
	return gate


func _release_threat_worker(b: TestBattle, gate: Semaphore) -> void:
	gate.post()
	b._threat_reap()
	await process_frame
	await process_frame


func _free_battle(b: TestBattle) -> void:
	b.sfx.free()
	b.free()


func _run() -> void:
	for action: String in ["Q", "E", "Backspace", "G then X", "Enter", "Space", "B", "X", "G", "confirm", "end", "undo", "auto-end"]:
		var b := _battle()
		if b == null:
			return
		if action in ["Backspace", "Enter", "confirm", "undo"]:
			b._rotate(1)
			_check(b.plan != null, action + " fixture has a turn plan")
		if action == "auto-end":
			b.exhausted = true
			b.VU[b.sel]["active"] = true
		# Hold the ownership flag and the actual task until the whole input (or timer) has arrived.
		var gate := _hold_threat_worker(b)
		match action:
			"Q": b._on_key(KEY_Q)
			"E": b._on_key(KEY_E)
			"Backspace": b._on_key(KEY_BACKSPACE)
			"G then X":
				b._on_key(KEY_G)
				b._on_key(KEY_X)
			"Enter": b._on_key(KEY_ENTER)
			"Space": b._on_key(KEY_SPACE)
			"B": b._on_key(KEY_B)
			"X": b._on_key(KEY_X)
			"G": b._on_key(KEY_G)
			"auto-end":
				b._auto_end(b.sel)
				await create_timer(0.9).timeout
			_: b._on_action(action, null)
		_check(b.commands == 0 and b.mode == "", action + " did not act while rules were owned by the worker")
		await _release_threat_worker(b, gate)
		match action:
			"Q", "E":
				var turn := -1 if action == "Q" else 1
				_check(b.plan != null and int(b.plan["rot"]) == turn, action + " turns once after the worker")
			"G then X": _check(b.mode == "ram" and b.commands == 0, "G and X replay in order")
			"X": _check(b.mode == "ram", "X arms ram after the worker")
			"G": _check(b.mode == "board", "G switches to boarding after the worker")
			"Backspace", "undo": _check(b.plan == null and b.commands == 0, action + " steps back after the worker")
			_:
				_check(b.commands == 1, action + " sends exactly one command after the worker")
		_free_battle(b)
	await _check_playback()
	await _check_handoff()
	_check_rules_halt()
	for action: String in ["end", "undo", "confirm", "auto-end", "auto-end without worker", "end with prompt"]:
		await _check_modal(action)
	if failures == 0:
		print("PASS: threat inputs wait for playback and modals, stop at handoff, and respect rules halt")
	quit(1 if failures else 0)


func _check_playback() -> void:
	var b := _battle()
	if b == null:
		return
	b.set_process(true)
	b.play_commands = true
	var gate := _hold_threat_worker(b)
	b._on_key(KEY_B)
	b._on_key(KEY_E)
	b._on_key(KEY_ENTER)
	await _release_threat_worker(b, gate)
	_check(b.commands == 1 and b.busy, "first replayed command starts playback")
	_check(b._threat_inputs.size() == 2 and b.plan == null, "playback leaves the turn and Enter queued")
	_check(not b.skip, "queued Enter does not skip playback")
	b.busy = false
	await process_frame
	await process_frame
	_check(b.commands == 2 and b.plan == null and b._threat_inputs.is_empty(), "turn and Enter resume in order and commit once")
	_free_battle(b)


func _check_handoff() -> void:
	var b := _battle()
	if b == null:
		return
	b.set_process(true)
	b.run_rules = true
	b.opening = true # Only skip the camera glide. The runner and enemy use the real rules.
	var old := b.sel
	var gate := _hold_threat_worker(b)
	b._on_key(KEY_SPACE)
	b._on_key(KEY_B)
	await _release_threat_worker(b, gate)
	for i in 120:
		if not b.busy:
			break
		await process_frame
	await process_frame
	_check(not b.busy and b.enemy_acted and b.sel != "" and b.sel != old, "End plays the enemy activation and hands over to another ship")
	_check(b.commands == 1 and b._threat_inputs.is_empty(), "Brace queued for the previous ship is discarded")
	_free_battle(b)


func _check_rules_halt() -> void:
	var b := _battle()
	if b == null:
		return
	b._threat_busy = true
	b._on_key(KEY_B)
	b._threat_busy = false
	b.api.phase = "halted"
	b.api.halted = "threat check halt"
	b._process(0.0)
	_check(b._rules_halt_shown and is_instance_valid(b.hud.menu) and b.commands == 0,
		"the frame loop shows a rules halt before replaying any orders")
	_free_battle(b)


func _check_modal(action: String) -> void:
	var b := _battle()
	if b == null:
		return
	b.set_process(true)
	var undo := action == "undo"
	var auto_end := action.begins_with("auto-end")
	var prompt := action == "end with prompt"
	if undo or action == "confirm":
		b._rotate(1)
		_check(b.plan != null, action + " fixture has a turn plan")
	var gate := _hold_threat_worker(b) if action != "auto-end without worker" else null
	if auto_end:
		b.exhausted = true
		b.VU[b.sel]["active"] = true
		b._auto_end(b.sel)
	else:
		b._on_action("end" if prompt else action, null)
	if prompt:
		b.hud.show_ask({"kind": "role", "opts": []})
	elif undo or action == "confirm":
		b._on_action("menu", null) # Esc would cancel the plan before it opens the same menu.
	else:
		b._on_key(KEY_ESCAPE)
	_check(is_instance_valid(b.hud.ask_panel if prompt else b.hud.menu), action + " modal is open")
	if auto_end:
		await create_timer(0.9).timeout
	if gate != null:
		await _release_threat_worker(b, gate)
	_check(b.commands == 0 and (not undo or b.plan != null) and (not auto_end or b.ending), action + " waits behind the modal")
	if prompt:
		b.hud.hide_ask()
	elif undo or action == "confirm":
		b._on_action("menu_close", null)
	else:
		b._on_key(KEY_ESCAPE)
	await process_frame
	await process_frame
	_check(b.commands == (0 if undo else 1) and b.plan == null and not b.ending, action + " resumes once after the modal closes")
	_free_battle(b)
