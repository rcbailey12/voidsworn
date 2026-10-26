# A3 rules parity, Godot side. Run headless:
#   godot --headless --path godot --script res://rules/test/parity_main.gd -- prng <seed> <count> <out.txt>
#   godot --headless --path godot --script res://rules/test/parity_main.gd -- math <node_math.txt>
#   godot --headless --path godot --script res://rules/test/parity_main.gd -- scenario <name> <out.jsonl> [seed]
# The scenario harness mirrors node/golden.js line for line: same bot for your side, same activation order, same records.
extends SceneTree
const JSM = preload("res://rules/jsm.gd")
const RulesScript = preload("res://rules/rules.gd")
const APIScript = preload("res://rules/battle_api.gd")
var R

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var code := 2
	if a.size() >= 4 and a[0] == "prng": code = prng(int(a[1]), int(a[2]), a[3])
	elif a.size() >= 2 and a[0] == "math": code = math(a[1])
	elif a.size() >= 3 and a[0] == "scenario": code = scenario(a[1], a[2], int(a[3]) if a.size() >= 4 else -1, a[4] if a.size() >= 5 else "")
	elif a.size() >= 3 and a[0] == "batch": code = batch(a[1], a[2])
	else: printerr("usage: -- prng <seed> <count> <out> | math <file> | scenario <name> <out> [seed|-1] [file.json] | batch <file.json> <outdir>")
	quit(code)

func prng(seed: int, n: int, out: String) -> int:
	JSM.rnd_seed(seed)
	var lines := PackedStringArray()
	for i in range(n):
		var d := JSM.rnd(); lines.append(str(JSM.rng_u32()) + " " + JSM.hex64(d))
	var f := FileAccess.open(out, FileAccess.WRITE); f.store_string("\n".join(lines) + "\n"); f.close()
	print("prng ", seed, " ", n, " -> ", out); return 0

func math(path: String) -> int:
	var bad := {}; var n := 0
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		var p := line.split(" "); var fn := p[0]; var x := JSM.from_hex64(p[1]); var y := JSM.from_hex64(p[2]); var want := p[3]; var got: float
		match fn:
			"sin": got = JSM.sin(x)
			"cos": got = JSM.cos(x)
			"atan2": got = JSM.atan2(x, y)
			"exp": got = JSM.exp(x)
			"hypot": got = JSM.hypot([x, y])
			"round": got = JSM.jsround(x)
			"pow": got = JSM.pow(x, y)
		n += 1
		if JSM.hex64(got) != want: bad[fn] = int(bad.get(fn, 0)) + 1
	print("math ", n, " values, differences from Node: ", bad if bad.size() > 0 else "none")
	return 0 if bad.size() == 0 else 1

# ---------------- scenario harness (golden.js) ----------------
var stopped := false
const SKIP_U := {"t": 1, "ship": 1}
const SKIP_B := {"units": 1, "cfg": 1, "prog": 1}   # B.prog: the UI busy-watchdog counter, not a rule (see golden.js); the battle log is in the hash
func snap(turn: int, actor: String) -> Dictionary:
	if R.not_ported != "" and not stopped:
		stopped = true; printerr("NOT PORTED: this battle reached a rule the port does not carry yet: ", R.not_ported)
	var B = R.B; var parts := PackedStringArray()
	for u in B["units"]: parts.append(JSM.canon(u, "u", SKIP_U))
	var s := "{\"b\":" + JSM.canon(B, "b", SKIP_B) + ",\"units\":[" + ",".join(parts) + "]}"
	return {"turn": turn, "round": int(B["round"]), "actor": actor, "rng": JSM.rng_u32(), "hash": JSM.sha256(s), "state": s}

# your side's bot, through the same API calls the scene uses (golden.js pBotF)
var api
func pBot(u) -> void:
	var B = R.B
	if R.jt(B.get("over")) or R.jt(u.get("dead")): return
	var foes = R.alive("enemy")
	if foes.size() == 0: return
	var states = R.computeReach(u).states; var best: Variant = null; var bs = -1e9
	R.eval_begin()
	for s in states:
		var v = R.stateView(u, s); var off = R.evalOffense(v, R.readyList(u), foes); var th = R.evalThreat(v, foes)
		var ds := []
		for f in foes: ds.append(R.hdist(v, f))
		var nd = JSM.amin(ds); var sc = off - th * 0.3 - (0.0 if off > 0 else nd * 3.0)
		if sc > bs:
			bs = sc; best = s
	R.eval_end()
	if best != null and best.path.size() > 0: api.move(u["id"], best)
	run_enemy()
	for i in range(u["weapons"].size()):
		if R.jt(R.B.get("over")) or R.B["side"] != "player" or R.jt(u.get("activated")): break
		var bt = null; var bv = 0.0
		for t in R.alive("enemy"):
			if R.canFire(u, u["weapons"][i], t):
				var e = R.expectedVs(u, u["weapons"][i], t); var v = e.hull + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
				if v > bv:
					bv = v; bt = t
		if bt != null: api.fire(u["id"], i, bt["id"])
		run_enemy()
	if not R.jt(R.B.get("over")) and R.B["side"] == "player" and not R.jt(u.get("activated")): api.end_activation(u["id"])
	run_enemy()

# the full bot (golden.js pBotFull, sim3d.js botUnit), through the same API calls the scene uses
func attackFirst(u) -> void: # golden.js attackFirstF, through api.attack_move
	if R.jt(R.B.get("over")) or R.jt(u.get("dead")) or R.jt(u.get("isSq")): return
	for w in u["weapons"]:
		if not R.weaponReady(w): continue
		for t in R.alive("enemy"):
			if R.canFire(u, w, t): return
	var es = []
	for x in R.alive("enemy"):
		if not R.jt(x.get("isSq")): es.append(x)
	if es.size() == 0: return
	var t = es[0]
	for x in es:
		if R.hdist(u, x) < R.hdist(u, t): t = x
	api.attack_move(u["id"], t["id"]); run_enemy()
func bot(u, S) -> void:
	if S.get("attack_move") == true:
		attackFirst(u)
		if R.jt(R.B.get("over")) or R.jt(u.get("dead")) or R.jt(u.get("activated")) or R.B["side"] != "player": return
	if S.get("bot") == "full": pBotFull(u)
	else: pBot(u)
func pBotFull(u) -> void: # the full bot is the API's ai_activate (golden.js pBotFull)
	api.ai_activate(u["id"]); run_enemy()

var tm_acts := []; var tm_rounds := {}; var snap_us := 0
func run_enemy() -> void: # the enemy side's steps, timed without the hash records
	while api.phase == "enemy":
		var s0 := snap_us; var t0 := Time.get_ticks_usec(); var r = int(R.B["round"])
		var q = api._queue[0] if api._queue.size() > 0 else null
		api.step()
		var ms := (Time.get_ticks_usec() - t0 - (snap_us - s0)) / 1000.0
		if q != null and not R.jt(q.get("isSq")):
			tm_acts.append({"round": r, "ms": ms}); tm_rounds[str(r)] = float(tm_rounds.get(str(r), 0.0)) + ms

# every battle in a scenario file (the sweep), one record file each; exit code 3 if any hit something not ported
func batch(file: String, outdir: String) -> int:
	var all = JSON.parse_string(FileAccess.get_file_as_string(file)); var worst := 0; var k := 0
	for name in all.keys():
		var c := scenario(name, outdir.path_join(name + ".jsonl"), -1, file); worst = max(worst, c); k += 1
	print("batch ", k, " battles -> ", outdir)
	return worst
func scenario(name: String, out: String, seed_override: int = -1, file: String = "") -> int:
	tm_acts = []; tm_rounds = {}; snap_us = 0; stopped = false
	api = APIScript.new()
	var err = api.load_rules()
	if err != "":
		printerr(err); return 1
	R = api.R
	var all = JSON.parse_string(FileAccess.get_file_as_string(file if file != "" else "res://rules/test/scenarios.json"))
	if not all.has(name):
		printerr("unknown scenario ", name); return 1
	var S = all[name].duplicate(true)
	if seed_override >= 0: S.seed = seed_override
	var rec := []; var turn := [0]
	R.hook_cb = func(kind, u):
		if R.B != null:
			var t0 := Time.get_ticks_usec()
			rec.append(snap(turn[0], kind + (" " + String(u["id"]) if u != null else ""))); turn[0] += 1
			snap_us += Time.get_ticks_usec() - t0
	api.new_battle_scenario(S, -1)
	var g := 0
	var full: bool = S.get("bot") == "full"
	if R.jt(R.B.get("alt")):
		while not R.jt(R.B.get("over")) and R.B["round"] <= int(S.rounds) and g < 2000:
			g += 1
			var pp = api._pendingP()
			if pp.size() > 0:
				bot(pp[0], S)
			else:
				api.end_activation(null); run_enemy()
	else: # Classic mode: every ship acts, then the turn ends
		while not R.jt(R.B.get("over")) and R.B["round"] <= int(S.rounds) and g < 200:
			g += 1
			var mine = []
			for x in R.alive("player"):
				if not R.jt(x.get("isSq")): mine.append(x)
			for u in mine:
				if R.jt(R.B.get("over")): break
				bot(u, S)
			if not R.jt(R.B.get("over")):
				api.end_turn(); run_enemy()
	R.hook("end " + (str(R.B["over"]) if R.jt(R.B.get("over")) else "none"))
	R.hook_cb = null
	var f := FileAccess.open(out, FileAccess.WRITE)
	for x in rec: f.store_line(JSON.stringify(x))
	f.close()
	var ft := FileAccess.open(out + ".timing.json", FileAccess.WRITE); ft.store_string(JSON.stringify({"acts": tm_acts, "rounds": tm_rounds})); ft.close()
	print("scenario ", name, " ", rec.size(), " records ", rec[rec.size() - 1].actor, " -> ", out)
	if stopped:
		printerr("NOT PORTED: ", R.not_ported); return 3
	return 0
