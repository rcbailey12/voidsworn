extends SceneTree

const Battle := preload("res://scenes/battle/battle.gd")
const API := preload("res://rules/battle_api.gd")
const Hud := preload("res://ui/battle/hud.gd")
const Sfx := preload("res://audio/sfx.gd")

class TestBattle extends Battle:
	var commands := 0
	var exhausted := false

	func _ready() -> void:
		set_process(false)

	func _refresh_ui() -> void:
		pass

	func _overlay() -> void:
		pass

	func _ui(_id: String) -> Dictionary:
		return {"orders": {"brace": true}, "ram": {"target": "enemy"}}

	func _nothing_left(_id: String) -> bool:
		return exhausted

	func _cmd(_f: Callable) -> bool:
		commands += 1
		return true


var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", label)


func _run() -> void:
	for action: String in ["Q", "E", "Backspace", "G then X", "Enter", "Space", "B", "X", "G", "confirm", "end", "undo", "auto-end"]:
		var b := TestBattle.new()
		b.api = API.new()
		var err: String = b.api.load_rules()
		if err != "":
			printerr("FAIL: ", err)
			b.free()
			quit(1)
			return
		b.api.new_battle_scenario("s1")
		b.V = b.api.view()
		b._index_view()
		b.sel = b.api.R.alive("player")[1]["id"]
		b.handed_t = -1.0
		b.hud = Hud.new()
		b.sfx = Sfx.new()
		b.board = Battle.Board.new()
		b.add_child(b.hud)
		b.add_child(b.board)
		root.add_child(b)
		if action in ["Backspace", "Enter", "confirm", "undo"]:
			b._rotate(1)
			_check(b.plan != null, action + " fixture has a turn plan")
		if action == "auto-end":
			b.exhausted = true
			b.VU[b.sel]["active"] = true
		# Hold the ownership flag and the actual task until the whole input (or timer) has arrived.
		var gate := Semaphore.new()
		b._threat_tid = WorkerThreadPool.add_task(gate.wait)
		b._threat_busy = true
		b._threat_gen = b._gen
		b._threat_pending_version = int(b.api.version)
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
		gate.post()
		b._threat_reap()
		await process_frame
		await process_frame
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
		b.sfx.free()
		b.free()
	if failures == 0:
		print("PASS: threat worker preserves all listed keys and ledger actions, and auto-end retries")
	quit(1 if failures else 0)
