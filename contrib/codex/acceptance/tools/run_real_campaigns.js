#!/usr/bin/env node
'use strict';
const assert=require('assert/strict'),C=require('./common'),{fs,path,BASE,put,logged}=C;
const args=process.argv.slice(2),gi=args.indexOf('--godot'),godot=gi<0?process.env.VOIDSWORN_GODOT_EXE||'godot':args[gi+1];
const summary={status:'INCOMPLETE',scope:'Native campaign choices feed actual battle API outcomes through finish_battle. This is a six-faction headless integration smoke, not a JS parity comparison, rendered UI test or balance forecast.'};
const body=String.raw`
var live_api
func setup_real(run, cfg):
	live_api = BattleAPI.new()
	var err = live_api.load_rules()
	if err != "": printerr(err); quit(2); return null
	live_api.hard_stop = true
	live_api.new_battle(run, cfg)
	return live_api.R.B

func resolve_real() -> Dictionary:
	var guard = 0
	while live_api.phase != "over" and live_api.phase != "halted" and guard < 5000 and live_api.R.B["round"] <= 80:
		guard += 1
		if live_api.phase == "enemy": live_api.step()
		elif live_api.phase == "player":
			if live_api.R.jt(live_api.R.B.get("alt")):
				var pp = live_api._pendingP()
				if pp.size() > 0: live_api.ai_activate(pp[0]["id"])
				else: live_api.end_activation()
			else:
				for u in live_api.R.alive("player"):
					if not live_api.R.jt(u.get("isSq")): live_api.ai_activate(u["id"])
				live_api.end_turn()
		else: break
	if live_api.phase != "over": return {"error": "battle did not finish", "phase": live_api.phase, "round": live_api.R.B["round"], "halt": live_api.halted}
	var b = live_api.R.B
	var record = {"result": b["over"], "rounds": b["round"], "kind": b["cfg"]["kind"], "sector": C.RUN["sector"], "seed": b["seed"], "units": b["units"].size(), "phase": live_api.phase}
	C.finish_battle(b["over"], b)
	live_api = null
	return record

func _init() -> void:
	var a = OS.get_cmdline_user_args()
	if a.size() != 1: printerr("output file required"); quit(2); return
	C = CampaignScript.new()
	var err = C.load_tables()
	if err != "": printerr(err); quit(2); return
	C.fixed_clock = true; C.persist_on = false; C.battle_mode = "external"; C.battle_setup = setup_real
	var output = []; var bad = false
	for index in range(C.RUN_FACTIONS.size()):
		var fac = C.RUN_FACTIONS[index]; var seed = 43101 + index
		C.UID = 1; JSM.rnd_seed(seed); C.META = C.defaultMeta(); C.SAVED_RUN = null; reset_transients(); C.ended = false; C.tel_log = []; C.toasts = []
		C.picked_faction = fac
		var adm = ""
		for id in C.ADMIRALS:
			if C.ADMIRALS[id].get("fac", "voidsworn") == fac: adm = id; break
		C.picked_admiral = adm
		C.META["admirals"][adm] = true
		bot = {"s": seed % 2147483647, "streak": 0, "legacy": false, "help": false, "reloads": 0}
		C.ACT_startRun()
		var clicks = 0; var battles = []; var failure = null
		while not C.ended and clicks < 4000:
			if live_api != null:
				var result = resolve_real(); battles.append(result)
				if result.has("error"): failure = result; break
				continue
			var act = choose(C.screen_acts())
			if act == null or act[0] == "battle": failure = {"error": "missing external battle or campaign action", "page": C.page}; break
			bot["streak"] = bot["streak"] + 1 if STAY.has(act[0]) else 0
			C.act(act[0], act[1]); clicks += 1
		var rec = {"fac": fac, "admiral": adm, "seed": seed, "ended": C.ended, "clicks": clicks, "battles": battles, "failure": failure, "stats": C.META["stats"]}
		if not C.ended or failure != null or battles.size() == 0: bad = true
		output.append(rec); print("real campaign ", fac, ": ended=", C.ended, ", battles=", battles.size(), ", clicks=", clicks)
		if failure != null: break
	var file = FileAccess.open(a[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  ")); file.close()
	quit(1 if bad else 0)
`;
(async()=>{
 const prepared=JSON.parse(fs.readFileSync(path.join(BASE,'evidence/campaign_preparation.json')));summary.project=prepared.project;
 let source=fs.readFileSync(path.join(prepared.project,'campaign/test/parity_campaign.gd'),'utf8');const start=source.indexOf('func _init() -> void:'),end=source.indexOf('func bot_next()',start);assert(start>=0&&end>start);
 source=source.slice(0,start)+body+'\n'+source.slice(end);put(path.join(prepared.project,'campaign/test/real_campaign_smoke.gd'),source);
 const out=path.join(prepared.work,'real_campaigns.json');await logged('real_campaigns',godot,['--headless','--path',prepared.project,'--script','res://campaign/test/real_campaign_smoke.gd','--',out],{timeout:1200000});
 const rows=JSON.parse(fs.readFileSync(out));assert.equal(rows.length,6);assert.equal(new Set(rows.map(x=>x.fac)).size,6);assert(rows.every(x=>x.ended&&x.battles.length>0&&!x.failure));
 summary.status='PASS';summary.runs=rows;summary.battles=rows.reduce((n,x)=>n+x.battles.length,0);summary.limits=['API-only integration with no scene, animations, graphics, audio or persistent player save.','The starting admiral for each faction is chosen explicitly, and the bot uses the existing parity-choice weights.'];put(path.join(BASE,'evidence/real_campaign_summary.json'),JSON.stringify(summary,null,2)+'\n');console.log('PASS: six factions completed '+summary.battles+' actual campaign battles through rewards');
})().catch(e=>{summary.error=e.stack;put(path.join(BASE,'evidence/real_campaign_summary.json'),JSON.stringify(summary,null,2)+'\n');console.error(e.stack);process.exitCode=2;});
