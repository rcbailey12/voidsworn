# One bot battle, reached from a real campaign start, played to its end headless (issue 359 part c).
#   godot --headless --path godot --script res://tools/ci/bot_battle.gd [-- --seed N]
# Nothing here types a run, a fleet or a battle: the campaign makes them with its own functions and buttons
# (titleScreen, newRunScreen, pickFaction, startRun, pickAspect, enterNode), exactly as godot/main/campaign_host.gd
# wires it: external battle mode, battle_setup builds the rules battle through rules/battle_api.gd, and the real battle
# scene (scenes/battle/battle.tscn, HUD, effects, world, sound) plays it with both sides on the game's AI (its --bot
# mode). When the scene reports the end, the campaign takes the result through finish_battle, as in the game.
# Fails (exit 1) on: any script error, any "unknown event" line from the battle scene, a battle that does not end
# (softlock or the time limit), or a campaign that never reaches a battle. Fixed seed, no retries.
# Ship files: GitHub's checkout has no godot/gen, so every ship is the plain placeholder block. That is allowed here and
# reported: the capture stop (render/placeholder_guard.gd, issue 350) belongs to picture scripts and is never called.
extends SceneTree

const Campaign = preload("res://campaign/campaign.gd")
const BattleAPI = preload("res://rules/battle_api.gd")
const BattleScene = preload("res://scenes/battle/battle.tscn")
const JSM = preload("res://rules/jsm.gd")
const World = preload("res://world/world.gd")
const PG = preload("res://render/placeholder_guard.gd")

const LIMIT_S := 600.0   # real seconds for the whole check; GitHub's job limit is 30 minutes


class ErrLog extends Logger:
	var script_errors := 0
	var unknown := 0
	var first: Array = []
	var mutex := Mutex.new()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _bt: Array) -> void:
		var msg := rationale if rationale != "" else code
		mutex.lock()
		if msg.contains("unknown event"):
			unknown += 1
			if first.size() < 8: first.append(msg)
		elif error_type == Logger.ERROR_TYPE_SCRIPT:
			script_errors += 1
			if first.size() < 8: first.append("%s (%s:%d %s)" % [msg, file.get_file(), line, function])
		mutex.unlock()


var C
var api
var requested := false
var log := ErrLog.new()
var t0 := 0


func _init() -> void:
	OS.add_logger(log)
	t0 = Time.get_ticks_msec()
	_run.call_deferred()


func _fail(why: String) -> void:
	printerr("bot battle: FAIL: " + why)
	for l in log.first:
		printerr("  " + str(l))
	OS.remove_logger(log)
	quit(1)


func _setup(run: Dictionary, cfg: Dictionary) -> Dictionary:
	api = BattleAPI.new()
	var e: String = api.load_rules()
	if e != "":
		printerr("bot battle: rules: " + e)
	api.new_battle(run, cfg)
	return api.R.B


func _pick(acts: Array) -> Variant:
	# the first enabled button in this order; on the map, a battle node before any other node
	var on: Array = acts.filter(func(x): return int(x[2]) == 1)
	for name in ["closeModal", "storyCore", "beat3", "startRun", "pickAspect"]:
		for x in on:
			if x[0] == name: return x
	var nodes: Array = on.filter(func(x): return x[0] == "enterNode")
	for x in nodes:
		var n = C.findNode(str(x[1]))
		if n != null and str(n.get("type")) in ["battle", "elite", "boss"]: return x
	if not nodes.is_empty(): return nodes[0]
	for name in ["eventChoice", "takePerk", "takeSalvage", "takeMod", "backMap"]:
		for x in on:
			if x[0] == name: return x
	return null


func _run() -> void:
	var a := OS.get_cmdline_user_args()
	var seed := 359
	var i := a.find("--seed")
	if i >= 0 and i + 1 < a.size(): seed = int(a[i + 1])
	C = Campaign.new()
	var err: String = C.load_tables()
	if err != "":
		_fail("campaign tables: " + err); return
	C.persist_on = false
	C.fixed_clock = true
	C.META = C.defaultMeta()
	C.battle_mode = "external"
	C.battle_setup = _setup
	C.battle_requested.connect(func(): requested = true)
	JSM.rnd_seed(seed & 0xFFFFFFFF)   # as campaign_host.gd _seed_campaign for bot runs
	# a real campaign start, through the campaign's own buttons
	C.titleScreen()
	C.act("newRunScreen")
	var clicks := 0
	while not requested and clicks < 200:
		clicks += 1
		var x: Variant = _pick(C.screen_acts())
		if x == null:
			_fail("no button to press on page %s (modal %s)" % [str(C.page.get("kind")), str(C.modal_d.get("kind")) if C.modal_d != null else "none"]); return
		C.act(str(x[0]), str(x[1]))
	if not requested or api == null:
		_fail("the campaign did not reach a battle in %d clicks" % clicks); return
	var cfg: Dictionary = C.pending_battle if C.pending_battle is Dictionary else {}
	print("bot battle: seed %d, %s run as %s, %d clicks to the first battle (%s against %s, node %s)" % [seed, str(C.RUN["fac"]), str(C.RUN["admiral"]), clicks, str(cfg.get("kind")), str(cfg.get("fac")), str(C.RUN.get("curNode"))])
	# the real battle scene, as godot/main/main.gd play_api builds it, with both sides on the game's AI
	Engine.time_scale = 40.0   # as main.gd --bot-runs (--fast default)
	Engine.max_fps = 0
	var b = BattleScene.instantiate()
	b.external = true
	b.bot = true
	b.in_campaign = true
	b.can_retreat = false
	b.args["sector_setting"] = World.sector_setting(C.RUN)
	root.add_child(b)
	var out := {}
	var done := [false]
	b.finished.connect(func(r): out.merge(r); done[0] = true)
	b.begin_with(api)
	while not done[0]:
		await process_frame
		if (Time.get_ticks_msec() - t0) / 1000.0 > LIMIT_S:
			_fail("the battle did not end in %d s (phase %s, round %s)" % [int(LIMIT_S), str(api.phase), str(b.V.get("round") if b.V is Dictionary else "?")]); return
	Engine.time_scale = 1.0
	var res := str(out.get("result", ""))
	print("bot battle: result %s after %d rounds, %d enemy ships destroyed, %d of ours lost, %.1f s real time" % [res, int(out.get("rounds", 0)), int(out.get("killed", 0)), int(out.get("lost", 0)), (Time.get_ticks_msec() - t0) / 1000.0])
	print("bot battle: placeholder hulls drawn: %d (allowed here: GitHub has no ship files; the capture stop is not called)" % PG.count)
	# the campaign takes the result through its own function, as campaign_host.gd _play_battle does
	if res in ["win", "loss"]:
		C.finish_battle(res, api.R.B)
		print("bot battle: campaign page after the battle: %s" % str(C.page.get("kind")))
	b.queue_free()
	await process_frame
	await process_frame
	load("res://render/ship_view.gd").clear_static()
	load("res://scenes/battle/fx_stub.gd").clear_static()
	var bad: Array = []
	if not (res in ["win", "loss"]): bad.append("the battle ended as \"%s\", not a win or a loss" % res)
	for e in out.get("errors", []): bad.append("battle error: " + str(e))
	if log.script_errors > 0: bad.append("%d script error(s)" % log.script_errors)
	if log.unknown > 0: bad.append("%d unknown event line(s)" % log.unknown)
	if not C.jt(api.R.B.get("finished")) and res in ["win", "loss"]: bad.append("the campaign did not finish the battle")
	if not bad.is_empty():
		_fail("; ".join(PackedStringArray(bad))); return
	OS.remove_logger(log)
	print("bot battle: PASS")
	quit(0)
