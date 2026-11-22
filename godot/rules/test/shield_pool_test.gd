# R246 shield pool (issue 371): replay the saved hits and shield turns.
# Saved from contrib/opus/tools/shield_pool_tests.js at the R405 cutover.
# Replay the saved baseline with -- res://rules/test/shield_pool_cases.json.
extends SceneTree
@warning_ignore_start("inference_on_variant", "untyped_declaration", "unsafe_property_access", "unsafe_method_access", "unsafe_cast", "unsafe_call_argument", "unused_variable", "return_value_discarded")
const API = preload("res://rules/battle_api.gd")
const JSM = preload("res://rules/jsm.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected the saved fixture JSON path"); quit(2); return
	var fx = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not fx is Dictionary:
		printerr("Cannot read saved fixtures"); quit(2); return
	var api = API.new(); var err = api.load_rules()
	if err != "":
		printerr(err); quit(2); return
	var R = api.R
	fx = R._dec(fx)   # the browser writes non-integers as exact IEEE hex
	var bad := 0; var steps := 0
	for row in fx.cov:
		var got = R.shieldCov(row.fac, row.cls)
		if JSM.canon(got) != JSM.canon(row.cov):
			printerr("coverage ", row.tpl, ": got ", got, ", browser ", row.cov); bad += 1
	for q in fx.seqs:
		api.new_battle_scenario({"seed": 7, "admiral": "vex", "fac_player": q.pfac, "fleet": [q.p], "fac": q.efac, "enemies": [q.e],
			"obj": "rout", "shape": "open", "map": "open", "dep": "line", "kind": "battle", "sector": 1})
		R.B["terrain"] = {}
		var t = null; var a = null
		for u in R.B["units"]:
			if R.jt(u.get("isSq")): u["dead"] = true; continue
			if u["side"] == "player" and t == null: t = u
			if u["side"] == "enemy" and a == null: a = u
		var start = {"shMax": t["shMax"], "regen": t["regen"], "cov": t["cov"]}
		if JSM.canon(start) != JSM.canon(q.start):
			printerr(q.note, ": start ", start, ", browser ", q.start); bad += 1; continue
		var want: Array = q.steps
		for i in range(want.size()):
			if i > 0:
				var op = q.ops[i - 1]
				if op[0] == "hit": R.applyHit(a, a["weapons"][int(op[3])], t, float(op[1]), int(op[2]))
				elif op[0] == "turn": R.startSideTurn(op[1])
				elif op[0] == "set": t["shp"] = op[1]; R.syncShields(t)
			var snap = {"shp": t["shp"], "sh": t["sh"], "route": t["route"] if t.get("route") != null else [0, 0, 0, 0]}
			steps += 1
			if JSM.canon(snap) != JSM.canon(want[i]):
				printerr(q.note, ": step ", i, " ", (q.ops[i - 1] if i > 0 else "start"), ": got ", snap, ", browser ", want[i]); bad += 1; break
	print("Shield pool twin: ", fx.cov.size(), " coverage rows and ", fx.seqs.size(), " sequences (", steps, " steps) against the saved cases; failures: ", bad)
	quit(1 if bad > 0 else 0)
