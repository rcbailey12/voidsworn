# A3 rules parity, Godot side. Run headless:
#   godot --headless --path <this folder> --script res://main.gd -- prng <seed> <count> <out.txt>
#   godot --headless --path <this folder> --script res://main.gd -- math <node_math.txt>
#   godot --headless --path <this folder> --script res://main.gd -- scenario <name> <out.jsonl>
# The scenario harness mirrors node/golden.js line for line: same bot for your side, same activation order, same records.
extends SceneTree
const JSM = preload("res://rules/jsm.gd")
const RulesScript = preload("res://rules/rules.gd")
var R

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var code := 2
	if a.size() >= 4 and a[0] == "prng": code = prng(int(a[1]), int(a[2]), a[3])
	elif a.size() >= 2 and a[0] == "math": code = math(a[1])
	elif a.size() >= 3 and a[0] == "scenario": code = scenario(a[1], a[2], int(a[3]) if a.size() >= 4 else -1)
	else: printerr("usage: -- prng <seed> <count> <out> | math <file> | scenario <name> <out>")
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
		n += 1
		if JSM.hex64(got) != want: bad[fn] = int(bad.get(fn, 0)) + 1
	print("math ", n, " values, differences from Node: ", bad if bad.size() > 0 else "none")
	return 0 if bad.size() == 0 else 1

# ---------------- scenario harness (golden.js) ----------------
var stopped := false
const SKIP_U := {"t": 1, "ship": 1}
const SKIP_B := {"units": 1, "log": 1, "cfg": 1}
func snap(turn: int, actor: String) -> Dictionary:
	if R.not_ported != "" and not stopped:
		stopped = true; printerr("NOT PORTED: this battle reached a rule the port does not carry yet: ", R.not_ported)
	var B = R.B; var parts := PackedStringArray()
	for u in B["units"]: parts.append(JSM.canon(u, "u", SKIP_U))
	var s := "{\"b\":" + JSM.canon(B, "b", SKIP_B) + ",\"units\":[" + ",".join(parts) + "]}"
	return {"turn": turn, "round": int(B["round"]), "actor": actor, "rng": JSM.rng_u32(), "hash": JSM.sha256(s), "state": s}

func pBot(u) -> void:
	var B = R.B
	if R.jt(B.get("over")) or R.jt(u.get("dead")): return
	var foes = R.alive("enemy")
	if foes.size() == 0: return
	var states = R.computeReach(u).states; var best: Variant = null; var bs = -1e9
	for s in states:
		var v = R.stateView(u, s); var off = R.evalOffense(v, R.readyList(u), foes); var th = R.evalThreat(v, foes)
		var ds := []
		for f in foes: ds.append(R.hdist(v, f))
		var nd = JSM.amin(ds); var sc = off - th * 0.3 - (0.0 if off > 0 else nd * 3.0)
		if sc > bs:
			bs = sc; best = s
	if best != null and best.path.size() > 0: R.moveUnit(u, best)
	for i in range(u["weapons"].size()):
		var bt: Variant = null; var bv = 0.0
		for t in R.alive("enemy"):
			if R.canFire(u, u["weapons"][i], t):
				var e = R.expectedVs(u, u["weapons"][i], t); var v = e.hull + e.shield * 0.3 + (20.0 if e.hull >= t["hp"] else 0.0)
				if v > bv:
					bv = v; bt = t
		if bt != null: R.fireWeapon(u, i, bt)
		if R.jt(R.B.get("over")): return

func scenario(name: String, out: String, seed_override: int = -1) -> int:
	R = RulesScript.new()
	var err = R.load_tables("res://data/tables.json")
	if err != "":
		printerr(err); return 1
	var all = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios.json"))
	if not all.has(name):
		printerr("unknown scenario ", name); return 1
	var S = all[name]
	if seed_override >= 0: S.seed = seed_override
	R.UID = 1; JSM.rnd_seed(int(S.seed))
	R.RUN = {"admiral": S.admiral, "fac": "voidsworn", "credits": 0, "cpCap": 40, "sector": int(S.sector), "relics": [], "inventory": [], "fleet": [], "boons": [], "patrons": [], "stats": {"battles": 0, "elites": 0, "bosses": 0, "kills": 0}, "fallen": []}
	for t in S.fleet: R.RUN["fleet"].append(R.newShip(t, false))
	R.RUN["flagUid"] = R.RUN["fleet"][0]["uid"]
	var en := []
	for tpl in S.enemies: en.append({"tpl": tpl})
	R.startBattle({"kind": S.kind, "fac": S.fac, "col": 3, "seed": int(S.seed), "obj": S.obj, "shape": S.shape, "map": S.map, "dep": S.dep, "enemies": en})
	var rec := [snap(0, "start")]; var turn := 0
	var B = R.B
	B["alt"] = true
	for x in B["units"]: x["activated"] = false
	R.startSideTurn("enemy"); R.flush_deferred(); turn += 1; rec.append(snap(turn, "round 1"))
	var r := 0
	while not R.jt(R.B.get("over")) and r < int(S.rounds):
		var g := 0
		while not R.jt(R.B.get("over")):
			g += 1
			if g > 40: break
			var pp := []; var pe := []
			for x in R.alive("player"):
				if not R.jt(x.get("isSq")) and not R.jt(x.get("activated")): pp.append(x)
			for x in R.alive("enemy"):
				if not R.jt(x.get("isSq")) and not R.jt(x.get("activated")): pe.append(x)
			if pp.size() == 0 and pe.size() == 0: break
			if pp.size() > 0:
				pBot(pp[0]); pp[0]["activated"] = true; turn += 1; rec.append(snap(turn, pp[0]["id"]))
			var more := false
			for x in R.alive("player"):
				if not R.jt(x.get("isSq")) and not R.jt(x.get("activated")): more = true
			var batch: Array = ([R.aiPickActivation(pe)] if pe.size() > 0 else []) if more else pe
			for u in batch:
				if R.jt(R.B.get("over")): break
				R.aiUnit(u); u["activated"] = true; turn += 1; rec.append(snap(turn, u["id"]))
		if R.jt(R.B.get("over")): break
		R.B["round"] = R.B["round"] + 1
		for x in R.B["units"]: x["activated"] = false
		R.startSideTurn("player")
		if not R.jt(R.B.get("over")): R.startSideTurn("enemy")
		R.flush_deferred()
		turn += 1; rec.append(snap(turn, "round " + str(int(R.B["round"]))))
		r += 1
	turn += 1; rec.append(snap(turn, "end " + (str(R.B["over"]) if R.jt(R.B.get("over")) else "none")))
	var f := FileAccess.open(out, FileAccess.WRITE)
	for x in rec: f.store_line(JSON.stringify(x))
	f.close()
	print("scenario ", name, " ", rec.size(), " records ", rec[rec.size() - 1].actor, " -> ", out)
	if stopped:
		printerr("NOT PORTED: ", R.not_ported); return 3
	return 0
